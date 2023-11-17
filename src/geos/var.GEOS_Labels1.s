; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Systemlabels.
;******************************************************************************

;*** Allgemeine Labels.
:NULL			= $00
:FALSE			= $00
:TRUE			= $ff
:USELAST		= $7f

;*** Speicherbelegung.
:APP_RAM		= $0400				;start of application space
:BACK_SCR_BASE		= $6000				;base of background screen
:PRINTBASE		= $7900				;load address for print drivers
:APP_VAR		= $7f40				;application variable space
:OS_VARS		= $8000				;OS variable base
:SPRITE_PICS		= $8a00				;base of sprite pictures
:COLOR_MATRIX		= $8c00				;video color matrix
:DISK_BASE		= $9000				;disk driver base address
:SCREEN_BASE		= $a000				;base of foreground screen
:OS_ROM			= $c000				;start of OS code space
:OS_JUMPTAB		= $c100				;start of GEOS jump table
:vicbase		= $d000				;video interface chip base address.
:sidbase		= $d400				;sound interface device base address.
:ctab			= $d800
:cia1base		= $dc00				;1st communications interface adaptor (CIA).
:cia2base		= $dd00				;second CIA chip
:EXP_BASE		= $df00				;Base address of RAM expansion unit #1 & 2
:EXP_BASE1		= $df00				;Base address of RAM expansion unit #1
:EXP_BASE2		= $de00				;Base address of RAM expansion unit #2
:MOUSE_JMP		= $fe80				;start of mouse jump table
:MOUSE_BASE		= $fe80				;start of input driver
:END_MOUSE		= $fffa				;end of input driver

;*** Kernal-Vektoren.
:zpage			= $0000
:CPU_DDR		= $0000
:CPU_DATA		= $0001
:RAM_64K		= $30
:IO_IN			= $35
:KRNL_IO_IN		= $36
:KRNL_BAS_IO_IN		= $37

;Systemvariablen.
:curPattern		= $0022				;   1 Word
:string			= $0024				;   1 Word
:baselineOffset		= $0026				;   1 Byte
:curSetWidth		= $0027				;   1 Word
:curSetHight		= $0029				;   1 Byte
:curIndexTable		= $002a				;   1 Word
:cardDataPntr		= $002c				;   1 Word
:currentMode		= $002e				;   1 Byte
:dispBufferOn		= $002f				;   1 Byte %1xxxxxxx = Vordergrund.
							; %x1xxxxxx = Hintergrund.
							; %xx1xxxxx = Wert nicht verändern.
							;             (Für Dialogbox nötig)

:mouseOn		= $0030				;   1 Byte
:msePicPtr		= $0031				;   1 Word
:windowTop		= $0033				;   1 Byte
:windowBottom		= $0034				;   1 Byte
:leftMargin		= $0035				;   1 Word
:rightMargin		= $0037				;   1 Word
:pressFlag		= $0039				;   1 Byte
:mouseXPos		= $003a				;   1 Word
:mouseYPos		= $003c				;   1 Byte
:returnAddress		= $003d				;   1 Word
:graphMode		= $003f				;   1 Byte Nur C128 !!!
:DI_VecDefTab		= $003f				;   1 Word Nur C64  !!!
:CallRoutVec		= $0041				;   1 Word
:DB_VecDefTab		= $0043				;   1 Word
:SetStream		= $0045				;   8 Byte;Zwischenspeicher Zeichensatz.

:STATUS			= $0090				;   1 Byte

:curDevice		= $00ba				;   1 Byte

;Frei definierbare Register.
:r0L			= $02
:r0H			= $03
:r0			= $0002
:r1L			= $04
:r1H			= $05
:r1			= $0004
:r2L			= $06
:r2H			= $07
:r2			= $0006
:r3L			= $08
:r3H			= $09
:r3			= $0008
:r4L			= $0a
:r4H			= $0b
:r4			= $000a
:r5L			= $0c
:r5H			= $0d
:r5			= $000c
:r6L			= $0e
:r6H			= $0f
:r6			= $000e
:r7L			= $10
:r7H			= $11
:r7			= $0010
:r8L			= $12
:r8H			= $13
:r8			= $0012
:r9L			= $14
:r9H			= $15
:r9			= $0014
:r10L			= $16
:r10H			= $17
:r10			= $0016
:r11L			= $18
:r11H			= $19
:r11			= $0018
:r12L			= $1a
:r12H			= $1b
:r12			= $001a
:r13L			= $1c
:r13H			= $1d
:r13			= $001c
:r14L			= $1e
:r14H			= $1f
:r14			= $001e
:r15L			= $20
:r15H			= $21
:r15			= $0020

:a0L			= $fb
:a0H			= $fc
:a0			= $00fb
:a1L			= $fd
:a1H			= $fe
:a1			= $00fd
:a2L			= $70
:a2H			= $71
:a2			= $0070
:a3L			= $72
:a3H			= $73
:a3			= $0072
:a4L			= $74
:a4H			= $75
:a4			= $0074
:a5L			= $76
:a5H			= $77
:a5			= $0076
:a6L			= $78
:a6H			= $79
:a6			= $0078
:a7L			= $7a
:a7H			= $7b
:a7			= $007a
:a8L			= $7c
:a8H			= $7d
:a8			= $007c
:a9L			= $7e
:a9H			= $7f
:a9			= $007e

;*** Kernal-Vektoren.
:irqvec			= $0314
:bkvec			= $0316
:nmivec			= $0318
:kernalVectors		= $031a

;*** Einsprünge im Druckertreiber.
:InitForPrint		= $7900
:StartPrint		= $7903
:PrintBuffer		= $7906
:StopPrint		= $7909
:GetDimensions		= $790c
:PrintASCII		= $790f
:StartASCII		= $7912
:SetNLQ			= $7915

;*** Variablen im Bereich $8000-$8807.
:diskBlkBuf		= $8000				; 256 Byte
:fileHeader		= $8100				; 256 Byte
:curDirHead		= $8200				; 256 Byte
:fileTrScTab		= $8300				; 256 Byte
:dirEntryBuf		= $8400				;  30 Byte
:DrACurDkNm		= $841e				;  18 Byte
:DrBCurDkNm		= $8430				;  18 Byte
:dataFileName		= $8442				;  17 Byte
:dataDiskName		= $8453				;  17 Byte
:PrntFileName		= $8465				;  17 Byte
:PrntDiskName		= $8476				;  17 Byte
:curDrive		= $8489				;   1 Byte
:diskOpenFlg		= $848a				;   1 Byte
:isGEOS			= $848b				;   1 Byte
:interleave		= $848c				;   1 Byte
:numDrives		= $848d				;   1 Byte
:driveType		= $848e				;   4 Byte
:turboFlags		= $8492				;   4 Byte
:curRecord		= $8496				;   1 Byte
:usedRecords		= $8497				;   1 Byte
:fileWritten		= $8498				;   1 Byte
:fileSize		= $8499				;   1 Word
:appMain		= $849b				;   1 Word
:intTopVector		= $849d				;   1 Word
:intBotVector		= $849f				;   1 Word
:mouseVector		= $84a1				;   1 Word
:keyVector		= $84a3				;   1 Word
:inputVector		= $84a5				;   1 Word
:mouseFaultVec		= $84a7				;   1 Word
:otherPressVec		= $84a9				;   1 Word
:StringFaultVec		= $84ab				;   1 Word
:alarmTmtVector		= $84ad				;   1 Word
:BRKVector		= $84af				;   1 Word
:RecoverVector		= $84b1				;   1 Word
:selectionFlash		= $84b3				;   1 Byte
:alphaFlag		= $84b4				;   1 Byte
:iconSelFlag		= $84b5				;   1 Byte
:faultData		= $84b6				;   1 Byte
:menuNumber		= $84b7				;   1 Byte
:mouseTop		= $84b8				;   1 Byte
:mouseBottom		= $84b9				;   1 Byte
:mouseLeft		= $84ba				;   1 Word
:mouseRight		= $84bc				;   1 Word
:stringX		= $84be				;   1 Word
:stringY		= $84c0				;   1 Byte
:mousePicData		= $84c1				;  64 Byte
:maxMouseSpeed		= $8501				;   1 Byte
:minMouseSpeed		= $8502				;   1 Byte
:mouseAccel		= $8503				;   1 Byte
:keyData		= $8504				;   1 Byte
:mouseData		= $8505				;   1 Byte
:inputData		= $8506				;   1 Byte
:random			= $850a				;   1 Word
:saveFontTab		= $850c				;   9 Byte
:dblClickCount		= $8515				;   1 Byte
:year			= $8516				;   1 Byte
:month			= $8517				;   1 Byte
:day			= $8518				;   1 Byte
:hour			= $8519				;   1 Byte
:minutes		= $851a				;   1 Byte
:seconds		= $851b				;   1 Byte
:alarmSetFlag		= $851c				;   1 Byte
:sysDBData		= $851d				;   1 Byte
:screencolors		= $851e				;   1 Byte
:dlgBoxRamBuf		= $851f				; 417 Byte

:DM_MenuType		= $86c0				;   1 Byte
:DM_MenuRange		= $86c1				;   6 Byte
:DM_MenuTabL		= $86c7				;   4 Byte
:DM_MenuTabH		= $86cb				;   4 Byte
:DM_MseOnEntry		= $86cf				;   4 Byte
:DM_MenuPosL		= $86d3				;  15 Byte
:DM_MenuPosH		= $86e2				;  15 Byte
:ProcCurDelay		= $86f1				;  40 Byte Prozesse/20 Zähler   /Aktuell
:ProcStatus		= $8719				;  20 Byte Prozesse/20 Statusbytes
:ProcRout		= $872d				;  40 Byte Prozesse/20 Routinen x 2 Byte
:ProcDelay		= $8755				;  40 Byte Prozesse/20 Zähler   x 2 Byte
:MaxProcess		= $877d				;   1 Byte
:MaxSleep		= $877e				;   1 Byte
:SleepTimeL		= $877f				;  20 Byte Sleep/20 Zähler für Wartezeit
:SleepTimeH		= $8793				;  20 Byte Sleep/20 Zähler für Wartezeit
:SleepRoutL		= $87a7				;  20 Byte Sleep/20 Low -Bytes-Programmadresse
:SleepRoutH		= $87bb				;  20 Byte Sleep/20 High-Bytes-Programmadresse
:InpStrMaxKey		= $87cf				;   1 Byte
:InpStrgLen		= $87d0				;   1 Byte
:InpStrgKVecBuf		= $87d1				;   1 Word
:InpStrgFault		= $87d3				;   1 Byte
:GS_Xpos		= $87d4				;   1 Word GraphicsString: X-Aktuell
:GS_XposL		= $87d4				;   1 Byte GraphicsString: X-Aktuell
:GS_XposH		= $87d5				;   1 Byte GraphicsString: X-Aktuell
:GS_Ypos		= $87d6				;   1 Byte GraphicsString: Y-Aktuell
:keyBufPointer		= $87d7				;   1 Byte
:MaxKeyInBuf		= $87d8				;   1 Byte
:keyMode		= $87d9				;   1 Byte
:keyBuffer		= $87da				;  16 Byte Tastaturpuffer
:currentKey		= $87ea				;   1 Byte
:KB_LastKeyTab		= $87eb				;   8 Byte
:KB_MultipleKey		= $87f3				;   8 Byte
:BitStrDataMask		= $87fc				;   1 Byte
:BitStr1stBit		= $87fd				;   1 Byte
:BaseUnderLine		= $87fe				;   1 Byte
:NewStream		= $87ff				;   8 Byte
:CurCharWidth		= $8807				;   1 Byte

;*** Variablen im Bereich $8008-$8FFF.
:DI_VecToEntry		= $8808				;   1 Byte
:DI_SelectedIcon	= $8809				;   1 Byte
:AlarmAktiv		= $880a				;   1 Byte
:IRQ_BufAkku		= $880b				;   1 Byte
:DB_Icon_Tab		= $880c				;  68 Byte
:DA_ReturnAdr		= $8850				;   1 Word
:DA_RetStackP		= $8852				;   1 Byte
:DB_ReturnAdr		= $8853				;   1 Word
:DB_RetStackP		= $8855				;   1 Byte
:DB_FilesInTab		= $8856				;   1 Byte
:DB_GetFileX		= $8857				;   1 Byte
:DB_GetFileY		= $8858				;   1 Byte
:DB_FileTabVec		= $8859				;   1 Word
:DB_1stFileInTab	= $885b				;   1 Byte
:DB_SelectedFile	= $885c				;   1 Byte
:DA_ResetScrn		= $885d				;   1 Byte
:LoadFileMode		= $885e				;   1 Byte
:LoadBufAdr		= $885f				;   1 Word Zwischenspeicher ":GetFile"
:VLIR_HdrDirSek		= $8861				;   1 Word
:VLIR_HdrDEntry		= $8863				;   1 Word
:VLIR_HeaderTr		= $8865				;   1 Byte
:VLIR_HeaderSe		= $8866				;   1 Byte
:VerWriteFlag		= $8867				;   1 Byte;Datei schreiben/vergleichen
:StartDTdrv		= $8868				;   1 Byte

:savedmoby		= $88bb				;   1 Byte
:scr80polar		= $88bc				;   1 Byte
:scr80colors		= $88bd				;   1 Byte
:vdcClrMode		= $88be				;   1 Byte
:driveData		= $88bf				;   4 Byte
:ramExpSize		= $88c3				;   1 Byte
:sysRAMFlg		= $88c4				;   1 Byte
:firstBoot		= $88c5				;   1 Byte
:curType		= $88c6				;   1 Byte
:ramBase		= $88c7				;   4 Byte
:inputDevName		= $88cb				;  17 Byte
:DrCCurDkNm		= $88dc				;  18 Byte
:DrDCurDkNm		= $88ee				;  18 Byte
:dir2Head		= $8900				; 256 Byte
:spr0pic		= $8a00				;  64 Byte
:spr1pic		= $8a40				;  64 Byte
:spr2pic		= $8a80				;  64 Byte
:spr3pic		= $8ac0				;  64 Byte
:spr4pic		= $8b00				;  64 Byte
:spr5pic		= $8b40				;  64 Byte
:spr6pic		= $8b80				;  64 Byte
:spr7pic		= $8bc0				;  64 Byte
:obj0Pointer		= $8ff8				;   1 Byte
:obj1Pointer		= $8ff9				;   1 Byte
:obj2Pointer		= $8ffa				;   1 Byte
:obj3Pointer		= $8ffb				;   1 Byte
:obj4Pointer		= $8ffc				;   1 Byte
:obj5Pointer		= $8ffd				;   1 Byte
:obj6Pointer		= $8ffe				;   1 Byte
:obj7Pointer		= $8fff				;   1 Byte

;*** Einsprung in Laufwerkstreiber.
:Get1stDirEntry		= $9030
:GetNxtDirEntry		= $9033
:D_ReadSektor		= $903c
:D_WriteSektor		= $903f
:AllocateBlock		= $9048
:ReadLink		= $904b

;*** Variablen im Bereich $D000-$DFFF
:mob0xpos		= $d000
:mob0ypos		= $d001
:mob1xpos		= $d002
:mob1ypos		= $d003
:mob2xpos		= $d004
:mob2ypos		= $d005
:mob3xpos		= $d006
:mob3ypos		= $d007
:mob4xpos		= $d008
:mob4ypos		= $d009
:mob5xpos		= $d00a
:mob5ypos		= $d00b
:mob6xpos		= $d00c
:mob6ypos		= $d00d
:mob7xpos		= $d00e
:mob7ypos		= $d00f
:msbxpos		= $d010
:grcntrl1		= $d011
:rasreg			= $d012
:lpxpos			= $d013
:lpypos			= $d014
:mobenble		= $d015
:grcntrl2		= $d016
:moby2			= $d017
:grmemptr		= $d018
:grirq			= $d019
:grirqen		= $d01a
:mobprior		= $d01b
:mobmcm			= $d01c
:mobx2			= $d01d
:mobmobcol		= $d01e
:mobbakcol		= $d01f
:extclr			= $d020
:bakclr0		= $d021
:mcmclr0		= $d025
:mcmclr1		= $d026
:mob0clr		= $d027
:mob1clr		= $d028
:mob2clr		= $d029
:mob3clr		= $d02a
:mob4clr		= $d02b
:mob5clr		= $d02c
:mob6clr		= $d02d
:mob7clr		= $d02e

;*** Einsprünge im Maustreiber.
:InitMouse		= $fe80
:SlowMouse		= $fe83
:UpdateMouse		= $fe86
:SetMouse		= $fe89

;*** Variablen im C64-Kernal.
:VARTAB			= $002b
:TAPE1			= $00b2
:PNTR			= $00d3
:NDX			= $00c6
:KEYD			= $0277
:MEMSTR			= $0281
:MEMSIZ			= $0283
:HIBASE			= $0288
:TBUFFR			= $033c
:NMIINV			= $0318

;*** Einsprünge im RAMLink-Kernal.
:EN_SET_REC		= $e0a9
:RL_HW_EN		= $e0b1
:SET_REC_IMG		= $fe03
:EXEC_REC_REU		= $fe06
:EXEC_REC_SEC		= $fe09
:RL_HW_DIS		= $fe0c
:RL_HW_DIS2		= $fe0f
:EXEC_REU_DIS		= $fe1e
:EXEC_SEC_DIS		= $fe21

;*** Einsprünge im C64-Kernal.
:IOINIT			= $fda3
:CINT			= $ff81
:SETMSG			= $ff90				;Dateiparameter definieren.
:SECOND			= $ff93				;Sekundär-Adresse nach LISTEN senden.
:TKSA			= $ff96				;Sekundär-Adresse nach TALK senden.
:ACPTR			= $ffa5				;Byte-Eingabe vom IEC-Bus.
:CIOUT			= $ffa8				;Byte-Ausgabe auf IEC-Bus.
:UNTALK			= $ffab				;UNTALK-Signal auf IEC-Bus senden.
:UNLSN			= $ffae				;UNLISTEN-Signal auf IEC-Bus senden.
:LISTEN			= $ffb1				;LISTEN-Signal auf IEC-Bus senden.
:TALK			= $ffb4				;TALK-Signal auf IEC-Bus senden.
:SETLFS			= $ffba				;Dateiparameter setzen.
:SETNAM			= $ffbd				;Dateiname setzen.
:OPENCHN		= $ffc0				;Datei öffnen.
:CLOSE			= $ffc3				;Datei schließen.
:CHKIN			= $ffc6				;Eingabefile setzen.
:CKOUT			= $ffc9				;Ausgabefile setzen.
:CLRCHN			= $ffcc				;Standard-I/O setzen.
:LOAD			= $ffd5				;Datei laden.
:CLALL			= $ffe7				;Alle Kanäle schließen.

;*** Labels für Menüdefinition.
:UN_CONSTRAINED		= %00000000
:CONSTRAINED		= %01000000

:MENU_ACTION		= %00000000
:DYN_SUB_MENU		= %01000000
:SUB_MENU		= %10000000

:HORIZONTAL		= %00000000
:VERTICAL		= %10000000

;*** Labels für Dialogboxen.
:OK			= $01
:CANCEL			= $02
:YES			= $03
:NO			= $04
:OPEN			= $05
:DISK			= $06

;*** Labels für Disketteninformationen.
;Dateityp definieren.
:SEQ			= $01
:PRG			= $02
:USR			= $03
:REL			= $04
:CBM			= $05
:NATIVE_DIR		= $06

;Dateiformat definieren.
:SEQUENTIAL		= $00
:VLIR			= $01

;Schreibschutz definieren.
:ST_WR_PR		= %01000000
:ST_NO_WR_PR		= %00000000

;GEOS-Dateytyp definieren.
:NOT_GEOS		= $00
:BASIC			= $01
:ASSEMBLY		= $02
:DATA			= $03
:SYSTEM			= $04
:DESK_ACC		= $05
:APPLICATION		= $06
:APPL_DATA		= $07
:FONT			= $08
:PRINTER		= $09
:INPUT_DEVICE		= $0a
:DISK_DEVICE		= $0b
:SYSTEM_BOOT		= $0c
:TEMPORARY		= $0d
:AUTO_EXEC		= $0e
:INPUT_128		= $0f
:GATEWAY_DOC		= $11
:GEOSHELL_COM		= $15
:GEOFAX_PRINTER		= $16
