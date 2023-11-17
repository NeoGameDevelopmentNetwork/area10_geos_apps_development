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
; 03200.select-part.bas - select source/target partition
;
; parameter: dv    = current cmd-hd device address
;            so    = system area offset
;                    -1 = system area not tested
;            pn    = current partition (to be changed)
;                    -1 = partition not selected
;            fm    = partition format mode (to be changed)
;                    -1 = select source partition
;                    >0 = source partition format
;            fs    = source partition format mode
;            s1    = source partition start address
;            sk    = skip factor (+1 or +10)
; return   : es    = error status
;            pn    = partition number
;            fm    = partition format mode
;            ax    = partition start address
;            bx    = partition size in 512-byte blocks
; temporary: px,pb,pf,ba,ip,p,ad,hi,lo,bh,bm,bl
;

; select next partition
3200 ifso<0thengosub51400:ifes>0thengoto3290
3201 px=pn:ifpx<0thenpx=0

; Wait for media
3202 gosub50700:ifes>2thengoto3290

; Print status message
3203 printleft$(po$,14):print"{right}";sl$
3204 print"{up}{right}{right}searching for partition..."

; Define partition default values
; pb = last partition directory block
; pf = 1 / restarted search after end of partition list
3205 pb=-1:pf=0

; Open command channel
3210 open15,dv,15

; Select next partition
3220 if(px<254)thenif((px+sk)>(254+sk-1))thenpx=254:goto3222
; Set next partition / restart search at first partition
3221 px=px+sk:ifpx>254thenpx=1:pf=1
; All partitions tested?
; pn > 0
3222 if(px=pn)thengoto3285
; pn = -1 / no partition found, exit
3223 if((pf=1)and(px>pn))thengoto3285

; Pront current partition
3224 printleft$(po$,15);left$(ta$,34);right$("   "+str$(px),3)

; Set partition block address
3225 ba=so+128+int(px/16)

; Read partition block into CMD-HD ram
3226 ifpb=bathengoto3230
3227 gosub58900:rh=bh:rm=bm:rl=bl
3228 pb=ba:gosub58200

; Set position to partition entry
3230 ip=(px and 15)*32

; Get partition format byte
3231 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
3232 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
3233 get#15,a$:p=asc(a$+nu$)
; Skip empty or system partition
3234 if(p=0)or(p=255)thengoto3220
; Skip if incorrect partition type
3235 iffm>0thenifp<>fmthengoto3220

; Get partition name
3240 ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
3241 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
3242 fp$="":fori=1to16:get#15,a$:fp$=fp$+a$:next

; Get start address of current partition
3250 ad=sb+ip+21:hi=int(ad/256):lo=ad-hi*256
3251 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
3252 get#15,a$:bh=asc(a$+nu$)
3253 get#15,a$:bm=asc(a$+nu$)
3254 get#15,a$:bl=asc(a$+nu$)

; Convert h/m/l to lba
3255 gosub58950:ax=ba

; Get size of current partition
3260 ad=sb+ip+29:hi=int(ad/256):lo=ad-hi*256
3261 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
3262 get#15,a$:bh=asc(a$+nu$)
3263 get#15,a$:bm=asc(a$+nu$)
3264 get#15,a$:bl=asc(a$+nu$)

; Convert h/m/l to lba
3265 gosub58950:bx=ba

; Test for a valid partition
; fm = -1 / find new source partition
; fm =  x / format mode source partition
3280 iffm<0thengoto3284
; Native: Do not allow copying larger partitions to target
3281 if((fs=1)and(s1>bx))thengoto3220

; Set new format mode / partition number / name
3284 fm=p:pn=px:pn$=fp$

; Close command channel
3285 close15

; All done
3290 return
