; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateiname aus Verzeichniseintrag kopieren.
;    Übergabe: XReg = ZeroPage-Register/Zeiger Verzeichnis-Eintrag.
;              YReg = ZeroPage-Register/Zeiger auf 17Byte-Puffer.
.SysCopyFName		lda	$00,x			;Zeiger auf Dateiname korrigieren.
			pha				;Original-Adresse speichern.
			clc
			adc	#$05
			sta	zpage +0,x
			lda	zpage +1,x
			pha
			adc	#$00
			sta	zpage +1,x

			txa				;Zeiger auf Quelle sichern.
			pha

			jsr	SysCopyName		;Dateiname kopieren.

			pla				;Zeiger auf Quelle zurücksetzen.
			tax

			pla				;Zeiger auf Verzeichnis-
			sta	zpage +1,x		;Eintrag zurücksetzen.
			pla
			sta	zpage +0,x
			rts

;*** Name kopieren.
;--- HINWEIS:
;Name rückwärts auf $00/$A0 testen, da
;modifizierte Dateien mit $A0 im Namen
;sonst nicht kopiert werden können.
.SysFilterName		lda	#$ff			;Ungültige Zeichen filtern.
			b $2c
.SysCopyName		lda	#$00			;Name ungefiltert kopieren.
			sta	:filter_mode		;Filtermodus speichern.

			stx	:read1 +1
			stx	:read2 +1
			sty	:write1 +1
			sty	:write2 +1

			ldy	#15			;Letztes Zeichen im Dateinamen
::read1			lda	(r0L),y			;suchen das nicht $00/$A0 ist.
			beq	:1
			cmp	#$a0
			bne	:copy
::1			dey
			bpl	:read1

			iny				;Mind. 1 Zeichen kopieren.

::copy			iny				;Position zwischenspeichern.
			tya
			pha
			dey

::read2			lda	(r0L),y			;Zeichen aus Dateiname einlesen.
			bit	:filter_mode		;Ungültige zeichen filtern?
			bpl	:write1
			and	#%01111111		;Unter GEOS nur Zeichen $20-$7E.
			cmp	#$20			;ASCII < $20?
			bcc	:filter			; => Ja, Zeichen ersetzen.
			cmp	#$7f			;ASCII < $7F?
			bcc	:write1			; => Ja, weiter...
::filter		lda	#GD_REPLACE_CHAR	;Zeichen ersetzen.
::write1		sta	(r0L),y			;Zeichen in Puffer kopieren.
			dey				;Puffer voll?
			bpl	:read2			; => Nein, weiter...

			pla				;Zeiger auf letztes Byte im
			tay				;Dateinamen setzen.

;--- Ende, Puffer mit $00-Bytes auffüllen.
::end			lda	#NULL			;Dateiname auf 17 Zeichen mit
::write2		sta	(r0L),y			;$00-Bytes auffüllen.
			iny
			cpy	#16 +1
			bcc	:write2

			rts

::filter_mode		b $00
