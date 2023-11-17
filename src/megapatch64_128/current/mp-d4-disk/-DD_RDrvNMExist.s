; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk kann nur einmal installiert werden.
;    Übergabe: AKKU: RealDriveType
:CheckRDrvExist		ldx	#8
::1			cmp	RealDrvType -8,x	;Laufwerk bereits installiert?
			bne	:2			; => Nein, weiter...

			LoadW	r0,Dlg_ActivRAM		;Hinweis: Laufwerk kann nur
			jsr	DoDlgBox		;einmal verwendet werden!
			ldx	#DEV_NOT_FOUND
			rts

::2			inx				;Alle Laufwerke durchsucht?
			cpx	#12
			bcc	:1			; => Nein, weiter...
			ldx	#NO_ERROR
			rts

;*** Dialogbox.
:Dlg_ActivRAM		b %11100001
			b DB_USR_ROUT
			w Dlg_DrawBoxTitel
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
::52			b "be used once!",NULL
endif
