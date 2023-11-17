; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DCMD"
endif

;*** GEOS-Header.
			n "obj.GetFilesData"
			t "G3_Data.V.Class"

			o LD_ADDR_GFILDATA

;*** Dateinamen/Partitionsnamen einlesen.
;    Dieser Einsprung wird von der Kernel-Routine verwendet. Hier werden bei
;    der UserBox die Benutzereinträge, bei der Dateiauswahlbox die Dateinamen
;    und bei der Partitionsauswahlbox die Partitionsnamen.
:xGetFiles_Data		jsr	GetFileNames
			jsr	SetADDR_GFilData
			jmp	SwapRAM

;*** Partitionen einlesen.
:xGetPName_Data		jsr	GetPartNames
			jsr	SetADDR_GFilData
			jmp	SwapRAM

;*** Zeiger auf Speicherbereich für Dateienamen setzen.
:SetVecRAM		lda	DB_VecFNameBuf +0
			sta	r0L
			lda	DB_VecFNameBuf +1
			sta	r0H

			lda	#< R3_ADDR_FNAMES
			sta	r1L
			lda	#> R3_ADDR_FNAMES
			sta	r1H

			lda	#< R3_SIZE_FNAMES
			sta	r2L
			lda	#> R3_SIZE_FNAMES
			sta	r2H

			lda	MP3_64K_DATA
			sta	r3L
			rts

;*** Dateien einlesen.
;    ACHTUNG! FindFTypes muß bleiben! Einige Programme verbiegen den Vektor für
;    FindFTypes in der Sprungtabelle auf einen eigene Routine um mehrere Datei-
;    typen anzuzeigen. Dateien also immer über FindFTypes suchen.
;    Möchte man alle Dateinamen anzeigen lassen muß der GEOS-Typ=255 sein.
:GetFileNames		ldx	#$00			;Anzahl dateien in Tabelle
			stx	DB_FilesInTab		;löschen.

			bit	DB_GetFilesOpt		;Partitionsauswahl ?
			bpl	:51			; => Ja, Ende...

;--- Partitionen einlesen.
			jsr	SetVecFNameBuf
			jsr	GetPartNames
			jmp	SwapFNameBuf

;--- Anwenderdateien einlesen.
::51			bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvc	:54			; => Nein, weiter...

			jsr	GetVecFNameBuf		;Zeiger auf Zwischenspeicher.

			ldy	#$00
::52			inx
			beq	:53
			lda	(r6L),y			;Weitere Einträge in Tabelle ?
			beq	:53			; => Nein, Ende.

			jsr	SetVecNxFName
			jmp	:52

::53			dex
			stx	DB_FilesInTab
			jsr	SetVecRAM		;Dateinamen zwischenspeichern.
			jmp	StashRAM

;--- FindFTypes
::54			lda	DB_GFileClass  +0	;Zeiger auf GEOS-Klasse
			sta	r10L			;einlesen.
			lda	DB_GFileClass  +1
			sta	r10H
			ora	r10L			;GEOS-Klasse definiert ?
			bne	:55			; => Ja, weiter...
			sta	DB_VecFilClass +0
			sta	DB_VecFilClass +1
			beq	:57

;--- GEOS-Klasse kopieren.
::55			ldy	#$00			;Zeiger auf erstes Zeichen.
::56			lda	(r10L)      ,y
			sta	DB_FileClass,y
			iny
			cpy	#$10
			bcc	:56
			lda	#$00
			sta	DB_FileClass,y

			lda	#< DB_FileClass
			sta	DB_VecFilClass +0
			lda	#> DB_FileClass
			sta	DB_VecFilClass +1

;--- Dateien suchen.
::57			jsr	SetVecFNameBuf
			jsr	ClrFNameBuf		;Zwischenspeicher löschen.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch...

			lda	DB_GFileType		;Dateityp setzen.
			sta	r7L
			lda	#MAX_FILES_BROWSE	;Max. 255 Dateien einlesen.
			sta	r7H
			lda	DB_VecFilClass +0	;GEOS-Klasse festlegen.
			sta	r10L
			lda	DB_VecFilClass +1
			sta	r10H
			jsr	GetVecFNameBuf		;Zeiger auf Zwischenspeicher.
			jsr	FindFTypes		;Dateien suchen.
			txa				;Diskettenfehler ?
			bne	:58			; => Ja, Abbruch...

			lda	#MAX_FILES_BROWSE	;Anzahl gefundener Dateien
			sec				;berechnen.
			sbc	r7H
			sta	DB_FilesInTab		;Anzahl Dateien merken.
::58			jmp	SwapFNameBuf

;*** Dateien einlesen.
:GetPartNames		jsr	ClrFNameBuf		;Zwischenspeicher löschen.

			ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bpl	:56			; => Nein, weiter...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:56			; => Ja, Abbruch...

			LoadW	r4,DB_PDATA_BUF
			jsr	GetPTypeData		;Partitionstypen einlesen.
			txa				;Diskettenfehler ?
			bne	:56			; => Ja, Abbruch...
			stx	r13L			;Partitionszähler löschen.
			inx
			stx	r3H			;Zeiger auf Partitionstabelle.

			jsr	GetVecFNameBuf

::51			ldx	r3H
			lda	DB_PDATA_BUF  ,x	;Partitionstyp einlesen und mit
			eor	curType			;aktuellem Laufwerk vergleichen.
			and	#%00001111		;Richtiges Partitionsformat ?
			bne	:54			; => Nein, weiter...

			LoadW	r4 ,dirEntryBuf		;Speicher für Partitionseintrag.
			jsr	GetPDirEntry		;Partitionsdaten einlesen.
			cpx	#ILLEGAL_PARTITION
			beq	:55			; => Alle Part. eingelesen, weiter..

			ldy	#$00
::52			lda	dirEntryBuf +3,y	;Partitions-Name kopieren.
			cmp	#$a0
			beq	:53
			sta	(r6L),y
			iny
			cpy	#$10
			bcc	:52

::53			jsr	SetVecNxFName

			ldx	r13L
			lda	dirEntryBuf +2
			sta	DB_PDATA_BUF  ,x	;Partitions-Nr. in Tabelle
			inc	r13L			;zwischenspeichern.
::54			inc	r3H			;Zeiger auf nächsten Eintrag.
			CmpBI	r3H,255			;Alle Einträge geprüft ?
			bne	:51			; => Nein, weiter...

::55			lda	r13L			;Anzahl Partitionen einlesen und
			sta	DB_FilesInTab		;zwischenspeichern.
			lda	#$c0
			sta	Flag_GetFiles
::56			rts

;*** Zeiger auf nächsten Dateinamen setzen.
:SetVecNxFName		lda	r6L
			clc
			adc	#17
			sta	r6L
			bcc	:51
			inc	r6H
::51			rts

;*** Zwischenspeicher für Dateinamen löschen.
:ClrFNameBuf		jsr	i_FillRam		;Speicher für Partitions-Namen und
			w	17*256 +256		;Partitions-Daten löschen.
			w	DB_FNAME_BUF
			b	$00
			rts

;*** Zeiger auf Dateinamenspeicher einlesen.
:GetVecFNameBuf		lda	DB_VecFNameBuf +0	;Zeiger auf Speicherbereich.
			sta	r6L
			lda	DB_VecFNameBuf +1
			sta	r6H
			rts

;*** Zeiger auf dateispeicher setzen und Zwischenspeicher freimachen.
:SetVecFNameBuf		lda	#< DB_FNAME_BUF		;Zeiger auf Speicherbereich
			sta	DB_VecFNameBuf +0	;für Dateinamen setzen.
			lda	#> DB_FNAME_BUF
			sta	DB_VecFNameBuf +1

;*** Zwischenspeicher freimachen/zurücksetzen.
:SwapFNameBuf		jsr	SetVecRAM		;Speicherbereich retten.
			jmp	SwapRAM

;*** Variablen.
:DB_VecFilClass		w $0000
:DB_FileClass		s 17

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_GFILDATA + R2_SIZE_GFILDATA -1
;******************************************************************************
