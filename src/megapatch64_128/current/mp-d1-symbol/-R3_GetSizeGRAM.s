; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GeoRAM-Konfigurationsdaten:
;Register zur Auswahl der 16Kb/32Kb/64Kb-Speicherbank:
;GRAM_BANK_SLCT = $DFFF
;
;Register zur Auswahl der 256Byte-Speicherseite innerhalb
;der gewählten Speicherbank:
;GRAM_PAGE_SLCT = $DFFE
;
;Zugriff auf die gwählte Speicherbank/Speicherseite:
;GRAM_PAGE_DATA = $DE00-$DEFF
;
;Mögliche Werte für die Größe der Speicherbänke:
;    GeoRAM    64Kb = 16Kb
;    GeoRAM   128Kb = 16Kb
;    GeoRAM   256Kb = 16Kb
;    GeoRAM   512Kb = 16Kb
;    GeoRAM  1024Kb = 16Kb
;    GeoRAM  2048Kb = 16Kb
;    GeoRAM  4096Kb = 16Kb
;    GeoRAM  8192Kb = 32Kb
;    GeoRAM 16384Kb = 64Kb
;
;Mögliche Werte für die Anzahl der Speicher-Bänke:
;    GeoRAM   64Kb bis  4096Kb: 0-255, Bankgröße 16Kb
;    GeoRAM 4097Kb bis  8192Kb:   255, Bankgröße 32Kb
;    GeoRAM 8193Kb bis 16384Kb:   255, Bankgröße 64Kb
;
;

;*** Definierenn der GeoRAM-Register.
:GRAM_PAGE_DATA		= $de00
:GRAM_PAGE_SLCT		= $dffe
:GRAM_BANK_SLCT		= $dfff

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64

;*** Systemvariablen.
:GRAM_SIZE_KB		w $0000
:GRAM_BANK_COUNT	b $00				;Anzahl Bänke in GeoRAM mit 16/32/64Kb
:GRAM_BANK_VIRT64	b $00				;Anzahl virtuelle 64Kb-Speicherbänke.

;*** Standardwerte setzen und GeoRAM-Erkennung.
:GRAM_GET_SIZE		jsr	GRAM_GET_BCOUNT		;Anzahl 64K-Speicherbänke ermitteln.

;*** GeoRAM-Erkennung abgeschlossen.
:ExitGRamTest		ldx	GRAM_BANK_COUNT		;Speicher gefunden?
			beq	:9			;Nein, Abbruch...

;*** GeoRAM-Größe berechnen.
			ldy	#$00
			lda	GRAM_BANK_SIZE		;Bankgröße einlesen.
			bne	:1			;Größe = 0Kb? Nein, weiter...

			ldx	#DEV_NOT_FOUND		;GeoRAM nicht erkannt.
			jmp	:9			; => Abbruch.

::1			cmp	#GRAM_BSIZE_64K		;Bankgröße 64Kb?
			bne	:2			;Nein, weiter...
			cpx	#255			;255 Speicherbänke?
			beq	:3			;Ja, weiter...
							;Damit wird sichergestellt das max.
							;255 Speicherbänke a 64Kb erkannt
							;werden. Der Wert 256=0 wird für
							;"keine Erweiterung" verwendet.
::2			inx				;Anzahl der Speicherbänke +1.
							;Damit wird die gesamte Erweiterung
							;genutzt mit Ausnahme einer 16Mb
							;Erweiterung: max.255*64 = 16320Kb.
			bne	:3
			iny
::3			stx	r0L			;Anzahl der Speicherbänke zur
			sty	r0H			;Berechnung der GEOS/MP3 64Kb
							;Speicherbänke in r0 ablegen.
			lda	GRAM_BANK_SIZE		;Größe der Speicherbänke
			sta	r1L			;in r1L ablegen.

			ldx	#r0L			;BMult für WORD*BYTE aufrufen.
			ldy	#r1L
			jsr	BMult
			MoveW	r0,GRAM_SIZE_KB		;Größe der GeoRAM speichern.

			ldx	#NO_ERROR
::9			rts

;*** Größe des GeoRAM-Speichers ermitteln.
:GRAM_GET_BCOUNT	php
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			lda	MMU
			pha
			lda	#$7e
			sta	MMU
endif

			jsr	sysGetBCntGRAM		;Erkennungsroutine starten.
			ldx	GRAM_BANK_SIZE		;Bank-Größe 16/32/64kb.
			ldy	GRAM_BANK_VIRT64	;Anzahl 64K-Speicherbänke.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	MMU
endif

			plp				;IRQ-Status zurücksetzen.

;--- Ergänzung: 14.08.18/M.Kanet
;Code wird auch von GEOS128.BOOT in Bank#0/#1 verwendet. Variablen erst nach
;dem zurücksetzen der MMU im RAM speichern.
			stx	GRAM_BANK_SIZE
			tya
			sta	GRAM_BANK_VIRT64
			beq	:1
			ldx	#NO_ERROR
			b $2c
::1			ldx	#DEV_NOT_FOUND
			rts

;*** GeoRAM Bankanzahl testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysGetBCntGRAM		ldy	#$00
			sty	GRAM_BANK_SIZE
			sty	GRAM_BANK_COUNT
			sty	GRAM_BANK_VIRT64

;*** Page-Größe ermitteln.
			jsr	GRamGetBankSize		;Bank-Größe ermitteln.
			txa				;GeoRAM erkannt?
			bne	:1			;Nein, Abbruch...

;*** Anzahl Bänke ermitteln.
			jsr	GRamGetBankCnt		;Anzahl Bänke ermitteln.
			txa				;Speicher erkannt?
			bne	:1			;Nein, Abbruch...

			lda	GRAM_BANK_COUNT		;Anzahl der 16/32/64Kb-Bänke der
			ldx	GRAM_BANK_SIZE		;GeoRAM in virtuelle 64K-Bänke für
			cpx	#GRAM_BSIZE_64K		;GEOS/MP3 umrechnen.
			beq	:8
			cmp	#$00
			bne	:6
			lda	#$80
			bne	:7
::6			lsr
::7			cpx	#GRAM_BSIZE_32K
			beq	:8
			lsr
::8			tay
			bne	:9
			dey

::9			sty	GRAM_BANK_VIRT64
::1			rts

;*** Größe der Speicherbänke 16Kb/32Kb/64Kb ermitteln.
;			t "-R3_GetSBnkGRAM"

;*** Anzahl der Speicherbänke 0-255 ermitteln.
:GRamGetBankCnt

;Hinweis: Physikalische GeoRAM-Varianten verwenden 8/16Mb bei
;         256 gültigen Speicherseiten. Für diese Erweiterungen könnte man
;         auf die Erkennung der Bankanzahl verzichten, da immer 256.
;         Da aber nicht auszuschließen ist das es Erweiterungenn die sich
;         konfigurieren lassen sollte immer auf die gültige Anzahl an
;         Speicherbänken getestet werden.
;			lda	GRAM_BANK_SIZE		;Größe der Speicherbänke einlesen.
;			cmp	#GRAM_BSIZE_32K		;Kleiner 32Kb?
;			bcc	:1			;Ja, Speicherbänke 0-255 prüfen.
;
;			ldx	#255			;Ab 32Kb Speichergröße immer
;			stx	GRAM_BANK_COUNT		;255 Speicherbänke (8/16Mb GeoRAM).
;			jmp	:8

::1			lda	#0			;Speicherseite #0 aktivieren.
			sta	GRAM_PAGE_SLCT

			ldx	#255			;Aus den max. verfügbaren
::2			stx	GRAM_BANK_SLCT		;256 Speicherbänken
			lda	GRAM_PAGE_DATA+0	;die ersten beiden Bytes in Puffer
			sta	diskBlkBuf,x		;zwichenspeichern.
			lda	GRAM_PAGE_DATA+1
			sta	fileHeader,x
			dex
			cpx	#255
			bne	:2

;*** Alle Speicherbänke/Speicherseite #0 mit Testwerten füllen.
;    Dabei die Bänke vom Ende zum Anfang füllen:
;    Damit werden ungültige Speicherbänke so lange überschrieben bis
;    gültige Speicherbänke erreicht werden. Diese enthalten dann in den
;    ersten beiden Bytes die Speicherbank-Nummer und das Testbyte.
			ldy	#63			;Testbyte initialisieren.
;			ldx	#255			;Start mit Speicherbank #255.
::3			stx	GRAM_BANK_SLCT		;Neue Speicherbank aktivieren.
			stx	GRAM_PAGE_DATA+0	;Speicherbank und
			sty	GRAM_PAGE_DATA+1	;Testbyte speichern.
			dey				;Zeiger auf nächstes Testbyte und
			dex				;nächste Speicherbank setzen.
			cpx	#255			;Alle möglichen Speicherbänke
			bne	:3			;beschrieben? Nein, weiter...

			iny				;Testbyte auf ersten gültigen Wert.
::4			inx				;Zeiger auf nächste Speicherbank.
			stx	GRAM_BANK_SLCT		;Speicherseite aktivieren.
			cpx	GRAM_PAGE_DATA+0	;Stimmt die Speicherbank im RAM?
			bne	:5			;Nein, max. Größe erreicht.
			cpy	GRAM_PAGE_DATA+1	;Stimmt Testbyte?
			bne	:5			;Nein, max. Größe erreicht.
			iny				;Zeiger auf nächstes Testbyte.
			cpx	#255
			bne	:4			;Nein, weiter...
			inx
::5			stx	GRAM_BANK_COUNT		;Bankanzahl speichern.
			dex

;*** Gespeicherte Originalwerte wieder zurückschreiben.
;    Hinweis: Es müssen nur Werte der gültigen Speicherbänke
;             wiederhergestellt werden.
;    Hinweis: Das XReg zeigt hier auf die letzte gültige
;             Speicherbank:
;             Bank 0 bis   3 =    64Kb
;                  0 bis   7 =   128Kb
;                  0 bis  15 =   256Kb
;                  0 bis  31 =   512Kb
;                  0 bis  63 =  1024Kb
;                  0 bis 127 =  2048Kb
;                  0 bis 255 =  4096Kb, Bankgröße = 16Kb
;                  0 bis 255 =  8192Kb, Bankgröße = 32Kb
;                  0 bis 255 = 16384Kb, Bankgröße = 64Kb
::7			stx	GRAM_BANK_SLCT		;Speicherbank aktivieren.
			lda	diskBlkBuf,x		;Byte #1 aus Puffer einlesen
			sta	GRAM_PAGE_DATA+0	;und zurückschreiben.
			lda	fileHeader,x		;Byte #2 aus Puffer einlesen
			sta	GRAM_PAGE_DATA+1	;und zurückschreiben.
			dex				;Zeiger auf nächste Speicherbank.
			cpx	#255			;Alle Speicherbänke bearbeitet?
			bne	:7			;Nein, weiter...

::8			ldx	#NO_ERROR		;Kein Fehler.
			rts
