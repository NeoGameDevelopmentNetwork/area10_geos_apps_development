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
			n "obj.Drv_PCDOS"
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
:PC_DOS			= TRUE
:IEC_NM			= FALSE
:S2I_NM			= FALSE

:DISKDRV_MODE		= DrvPCDOS
:DISKDRV_OPTS		= SET_MODE_SUBDIR

:PART_TYPE		= DrvPCDOS
;:PART_MAX		= 0

.Tr_1stDirSek		= 1
.Se_1stDirSek		= 1
.Tr_1stDataSek		= 32
.Se_1stDataSek		= 0
;:Tr_BorderBlock	= 79
;:Se_BorderBlock	= 1
;:Tr_BootSektor		= 0
;:Se_BootSektor		= 1

:MaxDirPages		= 255				;max. 255*8 = 2040 Dateien.

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

;*** Variablen für Laufwerkstreiber.
:S_DRIVER_DATA		t "-DX_DriverData"
:E_DRIVER_DATA

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
