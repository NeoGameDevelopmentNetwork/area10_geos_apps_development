; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerksinformationen speichern.
:UpdateDskDrvData	lda	DrvMode			;INIT-Routine im Laufwerkstreiber
			ldx	#< DSK_INIT_SIZE	;aktualisieren. Damit werden die
			stx	r2L			;Vorgabe-Werte in die Systemdatei
			ldx	#> DSK_INIT_SIZE	;geschrieben und können beim
			stx	r2H			;beim Systemstart abgerufen werden.
			jsr	a_SaveDskDrvData

			lda	DrvAdrGEOS		;Laufwerk zurücksetzen.
			jmp	SetDevice
