; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_SCPU"
			t "SymbTab_GTYP"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
endif

;*** GEOS-Header.
			n "obj.Patch_SCPU"
			f DATA

			o BASE_SCPU_DRV

			r BASE_SCPU_DRV +SIZE_SCPU_DRV

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

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_SCPU_DRV +SIZE_SCPU_DRV
;******************************************************************************
