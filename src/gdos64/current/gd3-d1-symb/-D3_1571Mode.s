; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** 1571: Auf Doppel-/Einseitig umschalten.
;Übergabe: AKKU = doubleSideFlg, $80 = Doppelseitig.
;                                $00 = Einseitig.
;          XReg = Laufwerksadresse.
;
;Beispiel:
;			ldx	curDrive
;			lda	driveType -8,x		;RAM-Laufwerk ?
;			bmi	:cont			; => Ja, weiter...
;			lda	DriveInfoTab -8,x
;			cmp	#Drv1571		;1571-Laufwerk ?
;			bne	:cont			; => Nein, weiter...
;			lda	doubleSideFlg -8,x
;			jsr	Set1571DkMode		;1571-Laufwerksmodus festlegen.
;
;--- Modus prüfen.
;Hier wird das Flag für doppelseitige
;Disketten unter GEOS ausgewertet.
;Wenn das Flag nicht gesetzt ist, dann
;ist die Systemdiskette vom Typ 1541
;in einem 1571-Laufwerk.
:Set1571DkMode		stx	:drive			;Laufwerksadresse speichern.
			tax				;Doppelseitig ?
			beq	:setmode41		; => Nein, weiter...
::setmode71		lda	#"1"			;"U0>M1": 1571-Modus.
			b $2c
::setmode41		lda	#"0"			;"U0>M0": 1541-Modus.
			sta	:com_dblSide +4

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	UNLSN			;Laufwerk abschalten.

			lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	:drive			;Laufwerk auf Empfang
			jsr	LISTEN			;umschalten.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:err1			; => Ja, Abbruch

			lda	#15
			ora	#%11110000		;"OPEN"
			jsr	SECOND			;Sekundäradresse senden.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:err1			; => Ja, Abbruch

			ldy	#$00
::loop1			lda	:com_dblSide,y		;"U0>Mx"
			jsr	CIOUT			;Umschalten auf 1541/71-Modus.
			iny
			cpy	#:com_dblSide_len	;Befehl gesendet ?
			bcc	:loop1			; => Nein, weiter...
			bcs	:skipDrvStatus		;Weiter...

::err1			jsr	UNLSN			;Laufwerk abschalten.
			jmp	:alldone		;I/O abschalten und Abbruch...

::drive			b $00
::com_dblSide		b "U0>M1"
::com_dblSide_end
::com_dblSide_len	= (:com_dblSide_end - :com_dblSide)

;--- Laufwerkstatus überlesen.
::skipDrvStatus		jsr	UNLSN			;Laufwerk abschalten.
			jsr	UNTALK			;Laufwerk abschalten.

			lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	:drive			;Laufwerk auf Senden
			jsr	TALK			;umschalten.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:err2			; => Ja, Abbruch

			lda	#15
			ora	#%11110000		;"OPEN"
			jsr	TKSA			;Sekundäradresse senden.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:err2			; => Ja, Abbruch

::loop2			jsr	ACPTR			;Fehlerstatus überspringen.
			lda	STATUS			;Ende erreicht ?
			beq	:loop2

::err2			jsr	UNTALK			;Laufwerk abschalten.

::alldone		lda	:drive			;Laufwerksadresse.
			jsr	LISTEN			;Laufwerk aktivieren.
			lda	#15 ! %11100000
;			ora	#$e0			;"CLOSE".
			jsr	SECOND			;Kanal mit SA=15 schließen.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			rts
