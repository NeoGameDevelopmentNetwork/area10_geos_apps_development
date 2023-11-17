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
; 15000.menu-directory.bas - menu: display directory
;

15000 open1,ga,15:close1
15010 ifst=0thengoto15100
15020 printtt$:print"  hd.ini config directory:{down}"
15030 print"  error:"
15035 print"  device not present!"{down}"
15040 goto15300

15100 open1,ga,0,"$:*.ini=s"
15110 get#1,a$,a$:e$=chr$(0)

15200 i=0:printtt$:print"  hd.ini config directory:{down}"
15210 get#1,a$,a$,h$,l$:ifstthenclose1:print:goto15300
15220 print"{left}"asc(h$+nu$)+256*asc(l$+nu$);
15230 fors=0to1:get#1,a$,b$:ifa$thenprinta$b$;:s=abs(st):next
15240 printa$:i=i+1
15250 ifi>16thenprint:gosub60400:goto15200
15260 goto15210

; "Press <return> to continue."
15300 ifi>0thengosub60400

; All done
15390 return
