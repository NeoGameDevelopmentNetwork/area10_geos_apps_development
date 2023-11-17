; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
			t "src.1541_Tur.ext"
endif

			o $9000
			n "DiskDev_1541"
			a "M. Kanet"

:vInitForIO		w xInitForIO
:vDoneWithIO		w xDoneWithIO
:vExitTurbo		w xExitTurbo
:vPurgeTurbo		w xPurgeTurbo
:vEnterTurbo		w xEnterTurbo
:vChangeDiskDev		w xChangeDiskDev
:vNewDisk		w xNewDisk
:vReadBlock		w xReadBlock
:vWriteBlock		w xWriteBlock
:vVerWriteBlock		w xVerWriteBlock
:vOpenDisk		w xOpenDisk
:vGetBlock		w xGetBlock
:vPutBlock		w xPutBlock
:vGetDirHead		w xGetDirHead
:vPutDirHead		w xPutDirHead
:vGetFreeDirBlk		w xGetFreeDirBlk
:vCalcBlksFree		w xCalcBlksFree
:vFreeBlock		w xFreeBlock
:vSetNextFree		w xSetNextFree
:vFindBAMBit		w xFindBAMBit
:vNxtBlkAlloc		w xNxtBlkAlloc
:vBlkAlloc		w xBlkAlloc
:vChkDkGEOS		w xChkDkGEOS
:vSetGEOSDisk		w xSetGEOSDisk

:vGet1stDirEntry	jmp	xGet1stDirEntry
:vGetNxtDirEntry	jmp	xGetNxtDirEntry
:vGetBorderBlock	jmp	GetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	GetBlock_dskBuf
:vPutBlock_dskBuf	jmp	PutBlock_dskBuf
			jmp	TurboRoutine_r1
			jmp	GetDiskError
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadBlock

;*** Aktuelle BAM einlesen.
:xGetDirHead		jsr	SetBAM_TrSe1		;Zeiger auf Track/Sektor/Speicher.
			bne	xGetBlock		;Weiter mit "Sektor lesen".

;*** Sektor nach ":diskBlkBuf" einlesen.
:GetBlock_dskBuf	lda	#> diskBlkBuf		;Zeiger auf ":diskBlkBuf" richten.
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L

;*** Sektor nach ":r4" einlesen.
:xGetBlock		jsr	EnterTurbo		;Turbo aktivieren.
			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	ReadBlock		;Sektor von Diskette lesen.
			jsr	DoneWithIO		;I/O abschalten
::51			rts				;Ende...

;*** Aktuelle BAM auf Diskette speichern.
:xPutDirHead		jsr	SetBAM_TrSe1		;Zeiger auf Track/Sektor/Speicher.
			bne	xPutBlock		;Weiter mit "Sektor schreiben".

;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
:PutBlock_dskBuf	lda	#> diskBlkBuf		;Zeiger auf ":diskBlkBuf" richten.
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L

;*** Sektor in ":r4" auf Diskette schreiben.
:xPutBlock		jsr	EnterTurbo		;Turbo aktivieren.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	WriteBlock		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			jsr	VerWriteBlock		;Sektor vergleichen.
::51			jsr	DoneWithIO		;I/O abschalten.
::52			rts				;Ende...

;*** Zeiger auf BAM-Sektor und BAM-Speicher setzen.
:SetBAM_TrSe1		lda	#$12			;Track #18.
			sta	r1L
			lda	#$00			;Sektor #0.
			sta	r1H
			sta	r4L			;Speicher ":curDirHead".
			lda	#> curDirHead
			sta	r4H
			rts

;*** Sektor in ShadowRAM bereits gespeichert ?
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:IsSekInRAM_OK		bit	curType			;Shadow 1541 ?
			bvc	TestTrSe_ADDR		;Nein, weiter...

			jsr	VerifySekInRAM		;Sektor in ShadowRAM gespeichert ?
			beq	CancelTest		;Ja, weiter...

:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#$02			;Vorbereiten: "Falsche Sektor-Nr.".

			lda	r1L			;Track-Nummer einlesen.
			beq	CancelTest		; =  0, Fehler...
			cmp	#36
			bcs	CancelTest		; > 35, Fehler...
			sec				;Sektor-Adresse in Ordnung, Ende...
			rts

:CancelTest		clc
			rts

;*** Neue Diskette öffnen.
:xOpenDisk		ldy	curDrive
			lda	driveType -8,y		;Laufwerkstyp einlesen und
			sta	driveTypeCopy		;zwischenspeichern.
			and	#$bf			;Shadow-Bit löschen und
			sta	driveType -8,y 		;zurückschreiben.

			jsr	NewDisk			;Neue Diskette initialisieren.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			bit	driveTypeCopy		;Shadow1541 ?
			bvc	:51			;Nein, weiter...

			jsr	VerifySekInRAM		;BAM in ShadowRAM gespeichert ?
			beq	:51			;Ja, weiter...

			jsr	NewShadowDisk		;ShadowRAM löschen.
			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor setzen.
			jsr	SaveSekInRAM		;BAM in ShadowRAM speichern.

::51			lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L			;Zeiger auf BAM richten und
			jsr	ChkDkGEOS 		;auf GEOS-Diskette testen.

			lda	#> curDirHead +$90
			sta	r4H
			lda	#< curDirHead +$90
			sta	r4L
			ldx	#r5L			;Zeiger auf Speicher für
			jsr	GetPtrCurDkNm		;Diskettennamen setzen.

			ldx	#r4L
			ldy	#r5L
			lda	#18
			jsr	CopyFString		;Diskettenname kopieren.

			ldx	#$00
::52			lda	driveTypeCopy
			ldy	curDrive
			sta	driveType -8,y		;Laufwerkstyp zurücksetzen.
			rts

:driveTypeCopy		b $00

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xBlkAlloc		ldy	#$01			;Zeiger auf ersten Sektor
			sty	r3L			;auf Diskette.
			dey
			sty	r3H

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r3 = Erster Sektor für Suche nach freiem Sektor,
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xNxtBlkAlloc		PushW	r9
			PushW	r3

			lda	#0			;Anzahl Bytes in Anzahl Sektoren
			sta	r3H			;umrechnen.
			lda	#254
			sta	r3L
			ldx	#r2L
			ldy	#r3L
			jsr	Ddiv

			lda	r8L			;Bytes / 254, Rest = 0 ?
			beq	:51			;Ja, weiter...
			inc	r2L			;Anzahl Sektoren +1.
			bne	:51
			inc	r2H

::51			lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L
			jsr	CalcBlksFree

			PopW	r3			;Register ":r3" zurücksetzen.

			ldx	#$03			;Fehler "Kein Platz auf Diskette!"
			lda	r2H			;Genügend Speicher frei ?
			cmp	r4H
			bne	:52
			lda	r2L
			cmp	r4L
::52			beq	:53
			bcs	:58			;Nein, Fehler, Abbruch...

::53			lda	r6H			;Zeiger auf Track/Sektor-Tabelle
			sta	r4H			;nach ":r4" kopieren.
			lda	r6L
			sta	r4L

			lda	r2H			;Anzahl Sektoren nach ":r5"
			sta	r5H			;kopieren.
			lda	r2L
			sta	r5L

::54			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...

			ldy	#$00
			lda	r3L			;Sektor in Track/Sektor-Tabelle
			sta	(r4L),y			;kopieren.
			iny
			lda	r3H
			sta	(r4L),y

			clc				;Zeiger auf Track/Sektor-Tabelle
			lda	#$02			;korrigieren.
			adc	r4L
			sta	r4L
			bcc	:55
			inc	r4H

::55			lda	r5L			;Anzahl Sektoren -1.
			bne	:56
			dec	r5H
::56			dec	r5L
			lda	r5L
			ora	r5H			;Alle Sektoren belegt ?
			bne	:54			;Nein, weiter...

			ldy	#$00
			tya
			sta	(r4L),y
			iny
			lda	r8L			;Anzahl Bytes in letztem Sektor
			bne	:57			;in Track/Sektor-Tabelle kopieren.
			lda	#$fe
::57			clc
			adc	#$01
			sta	(r4L),y
			ldx	#$00			;Kein Fehler, Ende...

::58			PopW	r9			;Register ":r9" zurücksetzen.
			rts

;*** Zeiger auf ersten Verzeichnis-Eintrag richten.
:xGet1stDirEntry	lda	#$12			;Track #18.
			sta	r1L
			lda	#$01			;Sektor #1.
			sta	r1H
			jsr	vGetBlock_dskBuf	;Sektor nach ":diskBlkBuf".

			lda	#> diskBlkBuf +2	;Zeiger auf ersten Eintrag.
			sta	r5H
			lda	#< diskBlkBuf +2
			sta	r5L

			lda	#$00			;Flag für "Aktueller Sektor ist
			sta	Flag_BorderBlock	;Borderblock" löschen.
			rts

;*** Nächsten Verzeichnis-Eintrag einlesen.
;    Übergabe:		r5 = Zeiger auf aktuelle Eintrag in Verzeichnis-Sektor.
;			diskBlkBuf = Aktueller Verzeichnis-Sektor.
:xGetNxtDirEntry	ldx	#$00
			ldy	#$00
			clc				;Register ":r5" auf nächsten
			lda	#$20			;Eintrag setzen.
			adc	r5L
			sta	r5L
			bcc	:51
			inc	r5H

::51			lda	r5H			;Alle Einträge eines Sektors
			cmp	#$80			;eingelesen ?
			bne	:52
			lda	r5L
			cmp	#$ff
::52			bcc	:54			;Nein, weiter...

			ldy	#$ff
			lda	diskBlkBuf +$01		;Zeiger auf nächsten
			sta	r1H			;Verzeichnis-Sektor richten.
			lda	diskBlkBuf +$00
			sta	r1L			;Sektor verfügbar ?
			bne	:53			;Ja, weiter...

			lda	Flag_BorderBlock	;Ist Borderblock im Speicher ?
			bne	:54			;Ja, weiter...
			lda	#$ff			;Borderblock als letzten
			sta	Flag_BorderBlock	;Verzeichnisblock einlesen.

			jsr	vGetBorderBlock		;Zeiger auf Borderblock richten.
			txa				;Diskettenfehler ?
			bne	:54			;Ja, Abbruch...
			tya				;Borderblock verfügbar ?
			bne	:54			;Nein, Ende...

::53			jsr	vGetBlock_dskBuf	;Verzeichnissektor einlesen.

			ldy	#$00
			lda	#> diskBlkBuf +2	;Zeiger auf ersten Eintrag.
			sta	r5H
			lda	#< diskBlkBuf +2
			sta	r5L
::54			rts

;*** Zeiger auf Borderblock einlesen.
:GetBorderBlock		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L
			jsr	ChkDkGEOS		;Auf GEOS-Diskette testen.
			bne	:51			; => GEOS-Diskette, weiter...

			ldy	#$ff			;Flag: "Keine GEOS-Diskette" und
			bne	:52			;Ende...

::51			lda	curDirHead +172		;Zeiger auf Borderblock setzen.
			sta	r1H
			lda	curDirHead +171
			sta	r1L
			ldy	#$00			;Flag: "GEOS-Diskette" und
::52			ldx	#$00			;Kein Fehler...
::53			rts

;*** Auf GEOS-Diskette testen.
;    Übergabe:		r5 = Zeiger auf aktuelle BAM (":curDirHead").
:xChkDkGEOS		ldy	#$ad			;Zeiger auf BAM.
			ldx	#$00

			lda	#$00			;Flag: "Keine GEOS-Diskette".
			sta	isGEOS

::51			lda	(r5L)     ,y		;Format-Text vergleichen.
			cmp	FormatText,x
			bne	:52			;Fehler, keine GEOS-Diskette.
			iny
			inx
			cpx	#$0b
			bne	:51
			lda	#$ff			;Flag: "GEOS-Diskette".
			sta	isGEOS
::52			lda	isGEOS
			rts

:FormatText		b "GEOS format V1.0",NULL

;*** Freien Verzeichnis-Sektor suchen.
;    Übergabe:		r10L = Erste Seite für Suche nach freiem Eintrag.
:xGetFreeDirBlk		php
			sei

			lda	r6L			;Register ":r6L" speichern.
			pha

			lda	r2H			;Register ":r2"  speichern.
			pha
			lda	r2L
			pha

			ldx	r10L			;Erste Verzeichnis-Seite
			inx				;festlegen.
			stx	r6L

			lda	#$12			;Zeiger auf ersten Verzeichnis-
			sta	r1L			;Sektor setzen.
			lda	#$01
			sta	r1H

::51			jsr	vGetBlock_dskBuf	;Sektor von Diskette lesen.
::52			txa				;Diskettenfehler ?
			bne	:57			;Ja, Abbruch...

			dec	r6L			;Verzeichnis-Seite erreicht ?
			beq	:55			;Ja, weiter...

::53			lda	diskBlkBuf +$00		;Nächster Sektor verfügbar ?
			bne	:54			;Ja, weiter...

			jsr	vCreateNewDirBlk
			clv
			bvc	:52

::54			sta	r1L			;Zeiger auf nächsten Sektor
			lda	diskBlkBuf +$01		;setzen und Sektor von Diskette
			sta	r1H			;einlesen.
			clv
			bvc	:51

::55			ldy	#$02			;Freien Verzeichnis-Eintrag
			ldx	#$00			;innerhalb des Sektors suchen.
::56			lda	diskBlkBuf +$00,y	;Eintrag frei ?
			beq	:57			;Ja, weiter...
			tya
			clc
			adc	#$20			;Zeiger auf nächsten Eintrag.
			tay				;Alle Einträge geprüft ?
			bcc	:56			;Nein, weiter...

			lda	#$01			;Flag: "Nächsten Sektor suchen".
			sta	r6L

			ldx	#$04
			ldy	r10L			;Zeiger auf nächste
			iny				;Verzeichnis-Seite setzen.
			sty	r10L
			cpy	#$12			;18 Seiten/8 Dateien = 144 Einträge.
			bcc	:53

::57			pla				;Register ":r2"  zurücksetzen.
			sta	r2L
			pla
			sta	r2H

			pla				;Register ":r6L" zurücksetzen.
			sta	r6L
			plp
			rts

;*** Neuen Verzeichnis-Sektor erstellen.
;    Übergabe:		r1 = Aktueller Verzeichnis-Track/Sektor.
:xCreateNewDirBlk	lda	r6H			;Register ":r6" zwischenspeichern.
			pha
			lda	r6L
			pha

			ldy	#$48			;Zeiger auf BAM.
			ldx	#$04			;Vorbereiten: "Verzeichnis voll".
			lda	curDirHead,y		;Freie Verzeichnis-Sektoren testen.
			beq	:51			; => Abbruch wenn kein Sektor frei.

			lda	r1H			;Aktuellen Verzeichnis-Sektor als
			sta	r3H			;Startwert für Suche nach freien
			lda	r1L			;Verzeichnis-Sektor setzen.
			sta	r3L
			jsr	SetNextFree		;Freien Sektor suchen.

			lda	r3H			;Freien Sektor als LinkBytes in
			sta	diskBlkBuf +$01		;aktuellem Verzeichnis-Sektor
			lda	r3L			;eintragen.
			sta	diskBlkBuf +$00
			jsr	vPutBlock_dskBuf	;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			lda	r3H			;Zeiger auf aktuellen Sektor.
			sta	r1H
			lda	r3L
			sta	r1L
			jsr	Clr_diskBlkBuf		;Sektor-Speicher löschen.

::51			pla				;Register ":r6" zurücksetzen.
			sta	r6L
			pla
			sta	r6H
			rts

;*** Sektorspeicher ":diskBlkBuf" löschen.
;    Übergabe:		r1 = Track/Sektor.
:Clr_diskBlkBuf		lda	#$00
			tay
::51			sta	diskBlkBuf,y		;Sektor-Inhalt löschen.
			iny
			bne	:51
			dey
			sty	diskBlkBuf +1		;Link-Zeiger definieren.
			jmp	vPutBlock_dskBuf	;Sektor auf Disk schreiben.

;*** Nächsten freien Sektor auf Diskette belegen.
;    Übergabe:		r3 = Track/Sektor.
:xSetNextFree		lda	r3H			;Zeiger auf nächsten Sektor
			clc				;durch "interleave" berechnen.
			adc	interleave
			sta	r6H

			lda	r3L			;Zeiger auf aktuellen Track setzen.
			sta	r6L

			cmp	#$19			;Suche auf Track #25 oder größer ?
			bcc	:51			;Nein, weiter...
			dec	r6H			;Zeiger auf Sektor korrigieren.

::51			cmp	#$12			;Aktueller Track #18 ?
			beq	:53			;Ja, weiter...

;*** Suche nach Sektor auf neuem Track durchführen.
::52			lda	r6L			;Aktuellen Track einlesen.
			cmp	#$12			;Track #18 erreicht ?
			beq	:55			;Ja, weiter mit nächstem Track.

::53			asl
			asl
			tax
			lda	curDirHead,x		;Sektoren auf Track frei ?
			beq	:55			;Nein, Zeiger auf nächsten Track.

			lda	r6L
			jsr	GetVecMaxSekTab		;Zeiger auf Sektortabelle berechnen.
			lda	MaxSekTrackTab,x	;Max. Anzahl Sektoren einlesen und
			sta	r7L			;zwischenspeichern.
			tay				;Anzahl Sektoren als Zähler setzen.
::54			jsr	TestCurSekFree		;Sektor frei ?
			beq	:56			;Ja, weiter...

			inc	r6H			;Sektor-Zähler +1.
			dey				;Alle Sektoren geprüft ?
			bne	:54			;Nein, weiter..

::55			inc	r6L			;Zeiger auf nächsten Track.
			lda	r6L
			cmp	#$24			;Ende Diskette erreicht ?
			bcs	:57			;Ja, Fehler, Diskette voll...

			sec				;Zeiger auf ersten Sektor des
			sbc	r3L			;neuen Tracks berechnen.
			sta	r6H
			asl
			adc	#$04
			adc	interleave
			sta	r6H
			clv
			bvc	:52			;Weitersuchen.

::56			lda	r6L			;Freien Sektor in ":r3"
			sta	r3L			;übergeben.
			lda	r6H
			sta	r3H
			ldx	#$00			;Kein Fehler...
			rts
::57			ldx	#$03			;Fehler: "Diskette voll".
			rts

;*** Zeiger auf Tabelle mit Sektorzahlen berechnen.
:GetVecMaxSekTab	ldx	#$00
::51			cmp	NewSekTrackTab,x
			bcc	:52
			inx
			bne	:51
::52			rts

;*** Tabelle mit Tracks, bei denen ein Wechsel
;    der max. Sektoranzahl stattfindet.
:NewSekTrackTab		b $12,$19,$1f,$24

;*** Tabelle mit max. Anzahl Sektoren/Track.
:MaxSekTrackTab		b $15,$13,$12,$11

;*** Aktuellen Sektor auf Gültigkeit testen.
;    Anschließend testen ob Sektor frei ist.
:TestCurSekFree		lda	r6H
::51			cmp	r7L
			bcc	:52
			sec
			sbc	r7L
			clv
			bvc	:51
::52			sta	r6H

;*** Sektor in BAM belegen.
:xAllocateBlock		jsr	FindBAMBit		;Position in der BAM berechnen.
			beq	:51			;Sektor belegt, Fehler...

			lda	r8H
			eor	#$ff
			and	curDirHead,x		;Sektor in BAM als
			sta	curDirHead,x		;"Belegt" markieren.
			ldx	r7H			;Anzahl Sektoren/Track korrigieren.
			dec	curDirHead,x
			ldx	#$00			;Kein Fehler...
			rts
::51			ldx	#$06			;Fehler: "BAD BAM".
			rts

;*** Zeiger auf Sektor in BAM berechnen.
;    Übergabe:		r6 = Track/Sektor.
:xFindBAMBit		lda	r6L			;Offset auf Track berechnen.
			asl
			asl
			sta	r7H

			lda	r6H			;Offset innerhalb Byte berechnen.
			and	#$07
			tax
			lda	SingleBitTab,x
			sta	r8H

			lda	r6H			;Zeiger auf Byte mit Sektor-Bit
			lsr				;in BAM berechnen.
			lsr
			lsr
			sec
			adc	r7H
			tax
			lda	curDirHead,x		;Sektor-Byte einlesen und Bit für
			and	r8H			;aktuellen Sektor isolieren.
			rts

:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80

;*** Sektor in BAM freigeben.
;    Übergabe:		r6 = Track/Sektor.
:xFreeBlock		jsr	FindBAMBit		;Position in der BAM berechnen.
			bne	:51			;Sektor belegt, Fehler...

			lda	r8H
			eor	curDirHead,x		;Sektor in BAM als
			sta	curDirHead,x		;"Frei" markieren.
			ldx	r7H			;Anzahl Sektoren/Track korrigieren.
			inc	curDirHead,x
			ldx	#$00			;Kein Fehler...
			rts
::51			ldx	#$06			;Fehler: "BAD BAM".
			rts

;*** Anzahl freier Blocks auf Diskette berechnen.
;    Übergabe:		r5 = Zeiger auf aktuelle BAM (":curDirHead").
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$04
::51			lda	(r5L),y			;Freie Sektoren auf Track einlesen
			clc				;und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H

::52			tya
			clc
			adc	#$04
			tay
			cpy	#$48			;Track #18 erreicht ?
			beq	:52			;Ja, übergehen.

			cpy	#$90			;Track #36 erreicht ?
			bne	:51			;Nein, weiter...

			lda	#>664			;Max. Anzahl freier Blocks.
			sta	r3H
			lda	#<664
			sta	r3L
			rts

;*** Diskette in GEOS-Diskette wandeln.
:xSetGEOSDisk		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L			;Zeiger auf aktuelle BAM.
			jsr	CalcBlksFree		;Anzahl freie Sektoren ermitteln.

			ldx	#$03			;Vorbereiten "Verzeichnis voll".
			lda	r4L
			ora	r4H			;Sektoren auf Diskette frei ?
			beq	:53			;Nein, Abbruch...

			lda	#$13			;Standardwert für Borderblock auf
			sta	r3L			;Track #19, Sektor #0 setzen.
			lda	#$00
			sta	r3H
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Ist Sektor frei ?
			beq	:51			;Ja, weiter...

			lda	#$01			;Zeiger auf Track #1 zurücksetzen.
			sta	r3L
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch.

::51			lda	r3H			;Zeiger auf neuen Sektor nach
			sta	r1H			;":r1" kopieren ? Zeiger auf Sektor
			lda	r3L			;auf Diskette.
			sta	r1L
			jsr	Clr_diskBlkBuf		;Sektor löschen/auf Disk schreiben.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	r1H			;Zeiger auf BorderBlock in BAM
			sta	curDirHead +172		;übertragen.
			lda	r1L
			sta	curDirHead +171

			ldy	#$bc
			ldx	#$0f
::52			lda	FormatText,x		;GEOS-Formatkennung in BAM
			sta	curDirHead,y		;übertragen.
			dey
			dex
			bpl	:52

			jsr	PutDirHead		;BAM auf Diskette schreiben.

::53			rts

;*** I/O aktivieren.
:xInitForIO		php
			pla
			sta	IRQ_RegBuf		;IRQ-Status speichern.

			sei
			lda	CPU_DATA
			sta	CPU_RegBuf		;CPU-Status speichern.

			lda	#$36			;I/O + Kernal einblenden.
			sta	CPU_DATA

			lda	$d01a			;IRQ-Maskenregister speichern.
			sta	RegD01A_Buf
			lda	$d030
			sta	RegD030_Buf

			ldy	#$00
			sty	$d030
			sty	$d01a

			lda	#%01111111		;VIC-Interrupt sperren.
			sta	$d019
			sta	$dc0d			;IRQs sperren.
			sta	$dd0d			;NMIs sperren.

			lda	#> NewIRQ		;IRQ-Routine abschalten.
			sta	$0315
			lda	#< NewIRQ
			sta	$0314

			lda	#> NewNMI		;NMI-Routine abschalten.
			sta	$0319
			lda	#< NewNMI
			sta	$0318

			lda	#$3f			;Datenrichtungsregister A setzen.
			sta	$dd02			;(Serieller Bus)

			lda	$d015			;Aktive Sprites zwischenspeichern.
			sta	RegD015_Buf
			sty	$d015			;Sprites abschalten.

			sty	$dd05			;Timer A löschen.
			iny
			sty	$dd04

			lda	#$81			;NMI-Register initialisieren.
			sta	$dd0d
			lda	#$09			;Timer A starten.
			sta	$dd0e

			ldy	#$2c			;Warteschleife bis Ser. Bus
::51			lda	$d012			;initialisiert (Turbo-Routinen!)
			cmp	$8f
			beq	:51
			sta	$8f
			dey
			bne	:51

			lda	$dd00
			and	#%00000111		;Byte zum aktivieren des Turbo-
			sta	$8e			;Modus ermitteln.
			sta	TurboMode_ON
			ora	#%00110000		;Byte zum abschalten des Turbo-
			sta	$8f			;Modus ermitteln.
			lda	$8e
			ora	#$10
			sta	TurboMode_OFF
			rts

;*** Neue IRQ/NMI-Routine.
:NewIRQ			pla
			tay
			pla
			tax
			pla
:NewNMI			rti

;*** I/O abschalten.
:xDoneWithIO		sei
			lda	RegD030_Buf
			sta	$d030
			lda	RegD015_Buf		;Sprites wieder aktivieren.
			sta	$d015

			lda	#$7f			;NMIs sperren.
			sta	$dd0d

			lda	$dd0d

			lda	RegD01A_Buf		;IRQ-Maskenregister zurücksetzen.
			sta	$d01a

			lda	CPU_RegBuf		;CPU-Register zurücksetzen.
			sta	CPU_DATA

			lda	IRQ_RegBuf		;IRQ-Status zurücksetzen.
			pha
			plp
			rts

;*** Berechnungstabelle für TurboDOS-Byte-Übertragung.
:NibbleByteL		b $0f,$07,$0d,$05
			b $0b,$03,$09,$01
			b $0e,$06,$0c,$04
			b $0a,$02,$08;$00

:NibbleByteH		b $00,$80,$20,$a0
			b $40,$c0,$60,$e0
			b $10,$90,$30,$b0
			b $50,$d0,$70,$f0

;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		$8B/$8C  , Zeiger auf Bytespeicher.
;			yReg     , Zeiger auf erstes Byte.
:TurboBytes_GET		jsr	StopTurboMode
			pha
			pla
			pha
			pla
			sty	$8d

::51			sec				;Warteschleife.
::52			lda	$d012
			sbc	#$31
			bcc	:53
			and	#$06
			beq	:52

::53			lda	$8f			;TurboDOS-Übertragung abschalten.
			sta	$dd00

			lda	$8b
			lda	$8e			;TurboDOS-Übertragung starten.
			sta	$dd00
			dec	$8d
			nop
			nop
			nop

			lda	$dd00			;Byte über TurboDOS einlesen und
			lsr				;Low/High-Nibble berechnen.
			lsr
			nop
			ora	$dd00
			lsr
			lsr
			lsr
			lsr
			ldy	$dd00
			tax
			tya
			lsr
			lsr
			ora	$dd00
			and	#$f0
			ora	NibbleByteL,x

			ldy	$8d			;Zeiger auf Byte-Speicher lesen und
			sta	($8b),y			;Byte in Floppy-Speicher schreiben.
			bne	:51			;Alle Bytes gelsen ? Nein, weiter...

;*** TurboModus abschalten.
:StartTurboMode		ldx	TurboMode_OFF
			stx	$dd00
			rts

;*** Bytes über ser. Bus / TurboDOS senden.
;    Übergabe:		$8B/$8C  , Zeiger auf Bytespeicher.
;			yReg     , Zeiger auf erstes Byte.
:TurboBytes_SEND	jsr	StopTurboMode
			tya
			pha
			ldy	#$00			;Letztes Byte senden, da Routine
			jsr	:52			;max. 255 Byte senden kann!
			pla
			tay
			jsr	StopTurboMode

::51			dey				;Zeiger auf Daten korrigieren.
			lda	($8b),y			;Byte einlesen.

			ldx	$8e			;TurboDOS-Übertragung starten.
			stx	$dd00

::52			tax				;LOW-Nibble für Übertragung
			and	#$0f			;berechnen und speichern.
			sta	$8d

			sec
::53			lda	$d012			;Warteschleife.
			sbc	#$31
			bcc	:54
			and	#$06
			beq	:53

::54			txa

			ldx	$8f			;TurboDOS-Übertragung abschalten.
			stx	$dd00

			and	#$f0			;LOW-Nibble für Übertragung
			ora	$8e			;berechnen und senden.
			sta	$dd00
			ror
			ror
			and	#$f0
			ora	TurboMode_ON
			sta	$dd00

			ldx	$8d			;LOW-Nibble senden.
			lda	NibbleByteH,x
			ora	$8e
			sta	$dd00
			ror
			ror
			and	#$f0
			ora	$8e
			cpy	#$00
			sta	$dd00
			bne	:51
			nop
			nop
			beq	StartTurboMode

;*** Floppy-Befehl an Laufwerk senden.
;    Sendet genau 5 Bytes!
;    Übergabe:		AKKU/xReg, Zeiger auf Floppy-Befehl.
:SendFloppyCom		stx	$8c			;Zeiger auf Floppy-Befehl sichern.
			sta	$8b

			lda	#$00
			sta	STATUS
			lda	curDrive
			jsr	$ffb1			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:52			;Ja, Abbruch...

			lda	#$ff
			jsr	$ff93			;Sekundäradresse senden.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:52			;Ja, Abbruch...

			ldy	#$00
::51			lda	($8b),y			;Bytes an Floppy-Laufwerk senden.
			jsr	$ffa8
			iny
			cpy	#$05
			bcc	:51
			ldx	#$00
			rts

::52			jsr	$ffae			;Laufwerk abschalten.
			ldx	#$0d			;Fehler: "Kein Laufwerk"...
			rts

;*** Floppy-Routine ohne Parameter aufrufen.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
:TurboRoutine		stx	$8c			;Zeiger auf Routine nach $8b/$8c
			sta	$8b			;kopieren.

			ldy	#$02			;2-Byte-Befehl.
			bne	InitTurboData		;Befehl ausführen.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:TurboRoutSet_r1	stx	$8c			;Zeiger auf Routine nach $8b/$8c
			sta	$8b			;kopieren.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		$8B/$8C  , Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:TurboRoutine_r1	ldy	#$04			;4-Byte-Befehl.

			lda	r1H			;Parameter-Bytes in Init-Befehl
			sta	TurboParameter2 		;kopieren.
			lda	r1L
			sta	TurboParameter1

;*** Turbodaten initialisieren.
;    Übergabe:		$8B/$8C = Zeiger auf TurboRoutine.
;			yReg	 = Anzahl Bytes (Routine+Parameter)
:InitTurboData		lda	$8c			;Auszuführende Routine in
			sta	TurboRoutineH		;Init-Befehl kopieren.
			lda	$8b
			sta	TurboRoutineL

			lda	#> TurboRoutineL
			sta	$8c
			lda	#< TurboRoutineL
			sta	$8b
			jmp	TurboBytes_SEND

;*** Fehlerstatus über ser. Bus einlesen.
:GetErrorData		ldy	#$01			;Fehlercoide
			jsr	TurboBytes_GET		;aus Floppy-Programm abfragen.
			pha				;Anzahl Bytes auf Stack retten und
			tay				;Zähler initialisieren.
			jsr	TurboBytes_GET		;Anzahl Bytes aus FloppyRAM lesen.
			pla				;Anzahl Bytes wieder vom Stack
			tay				;holen und in yReg kopieren.
			rts

;*** Turbo-Modus aktivieren.
:StopTurboMode		sei
			lda	$8e
			sta	$dd00

;*** Warten, bis TurboModus bereit.
:WaitTurboReady		bit	$dd00
			bpl	WaitTurboReady
			rts

;*** TurboDOS aktivieren.
:xEnterTurbo		lda	curDrive		;Laufwerk aktivieren.
			jsr	SetDevice

			ldx	curDrive
			lda	turboFlags -8,x		;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:56			;Ja, Abbruch...

			ldx	curDrive
			lda	#$80			;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#$40			;TurboDOS bereits aktiv ?
			bne	:54			;Ja, weiter...

			jsr	InitForIO		;I/O aktivieren.

			ldx	#>ExecTurboDOS
			lda	#<ExecTurboDOS
			jsr	SendFloppyCom		;"M-E" ausführen.
			txa				;Laufwerksfehler ?
			bne	:55			;Ja, Abbruch...

			jsr	$ffae			;Laufwerk abschalten.

			sei				;IRQ sperren.

			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52

			jsr	StartTurboMode

::53			bit	$dd00			;Warten bis Laufwerk aktiv.
			bmi	:53

			jsr	DoneWithIO		;I/O abschalten.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#$40			;Flag für "TurboDOS in FloppyRAM
			sta	turboFlags -8,x		;ist aktiv" setzen.

::54			ldx	#$00			;Flag "Kein Fehler"...
			beq	:56			;Ende...
::55			jsr	DoneWithIO
::56			rts

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w l03e2

;*** TurboDOS-Routine in FloppyRAM abschalten.
:TurnOffTurboDOS	jsr	InitForIO

			ldx	#> l0420
			lda	#< l0420
			jsr	TurboRoutine

			jsr	StopTurboMode

			lda	curDrive
			jsr	$ffb1
			lda	#$ef
			jsr	$ff93
			jsr	$ffae

			jmp	DoneWithIO

;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#> TurboDOS_1541	;Zeiger auf TurboDOS-Routine in
			sta	$8e			;C64-Speicher.
			lda	#< TurboDOS_1541
			sta	$8d

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$1a			;26 * 32 Bytes kopieren.
			sta	$8f

::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	$8d
			sta	$8d
			bcc	:52
			inc	$8e

::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H

::53			dec	$8f			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

::54			jmp	DoneWithIO		;I/O abschalten.

;*** Daten aus TurboDOS-Routine in FloppyRAM kopieren.
:CopyTurboDOSByt	lda	$8f
			ora	numDrives		;Laufwerke verfügbar ?
			beq	:52			;Nein, keine Daten senden...

			ldx	#> Floppy_MW
			lda	#< Floppy_MW
			jsr	SendFloppyCom		;"M-W"-Befehl an Floppy senden.
			txa				;Laufwerksfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#$20			;Anzahl Bytes an Floppy senden.
			jsr	$ffa8			;(Max. 32 Bytes wegen Puffergröße!)

			ldy	#$00
::51			lda	($8d),y			;Byte einlesen und an Floppy senden.
			jsr	$ffa8
			iny
			cpy	#$20			;Alle Bytes gesendet ?
			bcc	:51			;Nein, weiter...

			jsr	$ffae			;Laufwerk abschalten.
::52			ldx	#$00			;Flag: "Kein Fehler..."
::53			rts

;*** Befehl für "M-W".
:Floppy_MW		b "M-W"
:Floppy_ADDR_L		b $00
:Floppy_ADDR_H		b $00

;*** TurboDOS deaktivieren.
:xExitTurbo		txa
			pha
			ldx	curDrive
			lda	turboFlags -8,x
			and	#$40			;Aktuelle Diskette geöffnet ?
			beq	:51			;Nein, weiter...

			jsr	TurnOffTurboDOS		;TurboDOS abschalten.

			ldx	curDrive
			lda	turboFlags -8,x
			and	#$bf
			sta	turboFlags -8,x
::51			pla
			tax
			rts

;*** TurboDOS in aktuellem Laufwerk abschalten.
:xPurgeTurbo		jsr	InitShadowRAM
			jsr	ExitTurbo

;*** TurboDOS in aktuellem Laufwerk "Nicht verfügbar".
:ClrCurTurboFlag	ldy	curDrive
			lda	#$00
			sta	turboFlags -8,y
			rts

;*** Neue Diskette öffnen.
:xNewDisk		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Laufwerksfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	InitShadowRAM		;ShadowRAM löschen.

			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	RepeatFunction

::51			lda	#> l04dc
			sta	$8c
			lda	#< l04dc
			sta	$8b
			jsr	TurboRoutine_r1

			jsr	GetDiskError
			beq	:52

			inc	RepeatFunction
			cpy	RepeatFunction
			beq	:52
			bcs	:51

::52			jsr	DoneWithIO
::53			rts

;*** Geräteadresse ändern.
;    Übergabe:		AKKU     = Neue Geräteadresse.
;			curDrive = Aktuelle Geräteadresse.
:xChangeDiskDev		pha

			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...

			pla
			pha
			ora	#$20			;Neue Geräteadresse berechnen und
			sta	r1L			;zwischenspeichern.

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> l0439
			lda	#< l0439
			jsr	TurboRoutSet_r1

			jsr	DoneWithIO

			jsr	ClrCurTurboFlag
			pla
			tax
			lda	#$c0
			sta	turboFlags -8,x
			stx	curDrive
			stx	curDevice
			ldx	#$00
			rts

::51			pla
			rts

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock		jsr	TestTrSe_ADDR		;Sektor-Adresse testen.
			bcc	:53			;Fehler, Abbruch...

			bit	curType			;Shadow1541 aktiv ?
			bvc	:51			;Nein, weiter...

			jsr	IsSekInShadowRAM	;Sektor in RAM gespeichert ?
			bne	:53			;Ja, weiter...

::51			ldx	#> l058e
			lda	#< l058e
			jsr	TurboRoutSet_r1

			ldx	#> l0320
			lda	#< l0320
			jsr	TurboRoutine

			lda	r4H			;Zeiger auf Daten an
			sta	$8c			;GET-Routine übergeben.
			lda	r4L
			sta	$8b

			ldy	#$00
			jsr	TurboBytes_GET

			jsr	GetReadError
			txa
			beq	:52

			inc	RepeatFunction
			cpy	RepeatFunction
			beq	:52
			bcs	:51

::52			txa
			bne	:53

			bit	curType
			bvc	:53

			jsr	SaveSekInRAM
			clv
			bvc	:53

::53			ldy	#$00
			rts

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	IsSekInRAM_OK
			bcc	:52

::51			ldx	#> l057c
			lda	#< l057c
			jsr	TurboRoutSet_r1

			lda	r4H			;Zeiger auf Daten an
			sta	$8c			;SEND-Routine übergeben.
			lda	r4L
			sta	$8b

			ldy	#$00
			jsr	TurboBytes_SEND

			jsr	GetDiskError
			beq	:52

			inc	RepeatFunction
			cpy	RepeatFunction
			beq	:52
			bcs	:51

::52			rts

;*** Sektor auf Diskette vergleichen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xVerWriteBlock		jsr	IsSekInRAM_OK		;Sektor in ShadowRAM gespeichert ?
			bcc	:54

::51			lda	#$03
			sta	TryVerify

::52			ldx	#> l058e
			lda	#< l058e
			jsr	TurboRoutSet_r1

			jsr	GetDiskError
			txa
			beq	:53

			dec	TryVerify
			bne	:52

			ldx	#$25
			inc	RepeatFunction

			lda	RepeatFunction
			cmp	#$05
			beq	:53
			pha
			jsr	WriteBlock
			pla
			sta	RepeatFunction
			txa
			beq	:51

::53			txa
			bne	:54

			bit	curType
			bvc	:54
			jmp	SaveSekInRAM

::54			rts

;*** Diskettenstatus einlesen.
:GetDiskError		ldx	#> l0325		;Floppy dazu veranlassen den
			lda	#< l0325		;Fehlerstatus über den ser. Bus
			jsr	TurboRoutine		;zu senden.

;*** Diskettenstatus nach READ-Job einlesen.
:GetReadError		lda	#> ErrorCode		;Befehlsbyte über ser. Bus
			sta	$8c			;einlesen.
			lda	#< ErrorCode
			sta	$8b
			jsr	GetErrorData

			lda	ErrorCode
			pha
			tay
			lda	ErrCodes -1,y
			tay
			pla
			cmp	#$01			;$01 = Kein Fehler ?
			beq	:51			;Ja, Ende...
			clc				;Fehlercodes berechnen.
			adc	#30			;Codes 31,32,35,38 sind möglich.
			bne	:52
::51			lda	#$00
::52			tax
			rts

;*** Offset für Fehlercodes (- 30).
:ErrCodes		b $01,$05,$02,$08
			b $08,$01,$05,$01
			b $05,$05,$05

;*** Turbo-Routine für 1541-Laufwerk.
:TurboDOS_1541		d "obj.Turbo41"

;*** ShadowRAM initialisieren.
:InitShadowRAM		bit	curType			;Shaow1541 ?
			bvs	NewShadowDisk		;Ja, weiter...
			rts				;Ende.

:InitWordData		= InitShadowRAM -2
:NewShadowDisk		lda	#>InitWordData		;Zeiger auf Initialisierungswert
			sta	r0H			;für Sektortabelle (2x NULL-Byte!)
			lda	#<InitWordData
			sta	r0L

			ldy	#$00			;Offset in 64K-Bank.
			sty	r1L
			sty	r1H
			sty	r2H			;Anzahl Bytes.
			iny
			iny
			sty	r2L

			iny				;Bank-Zähler initialisieren.
			sty	r3H

			ldy	curDrive		;Zeiger auf erste Bank für
			lda	ramBase -8,y		;Shadow1541-Laufwerk richten.
			sta	r3L

::52			jsr	StashRAM		;Sektor "Nicht gespeichert" setzen.
			inc	r1H			;Zeiger auf nächsten Sektor in Bank.
			bne	:52			;Schleife.

			inc	r3L			;Zeiger auf nächste Bank.
			dec	r3H			;Alle Bänke initialisiert ?
			bne	:52			;Nein, weiter...
			rts

;*** Sektor in ShadowRAM gespeichert ?
:IsSekInShadowRAM	ldy	#$91			;Sektor aus ShadowRAM einlesen.
			jsr	DoShadowRAMOp

			ldy	#$00			;LinkBytes verknüpfen.
			lda	(r4L),y			;Ist Ergebnis = $00, dann war Sektor
			iny				;nicht in RAM gespeichert.
			ora	(r4L),y
			rts

			ldx	#$00			;Nicht genutzte Bytes.
			rts

;*** Sektor in ShadowRAM vergleichen.
:VerifySekInRAM		ldy	#$93
			jsr	DoShadowRAMOp
			and	#$20
			rts

;*** Sektor in ShadowRAM speichern.
:SaveSekInRAM		ldy	#$90

;*** ShadowJOB erledigen.
:DoShadowRAMOp		lda	r0H			;Register ":r0" bis ":r3L" sichern.
			pha
			lda	r0L
			pha
			lda	r1H
			pha
			lda	r1L
			pha
			lda	r2H
			pha
			lda	r2L
			pha
			lda	r3L
			pha

			tya				;DoRAMOp-Job zwischenspeichern.
			pha

			ldy	r1L			;Offset in 64K-Bank berechnen.
			dey
			lda	Offset_64K_Bank,y
			clc
			adc	r1H
			sta	r1H

			lda	Shadow_64K_Bank,y	;Zeiger auf 64K-Bank berechnen.
			ldy	curDrive
			adc	ramBase -8     ,y
			sta	r3L

			ldy	#$00
			sty	r1L
			sty	r2L
			iny
			sty	r2H

			lda	r4H			;Zeiger auf Speicher für Sektor.
			sta	r0H
			lda	r4L
			sta	r0L
			pla				;DoRAMOp-Job einlesen.
			tay
			jsr	DoRAMOp			;Sektor aus/in RAM lesen/schreiben.
			tax				;Transferstatus zurücksetzen.

			pla				;Register ":r0" bis ":r3L" laden.
			sta	r3L
			pla
			sta	r2L
			pla
			sta	r2H
			pla
			sta	r1L
			pla
			sta	r1H
			pla
			sta	r0L
			pla
			sta	r0H

			txa				;Transferstatus zurücksetzen.
			ldx	#$00			;Flag: "Kein Fehler..."
			rts

;*** Variablen.
:Offset_64K_Bank	b $00,$15,$2a,$3f,$54,$69,$7e,$93
			b $a8,$bd,$d2,$e7,$fc,$11,$26,$3b
			b $50,$65,$78,$8b,$9e,$b1,$c4,$d7
			b $ea,$fc,$0e,$20,$32,$44,$56,$67
			b $78,$89,$9a,$ab

:Shadow_64K_Bank	b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$01,$01,$01
			b $01,$01,$01,$01,$01,$01,$01,$01
			b $01,$01,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02

:RegD030_Buf		b $00
:IRQ_RegBuf		b $00
:RegD01A_Buf		b $00
:CPU_RegBuf		b $00
:RegD015_Buf		b $00
			b $00
:TurboRoutineL		b $00
:TurboRoutineH		b $00
:TurboParameter1	b $00
:TurboParameter2	b $00
:TurboMode_ON		b $00
:TurboMode_OFF		b $00
:RepeatFunction		b $00
:ErrorCode		b $00
:TryVerify		b $00
:Flag_BorderBlock	b $00
