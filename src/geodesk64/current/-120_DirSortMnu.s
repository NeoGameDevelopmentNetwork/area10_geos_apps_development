; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Verzeichnis sortieren.
:xSORTDIR

if SORTMODE64K  = TRUE
			jsr	FindFreeBank		;64K für DACC-Sortieren suchen.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			sty	sort64Kbank		;Speicherbank merken.
			jsr	AllocateBank		;Speicher reservieren.
			jmp	:readFiles		; => Weiter...

::noram			LoadW	r0,Dlg_NoFreeRAM	; => Kein freier Speicher.
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	ExitRegMenuUser		;Zurück zum DeskTop.

::readFiles		jsr	Read64kDir		;Dateien in DACC einlesen.
endif

if SORTMODE64K  = FALSE
::readFiles		jsr	Read224Dir		;Dateien in RAM einlesen.
endif

;--- Dateien eingelesen, Fortsetzung.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

if SORTMODE64K  = TRUE
			lda	SortS_MaxH		;Max. Anzahl Dateien einlesen.
			bne	:1
			lda	SortS_Max
			cmp	#2			;Nichts zum sortieren?
			bcc	exitDirSort		; => Ja, Ende...
::1
endif

if SORTMODE64K  = FALSE
			lda	SortS_Max		;Max. Anzahlk Dateien einlesen.
			cmp	#2			;Nichts zum sortieren?
			bcc	exitDirSort		; => Ja, Ende...
endif

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;--- Laufwerksfehler.
::error			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

;*** Zurück zum DeskTop.
:ExitRegMenuUser

if SORTMODE64K  = TRUE
			ldy	sort64Kbank		;Speicher für DACC-Sortierung
			beq	:1			;freigeben.
			jsr	FreeBank
::1
endif

			bit	reloadDir		;Verzeichnis aktualisieren?
			bpl	exitDirSort		; => Nein, Ende...

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
:exitDirSort		jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Verzeichnis schreiben" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	jsr	S_SetAll
			jsr	TakeSource

if SORTMODE64K  = FALSE
			jsr	Write224Dir		;Verzeichnis aktualisieren.
endif

if SORTMODE64K  = TRUE
			jsr	Write64kDir		;Verzeichnis aktualisieren.
endif
			txa				;Fehler?
			beq	:1

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
;			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

			lda	#$00			;Verzeichnis nicht aktualisieren.
			b $2c
::1			lda	#$ff			;Verzeichnis aktualisieren.
			sta	reloadDir

			ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

if SORTMODE64K = TRUE
:sort64Kbank		b $00				;Speicherbank für DACC-Sortieren.
endif

if SORTMODE64K = TRUE
;*** Nicht genügend freier Speicher.
:Dlg_NoFreeRAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL
endif

if SORTMODE64K!LANG = TRUE!LANG_DE
::1			b PLAINTEXT,BOLDON
			b "FEHLER!",NULL

::2			b PLAINTEXT
			b "Dateien ordnen erfordert",NULL
::3			b "64Kb freien GEOS-Speicher!",NULL
::4			b "Funktion wird abgebrochen.",NULL
endif
if SORTMODE64K!LANG = TRUE!LANG_EN
::1			b PLAINTEXT,BOLDON
			b "ERROR!",NULL

::2			b PLAINTEXT
			b "Sorting files requires 64Kb",NULL
::3			b "of free GEOS memory!",NULL
::4			b "Function cancelled.",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $08
:R1SizeY1		= $b7
:R1SizeX0		= $0000
:R1SizeX1		= $013f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RTabName1_1			;Register: "DIRSORT".
			w RTabMenu1_1

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

;*** System-Icons.
:RIcon_Up		w IconUArrow
			b $00,$00
			b IconUArrow_x,IconUArrow_y
			b $01

:RIcon_Down		w IconDArrow
			b $00,$00
			b IconDArrow_x,IconDArrow_y
			b $01

:RIcon_Add		w IconAddFiles
			b $00,$00
			b IconAddFiles_x,IconAddFiles_y
			b $01

:RIcon_Sub		w IconSubFiles
			b $00,$00
			b IconSubFiles_x,IconSubFiles_y
			b $01

:RIcon_Page		w IconPage
			b $00,$00
			b IconPage_x,IconPage_y
			b $01

:RIcon_Select		w IconSelect
			b $00,$00
			b IconSelect_x,IconSelect_y
			b $01

:RIcon_Unselect		w IconUnselect
			b $00,$00
			b IconUnselect_x,IconUnselect_y
			b $01

:RIcon_Reset		w IconReset
			b $00,$00
			b IconReset_x,IconReset_y
			b $01

:RIcon_Save		w IconSave
			b $00,$00
			b IconSave_x,IconSave_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DIRSORT".
:NO_OPT_UPDATE		= NULL
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RWidth1  = $0028
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $40

:RTabMenu1_1		b (22 + SORT64K_ENTRIES + SORTFINFO_ENTRIES)

;--- Source.
::1			b BOX_USER			;----------------------------------------
				w $0000
				w SlctSource
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX0 +$08
				w R1SizeX0 +$a0 -$10 -$01
::2			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX0 +$08
				w R1SizeX0 +$a0 -$10 -$01
::3			b BOX_ICON			;----------------------------------------
				w $0000
				w S_FileUp
				b R1SizeY0 +SB_YPosMin -$08
				w R1SizeX0 +$a0 -$10
				w RIcon_Up
				b NO_OPT_UPDATE
::4			b BOX_ICON			;----------------------------------------
				w $0000
				w S_FileDown
				b R1SizeY1 -$30 +$01
				w R1SizeX0 +$a0 -$10
				w RIcon_Down
				b NO_OPT_UPDATE
::5			b BOX_ICON			;----------------------------------------
				w $0000
				w TakeSource
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$08
				w RIcon_Add
				b NO_OPT_UPDATE
::6			b BOX_ICON			;----------------------------------------
				w $0000
				w S_Reset
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$30
				w RIcon_Unselect
				b NO_OPT_UPDATE
::7			b BOX_ICON			;----------------------------------------
				w $0000
				w S_SetAll
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$40
				w RIcon_Select
				b NO_OPT_UPDATE
::8			b BOX_ICON			;----------------------------------------
				w $0000
				w S_SetPage
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$50
				w RIcon_Page
				b NO_OPT_UPDATE
::9			b BOX_USER			;----------------------------------------
				w $0000
				w S_ChkBalken
				b R1SizeY0 +SB_YPosMin
				b R1SizeY1 -$30
				w R1SizeX0 +$a0 -$10
				w R1SizeX0 +$a0 -$08 -$01
::10			b BOX_FRAME			;----------------------------------------
				w R1T01
				w DrawFileList_ST
				b R1SizeY0 +SB_YPosMin -$08 -$01
				b R1SizeY1 -$28 +$01
				w R1SizeX0 +$08 -$01
				w R1SizeX0 +$a0 -$08

;--- Target.
::11			b BOX_USER			;----------------------------------------
				w $0000
				w SlctTarget
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX1 -$a0 +$08 +$01
				w R1SizeX1 -$10
::12			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX1 -$a0 +$08 +$01
				w R1SizeX1 -$10
::13			b BOX_ICON			;----------------------------------------
				w $0000
				w T_FileUp
				b R1SizeY0 +SB_YPosMin -$08
				w R1SizeX1 -$10 +$01
				w RIcon_Up
				b NO_OPT_UPDATE
::14			b BOX_ICON			;----------------------------------------
				w $0000
				w T_FileDown
				b R1SizeY1 -$30 +$01
				w R1SizeX1 -$10 +$01
				w RIcon_Down
				b NO_OPT_UPDATE
::15			b BOX_ICON			;----------------------------------------
				w $0000
				w TakeTarget
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$08 +$01
				w RIcon_Sub
				b NO_OPT_UPDATE
::16			b BOX_ICON			;----------------------------------------
				w $0000
				w T_Reset
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$30 +$01
				w RIcon_Unselect
				b NO_OPT_UPDATE
::17			b BOX_ICON			;----------------------------------------
				w $0000
				w T_SetAll
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$40 +$01
				w RIcon_Select
				b NO_OPT_UPDATE
::18			b BOX_ICON			;----------------------------------------
				w $0000
				w T_SetPage
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$50 +$01
				w RIcon_Page
				b NO_OPT_UPDATE
::19			b BOX_ICON			;----------------------------------------
				w $0000
				w ResetDir
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$68 +$01
				w RIcon_Reset
				b NO_OPT_UPDATE
::20			b BOX_USER			;----------------------------------------
				w $0000
				w T_ChkBalken
				b R1SizeY0 +SB_YPosMin
				b R1SizeY1 -$30
				w R1SizeX1 -$10 +$01
				w R1SizeX1 -$08
::21			b BOX_FRAME			;----------------------------------------
				w R1T02
				w InitSortMenu
				b R1SizeY0 +SB_YPosMin -$08 -$01
				b R1SizeY1 -$28 +$01
				w R1SizeX1 -$a0 +$08
				w R1SizeX1 -$08 +$01

;--- SAVE-Icon.
::22			b BOX_ICON			;----------------------------------------
				w R1T03
				w EXEC_REG_ROUT
				b R1SizeY0 +$08
				w R1SizeX0 +$10
				w RIcon_Save
				b NO_OPT_UPDATE

;--- Datei-Informationen anzeigen.
if SORTFINFO = TRUE
:RTabMenu1_1a		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w prntFIcon
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$18 -$01
				w R1SizeX1 -$08 -$18 +$01
				w R1SizeX1 -$08

:RTabMenu1_1b		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w prntFInfo
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$18 -$01
				w R1SizeX1 -$a0 +$08 +$01
				w R1SizeX1 -$10 -$18

::25			b BOX_OPTION			;----------------------------------------
				w R1T04
				w setOptFInfo
				b R1SizeY0 +$08
				w R1SizeX1 -$a0 -$28 +$01
				w OPT_SORTFINFO
				b %11111111
endif

;--- AutoSelect-Modus.
if SORTMODE64K = TRUE
::26			b BOX_OPTION			;----------------------------------------
				w R1T05
				w $0000
				b R1SizeY0 +$08 +SORTINFO_MODE*$10
				w R1SizeX1 -$a0 -$28 +$01
				w OPT_AUTOSLCT
				b %11111111
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DIRSORT".
if LANG = LANG_DE
:R1T01			b "ORIGINAL",NULL

:R1T02			b "SORTIERT",NULL

:R1T03			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$06
			b "Verzeichnis"
			b GOTOXY
			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$08 +$06
			b "speichern",NULL
endif
if LANG = LANG_EN
:R1T01			b "ORIGINAL",NULL

:R1T02			b "SORTED",NULL

:R1T03			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$06
			b "Write sorted"
			b GOTOXY
			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$08 +$06
			b "directory",NULL
endif

;--- Datei-Info.
:R1T04			w R1SizeX1 -$a0 -$28 +$01 +$0c
			b R1SizeY0 +$08 +$06
			b "Info",NULL
;--- AutoSelect.
:R1T05			w R1SizeX1 -$a0 -$28 +$01 +$0c
			b R1SizeY0 +$08 +SORTINFO_MODE*$10 +$06
			b "Auto",NULL

;*** Icons für Registerkarten.
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

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons.
:IconUArrow
<MISSING_IMAGE_DATA>

:IconUArrow_x		= .x
:IconUArrow_y		= .y

:IconDArrow
<MISSING_IMAGE_DATA>

:IconDArrow_x		= .x
:IconDArrow_y		= .y

:IconAddFiles
<MISSING_IMAGE_DATA>

:IconAddFiles_x		= .x
:IconAddFiles_y		= .y

:IconSubFiles
<MISSING_IMAGE_DATA>

:IconSubFiles_x		= .x
:IconSubFiles_y		= .y

:IconSelect
<MISSING_IMAGE_DATA>

:IconSelect_x		= .x
:IconSelect_y		= .y

:IconUnselect
<MISSING_IMAGE_DATA>

:IconUnselect_x		= .x
:IconUnselect_y		= .y

:IconPage
<MISSING_IMAGE_DATA>

:IconPage_x		= .x
:IconPage_y		= .y

:IconReset
<MISSING_IMAGE_DATA>

:IconReset_x		= .x
:IconReset_y		= .y

:IconSave
<MISSING_IMAGE_DATA>

:IconSave_x		= .x
:IconSave_y		= .y
