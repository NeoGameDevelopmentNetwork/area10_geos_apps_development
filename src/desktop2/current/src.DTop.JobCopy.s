; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette/Blocks kopieren.
;Auch 1541 nach 1571 ist möglich!
;Verwendet ":tempDataBuf" als Speicher
;Blockadressen und Blockdaten.
;r10 zeigt auf den Beginn der Block-
;Tabelle am Anfang von ":tempDataBuf".
;Nach der Tabelle folgen die Daten der
;Blöcke zu den Block-Adressen.
:doJobCopyDisk		lda	#$00			;$00=Datei kopieren.
			sta	flagDuplicate

			ldy	a1H			;Quelle = RAM-Lfwk.?
			lda	driveType -8,y
			bmi	:1			; => Ja, weiter...

			and	#ST_DTYPES
			cmp	#Drv1571		;1571-Laufwerk?
			bne	:3			; => Nein, weiter...

::1			ldy	a2L			;Ziel = RAM-Lfwk.?
			lda	driveType -8,y
			bmi	:2			; => Ja, weiter...

			and	#ST_DTYPES
			cmp	#Drv1571		;1571-Laufwerk?
			bne	:3			; => Nein, weiter...

;--- Neuen Interleave-Wert setzen.
::2			lda	#$07			;Nur RAMDisk u. 1571.
			sta	diskInterleave

::3			jsr	setSourceDiskDrv
			jsr	testErrBox1Line
			txa				;Diskfehler?
			bne	:4			; => Ja, Ende...

			jsr	prepFileCopy

			clc
			lda	#$00
			adc	bufTempDataSize +0
			sta	bufTempDataSize +0
			lda	#$03
			adc	bufTempDataSize +1
			sta	bufTempDataSize +1
			jsr	setUserRecVec

;--- Dateien kopieren.
			jsr	doDiskCopyJob
			jsr	testErrBox1Line

;--- DeskTop suchen.
			jsr	chkDeskTop

::4			lda	#$08			;Standard setzen.
			sta	diskInterleave
			clv
			bvc	exitFCopy

;*** Datei kopieren.
;Übergabe: A = $00: Datei kopieren.
;              $ff: Datei duplizieren.
.doJobCopyFile		sta	flagDuplicate

			jsr	prepFileCopy

			ldx	#$00
			ldy	a2L
			jsr	is1571_yReg
			cmp	#Drv1581 +1		;Unbekanntes Format?
			bcs	:err			; => Ja, Fehler...

			jsr	copyDirHead2Buf
			txa				;Diskfehler?
			bne	:err			; => Ja, Ende...

			lda	vec2FCopyNmSrc +1
			sta	r6H
			lda	vec2FCopyNmSrc +0
			sta	r6L
			jsr	FindFile		;Ziel-Datei suchen.
			txa				;Diskfehler?
			bne	:err			; => Ja, Ende...

			ldx	#CANCEL_ERR
			lda	dirEntryBuf
			and	#%00001111
			cmp	#REL			;REL-Datei?
			beq	:err			; => Ja, Fehler...

			lda	dirEntryBuf +29
			bne	:1
			lda	dirEntryBuf +28
			cmp	#> sizeDataBuf +256
			bcs	:1

			jsr	resetCopyBuf

::1			jsr	setUserRecVec

			jsr	doFileCopy
			jsr	testErrBox1Line

			jsr	chkDeskTop
			clv
			bvc	exitFCopy

::err			jsr	testErrBox1Line

:exitFCopy		lda	#$00
			sta	flagFileCopy
			rts

;*** Auf Fehler oder Abbruch testen.
:testErrBox1Line	txa
			beq	:ok
			cmp	#CANCEL_ERR
			beq	:ok
			pha
			jsr	openErrBox1Line
			pla
			tax
::ok			rts

;*** Kopieren von Dateien vorbereiten.
:prepFileCopy		lda	#$ff
			sta	flagFileCopy

			jsr	resetCopyBuf

			lda	a1H			;Quell-Laufwerk =
			cmp	a2L			;Ziel-Laufwerk ?
			bne	:1			; => Nein, weiter...

			lda	flagDuplicate
			bne	:1			; => "Duplicate"...

;--- FileCopy ein Laufwerk/Borderblock.
			sta	flagFileCopy
			sta	flagBootDT
			sta	flagDiskRdy

;--- Max. Speicher als Puffer nutzen.
;ca. 84 Blocks.
;Nachteil: Danach muss DeskTop neu
;gestartet werden.
			lda	#> tempDataBufMax
			sta	bufTempDataVec +1
			lda	#< tempDataBufMax
			sta	bufTempDataVec +0

			lda	#> sizeDataBufMax
			sta	bufTempDataSize +1
			lda	#< sizeDataBufMax
			sta	bufTempDataSize +0

			lda	#$00
			sta	a9L

;--- Uhrzeit nicht mehr aktualisieren.
			jsr	blockProcClock

::1			lda	#$00
			sta	flagDkDrvRdy
			rts

;*** Zeiger auf Kopierspeicher initialisieren.
:resetCopyBuf		lda	#$ff			;DeskTop nach FCopy
			sta	flagBootDT		;neu starten.

			lda	#> tempDataBuf
			sta	bufTempDataVec +1
			lda	#< tempDataBuf
			sta	bufTempDataVec +0

			lda	#> sizeDataBuf
			sta	bufTempDataSize +1
			lda	#< sizeDataBuf
			sta	bufTempDataSize +0
			jmp	restartProcClock

;*** Sicherstellen das DeskTop verfügbar ist.
:chkDeskTop		txa
			pha

			lda	flagBootDT
			bne	:ok

::search		jsr	findDeskTop
			txa
			beq	:ok
			ldy	#ERR_INSERTDT
			jsr	openMsgDlgBox
			clv
			bvc	:search

::ok			jsr	resetRecVec
			jsr	updateProcClock

			lda	#$ff
			sta	flagBootDT

			pla
			tax
			rts

;*** DESKTOP auf Diskette suchen.
:findDeskTop		jsr	OpenDisk		;Diskette öffnen.
			jsr	exitOnDiskErr

			jsr	findDTopFile
			jsr	exitOnDiskErr

;--- Hinweis:
;Code-Optimierung mölglich.
;			ldx	#FILE_NOT_FOUND
;			lda	r7H			;Gefunden?
;			bne	:exit			; => Nein, Ende...
;---
			lda	r7H			;Gefunden?
			beq	:1			; => Ja, weiter...

			ldx	#FILE_NOT_FOUND
			bne	:exit

::1			lda	r5H			;Zeiger auf Datei in
			sta	r9H			;Verzeichnis nach r9.
			lda	r5L			;(Für GetFHdrInfo)
			sta	r9L
			jsr	reloadDeskTop

::exit			rts

;*** DESKTOP über GEOS-Klasse suchen.
:findDTopFile		jsr	r10_classDTop

			lda	#SYSTEM			;Systemdatei suchen.
			sta	r7L

;*** Dateityp suchen.
;Übergabe: r7L = GEOS-Dateityp.
;          r10 = GEOS-Klasse.
;Rückgabe: r7H = 0: Datei gefunden.
;          r6  = Zeiger auf Dateiname.
:findUserFile		jsr	OpenDisk

			lda	#$01			;Nur 1 Datei suchen.
			sta	r7H

			jsr	r6_buf_TempName

			jmp	FindFTypes

;*** hauptmodul von DeskTop neu einlesen.
;Übergabe: r9 = Zeiger auf Verzeichniseintrag.
:reloadDeskTop		jsr	GetFHdrInfo		;Infoblock einlesen.
			jsr	exitOnDiskErr

			ldy	#$01			;Zeiger auf VLIR-
			lda	(r9L),y			;Header setzen.
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
			jsr	getDiskBlock
			jsr	exitOnDiskErr

			lda	diskBlkBuf +2
			sta	r1L
			lda	diskBlkBuf +3
			sta	r1H			;Erster Datensatz.

;--- Hinweis:
;Falls der Datensatz größer ist als
;erwartet, dann überschreibt diese
;Routine ggf. den GEOS-Systembereich!
			lda	#$ff			;Größe wird nicht
			sta	r2L			;begrenzt, Fehler?
			sta	r2H
			jmp	ReadFile		;Datensatz lesen.
