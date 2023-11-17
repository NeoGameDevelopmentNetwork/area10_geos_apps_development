; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"TopMac"
endif

			n	"FixDiskName"
			c	"D81FIX      V1.0",NULL
			a	"Markus Kanet",NULL
			o	$1000
			h	"Convert disk name from GEOS to BASIC format."

:Start			lda	curType
			and	#%0000 0111
			cmp	#$03
			bne	:1

			lda	#40
			sta	r1L
			lda	#0
			sta	r1H
			sta	r4L
			lda	#>diskBlkBuf
			sta	r4H
			jsr	GetBlock
			txa
			bne	:1
			jsr	SwapDskNamData
			jsr	PutBlock
::1			jmp	EnterDeskTop

:SwapDskNamData		ldy	#$04			;Zeiger auf Angang Diskname.
::51			lda	(r4L),y			;Zeichen aus Original-Name lesen
			sta	:SwapByteBuf		;und zwischenspeichern.

			tya				;Zeiger auf 1541/1571 kompatible
			clc				;Position des Disknamen setzen.
			adc	#$8c
			tay

			lda	(r4L),y			;Zeichen aus 1541/1571 kompatiblen
			pha				;Disknamen einlesen und merken.

			lda	:SwapByteBuf		;Zeichen aus Original-Name wieder
			sta	(r4L),y			;einlesen und an kompatible
							;Position speichern.
			tya				;Zeiger zurück auf originale
			sec				;Position des Disknamen setzen.
			sbc	#$8c
			tay

			pla				;Zeichen aus 1541/1571 kompatiblen
			sta	(r4L),y			;Disknamen wieder einlesen und
							;an originaler Stelle einfügen.
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#$1d			;Alle Zeichen getauscht?
			bne	:51			; => Nein, weiter...

;			ldx	#$00			;XReg zurücksetzen/Kein Fehler.
			rts				;Ende.

::SwapByteBuf		b $00
