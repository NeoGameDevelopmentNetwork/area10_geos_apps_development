; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Hauptverzeichnis aktivieren.
;    Übergabe:		-
;    Rückgabe:		xReg = Fehler.
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenRootDir		lda	#1			;Tr/Set für ROOT-Verzeichnisheader.
;			ldx	#1
			tax
			bne	openDirectory		;Verzeichnis öffnen.

;*** Unterverzeichnis aktivieren.
;    Übergabe:		r1L/r1H = Track/Sektor Unterverzeichnis.
;    Rückgabe:		xReg = Fehler.
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenSubDir		lda	r1L
			ldx	r1H
:openDirectory		sta	DirHead_Tr		;Neuen Verzeichnisheader setzen.
			stx	DirHead_Se
			jmp	xOpenDisk		;Diskette/Verzeichnis öffnen.
endif
