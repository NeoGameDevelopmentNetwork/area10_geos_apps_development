; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei-Eigenschaften anzeigen.
;
;--- Speicherbelegung:
;$0400-$37FF: GeoDesk/FileInfo
;$3800-$4BFF: Ausgewählte Dateieinträge
;$4C00-$5FFF: Dateien im Fenster
;$6000-$6CFF: Zwischenspeicher
;$6D00-$78FF: Registermenü
;$7900-$7FFF: Drucker/Zwischenspeicher

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"
endif

;*** GEOS-Header.
			n "obj.GD80"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xFILE_INFO

;*** Systemroutinen.
			t "-SYS_GTYPE"
			t "-SYS_GTYPE_TXT"
			t "-SYS_CTYPE"
			t "-SYS_STATMSG"

;*** Datei-Eigenschaften anzeigen.
:xFILE_INFO		jsr	i_FillRam		;Speicher initialisieren.
			w	dirEntryData_S
			w	dirEntryData
			b	$00

			jsr	i_FillRam		;Speicher initialisieren.
			w	SIZE_EXTDATA
			w	BASE_EXTDATA
			b	$00

			jsr	copyDirEntryData	;Dateinamen in Speicher kopieren.

			ldx	slctFiles		;Dateien ausgewählt?
			beq	ExitFileInfo		;=> Nein, Ende...

			LoadB	curFile,$00		;Zeiger auf erste Datei.
			LoadW	curFileVec,dirEntryData

			jsr	GetFileData		;Datei-Info einlesen.
			jsr	chkDateAndTime		;Datum/Uhrzeit überprüfen.

;--- Register-Menü initialisieren.
;			ClrB	regUpdate		;Flag löschen "Update Register".
			ClrB	reloadDir		;Flag löschen "Verzeichnis laden".

			jsr	SetADDR_Register	;RegisterMenü-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Register-Font aktivieren.

			LoadW	r0,RegMenu1
			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" initialisieren.
			lda	C_RegisterExit		;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
			b	(R1SizeX0/8) +1
			b	(R1SizeY0/8) -1
			b	IconExit_x
			b	IconExit_y/8

			LoadW	r0,IconMenu
			jmp	DoIcons			;Icon-Menü aktivieren.

;*** Zurück zum DeskTop.
:Exit			jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			bit	GD_INFO_SAVE		;Datei-Info automatisch speichern?
			bpl	:1			; => Nein, weiter...

			lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			beq	:1			; => Gelöschte Datei, weiter...

			jsr	doSaveData		;Datei-Info speichern.

::1			jsr	StopTextEdit		;Datei-Infotext-Eingabe beenden.
			jsr	ExitRegisterMenu	;Register-Menü beenden.

:ExitFileInfo		bit	reloadDir		;Verzeichnis neu laden?
			bpl	:2			; => Nein, weiter...

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen, da
							;evtl. Dateien umbenannt.

::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.

;*** Icon-Menü "Beenden".
:IconMenu		b $01
			w $0000
			b $00

			w IconExit
			b (R1SizeX0/8) +1,R1SizeY0 -$08
			b IconExit_x,IconExit_y
			w Exit

:IconExit
<MISSING_IMAGE_DATA>

:IconExit_x		= .x
:IconExit_y		= .y

;*** Register-Menü.
:R1SizeY0 = $28
:R1SizeY1 = $af
:R1SizeX0 = $0028
:R1SizeX1 = $0117

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 3				;Anzahl Einträge.

			w RegTName1			;Register: "CBM".
			w RegTMenu1

			w RegTName2			;Register: "GEOS".
			w RegTMenu2

			w RegTName3			;Register: "GEOS-INFO".
			w RegTMenu3

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RegTName2		w RTabIcon2
			b RCardIconX_2,R1SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

:RegTName3		w RTabIcon3
			b RCardIconX_3,R1SizeY0 -$08
			b RTabIcon3_x,RTabIcon3_y

:RTabIcon3
<MISSING_IMAGE_DATA>

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x
:RCardIconX_3		= RCardIconX_2 + RTabIcon2_x

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= FALSE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Icons zum laden/speichern der Datei-Eigenschaften.
:RIcon_Save		w Icon_Save
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Save_x,Icon_Save_y
			b USE_COLOR_INPUT

:Icon_Save
<MISSING_IMAGE_DATA>

:Icon_Save_x		= .x
:Icon_Save_y		= .y

:RIcon_Undo		w Icon_Undo
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Undo_x,Icon_Undo_y
			b USE_COLOR_INPUT

:Icon_Undo
<MISSING_IMAGE_DATA>

:Icon_Undo_x		= .x
:Icon_Undo_y		= .y

;*** Icon für Seitenwechsel.
:RIcon_Page		w SlctPage
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b SlctPage_x,SlctPage_y
			b USE_COLOR_INPUT

:SlctPage
<MISSING_IMAGE_DATA>

:SlctPage_x		= .x
:SlctPage_y		= .y

:PosSlctPage_x		= (R1SizeX1 +1) -$10
:PosSlctPage_y		= (R1SizeY1 +1) -$10

;*** Icons für Optionen.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

:RIcon_DateTime		w Icon_DateTime
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_DateTime_x,Icon_DateTime_y
			b USE_COLOR_INPUT

:Icon_DateTime
<MISSING_IMAGE_DATA>

:Icon_DateTime_x	= .x
:Icon_DateTime_y	= .y

:RIcon_Upper		w Icon_Upper
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Upper_x,4 ;Icon_Upper_y
			b USE_COLOR_REG

:Icon_Upper
<MISSING_IMAGE_DATA>

:Icon_Upper_x		= .x
:Icon_Upper_y		= .y

:RIcon_Lower		w Icon_Lower
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Lower_x,4 ;Icon_Lower_y
			b USE_COLOR_REG

:Icon_Lower
<MISSING_IMAGE_DATA>

:Icon_Lower_x		= .x
:Icon_Lower_y		= .y

:RIcon_FSetSlct		w Icon_FSetSlct
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FSetSlct_x,Icon_FSetSlct_y
			b USE_COLOR_INPUT

:Icon_FSetSlct
<MISSING_IMAGE_DATA>

:Icon_FSetSlct_x	= .x
:Icon_FSetSlct_y	= .y

:RIcon_FSetAll		w Icon_FSetAll
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FSetAll_x,Icon_FSetAll_y
			b USE_COLOR_INPUT

:Icon_FSetAll
<MISSING_IMAGE_DATA>

:Icon_FSetAll_x		= .x
:Icon_FSetAll_y		= .y

;*** Icons für InfoText-Zwischenspeicher.
:RIcon_ClrText		w Icon_ClrText
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_ClrText_x,Icon_ClrText_y
			b USE_COLOR_INPUT

:Icon_ClrText
<MISSING_IMAGE_DATA>

:Icon_ClrText_x		= .x
:Icon_ClrText_y		= .y

:RIcon_SaveBuf1		w Icon_SaveBuf1
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SaveBuf1_x,Icon_SaveBuf1_y
			b USE_COLOR_INPUT

:Icon_SaveBuf1
<MISSING_IMAGE_DATA>

:Icon_SaveBuf1_x	= .x
:Icon_SaveBuf1_y	= .y

:RIcon_LoadBuf1		w Icon_LoadBuf1
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_LoadBuf1_x,Icon_LoadBuf1_y
			b USE_COLOR_INPUT

:Icon_LoadBuf1
<MISSING_IMAGE_DATA>

:Icon_LoadBuf1_x	= .x
:Icon_LoadBuf1_y	= .y

:RIcon_SaveBuf2		w Icon_SaveBuf2
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SaveBuf2_x,Icon_SaveBuf2_y
			b USE_COLOR_INPUT

:Icon_SaveBuf2
<MISSING_IMAGE_DATA>

:Icon_SaveBuf2_x	= .x
:Icon_SaveBuf2_y	= .y

:RIcon_LoadBuf2		w Icon_LoadBuf2
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_LoadBuf2_x,Icon_LoadBuf2_y
			b USE_COLOR_INPUT

:Icon_LoadBuf2
<MISSING_IMAGE_DATA>

:Icon_LoadBuf2_x	= .x
:Icon_LoadBuf2_y	= .y

:RIcon_SaveBuf3		w Icon_SaveBuf3
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SaveBuf3_x,Icon_SaveBuf3_y
			b USE_COLOR_INPUT

:Icon_SaveBuf3
<MISSING_IMAGE_DATA>

:Icon_SaveBuf3_x	= .x
:Icon_SaveBuf3_y	= .y

:RIcon_LoadBuf3		w Icon_LoadBuf3
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_LoadBuf3_x,Icon_LoadBuf3_y
			b USE_COLOR_INPUT

:Icon_LoadBuf3
<MISSING_IMAGE_DATA>

:Icon_LoadBuf3_x	= .x
:Icon_LoadBuf3_y	= .y

;*** Daten für Register "CBM".
:DIGIT_2_BYTE = $02 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:RPos1_x  = R1SizeX0 +$08
:RPos1_y  = R1SizeY0 +$28
:RTab1_1  = $0050
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $30
:RLine1_5 = $40
:RLine1_6 = $50

:RegTMenu1		b 35

			b BOX_ICON
				w $0000
				w SaveFileData
				b R1SizeY0 +$08
				w RPos1_x
				w RIcon_Save
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w ResetFileInfo
				b R1SizeY0 +$08
				w RPos1_x +$18
				w RIcon_Undo
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b NO_OPT_UPDATE

			b BOX_OPTION
				w R1T00
				w $0000
				b R1SizeY0 +$10
				w RPos1_x +RTab1_1 +$78
				w GD_INFO_SAVE
				b %11111111

			b BOX_USER_VIEW
				w $0000
				w InitRegTab
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$0f
				w RPos1_x
				w RPos1_x +$0f

			b BOX_STRING
				w R1T01
				w chkFileName
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w curFileName
				b 16

;--- Datum.
			b BOX_ICON
				w $0000
				w editDayUp
				b RPos1_y +RLine1_2 -6
				w RPos1_x +RTab1_1
				w RIcon_Upper
				b (RegTMenu1c - RegTMenu1 -1)/11 +1
:RegTMenu1c		b BOX_NUMERIC
				w R1T02
				w chkDateDay
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1
				w curDirEntry +27
				b DIGIT_2_BYTE
			b BOX_ICON
				w $0000
				w editDayDn
				b RPos1_y +RLine1_2 +10
				w RPos1_x +RTab1_1
				w RIcon_Lower
				b (RegTMenu1c - RegTMenu1 -1)/11 +1

			b BOX_ICON
				w $0000
				w editMonthUp
				b RPos1_y +RLine1_2 -6
				w RPos1_x +RTab1_1 +$18
				w RIcon_Upper
				b (RegTMenu1d - RegTMenu1 -1)/11 +1
:RegTMenu1d		b BOX_NUMERIC
				w R1T02a
				w chkDateMonth
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +$18
				w curDirEntry +26
				b DIGIT_2_BYTE
			b BOX_ICON
				w $0000
				w editMonthDn
				b RPos1_y +RLine1_2 +10
				w RPos1_x +RTab1_1 +$18
				w RIcon_Lower
				b (RegTMenu1d - RegTMenu1 -1)/11 +1

			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -1
				b RPos1_y +RLine1_2 +8
				w RPos1_x +RTab1_1 +$30 -1
				w RPos1_x +RTab1_1 +$30 +$10 +8
			b BOX_ICON
				w $0000
				w editYearUp
				b RPos1_y +RLine1_2 -6
				w RPos1_x +RTab1_1 +$30
				w RIcon_Upper
				b (RegTMenu1e - RegTMenu1 -1)/11 +1
:RegTMenu1e		b BOX_NUMERIC
				w R1T02b
				w chkDateYear
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +$30
				w curDirEntry +25
				b DIGIT_2_BYTE
			b BOX_ICON
				w $0000
				w editYearDn
				b RPos1_y +RLine1_2 +10
				w RPos1_x +RTab1_1 +$30
				w RIcon_Lower
				b (RegTMenu1e - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w SetCurDate
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +$40
				w RIcon_DateTime
				b NO_OPT_UPDATE

;--- Zeit.
			b BOX_ICON
				w $0000
				w editHourUp
				b RPos1_y +RLine1_2 -6
				w RPos1_x +RTab1_1 +$50
				w RIcon_Upper
				b (RegTMenu1f - RegTMenu1 -1)/11 +1
:RegTMenu1f		b BOX_NUMERIC
				w $0000
				w chkDateHour
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +$50
				w curDirEntry +28
				b DIGIT_2_BYTE
			b BOX_ICON
				w $0000
				w editHourDn
				b RPos1_y +RLine1_2 +10
				w RPos1_x +RTab1_1 +$50
				w RIcon_Lower
				b (RegTMenu1f - RegTMenu1 -1)/11 +1

			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -1
				b RPos1_y +RLine1_2 +8
				w RPos1_x +RTab1_1 +$68 -1
				w RPos1_x +RTab1_1 +$68 +$10 +8
			b BOX_ICON
				w $0000
				w editMinUp
				b RPos1_y +RLine1_2 -6
				w RPos1_x +RTab1_1 +$68
				w RIcon_Upper
				b (RegTMenu1g - RegTMenu1 -1)/11 +1
:RegTMenu1g		b BOX_NUMERIC
				w R1T03
				w chkDateMinute
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +$68
				w curDirEntry +29
				b DIGIT_2_BYTE
			b BOX_ICON
				w $0000
				w editMinDn
				b RPos1_y +RLine1_2 +10
				w RPos1_x +RTab1_1 +$68
				w RIcon_Lower
				b (RegTMenu1g - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w SetCurTime
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1 +$78
				w RIcon_DateTime
				b NO_OPT_UPDATE

;--- Datum/Zeit für Dateien übernehmen.
			b BOX_ICON
				w R1T09
				w svTimeAllFiles
				b RPos1_y +RLine1_3
				w RPos1_x +$50
				w RIcon_FSetSlct
				b NO_OPT_UPDATE
if LANG = LANG_DE
			b BOX_ICON
				w $0000
				w svTimeDiskFiles
				b RPos1_y +RLine1_3
				w RPos1_x +$88
				w RIcon_FSetAll
				b NO_OPT_UPDATE
endif
if LANG = LANG_EN
			b BOX_ICON
				w $0000
				w svTimeDiskFiles
				b RPos1_y +RLine1_3
				w RPos1_x +$90
				w RIcon_FSetAll
				b NO_OPT_UPDATE
endif

;--- Dateigröße.
			b BOX_NUMERIC_VIEW
				w R1T04
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_1
				w curDirEntry +30
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW
				w R1T05
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_1 +$48
				w curDirEntry +0
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT

;--- Dateityp.
:RegTMenu1b		b BOX_STRING_VIEW
				w R1T06
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_1 -$08
				w curFileType
				b $03
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_5 -1
				b RPos1_y +RLine1_5 +8
				w RPos1_x +RTab1_1 -$08 -1
				w RPos1_x +RTab1_1 +$10 +8
			b BOX_ICON
				w $0000
				w setCBMFType
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_1 +$10
				w RIcon_Select
				b NO_OPT_UPDATE

;--- GEOS-Dateistruktur.
			b BOX_STRING_VIEW
				w R1T06a
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_1 +$20 +$38
:RegTMenu1a			w $ffff
				b $05

;--- Dateieigenschaften.
			b BOX_OPTION
				w R1T08
				w $0000
				b RPos1_y +RLine1_6
				w RPos1_x +RTab1_1 +$10
				w curDirEntry +2
				b %10000000
			b BOX_OPTION
				w R1T07
				w $0000
				b RPos1_y +RLine1_6
				w RPos1_x +RTab1_1 +$78
				w curDirEntry +2
				b %01000000

;*** Texte für Register "CBM".
if LANG = LANG_DE
:R1T00			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0f
			b "Eingaben beim beenden"
			b GOTOXY
			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$17
			b "automatisch speichern:"
			b GOTOXY
			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$1f
			b "Ausnahme: DEL-Dateien!",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Dateiname:",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Datum/Zeit:",NULL
:R1T02a			w RPos1_x +RTab1_1 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
:R1T02b			w RPos1_x +RTab1_1 +$18 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL

:R1T03			w RPos1_x +RTab1_1 +$18 +$18 +$18 +$18 +$02
			b RPos1_y +RLine1_2 +$06
			b ":",NULL

:R1T04			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "Dateigröße:"
			b GOTOXY
			w RPos1_x +RTab1_1 +$28 +$04
			b RPos1_y +RLine1_4 +$06
			b "Blks",NULL

:R1T05			w RPos1_x +RTab1_1 +$28 +$04 +$48
			b RPos1_y +RLine1_4 +$06
			b "KB",NULL

:R1T06			w RPos1_x
			b RPos1_y +RLine1_5 +$06
			b "Dateityp:",NULL
:R1T06a			w RPos1_x +RTab1_1 +$20
			b RPos1_y +RLine1_5 +$06
			b "Struktur:",NULL

:R1T07			w RPos1_x +RTab1_1 +$20
			b RPos1_y +RLine1_6 +$06
			b "Schreibschutz:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "Geschlossen (*):",NULL

:R1T09			w RPos1_x +$00
			b RPos1_y +RLine1_3 +$06
			b "->Übernehmen"
			b GOTOXY
			w RPos1_x +$5a
			b RPos1_y +RLine1_3 +$06
			b "Auswahl"
			b GOTOXY
			w RPos1_x +$92
			b RPos1_y +RLine1_3 +$06
			b "Verzeichnis"
			b NULL
endif
if LANG = LANG_EN
:R1T00			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0f
			b "Update file properties"
			b GOTOXY
			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$17
			b "automatically on exit:"
			b GOTOXY
			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$1f
			b "Except for DEL files!",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Filename:",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Date/Time:",NULL
:R1T02a			w RPos1_x +RTab1_1 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
:R1T02b			w RPos1_x +RTab1_1 +$18 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL

:R1T03			w RPos1_x +RTab1_1 +$18 +$18 +$18 +$18 +$02
			b RPos1_y +RLine1_2 +$06
			b ":",NULL

:R1T04			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "Filesize:"
			b GOTOXY
			w RPos1_x +RTab1_1 +$28 +$04
			b RPos1_y +RLine1_4 +$06
			b "Blks",NULL

:R1T05			w RPos1_x +RTab1_1 +$28 +$04 +$48
			b RPos1_y +RLine1_4 +$06
			b "KB",NULL

:R1T06			w RPos1_x
			b RPos1_y +RLine1_5 +$06
			b "Filetype:",NULL
:R1T06a			w RPos1_x +RTab1_1 +$20
			b RPos1_y +RLine1_5 +$06
			b "Filemode:",NULL

:R1T07			w RPos1_x +RTab1_1 +$20
			b RPos1_y +RLine1_6 +$06
			b "Write-protect:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "File closed (*):",NULL

:R1T09			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "-> Apply to"
			b GOTOXY
			w RPos1_x +$5a
			b RPos1_y +RLine1_3 +$06
			b "Selected"
			b GOTOXY
			w RPos1_x +$9a
			b RPos1_y +RLine1_3 +$06
			b "Directory"
			b NULL
endif

;*** Daten für Register "GEOS".
:RPos2_x  = R1SizeX0 +$08
:RPos2_y  = R1SizeY0 +$28
:RTab2_1  = $0040
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $20
:RLine2_4 = $30
:RLine2_5 = $40
:RLine2_6 = $50

:RegTMenu2		b 18

			b BOX_ICON
				w $0000
				w SaveFileData
				b R1SizeY0 +$08
				w RPos2_x
				w RIcon_Save
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w ResetFileInfo
				b R1SizeY0 +$08
				w RPos2_x +$18
				w RIcon_Undo
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b NO_OPT_UPDATE
			b BOX_STRING_VIEW
				w R2T01
				w $0000
				b R1SizeY0 +$10
				w RPos2_x +$18 +$18 +$10
				w curFileName
				b 16

			b BOX_USER_VIEW
				w $0000
				w InitRegTab
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$0f
				w RPos2_x
				w RPos2_x +$0f

;--- GEOS-Dateityp.
:RegTMenu2b		b BOX_STRING_VIEW
				w R2T02
				w $0000
				b RPos2_y +RLine2_1
				w RPos2_x +RTab2_1
				w curGEOSType
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b RPos2_y +RLine2_1 -1
				b RPos2_y +RLine2_1 +8
				w RPos2_x +RTab2_1 -1
				w RPos2_x +RTab2_1 +$80 +8
:RegTMenu2c		b BOX_ICON
				w $0000
				w SetGEOSType
				b RPos2_y +RLine2_1
				w RPos2_x +RTab2_1 +$80
				w RIcon_Select
				b (RegTMenu2b - RegTMenu2 -1)/11 +1

;--- GEOS-Klasse.
:RegTMenu2g		b BOX_STRING
				w R2T03
				w ChkGEOSClass
				b RPos2_y +RLine2_2
				w RPos2_x +RTab2_1
				w curClass
				b 12
:RegTMenu2h		b BOX_STRING
				w $0000
				w ChkGEOSVersion
				b RPos2_y +RLine2_2
				w RPos2_x +RTab2_1 +$68
				w curClassVer
				b 6

;--- Autor.
:RegTMenu2e		b BOX_STRING
				w R2T04
				w SetGEOSAuthor
				b RPos2_y +RLine2_3
				w RPos2_x +RTab2_1
				w curAuthor
				b 19

			b BOX_ICON
				w R2T07
				w svAuthorAllFiles
				b RPos2_y +RLine2_4
				w RPos2_x +RTab2_1
				w RIcon_FSetSlct
				b NO_OPT_UPDATE

;--- Bildschirm-Modus.
:RegTMenu2d		b BOX_STRING_VIEW
				w R2T05
				w $0000
				b RPos2_y +RLine2_5
				w RPos2_x +RTab2_1
				w curScrnMode
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b RPos2_y +RLine2_5 -1
				b RPos2_y +RLine2_5 +8
				w RPos2_x +RTab2_1 -1
				w RPos2_x +RTab2_1 +$80 +8
:RegTMenu2f		b BOX_ICON
				w $0000
				w SetScrnMode
				b RPos2_y +RLine2_5
				w RPos2_x +RTab2_1 +$80
				w RIcon_Select
				b (RegTMenu2d - RegTMenu2 -1)/11 +1

;--- Lade-/End-/Startadresse.
			b BOX_STRING_VIEW
				w R2T06
				w $0000
				b RPos2_y +RLine2_6
				w RPos2_x +RTab2_1 +$08
				w curAdrGEOSload
				b 4
			b BOX_STRING_VIEW
				w R2T06a
				w $0000
				b RPos2_y +RLine2_6
				w RPos2_x +RTab2_1 +$08 +$30
				w curAdrGEOSend
				b 4
			b BOX_STRING_VIEW
				w R2T06b
				w $0000
				b RPos2_y +RLine2_6
				w RPos2_x +RTab2_1 +$08 +$30 +$30
				w curAdrGEOSrun
				b 4

;*** Daten für Register "GEOS".
if LANG = LANG_DE
:R2T01			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0d
			b "Aktuelle Datei:",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Dateityp:",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "Klasse:",NULL

:R2T04			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "Autor:",NULL

:R2T05			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "Modus:",NULL

:R2T06			w RPos2_x
			b RPos2_y +RLine2_6 +$06
			b "Adressen:"
			b GOTOXY
			w RPos2_x +RTab2_1
			b RPos2_y +RLine2_6 +$06
			b "L",NULL
:R2T06a			w RPos2_x +RTab2_1 +$08 +$27
			b RPos2_y +RLine2_6 +$06
			b "E",NULL
:R2T06b			w RPos2_x +RTab2_1 +$08 +$30 +$27
			b RPos2_y +RLine2_6 +$06
			b "S",NULL
:R2T07			w RPos2_x +RTab2_1 +$08 +$04
			b RPos2_y +RLine2_4 +$06
			b "Für Auswahl Übernehmen"
			b NULL
endif
if LANG = LANG_EN
:R2T01			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0d
			b "Current file:",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Filetype:",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "Class:",NULL

:R2T04			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "Author:",NULL

:R2T05			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "Mode:",NULL

:R2T06			w RPos2_x
			b RPos2_y +RLine2_6 +$06
			b "Address:"
			b GOTOXY
			w RPos2_x +RTab2_1
			b RPos2_y +RLine2_6 +$06
			b "L",NULL
:R2T06a			w RPos2_x +RTab2_1 +$08 +$27
			b RPos2_y +RLine2_6 +$06
			b "E",NULL
:R2T06b			w RPos2_x +RTab2_1 +$08 +$30 +$27
			b RPos2_y +RLine2_6 +$06
			b "S",NULL

:R2T07			w RPos2_x +RTab2_1 +$08 +$04
			b RPos2_y +RLine2_4 +$06
			b "Set for selected files"
			b NULL
endif

;*** Daten für Register "GEOS-INFO".
:RPos3_x   = R1SizeX0 +$08
:RPos3_y   = R1SizeY0 +$28
:RTab3_1  = $00b8
:RLine3_1 = $00
:RLine3_2 = $48

:RegTMenu3		b 15

			b BOX_ICON
				w $0000
				w SaveFileData
				b R1SizeY0 +$08
				w RPos3_x
				w RIcon_Save
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w ResetFileInfo
				b R1SizeY0 +$08
				w RPos3_x +$18
				w RIcon_Undo
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b NO_OPT_UPDATE
			b BOX_STRING_VIEW
				w R2T01
				w $0000
				b R1SizeY0 +$10
				w RPos3_x +$18 +$18 +$10
				w curFileName
				b 16

			b BOX_USER_VIEW
				w $0000
				w InitRegTab
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$0f
				w RPos3_x
				w RPos3_x +$0f

;--- GEOS-Icon.
			b BOX_USEROPT
				w R3T02
				w DefInfoIcon
				b RPos3_y +RLine3_1 +$08
				b RPos3_y +RLine3_1 +$08 +$30 -1
				w RPos3_x +RTab3_1
				w RPos3_x +RTab3_1 +$28 -1

;--- Infotext.
:RegTMenu3b		b BOX_USEROPT
				w R3T01
				w DefInfoText
				b RPos3_y +RLine3_1 +$08
				b RPos3_y +RLine3_1 +$08 +$30 -1
				w RPos3_x
				w RPos3_x +$a8 -1
			b BOX_FRAME
				w $0000
				w $0000
				b RPos3_y +RLine3_1 -1
				b RPos3_y +RLine3_1 +8 -1
				w RPos3_x +$a0 -1
				w RPos3_x +$a0 +8
			b BOX_ICON
				w $0000
				w ClrInfoText
				b RPos3_y +RLine3_1
				w RPos3_x +$a0
				w RIcon_ClrText
				b (RegTMenu3b - RegTMenu3 -1)/11 +1

;--- Text-Speicher #1-#3.
			b BOX_ICON
				w R3T03
				w doSaveBuf1
				b RPos3_y +RLine3_2
				w RPos3_x +$00
				w RIcon_SaveBuf1
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w doLoadBuf1
				b RPos3_y +RLine3_2
				w RPos3_x +$18
				w RIcon_LoadBuf1
				b NO_OPT_UPDATE

			b BOX_ICON
				w $0000
				w doSaveBuf2
				b RPos3_y +RLine3_2
				w RPos3_x +$40
				w RIcon_SaveBuf2
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w doLoadBuf2
				b RPos3_y +RLine3_2
				w RPos3_x +$58
				w RIcon_LoadBuf2
				b NO_OPT_UPDATE

			b BOX_ICON
				w $0000
				w doSaveBuf3
				b RPos3_y +RLine3_2
				w RPos3_x +$80
				w RIcon_SaveBuf3
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w doLoadBuf3
				b RPos3_y +RLine3_2
				w RPos3_x +$98
				w RIcon_LoadBuf3
				b NO_OPT_UPDATE

;*** Texte für Register "GEOS-INFO".
if LANG = LANG_DE
:R3T01			w RPos3_x
			b RPos3_y +RLine3_1 +$04
			b "Infotext:",NULL

:R3T02			w RPos3_x +RTab3_1
			b RPos3_y +RLine3_1 +$04
			b "Icon:",NULL

:R3T03			w RPos3_x
			b RPos3_y +RLine3_2 -$04
			b "Infotext-Zwischenspeicher:",NULL
endif
if LANG = LANG_EN
:R3T01			w RPos3_x
			b RPos3_y +RLine3_1 +$04
			b "Info text:",NULL

:R3T02			w RPos3_x +RTab3_1
			b RPos3_y +RLine3_1 +$04
			b "Icon:",NULL

:R3T03			w RPos3_x
			b RPos3_y +RLine3_2 -$04
			b "Buffers for info text:",NULL
endif

;*** Verzeichniseinträge sichern.
;HINWEIS:
;Hier werden ganze Verzeichniseinträge
;gesichert und nicht nur die Datei-
;namen => Über ":FindFile" können keine
;gelöschten Dateien gesucht werden.
:copyDirEntryData	lda	fileEntryCount
			bne	:find_files		; => Dateien vorhanden, weiter...
			sta	slctFiles		; => Keine Dateien ausgewählt, Ende.
			rts

::find_files		LoadW	r0,BASE_DIRDATA		;Zeiger auf Verzeichnis-Daten.
			LoadW	r1,dirEntryData		;Zeiger auf Zwischenspeicher.
			LoadW	r2,32			;Größe Verzeichnis-Eintrag.

			lda	#$00			;Dateizähler auf Angang.
			sta	r3L

			sta	slctFiles		;Anzahl Dateien im Speicher.

::loop			ldy	#$00
			lda	(r0L),y			;Datei ausgewählt?
			beq	:next_file		; => Nein, weiter...

			jsr	MoveData		;Verzeichnis-Eintrag speichern.

			inc	slctFiles		;Anzahl Dateien +1.
			AddVBW	32,r1			;Zeiger auf nächsten Speicher.

			lda	slctFiles
			cmp	#255			;Speicher voll?
			beq	:buffer_full		; => Ja, Ende...

			CmpWI	r1,RegMenuBase
			beq	:buffer_full		; => Ja, Ende...

::next_file		inc	r3L			;Dateizähler +1.

::1			AddVBW	32,r0			;Nächster Verzeichnis-Eintrag.

			lda	r3L			;Alle markierte Einträge kopiert?
			cmp	fileEntryCount
::2			bcc	:loop			; => Nein, weiter...

::buffer_full		rts

;*** Datei-Informationen einlesen.
:GetFileData		ClrB	setDateTime

			jsr	i_FillRam		;Datei-Informationen löschen.
			w	(FILE_VAR_END - FILE_VAR_START)
			w	FILE_VAR_START
			b	$00

			MoveW	curFileVec,r6		;Zeiger auf aktuellen
							;Verzeichnis-Eintrag setzen.

			ldy	#2			;Verzeichnis-Eintrag in
::1			lda	(r6L),y			;Zwischenspeicher kopieren.
			sta	curDirEntry,y
			iny
			cpy	#32
			bcc	:1

			LoadW	r7,curDirEntry +5
			LoadW	r8,curFileName		;Zwischenspeicher Dateiname.

			ldx	#r7L
			ldy	#r8L
			jsr	SysFilterName		;Dateiname kopieren.

			ldy	#0
::backupName		lda	curFileName,y
			sta	bakFileName,y
			iny
			cpy	#16
			bcc	:backupName

			lda	curDirEntry +30		;Größe in Blocks einlesen.
			sta	r0L
			lda	curDirEntry +31
			sta	r0H

			lda	r0L
			pha
			ldx	#r0L
			ldy	#$02
			jsr	DShiftRight		;Blocks in KBytes umrechnen.
			pla
			and	#%00000011		;Auf volle KByte aufrunden?
			beq	:2			; => Bereits volle KByte, weiter...

			IncW	r0

::2			MoveW	r0,curDirEntry		;Größe in KByte in den ungenutzen
							;Bytes #0 und #1 speichern.

			jsr	getCBMFType		;CBM-Dateityp definieren.

::fileSEQ		lda	#< fileStructSEQ	;Zeiger auf Text "SEQ" für
			ldx	#> fileStructSEQ	;Sequentielle Dateistruktur.
			ldy	curDirEntry +23		;Dateistruktur = SEQ?
			beq	:5			; => Ja, weiter...

::fileVLIR		lda	#< fileStructVLIR	;Zeiger auf Text "SEQ" für
			ldx	#> fileStructVLIR	;GEOS-VLIR Dateistruktur.

::5			sta	RegTMenu1a +0		;Zeiger auf Text für
			stx	RegTMenu1a +1		;Dateistruktur speichern.

			lda	#BOX_STRING_VIEW
			sta	RegTMenu2e		;GEOS-Autor deaktivieren.
			sta	RegTMenu2g		;GEOS-Klasse deaktivieren.
			sta	RegTMenu2h		;GEOS-Klasse/Version deaktivieren.
			lda	#BOX_ICON_VIEW
			sta	RegTMenu2c		;GEOS-Dateityp deaktivieren.
			sta	RegTMenu2f		;GEOS-ScreenMode deaktivieren.

			lda	curDirEntry +24		;GEOS-Datei?
			beq	:exit			; => Nein, Ende...
			lda	curDirEntry +21		;Infoblock definiert?
			beq	:exit			; => Nein, Ende...

			jsr	readGeosHeader		;GEOS-InfoBlock einlesen.
			txa				;Header-Fehler?
			bne	:exit			; => Ja, keine GEOS-Info anzeigen.

			lda	#$ff			;GEOS-Datei.
			b $2c
::exit			lda	#$00			;CBM-Datei/Verzeichnis.
			sta	curFileGEOS

			jmp	DefGEOSType		;GEOS-Dateityp/Verzeichnis setzen.

;*** Daten aus GEOS-InfoBlock einlesen.
:readGeosHeader		LoadW	r9,curDirEntry +2	;Zeiger auf Verzeichnis-Eintrag.
			jsr	GetFHdrInfo		;InfoBlock einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#0
::1			lda	fileHeader,y
			cmp	headerCode,y
			bne	:err
			iny
			cpy	#5
			bcc	:1
			bcs	:ok

::err			jsr	i_FillRam		;Speicher initialisieren.
			w	256
			w	curFHdrInfo
			b	$00

			LoadB	curFileBadHdr,$ff	;Header als "Defekt" markieren.

			ldx	#STRUCT_MISMAT		;GEOS-Header fehlerhaft.
::exit			rts

::ok			jsr	i_MoveData		;InfoBlock in Zwischenspeicher.
			w	fileHeader
			w	curFHdrInfo
			w	256

			jsr	i_MoveData		;GEOS-Klasse in Zwischenspeicher.
			w	fileHeader +$4d
			w	curClass
			w	12

			jsr	i_MoveData		;Klasse/Version in Zwischenspeicher.
			w	fileHeader +$4d +12
			w	curClassVer
			w	6

			jsr	i_MoveData		;GEOS-Autor in Zwischenspeicher.
			w	fileHeader +$61
			w	curAuthor
			w	19

			lda	#BOX_STRING
			sta	RegTMenu2e		;GEOS-Autor aktivieren.
			sta	RegTMenu2g		;GEOS-Klasse aktivieren.
			sta	RegTMenu2h		;GEOS-Klasse/Version aktivieren.
			lda	#BOX_ICON
			sta	RegTMenu2c		;GEOS-Dateityp aktivieren.

			ldy	curFHdrInfo +$45
			beq	:skip_mode
			cpy	#DATA
			beq	:skip_mode
			cpy	#APPL_DATA
			beq	:skip_mode
			cpy	#FONT
			beq	:skip_mode
			cpy	#TEMPORARY
			beq	:skip_mode
			cpy	#GATEWAY_DIR
			beq	:skip_mode

::enable_mode		sta	RegTMenu2f		;GEOS-ScreenMode aktivieren.

			jsr	DefScrnMode		;Bildschirm-Modus einlesen.

::skip_mode		jsr	DefGEOSAuthor		;GEOS-Autor definieren.

			jsr	DefGEOSload		;GEOS-Lade/Ende/Start-Adressen.
			jsr	DefGEOSend
			jsr	DefGEOSrun

			ldx	#NO_ERROR
			rts

;*** Datei im Verzeichnis suchen.
;    Übergabe: r6 = Zeiger auf 32Byte Verzeichnis-Eintrag.
;    Rückgabe: r1L/r1H = Track/Sektor Verzeichnis-Eintrag.
;              r5      = Zeiger auf 30Byte-Verzeichnis-Eintrag.
;
;Hinweis:
;":FindFile" kann hier nicht verwendet
;werden, da hier auch gelöschte Dateien
;gesucht werden (Dateityp = $x0).
:userFindFile		jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:no_error		; => Ja, weiter...

;--- Ergänzung: 09.10.21/M.Kanet
;Bei gelöschten Dateien den genauen
;Dateieintrag suchen. Bei anderen
;Dateien nur Typ+Name vergleichen.
;Falls die Daten im Verzeichnis-Cache
;veraltet sind (z.B. Datum geändert)
;dann erzeugt diese Routine einen
;"FILE NOT FOUND"-Fehler.
;Test:
;* Laufwerk A: geöffnet.
;* MegaAssembler starten.
;* Datei auf A: neu assemblieren.
;  Dabei wird ein neues Datum vergeben.
;* Rückkehr zu GeoDesk.
;* Dateieintrag hat noch altes Datum.
;* Dateiinfo aufrufen und beenden.
;* Bei AutoSave -> "FILE NOT FOUND",
;  da die Datei auf Disk ein neueres
;  Datum enthält.
			tay
			lda	(r5L),y			;CBM-Dateityp einlesen und als
			sta	saveSearchFlg		;Suchmodus speichern.

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#0			;Zeiger auf erstes Byte.
::1			bit	saveSearchFlg		;Gelöschte Datei suchen ?
			bpl	:testByte		; => Ja, weiter...
			dey				;Zeiger korrigieren.
::skipPos		iny
			cpy	#$01
			beq	:skipPos		; => Datei/Track übergehen.
			cpy	#$02
			beq	:skipPos		; => Datei/Sektor übergehen.
			cpy	#$13
			beq	:skipPos		; => Infoblock/Track übergehen.
			cpy	#$14
			beq	:skipPos		; => Infoblock/Track übergehen.
			cpy	#$17
			bcs	:found			; => Datum/Zeit/Größe übergehen.
::testByte		lda	(r5L),y			;Eintrag im Verzeichnis mit
			iny				;gesuchtem Eintrag im Speicher
			iny				;vergleichen.
			cmp	(r6L),y			;Dateieintrag gefunden?
			bne	:next_file		; => Nein, nächste Datei.
			dey
			cpy	#30			;Alle Bytes geprüft ?
			bcc	:1			; => Nein, weiter...

::found			ldy	#30 -1 			;Dateieintrag kopieren.
::copy			lda	(r5L),y
			sta	dirEntryBuf,y
			dey
			bpl	:copy

::no_error		ldx	#NO_ERROR		;Ende.
			rts

;--- Weiter mit nächsten Eintrag.
::next_file		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Verzeichnis bearbeitet.
			ldx	#FILE_NOT_FOUND
::error			rts				;Ende.

;*** Datei-Informationen speichern.
;Am Ende Register-Karte neu laden.
:SaveFileData		jsr	doSaveData		;Datei-Informationen speichern.
			jmp	ResetFileInfo		;Register-Karte zurücksetzen.

;*** Datei-Informationen speichern.
:doSaveData		lda	curDirEntry +0		;Datei-Info gültig?
			cmp	#$ff
			bne	:1			; => Ja, weiter...
			lda	curDirEntry +1
			cmp	#$ff
			bne	:1			; => Ja, weiter...
			rts				; => Nein, Ende.

::1			lda	curFileVec +0		;Zeiger auf Dateiname im aktuellen
			clc				;Verzeichnis-Eintrag setzen.
			adc	#< $0005
			sta	r7L
			lda	curFileVec +1
			adc	#> $0005
			sta	r7H

			LoadW	r8,testFileName		;Zwischenspeicher Dateiname.

			ldx	#r7L
			ldy	#r8L
			jsr	SysCopyName		;Dateiname kopieren.

			LoadW	r6,curFileName		;Zeiger auf neuen Dateiname.

			ldx	#r6L
			ldy	#r8L
			jsr	CmpString		;Wurde Name geändert?
			beq	:skip_file_name		; => Nein, weiter...

			jsr	FindFile		;Neue Datei suchen.
			cpx	#FILE_NOT_FOUND		;Datei vorhanden?
			beq	:rename_ok		; => Nein, weiter...
			txa				;Laufwerksfehler?
			bne	:diskError		; => Ja, Abbruch...
							;Hinweis: gelöschte Dateien
							;werden bei der Suche ignoriert.

			LoadW	r0,Dlg_ErrRename	;Fehler anzeigen "File exist!".
			jsr	DoDlgBox

::skip_file_name	lda	#$ff			;Datei nicht umbenennen.
			b $2c
::rename_ok		lda	#$00			;Datei umbenennen.
			sta	renameFile		;Rename-Flag speichern.

			MoveW	curFileVec,r6
			jsr	userFindFile		;Aktuelle Datei suchen.
			txa				;Gefunden?
			bne	:diskError		; => Nein, Ende...

::copy_data		LoadB	reloadDir,$ff		;Dateien geändert, Verzeichnis
							;in GeoDesk neu einlesen.

::rename_file		bit	renameFile		;Datei umbenennen?
			bmi	:2			; => Nein, weiter...

			jsr	updateFileName		;Dateiname ändern.

::2			jsr	updateDirEntry		;CBM-Daten speichern.
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	curFileBadHdr		;Header beschädigt?
			bmi	:badHeader		; => Nein, weiter...

			bit	curFileGEOS		;GEOS-Datei?
			bmi	:updGEOSHdr		; => Ja, weiter...

			bit	renameFile		;Verzeichnis umbenennen?
			bmi	:exit			; => Nein, weiter...

::updDirHdr		jmp	updateDirHeader		;Verzeichnis-Header umbenennen.
::updGEOSHdr		jmp	updateGeosHeader	;GEOS-InfoBlock aktualisieren.
::diskError		jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;--- Defekter GEOS-Header.
::badHeader		LoadW	r0,Dlg_BadHdr
			jmp	DoDlgBox		;Fehlermeldung anzeigen.

;*** Dateiname aktualisieren.
;    Übergabe: curEntryVec = Zeiger auf 32Byte Verzeichnis-Eintrag.
;              curFileName = Neuer Dateiname.
:updateFileName		lda	curFileVec +0		;Zeiger auf aktuellen
			clc				;Verzeichnis-Eintrag im Speicher.
			adc	#< $0002
			sta	r8L
			lda	curFileVec +1
			adc	#> $0002
			sta	r8H

			ldy	#3			;Dateiname in aktueller
			ldx	#0			;Dateiliste aktualisieren und
::1			lda	curFileName,x		;in Verzeichnis-Eintrag speichern.
			beq	:2
			sta	(r5L),y
			sta	(r8L),y
			iny
			inx
			cpx	#16
			bcc	:1
			bcs	:4

::2			lda	#$a0			;Auf 16 Zeichen mit $A0
::3			sta	(r5L),y			;auffüllen.
			sta	(r8L),y
			iny
			inx
			cpx	#16
			bcc	:3
::4			rts

;*** Datei-Informationen aktualisieren.
;    Übergabe: r1L/r1H = Track/Sektor Verzeichnis-Eintrag.
;              r5      = Zeiger auf 30Byte-Verzeichnis-Eintrag.
;              curEntryVec = Zeiger auf 32Byte Original-Eintrag.
;              curDirEntry = Kopie Verzeichnis-Eintrag.
:updateDirEntry		lda	curFileVec +0		;Zeiger auf aktuellen
			clc				;Verzeichnis-Eintrag im Speicher.
			adc	#< $0002
			sta	r8L
			lda	curFileVec +1
			adc	#> $0002
			sta	r8H

			ldy	#0
			lda	curDirEntry +2,y	;Dateityp-Flag mit "Geschlossen" und
			sta	(r5L),y			;"Schreibschutz"-Status speichern.
			sta	(r8L),y

			ldy	#22			;GEOS-Dateityp speichern.
			lda	curDirEntry +2,y
			sta	(r5L),y

			bit	setDateTime		;Datum geändert ?
			bpl	:3			; => Nein, weiter...

			ldy	#23			;Datum und Uhrzeit speichern.
::1			lda	curDirEntry +2,y
			sta	(r5L),y
			sta	(r8L),y
			iny
			cpy	#27 +1
			bcc	:1
			bcs	:4

::2			ldy	#23			;Datum und Uhrzeit einlesen.
::3			lda	(r5L),y			;(Falls Datum im Cache veraltet!)
			sta	(r8L),y
			sta	curDirEntry +2,y
			iny
			cpy	#27 +1
			bcc	:3

::4			;LoadW	r4,diskBlkBuf		;r4 noch gesetzt
			jsr	PutBlock		;Verzechnis-Sektor speichern.
			txa				;Laufwerksfehler?
			beq	:exit			; => Nein, Ende...
			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;*** Verzeichnis-Header aktualisieren.
;    Übergabe: curDirEntry = Kopie Verzeichnis-Eintrag.
:updateDirHeader	ldx	#NO_ERROR
			lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			cmp	#DIR			;Verzeichnis?
			bne	:exit			; => Nein, Ende.

			lda	curDirEntry +3
			sta	r1L
			lda	curDirEntry +4
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Verzeichnis-Header einlesen.
			txa				;Fehler?
			bne	:diskError		; => Ja, Abbruch...

			ldx	#0
::3			lda	curFileName,x		;Dateiname=Diskname in
			beq	:4			;Verzeichnis-Header kopieren.
			sta	diskBlkBuf +4,x
			inx
			cpx	#16
			bcc	:3
			beq	:6
::4			lda	#$a0			;Auf 16 Zeichen mit $A0
::5			sta	diskBlkBuf +4,x		;auffüllen.
			inx
			cpx	#16
			bcc	:5

::6			;LoadW	r4,diskBlkBuf		;r4 noch gesetzt
			jsr	PutBlock		;Verzechnis-Sektor speichern.
			txa				;Laufwerksfehler?
			beq	:exit			; => Nein, Ende...
::diskError		jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;*** GEOS-InfoBlock aktualisieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
:updateGeosHeader	LoadW	r9,curDirEntry +2	;Zeiger auf Verzeichnis-Eintrag.
			jsr	GetFHdrInfo		;InfoBlock einlesen.
			txa				;Fehler?
			bne	:diskError		; => Ja, Abbruch...

			ldy	#$02			;InfoBlock aus Zwischenspeicher
::1			lda	curFHdrInfo,y		;In Sektor kopieren.
			sta	fileHeader,y
			iny
			bne	:1

			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
;			LoadW	r4,diskBlkBuf		;r4 noch gesetzt
			jsr	PutBlock		;Verzechnis-Sektor speichern.
			txa				;Laufwerksfehler?
			beq	:exit			; => Nein, Ende...
::diskError		jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;*** Seite wechseln.
:SwitchPage		php
			sei				;Interrupt sperren.

			bit	GD_INFO_SAVE
			bpl	:1

			lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			beq	:1			; => Gelöschte Datei, weiter...

			jsr	doSaveData

::1			sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#PosSlctPage_y		;"Eselsohrs" angeklickt wurde.
			bcs	:3
::2			plp				;Interrupt wieder freigeben.
			rts				;Nein, Rücksprung.

::3			tay
			sec
			lda	mouseXPos+0
			sbc	#< PosSlctPage_x
			tax
			lda	mouseXPos+1
			sbc	#> PosSlctPage_x
			bne	:2
			cpx	#16			;Ist Maus innerhalb "Eselsohr" ?
			bcs	:2			;Nein, Rücksprung.
			cpy	#16
			bcs	:2
			sty	r0L
			txa				;Feststellen: Seite vor/zurück ?
			eor	#%00001111
			cmp	r0L
			bcs	:11			;Seite vor.
			bcc	:21			;Seite zurück.

;*** Weiter auf nächste Seite.
::11			ldx	curFile
			inx
			cpx	slctFiles
			bcc	:31
			ldx	#$00
			beq	:31

;*** Zurück zur letzten Seite.
::21			ldx	curFile
			bne	:22
			ldx	slctFiles
::22			dex

::31			stx	curFile			;Dateiposition speichern.

			stx	r0L			;Zeiger auf Verzeichnis-Eintrag
			LoadB	r0H,0			;im Speicher berechnen.
			ldx	#r0L
			ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.
			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			lda	r0L
			clc
			adc	#< dirEntryData
			sta	curFileVec +0
			lda	r0H
			adc	#> dirEntryData
			sta	curFileVec +1

;			plp				;Interrupt wieder freigeben.
			bne	ResetFileInfoIRQ	;"IRQ sperren" überspringen.

;*** Datei-Informationen einlesen.
:ResetFileInfo		php
			sei				;Interrupt sperren.

:ResetFileInfoIRQ	jsr	GetFileData		;Datei-Info einlesen.
			jsr	chkDateAndTime		;Datum/Uhrzeit überprüfen.

;--- Hinweis:
;regUpdate ist nur notwendig wenn
;die InfoBox der letzte Eintrag in der
;Register-Tabelle ist.
;ToDo: Evtl. Fehler in Register-Code?
:UpdateRegData
;			LoadB	regUpdate,$ff
			jsr	RegisterNextOpt
;			ClrB	regUpdate

			plp				;Interrupt wieder freigeben.
			rts

;*** Dateiname auf Gültigkeit testen.
:chkFileName		bit	r1L			;RegisterKarte aufbauen?
			bpl	:exit			; => Ja, weiter...

			ldy	curFileName
			bne	:exit
::1			lda	bakFileName,y
			sta	curFileName,y
			iny
			cpy	#16
			bcc	:1

::exit			rts

;*** Datum und Uhrzeit auf Gültigkeit testen.
:chkDateAndTime		lda	curDirEntry +27		;Tag.
			bne	:1

;--- Fehlerhaftes Datum ersetzen.
::errDate		lda	#1
			sta	curDirEntry +27		;Tag.
			sta	curDirEntry +26		;Monat.
			lda	#80
			sta	curDirEntry +25		;Jahr.

;--- Fehlerhafte Uhrzeit ersetzen.
::errTime		lda	#00
			sta	curDirEntry +28		;Stunde.
			sta	curDirEntry +29		;Minute.
			rts

;--- Datum testen.
::1			cmp	#31 +1			;Tag =< 31?
			bcs	:errDate		; => Nein, Fehler...

			lda	curDirEntry +26		;Monat.
			beq	:errDate

			cmp	#12 +1			;Monat =< 12?
			bcs	:errDate		; => Nein, Fehler...

			lda	curDirEntry +25		;Jahr.
			beq	:errDate

			cmp	#99 +1			;Jahr =< 99?
			bcs	:errDate		; => Nein, Fehler...

;--- Uhrzeit testen.
::chkTime		lda	curDirEntry +28		;Stunde.
			cmp	#24			;Stunde >= 24?
			bcs	:errDate		; => Ja, Fehler...

			lda	curDirEntry +29		;Minute.
			cmp	#60			;Minute >= 60?
			bcs	:errDate		; => Ja, Fehler...

			rts

;*** Datum ändern.
:editDayUp		lda	#$01
			b $2c
:editDayDn		lda	#$ff
			clc
			adc	curDirEntry +27
			sta	curDirEntry +27

;*** Datum auf Gültigkeit testen.
:chkDateDay		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +27		;Tag einlesen.
			beq	:0a			; => Tag ungültig...

			cmp	#31 +1			;Tag > 31?
			beq	:1
			bcc	:2			; => Nein, weiter...

::0a			lda	#31			;max.Wert für Tag setzen.
			b $2c
::1			lda	#1			;min.Wert für Tag setzen.
			sta	curDirEntry +27		;Korrigierter Wert für Tag.
::2			rts

:editMonthUp		lda	#$01
			b $2c
:editMonthDn		lda	#$ff
			clc
			adc	curDirEntry +26
			sta	curDirEntry +26

:chkDateMonth		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +26		;Monat einlesen.
			beq	:0a			; => Monat ungültig...

			cmp	#12 +1			;Monat > 12?
			beq	:1
			bcc	:2			; => Nein, weiter...

::0a			lda	#12			;max.Wert für Monat setzen.
			b $2c
::1			lda	#1			;min.Wert für Monat setzen.
			sta	curDirEntry +26		;Korrigierter Wert für Monat.
::2			rts

:editYearUp		lda	#$01
			b $2c
:editYearDn		lda	#$ff
			clc
			adc	curDirEntry +25
			sta	curDirEntry +25

;*** Jahreszahl testen.
;Hinweis: Ist immer gültig.
;hier könnte aber das Jahrtausend
;für die Anzeige gesetzt werden.
:chkDateYear		rts

;*** Zeit ändern.
:editHourUp		lda	#$01
			b $2c
:editHourDn		lda	#$ff
			clc
			adc	curDirEntry +28
			sta	curDirEntry +28

;*** Uhrzeit auf Gültigkeit testen.
:chkDateHour		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +28		;Stunde einlesen.
			cmp	#23 +1			;Stunde > 23?
			beq	:1
			bcc	:2			; => Nein, weiter...

			lda	#23			;max.Wert für Stunde setzen.
			b $2c
::1			lda	#0
			sta	curDirEntry +28		;Korrigierter Wert für Stunde.

::2			rts

:editMinUp		lda	#$01
			b $2c
:editMinDn		lda	#$ff
			clc
			adc	curDirEntry +29
			sta	curDirEntry +29

:chkDateMinute		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +29		;Minute einlesen.
			cmp	#59 +1			;Minute > 59?
			beq	:1
			bcc	:2

			lda	#59			;max.Wert für Minute setzen.
			b $2c
::1			lda	#0
			sta	curDirEntry +29		;Korrigierter Wert für Minute.

::2			rts

;*** Aktuelles Datum auf Datei anwenden.
:SetCurDate		lda	day			;Datum übernehmen.
			sta	curDirEntry +27
			lda	month
			sta	curDirEntry +26
			lda	year
			sta	curDirEntry +25

			lda	#< RegTMenu1c		;Tag aktualisieren.
			ldx	#> RegTMenu1c
			jsr	updRegEntry
			lda	#< RegTMenu1d		;Monat aktualisieren.
			ldx	#> RegTMenu1d
			jsr	updRegEntry
			lda	#< RegTMenu1e		;Jahr aktualisieren.
			ldx	#> RegTMenu1e
;			jmp	updRegEntry

:updRegEntry		sta	r15L
			stx	r15H
			jmp	RegisterUpdate

;*** Aktuelle Uhrzeit auf Datei anwenden.
:SetCurTime		lda	hour			;Uhrzeit übernehmen.
			sta	curDirEntry +28
			lda	minutes
			sta	curDirEntry +29

			lda	#< RegTMenu1f		;Stunde aktualisieren.
			ldx	#> RegTMenu1f
			jsr	updRegEntry
			lda	#< RegTMenu1g		;Minute aktualisieren.
			ldx	#> RegTMenu1g
			jmp	updRegEntry

;*** Zeit für ausgwählte Dateien speichern.
:svTimeDiskFiles	ldy	#$ff			;Datum für alle Dateien auf Disk.
			b $2c
:svTimeAllFiles		ldy	#$00			;Datum für ausgewählte Dateien.
			sty	svTimeMode

			bit	GD_INFO_SAVE		;Automatisch speichern?
			bmi	:100			; => Ja, weiter...

			lda	#< Dlg_SetADate		;Datum für ausgewählte Dateien.
			ldx	#> Dlg_SetADate
			cpy	#$00
			beq	:99
			lda	#< Dlg_SetDDate		;Datum für alle Dateien auf Disk.
			ldx	#> Dlg_SetDDate
::99			sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Hinweistext ausgeben.

			lda	sysDBData
			cmp	#YES			;Datum aktualisieren?
			beq	:100			; => Ja, weiter...
			rts

::100			jsr	chkDateAndTime		;Datum/Uhrzeit überprüfen.

			bit	svTimeMode		;Alle Dateien auf Disk/Auswahl?
			bmi	:101			; => Alle Dateien auf Disk...

			jsr	doSelectedFiles		;Datum für ausgewählte Dateien.
			jmp	:102

::101			jsr	doAllFiles		;Datum für alle Dateien auf Disk.

::102			txa				;Laufwerksfehler?
			bne	:104			; => Ja, Abbruch...

			ldx	#$ff			;Dateien geändert, Verzeichnis
			stx	reloadDir		;in GeoDesk neu einlesen.
			inx
			stx	setDateTime

			lda	#< Dlg_UpdateDone
			sta	r0L
			lda	#> Dlg_UpdateDone
			sta	r0H
			jsr	DoDlgBox		;Hinweistext ausgeben.

::104			jmp	GetFileData		;Datei-Info einlesen.

;*** Datum für markierte Dateien übernehmen.
:doSelectedFiles	LoadW	r6,dirEntryData		;Zeiger auf Dateinamentabelle.

			ldy	#$00			;Dateizähler zurücksetzen.
::1			sty	r14H

;			MoveW	curFileVec,r6
			jsr	userFindFile		;Datei auf Disk suchen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::2			ldy	#23			;Datum in Datei-Eintrag kopieren.
::3			lda	curDirEntry +2,y
			sta	(r5L),y
			iny
			iny
			sta	(r6L),y
			dey
;			dey
;			iny
			cpy	#27 +1
			bcc	:3

			jsr	PutBlock		;Verzeichnis-Eintrag speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			AddVBW	32,r6			;Zeiger auf nächsten Dateinamen.

			ldy	r14H			;Dateizähler +1.
			iny
			cpy	slctFiles		;Alle Dateien bearbeitet?
			bcc	:1			; => Nein, weiter...
;			ldx	#NO_ERROR
			rts

;*** Datum für alle Dateien auf Disk übernehmen.
:doAllFiles		jsr	Get1stDirEntry		;Zeiger auf Anfang Verzeichnis.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...
			cpy	#$00			;Verzeichnis-Ende erreicht?
			beq	:1			; => Nein, weiter...
			cpy	#$ff
			beq	:doFilesRAM		; => Ja, Ende...
			ldx	#CANCEL_ERR
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::1			ldy	#$00
			lda	(r5L),y			;Dateieintrag gültig?
			beq	:3			; => Nein, überspringen.
							;Hinweis: Datum wird damit nicht
							;für gelöschte Dateien gesetzt.

			ldy	#23			;Datum in Datei-Eintrag kopieren.
::2			lda	curDirEntry +2,y
			sta	(r5L),y
			iny
			cpy	#27 +1
			bcc	:2

::3			lda	r5L			;Letzter Eintrag im Sektor
			cmp	#$e0			;bearbeitet ($E0=LB 8ter Eintrag)?
			bcs	:4			; => Ja, weiter...

			AddVBW	32,r5			;Zeiger auf nächsten Eintrag.
			jmp	:1			;Nächsten Eintrag bearbeiten.

::4			jsr	PutBlock		;Verzeichnis-Sektor speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	GetNxtDirEntry		;Zeiger nächste Verzeichnis-Sektor.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch.
			tya				;Verzeichnis-Ende erreicht?
			beq	:1			; => Nein, weiter...

;*** Zusätzlich Datum für markierte Dateien im RAM übernehmen.
::doFilesRAM		LoadW	r6,dirEntryData		;Zeiger auf Dateinamentabelle.

			ldy	#$00			;Dateizähler zurücksetzen.
::11			sty	r14H

			ldy	#25			;Datum in Datei-Eintrag kopieren.
::12			lda	curDirEntry,y
			sta	(r6L),y
			iny
			cpy	#29 +1
			bcc	:12

			AddVBW	32,r6			;Zeiger auf nächste Datei.

			ldy	r14H			;Dateizähler +1.
			iny
			cpy	slctFiles		;Alle Dateien bearbeitet?
			bcc	:11			; => Nein, weiter...
;			ldx	#NO_ERROR
			rts

;*** Texteingabe für InfoText beenden.
:InitRegTab		bit	r1L			;RegisterKarte aufbauen?
			bmi	:exit			; => Nein, Ende...
			jsr	StopTextEdit		;Texteingabe beenden.
::exit			rts

;*** Infotext eingeben
:DefInfoText
;			bit	regUpdate		;RegisterKarte zurücksetzen?
;			bmi	StopTextEdit		; => Ja, Texteingabe beenden...

			bit	curFileGEOS		;GEOS-Datei?
			bpl	StopTextEdit		; => Nein, Texteingabe beenden...

			LoadW	r0,curFHdrInfo +160
			jsr	InputText		;Texteingabe-Routine starten.
			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** Texteingabe abschließen.
:StopTextEdit		jsr	InitForIO		;I/O-Bereich einblenden.
			lda	C_Mouse			;Farbe für Cursor zurücksetzen.
			sta	$d027
			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	PromptOff		;Cursor abschalten.

			lda	#$00			;Tastenabfrage löschen.
			sta	keyVector +0
			sta	keyVector +1

			lda	alphaFlag		;Cursor ausblenden.
			and	#%01111111
			sta	alphaFlag

::exit			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** InfoText löschen.
:ClrInfoText		ldy	#$a0			;Zeiger auf erstes Zeichen InfoText.
			lda	#$00			;InfoText löschen.
::1			sta	curFHdrInfo,y
			iny
			bne	:1
			rts

;*** InfoBlock-Icon ausgeben.
:DefInfoIcon		lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			cmp	#DIR			;Verzeichnis?
			bne	:1			; => Nein, weiter...

			ldx	#< Icon_Map		;Zeiger auf Verzeichnis-Icon.
			ldy	#> Icon_Map
			jsr	drawIcon		;Icon ausgeben.

			ldx	#< textDIR		;"DIR" als Icon-Kennung ausgeben.
			ldy	#> textDIR
			lda	#11
			bne	prntIconText

::1			bit	curFileGEOS		;GEOS-Datei?
			bpl	:2			; => Nein, weiter...

			ldx	#< curFHdrInfo +4	;Zeiger auf InfoBlock-Icon.
			ldy	#> curFHdrInfo +4
			jsr	drawIcon		;Icon ausgeben.

			ldx	#< textGEOS		;"GEOS" als Icon-Kennung ausgeben.
			ldy	#> textGEOS
			lda	#8
			bne	prntIconText

::2			ldx	#< Icon_CBM		;Zeiger auf CBM-Icon.
			ldy	#> Icon_CBM
			jsr	drawIcon		;Icon ausgeben.

			ldx	#< textCBM		;"CBM" als Icon-Kennung ausgeben.
			ldy	#> textCBM
			lda	#10
;			bne	prntIconText

;*** Icon-Typ ausgeben.
:prntIconText		stx	r0L			;Zeiger auf Text setzen.
			sty	r0H

;			lda	#y			;X-Koordinate korrigieren.
			clc
			adc	r11L
			sta	r11L
			bcc	:1
			inc	r11H

::1			lda	r1H			;Y-Koordinate korrigieren.
			sec
			sbc	#3
			sta	r1H

			jmp	PutString		;Icon-Typ ausgeben.

;*** Datei-Icon ausgeben.
:drawIcon		stx	r0L			;Zeiger auf Bitmap-Daten speichern.
			sty	r0H

			PushB	r2H			;Register zwischenspeichern.
			PushW	r3

			ldx	#r3L			;X-Koordinate in CARDs umrechnen.
			ldy	#3
			jsr	DShiftRight

			lda	r3L			;Größe für Icon-Leinwand
			clc				;berechnen.
			adc	#$01
			sta	r1L
			lda	r2L
			clc
			adc	#$08
			sta	r1H
			lda	#3
			sta	r2L
			lda	#21
			sta	r2H
			jsr	BitmapUp		;Bitmap darstellen.

			PopW	r11			;Register zurücksetzen als
			PopB	r1H			;Position für Icon-Kennung.

::exit			rts

;*** Neuen Dateityp setzen.
:setCBMFType		lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#%11111000
			sta	r0L
			lda	curDirEntry +2
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			clc
			adc	#$01			;Dateityp wechseln.
			and	#ST_FMODES		;Dateityp auf $x0-$x7 begrenzen.
			ora	r0L
			sta	curDirEntry +2		;Neuen CBM-Dateityp speichern.
			jsr	getCBMFType

			lda	#< RegTMenu1b		;Dateityp-Option aktualisieren.
			ldx	#> RegTMenu1b
			jmp	updRegEntry

;*** CBM-Dateityp definieren.
:getCBMFType		lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			asl				;Zeiger auf Text für Dateityp
			asl				;berechnen.
			tax
			ldy	#$00
::3			lda	cbmFType,x		;CBM-Dateityp als Text in
			sta	curFileType,y		;Zwischenspeicher kopieren.
			inx
			iny
			cpy	#3
			bcc	:3
			rts

;*** Neuen Bildschirm-Modus setzen.
;Dabei wird zwischen folgenden Werten
;gewechselt:
; $00 = Nur 40 Zeichen.
; $20 = Nur Wheels128 40-Zeichen (Nicht änderbar).
; $40 = 40- und 80-Zeichen.
; $60 = Nur Wheels128 (Nicht änderbar).
; $80 = Nur GEOS64.
; $c0 = Nur GEOS 128 80 Zeichen.
:SetScrnMode		lda	curFHdrInfo +96		;Bildschirm-Modus einlesen.
			tax

			and	#%00111111		;Wheels/Unbekannt?
			bne	DefScrnMode		; => Ja, nicht ändern...

			txa				;Nur 40Zeichen (Standard)?
			bne	:1			; => Nein, weiter...
			ldx	#%01000000		;Neuer Modus: "40- und 80-Zeichen".
			bne	:set_new_mode

::1			cpx	#%01000000
			bne	:2
			ldx	#%10000000		;Neuer Modus: "Nur GEOS64".
			bne	:set_new_mode

::2			cpx	#%10000000
			bne	:3
			ldx	#%11000000		;Neuer Modus: "Nur 80-Zeichen".
			bne	:set_new_mode

::3			ldx	#%00000000		;Neuer Modus: "Nur 40-Zeichen".

::set_new_mode		stx	curFHdrInfo +96		;Neuen Modus speichern.

;*** Text für Bildschirm-Modus für Registerenü erzeugen.
:DefScrnMode		ldy	#BOX_ICON
			ldx	curFHdrInfo +96		;Bildschirm-Modus einlesen.
			txa
			and	#%00111111		;Wheels/Unbekannt?
			beq	:1			; => Ja, nicht ändern...
			ldy	#BOX_ICON_VIEW
			and	#%00011111
			beq	:1
			ldx	#%11100000
::1			sty	RegTMenu2f
			txa
			jsr	GetScreenMode		;Zeiger auf Text setzen.
			sta	r0L			;Zeiger zwischenspeichern.
			sty	r0H

			LoadW	r1,curScrnMode		;Zeiger auf Zwischenspeicher.

			ldx	#r0L			;Textstring für Bildschirm-Modus in
			ldy	#r1L			;Zwischenspeicher kopieren.
			jmp	CopyString

;*** Zeiger auf GEOS-Bildschirm-Modus.
;Übergabe: AKKU = Bildschirm-Modus.
;Rückgabe: XREG/YREG = Zeiger auf Text für Bildschirm-Modus.
:GetScreenMode		lsr
			lsr
			lsr
			lsr
;			lsr
;			asl
			tax
			lda	:tab +0,x
			ldy	:tab +1,x
			rts

;*** Text für Bildschirm-Modus.
::tab			w :40    ;Bit%000
			w :20    ;Bit%001
			w :40_80 ;Bit%010
			w :60    ;Bit%011
			w :64    ;Bit%100
			w :00    ;Bit%101
			w :80    ;Bit%110
			w :00    ;Bit%111

if LANG = LANG_DE
::00			b "Unbekannt",NULL
::20			b "Wheels128/40",NULL
::40			b "40 Zeichen",NULL
::60			b "Wheels128",NULL
::40_80			b "40 / 80 Zeichen",NULL
::64			b "GEOS 64",NULL
::80			b "80 Zeichen",NULL
endif
if LANG = LANG_EN
::00			b "Unknown",NULL
::20			b "Wheels128/40",NULL
::40			b "40 columns",NULL
::60			b "Wheels128",NULL
::40_80			b "40 / 80 columns",NULL
::64			b "GEOS 64",NULL
::80			b "80 columns",NULL
endif

;*** Neuen GEOS-Dateityp setzen.
:SetGEOSType		bit	curFileGEOS		;GEOS-Datei?
			bmi	:geos			; => Ja, weiter...
			rts

::geos			ldx	curDirEntry +24		;GEOS-Dateityp einlesen.
			inx
			cpx	#15			;Unbekannter Typ?
			bcc	:1			; => Nein, weiter...
			ldx	#0			;Typ "Unknown" setzen.
::1			stx	curDirEntry +24		;GEOS-Dateityp speichern und
			stx	curFHdrInfo +69		;auch im InfoBlock anpassen.

;*** Text für GEOS-Dateityp für Registerenü erzeugen.
:DefGEOSType		LoadW	r15,curDirEntry		;Zeiger auf Text für
			jsr	GetGeosType		;GEOS-Dateityp einlesen.
			sta	r0L			;Zeiger zwischenspeichern.
			sty	r0H

			LoadW	r1,curGEOSType		;Zeiger auf Zwischenspeicher.

			ldx	#r0L			;Textstring für Bildschirm-Modus in
			ldy	#r1L			;Zwischenspeicher kopieren.
			jmp	CopyString

;*** GEOS-Klasse/Version testen.
:ChkGEOSClass		LoadW	r0,curClass
			LoadW	r1,curFHdrInfo +77
			lda	#" "
			ldx	#12
			bne	chkStrData

:ChkGEOSVersion		LoadW	r0,curClassVer
			LoadW	r1,curFHdrInfo +77 +12
			lda	#$00
			ldx	#6

:chkStrData		sta	r2L			;Füllzeichen speichern.
			ldy	#$00
::1			lda	(r0L),y			;Zeichen aus String einlesen.
			beq	:2			; => Ende erreicht.
			sta	(r1L),y			;In GEOS-Header kopieren.
			iny				;Zeiger auf nächstes Zeichen.
			dex				;Alle Zeichen geprüft?
			bne	:1			; => Nein, weiter...
			beq	:4			; => Ja, Ende...
::2			lda	r2L			;Füllzeichen einlesen.
::3			sta	(r0L),y			;String bis zur max.Länge auffüllen.
			sta	(r1L),y			;GEOS-Header anpassen.
			iny
			dex
			bne	:3
::4			rts

;*** GEOS-Autor übernehmen.
;Wenn bei einem PhotoScrap der Autor
;ungültig ist, dann wird der Name nicht
;automatisch im InfoBlock gelöscht.
;Nur wenn der Autor geändert wird, dann
;den neuen Namen in den GEOS-InfoBlock
;übernehmen.
:SetGEOSAuthor		bit	r1L			;RegisterKarte aufbauen?
			bpl	:exit			; => Ja, Ende...

			ldy	#0
::1			lda	curAuthor,y
			beq	:2
			sta	curFHdrInfo +$61,y
			iny
			cpy	#19
			bcc	:1

			lda	#NULL
::2			sta	curFHdrInfo +$61,y
			iny
			cpy	#20
			bcc	:2

::exit			rts

;*** GEOS-Autor testen.
;Ein PhotoScrap kann einen ungültigen
;GEOS-Autor beinhalten. Daher hier auf
;gültige Zeichen testen und ggf. den
;Autor löschen.
:DefGEOSAuthor		ldy	#0
::1			lda	curAuthor,y
			beq	:ok
			cmp	#$20
			bcc	:skip
			cmp	#$7f
			bcs	:skip
			iny
			cpy	#19
			bcc	:1
::ok			rts

::skip			lda	#NULL
			sta	curAuthor
			rts

;*** Author für ausgwählte Dateien speichern.
:svAuthorAllFiles	ldy	#$00			;Datum für ausgewählte Dateien.
			sty	svTimeMode

			bit	GD_INFO_SAVE		;Automatisch speichern?
			bmi	:100			; => Ja, weiter...

			lda	#< Dlg_SetAuthor	;Autor für ausgewählte Dateien.
			ldx	#> Dlg_SetAuthor
			sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Hinweistext ausgeben.

			lda	sysDBData
			cmp	#YES			;Datum aktualisieren?
			beq	:100			; => Ja, weiter...
			rts

::100			jsr	doAuthorAllFiles	;Datum für ausgewählte Dateien.
			txa				;Laufwerksfehler?
			bne	:101			; => Ja, Abbruch...

			ldx	#$ff			;Dateien geändert, Verzeichnis
			stx	reloadDir		;in GeoDesk neu einlesen.

			lda	#< Dlg_UpdateDone
			sta	r0L
			lda	#> Dlg_UpdateDone
			sta	r0H
			jsr	DoDlgBox		;Hinweistext ausgeben.

::101			jmp	GetFileData		;Datei-Info einlesen.

;*** Autor für markierte Dateien übernehmen.
:doAuthorAllFiles	LoadW	r6,dirEntryData		;Zeiger auf Dateinamentabelle.

			ldy	#$00			;Dateizähler zurücksetzen.
::1			sty	r14H

;			MoveW	curFileVec,r6
			jsr	userFindFile		;Datei auf Disk suchen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::2			ldy	#22
			lda	(r5L),y			;GEOS-Datei?
			beq	:next			; => Nein, weiter...

			ldy	#19			;Zeiger auf Infoblock
::3			lda	(r5L),y			;einlesen.
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			beq	:next			; => Kein Infoblock, weiter...

			lda	#< fileHeader
			sta	r4L
			lda	#> fileHeader
			sta	r4H
			jsr	GetBlock		;Infoblock einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#0
::4			lda	curAuthor,y
			beq	:5
			sta	fileHeader  +$61,y
			sta	curFHdrInfo +$61,y
			iny
			cpy	#19
			bcc	:4

			lda	#NULL
::5			sta	fileHeader  +$61,y
			sta	curFHdrInfo +$61,y
			iny
			cpy	#20
			bcc	:5

			jsr	PutBlock		;Verzeichnis-Eintrag speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::next			AddVBW	32,r6			;Zeiger auf nächsten Dateinamen.

			ldy	r14H			;Dateizähler +1.
			iny
			cpy	slctFiles		;Alle Dateien bearbeitet?
			bcc	:1			; => Nein, weiter...
;			ldx	#NO_ERROR
			rts

;*** GEOS-Adressen einlesen.
:DefGEOSload		ldx	#0			;Ladeadresse.
			lda	#< curAdrGEOSload
			ldy	#> curAdrGEOSload
			bne	DefGEOSadr

:DefGEOSend		ldx	#2			;Endadresse.
			lda	#< curAdrGEOSend
			ldy	#> curAdrGEOSend
			bne	DefGEOSadr

:DefGEOSrun		ldx	#4			;Startadresse.
			lda	#< curAdrGEOSrun
			ldy	#> curAdrGEOSrun

:DefGEOSadr		sta	r1L
			sty	r1H

			lda	curFHdrInfo +$47,x
			sta	r0L
			lda	curFHdrInfo +$48,x
			sta	r0H

;			jmp	HEXW2ASCII

;*** HEX-WORD nach ASCII konvertieren.
;    Übergabe: r0 = Hex-Zahl als WORD.
;    Rückgabe: r1 = 4 ASCII-zeichen für Hex-Zahl/WORD.
::HEXW2ASCII		lda	r0L			;LOW-Byte zwischenspeichern.
			pha

			lda	r0H			;HIGH-Byte einlesen und
			jsr	HEX2ASCII		;nach ASCII wandeln.

			ldy	#$01
			sta	(r1L),y			;LOW-Nibble HIGH-Byte.
			dey
			txa
			sta	(r1L),y			;HIGH-Nibble HIGH-Byte.

			pla				;LOW-Byte einlesen und
			jsr	HEX2ASCII		;nach ASCII wandeln.

			ldy	#$03
			sta	(r1L),y			;LOW-Nibble LOW-Byte.
			dey
			txa
			sta	(r1L),y			;HIGH-Nibble LOW-Byte.
			rts

;*** InfoText in Zwischenspeicher #1-#3 kopieren.
:doSaveBuf1		lda	#< bufInfoText1		;Adresse Zwischenspeicher #1.
			ldx	#> bufInfoText1
			bne	doSaveBuf

:doSaveBuf2		lda	#< bufInfoText2		;Adresse Zwischenspeicher #2.
			ldx	#> bufInfoText2
			bne	doSaveBuf

:doSaveBuf3		lda	#< bufInfoText3		;Adresse Zwischenspeicher #3.
			ldx	#> bufInfoText3

:doSaveBuf		bit	curFileGEOS		;GEOS-Datei?
			bpl	:exit			; => Nein, Ende...

			sta	r1L			;Zeiger auf Zwischenspeicher
			stx	r1H			;sichern.

			LoadW	r0,curFHdrInfo +160
			jmp	CopyInfoText		;InfoText in Zwischenspeicher.
::exit			rts

;*** InfoText aus Zwischenspeicher #1-#3 einlesen.
:doLoadBuf1		lda	#< bufInfoText1		;Adresse Zwischenspeicher #1.
			ldx	#> bufInfoText1
			bne	doLoadBuf

:doLoadBuf2		lda	#< bufInfoText2		;Adresse Zwischenspeicher #2.
			ldx	#> bufInfoText2
			bne	doLoadBuf

:doLoadBuf3		lda	#< bufInfoText3		;Adresse Zwischenspeicher #3.
			ldx	#> bufInfoText3

:doLoadBuf		bit	curFileGEOS		;GEOS-Datei?
			bpl	:exit			; => Nein, Ende...

			sta	r0L			;Zeiger auf Zwischenspeicher
			stx	r0H			;sichern.

			LoadW	r1,curFHdrInfo +160
			jmp	CopyInfoText		;InfoText aus Zwischenspeicher.
::exit			rts

;*** InfoText von/nach InfoBlock kopieren.
:CopyInfoText		ldy	#$00
::1			lda	(r0L),y			;Zeichen einlesen.
			beq	:2			; => Ende...
			sta	(r1L),y
			iny
			cpy	#95
			bcc	:1

::2			lda	#$00			;Rest von InfoText löschen.
::3			sta	(r1L),y
			iny
			cpy	#96
			bcc	:3

			lda	#< RegTMenu3b
			ldx	#> RegTMenu3b
			jmp	updRegEntry		;InfoText-Option aktualisieren.

;
; Text-Eingaberoutine.
;
;BoxLeft		= 80				;Grenzen für Infoblock-Fenster.
;BoxRight		= 240
;BoxTop			= 100
;BoxBottom		= 144
;MaxText		= 96
;
;			LoadW	r0,iText		;Textspeicher.
;			LoadB	r2L,BoxTop		;Oben.
;			LoadB	r2H,BoxBottom		;Unten.
;			LoadW	r3,BoxLeft		;Links.
;			LoadW	r4,BoxRight		;Rechts.
;			jsr	InputText
;			rts
;
;Nach der Eingabe folgende Vektoren zurücksetzen:
;
; :keyVector			= $0000
; :alphaFlag			= %0xxxxxxx
;
;Cursor abschalten mit:
;
;			jsr	PromptOff
;
;

:spr1clr		= $d028
:MaxText		= 96 -1

;*** INPUT-Routine aktivieren.
:InputText		lda	r0L
			pha
			sta	SetTextAdr+1
			lda	r0H
			pha
			sta	SetTextAdr+5

			ldx	r2L			;Obere Grenze Eingabefeld.
			inx
			stx	BoxRange+0

			ldx	r2H			;Untere Grenze Eingabefeld.
			dex
			stx	BoxRange+1

			lda	r3L			;Linke Grenze Eingabefeld.
			clc
			adc	#3
			sta	BoxRange+2

			lda	r4L			;Rechte Grenze Eingabefeld.
			sec
			sbc	#3
			sta	BoxRange+3

;*** Vorgabetext definieren.
			jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			pla
			sta	r0H
			pla
			sta	r0L

			lda	#$00			;Länge des Vorgabetextes im
::1			sta	:2 +1
			tay
			lda	(r0L),y			;Textspeicher ermitteln.
			beq	:3

			ldy	#$00
			cmp	#$20
			bcc	:2
			ldx	currentMode
			jsr	GetRealSize
			dey

::2			ldx	#$ff
			tya
			sta	KeyWidthTab,x

			inx
			txa
			cmp	#MaxText
			bcc	:1
			tay

::3			sty	maxChars

			lda	#$00			;Rest des Textspeichers löschen.
::4			sta	(r0L),y
			sta	KeyWidthTab,y
			iny
			cpy	#MaxText+1
			bcc	:4

;*** Eingabe fortsetzen.
			lda	#8
			jsr	InitTextPrompt

			lda	#< PruefeTaste		;Tastaturabfrage installieren.
			sta	keyVector  +0
			lda	#> PruefeTaste
			sta	keyVector  +1

			lda	alphaFlag		;Cursor einschalten.
			ora	#%10000000
			sta	alphaFlag
			jsr	PromptOn
			cli

			jsr	InitForIO		;I/O-Bereich einblenden.
			ClrB	spr1clr			;Cursor-Farbe "BLAU".
			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	Home

;*** Ganzen Text ausgeben.
:PrintText		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			ldx	BoxRange+0
			stx	r2L
			ldx	BoxRange+1
			stx	r2H
			ldx	BoxRange+2
			dex
			dex
			stx	r3L
			ldx	BoxRange+3
			inx
			inx
			stx	r4L

			lda	#0
			sta	r3H
			sta	r4H

			jsr	SetPattern
			jsr	Rectangle

;*** Text ausgeben.
			jsr	SetTextAdr

			ldx	#$01
::1			stx	a3L
			stx	a1L

			jsr	GetLineLength
			jsr	SetLowXPos

			ldy	a0L
::2			lda	(r0L),y
			beq	:5
			cmp	#$0d
			beq	:4
			jsr	SmallPutChar
::3			inc	a0L
			ldy	a0L
			cpy	a0H
			bne	:2

::4			ldx	a3L
			inx

			lda	r1H
			clc
			adc	#10
			cmp	BoxRange+1
			bcc	:1

::5			jsr	FindCursor

			jmp	RegisterSetFont

;*** Textadresse setzen.
:SetTextAdr		lda	#$ff			;Werte werden berechnet!
			sta	r0L
			lda	#$ff
			sta	r0H
			rts

;*** Eine Zeile tiefer.
:Add10YPos		AddVB	10,r1H
			rts

;*** Cursor an den linken Rand.
:SetLowXPos		lda	BoxRange+2
			sta	r11L
			LoadB	r11H,NULL
			rts

;*** Cursor an den oberen Rand.
:SetLowYPos		lda	BoxRange+0
			clc
			adc	#8
			sta	r1H
			rts

;*** Länge der aktuellen Zeile berechnen.
:GetLineLength		lda	r0L
			sta	:2 +3
			lda	r0H
			sta	:2 +4

			jsr	SetLowYPos

			ldy	#$00

::1			sty	a0L
			ldx	BoxRange+2
			lda	#$00
			sta	a0H
			sta	a9L			;Länge der aktuellen Zeile = 0.
			sta	a9H			;Länge der aktuellen Zeile = 0.

::2			inc	a9L			;Anzahl Zeichen in Zeile +1.

			lda	$ffff,y			;Zeichen aus Speicher einlesen.
			bne	:2a			;$00-Byte ? Ja, Text-Ende.
			LoadB	a1L,$01			;Zähler für Zeilen auf 0.
			jmp	:3a

::2a			cmp	#$0d			;RETURN ?
			beq	:3a			;Nein, weiter...

			cmp	#$20			;Leerzeichen ?
			bne	:3			;Nein, weiter...

			MoveB	a9L,a9H			;Max. Zeilenlänge bis Leerzeichen
							;begrenzen.

::3			txa				;Zeichenbreite addieren.
			adc	KeyWidthTab,y
			tax
			iny
			cpx	BoxRange+3		;Rechter Rand erreicht ?
			bcc	:2			;Nein, weiter...

			dec	a9L			;Zeilenlänge -1 (Letztes Zeichen ist
							;sonst außerhalb Textfenster!)

			ldx	a9H
			beq	:3a
			cpx	a9L
			bcs	:3a
			stx	a9L 			;Zeile zu lang.
							;Max. Zeilenlänge auf letztes
							;Leerzeichen begrenzen.

::3a			lda	a9L			;Zeilenlänge berechnen.
			clc
			adc	a0L
			sta	a0H

			dec	a1L			;Noch eine Zeile testen ?
			beq	:6			;Nein, Ende...

			jsr	Add10YPos

			ldy	a0H
			jmp	:1

::6			rts

;*** Tastatur-Abfrage.
:PruefeTaste		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT
			jsr	TestTaste
			jmp	RegisterSetFont

:TestTaste		lda	keyData
			cmp	#$1e			;Cursor um 1 Zeichen nach rechts.
			beq	iRight
			cmp	#$08			;Cursor um 1 Zeichen nach links.
			beq	iLeft
			cmp	#$11			;Cursor eine Zeile tiefer.
			beq	iDown
			cmp	#$10			;Cursor eine Zeile höher.
			beq	iUp
			cmp	#$1d			;Zeichen links vom Cursor löschen.
			beq	iDeleteKey
			cmp	#$12			;Cursor in "Home"-Position.
			beq	iHome
			cmp	#$13			;Text löschen.
			beq	iClrHome

			ldx	stringY
			cpx	BoxRange+1		;Schlußzeile erreicht ?
			bcs	:1			;Ja, keine weitere Eingabe.

			cmp	#$0d			;Cursor zum Anfang der nächsten Zeile.
			beq	iReturnKey
			cmp	#$1c			;Leerzeichen einfügen.
			beq	iInsSpace

			cmp	#$20
			bcc	:1
			cmp	#$7f
			bcc	iInsertKey
::1			rts

:iRight			jmp	Right
:iLeft			jmp	Left
:iDown			jmp	Down
:iUp			jmp	Up
:iInsertKey		jmp	InsertKey
:iDeleteKey		jmp	DelLastChar
:iReturnKey		jmp	ReturnKey
:iInsSpace		jmp	Insert
:iHome			jmp	Home
:iClrHome		jmp	Clear

;*** Cursor suchen.
:FindCursor		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			jsr	SetTextAdr

			ldx	#$01
::1			stx	a3L
			stx	a1L
			jsr	GetLineLength
			jsr	SetLowXPos
			jmp	:4

::2			lda	(r0L),y
			beq	:6
			inc	a0L
			cmp	#$0d
			bne	:3
			jsr	SetLowXPos
			jsr	Add10YPos
			jmp	:4

::3			ldx	KeyWidthTab,y
			inx
			txa
			clc
			adc	r11L
			sta	r11L
			bcc	:4
			inc	r11H

::4			ldy	a0L
			cpy	curChar
			beq	:6

			cpy	a0H
			bne	:2

::5			ldx	a3L
			inx
			cpx	#$05
			bne	:1

			jsr	SetLowXPos
			jsr	Add10YPos

::6			jmp	SetCursor

;*** Cursor suchen.
:FindXYpos		jsr	UseSystemFont
			LoadB	currentMode,SET_PLAINTEXT

			jsr	SetTextAdr

			ldx	#$01
::1			stx	a3L
			stx	a1L
			jsr	GetLineLength
			jsr	SetLowXPos
			jmp	:3

::2			lda	(r0L),y
			beq	SetCursor
			inc	a0L
			cmp	#$0d
			beq	:3

			ldx	KeyWidthTab,y
			inx
			txa
			clc
			adc	r11L
			sta	r11L
			bcc	:3
			inc	r11H

::3			ldy	a0L
			cpy	maxChars
			beq	:4

			lda	r1H
			sec
			sbc	baselineOffset
			cmp	stringY
			bne	:5

			lda	r11L
			cmp	stringX
			bcs	:4
			cpy	a0H
			bcc	:2

::4			sty	curChar
			jmp	SetCursor

::5			cpy	a0H
			bne	:2

			ldx	a3L
			inx
			cpx	#$05
			bne	:1

			jsr	SetLowXPos
			jsr	Add10YPos

:SetCursor		MoveW	r11,stringX
			lda	r1H
			sec
			sbc	baselineOffset
			sta	stringY
			jmp	PromptOn

;*** "CURSOR RIGHT"
:Right			ldy	curChar
			cpy	maxChars
			bne	:1
			rts

::1			iny
			jmp	SetNewXPos

;*** "CURSOR LEFT"
:Left			ldy	curChar
			bne	:1
			rts

::1			dey

;*** Cursor auf neue X/Y-Position.
:SetNewXPos		sty	curChar
			jmp	FindCursor

;*** "CURSOR Down"
:Down			lda	stringY
			cmp	BoxRange+1
			bcc	:1
			rts

::1			clc
			adc	#10
			jmp	SetNewYPos

;*** "CURSOR UP"
:Up			lda	stringY
			sec
			sbc	#10
			cmp	BoxRange+0
			bcs	SetNewYPos
			rts

;*** Neue Y-Koordinate setzen.
:SetNewYPos		sta	stringY
			jmp	FindXYpos

;*** "RETURN" auswerten.
:ReturnKey		lda	#$0d

;*** Zeichen einfügen.
:InsertKey		jsr	AddKey
			jmp	Right

;*** Leerzeichen einfügen.
:Insert			lda	#" "

;*** Zeichen anfügen.
:AddKey			ldy	curChar
			cpy	#95
			bne	:1
			rts

::1			jsr	InsertChar
			jmp	PrintText

;*** Letztes Zeichen löschen.
:DelLastChar		ldy	curChar
			bne	:1
			rts

::1			jsr	DeleteChar
			jmp	PrintText

;*** Eingegebenen Text löschen.
:Clear			jsr	SetTextAdr

			lda	#$00
			sta	maxChars
			tay
::1			sta	(r0L),y
			sta	KeyWidthTab,y
			iny
			cpy	#MaxText+1
			bcc	:1

			jsr	PrintText

;*** Cursor in "Home"-Position.
:Home			LoadB	curChar,NULL
			jsr	FindCursor
			jmp	PromptOn

;*** Zeichen in Eingabetext einfügen.
:InsertChar		tax
			ldy	#MaxText
			cpy	curChar
			bne	:1
			rts

::1			jsr	SetTextAdr

::2			dey
			lda	(r0L),y
			pha
			lda	KeyWidthTab,y
			iny
			sta	KeyWidthTab,y
			pla
			sta	(r0L),y
			dey
			cpy	curChar
			bne	:2
			txa
			sta	(r0L),y

			ldx	currentMode
			ldy	#$00
			cmp	#$20
			bcc	:3
			jsr	GetRealSize
			dey
::3			tya
			ldy	curChar
			sta	KeyWidthTab,y

			ldy	#MaxText
			lda	#$00
			sta	(r0L),y
			cpy	maxChars
			beq	:4
			inc	maxChars
::4			rts

;*** Zeichen aus Text löschen.
:DeleteChar		ldy	curChar
			bne	:1
			rts

::1			dey
			sty	curChar

			jsr	SetTextAdr

::2			iny
			lda	(r0L),y
			pha
			lda	KeyWidthTab,y
			dey
			sta	KeyWidthTab,y
			pla
			sta	(r0L),y
			iny
			cpy	maxChars
			bne	:2

			dec	maxChars

			rts

;*** Variablen für Text-Eingabe.
:BoxRange		s $04
:KeyWidthTab		s 96
:maxChars		b $00
:curChar		b $00

;*** Zwischenspeicher.
:curFHdrInfo_S		= 256
:curFHdrInfo		= BASE_EXTDATA

:bufInfoText_S		= 96
:bufInfoText1		= BASE_EXTDATA + curFHdrInfo_S
:bufInfoText2		= bufInfoText1 + bufInfoText_S
:bufInfoText3		= bufInfoText2 + bufInfoText_S
:bufVarData		= bufInfoText3 + bufInfoText_S

;*** Variablen.
:renameFile		= bufVarData     +0		;$FF = Datei umbenennen.
;regUpdate		= renameFile     +1		;Register-Karte aktualisieren.
:svTimeMode		= renameFile     +1		;$00=Auswahl/$FF=Verzeichnis.
:slctFiles		= svTimeMode     +1		;Anzahl ausgewählte Dateien.
:setDateTime		= slctFiles      +1
:saveSearchFlg		= setDateTime    +1

;*** Aktuelle Datei.
:curFile		= saveSearchFlg  +1		;Nummer aktuelle Datei.
:curFileVec		= curFile        +1		;Zeiger auf aktuelle Datei.
:testFileName		= curFileVec     +2
:bakFileName		= testFileName   +17

;*** Zwischenspeicher für RegisterMenü.
:FILE_VAR_START		= bakFileName    +17
:curDirEntry		= FILE_VAR_START		;Verzeichnis-Eintrag.
:curFileGEOS		= curDirEntry    +32		;$FF = GEOS-Datei.
:curFileBadHdr		= curFileGEOS    +1		;$FF = Header beschädigt.
:curFileName		= curFileBadHdr  +1		;Dateiname.
:curFileType		= curFileName    +17		;CBM-Dateityp.
:curGEOSType		= curFileType    +4		;GEOS-Dateityp.
:curScrnMode		= curGEOSType    +24		;GEOS-Bildschirm-Modus.
:curClass		= curScrnMode    +20		;GEOS-Klasse.
:curClassVer		= curClass       +13		;GEOS-Klasse/Version.
:curAuthor		= curClassVer    +7		;GEOS-Autor.
:curAdrGEOSload		= curAuthor      +20		;GEOS-Ladeadresse.
:curAdrGEOSend		= curAdrGEOSload +5		;GEOS-Endadresse.
:curAdrGEOSrun		= curAdrGEOSend  +5		;GEOS-Startadresse.
:FILE_VAR_END		= curAdrGEOSrun  +5

;*** Text für Datei-Modus.
:textCBM		b "CBM",NULL
:textGEOS		b "GEOS",NULL
:textDIR		b "DIR",NULL

;*** Texte für GEOS-Dateistruktur.
:fileStructSEQ		b "SEQ",NULL
:fileStructVLIR		b "VLIR",NULL

;*** Kennung für GEOS-Dateiheader.
:headerCode		b $00,$ff,$03,$15,$bf

;*** Fehler: Infoblock beschädigt.
:Dlg_BadHdr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w curFileName
			b DBTXTSTR   ,$0c,$40
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "GEOS-Infoblock nicht gespeichert:",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Der Infoblock ist beschädigt!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The GEOS infoblock was not updated:",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "The infoblock is damaged!",NULL
endif

;*** Fehler: Datei kann nicht umbenannt werden.
:Dlg_ErrRename		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w curFileName
			b DBTXTSTR   ,$0c,$40
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Umbenennen der Datei fehlgeschlagen:",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Die Datei existiert bereits!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Error when renaming the file:",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "File already exist!",NULL
endif

;*** Hinweis: Datum wird für markierte Dateien gespeichert.
:Dlg_SetADate		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w :4
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Datum wird für alle ausgewählten",NULL
::3			b "Dateien direkt auf Disk gespeichert.",BOLDON,NULL
::4			b BOLDON
			b "Datum aktualisieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The date will be saved directly to",NULL
::3			b "disk for all selected files.",BOLDON,NULL
::4			b BOLDON
			b "Update date and time?",NULL
endif

;*** Hinweis: Datum wird für alle Dateien auf Disk gespeichert.
:Dlg_SetDDate		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w :4
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Datum wird für alle Dateien im",NULL
::3			b "aktuellen Verzeichnis gespeichert.",BOLDON,NULL
::4			b BOLDON
			b "Datum aktualisieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The date will be saved directly for",NULL
::3			b "all files in the current directory.",BOLDON,NULL
::4			b BOLDON
			b "Update date and time?",NULL
endif

;*** Hinweis: Autor wird für markierte Dateien gespeichert.
:Dlg_SetAuthor		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w :4
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Der Autor wird für alle ausgewählten",NULL
::3			b "Dateien direkt auf Disk gespeichert.",BOLDON,NULL
::4			b BOLDON
			b "Autor aktualisieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The author will be saved directly to",NULL
::3			b "disk for all selected files.",BOLDON,NULL
::4			b BOLDON
			b "Update author?",NULL
endif

;*** Hinweis: Dateien wurden aktualisiert.
:Dlg_UpdateDone		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Angaben wurdem für alle",NULL
::3			b "ausgewählten Dateien aktualisiert.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The information has been updated",NULL
::3			b "for all selected files.",NULL
endif

;*** Zwischenspeicher Dateieinträge.
:dirEntryData
:dirEntryData_S		= MAX_DIR_ENTRIES * 32

;*** Endadresse testen:
			g BASE_DIRDATA - dirEntryData_S
;***
