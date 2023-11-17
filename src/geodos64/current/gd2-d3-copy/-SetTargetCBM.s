; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: CBM: Ziel-Laufwerk öffnen.
; Datum			: 20.07.97
; Aufruf		: JSR  SetTarget
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -i_MoveData Speicher verschieben.
;			  -NewDrive Neues Laufwerk.
;			  -NewOpenDisk Neue Diskette öffnen.
;			  -GetDirHead BAM einlesen.
;			  -SaveNewPart Neue partition öffnen.
;			  -New_CMD_Root Hauptverzeichnis öffnen.
;			  -New_CMD_SubD Unterverzeichnis öffnen.
;******************************************************************************

;*** Ziel-Laufwerk für CBM aktivieren.
:SetTarget		lda	Target_Drv
			jsr	NewDrive		;Neues Laufwerk aktivieren.

;*** CMD-Laufwerke -> Partition öffnen.
			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:104			; => Nein, weiter...

			lda	TDrvPart +0
			jsr	SaveNewPart		;Partition aktivieren.
			txa
			beq	:104
::103			jmp	ExitDskErr

;*** NativeMode-Laufwerke -> Verzeichnis öffnen.
::104			lda	curDrvMode
			and	#%00100000		;SD2IEC/RAMNative-Laufwerk ?
			beq	:102			; => Nein, Ende...

			lda	TDrvNDir +0		;Verzeichnistyp testen.
			bne	:105			; => Unterverzeichnis, weiter...
			jsr	New_CMD_Root		;Hauptverzeichnis aktivieren.
			txa
			bne	:103
			rts

::105			lda	TDrvNDir +1		;Unterverzeichnis aktivieren.
			sta	r1L
			lda	TDrvNDir +2
			sta	r1H
			jsr	New_CMD_SubD
			txa
			bne	:103
			rts

;*** Nicht-NativeMode-Laufwerke -> Disk öffnen.
::102			jsr	NewOpenDisk		;Nur Diskette öffnen.
			txa
			bne	:103
::101			rts
