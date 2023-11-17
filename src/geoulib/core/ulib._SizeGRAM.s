; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Größe GeoRAM testen
;
;Übergabe : -
;Rückgabe : r2/r3 = Größe GeoRAM in Bytes
;           Y = Anzahl 64K-Speicherbänke:
;                   0Kb:   0
;                  64Kb:   1
;                 128Kb:   2
;                 ...
;                8192Kb: 128
;               16384Kb: 255  ;Sonderfall da 256 nicht möglich.
;           X = Fehlerstatus:
;               $00 = OK
;               $0D = Kein GeoRAM
;Verändert: A,X,Y,r2-r3,diskBlkBuf,fileHeader

:GRAM_BANK_COUNT	b $00  ;Anzahl der Speicherbänke.
:GRAM_BANK_SIZE		b $00  ;Bankgröße 16/32/64Kb.
:GRAM_BANK_VIRT64	b $00  ;Virtuelle 64K-Bänke für GEOS.

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64

:ULIB_SIZE_GRAM

			lda	#$00			;Größe C=REU löschen.
			sta	r2L
			sta	r2H
			sta	r3L
			sta	r3H

			jsr	_ulib_mb_gram		;Erkennungsroutine starten.

			tya				;Mind. 1 Speicherbank?
			beq	:no_gram		; => Nein, keine GeoRAM...

			sta	r3L
			cmp	#255			;Sonderfall 16Mb C=REU?
			bne	:ok			; => Nein, weiter...
			inc	r3L			;Anzahl Bytes korrigieren.
			inc	r3H			; => $0100:0000

::ok			ldx	#NO_ERROR
			b $2c
::no_gram		ldx	#DEV_NOT_FOUND

			rts

;*** GeoRAM Bankanzahl testen.
;Übergabe : -
;Rückgabe : Y = Anzahl 64K-Speicherbänke:
;               0   = Keine GeoRAM
;               1   = 64Kb
;               2   = 128Kb
;                     ...
;               64  = 4096Kb
;               128 = 8192Kb
;               255 = 16384Kb
;           X = Fehlerstatus:
;               $00 = OK
;               $0D = Keine C=REU
;Verändert: A,X,Y,diskBlkBuf,fileHeader
:_ulib_mb_gram		jsr	_ulib_gBankSize		;Bank-Größe ermitteln.
			txa				;GeoRAM erkannt?
			bne	:err			;Nein, Abbruch...

			jsr	_ulib_gBankCount	;Anzahl Bänke ermitteln.
			txa				;Speicher erkannt?
			bne	:err			;Nein, Abbruch...

			lda	GRAM_BANK_COUNT		;Anzahl der 16/32/64Kb-Bänke der
			ldx	GRAM_BANK_SIZE		;GeoRAM in virtuelle 64K-Bänke für
			cpx	#GRAM_BSIZE_64K		;GEOS umrechnen.
			beq	:3
			cmp	#$00
			bne	:1
			lda	#$80
			bne	:2
::1			lsr
::2			cpx	#GRAM_BSIZE_32K
			beq	:3
			lsr
::3			tay				;256 x 64Kb?
			bne	:set			; => Nein, weiter...
			dey				;Max. 255 x 64Kb, da 0=keine GeoRAM.

::set			sty	GRAM_BANK_VIRT64
::err			rts

;*** Größe einer Speicherbank ermitteln.
;Übergabe : -
;Rückgabe : GRAM_BANK_SIZE = Bankgröße 16/32/64Kb
;Verändert: A,X,Y,diskBlkBuf,fileHeader
:_ulib_gBankSize	ldx	#0			;Speicherbank #0 aktivieren.
			stx	GRAM_RAMBANK

;--- Originalwerte aus GeoRAM zwischenspeichern.
;			ldx	#0			;Aus den max. verfügbaren
::backup		stx	GRAM_RAMPAGE		;256 Speicherseiten einer Bank
			lda	GRAM_RAMDATA+0		;die ersten beiden Bytes in Puffer
			sta	diskBlkBuf,x		;zwichenspeichern.
			lda	GRAM_RAMDATA+1
			sta	fileHeader,x
			inx
			bne	:backup

;--- Hinweis:
;Alle Seiten einer Speicherbank mit
;Testwerten füllen. Dabei die Seiten
;vom Ende zum Anfang füllen:
;Damit werden ungültige Seiten so
;lange überschrieben bis eine gültige
;Seiten gefunden wurde.
;Die Seite enthält dann in den ersten
;beiden Bytes die letzte Seitennummer
;und das Testbyte.
::write			ldy	#63			;Testbyte initialisieren.
			ldx	#255			;Start mit Speicherseite #255.
::1			stx	GRAM_RAMPAGE		;Neue Speicherseite aktivieren.
			stx	GRAM_RAMDATA+0		;Speicherseite und
			sty	GRAM_RAMDATA+1		;Testbyte speichern.
			dey				;Zeiger auf nächstes Testbyte und
			dex				;nächste Speicherseite setzen.
			cpx	#255			;Alle möglichen Speicherseiten
			bne	:1			;beschrieben? Nein, weiter...

::test			iny				;Testbyte auf ersten gültigen Wert.
::2			inx				;Zeiger auf nächste Speicherseite.
			stx	GRAM_RAMPAGE		;Speicherseite aktivieren.
			cpx	GRAM_RAMDATA+0		;Stimmt die Speicherseite im RAM?
			bne	:3			;Nein, max. Größe erreicht.
			cpy	GRAM_RAMDATA+1		;Stimmt Testbyte?
			bne	:3			;Nein, max. Größe erreicht.
			iny				;Zeiger auf nächstes Testbyte.
			cpx	#255			;Alle Speicherseiten getestet?
			bne	:2			; => Nein, weiter testen...
			beq	:done			; => Bankgröße erkannt: 256 Seiten.

::3			ldy	#GRAM_BSIZE_0K		;Vorgabewert "Keine Erweiterung".
			cpx	#0			;Keine Speicherseite erkannt?
			beq	:set			; => Ja, keine GeoRAM, Abbruch...
			dex				;Gültige Speicherseiten -1.
			ldy	#GRAM_BSIZE_16K		;Vorgabewert Bankgröße 16Kb.
			cpx	#64			;Gültige Speicherseiten 0-63?
			bcc	:set			; => Ja, max. 4Mb. => Weiter...
			ldy	#GRAM_BSIZE_32K		;Vorgabewert Bankgröße 32Kb.
			cpx	#128			;Gültige Speicherseiten 0-127?
			bcc	:set			; => Ja, max. 8Mb. => Weiter...
::done			ldy	#GRAM_BSIZE_64K		;Vorgabewert Bankgröße 64Kb.
::set			sty	GRAM_BANK_SIZE		;Bankgröße speichern.
			tya				;Bankgröße = 0?
			beq	:err			; => Ja, GeoRAM nicht erkannt.

;--- Gespeicherte Originalwerte wieder zurückschreiben.
;Hinweis:
;Es müssen nur die Werte der gültigen
;Speicherseiten zurückgesetzt werden.
;Das XReg zeigt hier auf die letzte
;gültige Speicherseite:
;  Seiten 0 -  63 = Bankgröße 16Kb
;  Seiten 0 - 127 = Bankgröße 32Kb
;  Seiten 0 - 255 = Bankgröße 64Kb
::restore		stx	GRAM_RAMPAGE		;Speicherseite aktivieren.

			lda	diskBlkBuf,x		;Byte #1 aus Puffer einlesen
			sta	GRAM_RAMDATA+0		;und zurückschreiben.
			lda	fileHeader,x		;Byte #2 aus Puffer einlesen
			sta	GRAM_RAMDATA+1		;und zurückschreiben.

			dex				;Zeiger auf nächste Speicherseite.
			cpx	#255			;Alle Speicherseiten bearbeitet?
			bne	:restore		;Nein, weiter...

			ldx	#NO_ERROR		;Kein Fehler.
			rts

::err			ldx	#DEV_NOT_FOUND		;GeoRAM nicht erkannt.
			rts

;*** Anzahl der Speicherbänke ermitteln.
;Übergabe : -
;Rückgabe : GRAM_BANK_COUNT = Anzahl Speicherbänke
;Verändert: A,X,Y,diskBlkBuf,fileHeader
:_ulib_gBankCount	lda	GRAM_BANK_SIZE		;Größe der Speicherbänke einlesen.
			cmp	#GRAM_BSIZE_32K		;Kleiner 32Kb?
			bcc	:init			;Ja, Speicherbänke 0-255 prüfen.

			lda	#255			;Ab 32Kb Speichergröße immer
			sta	GRAM_BANK_COUNT		;255 Speicherbänke (8/16Mb GeoRAM).

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;--- Originalwerte aus GeoRAM zwischenspeichern.
::init			ldx	#0			;Speicherseite #0 aktivieren.
			stx	GRAM_RAMPAGE

;			ldx	#0			;Aus den max. verfügbaren
::backup		stx	GRAM_RAMBANK		;256 Speicherbänken
			lda	GRAM_RAMDATA+0		;die ersten beiden Bytes in Puffer
			sta	diskBlkBuf,x		;zwichenspeichern.
			lda	GRAM_RAMDATA+1
			sta	fileHeader,x
			inx
			bne	:backup

;--- Hinweis:
;Alle Speicherbänke/Speicherseite #0
;mit Testwerten füllen. Dabei die
;Bänke vom Ende zum Anfang füllen:
;Damit werden ungültige Speicherbänke
;so lange überschrieben bis gültige
;Speicherbänke erreicht werden.
;Diese enthalten dann in den ersten
;beiden Bytes die Speicherbank-Nummer
;und das Testbyte.
::write			ldy	#63			;Testbyte initialisieren.
			ldx	#255			;Start mit Speicherbank #255.
::1			stx	GRAM_RAMBANK		;Neue Speicherbank aktivieren.
			stx	GRAM_RAMDATA+0		;Speicherbank und
			sty	GRAM_RAMDATA+1		;Testbyte speichern.
			dey				;Zeiger auf nächstes Testbyte und
			dex				;nächste Speicherbank setzen.
			cpx	#255			;Alle möglichen Speicherbänke
			bne	:1			;beschrieben? Nein, weiter...

::test			iny				;Testbyte auf ersten gültigen Wert.
::2			inx				;Zeiger auf nächste Speicherbank.
			stx	GRAM_RAMBANK		;Speicherseite aktivieren.
			cpx	GRAM_RAMDATA+0		;Stimmt die Speicherbank im RAM?
			bne	:set			; => Nein, max. Größe erreicht.
			cpy	GRAM_RAMDATA+1		;Stimmt Testbyte?
			bne	:set			; => Nein, max. Größe erreicht.
			iny				;Zeiger auf nächstes Testbyte.
			cpx	#255			;Alle Speicherbänke durchsucht?
			bne	:2			; => Nein, weiter...
			inx
::set			stx	GRAM_BANK_COUNT		;Bankanzahl speichern.

;--- Gespeicherte Originalwerte wieder zurückschreiben.
;Hinweis:
;Es müssen nur die Werte der gültigen
;Speicherbänke zurückgesetzt werden.
;Das XReg zeigt hier auf die letzte
;gültige Speicherbank:
;  Bank 0 bis   3 =    64Kb
;       0 bis   7 =   128Kb
;       0 bis  15 =   256Kb
;       0 bis  31 =   512Kb
;       0 bis  63 =  1024Kb
;       0 bis 127 =  2048Kb
;       0 bis 255 =  4096Kb, Bankgröße = 16Kb
;       0 bis 255 =  8192Kb, Bankgröße = 32Kb
;       0 bis 255 = 16384Kb, Bankgröße = 64Kb
::restore		dex				;Zeiger auf nächste Speicherbank.
			stx	GRAM_RAMBANK		;Speicherbank aktivieren.
			lda	diskBlkBuf,x		;Byte #1 aus Puffer einlesen
			sta	GRAM_RAMDATA+0		;und zurückschreiben.
			lda	fileHeader,x		;Byte #2 aus Puffer einlesen
			sta	GRAM_RAMDATA+1		;und zurückschreiben.
			cpx	#0			;Alle Speicherbänke bearbeitet?
			bne	:restore		;Nein, weiter...

;			ldx	#NO_ERROR		;Kein Fehler.
			rts
