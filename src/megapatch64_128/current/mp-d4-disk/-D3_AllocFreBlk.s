; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0b = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp0c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0d = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d
if :tmp0 = TRUE
;******************************************************************************
;*** Block in BAM als "belegt" markieren.
;    Übergabe:		r6	= Sektor.
;    Geändert:		AKKU,xReg,yReg,r7H,r8H
:xAllocateBlock		jsr	xFindBAMBit		;Sektor-Status einlesen.
			beq	BAD_BAM_ERR		; => Belegt, Abbruch...
			bne	SwapBlockMode		;Sektor belegen.

;*** Block in BAM als "frei" markieren.
;    Übergabe:		r6	= Sektor.
;    Geändert:		AKKU,xReg,yReg,r7H,r8H
:xFreeBlock		jsr	xFindBAMBit		;Sektor-Status einlesen.
			beq	SwapBlockMode		; => Belegt, Sektor freigeben.

;*** BAM fehlerhaft!
:BAD_BAM_ERR		ldx	#BAD_BAM		;Fehler "BAD BAM".
			rts
endif
