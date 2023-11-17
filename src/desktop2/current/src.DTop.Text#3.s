; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemtexte.
if LANG = LANG_DE
:dbtxInsertDk1		b BOLDON
			b "Bitte Zieldisk in Laufwerk "
:dbtxInsertTgtDrv	b "A",NULL
:dbtxInsertDk2		b "einlegen",NULL

.dbtxGetEmptyDk		b BOLDON
			b "Leerdisk in Laufwerk "
.dbtxDrvEmptyDk		b "A und",NULL

.dbtxNewDiskNm		b BOLDON
			b "Bitte neuen "
.dbtxGetDiskNm		b "Disknamen eingeben:"
			b PLAINTEXT,NULL

:dbtxReplFiles1		b BOLDON
			b "Ersetzen Inhalt von",NULL
:dbtxReplFiles2		b "durch Inhalt von",NULL

:dbtxForbidden1		b BOLDON
			b "Dieser Arbeitsgang",NULL
:dbtxForbidden2		b "darf nicht auf",NULL
:txErrBootDisk		b "die Startdiskette",NULL
:txErrMainDisk		b "eine Hauptdiskette",NULL
.txErrOtherDisk		b "Dateien einer anderen Disk",NULL
:dbtxForbidden3		b "angewendet werden.",NULL

:textFileCount		b " Dateien",NULL
:textSlctCount		b " gewählt",NULL

:txErrReplace1		b BOLDON
			b "existiert auf der "
:txErrReplace2		b "Zieldisk.",NULL
:txErrReplace3		b "Überschreiben?",NULL
endif
if LANG = LANG_EN
:dbtxInsertDk1		b BOLDON
			b "Please insert destination disk",NULL
.dbtxGetEmptyDk		b BOLDON
			b "Put disk to format "
:dbtxInsertDk2		b "in drive:  "
:dbtxInsertTgtDrv	b "A",NULL

.dbtxNewDiskNm		b BOLDON
			b "Please enter new disk name:"
			b PLAINTEXT,NULL

.dbtxDrvEmptyDk
.dbtxGetDiskNm		b "and enter a name for it:"
			b PLAINTEXT,NULL

:dbtxReplFiles1		b BOLDON
			b "Replace contents of",NULL
:dbtxReplFiles2		b "with contents of",NULL

:dbtxForbidden1		b BOLDON
			b "The operation requested",NULL
:dbtxForbidden2		b "may not be performed on",NULL
:txErrBootDisk		b "the GEOS Boot disk.",NULL
:txErrMainDisk		b "a Master disk.",NULL
.txErrOtherDisk		b "a file from another disk.",NULL
:dbtxForbidden3		b NULL

:textFileCount		b " files,",NULL
:textSlctCount		b " selected",NULL

:txErrReplace1		b BOLDON
			b "is on "
:txErrReplace2		b "the disk.",NULL
:txErrReplace3		b "OK to overwrite?",NULL
endif
