; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "GEOS_QuellCo.ext"
			t "GEOS_9D80.SR.ext"
endif

			n "GEOS_BBG/1.OBJ"
			f $06
			c "KERNAL_9D80 V1.0"
			a "M. Kanet"
			o xVerifyRAM
			p EnterDeskTop
			i
<MISSING_IMAGE_DATA>

;*** Einsprungtabelle RAM-Tools.
:BBG_xVerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			bne	BBG_xDoRAMOp
:BBG_xStashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			bne	BBG_xDoRAMOp
:BBG_xSwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			bne	BBG_xDoRAMOp
:BBG_xFetchRAM		ldy	#%10010001		;RAM-Bereich laden.

:BBG_xDoRAMOp		ldx	#$0d

			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar ?
			bcs	:101			;Nein, Fehler...

			php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA

			jsr	SwapREU_Data		;DoRAMOp-Routine einlesen.
			jsr	$e100			;und ausführen.
			sta	AKKU_Buffer		;AKKU-Register speichern.
			jsr	SwapREU_Data		;DoRAMOp-Routine zurücksetzen.

			pla				;I/O-Bereich deaktivieren.
			sta	CPU_DATA

			plp				;IRQ-Status zurücksetzen.

			lda	AKKU_Buffer
			ldx	#$00			;Flag für "Kein Fehler".
::101			rts

:AKKU_Buffer		b $00

;*** DoRAMOp-Routine aus REU laden.
:SwapREU_Data		tya				;Y-Register zwischenspeichern.
			pha

			lda	#%00111111		;Seite #255 in REU aktivieren.
			sta	$dffe			;Bank #0, $FF00.
			lda	#%00000011
			sta	$dfff

			ldy	#$00			;256 Byte in RAM mit REU
::101			lda	$e100,y			;tauschen.
			tax
			lda	$de00,y			;Dabei wird die erweiterte
			sta	$e100,y			;DoRAMOp-Routine nach $E100
			txa				;eingelesen bzw. der Original-
			sta	$de00,y			;Inhalt wieder zurückgesetzt.
			iny
			bne	:101
			pla
			tay
			rts
