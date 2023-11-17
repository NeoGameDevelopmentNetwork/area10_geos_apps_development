; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Gewählte Datei öffnen.
;Übergabe: A  = GEOS-Dateityp.
;          a5 = Zeiger auf Directory-Eintrag.
:openFileSelected	pha

			ldy	#30 -1
::1			lda	(a5L),y
			sta	dirEntryBuf,y
			dey
			bpl	:1
			jsr	r9_dirEntryBuf

			pla
			cmp	#DATA			;0-2?
			bcc	openFileBASIC		; => Ja, weiter...

;--- GEOS-Programm starten.
::geos			cmp	#DESK_ACC
			bne	:2
			jmp	openFileDeskAcc

::2			cmp	#APPLICATION
			beq	:3
			cmp	#AUTO_EXEC
			bne	:4
::3			jmp	openFileApplic

::4			cmp	#APPL_DATA
			bne	openFileError
			jmp	openFileApplData

:openFileError		lda	#$00
			sta	flagTestTgtDrv
			ldy	#ERR_OPENFILE
			jsr	openMsgDlgBox
			jmp	unselectJobIcon

;--- BASIC-Programm starten.
:openFileBASIC		ldy	#$00
			lda	(r9L),y
			and	#%00001111
			cmp	#PRG
			bne	openFileError
			jsr	startFileBASIC
			cpx	#STRUCT_MISMAT
			beq	openFileError
			jmp	openErrBox1Line

:openFileApplic		lda	#> EnterDeskTop -1
			pha
			lda	#< EnterDeskTop -1
			pha
			jsr	resetScreen
:APPRAM_1B		jsr	clearAppRAM
			lda	#$00
			sta	r0L
			jmp	LdApplic

;*** Speicherbereiche löschen.
:tabClrAdr_H		b > APPRAM_1A
			b > APPRAM_2A
:tabClrAdr_L		b < APPRAM_1A
			b < APPRAM_2A
:tabClrSize_H		b > APPRAM_1B - APPRAM_1A
			b > OS_BASE   - APPRAM_2A
:tabClrSize_L		b < APPRAM_1B - APPRAM_1A
			b < OS_BASE   - APPRAM_2A

;*** APP_RAM für GetFile/LdApplic löschen.
:clearAppRAM		lda	r2L
			pha
			ldx	#$01
::1			lda	tabClrAdr_H,x
			sta	r1H
			lda	tabClrAdr_L,x
			sta	r1L
			lda	tabClrSize_H,x
			sta	r0H
			lda	tabClrSize_L,x
			sta	r0L
			jsr	ClearRam
			dex
			bpl	:1
			pla
			sta	r2L
			stx	DEBUG1 +2
			rts

;*** Dokument öffnen.
:openFileApplData	lda	#%10000000		;Datenfile nachladen.

;*** Dokument drucken.
.prntFileApplData	sta	flagTempData

			lda	r9L
			clc
			adc	#$03
			sta	r4L
			lda	r9H
			adc	#$00
			sta	r4H
			jsr	r3_bufTempStr1

			ldx	#r4L
			ldy	#r3L
			jsr	copyNameA0_16
			jsr	r2_bufTempStr0

			ldx	#r4L
			jsr	setVecOpenDkNm
			ldx	#r4L
			ldy	#r2L
			lda	#18
			jsr	CopyFString

			ldy	#$13			;Infoblock einlesen.
			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
			jsr	getDiskBlock
			txa
			beq	:1

::errorOpenDoc		jsr	openErrBox1Line
::cancelOpenDoc		jmp	cancelBack2DTop

::1			lda	diskBlkBuf +$75
			bne	:2			; => Anwendung OK.
			jmp	openFileError

::2			lda	#> diskBlkBuf +$75
			sta	r1H
			lda	#< diskBlkBuf +$75
			sta	r1L
			lda	#> buf_TempStr2
			sta	r10H
			lda	#< buf_TempStr2
			sta	r10L
			ldx	#r1L
			ldy	#r10L
			lda	#12
			jsr	copyNameA0_a
			jsr	findFile_Appl
			cpx	#CANCEL_ERR
			beq	:cancelOpenDoc
			txa
			bne	:errorOpenDoc

			lda	buf_TempName
			beq	:cancelOpenDoc

			jsr	resetScreen
			jsr	r2_bufTempStr0
;--- Hinweis:
;Das Highbyte der Adresse im JSR-
;Aufruf hinter DEBUG1 wird durch die
;Routine ":clearAppRAM" auf $ff
;gesetzt, aber danach wird nicht mehr
;zur Routine zurückgekehrt. Debugging?
:DEBUG1			jsr	r3_bufTempStr1
			jsr	r6_buf_TempName
			jsr	clearAppRAM

			lda	flagTempData
			sta	r0L

			lda	#> EnterDeskTop -1
			pha
			lda	#< EnterDeskTop -1
			pha
			jmp	GetFile

:flagTempData		b $00
