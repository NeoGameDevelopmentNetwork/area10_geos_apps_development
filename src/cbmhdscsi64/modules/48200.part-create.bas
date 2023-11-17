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
; 48200.part-create.bas - create new partition entry
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sb    = cmd-hd scsi data-out buffer
;            so    = system area offset
;            pn    = partition number
;            pt    = cmd partition type
;            pn$   = partition name
;            pa    = partition start address
;            ps    = partition size of last created partition
;            pr    = required blocks for partition
;            ap$   = Auto-create text
; return   : es    = error status
;            pt(x) = table with partition types
;            pa    = start address of last created partition
;            ps    = size of last created partition
;            pf    = first free partition
; temporary: ip,i,nm$,ba,bh,bm,bl,a$
;

; Create new partition entry
48200 printtt$
; "Create new partition:"
48201 gosub9560
48202 print"    partition :";pn
48203 print"    name      : ";pn$
48204 print"    type      : ";pt$
48205 print"    size      :";pr*2;"blocks{down}"

; Create partition entry
48210 print"  creating partition"
48211 gosub48400

; Write partition entry
48220 gosub49400:ifes>0thengoto48390

; Reload partition table by activating SCSI device
48230 gosub52000:ifes>0thengoto48390

; Reset device address
48231 gosub50500

; Do not format FOREIGN mode partitions
48240 ifpt<1orpt>4thengoto48340

; Switch partition and format new partition
48300 print"  formatting partition"

; Open command channel
48310 open15,dv,15

; Change partition
48320 print#15,"cp"+mid$(str$(pn),2)
48321 input#15,a$:es=val(a$):ifes>2thengoto48330

; Format partition
48323 print#15,"n:"+pn$+",hd"
48324 input#15,a$:es=val(a$)

; Close command channel
48330 close15




; Done
48340 print"{down}"

; Partition format ok?
48341 ifes>0thengoto48380

; Yes, set default values for next new partition
48350 pt(pn)=pt:pa=pa+ps:ps=pr:pl=pn

; Get next free partition
48351 gosub48700

; Partition created
48360 print"  partition created!{down}"

; Wait for return
48370 ifap=0thengoto48385
48371 ifap<>0thengosub51800
48372 goto48390




; "Disk error"
48380 gosub9200

; Wait for return
48385 gosub60400

; All done!
48390 return
