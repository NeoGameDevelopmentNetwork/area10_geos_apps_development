﻿; UTF-8 Byte Order Mark (BOM), do not remove!
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
:TRUE_C64		= $8000
:TRUE_C128		= $f000
:USELAST		= $7f

;*** Startadressen der Ladeprogramme.
:SIZE_REBOOT		= $0500				;max. size of reboot-code.
:BASE_AUTO_BOOT		= $5000				;startadress autoboot-code.
:SIZE_AUTO_BOOT		= $0500				;max. size of autoboot-code.
;2. Teil in SymTab64 bzw. SymbTab128 !

;*** ":dispBufferOn" definieren.
:ST_WRGS_FORE		= %00100000
:ST_WR_BACK		= %01000000
:ST_WR_FORE		= %10000000

;":iconSelFlag" definieren.
:ST_FLASH		= %10000000
:ST_INVERT		= %01000000

;*** Modi für Dialogbox.
:OK			= $01
:CANCEL			= $02
:YES			= $03
:NO			= $04
:OPEN			= $05
:DISK			= $06
:DRIVE			= $07
:DUMMY			= $08
:DBUSRFILES		= $09
:DBSETCOL		= $0a
:DBTXTSTR		= $0b
:DBVARSTR		= $0c
:DBGETSTRING		= $0d
:DBSYSOPV		= $0e
:DBGRPHSTR		= $0f
:DBGETFILES		= $10
:DBOPVEC		= $11
:DBUSRICON		= $12
:DB_USR_ROUT		= $13
:DBSETDRVICON		= %01000000
:DBSELECTPART		= %10000000

;*** Kernal-Vektoren.
:irqvec			= $0314
:bkvec			= $0316
:nmivec			= $0318
:kernalVectors		= $031a

;*** Speicherbelegung.
:APP_RAM		= $0400				;start of application space
:BACK_SCR_BASE		= $6000				;base of background screen
:PRINTBASE		= $7900				;load address for print drivers
:APP_VAR		= $7f40				;application variable space
:OS_VARS		= $8000				;OS variable base
:SPRITE_PICS		= $8a00				;base of sprite pictures
:COLOR_MATRIX		= $8c00				;video color matrix
:DISK_BASE		= $9000				;disk driver base address
:DISK_DRIVER_SIZE	= $0d80				;disk driver max. size
:SCREEN_BASE		= $a000				;base of foreground screen
:OS_ROM			= $c000				;start of OS code space
:MP_JUMPTAB		= $c0df
:OS_JUMPTAB		= $c100				;start of GEOS jump table
:vicbase		= $d000				;video interface chip base address.
:sidbase		= $d400				;sound interface device base address.
:ctab			= $d800
:cia1base		= $dc00				;1st communications interface adaptor (CIA).
:cia2base		= $dd00				;second CIA chip
:EXP_BASE		= $df00				;Base address of RAM expansion unit #1 & 2
:EXP_BASE1		= $df00				;Base address of RAM expansion unit #1
:EXP_BASE2		= $de00				;Base address of RAM expansion unit #2

;*** Kernal-Vektoren.
:zpage			= $0000
:CPU_DDR		= $0000
:CPU_DATA		= $0001

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

:STATUS			= $0090				;   1 Byte

:curDevice		= $00ba				;   1 Byte

;*** Variablen im Bereich $8000-$87FF.
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

;weiter in der entsprechenden SymbTab64 oder SymbTab128

;*** Einsprung in Laufwerkstreiber.
:Get1stDirEntry		= $9030
:GetNxtDirEntry		= $9033
:GetBlock_dskBuf	= $903c
:PutBlock_dskBuf	= $903f
:AllocateBlock		= $9048
:ReadLink		= $904b
:DiskDrvType		= $904e
:DiskDrvVersion		= $904f
:OpenRootDir		= $9050
:OpenSubDir		= $9053
:GetBAMBlock		= $9056
:PutBAMBlock		= $9059
:GetPDirEntry		= $905c
:ReadPDirEntry		= $905f
:OpenPartition		= $9062
:SwapPartition		= $9065
:GetPTypeData		= $9068
:SendCommand		= $906b
:DiskDrvTypeCode	= $906e

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
:mport			= $dc01
:mpddr			= $dc03

;*** Startadressen Installationsroutinen.
:SIZE_DDRV_INIT		= $1000
:SIZE_DDRV_DATA		= $0d80
:BASE_DDRV_INIT		= APP_RAM
:BASE_DDRV_DATA		= BASE_DDRV_INIT + SIZE_DDRV_INIT
:BASE_EDITOR_DATA	= BASE_DDRV_DATA + SIZE_DDRV_DATA
:SIZE_EDITOR_DATA	= 256 +256 +64 +64*2 +64*17
:BASE_EDITOR_MAIN	= BASE_EDITOR_DATA + SIZE_EDITOR_DATA

;*** Sprungtabelle für Installationsroutine.
:DDrv_TestMode		= BASE_DDRV_INIT +0
:DDrv_Install		= BASE_DDRV_INIT +3
:DDrv_DeInstall		= BASE_DDRV_INIT +6

;*** SuperCPU-Kernel-Einsprünge.
:StashRAM_SCPU		= $d300
:FetchRAM_SCPU		= $d303
:SwapRAM_SCPU		= $d306
:VerifyRAM_SCPU		= $d309

;*** Variablen die den Inhalt der ersten Speicherbank bestimmen.
:R1_SIZE_MOVEDATA	= $7900				;MoveData-Transfer-Bereich.
:R1_SIZE_SYS_VAR1	= $0500				;Kernel-Variablen.
:R1_SIZE_REBOOT		= $0500				;ReBoot-Routine.
:R1_SIZE_DSKDEV_A	= $0d80				;Laufwerkstreiber A:
:R1_SIZE_DSKDEV_B	= $0d80				;Laufwerkstreiber B:
:R1_SIZE_DSKDEV_C	= $0d80				;Laufwerkstreiber C:
:R1_SIZE_DSKDEV_D	= $0d80				;Laufwerkstreiber D:
:R1_SIZE_SYS_PRG1	= $0280				;Kernel $9D80-$9FFF
:R1_SIZE_SYS_PRG2	= $10c0				;Kernel $BF40-$CFFF
:R1_SIZE_SYS_PRG3	= $3000				;Kernel $D000-$DFFF
:R1_SIZE_RBOOTMSE	= $003f				;Aktuelles Mauszeiger-Icon.
:R1_SIZE_SYS_BBG1	= $0100				;DoRAMOp-Zusatz für BBGRAM.
:R1_SIZE_SYS_BBG2	= $0100				;DoRAMOp-Zusatz für BBGRAM.

:R1_ADDR_MOVEDATA	= $0000
:R1_ADDR_SYS_VAR1	= $7900
:R1_ADDR_REBOOT		= $7e00
:R1_ADDR_DSKDEV_A	= $8300
:R1_ADDR_DSKDEV_B	= $9080
:R1_ADDR_DSKDEV_C	= $9e00
:R1_ADDR_DSKDEV_D	= $ab80
:R1_ADDR_SYS_PRG1	= $b900
:R1_ADDR_SYS_PRG2	= $bb80
:R1_ADDR_SYS_PRG3	= $cc40
:R1_ADDR_RBOOTMSE	= $fc40
:R1_ADDR_SYS_BBG1	= $fe00
:R1_ADDR_SYS_BBG2	= $ff00

;*** Variablen die den Inhalt der zweiten (MP)-Speicherbank bestimmen.
;    Für diese Routinen existiert ein Einsprung in der System-Sprungtabelle.
:R2_SIZE_REGISTER	= $0c00				;Registermenü-Routine.
:R2_SIZE_ENTER_DT	= $0200				;EnterDeskTop-Routine.
:R2_SIZE_PANIC		= $0100				;Neue PANIC!-Box.
:R2_SIZE_TOBASIC	= $0200				;Neue ToBasic-Routine.
:R2_SIZE_GETNXDAY	= $0080				;Nächsten Tag berechnen.
:R2_SIZE_DOALARM	= $0080				;Weckzeit anzeigen.
:R2_SIZE_GETFILES	= $1c00				;Neue Dateiauswahlbox.
:R2_SIZE_GFILDATA	= $0180				;GetFiles-Subroutine.
:R2_SIZE_GFILMENU	= $0380				;GetFiles-Subroutine.
:R2_SIZE_DB_SCREEN	= $0300				;Dialogboxbildschirm laden/speichern.
:R2_SIZE_DB_COLOR	= 25*40				;Dialogboxbildschirm: Farbe.
:R2_SIZE_DB_GRAFX	= 25*40*8			;Dialogboxbildschirm: Grafik.
:R2_SIZE_GETBSCRN	= $0100				;Hintergrundbild einlesen.
:R2_SIZE_BS_COLOR	= 25*40				;Hintergrundbild: Farbe.
:R2_SIZE_BS_GRAFX	= 25*40*8			;Hintergrundbild: Grafik.
:R2_SIZE_SCRSAVER	= $1c00				;Bildschirmschoner-Routine.
:R2_SIZE_SS_COLOR	= 25*40				;Bildschirmschoner: Farbe.
:R2_SIZE_SS_GRAFX	= 25*40*8			;Bildschirmschoner: Grafik.
:R2_SIZE_SPOOLER	= $1600				;Spooler-Menü.
:R2_SIZE_PRNSPHDR	= $0100				;Header für Druckerspooler-Treiber.
:R2_SIZE_PRNSPOOL	= $0640				;Druckerspooler-Treiber.
:R2_SIZE_PRNTHDR	= $0100				;Header für Drucker-Treiber.
:R2_SIZE_PRINTER	= $0640				;Drucker-Treiber.
:R2_SIZE_TASKMAN	= $2000				;Größe des TaskSwitchers.

:R2_ADDR_REGISTER	= $0000
:R2_ADDR_ENTER_DT	= (R2_ADDR_REGISTER + R2_SIZE_REGISTER)
:R2_ADDR_PANIC		= (R2_ADDR_ENTER_DT + R2_SIZE_ENTER_DT)
:R2_ADDR_TOBASIC	= (R2_ADDR_PANIC    + R2_SIZE_PANIC   )
:R2_ADDR_GETNXDAY	= (R2_ADDR_TOBASIC  + R2_SIZE_TOBASIC )
:R2_ADDR_DOALARM	= (R2_ADDR_GETNXDAY + R2_SIZE_GETNXDAY)
:R2_ADDR_GETFILES	= (R2_ADDR_DOALARM  + R2_SIZE_DOALARM )
:R2_ADDR_GFILDATA	= (R2_ADDR_GETFILES + R2_SIZE_GETFILES)
:R2_ADDR_GFILMENU	= (R2_ADDR_GFILDATA + R2_SIZE_GFILDATA)
:R2_ADDR_DB_SCREEN	= (R2_ADDR_GFILMENU + R2_SIZE_GFILMENU)
:R2_ADDR_DB_COLOR	= (R2_ADDR_DB_SCREEN+ R2_SIZE_DB_SCREEN)
:R2_ADDR_DB_GRAFX	= (R2_ADDR_DB_COLOR + R2_SIZE_DB_COLOR)
:R2_ADDR_GETBSCRN	= (R2_ADDR_DB_GRAFX + R2_SIZE_DB_GRAFX)
:R2_ADDR_BS_COLOR	= (R2_ADDR_GETBSCRN + R2_SIZE_GETBSCRN)
:R2_ADDR_BS_GRAFX	= (R2_ADDR_BS_COLOR + R2_SIZE_BS_COLOR)
:R2_ADDR_SCRSAVER	= (R2_ADDR_BS_GRAFX + R2_SIZE_BS_GRAFX)
:R2_ADDR_SS_COLOR	= (R2_ADDR_SCRSAVER + R2_SIZE_SCRSAVER)
:R2_ADDR_SS_GRAFX	= (R2_ADDR_SS_COLOR + R2_SIZE_SS_COLOR)
:R2_ADDR_SPOOLER	= (R2_ADDR_SS_GRAFX + R2_SIZE_SS_GRAFX)
:R2_ADDR_PRNSPHDR	= $d180
:R2_ADDR_PRNSPOOL	= $d280
:R2_ADDR_PRNTHDR	= $d8c0
:R2_ADDR_PRINTER	= $d9c0
:R2_ADDR_TASKMAN	= $4000				;Adresse des TaskManagers.
:R2_ADDR_TASKMAN_E	= $6000				;Adresse des TaskManagers während GEOS.Editor.
:R2_ADDR_TASKMAN_B	= $e000				;Adresse des TaskManagers beim booten!

;*** Variablen die den Inhalt der dritten (MP)-Speicherbank bestimmen.
;    Für diese Variablen gibt es keinen Eintrag in der Sprungtabelle!!!
:R3_SIZE_SWAPFILE	= $7c00				;Größe der Auslagerungsdatei.
:R3_SIZE_FNAMES		= $1200				;Zwischenspeicher für Dateinamen.
:R3_SIZE_AUTOBBUF	= SIZE_AUTO_BOOT		;Zwischenspeicher AutoBoot-Routine.
:R3_SIZE_REGMEMBUF	= R2_SIZE_REGISTER		;Zwischenspeicher Registermenü.
:R3_SIZE_ZEROPBUF	= $0400				;Zwischenspeicher Druckerspooler.
:R3_SIZE_OSVARBUF	= $0c00				;Zwischenspeicher Druckerspooler.
:R3_SIZE_MPVARBUF	= $0050				;Zwischenspeicher Druckerspooler.
:R3_SIZE_SP_COLOR	= 25*40				;Zwischenspeicher Druckerspooler.
:R3_SIZE_SP_GRAFX	= 25*40*8			;Zwischenspeicher Druckerspooler.
:R3_SIZE_SPOOLDAT	= 640 + 80 + 1920		;Zwischenspeicher Druckerspooler.
:R3_SIZE_PRNSPLTMP	= $0640				;Temp. Kopie des Spooler-Treibers.

:R3_ADDR_SWAPFILE	= $0000
:R3_ADDR_FNAMES		= (R3_ADDR_SWAPFILE  + R3_SIZE_SWAPFILE )
:R3_ADDR_AUTOBBUF	= (R3_ADDR_FNAMES    + R3_SIZE_FNAMES   )
:R3_ADDR_REGMEMBUF	= (R3_ADDR_AUTOBBUF  + R3_SIZE_AUTOBBUF )
:R3_ADDR_ZEROPBUF	= (R3_ADDR_REGMEMBUF + R3_SIZE_REGMEMBUF)
:R3_ADDR_OSVARBUF	= (R3_ADDR_ZEROPBUF  + R3_SIZE_ZEROPBUF )
:R3_ADDR_MPVARBUF	= (R3_ADDR_OSVARBUF  + R3_SIZE_OSVARBUF )
:R3_ADDR_SP_COLOR	= (R3_ADDR_MPVARBUF  + R3_SIZE_MPVARBUF )
:R3_ADDR_SP_GRAFX	= (R3_ADDR_SP_COLOR  + R3_SIZE_SP_COLOR )
:R3_ADDR_SPOOLDAT	= (R3_ADDR_SP_GRAFX  + R3_SIZE_SP_GRAFX )
:R3_ADDR_PRNSPLTMP	= (R3_ADDR_SPOOLDAT  + R3_SIZE_SPOOLDAT )
:R3_ADDR_END_MP3	= (R3_ADDR_PRNSPLTMP + R3_SIZE_PRNSPLTMP)

;*** MegaPatch-Startadressen.
;    Die externen Routinen werden an diese Adresse geladen und ausgeführt.
:LD_ADDR_NEWBSCRN	= $7800
:LD_ADDR_REGISTER	= PRINTBASE- R2_SIZE_REGISTER
:LD_ADDR_ENTER_DT	= diskBlkBuf- R2_SIZE_ENTER_DT
:LD_ADDR_PANIC		= diskBlkBuf
:LD_ADDR_TOBASIC	= DISK_BASE- R2_SIZE_TOBASIC
:LD_ADDR_GETNXDAY	= diskBlkBuf
:LD_ADDR_DOALARM	= diskBlkBuf
:LD_ADDR_GETFILES	= BACK_SCR_BASE
:LD_ADDR_GFILDATA	= dlgBoxRamBuf+ 0
:LD_ADDR_GFILPART	= dlgBoxRamBuf+ 9
:LD_ADDR_GFILMENU	= diskBlkBuf			;- R2_SIZE_GFILMENU
:LD_ADDR_GFILICON	= LD_ADDR_GFILMENU									+ 3
:LD_ADDR_GFILFBOX	= LD_ADDR_GFILMENU									+ 6
:LD_ADDR_DBOXICON	= LD_ADDR_GFILMENU									+ 9
:DB_FNAME_BUF		= LD_ADDR_GETFILES									- R3_SIZE_FNAMES
:DB_PDATA_BUF		= LD_ADDR_GETFILES									- 256
:LD_ADDR_DB_SCREEN	= diskBlkBuf
:DB_SCREEN_SAVE		= LD_ADDR_DB_SCREEN									+ 0
:DB_SCREEN_LOAD		= LD_ADDR_DB_SCREEN									+ 3
:LD_ADDR_TASKMAN	= $4000
:LD_ADDR_INIT_GEOS	= diskBlkBuf
:LD_ADDR_SCRSAVER	= OS_VARS- R2_SIZE_SCRSAVER
:LD_ADDR_SCRSVINIT	= LD_ADDR_SCRSAVER									+ 3
:LD_ADDR_GETBSCRN	= diskBlkBuf
:LD_ADDR_SPOOLER	= $4000

;*** Zwischenspeicher.
:UserFileBuf		= APP_RAM + 5*256

;*** Definition der Laufwerkstypen.
:Drv1541		= $01
:Drv1571		= $02
:Drv1581		= $03
:DrvNative		= $04
:Drv81DOS		= $05
:DrvFDDOS		= $15
:DrvPCDOS		= $05
:DrvShadow1541		= $41
:DrvShadow1581		= $43
:DrvRAM1541		= $81
:DrvRAM1571		= $82
:DrvRAM1581		= $83
:DrvRAMNM		= $84
:DrvRAMNM_SCPU		= $c4
:DrvFD			= $10
:DrvFD2			= $13
:DrvFD4			= $13
:DrvHD			= $20
:DrvRAMLink		= $30
:DrvFD41		= $11
:DrvFD71		= $12
:DrvFD81		= $13
:DrvFDNM		= $14
:DrvHD41		= $21
:DrvHD71		= $22
:DrvHD81		= $23
:DrvHDNM		= $24
:DrvRL41		= $31
:DrvRL71		= $32
:DrvRL81		= $33
:DrvRLNM		= $34
:DrvCMD			= %00110000

;*** Laufwerksmodi für RealDrvMode.
:SET_MODE_PARTITION	= %10000000
:SET_MODE_SUBDIR	= %01000000
:SET_MODE_FASTDISK	= %00100000

;*** Definition der RAM-Typen.
:RAM_SCPU		= $10				;SuperCPU/RAMCard ab ROM V1.4!
:RAM_BBG		= $20				;GeoRAM/BBGRAM.
:RAM_REU		= $40				;Commodore C=REU.
:RAM_RL			= $80				;RAMLink.

;*** Einsprünge im C64/C128-Kernal.
:IOINIT			= $fda3
:CINT			= $ff81				;Reset: Timer, IO, PAL/NTSC, Bildschirm.
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
:BSOUT			= $ffd2				;Zeichen ausgeben.
:LOAD			= $ffd5				;Datei laden.
:GETIN			= $ffe4				;Tastatur-Eingabe.
:CLALL			= $ffe7				;Alle Kanäle schließen.

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
