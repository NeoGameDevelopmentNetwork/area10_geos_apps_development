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
			t "src.1581_Tur.ext"
:dir3Head		= $9c80
endif

;*** Fehler!
;    In Routine:	xCreateNewDirBlk

			o $9000
			n "DiskDev_1581"
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
:vGetBorderBlock	jmp	xGetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	xGetBlock_dskBuf
:vPutBlock_dskBuf	jmp	xPutBlock_dskBuf
:vTurboRoutine_r1	jmp	xTurboRoutine_r1
:vGetDiskError		jmp	xGetDiskError
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink
			b $03
			b $46,$6f,$72
			b $20,$4e,$6f,$65
			b $6c,$6c,$65,$20
			b $26,$20,$44,$79
			b $6c,$61,$6e,$00
			b $10,$00

;*** Aktuelle BAM einlesen.
:xGetDirHead		lda	#$ff
			sta	Flag_GetPutBAM		;Modus: BAM einlesen.

			jsr	EnterTurbo		;Turbo-Software aktivieren.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	GetPutBAM_TrSe1		;BAM-Sektor #1 einlesen.
			bne	:51			;Fehler, => Abbruch...

			jsr	GetPutBAM_TrSe2		;BAM-Sektor #2 einlesen.
			bne	:51			;Fehler, => Abbruch...

			jsr	GetPutBAM_TrSe3		;BAM-Sektor #3 einlesen.

::51			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			txa
::52			rts

;*** Sektor nach ":diskBlkBuf" einlesen.
:xGetBlock_dskBuf	LoadW	r4,diskBlkBuf		;Zeiger auf ":diskBlkBuf" setzen.

;*** Sektor nach ":r4" einlesen.
:xGetBlock		jsr	EnterTurbo		;Turbo-Software aktivieren.
			bne	:51			;Fehler ? Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich aktivieren.
			jsr	ReadBlock		;Sektor einlesen.
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::51			txa
			rts

;*** Aktuelle BAM speichern.
:xPutDirHead		lda	#$00
			sta	Flag_GetPutBAM		;Modus: BAM einlesen.

			jsr	EnterTurbo		;Turbo-Software aktivieren.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	GetPutBAM_TrSe1		;BAM-Sektor #1 speichern.
			bne	:51			;Fehler, => Abbruch...

			jsr	GetPutBAM_TrSe2		;BAM-Sektor #2 speichern.
			bne	:51			;Fehler, => Abbruch...

			jsr	GetPutBAM_TrSe3		;BAM-Sektor #3 speichern.

::51			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			txa
::52			rts

;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
:xPutBlock_dskBuf	LoadW	r4,diskBlkBuf		;Zeiger auf ":diskBlkBuf" setzen.

;*** Sektor in ":r4" auf Diskette schreiben.
:xPutBlock		jsr	EnterTurbo		;Turbo-Software aktivieren.
			bne	:51			;Fehler ? Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich aktivieren.
			jsr	WriteBlock		;Sektor speichern.
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::51			txa
			rts

;*** BAM-Sektor #1 bis #3 einlesen.
:GetPutBAM_TrSe1	ldx	#> curDirHead		;Zeiger auf ":curDirHead".
			ldy	#< curDirHead
			lda	#$00			;Sektor #0.
			beq	GetPutBAM_TrSe

:GetPutBAM_TrSe2	ldx	#> dir2Head		;Zeiger auf ":dir2Head".
			ldy	#< dir2Head
			lda	#$01			;Sektor #1.
			bne	GetPutBAM_TrSe

:GetPutBAM_TrSe3	ldx	#> dir3Head		;Zeiger auf ":dir3Head".
			ldy	#< dir3Head
			lda	#$02			;Sektor #2.

:GetPutBAM_TrSe		stx	r4H			;Zeiger auf BAM-Speicher setzen.
			sty	r4L
			sta	r1H			;Zeiger auf BAM-Sektor   setzen.
			lda	#$28
			sta	r1L

			bit	Flag_GetPutBAM		;BAM-Modus testen.
			bmi	:51			; => BAM einlesen.

			jsr	xWriteBlock		;BAM-Sektor schreiben.
			txa
			rts

::51			jsr	xReadBlock		;BAM-Sektor einlesen.
			txa
			rts

;*** Ist Track/Sektor-Adresse in Ordnung ?
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#$02			;Vorbereiten: "Falsche Sektor-Nr.".
			lda	r1L			;Track-Nummer einlesen.
			beq	Canceltest		; =  0, Fehler...
			cmp	#81
			bcs	Canceltest		; > 80, Fehler...
			sec
			rts
:Canceltest		clc
			rts

;*** Neue Diskette öffnen.
:xOpenDisk		jsr	NewDisk			;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	GetDirHead		;BAM einlesen.
			bne	:52			;Fehler ? Ja, Abbruch...

			jsr	SetVec_r5_isGEOS	;Zeiger auf BAM richten und
							;auf GEOS-Diskette testen.

			LoadW	r4,curDirHead +$90
			ldx	#$0c
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			ldy	#$12
::51			lda	(r4L),y			;Diskettenname kopieren.
			sta	(r5L),y
			dey
			bpl	:51
			ldx	#$00
::52			rts

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xBlkAlloc		pla				;Rücksprungadresse vom Stapel holen.
			sta	r3L
			pla
			sta	r3H

			lda	r3H			;Rücksprungadresse wieder auf
			pha				;Stapel zurücklegen.
			lda	r3L
			pha

			lda	r3L			;Offset auf ":SaveFile" ermitteln
			sec				;um festzustellen, ob ":BlkAlloc"
			sbc	SaveFile +1		;aus ":SaveFile" aufgerufen wurde.
			sta	r3L
			lda	r3H
			sbc	SaveFile +2
			sta	r3H

			ldy	#$27
			lda	r3H			;Aufruf aus ":SaveFile" ?
			beq	:51			;Ja, weiter...
			ldy	#$23
::51			sty	r3L			;Ersten Track für Sektorsuche
			ldy	#$00			;festlegen.
			sty	r3H

			lda	#$02
			bne	ExecBlkAlloc

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r3 = Erster Sektor für Suche nach freiem Sektor,
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xNxtBlkAlloc		lda	#$00

:ExecBlkAlloc		sta	BlkAllocMode

			PushW	r9			;Register ":r9" zwischenspeichern.
			PushW	r3			;Register ":r3" zwischenspeichern.

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

::51			jsr	SetVec_r5_isGEOS	;Zeiger auf aktuelle BAM.

			PopW	r3			;Register ":r3" zurücksetzen.

			ldx	#$03			;Fehler "Kein Platz auf Diskette!"
			lda	r2H			;Genügend Speicher frei ?
			cmp	r4H
			bne	:52
			lda	r2L
			cmp	r4L
::52			beq	:53
			bcs	:59			;Nein, Fehler, Abbruch...

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
			bne	:59			;Ja, Abbruch...

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

::55			lda	BlkAllocMode
			beq	:56
			dec	BlkAllocMode
			bne	:56
			lda	#$23
			sta	r3L

::56			lda	r5L			;Anzahl Sektoren -1.
			bne	:57
			dec	r5H
::57			dec	r5L
			lda	r5L
			ora	r5H			;Alle Sektoren belegt ?
			bne	:54			;Nein, weiter...

			ldy	#$00
			tya
			sta	(r4L),y
			iny
			lda	r8L			;Anzahl Bytes in letztem Sektor
			bne	:58			;in Track/Sektor-Tabelle kopieren.
			lda	#$fe
::58			clc
			adc	#$01
			sta	(r4L),y
			ldx	#$00			;Kein Fehler, Ende...
::59			PopW	r9			;Register ":r9" zurücksetzen.
			rts

;*** Zeiger auf ersten Verzeichnis-Eintrag richten.
:xGet1stDirEntry	lda	#$28
			sta	r1L
			lda	#$03
			sta	r1H

			lda	#$00
			sta	Flag_BorderBlock
			beq	GetCurDirSek

;*** Nächsten Verzeichnis-Eintrag einlesen.
;    Übergabe:		r5 = Zeiger auf aktuelle Eintrag in Verzeichnis-Sektor.
;			diskBlkBuf = Aktueller Verzeichnis-Sektor.
:xGetNxtDirEntry	ldx	#$00			;Flag: Kein Fehler...
			ldy	#$00			;Zeiger auf erstes Byte in Eintrag.

			clc				;Zeiger auf nächsten Eintrag.
			lda	#$20
			adc	r5L
			sta	r5L
			bcc	:51
			inc	r5H

::51			lda	r5H			;Alle Einträge aus Sektor ?
			cmp	#> diskBlkBuf +255
			bne	:52
			lda	r5L
			cmp	#< diskBlkBuf +255
::52			bcc	EndGetDirSek		;Nein, weiter...

			ldy	#$ff
			lda	diskBlkBuf +$01		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	diskBlkBuf +$00
			sta	r1L			;Sektor verfügbar ?
			bne	GetCurDirSek		;Ja, weiter...

			lda	Flag_BorderBlock	;Borderblock bereits aktiv ?
			bne	EndGetDirSek		;Ja, Ende...
			lda	#$ff			;Borderblock aktivieren.
			sta	Flag_BorderBlock

			jsr	vGetBorderBlock		;Zeiger auf Borderblock berechnen.
			txa				;Diskettenfehler ?
			bne	EndGetDirSek		;Ja, Abbruch...
			tya				;BorderBlock verfügbar ?
			bne	EndGetDirSek		;Nein, Ende...

;*** Nächsten Verzeichnis-Sektor einlesen.
:GetCurDirSek		jsr	vGetBlock_dskBuf	;Sektor einelesen.

			ldy	#$00			;Zeiger auf erstes Byte in Eintrag.
			LoadW	r5,diskBlkBuf +2	;Zeiger auf Eintrag.

:EndGetDirSek		rts

;*** Zeiger auf Borderblock einlesen.
:xGetBorderBlock	jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	SetVec_r5_isGEOS	;Zeiger auf BAM berechnen.
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

;*** Zeiger auf aktuelle BAM im Speicher richten und
;    auf GEOS-Diskette testen.
:SetVec_r5_isGEOS	lda	#$82
			sta	r5H
			lda	#$00
			sta	r5L

;*** Auf GEOS-Diskette testen.
;    Übergabe:		r5 = Zeiger auf aktuelle BAM (":curDirHead").
:xChkDkGEOS		ldy	#$ad			;Zeiger auf BAM.
			ldx	#$00
			stx	isGEOS			;Flag: "Keine GEOS-Diskette".

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

			lda	#$28			;Zeiger auf ersten Verzeichnis-
			sta	r1L			;Sektor setzen.
			lda	#$03
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

			ldx	#$04			;Vorbereiten: "Verzeichnis voll".
			lda	dir2Head +$fa		;Freie Verzeichnis-Sektoren testen.
			beq	Clr_r3_dskBlkBuf	; => Abbruch wenn kein Sektor frei.

			lda	r1H			;Aktuellen Verzeichnis-Sektor als
			sta	r3H			;Startwert für Suche nach freien
			lda	r1L			;Verzeichnis-Sektor setzen.
			sta	r3L
			jsr	SetNextFree		;Freien Sektor suchen.
			pla				;Register ":r6" zurücksetzen.
			sta	r6L
			pla
			sta	r6H

			lda	r3H			;Freien Sektor als LinkBytes in
			sta	diskBlkBuf +$01		;aktuellem Verzeichnis-Sektor
			lda	r3L			;eintragen.
			sta	diskBlkBuf +$00
			jsr	vPutBlock_dskBuf	;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			beq	Clr_r3_dskBlkBuf	;Nein, Sektor löschen...
			rts

;*** Sektorspeicher ":diskBlkBuf" löschen.
;    Übergabe:		r3 = Track/Sektor.
:Clr_r3_dskBlkBuf	lda	r3H			;Zeiger auf aktuellen Sektor.
			sta	r1H
			lda	r3L
			sta	r1L

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
:xSetNextFree		jsr	TestNextSetFree
			bne	:51
			rts

::51			lda	#$27			;Zeiger auf ersten Sektor für
			sta	r3L			;Sektorsuche.

:TestNextSetFree	ldy	r3H			;Zeiger auf nächsten Sektor.
			iny
			sty	r6H

			lda	r3L			;Zeiger auf aktuellen Track setzen.
			sta	r6L

			cmp	#40			;Verzeichnis-Spur erreicht ?
			beq	:52			;Ja, weiter...

::51			lda	r6L			;Aktuellen Track einlesen.
			cmp	#40			;Track #40 erreicht ?
			beq	:57			;Ja, weiter...

::52			cmp	#41			;Zeiger auf Track #1-40
			bcc	:53			;zurücksetzen.
			sec
			sbc	#40

::53			sec				;Zeiger auf BAM berechnen.
			sbc	#$01
			asl
			sta	r7L
			asl
			clc
			adc	r7L
			tax

			lda	r6L			;Speicher für BAM ermitteln.
			cmp	#41			;Track #1 - #40 ?
			bcc	:54			;Ja, weiter...

			lda	dir3Head +16,x		;Anzahl freie Sektoren einlesen.
			clv
			bvc	:55

::54			lda	dir2Head +16,x		;Anzahl freie Sektoren einlesen.
::55			beq	:57			; => Track belegt, weitersuchen.
			ldy	#$28			;Max. Anzahl Sektoren auf Track
			sty	r7L			;zwischenspeichern.

::56			jsr	TestCurSekFree
			beq	:60
			inc	r6H
			dey
			bne	:56

::57			ldy	r6L
			cpy	#41
			bcs	:58
			dey
			bne	:59
			ldy	#41
			bne	:59

::58			iny
			cpy	#81
			bcs	:61
::59			sty	r6L
			ldy	#$00
			sty	r6H
			beq	:51

::60			lda	r6L			;Freien Sektor in ":r3"
			sta	r3L			;übergeben.
			lda	r6H
			sta	r3H
			ldx	#$00			;Kein Fehler...
			rts
::61			ldx	#$03			;Fehler: "Diskette voll".
			rts

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
:xAllocateBlock		jsr	FindBAMBit
			bne	EditBAM_dir3Head
			ldx	#$06
			rts

;*** Sektor in BAM (":dir3Head") belegen / freigeben.
:EditBAM_dir3Head	php				;Z-Flag sichern.

			lda	r6L			;Aktuellen Track einlesen.
			cmp	#41			; < #41 ?
			bcc	EditBAM_dir2Head	;Ja, Sektor in ":dir2Head".

			lda	r8H			;Bit in BAM wechseln, damit
			eor	dir3Head +16,x		;Sektor belegen/freigeben.
			sta	dir3Head +16,x
			ldx	r7H

			plp				;Sektor freigeben ?
			beq	:51			;Ja, weiter...

			dec	dir3Head +16,x		;Anzahl Sektoren -1.
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

::51			inc	dir3Head +16,x		;Anzahl Sektoren +1.
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

;*** Sektor in BAM (":dir2Head") belegen / freigeben.
:EditBAM_dir2Head	lda	r8H			;Bit in BAM wechseln, damit
			eor	dir2Head +16,x		;Sektor belegen/freigeben.
			sta	dir2Head +16,x
			ldx	r7H

			plp				;Sektor freigeben ?
			beq	:51			;Ja, weiter...

			dec	dir2Head +16,x
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

::51			inc	dir2Head +16,x
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

;*** Sektor in BAM freigeben.
;    Übergabe:		r6 = Track/Sektor.
:xFreeBlock		jsr	FindBAMBit
			beq	EditBAM_dir3Head
			ldx	#$06
			rts

;*** Zeiger auf Sektor in BAM berechnen.
;    Übergabe:		r6 = Track/Sektor.
:xFindBAMBit		lda	r6H
			and	#$07
			tax
			lda	SingleBitTab,x
			sta	r8H

			lda	r6L
			cmp	#41
			bcc	:51
			sec
			sbc	#40

::51			sec
			sbc	#1
			asl
			sta	r7H
			asl
			clc
			adc	r7H
			sta	r7H

			lda	r6H
			lsr
			lsr
			lsr
			sec
			adc	r7H
			tax

			lda	r6L
			cmp	#41
			bcc	:52

			lda	dir3Head +16,x
			and	r8H
			rts

::52			lda	dir2Head +16,x
			and	r8H
			rts

:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80

;*** Anzahl freier Blocks auf Diskette berechnen.
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$10
::51			lda	dir2Head,y		;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H
::52			tya
			clc
			adc	#$06
			tay
			cpy	#$fa			;Directory-Track erreicht ?
			beq	:52			;Ja, weiter...
			tay				;Ende BAM#2 erreicht ?
			bne	:51			;Nein, weiter...

			ldy	#$10
::53			lda	dir3Head,y		;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:54
			inc	r4H
::54			tya
			clc
			adc	#$06
			tay				;Ende BAM#3 erreicht ?
			bne	:53			;Nein, weiter...

			lda	#> 3160
			sta	r3H
			lda	#< 3160
			sta	r3L
			rts

;*** Diskette in GEOS-Diskette wandeln.
:xSetGEOSDisk		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#$28			;Standardwert für Borderblock auf
			sta	r3L			;Track #28, Sektor #12 setzen.
			lda	#$12
			sta	r3H
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Ist Sektor frei ?
			bne	:53			;Nein, Abbruch...

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

			jmp	PutDirHead		;BAM auf Diskette schreiben.

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
			and	#$07
			sta	$8e
			sta	TurboInitByte_2 +1
			sta	TurboInitByte_3 +1
			ora	#$30
			sta	$8f
			sta	TurboInitByte_1 +1
			lda	$8e
			ora	#$10
			sta	StopTurboByte
			sta	StopTurboMode   +1

			ldy	#$1f
::52			lda	NibbleByteH,y
			and	#$f0
			ora	$8e
			sta	NibbleByteH,y
			dey
			bpl	:52
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

;*** Floppy-Befehl an Laufwerk senden, sendet genau 5 Bytes!
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
::51			lda	($8b),y			;Befehl senden.
			jsr	$ffa8
			iny
			cpy	#$05
			bcc	:51
			ldx	#$00
			rts

::52			jsr	$ffae			;Laufwerk abschalten.
			ldx	#$0d			;Flag: "Kein Laufwerk"...
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

			jsr	StopTurboMode

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
::56			txa
			rts

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w l040f

;*** TurboDOS-Routine deaktivieren.
:TurnOffTurboDOS	jsr	InitForIO

			ldx	#> l04b9
			lda	#< l04b9
			jsr	xTurboRoutine

			ldx	#> l0457
			lda	#< l0457
			jsr	xTurboRoutine

			jsr	StartTurboMode

;*** Aktuelles Laufwerk deaktivieren.
:TurnOffCurDrive	lda	curDrive
			jsr	$ffb1
			lda	#$ef
			jsr	$ff93
			jsr	$ffae

			ldx	#$00
			jmp	DoneWithIO

;*** TurboDOS für CBM/CMD-Floppy initialisieren.
:InitTurboDOS		jsr	TestForCMD_Drive	;Auf CMD-Laufwerk testen.
			txa				;Ergebnis testen.
			beq	InitTurboDOS_CMD	; => CMD FD,HD, weiter...
			bpl	:51			; => Abbruch, Laufwerksfehler.
			bmi	InitTurboDOS_CBM	; => C=1581, weiter...
::51			rts

;*** CMD-FD,HD initialisieren.
:InitTurboDOS_CMD	jsr	InitForIO		;I/O-Bereich einbleden.
			ldx	#> Floppy_GEOS
			lda	#< Floppy_GEOS
			jsr	SendFloppyCom		;GEOS-Modus aktivieren.
			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...
			jsr	$ffae
			ldx	#$00			;Flag: "Kein Fehler..."
::51			jmp	DoneWithIO		;I/O-Bereich ausblenden.

:Floppy_GEOS		b "GEOS",NULL

;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS_CBM	jsr	InitForIO		;I/O aktivieren.

			lda	#> TurboDOS_1581	;Zeiger auf TurboDOS-Routine in
			sta	$8e			;C64-Speicher.
			lda	#< TurboDOS_1581
			sta	$8d

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$0f			;26 * 32 Bytes kopieren.
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
:CopyTurboDOSByt	ldx	#> Floppy_MW
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

			bit	sysRAMFlg		;Laufwerkstreiber in REU ?
			bvc	:51			;Nein, Ende...

			PushW	r0
			PushW	r1
			PushW	r2
			PushB	r3L

			ldx	curDrive
			lda	dir3Head_RAM_L -8,x
			sta	r1L
			lda	dir3Head_RAM_H -8,x
			sta	r1H
			lda	#> dir3Head
			sta	r0H
			lda	#< dir3Head
			sta	r0L
			ldy	#$00
			sty	r3L
			sty	r2L
			iny
			sty	r2H
			jsr	StashRAM

			PopB	r3L
			PopW	r2
			PopW	r1
			PopW	r0

::51			pla
			tax
			rts

;*** Adresse von ":dir3Head" in REU.
:dir3Head_RAM_L		b < $8300 + $0c80
			b < $9080 + $0c80
			b < $9e00 + $0c80
			b < $ab80 + $0c80
:dir3Head_RAM_H		b > $8300 + $0c80
			b > $9080 + $0c80
			b > $9e00 + $0c80
			b > $ab80 + $0c80

;*** TurboDOS in aktuellem Laufwerk abschalten.
:xPurgeTurbo		jsr	ExitTurbo

			ldy	curDrive
			lda	#$00
			sta	turboFlags -8,y
			rts

;*** Geräteadresse ändern.
;    Übergabe:		AKKU     = Neue Geräteadresse.
;			curDrive = Aktuelle Geräteadresse.
:xChangeDiskDev		sta	Floppy_U0_x +3		;Neue Adresse merken.

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich einbleden.

			ldx	#> Floppy_U0_x
			lda	#< Floppy_U0_x
			jsr	SendFloppyCom		;Geräteadresse ändern.
			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...

			ldy	Floppy_U0_x +3		;Geräteadresse einlesen.
			lda	#$00
			sta	turboFlags -8,y		;TurboFlags löschen.
			sty	curDrive		;Neue Adresse an GEOS übergeben.
			sty	curDevice
			jmp	TurnOffCurDrive		;Laufwerk deaktivieren.

::51			jmp	DoneWithIO

;*** Befehl zum wechseln dr Laufwerksadresse.
:Floppy_U0_x		b "U0",$3e,$08,NULL

;*** Floppy-Routine ohne Parameter aufrufen.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
:xTurboRoutine		stx	$8c			;Zeiger auf Routine nach $8b/$8c
			sta	$8b			;kopieren.

			ldy	#$02			;2-Byte-Befehl.
			bne	InitTurboData		;Befehl ausführen.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:xTurboRoutSet_r1	stx	$8c			;Zeiger auf Routine nach $8b/$8c
			sta	$8b			;kopieren.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		$8B/$8C  , Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:xTurboRoutine_r1	ldy	#$04			;4-Byte-Befehl.

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
:StartTurboMode		sei
			lda	$8e
			sta	$dd00

;*** Warten, bis TurboModus bereit.
:WaitTurboReady		bit	$dd00
			bpl	WaitTurboReady
			rts

;*** Neue Diskette öffnen.
:xNewDisk		jsr	EnterTurbo		;TurboDOS aktivieren.
			bne	:53

			lda	#$00
			sta	RepeatFunction		;Zähler für Versuche auf #0.
			sta	r1L

			jsr	InitForIO		;I/O-Bereich einblenden.

::51			ldx	#> l049b		;NewDisk ausführen.
			lda	#< l049b
			jsr	xTurboRoutSet_r1

			jsr	xGetDiskError		;Diskettenfehler ?
			beq	:52			;Nein, weiter...

			inc	RepeatFunction		;Anzahl Versuche +1.
			cpy	RepeatFunction		;Alle versuche ausgeführt ?
			beq	:52			;Ja, Abbruch...
			bcs	:51			;Nein, NewDisk nochmal aufrufen...

::52			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::53			rts

;*** LinkBytes einlesen.
:xReadLink		jsr	TestTrSe_ADDR		;Sektoradresse testen.
			bcc	:51			;Fehler, Abbruch...

			lda	r1L			;Flag für LinkBytes setzen.
			ora	#$80
			sta	r1L
			jsr	GetLinkBytes		;LinkBytes einlesen
			lda	r1L
			and	#$7f			;Flag für LinkBytes löschen.
			sta	r1L
::51			rts

:ErrCodes		b $01,$05,$02,$08
			b $08,$01,$05,$01
			b $05,$05,$05

:NibbleByteH		b $00,$80,$20,$a0
			b $40,$c0,$60,$e0
			b $10,$90,$30,$b0
			b $50,$d0,$70,$f0

:NibbleByteL		b $00,$20,$00,$20
			b $10,$30,$10,$30
			b $00,$20,$00,$20
			b $10,$30,$10,$30

;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		$8b/$8c  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes (0=256 Byte)
:TurboBytes_GET		jsr	StartTurboMode

:Turbo_SendNxByte	sec				;Warteschleife bis TurboDOS
::51			lda	$d012			;aktiviert ist.
			sbc	#$32
			and	#$07
			beq	:51

:TurboInitByte_1	lda	#$35
			sta	$dd00
			and	#$0f
			sta	$dd00

			lda	$dd00			;High/Low-Nibble einlesen und
			lsr				;Byte-Wert berechnen.
			lsr
			ora	$dd00
			lsr
			lsr
:TurboInitByte_2	eor	#$05
			eor	$dd00
			lsr
			lsr
:TurboInitByte_3	eor	#$05
			eor	$dd00
			dey
			sta	($8b),y			;Nyte speichern und weiter mit
			bne	Turbo_SendNxByte	;nächstem Byte.

:StopTurboMode		ldx	#$0f
			stx	$dd00
			rts

;*** Bytes über ser. Bus / TurboDOS senden.
;    Übergabe:		$8b/$8c  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes (0=256 Byte)
:TurboBytes_SEND	jsr	StartTurboMode		;TurboModus aktivieren.

			tya				;Anzal Bytes in AKKU übertragen und
			pha				;zwischenspeichern.
			ldy	#$00			;Anzahl folgender Bytes an TurboDOS
			jsr	Turbo_SendByte		;in Floppy-RAM senden.
			pla
			tay				;Anzahl Bytes zurücksetzen.

;*** Bytes an Floppy senden.
;    Übergabe:		$8b,$8c = Zeiger auf Daten.
;			yReg    = Anzahl Bytes.
:Turbo_WriteBlock	jsr	StartTurboMode

:Turbo_GetNxByte	dey				;Zeiger auf Daten korrigieren.
			lda	($8b),y			;Byte einlesen.

			ldx	$8e			;TurboDOS-Übertragung starten.
			stx	$dd00

;*** Byte an Floppy senden.
:Turbo_SendByte		tax				;LOW-Nibble für Übertragung
			and	#$0f			;berechnen und speichern.
			sta	$8d

			sec
::51			lda	$d012			;Warteschleife bis TurboDOS
			sbc	#$32			;aktiviert ist.
			and	#$07
			beq	:51

			txa

			ldx	$8f			;Startzeichen an TurboRoutine in
			stx	$dd00			;FloppyRAM übergeben.

			and	#$f0			;HIGH-Nibble für Übertragung
			ora	$8e			;berechnen und Byte senden.
			sta	$dd00
			ror
			ror
			and	#$f0
			ora	$8e
			sta	$dd00

			ldx	$8d			;LOW-Nibble senden.
			lda	NibbleByteH,x
			sta	$dd00
			lda	NibbleByteL,x
			cpy	#$00
			sta	$dd00
			bne	Turbo_GetNxByte
			beq	StopTurboMode

;*** Sektor einlesen.
:xReadBlock		jsr	TestTrSe_ADDR
			bcc	ExitReadBlock

;*** Einsprung aus ":ReadLink".
:GetLinkBytes		ldx	#> l04cc
			lda	#< l04cc
			jsr	xTurboRoutSet_r1

			ldx	#> l031f
			lda	#< l031f
			jsr	xTurboRoutine

			lda	r4H
			sta	$8c
			lda	r4L
			sta	$8b

			ldy	#$00
			lda	r1L
			bpl	:51
			ldy	#$02
::51			jsr	TurboBytes_GET
			jsr	GetReadError
			beq	SwapDskNmData
			inc	RepeatFunction
			cpy	RepeatFunction
			beq	SwapDskNmData
			bcs	GetLinkBytes

;*** Konvertierung der BAM von 1581 nach 1541 und umgekehrt.
:SwapDskNmData		lda	r1L
			cmp	#$28
			bne	:52
			lda	r1H
			bne	:52

			ldy	#$04
::51			lda	(r4L),y
			sta	SwapByteBuf
			tya
			clc
			adc	#$8c
			tay
			lda	(r4L),y
			pha
			lda	SwapByteBuf
			sta	(r4L),y
			tya
			sec
			sbc	#$8c
			tay
			pla
			sta	(r4L),y
			iny
			cpy	#$1d
			bne	:51

::52			txa
:ExitReadBlock		ldy	#$00
			rts

;*** Sektor in ":r4" auf Diskette schreiben.
:xWriteBlock		jsr	TestTrSe_ADDR		;Sektor-Adresse testen.
			bcc	:53			; => Fehler, Abbruch...

			jsr	SwapDskNmData		;BAM nach 1581 Konvertieren.

::51			ldx	#> l047c
			lda	#< l047c
			jsr	xTurboRoutSet_r1

			lda	r4H
			sta	$8c
			lda	r4L
			sta	$8b
			ldy	#$00
			jsr	Turbo_WriteBlock	;256 Byte an Floppy senden.

			jsr	GetReadError		;Diskettenfehler ?
			beq	:52			;Nein, weiter...

			inc	RepeatFunction		;Fehlerzähler korrigieren.
			cpy	RepeatFunction		;Zähler abgelaufen ?
			beq	:52			;Ja, Ende...
			bcs	:51			;Nein, nochmal schreiben...

::52			jsr	SwapDskNmData		;BAM zurückkonvertieren.
::53			rts

;*** Sektor auf Diskette vergleichen.
:xVerWriteBlock		ldx	#$00
			rts

;*** Diskettenstatus inlesen.
:xGetDiskError		ldx	#> l032b
			lda	#< l032b
			jsr	xTurboRoutine

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
			cmp	#$02			;$00,$01 = Kein Fehlr ?
			bcc	:51			;Ja, Ende...
			clc
			adc	#$1e			;Fehlercodes berechnen.
			bne	:52
::51			lda	#$00
::52			tax
			rts

;*** Auf CMD-Laufwerk testen.
:TestForCMD_Drive	jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Fehler-Flag löschen.
			sta	STATUS

			lda	#> FloppyROM_Data	;Zeiger auf Zwischenspeicher.
			sta	$8e
			lda	#< FloppyROM_Data
			sta	$8d

			lda	#$fe			;Zeiger auf ROM-Adresse.
			sta	FloppyROM_H
			lda	#$a0
			sta	FloppyROM_L

			jsr	GetROM_Bytes		;Bytes aus FloppyROM einlesen.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			lda	FloppyROM_Data +0	;Auf CMD-Kennung testen.
			cmp	#"C"
			bne	:51
			lda	FloppyROM_Data +1
			cmp	#"M"
			bne	:51

			ldx	#$00			;CMD-Laufwerk.
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			rts

::51			ldx	#$ff			;Kein CMD-Laufwerk.
::52			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			rts

;*** Bytes aus FloppyROM einlesen.
:GetROM_Bytes		ldx	#> Floppy_MR
			lda	#< Floppy_MR
			jsr	SendFloppyCom		;Floppy-Befehl senden.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			lda	#$02			;Datenkanal öffnen.
			jsr	$ffa8
			jsr	$ffae
			lda	curDrive
			jsr	$ffb4

			lda	#$ff
			jsr	$ff96
			ldy	#$00
::51			jsr	$ffa5			;Byte über ser. Bus einlesen.
			sta	($8d),y
			iny
			cpy	#$02
			bcc	:51
			jsr	$ffab			;Datenkanal schließen.
			ldx	#$00
::52			rts

;*** befehl zum einlesen von Floppy-Bytes.
:Floppy_MR		b "M-R"
:FloppyROM_L		b $00
:FloppyROM_H		b $00

;*** FurboDOS-Routine.
:TurboDOS_1581		d "obj.Turbo81"

;*** Variablen.
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
:StopTurboByte		b $00
:Flag_GetPutBAM		b $00
:SwapByteBuf		b $00
:RepeatFunction		b $00
:ErrorCode		b $00
			b $00
:FloppyROM_Data		s $02
:BlkAllocMode		b $00
:Flag_BorderBlock	b $00
			b $00
			b $00
			b $00
			b $00
			b $00
