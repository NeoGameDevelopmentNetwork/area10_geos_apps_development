; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#406.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	DoDISKtoDISK

;*** L406: Disk to Disk Copy.
:Anz_Tracks		= SCREEN_BASE +0
:Track_Table		= SCREEN_BASE +1
:EndBuffer		= $7100

:DoDISKtoDISK		jsr	UseGDFont 		;Bildschirm Initialisieren.
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			ldx	#r0L
			jsr	GetPtrCurDkNm
			ldy	#15
::101			lda	(r0L),y			;Dateiname in Zwischenspeicher
			cmp	#$a0
			bne	:102
			lda	#" "
::102			sta	V406a0+12,y
			dey
			bpl	:101

			PrintXY	6,190,V406a0
			PrintXY	6,198,V406a1
			jsr	CopyDisk

;*** Ende. Zurück zu GeoDOS.
:L406ExitGD		jsr	SetTarget
			jsr	SetGDScrnCol
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	InitScreen		;Zurück zu GeoDOS.

;*** Quell-Laufwerk aktivieren.
:SetSource		lda	SDrvPart
			ldx	Source_Drv
			jmp	OpenNewDrive

;*** Ziel-Laufwerk aktivieren.
:SetTarget		lda	TDrvPart
			ldx	Target_Drv

;*** Neues Laufwerk und Diskette öffnen.
:OpenNewDrive		pha
			txa
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			pla

			bit	curDrvMode		;CMD-Laufwerk ?
			bmi	:101			;ja, weiter...
			jsr	NewOpenDisk		;Nur Diskette öffnen.
			txa
			bne	ExitDskErr
			rts

::101			ldx	curDrive
			ldy	curDrvType
			cpy	#Drv_CMDRL
			beq	:102
;--- Ergänzung: 22.11.18/M.Kanet
;RAMDrive ist ähnlich CMD RAMLink, Kennung angepasst.
			cpy	#Drv_CMDRD
			bne	:103
::102			ldx	#$04 +8
::103			cmp	SystemPart-8,x		;Partition bereits aktiviert ?
			bne	:104			;Ja, weiter...
			rts

::104			sta	SystemPart-8,x		;Neue Partition merken und
			jsr	OpenNewPart		;Partition aktivieren.
::105			rts

;*** Disketten-Fehler!
:ExitDskErr		stx	:101 +1			;Fehler-Nummer merken.
			jsr	SetGDScrnCol
			jsr	ClrScreen
::101			ldx	#$ff			;Fehler-Nummer einlesen.
			jmp	DiskError		;Disketten-Fehler ausgeben.

;*** Neue Partition öffnen.
:OpenNewPart		sta	Part_Change+4		;Partitions-Nr. merken.
			C_Send	Part_Change		;Neue Partition aktivieren.

			bit	curDrvMode		;GEOS-RAM-Laufwerk ?
			bvc	:101			;Nein, weiter...

			jsr	GetCurPInfo

			ldx	curDrive		;Startadresse RAM-Partition setzen.
			lda	Part_Info +22
			sta	ramBase   - 8,x
			lda	Part_Info +23
			sta	driveData + 3
::101			rts

;** Diskette kopieren.
:CopyDisk		LoadW	a9,Track_Table		;Zeiger auf ersten Track einlesen.
			jsr	SetPoiToTrk
			MoveB	r1L,DskTr1
			MoveB	r1H,DskSe1

:LoadFrmDsk		jsr	CopyInfo

			MoveW	a9,a8			;Zeiger auf Vektor-Tabelle sichern.
			jsr	SetPoiToTrk
			jsr	SetSource		;Quell-Diskette öffnen.

			jsr	EnterTurbo
			jsr	InitForIO
			LoadW	r4,Memory2
			MoveB	DskTr1,r1L
			MoveB	DskSe1,r1H
::101			jsr	ReadBlock
			txa
			beq	:102
			jsr	DoneWithIO
			jmp	ExitDskErr

::102			lda	r1H
			cmp	a3H
			bne	:103
			jsr	NextTrack
			txa
			bne	:105
			beq	:104
::103			inc	r1H
::104			inc	r4H
			lda	r4H
			cmp	#>EndBuffer
			bne	:101

::105			MoveB	r1L,DskTr2
			MoveB	r1H,DskSe2

			jsr	DoneWithIO

;*** Sektoren speichern.
:SaveToDsk		ClrB	EndOfDisk

			MoveW	a8,a9
			jsr	SetPoiToTrk
			jsr	SetTarget

			jsr	EnterTurbo
			jsr	InitForIO
			LoadW	r4,Memory2
			MoveB	DskTr1,r1L
			MoveB	DskSe1,r1H
::101			jsr	WriteBlock
			txa
			beq	:102
			jsr	DoneWithIO
			jmp	ExitDskErr

::102			lda	r1H
			cmp	a3H
			bne	:103
			jsr	NextTrack
			txa
			bne	:105
			beq	:104
::103			inc	r1H
::104			inc	r4H
			lda	r4H
			cmp	#>EndBuffer
			bne	:101

::105			jsr	DoneWithIO

			MoveB	DskTr2,DskTr1
			MoveB	DskSe2,DskSe1

			ldx	EndOfDisk
			bne	CopyInfo
			jmp	LoadFrmDsk

;*** CopyInfo ausgeben.
:CopyInfo		MoveB	a3L       ,r0L
			LoadB	r1L       ,100
			lda	#$00
			sta	r0H
			sta	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	DMult
			MoveB	Anz_Tracks,r1L
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			LoadB	r1H,198
			LoadW	r11,83

			lda	#%11000000
			jsr	PutDecimal

			lda	#"%"
			jmp	SmallPutChar

;*** Zeiger auf nächsten Track.
:NextTrack		lda	a3L
			cmp	Anz_Tracks
			bne	:101
			ldx	#$ff
			stx	EndOfDisk
			rts

::101			AddVBW	3,a9

;*** Zeiger auf aktuellen Track.
:SetPoiToTrk		ldy	#$00
			lda	(a9L),y
			sta	r1L
			sta	a3L
			iny
			lda	(a9L),y
			sta	r1H
			iny
			lda	(a9L),y
			sta	a3H

			ldx	#$00
			stx	EndOfDisk
			rts

;*** Variablen:
:DskTr1			b $00
:DskSe1			b $00
:DskTr2			b $00
:DskSe2			b $00
:EndOfDisk		b $00
:SystemPart		b $05

if Sprache = Deutsch
:V406a0			b PLAINTEXT
			b "Diskette : 1234567890123456",NULL
:V406a1			b "Kopiert  :",NULL
endif

if Sprache = Englisch
:V406a0			b PLAINTEXT
			b "Disk     : 1234567890123456",NULL
:V406a1			b "Copied   :",NULL
endif

:EndProgrammCode

;*** Startadresse Zwischenspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1) * 256
