; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: CBM: Quell-Laufwerk öffnen.
; Datum			: 20.07.97
; Aufruf		: JSR  SetSource
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

;*** Quell-Laufwerk für CBM aktivieren.
:SetSource		lda	Source_Drv
			jsr	NewDrive		;Neues Laufwerk aktivieren.

			lda	curDrvMode		;CMD-Laufwerk ?
			bmi	:102			; => Ja, weiter...
			and	#%00100000		;NativeMode ?
			bne	:104a			; => Ja, weiter...
			jsr	NewOpenDisk		;Nur Diskette öffnen.
			txa
			bne	:103
::101			rts

::102			lda	SDrvPart +0
			jsr	SaveNewPart		;Partition aktivieren.
			txa
			beq	:104
::103			jmp	ExitDskErr

::104			lda	curDrvMode
			and	#%00100000		;Native-Mode-Laufwerk ?
			beq	:101			;Nein, Ende...

::104a			lda	SDrvNDir +0		;Verzeichnistyp testen.
			bne	:105			; => Unterverzeichnis, weiter...
			jsr	New_CMD_Root		;Hauptverzeichnis aktivieren.
			txa
			bne	:103
			rts

::105			lda	SDrvNDir +1		;Unterverzeichnis aktivieren.
			sta	r1L
			lda	SDrvNDir +2
			sta	r1H
			jsr	New_CMD_SubD
			txa
			bne	:103
			rts
