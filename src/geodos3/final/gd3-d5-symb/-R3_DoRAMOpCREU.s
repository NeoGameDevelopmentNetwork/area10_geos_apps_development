; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemroutine für Zugriff auf C=REU.
:DoRAMOp_CREU		ldx	#$03			;C64/C=REU-Parameter übergeben.
::1			lda	r0L         ,x
			sta	EXP_BASE1 +2,x
			dex
			bpl	:1

			lda	r3L			;Bank in der C=REU festlegen.
			sta	EXP_BASE1 + 6
			lda	r2L			;Anzahl Bytes festlegen.
			sta	EXP_BASE1 + 7
			lda	r2H
			sta	EXP_BASE1 + 8
			lda	#$00
			sta	EXP_BASE1 + 9		;C=REU-Interrupts verhindern.
			sta	EXP_BASE1 +10		;Parameterwerte hochzählen.
			sty	EXP_BASE1 + 1		;Befehlsbyte setzen.

::2			lda	EXP_BASE1 + 0		;Job ausführen.
			and	#%01100000		;Job beendet?
			beq	:2			; => Nein, weiter...
			ldx	#NO_ERROR
			rts
