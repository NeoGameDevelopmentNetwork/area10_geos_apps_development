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
50500 gosub 50580

; Print new CMD-HD device address
50510 print"  cmd-hd device address: ";
50511 printmid$(str$(dv),2);":";chr$(48+sd)

; All done
50520 return




; Reset device address
50570 dv=h1

; Test for SWAP8/9 buttons
50580 ifh2=0thengoto50590
50582 open15,dv,15,"s-"+chr$(48+h2):close15
50585 dv=h2

; Test for custom device address
50590 ifh3=0thengoto50599
50592 open15,dv,15,"u0>"+chr$(h3):close15
50595 dv=h3

; All done
50599 return
