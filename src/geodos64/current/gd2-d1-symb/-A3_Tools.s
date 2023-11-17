; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_TOOLS		OPEN_MAIN

			b $f0,"src.InstallGD",$00
			b $f0,"src.InstallDT",$00
			b $f0,"src.InstallD2T",$00
			b $f0,"src.MakeInstall",$00
