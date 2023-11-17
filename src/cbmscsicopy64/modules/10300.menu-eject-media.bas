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
; 10300.menu-eject-media.bas - menu: eject media
;

; Eject source media
10300 ifhs<0thengoto10330
10310 sd=hs:gosub59600
10320 cs=-1:ct=-1:cs=0:ct=0
10330 return

; Eject target media
10350 ifht<0thengoto10380
10360 sd=ht:gosub59600
10370 ct=-1:ct=0
10380 return
