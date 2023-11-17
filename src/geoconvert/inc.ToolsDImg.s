; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;DiskImage Funktionen

;*** Spur/Sektor-Adressen der Datenblöcke innerhalb
;    einer D64/D71/D81-Datei einlesen.
.DiskImage_ReadSekAdr	jsr	TextInfo_ReadData	;Info: Reading data...
			jsr	ClearJobInfo

			jsr	i_FillRam		;Sektoradressen-Tabelle löschen.
;			w	683  * 3		;1541: mind.  683 Sektoren * 3 Bytes
;			w	1366 * 3		;1571: mind. 1366 Sektoren * 3 Bytes
			w	3200 * 3		;1581: mind. 3200 Sektoren * 3 Bytes
			w	StartSekTab
			b	$00

			jsr	FindSlctFile		;Image-Datei suchen.

			LoadW	a0 ,StartSekTab		;Zwischenspeicher für Spur/Sektor-Adressen.
			LoadW	a1L,$02			;Zeiger auf Datenbyte im Zwischenspeicher.

			lda	DiskImageMode		;Sektorzähler auf Anfang setzen.
			cmp	#DRV_1541		;1541?
			bne	:100a			;Nein, weiter...
			ldx	#<683			;Max. 683 Sektoren.
			ldy	#>683
			bne	:100d
::100a			cmp	#DRV_1571		;1571?
			bne	:100b			;Nein, weiter...
			ldx	#<1366			;Max. 1366 Sektoren.
			ldy	#>1366
			bne	:100d
::100b			cmp	#DRV_1581		;1581?
			bne	:100c			;Nein, weiter...
			ldx	#<3200			;Max. 3200 Sektoren.
			ldy	#>3200
			bne	:100d
::100c			ldx	#$0d			;Unbekannter Laufwerkstyp.
			jmp	GetTxtDiskErr

::100d			stx	a2L			;Max. Anzahl Sektoren speichern.
			sty	a2H

			LoadB	a3L,1			;Zeiger Auf Spur 1/Sektor 0.
			LoadB	a3H,0

			lda	#0			;Sektor-Zähler für Fortschritts-
			sta	a4L			;Anzeige löschen.

			MoveB	dirEntryBuf +1,a5L	;Spur des ersten Datenblocks.
			MoveB	dirEntryBuf +2,a5H	;Sektor des ersten Datenblocks.

::101			lda	a4L			;Fortschritts-Anzeige aktualisieren?
			bne	:101a			;Nein, weiter...
			ldx	a3L			;Aktuelle Spurnummer für
			jsr	PrintJobInfo		;Fortschritts-Anzeige in Prozent.
			lda	#20			;Zähler für Fortschritts-
			sta	a4L			;Anzeige zurücksetzen.
::101a			dec	a4L			;Zähler für Fortschritts-Anzeige.

::101b			MoveB	a5H,r1H			;Zeiger auf nächsten Datenblock
			MoveB	a5L,r1L			;setzen.
			bne	:101d			;Ende erreicht? Nein, weiter...
			jmp	:105			;Letzter Datenblock eingelesen.
::101d			LoadW	r4,diskBlkBuf		;Ladeadresse für Datenblock.
			jsr	GetBlock		;Datenblock einlesen.
			txa				;Diskettenfehler?
			beq	:101c			;Nein, weiter...
			jmp	GetTxtDiskErr		;Abbruch, Fehler anzeigen.

::101c			ldy	#$00
			lda	a5L			;Spur des aktuellen Datenblocks
			sta	(a0L),y			;in Sektortabelle eintragen.
			iny
			lda	a5H			;Sektor des aktuellen Datenblocks
			sta	(a0L),y			;in Sektortabelle eintragen.
			iny
			lda	a1L			;Zeiger auf erstes Byte im Datenblock
			sta	(a0L),y			;in Sektortabelle eintragen.

			lda	a2L			;Sektorzähler aktualisieren.
			bne	:102a
			dec	a2H
::102a			dec	a2L
			lda	a2L			;Alle Sektoren eingelesen?
			ora	a2H
			beq	:105			;Ja, Ende.

::103			jsr	SetNextSek		;Zeiger auf nächsten Sektor
							;für Fortschritts-Anzeige.

			lda	a0L			;Zeiger auf nächste Adresse
			clc				;in Sektortabelle berechnen.
			adc	#$03
			sta	a0L
			bcc	:102
			inc	a0H

::102			inc	a1L			;Byte-Zähler erhöhen
			inc	a1L			;Die letzten beiden Bytes erreicht?
			bne	:104			;Nein, weiter.

;Wenn die letzten beiden Bytes innerhalb eines Datenblocks
;erreicht wurden gehören alle Bytes des nächsten Datenblocks
;zum aktuellen Sektor (256Bytes - 2Bytes für Spur/Sektor des
;nachfolgenden Datenblocks).
;Daher den nächsten Datenblock einlesen und direkt mit dem
;darauf folgenden Datenblock weiterarbeiten.
			MoveB	diskBlkBuf +1,r1H	;Spur/Sektor auf nächsten
			MoveB	diskBlkBuf +0,r1L	;Datenblock setzen. Ende erreicht?
			beq	:105			;Ja, Ende...
			LoadW	r4,diskBlkBuf		;Ladeadresse für Datenblock.
			jsr	GetBlock		;Datenblock einlesen.
			txa
			beq	:104a
			jmp	GetTxtDiskErr		;Abbruch, Fehler anzeigen.

::104a			inc	a1L			;Byte-Zähler erhöhen
			inc	a1L
::104			MoveB	diskBlkBuf +1,a5H	;Sektor des nächsten Datenblocks.
			MoveB	diskBlkBuf +0,a5L	;Spur des nächsten Datenblocks.
			beq	:105			;Ende erreicht? Ja, Ende...
			jmp	:101			;Nein, Nächsten Datenblock einlesen.

;*** Alle Sektoren eingelesen.
::105			jmp	ResetScreenBackground	;Hintergrundmuster wieder herstellen.

;*** Zeiger auf Sektor berechnen.
;    X: Spur
;    A: Sektor
.PosToSektor		pha				;Sektor-Adresse zwischenspeichern.
			LoadW	a0,StartSekTab		;Zwischenspeicher für Spur/Sektor-Adressen.
			LoadB	a1L,$01			;Spur-Zeiger auf Anfang setzen.

			lda 	DiskImageMode		;Laufwerkstyp bestimmen.
			cmp	#DRV_1581		;1581-Laufwerk?
			beq	:107			;Ja, weiter.

;*** 1541/1571: Spur suchen.
::101			cpx	a1L			;Aktuelle Spur = Gesuchte Spur?
			beq	:103			;Ja, weiter

			ldy	a1L			;Spur-Zeiger einlesen.
			lda	SekPerTrack,y		;Anzahl Sektoren je Spur überspringen.
			asl				;Zeiger auf nächste Spur in der
			clc				;Sektortabelle berechnen.
			adc	SekPerTrack,y
			clc
			adc	a0L
			sta	a0L
			bcc	:102
			inc	a0H
::102			inc	a1L			;Zeiger auf nächste Spur setzen.
			lda	a1L			;Spur-Zeiger einlesen.
			cmp	#36			;1541: Letzte Spur erreicht?
			bcc	:101			;Nein, weiter.
			ldy	DiskImageMode		;Disk-Modus einlesen.
			cpy	#DRV_1571		;1571-Laufwerk?
			bne	:102a			;Nein, Illegale Spur-Nummer.
			cmp	#71			;1571: Letzte Spur erreicht?
			bcc	:101			;Nein, weiter...
::102a			pla
			ldx	#$02			;Illegale Spur-Nummer.
			jmp	ExitDiskErr

;*** 1541/1571: Sektor suchen.
::103			lda	#$00			;Sektor auf NULL setzen.
			sta	a1L
			pla
			tax
::104			cpx	a1L			;Sektor gefunden?
			beq	:106			;Ja, Ende.

			lda	a0L			;Zeiger auf nächsten Sektor in der
			clc				;Sektortabelle berechnen.
			adc	#$03
			sta	a0L
			bcc	:105
			inc	a0H
::105			inc	a1L			;Zeiger auf nächsten Sektor setzen.
			bne	:104			;Sektor=$00 ? -> Nein, weiter...
			ldx	#$02			;Illegale Sektor-Nummer.
			jmp	ExitDiskErr

;*** 1541/1571: Sektor in Tabelle gefunden.
::106			rts				;Zeiger auf Sektor berechnet, Ende.

;*** 1581: Spur suchen.
::107			cpx	a1L			;Aktuelle Spur = Gesuchte Spur?
			beq	:109			;Ja, weiter

			clc				;Spur-Zeiger einlesen.
			lda	#120			;Anzahl Sektoren*3 je Spur überspringen.
			adc	a0L			;Zeiger auf nächste Spur in der
			sta	a0L			;Sektortabelle berechnen.
			bcc	:108
			inc	a0H
::108			inc	a1L			;Zeiger auf nächste Spur setzen.
			lda	a1L			;Spur-Zeiger einlesen.
			cmp	#81			;1581: Letzte Spur erreicht?
			bcc	:107			;Nein, weiter.
			pla
			ldx	#$02			;Illegale Spur-Nummer.
			jmp	ExitDiskErr

;*** 1581: Sektor suchen.
::109			lda	#$00			;Sektorzähler auf NULL setzen.
			sta	a1L
			pla
			tax
::110			cpx	a1L			;Spur/Sektor gefunden?
			beq	:112			;Ja, Ende.

			lda	a0L			;Zeiger auf nächsten Sektor in der
			clc				;Sektortabelle berechnen.
			adc	#$03
			sta	a0L
			bcc	:111
			inc	a0H
::111			inc	a1L			;Zeiger auf nächsten Sektor setzen.
			bne	:110			;Sektor=$00 ? -> Nein, weiter...
			ldx	#$02			;Illegale Sektor-Nummer.
			jmp	ExitDiskErr

;*** 1581: Sektor in Tabelle gefunden.
::112			rts				;Zeiger auf Sektor berechnet, Ende.

;*** Datensektor einlesen.
;    a0 : Zeiger auf StartSekTab mit Startadressen der Spur/Sektor-Daten.
;    r15: Zeiger auf Zwischenspeicher für Datenblöcke.
.GetSektor		ldy	#$00
			lda	(a0L),y			;Lage des gesuchten Sektors
			sta	r1L			;innerhalb der D64-Datei als
			iny				;Spur/Sektor-Adresse festlegen.
			lda	(a0L),y
			sta	r1H
			iny				;Zeiger auf Datenbyte im Datenblock
			lda	(a0L),y			;der D64-Datei einlesen.
			pha
			lda	#$00
			pha
			LoadW	r4,fileHeader		;Zeiger auf temporären Zwischenspeicher.
::101			jsr	ReadBlock		;Datenblock einlesen.
			pla				;Zeiger auf aktuelles Byte im
			tay				;Datenblock wiederherstellen.
			pla				;Zeiger auf aktuelles Byte im temporären
			tax				;Zwischenspeicher wiederherstellen.
::102			lda	fileHeader,x		;Datenbyte aus temporären Zwischenspeicher
			sta	(r15L),y		;in Datenblock übertragen.
			iny				;Datenblock vollständig?
			beq	:103			;Ja, Ende.
			inx				;Datensektor aus D64-Datei ausgelesen?
			bne	:102			;Nein, nächstes Byte aus D64-Datei lesen.

			lda	fileHeader +1		;Zeiger auf nächsten Sektor in D64-Datei.
			sta	r1H
			lda	fileHeader +0
			sta	r1L			;Letzter Sektor der D64-Datei erreicht?
			beq	:103			;Ja, Ende.

			lda	#$02			;Zeiger auf erstes Byte im nächsten
			pha				;Sektor der D64-Datei setzen.
			tya				;Zeiger auf Byte im aktuellen Datenblock
			pha				;zwischenspeichern.
			jmp	:101			;Datenblock weiter auslesen.
::103			rts				;Ende.

;*** Zeiger auf nächsten Sektor berechnen.
;    a3L: Aktuelle Spur-Nummer.
;    a3H: Aktuelle Sektor-Nummer.
.SetNextSek		lda 	DiskImageMode		;Laufwerkstyp bestimmen.
			cmp	#DRV_1581		;1581-Laufwerk?
			beq	:103			;Ja, weiter.

;*** 1541/1571: Zeiger auf nächsten Sektor.
			inc	a3H			;Zeiger auf nächsten Sektor.
			ldx	a3L			;Max. Sektorzahl überschritten?
			lda	SekPerTrack,x
			cmp	a3H
			bne	:102			;Nein, weiter.

			lda	#$00			;Ja, Sektor auf $00 zurücksetzen.
			sta	a3H
			inc	a3L			;Zeiger auf nächste Spur.
			lda	a3L
			cmp	#36			;Letzte Spur erreicht?
			bcc	:102			;Nein, weiter.
			ldy 	DiskImageMode		;Laufwerkstyp bestimmen.
			cpy	#DRV_1571		;1571-Laufwerk?
			bne	:101			;Nein, Letzter Sektor 1541 erreicht.
			cmp	#71			;Spur #71 erreicht?
			bcc	:102			;Nein, weiter.
::101			lda	#$ff			;Nein, Letzter Sektor 1571 erreicht.
			rts
::102			lda	#$00			;Zeiger auf nächsten Sektor gesetzt.
			rts

;*** 1581: Zeiger auf nächsten Sektor.
::103			inc	a3H			;Zeiger auf nächsten Sektor.
			lda	a3H			;Max. Sektorzahl überschritten?
			cmp	#40			;Max. 40 Sektoren je Spur.
			bne	:104			;Nein, weiter.
			lda	#$00			;Ja, Sektor auf $00 zurücksetzen.
			sta	a3H
			inc	a3L			;Zeiger auf nächste Spur.
			lda	a3L
			cmp	#81			;Letzte Spur erreicht?
			bne	:104			;Nein, weiter.
			lda	#$ff			;Nein, Letzter Sektor 1581 erreicht.
			rts
::104			lda	#$00			;Zeiger auf nächsten Sektor gesetzt.
			rts

;*** Bildschirmbereich für Fortschritts-Anyeige löschen.
.ClearJobInfo		PushB	dispBufferOn
			LoadB	dispBufferOn,ST_WR_FORE
			lda	#$00			;Bildschirmbereich löschen.
			jsr	SetPattern		;Füllmuster setzen.
			jsr	i_Rectangle		;Rechteck-Bereich mit Muster füllen.
			b	187,196
			w	290
			w	309
			PopB	dispBufferOn
			rts

;*** Aktuelle Spurnummer ausgeben.
;    X: Spurnummer.
.PrintJobInfo		LoadW	r11,295
			LoadB	r1H,194
			dex
			ldy	DiskImageMode
			cpy	#DRV_1541
			bne	:101
			ldy	PercentDone_1541,x
			jmp	:104
::101			cpy	#DRV_1571
			bne	:102
			ldy	PercentDone_1571,x
			jmp	:104
::102			cpy	#DRV_1581
			bne	:103
			ldy	PercentDone_1581,x
			jmp	:104
::103			ldx	#$0d			;Kein passendes laufwerk gefunden.
			jmp	GetTxtDiskErr

::104			PushB	dispBufferOn
			LoadB	dispBufferOn,ST_WR_FORE

			tya
			ldy	#"0"
::105			cmp	#10
			bcc	:106
			iny
			sec
			sbc	#10
			bne	:105
::106			clc
			adc	#"0"
			pha
			tya
			cmp	#"0"
			bne	:107
			lda	#" "
::107			pha
			lda	#PLAINTEXT
			jsr	PutChar
			pla
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar
			lda	#"%"
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar
			PopB	dispBufferOn
			rts

;*** DiskImage-Modus 1541/1571/1581
.DiskImageMode		b $00

;*** Variablen für D64.
;    Anzal der Spuren=35, wird auch bei :SetNextSek verwendet.
:SekPerTrack		b 00,21,21,21,21,21,21,21       ;0-7
			b 21,21,21,21,21,21,21,21       ;8-15
			b 21,21,19,19,19,19,19,19       ;16-23
			b 19,18,18,18,18,18,18,17       ;24-31
			b 17,17,17,17                   ;32-35
:SekPerTrackD71		b 21,21,21,21,21,21,21,21       ;36-43
			b 21,21,21,21,21,21,21,21       ;44-51
			b 21,19,19,19,19,19,19,19       ;52-59
			b 18,18,18,18,18,18,17,17       ;60-67
			b 17,17,17                      ;68-70

;*** Prozentangaben für Fortschrittsanzeige.
:PercentDone_1541	b  0, 3, 6, 9,11,14,17,20,23,26
			b 29,31,34,37,40,43,46,49,51,54
			b 57,60,63,66,69,71,74,77,80,83
			b 86,89,91,94,97
:PercentDone_1571	b  0, 1, 3, 4, 6, 7, 9,10,11,13
			b 14,16,17,19,20,21,23,24,26,27
			b 29,30,31,33,34,36,37,39,40,41
			b 43,44,46,47,49,50,51,53,54,56
			b 57,59,60,61,63,64,66,67,69,70
			b 71,73,74,76,77,79,80,81,83,84
			b 86,87,89,90,91,93,94,96,97,99
:PercentDone_1581	b  0, 1, 3, 4, 5, 6, 8, 9,10,11
			b 13,14,15,16,18,19,20,21,23,24
			b 25,26,28,29,30,31,33,34,35,36
			b 38,39,40,41,43,44,45,46,48,49
			b 50,51,53,54,55,56,58,59,60,61
			b 63,64,65,66,68,69,70,71,73,74
			b 75,76,78,79,80,81,83,84,85,86
			b 88,89,90,91,93,94,95,96,98,99

.DImgTargetFile		s 17
.DImgSekData		s 256

if Sprache = Deutsch
.No41DrvTxt		b BOLDON,"Kein 1541-Laufwerk!" ,PLAINTEXT,NULL
.No71DrvTxt		b BOLDON,"Kein 1571-Laufwerk!" ,PLAINTEXT,NULL
.No81DrvTxt		b BOLDON,"Kein 1581-Laufwerk!" ,PLAINTEXT,NULL
endif
if Sprache = Englisch
.No41DrvTxt		b BOLDON,"No 1541-drive!"      ,PLAINTEXT,NULL
.No71DrvTxt		b BOLDON,"No 1571-drive!"      ,PLAINTEXT,NULL
.No81DrvTxt		b BOLDON,"No 1581-drive!"      ,PLAINTEXT,NULL
endif

;*** Start Spur/Sektor-Adressen der Datenblöcke innerhalb
;    der D64/D71/D81-Datei.
;    Bereich wird auch für ConvertUUE/SEQ/CVT als
;    Zwischenspeicher für Quell-/Zielsektor verwendet.
;    Siehe 'inc.ToolsSEQ'.
.StartSekTab
;			s 683 *3			;1541: mind.  683 Sektoren *  3 Bytes.
;			s 1366*3			;1571: mind. 1366 Sektoren *  3 Bytes.
			s 3200*3			;1581: mind. 3200 Sektoren *  3 Bytes.
