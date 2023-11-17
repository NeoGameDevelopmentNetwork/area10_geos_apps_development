﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDDrv"

;*** GEOS-Header.
			n "DiskDev_SD2IEC"
			t "G3_Sys.Author"
			f 3 ;DATA

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
:PC_DOS			= FALSE
:IEC_NM			= FALSE
:S2I_NM			= TRUE

:DriveModeFlags		= $00 ! SET_MODE_SUBDIR
;--- Ergänzung: 17.10.18/M.Kanet
;SET_MODE_FASTDISK muss noch mit der SuperCPU verifiziert werden.
; ! SET_MODE_FASTDISK

:PART_TYPE		= $04
:PART_MAX		= 1

:dir3Head		= $9c80
:DiskDrvMode		= DrvSD2IEC
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
:TDOS_MODE = TDOS_S2I_NM
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

if TDOS_S2I_NM = TDOS_ENABLED
;*** Tabellen für TurboDOS-Übertragung.
:NibbleByteH		b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0
:NibbleByteL		b $00,$20,$00,$20,$10,$30,$10,$30
			b $00,$20,$00,$20,$10,$30,$10,$30

;*** TurboDOS-Routine für SD2IEC-Laufwerk.
;--- Ergänzung: 17.10.18/M.Kanet
;Das SD2IEC verwendet das TurboDOS nur um die passenden Antworten auf die
;TurboDOS-Befehle geben zu können. Der Code wird nicht im SD2IEC gespeichert
;und auch nicht ausgefühert. Siehe auch Routine "-TD_InitTurbo".
;Es wird trotzdem über die TurboDOS-Befehle mit dem Laufwerk kommuniziert.
;Um alle 255 Spuren ansprechen zu können nutzt der Treiber aber den
;Firmware-Einsprung im SD2IEC für den ReadSektor-Befehl der 1571.
:TD_RdSekData71 = $04af
;:TurboDOS_SD2IEC	d "obj.Turbo81"
			t "s.1581_Turbo.ext"
endif

;******************************************************************************
			g dir3Head
;******************************************************************************
