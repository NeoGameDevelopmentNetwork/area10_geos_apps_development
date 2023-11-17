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
; 59300.scsi-sense.bas - REQUEST SENSE
;
; parameter: sl/sh = cmd-hd scsi data-out buffer
; return   : ec(x) = sense data bytes
; temporary: i,a$,he$,sc$,by$,by,ba
;

; REQUEST SENSE command
; The REQUEST SENSE command requests that the device server transfer
; sense data to the application client.

; SCSI REQUEST SENSE
59300 he$="030000001b00":gosub60100:sc$=by$

; Send SCSI command
59320 gosub59800:ifes>0thengoto59390

; Read sense data (27Bytes + NULL)
59330 print#15,"m-r"chr$(sl)chr$(sh)chr$(28)
59331 fori=0to27:get#15,a$:ec(i)=asc(a$+nu$):next

; Display SCSI error
; B00: RESPONSE CODE (70h or 71h)
; B02: SENSE KEY
; B12: ADDITIONAL SENSE-CODE
59340 print"  scsi status:";
59341 by=ec( 0)and127:gosub60200:print" ";he$;
59342 by=ec( 2)and 15:gosub60200:print" ";he$;
59343 by=ec(12):gosub60200:print" ";he$

; Display extended error information
; B03-B06: INFORMATION, the unsigned LOGICAL BLOCK ADDRESS associated
;          with the sense key, for:
;           -> direct-access devices (device type 0),
;           -> write-once devices (device type 4),
;           -> CD-ROM devices (device type 5),
;           -> optical memory devices (device type 7);
59350 print"  block address:";
59351 forba=3to6:by=ec(ba):gosub60200:print" ";he$;:next
59352 print

59390 return
