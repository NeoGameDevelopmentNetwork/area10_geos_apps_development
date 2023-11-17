; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor auf Diskette vergleichen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xVerWriteBlock		jsr	IsSekInRAM_OK		;Sektor in ShadowRAM gespeichert ?
			bcc	:exitVerBlock

::verify		lda	#$03
			sta	:retryVerify

			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit_verify		; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit_verify		; => Ja, Abbruch...

::loop			jsr	sendFComU1		;Block lesen.
			txa				;Fehler?
			bne	:retry			; => Ja, wiederholen.

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L			;Zeiger auf Daten an
			ldx	r4H			;GET-Routine übergeben.
			jsr	verDataBytes		;Datenbytes vergleichen.
			txa
			beq	:exit_verify

::retry			dec	:retryVerify
			bne	:loop

::exit_verify		pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			tax				;Fehler in xReg übergeben.
			beq	:updRAMBuf

;			ldx	#VER_WR_ERR		;Durch ":verDataBytes gesetzt.
			inc	RepeatFunction
			ldy	RepeatFunction
			cpy	#$05
			beq	:exitVerBlock
			tya
			pha
			jsr	xWriteBlock		;Block erneut schreiben.
			pla
			sta	RepeatFunction
			txa				;Fehler?
			beq	:verify			;Nein => Verify ausführen.
			bne	:exitVerBlock

::updRAMBuf		bit	curType			;Shadow-Laufwerk?
			bvc	:exitVerBlock		; => Nein, weiter...

			jsr	SaveSekInRAM		;Shadow-RAM aktualisieren.

::exitVerBlock		rts

::retryVerify		b $00
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor auf Diskette vergleichen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xVerWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:exitVerBlock		;Nein, Abbruch...

::verify		lda	#$03
			sta	:retryVerify

			jsr	setTrSeAdr

			jsr	openFComChan		;Befehlskanal öffnen.
			txa				;Fehler?
			bne	:exit_verify		; => Ja, Abbruch...

			jsr	openDataChan		;Datenkanal öffnen.
			txa				;Fehler?
			bne	:exit_verify		; => Ja, Abbruch...

::loop			jsr	sendFComU1		;Block lesen.
			txa				;Fehler?
			bne	:retry			; => Ja, wiederholen.

			jsr	setBufPointer		;Buffer-Pointer auf Anfang.

			lda	r4L			;Zeiger auf Daten an
			ldx	r4H			;GET-Routine übergeben.
			jsr	verDataBytes		;Datenbytes vergleichen.
			txa
			beq	:exit_verify

::retry			dec	:retryVerify
			bne	:loop

::exit_verify		pha
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			pla
			tax				;Fehler in xReg übergeben.
			beq	:exitVerBlock

;			ldx	#VER_WR_ERR		;Durch ":verDataBytes" gesetzt.
			inc	RepeatFunction
			ldy	RepeatFunction
			cpy	#$05
			beq	:exitVerBlock
			tya
			pha
			jsr	xWriteBlock		;Block erneut schreiben.
			pla
			sta	RepeatFunction
			txa				;Fehler?
			beq	:verify			;Nein => Verify ausführen.

::exitVerBlock		rts

::retryVerify		b $00
endif

;******************************************************************************
::tmp2a = C_81!IEC_NM!S2I_NM
::tmp2b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp2  = :tmp2a!:tmp2b
if :tmp2!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Sektor auf Diskette vergleichen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
;--- Hinweis#1:
;In TurboDOS-Treibern aus Platzgründen
;bei 1581/CMD nicht implementiert bzw.
;nicht erforderlich.
;Das Verhalten entspricht dem Original
;GEOS-1581-Treiber.
;--- Hinweis#2:
;Im GEOS-RAM81-Treiber wird hier nur
;die Sektoradresse geprüft.
;":VerWriteBlock" wurde daher aus allen
;Treibern ausser 1541/1571 entfernt.
:xVerWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:51			;Nein, Abbruch...

			ldx	#NO_ERROR		;Kein Fehler.
::51			rts
endif
