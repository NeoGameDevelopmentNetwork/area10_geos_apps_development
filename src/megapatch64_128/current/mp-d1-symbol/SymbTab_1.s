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

;*** ":iconSelFlag" definieren.
:ST_FLASH		= %10000000
:ST_INVERT		= %01000000

;*** Modi für Dialogbox.
:OK			= $01
:CANCEL			= $02
:YES			= $03
:NO			= $04
:OPEN			= $05
:DISK			= $06
;DRIVE			= $07				;--- Ergänzung: 14.01.19/M.Kanet
							;Ersetzt durch !DBSETDRVICON in DialogBox.
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

;*** Frei definierbare Register.
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

;*** Systemvariablen.
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
							; %xx1xxxxx = Wert nicht ändern.
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

:C3PO			= $0094				;   1 Byte
:BSOUR			= $0095				;   1 Byte

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

;*** Einsprungadressen innerhalb Laufwerkstreiber.
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
:DiskDrvTypeCode	= $906e				;"MPDD3"

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

;*** Zwischenspeicher.
:UserFileBuf		= APP_RAM + 5*256

;--- Ergänzung: 08.08.18/M.Kanet
;Um Symbolspeicher zu sparen wurde die Definition der Laufwerkstypen
;in SymbTab_2 ausgelagert.

;*** Definition der RAM-Typen.
:RAM_SCPU		= $10				;SuperCPU/RAMCard ab ROM V1.4!
:RAM_BBG		= $20				;GeoRAM/BBGRAM allgemein.
:RAM_BBG16		= $21				;GeoRAM/BBGRAM: Bankgröße 16Kb.
:RAM_BBG32		= $22				;GeoRAM/BBGRAM: Bankgröße 32Kb.
:RAM_BBG64		= $23				;GeoRAM/BBGRAM: Bankgröße 64Kb.
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
