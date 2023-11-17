; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: DOS_TARGET
;
;Target DOS1/DOS2 wählen.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;Verändert: A

:_UCID_SET_TARGET1

			lda	#UCI_TARGET_DOS1
			b $2c

:_UCID_SET_TARGET2

			lda	#UCI_TARGET_DOS2
			sta	UCI_TARGET
			rts

:UCI_TARGET		b $00
