; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "s.GDC.Config.ext"
endif

;*** GEOS-Header.
			n "obj.GD.INITSYS"
			t "G3_Appl.V.Class"
			f 3 ;DATA

			o BASE_AUTO_BOOT		;BASIC-Start beachten!

;*** Zusätzliche Symbole.
if GD_NG_MODE = FALSE
:LD_CONF_ADDR		= BASE_EDITOR_MAIN
endif
if GD_NG_MODE = TRUE
:LD_CONF_ADDR		= BASE_EDITOR_MAIN_NG
endif
.INITSYS_NG_MODE	= GD_NG_MODE

;******************************************************************************
;Dieses Programm wird zum Abschluß des Installation/Update-Vorgangs gestartet.
;Das Programm startet 'GD.CONFIG' und konfiguriert das GEOS-System.
;Danach wird im Falle einer Installation die Konfiguration gespeichert und
;die Diskette bootfähig gemacht.
;******************************************************************************

;*** Einsprungtabelle.
:MainInit		jmp	ContInstall

;*** Laufwerksdaten, werden vom Installationsprogramm ergänzt.
:UserConfig		s $04
:UserPConfig		s $04
:UserRamBase		s $04

;*** Update-Funktionen:
; Byte #0: +/- GD.CONFIG starten und Konfiguration speichern.
; Byte #1: +/- GD.MAKEBOOT starten.
;Die beiden bytes werden von GD.UPDATE aus dem Infoblock eingelesen.
;MakeBoot wird per Standard nur 1x ausgeführt, danach wird das Byte im
;InfoBlock von GD.UPDATE gelöscht (auf "-" gesetzt).
if GD_NG_MODE = FALSE
:UserTools		b $00,$00
endif
if GD_NG_MODE = TRUE
:UserTools		b $00
endif

;*** GD.CONFIG nachladen und neu initialisieren.
:ContInstall		lda	curDrive
			sta	BOOT_DEVICE

			lda	EnterDeskTop +1		;Zeiger auf ":EnterDeskTop"-Routine
			sta	vecEnterDT   +0		;zwischenspeichern.
			lda	EnterDeskTop +2
			sta	vecEnterDT   +1

			lda	#<EndInstall		;Neue ":EnterDeskTop"-Routine
			sta	EnterDeskTop +1		;installieren.
			lda	#>EndInstall
			sta	EnterDeskTop +2

			LoadW	r0,InfoText01		;Installationsmeldung ausgeben.
			jsr	InfoString

			LoadB	r0L,%00000001
			LoadW	r6 ,FNameSetup
			LoadW	r7 ,LD_CONF_ADDR
			jsr	GetFile			;GD.CONFIG laden.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	EndUpdate

::52			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;InfoBlock einlesen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	PurgeTurbo		;TurboDOS abschalten.

;--- GD.UPDATE-Funktionen ausführen.
;Konfiguration für GD.CONFIG übernehmen.
:chkcfgdrives		lda	UserTools +0
			cmp	#"-"			;GD.CONFIG starten?
			beq	:docfgdrives		; => Nein, weiter...

			ldy	#8
::53			lda	UserConfig  -8,y	;Aktuellen Konfiguration einlesen.
			sta	BootConfig  -8,y	;LW an GD.CONFIG übergeben.
			beq	:54a
			and	#%11110000		;CMD RAMLink ?
			cmp	#DrvRAMLink
			bne	:54			;Nein, weiter...
			lda	UserPConfig -8,y
			b $2c
::54			lda	#$00
			sta	BootPartRL  -8,y	;Partition an GD.CONFIG übergeben.
			lda	#$00
			sta	BootPartRL_I-8,y
			lda	UserConfig  -8,y
			and	#%00001111
			sta	BootPartType-8,y	;PartTyp an GD.CONFIG übergeben.

;--- Ergänzung: 14.07.18/M.Kanet
;Beim Update-Vorgang für RAMNative-Laufwerke auch die RamBase-Adresse des
;Laufwerkes sichern. Die INIT-Routine des RAMNative-Treibers verwendet jetzt
;auch eine evtl. gesetzte RamBase-Adresse zur Überprüfung ob bereits ein
;gültiges Inhaltsverzeichnis an der richtigen Stelle vorliegt. Falls ja, dann
;wird das Laufwerk nicht gelöscht und die richtige Laufwerksgröße aus dem
;Inhaltsverzeichnis ermittelt.
;Ohne diese Ergänzung werden zwei RAMNative-Laufwerke nach dem Update/Neustart
;durch ein einziges Laufwerk ersetzt.
			lda	UserConfig  -8,y	;Bei RAM41/71/81/NM die Start-
			bpl	:54a			;adresse in ramBase sichern.
			and	#%01110000
			bne	:54a
			lda	UserRamBase -8,y
			sta	BootRamBase -8,y	;RAMAdr. an GD.CONFIG übergeben.

::54a			cpy	curDrive		;Aktuelles Laufwerk ?
			beq	:55			;Ja, weiter...

			lda	#$00			;Laufwerk löschen. Die Register
			sta	driveType   -8,y	;":ramBase"/":driveData" dürfen hier
;			sta	ramBase     -8,y	;nicht gelöscht werden, da diese
;			sta	driveData   -8,y	;von den alten GEOSV2-Treiber noch
			sta	turboFlags  -8,y	;mitverwendet werden (RAMLink)!

::55			iny
			cpy	#12
			bne	:53

;--- GD.CONFIG starten.
;Nach der Rückkehr zum DeskTop wird
;dann ":EndInstall" aufgerufen.
::docfgdrives		ldx	curDrive
			lda	BootConfig  -8,x	;Der reale Laufwerkstyp wird vom
			sta	RealDrvType -8,x	;GD.CONFIG in die aktuelle Boot-
							;konfiguration übernommen.

			ldx	#$00			;GD.CONFIG starten.
			stx	r0L
			stx	firstBoot
			dex
			stx	BootInstalled
			lda	fileHeader +$4b
			sta	r7L
			lda	fileHeader +$4c
			sta	r7H
			jmp	StartAppl

;*** AutoBoot beenden.
:EndInstall		lda	vecEnterDT   +0		;Vektor für ":EnterDeskTop"
			sta	EnterDeskTop +1		;zurücksetzen.
			lda	vecEnterDT   +1
			sta	EnterDeskTop +2

;--- GD.UPDATE-Funktionen ausführen.
;Konfiguration von GD.CONFIG auslesen und auf Diskette speichern.
			lda	UserTools +0
			cmp	#"-"			;Konfiguration speichern?
if GD_NG_MODE = FALSE
			beq	:51			; => Nein, weiter...
endif
if GD_NG_MODE = TRUE
			beq	EndUpdate		; => Nein, weiter...
endif
			LoadW	r0,InfoText02		;Installationsmeldung ausgeben.
			jsr	InfoString
			jsr	PatchMP_Files

;--- GD.UPDATE-Funktionen ausführen.
;GD.MAKEBOOT starten.
if GD_NG_MODE = FALSE
::51			lda	UserTools +1
			cmp	#"-"			;MakeBoot ausführen?
			bne	:53			; => Ja, weiter...
::52			jmp	EndUpdate		;Zurück zum DeskTop.

::53			LoadW	r0,InfoText03		;Installationsmeldung ausgeben.
			jsr	InfoString

			LoadW	r6,FNameMkBoot
			jsr	FindFile		;Bootprogramm suchen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			lda	#>EnterDeskTop -1	;Rücksprungadresse setzen.
			pha
			lda	#<EnterDeskTop -1
			pha
			LoadB	r0L,%00000000
			LoadW	r6 ,FNameMkBoot
			jmp	GetFile			;MakeBoot starten.
endif

;*** Bildschirm löschen und zurück zum DeskTop.
:EndUpdate		lda	screencolors		;Fehler, Bildschirm löschen und
			sta	:51			;zurück zum DeskTop.
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::51			b	$00

			lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f
::52			jmp	EnterDeskTop

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

;*** RAM-Konfiguration speichern.
:PatchMP_Files		lda	BOOT_DEVICE		;Startlaufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			rts

::52			LoadW	r6,FNameSetup
			jsr	FindFile		;GEOS-Editor suchen.
			txa				;Editor gefunden ?
			bne	:51			; => Nein, Abbruch...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

::53			lda	LD_CONF_ADDR,x		;Konfiguration übertragen.
			sta	diskBlkBuf +2,x
			inx
			cpx	#(Boot_EndData - Boot_StartData)
			bne	:53

;--- Sonderbehandlung: RAM-Laufwerke.
;BootRamBase wird in GD.CONFIG manuell
;in der Konfiguration gespeichert.
;Beim Erststart bzw. mit GD.UPDATE muss
;die Startadresse von RAM-Laufwerken in
;der Konfiguration gespeichert werden.
			ldx	#8
::54			lda	RealDrvType -8,x
			bpl	:55
			and	#%01110000		;RAM41/71/81/NM ?
			bne	:55			; => Nein, weiter...
			lda	ramBase -8,x
			sta	diskBlkBuf +2 +(BootRamBase - Boot_StartData) -8,x
::55			inx
			cpx	#12
			bcc	:54

			jmp	PutBlock		;Konfiguration speichern.

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

			b "  GeoDOS64 - (C)1995-2021: M.KANET",CR
			b "  SPECIAL-EDITION 3.0  BUILD:"
			d "obj.BuildID"
			b CR,CR,NULL

if Sprache = Deutsch
:InfoText01		b BOLDON
			b "  GeoDOS64 V3 ist installiert.",CR,CR
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
if GD_NG_MODE!Sprache = FALSE!Deutsch
			b CR,CR,PLAINTEXT
			b "  Um die Diskette bootfähig zu machen wird nun",CR
			b "  'GD.MAKEBOOT' gestartet. Bitte warten..."
endif
if Sprache = Deutsch
			b NULL
endif

if Sprache = Englisch
:InfoText01		b BOLDON
			b "  GeoDOS64 V3 has been installed.",CR,CR
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
if GD_NG_MODE!Sprache = FALSE!Englisch
			b CR,CR,PLAINTEXT
			b "  Please wait while loading 'GD.MAKEBOOT' to",CR
			b "  make the current disk bootable..."
endif
if Sprache = Englisch
			b NULL
endif

;*** Variablen.
:vecEnterDT		w $0000

:BOOT_DEVICE		b $00

:FNameSetup		b "GD.CONFIG",NULL
:FNameMkBoot		b "GD.MAKEBOOT",NULL
