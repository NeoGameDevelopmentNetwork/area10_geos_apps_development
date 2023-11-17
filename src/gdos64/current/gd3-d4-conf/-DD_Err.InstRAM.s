; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dialogbox: "Nicht genügend freier Speicher!"
:devErr_NoRAM		LoadW	r0,:dlg_InstRamErr
			jmp	DoDlgBox		;Dialogbox ausgeben.

::dlg_InstRamErr	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DlgBoxTitle
			b DBTXTSTR   ,$0c,$20
			w :t01
			b DBTXTSTR   ,$0c,$2c
			w :t02
			b DBTXTSTR   ,$0c,$36
			w :t03
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::t01			b PLAINTEXT
			b "Installation abgebrochen!",NULL
::t02			b "Es ist nicht ausreichend",NULL
::t03			b "freier Speicher verfügbar.",NULL
endif

if LANG = LANG_EN
::t01			b PLAINTEXT
			b "Unable to install drive!",NULL
::t02			b "Not enough free extended",NULL
::t03			b "memory available!",NULL
endif
