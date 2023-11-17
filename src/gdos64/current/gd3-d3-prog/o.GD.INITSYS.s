; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GDC.Config.ext"

;--- GD.INI-Version.
			t "opt.INI.Version"
endif

;*** GEOS-Header.
			n "obj.GD.INITSYS"
			f DATA

			o BASE_AUTO_BOOT		;BASIC-Start beachten!

			r BASE_AUTO_BOOT +SIZE_AUTO_BOOT

;******************************************************************************
;Dieses Programm wird zum Abschluß des Installation/Update-Vorgangs gestartet.
;Das Programm startet 'GD.CONFIG' und konfiguriert das GEOS-System.
;Danach wird im Falle einer Installation die Konfiguration gespeichert und
;die Diskette bootfähig gemacht.
;******************************************************************************

;*** Einsprungtabelle.
:MainInit		jmp	ContInstall

;*** Speichererweiterung.
:UserRAMType		b $00
:UserRAMSize		b $00
:UserRAMBank		w $0000
:UserRAMPart		b $00

;*** Laufwerksdaten.
:UserConfig		s $04
:UserPConfig		s $04
:UserPType		s $04
:UserRamBase		s $04

;*** Update-Funktion:
; +/- Konfiguration speichern.
;Das Byte wird von GD.UPDATE aus dem
;Infoblock eingelesen.
:flagUpdConfig		b $00

;*** GD.INI-Laderoutine.
			t "-G3_LoadGDINI"		;GD.INI-Datei in DACC laden.

;*** Kernal in REU kopieren.
			t "-G3_Kernal2REU"

;*** GD.CONFIG nachladen und neu initialisieren.
:ContInstall		lda	curDrive
			sta	BOOT_DEVICE

			lda	EnterDeskTop +1		;Zeiger auf ":EnterDeskTop"-Routine
			sta	vecEnterDT   +0		;zwischenspeichern.
			lda	EnterDeskTop +2
			sta	vecEnterDT   +1

			lda	#< EndInstall		;Neue ":EnterDeskTop"-Routine
			sta	EnterDeskTop +1		;installieren.
			lda	#> EndInstall
			sta	EnterDeskTop +2

			LoadW	r0,InfoText01		;Installationsmeldung ausgeben.
			jsr	InfoString

			jsr	LoadGDINI		;GD.INI in GEOS-DACC einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- GD.INI aktualisieren.
			ldy	#8
::1			lda	UserConfig  -8,y	;Aktuellen Konfiguration einlesen.
			beq	:3
			and	#%11110000		;CMD RAMLink ?
			cmp	#DrvRAMLink
			bne	:2			;Nein, weiter...
			lda	UserPConfig -8,y
			b $2c
::2			lda	#$00
			sta	UserPConfig -8,y	;Partition an GD.CONFIG übergeben.

			lda	UserConfig  -8,y
			and	#%00001111
			sta	UserPType   -8,y	;PartTyp an GD.CONFIG übergeben.

::3			cpy	curDrive		;Aktuelles Laufwerk ?
			beq	:4			;Ja, weiter...

			lda	#$00			;Laufwerk löschen. Die Register
			sta	driveType   -8,y	;":ramBase"/":driveData" dürfen hier
;			sta	ramBase     -8,y	;nicht gelöscht werden, da diese
;			sta	driveData   -8,y	;von den alten GEOSV2-Treiber noch
			sta	turboFlags  -8,y	;mitverwendet werden (RAMLink)!

::4			iny
			cpy	#12
			bne	:1

;--- GD.INI aktualisieren.
			LoadW	r0,UserRAMType
			LoadW	r1,R3A_CFG_GDOS +2
			LoadW	r2,21			;Nur RAM- und Laufwerksdaten.
			lda	MP3_64K_DATA
			sta	r3L
			jsr	StashRAM

;--- GD.CONFIG laden/starten.
;Nach der Rückkehr zum DeskTop wird
;dann ":EndInstall" aufgerufen.
			ldx	curDrive		;Der reale Laufwerkstyp wird vom
			lda	UserConfig  -8,x	;GD.CONFIG in die aktuelle Boot-
			sta	RealDrvType -8,x	;konfiguration übernommen.

			LoadB	firstBoot,$00		;Flag für "GEOS-Boot" setzen.

			LoadB	r0L,%00000000
			LoadW	r6,FNamGConf
;			LoadW	r7,BASE_GCFG_MAIN
			jsr	GetFile			;GD.CONFIG laden+starten.
;			txa				;Diskettenfehler?
;			bne	:error			; => Ja, Abbruch...

;			jmp	BASE_GCFG_MAIN		;GD.CONFIG starten.

::error			jmp	EndUpdate		;Fehler, zurück zum DeskTop.

;*** AutoBoot beenden.
:EndInstall		lda	flagUpdConfig
			cmp	#"-"			;Konfiguration speichern?
			beq	EndUpdate		; => Nein, weiter...

			LoadW	r0,InfoText02		;Installationsmeldung ausgeben.
			jsr	InfoString

;--- Sonderbehandlung: RAM-Laufwerke.
;BootRamBase wird in GD.CONFIG manuell
;in der Konfiguration gespeichert.
;Beim Erststart bzw. mit GD.UPDATE muss
;die Startadresse von RAM-Laufwerken in
;der Konfiguration gespeichert werden.
			ldy	#8
::1			lda	RealDrvType -8,y
			bpl	:2
			and	#%01110000		;RAM41/71/81/NM ?
			bne	:2			; => Nein, weiter...
			lda	ramBase -8,y
			sta	BootRamBase -8,y	;RAMAdr. an GD.CONFIG übergeben.
::2			inx
			iny
			cpy	#12
			bcc	:1

			jsr	SaveConfigData		;GD.INI aktualisieren.

;*** Bildschirm löschen und zurück zum DeskTop.
:EndUpdate		lda	vecEnterDT   +0		;Vektor für ":EnterDeskTop"
			sta	EnterDeskTop +1		;zurücksetzen.
			lda	vecEnterDT   +1
			sta	EnterDeskTop +2

			lda	screencolors		;Fehler, Bildschirm löschen und
			sta	:col			;zurück zum DeskTop.
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::col			b	$00

			lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

;--- Ergänzung: 11.12.22/M.Kanet:
;Analog zur AutoBoot-Routine den GEOS-
;Kernal in der REU sichern, sonst ist
;direkt nach dem Bootvorgang und dem
;sofortigen Verlassen nach BASIC kein
;GEOS-Boot über SYS49152 möglich.
			jsr	CopyKernal2REU		;Aktuelles Kernal in REU speichern.

			jmp	EnterDeskTop		;DeskTop starten.

;*** Warteschleife.
:InfoString		PushW	r0
			LoadW	r0,InfoText00		;Bildschirm löschen.
			jsr	GraphicsString
			PopW	r0
			jsr	PutString

			php
			sei

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

;--- Ergänzung: 19.07.18/M.Kanet
;Die beiden Befehle "lda $dc08/sta $dc08" wurden eingefügt, nachdem bei einem
;Test mit GEOS 2.x nach dem update die Uhr nicht gestartet wurde.
			lda	$dc08			;Sicherstellen das die Uhr läuft.
			sta	$dc08

			ldx	#$04
::51			lda	$dc08			;Sekunden/10 - Register.
::52			cmp	$dc08
			beq	:52
			dex
			bne	:51

			pla
			sta	CPU_DATA

			plp
			rts

;*** Konfiguration speichern.
:SaveConfigData		lda	BOOT_DEVICE		;Startlaufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:error			; => Nein, weiter...

			LoadW	r6,FNamGDINI
			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Sektor mit Konfiguration laden.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			ldy	#0
::1			lda	BASE_GCFG_DATA,y	;Konfiguration übernehmen.
			sta	diskBlkBuf +2,y
			iny
			cpy	#254
			bne	:1

			jsr	PutBlock		;Sektor mit Konfiguration speichern.
;			txa				;Diskettenfehler ?
;			bne	:error			; => Ja, Abbruch...

::error			rts

;*** Systemtexte.
:InfoText00		b NEWPATTERN,$00
			b MOVEPENTO
			w $0000
			b $00
			b RECTANGLETO
			w $013f
			b $c7
			b ESC_PUTSTRING
			w $0000
			b $0b
			b PLAINTEXT,BOLDON

			b "  GDOS64 - (W)1997-2023 BY MARKUS KANET",CR
			b "  BUILD:"
			t "opt.GDOS.Build"
			b CR,CR,NULL

if LANG = LANG_DE
:InfoText01		b BOLDON
			b "  GDOS64 ist installiert.",CR,CR
			b PLAINTEXT
			b "  Für die Laufwerksinstallation wird nun",CR
			b "  'GD.CONFIG' gestartet. Bitte warten...",NULL
:InfoText02		b BOLDON
			b "  System ist konfiguriert.",CR,CR
			b PLAINTEXT
			b "  Konfiguration speichern...",NULL
:InfoText03		b BOLDON
			b "  Laufwerksinstallation beendet."
endif
if LANG = LANG_DE
			b NULL
endif

if LANG = LANG_EN
:InfoText01		b BOLDON
			b "  GDOS64 has been installed.",CR,CR
			b PLAINTEXT
			b "  To configure the disk drives 'GD.CONFIG'",CR
			b "  is started now. Please wait...",NULL
:InfoText02		b BOLDON
			b "  System is configured.",CR,CR
			b PLAINTEXT
			b "  Save configuration...",NULL
:InfoText03		b BOLDON
			b "  Drive installation completed."
endif
if LANG = LANG_EN
			b NULL
endif

;*** Variablen.
:vecEnterDT		w $0000

:BOOT_DEVICE		b $00

:FNamGConf		b "GD.CONFIG",NULL
:FNamGDINI		b "GD.INI",NULL
