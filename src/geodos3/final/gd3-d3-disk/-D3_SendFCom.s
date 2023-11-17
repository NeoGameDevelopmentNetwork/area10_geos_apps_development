; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!RL_41!RL_71!RL_81!RL_NM
::tmp0b = FD_41!FD_71!FD_81!FD_NM!PC_DOS!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0c = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0 = :tmp0a!:tmp0b!:tmp0c
if :tmp0 = TRUE
;******************************************************************************
;*** Floppy-Befehl an Laufwerk senden.
;    Übergabe:		r0	= Zeiger auf Floppy-Befehl.
;			r2L	= Anzahl Zeichen in Befehl.
:xSendCommand		lda	r0L
			ldx	r0H
			ldy	r2L
			b $2c

;*** Floppy-Befehl (5Bytes) an Laufwerk senden.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
:SendCom5Byt		ldy	#$05

;*** Floppy-Befehl mit variabler Länge an Laufwerk senden.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:SendComVLen		sta	:51 +1			;Zeiger auf Floppy-Befehl sichern.
			stx	:51 +2
			sty	:52 +1

;			jsr	UNTALK			;Aufruf durch ":initDevLISTEN".

			jsr	initDevLISTEN		;Laufwerk auf Empfang schalten.
			bne	:53			;Fehler? => Ja, Abbruch...

			ldy	#$00
::51			lda	$ffff,y			;Bytes an Floppy-Laufwerk senden.
			jsr	CIOUT
			iny
::52			cpy	#$05
			bcc	:51

			ldx	#NO_ERROR
::53			rts
endif
