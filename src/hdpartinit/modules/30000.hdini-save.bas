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
; 30000.hdini-save.bas - save configuration file
;
; parameter: ga    = system device
;            cf$   = configuration file
;            hm    = max. possible partitions
;            pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
; return   : es    = error status
;            e$    = error message
;            tr    = error track
;            se    = error sector
; temporary: ii,st
;

; Write new hd configuration file
30000 printtt$:print"  saving config '";cf$;"'..."
30001 open1,ga,15:close1
30002 ifst>0thenes=st:e$="device error":tr=-1:se=-1:goto30082

; Open new configuration file
30010 open15,ga,15:open2,ga,2,"@0:"+cf$+",s,w"
30011 input#15,es,e$,tr,se
30012 ifes<>0thengoto30080

; Write partition data to file
30020 forii=1tohm
30030   ifpt(ii)=0thengoto30060
30040   print#2,ii;",";pn$(ii);",";pt(ii);",";ps(ii)
30060 next

; Close configuration file
30080 close2:close15

; Check for errors
30081 ifes=0thengosub9000:goto30085
30082 print"{down}  unable to write partitions to file!"
30083 print"    ->";es;e$;tr;se;"{down}"

; "Press <return> to continue."
30085 gosub60400

; All done
30090 return
