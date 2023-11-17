; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemtexte.
;Die Texte werden u.a. von Modul#3 bei
;der Auswahl eines Druckertreibers oder
;eines Eingabegeräts verwendet.
if LANG = LANG_DE
.textPrnEmpty		b " ",NULL

.textSlctDev		b BOLDON
			b "wählen",NULL

.textPrinter		b "Drucker",NULL

.textInput		b "Eingabe-",NULL
.textInputDev		b "gerät",NULL
endif
if LANG = LANG_EN
.textSlctDev		b BOLDON
			b "Select",NULL

.textPrinter		b "Printer",NULL
.textPrnEmpty		b " ",NULL

.textInput		b "Input",NULL
.textInputDev		b "Device",NULL
endif
