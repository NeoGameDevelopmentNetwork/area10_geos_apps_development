; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: DOS: Quell-Laufwerk öffnen.
; Datum			: 20.07.97
; Aufruf		: JSR  SetSource
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -NewDrive Neues Laufwerk.
;******************************************************************************

;*** Quell-Laufwerk für DOS aktivieren.
:SetSource		lda	Source_Drv		;Ziel-Laufwerk.
			jsr	NewDrive		;Laufwerk aktivieren.
			txa
			beq	:101
			jmp	ExitDskErr
::101			rts
