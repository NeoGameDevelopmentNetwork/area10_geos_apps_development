; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; LLFORMAT V2.00 (C)1989 C.M.D.
; Version: V2.01 12/19/1994
;
; Additional comments by Markus Kanet
; Version: V1.00 02/05/2020
;
; SCSI command description has been taken from:
;
; SeaGate SCSI Commands Reference Manual
; https://www.seagate.com/files/staticfiles/support/docs/manual/Interface manuals/100293068j.pdf
;
;   Fibre Channel (FC)
;   Serial Attached SCSI (SAS)
;
; 100293068, Rev. J
; October 2016
;

  100 rem llformat v2.00 (c)1989 c.m.d.
  101 vn$="v2.01 12/19/94"

; Test for C64/C128

  102 f=abs(peek(65533)=255)
  110 poke53280,0:poke53281,0
  112 iff=1thenbank15

; Enable configuration mode for the CMD-HD

  120 gosub 2890: rem enable config mode
  140 :
  
; dl%(x) = SCSI device address x16 + SCSI LUN
; d%(x)  = SCSI device address
; l%(x)  = SCSI LUN
; rs(x)  = Requested SCSI SENSE-DATA
  
  150 dim dl%(56),d%(56),l%(56),rs(27)
  160 h$="0123456789abcdef"
  170 :
  172 td=30: rem device address cmd-hd in config mode

; Set internal buffer address for SCSI DEV/LUN data

  174 iff=0thenha=52736: rem = $ce00
  180 iff=1then ha=dec("1900")
  190 :
  200 :

; Check if device #30 is a CMD-HD:
; Read 6 bytes at $FEA0 and check vor "CMD HD"

  210 open15,td,15,"m-r"+chr$(160)+chr$(254)+chr$(6)
  220 fori=1to6:get#15,a$:id$=id$+a$:next
  230 ifid$<>"cmd hd"then print"hd not present":goto 2840
  240 :
  270 :

; Scanning for SCSI devices on the CMD-HD
; Device #0 to #7, LUN #0 to #7
; Currently on NARROW SCSI-1 the device address #7 is reserved
; for the SCSI initiator host device.
; Since llformat scans for device #0 to #7 but only allows
; to select a device from #0 to #6 with LUN from #0 to #7
; this does not have any effect. Max -> 7x8 = 56 devices.

  460 print"{clr}{down}scanning for scsi drives:      dev lun"
  470 print"                               {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}":print

; Clear internal DEV/LUN address buffer

  472 fori=0to255:pokeha+i,255:next
  480 gosub2200: rem reset scsi controller

; Initialize scanning for devices
; d=0  : Start with SCSI device #0
; l=0  : Start with SCSI LUN #0
; hi=0 : Pointer to internal DEV/LUN address buffer

  490 d=0:l=0:hi=0
  500 :

; SCSI command data
; dv: Device address CMD-HD
; sd: SCSI device address
; sl: SCSI logical unit number (LUN)
; sb: SCSI data buffer in CMD-HD ram ($4000)

  510 : dv=td:sd=d:sl=l:sb=16384

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

  520 : sc$="00 00 00 00 00 00"
  530 : gosub2310

; Print SCSI device address.

  540 : print"{up}"tab(31)d tab(35)"  "

; Test for SCSI LUN and print SCSI device if avilable.

  550 : if ss=133thenl=7:goto650; rem SCSI device not available

; Device available,

  560 : print"{up}"tab(35)l
  570 : if ss<>0then650

; If device is ready create DEV/LUN address and copy the address
; into the internel data buffer.
; Bit %xxxx.... = SCSI device address
; Bit %....xxxx = SCSI LUN

  580 : dl=d*16+l
  590 : pokeha+hi,dl:hi=hi+1
  600 :
  650 l=l+1:ifl=8thenl=0:d=d+1

; All SCSI device address tested?
; Note: Currently on NARROW SCSI-1 the device address #7 is reserved
; for the SCSI initiator host device.
; Testing SCSI device address #0 to #6 should be enough.

  660 if d<8 then 510: rem d<8 should be d<7
  700 gosub2200: rem reset scsi controller
  710 :

; Create menu with all SCSI devices

 1000 print"{clr}{down}    currently recognized scsi drives":print
 1010 print"{down} dev lun   dev lun   dev lun   dev lun"
 1020 print" {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}   {CBM-T}{CBM-T}{CBM-T} {CBM-T}{CBM-T}{CBM-T}"
 1030 :
 1040 gosub1060:goto1190: rem why using gosub/return here?
 1050 :

; Print all SCSI device address/LUN and create a data array
; that includes the SCSI device address (d%) and the SCSI LUN (l%).

 1060 t1=1:t2=5:ct=1:fori=1to56:d%(i)=255:l%(i)=255:next
 1070 forc=0to3
 1080 :print"{home}{down}{down}{down}{down}{down}{down}";
 1090 :for i=c*14 to c*14+13

; Test if SCSI device does exist, if not skip display SCSI device.

 1100 : dl=peek(ha+i):if dl=255 then print      tab(t1+c*10)" -   -":goto1140

; SCSI device/LUN available:
; Bit %xxxx.... = SCSI device address
; Bit %....xxxx = SCSI LUN

 1110 : d=(dl and 240)/16
 1120 : l=(dl and 15):d%(ct)=d:l%(ct)=l:ct=ct+1
 1130 : printtab(t1+c*10)d;tab(t2+c*10)l
 1140 : dl%(i)=dl
 1150 :next i
 1160 next c
 1170 return
 1180 :

; Select the SCSI device address / LUN from the menu.

 1190 p=1
 1200 print"{down}  use the cursor keys to select drive  "
 1210 print"  to format - press return to continue "
 1220 xp$="{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}":yp$="{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}"
 1230 xp=int((p-1)/14):yp=p-(xp*14):xp=xp*10+8
 1240 print"{home}{down}{down}{down}{down}{down}";
 1250 printleft$(xp$,xp);
 1260 printleft$(yp$,yp);
 1270 print"_";
 1280 getk$:ifk$<>chr$(13)andk$<>"{down}"andk$<>"{up}"andk$<>"{left}"andk$<>"{rght}"then1280
 1290 ifk$="{down}"andp<56thenifd%(p+1)<>255thenp=p+1
 1300 ifk$="{up}"andp>1thenifd%(p-1)<>255thenp=p-1
 1310 ifk$="{rght}"andp<43thenifd%(p+14)<>255thenp=p+14
 1320 ifk$="{left}"andp>14thenifd%(p-14)<>255thenp=p-14
 1330 ifk$=chr$(13)thend=d%(p):l=l%(p):goto1360
 1340 print"{left} ";:rem d & l
 1350 goto1230

; SCSI device selected, continue...

 1360 gosub2200: rem reset scsi controller
 1370 :
 1380 print"{home}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}";
 1390 : dl=d*16+l
 1400 : for i=0to55
 1410 :  if dl%(i)=dl then fl=1
 1420 : next
 1430 : if fl=0then print"{clr}{rvon}error:{rvof} specified dev/lun not present!":goto 2840
 1440 :
 1450 : dv=td:sd=d:sl=l:sb=16384
 1460 : sc$="00 00 00 00 00 00"
 1470 : gosub2310:ifss=2thengosub2310: rem ss=2: sense data in buffer
 1480 : ifss<>0thenprint"{clr}{rvon}error:{rvof} scsi drive not ready!":goto 2840
 1490 :

; WARNING:
; Formatting will destroy all data on the specified drive.

 1500 print"{rvon}warning:{rvof} formatting will destroy      "
 1510 print"all data on the specified drive.       "
 1520 input"continue (y/n)";yn$
 1530 ifyn$="y"then1550
 1540 ifyn$<>"Y"then2840

; WARNING:
; Format scsi device xx lun yy ?

 1550 print"{up}{up}{up}                                       "
 1560 print"format scsi dev"d"{left} lun"l"{left}            "
 1570 input"are you sure (y/n)";yn$
 1580 ifyn$="y"then1610
 1590 ifyn$<>"Y"then2840
 1600 :

; Start format medium.

 1610 print"{up}{up}{up}{rvon}formatting...{rvof} please wait              "
 1620 print"                                       "
 1630 print"                                       "
 1640 print"                                       ":print"{up}{up}{up}";
 1650 :

; Erease SCSI data-out buffer
; The data-out buffer includes a defect list for the current medium.
; The "s-c" command will use the RAM at $4000 as data-out buffer.
; The "m-w" command will clear the data-out buffer.

 1660 print#15,"m-w"+chr$(al)+chr$(ah)+chr$(4)+chr$(0)+chr$(0)+chr$(0)+chr$(0)

; FORMAT UNIT command
; The FORMAT UNIT command requests that the device server format the
; medium into application client accessible logical blocks as specified
; in the number of blocks and block length values received in the last
; mode parameter block descriptor in a MODE SELECT command.
; In addition, the device server may certify the medium and create
; control structures for the management of the medium and defects.
;
; Format: 04 18 00 00 01 00
; $04 : FORMAT command
; $18 :
;       $1x : A FMTDATA bit set to "1" specifies that the FORMAT UNIT
;             parameter list shall be transferred from the data-out
;             buffer. The parameter list consists of a parameter list
;             header, followed by an optional initialization pattern
;             descriptor, followed by an optional defect list.
;       $x8 : A CMPLST bit set to one specifies that the defect list
;             included in the FORMAT UNIT parameter list is a complete
;             list of defects. Any existing GLIST shall be discarded
;             by the device server. As a result, the device server shall
;             construct a new GLIST that contains:
;             a) the DLIST, if it is sent by the application client; and
;             b) the CLIST, if certification is enabled (i.e., the
;                device server may add any defects it detects during the
;                format operation).
; $00 : Vendor specific
; $00 : Reserved
; $01 : The fast format (FFMT) field
;       $00 : The device server initializes the medium as specified in
;             the CDB and parameter list before completing the format
;             operation.
;             After successful completion of the format operation, read
;             commands and verify commands are processed as described
;             in SBC-4.
;       $01 : The device server initializes the medium without
;             overwriting the medium (i.e., resources for managing
;             medium access are initialized and the medium is not
;             written) before completing the format operation.
;             After successful completion of the format operation, read
;             commands and verify commands are processed as described
;             in SBC-4.
;             If the device server determines that the options specified
;             in this FORMAT UNIT command are incompatible with the read
;             command and verify command requirements described in
;             SBC-4, then the device server shall not perform the format
;             operation and shall terminate the FORMAT UNIT command with
;             CHECK CONDITION status with the sense key set to ILLEGAL
;             REQUEST and the additional sense code set to INVALID FAST
;             FORMAT COMBINATION.
; $00 : Control
;
; Note: In some rare case format will not work with FFMT set to "1".
; When set FFMT to "0" format may take some time to complete (no fast
; format) but on some medium this seem to be necessary (as seen on a
; 1Gb JAZ disk drive).

 1670 sc$="04 18 00 00 01 00"
 1680 gosub2510: rem send format command
 1690 if ss<>0then 2830: rem error / exit
 1700 :
 1710 print"{clr}format complete."
 1720 :
 1722 gosub2200: rem reset scsi controller

; READ CAPACITY command
; The READ CAPACITY command requests that the device server transfer
; 8 bytes of parameter data describing the capacity and medium format
; of the direct-access block device to the data-in buffer.

 1730 sc$="25 00 00 00 00 00 00 00 00 00"
 1740 gosub2510:ifss<>0then 2830: rem error/exit

; READ CAPACITY data
; Byte #0-3 include LBA in MSB...LSB format.
; Only byte #1 to #3 are used here.

 1750 print#15,"m-r"+chr$(al+1)+chr$(ah)+chr$(3)
 1760 get#15,bh$,bm$,bl$

; Calculate block count:
; nb: Number of blocks on the medium.

 1770 nb=asc(bh$+chr$(0))*65536+asc(bm$+chr$(0))*256+asc(bl$+chr$(0))+1
  :
 1790 :

; Verify blocks on the medium.

 1800 print"verifying format - please wait":print
 1810 print"bad blocks: 0      remapped: 0"

; bc: block count
; bf: FAILED blocks
; br: REMAPPED blocks
; vl: VERIFICATION length

 1820 bc=nb:bf=0:br=0:of=0
 1830 vl=65535
 1840 if vl>bc then vl=bc

; VERIFY command
; The VERIFY command requests that the device server verify the
; specified logical block(s) on the medium.
; Each logical block includes user data and may include protection
; information, based on the VRPROTECT field and the medium format.

; B02-B05: LBA offset address to start VERIFY
; B07-B08: VERIFICATION LENGTH 1-65535 blocks

 1850 : sc$="2f 00 00"
 1860 : gosub2400: rem ascii -> bytes.

; LOGICAL BLOCK ADDRESS
; Note: 4-Byte value
;       Byte #1 is part of sc$ above
;       chr$(0)= GROUP NUMBER (always zero)

 1870 : bn=of:gosub2780
 1880 : ss$=ss$+chr$(bh)+chr$(bm)+chr$(bl)+chr$(0)

; VERIFICATION LENGTH
; Note: 2-Byte value
;       chr$(0) is the CONTROL byte

 1890 : bn=vl:gosub2780
 1900 : ss$=ss$+chr$(bm)+chr$(bl)+chr$(0)

 1910 : gosub2320:gosub2520
 1920 : if ss=0 then 2060

; BAD BLOCK
; bb = LBA of bad block in MSB..LSB format

 1930 :  bb=rs(4)*65536+rs(5)*256+rs(6)

; SENSE KEY
; Only bit %0 to %4 are used, bit %5 to %7 are reserved
; SENSE CODE:
; $01 = RECOVERED error -> reassign bad block
; $09 = VENDOR SPECIFIC -> continue
; $03 = MEDIUM error    -> reassign bad block
; $xx = ERROR           -> error / exit

 1940 :  if(rs(2)and15)=1then 1960
 1942 :  if((rs(2)and15)=9)and(rs(12)=128)then2040
 1950 :  if(rs(2)and15)<>3then 2830: rem error / exit

; Create list of BAD BLOCK for REASSIGN BLOCKS command

 1960 :  dl$=chr$(0)+chr$(0)+chr$(0)+chr$(4)
 1970 :  dl$=dl$+chr$(rs(3))+chr$(rs(4))+chr$(rs(5))+chr$(rs(6))

; Display BAD BLOCK

 1980 :  gosub2660:bf=bf+1:print"{up}{up}"tab(11)bf:print"{up}";
 1990 :  print#15,"m-w"+chr$(al)+chr$(ah)+chr$(8)+dl$

; REASSIGN BLOCKS command
; The REASSIGN BLOCKS command requests that the device server reassign
; defective logical blocks to another area on the medium set aside for
; this purpose. The device server should also record the location of
; the defective logical blocks in the GLIST, if supported.

 2000 :  sc$="07 00 00 00 00 00"
 2010 :  gosub 2510:ifss<>0then 2830: rem error / exit

; BLOCK REMAPPED

 2020 :  br=br+1:printtab(28)br:print"                                       "
 2030 :  print"{up}";

; Calculate remaining blocks for VERIFY after an ERROR occured

 2040 :  bc=bc-(bb-of):of=bb:goto 1830
 2050 :

; Calculate remaining blocks for VERIFY

 2060 : bc=bc-vl:of=of+vl
 2070 if bc>0 then 1830

; FORMAT / VERIFY done

 2080 print"{down}{down}{down}{down}{down}format successful                      ":print:goto2840
 2090 :
 2100 :

; RESET CMD HD controller device

 2200 co=130 :rem $82 = Controller reset?
 2210 ec=2   :rem max 2 retries

; Write job address
; Note: bl/bh should be $00 at this point

 2220 print#15,"m-w"+chr$(08)chr$(00)chr$(2)chr$(bh)chr$(bl)

; Write job code
; Note: Using JOB code $82 for CONTROLLER RESET to check for
;       a CMD HD device.

 2230 print#15,"m-w"+chr$(00)chr$(00)chr$(1)chr$(co)

; Read job queue ERROR code
; 0/1 = OK
; >=2 = ERROR

 2240 print#15,"m-r"+chr$(00)chr$(00)chr$(1)
 2250 get#15,a$:ifa$=""thena$=chr$(0)
 2260 ifa$>chr$(127)then 2240
 2270 ifa$<chr$(2)  then return
 2280 ec=ec-1:ifec>0then 2230
 2290 print"disk error"asc(a$)"{left}                 ":goto 2840
 2300 :

; Send CMD-HD SCSI command / ASCII format
; Convert SCSI command from ASCIi to binary and send the
; command to the CMD-HD.
; Return:    ss=133 / Device "sd" not available

 2310 gosub2400: rem ascii -> bytes.
 2320 ah=int(sb/256):al=sb-ah*256
 2330 gosub2350:ifss=2 then gosub2350: rem ss=2: sense data in buffer
 2340 return

; Send CMD-HD SCSI command / Binary format
; Parameter: sd  = SCSI device address
;            al  = SCSI data buffer low address
;            ah  = SCSI data buffer high address
;            ss$ = SCSI command bytes
; Return:    ss  = SCSI SENSE / error code

 2350 print#15,"s-c"+chr$(sd)+chr$(al)+chr$(ah)+ss$
 2360 get#15,sa$,sb$:ss=asc(sa$+chr$(0))
 2370 return
 2380 :
 2390 :

; Convert SCSI command from ASCII into byte values
; Parameter: sc$ = SCSI-Command as ASCII string "00 11 22..."
; Return:    ss$ = SCSI-Command as byte values

 2400 ss$=""
 2410 for i=1 to len(sc$) step3
 2420 : hv%=asc(mid$(sc$,i,1))-55:ifhv%<10thenhv%=hv%+7
 2430 hv%=hv%*16
 2440 : hl%=asc(mid$(sc$,i+1,1))-55:ifhl%<10thenhl%=hl%+7
 2450 : if i=4 then hv%=(hv%and31)or(sl*32)
 2460 : ss$=ss$+chr$(hv%+hl%)
 2470 next
 2480 return
 2490 :
 2500 :

; SEND SCSI COMMAND
; Parameter: sc$ = SCSI-Command

 2510 gosub2310
 2520 ifss=0 then return
 
; REQUEST SENSE command
; The REQUEST SENSE command requests that the device server transfer
; sense data to the application client.
; B00: RESPONSE CODE (70h or 71h)
; B02: SENSE KEY
; B12: ADDITIONAL SENSE-CODE

 2530 sc$="03 00 00 00 1b 00"
 2540 gosub2310

; Read sense data (27Bytes + NULL)

 2550 print#15,"m-r"+chr$(al)+chr$(ah)+chr$(27)
 2560 fori=0to27:get#15,a$:rs(i)=asc(a$+chr$(0)):next
 2570 ss=2:return: rem ss=2: sense data in buffer
 2580 :
 2590 :
 2600 :

; Display SCSI error
; Parameter: rs(x) = 27 bytes of error data.

 2610 ec=rs(0) :gosub2730:ec$=eh$: rem response code
 2620 ec=rs(2) :gosub2730:ek$=eh$: rem sense key
 2630 ec=rs(12):gosub2730:es$=eh$: rem additional sense key
 2640 print"scsi error: "ec$" "ek$" "es$
 2650 if rs(0)<127 then 2710

; Display extended error information
; B03-B06: INFORMATION, the unsigned LOGICAL BLOCK ADDRESS associated
;          with the sense key, for:
;           -> direct-access devices (device type 0),
;           -> write-once devices (device type 4),
;           -> CD-ROM devices (device type 5),
;           -> optical memory devices (device type 7);

 2660 eb$=""
 2670 fori=3to6
 2680 ec=rs(i):gosub2730:eb$=eb$+eh$
 2690 next
 2700 print"block address: "eb$
 2710 return
 2720 :

; Convert Byte into HEX/ASCII
; Parameter: ec  = Zahlenwert
; Return:   eh$ = HEX-Byte als ASCII-Text "FF"

 2730 eh=int(ec/16)
 2740 ez=ec-(eh*16)
 2750 eh$=mid$(h$,eh+1,1)+mid$(h$,ez+1,1)
 2760 return
 2770 :

; LOGICAL BLOCK ADDRESS
; Convert LBA to hi/mid/lo bytes
; Parameter: bn = LBA
; Return:    bh/bm/bl = LBA als 3-Byte-Adresse

 2780 bh=int(bn/65536)
 2790 bm=int((bn-(bh*65536))/256)
 2800 bl=bn-(bh*65536+bm*256)
 2810 return
 2820 :

; Display error status and exit program

 2830 gosub 2610
 2840 close 15
 2870 end

; Display note about setting CMD-HD into installation mode

 2880 :
 2890 print"{clr}"
 2900 print"{cyn}         llformat "vn$
 2910 print"{down}{wht}   before continuing you should place"
 2920 print"    your hd into installation mode."
 2930 print"{down}   1. press and hold down the swap 8"
 2940 print"      and swap 9 switches."
 2950 print"{down}   2. while holding down the swap 8 and"
 2960 print"      swap 9 switches, press the reset"
 2970 print"      switch once and release it."
 2980 print"{down}   3. continue to hold down the swap 8"
 2990 print"      and swap 9 switches until the"
 3000 print"      activity led's stay off."
 3010 print"{down}   4. release the swap 8 and swap 9
 3020 print"      switches.
 3030 print"{down}      press <return> to continue"
 3040 getk$:ifk$<>chr$(13)then3040
 3050 return
