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
; 01500.main-menu.bas - main menu
;

; Main menu

; Print title
1500 printtt$

; Print main menu
1505 gosub1800




; Scan for CMD-HD devices
; -> Exit program if no CMD-HD found
1510 ifdv=0thengosub10200:ifes<>0thenstop

; Scan for SCSI devices
1520 ifhs>=0thengoto1530
1521 gosub50600
1522 hs=sd:gosub3150:ht=sd

; Do not search for partitions automatically
; 1525 ifcs<0thenpn=0:gosub3300
; 1526 ifct<0thenpn=0:gosub3400

; Reset error flag
1530 es=0

; Print device info
1535 gosub2000



; Wait for a key
1540 getmk$:ifmk$=""thengoto1540

; Exit program ?
1541 ifmk$=chr$(95)thengoto1790

; DEVICE
; <H>   = Select CMD-HD
; Note: Always reset SCSI device information
1550 ifmk$="h"thengosub3000:goto1700:rem reset scsi dev info

; F1/F3 = Select source/target SCSI device
1551 ifmk$=chr$(133)thengosub3100:goto1530:rem reset error flag
1552 ifmk$=chr$(134)thengosub3110:goto1530:rem reset error flag

; F2/F4 = Source/Target partition list
1553 ifmk$=chr$(137)andhs>=0thensd=hs:so=os:gosub48500:goto1500:rem reset menu
1554 ifmk$=chr$(138)andht>=0thensd=ht:so=ot:gosub48500:goto1500:rem reset menu

; F5/+ = Select source partition +1/+10
1555 ifmk$=chr$(135)thengosub3300:goto1530:rem reset error flag
1556 ifmk$="+"thengosub3310:goto1530:rem reset error flag

; F7/* = Select target partition +1/+10
1557 ifmk$=chr$(136)andcs>0thengosub3400:goto1530:rem reset error flag
1558 ifmk$="*"andcs>0thengosub3410:goto1530:rem reset error flag

; F6/F8 = Enter source/target partition
1559 ifmk$=chr$(139)thengosub3600:goto1530:rem reset error flag
1560 ifmk$=chr$(140)thengosub3700:goto1530:rem reset error flag

; COPY
1565 ifmk$="c"thengosub20000:goto1530:rem reset error flag

; Directory
1570 if(mk$="s")and(hs>=0)and(cs>0)thengosub30000:goto1500:rem reset menu
1571 if(mk$="t")and(ht>=0)and(ct>0)thengosub30100:goto1500:rem reset menu

; Eject media
1580 ifmk$="a"thengosub10300:goto1530:rem reset error flag
1581 ifmk$="b"thengosub10350:goto1530:rem reset error flag

; Unknown key...
1590 goto1540




; DEVICE -> <F1> / <F3> / <F5> / <F7>
; MANAGE -> <c>
; If no error, restart menu...
1700 ifes>=0thengoto1520:rem reset scsi dev info
1710 end

; Exit programm...
1790 print"{clr}good bye!":end
