; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;*** Sektoren in D64-Datei einlesen.
:GetSekOfD64File	jsr	ScreenInfo3

			jsr	i_FillRam
			w	768 * 3
			w	StartSekTab
			b	$00

			jsr	FindSlctFile

			jsr	EnterTurbo
			jsr	InitForIO

			LoadW	a0 ,StartSekTab
			LoadW	a1L,$02
			LoadW	a2 ,$0000

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf

::101			jsr	ReadBlock

			ldy	#$00
			lda	r1L
			sta	(a0L),y
			iny
			lda	r1H
			sta	(a0L),y
			iny
			lda	a1L
			sta	(a0L),y

			lda	a0L
			clc
			adc	#$03
			sta	a0L
			bcc	:102
			inc	a0H

::102			inc	a2L
			bne	:103
			inc	a2H

::103			inc	a1L
			inc	a1L
			lda	a1L
			bne	:104
			lda	diskBlkBuf +1
			sta	r1H
			lda	diskBlkBuf +0
			sta	r1L
			beq	:105
			jsr	ReadBlock
			jmp	:103

::104			lda	diskBlkBuf +1
			sta	r1H
			lda	diskBlkBuf +0
			sta	r1L
			bne	:101

::105			jsr	DoneWithIO
			jmp	ScreenInfo2

;*** Zeiger auf Sektor berechnen.
:PosToSektor		pha
			LoadW	a0,StartSekTab
			LoadB	a1L,$01
::101			cpx	a1L
			beq	:103

			ldy	a1L
			lda	SekPerTrack,y
			asl
			clc
			adc	SekPerTrack,y
			clc
			adc	a0L
			sta	a0L
			bcc	:102
			inc	a0H
::102			inc	a1L
			bne	:101

::103			lda	#$00
			sta	a1L
			pla
			tax
::104			cpx	a1L
			beq	:106

			lda	a0L
			clc
			adc	#$03
			sta	a0L
			bcc	:105
			inc	a0H
::105			inc	a1L
			bne	:104
::106			rts

;*** Sektor einlesen.
:GetSektor		ldy	#$00
			lda	(a0L),y
			sta	r1L
			iny
			lda	(a0L),y
			sta	r1H
			iny
			lda	(a0L),y
			pha
			lda	#$00
			pha
			LoadW	r4,fileHeader
::101			jsr	ReadBlock
			pla
			tay
			pla
			tax
::102			lda	fileHeader,x
			sta	(r15L),y
			iny
			beq	:103
			inx
			bne	:102

			lda	fileHeader +1
			sta	r1H
			lda	fileHeader +0
			sta	r1L
			beq	:103

			lda	#$02
			pha
			tya
			pha
			jmp	:101
::103			rts

;*** Zeiger auf nächsten Sektor berechnen.
:SetNextSek		inc	a3H
			ldx	a3L
			lda	SekPerTrack,x
			cmp	a3H
			bne	:101

			lda	#$00
			sta	a3H
			inc	a3L
			lda	a3L
			cmp	#36
			bne	:101
			lda	#$ff
			rts
::101			lda	#$00
			rts

;*** Variablen für D64.
:SekPerTrack		b 00,21,21,21,21,21,21,21
			b 21,21,21,21,21,21,21,21
			b 21,21,19,19,19,19,19,19
			b 19,18,18,18,18,18,18,17
			b 17,17,17,17,17,17,17,17
			b 17
