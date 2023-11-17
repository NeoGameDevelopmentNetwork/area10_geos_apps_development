; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Systemlabels MegaPatch
; Version 09.08.2019

:DskDrvBaseL		= $9f7e
:DskDrvBaseH		= $9f82
:doubleSideFlg		= $9f86
:drivePartData		= $9f8a
:RealDrvType		= $9f8e
:RealDrvMode		= $9f92
:RamBankInUse		= $9f96
:RamBankFirst		= $9fa6
:GEOS_RAM_TYP		= $9fa8
:RAM_SCPU		= $10
:RAM_BBG		= $20
:RAM_GEORAM		= $20
:RAM_REU		= $40
:RAM_RL			= $80
:MP3_64K_SYSTEM		= $9fa9
:MP3_64K_DATA		= $9faa
:MP3_64K_DISK		= $9fab
:Flag_Optimize		= $9fac
:millenium		= $9fad
:Flag_LoadPrnt		= $9fae
:PrntFileNameRAM	= $9faf
:Flag_Spooler		= $9fc0
:Flag_SpoolMinB		= $9fc1
:Flag_SpoolMaxB		= $9fc2
:Flag_SpoolADDR		= $9fc3
:Flag_SpoolCount	= $9fc6
:Flag_SplCurDok		= $9fc7
:Flag_SplMaxDok		= $9fc8
:Flag_TaskAktiv		= $9fc9
:Flag_TaskBank		= $9fca
:Flag_ExtRAMinUse	= $9fcb
:Flag_ScrSvCnt		= $9fcc
:Flag_ScrSaver		= $9fcd
:Flag_CrsrRepeat	= $9fce
:BackScrPattern		= $9fcf
:Flag_SetColor		= $9fd0
:SET_COLOR_OFF		= $00
:SET_COLOR_DLGBOX	= $40
:SET_COLOR_ON		= $80
:Flag_ColorDBox		= $9fd1
:Flag_IconMinX		= $9fd2
:Flag_IconMinY		= $9fd3
:Flag_IconDown		= $9fd4
; :Flag_DBoxType	= $9fd5				;Used by kernal only.
; :Flag_GetFiles	= $9fd6				;Used by kernal only.
:DB_GFileType		= $9fd7
:DB_GFileClass		= $9fd8
:DB_GetFileEntry	= $9fda
:DB_StdBoxSize		= $9fdb
:Flag_SetMLine		= $9fe1
:Flag_MenuStatus	= $9fe2
:DM_LastEntry		= $9fe3
:DM_LastNumEntry	= $9fe9
:MP3_COLOR_DATA		= $9fea
:C_Balken		= $9fea
:C_Register		= $9feb
:C_RegisterOff		= $9fec
:C_RegisterBack		= $9fed
:C_Mouse		= $9fee
:C_DBoxTitel		= $9fef
:C_DBoxBack		= $9ff0
:C_DBoxDIcon		= $9ff1
:C_FBoxTitel		= $9ff2
:C_FBoxBack		= $9ff3
:C_FBoxDIcon		= $9ff4
:C_FBoxFiles		= $9ff5
:C_WinTitel		= $9ff6
:C_WinBack		= $9ff7
:C_WinShadow		= $9ff8
:C_WinIcon		= $9ff9
:C_PullDMenu		= $9ffa
:C_InputField		= $9ffb
:C_InputFieldOff	= $9ffc
:C_GEOS_BACK		= $9ffd
:C_GEOS_FRAME		= $9ffe
:C_GEOS_MOUSE		= $9fff

; DoDlgBox
:DB_SET_COLOR_ON	= %01000000
:DB_SET_COLOR_OFF	= %00000000
:DUMMY			= $08
:DBUSRFILES		= $09
:DBSETCOL		= $0a
:DBSELECTPART		= %10000000
:DBSETDRVICON		= %01000000

; MP3-Routinen
:i_UserColor		= $c0dc
:i_ColorBox		= $c0df
:DirectColor		= $c0e2
:RecColorBox		= $c0e5
:GetBackScreen		= $c0e8
:ResetScreen		= $c0eb
:GEOS_InitSystem	= $c0ee
:PutKeyInBuffer		= $c0f1
:SCPU_Pause		= $c0f4
; :SCPU_OptOn		= $c0f7
; :SCPU_OptOff		= $c0fa
; :SCPU_SetOpt		= $c0fd

; Register-Menu
:BOX_USER		= $01
:BOX_USER_VIEW		= $02
:BOX_USEROPT		= $03
:BOX_USEROPT_VIEW	= $04
:BOX_FRAME		= $05
:BOX_ICON		= $06
:BOX_ICON_VIEW		= $07
:BOX_OPTION		= $08
:BOX_OPTION_VIEW	= $09
:BOX_STRING		= $0a
:BOX_STRING_VIEW	= $0b
:BOX_NUMERIC		= $0c
:BOX_NUMERIC_VIEW	= $0d
:NUMERIC_LEFT		= %00000000
:NUMERIC_RIGHT		= %10000000
:NUMERIC_SETSPC		= %00000000
:NUMERIC_SET0		= %01000000
:NUMERIC_BYTE		= %00000000
:NUMERIC_WORD		= %00100000
:DoRegister		= $6d00
:ExitRegisterMenu	= $6d03
:RegisterInitMenu	= $6d06
:RegisterUpdate		= $6d09
:RegisterAllOpt		= $6d0c
:RegisterNextOpt	= $6d0f
:RegDrawOptFrame	= $6d12
:RegClrOptFrame		= $6d15
:RegisterSetFont	= $6d18
:RegisterAktiv		= $6d1b

; Ausgelagerte MP3 Routinen.
:SetADDR_TaskMan	= $cfed
:SetADDR_Register	= $cfe6
:SetADDR_EnterDT	= $cfe3
; :SetADDR_ToBASIC	= $cfe0
; :SetADDR_PANIC	= $cfdd
; :SetADDR_GetNxDay	= $cfda
; :SetADDR_DoAlarm	= $cfd7
; :SetADDR_GetFiles	= $cfd4
; :SetADDR_GFilData	= $cfd1
; :SetADDR_GFilMenu	= $cfce
; :SetADDR_DB_SCRN	= $cfcb
; :SetADDR_DB_GRFX	= $cfc8
; :SetADDR_DB_COLS	= $cfc5
; :SetADDR_BackScrn	= $cfc2
; :SetADDR_ScrSaver	= $cfbf
; :SetADDR_Spooler	= $cfbc
; :SetADDR_PrnSpool	= $cfb9
; :SetADDR_PrnSpHdr	= $cfb6
; :SetADDR_Printer	= $cfb3
; :SetADDR_PrntHdr	= $cfb0

; Startadresse Register Menü.
:LD_ADDR_REGISTER	= $6d00

; Startadresse TaskManager
:LD_ADDR_TASKMAN	= $4000

; Adresse/Größe des Hintergrundbildes im DACC.
:R2_ADDR_BS_COLOR	= $5a28
:R2_ADDR_BS_GRAFX	= $5e10
:R2_SIZE_BS_COLOR	= $03e8
:R2_SIZE_BS_GRAFX	= $1f40

; MP3 Laufwerkstreiber
:OpenRootDir		= $9050
:OpenSubDir		= $9053
:GetBAMBlock		= $9056
:PutBAMBlock		= $9059
:GetPDirEntry		= $905c
:ReadPDirEntry		= $905f
:OpenPartition		= $9062
:SwapPartition		= $9065
:GetPTypeData		= $9068
:SendFloppyCom		= $906b
:DiskDrvTypeExt		= $9074
:DDRV_EXT_DATA1		= $907a
;DDRV_EXT_DATA2		= $907b
:InitForDskDvOp		= $907c
:DoneWithDskDvOp	= $907f
:dir3Head		= $9c80

; Verschiedene Label
:OS_VARS		= $8000				;OS variable base
:MP3_CODE		= $c014

; Erweiterte Diskettenfehlermeldungen
:NO_ERROR		= $00
; :NO_BLOCKS		= $01
:INV_TRACK		= $02
; :INSUFF_SPACE		= $03
:FULL_DIRECTORY		= $04
:FILE_NOT_FOUND		= $05
:BAD_BAM		= $06
; :UNOPENED_VLIR	= $07
; :INV_RECORD		= $08
; :OUT_OF_RECORDS	= $09
; :STRUCT_MISMAT	= $0a				;In TopSym definiert.
; :BFR_OVERFLOW		= $0b
:CANCEL_ERR		= $0c
:DEV_NOT_FOUND		= $0d
; :INCOMPATIBLE		= $0e				;In TopSym definiert.
; :HDR_NOT_THERE	= $20
:NO_SYNC		= $21
; :DBLK_NOT_THERE	= $22
; :DAT_CHKSUM_ERR	= $23
;WR_VER_ERR		= $25
:WR_PR_ON		= $26
; :HDR_CHKSUM_ERR	= $27
; :DSK_ID_MISMAT	= $29
; :BYTE_DEC_ERR		= $2e
; :NO_PARTITION		= $30
; :PART_FORMAT_ERR	= $31
; :ILLEGAL_PARTITION	= $32
; :NO_PART_FD_ERR	= $33
; :ILLEGAL_DEVICE	= $40
:NO_FREE_RAM		= $60
; :DOS_MISMATCH		= $73

; Definition der Laufwerkstypen.
:DRIVE_MODES		= %00000111
:Drv1541		= $01
:Drv1571		= $02
:Drv1581		= $03
:DrvIECBNM		= $04
:DrvSD2IEC		= $04
:DrvNative		= $04
:DrvPCDOS		= $05
:Drv81DOS		= $05

:DrvShadow		= %01000000
:DrvShadow1541		= DrvShadow ! Drv1541
;DrvShadow1571		= DrvShadow ! Drv1571
;DrvShadow1581		= DrvShadow ! Drv1581
;DrvShadowNM		= DrvShadow ! DrvNative

:DrvRAM			= %10000000
:DrvRAM1541		= DrvRAM ! Drv1541
:DrvRAM1571		= DrvRAM ! Drv1571
:DrvRAM1581		= DrvRAM ! Drv1581
:DrvRAMNM		= DrvRAM ! DrvNative
:DrvRAMNM_CREU		= %10100000 ! DrvNative
:DrvRAMNM_GRAM		= %10110000 ! DrvNative
:DrvRAMNM_SCPU		= %11000000 ! DrvNative

:DrvFD			= %00010000
:DrvFD41		= DrvFD ! Drv1541
:DrvFD71		= DrvFD ! Drv1571
:DrvFD81		= DrvFD ! Drv1581
:DrvFD2			= DrvFD
:DrvFD4			= DrvFD
:DrvFDNM		= DrvFD ! DrvNative
:DrvFDDOS		= DrvFD ! DrvPCDOS
:DrvHD			= %00100000
:DrvHD41		= DrvHD ! Drv1541
:DrvHD71		= DrvHD ! Drv1571
:DrvHD81		= DrvHD ! Drv1581
:DrvHDNM		= DrvHD ! DrvNative
:DrvRAMLink		= %00110000
:DrvRL41		= DrvRAMLink ! Drv1541
:DrvRL71		= DrvRAMLink ! Drv1571
:DrvRL81		= DrvRAMLink ! Drv1581
:DrvRLNM		= DrvRAMLink ! DrvNative

:DrvCMD			= %00110000

; Definition der Laufwerks-Modi.
:SET_MODE_PARTITION	= %10000000
:SET_MODE_SUBDIR	= %01000000
:SET_MODE_FASTDISK	= %00100000
:SET_MODE_SRAM		= %00010000
:SET_MODE_CRAM		= %00001000
:SET_MODE_GRAM		= %00000100
:SET_MODE_SD2IEC	= %00000010

;*** CBM-Dateitypen.
:FMODE_CLOSED		= %10000000
:FMODE_WRPROT		= %01000000
:FTYPE_MODES		= %00000111
;FTYPE_DEL		= $00
;FTYPE_SEQ		= $01
;FTYPE_PRG		= $02
;FTYPE_USR		= $03
;FTYPE_REL		= $04
:FTYPE_DIR		= $06

;*** Sonstige C64-System-Adressen.
:zpage			= $0000
