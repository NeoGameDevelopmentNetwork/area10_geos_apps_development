; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_HELP		OPEN_MAIN

			b $f0,"src.LoadGeoHelp",$00
			b $f0,"src.GeoHelpView",$00
			b $f0,"src.GeoHelp.Edit",$00
