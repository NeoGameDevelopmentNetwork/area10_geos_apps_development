; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.DvRAM_BBG.1"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o BASE_RAM_DRV

			r BASE_RAM_DRV +SIZE_RAM_DRV

			h "MegaPatch-Kernal"
			h "BBG-Funktionen..."

;******************************************************************************
;RAM_Type = RAM_BBG
;******************************************************************************
.DvRAM_GRAM_START
;*** Einsprungtabelle RAM-Tools.
:xVerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			b $2c
:xStashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			b $2c
:xSwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			b $2c
:xFetchRAM		ldy	#%10010001		;RAM-Bereich laden.

:xDoRAMOp		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	ramOpErr		; => Nein, Fehler...

;--- Einsprung für BootGEOS ($c000).
:xDoRAMOp_NoChk		php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#$7e
			sta	MMU
endif

			jsr	SwapBBG_Data		;DoRAMOp-Routine einlesen.
.DvRAM_GRAM_BSIZE	lda	#$ff			;Bank-Größe an DoRAMOp über-
							;geben. Wird beim Systemstart
							;über GEOS.BOOT gesetzt.
			jsr	$e100			;DoRAMOp ausführen.
			tay				;AKKU-Register speichern.
			jsr	SwapBBG_Data		;DoRAMOp-Routine zurücksetzen.

if Flag64_128 = TRUE_C64
			pla				;I/O-Bereich deaktivieren.
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	MMU
endif

			plp				;IRQ-Status zurücksetzen.

			tya
			ldx	#$00			;Flag für "Kein Fehler".
:ramOpErr		rts

;*** DoRAMOp-Routine aus GeoRAM laden.
:SwapBBG_Data		tya				;Y-Register zwischenspeichern.
			pha

.DvRAM_GRAM_SYSP	lda	#%00111110		;Seite #254 in REU aktivieren.
			sta	$dffe			;Bank #0, $FE00.
.DvRAM_GRAM_SYSB	lda	#%00000011
			sta	$dfff

			ldy	#$00			;256 Byte in RAM mit REU
::51			ldx	$e100,y			;tauschen.
			lda	$de00,y			;Dabei wird die erweiterte
			sta	$e100,y			;DoRAMOp-Routine nach $E100
			txa				;eingelesen bzw. der Original-
			sta	$de00,y			;Inhalt wieder zurückgesetzt.
			iny
			bne	:51

			pla
			tay
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_RAM_DRV_END
;******************************************************************************
