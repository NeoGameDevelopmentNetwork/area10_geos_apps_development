; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#10			;Sektor-Interleave festlegen.
			sta	interleave

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GD3-Register nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DriveModeFlags
			ora	xFlag_SD2IEC
			sta	RealDrvMode -8,y

;			ldy	curDrive
			lda	turboFlags -8,y
			ora	#%11000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,y		;wegen Kompatibilität setzen.

			ldx	#NO_ERROR
::error			txa
			pha
			jsr	closeAllChan		;Laufwerkskanäle zurücksetzen.
			pla
			tax

			rts
endif

;******************************************************************************
::tmp1 = C_81!S2I_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#$01			;Sektor-Interleave für FD/HD
			sta	interleave		;festlegen.

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GD3-Register nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DriveModeFlags
			ora	xFlag_SD2IEC
			sta	RealDrvMode -8,y

;			ldy	curDrive
			lda	turboFlags -8,y
			ora	#%11000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,y		;wegen Kompatibilität setzen.

			ldx	#NO_ERROR
::error			txa
			pha
			jsr	closeAllChan		;Laufwerkskanäle zurücksetzen.
			pla
			tax

			rts
endif

;******************************************************************************
::tmp2 = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM!PC_DOS!IEC_NM
if :tmp2!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#$01			;Sektor-Interleave für FD/HD
			sta	interleave		;festlegen.

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GD3-Register nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DriveModeFlags
			sta	RealDrvMode -8,y

;			ldy	curDrive
			lda	turboFlags -8,y
			ora	#%11000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,y		;wegen Kompatibilität setzen.

			ldx	#NO_ERROR
::error			txa
			pha
			jsr	closeAllChan		;Laufwerkskanäle zurücksetzen.
			pla
			tax

			rts
endif
