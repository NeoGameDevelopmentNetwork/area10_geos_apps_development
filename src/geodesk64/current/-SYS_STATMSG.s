; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Statusmeldung ausgeben.
;Übergabe: XReg = Fehlernummer.
;          r1L/r1H = Blockadresse.
:doXRegStatus		stx	errDrvCode		;Fehlernummer zwischenspeichern.

			MoveB	r1L,errDrvInfoT		;Track/Sektor für Laufwerksfehler
			MoveB	r1H,errDrvInfoS		;zwischenspeichern.

			ClrW	errDrvInfoF

			ldy	curDrive		;Partition für Laufwerksfehler
			lda	RealDrvMode -8,y	;zwischenspeichern.
			and	#SET_MODE_PARTITION
			beq	:1
			lda	drivePartData -8,y
::1			sta	errDrvInfoP

			jsr	SUB_STATMSG		;Statusmeldung ausgeben.

			ldx	errDrvCode		;Laufwerkfehler?
			beq	:exit			; => Nein, weiter...
			ldx	#CANCEL_ERR		; => Ja, Abbruch...
::exit			rts
