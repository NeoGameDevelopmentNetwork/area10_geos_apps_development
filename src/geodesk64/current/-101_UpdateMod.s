; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichern der Systemvariablen, Programm-Modul und
;    Verzeichnisdaten. Wird verwendet bevor man das Modul
;    wechselt oder eine Anwendung startet.
.UPDATE_GD_CORE		lda	GD_RAM_GDESK1		;GeoDesk im RAM installiert?
			beq	UpdateExit		; => Nein, Ende...

			jsr	UPDATE_APPVAR		;Variablen speichern.
			jsr	UPDATE_MAINMOD		;Haupt-Modul speichern.
			jsr	UPDATE_CURMOD		;Aktuelles Programm-Modul speichern.

			lda	WM_WCODE		;Fenster geöffnet?
			beq	UpdateExit		; => Nein, weiter...

			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jmp	StashRAM		;Verzeichnisdaten speichern.

;*** Aktuelles Programm-Modul speichern.
;Sichert u.a. Variablen des Fenstermanagers.
:UPDATE_CURMOD		ldy	GD_VLIR_ACTIVE		;Aktuelles VLIR-Modul sichern.
			b $2c

;*** Haupt-Modul speichern.
:UPDATE_MAINMOD		ldy	#$01			;Haupt-Menü sichern.
			b $2c

;*** Variablen speichern.
:UPDATE_APPVAR		ldy	#$00			;Variablen ab APP_RAM sichern.

			pha				;AKKU/XReg sichern.
			txa				;Beinhaltet ggf. Programm-Modul
			pha				;und Einsprungadresse.

			tya
			jsr	SetVecModule		;Sichert u.a. Variablen des
			jsr	StashRAM		;Fenstermanagers.

			pla
			tax
			pla

:UpdateExit		rts
