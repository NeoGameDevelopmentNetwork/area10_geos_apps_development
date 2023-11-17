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
			n "obj.Patch_SCPU"
			t "G3_Data.V.Class"

			h "GEOS-Kernal"
			h "SuperCPU-Funktionen..."

			o BASE_SCPU_DRV

;*** 16-Bit-SuperCPU-Routinen.
			t "-R3_SCPU16Bit"

;******************************************************************************
;*** SuperCPU-Routinen.
;******************************************************************************
.sClearRam		= s_ClearRam
.sFillRam		= s_FillRam
.si_MoveData		= s_i_MoveData
.sMoveData		= s_MoveData
.sInitForIO		= s_InitForIO
.sDoneWithIO		= s_DoneWithIO
.sSCPU_OptOn		= s_SCPU_OptOn
.sSCPU_OptOff		= s_SCPU_OptOff
.sSCPU_SetOpt		= s_SCPU_SetOpt
;******************************************************************************
