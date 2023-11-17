; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81
::tmp0b = FD_41!FD_71!FD_81!FD_NM!PC_DOS!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Floppy-Routine ohne Parameter aufrufen.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
:xTurboRoutine		stx	d0H			;Zeiger auf Routine nach d0L/d0H
			sta	d0L			;kopieren.
			ldy	#$02			;2-Byte-Befehl.
			bne	InitTurboData		;Befehl ausführen.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:xTurboRoutSet_r1	stx	d0H			;Zeiger auf Routine nach d0L/d0H
			sta	d0L			;kopieren.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		d0L/d0H  , Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:xTurboRoutine_r1	ldy	#$04			;4-Byte-Befehl.

			lda	r1H			;Parameter-Bytes in Init-Befehl
			sta	TurboParameter2 		;kopieren.
			lda	r1L
			sta	TurboParameter1

;*** Turbodaten initialisieren.
;    Übergabe:		d0L/d0H = Zeiger auf TurboRoutine.
;			yReg	 = Anzahl Bytes (Routine+Parameter)
:InitTurboData		lda	d0H			;Auszuführende Routine in
			sta	TurboRoutineH		;Init-Befehl kopieren.
			lda	d0L
			sta	TurboRoutineL

			lda	#> TurboRoutineL
			sta	d0H
			lda	#< TurboRoutineL
			sta	d0L
			jmp	Turbo_PutInitByt

:TurboRoutineL		b $00
:TurboRoutineH		b $00
:TurboParameter1	b $00
:TurboParameter2	b $00
endif

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: Getrennte Routinen für C64 und C128 da unterschiedliche
;Register zum RAM- und I/O-Umschalten verwendet werden.
;******************************************************************************
::tmp2 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Floppy-Routine aufrufen.
;xReg = $00		= TurboDOS deaktivieren
;     = $01		= Sektor schreiben
;     = $02		= Sektor lesen
;     = $03		= Linkbytes lesen
;     = $04		= Fehlerstatus abfragen.
:TurboRoutine1		lda	r4H
			sta	d0H
			lda	r4L
			sta	d0L
			b $2c
:xGetDiskError		ldx	#$04
:TurboRoutine2		stx	TurboMode

			lda	#$00			;Fehlercode löschen.
			sta	ErrorCode

			lda	PP_DOS_ROUT_L,x		;Zeiger auf auszuführende Routine
			sta	TurboRoutineL		;im TurboDOS einlesen und speichern.
			lda	PP_DOS_ROUT_H,x
			sta	TurboRoutineH

			lda	r1L			;Track und Sektor an TurboDOS
			sta	TurboParameter1		;übergeben.
			lda	r1H
			sta	TurboParameter2

			jsr	EN_SET_REC		;RL-Hardware aktivieren.

			lda	d0H			;Zeiger auf Sektorspeicher
			pha				;auf Stack retten.
			lda	d0L
			pha

			lda	#> TurboRoutineL	;TurboDOS-Routine
			sta	d0H			;ausführen.
			lda	#< TurboRoutineL
			sta	d0L
			ldy	#$04
			jsr	Turbo_PutBytes
			pla
			sta	d0L
			pla
			sta	d0H

			ldy	TurboMode		;TurboPP starten?
			beq	:4			; => Ja, Ende...

			dey				;Sektor schreiben?
			bne	:1			; => Nein, weiter...
			jsr	Turbo_PutBytes		;Sektor auf Diskette schreiben und
			jmp	:3			;Fehlerstatus abfragen.

::1			dey				;Sektor lesen?
			beq	:2			; => Ja, weiter...
			dey				;Linkbytes lesen?
			bne	:3			; => Nein, weiter...
			ldy	#$02
::2			jsr	Turbo_GetBytes		;Daten von Diskette lesen.

::3			lda	#> ErrorCode
			sta	d0H
			lda	#< ErrorCode
			sta	d0L
			ldy	#$01
			jsr	Turbo_GetBytes		;Fehlerstatus abfragen.

::4			jsr	RL_HW_DIS2		;RL-Hardware deaktivieren.

			lda	ErrorCode
			cmp	#$02
			bcc	:5
			adc	#$1d
			b $2c
::5			lda	#$00
			tax
			stx	ErrorCode
			rts
endif

;******************************************************************************
::tmp4 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** HD-Kabel-Modus wechseln.
:HD_MODE_SEND		ldx	#$98
			b $2c
:HD_MODE_RECEIVE	ldx	#$88
			lda	$df41
			pha
			lda	$df42
			stx	$df43
			sta	$df42
			pla
			sta	$df41
			rts
endif

;******************************************************************************
::tmp6 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp6!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Variablen.
:PP_DOS_ROUT_L		b < TD_MLoop_Stop
			b < TD_WriteBlock
			b < TD_ReadBlock
			b < TD_ReadLink
			b < TD_GetError

:PP_DOS_ROUT_H		b > TD_MLoop_Stop
			b > TD_WriteBlock
			b > TD_ReadBlock
			b > TD_ReadLink
			b > TD_GetError

:TurboMode		b $00
:TurboRoutineL		b $00
:TurboRoutineH		b $00
:TurboParameter1	b $00
:TurboParameter2	b $00

:ErrorCode		b $00
endif
