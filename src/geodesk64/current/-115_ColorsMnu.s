; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Optionen anzeigen.
:xCOLOR_SETUP		LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	ApplyConfig		;Farbe Mauszeiger übernehmen.

			bit	reloadDir		;Farbdatei gespeichert?
			bpl	:1			; => Nein, Ende...

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::1			jmp	MOD_REBOOT		;Zurück zu GeoDesk.

;*** Icon gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $97
:R1SizeX0		= $0020
:R1SizeX1		= $0117

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 3				;Anzahl Einträge.

			w RTabName1_1			;Register: "ANZEIGE".
			w RTabMenu1_1

			w RTabName1_2			;Register: "OPTIONEN".
			w RTabMenu1_2

			w RTabName1_3			;Register: "DATEI-ICONS".
			w RTabMenu1_3

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

;*** System-Icons.
:RIcon_Up		w IconUArrow
			b $00,$00
			b IconUArrow_x,IconUArrow_y
			b $01

:RIcon_Down		w IconDArrow
			b $00,$00
			b IconDArrow_x,IconDArrow_y
			b $01

:RIcon_Reset		w IconReset
			b $00,$00
			b IconReset_x,IconReset_y
			b $01

:RIcon_Save		w IconSave
			b $00,$00
			b IconSave_x,IconSave_y
			b $01

:RIcon_Load		w IconLoad
			b $00,$00
			b IconLoad_x,IconLoad_y
			b $01

:RIcon_CBM		w Icon_CBM
			b $00,$00
			b 3,21
			b $01

;*** Daten für Register "Farben".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RWidth1  = $0028
:RLine1_1 = $00
:RLine1_2 = $28
:RLine1_3 = $48
:RLine1_4 = $68

:RTabMenu1_1		b 14

			b BOX_FRAME			;----------------------------------------
				w R1T01
				w $0000
				b RPos1_y -$05
				b RPos1_y +RLine1_1 +$10 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$10
				w RPos1_x +RWidth1 -$01
				w R1SizeX1 -$18 +$01
			b BOX_USER			;----------------------------------------
				w R1T02
				w PrintCurColName
				b RPos1_y +RLine1_1
				b RPos1_y +RLine1_1 +$10 -$01
				w RPos1_x +RWidth1
				w R1SizeX1 -$18
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$10
				w R1SizeX1 -$18 +$01
				w R1SizeX1 -$10 +$01
			b BOX_ICON			;----------------------------------------
				w $0000
				w LastColEntry
				b RPos1_y +RLine1_1
				w R1SizeX1 -$18 +$01
				w RIcon_Up
				b $02
			b BOX_ICON			;----------------------------------------
				w $0000
				w NextColEntry
				b RPos1_y +RLine1_1 +$08
				w R1SizeX1 -$18 +$01
				w RIcon_Down
				b $02

			b BOX_FRAME			;----------------------------------------
				w R1T03
				w $0000
				b RPos1_y +RLine1_2 -$05
				b RPos1_y +RLine1_2 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08
:RegTMenu_1a		b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T04
				w PrintCurColorT
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +$08 -$01
				w R1SizeX1 -$28 +$01
				w R1SizeX1 -$10
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -$01
				b RPos1_y +RLine1_2 +$08
				w RPos1_x +RWidth1 -$01
				w RPos1_x +RWidth1 +$80
			b BOX_USER			;----------------------------------------
				w R1T04a
				w ColorInfoT
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +$08 -$01
				w RPos1_x +RWidth1
				w RPos1_x +RWidth1 +$80 -$01

			b BOX_FRAME			;----------------------------------------
				w R1T05
				w $0000
				b RPos1_y +RLine1_3 -$05
				b RPos1_y +RLine1_3 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08
:RegTMenu_1b		b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T06
				w PrintCurColorB
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$08 -$01
				w R1SizeX1 -$28 +$01
				w R1SizeX1 -$10
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_3 -$01
				b RPos1_y +RLine1_3 +$08
				w RPos1_x +RWidth1 -$01
				w RPos1_x +RWidth1 +$80
			b BOX_USER			;----------------------------------------
				w R1T06a
				w ColorInfoB
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$08 -$01
				w RPos1_x +RWidth1
				w RPos1_x +RWidth1 +$80 -$01

;*** Texte für Register "Farben".
if LANG = LANG_DE
:R1T01			b "BEREICH",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL

:R1T03			b "VORDERGRUND",NULL

:R1T04			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Farbe:",NULL

:R1T04a			w R1SizeX1 -$36
			b RPos1_y +RLine1_2 +$06
			b "->",NULL

:R1T05			b "HINTERGRUND",NULL

:R1T06			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Farbe:",NULL

:R1T06a			w R1SizeX1 -$36
			b RPos1_y +RLine1_3 +$06
			b "->",NULL
endif
if LANG = LANG_EN
:R1T01			b "AREA",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL

:R1T03			b "FOREGROUND",NULL

:R1T04			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Color:",NULL

:R1T04a			w R1SizeX1 -$36
			b RPos1_y +RLine1_2 +$06
			b "->",NULL

:R1T05			b "BACKGROUND",NULL

:R1T06			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Color:",NULL

:R1T06a			w R1SizeX1 -$36
			b RPos1_y +RLine1_3 +$06
			b "->",NULL
endif

;*** Daten für Register "Optionen".
:RPos2_x  = R1SizeX0 +$10
:RPos2_y  = R1SizeY0 +$10
;RWidth2  = $0000	;Pattern: GEOS.
:RWidth2a = $0058	;Pattern: GeoDesk.
:RWidth2b = $00b0	;Pattern: TaskBar.
:RPat     = $28		;Breite PatternBox.
:RLine2_1 = $00
:RLine2_2 = $28
:RLine2_3 = $38
:RLine2_4 = $48
:RLine2_5 = $28
:RLine2_6 = $40

:RTabMenu1_2		b 20

			b BOX_FRAME			;----------------------------------------
				w R2T01
				w $0000
				b RPos2_y +RLine2_1 -$05
				b RPos2_y +RLine2_1 +$10 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08
;--- Pattern: GEOS.
			b BOX_FRAME			;----------------------------------------
				w $0000
				w PrintPatGEOS
				b RPos2_y +RLine2_1 -$01
				b RPos2_y +RLine2_1 +$10
				w RPos2_x +$20 -$01
				w RPos2_x +$20 +RPat
			b BOX_USER_VIEW			;----------------------------------------
				w R2T02a
				w $0000
				b RPos2_y +RLine2_1
				b RPos2_y +RLine2_1 +$10 -$01
				w RPos2_x +$20
				w RPos2_x +$20 +RPat -$08 -$01
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetPrevBackPat
				b RPos2_y +RLine2_1
				w RPos2_x +$20 +RPat -$08
				w RIcon_Up
				b $02
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetNextBackPat
				b RPos2_y +RLine2_1 +$08
				w RPos2_x +$20 +RPat -$08
				w RIcon_Down
				b $02

;--- Pattern: GeoDesk.
			b BOX_FRAME			;----------------------------------------
				w $0000
				w PrintPatGDesk
				b RPos2_y +RLine2_1 -$01
				b RPos2_y +RLine2_1 +$10
				w RPos2_x +RWidth2a +$28 -$01
				w RPos2_x +RWidth2a +$28 +RPat
			b BOX_USER_VIEW			;----------------------------------------
				w R2T02b
				w $0000
				b RPos2_y +RLine2_1
				b RPos2_y +RLine2_1 +$10 -$01
				w RPos2_x +RWidth2a +$28
				w RPos2_x +RWidth2a +$28 +RPat -$08 -$01
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetPrevBackPatGD
				b RPos2_y +RLine2_1
				w RPos2_x +RWidth2a +$28 +RPat -$08
				w RIcon_Up
				b $02
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetNextBackPatGD
				b RPos2_y +RLine2_1 +$08
				w RPos2_x +RWidth2a +$28 +RPat -$08
				w RIcon_Down
				b $02

;--- Pattern: TaskBar.
			b BOX_FRAME			;----------------------------------------
				w $0000
				w PrintPatTaskB
				b RPos2_y +RLine2_1 -$01
				b RPos2_y +RLine2_1 +$10
				w RPos2_x +RWidth2b +$00 -$01
				w RPos2_x +RWidth2b +$00 +RPat
			b BOX_USER_VIEW			;----------------------------------------
				w $0000
				w $0000
				b RPos2_y +RLine2_1
				b RPos2_y +RLine2_1 +$10 -$01
				w RPos2_x +RWidth2b +$00
				w RPos2_x +RWidth2b +$00 +RPat -$08 -$01
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetPrevBackPatTB
				b RPos2_y +RLine2_1
				w RPos2_x +RWidth2b +$00 +RPat -$08
				w RIcon_Up
				b $02
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetNextBackPatTB
				b RPos2_y +RLine2_1 +$08
				w RPos2_x +RWidth2b +$00 +RPat -$08
				w RIcon_Down
				b $02

;--- Reset.
			b BOX_FRAME			;----------------------------------------
				w R2T03
				w $0000
				b RPos2_y +RLine2_2 -$05
				b RPos2_y +RLine2_4 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX0 +$08 +$a0 -$01
			b BOX_ICON			;----------------------------------------
				w R2T04a
				w ResetCol_GEOS
				b RPos2_y +RLine2_2
				w R1SizeX0 +$08 +$a0 -$10
				w RIcon_Reset
				b $02
			b BOX_ICON			;----------------------------------------
				w R2T04b
				w ResetCol_GDESK
				b RPos2_y +RLine2_3
				w R1SizeX0 +$08 +$a0 -$10
				w RIcon_Reset
				b $02
			b BOX_ICON			;----------------------------------------
				w R2T04c
				w ResetCol_FICON
				b RPos2_y +RLine2_4
				w R1SizeX0 +$08 +$a0 -$10
				w RIcon_Reset
				b $02

;--- Save/Load.
			b BOX_FRAME			;----------------------------------------
				w R2T06
				w $0000
				b RPos2_y +RLine2_5 -$05
				b RPos2_y +RLine2_6 +$10 +$04
				w R1SizeX0 +$08 +$98 +$10
				w R1SizeX1 -$08
			b BOX_ICON			;----------------------------------------
				w R2T07
				w svColorConfig
				b RPos2_y +RLine2_5
				w R1SizeX1 -$20 +$04
				w RIcon_Save
				b $02
			b BOX_ICON			;----------------------------------------
				w R2T08
				w ldColorConfig
				b RPos2_y +RLine2_6
				w R1SizeX1 -$20 +$04
				w RIcon_Load
				b $02

;*** Texte für Register "Optionen".
if LANG = LANG_DE
:R2T01			b "HINTERGRUNDMUSTER",NULL

:R2T02a			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "GEOS",NULL
:R2T02b			w RPos2_x +RWidth2a -$0a
			b RPos2_y +RLine2_1 +$06
			b "GeoDesk/"
			b GOTOXY
			w RPos2_x +RWidth2a -$0a
			b RPos2_y +RLine2_1 +$08 +$06
			b "TaskBar",NULL

:R2T03			b "VOREINSTELLUNGEN",NULL

:R2T04a			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "GEOS/MegaPatch",NULL

:R2T04b			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "GeoDesk/Extras",NULL

:R2T04c			w RPos2_x
			b RPos2_y +RLine2_4 +$06
			b "GeoDesk/Datei-Icons",NULL

:R2T06			b "DATEI",NULL

:R2T07			w RPos2_x +$98 +$10
			b RPos2_y +RLine2_5 +$0a
			b "SAVE",NULL

:R2T08			w RPos2_x +$98 +$10
			b RPos2_y +RLine2_6 +$0a
			b "LOAD",NULL
endif
if LANG = LANG_EN
:R2T01			b "BACKGROUND PATTERN",NULL

:R2T02a			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "GEOS",NULL
:R2T02b			w RPos2_x +RWidth2a -$0a
			b RPos2_y +RLine2_1 +$06
			b "GeoDesk/"
			b GOTOXY
			w RPos2_x +RWidth2a -$0a
			b RPos2_y +RLine2_1 +$08 +$06
			b "TaskBar",NULL

:R2T03			b "DEFAULT SETTINGS",NULL

:R2T04a			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "GEOS/MegaPatch",NULL

:R2T04b			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "GeoDesk/Extras",NULL

:R2T04c			w RPos2_x
			b RPos2_y +RLine2_4 +$06
			b "GeoDesk/File icons",NULL

:R2T06			b "FILE",NULL

:R2T07			w RPos2_x +$98 +$10
			b RPos2_y +RLine2_5 +$0a
			b "SAVE",NULL

:R2T08			w RPos2_x +$98 +$10
			b RPos2_y +RLine2_6 +$0a
			b "LOAD",NULL
endif

;*** Daten für Register "Datei-Icons".
:RPos3_x  = R1SizeX0 +$10
:RPos3_y  = R1SizeY0 +$10
:RWidth3  = $0028
:RLine3_1 = $00
:RLine3_2 = $10
:RLine3_3 = $30
:RLine3_4 = $38

:RTabMenu1_3		b 9

			b BOX_FRAME			;----------------------------------------
				w R3T01
				w $0000
				b RPos3_y -$05
				b RPos3_y +RLine3_2 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos3_y +RLine3_1 -$01
				b RPos3_y +RLine3_1 +$08
				w RPos3_x +RWidth3 -$01
				 w R1SizeX1 -$10 +$01
			b BOX_USER			;----------------------------------------
				w R3T02
				w PrintCurIColName
				b RPos3_y +RLine3_1
				b RPos3_y +RLine3_1 +$08 -$01
				w RPos3_x +RWidth3
				 w R1SizeX1 -$18
			b BOX_ICON			;----------------------------------------
				w $0000
				w NextIColEntry
				b RPos3_y +RLine3_1
				w R1SizeX1 -$18 +$01
				w RIcon_Down
				b $02

:RegTMenu_3a		b BOX_USEROPT_VIEW		;----------------------------------------
				w R3T04
				w PrintCurIColor
				b RPos3_y +RLine3_2
				b RPos3_y +RLine3_2 +$08 -$01
				w R1SizeX1 -$28 +$01
				 w R1SizeX1 -$10
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos3_y +RLine3_2 -$01
				b RPos3_y +RLine3_2 +$08
				w RPos3_x +RWidth3 -$01
				 w RPos3_x +RWidth3 +$80
			b BOX_USER			;----------------------------------------
				w R3T04a
				w ColorInfoI
				b RPos3_y +RLine3_2
				b RPos3_y +RLine3_2 +$08 -$01
				w RPos3_x +RWidth3
				 w RPos3_x +RWidth3 +$80 -$01

			b BOX_ICON			;----------------------------------------
				w $0000
				w $0000
				b RPos3_y +RLine3_4
				w R1SizeX1 -$28 +$01
				w RIcon_CBM
				b $02
			b BOX_FRAME			;----------------------------------------
				w R3T05
				w setColPreview
				b RPos3_y +RLine3_3 -$05
				b R1SizeY1 -$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;*** Texte für Register "Datei-Icons".
if LANG = LANG_DE
:R3T01			b "DATEITYP",NULL

:R3T02			w RPos3_x
			b RPos3_y +RLine3_1 +$06
			b "Name:",NULL

:R3T03			b "ICON-FARBE",NULL

:R3T04			w RPos3_x
			b RPos3_y +RLine3_2 +$06
			b "Farbe:",NULL

:R3T04a			w R1SizeX1 -$36
			b RPos3_y +RLine3_2 +$06
			b "->",NULL

:R3T05			b "VORSCHAU/INFO"
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$06
			b "Das Beispiel-Icon zeigt eine"
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$08 +$06
			b "Vorschau auf den Dateityp."
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$14 +$06
			b "Farbe `SCHWARZ` wird durch die"
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$1c +$06
			b "Fenster/Textfarbe ersetzt!"
			b NULL
endif
if LANG = LANG_EN
:R3T01			b "FILE TYPE",NULL

:R3T02			w RPos3_x
			b RPos3_y +RLine3_1 +$06
			b "Name:",NULL

:R3T03			b "ICON-COLOR",NULL

:R3T04			w RPos3_x
			b RPos3_y +RLine3_2 +$06
			b "Color:",NULL

:R3T04a			w R1SizeX1 -$36
			b RPos3_y +RLine3_2 +$06
			b "->",NULL

:R3T05			b "PREVIEW/INFO"
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$06
			b "The sample icon shows a"
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$08 +$06
			b "preview for the file type."
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$14 +$06
			b "`Black` color will be replaced"
			b GOTOXY
			w RPos3_x
			b RPos3_y +RLine3_3 +$1c +$06
			b "by window/text color!"
			b NULL
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

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_3		= RCardIconX_1 + RTabIcon1_x
:RCardIconX_2		= RCardIconX_3 + RTabIcon3_x

;*** System-Icons.
:IconUArrow
<MISSING_IMAGE_DATA>

:IconUArrow_x		= .x
:IconUArrow_y		= .y

:IconDArrow
<MISSING_IMAGE_DATA>

:IconDArrow_x		= .x
:IconDArrow_y		= .y

:IconReset
<MISSING_IMAGE_DATA>

:IconReset_x		= .x
:IconReset_y		= .y

:IconSave
<MISSING_IMAGE_DATA>

:IconSave_x		= .x
:IconSave_y		= .y

:IconLoad
<MISSING_IMAGE_DATA>

:IconLoad_x		= .x
:IconLoad_y		= .y
