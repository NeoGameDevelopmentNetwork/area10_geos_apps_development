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
			t "MacTab"

;--- Laufwerkstreiber konfigurieren.
			t "opt.Disk.Config"
			t "opt.Disk.DOSMode"
endif

;*** GEOS-Header.
			n "obj.Drv_HD41"
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
:HD_41			= TRUE
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

:DISKDRV_MODE		= DrvHD41
:DISKDRV_OPTS		= SET_MODE_PARTITION

:PART_TYPE		= Drv1541
:PART_MAX		= 254

:Tr_1stDirSek		= 18
:Se_1stDirSek		= 1
:Tr_1stDataSek		= 1
:Se_1stDataSek		= 0
:Tr_BorderBlock		= 19
:Se_BorderBlock		= 0

:MaxDirPages		= 18				;max. 18*8 = 144 Dateien.

:Tr_DskNameSek		= 18
:Se_DskNameSek		= 0

;*** TurboDOS-Modus für aktuellen Treiber setzen.
:TDOS_MODE = TDOS_HD_41
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

if TDOS_HD_41  = TDOS_ENABLED
;*** Tabellen für TurboDOS-Übertragung.
:NibbleByteH		b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0
:NibbleByteL		b $00,$20,$00,$20,$10,$30,$10,$30
			b $00,$20,$00,$20,$10,$30,$10,$30

;*** TurboDOS-Routine für HD41-Laufwerk.
			t "s.1581_Turbo.ext"
endif

;******************************************************************************
			g dir3Head
;******************************************************************************
