; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Fehlertexte.
if LANG = LANG_DE
:txErrMaxBorder1	b BOLDON
			b "Nur 8 Dateien dürfen auf dem",NULL
:txErrMaxBorder2	b "Rand liegen.",NULL

:txErrPrintFile1	b BOLDON
			b "Datei kann nicht von",NULL
:txErrPrintFile2	b "deskTop gedruckt werden.",NULL

:txErrOpenFile1		b BOLDON
			b "Diese Datei nicht von",NULL
:txErrOpenFile2		b "deskTop zu öffnen.",NULL

:txString_In		b "in",NULL

:txErrOtherDisk1	b BOLDON
			b "Nicht möglich, da Applikation",NULL
:txErrOtherDisk2	b "auf anderer Disk.",NULL

:txErrDelTgtFile	b BOLDON
			b "ist erst zu löschen von",NULL

.txString_File		b BOLDON
			b "Datei"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
:txErrMaxBorder1	b BOLDON
			b "Only 8 files may be on the",NULL
:txErrMaxBorder2	b "border.",NULL

:txErrPrintFile1	b BOLDON
			b "This file can't be printed",NULL

:txErrOpenFile1		b BOLDON
			b "This file can't be opened",NULL

:txErrPrintFile2
:txErrOpenFile2		b "from the deskTop.",NULL

:txString_In		b "in",NULL

:txErrOtherDisk1	b BOLDON
			b "Can't preceed if application",NULL
:txErrOtherDisk2	b "is on a different disk.",NULL

:txErrDelTgtFile	b BOLDON
			b "must first be deleted from",NULL

:txString_A		b BOLDON
			b "A",NULL

.txString_File		b BOLDON
			b "The file"
			b PLAINTEXT,NULL
endif
