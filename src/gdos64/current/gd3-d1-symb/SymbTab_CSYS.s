; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** C64-Systemadressen.
;--- Ergänzung: 07.04.19/M.Kanet
;Die Adresse VARTAB war bisher falsch
;definiert und muss auf $002D zeigen.
;Bisher $002B = TXTTAB.
;Dadurch funktionierte ToBASIC nicht
;wie erwartet (Starten von Anwendungen
;funktioniert nicht).
:VARTAB			= $002d
:C3PO			= $0094
:BSOUR			= $0095
:EAL			= $00ae
:TAPE1			= $00b2
:NDX			= $00c6
:PNTR			= $00d3
:TBLX			= $00d6
:KEYD			= $0277
:MEMSTR			= $0281
:MEMSIZ			= $0283
:COLOR			= $0286
:HIBASE			= $0288
:PAL_NTSC		= $02a6
:TBUFFR			= $033c

;*** Kernal-Vektoren.
:irqvec			= $0314
:bkvec			= $0316
:nmivec			= $0318
