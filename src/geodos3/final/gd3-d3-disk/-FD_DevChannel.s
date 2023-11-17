; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Befehlskanal öffnen.
:openFComChan		lda	#$00			;Status löschen.
			sta	STATUS

;			lda	#$00
			tax
			tay
			jsr	SETNAM			;Kein Dateiname.
			lda	#15			;open 15,dv,15
			tay
			ldx	curDevice
			jsr	SETLFS			;Daten für Befehlskanal.
			jsr	OPENCHN			;Befehlskanal #15 öffnen.

			ldx	STATUS			;Fehler?
			beq	:1			; => Nein, weiter...
			jsr	closeFComChan		;Befehlskanal schließen.
			ldx	#CANCEL_ERR		;Laufwerksfehler.
::1			rts

;*** Buffer-Pointer setzen.
:setBufPointer		lda	#< :com_SetBP
			ldx	#> :com_SetBP
			ldy	#7
			jsr	SendComVLen		;Buffer-Pointer setzen.
			jmp	UNLSN			;Laufwerk abschalten.

::com_SetBP		b "B-P 5 0"

;*** Alle Laufwerkskanäle schließen.
:closeAllChan		jsr	InitForIO		;I/O aktivieren.
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.
			jmp	DoneWithIO		;I/O abschalten.

;*** Datenkanal schließen.
:closeDataChan		lda	#5			;Datenkanal schließen.
			jmp	CLOSE

;*** Befehlskanal schließen.
:closeFComChan		lda	#15			;Befehlskanal schließen.
			jmp	CLOSE
endif

;******************************************************************************
::tmp1a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp1b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp1 = :tmp1a!:tmp1b
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Datenkanal öffnen.
:openDataChan		lda	#$00			;Status löschen.
			sta	STATUS

			lda	# :comDBufLen		;open x,y,z,"#"
			ldx	#< :comDBufChan
			ldy	#> :comDBufChan
			jsr	SETNAM			;Datenkanal, Name "#".
			lda	#5			;open 5,dv,5
			tay
			ldx	curDevice
			jsr	SETLFS			;Daten für Datenkanal.
			jsr	OPENCHN			;Datenkanal öffnen.

			ldx	STATUS			;Fehler?
			beq	:1			; => Nein, weiter...
			jsr	closeDataChan		;Datenkanal schließen.
			ldx	#CANCEL_ERR		;Laufwerksfehler.
::1			rts

::comDBufChan		b "#0"
::comDBufEnd
::comDBufLen		= (:comDBufEnd - :comDBufChan)
endif
