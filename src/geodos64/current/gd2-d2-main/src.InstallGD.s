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
			n "GO/BootGD"
			a "M. Kanet"
			c "InstallDT   V1.0"
			i
<MISSING_IMAGE_DATA>
			z $40

			h "Startet GeoDOS als neue"
			h "DeskTop-Oberfläche..."

:MainInit		ldy	#$00
			bit	c128Flag
			bpl	:101
			ldy	#$06
::101			ldx	#$00
::102			lda	V001a0,y
			sta	r0L,x
			lda	V001a1,y
			sta	r3L,x
			iny
			inx
			cpx	#$06
			bne	:102

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
			jmp	EnterDeskTop

;*** Text für DeskTop-Name.
:V001a0			w $c3cf,$c3d9,$c3f6
			w $c9bb,$c9c8,$c9e0

:V001a1			w V001b0,V001b1,V001b2
			w V001c0,V001c1,V001c2

:V001b0			b "BootGD",NULL
:V001b1			b "Bitte eine Diskette einlegen",NULL
:V001b2			b "die BootGD  enthält",NULL

:V001c0			b "BootGD",NULL
:V001c1			b "Bitte eine Diskette mit",NULL
:V001c2			b "BootGD einlegen",NULL
