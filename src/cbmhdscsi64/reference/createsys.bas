; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; createsys.bas - Written by C.M.D.
; Version: V1.12
;
; A tool for C64/C128 which can be used to
; create a new system partition table for the CMD-HD.
;
; Additional comments by Markus Kanet
; Version: V1.00 02/08/2020
;

; Check for C64/C128.

 1000 f=abs(peek(65533)=255): rem f=0 -> C64

; C64: Set beginning of free string memory to $2000.

 1010 iff=0thenclr:poke51,00:poke55,00:poke52,32:poke56,32:f=0

; Get current device address for loading additional files.
; Write computer type to $00FA for the assembler part of the
; 'CREATE.SYS' utility (see 'CREATESYS.ASS').

 1020 dl=peek(186):poke250,f

; Define system call for the assembler part of 'CREATE.SYS'.

 1030 iff=0thenml=peek(46)*256+peek(45)-147: rem c64
 1040 iff=1thenml=peek(4625)*256+peek(4624)-147: rem c128

; Define location of the internal buffer.

 1050 ta=2*4096:iff=1thenta=4*4096:bank15

; Disable parallel cable between CMD-RAMLink/CMD-HD.

 1060 ifpeek(57513)=120then@p0
 1070 :

; Display warning message and wait for the CMD-HD to
; be set into configuration mode.
; Note: It should be possible to replace this using the CMD-89
;       autoexec code. Since there might be an unformatted disk
;       inside of the CMD-HD the autoexec code must be sent to
;       the CMD-HD manually. Enable config mode is then at $8E06.

 1080 print"{clr}{down}create sys v1.12"
 1090 print"{down}this program creates a new system"
 1100 print"area on your hd."
 1110 print"{down}warning: continuing will cause any data"
 1120 print"and partitions on the hd to be lost!!"
 1130 print"{down}important: this program must be run"
 1140 print"from a floppy disk that contains the"
 1150 print"files 'rewrite dos', 'system header',"
 1160 print"'hdos v?.??' and 'geos/hd ?.??'."
 1170 print"{down}remember: after running this program,"
 1180 print"you will have to use hd-tools to create"
 1190 print"new partitions."
 1200 print"{down}to begin, hold down 'swap 8' & 'swap 9'"
 1210 print"while you press and release 'reset'."
 1220 print"{down}press <return> to create the new system"
 1230 print
 1240 geta$:ifa$<>chr$(13)then1240
 1250 :

; Define system settings:
; so : start offset block on cmd-hd medium
; dv : Device address CMD-HD
; sd : SCSI device address
; sl : SCSI logical unit number (LUN)
; sb : SCSI data buffer in CMD-HD ram ($4000)

 1260 so=3
 1270 dv=30:sd=0:sl=0:sb=16384

; READ CAPACITY command
; The READ CAPACITY command requests that the device server transfer
; 8 bytes of parameter data describing the capacity and medium format
; of the direct-access block device to the data-in buffer.

 1280 sc$="25 00 00 00 00 00 00 00 00 00"
 1290 gosub2020: rem send read capacity command
 1300 ifss<>0thenprint"scsi error"ss:end

; Get number of total 512-byte blocks on medium.
; tb : Number of 512-byte blocks

 1310 open15,dv,15,"m-r"+chr$(bl+1)+chr$(bh)+chr$(3)
 1320 get#15,a$,b$,c$:ch=asc(a$+chr$(0)):cm=asc(b$+chr$(0)):cl=asc(c$+chr$(0))
 1330 close15:tb=ch*65536+cm*256+cl
 1340 :

; Clear screen and display storage size and the
; number of 512-byte blocks. 

 1350 print"{clr}total storage ="tb"blocks": rem 512-byte blocks
 1360 print"              ="tb*512"bytes": rem storage size in bytes
 1370 :

; Define starting block address (defaults to 3x128 = 384).
; Allowed range is 0 to 255 with offset < (total blocks -2048).
; Note: One block = 512 bytes!
;
; Max. offset is 255 x 128 x 512 bytes = $FF:0000.
; This means the system header must be inside of the
; a 64k area within the first 16mb of the current medium.
;
; 2048 blocks with 512 bytes each block is $01:0000.
;
; The system area requires at least $01:0000 bytes.
; Therefore you need a medium with at least 2Mb for a
; system area and a data area for partition data.
;
; Starting block address(3) x 128 = 384
; 384 blocks with 512 bytes each block = $03:0000

; This might be confusing:
 1371 print:print"system starting block ="so*128

; This is more easy to understand:
; A system area always begins at $xx:0000. This means:
; $xx * 256 * 256-byte blocks(64K) or $xx * 128 * 512-byte blocks.
;
;1371 print:print"system starting block ="so*($01:0000/$0200)
;1371 print:print"system starting block ="so*( 65536  / 512 )
;
; Why not print the full byte address like:
; "system starting address = $03:xxxx"
; "(192Kb reserved = 384 blocks with 512 bytes/block)"
;
; Currently there does not seem to be any need for a
; starting system block <> 0.

 1372 print" use{rght}+ or - to change, return to accept."
 1373 print" (note: default is normally 384)
 1374 getk$:ifk$=""thengoto1374
 1375 ifk$="+"thenso=so+1:if(so=256)or(so*128>tb-2048)thenso=0
 1376 ifk$="-"thenso=so-1:ifso<0thenso=0
 1377 ifk$=chr$(13)thengoto1380
 1378 goto1350
 1379 :

; Convert total blocks into hi/mid/low byte.

 1380 le=tb+1
 1390 lh=int(le/65536)
 1400 lm=int((le-lh*65536)/256)
 1410 ll=le-lh*65536-lm*256
 1420 :

; Clear area below system block.

 1421 ifso=0thengoto1450
 1422 print"{down}clear area below system if not"
 1423 print"sharing hd with other computer types."
 1424 print"{down}clear area below system? ";
 1425 getk$:ifk$<>"y"andk$<>"n"thengoto1425
 1426 printk$:ifk$="n"thengoto1450
 1427 print:print"clearing area below system"
 1429 :

; Clear block buffer.

 1430 fori=0to255:poketa+i,0:next

; Send 'so' blocks to clear area below system
; This will only clear one sector of a 64Kb area which is used
; on the first system block for the system header.
; It seem to be enough to clear just these 256 bytes of a 64Kb
; area to delete any existing CMD-HD detection code.
; This will clear the following sectors:
;   -> $0000:0500-$0000:05FF
;   -> $0001:0500-$0001:05FF
;   -> $0002:0500-$0002:05FF
; If the starting system block is set to 3 (default) then the
; following sector will contain the system header.
;   -> $0003:0500-$0003:05FF

 1440 for bh=0toso-1:gosub1760:next

; Create system partition.

 1450 print:print"creating device table"
 1460 :
 1470 i$=chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(128)+chr$(1)+chr$(0)
 1480 i$=i$+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)
 1490 i$=i$+"cmd hd  "+chr$(141)+chr$(3)+chr$(136)+chr$(142)
 1500 i$=i$+chr$(2)+chr$(136)+chr$(234)+chr$(96)

; Clear device map:
;   $0000-$0037 = scsi device id/lun
;   $0038-$006f = High byte / start address in 512byte blocks.
;   $0070-$00a7 = Middle byte
;   $00a8-$00df = Low byte
;   $00e0-$00ef = system data
;   $00f0-$00ff = CMD-HD detection code

 1510 fori=0to223:poketa+i,255:next

; Clear device info.
; Note: Byte#0 is the SCSI device ID x16 + LUN.
;       (High-nibble=SCSI-ID, Low-nibble=LUN)

 1520 fori=0to3:poketa+(i*56),0:next

; To support other devices this is recommended.
;     poketa+0,sd*16+sl

; Write system data and CMD-HD detection code:
;   $0003:05E0: 00:00:00:00:00:80:01:00:00:00:00:00:00:00:00:00
;   $0003:05F0: 43:4D:44:20:48:44:20:20:8D:03:88:8E:02:88:EA:60

 1530 fori=0to31:poketa+i+224,asc(mid$(i$,i+1,1)):next

; Write number of total blocks for device.
;   $0003:$0539: Total block hount 'lh'
;   $0003:$0571: Total block count 'lm'
;   $0003:$05A9: Total block count 'll'
;
; Note: The values will be the beginning for the next possible
;       SCSI device.

 1540 poketa+57,lh:poketa+113,lm:poketa+169,ll

; Initialize default device address/partition.
;   dn: Default address for the CMD-HD.
;   dp: Default partition for the CMD-HD.

 1550 dn=12:dp=1
 1560 poketa+225,dn:poketa+228,dn
 1570 poketa+226,dp:poketa+227,dp
 1580 :

; Write device table to disk.

 1590 print"writing device table"
 1600 bh=so:gosub1760
 1610 :

; Write partition table.
; Note: Commands need to be verified:
;
; Guess: p-h: "Partition header"
;             Select partition header
;        p-n: "New partition"
;             Clear partition header
;        p-u: "Partition update"
;             Update partiton header

 1620 open15,30,15:print#15,"p-h"
 1630 print#15,"p-n"
 1640 print:print"writing partition table"
 1650 :

; Create entry for system partition.

 1660 pn=000:pt=255:sh=000:sm=000:sl=144
 1670 oh=000:om=int((so*256/2)/256):ol=so*256/2-om*256
 1680 pn$="system":gosub 2190
 1690 :

; Update partition table on disk.

 1700 print#15,"p-u"
 1710 close15

; System created, rewrite HD-DOS and GEOS/OS.

 1720 cs=1: rem create sys flag
 1730 load"rewrite dos",dl
 1740 :
 1750 :

; Send data block to CMD-HD
; Parameter: ta = internal buffer in C64/C128 ($2000/$4000)
; lb: Low-byte internal buffer
; hb: High-byte internal buffer
; bl: 5 -> Area $0500:05FF of a 64Kb area on the medium.

 1760 lb=00:hb=ta/256:bl=5:bc=1
 1770 poke 251,lb: poke 252,hb:print

; co: 144/$90 Job command "Write logical block"
; dv: CMD-HD device address in configuration mode

  co=144
 1790 poke 186,dv

; The following code will write exactly one sector
; to the medium because 'bc=1'

 1800 for i=1 to bc: rem write 1 block
 1810 for j=1 to 8: rem send 8x32 bytes to cmd-hd ram
 1820 sys ml+3: rem send 32 bytes to cmd-hd at $0300
 1830 next j
 1840 :
 1850 gosub 1910: rem write 256 bytes to medium

; The following line is useless because 'bl' is always 5 and
; 'next i' will always finish the loop.
; Looks like some code accidentally ported from rewrite.dos

 1860 bl=bl+1:ifbl=256thenbl=0:bh=bh+1
 1870 :
 1880 next i
 1890 return
 1900 :

; Write logical block to disk
; CMD-HD address: $0000 = Job queue
;                 $0008/$0009 = Job track and sector
;                 $0300 = Job queue buffer
; Parameter: bh = block address HIGH
;            bl = block address LOW
;            co = Job command

 1910 ec=04: rem number of retries

; Write job address -> $0008

 1920 open15,dv,15,"m-w"+chr$(08)+chr$(00)+chr$(2)+chr$(bh)+chr$(bl)

; Write job command -> $0000

 1930 print#15,"m-w"+chr$(00)chr$(00)chr$(1)chr$(co)

; Read job status byte

 1940 print#15,"m-r"+chr$(00)chr$(00)chr$(1)
 1950 get#15,a$:ifa$=""thena$=chr$(0)

; Job still in progress?
; >127 = TRUE, wait...

 1960 ifa$>chr$(127)then 1940

; Job successful?
; 0/1 = TRUE, done.

 1970 ifa$<chr$(2)  then close15:return

; Job error... retry multiple times.
; If error still occures, exit program.

 1980 ec=ec-1:ifec>0then 1930
 1990 print"write error"asc(a$):close15:end
 2000 :
 2010 :

; Send CMD-HD SCSI command / ASCII format
; Convert SCSI command from ASCIi to binary and send the
; command to the CMD-HD.
; Return:    ss=0 / OK

 2020 gosub2110
 2030 bh=int(sb/256):bl=sb-bh*256
 2040 gosub2060:ifss<>0thengosub2060
 2050 return

; Send CMD-HD SCSI command / Binary format
; Parameter: sd  = SCSI device address
;            al  = SCSI data buffer low address
;            ah  = SCSI data buffer high address
;            ss$ = SCSI command bytes
; Return:    ss  = SCSI SENSE / error code

 2060 open15,dv,15,"s-c"+chr$(sd)+chr$(bl)+chr$(bh)+ss$
 2070 get#15,sa$,sb$:ss=asc(sa$+chr$(0))
 2080 close15:return
 2090 :
 2100 :

; Convert SCSI command from ASCII into byte values
; Parameter: sc$ = SCSI-Command as ASCII string "00 11 22..."
; Return:    ss$ = SCSI-Command as byte values

 2110 ss$=""
 2120 for i=1 to len(sc$) step3
 2130 hv%=asc(mid$(sc$,i,1))-55:ifhv%<10thenhv%=hv%+7:hv%=hv%*16
 2140 hl%=asc(mid$(sc$,i+1,1))-55:ifhl%<10thenhl%=hl%+7
 2150 ss$=ss$+chr$(hv%+hl%)
 2160 next:return
 2170 :
 2180 :

; Create partition entry
; Parameter: pn$ = Partition name
;            pt  = CMD partition type
;            ox  = Partition offset h/m/l
;            sx  = Partition size h/m/l
;
; Guess: p-p = "Partition prepare"
;              Set data for a partition
;        p-w = "Partition write"
;              Write new partition data to disk

 2190 iflen(pn$)=16then2220
 2200 for i=len(pn$)to 15
 2210 pn$=pn$+chr$(160):next
 2220 pp$=chr$(pt)+chr$(0)+chr$(0)+pn$+chr$(oh)+chr$(om)+chr$(ol)
 2230 pp$=pp$+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(sh)+chr$(sm)+chr$(sl)
 2240 print#15,"p-p"+chr$(pn)+pp$
 2250 print#15,"p-w":return
