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
; 50100.find-cmdhd.bas - scan for cmd-hd devices
;
; parameter: -
; return   : hd(x) = x / cmd-hd available
;            hc    = counter cmd-hd devices
;            dd    = default cmd-hd
;            es    = error status
; temporary: dv,h1,h2,h3
;

; Find CMD-HD devices
50100 printtt$;left$(po$,7)

50120 es=0:hc=0:dd=0:for dv=8 to 30
50130     print"{up}  scanning for cmd-hd devices...";dv
50131     open15,dv,15:close15
50132     hd(dv)=0:ifst<>0thengoto50140
; Is device a CMD-HD?
50134     gosub50300:ifes<>0thengoto50140
50135     hd(dv)=dv:hc=hc+1:ifdd=0thendd=dv
50140 next

; We need at least one CMD-HD...

; CMD-HD in config mode may be necessary if
; disk in not yet formatted.
; The CMD-HD will block the serial bus and you
; have to manually set the installation mode by
; presing SWAP8+SWAP9 and RESET.
; 50150 ifhd(30)>0thengosub9100:es=-1:goto50190
; "No CMD-HD found!"
50150 ifhc=0thengosub9100:es=-1:goto50190

; Scan CMD-HD devices for bad device address
50160 es=0:ed=0:fordv=8to29
50161     ifhd(dv)=0thengoto50166
; Get CMD-HD info
50162     gosub50400
50163     if(h1>0)and(dv<>h1)thenes=es+1
50164     if(h2>0)thenes=es+1
50165     if(h3>0)thenes=es+1
50166     if((h1+h2+h3)>0)and(ed=0)thened=dv
50167 next

; Bad CMD-HD device address?
50170 ifes=0thengoto50180

; Wait for CMD-HD to be reset...
50171 printleft$(po$,15);
50172 print"  bad cmd-hd address!{down}"
50173 print"  please reset cmd-hd #";mid$(str$(ed),2);" and then"
50174 print"  press <return> to continue."
; Wait for <RETURN>
50175 getk$:ifk$<>chr$(13)thengoto50175
; CMD-HD reset, restart scanning for devices
50176 goto50100

; Get CMD-HD info
50180 dv=dd:gosub50400

; All done
50190 return
