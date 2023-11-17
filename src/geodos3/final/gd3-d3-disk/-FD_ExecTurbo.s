; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** API-Dummy-Routine für Sprungtabelle.
:xTurboRoutine_r1	ldx	#NO_ERROR
			rts

;*** U1/U2-Befehl senden.
:sendFComU1		lda	#"1"			;"U1"
			b $2c
:sendFComU2		lda	#"2"			;"U2"
			sta	FComUsek +1

			jsr	initDevLISTEN		;Laufwerk auf Empfang schalten.
			bne	:err			;Fehler? => Ja, Abbruch...

			ldy	#$00
::1			lda	FComUsek,y		;Befehl an Laufwerk senden.
			jsr	CIOUT
			iny
			cpy	#FComAdrLen
			bcc	:1

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	xGetDiskError		;Fehlerstatus einlesen.

::err			rts

:FComUsek		b "U1 5 0 "
:FComAdrTr		b "001 "
:FComAdrSe		b "001"
:FComAdrEnd
:FComAdrLen		= (FComAdrEnd - FComUsek)
endif
