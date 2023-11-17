; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;SEQ/UUE-Funktionen

;*** Linefeed an Datei senden.
.SendLF2File		lda	Option_LineFeedMode
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
.AddByte2Sek		stx	:102 +1
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
.UpdateLastSek		lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead

			lda	TgtSektor  +0
			bne	:101
			jsr	GetFirstSektor

::101			lda	TgtSektor  +0
			sta	r1L
			lda	TgtSektor  +1
			sta	r1H
			LoadW	r4,TgtSekData
			jmp	PutBlock

;*** Neuen Sektor initialisieren.
.InitNewSektor		jsr	i_FillRam
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
.GetNxByte		stx	:106 +1
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

;*** Variablen.
.SrcSektor		b $00,$00
.TgtSektor		b $00,$00

.BytePointer		b $00

.BlockCount		w $0000
.DirSektor		b $00,$00
.DirPointer		b $00

.FindSektor		b $01,$01
.StartSektor		b $00,$00

;*** Gemeinsam genutzer Zwischenspeicher mit
;    'inc.ToolsDImg'.
.SourceFile		= StartSekTab +0
.TargetFile		= StartSekTab +17
:SrcSekData		= StartSekTab +17 +17
.TgtSekData		= StartSekTab +17 +17 +256
