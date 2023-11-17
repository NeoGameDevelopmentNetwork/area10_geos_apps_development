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
; 50400.getdevdata.bas - get cmd-hd device info
; This will read the default device address of the
; cmd-hd, the swap-8/9 mode and the changed device
; address using the "u0>x" command.
;
; parameter: dv    = device address
; return   : es    = error status
;            h1    = default address
;            h2    = 0/8/9 swap mode
;            h3    = 0/dev u0>x address
; temporary: a,a$
;

; Test device
50400 open15,dv,15:close15:ifst<>0thenes=st:goto50490

; Open command channel
50410 open15,dv,15

; Read default CMD-HD device address
50420 print#15,"m-r"chr$(225)chr$(144)chr$(1)
50425 get#15,a$:h1=asc(a$+nu$)

; Read current device address:
; bit%7=0 + dv  = default device address
; bit%7=1 + 8/9 = swap 8/9 enabled
50430 print#15,"m-r"chr$(228)chr$(144)chr$(1)
50435 get#15,a$:h2=asc(a$+nu$)
50440 close15

; If no swap is active, then swap-address = 0
; If swap 8/9 is active, then swap-address = 8/9
50450 ifh2=dvthengoto50453
50451 ifh2=(128+8)thenh2=8:goto50460
50452 ifh2=(128+9)thenh2=9:goto50460
50453 h2=0

; Test for a CMD-HD with default device address
50460 ifh1=dvthenh2=0:h3=0:goto50490

; Test for a CMD-HD with swap-8/9 enabled
50461 ifh2=dvthenh3=0:goto50490

; CMD-HD with changed device address using u0>x
50462 h3=dv

; print device system data
; 50470 print"cmd-hd"dv": default:"h1
; 50475 print"cmd-hd"dv": swap   :"h2
; 50480 print"cmd-hd"dv": current:"h3

; All done
50490 return
