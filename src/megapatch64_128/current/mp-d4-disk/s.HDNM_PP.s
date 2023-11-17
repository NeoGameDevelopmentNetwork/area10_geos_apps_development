; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "DiskDev_HDNM_PP"
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
:HD_NM_PP		= TRUE
:FD_41			= FALSE
:FD_71			= FALSE
:FD_81			= FALSE
:FD_NM			= FALSE
:PC_DOS			= FALSE
:IEC_NM			= FALSE
:S2I_NM			= FALSE

:DriveModeFlags		= SET_MODE_PARTITION ! SET_MODE_SUBDIR ! SET_MODE_FASTDISK

:PART_TYPE		= $04
:PART_MAX		= 254

;--- Ergänzung: 01.03.19/M.Kanet
;ACHTUNG! Der HD-NM-PP-Treiber verwendet dir3Head nicht wie die
;anderen Treiber da er den Bereich durch Programm-Code überschreibt.
;Daher funktioniert z.B. das auslesen des letzten Tracks über den
;BAM-Sektor $01/$02 in dir3Head nicht.
:dir3Head		= $9c80
:DiskDrvMode		= DrvHDNM
:Tr_BorderBlock		= 1
:Se_BorderBlock		= 255
:Tr_1stDirSek		= 1
:Se_1stDirSek		= 1
:Tr_1stDataSek		= 1
:Se_1stDataSek		= 64
:Tr_DskNameSek		= 1
:Se_DskNameSek		= 1
:MaxDirPages		= 255

;*** TurboDOS-Modus für aktuellen Treiber setzen.
:TDOS_MODE = TDOS_HD_NM_PP
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

if TDOS_HD_NM_PP = TDOS_ENABLED
;*** TurboDOS-Routine für HDNM/PP-Laufwerk.
:TurboPP		d "obj.TurboPP"
			t "s.PP_Turbo.ext"
endif

;******************************************************************************
			g DISK_BASE + DISK_DRIVER_SIZE
;******************************************************************************
