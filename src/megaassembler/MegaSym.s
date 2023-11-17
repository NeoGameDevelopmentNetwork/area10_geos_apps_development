﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Systemlabels
; Version 28.06.1989
;
; Revision 26.03.2023:
; APP_LVAR und APP_LRAM ergänzt.
;
; Revision 26.12.2022:
; sysApplData ergänzt.
;
; Revision 07.10.2022:
; GetDiskBlkBuf, GetOPDPtr, PrintFCodes
; und PutDiskBlkBuf ergänzt.
;
; Revision 03.12.2022:
; sysVersion ergänzt.

:c128Flag = $c013
:ALARMMASK = %00000100
:ANY_FAULT = %11111000
:APPLICATION = 6
:APPL_DATA = 7
:APP_LVAR = $0200
:APP_LRAM = $0334
:APP_RAM = $0400
:APP_VAR = $7f40
:ASSEMBLY = 2
:AUTO_EXEC = 14
:AllocateBlock = $9048
:AppendRecord = $c289
:BACKSPACE = 8
:BACK_SCR_BASE = $6000
:BAD_BAM = 6
:BASIC = 1
:BBMult = $c160
:BFR_OVERFLOW = 11
:BLACK = 0
:BLOCKED_BIT = 6
:BLUE = 6
:BMult = $c163
:BOLDON = 24
:BOLD_BIT = 6
:BRKVector = $84af
:BROWN = 9
:BYTE_DEC_ERR = $2e
:BitOtherClip = $c2c5
:BitmapClip = $c2aa
:BitmapUp = $c142
:BldGDirEntry = $c1f3
:BlkAlloc = $c1fc
:BlockProcess = $c10c
:BootGEOS = $c000
:CANCEL = 2
:CANCEL_ERR = 12
:CBM = 5
:CLR_SAVE = %01000000
:CMND_FILE_NUM = 15
:COLOR_MATRIX = $8c00
:CONSTRAINED = %01000000
:CPU_DATA = $0001
:CPU_DDR = $0000
:CR = 13
:CRC = $c20e
:CYAN = 3
:CalcBlksFree = $c1db
:CallRoutine = $c1d8
:ChangeDiskDevice = $c2bc

:ChkDkGEOS = $c1de
:ClearMouseMode = $c19c
:ClearRam = $c178
:CloseRecordFile = $c277
:CmpFString = $c26e
:CmpString = $c26b
:CopyFString = $c268
:CopyString = $c265
:DATA = 3
:DAT_CHKSUM_ERR = $23
:DBGETFILES = 16
:DBGETSTRING = 13
:DBGRPHSTR = 15
:DBI_X_0 = 1
:DBI_X_1 = 9
:DBI_X_2 = 17
:DBI_Y_0 = 8
:DBI_Y_1 = 40
:DBI_Y_2 = 72
:DBLK_NOT_THERE = $22
:DBOPVEC = 17
:DBSYSOPV = 14
:DBTXTSTR = 11
:DBUSRICON = 18
:DBVARSTR = 12
:DB_USR_ROUT = 19
:DEF_DB_BOT = 127
:DEF_DB_LEFT = 64
:DEF_DB_POS = $80
:DEF_DB_RIGHT = 255
:DEF_DB_TOP = 32
:DEL = 0
:DESK_ACC = 5
:DEV_NOT_FOUND = 13
:DIR_1581_TRACK = 40
:DIR_ACC_CHAN = 13
:DIR_TRACK = 18
:DISK = 6
:DISK_BASE = $9000
:DISK_DEVICE = 11
:DKGREY = 11
:DK_NM_ID_LEN = 18
:DMult = $c166
:DOS_MISMATCH = $73
:DRV_1541 = 1
:DRV_1571 = 2
:DRV_1581 = 3
:DRV_NETWORK = 15
:DRV_NULL = 0
:DSK_ID_MISMAT = $29
:DSdiv = $c16c

:DShiftLeft = $c15d
:DShiftRight = $c262
:DYN_SUB_MENU = $40
:Dabs = $c16f
:Ddec = $c175
:Ddiv = $c169
:DeleteFile = $c238
:DeleteRecord = $c283
:DisablSprite = $c1d5
:Dnegate = $c172
:DoDlgBox = $c256
:DoIcons = $c15a
:DoInlineReturn = $c2a4
:DoMenu = $c151
:DoPreviousMenu = $c190
:DoRAMOp = $c2d4
:DoneWithIO = $c25f
:DrACurDkNm = $841e
:DrBCurDkNm = $8430
:DrCCurDkNm = $88dc
:DrDCurDkNm = $88ee
:DrawLine = $c130
:DrawPoint = $c133
:DrawSprite = $c1c6
:END_MOUSE = $fffa
:EOF = 0
:ESC_GRAPHICS = 16
:ESC_PUTSTRING = 6
:ESC_RULER = 17
:EXP_BASE = $df00
:EnablSprite = $c1d2
:EnableProcess = $c109
:EnterDeskTop = $c22c
:EnterTurbo = $c214
:ExitTurbo = $c232
:FALSE = 0
:FG_SAVE = %10000000
:FILE_NOT_FOUND = 5
:FONT = 8
:FORWARDSPACE = 9
:FRAME_RECTO = 7
:FROZEN_BIT = 5
:FRST_FILE_ENTRY = 2
:FULL_DIRECTORY = 4
:FUTURE1 = 7
:FUTURE2 = 8
:FUTURE3 = 9
:FUTURE4 = 10
:FastDelFile = $c244
:FetchRAM = $c2cb

:FillRam = $c17b
:FindBAMBit = $c2ad
:FindFTypes = $c23b
:FindFile = $c20b
:FirstInit = $c271
:FollowChain = $c205
:FrameRectangle = $c127
:FreeBlock = $c2b9
:FreeFile = $c226
:FreezeProcess = $c112
:GOTOX = 20
:GOTOXY = 22
:GOTOY = 21
:GRBANK0 = %11
:GRBANK1 = %10
:GRBANK2 = %01
:GRBANK3 = %00
:GREEN = 5
:GREY = 12
:Get1stDirEntry = $9030
:GetBlock = $c1e4
:GetCharWidth = $c1c9
:GetDimensions = $790c
:GetDirHead = $c247
:GetDiskBlkBuf = $903c
:GetFHdrInfo = $c229
:GetFile = $c208
:GetFreeDirBlk = $c1f6
:GetNextChar = $c2a7
:GetNxtDirEntry = $9033
:GetOPDPtr = $9036
:GetPtrCurDkNm = $c298
:GetRandom = $c187
:GetRealSize = $c1b1
:GetScanLine = $c13c
:GetSerialNumber = $c196
:GetString = $c1ba
:GotoFirstMenu = $c1bd
:GraphicsString = $c136
:HDR_CHKSUM_ERR = $27
:HDR_NOT_THERE = $20
:HOME = 11
:HORIZONTAL = %00000000
:HorizontalLine = $c118
:ICONSON_BIT = 5
:INCOMPATIBLE = 14
:INPUT_128 = 15
:INPUT_BIT = 6
:INPUT_DEVICE = 10
:INSUFF_SPACE = 3
:INV_RECORD = 8
:INV_TRACK = 2

:IO_IN = $35
:IRQ_VECTOR = $fffe
:ITALICON = 25
:ITALIC_BIT = 4
:ImprintRectangle = $c250
:InitForIO = $c25c
:InitForPrint = $7900
:InitMouse = $fe80
:InitProcesses = $c103
:InitRam = $c181
:InitTextPrompt = $c1c0
:InsertRecord = $c286
:InterruptMain = $c100
:InvertLine = $c11b
:InvertRectangle = $c12a
:IsMseInRegion = $c2b3
:KEYPRESS_BIT = 7
:KEY_BPS = 24
:KEY_CLEAR = 19
:KEY_DELETE = 29
:KEY_DOWN = 17
:KEY_F1 = 1
:KEY_F2 = 2
:KEY_F3 = 3
:KEY_F4 = 4
:KEY_F5 = 5
:KEY_F6 = 6
:KEY_F7 = 14
:KEY_F8 = 15
:KEY_HOME = 18
:KEY_INSERT = 28
:KEY_INVALID = 31
:KEY_LARROW = 20
:KEY_LEFT = BACKSPACE
:KEY_RIGHT = 30
:KEY_RUN = 23
:KEY_STOP = 22
:KEY_UP = 16
:KEY_UPARROW = 21
:KRNL_BAS_IO_IN = $37
:KRNL_IO_IN = $36
:LF = 10
:LINETO = 2
:LTBLUE = 14
:LTGREEN = 13
:LTGREY = 15
:LTRED = 10
:LdApplic = $c21d
:LdDeskAcc = $c217
:LdFile = $c211

:LoadCharSet = $c1cc
:MAX_CMND_STR = 32
:MEDGREY = 12
:MENUON_BIT = 6
:MENU_ACTION = $00
:MOUSEON_BIT = 7
:MOUSE_BASE = $fe80
:MOUSE_BIT = 5
:MOUSE_JMP = $fe80
:MOUSE_SPRNUM = 0
:MOVEPENTO = 1
:MainLoop = $c1c3
:MouseOff = $c18d
:MouseUp = $c18a
:MoveData = $c17e
:NEWCARDSET = 23
:NEWPATTERN = 5
:NMI_VECTOR = $fffa
:NO = 4
:NOTIMER_BIT = 4
:NOT_GEOS = 0
:NO_BLOCKS = 1
:NO_SYNC = $21
:NULL = 0
:NUM_FILE_TYPES = 15
:N_TRACKS = 35
:NewDisk = $c1e1
:NextRecord = $c27a
:NxtBlkAlloc = $c24d
:OFFBOTTOM_BIT = 6
:OFFLEFT_BIT = 5
:OFFMENU_BIT = 3
:OFFRIGHT_BIT = 4
:OFFTOP_BIT = 7
:OFF_1ST_M_ITEM = 7
:OFF_CFILE_TYPE = 0
:OFF_DB_1STCMD = 7
:OFF_DB_BOT = 2
:OFF_DB_FORM = 0
:OFF_DB_LEFT = 3
:OFF_DB_RIGHT = 5
:OFF_DB_TOP = 1
:OFF_DE_TR_SC = 1
:OFF_DISK_NAME = 144
:OFF_FNAME = 3
:OFF_GFILE_TYPE = 22
:OFF_GHDR_PTR = 19
:OFF_GSTRUC_TYPE = 21
:OFF_GS_DTYPE = 189
:OFF_GS_ID = 173

:OFF_HEIGHT_ICON = 5
:OFF_IC_XMOUSE = 1
:OFF_IC_YMOUSE = 3
:OFF_INDEX_PTR = 1
:OFF_MX_LEFT = 2
:OFF_MX_RIGHT = 4
:OFF_MY_BOT = 1
:OFF_MY_TOP = 0
:OFF_NM_ICNS = 0
:OFF_NUM_M_ITEMS = 6
:OFF_NXT_FILE = 32
:OFF_NX_ICON = 8
:OFF_OP_TR_SC = 171
:OFF_PIC_ICON = 0
:OFF_SIZE = 28
:OFF_SRV_RT_ICON = 6
:OFF_TO_BAM = 4
:OFF_WDTH_ICON = 4
:OFF_X_ICON_POS = 2
:OFF_YEAR = 23
:OFF_Y_ICON_POS = 3
:OK = 1
:OPEN = 5
:ORANGE = 8
:OS_JUMPTAB = $c100
:OS_ROM = $c000
:OS_VARS = $8000
:OUTLINEON = 26
:OUTLINE_BIT = 3
:OUT_OF_RECORDS = 9
:O_128_FLAGS = 96
:O_GHCMDR_TYPE = 68
:O_GHEND_ADDR = 73
:O_GHFNAME = 77
:O_GHGEOS_TYPE = 69
:O_GHIC_HEIGHT = 3
:O_GHIC_PIC = 4
:O_GHIC_WIDTH = 2
:O_GHINFO_TXT = $a0
:O_GHP_DISK = 97
:O_GHP_FNAME = 117
:O_GHSTR_TYPE = 70
:O_GHST_ADDR = 71
:O_GHST_VEC = 75
:O_GH_AUTHOR = 97
:OpenDisk = $c2a1
:OpenRecordFile = $c274
:PAGE_BREAK = 12
:PEN_XY_DELTA = 10
:PEN_X_DELTA = 8

:PEN_Y_DELTA = 9
:PLAINTEXT = 27
:PRG = 2
:PRINTBASE = $7900
:PRINTER = 9
:PURPLE = 4
:Panic = $c2c2
:PointRecord = $c280
:PosSprite = $c1cf
:PreviousRecord = $c27d
:PrintASCII = $790f
:PrintBuffer = $7906
:PrintFCodes = $7918
:PrntDiskName = $8476
:PrntFilename = $8465
:PrntFileName = PrntFilename
:PromptOff = $c29e
:PromptOn = $c29b
:PurgeTurbo = $c235
:PutBlock = $c1e7
:PutChar = $c145
:PutDecimal = $c184
:PutDirHead = $c24a
:PutDiskBlkBuf = $903f
:PutString = $c148
:RAM_64K = $30
:RECTANGLETO = 3
:RED = 2
:REL = 4
:REL_FILE_NUM = 9
:RESET_VECTOR = $fffc
:REVERSE_BIT = 5
:REV_OFF = 19
:REV_ON = 18
:RUNABLE_BIT = 7
:ReDoMenu = $c193
:ReadBlock = $c21a
:ReadByte = $c2b6
:ReadFile = $c1ff
:ReadLink = $904b
:ReadRecord = $c28c
:RecoverAllMenus = $c157
:RecoverLine = $c11e
:RecoverMenu = $c154
:RecoverRectangle = $c12d
:RecoverVector = $84b1
:Rectangle = $c124
:RenameFile = $c259
:ResetHandle = $c003
:RestartProcess = $c106
:RstrAppl = $c23e
:RstrFrmDialogue = $c2bf
:SCREEN_BASE = $a000

:SC_BYTE_WIDTH = 40
:SC_PIX_HEIGHT = 200
:SC_PIX_WIDTH = 320
:SC_SIZE = 8000
:SECTOR = 12
:SEQ = 1
:SEQUENTIAL = 0
:SET_BLOCKED = %01000000
:SET_BOLD = %01000000
:SET_DB_POS = 0
:SET_FROZEN = %00100000
:SET_ICONSON = %00100000
:SET_INPUTCHG = %01000000
:SET_ITALIC = %00010000
:SET_KEYPRESS = %10000000
:SET_LEFTJUST = %10000000
:SET_MENUON = %01000000
:SET_MOUSE = %00100000
:SET_MSE_ON = %10000000
:SET_NOSUPRESS = %00000000
:SET_NOTIMER = %00010000
:SET_OFFBOTTOM = %01000000
:SET_OFFLEFT = %00100000
:SET_OFFMENU = %00001000
:SET_OFFRIGHT = %00010000
:SET_OFFTOP = %10000000
:SET_OUTLINE = %00001000
:SET_PLAINTEXT = 0
:SET_REVERSE = %00100000
:SET_RIGHTJUST = %00000000
:SET_RUNABLE = %10000000
:SET_SUBSCRIPT = %00000010
:SET_SUPERSCRIPT = %00000100
:SET_SUPRESS = %01000000
:SET_UNDERLINE = %10000000
:SHORTCUT = 128
:SPRITE_PICS = $8a00
:STATUS = $0090
:STRUCT_MISMAT = 10
:ST_FLASH = $80
:ST_INVERT = $40
:ST_LD_AT_ADDR = $01
:ST_LD_DATA = $80
:ST_PR_DATA = $40
:ST_WRGS_FORE = $20
:ST_WR_BACK = $40
:ST_WR_FORE = $80
:ST_WR_PR = $40
:SUBSCRIPT_BIT = 1
:SUB_MENU = $80

:SUPERSCRIPT_BIT = 2
:SYSDBI_HEIGHT = 16
:SYSDBI_WIDTH = 6
:SYSTEM = 4
:SYSTEM_BOOT = 12
:SaveFile = $c1ed
:SetDevice = $c2b0
:SetGDirEntry = $c1f0
:SetGEOSDisk = $c1ea
:SetMouse = $fe89
:SetNLQ = $7915
:SetNextFree = $c292
:SetPattern = $c139
:Sleep = $c199
:SlowMouse = $fe83
:SmallPutChar = $c202
:StartASCII = $7912
:StartAppl = $c22f
:StartMouseMode = $c14e
:StartPrint = $7903
:StashRAM = $c2c8
:StopPrint = $7909
:StringFaultVec = $84ab
:SwapRAM = $c2ce
:TAB = 9
:TEMPORARY = 13
:TOTAL_BLOCKS = 664
:TRACK = 9
:TRUE = $ff
:TXT_LN_1_Y = 16
:TXT_LN_2_Y = 32
:TXT_LN_3_Y = 48
:TXT_LN_4_Y = 64
:TXT_LN_5_Y = 80
:TXT_LN_X = 16
:TestPoint = $c13f
:ToBasic = $c241
:ULINEOFF = 15
:ULINEON = 14
:UNDERLINE_BIT = 7
:UNOPENED_VLIR = 7
:UN_CONSTRAINED = %00000000
:UPLINE = 12
:USELAST = 127
:USR = 3
:UnblockProcess = $c10f
:UnfreezeProcess = $c115
:UpdateMouse = $fe86
:UpdateRecordFile = $c295
:UseSystemFont = $c14b

:VERTICAL = %10000000
:VIC_XPOS_OFF = 24
:VIC_YPOS_OFF = 50
:VLIR = 1
:VerWriteBlock = $c223
:VerifyRAM = $c2d1
:VerticalLine = $c121
:WHITE = 1
:WR_PR_ON = $26
:WR_VER_ERR = $25
:WriteBlock = $c220
:WriteFile = $c1f9
:WriteRecord = $c28f
:YELLOW = 7
:YES = 3
:a0 = $fb
:a0H = $fc
:a0L = $fb
:a1 = $fd
:a1H = $fe
:a1L = $fd
:a2 = $70
:a2H = $71
:a2L = $70
:a3 = $72
:a3H = $73
:a3L = $72
:a4 = $74
:a4H = $75
:a4L = $74
:a5 = $76
:a5H = $77
:a5L = $76
:a6 = $78
:a6H = $79
:a6L = $78
:a7 = $7a
:a7H = $7b
:a7L = $7a
:a8 = $7c
:a8H = $7d
:a8L = $7c
:a9 = $7e
:a9H = $7f
:a9L = $7e
:alarmSetFlag = $851c
:alarmTmtVector = $84ad
:alphaFlag = $84b4
:appMain = $849b
:bakclr0 = $d021

:bakclr1 = $d022
:bakclr2 = $d023
:bakclr3 = $d024
:baselineOffset = $0026
:bkvec = $0316
:bootName = $c006
:cardDataPntr = $002c
:cia1base = $dc00
:cia2base = $dd00
:ctab = $d800
:curDevice = $00ba
:curDirHead = $8200
:curDrive = $8489
:curHeight = $0029
:curIndexTable = $002a
:curPattern = $0022
:curRecord = $8496
:curSetWidth = $0027
:curType = $88c6
:currentMode = $002e
:dataDiskName = $8453
:dataFileName = $8442
:dateCopy = $c018
:day = $8518
:dblClickCount = $8515
:dir2Head = $8900
:dirEntryBuf = $8400
:diskBlkBuf = $8000
:diskOpenFlg = $848a
:dispBufferOn = $002f
:dlgBoxRamBuf = $851f
:driveData = $88bf
:driveType = $848e
:extclr = $d020
:faultData = $84b6
:fileHeader = $8100
:fileSize = $8499
:fileTrScTab = $8300
:fileWritten = $8498
:firstBoot = $88c5
:grcntrl1 = $d011
:grcntrl2 = $d016
:grirq = $d019
:grirqen = $d01a
:grmemptr = $d018
:hour = $8519
:i_BitmapUp = $c1ab
:i_FillRam = $c1b4
:i_FrameRectangle = $c1a2
:i_GraphicsString = $c1a8

:i_ImprintRectangle = $c253
:i_MoveData = $c1b7
:i_PutString = $c1ae
:i_RecoverRectangle = $c1a5
:i_Rectangle = $c19f
:iconSelFlag = $84b5
:inputData = $8506
:inputDevName = $88cb
:inputVector = $84a5
:intBotVector = $849f
:intTopVector = $849d
:interleave = $848c
:irqvec = $0314
:isGEOS = $848b
:kernalVectors = $031a
:keyData = $8504
:keyVector = $84a3
:leftMargin = $0035
:lpxpos = $d013
:lpypos = $d014
:maxMouseSpeed = $8501
:mcmclr0 = $d025
:mcmclr1 = $d026
:menuNumber = $84b7
:minMouseSpeed = $8502
:minutes = $851a
:mob0clr = $d027
:mob0xpos = $d000
:mob0ypos = $d001
:mob1clr = $d028
:mob1xpos = $d002
:mob1ypos = $d003
:mob2clr = $d029
:mob2xpos = $d004
:mob2ypos = $d005
:mob3clr = $d02a
:mob3xpos = $d006
:mob3ypos = $d007
:mob4clr = $d02b
:mob4xpos = $d008
:mob4ypos = $d009
:mob5clr = $d02c
:mob5xpos = $d00a
:mob5ypos = $d00b
:mob6clr = $d02d
:mob6xpos = $d00c
:mob6ypos = $d00d
:mob7clr = $d02e
:mob7xpos = $d00e
:mob7ypos = $d00f

:mobbakcol = $d01f
:mobenble = $d015
:mobmcm = $d01c
:mobmobcol = $d01e
:mobprior = $d01b
:mobx2 = $d01d
:moby2 = $d017
:month = $8517
:mouseAccel = $8503
:mouseBottom = $84b9
:mouseData = $8505
:mouseFaultVec = $84a7
:mouseLeft = $84ba
:mouseOn = $0030
:mousePicData = $84c1
:mouseRight = $84bc
:mouseTop = $84b8
:mouseVector = $84a1
:mouseXPos = $003a
:mouseYPos = $003c
:msbxpos = $d010
:msePicPtr = $0031
:nationality = $c010
:nmivec = $0318
:numDrives = $848d
:obj0Pointer = $8ff8
:obj1Pointer = $8ff9
:obj2Pointer = $8ffa
:obj3Pointer = $8ffb
:obj4Pointer = $8ffc
:obj5Pointer = $8ffd
:obj6Pointer = $8ffe
:obj7Pointer = $8fff
:otherPressVec = $84a9
:pressFlag = $0039
:r0 = $0002
:r0H = $03
:r0L = $02
:r10 = $0016
:r10H = $17
:r10L = $16
:r11 = $0018
:r11H = $19
:r11L = $18
:r12 = $001a
:r12H = $1b
:r12L = $1a
:r13 = $001c
:r13H = $1d
:r13L = $1c

:r14 = $001e
:r14H = $1f
:r14L = $1e
:r15 = $0020
:r15H = $21
:r15L = $20
:r1 = $0004
:r1H = $05
:r1L = $04
:r2 = $0006
:r2H = $07
:r2L = $06
:r3 = $0008
:r3H = $09
:r3L = $08
:r4 = $000a
:r4H = $0b
:r4L = $0a
:r5 = $000c
:r5H = $0d
:r5L = $0c
:r6 = $000e
:r6H = $0f
:r6L = $0e
:r7 = $0010
:r7H = $11
:r7L = $10
:r8 = $0012
:r8H = $13
:r8L = $12
:r9 = $0014
:r9H = $15
:r9L = $14
:ramBase = $88c7
:ramExpSize = $88c3
:random = $850a
:rasreg = $d012
:returnAddress = $003d
:rightMargin = $0037
:saveFontTab = $850c
:savedmoby2 = $88bb
:scr80colors = $88bd
:scr80polar = $88bc
:screencolors = $851e
:seconds = $851b
:selectionFlash = $84b3
:sidbase = $d400
:spr0pic = $8a00
:spr1pic = $8a40
:spr2pic = $8a80

:spr3pic = $8ac0
:spr4pic = $8b00
:spr5pic = $8b40
:spr6pic = $8b80
:spr7pic = $8bc0
:string = $0024
:stringX = $84be
:stringY = $84c0
:sysApplData = $8fe8
:sysDBData = $851d
:sysFlgCopy = $c012
:sysRAMFlg = $88c4
:sysVersion = $c011
:turboFlags = $8492
:usedRecords = $8497
:vdcClrMode = $88be
:version = $c00f
:vicbase = $d000
:windowBottom = $0034
:windowTop = $0033
:year = $8516
:zpage = $0000
