; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Größe der Speicherbänke 16Kb/32Kb/64Kb ermitteln.
:GRamGetBankSize	lda	#0			;Speicherbank #0 aktivieren.
			sta	GRAM_BANK_SLCT

			ldx	#255			;Aus den max. verfügbaren
::1			stx	GRAM_PAGE_SLCT		;256 Speicherseiten einer Bank
			lda	GRAM_PAGE_DATA+0	;die ersten beiden Bytes in Puffer
			sta	diskBlkBuf,x		;zwichenspeichern.
			lda	GRAM_PAGE_DATA+1
			sta	fileHeader,x
			dex
			cpx	#255
			bne	:1

;*** Alle Seiten einer Speicherbank mit Testwerten füllen.
;    Dabei die Bänke vom Ende zum Anfang füllen:
;    Damit werden ungültige Speicherseiten so lange überschrieben bis
;    gültige Speicherseiten erreicht werden. Diese enthalten dann in den
;    ersten beiden Bytes die Seitenspeicher-Nummer und das Testbyte.
			ldy	#63			;Testbyte initialisieren.
;			ldx	#255			;Start mit Speicherseite #255.
::2			stx	GRAM_PAGE_SLCT		;Neue Speicherseite aktivieren.
			stx	GRAM_PAGE_DATA+0	;Speicherseite und
			sty	GRAM_PAGE_DATA+1	;Testbyte speichern.
			dey				;Zeiger auf nächstes Testbyte und
			dex				;nächste Speicherseite setzen.
			cpx	#255			;Alle möglichen Speicherseiten
			bne	:2			;beschrieben? Nein, weiter...

			iny				;Testbyte auf ersten gültigen Wert.
::3			inx				;Zeiger auf nächste Speicherseite.
			stx	GRAM_PAGE_SLCT		;Speicherseite aktivieren.
			cpx	GRAM_PAGE_DATA+0	;Stimmt die Speicherseite im RAM?
			bne	:4			;Nein, max. Größe erreicht.
			cpy	GRAM_PAGE_DATA+1	;Stimmt Testbyte?
			bne	:4			;Nein, max. Größe erreicht.
			iny				;Zeiger auf nächstes Testbyte.
			cpx	#255			;Alle Speicherseiten getestet?
			bne	:3			;Nein, weiter...

			beq	:5			;Ja, Bankgröße erkannt: 256 Seiten.
							; => Weiter...

::4			ldy	#GRAM_BSIZE_0K		;Vorgabewert "Keine Erweiterung".
			cpx	#0			;Keine Speicherseite erkannt?
			beq	:6			;Ja, GeoRAM nicht erkannt, Abbruch.
			dex				;Gültige Speicherseiten -1.
			ldy	#GRAM_BSIZE_16K		;Vorgabewert Bankgröße 16Kb.
			cpx	#64			;Gültige Speicherseiten 0-63?
			bcc	:6			;Ja, max. 4Mb. => Weiter...
			ldy	#GRAM_BSIZE_32K		;Vorgabewert Bankgröße 32Kb.
			cpx	#128			;Gültige Speicherseiten 0-127?
			bcc	:6			;Ja, max. 8Mb. => Weiter...
::5			ldy	#GRAM_BSIZE_64K		;Vorgabewert Bankgröße 64Kb.
::6			sty	GRAM_BANK_SIZE		;Bankgröße speichern.
			tya				;Bankgröße = 0?
			beq	:8			;Ja, GeoRAM nicht erkannt.

;*** Gespeicherte Originalwerte wieder zurückschreiben.
;    Hinweis: Es müssen nur Werte der gültigen Speicherseiten
;             wiederhergestellt werden.
;    Hinweis: Das XReg zeigt hier auf die letzte gültige
;             Speicherseite: 63/127/255.
::7			stx	GRAM_PAGE_SLCT		;Speicherseite aktivieren.
			lda	diskBlkBuf,x		;Byte #1 aus Puffer einlesen
			sta	GRAM_PAGE_DATA+0	;und zurückschreiben.
			lda	fileHeader,x		;Byte #2 aus Puffer einlesen
			sta	GRAM_PAGE_DATA+1	;und zurückschreiben.
			dex				;Zeiger auf nächste Speicherseite.
			cpx	#255			;Alle Speicherseiten bearbeitet?
			bne	:7			;Nein, weiter...

			ldx	#NO_ERROR		;Kein Fehler.
			b	$2c
::8			ldx	#DEV_NOT_FOUND		;GeoRAM nicht erkannt.
			rts

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet:
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
;Die Routine GetSBnkGRAM wird z.B. von GEOS.MP3 nach der Erkennung der GeoRAM
;überschrieben und damit wäre der hier gespeicherte Wert zerstört.
;:GRAM_BANK_SIZE	b $00
