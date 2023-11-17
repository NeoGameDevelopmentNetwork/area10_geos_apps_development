; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DeskTop-Datei suchen.
;Disk-/Laufwerkswechsel möglich.
:findFile_System	lda	#SYSTEM
			b $2c

;*** Application suchen.
;Disk-/Laufwerkswechsel nur bei zwei Laufwerken möglich.
:findFile_Appl		lda	#APPLICATION
			sta	r7L

			jsr	findUserFile
			txa
			bne	:1

			lda	buf_TempName
			bne	:found

::1			jsr	checkForOtherDrv
			txa				;Keine Suche auf
			bne	:error			;Anderem Laufwerk...

			ldy	numDrives		;Sonderbehandlung
			dey				;für SYSTEM-Datei.
			beq	:test_ramdisk

;--- Laufwerk wechseln.
			jsr	swapCurDrive

;--- Datei erneut suchen.
::search		jsr	findUserFile
			txa
			bne	:test_ramdisk

			lda	buf_TempName
			bne	:found

;--- Datei nicht gefunden.
::test_ramdisk		lda	flagEnablSwapDk
			bne	:cancel			;Kein Diskwechsel.

			jsr	get_DrvY_TypeA
			bpl	:dbSwapDk		;Keine RAMDisk.

			lda	r7L
			cmp	#SYSTEM			;System-Datei?
			beq	:resetDrv		; => Ja, Diskwechsel.

::error			ldy	#ERR_OTHERDSK
			jsr	openMsgDlgBox
			clv
			bvc	:cancel			; => Abbruch...

;--- Zurück zum ersten Laufwerk.
::resetDrv		jsr	swapCurDrive

;--- Andere Diskette einlegen.
::dbSwapDk		ldy	curDrive
			ldx	#r5L
			jsr	setVecDrvTitle

			lda	r7L			;GEOS-Dateityp
			pha				;zwischenspeichern.
			lda	r10H			;GEOS-Klasse
			pha				;zwischenspeichern.
			lda	r10L
			pha
			ldx	#> dbox_SwapDisk
			lda	#< dbox_SwapDisk
			jsr	openDlgBox
			pla
			sta	r10L
			pla
			sta	r10H
			pla
			sta	r7L

			lda	r0L
			cmp	#OK			;OK?
			beq	:search			; => Weitersuchen...

;--- Abbruch...
::cancel		ldx	#CANCEL_ERR

;--- Datei gefunden.
::found			ldy	#$00
			sty	flagEnablSwapDk
			rts

;*** Testen ob Laufwerk gewechselt werden kann.
;Rückgabe: X = $00: Laufwerkswechsel möglich.
;              $ff: Laufwerkswechsel nicht möglich.
:checkForOtherDrv	ldx	#$00

			lda	r7L
			cmp	#SYSTEM
			beq	:ok

			lda	ramExpSize
			bne	:ok

			ldy	numDrives
			dey
			beq	:fail

			lda	driveType +0
			cmp	driveType +1
			beq	:ok

::fail			dex

::ok			rts

;*** Dialogbox: Diskette wechseln.
:dbox_SwapDisk		b %10000001
			b DBTXTSTR,$10,$10
			w dbtxGetDiskWith
			b DBVARSTR,$10,$20
			b r10L
			b DBTXTSTR,$10,$30
			w txString_In
			b DBVARSTR,$1c,$30
			b r5L
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL
