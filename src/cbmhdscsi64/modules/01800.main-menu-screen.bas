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
; 01800.main-menu-screen.bas - print main menu screen
;

; Print main menu
1800 print"{home}{down}"
1810 print" main menu:         ";chr$(95);" exit program{down}"

1820 print" * device           * format"
1821 print"   f1 find cmd-hd     l sysfile device"
1822 print"   f3 select cmd-hd   c check sysfiles"
1823 print"   f5 select scsi-id  f auto-format"
1824 print"   f7 change device   i initialize disk"
1825 print"   f8 eject media     m  +format disk"
1826 print"                      v  +verify disk"
1827 print" * partition ";ap$;"   s  +system area"
1828 print"   $ partition list   o  +main o.s."
1829 print"   a auto on/off      t  +part. table"
1830 print"   + part nr. +1      e erase disk"
1831 print"   * part nr. +10"
1832 print"   1 find free part * defaults"
1833 print"   4  +1541           d device address"
1834 print"   7  +1571           p partition"
1835 print"   8  +1581"
1836 print"   n  +native ";am$;"  * manage cmd-hd"
1837 print"   0  +foreign ";am$;"   k enable config"
1838 print"   r remove part      h park hdd"


; Create system status
1850 sz$=po$+"{rvon} "
1851 sz$=sz$+"hd:"+mid$(str$(dd),2)+":"+chr$(48+sd)+" "
1852 sz$=sz$+"- l:"+mid$(str$(ga),2)+" "

; Partition table analyzed?
1860 ifpf<0thengoto1880

; Add next free partition
1861 sz$=sz$+"- p:"+mid$(str$(pf),2)+" "

; Add remaining free blocks
1862 sz$=sz$+"- f:"+mid$(str$(br*2),2)

1880 printleft$(sz$+sp$+sp$+sp$+sp$,39+24+2);"{rvof}{home}";
1890 return
