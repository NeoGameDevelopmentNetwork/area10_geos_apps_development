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
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk		bit	curType			;Shadow1541 ?
			bvc	:1			; => Nein, weiter...

			jsr	InitShadowRAM		;ShadowRAM löschen.
::1
endif

;******************************************************************************
::tmp1 = C_71!C_81!PC_DOS!IEC_NM!S2I_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk
endif

;******************************************************************************
::tmp2 = C_41!C_71!C_81!PC_DOS!IEC_NM!S2I_NM
if :tmp2!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
			jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...
			stx	RepeatFunction

			jsr	InitForIO		;I/O-Bereich einblenden.

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

::exit			jsr	DoneWithIO		;I/O-Bereich ausblenden.

::err			rts

::com_InitDisk		b "I0:"
endif

;******************************************************************************
::tmp3 = FD_41!FD_71!FD_81!FD_NM
if :tmp3!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Diskette aktivieren.
:xNewDisk		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	FCom_InitDisk		;NewDisk ausführen.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

::err			rts
endif

;******************************************************************************
::tmp4 = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp4!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk = xEnterTurbo
endif
