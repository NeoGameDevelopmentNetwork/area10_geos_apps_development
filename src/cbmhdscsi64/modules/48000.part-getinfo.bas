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
; 48000.part-getinfo.bas - find last created partition
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sb    = cmd-hd scsi data-out buffer
;            so    = system area offset
; return   : es    = error status
;            pt(x) = table with partition types
;            pl    = last created partition
;            pa    = start address of last created partition
;            ps    = size of last created partition
;            pf    = first free partition
; temporary: pc,pb,ii,ba,rh,rm,rl,ad,hi,lo,a$,bh,bm,bl,ip
;

; Find last created partition and first free partition
; Find system area
48000 es=0:ifso<0thengosub51400:ifes>0thengoto48190

; Print status message
48010 print"  analyzing partition table"
48011 print"  ";

; Open command channel
48020 open15,dv,15

; Define partition default values
48030 pc=0:pa=0:ps=0:pb=-1:pf=-1:pl=-1

; Start at partition #0 to find offset for first partition
; Don't test partition #255 = current partition
48040 forii=0to254

; Clear partition status
48050     pt(ii)=0

; Set partition block address
48060     ba=so+128+int(ii/16)

; Read partition block into CMD-HD ram
48100     ifpb=bathengoto48110
48101     print".";
48102     gosub58900:rh=bh:rm=bm:rl=bl
48103     pb=ba:gosub58200

; Set position to partition entry
48110     ip=(ii and 15)*32

; Check for free partition entry
48120     ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
48122     print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
48123     get#15,a$:pt(ii)=asc(a$+nu$)
48124     ifpf<0thenifpt(ii)=0thenpf=ii
48125     ifpt(ii)=0thengoto48180

; Get start address of current partition
48130     ad=sb+ip+21:hi=int(ad/256):lo=ad-hi*256
48131     print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
48132     get#15,a$:bh=asc(a$+nu$)
48133     get#15,a$:bm=asc(a$+nu$)
48134     get#15,a$:bl=asc(a$+nu$)

; Convert h/m/l to lba
48140     gosub58950

; Check for new start address
48150     ifba<pathengoto48180

; Remember last created partition
48151     pl=ii

; Start address of last partition
48152     pa=ba

; Get size of current partition
48160     ad=sb+ip+29:hi=int(ad/256):lo=ad-hi*256
48161     print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
48162     get#15,a$:bh=asc(a$+nu$)
48163     get#15,a$:bm=asc(a$+nu$)
48164     get#15,a$:bl=asc(a$+nu$)

; Convert h/m/l to lba
48170     gosub58950

; Remember size of last created partition
48171     ps=ba

; Next partition
48180 next

; Done
48181 print
48182 print"{up}";sp$;sp$;"{up}"

; Close command channel
48183 close15

; All done
48190 return
