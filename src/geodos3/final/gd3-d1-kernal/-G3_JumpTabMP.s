; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle für neue Kernal-Routinen.
.i_UserColor		jmp	xi_UserColor
.i_ColorBox		jmp	xi_ColorBox
.DirectColor		jmp	xDirectColor
.RecColorBox		jmp	xRecColorBox
.GetBackScreen		jmp	xGetBackScreen
.ResetScreen		jmp	xResetScreen
.GEOS_InitSystem	jmp	GEOS_Init1
.PutKeyInBuffer		jmp	NewKeyInBuf

;*** Einsprungtabelle für SCPU-Routinen.
.SCPU_Pause		jmp	xSCPU_Pause

;*** Hier wird direkt variabler Code eingetragen.
;    Beim booten mit SCPU stehen hier Vektoren auf die
;    Optimierungsroutinen.
;    Wird beim booten von GEOS modifiziert wenn SCPU vorhanden.

.SCPU_PATCH_JMPTAB
if SCPU_Mode = FALSE
.SCPU_OptOn		rts
			b $00,$00
.SCPU_OptOff		rts
			b $00,$00
.SCPU_SetOpt		rts
			b $00,$00
else
.SCPU_OptOn		jmp	xSCPU_OptOn
.SCPU_OptOff		jmp	xSCPU_OptOff
.SCPU_SetOpt		jmp	xSCPU_SetOpt
endif
