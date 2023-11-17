; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; geoWLoad64
;
;GEOS-Anwendung für das WiC64.
; * DiskImages herunterladen
; * Dateien herunterladen
;
; (w) 2022 / M.Kanet
;

;*** Symboltabellen.
if .p
			t "TopSym"
			t "TopMac"

;--- Zusätzliche Labels MP3/Kernal:
			t "TopSym.MP3"
			t "TopSym.ROM"
			t "TopSym.IO"

;--- Sprache festlegen.
:LANG_DE		= $0110
:LANG_EN		= $0220
:LANG			= LANG_DE

;--- DEMO-Modus?
:DEMO_TRUE		= $8000
:DEMO_FALSE		= $0000
:DEMO_MODE		= DEMO_FALSE

;--- lib.WiC64-Build-Optionen.
;Werden die folgenden Optionen auf
;`TRUE` gesetzt, dann werden die dazu
;erforderlichen Routinen während des
;Assemblierungsvorgangs mit in den
;Code eingebunden.
;
;TRUE = Aktuelle Timezone abfragen:
:ENABLE_GETTZN  = FALSE
;ENABLE_GETTZN  = TRUE
;
;TRUE = Timezone setzen:
:ENABLE_SETTZN  = FALSE
;ENABLE_SETTZN  = TRUE
;
;TRUE = Datum/Zeit via NTP abfragen:
;Erfordert ENABLE_SETTZN=TRUE, da bei
;fehlerhaften Datum/Zeit-Angaben die
;Timezone auf "00" gesetzt wird.
:ENABLE_GETNTP  = FALSE
;ENABLE_GETNTP  = TRUE
;
;TRUE = Netzwerkname abfragen:
;ENABLE_GETSSID = FALSE
:ENABLE_GETSSID = TRUE
;
;TRUE = Signalstärke abfragen:
;ENABLE_GETRSSI = FALSE
:ENABLE_GETRSSI = TRUE
;

;--- Speicherbelegung.
:MIN_APP_AREA		= APP_RAM ;$0400
:MAX_APP_AREA		= $3fff
:BASE_DLIST		= $4000
:SIZE_DLIST		= $2000   ; max. LD_ADDR_REGISTER = $6D00.
:BASE_SCRAP		= BASE_DLIST + SIZE_DLIST
:SIZE_SCRAP		= $0100
:BASE_FLIST		= BASE_SCRAP + SIZE_SCRAP
:SIZE_FLIST		= LD_ADDR_REGISTER - BASE_FLIST
:MAX_NAM_FLIST		= SIZE_FLIST / 17

:maxListEntries		= 127
:lenNameServer		= 32
:lenNameRequest		= 24
:lenNameFile		= 16

;--- Variablen für Status-Box:
:STATUS_X		= $0040
:STATUS_W		= $00c0
:STATUS_Y		= $30
:STATUS_H		= $40
:INFO_X			= STATUS_X +STATUS_W -32 -10*8
:INFO_Y			= STATUS_Y +STATUS_H -16
endif

if LANG = LANG_DE
			n "geoWLoad64"
			c "geoWLoad64  V0.1"
endif
if LANG = LANG_EN
			n "geoWLoad64e"
			c "geoWLoad64e V0.1"
endif

			a "Markus Kanet"

			f APPLICATION
			z $80 ;Nur GEOS64!

			o MIN_APP_AREA
			p MAIN

			i
<MISSING_IMAGE_DATA>

if LANG!DEMO_MODE = LANG_DE!DEMO_FALSE
			h "GEOS-Anwendung für WiC64."
			h "DiskImages herunterladen..."
endif
if LANG!DEMO_MODE = LANG_EN!DEMO_FALSE
			h "GEOS application for WiC64."
			h "Download disk images..."
endif

if DEMO_MODE = DEMO_TRUE
;--- Lokaler Server Link-Liste.
			h "+:http://192.168.2.2:8080/linklist"

;--- Standard-Server Link-Liste.
;			h "+:http://bitbucket.org/mkgit64/area6510/downloads/LATEST"

;--- Standard-Download-Server.
;			h "-:http://bitbucket.org/mkgit64/area6510/raw/master/usr/releases/cbmdiredit/v0.1/cbmdiredit.d64"
endif

;*** Externer Code: WiC64-Tools.
			t "lib.WiC64"

;*** Externer Code: TextEditor.
			t "lib.TextEditor"

;*** Hauptprpogramm.
:MAIN			lda	#ST_WR_FORE		;Nur in den Vordergrund schreiben.
			sta	dispBufferOn

			jsr	TEST_KERNAL		;Auf GEOS/MP3-Kernal testen.
			txa				;MP3/GDOS64 vorhanden?
			beq	InitAppl		; => Nein, Abbruch...

;*** Zurück zum DeskTop.
:ExitRegMenu		jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Programm initialisieren.
:InitAppl		jsr	GetBackScreen		;Hintergrundbild laden.

;--- Programm initialisieren.
			jsr	INIT_PROG_DATA		;Programmdaten initialisieren.

			jsr	INIT_URL_DATA		;Standard-URL/Infoblock einlesen.
			txa				;Diskfehler?
			bne	ExitRegMenu		; => Ja, Abbruch...

			jsr	_WiC64_HW_TC64		;TurboChameleon64 erkennen.
			jsr	_WiC64_HW_SCPU		;CMD SuperCPU erkennen.

			jsr	_WiC64_CHECK		;WiC64-Hardware erkennen.
			txa				;Gefunden?
			beq	:wic64_ok		; => Ja, weiter...

			jsr	doErrorWiC64		;WiC64-Fehler ausgeben.

;--- Fehlendes WiC64 ignorieren?
if DEMO_MODE = DEMO_FALSE
			php
			sei
			ldy	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	#%01111111		;C=-Taste abfragen.
			sta	CIA_PRA
			lda	CIA_PRB
			sty	CPU_DATA
			plp

			cmp	#%11001111
			beq	:wic64_ok
			cmp	#%11011111		;C= gedrückt?
			bne	ExitRegMenu		; => Nein, Abbruch...
endif

;--- Register-Menü initialisieren.
::wic64_ok		jsr	regInitLinkList		;Option: Link-Liste.

			jsr	regInitTgtDrv		;Option: Ziel-Laufwerk.
			jsr	regInitDLoadOpt		;Option: Ziel-Modus.

			jsr	splitDLoadURL		;Aktuelle URL aufteilen.

:RestartRegMenu		jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Register-Font aktivieren.

			LoadW	r0,RegMenu1		;Zeiger auf Menü.
			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" starten.
:StartIconMenu		lda	IconExitPos +0		;X-Position für Farbe.
			sta	:x40

			lda	IconExitPos +1		;Y-Position für Farbe.
			lsr				;In CARDs umrechnen.
			lsr
			lsr
			sta	:y40

			lda	C_InputField		;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
::x40			b	(R1SizeX0/8) +1
::y40			b	(R1SizeY0/8) -1
			b	IconExit_x
			b	IconExit_y/8

			LoadW	r0,IconMenu		;Zeiger auf "X"-Icon-Menü.
			jmp	DoIcons			;Icon-Menü aktivieren.

;*** Auf GEOS/MP3-Kernal testen.
:TEST_KERNAL		lda	MP3_CODE +0		;GEOS/MP3-Kennung prüfen.
			ldx	MP3_CODE +1
			cmp	#"M"
			bne	:1
			cpx	#"P"
			beq	:2			; => GEOS/MP3 gefunden.

::1			LoadW	r0,DLG_NO_GEOS_V3	; => Kein GEOS/MP3.
			jsr	DoDlgBox		;Fehler ausgeben.

			ldx	#CANCEL_ERR		;Fehler -> Zurück zum DeskTop.
			b $2c
::2			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Programm initialisieren.
:INIT_PROG_DATA		lda	curDrive		;Aktuelles Laufwerk speichern.
			sta	sysAppDrive
			jsr	SetDevice		;Laufwerk aktivieren und
			jsr	OpenDisk		;Diskette öffnen.

			ldy	sysAppDrive		;Aktive Partition einlesen.
			lda	drivePartData -8,y

			cpx	#NO_ERROR		;Diskfehler?
			beq	:1			; => Ja, Keine aktive Partition.

			lda	#$00			;Vorgabewert CMD-Partition.
::1			sta	sysAppPart		;CMD-Partition speichern.

			tya				;Laufwerk für TextScrap nach
			clc				;ASCII wandeln.
			adc	#"A" -8
			sta	textScrapDrv

			jsr	i_FillRam		;Speicher löschen.
			w	(SYS_DATA_END - SYS_DATA_START)
			w	SYS_DATA_START
			b	NULL

;			jsr	i_FillRam		;Server-URL löschen.
;			w	256
;			w	urlDFile
;			b	NULL

;			jsr	i_FillRam		;Link-Listen-URL löschen.
;			w	256
;			w	urlDList
;			b	NULL

			jsr	i_FillRam		;Link-Liste im Speicher löschen.
			w	SIZE_DLIST
			w	BASE_DLIST
			b	NULL

if DEMO_MODE = DEMO_TRUE
			lda	#%10000000		;Bit%7=1: Debug-Modus setzen.
			sta	flagWiC64dbg

			jsr	initLnkLst_DEMO		;Link-Liste initialisieren.
endif

			jsr	i_FillRam		;Speicher für TextScrap löschen.
			w	SIZE_SCRAP
			w	BASE_SCRAP
			b	NULL

			ldx	sysAppDrive		;Start-Laufwerk als Ziel-Laufwerk
			stx	drvTargetAdr		;festlegen.
			ldy	#DrvRAM1541		;Nächstes Laufwerk vom Typ RAM1541
			jsr	regNextTgtDrv		;für Ziel-Laufwerk suchen.

			cpx	sysAppDrive		;RAM1541 gefunden?
			bne	:2			; => Ja, weiter...
			ldy	#$00			;Nächstes verfügbares Laufwerk
			jsr	regNextTgtDrv		;als Ziel-Laufwerk wählen.

::2			rts				;Ende.

;*** Standard-Server-URL einlesen.
:INIT_URL_DATA		jsr	OPEN_SYS_DRIVE		;Start-Laufwerk öffnen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,sysAppClass
			LoadW	r6,sysAppFName
			jsr	FindFTypes		;Programmdatei suchen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Fehler ausgeben.

			lda	r7H			;Programmdatei gefunden?
			beq	:found			; => Ja, weiter...

			ldx	#FILE_NOT_FOUND
::err			jsr	doErrorGEOS		;GEOS-Fehler ausgeben.

			LoadW	r0,DLG_SYS_ERROR
			jsr	DoDlgBox		;Programmdatei nicht gefunden.

			ldx	#CANCEL_ERR		;Programm beenden.
			rts

::found			LoadW	r6,sysAppFName
			jsr	FindFile		;Verzeichniseintrag suchen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;GEOS-Infoblock einlesen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			lda	fileHeader +160		;Kennbyte einlesen.
			cmp	#"L"			;`L` = Standard-Link-Liste?
			beq	:1			; => Ja, weiter...
			cmp	#"D"			;`D` = Standard-Server?
			bne	:skip			; => Nein, Ende...
::1			ldx	fileHeader +161
			cpx	#":"			;Feld-Trenner vorhanden?
			beq	:geturl			; => Ja, weiter...

::skip			ldx	#NO_ERROR
			rts

::geturl		ldx	#<urlDList
			ldy	#>urlDList
			cmp	#"L"			;`L` = Standard-LinkListe...
			beq	:10

			ldx	#<urlDFile		;`D` = Standard-Download...
			ldy	#>urlDFile

::10			stx	r0L			;Zeiger auf URL-Speicher setzen.
			sty	r0H

			ldx	#162			;Zeiger auf URL hinter Feld-Trenner.
			ldy	#$00
::11			lda	fileHeader,x		;Zeichen einlesen.
			beq	:14			; => $00 = Text-Ende.
			cmp	#" "			;Leerzeichen?
			bcc	:12			; => Ja, überspringen...
			cmp	#$7f			;Zeichen gültig?
			bcs	:12			; => Nein, überspringen...
			cmp	#CR			;Zeilenende?
			beq	:13			; => Ja, Ende...
			sta	(r0L),y			;Zeichen in URL speichern.
::12			iny
			inx
			cpx	#255			;Speicher voll?
			bne	:11			; => Nein, weiter...

::13			lda	#NULL			;Rest des URL-Speichers löschen.
::14			sta	(r0L),y
			iny
			bne	:14

			ldx	#NO_ERROR		;Kein Fehler, Ende...
			rts

;*** System-Laufwerk öffnen.
:OPEN_SYS_DRIVE		lda	sysAppPart
			ldy	sysAppDrive
			bne	openDrive

;*** Ziel-Laufwerk öffnen.
:OPEN_TGT_DRIVE		lda	drvTargetPart
			ldy	drvTargetAdr

;*** System-/Ziel-Laufwerk öffnen.
:openDrive		sta	r3H

			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;Laufwerktyp gültig?
			beq	:exit			; => Nein, Abbruch...
			tya
			jsr	SetDevice		;Laufwerk aktivieren.

			lda	r3H			;CMD-Partition definiert?
			beq	:1			; => Nein, weiter...
			jsr	OpenPartition		;CMD-Partition öffnen.
			txa				;Diskfehler?
			bne	:exit			; => Ja, Abbruch...
			beq	:exit

::1			jsr	OpenDisk		;Diskette öffnen.
;			txa				;Diskfehler?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** Titelzeile in Dialogbox löschen.
:drawDBoxHeader		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern
			jsr	i_Rectangle		;Titelzeile löschen.
			b	$20,$2f
			w	$0040,$00ff
			lda	C_DBoxTitel		;Farbe setzen.
			jsr	DirectColor
			jmp	UseSystemFont		;Standard-Schriftart.

;*** Byte nach ASCII wandeln.
:DEZ2ASCII		ldy	#"0"
			ldx	#"0"
::1			cmp	#100
			bcc	:2
;			sec
			sbc	#100
			iny
			bne	:1
::2			cmp	#10
			bcc	:3
;			sec
			sbc	#10
			inx
			bne	:2
::3			;clc
			adc	#"0"
			rts

;*** Hex nach ASCII wandeln.
:HEX2ASCII		pha
			and	#%11110000
			lsr
			lsr
			lsr
			lsr
			jsr	:1
			tax
			pla
			and	#%00001111
::1			clc
			adc	#"0"
			cmp	#"9" +1
			bcc	:2
			clc
			adc	#$07
::2			rts

;*** Fehlercode auswerten.
;Übergabe: AKKU = Fehlercode.
:doErrorMain		cmp	#INCOMPATIBLE		;DiskImage incompatibel?
			beq	doErrorCompat		; => Ja, Fehler ausgeben.
			cmp	#DOS_MISMATCH		;Soft-WriteProtect?
			beq	doErrorSoftWP		; => Ja, Fehler ausgeben.

			tax				;Download-Fehler?
			bmi	doErrorWiC64		; => Ja, weiter...

;*** GEOS-Laufwerksfehler auswerten.
;Übergabe: XReg = Fehlercode.
:doErrorGEOS		txa
			jsr	HEX2ASCII		;Fehlercode nach ASCII wandeln.
			stx	txtErrStatus +1		;Fehlercode speichern.
			sta	txtErrStatus +2

			ldx	#< txtErrStatus		;Zeiger auf Fehlertext für
			ldy	#> txtErrStatus		;einlesen.
			bne	doErrDBoxMain		;Dialogbox/Fehler ausgeben.

;*** Download-Fehler auswerten.
;Übergabe: AKKU = Fehlercode.
:doErrorWiC64		cmp	#$80 ! ERR_MAX		;Bekannter Fehler?
			bcc	:1			; => Ja, weiter...
			lda	#ERR_UNKNOWN		;Unbekannter Fehlercode.
::1			and	#%01111111		;Bit%7 löschen = Fehlercode 0-127.
			asl
			asl
			tay
			ldx	#0
::2			lda	errDataTab,y		;Zeiger auf Fehlertext/r9 und
			sta	r9L,x			;Fehlermeldung/r10 einlesen.
			iny
			inx
			cpx	#4
			bcc	:2
			bcs	doErrDBox

;*** Laufwerks-Status ausgeben.
;Übergabe: dskErrData = Fehler-Status als ASCII-Text.
:doErrorDrvChan		ldx	#< dskErrData		;Zeiger auf Speicher mit Text des
			ldy	#> dskErrData		;Laufwerksfehlers setzen.
;			bne	doErrDBoxMain		;Dialogbox/Fehler ausgeben.

;*** Fehler: GEOS-Fehler ausgeben.
:doErrDBoxMain		lda	#< txtErrMain		;`Es ist ein Fehler aufgetreten:`
			sta	r9L
			lda	#> txtErrMain
			sta	r9H
			bne	setErrText		;Dialogbox/Fehler ausgeben.

;*** Fehler: Laufwerk nicht kompatibel.
:doErrorCompat		ldx	#< txtErrCompat		;`Laufwerk nicht kompatibel:`
			ldy	#> txtErrCompat
			bne	doErrDBoxDLoad		;Dialogbox/Fehler ausgeben.

;*** Fehler: 1581/D81 mit Soft-WriteProtect.
:doErrorSoftWP		ldx	#< txtErrSoftWP
			ldy	#> txtErrSoftWP
;			bne	doErrDBoxDLoad		;Dialogbox/Fehler ausgeben.

;*** Fehler: Dialogtbox ausgeben.
:doErrDBoxDLoad		lda	#< txtErrDLoad		;`Download fehlgeschlagen:`
			sta	r9L
			lda	#> txtErrDLoad
			sta	r9H
;			bne	setErrText		;Dialogbox/Fehler ausgeben.

:setErrText		stx	r10L			;Zeiger auf zusätzlichen
			sty	r10H			;Dialogbox-Text.

:doErrDBox		LoadW	r0,Dlg_ErrorBox
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

;*** Systemdaten.
:sysAppDrive		b $00
:sysAppPart		b $00
:sysAppFName		s 17
if LANG = LANG_DE
:sysAppClass		b "geoWLoad64  V0.1"
endif
if LANG = LANG_EN
:sysAppClass		b "geoWLoad64e V0.1"
endif
			b NULL

;*** Dialogbox-Titel.
if LANG = LANG_DE
:DLG_TITEL_ERR		b PLAINTEXT,BOLDON
			b "FEHLER!"
			b PLAINTEXT,NULL
:DLG_TITEL_INFO		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
:DLG_TITEL_ERR		b PLAINTEXT,BOLDON
			b "ERROR!"
			b PLAINTEXT,NULL
:DLG_TITEL_INFO		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b PLAINTEXT,NULL
endif

;*** Dialogbox: Kein GEOS/MP3-Kernal.
:DLG_NO_GEOS_V3		b %10000001

			b DBTXTSTR   ,$08,$10
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$24
			w :1
			b DBTXTSTR   ,$08,$2e
			w :2
			b DBTXTSTR   ,$08,$3a
			w :3

			b CANCEL     ,$01,$48
			b NULL

if LANG = LANG_DE
::1			b "Dieses Programm erfordert",NULL
::2			b "GEOS/MegaPatch oder GDOS64.",NULL
::3			b "Programm wird beendet!",NULL
endif
if LANG = LANG_EN
::1			b "This program requires",NULL
::2			b "GEOS/MegaPatch or GDOS64.",NULL
::3			b "Program will be aborted!",NULL
endif

;*** Dialogbox: Programm nicht gefunden!
:DLG_SYS_ERROR		b %10000001

			b DBTXTSTR   ,$08,$10
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$24
			w :1
			b DBTXTSTR   ,$10,$30
			w sysAppClass
			b DBTXTSTR   ,$08,$3c
			w :2

			b CANCEL     ,$01,$48
			b NULL

if LANG = LANG_DE
::1			b "Hauptprogramm nicht gefunden:"
			b BOLDON,NULL
::2			b PLAINTEXT
			b "Das Programm wird beendet!",NULL
endif
if LANG = LANG_EN
::1			b "Main program not found:"
			b BOLDON,NULL
::2			b PLAINTEXT
			b "Program will be aborted!",NULL
endif

;*** Dialogbox: Fehlermeldung ausgeben.
:Dlg_ErrorBox		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_ERR

			b DBVARSTR   ,$08,$20
			b r9L
			b DBVARSTR   ,$08,$30
			b r10L

			b OK         ,$01,$48
			b NULL

if LANG = LANG_DE
:txtErrDLoad		b BOLDON
			b "Download fehlgeschlagen:"
			b PLAINTEXT,NULL
:txtErrMain		b BOLDON
			b "Es ist ein Fehler aufgetreten:"
			b PLAINTEXT,NULL
:txtErrStatus		b "$xx (Laufwerksfehler)",NULL
:txtErrCompat		b "Laufwerk nicht kompatibel",NULL
:txtErrSoftWP		b "Software-Schreibschutz aktiv",NULL
endif
if LANG = LANG_EN
:txtErrDLoad		b BOLDON
			b "Download failed:"
			b PLAINTEXT,NULL
:txtErrMain		b BOLDON
			b "An error has occurred:"
			b PLAINTEXT,NULL
:txtErrStatus		b "$xx (Drive error)",NULL
:txtErrCompat		b "Drive not compatible",NULL
:txtErrSoftWP		b "Software write-protection active",NULL
endif

;*** Download-Fehlertexte.
if LANG = LANG_DE
:txtErrDLoad_00		b "Unbekannter Fehler",NULL
:txtErrDLoad_01		b "WiC64-Hardware nicht gefunden!",CR
			b GOTOX
			w $0048
			b "Programm wird beendet!",NULL
:txtErrDLoad_02		b "Keine Netzwerk-Verbindung",NULL
:txtErrDLoad_03		b "WiC64 Timeout-Fehler",NULL
:txtErrDLoad_04		b "Download-Adresse ungültig",NULL
:txtErrDLoad_05		b "Downloadgröße unbekannt",NULL
:txtErrDLoad_06		b "WiC64-Befehlsgröße fehlerhaft",NULL
:txtErrDLoad_07		b "WiC64-Befehlsbereich fehlerhaft",NULL
:txtErrDLoad_08		b "Downloadgröße ungültig/$00",NULL
:txtErrDLoad_09		b "Keine Download-Daten vorhanden",NULL
:txtErrDLoad_10		b "Fehler während Initialisierung",NULL
:txtErrDLoad_11		b "Datum/Zeit-Angaben fehlerhaft",NULL
endif
if LANG = LANG_EN
:txtErrDLoad_00		b "Unknown error",NULL
:txtErrDLoad_01		b "WiC64 hardware not found",CR
			b GOTOX
			w $0048
			b "Program will be aborted!",NULL
:txtErrDLoad_02		b "No network connection",NULL
:txtErrDLoad_03		b "WiC64 timeout error",NULL
:txtErrDLoad_04		b "Download address invalid",NULL
:txtErrDLoad_05		b "Unknown download size",NULL
:txtErrDLoad_06		b "WiC64 command size invalid",NULL
:txtErrDLoad_07		b "WiC64 command area invalid",NULL
:txtErrDLoad_08		b "Download size invalid/$00",NULL
:txtErrDLoad_09		b "No download data available",NULL
:txtErrDLoad_10		b "Error during initialization",NULL
:txtErrDLoad_11		b "Invalid date/time data",NULL
endif

;*** Zeiger auf Fehlertext/Fehlermeldung.
:errDataTab		w txtErrMain  ,txtErrDLoad_00
			w txtErrMain  ,txtErrDLoad_01
			w txtErrMain  ,txtErrDLoad_02
			w txtErrDLoad ,txtErrDLoad_03
			w txtErrDLoad ,txtErrDLoad_04
			w txtErrDLoad ,txtErrDLoad_05
			w txtErrDLoad ,txtErrDLoad_06
			w txtErrDLoad ,txtErrDLoad_07
			w txtErrDLoad ,txtErrDLoad_08
			w txtErrDLoad ,txtErrDLoad_09
			w txtErrMain  ,txtErrDLoad_10
			w txtErrMain  ,txtErrDLoad_11

;*** Icon-Menü "Beenden".
:IconMenu		b $01
			w $0000
			b $00

			w IconExit
:IconExitPos		b (R1SizeX0/8) +1
			b R1SizeY0 -$08
			b IconExit_x
			b IconExit_y
			w ExitRegMenu

;*** Icon zum schließen des Menüs.
:IconExit
<MISSING_IMAGE_DATA>

:IconExit_x		= .x
:IconExit_y		= .y

;*** Register-Menü.
:R1SizeY0		= $10
:R1SizeY1		= $bf
:R1SizeX0		= $0008
:R1SizeX1		= $0137

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "GEOWLOAD".
			w RegTMenu1

;*** Registerkarten-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons.
:RIcon_SETNAM		w Icon_SETNAM
			b $00,$00
			b Icon_SETNAM_x
			b Icon_SETNAM_y
			b USE_COLOR_INPUT

:Icon_SETNAM
<MISSING_IMAGE_DATA>

:Icon_SETNAM_x		= .x
:Icon_SETNAM_y		= .y

:RIcon_SELECT		w Icon_SELECT
			b $00,$00
			b Icon_SELECT_x
			b Icon_SELECT_y
			b USE_COLOR_INPUT

:Icon_SELECT
<MISSING_IMAGE_DATA>

:Icon_SELECT_x		= .x
:Icon_SELECT_y		= .y

:RIcon_DSKINF		w Icon_DSKINF
			b $00,$00
			b Icon_DSKINF_x
			b Icon_DSKINF_y
			b USE_COLOR_INPUT

:Icon_DSKINF
<MISSING_IMAGE_DATA>

:Icon_DSKINF_x		= .x
:Icon_DSKINF_y		= .y

:RIcon_EXIT		w Icon_EXIT
			b $00,$00
			b Icon_EXIT_x
			b Icon_EXIT_y
			b USE_COLOR_INPUT

:Icon_EXIT
<MISSING_IMAGE_DATA>

:Icon_EXIT_x		= .x
:Icon_EXIT_y		= .y

:RIcon_START		w Icon_START
			b $00,$00
			b Icon_START_x
			b Icon_START_y
			b USE_COLOR_INPUT

:Icon_START
<MISSING_IMAGE_DATA>

:Icon_START_x		= .x
:Icon_START_y		= .y

:RIcon_UPDLST		w Icon_UPDLST
			b $00,$00
			b Icon_UPDLST_x
			b Icon_UPDLST_y
			b USE_COLOR_INPUT

:Icon_UPDLST
<MISSING_IMAGE_DATA>
:Icon_UPDLST_x		= .x
:Icon_UPDLST_y		= .y

:RIcon_TXTMAN		w Icon_TXTMAN
			b $00,$00
			b Icon_TXTMAN_x
			b Icon_TXTMAN_y
			b USE_COLOR_INPUT

:Icon_TXTMAN
<MISSING_IMAGE_DATA>

:Icon_TXTMAN_x		= .x
:Icon_TXTMAN_y		= .y

:RIcon_DLIST		w Icon_DLIST
			b $00,$00
			b Icon_DLIST_x
			b Icon_DLIST_y
			b USE_COLOR_INPUT

:Icon_DLIST
<MISSING_IMAGE_DATA>

:Icon_DLIST_x		= .x
:Icon_DLIST_y		= .y

:RIcon_DSERVER		w Icon_DSERVER
			b $00,$00
			b Icon_DSERVER_x
			b Icon_DSERVER_y
			b USE_COLOR_INPUT

:Icon_DSERVER
<MISSING_IMAGE_DATA>

:Icon_DSERVER_x		= .x
:Icon_DSERVER_y		= .y

:RIcon_BACK		w Icon_BACK
			b $00,$00
			b Icon_BACK_x
			b Icon_BACK_y
			b USE_COLOR_INPUT

:Icon_BACK
<MISSING_IMAGE_DATA>

:Icon_BACK_x		= .x
:Icon_BACK_y		= .y

:RIcon_NEXT		w Icon_NEXT
			b $00,$00
			b Icon_NEXT_x
			b Icon_NEXT_y
			b USE_COLOR_INPUT

:Icon_NEXT
<MISSING_IMAGE_DATA>

:Icon_NEXT_x		= .x
:Icon_NEXT_y		= .y

:RIcon_SD1		w Icon_SD1
			b $00,$00
			b Icon_SD1_x
			b Icon_SD1_y
			b USE_COLOR_INPUT

:Icon_SD1
<MISSING_IMAGE_DATA>

:Icon_SD1_x		= .x
:Icon_SD1_y		= .y

:Icon_SDALL
<MISSING_IMAGE_DATA>

:Icon_SDALL_x		= .x
:Icon_SDALL_y		= .y

:RIcon_DEBUG		w Icon_DEBUG
			b $00,$00
			b Icon_DEBUG_x
			b Icon_DEBUG_y
			b USE_COLOR_REG

:Icon_DEBUG
<MISSING_IMAGE_DATA>

:Icon_DEBUG_x		= .x
:Icon_DEBUG_y		= .y

;*** Daten für Register "GEOWLOAD".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RTab1_1  = $0000  ;Eingabefeld: Link-Liste/Download-URL
:RTab1_2  = $0000  ;Option: 1:1-Modus
:RTab1_3  = $0088  ;Option: Dateiname
:RTab1_4  = $0030  ;Option: Download-Modus
:RTab1_5  = $0030  ;Option: Ziel-Laufwerk
:RTab1_6  = $0050  ;Option: Ziel-Diskette/Partition
:RTab1_6s = 22     ;        Anzahl Zeichen
:RTab1_I1 = $0008  ;Icon-Menü: Start
:RTab1_I2 = $0050  ;Icon-Menü: LinkListe
:RTab1_I3 = $00b8  ;Icon-Menü: TextManager
:RTab1_I4 = $0118  ;Icon-Menü: Beenden
:RLine1_1 = $08    ;Eingabefeld: Link-Liste
:RLine1_2 = $38    ;Eingabefeld: Download-URL
:RLine1_3 = $60    ;Option: Ziel-Laufwerk/Ziel-Diskette
:RLine1_4 = $70    ;Option: Download-Modus/Dateiname
:RLine1_5 = $80    ;Option: 1:1-Modus
:RLine1_6 = $90    ;Icon-Menü

:RegTMenu1		b 26

;--- URL: Link-Liste.
:regDatLnkLst		b BOX_USEROPT
				w R1T01
				w initUrlLink
				b RPos1_y +RLine1_1
				b RPos1_y +RLine1_1 +$20 -1
				w RPos1_x +RTab1_1
				w RPos1_x +RTab1_1 +$110 -1

;--- URL: Download-Adresse.
:regDatFileURL		b BOX_USEROPT
				w R1T02
				w initUrlDServer
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +$20 -1
				w RPos1_x +RTab1_1
				w RPos1_x +RTab1_1 +$110 -1

;--- Ziel-Laufwerk.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_3 -$01
				b RPos1_y +RLine1_3 +$08
				w RPos1_x +RTab1_5 -$01
				w RPos1_x +RTab1_5 +2*8 +$08
:regDatTgtDrv		b BOX_STRING_VIEW
				w R1T10
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_5
				w drvTargetTxt
				b 2
			b BOX_ICON
				w $0000
				w regSlctTgtDrv
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_5 +2*8
				w RIcon_SELECT
				b (regDatTgtDrv - RegTMenu1 -1)/11 +1

;--- Ziel-Diskette/Partition.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_3 -$01
				b RPos1_y +RLine1_3 +$08
				w RPos1_x +RTab1_6 -$01
				w RPos1_x +RTab1_6 +RTab1_6s*8 +$08 +$08
:regDatTgtDsk		b BOX_STRING_VIEW
				w $0000
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_6
				w dskTargetTxt
				b RTab1_6s
			b BOX_ICON
				w $0000
				w regSlctTgtPart
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_6 +RTab1_6s*8
				w RIcon_SELECT
				b (regDatTgtDsk - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w prntDiskInfo
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_6 +RTab1_6s*8 +8
				w RIcon_DSKINF
				b NO_OPT_UPDATE

;--- Download-Modus.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_4 -$01
				b RPos1_y +RLine1_4 +$08
				w RPos1_x +RTab1_4 -$01
				w RPos1_x +RTab1_4 +9*8 +$08
:regDatWrMode		b BOX_USEROPT_VIEW
				w R1T12
				w prntDLoadMode
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +$08 -1
				w RPos1_x +RTab1_4
				w RPos1_x +RTab1_4 +9*8 -1
			b BOX_ICON
				w $0000
				w slctDLoadMode
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_4 +9*8
				w RIcon_SELECT
				b (regDatWrMode - RegTMenu1 -1)/11 +1

;--- Dateiname.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_4 -$01
				b RPos1_y +RLine1_4 +$08
				w RPos1_x +RTab1_3 -$01
				w RPos1_x +RTab1_3 +16*8 +$08
:regDatFileNm		b BOX_STRING
				w $0000
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_3
				w altFileName
				b lenNameFile
			b BOX_ICON
				w $0000
				w createFileName
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_3 +16*8
				w RIcon_SETNAM
				b (regDatFileNm - RegTMenu1 -1)/11 +1

:regDatBlkMode		b BOX_OPTION
				w R1T11
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_2
				w flagWrEmpty
				b %10000000

;--- Icon-Menü: Start.
			b BOX_ICON
				w R1T90
				w StartDownload
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I1
				w RIcon_START
				b NO_OPT_UPDATE

;--- Icon-Menü: Link-Liste.
			b BOX_ICON
				w R1T91
				w reloadDList
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I2
				w RIcon_UPDLST
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w prevLinkEntry
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I2 +$10
				w RIcon_BACK
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w nextLinkEntry
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I2 +$20
				w RIcon_NEXT
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w swapAutoMode
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I2 +$30
				w RIcon_SD1
				b NO_OPT_UPDATE

;--- Icon-Menü: TextManager.
			b BOX_ICON
				w R1T92
				w openTextMan
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I3
				w RIcon_TXTMAN
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w textScrapL
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I3 +$10
				w RIcon_DLIST
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w textScrapD
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I3 +$20
				w RIcon_DSERVER
				b NO_OPT_UPDATE

;--- Icon-Menü: Beenden.
			b BOX_ICON
				w $0000
				w ExitRegMenu
				b RPos1_y +RLine1_6
				w R1SizeX0 +RTab1_I4
				w RIcon_EXIT
				b NO_OPT_UPDATE

;--- Icon-Menü: DEBUG.
			b BOX_ICON
				w R1T99
				w setDebugMode
				b R1SizeY1 -$07
				w R1SizeX1 -$07
				w RIcon_DEBUG
				b NO_OPT_UPDATE

;*** Icon-Bereiche für visuelle Rückmeldung.
:visAreaTab		b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +7 -1
			w R1SizeX0 +RTab1_I3 +$10 +1
			w R1SizeX0 +RTab1_I3 +$10 +15 -1

			b RPos1_y +RLine1_6 +8 +1
			b RPos1_y +RLine1_6 +15 -1
			w R1SizeX0 +RTab1_I3 +$10 +1
			w R1SizeX0 +RTab1_I3 +$10 +15 -1

			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +7 -1
			w R1SizeX0 +RTab1_I3 +$20 +1
			w R1SizeX0 +RTab1_I3 +$20 +15 -1

			b RPos1_y +RLine1_6 +8 +1
			b RPos1_y +RLine1_6 +15 -1
			w R1SizeX0 +RTab1_I3 +$20 +1
			w R1SizeX0 +RTab1_I3 +$20 +15 -1

			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +15 -1
			w R1SizeX0 +RTab1_I2 +$10 +1
			w R1SizeX0 +RTab1_I2 +$10 +15 -1

			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +15 -1
			w R1SizeX0 +RTab1_I2 +$20 +1
			w R1SizeX0 +RTab1_I2 +$20 +15 -1

			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +15 -1
			w R1SizeX0 +RTab1_I2 +$30 +1
			w R1SizeX0 +RTab1_I2 +$30 +15 -1

			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +15 -1
			w R1SizeX0 +RTab1_I2 +1
			w R1SizeX0 +RTab1_I2 +15 -1

;*** Texte für Register "DOWNLOAD".
:R1T01			w RPos1_x +RTab1_1 +$04
			b RPos1_y +RLine1_1 -$04
if LANG = LANG_DE
			b "LINK-LISTE (L)",NULL
endif
if LANG = LANG_EN
			b "LINK LIST (L)",NULL
endif

:R1T02			w RPos1_x +RTab1_1 +$04
			b RPos1_y +RLine1_2 -$04
			b "DOWNLOAD (D)",NULL

;--- Ziel-Laufwerk.
:R1T10			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_3 +$06
if LANG = LANG_DE
			b "Ziel:",NULL
endif
if LANG = LANG_EN
			b "Target:",NULL
endif

:R1T11			w RPos1_x +RTab1_2 +$0c
			b RPos1_y +RLine1_5 +$06
if LANG = LANG_DE
			b "Dxx/Disk: Leere Sektoren auf Disk schreiben",NULL
endif
if LANG = LANG_EN
			b "Dxx/Disk: Write empty blocks to disk",NULL
endif

:R1T12			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_4 +$06
if LANG = LANG_DE
			b "Modus:",NULL
endif
if LANG = LANG_EN
			b "Mode:",NULL
endif

;--- Icon-Menü: Start.
:R1T90			w R1SizeX0 +RTab1_I1 +$10 +$02
			b RPos1_y +RLine1_6 +$06
if LANG = LANG_DE
			b "Download"
endif
if LANG = LANG_EN
			b "Start"
endif
			b GOTOXY
			w R1SizeX0 +RTab1_I1 +$10 +$02
			b RPos1_y +RLine1_6 +$08 +$06
if LANG = LANG_DE
			b "starten",NULL
endif
if LANG = LANG_EN
			b "download",NULL
endif

;--- Icon-Menü: Link-Liste.
:R1T91			w R1SizeX0 +RTab1_I2 +$40 +$02
			b RPos1_y +RLine1_6 +$06
if LANG = LANG_DE
			b "Link-"
endif
if LANG = LANG_EN
			b "Link"
endif
			b GOTOXY
			w R1SizeX0 +RTab1_I2 +$40 +$02
			b RPos1_y +RLine1_6 +$08 +$06
if LANG = LANG_DE
			b "Liste",NULL
endif
if LANG = LANG_EN
			b "list",NULL
endif

;--- Icon-Menü: TextManager.
:R1T92			w R1SizeX0 +RTab1_I3 +$30 +$02
			b RPos1_y +RLine1_6 +$06
			b "Text-"
			b GOTOXY
			w R1SizeX0 +RTab1_I3 +$30 +$02
			b RPos1_y +RLine1_6 +$08 +$06
			b "Scrap",NULL

;--- DEMO-Modus.
if LANG!DEMO_MODE = LANG_DE!DEMO_TRUE
:R1T99			w RPos1_x +RTab1_1 +$110 -96
			b RPos1_y +RLine1_1 -$04
			b "* DEMO-MODUS *",NULL
endif
if LANG!DEMO_MODE = LANG_EN!DEMO_TRUE
:R1T99			w RPos1_x +RTab1_1 +$110 -88
			b RPos1_y +RLine1_1 -$04
			b "* DEMO-MODE *",NULL
endif
if DEMO_MODE = DEMO_FALSE
:R1T99			w R1SizeX1 -$42
			b R1SizeY0 +$08
			b NULL
endif

;*** Debug-Modus aktivieren.
;Hinweis: Erzeugt beim Download im
;Bildschirmrand farbige Streifen.
:setDebugMode		lda	mouseData		;Maustaste noch gedrückt?
			bpl	setDebugMode		; => Ja, warten...
			lda	#$00			;Tastenstatus löschen.
			sta	pressFlag

			php				;Tastatur abfragen.
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	#%01111101
			sta	CIA_PRA
			lda	CIA_PRB
			stx	CPU_DATA
			plp

			cmp	#%01011111		;CBM+SHIFT gedrückt?
			bne	:2			; => Nein, weiter...

			lda	flagWiC64dbg		;Debug-Modus umschalten.
			eor	#%10000000
			sta	flagWiC64dbg

			ldx	#< dboxDebug01		;Debug-Modus aktiviert.
			ldy	#> dboxDebug01
			cmp	#%10000000
			beq	:1
			ldx	#< dboxDebug02		;Debug-Modus deaktiviert.
			ldy	#> dboxDebug02
::1			stx	r10L
			sty	r10H

			LoadW	r0,Dlg_DebugMode
			jsr	DoDlgBox		;Status Debug-Modus anzeigen.

::2			rts

;*** Diskinfo ausgeben.
:prntDiskInfo		jsr	StopTextEdit		;Text-Eingabe beenden.

			jsr	OPEN_TGT_DRIVE		;Ziel-Laufwerk öffnen.
			txa				;Diskfehler?
			bne	:exit			; => Nein, weiter...

			LoadW	r0,Dlg_DiskInfo
			jsr	DoDlgBox		;DiskInfo ausgeben.

::exit			rts				;Ende.

;*** Daten für DiskInfo ermitteln und ausgeben.
:drawDiskInfo		LoadW	r0,dskInfTx01
			LoadB	r1H,$50
			LoadW	r11,$0048
			jsr	PutString		;`Disk:`

			LoadW	r11,$0064
			LoadW	r0,dskTargetTxt
			jsr	PutString		;Diskname ausgeben.

			LoadW	r5,curDirHead
			jsr	CalcBlksFree		;Anzahl freier Sektoren berechnen.

			PushW	r3			;Gesamtanzahl Sektoren.
			PushW	r4			;Freie Sektoren.

			LoadW	r0,dskInfTx02
			LoadB	r1H,$5c
			LoadW	r11,$0048
			jsr	PutString		;`Frei:`

			LoadW	r11,$0064
			PopW	r0
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Freie Sektoren ausgeben.

			lda	#"/"
			jsr	SmallPutChar		;Trennzeichen ausgeben.

			PopW	r0
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Gesamtanzahl Sektoren ausgeben.

			LoadW	r0,dskInfTx03
			jmp	PutString		;`Blocks`

;*** Nächstes Laufwerk suchen.
:regSlctTgtDrv		jsr	StopTextEdit		;Text-Eingabe beenden.

			ldy	#$00			;Keine Vorgabe für Laufwerk.
			jsr	regNextTgtDrv		;Nächstes Laufwerk wählen.
			jsr	regInitTgtDrv		;Texte für Ziel-Laufwerk setzen.
			jsr	regInitDLoadOpt		;Register-Optionen aktualisieren.

			LoadW	r15,regDatTgtDsk	;Option: Ziel-Diskette.
			jsr	RegisterUpdate		;InfoText-Option aktualisieren.

			LoadW	r15,regDatWrMode	;Option: Download-Modus.
			jsr	RegisterUpdate		;InfoText-Option aktualisieren.

			LoadW	r15,regDatFileNm	;Option: Alternativer Dateiname.
			jsr	RegisterUpdate		;InfoText-Option aktualisieren.

			LoadW	r15,regDatBlkMode	;Option: 1:1-Modus.
			jmp	RegisterUpdate		;InfoText-Option aktualisieren.

;*** Nächstes Ziel-Laufwerk wählen.
;Übergabe: YReg = $00/DrvType (z.B. DrvRAM1541)
;          drvTargetAdr = Aktuelles Laufwerk.
:regNextTgtDrv		ldx	drvTargetAdr		;Aktuelles Laufwerk einlesen.
::1			inx				;Nächstes Laufwerk.
			cpx	drvTargetAdr		;Suche abgeschlossen?
			beq	:5			; => Ja, Ende...
			cpx	#12			;Laufwerk #12 erreicht?
			bcc	:2			; => Nein, weiter...
			ldx	#8			; => Ja, weiter mit Laufwerk #8.
::2			tya				;Bestimmten Laufwerkstyp suchen?
			beq	:3			; => Nein, weiter...
			cmp	driveType -8,x		;Laufwerkstyp gefunden?
			beq	:4			; => Ja, Ende...
::3			lda	driveType -8,x		;Laufwerk definiert?
			beq	:1			; => Nein, nächstes Laufwerk.
::4			stx	drvTargetAdr		;Neues Ziel-Laufwerk speichern.
			sta	drvTargetType

::5			rts

;*** Register-Eintrag Ziel-Laufwerk aktualisieren.
:regInitTgtDrv		lda	drvTargetAdr
			jsr	SetDevice		;Ziel-Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.

			jsr	initTargetDrv		;Option: Ziel-Laufwerk.
			jsr	initTargetPart		;Option: Ziel-Disk/Partition.

			rts

;*** Text für Ziel-Laufwerk definieren.
:initTargetDrv		lda	drvTargetAdr		;GEOS-Laufwerksadresse nach
			clc				;ASCII wandeln.
			adc	#"A" -8
			sta	drvTargetTxt
			rts

;*** Register-Eintrag Ziel-Partition aktualisieren.
:regSlctTgtPart		jsr	StopTextEdit		;Text-Eingabe beenden.

			ldx	drvTargetAdr
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			bpl	:exit			; => Nein, Ende...

			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Partition auswählen.

			lda	sysDBData
			cmp	#OPEN			;Partition geöffnet?
			bne	:exit			; => Nein, Ende...

			jsr	initTargetPart

::exit			rts

;*** Text für Ziel-Partition definieren.
:initTargetPart		lda	#$00
			sta	drvTargetPart

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskfehler?
			bne	:nodisk			; => Ja, Text "Keine Diskette".

			ldx	drvTargetAdr
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			bpl	:nocmd			; => Nein, weiter...

			lda	drivePartData -8,x
			sta	drvTargetPart
			jsr	DEZ2ASCII		;Partitions-Nr. nach ASCII wandeln.
			sty	dskTargetTxt +0
			stx	dskTargetTxt +1
			sta	dskTargetTxt +2

			lda	#":"
			sta	dskTargetTxt +3		;Feld-Trenner einfügen.

			lda	#4			;Position Dateiname bei CMD.
			b $2c
::nocmd			lda	#0			;Position Dateiname Standard.
			pha

			ldx	#r0L			;Zeiger auf Diskname einlesen.
			jsr	GetPtrCurDkNm

			pla
			tax				;Position Dateiname setzen.

::copy			ldy	#0
;			ldx	#0			;0=CBM, 4=CMD/Partition.
::11			lda	(r0L),y			;Zeichen einlesen. Ende erreicht?
			beq	:done			; => Ja, weiter...
			cmp	#$a0			;SHIFT-SPACE = Ende erreicht ?
			beq	:done			; => Ja, weiter...
			cmp	#$20			;Auf gültiges Zeichen testen.
			bcc	:12
			cmp	#$7f
			bcc	:13
::12			lda	#"."			;Ungültig, Ersatzzeichen `.`.
::13			sta	dskTargetTxt,x		;Zeichen für Diskname kopieren.
			inx
			iny
			cpy	#lenNameFile		;Max.Länge Disk/Dateiname erreicht?
			bcc	:11			; => Nein, weiter...

::done			tya				;Mind. 1 Zeichen kopiert?
			bne	:clrbuf			; => Ja, weiter...

::nodisk		bit	curType			;Laufwerk oder RAM-Disk?
			bmi	:noram			; => RAM-Disk, weiter...

if DEMO_MODE = DEMO_FALSE
			jsr	ExitTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.
			jsr	openDevChan		;Befehlskanal öffnen.
			jsr	getDiskError		;Laufwerks-Status einlesen.
			jsr	closeDevChan		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O-Bereich abschalten.
endif

::noram			LoadW	r0,errNoDisk		;Vorgabetext "Keine Diskette".
			ldx	#0
			jmp	:copy			;Vorgabetext kopieren.

::clrbuf		lda	#$00			;Rest des Speichers für
::21			sta	dskTargetTxt,x		;Disk-/Partitionsname löschen.
			inx
			iny
			cpy	#(lenNameFile +1)
			bcc	:21

			rts				;Ende.

;*** Register-Optionen aktualisieren.
;Die Option 1:1 ist nur gültig für den
;Download von ein echtes Laufwerk bzw.
;auf ein vorhandenes SD2IEC/DiskImage.
;Die Option "Dateiname" ist nur gültig
;beim Download als Datei.
:regInitDLoadOpt	ldy	dloadMode
			jsr	testWriteMode		;Aktuellen Download-Modus testen.
			dey				;Download-Modus: Dxx/Disk?
			beq	:1			; => Ja, weiter...

			lda	#BOX_OPTION_VIEW	;1:1-Modus deaktivieren.
			b $2c
::1			lda	#BOX_OPTION		;1:1-Modus aktivieren.
			sta	regDatBlkMode		;Options-Modus speichern.

			iny
			cpy	#2			;Als Datei speichern? (Auch SD2IEC)
			bcs	:2			; => Ja, weiter...

			lda	#NULL			;Dateiname löschen da keine
			sta	altFileName		;Eingabe möglich.

			lda	#BOX_STRING_VIEW	;STRING_VIEW: Keine Eingabe möglich.
			b $2c
::2			lda	#BOX_STRING		;STRING: Dateiname ändern möglich.
			sta	regDatFileNm		;Options-Modus speichern.

			rts

;*** Download-Modus anzeigen.
:prntDLoadMode		lda	#(RPos1_y +RLine1_4 +6)
			sta	r1H
			lda	#< (RPos1_x +RTab1_4 +2)
			sta	r11L
			lda	#> (RPos1_x +RTab1_4 +2)
			sta	r11H

			ldy	dloadMode		;Download-Modus einlesen und
			jsr	testWriteMode		;auf Gültigkeit testen.

			tya				;Zeiger auf Modus-Text berechnen.
			asl
			tay
			lda	dloadNamTab +0,y
			sta	r0L
			lda	dloadNamTab +1,y
			sta	r0H

			jmp	PutString		;Download-Modus ausgeben.

;*** Download-Modus wechseln.
:slctDLoadMode		ldy	dloadMode		;Download-Modus einlesen und
			jsr	nextWriteMode		;auf nächsten Modus wechseln.

			jsr	regInitDLoadOpt		;Register-Optionen aktualisieren.

			LoadW	r15,regDatBlkMode	;1:1-Option aktualisieren.
			jsr	RegisterUpdate

			jsr	splitDLoadURL		;Aktuelle URL aufteilen.
			jsr	createFileName		;Dateiname erzeugen.

			LoadW	r15,regDatFileNm	;Dateiname aktualisieren.
			jmp	RegisterUpdate

;*** Download-Modus wechseln.
:nextWriteMode		iny				;Download-Modus +1.
			cpy	#6			;Ende erreicht?
			bcc	testWriteMode		; => Nein, weiter...
			ldy	#0			;Zurück auf Anfang.

;*** Aktuellen Download-Modus testen.
;Hinweis: Nicht alle Modi sind bei
;jedem Ziel-Laufwerk möglich.
:testWriteMode		cpy	#0			;Dxx/RAMDisk?
			bne	:1			; => Nein, weiter...

			bit	drvTargetType		;Ziel-Laufwerk = RAM-Laufwerk?
			bmi	:1			; => Ja, weiter...
			iny				; => Nein, nächsten Modus wählen.

::1			cpy	#1			;Dxx/Disk?
			bne	:2			; => Nein, weiter...

			bit	drvTargetType		;Ziel-Laufwerk = Disk-Laufwerk?
			bpl	:2			; => Ja, weiter...
			lda	dloadMode		;Download-Modus einlesen.
;			cmp	#0			;Aktueller Modus = Dxx/RAMDisk?
			beq	nextWriteMode		; => Ja, nächsten Modus wählen.
			dey				; => Nein, vorherigen Modus wählen.

::2			cpy	#2			;Dxx/SD2IEC?
			beq	:2a			; => Ja, weiter...
			cpy	#5			;Datei/SD2IEC?
			bne	:3			; => Nein, weiter...

::2a			ldx	drvTargetAdr
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
if DEMO_MODE = DEMO_FALSE
			beq	nextWriteMode		; => Nein, nächsten Modus wählen.
endif

::3			cpy	#3			;Datei/RAMDisk?
			bne	:4			; => Nein, weiter...

			bit	drvTargetType		;Ziel-Laufwerk = RAM-Laufwerk?
			bmi	:4			; => Ja, weiter...
			iny				; => Nein, nächsten Modus wählen.

::4			cpy	#4			;Datei/Disk?
			bne	:5			; => Nein, weiter...

			bit	drvTargetType		;Ziel-Laufwerk = Disk-Laufwerk?
			bpl	:5			; => Ja, weiter...

			lda	dloadMode		;Download-Modus einlesen.
			cmp	#3			;Aktueller Modus = Datei/RAMDisk?
			beq	nextWriteMode		; => Nein, nächsten Modus wählen.
			dey				; => Nein, vorherigen Modus wählen.

::5			sty	dloadMode		;Neuen Download-Modus speichern.
			rts

;*** Texteingabe abschließen.
:StopTextEdit		jsr	InputExit		;Texteingabe beenden.

			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** Infotext eingeben
:initUrlLink		LoadW	r0,urlDList
			LoadB	r5L,%00000000		;Bit%7+6=0: Kein CR+SP erlauben.
			jsr	InputText		;Texteingabe-Routine starten.
			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** InfoText löschen.
:clrUrlLink		ldy	#$00			;URL für Link-Liste löschen.
			tya
::1			sta	urlDList,y
			iny
			cpy	#INPUT_MAX_LEN +1
			bne	:1

			LoadW	r15,regDatLnkLst	;Link-Liste aktualisieren.
			jmp	RegisterUpdate

;*** Infotext eingeben
:initUrlDServer		LoadW	r0,urlDFile
			LoadB	r5L,%00000000		;Bit%7+6=0: Kein CR+SP erlauben.
			jsr	InputText		;Texteingabe-Routine starten.
			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** InfoText löschen.
:clrUrlDServer		ldy	#$00			;URL für Download-Datei löschen.
			tya
::1			sta	urlDFile,y
			iny
			cpy	#INPUT_MAX_LEN +1
			bne	:1

			LoadW	r15,regDatFileURL	;Download-Datei aktualisieren.
			jmp	RegisterUpdate

;*** Daten der LinkListe auswerten.
:regInitLinkList	lda	#$00
			sta	lnkCount		;Anzahl Einträge und Zeiger auf
			sta	lnkPointer		;Link-Liste löschen.

			jsr	i_FillRam		;Tabelle für Einträge der
			w	maxListEntries *2	;Link-Liste löschen.
			w	lnkEntries
			b	NULL

			LoadW	r0,BASE_DLIST		;Zeiger auf Anfang Link-Liste.

			ldy	#$00			;Zeiger auf ersten Eintrag.
			sty	r1L

;--- Nächsten Eintrag auswerten.
::init			ldy	#$00			;Länge aktueller Eintrag löschen.
			sty	r1H

::2			lda	(r0L),y			;Zeichen einlesen. $00-Byte?
			beq	:5			; => Ja, Ende Eintrag erreicht...
			cmp	#CR			;Zeilenumbruch?
			beq	:3			; => Ja, Ende Eintrag erreicht...
			cmp	#LF			;Zeilenvorschub?
			beq	:3			; => Ja, Ende Eintrag erreicht...
			inc	r1H			;Länge Eintrag +1.
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#INPUT_MAX_LEN +1	;Max. Länge für URL erreicht?
			bcc	:2			; => Nein, weiter...

::3			lda	#NULL			;CR/LF durch $00-Byte
			sta	(r0L),y			;als Zeilen-Ende ersetzen.

::5			lda	r1H			;Länge Eintrag > 0?
			beq	:next			; => Nein, weiter...

;--- Eintrag in Tabelle kopieren
			ldx	r1L			;Anfangsadresse der aktuellen
			lda	r0L			;URL in der Link-Liste in die
			sta	lnkEntries +0,x		;Tabelle übertragen.
			lda	r0H
			sta	lnkEntries +1,x

			inc	r1L			;Zeiger auf nächsten Eintrag.
			inc	r1L

			inc	lnkCount		;Anzahl Einträge +1.
			lda	lnkCount
			cmp	#maxListEntries		;Max. Anzahl Einträge erreicht?
			bcs	copyLinkEntry		; => Ja, Ende...

;--- Weiter zum nächstem Eintrag.
::next			iny				;Zeiger auf nächstes Zeichen.
			tya
			clc
			adc	r0L
			sta	r0L
			bcc	:4
			inc	r0H

::4			ldy	#$00
			lda	(r0L),y			;Folgt weitere URL?
			bne	:init			; => Ja, weiter...

;*** Aktuellen Eintrag übernehmen.
:copyLinkEntry		lda	lnkPointer		;Zeiger auf Anfang des
			asl				;aktuellen Eintrags aus
			tax				;Tabelle einlesen.
			lda	lnkEntries +0,x
			sta	r0L
			lda	lnkEntries +1,x
			sta	r0H
			ora	r0L			;Ist URL vorhanden?
			beq	:exit			; => Nein, Ende...

			ldy	#$00			;URL aus Link-Liste in
::1			lda	(r0L),y			;Download-Adresse kopieren.
			beq	:3
			sta	urlDFile,y
			iny
			cpy	#INPUT_MAX_LEN
			bcc	:1

::2			lda	#NULL			;Rest des URL-Speichers löschen.
::3			sta	urlDFile,y
			iny
			cpy	#INPUT_MAX_LEN +1
			bne	:3

::exit			rts

;*** Vorheriger Eintrag.
:prevLinkEntry		jsr	visFeedBackPr		;Visuelles Feedback erzeugen.

			lda	lnkCount
			beq	:1
			ldx	lnkPointer
			beq	:1
			dex
			stx	lnkPointer

			jsr	updLinkEntry

::1			jmp	visFeedBackPr		;Visuelles Feedback erzeugen.

;*** Nächster Eintrag.
:nextLinkEntry		jsr	visFeedBackNx		;Visuelles Feedback erzeugen.

			lda	lnkCount
			beq	:1
			ldx	lnkPointer
			inx
			cpx	lnkCount
			bcs	:1
			stx	lnkPointer

			jsr	updLinkEntry

::1			jmp	visFeedBackNx		;Visuelles Feedback erzeugen.

:updLinkEntry		jsr	copyLinkEntry

			lda	dloadMode
			cmp	#2
			bcc	:1

			jsr	splitDLoadURL		;Aktuelle URL aufteilen.
			jsr	createFileName		;Dateiname erzeugen.

			LoadW	r15,regDatFileNm	;InfoText-Option aktualisieren.
			jsr	RegisterUpdate

::1			LoadW	r15,regDatFileURL	;InfoText-Option aktualisieren.
			jsr	RegisterUpdate

:noUpdLinkEntry		rts

;*** Aktuelle URL in Server+Datei aufteilen.
:splitDLoadURL		ldy	urlDFile		;URL definiert?
			bne	:1			; => Ja, weiter...

::init			jsr	setDefaultURL		;Standard-URL setzen.

::1			jsr	getNameServer		;Server-Adresse auswerten.

			ldy	r2L			;Dateiname gefunden?
			beq	:init			; => Nein, Standard-URL verwenden.

;--- Downoad-URL kürzen:
;Erzeugt "http://serverurl..."
			ldx	r2H			;Letzte Position für begrenzte
			lda	#"."			;Länge der Server-Adresse einlesen.
			sta	dboxTxtServer +1,x
			sta	dboxTxtServer +2,x
			sta	dboxTxtServer +3,x
			lda	#NULL			;Ende Download-Adresse markieren.
			sta	dboxTxtServer +4,x

			jsr	getNameFile		;Dateiname auswerten.

;--- Dateiname kürzen:
;Erzeugt "filename...D64".
			ldx	r0L			;Position `.` In Dateiname gültig?
			cpx	#(lenNameRequest -4)
			bcc	:done			; => Ja, weiter...
			ldx	#(lenNameRequest -4)

			lda	#"."			;Dateiname für Download-Info
			sta	dboxTxtDImg -1,x	;kürzen.
			sta	dboxTxtDImg -2,x

			ldy	r0H			;Zeichen hinter `.` in
::2			lda	urlDFile,y		;Download-Info kopieren.
			sta	dboxTxtDImg,x		;Ende erreicht?
			beq	:done			; => Ja, Ende...
			iny
			inx
			cpx	#lenNameRequest		;Länge Dateiname überschritten?
			bcc	:2			; => Nein, weiter...

			lda	#NULL			;Ende Dateiname markieren.
			sta	dboxTxtDImg,x
::done			rts

;*** Standard-URL setzen.
:setDefaultURL		ldy	#0
::1			lda	defaultName,y		;Zeichen aus Default-URL einlesen
			sta	urlDFile,y		;und in Download-Adresse kopieren.
			beq	:done
			iny
			cpy	#255			;Letztes Zeichen erreicht?
			bcc	:1			; => Nein, weiter...

			lda	#NULL			;Ende Download-Adresse markieren.
			sta	urlDFile,y
::done			rts

;*** Datei-Erweiterung suchen.
:getNameServer		ldy	#$00
			sty	r2L			;Zeiger auf letztes "/"-Zeichen.
			sty	r2H			;Letztes Zeichen Server.

::1			lda	urlDFile,y		;Zeichen einlesen. $00-Byte?
			beq	:4			; => Ja, Ende erreicht.
			cpy	#(lenNameServer -4)
			bcs	:2			; => Max. Länge erreicht.
			sta	dboxTxtServer,y		;Zeichen in Download-Info
			sty	r2H			;übertragen und Position speichern.
::2			cmp	#"/"			;URL-Trenner?
			bne	:3			; => Nein, weiter...
			sty	r2L			;Beginn Dateiname speichern.
::3			iny
			cpy	#255			;Letztes Zeichen erreicht?
			bcc	:1			; => Nein, weiter...

::4			rts

;*** Name Download-Datei einlesen.
:getNameFile		ldy	r2L			;Zeiger auf erstes Zeichen für
			iny				;Dateiname setzen.

			ldx	#$00
			stx	r0L			;Position `.` in Download-Adresse.
			stx	r0H			;Position `.` in Dateiname.
::1			lda	urlDFile,y		;Zeichen einlesen. $00-Byte?
			beq	:4			; => Ja, weiter...

			cmp	#"."			;`.` gefunden?
			bne	:2			; => Nein, weiter...
			stx	r0L			;Position in Download-Adresse.
			sty	r0H			;Position in Dateiname.

::2			cpx	#(lenNameRequest -4)
			bcs	:3			; => Länge Dateiname überschritten.
			sta	dboxTxtDImg,x		;Zeichen in Dateiname speichern.
			stx	r2H			;Anzahl Zeichen +1.

::3			inx				;Zeiger auf nächstes Zeichen.
			iny
			cpy	#255			;Letztes Zeichen erreicht?
			bcc	:1			; => Nein, weiter...

::4			ldx	r2H			;Ende Dateiname markieren.
			inx
			lda	#NULL
			sta	dboxTxtDImg,x
			rts

;*** CBM-Dateiname erzeugen.
:createFileName		lda	dloadMode
			cmp	#2			;Als Datei speichern? (Auch SD2IEC)
			bcs	:init			; => Ja, weiter...

::noname		lda	#NULL			;CBM-Dateiname löschen.
			sta	altFileName
			rts

::init			jsr	getEndSvrNm		;Ende Server-Adresse suchen.

			ldy	r2L			;Server-Adresse gültig?
			beq	:noname			; => Nein, CBM-Dateiname löschen.

			jsr	getFNameCBM		;CBM-Dateiname kopieren.

			ldx	r0H			;Position `.` in Dateiname gültig?
			cpx	#(lenNameFile -4)
			bcc	:done			; => Ja, Ende.
			ldx	#(lenNameFile -4)

			ldy	r0L
::1			lda	urlDFile,y
			sta	altFileName,x
			beq	:done
			iny
			inx
			cpx	#lenNameFile
			bcc	:1

			lda	#NULL			;Ende Dateiname markieren.
			sta	dboxTxtDImg,x
::done			rts

;*** Ende Server-Adresse suchen.
:getEndSvrNm		ldy	#$00
			sty	r2L
::1			lda	urlDFile,y		;Zeichen einlesen. $00-Byte?
			beq	:3			; => Ja, Ende...

			cmp	#"/"			;Ende Server-Adresse gefunden?
			bne	:2			; => Nein, weiter...
			sty	r2L			;Position speichern.

::2			iny
			cpy	#255			;Letztes Zeichen erreicht?
			bcc	:1			; => Nein, weiter...

::3			rts

;*** CBM-Dateiname kopieren.
:getFNameCBM		ldy	r2L
			iny

			ldx	#$00
			stx	r0L			;Position `.` in Download-Adresse.
			stx	r0H			;Position `.` in Dateiname.
			stx	r2L			;Länge Dateiname.

::1			lda	urlDFile,y		;Zeichen einlesen. $00-Byte?
			beq	:done			; => Ja, weiter...

			cmp	#"."			;`.` gefunden?
			bne	:2			; => Nein, weiter...
			sty	r0L			;Position `.` in Download-Adresse.
			stx	r0H			;Position `.` in CBM-Dateiname.

::2			cpx	#lenNameFile		;Länge CBM-Dateiname überschritten?
			bcs	:3			; => Ja, weiter...
			sta	altFileName,x		;Zeichen in CBM-Dateiname kopieren.
			stx	r2L			;Anzahl Zeichen +1.

::3			inx				;Zeiger auf nächstes Zeichen.
			iny
			cpy	#255			;Letztes Zeichen erreicht?
			bcc	:1			; => Nein, weiter...

			lda	#NULL
::done			ldx	r2L			;Ende CBM-Dateiname markieren.
			inx
			sta	altFileName,x
			stx	altFileNameLen		;Länge Dateiname.

			lda	r0H			;`.` in Dateiname gefunden?
			beq	:4			; => Nein, weiter...
			tax				;Position `.` in Dateiname einlesen.
::4			dex
			stx	altFileNameDot		;Zeiger auf Zeichen vor `.`.

			rts

;*** SD2IEC-Download-Modus wechseln.
:swapAutoMode		jsr	visFeedBackSM		;Visuelles Feedback.

if FALSE
			lda	urlDList		;URL für Link-Liste definiert?
			beq	:err
			lda	BASE_DLIST
			bne	:swap

::err			jsr	SCPU_Pause		;1/10sec. warten.
			jmp	visFeedBackSM		;Visuelles Feedback.
endif

::swap			ldx	#< dboxDAuto01		;Text für "Mehrfach-Download".
			ldy	#> dboxDAuto01

			lda	dloadAuto		;SD2IEC-Download-Modus
			eor	#%10000000		;wechwseln.
			sta	dloadAuto		;Mehrfach-Modus aktiv?
			bmi	:1			; => Ja, weiter...

			ldx	#< dboxDAuto02		;Text für "Einzel-Download".
			ldy	#> dboxDAuto02

::1			stx	r10L			;Zeiger auf Modus-Text
			sty	r10H			;zwischenspeichern.

			LoadW	r0,Dlg_DAutoMode
			jsr	DoDlgBox		;Status Download-Modus anzeigen.

			ldx	#< Icon_SDALL		;Zeiger auf Icon für
			ldy	#> Icon_SDALL		;"Mehrfach-Download".

			bit	dloadAuto		;Mehrfach-Download aktiv?
			bmi	:2			; => Ja, weiter...

			ldx	#< Icon_SD1		;Zeiger auf Icon für
			ldy	#> Icon_SD1		;"Mehrfach-Download".

::2			stx	r0L			;Zeiger auf Icon-Daten
			sty	r0H			;zwischenspeichern.
			stx	RIcon_SD1 +0
			sty	RIcon_SD1 +1

			lda	#(R1SizeX0 +RTab1_I2 +$30)/8
			sta	r1L
			lda	#RPos1_y +RLine1_6
			sta	r1H

			lda	#Icon_SD1_x
			sta	r2L
			lda	#Icon_SD1_y
			sta	r2H

			jmp	BitmapUp		;Visuelles Feedback.

;*** Textmanager starten.
:openTextMan		jsr	StopTextEdit		;Text-Eingabe beenden.

			jsr	OPEN_SYS_DRIVE		;Start-Laufwerk öffnen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abruch...

			LoadB	r7L,DESK_ACC
			LoadB	r7H,1
			LoadW	r10,textManClass
			LoadW	r6,textManFName
			jsr	FindFTypes		;TextManager suchen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...
			lda	r7H			;Datei gefunden?
			beq	:find			; => Ja, weiter...

::err			LoadW	r0,Dlg_NoTextMan
			jmp	DoDlgBox		;Fehler: TextManager nicht gefunden.

::find			jsr	ResetScreen		;Bildschirm löschen.
			jsr	UseSystemFont		;Systemfont aktivieren.

			jsr	i_FillRam		;Speicher für DialogBox löschen.
			w	417
			w	dlgBoxRamBuf
			b	$00

			ldx	#r15H			;ZeroPage initialisieren.
			lda	#$00
::1			sta	zpage,x
			dex
			cpx	#r0L
			bcs	:1

			LoadW	r6,textManFName
			LoadB	r0L,%00000000
;			LoadB	r10L,$00		;Ist bereits gesetzt.
			jsr	GetFile			;TextManager laden.

			jsr	GetBackScreen		;Hintergrundbild wieder laden.

			jmp	RestartRegMenu		;RegisterMenü erneut starten.

;*** Text-Scrap einlesen.
:textScrapL		lda	#$00			;TextScrap: Link-Liste.
			b $2c
:textScrapD		lda	#$ff			;TextScrap: Download-Adresse.
			sta	textScrapType		;Typ TextScrap speichern.

			lda	mouseYPos		;Maus-Position auswerten.
			sec
			sbc	#(RPos1_y +RLine1_6)
			cmp	#8			;Offset >8?
			bcs	:1			; => Ja, weiter...
			ldx	#$00			;TextScrap einlesen.
			b $2c
::1			ldx	#$ff			;TextScrap speichern.
			stx	textScrapMode		;Modus TextScrap speichern.

			jsr	StopTextEdit		;Texteingabe beenden.

			jsr	visFeedBackTS		;Visuelles Feedback erzeugen.

			jsr	OPEN_SYS_DRIVE
			txa
			bne	:err

			lda	#<textScrapRead		;Routiene für "TextScrap lesen".
			ldx	#>textScrapRead
			bit	textScrapMode		;Modus TextScrap auswerten.
			bpl	:2			; => TextScrap lesen, weiter...
			lda	#<textScrapWrite	;Routiene für "TextScrap speichern".
			ldx	#>textScrapWrite
::2			jsr	CallRoutine		;TextScrap-Routine ausführen.

::err			jsr	visFeedBackTS		;Visuelles Feedback erzeugen.
			rts

;*** Visuelles Feedback für TextScrap erzeugen.
:visFeedBackTS		bit	textScrapMode		;Modus TextScrap auswerten.
			bmi	visFeedBackW

;*** Visuelles Feedback: TextScrap lesen.
:visFeedBackR		ldy	#0			;TextScrap: Link-Liste.
			bit	textScrapType		;Typ TextScrap auswerten.
			bpl	visDoFeedBack		; => Link-Liste, weiter...
			ldy	#12			;TextScrap: Download-Adresse.
			bne	visDoFeedBack

;*** Visuelles Feedback: TextScrap speichern.
:visFeedBackW		ldy	#6			;TextScrap: Link-Liste.
			bit	textScrapType		;Typ TextScrap auswerten.
			bpl	visDoFeedBack		; => Link-Liste, weiter...
			ldy	#18			;TextScrap: Download-Adresse.
			bne	visDoFeedBack

;*** Visuelles Feedback: URL aus Link-Liste auswählen.
:visFeedBackPr		ldy	#24			;Vorherige URL in Link-Liste.
			b $2c
:visFeedBackNx		ldy	#30			;Nächste URL in Link-Liste.
			b $2c

;*** Visuelles Feedback: Mehrfach-/Einzel-Download.
:visFeedBackSM		ldy	#36			;Modus Auto-Download.
			b $2c

;*** Visuelles Feedback: Link-Liste laden.
:visFeedBackLL		ldy	#42			;Link-Liste laden.

;*** Visuelles Feedback ausführen.
:visDoFeedBack		ldx	#0			;Bereichsgrenzen für visuelles
::1			lda	visAreaTab,y		;Feedback einlesen.
			sta	r2L,x
			iny
			inx
			cpx	#6
			bcc	:1

			jsr	InvertRectangle		;Bereich invertieren und
			jmp	SCPU_Pause		;1/10sec. warten.

;*** TextScrap auf Disk speichern.
:textScrapWrite		jsr	setVecScrapData		;Zeiger auf URL-Speicher setzen.

			ldy	#0			;URL in TextScrap kopieren.
			ldx	#6
::1			lda	(r0L),y
			beq	:2
			sta	BASE_SCRAP,x
			iny
			inx
			cpx	#255			;Max. Länge erreicht?
			bcc	:1			; => Nein, weiter...

::2			stx	BASE_SCRAP +0		;TextScrap: Länge.
			lda	#$00
			sta	BASE_SCRAP +1

			lda	#NEWCARDSET		;Font-Information.
			sta	BASE_SCRAP +2

			lda	#$09			;Font-Größe: 9 Punkte.
			sta	BASE_SCRAP +3
			lda	#$00			;Font-ID: BSW-Font.
			sta	BASE_SCRAP +4
			sta	BASE_SCRAP +5

			txa				;Dateigröße für Infoblock
			clc				;berechnen.
			adc	HdrB071 +0
			sta	HdrB073 +0
			lda	#$00
			adc	HdrB071 +1
			sta	HdrB073 +1

			LoadW	r0,textScrapName
			jsr	DeleteFile		;Vorhandenes TextScrap löschen.
			txa				;Diskfehler?
			beq	:save			; => Nein, weiter...
			cpx	#FILE_NOT_FOUND		;Fehler "Datei nicht vorhanden"?
			bne	:err			; => Nein, Fehler ausgeben.

::save			LoadB	r10L,0
			LoadW	r9,HdrB000
			jsr	SaveFile		;TextScrap speichern.
			txa				;Diskfehler?
			beq	:done			; => Nein, weiter...

::err			jsr	doErrorGEOS		;GEOS-Fehler ausgeben.

::done			rts

;*** TextScrap von Disk einlesen.
:textScrapRead		jsr	i_FillRam		;Speicher für TextScrap löschen.
			w	SIZE_SCRAP
			w	BASE_SCRAP
			b	NULL

			LoadW	r6,textScrapName
			jsr	FindFile		;TextScrap suchen.
			txa				;Diskfehler?
			beq	:found
			cpx	#FILE_NOT_FOUND
			bne	:err			; => Ja, Abbruch...

			LoadW	r0,Dlg_NoScrap		;Fehler: Kein TextScrap.
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

::found			lda	dirEntryBuf +1		;Zeiger auf ersten Datensektor
			beq	:err			;einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H

			LoadW	r7,BASE_SCRAP
			LoadW	r2,SIZE_SCRAP
			jsr	ReadFile		;TextScrap in Speicher einlesen.
			txa				;Diskfehler?
			beq	:ok			; => Nein, weiter...
			cpx	#BFR_OVERFLOW		;Anderer Fehler als "Puffer voll"?
			bne	:err			; => Ja, Abbruch...

::ok			jsr	parseTextScrap		;TextScrap analysieren.

			jsr	setVecScrapData		;Zeiger auf URL-Speicher setzen.

			ldy	#0
::1			lda	BASE_SCRAP,y		;Zeichen aus TextScrap einlesen
			sta	(r0L),y			;und in URL kopieren.
			beq	:2
			iny
			cpy	#255			;Max. Länge erreicht?
			bcc	:1			; => Nein, weiter...

			lda	#NULL			;Rest der URL löschen.
::2			sta	(r0L),y
			iny
			bne	:2
			beq	:update			;Register-Optionen aktualisieren.

::err			jsr	doErrorGEOS		;GEOS-Fehler ausgeben.

::update		ldx	#< regDatLnkLst		;LinkListe aktualisieren.
			ldy	#> regDatLnkLst
			bit	textScrapType		;LinkListe oder Download-URL?
			bpl	:setopt			; => LinkListe, weiter...

			jsr	splitDLoadURL		;Aktuelle URL aufteilen.
			jsr	createFileName		;Ggf. Dateiname erstellen.

			LoadW	r15,regDatFileNm	;Dateiname aktualisieren.
			jsr	RegisterUpdate

			ldx	#< regDatFileURL	;Download-URL aktualisieren.
			ldy	#> regDatFileURL

::setopt		stx	r15L
			sty	r15H

			jmp	RegisterUpdate		;Register-Option aktualisieren.

;*** Zeiger auf URL für Link-Liste oder Download-Adresse setzen.
:setVecScrapData	ldx	#< urlDList		;TextScrap: Link-Liste.
			ldy	#> urlDList
			bit	textScrapType		;Typ TextScrap auswerten.
			bpl	:1			; => Link-Liste, weiter...
			ldx	#< urlDFile		;TextScrap: Download-Adresse.
			ldy	#> urlDFile
::1			stx	r0L
			sty	r0H
			rts

;*** TextScrap auswerten.
;Hinweis: Filtert ungültige Zeichen
;aus dem TextScrap heraus.
:parseTextScrap		ldy	#0
			ldx	#6			;NEWCARDSET überlesen.
::1			lda	BASE_SCRAP,x		;Zeichen einlesen. $00-Byte?
			beq	:7			; => Ja, Ende erreicht...

			cmp	#CR			;Zeilenumbruch?
			beq	:4			; => Ja, ignorieren.
			cmp	#TAB			;Tabulator?
			beq	:4			; => Ja, ignorieren...
			cmp	#NEWCARDSET		;Zeichensatz-Daten?
			bne	:2			; => Nein, weiter...
			txa
			clc
			adc	#4
			bcs	:6			;Überlauf? => Ja, Ende...
			tax
			bne	:5

::2			cmp	#ESC_RULER		;Seitenformat-Daten?
			bne	:3			; => Nein, weiter..
			txa
			clc
			adc	#1 +11*2 +4
			bcs	:6			;Überlauf? => Ja, Ende...
			tax
			bne	:5

::3			sta	BASE_SCRAP,y		;Zeichen in Speicher kopieren.
			iny
::4			inx
::5			cpx	#255			;Max. Länge erreicht?
			bcc	:1			; => Nein, weiter...

::6			lda	#NULL			;Rest TextScrap-Speicher löschen.
::7			sta	BASE_SCRAP,y
			iny
			bne	:7

			rts

;*** Download-Liste aktualisieren.
:reloadDList		jsr	visFeedBackLL		;Visuelles Feedback.

			lda	urlDList		;URL für Link-Liste definiert?
			bne	:reload			; => Ja, weiter...

			jsr	SCPU_Pause		;1/10sec. warten.
			jmp	visFeedBackLL		;Visuelles Feedback.

::reload		jsr	i_FillRam		;Speicher für Link-Liste löschen.
			w	SIZE_DLIST
			w	BASE_DLIST
			b	NULL

			jsr	clrUrlDServer		;Download-Adresse löschen, wird
							;durch ersten Eintrag ersetzt.

			jsr	drawDLoadBoxLst		;Status-Box anzeigen.

if DEMO_MODE = DEMO_TRUE
			jsr	initLnkLst_DEMO		;Dummy-Werte kopieren.
			jsr	SCPU_Pause		;3x 1/10sec. warten.
			jsr	SCPU_Pause
			jsr	SCPU_Pause
endif
if DEMO_MODE = DEMO_FALSE
			lda	#"W"			;GET-Befehl initialisieren.
			sta	com_getlnk
			lda	#$01			;Befehl $01.
			sta	com_getlnk_mode

			LoadW	com_getlnk_size,4	;Länge Befehl initialisieren.

			ldx	#$00
			ldy	#$00
::1			lda	urlDList,y		;URL in GET-Befehl übertragen und
			beq	:3			;Befehlslänge ermitteln.
			sta	com_getlnk_data,y

			inc	com_getlnk_size +0
			bne	:2
			inc	com_getlnk_size +1

::2			iny
			cpy	#254			;Alle Zeichen kopiert?
			bcc	:1			; => Nein, weiter...

			lda	#NULL			;Rest der Download-Adresse löschen.
::3			sta	urlDList,y
			iny
			cpy	#255
			bne	:3

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:5			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	; => 1MHz aktivieren.

::5			jsr	_WiC64_Init		;WiC64 initialisieren.

			lda	#<com_getlnk
			ldy	#>com_getlnk
			jsr	_WiC64_SendCom 		;HTTP/GET an WiC64 senden.
			txa				;Fehler?
			bne	:6			; => Ja, Abbruch...

			lda	#<SIZE_DLIST		;Puffergröße definieren.
			sta	r14L
			lda	#>SIZE_DLIST
			sta	r14H

			lda	#<BASE_DLIST		;Daten von WiC64 empfangen.
			ldy	#>BASE_DLIST
			ldx	#TRUE			;Puffer initialisieren.
			jsr	_WiC64_GetData

::6			stx	dloadStatus		;Fehlerstatus speichern.

			jsr	_WiC64_Init		;WiC64 initialisieren.
			jsr	_WiC64_ReadMode		;WiC64 auf Empfang schalten.

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:7			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo zurücksetzen.

::7			jsr	DoneWithIO		;I/O-Bereich abschalten.

			ldx	dloadStatus		;Download erfolgreich?
			lda	BASE_DLIST +0		;Rückmeldung `!0` steht für
			cmp	#"!"			;`URL ungültig`.
			bne	:8
			lda	BASE_DLIST +1
			cmp	#"0"
			bne	:8
			lda	BASE_DLIST +2		;Mehr als zwei Zeichen?
			bne	:8			; => Ja, Kein Fehler.
			ldx	#ERR_BAD_URL		;Fehler, URL ungültig.
::8			txa
			beq	:init			; => Ja, weiter...

			jsr	doErrorMain		;Fehlermeldung ausgeben.

			jsr	i_FillRam		;Speicher für Link-Liste löschen.
			w	SIZE_DLIST
			w	BASE_DLIST
			b	NULL
endif

;--- Link-Liste auswerten.
::init			jsr	regInitLinkList		;Link-Liste initialisieren.

			lda	dloadMode
			cmp	#2			;Dateiname aktualisieren?
			bcc	:regupd			; => Nein, weiter...

			jsr	splitDLoadURL		;Aktuelle URL aufteilen.
			jsr	createFileName		;Dateiname erzeugen.

;--- Register-Menü aktualisieren.
::regupd		jsr	RegisterSetFont		;Register-Font aktivieren.
			jsr	RegisterAllOpt		;Register-Menü aktualisieren.

::exit			rts

;*** Dummy-Werte für Link-Liste kopieren.
if DEMO_MODE = DEMO_TRUE
:initLnkLst_DEMO	jsr	i_MoveData
			w	dataLnkLst_DEMO
			w	BASE_DLIST
			w	(dataLnkLstEnd - dataLnkLst_DEMO)
			rts
endif

;*** Download starten.
:StartDownload		jsr	StopTextEdit		;Texteingabe beenden.

			jsr	OPEN_TGT_DRIVE		;Ziel-Laufwerk öffnen.
			txa				;Diskfehler?
			beq	:init			; => Nein, weiter...

			lda	dloadMode		;Download-Modus testen:
			cmp	#2			;Dxx/SD2IEC?
			beq	:init			; => Ja, keine Disk erforderlich.
			cmp	#5			;Datei/SD2IEC?
			beq	:init			; => Ja, keine Disk erforderlich.
			jmp	doErrorGEOS		;GEOS-Fehler ausgeben.

::init			jsr	getDriveMode		;Laufwerksmodus konvertieren.
			jsr	getMediaSize		;Native: Mediengröße einlesen.
			jsr	getFileType		;Download (Dxx/Datei) auswerten.

			bit	dloadAuto		;Auto-Download aktiv?
			bpl	:2			; => Nein, weiter...
			lda	dloadMode
			cmp	#2			;Ziel-Laufwerk geeignet?
			bcs	:1			; => Ja, weiter...

			jsr	swapAutoMode		;Auto-Download abschalten.
			jmp	:2			; => Weiter mit Einzel-Download...

::1			lda	#FALSE			;Flag löschen:
			sta	altFileNameFix		;"Dateinamen geändert"

			jsr	testFileExist		;Ggf. Dateiname anpassen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	i_FillRam		;Speicher für Dateinamen löschen.
			w	SIZE_FLIST
			w	BASE_FLIST
			b	NULL

::2			jsr	checkCompat		;Kompatibilität testen.
			txa				;Download kompatibel?
			beq	:info			; => Ja, Info ausgeben.

			jsr	dBoxCompatErr		;Fehlrmeldung ausgeben.
			jmp	:exit			;Abbruch...

::info			LoadW	r0,Dlg_DLoadInfo
			jsr	DoDlgBox		;Infobox anzeigen.

			lda	sysDBData
			cmp	#YES			;Download starten?
			bne	:exit			; => Nein, Ende..

			bit	dloadAuto		;Auto-Download aktiv?
			bpl	:next			; => Nein, weiter...

			lda	#%00000000		;Flag setzen: Keine SwapList.
			sta	flagSwapList

;			lda	#0			;Download-Zähler löschen.
			sta	dloadCount

			LoadW	a8,BASE_FLIST		;Zeiger auf Namensspeicher.

;--- Download starten.
::next			jsr	copyDLoadURL		;Download-URL kopieren.
			jsr	drawDLoadBoxImg		;Download-Info ausgeben.

			jsr	getWiC64file4		;WiC64-Download ausführen.

			lda	dloadStatus		;Download erfolgreich?
			beq	:ok			; => Ja, weiter...
::err			jsr	doErrorMain		;Fehlermeldung ausgeben.
			jmp	:update

;--- Download erfolgreich.
::ok			bit	dloadAuto		;Auto-Download aktiv?
			bpl	:done			; => Nein, weiter...

			inc	dloadCount		;Download-Zähler +1.
			jsr	addDLoadFName		;Dateiname in Zwischenspeicher.

			jsr	checkAutoDLoad		;Download-Modus testen.
			txa				;Weitere Datei downloaden?
			beq	:next			; => Ja, weiter...

			jsr	checkMakeSwap		;SwapList erstellen.
			txa				;Liste erstellt?
			beq	:update			; => Ja, Ende...
			cpx	#CANCEL_ERR		;Laufwerksfehler?
			bne	:update			; => Ja, Ende...

;--- SWAPLIST.LST öffnen.
::done			lda	dloadMode		;Download als Datei in
			cmp	#5			;SD2IEC-Verzeichnis speichern?
			bne	:update			; => Nein, Ende...
			bit	dloadFType		;DiskImage?
			bpl	:update			; => Ja, keine SwapList...

			bit	dloadAuto		;Auto-Download aktiv?
			bpl	:7			; => Nein, weiter...
			lda	altFileNameFix
			cmp	#FALSE			;Mussten Dateinamen geändert werden?
			bne	:update			; => Ja, SwapList überspringen.

::7			jsr	openSwapList		;SwapList testen...

;--- Download beendet.
::update		jsr	regInitTgtDrv		;Laufwerk/Diskname aktualisieren.

::exit			jsr	RegisterSetFont		;Register-Font aktivieren.
			jmp	RegisterAllOpt		;Register-Menü aktualisieren.

;*** Laufwerksmodus konvertieren (D64, D71...)
:getDriveMode		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC?
			bne	:1			; => Ja, weiter...
			lda	#"D"			;`Dxx`...
			b $2c
::1			lda	#"S"			;`Sxx`...
			sta	dboxDiskType +0

			lda	driveType -8,x		;Laufwerkstyp einlesen.
			and	#ST_DMODES		;Emulationsformat isolieren.
			asl
			tax
			lda	dboxTypeTab +0,x	;41/71/81/NP.
			sta	dboxDiskType +1
			lda	dboxTypeTab +1,x
			sta	dboxDiskType +2
			rts

;*** Native: Mediengröße einlesen.
:getMediaSize		lda	curType			;Laufwerksmodus in Text
			and	#ST_DMODES		;umwandeln (D64, D71...)
			cmp	#DrvNative		;CMD-NativeMode?
			bne	:exit			; => Nein, weiter...

			ldx	#1			;Größe des aktuellen Mediums
			stx	r1L			;einlesen: Sektor #1/2, Byte #8.
			inx
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			ldy	#0			;Vorgabewert: Keine Disk.
			txa				;Diskfehler?
			bne	:1			; => Ja, weiter...
			lda	diskBlkBuf +2
			cmp	#$48			;Kennbyte einlesen, Typ `H` ?
			bne	:1			; => Nein, weiter...
			ldy	diskBlkBuf +8		;Mediengröße einlesen und für
::1			sty	dloadSizeNM +1		;Download-Check speichern.
::exit			rts

;*** Download (Dxx/Datei) auswerten.
:getFileType		jsr	splitDLoadURL		;Aktuelle URL aufteilen.

			ldy	#$00			;Punkt für Erweiterung in
			sty	r0L			;Dateiname suchen.
::1			lda	dboxTxtDImg,y		;Ende Dateiname erreicht?
			beq	:test			; => Ja, weiter...
			cmp	#"."			;Punkt gefunden?
			bne	:2			; => Nein, weiter...
			sty	r0L			;Position für Punkt speichern.
::2			iny
			cpy	#(lenNameRequest +1)
			bcc	:1			;Suche fortsetzen.
			bcs	:file			; => Suche abgeschlossen.

::test			lda	#"D"			;Vorgabe für `ImageTyp unbekannt`.
			sta	dboxDImgType +0
			lda	#"A"
			sta	dboxDImgType +1
			lda	#"T"
			sta	dboxDImgType +2

			ldy	r0L
			beq	:file
			iny
			lda	dboxTxtDImg,y		;Zeichen hinter Punkt einlesen.
			beq	:file			; => Kein Image, ignorieren...

			cmp	#"d"			;`Dxx` oder `dxx`?
			beq	:type			; => Ja, weiter...
			cmp	#"D"
			bne	:file			; => Kein Image, ignorieren...

::type			iny
			lda	dboxTxtDImg,y		;Nächstes Byte einlesen.
			beq	:file			; => Kein Image, ignorieren...

			ldx	#Drv1541
			cmp	#"6"			;`D64`?
			beq	:image			; => Ja, weiter...
			inx				;Drv1571
			cmp	#"7"			;`D71`?
			beq	:image			; => Ja, weiter...
			inx				;Drv1581
			cmp	#"8"			;`D81`?
			beq	:image			; => Ja, weiter...
			inx				;DrvNative
			cmp	#"N"			;`DNP`?
			beq	:image			; => Ja, weiter...
			cmp	#"n"			;`dnp`?
			bne	:file			; => Kein Image, ignorieren...
::image			sta	dboxDImgType +1		;ImageTyp erkannt und in
			lda	dboxTxtDImg  +1,y	;Dialogboxtext kopieren.
			sta	dboxDImgType +2
			b $2c				; => Image-Typ im XReg.
::file			ldx	#$ff			; => Image-Typ nicht erkannt.
			stx	dloadFType		;Image-Typ speichern.
			rts

;*** Download-URL kopieren.
:copyDLoadURL		lda	#"W"			;GET-Befehl initialisieren.
			sta	com_geturl
			lda	#$25
			sta	com_geturl_mode

			LoadW	com_geturl_size,4	;Länge GET-Befehl initialisieren.

			ldy	#$00
::1			lda	urlDFile,y		;Ende URL erreicht?
			beq	:3			; => Ja, weiter...
			sta	com_geturl_data,y	;Zeichen in URL kopieren.

			inc	com_geturl_size +0
			bne	:2
			inc	com_geturl_size +1

::2			iny
			cpy	#254			;Gesamte URL durchsucht?
			bcc	:1			; => Nein, weiter...

			lda	#NULL			;Rest der URL löschen.
::3			sta	urlDFile,y
			iny
			cpy	#255
			bne	:3
			rts

;*** Dateiname in Zwischenspeicher kopieren.
:addDLoadFName		lda	dloadFType		;Dateityp = DiskImage?
			bmi	:1			; => Nein, weiter...

;SWAPLIST erstellen wenn mind. ein
;DiskImage geladen wurde, egal welcher
;Typ von DiskImage.
;			eor	curType
;			and	#ST_DMODES		;Kompatibles DiskImage?
;			bne	:1			; => Nein, weiter...

			lda	#%10000000		;Flag setzen: SwapList erzeugen.
			sta	flagSwapList

::1			ldy	#0			;Dateiname in Zwischenspeicher
::2			lda	altFileName,y		;kopieren.
			sta	(a8L),y
			beq	:3
			iny
			cpy	#lenNameFile
			bcc	:2

::3			lda	a8L			;Zeiger auf Zwischenspeicher
			clc				;korrigieren.
			adc	#(lenNameFile +1)
			sta	a8L
			bcc	:4
			inc	a8H

::4			rts

;*** Kompatibilität testen.
:checkCompat		ldx	dloadFType		;Image-Typ erkannt?
			bpl	:1			; => Ja, weiter...

			lda	dloadMode		;Download-Modus einlesen.
			cmp	#3
			bcs	:ok			;Datei-Modus: Nicht testen.
			bcc	:unknown		;Fehler, Format unbekannt.

::1			lda	dloadMode		;Download-Modus einlesen.
			cmp	#5			;Datei/SD2IEC?
			beq	:ok			; => Ja, nicht testen.
			cmp	#2
			beq	:ok			;Dxx/SD2IEC: Nicht testen.
			bcc	:image			;Dxx/Disk+RAM: Ziel-Laufwerk testen.

::file			lda	curType			;Speichern als Datei nur auf
			and	#ST_DMODES		;größeren Laufwerken möglich.
			cmp	dloadFType
			bcc	:dsksize		;D71 auf D64 => Fehler.
			beq	:dsksize		;D71 auf D71 => Fehler.
			bcs	:ok			;Kein ImageTyp erkannt, weiter...

::image			txa				;Speichern als DiskImage nur auf
			eor	curType			;gleichem Laufwerkstyp möglich.
			and	#ST_DMODES
			beq	:ok			; => Gleiches Laufwerk, weiter...

::compat		ldx	#INCOMPATIBLE		;Fehler: Nicht kompatibel.
			rts

::dsksize		ldx	#INSUFF_SPACE		;Fehler: Ziel-Laufwerk zu klein.
			rts

::unknown		ldx	#STRUCT_MISMAT		;Fehler: Dateiformat nicht erkannt.
			rts

::ok			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Download nicht kompatibel, Fehler ausgeben.
:dBoxCompatErr		cpx	#INSUFF_SPACE
			beq	:dsksize
;			cpx	#STRUCT_MISMAT
;			beq	:unknown
			cpx	#INCOMPATIBLE
			bne	:unknown

::compat		lda	#< Dlg_CompatErr	;Fehler: Nicht kompatibel.
			ldx	#> Dlg_CompatErr
			bne	:errbox
::dsksize		lda	#< Dlg_DskSizeErr	;Fehler: Ziel-Laufwerk zu klein.
			ldx	#> Dlg_DskSizeErr
			bne	:errbox
::unknown		lda	#< Dlg_UnknownDxx	;Fehler: Dateiformat nicht erkannt.
			ldx	#> Dlg_UnknownDxx
::errbox		sta	r0L
			stx	r0H
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

;*** SD2IEC-Auto-Download.
:checkAutoDLoad		lda	dloadMode		;Download-Modus testen.
;			cmp	#2			;Dxx/SD2IEC?
;			beq	:test			; => Ja, weiter...
;			cmp	#5			;Datei/SD2IEC?
;			bne	:exit			; => Nein, Ende...
			cmp	#2			;Dxx/SD2IEC oder Datei-Download?
			bcc	:exit			; => Ja, weiter...

::test			bit	dloadAuto		;Auto-Download aktiv?
			bmi	:1			; => Ja, weiter...

::exit			ldx	#FILE_NOT_FOUND		;Keine weitere Datei zum Download.
			rts				;Ende.

::1			lda	lnkCount		;Mehr als eine Datei in Link-Liste?
			beq	:exit			; => Nein, Ende...
			lda	urlDList		;URL für Link-Liste definiert?
			beq	:exit			; => Nein, Ende...
			lda	BASE_DLIST		;Daten für link-Liste vorhanden?
			beq	:exit			; => Nein, Ende...

::2			ldx	lnkPointer		;Zeiger auf nächste Datei in
			inx				;Link-Liste.
			cpx	lnkCount		;Ende erreicht?
			bcs	:exit			; => Ja, Ende...
			stx	lnkPointer

			jsr	copyLinkEntry		;Aktuellen Link-Eintrag kopieren.

			jsr	getFileType		;Download (Dxx/Datei) auswerten.

			lda	dloadMode		;Download-Modus auswerten.
			cmp	#$02			;Dxx/SD2IEC?
			beq	:3			; => Ja, weiter...
			cmp	#$05			;Datei/SD2IEC?
			bne	:5			; => Nein, kein SD2IEC, weiter...

			lda	#$02			;Vorgabe Dxx/SD2IEC.
::3			ldx	dloadFType		;Image-Typ erkannt?
			bpl	:4			; => Ja, weiter...
			lda	#$05			;Unbekanntes Format -> Datei/SD2IEC.
::4			sta	dloadMode		;Download-Modus speichern.

;			jsr	splitDLoadURL		;Aktuelle URL aufteilen.
::5			jsr	createFileName		;Dateiname erzeugen.

			jsr	testFileExist		;Ggf. Dateiname anpassen.
			txa
			bne	:err

			jsr	checkCompat		;Kompatibilität testen.
			txa				;Download kompatibel?
			bne	:exit			; => Nein, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			rts

;*** Mehrfach-Downoad: SwapList erstellen?
:checkMakeSwap		ldx	curDrive
if DEMO_MODE = DEMO_FALSE
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:exit			; => Nein, kein SD2IEC.
endif
if DEMO_MODE = DEMO_TRUE
			lda	driveType -8,x		;Laufwerksmodus einlesen.
			bmi	:exit			; => Nein, kein SD2IEC.
endif

			lda	dloadMode		;Download-Modus auswerten.
			cmp	#2			;Dxx/SD2IEC?
			beq	:0			; => Ja, weiter...
			cmp	#5			;Datei/SD2IEC?
			bne	:exit			; => Nein, Ende...

::0			lda	dloadCount
			cmp	#2			;Weniger als zwei Dateien?
			bcc	:exit			; => Ja, Ende...

			bit	flagSwapList		;Wurden Dxx-Images geladen?
			bmi	:1			; => Ja, weiter...

::exit			ldx	#CANCEL_ERR		;Keine SWAPLIST erstellen.
			rts

::1			LoadW	r0,Dlg_MakeSwap
			jsr	DoDlgBox		;Dialogbox: SWAPLIST erstellen?

			lda	sysDBData
			cmp	#YES			;SWAPLIST erstellen?
			bne	:exit			; => Nein, Abbruch...

			LoadW	r10,swapLstEditNm
			LoadW	r0,Dlg_SwapName
			jsr	DoDlgBox		;Dateiname für SWAPLIST eingeben.

			lda	sysDBData
			cmp	#CANCEL			;SWAPLIST erstellen?
			beq	:exit			; => Nein, Abbruch...

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			jsr	openDevChan		;Befehlskanal öffnen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			jsr	getSD2IECmode		;SD2IEC-Modus ermitteln.
			txa				;DiskImage aktiv?
			bmi	:2			; => Ja, weiter...
			bne	:error			; => Fehler, keine SD-Karte.

			jsr	exitDiskImage		;Aktuelles DiskImage verlassen.

::2			ldy	#0			;Länge Dateiname ermitteln.
::3			lda	swapLstEditNm,y		;Ende erreicht?
			beq	:4			; => Ja, weiter...
			iny
			cpy	#16			;Max. 16Zeichen?
			bcc	:3			; => Nein, weiter...

::4			tya
			clc
			adc	#2			;"Q:name..."
			ldx	#< swapLstNewNm
			ldy	#> swapLstNewNm
			jsr	SETNAM			;Dateiname festlegen.
			lda	#5
			ldx	curDevice
			ldy	#1
			jsr	SETLFS			;open 5,dv,1,"Q:name"
			jsr	OPENCHN			;Datei öffnen.

			ldx	STATUS			;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldx	#5			;Ausgabekanal festlegen.
			jsr	CKOUT

			LoadW	a8,BASE_FLIST		;Zeiger auf Liste mit Dateinamen.

::5			ldy	#0
::6			lda	(a8L),y			;Zeichen aus Dateiname einlesen.
			beq	:7			;Ende erreicht? => Ja, weiter...
			jsr	CIOUT			;Zeichen in SWAPLIST ausgeben.
			iny
			cpy	#16			;Dateiname kopiert?
			bcc	:6			; => Nein, weiter...

::7			lda	#CR			;Neue Zeile einfügen.
			jsr	CIOUT

			lda	a8L			;Zeiger auf Dateiliste
			clc				;korrigieren.
			adc	#(lenNameFile +1)
			sta	a8L
			bcc	:8
			inc	a8H

::8			dec	dloadCount		;Alle Dateien ausgegeben?
			bne	:5			; => Nein, weiter...

			jsr	getDiskError		;Laufwerks-Status einlesen.

			jsr	CLRCHN			;Standard-I/O aktivieren.

			lda	#5
			jsr	CLOSE			;Datei schließen.

			jsr	closeDevChan		;Datenkanal schließen.

			ldx	dskErrCode		;Fehler-Status einlesen.
endif
if DEMO_MODE = DEMO_TRUE
			ldx	#NO_ERROR		;"00, OK, 00, 00"
endif

::error			jsr	DoneWithIO		;I/O-Bereich abschalten.

			txa				;Fehler?
			bne	:skip			; => Ja, Abbruch...

			LoadW	r0,swapLstEditNm
			jsr	openCustomList		;Neue SWAPLIST aktivieren.

::skip			rts

;*** Dateiname testen.
:testFileExist		ldx	#INCOMPATIBLE
			lda	dloadMode		;Download-Modus auswerten.
			cmp	#2			;Dxx/RAM oder Dxx/Disk?
			bcc	:err			; => Ja, Fehler...
;			cmp	#2			;Dxx/SD2IEC?
			beq	:disk			; => Ja, Datei über Kernal suchen...
			cmp	#4			;Datei/Disk?
			beq	:geos			; => Ja, Datei über GEOS suchen...
			cmp	#5			;Datei/SD2IEC?
			beq	:disk			; => Ja, Datei über Kernal suchen...
			cmp	#3			;Datei/RAM?
			bne	:err			; => Nein, Fehler...

;--- RAM-Disk oder Diskette.
::geos			LoadW	r6,altFileName
			jsr	FindFile		;Datei auf RAM-Disk suchen.
			txa				;Datei vorhanden?
			beq	setNewName		; => Ja, Name anpassen...
			cpx	#FILE_NOT_FOUND		;Fehler "Nicht gefunden"?
			bne	:err			; => Nein, Abbruch...
::ok			ldx	#NO_ERROR		;Kein Fehler, Ende.
::err			rts

;--- Disk/SD2IEC.
::disk			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			jsr	openDevChan		;Befehlskanal öffnen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			jsr	getSD2IECmode		;SD2IEC-Modus ermitteln.
			txa				;DiskImage aktiv?
			bmi	:1			; => Ja, weiter...
			bne	:error			; => Fehler, keine SD-Karte.

			jsr	exitDiskImage		;Aktuelles DiskImage verlassen.

::1			lda	altFileNameLen
			ldx	#< altFileName
			ldy	#> altFileName
			jsr	SETNAM			;Dateiname festlegen.
			lda	#4
			ldx	curDevice
;			ldy	#0
			tay
			jsr	SETLFS			;open 4,dv,0,"name"
			jsr	OPENCHN			;Datei öffnen.
			lda	#4
			jsr	CLOSE			;Datei schließen.

			jsr	getDiskError		;Laufwerks-Status einlesen.

			jsr	CLRCHN			;Standard-I/O aktivieren.

			jsr	closeDevChan		;Datenkanal schließen.

			ldx	dskErrCode		;Fehler-Status einlesen.
endif
if DEMO_MODE = DEMO_TRUE
			ldx	#$62			;"62, File not found"
endif
::error			jsr	DoneWithIO		;I/O-Bereich abschalten.
			txa				;Datei gefunden?
			beq	setNewName		; => Ja, neuen Namen festlegen.
			cpx	#$62			;Datei nicht gefunden?
			beq	:ok			; => Ja, Kein Fehler, Ende...
			bne	:err			; => Fehler, Abbruch...

;*** Neuen Dateinamen setzen.
:setNewName		lda	#TRUE
			sta	altFileNameFix

			ldx	altFileNameDot
::1			lda	altFileName,x		;Zeichen vor "." einlesen.
			cmp	#"0"			;Bereits eine Zahl?
			bcc	:set0			; => Nein, mit "0" starten...
			cmp	#"9"			;9 Dateinamen getestet?
			beq	:2			; => Ja, mit Datei 10 fortfahren...
			bcc	:next			; => Ja, Zahl erhöhen, weiter...
			bcs	:set0			; => Keine Zahl, mit "0" starten...

::2			dex				;Vorheriges Zeichen möglich?
			bne	:3			; => Ja, weiter...
::cancel		ldx	#CANCEL_ERR		; => Nein, Abbruch...
			rts

::3			lda	altFileName,x		;Vorhiges Zeichen testen.
			cmp	#"0"			;Bereits eine Zahl?
			bcc	:4			; => Nein, mit "0" starten...
			cmp	#"9"			;Bereits 99 Dateinamen getestet?
			beq	:cancel			; => Ja, Abbruch..
			bcc	:5			; => Nächste 10 Dateinamen testen.

::4			lda	#"0" -1			;Datei "tes0x.dat"
			sta	altFileName,x
::5			inc	altFileName,x
			inx

::set0			lda	#"0"			;Datei "test0.dat"
			sta	altFileName,x
::next			inc	altFileName,x
			jmp	testFileExist		;Neuen Dateinamen testen.

;*** Download-Routinen.
if DEMO_MODE = DEMO_FALSE
:readWiC64byte = read_byte
endif
if DEMO_MODE = DEMO_TRUE
:readDummyByte		lda	rasreq
			and	#%00001111
			tax
::1			dex
			bne	:1
			ldx	#NO_ERROR
			rts

:readWiC64byte = readDummyByte
endif

;*** Spungtabelle.
:dl_jmp_open		jmp	(a2)			;Datei öffnen.
:dl_jmp_init		jmp	(a3)			;Download initialisieren.
:dl_jmp_write		jmp	(a4)			;Daten herunterladen und speichern.
:dl_jmp_close		jmp	(a5)			;Datei schließen.

;*** Download starten.
:getWiC64file4		lda	dloadMode		;Write to RAMDisk...
			asl
			asl
			asl
			tay
			ldx	#0
::l0			lda	dloadVecTab,y		;Routinen nach :a2-:a5 kopieren.
			sta	a2L,x
			iny
			inx
			cpx	#8
			bcc	:l0

			jsr	dl_jmp_open		;Ziel-Datei öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

if DEMO_MODE = DEMO_FALSE
			jsr	_WiC64_Init		;WiC64 initialisieren.

			lda	#<com_geturl
			ldy	#>com_geturl
			jsr	_WiC64_SendCom 		;HTTP/GET an WiC64 senden.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	_WiC64_InitGet4		;Datenempfang initialisieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
endif

			lda	lenDataSize +1
			cmp	#$02 			;Bei Fehler = $02? Anzahl/LOW.
			bne	:prepare		; => Nein, weiter...
			lda	lenDataSize +0
;			cmp	#$00 			;Bei Fehler = $00? Anzahl/HIGH.
			bne	:prepare		; => Nein, weiter...
			lda	lenDataSize +3		;Fehler-Status?
			cmp	#"0"
			bne	:prepare		; => Nein, weiter...
			lda	lenDataSize +2
			cmp	#"!" 			;HTTP-Fehler = "!"?
			beq	:no_url			; => Ja, Abbruch...

::prepare		jsr	dl_jmp_init		;Download initialisieren.
			stx	dloadStatus		;Fehler-Status speichern.

			jsr	initProcData		;Status-Info initialisieren.

			ldx	#4 -1			;Dateigröße nach :a0-:a1 kopieren.
::l1			lda	lenDataSize,x
			sta	a0L,x
			dex
			bpl	:l1

;--- Download via HTTP/GET starten.
::init			lda	extclr			;Rahmenfarbe für Debug-Modus
			pha				;zwischenspeichern.

			lda	#timeout_default 	;Timeout initialisieren.
			sta	r0L

			jsr	dl_jmp_write		;Download starten.

			ldx	dloadStatus		;Letzter Sektor gespeichert?
			cpx	#BFR_OVERFLOW		;(Kennbyte für BufferOverflow)
			bne	:err			; => Nein, weiter...

			ldx	#NO_ERROR		;Fehler ignorieren.

;--- GET beenden, Programmlänge ermitteln.
::err			pla
			sta	extclr			;Rahmenfarbe zurücksetzen.

			b $2c				;Fehler-Status überspringen.
::no_url		ldx	#ERR_BAD_URL		;Download-URL ungültig.
::error			stx	dloadStatus		;Fehler-Status speichern.

::exit			jmp	dl_jmp_close		;Datei schließen.

;*** 32Bit-Zähler korrigieren.
;Bei Dateien alle Bytes zählen.
:decByteCount4		ldx	a1H
			bne	:256b
			ldx	a1L
			bne	:64k
			ldx	a0H
			bne	:16m
			ldx	a0L
			beq	:done

::4gb			dec	a0L
::16m			dec	a0H
::64k			dec	a1L
::256b			dec	a1H

			ldx	#$ff
::done			stx	flagEOF
			rts

;*** 24Bit-Zähler korrigieren.
;Bei Dxx nur 256Byte-Blocks zählen.
:decByteCount3		ldx	a1L
			bne	:64k
			ldx	a0H
			bne	:16m
			ldx	a0L
			beq	:done

::4gb			dec	a0L
::16m			dec	a0H
::64k			dec	a1L

			ldx	#$ff
::done			stx	flagEOF
			rts

;*** Status-Box "DOWNLOAD" anzeigen.
:drawDLoadBoxLst	lda	#$00
			b $2c
:drawDLoadBoxImg	lda	#$ff
			pha

			lda	#$01			;Füllmuster löschen.
			jsr	SetPattern

			jsr	i_Rectangle		;Status-Box zeichnen.
			b	STATUS_Y +8
			b	(STATUS_Y + STATUS_H) +8 -1
			w	STATUS_X +8
			w	(STATUS_X + STATUS_W) +8 -1

			lda	C_WinShadow		;Farbe für Titelzeile setzen.
			jsr	DirectColor

			lda	#$00			;Füllmuster löschen.
			jsr	SetPattern

			jsr	i_Rectangle		;Status-Box zeichnen.
			b	STATUS_Y
			b	(STATUS_Y + STATUS_H) -1
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	#%11111111		;Rahmen für Status-Box.
			jsr	FrameRectangle

			lda	C_DBoxBack		;Farbe für Status-Box.
			jsr	DirectColor

			jsr	i_Rectangle		;Titelzeile löschen.
			b	STATUS_Y
			b	STATUS_Y +15
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	C_DBoxTitel		;Farbe für Titelzeile setzen.
			jsr	DirectColor

			jsr	UseSystemFont

			LoadW	r0,jobInfTxHead		;`WiC64 DOWNLOAD`
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +11
			jsr	PutString

			ldx	#< infoTxDLoadImg	;`Datei wird heruntergeladen...`
			ldy	#> infoTxDLoadImg
			pla
			pha
			bne	:1
			ldx	#< infoTxDLoadLst	;`Link-Liste wird geladen...`
			ldy	#> infoTxDLoadLst
::1			stx	r0L
			sty	r0H

			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +16 +12
			jsr	PutString

			LoadW	r0,infoTxDLoadNam	;`Datei: `
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +16 +12 +12
			jsr	PutString

			lda	#< dboxTxtDImg
			ldx	#> dboxTxtDImg
			ldy	altFileName
			beq	:2
			lda	#< altFileName
			ldx	#> altFileName
::2			sta	r0L
			stx	r0H
			jsr	PutString

			pla
			beq	:exit

			jsr	i_FrameRectangle	;Rahmen für Status-Box.
			b	INFO_Y -1
			b	INFO_Y +8
			w	INFO_X -1
			w	INFO_X +10*8
			b	%11111111

			lda	#$00			;Füllmuster löschen.
			jsr	SetPattern

			jsr	i_Rectangle		;Status-Box zeichnen.
			b	INFO_Y
			b	INFO_Y +8 -1
			w	INFO_X
			w	INFO_X +10*8 -1

			lda	C_InputField		;Farbe für Titelzeile setzen.
			jsr	DirectColor

			LoadW	r0,infoTxStatus
			jsr	PutString

::exit			rts

;*** Fortschrittsanzeige initialisieren.
:initProcData		lda	lenDataSize +0		;Datei < 16Mb?
			beq	:1			; => Ja, weiter...

			lda	#$ff			;Größe auf 16Mb begrenzen.
			sta	r10L			;Die Download-Anzeige invertiert
			sta	r10H			;sich dann nach jeweils 16Mb.
			bne	:2

::1			lda	lenDataSize +2		;Anzahl Blocks einlesen.
			sta	r10L
			lda	lenDataSize +1
			sta	r10H

::2			lda	#< 10			;10er-Teilung Fortschrittsanzeige.
			sta	r11L
			lda	#> 10
			sta	r11H

			ldx	#r10L			;Anzahl Blocks durch 10 teilen.
			ldy	#r11L
			jsr	Ddiv

			lda	r10L			;Anzahl Blocks je 10% als
			sta	procCounter +0		;Zähler speichern.
			sta	a9L
			lda	r10H
			sta	procCounter +1
			sta	a9H

			lda	#0			;Zeiger auf Anfang = 0%.
			sta	procStatus

			rts

;*** Fortschrittsanzeige aktualisieren.
;HINWEIS:
;Routine darf X/Y-Reg nicht verändern!
:updProcData		lda	a9L			;Zähler für Fortschrittsanzeige
			bne	:1			;reduzieren.
			dec	a9H
			bmi	:2			; => Zähler abgelaufen, weiter...
::1			dec	a9L
			rts

::2			lda	#$00			;Neuen Fortschritt anzeigen.
			b $2c
:doProcData		lda	#$ff			;Fortschritt 100% anzeigen.
			sta	r2H

			tya				;Y-Reg zwischenspeichern.
			pha

			lda	#< SCREEN_BASE +(INFO_Y/8)*40*8 +(INFO_X/8)*8
			sta	r0L
			lda	#> SCREEN_BASE +(INFO_Y/8)*40*8 +(INFO_X/8)*8
			sta	r0H			;Position in Grafik-RAM berechnen.

			lda	#8			;8 Bytes schreiben.
			ldy	procStatus		;Aktuellen Status einlesen.

			bit	r2H			;Fortschrittsanzeige aktualisieren?
			bpl	:1			; => Ja, weiter...

			lda	#8*10			;Fortschrittsanzeige auf
			ldy	#0			;100% setzen.

::1			sta	r2L			;Byte-Zähler speichern.

::2			bit	r2H			;Fortschrittsanzeige aktualisieren?
			bmi	:3			; => Nein, weiter...

			lda	(r0L),y			;Byte aus Grafik-RAM einlesen und
			eor	#%11111111		;invertieren.
			b $2c
::3			lda	#%11111111		;Bei 100% alle Bits setzen.
			sta	(r0L),y			;Grafik-Daten in RAM speichern.
			iny
			dec	r2L			;Alle Bytes bearbeitet?
			bne	:2			; => Nein, weiter...

			cpy	#8*10			;Überlauf bei 16Mb?
			bcc	:4			; => Nein, weiter...
			ldy	#0			;Fortschrittsanzeige zurücksetzen.
::4			sty	procStatus		;Neuen Status speichern.

			lda	procCounter +0		;Zähler neu initialisieren.
			sta	a9L
			lda	procCounter +1
			sta	a9H

			pla
			tay				;Y-Reg wieder zurücksetzen.

::exit			rts

if DEMO_MODE = DEMO_FALSE
;*** Befehlskanal öffnen.
:openDevChan		bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	; => 1MHz aktivieren.

::1			lda	#$00			;Status löschen.
			sta	STATUS

;			lda	#$00
			tax
			tay
			jsr	SETNAM			;Kein Dateiname.
			lda	#15			;open 15,dv,15
			ldx	curDevice
;			ldy	#15
			tay
			jsr	SETLFS			;Daten für Befehlskanal.
			jsr	OPENCHN			;Befehlskanal #12 öffnen.

			ldx	STATUS			;Fehler?
			rts

;*** Datenkanal öffnen.
:openDataChan		lda	#:com_Buf0_len		;open x,y,z,"#"
			ldx	#< :com_Buf0
			ldy	#> :com_Buf0
			jsr	SETNAM			;Datenkanal, Name "#".
			lda	#5			;open 5,dv,5
			ldx	curDevice
;			ldy	#5
			tay
			jsr	SETLFS			;Daten für Datenkanal.
			jsr	OPENCHN			;Datenkanal öffnen.

			ldx	STATUS			;Fehler?
			rts

::com_Buf0		b "#0"
::com_Buf0_end
::com_Buf0_len		= (:com_Buf0_end - :com_Buf0)

:openFileChan		ldx	#0
			ldy	#2
::1			lda	altFileName,x
			beq	:2
			sta	:com_FName,y
			iny
			inx
			cpx	#lenNameFile
			bne	:1

::2			tya
			ldx	#< :com_FName
			ldy	#> :com_FName
			jsr	SETNAM			;Datenkanal, Name "#".
			lda	#5			;open 5,dv,1
			ldx	curDevice
			ldy	#1
			jsr	SETLFS			;Daten für Datenkanal.
			jsr	OPENCHN			;Datenkanal öffnen.

			ldx	STATUS			;Fehler?
			rts

::com_FName		b $40,":"
			e (:com_FName +2 +16 +1)

;*** Datenkanal schließen.
:closeDataChan		lda	#5
			jmp	CLOSE

;*** Befehlskanal schließen.
:closeDevChan		lda	#15			;Befehlskanal schließen.
			jsr	CLOSE

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo zurücksetzen.

::1			rts

;*** Verzeichnis-Eintrag erzeugen.
:createDirEntry		lda	#$00
			sta	r10L
			jsr	GetFreeDirBlk		;Freien Verzeichniseintrag suchen.
			txa				;Diskfehler?
			beq	:ok			; => Nein, weiter...
			rts

::ok			lda	#PRG ! %10000000	;CBM-Dateityp definieren.
			sta	diskBlkBuf,y
			iny

			lda	curFile1stTr		;Zeiger auf ersten Track/Sektor
			sta	diskBlkBuf,y		;festlegen.
			iny
			lda	curFile1stSe
			sta	diskBlkBuf,y
			iny

			ldx	#0			;Dateiname ünerbehmen.
::3			lda	altFileName,x
			beq	:4
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#lenNameFile
			bcc	:3
			bcs	:6

::4			lda	#$a0			;Rest des Dateinamen mit
::5			sta	diskBlkBuf,y		;SHIFT-SPACE auffüllen.
			iny
			inx
			cpx	#lenNameFile
			bcc	:5

::6			lda	#NULL			;Reserviert/GEOS-Daten löschen.
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny

			lda	year			;Datum speichern.
			sta	diskBlkBuf,y
			iny
			lda	month
			sta	diskBlkBuf,y
			iny
			lda	day
			sta	diskBlkBuf,y
			iny

			lda	hour			;Uhrzeit speichern.
			sta	diskBlkBuf,y
			iny
			lda	minutes
			sta	diskBlkBuf,y
			iny

			lda	maxFileSize +0		;Dateigröße speichern.
			sta	diskBlkBuf,y
			iny
			lda	maxFileSize +1
			sta	diskBlkBuf,y

			jsr	PutBlock		;Verzeichnis-Eintrag speichern.
;			txa				;Diskfehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR
			rts
endif

if DEMO_MODE = DEMO_FALSE
;*** Floppy-Befehl mit variabler Länge an Laufwerk senden.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:SendComVLen		sta	r0L
			stx	r0H
			sty	r2L

			ldx	#15			;Ausgabekanal festlegen.
			jsr	CKOUT

			ldy	#$00
::51			lda	(r0L),y			;Bytes an Floppy-Laufwerk senden.
			jsr	CIOUT
			iny
::52			cpy	r2L
			bne	:51

			jsr	CLRCHN			;Standard-I/O aktivieren.

::53			ldx	STATUS
			rts

;*** Diskettenstatus einlesen.
:getDiskError		ldx	#15			;Eingabekanal setzen.
			jsr	CHKIN

			ldy	#0
::1			jsr	ACPTR			;1.Zeichen aus Status einlesen.
			cpy	#63			;Speicher voll?
			bcs	:2			; => Ja, Zeichen ignorieren.
			sta	dskErrData,y		;Zeichen für Fehlerstatus speichern.
::2			iny
			lda	STATUS			;Ende erreicht?
			beq	:1			; => Nein, nächstes Zeichen...

			lda	#NULL			;Ende Lafwerks-Status markieren.
			sta	dskErrData,y

;			jsr	CLRCHN			;Standard-I/O aktivieren.

			lda	dskErrData +0		;High-Nibble nach HEX wandeln.
			sec
			sbc	#$30
			asl
			asl
			asl
			asl
			sta	dskErrCode

			lda	dskErrData +1		;Low-Nibble nach HEX wandeln.
			sec
			sbc	#$30
			ora	dskErrCode
			sta	dskErrCode		;Fehler als HEX-Wert erzeugen.

			tax
			rts

;*** Aktuelles Laufwerk auf SD2IEC testen.
;    Übergabe: curDrive = Aktuelles Laufwerk.
;    Rückgabe: XREG = $00, DiskImage.
;                   = $FF, Verzeichnis.
:getSD2IECmode		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:mode_dimg		; => Nein, kein SD2IEC.

			jsr	getDISKmode
			txa
			beq	:mode_dimg		;`00,` => Ja, DiskImage-Modus.
			cmp	#$70
			bne	:mode_dir		;`70,` => Ja, Keine SD-Karte.

::err			ldx	#DEV_NOT_FOUND		;SD2IEC: Keine Karte im Laufwerk.
			b $2c
::mode_dir		ldx	#$ff			;SD2IEC: Verzeichnis.
			b $2c
::mode_dimg		ldx	#$00			;SD2IEC: DiskImage.
			rts

:getDISKmode		jsr	openDataChan		;Datenkanal öffnen.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			lda	#< :com_U1_read
			ldx	#> :com_U1_read
			ldy	#:com_U1_len
			jsr	SendComVLen		;Buffer-Pointer setzen.

			jsr	getDiskError		;Laufwerks-Status einlesen.

			jsr	CLRCHN			;Standard-I/O aktivieren.

			jsr	closeDataChan		;Datenkanal schließen.

			ldx	dskErrCode		;Fehler-Status einlesen.
::err			rts

::com_U1_read		b "U1 5 0 1 1"
::com_U1_end
::com_U1_len		= (:com_U1_end - :com_U1_read)

;*** SD2IEC: Disk-Image verlassen.
:exitDiskImage		lda	#< :com_CDirUp
			ldx	#> :com_CDirUp
			ldy	#:com_CDirUp_len
			jmp	SendComVLen

::com_CDirUp		b "CD",$5f
::com_CDirUp_end
::com_CDirUp_len	= (:com_CDirUp_end - :com_CDirUp)
endif

if DEMO_MODE = DEMO_FALSE
;*** Neues DiskImage öffnen.
:openDiskImage		lda	curType			;Kann DiskImage gemounted werden?
			and	#ST_DMODES
			cmp	dloadFType
			bne	:err			; => Nein, Abbruch...

			ldx	#0
			ldy	#3
::1			lda	altFileName,x		;Name DiskImage in Verzeichnis-
			beq	:2			;Befehl übertragen.
			sta	:com_CDir,y
			iny
			inx
			cpx	#lenNameFile
			bne	:1

::2			lda	#< :com_CDir
			ldx	#> :com_CDir
;			ldy	#:com_CDir_len
			jsr	SendComVLen		;DiskImage öffnen.

::err			jsr	getDiskError		;Laufwerks-Status einlesen.

			rts

::com_CDir		b "CD:"
			e (:com_CDir  +3 +16 +1)
endif

;*** Auf SWAPLIST.LST testen.
:openSwapList		ldx	curDrive
if DEMO_MODE = DEMO_FALSE
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:exit			; => Nein, kein SD2IEC.
endif
if DEMO_MODE = DEMO_TRUE
			lda	driveType -8,x		;Laufwerksmodus einlesen.
			bmi	:exit			; => Nein, kein SD2IEC.
endif

			ldy	#0
::1			lda	altFileName,y
			beq	:3
			cmp	swapListName,y
			beq	:2
			eor	#%00100000
			cmp	swapListName,y
			bne	:exit
::2			iny				;übertragen.
			cpy	#lenNameFile		;Alle Zeichen überprüft?
			bne	:1			; => Nein, weiter...

::3			LoadW	r0,Dlg_SwapList
			jsr	DoDlgBox

			ldx	#CANCEL_ERR
			lda	sysDBData
			cmp	#YES			;SwapList öffnen?
			beq	:4			; => Nein, Ende...

::exit			rts

::4			LoadW	r0,altFileName

;*** Beliebige SwapList öffnen.
:openCustomList		ldy	#0
::1			lda	(r0L),y
			beq	:2
			sta	:com_SWAP +3,y		;Name SwapList in `XS`-Befehl
			iny				;übertragen.
			cpy	#16			;Alle Zeichen überprüft?
			bcc	:1			; => Nein, weiter...

::2			tya
			clc
			adc	#3
			sta	:com_SWAP_len		;Länge Dateiname speichern.

if DEMO_MODE = DEMO_FALSE
			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	openDevChan		;Befehlskanal öffnen.

			lda	#< :com_SWAP
			ldx	#> :com_SWAP
			ldy	:com_SWAP_len
			jsr	SendComVLen		;SwapList öffnen.

::err			jsr	getDiskError		;Laufwerks-Status einlesen.
			txa				;Fehler-Status zwischenspeichern.
			pha

			jsr	closeDevChan		;Befehlskanal schließen.

			jsr	DoneWithIO		;I/O-Bereich abschalten.

			pla				;Laufwerksfehler?
			beq	:3			; => Nein, weiter...

			pha
			jsr	doErrorGEOS		;Fehler ausgeben.
			pla

::3			tax
endif
if DEMO_MODE = DEMO_TRUE
			ldx	#NO_ERROR
endif

::exit			rts

::com_SWAP		b "XS:"
			e (:com_SWAP  +3 +16 +1)
::com_SWAP_len		b $00

if DEMO_MODE = DEMO_FALSE
;*** Block über Kernal auf Disk schreiben.
:WriteDiskBlock		ldx	#5			;Ausgabekanal festlegen.
			jsr	CKOUT

			ldx	STATUS			;Fehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#0			;Daten an Laufwerk senden.
::1			lda	diskBlkBuf,y
			jsr	CIOUT
			iny
			bne	:1

			ldx	STATUS			;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	r1L
			jsr	DEZ2ASCII		;Track nach ASCII wandeln.
			sty	:com_U2_tr +0
			stx	:com_U2_tr +1
			sta	:com_U2_tr +2

			lda	r1H
			jsr	DEZ2ASCII		;Sektor nach ASCII wandeln.
			sty	:com_U2_se +0
			stx	:com_U2_se +1
			sta	:com_U2_se +2

			lda	#< :com_U2_write
			ldx	#> :com_U2_write
			ldy	#:com_U2_len		;Block auf Disk schreiben mit
			jsr	SendComVLen		;Befehl: "U2 5 0 xxx yyy"

::err			rts

::com_U2_write		b "U2 5 0 "
::com_U2_tr		b "001 "
::com_U2_se		b "001"
::com_U2_end
::com_U2_len		= (:com_U2_end - :com_U2_write)

;*** Block über GEOS-Routinen auf Disk schreiben.
;Übergabe: YReg = Zeiger auf letztes Byte/Letzter Sektor.
;          r4   = Zeiger auf diskBlkBuf.
;          flagEOF = $00/Dateiende.
:addData2File		lda	flagEOF			;Dateiende erreicht?
			bne	:1			; => Nein, weiter...

			sta	diskBlkBuf +0		;Kennung für Datei-Ende.
			sty	diskBlkBuf +1		;Zeiger auf letztes Byte in Sektor.
			beq	:2			; => Letzten Sektor speichern.

::1			lda	r1L			;Aktuellen Sektor als Startwert
			sta	r3L			;für Suche nach nächstem freien
			lda	r1H			;Sektor setzen.
			sta	r3H

;			jsr	DoneWithIO		;I/O-Bereich abschalten.
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
;			txa				;Fehlerstatus zwischenspeichern.
;			pha
;			jsr	InitForIO		;I/O-Bereich aktivieren.
;			pla
;			tax
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			lda	r3L			;Freien Sektor als Folgesektor in
			sta	diskBlkBuf +0		;Dsatenblock schreiben.
			lda	r3H
			sta	diskBlkBuf +1

::2			jsr	WriteBlock		;Datenblock auf Disk speichern.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			inc	maxFileSize +0		;Anzahl Blocks +1.
			bne	:3
			inc	maxFileSize +1

::3			lda	diskBlkBuf +0		;Folgesektor als aktuellen
			sta	r1L			;Sektor setzen.
			lda	diskBlkBuf +1
			sta	r1H

::err			rts
endif

;*** Download-Größe überprüfen.
:testImageSize		lda	curType
			and	#ST_DMODES
			asl
			asl
			tax

if DEMO_MODE = DEMO_TRUE
			lda	dloadSizeTab +0,x	;Im Demo-Modus Testgröße
			sta	lenDataSize +0		;definieren.
			lda	dloadSizeTab +1,x
			sta	lenDataSize +1
			lda	dloadSizeTab +2,x
			sta	lenDataSize +2
			lda	dloadSizeTab +3,x
			sta	lenDataSize +3
endif
if DEMO_MODE = DEMO_FALSE
			lda	lenDataSize +0		;Dateigröße prüfen.
			cmp	dloadSizeTab +0,x
			bne	:1
			lda	lenDataSize +1
			cmp	dloadSizeTab +1,x
			bne	:1
			lda	lenDataSize +2
			cmp	dloadSizeTab +2,x
			bne	:1
			lda	lenDataSize +3
			cmp	dloadSizeTab +3,x
::1			bne	:err			; => Falsche Größe, Fehler...
endif

::ok			ldx	#NO_ERROR
			b $2c
::err			ldx	#INCOMPATIBLE
			rts

;*** Zeiger auf nächsten Sektor.
:GetNextSekAdr		lda	curType			;Laufwerksmodus einlesen.
			bne	:1			; => Gültig, weiter...
::err			ldx	#INV_TRACK		;Laufwerksmodus ungültig.
			rts

::1			and	#ST_DMODES		;Laufwerksmodus isolieren.
			cmp	#Drv1541		;Typ 1541?
			beq	:1541			; => Ja, weiter...
			cmp	#Drv1571		;Typ 1571?
			beq	:1571			; => Ja, weiter...
			cmp	#Drv1581		;Typ 1581?
			beq	:1581			; => Ja, weiter...
			cmp	#DrvNative		;Typ Native?
			beq	:Native			; => Ja, weiter...
			bne	:err			;Ungültig, Abbruch...

;--- 1541: Zeiger auf nächsten Sektor.
::1541			inc	r1H			;Sektor +1.

			ldx	r1L
			lda	r1H
			cmp	maxSectorTab -1,x	;Letzter Sektor überschritten?
			bcc	:ok			; => Nein, weiter...

			ldx	#35			;Max. Anzahl Tracks.
			bne	:nextTrack		;Auf letzten Track testen.

;--- 1571: Zeiger auf nächsten Sektor.
::1571			ldy	curDrive		;1571/Doppelseitig?
			lda	doubleSideFlg -8,y
			bpl	:1541			; => Nein, 1571/Einseitig.

			inc	r1H			;Sektor +1.

			ldx	r1L
			lda	r1H
			cmp	maxSectorTab -1,x
			bcc	:ok

			ldx	#70			;Max. Anzahl Tracks.
			bne	:nextTrack		;Auf letzten Track testen.

;--- 1581: Zeiger auf nächsten Sektor.
::1581			inc	r1H			;Sektor +1.

			ldx	r1L
			lda	r1H
			cmp	#40
			bcc	:ok

			ldx	#80			;Max. Anzahl Tracks.
			bne	:nextTrack		;Auf letzten Track testen.

;--- Native: Zeiger auf nächsten Sektor.
::Native		inc	r1H			;Sektor +1.
			bne	:ok			; => OK, weiter...

			ldx	lenDataSize +1
;			bne	:nextTrack

;--- Ende Track erreicht, Zeiger auf nächsten Track.
::nextTrack		inc	r1L			;Spur +1.
			beq	:exit			; => NativeMode: Ende erreicht.

			lda	#$00			;Zeiger auf ersten Sektor
			sta	r1H			;zurücksetzen.

			cpx	r1L			;Letzte Spur überschritten?
			bcs	:ok			; => Nein, weiter...

::exit			ldx	#BFR_OVERFLOW		;Ende erreicht.
			rts

::ok			ldx	#NO_ERROR		;Kein Fehler.
			rts

;******************************************************************************
;*** DiskImage auf RAMDisk schreiben.
;******************************************************************************

;*** RAMDisk öffnen.
:dlRamOpen		jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	; => 1MHz aktivieren.
endif

::1			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Initialisierung.
:dlRamInit		lda	#1			;Zeiger auf ersten Track/Sektor.
			sta	r1L
			lda	#0
			sta	r1H

;			lda	#< diskBlkBuf		;Zeiger auf Zwischenspeicher.
			sta	r4L
			lda	#> diskBlkBuf
			sta	r4H

			jmp	testImageSize		;Doanload-Größe testen.

;*** Block auf RAMDisk schreiben.
;Übergabe: a0-a1 = Anzahl Blocks.
;          r4    = Zeiger auf diskBlkBuf.
:dlRamWrite		jsr	decByteCount3		;Anzahl Blocks -1.

::loop			ldy	#0
::read			jsr	readWiC64byte		;Byte vom WiC64 einlesen.
			cpx	#NO_ERROR		;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:write			; => Nein, weiter...
			sta	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::write			sta	diskBlkBuf,y		;Byte in Zwischenspeicher schreiben.

::next			iny				;256 Bytes empfangen?
			bne	:read			; => Nein, weiter...

			jsr	updProcData		;Fortschrittsanzeige aktualisieren.

::complete		ldx	dloadStatus		;Fehler aufgetreten?
			bne	:skip			; => Ja, weiter...

			jsr	decByteCount3		;Anzahl Blocks -1.

if DEMO_MODE = DEMO_FALSE
;			LoadW	r4,diskBlkBuf
			jsr	WriteBlock		;Block auf Disk speichern.
			txa				;Diskfehler?
			bne	:err			; => Ja, weiter...
endif

			jsr	GetNextSekAdr		;Zeiger auf nächsten Sektor.
;			txa				;Ende erreicht?
;			bne	:err			; => Ja, weiter...

::err			stx	dloadStatus		;Fehler-Status speichern.

::skip			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:check			; => Nein, weiter...
			inc	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::check			lda	flagEOF			;Download beendet?
			bne	:loop			; => Nein, weiter...

::done			jsr	doProcData		;Fortschrittsanzeige aktualisieren.
			jsr	SCPU_Pause		;1/10sec. warten für 100%-Anzeige.

::exit			stx	dloadStatus		;Fehler-Status speichern.
			rts

;*** RAMDisk schließen.
:dlRamClose
if DEMO_MODE = DEMO_FALSE
			jsr	_WiC64_ReadMode		;WiC64 auf Empfang schalten.
			jsr	_WiC64_Init		;WiC64 initialisieren.

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo zurücksetzen.
endif

::1			jsr	DoneWithIO		;I/O-Bereich abschalten.

if DEMO_MODE = DEMO_FALSE
			ldx	dloadStatus		;Download erfolgreich?
			bne	:exit			; => Nein, Ende...

			lda	curType			;Laufwerksmodus einlesen.
			and	#ST_DMODES
			cmp	#Drv1581		;C=1581?
			beq	:2			; => Ja, weiter...
			cmp	#DrvNative		;CMD-Native?
			bne	:exit			; => Nein, Ende...

;--- Hinweis:
;Bei RAMDisk muss der Diskname bei 1581
;korrigiert werden, da der Laufwerks-
;treiber für die Kompatibilität den
;Disknamen bei Offset $90 eintauscht.
::2			jsr	NewDisk			;Neue Diskette aktivieren.
			txa				;Diskfehler ?
			bne	:err			; => Ja, Abbruch...
			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskfehler ?
			bne	:err			; => Ja, Abbruch...

			ldy	#$00 +4			;Diskname an die richtige
			ldx	#$90			;Stelle verschieben.
::3			lda	curDirHead,y
			pha
			lda	curDirHead,x
			sta	curDirHead,y
			pla
			sta	curDirHead,x
			inx
			iny
			cpy	#$19 +4
			bcc	:3

			jsr	PutDirHead		;BAM speichern.
			jsr	OpenDisk		;Disk öffnen/Diskname einlesen.
;			txa				;Diskfehler ?
;			bne	:err			; => Ja, Abbruch...

::err			stx	dloadStatus		;Download-Status speichern.
endif

::exit			rts				;Ende.

;******************************************************************************
;*** DiskImage auf Disk schreiben.
;******************************************************************************

;*** Laufwerkskanäle öffnen.
:dlDskOpen		jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			lda	curType
			cmp	#Drv1581		;Laufwerk vom Typ 1581?
			bne	:1			; => Nein, weiter...

			lda	curDirHead +2		;Disk-Format einlesen.
			cmp	#"D"			;Format = "D" ?
			beq	:1			; => Ja, weiter...

			ldx	#DOS_MISMATCH		;Soft-WriteProtect aktiv!
			bne	:err			; => Abbruch...

::1			jsr	openDevChan		;Befehlskanal öffnen.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			lda	#< :com_SetPoi
			ldx	#> :com_SetPoi
			ldy	#:com_SetPoi_len
			jsr	SendComVLen		;Buffer-Pointer setzen.

;			ldx	STATUS			;Fehler?
endif
if DEMO_MODE = DEMO_TRUE
			ldx	#NO_ERROR
endif

::err			rts

::com_SetPoi		b "B-P 5 0"
::com_SetPoi_end
::com_SetPoi_len	= (:com_SetPoi_end - :com_SetPoi)

;*** Initialisierung.
:dlDskInit		= dlRamInit

;*** Block auf Disk schreiben.
;Übergabe: a0-a1 = Anzahl Blocks.
;          r4    = Zeiger auf diskBlkBuf.
:dlDskWrite		jsr	decByteCount3		;Anzahl Blocks -1.

::loop			ldy	#0
			sty	r5L
::read			jsr	readWiC64byte		;Byte vom WiC64 einlesen.
			cpx	#NO_ERROR		;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:write			; => Nein, weiter...
			sta	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::write			sta	diskBlkBuf,y		;Byte in Zwischenspeicher schreiben.

			bit	flagWrEmpty		;Leere Sektoren schreiben?
			bmi	:next			; => Ja, weiter...
			ora	r5L			;Daten-Bits addieren.
			sta	r5L

::next			iny				;256 Bytes empfangen?
			bne	:read

			jsr	updProcData		;Fortschrittsanzeige aktualisieren.

::complete		ldx	dloadStatus		;High-Byte +1.
			bne	:skip

			jsr	decByteCount3		;Anzahl Blocks -1.

if DEMO_MODE = DEMO_FALSE
			bit	flagWrEmpty		;Leere Sektoren schreiben?
			bmi	:1			; => Ja, weiter...
			lda	r5L			;Sektor enthält Daten?
			beq	:3			; => Nein, weiter...

::1			jsr	WriteDiskBlock		;Sektor auf Disk speichern.
			txa				;Diskfehler?
			bne	:err			; => Ja, weiter...
endif

::3			jsr	GetNextSekAdr		;Zeiger auf nächsten Sektor.
;			txa				;Ende erreicht?
;			bne	:err			; => Ja, weiter...

::err			stx	dloadStatus		;Fehler-Status speichern.

::skip			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:check			; => Nein, weiter...
			inc	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::check			lda	flagEOF			;Download beendet?
			bne	:loop			; => Nein, weiter...

::done			jsr	doProcData		;Fortschrittsanzeige aktualisieren.
;			jsr	SCPU_Pause		;1/10sec. warten für 100%-Anzeige.

if DEMO_MODE = DEMO_FALSE
			txa
			pha
			jsr	getDiskError		;Laufwerks-Status einlesen.
			pla
			tax
endif

::exit			stx	dloadStatus		;Fehler-Status speichern.

if DEMO_MODE = DEMO_FALSE
			jsr	CLRCHN			;Standard-I/O aktivieren.
endif

			rts

;*** RAMDisk schließen.
:dlDskClose
if DEMO_MODE = FALSE
			jsr	closeDataChan		;Datenkanal schließen.

			jsr	closeDevChan		;Befehlskanal schließen.

			jsr	_WiC64_ReadMode		;WiC64 auf Empfang schalten.
			jsr	_WiC64_Init		;WiC64 initialisieren.
endif
			jmp	DoneWithIO		;I/O-Bereich abschalten.

;******************************************************************************
;*** DiskImage auf SD2IEC schreiben.
;******************************************************************************

;*** SD2IEC/DiskImage öffnen.
:dlImgOpen		jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			jsr	openDevChan		;Befehlskanal öffnen.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	getSD2IECmode		;SD2IEC-Modus ermitteln.
			txa				;DiskImage aktiv?
			bmi	:1			; => Ja, weiter...
			bne	:err			; => Fehler, keine SD-Karte.

			jsr	exitDiskImage		;Aktuelles DiskImage verlassen.

::1			jsr	openFileChan		;Datei öffnen.
			txa				;Diskfehler?
			beq	:exit			; => Nein, Ende...

::err			ldx	#ERR_INIT_DLOAD		;Dateifehler.
endif
if DEMO_MODE = DEMO_TRUE
			ldx	#NO_ERROR		;Kein Fehler.
endif

::exit			rts

;*** Initialisierung.
:dlImgInit		ldx	#NO_ERROR
			rts

;*** Block in DiskImage schreiben.
;Übergabe: a0-a1 = Anzahl Blocks.
:dlImgWrite		jsr	decByteCount3		;Anzahl Blocks -1.

if DEMO_MODE = DEMO_FALSE
			ldx	#5			;Ausgabekanal festlegen.
			jsr	CKOUT
endif

::loop			ldy	#0
::read			jsr	readWiC64byte		;Byte vom WiC64 einlesen.
			cpx	#NO_ERROR		;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:write			; => Nein, weiter...
			sta	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::write			ldx	dloadStatus		;Fehler aufgetreten?
			bne	:next			; => Ja, weiter...

if DEMO_MODE = DEMO_FALSE
			jsr	CIOUT			;Byte in Datei speichern.
endif

::next			iny				;256 Bytes empfangen?
			bne	:read			; => Nein, weiter...

			lda	STATUS
			sta	dloadStatus		;Fehler-Status speichern.

			jsr	updProcData		;Fortschrittsanzeige aktualisieren.

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:check			; => Nein, weiter...
			inc	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::check			jsr	decByteCount3		;Anzahl Blocks -1.
			txa				;Alle Blocks geschrieben?
			bne	:loop			; => Nein, weiter...

::done			jsr	doProcData		;Fortschrittsanzeige aktualisieren.
;			jsr	SCPU_Pause		;1/10sec. warten für 100%-Anzeige.

if DEMO_MODE = DEMO_FALSE
			ldx	dloadStatus		;Fehler aufgetreten?
			bne	:err			; => Ja, weiter...
			jsr	getDiskError		;Laufwerks-Status einlesen.
;			txa				;Diskfehler?
;			bne	:err			; => Ja, Abbruch...
endif

::exit			stx	dloadStatus		;Fehler-Status speichern.

::err
if DEMO_MODE = DEMO_FALSE
			jsr	CLRCHN			;Standard-I/O aktivieren.
endif

			rts

;*** DiskImage schließen.
:dlImgClose
if DEMO_MODE = DEMO_FALSE
			jsr	closeDataChan		;Datenkanal schließen.

			ldx	dloadStatus		;Download erforlgreich?
			bne	:exit			; => Nein, weiter...

			jsr	openDiskImage		;DiskImage öffnen.

::exit			jsr	closeDevChan		;Befehlskanal schließen.

			jsr	_WiC64_ReadMode		;WiC64 auf Empfang schalten.
			jsr	_WiC64_Init		;WiC64 initialisieren.
endif

			jmp	DoneWithIO		;I/O-Bereich abschalten.

;******************************************************************************
;*** Datei auf RAM-Disk speichern.
;******************************************************************************

;*** Datei auf RAMDisk öffnen.
:dlRDatOpen		LoadW	r0,altFileName
			jsr	DeleteFile		;Vorhandene Datei löschen.
			txa				;Diskfehler?
			beq	:1			; => Nein, weiter...
			cpx	#FILE_NOT_FOUND		;Fehler "Datei nicht gefunden"?
			bne	:1			; => Nein, weiter...
			ldx	#NO_ERROR		;Kein Fehler.
::1			stx	dloadStatus		;Fehler-Status speichern.

			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			ldx	dloadStatus		;Fehler aufgetreten?
			bne	:err			; => Ja, Abbruch...

if DEMO_MODE = DEMO_FALSE
			lda	#1			;Zeiger auf ersten Track.
			sta	r3L

			lda	curType			;Zeiger auf ersten Sektor.
			and	#ST_DMODES
			cmp	#DrvNative
			bne	:2
			lda	#64			;Native: Reservierte Sektoren.
			b $2c
::2			lda	#0
			sta	r3H
			jsr	SetNextFree		;Ersten freien Sektor suchen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			lda	r3L			;Ersten Datensektor speichern.
			sta	curFile1stTr
			sta	curFileTr
			lda	r3H
			sta	curFile1stSe
			sta	curFileSe

			bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:3			; => Nein, weiter...
			jsr	_WiC64_TURBO_OFF	; => 1MHz aktivieren.
endif
if DEMO_MODE = DEMO_TRUE
			lda	#0			;Demo-Modus: Dateigröße setzen.
			sta	lenDataSize +0
			lda	#0
			sta	lenDataSize +1
			lda	#> 60000
			sta	lenDataSize +2
			lda	#< 60000
			sta	lenDataSize +3
endif

::3			ldx	#NO_ERROR		;Kein Fehler.
::err			rts

;*** Initialisierung.
:dlRDatInit		lda	curFileTr		;Zeiger auf ersten Sektor.
			sta	r1L
			lda	curFileSe
			sta	r1H

			ldx	#< diskBlkBuf		;Zeiger auf Zwischenspeicher.
			stx	r4L
			lda	#> diskBlkBuf
			sta	r4H

;			ldx	#$00			;Dateigröße zurücksetzen.
			stx	maxFileSize +0
			stx	maxFileSize +1

;			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Datei auf RAMDisk speichern.
;Übergabe: a0-a1 = Anzahl Bytes.
;          r1    = Aktueller Track/Sektor.
;          r4    = Zeiger auf diskBlkBuf.
:dlRDatWrite		jsr	decByteCount4		;Anzahl Bytes -1.

::loop			ldy	#2
::read			jsr	readWiC64byte		;Byte vom WiC64 einlesen.
			cpx	#NO_ERROR		;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:write			; => Nein, weiter...
			sta	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::write			sta	diskBlkBuf,y		;Byte in Zwischenspeicher schreiben.

::next			jsr	decByteCount4		;Anzahl Bytes -1.
			txa				;Alle Bytes gespeichert?
			beq	:complete		; => Ja, Ende...

			iny				;256 Bytes empfangen?
			bne	:read

			jsr	updProcData		;Fortschrittsanzeige aktualisieren.

::complete		ldx	dloadStatus		;Fehler aufgetreten?
			bne	:skip			; => Ja, Weiter...

if DEMO_MODE = DEMO_FALSE
;			LoadW	r4,diskBlkBuf
			jsr	addData2File		;Block in DiskImage speichern.
;			txa				;Diskfehler?
;			bne	:err			; => Ja, weiter...
;
;::err			stx	dloadStatus		;Fehler-Status speichern.
endif

::skip			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:check			; => Nein, weiter...
			inc	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::check			lda	flagEOF			;Download beendet?
			bne	:loop			; => Nein, weiter...

			jsr	doProcData		;Fortschrittsanzeige aktualisieren.
			jsr	SCPU_Pause		;1/10sec. warten für 100%-Anzeige.

::exit			stx	dloadStatus		;Fehler-Status speichern.
			rts

;*** Datei schließen.
:dlRDatClose		bit	flagTurboMode		;CPU-Turbo aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	_WiC64_TURBO_ON		;CPU-Turbo zurücksetzen.

::1			jsr	DoneWithIO		;I/O-Bereich abschalten.

			ldx	dloadStatus		;Download erfolgreich?
			bne	:exit			; => Nein, Abbruch...

if DEMO_MODE = DEMO_FALSE
			jsr	createDirEntry		;Verzeichniseintrag erstellen.
			txa				;Diskfehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
endif

::exit			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			jsr	_WiC64_ReadMode		;WiC64 auf Empfang schalten.
			jsr	_WiC64_Init		;WiC64 initialisieren.
endif

			jmp	DoneWithIO		;I/O-Bereich abschalten.

;******************************************************************************
;*** Datei auf Disk/SD2IEC speichern.
;******************************************************************************

;*** Datei auf Disk öffnen.
:dlDDatOpen		jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if DEMO_MODE = DEMO_FALSE
			jsr	openDevChan		;Befehlskanal öffnen.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			lda	dloadMode		;Download als Datei in
			cmp	#5			;SD2IEC-Verzeichnis speichern?
			beq	:dir			; => Ja, weiter...

::dimg			jsr	getDISKmode		;Diskette im Laufwerk?
			txa
			bne	:err			; => Nein, Fehler...
			beq	:1			; => Ja, weiter...

::dir			jsr	getSD2IECmode		;SD2IEC-Modus ermitteln.
			txa				;DiskImage aktiv?
			bmi	:1			; => Ja, weiter...
			bne	:err			; => Fehler, keine SD-Karte.

			jsr	exitDiskImage		;Aktuelles DiskImage verlassen.

::1			jsr	openFileChan		;Datei öffnen.
			txa				;Diskfehler?
			beq	:exit			; => Nein, Ende...

::err			ldx	#ERR_INIT_DLOAD		;Dateifehler.
endif
if DEMO_MODE = DEMO_TRUE
			lda	#0			;Demo-Modus: Dateigröße setzen.
			sta	lenDataSize +0
			lda	#0
			sta	lenDataSize +1
			lda	#> 60000
			sta	lenDataSize +2
			lda	#< 60000
			sta	lenDataSize +3

			ldx	#NO_ERROR		;Kein Fehler.
endif

::exit			rts

;*** Initialisierung.
:dlDDatInit		= dlImgInit

;*** Download in Datei speichern.
;Übergabe: a0-a1 = Anzahl Bytes.
:dlDDatWrite		jsr	decByteCount4		;Anzahl Bytes -1.

if DEMO_MODE = DEMO_FALSE
			ldx	#5			;Ausgabekanal festlegen.
			jsr	CKOUT
endif

::loop			ldy	#0
::read			jsr	readWiC64byte		;Byte vom WiC64 einlesen.
			cpx	#NO_ERROR		;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:write			; => Nein, weiter...
			sta	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::write			ldx	dloadStatus		;Fehler aufgetreten?
			bne	:next			; => Ja, weiter...

if DEMO_MODE = DEMO_FALSE
			jsr	CIOUT			;Byte in Datei speichern.
endif

::next			jsr	decByteCount4		;Anzahl Blocks -1.
			txa				;Alle Bytes gespeichert?
			beq	:complete		; => Ja, Ende...

			iny				;256 Bytes empfangen?
			bne	:read			; => Nein, weiter...

			lda	STATUS
			sta	dloadStatus		;Fehler-Status speichern.

			jsr	updProcData		;Fortschrittsanzeige aktualisieren.

			bit	flagWiC64dbg		;Debug-Modus aktiv?
			bpl	:check			; => Nein, weiter...
			inc	extclr 			;Debug-Modus: Rahmenfarbe ändern.

::check			lda	flagEOF			;Download beendet?
			bne	:loop			; => Nein, weiter...

::complete		jsr	doProcData		;Fortschrittsanzeige aktualisieren.
;			jsr	SCPU_Pause		;1/10sec. warten für 100%-Anzeige.

if DEMO_MODE = DEMO_FALSE
			ldx	dloadStatus		;Fehler aufgetreten?
			bne	:err			; => Ja, weiter...
			jsr	getDiskError		;Laufwerks-Status einlesen.
;			txa				;Diskfehler?
;			bne	:err			; => Ja, Abbruch...
endif

::exit			stx	dloadStatus		;Fehler-Status speichern.

::err
if DEMO_MODE = DEMO_FALSE
			jsr	CLRCHN			;Standard-I/O aktivieren.
endif

			rts

;*** Datei schließen.
:dlDDatClose
if DEMO_MODE = DEMO_FALSE
			jsr	closeDataChan		;Datenkanal schließen.

			jsr	closeDevChan		;Befehlskanal schließen.

			jsr	_WiC64_ReadMode		;WiC64 auf Empfang schalten.
			jsr	_WiC64_Init		;WiC64 initialisieren.
endif

			jsr	DoneWithIO		;I/O-Bereich abschalten.

::exit			rts				;Ende.

;*** Angaben für Ziel-Laufwerk.
:drvTargetAdr		b $00     ;Ziel-Laufwerk: GEOS-Adresse.
:drvTargetType		b $00     ;Ziel-Laufwerk: Emulationsformat.
:drvTargetPart		b $00     ;Ziel-Laufwerk: CMD-Partition.
:drvTargetTxt		b "A:",NULL
:dskTargetTxt		s 21      ;Ziel-Laufwerk: Partition/Diskname.

;*** Alternativer Dateiname.
:altFileName		s lenNameFile +1
:altFileNameLen		b $00     ;Anzahl Zeichen im Dateinamen.
:altFileNameDot		b $00     ;Position `.` im Dateinamen.
:altFileNameFix		b $00     ;>0 = Dateinamen gekürzt.

;*** Vorgabetext für "Keine Diskette".
if LANG = LANG_DE
:errNoDisk		b "(Keine Diskette)",NULL
endif
if LANG = LANG_EN
:errNoDisk		b "(No disk)",NULL
endif

;*** Standard-URL.
:defaultName		b "http://unknown.d64",NULL

;*** SWAPLIST.LST
:swapListName		b "swaplist.lst",NULL
:swapLstNewNm		b $40,":"
:swapLstEditNm		b "swaplist.lst"
			e (swapLstEditNm +17)

;*** Daten für Laufwerksfehler.
:dskErrCode		b $00
if DEMO_MODE = DEMO_FALSE
:dskErrData		s 64
endif
if DEMO_MODE = DEMO_TRUE
:dskErrData		b "00, OK,00,00",NULL
endif

;*** GEOS-Daten für WriteBlock.
:curFile1stTr		b $00       ;Daten als GEOS-Datei speichern.
:curFile1stSe		b $00
:curFileTr		b $00       ;Aktueller Track/Sektor für GEOS-Datei.
:curFileSe		b $00
:maxFileSize		w $0000     ;Dateigröße für GEOS-Datei.

;*** Fortschrittsanzeige.
:procCounter		w $0000     ;Fortschittsanzeige: Zähler.
:procStatus		b $00       ;Fortschittsanzeige: %-Wert.

;*** Doanload-Angaben.
:dloadMode		b $00       ;Download-Methode.
:dloadStatus		b $00       ;Download-Status.
:dloadFType		b $00       ;Download_Dateityp. $FF = Kein DiskImage.
:dloadAuto		b $00       ;Download-Auto-Mode.
:dloadCount		b $00       ;Anzahl geladener Dateien.
:flagEOF		b $00       ;$FF = Dateiende erreicht.
:flagWrEmpty		b %10000000 ;Bit%7=1: $00-Byte-Blocks auf Disk schreiben.
:flagSwapList		b %00000000 ;Bit%7=1: SwapList erstellen.

;*** Routinen für Download-Methoden.
:dloadVecTab		w dlRamOpen ,dlRamInit ,dlRamWrite ,dlRamClose
			w dlDskOpen ,dlDskInit ,dlDskWrite ,dlDskClose
			w dlImgOpen ,dlImgInit ,dlImgWrite ,dlImgClose
			w dlRDatOpen,dlRDatInit,dlRDatWrite,dlRDatClose
			w dlDDatOpen,dlDDatInit,dlDDatWrite,dlDDatClose
			w dlDDatOpen,dlDDatInit,dlDDatWrite,dlDDatClose

;*** Texte für Download-Methoden.
:dloadNamTab		w :d1, :d2, :d3, :d4, :d5,:d6
::d1			b "Dxx/RAM",NULL
::d2			b "Dxx/Disk",NULL
::d3			b "Dxx/SD2IEC",NULL
::d4			b "Datei/RAM",NULL
::d5			b "Datei/Disk",NULL
::d6			b "Datei/SD2IEC",NULL

;*** Standard-Größe der DiskImages.
:dloadSizeTab		b $00,$00,$00,$00
			b $00,$02,$ab,$00
			b $00,$05,$56,$00
			b $00,$0c,$80,$00
:dloadSizeNM		b $00,$00,$00,$00 ;Native-Größe wird nachträglich definiert.
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00

;*** Anzahl Sektoren pro Spur, 1541/1571.
:maxSectorTab		b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11
::1571			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11

;*** Anzahl Tracks auf NativeMode.
:maxTrackNM		b $00

;*** Dummy-Daten für Link-Liste.
if DEMO_MODE = DEMO_TRUE
:dataLnkLst_DEMO	b "http://192.168.2.2:8080"
			b "/geowload64.d81"
			b NULL
			b "http://192.168.2.2:8080"
			b "/demodisk.d64"
			b NULL
			b "http://192.168.2.2:8080"
			b "/swaplist.lst"
			b NULL
:dataLnkLstEnd
endif

;*** Daten für TextManager.
:textManClass		b "Text Mgr",NULL
:textManFName		s 17
:textScrapType		b $00
:textScrapMode		b $00
:textScrapName		b "Text  Scrap",NULL

;*** Info-Block für TextManager.
:HdrB000		w textScrapName
:HdrB002		b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%01000000,%00000001
			b %10000000,%01100000,%00000001
			b %10000000,%01100000,%00000001
			b %10000000,%01100000,%00001101
			b %10000000,%01010000,%00110101
			b %10000000,%01010000,%11011001
			b %10000000,%01010011,%00100001
			b %10000000,%01011100,%11000001
			b %10000000,%01011001,%00000001
			b %10000111,%11001110,%00000001
			b %10011111,%11001000,%00000001
			b %10111000,%11111000,%00000001
			b %10110001,%11111100,%00000001
			b %10111111,%01101101,%00000001
			b %10011100,%01100110,%00000001
			b %10000000,%01100110,%00000001
			b %10000000,%01101100,%00000001
			b %10000000,%00111000,%00000001
			b %10000000,%00000000,%00000001
			b %11111111,%11111111,%11111111

:HdrB068		b $83				;USR.
:HdrB069		b SYSTEM			;GEOS-Systemdatei.
:HdrB070		b SEQUENTIAL			;GEOS-Dateityp VLIR.
:HdrB071		w BASE_SCRAP			;Programm-Anfang.
:HdrB073		w $ffff				;Programm-Ende.
:HdrB075		w $0000				;Programm-Start.
:HdrB077		b "Text  Scrap "		;Klasse
:HdrB089		b "V2.0"			;Version
:HdrB093		b NULL
:HdrB094		b $00,$00			;Reserviert
:HdrB096		b $00				;Bildschirmflag
:HdrB097		b NULL				;Autor
			e (HdrB097 +20)			;Reserviert
:HdrB117		b NULL
			e (HdrB117 +17)			;Reserviert
:HdrB134		e (HdrB134 +26)			;Reserviert.
:HdrB160		b NULL
:HdrEnd			s (HdrB000+256)-HdrEnd

;*** Download-Status.
:jobInfTxHead		b PLAINTEXT,BOLDON
			b "WiC64 DOWNLOAD"
			b PLAINTEXT,NULL

if LANG = LANG_DE
:infoTxDLoadImg		b "Datei wird geladen und gespeichert...",NULL
:infoTxDLoadLst		b "LinkListe wird geladen...",NULL
:infoTxDLoadNam		b "Datei: ",NULL
:infoTxStatus		b GOTOXY
			w STATUS_X +8
			b INFO_Y +6
			b "Fortschritt:"
			b GOTOX
			w INFO_X -15
			b "0%"
			b GOTOX
			w INFO_X +10*8 +2
			b "100%"
			b NULL
endif
if LANG = LANG_EN
:infoTxDLoadImg		b "File will be downloaded and saved...",NULL
:infoTxDLoadLst		b "Loading link list...",NULL
:infoTxDLoadNam		b "File: ",NULL
:infoTxStatus		b GOTOXY
			w STATUS_X +8
			b INFO_Y +6
			b "Proccess:"
			b GOTOX
			w INFO_X -15
			b "0%"
			b GOTOX
			w INFO_X +10*8 +2
			b "100%"
			b NULL
endif

;*** Dialogbox: Partition wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** TextManager nicht gefunden!
:Dlg_NoTextMan		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$24
			w :1
			b DBTXTSTR   ,$10,$30
			w textManClass

			b OK         ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "Programm nicht gefunden:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "Main program not found:"
			b PLAINTEXT,NULL
endif

;*** TextScrap nicht gefunden!
:Dlg_NoScrap		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$24
			w :1
			b DBTXTSTR   ,$08,$30
			w :2

			b OK         ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "Kann URL nicht einfügen:",NULL
::2			b PLAINTEXT
			b "Kein TextScrap auf Laufwerk "
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "Cannot paste URL:",NULL
::2			b PLAINTEXT
			b "TextScrap not found on drive "
endif
:textScrapDrv		b "A:",NULL

;*** Dialogbox: Status SD2IEC/Download-Modus.
:Dlg_DAutoMode		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO

			b DBTXTSTR   ,$08,$20
			w :1
			b DBVARSTR   ,$08,$2c
			b r10L

			b OK         ,$01,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "Auto-Download für Link-Liste:"
			b PLAINTEXT,NULL
:dboxDAuto01		b "SD2IEC/Mehrfach-Download aktiv!"
			b GOTOXY
			w $0048
			b $5c
			b "(Download beginnt mit aktueller Datei)",NULL
:dboxDAuto02		b "SD2IEC/Einzel-Download aktiv!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "Auto download using link list:"
			b PLAINTEXT,NULL
:dboxDAuto01		b "SD2IEC/Multiple download mode!"
			b GOTOXY
			w $0048
			b $5c
			b "(Download will begin with current file)",NULL
:dboxDAuto02		b "SD2IEC/Single download mode!",NULL
endif

;*** Dialogbox: Download-Informationen.
:Dlg_DLoadInfo		b %01100001
			b $20,$9f
			w $0040,$00ff			;Wird durch :InitDBoxData angepasst.

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO
			b DBTXTSTR   ,$08,$1a
			w dboxTxt01

;			b DBTXTSTR   ,$08,$26		;Download-Adresse.
;			w dboxTxt02
			b DBTXTSTR   ,$08,$26
			w dboxTxtServer
;			b DBTXTSTR   ,$08,$30		;Download-Datei.
;			w dboxTxt03
			b DBTXTSTR   ,$08,$30
			w dboxTxtDImg

			b DBTXTSTR   ,$9c,$30		;Dateiformat.
			w dboxTxt07
			b DBTXTSTR   ,$a8,$30
			w dboxDImgType

			b DBTXTSTR   ,$08,$40		;Ziel-Laufwerk.
			w dboxTxt04
			b DBTXTSTR   ,$08,$4a
			w drvTargetTxt
			b DBTXTSTR   ,$12,$4a
			w dskTargetTxt

			b DBTXTSTR   ,$9c,$4a		;Laufwerks-Format.
			w dboxTxt07
			b DBTXTSTR   ,$a8,$4a
			w dboxDiskType

			b DBTXTSTR   ,$08,$58		;WiC64-IP.
			w dboxTxt05
			b DBTXTSTR   ,$3a,$58
			w com_getip_data
			b DBTXTSTR   ,$9c,$58		;WiC64-RSSI.
			w com_getsig_data

			b DBTXTSTR   ,$08,$62		;WiC64-Netzwerkname.
			w dboxTxt06
			b DBTXTSTR   ,$22,$62
			w com_getnam_data

			b YES        ,$01,$68
			b CANCEL     ,$11,$68
			b NULL

if LANG = LANG_DE
:dboxTxt01		b PLAINTEXT,BOLDON
			b "Download starten?"
			b PLAINTEXT,NULL
;:dboxTxt02		b "Server:",NULL
;:dboxTxt03		b "Datei:",NULL
:dboxTxt04		b BOLDON,"Laufwerk:",PLAINTEXT,NULL
:dboxTxt05		b BOLDON,"WiC64-IP:",PLAINTEXT,NULL
:dboxTxt06		b BOLDON,"SSID:",PLAINTEXT,NULL
:dboxTxt07		b BOLDON,">>",PLAINTEXT,NULL
endif
if LANG = LANG_EN
:dboxTxt01		b PLAINTEXT,BOLDON
			b "Start download?"
			b PLAINTEXT,NULL
;:dboxTxt02		b "Server:",NULL
;:dboxTxt03		b "File:",NULL
:dboxTxt04		b BOLDON,"Drive:",PLAINTEXT,NULL
:dboxTxt05		b BOLDON,"WiC64-IP:",PLAINTEXT,NULL
:dboxTxt06		b BOLDON,"SSID:",PLAINTEXT,NULL
:dboxTxt07		b BOLDON,">>",PLAINTEXT,NULL
endif

:dboxDiskType		b "C41",NULL
:dboxDImgType		b "D41",NULL

:dboxTypeTab		b "??417181NM??????"

;*** Fehler: Laufwerke nicht kompatibel.
:Dlg_CompatErr		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$20
			w dloadErrInfo
			b DBTXTSTR   ,$08,$32
			w dloadErrTx01

			b DBTXTSTR   ,$08,$42
			w dloadErrTx11
			b DBTXTSTR   ,$50,$42
			w dboxDImgType

			b DBTXTSTR   ,$08,$4e
			w dloadErrTx12
			b DBTXTSTR   ,$50,$4e
			w dboxDiskType

			b CANCEL     ,$11,$48
			b NULL

;*** Fehler: Laufwerksgröße nicht ausreichend.
:Dlg_DskSizeErr		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$20
			w dloadErrInfo
			b DBTXTSTR   ,$08,$32
			w dloadErrTx02

			b DBTXTSTR   ,$08,$42
			w dloadErrTx11
			b DBTXTSTR   ,$50,$42
			w dboxDiskType

			b DBTXTSTR   ,$08,$4e
			w dloadErrTx12
			b DBTXTSTR   ,$50,$4e
			w dboxDImgType

			b CANCEL     ,$11,$48
			b NULL

;*** Fehler: Download-Format nicht erkannt.
:Dlg_UnknownDxx		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_ERR

			b DBTXTSTR   ,$08,$20
			w dloadErrInfo
			b DBTXTSTR   ,$08,$30
			w dloadErrTx21
			b DBTXTSTR   ,$08,$3b
			w dloadErrTx22

			b CANCEL     ,$11,$48
			b NULL

;*** Texte für Fehler bei Download-Konfiguration.
if LANG = LANG_DE
:dloadErrInfo		b PLAINTEXT,BOLDON
			b "Download nicht möglich!"
			b PLAINTEXT,NULL
:dloadErrTx01		b "Datei und Laufwerk nicht kompatibel:",NULL
:dloadErrTx02		b "Laufwerksgröße nicht ausreichend:",NULL
:dloadErrTx11		b "Modus/Datei:",NULL
:dloadErrTx12		b "Ziel-Laufwerk:",NULL
:dloadErrTx21		b "Der Download-Modus funktioniert",NULL
:dloadErrTx22		b "nur mit .Dxx-Dateien.",NULL
endif
if LANG = LANG_EN
:dloadErrInfo		b PLAINTEXT,BOLDON
			b "Download not possible!"
			b PLAINTEXT,NULL
:dloadErrTx01		b "File and drive type not compatible:",NULL
:dloadErrTx02		b "Drive size not sufficient:",NULL
:dloadErrTx11		b "Mode/File:",NULL
:dloadErrTx12		b "Target drive:",NULL
:dloadErrTx21		b "Download mode works only",NULL
:dloadErrTx22		b "with .Dxx files.",NULL
endif

;*** Dialogbox: Diskinfo anzeigen.
:Dlg_DiskInfo		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO

			b DBTXTSTR   ,$08,$20
			w dskInfTx00
			b DB_USR_ROUT
			w drawDiskInfo

			b OK         ,$11,$48
			b NULL

if LANG = LANG_DE
:dskInfTx00		b PLAINTEXT,BOLDON
			b "Information Ziel-Laufwerk:",NULL
:dskInfTx01		b BOLDON,"Disk: ",PLAINTEXT,NULL
:dskInfTx02		b BOLDON,"Frei: ",PLAINTEXT,NULL
:dskInfTx03		b " Blocks",NULL
endif
if LANG = LANG_EN
:dskInfTx00		b PLAINTEXT,BOLDON
			b "Target drive information:",NULL
:dskInfTx01		b BOLDON,"Disk: ",PLAINTEXT,NULL
:dskInfTx02		b BOLDON,"Free: ",PLAINTEXT,NULL
:dskInfTx03		b " blocks",NULL
endif

;*** Dialogbox: Status Debug-Modus.
:Dlg_DebugMode		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO

			b DBVARSTR   ,$08,$20
			b r10L

			b OK         ,$01,$48
			b NULL

if LANG = LANG_DE
:dboxDebug01		b PLAINTEXT,BOLDON
			b "Debug-Modus aktiviert!",NULL
:dboxDebug02		b PLAINTEXT,BOLDON
			b "Debug-Modus deaktiviert!",NULL
endif
if LANG = LANG_EN
:dboxDebug01		b PLAINTEXT,BOLDON
			b "Debug mode enabled!",NULL
:dboxDebug02		b PLAINTEXT,BOLDON
			b "Debug mode disabled!",NULL
endif

;*** Dialogbox: SwapList aktivieren?
:Dlg_SwapList		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO

			b DBTXTSTR   ,$08,$24
			w :1
			b DBTXTSTR   ,$08,$32
			w :2

			b YES        ,$01,$48
			b NO         ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "SD2IEC/SWAPLIST erkannt!"
			b PLAINTEXT,NULL
::2			b "`SWAPLIST.LST` aktivieren?",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "SD2IEC/swap list detected!"
			b PLAINTEXT,NULL
::2			b "Enable `SWAPLIST.LST`?",NULL
endif

;*** Dialogbox: SwapList erstellen?
:Dlg_MakeSwap		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO

			b DBTXTSTR   ,$08,$24
			w :1
			b DBTXTSTR   ,$08,$30
			w :2

			b YES        ,$01,$48
			b NO         ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Soll eine SWAPLIST für die neuen",NULL
::2			b "Dateien erstellt werden?",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "Should a SWAPLIST be created",NULL
::2			b "for the new files?",NULL
endif

;*** Dialogbox: Dateiname für SwapList eingeben.
:Dlg_SwapName		b %10000001

			b DB_USR_ROUT
			w drawDBoxHeader
			b DBTXTSTR   ,$08,$0a
			w DLG_TITEL_INFO

			b DBTXTSTR   ,$08,$24
			w :1

			b DBTXTSTR   ,$10,$39
			w :2
			b DBGETSTRING,$1c,$32
			b r10L,16

			b CANCEL     ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Dateiname für SWAPLIST eingeben:",NULL
::2			b BOLDON,">>",PLAINTEXT,NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "Enter filename for SWAPLIST:",NULL
::2			b BOLDON,">>",PLAINTEXT,NULL
endif

;*** Beginn nicht initialisierter Speicher.
:SYS_DATA_START

:lnkCount		= SYS_DATA_START
:lnkPointer		= lnkCount       +1
:lnkEntries		= lnkPointer     +1

:urlDList		= lnkEntries     + (maxListEntries *2)
:urlDFile		= urlDList       +256
:dboxTxtServer		= urlDFile       +256
:dboxTxtDImg		= dboxTxtServer  +lenNameServer  +1

:END_DATA_1		= dboxTxtDImg    +lenNameRequest +1

;**** Download-Adressen.
;HINWEIS:
;GEOS verwendet ASCII-Codes, daher hier
;die URL in Kleinbuchstaben!
;
;Der WiC64-Befehl wird als PETSCII-Code
;gesendet, daher Großbuchstaben!
;$01=LOAD/HTTP=Max64K
;$25=LOADLONG/HTTP=Max2TB
;
;--- Download-URL.
:max_geturl_data	= 256 +4  ;URL max. 255 Zeichen + $00-Byte.
:com_geturl		= END_DATA_1
:com_geturl_size	= com_geturl      +1
:com_geturl_mode	= com_geturl_size +2
:com_geturl_data	= com_geturl_mode +1

;--- Link-Liste.
:max_getlnk_data	= 256 +4  ;URL max. 255 Zeichen + $00-Byte.
:com_getlnk		= com_geturl      +max_geturl_data
:com_getlnk_size	= com_getlnk      +1
:com_getlnk_mode	= com_getlnk_size +2
:com_getlnk_data	= com_getlnk_mode +1

:SYS_DATA_END		= (com_getlnk +max_getlnk_data)

;******************************************************************************
;*** Endadresse testen:                                                     ***
			g MAX_APP_AREA  - (SYS_DATA_END - SYS_DATA_START)
;******************************************************************************
