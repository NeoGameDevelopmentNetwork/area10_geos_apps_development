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
			n "obj.Drv_SD2IEC"
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
:HD_NM_PP		= FALSE
:FD_41			= FALSE
:FD_71			= FALSE
:FD_81			= FALSE
:FD_NM			= FALSE
:PC_DOS			= FALSE
:IEC_NM			= FALSE
:S2I_NM			= TRUE

:DISKDRV_MODE		= DrvSD2IEC
:DISKDRV_OPTS		= SET_MODE_SUBDIR

:PART_TYPE		= DrvNative
;:PART_MAX		= 0

:Tr_1stDirSek		= 1
:Se_1stDirSek		= 1
:Tr_1stDataSek		= 1
:Se_1stDataSek		= 64
:Tr_BorderBlock		= Tr_1stDataSek
:Se_BorderBlock		= Se_1stDataSek

:MaxDirPages		= 255				;max. 255*8 = 2040 Dateien.

;*** TurboDOS-Modus für aktuellen Treiber setzen.
:TDOS_MODE = TDOS_S2I_NM
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
