; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Vorbereitungen für "GetFile"-Routine.
; Datum			: 04.07.97
; Aufruf		: JSR  PrepGetFile
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -i_FillRam Speicherbereich füllen
;******************************************************************************

;*** Vorbereitungen für "GetFile"-Routine.
.PrepGetFile		jsr	i_FillRam
			w	417
			w	dlgBoxRamBuf
			b	$00

			lda	#$00
			tax
::101			sta	r0L,x
			inx
			cpx	#(r15H-r0L) +1
			bcc	:101
			rts
