; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Patches für SuperCPU und Speichererweiterungen.
			b $f0,"o.Patch_SRAM",$00
			b $f0,"o.Patch_SCPU",$00

			b $f0,"o.DvRAM_SCPU",$00
			b $f0,"o.DvRAM_CREU",$00
			b $f0,"o.DvRAM_RL",$00
			b $f0,"o.DvRAM_GRAM",$00
			b $f0,"o.DvRAM_GSYS",$00
