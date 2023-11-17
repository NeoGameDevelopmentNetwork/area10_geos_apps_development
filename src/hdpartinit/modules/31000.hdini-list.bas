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
; 31000.hdini-list.bas - print partition list
;
; parameter: hm    = max. possible partitions
; return   : -
; temporary: pc,px,pb,pn,k$
;

; Print partition list
31000 gosub31200

; Initialize counter for page/partitions
31015 pc=0:px=0:pb=-1:k$=""

; List all partitions
31020 forpn=1tohm

; Does partition exist?
31030     ifpt(pn)=0thengoto31060

; Print partition number
31031     printright$(sp$+str$(pn),4);" ";

; Print partition name
31043     printleft$("'"+pn$(pn)+"'"+sp$+sp$,18);

; Print partition size
31047     printright$(sp$+str$(ps(pn)*2),6);" ";

; Print partition type
31048     pt=pt(pn):gosub48900:printpt$

; Test for "Page full"
31050     px=px+1:pc=pc+1:ifpc<mpthengoto31060
31051     printleft$(po$,25);
31052     print"  <return> next page    <";chr$(95);"> main menu";

; Wait for a key
31053     getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto31053
31054     ifk$=chr$(13)thengoto31059
31055     ifk$=chr$(95)thenpn=254:goto31060
31056     goto31053

; New page.
31059     pc=0:gosub31200

; Next partition
31060 next

; Close command channel
31061 close15

; All done!
31064 ifk$=chr$(95)thengoto31090
31065 if(px=0)thengoto31075
31066 if(pc>0)thengoto31080

; "No more partitions"
31070 print"{down}{down}";:gosub9510
31071 goto31080

; "No partitions on disk"
31075 print"{down}{down}      no partitions found!"

; Wait for return
31080 printleft$(po$,25);"  press <return> to continue.";
31081 getk$:ifk$<>chr$(13)thengoto31081

; All done
31090 return




; Print partition list header
31200 printtt$
31210 print"  partition configuration{down}"
31220 print"  nr  partition          size type"
31230 printli$
31240 fori=0to15:printsl$:next
31250 printli$
31260 printsl$;left$(po$,7)
31290 return
