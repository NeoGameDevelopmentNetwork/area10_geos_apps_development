; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;*** Diskette nach D64 wandeln.
:CreateD64Image		jsr	GotoFirstMenu

			ldy	SourceDrive
			lda	driveType-8,y
			and	#%00000111
			cmp	#DRV_1541
			beq	:101
			cmp	#DRV_1571
			bne	:100
			tya
			jsr	SetDevice
			jsr	NewOpenDisk

			lda	curDirHead+3
			beq	:101

::100			LoadW	r5,No41DrvTxt
			jmp	ErrDiskError

::101			LoadW	r0,DlgSlctTgtDrv
			jsr	DoDlgBox

			lda	sysDBData
			bmi	:102
			rts

::102			and	#%01111111
			sta	TargetDrive

			lda	#$00
			sta	TargetFile
			LoadW	r5,TargetFile
			LoadW	r0,DlgGetFileName
			jsr	DoDlgBox

			lda	TargetFile
			beq	:103
			lda	sysDBData
			cmp	#CANCEL
			bne	:104
::103			rts

::104			LoadW	r0,TargetFile
			jsr	SetNameDOS
			lda	#"."
			sta	FileNameDOS   +8
			lda	#"D"
			sta	FileNameDOS   +9
			lda	#"6"
			sta	FileNameDOS   +10
			lda	#"4"
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
::105			lda	FileNameDOS,y
			sta	TargetFile ,y
			iny
			cpy	#16
			bne	:105

			lda	TargetDrive
			jsr	SetDevice
			jsr	NewOpenDisk

			LoadW	r0,TargetFile
			jsr	DeleteFile


;*** Bildschirm-Informationen ausgeben.
:PrnScrnInfo		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
:D64_c1			w	$0040
			b	$58
			b	RECTANGLETO
:D64_c2			w	$00ff
			b	$6f
			b	FRAME_RECTO
:D64_c3			w	$0040
			b	$58
			b	MOVEPENTO
:D64_c4			w	$0042
			b	$5a
			b	FRAME_RECTO
:D64_c5			w	$00fd
			b	$6d
			b	NULL

			LoadW	r0,V302a0
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

::107			jsr	ScreenInfo1

;*** Datei einlesen.
:InitD64Info		lda	#$01
			ldx	#$00
			sta	a3L
			stx	a3H

			stx	TgtSekData +$00
			sta	TgtSekData +$01

			stx	D64ImageEntry +$01
			stx	D64ImageEntry +$02
			sta	D64ImageEntry +$1c
			stx	D64ImageEntry +$1d

			sta	a4L
			sta	a4H

;*** Disketten-Daten einlesen.
:Read1541Data		lda	SourceDrive
			jsr	SetDevice

			jsr	EnterTurbo
			jsr	InitForIO

			LoadW	r4,BACK_SCR_BASE

			lda	#$20
			sta	a5L
			sta	a5H

;*** 32 Sektoren einlesen.
::101			MoveB	a3L,r1L
			MoveB	a3H,r1H
			jsr	ReadBlock
			dec	a5L

			jsr	SetNextSek
			bne	:102

			inc	r4H
			lda	a5L
			bne	:101

::102			sta	a9L
			jsr	DoneWithIO

			CmpBI	a5L,$20
			bne	SaveDiskToD64
			jmp	EndOfDiskData

;*** Daten in D64-Datei schreiben.
:SaveDiskToD64		lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead

			LoadW	a6 ,BACK_SCR_BASE

			ldy	D64ImageEntry +$01
			bne	:104

			MoveB	a4L,r3L
			MoveB	a4H,r3H
			jsr	SetNextFree
			txa
			beq	:102
::101			jmp	ExitDiskErr

::102			lda	r3L
			ldx	r3H
			sta	a4L
			stx	a4H
			sta	a7L
			stx	a7H
			sta	D64ImageEntry +$01
			stx	D64ImageEntry +$02

::104			ldy	#$00
::105			lda	(a6L),y
			jsr	AddByteToD64Sek
			iny
			bne	:105

			dec	a5H
			bne	:107

::106			jsr	PutDirHead

			lda	a9L
			bne	EndOfDiskData
			jmp	Read1541Data

::107			inc	a6H
			lda	a9L
			beq	:104

			lda	a5H
			cmp	a5L
			beq	:108
			jmp	:104

::108			jsr	PutDirHead

;*** D64-Datei beenden.
:EndOfDiskData		lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead

;*** Fehlerbytes schreiben.
:WriteErrInfo		LoadW	a0,683
::101			lda	#$00
			jsr	AddByteToD64Sek
			lda	a0L
			bne	:102
			dec	a0H
::102			dec	a0L
			lda	a0L
			ora	a0H
			bne	:101

			jsr	UpdateD64Sek
			jsr	PutDirHead

;*** Verzeichniseintrag erzeugen.
:MakeD64DirEntry	lda	#$82
			sta	D64ImageEntry

			ldy	#$03
			ldx	#$00
::101			lda	TargetFile ,x
			beq	:102
			sta	D64ImageEntry ,y
			iny
			inx
			cpx	#$10
			bne	:101
			beq	:103
::102			lda	#$a0
			sta	D64ImageEntry ,y
			iny
			inx
			cpx	#$10
			bne	:102
::103			lda	#$00
			sta	D64ImageEntry ,y
			iny
			sta	D64ImageEntry ,y
			iny
			sta	D64ImageEntry ,y
			iny
			sta	D64ImageEntry ,y
			iny
			lda	year
			sta	D64ImageEntry ,y
			iny
			lda	month
			sta	D64ImageEntry ,y
			iny
			lda	day
			sta	D64ImageEntry ,y
			iny
			lda	hour
			sta	D64ImageEntry ,y
			iny
			lda	minutes
			sta	D64ImageEntry ,y

			LoadB	r10L,$00
			jsr	GetFreeDirBlk

			ldx	#$00
::104			lda	D64ImageEntry ,x
			sta	diskBlkBuf ,y
			iny
			inx
			cpx	#$1e
			bne	:104

			jsr	PutBlock

;			LoadB	dispBufferOn,ST_WR_BACK
;			lda	#$02
;			jsr	SetPattern
;			jsr	i_Rectangle
;			b	$00,$c7
;			w	$0000,$013f

;			LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK
;			jsr	i_Rectangle
;			b	$10,$c7
;			w	$0000,$013f

;			jsr	ScreenInfo2
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	OpenMain

;*** Byte in D64-Datei übertragen.
:AddByteToD64Sek	sty	:102 +1

			ldx	TgtSekData +$01
			inx
			bne	:101

			pha

			MoveB	a4L,r3L
			MoveB	a4H,r3H
			jsr	SetNextFree

			lda	r3L
			ldx	r3H
			sta	a4L
			stx	a4H
			sta	TgtSekData +$00
			stx	TgtSekData +$01

			MoveB	a7L,r1L
			MoveB	a7H,r1H
			LoadW	r4,TgtSekData
			jsr	PutBlock

			lda	TgtSekData +$00
			ldx	TgtSekData +$01
			sta	a7L
			stx	a7H

			inc	D64ImageEntry +$1c
			bne	:100
			inc	D64ImageEntry +$1d

::100			lda	#$00
			sta	TgtSekData +$00
			ldx	#$02
			pla

::101			stx	TgtSekData +$01
			sta	TgtSekData,x
::102			ldy	#$ff
			rts

;*** Byte in D64-Datei übertragen.
:UpdateD64Sek		MoveB	a7L,r1L
			MoveB	a7H,r1H
			LoadW	r4,TgtSekData
			jmp	PutBlock

;*** Variablen.
:D64ImageEntry		s 30

if Sprache = Deutsch
:V302a0			b PLAINTEXT,BOLDON
			b GOTOXY
:V302a1			w $0048
			b $66
			b "Datei",GOTOX
:V302a2			b $78,$00,": ",NULL
endif


if Sprache = Englisch
:V302a0			b PLAINTEXT,BOLDON
			b GOTOXY
:V302a1			w $0048
			b $66
			b "File",GOTOX
:V302a2			b $78,$00,": ",NULL
endif
