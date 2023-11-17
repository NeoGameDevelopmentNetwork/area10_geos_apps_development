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
; 39600.directory-clear-page.bas - clear directory page
;

; Clear directory page
39600 printleft$(po$,6);
39610 printc0$;li$;c1$
39620 fori=0to15:printvi$;sl$;vi$:next
39630 printc2$;li$;c3$
39640 printleft$(po$,24);
39641 print"  searching...    press <";chr$(95);"> to cancel";
39690 return
