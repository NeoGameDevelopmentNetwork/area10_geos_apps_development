; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** SuperCPU patchen.
;    Anpassung für MoveData, da diese Routine schneller ist als die
;    Standard-MoveData-Routine (16Bit-NativeMode).
:InitDeviceSCPU		lda	Device_SCPU		;SCPU verfügbar ?
			beq	:53			;=> Nein, weiter...

			ldy	#$00			;SCPU-Patches aktivieren.
::51			lda	Code6a        ,y
			sta	BASE_SCPU_DRV ,y
			iny
			cpy	#Code6L
			bcc	:51

			lda	#$4c			;Vektor ":InitForIO" verbiegen.
			sta	InitForIO   +0
			lda	#<sInitForIO
			sta	InitForIO   +1
			lda	#>sInitForIO
			sta	InitForIO   +2

			lda	#$4c			;Vektor ":DoneWithIO" verbiegen.
			sta	DoneWithIO  +0
			lda	#<sDoneWithIO
			sta	DoneWithIO  +1
			lda	#>sDoneWithIO
			sta	DoneWithIO  +2

			lda	#<si_MoveData		;Vektor ":i_MoveData" verbiegen.
			sta	i_MoveData  +1
			lda	#>si_MoveData
			sta	i_MoveData  +2

			lda	#<sMoveData		;Vektor ":MoveData" verbiegen.
			sta	MoveData    +1
			lda	#>sMoveData
			sta	MoveData    +2

			ldy	#$00			;Vektoren für SCPU-Optimierungen
::52			lda	Code8a,y		;verbiegen.
			sta	SCPU_PATCH_JMPTAB,y
			iny
			cpy	#Code8L
			bcc	:52

::53			rts
