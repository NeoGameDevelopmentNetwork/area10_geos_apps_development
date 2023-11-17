; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speicherbank berechnen.

;Der GEOS-DACC beginnt ab der ersten
;freien Speicherbank in der RAMCard.
;Das muss nicht unbedingt Bank#0 sein!
;Bank#0/#1 sind System-RAM, auch wenn
;keine RAMCard installiert ist.
;Ab Bank#2 beginnt der freie Speicher,
;dieser kann aber zuvor durch andere
;Anwendungen eingeschränkt worden sein.
;Beim Systemstart wird in RamBankFirst
;die erste freie Speicherbank abgelegt.
:DefBankAdrDACC		lda	RamBankFirst +1
			b $2c

;Der Laufwerkstreiber beginnt direkt an
;der angegebenen Speicherbank.
:DefBankAdrDISK		lda	#$00
			clc
			adc	r3L
			rts

;*** StashRAM-Routine (16-Bit NativeCode).
;    Übergabe:		AKKU	= Erste Speicherbank in SCPU.
:SCPU_STASH_RAM		sta	SCPU_HW_EN		;Hardware-Register einschalten.
							;Muss zu Beginn erfolgen da sonst
							;der Bereich ab $D300 nicht
							;verändert werden kann (SRAM-Patch)

			jsr	DefBankAdrSRAM		;Speicherbank berechnen.
			sta	:51 +1

			b $18				;clc
			b $fb				;xce
			b $c2,$30			;rep #$30

			b $a5,$06			;lda $0006
			b $3a				;dea
			b $a6,$02			;ldx $0002
			b $a4,$04			;ldy $0004
			b $8b				;phb
::51			b $54,$00,$00			;mvn $00.$00
			b $ab				;plb
			b $38				;sec
			b $fb				;xce

			sta	SCPU_HW_DIS		;Hardware-Register abschalten.
			rts

;*** FetchRAM-Routine (16-Bit NativeCode).
;    Übergabe:		AKKU	= Erste Speicherbank in SCPU.
:SCPU_FETCH_RAM		sta	SCPU_HW_EN		;Hardware-Register einschalten.
							;Muss zu Beginn erfolgen da sonst
							;der Bereich ab $D300 nicht
							;verändert werden kann (SRAM-Patch)

			jsr	DefBankAdrSRAM		;Speicherbank berechnen.
			sta	:51 +2

			b $18				;clc
			b $fb				;xce
			b $c2,$30			;rep #$30

			b $a5,$06			;lda $0006
			b $3a				;dea
			b $a6,$04			;ldx $0002
			b $a4,$02			;ldy $0004
			b $8b				;phb
::51			b $54,$00,$00			;mvn $00.$00
			b $ab				;plb
			b $38				;sec
			b $fb				;xce

			sta	SCPU_HW_DIS		;Hardware-Register abschalten.
			rts

;*** SwapRAM-Routine (16-Bit NativeCode).
;    Übergabe:		AKKU	= Erste Speicherbank in SCPU.
:SCPU_SWAP_RAM		sta	SCPU_HW_EN		;Hardware-Register einschalten.
							;Muss zu Beginn erfolgen da sonst
							;der Bereich ab $D300 nicht
							;verändert werden kann (SRAM-Patch)

			jsr	DefBankAdrSRAM		;Speicherbank berechnen.
			sta	:52 +3
			sta	:53 +3

			PushW	r0			;Register r0/r1 speichern.
			PushW	r1

			b $18				;clc
			b $fb				;xce
			b $c2,$10			;rep #$00010000

			b $a0,$00,$00			;ldy #$0000
::51			b $a6,$02			;ldx r0
			b $bf,$00,$00,$00		;lda $00:0000,x
			b $48				;pha
			b $a6,$04			;ldx r1
::52			b $bf,$00,$00,$00		;lda $??:0000,x
			b $a6,$02			;ldx r0
			b $9f,$00,$00,$00		;sta $00:0000,x
			b $e8				;inx
			b $86,$02			;stx r0
			b $68				;pla
			b $a6,$04			;ldx r1
::53			b $9f,$00,$00,$00		;sta $??:0000,x
			b $e8				;inx
			b $86,$04			;stx r1

			b $c8				;iny
			b $c4,$06			;cpy r2
			b $d0,$db			;bne :51

			b $38				;sec
			b $fb				;xce

			PopW	r1			;Register r0/r1 zurücksetzen.
			PopW	r0

			sta	SCPU_HW_DIS		;Hardware-Register abschalten.
			rts

;*** VerifyRAM-Routine (16-Bit NativeCode).
;    Übergabe:		AKKU	= Erste Speicherbank in SCPU.
:SCPU_VERIFY_RAM	sta	SCPU_HW_EN		;Hardware-Register einschalten.
							;Muss zu Beginn erfolgen da sonst
							;der Bereich ab $D300 nicht
							;verändert werden kann (SRAM-Patch)

			jsr	DefBankAdrSRAM		;Speicherbank berechnen.
			sta	:52 +3

			PushW	r0			;Register r0/r1/r3L speichern.
			PushW	r1
			PushB	r3L

			lda	#$ff			;Verify-Error als Rückgabewert
			sta	r3L			;vordefinieren.

			b $18				;clc
			b $fb				;xce
			b $c2,$10			;rep #$00010000

			b $a0,$00,$00			;ldy #$0000
::51			b $a6,$02			;ldx r0
			b $bf,$00,$00,$00		;lda $00:0000,x
			b $e8				;inx
			b $86,$02			;stx r0
			b $a6,$04			;ldx r1
::52			b $df,$00,$00,$00		;cmp $??:0000,x
			b $d0,$0a			;bne :53
			b $e8				;inx
			b $86,$04			;stx r1

			b $c8				;iny
			b $c4,$06			;cpy r2
			b $d0,$e7			;bne :51
			b $e6,$08			;inc r3L --> Verify OK.

::53			b $38				;sec
			b $fb				;xce

			ldx	r3L

			PopB	r3L			;Register r0/r1/r3L zurücksetzen.
			PopW	r1
			PopW	r0

			sta	SCPU_HW_DIS		;Hardware-Register abschalten.
			rts
