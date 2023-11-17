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
; 51200.get-cfgbyte.bas - get cmd-hd default address
;
; parameter: dv    = cmd-hd device address
;            bb    = byte address
;                    225 = default device address
;                    226 = default device partition
; return   : bv    = cmd-hd default value
; temporary: he$,ba,bh,bm,bl,rh,rm,rl
;

; Get CMD-HD default value

; Find system area
51200 es=0:ifso<0thengosub51400:ifes>0thengoto51290

; Set base address to $xx:0400-$xx:$05FF
51205 ba=so+2

; Open command channel
51210 open15,dv,15

; Convert LBA to h/m/l
51211 gosub58900:rh=bh:rm=bm:rl=bl

; Read block from disk
51215 gosub58200

; Read address $01E1 = CMD-HD default address
51220 ad=sb+256+bb:hi=int(ad/256):lo=ad-hi*256
51222 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
51223 get#15,a$:bv=asc(a$+nu$)

; Close command channel
51240 close15
51290 return
