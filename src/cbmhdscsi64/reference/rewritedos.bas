; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; rewritedos.bas - Written by C.M.D.
; Version: V1.10
;
; A tool for C64/C128 which can be used to
; write a new hddos/geos-os on the CMD-HD.
;
; Additional comments by Markus Kanet
; Version: V1.00 02/16/2020
;

; Check fpr C64/C128 and set create sys flag.

  100 l=l+1:ifl=1thenf=abs(peek(65533)=255):poke251,cs:rem create sys flag
  101 ifl<>1then180: rem restart after loading system file.
  102 :

  103 iff=1then120: rem c128

; C64: Set beginning of free string memory to $1600.

  104 ifcs<>0thenpoke45,peek(174):poke46,peek(175)
  110 clr:poke51,00:poke55,00:poke52,22:poke56,22:l=1:f=0
  112 :

; Get current device address for loading additional files.
; Write computer type to $00FA for the assembler part of the
; 'CREATE.SYS' utility (see 'CREATESYS.ASS').
; dl = device address
; ha = Internal buffer for system files

; Define location of the internal buffer.
; ta = $2000(C64) / $4000(C128)

  120 dl=peek(186):poke250,f:ha=5632:ta=2*4096:iff=1thenta=4*4096

; Get create sys flag.

  130 cs=peek(251)

; Define system call for the assembler part of 'REWRITE DOS'.

  140 iff=0thenml=peek(46)*256+peek(45)-147
  150 iff=1thenml=peek(4625)*256+peek(4624)-147

; Load system header into internal buffer at $1600.

  160 iff=0thenload"system header",dl,1
  170 iff=1thenbank15:bload"system header",u(dl):l=l+1
  172 :

; Load HDDOS into internal buffer at $2000.

  180 ifl=2andf=0thenload"hdos v?.??",dl,1
  190 ifl=2andf=1thenbload"hdos v?.??",u(dl),p(ta):l=l+1

  200 ifl=3then230: rem write system header and hddos.
  210 ifl=4then510: rem write geos/os.
  220 :

; C128: Set RAM-bank.

  230 iff=1thenbank15

; De-activate CMD-HD parallel cable.

  240 ifpeek(57513)=120then@p0

; Initialize CMD-HD.

  250 td=30:open15,td,15:print
  260 oi=0:gosub 870: rem test checksum system header
  270 :

; Do not display warning when using create sys.

  280 ifcs=1then440:rem create sys flag
  290 :

; Display note about setting CMD-HD into configuration mode

  300 print"{clr}{down}rewrite dos v1.10"
  310 print"{down}this program installs a new hd-dos and"
  320 print"geos/hd driver onto your hd without"
  330 print"destroying any data on the drive."
  340 print"{down}important: this program must be run"
  350 print"from a floppy disk that contains the"
  360 print"files 'system header' 'hdos v?.??' and"
  370 print"'geos/hd v?.??'."
  380 print"{down}to continue, hold down 'write protect',"
  390 print"while you press and release 'reset'."
  400 print"{down}then, clear write protect (if necessary)"
  410 print"and press <return> to rewrite dos"
  420 geta$:ifa$<>chr$(13)then420
  430 :

; Write system header and HDDOS.

  440 lb=00:hb=ha/256:print:print
  450 bl=4:bh=0:bc=1:print"writing system header":print:gosub600
  460 :

; Test checksum and write HDDOS to disk.

  470 oi=00:gosub870:lb=00:hb=ta/256:print:print"writing main o.s.":gosub580

; Load GEOS/OS into internal buffer at $2000.

  480 iff=0thenload "geos/hd v?.??",dl,1
  490 iff=1thenbload "geos/hd v?.??",u(dl),p(ta)
  500 :

; Write GEOS/OS.
; Test checksum and write GEOS/OS to disk.

  510 oi=64:gosub870:print:print"writing geos o.s.":gosub580
  520 print:print"press reset on hd to reboot dos"

; Re-activate CMD-HD parallel cable.

  530 clr:ifpeek(57513)=120then@p1

; Close command channel.

  540 close15

; End of program.

  550 end
  560 :
  570 :

; Write system file to disk.
; HDDOS  : oi=0  : bc=$6c: bl/bh = system area address (00:0Exx)
; GEOS/OS: oi=64 : bc=$02: bl/bh = system area address (00:7Exx)

  580 print:bl=peek(ha+oi+3):bh=peek(ha+oi+2):bc=peek(ha+oi+1):gosub 600:return
  590 :

; Set $FB/$FC to internal buffer for system data.
; SYSTEM : $1600 -> system area address (00:0400)
; HDDOS  : $2000 -> system area address (00:0E00)
; GEOS/OS: $2000 -> system area address (00:7E00)

  600 poke 251,lb: poke 252,hb:print

; co: 144/$90 Job command "Write logical block"
; td: CMD-HD device address in configuration mode

  610 co=144
  620 poke 186,td
  630 :

; Send 256 bytes to HD ram buffer and write sektor to disk.

  640 for i=1 to bc
  650 :
  660 for j=1 to 8: rem send 8x32 bytes to cmd-hd ram
  670 sys ml+3: rem send 32 bytes to cmd-hd at $0300
  680 next j
  690 :
  700 gosub 770: rem write 256 bytes to medium

; Set pointer to next block on disk.

  710 bl=bl+1:ifbl=256thenbl=0:bh=bh+1
  720 :

; Continue with next block.

  730 print"{up}"i:next i
  740 return
  750 :
  760 :

; Write logical block to disk
; CMD-HD address: $0000 = Job queue
;                 $0008/$0009 = Job track and sector
;                 $0300 = Job queue buffer
; Parameter: bh = block address HIGH
;            bl = block address LOW
;            co = Job command

  770 ec=10: max 10 retries.

; Write job address -> $0008
; bl/bh = $0400 -> system header
;       = $0E00 -> HDDOS
;       = $7E00 -> GEOS/OS
  780 print#15,"m-w"+chr$(08)chr$(00)chr$(2)chr$(bh)chr$(bl)

; Write job command -> $0000

  790 print#15,"m-w"+chr$(00)chr$(00)chr$(1)chr$(co)

; Read job status byte

  800 print#15,"m-r"+chr$(00)chr$(00)chr$(1)
  810 get#15,a$:ifa$=""thena$=chr$(0)

; Job still in progress?
; >127 = TRUE, wait...

  820 ifa$>chr$(127)then 800

; Job successful?
; 0/1 = TRUE, done.

  830 ifa$<chr$(2)  then return

; Job error... retry multiple times.
; If error still occures, exit program.

  840 ec=ec-1:ifec>0then 790
  850 print"write error"asc(a$):close15:end
  860 :

; Test checksum for system file.

  870 sys ml :ifpeek(251)<>peek(ha+oi+5)then 890
  880 ifpeek(252)=peek(ha+oi+4)then return
  890 print"{down}checksum error!"
  900 print"the 'hdos' and/or 'geos/hd' files may"
  910 print"be corrupt, or you may be using"
  920 print"an outdated 'system header' file."
  930 close15:end
