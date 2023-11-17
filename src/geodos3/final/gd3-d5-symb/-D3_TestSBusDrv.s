; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prüfen ob Laufwerk am ser.Bus aktiv ist.
;    Übergabe:		AKKU = Laufwerksadresse.
:xTestSBusDrive		tax				;Laufwerksadresse einlesen und
			lda	#2			;testen ob Laufwerk aktiv.
			tay				;Nicht Sek.Adr #15 verwenden, macht
			jsr	SETLFS			;am C128 Probleme, da hier dann das
							;Status-Byte nicht gesetzt wird.
			lda	#0			;Kein Dateiname erforderlich.
;			tax
;			tay
			jsr	SETNAM
			jsr	OPENCHN			;Datenkanal öffnen.

			lda	#2
			jsr	CLOSE			;Datenkanal schließen.

			lda	STATUS			;STATUS = OK ?
			rts
