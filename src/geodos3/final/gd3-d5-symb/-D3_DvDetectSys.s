; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf VICE/VDRIVE-Laufwerk testen.
;Sendet U1-Befehl an das Laufwerk, ein
;"30,SYNTAX ERROR" deutet auf ein VICE
;Dateisystem-Laufwerk hin.
;Rückgabe: YReg = 127 / VICE-FS.
;          XReg = Laufwerk erkannt.
:testViceFS		lda	#< :FCom_U1
			ldx	#> :FCom_U1
			ldy	#:FCom_U1_len
			jsr	xSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	getStatusBytes		;Laufwerksstatus einlesen.

			ldx	#NO_ERROR		;Kein Fehler.

			ldy	#127			;Kennung für VICE/VDRIVE.
			lda	devDataBuf +0
			cmp	#"3"
			bne	:err
			lda	devDataBuf +1
			cmp	#"0"
			bne	:err
			lda	devDataBuf +2
			cmp	#","
			beq	:exit

::err			ldx	#DEV_NOT_FOUND		;Kein VICE/VDRIVE.
::exit			rts

::FCom_U1		b "U1 5 0 1 1"
::FCom_U1_end
::FCom_U1_len		= (:FCom_U1_end - :FCom_U1)

;*** Auf SD2IEC-Laufwerk testen.
:testSD2IEC		lda	#< :FCom_MR
			ldx	#> :FCom_MR
			ldy	#:FCom_MR_len
			jsr	xSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	#< devDataBuf
			ldx	#> devDataBuf
			ldy	#3
			jsr	getDevBytes

			ldx	#NO_ERROR
			ldy	#%01000000
			lda	devDataBuf +0
			cmp	#"0"
			bne	:err
			lda	devDataBuf +1
			cmp	#"0"
			bne	:err
			lda	devDataBuf +2
			cmp	#","
			beq	:exit

::err			ldx	#DEV_NOT_FOUND		;Kein SD2IEC.
::exit			rts

::FCom_MR		b "M-R"
			w $0300
			b $03
::FCom_MR_end
::FCom_MR_len		= (:FCom_MR_end - :FCom_MR)

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

;*** Datenkanal schließen.
:closeDataChan		lda	#5			;Datenkanal schließen.
			jmp	CLOSE

;*** Befehlskanal schließen.
:closeFComChan		lda	#15			;Befehlskanal schließen.
			jmp	CLOSE

;*** Bytes über ser. Bus einlesen.
;    Übergabe:		AKKU/xReg , Zeiger auf Bytespeicher.
;			yReg      , Anzahl Bytes.
:getDevBytes		sta	r0L
			stx	r0H

			sty	r1L

			ldy	#0
			tya
::1			sta	(r0L),y
			iny
			cpy	r1L
			bne	:1

			jsr	initDevTALK
			bne	:err

::2			jsr	ACPTR

			ldy	#$00
			sta	(r0L),y

			inc	r0L
			bne	:3
			inc	r0H

::3			dec	r1L
			bne	:2

			jsr	UNTALK

			lda	#NO_ERROR
::err			tax
			rts

;*** Bytes über ser. Bus bis Zeilenende einlesen.
:getStatusBytes		LoadW	r0,devDataBuf

			ldy	#0
			tya
::1			sta	(r0L),y
			iny
			cpy	#32
			bcc	:1

			jsr	initDevTALK
			bne	:err

			ldy	#0
::2			jsr	ACPTR
			sta	(r0L),y
			cmp	#13
			beq	:3
			iny
			cpy	#32
			bcc	:2

::3			jsr	UNTALK

			lda	#NO_ERROR
::err			tax
			rts

;*** Speicher für Laufwerksdaten.
:devDataBuf		s 32

;*** Laufwerkstabelle.
;C=1541/1571/1581 = $01/$02/03
;CMD FD/HD/RL     = $10/$20/$30
;SD2IEC           = $41/$42/$43/$44
:sysDevInfo		s 22				;(#8-29)
