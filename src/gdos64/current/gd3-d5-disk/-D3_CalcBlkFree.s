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
;*** Freien Speicher auf Diskette ermitteln.
;    Übergabe:		r5	= BAM im Speicher (in MP3 nicht verwendet).
;    Rückgabe:		r3	= Gesamtanzahl verfügbare Blöcke.
;			r4	= Anzahl freie Blöcke.
;    Geändert:		AKKU,xReg,yReg,r3,r4
:CalcCurBlksFree	jsr	curDirHead_r5		;Zeiger auf aktuelle BAM setzen.
:xCalcBlksFree		PushW	r2			;Register ":r2" retten.

			lda	#Tr_1stDataSek		;Zeiger auf ersten Datensektor.
			sta	r2L
			lda	#Se_1stDataSek
			sta	r2H

			lda	#$00			;Anzahl freier Sektoren löschen.
			sta	r4L
			sta	r4H

::51			lda	r2L			;Offset für BAM berechnen.
			sta	r3L
			lda	r2H
			sta	r3H

			ldx	#$03			;Track/Sektor-Adresse um 4Bit
::52			lsr	r3L			;verschieben. Track wird dadurch zum
			ror	r3H			;Zeiger auf BAM-Sektor und Sektor
			dex				;wird Zeiger auf BAM-Byte!
			bne	:52

			lda	r3L
			clc
			adc	#$02
			jsr	xGetBAMBlock		;BAM-Block einlesen.
			txa				;Diskettenfehler ?
			bne	:59			; => Ja, Abbruch...

			ldx	r3H
::53			lda	dir2Head,x		;Sektor in BAM-Byte frei ?
			beq	:56			; => Nein, weiter...

			ldy	#$07			;Freie Sektoren in BAM-Byte
::54			lsr				;addieren.
			bcc	:55
			inc	r4L
			bne	:55
			inc	r4H
::55			dey
			bpl	:54

::56			txa				;Alle Sektoren eines Tracks
			clc				;überprüft ?
			adc	#$01
			tax
			and	#%00011111
			bne	:53			; => Nein, weiter...

			lda	#$00			;Zeiger auf nächsten Track.
			sta	r2H
			inc	r2L
			lda	r2L			;Alle Tracks durchsucht ?
			beq	:57			; => Ja, Ende...
			cmp	LastTrOnDsk
			beq	:51
			bcc	:51			; => Nein, weiter...

::57			lda	DiskSize_Lb		;Max. verfügbarer Speicher
			sec				;ermitteln.
			sbc	#$10			;16K für Verzeichnis-Header
			sta	r3L			;von Gesamtgröße abziehen.
			lda	DiskSize_Hb
			sbc	#$00
			sta	r3H

			ldx	#$02			;KByte in Anzahl verfügbarer
::58			asl	r3L			;Sektoren umrechnen.
			rol	r3H
			dex
			bne	:58

::59			PopW	r2			;Register ":r2" zurücksetzen.
			rts
endif

;******************************************************************************
::tmp1 = RL_41!RD_41!C_41!FD_41!HD_41!HD_41_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Freien Speicher auf Diskette ermitteln.
;    Übergabe:		r5	= BAM im Speicher (in MP3 nicht verwendet).
;    Rückgabe:		r3	= Gesamtanzahl verfügbare Blöcke.
;			r4	= Anzahl freie Blöcke.
;    Geändert:		AKKU,xReg,yReg,r3,r4
:CalcCurBlksFree	jsr	curDirHead_r5		;Zeiger auf aktuelle BAM setzen.
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$04
::51			lda	(r5L),y			;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H
::52			tya
			clc
			adc	#$04
			tay
			cpy	#$48			;Verzeichnis-Track erreicht ?
			beq	:52			;Ja, weiter...
			cpy	#$90			;Ende BAM#1 erreicht ?
			bne	:51			;Nein, weiter...
			LoadW	r3,664			;Anzahl Sektoren auf 1541-Diskette.
			rts
endif

;******************************************************************************
::tmp2 = RL_71!RD_71!FD_71!HD_71!HD_71_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Freien Speicher auf Diskette ermitteln.
;    Übergabe:		r5	= BAM im Speicher (in MP3 nicht verwendet).
;    Rückgabe:		r3	= Gesamtanzahl verfügbare Blöcke.
;			r4	= Anzahl freie Blöcke.
;    Geändert:		AKKU,xReg,yReg,r3,r4
:CalcCurBlksFree	jsr	curDirHead_r5		;Zeiger auf aktuelle BAM setzen.
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$04
::51			lda	(r5L),y			;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H
::52			tya
			clc
			adc	#$04
			tay
			cpy	#$48			;Verzeichnis-Track erreicht ?
			beq	:52			;Ja, weiter...
			cpy	#$90			;Ende BAM#1 erreicht ?
			bne	:51			;Nein, weiter...

			ldy	#$dd
::53			lda	(r5L),y			;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:54
			inc	r4H
::54			iny				;Ende BAM#2 erreicht ?
			bne	:53			;Nein, weiter...

			lda	#> 1328			;Anzahl Sektoren auf 1571-Diskette.
			sta	r3H
			lda	#< 1328
			sta	r3L
::55			rts
endif

;******************************************************************************
::tmp3 = C_71
if :tmp3 = TRUE
;******************************************************************************
;*** Freien Speicher auf Diskette ermitteln.
;    Übergabe:		r5	= BAM im Speicher (in MP3 nicht verwendet).
;    Rückgabe:		r3	= Gesamtanzahl verfügbare Blöcke.
;			r4	= Anzahl freie Blöcke.
;    Geändert:		AKKU,xReg,yReg,r3,r4
:CalcCurBlksFree	jsr	curDirHead_r5		;Zeiger auf aktuelle BAM setzen.
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$04
::51			lda	(r5L),y			;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H
::52			tya
			clc
			adc	#$04
			tay
			cpy	#$48			;Verzeichnis-Track erreicht ?
			beq	:52			;Ja, weiter...
			cpy	#$90			;Ende BAM#1 erreicht ?
			bne	:51			;Nein, weiter...

			lda	#<664			;Anzahl Sektoren auf 1541-Diskette.
			ldy	#>664
			bit	curDirHead +3
			bpl	:55

			ldy	#$dd
::53			lda	(r5L),y			;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:54
			inc	r4H
::54			iny				;Ende BAM#2 erreicht ?
			bne	:53			;Nein, weiter...

			lda	#<1328			;Anzahl Sektoren auf 1571-Diskette.
			ldy	#>1328
::55			sta	r3L
			sty	r3H
::56			rts
endif

;******************************************************************************
::tmp4 = RL_81!RD_81!C_81!FD_81!HD_81!HD_81_PP
if :tmp4 = TRUE
;******************************************************************************
;*** Freien Speicher auf Diskette ermitteln.
;    Übergabe:		r5	= BAM im Speicher (in MP3 nicht verwendet).
;    Rückgabe:		r3	= Gesamtanzahl verfügbare Blöcke.
;			r4	= Anzahl freie Blöcke.
;    Geändert:		AKKU,xReg,yReg,r3,r4
:CalcCurBlksFree	jsr	curDirHead_r5		;Zeiger auf aktuelle BAM setzen.
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$10
::51			lda	dir2Head,y		;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H
::52			tya
			clc
			adc	#$06
			tay
			cpy	#$fa			;Directory-Track erreicht ?
			bne	:51			;Nein, weiter...

			ldy	#$10
::53			lda	dir3Head,y		;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:54
			inc	r4H
::54			tya
			clc
			adc	#$06
			tay				;Ende BAM#3 erreicht ?
			bne	:53			;Nein, weiter...

			lda	#> 3160
			sta	r3H
			lda	#< 3160
			sta	r3L
			rts
endif
