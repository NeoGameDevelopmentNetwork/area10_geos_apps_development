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
			t "ass.Options"
endif

			n "ass.G3_64_DSK"
			c "ass.SysFile V1.0"
			t "G3_Sys.Author"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Laufwerkstreiber."
			f $04

			o $4000

			t "-A3_Disk"
			b $ff

;--- NativeMode-Unterverzeichnisse einbinden.
			t "ass.NativeDir"
