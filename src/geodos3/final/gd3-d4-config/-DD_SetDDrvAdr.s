; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk auf neue Adresse setzen.
;    Übergabe:		r14L = Quell-Laufwerk.
;			r15L = Ziel -Laufwerk.
;    Rückgabe:    XReg = Fehler.
:SetDiskDrvAdr		ldx	#NO_ERROR		;Ende...
			lda	r15L			;Hat Laufwerk bereits die
			cmp	r14L			;korrekte Laufwerksadresse ?
			beq	:3			; => Ja, Ende...

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			lda	r15L			;Existiert ein Laufwerk mit neuer
			jsr	FindSBusDevice		;Geräteadresse ?
			bne	:1			; => Nein, weiter...

			jsr	GetFreeDrvAdr		;Freie Geräteadresse suchen.
			txa				;XReg = STATUS/$0090 >0 = N.V.
			beq	:err			; => Keine Adresse #20-29 frei.

			ldy	r14H 			;Neue Adresse.
			ldx	r15L			;Alte Adresse.
			jsr	SwapDiskDevAdr		;Aktuelles Gerät auf eine neue
							;Adresse umschalten, damit die
							;Geräteadresse für neues Laufwerk
							;freigegeben wird.

			lda	r15L
			jsr	FindSBusDevice		;Adresse erfolgreich gewechselt?
			beq	:err			; => Nein, Fehler...

::1			ldy	r15L			;Ziel-Laufwerk auf die neue GEOS-
			ldx	r14L			;Adresse umschalten.
			jsr	SwapDiskDevAdr

			ldx	#NO_ERROR		;Ende...
			b $2c
::err			ldx	#ILLEGAL_DEVICE

::2			jsr	DoneWithIO		;I/O abschalten.

::3			rts
