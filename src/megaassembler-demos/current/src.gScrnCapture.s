; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Symboltabellen.
;
if .p
			t "TopSym"
			t "TopMac"
endif

;
; GEOS-Header.
;
			n "geoScreenCapture"
			c "Capture     V1.0"
			f DESK_ACC
			a "Markus Kanet"
			z $80 ;Nur GEOS64.

			o APP_RAM
			q END_DESC_ACC
			p MAININIT

			h "Screenshot mit c, Photoscrap mit RETURN. x/X, y/Y, m/M für Größe, Position mit CRSR-Tasten."

			i
<MISSING_IMAGE_DATA>

;
; Quelltext für Photoscrap und
; Screenshot einbinden.
;
			t "inc.WritePScrap"		;Photoscrap erstellen.
			t "inc.WriteGPFile"		;Screenshot erstellen.

;
; geoScreenCapture
;
; Bildschirm als PhotoScrap oder als
; GeoPaint-Datei speichern.
;
;
; DeskAccessories dürfen die Register
; a0-a9 nicht verändern, daher die
; Register zwischenspeichern.
;
:MAININIT		ldx	#0			;Register a0-a1
::l1			lda	a0,x			;zwischenspeichern.
			sta	aBuf +0,x
			inx
			cpx	#4
			bcc	:l1

			ldx	#0			;Register a2-a9
::l2			lda	a2,x			;zwischenspeichern.
			sta	aBuf +4,x
			inx
			cpx	#8 *2
			bcc	:l2

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	MainExit		; => Ja, Abbruch...

			jsr	defScrapSize		;Rahmen für PhotoScrap berechnen.
			jsr	printScrapSize		;Rahmen um PhotoScrap zeichnen.

			lda	#< setScrapSize		;Tastatur-Menü installieren.
			sta	keyVector +0
			lda	#> setScrapSize
			sta	keyVector +1

; Tastatur-Menü ausführen.
			rts				;Zurück zur Mainloop.

;
; DeskAccessory beenden. Dazu die zuvor
; gesicherten Register a0 bis a9 wieder
; zurückschreiben.
;
:MainExit		ldx	#0			;Register a0-a1
::l1			lda	aBuf +0,x		;wieder zurückschreiben.
			sta	a0,x
			inx
			cpx	#4
			bcc	:l1

			ldx	#0			;Register a2-a9
::l2			lda	aBuf +4,x		;wieder zurückschreiben.
			sta	a2,x
			inx
			cpx	#8 *2
			bcc	:l2

			jsr	OpenDisk		;Diskette öffnen.

			lda	#< RstrAppl		;DeskAccessory über die
			sta	appMain +0		;Mainloop beenden.
			lda	#> RstrAppl
			sta	appMain +1

			rts

;
; Größe Photoscrap anzeigen.
;
; Dabei wird am Bildschirm ein 1-Pixel
; breiter Rahmen invertiert um die
; aktuelle Größe anzuzeigen.
;
; Übergabe:
; r2L/r2H = y-Koordinate oben/unten
; r3 /r4  = x-Koordinate links/rechts
;
:printScrapSize		lda	#ST_WR_FORE		;Nur in den Vordergrund zeichnen.
			sta	dispBufferOn

			lda	r2L			;y-Koordinaten zwischenspeichern.
			pha
			lda	r2H
			pha

			lda	r2L
			sta	r2H
			jsr	InvertRectangle		;Oberen Rand invertieren.

			pla
			sta	r2H			;y-Koordinate wieder zurücksetzen.
			sta	r2L
			jsr	InvertRectangle		;Unteren Rand invertieren.
			pla
			sta	r2L			;y-Koordinate wieder zurücksetzen.

			lda	r3H			;x-Koordinaten zwischenspeichern.
			pha
			lda	r3L
			pha
			lda	r4H
			pha
			lda	r4L
			pha

			lda	r3L
			sta	r4L
			lda	r3H
			sta	r4H
			jsr	InvertRectangle		;Linken Rand invertieren.

			pla
			sta	r4L			;x-Koordinate wieder zurücksetzen.
			sta	r3L
			pla
			sta	r4H
			sta	r3H
			jsr	InvertRectangle		;Rechten Rand invertieren.

			pla
			sta	r3L
			pla
			sta	r3H			;x-Koordinate wieder zurücksetzen.

			rts

;
; X-/Y-Koordinaten für den 1-Pixel
; Rahmen des Photoscrap berechnen.
;
; Rückgabe:
; r2L/r2H = y-Koordinate oben/unten
; r3 /r4  = x-Koordinate links/rechts
;
:defScrapSize		lda	scrapXPos		;x-Koordinate in Cards einlesen.
			sta	r3L
			ldx	#$00
			stx	r3H

;			lda	scrapXPos		;Breite des Photoscrap einlesen.
			clc
			adc	scrapWidth
			sta	r4L
;			ldx	#$00
			stx	r4H

			ldx	#r3L			;Linker Rand nach Pixel
			ldy	#3			;konvertieren.
			jsr	DShiftLeft

			ldx	#r4L			;Rechter Rand nach Pixel
			ldy	#3			;konvertieren.
			jsr	DShiftLeft

			ldx	#r4L			;Rechten Rand auf das letzte Pixel
			jsr	Ddec			;im letzten Card setzen.

			lda	scrapYPos		;y-Koordinate einlesen.
			sta	r2L

;			lda	scrapYPos		;Unteren Rand des Photoscrap
			clc				;berechnen.
			adc	scrapHeight

			sec				;Unteren Rand auf das letzte Pixel
			sbc	#1			;im letzten Card setzen.
			sta	r2H

			rts

;
; Tastatur-Menü
;
; Die Routine wird über die Mainloop
; aufgerufen und werten einen Tasten-
; druck aus und ruft dann die dazu
; passende Menü-Routine auf.
;
:setScrapSize		jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
			jsr	printScrapSize		;Photoscrap-Rahmen löschen.

			ldx	#0
			lda	keyData			;Aktuelle Taste einlesen.
::1			cmp	keyDataTab,x		;Taste in Tabelle suchen?
			beq	:2			; => Gefunden, weiter...
			inx
			cpx	#MAX_KEYS		;Alle Tasten durchsucht?
			bcc	:1			; => Nein, weiter...

;			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
			jsr	printScrapSize		;Photoscrap-Rahmen anzeigen.

			rts

;
; Tasten-Routine ausführen.
;
::2			lda	adrDataTabH,x		;Startadresse auf Stack schieben
			pha				;und Tasten-Routine aufrufen.
			lda	adrDataTabL,x
			pha
			rts

;
; Liste der Menütasten.
;
:keyDataTab		b $0d				;RETURN
			b $63				;c /Capture
			b $08				;Cursor links
			b $1e				;Cursor rechts
			b $10				;Cursor hoch
			b $11				;Cursor runter
			b $78				;x-kleiner
			b $58				;x-größer
			b $79				;y-kleiner
			b $59				;y-größer
			b $6d				;m /GeoPaint
			b $4d				;M /Maximum
:endDataTab

;
; Anzahl der Menütasten ermitteln.
;
:MAX_KEYS		= endDataTab - keyDataTab

;
; Startadressen der Tasten-Routinen.
; Da die Adresse auf den Stack gelegt
; und als Rücksprungadresse genutzt
; wird, muss der Wert für den Stack
; umd 1 Byte reduziert werden.
;
; Lowbyte:
:adrDataTabL		b < DoPhotoScrap -1
			b < DoScreenShot -1
			b < moveLeft -1
			b < moveRight -1
			b < moveUp -1
			b < moveDown -1
			b < sizeXsub -1
			b < sizeXadd -1
			b < sizeYsub -1
			b < sizeYadd -1
			b < sizePaint -1
			b < sizeMax -1

; Highbyte:
:adrDataTabH		b > DoPhotoScrap -1
			b > DoScreenShot -1
			b > moveLeft -1
			b > moveRight -1
			b > moveUp -1
			b > moveDown -1
			b > sizeXsub -1
			b > sizeXadd -1
			b > sizeYsub -1
			b > sizeYadd -1
			b > sizePaint -1
			b > sizeMax -1

;
; Screenshot erstellen
;
; Über die Taste `c` wird der aktuelle
; Bildinhalt mit Grafik+Farbe in ein
; GeoPaint-Dokument gespeichert.
;
:DoScreenShot		jsr	CREATE_GIMAGE		;Screenshot erstellen.
			jmp	MainExit		;DeskAccessory beenden.

;
; Screenshot erstellen
;
; Über `RETURN` wird die aktuelle
; Auswahl mit Grafik+Farbe in eine
; Photoscrap-Datei gespeichert.
;
:DoPhotoScrap		jsr	CREATE_PSCRAP		;Photoscrap erstellen.
			jmp	MainExit		;DeskAccessory beenden.

;
; Taste `CRSR-LEFT`:
; Auswahl nach links schieben.
;
:moveLeft		ldx	scrapXPos		;Auswahl bereits am rechten Rand?
			beq	:done			; => Ja, Ende...

			dex				;Rahmen nach links schieben.
			stx	scrapXPos
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `CRSR-RIGHT`:
; Auswahl nach rechts schieben.
;
:moveRight		lda	scrapXPos		;Auswahl bereits am rechten Rand?
			clc
			adc	scrapWidth
			cmp	#40
			bcs	:done			; => Ja, Ende...

			inc	scrapXPos		;Auswahl nach rechts schieben.
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `CRSR-UP`:
; Auswahl nach oben schieben.
;
:moveUp			lda	scrapYPos		;Auswahl bereits am oberen Rand?
			beq	:done			; => Ja, Ende...

			sec				;Auswahl nach oben schieben.
			sbc	#8
			sta	scrapYPos
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `CRSR-DOWN`:
; Auswahl nach unten schieben.
;
:moveDown		lda	scrapYPos		;Auswahl bereits am unteren Rand?
			clc
			adc	scrapHeight
			bcs	:done			;Überlauf, Ende...
			cmp	#200
			bcs	:done			; => Ja, Ende...

			lda	scrapYPos		;Auswahl nach unten schieben.
			clc
			adc	#8
			sta	scrapYPos
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `x`:
; Breite der Auswahl reduzieren.
;
:sizeXsub		ldx	scrapWidth		;Breite bereit auf Minimum?
			dex
			beq	:done			; => Ja, Ende...

			stx	scrapWidth		;Breite der Auswahl reduzieren.
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `SHIFT x`:
; Breite der Auswahl vergrößeren.
;
:sizeXadd		lda	scrapXPos		;x-Koordinate und Breite bereits
			clc				;am rechten Rand?
			adc	scrapWidth
			cmp	#40
			bcs	:done			; => Ja, Ende...

			inc	scrapWidth		;Breite der Auswahl vergrößeren.
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `y`:
; Höhe der Auswahl reduzieren.
;
:sizeYsub		lda	scrapHeight		;Höhe bereits auf Minimum?
			sec
			sbc	#8
			bcc	:done			;Unterlauf, Ende...
			beq	:done			; => Ja, Ende...

			sta	scrapHeight		;Höhe der Auswahl reduzieren.
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `SHIFT y`:
; Höhe der Auswahl vergrößeren.
;
:sizeYadd		lda	scrapYPos		;y-Koordinate und Höhe bereits
			clc				;am unteren Rand?
			adc	scrapHeight
			bcs	:done			;Überlauf, Ende...
			cmp	#200
			bcs	:done			; => Ja, Ende...

			lda	scrapHeight		;Höhe der Auswahl vergrößeren.
			clc
			adc	#8
			sta	scrapHeight
			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
::done			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `m`:
; Größe der Auswahl auf die maximale
; Auswahl-Größe von GeoPaint setzen.
; Dieser Ausschnitt kann von GeoPaint
; und Geowrite unskaliert in das
; Dokument eingefügt werden.
;
:sizePaint		lda	#0			;Auswahl auf GeoPaint-Größe
			sta	scrapXPos		;setzen.
			sta	scrapYPos
			lda	#33			;Max. $21 Cards breit.
			sta	scrapWidth
			lda	#144			;Max. $90 Cards hoch.
			sta	scrapHeight

			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;
; Taste `SHIFT m`:
; Größe der Auswahl auf den gesamten
; Bildschirm setzen.
; Das Photoscrap kann von GeoPaint dann
; nur noch skaliert eingefügt werden,
; dabei werden die Farben aber nicht
; in das Bild übernommen.
; GeoWrite kann das Photoscrap nicht
; mehr in ein Dokument einfügen.
;
:sizeMax		lda	#0			;Auswahl auf Bildschirmgröße
			sta	scrapXPos		;setzen.
			sta	scrapYPos
			lda	#40			;Max. $28 Cards breit.
			sta	scrapWidth
			lda	#200			;Max. $19 Cards hoch.
			sta	scrapHeight

			jsr	defScrapSize		;Größe Photoscrap-Rahmen berechnen.
			jmp	printScrapSize		;Photoscrap-Rahmen anzeigen.

;*** Ende DeskAccessory / Beginn Daten.

;
; Zwischenspeicher für die Application-
; Register. Werden am Ende wieder in
; die Register a0-a9 zurückgeschrieben.
;
:aBuf			s 10 *2

; Speicher für Photoscrap/Screenshot.
:dataBuf

; Speicher für Original-Daten.
:dataUnpacked		= dataBuf

; Speicher für gepackte Daten.
:dataPacked		= dataUnpacked + 1280 + 8 + 160 +1

; Größe Zwischenspeicher berechnen.
:dataBufEnd		= dataPacked   + 1280 + 8 + 160 +1 +48
:dataBufSize		= (dataBufEnd -dataBuf)

;
; Die Größe des DeskAccessory wird so
; gewählt, das auch der Datenspeicher
; im Swapfile ausgelagert wird.
;
:END_DESC_ACC		= dataBufEnd
