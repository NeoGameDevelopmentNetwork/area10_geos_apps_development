; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.Patch_SRAM"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o $d300

			r $d3ff

			h "MegaPatch-Kernal"
			h "SuperCPU-Funktionen..."

;******************************************************************************
;RAM_Type = RAM_SCPU
;******************************************************************************
.StashRAM_SCPU		jmp	SCPU_STASH_RAM
.FetchRAM_SCPU		jmp	SCPU_FETCH_RAM
.SwapRAM_SCPU		jmp	SCPU_SWAP_RAM
.VerifyRAM_SCPU		jmp	SCPU_VERIFY_RAM

;*** Speicherbank berechnen.
:DefBankAdr		lda	RamBankFirst +1		;Speicherbank berechnen.
			clc
			adc	r3L
			rts

			t "-R3_SRAM16Bit"
