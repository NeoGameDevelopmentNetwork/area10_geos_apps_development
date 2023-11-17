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
; 48500.part-list.bas - print partition list
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
; return   : -
; temporary: pc,px,pn,bh,bm,bl,ba,pt,ip,px,pc
;

; Check for system-area
48500 ifso<0thengosub51400:ifes>0thengoto48590

; Wait for media
48501 gosub50700:ifes>2thengoto48590

; Print title
48510 printtt$

; Print disk name, device, scsi-id, partition
48511 printleft$(po$,3);
48512 printc0$;li$;c1$
48513 printvi$;sl$;vi$
48514 printc2$;li$;c3$
48515 printleft$(po$,4);left$(ta$,2);
48516 print"  partition list: cmd-hd";str$(dv);":";chr$(48+sd)

; Clear directory page
48517 gosub39600:printleft$(po$,5)

; Initialize counter for page/partitions
48518 pc=0:px=0:pb=-1:mp=16

; Open command channel
48519 open15,dv,15

; List all partitions
48520 forpn=1to254

; Read partition block into CMD-HD ram
48521     ba=so+128+int(pn/16)
48522     ifpb=bathengoto48525
48523     gosub58900:rh=bh:rm=bm:rl=bl
48524     pb=ba:gosub58200

; Print progess bar
48525     printleft$(po$,24);left$(ta$,11);
48526     printint(100*pn/254);"{left}%";

; Set position to partition entry
48528     ip=(pn and 15)*32

; Does partition exist?
48530     ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
48531     print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
48532     get#15,a$:pt=asc(a$+nu$)
48533     if(pt=0)or(pt=255)thengoto48560

; Print partition number
48535     printleft$(po$,7+pc);
48540     print"{right}{right}";right$(sp$+str$(pn),4);" ";

; Set pointer to partition name in partition block
48541     ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
; Read partition name from CMD-HD
48542     print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
48543     printgf$;:fori=1to16:get#15,a$:printa$;:next:printgf$;

; Set pointer to partition size in partition block
; We need only two bytes -> 16Mb max = 32768 512-byte blocks.
48544     ad=sb+ip+30:hi=int(ad/256):lo=ad-hi*256
48545     print#15,"m-r"chr$(lo)chr$(hi)chr$(2)
48546     get#15,a$,b$:ba=asc(a$+nu$)*256+asc(b$+nu$)
48547     printright$(sp$+str$(ba*2),6);" ";

; Print partition type
48548     gosub48900:printpt$

; Test for "Page full"
48550     px=px+1:pc=pc+1:ifpc<mpthengoto48560
48551     printleft$(po$,24);
48552     print"  <return> next page    <";chr$(95);"> main menu";

; Wait for a key
48553     getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto48553
48554     ifk$=chr$(13)thengoto48559
48555     ifk$=chr$(95)thenpn=254:goto48561
48556     goto48553

; New page.
48559     pc=0:gosub39600

; Abort directory listing?
48560     getk$:ifk$=chr$(95)thenk$="":pn=254

; Next partition
48561 next

; Close command channel
48563 close15

; All done!
48564 ifk$=chr$(95)thengoto48590
48565 if(pc>0)thengoto48580
48566 if(px=0)thengoto48575

; "No more partitions"
48570 print"{down}{down}      no more partitions found!"
48571 goto48580

; "No partitions on disk"
48575 print"{down}{down}      no partitions found!"

; Wait for return
48580 printleft$(po$,24);"  press <return> to continue.        ";
48581 getk$:ifk$<>chr$(13)thengoto48581

; All done
48590 return
