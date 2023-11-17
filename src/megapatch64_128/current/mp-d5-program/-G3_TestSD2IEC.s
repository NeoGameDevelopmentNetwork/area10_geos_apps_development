; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf 1581 oder SD2IEC testen.
;Dazu den Befehl "M-R",$00,$03,$03 senden.
;Die Rückmeldung "00,(OK,00,00)" deutet auf ein SD2IEC hin.
:TestSD2IEC		ldx	#8
::1			stx	curDrvTest		;Aktuelles Laufwerk merken.
			lda	driveType -8,x		;Laufwerk installiert?
			beq	:2			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	TestDevSD2IEC		;SD2IEC-Laufwerk?
			b $2c
::2			ldx	#$00
			txa
			ldx	curDrvTest		;SD2IEC-Flag speichern.
			sta	DrvTypeSD -8,x
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke geprüft?
			bcc	:1			; => Nein, weiter...
			rts

;*** Zwischenspeicher Laufwerksadresse.
:curDrvTest		b $00

;*** Aktuelles Laufwerk auf SD2IEC testen.
:TestDevSD2IEC		ldx	curDrive
			lda	RealDrvType -8,x
			beq	:3
			and	#%10111111
			cmp	#$10			;CMD/RAM-Laufwerk?
			bcs	:3			; => Ja, kein SD2IEC.

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldx	curDrive		;Laufwerksadresse einlesen.
			lda	#15			;Kanal und Sekundäadresse #15.
			tay
			jsr	SETLFS
			lda	#0			;Kein Dateiname erforderlich.
			tax
			tay
			jsr	SETNAM
			jsr	OPENCHN			;Befehlskanal öffnen.

			jsr	initDrvStatus		;"M-R"-Befehl senden.
			jsr	getDrvStatus		;Antwort empfangen.

			lda	#15
			jsr	CLOSE			;Befehlskanal schließen.

			ldx	#$ff			;Vorgabe: SD2IEC.
			lda	drvStatus +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:1			; => Nein, Ende...
			lda	drvStatus +1
			cmp	#"0"
			bne	:1
			lda	drvStatus +2
			cmp	#","
			beq	:2
::1			ldx	#$00			;Kein SD2IEC.
::2			jmp	DoneWithIO

::3			ldx	#$00			;Kein SD2IEC.
			rts

;*** "M-R"-Befehl an Laufwerk senden.
:initDrvStatus		ldx	#15
			jsr	CKOUT

			ldy	#$00
::1			tya
			pha
			lda	:getData,y
			jsr	BSOUT
			pla
			tay
			iny
			cpy	#6
			bcc	:1

			jmp	CLRCHN

::getData		b "M-R",$00,$03,$03

;*** Rückmeldung von Floppy empfangen.
:getDrvStatus		ClrB	STATUS

			ldx	#15
			jsr	CHKIN

			ldy	#$00
::1			tya
			pha
			jsr	GETIN
			tax
			pla
			tay
			txa
			sta	drvStatus,y
			iny
			cpy	#3
			bcc	:1

			jmp	CLRCHN

:drvStatus		s $03
