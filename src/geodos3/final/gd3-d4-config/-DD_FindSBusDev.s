; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk am seriellen Bus suchen.
;    Übergabe: AKKU = Laufwerksadresse.
;    Rückgabe: AKKU = $00: OK.
:FindSBusDevice		pha				;Laufwerksadresse sichern.

			lda	#$00
			sta	STATUS			;Status-Flag löschen.
			jsr	UNTALK			;Alle Laufwerke => UNTALK.
			pla
			tax

			lda	STATUS			;Fehler aufgetreten?
			bne	:1			; => Ja, Abbruch...

			txa
			jsr	LISTEN			;Laufwerk aktiveren => LISTEN.

			lda	STATUS			;Fehler aufgetreten?
			bne	:1			; => Ja, Abbruch...

			lda	#$ff			;Sekundäradresse auf Bus senden.
			jsr	SECOND

			lda	STATUS			;Fehlerstatus einlesen.
::1			pha
			jsr	UNLSN			;Alle Laufwerke => UNLISTEN.
			pla				;Fehlerstatus im AKKU.
			rts
