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
; 50700.wait-media.bas - wait for media in drive
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            si(x) = device type
;            sm(x) = removable media
; return   : es    = error status
; temporary: k$
;

; Wait for media in drive
50700 es=0

; SCSI START UNIT
; Don't check for errors here, maybe there is no disk in drive...
50710 gosub59500:rem ifes>0thengoto50790

; Hard disk(hd/zip)?
50720 ifsi(sd)<>0thengoto50730
; Removable media(zip)?
50721 ifsm(sd)=0thengoto50790

; SCSI TEST UNIT READY
50730 gosub59100:ifes<2thengoto50790

50740 printleft$(po$,14):print"{right}";sl$
50741 print"{up}{right}{right}insert media: ";
50742 printright$("   "+str$(dv),2);":";mid$(str$(sd),2);

; "Press <x> to cancel."
50750 print"   (x to cancel)"

; Wait for a key
50760 getk$:ifk$="x"thengoto50790

; SCSI TEST UNIT READY
50761 gosub59100:ifes>=2thengoto50760

; All done
50790 return

