; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
endif

			o PRINTBASE
			f AUTO_EXEC
			n "GO64/dualTop"
			a "M. Kanet"
			c "InstallDT   V1.0"
			i
<MISSING_IMAGE_DATA>
			z $40

			h "Startet DualTop als neue"
			h "DeskTop-Oberfläche..."

:MainInit		bit	c128Flag
			bmi	:102

			ldx	#$00
::101			lda	V001a0,x
			sta	r0L,x
			lda	V001a1,x
			sta	r3L,x
			inx
			cpx	#$06
			bne	:101

			ldx	#r3L
			ldy	#r0L
			jsr	CopyString

			ldx	#r4L
			ldy	#r1L
			jsr	CopyString

			ldx	#r5L
			ldy	#r2L
			jsr	CopyString

			lda	#$08
			jsr	SetDevice
::102			jmp	EnterDeskTop

;*** Text für DeskTop-Name.
:V001a0			w $c3cf,$c3d9,$c3f6

:V001a1			w V001b0,V001b1,V001b2

:V001b0			b "DUAL_TOP",NULL
:V001b1			b "Bitte eine Diskette einlegen",NULL
:V001b2			b "die dualTop enthält",NULL
