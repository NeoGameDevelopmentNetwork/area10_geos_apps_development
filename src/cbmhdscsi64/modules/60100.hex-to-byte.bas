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
; 60100.hex-to-byte.bas - convert hex-ascii string to bytes
;
; parameter: he$   = hex-ascii string
; return   : by$   = byte string
; temporary: i, lo, hi
;

; Convert HEX-ascii to bytes
60100 by$="":fori=1tolen(he$)step2
60110 hi=asc(mid$(he$,i+0,1))-48:ifhi>9thenhi=hi-7
60120 lo=asc(mid$(he$,i+1,1))-48:iflo>9thenlo=lo-7
60130 by$=by$+chr$(hi*16+lo)
60140 next
60190 return
