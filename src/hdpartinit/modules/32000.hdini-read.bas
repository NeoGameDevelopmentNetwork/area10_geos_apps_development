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
; 32000.hdini-read.bas - read partition data from scsi device
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sb    = cmd-hd scsi data-out buffer
;            so    = system area offset
;            hm    = max. possible partitions
; return   : es    = error status
;            pt()  = table with partition types
;            pa    = start address of last created partition
;            ps    = size of last created partition
;            pf    = first free partition
;            br    = blocks remaining
; temporary: pc,pb,ii,ba,rh,rm,rl,ad,hi,lo,a$,bh,bm,bl,ip
;

; Find last created partition and first free partition
32000 printtt$:print"  import partitions:{down}"

; Find system area
32005 es=0:ifso<0thengosub51400:ifes>0thengoto32190

; Print status message
32010 print"  reading partition table"
32011 print"  ";

; Clear partition data
32015 gosub38800

; Open command channel
32020 open15,dv,15

; Define partition default values
32030 pc=0:pb=-1:pf=-1

; Start at partition #0 to find offset for first partition
; Don't test partition #255 = current partition
32040 forii=0tohm

; Clear partition status
32050     pt(ii)=0:pn$(ii)="":ps(ii)=0:pa(ii)=0

; Set partition block address
32060     ba=so+128+int(ii/16)

; Read partition block into CMD-HD ram
32100     ifpb=bathengoto32110
32101     print".";
32102     gosub58900:rh=bh:rm=bm:rl=bl
32103     pb=ba:gosub58200

; Set position to partition entry
32110     ip=(ii and 15)*32

; Get type of current partition
32120     ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
32122     print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
32123     get#15,a$:pt(ii)=asc(a$+nu$)

; Check for free partition entry
32124     ifpf<0thenifpt(ii)=0thenpf=ii
32125     ifpt(ii)=0thengoto32180

; Get name of current partition
32130     ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
32131     print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
32132     b$="":forj=0to15
32133         get#15,a$:a=asc(a$+chr$(0))
32134         ifa>0anda<>160thenb$=b$+a$
32135     next
32136     pn$(ii)=b$

; Get size of current partition
32160     ad=sb+ip+29:hi=int(ad/256):lo=ad-hi*256
32161     print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
32162     get#15,a$:bh=asc(a$+nu$)
32163     get#15,a$:bm=asc(a$+nu$)
32164     get#15,a$:bl=asc(a$+nu$)

; Convert h/m/l to lba
32165     gosub58950

; Remember size of current partition
32166     ps(ii)=ba

; Partition imported
32170     if(pt(ii)<>255)and(pt(ii)>0)thenpc=pc+1

; Next partition
32180 next

; Done
32181 print
32182 print"{up}";sp$;sp$;"{up}"

; Close command channel
32183 close15

; Done
32184 print"{down}  imported partitions:";pc;"{up}"
32185 gosub9000

; Get next free partition
32186 pn=1:gosub39000

; Check partition data
32187 gosub30300

; "Press <return> to continue."
32188 gosub60400

; All done
32190 return
