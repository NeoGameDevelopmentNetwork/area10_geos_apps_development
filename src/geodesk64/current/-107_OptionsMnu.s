; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Optionen anzeigen.
:xOPTIONS		lda	GD_DUALWIN_DRV1		;DeskTop: Laufwerk #1.
			clc
			adc	#"A"
			sta	drvWin1Text +0

			lda	GD_DUALWIN_DRV2		;DeskTop: Laufwerk #2.
			clc
			adc	#"A"
			sta	drvWin2Text +0

			jsr	defSortModTx		;Text für Sortiermodus einlesen.

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	bit	reloadDir		;Optionen geändert?
			bpl	:2			; => Nein, Ende...

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

::1			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.
:drvWin1Text		b "A:",NULL
:drvWin2Text		b "A:",NULL
:sortModeText		s 20

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

if DEBUG_SYSINFO = FALSE
			b 5				;Anzahl Einträge ohne Debug.
endif
if DEBUG_SYSINFO = TRUE
			b 6				;Anzahl Einträge mit Debug.
endif

			w RTabName1_1			;Register: "ANZEIGE".
			w RTabMenu1_1

			w RTabName1_2			;Register: "OPTIONEN1".
			w RTabMenu1_2

			w RTabName1_3			;Register: "OPTIONEN2".
			w RTabMenu1_3

			w RTabName1_4			;Register: "INFO".
			w RTabMenu1_4

			w RTabName1_5			;Register: "DESKTOP".
			w RTabMenu1_5

if DEBUG_SYSINFO = TRUE
			w RTabName1_9			;Register: "DEBUG".
			w RTabMenu1_9
endif

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabName1_2		w RTabIcon2
			b RCardIconX_2,R1SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

:RTabName1_3		w RTabIcon3
			b RCardIconX_3,R1SizeY0 -$08
			b RTabIcon3_x,RTabIcon3_y

:RTabName1_4		w RTabIcon4
			b RCardIconX_4,R1SizeY0 -$08
			b RTabIcon4_x,RTabIcon4_y

:RTabName1_5		w RTabIcon5
			b RCardIconX_5,R1SizeY0 -$08
			b RTabIcon5_x,RTabIcon5_y

if DEBUG_SYSINFO = TRUE
:RTabName1_9		w RTabIcon9
			b RCardIconX_9,R1SizeY0 -$10
			b RTabIcon9_x,RTabIcon9_y
endif

;*** Menü-Icons.
:Icon_Next		w IconNext
			b $00,$00
			b IconNext_x,IconNext_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "ANZEIGE".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RWidth1  = $0028
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $30
:RLine1_5 = $40
:RLine1_6 = $50

:RTabMenu1_1		b 7

			b BOX_FRAME			;----------------------------------------
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R1T02
				w setReloadDir
				b RPos1_y +RLine1_1
				w RPos1_x
				w GD_VIEW_DEL
				b %11111111

:RTabMenu1_1a		b BOX_OPTION			;----------------------------------------
				w R1T03
				w setupIconCache
				b RPos1_y +RLine1_2
				w RPos1_x
				w GD_ICON_CACHE
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T04
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w GD_ICON_PRELOAD
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T05
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x
				w GD_COL_MODE
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T06
				w setReloadDir
				b RPos1_y +RLine1_5
				w RPos1_x
				w GD_COL_DEBUG
				b %11111111

			b BOX_USEROPT			;----------------------------------------
				w R1T07
				w switchReloadDA
				b RPos1_y +RLine1_6
				b RPos1_y +RLine1_6 +$07
				w RPos1_x
				w RPos1_x +$07

if LANG = LANG_DE
:R1T01			b "VERZEICHNIS",NULL

:R1T02			w RPos1_x +$10
			b RPos1_y +RLine1_1 +$06
			b "Gelöschte Dateien anzeigen",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "64Kb Speicher für Icon-Cache",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Zuerst alle Datei-Icons einlesen",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "Datei-Icons ohne Farbe anzeigen",NULL

:R1T06			w RPos1_x +$10
			b RPos1_y +RLine1_5 +$06
			b "Debug-Modus für Icon-Cache",NULL

:R1T07			w RPos1_x +$10
			b RPos1_y +RLine1_6 +$06
			b "DeskAccessory: Fenster neu laden"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_6 +$06 +$08
			b "(Aus / Oberstes / Alle Fenster)",NULL

endif
if LANG = LANG_EN
:R1T01			b "DIRECTORY",NULL

:R1T02			w RPos1_x +$10
			b RPos1_y +RLine1_1 +$06
			b "Display deleted files",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "64Kb memory for icon cache",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Preload all file icons",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "Display file icons without color",NULL

:R1T06			w RPos1_x +$10
			b RPos1_y +RLine1_5 +$06
			b "Debug mode for icon cache",NULL

:R1T07			w RPos1_x +$10
			b RPos1_y +RLine1_6 +$06
			b "DeskAccessory: Reload files"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_6 +$06 +$08
			b "(Off / Top only / All windows)",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "OPTIONEN1".
:RPos2_x  = R1SizeX0 +$10
:RPos2_y  = R1SizeY0 +$10
:RWidth2  = $0060
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $30
:RLine2_4 = $50

:RTabMenu1_2		b 6

			b BOX_FRAME			;----------------------------------------
				w R2T01
				w $0000
				b RPos2_y +RLine2_1 -$05
				b RPos2_y +RLine2_2 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R2T02
				w $0000
				b RPos2_y +RLine2_1
				w RPos2_x
				w GD_DEL_MENU
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R2T03
				w $0000
				b RPos2_y +RLine2_2
				w RPos2_x
				w GD_DEL_EMPTY
				b %11111111

			b BOX_FRAME			;----------------------------------------
				w R2T04
				w $0000
				b RPos2_y +RLine2_3 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R2T05
				w $0000
				b RPos2_y +RLine2_3
				w RPos2_x
				w GD_COPY_NM_DIR
				b %10000000

			b BOX_OPTION			;----------------------------------------
				w R2T06
				w $0000
				b RPos2_y +RLine2_4
				w RPos2_x +$10
				w GD_COPY_NM_DIR
				b %01000000

if LANG = LANG_DE
:R2T01			b "DATEIEN LÖSCHEN",NULL

:R2T02			w RPos2_x +$10
			b RPos2_y +RLine2_1 +$06
			b "Dateien ohne Nachfragen löschen",NULL

:R2T03			w RPos2_x +$10
			b RPos2_y +RLine2_2 +$06
			b "Nur leere Verzeichnisse löschen",NULL

:R2T04			b "VERZEICHNISSE KOPIEREN",NULL

:R2T05			w RPos2_x +$10
			b RPos2_y +RLine2_3 +$06
			b "Von NativeMode nach 1541/71/81:"
			b GOTOXY
			w RPos2_x +$10
			b RPos2_y +RLine2_3 +$09 +$06
			b "Deaktiviert: Nichts kopieren"
			b GOTOXY
			w RPos2_x +$10
			b RPos2_y +RLine2_3 +$12 +$06
			b "Aktiviert: Nur Inhalte kopieren",NULL

:R2T06			w RPos2_x +$10 +$10
			b RPos2_y +RLine2_4 +$06
			b "Kopieren: Hinweis anzeigen",NULL
endif
if LANG = LANG_EN
:R2T01			b "DELETE FILES",NULL

:R2T02			w RPos2_x +$10
			b RPos2_y +RLine2_1 +$06
			b "Delete files without prompting",NULL

:R2T03			w RPos2_x +$10
			b RPos2_y +RLine2_2 +$06
			b "Delete empty directories only",NULL

:R2T04			b "COPY DIRECTORIES",NULL

:R2T05			w RPos2_x +$10
			b RPos2_y +RLine2_3 +$06
			b "From NativeMode to 1541/71/81:"
			b GOTOXY
			w RPos2_x +$10
			b RPos2_y +RLine2_3 +$09 +$06
			b "Disabled: Don`t copy anything"
			b GOTOXY
			w RPos2_x +$10
			b RPos2_y +RLine2_3 +$12 +$06
			b "Enabled: Copy files only",NULL

:R2T06			w RPos2_x +$10 +$10
			b RPos2_y +RLine2_4 +$06
			b "If enabled: Display warning",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "OPTIONEN2".
:RPos3_x  = R1SizeX0 +$10
:RPos3_y  = R1SizeY0 +$10
:RWidth3  = $0060
:RLine3_1 = $00
:RLine3_2 = $10
:RLine3_3 = $30
:RLine3_4 = $40
:RLine3_5 = $50

:RTabMenu1_3		b 7

			b BOX_FRAME			;----------------------------------------
				w R3T01
				w $0000
				b RPos3_y +RLine3_1 -$05
				b RPos3_y +RLine3_3 -$0f
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R3T06
				w $0000
				b RPos3_y +RLine3_1
				w RPos3_x
				w GD_OPEN_TARGET
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R3T02
				w $0000
				b RPos3_y +RLine3_2
				w RPos3_x
				w GD_REUSE_DIR
				b %11111111

			b BOX_FRAME			;----------------------------------------
				w R3T07
				w $0000
				b RPos3_y +RLine3_3 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R3T03
				w $0000
				b RPos3_y +RLine3_3
				w RPos3_x
				w GD_OVERWRITE_FILES
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R3T04
				w $0000
				b RPos3_y +RLine3_4
				w RPos3_x
				w GD_SKIP_EXISTING
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R3T05
				w $0000
				b RPos3_y +RLine3_5
				w RPos3_x +$10
				w GD_SKIP_NEWER
				b %11111111

if LANG = LANG_DE
:R3T01			b "DATEIEN KOPIEREN",NULL

:R3T06			w RPos3_x +$10
			b RPos3_y +RLine3_1 +$06
			b "Am Ende Ziel-Fenster aktivieren",NULL

:R3T02			w RPos3_x +$10
			b RPos3_y +RLine3_2 +$06
			b "Dateien in bereits vorhandene"
			b GOTOXY
			w RPos3_x +$10
			b RPos3_y +RLine3_2 +$08 +$06
			b "Unterverzeichnisse kopieren",NULL

:R3T07			b "DATEIEN ERSETZEN",NULL

:R3T03			w RPos3_x +$10
			b RPos3_y +RLine3_3 +$06
			b "Dateien überschreiben",NULL

:R3T04			w RPos3_x +$10
			b RPos3_y +RLine3_4 +$06
			b "Vorhandene Dateien überspringen",NULL

:R3T05			w RPos3_x +$20
			b RPos3_y +RLine3_5 +$06
			b "Nur wenn die Ziel-Datei ein"
			b GOTOXY
			w RPos3_x +$20
			b RPos3_y +RLine3_5 +$08 +$06
			b "aktuelleres Datum hat",NULL
endif
if LANG = LANG_EN
:R3T01			b "COPY FILES",NULL

:R3T06			w RPos3_x +$10
			b RPos3_y +RLine3_1 +$06
			b "Open target window after copy",NULL

:R3T02			w RPos3_x +$10
			b RPos3_y +RLine3_2 +$06
			b "Copy files to existing"
			b GOTOXY
			w RPos3_x +$10
			b RPos3_y +RLine3_2 +$08 +$06
			b "subdirectories",NULL

:R3T07			b "REPLACE FILES",NULL

:R3T03			w RPos3_x +$10
			b RPos3_y +RLine3_3 +$06
			b "Replace existing files",NULL

:R3T04			w RPos3_x +$10
			b RPos3_y +RLine3_4 +$06
			b "Skip existing files",NULL

:R3T05			w RPos3_x +$20
			b RPos3_y +RLine3_5 +$06
			b "Only if target file has"
			b GOTOXY
			w RPos3_x +$20
			b RPos3_y +RLine3_5 +$08 +$06
			b "a more recent date",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "INFO".
:RPos4_x  = R1SizeX0 +$10
:RPos4_y  = R1SizeY0 +$10
:RWidth4  = $0048
:RWidth4a  = $0078
:RLine4_1 = $00
:RLine4_2 = $10
:RLine4_3 = $20
:RLine4_4 = $40
:RLine4_5 = $50

:RTabMenu1_4		b 10

			b BOX_FRAME			;----------------------------------------
				w R4T01
				w doInitSysInfo
				b RPos4_y +RLine4_1 -$05
				b RPos4_y +RLine4_3 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R4T02
				w $0000
				b RPos4_y +RLine4_1
				w RPos4_x +RWidth4
				w infoBootDrive
				b 2

			b BOX_STRING_VIEW		;----------------------------------------
				w R4T02a
				w $0000
				b RPos4_y +RLine4_1
				w RPos4_x +RWidth4 +$50
				w infoBootType
				b 2

			b BOX_STRING_VIEW		;----------------------------------------
				w R4T02b
				w $0000
				b RPos4_y +RLine4_1
				w RPos4_x +RWidth4 +$70
				w infoBootMode
				b 2

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R4T03
				w $0000
				b RPos4_y +RLine4_2
				w RPos4_x +RWidth4a
				w BootPart
				b 3!NUMERIC_LEFT!NUMERIC_BYTE

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R4T04
				w $0000
				b RPos4_y +RLine4_3
				w RPos4_x +RWidth4a
				w BootSDir +0
				b 3!NUMERIC_LEFT!NUMERIC_BYTE

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R4T04a
				w $0000
				b RPos4_y +RLine4_3
				w RPos4_x +RWidth4a +$28
				w BootSDir +1
				b 3!NUMERIC_LEFT!NUMERIC_BYTE

			b BOX_FRAME			;----------------------------------------
				w R4T05
				w $0000
				b RPos4_y +RLine4_4 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R4T06
				w $0000
				b RPos4_y +RLine4_4
				w RPos4_x +RWidth4
				w GD_SYS_NAME
				b 16

			b BOX_STRING_VIEW		;----------------------------------------
				w R4T07
				w $0000
				b RPos4_y +RLine4_5
				w RPos4_x +RWidth4
				w GD_CLASS
				b 16

if LANG = LANG_DE
:R4T01			b "SYSTEM-LAUFWERK",NULL

:R4T02			w RPos4_x
			b RPos4_y +RLine4_1 +$06
			b "Laufwerk:",NULL

:R4T02a			w RPos4_x +RWidth4 +$30
			b RPos4_y +RLine4_1 +$06
			b "GEOS:",NULL

:R4T02b			w RPos4_x +RWidth4 +$66
			b RPos4_y +RLine4_1 +$06
			b "/",NULL

:R4T03			w RPos4_x
			b RPos4_y +RLine4_2 +$06
			b "CMD-Partition:",NULL

:R4T04			w RPos4_x
			b RPos4_y +RLine4_3 +$06
			b "Native/Verzeichnis:",NULL

:R4T04a			w RPos4_x +RWidth4a +$1e
			b RPos4_y +RLine4_3 +$06
			b "/",NULL

:R4T05			b "SYSTEM-DATEI",NULL

:R4T06			w RPos4_x
			b RPos4_y +RLine4_4 +$06
			b "Dateiname:",NULL

:R4T07			w RPos4_x
			b RPos4_y +RLine4_5 +$06
			b "Klasse:",NULL
endif
if LANG = LANG_EN
:R4T01			b "SYSTEM-DRIVE",NULL

:R4T02			w RPos4_x
			b RPos4_y +RLine4_1 +$06
			b "Drive:",NULL

:R4T02a			w RPos4_x +RWidth4 +$30
			b RPos4_y +RLine4_1 +$06
			b "GEOS:",NULL

:R4T02b			w RPos4_x +RWidth4 +$66
			b RPos4_y +RLine4_1 +$06
			b "/",NULL

:R4T03			w RPos4_x
			b RPos4_y +RLine4_2 +$06
			b "CMD-Partition:",NULL

:R4T04			w RPos4_x
			b RPos4_y +RLine4_3 +$06
			b "Native/Directory:",NULL

:R4T04a			w RPos4_x +RWidth4a +$1e
			b RPos4_y +RLine4_3 +$06
			b "/",NULL

:R4T05			b "SYSTEM-FILE",NULL

:R4T06			w RPos4_x
			b RPos4_y +RLine4_4 +$06
			b "Filename:",NULL

:R4T07			w RPos4_x
			b RPos4_y +RLine4_5 +$06
			b "Class:",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DESKTOP".
:RPos5_x  = R1SizeX0 +$10
:RPos5_y  = R1SizeY0 +$10
:RWidth5  = $0080
:RWidth5a = $0080
:RWidth5b = $00b0
:RWidth5c = $0060
:RWidth5d = $0070
:RLine5_1 = $00
:RLine5_2 = $20
:RLine5_3 = $30
:RLine5_4 = $50

:RTabMenu1_5		b 16

			b BOX_FRAME			;----------------------------------------
				w R5T01
				w doInitSysInfo
				b RPos5_y +RLine5_1 -$05
				b RPos5_y +RLine5_1 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX0 +$6f
			b BOX_OPTION			;----------------------------------------
				w R5T01a
				w $0000
				b RPos5_y +RLine5_1
				w RPos5_x
				w GD_SYSINFO_MODE
				b %11111111

			b BOX_FRAME			;----------------------------------------
				 w R5T02
				w $0000
				b RPos5_y +RLine5_1 -$05
				b RPos5_y +RLine5_1 +$08 +$05
				w R1SizeX0 +$78
				w R1SizeX1 -$08
			b BOX_OPTION			;----------------------------------------
				 w R5T02a
				w $0000
				b RPos5_y +RLine5_1
				w RPos5_x +RWidth5d
				w GD_DA_BACKSCRN
				b %11111111

			b BOX_FRAME			;----------------------------------------
				w R5T03
				w $0000
				b RPos5_y +RLine5_2 -$05
				b RPos5_y +RLine5_3 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:updViewMode		b BOX_OPTION			;----------------------------------------
				w R5T04
				w $0000
				b RPos5_y +RLine5_2
				w RPos5_x
				w GD_STD_VIEWMODE
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R5T04a
				w $0000
				b RPos5_y +RLine5_2
				w RPos5_x +RWidth5c
				w GD_STD_SIZEMODE
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R5T05
				w defViewMode
				b RPos5_y +RLine5_3
				w RPos5_x ;+$10
				w GD_STD_TEXTMODE
				b %11111111

:updSortMode		b BOX_STRING_VIEW		;----------------------------------------
				w R5T05a
				w $0000
				b RPos5_y +RLine5_3
				w RPos5_x +RWidth5c
				w sortModeText
				b 12
			b BOX_ICON			;----------------------------------------
				w $0000
				w setSortMode
				b RPos5_y +RLine5_3
				w RPos5_x +RWidth5c +12*8
				w Icon_Next
				b $00

			b BOX_FRAME			;----------------------------------------
				w R5T06
				w $0000
				b RPos5_y +RLine5_4 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R5T07
				w $0000
				b RPos5_y +RLine5_4
				w RPos5_x
				w GD_DUALWIN_MODE
				b %11111111

:updDrv1Text		b BOX_STRING_VIEW		;----------------------------------------
				w R5T08
				w $0000
				b RPos5_y +RLine5_4
				w RPos5_x +RWidth5a
				w drvWin1Text
				b 2
			b BOX_ICON			;----------------------------------------
				w $0000
				w setDualWin1
				b RPos5_y +RLine5_4
				w RPos5_x +RWidth5a +$10
				w Icon_Next
				b $00
:updDrv2Text		b BOX_STRING_VIEW		;----------------------------------------
				w R5T09
				w $0000
				b RPos5_y +RLine5_4
				w RPos5_x +RWidth5b
				w drvWin2Text
				b 2
			b BOX_ICON			;----------------------------------------
				w $0000
				w setDualWin2
				b RPos5_y +RLine5_4
				w RPos5_x +RWidth5b +$10
				w Icon_Next
				b $00

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if LANG = LANG_DE
:R5T01			b "SYSTEM-INFO",NULL

:R5T01a			w RPos5_x +$10
			b RPos5_y +RLine5_1 +$06
			b "Aktive Tasks",NULL

:R5T02			b "HILFSMITTEL",NULL

:R5T02a			w RPos5_x +RWidth5d +$10
			b RPos5_y +RLine5_1 +$06
			b "Hintergrund",NULL

:R5T03			b "STANDARD ANZEIGEMODUS",NULL

:R5T04			w RPos5_x +$10
			b RPos5_y +RLine5_2 +$06
			b "Textmodus",NULL

:R5T04a			w RPos5_x +RWidth5c +$10
			b RPos5_y +RLine5_2 +$06
			b "KBytes anzeigen",NULL

:R5T05			w RPos5_x +$10 ;+$10
			b RPos5_y +RLine5_3 +$06
			b "Details",NULL

:R5T05a			w RPos5_x +RWidth5c -$1e
			b RPos5_y +RLine5_3 +$06
			b "Sort:",NULL

:R5T06			b "ZWEI-FENSTER-MODUS",NULL

:R5T07			w RPos5_x +$10
			b RPos5_y +RLine5_4 +$06
			b "Aktiv",NULL

:R5T08			w RPos5_x +RWidth5a -$40
			b RPos5_y +RLine5_4 +$06
			b "Fenster #1",NULL

:R5T09			w RPos5_x +RWidth5b -$10
			b RPos5_y +RLine5_4 +$06
			b "#2",NULL
endif
if LANG = LANG_EN
:R5T01			b "SYSTEM-INFO",NULL

:R5T01a			w RPos3_x +$10
			b RPos5_y +RLine5_1 +$06
			b "Active tasks",NULL

:R5T02			b "DESKACCESSORY",NULL

:R5T02a			w RPos5_x +RWidth5d +$10
			b RPos5_y +RLine5_1 +$06
			b "Wallpaper",NULL

:R5T03			b "DEFAULT VIEWMODE",NULL

:R5T04			w RPos5_x +$10
			b RPos5_y +RLine5_2 +$06
			b "Text mode",NULL

:R5T04a			w RPos5_x +RWidth5c +$10
			b RPos5_y +RLine5_2 +$06
			b "Display KByte",NULL

:R5T05			w RPos5_x +$10 ;+$10
			b RPos5_y +RLine5_3 +$06
			b "Details",NULL

:R5T05a			w RPos5_x +RWidth5c -$1e
			b RPos5_y +RLine5_3 +$06
			b "Sort:",NULL

:R5T06			b "TWO-WINDOW-MODE",NULL

:R5T07			w RPos5_x +$10
			b RPos5_y +RLine5_4 +$06
			b "Enabled",NULL

:R5T08			w RPos5_x +RWidth5a -$40
			b RPos5_y +RLine5_4 +$06
			b "Window #1",NULL

:R5T09			w RPos5_x +RWidth5b -$10
			b RPos5_y +RLine5_4 +$06
			b "#2",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DEBUG".
if DEBUG_SYSINFO = TRUE
:RPos9_x  = R1SizeX0 +$10
:RPos9_y  = R1SizeY0 +$10
:RLine9_1 = $00
:RLine9_2 = $20

:RTabMenu1_9		b 7

			b BOX_FRAME			;----------------------------------------
				w R9T01
				w doInitRAMInfo
				b RPos9_y -$05
				b RPos9_y +RLine9_1 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R9T01a
				w $0000
				b RPos9_y +RLine9_1
				w RPos9_x
				w bankSys
				b $02

			b BOX_STRING_VIEW		;----------------------------------------
				w R9T01b
				w $0000
				b RPos9_y +RLine9_1
				w RPos9_x +$40
				w bankData
				b $02

:RTabMenu1_9a		b BOX_STRING_VIEW		;----------------------------------------
				w $0000
				w SwapBankGD
				b RPos9_y +RLine9_2
				w RPos9_x
				w bankGDesk1
				b $02

			b BOX_ICON			;----------------------------------------
				w $0000
				w SwapBankGD
				b RPos9_y +RLine9_2
				w RPos9_x +$10
				w Icon_Next
				b $00

			b BOX_STRING_VIEW		;----------------------------------------
				w R9T01d
				w $0000
				b RPos9_y +RLine9_1
				w RPos9_x +$78
				w bankCache
				b $02

			b BOX_FRAME			;----------------------------------------
				w R9T02
				w prntVlirInfo
				b RPos9_y +RLine9_2 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08
endif

if DEBUG_SYSINFO ! LANG = TRUE ! LANG_DE
:R9T01			b "RESERVIERTER SPEICHER",NULL

:R9T02			b "VLIR-MODULE IN GDESK-RAM",NULL

:R9T01a			w RPos9_x +$10 +$03
			b RPos9_y +RLine9_1 +$06
			b "SYSTEM",NULL

:R9T01b			w RPos9_x +$50 +$03
			b RPos9_y +RLine9_1 +$06
			b "DATA",NULL

:R9T01d			w RPos9_x +$88 +$03
			b RPos9_y +RLine9_1 +$06
			b "ICON-CACHE",NULL
endif
if DEBUG_SYSINFO ! LANG = TRUE ! LANG_EN
:R9T01			b "RESERVED MEMORY",NULL

:R9T02			b "VLIR-MODULES IN GDESK-RAM",NULL

:R9T01a			w RPos9_x +$10 +$03
			b RPos9_y +RLine9_1 +$06
			b "SYSTEM",NULL

:R9T01b			w RPos9_x +$50 +$03
			b RPos9_y +RLine9_1 +$06
			b "DATA",NULL

:R9T01d			w RPos9_x +$88 +$03
			b RPos9_y +RLine9_1 +$06
			b "ICON-CACHE",NULL
endif

;*** Icons für Registerkarten.
:RTabIcon1
if LANG = LANG_DE
<MISSING_IMAGE_DATA>
endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>
endif

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RTabIcon2
if LANG = LANG_DE
<MISSING_IMAGE_DATA>
endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>
endif

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

:RTabIcon3
if LANG = LANG_DE
<MISSING_IMAGE_DATA>
endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>
endif

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y

:RTabIcon4
<MISSING_IMAGE_DATA>

:RTabIcon4_x		= .x
:RTabIcon4_y		= .y

:RTabIcon5
<MISSING_IMAGE_DATA>

:RTabIcon5_x		= .x
:RTabIcon5_y		= .y

if DEBUG_SYSINFO = TRUE
:RTabIcon9
<MISSING_IMAGE_DATA>

:RTabIcon9_x		= .x
:RTabIcon9_y		= .y
endif

;*** X-Koordinate der Register-Icons.
;--- Reiher#1.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_5		= RCardIconX_1 + RTabIcon1_x
:RCardIconX_2		= RCardIconX_5 + RTabIcon5_x
:RCardIconX_3		= RCardIconX_2 + RTabIcon2_x
:RCardIconX_4		= RCardIconX_3 + RTabIcon3_x
;--- Reihe#2.
if DEBUG_SYSINFO = TRUE
:RCardIconX_9		= (R1SizeX0/8) +4
endif

;*** Menü-Icons.
:IconNext
<MISSING_IMAGE_DATA>

:IconNext_x		= .x
:IconNext_y		= .y
