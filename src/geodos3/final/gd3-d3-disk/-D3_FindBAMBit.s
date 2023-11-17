; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!FD_41!HD_41!HD_41_PP!RL_41!RD_41
if :tmp0 = TRUE
;******************************************************************************
;*** Zustand für Sektor in BAM ermitteln.
;    Übergabe:		r6L	= Track
;			r6H	= Sektor.
;    Rückgabe:		Z-Flag	= 1, Sektor ist belegt.
;    Geändert:		AKKU,yReg,xReg,r7H,r8H
:xFindBAMBit		lda	r6H			;Offset innerhalb Byte berechnen.
			and	#$07
			tax
			lda	SingleBitTab,x
			sta	r8H

			lda	r6L			;Offset auf Track berechnen.
			asl
			asl
			sta	r7H

			lda	r6H			;Zeiger auf Byte mit Sektor-Bit
			lsr				;in BAM berechnen.
			lsr
			lsr
			sec
			adc	r7H
			tax
			lda	curDirHead,x		;Sektor-Byte einlesen und Bit für
			and	r8H			;aktuellen Sektor isolieren.
			rts

;*** BIT-Tabelle.
:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80
endif

;******************************************************************************
::tmp1 = C_71!FD_71!HD_71!HD_71_PP!RL_71!RD_71
if :tmp1 = TRUE
;******************************************************************************
;*** Zustand für Sektor in BAM ermitteln.
;    Übergabe:		r6L	= Track
;			r6H	= Sektor.
;    Rückgabe:		Z-Flag	= 1, Sektor ist belegt.
;    Geändert:		AKKU,yReg,xReg,r7H,r8H
:xFindBAMBit		lda	r6H			;Offset innerhalb Byte berechnen.
			and	#$07
			tax
			lda	SingleBitTab,x
			sta	r8H

			lda	r6L
			cmp	#36			;BAM-Bit für Tracks #1 - #35 ?
			bcc	:51			;Ja, weiter...

			sec				;Track-Adresse umrechnen.
			sbc	#36
			sta	r7H

			lda	r6H			;Zeiger auf Byte mit Sektor-Bit
			lsr				;in BAM berechnen.
			lsr
			lsr
			clc
			adc	r7H
			asl	r7H
			clc
			adc	r7H
			tax
			lda	r6L
			clc
			adc	#$b9
			sta	r7H
			lda	dir2Head,x		;Sektor-Byte einlesen und Bit für
			and	r8H			;aktuellen Sektor isolieren.
			rts

::51			asl				;Offset auf Track berechnen.
			asl
			sta	r7H

			lda	r6H			;Zeiger auf Byte mit Sektor-Bit
			lsr				;in BAM berechnen.
			lsr
			lsr
			sec
			adc	r7H
			tax
			lda	curDirHead,x		;Sektor-Byte einlesen und Bit für
			and	r8H			;aktuellen Sektor isolieren.
			rts

;*** BIT-Tabelle.
:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80
endif

;******************************************************************************
::tmp2 = C_81!FD_81!HD_81!HD_81_PP!RL_81!RD_81
if :tmp2 = TRUE
;******************************************************************************
;*** Zustand für Sektor in BAM ermitteln.
;    Übergabe:		r6L	= Track
;			r6H	= Sektor.
;    Rückgabe:		Z-Flag	= 1, Sektor ist belegt.
;    Geändert:		AKKU,yReg,xReg,r7H,r8H
:xFindBAMBit		lda	r6H			;Zeiger auf zuständiges Bit für
			and	#$07			;aktuellen Sektor in BAM-Byte
			tax				;ermitteln.
			lda	SingleBitTab,x
			sta	r8H

			lda	r6L			;Zeiger auf BAM-Daten berechnen.
			cmp	#41
			bcc	:51
			sec
			sbc	#40
::51			sec
			sbc	#$01
			asl
			sta	r7H
			asl
			clc
			adc	r7H
			sta	r7H
			lda	r6H
			lsr
			lsr
			lsr
			sec
			adc	r7H
			tax
			lda	r6L
			cmp	#41
			bcc	:52

			lda	dir3Head +16,x		;Byte für Track #41-#80 einlesen.
			and	r8H
			rts
::52			lda	dir2Head +16,x		;Byte für Track #41-#80 einlesen.
			and	r8H
			rts

;*** BIT-Tabelle.
:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80
endif

;******************************************************************************
::tmp3a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp3b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp3  = :tmp3a!:tmp3b
if :tmp3 = TRUE
;******************************************************************************
;*** Zustand für Sektor in BAM ermitteln.
;    Übergabe:		r6L	= Track
;			r6H	= Sektor.
;    Rückgabe:		Z-Flag	= 1, Sektor ist belegt.
;    Geändert:		AKKU,yReg,xReg,r7H,r8H
:xFindBAMBit		lda	r6H			;Bit-Maske für aktuellen
			and	#$07			;Sektor ermitteln.
			tax
			lda	SingleBitTab,x
			sta	r8H

			lda	r7L			;Register ":r7L" retten.
			pha

			MoveB	r6H,r7H
			MoveB	r6L,r7L

			ldx	#$03			;Track/Sektor-Adresse um 4Bit
::51			lsr	r7L			;verschieben. Track wird dadurch zum
			ror	r7H			;Zeiger auf BAM-Sektor und Sektor
			dex				;wird Zeiger auf BAM-Byte!
			bne	:51

			lda	r7L
			clc
			adc	#$02
			jsr	xGetBAMBlock		;BAM-Block einlesen.

			pla				;Register ":r7L" zurücksetzen.
			sta	r7L

			ldx	r7H			;Zustand für aktuellen Sektor
			txa				;ermitteln und Sektor-BIT
			lda	dir2Head,x		;isolieren.
			and	r8H
			rts

;*** BIT-Tabelle.
:SingleBitTab		b $80,$40,$20,$10,$08,$04,$02,$01
endif
