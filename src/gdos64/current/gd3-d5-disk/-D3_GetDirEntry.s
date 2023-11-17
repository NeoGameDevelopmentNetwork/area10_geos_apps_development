﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81
::tmp0b = FD_41!FD_71!FD_81!HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp0c = RL_41!RL_71!RL_81!RD_41!RD_71!RD_81
::tmp0  = :tmp0a!:tmp0b!:tmp0c
if :tmp0 = TRUE
;******************************************************************************
;*** Zeiger auf ersten Verzeichnis-Eintrag setzen.
;Übergabe: -
;Rückgabe: r5 = Zeiger auf ersten Verzeichnis-Eintrag.
;          X  = $00: Kein Fehler.
;Geändert: A,X,Y,r1,r4
:xGet1stDirEntry	jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.
			lda	#$00
			sta	Flag_BorderBlock
			beq	GetCurDirSek		;Verzeichnis-Sektor einlesen.

;*** Nächsten Verzeichnis-Eintrag einlesen.
;Übergabe: r5 = Zeiger auf aktuellen Eintrag.
;Rückgabe: r5 = Zeiger auf nächsten Verzeichnis-Eintrag.
;          X  = $00: Kein Fehler.
;          Y  = $FF: Verzeicnis-Ende erreicht.
;Geändert: A,X,Y,r1,r4
:xGetNxtDirEntry	ldy	#$00			;YReg = #NULL = Verzeichnis OK
			ldx	#NO_ERROR		;XReg = #NULL = NO_ERROR.

			lda	r5L			;r5 auf nächsten Eintrag setzen.
			clc
			adc	#$20
			sta	r5L			;Ende Verzeichnis-Block?
			bcc	EndDirSekJob		; => Nein, weiter...

;			ldx	#NO_ERROR
;			ldy	#$00

;			AddVBW	32,r5			;Zeiger auf nächsten Eintrag setzen.

;			lda	r5H
;			cmp	#> diskBlkBuf		;Ende des Sektors erreicht ?
;			beq	EndDirSekJob		;Nein, weiter...

			dey				;YReg = #$FF = Verzeichnis Ende.

			lda	diskBlkBuf +1
			sta	r1H
			lda	diskBlkBuf +0
			sta	r1L			;Weiterer Sektor verfügbar ?
			bne	GetCurDirSek		;Ja, Sektor einlesen.

			bit	Flag_BorderBlock	;Ist Borderblock bereits aktiv ?
			bmi	EndDirSekJob		; => Ja, Verzeichnis-Ende erreicht.

			dec	Flag_BorderBlock	;Borderblock aktivieren.

			jsr	xGetBorderBlock		;Zeiger auf Borderblock einlesen.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		; => Ja, Abbruch...
			tya				;Borderblock verfügbar ?
			bne	EndDirSekJob		; => Nein, Abbruch...

:GetCurDirSek		jsr	xGetBlock_dskBuf	;Verzeichnis-Sektor einlesen.

			ldy	#$00
			LoadW	r5,diskBlkBuf +2
:EndDirSekJob		rts
endif

;******************************************************************************
::tmp1a = FD_NM!HD_NM!HD_NM_PP!RL_NM!RD_NM!IEC_NM!S2I_NM
::tmp1b = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1  = :tmp1a!:tmp1b
if :tmp1 = TRUE
;******************************************************************************
;*** Zeiger auf ersten Verzeichnis-Eintrag setzen.
;Übergabe: -
;Rückgabe: r5 = Zeiger auf ersten Verzeichnis-Eintrag.
;          X  = $00: Kein Fehler.
;Geändert: A,X,Y,r1,r4
:xGet1stDirEntry	jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		; => Ja, Abbruch...

			jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.
			lda	#$00
			sta	Flag_BorderBlock
			beq	GetCurDirSek		;Verzeichnis-Sektor einlesen.

;*** Nächsten Verzeichnis-Eintrag einlesen.
;Übergabe: r5 = Zeiger auf aktuellen Eintrag.
;Rückgabe: r5 = Zeiger auf nächsten Verzeichnis-Eintrag.
;          X  = $00: Kein Fehler.
;          Y  = $FF: Verzeicnis-Ende erreicht.
;Geändert: A,X,Y,r1,r4
:xGetNxtDirEntry	ldy	#$00			;YReg = #NULL = Verzeichnis OK
			ldx	#NO_ERROR		;XReg = #NULL = NO_ERROR.

			lda	r5L			;r5 auf nächsten Eintrag setzen.
			clc
			adc	#$20
			sta	r5L			;Ende Verzeichnis-Block?
			bcc	EndDirSekJob		; => Nein, weiter...

;			ldx	#NO_ERROR
;			ldy	#$00

;			AddVBW	32,r5			;Zeiger auf nächsten Eintrag setzen.

;			lda	r5H
;			cmp	#> diskBlkBuf		;Ende des Sektors erreicht ?
;			beq	EndDirSekJob		; => Nein, weiter...

			dey				;YReg = #$FF = Verzeichnis Ende.

			lda	diskBlkBuf +1
			sta	r1H
			lda	diskBlkBuf +0
			sta	r1L			;Weiterer Sektor verfügbar ?
			bne	GetCurDirSek		; => Ja, Sektor einlesen.

			bit	Flag_BorderBlock	;Borderblock/SharedDir aktiv?
			bmi	EndDirSekJob		; => Ja, Verzeichnis-Ende erreicht.

			dec	Flag_BorderBlock	;Borderblock/SharedDir aktiv.

;--- Hinweis:
;":OpenDisk" führt ":GetDirHead" aus.
;Bei NativeMode wird dabei der ROOT-
;BAM-Block mit der Adresse des Border-
;Blocks eingelesen.
;			jsr	xGetBorderBlock		;Zeiger auf Borderblock einlesen.
;			txa				;Diskettenfehler ?
;			bne	EndDirSekJob		; => Ja, Abbruch...
;			tya				;Borderblock verfügbar ?
;			bne	EndDirSekJob		; => Nein, Abbruch...

			bit	isGEOS			;GEOS-Diskette?
			bpl	EndDirSekJob		; => Nein, Ende...

			lda	curDirHead +172
			sta	r1H
			lda	curDirHead +171
			sta	r1L			;Borderblock/SharedDir vorhanden?
			beq	EndDirSekJob		; => Nein, Ende...

:GetCurDirSek		jsr	xGetBlock_dskBuf	;Verzeichnis-Sektor einlesen.

			ldy	#$00
			LoadW	r5,diskBlkBuf +2
:EndDirSekJob		rts
endif

;******************************************************************************
::tmp2 = PC_DOS
if :tmp2 = TRUE
;******************************************************************************
;*** Zeiger auf ersten Verzeichnis-Eintrag setzen.
;Übergabe: -
;Rückgabe: r5 = Zeiger auf ersten Verzeichnis-Eintrag.
;          X  = $00: Kein Fehler.
;Geändert: A,X,Y,r1,r4
:xGet1stDirEntry	jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		; => Ja, Abbruch...

			jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.
			clv
			bvc	GetCurDirSek		;Verzeichnis-Sektor einlesen.

;*** Nächsten Verzeichnis-Eintrag einlesen.
;Übergabe: r5 = Zeiger auf aktuellen Eintrag.
;Rückgabe: r5 = Zeiger auf nächsten Verzeichnis-Eintrag.
;          X  = $00: Kein Fehler.
;          Y  = $FF: Verzeicnis-Ende erreicht.
;Geändert: A,X,Y,r1,r4
:xGetNxtDirEntry	ldy	#$00			;YReg = #NULL = Verzeichnis OK
			ldx	#NO_ERROR		;XReg = #NULL = NO_ERROR.

			lda	r5L			;r5 auf nächsten Eintrag setzen.
			clc
			adc	#$20
			sta	r5L			;Ende Verzeichnis-Block?
			bcc	EndDirSekJob		; => Nein, weiter...

;			ldx	#NO_ERROR
;			ldy	#$00

;			AddVBW	32,r5			;Zeiger auf nächsten Eintrag setzen.

;			lda	r5H
;			cmp	#> diskBlkBuf		;Ende des Sektors erreicht ?
;			beq	EndDirSekJob		;Nein, weiter...

			dey				;YReg = #$FF = Verzeichnis Ende.

			lda	diskBlkBuf +$01
			sta	r1H
			lda	diskBlkBuf +$00
			sta	r1L			;Weiterer Sektor verfügbar ?
			beq	EndDirSekJob		; => Ja, Verzeichnis-Ende erreicht.

:GetCurDirSek		jsr	xGetBlock_dskBuf	;Verzeichnis-Sektor einlesen.

			ldy	#$00
			LoadW	r5,diskBlkBuf +2
:EndDirSekJob		rts
endif
