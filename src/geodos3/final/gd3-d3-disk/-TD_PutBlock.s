; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O abschalten.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

			jsr	IsSekInRAM_OK
			bcc	exitWrBlock

::loop			ldx	#> TD_WrSekData
			lda	#< TD_WrSekData
			jsr	xTurboRoutSet_r1
			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;SEND-Routine übergeben.
			ldy	#$00
			jsr	Turbo_PutInitByt
			jsr	xGetDiskError		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:updRAMBuf		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitWrBlock		; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal schreiben.
;			bcc	exitWrBlock		;Wird durch BEQ bereits abgefangen.

::updRAMBuf		bit	curType			;Shadow-Laufwerk?
			bvc	exitWrBlock		; => Nein, weiter...

			jsr	SaveSekInRAM		;Shadow-RAM aktualisieren.

:exitWrBlock		rts
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...
			jsr	xVerWriteBlock		;Sektor vergleichen.
::err			jmp	DoneWithIO		;I/O abschalten.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

::loop			jsr	Turbo_PutBlock
			jsr	Turbo_PutBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	exitWrBlock		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitWrBlock		; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal schreiben.
;			bcc	exitWrBlock		;Wird durch BEQ bereits abgefangen.

:exitWrBlock		rts
endif

;******************************************************************************
::tmp2 = FD_41!FD_71!HD_41!HD_71
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O abschalten.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

::loop			ldx	#> TD_WrSekData
			lda	#< TD_WrSekData
			jsr	xTurboRoutSet_r1

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;SEND-Routine übergeben.
			ldy	#$00
			jsr	Turbo_PutBytes		;256 Byte an Floppy senden.

			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	exitWrBlock		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitWrBlock		; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal schreiben.
;			bcc	exitWrBlock		;Wird durch BEQ bereits abgefangen.

:exitWrBlock		rts
endif

;******************************************************************************
::tmp3 = C_81!FD_81!FD_NM!HD_81!HD_NM!IEC_NM!S2I_NM
if :tmp3!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O abschalten.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

			jsr	SwapDskNamData		;Diskname zurück nach 1581/Native.

::loop			ldx	#> TD_WrSekData
			lda	#< TD_WrSekData
			jsr	xTurboRoutSet_r1

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;SEND-Routine übergeben.
			ldy	#$00
			jsr	Turbo_PutBytes		;256 Byte an Floppy senden.

			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:exit			; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal schreiben.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

;--- Hinweis:
;Diskname auch bei Fehler zurücktauschen!
::exit			jsr	SwapDskNamData		;Diskname nach GEOS.

:exitWrBlock		rts
endif

;******************************************************************************
::tmp4 = RD_41!RD_71
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	xDsk_SekWrite		;Sektor auf Diskette schreiben.

			plp				;IRQ-Status zurücksetzen.

			txa
::51			rts
endif

;******************************************************************************
::tmp5 = RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp5!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	SwapDskNamData		;Diskname zurück nach 1581/Native.

			jsr	xDsk_SekWrite		;Sektor auf Diskette schreiben.

			jsr	SwapDskNamData		;Diskname nach GEOS.

			plp				;IRQ-Status zurücksetzen.

			txa
::51			rts
endif

;******************************************************************************
::tmp6 = RL_41!RL_71
if :tmp6!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock
:xWriteBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	RL_DataCheck		;RAMLink-Daten überprüfen.
			txa				;Partitionsfehler?
			bne	:51			; => Ja, Abbruch...

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			PushB	r3H			;Register ":r3H" zwischenspeichern.
			lda	RL_PartNr		;Partitionsadresse setzen.
			sta	r3H
			jsr	xDsk_SekWrite		;Sektor auf Diskette schreiben.
			PopB	r3H			;Register ":r3H" zurücksetzen.

::51			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif

;******************************************************************************
::tmp7 = RL_81!RL_NM
if :tmp7!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock
:xWriteBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	RL_DataCheck		;RAMLink-Daten überprüfen.
			txa				;Partitionsfehler?
			bne	:51			; => Ja, Abbruch...

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			jsr	SwapDskNamData		;Diskname zurück nach 1581/Native.

			PushB	r3H			;Register ":r3" retten.
			lda	RL_PartNr		;Partitionsadresse setzen.
			sta	r3H
			jsr	xDsk_SekWrite		;Sektor auf Diskette schreiben.
			PopB	r3H			;Register ":r3" zurücksetzen.

			jsr	SwapDskNamData		;Diskname nach GEOS.

::51			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif

;******************************************************************************
::tmp8 = HD_81_PP!HD_NM_PP
if :tmp8!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O abschalten.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

			jsr	SwapDskNamData		;Diskname zurück nach 1581/Native.

			ldx	#$01			;TurboDOS-Befehl: Block schreiben.
			jsr	TurboRoutine1

			jsr	SwapDskNamData		;Diskname nach GEOS.

			ldx	ErrorCode
:exitWrBlock		rts
endif

;******************************************************************************
::tmp9 = HD_41_PP!HD_71_PP
if :tmp9!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitWrBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O abschalten.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitWrBlock		;Fehler? => Ja, Abbruch...

			ldx	#$01			;TurboDOS-Befehl: Block schreiben.
			jsr	TurboRoutine1

			ldx	ErrorCode
:exitWrBlock		rts
endif
