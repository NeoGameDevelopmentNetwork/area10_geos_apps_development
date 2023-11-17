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
; 55800.sysfile-search.bas - search for a system file
;
; parameter: ga    = system file device
; return   : es    = status
; temporary: a$,b$
;

; Search for a system file
; Return error if file is not found.

; Open command channel
55800 open15,ga,15:open2,ga,0,ff$

; Read status message from device
; -> 00, ok, 00, 00 = no error
55810 get#15,a$,b$:es=(asc(a$+nu$)-48)*10+(asc(b$+nu$)-48)

; Close command channel
55830 close2:close15

; All done
55890 return
