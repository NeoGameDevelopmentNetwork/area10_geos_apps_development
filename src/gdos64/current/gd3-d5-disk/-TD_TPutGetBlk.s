; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_71
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor-Daten über TurboDOS an Floppy senden.
:Turbo_PutBlock		lda	#< TD_WrSekData
			ldx	#> TD_WrSekData
			bne	Turbo_SetBlock

;*** Sektor-Daten über TurboDOS aus Floppy einlesen.
:Turbo_GetBlock		lda	#< TD_RdSekData
			ldx	#> TD_RdSekData
:Turbo_SetBlock		jsr	xTurboRoutSet_r1

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET/SEND-Routine übergeben.

			ldy	#$00
			rts
endif

;******************************************************************************
::tmp1 = S2I_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor-Daten über TurboDOS an Floppy senden.
:Turbo_PutBlock		lda	#< TD_WrSekData
			ldx	#> TD_WrSekData
			bne	Turbo_SetBlock

;*** Sektor-Daten über TurboDOS aus Floppy einlesen.
;--- Ergänzung: 17.10.18/M.Kanet
;Das SD2IEC arbeitet auch mit dem TurboDOS der 1581 und kann damit die Spuren
;1-127 lesen und schreiben. Um nur die beiden Link-Bytes einzulesen setzt das
;TurboDOS der 1581 aber Bit#7 in der Spur-Adresse. Damit kann das TurboDOS der
;1581 keine Spuren oberhalb von 128 lesen.
;Der SD2IEC-Treiber nutzt dazu jetzt den ReadSektor-Einsprung für die 1571 da
;es diese Option hier nicht gibt.
:Turbo_GetBlock		lda	#< TD_RdSekData71
			ldx	#> TD_RdSekData71
:Turbo_SetBlock		jsr	xTurboRoutSet_r1

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET/SEND-Routine übergeben.

			ldy	#$00
			rts
endif
