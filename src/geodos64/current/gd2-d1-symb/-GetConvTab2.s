; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Übersetzungstabelle einlesen.
:LoadConvTab		sta	:107 +1
			stx	:110 +1
			sty	:111 +1

			cmp	#00
			bne	:103

;*** 1:1 Tabelle erzeugen.
::101			stx	r7L
			sty	r7H

			ldy	#$00
::102			tya
			sta	(r7L),y
			iny
			bne	:102
			rts

::103			jsr	OpenSysDrive

			LoadW	r6 ,V174a0
			LoadB	r7L,SYSTEM
			LoadB	r7H,$01
			LoadW	r10,V174a1
			jsr	FindFTypes
			txa
			bne	:105

			lda	r7H
			beq	:106

			lda	#$05
::105			pha
			jsr	OpenUsrDrive
			pla
			tax
			jmp	DiskError

::106			LoadW	r0,V174a0
			jsr	OpenRecordFile
			txa
			bne	:105

::107			lda	#$ff
			clc
			adc	#$01
			jsr	PointRecord
			txa
			beq	:109
::108			pha
			jsr	CloseRecordFile
			pla
			jmp	:105

::109			LoadW	r2,256

::110			lda	#$ff
			sta	r7L
::111			lda	#$ff
			sta	r7H
			jsr	ReadRecord
			txa
			bne	:108

			jsr	CloseRecordFile
			txa
			bne	:105

			jmp	OpenUsrDrive

;*** Variablen.
:V174a0			s 17
:V174a1			b "GD_Convert  ",NULL
