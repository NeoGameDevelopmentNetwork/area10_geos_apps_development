; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 20000.copy-partition.bas - copy partition
;
; parameter: dd    = cmd-hd device address
;            hs    = source scsi device
;            cs    = source partition number
;            fs    = source partition format mode
;            s0    = source partition start address
;            s1    = source partition size in 512-byte blocks
;            ht    = target scsi device
;            ct    = target partition number
;            ft    = target partition format mode
;            t0    = target partition start address
;            t1    = target partition size in 512-byte blocks
; return   : -
; temporary: as,ap,at,sd,so,k$,bc,b0,b1,bs,ba,by,bh,bm,bl
;            he$,rh$,rm$,rl$,wh$,wm$,wl$,rh,rm,rl,wh,wm,wl
;

; Copy partition
20000 ifcs<1orct<1thengoto20900

; Check for valid partitions
20010 iffs<>ftthengoto20910
20011 if((fs<>1)and(s1<>t1))or((fs=1)and(s1>t1))thengoto20920
20012 if(hs=ht)and(s0=t0)thengoto20940

; Last warning
20030 printleft$(po$,15);"{right}";sl$
20031 print"{up}{right}{right}are you really sure (y/n) ?";
20032 getk$:ifk$=""thengoto20032
20033 if(k$<>"y")and(k$<>"Y")thengoto20990

; Clear status message
20040 printleft$(po$,15);"{right}";sl$
20041 print"{up}{right}{right}copying partition...";
20042 printleft$(po$,15);left$(ta$,37);




; Get active SCSI ID
20050 gosub50900:as=sd

; Get active partition type/number
20060 open15,dv,15:print#15,"g-p":get#15,a$,b$,b$:close15
20061 at=asc(a$+chr$(0)):ap=0
20062 if(at>=0)and(at<=4)thenap=asc(b$+chr$(0))
20063 if(ap<1)or(ap>254)thenat=0:ap=0




; Initialize copy values
; bc = block count (512-byte blocks)
; b0 = start address source partition
; b1 = start address target partition
20090 bc=s1:b0=s0:b1=t0

; Test CMD-HD device
20100 open15,dv,15:close15:ifst<>0thenes=st:goto20930

; Open command channel
20110 open15,dv,15

; Update status message
20200 print"{left}{left}{left}{left}";right$("   "+str$(int((s1-bc)*100/s1)),3);"%";

; Define count of blocks to be copied
; 16 Blocks a 512 bytes = 8192 bytes = SCSI buffer size
20300 bs=16:ifbs>bcthenbs=bc

; Convert source LBA to h/m/l
20400 ba=b0:gosub58900

; Convert h/m/l to ASCII
20410 by=bh:gosub60200:rh$=he$
20420 by=bm:gosub60200:rm$=he$
20430 by=bl:gosub60200:rl$=he$

; Convert block count LBA to h/m/l
20440 ba=bs:gosub58900
; Only low-byte required
; max. 16 blocks x 512 bytes = 8192 bytes (SCSI buffer size)
20450 by=bl:gosub60200

; Prepare "S-C" (read) command
; he$ = LBA block count
20490 he$="280000"+rh$+rm$+rl$+"0000"+he$+"00":gosub60100:sc$=by$
; Send SCSI command, exit on error
20491 sd=hs:gosub59800:ifes>0thengoto20700

; Convert source LBA to h/m/l
20500 ba=b1:gosub58900

; Convert h/m/l to ASCII
20510 by=bh:gosub60200:wh$=he$
20520 by=bm:gosub60200:wm$=he$
20530 by=bl:gosub60200:wl$=he$

; Convert block count LBA to h/m/l
20540 ba=bs:gosub58900
; Only low-byte required
; max. 16 blocks x 512 bytes = 8192 bytes (SCSI buffer size)
20550 by=bl:gosub60200


; Prepare "S-C" (write) command
; he$ = LBA block count
20590 he$="2a0000"+wh$+wm$+wl$+"0000"+he$+"00":gosub60100:sc$=by$

; Prepare "S-C" (write+verify) command
; he$ = LBA block count
;20590 he$="2e0000"+wh$+wm$+wl$+"0000"+he$+"00":gosub60100:sc$=by$

; Send SCSI command, exit on error
20591 sd=ht:gosub59800:ifes>0thengoto20700

; Update source LBA
20600 b0=b0+bs
; Update target LBA
20610 b1=b1+bs

; Update remaining LBA block counter
20620 bc=bc-bs:ifbc>0thengoto20200




; Close command channel
20700 close15
; Check for error
20701 ifes0thengoto20930

; Update process count
20710 print"{left}{left}{left}{left}100%";

; Do not initialize FOREIGN/DACC/PRNT mode partitions
20720 if(fs<1)or(fs>4)thengoto20800

; Do only initilize partition on the active SCSI device
20721 ifas<>htthengoto20800

; Do only initilize active partitions
20722 ifap<>ctthengoto20800

; Note: Unlike cbmHDscsi the partition table has not
;       been changed after copy a partition. There is
;       no need to update the partition table or to
;       reset the active partition.
; Reload partition table by activating SCSI device
; Note: Currently there will be no error status returned!
;20723 sd=ht:gosub52000:rem ifes>0thengoto20990

; Reset active partition
;20724 open15,dv,15:print#15,"cP"+chr$(ap):close15

; Reset device address
; Not needed since we test for bad configured CMD-HD devices
;20725 gosub50500




; Display update message...
20730 printleft$(po$,14):print"{right}";sl$;"{up}"
20731 print"{right}{right}updating disk/partition info..."




; Update partition size for native-mode
; Required if we copy a smaller partition to
; a larger partition: last available track must
; be fixed in the directory header.
20740 if(fs>1)or(s1=t1)thengoto20760

; Open command channel
20750 open15,dv,15
; Convert LBA to h/m/l
20751 ba=t0+1:gosub58900:rh=bh:rm=bm:rl=bl
; Read block from disk
20752 sd=ht:gosub58200:ifes>0thengoto20790
20753 ad=sb+8:hi=int(ad/256):lo=ad-hi*256
; Debug, read source partition size
;20754 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
;20755 get#15,a$:by=asc(a$+nu$):ifby<>(s1/128)thenstop
; Fix last available track on partition
20757 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(t1/128)
; Write block to disk
20758 wh=bh:wm=bm:wl=bl:gosub58300:ifes>0thengoto20790
; Close command channel
20759 close15



; Initialize the active partition to update
; the BAM in the CMD-HD buffer

; Open command channel
20760 open15,dv,15

; Change partition
20770 print#15,"cP"+chr$(ct)
20771 input#15,a$:es=val(a$):ifes>2thengoto20790

; Initialize partition
20780 print#15,"i:"
20781 input#15,a$:es=val(a$)

; Close command channel
20790 close15

; Wait a few seconds...
20791 gosub51800

; Test for errors
20795 ifes>0thengoto20930



; Copy completed
20800 printleft$(po$,14):print"{right}";sl$;"{up}"
20810 em$="copy completed!":goto20980


;        1234567890123456789012345678901234567890
;                               press <return>
20900 em$="select partitions!":goto20980
20910 em$="not compatible!":goto20980
20920 em$="different size!":goto20980
20930 em$="disk error!":goto20980
20940 em$="source=target!":rem goto20980

20980 printleft$(po$,14):print"{right}";sl$
20981 print"{up}{right}{right}";left$(em$+sp$+sp$+sp$+sp$,21);"press <return>"

; Wait for return
20982 gosub60400
20990 return

