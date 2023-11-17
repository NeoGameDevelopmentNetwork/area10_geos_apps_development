; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; hdPartInit
;
; 01800.main-menu-screen.bas - print main menu screen
;

; Print main menu
1800 print"{home}{down}"
1810 print" main menu:         ";chr$(95);" exit program{down}"

1820 print" * device           * edit partitions"
1821 print"   f1 find cmd-hd     l load config"
1822 print"   f3 select cmd-hd   s save config"
1823 print"   f5 select scsi-id  c clear data"
1824 print"   f6 show partitions p show data"
1825 print"   f7 change device   v validate data"
1826 print"   f8 eject media     w write p.table"
1827 print"                      d config device"
1828 print"                      $ list ini files"
1829 print" * create ";ap$;"      e edit filename"
1830 print"   4  +1541           ";left$(cf$,16)
1831 print"   7  +1571"
1832 print"   8  +1581         * partition data"
1833 print"   n  +native ";am$;"    i import from hd"
1834 print"   0  +foreign ";am$;"   + part nr. +1"
1835 print"   m  +1581 cp/m      * part nr. +10"
1836 print"   b  +printbuf       f find free part"
1837 print"   a auto on/off      r remove part"
1838 print""


; Create system status
1850 sz$=po$+"{rvon} "
1851 sz$=sz$+"hd:"+mid$(str$(dd),2)+":"+chr$(48+sd)+" "
1852 sz$=sz$+"- l:"+mid$(str$(ga),2)+" "

; Partition table analyzed?
1860 ifpf<0thengosub30300

; Add next free partition
1861 sz$=sz$+"- p:"+mid$(str$(pf),2)+" "

; System area analyzed?
1870 if(so<0)or(tb<=0)thengoto1880

; Add remaining free blocks
1871 sz$=sz$+"- f:"+mid$(str$(br*2),2)

1880 printleft$(sz$+sp$+sp$+sp$+sp$,39+24+2);"{rvof}{home}";
1890 return
