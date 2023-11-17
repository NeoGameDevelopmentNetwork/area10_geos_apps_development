; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aktuelles Laufwerk auf SD2IEC testen.
;    Übergabe: curDrive = Aktuelles Laufwerk.
;    Rückgabe: XREG = $00, DiskImage.
;                   = $FF, Verzeichnis.
:getModeSD2IEC		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			bne	:100			; => Nein, kein SD2IEC.

			ldx	#NO_ERROR
			rts

::100			lda	#"7"			;Fehlermeldung initialisieren.
			sta	FComReply +0
			lda	#"0"
			sta	FComReply +1
			lda	#","
			sta	FComReply +2

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			lda	#1
			ldx	#<FComName
			ldy	#>FComName
			jsr	SETNAM			;Datenkanal, Name "#".

			lda	#5
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Datenkanal.

			jsr	OPENCHN			;Datenkanal öffnen.
			bcs	:error

			lda	#10
			ldx	#<FComTest
			ldy	#>FComTest
			jsr	SETNAM			;"U1"-Befehl.

			lda	#15
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal #15 öffnen.
			bcs	:error

			lda	#<FComReply		;Antwort empfangen.
			ldx	#>FComReply
			ldy	#3
			jsr	GetFData

::error			lda	#15			;Befehlskanal schließen.
			jsr	CLOSE

			lda	#5			;Datenkanal schließen.
			jsr	CLOSE

			jsr	CLRCHN

			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:101			; => Nein, Verzeichnis-Modus.
			lda	FComReply +1
			cmp	#"0"
			bne	:101
			lda	FComReply +2
			cmp	#","
			beq	:103

::101			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"7"			;"70," ?
			bne	:102			; => Ja, Keine SD-Karte.
			lda	FComReply +1
			cmp	#"0"
			bne	:102
			lda	FComReply +2
			cmp	#","
			bne	:102

			ldx	#DEV_NOT_FOUND
			b $2c
::102			ldx	#$ff			;SD2IEC: Verzeichnis.
			b $2c
::103			ldx	#$00			;SD2IEC: DiskImage.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

:FComName		b "#"
:FComTest		b "U1 5 0 1 1"
:FComReply		s $03

;*** Rückmeldung von Floppy empfangen.
:GetFData		sta	r0L
			stx	r0H
			sty	r1L

			lda	#$00
			sta	STATUS

			ldx	#15
			jsr	CHKIN

			lda	#$00
			sta	:102 +1

::101			jsr	READST
			bne	:103
			jsr	CHRIN

::102			ldy	#$ff
			cpy	r1L
			bcs	:101
			sta	(r0L),y
			inc	:102 +1
			jmp	:101

::103			rts
