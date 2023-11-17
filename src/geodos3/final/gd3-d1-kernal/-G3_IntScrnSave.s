; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Bildschirmschoner aktivieren ?
:IntScrnSave		bit	Flag_ScrSaver		;ScreenSaver-Modus testen.
			bmi	:5			; => Nicht aktiv.
			bvs	:6			; => Neu initialisieren.
			beq	:6			; => ScreenSaver aufrufen.

			lda	inputData
			eor	#%11111111		;Mausbewegung ?
			bne	:6			;Ja, Zähler neu setzen.

			lda	pressFlag		;Taste gedrückt ?
			and	#%11100000		;Nein, Zähler korrigieren.
			beq	:1

::6			ldx	Flag_ScrSvCnt		;Zähler neu initialisieren.
			stx	:1 +1
			stx	:3 +1
			ldx	#%00100000		;Flag für "Zähler läuft".
			bne	:4

::1			ldx	#$06
			beq	:2
			dec	:1 +1
			rts

::2			dec	:1 +1
::3			ldx	#$06
			beq	:4
			dec	:3 +1
			rts

::4			stx	Flag_ScrSaver		;$00 = ScreenSaver starten.
::5			rts
