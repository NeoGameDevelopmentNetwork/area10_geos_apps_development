; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Arbeitsplatz-Menü.

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
endif

;*** GEOS-Header.
			n "obj.GD32"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenMyComp

;*** PopUp/Arbeitsplatz
:OpenMyComp		ldx	MyCompEntry
			cpx	#$04			;Rechtsklick auf Drucker?
			beq	:print			; => Ja, weiter...
			cpx	#$05			;Rechtsklick auf Eingabegerät?
			beq	:input			; => Ja, weiter...
			bcc	:test			; => Rechtsklick gültig.

::exit			rts

::test			lda	driveType,x		;Existiert Laufwerk?
			beq	:exit			; => Rechtsklick ungültig.
			lda	RealDrvMode,x		;Laufwerksmodus einlesen.
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			bne	:part			; => Nein, weiter...

::drive			lda	#< menuComp_Drive
			ldx	#> menuComp_Drive
			ldy	#widthComp_Drive
			bne	menuSetSizeOpen

::part			lda	#< menuComp_SDCMD
			ldx	#> menuComp_SDCMD
			ldy	#widthComp_SDCMD
			bne	menuSetSizeOpen

::print			lda	#< menuComp_Prnt
			ldx	#> menuComp_Prnt
			ldy	#widthComp_Prnt
			bne	menuSetSizeOpen

::input			lda	#< menuComp_Inpt
			ldx	#> menuComp_Inpt
			ldy	#widthComp_Inpt
;			bne	menuSetSizeOpen

;*** Menü definieren und anzeigen.
:menuSetSizeOpen	sta	r0L			;Zeiger auf Menü-Tabelle.
			stx	r0H
			sty	r5H			;Menü-Breite.
			jsr	MENU_SET_SIZE		;Menügröße definieren.
			jmp	OPEN_MENU		;Menü anzeigen.

;*** MyComputer/Laufwerk CMD/SD2IEC
if LANG = LANG_DE
:widthComp_SDCMD = $47
endif
if LANG = LANG_EN
:widthComp_SDCMD = $3f
endif

:menuComp_SDCMD		b $00,$00
			w $0000,$0000

			b 7!VERTICAL

			w :t1				;Neue Ansicht.
			b MENU_ACTION
			w :m1

			w :t2				;Disk öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;Partition/DiskImage wechseln.
			b MENU_ACTION
			w :m3

			w :t4				;Validate.
			b MENU_ACTION
			w :m4

			w :t5				;Disk-Info.
			b MENU_ACTION
			w :m5

			w :t6				;Diskette löschen.
			b MENU_ACTION
			w :m6

			w :t7				;Diskette formatieren.
			b MENU_ACTION
			w :m7

if LANG = LANG_DE
::t1			b "Neue Ansicht",NULL
::t2			b "Disk öffnen",NULL
::t3			b "Disk wechseln",NULL
::t4			b "Überprüfen",NULL
::t5			b "Eigenschaften",NULL
::t6			b "Löschen",NULL
::t7			b "Formatieren",NULL
endif

if LANG = LANG_EN
::t1			b "New view",NULL
::t2			b "Open disk",NULL
::t3			b "Switch disk",NULL
::t4			b "Validate",NULL
::t5			b "Properties",NULL
::t6			b "Clear drive",NULL
::t7			b "Format disk",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_NEWVIEW		;Neue Ansicht.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_OPENDRV		;Laufwerk öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_PART		;Partition/DiskImage wechseln.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_VALIDATE		;Validate.

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_DISKINFO		;Disk-Info.

::m6			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_CLRDRV		;Diskette löschen.

::m7			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_FRMTDRV		;Diskette formatieren.

;*** MyComputer/Laufwerk
if LANG = LANG_DE
:widthComp_Drive = $57
endif
if LANG = LANG_EN
:widthComp_Drive = $4f
endif

:menuComp_Drive		b $00,$00
			w $0000,$0000

			b 6!VERTICAL

			w :t1				;Neue Ansicht.
			b MENU_ACTION
			w :m1

			w :t2				;Laufwerk öffnen.
			b MENU_ACTION
			w :m2

			w :t3				;Validate.
			b MENU_ACTION
			w :m3

			w :t4				;DiskInfo.
			b MENU_ACTION
			w :m4

			w :t5				;Diskette löschen.
			b MENU_ACTION
			w :m5

			w :t6				;Diskette formatieren.
			b MENU_ACTION
			w :m6

if LANG = LANG_DE
::t1			b "Neue Ansicht",NULL
::t2			b "Laufwerk öffnen",NULL
::t3			b "Überprüfen",NULL
::t4			b "Eigenschaften",NULL
::t5			b "Löschen",NULL
::t6			b "Formatieren",NULL
endif

if LANG = LANG_EN
::t1			b "New view",NULL
::t2			b "Open drive",NULL
::t3			b "Validate",NULL
::t4			b "Properties",NULL
::t5			b "Clear drive",NULL
::t6			b "Format disk",NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_NEWVIEW		;Neue Ansicht.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_OPENDRV		;Laufwerk öffnen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_VALIDATE		;Validate.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_DISKINFO		;DiskInfo.

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_CLRDRV		;Diskette löschen.

::m6			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MYCOMP_FRMTDRV		;Diskette formatieren.

;*** MyComputer/Drucker
if LANG = LANG_DE
:widthComp_Prnt = $67
endif
if LANG = LANG_EN
:widthComp_Prnt = $4f
endif

:menuComp_Prnt		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

			w :t1				;Drucker auswählen.
			b MENU_ACTION
			w :m1

			w PrntFileName			;Druckername anzeigen/auswählen.
			b MENU_ACTION
			w :m1

if LANG = LANG_DE
::t1			b BOLDON
			b "Drucker"
			b PLAINTEXT,NULL
endif

if LANG = LANG_EN
::t1			b BOLDON
			b "Printer"
			b PLAINTEXT,NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	AL_SWAP_PRINTER

;*** MyComputer/Eingabe
if LANG = LANG_DE
:widthComp_Inpt = $67
endif
if LANG = LANG_EN
:widthComp_Inpt = $4f
endif

:menuComp_Inpt		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

			w :t1
			b MENU_ACTION
			w :m1

			w inputDevName
			b MENU_ACTION
			w :m1

if LANG = LANG_DE
::t1			b BOLDON
			b "Eingabegerät"
			b PLAINTEXT,NULL
endif

if LANG = LANG_EN
::t1			b BOLDON
			b "Input device"
			b PLAINTEXT,NULL
endif

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	EXT_INPUTDBOX		;Eingabetreiber wählen.

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
