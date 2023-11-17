; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Hintergrundbild wechseln.
:SelectBackScrn		lda	#<AppClassPaint		;GEOS-Klasse für
			sta	r10L			;GeoPaint-Dokumente setzen.
			lda	#>AppClassPaint
			sta	r10H
			LoadB	r7L,APPL_DATA
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:openfile
::exit			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

::openfile		LoadW	r6,dataFileName
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			php				;Hintergrundfarbe löschen.
			sei

			ldx	CPU_DATA
			lda	#$35			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	BORDER_COL		;Rahmenfarbe einlesen.
			sta	r0L
			lsr	r0L
			rol
			lsr	r0L
			rol
			lsr	r0L
			rol
			lsr	r0L
			rol

			stx	CPU_DATA		;I/O-Bereich ausblenden.
			plp

			jsr	i_UserColor		;Farb-RAM löschen.
			b	$00,$00,$28,$19

			jsr	ViewPaintFile		;Hintergrundbild anzeigen.
			txa				;Fehler ?
			bne	NoBackScrn		; => Ja, kein Startbild.

;*** Hintergrundgrafik speichern.
			lda	MP3_64K_SYSTEM		;Zeiger auf MP3-Systembank.
			sta	r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_BS_GRAFX
			LoadW	r2,R2_SIZE_BS_GRAFX
			jsr	StashRAM		;Grafik speichern.
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_BS_COLOR
			LoadW	r2,R2_SIZE_BS_COLOR
			jsr	StashRAM		;Farbe speichern.

;--- Hinweis:
;Prüfcode für Hintergrundbild setzen.
;War zuvor bereits ein Hintergrundbild
;aktiv, dann wird beim einschalten des
;Hintergrundbildes dieser Wert geprüft.
;Falls nicht vohanden wird zur Auswahl
;eines Hintergrundbildes aufgefordert.
			LoadW	r0,backScrCode
			LoadW	r1,backScrCodeRAM
			LoadW	r2,backScrCodeLen
			lda	GD_SYSDATA_BUF
			sta	r3L
			jsr	StashRAM		;Prüfcode Hintergrundbild setzen.

			lda	#$ff			;Hintergrundbild aktiv.
			b $2c

;*** Kein Startbild, Hintergrund löschen.
:NoBackScrn		lda	#$00			;Kein Hintergrundbild aktiv.
			sta	GD_BACKSCRN

			lda	sysRAMFlg
			and	#%11110111
			bit	GD_BACKSCRN		;GeoDesk-Hintergrundbild verwenden?
			bpl	:1			; => Nein, weiter...
			ora	#%00001000		; => Ja, System-Wert ändern.
::1			sta	sysRAMFlg
			sta	sysFlgCopy

			jmp	MOD_INITWM		;Zurück zum Desktop.

;*** Hintergrundbild anzeigen.
:ViewPaintFile		LoadW	r0,dataFileName
			jsr	OpenRecordFile		;geoPaint-Dokument öffnen.
			txa				;Fehler?
			bne	:53			; => Ja, Abbruch...

			LoadW	r14,SCREEN_BASE		;Zeiger auf Grafikspeicher.
			LoadW	r15,COLOR_MATRIX

			lda	#$00
::51			sta	a9H
			jsr	Get80Cards		;Grafikzeile einlesen.
			jsr	Prnt_Grfx_Cols		;Grafikzeile ausgeben.
			inc	a9H
			lda	a9H
			cmp	usedRecords		;Ende geoPaint-Dokument erreicht?
			bcs	:52			; => Ja, Ende...
			cmp	#13			;Bildschirm voll?
			bcc	:51			; => Nein, weiter...
::52			ldx	#$00
::53			txa
			pha
			jsr	CloseRecordFile		;geoPaint-Dokument schließen.
			pla
			tax
			rts

;*** Grafikdaten ausgeben.
;Eine geoPaint-Zeile besteht aus zwei
;Grafikzeilen a 8 Pixel Höhe.
:Prnt_Grfx_Cols		lda	#<GrfxData +   0	;Zeile #1 ausgeben.
			ldx	#>GrfxData +   0
			jsr	MoveGrfx
			lda	#<GrfxData +1288
			ldx	#>GrfxData +1288
			jsr	MoveCols

			lda	a9H			;12*2 +1 Zeilen.
			cmp	#12
			bcs	:1

			lda	#<GrfxData + 640	;Zeile #2 ausgeben.
			ldx	#>GrfxData + 640
			jsr	MoveGrfx
			lda	#<GrfxData +1368
			ldx	#>GrfxData +1368
			jmp	MoveCols

::1			rts

;*** Grafikdaten in Bildschirm kopieren.
:MoveGrfx		sta	r0L
			stx	r0H
			MoveW	r14,r1
			AddVW	SCRN_XBYTES,r14
			LoadW	r2 ,SCRN_XBYTES
			jmp	MoveData

;*** Farbdaten in Bildschirm kopieren.
:MoveCols		sta	r0L
			stx	r0H
			MoveW	r15,r1
			AddVW	SCRN_XCARDS ,r15
			LoadW	r2 ,SCRN_XCARDS
			jmp	MoveData

;*** Eine Grafikzeile (80 Cards/8 Pixel hoch) einlesen.
:Get80Cards		jsr	PointRecord		;Zeiger auf Grafikzeile.
			txa				;Fehler?
			bne	NoGrfxData		; => Ja, Abbruch...
			tya
			bne	LoadVLIR_Data

:NoGrfxData		jsr	i_FillRam		;Keine weitere Grafikzeile.
			w	1280			;Leere Zeile ausgeben.
			w	GrfxData +   0
			b	$00
			jsr	i_FillRam
			w	160
			w	GrfxData +1288
			b	$bf
			rts

;*** Grafikbytes aus Datensatz einlesen.
:LoadVLIR_Data		LoadW	r4,diskBlkBuf		;Zeiger auf Diskettenspeicher.
			jsr	GetBlock		;Ersten Sektor des aktuellen
			txa				;Datensatzes einlesen. Fehler ?
			bne	NoGrfxData		;Nein, weiter...

			LoadW	r0 ,GrfxData		;Zeiger auf Grafikdatenspeicher.

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
			sta	ByteCopyBuf,y		;einlesen und in Zwischenspeicher.
			iny				;Zeiger auf nächstes Byte.
			cpy	#$08			;8 Byte eingelesen ?
			bne	Repeat8Byte		;Nein, weiter...

			ldx	#$00
::1			ldy	#$07			;8 Byte in Grafikdatenspeicher.
::2			lda	ByteCopyBuf,y
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
:GetByteError		pla
			pla
			rts

;*** Nächsten Sektor aus Paint-Datensatz einlesen.
:GetNxSektor		lda	diskBlkBuf +$00
			sta	r1L
			lda	diskBlkBuf +$01
			sta	r1H
			sty	a9L
			jsr	GetBlock		;Sektor einlesen.
			ldy	a9L
			txa				;Diskettenfehler ?
			beq	:1			;Ja, Abbruch...
			pla
			pla
			jmp	NoBackScrn

::1			ldx	#$02			;Zeiger auf erstes Byte in Sektor.

;*** Nächstes Byte aus Sektor einlesen.
:RdBytFromSek		lda	r1L
			bne	:1
			cpx	r1H
			bcc	:1
			beq	:1
			bne	GetByteError
::1			lda	diskBlkBuf +$00,x	;Byte aus Sektor einlesen.
			stx	r5H			;Bytezeiger speichern.
			rts

;*** GeoPaint-Daten.
;Am Ende der Datei oder Bytepuffer setzen.
:ByteCopyBuf		s $08
:GrfxData		b $00
			;s (640 * 2) +8 +(80 * 2)
