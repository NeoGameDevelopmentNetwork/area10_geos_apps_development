; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeiger auf GEOS-Bildschirm-Modus.
;Übergabe: AKKU = Bildschirm-Modus.
;Rückgabe: XREG/YYREG = Zeiger auf Text für Bildschirm-Modus.
:GetScreenMode		lsr
			lsr
			lsr
			lsr
			lsr
			tax
			lda	:tab +0,x
			ldy	:tab +1,x
			rts

;*** Text für Bildschirm-Modus.
::tab			w :40
			w :40_80
			w :64
			w :80

if LANG = LANG_DE
::40			b "40 Zeichen",NULL
::40_80			b "40 & 80 Zeichen",NULL
::64			b "GEOS 64",NULL
::80			b "80 Zeichen",NULL
endif
if LANG = LANG_EN
::40			b "40 columns",NULL
::40_80			b "40 / 80 columns",NULL
::64			b "GEOS 64",NULL
::80			b "80 columns",NULL
endif
