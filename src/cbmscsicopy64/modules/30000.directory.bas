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
; 30000.directory.bas - list directory
;
; List source directory:
; parameter: dv    = cmd-hd device address
;            hs    = current source scsi device
;            os    = system area offset
;                    -1 = system area not tested
;            cs    = copy source partition
;            fs    = source partition format mode
;            s0    = source partition start address
;
; List target directory:
; parameter: dv    = cmd-hd device address
;            ht    = current target scsi device
;            ot    = system area offset
;                    -1 = system area not tested
;            ct    = copy target partition
;            ft    = target partition format mode
;            t0    = target partition start address
;
; return   : -
; temporary: sd,so,sb,pn,fm,b0,em$,dn$,ad,hi,lo,i,a$,a,c0,c1
;            bh,bm,bl,rh,rm,rl,ba,d0,d1,tr,se,ii,ip,ty,ff$,k$
;

; List directory - Source SCSI device
30000 sd=hs:so=os:pn=cs:fm=fs:b0=s0:goto31000
; List directory - Target SCSI device
30100 sd=ht:so=ot:pn=ct:fm=ft:b0=t0:rem goto31000

; List directory - Source/Target SCSI device
; Test for a valid partition mode.
31000 iffm>=1andfm=<4thengoto31010

; Error: Not supported
31001 em$="not supported!"
31002 printleft$(po$,14):print"{right}";sl$
31003 print"{up}{right}{right}";left$(em$+sp$+sp$,21);"press <return>"
31004 goto32990




; Define BAM sector / LBA-offset
; d0 = LBA offset for BAM block
31010 onfmgosub39820,39800,39800,39810

; Test CMD-HD device
31020 open15,dv,15:close15:ifst<>0thenes=st:goto32990

; Open command channel
31030 open15,dv,15

; Convert source LBA to h/m/l
31100 ba=b0+d0:gosub58900:rh=bh:rm=bm:rl=bl

; Read first BAM-Block from disk
31110 gosub58200

; Clear disk name
31120 dn$=""

; Read 16 data bytes into buffer.
31130 ad=sb+d1+d2:hi=int(ad/256):lo=ad-hi*256
31131 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
31132 fori=0to15
31133     get#15,a$:a=asc(a$+nu$)
31134     if(a<32)or((a>=128)and(a<160))thena=32
31135     if(a>=97)and(a=<122)thena=a-32
31136     dn$=dn$+chr$(a)
31137 next

; Print title
31200 printtt$

; Print disk name, device, scsi-id, partition
31210 printleft$(po$,3);
31211 printc0$;li$;c1$
31212 printvi$;sl$;vi$
31213 printc2$;li$;c3$
31214 printleft$(po$,4);left$(ta$,2);"disk ";
31215 printright$("  "+str$(dv),2);":";mid$(str$(sd),2);
31216 print" ";chr$(34);dn$;chr$(34)
31217 printleft$(po$,4);left$(ta$,32);"p:";
31218 printright$("000"+mid$(str$(pn),2),3)

; Clear directory page
31220 gosub39600

; Reset page/file count
31230 c0=0:c1=0

; Define next directory sector
32000 ad=sb+d1:hi=int(ad/256):lo=ad-hi*256

; Read next block address
32010 print#15,"m-r"chr$(lo)chr$(hi)chr$(2)
32020 get#15,a$,b$:tr=asc(a$+nu$):se=asc(b$+nu$)

; End of directory?
32021 iftr=0thengoto32300

; Convert block to LBA-offset
32030 d0=0:onfmgosub39750,39700,39700,39730
32031 d1=(((d0/2)-int(d0/2))*2)*256

; Convert LBA to h/m/l
32040 ba=b0+int(d0/2):gosub58900:rh=bh:rm=bm:rl=bl

; Read next directory-block from disk
32050 gosub58200:ifes>0thengoto32300




; Read directory entires
32100 forii=0to255step32
32110     ip=d1+ii

; Define address for file type
32120     ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256

; Read file type
32130     print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
32131     get#15,a$:ty=asc(a$+nu$)

; Valid file type?
32140     ifty=0thengoto32190

; Define address for file name
32150     ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256

; Print file name
32151     print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
32152     ff$="":forj=0to15
32153         get#15,a$:a=asc(a$+nu$):ifa=160thenj=15:goto32156
32154         if(a<32)or((a>=128)and(a<160))thena=32
32155         if(a>=97)and(a=<122)thena=a-32
32156         ff$=ff$+chr$(a)
32157     next
32158     printleft$(po$,7+c0);left$(ta$,3);ff$

; Print file type
32160     ty=tyand15:ifty>6thenty=9
32161     printleft$(po$,7+c0);left$(ta$,33);ty$(ty)

; Check for "Page full"
32170     c1=c1+1:c0=c0+1:ifc0<16thengoto32180
32171     printleft$(po$,24);
32172     print"  <return> next page    <";chr$(95);"> main menu"
; Wait for a key
32173     getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto32173
; Clear directory page
32174     ifk$=chr$(13)thenc0=0:gosub39600
32175     ifk$=chr$(95)thenii=255:tr=0
32176     goto32190

; Abort directory listing?
32180     getk$:ifk$=chr$(95)thenk$="":ii=255:tr=0

; Continue with next file
32190 next

; Test for next directory block
32200 iftr>0thengoto32000




; Close command channel
32300 close15
; Check for disk error
32310 ifes>0thengoto32990

; Check for empty disk
32400 ifc1=0thenprintleft$(po$,8);left$(ta$,3);"empty disk"
32410 goto39982

; All done
32990 return
