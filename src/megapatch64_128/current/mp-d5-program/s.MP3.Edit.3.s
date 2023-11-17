; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Da im GEOS128.Editor nicht genügend freier Speicher zur Verfügung steht,
;wird die Routine zum wechseln vom SD2IEC-Images in Bank#0 ausgelagert.
;******************************************************************************

			n "mod.GE_#102"
			t "G3_SymMacExtEdit"
			t "s.MP3.Edit.2.ext"

			t "src.Edit.Class"

			a "Markus Kanet"
			o Base1SDTools

;*** Einsprungtabelle.
:xTestSD2IEC		jmp	TestSD2IEC
:xSlctDiskImg		jmp	SlctDiskImg

			t "-G3_TestSD2IEC"
			t "-G3_SlctDskImg"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_EDITOR_DATA -1
;******************************************************************************
