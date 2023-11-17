; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Linker file for DESK TOP
;
; Reassembled (w)2020 by Markus Kanet
;
; Revision V0.3
; Date: 23/03/23
;
; History:
; V0.1 - Initial release.
;
; V0.2 - Updates for MegaAssembler.
;
; V0.3 - Added english translation.
;

			n "DESK TOP"

;--- Note:
;Newer versions of GEOS/MegaAssembler
;will get a/c/h from the first module.
;
;			c "deskTop  GE V2.0",NULL
;			h "deskTop verwaltet Ihre Disketten und Dateien."
;
;			c "deskTop AM  V2.0",NULL
;			h "Use the deskTop to manage and manipulate your files."
;
;			a "Brian Dougherty",NULL
;---

			m
			- "obj.DeskTop"
			- "obj.mod#1"
			- "obj.mod#2"
			- "obj.mod#3"
			- "obj.mod#4"
			- "obj.mod#5"
			/
