; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			t "G3_SymMacExt"

			n "Patch.TaskMan128"
			f APPLICATION
			c "MegaPatch   V3.0"
			a "MegaCom Soft"
			z $c0				;nur GEOS128 80 Zeichen

:Start			lda	#$a9
			sta	TaskManager+3
			jmp	EnterDeskTop
