; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RAMLink erkennen.
:CheckRLNK		jsr	DetectRLNK		;RAMLink erkennen.

			ldy	#$00
			cpx	#DEV_NOT_FOUND
			beq	:1
			dey				; => RAMLink vorhanden.
::1			sty	Device_RL		;RAMLink-Modus speichern.

			rts

;*** RAMLink-Modus:
;    $00 = Keine RAMLink.
;    $FF = RAMLink vorhanden.
:Device_RL		b $00
