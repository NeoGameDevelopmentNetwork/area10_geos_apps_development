; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* DiskImage-Menü.

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
			n "obj.GD38"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenMenu_DImage

;*** PopUp/DiskImage.
:OpenMenu_DImage	ldx	#GMOD_SD2IEC
			ldy	GD_DACC_ADDR_B,x	;DiskImage-Menü installiert?
			bne	:1			; => Ja, weiter...

			lda	#ITALICON		;DiskImage-Menü
			sta	txImgRename		;deaktivieren.
			sta	txImgDelete
			sta	txImgDuplicate
			sta	txImgNewDir

::1			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			beq	:exit			; => Kein Laufwerk, Ende...

;--- DiskImage-Modus.
			lda	WIN_DATAMODE,x		;CMD-/DiskImage-Browser aktiv?
			bmi	:exit			; => CMD, Modus wechseln.
			bne	execSD2IEC		; => SD2IEC, DiskImage-Menü.

;--- Rechter Mausklick nicht möglich.
::exit			rts

;*** SD2IEC/Browser.
:execSD2IEC		lda	fileEntryVec +0
			sta	r0L
			lda	fileEntryVec +1
			sta	r0H

			ldy	#2
			lda	(r0),y
			cmp	#DIR
			bne	:file

			lda	#< menuSD2DIR		; -> Verzeichnis.
			ldx	#> menuSD2DIR
			ldy	#widthSD2DIR
			bne	:setmenu

::file			lda	#< menuSD2IEC		; -> Datei.
			ldx	#> menuSD2IEC
			ldy	#widthSD2IEC

::setmenu		sta	r0L
			stx	r0H
			sty	r5H
			jsr	menuSetSize

			lda	#< :unselect
			sta	exitMenuVec +0
			lda	#> :unselect
			sta	exitMenuVec +1

			jmp	OPEN_MENU

;--- Dateiauswahl aufheben.
::unselect		lda	fileEntryPos		;Zeiger auf Datei-Eintag im
			sta	r0L			;Speicher berechnen.

			ldx	#r0L
			jsr	WM_SETVEC_ENTRY

			lda	fileEntryPos		;Datei abwählen, erfordert in
			sta	r14L			;r0 einen Zeiger auf Datei-Eintrag.
			jmp	WM_FMODE_UNSLCT

;*** Untermenü "Neu"...
:execCreate		lda	#< menuCreate
			ldx	#> menuCreate
			ldy	#widthCreate
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

;*** Menü definieren.
:menuSetSize		sta	r0L			;Zeiger auf Menü-Tabelle.
			stx	r0H
			sty	r5H			;Menü-Breite.
			jmp	MENU_SET_SIZE		;Menügröße definieren.

;*** Disk-/SD2IEC-Manager nachladen.
:MOD_DIMGREN		lda	#0 *3			;DiskImage umbenennen.
			b $2c
:MOD_DIMGDEL		lda	#1 *3			;DiskImage löschen.
			b $2c
:MOD_DIMGCOPY		lda	#2 *3			;DiskImage duplizieren.
			b $2c
:MOD_NEWDIR		lda	#3 *3			;Verzeichnis erstellen.
			b $2c
:MOD_DELDIR		lda	#4 *3			;Verzeichnis löschen.

			ldx	#GMOD_SD2IEC
			ldy	GD_DACC_ADDR_B,x	;DiskImage-Menü installiert?
			beq	:exit			; => Ja, weiter...

			ldx	#GMOD_SD2IEC
			jmp	EXEC_MODULE
::exit			rts

;*** Menü-Routinen.

;-- Partition/DiskImage öffnen.
:jobOpen		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.

			ldx	fileEntryPos		;Datei-Nr. einlesen.
			jmp	MseClkOnFile

;--- DiskImage umbenennen.
:jobImgRename		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_DIMGREN

;--- DiskImage löschen.
:jobImgDelete		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_DIMGDEL

;--- DiskImage duplizieren.
:jobImgDuplicate	jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_DIMGCOPY

;--- DiskImage erstellen.
:jobImgNewDImg		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_CREATE_IMG		;DiskImage erstellen.

;--- Verzeichnis erstellen.
:jobImgNewDir		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_NEWDIR		;DiskImage erstellen.

;--- Verzeichnis löschen.
:jobImgDelDir		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_DELDIR		;DiskImage erstellen.

;*** PopUp/SD2IEC -> Datei.
if LANG = LANG_DE
:widthSD2IEC = $3f
endif
if LANG = LANG_EN
:widthSD2IEC = $37
endif

:menuSD2IEC		b $00,$00
			w $0000,$0000

			b 5!VERTICAL

::_07			w txImgOpen			;DiskImage öffnen.
			b MENU_ACTION
			w jobOpen

::_12			w txImgCreate			;DiskImage erstellen.
			b DYN_SUB_MENU
			w execCreate

::_17			w txImgRename			;DiskImage umbenennen.
			b MENU_ACTION
			w jobImgRename

::_22			w txImgDuplicate		;DiskImage umbenennen.
			b MENU_ACTION
			w jobImgDuplicate

::_27			w txImgDelete			;DiskImage löschen.
			b MENU_ACTION
			w jobImgDelete

;*** PopUp/SD2IEC -> Verzeichnis.
if LANG = LANG_DE
:widthSD2DIR = $3f
endif
if LANG = LANG_EN
:widthSD2DIR = $37
endif

:menuSD2DIR		b $00,$00
			w $0000,$0000

			b 4!VERTICAL

::_07			w txImgOpen			;DiskImage öffnen.
			b MENU_ACTION
			w jobOpen

::_12			w txImgCreate			;DiskImage erstellen.
			b DYN_SUB_MENU
			w execCreate

::_17			w txImgRename			;DiskImage umbenennen.
			b MENU_ACTION
			w jobImgRename

::_22			w txImgDelete			;DiskImage löschen.
			b MENU_ACTION
			w jobImgDelDir

;*** PopUp/SD2IEC -> Datei -> Neu.
if LANG = LANG_DE
:widthCreate = $3f
endif
if LANG = LANG_EN
:widthCreate = $37
endif

:menuCreate		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

::_07			w txImgNewDImg			;DiskImage erstellen.
			b MENU_ACTION
			w jobImgNewDImg

::_12			w txImgNewDir			;DiskImage umbenennen.
			b MENU_ACTION
			w jobImgNewDir

;** Menü-Texte.
if LANG = LANG_DE
:txImgOpen		b PLAINTEXT
			b "Öffnen",NULL
:txImgRename		b PLAINTEXT
			b "Umbenennen",NULL
:txImgDelete		b PLAINTEXT
			b "Löschen",NULL
:txImgDuplicate		b PLAINTEXT
			b "Duplizieren",NULL
:txImgCreate		b PLAINTEXT
			b ">> Neu",NULL
:txImgNewDImg		b PLAINTEXT
			b "DiskImage",NULL
:txImgNewDir		b PLAINTEXT
			b "Verzeichnis",NULL
endif

if LANG = LANG_EN
:txImgOpen		b PLAINTEXT
			b "Open",NULL
:txImgRename		b PLAINTEXT
			b "Rename",NULL
:txImgDelete		b PLAINTEXT
			b "Delete",NULL
:txImgDuplicate		b PLAINTEXT
			b "Duplicate",NULL
:txImgCreate		b PLAINTEXT
			b ">> Create",NULL
:txImgNewDImg		b PLAINTEXT
			b "Disk image",NULL
:txImgNewDir		b PLAINTEXT
			b "Directory",NULL
endif

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
