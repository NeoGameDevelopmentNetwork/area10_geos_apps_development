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
; 59400.scsi-capacity.bas - READ CAPACITY
;
; parameter: sl/sh = cmd-hd scsi data-out buffer
; return   : ed    = status byte
;            tb    = block count
; temporary: ec,a$,he$,sc$,by$,by,bh,bm,bl
;

;--- 10 Bytes
;SCSI-Befehl: READ CAPACITY
; -Operation Code $25
; -Reserved/Obsolete
; -Logical Block Address 4 Bytes (Obsolete)
; -Reserved
; -Reserved
; -Reserved/PMI(Obsolete)
; -Control

; SCSI READ CAPACITY
59400 he$="25000000000000000000":gosub60100:sc$=by$

; Send SCSI command
59410 gosub59800:ifes>0thengoto59440

; READ CAPACITY data
; Byte #0-3 include LBA in MSB...LSB format.
; Only byte #1 to #3 are used here.
59420 print#15,"m-r"chr$(sl)chr$(sh)chr$(4)
59421 get#15,a$,bh$,bm$,bl$

; Calculate block count:
; bc: Number of blocks on the medium.
59430 bh=asc(bh$+nu$)
59431 bm=asc(bm$+nu$)
59432 bl=asc(bl$+nu$)

; bh/bm/bl defines the last available logical block.
; Address from 0 to x. Total block count = last LB +1
59433 bl=bl+1:ifbl>255thenbl=0:bm=bm+1
59434 ifbm>255thenbm=0:bh=bh+1
59435 tb=bh*65536+bm*256+bl

59440 return
