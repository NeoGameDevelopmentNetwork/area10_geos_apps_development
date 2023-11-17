; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.DvRAM_GSYS"
			t "G3_Data.V.Class"

			o $e100

;*** Neue DORAMOp-Routine. Wird in der REU in
;    Bank #0, ab $FF00 gespeichert. Bei Bedarf wird diese Routine dann
;    nach $E100 eingewechselt und ausgeführt.
:BBG_DoRAMOp		t "-R3_DoRAMOpGRAM"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g $e1ff
;******************************************************************************
