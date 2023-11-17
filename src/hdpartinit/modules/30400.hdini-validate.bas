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
; 30400.hdini-validate.bas - make sure that partition data is valid
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sb    = cmd-hd scsi data-out buffer
;            so    = system area offset
;            hm    = max. possible partitions
;            tb    = total blocks on device
; return   : es    = error status
;            pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
;            pf    = first free partition
;            br    = blocks remaining
; temporary: ii
;

; Validate partition data
30400 printtt$:print"  validating partition data:{down}"

; Find system area
30401 es=0:ifso<0thengosub51400:ifes>0thenso=-1:tb=-1:goto30410

; Open command channel
30405 open15,dv,15

; SCSI READ CAPACITY
30406 gosub59450

; Wait a second...
30407 gosub51800

; Close command channel
30408 close15

; Print status message
30410 print"{down}  validate in progress...{down}"

; initialize system values
30411 es=0:pf=-1
30412 ifso>0theniftb>0thenbr=tb

; Validate partition data
30420 forii=0tohm

30421   print"{up}  partition:";ii;"{left} "
30422   if(pt(ii)=0)and(pf=<0)thenpf=ii
30423   if(pt(ii)=0)thengoto30470
30424   if(pt(ii)=255)thengoto30442

; Validate partition data
30430   ifpt(ii)<1orpt(ii)>7thengoto30450

; 1541/1571/1581/1581CPM
30431   ifpt(ii)=2thenps(ii)=684/2:goto30440
30432   ifpt(ii)=3thenps(ii)=1366/2:goto30440
30433   ifpt(ii)=4orpt(ii)=5thenps(ii)=3200/2:goto30440

; Native/Foreign/PrintBuf
30434   ifps(ii)<128thenps(ii)=128:goto30438

; Foreign/PrintBuf max 16Mb
30435   ifps(ii)>32768thenps(ii)=32768

; Native max 255 tracks
30436   if(pt(ii)=1)and(ps(ii)>32640)thenps(ii)=32640
30438   ps(ii)=int(ps(ii)/128)*128

; Partition name
30440   iflen(pn$(ii))>16thenpn$(ii)=left$(pn$(ii),16)

; Check remaining disk space
30441   iftb>0thenif(br-ps)<0thengoto30450

; Calculate remaining blocks (if available)
30442   iftb>0thenbr=br-ps(ii)
30443   goto30470

; Partition vot valid
30450   es=es+1:pn$(ii)="":pt(ii)=0:ps(ii)=0:pa(ii)=0

; Continue validate
30470 next

; Done
30471 gosub9000

; Check for errors
30472 ifes=0thengoto30480
30473 print"{down} ";es;"partitions bad/removed!{down}"

; "Press <return> to continue."
30480 gosub60400

; All done
30490 return
