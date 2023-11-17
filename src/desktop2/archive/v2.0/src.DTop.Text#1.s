; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemtexte.
if LANG = LANG_DE
:textConvDisk1		b BOLDON
			b "Diskette ist eine "
:txErrNoGEOSDisk	b "Nicht-GEOS-Disk",NULL
:textConvDisk2		b "Konvertieren?",NULL

:textUsedKb		b " K belegt",NULL
:textFreeKb		b " K frei",NULL
endif
if LANG = LANG_EN
:textConvDisk1		b BOLDON
			b "This is a "
:txErrNoGEOSDisk	b "NON-GEOS disk",NULL
:textConvDisk2		b "Convert it?",NULL

:textUsedKb		b " Kbytes used",NULL
:textFreeKb		b " Kbytes free",NULL

;** AM/PM-Flag.
.txAM			b " AM",NULL
.txPM			b " PM",NULL
endif
