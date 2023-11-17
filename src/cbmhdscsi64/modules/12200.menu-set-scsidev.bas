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
; 12200.menu-set-scsidev.bas - menu: enable config mode for scsi device
;

; Enable configuration mode for HDTOOLS.64
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
12200 printtt$
; "Enable configuration mode"
12201 gosub9570:print":{down}"

; Print device info
12210 dv=dd:gosub13900

; Find system area
; Always check for a valid system area!
12220 gosub51400:ifes>0thengoto12290
; Wait a second...
12221 gosub51800

; Valid SCSI device found...
12230 printtt$
; "Enable configuration mode"
12231 gosub9570:print":{down}"

; Print device info
12240 gosub13900

; "Enable configuration mode"
12250 gosub9570:print
12251 gosub51000

; Switch active SCSI device
12260 print"  set active scsi device{down}"
12261 gosub52200

; Print status message
12270 print"  cmd-hd/scsi device is configured!{down}"
12271 print"  use the cmd 'hd-tools.64' program to"
12272 print"  configure the cmd-hd/scsi device.{down}"
12273 print"  press 'reset' on the cmd-hd to exit"
12274 print"  the cmd-hd configuration mode.{down}"

; Exit programm
12280 es=-127

12290 return
