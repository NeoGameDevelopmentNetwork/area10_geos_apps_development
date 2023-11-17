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
::tmp0 = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Diskettennamen definieren.
;    Übergabe:		r4	= Zeiger auf dir2Head.
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:SwapDskNamData		php
			sei

			lda	r1L
			cmp	DirHead_Tr
			bne	:ExitSwapDkNm
			lda	r1H
			cmp	DirHead_Se
			bne	:ExitSwapDkNm
endif

;******************************************************************************
::tmp1 = RD_81!RL_81!C_81!FD_81!HD_81!HD_81_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Diskettennamen definieren.
;    Übergabe:		r4	= Zeiger auf dir2Head.
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:SwapDskNamData		php
			sei

			lda	r1L
			cmp	#Tr_DskNameSek
			bne	:ExitSwapDkNm
			lda	r1H
			cmp	#Se_DskNameSek
			bne	:ExitSwapDkNm
endif

;******************************************************************************
::tmp2a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp2b = RD_81!RL_81!C_81!FD_81!HD_81!HD_81_PP
::tmp2c = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp2 = :tmp2a!:tmp2b!:tmp2c
if :tmp2 = TRUE
;******************************************************************************
;--- Ergänzung: 26.08.18/M.Kanet
;Einige Anwendungen erwarten den Disknamen ab Byte $04, andere ab Byte $90.
;Disknamen an beiden Stellen einblenden.
;--- Ergänzung: 25.10.18/M.Kanet
;Änderung rückgängig gemacht.
;Diese Routine kopiert im Original GEOS 2.x immer den Namen von $04 nach $90
;um Kompatibel mit 1541/71 zu sein. Damit können auch Programme die nicht
;an 1581/Native angepasst wurden den Disknamen ab Byte $90 auslesen.
;Bei PutBlock wird der Name dann wieder zurückgetauscht.
			ldy	#$00 +4			;Zeiger auf Angang Diskname.
::51			lda	(r4L),y			;Zeichen aus Original-Name lesen
			sta	:byteBuf +1		;und zwischenspeichern.

			tya				;Zeiger auf 1541/1571 kompatible
			clc				;Position des Disknamen setzen.
			adc	#$90 -4
			tay

			lda	(r4L),y			;Zeichen aus 1541/1571 kompatiblen
			pha				;Disknamen einlesen und merken.

::byteBuf		lda	#$ff			;Zeichen aus Original-Name wieder
			sta	(r4L),y			;einlesen und an kompatible
							;Position speichern.
			tya				;Zeiger zurück auf originale
			sec				;Position des Disknamen setzen.
			sbc	#$90 -4
			tay

			pla				;Zeichen aus 1541/1571 kompatiblen
			sta	(r4L),y			;Disknamen wieder einlesen und
							;an originaler Stelle einfügen.
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#$19 +4			;Alle 25 Zeichen getauscht?
			bne	:51			; => Nein, weiter...

			txa				;AKKU wieder herstellen.
			ldy	#$00			;YReg zurücksetzen.
::ExitSwapDkNm		plp				;IRQ wieder freigeben.
			rts				;Ende.
endif
