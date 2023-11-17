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
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "SymbTab_GSPR"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.SCRN.ext"
endif

;*** GEOS-Header.
			n "GD.CONF.SCREEN"
			c "GDC.SCREEN  V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Anzeige konfigurieren"
endif
if LANG = LANG_EN
			h "Configure display"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts
;******************************************************************************
;*** Systemkennung.
;******************************************************************************
			b "GDCONF10"
;******************************************************************************

;*** Systemroutinen.
			t "-SYS_GTYPE_TXT"

;*** Programmroutinen.
			t "-GC_OpenFile"

;*** Menü initialisieren.
:InitMenu		bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	DoAppStart		; => Ja, keine Parameterübernahme.

;--- Hintergrundbild.
			lda	BackScrPattern
			sta	BootPattern

			lda	BootRAM_Flag
			and	#%11110111
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Modus für Hintergrundbild
			and	#%00001000		;aktualisieren.
			ora	BootRAM_Flag
			sta	BootRAM_Flag

;--- Farbeinstellungen.
			LoadW	r0,GD_PROFILE
			LoadW	r1,R3A_CPROFILE
			LoadW	r2,R3S_CPROFILE
			lda	MP3_64K_DATA
			sta	r3L
			jsr	FetchRAM		;Farbprofil laden.

			jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	COLVAR_BASE
			w	GD_COLOR_GEOS
			w	COLVAR_SIZE

			lda	BackScrPattern		;GEOS-Füllmuster übernehmen.
			sta	C_GEOS_PATTERN

			lda	C_Mouse			;Standardfarbe Mauszeiger überhmen.
			sta	C_GEOS_MOUSE

;--- Bildschirmschoner.
			jsr	SetScrSvOpt		;Bildschirmschoner-Optionen setzen.

			lda	Flag_ScrSvCnt		;Bildschirmschoner Verzögerung.
			sta	BootScrSvCnt
			lda	Flag_ScrSaver		;Bildschirmschoner ein/aus.
			sta	BootScrSaver

;			bit	BootScrSaver		;Bildschirmschoner aktiv?
			bmi	:1			; => Nein, kein Name einlesen.
			jsr	GetScrSvName		;Name Bildschirmschoner einlesen.

::1			jsr	SaveConfig		;Konfiguration übernehmen.

;*** Menü starten.
:DoAppStart		lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Aktuelle Konfiguration speichern.
:SaveConfig		lda	r14H			;"SPEICHERN" im Menü gewählt ?
			cmp	#CFG_MOD_SCREEN		; => Dann r14H = Modul = Screen.
			bne	updateColCfg

			lda	Flag_ScrSvCnt		;Bildschirmschoner Verzögerung.
			sta	BootScrSvCnt
			lda	Flag_ScrSaver		;Bildschirmschoner ein/aus.
			sta	BootScrSaver

			bit	BootSaveColors		;Farbprofil erstellen ?
			bpl	updateColCfg		; => Nein, weiter...

			lda	SystemDevice		;System-Laufwerk aktivieren.
			jsr	SetDevice
			txa				;Fehler ?
			bne	updateColCfg		; => Ja, Abbruch...

			lda	#< configColStd		;Zeiger auf Dateiname für
			sta	HdrB000 +0		;Standard-Farbprofil.
			lda	#> configColStd
			sta	HdrB000 +1

			jsr	doSvColorConfig		;Farbprofil speichern.

;*** Farbprofil in BootConfig speichern.
:updateColCfg		jsr	i_MoveData		;GEOS-Farben in Boot-Konfiguration
			w	GD_COLOR_GEOS		;übernehmen.
			w	BootColorGEOS
			w	COLVAR_SIZE

			jmp	e_UpdateColRAM		;Farbprofil in DACC speichern.

;*** Register-Menü.
:R1SizeY0		= $30
:R1SizeY1		= $bf
:R1SizeX0		= $0038
:R1SizeX1		= $0137

:RegisterTab		b R1SizeY0,R1SizeY1
			w R1SizeX0,R1SizeX1

			b 5				;Anzahl Einträge.

			w RegTName2			;Register: "Desktop".
			w RegTMenu2

			w RegTName1			;Register: "Bildschirmschoner".
			w RegTMenu1

			w RegTName3			;Register: "Farben".
			w RegTMenu3

			w RegTName4			;Register: "Icons".
			w RegTMenu4

			w RegTName5			;Register: "Optionen".
			w RegTMenu5

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RegCardIconX_1,$28
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
			b RegCardIconX_2,$28
			b RTabIcon2_x,RTabIcon2_y

:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

:RegTName3		w RTabIcon3
			b RegCardIconX_3,$28
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
			b RegCardIconX_4,$28
			b RTabIcon4_x,RTabIcon4_y

:RTabIcon4
<MISSING_IMAGE_DATA>

:RTabIcon4_x		= .x
:RTabIcon4_y		= .y

:RegTName5		w RTabIcon5
			b RegCardIconX_5,$28
			b RTabIcon5_x,RTabIcon5_y

if LANG = LANG_DE
:RTabIcon5
<MISSING_IMAGE_DATA>

:RTabIcon5_x		= .x
:RTabIcon5_y		= .y
endif

if LANG = LANG_EN
:RTabIcon5
<MISSING_IMAGE_DATA>

:RTabIcon5_x		= .x
:RTabIcon5_y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RegCardIconX_2		= $07
:RegCardIconX_1		= RegCardIconX_2 + RTabIcon2_x
:RegCardIconX_3		= RegCardIconX_1 + RTabIcon1_x
:RegCardIconX_4		= RegCardIconX_3 + RTabIcon3_x
:RegCardIconX_5		= RegCardIconX_4 + RTabIcon4_x

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= TRUE
:EnableMUpDown		= FALSE
:EnableMButton		= TRUE
endif
			t "-SYS_ICONS"

;*** System-Icons.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

:RIcon_SlctUp		w Icon_MSlctUp
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSlctUp_x,Icon_MSlctUp_y
			b USE_COLOR_INPUT

:RIcon_Button		w Icon_MButton
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MButton_x,Icon_MButton_y
			b USE_COLOR_INPUT

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

:RIcon_Load		w Icon_Load
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Load_x,Icon_Load_y
			b USE_COLOR_INPUT

:Icon_Load
<MISSING_IMAGE_DATA>

:Icon_Load_x		= .x
:Icon_Load_y		= .y

:RIcon_CBM		w Icon_CBM
			b %01000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_CBM_x,Icon_CBM_y
			b USE_COLOR_INPUT

:Icon_CBM
<MISSING_IMAGE_DATA>
:Icon_CBM_x		= .x
:Icon_CBM_y		= .y

;*** Daten für Register "BILDSCHIRMSCHONER".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$18
:RTab1_1  = $0018
:RTab1_2  = $0028
:RTab1_3  = $0020
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $50

:RegTMenu1		b 9

			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y -$08
				b R1SizeY1 -$10
				w R1SizeX0 +$08
				w R1SizeX1 -$08
			b BOX_USER
				w $0000
				w StartScrnSaver
				b RPos1_y +RLine1_1
				b RPos1_y +RLine1_1 +$08 -$01
				w RPos1_x +RTab1_1
				w RPos1_x +RTab1_1 +$80 -$01
:RegTMenu1a		b BOX_STRING_VIEW
				w R1T02
				w StartScrnSaver
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_2
				w BootSaverName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$08
				w RPos1_x +RTab1_2 +$80
				w RPos1_x +RTab1_2 +$80 +$08
			b BOX_ICON
				w $0000
				w GetNewScrSaver
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_2 +$80
				w RIcon_Select
				b (RegTMenu1a - RegTMenu1 -1)/11 +1

			b BOX_USER
				w R1T04
				w Swap_ScrSvDelay
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +$08 -$01
				w RPos1_x +RTab1_3 +$04
				w RPos1_x +RTab1_3 +$9c -$01

:RegTMenu1b		b BOX_OPTION
				w R1T05
				w Swap_ScrSaver
				b RPos1_y +RLine1_2
				w RPos1_x
				w Flag_ScrSaver
				b %10000000

:RegTMenu1c		b BOX_OPTION
				w R1T06
				w Swap_ScrSvMode
				b RPos1_y +RLine1_3
				w RPos1_x
				w Flag_ScrSvCnt
				b %10000000

;*** Texte für Register "BILDSCHIRMSCHONER".
if LANG = LANG_DE
:R1T01			b "BILDSCHIRMSCHONER",NULL
:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL
:R1T03			b PLAINTEXT
			b GOTOXY
			w RPos1_x +$68
			b RPos1_y +RLine1_4 -$18 +$0a
:R1T03a			b "00:00 MIN. ",NULL
:R1T04			w RPos1_x
			b RPos1_y +RLine1_4 -$18 +$0a
			b "Aktivierungszeit:"
			b GOTOXY
			w RPos1_x +RTab1_3 -$18
			b RPos1_y +RLine1_4 +$06
			b "<->"
			b GOTOX
			w RPos1_x +RTab1_3 +$a8
			b "<+>"
			b GOTOXY
			w RPos1_x +RTab1_3 -$09
			b RPos1_y +RLine1_4 -$08 +$06
			b "00:05"
			b GOTOX
			w RPos1_x +RTab1_3 +$24
			b "01:00"
			b GOTOX
			w RPos1_x +RTab1_3 +$53
			b "02:00"
			b GOTOX
			w RPos1_x +RTab1_3 +$83
			b "03:00",NULL

:R1T05			w RPos1_x +$08 +$06
			b RPos1_y +RLine1_2 +$06
			b "Bildschirmschoner deaktivieren",NULL
:R1T06			w RPos1_x +$08 +$06
			b RPos1_y +RLine1_3 +$06
			b "Nur manuell starten",NULL
endif
if LANG = LANG_EN
:R1T01			b "SCREENSAVER",NULL
:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL
:R1T03			b PLAINTEXT
			b GOTOXY
			w RPos1_x +$78
			b RPos1_y +RLine1_4 -$18 +$0a
:R1T03a			b "00:00 MIN. ",NULL
:R1T04			w RPos1_x
			b RPos1_y +RLine1_4 -$18 +$0a
			b "Delay screen saver:"
			b GOTOXY
			w RPos1_x +RTab1_3 -$18
			b RPos1_y +RLine1_4 +$06
			b "<->"
			b GOTOX
			w RPos1_x +RTab1_3 +$a8
			b "<+>"
			b GOTOXY
			w RPos1_x +RTab1_3 -$09
			b RPos1_y +RLine1_4 -$08 +$06
			b "00:05"
			b GOTOX
			w RPos1_x +RTab1_3 +$24
			b "01:00"
			b GOTOX
			w RPos1_x +RTab1_3 +$53
			b "02:00"
			b GOTOX
			w RPos1_x +RTab1_3 +$83
			b "03:00",NULL

:R1T05			w RPos1_x +$08 +$06
			b RPos1_y +RLine1_2 +$06
			b "Turn off screensaver",NULL
:R1T06			w RPos1_x +$08 +$06
			b RPos1_y +RLine1_3 +$06
			b "Manual start only",NULL
endif

;*** Daten für Register "DESKTOP".
:RPos2_x  = R1SizeX0 +$10
:RPos2_y  = R1SizeY0 +$18
:RTab2_1  = $0010
if LANG = LANG_DE
:RTab2_3  = $0070
endif
if LANG = LANG_EN
:RTab2_3  = $0078
endif
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $20
:RLine2_4 = $30
:RLine2_5 = $48

:RegTMenu2		b 10

;--- Hintergrundbild.
			b BOX_FRAME
				w R2T01
				w $0000
				b RPos2_y -$08
				b R1SizeY1 -$10
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R2T02
				w Swap_BackScrn
				b RPos2_y +RLine2_1
				w RPos2_x
				w BootRAM_Flag
				b %00001000

			b BOX_USER
				w $0000
				w PrintCurBackScrn
				b RPos2_y +RLine2_2
				b RPos2_y +RLine2_2 +$08 -$01
				w RPos2_x +RTab2_1
				w RPos2_x +RTab2_1 +$80 -$01
::u01			b BOX_STRING_VIEW
				w R2T02
				w $0000
				b RPos2_y +RLine2_2
				w RPos2_x +RTab2_1
				w BootGrfxFile
				b 16

			b BOX_FRAME
				w $0000
				w $0000
				b RPos2_y +RLine2_2 -$01
				b RPos2_y +RLine2_2 +$08
				w RPos2_x +RTab2_1 +$80
				w RPos2_x +RTab2_1 +$80 +$08
			b BOX_ICON
				w $0000
				w GetNewBackScrn
				b RPos2_y +RLine2_2
				w RPos2_x +RTab2_1 +$80
				w RIcon_Select
				b (:u01 - RegTMenu2 -1)/11 +1

			b BOX_OPTION
				w R2T03
				w $0000
				b RPos2_y +RLine2_3
				w RPos2_x +RTab2_1
				w BootGrfxRandom
				b %10000000
			b BOX_ICON
				w R2T04
				w NewRandomGrfx
				b RPos2_y +RLine2_3
				w RPos2_x +RTab2_3
				w RIcon_Button
				b (:u01 - RegTMenu2 -1)/11 +1

			b BOX_OPTION
				w R2T05
				w $0000
				b RPos2_y +RLine2_4
				w RPos2_x +RTab2_1
				w BootGrfxRandom
				b %01000000
			b BOX_OPTION
				w R2T06
				w $0000
				b RPos2_y +RLine2_4
				w RPos2_x +RTab2_3
				w BootGrfxRandom
				b %00100000

;*** Texte für Register "DESKTOP".
if LANG = LANG_DE
:R2T01			b "HINTERGRUNDBILD",NULL
:R2T02			w RPos2_x +RTab2_1
			b RPos2_y +RLine2_1 +$06
			b "Hintergrundbild aktiv",NULL
:R2T03			w RPos2_x +RTab2_1 +$08 +$06
			b RPos2_y +RLine2_3 +$06
			b "Zufallsmodus"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "HINWEIS:  Max. 16 Bilder möglich!"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_5 +$08 +$06
			b "Der Zufallsmodus verlangsamt den"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_5 +$10 +$06
			b "Start von GDOS64!",NULL
:R2T04			w RPos2_x +RTab2_3 +$08 +$06
			b RPos2_y +RLine2_3 +$06
			b "Neues Bild laden",NULL
:R2T05			w RPos2_x +RTab2_1 +$08 +$06
			b RPos2_y +RLine2_4 +$06
			b "Farbprofil"
			b GOTOXY
			w RPos2_x +RTab2_1 +$08 +$06
			b RPos2_y +RLine2_4 +$08 +$06
			b "anwenden",NULL
:R2T06			w RPos2_x +RTab2_3 +$08 +$06
			b RPos2_y +RLine2_4 +$06
			b "Standardfarben"
			b GOTOXY
			w RPos2_x +RTab2_3 +$08 +$06
			b RPos2_y +RLine2_4 +$08 +$06
			b "erzwingen",NULL
endif
if LANG = LANG_EN
:R2T01			b "BACKGROUND-IMAGE",NULL
:R2T02			w RPos2_x +RTab2_1
			b RPos2_y +RLine2_1 +$06
			b "Enable background images",NULL
:R2T03			w RPos2_x +RTab2_1 +$08 +$06
			b RPos2_y +RLine2_3 +$06
			b "Random mode"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "NOTE:  Max. 16 images supported!"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_5 +$08 +$06
			b "Enable random mode will slow down"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_5 +$10 +$06
			b "booting up GDOS64!",NULL
:R2T04			w RPos2_x +RTab2_3 +$08 +$06
			b RPos2_y +RLine2_3 +$06
			b "Load new image",NULL
:R2T05			w RPos2_x +RTab2_1 +$08 +$06
			b RPos2_y +RLine2_4 +$06
			b "Load matching"
			b GOTOXY
			w RPos2_x +RTab2_1 +$08 +$06
			b RPos2_y +RLine2_4 +$08 +$06
			b "color profile",NULL
:R2T06			w RPos2_x +RTab2_3 +$08 +$06
			b RPos2_y +RLine2_4 +$06
			b "Force default"
			b GOTOXY
			w RPos2_x +RTab2_3 +$08 +$06
			b RPos2_y +RLine2_4 +$08 +$06
			b "color profile",NULL
endif

;*** Daten für Register "Farben".
:RPos3_x  = R1SizeX0 +$10
:RPos3_y  = R1SizeY0 +$18
:RTab3_1  = $0028
:RTab3_2  = $0000
:RLine3_1 = $00
:RLine3_2 = $40
:RLine3_3 = $60
:RLine3_4 = $20

:RegTMenu3		b 15

			b BOX_FRAME
				w R3T01
				w $0000
				b RPos3_y -$08
				b RPos3_y +RLine3_1 +$28 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_FRAME
				w $0000
				w $0000
				b RPos3_y +RLine3_1 -$01
				b RPos3_y +RLine3_1 +$10
				w RPos3_x +RTab3_1 -$01
				w R1SizeX1 -$18 +$01
::u01			b BOX_USER
				w R3T02
				w PrintCurColName
				b RPos3_y +RLine3_1
				b RPos3_y +RLine3_1 +$10 -$01
				w RPos3_x +RTab3_1
				w R1SizeX1 -$18
			b BOX_FRAME
				w $0000
				w $0000
				b RPos3_y +RLine3_1 -$01
				b RPos3_y +RLine3_1 +$10
				w R1SizeX1 -$18 +$01
				w R1SizeX1 -$10 +$01
			b BOX_ICON
				w $0000
				w LastColEntry
				b RPos3_y +RLine3_1
				w R1SizeX1 -$18 +$01
				w RIcon_SlctUp
				b (:u01 - RegTMenu3  -1)/11 +1
			b BOX_ICON
				w $0000
				w NextColEntry
				b RPos3_y +RLine3_1 +$08
				w R1SizeX1 -$18 +$01
				w RIcon_Select
				b (:u01 - RegTMenu3  -1)/11 +1
			b BOX_ICON
				w R3T02a
				w ApplyColConfig
				b RPos3_y +RLine3_4
				w RPos3_x +RTab3_2
				w RIcon_Button
				b NO_OPT_UPDATE

;--- Farbe: Vordergrund.
			b BOX_FRAME
				w R3T03
				w $0000
				b RPos3_y +RLine3_2 -$08
				b RPos3_y +RLine3_2 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08
:RegTMenu3a		b BOX_USEROPT_VIEW
				w R3T04
				w PrintCurColorT
				b RPos3_y +RLine3_2
				b RPos3_y +RLine3_2 +$08 -$01
				w R1SizeX1 -$28 +$01
				w R1SizeX1 -$10
			b BOX_FRAME
				w $0000
				w $0000
				b RPos3_y +RLine3_2 -$01
				b RPos3_y +RLine3_2 +$08
				w RPos3_x +RTab3_1 -$01
				w RPos3_x +RTab3_1 +$80
			b BOX_USER
				w R3T04a
				w ColorInfoT
				b RPos3_y +RLine3_2
				b RPos3_y +RLine3_2 +$08 -$01
				w RPos3_x +RTab3_1
				w RPos3_x +RTab3_1 +$80 -$01

;--- Farbe: Hintergrund.
			b BOX_FRAME
				w R3T05
				w $0000
				b RPos3_y +RLine3_3 -$08
				b RPos3_y +RLine3_3 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08
:RegTMenu3b		b BOX_USEROPT_VIEW
				w R3T06
				w PrintCurColorB
				b RPos3_y +RLine3_3
				b RPos3_y +RLine3_3 +$08 -$01
				w R1SizeX1 -$28 +$01
				w R1SizeX1 -$10
			b BOX_FRAME
				w $0000
				w $0000
				b RPos3_y +RLine3_3 -$01
				b RPos3_y +RLine3_3 +$08
				w RPos3_x +RTab3_1 -$01
				w RPos3_x +RTab3_1 +$80
			b BOX_USER
				w R3T06a
				w ColorInfoB
				b RPos3_y +RLine3_3
				b RPos3_y +RLine3_3 +$08 -$01
				w RPos3_x +RTab3_1
				w RPos3_x +RTab3_1 +$80 -$01

;*** Texte für Register "Farben".
if LANG = LANG_DE
:R3T01			b "BEREICH",NULL

:R3T02			w RPos3_x
			b RPos3_y +RLine3_1 +$06
			b "Name:",NULL
:R3T02a			w RPos3_x +RTab3_2 +$08 +$06
			b RPos3_y +RLine3_4 +$06
			b "Aktuelle Farbauswahl anwenden",NULL

:R3T03			b "VORDERGRUND",NULL

:R3T04			w RPos3_x
			b RPos3_y +RLine3_2 +$06
			b "Farbe:",NULL

:R3T04a			w R1SizeX1 -$36
			b RPos3_y +RLine3_2 +$06
			b "->",NULL

:R3T05			b "HINTERGRUND",NULL

:R3T06			w RPos3_x
			b RPos3_y +RLine3_3 +$06
			b "Farbe:",NULL

:R3T06a			w R1SizeX1 -$36
			b RPos3_y +RLine3_3 +$06
			b "->",NULL
endif
if LANG = LANG_EN
:R3T01			b "AREA",NULL

:R3T02			w RPos3_x
			b RPos3_y +RLine3_1 +$06
			b "Name:",NULL
:R3T02a			w RPos3_x +RTab3_2 +$08 +$06
			b RPos3_y +RLine3_4 +$06
			b "Apply current color settings",NULL

:R3T03			b "FOREGROUND",NULL

:R3T04			w RPos3_x
			b RPos3_y +RLine3_2 +$06
			b "Color:",NULL

:R3T04a			w R1SizeX1 -$36
			b RPos3_y +RLine3_2 +$06
			b "->",NULL

:R3T05			b "BACKGROUND",NULL

:R3T06			w RPos3_x
			b RPos3_y +RLine3_3 +$06
			b "Color:",NULL

:R3T06a			w R1SizeX1 -$36
			b RPos3_y +RLine3_3 +$06
			b "->",NULL
endif

;*** Daten für Register "Datei-Icons".
:RPos4_x  = R1SizeX0 +$10
:RPos4_y  = R1SizeY0 +$18
:RTab4_1  = $0028
:RLine4_1 = $00
:RLine4_2 = $18
:RLine4_3 = $40
:RLine4_4 = $48

:RegTMenu4		b 9

			b BOX_FRAME
				w R4T01
				w $0000
				b RPos4_y -$08
				b RPos4_y +RLine4_2 +$10 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_FRAME
				w $0000
				w $0000
				b RPos4_y +RLine4_1 -$01
				b RPos4_y +RLine4_1 +$08
				w RPos4_x +RTab4_1 -$01
				w R1SizeX1 -$10 +$01
:RegTMenu4b		b BOX_USER
				w R4T02
				w PrintCurIColName
				b RPos4_y +RLine4_1
				b RPos4_y +RLine4_1 +$08 -$01
				w RPos4_x +RTab4_1
				w R1SizeX1 -$18
			b BOX_ICON
				w $0000
				w NextIColEntry
				b RPos4_y +RLine4_1
				w R1SizeX1 -$18 +$01
				w RIcon_Select
				b (RegTMenu4b - RegTMenu4  -1)/11 +1

:RegTMenu4a		b BOX_USEROPT_VIEW
				w R4T04
				w PrintCurIColor
				b RPos4_y +RLine4_2
				b RPos4_y +RLine4_2 +$08 -$01
				w R1SizeX1 -$28 +$01
				w R1SizeX1 -$10
			b BOX_FRAME
				w $0000
				w $0000
				b RPos4_y +RLine4_2 -$01
				b RPos4_y +RLine4_2 +$08
				w RPos4_x +RTab4_1 -$01
				w RPos4_x +RTab4_1 +$80
			b BOX_USER
				w R4T04a
				w ColorInfoI
				b RPos4_y +RLine4_2
				b RPos4_y +RLine4_2 +$08 -$01
				w RPos4_x +RTab4_1
				w RPos4_x +RTab4_1 +$80 -$01

;--- Vorschaubereich.
			b BOX_ICON_VIEW
				w $0000
				w $0000
				b RPos4_y +RLine4_4
				w R1SizeX1 -$28 +$01
				w RIcon_CBM
				b NO_OPT_UPDATE
			b BOX_FRAME
				w R4T05
				w setColPreview
				b RPos4_y +RLine4_3 -$05
				b R1SizeY1 -$10
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;*** Texte für Register "Datei-Icons".
if LANG = LANG_DE
:R4T01			b "DATEITYP",NULL

:R4T02			w RPos4_x
			b RPos4_y +RLine4_1 +$06
			b "Name:",NULL

:R4T03			b "ICON-FARBE",NULL

:R4T04			w RPos4_x
			b RPos4_y +RLine4_2 +$06
			b "Farbe:",NULL

:R4T04a			w R1SizeX1 -$36
			b RPos4_y +RLine4_2 +$06
			b "->",NULL

:R4T05			b "VORSCHAU/INFO"
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$06
			b "Das Beispiel-Icon zeigt eine"
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$08 +$06
			b "Vorschau auf den Dateityp."
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$14 +$06
			b "Farbe `SCHWARZ` wird durch die"
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$1c +$06
			b "Fenster/Textfarbe ersetzt!"
			b NULL
endif
if LANG = LANG_EN
:R4T01			b "FILE TYPE",NULL

:R4T02			w RPos4_x
			b RPos4_y +RLine4_1 +$06
			b "Name:",NULL

:R4T03			b "ICON-COLOR",NULL

:R4T04			w RPos4_x
			b RPos4_y +RLine4_2 +$06
			b "Color:",NULL

:R4T04a			w R1SizeX1 -$36
			b RPos4_y +RLine4_2 +$06
			b "->",NULL

:R4T05			b "PREVIEW/INFO"
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$06
			b "The sample icon shows a"
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$08 +$06
			b "preview for the file type."
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$14 +$06
			b "`Black` color will be replaced"
			b GOTOXY
			w RPos4_x
			b RPos4_y +RLine4_3 +$1c +$06
			b "by window/text color!"
			b NULL
endif

;*** Daten für Register "Optionen".
:RPos5_x  = R1SizeX0 +$10
:RPos5_y  = R1SizeY0 +$18
:RTab5_1  = $0058 ;Pattern: GeoDesk.
:RTab5_2  = $00b0 ;Pattern: TaskBar.
:RPat     = $28   ;Breite PatternBox.
:RLine5_1 = $00
:RLine5_2 = $28
:RLine5_3 = $38
:RLine5_4 = $48
:RLine5_5 = $28
:RLine5_6 = $40
:RLine5_7 = $60

:RegTMenu5		b 21

;--- Hintergrundmuster.
			b BOX_FRAME
				w R5T01
				w $0000
				b RPos5_y +RLine5_1 -$08
				b RPos5_y +RLine5_1 +$10 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;--- Pattern: GEOS.
			b BOX_FRAME
				w $0000
				w PrintPatGEOS
				b RPos5_y +RLine5_1 -$01
				b RPos5_y +RLine5_1 +$10
				w RPos5_x +$20 -$01
				w RPos5_x +$20 +RPat
::u01			b BOX_USER_VIEW
				w R5T02a
				w $0000
				b RPos5_y +RLine5_1
				b RPos5_y +RLine5_1 +$10 -$01
				w RPos5_x +$20
				w RPos5_x +$20 +RPat -$08 -$01
			b BOX_ICON
				w $0000
				w SetPrevBackPat
				b RPos5_y +RLine5_1
				w RPos5_x +$20 +RPat -$08
				w RIcon_SlctUp
				b (:u01 - RegTMenu5  -1)/11 +1
			b BOX_ICON
				w $0000
				w SetNextBackPat
				b RPos5_y +RLine5_1 +$08
				w RPos5_x +$20 +RPat -$08
				w RIcon_Select
				b (:u01 - RegTMenu5  -1)/11 +1

;--- Pattern: GeoDesk.
			b BOX_FRAME
				w $0000
				w PrintPatGDesk
				b RPos5_y +RLine5_1 -$01
				b RPos5_y +RLine5_1 +$10
				w RPos5_x +RTab5_1 +$28 -$01
				w RPos5_x +RTab5_1 +$28 +RPat
			b BOX_USER_VIEW
				w R5T02b
				w $0000
				b RPos5_y +RLine5_1
				b RPos5_y +RLine5_1 +$10 -$01
				w RPos5_x +RTab5_1 +$28
				w RPos5_x +RTab5_1 +$28 +RPat -$08 -$01
			b BOX_ICON
				w $0000
				w SetPrevBackPatGD
				b RPos5_y +RLine5_1
				w RPos5_x +RTab5_1 +$28 +RPat -$08
				w RIcon_SlctUp
				b (:u01 - RegTMenu5  -1)/11 +1
			b BOX_ICON
				w $0000
				w SetNextBackPatGD
				b RPos5_y +RLine5_1 +$08
				w RPos5_x +RTab5_1 +$28 +RPat -$08
				w RIcon_Select
				b (:u01 - RegTMenu5  -1)/11 +1

;--- Pattern: TaskBar.
			b BOX_FRAME
				w $0000
				w PrintPatTaskB
				b RPos5_y +RLine5_1 -$01
				b RPos5_y +RLine5_1 +$10
				w RPos5_x +RTab5_2 +$00 -$01
				w RPos5_x +RTab5_2 +$00 +RPat
			b BOX_USER_VIEW
				w $0000
				w $0000
				b RPos5_y +RLine5_1
				b RPos5_y +RLine5_1 +$10 -$01
				w RPos5_x +RTab5_2 +$00
				w RPos5_x +RTab5_2 +$00 +RPat -$08 -$01
			b BOX_ICON
				w $0000
				w SetPrevBackPatTB
				b RPos5_y +RLine5_1
				w RPos5_x +RTab5_2 +$00 +RPat -$08
				w RIcon_SlctUp
				b (:u01 - RegTMenu5  -1)/11 +1
			b BOX_ICON
				w $0000
				w SetNextBackPatTB
				b RPos5_y +RLine5_1 +$08
				w RPos5_x +RTab5_2 +$00 +RPat -$08
				w RIcon_Select
				b (:u01 - RegTMenu5  -1)/11 +1

;--- Reset.
			b BOX_FRAME
				w R5T03
				w $0000
				b RPos5_y +RLine5_2 -$08
				b R1SizeY1 -$20
				w R1SizeX0 +$08
				w R1SizeX0 +$08 +$a0 -$01
			b BOX_ICON
				w R5T04a
				w ResetCol_GEOS
				b RPos5_y +RLine5_2
				w RPos5_x
				w RIcon_Button
				b (:u01 - RegTMenu5  -1)/11 +1
			b BOX_ICON
				w R5T04b
				w ResetCol_GDESK
				b RPos5_y +RLine5_3
				w RPos5_x
				w RIcon_Button
				b (:u01 - RegTMenu5  -1)/11 +1
			b BOX_ICON
				w R5T04c
				w ResetCol_FICON
				b RPos5_y +RLine5_4
				w RPos5_x
				w RIcon_Button
				b (:u01 - RegTMenu5  -1)/11 +1

;--- Save/Load.
			b BOX_FRAME
				w R5T06
				w $0000
				b RPos5_y +RLine5_5 -$08
				b R1SizeY1 -$20
				w R1SizeX0 +$08 +$98 +$10
				w R1SizeX1 -$08
			b BOX_ICON
				w R5T07
				w svColorConfig
				b RPos5_y +RLine5_5
				w R1SizeX1 -$20 +$04
				w RIcon_Save
				b (:u01 - RegTMenu5  -1)/11 +1
			b BOX_ICON
				w R5T08
				w ldColorConfig
				b RPos5_y +RLine5_6
				w R1SizeX1 -$20 +$04
				w RIcon_Load
				b (:u01 - RegTMenu5  -1)/11 +1

;--- Farbprofil erstellen.
			b BOX_OPTION
				w R5T09
				w $0000
				b RPos5_y +RLine5_7
				w RPos5_x
				w BootSaveColors
				b %10000000

;*** Texte für Register "Optionen".
if LANG = LANG_DE
:R5T01			b "HINTERGRUNDMUSTER",NULL

:R5T02a			w RPos5_x
			b RPos5_y +RLine5_1 +$06
			b "GEOS",NULL
:R5T02b			w RPos5_x +RTab5_1 -$0a
			b RPos5_y +RLine5_1 +$06
			b "GeoDesk/"
			b GOTOXY
			w RPos5_x +RTab5_1 -$0a
			b RPos5_y +RLine5_1 +$08 +$06
			b "TaskBar",NULL
:R5T03			b "VOREINSTELLUNGEN",NULL

:R5T04a			w RPos5_x +$0c
			b RPos5_y +RLine5_2 +$06
			b "GEOS/GDOS64",NULL

:R5T04b			w RPos5_x +$0c
			b RPos5_y +RLine5_3 +$06
			b "GeoDesk/Extras",NULL

:R5T04c			w RPos5_x +$0c
			b RPos5_y +RLine5_4 +$06
			b "GeoDesk/Datei-Icons",NULL

:R5T06			b "DATEI",NULL

:R5T07			w RPos5_x +$98 +$10
			b RPos5_y +RLine5_5 +$0a
			b "SAVE",NULL

:R5T08			w RPos5_x +$98 +$10
			b RPos5_y +RLine5_6 +$0a
			b "LOAD",NULL

:R5T09			w RPos5_x +$08 +$06
			b RPos5_y +RLine5_7 +$06
			b "Beim speichern der Konfiguration"
			b GOTOXY
			w RPos5_x +$08 +$06
			b RPos5_y +RLine5_7 +$08 +$06
			b "automatisch `GeoDesk.col` erstellen.",NULL
endif
if LANG = LANG_EN
:R5T01			b "BACKGROUND PATTERN",NULL

:R5T02a			w RPos5_x
			b RPos5_y +RLine5_1 +$06
			b "GEOS",NULL
:R5T02b			w RPos5_x +RTab5_1 -$0a
			b RPos5_y +RLine5_1 +$06
			b "GeoDesk/"
			b GOTOXY
			w RPos5_x +RTab5_1 -$0a
			b RPos5_y +RLine5_1 +$08 +$06
			b "TaskBar",NULL
:R5T03			b "DEFAULT SETTINGS",NULL

:R5T04a			w RPos5_x +$0c
			b RPos5_y +RLine5_2 +$06
			b "GEOS/GDOS64",NULL

:R5T04b			w RPos5_x +$0c
			b RPos5_y +RLine5_3 +$06
			b "GeoDesk/Extras",NULL

:R5T04c			w RPos5_x +$0c
			b RPos5_y +RLine5_4 +$06
			b "GeoDesk/File icons",NULL

:R5T06			b "FILE",NULL

:R5T07			w RPos5_x +$98 +$10
			b RPos5_y +RLine5_5 +$0a
			b "SAVE",NULL

:R5T08			w RPos5_x +$98 +$10
			b RPos5_y +RLine5_6 +$0a
			b "LOAD",NULL

:R5T09			w RPos5_x +$08 +$06
			b RPos5_y +RLine5_7 +$06
			b "Automatically create `GeoDesk.col`"
			b GOTOXY
			w RPos5_x +$08 +$06
			b RPos5_y +RLine5_7 +$08 +$06
			b "when saving the configuration.",NULL
endif

;*** Bezeichnung des Bildschirmschoner einlesen.
:GetScrSvName		jsr	SetADDR_ScrSaver	;Bildschirmschoner einlesen.
			jsr	SwapRAM

			LoadW	r0,LOAD_SCRSAVER +6
			LoadW	r1,BootSaverName
			ldx	#r0L
			ldy	#r1L			;Name des Bildschirmschoners in
			jsr	CopyString		;Konfigurationstabelle übernehmen.

			jsr	SetADDR_ScrSaver	;Speicher zurücksetzen.
			jmp	SwapRAM

;*** Modus für Bildschirmschoner wechseln.
:Swap_ScrSaver		lda	BootSaverName		;Bildschirmschoner definiert?
			beq	:off			; => Nein, abschalten.

			lda	Flag_ScrSaver		;Modus Bildchirmschoner in
			and	#%10000000		;Boot-Konfiguration übernehmen.
			sta	BootScrSaver		;Bildschirmschoner abgeschaltet?
			bne	:exit			; => Ja, Ende...

;--- Ergänzung: 16.02.21/M.Kanet
;Prüfen ob der angezeigte Bildschirm-
;schoner bereits geladen wurde.
;Sonst nachladen, bei Fehler abbrechen.
			jsr	e_Test_ScrSvNm		;Name Bildschirmschoner prüfen.
			txa				;Bildschirmschoner bereits geladen?
			beq	:exit			;Ist im Speicher, weiter...

			jsr	GetScrSvFile		;Bildschirmschoner laden.
			txa				;Fehler?
			bne	GetNewScrSaver		; => Ja, Neu laden.

::exit			jmp	UpdateScrSvOpt		;Register-Menü aktualisieren.
::off			jmp	DisableScrSaver		;Bildschirmschoner abschalten.

;*** Manuellen Modus wechseln.
:Swap_ScrSvMode		lda	Flag_ScrSvCnt		;Bildschirmschoner Verzögerung.
			sta	BootScrSvCnt
			rts

;*** Neuen Bildschirmschoner laden.
:GetNewScrSaver		LoadB	r7L,SYSTEM
			LoadW	r10,Class_ScrSaver
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			bne	DisableScrSaver		; => Ja, Ende...

			LoadW	r0,dataFileName		;Name des Bildschirmschoners in
			LoadW	r1,BootSaverName	;Konfigurationstabelle übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Bildschirmschoner laden.
:GetScrSvFile		LoadW	r6,BootSaverName
			jsr	e_InitScrSaver		;Neuen Bildschirmschoner laden.
			txa				;Diskettenfehler ?
			bne	:err			; => Nein, weiter...

			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

;--- Ergänzung: 16.02.21/M.Kanet
;Name muss nicht eingelesen werden, da
;der Name der Bildschirmschoners dem
;Dateinamen entsprechen muss und dieser
;ist bereits definiert.
;			jsr	GetScrSvName		;Name Bildschirmschoner einlesen.
			jmp	UpdateScrSvOpt		;Registermenü aktualisieren.

::err			LoadW	r0,Dlg_ScrSvErr		;Fehlermeldung ausgeben.
			jsr	DoDlgBox

;*** Bildschirmschoner abschalten.
:DisableScrSaver	jsr	e_TurnOff_ScrSv		;Bildschirmschoner abschalten.

;*** Registermenü aktualisieren.
:UpdateScrSvOpt		jsr	SetScrSvOpt		;Bildschirmschoner-Optionen setzen.

			LoadW	r15,RegTMenu1a
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1b
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1c
			jmp	RegisterUpdate

;*** Optionen für Bildschirmschoner setzen.
:SetScrSvOpt		bit	Flag_ScrSaver		;Modus Bildchirmschoner in
			bpl	:on

			lda	Flag_ScrSvCnt
			and	#%01111111		;Bit%7 = "Manuell starten" löschen.
			sta	Flag_ScrSvCnt

			lda	#BOX_OPTION_VIEW	;Manuellen Start deaktivieren.
			b $2c
::on			lda	#BOX_OPTION
			sta	RegTMenu1c
			rts

;*** Bildschirmschoner testen.
;    Dazu wird der Zähler im ":Flag_ScrSaver" gelöscht, was beim nächsten
;    Interrupt den Bildschirmschoner startet.
:StartScrnSaver		lda	r1L			;Register-Grafikaufbau ?
			beq	:exit			; => Ja, Ende...

::wait			bit	mouseData		;Maustaste gedrückt ?
			bpl	:wait			; => Ja, warten bis keine Maustaste.

;--- Ergänzung: 01.07.18/M.Kanet
;Das testen funktioniert nicht wenn der
;Bildschirmschoner deaktiviert ist.
			bit	Flag_ScrSaver		;Bildschirmschoner aktiv?
			bmi	:exit			; => Nein, Ende...

;--- Ergänzung: 16.02.21/M.Kanet
;Bildschirmschoner testen. Wenn die
;Routinen einen Fehler meldet, dann den
;Bildschirmschoner abschalten.
			php				;IRQ sperren um den Bildschirm-
			sei				;schoner einzulesen und zu starten.
			jsr	SetADDR_ScrSaver	;Bildschirmschoner einlesen.
			jsr	SwapRAM
			jsr	LOAD_SCRSVINIT		;Starten...
			txa
			pha
			jsr	SetADDR_ScrSaver	;Speicher zurücksetzen.
			jsr	SwapRAM
			pla
			tax				;Fehler-Register zurücksetzen.
			plp

			cpx	#NO_ERROR		;Test erfolgreich?
			beq	:start_ScrSv		; => Ja, weiter...

			LoadW	r0,Dlg_ScrSvErr		;Fehlermeldung ausgeben.
			jsr	DoDlgBox

			jmp	DisableScrSaver		;Bildschirmschoner abschalten.

;--- Bildschirmschoner starten.
::start_ScrSv		lda	#%00000000		;Zähler löschen und
			sta	Flag_ScrSaver		;Bildschirmschoner starten.
::exit			rts

;*** Neuen Wert für Bildschirmschoner eingeben.
:Swap_ScrSvDelay	lda	r1L			;Register-Grafikaufbau ?
			beq	Draw_ScrSvDelay		; => Ja, weiter...

			lda	Flag_ScrSvCnt
			and	#%10000000		;Bit%7 = Manuell isolieren.
			sta	r0L

			lda	mouseXPos		;Neuen Wert für Aktivierungszeit
			sec				;berechnen.
			sbc	#< (RPos1_x +RTab1_3)
			lsr
			lsr
			bne	:1			;Wert > 0 ? => Ja, weiter...
			lda	#1			;Auf Minimum zurücksetzen.

::1			ora	r0L
			sta	Flag_ScrSvCnt		;Neue Aktivierungszeit setzen.
			sta	BootScrSvCnt

;--- Ergänzung: 01.07.18/M.Kanet
;In der MegaPatch/2003-Version von 1999-2003 wurde hier der Bildschirmschoner
;grundsätzlich neu gestartet, auch wenn dieser deaktiviert war.
			lda	Flag_ScrSaver		;Bildschirmschoner initialisieren.
			ora	#%01000000		;Dabei nur das "Initialize"-Bit
			sta	Flag_ScrSaver		;setzen, das "On/Off"-Bit#7 nicht
							;löschen, da sonst der Bildschirm-
							;schoner auch eingeschaltet wird.

;*** Verzögerungszeit für Bildschirmschoner festlegen.
:Draw_ScrSvDelay	lda	C_InputField		;Farbe für Schieberegler setzen.
			jsr	DirectColor

			jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_SETSCRN
			b	(RPos1_x +RTab1_3)/8
			b	RPos1_y +RLine1_4
			b	Icon_SETSCRN_x
			b	Icon_SETSCRN_y

			ldx	# (RPos1_x+RTab1_3)/8
			lda	Flag_ScrSvCnt		;Position Schiebe-Regler berechnen.
			and	#%01111111		;Bit%7 = Manuell löschen.
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff
			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_ScrSvCnt		;berechnen.
			and	#%01111111		;Bit%7 = Manuell löschen.
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx
::3			stx	:6 +2

			ldx	#< Icon_SETPOS2		;Typ für Regler-Icon ermitteln.
			ldy	#> Icon_SETPOS2
			lda	Flag_ScrSvCnt
			and	#%01111111		;Bit%7 = Manuell löschen.
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#< Icon_SETPOS1		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#> Icon_SETPOS1
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_SETSCRN
::6			b	$0c,RPos1_y +RLine1_4 +$03
			b	$ff,$05

;*** Aktivierungszeit anzeigen.
:Draw_ScrSvTime		LoadW	r0,R1T03a

			lda	Flag_ScrSvCnt		;Aktivierungszeit in Minuten und
			and	#%01111111		;Sekunden umrechnen.
			pha
			asl
			asl
			sta	r1L
			pla
;			lda	Flag_ScrSvCnt
;			and	#%01111111		;Bit%7 = Manuell löschen.
			clc
			adc	r1L

			ldx	#$00
::1			cmp	#60
			bcc	:2
			sec
			sbc	#60
			inx
			bne	:1
::2			jsr	SetDelayTime

			LoadW	r0,R1T03
			jsr	PutString		;Aktivierungszeit anzeigen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;*** Zahl nach ASCII wandeln.
:SetDelayTime		pha
			txa
			ldy	#$01
			jsr	:1
			pla

::1			ldx	#$30
::2			cmp	#10
			bcc	:3
			inx
			sbc	#10
			bcs	:2
::3			adc	#$30
			sta	(r0L),y
			dey
			txa
			sta	(r0L),y
			iny
			iny
			iny
			iny
			rts

;*** Modus für Hintergrund wechseln.
:Swap_BackScrn		lda	BootGrfxFile		;Hintergrundbild definiert?
			beq	:1			; => Nein, abschalten...

			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			bne	:1			; => Nein, weiter...
			jmp	GetBackScrFile		; => Ja, Hintergrundbild laden.

::1			jsr	e_TurnOff_BkScr		; => Nein, abschalten...

			jsr	DrawCfgMenu		;Menü neu zeichnen und
			jmp	RegisterInitMenu	;Registermenü aktualisieren.

;*** Neues Hintergrundbild laden.
:GetNewBackScrn		LoadB	r7L,APPL_DATA
			LoadW	r10,Class_GeoPaint
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler / Abbruch ?
			bne	DisableBackScrn		; => Ja, Ende...

			LoadW	r0,dataFileName		;Name des Bildschirmschoners in
			LoadW	r1,BootGrfxFile		;Konfigurationstabelle übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Bildschirmgrafik einlesen.
:GetBackScrFile		lda	sysRAMFlg
			ora	#%00001000
			sta	sysRAMFlg
			sta	sysFlgCopy
			lda	BootRAM_Flag
			ora	#%00001000
			sta	BootRAM_Flag

;*** Grafik von Diskette einlesen und speichern.
:GetScrnFromDisk	jsr	e_LdScrnFrmDisk

			jsr	DrawCfgMenu		;Menü neu zeichnen und
			jmp	RegisterInitMenu	;Registermenü aktualisieren.

;*** Hintergrundbild löschen.
;--- Ergänzung: 13.01.19/M.Kanet
;Wenn die Auswahl des Hintergrundbildes
;abgebrochen wurde, dann auch das
;Hintergrundbild deaktivieren.
:DisableBackScrn	lda	#NULL
			sta	BootGrfxFile

::1			jsr	e_TurnOff_BkScr		; => Nein, abschalten...

			jsr	DrawCfgMenu		;Menü neu zeichnen und
			jmp	RegisterInitMenu	;Registermenü aktualisieren.

;*** Aktuelles Hintergrundbild anzeigen.
:PrintCurBackScrn	lda	r1L			;Aufbau Registermenü ?
			beq	:1			; => Ja, Ende...

			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			beq	:1			; => Nein, weiter...

			LoadW	r0,Dlg_GetBScrn
			jsr	DoDlgBox		;Hintergrundbild anzeigen.

::1			rts

;*** Neue Grafik laden.
:NewRandomGrfx		lda	SystemDevice		;System-Laufwerk aktivieren.
			jsr	SetDevice
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	e_GetRandomGrfx		;Zufälige Grafik suchen.
			txa				;Datei gefunden ?
			bne	:exit			; => Nein, Ende...

			jsr	e_LdScrnFrmDisk		;Hintergrundbild von Disk einlesen.

			bit	BootGrfxRandom		;Farbprofil laden ?
			bvc	:skip			; => Nein, weiter...

			jsr	e_GetRandomCols		;Passendes Farbprofil suchen.
			txa				;Datei gefunden ?
			beq	:ok			; => Nein, Ende...

::skip			lda	BootGrfxRandom
			and	#%00100000		;Standard-Farben verwenden ?
			bne	:default

			jsr	e_FindStdColCfg		;"GeoDesk.col" suchen und laden.
			txa				;Fehler ?
			beq	:menu			; => Nein, weiter...

::default		jsr	e_ResetColGEOS		;GEOS-Farben zurücksetzen.
			jsr	e_ResetColGDESK		;GeoDesk-Farben zurücksetzen.
			jsr	e_ResetColFICON		;Datei-Farben zurücksetzen.

::ok			jsr	e_ApplyColors		;Farben übernehmen.

::menu			jsr	DrawCfgMenu		;Menü neu zeichnen und
			jmp	RegisterInitMenu	;Registermenü aktualisieren.

::exit			rts

;*** Hintergrundmuster/GEOS wechseln.
:SetPrevBackPat		lda	C_GEOS_PATTERN		;Vorheriges Füllmuster setzen.
			bne	:1
			lda	#32
::1			sec
			sbc	#$01
			jmp	SetNewBackPat		;Neues Füllmuster anzeigen.

:SetNextBackPat		lda	C_GEOS_PATTERN		;Nächstes Füllmuster setzen.
			clc
			adc	#$01
			cmp	#32
			bcc	SetNewBackPat
			lda	#$00
:SetNewBackPat		sta	C_GEOS_PATTERN

;*** Aktuelles Füllmuster anzeigen.
:PrintPatGEOS		lda	C_GEOS_PATTERN		;Füllmuster aktivieren.
			jsr	SetPattern

			jsr	i_Rectangle		;Füllmuster darstellen.
			b	RPos5_y +RLine5_1
			b	RPos5_y +RLine5_1 +$10 -$01
			w	RPos5_x +$20
			w	RPos5_x +$20 +RPat -$08 -$01

			lda	C_GEOS_BACK		;GEOS-Hintergrundfarbe setzen.
			jmp	DirectColor

;*** Hintergrundmuster/GeoDesk wechseln.
:SetPrevBackPatGD	lda	C_GDESK_PATTERN		;Vorheriges Füllmuster setzen.
			bne	:1
			lda	#32
::1			sec
			sbc	#$01
			jmp	SetNewBackPatGD		;Neues Füllmuster anzeigen.

:SetNextBackPatGD	lda	C_GDESK_PATTERN		;Nächstes Füllmuster setzen.
			clc
			adc	#$01
			cmp	#32
			bcc	SetNewBackPatGD
			lda	#$00
:SetNewBackPatGD	sta	C_GDESK_PATTERN

;*** Aktuelles Füllmuster anzeigen.
:PrintPatGDesk		lda	C_GDESK_PATTERN		;Füllmuster aktivieren.
			jsr	SetPattern

			jsr	i_Rectangle		;Füllmuster darstellen.
			b	RPos5_y +RLine5_1
			b	RPos5_y +RLine5_1 +$10 -$01
			w	RPos5_x +RTab5_1 +$28
			w	RPos5_x +RTab5_1 +$28 +RPat -$08 -$01

			lda	C_GDesk_DeskTop		;GeoDesk-Hintergrundfarbe setzen.
			jmp	DirectColor

;*** Hintergrundmuster/TaskBar wechseln.
:SetPrevBackPatTB	lda	C_GTASK_PATTERN		;Vorheriges Füllmuster setzen.
			bne	:1
			lda	#32
::1			sec
			sbc	#$01
			jmp	SetNewBackPatTB		;Neues Füllmuster anzeigen.

:SetNextBackPatTB	lda	C_GTASK_PATTERN		;Nächstes Füllmuster setzen.
			clc
			adc	#$01
			cmp	#32
			bcc	SetNewBackPatTB
			lda	#$00
:SetNewBackPatTB	sta	C_GTASK_PATTERN

;*** Aktuelles Füllmuster anzeigen.
:PrintPatTaskB		lda	C_GTASK_PATTERN		;Füllmuster aktivieren.
			jsr	SetPattern

			jsr	i_Rectangle		;Füllmuster darstellen.
			b	RPos5_y +RLine5_1
			b	RPos5_y +RLine5_1 +$10 -$01
			w	RPos5_x +RTab5_2 +$00
			w	RPos5_x +RTab5_2 +$00 +RPat -$08 -$01

			lda	C_GDesk_TaskBar		;TaskBar-Hintergrundfarbe setzen.
			jmp	DirectColor

;*** Systemfarben wechseln.
:PrintCurColName	lda	#$00			;Füllmuster für Farbbereich.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos3_y +RLine3_1
			b	RPos3_y +RLine3_1 +$10 -$01
			w	RPos3_x +RTab3_1
			w	R1SizeX1 -$18

			lda	C_InputField		;Farbe für Anzeigebereich setzen.
			jsr	DirectColor

			jsr	InitVecColTab		;Farb-Tabelle initialisieren.

			tya				;Zeiger auf Farbwert einlesen.
			and	#%01111111
			asl
			asl
			pha
			tay
			lda	(r15L),y		;Zeiger auf Text/Zeile#1.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos3_y +RLine3_1 +$06)
			jsr	:prntCurLine		;Textzeile ausgeben.

			pla
			tay
			iny
			iny
			lda	(r15L),y		;Zeiger auf Text/Zeile#2.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos3_y +RLine3_1 +$08 +$06)

::prntCurLine		sty	r1H			;Cursorposition festlegen.
			LoadW	r11,(RPos3_x +RTab3_1 +$02)

			jmp	PutString		;Textzeile ausgeben.

;*** Zeiger auf Tabelle mit Farbbereichen setzen.
:InitVecColTab		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			ldy	Vec2ColorTab,x		;GEOS/MegaPatch- oder GeoDesk?
			bmi	:colNameGDesk		; => GeoDesk, weiter...

::colNameGEOS		lda	#< Vec2ColNames1	;Zeiger auf GEOS/MegaPatch-Farben.
			ldx	#> Vec2ColNames1
			bne	:1

::colNameGDesk		lda	#< Vec2ColNames2	;Zeiger auf GeoDesk-Farben.
			ldx	#> Vec2ColNames2

::1			sta	r15L			;Zeiger auf Tabelle mit den
			stx	r15H			;Farbtexten festlegen.
			rts

;*** Zeiger auf nächsten Bereich.
:NextColEntry		ldx	Vec2Color		;Nächster Bereich.
::2			inx
			cpx	#skipMseCol1
			beq	:2
			cpx	#MaxColSettings
			bcc	:1
			ldx	#$00
::1			jmp	SetColEntry

;*** Zeiger auf letzten Bereich.
:LastColEntry		ldx	Vec2Color		;Vorheriger Bereich.
			bne	:1
			ldx	#MaxColSettings
::1			dex
			cpx	#skipMseCol1
			beq	:1

:SetColEntry		stx	Vec2Color
;			jsr	PrintCurColName		;Farbbereich ausgeben.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

;*** Aktuelle Farbeinstellungen anzeigen.
:UpdateCurColor		LoadW	r15,RegTMenu3a		;Farbbereiche für Vorder- und
			jsr	RegisterUpdate		;Hintergrund anzeigen.
			LoadW	r15,RegTMenu3b
			jmp	RegisterUpdate

;*** Aktuellen Farbwert für Text ausgeben.
:PrintCurColorT		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			lda	Vec2ColorTab,x		;GEOS/MegaPatch- oder GeoDesk?
			bmi	:colDataGDesk		; => GeoDesk, weiter...

::colDataGEOS		tax				;Aktuellen Farbwert aus
			lda	GD_COLOR_GEOS,x		;GEOS/MegaPatch-Farbtabelle holen.
			jmp	:prntColData

::colDataGDesk		and	#%01111111
			tax				;Aktuellen Farbwert aus
			lda	GD_COLOR,x		;GeoDesk-Farbtabelle holen.

::prntColData		lsr				;Farbbereich anzeigen.
			lsr
			lsr
			lsr
			jmp	DirectColor

;*** Aktuellen Farbwert für Hintergrund ausgeben.
:PrintCurColorB		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			lda	Vec2ColorTab,x		;GEOS/MegaPatch- oder GeoDesk?
			bmi	:colDataGDesk		; => GeoDesk, weiter...

::colDataGEOS		tax				;Aktuellen Farbwert aus
			lda	GD_COLOR_GEOS,x		;GEOS/MegaPatch-Farbtabelle holen.
			jmp	:prntColData

::colDataGDesk		and	#%01111111
			tax				;Aktuellen Farbwert aus
			lda	GD_COLOR,x		;GeoDesk-Farbtabelle holen.

::prntColData		and	#%00001111		;Farbbereich anzeigen.
			jmp	DirectColor

;*** Icon-Farbe wechseln.
:PrintCurIColName	lda	#$00			;Füllmuster für Farbbereich.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos4_y +RLine4_1
			b	RPos4_y +RLine4_1 +$08 -$01
			w	RPos4_x +RTab4_1
			w	R1SizeX1 -$18

			lda	C_InputField		;Farbe für Anzeigebereich setzen.
			jsr	DirectColor

;--- Icon-Typ festlegen.
			lda	Vec2ICol		;Zeiger auf Icon-Typ einlesen.
			asl
			tay
			lda	vecGTypeText,y		;Zeiger auf Text einlesen.
			sta	r0L
			iny
			lda	vecGTypeText,y
			sta	r0H

;--- Cursorposition festlegen.
			LoadB	r1H,(RPos4_y +RLine4_1 +$06)
			LoadW	r11,(RPos4_x +RTab4_1 +$02)

			jmp	PutString		;Textzeile ausgeben.

;*** Zeiger auf nächsten Icon-Typ.
:NextIColEntry		ldx	Vec2ICol		;Nächster Icon-Typ.
			inx
			cpx	#MaxIColSettings
			bcc	:1
			ldx	#$00
::1			stx	Vec2ICol
			jsr	PrintCurIColName	;Farbbereich ausgeben.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

;*** Aktuelle Farbeinstellungen anzeigen.
:UpdateCurIColor	jsr	setColPreview		;Farbe für Vorschau-Icon.

			LoadW	r15,RegTMenu4a		;Farbbereiche für Vorder- und
			jmp	RegisterUpdate		;Hintergrund anzeigen.

;*** Aktuellen Farbwert für Icon ausgeben.
:PrintCurIColor		ldx	Vec2ICol		;Zeiger auf Tabelle holen.
			ldy	Vec2IColTab,x
			lda	GD_COLICON,y		;Icon-Farbe aus Farbtabelle holen.
			lsr				;Farbbereich anzeigen.
			lsr
			lsr
			lsr
			jmp	DirectColor		;Farbe anzeigen.

;*** Farbe für Vorschau-Icon.
:setColPreview		ldx	Vec2ICol		;Zeiger auf Tabelle holen.
			ldy	Vec2IColTab,x
			lda	GD_COLICON,y		;Icon-Farbe aus Farbtabelle holen.
			bne	:1
			lda	C_WinBack		;Farbe verknüpfen.
			and	#%11110000
::1			sta	r7L			;Farbwert für Icon mit Hintergund-
			lda	C_WinBack		;Farbe verknüpfen.
			and	#%00001111
			ora	r7L
			jsr	i_UserColor		;Vorschau-Icon einfärben.
			b	(R1SizeX1 -$28 +$01) / 8
			b	(RPos4_y +RLine4_4) / 8
			b	3,3
			rts

;*** Farbtabelle Text/Hintergrund ausgeben.
;    Übergabe: r1L = $00=Farbtabelle anzeigen/$FF=aktualisieren.
;              Wird durch RegisterMenü gesetzt.
:ColorInfoT		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorT		; => Nein, weiter...
			lda	#(RPos3_y +RLine3_2)/8
			bne	ColorInfo

:ColorInfoB		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorB		; => Nein, weiter...
			lda	#(RPos3_y +RLine3_3)/8
			bne	ColorInfo

:ColorInfoI		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorI		; => Nein, weiter...
			lda	#(RPos4_y +RLine4_2)/8

:ColorInfo		sta	:2 +1

			lda	#(RPos3_x +RTab3_1)/8
			sta	:2 +0

			ldx	#$00			;Farbtabelle ausgeben.
::1			txa
			pha
			lda	ColorTab,x		;Farbwert einlesen und
			jsr	i_UserColor		;anzeigen.
::2			b	$00,$11,$01,$01
			inc	:2 +0
			pla
			tax
			inx				;Zeiger auf nächste Farbe setzen.
			cpx	#$10			;Alle Farben angezeigt?
			bne	:1			; => Nein, weiter...
			rts

;*** Neue Icon-Farbe setzen.
:SetColorI		jsr	getSlctColor		;Zeiger auf Farbdaten berechnen.

			lda	ColorTab,x		;Farbwert einlesen.
			asl
			asl
			asl
			asl
			ldx	Vec2ICol		;Zeiger auf Farbtabelle.
			ldy	Vec2IColTab,x
			sta	GD_COLICON,y		;Neuen Farbwert speichern.
			jmp	UpdateCurIColor

;*** Neue Textfarbe setzen.
;HINWEIS:
;Abfrage ob Maus innerhalb Bereich, da
;die Routine auch von RegisterAllOpt
;aufgerufen wird und dabei eine neue
;Farbe ausgewählt werden würde.
:SetColorT		LoadB	r2L,RPos3_y +RLine3_2
			LoadB	r2H,RPos3_y +RLine3_2 +$08 -$01
			LoadW	r3 ,RPos3_x +RTab3_1
			LoadW	r4 ,RPos3_x +RTab3_1 +$80 -$01
			jsr	IsMseInRegion
			cmp	#TRUE
			beq	SetNewColT
			rts

;*** Neue Hintergrundfarbe setzen.
:SetColorB		LoadB	r2L,RPos3_y +RLine3_3
			LoadB	r2H,RPos3_y +RLine3_3 +$08 -$01
			LoadW	r3 ,RPos3_x +RTab3_1
			LoadW	r4 ,RPos3_x +RTab3_1 +$80 -$01
			jsr	IsMseInRegion
			cmp	#TRUE
			beq	SetNewColB
			rts

;*** Neue Vorder-/Hintergrundfarbe setzen.
:SetNewColT		lda	#$00
			b $2c
:SetNewColB		lda	#$ff
			sta	r13H

			jsr	InitVecDataTab		;Zeiger auf Systemfarben setzen.

			jsr	getSlctColor		;Zeiger auf Farbdaten berechnen.

			lda	ColorTab,x		;Farbwert einlesen und
			sta	r0L			;zwischenspeichern.

			ldx	Vec2Color
			lda	Vec2ColorTab,x
			and	#%01111111
			asl
			pha
			tay

			bit	r13H			;Vorder- oder Hintergrundfarbe?
			bpl	:0			; => Vordergrund, weiter...
			iny

::0			lda	(r14L),y		;Modus einlesen.
			and	#%11110000		;Vordergrund anzeigen?
			beq	:1			; => Nein, weiter...
			jsr	Add1High		;High-Nibble Farbwert erzeugen.

::1			pla
			tay

			bit	r13H			;Vorder- oder Hintergrundfarbe?
			bpl	:2			; => Vordergrund, weiter...
			iny

::2			lda	(r14L),y		;Modus einlesen.
			and	#%00001111		;Hintergrund anzeigen?
			beq	:3			; => Nein, weiter...
			jsr	Add1Low			;Low-Nibble Farbwert erzeugen.

::3			jmp	UpdateCurColor		;Farbwert anzeigen.

;*** Gewählte Farbe berechnen.
:getSlctColor		lda	mouseXPos +1		;Position Mauszeiger einlesen und
			lsr				;in Zeiger auf Farbtabelle wandeln.
			lda	mouseXPos +0
			ror
			lsr
			lsr
			sec
			sbc	#(RPos3_x +RTab3_1)/8
			tax
			rts

;*** Textfarbe wechseln.
:Add1High		ldx	Vec2Color
			lda	Vec2ColorTab,x
			and	#%01111111		;GEOS/GeoDesk-Bit ausblenden.
			tay
			lda	(r15L),y		;Farbwert einlesen und
			and	#%00001111		;Low-Nibble isolieren.
			sta	r0H
			lda	r0L			;Aktueller Farbwert in High-Nibble
			asl				;umwandeln.
			asl
			asl
			asl
			ora	r0H			;High-/Low-Nibble erzeugen und
			sta	(r15L),y		;neuen Farbwert speichern.
			rts

;*** Hintergrundfarbe wechseln.
:Add1Low		ldx	Vec2Color
			lda	Vec2ColorTab,x
			and	#%01111111		;GEOS/GeoDesk-Bit ausblenden.
			tay
			lda	(r15L),y		;Farbwert einlesen und
			and	#%11110000		;Low-Nibble isolieren.
			ora	r0L			;High-/Low-Nibble erzeugen und
			sta	(r15L),y		;neuen Farbwert speichern.
			rts

;*** Tabellenzeiger initialisieren.
;    Rückgabe: r14 = High-/Low-Nibble-Informationen.
;              r15 = Zeiger auf Farbdaten GEOS/GeoDesk.
:InitVecDataTab		ldx	Vec2Color
			ldy	Vec2ColorTab,x
			bmi	:colDataGDesk

::colDataGEOS		lda	#< GD_COLOR_GEOS
			ldx	#> GD_COLOR_GEOS
			bne	:1

::colDataGDesk		lda	#< GD_COLOR
			ldx	#> GD_COLOR

::1			sta	r15L			;Zeiger auf Farbdaten festlegen.
			stx	r15H

			tya
			bmi	:colModeGDesk

::colModeGEOS		lda	#< ColModifyTab1
			ldx	#> ColModifyTab1
			bne	:2

::colModeGDesk		lda	#< ColModifyTab2
			ldx	#> ColModifyTab2

::2			sta	r14L			;Zeiger auf High-/Low-Nibble
			stx	r14H			;Farbinformationen speichern.

			rts

;*** Warten bis keine Maustaste gedrückt.
:waitNoMseKey		lda	mouseData		;Maustaste gedrückt?
			bpl	waitNoMseKey		; => Ja, warten...
			ClrB	pressFlag		;Tastenstatus löschen.
			rts

;*** GEOS-Farben auf Standard setzen.
:ResetCol_GEOS		jsr	e_ResetColGEOS		;GEOS-Farben zurücksetzen.
			jmp	ApplyColConfig		;RegisterMenü aktualisieren.

;*** GeoDesk-Farben auf Standard setzen.
:ResetCol_GDESK		jsr	e_ResetColGDESK		;GeoDesk-Farben zurücksetzen.
			jmp	ApplyColConfig		;RegisterMenü aktualisieren.

;*** Datei-Icon-Farben auf Standard setzen.
:ResetCol_FICON		jsr	e_ResetColFICON		;Datei-Farben zurücksetzen.
;			jmp	ApplyColConfig		;RegisterMenü aktualisieren.

;*** Aktuelles Farbprofil anwenden.
:ApplyColConfig		jsr	e_ApplyColors		;Farbe Mauszeiger übernehmen.

			jsr	DrawCfgMenu		;Menü neu zeichnen und
			jmp	RegisterInitMenu	;Registermenü aktualisieren.

;*** Konfiguration laden.
:ldColorConfig		LoadB	r7L,SYSTEM
			LoadW	r10,Class_ColConf
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler / Abbruch ?
			beq	:load			; => Nein, weiter...
			rts

::load			LoadW	r0,dataFileName		;Name des Farbprofils in
			LoadW	r1,configColName	;Dateiname übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

			LoadB	r0L,%00000001
			LoadW	r6,configColName
			LoadW	r7,GD_PROFILE		;Startadresse Farb-/Musterdaten.
			jsr	GetFile			;Datei einlesen.
			txa				;Fehler?
			beq	ApplyColConfig		; => Nein, weiter...

::err			LoadW	r0,Dlg_DiskLoadErr
			jmp	DoDlgBox		;Disk-/Laufwerksfehler ausgeben.

;*** Konfiguration speichern.
:svColorConfig		lda	#0			;Namenspeicher löschen.
			tay
::clr			sta	configColName,y
			iny
			cpy	#16 +1
			bcc	:clr

			LoadW	a0,configColName
			LoadW	r0,Dlg_InputName
			jsr	DoDlgBox		;Dateiname eingeben.

			lda	sysDBData		;Rückmeldung auswerten.
			cmp	#CANCEL			; ABBRUCH ?
			beq	:cancel			; => Ja, Ende...
			lda	configColName		;Name eingegeben ?
			bne	:slctDrive		; => Ja, weiter...
::cancel		rts

::slctDrive		lda	#NULL
			ldx	SystemDevice
			ldy	RealDrvMode -8,x	;CMD-Laufwerk ?
			bpl	:nocmd			; => Nein, weiter...

			jsr	OpenDisk		;Diskette öffnen um die aktive
			lda	#NULL			;Partition einzulesen.
			cpx	#NO_ERROR		;Fehler ?
			bne	:nocmd			; => Keine Partition.

			ldx	SystemDevice
			lda	drivePartData -8,x
::nocmd			sta	configColSvPart		;Aktive Partition speichern.

::restart		LoadW	r5,dataFileName		;Temporärer Name. Ausgewählter
			LoadB	r7L,SYSTEM		;Dateiname wird ignoriert.
			LoadW	r10,Class_ColConf
			LoadW	r0,Dlg_SlctDrive
			jsr	DoDlgBox		;Partition/Laufwerk wählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:1			; =>: Nein, weiter...
			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			jmp	:restart		;Neustart...

::1			cmp	#DISK			;Partition/Diskwechsel gewählt ?
			beq	:restart		; => Ja, Neustart...
			cmp	#CANCEL			;"ABBRUCH" gewählt ?
			beq	:end			; => Ja, Ende...

::save			lda	curDrive		;Laufwerksname in
			clc				;DialogBox übernehmen.
			adc	#"A" -$08
			sta	configColSvDrv

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			lda	#< configColName	;Zeiger auf Dateiname für
			sta	HdrB000 +0		;Standard-Farbprofil.
			lda	#> configColName
			sta	HdrB000 +1

			jsr	doSvColorConfig		;Farbprofil speichern.

			lda	#< Dlg_DiskSave		;Dialogbox:
			ldy	#> Dlg_DiskSave		;"Farbprofil gespeichert"

			cpx	#NO_ERROR		;Fehler ?
			beq	:dlgbox			; => Nein, Ende...

::err			lda	#< Dlg_DskSvErr		;Dialogbox:
			ldy	#> Dlg_DskSvErr		;"Farbprofil nicht gespeichert"
::dlgbox		sta	r0L
			sty	r0H

			lda	HdrB000 +0		;Zeiger auf Dateiname einlesen.
			sta	a0L
			lda	HdrB000 +1
			sta	a0H

			jsr	DoDlgBox		;Hinweis ausgeben.

::end			lda	configColSvPart		;Partition zurücksetzen ?
			beq	:exit			; => Nein, Ende...
			pha
			lda	SystemDevice
			jsr	SetDevice		;Startlaufwerk aktivieren.
			pla
			sta	r3H
			jsr	OpenPartition		;Partition zurücksetzen.

::exit			rts

;*** Farbprofil speichern.
:doSvColorConfig	lda	HdrB000 +0		;Zeiger auf Dateiname einlesen.
			sta	r6L
			lda	HdrB000 +1
			sta	r6H
			jsr	FindFile		;Farbdatei suchen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
			cpx	#FILE_NOT_FOUND		;"FILE NOT FOUND"?
			beq	:2			; => Ja, ignorieren...
			bne	:err			;Abbruch...

::1			lda	HdrB000 +0		;Zeiger auf Dateiname einlesen.
			sta	r0L
			lda	HdrB000 +1
			sta	r0H
			jsr	DeleteFile		;Vorhandene Datei löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::2			lda	BackScrPattern		;GEOS-Füllmuster übernehmen.
			sta	C_GEOS_PATTERN

;			LoadW	HdrB000,configColStd
			LoadB	r10L,0			;Zeiger auf Infoblock für
			LoadW	r9,HdrB000		;neue Konfigurationsdatei.
			jsr	SaveFile		;Datei speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	HdrB000 +0		;Zeiger auf Dateiname einlesen.
			sta	r6L
			lda	HdrB000 +1
			sta	r6H
			jsr	FindFile		;Konfigurationsdatei suchen.
			txa				;Datei gefunden?
			bne	:err			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	HdrB160			;SaveFile löscht Byte #160,
			sta	fileHeader +160		;Byte wieder herstellen.

			lda	dirEntryBuf+19
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	PutBlock		;Infoblock schreiben.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

::err			rts

;*** Speicherpfad für GeoDesk.col.
:configColSvDrv		b "A:",PLAINTEXT,NULL
:configColSvPart	b $00

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w configColStd
::002			b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00001101
			b %10011100,%00111000,%00010001
			b %10011100,%00111000,%00010001
			b %10011100,%00111000,%00010001
			b %10000000,%00000000,%00001101
			b %10111110,%01111100,%00000001
			b %10000000,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10000000,%00000011,%00111001
			b %10111110,%00000100,%00100101
			b %10000000,%00000101,%10100101
			b %10000000,%00000100,%10100101
			b %10000000,%00000011,%10111001
			b %10000000,%00000000,%00000001
			b %10101010,%10101010,%10101011
			b %11010101,%01010101,%01010101
			b %11111111,%11111111,%11111111

::068			b $81				;SEQ.
			b SYSTEM			;GEOS-Systemdatei.
			b SEQUENTIAL			;GEOS-Dateityp SEQ.
			w GD_PROFILE			;Programm-Anfang.
			w GD_PROFILE_END		;Programm-Ende.
			w $0000				;Programm-Start.
::077			b "geoDeskCol  "		;Klasse
			b "V1.0"			;Version
			b NULL
			b $00,$00			;Reserviert
			b $00				;Bildschirmflag
::097			b "GeoDesk64"			;Autor
			s 11				;Reserviert
			s 12  				;Anwendung/Klasse
			s 4  				;Anwendung/Version
			b NULL
			s 26				;Reserviert.

if LANG = LANG_DE
:HdrB160		b "Konfigurationsdatei",CR
			b "für GeoDesk Farben",NULL
endif
if LANG = LANG_EN
:HdrB160		b "Configuration file",CR
			b "for GeoDesk colors",NULL
endif

::HdrEnd		s (HdrB000+256)-:HdrEnd

;*** Dialogbox: Ziel-Laufwerk wählen.
:Dlg_SlctDrive		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b DISK   ,$00,$00
			b CANCEL ,$00,$00
			b OPEN   ,$00,$00
			b NULL

;*** Neuen Namen für Farbprofil eingeben.
:Dlg_InputName		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$40
			w :3
			b DBTXTSTR   ,$0c,$4a
			w :4
			b DBTXTSTR   ,$18,$31
			w :5
			b DBGETSTRING,$38,$2b
			b a0L, 16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "FARBPROFIL SPEICHERN",NULL
::2			b PLAINTEXT
			b "Name für Farbprofil eingeben:",NULL
::3			b "Auf der nächsten Seite das Laufwerk",NULL
::4			b "wählen und mit 'Öffnen' bestätigen.",NULL
::5			b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "SAVE COLOR PROFILE",NULL
::2			b PLAINTEXT
			b "Enter name for the color profile:",NULL
::3			b "On the next page please select the",NULL
::4			b "drive and confirm with 'Open'.",NULL
::5			b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
endif

;*** Dialogbox: Hintergrundbild zeigen.
:Dlg_GetBScrn		b $00
			b $00,$c7
			w $0000,$013f
			b DB_USR_ROUT
			w GetBackScreen
			b DBSYSOPV
			b NULL

;*** Bildschirmschoner - Initialisierung fehlgeschlagen.
:Dlg_ScrSvErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$10,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$10,$20
			w :1
			b DBTXTSTR   ,$10,$2b
			w :2
			b DBTXTSTR   ,$10,$3b
			w :3
			b OK         ,$02,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Der Bildschirmschoner konnte",NULL
::2			b "nicht initialisiert werden!",NULL
::3			b "Bildschirmschoner deaktiviert.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "Unable to initialize the",NULL
::2			b "screen saver!",NULL
::3			b "Screensaver has been disabled.",NULL
endif

;*** Fehler: Farbprofil nicht gespeichert.
:Dlg_DskSvErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$18,$3a
			w :4
			b DBTXTSTR   ,$38,$3a
			w configColSvDrv
			b DBVARSTR   ,$42,$3a
			b a0L
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das aktuelle Farbprofil konnte",NULL
::3			b "nicht gespeichert werden!",NULL
::4			b BOLDON
			b "Datei:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The current color settings",NULL
::3			b "could not be saved!",NULL
::4			b BOLDON
			b "File:"
			b PLAINTEXT,NULL
endif

;*** Info: Farbprofil gespeichert.
:Dlg_DiskSave		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_INF
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$18,$3a
			w :4
			b DBTXTSTR   ,$38,$3a
			w configColSvDrv
			b DBVARSTR   ,$42,$3a
			b a0L
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das aktuelle Farbprofil wurde",NULL
::3			b "erfolgreich gespeichert:",NULL
::4			b BOLDON
			b "Datei:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The current color profile has",NULL
::3			b "been saved successfully:",NULL
::4			b BOLDON
			b "File:"
			b PLAINTEXT,NULL
endif

;*** Fehler: Konfiguration nicht geladen.
:Dlg_DiskLoadErr	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Farbprofil konnte nicht",NULL
::3			b "geladen werden!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The color settings could",NULL
::3			b "not be loaded!",NULL
endif

;*** Sortierte Farbtabelle.
:ColorTab		b $01,$0f,$0c,$0b,$00,$09,$08,$07
			b $0a,$02,$04,$06,$0e,$03,$05,$0d

;*** Farbeinstellungen.
:Vec2Color		b $00				;Zeiger aktueller Farbbereich.
:Vec2ICol		b $00				;Zeiger aktueller Icon-Typ.

;*** Datei-Icon-Farben.
:MaxIColSettings	= 21
:Vec2IColTab		b $00				;#1  : Nicht GEOS.
			b $01				;#2  : BASIC-Programm.
			b $02				;#3  : Assembler-Programm.
			b $03				;#4  : Datenfile.
			b $04				;#5  : Systemdatei.
			b $05				;#6  : Hilfsprogramm.
			b $06				;#7  : Anwendung.
			b $07				;#8  : Dokument.
			b $08				;#9  : Zeichensatz.
			b $09				;#10 : Druckertreiber.
			b $0a				;#11 : Eingabetreiber.
			b $0b				;#12 : Laufwerkstreiber.
			b $0c				;#13 : Startprogramm.
			b $0d				;#14 : Temporäre Datei (SWAP FILE).
			b $0e				;#15 : Selbstausführend (AUTO_EXEC).
			b $0f				;#16 : Eingabetreiber C128.
			b $11				;#17 : gateWay-Dokument.
			b $15				;#18 : geoShell-Befehl.
			b $16				;#19 : geoFax-Dokument.
			b $17				;#20 : Unbekannt.
			b $18				;#21 : Verzeichnis.

;*** GEOS- oder GeoDesk-Farben?
;    GEOS    = %0xxxxxxx
;    GeoDesk = %1xxxxxxx
:MaxColSettings		= 32
:skipMseCol1		= 4 -1
:Vec2ColorTab		b $01				;#1  : GEOS/Registerkarten: Aktives Register.
			b $02				;#2  : GEOS/Registerkarten: Inaktives Register.
			b $03				;#3  : GEOS/Registerkarten: Hintergrund/Text.
			b $04				;#4  : GEOS/Zeiger: Mauspfeil/Pointer.
			b $05				;#5  : GEOS/Dialogbox: Titel.
			b $06				;#6  : GEOS/Dialogbox: Hintergrund/Text.
			b $07				;#7  : GEOS/Dialogbox: System-Icons.
			b $0e				;#14 : GEOS/Dialogbox: Schatten.
			b $08				;#8  : GEOS/Dateiauswahlbox: Titel.
			b $09				;#9  : GEOS/Dateiauswahlbox: Hintergrund/Text.
			b $0a				;#10 : GEOS/Dateiauswahlbox: System-Icons.
			b $0b				;#11 : GEOS/Dateiauswahlbox: Dateifenster.
			b $00				;#0  : GEOS/Dateiauswahlbox: Balken und Pfeile.
			b $0c				;#12 : GEOS/Fenster: Titel.
			b $0d				;#13 : GEOS/Fenster: Hintergrund/Text.
			b $0f				;#15 : GEOS/Fenster: System-Icons.
			b $10				;#16 : GEOS/PullDown: GEOS-Menü für Anwendungen.
			b $11				;#17 : GEOS/Eingabefelder: Eingabefeld.
			b $12				;#18 : GEOS/Eingabefelder: Inaktives Optionsfeld.
			b $13				;#19 : GEOS/Standard: Hintergrund.
			b $14				;#20 : GEOS/Standard: Rahmen.
			b $15				;#21 : GEOS/Standard: Mauszeiger.

			b $83				;#3  : GeoDesk: GEOS-Hauptmenü.
			b $82				;#2  : GeoDesk: Datum und Uhrzeit.
			b $85				;#5  : GeoDesk: TaskBar.
			b $89				;#9  : GeoDesk: DeskTop.
			b $86				;#6  : GeoDesk/AppLinks: AppLink-Icon.
			b $87				;#7  : GeoDesk/AppLinks: AppLink-Titel.
			b $88				;#8  : GeoDesk/AppLinks: Arbeitsplatz.
			b $80				;#0  : GeoDesk/Fenster: Scollbalken.
			b $81				;#1  : GeoDesk/Fenster: Scoll-Icons Up/Down.
			b $84				;#4  : GeoDesk/Registermenü: Menü beenden.

;*** Tabelle zum ändern des Farbwertes.
;    Highbyte:		Textfarbe ändern.
;    Lowbyte:		Hintergrundfarbe ändern.
;    Byte #1:		Textfarbe.
;    Byte #2:		Hintergrundfarbe.
:ColModifyTab1		b %11110000,%00001111		;#0
			b %11110000,%00001111		;#1
			b %11110000,%00001111		;#2
			b %11110000,%00001111		;#3
			b %11111111,%11111111		;#4
			b %11110000,%00001111		;#5
			b %11110000,%00001111		;#6
			b %11110000,%00001111		;#7
			b %11110000,%00001111		;#8
			b %11110000,%00001111		;#9
			b %11110000,%00001111		;#10
			b %11110000,%00001111		;#11
			b %11110000,%00001111		;#12
			b %11110000,%00001111		;#13
			b %11110000,%00001111		;#14
			b %11110000,%00001111		;#15
			b %11110000,%00001111		;#16
			b %11110000,%00001111		;#17
			b %11110000,%00001111		;#18
			b %11110000,%00001111		;#19
			b %11111111,%11111111		;#20
			b %11111111,%11111111		;#21

:Vec2ColNames1		w Text_1_05, Text_2_01		;#0
			w Text_1_02, Text_2_02		;#1
			w Text_1_02, Text_2_03		;#2
			w Text_1_02, Text_2_04		;#3
			w Text_1_03, Text_2_05		;#4
			w Text_1_04, Text_2_06		;#5
			w Text_1_04, Text_2_04		;#6
			w Text_1_04, Text_2_07		;#7
			w Text_1_05, Text_2_06		;#8
			w Text_1_05, Text_2_04		;#9
			w Text_1_05, Text_2_07		;#10
			w Text_1_05, Text_2_08		;#11
			w Text_1_06, Text_2_16		;#12
			w Text_1_06, Text_2_04		;#13
			w Text_1_04, Text_2_09		;#14
			w Text_1_06, Text_2_07		;#15
			w Text_1_07, Text_2_10		;#16
			w Text_1_08, Text_2_11		;#17
			w Text_1_08, Text_2_12		;#18
			w Text_1_09, Text_2_13		;#19
			w Text_1_09, Text_2_14		;#20
			w Text_1_09, Text_2_15		;#21

if LANG = LANG_DE
:Text_1_02		b "GEOS/Registerkarten:",NULL
:Text_1_03		b "GEOS/Zeiger",NULL
:Text_1_04		b "GEOS/Dialogbox:",NULL
:Text_1_05		b "GEOS/Dateiauswahlbox:",NULL
:Text_1_06		b "GEOS/Fenster:",NULL
:Text_1_07		b "GEOS/PullDown-Menu",NULL
:Text_1_08		b "GEOS/Eingabefelder:",NULL
:Text_1_09		b "GEOS/Standard:",NULL

:Text_2_01		b "Balken und Pfeile",NULL
:Text_2_02		b "Aktives Register",NULL
:Text_2_03		b "Inaktives Register",NULL
:Text_2_04		b "Textfarbe/Hintergrund",NULL
:Text_2_05		b "Mauspfeil/Pointer",NULL
:Text_2_06		b "Titel",NULL
:Text_2_07		b "System-Icons",NULL
:Text_2_08		b "Dateifenster",NULL
:Text_2_09		b "Schatten",NULL
:Text_2_10		b "(Für GEOS-Anwendungen)",NULL
:Text_2_11		b "Text-Eingabefeld",NULL
:Text_2_12		b "Inaktives Optionsfeld",NULL
:Text_2_13		b "Hintergrund/Anwendungen",NULL
:Text_2_14		b "Rahmen",NULL
:Text_2_15		b "Mauszeiger",NULL
:Text_2_16		b "Titelzeile/Statuszeile",NULL
endif
if LANG = LANG_EN
:Text_1_02		b "GEOS/Register cards:",NULL
:Text_1_03		b "GEOS/Pointer",NULL
:Text_1_04		b "GEOS/Dialogue box:",NULL
:Text_1_05		b "GEOS/File selector box:",NULL
:Text_1_06		b "GEOS/Window:",NULL
:Text_1_07		b "GEOS/PullDown menu",NULL
:Text_1_08		b "GEOS/Input fields:",NULL
:Text_1_09		b "GEOS/Default:",NULL

:Text_2_01		b "Scrollbar and arrows",NULL
:Text_2_02		b "Active register",NULL
:Text_2_03		b "Inactive register",NULL
:Text_2_04		b "Text color/Background",NULL
:Text_2_05		b "Mouse/Pointer",NULL
:Text_2_06		b "Title",NULL
:Text_2_07		b "System icons",NULL
:Text_2_08		b "File window",NULL
:Text_2_09		b "Shadow",NULL
:Text_2_10		b "(For GEOS applications)",NULL
:Text_2_11		b "Input field for text",NULL
:Text_2_12		b "Inactive option field",NULL
:Text_2_13		b "Background/Applications",NULL
:Text_2_14		b "Border",NULL
:Text_2_15		b "Mouse",NULL
:Text_2_16		b "Titlebar/Statusbar",NULL
endif

;*** Tabelle zum ändern des Farbwertes.
;    Highbyte:		Textfarbe ändern.
;    Lowbyte:		Hintergrundfarbe ändern.
;    Byte #1:		Textfarbe.
;    Byte #2:		Hintergrundfarbe.
:ColModifyTab2		b %11110000,%00001111		;#0
			b %11110000,%00001111		;#1
			b %11110000,%00001111		;#2
			b %11110000,%00001111		;#3
			b %11110000,%00001111		;#4
			b %11110000,%00001111		;#5
			b %11110000,%00001111		;#6
			b %11110000,%00001111		;#7
			b %11110000,%00001111		;#8
			b %11110000,%00001111		;#9

:Vec2ColNames2		w Text_3_01, Text_4_01		;#0
			w Text_3_01, Text_4_02		;#1
			w Text_3_02, Text_4_03		;#2
			w Text_3_02, Text_4_04		;#3
			w Text_3_03, Text_4_05		;#4
			w Text_3_02, Text_4_06		;#5
			w Text_3_04, Text_4_07		;#6
			w Text_3_04, Text_4_08		;#7
			w Text_3_04, Text_4_09		;#8
			w Text_3_02, Text_4_10		;#9

if LANG = LANG_DE
:Text_3_01		b "GeoDesk/Fenster:",NULL
:Text_3_02		b "GeoDesk/DeskTop:",NULL
:Text_3_03		b "GeoDesk/Registermenu:",NULL
:Text_3_04		b "GeoDesk/AppLinks:",NULL

:Text_4_01		b "Scrollbalken",NULL
:Text_4_02		b "Scroll Up/Down",NULL
:Text_4_03		b "Datum und Uhrzeit",NULL
:Text_4_04		b "GEOS-Hauptmenü",NULL
:Text_4_05		b "Menü beenden",NULL
:Text_4_06		b "TaskBar",NULL
:Text_4_07		b "AppLink-Icon",NULL
:Text_4_08		b "AppLink-Titel/Name",NULL
:Text_4_09		b "Arbeitsplatz-Icon",NULL
:Text_4_10		b "DeskTop-Hintergrund",NULL
endif
if LANG = LANG_EN
:Text_3_01		b "GeoDesk/Window:",NULL
:Text_3_02		b "GeoDesk/DeskTop:",NULL
:Text_3_03		b "GeoDesk/Register menu:",NULL
:Text_3_04		b "GeoDesk/AppLinks:",NULL

:Text_4_01		b "Scrollbar",NULL
:Text_4_02		b "Scroll up/down",NULL
:Text_4_03		b "Date and Time",NULL
:Text_4_04		b "GEOS main menu",NULL
:Text_4_05		b "Exit menu",NULL
:Text_4_06		b "TaskBar",NULL
:Text_4_07		b "AppLink icon",NULL
:Text_4_08		b "AppLink title/name",NULL
:Text_4_09		b "MyComputer icon",NULL
:Text_4_10		b "DeskTop background",NULL
endif

;*** Icons.
:Icon_SETSCRN
<MISSING_IMAGE_DATA>
:Icon_SETSCRN_x		= .x
:Icon_SETSCRN_y		= .y

:Icon_SETPOS1
<MISSING_IMAGE_DATA>
:Icon_SETPOS1_x		= .x
:Icon_SETPOS1_y		= .y

:Icon_SETPOS2
<MISSING_IMAGE_DATA>
:Icon_SETPOS2_x		= .x
:Icon_SETPOS2_y		= .y

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g RegMenuBase
;******************************************************************************
