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
; 55400.sysfile-write.bas - write main o.s. to disk
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

; Write new system os

; Test for AutoFormat
55400 ifmk$=af$thengoto55410

; Check system files...
55401 gosub54800:ifec>0thengoto55790

55410 printtt$
55411 print"  preparing system area{down}{down}"
55412 print"  please be patient..."
55413 print"  (this may take some time){down}{down}"

; Find system area
55420 es=0:ifso<0thengosub51400:ifes>0thengoto55790

; Read system header info
55430 gosub55900


; Write main o.s.
55500 print"  writing main o.s.{down}"

; Open system file
55506 open2,ga,0,s0$:open15,dv,15
; Skip load address
55507 get#2,a$,a$

55510 ba=db:forwi=1todcstep2
;55520     print"{up}  block:";wi+1;"{left} /";dc;"{left} "
55520     print"{up}  process:";int(wi/dc*100)"{left}% "
55521     forwj=0to511
55522         get#2,a$:bu(wj)=asc(a$+nu$)
55523     next
; Send buffer to CMD-HD
55524     gosub58000
; Convert LBA to h/m/l
55525     gosub58900:wh=bh:wm=bm:wl=bl
; Write block to disk
55527     gosub58300:ifes>0thenwi=dc
55529     ba=ba+1:print"{up}";sp$;sp$
55530 next

55540 close2:close15

55550 ifes>0thengoto55780


; Write geos/hd driver.
55600 print"{up}  writing geos/hd driver{down}"

; Open system file
55606 open2,ga,0,s1$:open15,dv,15
; Skip load address
55607 get#2,a$,a$

55610 ba=gb:forwi=1togcstep2

;55620     print"{up}  block:";wi+1;"{left} /";gc;"{left} "
55620     print"{up}  process:";int(wi/gc*100)"{left}% "

55621     forwj=0to511
55622         get#2,a$:bu(wj)=asc(a$+nu$)
55623     next

; Send buffer to CMD-HD
55624     gosub58000

; Convert LBA to h/m/l
55625     gosub58900:wh=bh:wm=bm:wl=bl

; Write block to disk
55627     gosub58300:ifes>0thenwi=gc
55629     ba=ba+1:print"{up}";sp$;sp$

55630 next

55640 close2:close15

55650 ifes>0thengoto55780


; Write system header.
; This file includes checksum and date info for
; the system files 'hdos v?-??' and 'geos/hd v?.??'.
55700 print"{up}  writing system header"

; Set base address to $xx:0400-$xx:05FF
55710 ba=so+2

; Open command channel
55720 open15,dv,15

; Convert LBA to h/m/l
55721 gosub58900:rh=bh:rm=bm:rl=bl

; Read block from disk
55723 gosub58200:ifes>0thengoto55750

; Read buffer from CMD-HD
55725 gosub58100

; Read system header into buffer
55730 open2,ga,0,s3$
; Skip load address
55731 get#2,a$,a$
55732 for i=0 to 255
55733     get#2,a$:bu(i)=asc(a$+nu$)
55734 next
55735 close2

; Send buffer to CMD-HD
55740 gosub58000

; Convert LBA to h/m/l
; Block address still in buffer
; 55741 gosub58900:wh=bh:wm=bm:wl=bl

; Write block to disk
55742 wh=bh:wm=bm:wl=bl:gosub58300

55750 close15
55751 ifes>0thengoto55780

; Test for AutoFormat
55760 ifmk$=af$thengoto55770

; "Done"
55761 gosub9000

; Wait for return
55762 gosub60400
; All done
55770 return


; ERROR. Write file to disk.
55780 print"{down}  write error: ";es

; Wait for return
55781 gosub60400
; All done
55790 return
