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
; 09500.program-messages.bas - program messages
;

; Program messages
9500 print"  clear partition table:{down}":return
9510 print"      no more partitions found!":return
9520 print"  press <return> for main menu.":return
9540 print"  press <x> to cancel.{down}":return
9550 print"  erase content from disk";:return
9560 print"  create new partition:{down}":return
9570 print"  enable configuration mode";:return
