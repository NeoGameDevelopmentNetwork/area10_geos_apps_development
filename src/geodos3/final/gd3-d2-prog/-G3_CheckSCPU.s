; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** SuperCPU erkennen.
:CheckSCPU		jsr	DetectSCPU

			ldy	#$00
			cpx	#DEV_NOT_FOUND
			beq	:1
			dey				; => SuperCPU vorhanden.
::1			sty	Device_SCPU		;SuperCPU-Modus speichern.

			rts

;*** SuperCPU-Modus:
;    $00 = Keine SuperCPU.
;    $FF = SuperCPU vorhanden.
:Device_SCPU		b $00
