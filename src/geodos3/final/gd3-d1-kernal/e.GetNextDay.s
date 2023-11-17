; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.GetNextDay"
			t "G3_Data.V.Class"

			o LD_ADDR_GETNXDAY

;*** Neuen Tag definieren.
:GetNextDay		ldy	month			;Zeiger auf Tagestabelle.
			lda	DaysPerMonth -1,y	;Anzahl Tage/Monat einlesen.
			cpy	#$02			;Monat = "Februar" ?
			bne	:52			;Nein, weiter...
			tay
			lda	year			;Auf Schaltjahr testen.
			and	#$03
			bne	:51			; => Kein Schaltjahr.
			iny				;"Februar" = 29 Tage.
::51			tya

::52			cmp	day			;Letzter Tag erreicht ?
			bne	:55			;Nein, weiter...
			ldy	#$00			;Tag auf Anfangswert setzen.
			sty	day
			lda	month
			cmp	#12			;Letzter Monat erreicht ?
			bne	:54			;Nein, weiter...
			sty	month			;Monat auf Anfangswert setzen.
			lda	year
			cmp	#99			;Letztes Jahr (99) erreicht ?
			bne	:53			;Nein, weiter...
			dey				;Jahr auf Anfangswert setzen.
			sty	year
::53			inc	year			;Datum +1.
::54			inc	month
::55			inc	day

			ldx	#19
			lda	year			;Jahrtausendbyte festlegen.
			cmp	#99
			bcs	:56
			inx
::56			stx	millenium
			jmp	SwapRAM

;*** Tabelle mit der Anzahl von Tagen pro Monat.
:DaysPerMonth		b 31,28,31,30,31,30
			b 31,31,30,31,30,31

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_GETNXDAY + R2_SIZE_GETNXDAY -1
;******************************************************************************
