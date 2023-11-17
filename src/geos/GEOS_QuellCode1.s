; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS_C000.OBJ"
			f $06
			c "KERNAL_C000 V1.0"
			a "M. Kanet"
			o $c000
			p $c22c
			i

if .p
			t "var.ZeroPage"
			t "var.System"
			t "var.I/O-Bereich"

:irqvec			= $0314
:BACK_SCR_BASE		= $6000
:SCREEN_BASE		= $a000

:SETMSG			= $ff90
:SETLFS			= $ffba
:SETNAM			= $ffbd
:LOAD			= $ffd5

;*** Speicherbelegung in der REU.
:SetVecToSek		= $9d80				;Vektor ":r6" +2.
:xReadFile		= $9d8c				;Datei laden.
:xWriteFile		= $9e28				;Datei schreiben.
:SerialNumber		= $9ea7				;GEOS-Seriennummer.
:xVerifyRAM		= $9eaa				;RAM-Bereich vergleichen.
:xStashRAM		= $9eae				;RAM-Bereich speichern.
:xSwapRAM		= $9eb2				;RAM-Bereich tauschen.
:xFetchRAM		= $9eb6				;RAM-Bereich laden.
:xDoRAMOp		= $9eb8				;RAM-Routinen ausführen.
:BasicCommand		= $9f01				;BASIC-Befehl.
:JumpToBasic		= $9f2f
.ramExpBase1		= $de00
.ramExpBase2		= $df00

endif

;******************************************************************************
;*** Tastaturmatrix für Abfrage über
;    Register $DC00/$DC01
;
;-----------------------------------------------------------------------------
;Spalte			#0	#1 #2			#3	#4	#5	#6	#7
;-----------------------------------------------------------------------------
;Reihe
; #0			DEL	RET CRSR/LR			F1	F3	F7	F5	CRSR/UD
;
; #1			3	W A			4	Z	S	E	SHIFT/L
;
; #2			5	R D			6	C	F	T	X
;
; #3			7	Y G			8	B	H	U	V
;
; #4			9	I J			0	M	K	O	N
;
; #5			+	P L			-	.	:	(at)	,
;
; #6			E	*			;HOME	SHIFTR	=	^	/
;
; #7			1	<- CTRL			2	SPACE	C=	Q	RSTOP
;
;-----------------------------------------------------------------------------
;
;
;******************************************************************************

;*** Beginn des GEOS-Kernals ab $c000
.SystemReBoot		jmp	ReBootGEOS
			jmp	$5000

:bootName		b "GEOS BOOT"
:version		b $20
:nationality		b $01
			b $00
:sysFlgCopy		b $00
:c128Flag		b $00
			b $05,$00,$00,$00
:dateCopy		b $58,$07,$06

;*** GEOS neu starten.
.ReBootGEOS		lda	sysFlgCopy
			and	#%0100000		;RAM-Erweiterung vorhanden ?
			bne	ReBootRAM		;Ja, RAM-ReBoot...

			jsr	SETMSG

			lda	#$09			;Dateiname definieren.
			ldx	#<bootName
			ldy	#>bootName
			jsr	SETNAM
			lda	#$50			;Laufwerksdaten setzen.
			ldx	#$08
			ldy	#$01
			jsr	SETLFS
			lda	#$00			;Datei laden.
			jsr	LOAD
			bcc	StartBoot		;Fehler ? Nein, weiter...
			jmp	($0302)			;Abbruch...

;*** Boot-Programm aus RAM einlesen.
:ReBootRAM		ldy	#$08
::101			lda	RamBootData  ,y		;Transfer ausführen.
			sta	ramExpBase2+1,y
			dey
			bpl	:101
::102			dey				;Wartepause.
			bne	:102
:StartBoot		jmp	$6000			;Boot-Programm starten.

;*** Transferdaten.
:RamBootData		b $91
			w $6000
			w $7e00
			b $00
			w $0500
			b $00

			b $00

;*** Nach BASIC verlassen.
:xToBasic		ldy	#$27			;Befehlsstring auf gültige
::101			lda	(r0L),y			;Zeichen testen.
			cmp	#$41
			bcc	:102
			cmp	#$5b
			bcs	:102
			sbc	#$3f
::102			sta	BasicCommand,y		;Befehl in Zwischenspeicher.
			dey
			bpl	:101

			lda	r5H			;BASIC-File nachladen ?
			beq	:104			;Nein, weiter...

			iny
			tya
::103			sta	$0800,y
			iny
			bne	:103

			sec				;Ladeadresse BASIC-Datei -2.
			lda	r7L			;(Zeiger auf $07ff, dadurch
			sbc	#$02			; wird die Startadresse im
			sta	r7L			; ersten Sektor der Datei
			lda	r7H			; überlesen...)
			sbc	#$00
			sta	r7H

			lda	(r7L),y			;Inhalt der Adressen $07ff und
			pha				;$0800 sichern.
			iny
			lda	(r7L),y
			pha
			lda	r7H			;Ladeadresse merken.
			pha
			lda	r7L
			pha
			lda	(r5L),y			;Zeiger auf ersten Sektor der
			sta	r1L			;BASIC-Datei.
			iny
			lda	(r5L),y
			sta	r1H
			lda	#$ff
			sta	r2L
			sta	r2H
			jsr	xReadFile		;BASIC-Datei laden.
			pla				;ladeadresse zurück nach ":r0".
			sta	r0L
			pla
			sta	r0H

			ldy	#$01			;Inhalt der Adressen $07ff und
			pla				;$0800 wieder zurückschreiben.
			sta	(r0L),y
			dey
			pla
			sta	(r0L),y

::104			jsr	GetDirHead		;BAM einlesen.
			jsr	PurgeTurbo		;GEOS-Turbo abschalten.

			lda	sysRAMFlg
			sta	sysFlgCopy
			and	#%00100000		;RAM vorhanden ?
			beq	:106			;Nein, weiter...

			ldy	#$06			;GEOS-Daten in REU kopieren.
::105			lda	BootBasicData,y
			sta	r0,y
			dey
			bpl	:105
			jsr	StashRAM

::106			jmp	JumpToBasic		;"ToBasic" ausführen.

;*** Transferdaten.
:BootBasicData		w $8400
			w $7900
			w $0500
			b $00

;*** Mainloop von GEOS.
:xMainLoop		jsr	ExecMseKeyb		;Maus/Tastatur abfragen.
			jsr	ExecProcTab		;Prozesse ausführen.
			jsr	ExecSleepJobs
			jsr	SetGeosClock
			lda	appMain+0		;Anwenderprogramm ausführen.
			ldx	appMain+1
:InitMLoop1		jsr	CallRoutine
:InitMLoop2		cli
			jmp	InitSysIRQ

;*** Zeiger auf Positionen der Namen
;    aller Disketten (A: bis D:)
:DrvNmVecL		b <DrACurDkNm,<DrBCurDkNm,<DrCCurDkNm,<DrDCurDkNm
:DrvNmVecH		b >DrACurDkNm,>DrBCurDkNm,>DrCCurDkNm,>DrDCurDkNm

;*** GEOS-Sprungtabelle.
.Get1stDirEntry		= $9030
.GetNxtDirEntry		= $9033
.D_ReadSektor		= $903c
.D_WriteSektor		= $903f
.AllocateBlock		= $9048
.ReadLink		= $904b

.InterruptMain		jmp	xInterruptMain
.InitProcesses		jmp	xInitProcesses
.RestartProcess		jmp	xRestartProcess
.EnableProcess		jmp	xEnableProcess
.BlockProcess		jmp	xBlockProcess
.UnblockProcess		jmp	xUnblockProcess
.FreezeProcess		jmp	xFreezeProcess
.UnfreezeProcess	jmp	xUnfreezeProcess
.HorizontalLine		jmp	xHorizontalLine
.InvertLine		jmp	xInvertLine
.RecoverLine		jmp	xRecoverLine
.VerticalLine		jmp	xVerticalLine
.Rectangle		jmp	xRectangle
.FrameRectangle		jmp	xFrameRectangle
.InvertRectangle	jmp	xInvertRectangle
.RecoverRectangle	jmp	xRecoverRec
.DrawLine		jmp	xDrawLine
.DrawPoint		jmp	xDrawPoint
.GraphicsString		jmp	xGraphicsString
.SetPattern		jmp	xSetPattern
.GetScanLine		jmp	xGetScanLine
.TestPoint		jmp	xTestPoint
.BitmapUp		jmp	xBitmapUp
.PutChar		jmp	xPutChar
.PutString		jmp	xPutString
.UseSystemFont		jmp	xUseSystemFont
.StartMouseMode		jmp	xStartMouseMode
.DoMenu			jmp	xDoMenu
.RecoverMenu		jmp	xRecoverMenu
.RecoverAllMenus	jmp	xRecoverAllMenus
.DoIcons		jmp	xDoIcons
.DShiftLeft		jmp	xDShiftLeft
.BBMult			jmp	xBBMult
.BMult			jmp	xBMult
.DMult			jmp	xDMult
.Ddiv			jmp	xDdiv
.DSdiv			jmp	xDSdiv
.Dabs			jmp	xDabs
.Dnegate		jmp	xDnegate
.Ddec			jmp	xDdec
.ClearRam		jmp	xClearRam
.FillRam		jmp	xFillRam
.MoveData		jmp	xMoveData
.InitRam		jmp	xInitRam
.PutDecimal		jmp	xPutDecimal
.GetRandom		jmp	xGetRandom
.MouseUp		jmp	xMouseUp
.MouseOff		jmp	xMouseOff
.DoPreviousMenu		jmp	xDoPreviousMenu
.ReDoMenu		jmp	xReDoMenu
.GetSerialNumber	jmp	xGetSerialNumber
.Sleep			jmp	xSleep
.ClearMouseMode		jmp	xClearMouseMode
.i_Rectangle		jmp	xi_Rectangle
.i_FrameRectangle	jmp	xi_FrameRec
.i_RecoverRectangle	jmp	xi_RecoverRec
.i_GraphicsString	jmp	xi_GraphicsStrg
.i_BitmapUp		jmp	xi_BitmapUp
.i_PutString		jmp	xi_PutString
.GetRealSize		jmp	xGetRealSize
.i_FillRam		jmp	xi_FillRam
.i_MoveData		jmp	xi_MoveData
.GetString		jmp	xGetString
.GotoFirstMenu		jmp	xGotoFirstMenu
.InitTextPrompt		jmp	xInitTextPrompt
.MainLoop		jmp	xMainLoop
.DrawSprite		jmp	xDrawSprite
.GetCharWidth		jmp	xGetCharWidth
.LoadCharSet		jmp	xLoadCharSet
.PosSprite		jmp	xPosSprite
.EnablSprite		jmp	xEnablSprite
.DisablSprite		jmp	xDisablSprite
.CallRoutine		jmp	xCallRoutine
.CalcBlksFree		jmp	 ($9020)
.ChkDkGEOS		jmp	 ($902c)
.NewDisk		jmp	 ($900c)
.GetBlock		jmp	 ($9016)
.PutBlock		jmp	 ($9018)
.SetGEOSDisk		jmp	 ($902e)
.SaveFile		jmp	xSaveFile
.SetGDirEntry		jmp	xSetGDirEntry
.BldGDirEntry		jmp	xBldGDirEntry
.GetFreeDirBlk		jmp	 ($901e)
.WriteFile		jmp	xWriteFile
.BlkAlloc		jmp	 ($902a)
.ReadFile		jmp	xReadFile
.SmallPutChar		jmp	xSmallPutChar
.FollowChain		jmp	xFollowChain
.GetFile		jmp	xGetFile
.FindFile		jmp	xFindFile

;*** GEOS-Sprungtabelle.
.CRC			jmp	xCRC
.LdFile			jmp	xLdFile
.EnterTurbo		jmp	 ($9008)
.LdDeskAcc		jmp	xLdDeskAcc
.ReadBlock		jmp	 ($900e)
.LdApplic		jmp	xLdApplic
.WriteBlock		jmp	 ($9010)
.VerWriteBlock		jmp	 ($9012)
.FreeFile		jmp	xFreeFile
.GetFHdrInfo		jmp	xGetFHdrInfo
.EnterDeskTop		jmp	xEnterDeskTop
.StartAppl		jmp	xStartAppl
.ExitTurbo		jmp	 ($9004)
.PurgeTurbo		jmp	 ($9006)
.DeleteFile		jmp	xDeleteFile
.FindFTypes		jmp	xFindFTypes
.RstrAppl		jmp	xRstrAppl
.ToBasic		jmp	xToBasic
.FastDelFile		jmp	xFastDelFile
.GetDirHead		jmp	 ($901a)
.PutDirHead		jmp	 ($901c)
.NxtBlkAlloc		jmp	 ($9028)
.ImprintRectangle	jmp	xImprintRec
.i_ImprintRectangle	jmp	xi_ImprintRec
.DoDlgBox		jmp	xDoDlgBox
.RenameFile		jmp	xRenameFile
.InitForIO		jmp	 ($9000)
.DoneWithIO		jmp	 ($9002)
.DShiftRight		jmp	xDShiftRight
.CopyString		jmp	xCopyString
.CopyFString		jmp	xCopyFString
.CmpString		jmp	xCmpString
.CmpFString		jmp	xCmpFString
.FirstInit		jmp	xFirstInit
.OpenRecordFile		jmp	xOpenRecordFile
.CloseRecordFile	jmp	xCloseRecordFile
.NextRecord		jmp	xNextRecord
.PreviousRecord		jmp	xPreviousRecord
.PointRecord		jmp	xPointRecord
.DeleteRecord		jmp	xDeleteRecord
.InsertRecord		jmp	xInsertRecord
.AppendRecord		jmp	xAppendRecord
.ReadRecord		jmp	xReadRecord
.WriteRecord		jmp	xWriteRecord
.SetNextFree		jmp	 ($9024)
.UpdateRecordFile	jmp	xUpdateRecFile
.GetPtrCurDkNm		jmp	xGetPtrCurDkNm
.PromptOn		jmp	xPromptOn
.PromptOff		jmp	xPromptOff
.OpenDisk		jmp	 ($9014)
.DoInlineReturn		jmp	xDoInlineReturn
.GetNextChar		jmp	xGetNextChar
.BitmapClip		jmp	xBitmapClip
.FindBAMBit		jmp	 ($9026)
.SetDevice		jmp	xSetDevice
.IsMseInRegion		jmp	xIsMseInRegion
.ReadByte		jmp	xReadByte
.FreeBlock		jmp	 ($9022)
.ChangeDiskDevice	jmp	 ($900a)
.RstrFrmDialogue	jmp	xRstrFrmDialogue
.Panic			jmp	xPanic
.BitOtherClip		jmp	xBitOtherClip
.StashRAM		jmp	xStashRAM
.FetchRAM		jmp	xFetchRAM
.SwapRAM		jmp	xSwapRAM
.VerifyRAM		jmp	xVerifyRAM
.DoRAMOp		jmp	xDoRAMOp

;*** IRQ-Routine von GEOS.
:xInterruptMain		jsr	InitMouseData
			jsr	PrepProcData
			jsr	DecSleepTime		;Prozesse ausführen.
			jsr	SetCursorMode		;Cursormodus festlegen.
			jmp	xGetRandom

;*** Datenfelder.
:BitData1		b $80,$40,$20,$10,$08,$04,$02
:BitData2		b $01,$02,$04,$08,$10,$20,$40,$80
:BitData3		b $00,$80,$c0,$e0,$f0,$f8,$fc,$fe
:BitData4		b $7f,$3f,$1f,$0f,$07,$03,$01,$00

;*** Zeiger auf Diskettenname einlesen.
:xGetPtrCurDkNm		ldy	curDrive
			lda	DrvNmVecL-8,y
			sta	zpage+0,x
			lda	DrvNmVecH-8,y
			sta	zpage+1,x
			rts

;*** IRQ-Abfrage initialisieren und
;    zurück zur Mainloop.
:InitSysIRQ		ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA
			lda	grcntrl1
			and	#$7f
			sta	grcntrl1
			stx	CPU_DATA
			jmp	xMainLoop

;*** Zurück zum DeskTop
:xEnterDeskTop		sei				;IRQ sperren.
			cld				;"DEZIMAL"-Flag löschen.
			ldx	#$ff			;Wert für "GEOS-Bootvorgang ist
			stx	firstBoot		;aktiv!" setzen.
			txs				;Stackzeiger löschen.
			jsr	ClrDeskScrn		;GEOS-Bildschirm löschen.
			jsr	GEOS_Init1
			lda	curDrive		;Aktuelles Laufwerk merken.
			sta	StartDTdrv
			eor	#$01			;Zeiger auf nächstes Laufwerk.
			tay				;Laufwerkstyp einlesen.
			lda	driveType -8,y
			php
			lda	StartDTdrv		;Startlaufwerk einlesen.
			plp				;Nächstes Lfw. = RAM-Lfw. ?
			bpl	DT_StartSearch		;Nein, Startlaufwerk vorgeben.
			tya				;RAM-Laufwerk vorgeben.

;*** Suche nach DeskTop starten.
:DT_StartSearch		jsr	IsDTonDisk		;Desktop suchen...
			ldy	numDrives		;Nicht gefunden.
			cpy	#$02			;Mehr als 1 Laufwerk ?
			bcc	DT_NotFound		;Nein, weiter...
			lda	curDrive
			eor	#$01			;Zweites Laufwerk aktivieren.
			jsr	IsDTonDisk		;Desktop suchen...

;*** DeskTop-Diskette einlegen.
:DT_NotFound		lda	#>DlgBoxDTdisk		;Dialogbox öffnen.
			sta	r0H			;"Bitte Diskette mit DeskTop
			lda	#<DlgBoxDTdisk		; einlegen..."
			sta	r0L
			jsr	DoDlgBox
			lda	StartDTdrv		;Startlaufwerk einlesen und
			bne	DT_StartSearch		;Suche erneut starten.

;*** Neue DeskTop-Diskette öffnen.
:IsDTonDisk		jsr	SetDevice
			jsr	OpenDisk
			txa
			beq	:102
::101			rts

::102			sta	r0L
			lda	#>DeskTopName		;Zeiger auf Dateiname.
			sta	r6H
			lda	#<DeskTopName
			sta	r6L
			jsr	GetFile			;DeskTop-Datei laden.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	fileHeader+$5a		;Versions-Nr. testen.
			cmp	#$31
			bcc	:101
			bne	:103
			lda	fileHeader+$5c
			cmp	#$35
			bcc	:101

::103			lda	StartDTdrv		;Laufwerk zurücksetzen.
			jsr	SetDevice

			lda	#$00
			sta	r0L
			lda	fileHeader+$4c		;Zeiger auf Startadresse
			sta	r7H			;DeskTop-Programm im Speicher.
			lda	fileHeader+$4b
			sta	r7L

;*** Applikation starten.
:xStartAppl		sei				;IRQ sperren.
			cld				;"DEZIMAL"-Flag löschen.
			ldx	#$ff			;Stackzeiger löschen.
			txs
			jsr	SaveFileData
			jsr	GEOS_Init1
			jsr	xUseSystemFont
			jsr	LoadFileData
			ldx	r7H
			lda	r7L
			jmp	InitMLoop1

;*** Dialogbox: Bootdisk einlegen.
:DlgBoxDTdisk		b $81
			b $0b,$10,$16
			w SysMsg1
			b $0b,$10,$26
			w SysMsg2
			b $01,$11,$48
			b $00

:DeskTopName		b "DESK TOP",$00

:SysMsg1		b $18
			b "Bitte eine Diskette einlegen",$00
:SysMsg2		b "die deskTop enthält",$00

;*** GEOS-Variablen initialisieren.
:GEOS_Init1		jsr	SysVarInit1

;*** GEOS-RAM-Bereiche initialisieren.
:GEOS_Init2		lda	#>InitVarData
			sta	r0H
			lda	#<InitVarData
			sta	r0L
			jmp	xInitRam

;*** Initialisierungswerte für VIC.
:InitVICdata		b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$3b,$fb,$aa
			b $aa,$01,$08,$00
			b $38,$0f,$01,$00
			b $00,$00

;*** Kernal-Variablen initialisieren.
:SysVarInit1		lda	#$2f
			sta	zpage
			lda	#$36
			sta	CPU_DATA
			ldx	#$07
			lda	#$ff
::101			sta	KB_MultipleKey,x
			sta	KB_LastKeyTab ,x
			dex
			bpl	:101
			stx	keyMode
			stx	$dc02
			inx
			stx	keyBufPointer
			stx	MaxKeyInBuf
			stx	$dc03
			stx	$dc0f
			stx	$dd0f
			lda	$02a6
			beq	:102
			ldx	#$80
::102			stx	$dc0e
			stx	$dd0e
			lda	$dd00
			and	#$30
			ora	#$05
			sta	$dd00
			lda	#$3f
			sta	$dd02
			lda	#$7f
			sta	$dc0d
			sta	$dd0d
			lda	#>InitVICdata
			sta	r0H
			lda	#<InitVICdata
			sta	r0L
			ldy	#$1e
			jsr	VIC_Init
			jsr	SetKernalVec		;IO-Vektoren initialisieren.
			lda	#%00110000
			sta	CPU_DATA
			jmp	SetMseFullWin

;*** Grafikspeicher (Vorder- und
;    Hintergrund!) löschen.
:ClrDeskScrn		lda	#>SCREEN_BASE
			sta	r0H
			lda	#<SCREEN_BASE
			sta	r0L
			lda	#>BACK_SCR_BASE
			sta	r1H
			lda	#<BACK_SCR_BASE
			sta	r1L

			ldx	#$7d
::101			ldy	#$3f
::102			lda	#$55
			sta	(r0L),y
			sta	(r1L),y
			dey
			lda	#$aa
			sta	(r0L),y
			sta	(r1L),y
			dey
			bpl	:102

			clc
			lda	#$40
			adc	r0L
			sta	r0L
			bcc	:103
			inc	r0H

::103			clc
			lda	#$40
			adc	r1L
			sta	r1L
			bcc	:104
			inc	r1H

::104			dex
			bne	:101
			rts

;*** Kernal-Variablen initialisieren.
.SetKernalVec		ldx	#$20
::101			lda	$fd30  -1,x
			sta	irqvec -1,x
			dex
			bne	:101
			rts

;*** GEOS-Variablen löschen.
:xFirstInit		sei
			cld
			jsr	GEOS_Init1

			lda	#>xEnterDeskTop
			sta	EnterDeskTop+2
			lda	#<xEnterDeskTop
			sta	EnterDeskTop+1

			lda	#$7f
			sta	maxMouseSpeed
			lda	#$1e
			sta	minMouseSpeed

			lda	#$7f
			sta	mouseAccel

			lda	#$bf
			sta	screencolors
			sta	:101
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::101			b	$bf

			ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA

			lda	#$06
			sta	mob0clr
			sta	mob1clr

			lda	#$00
			sta	extclr
			stx	CPU_DATA

			ldy	#$3e
::102			lda	#$00
			sta	mousePicData,y
			dey
			bpl	:102

			ldx	#$18
::103			lda	$bf40       -1,x	;Daten für Mauszeiger ab
			sta	mousePicData-1,x	;":OrgMouseData" kopieren.
			dex
			bne	:103
			jmp	DefSprPoi		;Spritezeiger definieren.

;*** Speicherbereich löschen.
:xClearRam		lda	#$00
			sta	r2L

;*** Speicherbereich mit Byte füllen.
:xFillRam		lda	r0H
			beq	:102

			lda	r2L
			ldy	#$00
::101			sta	(r1L),y
			dey
			bne	:101
			inc	r1H
			dec	r0H
			bne	:101

::102			lda	r2L
			ldy	r0L
			beq	:104
			dey
::103			sta	(r1L),y
			dey
			cpy	#$ff
			bne	:103
::104			rts

;*** Speicherbereich initialisieren.
:xInitRam		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			ora	(r0L),y
			beq	:104
			lda	(r0L),y
			sta	r1H
			iny
			lda	(r0L),y
			sta	r2L
			iny
::101			tya
			tax
			lda	(r0L),y
			ldy	#$00
			sta	(r1L),y
			inc	r1L
			bne	:102
			inc	r1H
::102			txa
			tay
			iny
			dec	r2L
			bne	:101
			tya
			clc
			adc	r0L
			sta	r0L
			bcc	:103
			inc	r0H
::103			clv
			bvc	xInitRam
::104			rts

;*** GEOS-Routine aufrufen.
; AKKU = Zeiger auf LOW -Byte.
; xReg = Zeiger auf HIGH-Byte.
:xCallRoutine		cmp	#$00
			bne	:101
			cpx	#$00
			beq	:102
::101			sta	CallRoutVec+0
			stx	CallRoutVec+1
			jmp	(CallRoutVec)
::102			rts

;*** Inline-Routine beenden.
:xDoInlineReturn	clc
			adc	returnAddress+0
			sta	returnAddress+0
			bcc	:101
			inc	returnAddress+1
::101			plp
			jmp	(returnAddress)

;*** Sprite-Register initialisieren.
:VIC_Init		sty	r1L
			ldy	#$00
::101			lda	(r0L),y			;Neuen Wert für VIC-Register
			cmp	#$aa			;einlesen. Code $AA ?
			beq	:102			;Ja, übergehen.
			sta	mob0xpos,y		;Neuen VIC-Wert schreiben.
::102			iny
			cpy	r1L
			bne	:101
			rts

;*** Variablen zurückschreiben.
;    Aufruf durch ":StartAppl",
;    ":GetFile" und ":LdApplic".
:LoadFileData		lda	DA_ResetScrn
			sta	r10L
			lda	LoadFileMode
			sta	r0L
			and	#$01
			beq	:101
			lda	LoadBufAdr+1
			sta	r7H
			lda	LoadBufAdr+0
			sta	r7L
::101			lda	#>dataDiskName
			sta	r2H
			lda	#<dataDiskName
			sta	r2L
			lda	#>dataFileName
			sta	r3H
			lda	#<dataFileName
			sta	r3L
			rts

;*** Variablen zwischenspeichern.
;    Aufruf durch ":StartAppl",
;    ":GetFile" und ":LdApplic".
:SaveFileData		lda	r7H
			sta	LoadBufAdr+1
			lda	r7L
			sta	LoadBufAdr+0
			lda	r10L
			sta	DA_ResetScrn
			lda	r0L
			sta	LoadFileMode
			and	#%11000000		;Datenfile nachladen bzw.
			beq	:102			;ausdrucken ? Nein, weiter...
			ldy	#>dataDiskName		;Diskettenname retten.
			lda	#<dataDiskName
			ldx	#r2L
			jsr	:101
			ldy	#>dataFileName		;Dateiname retten.
			lda	#<dataFileName
			ldx	#r3L
::101			sty	r4H			;Datei-/Diskname retten.
			sta	r4L
			ldy	#r4L
			lda	#$10
			jsr	CopyFString
::102			rts

;*** X-Koordinaten (Pixel) auf CARDs
;    umrechnen. Die Bits im ersten und
;    letzten CARD werden in ":r8L" bzw.
;    ":r8H" gespeichert.
:GetCARDs		ldx	r11L			;Zeilenadresse berechnen.
			jsr	xGetScanLine
			lda	r4L
			and	#%00000111		;Anzahl zu setzender Bits im
			tax				;letzten CARD berechnen.
			lda	BitData4,x
			sta	r8H
			lda	r3L
			and	#%00000111		;Anzahl zu setzender Bits im
			tax				;ersten CARD berechnen.
			lda	BitData3,x
			sta	r8L
			lda	r3L
			and	#%11111000
			sta	r3L
			lda	r4L
			and	#%11111000
			sta	r4L
			rts

;*** Horizontale Linie zeichen.
;    r2L  = yLow
;    r3   = xLow
;    r4   = xHigh
;    Akku = Linienmuster
:xHorizontalLine	sta	r7L			;Linienmuster merken.
			lda	r3H			;X-Koordinaten speichern.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			jsr	GetCARDs		;Startwerte für aktuelle Zeile.

			ldy	r3L			;X-Koordinate in Grafikspeicher
			lda	r3H			;berechnen.
			beq	:101
			inc	r5H
			inc	r6H

::101			lda	r3H			;Erstes CARD gleich letztes
			cmp	r4H			;CARD ?
			bne	:102
			lda	r3L
			cmp	r4L
::102			beq	:105			;Ja, weiter...

			lda	r4L			;Länge der Grafikzeile in
			sec				;Pixel berechnen.
			sbc	r3L
			sta	r4L
			lda	r4H
			sbc	r3H
			sta	r4H

			lsr	r4H			;Anzahl Pixel in CARDs
			ror	r4L			;umrechnen.
			lsr	r4L
			lsr	r4L
			lda	r8L			;Linienmuster für erstes
			jsr	GetLinePattern		;CARD berechnen.

::103			sta	(r6L),y			;Linienmuster in Grafikspeicher
			sta	(r5L),y			;übertragen.
			tya				;Zeiger auf nähstes CARD
			clc				;berechnen.
			adc	#$08
			tay
			bcc	:104
			inc	r5H
			inc	r6H
::104			dec	r4L			;Zähler für CARDs korrigieren.
			beq	:106			;Fertig ? Ja, weiter...
			lda	r7L			;Lnienmuster einlesen und
			clv				;Grafikspeicher weiter
			bvc	:103			;beschreiben.

;*** Nur 1 CARD beschreiben.
::105			lda	r8L			;Bits im ersten und letzten
			ora	r8H			;CARD addieren.
			clv
			bvc	:107

::106			lda	r8H			;Linienmuster für letztes CARD.
::107			jsr	GetLinePattern		;Muster berechnen.

;*** Letes Byte in Zeile beschreiben.
:SetLastGrByt		sta	(r6L),y 			;Letztes Byte in Grafik-
			sta	(r5L),y			;speicher übertragen.

;*** Grafikroutinen beenden.
;    X-Koordinaten zurückschreiben.
:ExitGrafxRout		pla
			sta	r4L
			pla
			sta	r4H
			pla
			sta	r3L
			pla
			sta	r3H
			rts

;*** Linienmuster berechnen.
:GetLinePattern		sta	r11H
			and	(r6L),y
			sta	r7H
			lda	r11H
			eor	#%11111111
			and	r7L
			ora	r7H
			rts

;*** Horizontale Linie invertieren.
;    r2L      = yLow
;    r3 /r4   = xLow/xHigh
:xInvertLine		lda	r3H			;X-Koordinaten speichern.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			jsr	GetCARDs		;Startwerte für aktuelle Zeile.

			ldy	r3L			;X-Koordinate in Grafikspeicher
			lda	r3H			;berechnen.
			beq	:101
			inc	r5H
			inc	r6H

::101			lda	r3H			;Erstes CARD gleich letztes
			cmp	r4H			;CARD ?
			bne	:102
			lda	r3L
			cmp	r4L
::102			beq	:105			;Ja, weiter...

			lda	r4L			;Länge der Grafikzeile in
			sec				;Pixel berechnen.
			sbc	r3L
			sta	r4L
			lda	r4H
			sbc	r3H
			sta	r4H

			lsr	r4H			;Anzahl Pixel in CARDs
			ror	r4L			;umrechnen.
			lsr	r4L
			lsr	r4L
			lda	r8L			;Linienmuster für erstes
			eor	(r5L),y			;CARD berechnen.

::103			eor	#%11111111
			sta	(r6L),y			;Linienmuster in Grafikspeicher
			sta	(r5L),y			;übertragen.
			tya				;Zeiger auf nähstes CARD
			clc				;berechnen.
			adc	#$08
			tay
			bcc	:104
			inc	r5H
			inc	r6H
::104			dec	r4L			;Zähler für CARDs korrigieren.
			beq	:106			;Fertig ? Ja, weiter...
			lda	(r5L),y			;Lnienmuster einlesen und
			clv				;Grafikspeicher weiter
			bvc	:103			;beschreiben.

;*** Nur 1 CARD beschreiben.
::105			lda	r8L			;Bits im ersten und letzten
			ora	r8H			;CARD addieren.
			clv
			bvc	:107

::106			lda	r8H
::107			eor	#%11111111		;Muster für letztes Grafik-
			eor	(r5L),y			;CARD berechnen.
			jmp	SetLastGrByt

;*** Zeile aus Vordergrund in Hinter-
;    grund kopieren. Wird von Routine
;    ":ImprintRectangle" benötigt.
:ImprintRecLine		lda	r3H			;X-Koordinaten speichern.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			lda	dispBufferOn		;Bildschirm-Flag speichern.
			pha
			ora	#%11000000		;Grafikdaten in Vorder- und
			sta	dispBufferOn		;Hintergrundspeicher schreiben.
			jsr	GetCARDs		;Startwerte für aktuelle Zeile.
			pla
			sta	dispBufferOn		;Bildschirm-Flag zurücksetzen.

			lda	r5L			;Startadressen der Linien im
			ldy	r6L			;Vorder- und Hintergrund-
			sta	r6L			;Grafikspeicher vertauschen.
			sty	r5L
			lda	r5H
			ldy	r6H
			sta	r6H
			sty	r5H
			clv
			bvc	MovGrafxData

;*** Horizontale Linie aus dem Hinter-
;    grund in den Vordergrund kopieren.
;    r2L      = yLow
;    r3 /r4   = xLow/xHigh
:xRecoverLine		lda	r3H			;X-Koordinaten speichern.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha
			lda	dispBufferOn		;Bildschirm-Flag speichern.
			pha
			ora	#%11000000		;Grafikdaten in Vorder- und
			sta	dispBufferOn		;Hintergrundspeicher schreiben.
			jsr	GetCARDs		;Startwerte für aktuelle Zeile.
			pla
			sta	dispBufferOn		;Bildschirm-Flag zurücksetzen.

;*** Rechteck zwischen Vorder- und
;    Hintergrundgrafik kopieren.
:MovGrafxData		ldy	r3L			;X-Koordinate in Grafikspeicher
			lda	r3H			;berechnen.
			beq	:101
			inc	r5H
			inc	r6H

::101			lda	r3H
			cmp	r4H
			bne	:102
			lda	r3L
			cmp	r4L
::102			beq	:105

			lda	r4L			;Länge der Grafikzeile in
			sec				;Pixel berechnen.
			sbc	r3L
			sta	r4L
			lda	r4H
			sbc	r3H
			sta	r4H

			lsr	r4H			;Anzahl Pixel in CARDs
			ror	r4L			;umrechnen.
			lsr	r4L
			lsr	r4L
			lda	r8L			;Erstes Card erzeugen.
			jsr	LinkGrafxMem

::103			tya				;Zeiger auf nähstes CARD
			clc				;berechnen.
			adc	#$08
			tay
			bcc	:104
			inc	r5H
			inc	r6H
::104			dec	r4L			;Zähler für CARDs korrigieren.
			beq	:106			;Fertig ? Ja, weiter...

			lda	(r6L),y			;Byte aus Speicher #1 in
			sta	(r5L),y			;Speicher #2 kopieren.
			clv
			bvc	:103			;Nächstes Byte kopieren.

;*** Nur 1 CARD beschreiben.
::105			lda	r8L			;Bits im ersten und letzten
			ora	r8H			;CARD addieren.
			clv
			bvc	:107

::106			lda	r8H			;Linienmuster für letztes CARD.
::107			jsr	LinkGrafxMem		;Muster berechnen.
			jmp	ExitGrafxRout		;Routine abschließen.

;*** Byte aus Vordergrund mit Byte
;    aus Hintergrund verknüpfen.
:LinkGrafxMem		sta	r7L
			and	(r5L),y
			sta	r7H
			lda	r7L
			eor	#%11111111
			and	(r6L),y
			ora	r7H
			sta	(r5L),y
			rts

;*** Vertikale Linie zeichen.
;    r3L/r3H  = yLow/yHigh
;    r4       =      xHigh
;    Akku = Linienmuster
:xVerticalLine		sta	r8L			;Linienmuster merken.

			lda	r4L			;LOW-Byte der X-Koordinate
			pha				;zwischenspeichern.
			and	#%00000111
			tax
			lda	BitData1,x		;Zeiger auf Bit in Byte
			sta	r7H			;berechnen und merken.

			lda	r4L			;X-Koordinate in 8-Byte-Wert
			and	#%11111000		;umrechnen.
			sta	r4L

			ldy	#$00
			ldx	r3L			;Zeiger auf Bytereihe in CARD.

::101			stx	r7L			;Aktuelle Zeile merken.
			jsr	xGetScanLine		;Zeilenadresse berechnen.

			lda	r4L			;Zeiger auf CARD-Spalte in
			clc				;Vordergrund-Grafikspeicher
			adc	r5L			;berechnen.
			sta	r5L
			lda	r4H
			adc	r5H
			sta	r5H

			lda	r4L			;Zeiger auf CARD-Spalte in
			clc				;Hintergrund-Grafikspeicher
			adc	r6L			;berechnen.
			sta	r6L
			lda	r4H
			adc	r6H
			sta	r6H

			lda	r7L			;Aktuelle Zeile einlesen.
			and	#%00000111		;8-Bit-Wert ermitteln.
			tax
			lda	BitData1,x		;Zu setzendes Bit berechnen.
			and	r8L			;Mit Linienmuster verknüpfen.
			bne	:102			;Bit setzen ? Ja, weiter...

			lda	r7H			;Bit an X-Koordinate löschen.
			eor	#%11111111
			and	(r6L),y
			clv
			bvc	:103

::102			lda	r7H			;Bit an X-Koordinate setzen.
			ora	(r6L),y
::103			sta	(r6L),y
			sta	(r5L),y
			ldx	r7L
			inx
			cpx	r3H
			beq	:101
			bcc	:101
			pla
			sta	r4L
			rts

;*** Inline: Rechteck zeichen.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_Rectangle		jsr	GetInlineData		;Inline-Daten einlesen.
			jsr	xRectangle		;Rechteck zeichnen.
			php
			lda	#$07			;Routine beenden.
			jmp	DoInlineReturn

;*** Rechteck zeichen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xRectangle		lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.
::101			lda	r11L
			and	#$07
			tay				;Linienmuster für aktuelle
			lda	(curPattern),y		;Zeile einlesen.
			jsr	xHorizontalLine		;Horizontale Linie zeichnen.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:101			;Nein, weiter...
			rts

;*** Rechteck invertieren.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xInvertRectangle	lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.
::101			jsr	xInvertLine		;Linie invertieren.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:101			;Nein, weiter...
			rts

;*** Inline: Rechteck herstellen.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_RecoverRec		jsr	GetInlineData		;Inline-Daten einlesen.
			jsr	xRecoverRec		;Rechteck kopieren.
			php
			lda	#$07			;Routine beenden.
			jmp	DoInlineReturn

;*** Rechteck herstellen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xRecoverRec		lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.

::101			jsr	xRecoverLine		;Zeile kopieren.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:101			;Nein, weiter...
			rts

;*** Inline: Rechteck speichern.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_ImprintRec		jsr	GetInlineData		;Inline-Daten einlesen.
			jsr	xImprintRec		;Rechteck kopieren.
			php
			lda	#$07			;Routine beenden.
			jmp	DoInlineReturn

;*** Rechteck speichern.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xImprintRec		lda	r2L			;Startzeile als Anfangswert
			sta	r11L			;für Rectangle setzen.

::101			jsr	ImprintRecLine		;Zeile kopieren.
			lda	r11L
			inc	r11L
			cmp	r2H			;Letzte Zeile erreicht ?
			bne	:101			;Nein, weiter...
			rts
;*** Inline: Rechteck herstellen.
;    b yLow,yHigh
;    w xLow,xHigh
:xi_FrameRec		jsr	GetInlineData		;Inline-Daten einlesen.
			iny
			lda	(returnAddress),y	;Linienmuster einlesen.
			jsr	xFrameRectangle		;Rahmen zeichnen.
			php
			lda	#$08			;Routine beenden.
			jmp	DoInlineReturn

;*** Inline: Rechteck herstellen.
;    r2L/r2H = yLow/yHigh
;    r3 /r4  = xLow/xHigh
:xFrameRectangle	sta	r9H			;Linienmuster merken.

			ldy	r2L			;Oberen Rand zeichnen.
			sty	r11L
			jsr	xHorizontalLine

			lda	r2H			;Unteren Rand zeichnen.
			sta	r11L
			lda	r9H
			jsr	xHorizontalLine

			lda	r3H			;X-Koordinaten merken.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha

			lda	r3H			;X-Koordinate auf Linken Rand
			sta	r4H			;setzen.
			lda	r3L
			sta	r4L
			lda	r2H
			sta	r3H
			lda	r2L
			sta	r3L
			lda	r9H			;Linken Rand zeichnen.
			jsr	xVerticalLine
			pla				;X-Koordinate für rechten
			sta	r4L			;Rand wiederherstellen.
			pla
			sta	r4H
			lda	r9H			;Linken Rand zeichnen.
			jsr	xVerticalLine
			pla				;X-Koordinate für rechten
			sta	r3L			;Rand wiederherstellen.
			pla
			sta	r3H
			rts

;*** Inline-Grafikdaten einlesen.
;    Aufruf über JSR...
:GetInlineData		pla				;Rücksprungadresse vom
			sta	r5L			;Stapel holen.
			pla
			sta	r5H
			pla				;Startadresse der Inline-Daten
			sta	returnAddress+0		;einlesen und speichern.
			pla
			sta	returnAddress+1

			ldy	#$01
			lda	(returnAddress),y	;yOben einlesen.
			sta	r2L
			iny
			lda	(returnAddress),y	;yUnten einlesen.
			sta	r2H
			iny
			lda	(returnAddress),y	;xLinks einlesen.
			sta	r3L
			iny
			lda	(returnAddress),y
			sta	r3H
			iny
			lda	(returnAddress),y	;xRechts einlesen.
			sta	r4L
			iny
			lda	(returnAddress),y
			sta	r4H

			lda	r5H			;Rücksprungadresse auf Stapel
			pha				;zurückschreiben.
			lda	r5L
			pha
			rts				;Rücksprung.

;*** Inline: Grafikbefehle ausführen.
:xi_GraphicsStrg	pla				;Zeiger auf Inline-Daten
			sta	r0L			;für ":GraphicsString".
			pla
			inc	r0L
			bne	:101
			clc
			adc	#$01
::101			sta	r0H
			jsr	xGraphicsString		;Grafikbefehle ausführen.
			jmp	(r0)			;Zum Programm zurück.

;*** Inline: Grafikbefehle ausführen.
;    r0 = Zeiger auf Tabelle.
:xGraphicsString	jsr	Get1Byte
			beq	:101
			tay
			dey
			lda	GS_RoutTabL,y
			ldx	GS_RoutTabH,y
			jsr	CallRoutine
			clv
			bvc	xGraphicsString
::101			rts

;*** Einsprungadressen für
;    GraphicsString-Befehle.
:GS_RoutTabL		b < GS_MOVEPENTO
			b < GS_LINETO
			b < GS_RECTANGLETO
			b < GS_PENFILL
			b < GS_NEWPATTERN
			b < GS_PUTSTRING
			b < GS_FRAMERECTO
			b < GS_PENXDELTA
			b < GS_PENYDELTA
			b < GS_PENXYDELTA

:GS_RoutTabH		b > GS_MOVEPENTO
			b > GS_LINETO
			b > GS_RECTANGLETO
			b > GS_PENFILL
			b > GS_NEWPATTERN
			b > GS_PUTSTRING
			b > GS_FRAMERECTO
			b > GS_PENXDELTA
			b > GS_PENYDELTA
			b > GS_PENXYDELTA

;*** GraphicsString: MOVEPENTO
:GS_MOVEPENTO		jsr	Get3Bytes
			sta	GS_Ypos
			stx	GS_XposL
			sty	GS_XposH
			rts

;*** GraphicsString: LINETO
:GS_LINETO		lda	GS_XposH
			sta	r3H
			lda	GS_XposL
			sta	r3L
			lda	GS_Ypos
			sta	r11L
			jsr	GS_MOVEPENTO
			sta	r11H
			stx	r4L
			sty	r4H
			sec
			lda	#$00
			jmp	xDrawLine

;*** GraphicsString: RECTANGLETO
:GS_RECTANGLETO		jsr	GS_GetXYpar
			jmp	xRectangle

;*** GraphicsString: PENFILL
:GS_PENFILL		rts

;*** GraphicsString: NEWPATTERN
:GS_NEWPATTERN		jsr	Get1Byte
			jmp	xSetPattern

;*** GraphicsString: ESC_PUTSTRING
:GS_PUTSTRING		jsr	Get1Byte
			sta	r11L
			jsr	Get1Byte
			sta	r11H
			jsr	Get1Byte
			sta	r1H
			jsr	xPutString
			rts

;*** GraphicsString: FRAME_RECTO
:GS_FRAMERECTO		jsr	GS_GetXYpar
			lda	#$ff
			jmp	xFrameRectangle

;*** GraphicsString: PENXYDELTA
:GS_PENXYDELTA		ldx	#$01
			bne	GS_SetXDelta

;*** GraphicsString: PENXDELTA
:GS_PENXDELTA		ldx	#$00
:GS_SetXDelta		ldy	#$00
			lda	(r0L),y
			iny
			clc
			adc	GS_XposL
			sta	GS_XposL
			lda	(r0L),y
			iny
			adc	GS_XposH
			sta	GS_XposH
			txa
			beq	GS_ExitPenDelta
			bne	GS_SetYDelta

;*** GraphicsString: PENYDELTA
:GS_PENYDELTA		ldy	#$00
:GS_SetYDelta		lda	(r0L),y
			iny
			clc
			adc	GS_Ypos
			sta	GS_Ypos
			iny
:GS_ExitPenDelta	tya
			clc
			adc	r0L
			sta	r0L
			bcc	:101
			inc	r0H
::101			rts

;*** GraphicsString:
;    Parameter einlesen (Word,Byte)
:GS_GetXYpar		jsr	Get3Bytes
			cmp	GS_Ypos
			bcs	:101
			sta	r2L
			pha
			lda	GS_Ypos
			sta	r2H
			clv
			bvc	:102

::101			sta	r2H
			pha
			lda	GS_Ypos
			sta	r2L

::102			pla
			sta	GS_Ypos
			cpy	GS_XposH
			beq	:103
			bcs	:105
::103			bcc	:104
			cpx	GS_XposL
			bcs	:105

::104			stx	r3L
			sty	r3H
			lda	GS_XposH
			sta	r4H
			lda	GS_XposL
			sta	r4L
			clv
			bvc	:106

::105			stx	r4L
			sty	r4H
			lda	GS_XposH
			sta	r3H
			lda	GS_XposL
			sta	r3L
::106			stx	GS_XposL
			sty	GS_XposH
			rts

;*** Neues Füllmuster setzen.
:xSetPattern		asl
			asl
			asl
			adc	#<GEOS_Patterns
			sta	curPattern+0
			lda	#$00
			adc	#>GEOS_Patterns
			sta	curPattern+1
			rts

;*** 3 Bytes über ":r0" einlesen.
:Get3Bytes		jsr	Get1Byte
			tax
			jsr	Get1Byte
			sta	r2L
			jsr	Get1Byte
			ldy	r2L
			rts

;*** 1 Byte über ":r0" einlesen.
:Get1Byte		ldy	#$00
			lda	(r0L),y
			inc	r0L
			bne	:101
			inc	r0H
::101			cmp	#$00
			rts

;*** Zeilenadresse berechnen.
:xGetScanLine		txa				;Nummer der Bildschirmzeile
			pha				;zwischenspeichern.
			pha
			and	#%00000111		;Zeile innerhalb eines CARDs
			sta	r6H			;ermitteln.
			pla
			lsr
			lsr
			lsr
			tax
			bit	dispBufferOn
			bpl	:102			; -> Vordergrund nicht aktiv.
			bit	dispBufferOn
			bvs	:101			; -> Hintergrund aktiv.
			lda	GrfxLinAdrL,x		;Nur Vordergrund.
			ora	r6H
			sta	r5L
			lda	GrfxLinAdrH,x
			sta	r5H
			lda	r5H
			sta	r6H
			lda	r5L
			sta	r6L
			pla
			tax
			rts

::101			lda	GrfxLinAdrL,x		;Vorder- und Hintergrund.
			ora	r6H
			sta	r5L
			sta	r6L
			lda	GrfxLinAdrH,x
			sta	r5H
			sec
			sbc	#$40
			sta	r6H
			pla
			tax
			rts

::102			bit	dispBufferOn
			bvc	:103
			lda	GrfxLinAdrL,x		;Nur Hintergrund.
			ora	r6H
			sta	r6L
			lda	GrfxLinAdrH,x
			sec
			sbc	#$40
			sta	r6H
			lda	r6H
			sta	r5H
			lda	r6L
			sta	r5L
			pla
			tax
			rts

::103			lda	#$00			;Bildschirmmitte.
			sta	r5L
			sta	r6L
			lda	#$af
			sta	r5H
			sta	r6H
			pla
			tax
			rts

;*** Startadressen der 25 Bildschirm-
;    zeilen im Grafikspeicher.
:GrfxLinAdrL		b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00,$40,$80,$c0
			b $00

:GrfxLinAdrH		b $a0,$a1,$a2,$a3
			b $a5,$a6,$a7,$a8
			b $aa,$ab,$ac,$ad
			b $af,$b0,$b1,$b2
			b $b4,$b5,$b6,$b7
			b $b9,$ba,$bb,$bc
			b $be

;*** Prozesstabelle onitialisieren.
:xInitProcesses		ldx	#$00			;Prozesse in Tabelle löschen.
			stx	MaxProcess
			sta	r1L			;Anzahl Prozesse merken.
			sta	r1H			;Zähler für Prozesse auf Start.
			tax
			lda	#%00100000		;Alle Prozesse auf "FROZEN"
::101			sta	ProcStatus-1,x		;zurückstellen.
			dex
			bne	:101

			ldy	#$00
::102			lda	(r0L),y			;Prozess-Routine in Tabelle.
			sta	ProcRout  +0,x
			iny
			lda	(r0L),y
			sta	ProcRout  +1,x
			iny
			lda	(r0L),y			;Prozess-Zähler in Tabelle.
			sta	ProcDelay +0,x
			iny
			lda	(r0L),y
			sta	ProcDelay +1,x
			iny
			inx
			inx
			dec	r1H			;Alle Prozesse eingelesen ?
			bne	:102			;Nein, weiter...
			lda	r1L			;Anzahl Prozesse merken.
			sta	MaxProcess
			rts

;*** Prozesse ausführen.
:ExecProcTab		ldx	MaxProcess		;Prozesse aktiv ?
			beq	:103			;Nein, weiter...
			dex				;Zeiger auf letzten Prozess.
::101			lda	ProcStatus,x		;Aktueller Prozess aktiv ?
			bpl	:102			;Nein, weiter...
			and	#%01000000		;Prozess-Pause aktiv ?
			bne	:102			;Ja, übergehen.
			lda	ProcStatus,x
			and	#%01111111
			sta	ProcStatus,x
			txa
			pha
			asl
			tax
			lda	ProcRout+0,x		;Adresse für Prozessroutine
			sta	r0L			;einlesen.
			lda	ProcRout+1,x
			sta	r0H
			jsr	ExecProcRout		;Prozessroutine ausführen.
			pla
			tax
::102			dex				;Zeiger auf nächsten
			bpl	:101			;Prozess.
::103			rts

;*** Prozess-Routine ausführen.
:ExecProcRout		jmp	(r0)

;*** Prozesstabelle korrigieren.
:PrepProcData		lda	#$00
			tay
			tax
			cmp	MaxProcess		;Prozesse definiert ?
			beq	:104			;Nein, Ende...

::101			lda	ProcStatus,x
			and	#%00110000		;Prozess eingefroren ?
			bne	:103			;Ja, übergehen.

			lda	ProcCurDelay+0,y	;Zähler korrigieren.
			bne	:102			;(Zähler besteht aus 1 Word!)
			pha
			lda	ProcCurDelay+1,y
			sec
			sbc	#$01
			sta	ProcCurDelay+1,y
			pla
::102			sec
			sbc	#$01
			sta	ProcCurDelay+0,y
			ora	ProcCurDelay+1,y	;Zähler = $0000 ?
			bne	:103			;Nein, weiter...

			jsr	ResetProcDelay		;Prozess aktivieren.

			lda	ProcStatus,x
			ora	#%10000000
			sta	ProcStatus,x

::103			iny
			iny
			inx
			cpx	MaxProcess		;Alle Prozesse geprüft ?
			bne	:101

::104			rts

;*** Prozess wieder starten.
:xRestartProcess	lda	ProcStatus,x
			and	#%10011111
			sta	ProcStatus,x
:ResetProcDelay		txa
			pha
			asl
			tax
			lda	ProcDelay   +0,x
			sta	ProcCurDelay+0,x
			lda	ProcDelay   +1,x
			sta	ProcCurDelay+1,x
			pla
			tax
			rts

;*** Prozess sofort starten.
:xEnableProcess		lda	ProcStatus,x
			ora	#%10000000
:NewProcStatus		sta	ProcStatus,x
			rts

;*** Prozess nicht mehr ausführen.
:xBlockProcess		lda	ProcStatus,x
			ora	#%01000000
			clv
			bvc	NewProcStatus

;*** Prozess wieder ausführen.
:xUnblockProcess	lda	ProcStatus,x
			and	#%10111111
			clv
			bvc	NewProcStatus

;*** Prozess-Zähler einfrieren.
:xFreezeProcess		lda	ProcStatus,x
			ora	#%00100000
			clv
			bvc	NewProcStatus

;*** Prozess-Zähler freigeben.
:xUnfreezeProcess	lda	ProcStatus,x
			and	#%11011111
			clv
			bvc	NewProcStatus

;*** Sleep-Wartezeit korrigieren.
:DecSleepTime		ldx	MaxSleep		;Sleep-Routinen aktiv ?
			beq	:104			;Nein, Ende...
			dex
::101			lda	SleepTimeL,x		;Wartezeit (Word)
			bne	:102			;korrigieren.
			ora	SleepTimeH,x
			beq	:103
			dec	SleepTimeH,x
::102			dec	SleepTimeL,x
::103			dex
			bpl	:101
::104			rts

;*** Alle Sleep-Routinen ausführen
;    wenn Wartezeit = $0000.
:ExecSleepJobs		ldx	MaxSleep		;Sleep-Routinen aktiv ?
			beq	:103			;Nein, Ende...
			dex
::101			lda	SleepTimeL,x
			ora	SleepTimeH,x		;Wartezeit abgelaufen ?
			bne	:102			;Nein, weiter...
			lda	SleepRoutH,x		;Sleep-Routine einlesen.
			sta	r0H
			lda	SleepRoutL,x
			sta	r0L
			txa
			pha
			jsr	Del1stSleep		;Ersten Eintrag löschen.
			jsr	DoSleepJob		;Sleep-Routine aufrufen.
			pla
			tax
::102			dex
			bpl	:101			;Nächsten Sleep testen.
::103			rts

;*** SLEEP-Routine aufrufen.
:DoSleepJob		inc	r0L
			bne	:101
			inc	r0H
::101			jmp	(r0)

;*** Eintrag aus SLEEP-Tabelle löschen.
:Del1stSleep		php
			sei
::101			inx
			cpx	MaxSleep
			beq	:102
			lda	SleepTimeL  ,x
			sta	SleepTimeL-1,x
			lda	SleepTimeH  ,x
			sta	SleepTimeH-1,x
			lda	SleepRoutL  ,x
			sta	SleepRoutL-1,x
			lda	SleepRoutH  ,x
			sta	SleepRoutH-1,x
			clv
			bvc	:101
::102			dec	MaxSleep
			plp
			rts

;*** GEOS-Pause einlegen.
:xSleep			php
			pla
			tay
			sei
			ldx	MaxSleep
			lda	r0L
			sta	SleepTimeL,x
			lda	r0H
			sta	SleepTimeH,x
			pla
			sta	SleepRoutL,x
			pla
			sta	SleepRoutH,x
			inc	MaxSleep
			tya
			pha
			plp
			rts

;*** Spritedaten in Spritespeicher
;    kopieren.
:xDrawSprite		ldy	r3L
			lda	sprPicAdrL,y
			sta	r5L
			lda	sprPicAdrH,y
			sta	r5H

			ldy	#$3f
::101			lda	(r4L),y
			sta	(r5L),y
			dey
			bpl	:101
			rts

;*** Zeiger auf Sprite-Speicher.
:sprPicAdrL		b < spr0pic
			b < spr1pic
			b < spr2pic
			b < spr3pic
			b < spr4pic
			b < spr5pic
			b < spr6pic
			b < spr7pic

:sprPicAdrH		b > spr0pic
			b > spr1pic
			b > spr2pic
			b > spr3pic
			b > spr4pic
			b > spr5pic
			b > spr6pic
			b > spr7pic

;*** Sprite positionieren.
:xPosSprite		lda	CPU_DATA
			pha

			lda	#%00110101
			sta	CPU_DATA

			lda	r3L
			asl
			tay
			lda	r5L

			clc
			adc	#$32
			sta	mob0ypos,y
			lda	r4L
			clc
			adc	#$18
			sta	r6L
			lda	r4H
			adc	#$00
			sta	r6H

			lda	r6L
			sta	mob0xpos,y

			ldx	r3L
			lda	BitData2,x
			eor	#$ff
			and	msbxpos
			tay
			lda	#$01
			and	r6H
			beq	:101
			tya
			ora	BitData2,x
			tay
::101			sty	msbxpos

			pla
			sta	CPU_DATA
			rts

;*** Sprite einschalten.
:xEnablSprite		ldx	r3L
			lda	BitData2,x
			tax
			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA
			txa
			ora	mobenble
			sta	mobenble
			pla
			sta	CPU_DATA
			rts

;*** Sprite abschalten.
:xDisablSprite		ldx	r3L
			lda	BitData2,x
			eor	#$ff
			pha
			ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA
			pla
			and	mobenble
			sta	mobenble
			stx	CPU_DATA
			rts

;*** ZeroPage-Adresse * 2^y
:xDShiftLeft		dey
			bmi	:101
			asl	zpage+0,x
			rol	zpage+1,x
			jmp	xDShiftLeft
::101			rts

;*** ZeroPage-Adresse : 2^y
:xDShiftRight		dey
			bmi	:101
			lsr	zpage+1,x
			ror	zpage+0,x
			jmp	xDShiftRight
::101			rts

;*** Zwei Bytes multiplizieren.
:xBBMult		lda	zpage,y
			sta	r8H
			sty	r8L
			ldy	#$08
			lda	#$00
::101			lsr	r8H
			bcc	:102
			clc
			adc	zpage+0,x
::102			ror
			ror	r7L
			dey
			bne	:101
			sta	zpage+1,x
			lda	r7L
			sta	zpage+0,x
			ldy	r8L
			rts

;*** Bytes mit Word multiplizieren.
:xBMult			lda	#$00
			sta	zpage+1,y

;*** Word mit Word multiplizieren.
:xDMult			lda	#$10
			sta	r8L
			lda	#$00
			sta	r7L
			sta	r7H
::101			lsr	zpage+1,x
			ror	zpage+0,x
			bcc	:102
			lda	r7L
			clc
			adc	zpage+0,y
			sta	r7L
			lda	r7H
			adc	zpage+1,y
::102			lsr
			sta	r7H
			ror	r7L
			ror	r6H
			ror	r6L
			dec	r8L
			bne	:101
			lda	r6L
			sta	zpage+0,x
			lda	r6H
			sta	zpage+1,x
			rts

;*** Ohne Vorzeichen dividieren.
:xDdiv			lda	#$00
			sta	r8L
			sta	r8H
			lda	#$10
			sta	r9L
::101			asl	zpage+0,x
			rol	zpage+1,x
			rol	r8L
			rol	r8H
			lda	r8L
			sec
			sbc	zpage+0,y
			sta	r9H
			lda	r8H
			sbc	zpage+1,y
			bcc	:102
			inc	zpage+0,x
			sta	r8H
			lda	r9H
			sta	r8L
::102			dec	r9L
			bne	:101
			rts

;*** Mit Vorzeichen dividieren.
:xDSdiv			lda	zpage+1,x
			eor	zpage+1,y
			php
			jsr	xDabs
			stx	r8L
			tya
			tax
			jsr	xDabs
			ldx	r8L
			jsr	xDdiv
			plp
			bpl	:101
			jsr	xDnegate
::101			rts

;*** Vorzeichen ermitteln.
:xDabs			lda	zpage+1,x
			bmi	xDnegate
			rts

;*** Word negieren.
:xDnegate		lda	zpage+1,x
			eor	#$ff
			sta	zpage+1,x
			lda	zpage+0,x
			eor	#$ff
			sta	zpage+0,x
			inc	zpage+0,x
			bne	:101
			inc	zpage+1,x
::101			rts

;*** Word-Adresse -1.
:xDdec			lda	zpage+0,x
			bne	:101
			dec	zpage+1,x
::101			dec	zpage+0,x
			lda	zpage+0,x
			ora	zpage+1,x
			rts

;*** Zufallszahl berechnen.
:xGetRandom		inc	random+0
			bne	:101
			inc	random+1
::101			asl	random+0
			rol	random+1
			bcc	:103
			clc
			lda	#$0f
			adc	random+0
			sta	random+0
			bcc	:102
			inc	random+1
::102			rts

::103			lda	random+1
			cmp	#$ff
			bcc	:104
			lda	random+0
			sec
			sbc	#$f1
			bcc	:104
			sta	random+0
			lda	#$00
			sta	random+1
::104			rts

;*** String kopieren. (Akku =$00 bis zum $00-Byte, <>$00 = Anzahl Zeichen).
:xCopyString		lda	#$00
:xCopyFString		stx	:101 +1
			sty	:102 +1
			tax
			ldy	#$00
::101			lda	(r4L),y
::102			sta	(r5L),y
			bne	:103
			txa
			beq	:104
::103			iny
			beq	:104
			txa
			beq	:101
			dex
			bne	:101
::104			rts

;*** Inline: Speicher verschieben.
:xi_MoveData		pla
			sta	returnAddress+0
			pla
			sta	returnAddress+1
			jsr	Get2Word1Byte
			iny
			lda	(returnAddress),y
			sta	r2H
			jsr	xMoveData
			php
			lda	#$07
			jmp	DoInlineReturn

;*** 2 Words und 1 Byte aus Programmtext einlesen.
:Get2Word1Byte		ldy	#$01
			lda	(returnAddress),y
			sta	r0L
			iny
			lda	(returnAddress),y
			sta	r0H
			iny
			lda	(returnAddress),y
			sta	r1L
			iny
			lda	(returnAddress),y
			sta	r1H
			iny
			lda	(returnAddress),y
			sta	r2L
			rts

;*** Speicherbereich veschieben.
:xMoveData		lda	r2L
			ora	r2H			;Anzahl Bytes = $0000 ?
			beq	:107			;Ja, -> Keine Funktion.

			lda	r0H			;Register zwischenspeichern.
			pha
			lda	r0L
			pha
			lda	r1H
			pha
			lda	r2H
			pha
			lda	r3L
			pha

			lda	sysRAMFlg		;MoveData über REU ?
			bpl	:101			;Nein, weiter...

			lda	r1H
			pha
			lda	#$00
			sta	r1H
			sta	r3L			;Speicherbereich aus RAM
			jsr	StashRAM		;in REU übertragen.
			pla
			sta	r0H
			lda	r1L
			sta	r0L			;Speicherbereich aus REU
			jsr	FetchRAM		;in RAM zurückschreiben.
			clv
			bvc	:106			;Ende ":MoveData".

::101			lda	r0H
			cmp	r1H
			bne	:102
			lda	r0L
			cmp	r1L
::102			bcs	:103			; -> Daten Aufwärts kopieren.
			bcc	:108			; -> Daten Abwärts kopieren.

;*** ":MoveData" (Daten Aufwärts kopieren).
::103			ldy	#$00
			lda	r2H
			beq	:105
::104			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:104
			inc	r0H
			inc	r1H
			dec	r2H
			bne	:104
::105			cpy	r2L
			beq	:106
			lda	(r0L),y
			sta	(r1L),y
			iny
			clv
			bvc	:105

;*** Ende ":MoveData", Register wiederherstellen.
::106			pla
			sta	r3L
			pla
			sta	r2H
			pla
			sta	r1H
			pla
			sta	r0L
			pla
			sta	r0H
::107			rts

;*** ":MoveData" (Daten Abwärts kopieren).
::108			clc
			lda	r2H
			adc	r0H
			sta	r0H
			clc
			lda	r2H
			adc	r1H
			sta	r1H
			ldy	r2L
			beq	:110
::109			dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	:109
::110			dec	r0H
			dec	r1H
			lda	r2H
			beq	:106
::111			dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	:111
			dec	r2H
			clv
			bvc	:110

;*** String + NULL-Byte vergleichen.
;    Akku =  $00, Ende durch $00-Byte.
;    Akku <> $00, Anzahl Zeichen.
:xCmpString		lda	#$00
:xCmpFString		stx	:101 +1
			sty	:102 +1
			tax
			ldy	#$00
::101			lda	(r5L),y
::102			cmp	(r1L),y
			bne	:104
			cmp	#$00
			bne	:103
			txa
			beq	:104
::103			iny
			beq	:104
			txa
			beq	:101
			dex
			bne	:101
			lda	#$00
::104			rts

;*** Ist Maus in Bildschirmbereich ?
:xIsMseInRegion		lda	mouseYPos
			cmp	r2L
			bcc	:105
			cmp	r2H
			beq	:101
			bcs	:105
::101			lda	mouseXPos+1
			cmp	r3H
			bne	:102
			lda	mouseXPos+0
			cmp	r3L
::102			bcc	:105
			lda	mouseXPos+1
			cmp	r4H
			bne	:103
			lda	mouseXPos+0
			cmp	r4L
::103			beq	:104
			bcs	:105
::104			lda	#$ff
			rts
::105			lda	#$00
			rts

;*** PANIC!-Routine.
:xPanic			pla				;Abbruch-Adresse einlesen.
			sta	r0L
			pla
			sta	r0H

			sec				;Programm-Adresse
			lda	r0L			;berechnen.
			sbc	#$02
			sta	r0L
			lda	r0H
			sbc	#$00
			sta	r0H

			lda	r0H			;HEX nach ASCII wandeln.
			ldx	#$00			;(High-Byte)
			jsr	ConvHexToASCII

			lda	r0L			;HEX nach ASCII wandeln.
			jsr	ConvHexToASCII		;(Low-Byte)

			lda	#>PanicBox
			sta	r0H
			lda	#<PanicBox
			sta	r0L
			jsr	DoDlgBox		;Panic-Box anzeigen.

;*** Da keine Abbruchmöglichkeit für
;    die Dialogbox existiert, kann
;    eine Rückkehr zum DeskTop
;    entfallen.

;*** HEX-Zahl nach ASCII-Wandeln und in
;    PANIC!-Text eintragen.
:ConvHexToASCII		pha
			lsr
			lsr
			lsr
			lsr
			jsr	ConvHexNibble
			inx
			pla
			and	#$0f
			jsr	ConvHexNibble
			inx
			rts

;*** Halb-Byte nach ASCII wandeln.
:ConvHexNibble		cmp	#$0a
			bcs	:101
			clc
			adc	#$30
			bne	:102
::101			clc
			adc	#$37
::102			sta	PanicAddress,x
			rts

;*** Dialogbox für PANIC!-Routine.
:PanicBox		b $81
			b $0b,$10,$10
			w :101
			b $00

;*** Systemtext für PANIC!-Routine.
::101			b $18
			b "Systemfehler nahe $"

;*** Speicher für HEX-Zahl bei
;    PANIC!-Routine.
:PanicAddress		b "xxxx",$00

;*** GEOS-Serien-Nummer einlesen.
:xGetSerialNumber	lda	SerialNumber+0
			sta	r0L
:GetSerHByte		lda	SerialNumber+1
			sta	r0H
			rts

;*** Unbekannte Bytes.
			b $01,$60

;*** GEOS-Füllmuster.
:GEOS_Patterns

:pattern00		b %00000000
			b %00000000
			b %00000000
			b %00000000
			b %00000000
			b %00000000
			b %00000000
			b %00000000

:pattern01		b %11111111
			b %11111111
			b %11111111
			b %11111111
			b %11111111
			b %11111111
			b %11111111
			b %11111111

:pattern02		b %10101010
			b %01010101
			b %10101010
			b %01010101
			b %10101010
			b %01010101
			b %10101010
			b %01010101

:pattern03		b %10011001
			b %01000010
			b %00100100
			b %10011001
			b %10011001
			b %00100100
			b %01000010
			b %10011001

:pattern04		b %11111011
			b %11110101
			b %11111011
			b %11110101
			b %11111011
			b %11110101
			b %11111011
			b %11110101

:pattern05		b %10001000
			b %00100010
			b %10001000
			b %00100010
			b %10001000
			b %00100010
			b %10001000
			b %00100010

:pattern06		b %01110111
			b %11011101
			b %01110111
			b %11011101
			b %01110111
			b %11011101
			b %01110111
			b %11011101

:pattern07		b %10001000
			b %00000000
			b %00100010
			b %00000000
			b %10001000
			b %00000000
			b %00100010
			b %00000000

:pattern08		b %01110111
			b %11111111
			b %11011101
			b %11111111
			b %01110111
			b %11111111
			b %11011101
			b %11111111

:pattern09		b %11111111
			b %00000000
			b %11111111
			b %00000000
			b %11111111
			b %00000000
			b %11111111
			b %00000000

:pattern10		b %01010101
			b %01010101
			b %01010101
			b %01010101
			b %01010101
			b %01010101
			b %01010101
			b %01010101

:pattern11		b %00000001
			b %00000010
			b %00000100
			b %00001000
			b %00010000
			b %00100000
			b %01000000
			b %10000000

:pattern12		b %10000000
			b %01000000
			b %00100000
			b %00010000
			b %00001000
			b %00000100
			b %00000010
			b %00000001

:pattern13		b %11111110
			b %11111101
			b %11111011
			b %11110111
			b %11101111
			b %11011111
			b %10111111
			b %01111111

:pattern14		b %01111111
			b %10111111
			b %11011111
			b %11101111
			b %11110111
			b %11111011
			b %11111101
			b %11111110

:pattern15		b %11111111
			b %10001000
			b %10001000
			b %10001000
			b %11111111
			b %10001000
			b %10001000
			b %10001000

:pattern16		b %11111111
			b %10000000
			b %10000000
			b %10000000
			b %10000000
			b %10000000
			b %10000000
			b %10000000

:pattern17		b %11111111
			b %10000000
			b %10000000
			b %10000000
			b %11111111
			b %00001000
			b %00001000
			b %00001000

:pattern18		b %00001000
			b %00011100
			b %00100010
			b %11000001
			b %10000000
			b %00000001
			b %00000010
			b %00000100

:pattern19		b %10001000
			b %00010100
			b %00100010
			b %01000001
			b %10001000
			b %00000000
			b %10101010
			b %00000000

:pattern20		b %10000000
			b %01000000
			b %00100000
			b %00000000
			b %00000010
			b %00000100
			b %00001000
			b %00000000

:pattern21		b %01000000
			b %10100000
			b %00000000
			b %00000000
			b %00000100
			b %00001010
			b %00000000
			b %00000000

:pattern22		b %10000010
			b %01000100
			b %00111001
			b %01000100
			b %10000010
			b %00000001
			b %00000001
			b %00000001

:pattern23		b %00000011
			b %10000100
			b %01001000
			b %00110000
			b %00001100
			b %00000010
			b %00000001
			b %00000001

:pattern24		b %11111000
			b %01110100
			b %00100010
			b %01000111
			b %10001111
			b %00010111
			b %00100010
			b %01110001

:pattern25		b %10000000
			b %10000000
			b %01000001
			b %00111110
			b %00001000
			b %00001000
			b %00010100
			b %11100011

:pattern26		b %01010101
			b %10100000
			b %01000000
			b %01000000
			b %01010101
			b %00001010
			b %00000100
			b %00000100

:pattern27		b %00010000
			b %00100000
			b %01010100
			b %10101010
			b %11111111
			b %00000010
			b %00000100
			b %00001000

:pattern28		b %00100000
			b %01010000
			b %10001000
			b %10001000
			b %10001000
			b %10001000
			b %00000101
			b %00000010

:pattern29		b %01110111
			b %10001001
			b %10001111
			b %10001111
			b %01110111
			b %10011000
			b %11111000
			b %11111000

:pattern30		b %10111111
			b %00000000
			b %10111111
			b %10111111
			b %10110000
			b %10110000
			b %10110000
			b %10110000

:pattern31		b %00000000
			b %00001000
			b %00010100
			b %00101010
			b %01010101
			b %00101010
			b %00010100
			b %00001000

:pattern32		b %10110001
			b %00110000
			b %00000011
			b %00011011
			b %11011000
			b %11000000
			b %00001100
			b %10001101

:pattern33		b %10000000
			b %00010000
			b %00000010
			b %00100000
			b %00000001
			b %00001000
			b %01000000
			b %00000100

;*** Tabelle zum berechnen der Daten
;    für Buchstaben in Fettschrift!
;    Jedes Byte in PLAINTEXT wird durch
;    ein Byte in BOLD ersetzt. Dabei
;    dient das PLAINTEXT-Byte als
;    Zeiger auf die BoldData-Tabelle.
;    Bsp: %00010000 wird zu %00011000
:BoldData		b $00,$01,$03,$03,$06,$07,$07,$07
			b $0c,$0d,$0f,$0f,$0e,$0f,$0f,$0f
			b $18,$19,$1b,$1b,$1e,$1f,$1f,$1f
			b $1c,$1d,$1f,$1f,$1e,$1f,$1f,$1f
			b $30,$31,$33,$33,$36,$37,$37,$37
			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
			b $38,$39,$3b,$3b,$3e,$3f,$3f,$3f
			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
			b $60,$61,$63,$63,$66,$67,$67,$67
			b $6c,$6d,$6f,$6f,$6e,$6f,$6f,$6f
			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $70,$71,$73,$73,$76,$77,$77,$77
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $c0,$c1,$c3,$c3,$c6,$c7,$c7,$c7
			b $cc,$cd,$cf,$cf,$ce,$cf,$cf,$cf
			b $d8,$d9,$db,$db,$de,$df,$df,$df
			b $dc,$dd,$df,$df,$de,$df,$df,$df
			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $e0,$e1,$e3,$e3,$e6,$e7,$e7,$e7
			b $ec,$ed,$ef,$ef,$ee,$ef,$ef,$ef
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff

;*** GEOS-Font in Quellcode einbinden.
:BSW_Font		v 9,"GEOS_BSWFONT.OBJ"

;*** Inline: Speicherbereich löschen.
:xi_FillRam		pla
			sta	returnAddress+0
			pla
			sta	returnAddress+1
			jsr	Get2Word1Byte
			jsr	xFillRam
			php
			lda	#$06
			jmp	DoInlineReturn

;*** Beliebige Datei laden.
:xGetFile		jsr	SaveFileData		;Datei-Informationen sichern.

			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	NoFunc1			;Ja, Abbruch...

			jsr	LoadFileData		;Datei-Informationen einlesen.

			lda	#>dirEntryBuf		;Zeiger auf Datei-Eintrag.
			sta	r9H
			lda	#<dirEntryBuf
			sta	r9L

			lda	dirEntryBuf+22		;Dateityp einlesen.
			cmp	#$05			;Hilfsmittel starten ?
			bne	:101			;Nein, weiter...
			jmp	LdDeskAcc

::101			cmp	#$06			;Applikation starten ?
			beq	:102			;Ja, weiter...
			cmp	#$0e			;AutoExec-Datei starten ?
			bne	xLdFile			;Nein, weiter...
::102			jmp	LdApplic		;Applikation/AutoExec starten.

;*** Datei laden.
:xLdFile		jsr	GetFHdrInfo		;Infoblock einlesen.
			txa
			bne	NoFunc1

			lda	fileHeader+$46		;Dateistruktur einlesen.
			cmp	#$01			;VLIR-Datei ?
			bne	:101			;Nein, weiter...

			ldy	#$01			;VLIR-Header einlesen.
			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
			jsr	D_ReadSektor		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	NoFunc1			;Ja, Abbruch...

			ldx	#$08			;Zeiger auf ersten Datensatz.
			lda	diskBlkBuf +2
			sta	r1L
			beq	NoFunc1
			lda	diskBlkBuf +3
			sta	r1H

::101			lda	LoadFileMode
			and	#$01			;Programm starten ?
			beq	:102			;Ja, weiter...

			lda	LoadBufAdr+1		;Ladeadresse setzen.
			sta	r7H
			lda	LoadBufAdr+0
			sta	r7L

::102			lda	#$ff
			sta	r2L
			sta	r2H
			jsr	ReadFile		;Datei laden.
:NoFunc1		rts

;*** Sektorkette verfolgen und
;    Track/Sektor-Tabelle anlegen.
:xFollowChain		php
			sei

			lda	r3H
			pha

			ldy	#$00
::101			lda	r1L			;Sektor in Tabelle
			sta	(r3L),y			;eintragen.
			iny
			lda	r1H
			sta	(r3L),y
			iny
			bne	:102
			inc	r3H

::102			lda	r1L			;Sektor verfügbar ?
			beq	:103			;Nein, Ende...
			tya
			pha
			jsr	D_ReadSektor		;Sektor einlesen.
			pla
			tay
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			lda	diskBlkBuf +1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	diskBlkBuf +0
			sta	r1L
			clv
			bvc	:101

::103			ldx	#$00
::104			pla
			sta	r3H
			plp
			rts

;*** Dateitypen suchen.
:xFindFTypes		php
			sei

			lda	r6H			;Zeiger auf Tabelle für
			sta	r1H			;dateinamen.
			lda	r6L
			sta	r1L

			lda	#$00			;Größe der Tabelle für
			sta	r0H			;Dateinamen berechnen.

			lda	r7H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			adc	r7H
			sta	r0L
			bcc	:101
			inc	r0H
::101			jsr	ClearRam		;Dateinamen-Tabelle löschen.

			sec
			lda	r6L
			sbc	#$03
			sta	r6L
			lda	r6H
			sbc	#$00
			sta	r6H

			jsr	Get1stDirEntry		;Ersten DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch...

			ldx	#>GetSerialNumber	;GEOS-Serien-Nummer einlesen.
			lda	#<GetSerialNumber
			jsr	CallRoutine

			lda	r0H			;For what the hell is this ???
			cmp	SerNoHByte		;Stimmt die Serien-Nummer ?
			beq	:102			;Ja, weiter...
			inc	LdDeskAcc+1		;Irgendwas ändern, wozu ??????

::102			ldy	#$00
			lda	(r5L),y			;Datei-Eintrag vorhanden ?
			beq	:106			;Nein, weiter...

			ldy	#$16
			lda	(r5L),y			;Dateityp einlesen.
			cmp	r7L			;Gesuchter Dateityp ?
			bne	:106			;Nein, übergehen.

			jsr	CheckFileClass		;GEOS-Klasse vergleichen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch...

			tya				;GEOS-Klasse OK ?
			bne	:106			;Nein, weiter...

			ldy	#$03
::103			lda	(r5L),y			;Dateinamen in Tabelle
			cmp	#$a0			;kopieren.
			beq	:104
			sta	(r6L),y
			iny
			cpy	#$13
			bne	:103

::104			lda	#$00
			sta	(r6L),y

			clc				;Zeiger auf Position für
			lda	#$11			;Dateinamen in Tabelle
			adc	r6L			;korrigieren.
			sta	r6L
			bcc	:105
			inc	r6H

::105			dec	r7H			;Dateizähler -1.
			beq	:107			;Speicher voll ? Ja, Ende...

::106			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch...
			tya				;Ende erreicht ?
			beq	:102			;Nein, weiter...
::107			plp
			rts

;*** Zeiger auf ":fileTrScTab" = $8300.
:Vec_fileTrScTab	lda	#>fileTrScTab
			sta	r6H
			lda	#<fileTrScTab
			sta	r6L
			rts

;*** Ladeadresse einlesen.
:GetLoadAdr		lda	fileHeader+$48
			sta	r7H
			lda	fileHeader+$47
			sta	r7L
			rts

;*** Zeiger auf ":fileHeader" = $8100.
:Vec_fileHeader		lda	#>fileHeader
			sta	r4H
			lda	#<fileHeader
			sta	r4L
			rts

;*** Datei suchen.
:xFindFile		php
			sei
			sec
			lda	r6L
			sbc	#$03
			sta	r6L
			lda	r6H
			sbc	#$00
			sta	r6H

			jsr	Get1stDirEntry		;Erster DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

::101			ldy	#$00
			lda	(r5L),y			;Gelöschter Eintrag ?
			beq	:104			;Ja, weiter...
			ldy	#$03
::102			lda	(r6L),y			;Dateinamen vergleichen.
			beq	:103
			cmp	(r5L),y
			bne	:104			; -> Falsche Datei,...
			iny
			bne	:102
::103			cpy	#$13
			beq	:105			; -> Richtige Datei...
			lda	(r5L),y
			iny
			cmp	#$a0
			beq	:103

::104			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch...
			tya				;Verzeichnis-Ende erreicht ?
			beq	:101			;Nein, weiter...
			ldx	#$05			;Fehler: "File not found"
			bne	:107

::105			ldy	#$00
::106			lda	(r5L),y			;Datei-Eintrag kopieren.
			sta	dirEntryBuf,y
			iny
			cpy	#$1e
			bne	:106
			ldx	#$00			;Kein Fehler...
::107			plp
			rts

;*** Neues Gerät aktivieren.
:xSetDevice		nop
			cmp	curDevice		;Aktuelles Laufwerk ?
			beq	:102			;Ja, weiter...
			pha				;Neue Adresse speichern.
			lda	curDevice		;Aktuelles Laufwerk lesen.
			cmp	#$08			;Diskettenlaufwerk ?
			bcc	:101			;Nein, weiter...
			cmp	#$0c
			bcs	:101			;Nein, weiter...
			jsr	ExitTurbo		;Turbo-DOS abschalten.

::101			pla				;Neues Laufwerk festlegen.
			sta	curDevice

::102			cmp	#$08			;Diskettenlaufwerk ?
			bcc	:103			;Nein, Ende...
			cmp	#$0c
			bcs	:103			;Nein, Ende...
			tay
			lda	driveType -8,y		;GEOS-Variablen aktualisieren.
			sta	curType
			cpy	curDrive		;War Laufwerk bereits aktiv ?
			beq	:103			;Ja, weiter...
			sty	curDrive
			bit	sysRAMFlg		;REU verfügbar ?
			bvc	:103			;Nein, weiter...
			lda	LB_DrvInREU -8,y	;Zeiger auf Laufwerkstreiber
			sta	CopyDrvData +2		;in REU.
			lda	HB_DrvInREU -8,y	;Zeiger auf laufwerkstreiber
			sta	CopyDrvData +3		;in RAM.
			jsr	SwapREUData		;RAM-Register speichern und
							;REU-Register einlesen.
			jsr	FetchRAM		;Treiber aus REU nach RAM.
			jsr	SwapREUData		;RAM-Register zurücksetzen.
::103			ldx	#$00			;OK!
			rts

;*** Austausch der REU-Register mit dem
;    Speicherbereich ":r0L - r4L".
:SwapREUData		ldy	#$06
::101			lda	r0,y
			tax
			lda	CopyDrvData,y
			sta	r0,y
			txa
			sta	CopyDrvData,y
			dey
			bpl	:101
			rts

;*** Transferdaten für ":SetDevice".
:CopyDrvData		w $9000				;RAM-Adresse Laufwerkstreiber.
			w $0000				;REU-Adresse Laufwerkstreiber.
			w $0d80				;Länge Laufwerkstreiber.
			b $00				;BANK in REU.

;*** Speicheradresse Laufwerkstreiber.
:LB_DrvInREU		b < $8300
			b < $9080
			b < $9e00
			b < $ab80
:HB_DrvInREU		b > $8300
			b > $9080
			b > $9e00
			b > $ab80

;*** Infoblock einlesen.
:xGetFHdrInfo		ldy	#$13
			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
			lda	r1H
			sta	fileTrScTab+1
			lda	r1L
			sta	fileTrScTab+0
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa
			bne	:101
			ldy	#$01
			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
			jsr	GetLoadAdr
::101			rts

;*** GEOS-Klasse vergleichen.
:CheckFileClass		ldx	#$00
			lda	r10L
			ora	r10H
			beq	:102
			ldy	#$13
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa
			bne	:104
			tay
::101			lda	(r10L),y
			beq	:102
			cmp	fileHeader+$4d,y
			bne	:103
			iny
			bne	:101
::102			ldy	#$00
			rts
::103			ldy	#$ff
::104			rts

;*** Hilfsmittel einlesen.
:xLdDeskAcc		lda	r10L
			sta	DA_ResetScrn
			jsr	GetFHdrInfo
			txa
			bne	ExitLdDA
			lda	r1H
			pha
			lda	r1L
			pha
			jsr	SaveSwapFile
			pla
			sta	r1L
			pla
			sta	r1H
			txa
			bne	ExitLdDA
			jsr	GetLoadAdr
			lda	#$ff
			sta	r2L
			sta	r2H
			jsr	ReadFile
			txa
			bne	ExitLdDA
			jsr	InitDB_Box1
			jsr	UseSystemFont
			jsr	GEOS_Init2
			lda	DA_ResetScrn
			sta	r10L
			pla
			sta	DA_ReturnAdr+0		;LOW -Byte Rücksprungadresse.
			pla
			sta	DA_ReturnAdr+1		;High -Byte Rücksprungadresse.
			tsx
			stx	DA_RetStackP		;Stackzeiger merken.
			ldx	fileHeader+$4c
			lda	fileHeader+$4b
			jmp	InitMLoop1

;*** Keine Ahnung wozu diese Routine verwendet wird!!!
:Unknown1		pla				;Ungenutzte Routine!!!
			sta	r1L
			pla
			sta	r1H
:ExitLdDA		rts

;*** DA beenden, zurück zur Applikation.
:xRstrAppl		lda	#>SwapFileName		;SWAP-File einlesen.
			sta	r6H
			lda	#<SwapFileName
			sta	r6L
			lda	#$00
			sta	r0L
			jsr	GetFile
			txa
			bne	:101

			jsr	InitDB_Box2

			lda	#>SwapFileName		;SWAP-File löschen.
			sta	r0H
			lda	#<SwapFileName
			sta	r0L
			lda	#>fileTrScTab
			sta	r3H
			lda	#<fileTrScTab
			sta	r3L
			jsr	FastDelFile
			txa
::101			ldx	DA_RetStackP
			txs
			tax
			lda	DA_ReturnAdr+1
			pha
			lda	DA_ReturnAdr+0
			pha
			rts

;*** Anwendung starten.
:xLdApplic		jsr	SaveFileData

			jsr	LdFile
			txa
			bne	:101

			lda	LoadFileMode
			and	#$01			;Programm starten ?
			bne	:101			;Nein, weiter...

			jsr	LoadFileData		;Variablen wieder einlesen.

			lda	fileHeader+$4b
			sta	r7L
			lda	fileHeader+$4c
			sta	r7H
			jmp	StartAppl		;Applikation starten.

::101			rts				;Zurück zum Programm.

;*** Name für Swap-Datei.
:SwapFileName		b $1b,"Swap File",$00
:SerNoHByte		b $96
;*** SWAP-File speichern.
:SaveSwapFile		lda	#$0d			;Aktuellen Infoblock für
			sta	fileHeader+$45		;SwapFile anpassen.
			lda	#>SwapFileName
			sta	fileHeader +1
			lda	#<SwapFileName
			sta	fileHeader +0
			lda	#>fileHeader		;Zeiger auf Infoblock.
			sta	r9H
			lda	#<fileHeader
			sta	r9L
			lda	#$00			;Zeiger auf Seite #1 des
			sta	r10L			;Directorys.

;*** Datei speichern.
:xSaveFile		ldy	#$00
::101			lda	(r9L),y			;Infoblock zwischenspeichern.
			sta	fileHeader +0,y
			iny
			bne	:101

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	GetFileSize		;Dateigröße berechnen.
			jsr	Vec_fileTrScTab

			jsr	BlkAlloc		;Sektor belegen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	Vec_fileTrScTab

			jsr	SetGDirEntry		;Verzeichnis-Eintrag erzeugen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			sta	fileHeader+$a0
			lda	dirEntryBuf+20
			sta	r1H
			lda	dirEntryBuf+19
			sta	r1L
			jsr	Vec_fileHeader

			jsr	PutBlock		;Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	SaveVLIR
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...

			jsr	GetLoadAdr		;Ladeadresse ermitteln.
			jsr	WriteFile		;Speicher auf Disk schreiben.
::102			rts

;*** Dateigröße berechnen.
:GetFileSize		lda	fileHeader+$49		;Programmgröße berechnen.
			sec
			sbc	fileHeader+$47
			sta	r2L
			lda	fileHeader+$4a
			sbc	fileHeader+$48
			sta	r2H

			jsr	:101			;254 Bytes für Infoblock.

			lda	fileHeader+$46
			cmp	#$01			;VLIR-Datei ?
			bne	:102			;Nein, weiter...

::101			clc				;254 Bytes für VLIR-Header.
			lda	#$fe
			adc	r2L
			sta	r2L
			bcc	:102
			inc	r2H
::102			rts

;*** VLIR-Header speichern.
:SaveVLIR		ldx	#$00
			lda	dirEntryBuf+21
			cmp	#$01			;VLIR-Datei ?
			bne	:102			;Nein, weiter...
			lda	dirEntryBuf+2
			sta	r1H
			lda	dirEntryBuf+1
			sta	r1L
			txa
			tay
::101			sta	diskBlkBuf +0,y
			iny
			bne	:101
			dey
			sty	diskBlkBuf +1
			jsr	D_WriteSektor		;Sektor auf Diskette schreiben.
::102			rts

;*** GEOS-Verzeichniseintrag speichern.
:xSetGDirEntry		jsr	BldGDirEntry		;Verzeichnis-Eintrag erzeugen.
			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	NoFunc2			;Ja, Abbruch...
			tya
			clc
			adc	#<diskBlkBuf
			sta	r5L
			lda	#>diskBlkBuf
			adc	#$00
			sta	r5H

			ldy	#$1d
::101			lda	dirEntryBuf+0,y		;Verzeichnis-Eintrag kopieren.
			sta	(r5L),y
			dey
			bpl	:101

			jsr	SetFileDate
			jmp	D_WriteSektor

;*** Aktuelles Datum in Verzeichnis-
;    eintrag schreiben.
:SetFileDate		ldy	#$17
::101			lda	year -$17,y
			sta	(r5L),y
			iny
			cpy	#$1c
			bne	:101
:NoFunc2		rts

;*** GEOS-Verzeichniseintrag erzeugen.
:xBldGDirEntry		ldy	#$1d
			lda	#$00			;Verzeichnis-Eintrag löschen.
::101			sta	dirEntryBuf+0,y
			dey
			bpl	:101

			tay
			lda	(r9L),y
			sta	r3L
			iny
			lda	(r9L),y
			sta	r3H
			sty	r1H
			dey

			ldx	#$03			;Dateiname kopieren.
::102			lda	(r3L),y
			bne	:104
			sta	r1H
::103			lda	#$a0
::104			sta	dirEntryBuf+0,x
			inx
			iny
			cpy	#$10
			beq	:105
			lda	r1H
			bne	:102
			beq	:103

::105			ldy	#$44
			lda	(r9L),y
			sta	dirEntryBuf+0		;Dateityp.
			ldy	#$46
			lda	(r9L),y
			sta	dirEntryBuf+21		;Datei-Struktur.
			ldy	#$00
			sty	fileHeader +0
			dey
			sty	fileHeader +1

			lda	fileTrScTab+1
			sta	dirEntryBuf+20		;Sektor Infoblock.
			lda	fileTrScTab+0
			sta	dirEntryBuf+19		;Track Infoblock.
			jsr	SetVecToSek

			lda	fileTrScTab+3		;Ersten Sektor merken.
			sta	dirEntryBuf+2
			lda	fileTrScTab+2
			sta	dirEntryBuf+1

			lda	dirEntryBuf+21
			cmp	#$01
			bne	:106
			jsr	SetVecToSek

::106			ldy	#$45
			lda	(r9L),y
			sta	dirEntryBuf+22
			lda	r2H			;Dateigröße übernehmen.
			sta	dirEntryBuf+29
			lda	r2L
			sta	dirEntryBuf+28
			rts

;*** Datei löschen.
:xDeleteFile		jsr	DelFileEntry		;Dateieintrag löschen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			rts

::101			lda	#>dirEntryBuf		;Zeiger auf Dateieintrag.
			sta	r9H
			lda	#<dirEntryBuf
			sta	r9L

;*** Belegte Blocks einer Datei
;    freigeben.
:xFreeFile		php
			sei
			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			ldy	#$13
			lda	(r9L),y			;Infoblock vorhanden ?
			beq	:101			;Nein, weiter...
			sta	r1L
			iny
			lda	(r9L),y			;Zeiger auf Track/Sektor
			sta	r1H			;des Infoblocks.
			jsr	FreeSeqChain		;Infoblock freigeben.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

::101			ldy	#$01
			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y			;Zeiger auf Track/Sektor
			sta	r1H			;der Programm-Datei.
			jsr	FreeSeqChain		;Programm-Daten freigeben.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			ldy	#$15
			lda	(r9L),y
			cmp	#$01			;VLIR-Datei freigeben ?
			bne	:102			;Nein, weiter...
			jsr	SetFreeVLIR		;VLIR-Datensätze freigeben.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...
::102			jsr	PutDirHead		;BAM aktualisieren.
::103			plp				;Ende...
			rts

;*** VLIR-Datensätze freigeben.
:SetFreeVLIR		ldy	#$00
::101			lda	diskBlkBuf +0,y		;VLIR-Header in
			sta	fileHeader +0,y		;Zwischenspeicher kopieren.
			iny
			bne	:101

			ldy	#$02
::102			tya				;Alle Datensätze gelöscht ?
			beq	:103			;Ja, Ende...
			lda	fileHeader +0,y		;Zeiger VLIR-Eintrag und
			sta	r1L			;Track/Sektor einlesen.
			iny
			lda	fileHeader +0,y
			sta	r1H
			iny
			lda	r1L
			beq	:102
			tya
			pha
			jsr	FreeSeqChain		;Datensatz freigeben.
			pla				;Zeiger auf Datensatz
			tay				;zurücksetzen.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::103			rts

;*** Sektorkette auf Disk freigeben.
:FreeSeqChain		lda	r1H			;Zeiger auf ersten
			sta	r6H			;Track/Sektor speichern.
			lda	r1L
			sta	r6L

			lda	#$00			;Zähler für gelöschte
			sta	r2L			;Blocks löschen.
			sta	r2H
::101			jsr	FreeBlock		;Sektor freigeben.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			inc	r2L			;Anzahl gelöschte Blocks
			bne	:102			;um 1 erhöhen.
			inc	r2H
::102			lda	r2H			;Anzahl gelöschter Blocks
			pha				;zwischenspeichern.
			lda	r2L
			pha
			lda	r6H
			sta	r1H
			lda	r6L
			sta	r1L
			jsr	D_ReadSektor		;Sektor einlesen.
			pla				;Anzahl gelöschter Blocks
			sta	r2L			;zurücksetzen.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			lda	diskBlkBuf +0		;Noch ein Sektor ?
			beq	:103			;Nein, Ende...
			sta	r6L
			lda	diskBlkBuf +1
			sta	r6H
			clv
			bvc	:101			;Nächsten Sektor freigeben.
::103			ldx	#$00			;Ende.
::104			rts

;*** Dateieintrag suchen, Aufruf durch ":FastDelFile" und ":DeleteFile".
:DelFileEntry		lda	r0H
			sta	r6H
			lda	r0L
			sta	r6L
			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...
			lda	#$00
			tay
			sta	(r5L),y			;Datei-Eintrag löschen.
			jsr	D_WriteSektor		;Sektor zurückschreiben.
::101			rts

;*** Datei löschen, nur für SEQ-Dateien.
;    ":r3" zeigt auf Tr/Se-Tabelle.
:xFastDelFile		lda	r3H			;Zeiger auf Track/Sektor-
			pha				;Tabelle zwischenspeichern.
			lda	r3L
			pha
			jsr	DelFileEntry		;Datei-Eintrag löschen.
			pla				;Zeiger auf Track/Sektor-
			sta	r3L			;Tabelle zurücksetzen.
			pla
			sta	r3H
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...
			jsr	FreeSekTab		;Sektoren freigeben.
::101			rts

;*** Sektoren in ":fileTrSeTab" freigeben.
:FreeSekTab		lda	r3H			;Zeiger auf Track/Sektor-
			pha				;Tabelle zwischenspeichern.
			lda	r3L
			pha
			jsr	GetDirHead		;BAM einlesen.
			pla				;Zeiger auf Track/Sektor-
			sta	r3L			;Tabelle zurücksetzen.
			pla
			sta	r3H

::101			ldy	#$00
			lda	(r3L),y			;Noch ein Sektor ?
			beq	:103			;Nein, weiter...
			sta	r6L
			iny
			lda	(r3L),y
			sta	r6H
			jsr	FreeBlock		;Sektor freigeben.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			clc				;Zeiger auf nächsten Eintrag.
			lda	#$02
			adc	r3L
			sta	r3L
			bcc	:102
			inc	r3H
::102			clv
			bvc	:101

::103			jsr	PutDirHead		;BAM zurückschreiben.
::104			rts

;*** Datei umbenennen.
:xRenameFile		lda	r0H			;Zeiger auf neuen Dateinamen
			pha				;zwischenspeichern.
			lda	r0L
			pha
			jsr	FindFile		;Datei suchen.
			pla				;Zeiger auf neuen Dateinamen
			sta	r0L			;zurückschreiben.
			pla
			sta	r0H
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abbruch...
			clc				;Zeiger auf Dateiname innerhalb
			lda	#$03			;Verzeichniseintrag berechnen.
			adc	r5L
			sta	r5L
			bcc	:101
			inc	r5H
::101			ldy	#$00			;Neuen Dateinamen in
::102			lda	(r0L),y			;Verzeichniseintrag kopieren.
			beq	:103
			sta	(r5L),y
			iny
			cpy	#$10
			bcc	:102
			bcs	:104

::103			lda	#$a0			;Dateiname auch 16 Zeichen
			sta	(r5L),y			;mit $A0-Codes auffüllen.
			iny
			cpy	#$10
			bcc	:103
::104			jsr	D_WriteSektor		;Sektor zurückschreiben.
::105			rts

;*** VLIR-Datei öffnen.
:xOpenRecordFile	lda	r0H			;Zeiger auf Dateiname
			sta	r6H			;für ":FindFile" umkopieren.
			lda	r0L
			sta	r6L
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			bne	NoRecordFlag		;Ja, Abbruch...

			ldx	#$0a
			ldy	#$00
			lda	(r5L),y			;Dateityp-Byte einlesen.
			and	#$3f
			cmp	#$03			;"USR"-Datei ?
			bne	NoRecordFlag		;Nein, Fehler...
			ldy	#$15
			lda	(r5L),y			;VLIR-Datei ?
			cmp	#$01			;Nein, Fehler...
			bne	NoRecordFlag

			ldy	#$01
			lda	(r5L),y			;Track/Sektor des VLIR-Headers
			sta	VLIR_HeaderTr		;in Zwischenspeicher.
			iny
			lda	(r5L),y
			sta	VLIR_HeaderSe
			lda	r1H			;Verzeichniseintrag der VLIR-
			sta	VLIR_HdrDirSek+1	;Datei in Zwischenspeicher.
			lda	r1L
			sta	VLIR_HdrDirSek+0
			lda	r5H
			sta	VLIR_HdrDEntry+1
			lda	r5L
			sta	VLIR_HdrDEntry+0
			lda	dirEntryBuf+29		;Dateigröße zwischenspeichern.
			sta	fileSize+1
			lda	dirEntryBuf+28
			sta	fileSize+0
			jsr	VLIR_GetHeader		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	NoRecordFlag		;Ja, Abbruch...
			sta	usedRecords		;Anzahl Records löschen.

			ldy	#$02			;Anzahl belegter Records
::101			lda	fileHeader +0,y		;in VLIR-Datei zählen.
			ora	fileHeader +1,y
			beq	:102
			inc	usedRecords
			iny
			iny
			bne	:101

::102			ldy	#$00
			lda	usedRecords		;Datei leer ?
			bne	:103			;Nein, weiter...
			dey				;Flag: "Leere VLIR-Datei".
::103			sty	curRecord
			ldx	#$00
			stx	fileWritten
			rts

;*** VLIR-Datei schließen.
:xCloseRecordFile	jsr	xUpdateRecFile
:NoRecordFlag		lda	#$00
			sta	VLIR_HeaderTr
			rts

;*** VLIR-Datei aktualisieren.
:xUpdateRecFile		ldx	#$00
			lda	fileWritten
			beq	:101

			jsr	VLIR_PutHeader		;VLIR-Header speichern.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	VLIR_HdrDirSek+1
			sta	r1H
			lda	VLIR_HdrDirSek+0
			sta	r1L
			jsr	D_ReadSektor		;Verzeichnissektor lesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	VLIR_HdrDEntry+1	;Zeiger auf Verzeichniseintrag.
			sta	r5H
			lda	VLIR_HdrDEntry+0
			sta	r5L
			jsr	SetFileDate

			ldy	#$1c
			lda	fileSize+0		;Dateigröße zurückschreiben.
			sta	(r5L),y
			iny
			lda	fileSize+1
			sta	(r5L),y
			jsr	D_WriteSektor
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			jsr	PutDirHead
			lda	#$00
			sta	fileWritten
::101			rts

;*** Zeiger auf nächsten Datensatz der VLIR-Datei.
:xNextRecord		lda	curRecord
			clc
			adc	#$01
			clv
			bvc	xPointRecord

;*** Zeiger auf vorherigen Datensatz der VLIR-Datei.
:xPreviousRecord	lda	curRecord
			sec
			sbc	#$01

;*** Zeiger auf Datensatz der VLIR-Datei positionieren.
:xPointRecord		tax
			bmi	:101
			cmp	usedRecords		;Record verfügbar ?
			bcs	:101			;Nein, Fehler...
			sta	curRecord		;Neuen Record merken.

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.

			ldy	r1L			;$00 = Nicht angelegt.
			ldx	#$00
			beq	:102

::101			ldx	#$08
::102			lda	curRecord
			rts

;*** Datensatz aus VLIR-Datei löschen.
:xDeleteRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	:103			;Nein, -> Fehler ausgeben...

			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.

			lda	curRecord		;Zeiger auf Record in
			sta	r0L 			;VLIR-Header.
			jsr	VLIR_DelRecEntry	;Record-Eintrag löschen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			lda	curRecord		;Zeiger auf aktuellen Record
			cmp	usedRecords		;korrigieren.
			bcc	:101
			dec	curRecord

::101			ldx	#$00
			lda	r1L			;War Record angelegt ?
			beq	:103			;Nein, Ende...
			jsr	FreeSeqChain		;Sektorkette freigeben.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch...

			lda	fileSize+0		;Dateigröße korrigieren.
			sec
			sbc	r2L
			sta	fileSize+0
			bcs	:102
			dec	fileSize+1
::102			ldx	#$00			;Kein Fehler, OK.
::103			rts

;*** Datensatz in VLIR-Datei einfügen.
:xInsertRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	:101			;Nein, Fehler ausgeben...

			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	curRecord		;Zeiger auf Record in
			sta	r0L 			;VLIR-Header.
			jsr	VLIR_InsRecEntry	;Record-Eintrag einfügen.
::101			rts

;*** Datensatz an VLIR-Datei anhängen.
:xAppendRecord		jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	curRecord		;Zeiger hinter aktuellen
			clc				;Record positionieren.
			adc	#$01
			sta	r0L
			jsr	VLIR_InsRecEntry	;Record-Eintrag einfügen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	r0L			;Zeiger auf aktuellen Record
			sta	curRecord		;korrigieren.
::101			rts

;*** Datensatz einlesen.
:xReadRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	:101			;Nein, Abbruch...

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.
			lda	r1L
			tax				;Record angelegt ?
			beq	:101			;Nein, Ende...

			jsr	ReadFile		;Record in Speicher einlesen.
			lda	#$ff			;$FF = Daten gelesen.
::101			rts

;*** Datensatz schreiben.
:xWriteRecord		ldx	#$08
			lda	curRecord		;Record verfügbar ?
			bmi	NoFunc4			;Nein, Abbruch...
			lda	r2H			;Anzahl zu schreibender
			pha				;Bytes zwischenspeichern.
			lda	r2L
			pha
			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			pla				;Anzahl zu schreibender
			sta	r2L			;Bytes zurückschreiben.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	NoFunc4			;Ja, Abbruch...
			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.
			lda	r1L			;Sektor bereits angelegt ?
			bne	:101			;Ja, weiter...
			ldx	#$00
			lda	r2L
			ora	r2H			;Sind Daten im Record ?
			beq	NoFunc4			;Nein, Ende...
			bne	:103			;Ja, Daten schreiben.

;*** Bestehenden Record löschen.
;    (Record wird später ersetzt)
::101			lda	r2H			;Anzahl zu schreibender
			pha				;Bytes zwischenspeichern.
			lda	r2L
			pha
			lda	r7H			;Startadresse Speicherbereich
			pha				;zwischenspeichern.
			lda	r7L
			pha
			jsr	FreeSeqChain		;Sektorkette freigeben.
			lda	r2L			;Anzahl freigegebener
			sta	r0L			;Sektoren merken.
			pla				;Startadresse Speicherbereich
			sta	r7L			;zurückschreiben.
			pla
			sta	r7H
			pla				;Anzahl zu schreibender
			sta	r2L			;Bytes zurückschreiben.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	NoFunc4			;Ja, Abbruch...

			lda	fileSize+0		;Dateilänge korrigieren.
			sec
			sbc	r0L
			sta	fileSize+0
			bcs	:102
			dec	fileSize+1

::102			lda	r2L
			ora	r2H			;Sind Daten im Record ?
			beq	VLIR_ClrHdrEntry	;Nein, Record-Eintrag löschen.
::103			jmp	VLIR_SaveRecData	;Speicherbereich schreiben.

;*** Leeren Record-Eintrag in
;    VLIR-Header erzeugen.
:VLIR_ClrHdrEntry	ldy	#$ff
			sty	r1H
			iny
			sty	r1L
			jsr	VLIR_Set1stSek
:NoFunc4		rts

;*** VLIR-Header einlesen.
:VLIR_GetHeader		jsr	VLIR_SetHdrData		;Zeiger auf VLIR-Header setzen.
			txa				;Fehler ?
			bne	:101			;Ja, Abbruch...
			jsr	GetBlock		;Sektor lesen.
::101			rts

;*** VLIR-Header speichern.
:VLIR_PutHeader		jsr	VLIR_SetHdrData		;Zeiger auf VLIR-Header setzen.
			txa				;Fehler ?
			bne	:101			;Ja, Abbruch...
			jsr	PutBlock		;Sektor schreiben.
::101			rts

;*** Zeiger auf VLIR-Header setzen.
:VLIR_SetHdrData	ldx	#$07
			lda	VLIR_HeaderTr		;VLIR-Datei geöffnet ?
			beq	:101			;Nein, Fehler...
			sta	r1L			;Zeiger auf Sektor VLIR-Header.
			lda	VLIR_HeaderSe
			sta	r1H
			jsr	Vec_fileHeader		;Zeiger auf Header-Speicher.
			ldx	#$00
::101			rts

;*** Record-Eintrag aus VLIR-Header
;    löschen. Anzahl Records -1.
:VLIR_DelRecEntry	ldx	#$08
			lda	r0L			;Record verfügbar ?
			bmi	:103			;Nein, Fehler ausgeben.
			asl				;Zeiger auf Record berechnen.
			tay
			lda	#$7e			;Anzahl Records berechnen.
			sec
			sbc	r0L
			asl
			tax
			beq	:102
::101			lda	fileHeader +4,y		;Ersten Record in Tabelle
			sta	fileHeader +2,y		;löschen, folgende Records
			iny				;verschieben.
			dex
			bne	:101
::102			stx	fileHeader+$fe		;Ende VLIR-Datei markieren.
			stx	fileHeader+$ff		;(über Tr/Se = $00/$00!)
			dec	usedRecords		;Anzahl Records -1.
::103			rts

;*** Record-Eintrag in VLIR-Header
;    einfügen. Anzahl Records +1.
:VLIR_InsRecEntry	ldx	#$09

			lda	usedRecords		;Bereits alle Records
			cmp	#$7f			;in VLIR-Datei belegt ?
			bcs	:103			;Ja, Abbruch...

			ldx	#$08
			lda	r0L			;Record verfügbar ?
			bmi	:103			;Nein, Abbruch...

			ldy	#$fe			;Zeiger auf letzten Record.
			lda	#$7e			;Anzahl Records berechnen.
			sec
			sbc	r0L
			asl
			tax
			beq	:102

::101			lda	fileHeader -1,y		;Record-Zeiger ab gewünschtem
			sta	fileHeader +1,y		;Record um 2 Byte verschieben.
			dey
			dex
			bne	:101

::102			txa				;Leeren Record-Eintrag in
			sta	fileHeader +0,y		;VLIR-Header erzeugen.
			lda	#$ff			;(Durch Tr/Se = $00/$FF!)
			sta	fileHeader +1,y
			inc	usedRecords		;Anzahl Records +1.
::103			rts

;*** Tr/Se des aktuellen Record lesen.
:VLIR_Get1stSek		lda	curRecord
			asl
			tay
			lda	fileHeader +2,y
			sta	r1L
			lda	fileHeader +3,y
			sta	r1H
			rts

;*** Tr/Se in VLIR-Header eintragen.
:VLIR_Set1stSek		lda	curRecord
			asl
			tay
			lda	r1L
			sta	fileHeader +2,y
			lda	r1H
			sta	fileHeader +3,y
			rts

;*** Speicherbereich in BAM belegen
;    und auf Disk speichern.
:VLIR_SaveRecData	jsr	Vec_fileTrScTab
			lda	r7H			;Startadresse Speicherbereich
			pha				;zwischenspeichern.
			lda	r7L
			pha
			jsr	BlkAlloc		;Sektoren belegen.
			pla				;Startadresse Speicherbereich
			sta	r7L			;zurückschreiben.
			pla
			sta	r7H
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...
			lda	r2L			;Anzahl Sektoren merken.
			pha
			jsr	Vec_fileTrScTab
			jsr	WriteFile		;Speicher auf Disk schreiben.
			pla				;Anzahl Sektoren wieder
			sta	r2L			;zurückschreiben.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...
			lda	fileTrScTab+1		;Zeiger auf ersten Sektor
			sta	r1H			;in VLIR-Header eintragen.
			lda	fileTrScTab+0
			sta	r1L
			jsr	VLIR_Set1stSek
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...
			lda	r2L			;Dateigröße korrigieren.
			clc
			adc	fileSize+0
			sta	fileSize+0
			bcc	:101
			inc	fileSize+1
::101			rts

;*** BAM im Speicher aktualisieren.
:VLIR_GetCurBAM		ldx	#$00
			lda	fileWritten		;Record bereits aktualisiert ?
			bne	:101			;Nein, weiter...
			jsr	GetDirHead		;Disketten-BAM einlesen.
			txa				;Fehler ?
			bne	:101			;Ja, Abbruch...
			lda	#$ff			;Record als "aktualisiert"
			sta	fileWritten		;markieren.
::101			rts

;*** Byte aus Datensatz einlesen.
:xReadByte		ldy	r5H
			cpy	r5L
			beq	:102
			lda	(r4L),y
			inc	r5H
			ldx	#$00
::101			rts

::102			ldx	#$0b
			lda	r1L
			beq	:101

			jsr	GetBlock
			txa
			bne	:101

			ldy	#$02
			sty	r5H
			dey
			lda	(r4L),y
			sta	r1H
			tax
			dey
			lda	(r4L),y
			sta	r1L
			beq	:103
			ldx	#$ff
::103			inx
			stx	r5L
			clv
			bvc	xReadByte

;*** Tabelle zum Initialisieren der
;    GEOS-Variablen. Aufruf über die
;    Routine ":InitRam".
:InitVarData		w currentMode
			b $0c
			b $00				;currentMode
			b $c0				;dispBufferOn
			b $00				;mouseOn
			w mousePicData			;mousePicPtr
			b $00				;windowTop
			b $c7				;windowBottom
			w $0000				;leftMargin
			w $013f				;rightMargin
			b $00				;pressFlag

			w appMain
			b $1c
			w $0000				;appMain
			w xInterruptMain		;intTopVector
			w $0000				;intBotVector
			w $0000				;mouseVector
			w $0000				;keyVector
			w $0000				;inputVector
			w $0000				;mouseFaultVec
			w $0000				;otherPressVec
			w $0000				;StringFaultVec
			w $0000				;alarmTmtVector
			w xPanic			;BRKVector
			w xRecoverRec			;RecoverVector
			b $0a				;selectionFlash
			b $00				;alphaFlag
			b $80				;iconSelFlag
			b $00				;faultData

			w MaxProcess
			b $02
			b $00,$00

			w DI_VecToEntry
			b $01
			b $00

			w DI_VecDefTab +1		;Zeiger auf DoIcon-Tabelle
			b $01				;löschen!
			b $00

			w obj0Pointer
			b $08
			b $28				;obj0Pointer
			b $29				;obj1Pointer
			b $2a				;obj2Pointer
			b $2b				;obj3Pointer
			b $2c				;obj4Pointer
			b $2d				;obj5Pointer
			b $2e				;obj6Pointer
			b $2f				;obj7Pointer

			w $0000

;*** Zeichenbreite ermitteln.
;    ":currentMode" im xReg übergeben!
:xGetRealSize		sec				;Zeichencode berechnen.
			sbc	#$20
			jsr	GetCodeWidth		;Zeichenbreite ermitteln.
			tay
			txa				;Schriftstil merken.
			ldx	curSetHight		;Zeichensatzhöhe einlesen.
			pha				;Schriftstil zwischenspeichern.
			and	#%01000000		;Schriftstil "BOLD" ?
			beq	:101			;Nein, weiter...
			iny				;Ja, Zeichenbreite +1.
::101			pla
			and	#%00001000		;Schriftstil "OUTLINE" ?
			beq	:102			;Nein, weiter...
			inx				;Ja, Zeichenbreite und
			inx				;Zeichenhöhe +2 Pixel.
			iny
			iny
			lda	baselineOffset		;Differenz Oberkante Zeichen
			clc				;und Baseline +2 Pixel.
			adc	#$02
			rts

::102			lda	baselineOffset		;Differenz Oberkante Zeichen
			rts				;und baseline einlesen.

;*** Zeicheninformationen ermitteln.
:DefCharData		ldy	r1H
			iny
			sty	BaseUnderLine
			sta	r5L			;Zeichencode merken.
			ldx	#$00			;Schriftart "PLAINTEXT".
			clc				;ASCII-Code berechnen.
			adc	#$20
			jsr	GetRealSize		;Zeichenbreite berechnen.
			tya				;Zeichenbreite speichern.
			pha

			lda	r5L			;Zeichencode einlesen.
			asl				;Zeiger auf Beginn der Daten
			tay				;in Bit-Streamtabelle.
			lda	(curIndexTable),y	;Startadresse einlesen und
			sta	r2L			;speichern.
			and	#%00000111
			sta	BitStr1stBit		;Zeiger auf erstes Bit merken.

			lda	r2L			;Startadresse auf erstes
			and	#%11111000		;Byte in Bit-Stream umrechnen.
			sta	r3L
			iny
			lda	(curIndexTable),y
			sta	r2H

			pla				;Zeichenbreite einlesen.

			clc				;Breite zu Beginn der Bit-
			adc	r2L			;Streamdaten addieren und
			sta	r6H			;zwischenspeichern.
			clc
			sbc	r3L
			lsr				;Anzahl Bytes mit 8 Bit
			lsr				;Grafikdaten berechnen.
			lsr
			sta	r3H
			tax
			cpx	#$03			;Mehr als 4 Datenbyte ?
			bcc	:101			;Nein, weiter...
			ldx	#$03			;Geht nicht! Da Startbyte +
							;4x Datenbyte + Abschlußbyte
							;zusammen bereits 48 Bit sind!
::101			lda	CalcBitDataL,x		;Berechnungsroutine für
			sta	r13L			;Anzahl Bytes definieren.
			lda	CalcBitDataH,x		;Vektor nach ":r13".
			sta	r13H

			lda	r2L			;Bit-Streamlänge bis zum
			lsr	r2H			;Beginn der Grafikdaten in
			ror				;Bytes umrechnen.
			lsr	r2H
			ror
			lsr	r2H
			ror
			clc				;Zeiger auf erstes Byte mit
			adc	cardDataPntr+0		;Grafikdaten in Zeichensatz
			sta	r2L			;nach ":r2" kopieren.
			lda	r2H
			adc	cardDataPntr+1
			sta	r2H

			ldy	BitStr1stBit
			lda	BitData3,y
			eor	#%11111111		;Bitmaske für Bits in erstem
			sta	BitStrDataMask		;Datenbyte berechnen.

			ldy	r6H
			dey
			tya
			and	#%00000111
			tay
			lda	BitData4,y
			eor	#%11111111		;Bitmaske für Bits in letztem
			sta	r7H			;Datenbyte berechnen.

			lda	currentMode		;Schriftart einlesen und
			tax				;in xReg kopieren.
			and	#%00001000		;"Outline" aktiv ?
			beq	:102			;Nein, weiter...
			lda	#%10000000
::102			sta	r8H			;Outline-Modus merken.

			lda	r5L
			clc				;ASCII-Code berechnen.
			adc	#$20
			jsr	GetRealSize		;Zeichenbreite berechnen.
			sta	r5H			;Abstand zur Baseline merken.

			lda	r1H			;Zeiger auf erste Grafikzeile
			sec				;für Zeichenausgabe.
			sbc	r5H
			sta	r1H

			stx	r10H			;Zeichenhöhe merken.

;*** Zeicheninformationen ermitteln (Fortsetzung).
			tya				;Zeichenbreite merken.
			pha

			lda	r11H			;Auf Bereichsüberschreitung
			bmi	:104			;testen ? Nein, weiter...

			lda	rightMargin+1		;Zeichen innerhalb
			cmp	r11H			;Textfenster ?
			bne	:103
			lda	rightMargin+0
			cmp	r11L
::103			bcc	RightOver		;Nein, nicht ausgeben.

::104			lda	currentMode
			and	#%00010000		;Schriftstil einlesen.
			bne	:105			;Kursiv ? Ja, weiter...
			tax				;Versatzmaß für Kursiv = $00.

::105			txa				;Versatzmaß für Kursiv = $08.
			lsr
			sta	r3L			;Versatzmaß merken.

			clc				;Versatzmaß zu aktueller
			adc	r11L			;X-Koordinate addieren.
			sta	StrBitXposL
			lda	r11H
			adc	#$00
			sta	StrBitXposH

			pla				;Zeichenbreite einlesen und
			sta	CurCharWidth		;in Zwischenspeicher kopieren.

			clc				;Zeichenbreite zu Versatzmaß
			adc	StrBitXposL		;und X-Koordinate addieren.
			sta	r11L
			lda	#$00
			adc	StrBitXposH
			sta	r11H			;Auf Bereichsüberschreitung
			bmi	LeftOver		;testen ? Nein, weiter...

			lda	leftMargin+1
			cmp	r11H
			bne	:106
			lda	leftMargin+0
			cmp	r11L
::106			bcs	LeftOver		;Ja, Fehlerbehandlung.

			jsr	StreamInfo

			ldx	#$00			;Zeichen nicht invertieren.
			lda	currentMode
			and	#%00100000		;REVERS-Modus aktiv ?
			beq	:107			;Nein, weiter...
			dex				;Zeichen invertieren.
::107			stx	r10L			;REVERS-Modus speichern.
			clc				;Kein Fehler, OK...
			rts

;*** Rechte Grenze überschritten,
;    Zeichen nicht ausgeben.
:RightOver		pla				;Zeichenbreite einlesen und
			sta	CurCharWidth		;Zwischenspeicher kopieren.
			clc				;Neue X-Koordinate berechnen.
			adc	r11L
			sta	r11L
			bcc	SetOverFlag
			inc	r11H
			sec
			rts

;*** Linke Grenze unterschritten.
:LeftOver		lda	r11L			;X-Koordinate korrigieren.
			sec
			sbc	r3L
			sta	r11L
			bcs	SetOverFlag
			dec	r11H
:SetOverFlag		sec
			rts

;*** Berechnungsroutinen.
:CalcBitDataL		b < Char24Bit,< Char32Bit,< Char40Bit,< Char48Bit
:CalcBitDataH		b > Char24Bit,> Char32Bit,> Char40Bit,> Char48Bit

;*** Bit-Stream-Infos einlesen.
;    Startbyte = Teilweise Bits setzen.
;    Datenbyte = 8 Bit-Stream-Byte.
;    Endbyte   = Teilweise Bits setzen.
:StreamInfo		ldx	r1H			;Grafikzeile berechnen.
			jsr	GetScanLine

;*** Erstes Byte bestimmen.
			lda	StrBitXposL		;X-Koordinate einlesen.
			ldx	StrBitXposH		;Auf Bereichsüberschreitung
			bmi	:102			;testen ? Nein, weiter...
			cpx	leftMargin+1
			bne	:101
			cmp	leftMargin+0
::101			bcs	:103			;Bereich nicht überschritten.

::102			ldx	leftMargin+1		;Wert für linken Rand als neue
			lda	leftMargin+0		;X-Koordinate setzen.

::103			pha				;LOW-Byte merken.
			and	#%11111000		;Zeiger auf erstes Byte für
			sta	r4L			;Grafikdaten berechnen.
			cpx	#$00
			bne	:104
			cmp	#%11000000
			bcc	:106

::104			sec
			sbc	#$80
			pha
			lda	r5L
			clc
			adc	#$80
			sta	r5L
			sta	r6L
			bcc	:105
			inc	r5H
			inc	r6H
::105			pla

::106			sta	r1L			;Zeiger auf Grafikspeicher.

			lda	StrBitXposH		;X-Koordinate in CARDs
			sta	r3L			;umrechnen.
			lsr	r3L
			lda	StrBitXposL
			ror
			lsr	r3L
			ror
			lsr	r3L
			ror
			sta	r7L			;CARD-Position merken.

			lda	leftMargin+1		;Wert für den linken Rand
			lsr				;des aktuellen Textfensters
			lda	leftMargin+0		;in CARDs umrechnen.
			ror
			lsr
			lsr
			sec				;Textausgabe links vom Rand
			sbc	r7L			;des aktuellen Textfensters ?
			bpl	:107			;Nein, weiter...
			lda	#$00			;X-Koordinate auf linken Rand.
::107			sta	CurStreamCard		;CARD-Position merken.

			lda	StrBitXposL
			and	#%00000111		;Anzahl ungültige Bits im
			sta	r7L			;ersten Grafik-Byte berechnen.

			pla
			and	#%00000111
			tay
			lda	BitData3,y		;Bit-Maske für die zu
			sta	r3L			;übernehmenden Bits berechnen.
			eor	#%11111111		;Bit-Maske für die zu
			sta	r9L			;setzenden Bits berechnen.

			ldy	r11L
			dey

;*** Letztes Byte bestimmen.
			ldx	rightMargin+1		;Rechte Grenze überschritten ?
			lda	rightMargin+0
			cpx	r11H
			bne	:108
			cmp	r11L
::108			bcs	:109			;Nein, weiter...

			tay
::109			tya
			and	#%00000111
			tax
			lda	BitData4,x		;Bit-Maske für die zu
			sta	r4H			;übernehmenden Bits berechnen.
			eor	#%11111111		;Bit-Maske für die zu
			sta	r9H			;setzenden Bits berechnen.

			tya
			sec
			sbc	r4L
			bpl	:110
			lda	#$00

::110			lsr
			lsr
			lsr
			clc
			adc	CurStreamCard
			sta	r8L			;Anzahl Stream-Bytes merken.
			cmp	r3H			;Muß größer als die Anzahl der
			bcs	:111			;Datenbytes sein!
			lda	r3H

::111			cmp	#$03			;Mind. 1 Datenbyte ?
			bcs	:113			;Ja, weiter...
			cmp	#$02			;Nur Start/Endbyte ?
			bne	:112			;Nein, weiter... (1 Byte!)
			lda	#$01			;Immer nur 1 Byte setzen.

::112			asl				;Anzahl Bits berechnen.
			asl				;Nur Werte $00 und $10 !!!
			asl
			asl
			sta	r12L

;*** Anzahl der Bit-Verschiebungen
;    berechnen.
			lda	r7L			;Anzahl Bits in erstem
							;Grafik-Byte auf Bildschirm.
			sec				;Anzahl Bits im erstem
			sbc	BitStr1stBit		;Bit-Stream-Byte.

			clc				;Zeiger auf Tabelle berechnen.
			adc	#$08
			clc
			adc	r12L
			tax
			lda	BitMoveRout,x		;Einsprungadresse berechnen.
			clc
			adc	#<D1a
			tay
			lda	#$00
			adc	#>D1a
			bne	:114

::113			lda	#>PrepBitStream
			ldy	#<PrepBitStream
::114			sta	r12H
			sty	r12L
:CurModusOK		clc
			rts

;*** Einsprungadressen in die
;    Berechnungsroutinen.
:BitMoveRout		b (D0a - D1a), (D3a - D1a)
			b (D3b - D1a), (D3c - D1a)
			b (D3d - D1a), (D3e - D1a)
			b (D3f - D1a), (D3g - D1a)
			b (D1h - D1a), (D1g - D1a)
			b (D1f - D1a), (D1e - D1a)
			b (D1d - D1a), (D1c - D1a)
			b (D1b - D1a), (D1a - D1a)

			b (D0a - D1a), (D4a - D1a)
			b (D4b - D1a), (D4c - D1a)
			b (D4d - D1a), (D4e - D1a)
			b (D4f - D1a), (D4g - D1a)
			b (D2h - D1a), (D2g - D1a)
			b (D2f - D1a), (D2e - D1a)
			b (D2d - D1a), (D2c - D1a)
			b (D2b - D1a), (D2a - D1a)

;*** Teil #2 einbinden.
			t "GEOS_QuellCode2"
;******************************************************************************
