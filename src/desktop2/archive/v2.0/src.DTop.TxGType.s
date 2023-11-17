; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Dateitypen.
if LANG = LANG_DE
.txFTyp_NotGEOS		b "nicht GEOS",NULL
.txFTyp_BASIC		b "BASIC-Prg.",NULL
.txFTyp_ASSEMBLE	b "Assemblerprg.",NULL
.txFTyp_DATA		b "reine Daten",NULL
:txErrSysFile		b "eine "
.txFTyp_SYSTEM		b "Systemdatei",NULL
.txFTyp_DESKACC		b "Hilfsprg.",NULL
.txFTyp_APPLIC		b "Applikation",NULL
.txFTyp_APPLDATA	b "Dokument",NULL
.txFTyp_FONT		b "Schriftart",NULL
.txFTyp_PRINTER		b "Druckertreiber",NULL
:textPrntNotOnDsk	b " NICHT AUF DISK ",NULL
.txFTyp_INPUT		b "C64 Eingabetr.",NULL
.txFTyp_DISK		b "Disktreiber",NULL
:txErrStartFile		b "ein "
.txFTyp_BOOT		b "Startprg.",NULL
.txFTyp_TEMP		b "Temporär",NULL
.txFTyp_AUTOEXEC	b "selbstausführend",NULL
endif
if LANG = LANG_EN
.txFTyp_NotGEOS		b "Non-GEOS File",NULL
.txFTyp_BASIC		b "BASIC Prg.",NULL
.txFTyp_ASSEMBLE	b "Assembly Prg.",NULL
.txFTyp_DATA		b "Data File",NULL
:txErrSysFile		b "a "
.txFTyp_SYSTEM		b "System File",NULL
.txFTyp_DESKACC		b "Desk Accessory",NULL
.txFTyp_APPLIC		b "Application",NULL
.txFTyp_APPLDATA	b "Appl. Data",NULL
.txFTyp_FONT		b "Font File",NULL
.txFTyp_PRINTER		b "Printer Driver",NULL
:textPrntNotOnDsk	b " NOT ON DISK ",NULL
.txFTyp_INPUT		b "C64 Input Driver",NULL
.txFTyp_DISK		b "Disk Driver",NULL
:txErrStartFile		b "a "
.txFTyp_BOOT		b "System Boot File",NULL
.txFTyp_TEMP		b "Temp",NULL
.txFTyp_AUTOEXEC	b "Auto-Exec",NULL
endif
