; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeiger auf Fehlertexte.
:tabTxLine1H		b > dbtxGetDiskWith
			b > txErrMaxBorder1
			b > txErrOpenFile1
			b > dbtxNoDkCopy1
			b > dbtxMultiFile1
			b > txErrPrintFile1
			b > txErrOtherDisk1

:tabTxLine1L		b < dbtxGetDiskWith
			b < txErrMaxBorder1
			b < txErrOpenFile1
			b < dbtxNoDkCopy1
			b < dbtxMultiFile1
			b < txErrPrintFile1
			b < txErrOtherDisk1

:tabTxLine2H		b > classDeskTop
			b > txErrMaxBorder2
			b > txErrOpenFile2
			b > dbtxNoDkCopy2
			b > dbtxMultiFile2
			b > txErrPrintFile2
			b > txErrOtherDisk2

:tabTxLine2L		b < classDeskTop
			b < txErrMaxBorder2
			b < txErrOpenFile2
			b < dbtxNoDkCopy2
			b < dbtxMultiFile2
			b < txErrPrintFile2
			b < txErrOtherDisk2

;*** Hinweisbox öffnen.
.openMsgDlgBox		lda	tabTxLine1L,y
			sta	r5L
			lda	tabTxLine1H,y
			sta	r5H
			lda	tabTxLine2L,y
			sta	r6L
			lda	tabTxLine2H,y
			sta	r6H

.openMsgDBox_r5r6	ldx	#> dbox_Message
			lda	#< dbox_Message

;*** Dialogbox öffnen.
.openDlgBox		stx	r0H
			sta	r0L

			lda	r5H
			pha
			lda	r5L
			pha
			lda	r6H
			pha
			lda	r6L
			pha
			lda	r7H
			pha
			lda	r7L
			pha

;--- DeskTop-Recover aktiv?
			jsr	testUsrRecVec
			beq	:1

;--- Ja, Bildschirmbereich Dialogbox sichern.
			ldx	#$00
			jsr	putScreenToBuf

::1			lda	$8e88			;Bei einer Dialogbox
			pha				;Color-Card links/
			lda	$8cc0			;unten und rechts/
			pha				;oben speichern.

			lda	#> $0008		;Farbrechteck für
			sta	r3H			;Dialogbox setzen.
			lda	#< $0008		;Achtung!
			sta	r3L			;Farbe für Dialogbox
			lda	#> $0020		;inkl. Schatten!
			sta	r4H
			lda	#< $0020
			sta	r4L
			lda	#$04
			sta	r2L
			lda	#$10
			sta	r2H

			lda	screencolors
			sta	r6L
			jsr	cardUsrColRec

			pla				;Von Dialogbox nicht
			sta	$8cc0			;genutzte Color-Cards
			pla				;wieder zurücksetzen.
			sta	$8e88

			pla
			sta	r7L
			pla
			sta	r7H
			pla
			sta	r6L
			pla
			sta	r6H
			pla
			sta	r5L
			pla
			sta	r5H

			jsr	DoDlgBox

;--- DeskTop-Recover aktiv?
			jsr	testUsrRecVec
			bne	:2

;--- Nein, nur DeskPad-Farben zurücksetzen.
			jsr	drawDeskPadCol

::2			lda	r0L			;Ergebnis Dialogbox.
			rts

;*** Testen ob eigene RecoverRectangle-Routine aktiv ist.
:testUsrRecVec		ldx	#$ff
			lda	RecoverVector +0
			cmp	#< u_RecoverVec
			bne	:1
			lda	RecoverVector +1
			cmp	#> u_RecoverVec
			beq	:2
::1			ldx	#$00
::2			txa
			rts

;*** Dialogbox: Hinweistext ausgeben.
:dbox_Message		b %10000001
			b DBVARSTR
			b $10,$20,r5L
			b DBVARSTR
			b $10,$30,r6L
			b OK
			b $11,$48
			b NULL
