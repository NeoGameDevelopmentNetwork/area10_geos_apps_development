; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration aus Infoblock einlesen.
;Übergabe: dirEntryBuf  = Verzeichnis-Eintrag
;Rückgabe: uHost = Host-Adresse
;                  NULL: Nicht definiert
;          uPort = Port-Adresse
;                  NULL: Nicht definiert
:getConfHost		lda	dirEntryBuf +22
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

			ldy	#0			;Host-Adresse kopieren.
::loop			lda	fileHeader +160,y
			beq	:done
			cmp	#":"
			beq	:port
			cmp	#CR
			beq	:done
			sta	uHost,y
			iny
			cpy	#96			;Max. Länge erreicht?
			bcc	:loop			; => Nein, weiter...
			bcs	:done

::port			iny
			sty	r0H

			ldx	#0			;ASCII-Länge Port-Adresse
::next			lda	fileHeader +160,y	;ermitteln.
			cmp	#"0"
			bcc	:getlen
			cmp	#"9" +1
			bcs	:getlen			; => Ende erreicht...
			iny
			inx
			cpx	#5			;Max. 5 Zeichen?
			bcc	:next			; => Nein, weiter...

::getlen		txa				;Mind 1 Zeichen?
			beq	:done			; => Nein, Ende...

			sta	r0L			;Zeiger auf Dezimal-Tabelle
			lda	#5			;berechnen.
			sec
			sbc	r0L
			tax

::ascii2dez		stx	r0L			;Zeiger auf Dezimal-Tabelle.

			ldy	r0H			;ASCII-Zeichen einlesen.
			lda	fileHeader +160,y
			sec
			sbc	#"0"			;Zeichen in Zahl umwandeln.
			tay				;Zahl = 0?
			beq	:nxascii		; => Ja, nächstes Zeichen...

			ldx	r0L			;10^x addieren.
::add			lda	uPort +0
			clc
			adc	:tabDezL,x
			sta	uPort +0
			lda	uPort +1
			adc	:tabDezH,x
			sta	uPort +1
			dey				;ASCII-Zahl addiert?
			bne	:add			; => Nein, weiter...

			ldx	r0L
::nxascii		inc	r0H

			inx				;Zeiger auf nächsten Dezimal-
			cpx	#5			;Wert in Tabelle. Ende erreicht?
			bcc	:ascii2dez		; => Nein, weiter...

::done			rts

;--- Umrechnungstabelle ASCII->Dezimal.
::tabDezL		b <10000,<1000,<100,<10,<1
::tabDezH		b >10000,>1000,>100,>10,>1

;*** Host-Adresse.
:uHost			s 96
:uPort			w $0000
