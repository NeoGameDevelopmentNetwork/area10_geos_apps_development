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
; 03000.select-dev-hd.bas - select cmd-hd device
;
; parameter: dd    = current cmd-hd device address
;            hd()  = list of active cmd-hd devices
; return   : dd    = new cmd-hd device address
;            hs    = -1 / reset source scsi device
;            ht    = -1 / reset target scsi device
;            cs    = -1 / reset copy source partition
;            ct    = -1 / reset copy target partition
;            fs    = -1 / reset format source partition
;            ft    = -1 / reset format target partition
; temporary: dv
;

; select next cmd-hd device
3000 dv=dd
3010 dv=dv+1:ifdv=30thendv=8
3020 ifdv=ddthengoto3090
3030 ifhd(dv)=0thengoto3010
3080 dd=dv:hs=-1:ht=-1:cs=-1:ct=-1:fs=-1:ft=-1
3090 return
