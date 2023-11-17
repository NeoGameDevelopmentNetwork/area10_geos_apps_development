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

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			jsr	sysGetBCntCREU		;Erkennungsroutine starten.

			pla
			sta	CPU_DATA

			plp

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
:TestREUByteRd		lda	#jobFetch
			b $2c
:TestREUByteWr		lda	#jobStash

			pha

			ldx	#$00
			ldy	#$01
			stx	EXP_BASE1 + 2		;Startadresse Computer : LOW
			lda	#>diskBlkBuf
			sta	EXP_BASE1 + 3		;Startadresse Computer : HIGH

			stx	EXP_BASE1 + 4		;Startadresse REU      : LOW
			stx	EXP_BASE1 + 5		;Startadresse REU      : HIGH
			lda	r0L			; => $0000
			sta	EXP_BASE1 + 6		;Aktuelle Bank

			sty	EXP_BASE1 + 7		;Anzahl Bytes          : LOW
			stx	EXP_BASE1 + 8		;Anzahl Bytes          : HIGH

			stx	EXP_BASE1 + 9		;Interrupt-Mask Register
			stx	EXP_BASE1 +10		;Adress-Kontroll Register

			pla
			sta	EXP_BASE1 + 1		;Job-Code setzen
::51			lda	EXP_BASE1 + 0		;Warten bis Übertragung beendet
			and	#%01100000
			beq	:51

			rts
