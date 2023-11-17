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
:FindRAMLink		jsr	xExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

;--- Gespeicherte Adresse testen.
			lda	sysRAMLink		;Ist RL-Adresse bereits definiert ?
			beq	:1			; => Nein, weiter...
			jsr	TestRL_Device		;RAMLink-Adresse testen.
			txa				;RAMLink gefunden ?
			beq	:ramlink_found		; => Ja, Ende...

;--- Default-Adresse testen.
::1			lda	#5
			jsr	getRLSysData		;Systemblock einlesen.

			lda	dir3Head +225		;Default-RAMLink-Adresse
			sta	sysRAMLink		;einlesen.
			jsr	TestRL_Device		;RAMLink-Adresse testen.
			txa				;RAMLink gefunden ?
			beq	:ramlink_found		; => Ja, Ende...

;--- Geräteadressen #8-30 testen.
			lda	#8
			sta	sysRAMLink		;Geräteadresse initialisieren.

::2			jsr	TestRL_Device		;RAMLink-Adresse testen.
			txa				;RAMLink gefunden ?
			beq	:ramlink_found		; => Ja, Ende...

			inc	sysRAMLink
			lda	sysRAMLink		;Weiter mit nächster Adresse.
			cmp	#30			;Alle Adressen getestet?
			bcc	:2			; => Nein, weiter...

;--- RAMLink nicht gefunden.
			lda	#$00			;RAMLink nicht gefunden.
			sta	sysRAMLink

;			ldx	#DEV_NOT_FOUND
;			b $2c

;--- RAMLink gefunden.
::ramlink_found
;			ldx	#NO_ERROR
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Geräteadresse auf RAMLink testen.
:TestRL_Device		ldx	#> :com_READROM
			lda	#< :com_READROM
			ldy	#6
			jsr	SendComVLen		;CMD-Kennung lesen.
			bne	:err			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:err			;Fehler? => Ja, Abbruch...

			jsr	ACPTR			;RAMLink-Kennung einlesen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla

			ldx	#NO_ERROR
			cmp	#"R"			;Prüfwert OK?
			beq	:exit			; => Ja, Ende...

::err			ldx	#DEV_NOT_FOUND		;Keine RAMLink.
::exit			rts

::com_READROM		b "M-R"				;"M-R"-Laufwerksbefehl.
			w $fea4				;$FEA0: "CMD RL"
			b $01				;Nur 1 Byte = "R" einlesen...
endif
