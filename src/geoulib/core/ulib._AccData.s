; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Daten akzeptieren
;
;Wenn ACK gesendet, dann warten bis
;das Ultimate die Meldung bestätigt.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK.
;           Y = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y

:ULIB_ACCEPT_DATA

			lda	#CMD_DATA_ACC
			sta	UCI_CONTROL

			jsr	ULIB_WAIT_IDLE		;Auf Ultimate warten...
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...

::err			rts				;Ende...
