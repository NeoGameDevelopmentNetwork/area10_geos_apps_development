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
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	diskBlkBuf_r4

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

			jsr	IsSekInRAM_OK
			bcc	exitWrBlock

::51			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L
			ldx	r4H
			jsr	putDataBytes		;Datenbytes senden.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::loop			jsr	sendFComU2		;Block schreiben.
			txa				;Fehler?
			beq	:exit			; => Ja, wiederholen.

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

::exit			pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			tax
			bne	exitWrBlock		; => Fehler, Ende...

			bit	curType			;Shadow-Laufwerk?
			bvc	exitWrBlock		; => Nein, weiter...
			jsr	SaveSekInRAM		;Shadow-RAM aktualisieren.

:exitWrBlock		rts
endif

;******************************************************************************
::tmp1a = C_71!C_81!IEC_NM!S2I_NM
::tmp1b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp1 = :tmp1a!:tmp1b
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	diskBlkBuf_r4

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L
			ldx	r4H
			jsr	putDataBytes		;Datenbytes senden.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::loop			jsr	sendFComU2		;Block schreiben.
			txa				;Fehler?
			beq	:exit			; => Ja, wiederholen.

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

::exit			pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			tax

:exitWrBlock		rts
endif
