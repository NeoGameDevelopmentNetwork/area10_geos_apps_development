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
; 58300.disk-hd-write.bas - write scsi-block to device
;
; parameter: bu(x) = 512 data bytes
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            wh    = lba high-byte
;            wm    = lba medium-byte
;            wl    = lba low-byte
; return   : es    = error status
; temporary: by,by$,he$,rh$,rm$,rl$,sc$,ec,a$
;

; Write SCSI block to device
58300 by=wh:gosub60200:wh$=he$
58301 by=wm:gosub60200:wm$=he$
58302 by=wl:gosub60200:wl$=he$

; SCSI WRITE
58320 he$="2a0000"+wh$+wm$+wl$+"00000100":gosub60100:sc$=by$

; SCSI WRITE AND VERIFY
; (Not yet supported in VICE 3.5)
;58320 he$="2e0000"+wh$+wm$+wl$+"00000100":gosub60100:sc$=by$

; Send SCSI command
58330 gosub59800

; All done
58390 return
