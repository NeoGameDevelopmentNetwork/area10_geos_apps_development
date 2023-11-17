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
; 12400.menu-change-stdadr.bas - menu: change cmd-hd default address
;

; Change cmd-hd default address
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
12400 printtt$:print"  change cmd-hd default address{down}"

; Get current device address
12410 dv=dd:bb=225:gosub51200:ifes>0thengoto12690
12411 bx=bv

; Print list of active devices
12420 fori=0to1
12421     forj=0to9
12422         printleft$(po$,15+j);
12423         fork=0toi*18:print"{right}";:next
12424         print"  ";right$("  "+str$(8+i*10+j),2);":";
12425         open15,(8+i*10+j),15:close15
12426         a$="none":ifst=0thena$="active"
12427         printa$
12428     next
12429 next

; Print options
12430 printleft$(po$,10)
12431 print"  press +/- to switch device address,"
12432 print"  press <return> to set new address or"
12433 print"  press <x> to cancel."

; Print selected address
12440 printleft$(po$,8)
12441 print"  cmd-hd default address:";bv;"{left}  "

; Wait for a key
12450 getkb$:ifkb$=""thengoto12450
12451 ifkb$="x"thengoto12490
12452 ifkb$=chr$(13)thengoto12460
12453 ifkb$="+"thenbv=bv+1:ifbv>29thenbv=8
12454 ifkb$="-"thenbv=bv-1:ifbv<8thenbv=29
12455 ifbx=bvthengoto12440
12456 open15,bv,15:close15:if(st=0)and(bv<>dd)thengoto12453
12457 if(kb$="+")or(kb$="-")thengoto12440
12458 goto12450

; Default address changed?
12460 ifbx=bvthengoto12490

; Set new default address
12461 printtt$:print"  change cmd-hd default address:{down}"

; Print device info
12463 dv=bv:gosub13900:dv=dd

; Update CMD-HD default address
; CMD HD-TOOLS.64 writes that value to $xx:05E1+$xx:05E4
12470 bb=225:gosub51300:ifes>0thengoto12480
12471 bb=228:gosub51300:ifes>0thengoto12480

; Send Job-code for "Reset SCSI controller"
12472 cj$="00":gosub51900

; "Done"
12473 gosub9000

; Wait for return
12474 gosub60400

; Scan for CMD-HD devices
12475 printtt$
12476 gosub10200:ifes<>0thengoto12480
12477 goto12490

; "Disk error"
12480 gosub9200
; Wait for return
12481 gosub60400

; All done
12490 return
