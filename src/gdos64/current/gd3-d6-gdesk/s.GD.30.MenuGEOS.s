; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GEOS-Menü.

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
			n "obj.GD30"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenGEOS

;*** GEOS-Menü öffnen.
:OpenGEOS		ldx	#GMOD_INFO
			ldy	GD_DACC_ADDR_B,x	;Info-Modul installiert?
			beq	:no_info		; => Nein, weiter...
::info			lda	#PLAINTEXT
			b $2c
::no_info		lda	#ITALICON
			sta	t14

			ldx	#GMOD_ICONMAN
			ldy	GD_DACC_ADDR_B,x	;IconManager-Modul installiert?
			beq	:no_iman		; => Nein, weiter...
::iman			lda	#PLAINTEXT
			b $2c
::no_iman		lda	#ITALICON
			sta	t47

			lda	#< menuGEOS
			sta	r0L
			lda	#> menuGEOS
			sta	r0H
			jmp	OPEN_MENU

;*** GEOS-Hauptmenü.
:MAX_ENTRY_GEOS		= 5
:m01y0			= ((MIN_AREA_BAR_Y-1) - MAX_ENTRY_GEOS*14 -2) & $f8
:m01y1			=  (MIN_AREA_BAR_Y-1)
:m01x0			= MIN_AREA_BAR_X
:m01x1			= $004f
:m01w			= (m01x1 - m01x0 +1)

:menuGEOS		b m01y0
			b m01y1
			w m01x0
			w m01x1

			b MAX_ENTRY_GEOS!VERTICAL

			w t11				;Anwendungen starten.
			b DYN_SUB_MENU
			w :m1

			w t12				;Dokumente öffnen.
			b DYN_SUB_MENU
			w :m2

			w t13				;Einstellungen.
			b DYN_SUB_MENU
			w :m3

			w t14				;Einstellungen.
			b MENU_ACTION
			w :m4

			w t19				;GeoDesk beenden.
			b DYN_SUB_MENU
			w :m9

::m1			lda	#< menuGEOS_Appl	;GEOS/Anwendungen.
			ldx	#> menuGEOS_Appl
			jmp	MENU_SETINT_AX

::m2			lda	#< menuGEOS_Docs	;GEOS/Dokumente.
			ldx	#> menuGEOS_Docs
			jmp	MENU_SETINT_AX

::m3			lda	#< menuGEOS_Setup	;GEOS/Einstellungen.
			ldx	#> menuGEOS_Setup
			jmp	MENU_SETINT_AX

::m4			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jsr	SUB_SHOWHELP		;Hilfe anzeigen.
			jmp	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.

::m9			lda	#< menuGEOS_Exit	;GEOS/Beenden.
			ldx	#> menuGEOS_Exit
			jmp	MENU_SETINT_AX

if LANG = LANG_DE
:t11			b "Programme >>",NULL
:t12			b "Dokumente >>",NULL
:t13			b "Einstellungen >>",NULL
:t14			b PLAINTEXT
			b "Hilfe"
			b PLAINTEXT,NULL
:t19			b "Beenden >>",NULL
endif

if LANG = LANG_EN
:t11			b "Applications >>",NULL
:t12			b "Documents >>",NULL
:t13			b "Settings >>",NULL
:t14			b PLAINTEXT
			b "Help"
			b PLAINTEXT,NULL
:t19			b "Exit GeoDesk >>",NULL
endif

;*** GEOS/Programme
:MAX_ENTRY_APPL		= 3
:m03y0			= ((m01y0 + 32 - MAX_ENTRY_APPL*14 -2) & $f8)  -0 -0
:m03y1			=  (m03y0 + MAX_ENTRY_APPL*16 )                -0 -1
:m03x0			= m01x1  + 1 - (m01w/2)
if LANG = LANG_DE
:m03x1			= m03x0 + $0047
endif
if LANG = LANG_EN
:m03x1			= m03x0 + $004f
endif

:menuGEOS_Appl		b m03y0
			b m03y1
			w m03x0
			w m03x1

			b MAX_ENTRY_APPL!VERTICAL

			w :t1				;Anwendungen.
			b MENU_ACTION
			w :m1

			w :t2				;AutoExec-Programme.
			b MENU_ACTION
			w :m2

			w :t3				;Hilfsmittel.
			b MENU_ACTION
			w :m3

if LANG = LANG_DE
::t1			b "Anwendungen",NULL
::t2			b "Autostart",NULL
::t3			b "Hilfsmittel",NULL
endif

if LANG = LANG_EN
::t1			b "Applications",NULL
::t2			b "Autoexec files",NULL
::t3			b "DeskAccessories",NULL
endif

::m1			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_APPL		;Anwendungen.

::m2			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_AUTO		;AutoStart-Programme..

::m3			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_DA		;Hilfsmittel.

;*** GEOS/Dokumente
:MAX_ENTRY_DOCS		= 3
:m04y0			= ((m01y0 + 40 - MAX_ENTRY_DOCS*14 -2) & $f8)  -0 -0
:m04y1			=  (m04y0 + MAX_ENTRY_DOCS*16 )                -0 -1
:m04x0			= m01x1  + 1 - (m01w/2)
:m04x1			= m04x0 + $0037

:menuGEOS_Docs		b m04y0
			b m04y1
			w m04x0
			w m04x1

			b MAX_ENTRY_DOCS!VERTICAL

			w :t1				;Dokumente.
			b MENU_ACTION
			w :m1

			w :t2				;GeoWrite.
			b MENU_ACTION
			w :m2

			w :t3				;GeoPaint.
			b MENU_ACTION
			w :m3

if LANG = LANG_DE
::t1			b "Dokumente",NULL
::t2			b "GeoWrite",NULL
::t3			b "GeoPaint",NULL
endif

if LANG = LANG_EN
::t1			b "Documents",NULL
::t2			b "GeoWrite",NULL
::t3			b "GeoPaint",NULL
endif

::m1			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_DOCS		;Alle Dokumente.

::m2			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_WRITE		;GeoWrite-Dokumente.

::m3			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_PAINT		;GeoPaint-Dokumente.

;*** GEOS/Einstellungen
:MAX_ENTRY_SETUP	= 10
:m06y0			= (((MIN_AREA_BAR_Y-1) - MAX_ENTRY_SETUP*14 -2) & $f8) -8 -0
:m06y1			=  (MIN_AREA_BAR_Y-1)                                  -8 -0
:m06x0			= m01x1  + 1 - (m01w/2)
if LANG = LANG_DE
:m06x1			= m06x0 + $0077
endif
if LANG = LANG_EN
:m06x1			= m06x0 + $0067
endif

:menuGEOS_Setup		b m06y0
			b m06y1
			w m06x0
			w m06x1

			b MAX_ENTRY_SETUP!VERTICAL

			w t41				;Einstellungen: GEOS.
			b MENU_ACTION
			w :m1

			w t42				;Einstellungen: GeoDesk.
			b MENU_ACTION
			w :m2

			w t43				;Einstellungen speichern.
			b MENU_ACTION
			w :m3

			w t44				;Drucker wechseln.
			b MENU_ACTION
			w :m4

			w t45				;Eingabegerät wechseln.
			b MENU_ACTION
			w :m5

			w t46				;Hintergrundbild ändern.
			b MENU_ACTION
			w :m6

			w t47				;GeoDesk-Icons ändern.
			b MENU_ACTION
			w :m7

			w t47a				;GeoDesk-Module ändern.
			b MENU_ACTION
			w :m7a

			w t48				;AppLinks speichern.
			b MENU_ACTION
			w :m8

			w t49				;Datum/Uhrzeit ändern.
			b MENU_ACTION
			w :m9

::m1			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	OpenGDConfig		;Einstellungen -> GEOS/GD.CONFIG.

::m2			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPTIONS		;Einstellungen -> GeoDesk.

::m3			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_SAVE_CONFIG		;Konfiguration speichern.

::m4			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	EXT_PRINTDBOX		;Druckertreiber wählen.

::m5			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	EXT_INPUTDBOX		;Eingabetreiber wählen.

::m6			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_BACKSCRN		;Hintergrundbild wechseln.

::m7			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
;			jmp	MOD_ICONMAN		;GeoDesk-Icons ändern.

::MOD_ICONMAN		lda	#$00			;Icon-Manager.
			ldx	#GMOD_ICONMAN
			jmp	EXEC_MODULE

::m7a			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_GDESKMOD		;GeoDesk-Module ändern.

::m8			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jsr	SUB_LNK_SV_DATA		;AppLinks speichern.
			jmp	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.

::m9			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_SYSTIME		;Systemzeit setzen.

if LANG = LANG_DE
:t41			b "Einstellungen -> GEOS",NULL
:t42			b "Optionen -> GeoDesk",NULL
:t43			b "Optionen speichern",NULL
:t44			b "Drucker wechseln",NULL
:t45			b "Eingabegerät wechseln",NULL
:t46			b "Hintergrundbild wechseln",NULL
:t47			b PLAINTEXT
			b "GeoDesk-Icons ändern"
			b PLAINTEXT,NULL
:t47a			b "GeoDesk-Module ändern",NULL
:t48			b "AppLinks speichern",NULL
:t49			b "Datum/Uhrzeit ändern",NULL
endif

if LANG = LANG_EN
:t41			b "Settings -> GEOS",NULL
:t42			b "Options -> GeoDesk",NULL
:t43			b "Save options",NULL
:t44			b "Select printer driver",NULL
:t45			b "Select input driver",NULL
:t46			b "Select wallpaper",NULL
:t47			b PLAINTEXT
			b "Edit GeoDesk icons"
			b PLAINTEXT,NULL
:t47a			b "Edit GeoDesk modules",NULL
:t48			b "Save AppLinks",NULL
:t49			b "Set date and time",NULL
endif

;*** GEOS/Beenden
:MAX_ENTRY_EXIT		= 3
:m05y0			= (((MIN_AREA_BAR_Y-1) - MAX_ENTRY_EXIT*14 -2) & $f8) -8 -0
:m05y1			=  (MIN_AREA_BAR_Y-1)                                 -8 -0
:m05x0			= m01x1  + 1 - (m01w/2)
:m05x1			= m05x0 + $0057

:menuGEOS_Exit		b m05y0
			b m05y1
			w m05x0
			w m05x1

			b MAX_ENTRY_EXIT!VERTICAL

			w :t1				;Zurück zu GEOS.
			b MENU_ACTION
			w :m1

			w :t2				;Basic starten.
			b MENU_ACTION
			w :m2

			w :t3				;Programm starten.
			b MENU_ACTION
			w :m3

if LANG = LANG_DE
::t1			b "Zurück zu GEOS",NULL
::t2			b "BASIC starten",NULL
::t3			b "BASIC-Programm",NULL
endif

if LANG = LANG_EN
::t1			b "Exit to GEOS",NULL
::t2			b "Exit to BASIC",NULL
::t3			b "BASIC application",NULL
endif

::m1			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_EXITG		;Nach GEOS beenden

::m2			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_EXIT64		;Nach BASIC beenden.

::m3			jsr	EXIT_MENU_GEOS		;GEOS-Menü beenden.
			jmp	MOD_OPEN_EXITB		;BASIC-Programm starten.

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
