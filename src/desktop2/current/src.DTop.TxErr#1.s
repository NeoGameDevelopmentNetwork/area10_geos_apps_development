; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Texte für Fehlermeldungen.
if LANG = LANG_DE
:dbtxGetDiskWith	b BOLDON,"Bitte Disk einlegen mit",NULL
:dbtxIDskInDrv		b BOLDON,"In Laufwerk:  "
:dbtxDriveAdr		b "A",NULL
:dbtxInsertDisk		b BOLDON,"Bitte Disk einlegen:",NULL
:dbtxCancelErr		b BOLDON,"Abgebrochen wegen",NULL
:dbtxDiskFullErr	b "Diskfehler:",NULL
:dbtxErrDiskFull	b "Disk zu voll",NULL
:dbtxErrDirFull		b "Verzeichnis voll",NULL
:dbtxErrNoDisk		b "Fehlt oder unformatiert Disk",NULL
:dbtxErrWrProt		b "schreibschutz auf Disk",NULL
:dbtxErrDiskDS		b "Doppelseitg. Disk in 1541",NULL
endif
if LANG = LANG_EN
:dbtxGetDiskWith	b BOLDON,"Please insert disk with",NULL
:dbtxIDskInDrv		b BOLDON,"In drive:  "
:dbtxDriveAdr		b "A",NULL
:dbtxInsertDisk		b BOLDON,"Please insert disk:",NULL
:dbtxCancelErr		b BOLDON,"Operation canceled due to",NULL
:dbtxDiskFullErr	b "disk error:",NULL
:dbtxErrDiskFull	b "Disk full",NULL
:dbtxErrDirFull		b "Directory full.",NULL
:dbtxErrNoDisk		b "Missing or unformatted disk.",NULL
:dbtxErrWrProt		b "Write protect tab on disk.",NULL
:dbtxErrDiskDS		b "Double-sided disk in 1541.",NULL
endif
