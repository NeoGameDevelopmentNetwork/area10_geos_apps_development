; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Hintergrundbild anzeigen.
;Übergabe:  dataFileName = Name GeoPaint-Datei.
;           a0L = $00: Farb-RAM nicht löschen.
;                 $80: Farb-RAM löschen.
;           a2  = Puffer für GeoPaint-Daten (2*80*8+8+2*80 = 1448 Bytes)
;
;Verwendet: a2  = Zeiger auf Grafikdaten Zeile #1.
;           a3  = Zeiger auf Grafikdaten Zeile #2.
;           a4  = Zeiger auf 8Byte-Datenspeicher.
;           a5  = Zeiger auf Farbdaten Zeile #1.
;           a6  = Zeiger auf Farbdaten Zeile #2.
:ViewPaintFile		ldx	#0			;Zeiger berechnen für:
::1			lda	a2L			; - Grafikzeile #1
			clc				; - Grafikzeile #2
			adc	scrnBaseData +0,x	; - Farbzeile #1
			sta	a3L,x			; - Farbzeile #2
			lda	a2H
			adc	scrnBaseData +1,x
			sta	a3H,x
			inx
			inx
			cpx	#8
			bcc	:1

			bit	a0L			;Farb-RAM löschen?
			bpl	:load			; => Nein, weiter...

			jsr	GetBorderCol

::load			LoadW	r0,dataFileName
			jsr	OpenRecordFile		;geoPaint-Dokument öffnen.
			txa				;Fehler?
			bne	:53			; => Ja, Abbruch...

			bit	a0L			;Farb-RAM löschen?
			bpl	:50			; => Nein, weiter...

			lda	backScrnCol
			jsr	i_UserColor		;Farb-RAM löschen.
			b	$00,$00,$28,$19

::50			LoadW	r14,SCREEN_BASE		;Zeiger auf Grafikspeicher.
			LoadW	r15,COLOR_MATRIX

			lda	#$00
::51			sta	a9H			;VLIR-Datensatz-Nr.

			jsr	Get80Cards		;Grafikzeile einlesen.
			jsr	Prnt_Grfx_Cols		;Grafikzeile ausgeben.

			inc	a9H			;Nächster Datensatz.
			lda	a9H
			cmp	usedRecords		;Ende geoPaint-Dokument erreicht?
			bcs	:52			; => Ja, Ende...
			cmp	#13			;Bildschirm voll?
			bcc	:51			; => Nein, weiter...

::52			ldx	#NO_ERROR
::53			txa
			pha
			jsr	CloseRecordFile		;geoPaint-Dokument schließen.
			pla
			tax
			rts

;
; Startadresse Daten in VLIR-Datensatz.
;
:scrnBaseData		w 640
			w 640 +640
			w 640 +640 +8
			w 640 +640 +8 +80

;*** Rahmenfarbe einlesen.
:GetBorderCol		php				;Hintergrundfarbe löschen.
			sei

			ldx	CPU_DATA
			lda	#$35			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	extclr			;Rahmenfarbe einlesen.
			and	#%00001111		;Rahmenfarbe isolieren.
			sta	r0L

			asl				;Farbe für Vorder- und
			asl				;Hintergrundfarbe berechnen.
			asl
			asl

			ora	r0L
			sta	backScrnCol

			stx	CPU_DATA		;I/O-Bereich ausblenden.

			plp
			rts

;
; Zwischenspeicher Hintergrundfarbe
;
:backScrnCol		b $00

;*** Grafikdaten ausgeben.
;Eine geoPaint-Zeile besteht aus zwei
;Grafikzeilen a 8 Pixel Höhe.
:Prnt_Grfx_Cols		lda	a2L			;Zeile #1 ausgeben.
			ldx	a2H
			jsr	MoveGrfx
			lda	a5L
			ldx	a5H
			jsr	MoveCols

			lda	a9H			;12*2 +1 Zeilen.
			cmp	#12
			bcs	:1

			lda	a3L			;Zeile #2 ausgeben.
			ldx	a3H
			jsr	MoveGrfx
			lda	a6L
			ldx	a6H
			jsr	MoveCols

::1			rts

;*** Grafikdaten in Bildschirm kopieren.
:MoveGrfx		sta	r0L			;Zeiger auf C64-Grafikspeicher.
			stx	r0H

			LoadW	r2,40*8			;Anzahl Bytes in einer Zeile.

			lda	r14L			;Startadresse Zwischenspeicher
			sta	r1L			;setzen und Position für nächste
			clc				;Grafikzeile berechnen.
			adc	r2L
			sta	r14L
			lda	r14H
			sta	r1H
			adc	r2H
			sta	r14H

			jmp	MoveData		;Grafikdaten kopieren.

;*** Farbdaten in Bildschirm kopieren.
:MoveCols		sta	r0L			;Zeiger auf C64-Farbspeicher.
			stx	r0H

			LoadW	r2,40			;Anzahl Bytes in einer Zeile.

			lda	r15L			;Startadresse Zwischenspeicher
			sta	r1L			;setzen und Position für nächste
			clc				;Grafikzeile berechnen.
			adc	r2L
			sta	r15L
			lda	r15H
			sta	r1H
			adc	r2H
			sta	r15H

			jmp	MoveData		;Farbdaten kopieren.

;*** Eine Grafikzeile (80 Cards/8 Pixel hoch) einlesen.
:Get80Cards		jsr	PointRecord		;Zeiger auf Grafikzeile.
			txa				;Fehler?
			bne	NoGrfxData		; => Ja, Abbruch...
			tya
			bne	LoadVLIR_Data

:NoGrfxData		LoadW	r0,1448			;Leere Grafikzeile ausgeben.
			MoveW	a2,r1
			LoadB	r2L,NULL
			jmp	FillRam

;*** Grafikbytes aus Datensatz einlesen.
:LoadVLIR_Data		LoadW	r4,diskBlkBuf		;Zeiger auf Diskettenspeicher.
			jsr	GetBlock		;Ersten Sektor des aktuellen
			txa				;Datensatzes einlesen. Fehler ?
			bne	NoGrfxData		; => Ja, nächste Zeile...

			MoveW	a2,r0			;Zeiger auf Grafikdatenspeicher.

			ldx	#$01			;Zeiger auf erstes Byte in Datei.
			stx	r5H
:GetNxDataByte		jsr	GetNxByte		;Nächstes Byte einlesen.
			sta	r2H			;Byte zwischenspeichern.

			ldy	#$00
			bit	r2H			;Gepackte Daten ?
			bmi	GetPackedBytes		;Ja, weiter...

			lda	r2H
			and	#$3f			;Anzahl Bytes ermitteln.
			beq	EndOfData		;$00 = Keine Daten.
			sta	r2H			;Anzahl Bytes merken.
			bvs	Repeat8Byte		;Bit #6 = 1, 8-Byte-Packformat.

::1			jsr	GetNxByte		;Byte einlesen und in Grafikdaten-
			sta	(r0L),y			;speicher kopieren.
			iny
			cpy	r2H			;Alle Bytes gelesen ?
			bne	:1			;Nein, weiter...

;*** Zeiger auf Grafikdatenspeicher korrigieren.
:SetNewMemPos		tya				;Zeiger auf Grafikdatenspeicher
			clc				;korrigieren.
			adc	r0L
			sta	r0L
			bcc	GetNxDataByte
			inc	r0H
			bne	GetNxDataByte		;Nächstes Byte einlesen.
:EndOfData		rts

;*** 8-Byte-Daten wiederholen.
:Repeat8Byte		jsr	GetNxByte		;Nächstes Byte aus Datensatz
			sta	(a4L),y			;einlesen und in Zwischenspeicher.
			iny				;Zeiger auf nächstes Byte.
			cpy	#$08			;8 Byte eingelesen ?
			bne	Repeat8Byte		;Nein, weiter...

			ldx	#$00
::1			ldy	#$07			;8 Byte in Grafikdatenspeicher.
::2			lda	(a4L),y
			sta	(r0L),y
			dey
			bpl	:2
			lda	r0L			;Zeiger auf Grafikdatenspeicher
			clc				;korrigieren.
			adc	#$08
			sta	r0L
			bcc	:3
			inc	r0H
::3			inx				;Anzahl Wiederholungen +1.
			cpx	r2H			;Wiederholungen beendet ?
			bne	:1			;Nein, weiter...
			beq	GetNxDataByte		;Weiter mit nächstem Byte.

;*** Gepackte Daten einlesen.
:GetPackedBytes		lda	r2H			;Anzahl gepackte Daten berechnen.
			and	#$7f
			beq	EndOfData		;$00 = Keine Daten, Ende...
			sta	r2H			;Anzahl Bytes merken.
			jsr	GetNxByte		;Datenbyte einlesen.

			ldy	r2H
			dey				;Byte in Grafikdatenspeicher
::1			sta	(r0L),y			;kopieren (Anzahl in ":r2H")
			dey
			bpl	:1

			ldy	r2H			;Zeiger auf Grafikdatenspeicher
			bne	SetNewMemPos		;korrigieren.

;*** Nächstes Byte aus Paint-Datei einlesen.
:GetNxByte		ldx	r5H
			inx
			bne	RdBytFromSek
			lda	r1L
			bne	GetNxSektor

:GfxLoadError		jmp	NoGrfxData		;Leere Zeile ausgeben.

;*** Nächsten Sektor aus Paint-Datensatz einlesen.
:GetNxSektor		sty	a9L

			lda	diskBlkBuf +0		;Zeiger auf nächsten Sektor.
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jsr	GetBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	GfxLoadError		; => Ja, Abbruch...

			ldy	a9L
			ldx	#$02			;Zeiger auf erstes Byte in Sektor.

;*** Nächstes Byte aus Sektor einlesen.
:RdBytFromSek		lda	r1L			;Letzter Sektor?
			bne	:1			; => Nein, weiter....
			cpx	r1H			;Letztes Bytes aus letztem Sektor?
			bcc	:1			; => Nein, weiter....
			bne	GfxLoadError		; => Ja, Abbruch....

::1			lda	diskBlkBuf,x		;Byte aus Sektor einlesen.
			stx	r5H			;Bytezeiger speichern.
			rts
