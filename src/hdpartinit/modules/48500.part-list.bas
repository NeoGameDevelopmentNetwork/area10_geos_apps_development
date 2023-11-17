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
; 48500.part-list.bas - print partition list
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
; return   : -
; temporary: pc,px,pn,bh,bm,bl,ba,pt,ip,px,pc
;

; Print partition list
48500 if(so>=0)thenifpl>0thengoto48510

; Get disk info
48501 printtt$:print"  partition menu:{down}"
48502 dv=dd:gosub13900

; Find system area
48503 es=0:ifso<0thengosub51400:ifes>0thengoto48590

; Analyze partition table
48504 gosub40900:ifes>0thengoto48590

; Print partition list
48510 gosub48600

; Initialize counter for page/partitions
48515 pc=0:px=0:pb=-1:k$=""

; Open command channel
48516 open15,dv,15

; List all partitions
48520 forpn=1tohm

; Does partition exist?
48530     ifpp(pn)=0thengoto48560

; Print partition number
48531     printright$(sp$+str$(pn),4);" ";

; Read partition block into CMD-HD ram
48532     ba=so+128+int(pn/16)
48533     ifpb=bathengoto48540
48534     gosub58900:rh=bh:rm=bm:rl=bl
48535     pb=ba:gosub58200

; Set position to partition entry
48540     ip=(pn and 15)*32

; Set pointer to partition name in partition block
48541     ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
; Read partition name from CMD-HD
48542     print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
48543     print"'";:fori=1to16:get#15,a$:printa$;:next:print"'";

; Set pointer to partition size in partition block
; We need only two bytes -> 16Mb max = 32768 512-byte blocks.
48544     ad=sb+ip+30:hi=int(ad/256):lo=ad-hi*256
48545     print#15,"m-r"chr$(lo)chr$(hi)chr$(2)
48546     get#15,a$,b$:ba=asc(a$+nu$)*256+asc(b$+nu$)
48547     printright$(sp$+str$(ba*2),6);" ";

; Print partition type
48548     pt=pp(pn):gosub48900:printpt$

; Test for "Page full"
48550     px=px+1:pc=pc+1:ifpc<mpthengoto48560
48551     printleft$(po$,25);
48552     print"  <return> next page    <";chr$(95);"> main menu";

; Wait for a key
48553     getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto48553
48554     ifk$=chr$(13)thengoto48559
48555     ifk$=chr$(95)thenpn=254:goto48560
48556     goto48553

; New page.
48559     pc=0:gosub48600

; Next partition
48560 next

; Close command channel
48561 close15

; All done!
48564 ifk$=chr$(95)thengoto48590
48565 if(px=0)thengoto48575
48566 if(pc>0)thengoto48580

; "No more partitions"
48570 print"{down}{down}";:gosub9510
48571 goto48580

; "No partitions on disk"
48575 print"{down}{down}      no partitions found!"

; Wait for return
48580 printleft$(po$,25);"  press <return> to continue.";
48581 getk$:ifk$<>chr$(13)thengoto48581

; All done
48590 return




; Print partition list header
48600 printtt$
48610 print"  partition list: cmd-hd";str$(dd);":";chr$(48+sd);"{down}"
48620 print"  nr  partition          size type"
48630 printli$
48640 fori=0to15:printsl$:next
48650 printli$
48660 printsl$;left$(po$,7)
48690 return
