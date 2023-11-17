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
; 10000.menu-slcthd.bas - select new cmd-hd
;

; Select a new CMD-HD
10000 printtt$
10010 print"  select cmd-hd:"
10011 print"{down}{down}  currently selected:";dd;"{down}"

; Get device data
10020 dv=dd:gosub50400
10021 print"   >default address:";h1
10022 print"   >swap-key mode  :";
10023   ifh2=0thenprint" disabled"
10024   ifh2>0thenprint" active /";h2
10025 print"   >custom address :";
10026   ifh3=0thenprint" no"
10027   ifh3>0thenprint" yes /";h3

10030 print"{down}{down}  press +/- to select cmd-hd or"

; "Press <return> for main menu."
10031 gosub9520

; Wait for a key
10040 getk$:ifk$=""thengoto10040

; Find next CMD-HD
10050 ifk$<>"+"thengoto10060
10051 dd=dd+1:ifdd>30thendd=8
10052 ifdd=dvthengoto10040
10053 ifhd(dd)=0thengoto10051
10054 goto10000

; Find previous CMD-HD
10060 ifk$<>"-"thengoto10070
10061 dd=dd-1:ifdd<8thendd=30
10062 ifdd=dvthengoto10040
10063 ifhd(dd)=0thengoto10051
10064 goto10000

; Select CMD-HD
10070 ifk$<>chr$(13)thengoto10040

; Get active SCSI-ID
10080 gosub50900

; All done
10090 return
