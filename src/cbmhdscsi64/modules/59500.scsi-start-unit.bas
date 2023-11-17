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
; 59500.scsi-start-unit.bas - START UNIT
;
; parameter: sl/sh = cmd-hd scsi data-out buffer
; return   : ed    = status byte / $02 = no disk
;            tb    = block count
; temporary: ec,a$,he$,sc$,by$,by,bh,bm,bl
;

;--- 6 Bytes
;SCSI-Befehl: START UNIT
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

; SCSI START UNIT
59500 he$="1b0000000300":gosub60100:sc$=by$

; Open command channel
59510 open15,dv,15

; Send SCSI command
59520 gosub59800

; Close command channel
59530 close15

; All done
59590 return
