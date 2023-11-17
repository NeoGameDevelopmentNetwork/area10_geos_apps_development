; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei auswählen.
;    Übergabe:		r7L  = Datei-Typ.
;			r10  = Datei-Klasse.
;    Rückgabe:		In ":dataFileName" steht der Dateiname.
;			xReg = $00, Datei wurde ausgewählt.
:OpenFile		MoveB	r7L,OpenFile_Type
			MoveW	r10,OpenFile_Class

::1			ldx	curDrive
			lda	driveType -8,x
			bne	:3

			ldx	#8
::2			lda	driveType -8,x
			bne	:3
			inx
			cpx	#12
			bcc	:2
			ldx	#$ff
			rts

::3			txa
			jsr	SetDevice

::4			MoveB	OpenFile_Type ,r7L
			MoveW	OpenFile_Class,r10
			LoadW	r5 ,dataFileName
			LoadB	r7H,255
			LoadW	r0,Dlg_SlctFile
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

;*** System-Datei suchen/öffnen.
:OpenFile_Type		b $00				;Dateiauswahl: Dateityp.
:OpenFile_Class		w $0000				;Dateiauswahl: Zeiger auf Klasse.

;*** Dialogbox: Datei wählen.
:Dlg_SlctFile		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b DISK                    ,$00,$00
			b DBUSRICON               ,$00,$00
			w Dlg_SlctInstall
			b NULL

;*** Icon für Dateiauswahlbox.
:Dlg_SlctInstall	w :install
			b $00,$00,:install_x,:install_y
			w :exit

::exit			lda	#OPEN
			sta	sysDBData
			jmp	RstrFrmDialogue

::install
<MISSING_IMAGE_DATA>

::install_x		= .x
::install_y		= .y
