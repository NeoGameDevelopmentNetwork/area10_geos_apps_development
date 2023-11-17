; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Archiv-Datei suchen.
:FindSetupGD		jsr	OpenSourceDrive		;Quell-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			LoadW	r6 ,FNameSETUP		;Setup-Datei suchen.
			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,ClassSETUP
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H			;Datei gefunden ?
			beq	:52			; => Nein, weiter...

			LoadW	r0,DLG_INSERTDISK	;Dialogbox anzeigen:
			jsr	DoDlgBox		;"Diskette mit Archiv einlegen!"
			lda	sysDBData
			cmp	#OK			;Nochmal versuchen?
			beq	FindSetupGD		; => Ja, weitere...

			ldx	#FILE_NOT_FOUND		;Fehler, Datei nicht gefunden.
::51			rts				; => Abbruch...

::52			LoadW	r6,FNameSETUP
			jmp	FindFile		;Setup-Datei suchen.

;*** Gepacktes MP3-Archiv analysieren.
:AnalyzeFile		LoadW	r0,txAnalyze1		;Textmeldung ausgeben.
			jsr	PutString

			jsr	OpenSourceDrive		;Quell-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	PatchInfoTS +0
			sta	r1L
			lda	PatchInfoTS +1
			sta	r1H
			LoadW	r2,(GD3_FILES_NUM * 32) +1 +3
			LoadW	r7,CRC_CODE
			jsr	ReadFile		;Informationsdaten einlesen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			rts

::52			lda	PatchDataTS +0
			ldx	PatchDataTS +1
			jsr	PatchCRC		;Prüfsumme für Patchdaten
			txa				;erstellen. Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			CmpW	a0,CRC_CODE		;Prüfsummenfehler ?
			beq	AnalyzeFileDAT		; => Nein, weiter...

			LoadW	r0,DLG_CRCFILE_ERR
			jsr	DoDlgBox		;Fehler anzeigen.
			jmp	ExitToDeskTop		;Zurück zum DeskTop.

;*** Startposition für Dateien in Archiv ermitteln.
:AnalyzeFileDAT		LoadW	r0,txAnalyze2		;Menü ausgeben.
			jsr	PutString

			jsr	GetPackerCode		;Packer-Kennbyte einlesen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			rts

::52			lda	#$00			;Packer-Information löschen.
			sta	firstByte
			sta	PackedByteCode
			sta	PackedBytCount
			sta	PackedBytes
			sta	WrTmpSekCount +0
			sta	WrTmpSekCount +1
			lda	#$02
			sta	BytesInTmpWSek
			lda	#$ff
			sta	PutByteToDisk

			jsr	SetVecTopArchiv		;Zeiger auf Tabelle mit Dateinamen.

;--- Startadresse aktuelle Datei speichern.
:AnalyzeNxFile		lda	EntryPosInArchiv	;Zeiger auf aktuelle Datei.
			asl
			asl
			tay
			lda	r1L			;Startadresse des ersten Sektors
			sta	PackFileSAdr +0,y	;zwischenspeichern.
			lda	r1H
			sta	PackFileSAdr +1,y
			lda	Vec2SourceByte		;Zeiger auf Byte innerhalb Sektor
			sta	PackFileSAdr +2,y	;zwischenspeichern.
			lda	#$00
			sta	PackFileSAdr +3,y	;Dummy-Byte löschen.
			sta	WrTmpSekCount +0
			sta	WrTmpSekCount +1
			jsr	InitTargetFile
			txa
			beq	AnalyzeNxByte
			rts

;--- Bytes aus Archiv entpacken.
:AnalyzeNxByte		jsr	GetNxDataByte		;Nächstes Datenbyte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#$00			;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutBytDskDrv		;Byte in Zieldatei speichern.

;--- Ende aktuelle Datei erreicht ?
			lda	WrTmpSekCount +1
			cmp	SizeSourceFile+1
			bne	AnalyzeNxByte
			lda	WrTmpSekCount +0
			cmp	SizeSourceFile+0	;Alle Bytes kopiert ?
			bne	AnalyzeNxByte		; => Nein, weiter...

;--- Zeiger auf nächste Datei.
			PushB	r1L			;Sektoradresse speichern.
			PushB	r1H
			PushW	r4			;Zeiger auf Sektorspeicher sichern.
			jsr	PrntJobStatus		;Fortschrittsanzeige.
			PopW	r4			;Sektorspeicher zurücksetzen.
			PopB	r1H			;Sektoradresse zurücksetzen.
			PopB	r1L

			jsr	SetVecNxEntry		;Alle Dateien analysiert ?
			bne	AnalyzeNxFile		; => Weiter mit nächstem Byte.

;--- Ende erreicht.
::51			ldx	#NO_ERROR
::52			rts

;*** Zeiger auf ersten Eintrag in Archiv-Dateiliste.
:SetVecTopArchiv	ldx	#$00
			stx	EntryPosInArchiv
			LoadW	a7,FNameTab1
			rts

;*** Zeiger auf nächsten Eintrag in Archiv-Dateiliste.
:SetVecNxEntry		AddVBW	32,a7

			inc	EntryPosInArchiv
			lda	EntryPosInArchiv
			cmp	#GD3_FILES_NUM
			rts

;*** Fortschrittsanzeige berechnen.
:PrntJobStatus		lda	EntryPosInArchiv
			sta	r0L
			lda	#100
			sta	r1L
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

			lda	#GD3_FILES_NUM
			sta	r1L
			lda	#$00
			sta	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			LoadW	r11,$0110
			LoadB	r1H,$a8
			lda	#SET_SUPRESS!SET_LEFTJUST
			jsr	PutDecimal
			lda	#"%"
			jsr	SmallPutChar
			lda	#" "
			jmp	SmallPutChar

;*** Byte aus Archiv-Datei einlesen.
:GetNxDataByte		lda	PackedBytes		;Gepackte Daten aktiv ?
			beq	:52			; => Nein, weiter...

			lda	PackedByteCode		;Nächstes gepacktes Byte einlesen.
			dec	PackedBytCount
			bne	:51
			ldy	#$00
			sty	PackedByteCode
			sty	PackedBytes
::51			ldx	#$00
			rts

::52			jsr	GetNxPackBytSrc		;Neues Byte einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			cmp	PackerCodeByte		;Packer-Code ?
			beq	:54			; => Ja, weiter...
::53			rts

::54			jsr	GetNxPackBytSrc		;PackByte einlesen und
			sta	PackedByteCode		;zwischenspeichern.
			jsr	GetNxPackBytSrc		;Anzahl gepackter Bytes einlesen und
			sta	PackedBytCount		;zwischenspeichern.
			lda	#$ff
			sta	PackedBytes
			jmp	GetNxDataByte

;*** Nächstes Byte aus Archiv einlesen.
;    Diese Routine wird universell von allen Unterprogrammen verwendet.
;    Dazu zählen: ":AnalyzeFile", ":ExtractFiles" und ":ExtractDskDrv".
:GetNxPackBytSrc	jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.

			lda	diskBlkBuf +0
			bne	:52
			ldy	diskBlkBuf +1
			iny
			cpy	Vec2SourceByte
			bne	:52
::51			ldx	#$ff
			rts

::52			ldy	Vec2SourceByte
			bne	:53
			cmp	#$00
			beq	:51
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jsr	GetBlock

			ldy	#$02			;Byte aus Sektor einlesen und
::53			lda	diskBlkBuf,y		;dekodieren.
			eor	#%11001010
			iny
			sty	Vec2SourceByte
			ldx	#$00
			rts

;*** Packer-Kennbyte einlesen.
:GetPackerCode		jsr	OpenSourceDrive		;Quell-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	PatchDataTS +0
			sta	r1L
			lda	PatchDataTS +1
			sta	r1H
			lda	#$02
			sta	Vec2SourceByte
			jsr	GetSek_dskBlkBuf	;Ersten Sektor laden und
			jsr	GetNxPackBytSrc		;Packer-Code einlesen.
			sta	PackerCodeByte
::51			rts

;*** Variablen.
:PackerCodeByte		b $00				;Kennung für gepackte Daten.
:PackedBytes		b $00				;$FF = Packer aktiv.
:PackedByteCode		b $00
:PackedBytCount		b $00

:BytesInTmpWSek		b $00
:Vec2SourceByte		b $00

:EntryPosInArchiv	b $00

:PutByteToDisk		b $00
:WrTmpSekCount		w $0000

;*** Archiv analysieren.
:txAnalyze1		b PLAINTEXT
			b GOTOXY
			w $0010
			b $60
if Sprache = Deutsch
			b "Bitte haben Sie einen kleinen Augenblick Geduld,"
endif
if Sprache = Englisch
			b "Please be patient while 'SetupGD' examines"
endif
			b GOTOXY
			w $0010
			b $68
if Sprache = Deutsch
			b "während 'SetupGD' das Archiv mit den gepackten"
endif
if Sprache = Englisch
			b "the archive with the packed GeoDOS64 files."
endif
			b GOTOXY
			w $0010
			b $70
if Sprache = Deutsch
			b "GeoDOS64-Dateien untersucht."
endif
if Sprache = Englisch
			b ""
endif

			b GOTOXY
			w $0010
			b $80
if Sprache = Deutsch
			b "Dieser Vorgang kann einige Minuten dauern..."
endif
if Sprache = Englisch
			b "This process may take a few minutes..."
endif

			b GOTOXY
			w $0010
			b $9e
if Sprache = Deutsch
			b "* Archiv auf Fehler untersuchen..."
endif
if Sprache = Englisch
			b "* Checking archive for errors..."
endif
			b NULL

:txAnalyze2		b GOTOXY
			w $0010
			b $a8
if Sprache = Deutsch
			b "* Datei-Informationen einlesen..."
endif
if Sprache = Englisch
			b "* Get system file informations..."
endif
			b NULL

;*** Dialogbox: Bitte Diskette einlegen.
:DLG_INSERTDISK		b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w :10
			b DBTXTSTR ,$10,$20
			w :11
			b DBTXTSTR ,$10,$2c
			w ClassSETUP
			b DBTXTSTR ,$10,$38
			w :12
			b OK       ,$10,$48
			b CANCEL   ,$02,$48
			b NULL

if Sprache = Deutsch
::10			b PLAINTEXT,BOLDON
			b "INFORMATON"
			b NULL
::11			b "Bitte Diskette mit der",NULL
::12			b "Installationsdatei einlegen!",NULL
endif
if Sprache = Englisch
::10			b PLAINTEXT,BOLDON
			b "INFORMATON"
			b NULL
::11			b "Please insert a disk including",NULL
::12			b "the setup file into the drive!",NULL
endif

;*** Dialogbox: Prüfsummenfehler.
:DLG_CRCFILE_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w :10
			b DBTXTSTR ,$10,$20
			w :11
			b DBTXTSTR ,$10,$2a
			w :12
			b OK       ,$10,$48
			b NULL

if Sprache = Deutsch
::10			b PLAINTEXT,BOLDON
			b "INSTALLATIONSFEHLER"
			b NULL
::11			b "Prüfsummenfehler in",NULL
::12			b "der Programm-Datei 'SetupGD'!",NULL
endif
if Sprache = Englisch
::10			b PLAINTEXT,BOLDON
			b "INSTALLATION FAILED"
			b NULL
::11			b "Checksum-error in",NULL
::12			b "program file 'SetupGD'!",NULL
endif
