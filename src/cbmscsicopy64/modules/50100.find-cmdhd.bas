; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 50100.find-cmdhd.bas - scan for cmd-hd devices
;
; parameter: -
; return   : es    = error status
;            hd(x) = >0 = cmd-hd available
;            hc    = counter cmd-hd devices
;            dd    = default cmd-hd
;            es    = error status
; temporary: dv,h1,h2,h3,hc,ed,k$
;

; Find CMD-HD devices
50100 printleft$(po$,14)
50110 print"{right}{right}scanning for cmd-hd devices...     ";

50120 es=0:hc=0:dd=0:for dv=8 to 30
50130     print"{left}{left}";right$("  "+str$(dv),2);
50132     open15,dv,15:close15
50133     hd(dv)=0:ifst<>0thengoto50140
; Is device a CMD-HD?
50134     gosub50300:ifes<>0thengoto50140
50135     hd(dv)=dv:hc=hc+1:ifdd=0thendd=dv
50140 next

; We need at least one CMD-HD...
50150 ifhc=0thengosub9100:es=-1:goto50190

; Scan CMD-HD devices for bad device address
50160 es=0:ed=0:fordv=8to29
50161     ifhd(dv)=0thengoto50167
; Get CMD-HD info
50162     gosub50400:ifes<>0thengoto50167
50163     if(h1>0)and(dv<>h1)thenes=es+1
50164     if(h2>0)thenes=es+1
50165     if(h3>0)thenes=es+1
50166     if((h1+h2+h3)>0)and(ed=0)thened=dv
50167 next

; Bad CMD-HD device address?
50170 ifes=0thengoto50180

; Wait for CMD-HD to be reset...
50171 printleft$(po$,15);"{right}";sl$
50172 print"{up}{right}{right}";
50173 print"bad cmd-hd address!  press <return>"
; Wait for <RETURN>
50174 getk$:ifk$<>chr$(13)thengoto50174
50175 printleft$(po$,15);"{right}";sl$
50176 print"{up}{right}{right}";
50177 print"reset cmd-hd #";mid$(str$(ed),2);" and press <return>"
; CMD-HD reset, restart scanning for devices
50178 goto50100

; Get CMD-HD info
50180 dv=dd:gosub50400

; All done
50190 return
