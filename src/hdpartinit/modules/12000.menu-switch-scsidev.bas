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
; 12000.menu-switch-scsidev.bas - menu: select new scsi device
;

; Select new SCSI device as active device for CMD-HD.
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
12000 printtt$:print"  selected scsi device:{down}"

; Print device info
12010 dv=dd:gosub13900

; Find system area on device
12020 es=0:ifso<0thengosub51400:ifes>0thengoto12090

; Find partition table
12025 pn=0
12026 gosub49200:ifes>0thengoto12050
12027 ifbu(2)<>255thengoto12050
12028 if(bu(30)*256+bu(31))<>144thengoto12050

; Switch scsi device
12030 print"  changing active scsi device"
12031 gosub52000

; Reset device address
12040 gosub50500
12041 goto12060

; Error: No partition table.
12050 print"  no partition table found!"
12051 goto12080

; "Done"
12060 gosub9000
12061 pl=-1:so=-1:tb=-1

; "Press <return> to continue."
12080 gosub60400
12090 return
