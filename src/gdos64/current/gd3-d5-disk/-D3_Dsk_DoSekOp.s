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
;Übergabe: r1   = Track/Sektor.
;          r3H  = Partitions-Nr.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
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

			jsr	EN_SET_REC		;RL-Hardware aktivieren.

			sty	EXP_BASE2 +$20		;Job-Code.

			lda	r1L			;RAMLink Track.
			sta	EXP_BASE2 +$21
			lda	r1H			;RAMLink Sector.
			sta	EXP_BASE2 +$22

			lda	r4L			;Computer Address.
			sta	EXP_BASE2 +$23
			lda	r4H
			sta	EXP_BASE2 +$24

			lda	r3H			;RAMLink Partition number.
			sta	EXP_BASE2 +$25

;			lda	#$01			;Bank in 128 for sector transfer.
;			sta	EXP_BASE2 +$26

			jsr	EXEC_REC_SEC		;Sektor-Jobcode ausführen.

			lda	EXP_BASE2 +$20		;Fehlerstatus einlesen und
			pha				;zwischenspeichern.
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.
			pla
			tax

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp				;IRQ-Status zurücksetzen.

::51			rts

;--- DoRAMOp-Routine für RAMLink.
			t "-D3_DoDISK_RLNK"

endif

;******************************************************************************
::tmp1 = RD_NM!RD_81!RD_71!RD_41
if :tmp1 = TRUE
;******************************************************************************
;*** Sektor über GEOS-Register einlesen.
;Übergabe: r1   = Track/Sektor.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:xDsk_SekRead		ldy	#jobFetch
			b $2c
:xDsk_SekWrite		ldy	#jobStash
			b $2c
:xDsk_SekVerify		ldy	#jobVerify
			b $2c
:xDsk_SekSwap		ldy	#jobSwap
:xDsk_DoSekJob		jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	DoRAMOp			;Daten aus RAMLink einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.
							;Akku,XReg,YReg unverändert!
			ldx	#NO_ERROR		;Flag für "Kein Fehler..."
			rts
endif

;******************************************************************************
::tmp2 = RD_NM_SCPU
if :tmp2 = TRUE
;******************************************************************************
;*** Sektor über GEOS-Register einlesen.
;Übergabe: r1   = Track/Sektor.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:xDsk_SekRead		ldy	#jobFetch
			b $2c
:xDsk_SekWrite		ldy	#jobStash
			b $2c
:xDsk_SekVerify		ldy	#jobVerify
			b $2c
:xDsk_SekSwap		ldy	#jobSwap
:xDsk_DoSekJob		jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	DoRAMOp_DISK		;Daten aus SCPU/C=REU/GRAM einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.
							;Akku,XReg,YReg unverändert!
			ldx	#NO_ERROR
			rts

;--- DoRAMOp-Routine für RAMCard.
			t "-D3_DoDISK_SRAM"
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"
endif

;******************************************************************************
::tmp3 = RD_NM_CREU
if :tmp3 = TRUE
;******************************************************************************
;*** Sektor über GEOS-Register einlesen.
;Übergabe: r1   = Track/Sektor.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:xDsk_SekRead		ldy	#jobFetch
			b $2c
:xDsk_SekWrite		ldy	#jobStash
			b $2c
:xDsk_SekVerify		ldy	#jobVerify
			b $2c
:xDsk_SekSwap		ldy	#jobSwap
:xDsk_DoSekJob		jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	DoRAMOp_DISK		;Daten aus SCPU/C=REU/GRAM einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.
							;Akku,XReg,YReg unverändert!
			ldx	#NO_ERROR
			rts

;--- DoRAMOp-Routine für C=REU.
			t "-D3_DoDISK_CREU"
			t "-R3_DoRAMOpCREU"
endif

;******************************************************************************
::tmp4 = RD_NM_GRAM
if :tmp4 = TRUE
;******************************************************************************
;*** Sektor über GEOS-Register einlesen.
;Übergabe: r1   = Track/Sektor.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:xDsk_SekRead		ldy	#jobFetch
			b $2c
:xDsk_SekWrite		ldy	#jobStash
			b $2c
:xDsk_SekVerify		ldy	#jobVerify
			b $2c
:xDsk_SekSwap		ldy	#jobSwap
:xDsk_DoSekJob		jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	DoRAMOp_DISK		;Daten aus SCPU/C=REU/GRAM einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.
							;Akku,XReg,YReg unverändert!
			ldx	#NO_ERROR
			rts

;--- DoRAMOp-Routine für GeORAM.
			t "-D3_DoDISK_GRAM"
			t "-R3_DoRAMOpGRAM"
endif
