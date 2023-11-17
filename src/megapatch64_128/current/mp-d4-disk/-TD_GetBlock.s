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
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink
:xReadBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

			bit	curType			;Shadow1541 aktiv ?
			bvc	:loop			;Nein, weiter...
			jsr	IsSekInShadowRAM	;Sektor in RAM gespeichert ?
			bne	:exit			;Ja, weiter...

::loop			ldx	#> TD_VerSekData
			lda	#< TD_VerSekData
			jsr	xTurboRoutSet_r1
			ldx	#> TD_RdSekData
			lda	#< TD_RdSekData
			jsr	xTurboRoutine
			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET-Routine übergeben.
			ldy	#$00
			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:updRAMBuf		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitRdBlock		; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	exitRdBlock		;Wird durch BEQ bereits abgefangen.

::updRAMBuf		bit	curType			;Shadow-Laufwerk?
			bvc	:exit			; => Nein, weiter...

			jsr	SaveSekInRAM		;Sektor in RAM speichern.

::exit			ldy	#$00			;Zeiger auf erstes Byte.
:exitRdBlock		rts
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink
:xReadBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

::loop			jsr	Turbo_GetBlock
			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:exit			; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitRdBlock		; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	exitRdBlock		;Wird durch BEQ bereits abgefangen.

::exit			ldy	#$00			;Zeiger auf erstes Byte.

:exitRdBlock		rts
endif

;******************************************************************************
::tmp2 = FD_41!FD_71!HD_41!HD_71
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

;*** Einsprung aus ":ReadLink".
:GetLinkBytes		ldx	#> TD_GetSektor
			lda	#< TD_GetSektor
			jsr	xTurboRoutSet_r1
			ldx	#> TD_RdSekData
			lda	#< TD_RdSekData
			jsr	xTurboRoutine

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET-Routine übergeben.

			ldy	#$00
			lda	r1L
			bpl	:get			; => ReadBlock
			ldy	#$02			; => ReadLink
::get			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:exit			; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitRdBlock		; => Ja, Abbruch...
			bcs	GetLinkBytes		;Sektor nochmal lesen.
;			bcc	exitRdBlock		;Wird durch BEQ bereits abgefangen.

::exit			ldy	#$00			;Zeiger auf erstes Byte.

:exitRdBlock		rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			lda	r1L			;Flag für LinkBytes setzen.
			pha
			ora	#%10000000
			sta	r1L
			jsr	GetLinkBytes		;LinkBytes einlesen
			pla
			sta	r1L			;Flag für LinkBytes löschen.

::51			rts
endif

;******************************************************************************
::tmp3 = C_81!FD_81!FD_NM!HD_81
if :tmp3!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

;*** Einsprung aus ":ReadLink".
:GetLinkBytes		ldx	#> TD_GetSektor
			lda	#< TD_GetSektor
			jsr	xTurboRoutSet_r1
			ldx	#> TD_RdSekData
			lda	#< TD_RdSekData
			jsr	xTurboRoutine

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET-Routine übergeben.

			ldy	#$00
			lda	r1L
			bpl	:get			; => ReadBlock
			ldy	#$02			; => ReadLink
::get			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:fixDskNam		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitRdBlock		; => Ja, Abbruch...
			bcs	GetLinkBytes		;Sektor nochmal lesen.
;			bcc	exitRdBlock		;Wird durch BEQ bereits abgefangen.

::fixDskNam		bit	r1L			;ReadLink/ReadBlock?
			bmi	:exit			; => ReadLink

			jsr	SwapDskNamData		;Diskname korrigieren.

::exit			ldy	#$00			;Zeiger auf erstes Byte.

:exitRdBlock		rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			lda	r1L			;Flag für LinkBytes setzen.
			ora	#$80
			sta	r1L
			jsr	GetLinkBytes		;LinkBytes einlesen
			lda	r1L
			and	#$7f			;Flag für LinkBytes löschen.
			sta	r1L

::51			rts
endif

;******************************************************************************
::tmp4 = HD_NM!IEC_NM
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock
;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
;--- Ergänzung: 15.10.18/M.Kanet
;Da HD und SD2IEC/DNP mehr als 128 Spuren haben können kann ReadLink nicht
;verwendet werden. Hierbei wird Bit#7 in der Spur-Adresse gesetzt um dem
;TurboDOS mitzuteilen das nur 2 Bytes zu senden sind.
;Der HD-TurboDOS-Code wird durch InitTD entsprechend gepatcht und der IECBUS-
;Treiber nutzt ein bereits angepasstes TurboDOS.
:xReadLink		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

;*** Einsprung aus ":ReadLink".
:GetLinkBytes		ldx	#> TD_GetSektor
			lda	#< TD_GetSektor
			jsr	xTurboRoutSet_r1
			ldx	#> TD_RdSekData
			lda	#< TD_RdSekData
			jsr	xTurboRoutine

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET-Routine übergeben.

			ldy	#$00
			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:fixDskNam		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitRdBlock		; => Ja, Abbruch...
			bcs	GetLinkBytes		;Sektor nochmal lesen.
;			bcc	exitRdBlock		;Wird durch BEQ bereits abgefangen.

::fixDskNam		jsr	SwapDskNamData		;Diskettenname nach GEOS.

;			ldy	#$00			;Zeiger auf erstes Byte.
							;(Durch ":SwapDskNamData" gesetzt)
:exitRdBlock		rts
endif

;******************************************************************************
::tmp5 = RL_41!RL_71
if :tmp5!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock
:xReadBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	RL_DataCheck		;RAMLink-Daten überprüfen.
			txa				;Partitionsfehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:err			;Fehler? => Ja, Abbruch...

			PushB	r3H			;Register ":r3H" zwischenspeichern.
			lda	RL_PartNr		;Partitionsadresse setzen.
			sta	r3H
			jsr	xDsk_SekRead		;Sektor von Diskette lesen.
			PopB	r3H			;Register ":r3H" zurücksetzen.

			ldy	#$00			;Zeiger auf erstes Byte.

::err			plp				;IRQ-Status zurücksetzen.
			txa
			rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	RL_DataCheck		;RAMLink-Daten überprüfen.
			txa				;Partitionsfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			jsr	Save_RegData		;Register ":r0" bis ":r4" speichern.

			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.

			LoadW	r2,$0002		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			ldy	#%10010001
			jsr	DoRAMOp_DISK		;FetchRAM/Disketreiber ausführen.

			jsr	Load_RegData		;Register ":r0" bis ":r4" einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::51			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif

;******************************************************************************
::tmp6 = RL_81!RL_NM
if :tmp6!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock
:xReadBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	RL_DataCheck		;RAMLink-Daten überprüfen.
			txa				;Partitionsfehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:err			;Fehler? => Ja, Abbruch...

			PushB	r3H			;Register ":r3" retten.
			lda	RL_PartNr		;Partitionsadresse setzen.
			sta	r3H
			jsr	xDsk_SekRead		;Sektor von Diskette lesen.
			PopB	r3H			;Register ":r3" zurücksetzen.

			jsr	SwapDskNamData		;Diskettenname nach GEOS.

;			ldy	#$00			;Zeiger auf erstes Byte.
							;(Durch ":SwapDskNamData" gesetzt)
::err			plp				;IRQ-Status zurücksetzen.
			txa
			rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	RL_DataCheck		;RAMLink-Daten überprüfen.
			txa				;Partitionsfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	TestTrSe_ADDR		;Track/Sektor-Adresse testen.
			bcc	:51			;Fehler, Abbrch...

			jsr	Save_RegData		;Register ":r0" bis ":r4" speichern.

			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.

			LoadW	r2,$0002		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			ldy	#%10010001
			jsr	DoRAMOp_DISK		;FetchRAM/Disketreiber ausführen.

			jsr	Load_RegData		;Register ":r0" bis ":r4" einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::51			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif

;******************************************************************************
::tmp7 = RD_41!RD_71
if :tmp7!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock
:xReadBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:err			;Fehler? => Ja, Abbruch...

			jsr	xDsk_SekRead		;Sektor von Diskette lesen.

			ldy	#$00			;Zeiger auf erstes Byte.

::err			plp				;IRQ-Status zurücksetzen.
			txa
			rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			jsr	Save_RegData		;Register ":r0" bis ":r4" speichern.

			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.

			LoadW	r2,$0002		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	FetchRAM		;Daten aus GEOS-DACC einlesen.

			jsr	Load_RegData		;Register ":r0" bis ":r4" einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::51			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif

;******************************************************************************
::tmp8 = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp8!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock
:xReadBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:err			;Fehler? => Ja, Abbruch...

			jsr	xDsk_SekRead		;Sektor von Diskette lesen.

			jsr	SwapDskNamData		;Diskettenname nach GEOS.

;			ldy	#$00			;Zeiger auf erstes Byte.
							;(Durch ":SwapDskNamData" gesetzt)
::err			plp				;IRQ-Status zurücksetzen.
			txa
			rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Fehler? => Ja, Abbruch...

			jsr	Save_RegData		;Register ":r0" bis ":r4" speichern.

			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.

			LoadW	r2,$0002		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			ldy	#%10010001
			jsr	DoRAMOp_DISK		;FetchRAM/Disktreiber ausführen.

			jsr	Load_RegData		;Register ":r0" bis ":r4" einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::51			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif

;******************************************************************************
::tmp9 = HD_41_PP!HD_71_PP
if :tmp9!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock		lda	#$00
			b $2c

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		lda	#$02
			sta	Flag_RdDataMode

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

			ldx	#$02
			lda	Flag_RdDataMode
			beq	:1
			inx
::1			jsr	TurboRoutine1

			ldy	#$00			;Zeiger auf erstes Byte.

			ldx	ErrorCode
:exitRdBlock		rts

:Flag_RdDataMode	b $00
endif

;******************************************************************************
::tmp10 = HD_81_PP!HD_NM_PP
if :tmp10!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock		lda	#$00
			b $2c

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		lda	#$02
			sta	Flag_RdDataMode

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

			ldx	#$02
			lda	Flag_RdDataMode
			beq	:1			; => ReadBlock
			inx				; => ReadLink
::1			jsr	TurboRoutine1

			jsr	SwapDskNamData		;Diskettenname nach GEOS.

;			ldy	#$00			;Zeiger auf erstes Byte.
							;(Durch ":SwapDskNamData" gesetzt)
			ldx	ErrorCode
:exitRdBlock		rts

:Flag_RdDataMode	b $00
endif

;******************************************************************************
::tmp11 = S2I_NM
if :tmp11!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	exitRdBlock		;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink
:xReadBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	exitRdBlock		;Fehler? => Ja, Abbruch...

::loop			jsr	Turbo_GetBlock
			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:fixDskNam		; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	exitRdBlock		; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	exitRdBlock		;Wird durch BEQ bereits abgefangen.

::fixDskNam		jsr	SwapDskNamData		;Diskettenname nach GEOS.

;			ldy	#$00			;Zeiger auf erstes Byte.
							;(Durch ":SwapDskNamData" gesetzt)
:exitRdBlock		rts
endif

;******************************************************************************
::tmp12 = RD_81!RD_NM
if :tmp12!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock
:xReadBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:err			;Fehler? => Ja, Abbruch...

			jsr	xDsk_SekRead		;Sektor von Diskette lesen.

			jsr	SwapDskNamData		;Diskettenname nach GEOS.

;			ldy	#$00			;Zeiger auf erstes Byte.
							;(Durch ":SwapDskNamData" gesetzt)
::err			plp				;IRQ-Status zurücksetzen.
			txa
			rts

;*** Link-Bytes eines Sektors einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xReadLink		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:err			;Fehler? => Ja, Abbruch...

			jsr	Save_RegData		;Register ":r0" bis ":r4" speichern.

			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.

			LoadW	r2,$0002		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	FetchRAM		;Daten aus GEOS-DACC einlesen.

			jsr	Load_RegData		;Register ":r0" bis ":r4" einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::err			plp				;IRQ-Status zurücksetzen.
			txa
			rts
endif
