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

			n "geoUFreezeNM"
			c "geoUFreeze  V0.5"
			a "Markus Kanet"

			h "Startet das Ultimate-Menü..."

			o APP_RAM
			p MAININIT

			f DESK_ACC

			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execFreeze

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ClkRate128"		;Nur C128: Auf 1/2 MHz umschalten.
			t "ulib._IRQ_NMI"		;IRQ/NMI aus-/einschalten.
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._ErrUDevDA"		;Fehlerausgabe bei DeskAccessories.

;CONTROL-Routinen:
			t "_ctl.05.Freeze"		;Ultimate-Menü aufrufen.

;*** Ultimate-Menü aufrufen.
:execFreeze		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV_DA
			jmp	exitDA			; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	uFreeze			;Ultimate-Menü aufrufen.

;*** Zurück zur Anwendung.
:exitDA			lda	#< RstrAppl		;Zurück zur Anwendung.
			sta	appMain +0
			lda	#> RstrAppl
			sta	appMain +1

			rts				;Ende.

;*** Ultimate-Menü aufrufen.
;Übergabe : -
;Rückgabe : -
;Verändert: A,X,Y

:uFreeze

;--- Hinweis:
;TurboDOS entfernen falls das Laufwerk
;im Ultimate-Menü verändert wird.
			jsr	PurgeTurbo		;TurboDOS deaktivieren.

			jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_IRQ_DISABLE	;IRQ/NMI verhindern.

			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCIC_FREEZE		;Menü aufrufen.

			jsr	ULIB_IRQ_ENABLE		;IRQ/NMI zulassen.
			jsr	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

			rts
