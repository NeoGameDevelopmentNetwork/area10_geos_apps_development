; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemtexte.
if LANG = LANG_DE
:dbtxDiskEmpty1		b BOLDON
			b "Disk enthält keine Datei.",NULL
:dbtxDiskEmpty2		b "Leerdisk kopieren?",NULL

:dbtxMultiFile1		b BOLDON
			b "Keine Mehrdateien-Behandlung",NULL
:dbtxMultiFile2		b "für diese Operation.",NULL

:dbtxNoDkCopy1		b BOLDON
			b "Keine ganzseitige Kopie mit",NULL
:dbtxNoDkCopy2		b "diesen Disk-Formaten möglich.",NULL
endif
if LANG = LANG_EN
:dbtxDiskEmpty1		b BOLDON
			b "Disk is empty.",NULL
:dbtxDiskEmpty2		b "Copy blank disk?",NULL

:dbtxMultiFile1		b BOLDON
			b "No multiple file operation for",NULL
:dbtxMultiFile2		b "this feature.",NULL

:dbtxNoDkCopy1		b BOLDON
			b "Disk copy can't be done",NULL
:dbtxNoDkCopy2		b "between these disk formats.",NULL
endif
