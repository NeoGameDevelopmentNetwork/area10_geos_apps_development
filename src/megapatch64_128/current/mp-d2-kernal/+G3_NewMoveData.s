; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Inline: Speicher verschieben.
:xi_MoveData		pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1

			ldy	#$06
::51			lda	(returnAddress)   ,y
			sta	r0              -1,y
			dey
			bne	:51
			jsr	xMoveData
			jmp	Exit7ByteInline

;*** Speicherbereich veschieben.
:xMoveData		txa				;XReg sichern. MoveData ändert
			pha				;nur AKKU/YReg!

			lda	r2L
			ora	r2H			;Anzahl Bytes = $0000 ?
			beq	:107			;Ja, -> Keine Funktion.

;--- Ergänzung: 28.05.20/M.Kanet
;Hier wurden nur die Register r0L bis r2H gesichert. Bei aktiviertem
;MoveData für die C=REU wird aber auch das Register r3L verändert.
;Fix von MegaPatch64 übernommen um Probleme mit DualTop128 zu beheben.
			ldx	#$07			;Register r0L bis r3L sichern.
::100			lda	r0L -1,x
			pha
			dex
			bne	:100

			lda	sysRAMFlg		;MoveData über REU ?
			bpl	:101			;Nein, weiter...

;Mehr als $38ff Bytes verschieben? Abfrage da beim 128er im Bereich von
;$3900 bis $78ff in der REU Bank0 gespeichert wird
			lda	r2H
			cmp	#$38
			beq	:1			; => nein
			bcs	:101			; => ja
::1			lda	r0H			;Startbereich unter $0200 ?
			cmp	#$02
			bcc	:101			; => ja
			lda	r1H			;Zielbereich unter $0200 ?
			cmp	#$02
			bcc	:101			; => ja

			lda	r1H
			pha
			stx	r1H
			stx	r3L			;Speicherbereich aus RAM
			jsr	StashRAM		;in REU übertragen.
			pla
			sta	r0H
			lda	r1L
			sta	r0L			;Speicherbereich aus REU
			jsr	FetchRAM		;in RAM zurückschreiben.
			jmp	:106			;Ende ":MoveData".

::101			jsr	c128_MoveData		;MoveData in Bank0 C128!

;*** Ende ":MoveData", Register wiederherstellen.
;--- Ergänzung: 28.05.20/M.Kanet
;Register r0L bis r2H und r3L wieder herstellen.
::106			ldx	#$00
::106a			pla
			sta	r0L,x
			inx
			cpx	#$07
			bcc	:106a

;--- Ergänzung: 23.09.18/M.Kanet.
;MoveData darf das XReg nicht verändern, da auch die Original-Routine
;das XReg unverändert lässt!
::107			pla
			tax
			rts
