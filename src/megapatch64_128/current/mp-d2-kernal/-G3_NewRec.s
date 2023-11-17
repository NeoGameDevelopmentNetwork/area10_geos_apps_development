; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if Flag64_128 = TRUE_C64
;*** Rechteck zeichen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xRectangle		jsr	TestFastRec		;Auf FastRectangle testen.
							;Rückkehr nur wenn FastRec
							;nicht möglich ist.

			lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.
::51			lda	r11L
			and	#$07
			tay				;Linienmuster für aktuelle
			lda	(curPattern),y		;Zeile einlesen.
			jsr	xHorizontalLine		;Horizontale Linie zeichnen.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:51			;Nein, weiter...
			rts
endif

if Flag64_128 = TRUE_C128
;*** Rechteck zeichen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xRectangle		lda	curPattern		;neuer Musterpointer (low)
			ldx	curPattern+1		;neuer Musterpointer (high)
			cpx	LastcurPattern+1	;auf altem MusterPointer (high)?
			bne	:2			;>nein dann Muster neu einlesen
			cmp	LastcurPattern		;auf altem MusterPointer (low)?
			beq	:3			;>ja Muster schon vorhanden
::2			sta	LastcurPattern		;>neuen Pointer speichern
			stx	LastcurPattern+1
			php
			sei
			PushB	RAM_Conf_Reg		;Configuration sichern
			and	#%11110000		;Common-Area $e000 - $ffff
			ora	#%00001010		;da die Pattern im Bereich von
			sta	RAM_Conf_Reg		;$c000 - $cfff liegen und nicht
			ldy	#7			;verschoben werden können
::1			lda	(curPattern),y		;aktuelles Pattern in Zwischen-
			sta	aktPattern,y		;speicher schreiben
			dey
			bpl	:1
			PopB	RAM_Conf_Reg		;Configuration wiederherstellen
			plp

::3			jsr	TestFastRec		;Auf FastRectangle testen.
							;Rückkehr nur wenn FastRec
							;nicht möglich ist.
			lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.
::51			lda	r11L
			and	#$07			;Linienmuster für aktuelle Zeile einlesen
			tay				;Anfangsmuster ins Y-Register
			lda	aktPattern,y		;Pattern für aktuelle Zeile
			jsr	_HorizontalLine		;Horizontale Linie zeichnen.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:51			;Nein, weiter...
			rts

:aktPattern		s	8			;aktuelles Muster
:LastcurPattern		w	$0000			;letzter Zeiger auf curPattern
endif
