; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_SCPU"
endif

;*** GEOS-Header.
			n "obj.DvRAM_SRAM"
			t "G3_Data.V.Class"

			h "GEOS-Kernal"
			h "SuperCPU-Funktionen..."

			o BASE_RAM_DRV

;*** 16Bit-DoRAMOp-Routinen.
			t "o.Patch_SRAM.ext"

;*** SuperCPU/RAMCard-Kernal-Einsprünge.
:SCPU_STASH_RAM		= StashRAM_SCPU
:SCPU_FETCH_RAM		= FetchRAM_SCPU
:SCPU_SWAP_RAM		= SwapRAM_SCPU
:SCPU_VERIFY_RAM	= VerifyRAM_SCPU

;*** DoRAMOp-Routine für RAMCard.
			t "-R3_DoRAM_SRAM"
			t "-R3_DoRAMOpSRAM"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g GD_JUMPTAB
;******************************************************************************
