; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS128.SetTask"
			c "TaskManSet V1.0"
			a "Kanet/MegaCom"
			t "G3_SymMacExt"

			f $06
			z $40

			i
<MISSING_IMAGE_DATA>

;*** TaskManager immer starten
:PatchTaskMan		lda	c128Flag
			bpl	:1
			lda	#$ea
			sta	TaskManager+3
			sta	TaskManager+4
::1			jmp	EnterDeskTop
