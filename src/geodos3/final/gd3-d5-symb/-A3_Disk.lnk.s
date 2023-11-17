; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- MegaLinker aufrufen.
:LnkDiskDrvFile		b $f5
			b $f0,"lnk.GD.DISK",$00
			b $f4
