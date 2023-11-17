; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* AppLink-Menü.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_CHAR"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "s.GD.21.Desk.ext"

;--- AppLink-Definition.
			t "e.GD.10.AppLink"
endif

;*** GEOS-Header.
			n "obj.GD34"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenMenu_ALink

;*** PopUp/AppLink.
:OpenMenu_ALink		ldy	#LINK_DATA_TYPE
			lda	(r14L),y
			cmp	#AL_TYPE_FILE
			beq	:4
			cmp	#AL_TYPE_MYCOMP
			beq	:5
			cmp	#AL_TYPE_SUBDIR
			beq	:7
			cmp	#AL_TYPE_PRNT
			beq	:6
			cmp	#AL_TYPE_DRIVE
			beq	:1
			rts

;--- Rechter Mausklick auf AppLink/Laufwerk.
::1			ldy	#LINK_DATA_DRIVE	;Laufwerksadresse einlesen.
			lda	(r14L),y
			tax
			lda	RealDrvMode -8,x	;Laufwerk CMD/SD2IEC?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:2			; => Nein, keine Partitionsauswahl.

;--- Rechter Mausklick auf AppLink/Laufwerk/CMD/SD.
			lda	#< menuAL_SDCMD
			ldx	#> menuAL_SDCMD
			ldy	#widthAL_SDCMD
			bne	menuSetSizeOpen

;--- Rechter Mausklick auf AppLink/Laufwerk/Std.
::2			lda	#< menuAL_Drive
			ldx	#> menuAL_Drive
			ldy	#widthAL_Drive
			bne	menuSetSizeOpen

;--- Rechter Mausklick auf AppLink/Datei.
::4			lda	#< menuAL_File
			ldx	#> menuAL_File
			ldy	#widthAL_File
			bne	menuSetSizeOpen

;--- Rechter Mausklick auf AppLink/Arbeitsplatz.
::5			lda	#< menuMyComp
			ldx	#> menuMyComp
			ldy	#widthMyComp
			bne	menuSetSizeOpen

;--- Rechter Mausklick auf AppLink/Drucker.
::6			lda	#< menuAL_Prnt
			ldx	#> menuAL_Prnt
			ldy	#widthAL_Prnt
			bne	menuSetSizeOpen

;--- Rechter Mausklick auf AppLink/Verzeichnis.
::7			lda	#< menuAL_SDir
			ldx	#> menuAL_SDir
			ldy	#widthAL_SDir
;			bne	menuSetSizeOpen

;*** Menü definieren und anzeigen.
:menuSetSizeOpen	sta	r0L			;Zeiger auf Menü-Tabelle.
			stx	r0H
			sty	r5H			;Menü-Breite.
			jsr	MENU_SET_SIZE		;Menügröße definieren.
			jmp	OPEN_MENU		;Menü anzeigen.

;*** PopUp/AppLink -> Arbeitsplatz
if LANG = LANG_DE
:widthMyComp = $57
endif
if LANG = LANG_EN
:widthMyComp = $4f
endif

:menuMyComp		b $00,$00
			w $0000,$0000

			b 5!VERTICAL

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

if LANG = LANG_DE
::t1			b BOLDON
			b "Arbeitsplatz"
			b PLAINTEXT,NULL
::t2			b " >> Laufwerk A:",NULL
::t3			b " >> Laufwerk B:",NULL
::t4			b " >> Laufwerk C:",NULL
::t5			b " >> Laufwerk D:",NULL
endif

if LANG = LANG_EN
::t1			b BOLDON
			b "My Computer"
			b PLAINTEXT,NULL
::t2			b " >> Drive A:",NULL
::t3			b " >> Drive B:",NULL
::t4			b " >> Drive C:",NULL
::t5			b " >> Drive D:",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_OPEN_ENTRY		;Arbeitsplatz öffnen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_A		;Laufwerk A: öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_B		;Laufwerk B: öffnen.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_C		;Laufwerk C: öffnen.

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_DRV_D		;Laufwerk D: öffnen.

;*** PopUp/AppLink -> Datei
if LANG = LANG_DE
:widthAL_File = $57
endif
if LANG = LANG_EN
:widthAL_File = $4f
endif

:menuAL_File		b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w :t1				;AppLink umbenennen.
			b MENU_ACTION
			w :m1

			w :t2				;AppLink öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;AppLink löschen.
			b MENU_ACTION
			w :m3

if LANG = LANG_DE
::t1			b "AppLink umbenennen",NULL
::t2			b "Datei öffnen",NULL
::t3			b "AppLink löschen",NULL
endif

if LANG = LANG_EN
::t1			b "Rename AppLink",NULL
::t2			b "Open file",NULL
::t3			b "Delete AppLink",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_RENAME_ENTRY		;AppLink umbenennen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_OPEN_ENTRY		;AppLink öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_DEL_ENTRY		;AppLink löschen.

;*** PopUp/AppLink -> Laufwerk -> Std.
if LANG = LANG_DE
:widthAL_Drive = $67
endif
if LANG = LANG_EN
:widthAL_Drive = $4f
endif

:menuAL_Drive		b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w :t1				;AppLink umbenennen.
			b MENU_ACTION
			w :m1

			w :t2				;Laufwerk öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;AppLink löschen.
			b MENU_ACTION
			w :m3

if LANG = LANG_DE
::t1			b "AppLink umbenennen",NULL
::t2			b "Laufwerk öffnen",NULL
::t3			b "AppLink löschen",NULL
endif

if LANG = LANG_EN
::t1			b "Rename AppLink",NULL
::t2			b "Open drive",NULL
::t3			b "Delete AppLink",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_RENAME_ENTRY		;AppLink umbenennen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_OPEN_ENTRY		;Laufwerk öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_DEL_ENTRY		;AppLink löschen.

;*** PopUp/AppLink -> Laufwerk -> CMD/SD
if LANG = LANG_DE
:widthAL_SDCMD = $67
endif
if LANG = LANG_EN
:widthAL_SDCMD = $67
endif

:menuAL_SDCMD		b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w :t1				;AppLink umbenennen.
			b MENU_ACTION
			w :m1

			w :t2				;Laufwerk öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;Partition/DiskImage wechseln.
			b MENU_ACTION
			w :m3

			w :t4				;AppLink löschen.
			b MENU_ACTION
			w :m4

if LANG = LANG_DE
::t1			b "AppLink umbenennen",NULL
::t2			b "Laufwerk öffnen",NULL
::t3			b "Partition wechseln",NULL
::t4			b "AppLink löschen",NULL
endif

if LANG = LANG_EN
::t1			b "Rename AppLink",NULL
::t2			b "Open drive",NULL
::t3			b "Switch partition",NULL
::t4			b "Delete AppLink",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_RENAME_ENTRY		;AppLink umbenennen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_OPEN_ENTRY		;Laufwerk öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_OPEN_DSKIMG		;Partition/DiskImage wechseln.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_DEL_ENTRY		;AppLink löschen.

;*** PopUp/AppLink -> Verzeichnis
if LANG = LANG_DE
:widthAL_SDir = $67
endif
if LANG = LANG_EN
:widthAL_SDir = $4f
endif

:menuAL_SDir		b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w :t1				;AppLink umbenennen.
			b MENU_ACTION
			w :m1

			w :t2				;Verzeichnis öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;AppLink löschen.
			b MENU_ACTION
			w :m3

if LANG = LANG_DE
::t1			b "AppLink umbenennen",NULL
::t2			b "Verzeichnis öffnen",NULL
::t3			b "AppLink löschen",NULL
endif

if LANG = LANG_EN
::t1			b "Rename AppLink",NULL
::t2			b "Open directory",NULL
::t3			b "Delete AppLink",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_RENAME_ENTRY		;AppLink umbenennen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_SDIR		;Verzeichnis öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_DEL_ENTRY		;AppLink löschen.

;*** PopUp/AppLink -> Drucker
if LANG = LANG_DE
:widthAL_Prnt = $6f
endif
if LANG = LANG_EN
:widthAL_Prnt = $57
endif

:menuAL_Prnt		b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w :t1				;Drucker auswählen.
			b MENU_ACTION
			w :m1

			w :t2				;Drucker installieren.
			b MENU_ACTION
			w :m2

			w :t3				;AppLink löschen.
			b MENU_ACTION
			w :m3

			w :t4				;AppLink umbenennen.
			b MENU_ACTION
			w :m4

if LANG = LANG_DE
::t1			b "Neuen Drucker wählen",NULL
::t2			b "Drucker wechseln",NULL
::t3			b "AppLink löschen",NULL
::t4			b "AppLink umbenennen",NULL
endif

if LANG = LANG_EN
::t1			b "Install new printer",NULL
::t2			b "Switch printer",NULL
::t3			b "Delete AppLink",NULL
::t4			b "Rename AppLink",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_SWAP_PRINTER		;Drucker auswählen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_OPEN_PRNT		;Drucker installieren.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_DEL_ENTRY		;AppLink löschen.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_RENAME_ENTRY		;AppLink umbenennen.

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
