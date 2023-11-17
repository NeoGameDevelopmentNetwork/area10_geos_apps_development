; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 60200.byte-to-hex.bas - convert byte to hex-ascii
;
; parameter: by    = byte
; return   : he$   = hex-ascii string
; temporary: i
;

; Convert byte to HEX-ascii
60200 he$=""
60210 i=(byand240)/2/2/2/2
60220 gosub60240
60230 i=(byand15)
60240 he$=he$+mid$("0123456789abcdef",i+1,1)
60290 return
