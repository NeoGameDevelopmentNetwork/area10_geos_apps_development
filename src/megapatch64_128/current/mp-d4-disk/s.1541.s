; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "DiskDev_1541"
			t "G3_SymMacExtDisk"

			a "M. Kanet"
			o DISK_BASE

if .p
:C_41			= TRUE
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
:PC_DOS			= FALSE
:IEC_NM			= FALSE
:S2I_NM			= FALSE

:DriveModeFlags		= $00

:PART_TYPE		= $01
:PART_MAX		= 0

;dir3Head		= $9c80
:DiskDrvMode		= Drv1541
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
:TDOS_MODE = TDOS_C_41
endif

;*** Sprungtabelle.
:JumpTab		t "-DX_JumpTable"

;*** Erweiterte Sprungtabelle/Speicheradressen.
			t "-DX_JumpTabDDX"

;*** Include-Dateien.
			t "-DX_IncludeFile"

if TDOS_C_41 = TDOS_ENABLED
;*** Berechnungstabelle für TurboDOS-Byte-Übertragung.
:NibbleByteL		b $0f,$07,$0d,$05,$0b,$03,$09,$01
			b $0e,$06,$0c,$04,$0a,$02,$08;$00
:NibbleByteH		b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0

;*** TurboDOS-Routine für 1541-Laufwerk.
:TurboDOS_1541		d "obj.Turbo41"
;--- Hinweis:
;Füllbytes für SD2IEC damit der GEOS-
;Fastloader erkannt wird.
:TurboDOS_END		s 27*32 - (TurboDOS_END-TurboDOS_1541)
			t "s.1541_Turbo.ext"
endif

;******************************************************************************
			g DISK_BASE + DISK_DRIVER_SIZE
;******************************************************************************
