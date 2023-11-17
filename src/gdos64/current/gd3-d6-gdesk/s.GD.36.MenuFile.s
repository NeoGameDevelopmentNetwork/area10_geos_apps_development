; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Dateifenster/Datei-Menü.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
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
			n "obj.GD36"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenFileMenu

;*** PopUp/Datei.
:OpenFileMenu		lda	#5!VERTICAL		;Anzahl Menüeinträge zurücksetzen.
			sta	menuFile +6

			jsr	GetNumSlctFiles		;Anzahl markierte Dateien ermitteln.
			cmp	#$01			;Mehr als eine Datei?
			bne	:init			; => Ja, kein Borderblock-Menü.

			jsr	GetBorderBlock		;Adresse Borderblock ermitteln.
			txa				;Diskettenfehler?
			bne	:init			; => Ja, kein Borderblock-Menü.
			tya				;Keine GEOS-Diskette?
			bne	:init			; => Ja, kein Borderblock-Menü.

			lda	#< diskBlkBuf
			sta	r4L
			lda	#> diskBlkBuf
			sta	r4H
			jsr	GetBlock		;Borderblock einlesen.
			txa				;Diskettenfehler?
			bne	:init			; => Ja, kein Borderblock-Menü.

			lda	fileEntryVec +0		;Ausgewählte Datei nach ":r0".
			sta	r0L
			lda	fileEntryVec +1
			sta	r0H

::search		ldy	#$02			;Dateieintrag im Borderblock
::byte			lda	(r0L),y			;suchen... 30Bytes vergleichen.
			cmp	(r4L),y
			bne	:next
			iny
			cpy	#$20
			bcc	:byte
			bcs	:border			;Borderblock-Datei gefunden.

::next			lda	r4L			;Alle Dateien durchsucht?
			clc
			adc	#$20
			sta	r4L
			bcc	:search			; => Nein, weitersuchen...

			lda	#" "			; => Datei ist im Verzeichnis.
			b $2c
::border		lda	#"*"			; => Datei ist im Borderblock.
			sta	t06 +1

			lda	#6!VERTICAL
			sta	menuFile +6		;Borderblock-Menü aktivieren.

;--- SendTo.
::init			ldx	#GMOD_SENDTO
			ldy	GD_DACC_ADDR_B,x	;FileCVT-Modul installiert?
			bne	:sendto2

::sendto1		lda	#MENU_ACTION
			ldx	#< SKIP_SENDTO
			ldy	#> SKIP_SENDTO
			bne	:set_sendto

::sendto2		lda	#DYN_SUB_MENU
			ldx	#< ROUT_SENDTO
			ldy	#> ROUT_SENDTO

::set_sendto		sta	r05
			stx	r05 +1
			sty	r05 +2

			cmp	#DYN_SUB_MENU
			bne	:no_sendto

::sendto		lda	#PLAINTEXT
			b $2c
::no_sendto		lda	#ITALICON
			sta	t05

;--- File/Deleted.
			lda	fileEntryVec +0		;Ausgewählte Datei nach ":r0".
			sta	r0L
			lda	fileEntryVec +1
			sta	r0H

			ldy	#$02
			lda	(r0L),y			;Dateityp einlesen.
			and	#%00000111		;Datei gelöscht?
			beq	:1			; => Ja, weiter...

;--- Convert/CVT.
			ldx	#GMOD_FILECVT
			ldy	GD_DACC_ADDR_B,x	;FileCVT-Modul installiert?
			beq	:no_filecvt		; => Nein, weiter...
::filecvt		lda	#PLAINTEXT
			b $2c
::no_filecvt		lda	#ITALICON
			sta	t04

			lda	#< menuFile		;Dateimenü.
			ldx	#> menuFile
			ldy	#widthFileMenu
			jsr	menuSetSize
			jmp	OPEN_MENU

;--- Gelöschte Dateien.
::1			lda	#< menuDeleted		;Menü für gelöschte Dateien.
			ldx	#> menuDeleted
			ldy	#widthDeleted
			jsr	menuSetSize
			jmp	OPEN_MENU

;*** Menü definieren.
:menuSetSize		sta	r0L			;Zeiger auf Menü-Tabelle.
			stx	r0H
			sty	r5H			;Menü-Breite.
			jmp	MENU_SET_SIZE		;Menügröße definieren.

;*** PopUp/Datei.
if LANG = LANG_DE
:widthFileMenu = $57
endif
if LANG = LANG_EN
:widthFileMenu = $47
endif

:menuFile		b $00,$00
			w $0000,$0000

			b 5!VERTICAL			;Anzahl wird berechnet!

			w t01				;Datei-Eigenschaften.
			b MENU_ACTION
			w m01

			w t02				;Datei öffnen.
			b MENU_ACTION
			w m02

			w t03				;Datei löschen.
			b MENU_ACTION
			w m03

			w t04				;Datei konvertieren.
			b MENU_ACTION
			w m04

			w t05				;>> Senden an...
:r05			b DYN_SUB_MENU
			w ROUT_SENDTO

			w t06				;Datei konvertieren.
			b MENU_ACTION
			w m06

:m01			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILE_INFO		;Datei-Eigenschaften.

:m02			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_OPEN_FILE		;Datei öffnen.

:m03			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_DEL_FILE		;Datei löschen.

:m04			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_CONVERT_FILE		;Datei konvertieren.

:ROUT_SENDTO		lda	#< menuSub_Send		; -> Senden an...
			ldx	#> menuSub_Send
			ldy	#widthSub_Send
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

:m06			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jsr	SUB_SWAPBORDER		;Datei mit Boderblock tauschen.
			jsr	SET_LOAD_DISK		;Verzeichnis neu laden.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

if LANG = LANG_DE
:t01			b "Eigenschaften",NULL
:t02			b "Datei öffnen",NULL
:t03			b "Löschen",NULL
:t04			b PLAINTEXT
			b "Konvertieren/CVT"
			b PLAINTEXT,NULL
:t05			b PLAINTEXT
			b "Senden an... >>"
			b PLAINTEXT,NULL
:t06			b "( ) Borderblock",NULL
endif

if LANG = LANG_EN
:t01			b "Properties",NULL
:t02			b "Open file",NULL
:t03			b "Delete",NULL
:t04			b PLAINTEXT
			b "Convert/CVT"
			b PLAINTEXT,NULL
:t05			b PLAINTEXT
			b "Send to... >>"
			b PLAINTEXT,NULL
:t06			b "( ) Borderblock",NULL
endif

;*** PopUp/Datei -> Senden an...
if LANG = LANG_DE
:widthSub_Send = $47
endif
if LANG = LANG_EN
:widthSub_Send = $3f
endif

:menuSub_Send		b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w t11				;Senden an: Drucker.
			b MENU_ACTION
			w m11

			w t12				;Senden an: Laufwerk#1.
			b MENU_ACTION
			w m12

			w t13				;Senden an: Laufwerk#2.
			b MENU_ACTION
			w m13

			w t14				;Senden an: Menü anzeigen.
			b MENU_ACTION
			w SKIP_SENDTO

:m11			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_SEND_PRNT		;Dateien an Drucker senden.

:m12			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_SEND_DRV1		;Dateien an Laufwerk#1 senden.

:m13			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_SEND_DRV2		;Dateien an Laufwerk#2 senden.

:SKIP_SENDTO		jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_SEND_MENU		;Dateien senden, Menü öffnen.

if LANG = LANG_DE
:t11			b "Drucker",NULL
:t12			b "Laufwerk#1",NULL
:t13			b "Laufwerk#2",NULL
:t14			b "Optionen",NULL
endif

if LANG = LANG_EN
:t11			b "Printer",NULL
:t12			b "Drive#1",NULL
:t13			b "Drive#2",NULL
:t14			b "Options",NULL
endif

;*** PopUp/gelöschte Datei.
if LANG = LANG_DE
:widthDeleted = $5f
endif
if LANG = LANG_EN
:widthDeleted = $4f
endif

:menuDeleted		b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w :t1				;Datei-Eigenschaften.
			b MENU_ACTION
			w :m1

			w :t2				;Datei retten.
			b MENU_ACTION
			w :m2

			w :t3				;Datei bereinigen.
			b MENU_ACTION
			w :m3

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILE_INFO		;Datei-Eigenschaften.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_UNDELFILE		;Datei retten.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_CLEANUP		;Datei bereinigen.

if LANG = LANG_DE
::t1			b "Eigenschaften",NULL
::t2			b "Wiederherstellen",NULL
::t3			b "Bereinigen",NULL
endif

if LANG = LANG_EN
::t1			b "Properties",NULL
::t2			b "Recover file",NULL
::t3			b "Purge files",NULL
endif

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
