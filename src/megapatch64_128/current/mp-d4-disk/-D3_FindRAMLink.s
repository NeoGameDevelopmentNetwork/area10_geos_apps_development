; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_41!RL_71!RL_81!RL_NM
if :tmp0 = TRUE
;******************************************************************************
;*** RL_Laufwerk suchen.
:FindRAMLink		jsr	xExitTurbo
			jsr	InitForIO

			lda	RL_DEV_ADDR		;Ist RL-Adresse bereits definiert ?
			beq	:51			; => Nein, weiter...
			jsr	TestRL_Device		;RAMLink-Adresse testen.
			txa				;RL gefunden ?
			beq	:exit			; => Ja, Ende...

;--- Diese Routine wird beim ersten Aufruf des Treibers aktiviert und wenn
;    von der RL mit einer anderen Adresse gebootet wurde.
::51			lda	#$08
			sta	RL_DEV_ADDR

::52			jsr	TestRL_Device
			txa
			beq	:exit

			inc	RL_DEV_ADDR
			lda	RL_DEV_ADDR
			cmp	#30
			bcc	:52

			lda	#$00
			sta	RL_DEV_ADDR

;			ldx	#DEV_NOT_FOUND
::exit			jmp	DoneWithIO

;*** RAMLink-Laufwerk suchen.
:TestRL_Device		ldx	#> :com_MR_CMD
			lda	#< :com_MR_CMD
			ldy	#6
			jsr	SendComVLen		;CMD-Kennung lesen.
			bne	:52			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:52			;Fehler? => Ja, Abbruch...

			ldy	#0
			sty	d1L
::51			jsr	ACPTR			;RAMLink-Kennung einlesen und
			eor	:cmd_RL,y		;mit CMD-Kennung abgleichen.
			ora	d1L
			sta	d1L			;Neuen Prüfwert speichern.
			iny
			cpy	#6
			bne	:51

			jsr	UNTALK			;Laufwerk abschalten.

			ldx	d1L			;Prüfwert OK?
			beq	:52			; => Ja, Ende...

			ldx	#DEV_NOT_FOUND		;Keine RAMLink.
::52			rts

::cmd_RL		b "CMD RL"
::com_MR_CMD		b "M-R",$a0,$fe,$06
endif
