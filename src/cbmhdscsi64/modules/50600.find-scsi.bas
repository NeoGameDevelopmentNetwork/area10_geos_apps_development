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
; 50600.find-scsi.bas - scan scsi bus for devices
;
; parameter: dv    = cmd-hd device address
; return   : si(x) = device type
;            sm(x) = removable media
;            sv$(x)= scsi vendor identification
;            sp$(x)= scsi product identification
;            sr$(x)= scsi revision level
; temporary: id,sx
;

; Scan SCSI bus
50600 printleft$(po$,6)
50610 print"  scanning for scsi devices...     ";

; Backup current sd device
50620 sx=sd

; Narrow-SCSI/SCSI-1 supports id=0-6 only
50630 forid=0to6
50631     print"{left}{left}{left}{left}";right$("   "+str$(int(id*100/6)),3);"%";
50632     si(id)=-1:sm(id)=0:sv$(id)="":sp$(id)="":sr$(id)=""

; SCSI TEST UNIT READY
50633     sd=id:gosub59100
50634     ifes>127thengoto50640

; SCSI INQUIRY data
50635     gosub59200

50640 next

; Reset current SCSI device
50680 sd=sx
50690 return
