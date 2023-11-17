; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** HD-Kabel deaktivieren. Ist notwendig, da sonst die
;    Kommunikation des TurboDOS versagt.
;--- Ergänzung: 09.09.18/M.Kanet
;Code ist deaktiviert. TurboDOS+PP-Kabel funktioniert.
:InitDeviceHD		lda	Device_RL		;RAMLink verfügbar ?
			beq	:52			;=> Nein, weiter...
			jsr	Strg_MgrHD		;Meldung ausgeben und
			jsr	:51			;Kabel abschalten.
			jmp	Strg_OK

::51			ldx	#<AT_P0			;Zeiger auf "P0"-Befehl.
			ldy	#>AT_P0
			stx	a7L
			sty	a7H
			ldx	#$0b			;RL_DOS-Befehlsabfrage.
			pha				;Dummy-Adresse auf Stack speichern
			pha				;und Fehlerroutine aufufen. RL-DOS
			jmp	($0300)			;testet dann auf die erweiterten
::52			rts				;RL-Befehle und führt diesen aus.

;*** Befehl zum deaktivieren des HD-Kabels.
:AT_P0			b $40,$50,$30,$00		;"P0"-Befehl.
