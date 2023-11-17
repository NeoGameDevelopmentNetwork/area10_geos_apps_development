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
; 54000.format-sysarea.bas - create system area
;                         (don not include writing the system files)
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

; Set default device address
54000 dv=h1

; Wait for media
54020 gosub50700
54030 ifes>2thenreturn

; Get initialization data.
54060 printtt$;left$(po$,18);

; Open command channel
54062 open15,dv,15

; SCSI read capacity
54063 gosub59450
54064 close15

; Count of total blocks on medium for hardware table.
54070 nh=bh:nm=bm:nl=bl


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

; Get offset for system area
; Default = 384 blocks x 512 bytes = $03:0000
54100 so=384

; Check for autoformat
54105 ifmk$<>af$thengoto54110
54106 printleft$(po$,4);
54107 print"  initializing disk, please wait...{down}{down}"

; Wait a second...
54108 gosub51800
; Skip starting address and clear area below system
54109 goto54300

; Set starting address
54110 printleft$(po$,4);
54111 print"  select system startiing address:{down}"
54112 print"  note: default starting address is 384"
54113 print"        change value at own risk!"

; Define hi/mid/low byte
54120 oh=int(so*512/65536)
54121 om=int((so*512-oh*65536)/256)
54122 ol=so*512-oh*65536-om*256

; Print current starting address
54130 printleft$(po$,9);
54131 print"  system starting address = ";
54132 by=oh:gosub60200:print"$";he$;":";
54133 by=om:gosub60200:printhe$;
54134 by=ol:gosub60200:printhe$
54135 print"  (";int(so*512/1024);"{left}kb reserved memory )  {down}"

54140 print"  use +/- to adjust starting address"
; "Press <return> to continue."
54141 gosub9010

; Wait for a key
54150 getk$:ifk$=""thengoto54150
; Set offset +64k
54151 ifk$="+"thenso=so+128
; Set offset -64k
54152 ifk$="-"thenso=so-128
54153 ifso<0thenso=0
; Test for max. 32640 blocks
54154 ifint(so/(65536/512))>255thenso=0
54155 if(so>tb-2048)thenso=0
54156 ifk$<>chr$(13)thengoto54120

; Clear area below system block?
54200 ifso=0thengoto54300

54210 printtt$
54211 print"  clear area below system:{down}"
54212 print"  warning! some devices may use this"
54213 print"  area for system data.{down}"
54214 print"  skip this step if you share the"
54215 print"  cmd-hd with other computer types.{down}"
54216 print"  if unsure say 'n'."
54217 print"  clear reserved area (y/n)? ";

; Wait for a key
54220 getk$:if(k$<>"y")and(k$<>"n")thengoto54220
54221 printk$:ifk$="n"thengoto54300

54230 print"{down}  clearing area below system"

; Open command channel
54240 open15,dv,15
; Clear SCSI block data buffer
54241 gosub58800
; Send block data buffer to CMD-HD
54242 gosub58000
54243 print
54250 forba=0toso-1
54251     print"{up}  blocks left:";(so-ba)-1;"{left}   "
; Convert LBA to h/m/l
54252     gosub58900:wh=bh:wm=bm:wl=bl
; Write block to disk
54254     gosub58300:ifes>0thenba=so
54256 next
54257 close15

; Disk error?
54258 ifes=0thengoto54300

; "Disk error"
54275 print"{down}  clear system area failed!"
54276 gosub9200
; Wait for return
54277 gosub60400

; Close command channel
54280 close15

; Done
54290 return

; Create new system header
54300 ifso>0thengoto54310
54301 printtt$

; Clear SCSI block data buffer
54310 gosub58800
54311 print"{down}  writing hardware table"

; If current device address of the CMD-HD is #30
; for configuration mode use adresse #12 as default
; address for the hardware table.
54315 hx=h1:ifhx=30thenhx=12

; Initialize scsi device table
; Hardware table is in sector 386 from byte $0100 - $01FF.

; SCSI-ID as high/low nibble, LUN always $0.
54320 bu(256)=sd*16
54321 fori=1to55
54322     bu(256+i)=255
54323 next

; Initialize start lba for next device
; Note: First device begins at $00:0000.
54330 bu(256+56+1)=nh
54331 bu(256+56+56+1)=nm
54332 bu(256+56+56+56+1)=nl

; Initialize start lba for other devices
54335 fori=2to55
54336     bu(256+i+56)=255
54337     bu(256+i+56+56)=255
54338     bu(256+i+56+56+56)=255
54339 next

; Initialize system data
;   $xx:05e0 = unknown
;54340 bu(256+224)=0
;   $xx:05e1 = default address
54341 bu(256+225)=hx
;   $xx:05e2 = default partition
54342 bu(256+226)=1
;   $xx:05e3 = default partition ?
54343 bu(256+227)=1
;   $xx:05e4 = default address or swap8/9 mode
54344 bu(256+228)=hx
;   $xx:05e5 = unknown
54345 bu(256+229)=128
;   $xx:05e6 = unknown
54346 bu(256+230)=1
;   $xx:05e7 = unknown
;54347 bu(256+231)=0

;   $xx:05e8 = unknown
;54350 bu(256+232)=0
;   $xx:05e9 = unknown
;54351 bu(256+233)=0
;   $xx:05ea = unknown
;54352 bu(256+234)=0
;   $xx:05eb = unknown
;54353 bu(256+235)=0
;   $xx:05ec = unknown
;54354 bu(256+236)=0
;   $xx:05ed = unknown
;54355 bu(256+237)=0
;   $xx:05ee = unknown
;54356 bu(256+238)=0
;   $xx:05ef = unknown
;54357 bu(256+239)=0

; CMD-HD detection code used by 3rd-party
; applications to find the system area.
; 54360 bu(256+240)=asc("c")
; 54361 bu(256+241)=asc("m")
; 54362 bu(256+242)=asc("d")
; 54363 bu(256+243)=asc(" ")
; 54364 bu(256+244)=asc("h")
; 54365 bu(256+245)=asc("d")
; 54366 bu(256+246)=asc(" ")
; 54367 bu(256+247)=asc(" ")
; This following code is shorter then the code above...
54360 fori=0to7
54361     bu(256+240+i)=asc(mid$("cmd hd  ",1+i,1))
54362 next

; Some additional data bytes/program code
; used for CMD-HD detection.
;   $f8 = sta $8803
;   $fb = stx $8802
;   $fe = nop
;   $ff = rts
54370 bu(256+248)=141
54371 bu(256+249)=3
54372 bu(256+250)=136
54373 bu(256+251)=142
54374 bu(256+252)=2
54375 bu(256+253)=136
54376 bu(256+254)=234
54377 bu(256+255)=96

; Open command channel
54380 open15,dv,15

; Send buffer to CMD-HD
54381 gosub58000

; Convert LBA to h/m/l
54382 ba=so+2:gosub58900:wh=bh:wm=bm:wl=bl

; Write block to disk
54384 gosub58300

; Close command channel
54385 close15

; Error occured?
54386 ifes>0thengoto54275

; Check for autoformat
54387 ifmk$=af$thengoto54390

; "Done"
54388 print:gosub9000
; Wait for return
54389 gosub60400
54390 return
