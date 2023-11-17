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
; 40500.part-delete.bas - delete partition
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pl    = partition number
; return   : es    = error status
; temporary: pn,ba,bh,bm,bl,pt,pt$,kb$,i
;

; Delete last created partition
40500 printtt$:print"  delete partition:{down}"

; Analyze partition table
40510 ifpl<1thengoto40580

; Read partition entry
40511 pn=pl:gosub49200:ifes>0then:goto40575

; Print partition entry
40520 printli$
40521 printright$(sp$+str$(pn),4);" ";

; Print partition name
40522 print"'";:fori=0to15:printchr$(bu(ip+5+i));:next:print"'";

; Print partition size
40523 bh=bu(ip+29):bm=bu(ip+30):bl=bu(ip+31)
40524 gosub58950
40525 printright$(sp$+str$(ba*2),6);" ";

; Print partition type
40526 pt=bu(ip+2):gosub48900:printpt$
40527 printli$;"{down}"

; Delete partition?
40530 print"  delete partition (y/n) ? ";
40540 getkb$:ifkb$=""thengoto40540
40541 if(kb$="y")or(kb$="Y")thengoto40550
40542 if(kb$="n")or(kb$="N")thengoto40599
40543 goto40540

; Delete partition
; Clear partition entry in data block buffer
40550 printkb$;"{down}"
40551 print"  deleting partition"
; Delete a partition by clear the complete partition entry
;40552 fori=0to31:bu(ip+i)=0:next
; Delete a partition the "CMD"-way (clear partition type only)
40552 bu(ip+2)=0

; Write partition entry
40553 gosub49400:ifes>0thengoto40575

; Reload partition table by activating SCSI device
40560 gosub52000:ifes>0thengoto40575

; Reset device address
40561 gosub50500

; Analyze partition table
40565 gosub48000:ifes>0thengoto40599

; Partition deleted
40570 print"  partition deleted!"

; "Done"
40571 gosub9000
40572 goto40590

; "Disk error"
40575 gosub9200
40576 goto40590

; "No more partitions"
40580 gosub9510
40581 printli$

; Wait for return
40590 gosub60400
; All done
40599 return

