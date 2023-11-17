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
; 00500.variables-generic.bas - define generic program variables
;
; Note: BASIC lines commented out include variables
;       that will be initialized later.
;       To reduce programm code skip initialization.
;
; Note: Reserved variable names for C128:
;       er, el, ds, ds$
;

; pd$(): Partition types
500 dimpd$(9)
501 pd$(0)="empty"
502 pd$(1)="native":pd$(2)="1541":pd$(3)="1571":pd$(4)="1581"
503 pd$(5)="1581 cp/m":pd$(6)="prntbuf":pd$(7)="foreign"
504 pd$(8)="system":pd$(9)="unknown"

; ga   : Load address sub-modules
; es   : error status
; dv   : Current CMD-HD device address
; dd   : Selected CMD-HD device
600 ga=peek(186):es=0:dv=0:dd=0

; hd() : List of available CMD-HD devices
; hc   : Count of CMD-HD devices
; hd   : CMD-HD in configuration mode
610 dim hd(30):hc=0:hd=30

; h1   : CMD-HD default address
; h2   : CMD-HD swap-mode 0/8/9
; h3   : CMD-HD changed device address using u0>x
;620 h1=0:h2=0:h3=0

; sd   : CMD-HD SCSI device address
; sx   : Backup SCSI device address
;630 sd=5:sx=0

; sb   : CMD-HD internal SCSI buffer $4000
; sl/sh: CMD-HD internal SCSI buffer high/low-byte
700 sb=16384:sh=int(sb/256):sl=sb-sh*256

; sc$  : SCSI command string
;710 sc$=""

; h/m/l: hi/mid/low byte of LBA
;720 bh=0:bm=0:bl=0
;721 rh=0:rm=0:rl=0
;722 wh=0:wm=0:wl=0

; ba   : SCSI block address
;730 ba=0




; si() : SCSI device type
; sm() : SCSI removable media
; sv$(): SCSI vendor identification
; sp$(): SCSI product identification
; sr$(): SCSI revision level
800 dim si(6),sm(6),sv$(6),sp$(6),sr$(6)

; bu() : SCSI block data buffer
; ec() : SCSI sense data
810 dim bu(512),ec(28)




; NULL-byte
990 nu$=chr$(0)
