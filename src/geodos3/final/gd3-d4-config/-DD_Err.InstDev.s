; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dialogbox: "Laufwerk konnte nicht installiert werden!"
;Übergabe: XReg       = Fehlercode.
;          DrvAdrGEOS = Laufwerksadresse.
:devErr_Install		lda	DrvAdrGEOS		;Laufwerksadresse in
			clc				;Fehlermeldung übertragen.
			adc	#"A" -8
			sta	:t03drv

			txa				;Fehlercode als HEX-Wert in
			jsr	HEX2ASCII		;Fehlermeldung übertragen.
			stx	:t04err +0
			sta	:t04err +1

			LoadW	r0,:dlg_InstDevErr
			jmp	DoDlgBox		;Dialogbox ausgeben.

::tab1			= $0040 +$58
::dlg_InstDevErr	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DlgBoxTitle
			b DBTXTSTR   ,$0c,$20
			w :t01
			b DBTXTSTR   ,$0c,$2a
			w :t02
			b DBTXTSTR   ,$0c,$3a
			w :t03
			b DBTXTSTR   ,$0c,$44
			w :t04
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::t01			b "Das Laufwerk konnte nicht",NULL
::t02			b "installiert werden!",NULL
::t03			b BOLDON,"Laufwerk: ",PLAINTEXT
			b GOTOX
			w :tab1
::t03drv		b "X:"
			b NULL
::t04			b BOLDON,"Fehler:",PLAINTEXT
			b GOTOX
			w :tab1
			b "$"
::t04err		b "XX"
			b NULL
endif

if Sprache = Englisch
::t01			b "Unable to install drive!",NULL
::t02			b NULL
::t03			b BOLDON,"Drive: ",PLAINTEXT
			b GOTOX
			w :tab1
::t03drv		b "X:"
			b NULL
::t04			b BOLDON,"Error:",PLAINTEXT
			b GOTOX
			w :tab1
			b "$"
::t04err		b "XX"
			b NULL
endif
