; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "MakeSetup128"
			t "G3_SymMacExt"

			c "MkSetup_128 V2.0"
			a "M.Kanet/W.Grimm"
			f APPLICATION
			z $40

			o $0400
			p MainInit

if Sprache = Deutsch
			h "* Erstellt die MegaPatch128 Setup-Dateien..."
endif
if Sprache = Englisch
			h "* Create MegaPatch128 setup files..."
endif

;*** MegaPatch-Install einbinden.
			t "-M3_Shared"
