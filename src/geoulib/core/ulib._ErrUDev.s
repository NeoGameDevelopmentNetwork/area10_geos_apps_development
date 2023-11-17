; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Dialogbox: Kein Ultimate erkannt
;
;Hinweis:
;Für Applications und DeskAccesories!
;
;Übergabe : -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15

:ULIB_ERR_NO_UDEV

			lda	#< :dBoxUErr
			sta	r0L
			lda	#> :dBoxUErr
			sta	r0H
			jsr	DoDlgBox
;			lda	sysDBData
			rts

;--- Fehler: Kein Ultimate erkannt.
::dBoxUErr		b %10000001
			b DBTXTSTR,$10,$10
			w :1
			b DBTXTSTR,$10,$20
			w :2
			b OK      ,$02,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "FEHLER!"
			b PLAINTEXT,NULL
::2			b "Kein Ultimate-Gerät erkannt!"
			b NULL
