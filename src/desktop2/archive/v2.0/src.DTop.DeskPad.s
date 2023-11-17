; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Position Status-Info.
;:AREA_DSKSTAT_X0	= $0009
if LANG = LANG_DE
:DSKSTAT_TX1		= AREA_DSKSTAT_X0 +7
:DSKSTAT_TX2		= AREA_DSKSTAT_X0 +77
:DSKSTAT_TX3		= AREA_DSKSTAT_X0 +129
:DSKSTAT_TX4		= AREA_DSKSTAT_X0 +198
endif
if LANG = LANG_EN
:DSKSTAT_TX1		= AREA_DSKSTAT_X0 +7
:DSKSTAT_TX2		= AREA_DSKSTAT_X0 +57
:DSKSTAT_TX3		= AREA_DSKSTAT_X0 +104
:DSKSTAT_TX4		= AREA_DSKSTAT_X0 +183
endif

;*** DeskPad zeichnen.
:openDeskPad		jsr	drawEmptyDeskPad
			jsr	loadDirectory
			jsr	exitOnDiskErr

			ldy	curDrive
			lda	driveType -8,y
			and	#ST_DTYPES
			cmp	#Drv1541
			bne	:analyze

			ldx	#DBLSIDED_DISK
			bit	curDirHead +3
			bmi	:exit

::analyze		jsr	analyzeDirFiles

			lda	r9H			;Temporary/SwapFile?
			beq	:1			; => Nein, weiter...

			jsr	delTempFile		;Temporary/SwapFile
			clv				;löschen.
			bvc	:analyze

::1			jsr	getCurDkPrnDkNm
			jsr	loadIconsCurPage
			jsr	exitOnDiskErr

			jsr	prntCurDiskInfo

			ldx	#NO_ERROR
::exit			rts

;*** Leeres DeskPad zeichnen.
.drawEmptyDeskPad	jsr	i_GraphicsString

			b NEWPATTERN
			b PAT_DESKPAD

			b MOVEPENTO
			w AREA_FULLPAD_X0
			b AREA_FULLPAD_Y0
			b RECTANGLETO
			w AREA_FULLPAD_X1
			b AREA_FULLPAD_Y1
			b FRAME_RECTO
			w AREA_FULLPAD_X0
			b AREA_FULLPAD_Y0

			b MOVEPENTO
			w AREA_DSKSTAT_X0 -1
			b AREA_DSKSTAT_Y0 -1
			b LINETO
			w AREA_DSKSTAT_X1 +1
			b AREA_DSKSTAT_Y0 -1

			b MOVEPENTO
			w AREA_DSKSTAT_X0 -1
			b AREA_DSKSTAT_Y1 +1
			b LINETO
			w AREA_DSKSTAT_X1 +1
			b AREA_DSKSTAT_Y1 +1

			b MOVEPENTO
			w AREA_FULLPAD_X0
			b AREA_FULLPAD_Y1 -4
			b LINETO
			w AREA_FULLPAD_X1
			b AREA_FULLPAD_Y1 -4

			b MOVEPENTO
			w AREA_FULLPAD_X0
			b AREA_FULLPAD_Y1 -2
			b LINETO
			w AREA_FULLPAD_X1
			b AREA_FULLPAD_Y1 -2

			b NEWPATTERN
			b PAT_TITLE

			b MOVEPENTO
			w AREA_DSKNAME_X0
			b AREA_DSKNAME_Y0
			b RECTANGLETO
			w AREA_DSKNAME_X1
			b AREA_DSKNAME_Y1

			b NULL

			jmp	drawDeskPadCol

;*** Name für Druckerdiskette / Aktuelle Diskette einlesen.
:getCurDkPrnDkNm	lda	#> curDirHead +$90
			sta	r0H
			lda	#< curDirHead +$90
			sta	r0L

			ldx	#r1L
			jsr	setVecOpenDkNm
			jsr	copyStr_r0_r1

			ldx	#r1L
			jsr	setVecDkNmBuf

:copyStr_r0_r1		ldx	#r0L
			ldy	#r1L
			lda	#18
			jmp	CopyFString

;*** Diskname+Status ausgeben.
:prntCurDiskInfo	jsr	setPattern0
			jsr	i_Rectangle
			b AREA_DSKSTAT_Y0,AREA_DSKSTAT_Y1
			w AREA_DSKSTAT_X0,AREA_DSKSTAT_X1

;--- Diskname ausgeben.
			ldx	#> curDirHead +$90
			lda	#< curDirHead +$90
			jsr	copyIconTitle

			jsr	r0_buf_TempName
			lda	#> AREA_FULLPAD_X0 +FULLPAD_CX
			sta	r11H
			lda	#< AREA_FULLPAD_X0 +FULLPAD_CX
			sta	r11L
			lda	# AREA_DSKNAME_Y0 +7
			sta	r1H
			jsr	prntCenterText

			jsr	prntStatFiles

			jsr	getUsedBlocks

			ldy	#2			;Kb belegt.
			ldx	#r0L
			jsr	DShiftRight

			lda	#> DSKSTAT_TX3
			sta	r11H
			lda	#< DSKSTAT_TX3
			sta	r11L
			jsr	putDecimalLeft

			ldx	#> textUsedKb
			lda	#< textUsedKb
			jsr	putStringAX

			jsr	getUsedBlocks

			lda	r4H			;Kb frei.
			lsr
			ror	r4L
			lsr
			ror	r4L
			sta	r0H
			lda	r4L
			sta	r0L

			lda	#> DSKSTAT_TX4
			sta	r11H
			lda	#< DSKSTAT_TX4
			sta	r11L
			jsr	putDecimalLeft

			ldx	#> textFreeKb
			lda	#< textFreeKb
			jsr	putStringAX

			ldx	#r0L
			jsr	setVecDkNmBuf
			jsr	getIconNumCurDrv

			ldx	#%11000000
			stx	r1L
			jmp	updDriveIcons

;*** Anzahl belegter Blöcke ermitteln.
;Rückgabe: r0 = Anzahl belegter Blocks.
:getUsedBlocks		lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L
			jsr	CalcBlksFree

			lda	r3L
			sec
			sbc	r4L
			sta	r0L
			lda	r3H
			sbc	r4H
			sta	r0H
			rts

;*** Zahl linksbündig ausgeben.
;Übergabe: r0  = 16Bit-Zahl.
;          r11 = X-Koordinate.
;          r1H = Y-Koordinate.
:putDecimalLeft		lda	#SET_LEFTJUST ! SET_SUPRESS
			jmp	PutDecimal

;*** Anzahl Dateien ausgeben.
:prntStatFiles		jsr	analyzeDirFiles

			lda	r0L			;Anzahl Dateien.
			pha
			pla
			sta	r0L
			sta	a7H
			lda	#$00
			sta	r0H

			lda	#> DSKSTAT_TX1
			sta	r11H
			lda	#< DSKSTAT_TX1
			sta	r11L
			lda	# AREA_DSKSTAT_Y0 +7
			sta	r1H

			jsr	putDecimalLeft

			ldx	#> textFileCount
			lda	#< textFileCount
			jsr	putStringAX

;--- Dateien gewählt.
			lda	#> DSKSTAT_TX2
			sta	r11H
			lda	#< DSKSTAT_TX2
			sta	r11L

			ldx	#> textSlctCount
			lda	#< textSlctCount
			jsr	putStringAX

;*** Anzahl gewählte Dateien ausgeben.
:prntStatSlctFile	lda	r0H
			pha
			lda	r0L
			pha
			lda	r1L
			pha

			lda	#> DSKSTAT_TX2 -13
			sta	r11H
			lda	#< DSKSTAT_TX2 -13
			sta	r11L
			lda	# AREA_DSKSTAT_Y0 +7
			sta	r1H

			jsr	printSpace
			jsr	printSpace

			lda	#> DSKSTAT_TX2 -36
			sta	r11H
			lda	#< DSKSTAT_TX2 -36
			sta	r11L

			lda	a6L
			bit	a2H			;Dateiwahl aktiv?
			bpl	:1			; => Nein, weiter...
			clc
			adc	#$01
::1			sta	r0L
			lda	#$00
			sta	r0H

			lda	#36 ! SET_RIGHTJUST ! SET_SUPRESS
			jsr	PutDecimal

			pla
			sta	r1L
			pla
			sta	r0L
			pla
			sta	r0H
			rts

;*** Leerzeichen ausgeben.
;Übergabe: r11 = X-Koordinate.
;          r1H = Y-Koordinate.
:printSpace		lda	#" "
			jmp	PutChar
