; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Dieses Programm wird zum Abschluß des Installation/Update-Vorgangs gestartet.
;Das Programm startet den GEOS.Editor und konfiguriert das GEOS-System.
;Danach wird im Falle einer Installation die Konfiguration gespeichert und
;die Diskette bootfähig gemacht.
;******************************************************************************

			n "obj.Update2MP3"
			t "G3_SymMacExtEdit"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Apps"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Apps"
endif

			o BASE_AUTO_BOOT		;BASIC-Start beachten!

;*** Einsprungtabelle.
:MainInit		jmp	ContInstall

;*** Laufwerksdaten, werden vom Installationsprogramm ergänzt.
:UserConfig		s $04
:UserPConfig		s $04
:UserRamBase		s $04

;*** Update-Funktionen:
; Byte #0: +/- GEOS.Editor starten und Konfiguration speichern.
; Byte #1: +/- GEOS.MakeBoot starten.
;Die beiden Bytes werden von GEOS.MP3 aus dem Infoblock eingelesen.
;MakeBoot wird per Standard nur 1x ausgeführt, danach wird das Byte im
;Infoblock von GEOS.MP3 gelöscht (auf "-" gesetzt).
:UserTools		s $02

;*** GEOS.Editor nachladen und neu initialisieren.
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
			LoadW	r6 ,FNameME3
			LoadW	r7 ,BASE_EDITOR_MAIN
			jsr	GetFile			;GEOS.Editor laden.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	EndUpdate

::52			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;InfoBlock einlesen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	PurgeTurbo		;TurboDOS abschalten.

			lda	UserTools +0
			cmp	#"-"
			beq	:56

			ldy	#8
::53			lda	UserConfig  -8,y	;Aktuellen Konfiguration einlesen.
			sta	BootConfig  -8,y	;LW an GEOS.Editor übergeben.
			beq	:54a
			and	#%11110000		;CMD RAMLink ?
			cmp	#DrvRAMLink
			bne	:54			;Nein, weiter...
			lda	UserPConfig -8,y
			b $2c
::54			lda	#$00
			sta	BootPartRL  -8,y	;Partition an GEOS.Editor übergeben.
			lda	#$00
			sta	BootPartRL_I-8,y
			lda	UserConfig  -8,y
			and	#%00001111
			sta	BootPartType-8,y	;PartTyp an GEOS.Editor übergeben.

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
			sta	BootRamBase -8,y	;RAMAdr. an GEOS.Editor übergeben.

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

::56			ldx	curDrive
			lda	BootConfig  -8,x	;Der reale Laufwerkstyp wird vom
			sta	RealDrvType -8,x	;GEOS.Editor in die aktuelle Boot-
							;konfiguration übernommen.

			lda	#$00			;GEOS.Editor starten.
			sta	r0L
			sta	firstBoot
			sta	BootInstalled
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

;--- Konfiguration des GEOS-Editors auslesen und auf Diskette speichern.
			lda	UserTools +0
			cmp	#"-"
			beq	:51

			LoadW	r0,InfoText02		;Installationsmeldung ausgeben.
			jsr	InfoString
			jsr	PatchMP_Files

::51			lda	UserTools +1
			cmp	#"-"
			bne	:53
::52			jmp	EndUpdate		;Zurück zum DeskTop.

;--- Bei Update-Vorgang "GEOS64.MakeBoot" starten.
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
			w	$0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W

if Flag64_128 = TRUE_C128
			bit	graphMode		;80-Zeichen-Modus ?
			bpl	:52			; => Nein, weiter...
			lda	scr80colors		;80-Zeichen-Bildschirm löschen.
			jsr	ColorRectangle
endif

::52			jmp	EnterDeskTop

;*** Warteschleife.
:InfoString		PushW	r0
			LoadW	r0,InfoText00		;Bildschirm löschen.
			jsr	GraphicsString
			PopW	r0
			jsr	PutString

			php
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#$35
			sta	CPU_DATA
endif

;--- Ergänzung: 19.07.18/M.Kanet
;Die beiden Befehle "lda $dc08/sta $dc08" wurden eingefügt nachdem bei einem
;Test mit GEOS 2.x nach dem Update die Uhr nicht gestartet wurde.
			lda	$dc08			;Sicherstellen das die Uhr läuft.
			sta	$dc08

			ldx	#$04
::51			lda	$dc08			;Sekunden/10 - Register.
::52			cmp	$dc08
			beq	:52
			dex
			bne	:51

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
			plp
			rts

;*** RAM-Konfiguration speichern.
:PatchMP_Files		lda	BOOT_DEVICE		;Startlaufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			rts

::52			LoadW	r6,FNameME3
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

			lda	diskBlkBuf  +2
			sta	r1L
			lda	diskBlkBuf  +3
			sta	r1H
			jsr	GetBlock		;Ersten Programmsektor einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

::53			lda	BASE_EDITOR_MAIN,x	;Konfiguration übertragen.
			sta	diskBlkBuf  +2,x
			inx
			cpx	#(BootVarEnd - BootVarStart)
			bne	:53

;--- Sonderbehandlung: RAM-Laufwerke.
;BootRamBase wird im Editor nur manuell
;in der Konfiguration gespeichert.
;Beim Erststart bzw. GEOS.MP3 muss hier
;die Startadresse von RAM-Laufwerken in
;der Konfiguration gespeichert werden.
			ldx	#8
::54			lda	RealDrvType -8,x
			bpl	:55
			and	#%01110000		;RAM41/71/81/NM ?
			bne	:55			; => Nein, weiter...
			lda	ramBase -8,x
			sta	diskBlkBuf +2 +(BootRamBase - BootVarStart) -8,x
::55			inx
			cpx	#12
			bcc	:54

			jmp	PutBlock		;Konfiguration speichern.

;*** Systemtexte.
:InfoText00		b NEWPATTERN,$00
			b MOVEPENTO
			w $0000 ! DOUBLE_W
			b $00
			b RECTANGLETO
			w $013f ! DOUBLE_W ! ADD1_W
			b $c7
			b ESC_PUTSTRING
			w $0000 ! DOUBLE_W
			b $10
			b PLAINTEXT,BOLDON

if Flag64_128 = TRUE_C64
			b "GEOS-MEGAPATCH 64",CR,CR,NULL
endif

if Flag64_128 = TRUE_C128
			b "GEOS-MEGAPATCH 128",CR,CR,NULL
endif

if Sprache = Deutsch
:InfoText01		b "MegaPatch ist installiert.",CR,CR
			b "Für die Laufwerksinstallation wird nun",CR
			b "der GEOS.Editor gestartet. Bitte warten...",NULL
:InfoText02		b "Konfiguration speichern...",NULL
:InfoText03		b "Laufwerksinstallation beendet.",CR,CR
			b "Um die Diskette bootfähig zu machen wird nun",CR
			b "GEOS.MakeBoot gestartet. Bitte warten...",NULL
endif

if Sprache = Englisch
:InfoText01		b "MegaPatch is installed now.",CR,CR
			b "To configure the disk drives GEOS.Editor",CR
			b "will be started now. Please wait...",NULL
:InfoText02		b "Saveing configuration...",NULL
:InfoText03		b "Drive-installation finished.",CR,CR
			b "Please wait while loading GEOS.MakeBoot to",CR
			b "make the current disk bootable...",NULL
endif

;*** Variablen.
:vecEnterDT		w $0000

:BOOT_DEVICE		b $00

if Flag64_128 = TRUE_C64
:FNameME3		b "GEOS64.Editor",NULL
:FNameMkBoot		b "GEOS64.MakeBoot",NULL
endif

if Flag64_128 = TRUE_C128
:FNameME3		b "GEOS128.Editor",NULL
:FNameMkBoot		b "GEOS128.MakeBoot",NULL
endif
