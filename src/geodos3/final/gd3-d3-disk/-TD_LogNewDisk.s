; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Diskette aktivieren.
:xLogNewDisk		jsr	xEnterTurbo
;			txa
			bne	:err
			stx	RepeatFunction
			inx
			stx	r1L
			stx	r1H

			jsr	InitForIO		;I/O aktivieren.

::loop			ldx	#> TD_NewDisk		;NewDisk ausführen.
			lda	#< TD_NewDisk
			jsr	xTurboRoutSet_r1
			jsr	xGetDiskError		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:exit			;Nein, weiter...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;NewDisk nochmal senden.

::exit			jsr	DoneWithIO		;I/O abschalten.

::err			rts
endif
