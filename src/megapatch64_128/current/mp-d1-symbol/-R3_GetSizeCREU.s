; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Definieren der C=REU-Register.
:CREU_BSIZE_64K		= 64

;*** Systemvariablen.
:CREU_SIZE_KB		w $0000
:CREU_BANK_COUNT	b $00

;*** Standardwerte setzen und GeoRAM-Erkennung.
:CREU_GET_SIZE		jsr	CREU_GET_BCOUNT		;Anzahl 64K-Bänke ermitteln.

;*** C=REU-Erkennung abgeschlossen.
:ExitCReuTest		lda	CREU_BANK_COUNT		;Speicher verfügbar?
			beq	:1			; => Nein, Ende...

;*** C=REU-Größe berechnen.
			sta	r0L			;Anzahl der Speicherbänke zur
			lda	#$00			;Berechnung der GEOS/MP3 64Kb
			sta	r0H			;Speicherbänke in r0 ablegen.

			lda	#CREU_BSIZE_64K		;Größe der Speicherbänke
			sta	r1L			;in r1L ablegen.

			ldx	#r0L			;BMult für WORD*BYTE aufrufen.
			ldy	#r1L
			jsr	BMult
			MoveW	r0,CREU_SIZE_KB		;Größe der C=REU speichern.

			ldx	#NO_ERROR
			b $2c
::1			ldx	#DEV_NOT_FOUND		;GeoRAM nicht erkannt.
			rts

;*** Größe des C=REU-Speichers ermitteln.
:CREU_GET_BCOUNT	php				;IRQ sperren.
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
			lda	RAM_Conf_Reg
			pha
			lda	#$40			;keine CommonArea VIC =
			sta	RAM_Conf_Reg		;Bank1 für REU Transfer
			lda	CLKRATE			;aktuellen Takt
			pha				;zwischenspeichern.
			lda	#$00			;auf 1 Mhz schalten!
			sta	CLKRATE			;Sonst geht nichts!
endif

			jsr	sysGetBCntCREU		;Erkennungsroutine starten.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla				;aktuellen Takt zurücksetzen
			sta	CLKRATE
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif

			plp

;--- Ergänzung: 14.08.18/M.Kanet
;Code wird auch von GEOS128.BOOT in Bank#0/#1 verwendet. Variablen erst nach
;dem zurücksetzen der MMU im RAM speichern.
			tya
			sta	CREU_BANK_COUNT
			beq	:6
			ldx	#NO_ERROR
			b $2c
::6			ldx	#DEV_NOT_FOUND
			rts

;*** C=REU Bankanzahl testen, keine Änderung von MMU, CLKRATE und RAM_Reg_Buf.
:sysGetBCntCREU		ldx	#$00			;Zeiger auf Bank #0.
::1			stx	r0L			;Aktuelle Bank-Adresse speichern.
			jsr	TestREUByteRd		;Testbyte einlesen.
			ldx	r0L			;Bank-Adresse einlesen,
			lda	diskBlkBuf		;Testbyte einlesen und in
			sta	fileHeader,x		;Zwischenspeicher kopieren.
			inx				;Alle Testbytes #0-#255 ausgelesen ?
			bne	:1			; => Nein, weiter...

;--- Prüfbytes (Bank-Adresse) in jede Bank ab Byte #0 speichern.
			dex				;Zeiger auf letzte Speicherbank.
::2			stx	r0L			;Bank-Adresse speichern.
			stx	diskBlkBuf		;Prüfbyte speichern.
			jsr	TestREUByteWr		;Prüfbyte in REU übertragen.
			ldx	r0L			;Bank-Adresse einlesen und
			dex				;Zeiger auf nächste Bank setzen.
			cpx	#$ff			;Alle Bänke bearbeitet ?
			bne	:2			; => Nein, weiter...

			inx				;Zeiger auf Bank #0.
::3			stx	r0L			;Bank-Adresse speichern.
			jsr	TestREUByteRd		;Prüfbyte aus REU einlesen.
			ldx	r0L			;Bank-Adresse einlesen und mit
			cpx	diskBlkBuf		;Prüfbyte vergleichen.
			bne	:4			; => Fehler, REU-Größe erkannt.
			inx				;Alle Bänke überprüft ?
			bne	:3			; => Nein, weiter...
			dex				;Max. 255x64K adressieren.
::4			stx	CREU_BANK_COUNT		;REU-Größe speichern.

;--- Original-Inhalt der REU wiederherstellen.
			ldx	#$ff			;Zeiger auf letzte Speicherbank.
::5			stx	r0L			;Bank-Adresse speichern.
			lda	fileHeader,x		;Original-Inhalt einlesen und in
			sta	diskBlkBuf		;Zwischenspeicher übertragen.
			jsr	TestREUByteWr		;Inhalt zurück in die REU.
			ldx	r0L			;Bank-Adresse einlesen.
			dex				;Zeiger auf nächste Bank setzen.
			cpx	#$ff			;Alle Bänke bearbeitet ?
			bne	:5			; => Nein, weiter...

			ldy	CREU_BANK_COUNT		;max. REU-Größe Übergeben.
			rts

;*** C=REU-Read/Write ausführen.
:TestREUByteRd		lda	#%10010001
			b $2c
:TestREUByteWr		lda	#%10010000

			pha

			ldx	#$00
			ldy	#$01
			stx	EXP_BASE1 + 2		;Startadresse low Computer
			lda	#>diskBlkBuf
			sta	EXP_BASE1 + 3		;Startadresse high Computer

			stx	EXP_BASE1 + 4		;Startadresse low REU
			stx	EXP_BASE1 + 5		;Startadresse high REU = $0000
			lda	r0L
			sta	EXP_BASE1 + 6		;aktuelle Bank

			sty	EXP_BASE1 + 7		;Anzahl zu übertragender Bytes low
			stx	EXP_BASE1 + 8		;Anzahl zu übertragender Bytes high

			stx	EXP_BASE1 + 9		;Interrupt-Mask Register
			stx	EXP_BASE1 +10		;Adress-Kontroll Register

			pla				;Kommando
			sta	EXP_BASE1 + 1		;ins Kommandoregister
::51			lda	EXP_BASE1 + 0		;warten bis Übertragung beendet
			and	#%01100000
			beq	:51

			rts
