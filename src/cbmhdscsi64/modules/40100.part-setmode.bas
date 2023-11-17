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
; 40100.part-setmode.bas - set format mode data
;
; parameter: ap    = auto-create partition mode
;            pf    = next free partition
;            br    = blocks remaining
; return   : pt    = cmd partition type
;            pt$   = cmd partition type text
;            pn$   = new partition name
;                    return to menu if empty
;            pr    = required 512-byte blocks for partition
;

; Create 1541 partition
40100 pt=2:pr=684/2:goto40150

; Create 1571 partition
40110 pt=3:pr=1366/2:goto40150

; Create 1581 partition
40120 pt=4:pr=3200/2:goto40150

; Create native partition
; In Auto-create mode a 16mb(255 tracks) partition will be created
40130 pt=1:pr=(255*256)/2:goto40150

; Foreign mode partition
40140 pt=7:pr=(256*256)/2




; Create partition
40150 printtt$
; "create new partition:"
40151 gosub9560
40152 dv=dd:gosub13900

; Free partition available?
40155 ifpf<1thenes=1:goto40190

; Set partition number
40160 pn=pf

; Set partition type text for auto-create
40165 gosub48900

; Set native-mode partiton size
40170 ifpt<>1andpt<>7thengoto40180
40171 ifap=0thengosub41200
; Check remaining free blocks for native-mode
40172 ifpr>brthenpr=br
; We need at least 256 blocks = 64kb
; 256 cbm-blocks are 128 512-byte blocks
40173 ifpr=0thengoto40195
40174 ifpr<(256/2)thenpr=(256/2)
40175 ifpt=1andpr>((255*256)/2)thenpr=((255*256)/2)
40176 ifpt=7andpr>((256*256)/2)thenpr=((256*256)/2)

; Check remaining free blocks for 1541/71/81
40180 ifpr>brthengoto40195

; Set partition name
40181 gosub41000:ifpn$=""thengoto40199

; Create partition
40182 gosub48200

; Analyze partition table
; (Calculate remaining free blocks only)
40183 gosub40900

; All done
40184 return




; No more free partition!
40190 printtt$:print"{down}  no more free partition!"
40191 goto40198

; No more free partition!
40195 printtt$:print"{down}  not enough free blocks!"

; Wait for return
40198 gosub60400
; All done
40199 return
