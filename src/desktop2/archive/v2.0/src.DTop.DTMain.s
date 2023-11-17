; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DeskTop/MainInit.
;.MainInit		;In src.DeskTop definiert.

			ldx	#$48
			lda	#$00
::1			sta	bufOpenDiskNm -1,x
			dex
			bne	:1

			lda	#$00
			ldy	#3
::2			sta	a0,y
			dey
			bpl	:2

			ldy	#15
::3			sta	a2,y
			dey
			bpl	:3

			sta	iconSelFlag
			sta	flagFileCopy
			sta	flagLockMseDrv
			sta	flagDrivesRdy
			sta	flagKeepMsePos
			sta	flagDriverReady
			lda	#$ff			;Diskette gültig.
			sta	flagDiskRdy
			sta	flagBootDT

			jsr	clearVarBuf1

			lda	#> initGEOSVar
			sta	r0H
			lda	#< initGEOSVar
			sta	r0L
			jsr	InitRam
			jsr	clearScreen

			jsr	isGEOS_V2
			bcs	:4
			jsr	errIncompatible

::4			lda	#> dm_MainMenu
			sta	r0H
			lda	#< dm_MainMenu
			sta	r0L
			lda	#$02
			jsr	DoMenu

			jsr	resetIconMenu
			jsr	initDTopClock

			jsr	initDriveConfig
			cpx	#$21
			bne	:5
			jsr	closeCurDisk

::5			jsr	chkErrRestartDT

			lda	#$ff
			sta	flagEnablSwapDk
			jsr	loadDTopMod1
			rts

;*** Zwischenspeicher löschen.
:clearVarBuf1		ldx	#$90
			lda	#$00
::1			sta	tabBIconDkNm -1,x
			dex
			bne	:1

			ldx	#$ff
			lda	#$00
::2			sta	tabBIconDEntry -1,x
			dex
			bne	:2
			rts

;*** Initialisierungstabelle.
:initGEOSVar		w otherPressVec
			b $02
			w u_otherPressVec

			w appMain
			b $02
			w u_appMain

			w keyVector
			b $02
			w u_keyVector

			w numDrives
			b $01
			b $01

			w dispBufferOn
			b $01
			b ST_WR_FORE

			w RecoverVector
			b $02
			w u_RecoverVec

			w NULL
