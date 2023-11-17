; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L351: Anzahl freier Bytes berechnen.
:Max_Free		jsr	DefDbr
			sta	Free_Clu
			stx	Free_Clu+1

			sec
			lda	Anz_Sektor
			sbc	Free_Clu
			sta	Free_Clu
			lda	Anz_Sektor+1
			sbc	Free_Clu+1
			sta	Free_Clu+1

			MoveW	BpSek,Clu_Byte

			lda	SpClu
::1			lsr				;Anz. Byte pro Cluster
			tax				;und Anzahl Cluster
			beq	:2			;berechnen.
			RORWord	Free_Clu
			ROLWord	Clu_Byte
			txa
			jmp	:1

::2			LoadFAC	Free_Clu
			jsr	MOVFA
			LoadFAC	Clu_Byte
			jsr	x_MULT
			ldx	#<Free_Byte
			ldy	#>Free_Byte
			jsr	MOVFM

			MoveW	Free_Clu,Free_Sek

			ldx	SpClu			;Anz. Byte proCluster
::3			dex				;und anzahl Cluster
			beq	:4			;berechnen.
			ROLWord	Free_Sek
			jmp	:3

::4			rts

:Free_Byte		s	$06
:Free_Sek		w	$0000
:Free_Clu		w	$0000
:Clu_Byte		w	$0000

