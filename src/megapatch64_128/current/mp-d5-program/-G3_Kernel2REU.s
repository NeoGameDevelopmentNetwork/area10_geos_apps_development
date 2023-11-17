; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Kernel in REU kopieren.
;******************************************************************************
;*** Aktuelles GEOS-Kernal in REU kopieren.
:CopyKernel2REU		lda	sysRAMFlg
			ora	#%00100000		;Flag "Kernal in REU gespeichert".
			sta	sysRAMFlg		;(für ReBoot-Funktion).

			jsr	SetLowBAdr		;Systemvariablen in REU kopieren.
			LoadB	r0H,$84			;C64: $8400-$88FF
			LoadB	r1H,$79			;REU: $7900-$7DFF
			LoadB	r2H,$05
			jsr	StashRAM

;			jsr	SetLowBAdr		;Laufwerkstreiber in REU kopieren.
;			LoadB	r0H,$90			;C64: $9000-$9D7F
;			LoadB	r1H,$83			;REU: $8300-$907F
;			LoadW	r2 ,$0d80		;(Entfällt, alle Treiber sind
;			jsr	StashRAM		; bereits in der REU!)

			jsr	SetLowBAdr		;Kernal Teil #1 in REU kopieren.
			lda	#$80			;C64: $9D80-$9FFF
			sta	r0L			;REU: $B900-$BB7F
			sta	r2L
			LoadB	r0H,$9d
			LoadB	r1H,$b9
			LoadB	r3L,$00
			LoadB	r2H,$02
			jsr	StashRAM

if Flag64_128 = TRUE_C64
			jsr	SetLowBAdr		;Kernal Teil #2 in REU kopieren.
			LoadW	r0,$bf40		;C64: $BF40-$CFFF
			LoadW	r1,$bb80		;REU: $BB80-$CC3F
			LoadW	r2,$10c0
			jsr	StashRAM
else
			jsr	SetLowBAdr		;Kernal Teil #2 in REU kopieren.
			LoadW	r0,$c000		;C128: $C000-$CFFF
			LoadW	r1,$bc40		;REU: $BC40-$CC3F
			LoadW	r2,$1000
			jsr	StashRAM
endif

			LoadB	r4L,$30
			LoadW	r5 ,$d000
			LoadW	r0 ,$8000		;Kernal Teil #3 in REU kopieren.
			LoadW	r1 ,$cc40		;C64: $D000-$FFFF
			LoadW	r2 ,$0100		;REU: $CC40-$FC3F
			LoadB	r3L,$00

::1			php
			sei
if Flag64_128 = TRUE_C128
			PushB	MMU
			LoadB	MMU,$7f
endif
			ldy	#$00
::2			lda	(r5L),y
			sta	diskBlkBuf +$00,y
			iny
			bne	:2
if Flag64_128 = TRUE_C128
			PopB	MMU
endif
			plp
			jsr	StashRAM
			inc	r5H
			inc	r1H
			dec	r4L
			bne	:1

if Flag64_128 = TRUE_C128
			LoadB	r4L,$40
			LoadW	r5 ,$c000
			LoadW	r0 ,$8000		;Kernal Teil #4 (Bank 0) in REU kopieren.
			LoadW	r1 ,$3900		;C128: $C000-$FFFF
			LoadW	r2 ,$0100		;REU: $3900-$78FF
			LoadB	r3L,$00

::3			php
			sei
			PushB	RAM_Conf_Reg
			LoadB	RAM_Conf_Reg,$4b	;16kByte Common Area oben = Bank 0
			PushB	MMU
			LoadB	MMU,$7f
			ldy	#$00
::4			lda	(r5L),y
			sta	diskBlkBuf +$00,y
			iny
			bne	:4
			PopB	MMU
			PopB	RAM_Conf_Reg
			plp
			jsr	StashRAM
			inc	r5H
			inc	r1H
			dec	r4L
			bne	:3
endif

			LoadW	r0,mousePicData		;Mauszeiger in REU kopieren.
			LoadW	r1,$fc40		;C64: mousePicData
			LoadW	r2,$003f		;REU: $fc40-$fc7f
			jmp	StashRAM

;*** LOW -Bytes für StashRAM/FetchRAM-Routinen setzen.
:SetLowBAdr		lda	#$00
			sta	r0L
			sta	r1L
			sta	r2L
			sta	r3L
			rts
