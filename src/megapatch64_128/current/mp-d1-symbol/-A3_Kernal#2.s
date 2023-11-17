; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if COMP_SYS = TRUE_C64
;--- Kernal
			b $f0,"src.GEOS_MP3.64",$00	;Kernel
			b $f0,"src.MakeKernal",$00	;Kernel-Packer
endif

if COMP_SYS = TRUE_C128
;--- Kernal
			b $f0,"src.GEOS_MP3.128",$00	;Kernel Bank1
			b $f0,"src.G3_RBasic128",$00	;Externe ToBasic-Routine Bank0
			b $f0,"src.G3_B0_128",$00	;Kernel Bank0
			b $f0,"src.MakeKernal",$00	;Kernel-Packer
endif
