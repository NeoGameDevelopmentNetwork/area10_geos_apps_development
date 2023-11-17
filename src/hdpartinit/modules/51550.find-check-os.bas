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
; 51550.find-check-os.bas - find system o.s.
;
; parameter: bc    = 64k system area to be checked
;            sd    = cmd-hd scsi device id
; return   : er    = 0/system o.s. found
; temporary: ba,rh,rm,rl,bh,bm,bl,ad,hi,lo,i,a$,bu(x),es
;

; Find system o.s.

; Calculate the lba including the system o.s.
;  -> $xx:0E00-$xx:79FF
51550 ba=bc*128+60

; Convert LBA to h/m/l
51556 gosub58900:rh=bh:rm=bm:rl=bl

; Read block from disk
51560 gosub58200

; Read 16 data bytes into buffer.
51561 ad=sb+160:hi=int(ad/256):lo=ad-hi*256
51562 print#15,"m-r"chr$(lo)chr$(hi)chr$(6)
51563 fori=0to5
51564     get#15,a$:bu(160+i)=asc(a$+nu$)
51565 next

; Test for "CMD HD" to match a valid system o.s.
51570 es=0:fori=0to5
51571     ifbu(160+i)<>asc(mid$("cmd hd",1+i,1))thenes=1:i=5
51572 next

; All done
51590 return
