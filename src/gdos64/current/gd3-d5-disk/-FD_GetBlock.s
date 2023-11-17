; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	diskBlkBuf_r4

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		lda	#$02
			b $2c
:xReadBlock		lda	#$00
			sta	d1L

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

			bit	curType			;Shadow1541 aktiv ?
			bvc	:51			;Nein, weiter...
			jsr	IsSekInShadowRAM	;Sektor in RAM gespeichert ?
			bne	:53			; => Ja, weiter...

::51			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::loop			jsr	sendFComU1		;Block lesen.
			txa				;Fehler?
			bne	:retry			; => Ja, wiederholen.

			tya				;Wiederholungszähler speichern.
			pha

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L			;Zeiger auf Daten an
			ldx	r4H			;GET-Routine übergeben.
			ldy	d1L
			jsr	getDataBytes		;Datenbytes einlesen.

::next			pla				;Wiederholungszähler einlesen.
			tay

			txa
			beq	:exit

::retry			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

::exit			pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			bne	:53			; => Fehler, Ende...

			bit	curType			;Shadow-Laufwerk?
			bvc	:53			; => Nein, weiter...
			jsr	SaveSekInRAM		;Sektor in Shadow-RAM speichern.
			txa

::53			tax

			ldy	#$00			;Zeiger auf erstes Byte.

:exitRdBlock		rts
endif

;******************************************************************************
::tmp1 = C_71!FD_41!FD_71!HD_41!HD_71
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	diskBlkBuf_r4

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		lda	#$02
			b $2c
:xReadBlock		lda	#$00
			sta	d1L

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::loop			jsr	sendFComU1		;Block lesen.
			txa				;Fehler?
			bne	:retry			; => Ja, Abbruch...

			tya				;Wiederholungszähler speichern.
			pha

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L			;Zeiger auf Daten an
			ldx	r4H			;GET-Routine übergeben.
			ldy	d1L
			jsr	getDataBytes		;Datenbytes einlesen.

::next			pla				;Wiederholungszähler einlesen.
			tay

			txa
			beq	:exit

::retry			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

::exit			pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			tax

			ldy	#$00			;Zeiger auf erstes Byte.

:exitRdBlock		rts
endif

;******************************************************************************
::tmp2 = C_81!FD_81!FD_NM!HD_81!HD_NM!IEC_NM!S2I_NM
if :tmp2!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	diskBlkBuf_r4

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:51			; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.
::51			rts				;Ende...

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		lda	#$02
			b $2c
:xReadBlock		lda	#$00
			sta	d1L

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::loop			jsr	sendFComU1		;Block lesen.
			txa				;Fehler?
			bne	:retry			; => Ja, Abbruch...

			tya				;Wiederholungszähler speichern.
			pha

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L			;Zeiger auf Daten an
			ldx	r4H			;GET-Routine übergeben.
			ldy	d1L
			jsr	getDataBytes		;Datenbytes einlesen.

::next			pla				;Wiederholungszähler einlesen.
			tay

			txa
			beq	:exit

::retry			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

::exit			pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			tax
			bne	exitRdBlock

::fixDskNam		lda	d1L
			bne	:skip

			jsr	SwapDskNamData		;Diskettenname nach GEOS.

::skip			ldy	#$00			;Zeiger auf erstes Byte.

:exitRdBlock		rts
endif
