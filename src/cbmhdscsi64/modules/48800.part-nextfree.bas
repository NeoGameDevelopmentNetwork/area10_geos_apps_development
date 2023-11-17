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
; 48800.part-nextfree.bas - Set next free partition
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            pn    = partition number
;

; Set partition number to next free partition
48800 pn=pf+1:ifpn>254thenpn=1
; Find free partition
48801 goto48700

; Set free partition +10
48850 pn=pf+10:ifpn>254thenpn=1
; Find free partition
48851 goto48700
