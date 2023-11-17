; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Fenster-Menü.

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
			n "obj.GD31"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenWinMenu

;*** Fenster-Menü.
:OpenWinMenu		lda	#< menuWindows
			sta	r0L
			lda	#> menuWindows
			sta	r0H
			jmp	OPEN_MENU

;*** Fenster-Menü.
if LANG = LANG_DE
:widthWindows = $57
endif
if LANG = LANG_EN
:widthWindows = $4f
endif

:MAX_ENTRY_SCRN		= 8
:m02y0			= ((MIN_AREA_BAR_Y-1) - MAX_ENTRY_SCRN*14 -2) & $f8
:m02y1			=  (MIN_AREA_BAR_Y-1)
:m02x0			= MAX_AREA_BAR_X - widthWindows
:m02x1			= MAX_AREA_BAR_X

:menuWindows		b m02y0
			b m02y1
			w m02x0
			w m02x1

			b MAX_ENTRY_SCRN!VERTICAL

			w :t1				;Arbeitsplatz öffnen.
			b MENU_ACTION
			w :m1

			w :t2				;Laufwerk A: öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;Laufwerk B: öffnen.
			b MENU_ACTION
			w :m3

			w :t4				;Laufwerk C: öffnen.
			b MENU_ACTION
			w :m4

			w :t5				;Laufwerk D: öffnen.
			b MENU_ACTION
			w :m5

			w :t6				;Fenster überlappend.
			b MENU_ACTION
			w :m6

			w :t7				;Fenster nebeneinander.
			b MENU_ACTION
			w :m7

			w :t8				;Alle Fenster schließen.
			b MENU_ACTION
			w :m8

if LANG = LANG_DE
::t1			b BOLDON
			b "Arbeitsplatz"
			b PLAINTEXT,NULL
::t2			b " >> Laufwerk A:",NULL
::t3			b " >> Laufwerk B:",NULL
::t4			b " >> Laufwerk C:",NULL
::t5			b " >> Laufwerk D:",NULL
::t6			b "Überlappend",NULL
::t7			b "Nebeneinander",NULL
::t8			b "Fenster schließen",NULL
endif

if LANG = LANG_EN
::t1			b BOLDON
			b "My Computer"
			b PLAINTEXT,NULL
::t2			b " >> Drive A:",NULL
::t3			b " >> Drive B:",NULL
::t4			b " >> Drive C:",NULL
::t5			b " >> Drive D:",NULL
::t6			b "Overlapping",NULL
::t7			b "Side by side",NULL
::t8			b "Close windows",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	OpenMyComputer		;Arbeitsplatz öffnen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_A		;Laufwerk A: öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_B		;Laufwerk B: öffnen.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_C		;Laufwerk C: öffnen.

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_D		;Laufwerk D: öffnen.

::m6			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	WM_FUNC_SORT		;Fenster überlappend anordnen.

::m7			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	WM_FUNC_POS		;Fenster nebeneinander anordnen.

::m8			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	WM_CLOSE_ALL_WIN	;Alle Fenster schließen.

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
