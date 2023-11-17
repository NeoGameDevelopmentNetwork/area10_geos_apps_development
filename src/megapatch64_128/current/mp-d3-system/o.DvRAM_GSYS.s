; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.DvRAM_BBG.2"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o $e100

			h "MegaPatch-Kernal"
			h "BBG-Funktionen..."

;*** Neue DORAMOp-Routine. Wird in der REU in
;    Bank #0, ab $FF00 gespeichert. Bei Bedarf wird diese Routine dann
;    nach $E100 eingewechselt und ausgeführt.
:BBG_DoRAMOp		t "-R3_DoRAMOpGRAM"
