; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0b = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp0c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0d = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d
if :tmp0 = TRUE
;******************************************************************************
;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2	= Anzahl Bytes.
;			r6	= Zeiger auf Track/Sektor-Tabelle.
;    Rückgabe:		r2	= Anzahl belegter Blöcke.
;			r3	= Letzter belegter Block.
;    Geändert:		AKKU,xReg,yReg,r2,r3,r4,r5,r8
:xBlkAlloc		lda	#Tr_1stDataSek
			sta	r3L
			lda	#Se_1stDataSek
			sta	r3H

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r3 = Erster Sektor für Suche nach freiem Sektor,
;			r6 = Zeiger auf Track/Sektor-Tabelle.
;    Rückgabe:		r2	= Anzahl belegter Blöcke.
;			r3	= Letzter belegter Block.
;    Geändert:		AKKU,xReg,yReg,r2,r3,r4,r5,r8
:xNxtBlkAlloc		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			PushW	r9
			PushW	r3

			LoadW	r3,254			;Anzahl Bytes in Anzahl Sektoren
			ldx	#r2L			;umrechnen.
			ldy	#r3L
			jsr	Ddiv

			lda	r8L			;Bytes / 254, Rest = 0 ?
			beq	:51			;Ja, weiter...
			inc	r2L			;Anzahl Sektoren +1.
			bne	:51
			inc	r2H

::51			jsr	CalcCurBlksFree		;Anzahl freier Blocks berechnen.

			PopW	r3			;Register ":r3" zurücksetzen.

			ldx	#INSUFF_SPACE		;Fehler: "Kein Platz auf Diskette!"

			CmpW	r2,r4			;Genügend Speicher frei ?
			beq	:53			;Ja, weiter...
			bcs	:58			;Nein, Fehler, Abbruch...

::53			MoveB	r6L,r4L			;Zeiger auf Track/Sektor-Tabelle
			MoveB	r6H,r4H			;nach ":r4" kopieren.

			MoveB	r2L,r5L			;Anzahl Sektoren nach ":r5"
			MoveB	r2H,r5H			;kopieren.

::54			jsr	xSetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...

			tay				;YReg auf $00 setzen.
;			ldy	#$00
			lda	r3L			;Sektor in Track/Sektor-Tabelle
			sta	(r4L),y			;kopieren.
			iny
			lda	r3H
			sta	(r4L),y

			AddVBW	2,r4			;Zeiger auf Track/Sektor-Tabelle
							;korrigieren.
			lda	r5L			;Anzahl Sektoren -1.
			bne	:56
			dec	r5H
::56			dec	r5L

			lda	r5L
			ora	r5H			;Alle Sektoren belegt ?
			bne	:54			;Nein, weiter...
			tay
			sta	(r4L),y
			iny
			lda	r8L			;Anzahl Bytes in letztem Sektor
			bne	:57			;in Track/Sektor-Tabelle kopieren.
			lda	#$fe
::57			clc
			adc	#$01
			sta	(r4L),y

;			ldx	#NO_ERROR		;Kein Fehler, Ende...
							;(xReg ist bereits NULL).

::58			PopW	r9			;Register ":r9" zurücksetzen.
			plp				;IRQ-Status zurücksetzen.
			rts
endif
