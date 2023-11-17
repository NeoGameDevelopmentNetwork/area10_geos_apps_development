; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien im Speicher sortieren.
;Sortieralgorythmus:
;       a4 = Ende
;:loop1 a2 = Aktuell
;       a4 -> a3
;:loop3 a2 = a3? -> loop2
;       a0/compare
;           a3 < a2? ->swap
;       a3  -32
;       -> loop3
;:loop2 a2 +32
;       a2 = a4? -> loop1
;
;    a0   = Anzahl Einträge.
;    a1   = Startadresse Einträge im Speicher.
;    a2   = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a3   = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;    a4   = Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;
;    a5   = Anzahl Dateien -1.
;
:xSORT_ALL_FILES	lda	a0L
			ldx	a0H
			bne	:do_sort
			cmp	#$02
			bcs	:do_sort

::no_sort		ldx	#$ff			;Weniger als 2 Dateien, Ende...
			rts

::do_sort		sec				;Zeiger auf letzten Eintrag
			sbc	#$01			;berechnen.
			sta	a5L
			bcs	:1
			dex
::1			stx	a5H

;--- Adressen Verzeichnis im Speicher.
			MoveW	a5,a4
			ldx	#a4L			;Zeiger auf letzten Verzeichnis-
			jsr	setDataPos		;Eintrag im Speicher berechnen.

			ClrW	a2
			ldx	#a2L			;Zeiger auf ersten Verzeichnis-
			jsr	setDataPos		;Eintrag im Speicher berechnen.

::do_compare		MoveW	a4,a3			;Temporärer Zähler auf letzten

::next_entry		CmpW	a3,a2			;Aktueller Zähler = temp. Zähler?
			beq	:do_next		; => Ja, weiter...

			jsr	SortName		;Einträge vergleichen.

			SubVW	32,a3			;Temporären Zähler Speicher.

			jmp	:next_entry		;Weiter mit nächstem Vergleich.

::do_next		AddVBW	32,a2			;Nächster Eintrag Speicher.

			CmpW	a2,a4			;Ende erreicht?
			beq	:exit			; => Ja, Ende...

			jmp	:do_compare		; => Nein, weiter...

::exit			ldx	#$00			;Dateien sortiert, Ende.
			rts

;*** Einträge vergleichen.
;    a2 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a3 = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.

;*** Modus: Name.
:SortName		ldy	#$05
			lda	(a2L),y			;Zuerst nach Buchstabe a=A
			jsr	:convert_upper		;vergleichen.
			sta	:101 +1
			lda	(a3L),y
			jsr	:convert_upper
::101			cmp	#$ff
			bcc	:106
			beq	:102
			bcs	:109

::102			lda	(a3L),y			;Hier unterscheiden zwischen
			cmp	(a2L),y			;Groß- und Kleinbuchstaben.
			beq	:108
			bcc	:103
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::103			rts

::104			ldy	#$05			;Zeichen vergleichen.
::105			lda	(a3L),y
			cmp	(a2L),y
			bcs	:107
::106			jmp	SwapEntry		;Eintrag tauschen/sortieren.

::107			bne	:109
::108			iny				;Weitervergleichen bis
			cpy	#$15			;alle 11 Zeichen geprüft.
			bne	:105
::109			rts

::convert_upper		cmp	#$61			;Kleinbuchstaben in
			bcc	:13			;Großbuchstaben wandeln.
			cmp	#$7e			;Sortieren nach Buchstabe a=A,...
			bcs	:13			;Kein Unterschied Groß/Klein.
::12			sec
			sbc	#$20
::13			rts

;*** Einträge vertauschen.
;    a2 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a3  = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
:SwapEntry		ldy	#$1f			;Einträge im Speicher tauschen.
::101			lda	(a2L),y
			tax
			lda	(a3L),y
			sta	(a2L),y
			txa
			sta	(a3L),y
			dey
			bpl	:101
			rts

;******************************************************************************
;Routine:   setDataPos
;Parameter: XReg = Zero-Page-Adresse Faktor #1.
;Rückgabe:  Zero-Page Faktor#1 erhält Adresse im RAM.
;Verändert: A,X,Y,r6-r8
;Funktion:  Zeiger auf Eintrag im Speicher berechnen.
;******************************************************************************
:setDataPos		ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.

if MAXENTRY16BIT = TRUE
			lda	#$00			;High-Byte Dateizähler löschen.
			sta	zpage +1,x
endif

			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			lda	zpage +0,x
			clc
			adc	a1L
			sta	zpage +0,x
			lda	zpage +1,x
			adc	a1H
			sta	zpage +1,x
			rts
