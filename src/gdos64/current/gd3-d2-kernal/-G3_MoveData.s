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
::1			lda	(returnAddress),y	;inline-MoveData-Werte nach
			sta	r0           -1,y	;r0-r2 kopieren.
			dey
			bne	:1
			jsr	xMoveData		;MoveData ausführen.
			jmp	Exit7ByteInline		;Rücksprungadresse korrigieren.

;*** Speicherbereich veschieben.
:xMoveData		txa				;XReg sichern. MoveData ändert
			pha				;nur AKKU/YReg!

			lda	r2L
			ora	r2H			;Anzahl Bytes = $0000 ?
			beq	:exit			;Ja, -> Keine Funktion.

;--- Ergänzung: 27.10.18/M.Kanet
;Hier wurden bisher nur die Register
;r0L bis r2H gesichert. Bei aktiviertem
;MoveData für die C=REU wird aber auch
;das Register r3L verändert.
;Das führt u.a. bei geoPaint zu einem
;Absturz wenn der Bildschirm-Ausschnitt
;verschoben werden soll da hier r3L als
;Zähler verwendet wird.
			ldx	#3*2 +1 			;Register r0L bis r3L sichern.
::11			lda	r0L -1,x		;r3L wird bei REU-MoveData
			pha				;verwendet!
			dex
			bne	:11

			lda	sysRAMFlg		;MoveData über REU ?
			bpl	:kernal			; => Nein, weiter...

;--- Ergänzung: 11.12.22/M.Kanet:
;GEOS128 hat einen Test eingebaut, wenn
;mehr Daten verschoben werden sollen
;als Platz in der REU reserviert ist.
;Unter GEOS64 sind in der REU maximal
;$7900 Bytes für MoveData reserviert.
;Der Test ist allerdings in der Praxis
;nicht wirklich notwendig, da in dem
;Fall praktisch das gesamte APP_RAM
;verschoben werden müsste.
;			lda	r2H
;			cmp	#$79			;Mehr als $7900 Bytes kopieren?
;			bcs	:kernal			; => Ja, Kernal-Routine.

;--- Daten über REU/DMA verschieben.
::reudma		lda	r1H
			pha
;			ldx	#$00
			stx	r1H
			stx	r3L			;Speicherbereich aus RAM
			jsr	StashRAM		;in REU übertragen.
			pla
			sta	r0H
			lda	r1L
			sta	r0L			;Speicherbereich aus REU
			jsr	FetchRAM		;in RAM zurückschreiben.
;			jmp	:done			;Ende ":MoveData".

;--- Ende ":MoveData", Register wiederherstellen.
;
;--- Ergänzung: 27.10.18/M.Kanet
;Register r0L bis r3L (wegen REU-
;MoveData) wieder herstellen.
::done			ldx	#0
::12			pla
			sta	r0L,x
			inx
			cpx	#3*2 +1			;r0,r1,r2,r3L...
			bcc	:12

;--- Ergänzung: 23.09.18/M.Kanet.
;MoveData darf das XReg nicht verändern,
;da auch die Original-Routine das XReg
;unverändert lässt!
::exit			pla
			tax
			rts

;--- Kernal: Daten aufwärts/abwärts kopieren?
::kernal		lda	r0H
			cmp	r1H
			bne	:21
			lda	r0L
			cmp	r1L
::21			bcc	:mvDown			; -> Daten Abwärts kopieren.

;--- Kernal: Daten aufwärts kopieren.
::mvUp			ldy	#$00
			lda	r2H
			beq	:32
::31			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:31
			inc	r0H
			inc	r1H
			dec	r2H
			bne	:31
::32			cpy	r2L
			beq	:done
			lda	(r0L),y
			sta	(r1L),y
			iny
			jmp	:32

;--- Kernal: Daten abwärts kopieren.
::mvDown		clc
			lda	r2H
			adc	r0H
			sta	r0H
			clc
			lda	r2H
			adc	r1H
			sta	r1H
			ldy	r2L
			beq	:41
			jsr	:mvByt
::41			dec	r0H
			dec	r1H
			lda	r2H
			beq	:done
			jsr	:mvByt
			dec	r2H
			jmp	:41

;--- Kernal: Einzelne Bytes kopieren.
::mvByt			dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	:mvByt
			rts
