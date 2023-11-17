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
; 13000.menu-format.bas - menu: format menu data
;

; Check system files...
13000 gosub54800:ifec>0thengoto13090

; Format scsi device
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
13005 printtt$:print"  format cmd-hd scsi device:{down}"

; Print device info
13010 dv=dd:gosub13900

; Print warning
13020 gosub13910

; Print options
13021 gosub13950

; Wait for a key
13030 getk$:ifk$=""thengoto13030
13031 if(k$="s")or(k$="S")thengosub11000:goto13000
13032 if(k$="y")or(k$="Y")thengoto13040
13033 if(k$="n")or(k$="N")thenes=2:goto13090
13034 goto13030

; Format device
13040 gosub53000
13090 return
