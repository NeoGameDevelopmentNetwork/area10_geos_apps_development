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
; 39800.directory-bam-offset.bas - define bam/directory offset
;

; Define partition type values
39800 d0=178:d1=256:d2=144:return:rem bam lba-offset 1541/71
39810 d0=780:d1=0:d2=4:return:rem bam lba-offset 1581
39820 d0=0:d1=256:d2=4:return:rem bam lba-offset native

;        1234567890123456789012345678901234567890
;                               press <return>
39900 em$="unknown error!":rem goto39980

39980 printleft$(po$,24);left$(ta$,2);em$;

; Test for "Exit to main menu"
39982 ifk$=chr$(95)thengoto39999

; Press return to continue
39983 printleft$(po$,24);sl$
39984 print"{up}  press <return> to continue."

; Wait for return
39990 gosub60400
39999 return
