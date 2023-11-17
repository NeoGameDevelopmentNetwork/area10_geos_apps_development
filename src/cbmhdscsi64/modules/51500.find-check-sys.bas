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
; 51500.find-check-sys.bas - find system area
;
; parameter: bc    = 64k system area to be checked
;            sd    = cmd-hd scsi device id
; return   : er    = 0/system area found
; temporary: ba,rh,rm,rl,bh,bm,bl,ad,hi,lo,i,a$,bu(x),es
;

; Find system area
51500 es=255

; Calculate the lba including a system area
; This is always inside of a 64Kb area in lba #2/512 bytes.
;  -> $xx:0400-$xx:05ff
51505 ba=bc*128+2

; Convert LBA to h/m/l
51506 gosub58900:rh=bh:rm=bm:rl=bl

; Read block from disk
51510 gosub58200

; We do not need the complete 512 data of the block.
; Just check the last 16 bytes to match the CMD-HD
; detection code.
; Read data into block data buffer
;51511 gosub58100

; Read 16 data bytes into buffer.
51511 ad=sb+256+240:hi=int(ad/256):lo=ad-hi*256
51512 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
51513 fori=0to15
51514     get#15,a$:bu(256+240+i)=asc(a$+nu$)
51515 next

; Check for "CMD HD"
; 51520 ifbu(256+240)<>asc("c")thengoto51540
; 51521 ifbu(256+241)<>asc("m")thengoto51540
; 51522 ifbu(256+242)<>asc("d")thengoto51540
; 51523 ifbu(256+243)<>asc(" ")thengoto51540
; 51524 ifbu(256+244)<>asc("h")thengoto51540
; 51525 ifbu(256+245)<>asc("d")thengoto51540
; 51526 ifbu(256+246)<>asc(" ")thengoto51540
; 51527 ifbu(256+247)<>asc(" ")thengoto51540
; This code is shorter then the single byte check above...
51520 es=0:fori=0to7
51521     ifbu(256+240+i)<>asc(mid$("cmd hd  ",1+i,1))thenes=1:i=7
51522 next:ifes>0thengoto51540

; Check for additional data bytes
51530 ifbu(256+248)<>141thengoto51540 :rem sta $8803
51531 ifbu(256+249)<>3  thengoto51540
51532 ifbu(256+250)<>136thengoto51540
51533 ifbu(256+251)<>142thengoto51540 :rem stx $8802
51534 ifbu(256+252)<>2  thengoto51540
51535 ifbu(256+253)<>136thengoto51540
51536 ifbu(256+254)<>234thengoto51540 :rem nop
51537 ifbu(256+255)<>96 thengoto51540 :rem rts

; Found CMD-HD system area.
51539 es=0

; All done
51540 return
