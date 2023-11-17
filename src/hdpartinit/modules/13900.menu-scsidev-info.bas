; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; hdPartInit
;
; 13900.menu-scsidev-info.bas - menu: print scsi device info
;

; Print device info
13900 print"    cmd-hd  :";dv
13901 print"    scsi id :";sd
; LUN is always '0' here...
; 13902 print"    scsi lun :";0
13903 print"    vendor  : '";sv$(sd);"'"
13904 print"    product : '";sp$(sd);"'{down}"
13909 return
