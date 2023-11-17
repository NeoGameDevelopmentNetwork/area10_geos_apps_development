; UTF-8 Byte Order Mark (BOM), do not remove!
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
;    Übergabe:		-
;    Rückgabe:		r5	= Zeiger auf ersten Verzeichnis-Eintrag.
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGet1stDirEntry	php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.
			lda	#$00
			sta	Flag_BorderBlock
			beq	GetCurDirSek		;Sektor einlesen.

;*** Nächsten Verzeichnis-Eintrag einlesen.
;    Übergabe:		r5	= Zeiger auf aktuellen Eintrag.
;    Rückgabe:		r5	= Zeiger auf nächsten Verzeichnis-Eintrag.
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetNxtDirEntry	php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			ldy	#$00			;YReg = #NULL = Verzeichnis OK
			ldx	#NO_ERROR		;XReg = #NULL = NO_ERROR.

			lda	#$20
			clc				;r5 auf nächsten Eintrag setzen.
			adc	r5L
			sta	r5L
			bcc	EndDirSekJob

;			ldx	#NO_ERROR
;			ldy	#$00

;			AddVBW	32,r5			;Zeiger auf nächsten Eintrag setzen.

;			lda	r5H
;			cmp	#> diskBlkBuf		;Ende des Sektors erreicht ?
;			beq	EndDirSekJob		;Nein, weiter...

			dey				;YReg = #255 = Verzeichnis Ende.
			lda	diskBlkBuf +$01
			sta	r1H
			lda	diskBlkBuf +$00
			sta	r1L			;Weiterer Sektor verfügbar ?
			bne	GetCurDirSek		;Ja, Sektor einlesen.

			lda	Flag_BorderBlock	;Ist BorderBlock bereits aktiv ?
			bne	EndDirSekJob		;Ja, Verzeichnis-Ende erreicht.
			dec	Flag_BorderBlock	;BorderBlock aktivieren.

			jsr	xGetBorderBlock		;Zeiger auf BorderBlock einlesen.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		;Ja, Abbruch...
			tya				;BorderBlock verfügbar ?
			bne	EndDirSekJob		;Nein, Abbruch...

:GetCurDirSek		jsr	xGetBlock_dskBuf	;Verzeichnis-Sektor einlesen.

			ldy	#$00
			LoadW	r5,diskBlkBuf +2
:EndDirSekJob		plp				;IRQ-Status zurücksetzen.
			rts

:Flag_BorderBlock	b $00
endif

;******************************************************************************
::tmp1a = FD_NM!PC_DOS!HD_NM!HD_NM_PP!RL_NM!RD_NM!IEC_NM!S2I_NM
::tmp1b = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1  = :tmp1a!:tmp1b
if :tmp1 = TRUE
;******************************************************************************
;*** Zeiger auf ersten Verzeichnis-Eintrag setzen.
;    Übergabe:		-
;    Rückgabe:		r5	= Zeiger auf ersten Verzeichnis-Eintrag.
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGet1stDirEntry	php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		; => Ja, Abbruch...

			jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.
			lda	#$00
			sta	Flag_BorderBlock
			beq	GetCurDirSek		;Sektor einlesen.

;*** Nächsten Verzeichnis-Eintrag einlesen.
;    Übergabe:		r5	= Zeiger auf aktuellen Eintrag.
;    Rückgabe:		r5	= Zeiger auf nächsten Verzeichnis-Eintrag.
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetNxtDirEntry	php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			ldy	#$00			;YReg = #NULL = Verzeichnis OK
			ldx	#NO_ERROR		;XReg = #NULL = NO_ERROR.

			lda	#$20
			clc				;r5 auf nächsten Eintrag setzen.
			adc	r5L
			sta	r5L
			bcc	EndDirSekJob

;			ldx	#NO_ERROR
;			ldy	#$00

;			AddVBW	32,r5			;Zeiger auf nächsten Eintrag setzen.

;			lda	r5H
;			cmp	#> diskBlkBuf		;Ende des Sektors erreicht ?
;			beq	EndDirSekJob		;Nein, weiter...

			dey				;YReg = #255 = Verzeichnis Ende.
			lda	diskBlkBuf +$01
			sta	r1H
			lda	diskBlkBuf +$00
			sta	r1L			;Weiterer Sektor verfügbar ?
			bne	GetCurDirSek		;Ja, Sektor einlesen.

			lda	Flag_BorderBlock	;Ist BorderBlock bereits aktiv ?
			bne	EndDirSekJob		;Ja, Verzeichnis-Ende erreicht.
			dec	Flag_BorderBlock	;BorderBlock aktivieren.

			jsr	xGetBorderBlock		;Zeiger auf BorderBlock einlesen.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		;Ja, Abbruch...
			tya				;BorderBlock verfügbar ?
			bne	EndDirSekJob		;Nein, Abbruch...

:GetCurDirSek		jsr	xGetBlock_dskBuf	;Verzeichnis-Sektor einlesen.

			ldy	#$00
			LoadW	r5,diskBlkBuf +2
:EndDirSekJob		plp				;IRQ-Status zurücksetzen.
			rts

:Flag_BorderBlock	b $00
endif
