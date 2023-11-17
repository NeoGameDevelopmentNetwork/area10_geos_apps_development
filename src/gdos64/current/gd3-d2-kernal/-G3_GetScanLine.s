; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeilenadresse berechnen.
:xGetScanLine_r11	ldx	r11L
:xGetScanLine		txa				;Nummer der Bildschirmzeile
			pha				;zwischenspeichern.
;--- Ergänzung: 21.10.18/M.Kanet
;Der zusätzliche PHA/PLA Befehl ist unnötig da der Wert für
;die Bildschirmzeile noch im XReg ist.
;			pha
			and	#%00000111		;Zeile innerhalb eines CARDs
			sta	r6H			;ermitteln.
;			pla
			txa
			lsr
			lsr
			lsr
			tax

			jsr	:104			;Adresse Grafikspeicher setzen.

			bit	dispBufferOn
			bpl	:102			; -> Vordergrund nicht aktiv.
			bvc	:103			; -> Grafik nur in Vordergrund.

;*** Grafik im Vordergrund und Hintergrund.
::101			jsr	:105			;Grafikadressen berechnen.
			pla
			tax
			rts

;*** Grafik nicht im Vordergrund.
::102            ;bit	dispBufferOn			;Grafik im Hintergrund ?
			bvc	:103			;(BIT #6 ist noch im Status-
							; Register aktiv! Im Original-
							; Code Sprung nach :106!)

;*** Grafik nur im Hintergrund.
			jsr	:105			;Adr. Hintergrund berechnen und
			sta	r5H			;Vordergrund gleichsetzen.

;*** Grafikadresse für Vordergrund/Hintergrund gleichsetzen.
::103			lda	r5L
			sta	r6L
			lda	r5H
			sta	r6H
			pla
			tax
			rts

;*** Adresse in Grafikspeicher berechnen.
::104			lda	GrfxLinAdrL,x		;Adresse für Vordergrund-Grafik
			ora	r6H			;berechnen.
			sta	r5L
			lda	GrfxLinAdrH,x
			sta	r5H
			rts

;*** Adresse für Hintergrund berechnen.
::105			ldx	r5L			;LowByte gleichsetzen.
			stx	r6L
;			lda	r5H			;HighByte (noch im Akku!) für
			sec				;Hintergrund berechnen.
			sbc	#$40
			sta	r6H
			rts

;*** Die folgende Routine wurde entfernt da kein ersichtlicher Grund
;    vorliegt, die Position der gewünschten Pixelzeile auf die Bildmitte
;    zu fixieren. Stattdessen wird, wenn dispBufferOn = %00xxxxxx ist,
;    nur auf den Vordergrund geschrieben!
;::106			lda	#$00			;Bildschirmmitte.
;			sta	r5L
;			sta	r6L
;			lda	#$af
;			sta	r5H
;			sta	r6H
;			pla
;			tax
;			rts

;*** Startadressen der 25 Bildschirm-
;    zeilen im Grafikspeicher.
:GrfxLinAdrL		b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00

:GrfxLinAdrH		b $a0,$a1,$a2,$a3
			b $a5,$a6,$a7,$a8
			b $aa,$ab,$ac,$ad
			b $af,$b0,$b1,$b2
			b $b4,$b5,$b6,$b7
			b $b9,$ba,$bb,$bc
			b $be
