; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Alle Blocks einer Diskette kopieren.
:doDiskCopyJob		jsr	calcCopyBufSize

			lda	#$ff
			jsr	initFreeBlkData

::1			jsr	dcopyRdSrcData
			jsr	exitOnDiskErr

			jsr	setTargetDiskDrv
			jsr	exitOnDiskErr

			jsr	dcopyWrTgtData
			jsr	exitOnDiskErr

			lda	drvCurBlkTr
			cmp	drvMaxTracks
			beq	:2
			bcs	:3

::2			jsr	setSourceDiskDrv
			txa
			beq	:1

::exit			rts

;--- DiskCopy 1541 -> 1571: BAM korrigieren.
::3			lda	dvTypSource
			cmp	#Drv1541
			bne	:exit
			lda	dvTypTarget
			cmp	#Drv1571
			bne	:exit
			sta	dvTypSource

			jsr	GetDirHead
			jsr	exitOnDiskErr

			jsr	createNewBAM
			jmp	PutDirHead

;*** Anfangsadresse Kopierspeicher berechnen.
:calcCopyBufSize	lda	bufTempDataSize +1
			sta	r3H
			lda	bufTempDataSize +0
			sta	r3L

			lda	#> $0102		;256Byte Datenblock
			sta	r0H			;+2Byte Sek.Adresse.
			lda	#< $0102
			sta	r0L

			ldx	#r3L
			ldy	#r0L
			jsr	Ddiv

			lda	r3L
			sta	countLastByt

			asl	r3L			;2Byte Sek.Adresse
			rol	r3H			;für jeden Block.

			lda	bufTempDataVec +0
			clc				;Startadresse im
			adc	r3L			;Datenpuffer setzen.
			sta	bufTmpBlkDatVec +0
			lda	bufTempDataVec +1
			adc	r3H
			sta	bufTmpBlkDatVec +1
			rts

;*** Blocks von Quelldisk einlesen.
:dcopyRdSrcData		jsr	EnterTurbo
			jsr	exitOnDiskErr
			jsr	InitForIO

			jsr	initBlkDataVec

			lda	#$00
			sta	countBlocks

::1			lda	drvCurBlkTr
			sta	r1L
			cmp	drvMaxTracks
			beq	:2
			bcs	:ok

::2			lda	drvCurBlkSe
			sta	r1H
			jsr	move_r11_r4
			jsr	ReadBlock
			txa
			bne	:err

			ldy	#$00
			lda	r1L
			sta	(r10L),y
			iny
			lda	r1H
			sta	(r10L),y
			inc	countBlocks
			jsr	add_2_r10
			inc	r11H

			lda	#RAM_64K
			sta	CPU_DATA
			jsr	getFreeNextBlock
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			lda	countBlocks
			cmp	countLastByt
			bcc	:1

::ok			ldx	#NO_ERROR
::err			jmp	DoneWithIO

;*** Zeiger auf Kopierspeicher setzen.
;Rückgabe: r10 = Zeiger auf Sektor-Tabelle.
;          r11 = Zeiger auf Kopierspeicher.
:initBlkDataVec		lda	bufTempDataVec +1
			sta	r10H
			lda	bufTempDataVec +0
			sta	r10L

			lda	bufTmpBlkDatVec +1
			sta	r11H
			lda	bufTmpBlkDatVec +0
			sta	r11L

			rts

;*** Blocks auf Zieldisk schreiben.
:dcopyWrTgtData		jsr	EnterTurbo
			jsr	exitOnDiskErr

			stx	flagWriteVerify

			jsr	InitForIO

			lda	countBlocks
			pha
			jsr	:doJob			;Write Data...
			pla
			sta	countBlocks
			txa
			bne	:exit

			dec	flagWriteVerify
			jsr	:doJob			;Verify Data...

::exit			jmp	DoneWithIO

;--- Blöcke schreiben oder überprüfen.
::doJob			jsr	initBlkDataVec

::next			lda	countBlocks
			beq	:done

			ldy	#$00
			lda	(r10L),y
			sta	r1L
			iny
			lda	(r10L),y
			sta	r1H
			jsr	backupTgtDkNm
			jsr	exitOnDiskErr

			jsr	move_r11_r4

			lda	flagWriteVerify
			bne	:verify
::write			jsr	WriteBlock
			clv
			bvc	:testerr

::verify		jsr	VerWriteBlock

::testerr		jsr	exitOnDiskErr

			jsr	add_2_r10
			inc	r11H
			dec	countBlocks
			bne	:next

::done			ldx	#NO_ERROR
			rts

;*** Zeiger auf Kopierspeicher nach r4.
:move_r11_r4		lda	r11H
			sta	r4H
			lda	r11L
			sta	r4L
			rts

;*** Diskname übernehmen.
;Beim kopieren einer Diskette wird hier
;vor dem schreiben des BAM-Headers der
;Name der Zieldiskette eingelesen und
;in den Zwischenspeicher kopiert.
:backupTgtDkNm		lda	r1L			;Track $18 oder $40?
			cmp	drv1stDirTr
			bne	:ok			; => Nein, Ende...

;--- Bei Verify überspringen.
			lda	r1H			;Sektor $00?
			ora	flagWriteVerify
			bne	:ok			; => Nein, Ende...

;--- BAM-Header einlesen.
			jsr	r4_diskBlkBuf
			jsr	ReadBlock
			jsr	exitOnDiskErr

;--- BAM-Header für Ziel-Diskette vorbereiten.
			ldy	#$90			;Diskname kopieren.
			ldx	#20 -1
::1			lda	diskBlkBuf,y
			sta	(r11L),y
			iny
			dex
			bpl	:1

			ldy	#OFF_DISK_TYPE
			lda	#$00			;GEOS-Daten löschen:
			sta	(r11L),y		;Disk-Typ.
			iny
			sta	(r11L),y		;GEOS-Ser.No/Low.
			iny
			sta	(r11L),y		;GEOS-Ser.No/High.

::ok			ldx	#NO_ERROR
			rts
