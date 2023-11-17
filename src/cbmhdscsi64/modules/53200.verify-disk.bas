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
; 53200.verify-disk.bas - verify media
;
; parameter: dv    = cmd-hd device address
;            hd    = cmd-hd config-mode device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            sv$(x)= scsi vendor identification
;            sp$(x)= scsi product identification
; return   : -
; temporary: fm$,k$,eb,i,a$,ec(x),e1$,e2$,e3$,he$,by
;

; Verify media
53200 printtt$:print"  verifying format, please wait...{down}"

; Wait for media in device
53205 gosub50700:ifes>2thengoto53490
53206 es=0:rem reset error status

; If not using the installation mode then it
; might be a good idea to reset the SCSI controller here.
; Only do this for device #8 to #29!
; If CMD-HD is set to #30 then a reset will block
; the serial bus since the CMD-HD cannot find the
; system partition data.

; Disabled for now... do we still need that?
;
; 53220 ifdv=30thengoto53222
; ; Enable config mode
; 53221 gosub51000
; ; Reset SCSI controller
; 53222 dv=hd:gosub50800
;
; 53223 ifh1=30thengoto53227
; 53224 eb=es
; ; Disable config mode
; 53225 gosub51100
; 53226 es=eb
;
; Reset device address
; 53227 gosub50500:ifes>0thengoto53390

; Read disk capacity for verifying data blocks.
53230 print"{down}"
53231 open15,dv,15

; SCSI READ CAPACITY
53232 gosub59450:ifes>0thengoto53450


; Verify blocks on the medium.
; bc: block count
; bf: FAILED blocks
; br: REMAPPED blocks
; of: Offset for verify command
53300 bc=tb:bf=0:br=0:of=0

; Verification loop...
; vl: VERIFICATION length
53320 vl=65535
53321 ifvl>bcthenvl=bc
53322 ifvl=0thengoto53400

; Print bad/remapped blocks...
53330     printleft$(po$,16)
53331     print"  verifying :";of+1;"{left} -";of+vl
53332     print"  bad blocks:";bf
53333     print"  remapped  :";br
53334     print

; VERIFY command
; The VERIFY command requests that the device server verify the
; specified logical block(s) on the medium.
; Each logical block includes user data and may include protection
; information, based on the VRPROTECT field and the medium format.
;
; B02-B05: LBA offset address to start VERIFY
; B07-B08: VERIFICATION LENGTH 1-65535 blocks

53340     he$="2f00":gosub60100:sc$=by$

; LOGICAL BLOCK ADDRESS
; Note: 4-Byte value, 1st byte always #0
53341     bh=int(of/65536)
53342     bm=int((of-(bh*65536))/256)
53343     bl=of-(bh*65536+bm*256)
53344     sc$=sc$+nu$+chr$(bh)+chr$(bm)+chr$(bl)

; GROUP NUMBER (always ZERO)
53345     sc$=sc$+nu$

; VERIFICATION LENGTH
; Note: 2-Byte value in bytes (not blocks)
53346     bh=int(vl/256):bl=vl-(bh*256)
53348     sc$=sc$+chr$(bh)+chr$(bl)

; Control byte
53349     sc$=sc$+nu$

; Send SCSI VERIFY command
53350     gosub59800:ifes=0thengoto53390

; Get SENSE data -> SENSE data error / exit
53360     gosub59300:ifes>0thengoto53450

; BAD BLOCK
; bb = LBA of bad block in MSB..LSB format
53362     bb=ec(4)*65536+ec(5)*256+ec(6)

; SENSE KEY
; Only bit %0 to %4 are used, bit %5 to %7 are reserved
; SENSE CODE:
; $01 = RECOVERED error -> reassign bad block
; $09 = VENDOR SPECIFIC -> continue
; $03 = MEDIUM error    -> reassign bad block
; $xx = ERROR           -> error / exit
53363     if(ec(2)and15)=1thengoto53370
53364     if((ec(2)and15)=9)and(ec(12)=128)thengoto53387
53365     if(ec(2)and15)<>3thengoto53450

; Create list of BAD BLOCK for REASSIGN BLOCKS command
53370     dl$=nu$+nu$+nu$+chr$(4)
53371     dl$=dl$+chr$(ec(3))+chr$(ec(4))+chr$(ec(5))+chr$(ec(6))

; The data-out buffer includes a defect list for the current medium.
; Write BAD BLOCK to defect list.
53372     bf=bf+1
53373     print#15,"m-w"chr$(sl)chr$(sh)chr$(8)dl$

; REASSIGN BLOCKS command
; The REASSIGN BLOCKS command requests that the device server reassign
; defective logical blocks to another area on the medium set aside for
; this purpose. The device server should also record the location of
; the defective logical blocks in the GLIST, if supported.
53380     he$="070000000000":gosub60100:sc$=by$

; Send SCSI command
53381     gosub59800:ifes>0thengoto53450

; BLOCK REMAPPED
53386     br=br+1

; Calculate remaining blocks for VERIFY after an ERROR occured
53387     bc=bc-(bb-of):of=bb:goto53320

; Calculate remaining blocks for VERIFY
53390     bc=bc-vl:of=of+vl
53391 ifbc>0thengoto53320

; FORMAT / VERIFY done
53400 print"{down}  verify disk successful!"

; Wait a few seconds to let the scsi-controller finish job after reset
53410 close15
53420 es=0

; Test for AutoFormat...
53430 ifmk$=af$thengosub51800:goto53440
; Wait for return
53431 gosub60400
53440 return

; FORMAT / VERIFY failed
53450 print"{down}  verify disk failed!"
53460 close15

53461 es=255

; Wait for return
53470 gosub60400
53490 return
