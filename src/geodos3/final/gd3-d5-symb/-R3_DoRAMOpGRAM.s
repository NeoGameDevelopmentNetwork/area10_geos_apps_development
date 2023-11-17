; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemroutine für Zugriff auf GeoRAM.
;    Übergabe:		AKKU = BANK-Größe 16/32/64Kb
;Im Laufwerkstreiber wird dieser Wert durch INIT_RAMNM_GRAM in ":GeoRAMBSize"
;gespeichert und ist vor dem Aufruf der Routine einzulesen.
;Die Routine INIT_RAMNM_GRAM ermittelt diesen Wert und verwendet für den
;Aufruf dieser Routine eine lokale Kopie.
;Dadurch kann die Routine unverändert für beide Programmteile genutzt werden.
:DoRAMOp_GRAM		ldx	#%11111111		;Maskenbits für Bank-Größe
			cmp	#$40			;ermitteln.
			beq	:50
			ldx	#%01111111
			cmp	#$20
			beq	:50
			ldx	#%00111111
::50			sta	BBG_BSIZE+1		;Bank-Größe speichern.
			stx	BBG_BMASK+1		;Masken-Bits speichern.

			ldx	#$0f
::51			lda	r0L,x			;Register ":r0" bis ":r7"
			pha				;zwischenspeichern.
			dex
			bpl	:51

			tya				;Job-Adresse aus Tabelle einlesen
			and	#%00000011		;und in ":r6" als Sprung-Vektor
			asl				;zwischenspeichern.
			tay
			lda	BBG_JobAdr +0,y
			sta	r6L
			lda	BBG_JobAdr +1,y
			sta	r6H

			lda	#> $de00		;High-Byte für REU-Adresse immer
			sta	r5H			;auf $DExx setzen.
			lda	r1L			;":r5" zeigt jetzt auf das erste
			sta	r5L			;benötigte Byte auf der REU-Seite.
			jsr	DefBBG_Page		;Speicher-Seite berechnen.

:SetCopyData		lda	#$01			;$0100 Bytes als Startwert für
			sta	r7H			;RAM-Routinen.
			lda	#$00
			tay
			sta	r7L
			sec				;Anzahl der zu kopierenden Bytes
			sbc	r5L			;berechnen.
			sta	r7L
			lda	r7H
			sbc	#$00
			sta	r7H

			lda	r7H
			cmp	r2H
			bne	:51
			lda	r7L
			cmp	r2L			;Weniger als 256 Byte kopieren ?
::51			bcc	:52			;Nein, weiter...

			lda	r2H
			sta	r7H
			lda	r2L
			sta	r7L
::52			ldx	r7L			;Anzahl zu bearbeitender Bytes.
			jmp	(r6)			;RAM-Job ausführen.

;*** Variablen & Zeiger für nächsten Job-Aufruf korrigieren.
:DefNextJob		lda	r7L			;Zeiger auf C64-Adresse korrigieren.
			clc
			adc	r0L
			sta	r0L
			lda	r7H
			adc	r0H
			sta	r0H

			lda	r2L			;Anzahl bereits bearbeiteter Bytes
			sec				;korrigieren.
			sbc	r7L
			sta	r2L
			lda	r2H
			sbc	r7H
			sta	r2H

			lda	#$00			;LOW-Byte Speicherseite auf #0
			sta	r5L			;setzen (Speicherseite ab $DE00).

			inc	r1H			;Zeiger auf nächste Speicherseite.
			bne	:51			;Ende erreicht ?
			inc	r3L			;Ja, High-Byte/Bank korrigieren.
::51			jsr	DefBBG_Page		;Speicher-Seite berechnen.
			lda	r2L
			ora	r2H			;Alle Bytes kopiert ?
			bne	SetCopyData		;Nein, weiter.

			ldx	#%01000000		;Abschlußbyte "OK".
			b $2c
:VerifyError		ldx	#%00100000
			ldy	#$00
::51			pla				;Register ":r0" bis ":r7"
			sta	r0,y			;wieder zurücksetzen.
			iny
			cpy	#$10
			bne	:51
			txa				;Ende DoRAMOp.
			ldx	#NO_ERROR
			rts

;*** C64-RAM nach GeoRAM kopieren.
:CopyC64_GRAM		lda	(r0L),y
			sta	(r5L),y
			iny
			dex
			bne	CopyC64_GRAM
			beq	DefNextJob

;*** GeoRAM nach C64-RAM kopieren.
:CopyBBG_C64		lda	(r5L),y
			sta	(r0L),y
			iny
			dex
			bne	CopyBBG_C64
			beq	DefNextJob

;*** C64-RAM mit GeoRAM tauschen.
:SwapC64_GRAM		lda	(r0L),y
			pha
			lda	(r5L),y
			sta	(r0L),y
			pla
			sta	(r5L),y
			iny
			dex
			bne	SwapC64_GRAM
			beq	DefNextJob

;*** C64-RAM mit GeoRAM vergleichen.
:CompC64_GRAM		lda	(r0L),y
			cmp	(r5L),y
			bne	VerifyError
			iny
			dex
			bne	CompC64_GRAM
			beq	DefNextJob

;*** Einsprungsadressen für Job-Codes.
:BBG_JobAdr		w CopyC64_GRAM
			w CopyBBG_C64
			w SwapC64_GRAM
			w CompC64_GRAM

;*** GeoRAM-Speicherseite berechnen.
:DefBBG_Page		lda	r1H			;GeoRAM-Highbyte
			pha				;zwischenspeichern.
:BBG_BMASK		and	#$ff			;Low-Byte Speicherbank definieren.
			sta	$dffe

			lda	r3L			;64K-Speicherbank einlesen und
:BBG_BSIZE		ldx	#$ff			;in GeoRAM 16/32/64K-Bank
			cpx	#$40			;umrechnen.
			beq	:3
			asl	r1H
			rol
			cpx	#$20
			beq	:3
			asl	r1H
			rol
::3			sta	$dfff			;Speicherbank aktivieren.

			pla				;GeoRAM-Highbyte
			sta	r1H			;zurücksetzen.
			rts
