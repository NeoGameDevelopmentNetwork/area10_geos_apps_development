; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Speicher bis zur MP-Sprungtabelle mit $00-Bytes auffüllen.
;*** ACHTUNG! Sprungtabelle darf nur nach "hinten" mit neuen
;*** Sprungbefehlen aufgefüllt werden.
;******************************************************************************
			e $c0dc
;******************************************************************************
;*** Einsprungtabelle für neue Kernal-Routinen.
.i_UserColor		jmp	xi_UserColor
.i_ColorBox		jmp	xi_ColorBox
.DirectColor		jmp	xDirectColor
.RecColorBox		jmp	xRecColorBox
.GetBackScreen		jmp	xGetBackScreen
.ResetScreen		jmp	xResetScreen
.GEOS_InitSystem	jmp	GEOS_Init1
.PutKeyInBuffer		jmp	NewKeyInBuf
.SCPU_Pause		jmp	xSCPU_Pause

;*** Beim booten mit einer SuperCPU stehen hier Vektoren auf die
;    Optimierungsroutinen. Wird beim Startvorgang modifiziert wenn
;    eine SuperCPU erkannt wird.
.SCPU_PATCH_JMPTAB
if TRUE
.SCPU_OptOn		rts
			b $00,$00
.SCPU_OptOff		rts
			b $00,$00
.SCPU_SetOpt		rts
			b $00,$00
endif
if FALSE
.SCPU_OptOn		jmp	xSCPU_OptOn
.SCPU_OptOff		jmp	xSCPU_OptOff
.SCPU_SetOpt		jmp	xSCPU_SetOpt
endif
