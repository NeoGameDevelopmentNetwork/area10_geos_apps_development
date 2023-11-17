; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Hinweis:
;Bei FileCopy wird die BAM auf dem
;Ziel-Laufwerk beim Wechsel auf das
;Quell-Laufwerk zwischengespeichert
;und beim Wechsel zurück auf das Ziel-
;Laufwerk wieder hergestellt.
;Da die BAM nicht nach jedem schreiben
;auf der Ziel-Diskette aktualisiert
;wird ist das kopieren schneller.
;
;Diese Methode darf bei NativeMode
;nicht verwendet werden, da hier der
;dritte BAM-Speicher durch den Treiber
;ggf. auf einen anderen BAM-Block
;gesetzt wurde! Das kann dann die BAM
;zerstören -> Datenverlust!

;*** BAM sichern und Quell-Laufwerk öffnen.
:copyDirHead2Buf	ldy	#$00
::1			lda	curDirHead,y
			sta	buf_diskSek1,y
			lda	dir2Head,y
			sta	buf_diskSek2,y
			iny
			bne	:1

			ldy	a2L
			lda	driveType -8,y
			and	#ST_DTYPES
			cmp	#Drv1581
			bne	setSourceDiskDrv

;--- Nur 1581: ":dir3Head" sichern.
			tya
			jsr	setNewDevice

			ldy	#$00
::2			lda	dir3Head,y
			sta	buf_diskSek3,y
			iny
			bne	:2

;*** Quell-Laufwerk öffnen.
:setSourceDiskDrv	lda	nmDkSrc +1
			sta	r1H
			lda	nmDkSrc +0
			sta	r1L

			lda	a1H
			bne	setNewDiskDrive

;*** Ziel-Laufwerk öffnen.
:setTargetDiskDrv	lda	nmDkTgt +1
			sta	r1H
			lda	nmDkTgt +0
			sta	r1L

			lda	a2L

;*** Neues Laufwerk aktivieren.
:setNewDiskDrive	jsr	setNewDevice

			lda	flagFileCopy
			beq	:2

			lda	flagDkDrvRdy
			cmp	#$02
			bcc	:1

			ldx	#NO_ERROR
			rts

::1			inc	flagDkDrvRdy
::2			jmp	testErrOtherDisk

;*** Ziel-Laufwerk öffnen und BAM zurücksetzen.
:copyBuf2DirHead	jsr	setTargetDiskDrv

			ldy	#$00
::1			lda	buf_diskSek1,y
			sta	curDirHead,y
			lda	buf_diskSek2,y
			sta	dir2Head,y
			iny
			bne	:1

			ldy	a2L
			lda	driveType -8,y
			and	#ST_DTYPES
			cmp	#Drv1581
			bne	exit0

;--- Nur 1581: ":dir3Head" zurücksetzen.
			ldy	#$00
::2			lda	buf_diskSek3,y
			sta	dir3Head,y
			iny
			bne	:2

:exit0			rts
