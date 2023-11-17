; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskinhalt einlesen.
.loadDirectory		ldx	#$ff
			lda	#$00
::1			sta	buf_diskSek3 -1,x
			dex
			bne	:1

			lda	#> dirDiskBuf
			sta	r4H
			lda	#< dirDiskBuf
			sta	r4L

			jsr	get1stDirTrSe
			sty	r1H

			lda	#MAX_DIR_BLK
			sta	r2L
			jsr	readDir2DiskBuf
			jsr	exitOnDiskErr

			lda	#MAX_DIR_BLK -1
			sec
			sbc	r2L
			sta	a1L
			ldx	#NO_ERROR
			cmp	#10			;Anzahl Seiten <10 ?
			bcc	:unknown		; => Ja, weiter...

::unknown		lda	isGEOS			;GEOS-Diskette?
			beq	exit4			; => Nein, Ende...

			jsr	prepGetBorderB
			jmp	GetBlock		;Borderblock laden.

;*** Zeiger auf Borderblock setzen.
:prepGetBorderB		lda	#> buf_diskSek3
			sta	r4H
			lda	#< buf_diskSek3
			sta	r4L
			lda	curDirHead +$ac
			sta	r1H
			lda	curDirHead +$ab
			sta	r1L
:exit4			rts

;*** Zeiger auf ersten Verzeichnis-Sektor einlesen.
.get1stDirTrSe		lda	#$00
			sta	r1H
			jsr	testCurDrv1581
			bne	:is1581

::is1541_1571		lda	#$12
			sta	r1L
			ldy	#$01
			rts

::is1581		lda	#$28
			sta	r1L
			ldy	#$03
			rts

;*** Aktuelles Laufwerk auf 1581 testen.
;Rückgabe: Y=$ff/Z-Flag=0: 1581
;          Y=$00/Z-Flag=1: 1541/1571
.testCurDrv1581		ldy	curDrive
			lda	driveType -8,y
			and	#ST_DTYPES
			cmp	#Drv1581
			beq	:is1581

::no1581		ldy	#$00
			rts
::is1581		ldy	#$ff
			rts

;*** Directory in Speicher einlesen.
:readDir2DiskBuf	jsr	EnterTurbo
			txa
			bne	:exit

			jsr	InitForIO

::next			jsr	ReadBlock
			txa
			bne	:exit

			dec	r2L			;Alle Blocks gelesen?
			beq	:exit			; => Ja, Ende...

			ldy	#$00
			lda	(r4L),y
			beq	:exit
			sta	r1L
			iny
			lda	(r4L),y
			sta	r1H
			inc	r4H
			bne	:next

::exit			jmp	DoneWithIO
