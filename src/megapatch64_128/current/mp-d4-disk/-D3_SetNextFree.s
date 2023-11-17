; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!FD_41!HD_41!HD_41_PP
if :tmp0 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		php
			sei

			lda	r3H			;Zeiger auf nächsten Sektor
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
			jsr	GetMaxSekOnTrack	;Max. Anzahl Sektoren einlesen und
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

::56			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			ldx	#NO_ERROR		;Kein Fehler...
			b $2c
::57			ldx	#INSUFF_SPACE		;Fehler: "Diskette voll".
			plp
			rts

;*** Auf freien Sektor testen.
:TestCurSekFree		lda	r6H			;Aktuellen Sektor einlesen.
::51			cmp	r7L			;Ist Sektor gültig ?
			bcc	:52			;Ja, weiter...
;			sec				;Sektoradresse zurücksetzen.
			sbc	r7L
			jmp	:51

::52			sta	r6H			;Neue Sektor-Adresse speichern.
			jmp	xAllocateBlock
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette (41/71) belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		php
			sei

			lda	r3H			;Zeiger auf nächsten Sektor
			clc				;durch "interleave" berechnen.
			adc	interleave
			sta	r6H
			lda	r3L			;Zeiger auf aktuellen Track setzen.
			sta	r6L

			cmp	#$12
			beq	:52
			cmp	#$35
			beq	:52
::51			lda	r6L
			cmp	#$12
			beq	:56
			cmp	#$35
			beq	:56

::52			cmp	#$24			;BAM-Bit für Track #36 - #70 testen.
			bcc	:53
			clc
			adc	#$b9			;Zeiger auf BAM berechnen.
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			bne	:54			;Sektor auf Track frei, weiter...
			beq	:56			;Track voll, weitersuchen.

::53			asl				;BAM-Bit für Track #1 - #35 testen.
			asl
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			beq	:56			;Track voll, weitersuchen.

::54			lda	r6L
			jsr	GetMaxSekOnTrack	;Max. Anzahl Sektoren einlesen und
			sta	r7L			;zwischenspeichern.
			tay				;Anzahl Sektoren als Zähler setzen.
::55			jsr	TestCurSekFree		;Sektor frei ?
			beq	:61			;Ja, weiter...
			inc	r6H			;Sektor-Zähler +1.
			dey				;Alle Sektoren geprüft ?
			bne	:55			;Nein, weiter..

::56			bit	curDirHead +3
			bpl	:58

			lda	r6L			;Track-Adresse einlesen.
			cmp	#$24			;Track #36 überschritten ?
			bcs	:57			;Ja, weiter...
			clc
			adc	#$23
			sta	r6L
			bne	:60

::57			sec
			sbc	#$22			;Neue Track-Adresse definieren.
			sta	r6L
			bne	:59
::58			inc	r6L
			lda	r6L
::59			cmp	#$24			;Gesamte Diskette nach freiem Sektor
			bcs	:62			;durchsucht ? Ja, Fehler "DISK FULL"

::60			sec
			sbc	r3L
			sta	r6H
			asl
			adc	#$04
			adc	interleave
			sta	r6H
			clv
			bvc	:51			;Nächsten freien Sektor suchen.

::61			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			ldx	#NO_ERROR		;Kein Fehler...
			b $2c
::62			ldx	#INSUFF_SPACE		;Fehler: "Diskette voll".
			plp
			rts

;*** Auf freien Sektor testen.
:TestCurSekFree		lda	r6H			;Aktuellen Sektor einlesen.
::51			cmp	r7L			;Ist Sektor gültig ?
			bcc	:52			;Ja, weiter...
;			sec				;Sektoradresse zurücksetzen.
			sbc	r7L
			jmp	:51

::52			sta	r6H			;Neue Sektor-Adresse speichern.
			jmp	xAllocateBlock
endif

;******************************************************************************
::tmp2 = FD_71!HD_71!HD_71_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		php
			sei

			lda	r3H			;Zeiger auf nächsten Sektor
			clc				;durch "interleave" berechnen.
			adc	interleave
			sta	r6H
			lda	r3L			;Zeiger auf aktuellen Track setzen.
			sta	r6L

			cmp	#$12
			beq	:52
			cmp	#$35
			beq	:52
::51			lda	r6L
			cmp	#$12
			beq	:56
			cmp	#$35
			beq	:56

::52			cmp	#$24			;BAM-Bit für Track #36 - #70 testen.
			bcc	:53
			clc
			adc	#$b9			;Zeiger auf BAM berechnen.
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			bne	:54			;Sektor auf Track frei, weiter...
			beq	:56			;Track voll, weitersuchen.

::53			asl				;BAM-Bit für Track #1 - #35 testen.
			asl
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			beq	:56			;Track voll, weitersuchen.

::54			lda	r6L
			jsr	GetMaxSekOnTrack	;Max. Anzahl Sektoren einlesen und
			sta	r7L			;zwischenspeichern.
			tay				;Anzahl Sektoren als Zähler setzen.
::55			jsr	TestCurSekFree		;Sektor frei ?
			beq	:61			;Ja, weiter...

			inc	r6H			;Sektor-Zähler +1.
			dey				;Alle Sektoren geprüft ?
			bne	:55			;Nein, weiter..

::56			inc	r6L
			lda	r6L
::59			cmp	#70 +1			;Gesamte Diskette nach freiem Sektor
			bcs	:62			;durchsucht ? Ja, Fehler "DISK FULL"

::60			lda	#$00
			sta	r6H
			jmp	:51			;Nächsten freien Sektor suchen.

::61			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			ldx	#NO_ERROR		;Kein Fehler...
			b $2c
::62			ldx	#INSUFF_SPACE		;Fehler: "Diskette voll".
			plp
			rts

;*** Auf freien Sektor testen.
:TestCurSekFree		lda	r6H			;Aktuellen Sektor einlesen.
::51			cmp	r7L			;Ist Sektor gültig ?
			bcc	:52			;Ja, weiter...
;			sec				;Sektoradresse zurücksetzen.
			sbc	r7L
			jmp	:51

::52			sta	r6H			;Neue Sektor-Adresse speichern.
			jmp	xAllocateBlock
endif

;******************************************************************************
::tmp3 = C_81!FD_81!HD_81!HD_81_PP
if :tmp3 = TRUE
;******************************************************************************
;*** Nächsten freien Sektor auf Diskette belegen.
;    Zuerst auf Tracks #39-#1 abwärts suchen.
;    Dann von Track #41 bis #80 aufwärts suchen.
:xSetNextFree		php
			sei

			lda	r3H
			sta	r6H
			lda	r3L
			cmp	#40			;Sektor für Verzeichnis belegen ?
			beq	:51			;Ja, weiter...
			lda	#39			;Startwert für Sektorsuche...
::51			sta	r6L

;*** Nächsten freien Sektor suchen.
:FindNextFree		jsr	GetBAM_Offset		;Zeiger auf BAM berechnen.
			tay				;":dir3Head" ?
			bne	:51			;Ja, weiter...

			lda	dir2Head +16,x
			jmp	:52
::51			lda	dir3Head +16,x
::52			bne	GetSekOnTrack

;*** Track mit freiem Sektor suchen.
:FindNextTrack		lda	r6L			;Aktuellen Track einlesen.
			cmp	#40			;Suche nach Verzeichnis-Sektor ?
			bne	:52			;Nein, weiter...
::51			plp
			ldx	#INSUFF_SPACE		;Fehler, Diskette voll!
			rts

::52			cmp	#41			;Track #41-#80 ?
			bcs	:53			;Ja, weiter...
			dec	r6L			;Zeiger auf letzten Track setzen.
			bne	FindNextFree		;Ende erreicht ? Nein, weiter...
			lda	#40			;Zeiger auf Track #41-80 setzen.
			sta	r6L
::53			inc	r6L			;Zeiger auf nächsten track.
			lda	r6L
			cmp	#81			;Track #81 erreicht ?
			bcc	FindNextFree		;Nein, weiter...
			bcs	:51			;Fehler, Diskette voll..

;*** Freien Sektor auf Track suchen.
:GetSekOnTrack		txa
			clc
			adc	#$06 -1			;Zeiger auf letztes BAM-Byte für
			sta	:54  +1			;Track und zwischenspeichern.

			lda	#$00			;Zeiger auf ersten Sektor.
			sta	r6H
::51			inx				;Zeiger auf nächstes BAM-Byte.
			tya				;":dir3Head" ?
			bne	:52			;Ja, weiter...
			lda	dir2Head +16,x
			jmp	:53
::52			lda	dir3Head +16,x
::53			bne	:55			;Sektor gefunden ? => Ja, weiter...

			AddVB	8,r6H			;Zeiger auf nächsten Sektor.
::54			cpx	#$ff			;Alle BAM-Bytes geprüft ?
			bne	:51			;Nein, weiter...
			plp
			ldx	#INSUFF_SPACE		;Fehler, Diskette voll...
			rts

::55			lsr				;Zeiger auf Sektor berechnen.
			bcs	:56			;BAM-Byte solange verschieben bis
			inc	r6H			;#1-BIT gefunden => freier Sektor
			bne	:55			;auf Track in BAM-Byte gefunden.
::56			jsr	xAllocateBlock		;Block auf Diskette belegen.
			txa				;Diskettenfehler ?
			bne	:57			;Ja, Abbruch...

			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::57			plp
			rts				;Ende...
endif

;******************************************************************************
::tmp4 = RL_41!RD_41
if :tmp4 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			MoveB	r3L,r6L			;Sektor-Adresse in
			MoveB	r3H,r6H			;Zwischenspeicher kopieren.

::51			lda	r6L			;Zeiger auf BAM-Daten berechnen.
			asl				;BAM-Bit für Track #1 - #35 testen.
			asl
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			beq	:53			;Track voll, weitersuchen.

			lda	r6L
			jsr	GetMaxSekOnTrack
			sta	r7L
			tay
::52			jsr	TestCurSekFree		;Freien Sektor auf Track suchen.
			txa				;Sektor gefunden ?
			beq	:56			;Ja, weiter...
			inc	r6H
			dey
			bne	:52

::53			ldx	r6L			;Aktuellen Track einlesen.
			cpx	#18			;Sektor in Verzeichnis suchen ?
			beq	:55			;Ja, kein freier Sektor, Abbruch...
			inx				;Zeiger auf nächsten Track.
			cpx	#18			;Verzeichnis erreicht ?
			bne	:54			;Nein, weiter...
			inx				;Zeiger auf nächsten Track.
::54			cpx	#36			;Alle Tracks durchsucht ?
			beq	:55			;Ja, Abbruch...
			stx	r6L			;Zeiger auf nächsten Track.
			jmp	:51			;Weitersuchen.

::55			plp				;IRQ-Status zurücksetzen.
			ldx	#INSUFF_SPACE		;Fehler: "Diskette voll"...
			rts

::56			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			plp				;IRQ-Status zurücksetzen.
			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
			rts

;*** Auf freien Sektor testen.
:TestCurSekFree		lda	r6H			;Aktuellen Sektor einlesen.
::51			cmp	r7L			;Ist Sektor gültig ?
			bcc	:52			;Ja, weiter...
;			sec				;Sektoradresse zurücksetzen.
			sbc	r7L
			jmp	:51

::52			sta	r6H			;Neue Sektor-Adresse speichern.
			jmp	xAllocateBlock
endif

;******************************************************************************
::tmp5 = RL_71!RD_71
if :tmp5 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			MoveB	r3L,r6L			;Sektor-Adresse in
			MoveB	r3H,r6H			;Zwischenspeicher kopieren.

::51			CmpBI	r6L,36
			bcs	:52
			asl				;Zeiger auf BAM-Daten berechnen.
			asl
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			beq	:55			;Track voll, weitersuchen.
			bne	:53

::52			clc
			adc	#$b9
			tax
			lda	curDirHead,x		;Sektorzähler einlesen.
			beq	:55			;Track voll, weitersuchen.

::53			lda	r6L
			jsr	GetMaxSekOnTrack
			sta	r7L
			tay
::54			jsr	TestCurSekFree		;Freien Sektor auf Track suchen.
			txa				;Sektor gefunden ?
			beq	:59			;Ja, weiter...
			inc	r6H
			dey
			bne	:54

::55			ldx	r6L			;Aktuellen Track einlesen.
			cpx	#18			;Sektor in Verzeichnis suchen ?
			beq	:58			;Ja, kein freier Sektor, Abbruch...
			inx				;Zeiger auf nächsten Track.
			cpx	#18			;Verzeichnis erreicht ?
			beq	:56			;Nein, weiter...
			cpx	#53
			bne	:57
::56			inx				;Zeiger auf nächsten Track.
::57			cpx	#71			;Alle Tracks durchsucht ?
			beq	:58			;Ja, Abbruch...
			stx	r6L			;Zeiger auf nächsten Track.
			jmp	:51			;Weitersuchen.

::58			plp
			ldx	#INSUFF_SPACE		;Fehler: "Diskette voll"...
			rts

::59			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			plp
			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
			rts

;*** Auf freien Sektor testen.
:TestCurSekFree		lda	r6H			;Aktuellen Sektor einlesen.
::51			cmp	r7L			;Ist Sektor gültig ?
			bcc	:52			;Ja, weiter...
;			sec				;Sektoradresse zurücksetzen.
			sbc	r7L
			jmp	:51

::52			sta	r6H			;Neue Sektor-Adresse speichern.
			jmp	xAllocateBlock
endif

;******************************************************************************
::tmp6 = RL_81!RD_81
if :tmp6 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			MoveB	r3L,r6L			;Sektor-Adresse in
			MoveB	r3H,r6H			;Zwischenspeicher kopieren.

::51			lda	r6L			;Zeiger auf BAM-Daten berechnen.
			cmp	#41
			bcc	:52
;			sec
			sbc	#40

::52			sec
			sbc	#$01
			asl
			sta	r7L
			asl
			clc
			adc	r7L
			tax
			lda	r6L
			cmp	#41
			bcc	:53
			lda	dir3Head +16,x		;Sektoren auf Track #41-#80 frei ?
			beq	:57			;Nein, weiter mit nächstem Track.
			bne	:55			;Ja, freien Sektor auf Track suchen.
::53			lda	dir2Head +16,x		;Sektoren auf Track #01-#40 frei ?
::54			beq	:57			;Nein, weiter mit nächstem Track.

::55			ldy	#40
::56			jsr	TestCurSekFree		;Freien Sektor auf Track suchen.
			txa				;Sektor gefunden ?
			beq	:60			;Ja, weiter...
			inc	r6H
			dey
			bne	:56

::57			ldx	r6L			;Aktuellen Track einlesen.
			cpx	#40			;Sektor in Verzeichnis suchen ?
			beq	:59			;Ja, kein freier Sektor, Abbruch...
			inx				;Zeiger auf nächsten Track.
			cpx	#40			;Verzeichnis erreicht ?
			bne	:58			;Nein, weiter...
			inx				;Zeiger auf nächsten Track.
::58			cpx	#81			;Alle Tracks durchsucht ?
			beq	:59			;Ja, Abbruch...
			stx	r6L			;Zeiger auf nächsten Track.
			jmp	:51			;Weitersuchen.

::59			plp
			ldx	#INSUFF_SPACE		;Fehler: "Diskette voll"...
			rts

::60			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			plp
			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
			rts

;*** Auf freien Sektor testen.
:TestCurSekFree		tya
			pha
			lda	r6H			;Aktuellen Sektor einlesen.
			cmp	#40			;Ist Sektor gültig ?
			bcc	:51			;Ja, weiter...
			lda	#$00 			;Sektoradresse zurücksetzen.
::51			sta	r6H			;Neue Sektor-Adresse speichern.
			jsr	xAllocateBlock
			pla
			tay
			rts
endif

;******************************************************************************
::tmp7a = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp7b = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp7  = :tmp7a!:tmp7b
if :tmp7 = TRUE
;******************************************************************************
;*** Nächsten freien Datensektor auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:xSetNextFree		lda	#Tr_1stDataSek		;Startsektor im Bereich Native-
			cmp	r3L			;Verzeichnis ?
			bne	SetNextFreeAll
			lda	#Se_1stDataSek
			cmp	r3H
			bcc	SetNextFreeAll		; => Nein, weiter...
			sta	r3H			;Ja, Datenbereich auf Tr/Se= $01/40
							;zurücksetzen.
;*** Nächsten freien Sektor (Verzeichnis/Daten) auf Diskette belegen.
;    Übergabe:		r3	= Start-Sektor für Sektorsuche.
;    Rückgabe:		r3	= Erster freier Sektor.
;    Geändert:		AKKU,xReg,yReg,r6,r7,r8H
:SetNextFreeAll		lda	LastTrOnDsk		;Letzten Track für Sektorsuche
			sta	LastSearchTr		;festlegen.
			jsr	SearchCurrent		;Suche ab aktuellem Sektor beginnen.
			cpx	#INSUFF_SPACE		;Sektor gefunden ?
			bne	exitSetNxFree		; => Kein freier Sektor, Ende.

;--- Suche ab Diskanfang.
:SearchBeginn		lda	r3L			;Starttrack als letzten Track
			sta	LastSearchTr		;für Sektorsuche festlegen.

			lda	#Tr_1stDataSek		;Zeiger auf Diskanfang.
			sta	r3L
			lda	#Se_1stDataSek
			sta	r3H

;--- Freien Sektor suchen.
:SearchCurrent		ldx	r3L
			stx	r6L			;Start-Track festlegen.
			stx	r7L

			ldy	r3H			;Zeiger auf nächsten Sektor setzen.
			iny				;Zurück auf Anfang des Tracks?
			bne	:50			; => Nein, weiter...

;--- Ergänzung: 12.09.21/M.Kanet
;Auf Track#1 nicht ab Sektor#0 suchen,
;sondern ab dem ersten Datensektor.
			cpx	#Tr_1stDataSek		;Track #1 ?
			bne	:50			; => Nein, weiter...
			ldy	#Se_1stDataSek		;Suche ab erstem Datensektor.

::50			sty	r6H			;Start-Sektor festlegen.
			sty	r7H

::51			ldx	#$03			;Track/Sektor-Adresse um 4Bit
::52			lsr	r7L			;verschieben. Track wird dadurch zum
			ror	r7H			;Zeiger auf BAM-Sektor und Sektor
			dex				;wird Zeiger auf BAM-Byte!
			bne	:52

			lda	r7L
			clc
			adc	#$02
			jsr	xGetBAMBlock		;BAM-Block einlesen.
			txa				;Diskettenfehler ?
			bne	exitSetNxFree		; => Ja, Abbruch...

			ldx	r7H
			ldy	#$1f			;Freien Sektor auf Track suchen.
::53			lda	dir2Head,x		;Sektor frei ?
			bne	:54			; => Ja, weiter...
			inx				;Weitersuchen.
			dey				;Alle Tracks/BAM-Sektor durchsucht ?
			bpl	:53			; => Nein, weiter...
			bmi	:55			; => Ja, nächster BAM-Sektor.

::54			jsr	xAllocateBlock		;Ist Sektor frei ?
			beq	:57			; => Ja, weiter...
			inc	r6H			;Alle Sektoren auf Track geprüft ?
			bne	:54			; => Nein, weiter...

::55			lda	r6L			;Zeiger auf nächsten Track.
			clc
			adc	#$01			;Max. Diskgröße (16Mb) erreicht ?
			beq	:58			; => Ja, Ende...
			cmp	LastSearchTr		;Alle Tracks durchsucht ?
			beq	:56
			bcs	:58			; => Ja, Ende...
::56			sta	r6L			;Suche auf nächstem Track
			sta	r7L			;fortsetzen.

			lda	#$00			;Suche ab Sektor #0 auf nächstem
			sta	r6H			;Track fortsetzen.
			sta	r7H
			beq	:51

::57			MoveB	r6L,r3L			;Freien Sektor in ":r3"
			MoveB	r6H,r3H			;übergeben.

			ldx	#NO_ERROR		;Flag: "Kein Fehler!".
			rts

::58			ldx	#INSUFF_SPACE		;Flag: "Diskette voll!".
:exitSetNxFree		rts
endif
