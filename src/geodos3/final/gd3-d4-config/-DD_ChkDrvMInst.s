; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk kann nur einmal installiert werden.
;Übergabe: AKKU = ":RealDriveType"
;          XReg = Neue GEOS-Laufwerksadresse.
;Rückgabe: XReg = Fehlercode.
;          YReg = Vorhandenes Laufwerk.
:ChkDrvMInst		stx	r0L

			ldx	#8
::1			cmp	RealDrvType -8,x	;Laufwerk bereits installiert?
			bne	:2			; => Nein, weiter...
			cpx	r0L			;Adresse = Neues Laufwerk ?
			beq	:2			; => Ja, ignorieren.

			txa
			pha

			LoadW	r0,Dlg_ActivRAM		;Hinweis: Laufwerk kann nur
			jsr	DoDlgBox		;einmal verwendet werden!

			pla
			tay

			ldx	#DEV_NOT_FOUND
			rts

::2			inx				;Alle Laufwerke durchsucht?
			cpx	#12
			bcc	:1			; => Nein, weiter...

			ldy	#NULL
			ldx	#NO_ERROR
			rts

;*** Dialogbox.
:Dlg_ActivRAM		b %01100001
			b $30,$8f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR ,$10,$20
			w :51
			b DBTXTSTR ,$10,$2a
			w :52
			b OK       ,$10,$48
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "Dieser Laufwerkstyp kann",NULL
::52			b "nur einmal verwendet werden!",NULL
endif

if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "This drive type can only",NULL
::52			b "be installed once!",NULL
endif
