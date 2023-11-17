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
; 10300.menu-editcfgname.bas - edit 'hd.ini' config filename
;

; Select 'hd.ini' device
10300 printtt$
10310 printleft$(po$,5)
10311 print"  enter new configuration filename.{down}"
10312 print"  up to 16 characters are allowed,"
10313 print"  default filename is '";cd$;"'.{down}"
10314 print"  name without file extension '.ini'!{down}"
10315 print"  leave blank to return to menu."
10316 printleft$(po$,4)

10320 print"{up}";sl$
10321 a$="":input"{up}  new filename";a$
10323 ifa$=""thengoto10390

; Remove '.ini' from filename
10330 j=len(a$):fori=1toj
10331   b$=mid$(a$,i,4)
10332   ifb$=".ini"thena$=left$(a$,i-1):i=j
10333 next

; Test for invalid characters
10340 j=len(a$):fori=1toj
10341   b$=mid$(a$,i,1)
10342   es=0:forii=1tolen(ch$)
10343     ifmid$(a$,i,1)=mid$(ch$,ii,1)thenes=1:ii=len(ch$)
10344   next
10345   ifes=0theni=j
10346 next

; Filename valid?
10350 ifes>0then10380

; Display error message
10360 printtt$
10361 print"{down}  invalid config file name!"
10362 print"    -> 34 syntax error 01 00{down}"

; "Press <return> to continue."
10370 gosub60400
10371 goto10300

; Copy new filename
10380 cf$=left$(left$(a$,12)+".ini",16)

; All done
10390 return
