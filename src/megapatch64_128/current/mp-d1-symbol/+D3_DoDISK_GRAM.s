; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;Übergabe: r0   = Startadresse C128-RAM.
;          r1   = Startadresse REU.
;          r2   = Anzahl Bytes.
;          r3L  = Speicherbank.
;          yReg = Job-Code.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:DoRAMOp_DISK		php				;IRQ sperren.
			sei
			lda	MMU
			pha
			lda	#$7e
			sta	MMU

			lda	GeoRAMBSize		;Bank-Größentyp einlesen.
			jsr	DoRAMOp_GRAM		;Job ausführen.
			tay

			pla
			sta	MMU
			plp

			tya				;IRQ-Status zurücksetzen.
;			ldx	#NO_ERROR		;Flag für "Kein Fehler".
			rts
