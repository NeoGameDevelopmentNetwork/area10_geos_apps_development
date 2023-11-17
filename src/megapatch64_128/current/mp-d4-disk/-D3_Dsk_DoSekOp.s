; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = Flag64_128!RL_NM!RL_81!RL_71!RL_41
if :tmp0 = TRUE_C64!TRUE
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

			tya
			pha
			jsr	EN_SET_REC		;RL-Hardware aktivieren.
			pla				;Sektor-Daten setzen.
			sta	$de20

			lda	r1L			;RAMLink Track.
			sta	$de21
			lda	r1H			;RAMLink Sector.
			sta	$de22

			lda	r4L			;Computer Address.
			sta	$de23
			lda	r4H
			sta	$de24

			lda	r3H			;RAMLink Partition number.
			sta	$de25

;			lda	#$01			;Bank in 128 for sector transfer.
;			sta	$de26			;(Always GEOS FrontRAM Bank 1)

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
::tmp1 = Flag64_128!RL_NM!RL_81!RL_71!RL_41
if :tmp1 = TRUE_C128!TRUE
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
:xDsk_DoSekJob		php				;IRQ-Status zwischenspeichern
			jsr	InitRLKonfig		;RL-Konfiguration einschalten

			pha
			jsr	EN_SET_REC		;RL-Hardware aktivieren.
			pla				;Sektor-Daten setzen.
			sta	$de20

			lda	r1L			;RAMLink Track.
			sta	$de21
			lda	r1H			;RAMLink Sector.
			sta	$de22

			lda	r4L			;Computer Address.
			sta	$de23
			lda	r4H
			sta	$de24

			lda	r3H			;RAMLink Partition number.
			sta	$de25

			lda	#$01			;Bank in 128 for sector transfer.
			sta	$de26			;(Always GEOS FrontRAM Bank 1)

			jsr	EXEC_REC_SEC		;Sektor-Jobcode ausführen.

			lda	$de20			;Fehlerstatus einlesen und
			pha				;zwischenspeichern.
			jsr	ExitRLKonfig
			pla
			tax

			plp				;IRQ-Status zurücksetzen.

::51			rts

:ExitRLKonfig		jsr	RL_HW_DIS2		;RL-Hardware abschalten.
:LastRAM_Conf_Reg	lda	#$00			;wird gesetzt
			sta	RAM_Conf_Reg		;Konfiguration rücksetzen
:LastMMU		lda	#$00			;wird gesetzt
			sta	MMU			;Konfiguration rücksetzen
			rts

:InitRLKonfig		sei				;und IRQs sperren.
			lda	MMU			;Konfiguration sichern
			sta	LastMMU+1
			LoadB	MMU,%01001110		;Ram1 bis $bfff + IO + Kernal
							;I/O-Bereich und Kernal für
							;RAMLink-Transfer aktivieren.
			lda	RAM_Conf_Reg		;Konfiguration sichern
			sta	LastRAM_Conf_Reg+1
			and	#%11110000
			ora	#%00000100		;Common Area $0000 bis $0400
			sta	RAM_Conf_Reg
			tya
			rts
endif

;******************************************************************************
::tmp2 = RD_NM!RD_81!RD_71!RD_41
if :tmp2 = TRUE
;******************************************************************************
;*** Sektor über GEOS-Routinen einlesen.
;Übergabe: r1   = Track/Sektor.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:xDsk_SekRead		ldy	#%10010001
			b $2c
:xDsk_SekWrite		ldy	#%10010000
			b $2c
:xDsk_SekVerify		ldy	#%10010011
			b $2c
:xDsk_SekSwap		ldy	#%10010010
:xDsk_DoSekJob		jsr	Save_RegData

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	DoRAMOp			;Daten aus GEOS-DACC einlesen.
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
;*** Sektor über GEOS-Routinen einlesen.
;Übergabe: r1   = Track/Sektor.
;          r4   = Sektorspeicher.
;Rückgabe: -
;Geändert: AKKU,xReg,yReg
;
:xDsk_SekRead		ldy	#%10010001
			b $2c
:xDsk_SekWrite		ldy	#%10010000
			b $2c
:xDsk_SekVerify		ldy	#%10010011
			b $2c
:xDsk_SekSwap		ldy	#%10010010
:xDsk_DoSekJob		jsr	Save_RegData

;			tya
;			pha
			jsr	DefSekAdrREU		;Sektor-Adresse berechnen.
;			pla
;			tay

			LoadW	r2,$0100		;Anzahl Bytes.
			MoveW	r4,r0			;Zeiger auf C64-Speicher.

			jsr	DoRAMOp_DISK		;Daten aus SCPU/C=REU/GRAM einlesen.
							;Ergebnis-Code im AKKU.

			jsr	Load_RegData		;Register zurücksetzen. Akku,
							;XReg,YReg werden nicht verändert.
			ldx	#NO_ERROR
			rts
endif
