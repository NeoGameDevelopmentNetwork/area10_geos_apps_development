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
; 50800.controller-reset.bas - reset CMD-HD scsi controller
;
; parameter: dv    = cmd-hd device address
; return   : sd    = cmd-hd scsi device id
;            si(x) = device type
;            sm(x) = removable media
; temporary: k$
;
; Note: Currently not used.
;       This code was part of 53000.format-disk.s
;

; ; Reset SCSI controller
; 50800 print"  reset scsi controller"
;
; ; Open command channel
; 50820 open15,dv,15
;
; ; Write job address $00/$00
; 50821 ec=2:print#15,"m-w"chr$(8)chr$(0)chr$(2)chr$(0)chr$(0)
;
; ; Write job code $82 for CONTROLLER RESET
; 50822 print#15,"m-w"chr$(0)chr$(0)chr$(1)chr$(130)
;
; ; Read job queue ERROR code
; ; 0/1 = OK
; ; >=2 = ERROR
; 50823 print#15,"m-r"chr$(0)chr$(0)chr$(1)
; 50824 get#15,a$:es=asc(a$+nu$)
; 50825 ifes>=128thengoto50824
; 50826 ifes<2thengoto50890
;
; 50827 ec=ec-1:ifec>0thengoto50822
;
; ; "Disk error"
; 50830 gosub9200
; ; Wait for return
; 50831 gosub60400
;
; ; Close command channel
; 50890 close15
; 50891 return
