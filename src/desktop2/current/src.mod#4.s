; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Source code for DESK TOP V2
;
; Reassembled (w)2020-2023:
;   Markus Kanet
;
; Original authors:
;   Brian Dougherty
;   Doug Fults
;   Jim Defrisco
;   Tony Requist
; (c)1986,1988 Berkeley Softworks
;
; Revision V1.0
; Date: 23/03/25
;
; History:
; V0.1 - Initial reassembled code.
;
; V0.2 - Initial code analysis.
;
; V0.3 - Source code analysis complete.
;
; V0.4 - Added english translation.
;
; V1.0 - Updated to V2.1.
;

if .p
			t "TopSym"
;			t "TopMac"
			t "SymTab.rom"
			t "src.DESKTOP.ext"
			t "lang.DESKTOP.ext"

;--- BASIC-Start:
:BASIC_RAM		= $0800
:BASIC_PRG		= BASIC_RAM +1

;--- Position/Größe Scroll-Pfeile/Textmodus.
:AREA_SCRICON_Y0	= $7c
:AREA_SCRICON_Y1	= $8b
:AREA_SCRICON_X0	= $0080
:AREA_SCRICON_X1	= $0090
endif

			n "obj.mod#4"
			o vlirModBase

;*** Sprungtabelle.
:vlirJumpTab		jmp	doViewBySize		;Anzeige: Größe.
			jmp	doViewByType		;Anzeige: Dateityp.
			jmp	doViewByDate		;Anzeige: Datum.
			jmp	doViewByName		;Anzeige: Name.
			jmp	doScrolUpDn		;Scroll Up/Down.
			jmp	doExitBASIC		;Options/BASIC.
			jmp	doRunBASIC		;Start BASIC-Prg.
			jmp	doDiskRename		;Disk/Rename.
			jmp	doFileRename		;File/Rename.
			jmp	doFileDuplicate		;File/Duplicate.

;*** Tabulatoren für Textausgabe.
;:AREA_FILEPAD_X0	= $0009
if LANG = LANG_DE
:PAD1TAB		= AREA_FILEPAD_X0 +3    ;Dateiname.
:PAD1WIDTH		= PAD1TAB +108
:PAD2TAB		= AREA_FILEPAD_X0 +111  ;Größe.
:PAD3TAB		= AREA_FILEPAD_X0 +151  ;Datum.
:PAD3WIDTH		= $0035
:PAD4TAB		= AREA_FILEPAD_X0 +141  ;Dateityp/DE.
endif
if LANG = LANG_EN
:PAD1TAB		= AREA_FILEPAD_X0 +3    ;Dateiname.
:PAD1WIDTH		= PAD1TAB +108
:PAD2TAB		= AREA_FILEPAD_X0 +111  ;Größe.
:PAD3TAB		= AREA_FILEPAD_X0 +151  ;Datum.
:PAD3WIDTH		= $0030
:PAD4TAB		= AREA_FILEPAD_X0 +149  ;Dateityp/EN.
endif

;*** Nach Name sortieren.
:doViewByName		lda	#3			;Zeiger auf Name.
			sta	r5H

			lda	#16			;Länge für Vergleich:
			sta	r6L			;16 Zeichen.

			lda	#$00
			sta	r6H
			jmp	jobPrintCurPage

;*** Nach Datum sortieren.
:doViewByDate		lda	#23			;Zeiger auf Datum.
			sta	r5H

			lda	#5			;Länge für Vergleich:
			sta	r6L			;Datum(3)+Zeit(2).
			bne	setModeFInfo

;*** Nach Größe sortieren.
:doViewBySize		lda	#28			;Zeiger auf Größe.
			sta	r5H

			lda	#$02			;Länge für Vergleich:
			sta	r6L			;Word, Dateigröße.

:setModeFInfo		lda	#$01
			sta	r6H
			jmp	jobPrintCurPage

;*** Nach Dateityp sorieren.
:doViewByType		lda	#22			;Zeiger auf Dateityp.
			sta	r5H

			lda	#$01			;Länge für Vergleich:
			sta	r6L			;Byte, GEOS-Dateityp.
			bne	setModeFInfo

;*** Aktuelle Seite ausgeben.
:jobPrintCurPage	lda	a7H			;Dateien vorhanden?
			bne	:init			; => Ja, weiter...
::exit			rts

::init			jsr	createTabFiles

			lda	#> tabFIconBitmaps
			sta	r4H
			lda	#< tabFIconBitmaps
			sta	r4L

			lda	a8L			;Dateien auf Seite?
			beq	:exit			; => Nein, Ende...

;			lda	a8L
			sta	r5L

			jsr	sortFileList

			lda	#$00
			sta	topTxEntry +0
			sta	topTxEntry +1

			jsr	clearFilePad

			lda	#8
			sta	r14L

			cmp	a8L
			bcc	:1
			beq	:1

			lda	a8L			;Anzahl Dateien
			sta	r14L			;auf Seite.

::1			ldy	#$00
			sty	r12L			;Zeilenzähler.
			sty	r12H			;Zeiger auf Tabelle.

::loop			jsr	prntCurEntry

			inc	r12L
			dec	r14L
			bne	:loop

;*** Schriftstil zurücksetzen.
:clrCurTxMode		lda	#$00
			sta	currentMode
			rts

;*** Aktuellen Eintrag ausgeben.
:prntCurEntry		lda	topTxEntry +0
			clc
			adc	#< tabFIconBitmaps
			sta	r4L
			lda	topTxEntry +1
			adc	#> tabFIconBitmaps
			sta	r4H

			lda	#SET_BOLD
			sta	currentMode

			ldy	r12H			;Zeiger auf
			lda	(r4L),y			;Verzeichnis-Eintrag
			sta	r15L			;nach r15 und
			clc				;Zeiger auf Dateiname
			adc	#$03			;nach r0 einlesen.
			sta	r0L
			iny
			lda	(r4L),y
			sta	r15H
			adc	#$00
			sta	r0H

			iny				;Tabellenzeiger +1.
			sty	r12H			;(Max. 128 Dateien?)

			ldx	#$00			;Dateiname einlesen.
			jsr	convIconText

			ldx	r1L			;Ende-Kennung für
			inx				;Dateiname.
			lda	#NULL
			sta	buf_TempName,x

			jsr	r0_buf_TempName

			lda	#> PAD1TAB
			sta	r11H
			lda	#< PAD1TAB
			sta	r11L

			ldx	r12L
			lda	tabPosBaseLine,x
			sta	r1H

			lda	r4H
			pha
			lda	r4L
			pha

			lda	r12H
			pha
			lda	r12L
			pha

			lda	#> PAD1WIDTH
			sta	rightMargin +1
			lda	#< PAD1WIDTH
			sta	rightMargin +0

			jsr	PutString		;Dateiname ausgeben.

			lda	#> $013f
			sta	rightMargin +1
			lda	#< $013f
			sta	rightMargin +0

			ldy	a7L
			lda	tabSortModeL -1,y
			ldx	tabSortModeH -1,y
			jsr	CallRoutine

			pla
			sta	r12L
			pla
			sta	r12H

			pla
			sta	r4L
			pla
			sta	r4H

			rts

;*** Y-Koordinate Baseline für Einträge 1-8.
:tabPosBaseLine		b AREA_FILEPAD_Y0 +0*10 +7
			b AREA_FILEPAD_Y0 +1*10 +7
			b AREA_FILEPAD_Y0 +2*10 +7
			b AREA_FILEPAD_Y0 +3*10 +7
			b AREA_FILEPAD_Y0 +4*10 +7
			b AREA_FILEPAD_Y0 +5*10 +7
			b AREA_FILEPAD_Y0 +6*10 +7
			b AREA_FILEPAD_Y0 +7*10 +7

;*** Zeiger auf Sortier-Routinen.
:tabSortModeL		b < prntInfoFileType
			b < prntInfoFileType
			b < prntInfoDateTime
			b < prntInfoFileType

:tabSortModeH		b > prntInfoFileType
			b > prntInfoFileType
			b > prntInfoDateTime
			b > prntInfoFileType

;*** Seite nach oben scrollen.
:func_MoveUp		lda	#AREA_FILEPAD_Y0 +10
			sta	r7L
			lda	#AREA_FILEPAD_Y0
			sta	r7H

			lda	#$01
			jsr	mvFListUpDown

			jsr	i_Rectangle
			b AREA_FILEPAD_Y0 +7*10 +1
			b AREA_FILEPAD_Y0 +8*10 +2
			w AREA_FILEPAD_X0
			w AREA_FILEPAD_X1

			lda	#7
			bne	initNewTxLine

;*** Seite nach unten scrollen.
:func_MoveDown		lda	#AREA_FILEPAD_Y0 +7*10
			sta	r7L
			lda	#AREA_FILEPAD_Y0 +8*10
			sta	r7H

			lda	#$ff
			jsr	mvFListUpDown

			jsr	i_Rectangle
			b AREA_FILEPAD_Y0 +0*10
			b AREA_FILEPAD_Y0 +1*10
			w AREA_FILEPAD_X0
			w AREA_FILEPAD_X1

			lda	#0

;*** neue Zeile ausgeben.
:initNewTxLine		sta	r12L
			asl
			sta	r12H

			jsr	prntCurEntry
			jmp	clrCurTxMode

;*** Dateiliste hoch/runter.
:mvFListUpDown		sta	r8L

			lda	#7*10
			sta	r8H

::loop			ldx	r7L
			txa
			clc
			adc	r8L
			sta	r7L
			jsr	GetScanLine

			lda	r5H
			sta	r0H
			lda	r5L
			sta	r0L
			ldx	r7H
			txa
			clc
			adc	r8L
			sta	r7H
			jsr	GetScanLine

			ldx	#$20
			bne	:next

::line			ldy	#$00
			lda	(r0L),y
			sta	(r5L),y

::next			clc
			lda	#8
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H

::1			clc
			lda	#8
			adc	r5L
			sta	r5L
			bcc	:2
			inc	r5H

::2			dex
			bpl	:line

			dec	r8H
			bne	:loop

			jmp	setPattern0

;*** Anzeige nach Datum.
:prntInfoDateTime	jsr	doPrintFSize

			lda	#> PAD3TAB
			sta	r11H
			lda	#< PAD3TAB
			sta	r11L

			jsr	doPrintDateTime

			lda	#SET_BOLD
			sta	currentMode
			rts

;*** Anzeige nach Größe/Typ/Name.
:prntInfoFileType	jsr	doPrintFSize

			lda	#> PAD4TAB
			sta	r11H
			lda	#< PAD4TAB
			sta	r11L

			jmp	doPrintFType

;*** Tabelle mit Verzeichnis-Einträgen erzeugen.
;Die Tabelle wird im Bereich der
;Bitmap-Grafiken für den Piktogramm-
;Modus abgelegt.
:createTabFiles		lda	#> tabFIconBitmaps
			sta	r3H
			lda	#< tabFIconBitmaps
			sta	r3L

			lda	#< dirDiskBuf +2
			sta	r4L
			lda	#> dirDiskBuf +2
			sta	r4H

			clc
			adc	a1L			;Endadresse für
			sta	r8L			;Dateisuche.

			lda	#$00			;Dateien auf Seite
			sta	a8L			;zurücksetzen.

::loop			ldy	#$00
			lda	(r4L),y			;Datei vorhanden?
			beq	:next			; => Nein, weiter...

			lda	r4L			;Zeiger auf
			sta	(r3L),y			;Dateieintrag in
			iny				;Tabelle schreiben.
			lda	r4H
			sta	(r3L),y

			clc				;Zeiger auf nächsten
			lda	#$02			;Tabelleneintrag.
			adc	r3L
			sta	r3L
			bcc	:1
			inc	r3H

::1			inc	a8L			;Dateien/Seite +1.

::next			lda	#$20			;Zeiger auf nächsten
			clc				;Verzeichnis-Eintrag.
			adc	r4L
			sta	r4L
			lda	r4H
			adc	#$00
			sta	r4H

			cmp	r8L			;Alle Seiten?
			bcc	:loop
			beq	:loop			; => Nein, weiter...
			rts

;*** Dateiliste sortieren.
;Übergabe: r4  = Zeiger auf Verzeichnis-Tabelle.
;          r5L = Anzahl Dateien auf Seite.
:sortFileList		lda	r4H
			sta	r0H
			lda	r4L
			sta	r0L

			lda	r5L			;Dateien auf Seite?
			beq	:exit			; => Nein, Ende...

			dec	r5L			;Anzahl Einträge -1.
			bne	doSortNxFiles		; => Weiter...

::exit			rts

;***Unterliste sortieren.
;Dabei werden nur so viele Dateien
;sortiert wie für die Ausgabe der
;Liste erforderlich sind.
:doSortNxFiles		lda	r0L			;Zeiger auf nächsten
			clc				;Eintrag setzen.
			adc	#$02
			sta	r0L
			sta	r1L
			lda	r0H
			adc	#$00
			sta	r0H
			sta	r1H

			ldy	#$00			;Zeiger auf
			lda	(r0L),y			;Verzeichnis-Eintrag
			sta	r7L			;nach r7 schreiben.
			clc
			adc	r5H			;Zeiger auf die
			sta	r2L			;Vergleichsdaten
			iny				;nach r2 schreiben.
			lda	(r0L),y
			sta	r7H
			adc	#$00
			sta	r2H

::loop			sec				;Zeiger für die 2te
			lda	r1L			;Datei auf den
			sbc	#$02			;vorherigen Eintrag
			sta	r1L			;setzen.
			lda	r1H
			sbc	#$00
			sta	r1H

;			lda	r1H			;2te Datei vor der
			cmp	r4H			;ersten Datei der
			bne	:1			;Seite?
			lda	r1L
			cmp	r4L
::1			bcc	:swap_1_2		; => Ja, weiter...

			ldy	#$00			;Zeiger auf die
			lda	(r1L),y			;Vergleichsaten für
			clc				;die 2te Datei nach
			adc	r5H			;r3 schreiben.
			sta	r3L
			iny
			lda	(r1L),y
			adc	#$00
			sta	r3H

			jsr	swapByteOrder

			ldx	#r2L			;Erste Datei.
			ldy	#r3L			;Zweite Datei.
			lda	r6L
			jsr	CmpFString		;Daten vergleichen.

			php				;Ergebnis speichern.

			jsr	swapByteOrder

			lda	r6H			;Anzeige nach Datum?
			beq	:2			; => Ja, weiter...

			plp
			beq	:swap_1_2
			bcs	:loop
			bcc	:swap_1_2

::2			plp
			bcc	:loop

;			...

;--- Zweiter Eintrag < Erster Eintrag, Einträge tauschen.
::swap_1_2		lda	r0L
			sta	r2L
			sta	r3L
			lda	r0H
			sta	r2H
			sta	r3H

			ldy	#$00
::move_next		lda	r2L			;Zeiger auf 1te
			sec				;Datei setzen.
			sbc	#$02
			sta	r2L
			lda	r2H
			sbc	#$00
			sta	r2H

			cmp	r1H			;Zeiger auf 1te
			bne	:move			;Datei erreicht?
			lda	r2L
			cmp	r1L
			beq	:newpos

::move			lda	(r2L),y			;Datei an die
			sta	(r3L),y			;nächste Position in
			iny				;Tabelle schreiben.
			lda	(r2L),y
			sta	(r3L),y
			dey

			lda	r3L			;Zeiger auf 2te
			sec				;Datei setzen.
			sbc	#$02
			sta	r3L
			lda	r3H
			sbc	#$00
			sta	r3H
			bne	:move_next		;Nächster Eintrag...

::newpos		clc
			lda	#$02
			adc	r1L
			sta	r1L
			bcc	:3
			inc	r1H

::3			lda	r7L			;Zeiger auf den
			sta	(r1L),y			;Verzeichnis-Eintrag
			lda	r7H			;der zweiten Datei
			iny				;an Stelle der ersten
			sta	(r1L),y			;Datei schreiben.

			dec	r5L			;Dateien soretiert?
			beq	:done

			jmp	doSortNxFiles

::done			rts

;*** Für Vergleich der Größe Low/High tauschen.
:swapByteOrder		ldy	#28
			cpy	r5H			;Anzeige nach Größe?
			bne	:exit			; => Nein, Ende...

			ldy	#$00
			lda	(r2L),y
			pha
			lda	(r3L),y
			tax
			iny
			lda	(r2L),y
			pha
			lda	(r3L),y
			dey
			sta	(r3L),y
			pla
			sta	(r2L),y
			iny
			txa
			sta	(r3L),y
			pla
			sta	(r2L),y

::exit			rts

;*** Seite hoch/runter scrollen.
:doScrolUpDn		lda	a8L
			cmp	#8 +1			;Mehr als 8 Dateien?
			bcc	:exit			; => Nein, Ende...

			lda	mouseYPos
			cmp	#AREA_SCRICON_Y0 +9
			beq	:up
			bcs	:down

::up			lda	topTxEntry +0
			ora	topTxEntry +1
			beq	:mouse

			sec
			lda	topTxEntry +0
			sbc	#$02
			sta	topTxEntry +0
			lda	topTxEntry +1
			sbc	#$00
			sta	topTxEntry +1

			jsr	func_MoveDown
			clv
			bvc	:mouse

::down			lda	topTxEntry +1
			lsr
			lda	topTxEntry +0
			ror
			clc
			adc	#$08
			cmp	a8L
			bcs	:mouse

			clc
			lda	#$02
			adc	topTxEntry +0
			sta	topTxEntry +0
			bcc	:1
			inc	topTxEntry +1

::1			jsr	func_MoveUp

::mouse			jsr	u_IsMseInRegion
			b AREA_SCRICON_Y0,AREA_SCRICON_Y1
			w AREA_SCRICON_X0,AREA_SCRICON_X1

			beq	:exit

			lda	mouseData
			beq	doScrolUpDn

::exit			rts

;*** Dateityp ausgeben.
:doPrintFType		ldy	#$16
			lda	(r15L),y		;GEOS-Datei?
			bne	:isGEOS			; => Ja, weiter...

			ldy	#$00
			lda	(r15L),y
			sec
			sbc	#$01
			and	#%00001111
			cmp	#CBMDIR
			bcs	:exit

			clc
			adc	#15

			clv
			bvc	:print

::isGEOS		cmp	#15			;Nur Dateitypen
			bcs	:exit			;0-14 möglich...

::print			tax

			ldy	#$00
			lda	(r15L),y
			pha

			lda	tabInfoFTypL,x
			pha
			lda	tabInfoFTypH,x
			tax
			pla
			jsr	putStringAX

			pla
			and	#%01000000
			beq	:exit

			ldx	#> prntWrProtStatus
			lda	#< prntWrProtStatus
			jmp	putStringAX

::exit			rts

;*** Zeiger auf Texte für GEOS-Dateityp.
:tabInfoFTypL		b < txFTyp_NotGEOS
			b < txFTyp_BASIC
			b < txFTyp_ASSEMBLE
			b < txFTyp_DATA
			b < txFTyp_SYSTEM
			b < txFTyp_DESKACC
			b < txFTyp_APPLIC
			b < txFTyp_APPLDATA
			b < txFTyp_FONT
			b < txFTyp_PRINTER
			b < txFTyp_INPUT
			b < txFTyp_DISK
			b < txFTyp_BOOT
			b < txFTyp_TEMP
			b < txFTyp_AUTOEXEC
			b < txFTyp_CBM_SEQ
			b < txFTyp_CBM_PRG
			b < txFTyp_CBM_USR
			b < txFTyp_CBM_REL
			b < txFTyp_CBM_DIR

:tabInfoFTypH		b > txFTyp_NotGEOS
			b > txFTyp_BASIC
			b > txFTyp_ASSEMBLE
			b > txFTyp_DATA
			b > txFTyp_SYSTEM
			b > txFTyp_DESKACC
			b > txFTyp_APPLIC
			b > txFTyp_APPLDATA
			b > txFTyp_FONT
			b > txFTyp_PRINTER
			b > txFTyp_INPUT
			b > txFTyp_DISK
			b > txFTyp_BOOT
			b > txFTyp_TEMP
			b > txFTyp_AUTOEXEC
			b > txFTyp_CBM_SEQ
			b > txFTyp_CBM_PRG
			b > txFTyp_CBM_USR
			b > txFTyp_CBM_REL
			b > txFTyp_CBM_DIR

;*** Sonstige Dateiinfo-Angaben.
:txFTyp_CBM_SEQ		b PLAINTEXT
			b $80				;C= SEQ
			b BOLDON
			b " SEQ"
			b NULL

:txFTyp_CBM_PRG		b PLAINTEXT
			b $80				;C= PRG
			b BOLDON
			b " PRG"
			b NULL

:txFTyp_CBM_USR		b PLAINTEXT
			b $80				;C= USR
			b BOLDON
			b " USR"
			b NULL

:txFTyp_CBM_REL		b PLAINTEXT
			b $80				;C= REL
			b BOLDON
			b " REL"
			b NULL

:txFTyp_CBM_DIR		b PLAINTEXT
			b $80				;C= CBM
			b BOLDON
			b " CBM"
			b NULL

:prntWrProtStatus	b GOTOX
			w AREA_FILEPAD_X1 -8
			b REV_ON," ",REV_OFF
			b NULL

;*** Datum/Zeit der Änderung ausgeben.
:doPrintDateTime	ldy	#$16
			lda	(r15L),y		;GEOS-Datei?
			beq	:exit			; => Nein, Ende...

			lda	r11H			;X-Koordinate
			pha				;zwischenspeichern.
			lda	r11L
			pha

if LANG = LANG_DE
			ldy	#25
			lda	(r15L),y
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Tag.

			ldy	#24
			lda	(r15L),y
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Monat.
endif
if LANG = LANG_EN
			ldy	#24
			lda	(r15L),y
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Month.

			ldy	#25
			lda	(r15L),y
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Day.
endif

			ldy	#23
			lda	(r15L),y
			clc				;Ende-Kennung.
			jsr	prntDateNum		;Jahr.

			pla				;Tabulator für
			clc				;Ausgabe Uhrzeit.
			adc	#< PAD3WIDTH
			sta	r11L
			pla
			adc	#> PAD3WIDTH
			sta	r11H

			jmp	prntFileTime

::exit			rts

;*** Jahr/Monat/tag ausgeben.
:prntDateNum		php
			jsr	prntSetDecimal
			plp
			bcc	:exit

			lda	#"/"
			jmp	PutChar

::exit			rts

;*** Uhrzeit ausgeben.
if LANG = LANG_DE
:prntFileTime		ldy	#26
			lda	(r15L),y
			bne	:1
			lda	#12
::1			sta	r0L

			lda	#SET_RIGHTJUST! SET_SUPRESS ! 12
			jsr	prntDecimal

			lda	#"."
			jsr	PutChar

			ldy	#27
			lda	(r15L),y
			pha
			cmp	#10
			bcs	:2

			lda	#"0"
			jsr	PutChar

::2			pla
endif

;*** Zahl im Akku linksbündig ausgeben.
:prntSetDecimal		sta	r0L

			lda	#SET_LEFTJUST ! SET_SUPRESS ! 16

;*** Zahl 0-255 in r0 links-/rechtsbündig ausgeben.
;Übergabe: Akku = Formatierung für ":PutDecimal".
:prntDecimal		ldy	#$00
			sty	r0H
			jmp	PutDecimal

;*** Uhrzeit ausgeben.
if LANG = LANG_EN
:prntFileTime		ldy	#26
			lda	(r15L),y
			ldy	#1
			tax
			sec
			sbc	#12
			bpl	:1
			ldy	#0
			txa
::1			bne	:2
			lda	#12
::2			sta	r0L

			tya
			pha

			lda	#SET_RIGHTJUST! SET_SUPRESS ! 12
			jsr	prntDecimal

			lda	#":"
			jsr	PutChar

			lda	r11H
			pha
			lda	r11L
			pha

			ldy	#27
			lda	(r15L),y
			pha
			cmp	#10
			bcs	:3

			lda	#"0"
			jsr	PutChar

::3			pla
			jsr	prntSetDecimal

			pla
			clc
			adc	#< 16
			sta	r11L
			pla
			adc	#> 16
			sta	r11H

			ldx	#> txAM
			ldy	#< txAM
			pla
			beq	:4

			ldx	#> txPM
			ldy	#< txPM

::4			tya
			jmp	putStringAX
endif

;*** Dateigröße in KBytes ausgeben.
:doPrintFSize		lda	#> PAD2TAB
			sta	r11H
			lda	#< PAD2TAB
			sta	r11L

			lda	#SET_RIGHTJUST!SET_SUPRESS ! $12
			bne	:1

			lda	#SET_LEFTJUST !SET_SUPRESS ! $00

::1			pha

			ldy	#28
			lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			lsr
			ror	r0L
			lsr
			ror	r0L
			sta	r0H
			ora	r0L			;Dateigröße = 0?
			bne	:2			; => Nein, weiter...

			lda	#$01			;Größe mind. 1Kb.
			sta	r0L

::2			pla
			jsr	PutDecimal		;Größe ausgeben.

			lda	#"K"
			jmp	PutChar

;*** GEOS nach BASIC verlassen.
:doExitBASIC		lda	numDrives
			cmp	#2			;Mehr als 1 Lfwk.?
			bcc	:exit			; => Nein, weiter...

			jsr	swapCurDrive

			jsr	NewDisk
			txa
			bne	:err

			jsr	PurgeTurbo		;Initialize Disk
			jsr	InitForIO		;an Lwfk. senden.

			lda	curDrive
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			lda	#"I"
			jsr	CIOUT
			lda	#":"
			jsr	CIOUT
			lda	#"0"
			jsr	CIOUT

			jsr	UNLSN

			lda	curDrive
			jsr	LISTEN
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN

			jsr	DoneWithIO

::err			jsr	swapCurDrive

::exit			jsr	prepExitBASIC

			lda	#> :noCommand
			sta	r0H
			lda	#< :noCommand
			sta	r0L
			jmp	ToBasic

;--- Kein Befehl ausführen.
::noCommand		b NULL

;*** Verlassen nach BASIC vorbereiten.
:prepExitBASIC		ldy	#$00
			tya
::1			sta	BASIC_RAM,y
			iny
			bne	:1

			sta	r5L
			sta	r5H

			lda	#> BASIC_PRG +2
			sta	r7H
			lda	#< BASIC_PRG +2
			sta	r7L
			rts

;*** BASIC-Programm laden und starten.
:doRunBASIC		jsr	getFTypeGEOS

			ldy	#30 -1
::1			lda	(a5L),y
			sta	dirEntryBuf,y
			dey
			bpl	:1

			lda	#> dirEntryBuf
			sta	r5H
			lda	#< dirEntryBuf
			sta	r5L

			ldy	#$01
			jsr	getDiskBlock_r5
			jsr	exitOnDiskErr

			ldx	#STRUCT_MISMAT
			ldy	#$16
			lda	(r5L),y			;GEOS-Dateityp.
			cmp	#DATA
			bcs	:err			; => Ungültig.
			cmp	#ASSEMBLY
			bne	:2

;--- Assembler-Datei.
			jmp	loadAbsolute

;--- Nicht-GEOS/BASIC-Datei.
::2			jmp	loadRelative

;--- Datei ungültig.
::err			rts

;*** Relativ laden (LOAD"x",8,0).
:loadRelative		lda	diskBlkBuf +3
			cmp	#$04
			bcs	:1
			jmp	loadRelBASIC

::1			ldx	#STRUCT_MISMAT
			cmp	#>BASIC_PRG		;BASIC-Start $0801?
			bne	:err			; => Nein, Fehler...

			lda	diskBlkBuf +2
			cmp	#<BASIC_PRG		;BASIC-Start $0801?
			bne	:err			; => Nein, Fehler...

			ldx	#BFR_OVERFLOW
			ldy	#29
			lda	(r5L),y
			bne	:err
			dey
			lda	(r5L),y
			cmp	#$79			;Größer 121 Blocks?
			bcs	:err			; => Ja, Fehler...

			lda	#> runCommand
			sta	r0H
			lda	#< runCommand
			sta	r0L

			lda	#> BASIC_PRG
			sta	r7H
			lda	#< BASIC_PRG
			sta	r7L
			jmp	ToBasic

::err			rts

;*** Relativ über BASIC-LOAD laden.
:loadRelBASIC		jsr	createLoadCom
			jsr	prepExitBASIC

			lda	#> loadCommand
			sta	r0H
			lda	#< loadCommand
			sta	r0L
			jmp	ToBasic

:runCommand		b "RUN",NULL

;*** Absolut laden (LOAD"x",8,1).
:loadAbsolute		lda	diskBlkBuf +3
			cmp	#$04
			bcs	:1
			jmp	loadRelBASIC

::1			sta	r7H

			ldx	#STRUCT_MISMAT
			cmp	#>BASIC_PRG
			bcc	errLoad1

			lda	diskBlkBuf +2
			sta	r7L

			ldy	#19			;Infoblock.
			jsr	getDiskBlock_r5
			jsr	exitOnDiskErr

			jsr	getSysAdr

;--- Datei überschreibt Bereich ab $8000!
			lda	diskBlkBuf +$4a
			cmp	#> diskBlkBuf
			bcs	loadAbsBASIC		; => Ja, BASIC-LOAD.

			lda	#> sysCommand
			sta	r0H
			lda	#< sysCommand
			sta	r0L
			jmp	ToBasic

;*** Absolut über BASIC-LOAD laden.
:loadAbsBASIC		jsr	createLoadCom
			jsr	prepExitBASIC

			lda	#> sysCommandAdd
			sta	r0H
			lda	#< sysCommandAdd
			sta	r0L
			jsr	addSysLoadCom

			lda	#> loadCommand
			sta	r0H
			lda	#< loadCommand
			sta	r0L
			jmp	ToBasic

:errLoad1		rts

:sysCommandAdd		b ":"
:sysCommand		b "SYS("			;SYS(Adresse).
:sysComAdr		b "     "
			b ")"
			b NULL

;*** Assembler/GEOS-Datei:
;    SYS-Adresse aus Infoblock einlesen.
:getSysAdr		lda	diskBlkBuf +$4c
			sta	r0H
			lda	diskBlkBuf +$4b
			sta	r0L

			ldx	#$04

			lda	#$00
			sta	r2L

::1			ldy	#$00

::2			lda	r0L
			sec
			sbc	:tabDezNumL,x
			sta	r0L
			lda	r0H
			sbc	:tabDezNumH,x
			bcc	:3

			sta	r0H
			iny
			bne	:2

::3			lda	r0L
			adc	:tabDezNumL,x
			sta	r0L
			tya
			ora	#"0"

			ldy	r2L
			sta	sysComAdr,y

			inc	r2L
			dex
			bpl	:1
			rts

::tabDezNumL		b <1,<10,<100,<1000,<10000
::tabDezNumH		b >1,>10,>100,>1000,>10000

:loadCommand		b "LOAD "
			b $22				; => "
:loadComFName		s 34

:loadComData		b $22				; => "
			b ","
:comDrvAdr		b "  "				;Geräteadresse.
			b ",1"
			b NULL

;*** Dateiname für LOAD-Befehl.
:createLoadCom		ldy	#$03
::1			cpy	#$13
			beq	:2
			lda	(r5L),y
			cmp	#$a0
			beq	:2
			sta	loadComFName -3,y
			iny
			bne	:1

::2			lda	#$00
			sta	loadComFName -3,y

			lda	#" "
			sta	comDrvAdr +0

			lda	curDrive
			cmp	#10
			bcc	:3

			lda	#"1"
			sta	comDrvAdr +0

			lda	curDrive
			sec
			sbc	#10

::3			ora	#"0"
			sta	comDrvAdr +1

			lda	#> loadComData
			sta	r0H
			lda	#< loadComData
			sta	r0L

;*** SYS-Befehl anhängen.
:addSysLoadCom		ldx	#$00			;Ende suchen...
::1			lda	loadCommand,x
			beq	:2
			inx
			bne	:1

::2			ldy	#$00			;String anhängen.
::3			lda	(r0L),y
			sta	loadCommand,x
			beq	:4
			iny
			inx
			bne	:3
::4			rts

;*** Diskette umbennenen.
:doDiskRename		jsr	unselectIcons

			lda	diskOpenFlg		;Diskette geöffnet?
			beq	:exit			; => Nen, Ende...

			jsr	testDiskChanged
			jsr	chkErrRestartDT

::restart		ldx	#r4L
			jsr	setVecOpenDkNm

			lda	#> buf_TempStr1
			sta	r6H
			lda	#< buf_TempStr1
			sta	r6L

			ldx	#r4L
			ldy	#r6L
			jsr	copyNameA0_16

			ldx	#> dbox_DiskRName
			lda	#< dbox_DiskRName
			jsr	openDlgBox

			lda	r0L
			cmp	#CANCEL
			beq	:exit

			lda	buf_TempStr1
			beq	:restart

			jsr	clrBIconCurDisk
			jsr	getIconNumCurDrv
			jsr	clrDeskPadIcon

			ldx	#> buf_TempStr1
			lda	#< buf_TempStr1
			jsr	writeNewDiskNm
			jsr	chkErrRestartDT

			jmp	reopenCurDisk

::exit			rts

;*** Neuen Disknamen auf Diskette schreiben.
:writeNewDiskNm		stx	r6H
			sta	r6L

			lda	#> curDirHead +$90
			sta	r7H
			sta	r9H
			lda	#< curDirHead +$90
			sta	r7L
			sta	r9L

			ldx	#18
			jsr	convertNameCBM

			jmp	PutDirHead

;*** Dialogbox: Diskette umbenennen.
:dbox_DiskRName		b %10000001
			b DBTXTSTR   ,$10,$20
			w dbtxNewDiskNm
			b DBGETSTRING,$10,$30
			b r6L,16
			b CANCEL     ,$11,$48
			b NULL

;*** Datei umbenennen.
:doFileRename		jsr	testDiskChanged

			ldx	#> batchJobFRename
			lda	#< batchJobFRename
			jmp	execBatchJob

:batchJobFRename	jsr	testSystemFile
			jsr	testFileOtherDk
			jsr	getNewFileName
			jsr	chkErrRestartDT

			tya
			beq	:1

			jsr	writeNewFileNm

			jsr	chkErrRestartDT

::1			jsr	removeJobIcon
			jsr	analyzeDirFiles
			jsr	prntCurPadPage
			jsr	updInfoScrnSlct

			ldx	#NO_ERROR
			rts

;*** Neuen Dateinamen abfragen.
:getNewFileName		jsr	setVecFNamEntry
			jsr	r5_r6_TempName

			ldx	#r9L
			ldy	#r6L
			jsr	copyNameA0_16

			ldx	#r9L
			ldy	#r5L
			jsr	copyNameA0_16

			lda	#> dbtx_NewFName
			sta	r7H
			lda	#< dbtx_NewFName
			sta	r7L

			ldx	#> dbox_FileRName
			lda	#< dbox_FileRName
			jsr	openDlgBox

			jsr	r5_r6_TempName

			lda	r0L
			cmp	#CANCEL
			beq	:ok

			ldy	#$00
			lda	(r6L),y
			beq	getNewFileName

			jsr	compareFName
			beq	:ok

			jsr	testFileExist
			jsr	r5_r6_TempName

			ldy	#$ff

			cpx	#$ff			;DeskTop ungültig...
			beq	getNewFileName

			cpx	#CANCEL_ERR		;Abbruch?
			bne	:exit			; => Ja, Ende...

::ok			ldx	#NO_ERROR
			ldy	#$00

::exit			rts

;*** Dateiname Alt/Neu vergleichen.
:compareFName		jsr	r5_r6_TempName

			ldx	#r6L
			ldy	#r5L
			jmp	CmpString

;*** Dialogbox: Datei umbenennen.
:dbox_FileRName		b %10000001
			b DBVARSTR   ,$10,$20
			b r7L
			b DBGETSTRING,$10,$30
			b r6L,16
			b CANCEL     ,$11,$48
			b NULL

;*** Neuen Dateinamen schreiben.
:writeNewFileNm		lda	r6H
			pha
			lda	r6L
			pha

			jsr	initVecCurDEntry

			clc
			lda	#$03
			adc	r7L
			sta	r7L
			bcc	:1
			inc	r7H

::1			clc
			lda	#$03
			adc	r9L
			sta	r9L
			bcc	:2
			inc	r9H

::2			pla
			sta	r6L
			pla
			sta	r6H

			ldx	#16
			jsr	convertNameCBM

			lda	a3L
			jmp	writeDirEntry

;*** Dateien duplizieren.
:doFileDuplicate	jsr	testDiskChanged

			bit	a2H
			bpl	:exit

			ldx	#> batchJobFDouble
			lda	#< batchJobFDouble
			jmp	execBatchJob

::exit			rts

:batchJobFDouble	jsr	testSystemFile
			jsr	testFileOtherDk

			jsr	getNewFileName
			txa
			bne	:err
			tya
			beq	:skip

			jsr	setVecFNamEntry
			jsr	r5_bufTempStr1

			ldx	#r9L
			ldy	#r5L
			jsr	copyNameA0_16

			lda	#$02
			sta	nmDkSrc +1
			sta	nmDkTgt +1

			lda	#$00
			sta	nmDkSrc +0
			sta	nmDkTgt +0

			lda	#> buf_TempStr1
			sta	vec2FCopyNmSrc +1
			lda	#< buf_TempStr1
			sta	vec2FCopyNmSrc +0

			lda	#> buf_TempStr2
			sta	vec2FCopyNmTgt +1
			lda	#< buf_TempStr2
			sta	vec2FCopyNmTgt +0

			lda	curDrive
			sta	a1H			;Quell-Laufwerk.
			sta	a2L			;Ziel -Laufwerk.

			lda	a0L			;Freien Eintrag ab
			sta	a0H			;aktueller Seite.

			lda	#$ff			;Modus: Duplizieren.
			jsr	doJobCopyFile

::err			jsr	chkErrReopenDisk

			lda	#$00			;Icon aus Auswahl
			sta	a8H			;entfernen.
			jsr	removeJobIcon

			lda	a0H			;Neue aktuelle
			sta	a0L			;DeskPad-Seite.

			cmp	a1L			;Neue Seite?
			bcc	:skip			; => Nein, weiter...

			sta	a1L			;Neue Seitenanzahl
			clv				;setzen, Ende...
			bvc	:exit

::skip			jsr	removeJobIcon
::exit			jmp	testCurDiskReady

;*** Zeiger auf Dateiname im aktuellen Eintrag setzen.
:setVecFNamEntry	lda	a5L
			clc
			adc	#$03
			sta	r9L
			lda	a5H
			adc	#$00
			sta	r9H
			rts

;*** Existiert Ziel-Datei?
:testFileExist		jsr	FindFile		;Datei suchen.

			jsr	r5_r6_TempName

			cpx	#FILE_NOT_FOUND
			bne	:1

			jsr	testNameDeskTop
			beq	:invalid
			bne	:ok

::1			jsr	exitOnDiskErr

;--- Dialogbox: Datei existiert bereits.
			jsr	r5_bufTempStr1

			ldx	#r6L			;Dateiname der
			ldy	#r5L			;vorhandenen Datei.
			jsr	CopyString
			jsr	r5_r6_TempName

			ldx	#r5L			;Dateiname für
			ldy	#r6L			;neue Datei.
			jsr	CopyString
			jsr	r5_bufTempStr1

			ldx	#> dbox_FileExist
			lda	#< dbox_FileExist
			jsr	openDlgBox

			jsr	r5_r6_TempName

			ldx	#CANCEL_ERR

			lda	r0L
			cmp	#CANCEL			;Abbruch?
			beq	:cancel			; => Ja, Ende...

			ldy	#$00
			lda	(r6L),y			;Name eingegeben?
			beq	:invalid		; => Nein, Abbruch...

			jsr	testNameDeskTop
			beq	:invalid		; => Name ungültig.

			jsr	compareFName
			bne	testFileExist

			ldx	#CANCEL_ERR		;Gleicher Name.
			bne	:cancel			; => Abbruch...

::ok			ldx	#NO_ERROR		;Kein Fehler.
			beq	:cancel

::invalid		ldx	#$ff
::cancel		rts

;*** Dateiname mit DeskTop vergleichen.
:testNameDeskTop	lda	#> nameDESKTOP
			sta	r5H
			lda	#< nameDESKTOP
			sta	r5L

			ldx	#r6L
			ldy	#r5L
			jmp	CmpString

;*** r5 auf temp. Dateinamen setzen.
:r5_bufTempStr1		lda	#> buf_TempStr1
			sta	r5H
			lda	#< buf_TempStr1
			sta	r5L
			rts

;*** Dialogbox: Datei existiert bereits.
:dbox_FileExist		b %10000001
			b DBTXTSTR   ,$10,$10
			w txString_File
if LANG = LANG_DE
			b DBVARSTR   ,$2e,$10
endif
if LANG = LANG_EN
			b DBVARSTR   ,$42,$10
endif
			b r5L
			b DBTXTSTR   ,$10,$20
			w dbtx_FileExist
			b DBTXTSTR   ,$10,$30
			w dbtx_NewFName +1
			b DBGETSTRING,$10,$40
			b r6L,16
			b CANCEL     ,$11,$48
			b NULL

;*** Name in CBM-Format wandeln und mit SHIFT-SPACE füllen.
:convertNameCBM		ldy	#$00
::1			lda	(r6L),y
			beq	:2
			sta	(r9L),y
			sta	(r7L),y
			iny
			dex
			bne	:1
			beq	:exit

::2			lda	#$a0
::3			sta	(r9L),y
			sta	(r7L),y
			iny
			dex
			bne	:3
::exit			rts

if LANG = LANG_DE
:dbtx_FileExist		b BOLDON
			b "existiert schon.",NULL
endif
if LANG = LANG_EN
:dbtx_FileExist		b BOLDON
			b "already exists.",NULL
endif

;*** Variabler Text für Dialogbox.
:dbtx_NewFName		b BOLDON

;--- Text für Dialogbox.
if LANG = LANG_DE
::dbtx_NewFName2	b "Neuen Dateinamen eingeben:"
			b PLAINTEXT
			b NULL
endif
if LANG = LANG_EN
::dbtx_NewFName2	b "Please enter new filename:"
			b PLAINTEXT
			b NULL
endif

;Endadresse VLIR-Modul testen:
			g vlirModEnd
