; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Partitionseintrag einlesen.
;*** Übergabe:		r15L	= Bankadresse für MMU-Register
;				 %01001110 (Bank 1) oder %00001110 (Bank 0) Transfer
;			Bank für 128er Transfer (0 oder 1) wird berechnet
:GetRLPartEntry		PushB	r1L
			PushB	r1H
			PushW	r4

			lda	#$01
			sta	r1L
			lda	r3H
			pha
			lsr
			lsr
			lsr
			sta	r1H
			LoadW	r4,fileHeader
			LoadB	r3H,$ff
			jsr	RL_GetBlock
			pla
			sta	r3H

			asl
			asl
			asl
			asl
			asl
			tay
			ldx	#$00
::51			lda	fileHeader +2,y
			sta	dirEntryBuf  ,x
			iny
			inx
			cpx	#$1e
			bcc	:51

			lda	dirEntryBuf		;Partitionsformat in Tabelle
			beq	:52			;übertragen.
			cmp	#$05
			bcs	:52
			sec				;CMD-Emulationsmodus nach
			sbc	#$01			;GEOS-Format wandeln.
			bne	:52
			lda	#$04
::52			sta	dirEntryBuf

			PopW	r4
			PopB	r1H
			PopB	r1L
			rts

;*** Sektor über Partitions-Register einlesen.
;    Übergabe:		r1   = Track/Sektor.
;			r3H  = Partitions-Nr.
;			r4   = Sektorspeicher.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:RL_GetBlock		ldy	#$80
			b $2c
:RL_PutBlock		ldy	#$90
			b $2c
:RL_VerBlock		ldy	#$a0
			b $2c
:RL_SwapBlock		ldy	#$b0

			php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			lda	CPU_DATA		;CPU Register einlesen und
			pha				;zwischenspeichern.
			lda	#KRNL_IO_IN		;I/O-Bereich und Kernel für
			sta	CPU_DATA		;RAMLink-Transfer aktivieren.

			jsr	EN_SET_REC		;RL-Hardware aktivieren.

			sty	$de20
			lda	r1L
			sta	$de21
			lda	r1H
			sta	$de22
			lda	r4L
			sta	$de23
			lda	r4H
			sta	$de24
			lda	r3H
			sta	$de25
;--- Ergänzung: 07.02.21/M.Kanet
;Für GD3 nicht erforderlich, da keine
;Unterstützung für GEOS128.
;			lda	r15L			;Bank für C128 berechnen.
;			lsr				;(Bit 6 ist relevant)
;			lsr
;			lsr
;			lsr
;			lsr
;			lsr
;			sta	$de26

			jsr	EXEC_REC_SEC		;Sektor-Jobcode ausführen.

			ldx	$de20			;Fehlerstatus einlesen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp				;IRQ-Status zurücksetzen.
::51			rts
