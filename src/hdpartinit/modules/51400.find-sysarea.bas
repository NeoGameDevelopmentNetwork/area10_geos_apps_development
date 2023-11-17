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
; 51400.find-sysarea.bas - find system partition
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
; return   : -
; temporary: mo,mx,he$,by$,ba,bc,rh,rm,rl,a
;

; Find system partition
51400 mo=0:goto51420:rem system area and system o.s.
51410 mo=1:rem check for system area only

; Wait for media in device
51420 gosub50700:ifes>2thenreturn
51421 es=0:so=-1:rem clear system area offset

; Open command channel
51430 open15,dv,15

; SCSI READ CAPACITY
51431 gosub59400

; Get last possible system area
51432 mx=int(tb*512/65536)-1
51433 ifmx>255thenmx=255
51434 ifmm<0thengoto51460

; Start search for system area
51440 print"  searching for system area... ";
51442 forbc=0tomx

51443     printright$("   "+str$(int(bc*100/mx)),3);"%{left}{left}{left}{left}";

; Check for system area
51444     gosub51500:ifes>0thengoto51450

; Check for system o.s.
51445     ifmo<>0thengoto51446
51446     gosub51550:ifes>0thengoto51450

; Found CMD-HD system area, exit loop
51447     so=bc*128:bc=255

; Continue with next block
51450 next

; Close command channel
51460 close15

; Did we find a system area?
51470 ifso>=0thengoto51480
51471 print"error!"
51472 print"{down}  no system area found on disk!{down}"
51473 gosub60400
51474 tb=-1:pt(0)=0:pn$(0)="error":ps(0)=0:pa(0)=0
51475 es=128:return

; We have a system area...
51480 print"ok! "
51481 print"  found system area at offset:";so;"{down}"
51482 pt(0)=255:pn$(0)="system":ps(0)=144:pa(0)=so
51483 es=0:return
