; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* DeskTop-Menü.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_CHAR"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "s.GD.21.Desk.ext"
endif

;*** GEOS-Header.
			n "obj.GD33"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenDeskTop

;*** PopUp/DeskTop.
:OpenDeskTop		ldx	WM_WCODE		;Fenster-Nr. einlesen.

			ldy	#" "			;Applink: Titel anzeigen.
			lda	GD_LNK_TITLE
			beq	:1
			ldy	#"*"
::1			sty	t6 +1

			ldy	#" "			;AppLink: Gesperrt.
			lda	GD_LNK_LOCK
			beq	:2
			ldy	#"*"
::2			sty	t7 +1

			ldy	#" "			;Desktop: Hintergrundbild zeigen.
			lda	sysRAMFlg
			and	#%00001000
			beq	:3
			ldy	#"*"
::3			sty	t5 +1

			ldx	#GMOD_GPSHOW
			ldy	GD_DACC_ADDR_B,x	;GPShow-Modul installiert?
			beq	:no_gpshow		; => Nein, weiter...
::gpshow		lda	#PLAINTEXT
			b $2c
::no_gpshow		lda	#ITALICON
			sta	t4

			lda	#< menuDeskTop
			sta	r0L
			lda	#> menuDeskTop
			sta	r0H
			lda	#widthDeskTop
			sta	r5H
			jsr	MENU_SET_SIZE
			jmp	OPEN_MENU

;*** PopUp/DeskTop.
if LANG = LANG_DE
:widthDeskTop = $67
endif
if LANG = LANG_EN
:widthDeskTop = $5f
endif

:menuDeskTop		b $00,$00
			w $0000,$0000

			b 8!VERTICAL

			w t1				;Fenster überlappend.
			b MENU_ACTION
			w :m1

			w t2				;Fenster Nebeneinander.
			b MENU_ACTION
			w :m2

			w t3				;Hintergrundbild ändern.
			b MENU_ACTION
			w :m3

			w t4				;Diashow starten.
			b MENU_ACTION
			w :m4

			w t5				;Hintergrundbild ein/aus.
			b MENU_ACTION
			w :m5

			w t6				;AppLink-Titel anzeigen.
			b MENU_ACTION
			w :m6

			w t7				;AppLinks sperren.
			b MENU_ACTION
			w :m7

			w t8				;Alle Fenster schließen.
			b MENU_ACTION
			w :m8

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_WIN_SORT

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_WIN_POS

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_BACKSCRN

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_GPSHOW

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_BACK_SCREEN

::m6			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_VIEW_ALTITLE

::m7			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_LOCK_APPLINK

::m8			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	WM_CLOSE_ALL_WIN

if LANG = LANG_DE
:t1			b "Überlappend",NULL
:t2			b "Nebeneinander",NULL
:t3			b "Hintergrund wechseln",NULL
:t4			b PLAINTEXT
			b "Diashow starten"
			b PLAINTEXT,NULL
:t5			b "( ) Hintergrundbild",NULL
:t6			b "( ) Titel anzeigen",NULL
:t7			b "( ) AppLink sperren",NULL
:t8			b "Fenster schließen",NULL
endif

if LANG = LANG_EN
:t1			b "Overlapping",NULL
:t2			b "Side by side",NULL
:t3			b "Select wallpaper",NULL
:t4			b PLAINTEXT
			b "Start slide show"
			b PLAINTEXT,NULL
:t5			b "( ) Wallpaper",NULL
:t6			b "( ) Show titles",NULL
:t7			b "( ) Lock AppLinks",NULL
:t8			b "Close windows",NULL
endif

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
