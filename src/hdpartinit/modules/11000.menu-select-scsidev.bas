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
; 11000.menu-select-scsidev.bas - menu: select new scsi device
;

; Select scsi device
; Note: Use device address 'dd' to set the current device 'dv'!
;       'dd' is always the last selected CMD-HD.
11000 printtt$

; Scan SCSI bus
11010 dv=dd:gosub50600

; Print list of known SCSI devices
11020 gosub11200
11030 print"  press 0-6 to select scsi device or"
; "Press <return> for main menu."
11040 gosub9520

; Wait for a key
11050 getk$:ifk$=""thengoto11050
11051 ifk$=chr$(13)thengoto11090
11052 if(k$<"0")or(k$>"6")thengoto11050

; Select new SCSI device
11053 k=val(k$):ifsi(k)>=0thensd=k:goto11020
11054 goto11050

11090 pl=-1:br=-1:so=-1:return


; Print list of known SCSI devices
; Note: 'dd' is always the last selected CMD-HD.
11200 printtt$
11220 print"  known scsi devices for cmd-hd:";dd;"{down}"
11221 print"  id  vendor/device          removable"
11222 printli$

; Narrow-scsi/scsi-1 supports id=0-6 only
11230 fori=0to6

; Is current device = active device?
11231     a$=" ":ifi=sdthena$="*"

; Print device type:
;   $00 = hdd/zip  (h/z)
;   $05 = cd-drive (c)
;   $07 = mo-drive (m)
11232     b$=" "
11233     if(si(i)=0)and(sm(i)=0)thenb$="h"
11234     if(si(i)=0)and(sm(i)>0)thenb$="z"
11235     if(si(i)=5)thenb$="c"
11236     if(si(i)=7)thenb$="m"

; Is device available?
11237     print a$;right$(sp$+str$(i),2);" ";
11238     ifsi(i)=-1 thenprint"  ---{down}":goto11260

; Print vendor information
11240     print b$;" ";
11241     print ">";left$(sv$(i)+sp$, 8);"<"

; Print device information
11250     print "      >";left$(sp$(i)+sp$,16);"<          ";

; Removable media support?
11251     ifsm(i)=0thenprint" no"
11252     ifsm(i)>0thenprint"yes"

; Continue with next device
11260 next
11270 print li$

11290 return
