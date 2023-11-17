; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Assembler library.
; Daten von Disk lesen/auf Disk schreiben.
;
; Bei Zugriff auf Sektor-Ebene:
; Lesen/schreiben von X Sektoren/Track je Durchlauf.
;
; (w) 2021 m.kanet
;
; Wenn Ziel = Image:
; 10 open 10,8,15: open 2,8,2,"#"
; 15 open 11,9,15: open 3,9,3,"name.d81,p,w"
;
; Wenn Quelle = Image:
; 10 open 10,8,15: open 2,8,2,"name.d81,p,r"
; 15 open 11,9,15: open 3,9,3,"#"
;
; 20 poke 49152 +15,source
; 21 poke 49152 +16,target
; 22 poke 49152 +17,track
; 23 poke 49152 +18,maxsector (40 für 1581/0-39)
; 24 poke 49152 +19,drive/source (0/default für 1541/71/81, 0/1 für 8250)
; 25 poke 49152 +20,drive/target (0/default für 1541/71/81, 0/1 für 8250)
; 26 poke 49152 +21,errmode (0/default, Fehler nur zählen)
; 27 peek(49152 +22) = Max.Track in DNP DiskImage.
; 28 peek(49152 +23) = 0/Kein Fehler aufgetreten.
; 29 peek(49152 +24) = Fehler auf Laufwerk X.
; 30 peek(49152 +25) = Fehler auf Track X.
; 31 peek(49152 +26) = Fehlercode.
;
; 40 sys 49152 = Sektor lesen Quelle/#2 / Sektor schreiben Ziel/#3
;                Inkl. OPEN/CLOSE bei jedem Durchgang.
; 41 sys 49155 = Sektor lesen Quelle/#2 / Sektor schreiben Ziel/#3
;                OPEN/CLOSE durch BASIC-Programm!
; 42 sys 49158 = Sektor lesen Quelle/#2 / Daten schreiben  Ziel/#3
;                OPEN/CLOSE durch BASIC-Programm!
; 43 sys 49161 = Daten lesen  Quelle/#2 / Sektor schreiben Ziel/#3
;                OPEN/CLOSE durch BASIC-Programm!
; 44 sys 49164 = Byte #0-519 überlesen, Byte #520 einlesen = max.Track/DNP
;                OPEN/CLOSE durch BASIC-Programm!
;
; Wenn Quelle/Ziel = Image:
; 50 close 2:close 10:close 3: close 11
;

if .p
;--- Einsprünge C64-Kernal-ROM
:STATUS			= $90				;Fehlerstatus.
:CURDEV			= $ba				;Aktuelles Laufwerk.
:SETLFS			= $ffba				;Dateiparameter setzen.
:SETNAM			= $ffbd				;Dateiname setzen.
:OPENCHN		= $ffc0				;Datei öffnen.
:CLOSE			= $ffc3				;Datei schließen.
:CHKIN			= $ffc6				;Eingabefile setzen.
:CKOUT			= $ffc9				;Ausgabefile setzen.
:CLRCHN			= $ffcc				;Standard-I/O setzen.
:CHRIN			= $ffcf				;Byte aus Datei einlesen.
:BSOUT			= $ffd2				;Zeichen ausgeben.
endif

			n	"RDWRSEKLIB"
			f	0
			o	($c000 -2)		;Startadresse Programmcode mit
							;2-Byte-Header für Ladeadresse.

:loadAdr		w $c000				;BASIC-Ladeadresse.

;--- Sprungtabelle.
:callCopyDisk		jmp	doCopyDisk		;Disk->Disk.
:callCopyDiskU		jmp	doCopyDiskU		;Disk->Disk  (ohne OPEN/CLOSE).
:callCopyFileS		jmp	doCopyFileS		;Disk->Image (ohne OPEN/CLOSE).
:callCopyFileT		jmp	doCopyFileT		;Image->Disk (ohne OPEN/CLOSE).
:callReadMxTr		jmp	doReadMaxTr		;Max. Anzahl Tracks von DNP einlesen.

;--- Programmparameter.
:source			b $00				;Quell-Laufwerk.
:target			b $00				;Ziel -Laufwerk.
:track			b $00				;Trackadresse.
:maxsek			b $00				;Max. Anzahl Sektoren auf Track, 0=256.
:drvtarget		b $00				;Optional: Laufwerk 0/1 bei Doppellaufwerken.
:drvsource		b $00				;Optional: Laufwerk 0/1 bei Doppellaufwerken.
:errmode		b $00				;$00 = Bei Fehler nicht abbrechen.
:maxtrack		b $00				;max. Track in DNP DiskImage.
;--- Hinweis:
;Variablen müssen vor dem kopieren manuell auf $00 gesetzt werden!
:errcount		b $00				;Anzahl Fehler im aktuellen Durchlauf.
:errdrive		b $00				;Fehler auf Laufwerk X.
:errtrack		b $00				;Fehler auf Track X.
:errcode		b $00				;Fehlercode.

;--- Interne Variablen.
:sector			b $00				;Aktueller Sektor.

;*** Disk->Disk kopieren.
:doCopyDisk		jsr	openSource		;Quelle: Daten-/Befehlskanal öffnen.
			jsr	openTarget		;Ziel  : Daten-/Befehlskanal öffnen.

			jsr	doCopyDiskU		;Disk->Disk kopieren.

			jsr	closeTarget		;Ziel  : Daten-/Befehlskanal schließen.
			jsr	closeSource		;Quelle: Daten-/Befehlskanal schließen.

			rts				;Ende.

;*** Disk->Disk kopieren (ohne OPEN/CLOSE).
:doCopyDiskU		lda	#0			;Zeiger auf ersten Sektor des
			sta	sector			;aktuellen Tracks.

::nxsek			jsr	readSource		;Sektor von Quelle lesen.
			jsr	getErrStat10		;Status einlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			jsr	getDataSource		;Daten von Laufwerk einlesen.

			jsr	putDataTarget		;Daten an Laufwerk senden.

			jsr	writeTarget		;Sektor auf Ziel speichern.
			jsr	getErrStat11 		;Status einlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			inc	sector			;Zeiger auf nächsten Sektor.
			beq	:done			;256 Sektoren kopiert ? => Ja, Ende...

			lda	maxsek			;256 Sektoren kopieren (DNP) ?
			beq	:nxsek			; => Ja, weiter...
			cmp	sector			;Max. Anzahl Sektoren kopiert ?
			beq	:done			; => Ja, Ende...
			bcs	:nxsek			; => Nein, weiter...

::done			rts				;Ende.

;*** Disk->Image kopieren (ohne OPEN/CLOSE).
:doCopyFileS		lda	#0			;Zeiger auf ersten Sektor des
			sta	sector			;aktuellen Tracks der Quelle.

::nxsek			jsr	readSource		;Sektor von Quelle lesen.
			jsr	getErrStat10		;Status einlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			jsr	getDataSource		;Daten von Laufwerk einlesen.

			jsr	sendTarget		;Daten in Zieldatei speichern.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			inc	sector			;Zeiger auf nächsten Sektor.
			beq	:done			;256 Sektoren kopiert ? => Ja, Ende...

			lda	maxsek			;256 Sektoren kopieren (DNP) ?
			beq	:nxsek			; => Ja, weiter...
			cmp	sector			;Max. Anzahl Sektoren kopiert ?
			beq	:done			; => Ja, Ende...
			bcs	:nxsek			; => Nein, weiter...

::done			rts				;Ende.

;*** Image->Disk kopieren (ohne OPEN/CLOSE).
:doCopyFileT		lda	#0			;Zeiger auf ersten Sektor des
			sta	sector			;aktuellen Tracks der Quelle.

::nxsek			jsr	receiveSource		;Daten aus der Quelldatei lesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			jsr	putDataTarget		;Daten an Laufwerk senden.

			jsr	writeTarget		;Sektor auf Ziel speichern.
			jsr	getErrStat11		;Status einlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			inc	sector			;Zeiger auf nächsten Sektor.
			beq	:done			;256 Sektoren kopiert ? => Ja, Ende...

			lda	maxsek			;256 Sektoren kopieren (DNP) ?
			beq	:nxsek			; => Ja, weiter...
			cmp	sector			;Max. Anzahl Sektoren kopiert ?
			beq	:done			; => Ja, Ende...
			bcs	:nxsek			; => Nein, weiter...

::done			rts				;Ende.

;*** Max. Track in DNP einlesen.
:doReadMaxTr		lda	#0			;Max.track löschen.
			sta	maxtrack

			jsr	receiveSource		;Sektor 1/0 überlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			jsr	receiveSource		;Sektor 1/1 überlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			jsr	receiveSource		;Sektor 1/2 einlesen.
			txa				;Fehler aufgetreten ?
			bne	:done			; => Ja, Abbruch...

			lda	$cf08			;Anzahl Tracks in DNP in 1/2 Byte #8.
			sta	maxtrack

::done			rts

;*** Quelle: Daten-/Befehlskanal öffnen
:openSource		lda	#$00			;Befehlskanal:
;			tax				;Kein Dateiname erforderlich.
;			tay
			jsr	SETNAM			;Dateiname setzen.
			lda	#10			;Dateinummer #10.
			ldx	source			;Quell-Laufwerk.
			ldy	#15			;Sekundäradresse #15.
			jsr	SETLFS			;Dateiparameter festlegen.
			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#1			;Daenkanal:
			ldx	#<:srcbuf		;Dateiname "#" = Laufwerkspuffer.
			ldy	#>:srcbuf
			jsr	SETNAM			;Dateiname setzen.
			lda	#2			;Dateinummer #2.
			ldx	source			;Quell-Laufwerk.
			ldy	#2			;Sekundäradresse #2.
			jsr	SETLFS			;Dateiparameter festlegen.
			jsr	OPENCHN			;Datenkanal öffnen.

			rts				;Ende.

::srcbuf		b "#"				;Laufwerkspuffer.

;*** Ziel: Daten-/Befehlskanal öffnen
:openTarget		lda	#$00			;Befehlskanal:
;			tax				;Kein Dateiname erforderlich.
;			tay
			jsr	SETNAM			;Dateiname setzen.
			lda	#11			;Dateinummer #11.
			ldx	target			;Ziel-Laufwerk.
			ldy	#15			;Sekundäradresse #15.
			jsr	SETLFS			;Dateiparameter festlegen.
			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#1			;Daenkanal:
			ldx	#<:tgtbuf		;Dateiname "#" = Laufwerkspuffer.
			ldy	#>:tgtbuf
			jsr	SETNAM			;Dateiname setzen.
			lda	#3			;Dateinummer #3.
			ldx	target			;Ziel-Laufwerk.
			ldy	#3			;Sekundäradresse #3.
			jsr	SETLFS			;Dateiparameter festlegen.
			jsr	OPENCHN			;Datenkanal öffnen.

			rts				;Ende.

::tgtbuf		b "#"

;*** Quelle: Daten-/Befehlskanal schließen
:closeSource		lda	#2			;Quelle: Datenkanal schließen.
			jsr	CLOSE
			lda	#10			;Quelle: Befehlskanal schließen.
			jsr	CLOSE

			rts

;*** Ziel: Daten-/Befehlskanal öffnen
:closeTarget		lda	#3			;Ziel: Datenkanal schließen.
			jsr	CLOSE
			lda	#11			;Ziel: Befehlskanal schließen.
			jsr	CLOSE

			rts

;*** Quelle: Sektor lesen.
:readSource		jsr	setTrSeAdr		;Track/Sektor übernehmen.

			lda	#"1"			;"U1"-Befehl.
			sta	FComMode
			lda	#"2"			;Datenkanal #2.
			sta	FComSA
			lda	drvsource		;Laufwerk 0/1 bei Doppellaufwerken.
			clc
			adc	#"0"
			sta	FComDrv
			jsr	sendFCom10		;"U1"-Befehl senden (READ).

			rts				;Ende.

;*** Quelle: Daten von Laufwerk einlesen.
:getDataSource		lda	#"2"			;Datenkanal #2.
			sta	setBPsa
			jsr	sendBP10		;"B-P": Laufwerkspuffer auf Anfang.

			jsr	receiveSource		;256 Bytes aus Laufwerkspuffer in

			rts

;*** Ziel: Daten an Laufwerk senden.
:putDataTarget		lda	#"3"			;Datenkanal #3.
			sta	setBPsa
			jsr	sendBP11		;"B-P": Laufwerkspuffer auf Anfang.

			jsr	sendTarget		;256 Bytes aus Zwischenspeicher an
							;Laufwerkspuffer sende.
			rts

;*** Ziel: Sektor schreiben.
:writeTarget		jsr	setTrSeAdr		;Track/Sektor übernehmen.

			lda	#"2"			;"U2"-Befehl.
			sta	FComMode
			lda	#"3"			;Datenkanal #3.
			sta	FComSA
			lda	drvtarget		;Laufwerk 0/1 bei Doppellaufwerken.
			clc
			adc	#"0"
			sta	FComDrv
			jsr	sendFCom11		;"U2"-Befehl senden (WRITE).

			rts				;Ende.

;*** Quelle: 256 Bytes empfangen.
:receiveSource		ldx	#2			;Eingabekanal #2 setzen.
			jsr	CHKIN

			ldy	#0			;256 Bytes aus Laufwerkspuffer in
::1			ldx	STATUS			;Datnende erreicht ?
			bne	:exit			; => Ja, Abbruch...
			jsr	CHRIN			;Zwischenspeicher einlesen.
			sta	$cf00,y
			iny
			bne	:1

::exit			txa				;Statusbyte zwischenspeichern.
			pha
			jsr	CLRCHN			;Eingabekanal zurücksetzen.
			pla
			tax				;Statusbyte wieder herstellen.

			jsr	CheckError		;Fehlerstatus auswerten.

			rts				;Ende.

;*** Ziel: 256 Bytes senden.
:sendTarget		ldx	#3			;Ausgabekanal #3 setzen.
			jsr	CKOUT

			ldy	#0			;256 Bytes aus Zwischenspeicher an
::1			lda	$cf00,y			;Laufwerkspuffer sende.
			jsr	BSOUT
			ldx	STATUS			;Datnende erreicht ?
			bne	:exit			; => Ja, Abbruch...
			iny
			bne	:1

::exit			txa				;Statusbyte zwischenspeichern.
			pha
			jsr	CLRCHN			;Eingabekanal zurücksetzen.
			pla
			tax				;Statusbyte wieder herstellen.

			jsr	CheckError		;Fehlerstatus auswerten.

			rts				;Ende.

;*** U1/U2-Befehl senden.
;Übergabe: FComMode  = "1"/"2".
;          FComSA    = Sekundäradresse Laufwerkspuffer.
;          FComAdrTR = Track  "000"-"255".
;          FComAdrSE = Sektor "000"-"255".
:sendFCom10		ldx	#10			;Quelle: Befehlskanal #10.
			b $2c
:sendFCom11		ldx	#11			;Ziel  : Befehlskanal #11.
			jsr	CKOUT			;Ausgabekanal setzen

			ldy	#0			;"Ux"-Befehl senden:
::1			lda	FCom,y			;Zeichen aus Befehl einlesen.
			beq	:2			;Ende erreicht ? => Ja, Ende...
			jsr	BSOUT			;Zeichen senden.
			iny				;Alle Zeichen gesendet ?
			bne	:1			; => Nein, weiter...

::2			jsr	CLRCHN			;Ausgabekanal zurüsetzen.

			rts				;Ende.

:FCom			b "U"
:FComMode		b "1 "				;U1=READ / U2=WRITE
:FComSA			b "2 "				;Datenkanal #2 / #3.
:FComDrv		b "0 "				;Laufwerksnummer (Bei 1541/71/81 immer #0).
:FComAdrTr		b "000 "			;Track 0-255.
:FComAdrSe		b "000"				;Sektor 0-255.
			b $00				;"Befehlsende"-Kennung.

;*** Laufwerkspuffer auf Anfang setzen.
;Übergabe: setBPsa = Sekundäradresse Laufwerkspuffer.
:sendBP10		ldx	#10			;Quelle: Befehlskanal #10.
			b $2c
:sendBP11		ldx	#11			;Ziel  : Befehlskanal #11.
			jsr	CKOUT			;Ausgabekanal setzen

			ldy	#0			;"B-P"-Befehl senden:
::1			lda	setBP,y			;Zeichen aus Befehl einlesen.
			beq	:2			;Ende erreicht ? => Ja, Ende...
			jsr	BSOUT			;Zeichen senden.
			iny				;Alle Zeichen gesendet ?
			bne	:1			; => Nein, weiter...

::2			jsr	CLRCHN			;Ausgabekanal zurüsetzen.

			rts				;Ende.

:setBP			b "B-P "			;"B-P"-Befehl.
:setBPsa		b "2 "				;Datenkanal #2 / #3.
:setBPadr		b "0"				;Zeiger auf Anfang.
			b $00				;"Befehlsende"-Kennung.

;*** Fehlerstatus abfragen.
:getErrStat10		ldx	#10			;Quelle: Befehlskanal #10.
			b $2c
:getErrStat11		ldx	#11			;Ziel  : Befehlskanal #11.
			jsr	CHKIN

			lda	STATUS			;Fehler ?
			bne	:done			; => Ja, Abbruch...

			jsr	CHRIN			;Fehlerbyte #1 einlesen.
			pha
			jsr	CHRIN			;Fehlerbyte #1 einlesen.
			pha

::1			lda	STATUS			;Status einlesen. Ende erreicht ?
			bne	:2			; => Ja, weiter...
			jsr	CHRIN			;Nächstes Zeichen einlesen.
			jmp	:1			;Schleife...

::2			jsr	CLRCHN			;Eingabekanal zurücksetzen.

			pla				;Einer/Zehner in Fehlercode wandeln.
			sec
			sbc	#"0"
			tax
			pla
			sec
			sbc	#"0"
			tay
			txa

			cpy	#$00			;Fehler < 10 ?
			beq	:exit			; => Ja, Ende...

::add10			clc				;Fehlercode +10.
			adc	#10
			dey				;Ende erreicht ?
			bne	:add10			; => Nein, weiter...

::done			tax				;Fehler im XReg übergeben.
			jsr	CheckError		;Fehlerstatus auswerten.

::exit			rts				;Ende.

;*** Fehlerstatus auswerten.
;Übergabe: XReg = Fehler, $00=OK.
:CheckError		cpx	#$00			;Fehler ?
			beq	:exit			; => Nein, Ende...

			stx	errcode			;Fehlercode speichern.

			lda	CURDEV			;Aktuelles Laufwerk einlesen und
			sta	errdrive		;Laufwerk für Fehler speichern.

			lda	track			;Aktuellen Track einlesen und
			sta	errtrack		;Track für Fehler speichern.

			ldy	errcount		;Fehlerzähler einlesen.
			iny				;Zähler voll ?
			beq	:1			; => Ja, weiter...
			sty	errcount		;Fehlerzäler +1.
::1			ldy	errmode			;Fehler ignorieren oder abbrechen ?
			bne	:exit			; => Abbrechen, Ende...

			ldx	#$00			;Fehler ignorieren.
::exit			rts

;*** Track/Sektor in Befehl übertragen.
;Übergabe: track  = Track  0-255.
;          sector = Sektor 0-255.
:setTrSeAdr		lda	track			;Trackadresse einlesen und
			jsr	Byte2DEZ		;nach ASCII wandeln.
			sty	FComAdrTr +0		; -> Hunderter.
			stx	FComAdrTr +1		; -> Zehner.
			sta	FComAdrTr +2		; -> Einer.

			lda	sector			;Sektoradresse einlesen und
			jsr	Byte2DEZ		;nach ASCII wandeln.
			sty	FComAdrSe +0		; -> Hunderter.
			stx	FComAdrSe +1		; -> Zehner.
			sta	FComAdrSe +2		; -> Einer.

			rts				;Ende.

;*** Byte nach ASCII/Dezimal wandeln.
:Byte2DEZ		ldy	#"0"			; -> Hunderter.
			ldx	#"0"			; -> Zehner.

::1			cmp	#100			;Zahl < 100 ?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#100
			iny
			bne	:1

::2			cmp	#10			;Zahl < 10 ?
			bcc	:3			; => Ja, weiter...
;			sec
			sbc	#10
			inx
			bne	:2

::3			;clc
			adc	#"0"			; -> Einer.
			rts
