; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** System-Information (Beispiel):
;         1         2         3         4
;1234567890123456789012345678901234567890
;GDOS : GEOS SYSTEM ENVIRONMENT
;BUILD: V0.00-01.01.21:1800DEV
;
;1997-2023(W)MARKUS KANET
;
;
;COMPUTER  : C64
;SYSTEM    : PAL
;AKTIVE CPU: 6510/8502
;
;...BOOT-MELDUNGEN...
;
;
;*** Titel-Information.
:BootText00		b "GDOS : GEOS SYSTEM ENVIRONMENT",CR

;*** Kernal-Information.
			b "BUILD: "
			t "opt.GDOS.Build"
			b CR,CR,NULL

;*** Autor-Information.
:BootText00a		b "1997-2023(W)MARKUS KANET",CR
			b CR,CR,NULL
