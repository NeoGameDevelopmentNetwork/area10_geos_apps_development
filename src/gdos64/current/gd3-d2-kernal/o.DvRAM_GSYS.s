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
			t "SymbTab_GTYP"
			t "MacTab"
endif

;*** GEOS-Header.
			n "obj.DvRAM_GSYS"
			f DATA

			o $e100

			r $e1ff

;*** Neue DORAMOp-Routine. Wird in der REU in
;    Bank #0, ab $FE00 gespeichert. Bei Bedarf wird diese Routine dann
;    nach $E100 eingewechselt und ausgeführt.
:BBG_DoRAMOp		t "-R3_DoRAMOpGRAM"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g $e1ff
;******************************************************************************
