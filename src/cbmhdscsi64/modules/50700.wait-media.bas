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
; 50700.wait-media.bas - wait for media in drive
;
; parameter: dv    = cmd-hd device address
; return   : sd    = cmd-hd scsi device id
;            si(x) = device type
;            sm(x) = removable media
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

50740 print"  please insert media in drive: ";
50741 printmid$(str$(dv),2);":";mid$(str$(sd),2)

; "Press <x> to cancel."
50750 gosub9540

; Wait for a key
50760 getk$:ifk$="x"thengoto50790

; SCSI TEST UNIT READY
50761 gosub59100:ifes>=2thengoto50760

50790 return

