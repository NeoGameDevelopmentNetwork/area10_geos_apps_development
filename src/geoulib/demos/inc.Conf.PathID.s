; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration aus Infoblock einlesen.
;Übergabe: dirEntryBuf  = Verzeichnis-Eintrag
;Rückgabe: uIECID = IEC-ID für Ultimate-Laufwerk von 8 bis 30
;                   NULL: Nicht definiert
;          tIECID = IEC-ID für Ultimate-Laufwerk als ASCII-Text
;                   NULL: Nicht definiert
:getConfigID		lda	dirEntryBuf +22
			cmp	#APPLICATION		;Anwendung?
			beq	:1			; => Ja, weiter...
			cmp	#AUTO_EXEC		;AutoExec?
			beq	:1			; => Ja, weiter...
::exit			rts

::1			lda	dirEntryBuf +19		;Infoblock vorhanden?
			beq	:exit			; => Nein, Abbruch...

;Hinweis:
;Infoblock wird vom GEOS-Kernal über
;GetFile eingelesen!
if FALSE
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H

			lda	#< fileHeader
			sta	r4L
			lda	#> fileHeader
			sta	r4H

			jsr	GetBlock		;Infoblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Nein, weiter...
endif

			lda	fileHeader +160		;IEC-ID auswerten.
			cmp	#"0"
			bcc	:exit			; => Ungültig...
			cmp	#"9" +1
			bcs	:exit			; => Ungültig...

			ldx	fileHeader +161		;IEC-ID auswerten.
			cpx	#"0"
			bcc	:exit			; => Ungültig...
			cpx	#"9" +1
			bcs	:exit			; => Ungültig...

			ldy	fileHeader +162		;Trennzeichen?
			cpy	#":"
			bne	:exit			; => Ungültig...

			sta	tIECID +0
			stx	tIECID +1

			sec				;Ultimate IEC-ID ermitteln.
			sbc	#"0"
			asl
			sta	r0L
			asl
			asl
			clc
			adc	r0L
			sta	r0L
			txa
			sec
			sbc	#"0"
			clc
			adc	r0L
			cmp	#8			;IEC-ID < 8?
			bcc	:exit			; => Ja, ungültig...
			cmp	#30 +1			;IEC-ID > 30?
			bcs	:exit			; => Ja, ungültig...

			sta	uIECID			;IEC-ID speichern.

			rts

;*** Ultimate IEC-ID 8-30.
:uIECID			b $00
:tIECID			b "XX",NULL
