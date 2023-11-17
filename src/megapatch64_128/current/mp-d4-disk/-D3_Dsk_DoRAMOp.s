; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_NM!RL_81!RL_71!RL_41
if Flag64_128!:tmp0 = TRUE_C64!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für RAMLink.
			t "-D3_DoDISK_RLNK"
endif

;******************************************************************************
::tmp1 = RL_NM!RL_81!RL_71!RL_41
if Flag64_128!:tmp1 = TRUE_C128!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für RAMLink.
			t "+D3_DoDISK_RLNK"
endif

;******************************************************************************
::tmp2 = RD_NM_SCPU
if Flag64_128!:tmp2 = TRUE_C64!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für RAMCard.
			t "-D3_DoDISK_SRAM"
			t "-R3_DoDSKOpSRAM"
			t "-R3_SRAM16Bit"
endif

;******************************************************************************
::tmp3 = RD_NM_SCPU
if Flag64_128!:tmp3 = TRUE_C128!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für RAMCard.
			t "+D3_DoDISK_SRAM"
			t "-R3_DoDSKOpSRAM"
			t "-R3_SRAM16Bit"
endif

;******************************************************************************
::tmp4 = RD_NM_CREU
if Flag64_128!:tmp4 = TRUE_C64!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für C=REU.
			t "-D3_DoDISK_CREU"
			t "-R3_DoRAMOpCREU"
endif

;******************************************************************************
::tmp5 = RD_NM_CREU
if Flag64_128!:tmp5 = TRUE_C128!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für C=REU.
			t "+D3_DoDISK_CREU"
			t "-R3_DoRAMOpCREU"
endif

;******************************************************************************
::tmp6 = RD_NM_GRAM
if Flag64_128!:tmp6 = TRUE_C64!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für GeoRAM.
			t "-D3_DoDISK_GRAM"
			t "-R3_DoRAMOpGRAM"
endif

;******************************************************************************
::tmp7 = RD_NM_GRAM
if Flag64_128!:tmp7 = TRUE_C128!TRUE
;******************************************************************************
;*** DoRAMOp-Routine für GeoRAM.
			t "+D3_DoDISK_GRAM"
			t "-R3_DoRAMOpGRAM"
endif
