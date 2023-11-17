; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neuen Druckertreiber laden.
:ChangePrinter		LoadB	r7L,PRINTER		;Dateityp festlegen.
			LoadW	r10,$0000		;Keine GEOS-Klasse.
			jsr	OpenFile		;Druckertreiber auswählen.
			txa				;Datei ausgewählt?
			bne	exitOpenPrnt		; => Nein, Abbruch..

:OpenPrinter		lda	#<dataFileName		;Druckertreiber suchen.
			sta	r6L
			sta	errDrvInfoF +0
			lda	#>dataFileName
			sta	r6H
			sta	errDrvInfoF +1
			jsr	FindFile
			txa				;Datei gefunden?
			bne	OpenPrntError		; => Nein, weiter...

			LoadW	r0,dataFileName
			LoadW	r6,PrntFileName
			ldx	#r0L
			ldy	#r6L
			jsr	CopyString		;Druckername kopieren.

			LoadW	r7 ,PRINTBASE
			LoadB	r0L,%00000001
			jsr	GetFile			;Druckertreiber einlesen.
			txa				;Fehler?
			bne	OpenPrntError		; => Ja, Abbruch...
			jsr	OpenPrntOK		; => Nein, OK ausgeben.
			jsr	SUB_SYSINFO		;Statuszeile aktualisieren.
:exitOpenPrnt		rts

;*** Info: Drucker installiert.
:OpenPrntOK		LoadW	r6,PrntFileName
			lda	#$c0			;"PRNT_UPDATED"
			bne	OpenDevError

;*** Fehler: Drucker konnte nicht installiert werden.
:OpenPrntError		lda	#$80			;"PRNT_NOT_UPDATED"
			bne	OpenDevError

;*** Info: Eingabegerät installiert.
:OpenInptOK		LoadW	r6,inputDevName
			lda	#$c1			;"INPT_UPDATED"
			bne	OpenDevError

;*** Fehler: Eingabegerät konnte nicht installiert werden.
:OpenInptError		lda	#$81			;"INPT_NOT_UPDATED"
;			bne	OpenDevError

:OpenDevError		sta	errDrvCode		;Fehlernummer zwischenspeichern.

			jsr	SUB_STATMSG		;Statusmeldung ausgeben.

			ldx	#NO_ERROR
			bit	errDrvCode		;Fehler?
			bvs	:exit			; => Nein, weiter...
			ldx	#CANCEL_ERR		; => Ja, Abbruch...
::exit			rts

;*** Neuen Eingabetreiber laden.
:ChangeInput		LoadB	r7L,INPUT_DEVICE	;Dateityp festlegen.
			LoadW	r10,$0000		;Keine GEOS-Klasse.
			jsr	OpenFile		;Datei auswählen.
			txa				;Datei ausgewählt?
			bne	exitOpenInpt		; => Nein, Abbruch..

:OpenInput		LoadW	r6,dataFileName		;Name Eingabetreiber kopieren.
			MoveW	r6,errDrvInfoF
			jsr	FindFile
			txa
			bne	OpenInptError		; => Nein, weiter...

			LoadW	r0,dataFileName		;Name Eingabetreiber kopieren.
			LoadW	r6,inputDevName
			ldx	#r0L
			ldy	#r6L
			jsr	CopyString		;Name Eingabetreiber kopieren.

			LoadW	r7 ,MOUSE_BASE
			LoadB	r0L,%00000001
			jsr	GetFile			;Eingabetreiber einlesen.
			txa
			bne	OpenInptError
			jsr	InitMouse		;Initialisieren.
			jsr	OpenInptOK
:exitOpenInpt		rts

;*** Datei auswählen.
;    Übergabe:		r7L  = Datei-Typ.
;			r10  = Datei-Klasse.
;    Rückgabe:		In ":dataFileName" steht der Dateiname.
;			xReg = $00, Datei wurde ausgewählt.
:OpenFile		MoveB	r7L,:OpenFile_Type
			MoveW	r10,:OpenFile_Class

::1			ldx	curDrive
			lda	driveType -8,x		;Aktuelles Laufwerk gültig?
			bne	:3			; => Ja, weiter...

			ldx	#8			;Gültiges Laufwerk suchen.
::2			lda	driveType -8,x
			bne	:3
			inx
			cpx	#12
			bcc	:2
			ldx	#$ff
			rts

::3			txa				;Laufwerk aktivieren.
			jsr	SetDevice

;--- Dateiauswahlbox.
::4			MoveB	:OpenFile_Type ,r7L
			MoveW	:OpenFile_Class,r10
			LoadW	r5 ,dataFileName
			LoadB	r7H,255
			LoadW	r0,:Dlg_SlctFile
			jsr	DoDlgBox		;Datei auswählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:5			; => Nein, weiter...

			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			beq	:4			; => Nein, weiter...
			bne	:1			; => Ja, gültiges Laufwerk suchen.

::5			cmp	#DISK			;Partition wechseln ?
			beq	:4			; => Ja, weiter...
			ldx	#$ff
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:6			; => Ja, Abbruch...
			inx
::6			rts

::OpenFile_Type		b $00
::OpenFile_Class	w $0000

::Dlg_SlctFile		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b DISK                    ,$00,$00
			b OK,0,0
			b NULL
