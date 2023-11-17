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
; 59100.scsi-ready.bas - TEST UNIT READY
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
; return   : ed    = status byte
; temporary: i,a$,he$,sc$,by$
;

;--- 6 Bytes
;SCSI command  : TEST UNIT READY
; -Operation Code $00
; -Reserved 4 Bytes
; -Control
;Return        : 1 Byte
;$00           : OK
;$02           : No media
;$8x           : Not ready
;scsiREADY       b "S-C"
;scsiREADY_id    b $00
;                w $4000
;                b $00,$00,$00,$00,$00,$00

; SCSI TEST UNITY READY
59100 he$="000000000000":gosub60100:sc$=by$

; Open command channel
59110 open15,dv,15

; Send SCSI command
59120 gosub59900:get#15,a$:es=asc(a$+nu$)

; Close command channel
59130 close15

; All done
59190 return
