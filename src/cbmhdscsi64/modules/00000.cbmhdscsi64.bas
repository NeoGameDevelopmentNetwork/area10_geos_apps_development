; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmHDscsi64
;
; 00000.cbmhdscsi64.bas - main init
;

; Program description
0 rem configuration tool for cmd-hd

; Program name / author / version
1 vn$="cbmhdscsi64":vd$="(w)2020 by m.k.":vv$="v0.07"

; Define title
10 sp$="          "
11 tt$=" "+vn$+" - "+vv$+" / "+vd$+sp$+sp$+sp$+sp$
12 tt$="{clr}{rvon}"+left$(tt$,39)+"{rvof}{down}{down}"
