; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Beim 128er unter IO-Bereich ($d000) Bank 1!

;*** Druckerspooler aktivieren ?
:IntPrnSpool		bit	Flag_Spooler		;DruckerSpooler-Modus testen.
			bpl	:5			; => Nicht aktiv.
			bvs	:5			; => Menü wird gestartet.

			lda	Flag_SpoolCount		;Spooler manuell starten ?
			bmi	:5			; => Ja, Ende...

			lda	Flag_Spooler		;DruckerSpooler-Modus testen.
			and	#%00111111		;Zähler abgelaufen ?
			beq	:5			; => SpoolerMenü starten.

			lda	pressFlag		;Taste gedrückt ?
			and	#%11100000		;Nein, Zähler korrigieren.
			beq	:2

::1			lda	#$00			;Verzögerungsschleife
			sta	:2 +1			;neu initialisieren.
			lda	Flag_SpoolCount		;Zähler für DruckerSpooler
			jmp	:3			;initialisieren.

::2			ldx	#$00			;Verzögerungsschleife.
			dec	:2 +1			;Verzögerung abgelaufen ?
			dec	:2 +1			;Verzögerung abgelaufen ?
			bne	:5			;Nein, weiter...

			lda	Flag_Spooler		;Zähler für DruckerSpooler
			and	#%00111111		;einlesen.
			sec
			sbc	#$01			;Zähler korrigieren.
			beq	:4			; => Abgelaufen, Menü starten.
::3			ora	#%10000000		;Spooler-Flag setzen und Ende.
			b $2c
::4			lda	#%11000000		;Menü-Flag setzen und Ende.
			sta	Flag_Spooler
::5			rts
