; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Menü CBM/Befehle.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
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
			n "obj.GD39"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenComMenu

;*** PopUp/Befehls-Menü.
:OpenComMenu		lda	#1!VERTICAL		;Laufwerksliste initialisieren.
			sta	menuCDIRnum

			lda	#< t40
			sta	menuCDIR_1 +0
			lda	#> t40
			sta	menuCDIR_1 +1

			lda	#< m40
			sta	menuCDIR_1 +3
			lda	#> m40
			sta	menuCDIR_1 +4

			ldx	#GMOD_CBMDISK
			ldy	GD_DACC_ADDR_B,x	;CBMDISK-Modul installiert?
			beq	:no_cbmutil		; => Nein, weiter...
::cbmutil		lda	#PLAINTEXT
			b $2c
::no_cbmutil		lda	#ITALICON
			sta	t31
			sta	t32

			cmp	#ITALICON		;Modul installiert?
			beq	:init_cbmutil		; => Nein, weiter...

			jsr	InitDrvMenu		;Laufwerksliste aktualisieren.

::init_cbmutil		lda	#< menuSub_CBM		; -> CBM-Disk.
			ldx	#> menuSub_CBM
			ldy	#widthSub_CBM
			jsr	menuSetSize
			jmp	OPEN_MENU

;*** Menü definieren.
:menuSetSize		sta	r0L			;Zeiger auf Menü-Tabelle.
			stx	r0H
			sty	r5H			;Menü-Breite.
			jmp	MENU_SET_SIZE		;Menügröße definieren.

;*** Laufwerksmenü initialisieren.
:InitDrvMenu		php				;Intrerrupt sperren.
			sei

			lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Anzahl Laufwerke.
			sta	r0L
			lda	#$08			;Startadresse Laufwerke ser.Bus.
			sta	r0H

			lda	#< menuCDIR_1		;Zeiger auf Menütabelle.
			sta	r1L
			lda	#> menuCDIR_1
			sta	r1H

::loop			lda	#$00
			sta	STATUS
;			ldx	#< fname
;			ldy	#> fname
			jsr	SETNAM			;Kein Dateiname.

			lda	#5
			tay
			ldx	r0H
			jsr	SETLFS			;Daten für Laufwerk.

			jsr	OPENCHN			;Laufwerk öffnen.

			lda	#5			;Laufwerk schließen.
			jsr	CLOSE

			lda	STATUS			;Laufwerk vorhanden?
			bne	:next			; => Nein, weiter...

			ldx	r0L			;Eintrag in Laufwerksliste
			lda	r0H			;erstellen.
			sta	menuCDIRdrv,x
			txa
			asl
			asl
			tax
			ldy	#$00
			lda	menuCDIRtab,x
			sta	(r1L),y
			sta	r2L
			inx
			iny
			lda	menuCDIRtab,x
			sta	(r1L),y
			sta	r2H
			inx
			iny
			iny
			lda	menuCDIRtab,x
			sta	(r1L),y
			inx
			iny
			lda	menuCDIRtab,x
			sta	(r1L),y

			lda	r0H			;Geräteadresse in
			jsr	DEZ2ASCII		;Menüeintrag kopieren.
			cpx	#"0"
			bne	:1
			tax
			lda	#NULL

::1			ldy	#menuCDIRpos
			sta	(r2L),y
			txa
			dey
			sta	(r2L),y

			inc	r0L
			lda	r0L
			cmp	#8 +1			;Max. 8 Laufwerke gefunden?
			bcs	:end			; => Ja, Ende...
			ora	#VERTICAL
			sta	menuCDIRnum		;Anzahl Menüeinträge korrigieren.

			lda	r1L			;Zeiger auf nächsten Menüeintrag.
			clc
			adc	#5
			sta	r1L
			bcc	:next
			inc	r1H

::next			inc	r0H
			lda	r0H
			cmp	#29 +1			;Alle Laufwerke getestet?
			bcs	:end			; => Ja, Ende...
			jmp	:loop			; => Weiter mit nächstem Laufwerk...

::end			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			plp				;Interrupt zurücksetzen.
			rts

;*** PopUp/Dateifenster -> CBM/Disk.
if LANG = LANG_DE
:widthSub_CBM = $4f
endif
if LANG = LANG_EN
:widthSub_CBM = $47
endif

:menuSub_CBM		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

:menuCBM_1		w t31				;>> Verzeichnis.
			b DYN_SUB_MENU
			w m31

			w t32				;Auswahl: Keine auswählen.
			b MENU_ACTION
			w m32

:m31			lda	#< menuSub_CDIR		; -> Laufwerke anzeigen.
			ldx	#> menuSub_CDIR
			ldy	#widthSub_CDIR
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

:m32			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
;			jmp	MOD_CBM_COM		;Befehl senden.

::MOD_CBM_COM		lda	#$03			;Befehl senden.
			ldx	#GMOD_CBMDISK
			jmp	EXEC_MODULE

if LANG = LANG_DE
:t31			b PLAINTEXT
			b ">> Verzeichnis",NULL
:t32			b PLAINTEXT
			b "Befehl senden",NULL
endif

if LANG = LANG_EN
:t31			b PLAINTEXT
			b ">> Directory",NULL
:t32			b PLAINTEXT
			b "Send command",NULL
endif

;*** PopUp/Dateifenster -> Laufwerke.
if LANG = LANG_DE
:widthSub_CDIR = $47
endif
if LANG = LANG_EN
:widthSub_CDIR = $3f
endif

:menuSub_CDIR		b $00,$00
			w $0000,$0000

:menuCDIRnum		b 8!VERTICAL

:menuCDIR_1		w t41				;Laufwerk#1.
			b MENU_ACTION
			w m41

			w t42				;Laufwerk#2.
			b MENU_ACTION
			w m42

			w t43				;Laufwerk#3.
			b MENU_ACTION
			w m43

			w t44				;Laufwerk#4.
			b MENU_ACTION
			w m44

			w t45				;Laufwerk#5.
			b MENU_ACTION
			w m45

			w t46				;Laufwerk#6.
			b MENU_ACTION
			w m46

			w t47				;Laufwerk#7.
			b MENU_ACTION
			w m47

			w t48				;Laufwerk#8.
			b MENU_ACTION
			w m48

:m40			jmp	EXIT_POPUP_MENU		;PopUp-Menü beenden.

:m41			ldx	#0
			b $2c
:m42			ldx	#1
			b $2c
:m43			ldx	#2
			b $2c
:m44			ldx	#3
			b $2c
:m45			ldx	#4
			b $2c
:m46			ldx	#5
			b $2c
:m47			ldx	#6
			b $2c
:m48			ldx	#7
			lda	menuCDIRdrv,x
			sta	getFileDrv		;Laufwerk setzen.

			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
;			jmp	MOD_CBM_DIR		;Verzeichnis anzeigen.

::MOD_CBM_DIR		lda	#$00			;Verzeichnis anzeigen.
			ldx	#GMOD_CBMDISK
			jmp	EXEC_MODULE

if LANG = LANG_DE
:t40			b PLAINTEXT,ITALICON
			b "Unbekannt..."
			b PLAINTEXT,NULL
:t41			b "Laufwerk #00",NULL
:t42			b "Laufwerk #00",NULL
:t43			b "Laufwerk #00",NULL
:t44			b "Laufwerk #00",NULL
:t45			b "Laufwerk #00",NULL
:t46			b "Laufwerk #00",NULL
:t47			b "Laufwerk #00",NULL
:t48			b "Laufwerk #00",NULL
:menuCDIRpos		= 10 +1
endif

if LANG = LANG_EN
:t40			b PLAINTEXT,ITALICON
			b "Unknown..."
			b PLAINTEXT,NULL
:t41			b "Drive #00",NULL
:t42			b "Drive #00",NULL
:t43			b "Drive #00",NULL
:t44			b "Drive #00",NULL
:t45			b "Drive #00",NULL
:t46			b "Drive #00",NULL
:t47			b "Drive #00",NULL
:t48			b "Drive #00",NULL
:menuCDIRpos		= 7 +1
endif

:menuCDIRtab		w t41,m41
			w t42,m42
			w t43,m43
			w t44,m44
			w t45,m45
			w t46,m46
			w t47,m47
			w t48,m48

:menuCDIRdrv		s $08

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
