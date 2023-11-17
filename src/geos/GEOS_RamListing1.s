; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

$C000			4C1BC0	jmp $C01B
$C003			4C0050	jmp $5000

$C006			47	b "GEOS BOOT"			;bootName	
$C00F			20	b $20			;version
$C010			01	b $01			;nationality
$C011			00	b $00
$C012			00	b $00			;sysFlgCopy
$C013			00	b $00			;c128Flag
$C014			05	b $05
$C015			00	b $00
$C016			00	b $00
$C017			00	b $00
$C018			580706	b $58,$07,$06			;dateCopy
$C019			07	b $07
$C01A			06	b $06

$C01B			AD12C0	lda sysFlgCopy			;ReBootGEOS
$C01E			2920	and %00100000
$C020			D01F	bne $C041

$C022			2090FF	jsr SETMSG

$C025			A909	lda #$09
$C027			A206	ldx #$52
$C029			A0C0	ldy #$C0
$C02B			20BDFF	jsr SETNAM
$C02E			A950	lda #$50
$C030			A208	ldx #$08
$C032			A001	ldy #$01
$C034			20BAFF	jsr SETLFS
$C037			A900	lda #$00
$C039			20D5FF	jsr LOAD
$C03C			9011	bcc $C04F
$C03E			6C0203	jmp ($0302)

$C041			A008	ldy #$08			;ReBootRAM
$C043			B952C0	lda $C052,y
$C046			9901DF	sta ramExpBase2 +1,y
$C049			88	dey
$C04A			10F7	bpl $C043
$C04C			88	dey
$C04D			D0FD	bne $C04C
$C04F			4C0060	jmp $6000			;StartBoot

$C052			91	b $91			;RamBootData
$C053			0060	w $6000
$C055			007E	w $7E00
$C057			00	b $00
$C058			0005	w $0500
$C05A			00	b $00
$C05B			00	b $00

$C05C			A027	ldy #$27				;xToBasic
$C05E			B102	lda (r0L),y
$C060			C941	cmp #$41
$C062			9006	bcc $C06A
$C064			C95B	cmp #$5B
$C066			B002	bcs $C06A
$C068			E93F	sbc #$3F
$C06A			99019F	sta $9F01,y
$C06D			88	dey
$C06E			10EE	bpl $C05E
$C070			A50D	lda r5H
$C072			F043	beq $C0B7
$C074			C8	iny
$C075			98	tya
$C076			990008	sta $0800,y
$C079			C8	iny
$C07A			D0FA	bne $C076
$C07C			38	sec
$C07D			A510	lda r7L
$C07F			E902	sbc #$02
$C081			8510	sta r7L
$C083			A511	lda r7H
$C085			E900	sbc #$00
$C087			8511	sta r7H
$C089			B110	lda (r7L),y
$C08B			48	pha
$C08C			C8	iny
$C08D			B110	lda (r7L),y
$C08F			48	pha
$C090			A511	lda r7H
$C092			48	pha
$C093			A510	lda r7L
$C095			48	pha
$C096			B10C	lda (r5L),y
$C098			8504	sta r1L
$C09A			C8	iny
$C09B			B10C	lda (r5L),y
$C09D			8505	sta r1H
$C09F			A9FF	lda #$FF
$C0A1			8506	sta r2L
$C0A3			8507	sta r2H
$C0A5			208C9D	jsr xReadFile
$C0A8			68	pla
$C0A9			8502	sta r0L
$C0AB			68	pla
$C0AC			8503	sta r0H
$C0AE			A001	ldy #$01
$C0B0			68	pla
$C0B1			9102	sta (r0L),y
$C0B3			88	dey
$C0B4			68	pla
$C0B5			9102	sta (r0L),y
$C0B7			2047C2	jsr GetDirHead
$C0BA			2035C2	jsr PurgeTurbo
$C0BD			ADC488	lda sysRAMFlg
$C0C0			8D12C0	sta sysFlgCopy
$C0C3			2920	and #%00100000
$C0C5			F00E	beq $C0D5
$C0C7			A006	ldy #$06
$C0C9			B9D8C0	lda $C0D8,y
$C0CC			990200	sta r0,y
$C0CF			88	dey
$C0D0			10F7	bpl $C0C9
$C0D2			20C8C2	jsr StashRAM
$C0D5			4C2F9F	jmp JumpToBasic

$C0D8			0084	w dirEntryBuf +$00			;BootBasicData
$C0DA			0079	w $7900
$C0DC			0005	w $0500
$C0DE			00	b $00

$C0DF			2067FA	jsr ExecMseKeyB			;xMainLoop
$C0E2			2055CB	jsr ExecProcTab
$C0E5			2023CC	jsr ExecSleepJob
$C0E8			2057FD	jsr SetGeosClock
$C0EB			AD9B84	lda appMain
$C0EE			AE9C84	ldx appMain+1
$C0F1			20D8C1	jsr CallRoutine			;InitMLoop1
$C0F4			58	cli 			;InitMLoop2
$C0F5			4C13C3	jmp InitSysIRQ

$C0F8			1E	b < DrACurDkNm
$C0F9			30	b < DrBCurDkNm
$C0FA			DC	b < DrCCurDkNm
$C0FB			EE	b < DrDCurDkNm

$C0FC			84	b > DrACurDkNm
$C0FD			84	b > DrBCurDkNm
$C0FE			88	b > DrCCurDkNm
$C0FF			88	b > DrDCurDkNm

$C100			4CD7C2	jmp xInterruptMain
$C103			4C1DCB	jmp xInitProcesses
$C106			4CC5CB	jmp xRestartProcess
$C109			4CE0CB	jmp xEnableProcess
$C10C			4CE9CB	jmp xBlockProcess
$C10F			4CF1CB	jmp xUnblockProcess
$C112			4CF9CB	jmp xFreezeProcess
$C115			4C01CC	jmp xUnfreezeProcess
$C118			4C51C6	jmp xHorizontalLine
$C11B			4CD6C6	jmp xInvertLine
$C11E			4C6AC7	jmp xRecoverLine
$C121			4CE9C7	jmp xVerticalLine
$C124			4C55C8	jmp xRectangle
$C127			4CC3C8	jmp xFrameRectangle
$C12A			4C6CC8	jmp xInvertRectangle
$C12D			4C88C8	jmp xRecoverRectangle
$C130			4CB8E9	jmp xDrawLine
$C133			4C44EB	jmp xDrawPoint
$C136			4C4DC9	jmp xGraphicsString
$C139			4C53CA	jmp xSetPattern
$C13C			4C7DCA	jmp xGetScanLine
$C13F			4C81EB	jmp xTestPoint
$C142			4C2DE4	jmp xBitmapUp
$C145			4CF5E4	jmp xPutChar
$C148			4C91E6	jmp xPutString
$C14B			4CA4E6	jmp xUseSystemFont
$C14E			4CA1EB	jmp xStartMouseMode
$C151			4C39ED	jmp xDoMenu
$C154			4C9CEF	jmp xRecoverMenu
$C157			4C8BEF	jmp xRecoverAllMenus
$C15A			4C4FF1	jmp xDoIcons
$C15D			4C32CD	jmp xDShiftLeft
$C160			4C48CD	jmp xBBMult
$C163			4C69CD	jmp xBMult
$C166			4C6ECD	jmp xDMult
$C169			4CA1CD	jmp xDdiv
$C16C			4CCFCD	jmp xDSdiv
$C16F			4CEBCD	jmp xDabs
$C172			4CF0CD	jmp xDnegate
$C175			4C03CE	jmp xDdec
$C178			4C41C5	jmp xClearRam
$C17B			4C45C5	jmp xFillRam
$C17E			4C97CE	jmp xMoveData
$C181			4C67C5	jmp xInitRam
$C184			4C54E9	jmp xPutDecimal
$C187			4C10CE	jmp xGetRandom
$C18A			4CE6EB	jmp xMouseUp
$C18D			4CDDEB	jmp xMouseOff
$C190			4C19EE	jmp xDoPreviousMenu
$C193			4C02EE	jmp xReDoMenu
$C196			4CF3CF	jmp xGetSerialNumber
$C199			4C7ACC	jmp xSleep
$C19C			4CD2EB	jmp xClearMouseMode
$C19F			4C49C8	jmp xi_Rectangle
$C1A2			4CB4C8	jmp xi_FrameRectangle
$C1A5			4C7CC8	jmp xi_RecoverRectangle
$C1A8			4C3AC9	jmp xi_GraphicsString
$C1AB			4CFFE3	jmp xi_BitmapUp
$C1AE			4C58E6	jmp xi_PutString
$C1B1			4C4BDE	jmp xGetRealSize
$C1B4			4C01D5	jmp xi_FillRam
$C1B7			4C65CE	jmp xi_MoveData
$C1BA			4CFAE6	jmp xGetString
$C1BD			4C08EE	jmp xGotoFirstMenu
$C1C0			4CACE8	jmp xInitTextPrompt
$C1C3			4CDFC0	jmp xMainLoop
$C1C6			4C9ACC	jmp xDrawSprite
$C1C9			4CDEE6	jmp xGetCharWidth
$C1CC			4CACE6	jmp xLoadCharSet
$C1CF			4CC0CC	jmp xPosSprite
$C1D2			4C02CD	jmp xEnablSprite
$C1D5			4C1ACD	jmp xDisablSprite
$C1D8			4C9FC5	jmp xCallRoutine
$C1DB			6C2090	jmp ($9020)
$C1DE			6C2C90	jmp ($902C)
$C1E1			6C0C90	jmp ($900C)
$C1E4			6C1690	jmp ($9016)
$C1E7			6C1890	jmp ($9018)
$C1EA			6C2E90	jmp ($902E)
$C1ED			4C54D8	jmp xSaveFile
$C1F0			4CECD8	jmp xSetGDirEntry
$C1F3			4C1ED9	jmp xBldGDirEntry
$C1F6			6C1E90	jmp ($901E)
$C1F9			4C289E	jmp xWriteFile
$C1FC			6C2A90	jmp ($902A)
$C1FF			4C8C9D	jmp xReadFile
$C202			4C7CE5	jmp xSmallPutChar
$C205			4C83D5	jmp xFollowChain
$C208			4C13D5	jmp xGetFile
$C20B			4C66D6	jmp xFindFile
$C20E			4C7EE9	jmp xCRC
$C211			4C3CD5	jmp xLdFile
$C214			6C0890	jmp ($9008)
$C217			4C7FD7	jmp xLdDeskAcc
$C21A			6C0E90	jmp ($900E)
$C21D			4C0CD8	jmp xLdApplic
$C220			6C1090	jmp ($9010)
$C223			6C1290	jmp ($9012)

$C226			4CABD9	jmp xFreeFile
$C229			4C23D7	jmp xGetFHdrInfo
$C22C			4C26C3	jmp xEnterDeskTop
$C22F			4CA8C3	jmp xStartAppl
$C232			6C0490	jmp ($9004)
$C235			6C0690	jmp ($9006)
$C238			4C9CD9	jmp xDeleteFile
$C23B			4CBAD5	jmp xFindFTypes
$C23E			4CD5D7	jmp xRstrAppl
$C241			4C5CC0	jmp xToBasic
$C244			4C72DA	jmp xFastDelFile
$C247			6C1A90	jmp ($901A)
$C24A			6C1C90	jmp ($901C)
$C24D			6C2890	jmp ($9028)
$C250			4CA4C8	jmp xImprintRectangle
$C253			4C98C8	jmp xi_ImprintRectangle
$C256			4CB9F2	jmp xDoDlgBox
$C259			4CBCDA	jmp xRenameFile
$C25C			6C0090	jmp ($9000)
$C25F			6C0290	jmp ($9002)
$C262			4C3DCD	jmp xDShiftRight
$C265			4C47CE	jmp xCopyString
$C268			4C49CE	jmp xCopyFString
$C26B			4C38CF	jmp xCmpString
$C26E			4C3ACF	jmp xCmpFString
$C271			4CE6C4	jmp xFirstInit
$C274			4CF5DA	jmp xOpenRecordFile
$C277			4C6FDB	jmp xCloseRecordFile
$C27A			4CBEDB	jmp xNextRecord
$C27D			4CC7DB	jmp xPreviousRecord
$C280			4CCDDB	jmp xPointRecord
$C283			4CE7DB	jmp xDeleteRecord
$C286			4C2ADC	jmp xInsertRecord
$C289			4C40DC	jmp xAppendRecord
$C28C			4C5ADC	jmp xReadRecord
$C28F			4C6FDC	jmp xWriteRecord
$C292			6C2490	jmp ($9024)
$C295			4C78DB	jmp xUpdateRecFile
$C298			4C05C3	jmp xGetPtrCurDkNm
$C29B			4C6EE8	jmp xPromptOn
$C29E			4C92E8	jmp xPromptOff
$C2A1			6C1490	jmp ($9014)
$C2A4			4CAFC5	jmp xDoInlineReturn
$C2A7			4CF0FC	jmp xGetNextChar
$C2AA			4CB2E3	jmp xBitmapClip
$C2AD			6C2690	jmp ($9026)
$C2B0			4CB6D6	jmp xSetDevice
$C2B3			4C5CCF	jmp xIsMseInRegion
$C2B6			4CD1DD	jmp xReadByte
$C2B9			6C2290	jmp ($9022)
$C2BC			6C0A90	jmp ($900A)
$C2BF			4C29F4	jmp xRstrFrmDialogue
$C2C2			4C88CF	jmp xPanic
$C2C5			4CADE3	jmp xBitOtherClip
$C2C8			4CAE9E	jmp xStashRAM
$C2CB			4CB69E	jmp xFetchRAM
$C2CE			4CB29E	jmp xSwapRAM
$C2D1			4CAA9E	jmp xVerifyRAM
$C2D4			4CB89E	jmp xDoRAMOp

$C2D7			20EDEB	jsr InitMouseData			;xInterruptMain
$C2DA			2086CB	jsr PrepProcData
$C2DD			2009CC	jsr DecSleepTime
$C2E0			2074E7	jsr SetCursorMode
$C2E3			4C10CE	jmp xGetRandom

$C2E6			80402010b $80,$40,$20,$10			;BitData1	
$C2EA			080402	b $08,$04,$02
$C2ED			01020408b $01,$02,$04,$08			;BitData2
$C2F1			10204080b $10,$20,$40,$80
$C2F5			0080C0E0b $00,$80,$C0,$E0			;BitData3
$C2F9			F0F8FCFEb $F0,$F8,$FC,$FE
$C2FD			7F3F1F0Fb $7F,$3F,$1F,$0F			;BitData4
$C301			07030100b $07,$03,$01,$00

$C305			AC8984	ldy curDrive			;xGetPtrCurDkNm
$C308			B9F0C0	lda $C0F0,y
$C30B			9500	sta zPage+0,x
$C30D			B9F4C0	lda InitMLoop2,y
$C310			9501	sta zPage+1,x
$C312			60	rts

$C313			A601	ldx CPU_DATA			;InitSysIRQ
$C315			A935	lda #$35
$C317			8501	sta CPU_DATA
$C319			AD11D0	lda grcntrl1
$C31C			297F	and #%01111111
$C31E			8D11D0	sta grcntrl1
$C321			8601	stx CPU_DATA
$C323			4CDFC0	jmp xMainLoop

$C326			78	sei 			;xEnterDeskTop
$C327			D8	cld
$C328			A2FF	ldx #$FF
$C32A			8EC588	stx firstBoot
$C32D			9A	txs
$C32E			209CC4	jsr ClrDeskScrn
$C331			200AC4	jsr GEOS_Init1
$C334			AD8984	lda curDrive
$C337			8D6888	sta StartDTdrv
$C33A			4901	eor #%00000001
$C33C			A8	tay
$C33D			B98684	lda driveType -8,y
$C340			08	php
$C341			AD6888	lda StartDTdrv
$C344			28	plp
$C345			1001	bpl DT_StartSearch
$C347			98	tya

$C348			206AC3	jsr IsDTonDisk			;DT_StartSearch
$C34B			AC8D84	ldy numDrives
$C34E			C002	cpy #$02
$C350			9008	bcc DT_NotFound
$C352			AD8984	lda curDrive
$C355			4901	eor #%00000001
$C357			206AC3	jsr IsDTonDisk

$C35A			A9C3	lda #>DlgBoxDTdisk			;DT_NotFound
$C35C			8503	sta r0H
$C35E			A9C0	lda #<DlgBoxDTdisk
$C360			8502	sta r0L
$C362			2056C2	jsr DoDlgBox
$C365			AD6888	lda StartDTdrv
$C368			D0DE	bne DT_StartSearch

$C36A			20B0C2	jsr SetDevice			;IsDTonDisk
$C36D			20A1C2	jsr OpenDisk
$C370			8A	txa
$C371			F001	beq $C374
$C373			60	rts

$C374			8502	sta r0L
$C376			A9C3	lda #>DeskTopName
$C378			850F	sta r6H
$C37A			A9CF	lda #<DeskTopName
$C37C			850E	sta r6L
$C37E			2008C2	jsr GetFile
$C381			8A	txa
$C382			D0EF	bne $C373

$C384			AD5A81	lda $815A
$C387			C931	cmp #$31
$C389			90E8	bcc $C373
$C38B			D007	bne $C394
$C38D			AD5C81	lda $815C
$C390			C935	cmp #$35
$C392			90DF	bcc $C373

$C394			AD6888	lda StartDTdrv
$C397			20B0C2	jsr SetDevice
$C39A			A900	lda #$00
$C39C			8502	sta r0L
$C39E			AD4C81	lda fileHeader+$4C
$C3A1			8511	sta r7H
$C3A3			AD4B81	lda fileHeader+$4B
$C3A6			8510	sta r7L

$C3A8			78	sei 			;xStartAppl
$C3A9			D8	cld
$C3AA			A2FF	ldx #$FF
$C3AC			9A	txs
$C3AD			20F8C5	jsr SaveFileData
$C3B0			200AC4	jsr GEOS_Init1
$C3B3			20A4E6	jsr xUseSystemFont
$C3B6			20CFC5	jsr LoadFileData
$C3B9			A611	ldx r7H
$C3BB			A510	lda r7L
$C3BD			4CF1C0	jmp InitMLoop1

$C3C0			81	b $81			;DlgBoxDTdisk
$C3C1			0B1016	b $0B,$10,$16
$C3C4			D8C3	w SysMsg1
$C3C6			0B1026	b $0B,$10,$26
$C3C9			F6C3	w SysMsg2
$C3CB			011148	b $01,$11,$48
$C3CE			00	b $00
$C3CF			4445534Bb "DESK TOP",$00			;DeskTopName
$C3D3			20544F50
$C3D7			00
$C3D8			18	b $18			;SysMsg1
$C3D9			42697474b "Bitt"
$C3DD			65206569b "e ei"
$C3E1			6E652044b "ne D"
$C3E5			69736B65b "iske"
$C3E9			74746520b "tte "
$C3ED			65696E6Cb "einl"
$C3F1			6567656Eb "egen"
$C3F5			00	b $00
$C3F6			64696520b "die "			;SysMsg2
$C3FA			6465736Bb "desk"
$C3FE			546F7020b "Top "
$C402			656E7468b "enth"
$C406			7B6C74	b "ält"
$C409			00	b $00

$C40A			2036C4	jsr SysVarInit1			;GEOS_Init1

$C40D			A9DE	lda #>InitVarData			;GEOS_Init2
$C40F			8503	sta r0H
$C411			A903	lda #<InitVarData
$C413			8502	sta r0L
$C415			4C67C5	jmp xInitRam

$C418			00000000b $00,$00,$00,$00			;InitVarData
$C41C			00000000b $00,$00,$00,$00
$C420			00000000b $00,$00,$00,$00
$C424			00000000b $00,$00,$00,$00
$C428			003BFBAAb $00,$3B,$FB,$AA
$C42C			AA010800b $AA,$01,$08,$00
$C430			380F0100b $38,$0F,$01,$00
$C434			0000	b $00,$00

$C436			A92F	lda #$2F			;SysVarInit1
$C438			8500	sta $00
$C43A			A936	lda #$36
$C43C			8501	sta CPU_DATA
$C43E			A207	ldx #$07
$C440			A9FF	lda #$FF
$C442			9DF387	sta KB_MultipleKey,x
$C445			9DEB87	sta KB_LastKeyTab,x
$C448			CA	dex
$C449			10F7	bpl $C442
$C44B			8ED987	stx keyMode
$C44E			8E02DC	stx $DC02
$C451			E8	inx
$C452			8ED787	stx keyBufPointer
$C455			8ED887	stx MaxKeyInBuf
$C458			8E03DC	stx $DC03
$C45B			8E0FDC	stx $DC0F
$C45E			8E0FDD	stx $DD0F
$C461			ADA602	lda $02A6
$C464			F002	beq $C468
$C466			A280	ldx #$80
$C468			8E0EDC	stx $DC0E
$C46B			8E0EDD	stx $DD0E
$C46E			AD00DD	lda $DD00
$C471			2930	and #%00110000
$C473			0905	ora #%00000101
$C475			8D00DD	sta $DD00
$C478			A93F	lda #$3F
$C47A			8D02DD	sta $DD02
$C47D			A97F	lda #$7F
$C47F			8D0DDC	sta $DC0D
$C482			8D0DDD	sta $DD0D
$C485			A9C4	lda #>InitVICdata
$C487			8503	sta r0H
$C489			A918	lda #<InitVICdata
$C48B			8502	sta r0L
$C48D			A01E	ldy #$1e
$C48F			20BCC5	jsr VIC_Init
$C492			20DAC4	jsr SetKernalVec
$C495			A930	lda #$30
$C497			8501	sta CPU_DATA
$C499			4C82F1	jmp SetMseFullWin

$C49C			A9A0	lda #$A0			;ClrDeskScrn
$C49E			8503	sta r0H
$C4A0			A900	lda #$00
$C4A2			8502	sta r0L
$C4A4			A960	lda #$60
$C4A6			8505	sta r1H
$C4A8			A900	lda #$00
$C4AA			8504	sta r1L

$C4AC			A27D	ldx #$7D
$C4AE			A03F	ldy #$3F
$C4B0			A955	lda #$55
$C4B2			9102	sta (r0L),y
$C4B4			9104	sta (r1L),y
$C4B6			88	dey
$C4B7			A9AA	lda #$AA
$C4B9			9102	sta (r0L),y
$C4BB			9104	sta (r1L),y
$C4BD			88	dey
$C4BE			10F0	bpl $C4B0

$C4C0			18	clc
$C4C1			A940	lda #$40
$C4C3			6502	adc r0L
$C4C5			8502	sta r0L
$C4C7			9002	bcc $C4CB
$C4C9			E603	inc r0H

$C4CB			18	clc
$C4CC			A940	lda #$40
$C4CE			6504	adc r1L
$C4D0			8504	sta r1L
$C4D2			9002	bcc $C4D6
$C4D4			E605	inc r1H

$C4D6			CA	dex
$C4D7			D0D5	bne $C4AE
$C4D9			60	rts

$C4DA			A220	ldx #$20			;SetKernalVec
$C4DC			BD2FFD	lda $FD2F,x
$C4DF			9D1303	sta $0313,x
$C4E2			CA	dex
$C4E3			D0F7	bne $C4DC
$C4E5			60	rts

$C4E6			78	sei 			;xFirstInit
$C4E7			D8	cld
$C4E8			200AC4	jsr GEOS_Init1

$C4EB			A9C3	lda #>EnterDeskTop
$C4ED			8D2EC2	sta EnterDeskTop+2
$C4F0			A926	lda #<EnterDeskTop
$C4F2			8D2DC2	sta EnterDeskTop+1

$C4F5			A97F	lda #$7F
$C4F7			8D0185	sta maxMouseSpee
$C4FA			A91E	lda #$1E
$C4FC			8D0285	sta minMouseSpee

$C4FF			A97F	lda #$7F
$C501			8D0385	sta mouseAccel
$C504			A9BF	lda #$BF
$C506			8D1E85	sta screenColors
$C509			8D13C5	sta $C513
$C50C			20B4C1	jsr i_FillRam
$C50F			E803	w 1000
$C511			008C	w COLOR_MATRIX
$C513			BF
$C514			A601	ldx CPU_DATA
$C516			A935	lda #$35
$C518			8501	sta CPU_DATA
$C51A			A906	lda #$06
$C51C			8D27D0	sta mob0clr
$C51F			8D28D0	sta mob1clr

$C522			A900	lda #$00
$C524			8D20D0	sta extclr
$C527			8601	stx CPU_DATA

$C529			A03E	ldy #$3E
$C52B			A900	lda #$00
$C52D			99C184	sta mousePicData,y
$C530			88	dey
$C531			10F8	bpl $C52B

$C533			A218	ldx #$18
$C535			BD3FBF	lda $BF3F,x
$C538			9DC084	sta stringY,x
$C53B			CA	dex
$C53C			D0F7	bne $C535
$C53E			4C9DE3	jmp DefSprPoi

$C541			A900	lda #$00			;xClearRam
$C543			8506	sta r2L

$C545			A503	lda r0H			;xFillRam
$C547			F00F	beq $C558
$C549			A506	lda r2L
$C54B			A000	ldy #$00
$C54D			9104	sta (r1L),y
$C54F			88	dey
$C550			D0FB	bne $C54D
$C552			E605	inc r1H
$C554			C603	dec r0H
$C556			D0F5	bne $C54D
$C558			A506	lda r2L
$C55A			A402	ldy r0L
$C55C			F008	beq $C566
$C55E			88	dey
$C55F			9104	sta (r1L),y
$C561			88	dey
$C562			C0FF	cpy #$FF
$C564			D0F9	bne $C55F
$C566			60	rts

$C567			A000	ldy #$00			;xInitRam
$C569			B102	lda (r0L),y
$C56B			8504	sta r1L
$C56D			C8	iny
$C56E			1102	ora (r0L),y
$C570			F02C	beq $C59E
$C572			B102	lda (r0L),y
$C574			8505	sta r1H
$C576			C8	iny
$C577			B102	lda (r0L),y
$C579			8506	sta r2L
$C57B			C8	iny
$C57C			98	tya
$C57D			AA	tax
$C57E			B102	lda (r0L),y
$C580			A000	ldy #$00
$C582			9104	sta (r1L),y
$C584			E604	inc r1L
$C586			D002	bne $C58A
$C588			E605	inc r1H
$C58A			8A	txa
$C58B			A8	tay
$C58C			C8	iny
$C58D			C606	dec r2L
$C58F			D0EB	bne $C57C
$C591			98	tya
$C592			18	clc
$C593			6502	adc r0L
$C595			8502	sta r0L
$C597			9002	bcc $C59B
$C599			E603	inc r0H
$C59B			B8	clv
$C59C			50C9	bvc xInitRam
$C59E			60	rts

$C59F			C900	cmp #$00			;xCallRoutine
$C5A1			D004	bne $C5A7
$C5A3			E000	cpx #$00
$C5A5			F007	beq $C5AE
$C5A7			8541	sta CallRoutVec+0
$C5A9			8642	stx CallRoutVec+1
$C5AB			6C4100	jmp (CallRoutVec)
$C5AE			60	rts

$C5AF			18	clc 			;xDoInlineReturn
$C5B0			653D	adc returnAddress
$C5B2			853D	sta returnAddress
$C5B4			9002	bcc $C5B8
$C5B6			E63E	inc returnAddress+1
$C5B8			28	plp
$C5B9			6C3D00	jmp (returnAddress)

$C5BC			8404	sty r1L			;VIC_Init
$C5BE			A000	ldy #$00
$C5C0			B102	lda (r0L),y
$C5C2			C9AA	cmp #$AA
$C5C4			F003	beq $C5C9
$C5C6			9900D0	sta mob0xpos,y
$C5C9			C8	iny
$C5CA			C404	cpy r1L
$C5CC			D0F2	bne $C5C0
$C5CE			60	rts

$C5CF			AD5D88	lda DA_ResetScrn			;LoadFileData
$C5D2			8516	sta r10L
$C5D4			AD5E88	lda LoadFileMode
$C5D7			8502	sta r0L
$C5D9			2901	and #%00000001
$C5DB			F00A	beq $C5E7
$C5DD			AD6088	lda LoadBufAdr+1
$C5E0			8511	sta r7H
$C5E2			AD5F88	lda LoadBufAdr+0
$C5E5			8510	sta r7L
$C5E7			A984	lda #>dataDiskName
$C5E9			8507	sta r2H
$C5EB			A953	lda #<dataDiskName
$C5ED			8506	sta r2L
$C5EF			A984	lda #>dataFileName
$C5F1			8509	sta r3H
$C5F3			A942	lda #<dataFileName
$C5F5			8508	sta r3L
$C5F7			60	rts

$C5F8			A511	lda r7H			;SaveFileData
$C5FA			8D6088	sta LoadBufAdr+1
$C5FD			A510	lda r7L
$C5FF			8D5F88	sta LoadBufAdr+0
$C602			A516	lda r10L
$C604			8D5D88	sta DA_ResetScrn
$C607			A502	lda r0L
$C609			8D5E88	sta LoadFileMode
$C60C			29C0	and #%11000000
$C60E			F01A	beq $C62A
$C610			A084	ldy #>dataDiskName
$C612			A953	lda #<dataDiskName
$C614			A206	ldx #r2L
$C616			201FC6	jsr Copy1String
$C619			A084	ldy #>dataFileName
$C61B			A942	lda #<dataFileName
$C61D			A208	ldx #r3L			;Copy1String
$C61F			840B	sty r4H
$C621			850A	sta r4L
$C623			A00A	ldy #r4L
$C625			A910	lda #$10
$C627			2068C2	jsr CopyFString
$C62A			60	rts

$C62B			A618	ldx r11L			;GetCARDs
$C62D			207DCA	jsr xGetScanLine
$C630			A50A	lda r4L
$C632			2907	and #%00000111
$C634			AA	tax
$C635			BDFDC2	lda BitData4,x
$C638			8513	sta r8H
$C63A			A508	lda r3L
$C63C			2907	and #%00000111
$C63E			AA	tax
$C63F			BDF5C2	lda BitData3,x
$C642			8512	sta r8L
$C644			A508	lda r3L
$C646			29F8	and #%11111000
$C648			8508	sta r3L
$C64A			A50A	lda r4L
$C64C			29F8	and #%11111000
$C64E			850A	sta r4L
$C650			60	rts

$C651			8510	sta r7L			;xHorizontalLine
$C653			A509	lda r3H
$C655			48	pha
$C656			A508	lda r3L
$C658			48	pha
$C659			A50B	lda r4H
$C65B			48	pha
$C65C			A50A	lda r4L
$C65E			48	pha
$C65F			202BC6	jsr GetCARDs

$C662			A408	ldy r3L
$C664			A509	lda r3H
$C666			F004	beq $C66C
$C668			E60D	inc r5H
$C66A			E60F	inc r6H

$C66C			A509	lda r3H
$C66E			C50B	cmp r4H
$C670			D004	bne $C676
$C672			A508	lda r3L
$C674			C50A	cmp r4L
$C676			F032	beq $C6AA

$C678			A50A	lda r4L
$C67A			38	sec
$C67B			E508	sbc r3L
$C67D			850A	sta r4L
$C67F			A50B	lda r4H
$C681			E509	sbc r3H
$C683			850B	sta r4H

$C685			460B	lsr r4H
$C687			660A	ror r4L
$C689			460A	lsr r4L
$C68B			460A	lsr r4L
$C68D			A512	lda r8L
$C68F			20C7C6	jsr GetLinePattern

$C692			910E	sta (r6L),y
$C694			910C	sta (r5L),y
$C696			98	tya
$C697			18	clc
$C698			6908	adc #$08
$C69A			A8	tay
$C69B			9004	bcc $C6A1
$C69D			E60D	inc r5H
$C69F			E60F	inc r6H
$C6A1			C60A	dec r4L
$C6A3			F00C	beq $C6B1
$C6A5			A510	lda r7L
$C6A7			B8	clv
$C6A8			50E8	bvc $C692

$C6AA			A512	lda r8L
$C6AC			0513	ora r8H
$C6AE			B8	clv
$C6AF			5002	bvc $C6B3

$C6B1			A513	lda r8H
$C6B3			20C7C6	jsr GetLinePattern

$C6B6			910E	sta (r6L),y			;SetLastGrByt
$C6B8			910C	sta (r5L),y

$C6BA			68	pla 			;ExitGrafxRout
$C6BB			850A	sta r4L
$C6BD			68	pla
$C6BE			850B	sta r4H
$C6C0			68	pla
$C6C1			8508	sta r3L
$C6C3			68	pla
$C6C4			8509	sta r3H
$C6C6			60	rts

$C6C7			8519	sta r11H			;GetLinePattern
$C6C9			310E	and (r6L),y
$C6CB			8511	sta r7H
$C6CD			A519	lda r11H
$C6CF			49FF	eor #%11111111
$C6D1			2510	and r7L
$C6D3			0511	ora r7H
$C6D5			60	rts

$C6D6			A509	lda r3H			;xInvertLine
$C6D8			48	pha
$C6D9			A508	lda r3L
$C6DB			48	pha
$C6DC			A50B	lda r4H
$C6DE			48	pha
$C6DF			A50A	lda r4L
$C6E1			48	pha
$C6E2			202BC6	jsr GetCARDs

$C6E5			A408	ldy r3L
$C6E7			A509	lda r3H
$C6E9			F004	beq $C6EF
$C6EB			E60D	inc r5H
$C6ED			E60F	inc r6H

$C6EF			A509	lda r3H
$C6F1			C50B	cmp r4H
$C6F3			D004	bne $C6F9
$C6F5			A508	lda r3L
$C6F7			C50A	cmp r4L
$C6F9			F033	beq $C72E

$C6FB			A50A	lda r4L
$C6FD			38	sec
$C6FE			E508	sbc r3L
$C700			850A	sta r4L
$C702			A50B	lda r4H
$C704			E509	sbc r3H
$C706			850B	sta r4H

$C708			460B	lsr r4H
$C70A			660A	ror r4L
$C70C			460A	lsr r4L
$C70E			460A	lsr r4L
$C710			A512	lda r8L
$C712			510C	eor (r5L),y

$C714			49FF	eor #%11111111
$C716			910E	sta (r6L),y
$C718			910C	sta (r5L),y
$C71A			98	tya
$C71B			18	clc
$C71C			6908	adc #$08
$C71E			A8	tay
$C71F			9004	bcc $C725
$C721			E60D	inc r5H
$C723			E60F	inc r6H
$C725			C60A	dec r4L
$C727			F00C	beq $C735
$C729			B10C	lda (r5L),y
$C72B			B8	clv
$C72C			50E6	bvc $C714

$C72E			A512	lda r8L
$C730			0513	ora r8H
$C732			B8	clv
$C733			5002	bvc $C737

$C735			A513	lda r8H
$C737			49FF	eor #%11111111
$C739			510C	eor (r5L),y
$C73B			4CB6C6	jmp SetLastGrByt

$C73E			A509	lda r3H			;ImprintRecLine
$C740			48	pha
$C741			A508	lda r3L
$C743			48	pha
$C744			A50B	lda r4H
$C746			48	pha
$C747			A50A	lda r4L
$C749			48	pha
$C74A			A52F	lda dispBufferOn
$C74C			48	pha
$C74D			09C0	ora #%11000000
$C74F			852F	sta dispBufferOn
$C751			202BC6	jsr GetCARDs
$C754			68	pla
$C755			852F	sta dispBufferOn

$C757			A50C	lda r5L
$C759			A40E	ldy r6L
$C75B			850E	sta r6L
$C75D			840C	sty r5L
$C75F			A50D	lda r5H
$C761			A40F	ldy r6H
$C763			850F	sta r6H
$C765			840D	sty r5H
$C767			B8	clv
$C768			5019	bvc MovGrafxData

$C76A			A509	lda r3H			;xRecoverLine
$C76C			48	pha
$C76D			A508	lda r3L
$C76F			48	pha
$C770			A50B	lda r4H
$C772			48	pha
$C773			A50A	lda r4L
$C775			48	pha
$C776			A52F	lda dispBufferOn
$C778			48	pha
$C779			09C0	ora #%11000000
$C77B			852F	sta dispBufferOn
$C77D			202BC6	jsr GetCARDs
$C780			68	pla
$C781			852F	sta dispBufferOn

$C783			A408	ldy r3L			;MovGrafxData
$C785			A509	lda r3H
$C787			F004	beq $C78D
$C789			E60D	inc r5H
$C78B			E60F	inc r6H

$C78D			A509	lda r3H
$C78F			C50B	cmp r4H
$C791			D004	bne $C797
$C793			A508	lda r3L
$C795			C50A	cmp r4L
$C797			F030	beq $C7C9

$C799			A50A	lda r4L
$C79B			38	sec
$C79C			E508	sbc r3L
$C79E			850A	sta r4L
$C7A0			A50B	lda r4H
$C7A2			E509	sbc r3H
$C7A4			850B	sta r4H

$C7A6			460B	lsr r4H
$C7A8			660A	ror r4L
$C7AA			460A	lsr r4L
$C7AC			460A	lsr r4L
$C7AE			A512	lda r8L
$C7B0			20D8C7	jsr LinkGrafxMem

$C7B3			98	tya
$C7B4			18	clc
$C7B5			6908	adc #$08
$C7B7			A8	tay
$C7B8			9004	bcc $C7BE
$C7BA			E60D	inc r5H
$C7BC			E60F	inc r6H
$C7BE			C60A	dec r4L
$C7C0			F00E	beq $C7D0

$C7C2			B10E	lda (r6L),y
$C7C4			910C	sta (r5L),y
$C7C6			B8	clv
$C7C7			50EA	bvc $C7B3

$C7C9			A512	lda r8L
$C7CB			0513	ora r8H
$C7CD			B8	clv
$C7CE			5002	bvc $C7D2

$C7D0			A513	lda r8H
$C7D2			20D8C7	jsr LinkGrafxMem
$C7D5			4CBAC6	jmp ExitGrafxRout

$C7D8			8510	sta r7L			;LinkGrafxMem
$C7DA			310C	and (r5L),y
$C7DC			8511	sta r7H
$C7DE			A510	lda r7L
$C7E0			49FF	eor #%11111111
$C7E2			310E	and (r6L),y
$C7E4			0511	ora r7H
$C7E6			910C	sta (r5L),y
$C7E8			60	rts

$C7E9			8512	sta r8L			;xVerticalLine

$C7EB			A50A	lda r4L
$C7ED			48	pha
$C7EE			2907	and #%00000111
$C7F0			AA	tax
$C7F1			BDE6C2	lda BitData1,x
$C7F4			8511	sta r7H

$C7F6			A50A	lda r4L
$C7F8			29F8	and #%11111000
$C7FA			850A	sta r4L

$C7FC			A000	ldy #$00
$C7FE			A608	ldx r3L

$C800			8610	stx r7L
$C802			207DCA	jsr xGetScanLine

$C805			A50A	lda r4L
$C807			18	clc
$C808			650C	adc r5L
$C80A			850C	sta r5L
$C80C			A50B	lda r4H
$C80E			650D	adc r5H
$C810			850D	sta r5H

$C812			A50A	lda r4L
$C814			18	clc
$C815			650E	adc r6L
$C817			850E	sta r6L
$C819			A50B	lda r4H
$C81B			650F	adc r6H
$C81D			850F	sta r6H

$C81F			A510	lda r7L
$C821			2907	and #%00000111
$C823			AA	tax
$C824			BDE6C2	lda BitData1,x
$C827			2512	and r8L
$C829			D009	bne $C834

$C82B			A511	lda r7H
$C82D			49FF	eor #%11111111
$C82F			310E	and (r6L),y
$C831			B8	clv
$C832			5004	bvc $C838

$C834			A511	lda r7H
$C836			110E	ora (r6L),y

$C838			910E	sta (r6L),y
$C83A			910C	sta (r5L),y
$C83C			A610	ldx r7L
$C83E			E8	inx
$C83F			E409	cpx r3H
$C841			F0BD	beq $C800
$C843			90BB	bcc $C800
$C845			68	pla
$C846			850A	sta r4L
$C848			60	rts

$C849			2008C9	jsr GetInlineData			;xi_Rectangle
$C84C			2055C8	jsr xRectangle
$C84F			08	php
$C850			A907	lda #$07
$C852			4CA4C2	jmp DoInlineReturn

$C854			A506	lda r2L			;xRectangle
$C857			8518	sta r11L

$C859			A518	lda r11L
$C85B			2907	and #%00000111
$C85D			A8	tay
$C85E			B122	lda (curPattern),y
$C860			2051C6	jsr xHorizontalLine

$C863			A518	lda r11L
$C865			E618	inc r11L
$C867			C507	cmp r2H
$C869			D0EE	bne $C859
$C86B			60	rts

$C86C			A506	lda r2L			;xInvertRectangle
$C86E			8518	sta r11L

$C870			20D6C6	jsr xInvertLine
$C873			A518	lda r11L
$C875			E618	inc r11L
$C877			C507	cmp r2H
$C879			D0F5	bne $C870
$C87B			60	rts

$C87C			2008C9	jsr GetInlineData			;xi_RecoverRectangle
$C87F			2088C8	jsr xRecoverRectangle
$C882			08	php
$C883			A907	lda #$07
$C885			4CA4C2	jmp DoInlineReturn

$C888			A506	lda r2L			;xRecoverRectangle
$C88A			8518	sta r11L

$C88C			206AC7	jsr xRecoverLine
$C88F			A518	lda r11L
$C891			E618	inc r11L
$C893			C507	cmp r2H
$C895			D0F5	bne $C88C
$C897			60	rts

$C898			2008C9	jsr GetInlineData			;xi_ImprintRectangle
$C89B			20A4C8	jsr xImprintRectangle
$C89E			08	php
$C89F			A907	lda #$07
$C8A1			4CA4C2	jmp DoInlineReturn

$C8A4			A506	lda r2L			;xImprintRectangle
$C8A6			8518	sta r11L

$C8A8			203EC7	jsr ImprintRecLine
$C8AB			A518	lda r11L
$C8AD			E618	inc r11L
$C8AF			C507	cmp r2H
$C8B1			D0F5	bne $C8A8
$C8B3			60	rts

$C8B4			2008C9	jsr GetInlineData			;xi_FrameRectangle
$C8B7			C8	iny
$C8B8			B13D	lda (returnAddress),y
$C8BA			20C3C8	jsr xFrameRectangle
$C8BD			08	php
$C8BE			A908	lda #$08
$C8C0			4CA4C2	jmp DoInlineReturn

$C8C3			8515	sta r9H			;xFrameRectangle

$C8C5			A406	ldy r2L
$C8C7			8418	sty r11L
$C8C9			2051C6	jsr xHorizontalLine

$C8CC			A507	lda r2H
$C8CE			8518	sta r11L
$C8D0			A515	lda r9H
$C8D2			2051C6	jsr xHorizontalLine

$C8D5			A509	lda r3H
$C8D7			48	pha
$C8D8			A508	lda r3L
$C8DA			48	pha
$C8DB			A50B	lda r4H
$C8DD			48	pha
$C8DE			A50A	lda r4L
$C8E0			48	pha

$C8E1			A509	lda r3H
$C8E3			850B	sta r4H
$C8E5			A508	lda r3L
$C8E7			850A	sta r4L
$C8E9			A507	lda r2H
$C8EB			8509	sta r3H
$C8ED			A506	lda r2L
$C8EF			8508	sta r3L
$C8F1			A515	lda r9H
$C8F3			20E9C7	jsr xVerticalLine

$C8F6			68	pla
$C8F7			850A	sta r4L
$C8F9			68	pla
$C8FA			850B	sta r4H
$C8FC			A515	lda r9H
$C8FE			20E9C7	jsr xVerticalLine

$C901			68	pla
$C902			8508	sta r3L
$C904			68	pla
$C905			8509	sta r3H
$C907			60	rts

$C908			68	pla 			;GetInlineData
$C909			850C	sta r5L
$C90B			68	pla
$C90C			850D	sta r5H
$C90E			68	pla
$C90F			853D	sta returnAddress
$C911			68	pla
$C912			853E	sta returnAddress+1

$C914			A001	ldy #$01
$C916			B13D	lda (returnAddress),y
$C918			8506	sta r2L
$C91A			C8	iny
$C91B			B13D	lda (returnAddress),y
$C91D			8507	sta r2H
$C91F			C8	iny
$C920			B13D	lda (returnAddress),y
$C922			8508	sta r3L
$C924			C8	iny
$C925			B13D	lda (returnAddress),y
$C927			8509	sta r3H
$C929			C8	iny
$C92A			B13D	lda (returnAddress),y
$C92C			850A	sta r4L
$C92E			C8	iny
$C92F			B13D	lda (returnAddress),y
$C931			850B	sta r4H

$C933			A50D	lda r5H
$C935			48	pha
$C936			A50C	lda r5L
$C938			48	pha
$C939			60	rts

$C93A			68	pla 			;xi_GraphicsString
$C93B			8502	sta r0L
$C93D			68	pla
$C93E			E602	inc r0L
$C940			D003	bne $C945
$C942			18	clc
$C943			6901	adc #$01
$C945			8503	sta r0H
$C947			204DC9	jsr xGraphicsString
$C94A			6C0200	jmp (r0)

$C94D			2070CA	jsr Get1Byte			;xGraphicsString
$C950			F00E	beq $C960
$C952			A8	tay
$C953			88	dey
$C954			B961C9	lda GS_RoutTabL,y
$C957			BE6BC9	ldx GS_RoutTabH,y
$C95A			20D8C1	jsr CallRoutine
$C95D			B8	clv
$C95E			50ED	bvc xGraphicsString
$C960			60	rts

$C961			75	b < GS_MOVEPENTO			;GS_RoutTabL
$C962			82	b < GS_LINETO
$C963			A0	b < GS_RECTANGLETO
$C964			A6	b < GS_PENFILL
$C965			A7	b < GS_NEWPATTERN
$C966			AD	b < GS_PUTSTRING
$C967			C0	b < GS_FRAMERECTO
$C968			CC	b < GS_PENXDELTA
$C969			E8	b < GS_PENYDELTA
$C96A			C8	b < GS_PENXYDELTA

$C96B			C9	b > GS_MOVEPENTO			;GS_RoutTabH
$C96C			C9	b > GS_LINETO
$C96D			C9	b > GS_RECTANGLETO
$C96E			C9	b > GS_PENFILL
$C96F			C9	b > GS_NEWPATTERN
$C970			C9	b > GS_PUTSTRING
$C971			C9	b > GS_FRAMERECTO
$C972			C9	b > GS_PENXDELTA
$C973			C9	b > GS_PENYDELTA
$C974			C9	b > GS_PENXYDELTA

$C975			2061CA	jsr Get3Byte			;GS_MOVEPENTO
$C978			8DD687	sta GS_Ypos
$C97B			8ED487	stx GS_XposL
$C97E			8CD587	sty GS_XposH
$C981			60	rts

$C982			ADD587	lda GS_XposH			;GS_LINETO
$C985			8509	sta r3H
$C987			ADD487	lda GS_XposL
$C98A			8508	sta r3L
$C98C			ADD687	lda GS_Ypos
$C98F			8518	sta r11L
$C991			2075C9	jsr GS_MOVEPENTO
$C994			8519	sta r11H
$C996			860A	stx r4L
$C998			840B	sty r4H
$C99A			38	sec
$C99B			A900	lda #$00
$C99D			4CB8E9	jmp xDrawLine

$C9A0			2000CA	jsr GetXYpar			;GS_RECTANGLETO
$C9A3			4C55C8	jmp xRectangle

$C9A6			60	rts 			;GS_PENFILL

$C9A7			2070CA	jsr Get1Byte			;GS_NEWPATTERN
$C9AA			4C53CA	jmp xSetPattern

$C9AD			2070CA	jsr Get1Byte			;GS_PUTSTRING
$C9B0			8518	sta r11L
$C9B2			2070CA	jsr Get1Byte
$C9B5			8519	sta r11H
$C9B7			2070CA	jsr Get1Byte
$C9BA			8505	sta r1H
$C9BC			2091E6	jsr xPutString
$C9BF			60	rts

$C9C0			2000CA	jsr GetXYpar			;GS_FRAMERECTO
$C9C3			A9FF	lda #$FF
$C9C5			4CC3C8	jmp xFrameRectangle

$C9C8			A201	ldx #$01			;GS_PENXYDELTA
$C9CA			D002	bne $C9CE

$C9CC			A200	ldx #$00			;GS_PENXDELTA
$C9CE			A000	ldy #$00			;GS_SetXDelta
$C9D0			B102	lda (r0L),y
$C9D2			C8	iny
$C9D3			18	clc
$C9D4			6DD487	adc GS_XposL
$C9D7			8DD487	sta GS_XposL
$C9DA			B102	lda (r0L),y
$C9DC			C8	iny
$C9DD			6DD587	adc GS_XposH
$C9E0			8DD587	sta GS_XposH
$C9E3			8A	txa
$C9E4			F00F	beq $C9F5
$C9E6			D002	bne $C9EA

$C9E8			A000	ldy #$00			;GS_PENYDELTA
$C9EA			B102	lda (r0L),y			;GS_SetYDelta
$C9EC			C8	iny
$C9ED			18	clc
$C9EE			6DD687	adc GS_Ypos
$C9F1			8DD687	sta GS_Ypos
$C9F4			C8	iny
$C9F5			98	tya
$C9F6			18	clc
$C9F7			6502	adc r0L
$C9F9			8502	sta r0L
$C9FB			9002	bcc $C9FF
$C9FD			E603	inc r0H
$C9FF			60	rts

$CA00			2061CA	jsr Get3Byte			;GS_GetXYpar
$CA03			CDD687	cmp GS_Ypos
$CA06			B00B	bcs $CA13
$CA08			8506	sta r2L
$CA0A			48	pha
$CA0B			ADD687	lda GS_Ypos
$CA0E			8507	sta r2H
$CA10			B8	clv
$CA11			5008	bvc $CA1B

$CA13			8507	sta r2H
$CA15			48	pha
$CA16			ADD687	lda GS_Ypos
$CA19			8506	sta r2L

$CA1B			68	pla
$CA1C			8DD687	sta GS_Ypos
$CA1F			CCD587	cpy GS_XposH
$CA22			F002	beq $CA26
$CA24			B018	bcs $CA3E
$CA26			9005	bcc $CA2D
$CA28			ECD487	cpx GS_XposL
$CA2B			B011	bcs $CA3E

$CA2D			8608	stx r3L
$CA2F			8409	sty r3H
$CA31			ADD587	lda GS_XposH
$CA34			850B	sta r4H
$CA36			ADD487	lda GS_XposL
$CA39			850A	sta r4L
$CA3B			B8	clv
$CA3C			500E	bvc $CA4C

$CA3E			860A	stx r4L
$CA40			840B	sty r4H
$CA42			ADD587	lda GS_XposH
$CA45			8509	sta r3H
$CA47			ADD487	lda GS_XposL
$CA4A			8508	sta r3L
$CA4C			8ED487	stx GS_XposL
$CA4F			8CD587	sty GS_XposH
$CA52			60	rts

$CA53			0A	asl 			;xSetPattern
$CA54			0A	asl
$CA55			0A	asl
$CA56			6900	adc #$00
$CA58			8522	sta curPattern+0
$CA5A			A900	lda #$00
$CA5C			69D0	adc #$D0
$CA5E			8523	sta curPattern+1
$CA60			60	rts

$CA61			2070CA	jsr Get1Byte			;Get3Byte
$CA64			AA	tax
$CA65			2070CA	jsr Get1Byte
$CA68			8506	sta r2L
$CA6A			2070CA	jsr Get1Byte
$CA6D			A406	ldy r2L
$CA6F			60	rts

$CA70			A000	ldy #$00			;Get1Byte
$CA72			B102	lda (r0L),y
$CA74			E602	inc r0L
$CA76			D002	bne $CA7A
$CA78			E603	inc r0H
$CA7A			C900	cmp #$00
$CA7C			60	rts

$CA7D			8A	txa 			;xGetScanLine
$CA7E			48	pha
$CA7F			48	pha
$CA80			2907	and #%00000111
$CA82			850F	sta r6H
$CA84			68	pla
$CA85			4A	lsr
$CA86			4A	lsr
$CA87			4A	lsr
$CA88			AA	tax
$CA89			242F	bit dispBufferOn
$CA8B			1031	bpl $CABE
$CA8D			242F	bit dispBufferOn
$CA8F			7017	bvs $CAA8
$CA91			BDEBCA	lda GrfxLinAdrL,x
$CA94			050F	ora r6H
$CA96			850C	sta r5L
$CA98			BD04CB	lda GrfxLinAdrH,x
$CA9B			850D	sta r5H
$CA9D			A50D	lda r5H
$CA9F			850F	sta r6H
$CAA1			A50C	lda r5L
$CAA3			850E	sta r6L
$CAA5			68	pla
$CAA6			AA	tax
$CAA7			60	rts

$CAA8			BDEBCA	lda GrfxLinAdrL,x
$CAAB			050F	ora r6H
$CAAD			850C	sta r5L
$CAAF			850E	sta r6L
$CAB1			BD04CB	lda GrfxLinAdrH,x
$CAB4			850D	sta r5H
$CAB6			38	sec
$CAB7			E940	sbc #$40
$CAB9			850F	sta r6H
$CABB			68	pla
$CABC			AA	tax
$CABD			60	rts

$CABE			242F	bit dispBufferOn
$CAC0			501A	bvc $CADC
$CAC2			BDEBCA	lda GrfxLinAdrL,x
$CAC5			050F	ora r6H
$CAC7			850E	sta r6L
$CAC9			BD04CB	lda GrfxLinAdrH,x
$CACC			38	sec
$CACD			E940	sbc #$40
$CACF			850F	sta r6H
$CAD1			A50F	lda r6H
$CAD3			850D	sta r5H
$CAD5			A50E	lda r6L
$CAD7			850C	sta r5L
$CAD9			68	pla
$CADA			AA	tax
$CADB			60	rts

$CADC			A900	lda #$00
$CADE			850C	sta r5L
$CAE0			850E	sta r6L
$CAE2			A9AF	lda #$AF
$CAE4			850D	sta r5H
$CAE6			850F	sta r6H
$CAE8			68	pla
$CAE9			AA	tax
$CAEA			60	rts

$CAEB			004080c0b $00,$40,$80,$C0	;GrfxLinAdrL
$CAEF			004080c0b $00,$40,$80,$C0
$CAF3			004080c0b $00,$40,$80,$C0
$CAF7			004080c0b $00,$40,$80,$C0
$CAFB			004080c0b $00,$40,$80,$C0
$CAFF			004080c0b $00,$40,$80,$C0
$CB03			00	b $00

$CB04			A0A1A2A3b $A0,$A1,$A2,$A3	;GrfxLinAdrH
$CB08			A5A6A7A8b $A5,$A6,$A7,$A8
$CB0C			AAABACADb $AA,$AB,$AC,$AD
$CB0C			AFB0B1B2b $AF,$B0,$B1,$B2
$CB0C			B4B5B6B7b $B4,$B5,$B6,$B7
$CB0C			B9BABBBCb $B9,$BA,$BB,$BC
$CB0C			BE	b $BE

$CB1D			A200	ldx #$00			;xInitProcesses	
$CB1F			8E7D87	stx MaxProcess
$CB22			8504	sta r1L
$CB24			8505	sta r1H
$CB26			AA	tax
$CB27			A920	lda #%00100000
$CB29			9D1887	sta ProcStatus-1,x
$CB2C			CA	dex
$CB2D			D0FA	bne $CB29

$CB2F			A000	ldy #$00
$CB31			B102	lda (r0L),y
$CB33			9D2D87	sta ProcRout  +0,x
$CB36			C8	iny
$CB37			B102	lda (r0L),y
$CB39			9D2E87	sta ProcRout  +1,x
$CB3C			C8	iny
$CB3D			B102	lda (r0L),y
$CB3F			9D5587	sta ProcDelay +0,x
$CB42			C8	iny
$CB43			B102	lda (r0L),y
$CB45			9D5687	sta ProcDelay +1,x
$CB48			C8	iny
$CB49			E8	inx
$CB4A			E8	inx
$CB4B			C605	dec r1H
$CB4D			D0E2	bne $CB31
$CB4F			A504	lda r1L
$CB51			8D7D87	sta MaxProcess
$CB54			60	rts

$CB55			AE7D87	ldx MaxProcess			;ExecProcTab
$CB58			F028	beq $CB82
$CB5A			CA	dex
$CB5B			BD1987	lda ProcStatus,x
$CB5E			101F	bpl $CB7F
$CB60			2940	and #%01000000
$CB62			D01B	bne $CB7F
$CB64			BD1987	lda ProcStatus,x
$CB67			297F	and #%01111111
$CB69			9D1987	sta ProcStatus,x
$CB6C			8A	txa
$CB6D			48	pha
$CB6E			0A	asl
$CB6F			AA	tax
$CB70			BD2D87	lda ProcRout  +0,x
$CB73			8502	sta r0L
$CB75			BD2E87	lda ProcRout  +1,x
$CB78			8503	sta r0H
$CB7A			2083CB	jsr ExecProcRout
$CB7D			68	pla
$CB7E			AA	tax
$CB7F			CA	dex
$CB80			10D9	bpl $CB5B
$CB82			60	rts

$CB83			6C0200	jmp (r0)			;ExecProcRout

$CB86			A900	lda #$00			;PrepProcData
$CB88			A8	tay
$CB89			AA	tax
$CB8A			CD7D87	cmp MaxProcess
$CB8D			F035	beq $CBC4

$CB8F			BD1987	lda ProcStatus,x
$CB92			2930	and #%00110000
$CB94			D026	bne $CBBC

$CB96			B9F186	lda ProcCurDelay+0,y
$CB99			D00B	bne $CBA6
$CB9B			48	pha
$CB9C			B9F286	lda ProcCurDelay+1,y
$CB9F			38	sec
$CBA0			E901	sbc #$01
$CBA2			99F286	sta ProcCurDelay+1,y
$CBA5			68	pla
$CBA6			38	sec
$CBA7			E901	sbc #$01
$CBA9			99F186	sta ProcCurDelay+0,y
$CBAC			19F286	ora ProcCurDelay+1,y
$CBAF			D00B	bne $CBBC

$CBB1			20CDCB	jsr ResetProcDelay

$CBB4			BD1987	lda ProcStatus,x
$CBB7			0980	ora #%10000000
$CBB9			9D1987	sta ProcStatus,x
$CBBC			C8	iny
$CBBD			C8	iny
$CBBE			E8	inx
$CBBF			EC7D87	cpx MaxProcess
$CBC2			D0CB	bne $CB8F

$CBC4			60	rts

$CBC5			BD1987	lda ProcStatus,x			;xRestartProcess
$CBC8			299F	and #%10011111
$CBCA			9D1987	sta ProcStatus,x

$CBCD			8A	txa 			;ResetProcDelay
$CBCE			48	pha
$CBCF			0A	asl
$CBD0			AA	tax
$CBD1			BD5587	lda ProcDelay +0,x
$CBD4			9DF186	sta ProcCurDelay+0,x
$CBD7			BD5687	lda ProcDelay +1,x
$CBDA			9DF286	sta ProcCurDelay+1,x
$CBDD			68	pla
$CBDE			AA	tax
$CBDF			60	rts

$CBE0			BD1987	lda ProcStatus,x			;xEnableProcess
$CBE3			0980	ora #%10000000
$CBE5			9D1987	sta ProcStatus,x
$CBE8			60	rts

$CBE9			BD1987	lda ProcStatus,x			;xBlockProcess
$CBEC			0940	ora #%01000000
$CBEE			B8	clv
$CBEF			50F4	bvc $CBE5

$CBF1			BD1987	lda ProcStatus,x			;xUnblockProcess
$CBF4			29BF	and #%10111111
$CBF6			B8	clv
$CBF7			50EC	bvc $CBE5

$CBF9			BD1987	lda ProcStatus,x			;xFreezeProcess
$CBFC			0920	ora #%00100000
$CBFE			B8	clv
$CBFF			50E4	bvc $CBE5

$CC01			BD1987	lda ProcStatus,x			;xUnfreezeProcess
$CC04			29DF	and #%11011111
$CC06			B8	clv
$CC07			50DC	bvc $CBE5

$CC09			AE7E87	ldx MaxSleep			;DecSleepTime
$CC0C			F014	beq $CC22
$CC0E			CA	dex
$CC0F			BD7F87	lda SleepTimeL,x
$CC12			D008	bne $CC1C
$CC14			1D9387	ora SleepTimeH,x
$CC17			F006	beq $CC1F
$CC19			DE9387	dec SleepTimeH,x
$CC1C			DE7F87	dec SleepTimeL,x
$CC1F			CA	dex
$CC20			10ED	bpl $CC0F
$CC22			60	rts

$CC23			AE7E87	ldx MaxSleep			;ExecSleepJob
$CC26			F020	beq $CC48
$CC28			CA	dex
$CC29			BD7F87	lda SleepTimeL,x
$CC2C			1D9387	ora SleepTimeH,x
$CC2F			D014	bne $CC45
$CC31			BDBB87	lda SleepRoutH,x
$CC34			8503	sta r0H
$CC36			BDA787	lda SleepRoutL,x
$CC39			8502	sta r0L
$CC3B			8A	txa
$CC3C			48	pha
$CC3D			2052CC	jsr Del1stSleepJob
$CC40			2049CC	jsr DoSleepJob
$CC43			68	pla
$CC44			AA	tax
$CC45			CA	dex
$CC46			10E1	bpl $CC29
$CC48			60	rts

$CC49			E602	inc r0L			;DoSleepJob
$CC4B			D002	bne $CC4F
$CC4D			E603	inc r0H
$CC4F			6C0200	jmp (r0)

$CC52			08	php 			;Del1stSleepJob
$CC53			78	sei
$CC54			E8	inx
$CC55			EC7E87	cpx MaxSleep
$CC58			F01B	beq $CC75
$CC5A			BD7F87	lda SleepTimeL  ,x
$CC5D			9D7E87	sta SleepTimeL-1,x
$CC60			BD9387	lda SleepTimeH  ,x
$CC63			9D9287	sta SleepTimeH-1,x
$CC66			BDA787	lda SleepRoutL  ,x
$CC69			9DA687	sta SleepRoutL-1,x
$CC6C			BDBB87	lda SleepRoutH  ,x
$CC6F			9DBA87	sta SleepRoutH-1,x
$CC72			B8	clv
$CC73			50DF	bvc $CC54

$CC75			CE7E87	dec MaxSleep
$CC78			28	plp
$CC79			60	rts

$CC7A			08	php 			;xSleep
$CC7B			68	pla
$CC7C			A8	tay
$CC7D			78	sei
$CC7E			AE7E87	ldx MaxSleep
$CC81			A502	lda r0L
$CC83			9D7F87	sta SleepTimeL,x
$CC86			A503	lda r0H
$CC88			9D9387	sta SleepTimeH,x
$CC8B			68	pla
$CC8C			9DA787	sta SleepRoutL,x
$CC8F			68	pla
$CC90			9DBB87	sta SleepRoutH,x
$CC93			EE7E87	inc MaxSleep
$CC96			98	tya
$CC97			48	pha
$CC98			28	plp
$CC99			60	rts

$CC9A			A408	ldy r3L			;xDrawSprite
$CC9C			B9B0CC	lda sprPicAdrL,y
$CC9F			850C	sta r5L
$CCA1			B9B8CC	lda sprPicAdrH,y
$CCA4			850D	sta r5H
$CCA6			A03F	ldy #$3F
$CCA8			B10A	lda (r4L),y
$CCAA			910C	sta (r5L),y
$CCAC			88	dey
$CCAD			10F9	bpl $CCA8
$CCAF			60	rts

$CCB0			00	b < spr0pic			;sprPicAdrL
$CCB1			40	b < spr1pic
$CCB2			80	b < spr2pic
$CCB3			C0	b < spr3pic
$CCB4			00	b < spr4pic
$CCB5			40	b < spr5pic
$CCB6			80	b < spr6pic
$CCB7			C0	b < spr7pic

$CCB8			8A	b > spr0pic			;sprPicAdrL
$CCB9			8A	b > spr1pic
$CCBA			8A	b > spr2pic
$CCBB			8A	b > spr3pic
$CCBC			8B	b > spr4pic
$CCBD			8B	b > spr5pic
$CCBE			8B	b > spr6pic
$CCBF			8B	b > spr7pic

$CCC0			A501	lda CPU_DATA			;xPosSprite
$CCC2			48	pha

$CCC3			A935	lda #$35
$CCC5			8501	sta CPU_DATA

$CCC7			A508	lda r3L
$CCC9			0A	asl
$CCCA			A8	tay
$CCCB			A50C	lda r5L

$CCCD			18	clc
$CCCE			6932	adc #$32
$CCD0			9901D0	sta mob0ypos,y
$CCD3			A50A	lda r4L
$CCD5			18	clc
$CCD6			6918	adc #$18
$CCD8			850E	sta r6L
$CCDA			A50B	lda r4H
$CCDC			6900	adc #$00
$CCDE			850F	sta r6H

$CCE0			A50E	lda r6L
$CCE2			9900D0	sta mob0xpos,y

$CCE5			A608	ldx r3L
$CCE7			BDEDC2	lda BitData2,x
$CCEA			49FF	eor #%11111111
$CCEC			2D10D0	and msbxpos
$CCEF			A8	tay
$CCF0			A901	lda #$01
$CCF2			250F	and r6H
$CCF4			F005	beq $CCFB
$CCF6			98	tya
$CCF7			1DEDC2	ora BitData2,x
$CCFA			A8	tay
$CCFB			8C10D0	sty msbxpos

$CCFE			68	pla
$CCFF			8501	sta CPU_DATA
$CD01			60	rts

$CD02			A608	ldx r3L			;xEnablSprite
$CD04			BDEDC2	lda BitData2,x
$CD07			AA	tax
$CD08			A501	lda CPU_DATA
$CD0A			48	pha
$CD0B			A935	lda #$35
$CD0D			8501	sta CPU_DATA
$CD0F			8A	txa
$CD10			0D15D0	ora mobenble
$CD13			8D15D0	sta mobenble
$CD16			68	pla
$CD17			8501	sta CPU_DATA
$CD19			60	rts

$CD1A			A608	ldx r3L			;xDisablSprite
$CD1C			BDEDC2	lda BitData2,x
$CD1F			49FF	eor #%11111111
$CD21			48	pha
$CD22			A601	ldx CPU_DATA
$CD24			A935	lda #$35
$CD26			8501	sta CPU_DATA
$CD28			68	pla
$CD29			2D15D0	and mobenble
$CD2C			8D15D0	sta mobenble
$CD2F			8601	stx CPU_DATA
$CD31			60	rts

$CD32			88	dey 			;xDShiftLeft
$CD33			3007	bmi $CD3C
$CD35			1600	asl zPage+0,x
$CD37			3601	rol zPage+1,x
$CD39			4C32CD	jmp xDShiftLeft
$CD3C			60	rts

$CD3D			88	dey 			;xDShiftRight
$CD3E			3007	bmi $CD47
$CD40			5601	lsr zPage+1,x
$CD42			7600	ror zPage+0,x
$CD44			4C3DCD	jmp xDShiftRight
$CD47			60	rts

$CD48			B90000	lda zPage,y			;xBBMult
$CD4B			8513	sta r8H
$CD4D			8412	sty r8L
$CD4F			A008	ldy #$08
$CD51			A900	lda #$00
$CD53			4613	lsr r8H
$CD55			9003	bcc $CD5A
$CD57			18	clc
$CD58			7500	adc zPage+0,x
$CD5A			6A	ror
$CD5B			6610	ror r7L
$CD5D			88	dey
$CD5E			D0F3	bne $CD53
$CD60			9501	sta zPage+1,x
$CD62			A510	lda r7L
$CD64			9500	sta zPage+0,x
$CD66			A412	ldy r8L
$CD68			60	rts

$CD69			A900	lda #$00			;xBMult
$CD6B			990100	sta zPage+1,y

$CD6E			A910	lda #$10			;xDMult
$CD70			8512	sta r8L
$CD72			A900	lda #$00
$CD74			8510	sta r7L
$CD76			8511	sta r7H
$CD78			5601	lsr zPage+1,x
$CD7A			7600	ror zPage+0,x
$CD7C			900D	bcc $CD8B
$CD7E			A510	lda r7L
$CD80			18	clc
$CD81			790000	adc zPage+0,y
$CD84			8510	sta r7L
$CD86			A511	lda r7H
$CD88			790100	adc zPage+1,y
$CD8B			4A	lsr
$CD8C			8511	sta r7H
$CD8E			6610	ror r7L
$CD90			660F	ror r6H
$CD92			660E	ror r6L
$CD94			C612	dec r8L
$CD96			D0E0	bne $CD78
$CD98			A50E	lda r6L
$CD9A			9500	sta zPage+0,x
$CD9C			A50F	lda r6H
$CD9E			9501	sta zPage+1,x
$CDA0			60	rts

$CDA1			A900	lda #$00			;xDdiv
$CDA3			8512	sta r8L
$CDA5			8513	sta r8H
$CDA7			A910	lda #$10
$CDA9			8514	sta r9L
$CDAB			1600	asl zPage+0,x
$CDAD			3601	rol zPage+1,x
$CDAF			2612	rol r8L
$CDB1			2613	rol r8H
$CDB3			A512	lda r8L
$CDB5			38	sec
$CDB6			F90000	sbc zPage+0,y
$CDB9			8515	sta r9H
$CDBB			A513	lda r8H
$CDBD			F90100	sbc zPage+1,y
$CDC0			9008	bcc $CDCA
$CDC2			F600	inc zPage+0,x
$CDC4			8513	sta r8H
$CDC6			A515	lda r9H
$CDC8			8512	sta r8L
$CDCA			C614	dec r9L
$CDCC			D0DD	bne $CDAB
$CDCE			60	rts

$CDCF			B501	lda zPage+1,x			;xDSdiv
$CDD1			590100	eor zPage+1,y
$CDD4			08	php
$CDD5			20EBCD	jsr xDabs
$CDD8			8612	stx r8L
$CDDA			98	tya
$CDDB			AA	tax
$CDDC			20EBCD	jsr xDabs
$CDDF			A612	ldx r8L
$CDE1			20A1CD	jsr xDdiv
$CDE4			28	plp
$CDE5			1003	bpl $CDEA
$CDE7			20F0CD	jsr xDnegate
$CDEA			60	rts

$CDEB			B501	lda zPage+1,x			;xDabs
$CDED			3001	bmi xDnegate
$CDEF			60	rts

$CDF0			B501	lda zPage+1,x			;xDnegate
$CDF2			49FF	eor #%11111111
$CDF4			9501	sta zPage+1,x
$CDF6			B500	lda zPage+0,x
$CDF8			49FF	eor #%11111111
$CDFA			9500	sta zPage+0,x
$CDFC			F600	inc zPage+0,x
$CDFE			D002	bne $CE02
$CE00			F601	inc zPage+1,x
$CE02			60	rts

$CE03			B500	lda zPage+0,x			;xDdec
$CE05			D002	bne $CE09
$CE07			D601	dec zPage+1,x
$CE09			D600	dec zPage+0,x
$CE0B			B500	lda zPage+0,x
$CE0D			1501	ora zPage+1,x
$CE0F			60	rts

$CE10			EE0A85	inc random+0			;xGetRandom
$CE13			D003	bne $CE18
$CE15			EE0B85	inc random+1
$CE18			0E0A85	asl random+0
$CE1B			2E0B85	rol random+1
$CE1E			900F	bcc $CE2F
$CE20			18	clc
$CE21			A90F	lda #$0F
$CE23			6D0A85	adc random+0
$CE26			8D0A85	sta random+0
$CE29			9003	bcc $CE2E
$CE2B			EE0B85	inc random+1
$CE2E			60	rts

$CE2F			AD0B85	lda random+1
$CE32			C9FF	cmp #$FF
$CE34			9010	bcc $CE46
$CE36			AD0A85	lda random+0
$CE39			38	sec
$CE3A			E9F1	sbc #$F1
$CE3C			9008	bcc $CE46
$CE3E			8D0A85	sta random+0
$CE41			A900	lda #$00
$CE43			8D0B85	sta random+1
$CE46			60	rts

$CE48			A900	lda #$00			;xCopyString
$CE4A			8E53CE	stx $CE53			;xCopyFString
$CE4C			8C55CE	sty $CE55
$CE4F			AA	tax
$CE50			A000	ldy #$00
$CE52			B10A	lda (r4L),y
$CE54			910C	sta (r5L),y
$CE56			D003	bne $CE5B
$CE58			8A	txa
$CE59			F009	beq $CE64
$CE5B			C8	iny
$CE5C			F006	beq $CE64
$CE5E			8A	txa
$CE5F			F0F1	beq $CE52
$CE61			CA	dex
$CE62			D0EE	bne $CE52
$CE64			60	rts

$CE65			68	pla 			;xi_MoveData
$CE66			853D	sta returnAddress
$CE68			68	pla
$CE69			853E	sta returnAddress+1
$CE6B			207CCE	jsr Get2Word1Byte
$CE6E			C8	iny
$CE6F			B13D	lda (returnAddress),y
$CE71			8507	sta r2H
$CE73			2097CE	jsr xMoveData
$CE76			08	php
$CE77			A907	lda #$07
$CE79			4CA4C2	jmp DoInlineReturn

$CE7C			A001	ldy #$01			;Get2Word1Byte
$CE7E			B13D	lda (returnAddress),y
$CE80			8502	sta r0L
$CE82			C8	iny
$CE83			B13D	lda (returnAddress),y
$CE85			8503	sta r0H
$CE87			C8	iny
$CE88			B13D	lda (returnAddress),y
$CE8A			8504	sta r1L
$CE8C			C8	iny
$CE8D			B13D	lda (returnAddress),y
$CE8F			8505	sta r1H
$CE91			C8	iny
$CE92			B13D	lda (returnAddress),y
$CE94			8506	sta r2L
$CE96			60	rts

$CE97			A506	lda r2L			;xMoveData
$CE99			0507	ora r2H
$CE9B			F06B	beq $CF08

$CE9D			A503	lda r0H
$CE9F			48	pha
$CEA0			A502	lda r0L
$CEA2			48	pha
$CEA3			A505	lda r1H
$CEA5			48	pha
$CEA6			A507	lda r2H
$CEA8			48	pha
$CEA9			A508	lda r3L
$CEAB			48	pha

$CEAC			ADC488	lda sysRAMFlg
$CEAF			1019	bpl $CECA

$CEB1			A505	lda r1H
$CEB3			48	pha
$CEB4			A900	lda #$00
$CEB6			8505	sta r1H
$CEB8			8508	sta r3L
$CEBA			20C8C2	jsr StashRAM
$CEBD			68	pla
$CEBE			8503	sta r0H
$CEC0			A504	lda r1L
$CEC2			8502	sta r0L
$CEC4			20CBC2	jsr FetchRAM
$CEC7			B8	clv
$CEC8			502F	bvc $CEF9

$CECA			A503	lda r0H
$CECC			C505	cmp r1H
$CECE			D004	bne $CED4
$CED0			A502	lda r0L
$CED2			C504	cmp r1L
$CED4			B002	bcs $CED8
$CED6			9031	bcc $CF09

$CED8			A000	ldy #$00
$CEDA			A507	lda r2H
$CEDC			F00F	beq $CEED
$CEDE			B102	lda (r0L),y
$CEE0			9104	sta (r1L),y
$CEE2			C8	iny
$CEE3			D0F9	bne $CEDE
$CEE5			E603	inc r0H
$CEE7			E605	inc r1H
$CEE9			C607	dec r2H
$CEEB			D0F1	bne $CEDE
$CEED			C406	cpy r2L
$CEEF			F008	beq $CEF9
$CEF1			B102	lda (r0L),y
$CEF3			9104	sta (r1L),y
$CEF5			C8	iny
$CEF6			B8	clv
$CEF7			50F4	bvc $CEED

$CEF9			68	pla
$CEFA			8508	sta r3L
$CEFC			68	pla
$CEFD			8507	sta r2H
$CEFF			68	pla
$CF00			8505	sta r1H
$CF02			68	pla
$CF03			8502	sta r0L
$CF05			68	pla
$CF06			8503	sta r0H
$CF08			60	rts

$CF09			18	clc
$CF0A			A507	lda r2H
$CF0C			6503	adc r0H
$CF0E			8503	sta r0H
$CF10			18	clc
$CF11			A507	lda r2H
$CF13			6505	adc r1H
$CF15			8505	sta r1H
$CF17			A406	ldy r2L
$CF19			F008	beq $CF23
$CF1B			88	dey
$CF1C			B102	lda (r0L),y
$CF1E			9104	sta (r1L),y
$CF20			98	tya
$CF21			D0F8	bne $CF1B
$CF23			C603	dec r0H
$CF25			C605	dec r1H
$CF27			A507	lda r2H
$CF29			F0CE	beq $CEF9
$CF2B			88	dey
$CF2C			B102	lda (r0L),y
$CF2E			9104	sta (r1L),y
$CF30			98	tya
$CF31			D0F8	bne $CF2B
$CF33			C607	dec r2H
$CF35			B8	clv
$CF36			50EB	bvc $CF23

$CF38			A900	lda #$00			;xCmpString
$CF3A			8E44CF	stx $CF44			;xCmpFString
$CF3D			8C46CF	sty $CF46
$CF40			AA	tax
$CF41			A000	ldy #$00
$CF43			B10C	lda (r5L),y
$CF45			D104	cmp (r1L),y
$CF47			D012	bne $CF5B
$CF49			C900	cmp #$00
$CF4B			D003	bne $CF50
$CF4D			8A	txa
$CF4E			F00B	beq $CF5B
$CF50			C8	iny
$CF51			F008	beq $CF5B
$CF53			8A	txa
$CF54			F0ED	beq $CF43
$CF56			CA	dex
$CF57			D0EA	bne $CF43
$CF59			A900	lda #$00
$CF5B			60	rts

$CF5C			A53C	lda mouseYPos			;xIsMseInRegion
$CF5E			C506	cmp r2L
$CF60			9023	bcc $CF85
$CF62			C507	cmp r2H
$CF64			F002	beq $CF68
$CF66			B01D	bcs $CF85
$CF68			A53B	lda mouseXPos+1
$CF6A			C509	cmp r3H
$CF6C			D004	bne $CF72
$CF6E			A53A	lda mouseXPos
$CF70			C508	cmp r3L
$CF72			9011	bcc $CF85
$CF74			A53B	lda mouseXPos+1
$CF76			C50B	cmp r4H
$CF78			D004	bne $CF7E
$CF7A			A53A	lda mouseXPos
$CF7C			C50A	cmp r4L
$CF7E			F002	beq $CF82
$CF80			B003	bcs $CF85
$CF82			A9FF	lda #$FF
$CF84			60	rts
$CF85			A900	lda #$00
$CF87			60	rts

$CF88			68	pla 			;xPanic
$CF89			8502	sta r0L
$CF8B			68	pla
$CF8C			8503	sta r0H

$CF8E			38	sec
$CF8F			A502	lda r0L
$CF91			E902	sbc #$02
$CF93			8502	sta r0L
$CF95			A503	lda r0H
$CF97			E900	sbc #$00
$CF99			8503	sta r0H

$CF9B			A503	lda r0H
$CF9D			A200	ldx #$00
$CF9F			20B2CF	jsr ConvHexToASCII

$CFA2			A502	lda r0L
$CFA4			20B2CF	jsr ConvHexToASCII

$CFA7			A9CF	lda #>PanicBox
$CFA9			8503	sta r0H
$CFAB			A9D3	lda #<PanicBox
$CFAD			8502	sta r0L
$CFAF			2056C2	jsr DoDlgBox

$CFB2			48	pha 			;ConvHexToASCII
$CFB3			4A	lsr
$CFB4			4A	lsr
$CFB5			4A	lsr
$CFB6			4A	lsr
$CFB7			20C3CF	jsr ConvHexNibble
$CFBA			E8	inx
$CFBB			68	pla
$CFBC			290F	and #%00001111
$CFBE			20C3CF	jsr ConvHexNibble
$CFC1			E8	inx
$CFC2			60	rts

$CFC3			C90A	cmp #$0A			;ConvHexNibble
$CFC5			B005	bcs $CFCC
$CFC7			18	clc
$CFC8			6930	adc #$30
$CFCA			D003	bne $CFCF
$CFCC			18	clc
$CFCD			6937	adc #$37
$CFCF			9DEECF	sta PanicAddress,x
$CFD2			60	rts

$CFD3			81	b $81			;PanicBox
$CFD4			0B1010	b $0B,$10,$10
$CFD7			DACF	w $CFDA
$CFD9			00	b $00

$CFDA			18	b $18
$CFDB			53797374b "Syst"
$CFDF			656D6665b "emfe"
$CFE3			686C6572b "hler"
$CFE7			206E6168b " nah"
$CFEB			652024	b "e $"

$CFEE			78	b "xxxx"			;PanicAddress
$CFF2			00	b $00

$CFF3			ADA79E	lda SerialNumber+0			;xGetSerialNumber
$CFF6			8502	sta r0L
$CFF8			ADA89E	lda SerialNumber+1			;GetSerHByte
$CFFB			8503	sta r0H
$CFFD			60	rts

$CFFE			0160	b $01,$60

;*** GEOS-Füllpatterns.
$D000			b %00000000
$D001			b %00000000
$D002			b %00000000
$D003			b %00000000
$D004			b %00000000
$D005			b %00000000
$D006			b %00000000
$D007			b %00000000

$D008			b %11111111
$D009			b %11111111
$D00A			b %11111111
$D00B			b %11111111
$D00C			b %11111111
$D00D			b %11111111
$D00E			b %11111111
$D00F			b %11111111

$D010			b %10101010
$D011			b %01010101
$D012			b %10101010
$D013			b %01010101
$D014			b %10101010
$D015			b %01010101
$D016			b %10101010
$D017			b %01010101

$D018			b %10011001
$D019			b %01000010
$D01A			b %00100100
$D01B			b %10011001
$D01C			b %10011001
$D01D			b %00100100
$D01E			b %01000010
$D01F			b %10011001

$D020			b %11111011
$D021			b %11110101
$D022			b %11111011
$D023			b %11110101
$D024			b %11111011
$D025			b %11110101
$D026			b %11111011
$D027			b %11110101

$D028			b %10001000
$D029			b %00100010
$D02A			b %10001000
$D02B			b %00100010
$D02C			b %10001000
$D02D			b %00100010
$D02E			b %10001000
$D02F			b %00100010

$D030			b %01110111
$D031			b %11011101
$D032			b %01110111
$D033			b %11011101
$D034			b %01110111
$D035			b %11011101
$D036			b %01110111
$D037			b %11011101

$D038			b %10001000
$D039			b %00000000
$D03A			b %00100010
$D03B			b %00000000
$D03C			b %10001000
$D03D			b %00000000
$D03E			b %00100010
$D03F			b %00000000

$D040			b %01110111
$D041			b %11111111
$D042			b %11011101
$D043			b %11111111
$D044			b %01110111
$D045			b %11111111
$D046			b %11011101
$D047			b %11111111

$D048			b %11111111
$D049			b %00000000
$D04A			b %11111111
$D04B			b %00000000
$D04C			b %11111111
$D04D			b %00000000
$D04E			b %11111111
$D04F			b %00000000

;*** GEOS-Füllpatterns.
$D050			b %01010101
$D051			b %01010101
$D052			b %01010101
$D053			b %01010101
$D054			b %01010101
$D055			b %01010101
$D056			b %01010101
$D057			b %01010101

$D058			b %00000001
$D059			b %00000010
$D05A			b %00000100
$D05B			b %00001000
$D05C			b %00010000
$D05D			b %00100000
$D05E			b %01000000
$D05F			b %10000000

$D060			b %10000000
$D061			b %01000000
$D062			b %00100000
$D063			b %00010000
$D064			b %00001000
$D065			b %00000100
$D066			b %00000010
$D067			b %00000001

$D068			b %11111110
$D069			b %11111101
$D06A			b %11111011
$D06B			b %11110111
$D06C			b %11101111
$D06D			b %11011111
$D06E			b %10111111
$D06F			b %01111111

$D070			b %01111111
$D071			b %10111111
$D072			b %11011111
$D073			b %11101111
$D074			b %11110111
$D075			b %11111011
$D076			b %11111101
$D077			b %11111110

$D078			b %11111111
$D079			b %10001000
$D07A			b %10001000
$D07B			b %10001000
$D07C			b %11111111
$D07D			b %10001000
$D07E			b %10001000
$D07F			b %10001000

$D080			b %11111111
$D081			b %10000000
$D082			b %10000000
$D083			b %10000000
$D084			b %10000000
$D085			b %10000000
$D086			b %10000000
$D087			b %10000000

$D088			b %11111111
$D089			b %10000000
$D08A			b %10000000
$D08B			b %10000000
$D08C			b %11111111
$D08D			b %00001000
$D08E			b %00001000
$D08F			b %00001000

$D090			b %00001000
$D091			b %00011100
$D092			b %00100010
$D093			b %11000001
$D094			b %10000000
$D095			b %00000001
$D096			b %00000010
$D097			b %00000100

$D098			b %10001000
$D099			b %00010100
$D09A			b %00100010
$D09B			b %01000001
$D09C			b %10001000
$D09D			b %00000000
$D09E			b %10101010
$D09F			b %00000000

;*** GEOS-Füllpatterns.
$D0A0			b %10000000
$D0A1			b %01000000
$D0A2			b %00100000
$D0A3			b %00000000
$D0A4			b %00000010
$D0A5			b %00000100
$D0A6			b %00001000
$D0A7			b %00000000

$D0A8			b %01000000
$D0A9			b %10100000
$D0AA			b %00000000
$D0AB			b %00000000
$D0AC			b %00000100
$D0AD			b %00001010
$D0AE			b %00000000
$D0AF			b %00000000

$D0B0			b %10000010
$D0B1			b %01000100
$D0B2			b %00111001
$D0B3			b %01000100
$D0B4			b %10000010
$D0B5			b %00000001
$D0B6			b %00000001
$D0B7			b %00000001

$D0B8			b %00000011
$D0B9			b %10000100
$D0BA			b %01001000
$D0BB			b %00110000
$D0BC			b %00001100
$D0BD			b %00000010
$D0BE			b %00000001
$D0BF			b %00000001

$D0C0			b %11111000
$D0C1			b %01110100
$D0C2			b %00100010
$D0C3			b %01000111
$D0C4			b %10001111
$D0C5			b %00010111
$D0C6			b %00100010
$D0C7			b %01110001

$D0C8			b %10000000
$D0C9			b %10000000
$D0CA			b %01000001
$D0CB			b %00111110
$D0CC			b %00001000
$D0CD			b %00001000
$D0CE			b %00010100
$D0CF			b %11100011

$D0D0			b %01010101
$D0D1			b %10100000
$D0D2			b %01000000
$D0D3			b %01000000
$D0D4			b %01010101
$D0D5			b %00001010
$D0D6			b %00000100
$D0D7			b %00000100

$D0D8			b %00010000
$D0D9			b %00100000
$D0DA			b %01010100
$D0DB			b %10101010
$D0DC			b %11111111
$D0DD			b %00000010
$D0DE			b %00000100
$D0DF			b %00001000

$D0E0			b %00100000
$D0E1			b %01010000
$D0E2			b %10001000
$D0E3			b %10001000
$D0E4			b %10001000
$D0E5			b %10001000
$D0E6			b %00000101
$D0E7			b %00000010

$D0E8			b %01110111
$D0E9			b %10001001
$D0EA			b %10001111
$D0EB			b %10001111
$D0EC			b %01110111
$D0ED			b %10011000
$D0EE			b %11111000
$D0EF			b %11111000

;*** GEOS-Füllpatterns.
$D0F0			b %10111111
$D0F1			b %00000000
$D0F2			b %10111111
$D0F3			b %10111111
$D0F4			b %10110000
$D0F5			b %10110000
$D0F6			b %10110000
$D0F7			b %10110000

$D0F8			b %00000000
$D0F9			b %00001000
$D0FA			b %00010100
$D0FB			b %00101010
$D0FC			b %01010101
$D0FD			b %00101010
$D0FE			b %00010100
$D0FF			b %00001000

$D100			b %10110001
$D101			b %00110000
$D102			b %00000011
$D103			b %00011011
$D104			b %11011000
$D105			b %11000000
$D106			b %00001100
$D107			b %10001101

$D108			b %10000000
$D109			b %00010000
$D10A			b %00000010
$D10B			b %00100000
$D10C			b %00000001
$D10D			b %00001000
$D10E			b %01000000
$D10F			b %00000100

;*** Tabelle zum berechnen der Daten
;    für Buchstaben in Fettschrift!
;    Jedes Byte in PLAINTEXT wird durch
;    ein Byte in BOLD ersetzt. Dabei
;    dient das PLAINTEXT-Byte als
;    Zeiger auf die BoldData-Tabelle.
;    Bsp: %00010000 wird zu %00011000
$D110			b $00,$01,$03,$03,$06,$07,$07,$07
$D118			b $0c,$0d,$0f,$0f,$0e,$0f,$0f,$0f
$D120			b $18,$19,$1b,$1b,$1e,$1f,$1f,$1f
$D128			b $1c,$1d,$1f,$1f,$1e,$1f,$1f,$1f
$D130			b $30,$31,$33,$33,$36,$37,$37,$37
$D138			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
$D140			b $38,$39,$3b,$3b,$3e,$3f,$3f,$3f
$D148			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
$D150			b $60,$61,$63,$63,$66,$67,$67,$67
$D158			b $6c,$6d,$6f,$6f,$6e,$6f,$6f,$6f
$D160			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
$D168			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
$D170			b $70,$71,$73,$73,$76,$77,$77,$77
$D178			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
$D180			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
$D188			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
$D190			b $c0,$c1,$c3,$c3,$c6,$c7,$c7,$c7
$D198			b $cc,$cd,$cf,$cf,$ce,$cf,$cf,$cf
$D1A0			b $d8,$d9,$db,$db,$de,$df,$df,$df
$D1A8			b $dc,$dd,$df,$df,$de,$df,$df,$df
$D1B0			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
$D1B8			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
$D1C0			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
$D1C8			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
$D1D0			b $e0,$e1,$e3,$e3,$e6,$e7,$e7,$e7
$D1D8			b $ec,$ed,$ef,$ef,$ee,$ef,$ef,$ef
$D1E0			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
$D1E8			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
$D1F0			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
$D1F8			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
$D200			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
$D208			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff

;*** GEOS-Font in Quellcode einbinden.
:BSW_Font		v 9,"GEOS BSW/Font"

$D500			68	pla 			;xi_FillRam
$D502			853D	sta returnAddress
$D504			68	pla
$D505			853E	sta returnAddress+1
$D507			207CCE	jsr Get2Word1Byte
$D50A			2045C5	jsr xFillRam
$D50D			08	php
$D50E			A906	lda #$06
$D510			4CA4C2	jmp DoInlineReturn

$D513			20F8C5	jsr SaveFileData			;xGetFile

$D516			200BC2	jsr FindFile
$D519			8A	txa
$D51A			D066	bne NoFunc1

$D51C			20CFC5	jsr LoadFileData

$D51F			A984	lda #>dirEntryBuf
$D521			8515	sta r9H
$D523			A900	lda #<dirEntryBuf
$D525			8514	sta r9L

$D527			AD1684	lda dirEntryBuf+$16
$D52A			C905	cmp #$05
$D52C			D003	bne $D531
$D52E			4C17C2	jmp LdDeskAcc

$D531			C906	cmp #$06
$D533			F004	beq $D539
$D535			C90E	cmp #$0E
$D537			D003	bne xLdFile
$D539			4C1DC2	jmp LdApplic

$D53C			2029C2	jsr GetFHdrInfo			;xLdFile
$D53F			8A	txa
$D540			D040	bne NoFunc1

$D542			AD4681	lda fileHeader+$46
$D545			C901	cmp #$01
$D547			D01F	bne $D568

$D549			A001	ldy #$01
$D54B			B114	lda (r9L),y
$D54D			8504	sta r1L
$D54F			C8	iny
$D550			B114	lda (r9L),y
$D552			8505	sta r1H
$D554			203C90	jsr D_ReadSektor
$D557			8A	txa
$D558			D028	bne NoFunc1

$D55A			A208	ldx #$08
$D55C			AD0280	lda diskBlkBuf+$02
$D55F			8504	sta r1L
$D561			F01F	beq NoFunc1
$D563			AD0380	lda diskBlkBuf+$03
$D566			8505	sta r1H

$D568			AD5E88	lda LoadFileMode
$D56B			2901	and #%00000001
$D56D			F00A	beq $D579

$D56F			AD6088	lda LoadBufAdr+1
$D572			8511	sta r7H
$D574			AD5F88	lda LoadBufAdr+0
$D577			8510	sta r7L

$D579			A9FF	lda #$FF
$D57B			8506	sta r2L
$D57D			8507	sta r2H
$D57F			20FFC1	jsr ReadFile
$D582			60	rts 			;NoFunc1	

$D583			08	php 			;xFollowChain
$D584			78	sei

$D585			A509	lda r3H
$D587			48	pha

$D588			A000	ldy #$00
$D58A			A504	lda r1L
$D58C			9108	sta (r3L),y
$D58E			C8	iny
$D58F			A505	lda r1H
$D591			9108	sta (r3L),y
$D593			C8	iny
$D594			D002	bne $D598
$D596			E609	inc r3H

$D598			A504	lda r1L
$D59A			F017	beq $D5B3
$D59C			98	tya
$D59D			48	pha
$D59E			203C90	jsr D_ReadSektor
$D5A1			68	pla
$D5A2			A8	tay
$D5A3			8A	txa
$D5A4			D00F	bne $D5B5

$D5A6			AD0180	lda diskBlkBuf+$01
$D5A9			8505	sta r1H
$D5AB			AD0080	lda diskBlkBuf
$D5AE			8504	sta r1L
$D5B0			B8	clv
$D5B1			50D7	bvc $D58A

$D5B3			A200	ldx #$00
$D5B5			68	pla
$D5B6			8509	sta r3H
$D5B8			28	plp
$D5B9			60	rts

$D5BA			08	php 			;xFindFTypes
$D5BB			78	sei

$D5BC			A50F	lda r6H
$D5BE			8505	sta r1H
$D5C0			A50E	lda r6L
$D5C2			8504	sta r1L

$D5C4			A900	lda #$00
$D5C6			8503	sta r0H

$D5C8			A511	lda r7H
$D5CA			0A	asl
$D5CB			2603	rol r0H
$D5CD			0A	asl
$D5CE			2603	rol r0H
$D5D0			0A	asl
$D5D1			2603	rol r0H
$D5D3			0A	asl
$D5D4			2603	rol r0H
$D5D6			6511	adc r7H
$D5D8			8502	sta r0L
$D5DA			9002	bcc $D5DE
$D5DC			E603	inc r0H
$D5DE			2078C1	jsr ClearRam

$D5E1			38	sec
$D5E2			A50E	lda r6L
$D5E4			E903	sbc #$03
$D5E6			850E	sta r6L
$D5E8			A50F	lda r6H
$D5EA			E900	sbc #$00
$D5EC			850F	sta r6H

$D5EE			203090	jsr Get1stDirEntry
$D5F1			8A	txa
$D5F2			D053	bne $D647

$D5F4			A2C1	ldx #>GetSerialNumber
$D5F6			A996	lda #<GetSerialNumber
$D5F8			20D8C1	jsr CallRoutine

$D5FB			A503	lda r0H
$D5FD			CD38D8	cmp SerNoHByte
$D600			F003	beq $D605
$D602			EE18C2	inc $C218

$D605			A000	ldy #$00
$D607			B10C	lda (r5L),y
$D609			F033	beq $D63E

$D60B			A016	ldy #$16
$D60D			B10C	lda (r5L),y
$D60F			C510	cmp r7L
$D611			D02B	bne $D63E

$D613			2050D7	jsr CheckFileClass
$D616			8A	txa
$D617			D02E	bne $D647

$D619			98	tya
$D61A			D022	bne $D63E

$D61C			A003	ldy #$03
$D61E			B10C	lda (r5L),y
$D620			C9A0	cmp #$A0
$D622			F007	beq $D62B
$D624			910E	sta (r6L),y
$D626			C8	iny
$D627			C013	cpy #$13
$D629			D0F3	bne $D61E

$D62B			A900	lda #$00
$D62D			910E	sta (r6L),y
$D62F			18	clc
$D630			A911	lda #$11
$D632			650E	adc r6L
$D634			850E	sta r6L
$D636			9002	bcc $D63A
$D638			E60F	inc r6H

$D63A			C611	dec r7H
$D63C			F009	beq $D647

$D63E			203390	jsr GetNxtDirEntry
$D641			8A	txa
$D642			D003	bne $D647
$D644			98	tya
$D645			F0BE	beq $D605
$D647			28	plp
$D648			60	rts

$D649			A983	lda #>fileTrScTab			;VEC_fileTrScTab
$D64B			850F	sta r6H
$D64D			A900	lda #<fileTrScTab
$D64F			850E	sta r6L
$D651			60	rts

$D652			AD4881	lda fileHeader+$48			;GetLoadAdr
$D655			8511	sta r7H
$D657			AD4781	lda fileHeader+$47
$D65A			8510	sta r7L
$D65C			60	rts

$D65D			A981	lda #>fileHeader			;Vec_fileHeader
$D65F			850B	sta r4H
$D661			A900	lda #<fileHeader
$D663			850A	sta r4L
$D665			60	rts

$D666			08	php 			;xFindFile
$D667			78	sei
$D668			38	sec
$D669			A50E	lda r6L
$D66B			E903	sbc #$03
$D66D			850E	sta r6L
$D66F			A50F	lda r6H
$D671			E900	sbc #$00
$D673			850F	sta r6H

$D675			203090	jsr Get1stDirEntry
$D678			8A	txa
$D679			D039	bne $D6B4

$D67B			A000	ldy #$00
$D67D			B10C	lda (r5L),y
$D67F			F018	beq $D699
$D681			A003	ldy #$03
$D683			B10E	lda (r6L),y
$D685			F007	beq $D68E
$D687			D10C	cmp (r5L),y
$D689			D00E	bne $D699
$D68B			C8	iny
$D68C			D0F5	bne $D683
$D68E			C013	cpy #$13
$D690			F014	beq $D6A6
$D692			B10C	lda (r5L),y
$D694			C8	iny
$D695			C9A0	cmp #$A0
$D697			F0F5	beq $D68E

$D699			203390	jsr GetNxtDirEntry
$D69C			8A	txa
$D69D			D015	bne $D6B4
$D69F			98	tya
$D6A0			F0D9	beq $D67B
$D6A2			A205	ldx #$05
$D6A4			D00E	bne $D6B4

$D6A6			A000	ldy #$00
$D6A8			B10C	lda (r5L),y
$D6AA			990084	sta dirEntryBuf,y
$D6AD			C8	iny
$D6AE			C01E	cpy #$1E
$D6B0			D0F6	bne $D6A8
$D6B2			A200	ldx #$00
$D6B4			28	plp
$D6B5			60	rts

$D6B6			EA	nop 			;xSetDevice
$D6B7			C5BA	cmp curDevice
$D6B9			F011	beq $D6CC
$D6BB			48	pha
$D6BC			A5BA	lda curDevice
$D6BE			C908	cmp #$08
$D6C0			9007	bcc $D6C9
$D6C2			C90C	cmp #$0C
$D6C4			B003	bcs $D6C9
$D6C6			2032C2	jsr ExitTurbo

$D6C9			68	pla
$D6CA			85BA	sta curDevice

$D6CC			C908	cmp #$08
$D6CE			902D	bcc $D6FD
$D6D0			C90C	cmp #$0C
$D6D2			B029	bcs $D6FD
$D6D4			A8	tay
$D6D5			B98684	lda driveType -8,y
$D6D8			8DC688	sta curType
$D6DB			CC8984	cpy curDrive
$D6DE			F01D	beq $D6FD
$D6E0			8C8984	sty curDrive
$D6E3			2CC488	bit sysRAMFlg
$D6E6			5015	bvc $D6FD
$D6E8			B913D7	lda LB_DrvInREU -8,y
$D6EB			8D16D7	sta CopyDrvData +2
$D6EE			B917D7	lda HB_DrvInREU -8,y
$D6F1			8D17D7	sta CopyDrvData +3
$D6F4			2000D7	jsr SwapREUData

$D6F7			20CBC2	jsr FetchRAM
$D6FA			2000D7	jsr SwapREUData
$D6FD			A200	ldx #$00
$D6FF			60	rts

$D700			A006	ldy #$06			;SwapREUData
$D702			B90200	lda r0,y
$D705			AA	tax
$D706			B914D7	lda CopyDrvData,y
$D709			990200	sta r0,y
$D70C			8A	txa
$D70D			9914D7	sta CopyDrvData,y
$D710			88	dey
$D711			10EF	bpl $D702
$D713			60	rts

$D714			0090	w $9000			;CopyDrvData	
$D716			0000	w zPage+0
$D718			800D	w $0D80
$D71A			00	b $00

$D71B			00	b < fileTrScTab +0			;LB_DrvInREU
$D71C			80	b < $9080
$D71D			00	b < $9E00
$D71E			80	b < $AB80

$D71F			83	b > fileTrScTab +0			;HB_DrvInREU
$D720			90	b > $9080
$D721			9E	b > $9E00
$D722			AB	b > $AB80

$D723			A013	ldy #$13			;xGetFHdrInfo
$D725			B114	lda (r9L),y
$D727			8504	sta r1L
$D729			C8	iny
$D72A			B114	lda (r9L),y
$D72C			8505	sta r1H
$D72E			A505	lda r1H
$D730			8D0183	sta fileTrScTab +1
$D733			A504	lda r1L
$D735			8D0083	sta fileTrScTab
$D738			205DD6	jsr Vec_fileHeader
$D73B			20E4C1	jsr GetBlock
$D73E			8A	txa
$D73F			D00E	bne $D74F
$D741			A001	ldy #$01
$D743			B114	lda (r9L),y
$D745			8504	sta r1L
$D747			C8	iny
$D748			B114	lda (r9L),y
$D74A			8505	sta r1H
$D74C			2052D6	jsr GetLoadAdr
$D74F			60	rts

$D750			A200	ldx #$00			;CheckFileClass
$D752			A516	lda r10L
$D754			0517	ora r10H
$D756			F021	beq $D779
$D758			A013	ldy #$13
$D75A			B10C	lda (r5L),y
$D75C			8504	sta r1L
$D75E			C8	iny
$D75F			B10C	lda (r5L),y
$D761			8505	sta r1H
$D763			205DD6	jsr Vec_fileHeader
$D766			20E4C1	jsr GetBlock
$D769			8A	txa
$D76A			D012	bne $D77E
$D76C			A8	tay
$D76D			B116	lda (r10L),y
$D76F			F008	beq $D779
$D771			D94D81	cmp fileHeader+$4D,y
$D774			D006	bne $D77C
$D776			C8	iny
$D777			D0F4	bne $D76D
$D779			A000	ldy #$00
$D77B			60	rts
$D77C			A0FF	ldy #$FF
$D77E			60	rts

$D77F			A516	lda r10L			;xLdDeskAcc
$D781			8D5D88	sta DA_ResetScrn
$D784			2029C2	jsr GetFHdrInfo
$D787			8A	txa
$D788			D04A	bne ExitLdDA
$D78A			A505	lda r1H
$D78C			48	pha
$D78D			A504	lda r1L
$D78F			48	pha
$D790			2039D8	jsr SaveSwapFile
$D793			68	pla
$D794			8504	sta r1L
$D796			68	pla
$D797			8505	sta r1H
$D799			8A	txa
$D79A			D038	bne ExitLdDA
$D79C			2052D6	jsr GetLoadAdr
$D79F			A9FF	lda #$FF
$D7A1			8506	sta r2L
$D7A3			8507	sta r2H
$D7A5			20FFC1	jsr ReadFile
$D7A8			8A	txa
$D7A9			D029	bne ExitLdDA
$D7AB			2063F3	jsr InitDB_Box1
$D7AE			204BC1	jsr UseSystemFon
$D7B1			200DC4	jsr GEOS_Init2
$D7B4			AD5D88	lda DA_ResetScrn
$D7B7			8516	sta r10L
$D7B9			68	pla
$D7BA			8D5088	sta DA_ReturnAdr +0
$D7BD			68	pla
$D7BE			8D5188	sta DA_ReturnAdr +1
$D7C1			BA	tsx
$D7C2			8E5288	stx DA_RetStackP
$D7C5			AE4C81	ldx fileHeader+$4C
$D7C8			AD4B81	lda fileHeader+$4B
$D7CB			4CF1C0	jmp InitMLoop1

$D7CE			68	pla 			;*** Ungenutze Bytes!
$D7CF			8504	sta r1L
$D7D1			68	pla
$D7D2			8505	sta r1H
$D7D4			60	rts 			;ExitLdDA / RTS wird benötigt!

$D7D5			A9D8	lda #>SwapFileName			;xRstrAppl
$D7D7			850F	sta r6H
$D7D9			A92D	lda #<SwapFileName
$D7DB			850E	sta r6L
$D7DD			A900	lda #$00
$D7DF			8502	sta r0L
$D7E1			2008C2	jsr GetFile
$D7E4			8A	txa
$D7E5			D017	bne $D7FE
$D7E7			2041F4	jsr InitDB_Box2

$D7EA			A9D8	lda #>SwapFileName
$D7EC			8503	sta r0H
$D7EE			A92D	lda #<SwapFileName
$D7F0			8502	sta r0L
$D7F2			A983	lda #>fileTrScTab
$D7F4			8509	sta r3H
$D7F6			A900	lda #<fileTrScTab
$D7F8			8508	sta r3L
$D7FA			2044C2	jsr FastDelFile
$D7FD			8A	txa
$D7FE			AE5288	ldx DA_RetStackP
$D801			9A	txs
$D802			AA	tax
$D803			AD5188	lda DA_ReturnAdr +1
$D806			48	pha
$D807			AD5088	lda DA_ReturnAdr +0
$D80A			48	pha
$D80B			60	rts

$D80C			20F8C5	jsr SaveFileData			;xLdApplic

$D80F			2011C2	jsr LdFile
$D812			8A	txa
$D813			D017	bne $D82C

$D815			AD5E88	lda LoadFileMode
$D818			2901	and #%00000001
$D81A			D010	bne $D82C

$D81C			20CFC5	jsr LoadFileData

$D81F			AD4B81	lda fileHeader+$4B
$D822			8510	sta r7L
$D824			AD4C81	lda fileHeader+$4C
$D827			8511	sta r7H
$D829			4C2FC2	jmp StartAppl

$D82C			60	rts

$D82D			1B	b $1B			;SwapFileName
$D82E			53776170b "Swap"
$D832			2046696Cb " Fil"
$D836			65	b "e"
$D837			00	b $00

$D838			96	b $96			;SerNoHByte

$D839			A90D	lda #$0D			;SaveSwapFile
$D83B			8D4581	sta fileHeader+$45
$D83E			A9D8	lda #>SwapFileName
$D840			8D0181	sta fileHeader     +1
$D843			A92D	lda #<SwapFileName
$D845			8D0081	sta fileHeader     +0
$D848			A981	lda #>fileHeader
$D84A			8515	sta r9H
$D84C			A900	lda #<fileHeader
$D84E			8514	sta r9L
$D850			A900	lda #$00
$D852			8516	sta r10L

$D854			A000	ldy #$00			;xSaveFile
$D856			B114	lda (r9L),y
$D858			990081	sta fileHeader,y
$D85B			C8	iny
$D85C			D0F8	bne $D856

$D85E			2047C2	jsr GetDirHead
$D861			8A	txa
$D862			D03D	bne $D8A1

$D864			20A2D8	jsr GetFileSize
$D867			2049D6	jsr Vec_fileTrScTab

$D86A			20FCC1	jsr BlkAlloc
$D86D			8A	txa
$D86E			D031	bne $D8A1

$D870			2049D6	jsr Vec_fileTrScTab
$D873			20F0C1	jsr SetGDirEntry
$D876			8A	txa
$D877			D028	bne $D8A1

$D879			204AC2	jsr PutDirHead
$D87C			8A	txa
$D87D			D022	bne $D8A1

$D87F			8DA081	sta $81A0
$D882			AD1484	lda dirEntryBuf +20
$D885			8505	sta r1H
$D887			AD1384	lda dirEntryBuf +19
$D88A			8504	sta r1L
$D88C			205DD6	jsr Vec_fileHeader

$D88F			20E7C1	jsr PutBlock
$D892			8A	txa
$D893			D00C	bne $D8A1

$D895			20C9D8	jsr SaveVLIR
$D898			8A	txa
$D899			D006	bne $D8A1

$D89B			2052D6	jsr GetLoadAdr
$D89E			20F9C1	jsr WriteFile
$D8A1			60	rts

$D8A2			AD4981	lda fileHeader+$49			;GetFileSize
$D8A5			38	sec
$D8A6			ED4781	sbc fileHeader+$47
$D8A9			8506	sta r2L
$D8AB			AD4A81	lda fileHeader+$4A
$D8AE			ED4881	sbc fileHeader+$48
$D8B1			8507	sta r2H

$D8B3			20BDD8	jsr Add254Bytes

$D8B6			AD4681	lda fileHeader+$46
$D8B9			C901	cmp #$01
$D8BB			D00B	bne $D8C8

$D8BD			18	clc 			;Add254Bytes
$D8BE			A9FE	lda #$FE
$D8C0			6506	adc r2L
$D8C2			8506	sta r2L
$D8C4			9002	bcc $D8C8
$D8C6			E607	inc r2H
$D8C8			60	rts

$D8C9			A200	ldx #$00			;SaveVLIR
$D8CB			AD1584	lda dirEntryBuf +21
$D8CE			C901	cmp #$01
$D8D0			D019	bne $D8EB
$D8D2			AD0284	lda dirEntryBuf +$02
$D8D5			8505	sta r1H
$D8D7			AD0184	lda dirEntryBuf +$01
$D8DA			8504	sta r1L
$D8DC			8A	txa
$D8DD			A8	tay
$D8DE			990080	sta diskBlkBuf,y
$D8E1			C8	iny
$D8E2			D0FA	bne $D8DE
$D8E4			88	dey
$D8E5			8C0180	sty diskBlkBuf+$01
$D8E8			203F90	jsr D_WriteSektor
$D8EB			60	rts

$D8EC			20F3C1	jsr BldGDirEntry			;xSetGDirEntry
$D8EF			20F6C1	jsr GetFreeDirBl
$D8F2			8A	txa
$D8F3			D028	bne $D91D
$D8F5			98	tya
$D8F6			18	clc
$D8F7			6900	adc #$00
$D8F9			850C	sta r5L
$D8FB			A980	lda #$80
$D8FD			6900	adc #$00
$D8FF			850D	sta r5H

$D901			A01D	ldy #$1D
$D903			B90084	lda dirEntryBuf,y
$D906			910C	sta (r5L),y
$D908			88	dey
$D909			10F8	bpl $D903

$D90B			2011D9	jsr SetFileDate
$D90E			4C3F90	jmp D_WriteSektor

$D911			A017	ldy #$17			;SetFileDate
$D913			B9FF84	lda year -$17,y
$D916			910C	sta (r5L),y
$D918			C8	iny
$D919			C01C	cpy #$1C
$D91B			D0F6	bne $D913
$D91D			60	rts

$D91E			A01D	ldy #$1D			;xBldGDirEntry
$D920			A900	lda #$00
$D922			990084	sta dirEntryBuf,y
$D925			88	dey
$D926			10FA	bpl $D922

$D928			A8	tay
$D929			B114	lda (r9L),y
$D92B			8508	sta r3L
$D92D			C8	iny
$D92E			B114	lda (r9L),y
$D930			8509	sta r3H
$D932			8405	sty r1H
$D934			88	dey

$D935			A203	ldx #$03
$D937			B108	lda (r3L),y
$D939			D004	bne $D93F
$D93B			8505	sta r1H
$D93D			A9A0	lda #$A0
$D93F			9D0084	sta dirEntryBuf,x
$D942			E8	inx
$D943			C8	iny
$D944			C010	cpy #$10
$D946			F006	beq $D94E
$D948			A505	lda r1H
$D94A			D0EB	bne $D937
$D94C			F0EF	beq $D93D

$D94E			A044	ldy #$44
$D950			B114	lda (r9L),y
$D952			8D0084	sta dirEntryBuf
$D955			A046	ldy #$46
$D957			B114	lda (r9L),y
$D959			8D1584	sta dirEntryBuf +21
$D95C			A000	ldy #$00
$D95E			8C0081	sty fileHeader +0
$D961			88	dey
$D962			8C0181	sty fileHeader +1

$D965			AD0183	lda fileTrScTab +1
$D968			8D1484	sta dirEntryBuf +20
$D96B			AD0083	lda fileTrScTab
$D96E			8D1384	sta dirEntryBuf +19
$D971			20809D	jsr SetVecToSek

$D974			AD0383	lda fileTrScTab +3
$D977			8D0284	sta dirEntryBuf +2
$D97A			AD0283	lda fileTrScTab +2
$D97D			8D0184	sta dirEntryBuf +1

$D980			AD1584	lda dirEntryBuf +21
$D983			C901	cmp #$01
$D985			D003	bne $D98A
$D987			20809D	jsr SetVecToSek

$D98A			A045	ldy #$45
$D98C			B114	lda (r9L),y
$D98E			8D1684	sta dirEntryBuf+$16
$D991			A507	lda r2H
$D993			8D1D84	sta dirEntryBuf +29
$D996			A506	lda r2L
$D998			8D1C84	sta dirEntryBuf +28
$D99B			60	rts

$D99C			205BDA	jsr DelFileEntry			;xDeleteFile
$D99F			8A	txa
$D9A0			F001	beq $D9A3
$D9A2			60	rts

$D9A3			A984	lda #>dirEntryBuf
$D9A5			8515	sta r9H
$D9A7			A900	lda #<dirEntryBuf
$D9A9			8514	sta r9L

$D9AB			08	php 			;xFreeFile
$D9AC			78	sei
$D9AD			2047C2	jsr GetDirHead
$D9B0			8A	txa
$D9B1			D035	bne $D9E8

$D9B3			A013	ldy #$13
$D9B5			B114	lda (r9L),y
$D9B7			F00D	beq $D9C6
$D9B9			8504	sta r1L
$D9BB			C8	iny
$D9BC			B114	lda (r9L),y
$D9BE			8505	sta r1H
$D9C0			2015DA	jsr FreeSeqChain
$D9C3			8A	txa
$D9C4			D022	bne $D9E8

$D9C6			A001	ldy #$01
$D9C8			B114	lda (r9L),y
$D9CA			8504	sta r1L
$D9CC			C8	iny
$D9CD			B114	lda (r9L),y
$D9CF			8505	sta r1H
$D9D1			2015DA	jsr FreeSeqChain
$D9D4			8A	txa
$D9D5			D011	bne $D9E8

$D9D7			A015	ldy #$15
$D9D9			B114	lda (r9L),y
$D9DB			C901	cmp #$01
$D9DD			D006	bne $D9E5
$D9DF			20EAD9	jsr SetFreeVLIR
$D9E2			8A	txa
$D9E3			D003	bne $D9E8
$D9E5			204AC2	jsr PutDirHead
$D9E8			28	plp
$D9E9			60	rts

$D9EA			A000	ldy #$00			;SetFreeVLIR
$D9EC			B90080	lda diskBlkBuf,y
$D9EF			990081	sta fileHeader,y
$D9F2			C8	iny
$D9F3			D0F7	bne $D9EC

$D9F5			A002	ldy #$02
$D9F7			98	tya
$D9F8			F01A	beq $DA14
$D9FA			B90081	lda fileHeader,y
$D9FD			8504	sta r1L
$D9FF			C8	iny
$DA00			B90081	lda fileHeader,y
$DA03			8505	sta r1H
$DA05			C8	iny
$DA06			A504	lda r1L
$DA08			F0ED	beq $D9F7
$DA0A			98	tya
$DA0B			48	pha
$DA0C			2015DA	jsr FreeSeqChain
$DA0F			68	pla
$DA10			A8	tay
$DA11			8A	txa
$DA12			F0E3	beq $D9F7
$DA14			60	rts

$DA15			A505	lda r1H			;FreeSeqChain
$DA17			850F	sta r6H
$DA19			A504	lda r1L
$DA1B			850E	sta r6L

$DA1D			A900	lda #$00
$DA1F			8506	sta r2L
$DA21			8507	sta r2H
$DA23			20B9C2	jsr FreeBlock
$DA26			8A	txa
$DA27			D031	bne $DA5A

$DA29			E606	inc r2L
$DA2B			D002	bne $DA2F
$DA2D			E607	inc r2H
$DA2F			A507	lda r2H
$DA31			48	pha
$DA32			A506	lda r2L
$DA34			48	pha

$DA35			A50F	lda r6H
$DA37			8505	sta r1H
$DA39			A50E	lda r6L
$DA3B			8504	sta r1L
$DA3D			203C90	jsr D_ReadSektor
$DA40			68	pla
$DA41			8506	sta r2L
$DA43			68	pla
$DA44			8507	sta r2H
$DA46			8A	txa
$DA47			D011	bne $DA5A

$DA49			AD0080	lda diskBlkBuf
$DA4C			F00A	beq $DA58
$DA4E			850E	sta r6L
$DA50			AD0180	lda diskBlkBuf+$01
$DA53			850F	sta r6H
$DA55			B8	clv
$DA56			50CB	bvc $DA23
$DA58			A200	ldx #$00
$DA5A			60	rts

$DA5B			A503	lda r0H			;DelFileEntry
$DA5D			850F	sta r6H
$DA5F			A502	lda r0L
$DA61			850E	sta r6L
$DA63			200BC2	jsr FindFile
$DA66			8A	txa
$DA67			D008	bne $DA71
$DA69			A900	lda #$00
$DA6B			A8	tay
$DA6C			910C	sta (r5L),y
$DA6E			203F90	jsr D_WriteSektor
$DA71			60	rts

$DA72			A509	lda r3H			;xFastDelFile
$DA74			48	pha
$DA75			A508	lda r3L
$DA77			48	pha
$DA78			205BDA	jsr DelFileEntry
$DA7B			68	pla
$DA7C			8508	sta r3L
$DA7E			68	pla
$DA7F			8509	sta r3H
$DA81			8A	txa
$DA82			D003	bne $DA87
$DA84			2088DA	jsr FreeSekTab
$DA87			60	rts

$DA88			A509	lda r3H			;FreeSekTab
$DA8A			48	pha
$DA8B			A508	lda r3L
$DA8D			48	pha
$DA8E			2047C2	jsr GetDirHead
$DA91			68	pla
$DA92			8508	sta r3L
$DA94			68	pla
$DA95			8509	sta r3H

$DA97			A000	ldy #$00
$DA99			B108	lda (r3L),y
$DA9B			F01B	beq $DAB8
$DA9D			850E	sta r6L
$DA9F			C8	iny
$DAA0			B108	lda (r3L),y
$DAA2			850F	sta r6H
$DAA4			20B9C2	jsr FreeBlock
$DAA7			8A	txa
$DAA8			D011	bne $DABB
$DAAA			18	clc
$DAAB			A902	lda #$02
$DAAD			6508	adc r3L
$DAAF			8508	sta r3L
$DAB1			9002	bcc $DAB5
$DAB3			E609	inc r3H
$DAB5			B8	clv
$DAB6			50DF	bvc $DA97
$DAB8			204AC2	jsr PutDirHead
$DABB			60	rts

$DABC			A503	lda r0H			;xRenameFile
$DABE			48	pha
$DABF			A502	lda r0L
$DAC1			48	pha
$DAC2			200BC2	jsr FindFile
$DAC5			68	pla
$DAC6			8502	sta r0L
$DAC8			68	pla
$DAC9			8503	sta r0H
$DACB			8A	txa
$DACC			D026	bne $DAF4
$DACE			18	clc
$DACF			A903	lda #$03
$DAD1			650C	adc r5L
$DAD3			850C	sta r5L
$DAD5			9002	bcc $DAD9
$DAD7			E60D	inc r5H
$DAD9			A000	ldy #$00
$DADB			B102	lda (r0L),y
$DADD			F009	beq $DAE8
$DADF			910C	sta (r5L),y
$DAE1			C8	iny
$DAE2			C010	cpy #$10
$DAE4			90F5	bcc $DADB
$DAE6			B009	bcs $DAF1

$DAE8			A9A0	lda #$A0
$DAEA			910C	sta (r5L),y
$DAEC			C8	iny
$DAED			C010	cpy #$10
$DAEF			90F7	bcc $DAE8
$DAF1			203F90	jsr D_WriteSektor
$DAF4			60	rts

$DAF5			A503	lda r0H			;xOpenRecordFile
$DAF7			850F	sta r6H
$DAF9			A502	lda r0L
$DAFB			850E	sta r6L
$DAFD			200BC2	jsr FindFile
$DB00			8A	txa
$DB01			D06F	bne $DB72

$DB03			A20A	ldx #$0A
$DB05			A000	ldy #$00
$DB07			B10C	lda (r5L),y
$DB09			293F	and #%00111111
$DB0B			C903	cmp #$03
$DB0D			D063	bne $DB72
$DB0F			A015	ldy #$15
$DB11			B10C	lda (r5L),y
$DB13			C901	cmp #$01
$DB15			D05B	bne $DB72

$DB17			A001	ldy #$01
$DB19			B10C	lda (r5L),y
$DB1B			8D6588	sta VLIR_HeaderTr
$DB1E			C8	iny
$DB1F			B10C	lda (r5L),y
$DB21			8D6688	sta VLIR_HeaderSe
$DB24			A505	lda r1H
$DB26			8D6288	sta VLIR_HdrDirSek+1
$DB29			A504	lda r1L
$DB2B			8D6188	sta VLIR_HdrDirSek+0
$DB2E			A50D	lda r5H
$DB30			8D6488	sta VLIR_HdrDEntry+1
$DB33			A50C	lda r5L
$DB35			8D6388	sta VLIR_HdrDEntry+0
$DB38			AD1D84	lda dirEntryBuf +29
$DB3B			8D9A84	sta fileSize+1
$DB3E			AD1C84	lda dirEntryBuf +28
$DB41			8D9984	sta fileSize
$DB44			20DDDC	jsr VLIR_GetHeader
$DB47			8A	txa
$DB48			D028	bne $DB72
$DB4A			8D9784	sta usedRecords

$DB4D			A002	ldy #$02
$DB4F			B90081	lda fileHeader,y
$DB52			190181	ora fileHeader +1,y
$DB55			F007	beq $DB5E
$DB57			EE9784	inc usedRecords
$DB5A			C8	iny
$DB5B			C8	iny
$DB5C			D0F1	bne $DB4F

$DB5E			A000	ldy #$00
$DB60			AD9784	lda usedRecords
$DB63			D001	bne $DB66
$DB65			88	dey
$DB66			8C9684	sty curRecord
$DB69			A200	ldx #$00
$DB6B			8E9884	stx fileWritten
$DB6E			60	rts

$DB6F			2078DB	jsr xUpdateRecFile			;xCloseRecordFile
$DB72			A900	lda #$00
$DB74			8D6588	sta VLIR_HeaderTr
$DB77			60	rts

$DB78			A200	ldx #$00			;xUpdateRecFile
$DB7A			AD9884	lda fileWritten
$DB7D			F03E	beq $DBBD
$DB7F			20E7DC	jsr VLIR_PutHeader
$DB82			8A	txa
$DB83			D038	bne $DBBD

$DB85			AD6288	lda VLIR_HdrDirSek+1
$DB88			8505	sta r1H
$DB8A			AD6188	lda VLIR_HdrDirSek+0
$DB8D			8504	sta r1L
$DB8F			203C90	jsr D_ReadSektor
$DB92			8A	txa
$DB93			D028	bne $DBBD

$DB95			AD6488	lda VLIR_HdrDEntry+1
$DB98			850D	sta r5H
$DB9A			AD6388	lda VLIR_HdrDEntry+0
$DB9D			850C	sta r5L
$DB9F			2011D9	jsr SetFileDate

$DBA2			A01C	ldy #$1C
$DBA4			AD9984	lda fileSize
$DBA7			910C	sta (r5L),y
$DBA9			C8	iny
$DBAA			AD9A84	lda fileSize+1
$DBAD			910C	sta (r5L),y
$DBAF			203F90	jsr D_WriteSektor
$DBB2			8A	txa
$DBB3			D008	bne $DBBD

$DBB5			204AC2	jsr PutDirHead
$DBB8			A900	lda #$00
$DBBA			8D9884	sta fileWritten
$DBBD			60	rts

$DBBE			AD9684	lda curRecord			;xNextRecord
$DBC1			18	clc
$DBC2			6901	adc #$01
$DBC4			B8	clv
$DBC5			5006	bvc xPointRecord

$DBC7			AD9684	lda curRecord			;xPreviousRecord
$DBCA			38	sec
$DBCB			E901	sbc #$01

$DBCD			AA	tax 			;xPointRecord
$DBCE			3011	bmi $DBE1
$DBD0			CD9784	cmp usedRecords
$DBD3			B00C	bcs $DBE1
$DBD5			8D9684	sta curRecord

$DBD8			205BDD	jsr VLIR_Get1stSek

$DBDB			A404	ldy r1L
$DBDD			A200	ldx #$00
$DBDF			F002	beq $DBE3
$DBE1			A208	ldx #$08
$DBE3			AD9684	lda curRecord
$DBE6			60	rts

$DBE7			A208	ldx #$08			;xDeleteRecord
$DBE9			AD9684	lda curRecord
$DBEC			303B	bmi $DC29

$DBEE			20BEDD	jsr VLIR_GetCurBAM
$DBF1			8A	txa
$DBF2			D035	bne $DC29

$DBF4			205BDD	jsr VLIR_Get1stSek

$DBF7			AD9684	lda curRecord
$DBFA			8502	sta r0L
$DBFC			2005DD	jsr VLIR_DelRecEntry
$DBFF			8A	txa
$DC00			D027	bne $DC29

$DC02			AD9684	lda curRecord
$DC05			CD9784	cmp usedRecords
$DC08			9003	bcc $DC0D
$DC0A			CE9684	dec curRecord

$DC0D			A200	ldx #$00
$DC0F			A504	lda r1L
$DC11			F016	beq $DC29
$DC13			2015DA	jsr FreeSeqChain
$DC16			8A	txa
$DC17			D010	bne $DC29

$DC19			AD9984	lda fileSize
$DC1C			38	sec
$DC1D			E506	sbc r2L
$DC1F			8D9984	sta fileSize
$DC22			B003	bcs $DC27
$DC24			CE9A84	dec fileSize+1
$DC27			A200	ldx #$00
$DC29			60	rts

$DC2A			A208	ldx #$08			;xInsertRecord
$DC2C			AD9684	lda curRecord
$DC2F			300E	bmi $DC3F

$DC31			20BEDD	jsr VLIR_GetCurBAM
$DC34			8A	txa
$DC35			D008	bne $DC3F

$DC37			AD9684	lda curRecord
$DC3A			8502	sta r0L
$DC3C			202ADD	jsr VLIR_InsRecEntry
$DC3F			60	rts

$DC40			20BEDD	jsr VLIR_GetCurBAM			;xAppendRecord
$DC43			8A	txa
$DC44			D013	bne $DC59

$DC46			AD9684	lda curRecord
$DC49			18	clc
$DC4A			6901	adc #$01
$DC4C			8502	sta r0L
$DC4E			202ADD	jsr VLIR_InsRecEntry
$DC51			8A	txa
$DC52			D005	bne $DC59

$DC54			A502	lda r0L
$DC56			8D9684	sta curRecord
$DC59			60	rts

$DC5A			A208	ldx #$08			;xReadRecord
$DC5C			AD9684	lda curRecord
$DC5F			300D	bmi $DC6E

$DC61			205BDD	jsr VLIR_Get1stSek
$DC64			A504	lda r1L
$DC66			AA	tax
$DC67			F005	beq $DC6E

$DC69			20FFC1	jsr ReadFile
$DC6C			A9FF	lda #$FF
$DC6E			60	rts

$DC6F			A208	ldx #$08			;xWriteRecord
$DC71			AD9684	lda curRecord
$DC74			3066	bmi $DCDC
$DC76			A507	lda r2H
$DC78			48	pha
$DC79			A506	lda r2L
$DC7B			48	pha
$DC7C			20BEDD	jsr VLIR_GetCurBAM
$DC7F			68	pla
$DC80			8506	sta r2L
$DC82			68	pla
$DC83			8507	sta r2H
$DC85			8A	txa
$DC86			D054	bne $DCDC
$DC88			205BDD	jsr VLIR_Get1stSek
$DC8B			A504	lda r1L
$DC8D			D00A	bne $DC99
$DC8F			A200	ldx #$00
$DC91			A506	lda r2L
$DC93			0507	ora r2H
$DC95			F045	beq $DCDC
$DC97			D036	bne $DCCF

$DC99			A507	lda r2H
$DC9B			48	pha
$DC9C			A506	lda r2L
$DC9E			48	pha
$DC9F			A511	lda r7H
$DCA1			48	pha
$DCA2			A510	lda r7L
$DCA4			48	pha
$DCA5			2015DA	jsr FreeSeqChain
$DCA8			A506	lda r2L
$DCAA			8502	sta r0L
$DCAC			68	pla
$DCAD			8510	sta r7L
$DCAF			68	pla
$DCB0			8511	sta r7H
$DCB2			68	pla
$DCB3			8506	sta r2L
$DCB5			68	pla
$DCB6			8507	sta r2H
$DCB8			8A	txa
$DCB9			D021	bne $DCDC

$DCBB			AD9984	lda fileSize+0
$DCBE			38	sec
$DCBF			E502	sbc r0L
$DCC1			8D9984	sta fileSize+0
$DCC4			B003	bcs $DCC9
$DCC6			CE9A84	dec fileSize+1
$DCC9			A506	lda r2L
$DCCB			0507	ora r2H
$DCCD			F003	beq VLIR_ClrHdrEntry
$DCCF			4C7BDD	jmp VLIR_SaveRecData

$DCD2			A0FF	ldy #$FF			;VLIR_ClrHdrEntry
$DCD4			8405	sty r1H
$DCD6			C8	iny
$DCD7			8404	sty r1L
$DCD9			206BDD	jsr VLIR_Set1stSek
$DCDC			60	rts

$DCDD			20F1DC	jsr VLIR_SetHdrData			;VLIR_GetHeader
$DCE0			8A	txa
$DCE1			D003	bne $DCE6
$DCE3			20E4C1	jsr GetBlock
$DCE6			60	rts

$DCE7			20F1DC	jsr VLIR_SetHdrData			;VLIR_PutHeader
$DCEA			8A	txa
$DCEB			D003	bne $DCF0
$DCED			20E7C1	jsr PutBlock
$DCF0			60	rts

$DCF1			A207	ldx #$07			;VLIR_SetHdrData
$DCF3			AD6588	lda VLIR_HeaderTr
$DCF6			F00C	beq $DD04
$DCF8			8504	sta r1L
$DCFA			AD6688	lda VLIR_HeaderSe
$DCFD			8505	sta r1H
$DCFF			205DD6	jsr Vec_fileHeader
$DD02			A200	ldx #$00
$DD04			60	rts

$DD05			A208	ldx #$08			;VLIR_DelRecEntry
$DD07			A502	lda r0L
$DD09			301E	bmi $DD29
$DD0B			0A	asl
$DD0C			A8	tay
$DD0D			A97E	lda #$7E
$DD0F			38	sec
$DD10			E502	sbc r0L
$DD12			0A	asl
$DD13			AA	tax
$DD14			F00A	beq $DD20
$DD16			B90481	lda fileHeader +4,y
$DD19			990281	sta fileHeader +2,y
$DD1C			C8	iny
$DD1D			CA	dex
$DD1E			D0F6	bne $DD16
$DD20			8EFE81	stx fileHeader+254
$DD23			8EFF81	stx fileHeader+255
$DD26			CE9784	dec usedRecords
$DD29			60	rts

$DD2A			A209	ldx #$09			;VLIR_InsRecEntry
$DD2C			AD9784	lda usedRecords
$DD2F			C97F	cmp #$7F
$DD31			B027	bcs $DD5A

$DD33			A208	ldx #$08
$DD35			A502	lda r0L
$DD37			3021	bmi $DD5A

$DD39			A0FE	ldy #$FE
$DD3B			A97E	lda #$7E
$DD3D			38	sec
$DD3E			E502	sbc r0L
$DD40			0A	asl
$DD41			AA	tax
$DD42			F00A	beq $DD4E

$DD44			B9FF80	lda fileHeader -1,y
$DD47			990181	sta fileHeader +1,y
$DD4A			88	dey
$DD4B			CA	dex
$DD4C			D0F6	bne $DD44

$DD4E			8A	txa
$DD4F			990081	sta fileHeader   ,y
$DD52			A9FF	lda #$FF
$DD54			990181	sta fileHeader +1,y
$DD57			EE9784	inc usedRecords
$DD5A			60	rts

$DD5B			AD9684	lda curRecord			;VLIR_Get1stSek
$DD5E			0A	asl
$DD5F			A8	tay
$DD60			B90281	lda fileHeader +2,y
$DD63			8504	sta r1L
$DD65			B90381	lda fileHeader +3,y
$DD68			8505	sta r1H
$DD6A			60	rts

$DD6B			AD9684	lda curRecord			;VLIR_Set1stSek
$DD6E			0A	asl
$DD6F			A8	tay
$DD70			A504	lda r1L
$DD72			990281	sta fileHeader +2,y
$DD75			A505	lda r1H
$DD77			990381	sta fileHeader +3,y
$DD7A			60	rts

$DD7B			2049D6	jsr Vec_fileTrScTab			;VLIR_SaveRecData
$DD7E			A511	lda r7H
$DD80			48	pha
$DD81			A510	lda r7L
$DD83			48	pha
$DD84			20FCC1	jsr BlkAlloc
$DD87			68	pla
$DD88			8510	sta r7L
$DD8A			68	pla
$DD8B			8511	sta r7H
$DD8D			8A	txa
$DD8E			D02D	bne $DDBD
$DD90			A506	lda r2L
$DD92			48	pha
$DD93			2049D6	jsr Vec_fileTrScTab
$DD96			20F9C1	jsr WriteFile
$DD99			68	pla
$DD9A			8506	sta r2L
$DD9C			8A	txa
$DD9D			D01E	bne $DDBD
$DD9F			AD0183	lda fileTrScTab +1
$DDA2			8505	sta r1H
$DDA4			AD0083	lda fileTrScTab
$DDA7			8504	sta r1L
$DDA9			206BDD	jsr VLIR_Set1stSek
$DDAC			8A	txa
$DDAD			D00E	bne $DDBD
$DDAF			A506	lda r2L
$DDB1			18	clc
$DDB2			6D9984	adc fileSize
$DDB5			8D9984	sta fileSize
$DDB8			9003	bcc $DDBD
$DDBA			EE9A84	inc fileSize+1
$DDBD			60	rts

$DDBE			A200	ldx #$00			;VLIR_GetCurBAM
$DDC0			AD9884	lda fileWritten
$DDC3			D00B	bne $DDD0
$DDC5			2047C2	jsr GetDirHead
$DDC8			8A	txa
$DDC9			D005	bne $DDD0
$DDCB			A9FF	lda #$FF
$DDCD			8D9884	sta fileWritten
$DDD0			60	rts

$DDD1			A40D	ldy r5H			;xReadByte
$DDD3			C40C	cpy r5L
$DDD5			F007	beq $DDDE
$DDD7			B10A	lda (r4L),y
$DDD9			E60D	inc r5H
$DDDB			A200	ldx #$00
$DDDD			60	rts

$DDDE			A20B	ldx #$0B
$DDE0			A504	lda r1L
$DDE2			F0F9	beq $DDDD

$DDE4			20E4C1	jsr GetBlock
$DDE7			8A	txa
$DDE8			D0F3	bne $DDDD

$DDEA			A002	ldy #$02
$DDEC			840D	sty r5H
$DDEE			88	dey
$DDEF			B10A	lda (r4L),y
$DDF1			8505	sta r1H
$DDF3			AA	tax
$DDF4			88	dey
$DDF5			B10A	lda (r4L),y
$DDF7			8504	sta r1L
$DDF9			F002	beq $DDFD
$DDFB			A2FF	ldx #$FF
$DDFD			E8	inx
$DDFE			860C	stx r5L
$DE00			B8	clv
$DE01			50CE	bvc xReadByte

$DE03			2E00	w currentMode			;InitVarData
$DE05			0C	b $0C
$DE06			00	b $00			;currentMode
$DE07			C0	b $C0			;dispBufferOn
$DE08			00	b $00			;mouseOn
$DE09			C184	w mousePicData			;mousePicPtr
$DE0B			00	b $00			;windowTop
$DE0C			C7	b $C7			;windowBottom
$DE0D			0000	w zPage+0			;leftMargin
$DE0F			3F01	w $013F			;rightMargin
$DE11			00	b $00			;pressFlag

$DE12			9B84	w appMain
$DE14			1C	b $1C
$DE15			0000	w zPage+0			;appMain
$DE17			D7C2	w xInterruptMain			;intTopVector
$DE19			0000	w zPage+0			;intBotVector
$DE1B			0000	w zPage+0			;mouseVector
$DE1D			0000	w zPage+0			;keyVector
$DE1F			0000	w zPage+0			;inputVector
$DE21			0000	w zPage+0			;mouseFaultVec
$DE23			0000	w zPage+0			;otherPressVec
$DE25			0000	w zPage+0			;StringFaultVec
$DE27			0000	w zPage+0			;alarmTmtVector
$DE29			88CF	w xPanic			;BRKVector
$DE2B			88C8	w xRecoverRec			;RecoverVector
$DE2D			0A	b $0a			;selectionFlash
$DE2E			00	b $00			;alphaFlag
$DE2F			80	b $80			;iconSelFlag
$DE30			00	b $00			;faultData

$DE31			7D87	w MaxProcess
$DE33			02	b $02
$DE34			0000	b $00,$00

$DE36			0888	w DI_VecToEntry
$DE38			01	b $01
$DE39			00	b $00

$DE3A			4000	w DI_VecDefTab +1			;Zeiger auf DoIcon-Tabelle
$DE3C			01	b $01			;löschen!
$DE3D			00	b $00

$DE3E			F88F	w obj0Pointer
$DE40			08	b $08
$DE41			28	b $28			;obj0Pointer
$DE42			29	b $29			;obj1Pointer
$DE43			2A	b $2A			;obj2Pointer
$DE44			2B	b $2B			;obj3Pointer
$DE45			2C	b $2C			;obj4Pointer
$DE46			2D	b $2D			;obj5Pointer
$DE47			2E	b $2E			;obj6Pointer
$DE48			2F	b $2F			;obj7Pointer

$DE49			0000	w zPage+0

$DE4B			38	sec 			;xGetRealSize
$DE4C			E920	sbc #$20
$DE4E			20E6E6	jsr GetCodeWidth
$DE51			A8	tay
$DE52			8A	txa
$DE53			A629	ldx curSetHight
$DE55			48	pha
$DE56			2940	and #%01000000
$DE58			F001	beq $DE5B
$DE5A			C8	iny
$DE5B			68	pla
$DE5C			2908	and #%00001000
$DE5E			F00A	beq $DE6A
$DE60			E8	inx
$DE61			E8	inx
$DE62			C8	iny
$DE63			C8	iny
$DE64			A526	lda baselineOffset
$DE66			18	clc
$DE67			6902	adc #$02
$DE69			60	rts

$DE6A			A526	lda baselineOffset
$DE6C			60	rts

$DE6D			A405	ldy r1H			;DefCharData
$DE6F			C8	iny
$DE70			8CFE87	sty BaseUnderLine
$DE73			850C	sta r5L
$DE75			A200	ldx #$00
$DE77			18	clc
$DE78			6920	adc #$20
$DE7A			20B1C1	jsr GetRealSize
$DE7D			98	tya
$DE7E			48	pha

$DE7F			A50C	lda r5L
$DE81			0A	asl
$DE82			A8	tay
$DE83			B12A	lda (curIndexTable),y
$DE85			8506	sta r2L
$DE87			2907	and #%00000111
$DE89			8DFD87	sta BitStr1stBit

$DE8C			A506	lda r2L
$DE8E			29F8	and #%11111000
$DE90			8508	sta r3L
$DE92			C8	iny
$DE93			B12A	lda (curIndexTable),y
$DE95			8507	sta r2H

$DE97			68	pla

$DE98			18	clc
$DE99			6506	adc r2L
$DE9B			850F	sta r6H
$DE9D			18	clc
$DE9E			E508	sbc r3L
$DEA0			4A	lsr
$DEA1			4A	lsr
$DEA2			4A	lsr
$DEA3			8509	sta r3H
$DEA5			AA	tax
$DEA6			E003	cpx #$03
$DEA8			9002	bcc $DEAC
$DEAA			A203	ldx #$03

$DEAC			BD78DF	lda CalcBitDataL,x
$DEAF			851C	sta r13L
$DEB1			BD7CDF	lda CalcBitDataL,x
$DEB4			851D	sta r13H

$DEB6			A506	lda r2L
$DEB8			4607	lsr r2H
$DEBA			6A	ror
$DEBB			4607	lsr r2H
$DEBD			6A	ror
$DEBE			4607	lsr r2H
$DEC0			6A	ror
$DEC1			18	clc
$DEC2			652C	adc cardDataPtr
$DEC4			8506	sta r2L
$DEC6			A507	lda r2H
$DEC8			652D	adc cardDataPtr+1
$DECA			8507	sta r2H

$DECC			ACFD87	ldy BitStr1stBit
$DECF			B9F5C2	lda BitData3,y
$DED2			49FF	eor #%11111111
$DED4			8DFC87	sta BitStrDataMask

$DED7			A40F	ldy r6H
$DED9			88	dey
$DEDA			98	tya
$DEDB			2907	and #%00000111
$DEDD			A8	tay
$DEDE			B9FDC2	lda BitData4,y
$DEE1			49FF	eor #%11111111
$DEE3			8511	sta r7H

$DEE5			A52E	lda currentMode
$DEE7			AA	tax
$DEE8			2908	and #%00001000
$DEEA			F002	beq $DEEE
$DEEC			A980	lda #$80
$DEEE			8513	sta r8H

$DEF0			A50C	lda r5L
$DEF2			18	clc
$DEF3			6920	adc #$20
$DEF5			20B1C1	jsr GetRealSize
$DEF8			850D	sta r5H

$DEFA			A505	lda r1H
$DEFC			38	sec
$DEFD			E50D	sbc r5H
$DEFF			8505	sta r1H

$DF01			8617	stx r10H

$DF03			98	tya
$DF04			48	pha

$DF05			A519	lda r11H
$DF07			300C	bmi $DF15

$DF09			A538	lda rightMargin+1
$DF0B			C519	cmp r11H
$DF0D			D004	bne $DF13
$DF0F			A537	lda rightMargin
$DF11			C518	cmp r11L
$DF13			9047	bcc $DF5C

$DF15			A52E	lda currentMode
$DF17			2910	and #%00010000
$DF19			D001	bne $DF1C
$DF1B			AA	tax

$DF1C			8A	txa
$DF1D			4A	lsr
$DF1E			8508	sta r3L

$DF20			18	clc
$DF21			6518	adc r11L
$DF23			8D9BE3	sta StrBitXposL
$DF26			A519	lda r11H
$DF28			6900	adc #$00
$DF2A			8D9CE3	sta StrBitXposH

$DF2D			68	pla
$DF2E			8D0788	sta CurCharWidth

$DF31			18	clc
$DF32			6D9BE3	adc StrBitXposL
$DF35			8518	sta r11L
$DF37			A900	lda #$00
$DF39			6D9CE3	adc StrBitXposH
$DF3C			8519	sta r11H
$DF3E			302B	bmi $DF6B

$DF40			A536	lda leftMargin+1
$DF42			C519	cmp r11H
$DF44			D004	bne $DF4A
$DF46			A535	lda leftMargin
$DF48			C518	cmp r11L
$DF4A			B01F	bcs $DF6B

$DF4C			2080DF	jsr StreamInfo

$DF4F			A200	ldx #$00
$DF51			A52E	lda currentMode
$DF53			2920	and #%00100000
$DF55			F001	beq $DF58
$DF57			CA	dex
$DF58			8616	stx r10L
$DF5A			18	clc
$DF5B			60	rts

$DF5C			68	pla 			;RightOver	
$DF5D			8D0788	sta CurCharWidth
$DF60			18	clc
$DF61			6518	adc r11L
$DF63			8518	sta r11L
$DF65			900F	bcc $DF76
$DF67			E619	inc r11H
$DF69			38	sec
$DF6A			60	rts

$DF6B			A518	lda r11L			;LeftOver
$DF6D			38	sec
$DF6E			E508	sbc r3L
$DF70			8518	sta r11L
$DF72			B002	bcs $DF76
$DF74			C619	dec r11H
$DF76			38	sec
$DF77			60	rts

$DF78			36	b < Char24Bit			;CalcBitDataL
$DF79			44	b < Char32Bit
$DF7A			5B	b < Char40Bit
$DF7B			75	b < Char48Bit

$DF7C			E3	b > Char24Bit			;CalcBitDataH
$DF7D			E3	b > Char32Bit
$DF7E			E3	b > Char40Bit
$DF7F			E3	b > Char48Bit

$DF80			A605	ldx r1H			;StreamInfo
$DF82			203CC1	jsr GetScanLine

$DF85			AD9BE3	lda StrBitXposL
$DF88			AE9CE3	ldx StrBitXposH
$DF8B			3008	bmi $DF95
$DF8D			E436	cpx leftMargin+1
$DF8F			D002	bne $DF93
$DF91			C535	cmp leftMargin
$DF93			B004	bcs $DF99

$DF95			A636	ldx leftMargin+1
$DF97			A535	lda leftMargin

$DF99			48	pha
$DF9A			29F8	and #%11111000
$DF9C			850A	sta r4L
$DF9E			E000	cpx #$00
$DFA0			D004	bne $DFA6
$DFA2			C9C0	cmp #$C0
$DFA4			9014	bcc $DFBA

$DFA6			38	sec
$DFA7			E980	sbc #$80
$DFA9			48	pha
$DFAA			A50C	lda r5L
$DFAC			18	clc
$DFAD			6980	adc #$80
$DFAF			850C	sta r5L
$DFB1			850E	sta r6L
$DFB3			9004	bcc $DFB9
$DFB5			E60D	inc r5H
$DFB7			E60F	inc r6H
$DFB9			68	pla

$DFBA			8504	sta r1L

$DFBC			AD9CE3	lda StrBitXposH
$DFBF			8508	sta r3L
$DFC1			4608	lsr r3L
$DFC3			AD9BE3	lda StrBitXposL
$DFC6			6A	ror
$DFC7			4608	lsr r3L
$DFC9			6A	ror
$DFCA			4608	lsr r3L
$DFCC			6A	ror
$DFCD			8510	sta r7L

$DFCF			A536	lda leftMargin+1
$DFD1			4A	lsr
$DFD2			A535	lda leftMargin+0
$DFD4			6A	ror
$DFD5			4A	lsr
$DFD6			4A	lsr
$DFD7			38	sec
$DFD8			E510	sbc r7L
$DFDA			1002	bpl $DFDE
$DFDC			A900	lda #$00
$DFDE			8D9AE3	sta CurStreamCard

$DFE1			AD9BE3	lda StrBitXposL
$DFE4			2907	and #%00000111
$DFE6			8510	sta r7L

$DFE8			68	pla
$DFE9			2907	and #%00000111
$DFEB			A8	tay
$DFEC			B9F5C2	lda BitData3,y
$DFEF			8508	sta r3L
$DFF1			49FF	eor #%11111111
$DFF3			8514	sta r9L

$DFF5			A418	ldy r11L
$DFF7			88	dey

$DFF8			A638	ldx rightMargin+1
$DFFA			A537	lda rightMargin
$DFFC			E419	cpx r11H
$DFFE			D002	bne $E002
$E000			C518	cmp r11L
$E002			B001	bcs $E005

$E004			A8	tay
$E005			98	tya
$E006			2907	and #%00000111
$E008			AA	tax
$E009			BDFDC2	lda BitData4,x
$E00C			850B	sta r4H
$E00E			49FF	eor #%11111111
$E010			8515	sta r9H

$E012			98	tya
$E013			38	sec
$E014			E50A	sbc r4L
$E016			1002	bpl $E01A
$E018			A900	lda #$00

$E01A			4A	lsr
$E01B			4A	lsr
$E01C			4A	lsr
$E01D			18	clc
$E01E			6D9AE3	adc CurStreamCard
$E021			8512	sta r8L
$E023			C509	cmp r3H
$E025			B002	bcs $E029
$E027			A509	lda r3H

$E029			C903	cmp #$03
$E02B			B026	bcs $E053
$E02D			C902	cmp #$02
$E02F			D002	bne $E033
$E031			A901	lda #$01

$E033			0A	asl
$E034			0A	asl
$E035			0A	asl
$E036			0A	asl
$E037			851A	sta r12L

$E039			A510	lda r7L

$E03B			38	sec
$E03C			EDFD87	sbc BitStr1stBit

$E03F			18	clc
$E040			6908	adc #$08
$E042			18	clc
$E043			651A	adc r12L
$E045			AA	tax
$E046			BD5DE0	lda BitMoveRout,x
$E049			18	clc
$E04A			697C	adc #$7C
$E04C			A8	tay
$E04D			A900	lda #$00
$E04F			69E2	adc #$E2
$E051			D004	bne $E057

$E053			A9E2	lda #>PrepBitStream
$E055			A0DC	ldy #<PrepBitStream
$E057			851B	sta r12H
$E059			841A	sty r12L
$E05B			18	clc
$E05C			60	rts

$E05D			B4303132b $B4,$30,$31,$32			;BitMoveRout
$E061			33343536b $33,$34,$35,$36
$E065			07060504b $07,$06,$05,$04
$E069			03020100b $03,$02,$01,$00
$E06D			B43A3F44b $B4,$3A,$3F,$44
$E071			494E5358b $49,$4E,$53,$58
$E075			2D28231Eb $2D,$28,$23,$1E
$E079			19140F0Ab $19,$14,$0F,$0A

*** ENDE Teil 1 ***
