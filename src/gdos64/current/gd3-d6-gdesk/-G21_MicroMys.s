; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** MouseWheel testen.
:GD_MICROMYS		bit	GD_MWHEEL		;Mausrad aktiviert?
			bpl	:exit			; => Nein, Ende...

			lda	WM_STACK		;Fenster aktiv?
			beq	:exit
			bmi	:exit			; => Nein, Ende...

			lda	GD_MWHEEL_DELAY		;Verzögerung aktiv?
			beq	:0			; => Nein, weiter...
			dec	GD_MWHEEL_DELAY		; => Ja, Zähler aktualisieren.
			jmp	:exit			;Ende...

::0			ldx	CPU_DATA		;I/O-Bereich aktivieren.
			lda	#IO_IN
			sta	CPU_DATA

			lda	#%11111111
			sta	cia1base +0
			ldy	cia1base +1

			stx	CPU_DATA		;I/O-Bereich abschalten.

			cpy	#%11111111		;Taste gedrückt?
			beq	:exit			; => Nein, Ende...

			lda	GD_MWHEEL		;MicroMys-Optionen einlesen.

			cpy	#%11111011		;Mausrad "Up"?
			beq	:1			; => Ja, weiter...
			cpy	#%11110111		;Mausrad "Down"?
			bne	:exit			; => Nein, Ende...

			and	#%00001100		;Zeiger auf Tastentabelle
			lsr				;berechnen.
			lsr
			clc
			adc	#$04
			bne	:2

::1			and	#%00000011

::2			tax
			and	#%00000011		;Modus 0/4?
			bne	:3			; => Nein, weiter...

			ldy	#3			;Taste 3x ausführen.
			b $2c
::3			ldy	#1			;Taste 1x ausführen.
			lda	GD_MWHEEL_KEYS,x	;Tastencode einlesen.

::loop			pha
			jsr	PutKeyInBuffer		;Taste in Tastenspeicher schreiben.
			pla
			dey				;Alle Wiederholungen ausgeführt?
			bne	:loop			; => Nein, weiter...

			lda	GD_MWHEEL		;Verzögerungszähler setzen.
			and	#%00110000

			lsr				;Verzögerung / 16.
			lsr				;(Bit 4+5 nach Bit 0+1)
;			lsr
;			lsr

;			asl				;Verzögerung x 4.
;			asl

			sta	GD_MWHEEL_DELAY

::exit			rts

;*** Tastentabelle.
:GD_MWHEEL_KEYS		b $10				;Cursor Up x3.
			b $10				;Cursor Up.
			b $08				;Cursor Left.
			b $90				;CBM + SHIFT + Cursor Up.

			b $11				;Cursor Down x3.
			b $11				;Cursor Down.
			b $1e				;Cursor Right.
			b $91				;CBM + Cursor Down.

;*** Verzögerungszähler.
:GD_MWHEEL_DELAY	b $00				;Verzögerung.
