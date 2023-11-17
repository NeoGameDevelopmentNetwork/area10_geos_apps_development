; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Sektor aus BAM einlesen und nach ":dir2Head" einlesen.
;    Übergabe:		AKKU	= BAM-Sektor (#2 bis #33).
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBAMBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			ldx	#NO_ERROR		;Flag für "Kein Fehler".
			cmp	CurSek_BAM		;BAM-Sektor bereits im Speicher ?
			beq	EndBAMBlock		; => Ja, Ende...

			bit	BAM_Modified		;BAM im Speicher geändert ?
			bpl	:51			; => Nein, weiter...

			pha				;BAM-Sektor im Speicher auf
			jsr	xPutBAMBlock		;Diskette speichern.
			pla
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	EndBAMBlock		; => Ja, Abbruch...

::51			tax
			ldy	#$ff
			bne	JobBAMBlock

;*** BAM-Sektor auf Diskette aktualisieren.
;    Übergabe:		AKKU	= BAM-Sektor (#2 bis #33).
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBAMBlock		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			ldx	#NO_ERROR		;Flag für "Kein Fehler".
			bit	BAM_Modified		;BAM im Speicher geändert ?
			bpl	EndBAMBlock		; => Nein, weiter...

			ldx	CurSek_BAM
			ldy	#$00

;*** BAM-Sektor lesen/schreiben.
;    Übergabe:		xReg = Nr. des BAM-Sektors.
;			yReg = $00, Sektor schreiben.
;			     = $FF, Sektor lesen.
;    Rückgabe:		-
;    Geändert:		-
:JobBAMBlock		PushW	r1			;Register ":r1"/":r4" retten.
			PushW	r4

			stx	r1H			;Sektoradresse berechnen.
			ldx	#$01
			stx	r1L
			dex
;			ldx	#<dir2Head		;Zeiger auf BAM-Speicher.
			stx	r4L
			ldx	#>dir2Head
			stx	r4H
			tya				;Sektor lesen ?
			bmi	:51			; => Ja, weiter...

			jsr	Job_PutBAMsek		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...
			beq	:52

::51			jsr	Job_GetBAMsek		;Sektor von Diskette lesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			lda	r1H			;BAM-Sektor-Adresse speichern.
			sta	CurSek_BAM

::52			stx	BAM_Modified		;Flag löschen "BAM geändert".

::53			PopW	r4			;Register ":r1"/":r4" zurücksetzen.
			PopW	r1

:EndBAMBlock		plp				;IRQ-Status zurücksetzen.
			rts

;*** BAM-Sektor von Diskette lesen.
;    I/O-Modus testen und ":GetBlock"/":ReadBlock" ausführen.
:Job_GetBAMsek		bit	IO_Activ		;I/O-Modus aktiv ?
			bmi	:51			; => Ja, weiter...
			jmp	xGetBlock
::51			jmp	xReadBlock

;*** BAM-Sektor auf Diskette schreiben.
;    I/O-Modus testen und ":GetBlock"/":ReadBlock" ausführen.
:Job_PutBAMsek		bit	IO_Activ		;I/O-Modus aktiv ?
			bmi	:51			; => Ja, weiter...
			jmp	xPutBlock
::51			jmp	xWriteBlock
endif
