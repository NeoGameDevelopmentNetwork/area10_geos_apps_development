; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "SymbTab_1"
			t "SymbTab_MMap"
			t "SymbTab64"

;*** Landessprache festlegen.
			t "src.Kernal.Lang"

;*** Revision festlegen.
			t "src.Kernal.Rev"

;*** Version (C64 oder C128) festlegen
;C64  = TRUE_C64
;C128 = TRUE_C128
.Flag64_128		= TRUE_C64

;*** GEOS-Version. Nicht $30, da kein echtes GEOS 3.0!!!
;    $20 belassen, damit Programme für GEOSV2 auch unter MP3 laufen.
.MPatchVersion		= $20
endif

;******************************************************************************
;*** System-Variablen.
;******************************************************************************
.RAM_SIZE		= $40				;64 * 64K = 4096K = 4Mb.
.RAM_MAX_SIZE		= $40				;64 * 64K = 4096K = 4Mb.
.MAX_SPOOL_DOC		= $0f				;Max. 15 Dokumente im Spoolerspeicher.
.MAX_SPOOL_SIZE		= RAM_MAX_SIZE			;Max. Anzahl Bänke für Druckerspooler.
.MAX_SPOOL_STD		= $04				;Vorgabe für Spoolerspeicher.
.MAX_TASK_ACTIV		= $09				;Wert darf nicht größer "9 Tasks" sein!
.MAX_FILES_BROWSE	= 255				;Anzahl Dateien in Dialogbox.
;******************************************************************************

			n "tmp.G3_Kernal64"
			f 3				;Data
			c "MegaPatch64 V3.0"
			a "Markus Kanet"

			o $9d80
			p $c22c

;******************************************************************************
;*** Laufwerksroutinen Teil #1.
;******************************************************************************
			t "-G3_ReadFile"
			t "-G3_WriteFile"
			t "-G3_VerWrFile"

;*** Zeiger auf Sektorspeicher setzen.
:Vec_diskBlkBuf		lda	#>diskBlkBuf		;Zeiger auf Zwischenspeicher.
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L
			rts
;******************************************************************************

;*** Serien-Nummer des GEOS-Systems.
.SerialNumber		t "-G3_GEOS_ID"

;******************************************************************************
;*** Zeiger auf Laufwerkstreiber setzen.
;******************************************************************************
			t "-G3_SetVecDkRAM"
;******************************************************************************

;*** GEOS-Routine aufrufen.
; AKKU = Zeiger auf LOW -Byte.
; xReg = Zeiger auf HIGH-Byte.
:xCallRoutine		cmp	#$00
			bne	:1
			cpx	#$00			;Adresse = $0000 ?
			beq	:2			;Ja, nicht ausführen.
::1			sta	CallRoutVec +0
			stx	CallRoutVec +1
			jmp	(CallRoutVec)
::2			rts

;*** GEOS-Systeminterrupt!
:GEOS_IRQ		cld
			sta	IRQ_BufAkku
			pla
			pha
			and	#%00010000		;Standard IRQ ?
			beq	:1			;Ja, weiter...
			pla
			jmp	(BRKVector)		;BRK-Abbruch.

::1			txa				;Register zwischenspeichern.
			pha
			tya
			pha

			lda	CallRoutVec   +1	;Variablen zwischenspeichern.
			pha
			lda	CallRoutVec   +0
			pha
			lda	returnAddress +1
			pha
			lda	returnAddress +0
			pha

			ldx	#$00
::2			lda	r0L,x
			pha
			inx
			cpx	#$20
			bne	:2

			lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#$35			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	dblClickCount		;Auf Doppelklick testen ?
			beq	:3			;Nein, weiter...
			dec	dblClickCount		;Zähler korrigieren.
::3			ldy	keyMode			;Erste Taste einlesen ?
			beq	:4			;Ja, weiter...
			iny				;Taste in ":currentKey" ?
			beq	:4			;Nein, weiter...
			dec	keyMode
::4			jsr	GetMatrixCode

			lda	AlarmAktiv		;Zähler für Alarm-Wiederholung
			beq	:5			;gesetzt ?  => Nein, weiter...
			dec	AlarmAktiv		;Zähler korrigieren.

::5			lda	intTopVector +0		;IRQ/GEOS.
			ldx	intTopVector +1
			jsr	CallRoutine
			lda	intBotVector +0		;IRQ/Anwender.
			ldx	intBotVector +1
			jsr	CallRoutine

			lda	#$01			;Raster-IRQ-Flag setzen.
			sta	grirq

			pla				;CPU-Register wieder
			sta	CPU_DATA		;zurücksetzen.

			ldx	#$1f			;Variablen zurückschreiben.
::6			pla
			sta	r0L,x
			dex
			bpl	:6

			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			pla
			sta	CallRoutVec   +0
			pla
			sta	CallRoutVec   +1

			pla				;Register wieder einlesen.
			tay
			pla
			tax
			lda	IRQ_BufAkku

;*** Einsprung bei RESET/NMI.
:IRQ_END		rti

;*** Datenfelder.
.BitData1		b $80,$40,$20,$10,$08,$04,$02
.BitData2		b $01,$02,$04,$08,$10,$20,$40,$80
.BitData3		b $00,$80,$c0,$e0,$f0,$f8,$fc,$fe
.BitData4		b $7f,$3f,$1f,$0f,$07,$03,$01,$00

;******************************************************************************
;*** Neue MP3-Variablen.
;******************************************************************************
			t "-G3_MP3_VAR"
.C_FarbTab		t "-G3_MP3_COLOR"
.C_Balken		= C_FarbTab +0  ;Scrolbalken.
.C_Register		= C_FarbTab +1  ;Registerkarten: Aktiv.
.C_RegisterOff		= C_FarbTab +2  ;Registerkarten: Inaktiv.
.C_RegisterBack		= C_FarbTab +3  ;Registerkarten: Hintergrund.
.C_Mouse		= C_FarbTab +4  ;Mausfarbe (nicht verwendet).
.C_DBoxTitel		= C_FarbTab +5  ;Dialognox: Titel.
.C_DBoxBack		= C_FarbTab +6  ;Dialogbox: Hintergrund + Text.
.C_DBoxDIcon		= C_FarbTab +7  ;Dialogbox: System-Icons.
.C_FBoxTitel		= C_FarbTab +8  ;Dateiauswahlbox: Titel.
.C_FBoxBack		= C_FarbTab +9  ;Dateiauswahlbox: Hintergrund + Text.
.C_FBoxDIcon		= C_FarbTab +10 ;Dateiauswahlbox: System-Icons.
.C_FBoxFiles		= C_FarbTab +11 ;Dateiauswahlbox: Dateifenster.
.C_WinTitel		= C_FarbTab +12 ;Fenster: Titel.
.C_WinBack		= C_FarbTab +13 ;Fenster: Hintergrund.
.C_WinShadow		= C_FarbTab +14 ;Fenster: Schatten.
.C_WinIcon		= C_FarbTab +15 ;Fenster: System-Icons.
.C_PullDMenu		= C_FarbTab +16 ;PullDown-Menu.
.C_InputField		= C_FarbTab +17 ;Registerkarten: Text-Eingabefeld.
.C_InputFieldOff	= C_FarbTab +18 ;Registerkarten: Inaktives Optionsfeld.
.C_GEOS_BACK		= C_FarbTab +19 ;GEOS-Standard: Hintergrund.
.C_GEOS_FRAME		= C_FarbTab +20 ;GEOS-Standard: Rahmen.
.C_GEOS_MOUSE		= C_FarbTab +21 ;GEOS-Standard: Mauszeiger.

;******************************************************************************

;******************************************************************************
;*** Speicher bis $A000 mit $00-Bytes auffüllen.
;******************************************************************************
:_01T			e $a000
:_01
;******************************************************************************

;******************************************************************************
;*** Speicher bis $BF40 mit $00-Bytes auffüllen.
;******************************************************************************
:_SYS_BackGfxT		e $bf40
:_SYS_BackGfx
;******************************************************************************
.OrgMouseData		b %11111100,%00000000,%00000000
			b %11111000,%00000000,%00000000
			b %11110000,%00000000,%00000000
			b %11111000,%00000000,%00000000
			b %11011100,%00000000,%00000000
			b %10001110,%00000000,%00000000
			b %00000111,%00000000,%00000000
			b %00000010

;******************************************************************************
;*** System-Icons #1.
;******************************************************************************
			t "-G3_SysIcon1"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $C000 mit $00-Bytes auffüllen.
;******************************************************************************
:_02T			e $c000
:_02
;******************************************************************************
;*** ACHTUNG!
;*** Wenn möglich, Systemvariablen im Bereich $C000-$CFFF ablegen, da dieser
;*** Bereich über den Switcher beim Task-Wechsel gerettet wird.
;*** Beispiel ist ":EndGetStrgAdr". Würde diese Adresse im Bereich ab
;*** $E000-$FFFF abgelegt (bei der ":GetString"-Routine), würde die Adresse
;*** evtl. von einem anderen Task zerstört. Im unteren RAM wird der Inhalt
;*** der Adresse bei der Rückkehr zum aktuellen Task wieder korrekt gesetzt,
;*** da der Speicher aus dem RAM wieder eingelesen wird.

;*** Beginn des GEOS-Kernals ab $c000
.SystemReBoot		jmp	ReBootGEOS		;GEOS wieder einlesen.
.ResetHandle		jmp	BASE_AUTO_BOOT		;RESET-Routine.

.bootName		b "GEOS.BOOT"
.version		b MPatchVersion			;Versions-Nr.

if Sprache = Deutsch
.nationality		b $01				;Landessprache.
endif

if Sprache = Englisch
.nationality		b $00				;Landessprache.
endif

;--- Ergänzung: 27.11.22/M.Kanet
;Es gab bisher keine Möglichkeit die
;genaue MegaPatch-Version zu ermitteln.
;Das Byte an dieser Stelle ist laut dem
;GEOS Reference Guide "Reserved" = $00.
;Zukünftig findet man hier die Version
;von GEOS/MegaPatch ($3a=3.3r10).
.sysVersion		b SYSREV			;System-Version.

.sysFlgCopy		b %01110000
.c128Flag		b $00

.MP3_CODE		b "MP"

.EndGetStrgAdr		w $0000				;Rücksprungadresse GetString.

.dateCopy		b $58,$07,$06			;Nur Kopie des Datums.
;			b $07,$06			;Frühere MegaPatch-Versionen.
			b $00,$00			;Reserviert.

;*** GEOS neu starten.
:ReBootGEOS		ldx	#$06
::1			lda	RamBootData,x
			sta	r0L        ,x
			dex
			bpl	:1

			ldy	#%10010001		;Code für RAM-Bereich laden.
			jsr	xDoRAMOp_NoChk		;Directeinsprung "FetchRAM".
			jmp	BASE_REBOOT

;*** Transferdaten.
:RamBootData		w	BASE_REBOOT
			w	R1_ADDR_REBOOT
			w	R1_SIZE_REBOOT
			b	$00

;******************************************************************************
;*** DoRamOp-Funktionen.
;*** Funktionen befinden sich in separatem Quelltext und werden beim
;*** booten durch das StartProgramm an die Speichererweiterung angepaßt.
;******************************************************************************
.BASE_RAM_DRV

;*** Einsprungtabelle RAM-Tools.
;Dummy-Tabelle. Wichtig sind nur die Einsprungadressen:
;Diese müssen unverändert auch in den RAM-Patches am Anfang stehen.
:xVerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			b $2c
:xStashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			b $2c
:xSwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			b $2c
:xFetchRAM		ldy	#%10010001		;RAM-Bereich laden.
:xDoRAMOp		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	ramOpErr		; => Nein, Fehler...

;--- Einsprung für BootGEOS ($c000).
:xDoRAMOp_NoChk

:ramOpErr		rts

;******************************************************************************
;*** Speicher mit $00-Bytes auffüllen.
;*** Die max. Adresse hängt von der Größe der RAM-Treiber ab:
;*** o.DvRAM_RL   $C07A-$C0D9 = 96Bytes
;*** o.DvRAM_SCPU $C07A-$C0CB = 82Bytes
;*** o.DvRAM_CREU $C07A-$C0CA = 81Bytes
;*** o.DvRAM_GRAM $C07A-$C0CB = 82Bytes
;******************************************************************************
.SIZE_RAM_DRV		= 96

;******************************************************************************
;*** Speicher mit $00-Bytes auffüllen.
;******************************************************************************
:_14T			e BASE_RAM_DRV +SIZE_RAM_DRV
:_14
;******************************************************************************
.BASE_RAM_DRV_END
;******************************************************************************

;*** Zeiger auf nächstes Byte setzen.
:SetNxByte_r0		inc	r0L
			bne	:1
			inc	r0H
::1			rts

;*** Register ":r3" auf nächstes Byte setzen.
:SetNextByte_r3		inc	r3L
			bne	:1
			inc	r3H
::1			rts

;******************************************************************************
;*** Zufallszahl berechnen.
;******************************************************************************
			t "-G3_GetRandom"
;******************************************************************************

;******************************************************************************
;*** Sprungtabelle für MP3.
;******************************************************************************
::C0DC			t "-G3_JumpTabMP"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $C100 mit $00-Bytes auffüllen.
;******************************************************************************
:_03T			e $c100
:_03
;******************************************************************************
;*** GEOS-Sprungtabelle.
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

;*** GEOS-Sprungtabelle.
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

;******************************************************************************
;*** Neue I/O-Routinen.
;*** Die Routinen werden bei Einsatz einer SuperCPU auf das
;*** SuperCPU-Patch umgestellt.
;******************************************************************************
.InitForIO		jmp	($9000)
.DoneWithIO		jmp	($9002)
;******************************************************************************

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

;******************************************************************************
;*** Speicher bis $C2D7 mit $00-Bytes auffüllen.
;******************************************************************************
:_04T			e $c2d7
:_04
;******************************************************************************
;*** Neue Routine für GEOS-IRQ. Feste Adr.= $C2D7! Notwendig da einige
;    Programme nicht über ":InterruptMain" einspringen, sondern nach $C2D7 =
;    ":MainIRQ" um die Mausinformationen zu initialisieren (z.B. GeoWrite 64)
;******************************************************************************
			t "-G3_NewMainIRQ"
;******************************************************************************

;******************************************************************************
;*** Neue FistInit-Routine.
;******************************************************************************
			t "-G3_New1stInit"
;******************************************************************************

;******************************************************************************
;*** Prüfsummen-Routine.
;******************************************************************************
			t "-G3_NewCRC"
;******************************************************************************

;******************************************************************************
;*** Neue ToBASIC-Routine.
;******************************************************************************
			t "-G3_NewToBasic"
;******************************************************************************

;******************************************************************************
;*** Neue PANIC!-Routine.
;******************************************************************************
			t "-G3_NewPanicBox"
;******************************************************************************

;******************************************************************************
;*** Neue EnterDeskTop-Routine.
;******************************************************************************
			t "-G3_NewEnterDT"
;******************************************************************************

;******************************************************************************
;*** Hintergrundbild einlesen.
;******************************************************************************
			t "-G3_GetBackScrn"
;******************************************************************************

;******************************************************************************
;*** GEOS-Serien-Nummer einlesen.
;******************************************************************************
			t "-G3_GetSerNr"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $C3A8 mit $00-Bytes auffüllen.
;******************************************************************************
:_05T			e $c3a8
:_05
;******************************************************************************

;*** Applikation starten.
:xStartAppl		sei				;IRQ sperren.
			cld				;"DEZIMAL"-Flag löschen.
			ldx	#$ff			;Stackzeiger löschen.
			txs
			jsr	SaveFileData		;Startwerte speichern.
			jsr	GEOS_Init0		;GEOS initialisieren.
			jsr	xUseSystemFont		;GEOS-Zeichensatz aktivieren.
			jsr	LoadFileData		;Startwerte zurückschreiben.
			ldx	r7H
			lda	r7L
			jmp	InitMLoop1		;Programm starten.

;*** Dialogbox: Bootdisk einlegen.
.DlgBoxDTdisk		b %11100001
			b DBTXTSTR,$10,$16
			w DlgBoxDTopMsg1
			b DBTXTSTR,$10,$26
			w DlgBoxDTopMsg2
			b OK      ,$11,$48
			b NULL

if Sprache = Deutsch
.DeskTopName		b "DESK TOP"
.DeskTopNameEnd		b NULL

;******************************************************************************
;*** Speicher bis $C3D8 mit $00-Bytes auffüllen. Feste Adresse!
;******************************************************************************
:_06T			e $c3d8
:_06
;******************************************************************************
.DlgBoxDTopMsg1		b $18 ;BOLDON
			b "Bitte eine Diskette einlegen"
.DlgBoxDTopMsg1End	b NULL
.DlgBoxDTopMsg2		b "die deskTop enthält! "
.DlgBoxDTopMsg2End	b NULL
endif

if Sprache = Englisch
.DeskTopName		b "DESK TOP"
.DeskTopNameEnd		b NULL

;******************************************************************************
;*** Speicher bis $C3D9 mit $00-Bytes auffüllen. Feste Adresse!
;******************************************************************************
:_06T			e $c3d9
:_06
;******************************************************************************
			b $1b ;PLAINTEXT
.DlgBoxDTopMsg1		b $18 ;BOLDON
			b "Please insert a disk"
.DlgBoxDTopMsg1End	b NULL
.DlgBoxDTopMsg2		b "with deskTop V1.5 or higher"
.DlgBoxDTopMsg2End	b NULL
endif

;******************************************************************************
;*** Speicher bis $C40C mit $00-Bytes auffüllen. Feste Adresse!
;******************************************************************************
:_07T			e $c40c
:_07
;******************************************************************************

;******************************************************************************
;*** Neue MainLoop-Routine ab $C40C.
;******************************************************************************
			t "-G3_NewMainLoop"
;******************************************************************************

;******************************************************************************
;*** Neue ResetScreen-Routine.
;******************************************************************************
			t "-G3_ResetScreen"
;******************************************************************************

;*** GEOS initialisieren.
:GEOS_Init0		lda	#$00			;Flag für Dialogbox/SwapFile
			sta	Flag_ExtRAMinUse	;zurücksetzen.

:GEOS_Init1		jsr	InitGEOS		;GEOS-Register definieren.

;*** GEOS-Variablen initialisieren.
:GEOS_InitVar		lda	#>InitVarData		;RAM-Bereiche initialisieren.
			sta	r0H
			lda	#<InitVarData
			sta	r0L
			jmp	xInitRam

;*** Kernal-Variablen initialisieren.
:InitGEOS		lda	#$2f
			sta	zpage
			lda	#$36
			sta	CPU_DATA

			ldx	#$07
			lda	#$ff
::1			sta	KB_MultipleKey,x
			sta	KB_LastKeyTab ,x
			dex
			bpl	:1

			stx	keyMode
			stx	$dc02
			inx
			stx	keyBufPointer
			stx	MaxKeyInBuf
			stx	$dc03
			stx	$dc0f
			stx	$dd0f

			lda	PAL_NTSC		;PAL/NTSC-Flag auslesen.
			lsr				;Bit#0: PAL = %0, NTSC = %1
			txa
			ror
			sta	$dc0e			;Uhrzeit-Flag für PAL/NTSC
			sta	$dd0e			;korrigieren. SCPU64-V1-Bug!!!

			lda	$dd00
			and	#$30
			ora	#$05
			sta	$dd00
			lda	#$3f
			sta	$dd02
			lda	#$7f
			sta	$dc0d
			sta	$dd0d

			ldy	#$00
::3			lda	InitVICdata,y		;Neuen Wert für VIC-Register
			cmp	#$aa			;einlesen. Code $AA ?
			beq	:4			;Ja, übergehen.
			sta	$d000      ,y		;Neuen VIC-Wert schreiben.
::4			iny
			cpy	#$1e
			bne	:3

			jsr	SetKernalVec		;IO-Vektoren initialisieren.

			lda	#$30
			sta	CPU_DATA

			jsr	SetMseFullWin		;Mausgrenzen zurücksetzen.
			jmp	SCPU_SetOpt		;GEOS-Optimierung festlegen.

;*** Kernal-Variablen initialisieren.
.SetKernalVec		ldx	#$20
::1			lda	$fd30  -1,x
			sta	irqvec -1,x
			dex
			bne	:1
			rts

;*** Tabelle zum Initialisieren der GEOS-Variablen. Aufruf über ":InitRam".
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
			w InterruptMain			;intTopVector
			w $0000				;intBotVector
			w $0000				;mouseVector
			w $0000				;keyVector
			w $0000				;inputVector
			w $0000				;mouseFaultVec
			w $0000				;otherPressVec
			w $0000				;StringFaultVec
			w $0000				;alarmTmtVector
			w Panic				;BRKVector
			w RecoverRectangle		;RecoverVector
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

;*** Initialisierungswerte für VIC.
:InitVICdata		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$3b,$fb,$aa,$aa,$01,$08,$00
			b $38,$0f,$01,$00,$00,$00

;*** Speicherbereich initialisieren.
:xInitRam		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			ora	(r0L),y			;Nächste Adressen = $0000 ?
			beq	ExitInit		;Ja, Ende...

			lda	(r0L),y
			sta	r1H
			iny
			lda	(r0L),y			;Anzahl zu initialisierender
			sta	r2L			;Bytes einlesen.
			iny
::1			tya
			tax
			lda	(r0L),y			;Bytewert aus Tabelle lesen und
			ldy	#$00			;in Zielspeicherbereich über-
			sta	(r1L),y			;tragen.
			inc	r1L
			bne	:2
			inc	r1H
::2			txa
			tay
			iny
			dec	r2L
			bne	:1
			tya
			clc				;Zeiger auf nächsten Tabellen-
			adc	r0L			;bereich richten.
			sta	r0L
			bcc	:3
			inc	r0H
::3			jmp	xInitRam		;Nächsten Bereich füllen.
:ExitInit		rts

;*** Mauszeiger abfragen über System-IRQ! Setzt Variablen und Mauszeiger.
:InitMouseData		jsr	UpdateMouse		;Mausposition einlesen.
			bit	mouseOn			;Mauszeiger aktiv ?
			bpl	ExitInit		;Nein, weiter...
			jsr	SetMseToArea
			lda	#$00			;Zeiger auf Sprite #0 für
			sta	r3L			;Mauszeiger.
			lda	msePicPtr+1		;Zeiger auf Grafik-Daten für
			sta	r4H			;Sprite #0 = Mauszeiger.
			lda	msePicPtr+0
			sta	r4L
			jsr	DrawSprite		;Maus-Sprite erstellen.
			lda	mouseXPos+1
			sta	r4H
			lda	mouseXPos+0
			sta	r4L
			lda	mouseYPos
			sta	r5L
			jsr	PosSprite		;Mauszeiger positionieren.
			jmp	EnablSprite		;Sprite einschalten.

;*** Inline: Speicherbereich löschen.
:xi_FillRam		pla				;Rücksprungadresse vom Stapel
			sta	returnAddress +0	;einlesen und als Zeiger auf
			pla				;Inline-Daten verwenden.
			sta	returnAddress +1
			jsr	Get2Word1Byte		;Zwei WORDs und ein BYTE holen.
			jsr	FillRam			;Speicher füllen.

			php
			lda	#$06

;*** Inline-Routine beenden.
:xDoInlineReturn	clc
			adc	returnAddress +0
			sta	returnAddress +0
			bcc	:1
			inc	returnAddress +1
::1			plp
			jmp	(returnAddress)

;******************************************************************************
;*** MoveData/FillRAM-Routine.
;*** Bei einer SuperCPU wird beim booten hier das SuperCPU-Patch installiert.
;******************************************************************************
.BASE_SCPU_DRV

if TRUE
;--- GEOS-V2-Routinen einbinden.
			t "-G3_FillRam"
			t "-G3_NewMoveData"

endif
if FALSE
;--- SuperCPU-Routinen einlesen.
			t "-G3_Patch_SCPU"

;--- Labels für Sprungtabelle definieren.
:xClearRam		= s_ClearRam
:xFillRam		= s_FillRam
:xi_MoveData		= s_i_MoveData
:xMoveData		= s_MoveData
:xInitForIO		= s_InitForIO
:xDoneWithIO		= s_DoneWithIO
:xSCPU_OptOn		= s_SCPU_OptOn
:xSCPU_OptOff		= s_SCPU_OptOff
:xSCPU_SetOpt		= s_SCPU_SetOpt
endif

;******************************************************************************
;*** Speicher bis $xxxx mit $00-Bytes auffüllen.
;*** Hier muß der größte Wert von 'BASE_SCPU_DRV_END' eingetragen werden,
;*** welcher beim Assemblieren mit SCPU = FALSE/TRUE entsteht, damit das
;*** SCPU-Patch auch im Kernal Platz hat!
;*** SCPU = FALSE: $c60c-$c6d8 = 205Bytes
;*** SCPU = TRUE : $c60c-$c6c3 = 184Byte
;******************************************************************************
.SIZE_SCPU_DRV		= 205

:_13T			e BASE_SCPU_DRV +SIZE_SCPU_DRV
:_13
;******************************************************************************

.BASE_SCPU_DRV_END

;******************************************************************************
;*** SuperCPU-Pause ausführen..
;******************************************************************************
			t "-G3_SCPU_Pause"
;******************************************************************************

;******************************************************************************
;*** Disketten-Routinen Teil #1.
;******************************************************************************
			t "-G3_GetCurDkNm"
			t "-G3_NewGetFHdr"
;******************************************************************************

;******************************************************************************
;*** Sprite-Routinen.
;******************************************************************************
			t "-G3_Sprites"
;******************************************************************************

;******************************************************************************
;*** String/Arithmetik-Routinen.
;*** Müssen im Bereich $C000-$CFFF liegen da beim Update noch alte RAM-Treiber
;*** aktiv sind, welche mit diesen Routinen bei aktiviertem I/O hantieren.
;******************************************************************************
			t "-G3_CopyString"
			t "-G3_CmpString"
			t "-G3_DivMult"
;******************************************************************************

;******************************************************************************
;*** Prozess-Routinen.
;******************************************************************************
			t "-G3_Process"
;******************************************************************************

;******************************************************************************
;*** Neue GetScanLine-Routine.
;******************************************************************************
			t "-G3_NewGetScanL"
;******************************************************************************

;******************************************************************************
;*** Grafikroutinen C64.
;******************************************************************************
			t "-G3_Grafx64"
;******************************************************************************

;******************************************************************************
;*** Zeiger auf RAM-Routinen einlesen.
;******************************************************************************
			t "-G3_SetVecRAM"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $D000 mit $00-Bytes auffüllen.
;******************************************************************************
:_08T			e $d000
:_08
;******************************************************************************

;******************************************************************************
;*** GEOS-Füllpatterns.
;*** Muss bei $xx00 beginnen, damit
;*** DualTop64 über ":curPattern" das
;*** Pattern#0 erkennt. Ansonsten wird
;*** der Dateiname mit REVON angezeigt.
;******************************************************************************
			t "-G3_Patterns"
;******************************************************************************

;******************************************************************************
;*** Zeichensatz-Daten.
;******************************************************************************
			t "-G3_BoldData"
;******************************************************************************

;*** GEOS-Font in Quellcode einbinden.
if Sprache = Deutsch
:BSW_Font		v 9,"fnt.GEOS 64.de"
endif

if Sprache = Englisch
:BSW_Font		v 9,"fnt.GEOS 64.us"
endif

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
			bcc	:1			;Nein, weiter...
			ldx	#$03			;Geht nicht! Da Startbyte +
							;4x Datenbyte + Abschlußbyte
							;zusammen bereits 48 Bit sind!
::1			lda	CalcBitDataL,x		;Berechnungsroutine für
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
			beq	:2			;Nein, weiter...
			lda	#%10000000
::2			sta	r8H			;Outline-Modus merken.

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
			bmi	:4			;testen ? Nein, weiter...

			lda	rightMargin+1		;Zeichen innerhalb
			cmp	r11H			;Textfenster ?
			bne	:3
			lda	rightMargin+0
			cmp	r11L
::3			bcc	RightOver		;Nein, nicht ausgeben.

::4			lda	currentMode
			and	#%00010000		;Schriftstil einlesen.
			bne	:5			;Kursiv ? Ja, weiter...
			tax				;Versatzmaß für Kursiv = $00.

::5			txa				;Versatzmaß für Kursiv = $08.
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

			jsr	TestLeftMargin
			bcs	LeftOver		;Ja, Fehlerbehandlung.

			jsr	StreamInfo

			ldx	#$00			;Zeichen nicht invertieren.
			lda	currentMode
			and	#%00100000		;REVERS-Modus aktiv ?
			beq	:7			;Nein, weiter...
			dex				;Zeichen invertieren.
::7			stx	r10L			;REVERS-Modus speichern.
			clc				;Kein Fehler, OK...
			rts

;*** Berechnungsroutinen für Zeichenausgabe.
:CalcBitDataL		b < Char24Bit,< Char32Bit,< Char40Bit,< Char48Bit
:CalcBitDataH		b > Char24Bit,> Char32Bit,> Char40Bit,> Char48Bit

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

;*** Linken Rand prüfen.
:TestLeftMargin		lda	leftMargin+1
			cmp	r11H
			bne	:1
			lda	leftMargin+0
			cmp	r11L
::1			rts

;*** Bit-Stream-Infos einlesen.
;    Startbyte = Teilweise Bits setzen.
;    Datenbyte = 8 Bit-Stream-Byte.
;    Endbyte   = Teilweise Bits setzen.
:StreamInfo		ldx	r1H			;Grafikzeile berechnen.
			jsr	GetScanLine

;*** Erstes Byte bestimmen.
			lda	StrBitXposL		;X-Koordinate einlesen.
			ldx	StrBitXposH		;Auf Bereichsüberschreitung
			bmi	:2			;testen ? Nein, weiter...
			cpx	leftMargin+1
			bne	:1
			cmp	leftMargin+0
::1			bcs	:3			;Bereich nicht überschritten.

::2			ldx	leftMargin+1		;Wert für linken Rand als neue
			lda	leftMargin+0		;X-Koordinate setzen.

::3			pha				;LOW-Byte merken.
			and	#%11111000		;Zeiger auf erstes Byte für
			sta	r4L			;Grafikdaten berechnen.
			cpx	#$00
			bne	:4
			cmp	#%11000000
			bcc	:6

::4			sec
			sbc	#$80
			pha
			lda	r5L
			clc
			adc	#$80
			sta	r5L
			sta	r6L
			bcc	:5
			inc	r5H
			inc	r6H
::5			pla

::6			sta	r1L			;Zeiger auf Grafikspeicher.

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
			bpl	:7			;Nein, weiter...
			lda	#$00			;X-Koordinate auf linken Rand.
::7			sta	CurStreamCard		;CARD-Position merken.

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
			bne	:8
			cmp	r11L
::8			bcs	:9			;Nein, weiter...

			tay
::9			tya
			and	#%00000111
			tax
			lda	BitData4,x		;Bit-Maske für die zu
			sta	r4H			;übernehmenden Bits berechnen.
			eor	#%11111111		;Bit-Maske für die zu
			sta	r9H			;setzenden Bits berechnen.

			tya
			sec
			sbc	r4L
			bpl	:10
			lda	#$00

::10			lsr
			lsr
			lsr
			clc
			adc	CurStreamCard
			sta	r8L			;Anzahl Stream-Bytes merken.
			cmp	r3H			;Muß größer als die Anzahl der
			bcs	:11			;Datenbytes sein!
			lda	r3H

::11			cmp	#$03			;Mind. 1 Datenbyte ?
			bcs	:13			;Ja, weiter...
			cmp	#$02			;Nur Start/Endbyte ?
			bne	:12			;Nein, weiter... (1 Byte!)
			lda	#$01			;Immer nur 1 Byte setzen.

::12			asl				;Anzahl Bits berechnen.
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
			adc	#<A1
			tay
			lda	#$00
			adc	#>A1
			bne	:14

::13			lda	#>PrepBitStream
			ldy	#<PrepBitStream
::14			sta	r12H
			sty	r12L
:CurModusOK		clc
			rts

;*** Einsprungadressen in die
;    Berechnungsroutinen.
:BitMoveRout		b (D0a - A1), (C1 - A1)
			b (C2 - A1), (C3 - A1)
			b (C4 - A1), (C5 - A1)
			b (C6 - A1), (C7 - A1)
			b (A8 - A1), (A7 - A1)
			b (A6 - A1), (A5 - A1)
			b (A4 - A1), (A3 - A1)
			b (A2 - A1), (A1 - A1)

			b (D0a - A1), (D1 - A1)
			b (D2 - A1), (D3 - A1)
			b (D4 - A1), (D5 - A1)
			b (D6 - A1), (D7 - A1)
			b (B8 - A1), (B7 - A1)
			b (B6 - A1), (B5 - A1)
			b (B4 - A1), (B3 - A1)
			b (B2 - A1), (B1 - A1)

;*** Baseline und Kursivmöglichkeit überprüfen.
:ChkBaseItalic		lda	currentMode		;Unterstreichen aktiv ?
			bpl	:2			;Nein, weiter...

			ldy	r1H
			cpy	BaseUnderLine		;Unterstreichen möglich ?
			beq	:1			;Ja, weiter...
			dey				;Auf Baseline testen.
			cpy	BaseUnderLine		;Unterstreichen möglich ?
			bne	:2			;Nein, weiter...

::1			lda	r10L			;Baseline möglich,
			eor	#%11111111		;Invertieren der letzten
			sta	r10L			;Zeichensatz-Zeile.

::2			lda	currentMode
			and	#%00010000		;Kursiv-Modus aktiv ?
			beq	CurModusOK		;Nein, weiter...

			lda	r10H			;Zähler für Pixelverschiebung
			lsr				;bei Kursivschrift einlesen.
			bcs	:5			;Verschieben ? Nein, weiter...

			ldx	StrBitXposL		;X-Koordinate korrigieren.
			bne	:3
			dec	StrBitXposH
::3			dex
			stx	StrBitXposL

			ldx	r11L
			bne	:4
			dec	r11H
::4			dex
			stx	r11L

			jsr	StreamInfo

::5			lda	rightMargin+1
			cmp	StrBitXposH
			bne	:6
			lda	rightMargin+0
			cmp	StrBitXposL
::6			bcc	:8
			jmp	TestLeftMargin

::8			sec
:StreamOverRun		rts

;*** Neue Grafikdaten in Grafikdatenspeicher kopieren.
:WriteNewStream		ldy	r1L			;Zeiger auf Grafikspeicher.
			ldx	CurStreamCard
			lda	SetStream,x
			cpx	r8L			;Nur 1 CARD berechnen ?
			beq	:5			;Ja, weiter...
			bcs	StreamOverRun		;Überlauf, Ende...

;*** Startbyte definieren.
			eor	r10L			;Zeichen invertieren.
			and	r9L			;Die zu übernehmenden Bits
			sta	StreamByteData +1	;isolieren und merken.
			lda	r3L			;Bits aus Grafikspeicher
			jsr	AddStreamByte		;einlesen und isolieren.
							;Daten verknüpfen.

;*** Datenbytes definieren.
::2			tya				;Zeiger auf nächstes CARD
			clc				;setzen.
			adc	#$08
			tay
			inx
			cpx	r8L			;Letztes CARD erreicht ?
			beq	:3			;Ja, weiter...

			lda	SetStream,x		;Datenbyte einlesen.
			eor	r10L			;Invertieren.
			jsr	ByteIn_r5_r6		;In Grafikspeicher kopieren.
			jmp	:2			;Nächstes Card setzen.

;*** Bits im letzten CARD bestimmen.
::3			lda	SetStream,x		;Letztes CARD bestimmen.
			eor	r10L			;Zeichen invertieren.
			and	r9H			;Die zu übernehmenden Bits
			sta	StreamByteData +1	;isolieren und merken.
			lda	r4H			;Bits aus Grafikspeicher
			jmp	AddStreamByte		;einlesen und merken.

;*** Nur 1 CARD bestimmen.
::5			eor	r10L			;Invertieren.
			and	r9H			;Die zu übernehmenden Bits
			eor	#$ff			;isolieren und merken.
			ora	r3L
			ora	r4H
			eor	#$ff
			sta	StreamByteData +1
			lda	r3L			;Die ersten und letzten Bits
			ora	r4H			;im CARD isolieren und merken.

;*** Grafikdaten in aktuellem Byte einlesen und mit
;    den neuen Grafikdaten verküpfen.
:AddStreamByte		and	(r6L),y
:StreamByteData		ora	#$00			;Neue Grafikdaten addieren.

;*** Ein Byte in Vektor ":r5" und ":r6" kopieren.
;    yReg dient als Zeiger auf Speicherstelle.
:ByteIn_r5_r6		sta	(r6L),y
			sta	(r5L),y
			rts

;*** Neuen Bit-Stream initialisieren.
:InitNewStream		ldx	r8L			;Anzahl Bit-Stream-Bytes.

			lda	#$00
::1			sta	NewStream,x		;Datenspeicher für die neuen
			dex				;Bit-Stream-Daten löschen.
			bpl	:1

			lda	r8H
			and	#%01111111		;Schriftstil definiert ?
			bne	:5			;Ja, weiter...
::2			jsr	DefBitOutBold

::3			ldx	r8L
::4			lda	NewStream,x		;Neue Bit-Stream-Daten in
			sta	SetStream,x		;Zwischenspeicher kopieren.
			dex
			bpl	:4
			inc	r8H
			rts

::5			cmp	#$01
			beq	:6
			ldy	r10H
			dey				;Kursivschrift aktiv ?
			beq	:2			;Nein, weiter...

			dey				;Daten für Kursiv vorbereiten.
			php				;Dabei werden die oberen
			jsr	DefBitOutBold		;Pixelzeilen jeweils um 1 Bit
			jsr	AddFontWidth		;nach links zurückgesetzt.
			plp
			beq	:7

::6			jsr	AddFontWidth		;Zeiger auf Daten richten.
			jsr	CopyCharData		;Zeichendaten einlesen.
			jsr	DefBitOutBold		;Rahmen für Outline berechnen.
			lda	r2L			;Zeiger auf Daten wieder
			sec				;zurücksetzen.
			sbc	curSetWidth+0
			sta	r2L
			lda	r2H
			sbc	curSetWidth+1
			sta	r2H
::7			jsr	CopyCharData
			jsr	DefBitOutBold		;Rahmen für Outline berechnen.
			jsr	DefOutLine		;Fläche löschen -> Outline.
			jmp	:3			;Neuen Stream übertragen.

;*** Zeichensatzbreite! addieren.
:AddFontWidth		lda	curSetWidth+0
			clc
			adc	r2L
			sta	r2L
			lda	curSetWidth+1
			adc	r2H
			sta	r2H
			rts

;*** daten für Outline berechnen.
:DefOutLine		ldy	#$ff
::1			iny
			ldx	#$07
::2			lda	SetStream,y
			and	BitData2 ,x		;Bit gesetzt ?
			beq	:3			;Nein, weiter...
			lda	BitData2 ,x		;Bitmaske isolieren.
			eor	#%11111111
			and	NewStream,y		;Bit löschen und
			sta	NewStream,y		;zurückschreiben.
::3			dex				;8 Bit überprüft ?
			bpl	:2			;Nein, weiter...
			cpy	r8L			;Alle Cards geprüft ?
			bne	:1			;Nein, weiter...
			rts

;*** Bit-Verschiebung für Funktionen
;    Outline/Bold berechnen.
:DefBitOutBold		jsr	MovBitStrData

			ldy	#$ff
::1			iny

			ldx	#$07
::2			lda	SetStream  ,y
			and	BitData2   ,x
			beq	:7

			jsr	AddOutBoldData
			inx
			cpx	#$08
			bne	:3

			lda	NewStream-1,y
			ora	#%00000001
			sta	NewStream-1,y
			bne	:4

::3			jsr	AddOutBoldData
::4			dex
			dex
			bpl	:5

			lda	NewStream+1,y
			ora	#%10000000
			sta	NewStream+1,y
			bne	:6

::5			jsr	AddOutBoldData
::6			inx
::7			dex
			bpl	:2
			cpy	r8L
			bne	:1
			rts

;*** BIT-Stream für aktuelle Zeile um
;    1 Pixel verschieben.
:MovBitStrData		lsr	SetStream+0
			ror	SetStream+1
			ror	SetStream+2
			ror	SetStream+3
			ror	SetStream+4
			ror	SetStream+5
			ror	SetStream+6
			ror	SetStream+7
			rts

;*** Daten für Outline/Bold addieren.
:AddOutBoldData		lda	NewStream  ,y
			ora	BitData2   ,x
			sta	NewStream  ,y
			rts

;*** Zeichen ausgeben. Achtung!
;    ASCII-Code ist um #$20 reduziert!
:PrntCharCode		tay				;ASCII-Code merken.
			lda	r1H			;Y-Koordinate speichern.
			pha

			tya				;ASCII-Code zurücksetzen.
			jsr	DefCharData		;Zeichendaten definieren.
			bcs	:9			;Gültig ? Nein, übergehen.

::1			clc
			lda	currentMode
			and	#%10010000		;Kursiv/Unterstreichen ?
			beq	:2			;Nein, weiter...
			jsr	ChkBaseItalic		;Daten für Kursiv und
							;unterstreichen berechnen.
::2			php				;Schriftstile möglich ?
			bcs	:3			;Nein, übergehen.
			jsr	CopyCharData

::3			bit	r8H			;Outline-Modus aktiv ?
			bpl	:4			;Nein, weiter...
			jsr	InitNewStream
			jmp	:5

::4			jsr	AddFontWidth		;Zeiger auf näcste Bit-Stream-
							;datenzeile setzen.
::5			plp
			bcs	:7

			lda	r1H			;Ist Pixelzeile innerhalb des
			cmp	windowTop		;aktuellen Textfensters ?
			bcc	:7			;Nein, übergehen...
			cmp	windowBottom
			bcc	:6			;Ja, Daten ausgeben...
			bne	:7			;Nein, übergehen...
::6			jsr	WriteNewStream		;Grafikdaten ausgeben.

::7			inc	r5L			;Zeiger auf Grafikspeicher
			inc	r6L			;korrigieren.
			lda	r5L
			and	#$07
			bne	:8
			inc	r5H
			inc	r6H

			lda	r5L
			clc
			adc	#$38
			sta	r5L
			sta	r6L
			bcc	:8
			inc	r5H
			inc	r6H

::8			inc	r1H			;Zeiger auf nächste Pixelzeile.
			dec	r10H			;Alle Zeilen ausgegeben ?
			bne	:1			;Nein, weiter...
::9			pla				;Y-Koordinate zurücksetzen.
			sta	r1H
			rts

;*** Bit-Stream vorbereiten.
;    Nur bei max. 16 Pixel breiten
;    Zeichen (gleich 2 Byte).
:A1			lsr
:A2			lsr
:A3			lsr
:A4			lsr
:A5			lsr
:A6			lsr
:A7			lsr
:A8			jmp	DefBitStream2

:B1			lsr
			ror	SetStream+1
			ror	SetStream+2
:B2			lsr
			ror	SetStream+1
			ror	SetStream+2
:B3			lsr
			ror	SetStream+1
			ror	SetStream+2
:B4			lsr
			ror	SetStream+1
			ror	SetStream+2
:B5			lsr
			ror	SetStream+1
			ror	SetStream+2
:B6			lsr
			ror	SetStream+1
			ror	SetStream+2
:B7			lsr
			ror	SetStream+1
			ror	SetStream+2
:B8			jmp	DefBitStream2

:C1			asl
:C2			asl
:C3			asl
:C4			asl
:C5			asl
:C6			asl
:C7			asl
			jmp	DefBitStream2

:D1			asl	SetStream+2
			rol	SetStream+1
			rol
:D2			asl	SetStream+2
			rol	SetStream+1
			rol
:D3			asl	SetStream+2
			rol	SetStream+1
			rol
:D4			asl	SetStream+2
			rol	SetStream+1
			rol
:D5			asl	SetStream+2
			rol	SetStream+1
			rol
:D6			asl	SetStream+2
			rol	SetStream+1
			rol
:D7			asl	SetStream+2
			rol	SetStream+1
			rol
			jmp	DefBitStream2

;*** Bit-Stream vorbereiten.
;    Einügen/Löschen von Bits.
:PrepBitStream		sta	SetStream		;Erstes Byte speichern.

			lda	r7L			;Anzahl der zu löschenden
			sec				;Bits berechnen.
			sbc	BitStr1stBit
			beq	:2			;Bits löschen ? Nein, weiter...
			bcc	DefBitStream		;Ja, Bits löschen.

			tay				;Anzahl Bits als Zähler.
::1			jsr	MovBitStrData		;Bit-Stream um 1 Bit nach
							;rechts verschieben.
			dey				;Bits gelöscht ?
			bne	:1			;Nein, weiter...

::2			lda	SetStream
			jmp	DefBitStream2

;*** Überflüssige Bits in Bit-Stream
;    für aktuelles Zeichen löschen.
:DefBitStream		lda	BitStr1stBit		;Zeiger auf erstes Bit.
			sec				;Anzahl zu setzender Bits
			sbc	r7L			;abziehen und als Bit-Zähler
			tay				;in yReg kopieren.

::1			asl	SetStream+7		;Bit-Stream um 1 Bit nach
			rol	SetStream+6		;links verschieben.
			rol	SetStream+5
			rol	SetStream+4
			rol	SetStream+3
			rol	SetStream+2
			rol	SetStream+1
			rol	SetStream+0
			dey
			bne	:1

			lda	SetStream

;*** Bit-Stream-Daten bearbeiten.
:DefBitStream2		sta	SetStream

			bit	currentMode		;Schriftstil "Fett" ?
			bvc	D0a			;Nein, weiter...

			lda	#$00			;Bit #7 in aktuellem Bit-Stream
			pha				;nicht setzen.

			ldy	#$ff
::1			iny
			ldx	SetStream,y		;Bit-Stream-Byte einlesen.
			pla				;Bit #7-Wert einlesen.
			ora	BoldData ,x		;"Fettschrift"-Wert addieren.
			sta	SetStream,y		;Neues Bit-Stream-Byte setzen.
			txa
			lsr
			lda	#$00			;Bit #7 im nächstes Bytes des
			ror				;Bit-Streams definieren.
			pha
			cpy	r8L			;Alle Bytes des Bit-Streams
			bne	:1			;verdoppelt ? Nein, weiter...

			pla
:D0a			rts

;*** Erstes Datenbyte auswerten.
;    Einsprung in ":CharXYBit"
:CopyCharData		ldy	#$00
			jmp	(r13)

;*** Max. 24 Bit-Breites Zeichen.
:Char24Bit		sty	SetStream+1
			sty	SetStream+2
			lda	(r2L),y			;Datenbyte einlesen.
			and	BitStrDataMask		;Ungültige Bits am Anfang und
			and	r7H			;Ende entfernen.
			jmp	(r12)

;*** Max. 32 Bit-Breites Zeichen.
:Char32Bit		sty	SetStream+2
			sty	SetStream+3
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+1
:le356			lda	SetStream+0
			jmp	(r12)

;*** Max. 40 Bit-Breites Zeichen.
:Char40Bit		sty	SetStream+3
			sty	SetStream+4
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
			iny
			lda	(r2L),y
			sta	SetStream+1
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+2
			jmp	le356

;*** Max. 48 Bit-Breites Zeichen.
:Char48Bit		lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
::1			iny
			cpy	r3H
			beq	:2
			lda	(r2L),y
			sta	SetStream,y
			jmp	:1

::2			lda	(r2L),y
			and	r7H
			sta	SetStream+0,y
			lda	#$00
			sta	SetStream+1,y
			sta	SetStream+2,y
			beq	le356

;*** Variablen/Zwischenspeicher für Zeichenausgabe über PutChar.
:CurStreamCard		b $00
:StrBitXposL		b $34
:StrBitXposH		b $01

;*** Zeichen ausgeben.
:xPutChar		cmp	#$20
			bcs	:1
			tay
			lda	PrintCodeL -$08,y
			ldx	PrintCodeH -$08,y
			jmp	CallRoutine

::1			pha				;ASCII-Zeichen merken.
			ldy	r11H			;X-Koordinate speichern.
			sty	r13H
			ldy	r11L
			sty	r13L
			ldx	currentMode		;Zeichenbreite berechnen.
			jsr	xGetRealSize
			dey				;Breite -1 und zur
			tya				;aktuellen X-Koordinate
			clc				;addieren.
			adc	r13L
			sta	r13L
			bcc	:2
			inc	r13H

::2			lda	rightMargin+1		;Zeichen noch innerhalb
			cmp	r13H			;des Textfensters ?
			bne	:3
			lda	rightMargin+0
			cmp	r13L
::3			bcc	:7			;Nein, Fehlerbehandlung.

			jsr	TestLeftMargin
			beq	:5			;Ja, weiter...
			bcs	:6			;Nein, Fehlerbehandlung.

::5			pla
			sec
			sbc	#$20			;Zeichencode umrechnen und
			jmp	PrntCharCode		;Zeichen ausgeben.

::6			lda	r13L
			clc
			adc	#$01
			sta	r11L
			lda	r13H
			adc	#$00
			sta	r11H

::7			pla
			ldx	StringFaultVec+1
			lda	StringFaultVec+0
			jmp	CallRoutine

;*** Einsprung für Steuercodes.
:PrintCodeL		b < xBACKSPACE    , < xFORWARDSPACE
			b < xSetLF        , < xHOME
			b < xUPLINE       , < xSetCR
			b < xULINEON      , < xULINEOFF
			b < xESC_GRAPHICS , < xESC_RULER
			b < xREVON        , < xREVOFF
			b < xGOTOX        , < xGOTOY
			b < xGOTOXY       , < xNEWCARDSET
			b < xBOLDON       , < xITALICON
			b < xOUTLINEON    , < xPLAINTEXT

:PrintCodeH		b > xBACKSPACE    , > xFORWARDSPACE
			b > xSetLF        , > xHOME
			b > xUPLINE       , > xSetCR
			b > xULINEON      , > xULINEOFF
			b > xESC_GRAPHICS , > xESC_RULER
			b > xREVON        , > xREVOFF
			b > xGOTOX        , > xGOTOY
			b > xGOTOXY       , > xNEWCARDSET
			b > xBOLDON       , > xITALICON
			b > xOUTLINEON    , > xPLAINTEXT

;*** Textzeichen ausgeben.
:xSmallPutChar		sec
			sbc	#$20
			jmp	PrntCharCode

;*** Cursor nach rechts bewegen.
:xFORWARDSPACE		lda	#$00
			clc
			adc	r11L
			sta	r11L
			bcc	:1
			inc	r11H
::1			rts

;*** Eine Zeile tiefer.
:xSetLF			lda	r1H
			sec
			adc	curSetHight
			sta	r1H
			rts

;*** Cursor nach links/oben.
:xHOME			lda	#$00
			sta	r11L
			sta	r11H
			sta	r1H
			rts

;*** Eine Zeile höher.
:xUPLINE		lda	r1H
			sec
			sbc	curSetHight
			sta	r1H
			rts

;*** Zum Anfang der nächsten Zeile.
:xSetCR			lda	leftMargin+1
			sta	r11H
			lda	leftMargin+0
			sta	r11L
			jmp	xSetLF

;*** Neue X-Koordinate setzen.
:xGOTOX			jsr	GetXYbyte
			sta	r11L
			jsr	GetXYbyte
			sta	r11H
			rts

;*** Neue X und Y-Koordinate setzen.
:xGOTOXY		jsr	xGOTOX

;*** Neue Y-Koordinate setzen.
:xGOTOY			jsr	GetXYbyte
			sta	r1H
			rts

;*** Koordinatenbyte einlesen.
:GetXYbyte		jsr	SetNxByte_r0
			ldy	#$00
			lda	(r0L),y
			rts

;*** Drei Byte überlesen.
:xNEWCARDSET		lda	#$03
			jmp	Add_A_r0

;*** Unterstreichen aus.
:xULINEOFF		lda	#%01111111
			b $2c

;*** Inversdarstellung aus.
:xREVOFF		lda	#%11011111
			and	currentMode
			sta	currentMode
			rts

;*** Unterstreichen ein.
:xULINEON		lda	#%10000000
			b $2c

;*** Fettschrift ein.
:xBOLDON		lda	#%01000000
			b $2c

;*** Inversdarstellung ein.
:xREVON			lda	#%00100000
			b $2c

;*** Kursivschrift ein.
:xITALICON		lda	#%00010000
			b $2c

;*** "Outline"-Sschrift ein.
:xOUTLINEON		lda	#%00001000
			ora	currentMode
			b $2c

;*** Standard-Schrift ein.
:xPLAINTEXT		lda	#$00
			sta	currentMode
			rts

;*** Letztes Zeichen löschen.
:RemoveChar		ldx	currentMode
			jsr	xGetRealSize
			sty	CurCharWidth

;*** Ein Zeichen zurück.
:xBACKSPACE		lda	r11L
			sec
			sbc	CurCharWidth
			sta	r11L
			bcs	:1
			dec	r11H
::1			lda	r11H			;X-Koordinate merken.
			pha
			lda	r11L
			pha
			lda	#$5f			;Delete-Code ausgeben. Ist
			jsr	PrntCharCode		;normalerweise $7F, Wert wurde
			pla				;aber um $20 reduziert!
			sta	r11L			;X-Koordinate zurücksetzen.
			pla
			sta	r11H
			rts

;*** Grafikbefehle ausführen.
:xESC_GRAPHICS		jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			jsr	xGraphicsString
			jsr	:2
::2			ldx	#r0L
			jmp	Ddec

;*** Inline: Zeichenkette ausgeben.
:xi_PutString		pla				;Zeiger auf Inlne-Daten
			sta	r0L			;einlesen.
			pla
			sta	r0H
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.

			ldy	#$00
			lda	(r0L),y			;Xlow-Koordinate einlesen.
			sta	r11L
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			lda	(r0L),y			;Xhigh-Koordinate einlesen.
			sta	r11H
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			lda	(r0L),y			;Y-Koordinate einlesen.
			sta	r1H
			jsr	SetNxByte_r0		;Zeiger auf erstes Zeichen.
			jsr	xPutString		;Text ausgeben.
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			jmp	(r0)			;Zurück zum Programm.

;*** Zeichenkette ausgeben.
:xPutString		ldy	#$00
			lda	(r0L),y			;Zeichen einlesen.
			beq	:1			;$00 gefunden ? Ja, Ende...
			jsr	xPutChar		;Zeichen ausgeben.
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			bne	xPutString		;Endadresse $0000 erreicht ?
							; => Nächstes Zeichen ausgeben.

::1			rts

;******************************************************************************
;*** PutDecimal-Routine.
;******************************************************************************
			t "-G3_PutDecimal"
;******************************************************************************

;******************************************************************************
;*** Dezimalzahl nach ASCII-Routine.
;******************************************************************************
			t "-G3_ConvD2A"
;******************************************************************************

;*** Standardzeichensatz aktivieren.
:xUseSystemFont		lda	#>BSW_Font
			sta	r0H
			lda	#<BSW_Font
			sta	r0L

;*** Benutzerzeichensatz aktivieren.
:xLoadCharSet		ldy	#$00
::1			lda	(r0L),y
			sta	baselineOffset,y
			iny
			cpy	#$08
			bne	:1

			lda	r0L
			clc
			adc	curIndexTable+0
			sta	curIndexTable+0
			lda	r0H
			adc	curIndexTable+1
			sta	curIndexTable+1

			lda	r0L
			clc
			adc	cardDataPntr +0
			sta	cardDataPntr +0
			lda	r0H
			adc	cardDataPntr +1
			sta	cardDataPntr +1
::2			rts

;*** Breite des aktuellen Zeichens
;    (im Akku) ermitteln.
:xGetCharWidth		sec
			sbc	#$20			;Zeichencode berechnen.
			bcs	GetCodeWidth		;Steuercode ? Nein -> weiter..
			lda	#$00			;Steuercode, Breite = $00.
			rts

;*** Auf "Delete"-Code testen.
;    ASCII-Code um $20 reduziert!
:GetCodeWidth		cmp	#$5f			;Delete-Code ?
			bne	:1			;Nein, weiter...
			lda	CurCharWidth		;Breite des letzten Zeichens.
			rts

::1			asl
			tay
			iny
			iny
			lda	(curIndexTable),y
			dey
			dey
			sec
			sbc	(curIndexTable),y
			rts

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
			beq	:1			;Nein, weiter...
			iny				;Ja, Zeichenbreite +1.
::1			pla
			and	#%00001000		;Schriftstil "OUTLINE" ?
			beq	:2			;Nein, weiter...
			inx				;Ja, Zeichenbreite und
			inx				;Zeichenhöhe +2 Pixel.
			iny
			iny
			lda	#$02
::2			clc				;Differenz Oberkante Zeichen
			adc	baselineOffset		;und Baseline +(AKKU) Pixel.
			rts

;*** Linie zeichnen.
;    r11L/r11H = yLow/yHigh
;    r3  /r4   = xLow/xHigh
:xDrawLine		php				;Statusbyte merken.

			lda	r11H			;Y_Länge der Linie berechnen.
			sec
			sbc	r11L
			sta	r7L
			lda	#$00
			sta	r7H
			bcs	:1
			sec				;umrechnen.
			sbc	r7L
			sta	r7L

::1			lda	r4L			;X_Länge der Linie berechnen.
			sec
			sbc	r3L
			sta	r12L
			lda	r4H
			sbc	r3H
			sta	r12H
			ldx	#r12L			;Länge in Absolut-Wert
			jsr	Dabs			;umrechnen.

			lda	r12H			;X_Länge größer Y_Länge ?
			cmp	r7H
			bne	:2
			lda	r12L
			cmp	r7L
::2			bcs	SetVarHLine		;Ja, X_Linie zeichnen.
			jmp	SetVarVLine		; -> Y_Linie zeichnen.

;*** Linie zwischen +45 und -45 Grad
;    zeichnen. Y-Abstand zwischen zwei
;    X-Punkten max. 1 Pixel.
:SetVarHLine		lda	r7L			;Y-Delta-Wert zwischen zwei
			asl				;Punkten berechnen.
			sta	r9L
			lda	r7H
			rol
			sta	r9H

			lda	r9L
			sec
			sbc	r12L
			sta	r8L
			lda	r9H
			sbc	r12H
			sta	r8H

			lda	r7L
			sec
			sbc	r12L
			sta	r10L
			lda	r7H
			sbc	r12H
			sta	r10H

			asl	r10L
			rol	r10H

			lda	#$ff
			sta	r13L

;*** Linen-Richtung bestimmen.
			jsr	Compare_r3_r4
			bcc	:3			; -> Links nach rechts.

			lda	r11L
			cmp	r11H
			bcc	:2			; -> Oben nach unten.
			lda	#$01
			sta	r13L

::2			ldy	r3H			;X-Koordinaten vertauschen.
			ldx	r3L
			lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L
			sty	r4H
			stx	r4L
			lda	r11H			;Y-Startwert setzen.
			sta	r11L
			jmp	:4

;*** Linie zeichnen (Fortsetzung).
::3			ldy	r11H
			cpy	r11L
			bcc	:4			; -> Unten nach oben.
			lda	#$01
			sta	r13L

::4			plp
			php				;Statusbyte einlesen.
			jsr	xDrawPoint		;Punkt setzen.

			jsr	Compare_r3_r4		;Ende der Linie erreicht ?
			bcs	:8			;Ja, Ende...

			jsr	SetNextByte_r3		;Zeiger auf nächsten Punkt
							;der Linie berechnen.

			bit	r8H			;Y-Koordinate ändern ?
			bpl	:7			;Ja, weiter...

			ldy	#r9L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X
			jmp	:4

::7			clc				;Y-Koordinate ändern.
			lda	r13L
			adc	r11L
			sta	r11L

			ldy	#r10L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X
			jmp	:4

::8			plp
			rts

;*** Linie größer +45 oder -45 Grad
;    zeichnen. Y-Abstand zwischen zwei
;    X-Punkten größer als 1 Pixel.
:SetVarVLine		lda	r12L			;X-Delta-Wert zwischen zwei
			asl				;Punkten berechnen.
			sta	r9L
			lda	r12H
			rol
			sta	r9H

			lda	r9L
			sec
			sbc	r7L
			sta	r8L
			lda	r9H
			sbc	r7H
			sta	r8H

			lda	r12L
			sec
			sbc	r7L
			sta	r10L
			lda	r12H
			sbc	r7H
			sta	r10H
			asl	r10L
			rol	r10H

			lda	#$ff
			sta	r13H
			sta	r13L

;*** Linien-Richtung bestimmen.
			lda	r11L
			cmp	r11H
			bcc	:3			; -> Oben nach unten.

			jsr	Compare_r3_r4
			bcc	:2			; -> Links nach rechts.

			ldx	#$00
			stx	r13H
			inx
			stx	r13L

::2			lda	r4H			;X-Startwert setzen.
			sta	r3H
			lda	r4L
			sta	r3L
			ldx	r11L			;Y-Koordinaten vertauschen.
			lda	r11H
			sta	r11L
			stx	r11H
			jmp	:5

::3			jsr	Compare_r3_r4
			bcs	:5			; -> Rechts nach links.

			ldx	#$00
			stx	r13H
			inx
			stx	r13L

::5			plp
			php				;Statusbyte einlesen.
			jsr	xDrawPoint		;Punkt zeichnen.

			lda	r11L
			cmp	r11H			;Ende der Linie erreicht ?
			bcs	:7			;Ja, Ende...
			inc	r11L			;Zeiger auf nächstes Byte.
			bit	r8H			;X-Koordinate ändern ?
			bpl	:6			;Ja, weiter...

			ldy	#r9L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X

			jmp	:5

::6			ldy	#r13L			;X/Koordinate ändern.
			ldx	#r3L
			jsr	AddVec_Y_X

			ldy	#r10L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X
			jmp	:5

::7			plp
			rts

;*** Zeiger auf nächstes Pixel setzen.
:AddVec_Y_X		lda	zpage +0,y
			clc
			adc	zpage +0,x
			sta	zpage +0,x
			lda	zpage +1,y
			adc	zpage +1,x
			sta	zpage +1,x
			rts

;*** Einzelnen Punkt setzen.
:xDrawPoint		php				;Statusflag merken.
			jsr	xGetScanLine_r11	;Grafikzeile berechnen.

			lda	r3L			;Absoluten Bytewert ermitteln.
			and	#%11111000
			tay
			lda	r3H
			beq	:1
			inc	r5H
			inc	r6H

::1			lda	r3L
			and	#%00000111
			tax				;Zu setzendes Bit
			lda	BitData1,x		;berechnen.

			plp				;Statusflag einlesen.
			bmi	:4			;Hintergrund nach Vordergrund.
			bcc	:2			; -> Punkt löschen.
			ora	(r5L),y			; -> Punkt setzen.
			jmp	:3

::2			eor	#$ff
			and	(r5L),y

::3			jmp	ByteIn_r5_r6		;In Grafikspeicher kopieren.

::4			pha				;Pixel aus Hintergrundgrafik
			eor	#$ff			;einlesen und in Vordergrund-
			and	(r5L),y			;grafik kopieren.
			sta	(r5L),y
			pla
			and	(r6L),y
			ora	(r5L),y
			sta	(r5L),y
			rts

;*** Punkt-Zustand ermitteln.
:xTestPoint		jsr	xGetScanLine_r11	;Grafikzeile berechnen.

			lda	r3L			;Absoluten Bytewert ermitteln.
			and	#%11111000		;Achtung! Bei GEOS-V2 wird das
			tay				;Register ":r6" zum Auslesen
			lda	r3H			;verwendet, aber bei Front/
			beq	:1			;BackGrafxScrn sind die Daten
			inc	r5H			;im Normalfall im FrontScreen!
							;Deshalb ":r5" verwenden!!!!!
::1			lda	r3L
			and	#%00000111
			tax				;Zu testendes Bit
			lda	BitData1,x		;berechnen.
			and	(r5L),y
			beq	:2
			sec				; -> Punkt ist gesetzt.
			rts
::2			clc				; -> Punkt ist gelöscht.
			rts

;*** Bitmap-Ausschnitt ausgeben.
:xBitOtherClip		ldx	#$ff
			b $2c
:xBitmapClip		ldx	#$00
:BitAllClip		stx	r9H
			lda	#$00
			sta	r3L
			sta	r4L

::1			lda	r12L
			ora	r12H
			beq	:3

			lda	r11L
			jsr	:4

			lda	r2L
			jsr	:4

			lda	r11H
			jsr	:4

			lda	r12L
			bne	:2
			dec	r12H
::2			dec	r12L
			jmp	:1

::3			lda	r11L
			jsr	:4
			jsr	PrnPixelLine
			lda	r11H
			jsr	:4
			inc	r1H
			dec	r2H
			bne	:3
			rts

::4			cmp	#$00
			beq	:5
			pha
			jsr	GetGrafxByte
			pla
			sec
			sbc	#$01
			bne	:4
::5			rts

;*** Bitmap darstellen.
:xi_BitmapUp		pla				;Zeiger auf Inline-Daten
			sta	returnAddress+0		;einlesen.
			pla
			sta	returnAddress+1

			ldy	#$06
::1			lda	(returnAddress)   ,y	;Bitmap-Daten einlesen.
			sta	r0              -1,y	;r0 : Zeiger auf Grafikdaten
			dey				;r1L: X-Position in CARDs
			bne	:1			;r1H: Y-Position in Pixel
							;r2L: Breite in CARDs einlesen.
							;r2H: Breite in Pixel einlesen.
			jsr	xBitmapUp		;Grafik darstellen.
			jmp	Exit7ByteInline		;Routine beenden.

;*** Bitmap darstellen.
:xBitmapUp		lda	r9H			;Register ":r9" speichern.
			pha

			lda	#$00			;Zähler für Pixelzeilen
			sta	r9H			;löschen.
			sta	r3L			;LOW-Byte der X-Koordinaten
			sta	r4L			;löschen.
::1			jsr	PrnPixelLine
			inc	r1H
			dec	r2H
			bne	:1
			pla
			sta	r9H			;Register ":r9" zurücksetzen.
			rts

;*** Pixelzeile ausgeben.
:PrnPixelLine		ldx	r1H			;Grafikzeile berechnen.
			jsr	xGetScanLine

			lda	r2L			;Breite in CARDs merken.
			sta	r3H

			lda	r1L
			cmp	#$20			;Bitmap breiter 32 CARDs ?
			bcc	:1			;Nein, weiter...
			inc	r5H
			inc	r6H

::1			asl				;Zeiger auf CARD berechnen.
			asl
			asl
			tay

::2			sty	r9L			;Zeiger auf CARD merken.
			jsr	GetGrafxByte		;Byte einlesen und in
			ldy	r9L			;Grafikspeicher schreiben.
			jsr	ByteIn_r5_r6

			tya				;Zeiger auf nächstes CARD.
			clc
			adc	#$08
			bcc	:3
			inc	r5H
			inc	r6H
::3			tay
			dec	r3H			;Pixelzeile berechnet ?
			bne	:2			;Nein, weiter...
			rts

;*** Byte aus gepackten Daten einlesen.
:GetGrafxByte		lda	r3L
			and	#%01111111
			beq	:2
			bit	r3L
			bpl	:1
			jsr	GetPackedByte
			dec	r3L
			rts

::1			lda	r7H
			dec	r3L
			rts

::2			lda	r4L
			bne	:3
			bit	r9H
			bpl	:3
			jsr	GetNextByte

::3			jsr	GetPackedByte
			sta	r3L

			cmp	#$dc			;Doppelt gepackte Daten ?
			bcc	:4			;Nein, weiter...

			sbc	#$dc			;Anzahl doppelt gepackter
			sta	r7L			;Daten berechnen.
			sta	r4H
			jsr	GetPackedByte
			sec
			sbc	#$01
			sta	r4L
			lda	r0H
			sta	r8H
			lda	r0L
			sta	r8L
			jmp	:2

::4			cmp	#$80			;ungepackte Daten ?
			bcs	GetGrafxByte		;Ja, Byte einlesen.
			jsr	GetPackedByte
			sta	r7H
			jmp	GetGrafxByte

;*** Byte aus gepackten Daten einlesen.
:GetPackedByte		bit	r9H
			bpl	:1
			jsr	GetUsrNxByt

::1			ldy	#$00
			lda	(r0L),y
			jsr	SetNxByte_r0

			ldx	r4L
			beq	:3
			dec	r4H
			bne	:3
			ldx	r8H
			stx	r0H
			ldx	r8L
			stx	r0L
			ldx	r7L
			stx	r4H
			dec	r4L
::3			rts

:GetUsrNxByt		jmp	(r13)
:GetNextByte		jmp	(r14)

;******************************************************************************
;*** Disketten-Routinen Teil #2.
;*** Müssen im Bereich $E000-$FFFF liegen da die Routinen Diskettenfunktionen
;*** bei aktiviertem I/O benutzen (ReadBlock/ReadLink).
;******************************************************************************
			t "-G3_NewSetDev"
			t "-G3_RenFile"
			t "-G3_ReadByte"
			t "-G3_DelFile"
			t "-G3_RecordFile"
			t "-G3_BldGDirEnt"
			t "-G3_SetGDirEnt"
			t "-G3_NewFindFTyp"
			t "-G3_NewFindFile"
			t "-G3_LoadFile"
			t "-G3_SaveFile"
			t "-G3_F_F_Chain"
;******************************************************************************

;*** Ladeadresse einer Datei einlesen.
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
:NoCallRout		rts

;*** Zeiger auf ":fileTrScTab" = $8300.
:Vec_fileTrScTab	lda	#>fileTrScTab
			sta	r6H
			lda	#<fileTrScTab
			sta	r6L
			rts

;*** Mausabfrage starten.
:xStartMouseMode	bcc	:1			;Mauszeiger positionieren ?
							; -> Nein, weiter...
			lda	r11L
			ora	r11H			;X-Koordinate gesetzt ?
			beq	:1			; -> Nein, weiter...

			lda	r11H			;Neue Mausposition setzen.
			sta	mouseXPos+1
			lda	r11L
			sta	mouseXPos+0
			sty	mouseYPos
			jsr	SlowMouse

::1			lda	#>ChkMseButton		;Zeiger auf Mausabfrage
			sta	mouseVector+1		;installieren.
			lda	#<ChkMseButton
			sta	mouseVector+0
			lda	#>IsMseOnMenu
			sta	mouseFaultVec+1		;Zeiger auf Fehlerroutine bei
			lda	#<IsMseOnMenu		;verlassen des Mausbereichs.
			sta	mouseFaultVec+0
			lda	#$00			;Flag: "Mauszeiger im Bereich".
			sta	faultData
;			jmp	MouseUp			;Mauszeiger darstellen.

;*** Mauzeiger einschalten.
:xMouseUp		lda	#%10000000
			ora	mouseOn
			sta	mouseOn
			rts

;*** Mauszeiger abschalten.
:xMouseOff		lda	#%01111111
			and	mouseOn
;			sta	mouseOn			;Befehle können entfallen!
;			jmp	MouseSpriteOff		;Beide Befehle werden durch
			b $2c				;den $2C-BIT-Befehl ersetzt.

;*** Maus abschalten.
:xClearMouseMode	lda	#$00			;Mausabfrage unterbinden.
			sta	mouseOn
:MouseSpriteOff		lda	#$00			;Sprite #0 = Mauszeiger
			sta	r3L			;abschalten.
			jmp	xDisablSprite

;******************************************************************************
;*** Ist Maus in Bildschirmbereich?
;******************************************************************************
			t "-G3_IsMseInReg"
;******************************************************************************

;******************************************************************************
;*** Mauszeiger in Bereich festsetzen.
;******************************************************************************
			t "-G3_NewMseToRec"
;******************************************************************************

;*** Maustaste auswerten.
:ChkMseButton		lda	mouseData		;Maustaste gedrückt ?
			bmi	:6			;Nein, Ende...

			bit	mouseOn			;Mauszeiger/Menüs aktiv ?
			bpl	:6			;Kein Mauszeiger, Ende.
			bvc	:5			;Keine Menüs, weiter...

			jsr	DM_TestMenuPos
			bcs	:5
			jmp	DM_ExecMenuJob		;Menüeintrag ausgewählt.

::5			lda	mouseOn
			and	#%00100000		;Icons aktiv ?
			beq	:6			;Nein, weiter...
			jmp	DI_ChkMseClk		;Iconeintrag auswerten.

::6			lda	otherPressVec+0
			ldx	otherPressVec+1
			jmp	CallRoutine

;*** Mauszeiger hat Bereich verlassen.
:IsMseOnMenu		lda	#%11000000
			bit	mouseOn			;Mauszeiger und Menüs aktiv ?
			bpl	:3			;Nein, Ende...
			bvc	:3			;Nein, Ende...
			lda	menuNumber		;Hauptmenü aktiv ?
			beq	:3			;Ja, übergehen.

			lda	faultData		;Hat Mauszeiger aktuelles Menü
			and	#%00001000		;verlassen ?
			bne	:2			;Ja, ein Menü zurück.
			ldx	#%10000000
			lda	#%11000000
			tay
			bit	DM_MenuType
			bmi	:1
			ldx	#%00100000
::1			txa				;Hat Mauszeiger obere/linke
			and	faultData		;Grenze verlassen ?
			bne	:2			;Ja, ein Menü zurück.
			tya
			bit	DM_MenuType		;Mauszeiger einschränken ?
			bvs	:3			;Nein, weiter...
::2			jmp	xDoPreviousMenu		;Ein Menü zurück.
::3			rts

;******************************************************************************
;*** Menü/System-Routinen.
;******************************************************************************
			t "-G3_IntScrnSave"
			t "-G3_IntPrnSpool"
			t "-G3_NewGetStrg"
			t "-G3_NewDoMenu"
			t "-G3_NewDoIcons"
			t "-G3_NewDlgBox"
			t "-G3_ColorBox"
			t "-G3_SvLdGEOSvar"
;******************************************************************************

;******************************************************************************
;*** System-Icons #2.
;******************************************************************************
			t "-G3_SysIcon2"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $FB36 mit $00-Bytes auffüllen.
;******************************************************************************
:_09T			e $fb36
:_09
;******************************************************************************

;******************************************************************************
;*** Tastaturtreiber einbinden.
;******************************************************************************
			t "-G3_KeyDevice"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $FD68 mit $00-Bytes auffüllen.
;******************************************************************************
:_10T			e $fd68
:_10
;******************************************************************************

;*** Maus- und Tastatur abfragen.
:ExecMseKeyb		bit	pressFlag		;Eingabetreiber geändert ?
			bvc	:1			;Nein, weiter...

			lda	#%10111111
			and	pressFlag
			sta	pressFlag
			lda	inputVector   +0
			ldx	inputVector   +1
			jsr	CallRoutine

::1			lda	pressFlag
			and	#%00100000		;Wurde Mausknopf gedrückt ?
			beq	:2			;Nein, weiter...

			lda	#%11011111
			and	pressFlag
			sta	pressFlag
			lda	mouseVector  +0		;Mausklick ausführen.
			ldx	mouseVector  +1
			jsr	CallRoutine

::2			bit	pressFlag		;Wurde Taste gedrückt ?
			bpl	:3			;Nein, weiter...

			jsr	GetKeyFromBuf		;Taste aus Tastaturpuffer.
			lda	keyVector    +0		;Tastaturabfrage des Anwenders
			ldx	keyVector    +1		;aufrufen.
			jsr	CallRoutine

::3			lda	faultData		;Hat Maus Bereich verlassen ?
			beq	xESC_RULER		;Nein, weiter...

			lda	mouseFaultVec+0		;Maus hat bereich verlassen,
			ldx	mouseFaultVec+1		;zugehörige Anwender-Routine
			jsr	CallRoutine		;aufrufen.
			lda	#$00
			sta	faultData
:xESC_RULER		rts

;******************************************************************************
;*** Uhrzeit aktualisieren.
;******************************************************************************
			t "-G3_SetClock"
;******************************************************************************

;******************************************************************************
;*** TaskMan-Systemabfrage.
;******************************************************************************
			t "-G3_TaskMan"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $FE80 mit $00-Bytes auffüllen.
;******************************************************************************
:_11T			e $fe80
:_11
;******************************************************************************

			d "SuperMouse64"

;******************************************************************************
;*** Speicher bis $FFFA mit $00-Bytes auffüllen.
;******************************************************************************
:_12T			e $fffa
:_12
;******************************************************************************

			w IRQ_END
			w IRQ_END
			w GEOS_IRQ
