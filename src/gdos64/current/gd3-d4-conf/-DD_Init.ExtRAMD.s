; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Ext.RAMDisk testen.
;Rückgabe: xReg = DRIVE_NOT_FOUND : Laufwerk nicht vorhanden.
;          xReg = CANCEL_ERR      : Laufwerk nicht installiert.
;          xReg = NO_ERROR        : Neue Adresse gesetzt.
;          yReg = Adresse für Ext.RAM-Laufwerk.
:initTestExtRAM		jsr	initTestDevice		;RAM-Erweiterung testen.
			txa				;"DEVICE_NOT_FOUND" ?
			bne	:exit			; => Ja, Abbruch...

			ldy	#8
			lda	DrvMode			;Laufwerkstyp einlesen.
::loop			cmp	RealDrvType -8,y	;Laufwerk bereits installiert?
			beq	:found			; => Ja, weiter...
::next			iny
			cpy	#12			;Alle Laufwerke durchsucht?
			bcc	:loop			; => Nein, weiter...
			bcs	:cancel			; => Ja, Ende...

;--- Laufwerk bereits installiert.
::found			tya
			pha

			clc				;Laufwerksadresse für
			adc	#"A" -8			;Fehlermeldung berechnen.
			sta	dlgMInstTx02

			LoadW	r0,Dlg_ActivRAM		;Hinweis: Laufwerk kann nur
			jsr	DoDlgBox		;einmal verwendet werden!

			pla				;Laufwerksadresse zurückholen.
			tay

			ldx	#ILLEGAL_DEVICE

			bit	DEV_INSTALL_MODE	;Aufruf aus GD.CONFIG ?
			bmi	:exit			; => Ja, Ende...
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:exit			; => Ja, Ende...

			lda	#$00			;TurboDOS-Flag zurücksetzen.
			sta	turboFlags -8,y

			sta	driveData -8,y		;Zusätzlich Laufwerksdaten löschen.
			sta	drivePartData -8,y

::ok			ldx	#NO_ERROR		;Kein Fehler.
			b $2c
::cancel		ldx	#CANCEL_ERR		;Laufwerk nicht installiert.
::exit			rts				;Ende.

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
			b DBTXTSTR ,$10,$3a
			w dlgMInstTx01
			b OK       ,$10,$48
			b NULL

if LANG = LANG_DE
::51			b PLAINTEXT
			b "Dieser Laufwerkstyp kann",NULL
::52			b "nur einmal verwendet werden!",NULL
:dlgMInstTx01		b "(Wird als Laufwerk "
:dlgMInstTx02		b "x: installiert)",NULL
endif

if LANG = LANG_EN
::51			b PLAINTEXT
			b "This drive type can only",NULL
::52			b "be installed once!",NULL
:dlgMInstTx01		b "(Will be installed as drive "
:dlgMInstTx02		b "x:)",NULL
endif
