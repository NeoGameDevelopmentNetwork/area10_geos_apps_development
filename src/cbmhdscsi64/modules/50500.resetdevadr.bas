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
; 50500.resetdevadr.bas - reset device address
; This will reset the device address of the CMD-HD back
; to the address before configuration mode was enabled.
;
; parameter: h1    = default address
;            h2    = 0/8/9 swap mode
;            h3    = 0/dev u0>x address
;            sd    = cmd-hd scsi device id
; return   : -
; temporary: a,a$
;

; Reset device address
50500 dv=h1

; Test for SWAP8/9 buttons
50520 ifh2=0thengoto50530
50522 open15,dv,15,"s-"+chr$(48+h2):close15
50525 dv=h2

; Test for custom device address
50530 ifh3=0thengoto50540
50532 open15,dv,15,"u0>"+chr$(h3):close15
50535 dv=h3

; Print new CMD-HD device address
50540 print"  cmd-hd device address: ";
50541 printmid$(str$(dv),2);":";chr$(48+sd)

; All done
50590 return

