; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "SymbTab128"
			t "SymbTab_1"
			t "SymbTab_MMap"
			t "MacTab_K128"

;*** Landessprache festlegen.
			t "src.Kernal.Lang"

;*** Revision festlegen.
			t "src.Kernal.Rev"

;*** Version (C64 oder C128) festlegen
;C64  = TRUE_C64
;C128 = TRUE_C128
.Flag64_128		= TRUE_C128

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

			n "tmp.Kernal_Bank1"
			f 3				;Data
			c "MegaPatch128V3.0"
			a "M.Kanet/W.Grimm"
			o $9d80

;GEOS-Breich: Bank1 $9000 - $9fff
;$9000 - $9d7f = aktueller Laufwerkstreiber
;$9d80 - $9fff = GEOS-Kernal

;Sprung zu C128 Kernalroutinen ab $ff81 bis $fff0
:JmpKernal		sta	c128_BufAkku
			pla
			sta	JmpAdr+1
			pla
			sta	JmpAdr+2

			lda	JmpAdr+1
			sec
			sbc	#$02
			sta	JmpAdr+1
			bcs	:1
			dec	JmpAdr+2

;--- Ergänzung: 29.6.18/M.Kanet
;Code-Rekonstruktion: In der Version von 2003 wurde der lda/sta MMU-Befehl durch eine Routine
;ersetzt, welche neben dem MMU-Register auch RAM_Conf_Reg und CLKRATE sichert.
::1			jsr	Sv128
;			lda	MMU
;			sta	c128_BufMMU

			LoadB	MMU,$4e

;Wird durch :Sv128 gesichert.
;			lda	RAM_Conf_Reg
;			sta	c128_BufRAMConf
			lda	RAM_Conf_Reg
			and	#$f0
			ora	#$05
			sta	RAM_Conf_Reg

;Wird durch :Sv128 gesichert.
;			lda	CLKRATE
;			sta	c128_BufMHZ		;aktuellen Takt sichern
			LoadB	CLKRATE,0		;auf 1Mhz zurückschalten
			lda	c128_BufAkku
:JmpAdr			jsr	$ffff			;Sprungziel wird berechnet

			php
			pha

;Wird durch :Ld128 zurückgesetzt.
;			lda	c128_BufMHZ
;			sta	CLKRATE			;aktuellen Takt wiederherstell.
			lda	c128_BufRAMConf
			sta	RAM_Conf_Reg
			lda	c128_BufMMU
			sta	MMU
			jsr	Ld128
			pla
			plp
			rts

;Sprung in Bank 0 (Siehe Einsprungtabelle ab $e000 in Bank 1)
:JmpBank0		sta	c128_BufAkku2		;Akku sichern
			php
			pla
			sta	c128_BufStatus2		;Status sichern
			pla
			sec
			sbc	#$02			;Sprungadresse vom Stack holen
			sta	Jmp0Adr+1		;und Sprungvektor setzen
			pla
			sta	Jmp0Adr+2
			lda	RAM_Conf_Reg
			sta	c128_BufRAMConf2
			and	#$f0			;16kByte Common-Area oben
			ora	#$0b			;ergibt Bank 0 von $c000 bis
			sta	RAM_Conf_Reg		;$ffff aktiv
			lda	c128_BufStatus2		;Status und
			pha
			lda	c128_BufAkku2		;Akku wiederherstellen
			plp
:Jmp0Adr		jsr	$e072			;Sprungziel wird berechnet
			php
			pha	 			;Ausgangskonfiguration
			lda	c128_BufRAMConf2
			sta	RAM_Conf_Reg
			pla	 			;wiederherstellen
			plp
			rts

			t	"-G3_ReadFile"

			t	"-G3_VerWrFile"

			t	"-G3_NewMainIRQ"

			t	"-G3_NewMainLoop"

;******************************************************************************
;*** Speicher bis $9F54 mit $00-Bytes auffüllen.
;******************************************************************************
:_21T			e $9f54
:_21

;Seriennummer des GEOS-Systems
.SerialNumber		t	"-G3_GEOS_ID"

:Vec_fileTrScTab	LoadW	r6,fileTrScTab
			rts

.Jsr_00Akku		sta	:b+1
			lda	RAM_Conf_Reg
			sta	:a+1
			and	#%11110000
			sta	RAM_Conf_Reg		;keine Common-Area
			jsr	:b
::a			ldx	#$00
			stx	RAM_Conf_Reg
			rts
::b			jmp	($0000)

;******************************************************************************
;*** Neue MP3-Variablen.
;******************************************************************************
			t	"-G3_MP3_VAR"
.C_FarbTab		t	"-G3_MP3_COLOR"
.C_Balken		= C_FarbTab +0			;Scrolbalken.
.C_Register		= C_FarbTab +1			;Registerkarten: Aktiv.
.C_RegisterOff		= C_FarbTab +2			;Registerkarten: Inaktiv.
.C_RegisterBack		= C_FarbTab +3			;Registerkarten: Hintergrund.
.C_Mouse		= C_FarbTab +4			;Mausfarbe (nicht verwendet).
.C_DBoxTitel		= C_FarbTab +5			;Dialognox: Titel.
.C_DBoxBack		= C_FarbTab +6			;Dialogbox: Hintergrund + Text.
.C_DBoxDIcon		= C_FarbTab +7			;Dialogbox: System-Icons.
.C_FBoxTitel		= C_FarbTab +8			;Dateiauswahlbox: Titel.
.C_FBoxBack		= C_FarbTab +9			;Dateiauswahlbox: Hintergrund + Text.
.C_FBoxDIcon		= C_FarbTab +10			;Dateiauswahlbox: System-Icons.
.C_FBoxFiles		= C_FarbTab +11			;Dateiauswahlbox: Dateifenster.
.C_WinTitel		= C_FarbTab +12			;Fenster: Titel.
.C_WinBack		= C_FarbTab +13			;Fenster: Hintergrund.
.C_WinShadow		= C_FarbTab +14			;Fenster: Schatten.
.C_WinIcon		= C_FarbTab +15			;Fenster: System-Icons.
.C_PullDMenu		= C_FarbTab +16			;PullDown-Menu.
.C_InputField		= C_FarbTab +17			;Registerkarten: Text-Eingabefeld.
.C_InputFieldOff	= C_FarbTab +18			;Registerkarten: Inaktives Optionsfeld.
.C_GEOS_BACK		= C_FarbTab +19			;GEOS-Standard: Hintergrund.
.C_GEOS_FRAME		= C_FarbTab +20			;GEOS-Standard: Rahmen.
.C_GEOS_MOUSE		= C_FarbTab +21			;GEOS-Standard: Mauszeiger.

;******************************************************************************

;******************************************************************************
;*** Speicher bis $A000 mit $00-Bytes auffüllen.
;******************************************************************************
:_02T			e $a000
:_02
;******************************************************************************

;******************************************************************************
;*** Speicher bis $C000 mit $00-Bytes auffüllen.
;******************************************************************************
:_03T			e $c000
:_03
;******************************************************************************

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
.c128Flag		b $80

.MP3_CODE		b "MP"

.EndGetStrgAdr		w $0000				;Rücksprungadresse GetString.

.dateCopy		b $58,$07,$06			;Nur Kopie des Datums.
;			b $07,$06			;Frühere MegaPatch-Versionen.
			b $00,$00			;Reserviert.

;*** GEOS neu starten.
:ReBootGEOS		;bit	sysFlgCopy		;ReBoot aus RAM-Erweiterung ?
;			bvs	ReBootRAM		;Ja, RAM-ReBoot...

;			lda	#$00
;			sta	$fff5			;CBM-Kennung für Reset löschen
;			ldx	#7			;Reset-Routine in Zeropage
;::1			lda	ResetRoutine,x		;kopieren
;			sta	$02,x
;			dex
;			bpl	:1
;			jmp	$0002			;und starten

;*** ReBoot-Routine aus RAM-Erweiterung einlesen.
;:ReBootRAM
			ldx	#$06
::1			lda	RamBootData,x
			sta	r0L        ,x
			dex
			bpl	:1

			ldy	#%10010001		;Code für RAM-Bereich laden.
			jsr	xDoRAMOp_NoChk		;Directeinsprung "FetchRAM".
			jmp	BASE_REBOOT

;:ResetRoutine		LoadB	MMU,$00			;Resetroutine für Sprung ins
;			jmp	$ff3d			;Basic

;*** Transferdaten.
:RamBootData		w	BASE_REBOOT
			w	R1_ADDR_REBOOT
			w	R1_SIZE_REBOOT
			b	$00

;******************************************************************************
;*** DoRamOp-Funktionen.
;*** Funktionen befinden sich in separatem Quelltext und werden beim
;*** Booten durch das StartProgramm an die REU angepaßt.
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
;*** DvRAM_RL   $9EDE-$9F53= 118 Bytes
;*** DvRAM_SCPU $9EDE-$9F32= 85 Bytes
;*** DvRAM_CREU $9EDE-$9F4b= 110 Bytes
;*** DvRAM_GRAM $9EDE-$9F32= 85 Bytes
;******************************************************************************

;******************************************************************************
;*** Speicher mit $00-Bytes auffüllen.
;******************************************************************************
.SIZE_RAM_DRV		= 118

:_23T			e BASE_RAM_DRV + SIZE_RAM_DRV
:_23
;******************************************************************************
.BASE_RAM_DRV_END
;******************************************************************************

			t	"-G3_NewToBasic"

;******************************************************************************
;*** MP3-Sprungtabelle (Beginn ab $c0dc)
;******************************************************************************
			t "-G3_JumpTabMP"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $C100 mit $00-Bytes auffüllen.
;******************************************************************************
:_04T			e $c100
:_04
;******************************************************************************

;GEOS-Sprungtabelle (Beginn ab $c100)
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
.Rectangle		jmp	xxRectangle
.FrameRectangle		jmp	xFrameRectangle
.InvertRectangle	jmp	xInvertRectangle
.RecoverRectangle	jmp	xRecoverRectangle
.DrawLine		jmp	xDrawLine
.DrawPoint		jmp	xDrawPoint
.GraphicsString		jmp	xGraphicsString
.SetPattern		jmp	xSetPattern
.GetScanLine		jmp	xxGetScanLine
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
.DShiftLeft		jmp	dDShiftLeft
.BBMult			jmp	dBBMult
.BMult			jmp	dBMult
.DMult			jmp	dDMult
.Ddiv			jmp	dDdiv
.DSdiv			jmp	dDSdiv
.Dabs			jmp	dDabs
.Dnegate		jmp	dDnegate
.Ddec			jmp	dDdec
.ClearRam		jmp	xClearRam
.FillRam		jmp	xFillRam
.MoveData		jmp	xMoveData
.InitRam		jmp	dInitRam
.PutDecimal		jmp	xPutDecimal
.GetRandom		jmp	dGetRandom
.MouseUp		jmp	xMouseUp
.MouseOff		jmp	xMouseOff
.DoPreviousMenu		jmp	xDoPreviousMenu
.ReDoMenu		jmp	xReDoMenu
.GetSerialNumber	jmp	dGetSerialNumber
.Sleep			jmp	xSleep
.ClearMouseMode		jmp	xClearMouseMode
.i_Rectangle		jmp	xi_Rectangle
.i_FrameRectangle	jmp	xi_FrameRectangle
.i_RecoverRectangle	jmp	xi_RecoverRectangle
.i_GraphicsString	jmp	xi_GraphicsString
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

.CalcBlksFree		jmp	($9020)
.ChkDkGEOS		jmp	($902c)
.NewDisk		jmp	($900c)
.GetBlock		jmp	($9016)
.PutBlock		jmp	($9018)
.SetGEOSDisk		jmp	($902e)
.SaveFile		jmp	xSaveFile
.SetGDirEntry		jmp	xSetGDirEntry
.BldGDirEntry		jmp	xxBldGDirEntry
.GetFreeDirBlk		jmp	($901e)
.WriteFile		jmp	xWriteFile
.BlkAlloc		jmp	($902a)
.ReadFile		jmp	xReadFile
.SmallPutChar		jmp	xSmallPutChar
.FollowChain		jmp	xFollowChain
.GetFile		jmp	xGetFile
.FindFile		jmp	xFindFile
.CRC			jmp	dCRC
.LdFile			jmp	xLdFile
.EnterTurbo		jmp	($9008)
.LdDeskAcc		jmp	xLdDeskAcc
.ReadBlock		jmp	($900e)
.LdApplic		jmp	xLdApplic
.WriteBlock		jmp	($9010)
.VerWriteBlock		jmp	($9012)
.FreeFile		jmp	xFreeFile
.GetFHdrInfo		jmp	xGetFHdrInfo
.EnterDeskTop		jmp	xEnterDeskTop
.StartAppl		jmp	xStartAppl
.ExitTurbo		jmp	($9004)
.PurgeTurbo		jmp	($9006)
.DeleteFile		jmp	xDeleteFile
.FindFTypes		jmp	xFindFTypes
.RstrAppl		jmp	xRstrAppl
.ToBasic		jmp	xToBasic
.FastDelFile		jmp	xFastDelFile
.GetDirHead		jmp	($901a)
.PutDirHead		jmp	($901c)
.NxtBlkAlloc		jmp	($9028)
.ImprintRectangle	jmp	xImprintRectangle
.i_ImprintRectangle	jmp	xi_ImprintRectangle
.DoDlgBox		jmp	xDoDlgBox
.RenameFile		jmp	xRenameFile

;******************************************************************************
;*** Neue I/O-Routinen.
;*** Die Routinen werden bei Einsatz einer SuperCPU auf das SuperCPU-Patch umgestellt.
;******************************************************************************
.InitForIO		jmp	($9000)
.DoneWithIO		jmp	($9002)
;******************************************************************************

.DShiftRight		jmp	dDShiftRight
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
.SetNextFree		jmp	($9024)
.UpdateRecordFile	jmp	xUpdateRecFile
.GetPtrCurDkNm		jmp	dGetPtrCurDkNm
.PromptOn		jmp	xPromptOn
.PromptOff		jmp	xPromptOff
.OpenDisk		jmp	($9014)
.DoInlineReturn		jmp	xDoInlineReturn
.GetNextChar		jmp	xGetNextChar
.BitmapClip		jmp	xBitmapClip
.FindBAMBit		jmp	($9026)
.SetDevice		jmp	xSetDevice
.IsMseInRegion		jmp	dIsMseInRegion
.ReadByte		jmp	xReadByte
.FreeBlock		jmp	($9022)
.ChangeDiskDevice	jmp	($900a)
.RstrFrmDialogue	jmp	xRstrFrmDialogue
.Panic			jmp	xPanic
.BitOtherClip		jmp	xBitOtherClip
.StashRAM		jmp	xStashRAM
.FetchRAM		jmp	xFetchRAM
.SwapRAM		jmp	xSwapRAM
.VerifyRAM		jmp	xVerifyRAM
.DoRAMOp		jmp	xDoRAMOp

;ab hier spezielle 128er Einsprünge
;***********************************
.TempHideMouse		jmp	xTempHideMouse		;Sprites vom Screen entfernen
.SetMsePic		jmp	xSetMsePic		;Mauspfeil definieren
.SetNewMode		jmp	xSetNewMode		;40/80Zeichen Modus setzen
.NormalizeX		jmp	xNormalizeX		;40/80Zeichen-Anpassung X-Koor.
.MoveBData		jmp	xMoveBData		;Speicherverschiebung
.SwapBData		jmp	xSwapBData		;Speichertausch
.VerifyBData		jmp	xVerifyBData		;Speichervergleich
.DoBOp			jmp	xDoBOp			;Verschieberoutine
.DoBAMBuf		jmp	xDoBAMBuf		;BAM-Buffer Routine
.HideOnlyMouse		jmp	xHideOnlyMouse		;Mauspfeil vom Screen entfernen
.VDC_ModeInit		jmp	xVDC_ModeInit		;Initialis. des VDC Farbmodus
.ColorPoint		jmp	xColorPoint		;Farbe für Punkt setzen
.ColorRectangle		jmp	xDirectColor		;Farbe für Rechteck setzen

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

			t	"-G3_WriteFile"

:Vec_fileHeader		LoadW	r4,fileHeader
			rts

:xCallRoutine		cmp	#$00
			bne	:1
			cpx	#$00
			beq	:2
::1			sta	$42
			stx	$43
			jmp	($0042)
::2			rts

.Exit7ByteInline	php
			lda	#$07
;			jmp	DoInlineReturn
:xDoInlineReturn	clc
			adc	returnAddress +0
			sta	returnAddress +0
			bcc	:1
			inc	returnAddress +1
::1			plp
			jmp	($003d)

:xNormalizeX		lda	zpage +1,x		; Verdopplungsbit gelöscht?
			bpl	:1			; => Ja, weiter...

			rol				; Bit%14 gesetzt?
			bmi	:2			; Ja, negative Zahl, nicht verdoppeln.

;--- Bit%15 gesetzt und Bit%14 gelöscht:
; Positive Zahl mit Verdopplung.
			ror

			bit	graphMode		; 40/80-Zeichen?
			bpl	:3			; => 40 Zeichen, nur Bit%13-15 für positive Zahl löschen.

			clc				; Wenn hier ein Überlauf auftritt, dann war Bit%13 gesetzt.
			adc	#$60			; In dem Fall ist das Carry-Flag gesetzt = +1 / ADD1_W.
			rol	zpage +0,x
			rol				; Verdopplung mit Bit%7 aus Low-Byte ausführen.

::3			and	#$1f			; Bit%13-%15 für positive Zahl löschen.
			sta	zpage +1,x
			rts

;--- Bit%15 ist gelöscht:
; Entweder keine Verdopplung oder Negative Zahl mit Verdopplung.
::1			rol
			bpl	:2

;--- Bit%15 gelöscht und Bit%14 gesetzt:
; Negative Zahl mit Verdopplung.
			ror

			bit	graphMode		; 40/80-Zeichen?
			bpl	:4			; => 40 Zeichen, nur Bit%13-15 für negative Zahl setzen.

			sec				; Testen ob Bit%13 gesetzt oder gelöscht ist.
			adc	#$a0			; Wenn Bit%13 gesetzt, dann tritt hier ein Überlauf auf.
			rol	zpage +0,x		; Veropplung, Carry-Flag als Bit%0 übernehmen.
;--- Ergänzung: 21.12.22/M.Kanet.
;Gemäß "Hitchhikers Guide to GEOS" können auch negative
;Zahlen verdoppelt werden:
;
;			b15	b14 b13			Effect
;			 0	 0  n			x value unchanged (normal positive)
;			 1	 1  n			x value unchanged (normal negative)
;			 0	 1  n			x = x*2 -n (doubled negative)
;			 1	 0  n			x = x*2 +n (doubled positive)
;
;Aus -319 = $FEC1 wird dann -639 = $FD81 wenn Bit%15 und
;Bit%13 in der negativen Zahl gelöscht werden.
;Das entspricht einer Exklusiv-Oder-Verknüpfung mit den
;Konstanten DOUBLE_W und ADD1_W.
;
;Ohne die beiden folgenden Befehle wird allerdings
;keine gültige negative Zahl erzeugt.
			dec	zpage +0,x		; Low-Byte korrigieren.
			lda	zpage +1,x		; High-Byte wieder einlesen.
;---
			rol				; Verdopplung mit Bit%7 aus Low-Byte ausführen.
::4			ora	#$e0			; Bit%13-%15 für negative Zahl setzen.
			sta	zpage +1,x
::2			rts

.ExecMseKeyb		bit	c128_alphaFlag
			bpl	:1
			jsr	TempHideMouse
			LoadB	r3L,$01
			lda	stringX +0
			sta	r4L
			lda	stringX +1
			sta	r4H
			lda	stringY
			sta	r5L
			jsr	PosSprite
			jsr	EnablSprite
			clv
::1			bvc	:2
			jsr	TempHideMouse
			LoadB	r3L,$01
			jsr	DisablSprite
::2			LoadB	c128_alphaFlag,0
			bit	graphMode
			bpl	:3
			jsr	DoSoftSprites
::3			bit	pressFlag
			bvc	:4
			lda	#$bf
			and	pressFlag
			sta	pressFlag
			lda	inputVector +0
			ldx	inputVector +1
			jsr	CallRoutine
::4			lda	pressFlag
			and	#$20
			beq	:5
			lda	#$df
			and	pressFlag
			sta	pressFlag
			lda	mouseVector +0
			ldx	mouseVector +1
			jsr	CallRoutine
::5			bit	pressFlag
			bpl	:6
			jsr	GetKeyFromBuf
			lda	keyVector +0
			ldx	keyVector +1
			jsr	CallRoutine
::6			lda	faultData
			beq	xESC_RULER
			lda	mouseFaultVec +0
			ldx	mouseFaultVec +1
			jsr	CallRoutine
			LoadB	faultData,$00
:xESC_RULER		rts

;GEOS IRQ-Routine
.xGEOS_IRQ		txa
			pha
			tya
			pha
			tsx
			lda	$0108,x
			and	#$10
			beq	:1
			jmp	(BRKVector)
::1			PushB	c128_BufRAMConf2
			PushB	c128_BufAkku2
			PushB	c128_BufStatus2
			PushW	Jmp0Adr+1
			PushB	JmpIOAdr+1
			PushB	lastMMUReg+1
			PushB	$43
			PushB	$42
			PushW	returnAddress
			ldx	#0			;r0 bis r15 sichern
::2			lda	r0L,x
			pha
			inx
			cpx	#32
			bne	:2
			lda	dblClickCount		;Auf Doppelklick testen?
			beq	:3			;>nein weiter
			dec	dblClickCount		;Zähler erniedrigen
::3			jsr	InitMouseData		;Maus aktualisieren
			ldy	keyMode			;Erste Taste einlesen?
			beq	:4			;>ja weiter
			iny				;Taste in 'currentKey'?
			beq	:4			;>Nein weiter
			dec	keyMode
::4			jsr	GetMatrixCode		;Tastaturabfrage
			jsr	SetMouse		;Maus nach Tastaturabfrage
							;initialisieren
			lda	AlarmAktiv		;Zähler für Alarmwiederholung
			beq	:5			;gesetzt?  >Nein weiter
			dec	AlarmAktiv		;Zähler erniedrigen
::5			lda	intTopVector +0  ;IRQ/GEOS
			ldx	intTopVector +1
			jsr	CallRoutine
			lda	intBotVector +0  ;IRQ/Anwender
			ldx	intBotVector +1
			jsr	CallRoutine

			LoadB	grirq,1			;Raster-IRQ-Flag setzen
			ldx	#31			;r0 bis r15 wiederherstellen
::6			pla
			sta	r0L,x
			dex
			bpl	:6
			PopW	returnAddress
			PopB	$42
			PopB	$43
			PopB	lastMMUReg+1
			PopB	JmpIOAdr+1
			PopW	Jmp0Adr+1
			PopB	c128_BufStatus2
			PopB	c128_BufAkku2
			PopB	c128_BufRAMConf2
			pla
			tay
			pla
			tax
			rts

:xi_BitmapUp		pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			ldy	#$01
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
			iny
			lda	(returnAddress),y
			sta	r2H
			jsr	xBitmapUp
			jmp	Exit7ByteInline

:xi_RecoverRectangle
			jsr	GetInlineData
			jsr	xRecoverRectangle
			jmp	Exit7ByteInline

:xi_ImprintRectangle
			jsr	GetInlineData
			jsr	xImprintRectangle
			jmp	Exit7ByteInline

:xi_FrameRectangle	jsr	GetInlineData
			iny
			lda	(returnAddress),y
			jsr	xFrameRectangle
			php
			lda	#$08
			jmp	DoInlineReturn

:xSetNewMode		jsr	NewModeInit
			jsr	SCPU_SetOpt		;Optimierung der SCPU anpassen

:SetNewModeInit		lda	graphMode		;neuer Graphikmodus
			cmp	Old_grMd		;mit altem vergleichen
			beq	:1			;>Tabelle bereits initialisiert
			sta	Old_grMd		;>aktuellen graphMode speichern
			jsr	xSet_C_FarbTab		;MP3-Farbtab. wechs. (VIC/VDC)

::1			lda	$d011
			bit	graphMode
			bpl	:40Z
			and	#$6f
			sta	$d011
			lda	vdcClrMode
			jmp	VDC_ModeInit
::40Z			ora	#$10
			and	#$7f
			sta	$d011
			ldx	#26			;Register 26
			lda	#$00			;schwarz/schwarz
			jsr	SetVDC
			dex				;Register 25
			lda	#$80			;Einzelpunktgrafik an
			jmp	SetVDC

:NewModeInit		lda	#0			;1 MHz
			ldx	#>319
			ldy	#<319
			bit	graphMode
			bpl	:40Z
			LoadB	SoftSpriteFlag,$ff
			lda	#1			;2 MHz
			ldx	#>639
			ldy	#<639
::40Z			sta	CLKRATE
			stx	rightMargin +1
			sty	rightMargin +0
			stx	mouseRight +1
			sty	mouseRight +0
			jmp	UseSystemFont

:xGraphicsString	jsr	Get1Byte
			beq	:1
			tay
			dey
			lda	GS_RoutTabL,y
			ldx	GS_RoutTabH,y
			jsr	CallRoutine
			clv
			bvc	xGraphicsString
::1			rts

:GS_MOVEPENTO		jsr	Get3Byte
			sta	GS_Ypos
			stx	GS_XposL
			sty	GS_XposH
:GS_PENFILL		rts

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

:GS_RECTANGLETO		jsr	GS_GetXYpar
			jmp	xxRectangle

:GS_NEWPATTERN		jsr	Get1Byte
			jmp	xSetPattern

:GS_PUTSTRING		jsr	Get1Byte
			sta	r11L
			jsr	Get1Byte
			sta	r11H
			jsr	Get1Byte
			sta	r1H
			jmp	xPutString

:GS_FRAMERECTO		jsr	GS_GetXYpar
			lda	#$ff
			jmp	xFrameRectangle

:GS_PENXYDELTA		ldx	#$01
			bne	GS_SetXDelta
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
			beq	lc8bf
			bne	GS_SetYDelta

:GS_PENYDELTA		ldy	#$00
:GS_SetYDelta		lda	(r0L),y
			iny
			clc
			adc	GS_Ypos
			sta	GS_Ypos
			iny
:lc8bf			tya
			clc
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H
::1			rts

:GS_RoutTabL		b	<GS_MOVEPENTO
			b	<GS_LINETO
			b	<GS_RECTANGLETO
			b	<GS_PENFILL
			b	<GS_NEWPATTERN
			b	<GS_PUTSTRING
			b	<GS_FRAMERECTO
			b	<GS_PENXDELTA
			b	<GS_PENYDELTA
			b	<GS_PENXYDELTA

:GS_RoutTabH		b	>GS_MOVEPENTO
			b	>GS_LINETO
			b	>GS_RECTANGLETO
			b	>GS_PENFILL
			b	>GS_NEWPATTERN
			b	>GS_PUTSTRING
			b	>GS_FRAMERECTO
			b	>GS_PENXDELTA
			b	>GS_PENYDELTA
			b	>GS_PENXYDELTA

;******************************************************************************
;*** Neue MoveData-Routine.
;*** Bei einer SuperCPU wird beim booten hier das SuperCPU-Patch installiert.
;******************************************************************************
.BASE_SCPU_DRV

if TRUE
;--- GEOS-V2-Routinen einbinden.
			t "-G3_FillRam"
			t "+G3_NewMoveData"
endif
if FALSE
;--- SuperCPU-Routinen einbinden.
			t "+G3_Patch_SCPU"
:xFillRam		= s_FillRam
:xMoveData		= s_MoveData
:xi_MoveData		= s_i_MoveData
:xInitForIO		= s_InitForIO
:xDoneWithIO		= s_DoneWithIO
:xSCPU_OptOn		= s_SCPU_OptOn
:xSCPU_OptOff		= s_SCPU_OptOff
:xSCPU_SetOpt		= s_SCPU_SetOpt
endif

;******************************************************************************
;*** Speicher bis $xxxx mit $00-Bytes auffüllen.
;*** Hier muß der größte Wert von 'BASE_SCPU_DRV_END' eingetragen werden,
;*** welcher beim Assemblieren mit SCPU = FALSE/TRUE entsteht, damit der
;*** SCPU-Patch auch im Kernal Platz hat!
;*** SCPU = FALSE: $c631-$c6bc= 140 Bytes
;*** SCPU = TRUE : $c631-$c6f9= 201 Bytes
:Patch_SIZE_SCPU = $c5
;******************************************************************************
.SIZE_SCPU_DRV		= 201

:_19T			e BASE_SCPU_DRV + SIZE_SCPU_DRV	;$c6fa
:_19
;******************************************************************************
.BASE_SCPU_DRV_END

;******************************************************************************
;*** Speicher bis $C702 mit $00-Bytes auffüllen.
;******************************************************************************
:_20T			e $c702
:_20
;******************************************************************************
			t	"-G3_KeyDevice"

if Sprache = Deutsch
;******************************************************************************
;*** Speicher bis $C985 mit $00-Bytes auffüllen.
;******************************************************************************
:_05T			e $c985
:_05
endif
if Sprache = Englisch
;******************************************************************************
;*** Speicher bis $C991 mit $00-Bytes auffüllen.
;******************************************************************************
:_05T			e $c991
:_05
endif
;******************************************************************************
:OrgMouseData		b $fc,$00,$00,$f8,$00,$00,$f0,$00
			b $00,$f8,$00,$00,$dc,$00,$00,$8e
			b $00,$00,$07,$00,$00,$03,$00,$00

:InitVICdata		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$3b,$fb,$aa,$aa,$01,$08,$00
			b $38,$0f,$01,$00,$00,$00

if Sprache = Deutsch
;******************************************************************************
;*** Speicher bis $C9BB mit $00-Bytes auffüllen.
;******************************************************************************
:_06T			e $c9bb
:_06
;******************************************************************************
.DeskTopName		b "128 DESKTOP"
.DeskTopNameEnd		b NULL
.DlgBoxDTopMsg1		b $18 ;BOLDON
			b "Bitte eine Diskette mit"
.DlgBoxDTopMsg1End	b NULL
.DlgBoxDTopMsg2		b "128 DESKTOP einlegen"
.DlgBoxDTopMsg2End	b NULL

endif

;Eine Routine die hier liegt darf maximal 12 Bytes lang sein
;als ausgleich zwischen englischem und deutschem Quellcode!

if Sprache = Englisch
;******************************************************************************
;*** Speicher bis $C9C7 mit $00-Bytes auffüllen.
;******************************************************************************
:_06T			e $c9c7
:_06

.DlgBoxDTopMsg1		b $18 ;BOLDON
			b "Please insert a disk with the"
.DlgBoxDTopMsg1End	b NULL
.DlgBoxDTopMsg2		b "128 DESKTOP V2.0 or higher"
.DlgBoxDTopMsg2End	b NULL
.DeskTopName		b "128 DESKTOP"
.DeskTopNameEnd		b NULL

endif

;******************************************************************************
;*** Speicher bis $CA0D mit $00-Bytes auffüllen.
;******************************************************************************
:_07T			e $ca0d
:_07
;******************************************************************************

;Sprung in RAM-Bereich $d000 Bank 1 zur dortigen Sprungtabelle
:dIsMseInRegion		lda	#<xxIsMseInRegion
			b	$2c
:c128_MoveData		lda	#<xxc128_MoveData
			b	$2c
:dCRC			lda	#<xxCRC
			b	$2c
:dGetRandom		lda	#<xxGetRandom
			b	$2c
:dBBMult		lda	#<xxBBMult
			b	$2c
:dBMult			lda	#<xxBMult
			b	$2c
:dDMult			lda	#<xxDMult
			b	$2c
:dDdiv			lda	#<xxDdiv
			b	$2c
:dDabs			lda	#<xxDabs
			b	$2c
:DecSleepTime		lda	#<xxDecSleepTime
			b	$2c
:GetInlineData		lda	#<xxGetInlineData
			b	$2c
:GS_GetXYpar		lda	#<xxGS_GetXYpar
			b	$2c
:PrepProcData		lda	#<xxPrepProcData
			b	$2c
:dGetSerialNumber	lda	#<xxGetSerialNumber
			b	$2c
:TestgraphMode		lda	#<xxTestgraphMode
			b	$2c
:dGetPtrCurDkNm		lda	#<xxGetPtrCurDkNm
			b	$2c
:dNewC128K_RESTORE	lda	#<xxNewC128K_RESTORE
			b	$2c
:dInitRam		lda	#<xxInitRam
			b	$2c
:dDSdiv			lda	#<xxDSdiv
			b	$2c
:dDnegate		lda	#<xxDnegate
			b	$2c
:dDdec			lda	#<xxDdec
			b	$2c
:dDShiftLeft		lda	#<xxDShiftLeft
			b	$2c
:dDShiftRight		lda	#<xxDShiftRight
			b	$2c
:dIntPrnSpool		lda	#<xxIntPrnSpool
			b	$2c
:dIntScrnSave		lda	#<xxIntScrnSave

			sta	JmpIOAdr+1
			lda	MMU
			sta	lastMMUReg+1
			ora	#$01
			sta	MMU
:JmpIOAdr		jsr	$d000			;Zur Sprungtabelle ab $d000
			php
			pha
:lastMMUReg		lda	#$7f
			sta	MMU
			pla
			plp
			rts

;******************************************************************************
;*** Speicher bis $CA76 mit $00-Bytes auffüllen.
;******************************************************************************
:_08T			e $ca76
:_08
;******************************************************************************
if Sprache = Deutsch
.SetVDC			stx	VDCBaseD600
::1			bit	VDCBaseD600
			bpl	:1
			sta	VDCDataD601
			rts
.GetVDC			stx	VDCBaseD600
::1			bit	VDCBaseD600
			bpl	:1
			lda	VDCDataD601
			rts
endif

;Eine Routine die hier liegt darf maximal 19 Bytes lang sein
;als ausgleich zwischen englischem und deutschem Quellcode!

:xi_Rectangle		jsr	GetInlineData
			jsr	xxRectangle
			jmp	Exit7ByteInline

.Old_grMd		b	$00			;Alter Graphikmodus
							;$80 = VDC    $00 = VIC

if Sprache = Englisch
;******************************************************************************
;***  ab $CA89 !!! Feste Adresse!
;******************************************************************************
			e	$ca89

.SetVDC			stx	VDCBaseD600
::1			bit	VDCBaseD600
			bpl	:1
			sta	VDCDataD601
			rts
.GetVDC			stx	VDCBaseD600
::1			bit	VDCBaseD600
			bpl	:1
			lda	VDCDataD601
			rts
endif

;******************************************************************************
;*** Speicher bis $CAA1 mit $00-Bytes auffüllen.
;******************************************************************************
:_09T			e $caa1
:_09
;******************************************************************************

			t	"-G3_CopyString"

			t	"-G3_CmpString"

			t	"-G3_Sprites"

:xSetPattern		asl				;mal 8
			asl
			asl
			adc	#<GEOS_Patterns    ;plus Offset der Pattern's
			sta	curPattern
			lda	#0
			adc	#>GEOS_Patterns
			sta	curPattern+1
			rts

:GetLoadAdr		lda	fileHeader+$47
			sta	r7L
			lda	fileHeader+$48
			sta	r7H
			rts

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

:BitData2		b $01,$02,$04,$08,$10,$20,$40,$80

:xi_FillRam		pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			jsr	Get2Word1Byte
			jsr	FillRam
			php
			lda	#$06
			jmp	DoInlineReturn

			t	"-G3_SetClock"

			t	"-G3_Process"

			t	"-G3_iPutString"

			t	"-G3_SCPU_Pause"

			t	"-G3_NewSetDev"

;*** Zeiger auf Sektorspeicher setzen.
:Vec_diskBlkBuf		lda	#>diskBlkBuf		;Zeiger auf Zwischenspeicher.
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L
			rts

;******************************************************************************
;*** Speicher bis $xxF0 mit $00-Bytes auffüllen.
;******************************************************************************
:_22T			e $cdf0
:_22
;******************************************************************************

;******************************************************************************
;*** GEOS-Füllpatterns.
;*** Muss bei $xxF0 beginnen, damit DualTop128 über
;*** ":curPattern" das Pattern#0 erkennt.
;*** Ansonsten wird der Dateiname mit REVON angezeigt.
;******************************************************************************
			t	"-G3_Patterns"

;******************************************************************************
;*** Zeiger auf Laufwerkstreiber setzen.
;******************************************************************************
			t "-G3_SetVecDkRAM"
;******************************************************************************

;******************************************************************************
;*** Zeiger auf RAM-Routinen einlesen.
;******************************************************************************
			t "-G3_SetVecRAM"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $D000 mit $00-Bytes auffüllen.
;******************************************************************************
:_10T			e $d000
:_10
;******************************************************************************

;Bereich Bank 1 $d000 bis $dfff

:xxIsMseInRegion	jmp	xIsMseInRegion
:xxc128_MoveData	jmp	xc128_MoveData
:xxCRC			jmp	xCRC
:xxGetRandom		jmp	xGetRandom
:xxBBMult		jmp	xBBMult
:xxBMult		jmp	xBMult
:xxDMult		jmp	xDMult
:xxDdiv			jmp	xDdiv
:xxDSdiv		jmp	xDSdiv
:xxDecSleepTime		jmp	xDecSleepTime
:xxGetInlineData	jmp	xGetInlineData
:xxGS_GetXYpar		jmp	xGS_GetXYpar
:xxPrepProcData		jmp	xPrepProcData

:xxGetSerialNumber	jmp	xGetSerialNumber
:xxTestgraphMode	jmp	xTestgraphMode
:xxGetPtrCurDkNm	jmp	xGetPtrCurDkNm
:xxNewC128K_RESTORE 	jmp	xNewC128K_RESTORE
:xxInitRam		jmp	xInitRam

:xxDabs			jmp	xDabs
:xxDnegate		jmp	xDnegate
:xxDdec			jmp	xDdec
:xxDShiftLeft		jmp	xDShiftLeft
:xxDShiftRight		jmp	xDShiftRight

:xxIntPrnSpool		jmp	IntPrnSpool
:xxIntScrnSave		jmp	IntScrnSave

:xc128_MoveData		lda	r0H
			cmp	r1H
			bne	:1
			lda	r0L
			cmp	r1L
::1			bcs	:2
			bcc	:6
::2			ldy	#$00
			lda	r2H
			beq	:4
::3			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:3
			inc	r0H
			inc	r1H
			dec	r2H
			bne	:3
::4			cpy	r2L
			beq	:5
			lda	(r0L),y
			sta	(r1L),y
			iny
			jmp	:4
::5			rts
::6			clc
			lda	r2H
			adc	r0H
			sta	r0H
			clc
			lda	r2H
			adc	r1H
			sta	r1H
			ldy	r2L
			beq	:8
::7			dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	:7
::8			dec	r0H
			dec	r1H
			lda	r2H
			beq	:5
::9			dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	:9
			dec	r2H
			jmp	:8

:xDecSleepTime		ldx	MaxSleep
			beq	:4
			dex
::1			lda	SleepTimeL,x
			bne	:2
			ora	SleepTimeH,x
			beq	:3
			dec	SleepTimeH,x
::2			dec	SleepTimeL,x
::3			dex
			bpl	:1
::4			rts

:xGetInlineData		pla
			sta	r6L
			pla
			sta	r6H
			pla
			sta	r5L
			pla
			sta	r5H
			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			ldy	#$01
			lda	(returnAddress),y
			sta	r2L
			iny
			lda	(returnAddress),y
			sta	r2H
			iny
			lda	(returnAddress),y
			sta	r3L
			iny
			lda	(returnAddress),y
			sta	r3H
			iny
			lda	(returnAddress),y
			sta	r4L
			iny
			lda	(returnAddress),y
			sta	r4H
			lda	r5H
			pha
			lda	r5L
			pha
			lda	r6H
			pha
			lda	r6L
			pha
			rts

:xGS_GetXYpar		jsr	Get3Byte
			cmp	GS_Ypos
			bcs	:1
			sta	r2L
			pha
			lda	GS_Ypos
			sta	r2H
			clv
			bvc	:2
::1			sta	r2H
			pha
			lda	GS_Ypos
			sta	r2L
::2			pla
			sta	GS_Ypos
			cpy	GS_XposH
			beq	:3
			bcs	:5
::3			bcc	:4
			cpx	GS_XposL
			bcs	:5
::4			stx	r3L
			sty	r3H
			lda	GS_XposH
			sta	r4H
			lda	GS_XposL
			sta	r4L
			clv
			bvc	:6
::5			stx	r4L
			sty	r4H
			lda	GS_XposH
			sta	r3H
			lda	GS_XposL
			sta	r3L
::6			stx	GS_XposL
			sty	GS_XposH
			rts

:xPrepProcData		lda	#$00
			tay
			tax
			cmp	MaxProcess
			beq	:4
::1			lda	ProcStatus,x
			and	#$30
			bne	:3
			lda	ProcCurDelay,y
			bne	:2
			pha
			lda	ProcCurDelay+1,y
			sec
			sbc	#$01
			sta	ProcCurDelay+1,y
			pla
::2			sec
			sbc	#$01
			sta	ProcCurDelay,y
			ora	ProcCurDelay+1,y
			bne	:3
			jsr	ResetProcDelay
			lda	ProcStatus,x
			ora	#$80
			sta	ProcStatus,x
::3			iny
			iny
			inx
			cpx	MaxProcess
			bne	:1
::4			rts

			t	"-G3_SysIcon1"
			t	"-G3_SysIcon2"

			b $05,$ff			;Füllbytes

:DB_ArrowGrafx		b $03,$ff,$9e
			b $80,$00,$01,$80,$00,$01,$82,$00
			b $e1,$87,$07,$fd,$8f,$83,$f9,$9f
			b $c1,$f1,$bf,$e0,$e1,$87,$00,$41
			b $80,$00,$01,$80,$00,$01,$03,$ff

;aktueller Grafikmodus mit Grafikmodus des zu ladenden Files
;vergleichen
;Ret: Falscher Modus ->  x = $0e
;    Richtiger Modus ->  x = $00
:xTestgraphMode		bit	graphMode		;welcher Modus ist aktiv?
			bmi	:1			;>80 Zeichen
			bit	fileHeader+$60		;>40 Zeichen, FileModus?
			bpl	:2			;>ebenfalls 40 Zeichen -> OK

::3			ldx	#$0e			;Fehler
			rts

::1			bit	fileHeader+$60		;FileModus?
			bvc	:3			;>kein 40 oder 80 Zeichen File

::2			ldx	#$00			;>OK
			rts

:InitVarData		w	$002e			;ab "currentMode" füllen
			b	12			;Anzahl Initialisierungsbytes
			b	$00			;currentMode
			b	$c0			;dispBufferOn
			b	$00			;mouseOn
			w	mousePicData		;msePicPtr
			b	0			;windowTop
			b	199			;windowBottom
			w	0			;leftMargin
			w	319			;rightMargin
			b	$00			;pressFlag

			w	appMain			;ab "appMain" fülen
			b	28			;Anzahl Initialisierungsbytes
			w	$0000			;appMain
			w	InterruptMain		;intTopVector
			w	$0000			;intBotVec
			w	$0000			;mouseVector
			w	$0000			;keyVector
			w	$0000			;inputVector
			w	$0000			;mouseFaultVector
			w	$0000			;otherPressVector
			w	$0000			;StringFaultVector
			w	$0000			;alarmTmtVector
			w	Panic			;BRKVector
			w	RecoverRectangle	;RecoverVector
			b	$0a			;selectionFlash
			b	$00			;alphaFlag
			b	$80			;iconSelFlag
			b	$00			;faultData

			w	MaxProcess		;Adresse
			b	2			;Anzahl Initialisierungsbytes
			b	$00,$00			;Bytes

			w	DI_VecToEntry		;Adresse
			b	2			;Anzahl Initialisierungsbytes
			b	$00,$00			;Bytes

			w	obj0Pointer		;Adresse
			b	8			;Anzahl Initialisierungsbytes
			b	$28,$29,$2a,$2b,$2c,$2d,$2e,$2f ;Bytes

			w	$0000			;Ende-Kennzeichen

			t	"-G3_GetCurDkNm"

:xInitRam		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			ora	(r0L),y
			beq	:4
			lda	(r0L),y			;Startadresse nach r1
			sta	r1H
			iny
			lda	(r0L),y
			sta	r2L			;Anzahl Bytes nach r2L
			iny
::1			tya
			tax				;Zeiger auf Datenbyte sichern
			lda	(r0L),y			;DatenByte holen
			ldy	#$00
			sta	(r1L),y			;und an Adresse speichern
			inc	r1L			;Speicheradresse erhöhen
			bne	:2
			inc	r1H
::2			txa				;Zeiger auf Datenbyte
			tay				;wiederherstellen
			iny
			dec	r2L			;Zähler erniedrigen
			bne	:1			;>Schleife
			tya
			clc				;Zeiger zu Adresse addieren
			adc	r0L
			sta	r0L
			bcc	:3
			inc	r0H
::3			jmp	xInitRam		;>Schleife
::4			rts				;>fertig

;C128-Vektoren initialisieren
;Hardware-ResetRoutine installieren
;Ersatz für Kernalroutine wegen SCPU128-Fehler mit RamLink!!!
:xNewC128K_RESTORE
			LoadB	RAM_Conf_Reg,$44	;Common Area $0000 - $0400
			ldy	#7
::7			lda	ResetGEOS,y		;Hardware-Reset Routine
			sta	$03e4,y			;installieren
			dey	 			;in Bank 0
			bpl	:7
			LoadB	RAM_Conf_Reg,$40	;keine Common Area

			ldy	#$1f
::1			lda	RestoreTab,y
			sta	$0314,y
			dey
			bpl	:1
			rts

:RestoreTab		w	$fa65
			w	$b003
			w	$fa40
			w	$efbd
			w	$f188
			w	$f106
			w	$f14c
			w	$f226
			w	$ef06
			w	$ef79
			w	$f66e
			w	$eeeb
			w	$f222
			w	$b006
			w	$f26c
			w	$f54e

:ResetGEOS		LoadB	MMU,$7e			;RAM 1 und IO
			jmp	SystemReBoot		;GEOS ReBoot

			t	"-G3_DivMult"

			t	"-G3_GetSerNr"

			t	"-G3_GetRandom"

			t	"-G3_IsMseInReg"

			t	"-G3_NewCRC"

			t	"-G3_IntScrnSave"

			t	"-G3_IntPrnSpool"

;Druckertreiber liegt im Bereich von $d8c0 bis $dfff
;$d8c0 bis $d9c0 > Infoblock
;$d9c0 bis $dfff > eigentlicher Treiber

;******************************************************************************
;*** Speicher bis $D8C0 mit $00-Bytes auffüllen.
;******************************************************************************
:_11T			e $d8c0
:_11
;******************************************************************************
:_12T			s $e000-$d8c0
:_12
;******************************************************************************
;*** Speicher bis $E000 mit $00-Bytes auffüllen.
;******************************************************************************
:_13T			e $e000
:_13
;******************************************************************************

;Bereich Bank 1 $e000 bis $feff
:xHorizontalLine	jsr	JmpBank0		;$E000
:xInvertLine		jsr	JmpBank0		;$E003
:xRecoverLine		jsr	JmpBank0		;$E006
:xVerticalLine		jsr	JmpBank0		;$E009
:xxRectangle		jsr	JmpBank0		;$E00C
:xFrameRectangle	jsr	JmpBank0		;$E00F
:xInvertRectangle	jsr	JmpBank0		;$E012
:xRecoverRectangle	jsr	JmpBank0		;$E015
:xDrawLine		jsr	JmpBank0		;$E018
:xDrawPoint		jsr	JmpBank0		;$E01B
:xxGetScanLine		jsr	JmpBank0		;$E01E
:xTestPoint		jsr	JmpBank0		;$E021
:xBitmapUp		jsr	JmpBank0		;$E024
:xUseSystemFont		jsr	JmpBank0		;$E027
:xGetRealSize		jsr	JmpBank0		;$E02A
:xGetCharWidth		jsr	JmpBank0		;$E02D
:xLoadCharSet		jsr	JmpBank0		;$E030
:xImprintRectangle	jsr	JmpBank0		;$E033
:xBitmapClip		jsr	JmpBank0		;$E036
:xBitOtherClip		jsr	JmpBank0		;$E039
:xInitTextPrompt	jsr	JmpBank0		;$E03C
:xPromptOn		jsr	JmpBank0		;$E03F
:xPromptOff		jsr	JmpBank0		;$E042
.DoSoftSprites		jsr	JmpBank0		;$E045
:PrntCharCode		jsr	JmpBank0		;$E048
:xTempHideMouse		jsr	JmpBank0		;$E04B
:xSetMsePic		jsr	JmpBank0		;$E04E
:xxBldGDirEntry		jsr	JmpBank0		;$E051
:xVDC_ModeInit		jsr	JmpBank0		;$E054
:xColorPoint		jsr	JmpBank0		;$E057
:xDirectColor		jsr	JmpBank0		;$E05A
:xRecColorBox		jsr	JmpBank0		;$E05D
:xMoveBData		jsr	JmpBank0		;$E060
.JumpB0_Basic		jsr	JmpBank0		;$E063
.JumpB0_Basic2		jsr	JmpBank0		;$E066
:xSwapBData		jsr	JmpBank0		;$E069
:xVerifyBData		jsr	JmpBank0		;$E06C
:xDoBOp			jsr	JmpBank0		;$E06F
:xDoBAMBuf		jsr	JmpBank0		;$E072
:xHideOnlyMouse		jsr	JmpBank0		;$E075

.xGetBackScreenVDC	jsr	JmpBank0		;$E078
.xLoad80Screen		jsr	JmpBank0
.xSave80Screen		jsr	JmpBank0
.xSet_C_FarbTab		jsr	JmpBank0
.xSpritesSpool80	jsr	JmpBank0		;SpriteAnz. für Druckerspooler

			t	"-G3_NewGetStrg"

:xPutChar		pha
			ldx	#r11L
			jsr	NormalizeX
			pla
			cmp	#$20			;Akku >= 'SPACE'
			bcs	:1			;>ja
			tay				;>nein dann Steuercode
			lda	PrintCodeL-8,y		;Sprung zur Steuercode-
			ldx	PrintCodeH-8,y		;auswertung (Sprungziel aus
			jmp	CallRoutine		;Tabelle holen)
::1			pha
			ldy	r11H
			sty	r13H
			ldy	r11L
			sty	r13L
			ldx	currentMode
			jsr	xGetRealSize
			dey
			tya
			clc
			adc	r13L
			sta	r13L
			bcc	:2
			inc	r13H
::2			ldx	#rightMargin
			jsr	NormalizeX
			lda	rightMargin +1
			cmp	r13H
			bne	:3
			lda	rightMargin
			cmp	r13L
::3			bcc	:7
			ldx	#leftMargin
			jsr	NormalizeX
			lda	leftMargin +1
			cmp	r11H
			bne	:4
			lda	leftMargin
			cmp	r11L
::4			beq	:5
			bcs	:6
::5			pla
			sec
			sbc	#$20
			jmp	PrntCharCode
::6			lda	r13L
			clc
			adc	#$01
			sta	r11L
			lda	r13H
			adc	#$00
			sta	r11H
::7			pla
			ldx	StringFaultVec +1
			lda	StringFaultVec +0
			jmp	CallRoutine

:PrintCodeL		b	<xBACKSPACE,<xFORWARDSPACE,<xSetLF,<xHOME
			b	<xUPLINE,<xSetCR,<xULINEON,<xULINEOFF
			b	<xESC_GRAPHICS,<xESC_RULER,<xREVON,<xREVOFF
			b	<xGOTOX,<xGOTOY,<xGOTOXY,<xNEWCARDSET
			b	<xBOLDON,<xITALICON,<xOUTLINEON,<xPLAINTEXT

:PrintCodeH		b	>xBACKSPACE,>xFORWARDSPACE,>xSetLF,>xHOME
			b	>xUPLINE,>xSetCR,>xULINEON,>xULINEOFF
			b	>xESC_GRAPHICS,>xESC_RULER,>xREVON,>xREVOFF
			b	>xGOTOX,>xGOTOY,>xGOTOXY,>xNEWCARDSET
			b	>xBOLDON,>xITALICON,>xOUTLINEON,>xPLAINTEXT

:xSmallPutChar		sec
			sbc	#$20
			jmp	PrntCharCode

:xFORWARDSPACE		lda	#$00
			clc
			adc	r11L
			sta	r11L
			bcc	:1
			inc	r11H
::1			rts

:xSetLF			lda	r1H
			sec
			adc	curSetHight
			sta	r1H
			rts

:xHOME			lda	#0
			sta	r11L
			sta	r11H
			sta	r1H
			rts

:xUPLINE		lda	r1H
			sec
			sbc	curSetHight
			sta	r1H
			rts

:xSetCR			lda	leftMargin +1
			sta	r11H
			lda	leftMargin +0
			sta	r11L
			jmp	xSetLF

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

:xGOTOX			jsr	SetNxByte_r0
			ldy	#$00
			lda	(r0L),y
			sta	r11L
			jsr	SetNxByte_r0
			lda	(r0L),y
			sta	r11H
			rts

:xGOTOY			jsr	SetNxByte_r0
			ldy	#$00
			lda	(r0L),y
			sta	r1H
			rts

:xGOTOXY		jsr	xGOTOX
			jmp	xGOTOY

:xNEWCARDSET		clc
			lda	#$03
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H
::1			rts

:RemoveChar		ldx	currentMode
			jsr	xGetRealSize
			sty	CurCharWidth

:xBACKSPACE		lda	r11L
			sec
			sbc	CurCharWidth
			sta	r11L
			bcs	:1
			dec	r11H
::1			lda	r11H
			pha
			lda	r11L
			pha
			lda	#$5f
			jsr	PrntCharCode
			pla
			sta	r11L
			pla
			sta	r11H
			rts

:xESC_GRAPHICS		jsr	SetNxByte_r0
			jsr	xGraphicsString
			ldx	#r0L
			jsr	Ddec
			ldx	#r0L
			jmp	Ddec

:xPutString		ldy	#$00
			lda	(r0L),y
			beq	:1
			jsr	xPutChar
			jsr	SetNxByte_r0
			jmp	xPutString
::1			rts

			t	"-G3_ConvD2A"

			t	"-G3_PutDecimal"

			t	"-G3_NewFindFTyp"

			t	"-G3_F_F_Chain"

			t	"-G3_LoadFile"

			t	"-G3_NewFindFile"

			t	"-G3_NewGetFHdr"

			t	"-G3_SaveFile"

			t	 "-G3_SetGDirEnt"

			t	 "-G3_DelFile"

			t	"-G3_RenFile"

			t	"-G3_RecordFile"

			t	"-G3_ReadByte"

			t	"-G3_NewDlgBox"

			t	"-G3_SvLdGEOSvar"

.xStartAppl		sei
			cld
			ldx	#$ff
			txs
			jsr	SaveFileData
			jsr	GEOS_Init0
			jsr	xUseSystemFont
			jsr	LoadFileData
			ldx	r7H
			lda	r7L
			jsr	CallRoutine
			cli
			jmp	MainLoop

;*** GEOS-Variablen initialisieren
:GEOS_InitVar		PushB	MMU
			lda	#$7f
			sta	MMU
			LoadW	r0,InitVarData
			jsr	dInitRam
			PopB	MMU
			jmp	NewModeInit

;*** Kernal-Variablen initialisieren
:InitGEOS		LoadB	$00,$2f
			LoadB	MMU,$7e
			ldx	#7
			lda	#$ff
::6			sta	KB_MultipleKey,x
			sta	KB_LastKeyTab,x
			dex
			bpl	:6
			stx	keyMode
			stx	$dc02
			inx
			stx	keyBufPointer
			stx	MaxKeyInBuf
			stx	$dc03
			stx	$dc0f
			stx	$dd0f
			LoadB	RAM_Conf_Reg,$47
			lda	$0a03			;PAL ($FF) oder NTSC ($00) ?
			beq	:5			;>NTSC
			ldx	#$80
::5			LoadB	RAM_Conf_Reg,$40
			stx	$dc0e
			stx	$dd0e
			lda	$dd00
			and	#$30
			ora	#$05
			sta	$dd00
			LoadB	$dd02,$3f
			LoadB	$dc0d,$7f
			sta	$dd0d
			lda	$dc0d
			lda	$dd0d
			ldy	#$00
::1			lda	InitVICdata,y
			cmp	#$aa
			beq	:2
			sta	$d000,y
::2			iny
			cpy	#$1e
			bne	:1
			ldx	#36
::4			jsr	GetVDC
			cmp	InitVDCdata,x
			beq	:3
			lda	InitVDCdata,x
			cmp	#$ff
			beq	:3
			jsr	SetVDC
::3			dex
			bpl	:4
			lda	#2			;immer Farbe!
			jsr	VDC_ModeInit
			jsr	dNewC128K_RESTORE
			jmp	SetMseFullWin

			t	"-G3_New1stInit"
			t	"-G3_ResetScreen"

:xStartMouseMode	bcc	:1
			lda	r11L
			ora	r11H
			beq	:1
			ldx	#r11L
			jsr	NormalizeX
			lda	r11L
			sta	mouseXPos+0
			lda	r11H
			sta	mouseXPos+1
			sty	mouseYPos
			jsr	SlowMouse
::1			LoadW	mouseVector,ChkMseButton
			LoadW	mouseFaultVec,IsMseOnMenu
			LoadB	faultData,$00
			jmp	MouseUp

:xClearMouseMode	LoadB	mouseOn,$00

:MouseSpriteOff		LoadB	r3L,$00
			jmp	xDisablSprite

:xMouseOff		lda	#$7f
			and	mouseOn
			sta	mouseOn
			jmp	MouseSpriteOff

:xMouseUp		lda	#$80
			ora	mouseOn
			sta	mouseOn
			lda	mobenble
			ora	#$01
			sta	mobenble
			rts

:InitMouseData		jsr	UpdateMouse
			bit	mouseOn
			bpl	:2
			jsr	SetMseToArea
			LoadB	r3L,$00
			bit	graphMode
			bmi	:1
			lda	msePicPtr+0
			sta	r4L
			lda	msePicPtr+1
			sta	r4H
			jsr	DrawSprite
::1			lda	mouseXPos+0
			sta	r4L
			lda	mouseXPos+1
			sta	r4H
			lda	mouseYPos
			sta	r5L
			jsr	PosSprite
::2			rts

			t	"-G3_NewMseToRec"

:ChkMseButton		lda	mouseData
			bmi	:6
			lda	mouseOn
			and	#$80
			beq	:6
			lda	mouseOn
			and	#$40
			beq	:5
			lda	mouseYPos
			cmp	DM_MenuRange
			bcc	:5
			cmp	DM_MenuRange+1
			beq	:1
			bcs	:5
::1			lda	mouseXPos +1
			cmp	DM_MenuRange+3
			bne	:2
			lda	mouseXPos +0
			cmp	DM_MenuRange+2
::2			bcc	:5
			lda	mouseXPos +1
			cmp	DM_MenuRange+5
			bne	:3
			lda	mouseXPos +0
			cmp	DM_MenuRange+4
::3			beq	:4
			bcs	:5
::4			jmp	DM_ExecMenuJob

::5			lda	mouseOn
			and	#$20
			beq	:6
			jmp	DI_ChkMseClk

::6			lda	otherPressVec +0
			ldx	otherPressVec +1
			jmp	CallRoutine

:IsMseOnMenu		lda	#$c0
			bit	mouseOn
			bpl	:3
			bvc	:3
			lda	menuNumber
			beq	:3
			lda	faultData
			and	#$08
			bne	:2
			ldx	#$80
			lda	#$c0
			tay
			bit	DM_MenuType
			bmi	:1
			ldx	#$20
::1			txa
			and	faultData
			bne	:2
			tya
			bit	DM_MenuType
			bvs	:3
::2			jsr	xDoPreviousMenu
::3			rts

			t	"-G3_NewDoMenu"

			t	"-G3_NewDoIcons"

:xi_UserColor		sta	r7L
			ldy	#$05       ;Zeiger auf Inline-Daten ohne Farbe
			b $2c
:xi_ColorBox		ldy	#$06        ;Zeiger auf Inline-Daten mit Farbe
			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			sty	:a +1			;Überlesende Bytes merken.
			dey				;Zeiger auf Datenbyte.
::1			lda	(returnAddress),y
			sta	r5 -1,y
			dey
			bne	:1

			jsr	xRecColorBox		;Farbrechteck darstellen.
			php				;Zurück zur aufrufenden Routine
::a			lda	#$ff
			jmp	DoInlineReturn

;******************************************************************************
;*** Speicher bis $FCD9 mit $00-Bytes auffüllen.
;******************************************************************************
:_14T			e $fcd9
:_14
;******************************************************************************
;--- Ergänzung: 29.06.18/M.Kanet
;Code-Rekonstruktion: Die Version von 2003 beinhaltet ab $fcd9 eine Routine zum speichern der C128-Register
;MMU, RAM_Conf_Reg und CLKRATE. Die Routine wird u.a. von JmpKernal verwendet.
.Sv128			lda	MMU
			sta	c128_BufMMU
			lda	RAM_Conf_Reg
			sta	c128_BufRAMConf
			lda	CLKRATE
			sta	c128_BufMHZ
			rts
.Ld128			lda	c128_BufMHZ
			sta	CLKRATE
			rts

;******************************************************************************
;*** Speicher bis $FD00 mit $00-Bytes auffüllen.
;******************************************************************************
:_15T			e $fd00
:_15
;******************************************************************************

			d	"SuperMouse128"

			e	$fe80

.InitMouse		jmp	$fd00			;Sprungtabelle für Maustreiber
.SlowMouse		jmp	$fd03
.UpdateMouse		jmp	$fd06
.SetMouse		jmp	$fd09
;			jmp	$fd0c

			t	"-G3_TaskMan"

.DlgBoxDTdisk		b	$81
			b	$0b,$10,$16
			w	DlgBoxDTopMsg1
			b	$0b,$10,$26
			w	DlgBoxDTopMsg2
			b	$01,$11,$48
			b	$00

.Get2Word1Byte		ldy	#$01
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

;*** GEOS initialisieren.
:GEOS_Init0		lda	#$00			;Flag für Dialogbox/SwapFile
			sta	Flag_ExtRAMinUse   ;zurücksetzen

.GEOS_Init1		jsr	InitGEOS		;GEOS-Register definieren
			jsr	GEOS_InitVar		;Kernal-Variablen initialisieren.
			jmp	SetNewModeInit		;40/80 Zeichen-Modus init.

;******************************************************************************
;*** Speicher bis $FF00 mit $00-Bytes auffüllen.
;******************************************************************************
:_16T			e $ff00
:_16
;******************************************************************************
			s	5			;MMU-Register!

;Bereich Bank 1 $ff05 bis $ffff
.GEOS_IRQ		cld
			pha
			PushB	MMU
			LoadB	MMU,$7e
			PushB	RAM_Conf_Reg
			and	#$f0
			sta	RAM_Conf_Reg
			jsr	xGEOS_IRQ
			PopB	RAM_Conf_Reg
			PopB	MMU
			pla
.IRQ_END		rti

;Register 0 bis 36 des VDC
.InitVDCdata		b $7e,$50,$66,$49,$ff,$e0,$ff,$20
			b $fc,$ff,$a0,$e7,$00,$00,$00,$00
			b $ff,$ff,$ff,$ff,$ff,$ff,$78,$e8
			b $ff,$ff,$ff,$00,$ff,$f8,$ff,$ff
			b $ff,$ff,$7d,$64,$ff

:Get3Byte		jsr	Get1Byte
			tax
			jsr	Get1Byte
			sta	r2L
			jsr	Get1Byte
			ldy	r2L
			rts

:Get1Byte		ldy	#$00
			lda	(r0L),y
			jsr	SetNxByte_r0
			cmp	#$00
			rts

:xi_GraphicsString	pla
			sta	r0L
			pla
			sta	r0H
			jsr	SetNxByte_r0
			jsr	xGraphicsString
			jmp	(r0)

;******************************************************************************
;*** Hintergrundbild einlesen.
;******************************************************************************
			t "-G3_GetBackScrn"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $FF81 mit $00-Bytes auffüllen.
;******************************************************************************
:_17T			e $ff81
:_17
;******************************************************************************

;--- Ergänzung: 26.11.18/M.Kanet
;C128-Kernal-Adressen bezeichnet.
;Hinweis zu SETNAM und SETBNK ergänzt.
			jsr	JmpKernal		;CINTInit editor & display
			jsr	JmpKernal		;IOINITInit I/O devices
			jsr	JmpKernal		;RAMTASInitialize RAM and buffers for system
			jsr	JmpKernal		;RESTORERestore vectors to initial system
			jsr	JmpKernal		;VECTORChange vectors for USER
			jsr	JmpKernal		;SETMSGControl O.S. message
			jsr	JmpKernal		;SECNDSend secondary adresse after LISTEN
			jsr	JmpKernal		;TKSASend secondary adresse after TALK
			jsr	JmpKernal		;MEMTOPSet/Read top of system RAM
			jsr	JmpKernal		;MEMBOTSet/Read bottom of system RAM
			jsr	JmpKernal		;KEYScan keyboard (editor)
			jsr	JmpKernal		;SETTMOSet timeout in IEEE (reserved)
			jsr	JmpKernal		;ACPTRHandshake serial byte in
			jsr	JmpKernal		;CIOUTHandshake serial byte out
			jsr	JmpKernal		;UNTLKSend UNTALK to serial bus
			jsr	JmpKernal		;UNLSNSend UNLISTEN to serial bus
			jsr	JmpKernal		;LISTENSend LISTEN to serial bus
			jsr	JmpKernal		;TALKSend TALK to serial bus
			jsr	JmpKernal		;READSSReturn I/O status byte
			jsr	JmpKernal		;SETLFSSet Channel, adress, secondary adress
			jsr	JmpKernal		;SETNAMSet length and file name adress
							;NOTE: You need to use SETBANK before
							;SETNAME which is not mapped in here.
							;Use sta $c6/stx $c7 instead.
			jsr	JmpKernal		;OPENOPEN logical file
			jsr	JmpKernal		;CLOSECLOSE logical file
			jsr	JmpKernal		;CHKINSet input channel
			jsr	JmpKernal		;CKOUTSet output channel
			jsr	JmpKernal		;CLRCHRestore default I/O channel
			jsr	JmpKernal		;BASININPUT from channel
			jsr	JmpKernal		;BSOUTOUTPUT to channel
			jsr	JmpKernal		;LOADSPLOAD from file
			jsr	JmpKernal		;SAVESPSAVE to file
			jsr	JmpKernal		;SETTIMSet internal clock
			jsr	JmpKernal		;RDTIMRead internal clock
			jsr	JmpKernal		;STOPScan STOP key
			jsr	JmpKernal		;GETINRead buffered data
			jsr	JmpKernal		;CLALLClose all files and channels
			jsr	JmpKernal		;CLOCKIncrement internal clock
			jsr	JmpKernal		;SCRORGReturn screen window size
			jsr	JmpKernal		;PLOTRead/set X,Y currsor coordinates

;******************************************************************************
;*** Speicher bis $FFF5 mit $00-Bytes auffüllen.
;******************************************************************************
:_18T			e $fff5
:_18
;******************************************************************************

			b	$43,$42,$4d		;CBM-Kennung für Hardwarereset
			w	$03e4			;Sprungadresse für Reset

.NMI_VECTOR		w	IRQ_END
.RESET_VECTOR		w	IRQ_END
.IRQ_VECTOR		w	GEOS_IRQ
