; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei-Mehrfach-Operation ausführen.
.execBatchJob		bit	a2H			;Dateiwahl aktiv?
			bpl	:done			; => Nein, Ende...

			sta	:job +1
			stx	:job +2
			jsr	disableFileDnD

			lda	mouseYPos
			sta	bufMouseYPos

			lda	mouseXPos +1
			sta	bufMouseXPos +1
			lda	mouseXPos +0
			sta	bufMouseXPos +0

			lda	#$ff			;Job-Status
			sta	batchStatus		;initialisieren.

			lda	a6L			;Auswahl-Zähler.
::nextjob		inc	batchStatus		;Job aktiv.
			tax
			cpx	#$ff			;Auswahl-Ende?
			beq	:done			; => Ja, Ende...

			dex
			txa
			pha				;Auswahl-Icon suchen.
			jsr	findFirstFSlct

			lda	r0H
			pha
			lda	r0L
			pha
			lda	r1H
			pha
			lda	r1L
			pha

;--- Mauszeiger zurücksetzen ?
			lda	flagKeepMsePos
			beq	:1			; => Nein, weiter...

			lda	bufMouseYPos
			sta	mouseYPos

			lda	bufMouseXPos +1
			sta	mouseXPos +1
			lda	bufMouseXPos +0
			sta	mouseXPos +0

::1			jsr	MouseOff		;Mauszeiger aus.

			lda	a3L
::job			jsr	$0000			;Batch-Job ausführen.

			jsr	MouseUp			;Mauszeiger ein.

			pla
			sta	r1L
			pla
			sta	r1H
			pla
			sta	r0L
			pla
			sta	r0H

			cpx	#$ff			;Abbruch?
			bne	:testerr		; => Nein, weiter...

			jsr	unselectIcons
			pla

::done			ldx	#NO_ERROR
			rts

::testerr		cpx	#NO_ERROR
			beq	:testabort
			cpx	#CANCEL_ERR
			bne	:err

			jsr	unselectJobIcon

::testabort		jsr	chkStopKey
			beq	:abort

			pla
			clv
			bvc	:nextjob

::abort			jsr	unselectIcons
			jsr	testCurDiskReady

::err			pla
			rts
