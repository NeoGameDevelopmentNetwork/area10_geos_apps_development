; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;*** Auswahl SEQ-Format.
:SEQ_Verbinden		ldx	SEQ_ModeOpen
			bne	AppendToSEQ

			ldx	#$00
			ldy	#$01
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

			ldx	#$ff
			sta	SEQ_ModeOpen

:AppendToSEQ		ldy	#$00
::101			lda	CurFileName,y
			sta	SourceFile ,y
			beq	:102
			iny
			bne	:101
::102			sty	LenSrcFilNm
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
:DefSeqDataFile		lda	DirSektor +0
			bne	DefSEQ_Header

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
			lda	#"T"
			sta	FileNameDOS   +9
			lda	#"X"
			sta	FileNameDOS   +10
			lda	#"T"
			sta	FileNameDOS   +11
			lda	#$00
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

;*** Datei nach SEQ konvertieren.
:DefSEQ_Header		lda	SourceDrive
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

;*** Textdatei in SEQ-Datei übernehmen.
:CopySeqFileData	jsr	GetNxByte
			jsr	AddByte2Sek

			lda	STATUS
			beq	CopySeqFileData

			jsr	UpdateLastSek
			jsr	WrSeqFileEntry
			jmp	StartMenü

;*** Verzeichniseintrag schreiben.
:WrSeqFileEntry		lda	DirSektor +0
			bne	GetCurDirSek

:WrNewFileEntry		LoadB	r10L,$00
			jsr	GetFreeDirBlk

			lda	r1L
			sta	DirSektor +0
			lda	r1H
			sta	DirSektor +1
			sty	DirPointer

:GetCurDirSek		lda	DirSektor +0
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

::100a			lda	CBM_FileType
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
			jmp	PutDirHead

;*** Auswahl SEQ-Format.
:SEQ_Trennen		ldx	#$00
			stx	SrcSektor   +0
			stx	SrcSektor   +1
			stx	BytePointer
			stx	DirSektor   +0
			stx	DirSektor   +1
			stx	DirPointer  +0
			inx
			stx	FindSektor  +0
			stx	FindSektor  +1

:SEQ_NextFileInit	ldx	#$00
			ldy	#$01
			sty	BlockCount  +0
			stx	BlockCount  +1
			stx	StartSektor +0
			stx	StartSektor +1
			stx	TgtSektor   +0
			stx	TgtSektor   +1

			lda	DirSektor
			bne	:104

			ldy	#$00
::101			lda	CurFileName,y
			sta	SourceFile ,y
			beq	:102
			iny
			bne	:101

::102			LoadW	r0,DlgSlctTgtDrv
			jsr	DoDlgBox

			lda	sysDBData
			bmi	:103
			jmp	StartMenü

::103			and	#%01111111
			sta	TargetDrive

::104			jsr	ScreenInfo1

;*** Nächste Datei speichern.
:SaveNextSeqFile	jsr	SetNextFileName

;*** Bildschirm aufbauen.
:SetSeqScrn		LoadB	dispBufferOn,ST_WR_FORE

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0040
			b	$48
			b	RECTANGLETO
			w	$00ff
			b	$7f
			b	FRAME_RECTO
			w	$0040
			b	$48
			b	MOVEPENTO
			w	$0042
			b	$4a
			b	FRAME_RECTO
			w	$00fd
			b	$7d
			b	NULL

:PrnSrcFile		LoadW	r0,V305a0
			jsr	PutString

			ldy	#$00
::103			lda	SourceFile,y
			beq	PrnTgtFile
			sty	:106 +1
			cmp	#$20
			bcc	:104
			cmp	#$7f
			bcc	:105
::104			lda	#"*"
::105			jsr	SmallPutChar
::106			ldy	#$ff
			iny
			cpy	#$10
			bne	:103

:PrnTgtFile		LoadW	r0,V305a1
			jsr	PutString

			ldy	#$00
::103			lda	TargetFile,y
			beq	:107
			sty	:106 +1
			cmp	#$20
			bcc	:104
			cmp	#$7f
			bcc	:105
::104			lda	#"*"
::105			jsr	SmallPutChar
::106			ldy	#$ff
			iny
			cpy	#$10
			bne	:103

::107			LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK

			lda	SourceDrive
			jsr	SetDevice
			jsr	NewOpenDisk

			LoadW	r6,SourceFile
			jsr	FindFile

			lda	DirSektor
			bne	:101

			lda	dirEntryBuf +1
			sta	SrcSektor   +0
			lda	dirEntryBuf +2
			sta	SrcSektor   +1
			lda	#$00
			sta	BytePointer

::101			jsr	InitNewSektor

			lda	#$00
			sta	a9L
			sta	a9H

;*** Textdatei in SEQ-Datei übernehmen.
:SaveSeqFileData	jsr	GetNxByte
			jsr	AddByte2Sek

			lda	STATUS
			bne	:102

			inc	a9L
			bne	:101
			inc	a9H
::101			lda	a9H
			lsr
			lsr
			cmp	SEQ_MaxSize
			bne	SaveSeqFileData
			jsr	UpdateLastSek
			jsr	WrNewFileEntry
			jmp	SEQ_NextFileInit

::102			jsr	UpdateLastSek
			jsr	WrNewFileEntry
			jmp	StartMenü

;*** Nächsten Dateinamen definieren.
:SetNextFileName	lda	TargetDrive
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
			lda	#"-"
			sta	FileNameDOS   +9
			sta	FileNameDOS   +10
			lda	#"1"
			sta	FileNameDOS   +11
			lda	#$00
			sta	FileNameDOS   +12
			sta	FileNameDOS   +13
			sta	FileNameDOS   +14
			sta	FileNameDOS   +15
			sta	FileNameDOS   +16
			sta	FileNameDOS   +17

::102			LoadW	r6,FileNameDOS
			jsr	FindFile
			txa
			bne	:106

::103			ldy	FileNameDOS+11
			cpy	#"9"
			bne	:105
			ldy	#$2f
			ldx	FileNameDOS+10
			cpx	#"9"
			bne	:104
			ldx	#$2f
			inc	FileNameDOS+ 9
::104			inx
			stx	FileNameDOS+10
::105			iny
			sty	FileNameDOS+11
			jmp	:102

::106			ldy	#0
::107			lda	FileNameDOS,y
			sta	TargetFile ,y
			iny
			cpy	#16
			bne	:107

			rts

;*** Variablen
:SEQ_ModeOpen		b $00

if Sprache = Deutsch
:V305a0			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0048
			b $58
			b "Quelle",GOTOX,$78,$00,": ",NULL
:V305a1			b GOTOXY
			w $0048
			b $66
			b "Ziel"  ,GOTOX,$78,$00,": ",NULL
endif

if Sprache = Englisch
:V305a0			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0048
			b $58
			b "Source",GOTOX,$78,$00,": ",NULL
:V305a1			b GOTOXY
			w $0048
			b $66
			b "Target",GOTOX,$78,$00,": ",NULL
endif
