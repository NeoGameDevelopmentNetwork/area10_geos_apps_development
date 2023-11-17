; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Objektdateien löschen.
:DEL_OBJ_FILES		= TRUE

;*** Externe Symboldateien löschen.
:DEL_EXT_FILES		= TRUE

;*** Warnung ausgeben bei Dateifehler.
:DEL_ENABLE_WARN	= FALSE

;*** GD.DISK oder GD.DISK/NG.
:ENABLE_DISK_NG		= FALSE

;*** GD.DISK und GD.DISK/NG erstellen ?
;Nur zu Testzwecken sinnvoll, da dabei
;einige Dateien überschrieben werden!
:BUILD_EVERYTHING	= $8000				;GD.DISK und  GD.DISK/NG
:BUILD_SELECTED		= $0000				;GD.DISK oder GD.DISK/NG
:ENABLE_DISK_ALL	= BUILD_SELECTED
