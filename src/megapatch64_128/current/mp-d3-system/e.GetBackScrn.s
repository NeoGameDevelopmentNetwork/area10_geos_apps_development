; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.GetBackScrn"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o LD_ADDR_GETBSCRN

;*** Startbild laden.
:xMP_GETBACKSCRN	php
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif
			lda	$d020
			sta	r0L
			ldy	#$03
::51			lsr	r0L
			rol
			dey
			bpl	:51
if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif
			plp

			jsr	i_UserColor
			b	$00 ! DOUBLE_B,$00,$28 ! DOUBLE_B,$19

			lda	sysRAMFlg
			and	#%00001000
			bne	ViewPaintFile

;*** Kein Startbild, Hintergrund löschen.
:NoStartScreen		lda	dispBufferOn
			pha
			lda	#ST_WR_FORE
			sta	dispBufferOn
			lda	BackScrPattern
			jsr	SetPattern

			jsr	i_Rectangle
			b	$00,$c7
			w	$0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W
			pla
			sta	dispBufferOn

if Flag64_128 = TRUE_C128
			lda	scr80colors
			ldx	graphMode
			bmi	:80
endif
			lda	screencolors
::80			jsr	DirectColor
			jsr	SetADDR_BackScrn	;Speicherbereich wieder
			jmp	SwapRAM

;*** Neue Datei anzeigen.
:ViewPaintFile		MoveB	MP3_64K_SYSTEM,r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_BS_GRAFX
			LoadW	r2,R2_SIZE_BS_GRAFX
			jsr	FetchRAM
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_BS_COLOR
			LoadW	r2,R2_SIZE_BS_COLOR
			jsr	FetchRAM

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			jsr	xGetBackScreenVDC
::40
endif
			jsr	SetADDR_BackScrn	;Speicherbereich wieder
			jmp	SwapRAM

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_GETBSCRN + R2_SIZE_GETBSCRN -1
;******************************************************************************
