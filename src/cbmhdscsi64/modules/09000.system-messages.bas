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
; 09000.system-messages.bas - system messages
;

; Status messages
9000 print"{down}  done!{down}":return
9010 print"  press <return> to continue.":return

; No cmd hd found
9100 printtt$
9101 print"{down}no cmd-hd found!"
9110 print"exiting now!"
9120 return

; Unknown error
9200 print"{down}  disk error:";es;"{down}":return
