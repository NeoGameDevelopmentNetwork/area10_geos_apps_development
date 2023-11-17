; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if Flag64_128 = TRUE_C64
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
endif

if Flag64_128 = TRUE_C128
;*** Zeilenadresse berechnen.
:xGetScanLine		bit	graphMode		;welcher Garfikmodus?
			bpl	GetScanLine40
			jmp	GetScanLine80

:GetScanLine40		txa
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
			bit	dispBufferOn
			bpl	NotForeground
			bvs	FORandBack		;Fore- und Background
:OnlyForground		lda	GrfxLinAdrL,x		;>nur Vordergrund
			ora	r6H
			sta	r5L
			lda	GrfxLinAdrH,x
			sta	r5H
			jmp	MOVEr5TOr6

:FORandBack		lda	GrfxLinAdrL,x
			ora	r6H
			sta	r5L
			sta	r6L
			lda	GrfxLinAdrH,x
			sta	r5H
			sec
			sbc	#$40
			sta	r6H
			pla
			tax
			rts

:NotForeground		bvc	OnlyForground
			lda	GrfxLinAdrL,x
			ora	r6H
			sta	r6L
			lda	GrfxLinAdrH,x
			sec
			sbc	#$40
			sta	r6H
			jmp	MOVEr6TOr5

;:lf64a			lda	#$00
;			sta	r5L
;			sta	r6L
;			lda	#$af
;			sta	r5H
;			sta	r6H
;			pla
;			tax
;			rts

;*** Startadressen der 25 Bildschirmzeilen im Grafikspeicher.
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

:GetScanLine80		txa
			pha
			stx	r5H
			lda	#$00
			lsr	r5H
			ror
			lsr	r5H
			ror
			sta	r5L
			ldx	r5H
			stx	r6L
			lsr	r5H
			ror
			lsr	r5H
			ror
			clc
			adc	r5L
			sta	r5L
			lda	r6L
			adc	r5H
			sta	r5H
			bit	dispBufferOn
			bpl	lf6a6
			bvs	lf685
			clv
			bvc	MOVEr5TOr6
:lf685			pla
			tax
:lf687			lda	r5H
			clc
			adc	#$60
			sta	r6H
			lda	r5L
			sta	r6L
			lda	r6H
			cmp	#$7f
			bne	lf69c
			lda	r6L
			cmp	#$40
:lf69c			bcc	lf6a5
			lda	r6H
			clc
			adc	#$21
			sta	r6H
:lf6a5			rts
:lf6a6			bvc	MOVEr5TOr6
			jsr	lf687

;*** Grafikadresse für Vordergrund gleich wie Hintergrund setzen.
:MOVEr6TOr5		lda	r6L
			sta	r5L
			lda	r6H
			sta	r5H
			pla
			tax
			rts

;*** Grafikadresse für Hintergrund gleich wie Vordergrund setzen.
:MOVEr5TOr6		lda	r5L
			sta	r6L
			lda	r5H
			sta	r6H
			pla
			tax
			rts
endif
