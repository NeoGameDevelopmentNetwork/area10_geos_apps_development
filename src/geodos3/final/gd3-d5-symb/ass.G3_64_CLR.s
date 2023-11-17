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
;			t "ass.Options"

;--- Objektdateien löschen.
:DEL_OBJ_FILES		= TRUE

;--- Externe Symboldateien löschen.
:DEL_EXT_FILES		= TRUE

;--- Warnung ausgeben bei Dateifehler.
:DEL_ENABLE_WARN	= FALSE

;--- GD.DISK oder GD.DISK/NG.
:ENABLE_DISK_NG		= TRUE

;--- GD.DISK und GD.DISK/NG erstellen ?
;Beim manuellen löschen von Objekt- und
;Symboldateien immer alles löschen.
:BUILD_EVERYTHING	= $8000				;GD.DISK und  GD.DISK/NG
:BUILD_SELECTED		= $0000				;GD.DISK oder GD.DISK/NG
:ENABLE_DISK_ALL	= BUILD_EVERYTHING
endif

			n "ass.G3_64_CLR"
			c "ass.SysFile V1.0"
			t "G3_Sys.Author"
			h "* AutoAssembler Systemdatei."
			h "Löscht Objekt- und Symboldateien."
			f $04

			o $4000

			t "-A3_CleanUp"
			b $ff

;--- NativeMode-Unterverzeichnisse einbinden.
			t "ass.NativeDir"
