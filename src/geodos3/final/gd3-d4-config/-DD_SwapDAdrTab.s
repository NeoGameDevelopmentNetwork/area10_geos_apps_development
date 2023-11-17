; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerke #8 bis #11 auf freie Adressen legen.
:FreeDrvAdrGEOS		jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			ldy	#$08
::1			jsr	ClrDrvAdrGEOS		;Tabelle mit Geräteadressen löschen.
			iny
			cpy	#12
			bcc	:1

			ldx	#8
::2			stx	r15H
			lda	devInfo-8,x		;Laufwerk vorhanden ?
			beq	:3			;Nein, weiter...

			jsr	GetFreeDrvAdr		;Freie Geräteadresse suchen.
			txa				;XReg = STATUS/$0090 >0 = N.V.
			beq	:err			; => Keine Adresse #20-29 frei.

			ldx	r15H
			txa
			sta	OldDrvAdrTab -8,x
			ldy	r14H 			;Neue Adresse.
			tya
			sta	NewDrvAdrTab -8,x
			jsr	SwapDiskDevAdr		;Gerät auf neue Adresse umschalten.
			txa				;Fehler aufgetreten ?
			bne	:err			; => Ja, Abbruch...

::3			ldx	r15H
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getauscht ?
			bcc	:2			;Nein, weiter...

			ldx	#NO_ERROR
			b $2c
::err			ldx	#ILLEGAL_DEVICE
			jmp	DoneWithIO		;I/O abschalten.

;*** Geräteadressen zurücksetzen.
:ResetDrvAdrGEOS	jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			ldy	#8
::1			sty	r15H
			lda	NewDrvAdrTab -8,y	;Laufwerk gewechselt ?
			beq	:2			; => Nein, weite...
			tax
			lda	devInfo -8,x		;Laufwerk noch verfügbar ?
			beq	:2			; => Nein, weiter...
			ldx	OldDrvAdrTab -8,y	;Alte Laufwerksadresse einlesen.
			lda	devInfo -8,x		;Alte Adresse in Verwendung ?
			bne	:2			; => Ja, weiter...

			ldy	r15H
			ldx	NewDrvAdrTab -8,y	;Getauschte Adresse.
			lda	OldDrvAdrTab -8,y	;Alte/Originale Adresse.
			tay
			jsr	SwapDiskDevAdr		;Gerät auf neue Adresse umschalten.
			txa				;Fehler aufgetreten ?
			bne	:err			; => Ja, Abbruch...

::2			ldy	r15H
			iny
			cpy	#12
			bcc	:1

			ldx	#NO_ERROR
			b $2c
::err			ldx	#ILLEGAL_DEVICE
			jmp	DoneWithIO		;I/O abschalten.

;*** GEOS-Laufwerksadresse aus Tabelle löschen.
;Übergabe: YReg = GEOS-Laufwerksadresse.
:ClrDrvAdrGEOS		lda	#$00
			sta	OldDrvAdrTab -8,y
			sta	NewDrvAdrTab -8,y
			rts

:OldDrvAdrTab		s $04
:NewDrvAdrTab		s $04
