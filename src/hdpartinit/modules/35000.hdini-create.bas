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
; 35000.hdini-create.bas - create new partition
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sb    = cmd-hd scsi data-out buffer
;            so    = system area offset
;            hm    = max. possible partitions
;            pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
;            pf    = first free partition
; return   : es    = error status
;            e$    = error message
;            tr    = error track
;            se    = error sector
; temporary: pc,pb,ii,ba,rh,rm,rl,ad,hi,lo,a$,bh,bm,bl,ip
;

; Find last created partition and first free partition
35000 printtt$:print"  init partition table:{down}"

; Print device info
35010 dv=dd:gosub13900


; Clear partition table
35020 print"  this will clear the current partition"
35021 print"  table on the selected scsi device.{down}"
35022 print"  warning: continuing will cause any"
35023 print"  data and partitions to be lost!{down}"

; Print options
35030 print"  press <s> to select new scsi device."
35031 print"  continue (y/n/s)?"

; Delete partition?
35040 getkb$:ifkb$=""thengoto35040
35041 if(kb$="y")or(kb$="Y")thengoto35100
35042 if(kb$="n")or(kb$="N")thengoto35490
35043 if(kb$="s")or(kb$="S")thengosub11000:goto35000
35050 goto35040




; Find system area
35100 printtt$
35110 es=0:ifso<0thengosub51400:ifes>0thengoto35490




; Print status message
35200 print"  writing partition table and"
35201 print"  formatting partitions.{down}"
35202 print"  please be patient, this may take"
35203 print"  some time...{down}{down}"

; Define start address first partition
35210 pn=0:gosub49200:ifes>0thengoto35475
35211 bh=bu(ip+29):bm=bu(ip+30):bl=bu(ip+31)
35212 gosub58950:pa=so+ba

; Open command channel
35220 open15,dv,15

; SCSI READ CAPACITY
35221 gosub59400

; Close command channel
35222 close15




; Create partitions and delete partitions not in use
35300 forpn=1tohm

; Update progress bar
35310     print"{up}  creating partitions";int(pn*100/hm);"{left}% "

; Create/clear partition entry
35320     pa(pn)=pa:gosub35500:pa=pa+ps(pn)

; Write partition entry to disk
35325     gosub49400

; Do not format FOREIGN/printbuf/1581cpm mode partitions
35330     ifpt(pn)<1orpt(pn)>4thengoto35370

; Reload partition table by activating SCSI device
; This step is neccessary or some partitions will not be
; shown in the partition directory from BASIC when using
; @$=P. After about 78 partitions you will get an error:
; "79, drive not ready, 01, 31"
35332     gosub52000:ifes>0thengoto35345

; Reset device address
35333     gosub50570

; Open command channel
35340     es=0:open15,dv,15

; Change partition
35341     print#15,"cp"+mid$(str$(pn),2)
35342     input#15,es,e$,tr,se:ifes>2thentr=pn:se=0:goto35345

; Format partition
35343     print#15,"n:"+pn$(pn)+",hd"
35344     input#15,es,e$,tr,se:ifes>0thentr=pn:se=0:goto35345

; Close command channel
35345     close15
35346     ifes>0thenpn=hm

; Next partition
35370 next
35371 ifes>0thengoto35475

; Done
35380 print"{up}";sp$;sp$

; Reload partition directory from disk
35390 pl=-1



; Reload partition table by activating SCSI device
35400 print"{up}  updating partition table"
35401 gosub52000:ifes>0thengoto35475

; Reset device address
35410 gosub50500

; Done
35420 gosub9000
35430 goto35480

; Error
35475 gosub9200
35476 print"    ->";es;e$;tr;se;"{down}"

; "Press <return> to continue."
35480 gosub60400

; All done
35490 return
