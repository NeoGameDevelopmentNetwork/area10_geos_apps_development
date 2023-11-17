; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
;			t "TopMac"
;			t "Sym128.erg"
endif

			n "geoUReboot"
			c "geoUReboot  V0.1"
			a "Markus Kanet"

			h "Ultimate-Reset ausführen..."

			o APP_RAM
			p MAININIT

			f APPLICATION

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execReboot

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.

;CONTROL-Routinen:
			t "_ctl.06.Reboot"		;Ultimate neu starten.

;*** Ultimate-Reset ausführen.
;Übergabe: -
;Rückgabe: -
:execReboot		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			lda	#< dBoxAskReboot
			sta	r0L
			lda	#> dBoxAskReboot
			sta	r0H
			jsr	DoDlgBox		;Sicherheitsabfrage.

			ldx	#CANCEL_ERR
			lda	sysDBData
			cmp	#YES			;Reset ausführen?
			bne	exitDeskTop		; => Nein, Ende...

			jsr	ExitTurbo		;TurboDOS deaktivieren.
			jsr	uReboot			;Ultimate-Reset ausführen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Ultimate-Reset ausführen.
;Übergabe : -
;Rückgabe : -
;Verändert: A,X,Y

:uReboot		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCIC_REBOOT		;Ultimate-Reset ausführen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;Kein Fehler.
::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Dialogbox: Ultimate-Reset?
:dBoxAskReboot		b %10000001

			b DBTXTSTR,$10,$10
			w :1
			b DBTXTSTR,$10,$20
			w :2

			b YES     ,$02,$48
			b CANCEL  ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "ACHTUNG!"
			b PLAINTEXT,NULL
::2			b "Ultimate-Reset ausführen?"
			b NULL
