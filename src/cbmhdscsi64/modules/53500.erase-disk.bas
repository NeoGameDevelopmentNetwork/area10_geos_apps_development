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
; 53500.erase-disk.bas - erase content from disk
;
; parameter: -
; return   : hd(x) = x / cmd-hd available
;            hc    = counter cmd-hd devices
;            dd    = default cmd-hd
;            sb    = cmd-hd scsi data-out buffer
; external : dv
; temporary: mx,k$,ba,bc,mo,by$,he$,i,j,ec,er,ad,hi,lo,by,bh,bm,bl,wh$,wm$,wl$
;

; Erase content from disk

; Max. count of blocks to be cleared in part-mode.
53500 mx=2048:rem default is 2048x512=1024kb
53501 ifsd>0thengoto53550

; Warn about SCSI device ID=0
53510 printtt$
; "Erase content from disk"
53511 gosub9550:print":{down}"

53520 print"{down}  warning!{down}"
53521 print"  you are going to erase the content"
53522 print"  of the scsi device id=0 !{down}{down}"
53523 print"  are you really sure (y/n) ?"

; Wait for a key
53530 getk$:ifk$=""thengoto53530
53531 if(k$="y")or(k$="Y")thengoto53550
53532 if(k$="n")or(k$="N")thenes=2:goto53590
53533 goto53530

; Erase menu
53550 printtt$
; "Erase content from disk"
53551 gosub9550:print":{down}{down}"

; Print device info
53560 dv=dd:gosub13900

53570 print"{down}  select erase method:{down}"
53571 print"    -a- erase all data from disk (slow)"
53572 print"    -b- erase first";mx;"blocks only{down}"
53573 print"  press a/b to erase data from disk or"
; "Press <return> for main menu."
53574 gosub9520

; Wait for a key
53580 getk$:ifk$=""thengoto53580
53581 if(k$="a")or(k$="A")thenmo=1:goto53600
53582 if(k$="b")or(k$="B")thenmo=0:goto53600
53583 ifk$<>chr$(13)thengoto53580

53590 return


; Init wipe
53600 printtt$
; "Erase content from disk"
53605 gosub9550:print":{down}{down}"

; Open command channel
53610 open15,dv,15

; SCSI READ CAPACITY
53611 gosub59450

; Set count of blocks to be cleared
53620 bc=tb:ifmo=0thenbc=mx

; Clear SCSI data-out buffer in CMD-HD ($4000-$4FFF)
53630 print"{down}  preparing scsi data-out buffer"
; In debug mode use a different pattern for erase
;53631 by$="":fori=0to31:by$=by$+chr$(189):next
53631 by$="":fori=0to31:by$=by$+nu$:next
53632 fori=0to15:forj=0to255step32
53633     ad=sb+i*256+j:hi=int(ad/256):lo=ad-hi*256
53636     print#15,"m-w"chr$(lo)chr$(hi)chr$(32)by$
53637 next

; Start wipe disk
; "Erase content from disk"
53640 gosub9550:print"...{down}"

53650 forba=0tobc-1step8

; Convert LBA to h/m/l
53651     gosub58900
53652     by=bh:gosub60200:wh$=he$
53653     by=bm:gosub60200:wm$=he$
53654     by=bl:gosub60200:wl$=he$

53655     print"{up}    -> $";wh$;":";wm$;wl$;"  / ";int(ba*100/bc);"{left}% "

; Create SCSI "BLOCK WRITE" command
53660     he$="2a0000"+wh$+wm$+wl$+"00000800":gosub60100:sc$=by$

; Send SCSI command
53661     gosub59800:ifes>0thenba=tb

53670 next

; Close command channel
53680 close15

53681 print"{up}";sl$
53682 ifes=0thengoto53690


; WIPE failed
53685 print"{down}  erase content failed!"

; Wait for return
53686 gosub60400
53687 return


; "Done"
53690 gosub9000

; Wait for return
53691 gosub60400
53692 return
