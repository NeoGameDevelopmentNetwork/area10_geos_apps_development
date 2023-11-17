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
; 01500.main-menu.bas - main menu
;

; Main menu
; Reset system area offset
1500 so=-1

; Reset partition info
1502 pf=-1:pl=-1

; Reset error flag
1505 es=0

; Print title
1510 printtt$




; Update main menu options
; Define values for Auto-create mode
1520 ifap<>0thenap$="<auto>":am$="16mb"
1521 ifap =0thenap$="      ":am$="    "

; Print main menu
1530 gosub1800




; Wait for a key
1540 getmk$:ifmk$=""thengoto1540

; Exit program ?
1541 ifmk$=chr$(95)thengoto1790

; DEVICE
; Always reset SCSI device information
1550 ifmk$=chr$(133)thengosub10200:goto1700:rem reset scsi dev info
1551 ifmk$=chr$(134)thengosub10000:goto1700:rem reset scsi dev info
1552 ifmk$=chr$(135)thengosub11000:goto1700:rem reset scsi dev info
1553 ifmk$=chr$(136)thengosub12000:goto1700:rem reset scsi dev info
1554 ifmk$=chr$(140)thengosub59600:goto1500:rem reset scsi dev info

; FORMAT
1560 ifmk$="l"thengosub10100:goto1505:rem reset error status
1561 ifmk$="c"thengosub55000:goto1500:rem reset scsi dev info
1562 ifmk$=af$thengosub13800:goto1500:rem reset scsi dev info
1563 ifmk$="m"thengosub13000:goto1500:rem reset scsi dev info
1564 ifmk$="e"thengosub53500:goto1500:rem reset scsi dev info
1565 ifmk$="s"thengosub13200:goto1500:rem reset scsi dev info
1566 ifmk$="o"thengosub13300:goto1505:rem reset error status
1567 ifmk$="t"thengosub13400:goto1502:rem reset partition info
1568 ifmk$="i"thengosub13800:goto1500:rem reset scsi dev info
1569 ifmk$="v"thengosub53200:goto1505:rem reset error status

; DEFAULTS
1570 ifmk$="d"thensd=0:gosub12400:goto1500:rem reset scsi dev info
1571 ifmk$="p"thengosub12600:goto1505:rem reset error status

; MANAGE
1575 ifmk$="k"thengosub12200:goto1700:rem reset scsi dev info
1577 ifmk$="h"thengosub59650:goto1500:rem reset scsi dev info

; PARTITION
; -> Switch auto-create mode
1580 ifmk$="a"thenap=1-ap:goto1520
; -> Partition directory / Remove partition
1581 ifmk$="$"ormk$="r"thengoto1620
; -> Get free partition
1582 ifmk$="+"ormk$="*"ormk$="1"thengoto1600
; -> Create new partition
1583 ifmk$="4"ormk$="7"ormk$="8"ormk$="n"ormk$="0"thengoto1620

; Unknown key...
1590 goto1540




; PARTITION -> Get free partition
1600 ifpf<0thenprinttt$:gosub40900:printtt$:gosub1800:goto1540
1601 ifpf=0thengosub1790:goto1502:rem reset partition info
1602 ifmk$="+"thengosub48800
1603 ifmk$="*"thengosub48850
1604 ifmk$="1"thenpn=0:gosub48700
; Update free partition value
1605 gosub1850
; Return to menu
1610 goto1540




; PARTITION -> Create/Directory/Remove
1620 if(so>=0)and(pl>=0)thengoto1630

; PARTITION -> Get disk info
1621 printtt$:print"  partition menu:{down}"
1623 dv=dd:gosub13900

; PARTITION -> Find system area
1624 es=0:ifso<0thengosub51400:ifes>0thengoto1650

; PARTITION -> Analyze partition table
1625 gosub40900:ifes>0thengoto1650

; PARTITION -> Create
1630 ifmk$="4"thengosub40100
1631 ifmk$="7"thengosub40110
1632 ifmk$="8"thengosub40120
1633 ifmk$="n"thengosub40130
1634 ifmk$="0"thengosub40140

; PARTITION -> Remove
1640 ifmk$="r"thengosub40500

; PARTITION -> Directory
1641 ifmk$="$"thengosub48500

; Return to menu
1650 goto1505:rem reset error status




; DEVICE -> <F1> / <F3> / <F5> / <F7>
; MANAGE -> <c>
; If no error, restart menu...
1700 ifes>=0thengoto1500:rem reset scsi dev info
1710 end

; Exit programm...
1790 print"{clr}good bye!":end
