; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** SuperCPU-16Bit-Routinen.
;******************************************************************************
;*** Speicherbereich löschen.
:s_ClearRam		lda	#$00			;Füllbyte $00.
			sta	r2L

;*** Speicherbereich füllen.
:s_FillRam		php
			sei

			txa				;X-Register zwischenspeichern.
			pha				;(Original-Routine verwendet
							; nur A/Y-Register!)

			b $18				;clc
			b $fb				;xce
			b $c2,$10			;rep #$00010000

			b $a2,$00,$00			;ldx #$0000
			b $a4,$04			;ldy r1
			b $a5,$06			;lda r2L
::51			b $99,$00,$00			;sta $0000,y
			b $c8				;iny
			b $e8				;inx
			b $e4,$02			;cpx r0
			b $d0,$f7			;bne :51

			b $38				;sec
			b $fb				;xce

			pla
			tax

			plp
			rts

;*** Inline: Speicher verschieben.
:s_i_MoveData		pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			jsr	Get2Word1Byte
			iny
			lda	(returnAddress),y
			sta	r2H
			jsr	s_MoveData
			jmp	Exit7ByteInline

;*** Speicherbereich veschieben.
:s_MoveData		lda	r2L
			ora	r2H			;Anzahl Bytes = $0000 ?
			beq	:51			;Ja, -> Keine Funktion.

			txa				;X-Register sichern.
			pha
			jsr	DoMove			;MoveData ausführen.
			pla
			tax				;X-Register zurücksetzen.

::51			rts

:DoMove			php				;IRQ sperren.
			sei

			b $18				;clc
			b $fb				;xce
			b $c2,$30			;rep #$30

			b $a5,$02			;lda $0002
			b $c5,$04			;cmp $0004
			b $90,$0e			;bcc CopyDown

			b $a5,$06			;lda $0006
			b $3a				;dea
			b $a6,$02			;ldx $0002
			b $a4,$04			;ldy $0004

			b $54,$00,$00			;mvn $00.$00

			b $38				;sec
			b $fb				;xce

			plp				;(Pause/Umschalten auf 8Bit!!)
			rts

:CopyDown		b $a5,$06			;lda $0006
			b $3a				;dea
			b $48				;pha
			b $18				;clc
			b $65,$02			;adc $0002
			b $aa				;tax
			b $68				;pla
			b $48				;pha
			b $18				;clc
			b $65,$04			;adc $0004
			b $a8				;tay
			b $68				;pla

			b $44,$00,$00			;mvp $00.$00

			b $38				;sec
			b $fb				;xce

			plp				;(Pause/Umschalten auf 8Bit!!)
			rts

;*** Neue SuperCPU-I/O-Routinen.
:s_InitForIO		jsr	:52			;InitForIO aufrufen.

			lda	SCPU_HW_SPEED		;Aktuellen Takt einlesen und
			sta	s_DoneWithIO +1		;zwischenspeichern.

			ldy	curDrive		;Laufwerksmodus einlesen.
			lda	RealDrvMode -8,y
			and	#%00100000		;20Mhz-kompatibel ?
			bne	:51			; => Ja, weiter...

			sta	SCPU_HW_NORMAL		;Umschalten auf 1Mhz.
::51			rts

::52			jmp	($9000)			;InitForIO aufrufen.

:s_DoneWithIO		lda	#$ff			;Speed-Flag testen.
			bmi	:51			;War 20Mhz-Modus aktiv ?
			sta	SCPU_HW_TURBO		; => Ja, auf 20Mhz umschalten.
::51			jmp	($9002)			;DoneWithIO aufrufen.

;*** GEOS optimieren.
:s_SCPU_OptOn		ldy	#$00			;Flag: GEOS-Optimieren.
			b $2c
:s_SCPU_OptOff		ldy	#$03			;Flag: GEOS nicht optimieren.
			sty	Flag_Optimize		;Modus merken.

:s_SCPU_SetOpt		php
			sei				;IRQ abschalten.

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			ldy	Flag_Optimize		;Modus merken.
			sta	SCPU_HW_EN		;Hardware-Register einschalten.
			sta	SCPU_HW_VIC_OPT,y	;Optimierung setzen.
			sta	SCPU_HW_DIS		;Hardware-Register ausschalten.

			stx	CPU_DATA

			plp				;IRQ zurücksetzen.
			rts
