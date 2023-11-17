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
; 51900.scsi-controller.bas - send job-code to cmd-hd
;
; parameter: dv    = cmd-hd device address
;            cj$   = config mode job
;                    00 = reset scsi controller
;                    06 = enable cmd-hd configuration mode
;                    14 = disable cmd-hd configuration mode
; return   : -
; temporary: he$,by$
;

; Send configuration mode job

; initialize data buffer
51900 he$=    "78"     :rem sei
51901 he$=he$+"a992"   :rem lda #$92
51902 he$=he$+"8d0388" :rem sta $8803
51903 he$=he$+"a9e3"   :rem lda #$e3
51904 he$=he$+"8d0288" :rem sta $8802
51905 he$=he$+"a9"+cj$ :rem lda #$xx
51906 he$=he$+"18"     :rem clc
51907 he$=he$+"08"     :rem php
51908 he$=he$+"4cedde" :rem jmp $deed

; Send program to CMD-HD and execute it
51910 gosub51950:return
