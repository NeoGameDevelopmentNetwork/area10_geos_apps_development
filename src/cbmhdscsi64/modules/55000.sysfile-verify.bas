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
; 55000.sysfile-verify.bas - check system files
;
; parameter: dv    = cmd-hd device address
;            hd    = cmd-hd config-mode device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            sv$(x)= scsi vendor identification
;            sp$(x)= scsi product identification
; return   : -
; temporary: fm$,k$,eb,i,a$,ec(x),e1$,e2$,e3$,he$,by
;

; Check system files...
55000 gosub54800:ifec>0thengoto55390

; Verify CMD-HD system files...
55010 print"  verifying cmd-hd system files:"

; Read system header info
55020 gosub55900


; Verify main o.s.
55100 print"{down}  verifying ";s0$;"{down}"

; Open system file
55106 open2,ga,0,s0$
; Skip load address
55107 get#2,a$,a$

55110 su=0:fori=1todc
55120     print"{up}  blocks remaining:";dc-i;"{left} "
55121     forj=0to255
55122         get#2,a$:su=su+asc(a$+nu$):ifsu>65535thensu=su-65536
55123     next
55130 next

55140 close2

55150 ch=int(su/256):cl=su-ch*256
55151 if(ch<>dh)or(cl<>dl)thengoto55320


; Verify main geos/hd
55200 print"{down}  verifying ";s1$;"{down}"

; Open system file
55206 open2,ga,0,s1$
; Skip load address
55207 get#2,a$,a$

55210 su=0:fori=1togc
55220     print"{up}  blocks remaining:";gc-i;"{left} "
55221     forj=0to255
55222         get#2,a$:su=su+asc(a$+nu$):ifsu>65535thensu=su-65536
55223     next
55230 next

55240 close2

55250 ch=int(su/256):cl=su-ch*256
55251 if(ch<>gh)or(cl<>gl)thengoto55310

; All system files are OK.
55300 print"{down}{down}  all system files ok!"
55301 gosub60400
55302 return

; Checksum error for hdos or geos/hd.
55310 print"{down}  checksum error: ";s1$
55311 gosub60400
55312 return

55320 print"{down}  checksum error: ";s0$
55321 gosub60400
;55322 return

; All done
55390 return
