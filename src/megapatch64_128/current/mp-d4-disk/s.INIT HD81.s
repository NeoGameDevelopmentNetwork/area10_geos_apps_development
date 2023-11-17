; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#144"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Disk"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Disk"
endif

			t "-DD_JumpTab"
			t "-DD_InitHD"

;*** Systemvariablen.
:DriveMode		b $00
:DriveAdr		b $00
:FastPPmode		b $00

;*** TurboPP-Treiber.
:HD_PP			d "DiskDev_HD81_PP"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:END_INIT		g BASE_DDRV_INIT + SIZE_DDRV_INIT
:DSK_INIT_SIZE		= END_INIT - BASE_DDRV_INIT
;******************************************************************************
