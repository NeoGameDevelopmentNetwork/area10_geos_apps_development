; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


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
			jmp	StartMenü

::104			lda	DirSektor +0
			bne	:107

			LoadW	r0,DlgSlctTgtDrv
			jsr	DoDlgBox

			lda	sysDBData
			bmi	:106
			jmp	StartMenü

::106			and	#%01111111
			sta	TargetDrive

			jsr	InitNewSektor

::107			jsr	ScreenInfo1

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

			lda	Flag_Text_File
			beq	:100
			jmp	CopyTextFile

::100			ldy	#$00
::101			lda	Text1,y
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

			lda	Text2 +0
			jsr	AddByte2Sek
			lda	Text2 +1
			jsr	AddByte2Sek
			lda	Text2 +2
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
			jmp	StartMenü

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
			jmp	StartMenü

::104			lda	DirSektor +0
			bne	:107

			LoadW	r0,DlgSlctTgtDrv
			jsr	DoDlgBox

			lda	sysDBData
			bmi	:106
			jmp	StartMenü

::106			and	#%01111111
			sta	TargetDrive

::107			jsr	ScreenInfo1

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

;*** Suchen nach 'BEGINN'-Markierung.
:FindBeginUUE		jsr	InputTextLine

			ldy	#$04
::101			lda	SeqDataBuf +0,y
			cmp	Text1,y
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
			jmp	StartMenü

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
			cmp	Text2,y
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
			jmp	StartMenü

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
			jmp	StartMenü

;*** 'Dateiende erreicht.
:ErrEndOfFile		LoadW	r0,DlgEndNotFound
			jsr	DoDlgBox
			jmp	StartMenü

;*** Verzeichniseintrag schreiben.
:SetSeqName		LoadB	r10L,$00
			jsr	GetFreeDirBlk

			lda	CBM_FileType
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

;*** Linefeed an Datei senden.
:SendLF2File		lda	LineFeedMode
			cmp	#$01
			beq	:102
			cmp	#$03
			beq	:101

			lda	#$0d
			jsr	AddByte2Sek

::101			lda	#$0a
			jmp	AddByte2Sek

::102			lda	#$0d

;*** Byte in Sektor schreiben.
:AddByte2Sek		stx	:102 +1
			sty	:102 +3

::100			ldx	TgtSekData +1
			inx
			beq	:103

::101			sta	TgtSekData,x
			stx	TgtSekData +1
::102			ldx	#$ff
			ldy	#$ff
			rts

::103			pha

			lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead

			lda	StartSektor+0
			bne	:104

			jsr	GetFirstSektor

::104			MoveB	FindSektor +0,r3L
			MoveB	FindSektor +1,r3H
			jsr	SetNextFree

			lda	r3L
			sta	FindSektor +0
			sta	TgtSekData +0
			lda	r3H
			sta	FindSektor +1
			sta	TgtSekData +1

			lda	TgtSektor  +0
			sta	r1L
			lda	TgtSektor  +1
			sta	r1H
			LoadW	r4,TgtSekData
			jsr	PutBlock
			jsr	PutDirHead

			lda	TgtSekData +0
			sta	TgtSektor  +0
			lda	TgtSekData +1
			sta	TgtSektor  +1

			inc	BlockCount +0
			bne	:105
			inc	BlockCount +1
::105			jsr	InitNewSektor
			pla
			jmp	:100


;*** Letzten Sektor schreiben.
:UpdateLastSek
::101			lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead

			lda	TgtSektor  +0
			bne	:102
			jsr	GetFirstSektor

::102			lda	TgtSektor  +0
			sta	r1L
			lda	TgtSektor  +1
			sta	r1H
			LoadW	r4,TgtSekData
			jmp	PutBlock

;*** Neuen Sektor initialisieren.
:InitNewSektor		jsr	i_FillRam
			w	256
			w	TgtSekData
			b	$00

			ldx	#$00
			lda	#$01
			stx	TgtSekData +0
			sta	TgtSekData +1
			rts

;*** Ersten Sektor suchen.
:GetFirstSektor		MoveB	FindSektor +0,r3L
			MoveB	FindSektor +1,r3H
			jsr	SetNextFree

			lda	r3L
			sta	FindSektor +0
			sta	TgtSektor  +0
			sta	StartSektor+0
			lda	r3H
			sta	FindSektor +1
			sta	TgtSektor  +1
			sta	StartSektor+1

			jmp	PutDirHead

;*** Byte aus Quelldatei einlesen.
:GetNxByte		stx	:106 +1
			sty	:106 +3

			ldx	BytePointer
			bne	:103

::101			lda	SourceDrive
			jsr	SetDevice
			jsr	GetDirHead

::102			lda	SrcSektor +0
			sta	r1L
			lda	SrcSektor +1
			sta	r1H
			LoadW	r4,SrcSekData
			jsr	GetBlock

			lda	#$01
			sta	BytePointer

::103			ldx	BytePointer
			inx
			bne	:105

			lda	SourceDrive
			jsr	SetDevice
			jsr	GetDirHead

			lda	SrcSekData +0
			sta	SrcSektor  +0
			ldx	SrcSekData +1
			stx	SrcSektor  +1
			cmp	#$00
			beq	:104
			jmp	:102

::104			lda	#%01000000
			sta	STATUS
			lda	#$00
			jmp	:106

::105			lda	#%00000000
			sta	STATUS

			stx	BytePointer
			ldy	SrcSekData +0
			bne	:103b

			cpx	SrcSekData +1
			bne	:103b
			lda	#%01000000
			sta	STATUS

::103b			lda	SrcSekData,x

::106			ldx	#$ff
			ldy	#$ff
			rts

;*** UUE-Code Variablen.
:Text1			b "begin 644 ",NULL
:Text2			b "end ",NULL

:ConvModeUUE		b $00
:Flag_Text_File		b $00
:LastByte		b $00

:LineFeedMode		b $02

:LenSrcFilNm		b $00
:LenTgtFilNm		b $00

:Flag_EOF		b $00
:Flag_END_Found		b $00

:SeqDataBuf		s 81
