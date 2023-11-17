; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** PANIC!-Routine.
:xPanic			jsr	SetADDR_PANIC		;Panic-Routine einlesen.
			jsr	FetchRAM
			jmp	LD_ADDR_PANIC		;Panic-Routine ausführen.
