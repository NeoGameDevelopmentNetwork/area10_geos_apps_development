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
; 12600.menu-change-stdpart.bas - menu: change cmd-hd default partition
;

; Change cmd-hd default partition
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
12600 printtt$:print"  change cmd-hd default partition{down}"

; Get current default partition
12610 dv=dd:bb=226:gosub51200:ifes>0thengoto12690
12611 bx=bv

; Print options
12620 printleft$(po$,10)
12621 print"  press +/-/* to switch partition,"
12622 print"  press <return> to set partition or"
12623 print"  press <x> to cancel."

; Print selected address
12630 printleft$(po$,8)
12631 print"  cmd-hd default partition:";bv;"{left}  "

; Wait for a key
12640 getkb$:ifkb$=""thengoto12640
12641 ifkb$="x"thengoto12690
12642 ifkb$=chr$(13)thengoto12650
12643 ifkb$="+"thenbv=bv+1:ifbv>254thenbv=1
12644 ifkb$="-"thenbv=bv-1:ifbv<1thenbv=254
12645 ifkb$="*"thenbv=bv+10:ifbv>254thenbv=254
12646 if(kb$="+")or(kb$="-")or(kb$="*")thengoto12630
12647 goto12640

; Default p<rtition changed?
12650 ifbx=bvthengoto12690

; Set new default address
12660 printtt$:print"  change cmd-hd default partition:{down}"

; Print device info
12662 gosub13900
12663 print"  new default partition:";bv

; Update CMD-HD default partition
; CMD HD-TOOLS.64 writes that value to $xx:05E2+$xx:05E3
12670 bb=226:gosub51300:ifes>0thengoto12675
12671 bb=227:gosub51300:ifes>0thengoto12675

; "Done"
12672 gosub9000
12673 goto12680

; "Disk error"
12675 gosub9200
; Wait for return
12680 gosub60400

; All done
12690 return
