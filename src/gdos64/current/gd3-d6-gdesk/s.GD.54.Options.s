; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk-Konfiguration speichern.
;* GeoDesk-Optionen ändern.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
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
			n "obj.GD54"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSAVE_CONFIG
			jmp	xOPTIONS

;*** Speicherverwaltung.
			t "-DA_FindBank"
			t "-DA_FreeBank"
			t "-DA_AllocBank"
			t "-DA_GetBankByte"

;*** Systemroutinen.
			t "-SYS_DISKFILE"

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
			jsr	defWheelModTx		;Text für Wheel-Modus einlesen.
			jsr	defWheelDelay		;Wert für Wheel-Verzögerung setzen.

			jsr	setHCmodes		;Aktionen für HotCorner einlesen.

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			jsr	putGDINI_RAM		;GD.INI im RAM aktualisieren.

			bit	reloadDir		;Optionen geändert?
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

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;*** Konfiguration speichern.
:xSAVE_CONFIG		jsr	TempBootDrive		;Boot-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbrucb...

			jsr	doSaveConfig
			txa
			pha				;Fehlerstatus zwischenspeichern.

			jsr	BackTempDrive		;Laufwerk zurücksetzen.

			pla				;Diskettenfehler?
			beq	exitOptions		; => Nein, weiter...

;--- Fehler beim speichern.
::error			jsr	HEX2ASCII		;Fehlercode nach ASCII wandeln.
			stx	svErrorCode +0
			sta	svErrorCode +1

			LoadW	r0,Dlg_SaveError	;"Fehler beim speichern"
			jsr	DoDlgBox		;DialogBox aufrufen.

;--- Hinweis:
;Evtl. wurde das aktuelle Laufwerk oder
;die Partition gewechselt, daher muss
;hier ":MOD_UPDATE" getartet werden.
;Bei geöffneten Dateifenstern passt
;sonst der Inhalt des Laufwerks nicht
;mehr zum Dateifenster (Datei-Icons).
:exitOptions		lda	#< SET_LOAD_DISK	;Verzeichnis von Disk neu einlesen.
			ldx	#> SET_LOAD_DISK

			ldy	BootDrive
			cpy	curDrive		;Boot-Laufwerk = Aktuelles Laufwerk?
			beq	:1			; => Ja, weiter...

			lda	#< SET_LOAD_CACHE	;Verzeichnis aus Cache einlesen.
			ldx	#> SET_LOAD_CACHE

::1			jsr	CallRoutine		;Verzeichnis-Modus setzen.
			jmp	MOD_UPDATE		;Menü/FensterManager neu starten.

;*** Register-Menü.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

if DEBUG_SYSINFO = FALSE
			b 7				;Anzahl Einträge ohne Debug.
endif
if DEBUG_SYSINFO = TRUE
			b 8				;Anzahl Einträge mit Debug.
endif

			w RegTName1			;Register: "ANZEIGE".
			w RegTMenu1

			w RegTName2			;Register: "OPTIONEN1".
			w RegTMenu2

			w RegTName3			;Register: "OPTIONEN2".
			w RegTMenu3

			w RegTName4			;Register: "INFO".
			w RegTMenu4

			w RegTName5			;Register: "DESKTOP".
			w RegTMenu5

			w RegTName6			;Register: "HOT CORNERS".
			w RegTMenu6

			w RegTName7			;Register: "MICROMYS".
			w RegTMenu7

if DEBUG_SYSINFO = TRUE
			w RegTName9			;Register: "DEBUG".
			w RegTMenu9
endif

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif
if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

:RegTName2		w RTabIcon2
			b RCardIconX_2,R1SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

if LANG = LANG_DE
:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif
if LANG = LANG_EN
:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif

:RegTName3		w RTabIcon3
			b RCardIconX_3,R1SizeY0 -$08
			b RTabIcon3_x,RTabIcon3_y

if LANG = LANG_DE
:RTabIcon3
<MISSING_IMAGE_DATA>

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y
endif
if LANG = LANG_EN
:RTabIcon3
<MISSING_IMAGE_DATA>

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y
endif

:RegTName4		w RTabIcon4
			b RCardIconX_4,R1SizeY0 -$08
			b RTabIcon4_x,RTabIcon4_y

:RTabIcon4
<MISSING_IMAGE_DATA>

:RTabIcon4_x		= .x
:RTabIcon4_y		= .y

:RegTName5		w RTabIcon5
			b RCardIconX_5,R1SizeY0 -$08
			b RTabIcon5_x,RTabIcon5_y

:RTabIcon5
<MISSING_IMAGE_DATA>

:RTabIcon5_x		= .x
:RTabIcon5_y		= .y

:RegTName6		w RTabIcon6
			b RCardIconX_6,R1SizeY0 -$10
			b RTabIcon6_x,RTabIcon6_y

:RTabIcon6
<MISSING_IMAGE_DATA>

:RTabIcon6_x		= .x
:RTabIcon6_y		= .y

:RegTName7		w RTabIcon7
			b RCardIconX_7,R1SizeY0 -$10
			b RTabIcon7_x,RTabIcon7_y

:RTabIcon7
<MISSING_IMAGE_DATA>

:RTabIcon7_x		= .x
:RTabIcon7_y		= .y

if DEBUG_SYSINFO = TRUE
:RegTName9		w RTabIcon9
			b RCardIconX_9,R1SizeY0 -$10
			b RTabIcon9_x,RTabIcon9_y

:RTabIcon9
<MISSING_IMAGE_DATA>

:RTabIcon9_x		= .x
:RTabIcon9_y		= .y
endif

;*** X-Koordinate der Register-Icons.
;--- Reihe#1.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_5		= RCardIconX_1 + RTabIcon1_x
:RCardIconX_2		= RCardIconX_5 + RTabIcon5_x
:RCardIconX_3		= RCardIconX_2 + RTabIcon2_x
:RCardIconX_4		= RCardIconX_3 + RTabIcon3_x
;--- Reihe#2.
:RCardIconX_6		= (R1SizeX0/8) +4
:RCardIconX_7		= RCardIconX_6 + RTabIcon6_x
if DEBUG_SYSINFO = TRUE
:RCardIconX_9		= RCardIconX_7 + RTabIcon7_x
endif

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= TRUE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Menü-Icons.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

:RIcon_UpDown		w Icon_MUpDown
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MUpDown_x,Icon_MUpDown_y
			b USE_COLOR_INPUT

;--- HotCorner-Symbole.
:RIcon_HOTC1		w Icon_HOTC1
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_HOTC1_x,Icon_HOTC1_y
			b USE_COLOR_REG

:Icon_HOTC1
<MISSING_IMAGE_DATA>

:Icon_HOTC1_x		= .x
:Icon_HOTC1_y		= .y

:RIcon_HOTC2		w Icon_HOTC2
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_HOTC2_x,Icon_HOTC2_y
			b USE_COLOR_REG

:Icon_HOTC2
<MISSING_IMAGE_DATA>

:Icon_HOTC2_x		= .x
:Icon_HOTC2_y		= .y

:RIcon_HOTC3		w Icon_HOTC3
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_HOTC3_x,Icon_HOTC3_y
			b USE_COLOR_REG

:Icon_HOTC3
<MISSING_IMAGE_DATA>

:Icon_HOTC3_x		= .x
:Icon_HOTC3_y		= .y

:RIcon_HOTC4		w Icon_HOTC4
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_HOTC4_x,Icon_HOTC4_y
			b USE_COLOR_REG

:Icon_HOTC4
<MISSING_IMAGE_DATA>

:Icon_HOTC4_x		= .x
:Icon_HOTC4_y		= .y

;--- HotCorner-Überschrift.
:RIcon_Header		w Icon_Header
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Header_x,Icon_Header_y
			b USE_COLOR_REG

:Icon_Header
if LANG = LANG_DE
<MISSING_IMAGE_DATA>

endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>

endif

:Icon_Header_x		= .x
:Icon_Header_y		= .y

;*** Daten für Register "ANZEIGE".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0060
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $30
:RLine1_5 = $40
:RLine1_6 = $50

:RegTMenu1		b 8

			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R1T02
				w setReloadDir
				b RPos1_y +RLine1_1
				w RPos1_x
				w GD_VIEW_DELETED
				b %11111111

			b BOX_OPTION
				w R1T08
				w setReloadDir
				b RPos1_y +RLine1_2
				w RPos1_x
				w GD_HIDE_SYSTEM
				b %11100000

:RegTMenu1a		b BOX_OPTION
				w R1T03
				w setupIconCache
				b RPos1_y +RLine1_3
				w RPos1_x
				w GD_ICON_CACHE
				b %11111111

			b BOX_OPTION
				w R1T06
				w setReloadDir
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_1
				w GD_COL_DEBUG
				b %11111111

			b BOX_OPTION
				w R1T04
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x
				w GD_ICON_PRELOAD
				b %11111111

			b BOX_OPTION
				w R1T05
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x
				w GD_COL_MODE
				b %11111111

			b BOX_USEROPT
				w R1T07
				w switchReloadDA
				b RPos1_y +RLine1_6
				b RPos1_y +RLine1_6 +$07
				w RPos1_x
				w RPos1_x +$07

;*** Texte für Register "ANZEIGE".
if LANG = LANG_DE
:R1T01			b "VERZEICHNIS",NULL

:R1T02			w RPos1_x +$10
			b RPos1_y +RLine1_1 +$06
			b "Gelöschte Dateien anzeigen",NULL

:R1T08			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "System-Dateien ausblenden",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Icon-Cache",NULL

:R1T06			w RPos1_x +RTab1_1 +$10
			b RPos1_y +RLine1_3 +$06
			b "Debug-Modus",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "Datei-Icons vorab einlesen",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_5 +$06
			b "Datei-Icons ohne Farbe anzeigen",NULL

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

:R1T08			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Hide system files",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Icon cache",NULL

:R1T06			w RPos1_x +RTab1_1 +$10
			b RPos1_y +RLine1_3 +$06
			b "Debug mode",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "Preload all file icons",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_5 +$06
			b "Display file icons without color",NULL

:R1T07			w RPos1_x +$10
			b RPos1_y +RLine1_6 +$06
			b "DeskAccessory: Reload files"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_6 +$06 +$08
			b "(Off / Top only / All windows)",NULL
endif

;*** Daten für Register "OPTIONEN1".
:RPos2_x  = R1SizeX0 +$10
:RPos2_y  = R1SizeY0 +$10
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $30
:RLine2_4 = $50

:RegTMenu2		b 6

			b BOX_FRAME
				w R2T01
				w $0000
				b RPos2_y +RLine2_1 -$05
				b RPos2_y +RLine2_2 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R2T02
				w $0000
				b RPos2_y +RLine2_1
				w RPos2_x
				w GD_DEL_MENU
				b %11111111

			b BOX_OPTION
				w R2T03
				w $0000
				b RPos2_y +RLine2_2
				w RPos2_x
				w GD_DEL_EMPTY
				b %11111111

			b BOX_FRAME
				w R2T04
				w $0000
				b RPos2_y +RLine2_3 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R2T05
				w $0000
				b RPos2_y +RLine2_3
				w RPos2_x
				w GD_COPY_NM_DIR
				b %10000000

			b BOX_OPTION
				w R2T06
				w $0000
				b RPos2_y +RLine2_4
				w RPos2_x +$10
				w GD_COPY_NM_DIR
				b %01000000

;*** Texte für Register "OPTIONEN1".
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

;*** Daten für Register "OPTIONEN2".
:RPos3_x  = R1SizeX0 +$10
:RPos3_y  = R1SizeY0 +$10
:RLine3_1 = $00
:RLine3_2 = $10
:RLine3_3 = $30
:RLine3_4 = $40
:RLine3_5 = $50

:RegTMenu3		b 7

			b BOX_FRAME
				w R3T01
				w $0000
				b RPos3_y +RLine3_1 -$05
				b RPos3_y +RLine3_3 -$0f
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R3T06
				w $0000
				b RPos3_y +RLine3_1
				w RPos3_x
				w GD_OPEN_TARGET
				b %11111111

			b BOX_OPTION
				w R3T02
				w $0000
				b RPos3_y +RLine3_2
				w RPos3_x
				w GD_REUSE_DIR
				b %11111111

			b BOX_FRAME
				w R3T07
				w $0000
				b RPos3_y +RLine3_3 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R3T03
				w $0000
				b RPos3_y +RLine3_3
				w RPos3_x
				w GD_OVERWRITE
				b %11111111

			b BOX_OPTION
				w R3T04
				w $0000
				b RPos3_y +RLine3_4
				w RPos3_x
				w GD_SKIP_EXIST
				b %11111111

			b BOX_OPTION
				w R3T05
				w $0000
				b RPos3_y +RLine3_5
				w RPos3_x +$10
				w GD_SKIP_NEWER
				b %11111111

;*** Texte für Register "OPTIONEN2".
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

;*** Daten für Register "INFO".
:RPos4_x  = R1SizeX0 +$10
:RPos4_y  = R1SizeY0 +$10
if LANG = LANG_DE
:RTab4_1  = $0038
endif
if LANG = LANG_EN
:RTab4_1  = $0028
endif
:RTab4_2  = $0078
:RTab4_3  = $0098
:RTab4_4  = $00b8
:RTab4_5  = $0048
:RLine4_1 = $00
:RLine4_2 = $10
:RLine4_3 = $20
:RLine4_4 = $40
:RLine4_5 = $50

:RegTMenu4		b 10

			b BOX_FRAME
				w R4T01
				w doInitSysInfo
				b RPos4_y +RLine4_1 -$05
				b RPos4_y +RLine4_3 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW
				w R4T02
				w $0000
				b RPos4_y +RLine4_1
				w RPos4_x +RTab4_1
				w infoBootDrive
				b 2

			b BOX_STRING_VIEW
				w R4T02a
				w $0000
				b RPos4_y +RLine4_1
				w RPos4_x +RTab4_3
				w infoBootType
				b 2

			b BOX_STRING_VIEW
				w R4T02b
				w $0000
				b RPos4_y +RLine4_1
				w RPos4_x +RTab4_4
				w infoBootMode
				b 2

			b BOX_NUMERIC_VIEW
				w R4T03
				w $0000
				b RPos4_y +RLine4_2
				w RPos4_x +RTab4_2
				w BootPart
				b 3!NUMERIC_LEFT!NUMERIC_BYTE

			b BOX_NUMERIC_VIEW
				w R4T04
				w $0000
				b RPos4_y +RLine4_3
				w RPos4_x +RTab4_2
				w BootSDir +0
				b 3!NUMERIC_LEFT!NUMERIC_BYTE

			b BOX_NUMERIC_VIEW
				w R4T04a
				w $0000
				b RPos4_y +RLine4_3
				w RPos4_x +RTab4_2 +$28
				w BootSDir +1
				b 3!NUMERIC_LEFT!NUMERIC_BYTE

			b BOX_FRAME
				w R4T05
				w $0000
				b RPos4_y +RLine4_4 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW
				w R4T06
				w $0000
				b RPos4_y +RLine4_4
				w RPos4_x +RTab4_5
				w GD_SYS_NAME
				b 16

			b BOX_STRING_VIEW
				w R4T07
				w $0000
				b RPos4_y +RLine4_5
				w RPos4_x +RTab4_5
				w GD_SYS_CLASS
				b 16

;*** Daten für Register "INFO".
if LANG = LANG_DE
:R4T01			b "SYSTEM-LAUFWERK",NULL

:R4T02			w RPos4_x
			b RPos4_y +RLine4_1 +$06
			b "Laufwerk:",NULL

:R4T02a			w RPos4_x +RTab4_5 +$30
			b RPos4_y +RLine4_1 +$06
			b "GEOS:",NULL

:R4T02b			w RPos4_x +RTab4_5 +$66
			b RPos4_y +RLine4_1 +$06
			b "/",NULL

:R4T03			w RPos4_x
			b RPos4_y +RLine4_2 +$06
			b "CMD-Partition:",NULL

:R4T04			w RPos4_x
			b RPos4_y +RLine4_3 +$06
			b "Native/Verzeichnis:",NULL

:R4T04a			w RPos4_x +RTab4_2 +$1e
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

:R4T02a			w RPos4_x +RTab4_5 +$30
			b RPos4_y +RLine4_1 +$06
			b "GEOS:",NULL

:R4T02b			w RPos4_x +RTab4_5 +$66
			b RPos4_y +RLine4_1 +$06
			b "/",NULL

:R4T03			w RPos4_x
			b RPos4_y +RLine4_2 +$06
			b "CMD-Partition:",NULL

:R4T04			w RPos4_x
			b RPos4_y +RLine4_3 +$06
			b "Native/Directory:",NULL

:R4T04a			w RPos4_x +RTab4_2 +$1e
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

;*** Daten für Register "DESKTOP".
:RPos5_x  = R1SizeX0 +$10
:RPos5_y  = R1SizeY0 +$10
:RTab5_1  = $0080
:RTab5_2  = $0080
:RTab5_3  = $00b0
:RTab5_4  = $0060
:RTab5_5  = $0070
:RLine5_1 = $00
:RLine5_2 = $20
:RLine5_3 = $30
:RLine5_4 = $50

:RegTMenu5		b 19

			b BOX_FRAME
				w R5T01
				w $0000
				b RPos5_y +RLine5_1 -$05
				b RPos5_y +RLine5_1 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX0 +$6f
			b BOX_OPTION
				w R5T01a
				w $0000
				b RPos5_y +RLine5_1
				w RPos5_x
				w GD_SYSINFO_MODE
				b %11111111

			b BOX_FRAME
				w R5T02
				w $0000
				b RPos5_y +RLine5_1 -$05
				b RPos5_y +RLine5_1 +$08 +$05
				w R1SizeX0 +$78
				w R1SizeX1 -$08
			b BOX_OPTION
				w R5T02a
				w $0000
				b RPos5_y +RLine5_1
				w RPos5_x +RTab5_5
				w GD_DA_BACKSCRN
				b %11111111

			b BOX_FRAME
				w R5T03
				w $0000
				b RPos5_y +RLine5_2 -$05
				b RPos5_y +RLine5_3 +$08 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;--- Standard-Anzeigemodus.
:updViewMode		b BOX_OPTION
				w R5T04
				w $0000
				b RPos5_y +RLine5_2
				w RPos5_x
				w GD_STD_VIEWMODE
				b %11111111
			b BOX_OPTION
				w R5T04a
				w $0000
				b RPos5_y +RLine5_2
				w RPos5_x +RTab5_4
				w GD_STD_SIZEMODE
				b %11111111
			b BOX_OPTION
				w R5T05
				w defViewMode
				b RPos5_y +RLine5_3
				w RPos5_x
				w GD_STD_TEXTMODE
				b %11111111

			b BOX_FRAME
				w $0000
				w $0000
				b RPos5_y +RLine5_3 -1
				b RPos5_y +RLine5_3 +8
				w RPos5_x +RTab5_4 -1
				w RPos5_x +RTab5_4 +12*8 +8
:u05b			b BOX_STRING_VIEW
				w R5T05a
				w $0000
				b RPos5_y +RLine5_3
				w RPos5_x +RTab5_4
				w sortModeText
				b 12
			b BOX_ICON
				w $0000
				w setSortMode
				b RPos5_y +RLine5_3
				w RPos5_x +RTab5_4 +12*8
				w RIcon_Select
				b (u05b - RegTMenu5 -1)/11 +1

;--- Zwei-Fenster-Modus.
			b BOX_FRAME
				w R5T06
				w $0000
				b RPos5_y +RLine5_4 -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08
:upd2WinMode		b BOX_OPTION
				w R5T07
				w $0000
				b RPos5_y +RLine5_4
				w RPos5_x
				w GD_DUALWIN_MODE
				b %11111111

			b BOX_FRAME
				w $0000
				w $0000
				b RPos5_y +RLine5_4 -1
				b RPos5_y +RLine5_4 +8
				w RPos5_x +RTab5_2 -1
				w RPos5_x +RTab5_2 +2*8 +8
:u05c			b BOX_STRING_VIEW
				w R5T08
				w $0000
				b RPos5_y +RLine5_4
				w RPos5_x +RTab5_2
				w drvWin1Text
				b 2
			b BOX_ICON
				w $0000
				w setDualWin1
				b RPos5_y +RLine5_4
				w RPos5_x +RTab5_2 +$10
				w RIcon_Select
				b (u05c - RegTMenu5 -1)/11 +1

			b BOX_FRAME
				w $0000
				w $0000
				b RPos5_y +RLine5_4 -1
				b RPos5_y +RLine5_4 +8
				w RPos5_x +RTab5_3 -1
				w RPos5_x +RTab5_3 +2*8 +8
:u05d			b BOX_STRING_VIEW
				w R5T09
				w $0000
				b RPos5_y +RLine5_4
				w RPos5_x +RTab5_3
				w drvWin2Text
				b 2
			b BOX_ICON
				w $0000
				w setDualWin2
				b RPos5_y +RLine5_4
				w RPos5_x +RTab5_3 +$10
				w RIcon_Select
				b (u05d - RegTMenu5 -1)/11 +1

;*** Texte für Register "DESKTOP".
if LANG = LANG_DE
:R5T01			b "SYSTEM-INFO",NULL

:R5T01a			w RPos5_x +$10
			b RPos5_y +RLine5_1 +$06
			b "Aktive Tasks",NULL

:R5T02			b "HILFSMITTEL",NULL

:R5T02a			w RPos5_x +RTab5_5 +$10
			b RPos5_y +RLine5_1 +$06
			b "Hintergrund",NULL

:R5T03			b "STANDARD ANZEIGEMODUS",NULL

:R5T04			w RPos5_x +$10
			b RPos5_y +RLine5_2 +$06
			b "Textmodus",NULL

:R5T04a			w RPos5_x +RTab5_4 +$10
			b RPos5_y +RLine5_2 +$06
			b "KBytes anzeigen",NULL

:R5T05			w RPos5_x +$10 ;+$10
			b RPos5_y +RLine5_3 +$06
			b "Details",NULL

:R5T05a			w RPos5_x +RTab5_4 -$1e
			b RPos5_y +RLine5_3 +$06
			b "Sort:",NULL

:R5T06			b "ZWEI-FENSTER-MODUS",NULL

:R5T07			w RPos5_x +$10
			b RPos5_y +RLine5_4 +$06
			b "Aktiv",NULL

:R5T08			w RPos5_x +RTab5_2 -$40
			b RPos5_y +RLine5_4 +$06
			b "Fenster #1",NULL

:R5T09			w RPos5_x +RTab5_3 -$10
			b RPos5_y +RLine5_4 +$06
			b "#2",NULL
endif
if LANG = LANG_EN
:R5T01			b "SYSTEM-INFO",NULL

:R5T01a			w RPos3_x +$10
			b RPos5_y +RLine5_1 +$06
			b "Active tasks",NULL

:R5T02			b "DESKACCESSORY",NULL

:R5T02a			w RPos5_x +RTab5_5 +$10
			b RPos5_y +RLine5_1 +$06
			b "Wallpaper",NULL

:R5T03			b "DEFAULT VIEWMODE",NULL

:R5T04			w RPos5_x +$10
			b RPos5_y +RLine5_2 +$06
			b "Text mode",NULL

:R5T04a			w RPos5_x +RTab5_4 +$10
			b RPos5_y +RLine5_2 +$06
			b "Display KByte",NULL

:R5T05			w RPos5_x +$10 ;+$10
			b RPos5_y +RLine5_3 +$06
			b "Details",NULL

:R5T05a			w RPos5_x +RTab5_4 -$1e
			b RPos5_y +RLine5_3 +$06
			b "Sort:",NULL

:R5T06			b "TWO-WINDOW-MODE",NULL

:R5T07			w RPos5_x +$10
			b RPos5_y +RLine5_4 +$06
			b "Enabled",NULL

:R5T08			w RPos5_x +RTab5_2 -$40
			b RPos5_y +RLine5_4 +$06
			b "Window #1",NULL

:R5T09			w RPos5_x +RTab5_3 -$10
			b RPos5_y +RLine5_4 +$06
			b "#2",NULL
endif

;*** Daten für Register "HOT CORNERS".
:RPos6_x  = R1SizeX0 +$10
:RPos6_y  = R1SizeY0 +$10
:RTab6_1  = $0000
:RTab6_2  = $0018
:RTab6_3  = $0028
:RTab6_4  = $0040
:RLine6_1 = $00
:RLine6_2 = $18
:RLine6_3 = $30
:RLine6_4 = $48

:RegTMenu6		b 38

			b BOX_FRAME
				w R6T01
				w $0000
				b RPos6_y +RLine6_1 -5
				b R1SizeY1 -6
				w R1SizeX0 +8
				w R1SizeX1 -8
			b BOX_ICON_VIEW
				w $0000
				w $0000
				b RPos6_y +RLine6_1
				w RPos6_x +RTab6_1 +16
				w RIcon_Header
				b NO_OPT_UPDATE

;--- 1
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_1 -1
				b RPos6_y +RLine6_1 +16
				w RPos6_x +RTab6_1 -1
				w RPos6_x +RTab6_1 +16
			b BOX_ICON_VIEW
				w $0000
				w $0000
				b RPos6_y +RLine6_1
				w RPos6_x +RTab6_1
				w RIcon_HOTC1
				b NO_OPT_UPDATE
			b BOX_OPTION
				w $0000
				w initHCmode1
				b RPos6_y +RLine6_1 +8
				w RPos6_x +RTab6_2
				w GD_HC_CFG1
				b %10000000
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_1 +8 -1
				b RPos6_y +RLine6_1 +16
				w RPos6_x +RTab6_3 -1
				w RPos6_x +RTab6_3 +2*8
::u01a			b BOX_NUMERIC
				w $0000
				w $0000
				b RPos6_y +RLine6_1 +8
				w RPos6_x +RTab6_3
				w GD_HC_TIMER1
				b 1!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setHCtimer1
				b RPos6_y +RLine6_1 +8
				w RPos6_x +RTab6_3 +8
				w RIcon_UpDown
				b (:u01a - RegTMenu6 -1)/11 +1
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_1 +8 -1
				b RPos6_y +RLine6_1 +16
				w RPos6_x +RTab6_4 -1
				w RPos6_x +RTab6_4 +16*8 +8
:u01b			b BOX_STRING
				w $0000
				w $0000
				b RPos6_y +RLine6_1 +8
				w RPos6_x +RTab6_4
				w regMenAction1
				b 16
			b BOX_ICON
				w $0000
				w setHCmode1
				b RPos6_y +RLine6_1 +8
				w RPos6_x +RTab6_4 +16*8
				w RIcon_UpDown
				b (u01b - RegTMenu6 -1)/11 +1

;--- 2
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_2 -1
				b RPos6_y +RLine6_2 +16
				w RPos6_x +RTab6_1 -1
				w RPos6_x +RTab6_1 +16
			b BOX_ICON_VIEW
				w $0000
				w $0000
				b RPos6_y +RLine6_2
				w RPos6_x +RTab6_1
				w RIcon_HOTC2
				b NO_OPT_UPDATE
			b BOX_OPTION
				w $0000
				w initHCmode2
				b RPos6_y +RLine6_2 +8
				w RPos6_x +RTab6_2
				w GD_HC_CFG2
				b %10000000
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_2 +8 -1
				b RPos6_y +RLine6_2 +16
				w RPos6_x +RTab6_3 -1
				w RPos6_x +RTab6_3 +2*8
::u02a			b BOX_NUMERIC
				w $0000
				w $0000
				b RPos6_y +RLine6_2 +8
				w RPos6_x +RTab6_3
				w GD_HC_TIMER2
				b 1!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setHCtimer2
				b RPos6_y +RLine6_2 +8
				w RPos6_x +RTab6_3 +8
				w RIcon_UpDown
				b (:u02a - RegTMenu6 -1)/11 +1
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_2 +8 -1
				b RPos6_y +RLine6_2 +16
				w RPos6_x +RTab6_4 -1
				w RPos6_x +RTab6_4 +16*8 +8
:u02b			b BOX_STRING
				w $0000
				w $0000
				b RPos6_y +RLine6_2 +8
				w RPos6_x +RTab6_4
				w regMenAction2
				b 16
			b BOX_ICON
				w $0000
				w setHCmode2
				b RPos6_y +RLine6_2 +8
				w RPos6_x +RTab6_4 +16*8
				w RIcon_UpDown
				b (u02b - RegTMenu6 -1)/11 +1

;--- 3
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_3 -1
				b RPos6_y +RLine6_3 +16
				w RPos6_x +RTab6_1 -1
				w RPos6_x +RTab6_1 +16
			b BOX_ICON_VIEW
				w $0000
				w $0000
				b RPos6_y +RLine6_3
				w RPos6_x +RTab6_1
				w RIcon_HOTC3
				b NO_OPT_UPDATE
			b BOX_OPTION
				w $0000
				w initHCmode3
				b RPos6_y +RLine6_3 +8
				w RPos6_x +RTab6_2
				w GD_HC_CFG3
				b %10000000
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_3 +8 -1
				b RPos6_y +RLine6_3 +16
				w RPos6_x +RTab6_3 -1
				w RPos6_x +RTab6_3 +2*8
::u03a			b BOX_NUMERIC
				w $0000
				w $0000
				b RPos6_y +RLine6_3 +8
				w RPos6_x +RTab6_3
				w GD_HC_TIMER3
				b 1!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setHCtimer3
				b RPos6_y +RLine6_3 +8
				w RPos6_x +RTab6_3 +8
				w RIcon_UpDown
				b (:u03a - RegTMenu6 -1)/11 +1
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_3 +8 -1
				b RPos6_y +RLine6_3 +16
				w RPos6_x +RTab6_4 -1
				w RPos6_x +RTab6_4 +16*8 +8
:u03b			b BOX_STRING
				w $0000
				w $0000
				b RPos6_y +RLine6_3 +8
				w RPos6_x +RTab6_4
				w regMenAction3
				b 16
			b BOX_ICON
				w $0000
				w setHCmode3
				b RPos6_y +RLine6_3 +8
				w RPos6_x +RTab6_4 +16*8
				w RIcon_UpDown
				b (u03b - RegTMenu6 -1)/11 +1

;--- 4
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_4 -1
				b RPos6_y +RLine6_4 +16
				w RPos6_x +RTab6_1 -1
				w RPos6_x +RTab6_1 +16
			b BOX_ICON_VIEW
				w $0000
				w $0000
				b RPos6_y +RLine6_4
				w RPos6_x +RTab6_1
				w RIcon_HOTC4
				b NO_OPT_UPDATE
			b BOX_OPTION
				w $0000
				w initHCmode4
				b RPos6_y +RLine6_4 +8
				w RPos6_x +RTab6_2
				w GD_HC_CFG4
				b %10000000
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_4 +8 -1
				b RPos6_y +RLine6_4 +16
				w RPos6_x +RTab6_3 -1
				w RPos6_x +RTab6_3 +2*8
::u04a			b BOX_NUMERIC
				w $0000
				w $0000
				b RPos6_y +RLine6_4 +8
				w RPos6_x +RTab6_3
				w GD_HC_TIMER4
				b 1!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setHCtimer4
				b RPos6_y +RLine6_4 +8
				w RPos6_x +RTab6_3 +8
				w RIcon_UpDown
				b (:u04a - RegTMenu6 -1)/11 +1
			b BOX_FRAME
				w $0000
				w $0000
				b RPos6_y +RLine6_4 +8 -1
				b RPos6_y +RLine6_4 +16
				w RPos6_x +RTab6_4 -1
				w RPos6_x +RTab6_4 +16*8 +8
:u04b			b BOX_STRING
				w $0000
				w $0000
				b RPos6_y +RLine6_4 +8
				w RPos6_x +RTab6_4
				w regMenAction4
				b 16
			b BOX_ICON
				w $0000
				w setHCmode4
				b RPos6_y +RLine6_4 +8
				w RPos6_x +RTab6_4 +16*8
				w RIcon_UpDown
				b (u04b - RegTMenu6 -1)/11 +1

;*** Texte für Register "DESKTOP".
if LANG = LANG_DE
:R6T01			b "AKTIONEN",NULL

endif

if LANG = LANG_EN
:R6T01			b "ACTIONS",NULL

endif

;*** Daten für Register "MICROMYS".
:RPos7_x  = R1SizeX0 +$10
:RPos7_y  = R1SizeY0 +$10
:RTab7_1  = $0000
:RTab7_2  = $0048
:RTab7_3  = $00a8
:RLine7_1 = $00
:RLine7_2 = $40
:RLine7_3 = $50

:RegTMenu7		b 12

			b BOX_FRAME
				w R7T01
				w doInitSysInfo
				b RPos7_y +RLine7_1 -$05
				b RPos7_y +RLine7_2 -$05 -$10
				w R1SizeX0 +8
				w R1SizeX1 -8

			b BOX_OPTION
				w R7T02
				w $0000
				b RPos7_y +RLine7_1
				w RPos7_x +RTab7_1
				w GD_MWHEEL
				b %10000000

;--- Up/Down:
			b BOX_FRAME
				w R7T05
				w $0000
				b RPos7_y +RLine7_2 -$05
				b R1SizeY1 -6
				w R1SizeX0 +8
				w R1SizeX1 -8

;--- Up:
			b BOX_FRAME
				w $0000
				w $0000
				b RPos7_y +RLine7_2 -1
				b RPos7_y +RLine7_2 +8
				w RPos7_x +RTab7_2 -1
				w RPos7_x +RTab7_2 +9*8 +8
:u07a			b BOX_STRING_VIEW
				w R7T03
				w $0000
				b RPos7_y +RLine7_2
				w RPos7_x +RTab7_2
				w regMenMMUp
				b 9
			b BOX_ICON
				w $0000
				w setWheelUp
				b RPos7_y +RLine7_2
				w RPos7_x +RTab7_2 +9*8
				w RIcon_Select
				b (u07a - RegTMenu7 -1)/11 +1

;--- Down:
			b BOX_FRAME
				w $0000
				w $0000
				b RPos7_y +RLine7_3 -1
				b RPos7_y +RLine7_3 +8
				w RPos7_x +RTab7_2 -1
				w RPos7_x +RTab7_2 +9*8 +8
:u07b			b BOX_STRING_VIEW
				w R7T04
				w $0000
				b RPos7_y +RLine7_3
				w RPos7_x +RTab7_2
				w regMenMMDown
				b 9
			b BOX_ICON
				w $0000
				w setWheelDown
				b RPos7_y +RLine7_3
				w RPos7_x +RTab7_2 +9*8
				w RIcon_Select
				b (u07b - RegTMenu7 -1)/11 +1

;--- Delay:
			b BOX_FRAME
				w $0000
				w $0000
				b RPos7_y +RLine7_3 -1
				b RPos7_y +RLine7_3 +8
				w RPos7_x +RTab7_3 -1
				w RPos7_x +RTab7_3 +2*8
::u07c			b BOX_NUMERIC
				w R7T06
				w $0000
				b RPos7_y +RLine7_3
				w RPos7_x +RTab7_3
				w regMMDelay
				b 1!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setWheelDelay
				b RPos7_y +RLine7_3
				w RPos7_x +RTab7_3 +8
				w RIcon_UpDown
				b (:u07c - RegTMenu7 -1)/11 +1

;*** Daten für Register "MICROMYS".
if LANG = LANG_DE
:R7T01			b "MICROMYS-PROTOKOLL",NULL
:R7T02			w RPos7_x +$0c
			b RPos7_y +RLine7_1 +$06
			b "Mausrad aktivieren"

			b GOTOXY
			w RPos7_x
			b RPos7_y +RLine7_1 +$06 +18
			b "Nur im Fenster-Modus unterstützt!"

			b GOTOXY
			w RPos7_x
			b RPos7_y +RLine7_1 +$06 +18 +10
			b "SuperCPU/TC64 empfohlen!"
			b NULL

:R7T03			w RPos7_x
			b RPos7_y +RLine7_2 +$06
			b "Aufwärts:",NULL
:R7T04			w RPos7_x
			b RPos7_y +RLine7_3 +$06
			b "Abwärts:",NULL
:R7T05			b "FUNKTIONEN",NULL
:R7T06			w RPos7_x +RTab7_3
			b RPos7_y +RLine7_2 +$06
			b "Pause:",NULL
endif
if LANG = LANG_EN
:R7T01			b "MICROMYS PROTOCOL",NULL
:R7T02			w RPos7_x +$0c
			b RPos7_y +RLine7_1 +$06
			b "Enable mouse wheel"

			b GOTOXY
			w RPos7_x
			b RPos7_y +RLine7_1 +$06 +18
			b "Only supported in window mode!"

			b GOTOXY
			w RPos7_x
			b RPos7_y +RLine7_1 +$06 +18 +10
			b "SuperCPU/TC64 recommended!",NULL

:R7T03			w RPos7_x
			b RPos7_y +RLine7_2 +$06
			b "Move up:",NULL
:R7T04			w RPos7_x
			b RPos7_y +RLine7_3 +$06
			b "Move down:",NULL
:R7T05			b "FUNCTIONS",NULL
:R7T06			w RPos7_x +RTab7_3
			b RPos7_y +RLine7_2 +$06
			b "Delay:",NULL
endif

;*** Daten für Register "DEBUG".
if DEBUG_SYSINFO = TRUE
:RPos9_x  = R1SizeX0 +$10
:RPos9_y  = R1SizeY0 +$10
:RLine9_1 = $00
:RLine9_2 = $18

:RegTMenu9		b 7

;--- System-Speicherbänke.
			b BOX_FRAME
				w R9T01
				w doInitRAMInfo
				b RPos9_y -$05
				b R1SizeY1 -$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW
				w R9T01a
				w $0000
				b RPos9_y +RLine9_1
				w RPos9_x
				w bankSys
				b $02
			b BOX_STRING_VIEW
				w R9T01b
				w $0000
				b RPos9_y +RLine9_1
				w RPos9_x +$40
				w bankData
				b $02
			b BOX_STRING_VIEW
				w R9T01d
				w $0000
				b RPos9_y +RLine9_1
				w RPos9_x +$78
				w bankCache
				b $02

;--- GeoDesk-Speicherbank-Belegung.
:u09a			b BOX_STRING_VIEW
				w $0000
				w prntVlirInfo
				b RPos9_y +RLine9_2
				w RPos9_x
				w bankGDesk1
				b $02
			b BOX_ICON
				w $0000
				w SwapBankGD
				b RPos9_y +RLine9_2
				w RPos9_x +16
				w RIcon_Select
				b (u09a - RegTMenu9 -1)/11 +1
			b BOX_FRAME
				w $0000
				w prntVlirInfo
				b RPos9_y +RLine9_2 -1
				b RPos9_y +RLine9_2 +8
				w RPos9_x -1
				w RPos9_x +16 +8

endif

;*** Texte für Register "DEBUG".
if DEBUG_SYSINFO ! LANG = TRUE ! LANG_DE
:R9T01			b "RESERVIERTER SPEICHER"
			b GOTOXY
			w RPos9_x
			b RPos9_y +RLine9_2 -4
			b "VLIR-MODULE IN GEODESK-RAM",NULL

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
:R9T01			b "RESERVED MEMORY"
			b GOTOXY
			w RPos9_x
			b RPos9_y +RLine9_2 -4
			b "VLIR-MODULES IN GDESK-RAM",NULL

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

;*** DeskAccessory: Neu laden.
;Nach dem starten eines DA den Inhalt
;von keinem, dem obersten oder von
;allen Fenstern neu laden.
:switchReloadDA		bit	r1L			;Register-Menü aufbauen?
			bpl	updateReloadDA		; => Ja, weite...

			lda	GD_DA_UPD_DIR		;Aktuellen Modus einlesen und
			bne	:1			;auf nächsten Modus wechseln.
			lda	#$7f			; => Nur oberstes Fenster.
			bne	:3
::1			bmi	:2
			lda	#$ff			; => Alle Fenster aktualisieren.
			bne	:3
::2			lda	#$00			; => Nichts aktualisieren.
::3			sta	GD_DA_UPD_DIR

;*** DeskAccessory: Status anzeigen.
;RegisterMenü / Tri-State-Option.
:updateReloadDA		lda	GD_DA_UPD_DIR		;Aktuellen Modus einlesen.
			beq	:off
			bmi	:all

::top			lda	#$02			; => Nur oberstes Fenster.
			b $2c
::all			lda	#$01			; => Alle Fenster aktualisieren.
			b $2c
::off			lda	#$00			; => Nichts aktualisieren.
			jsr	SetPattern		;Füllmuster setzen.

			jsr	i_Rectangle		;Tri-State-Option anzeigen.
			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +6
			w RPos1_x +1
			w RPos1_x +6

			rts

;*** Laufwerk #1/#2 für DualWin-Modus ändern.
:setDualWin1		ldx	#$00			;Fenster #1.
			b $2c
:setDualWin2		ldx	#$01			;Fenster #2.

			lda	GD_DUALWIN_DRV1,x	;Laufwerk Fenster #1/#2 einlesen.

;--- Zeiger auf nächstes Laufwerk.
::1			clc				;Zeiger auf nächstes Laufwerk.
			adc	#$01

			cmp	#4			;Laufwerk #4 erreicht?
			bcc	:2			; => Nein, weiter...
			lda	#$00			;Auf erstes Laufwerk zurücksetzen.

::2			cmp	GD_DUALWIN_DRV1,x	;Alle Laufwerke getestet?
			beq	:exit			; => Ja, Ende.

			tay
			lda	driveType,y		;Laufwerk verfügbar?
			beq 	:1			; => Nein, weiter...

			tya
			sta	GD_DUALWIN_DRV1,x	;Neues Laufwerk speichern.

			pha

			txa				;Fensterdaten einlesen:
			bne	:3

			lda	#< drvWin1Text		;Register-Option Laufwerk #1.
			ldy	#> drvWin1Text
			bne	:4

::3			lda	#< drvWin2Text		;Register-Option Laufwerk #1.
			ldy	#> drvWin2Text

::4			sta	r14L			;Zeiger auf Register-Option
			sty	r14H			;speichern.

			pla

			clc				;Neuen Laufwerksbuchstaben
			adc	#"A"			;speichern.
			ldy	#$00
			sta	(r14L),y

			bit	GD_DUALWIN_MODE		;Zwei-Fenster-Modus bereits aktiv?
			bmi	:exit			; => Ja, Ende...

			lda	#$ff			;Zwei-Fenster-Modus aktivieren.
			sta	GD_DUALWIN_MODE

			LoadW	r15,upd2WinMode
			jsr	RegisterUpdate		;Register-Menü aktualisieren.

::exit			rts

:drvWin1Text		b "A:",NULL
:drvWin2Text		b "A:",NULL

;*** Sortiermodus setzen.
:setSortMode		lda	GD_STD_SORTMODE		;Auf nächsten Sortiermodus
			clc				;wechseln...
			adc	#$01
			cmp	#$07
			bcc	:1
			lda	#$00
::1			sta	GD_STD_SORTMODE

;*** Sortiermodus in Text wandeln.
:defSortModTx		lda	GD_STD_SORTMODE
			asl
			tax
			lda	sortModTxTab+0,x
			sta	r0L
			lda	sortModTxTab+1,x
			sta	r0H

			LoadW	r1,sortModeText
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Sortiermodus.
:sortModeText		s 20
:sortModTxTab		w sortMode0
			w sortMode1
			w sortMode2
			w sortMode3
			w sortMode4
			w sortMode5
			w sortMode6

;*** Texte für Sortiermodus.
;Hinweis:
;Max. 20 Zeichen da Puffer begrenzt.
;Aktuell Max. 14 wegen Register-Menu.
if LANG = LANG_DE
:sortMode0		b "Unsortiert",NULL
:sortMode1		b "Dateiname",NULL
:sortMode2		b "Dateigröße",NULL
:sortMode3		b "Datum Alt->Neu",NULL
:sortMode4		b "Datum Neu->Alt",NULL
:sortMode5		b "Dateityp",NULL
:sortMode6		b "GEOS-Dateityp",NULL
endif
if LANG = LANG_EN
:sortMode0		b "Unsorted",NULL
:sortMode1		b "File name",NULL
:sortMode2		b "File size",NULL
:sortMode3		b "Date old->new",NULL
:sortMode4		b "Date new->old",NULL
:sortMode5		b "File type",NULL
:sortMode6		b "GEOS-File type",NULL
endif

;*** Anzeigemodus definieren.
:defViewMode		lda	GD_STD_TEXTMODE		;Detail-Modus bereits aktiv?
			beq	:1			; => Nein, Ende...

;			lda	#$ff			;Text-Modus aktivieren.
			sta	GD_STD_VIEWMODE

			LoadW	r15,updViewMode
			jsr	RegisterUpdate		;Register-Menü aktualisieren.

::1			rts

;*** Wheel-Modus in Text wandeln.
:defWheelModTx		lda	GD_MWHEEL
			and	#%00000011
			ldx	#< regMenMMUp
			ldy	#> regMenMMUp
			jsr	:mode

			lda	GD_MWHEEL
			and	#%00001100
			lsr
			lsr

			cmp	#%00000011
			bne	:1
			lda	#%00000100

::1			ldx	#< regMenMMDown
			ldy	#> regMenMMDown

::mode			stx	r1L
			sty	r1H

			asl
			tax
			lda	tabMicroMys +0,x
			sta	r0L
			lda	tabMicroMys +1,x
			sta	r0H

			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Wheel-Modus: Up.
:setWheelUp		lda	regMMDelay
			asl
			asl
			asl
			asl
			sta	r0H

			lda	GD_MWHEEL
			pha
			and	#%11111100
			sta	r0L
			pla
			clc
			adc	#$01
			and	#%00000011
			ora	r0L
			ora	r0H
			sta	GD_MWHEEL
			jsr	defWheelModTx

;			LoadW	r15,u07a
;			jsr	RegisterUpdate		;Register-Menü aktualisieren.

			rts

;*** Wheel-Modus: Down.
:setWheelDown		lda	regMMDelay
			asl
			asl
			asl
			asl
			sta	r0H

			lda	GD_MWHEEL
			pha
			and	#%11110011
			sta	r0L
			pla
			lsr
			lsr
			clc
			adc	#$01
			and	#%00000011
			asl
			asl
			ora	r0L
			ora	r0H
			sta	GD_MWHEEL
			jsr	defWheelModTx

;			LoadW	r15,u07b
;			jsr	RegisterUpdate		;Register-Menü aktualisieren.

			rts

;*** Verzögerung für Mausrad einlesen.
:defWheelDelay		lda	GD_MWHEEL
			and	#%00110000
			lsr
			lsr
			lsr
			lsr
			sta	regMMDelay
			rts

;*** Verzögerung definieren.
:setWheelDelay		ldx	regMMDelay

			lda	mouseYPos		;Position Mauszeiger einlesen.
			and	#%00000111		;Up/Down?
			cmp	#4			; Y>=4?
			bcs	:down			; => Ja, runterzählen...

::up			inx
			cpx	#$04
			bcc	:set
			ldx	#$00
			beq	:set

::down			dex
			bpl	:set
			ldx	#$03

::set			stx	regMMDelay
			txa
			asl
			asl
			asl
			asl
			sta	r0H

			lda	GD_MWHEEL
			and	#%11001111
			ora	r0H
			sta	GD_MWHEEL

;			LoadW	r15,u07c
;			jsr	RegisterUpdate		;Register-Menü aktualisieren.

			rts

;*** Icon-Cache ein-/ausschalten.
:setupIconCache		bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:disable_cache

			jsr	DACC_FIND_BANK		;64K für Icon-Daten.
			cpx	#NO_ERROR		;Speicher gefunden?
			beq	:icon_cache		; => Ja, weiter...

			LoadW	r0,Dlg_RamCacheErr
			jsr	DoDlgBox		;Fehler: Kein Speicher frei.

			lda	#$00			;Kein Icon-Cache aktiv.
			sta	GD_ICON_CACHE

			LoadW	r15,RegTMenu1a		;Register-Option aktialisieren.
			jsr	RegisterUpdate

;--- Icon-Cache ausschalten.
::disable_cache		lda	GD_ICONDATA_BUF		;Speicher für Icon-Cache belegt?
			beq	:1			; => Nein, weiter...
			jsr	DACC_FREE_BANK 		;Speicher freigeben.

			lda	#$00			;Kein Icon-Cache aktiv.
			sta	GD_ICONDATA_BUF

::1			jmp	setReloadDir		;Dateien von Disk neu einlesen.

;--- icon-Cache einschalten.
::icon_cache		tya
			sta	GD_ICONDATA_BUF
			ldx	#%01000000		;Bank-Typ: Anwendung.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

;--- Alle Dateien neu einlesen.
;Damit wird ggf. der Status "Icon im Cache" gelöscht.
::continue		jmp	setReloadDir		;Dateien von Disk neu einlesen.

;*** Nicht genügend freier Speicher.
:Dlg_RamCacheErr	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$30
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Nicht genügend Speicher frei!",NULL
::3			b "Für den Icon-Cache werden 64Kb",NULL
::4			b "freier DACC-Speicher benötigt.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Not enough free GEOS memory!",NULL
::3			b "64Kb free DACC memory is",NULL
::4			b "required for the icon cache.",NULL
endif

;*** Systeminformationen aufbereiten.
;Angaben für Registerkarte "INFO".
;Weitere Angaben werden aus ":-SYS_VAR"
;direkt über Registerkarte angezeigt.
:doInitSysInfo		lda	BootDrive		;Startlaufwerk nach ASCII wandeln.
			clc
			adc	#"A" -8
			sta	infoBootDrive

			lda	BootType		;RealDrvType.
			jsr	HEX2ASCII
			stx	infoBootType +0
			sta	infoBootType +1

			lda	BootMode		;RealDrvMode.
			jsr	HEX2ASCII
			stx	infoBootMode +0
			sta	infoBootMode +1
			rts

;*** Variablen.
:infoBootDrive		b "x:",NULL
:infoBootType		b "XX",NULL
:infoBootMode		b "XX",NULL

;*** HotCorner-Daten einlesen.
:setHCmodes		ldx	#0
::1			txa
			jsr	initCurHCmode		;Aktions-Text initialisieren.
			inx
			cpx	#4			;Alle HotCorner bearbeitet?
			bcc	:1			; => Nein, weiter...
			rts

;*** HotCorner-Timer setzen.
:setHCtimer1		ldy	#0			;Oben/links.
			b $2c
:setHCtimer2		ldy	#1			;Oben/rechts.
			b $2c
:setHCtimer3		ldy	#2			;Unten/links.
			b $2c
:setHCtimer4		ldy	#3			;Unten/rechts.
			lda	mouseYPos		;Position Mauszeiger einlesen.
			and	#%00000111		;Up/Down?
			cmp	#4			; Y>=4?
			bcs	:down			; => Ja, runterzählen...

::up			lda	GD_HC_TIMER1,y		;Timer einlesen.
			clc
			adc	#1			;Timer korrigieren.
			cmp	#4			; > 3sec ?
			bcc	:u1			; => Nein, weiter...
			lda	#1			;Auf min. zurücksetzen.
::u1			sta	GD_HC_TIMER1,y		;Neuen Timer-Wert speichern.
			rts

::down			lda	GD_HC_TIMER1,y		;Timer einlesen.
			sec
			sbc	#1			;Timer korrigieren.
			bne	:d1			; => Nein, weiter...
			lda	#3			;Auf min. zurücksetzen.
::d1			sta	GD_HC_TIMER1,y		;Neuen Timer-Wert speichern.
			rts

;*** HotCorner-Aktion setzen.
:setHCmode1		ldy	#0			;Oben/links.
			b $2c
:setHCmode2		ldy	#1			;Oben/rechts.
			b $2c
:setHCmode3		ldy	#2			;Unten/links.
			b $2c
:setHCmode4		ldy	#3			;Unten/rechts.
			ldx	GD_HC_CFG1,y		;HotCorner aktiv?
			bpl	setHCexit		; => Nein, Ende...

			lda	mouseYPos		;Position Mauszeiger einlesen.
			and	#%00000111		;Up/Down?
			cmp	#4			; Y>=4?
			bcs	:down			; => Ja, runterzählen...

::up			txa
			and	#%00000111		;Nur max. 8 Aktionen!
			clc
			adc	#1			;Zähler auf nächste Aktion.
			cmp	#maxHCActions		;Max. Anzahl Aktionen überschritten?
			bcc	:u1			; => Nein, weiter...
			lda	#0			;Auf erste Aktion zurücksetzen.
::u1			ora	#%10000000		;HotCorner als Aktiv setzen.
			sta	GD_HC_CFG1,y		;Neue Aktion speichern.
			bne	copyHCmode

::down			txa
			and	#%00000111		;Nur max. 8 Aktionen!
			sec
			sbc	#1			;Zähler auf vorherige Aktion.
			bpl	:d1			;Unterlauf? => Nein, weiter...
			lda	#maxHCActions -1	;Auf letzte Aktion zurücksetzen.
::d1			ora	#%10000000		;HotCorner als Aktiv setzen.
			sta	GD_HC_CFG1,y		;Neue Aktion speichern.

;*** Name für Aktion kopieren.
:copyHCmode		and	#%00000111		;Nur max. 8 Aktionen!
			asl				;Zeiger auf Aktions-Name berechnen.
			asl
			asl
			asl
			tax
			tya				;Zeiger auf Zwischenspeicher
			jsr	setVecHCtext		;berechnen.

			ldy	#0
::1			lda	tabActionNames,x	;Aktions-Name in Zwischenspeicher
			sta	(r0L),y			;kopieren.
			inx
			iny
			cpy	#16
			bcc	:1
:setHCexit		rts

;*** HotCorner-Aktionen initialisieren.
:initHCmode1		ldx	#0			;Oben/links.
			b $2c
:initHCmode2		ldx	#1			;Oben/rechts.
			b $2c
:initHCmode3		ldx	#2			;Unten/links.
			b $2c
:initHCmode4		ldx	#3			;Unten/rechts.

			lda	GD_HC_CFG1,x		;HotCorner-Aktion zurücksetzen:
;			and	#%10000000		; -> Auf erste Aktion.
			and	#%10000111		; -> Auf gültigen Wert.
			sta	GD_HC_CFG1,x

			jsr	initCurHCmode		;Aktions-Text initialisieren.

			lda	regMenOptions +0,x
			sta	r15L
			lda	regMenOptions +4,x
			sta	r15H
			jmp	RegisterUpdate		;Register-Menü aktualisieren.

;*** Aktions-Text initialisieren.
;Übergabe: XReg = HotCorner 0-3.
:initCurHCmode		lda	GD_HC_CFG1,x		;HotCorner aktiv?
			bmi	:1			; => Ja, weiter...

			txa				;Zeiger auf Zwischenspeicher
			jsr	setVecHCtext		;berechnen.

			ldy	#0
			tya
			sta	(r0L),y			;HotCorner-Aktion löschen.
			rts

::1			txa
			tay
			pha
			lda	GD_HC_CFG1,x		;HotCorner-Aktion einlesen.
			and	#%00000111		;Status-Bit %7 löschen.
			jsr	copyHCmode		;HotCorner-Name kopieren.
			pla
			tax
			rts

;*** Zeiger auf Aktions-Namen für Register-Menü.
:setVecHCtext		asl
			tay
			lda	regMenDataTab +0,y	;Zwischenspeicher für
			sta	r0L			;Aktions-Text festlegen.
			lda	regMenDataTab +1,y
			sta	r0H
			rts

;*** HotCorner-Daten.
:maxHCActions		= 6

;*** Namen für HotCorner-Aktionen.
:tabActionNames		b "ScreenSaver"
			e tabActionNames +16*1
if LANG = LANG_DE
			b "Fenster ein/aus"
endif
if LANG = LANG_EN
			b "Windows on/off"
endif
			e tabActionNames +16*2
			b "GD.Config"
			e tabActionNames +16*3
if LANG = LANG_DE
			b "GeoDesk-Optionen"
endif
if LANG = LANG_EN
			b "GeoDesk options"
endif
			e tabActionNames +16*4
if LANG = LANG_DE
			b "Arbeitsplatz"
endif
if LANG = LANG_EN
			b "My Computer"
endif
			e tabActionNames +16*5
if LANG = LANG_DE
			b "Hilfeseite"
endif
if LANG = LANG_EN
			b "Help page"
endif
			e tabActionNames +16*6

;*** Zwischenspeicher für Register-Menü.
:regMenAction1		s 17
:regMenAction2		s 17
:regMenAction3		s 17
:regMenAction4		s 17

;*** Zeiger auf Zwischenspeicher für Register-Menü.
:regMenDataTab		w regMenAction1
			w regMenAction2
			w regMenAction3
			w regMenAction4

;*** Zeiger auf Register-Optionen.
:regMenOptions		b < u01b
			b < u02b
			b < u03b
			b < u04b
			b > u01b
			b > u02b
			b > u03b
			b > u04b

;*** MicroMys-Daten.
:tabMicroMys		w regMenTx00
			w regMenTx01
			w regMenTx10
			w regMenTx11a
			w regMenTx11b

:regMenMMUp		s 17
:regMenMMDown		s 17

if LANG = LANG_DE
:regMenTx00		b "Drei Zeilen",NULL
:regMenTx01		b "Eine Zeile",NULL
:regMenTx10		b "Ganze Seite",NULL
:regMenTx11a		b "Zum Anfang",NULL
:regMenTx11b		b "Zum Ende",NULL
endif
if LANG = LANG_EN
:regMenTx00		b "Three lines",NULL
:regMenTx01		b "Single line",NULL
:regMenTx10		b "Full page",NULL
:regMenTx11a		b "To the top",NULL
:regMenTx11b		b "To the end",NULL
endif

:regMMDelay		b $00

;*** Debug-Informationen ausgeben.
if DEBUG_SYSINFO = TRUE
:doInitRAMInfo		lda	GD_SCRN_STACK		;64K: Bildschirmspeicher.
			jsr	HEX2ASCII
			stx	bankSys +0
			sta	bankSys +1

			lda	GD_SYSDATA_BUF		;64K: Systemspeicher.
			jsr	HEX2ASCII
			stx	bankData +0
			sta	bankData +1

			lda	GD_ICONDATA_BUF		;64K: Icon-Cache.
			jsr	HEX2ASCII
			stx	bankCache +0
			sta	bankCache +1

			ldx	bankPointer
			lda	GD_RAM_GDESK1,x		;64K: GeoDesk #1/#2.
			jsr	HEX2ASCII
			stx	bankGDesk1 +0
			sta	bankGDesk1 +1

			rts

;*** GeoDesk-Speicherbank wechseln.
:SwapBankGD		lda	bankPointer		;Zwischen Bank#1 und #2 umschalten.
			eor	#$01
			sta	bankPointer
			tax
			lda	GD_RAM_GDESK1,x		;64K: GeoDesk #1/#2.
			jsr	HEX2ASCII
			stx	bankGDesk1 +0
			sta	bankGDesk1 +1

			jmp	prntVlirInfo		;Modul-Daten anzeigen.
endif

;*** Debug-Info: GeoDesk-Speicher.
;Gibt Lage der VLIR-Module im GeoDesk-
;Speicher aus. Max. $0000-$FFFF.
;Wird der Wert überschritten, dann ist
;eine Anpassung der Speicherroutine
;und eine weitere 64K-Speicherbank
;erforderlich...
;
if DEBUG_SYSINFO = TRUE
:prntVlirInfo		lda	#$00			;Info-Bereich löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b RPos9_y +RLine9_2 -$01
			b R1SizeY1 -$06 -$01
			w R1SizeX0 +$08 +$24
			w R1SizeX1 -$08 -$01

			ldx	#$00
			stx	a0L			;Endadresse löschen.
			stx	a0H

			stx	r15H			;VLIR-Zähler löschen.
			dex
			stx	:lineCount		;Zeilenzähler initialisieren.

			LoadW	r14,$001c		;Erste Spalte.

::loop			ldx	r15H
			lda	GD_DACC_ADDR_B,x	;Modulnummer einlesen.
			beq	:next			; => Nicht vorhanden, weiter...
			ldy	bankPointer
			cmp	GD_RAM_GDESK1,y		;Innerhalb aktiver Speicherbank ?
			bne	:next			; => Nein, weiter...

			stx	:lastvlir		;Aktuelles VLIR-Modul merken.
			jsr	:printVLIR		;VLIR-Modul ausgeben.

			ldy	#$00			;Startadresse ausgeben.
			jsr	:printWord

			lda	r15L			;Zeiger auf nächste Zeile.
			clc
			adc	#$08
			sta	r15L

			inc	:lineCount		;Anzahl Zeilen +1.

::next			inc	r15H			;Zeiger auf nächstes VLIR-Modul.
			lda	r15H
			cmp	#GD_VLIR_COUNT		;Alle Module ausgegeben?
			bcc	:loop			; => Ja, Ende.

;--- Ausgabe Endadresse.
			lda	#$ff -1			;Letzte Speicheradresse ausgeben.
			sta	r15H			; => Modul = $FF.

			jsr	:printVLIR		;Dummy-VLIR-Modul ausgeben.

			lda	:lastvlir		;Zeiger auf letztes Modul.
			sta	r15H

			ldy	#$02			;Endadresse ausgeben.
			jsr	:printWord

			rts				;Ende.

::lineCount		b $00
::lastvlir		b $00

;--- VLIR-Modul ausgeben.
::printVLIR		lda	:lineCount		;Zeilenzähler einlesen.
			bmi	:11

			cmp	#$09			;Spalte voll?
			bcc	:12			; => Nein, weiter...

			AddVBW	$2c,r14			;Zeiger auf nächste Spalte.

::11			lda	#(RPos9_y +RLine9_2 +$06)
			sta	r15L			;Zeile auf Anfang.

			lda	#$00
			sta	:lineCount		;Zeilenzähler auf Anfang.

::12			lda	r14L			;X-Koordinate Spalte berechnen.
			clc
			adc	#< RPos9_x
			sta	r11L
			lda	r14H
			adc	#> RPos9_x
			sta	r11H

;			lda	r11H			;X-Positon zwischenspeichern.
			pha
			lda	r11L
			pha

			lda	r15L			;Y-Koordinate Zeile setzen.
			sta	r1H

			lda	r15H			;VLIR-Modul ausgeben.
			clc
			adc	#$01
			jsr	HEX2ASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			pla				;Position für ":" berechnen.
			clc
			adc	#< 11
			sta	r11L
			pla
			adc	#> 11
			sta	r11H

			lda	#":"
			jmp	SmallPutChar

;--- Start-/End-Adresse ausgeben.
::printWord		lda	r15H			;Zeiger auf Adress-Tabelle
			asl				;berechnen.
			asl
			tax
			cpy	#$00			;Start- oder Endadresse?
			bne	:1			; => Ende-Adresse...

			lda	GD_DACC_ADDR +0,x	;Startadresse einlesen.
			sta	r0L
			lda	GD_DACC_ADDR +1,x
			sta	r0H

;			lda	GD_DACC_ADDR +1,x	;Größere Startadresse gefunden?
			cmp	a0H
			bne	:cmp
			lda	GD_DACC_ADDR +0,x
			cmp	a0L
::cmp			bcc	:2			; => Nein, weiter...

			lda	r0L			;Startadresse für letztes Modul in
			sta	a0L			;Zwischenspeicher ablegen.
			lda	r0H
			sta	a0H
			lda	GD_DACC_ADDR +2,x	;Größe für letztes Modul in
			sta	a1L			;Zwischenspeicher ablegen.
			lda	GD_DACC_ADDR +3,x
			sta	a1H

			jmp	:2

::1			lda	a0L			;Startadresse + Größe =
			clc				;Endadresse berechnen.
			adc	a1L
			sta	r0L
			lda	a0H
			adc	a1H
			sta	r0H

			SubVW	1,r0			;Endadresse -1.

::2			PushB	r1H			;Register ":r1H" zwischenspeichern.

			LoadW	r1,:adr			;WORD nach ASCII wandeln.
			jsr	HEXW2ASCII

			PopB	r1H			;Register ":r1H" zurücksetzen.

			LoadW	r0,:adr
			jmp	PutString		;WORD/ASCII-Zahl ausgeben.

::adr			b "0000",NULL			;Zwischenspeicher.

;*** HEX-WORD nach ASCII konvertieren.
;    Übergabe: r0 = Hex-Zahl als WORD.
;    Rückgabe: r1 = 4 ASCII-zeichen für Hex-Zahl/WORD.
:HEXW2ASCII		lda	r0L			;LOW-Byte zwischenspeichern.
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

;*** Variablen.
:bankSys		b "00",NULL
:bankData		b "00",NULL
:bankCache		b "00",NULL
:bankGDesk1		b "00",NULL
:bankPointer		b $00
endif

;*** Einstellungen in Datei speichern.
:doSaveConfig		jsr	putGDINI_RAM		;GeoDesk-Optionen in DACC speichern.

			LoadW	r6,FNamGDINI
			jsr	FindFile		;GD.INI suchen.
			txa				;Datei gefunden?
			beq	:replace		; => Ja, weiter...

			cpx	#FILE_NOT_FOUND
			beq	:create			;Nicht vorhanden, speichern...
			jmp	:exit			; => Diskfehler, Abbruch...

::replace		LoadW	r0,FNamGDINI
			jsr	DeleteFile		;Vorhandene GD.INI löschen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

::create		LoadB	r10L,0
			LoadW	r9,HdrB000
			jsr	SaveFile		;Neue GD.INI erzeugen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

::1			lda	dirEntryBuf +1
			ldx	dirEntryBuf +2
			jsr	:readGDINI		;GDOS-Konfiguration einlesen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			PushB	r1L			;Sektor-Adresse zwischenspeichern.
			PushB	r1H

			lda	#< R3A_CFG_GDOS
			ldx	#> R3A_CFG_GDOS
			ldy	#R3S_CFG_GDOS
			jsr	:updateGDINI		;Konfiguration aktualisieren.

			PopB	r1H			;Sektor-Adresse zurücksetzen.
			PopB	r1L

			jsr	PutBlock		;Konfiguration speichern.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			ldx	#STRUCT_MISMAT
			lda	diskBlkBuf +0		;Sektor #2 verfügbar?
			beq	:exit			; => Nein, Fehler.
			ldx	diskBlkBuf +1
			jsr	:readGDINI		;GeoDesk-Konfiguration einlesen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			PushB	r1L			;Sektor-Adresse zwischenspeichern.
			PushB	r1H

			lda	#< R3A_CFG_GDSK
			ldx	#> R3A_CFG_GDSK
			ldy	#R3S_CFG_GDSK
			jsr	:updateGDINI		;Konfiguration aktualisieren.

			PopB	r1H			;Sektor-Adresse zurücksetzen.
			PopB	r1L

			jsr	PutBlock		;Konfiguration speichern.
;			txa				;Diskettenfehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;--- GD.INI-Block einlesen.
::readGDINI		sta	r1L
			stx	r1H

			LoadW	r4,diskBlkBuf
			jmp	GetBlock		;GDOS-Konfiguration einlesen.

;--- GD.INI-Daten einlesen.
::updateGDINI		sta	r1L
			stx	r1H

			sty	r2L
			lda	#$00
			sta	r2H

			lda	#< diskBlkBuf +2
			sta	r0L
			lda	#> diskBlkBuf +2
			sta	r0H

			lda	MP3_64K_DATA
			sta	r3L

			jmp	FetchRAM		;Konfiguration aktualisieren.

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w FNamGDINI
::002			b $03,$15
			b $bf
			b %10101010,%10101010,%10101011
			b %01010101,%01010101,%01010111
			b %10000000,%00000000,%00000011
			b %01001111,%00111110,%00000011
			b %10011000,%00110011,%00000011
			b %01011011,%10110011,%00000011
			b %10011001,%10110011,%00000011
			b %01001111,%10111110,%00000011
			b %10000000,%00000000,%00000011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01001000,%10100101,%00010011
			b %10001100,%10110101,%00110011
			b %01001100,%10101101,%00110011
			b %10001000,%10100101,%00010011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01111111,%11111111,%11111111
			b %11111111,%11111111,%11111111

::068			b $82				;PRG
			b SYSTEM			;GEOS-Systemdatei
			b $00				;GEOS-Dateityp SEQUENTIELL
			w GDA_OPTIONS			;Programm-Anfang
			w GDA_OPTIONS + 2*254		;Programm-Ende
			w $0000				;Programm-Start
::077			t "opt.INI.Build"		;Klasse/Version
			b $00				;Bildschirmflag
::097			b "GDOS64"			;Autor
			s 14				;Reserviert
			s 12  				;Anwendung/Klasse
			s 4  				;Anwendung/Version
			b NULL
			s 26				;Reserviert
::160			b NULL				;Infotext

;::HdrEnd		s (HdrB000+256)-:HdrEnd
:FNamGDINI		b "GD.INI",NULL

;*** Fehler: Fehler beim speichern.
:Dlg_SaveError		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$0c,$3a
			w :3
			b DBTXTSTR   ,$0c,$44
			w svErrorTxt
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Fehler beim speichern der GDOS64-",NULL
::2			b "Konfigurationsdatei `",BOLDON,"GD.INI"
			b PLAINTEXT,"` !",NULL
::3			b "Die Datei wurde nicht gespeichert!",NULL
:svErrorTxt		b "Fehler: $",BOLDON
:svErrorCode		b "xx",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "Error while saving the GDOS64",NULL
::2			b "configuration file `",BOLDON,"GD.INI"
			b PLAINTEXT,"` !",NULL
::3			b "The configuration file was not saved!",NULL
:svErrorTxt		b "Error: $",BOLDON
:svErrorCode		b "xx",NULL
endif

;*** Endadresse testen:
			g BASE_DIRDATA
;***
