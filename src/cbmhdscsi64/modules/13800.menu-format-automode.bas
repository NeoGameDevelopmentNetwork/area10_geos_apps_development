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
; 13800.menu-format-automode.bas - menu: auto-format media
;

; Check system files...
13800 gosub54800:ifec>0thengoto13892

; Initialize media
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
13805 printtt$:print"  initialize cmd-hd scsi device:{down}"

; Print device info
13810 dv=dd:gosub13900

; Print warning
13820 gosub13910:gosub13930

; Print options
13821 gosub13950

; Wait for a key
13830 getk$:ifk$=""thengoto13830
13831 if(k$="s")or(k$="S")thengosub11000:goto13800
13832 if(k$="y")or(k$="Y")thengoto13840
13833 if(k$="n")or(k$="N")thengoto13885
13834 goto13830

; Initialize SCSI device
13840 ifmk$="i"thenmk$=af$:goto13860

; Format SCSI device
13850 gosub53000
13851 ifk$="x"thengoto13885
13852 ifes>0thengoto13890

; Wait a few seconds
13853 gosub51800

; Verify media
13855 gosub53200
13856 ifes>0thengoto13890

; Create system area
13860 gosub54000:ifes>0thengoto13890

; Write new system os
13861 gosub55400:ifes>0thengoto13890

; Create new partition table
13862 gosub54400:ifes>0thengoto13890

; Format successful.
13870 print"{down}{down}  initializing disk successful!{down}"

; Wait for return
13880 gosub60400
13885 es=0:return

; Format failed.
13890 print"{down}{down}  initializing disk failed!{down}"

; Wait for return
13891 gosub60400
13892 es=2:return
