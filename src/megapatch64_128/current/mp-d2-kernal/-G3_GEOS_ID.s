; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Serien-Nummer des GEOS-Systems.
;    Wird nur dann benötigt wenn eine bootfähige MP-Version erstellt werden
;    soll. Wird MP3 über das Update installiert muß die ID nicht geändert
;    werden. GEOS-ID befindet sich in "src.GEOS3_64" bzw. "src.GEOS3_128"

if Flag64_128 = TRUE_C64
			w $0c64
endif
if Flag64_128 = TRUE_C128
			w $c128
endif
