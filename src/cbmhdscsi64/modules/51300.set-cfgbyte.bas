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
; 51300.set-cfgbyte.bas - set cmd-hd default values
;
; parameter: dv    = cmd-hd device address
;            by    = byte address
;                    225 = default device address
;                    226 = default device partition
;            bv    = new cmd-hd default value
;            bx    = old cmd-hd default value
; return   : -
; temporary: he$,ba,bh,bm,bl,rh,rm,rl,wh,wm,wl
;

; Set CMD-HD default value

; Find system area
51300 es=0:ifso<0thengosub51400:ifes>0thengoto51390

; Set base address to $xx:0400-$xx:05FF
51305 ba=so+2

; Open command channel
51310 open15,dv,15

; Convert LBA to h/m/l
51311 gosub58900:rh=bh:rm=bm:rl=bl

; Read block from disk
51315 gosub58200

; Read address $01E1/2 = CMD-HD default value
51320 ad=sb+256+bb:hi=int(ad/256):lo=ad-hi*256

; Read default value and verify that value is unchanged
51322 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
51323 es=0:get#15,a$:if(bx<>asc(a$+nu$))thenes=1:goto51380

; Set new default value
51330 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(bv)

; Convert LBA to h/m/l
; Block address still in buffer
; 51340 gosub58900:wh=bh:wm=bm:wl=bl

; Write block to disk
51341 wh=bh:wm=bm:wl=bl:gosub58300

; Close command channel
51380 close15
51390 return
