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
; 38000.hdpart-setmode.bas - set format mode data
;
; parameter: ap    = auto-create partition mode
;            pf    = next free partition
;            tb    = total blocks on device
;            br    = blocks remaining
; return   : pn    = partition nr
;            pt    = cmd partition type
;            pt$   = cmd partition type text
;            pn$   = new partition name
;                    return to menu if empty
;            pr    = required 512-byte blocks for partition
; temporary: ip,i,pn$,nm$,ba,bh,bm,bl
;

; Create 1541 partition
38000 pt=2:pr=684/2:goto38050

; Create 1571 partition
38010 pt=3:pr=1366/2:goto38050

; Create 1581/1581CPM partition
38020 pt=4:pr=3200/2:goto38050
38025 pt=5:pr=3200/2:goto38050

; Create native partition
; In Auto-create mode a 16mb(255 tracks) partition will be created
38030 pt=1:pr=(255*256)/2:goto38050

; Foreign mode partition
38040 pt=7:pr=(256*256)/2:goto38050

; Print buffer partition
38045 pt=6:pr=(256*256)/2




; Create partition
38050 printtt$

; "create new partition:"
38051 gosub9560
38052 dv=dd:gosub13900

; Free partition available?
38055 ifpf<1thenes=1:goto38090

; Set partition number
38060 pn=pf

; Set partition type text for auto-create
38065 gosub48900

; Set native-mode partiton size
38070 ifpt<>1andpt<>6andpt<>7thengoto38080
38071 ifap=0thengosub38300
; Check remaining free blocks for native-mode
38072 if(tb>0)and(pr>br)thenpr=br
; We need at least 256 blocks = 64kb
; 256 cbm-blocks are 128 512-byte blocks
38073 ifpr=0thengoto38095
38074 ifpr<(256/2)thenpr=(256/2)
38075 ifpt=1andpr>((255*256)/2)thenpr=((255*256)/2)
38076 ifpt=6andpr>((256*256)/2)thenpr=((256*256)/2)
38077 ifpt=7andpr>((256*256)/2)thenpr=((256*256)/2)

; Check remaining free blocks for 1541/71/81
38080 if(tb>0)and(pr>br)thengoto38095

; Set partition name
38081 gosub38200:ifpn$=""thengoto38099

; Create partition
38082 gosub38400

; Analyze partition table
; (Calculate remaining free blocks only)
38083 if(tb>0)thenbr=br-pr

; All done
38084 return




; No more free partition!
38090 printtt$:print"{down}  no more free partition!"
38091 goto38098

; No more free partition!
38095 printtt$:print"{down}  not enough free blocks!"

; Wait for return
38098 gosub60400

; All done
38099 return
