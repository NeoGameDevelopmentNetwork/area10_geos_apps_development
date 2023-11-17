; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "ass.Includes"
			t "ass.Drives"
			t "ass.Macro"
endif

			n "ass.G3_64_1"
			c "ass.SysFile V1.0"
			t "G3_Sys.Author"
			h "* AutoAssembler Systemdatei."
			h "Erstellt komprimierten MegaPatch-Kernal."
			f $04

			o $4000

			t "-A3_Kernal"
			b $ff

;--- NativeMode-Unterverzeichnisse einbinden.
			t "ass.NativeDir"
