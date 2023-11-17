; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.Patch_SCPU"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o BASE_SCPU_DRV

			r BASE_SCPU_DRV +SIZE_SCPU_DRV

			h "MegaPatch-Kernal"
			h "SCPU-Funktionen..."

:_SCPU_START
;******************************************************************************
;*** 16Bit-FillRAM-Routine.
;******************************************************************************
;*** Speicherbereich löschen.
:s_ClearRam		lda	#$00			;Füllbyte $00.
			sta	r2L

:s_FillRam		php
			sei
			txa				;X-Register zwischenspeichern.
			pha				;(Original-Routine verwendet
							; nur A/Y-Register!)
			clc
			b $fb				;xce
			b $c2,$10			;rep #$00010000

			b $a2,$00,$00			;ldx #$0000
			b $a4,$04			;ldy r1
			b $a5,$06			;lda r2L
::51			b $99,$00,$00			;sta $0000,y
			b $c8				;iny
			b $e8				;inx
			b $e4,$02			;cpx r0
			b $d0,$f7			;bne :51

			b $38				;sec
			b $fb				;xce

			pla
			tax
			plp
			rts

;******************************************************************************
;*** 16Bit-MoveData-Routine.
;******************************************************************************
;*** Inline: Speicher verschieben.
:s_i_MoveData		pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			jsr	Get2Word1Byte
			iny
			lda	(returnAddress),y
			sta	r2H
			jsr	s_MoveData
			jmp	Exit7ByteInline

;*** Speicherbereich veschieben.
:s_MoveData		lda	r2L
			ora	r2H			;Anzahl Bytes = $0000 ?
			beq	:51			;Ja, -> Keine Funktion.

			txa				;X-Register sichern.
			pha
			jsr	DoMove			;MoveData ausführen.
			pla
			tax				;X-Register zurücksetzen.

::51			rts

:DoMove			php				;IRQ sperren.
			sei

			b $18				;clc
			b $fb				;xce
			b $c2,$30			;rep #$30

			b $a5,$02			;lda $0002
			b $c5,$04			;cmp $0004
			b $90,$0e			;bcc CopyDown

			b $a5,$06			;lda $0006
			b $3a				;dea
			b $a6,$02			;ldx $0002
			b $a4,$04			;ldy $0004

			b $54,$00,$00			;mvn $00.$00

			b $38				;sec
			b $fb				;xce
			plp				;(Pause/Umschalten auf 8Bit!!)
			rts

:CopyDown		b $a5,$06			;lda $0006
			b $3a				;dea
			b $48				;pha
			b $18				;clc
			b $65,$02			;adc $0002
			b $aa				;tax
			b $68				;pla
			b $48				;pha
			b $18				;clc
			b $65,$04			;adc $0004
			b $a8				;tay
			b $68				;pla

			b $44,$00,$00			;mvp $00.$00

			b $38				;sec
			b $fb				;xce
			plp				;(Pause/Umschalten auf 8Bit!!)
			rts

;******************************************************************************
;*** Neue SuperCPU-I/O-Routinen.
;******************************************************************************
:s_InitForIO		jsr	:54			;InitForIO aufrufen.

			lda	$d0b8			;Aktuellen Takt einlesen und
			sta	s_DoneWithIO +1		;zwischenspeichern.

			ldy	curDrive
			lda	RealDrvMode -8,y
			and	#SET_MODE_FASTDISK	;Laufwerkstyp RAM ?
			bne	:53			;Ja, weiter...

;--- Ergänzung: 02.07.18/M.Kanet
;Diese Abfrage auf 64Net ist in der 128er-Version von
;2003 nicht enthalten.
;if Flag64_128 = TRUE_C128
;			ldy	#4			;wenn 64Net Treiber aktiv
;::51			lda	:Net,y			;dann ebenfalls auf 20Mhz
;			cmp	$904f,y			;bleiben
;			bne	:52			;Im Treiber ab $904f steht
;			dey				;'64NET'
;			bpl	:51
;			rts
;::Net			b	"64NET"
;endif

::52			sta	$d07a			;Umschalten auf 1Mhz.
::53			rts

::54			jmp	($9000)			;InitForIO aufrufen.

:s_DoneWithIO		lda	#$ff			;Speed-Flag testen.
			bmi	:51			;War 20Mhz-Modus aktiv ?
			sta	$d07b			; => Ja, auf 20Mhz umschalten.
::51			jmp	($9002)			;DoneWithIO aufrufen.

;******************************************************************************
;*** GEOS optimieren.
;******************************************************************************
:s_SCPU_OptOn		ldy	#$00			;Flag: GEOS-Optimieren.
			b $2c
:s_SCPU_OptOff		ldy	#$03			;Flag: GEOS nicht optimieren.
			sty	Flag_Optimize		;Modus merken.

:s_SCPU_SetOpt		php
			sei				;IRQ abschalten.

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			ldx	MMU
			lda	#$7e
			sta	MMU
endif

if Flag64_128 = TRUE_C64
			ldy	Flag_Optimize		;Modus merken.
			sta	$d07e			;Hardware-Register einschalten.
			sta	$d074,y			;Optimierung setzen.
			sta	$d07f			;Hardware-Register ausschalten.
endif
if Flag64_128 = TRUE_C128
			ldy	Flag_Optimize		;Modus merken.
			sta	$d07e			;Hardware-Register einschalten.
			bne	:1			;-> keine Optimierung
			lda	graphMode		;Bildschirmmodus einlesen.
			bmi	:2			;-> 80Z.
			lda	#%00000010		;40/80Z. Optimierung
			b	$2c
::2			lda	#%10000100		;nur 80Z. Opt. -> schneller,
			b	$2c			;aber 40Z. nicht nutzbar!
::1			lda	#%11000001
			sta	$d0b3
			sta	$d07f			;Hardware-Register ausschalten.
endif

if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			stx	MMU
endif

			plp				;IRQ zurücksetzen.
			rts

;******************************************************************************
;*** SuperCPU-Routinen.
;******************************************************************************
.sClearRam		= s_ClearRam
.sFillRam		= s_FillRam
.si_MoveData		= s_i_MoveData
.sMoveData		= s_MoveData
.sInitForIO		= s_InitForIO
.sDoneWithIO		= s_DoneWithIO
.sSCPU_OptOn		= s_SCPU_OptOn
.sSCPU_OptOff		= s_SCPU_OptOff
.sSCPU_SetOpt		= s_SCPU_SetOpt
;******************************************************************************
:_SCPU_END
.Patch_SCPU_SIZE	= _SCPU_END - _SCPU_START
