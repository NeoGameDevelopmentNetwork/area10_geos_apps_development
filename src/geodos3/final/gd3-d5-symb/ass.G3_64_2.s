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

			n "ass.G3_64_2"
			c "ass.SysFile V1.0"
			t "G3_Sys.Author"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Laufwerkstreiber und Systemprogramme."
			f $04

			o $4000

;--- Systemfunktionen.
:DO_SYS			t "-A3_Sys"

;--- Laufwrkstreiber.
:DO_DSK			t "-A3_Disk"

;--- Programme.
:DO_PRG			t "-A3_Prog"

;--- Build-Dateien löschen.
:DEL_BUILD		OPEN_BOOT

;--- Objektdateien.
:DEL_OBJ		t "-A3_CleanUp#1"

;--- ext.Symboldateien.
:DEL_EXT		t "-A3_CleanUp#2"

;--- Objektdateien/Laufwerkstreiber.
:DEL_OBJ_DISK		t "-A3_CleanUp#3"

;--- Objektdateien/Laufwerkstreiber.
;Durch Link-Vorgang bereits gelöscht.
if (ENABLE_DISK_NG = TRUE) & (ENABLE_DISK_ALL = BUILD_SELECTED)
:DEL_OBJ_DRVSYS		t "-A3_CleanUp#4"
endif
;:DEL_OBJ_INISYS	t "-A3_CleanUp#5"

;--- ext.Symboldateien/Laufwerkstreiber.
:DEL_EXT_DISK		t "-A3_CleanUp#6"

;--- Ende.
:ALL_DONE		b $ff

;--- NativeMode-Unterverzeichnisse einbinden.
			t "ass.NativeDir"
