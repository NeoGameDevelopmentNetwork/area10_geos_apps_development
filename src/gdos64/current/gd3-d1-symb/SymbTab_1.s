; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Labels.
;******************************************************************************

;*** Speicherbelegung Allgemein.
:APP_RAM		= $0400				;start of application space
:BACK_SCR_BASE		= $6000				;base of background screen
:PRINTBASE		= $7900				;load address for print drivers
:APP_VAR		= $7f40				;application variable space
:SPRITE_PICS		= $8a00				;base of sprite pictures
:COLOR_MATRIX		= $8c00				;video color matrix
:DISK_BASE		= $9000				;disk driver base address
:DISK_DRIVER_SIZE	= $0d80				;disk driver max. size
:SCREEN_BASE		= $a000				;base of foreground screen

:OS_BASE		= $8000				;start of OS data/code space
:OS_LOW			= $9d80				;start of lower OS code space
:OS_HIGH		= $c000				;start of OS code space
:GD_JUMPTAB		= $c0dc				;start of GDOS jump table
:OS_JUMPTAB		= $c100				;start of GEOS jump table

;*** Kernal-IRQ-Tabelle.
:IRQ_BASE		= $fffa				;start of irq vector table

;*** Eingabetreiber.
:MOUSE_BASE		= $fe80				;start of input driver
:MOUSE_SIZE		= $017a				;max. size of input64 driver

;*** Variablen.
:SYSVAR_BASE		= OS_BASE			;OS variable base
:EXTVAR_BASE		= $9f7e				;  80 Byte = ":R3S_MPVARBUF"
:EXTVAR_SIZE		= 80
:COLVAR_BASE		= $9fea				;  22 Byte
:COLVAR_SIZE		= 22

;*** Allgemeine Labels.
:NULL			= $00
:FALSE			= $00
:TRUE			= $ff
:USELAST		= $7f
:NO_ERROR		= $00

;*** ":dispBufferOn" definieren.
:ST_WRGS_FORE		= %00100000
:ST_WR_BACK		= %01000000
:ST_WR_FORE		= %10000000

;*** ":iconSelFlag" definieren.
:ST_FLASH		= %10000000
:ST_INVERT		= %01000000

;*** Definition der RAM-Typen.
:RAM_SCPU		= $10				;SuperCPU/RAMCard ab ROM V1.4!
:RAM_BBG		= $20				;GeoRAM/BBGRAM allgemein.
;:RAM_BBG16		= $21				;GeoRAM/BBGRAM: Bankgröße 16Kb.
;:RAM_BBG32		= $22				;GeoRAM/BBGRAM: Bankgröße 32Kb.
;:RAM_BBG64		= $23				;GeoRAM/BBGRAM: Bankgröße 64Kb.
:RAM_REU		= $40				;Commodore C=REU.
:RAM_RL			= $80				;RAMLink.

;*** Jobcodes für DoRAMOp.
:jobStash		= %10010000
:jobFetch		= %10010001
:jobSwap		= %10010010
:jobVerify		= %10010011

;*** RAM/ROM-Konfiguration.
:zpage			= $0000
:CPU_DDR		= $0000
:CPU_DATA		= $0001

;*** RAM-Modi für CPU_DATA.
;---------------------------------------------------
;Value of       A000-BFFF    E000-FFFF    D000-DFFF
;Location $01   BASIC-ROM    KERNAL-ROM   I/O AREA
;----------     ----------   ----------   ----------
;   $30         ram          ram          ram
;   $31         ram          ram          Char ROM
;   $32         ram          ROM          Char ROM
;   $33         ROM          ROM          Char ROM
;   $34         ram          ram          ram
;   $35         ram          ram          I/O
;   $36         ram          ROM          I/O
;   $37         ROM          ROM          I/O
;---------------------------------------------------
:RAM_64K		= $30
:IO_IN			= $35
:KRNL_IO_IN		= $36
:KRNL_BAS_IO_IN		= $37

;*** Frei definierbare Labels.
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

;*** GEOS-Labels ZeroPage.
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
:DI_VecDefTab		= $003f				;   1 Word Nur C64  !!!
:CallRoutVec		= $0041				;   1 Word
:DB_VecDefTab		= $0043				;   1 Word
:SetStream		= $0045				;   8 Byte;Zwischenspeicher Zeichensatz.

:STATUS			= $0090				;   1 Byte

:curDevice		= $00ba				;   1 Byte

;*** GEOS-Labels im Bereich $8000-$87FF.
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
:CurCrsrPos		= $87d1				;   1 Byte  GetString: Cursor-Position
:InpStartXPosL		= $87d2				;   1 Byte  GetString: Low -X-Eingabeposition
:InpStartXPosH		= $87d3				;   1 Byte  GetString: High-X-Eingabeposition
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
:VerWriteFlag		= $8867				;   1 Byte Datei schreiben/vergleichen
;:StartDTdrv		= $8868				;   1 Byte Nur GEOS 2.x / EnterDeskTop
:savedmoby		= $88bb				;   1 Byte
;:scr80polar		= $88bc				;   1 Byte Nur C128
;:scr80colors		= $88bd				;   1 Byte Nur C128
;:vdcClrMode		= $88be				;   1 Byte Nur C128
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
:sysApplData		= $8fe8				;  16 Byte
:obj0Pointer		= $8ff8				;   1 Byte
:obj1Pointer		= $8ff9				;   1 Byte
:obj2Pointer		= $8ffa				;   1 Byte
:obj3Pointer		= $8ffb				;   1 Byte
:obj4Pointer		= $8ffc				;   1 Byte
:obj5Pointer		= $8ffd				;   1 Byte
:obj6Pointer		= $8ffe				;   1 Byte
:obj7Pointer		= $8fff				;   1 Byte

;*** Informationen Laufwerkstreiber.
:diskDrvType		= $904e
:diskDrvVersion		= $904f
:diskDrvRelease		= $906e				;"MPDD3"

;*** Speicher für erweiterte BAM.
:dir3Head		= $9c80				; 256 Byte
