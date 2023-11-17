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
; 58200.disk-hd-read.bas - read scsi-block from device
;
; parameter: bu(x) = 512 data bytes
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            rh    = lba high-byte
;            rm    = lba medium-byte
;            rl    = lba low-byte
; return   : es    = error status
; temporary: by,by$,he$,rh$,rm$,rl$,sc$,ec,a$
;

; Read SCSI block from device
58200 by=rh:gosub60200:rh$=he$
58201 by=rm:gosub60200:rm$=he$
58202 by=rl:gosub60200:rl$=he$

58220 he$="280000"+rh$+rm$+rl$+"00000100":gosub60100:sc$=by$

; Send SCSI command
58230 gosub59800

; All done
58290 return
