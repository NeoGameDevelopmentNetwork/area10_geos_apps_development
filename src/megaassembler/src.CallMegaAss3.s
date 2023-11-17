; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
			t "Sym128.erg"

;*** Kennung für GEOS-MegaPatch:
:MP3_Code = $c014

;--- Assemblieren für:
;MegaAssemvbler V2:	FALSE
;MegaAssemvbler V3/4/5:	TRUE
:newMegaAss = TRUE

;Hinweis:
;MegaAssembler V3/4/5 enthält den
;Linker. Daher wird hier der Linker-
;Button aus der DialogBox entfernt.
endif

if newMegaAss = TRUE
			n "Call MegaAss3"
			c "CallMA      V3.1"
			a "Markus Kanet"
			h "Startet MegaAssembler V3/4/5."
			h "Original-Version V1.1 von Ciprina/Goehrke"
endif

if newMegaAss = FALSE
			n "Call MegaAss"
			c "DPT Jumper  V1.2"
			a "Ciprina/Goehrke"
;			h "Startet MegaAssembler V2 oder V-Link."
endif

			o BACK_SCR_BASE
			p BACK_SCR_BASE

			f DESK_ACC
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;*** Programm initialisieren.
:MAIN			lda	curDrive		;Laufwerk speichern.
			sta	curDeviceBuf

			jsr	i_MoveData		;Dialogbox-Daten zwischenspeichern.
			w	dlgBoxRamBuf
			w	dlgBoxCopyBuf
			w	417

;--- Recover-Routine deaktivieren.
			LoadW	RecoverVector,no_func

			lda	screencolors		;Bildschirm-Farben löschen.
			sta	:1

			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::1			b	$00

			jsr	InitMode_40_80		;An GEOS128/80Z anpassen.

			LoadW	r0,DlgBoxData
			jsr	DoDlgBox		;DialogBox darstellen.

			lda	r0L			;Dialogbox-Status speichern.
			pha

			jsr	i_MoveData		;Dialogbox-Daten zurücksetzen.
			w	dlgBoxCopyBuf
			w	dlgBoxRamBuf
			w	417

			pla
			cmp	#2			;Abbruch?
			beq	Exit_CallMA		; => Ja, Ende...

if newMegaAss = FALSE
			cmp	#4			;Linker?
			beq	Open_VLink		; => Ja, weiter...
endif

;*** MegaAssembler starten.
:Open_MegaAss		lda	#<Class_MegaAss		;Zeiger auf GEOS-Klasse für
			ldx	#>Class_MegaAss		;MegaAssembler.

if newMegaAss = FALSE
			bne	OpenApplication

;*** V-Link starten.
:Open_VLink		lda	#<Class_VLink		;Zeiger auf GEOS-Klasse für
			ldx	#>Class_VLink		;V-Link.
endif

:OpenApplication	sta	vecGeosClass +0		;Zeiger auf GEOS-Klasse speichern.
			stx	vecGeosClass +1

			jsr	FindApplication		;Anwendung suchen.
			bcs	Restart_CallMA		; => Nicht gefunden, Neustart.

			lda	MP3_Code +0		;Auf GEOS-MegaPatch testen.
			cmp	#"M"
			bne	:1
			lda	MP3_Code +1
			cmp	#"P"
			beq	LoadApplication

;--- Bei GEOS V2.x SwapFile löschen.
::1			ldx	curDrive		;Systemlaufwerk aktivieren.
			lda	curDeviceBuf
			stx	curDeviceBuf
			jsr	SetDevice

			LoadW	r0,FNameSwapFile	;SwapFile löschen.
			jsr	DeleteFile		;(für GEOS V2.x, bei MP3 unnötig)

			ldx	curDrive		;Programm-Laufwerk aktivieren.
			lda	curDeviceBuf
			stx	curDeviceBuf
			jsr	SetDevice

;--- MegaAss oder V-Link starten.
:LoadApplication	lda	#>EnterDeskTop -1	;Bei Ladefehler zurück zum
			pha				;DeskTop springen, da APP_RAM
			lda	#<EnterDeskTop -1	;überschrieben sein könnte.
			pha

			LoadW	r6,FNameBuf		;Zeiger auf Dateiname.
			LoadB	r0L,$00			;Programm laden und starten.
			jmp	GetFile			;Bei Fehler zurück zum DeskTop.

;*** Zurück zur Anwendung.
:Exit_CallMA		lda	curDeviceBuf		;Systemlaufwerk zurücksetzen.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen und BAM einlesen.
			LoadW	appMain,RstrAppl	;Zurück zur Anwendung.
:no_func		rts				;Ende.

;*** MegaAss/V-Link nicht gefunden.
:Restart_CallMA		lda	curDeviceBuf		;Systemlaufwerk zurücksetzen.
			jsr	SetDevice
			jmp	MAIN			;Call-MegaAss neu starten.

;*** MegaAss oder V-Link auf Disk suchen.
;Anpassung auf 4-Laufwerke für V3.
;
;Die Original-Routine hat hier nur das
;aktuelle Laufwerk invertiert, daher
;wurde entweder auf A/B oder auf C/D
;nach dem Programm gesucht.
;
:FindApplication	LoadB	r7L,APPLICATION		;GEOS-DateiTyp.
			LoadB	r7H,1			;Max. Anzahl Dateien suchen.
			MoveW	vecGeosClass,r10	;Zeiger auf GEOS-Klasse.
			LoadW	r6,FNameBuf		;Zeiger auf Speicher Dateiname.
			jsr	FindFTypes		;Datei suchen.

			lda	r7H			;Datei gefunden?
			beq	:file_found		; => Ja, Ende...

::1			ldx	curDrive		;Zeiger auf nächstes
::2			inx				;Laufwerk setzen.
			cpx	#12
			bcc	:3
			ldx	#8
::3			cpx	curDeviceBuf
			beq	:not_found

			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	:2			; => Nein, nächstes Laufwerk.

			txa				;Laufwerk aktivieren.
			jsr	SetDevice
			txa				;Fehler?
			bne	:1			; => Ja, nächstes Laufwerk.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:1			; => Ja, nächstes Laufwerk.
			beq	FindApplication		; => Nein, Anwendung suchen.

::not_found		sec				;Anwendung nicht gefunden.
			rts

::file_found		clc				;Anwendung gefunden.	
			rts

;*** DialogBox an 40/80-Zeichen anpassen.
:InitMode_40_80		lda	c128Flag		;C128 ?
			bpl	:1			; => Nein, weiter...
			lda	graphMode		;80-Zeichen?
			bmi	:2			; => Ja, weiter...
::1			rts

;--- Größe DialogBox anpassen.
::2			lda	DlgBoxLeft +1		;Linke Grenze DialogBox.
			ora	#DOUBLE_B
			sta	DlgBoxLeft +1

			lda	DlgBoxRight +1		;Rechte Grenze DialogBox.
			ora	#DOUBLE_B
			sta	DlgBoxRight +1

;--- Größe Icons anpassen.
			lda	IconW80_MegaAss
			ora	#DOUBLE_B
			sta	IconW80_MegaAss

if newMegaAss = FALSE
			lda	IconW80_VLink
			ora	#DOUBLE_B
			sta	IconW80_VLink
endif

			lda	IconW80_Abbruch
			ora	#DOUBLE_B
			sta	IconW80_Abbruch

;--- Routine zu setzen des Mauszeigers.
			LoadW	DlgBoxMouseVec,SetMouse80

;--- DialogBox-Text anpassen.
;Bei 80Z. Text ohne Zeilenumbruch darstellen.

if newMegaAss = FALSE
			lda	#" "
			sta	DB_TEXT80_CR_1
endif

			lda	#" "
			sta	DB_TEXT80_CR_2
			rts

;*** Dialogbox: Initialisierung 40-Zeichen.
:SetMouse40		lda	#<$0030			;Linker Rand 40Z. für Textausgabe.
			ldx	#>$0030
			ldy	#$48			;Mauszeiger: X-Position.
			bne	SetMoude_40_80

;*** Dialogbox: Initialisierung 80-Zeichen.
:SetMouse80		lda	#<$0030!DOUBLE_W	;Linker Rand 80Z. für Textausgabe.
			ldx	#>$0030!DOUBLE_W
			ldy	#$c8			;Mauszeiger: X-Position.

;*** Dialogbox: Maus-Position setzen.
:SetMoude_40_80		sta	leftMargin +0		;Linker Rand für Textausgabe.
			stx	leftMargin +1

			sty	r11L			;Mauszeiger: X-Position.
			lda	#$00
			sta	r11H

			ldy	#122			;Mauszeiger: Y-Position.
			sec				;Mauszeiger neu positionieren.
			jmp	StartMouseMode

;*** Dialogbox beenden:
:DB_EXIT_MegaAss	lda	#3			;"Assembler" angeklickt.
			b $2c

if newMegaAss = FALSE
:DB_EXIT_VLink		lda	#4			;"Linker" angeklickt.
			b $2c
endif

:DB_EXIT_Abbruch	lda	#2			;"Abbruch" angeklickt.
			sta	sysDBData

			jmp	RstrFrmDialogue		;DialogBox beenden.

;*** Variablen:
:vecGeosClass		w $0000				;Zeiger auf GEOS-Klasse.
:dlgBoxCopyBuf		s 417				;Zwischenspeicher DlgBox-Daten.
:curDeviceBuf		b $00				;Zwischenspeicher Laufwerk.
:FNameBuf		s 17				;Zwischenspeicher Dateiname.

:FNameSwapFile		b PLAINTEXT			;Name für GEOS V2.x SwapFile.
			b "Swap File",NULL

if newMegaAss = TRUE
:Class_MegaAss		b "MegaAss     V",NULL		;MegaAssembler V3/4/5.
endif

if newMegaAss = FALSE
:Class_MegaAss		b "DPT MegaAss ",NULL		;MegaAssembler V2.
:Class_VLink		b "DPT V-Link",NULL		;V-Link.
endif

;*** DialogBox-Daten.
:DlgBoxData		b $01

			b $40
			b $80
:DlgBoxLeft		w $0028
:DlgBoxRight		w $0108

			b DB_USR_ROUT
:DlgBoxMouseVec		w SetMouse40

			b DBUSRICON
			b $01,$2e
			w IconTab_MegaAss

if newMegaAss = FALSE
			b DBUSRICON
			b $0a,$2e
			w IconTab_VLink
endif

			b DBUSRICON
			b $13,$2e
			w IconTab_Abbruch

			b DBTXTSTR
			b $08,$0a
			w DB_TEXT

			b NULL

:DB_TEXT		b BOLDON

if newMegaAss = TRUE
			b "Soll MegaAssembler gestartet werden?",PLAINTEXT
			b CR
endif
if newMegaAss = FALSE
			b "Welche Application soll gestartet"
:DB_TEXT80_CR_1		b CR
			b "werden ?",PLAINTEXT
endif

			b CR
			b "(Stellen Sie sicher, daß das Dokument"
:DB_TEXT80_CR_2		b CR
			b "aktualisiert wurde.)",NULL

;*** Icondaten für Dialogbox.
:IconTab_Abbruch	w Icon_Abbruch
			b $00,$00
:IconW80_Abbruch	b Icon_Abbruch_X
			b Icon_Abbruch_Y
			w DB_EXIT_Abbruch

:Icon_Abbruch
<MISSING_IMAGE_DATA>
:Icon_Abbruch_X		= .x
:Icon_Abbruch_Y		= .y

if newMegaAss = FALSE
:IconTab_VLink		w Icon_VLink
			b $00,$00
:IconW80_VLink		b Icon_VLink_X
			b Icon_VLink_Y
			w DB_EXIT_VLink

:Icon_VLink
<MISSING_IMAGE_DATA>
:Icon_VLink_X		= .x
:Icon_VLink_Y		= .y
endif

:IconTab_MegaAss	w Icon_MegaAss
			b $00,$00
:IconW80_MegaAss	b Icon_MegaAss_X
			b Icon_MegaAss_Y
			w DB_EXIT_MegaAss

:Icon_MegaAss
<MISSING_IMAGE_DATA>
:Icon_MegaAss_X		= .x
:Icon_MegaAss_Y		= .y
