; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Tools/GeoRAM.
;
; Wird nur innerhalb des Kernal oder
; dem RAM-Treiber verwendet.
;
;"-R3_DoRAM_GRAM"
; Diese Routine ist die Kernal-Routine
; für die ":DoRAMOp"-Funktionen.
;
;"-R3_DoRAM_GUPD"
; Diese Routine enthält eine temporäre
; ":DoRAMOp"-Routine für "GD.UPDATE",
; da die Original-GEOS-Routine Daten
; in einem anderen Format speichert.
; Siehe Kommentare in "-G3_UpdRAMOp".
;
.DvRAM_GRAM_START
:xVerifyRAM		ldy	#jobVerify		;RAM-Bereich vergleichen.
			b $2c
:xStashRAM		ldy	#jobStash		;RAM-Bereich speichern.
			b $2c
:xSwapRAM		ldy	#jobSwap		;RAM-Bereich tauschen.
			b $2c
:xFetchRAM		ldy	#jobFetch		;RAM-Bereich laden.

:xDoRAMOp		ldx	#$0d			;DEV_NOT_FOUND
			lda	r3L
			cmp	ramExpSize		;Speicherbank verfügbar?
			bcs	ramOpErr		; => Nein, Fehler...

;--- Einsprung für BootGEOS ($c000).
:xDoRAMOp_NoChk		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	SwapBBG_Data		;DoRAMOp-Routine einlesen.
.DvRAM_GRAM_BSIZE	lda	#$ff			;Bank-Größe an DoRAMOp über-
							;geben. Wird beim Systemstart
							;über GEOS.BOOT gesetzt.
			jsr	$e100			;DoRAMOp ausführen.
			tay				;AKKU-Register speichern.
			jsr	SwapBBG_Data		;DoRAMOp-Routine zurücksetzen.

			pla				;I/O-Bereich deaktivieren.
			sta	CPU_DATA

			plp				;IRQ-Status zurücksetzen.

			tya
			ldx	#NO_ERROR		;Flag für "Kein Fehler".
:ramOpErr		rts

;*** DoRAMOp-Routine aus GeoRAM laden.
:SwapBBG_Data		tya				;Y-Register zwischenspeichern.
			pha

;--- Hinweis:
;In Bit 0-5 von $DFFE finden sich die
;unteren 6 Bit der Page, in Bit 0+1 von
;$DFFF die oberen 2 Bit der Page.
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
