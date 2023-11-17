; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;Convert UUE
if .p
			t "TopSym"
			t "TopMac"
			t "src.geoConve.ext"
endif

			n "mod.#5"
			o VLIR_BASE
			p START_SEQ

;*** Sub-Routinen anspringen.
:START_SEQ		lda	FileConvMode
			cmp	#ConvMode_SEQ_UUE
			beq	ConvToUUE
			cmp	#ConvMode_SEQ_UUEadd
			beq	AppendToUUE
			jmp	ConvUUE_SEQ_PRG

;*** Auswahl UUE-Format.
:ConvToUUE		ldx	#$00
			ldy	#$01
			stx	ConvModeUUE
			sty	BlockCount  +0
			stx	BlockCount  +1
			stx	StartSektor +0
			stx	StartSektor +1
			stx	TgtSektor   +0
			stx	TgtSektor   +1
			stx	SrcSektor   +0
			stx	SrcSektor   +1
			stx	BytePointer
			stx	DirSektor   +0
			stx	DirSektor   +1
			stx	DirPointer  +0
			sty	FindSektor  +0
			sty	FindSektor  +1

:AppendToUUE		ldy	#$00
::101			lda	CurFileName,y
			sta	SourceFile ,y
			beq	:102
			iny
			bne	:101
::102			cpy	#14
			bcc	:103
			ldy	#13
::103			sty	LenSrcFilNm
			tya
			bne	:104
			jmp	StartMenu

::104			lda	DirSektor +0
			bne	:107

			jsr	InitNewSektor

::107			jsr	TextInfo_ConvertData

;*** Initialisieren.
:InitTargetSeq		lda	DirSektor +0
			bne	DefUUE_Header

			lda	TargetDrive
			jsr	SetDevice
			jsr	NewOpenDisk

			ldy	#16
::101			lda	SourceFile,y
			sta	TargetFile,y
			dey
			bpl	:101

			LoadW	r0,TargetFile
			jsr	SetNameDOS
			lda	#"."
			sta	FileNameDOS   +8
			lda	#"U"
			sta	FileNameDOS   +9
			lda	#"U"
			sta	FileNameDOS   +10
			lda	#$00
			sta	FileNameDOS   +11
			sta	FileNameDOS   +12
			sta	FileNameDOS   +13
			sta	FileNameDOS   +14
			sta	FileNameDOS   +15
			sta	FileNameDOS   +16
			sta	FileNameDOS   +17

			jsr	CheckCurFileNm

			ldy	#0
::102			lda	FileNameDOS,y
			sta	TargetFile ,y
			iny
			cpy	#16
			bne	:102

;*** Datei nach UUE konvertieren.
:DefUUE_Header		lda	SourceDrive
			jsr	SetDevice
			jsr	NewOpenDisk

			LoadW	r6,SourceFile
			jsr	FindFile

			lda	dirEntryBuf +1
			sta	SrcSektor   +0
			lda	dirEntryBuf +2
			sta	SrcSektor   +1
			lda	#$00
			sta	BytePointer

			lda	Option_ConvFileToUUE	;Datei UUE kodieren?
			beq	:100			;Ja, weiter...
			jmp	CopyTextFile		;Text als PLAINTEXT übernehmen.

::100			ldy	#$00
::101			lda	UUECodeBegin,y
			beq	:102
			jsr	AddByte2Sek
			iny
			bne	:101

::102			ldy	#$00
			ldx	LenSrcFilNm
::103			lda	SourceFile,y
			cmp	#$20
			bne	:104
			lda	#$2d
			bne	:107

::104			cmp	#$2f
			bne	:105
			lda	#$2d
			bne	:107

::105			cmp	#$41
			bcc	:107
			cmp	#$5b
			bcc	:106
			cmp	#$c1
			bcc	:107
			cmp	#$db
			bcs	:107

::106			and	#$7f
			ora	#$20
::107			jsr	AddByte2Sek
			iny
			dex
			bne	:103

			jsr	SendLF2File

;*** Quell-Daten lesen.
:GetNxSrcData		ldx	#$00
::101			jsr	GetNxByte
			sta	SeqDataBuf +0,x
			inx
			ldy	STATUS
			bne	:102
			cpx	#$2d
			bcc	:101
::102			stx	a2L
			sty	a2H

			ldx	a2L
			lda	#$00
			sta	SeqDataBuf +0,x
			sta	SeqDataBuf +1,x

			lda	a2L
			beq	SetEndUUE

;*** Ziel-Daten berechnen.
:ConvSeqLine		lda	a2L
			clc
			adc	#$20
			jsr	AddByte2Sek

			ldy	#$00
:ConvSeqData		ldx	#$00
::101			lda	SeqDataBuf +0,y
			sta	a3L,x
			inx
			iny
			cpx	#$03
			bne	:101

			lsr	a3L
			ror	a3H
			ror	a4L
			ror	a4H
			lsr	a3L
			ror	a3H
			ror	a4L
			ror	a4H
			lsr	a3H
			ror	a4L
			ror	a4H
			lsr	a3H
			ror	a4L
			ror	a4H
			lsr	a4L
			ror	a4H
			lsr	a4L
			ror	a4H
			lsr	a4H
			lsr	a4H

;*** Ziel-Daten schreiben.
:WriteDataUUE		ldx	#$00
::101			lda	a3L,x
			bne	:102
			lda	#$40
::102			clc
			adc	#$20
			jsr	AddByte2Sek
			inx
			cpx	#$04
			bne	:101

			cpy	a2L
			bcc	ConvSeqData

			jsr	SendLF2File

			lda	a2H
			bne	SetEndUUE
			jmp	GetNxSrcData

;*** Ende UUE-Datei markieren.
:SetEndUUE		lda	#$60
			jsr	AddByte2Sek

			jsr	SendLF2File

			lda	UUECodeEnd +0
			jsr	AddByte2Sek
			lda	UUECodeEnd +1
			jsr	AddByte2Sek
			lda	UUECodeEnd +2
			jsr	AddByte2Sek

			jsr	SendLF2File
			jsr	UpdateLastSek

;*** Verzeichniseintrag schreiben.
:WriteDirEntry		lda	DirSektor +0
			bne	:100

			LoadB	r10L,$00
			jsr	GetFreeDirBlk

			lda	r1L
			sta	DirSektor +0
			lda	r1H
			sta	DirSektor +1
			sty	DirPointer

::100			lda	DirSektor +0
			sta	r1L
			lda	DirSektor +1
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			ldy	DirPointer
			lda	diskBlkBuf,y
			beq	:100a
			tya
			clc
			adc	#$1c
			tay
			jmp	:105

::100a			lda	#$80 ! SEQ
			sta	diskBlkBuf,y
			iny
			lda	StartSektor +0
			sta	diskBlkBuf,y
			iny
			lda	StartSektor +1
			sta	diskBlkBuf,y
			iny
			ldx	#$00
::101			lda	TargetFile,x
			beq	:102
			sta	diskBlkBuf,y
			iny
			inx
			bne	:101
::102			tya
			and	#%00011111
			cmp	#21
			beq	:104
			lda	#$a0
			sta	diskBlkBuf,y
			iny
			bne	:102

::104			lda	#$00
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			lda	year
			sta	diskBlkBuf,y
			iny
			lda	month
			sta	diskBlkBuf,y
			iny
			lda	day
			sta	diskBlkBuf,y
			iny
			lda	hour
			sta	diskBlkBuf,y
			iny
			lda	minutes
			sta	diskBlkBuf,y
			iny
::105			lda	BlockCount +0
			sta	diskBlkBuf,y
			iny
			lda	BlockCount +1
			sta	diskBlkBuf,y

			LoadW	r4,diskBlkBuf
			jsr	PutBlock
			jsr	PutDirHead
			jmp	StartMenu

;*** Textdatei in UUE-Datei übernehmen.
:CopyTextFile		lda	#$00
			sta	LastByte

::101			jsr	GetNxByte
			pha
			cmp	#CR
			bne	:103
::102			jsr	SendLF2File
			jmp	:105

::103			cmp	#LF
			bne	:104
			lda	LastByte
			cmp	#CR
			bne	:102
			beq	:105

::104			jsr	AddByte2Sek
::105			pla
			sta	LastByte
			lda	STATUS
			beq	:101

			jsr	SendLF2File
			jsr	UpdateLastSek
			jmp	WriteDirEntry

;*** Auswahl SEQ-Format.
:ConvUUE_SEQ_PRG	ldx	#$ff
			stx	ConvModeUUE
			inx
			stx	SrcSektor   +0
			stx	SrcSektor   +1
			stx	BytePointer
			stx	DirSektor   +0
			stx	DirSektor   +1
			stx	DirPointer  +0
			inx
			stx	FindSektor  +0
			stx	FindSektor  +1

			ldy	#$00
::101			lda	CurFileName,y
			sta	SourceFile ,y
			beq	:102
			iny
			bne	:101
::102			cpy	#14
			bcc	:103
			ldy	#13
::103			sty	LenSrcFilNm
			tya
			bne	:104
			jmp	StartMenu

::104			jsr	TextInfo_ConvertData

;*** Quelldatei öffnen.
:DefSeq_Header		lda	SourceDrive
			jsr	SetDevice
			jsr	NewOpenDisk

			LoadW	r6,SourceFile
			jsr	FindFile

			lda	dirEntryBuf +1
			sta	SrcSektor   +0
			lda	dirEntryBuf +2
			sta	SrcSektor   +1
			lda	#$00
			sta	BytePointer
			sta	Flag_EOF
			sta	Flag_END_Found

;*** Suchen nach 'Start'-Markierung.
:FindBeginUUE		jsr	InputTextLine

			ldy	#$04
::101			lda	SeqDataBuf +0,y
			cmp	UUECodeBegin,y
			bne	FindBeginUUE
			dey
			bpl	:101

			lda	#$00
			sta	Flag_END_Found

			ldy	#$04
::102			iny
			lda	SeqDataBuf +0,y
			beq	ErrNoFileName
			cmp	#" "
			bne	:102

::103			iny
			lda	SeqDataBuf +0,y
			beq	ErrNoFileName
			cmp	#" "
			beq	:103

::104			iny
			lda	SeqDataBuf +0,y
			beq	ErrNoFileName
			cmp	#" "
			bne	:104

::105			iny
			lda	SeqDataBuf +0,y
			beq	ErrNoFileName
			cmp	#" "
			beq	:105
			jmp	GetSeqFName

;*** Fehler: Kein Dateiname angegeben.
:ErrNoFileName		LoadW	r0,DlgNoFileName
			jsr	DoDlgBox
			jmp	StartMenu

;*** Dateiname einlesen.
:GetSeqFName		ldx	#$00
::101			cmp	#$41
			bcc	:103
			cmp	#$5b
			bcs	:102
			ora	#$80
			bne	:103

::102			cmp	#$61
			bcc	:103
			cmp	#$7b
			bcs	:103
			and	#$5f

::103			sta	TargetFile,x
			inx
			iny
			lda	SeqDataBuf +0,y
			bne	:101

			lda	#$00
			sta	TargetFile,x
			stx	LenTgtFilNm

			lda	TargetDrive
			jsr	SetDevice
			jsr	NewOpenDisk
			LoadW	r0,TargetFile
			jsr	DeleteFile

;*** Quell-Daten lesen.
:InitNewSeqFile		ldx	#$00
			ldy	#$01
			sty	BlockCount  +0
			stx	BlockCount  +1
			stx	StartSektor +0
			stx	StartSektor +1
			stx	TgtSektor   +0
			stx	TgtSektor   +1

			jsr	InitNewSektor

;*** Ziel-Daten berechnen.
:ConvLineUUE		jsr	InputTextLine

			lda	SeqDataBuf +0
			sec
			sbc	#$20
			and	#$3f
			beq	EndOfAreaUUE
			sta	a2L

			ldy	#$01
:ConvDataUUE		ldx	#$00
::101			lda	SeqDataBuf +0,y
			sec
			sbc	#$20
			sta	a3L,x
			inx
			iny
			cpx	#$04
			bne	:101

			asl	a4H
			asl	a4H
			asl	a4H
			rol	a4L
			asl	a4H
			rol	a4L
			asl	a4H
			rol	a4L
			rol	a3H
			asl	a4H
			rol	a4L
			rol	a3H
			asl	a4H
			rol	a4L
			rol	a3H
			rol	a3L
			asl	a4H
			rol	a4L
			rol	a3H
			rol	a3L

;*** Ziel-Daten schreiben.
:WriteDataSeq		ldx	#$00
::101			lda	a3L,x
			jsr	AddByte2Sek
			dec	a2L
			beq	:102
			inx
			cpx	#$03
			bne	:101
			beq	ConvDataUUE
::102			jmp	ConvLineUUE

;*** Ende erreicht.
:EndOfAreaUUE		jsr	UpdateLastSek
			jsr	SetSeqName

			jsr	InputTextLine

			ldy	#$00
::101			lda	SeqDataBuf +0,y
			cmp	UUECodeEnd,y
			bne	ErrEndNotFound
			iny
			cpy	#$03
			bne	:101

			lda	#$ff
			sta	Flag_END_Found

			jmp	FindBeginUUE

;*** 'END'-Markierung nicht gefunden.
:ErrEndNotFound		LoadW	r0,DlgEndNotFound
			jsr	DoDlgBox
			jmp	StartMenu

;*** Textzeile einlesen.
:InputTextLine		ldx	#$00
::101			lda	Flag_EOF
			bne	NoMoreUUE

			jsr	GetNxByte

			ldy	STATUS
			sty	Flag_EOF

			cmp	#$20
			bcc	:102
			sta	SeqDataBuf +0,x
			inx
			cpx	#$4f
			bcc	:101

::102			cpx	#$00
			beq	:101
			lda	#$00
			sta	SeqDataBuf +0,x
			rts

;*** Keine weiteren UUE-Textzeilen.
:NoMoreUUE		pla
			pla

			lda	Flag_END_Found
			beq	ErrEndOfFile
			jmp	StartMenu

;*** 'Dateiende erreicht.
:ErrEndOfFile		LoadW	r0,DlgEndNotFound
			jsr	DoDlgBox
			jmp	StartMenu

;*** Verzeichniseintrag schreiben.
:SetSeqName		LoadB	r10L,$00
			jsr	GetFreeDirBlk

			lda	Option_CBMFileType
			sta	diskBlkBuf,y
			iny
			lda	StartSektor +0
			sta	diskBlkBuf,y
			iny
			lda	StartSektor +1
			sta	diskBlkBuf,y
			iny
			ldx	#$00
::101			lda	TargetFile,x
			beq	:102
			sta	diskBlkBuf,y
			iny
			inx
			cpx	LenTgtFilNm
			bne	:101
::102			tya
			and	#%00011111
			cmp	#21
			beq	:103
			lda	#$a0
			sta	diskBlkBuf,y
			iny
			bne	:102
::103			lda	#$00
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y
			iny
			lda	year
			sta	diskBlkBuf,y
			iny
			lda	month
			sta	diskBlkBuf,y
			iny
			lda	day
			sta	diskBlkBuf,y
			iny
			lda	hour
			sta	diskBlkBuf,y
			iny
			lda	minutes
			sta	diskBlkBuf,y
			iny
			lda	BlockCount +0
			sta	diskBlkBuf,y
			iny
			lda	BlockCount +1
			sta	diskBlkBuf,y

			LoadW	r4,diskBlkBuf
			jsr	PutBlock
			jmp	PutDirHead

;*** UUE-Code Variablen.
:UUECodeBegin		b "begin 644 ",NULL
:UUECodeEnd		b "end ",NULL

:ConvModeUUE		b $00
:LastByte		b $00

:LenSrcFilNm		b $00
:LenTgtFilNm		b $00

:Flag_EOF		b $00
:Flag_END_Found		b $00

:SeqDataBuf		s 81

;*** Dialogobx: "Dateiname nicht gefunden!"
:DlgNoFileName		b $81
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b OK          ,$02,$48
			b NULL

if Sprache = Deutsch
::101			b PLAINTEXT
			b BOLDON   ,"Schwerer Fehler!",PLAINTEXT,NULL
::102			b           "Es ist kein Dateiname im",BOLDON,NULL
::103			b           "UUE-Code angegeben!",NULL
endif
if Sprache = Englisch
::101			b PLAINTEXT
			b BOLDON   ,"Fatal error!",PLAINTEXT,NULL
::102			b           "No filename found in",BOLDON,NULL
::103			b           "UUE-converted file!",NULL
endif

;*** Dialogbox: "'END' nicht gefunden!"
:DlgEndNotFound		b $81
			b DBTXTSTR    ,$10,$0e
			w :101
			b DBTXTSTR    ,$10,$1e
			w :102
			b DBTXTSTR    ,$10,$29
			w :103
			b OK          ,$02,$48
			b NULL

if Sprache = Deutsch
::101			b PLAINTEXT
			b BOLDON   ,"Schwerer Fehler!",PLAINTEXT,NULL
::102			b           "Das Ende der UUE-Kodierung",BOLDON,NULL
::103			b           "wurde nicht gefunden!",NULL
endif
if Sprache = Englisch
::101			b PLAINTEXT
			b BOLDON   ,"Fatal error!",PLAINTEXT,NULL
::102			b           "End of the UUE-encoded",BOLDON,NULL
::103			b           "file not found!",NULL
endif

;*** Prüfen ob Datenspeicher bereits von Programmcode belegt.
			g DataSekBufStart
