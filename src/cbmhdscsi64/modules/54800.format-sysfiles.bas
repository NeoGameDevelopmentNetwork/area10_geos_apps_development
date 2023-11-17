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
; 54800.format-sysfiles.bas - check system files
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
; return   : es    = error status
; temporary: sy,bamsy,wh,wm,wl,bh,bm,bl,er
;

; Check if all systemfiles do exist before start format disk
54800 printtt$:print"  checking system files... ";

; Check for system file device
54802 open15,ga,15:close15:ifst<>0thenec=7:goto54850

; Reset error status
54805 ec=0

; Check for "hdos v?.??"
54810 ff$=s0$:gosub55800
54811 ifes=0thengoto54820
54819 ec=ec+1

; Check for "geoshd v?.??"
54820 ff$=s2$:gosub55800
54821 ifes=0thens1$=s2$:goto54830
; Check for "geos/hd v?.??" -> Alternative filename
54822 ff$=s1$:gosub55800
54823 ifes=0thens2$=s1$:goto54830
54829 ec=ec+2

; Check for "system header"
54830 ff$=s3$:gosub55800
54831 ifes=0thengoto54840
54839 ec=ec+4

; Any system files missing?
54840 ifec=0thenprint"ok!{down}{down}":goto54890

; Error: FILE NOT FOUND.
54850 print"error!":print"{down}{down}  missing some system files: {down}"
54851 if(ecand1)>0thenprint"   > ";s0$
54852 if(ecand2)>0thenprint"   > ";s1$
54853 if(ecand4)>0thenprint"   > ";s3$
54855 print"{down}":gosub60400

;All done
54890 return
