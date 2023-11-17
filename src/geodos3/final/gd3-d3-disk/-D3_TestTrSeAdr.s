; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM!HD_NM_PP
if :tmp0 = TRUE
;******************************************************************************
;*** Sektor-Adresse auf Gültigkeit testen.
:TestTrSe_ADDR		ldx	#INV_TRACK
			lda	r1L
			beq	:52
			cmp	LastTrOnDsk
			beq	:51
			bcs	:52
::51			sec
			rts
::52			clc
			rts
endif

;******************************************************************************
::tmp1 = RL_41!RD_41!HD_41_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Sektor-Adresse auf Gültigkeit testen.
:TestTrSe_ADDR		ldx	#INV_TRACK
			lda	r1L
			beq	:51
			cmp	#35 +1
			bcs	:51
			sec
			rts
::51			clc
			rts
endif

;******************************************************************************
::tmp2 = RL_71!RD_71!HD_71_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Sektor-Adresse auf Gültigkeit testen.
:TestTrSe_ADDR		ldx	#INV_TRACK
			lda	r1L
			beq	:51
			cmp	#70 +1
			bcs	:51
			sec
			rts
::51			clc
			rts
endif

;******************************************************************************
::tmp3 = RL_81!RD_81!HD_81_PP
if :tmp3 = TRUE
;******************************************************************************
;*** Sektor-Adresse gültig ?
;    Übergabe:		r1L = Track.
:TestTrSe_ADDR		ldx	#INV_TRACK
			lda	r1L
			beq	:51
			cmp	#80 +1
			bcs	:51
			sec
			rts
::51			clc
			rts
endif

;******************************************************************************
::tmp4 = C_41
if :tmp4 = TRUE
;******************************************************************************
;*** Sektor in ShadowRAM bereits gespeichert ?
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:IsSekInRAM_OK		bit	curType			;Shadow 1541 ?
			bvc	TestTrSe_ADDR		;Nein, weiter...

			jsr	VerifySekInRAM		;Sektor in ShadowRAM gespeichert ?
			beq	TestTrSe_Cancel		;Ja, weiter...

;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr.".

			lda	r1L			;Track-Nummer einlesen.
			beq	TestTrSe_Cancel		; =  0, Fehler...
			cmp	#35 +1
			bcs	TestTrSe_Cancel		; > 35, Fehler...
:TestTrSe_OK		sec				;Sektor-Adresse in Ordnung, Ende...
			rts
:TestTrSe_Cancel	clc
			rts

:RepeatFunction		b $00
endif

;******************************************************************************
::tmp5 = FD_41!HD_41
if :tmp5 = TRUE
;******************************************************************************
;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr.".

			lda	r1L			;Track-Nummer einlesen.
			beq	:51			; =  0, Fehler...
			cmp	#35 +1
			bcs	:51			; > 35, Fehler...
			sec				;Sektor-Adresse in Ordnung, Ende...
			rts
::51			clc
			rts

:RepeatFunction		b $00
endif

;******************************************************************************
::tmp6 = C_71
if :tmp6 = TRUE
;******************************************************************************
;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr."
			lda	r1L			;Track-Adresse einlesen.
			beq	:52			; = $00 ? Ja, Fehler...
			cmp	#35 +1			;Track-Adresse #1 bis #35 ?
			bcc	:51			;Ja, OK, Ende...

			ldy	curDrive		;Diskettenmodus einlesen.
			lda	doubleSideFlg-8,y	;1541-Diskette ?
			bpl	:52			;Ja, Fehler: 1541 hat nur 35 Tracks!

			lda	r1L			;Track-Adresse einlesen.
			cmp	#70 +1			;Track-Adresse > 70 ?
			bcs	:52			;Ja, Fehler: 1571 hat nur 70 Tracks!
::51			sec				;Track/Sektor-Adresse in Ordung.
			rts
::52			clc
			rts

:RepeatFunction		b $00
endif

;******************************************************************************
::tmp7 = FD_71!HD_71
if :tmp7 = TRUE
;******************************************************************************
;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr."
			lda	r1L			;Track-Adresse einlesen.
			beq	:51			; = $00 ? Ja, Fehler...
			cmp	#70 +1			;Track-Adresse > 70 ?
			bcs	:51			;Ja, Fehler: 1571 hat nur 70 Tracks!
			sec				;Track/Sektor-Adresse in Ordung.
			rts
::51			clc
			rts

:RepeatFunction		b $00
endif

;******************************************************************************
::tmp8 = C_81!FD_81!HD_81
if :tmp8 = TRUE
;******************************************************************************
;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00			;Wiederholungszähler löschen.
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr.".
			lda	r1L			;Track-Nummer einlesen.
			beq	:51			; =  0, Fehler...
			cmp	#80 +1
			bcs	:51			; > 80, Fehler...
			sec
			rts
::51			clc
			rts

:RepeatFunction		b $00
endif

;******************************************************************************
::tmp9 = FD_NM!HD_NM!IEC_NM!S2I_NM
if :tmp9 = TRUE
;******************************************************************************
;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00			;Wiederholungszähler löschen.
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr.".
			lda	r1L			;Track-Adr. = $00 ?
			beq	:52			; => Ja, falsche Sektoradresse.

			cmp	LastTrOnDsk
			beq	:51
			bcs	:52

::51			sec
			rts

::52			clc
			rts

:RepeatFunction		b $00
endif
