; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Größe C=REU/CMD-REU testen
;
;Übergabe : -
;Rückgabe : r2/r3 = Größe C=REU in Bytes
;           Y = Anzahl 64K-Speicherbänke:
;                   0Kb:   0
;                  64Kb:   1
;                 128Kb:   2
;                 ...
;                8192Kb: 128
;               16384Kb: 255  ;Sonderfall, da 256 nicht möglich.
;           X = Fehlerstatus:
;               $00 = OK
;               $0D = Keine C=REU
;Verändert: A,X,Y,r2-r3,diskBlkBuf,fileHeader

:ULIB_SIZE_CREU

			lda	#$00			;Größe C=REU löschen.
			sta	r2L
			sta	r2H
			sta	r3L
			sta	r3H

			jsr	ULIB_128_SLOW		;Für C=REU auf 1Mhz umschalten.

			jsr	_ulib_mb_creu		;Erkennungsroutine starten.

			tya				;Mind. 1 Speicherbank?
			beq	:no_creu		; => Nein, keine C=REU...

			sta	r3L
			cmp	#255			;Sonderfall 16Mb C=REU?
			bne	:ok			; => Nein, weiter...
			inc	r3L			;Anzahl Bytes korrigieren.
			inc	r3H			; => $0100:0000

::ok			ldx	#NO_ERROR
			b $2c
::no_creu		ldx	#DEV_NOT_FOUND

			jsr	ULIB_128_RESTORE	;CLKRATE zurücksetzen.

			rts

;*** C=REU Bankanzahl testen.
;Übergabe : -
;Rückgabe : Y = Anzahl 64K-Speicherbänke:
;                   0Kb:   0
;                  64Kb:   1
;                 128Kb:   2
;                 ...
;                8192Kb: 128
;               16384Kb: 255  ;Sonderfall, da 256 nicht möglich.
;Verändert: A,X,Y,diskBlkBuf,fileHeader
:_ulib_mb_creu		lda	#0			;Zeiger auf erste Bank.
::backup		pha				;Aktuelle Bank-Adresse speichern.

			tay				;Speicherbank in Y-Register.
			jsr	_ulib_mb_read		;Testbyte einlesen.

			pla
			tay				;Bank-Adresse einlesen,
			lda	diskBlkBuf		;Testbyte einlesen und in
			sta	fileHeader,y		;Zwischenspeicher kopieren.

			iny
			tya				;Alle Testbytes ausgelesen ?
			bne	:backup			; => Nein, weiter...

;--- Prüfbytes (Bank-Adresse) in jede Bank ab Byte #0 speichern.
::write			lda	#255			;Zeiger auf Test-Speicherbank.
::1			pha				;Bank-Adresse speichern.
			sta	diskBlkBuf		;Prüfbyte speichern.

			tay				;Speicherbank in Y-Register.
			jsr	_ulib_mb_write		;Prüfbyte in REU übertragen.

			pla
			sec				;Zeiger auf nächste Bank setzen.
			sbc	#1			;Alle Bänke bearbeitet ?
			bcs	:1			; => Nein, weiter...

::test			lda	#0			;Zeiger auf Bank #0.
::2			pha				;Bank-Adresse speichern.

			tay				;Speicherbank in Y-Register.
			jsr	_ulib_mb_read		;Prüfbyte aus REU einlesen.

			pla				;Bank-Adresse einlesen und mit
			cmp	diskBlkBuf		;Prüfbyte vergleichen.
			bne	:done			; => Fehler, REU-Größe erkannt.

			clc
			adc	#1			;Alle Testbytes ausgelesen ?
			bcc	:2			; => Nein, weiter...

			sec	 			;Max. 255x64K adressieren.
			sbc	#1			; => 16Mb C=REU...

::done			pha				;REU-Größe speichern.

;--- Original-Inhalt der REU wiederherstellen.
::read			lda	#255			;Zeiger auf letzte Speicherbank.
::restore		pha				;Bank-Adresse speichern.
			tay
			lda	fileHeader,y		;Original-Inhalt einlesen und in
			sta	diskBlkBuf		;Zwischenspeicher übertragen.

;			tay				;Speicherbank in Y-Register.
			jsr	_ulib_mb_write		;Inhalt zurück in die REU.

			pla
			sec				;Zeiger auf nächste Bank setzen.
			sbc	#1			;Alle Bänke bearbeitet ?
			bcs	:restore		; => Nein, weiter...

			pla
			tay				;max. REU-Größe Übergeben.

			rts

;*** C=REU-Read/Write ausführen.
;Übergabe : Y = Speicherbank
;Rückgabe : -
;Verändert: A,X,Y
:_ulib_mb_read		lda	#%10010001
			b $2c
:_ulib_mb_write		lda	#%10010000

			pha

			ldx	#$00
			stx	CREU_RAMREG + 2		;Startadresse Computer : LOW
			lda	#>diskBlkBuf
			sta	CREU_RAMREG + 3		;Startadresse Computer : HIGH

			stx	CREU_RAMREG + 4		;Startadresse REU      : LOW
			stx	CREU_RAMREG + 5		;Startadresse REU      : HIGH
			sty	CREU_RAMREG + 6		;Bankadresse in REU

			lda	#1
			sta	CREU_RAMREG + 7		;Anzahl Bytes          : LOW
			stx	CREU_RAMREG + 8		;Anzahl Bytes          : HIGH

			stx	CREU_RAMREG + 9		;Interrupt-Mask Register
			stx	CREU_RAMREG +10		;Adress-Kontroll Register

			pla
			sta	CREU_RAMREG + 1		;Job-Code setzen
::wait			lda	CREU_RAMREG + 0		;Warten bis Übertragung beendet
			and	#%01100000
			beq	:wait

			rts
