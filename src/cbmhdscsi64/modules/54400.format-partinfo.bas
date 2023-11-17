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
; 54400.format-partinfo.bas - create system area
;                           (does not include writing the system files)
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
; return   : es    = error status
; temporary: sy,bamsy,wh,wm,wl,bh,bm,bl,er
;

; Create partition table (16 blocks with 512bytes)
; Each SCSI-block includes two CBM-blocks with 256bytes.

; Clear buffer
54400 gosub58800
54410 print"  writing partition table"

; Create link address to next block and
; write partition table to disk.
54420 open15,dv,15

54421 forsy=15to0step-1
54422     bu(  0)=1:bu(  1)=1+sy*2
54423     bu(256)=1:bu(257)=1+sy*2+1
54424     ifsy<15thengoto54430
54425     bu(256)=0:bu(257)=255

; Send buffer to CMD-HD
54430     gosub58000
54431     ba=so+128+sy

; Convert LBA to h/m/l
54432     gosub58900:wh=bh:wm=bm:wl=bl

; Write block to disk
54434     gosub58300:ifes>0thensy=0

; Next partition
54439 next
54440 ifes>0thengoto54485

; Create partition entry
54450 pn=0:pt=255:pa=so:ps=0:pr=144:pn$="system"
54460 gosub48400

; Add data for system partition
; Block #0 including system partition still in buffer.

; Partition type 255 = system
;54450 bu( 2)=255

; Reserved
;54451 bu( 3)=0
;54452 bu( 4)=0

; Partition name
;54453 bu( 5)=asc("s")
;54454 bu( 6)=asc("y")
;54455 bu( 7)=asc("s")
;54456 bu( 8)=asc("t")
;54457 bu( 9)=asc("e")
;54458 bu(10)=asc("m")
;54459 bu(11)=160
;54460 bu(12)=160
;54461 bu(13)=160
;54462 bu(14)=160
;54463 bu(15)=160
;54464 bu(16)=160
;54465 bu(17)=160
;54466 bu(18)=160
;54467 bu(19)=160
;54468 bu(20)=160

; Start address system partition
; This also includes the complete system area!
;54469 bu(21)=0
;54470 bu(22)=1
;54471 bu(23)=128

; Reserved
;54472 bu(24)=0
;54473 bu(25)=0
;54474 bu(26)=0
;54475 bu(27)=0
;54476 bu(28)=0

; Size of system area and system partition
;54477 bu(29)=0
;54478 bu(30)=0
;54479 bu(31)=144

; Send buffer to CMD-HD
54480 gosub58000

; Block address still in buffer
;54481 wh=bh:wm=bm:wl=bl

; Write block to disk
54482 gosub58300:ifes=0thengoto54490

; Error
54485 print"{down}  writing partition table failed!"
54486 print"{down}  write error:";es

; Wait for return
54487 gosub60400
; Close command channel
54488 close15
54489 return

; All done!
; Check for autoformat
54490 ifmk$=af$thengoto54495

; "Done"
54491 print:gosub9000

; Wait for return
54492 gosub60400
; Close command channel
54495 close15
54499 return
