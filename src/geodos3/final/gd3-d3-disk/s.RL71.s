; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDDrv"

;*** GEOS-Header.
			n "DiskDev_RL71"
			t "G3_Sys.Author"
			f 3 ;DATA

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_RLNK"
endif

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
:RL_71			= TRUE
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
:PC_DOS			= FALSE
:IEC_NM			= FALSE
:S2I_NM			= FALSE

:DriveModeFlags		= SET_MODE_PARTITION ! SET_MODE_FASTDISK

:PART_TYPE		= $02
:PART_MAX		= 31

:dir3Head		= $9c80
:DiskDrvMode		= DrvRL71
:Tr_BorderBlock		= 19
:Se_BorderBlock		= 0
:Tr_1stDirSek		= 18
:Se_1stDirSek		= 1
:Tr_1stDataSek		= 1
:Se_1stDataSek		= 0
:Tr_DskNameSek		= 18
:Se_DskNameSek		= 0
:MaxDirPages		= 18

;*** TurboDOS-Modus für aktuellen Treiber setzen.
:TDOS_MODE = TDOS_RL_71
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

;*** Include-Dateien.
			t "-DX_IncludeFile"

;******************************************************************************
			g dir3Head
;******************************************************************************
