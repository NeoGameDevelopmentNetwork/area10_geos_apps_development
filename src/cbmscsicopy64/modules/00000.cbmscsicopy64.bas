; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 00000.cbmscsicopy64.bas - main init
;

; Program description
0 rem partition copy tool for cmd-hd and attached scsi devices

; Program name / author / version
1 vn$="cbmscsicopy64":vd$="(w)2020 by m.k.":vv$="v0.10"

; Define title
10 sp$="          "
11 tt$=vn$+" "+vv$+" "+vd$
12 tt$=right$(sp$+sp$+tt$,len(tt$)+(20-(len(tt$)/2)))
13 tt$="{clr}"+tt$+"{down}"
