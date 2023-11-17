; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei(en) kopieren.
:doFileCopy		jsr	fcopyInitNxFNam
			jsr	fcopyInitSearch

			jsr	fcopyTestBufFull
			jsr	exitOnDiskErr

			jsr	setTargetDiskDrv
			jsr	exitOnDiskErr

			lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L
			jsr	CalcBlksFree

			ldx	#INSUFF_SPACE
			lda	bufCurCopyFile +29
			cmp	r4H			;Testen ob genügend
			bne	:1			;Speicher frei.
			lda	bufCurCopyFile +28
			cmp	r4L
::1			beq	:2
			bcs	:exit			; => Nein, Abbruch...

::2			lda	a0H
			sta	r10L
			jsr	GetFreeDirBlk
			jsr	exitOnDiskErr

			lda	r10L			;Directory-Seite
			sta	a0H			;zwischenspeichern.
			sty	bufVecFreeDir

			lda	r1H
			sta	bufAdrFreeDir +1
			lda	r1L
			sta	bufAdrFreeDir +0
			jsr	PutDirHead
			jsr	exitOnDiskErr

::next			jsr	fcopyJobNextFile
			jsr	exitOnDiskErr
			tya				;Write VLIR-Header?
			bne	:ok			; => Ja, Ende...

			jsr	copyDirHead2Buf
			jsr	exitOnDiskErr

			jsr	fcopyTestBufFull
			jsr	exitOnDiskErr

			jsr	copyBuf2DirHead
			jsr	exitOnDiskErr
			beq	:next

::ok			jsr	fcopyWrTgtDEntry
			jsr	exitOnDiskErr
			jsr	PutDirHead
::exit			rts

;*** Einzelne Datei kopieren.
:fcopyJobNextFile	php
			sei

			lda	bufTempDataVec +1
			sta	r8H
			lda	bufTempDataVec +0
			sta	r8L

::next			jsr	move_r8_r10_y0

			lda	(r10L),y
			and	#%10000000		;Neuer Job?
			bne	:1			; => Ja, weiter...

			jsr	fcopyDoWriteBuf
			clv				;Daten in Puffer auf
			bvc	:2			;Disk schreiben.

::1			jsr	fcopyJobWrTgt
::2			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$02			;Zeiger auf Anfang
			lda	(r10L),y		;des nächsten Jobs
			sta	r8L			;einlesen.
			iny
			lda	(r10L),y
			sta	r8H

			ldy	#$00
			lda	(r10L),y
			and	#%00110000		;Datei Complete?
			beq	:next			; => Nein, weiter...

			ldx	#NO_ERROR
			and	#%00010000		;VLIR-Datei?
			beq	:exit			; => Nein, weiter...

			jsr	fcopyJobWrVLIR

			ldy	#$ff

::exit			plp
:no_func		rts

;*** DiskWrite-Routine für Dateityp aufrufen.
:fcopyJobWrTgt		ldy	#$00
			lda	(r10L),y		;Typ Datenstream
			and	#%00000011		;einlesen.
			tay
			lda	:tabWrJobH,y
			sta	r0H
			lda	:tabWrJobL,y
			sta	r0L
			jmp	(r0)

;*** Tabelle mit Schreibroutinen.
::tabWrJobH		b > fcopyJobWrGEOS		;Write InfoBlock.
			b > fcopyJobWrSEQ		;Write Data-Stream.
			b > fcopyJobWrVData		;Write VLIR-Header.
			b > no_func

::tabWrJobL		b < fcopyJobWrGEOS
			b < fcopyJobWrSEQ
			b < fcopyJobWrVData
			b < no_func

;*** VLIR-Header schreiben.
:fcopyJobWrVLIR		lda	tempDirEntry +21
			cmp	#VLIR			;VLIR-Datei?
			bne	:exit			; => Nein, Ende...

			lda	tempDirEntry +2
			sta	r1H
			lda	tempDirEntry +1
			sta	r1L
			lda	#>vlirHdrBuf
			sta	r4H
			lda	#<vlirHdrBuf
			sta	r4L
			jsr	PutBlock

::exit			rts

;*** Infoblock schreiben.
:fcopyJobWrGEOS		jsr	fcopyDoWriteBuf
			txa
			bne	:done

			lda	adr1stDataBlk +1
			sta	tempDirEntry +20
			lda	adr1stDataBlk +0
			sta	tempDirEntry +19

			lda	tempDirEntry +21
			cmp	#VLIR			;VLIR-Datei?
			bne	:done			; => Nein, weiter...

			jsr	setSearchTrSe
			jsr	SetNextFree

			lda	r3L			;VLIR-Header.
			sta	searchTrSe +0
			sta	tempDirEntry +1
			lda	r3H
			sta	searchTrSe +1
			sta	tempDirEntry +2

::done			lda	flagTgtDrv1581
			beq	:exit
			lda	#$23
			sta	searchTrSe +0
::exit			rts

;*** Seq.Datei schreiben.
:fcopyJobWrSEQ		jsr	fcopyDoWriteBuf

			lda	adr1stDataBlk +1
			sta	tempDirEntry +2
			lda	adr1stDataBlk +0
			sta	tempDirEntry +1
			rts

;*** VLIR-Stream schreiben.
:fcopyJobWrVData	jsr	fcopyDoWriteBuf

			ldy	#$01
			lda	(r10L),y		;VLIR-Datensatz.
			asl
			tay
			lda	adr1stDataBlk +0
			sta	vlirHdrBuf +2,y
			lda	adr1stDataBlk +1
			sta	vlirHdrBuf +3,y
			rts

;*** Buffer auf Disk speichern.
:fcopyDoWriteBuf	lda	r8L			;Zeiger auf Beginn
			clc				;Daten berechnen.
			adc	#< $0004
			sta	r7L
			lda	r8H
			adc	#> $0004
			sta	r7H

			ldy	#$02			;Ende der Daten
			lda	(r10L),y		;einlesen.
			sta	r2L
			iny
			lda	(r10L),y
			sta	r2H

			lda	r2L			;Dateigröße
			sec				;berechnen.
			sbc	r7L
			sta	r2L
			lda	r2H
			sbc	r7H
			sta	r2H

			jsr	setSearchTrSe
			jsr	r6_fileTrScTab

			lda	r7H
			pha
			lda	r7L
			pha
			jsr	NxtBlkAlloc
			pla
			sta	r7L
			pla
			sta	r7H
			jsr	exitOnDiskErr

			ldy	#$00
			lda	(r10L),y
			and	#%10000000		;Neue Datei?
			beq	:append			; => Nein, weiter...

			lda	fileTrScTab +1
			sta	adr1stDataBlk +1
			lda	fileTrScTab +0
			sta	adr1stDataBlk +0
			clv
			bvc	:write

;--- Verkettungszeiger aktualisieren.
::append		lda	searchTrSe +1
			sta	r1H
			lda	searchTrSe +0
			sta	r1L
			jsr	r4_diskBlkBuf
			jsr	GetBlock
			jsr	exitOnDiskErr

			lda	fileTrScTab +1
			sta	diskBlkBuf +1
			lda	fileTrScTab +0
			sta	diskBlkBuf +0
			jsr	PutBlock
			jsr	exitOnDiskErr

;--- Buffer auf Disk schreiben.
::write			lda	r3H
			sta	searchTrSe +1
			lda	r3L
			sta	searchTrSe +0
			jsr	r6_fileTrScTab
			jmp	WriteFile

;*** Zeiger auf fileTrScTab setzen.
:r6_fileTrScTab		lda	#> fileTrScTab
			sta	r6H
			lda	#< fileTrScTab
			sta	r6L
			rts

;*** Dateisuche initialisieren.
:fcopyInitSearch	lda	#%01000000		;File complete.
			sta	jobInfFCopy +0

			lda	#$00
			sta	flagTgtDrv1581

			ldy	a2L
			lda	driveType -8,y
			cmp	#Drv1581
			bne	:not1581
			sta	flagTgtDrv1581

::is1581		lda	#$27
			bne	:set1stblk

::not1581		lda	#$01

::set1stblk		sta	searchTrSe +0

			lda	#$00
			sta	searchTrSe +1
			sta	flagCopyMode
			rts

;*** Kopiermodus.
:flagCopyMode		b $00				;$00 = Infoblock.
							;$01 = Neue Seq.-Datei.
							;$02 = Neue VLIR-Datei.
							;$03 = Nächster VLIR-Datensatz.
							;$04 = Ende VLIR-Datei.

;*** Typ Ziel-Laufwerk.
:flagTgtDrv1581		b $00				;$00 = Keine 1581.
							;$03 = 1581 (":Drv1581").

;*** Testen ob Kopierspeicher voll?
:fcopyTestBufFull	php
			sei

			lda	bufTempDataVec +1
			sta	r8H
			lda	bufTempDataVec +0
			sta	r8L

			lda	bufTempDataSize +1
			sta	r9H
			lda	bufTempDataSize +0
			sta	r9L

			lda	#> jobInfFCopy
			sta	r10H
			lda	#< jobInfFCopy
			sta	r10L

::1			lda	r9H			;Überprüfen ob
			beq	:5			;Platz im Puffer für
			cmp	#> $0104		;einen weiteren Job
			bne	:2			;verfügbar ist.
			lda	r9L
			cmp	#< $0104
			bcc	:5			; => Nein, weiter...

::2			ldy	#$00
			lda	(r10L),y
			and	#%01000000		;Stream complete?
			bne	:3			; => Ja, weiter...

			jsr	fcopyInitAddData
			clv
			bvc	:4

::3			jsr	fcopyInitNxJob
::4			txa
			bne	:err

			ldy	#$00
			lda	(r10L),y
			and	#%01000000		;Stream complete?
			beq	:5			; => Nein, weiter...

			lda	flagCopyMode
			cmp	#$04			;Ende VLIR-Datei?
			bne	:1			; => Nein, weiter...

			lda	#%00110000		;Datei/VLIR complete.
			bne	:6			;Weiter...

::5			lda	#%00100000		;Datei complete.
::6			ldy	#$00
			ora	(r10L),y
			sta	(r10L),y
			sta	jobInfFCopy +0

			ldx	#NO_ERROR
::err			plp
			rts

;*** Kopierjob initialisieren.
:fcopyInitNxJob		ldy	flagCopyMode
			lda	:tabInitJobH,y
			sta	r0H
			lda	:tabInitJobL,y
			sta	r0L
			jmp	(r0)

::tabInitJobH		b > fcopyInitInfo		;InfoBlock einlesen.
			b > fcopyInitSEQ		;Seq.Datei einlesen.
			b > fcopyInitVLIR		;VLIR-Header laden.
			b > fcopyInitNxVLIR		;VLIR-Stream laden.

::tabInitJobL		b < fcopyInitInfo
			b < fcopyInitSEQ
			b < fcopyInitVLIR
			b < fcopyInitNxVLIR

;*** InfoBlock einlesen.
:fcopyInitInfo		lda	bufCurCopyFile +19
			beq	fcopyInitSEQ		; => Kein Infoblock.

			jsr	move_r8_r10_y0

			lda	#%10000000		;Neue Datei mit
			sta	(r10L),y		;GEOS-Infoblock.

			lda	bufCurCopyFile +20
			sta	r1H
			lda	bufCurCopyFile +19
			sta	r1L
			jsr	readSrcCopyJob

			ldy	#$01			;SEQ-Datei.
			lda	bufCurCopyFile +21
			cmp	#VLIR			;VLIR-Datei?
			bne	:1			; => Nein, weiter...
			ldy	#$02			;VLIR-Datei.
::1			sty	flagCopyMode
			rts

;*** Seq.Datei einlesen.
:fcopyInitSEQ		jsr	move_r8_r10_y0

			lda	#%10000001		;Neue sequentielle
			sta	(r10L),y		;Datendatei.

			lda	bufCurCopyFile +2
			sta	r1H
			lda	bufCurCopyFile +1
			sta	r1L
			jsr	readSrcCopyJob

			lda	#$04
			sta	flagCopyMode
			rts

;*** Weitere Daten einlesen.
:fcopyInitAddData	ldy	#$00
			lda	(r10L),y
			pha				;Zeiger auf Puffer.
			jsr	move_r8_r10_y0
			pla
			and	#%00001111		;Job-Bits löschen.
			sta	(r10L),y

			lda	jobInfFCopy +3
			sta	r1H
			lda	jobInfFCopy +2
			sta	r1L
			jmp	readSrcCopyJob

;*** VLIR-Header einlesen.
:fcopyInitVLIR		lda	#$ff
			sta	jobInfFCopy +1

			lda	bufCurCopyFile +2
			sta	r1H
			lda	bufCurCopyFile +1
			sta	r1L

			lda	#>vlirHdrBuf
			sta	r4H
			lda	#<vlirHdrBuf
			sta	r4L
			jsr	GetBlock

			lda	#$03			;Nächster Datensatz.
			sta	flagCopyMode
			rts

;*** VLIR-Datensatz einlesen.
:fcopyInitNxVLIR	lda	jobInfFCopy +1
			sta	r0L			;VLIR-Datensatz.

			jsr	fcopyChkEndVLIR

			lda	flagCopyMode
			cmp	#$04			;Ende VLIR-Datei?
			beq	:exit			; => Ja, Ende...

			jsr	move_r8_r10_y0

			lda	r0L
			sta	jobInfFCopy +1
			asl
			tax
			lda	vlirHdrBuf +2,x
			sta	r1L
			lda	vlirHdrBuf +3,x
			sta	r1H

			lda	#%10000010		;Neue VLIR-Datei.
			sta	(r10L),y
			iny
			lda	r0L			;VLIR-Datensatz in
			sta	(r10L),y		;Job-Header setzen.

			lda	r0L
			pha
			jsr	readSrcCopyJob
			pla
			sta	r0L

			txa
			beq	fcopyChkEndVLIR
::exit			rts

;*** Alle VLIR-Datensätze gelesen?
:fcopyChkEndVLIR	inc	r0L
			lda	r0L
			cmp	#$7f			;Letzter Datensatz?
			bcs	:done			; => Ja, Ende...

			asl				;Folgt weiterer
			tax				;Datensatz?
			lda	vlirHdrBuf +2,x
			beq	fcopyChkEndVLIR
			bne	:ok			; => Ja, weiter...

::done			lda	#$04			;Ende VLIR-Datei.
			sta	flagCopyMode

::ok			ldx	#NO_ERROR
			rts

;*** Datenstream einlesen.
;Übergabe: r10 = Zeiger auf Datenpuffer.
;          r9  = Größe Datenpuffer.
:readSrcCopyJob		lda	r10L			;Anfangsadresse des
			clc				;Datenspeichers
			adc	#< $0004		;berechnen, dabei
			sta	r7L			;vier Job-Daten
			lda	r10H			;überspringen.
			adc	#> $0004
			sta	r7H

			sec				;Größe des noch
			lda	r9L			;verbleibenden
			sbc	#< $0004		;Datenpuffer
			sta	r2L			;berechnen.
			lda	r9H
			sbc	#> $0004
			sta	r2H
			jsr	ReadFile		;Datei einlesen.
			cpx	#BFR_OVERFLOW
			bne	:1

			lda	r1H			;Buffer Overflow.
			sta	jobInfFCopy +3
			lda	r1L
			sta	jobInfFCopy +2
			ldx	#NO_ERROR
			beq	:2

::1			ldy	#$00
			lda	(r10L),y
			ora	#%01000000		;Stream complete.
			sta	(r10L),y

::2			lda	r7H			;Zeiger hinter das
			sta	r8H			;zuletzt gelesene
			lda	r7L			;Datenbyte setzen.
			sta	r8L

			lda	r8L			;Größe des aktuellen
			sec				;Jobs berechnen.
			sbc	r10L
			sta	r0L
			lda	r8H
			sbc	r10H
			sta	r0H

			lda	r9L			;Restgröße des noch
			sec				;verbleibenden
			sbc	r0L			;Datenpuffers
			sta	r9L			;berechnen.
			lda	r9H
			sbc	r0H
			sta	r9H

			lda	r8L			;Startadresse des
			ldy	#$02			;nächsten Jobs im
			sta	(r10L),y		;Datenpuffer sezen.
			lda	r8H
			iny
			sta	(r10L),y
			rts

;*** Verzeichnis-Eintrag Ziel-Laufwerk.
:fcopyWrTgtDEntry	lda	bufAdrFreeDir +1
			sta	r1H
			lda	bufAdrFreeDir +0
			sta	r1L
			jsr	getDiskBlock
			jsr	exitOnDiskErr

			ldy	bufVecFreeDir
			ldx	#$00
::1			lda	tempDirEntry,x
			sta	diskBlkBuf,y
			inx
			iny
			cpx	#30
			bne	:1

			jmp	putDiskBlock

;*** Zeiger auf nächsten Namen.
:fcopyInitNxFNam	ldy	#30 -1
::1			lda	(r5L),y
			sta	bufCurCopyFile,y
			sta	tempDirEntry,y
			dey
			bpl	:1

			lda	vec2FCopyNmTgt +1
			sta	r3H
			lda	vec2FCopyNmTgt +0
			sta	r3L

			lda	#$ff
			sta	r1H

			ldx	#3
			ldy	#0
::2			lda	(r3L),y
			bne	:4
			lda	#$00
			sta	r1H
::3			lda	#$a0
::4			sta	tempDirEntry,x
			inx
			iny
			cpy	#16
			beq	:done

			lda	r1H
			bne	:2
			beq	:3

::done			lda	#$00			;Start/Infoblock.
			sta	tempDirEntry +1
			sta	tempDirEntry +2
			sta	tempDirEntry +19
			sta	tempDirEntry +20
			rts

;*** Startadresse neuer Copy-Job setzen.
:move_r8_r10_y0		lda	r8H			;Zeiger auf neue
			sta	r10H			;Job-Adresse.
			lda	r8L
			sta	r10L

			ldy	#$00			;Zeiger auf Job-Byte.
			rts

;*** Erster Sektor für Suche nach freiem Block.
:setSearchTrSe		lda	searchTrSe +1
			sta	r3H
			lda	searchTrSe +0
			sta	r3L
			rts
