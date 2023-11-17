; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71!C_81!IEC_NM!S2I_NM
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Diskette aktivieren.
:xLogNewDisk		jsr	xEnterTurbo
;			txa
			bne	:err
			stx	RepeatFunction

			jsr	InitForIO		;I/O aktivieren.

::loop			ldx	#> :com_InitDisk	;NewDisk ausführen.
			lda	#< :com_InitDisk
			ldy	#$03
			jsr	SendComVLen
			bne	:retry			;Fehler => Ja, nochmal versuchen.

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	xGetDiskError		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:ok			; => Nein, Ende...

::retry			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;Sektor nochmal lesen.
;			bcc	:exit			;Wird durch BEQ bereits abgefangen.

::ok			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#NO_ERROR

::exit			jsr	DoneWithIO		;I/O abschalten.

::err			rts

::com_InitDisk		b "I0:"
endif

;******************************************************************************
::tmp1 = FD_41!FD_71!FD_81!FD_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Diskette aktivieren.
:xLogNewDisk		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	InitForIO		;I/O aktivieren.

			jsr	FCom_InitDisk		;NewDisk ausführen.

			jsr	DoneWithIO		;I/O abschalten.

::err			rts
endif
