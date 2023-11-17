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
; 10200.menu-find-cmdhd.bas - menu: find cmd-hd devices
;

; Find CMD-HD devices
10200 gosub50100:ifes<>0thengoto10290

; Get device system data
; Note: 'dd' is the default CMD-HD device.
10220 dv=dd:gosub50400

; Get active SCSI-ID
10230 gosub50900

; Send command: SCSI INQUIRY
10240 gosub59200

; All done
10290 return
