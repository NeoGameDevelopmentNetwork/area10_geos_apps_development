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
endif

;*** GEOS-Header.
			n "obj.Patch_SRAM"
			f DATA

			o SRAM_USER_PAGE

			r SRAM_USER_PAGE +255

;*** Sprungtabelle für 16Bit-DoRAMOp.
:SCPU_STASH		jmp	SCPU_X16_STASH
:SCPU_FETCH		jmp	SCPU_X16_FETCH
:SCPU_SWAP		jmp	SCPU_X16_SWAP
:SCPU_VERIFY		jmp	SCPU_X16_VERIFY

;*** SuperCPU 16Bit-DoRAMOp-Routinen.
			t "-R3_SRAM16Bit"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g SRAM_USER_PAGE +255
;******************************************************************************
