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

;*** Quell-Laufwerk aktivieren.
:SetSource		jsr	i_MoveData
			w	SDrvNDir,SetSysNDir
			w	$0003

			lda	SDrvPart
			ldx	Source_Drv
			jmp	OpenNewDrive

;*** Ziel-Laufwerk aktivieren.
:SetTarget		jsr	i_MoveData
			w	TDrvNDir,SetSysNDir
			w	$0003

			lda	TDrvPart
			ldx	Target_Drv
;			jmp	OpenNewDrive

;*** Neues Laufwerk und Diskette öffnen.
:OpenNewDrive		pha
			txa
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			pla				;Partition wieder einlesen.

;--- Ergänzung: 29.11.18/M.Kanet
;AKKU nicht verändern...
			bit	curDrvMode		;CMD-Laufwerk ?
			bmi	:103			;Ja, weiter...
;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für SD2IEC/RAMNative.
			lda	curDrvMode		;CMD-Laufwerk ?
			and	#%00100000		;NativeMode-Laufwerk ?
			bne	:107			; => Ja, weiter...
			jsr	NewOpenDisk		;Nur Diskette öffnen.
			txa
			beq	:102
::101			jmp	ExitDskErr
::102			rts

::103			ldx	curDrive
			ldy	curDrvType
			cpy	#Drv_CMDRL
			beq	:104
;--- Ergänzung: 22.11.18/M.Kanet
;RAMDrive is der RAMLink ähnlich, Kennung angepasst.
			cpy	#Drv_CMDRD
			bne	:105
::104			ldx	#$04 +8
::105			cmp	SystemPart-8,x		;Partition bereits aktiviert ?
			bne	:106			;Ja, weiter...

			lda	curDrvMode
			and	#%00100000		;Native-Mode-Laufwerk ?
			bne	:107			;Ja, weiter...
			jsr	GetDirHead
			txa
			bne	:101
			rts

::106			sta	SystemPart-8,x		;Neue Partition merken und
			jsr	SaveNewPart		;Partition aktivieren.
			txa
			bne	:101

			lda	curDrvMode
			and	#%00100000		;Native-Mode-Laufwerk ?
			beq	:102			;Nein, Ende...

::107			jsr	:111
			lda	SetSysNDir+1		;Verzeichnis auf Laufwerk noch aktiv ?
			cmp	SystemNDir,x
			bne	:108			;Nein, Verzeichnis neu setzen...
			inx
			lda	SetSysNDir+2
			cmp	SystemNDir,x
			bne	:108			;Nein, Verzeichnis neu setzen...
			jsr	GetDirHead
			txa
			bne	:101
			rts

::108			lda	SetSysNDir +0		;Verzeichnistyp testen.
			bne	:109			; => Unterverzeichnis, weiter...
			jsr	New_CMD_Root		;Hauptverzeichnis aktivieren.
			txa
			bne	:101
			beq	:110

::109			lda	SetSysNDir +1		;Unterverzeichnis aktivieren.
			sta	r1L
			lda	SetSysNDir +2
			sta	r1H
			jsr	New_CMD_SubD
			txa
			bne	:101

::110			jsr	:111
			lda	curDirHead +32		;Aktuelles Verzeichnis auf Laufwerk
			sta	SystemNDir,x		;in Tabelle eintragen.
			inx
			lda	curDirHead +33
			sta	SystemNDir,x
			ldx	#$00
			rts

::111			lda	curDrive
			sec
			sbc	#$08
			asl
			tax
			rts

;*** Zeiger auf aktive Partitionen.
:SystemPart		s $05
:SystemNDir		s $04 *2
:SetSysNDir		s $03
