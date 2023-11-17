; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "DiskDev_PCDOS"
			t "G3_SymMacExtDisk"

			a "M. Kanet"
			o DISK_BASE

if .p
:C_41			= FALSE
:C_71			= FALSE
:C_81			= FALSE
:RD_41			= FALSE
:RD_71			= FALSE
:RD_81			= FALSE
:RD_NM			= FALSE
:RD_NM_SCPU		= FALSE
:RD_NM_CREU		= FALSE
:RD_NM_GRAM		= FALSE
:RL_41			= FALSE
:RL_71			= FALSE
:RL_81			= FALSE
:RL_NM			= FALSE
:HD_41			= FALSE
:HD_71			= FALSE
:HD_81			= FALSE
:HD_NM			= FALSE
:HD_41_PP		= FALSE
:HD_71_PP		= FALSE
:HD_81_PP		= FALSE
:HD_NM_PP		= FALSE
:FD_41			= FALSE
:FD_71			= FALSE
:FD_81			= FALSE
:FD_NM			= FALSE
:PC_DOS			= TRUE
:IEC_NM			= FALSE
:S2I_NM			= FALSE

.DriveModeFlags		= SET_MODE_SUBDIR

.PART_TYPE		= $05
.PART_MAX		= 0

.dir3Head		= $9b80
.DiskDrvMode		= DrvPCDOS
.Tr_BorderBlock		= 79
.Se_BorderBlock		= 01
.Tr_1stDirSek		= 01
.Se_1stDirSek		= 01
.Tr_1stDataSek		= 32
.Se_1stDataSek		= 00
.Tr_DskNameSek		= 00
.Se_DskNameSek		= 01
.Tr_BootSektor		= 00
.Se_BootSektor		= 01
.MaxDirPages		= 255

;*** TurboDOS-Modus für aktuellen Treiber setzen.
:TDOS_MODE = TDOS_PC_DOS

;*** Einsprungadressen für Bootsektor-Informationen.
.TMP_AREA_SEKTOR	= diskBlkBuf
.RAM_AREA_SEKTOR	= $0000
.TMP_AREA_BUFFER	= curDirHead
.RAM_AREA_BUFFER	= $3e00
.TMP_AREA_BOOT		= diskBlkBuf
.RAM_AREA_BOOT		= $0200
.TMP_AREA_FAT		= $4000
.RAM_AREA_FAT		= $0400
.TMP_AREA_DIR		= $4000
.RAM_AREA_DIR		= $2000
.TMP_AREA_ALIAS		= $4000
.RAM_AREA_ALIAS		= $4000
endif

;*** Sprungtabelle.
:JumpTab		t "-DX_JumpTable"

;*** Erweiterte Sprungtabelle/Speicheradressen.
			t "-DX_JumpTabDDX"

;******************************************************************************
:S_DRIVER_DATA
;******************************************************************************

;*** Variablen für Laufwerkstreiber.
:drvData		t "-DX_DriverData"

;******************************************************************************
:E_DRIVER_DATA
;******************************************************************************

;*** Ungültiger Befehl, Abbruch.
:xIllegalCommand	ldx	#WR_PR_ON
			rts

;*** Einsprungtabelle für externe Routinen
.ReadBlock_DOS		jmp	xReadBlock_DOS
.WriteBlock_DOS		jmp	xIllegalCommand
.SendFCom_CRC1		jmp	SendCom5Byt
.SendFCom_CRC2		jmp	SendComVLen

;*** Include-Dateien.
			t "-DX_IncludeFile"

;*** Erweiterte DOS-Funktionen.
			t "-D3_PCDOS"

if TDOS_PC_DOS = TDOS_ENABLED
;*** Tabellen für TurboDOS-Übertragung.
:NibbleByteH		b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0
:NibbleByteL		b $00,$20,$00,$20,$10,$30,$10,$30
			b $00,$20,$00,$20,$10,$30,$10,$30

;*** TurboDOS-Routine für DOS-Laufwerk.
			t "s.DOS_Turbo.ext"
endif

;******************************************************************************
			g DISK_BASE + DISK_DRIVER_SIZE
;******************************************************************************
