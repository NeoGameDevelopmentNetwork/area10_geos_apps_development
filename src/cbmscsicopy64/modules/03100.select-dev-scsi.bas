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
; 03100.select-dev-scsi.bas - select cmd-hd scsi device
;
; Select source device:
; parameter: hs    = current source scsi device
;            si(x) = list of available scsi devices
; return   : hs    = new source scsi device
;            cs    = -1 / reset copy source partition
;            ct    = -1 / reset copy target partition
;            fs    = -1 / reset format source partition
;            ft    = -1 / reset format target partition
; temporary: sd,sx
;
; Select target device:
; parameter: ht    = current target scsi device
;            si(x) = list of available scsi devices
; return   : ht    = new target scsi device
;            ct    = -1 / reset copy target partition
;            ft    = -1 / reset format target partition
; temporary: sd,sx
;

; Select next source SCSI device
3100 sd=hs:gosub3150
; Set new source SCSI device, reset partition info for source/target
3101 hs=sd:cs=-1:ct=-1:fs=-1:ft=-1
3109 return

; Select next target SCSI device
3110 sd=ht:gosub3150
; Set new target SCSI device, reset partition info for target
3111 ht=sd:ct=-1:ft=-1
3119 return

; Select next SCSI device
3150 sx=sd
3151 sx=sx+1:ifsx=7thensx=0
; All devices tested?
3152 ifsx=sdthengoto3190
3153 ifsi(sx)<0thengoto3151
; Set new SCSI device
3154 sd=sx
3190 return
