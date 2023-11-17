; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Kernal
			b $f0,"s.GD3_KERNAL",$00	;Kernel
			b $f0,"src.MakeKernal",$00	;Kernel-Packer
