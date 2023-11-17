; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Spracheinstellungen.
;Der Wert für LANG wird als WORD
;definiert da der Wert mit TRUE/FALSE
;kombiniert werden muss, z.B. DEBUG.
.LANG_DE		= $4000
.LANG_EN		= $8000
.LANG			= LANG_EN
