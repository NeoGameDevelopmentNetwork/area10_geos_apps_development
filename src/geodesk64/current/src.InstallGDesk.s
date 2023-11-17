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
			n "GO/GEODESK"
			a "Markus Kanet"
			c "InstallDT   V1.0"
			i
<MISSING_IMAGE_DATA>
			z $80

			h "Startet GeoDesk als neue"
			h "DeskTop-Oberfläche..."
			h "GeoDesk64 in GEODESK umbenennen..."

:MainInit		ldy	#$00
			lda	nationality
			bne	:101
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
:V001a0			w $c3cf,$c3d9,$c3f6		;C64/Deutsch.
			w $c3cf,$c3da,$c3f0		;C64/Englisch.

:V001a1			w V001a2,V001b1,V001b2
			w V001a2,V001c1,V001c2

:V001a2			b "GEODESK",NULL

:V001b1			b "Bitte eine Diskette einlegen",NULL
:V001b2			b "die GEODESK enthält",NULL

:V001c1			b "Please insert a disk",NULL
:V001c2			b "with GEODESK",NULL
