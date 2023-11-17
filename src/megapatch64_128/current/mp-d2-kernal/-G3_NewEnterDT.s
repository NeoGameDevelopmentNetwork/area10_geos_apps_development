; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zurück zum DeskTop
.xEnterDeskTop		jsr	SetADDR_EnterDT
			jsr	FetchRAM
			jmp	LD_ADDR_ENTER_DT
