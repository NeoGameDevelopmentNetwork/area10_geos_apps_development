; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;*** Verzeichnis aus D64-Archiv einlesen.
:D64toFile		jsr	ClrScreen
			jsr	GetSekOfD64File

;*** Dateien aus Verzeichnis einlesen.
:GetD64DirFiles		lda	#$00
			sta	FilesOnDisk
			sta	MaxFilesOnDsk
			sta	Poi_1stEntryInTab
			sta	TargetSelected

			jsr	i_FillRam
			w	$2000
			w	$4000
			b	$00

			LoadW	a4,$4000

			jsr	EnterTurbo
			jsr	InitForIO

			ldx	#$12
			lda	#$01
::101			jsr	PosToSektor
			LoadW	r15,diskBlkBuf
			jsr	GetSektor

			ldx	#$00
::102			lda	diskBlkBuf +$02,x
			cmp	#$80 ! SEQ
			beq	:103
			cmp	#$80 ! PRG
			beq	:103
			cmp	#$80 ! USR
			bne	:105
::103			txa
			pha
			ldy	#$00
::104			lda	diskBlkBuf +$00,x
			sta	(a4L),y
			inx
			iny
			cpy	#$20
			bne	:104

			AddVW	32,a4
			inc	MaxFilesOnDsk

			pla
			tax
::105			txa
			clc
			adc	#32
			tax
			bne	:102

			lda	diskBlkBuf +$01
			ldx	diskBlkBuf +$00
			bne	:101

			jsr	DoneWithIO
			lda	#$09
			sta	FileConvMode
			jsr	SetMenuData
			jsr	TestFileMemory

;*** Image-Verzeichnis anzeigen.
:ViewD64Dir		LoadW	r0,Menu_Files
			lda	#$01
			jmp	DoMenu
;*** Datei aus D64-Datei extrahieren.
:ExtractD64File		lda	TargetSelected
			bne	:101a

			jsr	RecoverMenu

			LoadW	r0,DlgSlctTgtDrv
			jsr	DoDlgBox

			lda	sysDBData
			bmi	:101
			jmp	ReDoMenu

::101			and	#%01111111
			sta	TargetDrive
			sta	TargetSelected

::101a			ldy	#$02
::102			lda	(a0L),y
			sta	dirEntryBuf -$02,y
			sta	OrgFileEntry -$02,y
			iny
			cpy	#$20
			bne	:102

			LoadB	dispBufferOn,ST_WR_FORE

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
:D64_b1			w	$0040
			b	$48
			b	RECTANGLETO
:D64_b2			w	$00ff
			b	$7f
			b	FRAME_RECTO
:D64_b3			w	$0040
			b	$48
			b	MOVEPENTO
:D64_b4			w	$0042
			b	$4a
			b	FRAME_RECTO
:D64_b5			w	$00fd
			b	$7d
			b	NULL

			LoadW	r0,V301a0
			jsr	PutString

			ldy	#$00
::103			lda	dirEntryBuf +$03,y
			sta	ExtractFileName ,y
			cmp	#$a0
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

::107			lda	#$00
			sta	ExtractFileName,y

			LoadW	r0,V301a1
			jsr	PutString

			lda	#<V301b0
			ldx	#>V301b0
			ldy	dirEntryBuf +$13
			beq	:108
			lda	#<V301b1
			ldx	#>V301b1
			ldy	dirEntryBuf +$15
			beq	:108
			lda	#<V301b2
			ldx	#>V301b2
::108			sta	r0L
			stx	r0H
			jsr	PutString

			LoadW	r0,V301a2
			jsr	PutString

			lda	dirEntryBuf +$1c
			sta	r0L
			lda	dirEntryBuf +$1d
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal

			LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK

			jsr	ScreenInfo1

;*** Datei einlesen.
:ReadD64File		lda	TargetDrive
			jsr	SetDevice
			LoadW	r0,ExtractFileName
			jsr	DeleteFile

			lda	#$01 			;Suche nach erstem freien
			sta	a4L 			;Sektor initialsieren.
			sta	a4H

			lda	OrgFileEntry +$13
			beq	:101
			ldx	OrgFileEntry +$14
			jsr	CopyD64SeqChain
			lda	dirEntryBuf +$01
			ldx	dirEntryBuf +$02
			sta	dirEntryBuf +$13
			stx	dirEntryBuf +$14

::101			lda	OrgFileEntry +$01
			ldx	OrgFileEntry +$02
			jsr	CopyD64SeqChain

			lda	OrgFileEntry +$15
			bne	:102
			jmp	WriteFileEntry

::102			lda	TargetDrive
			jsr	SetDevice

			lda	dirEntryBuf +$01
			ldx	dirEntryBuf +$02
			sta	NewVlirHdrSek +$00
			stx	NewVlirHdrSek +$01
			sta	r1L
			stx	r1H
			LoadW	r4,NewVlirHeader
			jsr	GetBlock

			LoadB	VecNewVlirHdr,$02

::103			ldy	VecNewVlirHdr
			lda	NewVlirHeader +$00,y
			beq	:104
			ldx	NewVlirHeader +$01,y
			jsr	CopyD64SeqChain

			ldy	VecNewVlirHdr
			lda	dirEntryBuf +$01
			sta	NewVlirHeader +$00,y
			lda	dirEntryBuf +$02
			sta	NewVlirHeader +$01,y

::104			inc	VecNewVlirHdr
			inc	VecNewVlirHdr
			bne	:103

			lda	TargetDrive
			jsr	SetDevice

			lda	NewVlirHdrSek +$00
			ldx	NewVlirHdrSek +$01
			sta	dirEntryBuf +$01
			stx	dirEntryBuf +$02
			sta	r1L
			stx	r1H
			LoadW	r4,NewVlirHeader
			jsr	PutBlock

;*** Verzeichniseintrag schreiben.
:WriteFileEntry		lda	TargetDrive
			jsr	SetDevice
			jsr	GetDirHead

			LoadB	r10L,$00
			jsr	GetFreeDirBlk

			ldx	#$00
::101			lda	dirEntryBuf,x
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#$1e
			bne	:101

			jsr	PutBlock

			jsr	ClrScreen
			LoadW	mouseXPos,$005c
			LoadB	mouseYPos,$16
			jmp	ReDoMenu

;*** Sektorkette kopieren.
:CopyD64SeqChain	sta	a3L			;Ersten Sektor merken.
			stx	a3H

			ldx	#$00
			stx	dirEntryBuf +$01	;Ersten Sektor Zieldaten
			stx	dirEntryBuf +$02	;löschen.

:RdD64SeqChain		lda	SourceDrive		;Quell-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			jsr	InitForIO

			LoadW	r15,BACK_SCR_BASE	;Zeiger auf Zwischenspeicher.

			lda	#$20			;Zähler für gelesene Sektoren
			sta	a5L			;löschen (max. 32 Sektoren!)
			sta	a5H
::102			ldx	a3L			;Zeiger auf Sektor in D64-
			lda	a3H			;Datei berechnen und Sektor
			jsr	PosToSektor		;in Zwischenspeicher lesen.
			jsr	GetSektor
			dec	a5L			;Sektoren in Speicher +1.

			ldy	#$01			;Zeiger auf nächsten Sektor
			lda	(r15L),y		;einlesen und merken.
			sta	a3H
			dey
			lda	(r15L),y
			sta	a3L
			beq	:103
			inc	r15H			;Zeiger auf Zwischenspeicher.
			lda	a5L
			bne	:102

::103			jsr	DoneWithIO
			CmpBI	a5L,$20			;Daten im Speicher ?
			bne	SaveSeqChain		;Ja, weiter...
			rts				;Ende...

;*** Daten auf Zieldatei schreiben.
:SaveSeqChain		lda	TargetDrive		;Ziel-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	NewOpenDisk

			LoadW	a6 ,BACK_SCR_BASE	;Zeiger auf Zwischenspeicher.

			lda	dirEntryBuf +$01	;Erster Sektor definiert ?
			bne	:103			;Ja, weiter...
			MoveB	a4L,r3L			;Ersten Sektor für Sektorkette
			MoveB	a4H,r3H			;ermitteln und merken.
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
			sta	dirEntryBuf +$01
			stx	dirEntryBuf +$02

::103			ldy	#$00
			lda	(a6L),y			;Folgt weiterer Sektor ?
			beq	:104			;Nein, weiter...

			MoveB	a4L,r3L			;Nächsten Sektor belegen.
			MoveB	a4H,r3H
			jsr	SetNextFree
			txa
			bne	:101

			ldy	#$00
			lda	r3L			;Verkettungszeiger für
			sta	a4L			;Sektorkette aktualisieren.
			sta	(a6L),y
			iny
			lda	r3H
			sta	a4H
			sta	(a6L),y

::104			MoveB	a7L,r1L			;Aktuellen Sektor schreiben.
			MoveB	a7H,r1H
			MoveW	a6 ,r4
			jsr	PutBlock
			dec	a5H

			ldy	#$00			;Zeiger auf nächsten Sektor.
			lda	(a6L),y			;Sektor vorhanden ?
			beq	:105			;Nein, Ende...
			sta	a7L
			iny
			lda	(a6L),y
			sta	a7H

			inc	a6H
			lda	a5H			;Zwischenspeicher kopiert ?
			bne	:103			;Nein, weiter...
			jsr	PutDirHead		;BAM aktualsieren.
			jmp	RdD64SeqChain		;Daten weiterlesen.
::105			jmp	PutDirHead		;Sektorkette kopiert.

;*** Variablen.
:TargetSelected		b $00
:OrgFileEntry		s 30
:NewVlirHdrSek		b $00,$00
:NewVlirHeader		s 256
:VecNewVlirHdr		b $00
:ExtractFileName	s 17

if Sprache = Deutsch
:V301a0			b PLAINTEXT,BOLDON
			b GOTOXY
:V301a3			w $0048
			b $58
			b "Datei" ,GOTOX
:V301a3_		b $78,$00,": ",NULL
:V301a1			b GOTOXY
:V301a4			w $0048
			b $66
			b "Format",GOTOX
:V301a4_		b $78,$00,": ",NULL
:V301a2			b GOTOXY
:V301a5			w $0048
			b $74
			b "Größe" ,GOTOX
:V301a5_		b $78,$00,": ",NULL

:V301b0			b "Sequentiell",NULL
:V301b1			b "GEOS-Sequentiell",NULL
:V301b2			b "GEOS-VLIR",NULL
endif

if Sprache = Englisch
:V301a0			b PLAINTEXT,BOLDON
			b GOTOXY
:V301a3			w $0048
			b $58
			b "File" ,GOTOX
:V301a3_		b $78,$00,": ",NULL
:V301a1			b GOTOXY
:V301a4			w $0048
			b $66
			b "Format",GOTOX
:V301a4_		b $78,$00,": ",NULL
:V301a2			b GOTOXY
:V301a5			w $0048
			b $74
			b "Size" ,GOTOX
:V301a5_		b $78,$00,": ",NULL

:V301b0			b "Sequentiell",NULL
:V301b1			b "GEOS-sequentiell",NULL
:V301b2			b "GEOS-VLIR",NULL
endif
