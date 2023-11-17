; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstexte.
if LANG = LANG_DE
:textDriveA		b "Lfwerk A",NULL
:textDriveB		b "Lfwerk B",NULL
:textDriveC		b "Lfwerk C",NULL
endif
if LANG = LANG_EN
:textDriveA		b "DRIVE A",NULL
:textDriveB		b "DRIVE B",NULL
:textDriveC		b "DRIVE C",NULL
endif
