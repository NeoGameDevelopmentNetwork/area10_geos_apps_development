; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0 = TRUE
;******************************************************************************
;*** TurboDOS deaktivieren und aus Laufwerk entfernen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPurgeTurbo		bit	curType			;Shadow1541 ?
			bvc	:1			; => Nein, weiter...

			jsr	InitShadowRAM		;ShadowRAM löschen.

::1			jsr	xExitTurbo		;TurboDOS abschalten.

;*** TurboFlags auf aktuellem Laufwerk löschen.
:TurboOff_curDrv	ldy	curDrive
			lda	#%00000000
			sta	turboFlags -8,y
			rts
endif

;******************************************************************************
::tmp1a = C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!HD_41!HD_71!HD_81!HD_NM
::tmp1b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!IEC_NM!S2I_NM
::tmp1c = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp1d = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1  = :tmp1a!:tmp1b!:tmp1c!:tmp1d
if :tmp1 = TRUE
;******************************************************************************
;*** TurboDOS deaktivieren und aus Laufwerk entfernen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPurgeTurbo		jsr	xExitTurbo		;TurboDOS abschalten.

;*** TurboFlags auf aktuellem Laufwerk löschen.
:TurboOff_curDrv	ldy	curDrive
			lda	#%00000000
			sta	turboFlags -8,y
			rts
endif
