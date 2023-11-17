; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DDRV"
			t "SymbTab_GRFX"
			t "SymbTab_RLNK"
			t "MacTab"

;--- Laufwerkstreiber konfigurieren.
			t "opt.Disk.Config"
			t "opt.Disk.DOSMode"
endif

;*** GEOS-Header.
			n "obj.Drv_HDNM_PP"
			f DATA

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

:DISKDRV_MODE		= DrvHDNM
:DISKDRV_OPTS		= SET_MODE_PARTITION ! SET_MODE_SUBDIR ! SET_MODE_FASTDISK

:PART_TYPE		= DrvNative
:PART_MAX		= 254

;--- Ergänzung: 01.03.19/M.Kanet
;ACHTUNG!
;Der HD-NM-PP-Treiber nutzt dir3Head,
;überschreibt den Bereich aber mit
;Programm-Code:
;Wird der Bereich von dir3Head durch
;andere Daten überschrieben, dann muss
;am Ende ":Load_dir3Head" aufgerufen
;werden, damit der Bereich aus dem
;Treiber/DACC wieder hergestellt wird.
;:dir3Head		= $9c80

:Tr_1stDirSek		= 1
:Se_1stDirSek		= 1
:Tr_1stDataSek		= 1
:Se_1stDataSek		= 64
:Tr_BorderBlock		= Tr_1stDataSek
:Se_BorderBlock		= Se_1stDataSek

:MaxDirPages		= 255				;max. 255*8 = 2040 Dateien.

;*** TurboDOS-Modus für aktuellen Treiber setzen.
:TDOS_MODE = TDOS_HD_NM_PP
endif

;*** Sprungtabelle.
:JumpTab		t "-DX_JumpTable"

;*** Erweiterte Sprungtabelle/Speicheradressen.
			t "-DX_JumpTabDDX"

;*** Variablen für Laufwerkstreiber.
:S_DRIVER_DATA		t "-DX_DriverData"
:E_DRIVER_DATA

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
