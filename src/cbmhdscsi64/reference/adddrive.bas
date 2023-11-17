; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ADD DRIVE V2.00 (C)1989 C.M.D.
; Version: V2.00
;
; Additional comments by Markus Kanet
; Version: V1.00 02/09/2020
;

 1000 rem add drive v2.00 (c)1989 c.m.d.
 1010 vn$="v2.00"

; Check for C64/C128.

 1020 f=abs(peek(65533)=255)

 1030 poke53280,0:poke53281,0
 1040 gosub 3420
 1050 :
 1060 dimdl%(56)
 1070 :

; Define system settings:
; ha : Internal buffer
; td : Device address CMD-HD

 1080 iff=0thenha=52736
 1090 iff=1thenha=dec("1900"):bank15
 1100 td=30
 1110 :

; Check for CMD-HD.

 1120 open15,td,15,"m-r"+chr$(160)+chr$(254)+chr$(6)
 1130 fori=1to6:get#15,a$:id$=id$+a$:next
 1140 ifid$<>"cmd hd"then print"hd not present":close15:end
 1150 :

; Add or remove drive?

 1160 input"{clr}{down}add or remove drive (a/r)";ar$
 1170 ifar$<>"a"andar$<>"r"then1160
 1180 :

; lb: Unused, low-byte internal buffer.
; hb: unused, high-byte internal buffer.
; tl: Low-byte block buffer in CMD-HD.
; th: High-byte block buffer in CMD-HD.

 1190 lb=00:hb=ha/256:tl=00:th=03:print:print

; bl: Low-byte of relative address of hardware block.
; bh: High-byte of relative address of hardware block.
; bc: Always 1 = Read only one block.
; Note: bh/bl will point to one block in the 64kb system area.
;       $00/$05 points to the hardware block.

 1200 bl=5:bh=0:bc=1:print"reading hardware block";:gosub3040
 1210 :
 1220 ifar$="a"thengosub1250:goto2160
 1230 ifar$="r"then1430
 1240 :

; Print list of devices currently listed in the hardware block.

 1250 print"{clr}currently recognized scsi drives":print
 1260 print" dev lun   dev lun   dev lun   dev lun"
 1270 print" {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}"
 1280 :

; Print all SCSI device address/LUN and create a data array
; that includes the SCSI device address / LUN (dl%).

 1290 t1=1:t2=5
 1300 forc=0to3
 1310 :print"{home}{down}{down}{down}{down}";
 1320 :for i=c*14 to c*14+13

; Test if SCSI device does exist, if not skip display SCSI device.

 1330 : dl=peek(ha+i):if dl=255 then print      tab(t1+c*10)" -   -":goto1370

; SCSI device/LUN available:
; Bit %xxxx.... = SCSI device address
; Bit %....xxxx = SCSI LUN

 1340 : d=(dl and 240)/16
 1350 : l=(dl and 15)
 1360 : printtab(t1+c*10)d;tab(t2+c*10)l
 1370 : dl%(i)=dl
 1380 :next i
 1390 next c
 1400 return
 1410 :
 1420 :

; Remove a drive from hardware block.

 1430 gosub3620

; Create menu with all SCSI devices

 1440 print"{clr}currently recognized scsi drives":print
 1450 print" dev lun   dev lun   dev lun   dev lun"
 1460 print" {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}"
 1470 :

; Print all SCSI device address/LUN and create a data array
; that includes the SCSI device address (d%) and the SCSI LUN (l%).

 1480 dim d%(56),l%(56)
 1490 t1=1:t2=5:ct=1:fori=1to56:d%(i)=255:l%(i)=255:next
 1500 forc=0to3
 1510 :print"{home}{down}{down}{down}{down}";
 1520 :for i=c*14 to c*14+13

; Test if SCSI device does exist, if not skip display SCSI device.

 1530 : dl=peek(ha+i):if dl=255 then print      tab(t1+c*10)" -   -":goto1570

; SCSI device/LUN available:
; Bit %xxxx.... = SCSI device address
; Bit %....xxxx = SCSI LUN

 1540 : d=(dl and 240)/16
 1550 : l=(dl and 15):d%(ct)=d:l%(ct)=l:ct=ct+1
 1560 : printtab(t1+c*10)d;tab(t2+c*10)l
 1570 : dl%(i)=dl
 1580 :next i
 1590 next c
 1600 :

; Select the SCSI device address / LUN from the menu.

 1610 p=1
 1620 print"{down}  use the cursor keys to select drive  "
 1630 print"  to remove - press return to continue "

; Define strings to set cursor position.

 1640 xp$="{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}":yp$="{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}"

; Define cursor position according to current selected entry.

 1650 xp=int((p-1)/14):yp=p-(xp*14):xp=xp*10+8

; Print a marker next to the current selected entry.

 1660 print"{home}{down}{down}{down}";
 1670 printleft$(xp$,xp);
 1680 printleft$(yp$,yp);
 1690 print"_";

; Wait for a key...

 1700 getk$:ifk$<>chr$(13)andk$<>"{down}"andk$<>"{up}"andk$<>"{left}"andk$<>"{rght}"then1700

 1710 ifk$="{down}"andp<56thenifd%(p+1)<>255thenp=p+1
 1720 ifk$="{up}"andp>1thenifd%(p-1)<>255thenp=p-1
 1730 ifk$="{rght}"andp<43thenifd%(p+14)<>255thenp=p+14
 1740 ifk$="{left}"andp>14thenifd%(p-14)<>255thenp=p-14

; Entry selected, continue...

 1750 ifk$=chr$(13)thend=d%(p):l=l%(p):goto1790

; Remove marker and set new position.

 1760 print"{left} ";:rem d & l
 1770 goto1650
 1780 :

; Clear info area.

 1790 print"{home}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}";
 1800 print"                                       "
 1810 print"                                       "
 1820 print"{up}{up}";
 1830 :

; Test selected entry.
; If position=1 then display error message and exit.
; Position=1 is the system drive which can not be removed.

 1840 ifp<>1then1890
 1850 ifp= 1thenprint"  sorry... the system drive"
 1860 print "  cannot be removed.":close15:end
 1870 :
 1880 :

; Display a warning about SCSI device / LUN to be removed.

 1890 print"  remove dev."d" lun."l
 1900 print"  are you sure (y/n)?
 1910 geta$:ifa$=""then1910
 1920 ifa$<>"y"thenclose15:end
 1930 :

; Remove selected device.
; p : (Selected Entry 1-56) -1
; ha: Starting address internal buffer
; ox: HI/MID/LO starting block of 1st SCSI device

 1940 hi=p-1:dl=ha:oh=ha+56:om=oh+56:ol=om+56

; a : Starting address block of next device
; sr: Total block count of device to be removed

 1950 a=peek(oh+hi+1)*65536+peek(om+hi+1)*256+peek(ol+hi+1)
 1960 sr=a-(peek(oh+hi)*65536+peek(om+hi)*256+peek(ol+hi))
 1970 :

; Remove selected SCSI Device/ID + LUN from hardware table.
; dl: Starting address internal buffer
; hi: Current position in hardware table

 1980 pokedl+hi,peek(dl+hi+1)

; Get starting address of next SCSI device +1.
 1990 ms=peek(oh+hi+2)*65536+peek(om+hi+2)*256+peek(ol+hi+2)

; Is current device available?
; If available, no need to correct the following devices.

 2000 ifpeek(dl+hi)=255thensr=0

; Calculate new starting block of next SCSI device.

 2010 ns=ms-sr
 2020 nh=int(ns/65536)
 2030 nm=int((ns-nh*65536)/256)
 2040 nl=ns-(nh*65536+nm*256)
 
; Write new starting block of next SCSI device into hardware block.

 2050 pokeoh+hi+1,nh
 2060 pokeom+hi+1,nm
 2070 pokeol+hi+1,nl

; Set pointer to next deivce.

 2080 hi=hi+1

; Continue if next deivce is available.

 2090 ifpeek(dl+hi)<>255then1980
 2100 :

; Drive removed, write hardware block and exit program.

 2110 print"{up}{up}  writing hardware block      "
 2120 print"                             "
 2130 gosub2900
 2140 gosub1290:print"{down}  drive has been removed."
 2150 close15:end

; Add new SCSI device.

 2160 print
 2170 print"scanning for new scsi drive:   dev lun"
 2180 print"                               {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}":print

; Controller reset / re-read hardware block.

 2190 gosub3130

; Initialize SCSI-ID / LUN.

 2200 d=0:l=0
 2210 :

; SCSI command data
; dv: Device address CMD-HD
; sd: SCSI device address
; sl: SCSI logical unit number (LUN)
; sb: SCSI data buffer in CMD-HD ram ($4000)

 2220 : dv=td:sd=d:sl=l:sb=16384

; TEST UNIT READY command
; The TEST UNIT READY command provides a means to check if the logical
; unit is ready. This is not a request for a self-test.
; If the logical unit is able to accept an appropriate medium-access
; command without returning CHECK CONDITION status, this command shall
; return a GOOD status.
; If the logical unit is unable to become operational or is in a state
; such that an application client action (e.g., START UNIT command) is
; required to make the logical unit ready, the command shall be
; terminated with CHECK CONDITION status, with the sense key set to
; NOT READY.

 2230 : sc$="00 00 00 00 00 00"
 2240 : gosub3240

; Print SCSI device address.

 2250 : print"{up}"tab(31)d tab(35)"  "

; Test for SCSI LUN and print SCSI device if avilable.

 2260 : if ss=133thenl=7:goto2360

; Device available,

 2270 : print"{up}"tab(35)l
 2280 : if ss<>0then2360

; If device is ready create DEV/LUN address and copy the address
; into the internel data buffer.
; Bit %xxxx.... = SCSI device address
; Bit %....xxxx = SCSI LUN

 2290 : dl=d*16+l
 2300 : fl=0
 2310 : for i=0to55
 2320 :  if dl%(i)=dl then fl=1
 2330 : next
 2340 : if fl=0then 2410
 2350 :
 2360 l=l+1:ifl=8thenl=0:d=d+1

; All SCSI device address tested?
; Note: Currently on NARROW SCSI-1 the device address #7 is reserved
; for the SCSI initiator host device.
; Testing SCSI device address #0 to #6 should be enough.

 2370 if d<8 then 2220
 2380 print"{up}no new drives found":gosub3130:close15:end
 2390 :
 2400 :

; READ CAPACITY command
; The READ CAPACITY command requests that the device server transfer
; 8 bytes of parameter data describing the capacity and medium format
; of the direct-access block device to the data-in buffer.

 2410 gosub3130: rem controller reset
 2420 sc$="25 00 00 00 00 00 00 00 00 00"
 2430 gosub3240:ifss<>0thenprint"scsi error"ss:close15:end
 2440 :

; Get number of total 512-byte blocks and block size on medium.
; le : Block size
; cb : Number of 512-byte blocks

 2450 print"{up}drive found: ";
 2460 print#15,"m-r"+chr$(al+1)+chr$(ah)+chr$(7)
 2470 get#15,a$,b$,c$,l1$,l2$,l3$,l4$

; Define block size.
; Note: l1$ must be '0' or block size might be wrong.

 2480 lh=asc(l2$+chr$(0)):lm=asc(l3$+chr$(0)):ll=asc(l4$+chr$(0))
 2490 le=(lh*65536+lm*256+ll)
 2500 :

; Define block count.
; Note: Max. $FF:FFFF blocks with 512 bytes for each block defines
;       the max. disk size = 8Gb.

 2510 ch=asc(a$+chr$(0)):cm=asc(b$+chr$(0)):cl=asc(c$+chr$(0))
 2520 cb=(ch*65536+cm*256+cl)

; Define storage size.

 2530 by=cb*le
 2540 :

; Calculate storage size in Mb (1.000.000 Bytes)

 2550 cr=by/10000:wp=int(cr):dp=cr-wp:ifdp>=.5thenwp=wp+1
 2560 cr=wp/100
 2570 printcr"mb"

; Test block size: Must be 512 bytes

 2580 ifle<>512thenprint"error: incorrect block size":close15:end
 2590 :
 2600 input"add drive to system (y/n)";yn$
 2610 ifyn$="y"then 2650
 2620 ifyn$="Y"then 2650
 2630 close15:end
 2640 :

; Add selected drive to hardware block.

 2650 i=0

; Find a free position in the hardware table.

 2660 ifpeek(ha+i)=255then2700
 2670 i=i+1:ifi<55then2660

; All 56 possible drives in use, exit.
 2680 print"no room in drive table":close15:end
 2690 :

; Check if entry in hardware table is valid.
; The last position is $37. Since the byte at $37 +1 is
; always "$00" possible devices are $00-$36 = 55 devices.

 2700 ifpeek(ha+i+1)<>255then2680

; Write SCSI-Device / LUN into harware table.
; Bit %xxxx.... = SCSI device address
; Bit %....xxxx = SCSI LUN

 2710 pokeha+i,dl

; Define starting address in the storage volume.

 2720 sh=peek(ha+i+56)
 2730 sm=peek(ha+i+112)
 2740 sl=peek(ha+i+168)
 2750 sb=(sh*65536)+(sm*256)+sl

; Define new starting address for the next device.
; Note: Why add one extra sector?
;       This will add an empty block between two
;       devices in the storage volume.

 2760 nb=sb+cb+1

; Split starting address into HI/MID/LO byte.

 2770 sh=int(nb/65536)
 2780 sm=int((nb-(sh*65536))/256)
 2790 sl=nb-(sh*65536)-(sm*256)

; Write new starting address for the next device.
; This is why the last entry in the device tab can't be
; used for another device.

 2800 poke(ha+i+57),sh
 2810 poke(ha+i+113),sm
 2820 poke(ha+i+169),sl
 2830 :

; Drive added, write hardware block and exit program.

 2840 print"{up}writing hardware block              "
 2850 gosub1290:print"{down}{down}{down}"
 2860 gosub2900
 2870 close15:end
 2880 :
 2890 :

; Write hardware block to CMD-HD.

; Unused code:
; lb: Unused, low-byte internal buffer.
; hb: unused, high-byte internal buffer.

 2900 poke 250,lb:poke251,hb

; co: 144/$90 Job command "Write logical block"
; td: CMD-HD device address in configuration mode

 2910 co=144
 2920 poke 186,td

; The following code will write exactly one sector
; to the medium because 'bc=1'

 2930 for i=1 to bc
 2940 :
 2950 : for j=1 to 8
 2960 :  mw$="":fork=0to31:mw$=mw$+chr$(peek(ha+(j-1)*32+k)):next
 2970 :  print#15,"m-w"+chr$(tl+(j-1)*32)+chr$(th)+chr$(32)+mw$
 2980 : next j
 2990 : gosub 3140: rem write block

; The following line is useless because 'bl' is always 5 and
; 'next i' will always finish the loop.
; Looks like some code accidentally ported from rewrite.dos

 3000 : bl=bl+1:ifbl=256thenbl=0:bh=bh+1
 3010 next i
 3020 return
 3030 :

; Read hardware block from CMD-HD.

 3040 :
 3050 :
 3060 co=128
 3070 poke 186,td
 3080 gosub 3140: rem read block
 3090 print#15,"m-r"+chr$(tl)+chr$(th)+chr$(0)

; Read data from CMD-HD into the internal buffer.

 3100 fori=0to255:get#15,a$:poke(ha+i),asc(a$+chr$(0)):print".";:next
 3110 return
 3120 :

; Reset SCSI controller.
 3130 co=130: rem $82 = controller reset

; Reset SCSI Controller / Read/Write logical block
; CMD-HD address: $0000 = Job queue
;                 $0008/$0009 = Job track and sector
;                 $0300 = Job queue buffer
; Parameter: bh = block address HIGH
;            bl = block address LOW
;            co = Job command

 3140 ec=2: rem number of retries

; Job address -> $0008

 3150 print#15,"m-w"+chr$(08)chr$(00)chr$(2)chr$(bh)chr$(bl)

; Job command -> $0000

 3160 print#15,"m-w"+chr$(00)chr$(00)chr$(1)chr$(co)

; Read job status byte

 3170 print#15,"m-r"+chr$(00)chr$(00)chr$(1)

; Job still in progress?
; >127 = TRUE, wait...

 3180 get#15,a$:ifa$=""thena$=chr$(0)
 3190 ifa$>chr$(127)then 3170

; Job successful?
; 0/1 = TRUE, done.

 3200 ifa$<chr$(2)  then return

; Job error... retry multiple times.
; If error still occures, exit program.

 3210 ec=ec-1:ifec>0then 3160
 3220 print"disk error"asc(a$)"{left}                 ":close15:end
 3230 :

; Send CMD-HD SCSI command / ASCII format
; Convert SCSI command from ASCIi to binary and send the
; command to the CMD-HD.
; Return:    ss=0 / OK

 3240 gosub3330
 3250 ah=int(sb/256):al=sb-ah*256
 3260 gosub3280:ifss=2 then gosub3280
 3270 return

; Send CMD-HD SCSI command / Binary format
; Parameter: sd  = SCSI device address
;            al  = SCSI data buffer low address
;            ah  = SCSI data buffer high address
;            ss$ = SCSI command bytes
; Return:    ss  = SCSI SENSE / error code

 3280 print#15,"s-c"+chr$(sd)+chr$(al)+chr$(ah)+ss$
 3290 get#15,sa$,sb$:ss=asc(sa$+chr$(0))
 3300 return
 3310 :
 3320 :

; Convert SCSI command from ASCII into byte values
; Parameter: sc$ = SCSI-Command as ASCII string "00 11 22..."
; Return:    ss$ = SCSI-Command as byte values

 3330 ss$=""
 3340 for i=1 to len(sc$) step3
 3350 : hv%=asc(mid$(sc$,i,1))-55:ifhv%<10thenhv%=hv%+7
 3360 hv%=hv%*16
 3370 : hl%=asc(mid$(sc$,i+1,1))-55:ifhl%<10thenhl%=hl%+7
 3380 : if i=4 then hv%=(hv%and31)or(sl*32)
 3390 : ss$=ss$+chr$(hv%+hl%)
 3400 next
 3410 return

; Wait for the CMD-HD to be set into configuration mode.
; Note: It should be possible to replace this using the CMD-89
;       autoexec code. Since there might be an unformatted disk
;       inside of the CMD-HD the autoexec code must be sent to
;       the CMD-HD manually. Enable config mode is then at $8E06.

 3420 print"{clr}"
 3430 print"{cyn}            add drive "vn$
 3440 print"{down}{wht}   before continuing you should place"
 3450 print"    your hd into configuration mode."
 3460 print"{down}   1. press and hold down the write"
 3470 print"      protect switch."
 3480 print"{down}   2. while holding down the write"
 3490 print"      protect switch, press the reset"
 3500 print"      switch once and release it."
 3510 print"{down}   3. continue to hold down the write"
 3520 print"      protect switch until the"
 3530 print"      activity led's stay off."
 3540 print"{down}   4. release the write protect"
 3550 print"      switch. if the write protect"
 3560 print"      led is lit, press and release"
 3570 print"      the write protect switch again."
 3580 print"{down}      press return to continue..."
 3590 getk$:ifk$<>chr$(13)then3590
 3600 return
 3610 :

; Display a warning message.

 3620 print"{clr}{down}"
 3630 print"{rvon}warning{rvof}: removing a drive from the"
 3640 print"hd system configuration does not"
 3650 print"automatically correct the partition"
 3660 print"table to reflect the loss of storage"
 3670 print"space."
 3680 print
 3690 print"any partitions currently existing on"
 3700 print"the removed drive and any following"
 3710 print"add-on drives will no longer be valid"
 3720 print"once the drive is removed by this"
 3730 print"program."
 3740 print
 3750 print"before continuing, you should back up"
 3760 print"any valuable data and then remove any"
 3770 print"partitions currently existing on the"
 3780 print"above-mentioned drive(s)."
 3790 print
 3800 print"note: any partitions and data on the"
 3810 print"system (first) drive are safe and will"
 3820 print"not be altered."
 3830 print
 3840 input"continue (y/n)";yn$
 3860 ifyn$="y"thenreturn
 3870 close15:end
