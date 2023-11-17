; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;******************************************************************************
;*** Unterprogramme zum erzeugen von MSDOS-Dateinamen.
;******************************************************************************

;*** Gültigen Dateinamen erzeugen.
:CheckCurFileNm		lda	#$00
			sta	r15L
			sta	r15H

::101			LoadW	r6,FileNameDOS
			jsr	FindFile
			txa
			beq	:102
			rts

::102			ldy	r15L
			bne	:107
			lda	#"1"
			sta	r15H
::103			lda	FileNameDOS,y
			cmp	#"."
			bne	:104
			dey
			dey
			bne	:106

::104			cmp	#" "
			bne	:105
			cpy	#$07
			bcc	:106
			dey
			bne	:106
::105			iny
			bne	:103

::106			lda	#"0"
			sta	FileNameDOS,y
			iny
			sta	FileNameDOS,y
			dey
			sty	r15L
			sta	r15H
			jmp	:101

::107			ldx	r15L
			inc	FileNameDOS+1,x
			lda	FileNameDOS+1,x
			cmp	#$3a
			bcc	:101
			lda	#$30
			sta	FileNameDOS+1,x
			inc	FileNameDOS+0,x
			jmp	:101

;*** CBM-Dateiname nach MSDOS wandeln.
:SetNameDOS		PushW	r0
			jsr	ConvTextDOS		;Zeichen nach MSDOS wandeln.

			PopW	r0
			LoadW	r1,FileNameDOS
			jsr	ConvNameDOS		;Dateiname nach 8+3 wandeln.

			ldy	#12
			lda	#$00
::101			sta	FileNameDOS,y
			iny
			cpy	#17
			bcc	:101
			rts

;*** Zeichen in MSDOS-Format wandeln.
:ConvTextDOS		ldy	#$00
::101			lda	(r0L),y
			beq	:103
			cmp	#$60
			bcc	:102
			sbc	#$20
			sta	(r0L),y
			bcs	:101
::102			iny
			bne	:101
::103			rts

;*** Prüfen ob Zeichen erlaubt.
:L360g1			sty	:514 +1

			ldx	#$00
			ldy	#$00
::511			ldx	CharForDOS,y
			beq	:514
			cmp	CharForDOS,y
			beq	:513
			iny
			jmp	:511

::513			ldx	#$ff
::514			ldy	#$ff
			rts

;******************************************************************************
;*** Unterprogramme zum erzeugen von MSDOS-Dateinamen.
;******************************************************************************

;*** Dateinamen konvertieren.
:ConvNameDOS		ldy	#11
::401			lda	#$00			;Zwischenspeicher löschen.
			sta	FileNameBuf,y
			sta	(r1L),y
			dey
			bpl	:401

			ldy	#11
			lda	#" "			;Zieltextspeicher löschen.
::402			sta	(r1L),y
			dey
			bpl	:402

			iny
			sty	r2L
			sty	r2H
			sty	r3L
			sty	r4H

::403			lda	(r0L),y			;Zeichen aus Text einlesen.
			beq	:407			;$00-Byte ? Ja, Textende...

			cmp	#"."			;Mit Punkt vergleichen.
			bne	:404			;Kein Punkt, weiter...

			ldx	r2L			;Punkt im Dateinamen ?
			bne	:406			;Ja, weiter...
			ldx	r2H			;Zeichen im Dateinamen ?
			beq	:406			;Nein, weiter...
			stx	r2L			;Position Punkt speichern.
			jmp	:405			;Punkt in Zieltext übernehmen.

::404			jsr	L360g1			;Zeichen erlaubt ?
			cpx	#$ff
			beq	:405			;Ja, weiter...
			inc	r4H			;Nein, "ungültige Zeichen"
			jmp	:406			;korrigieren, nächstes Zeichen.

::405			ldy	r2H			;Zeichen in Zwischenspeicher.
			sta	FileNameBuf,y
			cpy	#15			;max. 16 Zeichen übernehmen.
			beq	:407			;Erreicht, ende...
			inc	r2H

::406			inc	r3L			;Zeiger auf nächstes Zeichen.
			ldy	r3L
			cpy	#16			;Max. 16 Zeichen.
			beq	:407			;Erreicht ? Ja, Ende...
			bne	:403			;Nein, nächstes Zeichen.

::407			ldy	r2H			;Textlänge = 0 ?
			bne	:409			;Nein, weiter...
			ldx	#$ff			;Ungültiger Text.
::408			rts

::409			ldy	#$00
			sty	r3L
			sty	r3H

::410			lda	FileNameBuf,y		;Zeichen aus Speicher holen.
			beq	:427			;$00-Byte = Textende.
			cmp	#"."			;"." erreicht ?
			beq	:420

::411			ldy	r3H
			sta	(r1L),y			;Zeichen in MSDOS 8+3-Speicher
			inc	r3H			;übertragen.
			cpy	#$07			;Name 8 Zeichen erreicht ?
			beq	:420			;Ja, Ende...

			inc	r3L			;Nächstes Zeichen kopieren.
			ldy	r3L
			jmp	:410

;******************************************************************************
;*** Unterprogramme zum erzeugen von MSDOS-Dateinamen.
;******************************************************************************

;*** Dateinamen konvertieren.
::420			ldy	#$08			;Punkt zwischen Name und
			lda	#"."			;Extension einfügen.
			sta	(r1L),y
			iny
::421			sty	r3H

::422			ldx	r3L			;Zeiger innerhalb Zwischenspeicher
			lda	r2L			;setzen. Falls "." vorhanden, Zeiger
			beq	:423			;hinter "." setzen.
			tax
::423			inx
			stx	r3L

::424			ldy	r3L
			cpy	r2H			;Ende Zwischenspeicher erreicht ?
			beq	:425			;Nein, weiter...
			bcs	:427			;Ja, Ende...
::425			lda	FileNameBuf,y		;Extension erzeugen.
			beq	:427
			ldy	r3H
			sta	(r1L),y
			cpy	#11
			beq	:427
			inc	r3H
::426			inc	r3L
			jmp	:424

::427			ldx	#$00			;Eingabe OK!
			rts

;*** Textstring verdichten.
:L360f0			ldy	#$00
			ldx	#$00
::451			lda	(r0L),y			;Zeichen aus Text einlesen.
			beq	:454			;$00-Byte ? Ja, Ende...
			cmp	#" "			;Leerzeichen ?
			beq	:453			;Ja, überlesen.

::452			sta	FileNameBuf,x		;In Zwischenspeicher übertragen.
			inx
::453			iny
			cpy	#12
			bne	:451

::454			txa
			tay

::455			cpy	#12
			beq	:456

			lda	#$00			;Rest des Speicher mit $00-Bytes
			sta	FileNameBuf,y		;auffüllen.
			iny
			jmp	:455

::456			txa				;Länge des Strings = 0 ?
			bne	:458			;Nein, weiter...
::457			ldx	#$ff			;Eingabe ungültig.
			rts

::458			dex
			lda	FileNameBuf,x
			cmp	#"."			;Letztes Zeichen = Punkt ?
			bne	:459			;Nein, Ende...

			cpx	#$00			;Nur ein Zeichen (".") im Text ?
			beq	:457
			beq	:460			;Ja, Fehler...

::459			cmp	#" "
			bne	:461

::460			lda	#$00
			sta	FileNameBuf,x		;Punkt löschen.
			jmp	:458

::461			ldx	#$00
			rts

;******************************************************************************
;*** Unterprogramme zum erzeugen von MSDOS-Dateinamen.
;******************************************************************************

;*** Variablen.
:FileNameDOS		s 17
:FileNameBuf		s 17
