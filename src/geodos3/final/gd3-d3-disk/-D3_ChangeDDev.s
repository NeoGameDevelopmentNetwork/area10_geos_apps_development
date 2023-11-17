; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71
;Routine entfällt bis auf weiteres, da Routine auf der nächsten
;Seite kürzer ist.
if 0=1
;******************************************************************************
;*** Geräteadresse ändern.
;    Übergabe:		AKKU	= Neue Geräteadresse.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1L
:xChangeDiskDev		tay
			lda	r1L
			pha
			tya
			pha
			jsr	xEnterTurbo		;TurboDOS aktivieren.
			pla
			cpx	#NO_ERROR 		;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...

			pha
			ora	#$20			;Neue Geräteadresse berechnen und
			sta	r1L			;zwischenspeichern.

			jsr	InitForIO		;I/O aktivieren.
			ldx	#> TD_NewDrvAdr
			lda	#< TD_NewDrvAdr
			jsr	xTurboRoutSet_r1	;Geräteadresse tauschen.
			jsr	DoneWithIO		;I/O abschalten.

			jsr	TurboOff_curDrv		;TurboFlag für aktuelles
							;Laufwerk löschen.
			pla
			tay
			cpy	#12
			bcs	:51

			lda	#%00000000
			sta	turboFlags -8,y		;TurboFlags löschen.
			sty	curDrive		;Neue Adresse an GEOS übergeben.
			sty	curDevice

			lda	diskDrvType		;Laufwerkstyp aktualisieren.
			sta	RealDrvType-8,y

::51			pla
			sta	r1L 			;Abbruch.
			rts
endif

;******************************************************************************
::tmp0a = C_41!C_71
if :tmp0a = TRUE
;******************************************************************************
;*** Geräteadresse ändern.
;    Übergabe:		AKKU	= Neue Geräteadresse.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1L
:xChangeDiskDev		pha
			ora	#%00100000
			sta	NewDrvAdr1		;Ziel-Adresse #1 berechnen.
			eor	#%01100000
			sta	NewDrvAdr2		;Ziel-Adresse #2 berechnen.

			ldx	curDrive
			cpx	#12
			bcs	:51
			jsr	xExitTurbo

::51			jsr	InitForIO		;I/O aktivieren.

			ldx	#> Floppy_ADR
			lda	#< Floppy_ADR
			ldy	#8
			jsr	SendComVLen		;Geräteadresse ändern.
			bne	:error			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			pla
			tay
			cpy	#12
			bcs	:exit

			lda	#%00000000
			sta	turboFlags -8,y		;TurboFlags löschen.
			sty	curDrive		;Neue Adresse an GEOS übergeben.
			sty	curDevice

			lda	diskDrvType		;Laufwerkstyp aktualisieren.
			sta	RealDrvType-8,y

::exit			ldx	#NO_ERROR
::error			jmp	DoneWithIO		;I/O abschalten.

;*** Variablen für Laufwerkstausch.
:Floppy_ADR		b "M-W",$77,$00,$02
:NewDrvAdr1		b $00
:NewDrvAdr2		b $00
endif

;******************************************************************************
::tmp1a = C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp1b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!PC_DOS!IEC_NM!S2I_NM
::tmp1 = :tmp1a!:tmp1b
if :tmp1 = TRUE
;******************************************************************************
;*** Geräteadresse ändern.
;    Übergabe:		AKKU	= Neue Geräteadresse.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xChangeDiskDev		sta	Floppy_U0_x +3		;Neue Adresse merken.

			jsr	xPurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldx	#> Floppy_U0_x
			lda	#< Floppy_U0_x
			ldy	#4
			jsr	SendComVLen		;Geräteadresse ändern.
			bne	:error			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	Floppy_U0_x +3		;Geräteadresse einlesen.
			cpy	#12
			bcs	:exit

			lda	#%00000000
			sta	turboFlags -8,y		;TurboFlags löschen.
			sty	curDrive		;Neue Adresse an GEOS übergeben.
			sty	curDevice

			lda	diskDrvType		;Laufwerkstyp aktualisieren.
			sta	RealDrvType-8,y

::exit			ldx	#NO_ERROR
::error			jmp	DoneWithIO		;I/O abschalten.

;*** Befehl zum wechseln der Laufwerksadresse.
:Floppy_U0_x		b "U0",$3e,$08
endif

;******************************************************************************
::tmp2 = RL_41!RL_71!RL_81!RL_NM
if :tmp2 = TRUE
;******************************************************************************
;*** Geräteadresse ändern.
;    Übergabe:		AKKU	= Neue Geräteadresse.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xChangeDiskDev		sta	Floppy_U0_x +3		;Neue Adresse merken.

			jsr	xPurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldx	#> Floppy_U0_x
			lda	#< Floppy_U0_x
			ldy	#4
			jsr	SendComVLen		;Geräteadresse ändern.
			bne	:error			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	Floppy_U0_x +3		;Geräteadresse einlesen.
			cpy	#12
			bcs	:exit

			lda	#%00000000
			sta	turboFlags -8,y		;TurboFlags löschen.
			sty	curDrive		;Neue Adresse an GEOS übergeben.
			sty	curDevice

			lda	diskDrvType		;Laufwerkstyp aktualisieren.
			sta	RealDrvType-8,y

::exit			ldx	#NO_ERROR
::error			jmp	DoneWithIO		;I/O abschalten.

;*** Befehl zum wechseln der Laufwerksadresse.
:Floppy_U0_x		b "U0",$3e,$08
endif

;******************************************************************************
::tmp3 = RD_NM!RD_81!RD_71!RD_41!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp3 = TRUE
;******************************************************************************
;*** Geräteadresse ändern.
;    Übergabe:		AKKU	= Neue Geräteadresse.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xChangeDiskDev		sta	curDrive		;Neue Adresse an GEOS übergeben.
			sta	curDevice

			tay
			lda	diskDrvType		;Laufwerkstyp aktualisieren.
			sta	RealDrvType -8,y

			ldx	#NO_ERROR
			rts
endif
