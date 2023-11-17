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
; 30200.hdini-load.bas - load configuration file
;
; parameter: ga    = system device
;            cf$   = configuration file
;            hm    = max. possible partitions
;            so    = system area offset
;            tb    = total blocks on device
; return   : es    = error status
;            e$    = error message
;            tr    = error track
;            se    = error sector
;            pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
;            pf    = first free partition
;            br    = blocks remaining
; temporary: br,pc,pn,pn$,pt,ps,st
;

; Read hd configuration file from disk
30200 printtt$:print"  loading config '";cf$;"'...{down}"
30201 open1,ga,15:close1
30202 ifst<>0thenes=st:e$="device error":tr=-2:se=-1:goto30285

; Clear partition data
30210 gosub38800

; Reset system values
30220 es=0:br=-1:pc=0
30221 ifso>0theniftb>0thenbr=tb

; Check for empty file
30230 open15,ga,15
30231 open2,ga,2,cf$+",s,r"
30232   input#15,es,e$,tr,se
30233   if(es<>0)thengoto30276
30235   get#2,a$
30236   if(st>0)thengoto30276
30237 close2

; Read data from configuration file
30240 open2,ga,2,cf$+",s,r"

; Read partition entry
30250   input#2,pn,pn$,pt,ps

; Validate partition data
30260   ifpt<1orpt>7thenes=127:e$="bad partition":tr=pt:se=pn:goto30276

; 1541/1571/1581/1581CPM
30261   ifpt=2thenps=684/2:goto30270
30262   ifpt=3thenps=1366/2:goto30270
30263   ifpt=4orpt=5thenps=3200/2:goto30270

; Native/Foreign/PrintBuf
30264   ifps<128thenps=128:goto30268

; Foreign/PrintBuf max 16Mb
30265   ifps>32768thenps=32768

; Native max 255 tracks
30266   if(pt=1)and(ps>32640)thenps=32640
30268   ps=int(ps/128)*128

; Copy partition data to internal table
30270   ifso>0theniftb>0thenif(br-ps)<0thengoto30275
30271   pc=pc+1:pn$(pn)=pn$:pt(pn)=pt:ps(pn)=ps

; Calculate remaining blocks (if available)
30272   iftb>0thenbr=br-ps

; Continue with next line
30275   if(pc<hm)thenif(st=0)then30250

; Close configuration file
30276 close2:close15




; Check for errors
30280 ifes>0thengoto30285

; Done
30281 print"  imported partitions:";pc;"{up}"
30282 gosub9000

; Check partition data
30283 gosub30300
30284 goto30288

; Display error message
30285 print"{down}  unable to read partitions from file!"
30286 print"    ->";abs(es);e$;abs(tr);abs(se);"{down}"

; "Press <return> to continue."
30288 gosub60400

; All done
30290 return
