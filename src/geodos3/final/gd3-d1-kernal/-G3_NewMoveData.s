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
::51			lda	(returnAddress),y	;inline-MoveData-Werte nach
			sta	r0           -1,y	;r0-r2 kopieren.
			dey
			bne	:51
			jsr	xMoveData		;MoveData ausführen.
			jmp	Exit7ByteInline		;Rücksprungadresse korrigieren.

;*** Speicherbereich veschieben.
:xMoveData		txa				;XReg sichern. MoveData ändert
			pha				;nur AKKU/YReg!

			lda	r2L
			ora	r2H			;Anzahl Bytes = $0000 ?
			beq	:107			;Ja, -> Keine Funktion.

;--- Ergänzung: 27.10.18/M.Kanet
;Hier wurden nur die Register r0L bis r2H gesichert. Bei aktiviertem
;MoveData für die C=REU wird aber auch das Register r3L verändert.
;Das führt u.a. bei geoPaint zu einem Absturz wenn der Bildschirm-Ausschnitt
;verschoben werden soll da hier r3L als Zähler verwendet wird.
			ldx	#$07			;Register r0L bis r3L sichern.
::100			lda	r0L -1,x		;r3L wird bei REU-MoveData
			pha				;verwendet!
			dex
			bne	:100

			lda	sysRAMFlg		;MoveData über REU ?
			bpl	:101			;Nein, weiter...

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
;			jmp	:106			;Ende ":MoveData".

;*** Ende ":MoveData", Register wiederherstellen.
;--- Ergänzung: 27.10.18/M.Kanet
;Register r0L bis r2H und r3L(wegen REU-MoveData) wieder herstellen.
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

;*** ":MoveData" (Daten Aufwärts/Abwärts kopieren).
::101			lda	r0H
			cmp	r1H
			bne	:102
			lda	r0L
			cmp	r1L
::102			bcc	:108			; -> Daten Abwärts kopieren.

;*** ":MoveData" (Daten Aufwärts kopieren).
::103			ldy	#$00
			lda	r2H
			beq	:105
::104			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:104
			inc	r0H
			inc	r1H
			dec	r2H
			bne	:104
::105			cpy	r2L
			beq	:106
			lda	(r0L),y
			sta	(r1L),y
			iny
			jmp	:105

;*** ":MoveData" (Daten Abwärts kopieren).
::108			clc
			lda	r2H
			adc	r0H
			sta	r0H
			clc
			lda	r2H
			adc	r1H
			sta	r1H
			ldy	r2L
			beq	:110
			jsr	:111
::110			dec	r0H
			dec	r1H
			lda	r2H
			beq	:106
			jsr	:111
			dec	r2H
			jmp	:110

;*** Einzelne Bytes kopieren.
::111			dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	:111
			rts
