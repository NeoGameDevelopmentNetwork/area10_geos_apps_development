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
; 13900.menu-format-info.bas - menu: print text messages
;

; Print device info
13900 print"    cmd-hd  :";dv
13901 print"    scsi id :";sd
; LUN is always '0' here...
; 13902 print"    scsi lun :";0
13903 print"    vendor  : '";sv$(sd);"'"
13904 print"    product : '";sp$(sd);"'{down}"
13909 return

; Format messages
13910 print"  warning: this will destroy all data"
13911 print"  on the specified scsi-drive!{down}"
13919 return

; Create new system area on selected SCSI device
13920 print"  this will create a new system"
13921 print"  area on the selected scsi device.{down}"
13922 print"  warning: continuing will cause any"
13923 print"  data and partitions to be lost!{down}"
13929 return

; Write new main o.s. and geos/hd driver
13930 print"  this will install a new hd-os and"
13931 print"  geos/hd driver onto your cmd-hd.{down}"
13932 print"  important: you need a floppy disk in"
13933 print"  drive";ga;"with these system files:"
13934 print"  '";s3$;"', '";s0$;"' and"
13935 print"  '";s1$;"'.{down}"
13939 return

; Clear partition table
13940 print"  this will clear the current partition"
13941 print"  table on the selected scsi device.{down}"
13942 print"  warning: continuing will cause any"
13943 print"  data and partitions to be lost!{down}"
13949 return

; Print options
13950 print"  press <s> to select new scsi device."
13951 print"  continue (y/n/s)?"
13952 return
