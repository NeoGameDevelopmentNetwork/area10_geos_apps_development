; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration Laufwerke initialisieren.
:initDriveConfig	lda	flagDriverReady
			bne	:2			; => Treiber geladen.

			ldy	curDrive
			sty	bufDskDrvAdr
			lda	driveType -8,y
			sta	r5L			;Laufwerkstyp.

			lda	curDrive		;Mehr als 1 Lfwk.?
			eor	#$01
			tay
			lda	driveType -8,y
			beq	:exit			; => Nein, Ende...

			sta	r5H			;Zeiter Lfwk.-Typ.
			inc	numDrives

			lda	ramExpSize		;REU verfügbar?
			bne	:2			; => Ja, weiter...

			lda	r5H			;Zweites Lfwk. vom
			cmp	#Drv1581		;Typ 1581?
			beq	:1			; => Ja, weiter...
			bcs	:3			; => Ungültig...

			cmp	r5L			;Typ#8 = Typ#9?
			beq	:2			; => Ja, weiter...

;--- 2ten Treiber laden.
::1			jsr	loadDiskDriver
			txa				;Treiber geladen?
			bne	:3			; => Nein, Ende...

;--- Ist 2.Lfwk. verfügbar?
::2			jsr	swapCurDrive

			jsr	OpenDisk
			cpx	#DEV_NOT_FOUND
			bne	:4

			jsr	swapCurDrive

;--- Kein zweiter Treiber verfügbar.
::3			dec	numDrives

			lda	#$00
			sta	flagDriverReady
			beq	:exit

;--- Fehlerabfrage...
::4			txa				;Fehler ?
			bne	:5			; => Ja, weiter...

;--- Laufwerk-Icon aktualisieren.
			jsr	setNewDriveData
			clv
			bvc	:6

;--- Kein Treiber für Lfwk.9.
::5			jsr	resetDriveData

;--- Lfwk.10 vorhanden?
::6			lda	ramExpSize		;REU vorhanden?
			beq	:9			; => Nein, Ende...

			lda	curDrive		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			lda	#10			;Lfwk.10 aktivieren.
			jsr	setDevOpenDisk

			cpx	#DEV_NOT_FOUND
			beq	:8			; => Kein Lfwk.10...
			txa				;Fehler?
			beq	:7			; => Nein, weiter...

			jsr	resetDriveData
			clv				;Reset Laufwerke.
			bvc	:8 			; => Ende...

::7			lda	curType			;Laufwerk vorhanden?
			beq	:8			; => Nein, Ende...

;--- Icon für Laufwerk 10 aktualisieren.
			jsr	setNewDriveData

;--- Laufwerk zurücksetzen.
::8			pla				;Lfwk. zurücksetzen.
			jsr	setDevOpenDisk

::9			jsr	swapCurDrive

::exit			jmp	openNewDisk		;Diskette öffnen.

;*** Laufwerkstreiber aus Configure einlesen.
:loadDiskDriver		sta	r12L

			lda	#> tempDataBuf
			sta	r6H
			lda	#< tempDataBuf
			sta	r6L

			lda	#AUTO_EXEC
			sta	r7L

			lda	#$01
			sta	r7H

			lda	#> classConfigure
			sta	r10H
			lda	#< classConfigure
			sta	r10L
			jsr	FindFTypes
			jsr	exitOnDiskErr

			ldx	#FILE_NOT_FOUND
			lda	r7H			;Configure gefunden?
			bne	:exit			; => Nein, Abbruch...

			lda	#> tempDataBuf
			sta	r0H
			lda	#< tempDataBuf
			sta	r0L
			jsr	OpenRecordFile
			jsr	exitOnDiskErr

			lda	r12L
			clc
			adc	#$01
			jsr	PointRecord
			jsr	exitOnDiskErr

			lda	#> bufDiskDriver
			sta	r7H
			lda	#< bufDiskDriver
			sta	r7L

			lda	#> DISK_SIZE
			sta	r2H
			lda	#< DISK_SIZE
			sta	r2L

			jsr	ReadRecord

::exit			jsr	exitOnDiskErr

			lda	#$ff
			sta	flagDriverReady
			rts

:classConfigure		b "Configure",NULL
