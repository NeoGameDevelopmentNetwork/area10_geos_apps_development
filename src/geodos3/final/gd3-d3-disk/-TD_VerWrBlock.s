; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor auf Diskette vergleichen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xVerWriteBlock		jsr	IsSekInRAM_OK		;Sektor in ShadowRAM gespeichert ?
			bcc	:54

::51			lda	#$03
			sta	RepeatVerify
::52			ldx	#> TD_VerSekData
			lda	#< TD_VerSekData
			jsr	xTurboRoutSet_r1
			jsr	xGetDiskError		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:53			;Nein, weiter...

			dec	RepeatVerify		;Verify beendet?
			bne	:52			; => Nein, nochmal vergleichen...

			ldx	#WR_VER_ERR
			inc	RepeatFunction		;Wiederholungszähler setzen.
			lda	RepeatFunction
			cmp	#$05			;Alle Versuche fehlgeschlagen?
			beq	:54			;Ja, Abbruch...
			pha
			jsr	WriteBlock		;Sektor nochmals schreiben.
			pla				;Wiederholungszähler zurücksetzen.
			sta	RepeatFunction
			txa				;Wurde Sektor korrekt gespeichert?
			beq	:51			;Ja, Sektor nochmals vergleichen.
			bne	:54

::53			bit	curType
			bvc	:54

			jsr	SaveSekInRAM

::54			rts

:RepeatVerify		b $00
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Sektor auf Diskette vergleichen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xVerWriteBlock		jsr	TestTrSe_ADDR		;Ist Track/Sektor-Adresse gültig ?
			bcc	:54			;Nein, Abbruch...

			ldx	#$00
::51			lda	#$03
			sta	RepeatVerify

::52			jsr	Turbo_GetBlock
			sty	d1L

			lda	#$51			;Assembler-Befehl definieren:
			sta	Def_AssCode1		; eor (d0L),Y
			lda	#$85			;Assembler-Befehl definieren:
			sta	Def_AssCode2		; sta d1L

			jsr	Turbo_GetBytes

			lda	#$91			;Assembler-Befehl definieren:
			sta	Def_AssCode1		; sta (d0L),Y
			lda	#$05			;Assembler-Befehl definieren:
			sta	Def_AssCode2		; ora d1L

			lda	d1L
			pha
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
			pla
			cpx	#NO_ERROR		;Fehler?
			bne	:53			;Nein, weiter...

			tax				;Sektor-Verify OK?
			beq	:54			; => Ja, weiter...
			ldx	#WR_VER_ERR

::53			dec	RepeatVerify		;Verify beendet?
			bne	:52			; => Nein, nochmal vergleichen...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			lda	RepeatFunction
			cmp	#$05			;Alle Versuche fehlgeschlagen ?
			beq	:54			;Ja, Abbruch...
			pha
			jsr	xWriteBlock		;Sektor nochmals schreiben.
			pla				;Wiederholungszähler zurücksetzen.
			sta	RepeatFunction
			txa				;Wurde Sektor korrekt gespeichert ?
			beq	:51			;Ja, Sektor nochmals vergleichen.
::54			rts

:RepeatVerify		b $00
endif

;******************************************************************************
::tmp2a = C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp2b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!RL_41!RL_71!RL_81!RL_NM
::tmp2c = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp2  = :tmp2a!:tmp2b!:tmp2c
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
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
