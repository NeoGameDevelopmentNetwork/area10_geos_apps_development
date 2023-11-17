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
; -> F1: Search for CMD-HD devices
1550 ifmk$=chr$(133)thengosub10200:goto1700:rem reset scsi dev info
; -> F3: Select CMD-HD
1551 ifmk$=chr$(134)thengosub10000:goto1700:rem reset scsi dev info
; -> F5: Select new SCSI device
1552 ifmk$=chr$(135)thengosub11000:goto1700:rem reset scsi dev info
; -> F7: Set new SCSI device
1553 ifmk$=chr$(136)thengosub12000:goto1700:rem reset scsi dev info
; -> F8: Eject disk
1554 ifmk$=chr$(140)thengosub59600:goto1500:rem reset scsi dev info
; -> F6: Display partition directory
1555 ifmk$=chr$(139)thengosub48500:goto1505:rem reset error status

; HD.INI
; -> Select system device
1560 ifmk$="d"thengosub10100:goto1505:rem reset error status
; -> Edit config filename
1561 ifmk$="e"thengosub10300:goto1505:rem reset error status
; -> Load hd.ini from sysfile device
1562 ifmk$="l"thengosub30200:goto1505:rem reset error status
; -> Save hd.ini to sysfile device
1563 ifmk$="s"thengosub30000:goto1505:rem reset error status
; -> Clear all partitions
1564 ifmk$="c"thengosub30100:goto1505:rem reset error status
; -> List current partitions
1565 ifmk$="p"thengosub31000:goto1505:rem reset error status
; -> Write new partition table
1566 ifmk$="w"thengosub35000:goto1505:rem reset error status
; -> Validate partition table
1567 ifmk$="v"thengosub30400:goto1505:rem reset error status
; -> List ini files
1568 ifmk$="$"thengosub15000:goto1505:rem reset error status

; PARTITION
; -> Import partition table from SCSI device
1580 ifmk$="i"thengosub32000:goto1505:rem reset error status
; -> Remove partition
1581 ifmk$="r"thengoto1630
; -> Get free partition
1582 ifmk$="+"ormk$="*"ormk$="f"thengoto1600

; CREATE
; -> Create new partition
1583 ifmk$="4"ormk$="7"ormk$="8"ormk$="n"thengoto1620
1584 ifmk$="m"ormk$="0"ormk$="b"thengoto1620
; -> Switch auto-create mode
1585 ifmk$="a"thenap=1-ap:goto1520

; Unknown key...
1590 goto1540




; PARTITION -> Get free partition
1600 ifpf<0thengosub30300
1601 ifpf=0thengosub38090:goto1530:rem print main menu
1602 ifmk$="+"thengosub39100
1603 ifmk$="*"thengosub39150
1604 ifmk$="f"thenpn=1:gosub39000
; Update free partition value
1605 gosub1850
; Return to menu
1610 goto1540




; PARTITION -> Create
1620 ifpf<0thengosub30300
1630 ifmk$="4"thengosub38000
1631 ifmk$="7"thengosub38010
1632 ifmk$="8"thengosub38020
1633 ifmk$="m"thengosub38025
1634 ifmk$="n"thengosub38030
1635 ifmk$="0"thengosub38040
1636 ifmk$="b"thengosub38045

; PARTITION -> Delete
1640 ifmk$="r"thengosub38100

; Return to menu
1650 goto1505:rem reset error status




; DEVICE -> <F1> / <F3> / <F5> / <F7>
; If no error, restart menu...
1700 ifes>=0thengoto1500:rem reset scsi dev info
1710 end

; Exit programm...
1790 print"{clr}good bye!":end
