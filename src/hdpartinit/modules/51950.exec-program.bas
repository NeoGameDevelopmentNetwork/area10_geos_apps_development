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
; 51950.exec-program.bas - send program to cmd-hd and execute it
;
; parameter: dv    = cmd-hd device address
;            by$   = program code
; return   : -
; temporary: -
;

; Send configuration mode job

; Convert data buffer from HEX-Ascii to binary format
; Entry point for 52000.switch-scsi.s
51950 gosub60100

; Send programm to CMD-HD and execute it
51960 open15,dv,15
51961 print#15,"m-w"chr$(0)chr$(3)chr$(len(by$))by$
51962 print#15,"m-e"chr$(0)chr$(3)
51963 close15

; Give controller some time for the RESET
51970 gosub51800

; All done
51990 return
