; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_NM!RL_81!RL_71!RL_41
if :tmp0 = TRUE
;******************************************************************************
;*** Sektor über Partitions-Register einlesen.
;    Übergabe:		r1   = Track/Sektor.
;			r3H  = Partitions-Nr.
;			r4   = Sektorspeicher.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xDsk_SekRead		ldy	#$80
			b $2c
:xDsk_SekWrite		ldy	#$90
			b $2c
:xDsk_SekVerify		ldy	#$a0
			b $2c
:xDsk_SekSwap		ldy	#$b0
:xDsk_DoSekJob		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.
			lda	CPU_DATA		;CPU Register einlesen und
			pha				;zwischenspeichern.
			lda	#$36			;I/O-Bereich und Kernal für
			sta	CPU_DATA		;RAMLink-Transfer aktivieren.

			tya
			pha
			jsr	EN_SET_REC		;RL-Hardware aktivieren.
			pla				;Sektor-Daten setzen.
			sta	$de20
			lda	r1L
			sta	$de21
			lda	r1H
			sta	$de22
			lda	r4L
			sta	$de23
			lda	r4H
			sta	$de24
			lda	r3H
			sta	$de25
			lda	#$01
			sta	$de26

			jsr	EXEC_REC_SEC		;Sektor-Jobcode ausführen.

			lda	$de20			;Fehlerstatus einlesen und
			pha				;zwischenspeichern.
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.
			pla
			tax
			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ-Status zurücksetzen.
::51			rts
endif

;******************************************************************************
::tmp2 = RD_NM!RD_81!RD_71!RD_41
if :tmp2 = TRUE
;******************************************************************************
;*** Sektor über Partitions-Register einlesen.
;    Übergabe:		r1   = Track/Sektor.
;			r3H  = Partitions-Nr.
;			r4   = Sektorspeicher.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xDsk_SekRead		ldy	#jobFetch
			b $2c
:xDsk_SekWrite		ldy	#jobStash
			b $2c
:xDsk_SekVerify		ldy	#jobVerify
			b $2c
:xDsk_SekSwap		ldy	#jobSwap
:xDsk_DoSekJob		jsr	Save_RegData

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.
			jsr	DoRAMOp			;Daten aus RAMLink einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register zurücksetzen. Akku,
							;XReg,YReg werden nicht verändert.
			ldx	#NO_ERROR		;Flag für "Kein Fehler..."
			rts
endif

;******************************************************************************
::tmp3 = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp3 = TRUE
;******************************************************************************
;*** Sektor über Partitions-Register einlesen.
;    Übergabe:		r1   = Track/Sektor.
;			r3H  = Partitions-Nr.
;			r4   = Sektorspeicher.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xDsk_SekRead		ldy	#jobFetch
			b $2c
:xDsk_SekWrite		ldy	#jobStash
			b $2c
:xDsk_SekVerify		ldy	#jobVerify
			b $2c
:xDsk_SekSwap		ldy	#jobSwap
:xDsk_DoSekJob		jsr	Save_RegData

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.
			jsr	xDoRAMOp		;Daten aus SCPU/C=REU/GRAM einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register zurücksetzen. Akku,
							;XReg,YReg werden nicht verändert.
			ldx	#NO_ERROR
			rts
endif
