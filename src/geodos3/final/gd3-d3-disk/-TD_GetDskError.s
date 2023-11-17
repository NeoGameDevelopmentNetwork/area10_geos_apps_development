; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81
::tmp0b = FD_41!FD_71!FD_81!FD_NM!PC_DOS!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Diskettenstatus einlesen.
:xGetDiskError		ldx	#> TD_SendStatus	;Floppy dazu veranlassen den
			lda	#< TD_SendStatus	;Fehlerstatus über den ser. Bus
			jsr	xTurboRoutine		;zu senden.

;*** Fehlercode von Laufwerk einlesen.
:readErrByte		lda	#> ErrorCode		;Fehlercode über ser. Bus
			sta	d0H			;einlesen.
			lda	#< ErrorCode
			sta	d0L

;--- Hinweis:
;Hier sendet das TurboDOS im Laufwerk
;die Anzahl zu empfangender Fehlerbytes
;an diese Routine.
			ldy	#$01			;Fehlercode aus Floppy-Programm
			jsr	Turbo_GetBytes		;abfragen.
;--- Hinweis:
;Im Akku werden die Anzahl an Bytes
;vom TurboDOS übergeben die danach über
;den ser.Bus gesendet werden.
;Die Anzahl wird später nicht genutzt,
;daher Wert nicht zwischenspeichern.
;			pha				;Anzahl Bytes auf Stack retten.
			tay				;Anzahl Bytes empfangen.
;--- Hinweis:
;Sollte durch einen Fehler mehr als
;ein Byte empfangen werden, dann wird
;hier Programmcode überschrieben!
;Bei Tests mit VICE/Warp-Modus kann
;dies ab&zu auftreten, vermutlich sind
;Timing-Probleme mit dem Warp-Modus
;hier die Ursache.
			jsr	Turbo_GetBytes		;Byte(s) einlesen.
;--- Hinweis:
;yReg und AKKU werden hier nicht mehr
;benötigt, da der Fehlercode direkt im
;Speicher ":ErrorCode" abgelegt wird.
;			pla				;Anzahl Bytes wieder vom Stack
;			tay				;holen und in yReg kopieren.

;--- Hinweis:
;Ersatzroutine um nur ein Fehlerbyte
;einzulesen, Rest ignorieren.
;Das einlesen von Bytes über TurboDOS
;mit einem SD2IEC funktioniert nur mit
;unverändertem Code & Timing.
;Daher ursprünglichen Code belassen.
;Das Problem mit VICE/Warp-Modus und
;dem überschreiben von Code  kann daher
;aktuell nicht behoben werden.
;			sta	d1L			;Anzahl Bytes zwischenspeichern.
;
;			jsr	waitDataIn_HIGH		;Warten bis TurboDOS bereit.
;
;			jsr	Turbo_GetNxByte
;			sta	ErrorCode
;
;			dec	d1L			;Byte-Zähler -1.
;			beq	:ok
;
;::1			jsr	Turbo_GetNxByte
;			dec	d1L			;Byte-Zähler -1.
;			bne	:1			;Nein, weiter...
;
;::ok			jsr	setClkOut_HIGH

			ldx	ErrorCode		;Fehlercode einlesen.
			ldy	:errRetryCnt -1,x	;Anzahl Wiederholungsversuche.
			txa
			cmp	#$02			;$00/$01 = Kein Fehler ?
			bcc	:51			;Ja, Ende...
			clc				;Fehlercode berechnen.
			adc	#30
			b $2c
::51			lda	#NO_ERROR
::52			tax
			rts

;*** Anzahl Wiederholungsversuche.
::errRetryCnt		b $01,$05,$02,$08
			b $08,$01,$05,$01
			b $05,$05,$05
:ErrorCode		b $00
endif
