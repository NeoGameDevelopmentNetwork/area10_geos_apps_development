; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GEOS.Editor.
			b $f0,"s.MP3.Edit.1",$00
			b $f0,"s.MP3.Edit.2",$00

;--- SD2IEC-DiskImage-Wechsel für C128.
if COMP_SYS = TRUE_C128
			b $f0,"s.MP3.Edit.3",$00
endif
