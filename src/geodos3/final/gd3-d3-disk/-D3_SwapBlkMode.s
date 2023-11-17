; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0b = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Modus für aktuellen Block wechseln.
;    BAM wird als "geändert" markiert!
:SwapBlockMode		lda	r8H
			eor	dir2Head,x
			sta	dir2Head,x

			ldx	#$ff			;Flag setzen "BAM geändert".
			stx	BAM_Modified
			inx				;Kein Fehler, Ende...
;			ldx	#NO_ERROR
			rts
endif

;******************************************************************************
::tmp1 = RL_41!RD_41!C_41!FD_41!HD_41!HD_41_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Modus für aktuellen Block wechseln.
;    BAM wird als "geändert" markiert!
:SwapBlockMode		lda	r8H
			eor	curDirHead,x
			sta	curDirHead,x
			and	r8H
			bne	:51

			ldx	r7H			;Anzahl freier Sektoren auf
			dec	curDirHead,x		;aktuellem Track korrigieren.
			ldx	#NO_ERROR
			rts

::51			ldx	r7H			;Anzahl freier Sektoren auf
			inc	curDirHead,x		;aktuellem Track korrigieren.
			ldx	#NO_ERROR
			rts
endif

;******************************************************************************
::tmp2 = RL_71!RD_71!C_71!FD_71!HD_71!HD_71_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Modus für aktuellen Block wechseln.
;    BAM wird als "geändert" markiert!
:SwapBlockMode		php				;Z-Flag sichern.
			CmpBI	r6L,36			;Track-Adresse #1 bis #35 ?
			bcc	:51			;Ja, weiter...
			lda	r8H			;Bit in BAM wechseln, damit
			eor	dir2Head  ,x		;Sektor freigeben/belegen.
			sta	dir2Head  ,x
			jmp	:52			;Anzahl freie Sektoren korrigieren.

::51			lda	r8H			;Bit in BAM wechseln, damit
			eor	curDirHead,x		;Sektor freigeben/belegen.
			sta	curDirHead,x

::52			ldx	r7H			;Zeiger auf Sektor-Zähler.
			plp				;Z-Flag wieder einlesen.
			beq	:53			; => Sektor freigeben.
			dec	curDirHead,x		; => Sektor belegen.
			jmp	:54

::53			inc	curDirHead,x
::54			ldx	#NO_ERROR
			rts
endif

;******************************************************************************
::tmp3 = RL_81!RD_81!C_81!FD_81!HD_81!HD_81_PP
if :tmp3 = TRUE
;******************************************************************************
;*** Modus für aktuellen Block wechseln.
;    BAM wird als "geändert" markiert!
:SwapBlockMode		php
			lda	r6L
			cmp	#41			;Track #1 bis #40 ?
			bcc	:52			;Ja, Sonderbehandlung...

			lda	r8H
			eor	dir3Head +16,x
			sta	dir3Head +16,x
			ldx	r7H
			plp
			beq	:51
			dec	dir3Head +16,x		;Sektor belegen.
			jmp	:54			;Weiter...

::51			inc	dir3Head +16,x		;Sektor freigeben.
			ldx	#NO_ERROR
			rts

::52			lda	r8H
			eor	dir2Head +16,x
			sta	dir2Head +16,x
			ldx	r7H
			plp
			beq	:53
			dec	dir2Head +16,x		;Sektor belegen.
			jmp	:54			;Weiter...

::53			inc	dir2Head +16,x		;Sektor freigeben.
::54			ldx	#NO_ERROR
			rts
endif
