﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 59600.scsi-eject.bas - STOP UNIT/EJECT
;
; parameter: sl/sh = cmd-hd scsi data-out buffer
; return   : ed    = status byte / $02 = no disk
; temporary: ec,a$,he$,sc$,by$,by,bh,bm,bl
;

;---  6 Bytes.
;SCSI-Befehl: STOP UNIT
; -Operation Code $1b
; -Immediate Bit%0=1
;  The device server shall return status as
;  soon as the CDB has been validated.
; -Reserved
; -Power condition modifier
;  $00 = Process LOEJ and START bits.
; -LOEJ/START
;  Bit%0=0 STOP
;  Bit%0=1 START
;  Bit%1=0 No action regarding loading/ejecting medium.
;  Bit%1=1 and Bit%0=0 Eject medium.
;  Bit%1=1 and Bit%0=1 Load medium.
; -Control

; Removable media?
59600 es=0:ifsm(sd)=0thengoto59690

; SCSI STOP UNIT + EJECT
59610 he$="1b0100000200":gosub60100:sc$=by$
; 59611 goto59670
; 
; ; Disk drive?
; 59650 es=0:ifsm(sd)>0thengoto59690
; 
; ; SCSI STOP UNIT
; 59660 he$="1b0100000000":gosub60100:sc$=by$

; Open command channel
59670 open15,dv,15

; Send SCSI command
59671 gosub59800

; Close command channel
59674 close15

; All done
59690 return
