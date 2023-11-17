; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

0 rem configuration tool for cmd-hd
1 vn$="cbmhdscsi64":vd$="(w)2020 by m.k.":vv$="v0.07"
10 sp$="          "
11 tt$=" "+vn$+" - "+vv$+" / "+vd$+sp$+sp$+sp$+sp$
12 tt$="{clr}{rvon}"+left$(tt$,39)+"{rvof}{down}{down}"
100 ts=162
110 af$="f":ap=1
120 dimpt(255)
200 so=-1
210 pl=-1
220 s0$="hdos v?.??"
221 s1$="geos/hd v?.??"
222 s2$="geoshd v?.??"
223 s3$="system header"
400 sl$=left$(sp$+sp$+sp$+sp$,39)
410 li$="":fori=0to38:li$=li$+"-":next
420 po$="{home}":fori=0to23:po$=po$+"{down}":next
430 ta$="":fori=0to38:ta$=ta$+"{right}":next
500 dimpd$(9)
501 pd$(0)="empty"
502 pd$(1)="native":pd$(2)="1541":pd$(3)="1571":pd$(4)="1581"
503 pd$(5)="1581 cp/m":pd$(6)="prntbuf":pd$(7)="foreign"
504 pd$(8)="system":pd$(9)="unknown"
600 ga=peek(186):es=0:dv=0:dd=0
610 dim hd(30):hc=0:hd=30
700 sb=16384:sh=int(sb/256):sl=sb-sh*256
800 dim si(6),sm(6),sv$(6),sp$(6),sr$(6)
810 dim bu(512),ec(28)
990 nu$=chr$(0)
1000 if(abs(peek(65533)=255)=0)thengoto1100
1010 key 1,chr$(133):key 3,chr$(134):key 5,chr$(135):key 7,chr$(136)
1011 key 8,chr$(140)
1020 goto1200
1100 poke53280,0:poke53281,0:poke646,5
1200 print"{clr}"
1210 rem ifpeek(57513)=120then: ::@p0:
1220 gosub10200:ifes<>0thenstop
1500 so=-1
1502 pf=-1:pl=-1
1505 es=0
1510 printtt$
1520 ifap<>0thenap$="<auto>":am$="16mb"
1521 ifap =0thenap$="      ":am$="    "
1530 gosub1800
1540 getmk$:ifmk$=""thengoto1540
1541 ifmk$=chr$(95)thengoto1790
1550 ifmk$=chr$(133)thengosub10200:goto1700
1551 ifmk$=chr$(134)thengosub10000:goto1700
1552 ifmk$=chr$(135)thengosub11000:goto1700
1553 ifmk$=chr$(136)thengosub12000:goto1700
1554 ifmk$=chr$(140)thengosub59600:goto1500
1560 ifmk$="l"thengosub10100:goto1505
1561 ifmk$="c"thengosub55000:goto1500
1562 ifmk$=af$thengosub13800:goto1500
1563 ifmk$="m"thengosub13000:goto1500
1564 ifmk$="e"thengosub53500:goto1500
1565 ifmk$="s"thengosub13200:goto1500
1566 ifmk$="o"thengosub13300:goto1505
1567 ifmk$="t"thengosub13400:goto1502
1568 ifmk$="i"thengosub13800:goto1500
1569 ifmk$="v"thengosub53200:goto1505
1570 ifmk$="d"thensd=0:gosub12400:goto1500
1571 ifmk$="p"thengosub12600:goto1505
1575 ifmk$="k"thengosub12200:goto1700
1577 ifmk$="h"thengosub59650:goto1500
1580 ifmk$="a"thenap=1-ap:goto1520
1581 ifmk$="$"ormk$="r"thengoto1620
1582 ifmk$="+"ormk$="*"ormk$="1"thengoto1600
1583 ifmk$="4"ormk$="7"ormk$="8"ormk$="n"ormk$="0"thengoto1620
1590 goto1540
1600 ifpf<0thenprinttt$:gosub40900:printtt$:gosub1800:goto1540
1601 ifpf=0thengosub1790:goto1502
1602 ifmk$="+"thengosub48800
1603 ifmk$="*"thengosub48850
1604 ifmk$="1"thenpn=0:gosub48700
1605 gosub1850
1610 goto1540
1620 if(so>=0)and(pl>=0)thengoto1630
1621 printtt$:print"  partition menu:{down}"
1623 dv=dd:gosub13900
1624 es=0:ifso<0thengosub51400:ifes>0thengoto1650
1625 gosub40900:ifes>0thengoto1650
1630 ifmk$="4"thengosub40100
1631 ifmk$="7"thengosub40110
1632 ifmk$="8"thengosub40120
1633 ifmk$="n"thengosub40130
1634 ifmk$="0"thengosub40140
1640 ifmk$="r"thengosub40500
1641 ifmk$="$"thengosub48500
1650 goto1505
1700 ifes>=0thengoto1500
1710 end
1790 print"{clr}good bye!":end
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
1850 sz$=po$+"{rvon} "
1851 sz$=sz$+"hd:"+mid$(str$(dd),2)+":"+chr$(48+sd)+" "
1852 sz$=sz$+"- l:"+mid$(str$(ga),2)+" "
1860 ifpf<0thengoto1880
1861 sz$=sz$+"- p:"+mid$(str$(pf),2)+" "
1862 sz$=sz$+"- f:"+mid$(str$(br*2),2)
1880 printleft$(sz$+sp$+sp$+sp$+sp$,39+24+2);"{rvof}{home}";
1890 return
9000 print"{down}  done!{down}":return
9010 print"  press <return> to continue.":return
9100 printtt$
9101 print"{down}no cmd-hd found!"
9110 print"exiting now!"
9120 return
9200 print"{down}  disk error:";es;"{down}":return
9500 print"  clear partition table:{down}":return
9510 print"      no more partitions found!":return
9520 print"  press <return> for main menu.":return
9540 print"  press <x> to cancel.{down}":return
9550 print"  erase content from disk";:return
9560 print"  create new partition:{down}":return
9570 print"  enable configuration mode";:return
10000 printtt$
10010 print"  select cmd-hd:"
10011 print"{down}{down}  currently selected:";dd;"{down}"
10020 dv=dd:gosub50400
10021 print"   >default address:";h1
10022 print"   >swap-key mode  :";
10023 ifh2=0thenprint" disabled"
10024 ifh2>0thenprint" active /";h2
10025 print"   >custom address :";
10026 ifh3=0thenprint" no"
10027 ifh3>0thenprint" yes /";h3
10030 print"{down}{down}  press +/- to select cmd-hd or"
10031 gosub9520
10040 getk$:ifk$=""thengoto10040
10050 ifk$<>"+"thengoto10060
10051 dd=dd+1:ifdd>30thendd=8
10052 ifdd=dvthengoto10040
10053 ifhd(dd)=0thengoto10051
10054 goto10000
10060 ifk$<>"-"thengoto10070
10061 dd=dd-1:ifdd<8thendd=30
10062 ifdd=dvthengoto10040
10063 ifhd(dd)=0thengoto10051
10064 goto10000
10070 ifk$<>chr$(13)thengoto10040
10080 gosub50900
10090 return
10100 printtt$
10110 printleft$(po$,5)
10111 print"  must be a device between 8 and 29."
10112 print"  enter '0' to return to menu."
10113 printleft$(po$,4)
10120 print"{up}";sl$
10121 input"{up}  enter device address";ga
10123 ifga=0thengoto10190
10130 if(ga<8)or(ga>29)or(ga=dd)thenga=0:goto10120
10131 open15,ga,15:close15
10132 ifst<>0thengoto10121
10190 return
10200 gosub50100:ifes<>0thengoto10290
10220 dv=dd:gosub50400
10230 gosub50900
10240 gosub59200
10290 return
11000 printtt$
11010 dv=dd:gosub50600
11020 gosub11200
11030 print"  press 0-6 to select scsi device or"
11040 gosub9520
11050 getk$:ifk$=""thengoto11050
11051 ifk$=chr$(13)thengoto11090
11052 if(k$<"0")or(k$>"6")thengoto11050
11053 k=val(k$):ifsi(k)>=0thensd=k:goto11020
11054 goto11050
11090 return
11200 printtt$
11220 print"  known scsi devices for cmd-hd:";dd;"{down}"
11221 print"  id  vendor/device          removable"
11222 printli$
11230 fori=0to6
11231 a$=" ":ifi=sdthena$="*"
11232 b$=" "
11233 if(si(i)=0)and(sm(i)=0)thenb$="h"
11234 if(si(i)=0)and(sm(i)>0)thenb$="z"
11235 if(si(i)=5)thenb$="c"
11236 if(si(i)=7)thenb$="m"
11237 print a$;right$(sp$+str$(i),2);" ";
11238 ifsi(i)=-1 thenprint"  ---{down}":goto11260
11240 print b$;" ";
11241 print ">";left$(sv$(i)+sp$, 8);"<"
11250 print "      >";left$(sp$(i)+sp$,16);"<          ";
11251 ifsm(i)=0thenprint" no"
11252 ifsm(i)>0thenprint"yes"
11260 next
11270 print li$
11290 return
12000 printtt$:print"  selected scsi device:{down}"
12010 dv=dd:gosub13900
12020 es=0:ifso<0thengosub51400:ifes>0thengoto12090
12025 pn=0
12026 gosub49200:ifes>0thengoto12050
12027 ifbu(2)<>255thengoto12050
12028 if(bu(30)*256+bu(31))<>144thengoto12050
12030 print"  changing active scsi device"
12031 gosub52000
12040 gosub50500
12041 goto12060
12050 print"  no partition table found!"
12051 goto12080
12060 gosub9000
12080 gosub60400
12090 return
12200 printtt$
12201 gosub9570:print":{down}"
12210 dv=dd:gosub13900
12220 gosub51400:ifes>0thengoto12290
12221 gosub51800
12230 printtt$
12231 gosub9570:print":{down}"
12240 gosub13900
12250 gosub9570:print
12251 gosub51000
12260 print"  set active scsi device{down}"
12261 gosub52200
12270 print"  cmd-hd/scsi device is configured!{down}"
12271 print"  use the cmd 'hd-tools.64' program to"
12272 print"  configure the cmd-hd/scsi device.{down}"
12273 print"  press 'reset' on the cmd-hd to exit"
12274 print"  the cmd-hd configuration mode.{down}"
12280 es=-127
12290 return
12400 printtt$:print"  change cmd-hd default address{down}"
12410 dv=dd:bb=225:gosub51200:ifes>0thengoto12690
12411 bx=bv
12420 fori=0to1
12421 forj=0to9
12422 printleft$(po$,15+j);
12423 fork=0toi*18:print"{right}";:next
12424 print"  ";right$("  "+str$(8+i*10+j),2);":";
12425 open15,(8+i*10+j),15:close15
12426 a$="none":ifst=0thena$="active"
12427 printa$
12428 next
12429 next
12430 printleft$(po$,10)
12431 print"  press +/- to switch device address,"
12432 print"  press <return> to set new address or"
12433 print"  press <x> to cancel."
12440 printleft$(po$,8)
12441 print"  cmd-hd default address:";bv;"{left}  "
12450 getkb$:ifkb$=""thengoto12450
12451 ifkb$="x"thengoto12490
12452 ifkb$=chr$(13)thengoto12460
12453 ifkb$="+"thenbv=bv+1:ifbv>29thenbv=8
12454 ifkb$="-"thenbv=bv-1:ifbv<8thenbv=29
12455 ifbx=bvthengoto12440
12456 open15,bv,15:close15:if(st=0)and(bv<>dd)thengoto12453
12457 if(kb$="+")or(kb$="-")thengoto12440
12458 goto12450
12460 ifbx=bvthengoto12490
12461 printtt$:print"  change cmd-hd default address:{down}"
12463 dv=bv:gosub13900:dv=dd
12470 bb=225:gosub51300:ifes>0thengoto12480
12471 bb=228:gosub51300:ifes>0thengoto12480
12472 cj$="00":gosub51900
12473 gosub9000
12474 gosub60400
12475 printtt$
12476 gosub10200:ifes<>0thengoto12480
12477 goto12490
12480 gosub9200
12481 gosub60400
12490 return
12600 printtt$:print"  change cmd-hd default partition{down}"
12610 dv=dd:bb=226:gosub51200:ifes>0thengoto12690
12611 bx=bv
12620 printleft$(po$,10)
12621 print"  press +/-/* to switch partition,"
12622 print"  press <return> to set partition or"
12623 print"  press <x> to cancel."
12630 printleft$(po$,8)
12631 print"  cmd-hd default partition:";bv;"{left}  "
12640 getkb$:ifkb$=""thengoto12640
12641 ifkb$="x"thengoto12690
12642 ifkb$=chr$(13)thengoto12650
12643 ifkb$="+"thenbv=bv+1:ifbv>254thenbv=1
12644 ifkb$="-"thenbv=bv-1:ifbv<1thenbv=254
12645 ifkb$="*"thenbv=bv+10:ifbv>254thenbv=254
12646 if(kb$="+")or(kb$="-")or(kb$="*")thengoto12630
12647 goto12640
12650 ifbx=bvthengoto12690
12660 printtt$:print"  change cmd-hd default partition:{down}"
12662 gosub13900
12663 print"  new default partition:";bv
12670 bb=226:gosub51300:ifes>0thengoto12675
12671 bb=227:gosub51300:ifes>0thengoto12675
12672 gosub9000
12673 goto12680
12675 gosub9200
12680 gosub60400
12690 return
13000 gosub54800:ifec>0thengoto13090
13005 printtt$:print"  format cmd-hd scsi device:{down}"
13010 dv=dd:gosub13900
13020 gosub13910
13021 gosub13950
13030 getk$:ifk$=""thengoto13030
13031 if(k$="s")or(k$="S")thengosub11000:goto13000
13032 if(k$="y")or(k$="Y")thengoto13040
13033 if(k$="n")or(k$="N")thenes=2:goto13090
13034 goto13030
13040 gosub53000
13090 return
13200 gosub54800:ifec>0thengoto13290
13205 printtt$:print"  create new system area:{down}"
13210 dv=dd:gosub13900
13220 gosub13920
13221 gosub13950
13230 getk$:ifk$=""thengoto13230
13231 if(k$="s")or(k$="S")thengosub11000:goto13200
13232 if(k$="y")or(k$="Y")thengoto13240
13233 if(k$="n")or(k$="N")thenes=2:goto13290
13234 goto13230
13240 gosub54000
13290 return
13300 gosub54800:ifec>0thengoto13390
13305 printtt$:print"  write new main o.s.:{down}"
13310 dv=dd:gosub13900
13311 es=0:ifso<0thengosub51410:ifes>0thengoto13490
13320 gosub13930
13321 gosub13950
13330 getk$:ifk$=""thengoto13330
13331 if(k$="s")or(k$="S")thengosub11000:goto13300
13332 if(k$="y")or(k$="Y")thengoto13340
13333 if(k$="n")or(k$="N")thenes=2:goto13390
13334 goto13330
13340 gosub55400
13390 return
13400 printtt$
13401 gosub9500
13410 dv=dd:gosub13900
13411 es=0:ifso<0thengosub51400:ifes>0thengoto13490
13420 gosub13940
13421 gosub13950
13430 getk$:ifk$=""thengoto13430
13431 if(k$="s")or(k$="S")thengosub11000:goto13400
13432 if(k$="y")or(k$="Y")thengoto13440
13433 if(k$="n")or(k$="N")thenes=2:goto13490
13434 goto13430
13440 printtt$
13441 gosub9500
13450 gosub13900
13460 gosub54400
13490 return
13800 gosub54800:ifec>0thengoto13892
13805 printtt$:print"  initialize cmd-hd scsi device:{down}"
13810 dv=dd:gosub13900
13820 gosub13910:gosub13930
13821 gosub13950
13830 getk$:ifk$=""thengoto13830
13831 if(k$="s")or(k$="S")thengosub11000:goto13800
13832 if(k$="y")or(k$="Y")thengoto13840
13833 if(k$="n")or(k$="N")thengoto13885
13834 goto13830
13840 ifmk$="i"thenmk$=af$:goto13860
13850 gosub53000
13851 ifk$="x"thengoto13885
13852 ifes>0thengoto13890
13853 gosub51800
13855 gosub53200
13856 ifes>0thengoto13890
13860 gosub54000:ifes>0thengoto13890
13861 gosub55400:ifes>0thengoto13890
13862 gosub54400:ifes>0thengoto13890
13870 print"{down}{down}  initializing disk successful!{down}"
13880 gosub60400
13885 es=0:return
13890 print"{down}{down}  initializing disk failed!{down}"
13891 gosub60400
13892 es=2:return
13900 print"    cmd-hd  :";dv
13901 print"    scsi id :";sd
13903 print"    vendor  : '";sv$(sd);"'"
13904 print"    product : '";sp$(sd);"'{down}"
13909 return
13910 print"  warning: this will destroy all data"
13911 print"  on the specified scsi-drive!{down}"
13919 return
13920 print"  this will create a new system"
13921 print"  area on the selected scsi device.{down}"
13922 print"  warning: continuing will cause any"
13923 print"  data and partitions to be lost!{down}"
13929 return
13930 print"  this will install a new hd-os and"
13931 print"  geos/hd driver onto your cmd-hd.{down}"
13932 print"  important: you need a floppy disk in"
13933 print"  drive";ga;"with these system files:"
13934 print"  '";s3$;"', '";s0$;"' and"
13935 print"  '";s1$;"'.{down}"
13939 return
13940 print"  this will clear the current partition"
13941 print"  table on the selected scsi device.{down}"
13942 print"  warning: continuing will cause any"
13943 print"  data and partitions to be lost!{down}"
13949 return
13950 print"  press <s> to select new scsi device."
13951 print"  continue (y/n/s)?"
13952 return
40100 pt=2:pr=684/2:goto40150
40110 pt=3:pr=1366/2:goto40150
40120 pt=4:pr=3200/2:goto40150
40130 pt=1:pr=(255*256)/2:goto40150
40140 pt=7:pr=(256*256)/2
40150 printtt$
40151 gosub9560
40152 dv=dd:gosub13900
40155 ifpf<1thenes=1:goto40190
40160 pn=pf
40165 gosub48900
40170 ifpt<>1andpt<>7thengoto40180
40171 ifap=0thengosub41200
40172 ifpr>brthenpr=br
40173 ifpr=0thengoto40195
40174 ifpr<(256/2)thenpr=(256/2)
40175 ifpt=1andpr>((255*256)/2)thenpr=((255*256)/2)
40176 ifpt=7andpr>((256*256)/2)thenpr=((256*256)/2)
40180 ifpr>brthengoto40195
40181 gosub41000:ifpn$=""thengoto40199
40182 gosub48200
40183 gosub40900
40184 return
40190 printtt$:print"{down}  no more free partition!"
40191 goto40198
40195 printtt$:print"{down}  not enough free blocks!"
40198 gosub60400
40199 return
40500 printtt$:print"  delete partition:{down}"
40510 ifpl<1thengoto40580
40511 pn=pl:gosub49200:ifes>0then:goto40575
40520 printli$
40521 printright$(sp$+str$(pn),4);" ";
40522 print"'";:fori=0to15:printchr$(bu(ip+5+i));:next:print"'";
40523 bh=bu(ip+29):bm=bu(ip+30):bl=bu(ip+31)
40524 gosub58950
40525 printright$(sp$+str$(ba*2),6);" ";
40526 pt=bu(ip+2):gosub48900:printpt$
40527 printli$;"{down}"
40530 print"  delete partition (y/n) ? ";
40540 getkb$:ifkb$=""thengoto40540
40541 if(kb$="y")or(kb$="Y")thengoto40550
40542 if(kb$="n")or(kb$="N")thengoto40599
40543 goto40540
40550 printkb$;"{down}"
40551 print"  deleting partition"
40552 bu(ip+2)=0
40553 gosub49400:ifes>0thengoto40575
40560 gosub52000:ifes>0thengoto40575
40561 gosub50500
40565 gosub48000:ifes>0thengoto40599
40570 print"  partition deleted!"
40571 gosub9000
40572 goto40590
40575 gosub9200
40576 goto40590
40580 gosub9510
40581 printli$
40590 gosub60400
40599 return
40900 ifpl>=0thengoto40950
40930 gosub48000:ifes>0thengoto40990
40931 ifpf=0thengoto40950
40932 print
40940 open15,dv,15
40941 gosub59450
40942 gosub51800
40943 close15
40950 br=tb-pa-ps
40990 return
41000 gosub48900
41001 ifap=0thengoto41050
41010 by=pf:gosub60200
41020 pn$=pt$+"#"+he$
41030 goto41090
41050 printtt$
41051 print"  create new ";pt$;"-mode partition{down}{down}"
41052 print"  please enter partition name:"
41053 print"  (leave blank to go back to menu){down}"
41054 printleft$(po$,20)
41055 print"  note: only 16 characters or less are"
41056 print"        allowed. it is recommended to"
41057 print"        use letters and numbers only."
41060 printleft$(po$,10);"  ";
41070 pn$="":inputpn$
41080 iflen(pn$)>16thengoto41060
41090 return
41200 printtt$
41201 print"  create new ";pt$;"-mode partition{down}"
41202 print"  free blocks remaining:";br*2
41210 printleft$(po$,13);
41211 print"  press +/-/* to change partiton size,"
41212 print"  press <x> to go back to menu or"
41213 gosub9010
41220 pr=1024
41221 px=32640:ifpt=7thenpx=32768
41230 printleft$(po$,9);
41231 print"  new partition size:";pr*2;"{left} blocks   "
41232 print"  ( about";pr*512/1024;"{left} kb )    "
41240 getkb$:ifkb$=""thengoto41240
41250 ifkb$="+"thenpr=pr+128:ifpr>pxthenpr=128
41251 ifkb$="-"thenpr=pr-128:ifpr<128thenpr=px
41252 ifkb$="*"thenpr=pr+1024:ifpr>pxthenpr=128
41260 ifpr>brthenpr=br
41270 ifkb$="x"thenpr=0:goto41290
41280 ifkb$<>chr$(13)thengoto41230
41290 return
48000 es=0:ifso<0thengosub51400:ifes>0thengoto48190
48010 print"  analyzing partition table"
48011 print"  ";
48020 open15,dv,15
48030 pc=0:pa=0:ps=0:pb=-1:pf=-1:pl=-1
48040 forii=0to254
48050 pt(ii)=0
48060 ba=so+128+int(ii/16)
48100 ifpb=bathengoto48110
48101 print".";
48102 gosub58900:rh=bh:rm=bm:rl=bl
48103 pb=ba:gosub58200
48110 ip=(ii and 15)*32
48120 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
48122 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
48123 get#15,a$:pt(ii)=asc(a$+nu$)
48124 ifpf<0thenifpt(ii)=0thenpf=ii
48125 ifpt(ii)=0thengoto48180
48130 ad=sb+ip+21:hi=int(ad/256):lo=ad-hi*256
48131 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
48132 get#15,a$:bh=asc(a$+nu$)
48133 get#15,a$:bm=asc(a$+nu$)
48134 get#15,a$:bl=asc(a$+nu$)
48140 gosub58950
48150 ifba<pathengoto48180
48151 pl=ii
48152 pa=ba
48160 ad=sb+ip+29:hi=int(ad/256):lo=ad-hi*256
48161 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
48162 get#15,a$:bh=asc(a$+nu$)
48163 get#15,a$:bm=asc(a$+nu$)
48164 get#15,a$:bl=asc(a$+nu$)
48170 gosub58950
48171 ps=ba
48180 next
48181 print
48182 print"{up}";sp$;sp$;"{up}"
48183 close15
48190 return
48200 printtt$
48201 gosub9560
48202 print"    partition :";pn
48203 print"    name      : ";pn$
48204 print"    type      : ";pt$
48205 print"    size      :";pr*2;"blocks{down}"
48210 print"  creating partition"
48211 gosub48400
48220 gosub49400:ifes>0thengoto48390
48230 gosub52000:ifes>0thengoto48390
48231 gosub50500
48240 ifpt<1orpt>4thengoto48340
48300 print"  formatting partition"
48310 open15,dv,15
48320 print#15,"cp"+mid$(str$(pn),2)
48321 input#15,a$:es=val(a$):ifes>2thengoto48330
48323 print#15,"n:"+pn$+",hd"
48324 input#15,a$:es=val(a$)
48330 close15
48340 print"{down}"
48341 ifes>0thengoto48380
48350 pt(pn)=pt:pa=pa+ps:ps=pr:pl=pn
48351 gosub48700
48360 print"  partition created!{down}"
48370 ifap=0thengoto48385
48371 ifap<>0thengosub51800
48372 goto48390
48380 gosub9200
48385 gosub60400
48390 return
48400 ip=(pn and 15)*32
48410 fori=2to31:bu(ip+i)=0:next
48420 bu(ip+ 2)=pt
48431 pn$=left$(pn$,16)
48432 nm$=pn$
48433 iflen(nm$)<16thennm$=nm$+chr$(160):goto48433
48434 fori=0to15:bu(ip+ 5+i)=asc(mid$(nm$,i+1,1)):next
48440 ba=pa+ps:gosub58900
48441 bu(ip+21)=bh:bu(ip+22)=bm:bu(ip+23)=bl
48450 ba=pr:gosub58900
48451 bu(ip+29)=bh:bu(ip+30)=bm:bu(ip+31)=bl
48490 return
48500 gosub48600
48515 pc=0:px=0:pb=-1:mp=16:k$=""
48516 open15,dv,15
48520 forpn=1to254
48530 ifpt(pn)=0thengoto48560
48531 printright$(sp$+str$(pn),4);" ";
48532 ba=so+128+int(pn/16)
48533 ifpb=bathengoto48540
48534 gosub58900:rh=bh:rm=bm:rl=bl
48535 pb=ba:gosub58200
48540 ip=(pn and 15)*32
48541 ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
48542 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
48543 print"'";:fori=1to16:get#15,a$:printa$;:next:print"'";
48544 ad=sb+ip+30:hi=int(ad/256):lo=ad-hi*256
48545 print#15,"m-r"chr$(lo)chr$(hi)chr$(2)
48546 get#15,a$,b$:ba=asc(a$+nu$)*256+asc(b$+nu$)
48547 printright$(sp$+str$(ba*2),6);" ";
48548 pt=pt(pn):gosub48900:printpt$
48550 px=px+1:pc=pc+1:ifpc<mpthengoto48560
48551 printleft$(po$,25);
48552 print"  <return> next page    <";chr$(95);"> main menu";
48553 getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto48553
48554 ifk$=chr$(13)thengoto48559
48555 ifk$=chr$(95)thenpn=254:goto48560
48556 goto48553
48559 pc=0:gosub48600
48560 next
48561 close15
48564 ifk$=chr$(95)thengoto48590
48565 if(px=0)thengoto48575
48566 if(pc>0)thengoto48580
48570 print"{down}{down}";:gosub9510
48571 goto48580
48575 print"{down}{down}      no partitions found!"
48580 printleft$(po$,25);"  press <return> to continue.";
48581 getk$:ifk$<>chr$(13)thengoto48581
48590 return
48600 printtt$
48610 print"  partition list: cmd-hd";str$(dd);":";chr$(48+sd);"{down}"
48620 print"  nr  partition          size type"
48630 printli$
48640 fori=0to15:printsl$:next
48650 printli$
48660 printsl$;left$(po$,7)
48690 return
48700 pf=0:fori=pnto254
48701 ifpt(i)=0thenpf=i:i=254
48702 next
48710 if(pf>0)or(pn=1)thengoto48790
48720 fori=1topn
48721 ifpt(i)=0thenpf=i:i=pn
48722 next
48790 return
48800 pn=pf+1:ifpn>254thenpn=1
48801 goto48700
48850 pn=pf+10:ifpn>254thenpn=1
48851 goto48700
48900 ifpt=255thenpt$=pd$(8):return
48910 ifpt>7thenpt$=pd$(9):return
48920 pt$=pd$(pt):return
49000 es=0:ifso<0thengosub51400:ifes>0thengoto49090
49005 ba=so+128+int(pn/16)
49010 gosub58900:rh=bh:rm=bm:rl=bl
49020 open15,dv,15:gosub58200:close15
49090 return
49100 es=0:ifso<0thengosub51400:ifes>0thengoto49190
49110 ba=so+128+int(pn/16)
49120 gosub58900:wh=bh:wm=bm:wl=bl
49130 open15,dv,15:gosub58300:close15
49190 return
49200 gosub49000:ifes>0thengoto49290
49210 ip=(pn and 15)*32
49220 open15,dv,15:gosub58400:close15
49290 return
49400 gosub49000:ifes>0thengoto49490
49410 ip=(pn and 15)*32
49420 open15,dv,15:gosub58510:close15
49430 gosub49100
49490 return
50100 printtt$;left$(po$,7)
50120 es=0:hc=0:dd=0:for dv=8 to 30
50130 print"{up}  scanning for cmd-hd devices...";dv
50131 open15,dv,15:close15
50132 hd(dv)=0:ifst<>0thengoto50140
50134 gosub50300:ifes<>0thengoto50140
50135 hd(dv)=dv:hc=hc+1:ifdd=0thendd=dv
50140 next
50150 ifhc=0thengosub9100:es=-1:goto50190
50160 es=0:ed=0:fordv=8to29
50161 ifhd(dv)=0thengoto50166
50162 gosub50400
50163 if(h1>0)and(dv<>h1)thenes=es+1
50164 if(h2>0)thenes=es+1
50165 if(h3>0)thenes=es+1
50166 if((h1+h2+h3)>0)and(ed=0)thened=dv
50167 next
50170 ifes=0thengoto50180
50171 printleft$(po$,15);
50172 print"  bad cmd-hd address!{down}"
50173 print"  please reset cmd-hd #";mid$(str$(ed),2);" and then"
50174 print"  press <return> to continue."
50175 getk$:ifk$<>chr$(13)thengoto50175
50176 goto50100
50180 dv=dd:gosub50400
50190 return
50300 b$="":open15,dv,15
50310 print#15,"m-r"chr$(160)chr$(254)chr$(6)
50320 fora=1to6:get#15,a$:b$=b$+a$:next
50330 close15
50350 es=0:ifb$<>"cmd hd"thenes=-1
50360 return
50400 open15,dv,15
50420 print#15,"m-r"chr$(225)chr$(144)chr$(1)
50425 get#15,a$:h1=asc(a$+nu$)
50430 print#15,"m-r"chr$(228)chr$(144)chr$(1)
50435 get#15,a$:h2=asc(a$+nu$)
50440 close15
50450 ifh2=dvthengoto50453
50451 ifh2=(128+8)thenh2=8:goto50460
50452 ifh2=(128+9)thenh2=9:goto50460
50453 h2=0
50460 ifh1=dvthenh2=0:h3=0:goto50490
50461 ifh2=dvthenh3=0:goto50490
50462 h3=dv
50490 return
50500 dv=h1
50520 ifh2=0thengoto50530
50522 open15,dv,15,"s-"+chr$(48+h2):close15
50525 dv=h2
50530 ifh3=0thengoto50540
50532 open15,dv,15,"u0>"+chr$(h3):close15
50535 dv=h3
50540 print"  cmd-hd device address: ";
50541 printmid$(str$(dv),2);":";chr$(48+sd)
50590 return
50600 printleft$(po$,6)
50610 print"  scanning for scsi devices...     ";
50620 sx=sd
50630 forid=0to6
50631 print"{left}{left}{left}{left}";right$("   "+str$(int(id*100/6)),3);"%";
50632 si(id)=-1:sm(id)=0:sv$(id)="":sp$(id)="":sr$(id)=""
50633 sd=id:gosub59100
50634 ifes>127thengoto50640
50635 gosub59200
50640 next
50680 sd=sx
50690 return
50700 es=0
50710 gosub59500
50720 ifsi(sd)<>0thengoto50730
50721 ifsm(sd)=0thengoto50790
50730 gosub59100:ifes<2thengoto50790
50740 print"  please insert media in drive: ";
50741 printmid$(str$(dv),2);":";mid$(str$(sd),2)
50750 gosub9540
50760 getk$:ifk$="x"thengoto50790
50761 gosub59100:ifes>=2thengoto50760
50790 return
50900 open15,dv,15
50910 print#15,"m-r"chr$(0)chr$(144)chr$(1)
50920 get#15,a$:a=asc(a$+nu$)/2/2/2/2
50930 sd=0:if(a>0)and(a<7)thensd=a
50940 close15
50990 return
51000 cj$="06":gosub51900
51090 return
51100 cj$="14":gosub51900
51120 gosub51800:return
51200 es=0:ifso<0thengosub51400:ifes>0thengoto51290
51205 ba=so+2
51210 open15,dv,15
51211 gosub58900:rh=bh:rm=bm:rl=bl
51215 gosub58200
51220 ad=sb+256+bb:hi=int(ad/256):lo=ad-hi*256
51222 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
51223 get#15,a$:bv=asc(a$+nu$)
51240 close15
51290 return
51300 es=0:ifso<0thengosub51400:ifes>0thengoto51390
51305 ba=so+2
51310 open15,dv,15
51311 gosub58900:rh=bh:rm=bm:rl=bl
51315 gosub58200
51320 ad=sb+256+bb:hi=int(ad/256):lo=ad-hi*256
51322 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
51323 es=0:get#15,a$:if(bx<>asc(a$+nu$))thenes=1:goto51380
51330 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(bv)
51341 wh=bh:wm=bm:wl=bl:gosub58300
51380 close15
51390 return
51400 mo=0:goto51420
51410 mo=1
51420 gosub50700:ifes>2thenreturn
51421 es=0:so=-1
51430 open15,dv,15
51431 gosub59400
51432 mx=int(tb*512/65536)-1
51433 ifmx>255thenmx=255
51434 ifmm<0thengoto51460
51440 print"  searching for system area... ";
51442 forbc=0tomx
51443 printright$("   "+str$(int(bc*100/mx)),3);"%{left}{left}{left}{left}";
51444 gosub51500:ifes>0thengoto51450
51445 ifmo<>0thengoto51446
51446 gosub51550:ifes>0thengoto51450
51447 so=bc*128:bc=255
51450 next
51460 close15
51470 ifso>=0thengoto51480
51471 print"error!"
51472 print"{down}  no system area found on disk!{down}"
51473 gosub60400
51474 es=128:return
51480 print"ok! "
51481 print"  found system area at offset:";so;"{down}"
51482 es=0:return
51500 es=255
51505 ba=bc*128+2
51506 gosub58900:rh=bh:rm=bm:rl=bl
51510 gosub58200
51511 ad=sb+256+240:hi=int(ad/256):lo=ad-hi*256
51512 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
51513 fori=0to15
51514 get#15,a$:bu(256+240+i)=asc(a$+nu$)
51515 next
51520 es=0:fori=0to7
51521 ifbu(256+240+i)<>asc(mid$("cmd hd  ",1+i,1))thenes=1:i=7
51522 next:ifes>0thengoto51540
51530 ifbu(256+248)<>141thengoto51540
51531 ifbu(256+249)<>3  thengoto51540
51532 ifbu(256+250)<>136thengoto51540
51533 ifbu(256+251)<>142thengoto51540
51534 ifbu(256+252)<>2  thengoto51540
51535 ifbu(256+253)<>136thengoto51540
51536 ifbu(256+254)<>234thengoto51540
51537 ifbu(256+255)<>96 thengoto51540
51539 es=0
51540 return
51550 ba=bc*128+60
51556 gosub58900:rh=bh:rm=bm:rl=bl
51560 gosub58200
51561 ad=sb+160:hi=int(ad/256):lo=ad-hi*256
51562 print#15,"m-r"chr$(lo)chr$(hi)chr$(6)
51563 fori=0to5
51564 get#15,a$:bu(160+i)=asc(a$+nu$)
51565 next
51570 es=0:fori=0to5
51571 ifbu(160+i)<>asc(mid$("cmd hd",1+i,1))thenes=1:i=5
51572 next
51590 return
51800 pokets,0
51810 ifpeek(ts)<120thengoto51810
51890 return
51900 he$=    "78"
51901 he$=he$+"a992"
51902 he$=he$+"8d0388"
51903 he$=he$+"a9e3"
51904 he$=he$+"8d0288"
51905 he$=he$+"a9"+cj$
51906 he$=he$+"18"
51907 he$=he$+"08"
51908 he$=he$+"4cedde"
51910 gosub51950:return
51950 gosub60100
51960 open15,dv,15
51961 print#15,"m-w"chr$(0)chr$(3)chr$(len(by$))by$
51962 print#15,"m-e"chr$(0)chr$(3)
51963 close15
51970 gosub51800
51990 return
52000 by=h1:gosub60200:h1$=he$
52001 by=sd:gosub60200:sd$=he$
52010 he$=    "78"
52011 he$=he$+"a992"
52012 he$=he$+"8d0388"
52013 he$=he$+"a9e3"
52014 he$=he$+"8d0288"
52015 he$=he$+"20bad1"
52016 he$=he$+"a901"
52017 he$=he$+"8daa30"
52018 he$=he$+"a9"+sd$
52019 he$=he$+"200ed1"
52020 he$=he$+"ad008f"
52021 he$=he$+"0920"
52022 he$=he$+"8d008f"
52023 he$=he$+"a9"+h1$
52024 he$=he$+"8de190"
52025 he$=he$+"8de490"
52030 he$=he$+"a9"+sd$
52031 he$=he$+"0a"
52032 he$=he$+"0a"
52033 he$=he$+"0a"
52034 he$=he$+"0a"
52035 he$=he$+"8d0090"
52040 he$=he$+"ad008f"
52041 he$=he$+"29df"
52042 he$=he$+"8d008f"
52043 he$=he$+"20b6dc"
52044 he$=he$+"4c9fd0"
52050 gosub51950:return
52200 dv=hd
52201 by=sd:gosub60200:sd$=he$
52210 he$=    "a901"
52211 he$=he$+"8daa30"
52212 he$=he$+"a9"+sd$
52213 he$=he$+"200ed1"
52214 he$=he$+"4c3de5"
52250 gosub51950:return
53000 dv=h1
53020 printtt$
53021 print"  select scsi format method:{down}"
53022 print"   1. standard format"
53023 print"      the recommended format method."
53024 print"      should work for most devices.{down}"
53025 print"   2. alternative format"
53026 print"      if standard format does not work"
53027 print"      for you then try this method.{down}"
53028 print"  select scsi format method (1/2) or"
53029 gosub9540
53030 getk$:ifk$=""thengoto53030
53031 ifk$="1"thenfm$="01":goto53100
53032 ifk$="2"thenfm$="00":goto53100
53033 ifk$=chr$(13)thenk$="x"
53090 es=2:return
53100 gosub50700:ifes>2thengoto53090
53102 printtt$
53103 print"  formatting, please wait...{down}{down}"
53104 print"  average time needed to format:{down}"
53105 print"   >about 10min. for a 100mb zip disk"
53106 print"   >about 5secs. for a 1gb scsi2sd"
53107 print
53110 open15,dv,15
53111 sc$=nu$+nu$+nu$+nu$
53112 print#15,"m-w"chr$(sl)chr$(sh)chr$(4)sc$
53120 he$="04180000"+fm$+"00":gosub60100:sc$=by$
53121 gosub59800
53130 eb=es:gosub59300:es=eb
53132 close15
53140 ifes=0thengoto53194
53190 print"{down}  formatting failed!"
53191 goto 53198
53194 print"{down}  format completed!"
53195 ifmk$=af$thengoto53199
53198 gosub60400
53199 return
53200 printtt$:print"  verifying format, please wait...{down}"
53205 gosub50700:ifes>2thengoto53490
53206 es=0
53230 print"{down}"
53231 open15,dv,15
53232 gosub59450:ifes>0thengoto53450
53300 bc=tb:bf=0:br=0:of=0
53320 vl=65535
53321 ifvl>bcthenvl=bc
53322 ifvl=0thengoto53400
53330 printleft$(po$,16)
53331 print"  verifying :";of+1;"{left} -";of+vl
53332 print"  bad blocks:";bf
53333 print"  remapped  :";br
53334 print
53340 he$="2f00":gosub60100:sc$=by$
53341 bh=int(of/65536)
53342 bm=int((of-(bh*65536))/256)
53343 bl=of-(bh*65536+bm*256)
53344 sc$=sc$+nu$+chr$(bh)+chr$(bm)+chr$(bl)
53345 sc$=sc$+nu$
53346 bh=int(vl/256):bl=vl-(bh*256)
53348 sc$=sc$+chr$(bh)+chr$(bl)
53349 sc$=sc$+nu$
53350 gosub59800:ifes=0thengoto53390
53360 gosub59300:ifes>0thengoto53450
53362 bb=ec(4)*65536+ec(5)*256+ec(6)
53363 if(ec(2)and15)=1thengoto53370
53364 if((ec(2)and15)=9)and(ec(12)=128)thengoto53387
53365 if(ec(2)and15)<>3thengoto53450
53370 dl$=nu$+nu$+nu$+chr$(4)
53371 dl$=dl$+chr$(ec(3))+chr$(ec(4))+chr$(ec(5))+chr$(ec(6))
53372 bf=bf+1
53373 print#15,"m-w"chr$(sl)chr$(sh)chr$(8)dl$
53380 he$="070000000000":gosub60100:sc$=by$
53381 gosub59800:ifes>0thengoto53450
53386 br=br+1
53387 bc=bc-(bb-of):of=bb:goto53320
53390 bc=bc-vl:of=of+vl
53391 ifbc>0thengoto53320
53400 print"{down}  verify disk successful!"
53410 close15
53420 es=0
53430 ifmk$=af$thengosub51800:goto53440
53431 gosub60400
53440 return
53450 print"{down}  verify disk failed!"
53460 close15
53461 es=255
53470 gosub60400
53490 return
53500 mx=2048
53501 ifsd>0thengoto53550
53510 printtt$
53511 gosub9550:print":{down}"
53520 print"{down}  warning!{down}"
53521 print"  you are going to erase the content"
53522 print"  of the scsi device id=0 !{down}{down}"
53523 print"  are you really sure (y/n) ?"
53530 getk$:ifk$=""thengoto53530
53531 if(k$="y")or(k$="Y")thengoto53550
53532 if(k$="n")or(k$="N")thenes=2:goto53590
53533 goto53530
53550 printtt$
53551 gosub9550:print":{down}{down}"
53560 dv=dd:gosub13900
53570 print"{down}  select erase method:{down}"
53571 print"    -a- erase all data from disk (slow)"
53572 print"    -b- erase first";mx;"blocks only{down}"
53573 print"  press a/b to erase data from disk or"
53574 gosub9520
53580 getk$:ifk$=""thengoto53580
53581 if(k$="a")or(k$="A")thenmo=1:goto53600
53582 if(k$="b")or(k$="B")thenmo=0:goto53600
53583 ifk$<>chr$(13)thengoto53580
53590 return
53600 printtt$
53605 gosub9550:print":{down}{down}"
53610 open15,dv,15
53611 gosub59450
53620 bc=tb:ifmo=0thenbc=mx
53630 print"{down}  preparing scsi data-out buffer"
53631 by$="":fori=0to31:by$=by$+nu$:next
53632 fori=0to15:forj=0to255step32
53633 ad=sb+i*256+j:hi=int(ad/256):lo=ad-hi*256
53636 print#15,"m-w"chr$(lo)chr$(hi)chr$(32)by$
53637 next
53640 gosub9550:print"...{down}"
53650 forba=0tobc-1step8
53651 gosub58900
53652 by=bh:gosub60200:wh$=he$
53653 by=bm:gosub60200:wm$=he$
53654 by=bl:gosub60200:wl$=he$
53655 print"{up}    -> $";wh$;":";wm$;wl$;"  / ";int(ba*100/bc);"{left}% "
53660 he$="2a0000"+wh$+wm$+wl$+"00000800":gosub60100:sc$=by$
53661 gosub59800:ifes>0thenba=tb
53670 next
53680 close15
53681 print"{up}";sl$
53682 ifes=0thengoto53690
53685 print"{down}  erase content failed!"
53686 gosub60400
53687 return
53690 gosub9000
53691 gosub60400
53692 return
54000 dv=h1
54020 gosub50700
54030 ifes>2thenreturn
54060 printtt$;left$(po$,18);
54062 open15,dv,15
54063 gosub59450
54064 close15
54070 nh=bh:nm=bm:nl=bl
54100 so=384
54105 ifmk$<>af$thengoto54110
54106 printleft$(po$,4);
54107 print"  initializing disk, please wait...{down}{down}"
54108 gosub51800
54109 goto54300
54110 printleft$(po$,4);
54111 print"  select system startiing address:{down}"
54112 print"  note: default starting address is 384"
54113 print"        change value at own risk!"
54120 oh=int(so*512/65536)
54121 om=int((so*512-oh*65536)/256)
54122 ol=so*512-oh*65536-om*256
54130 printleft$(po$,9);
54131 print"  system starting address = ";
54132 by=oh:gosub60200:print"$";he$;":";
54133 by=om:gosub60200:printhe$;
54134 by=ol:gosub60200:printhe$
54135 print"  (";int(so*512/1024);"{left}kb reserved memory )  {down}"
54140 print"  use +/- to adjust starting address"
54141 gosub9010
54150 getk$:ifk$=""thengoto54150
54151 ifk$="+"thenso=so+128
54152 ifk$="-"thenso=so-128
54153 ifso<0thenso=0
54154 ifint(so/(65536/512))>255thenso=0
54155 if(so>tb-2048)thenso=0
54156 ifk$<>chr$(13)thengoto54120
54200 ifso=0thengoto54300
54210 printtt$
54211 print"  clear area below system:{down}"
54212 print"  warning! some devices may use this"
54213 print"  area for system data.{down}"
54214 print"  skip this step if you share the"
54215 print"  cmd-hd with other computer types.{down}"
54216 print"  if unsure say 'n'."
54217 print"  clear reserved area (y/n)? ";
54220 getk$:if(k$<>"y")and(k$<>"n")thengoto54220
54221 printk$:ifk$="n"thengoto54300
54230 print"{down}  clearing area below system"
54240 open15,dv,15
54241 gosub58800
54242 gosub58000
54243 print
54250 forba=0toso-1
54251 print"{up}  blocks left:";(so-ba)-1;"{left}   "
54252 gosub58900:wh=bh:wm=bm:wl=bl
54254 gosub58300:ifes>0thenba=so
54256 next
54257 close15
54258 ifes=0thengoto54300
54275 print"{down}  clear system area failed!"
54276 gosub9200
54277 gosub60400
54280 close15
54290 return
54300 ifso>0thengoto54310
54301 printtt$
54310 gosub58800
54311 print"{down}  writing hardware table"
54315 hx=h1:ifhx=30thenhx=12
54320 bu(256)=sd*16
54321 fori=1to55
54322 bu(256+i)=255
54323 next
54330 bu(256+56+1)=nh
54331 bu(256+56+56+1)=nm
54332 bu(256+56+56+56+1)=nl
54335 fori=2to55
54336 bu(256+i+56)=255
54337 bu(256+i+56+56)=255
54338 bu(256+i+56+56+56)=255
54339 next
54341 bu(256+225)=hx
54342 bu(256+226)=1
54343 bu(256+227)=1
54344 bu(256+228)=hx
54345 bu(256+229)=128
54346 bu(256+230)=1
54360 fori=0to7
54361 bu(256+240+i)=asc(mid$("cmd hd  ",1+i,1))
54362 next
54370 bu(256+248)=141
54371 bu(256+249)=3
54372 bu(256+250)=136
54373 bu(256+251)=142
54374 bu(256+252)=2
54375 bu(256+253)=136
54376 bu(256+254)=234
54377 bu(256+255)=96
54380 open15,dv,15
54381 gosub58000
54382 ba=so+2:gosub58900:wh=bh:wm=bm:wl=bl
54384 gosub58300
54385 close15
54386 ifes>0thengoto54275
54387 ifmk$=af$thengoto54390
54388 print:gosub9000
54389 gosub60400
54390 return
54400 gosub58800
54410 print"  writing partition table"
54420 open15,dv,15
54421 forsy=15to0step-1
54422 bu(  0)=1:bu(  1)=1+sy*2
54423 bu(256)=1:bu(257)=1+sy*2+1
54424 ifsy<15thengoto54430
54425 bu(256)=0:bu(257)=255
54430 gosub58000
54431 ba=so+128+sy
54432 gosub58900:wh=bh:wm=bm:wl=bl
54434 gosub58300:ifes>0thensy=0
54439 next
54440 ifes>0thengoto54485
54450 pn=0:pt=255:pa=so:ps=0:pr=144:pn$="system"
54460 gosub48400
54480 gosub58000
54482 gosub58300:ifes=0thengoto54490
54485 print"{down}  writing partition table failed!"
54486 print"{down}  write error:";es
54487 gosub60400
54488 close15
54489 return
54490 ifmk$=af$thengoto54495
54491 print:gosub9000
54492 gosub60400
54495 close15
54499 return
54800 printtt$:print"  checking system files... ";
54802 open15,ga,15:close15:ifst<>0thenec=7:goto54850
54805 ec=0
54810 ff$=s0$:gosub55800
54811 ifes=0thengoto54820
54819 ec=ec+1
54820 ff$=s2$:gosub55800
54821 ifes=0thens1$=s2$:goto54830
54822 ff$=s1$:gosub55800
54823 ifes=0thens2$=s1$:goto54830
54829 ec=ec+2
54830 ff$=s3$:gosub55800
54831 ifes=0thengoto54840
54839 ec=ec+4
54840 ifec=0thenprint"ok!{down}{down}":goto54890
54850 print"error!":print"{down}{down}  missing some system files: {down}"
54851 if(ecand1)>0thenprint"   > ";s0$
54852 if(ecand2)>0thenprint"   > ";s1$
54853 if(ecand4)>0thenprint"   > ";s3$
54855 print"{down}":gosub60400
54890 return
55000 gosub54800:ifec>0thengoto55390
55010 print"  verifying cmd-hd system files:"
55020 gosub55900
55100 print"{down}  verifying ";s0$;"{down}"
55106 open2,ga,0,s0$
55107 get#2,a$,a$
55110 su=0:fori=1todc
55120 print"{up}  blocks remaining:";dc-i;"{left} "
55121 forj=0to255
55122 get#2,a$:su=su+asc(a$+nu$):ifsu>65535thensu=su-65536
55123 next
55130 next
55140 close2
55150 ch=int(su/256):cl=su-ch*256
55151 if(ch<>dh)or(cl<>dl)thengoto55320
55200 print"{down}  verifying ";s1$;"{down}"
55206 open2,ga,0,s1$
55207 get#2,a$,a$
55210 su=0:fori=1togc
55220 print"{up}  blocks remaining:";gc-i;"{left} "
55221 forj=0to255
55222 get#2,a$:su=su+asc(a$+nu$):ifsu>65535thensu=su-65536
55223 next
55230 next
55240 close2
55250 ch=int(su/256):cl=su-ch*256
55251 if(ch<>gh)or(cl<>gl)thengoto55310
55300 print"{down}{down}  all system files ok!"
55301 gosub60400
55302 return
55310 print"{down}  checksum error: ";s1$
55311 gosub60400
55312 return
55320 print"{down}  checksum error: ";s0$
55321 gosub60400
55390 return
55400 ifmk$=af$thengoto55410
55401 gosub54800:ifec>0thengoto55790
55410 printtt$
55411 print"  preparing system area{down}{down}"
55412 print"  please be patient..."
55413 print"  (this may take some time){down}{down}"
55420 es=0:ifso<0thengosub51400:ifes>0thengoto55790
55430 gosub55900
55500 print"  writing main o.s.{down}"
55506 open2,ga,0,s0$:open15,dv,15
55507 get#2,a$,a$
55510 ba=db:forwi=1todcstep2
55520 print"{up}  process:";int(wi/dc*100)"{left}% "
55521 forwj=0to511
55522 get#2,a$:bu(wj)=asc(a$+nu$)
55523 next
55524 gosub58000
55525 gosub58900:wh=bh:wm=bm:wl=bl
55527 gosub58300:ifes>0thenwi=dc
55529 ba=ba+1:print"{up}";sp$;sp$
55530 next
55540 close2:close15
55550 ifes>0thengoto55780
55600 print"{up}  writing geos/hd driver{down}"
55606 open2,ga,0,s1$:open15,dv,15
55607 get#2,a$,a$
55610 ba=gb:forwi=1togcstep2
55620 print"{up}  process:";int(wi/gc*100)"{left}% "
55621 forwj=0to511
55622 get#2,a$:bu(wj)=asc(a$+nu$)
55623 next
55624 gosub58000
55625 gosub58900:wh=bh:wm=bm:wl=bl
55627 gosub58300:ifes>0thenwi=gc
55629 ba=ba+1:print"{up}";sp$;sp$
55630 next
55640 close2:close15
55650 ifes>0thengoto55780
55700 print"{up}  writing system header"
55710 ba=so+2
55720 open15,dv,15
55721 gosub58900:rh=bh:rm=bm:rl=bl
55723 gosub58200:ifes>0thengoto55750
55725 gosub58100
55730 open2,ga,0,s3$
55731 get#2,a$,a$
55732 for i=0 to 255
55733 get#2,a$:bu(i)=asc(a$+nu$)
55734 next
55735 close2
55740 gosub58000
55742 wh=bh:wm=bm:wl=bl:gosub58300
55750 close15
55751 ifes>0thengoto55780
55760 ifmk$=af$thengoto55770
55761 gosub9000
55762 gosub60400
55770 return
55780 print"{down}  write error: ";es
55781 gosub60400
55790 return
55800 open15,ga,15:open2,ga,0,ff$
55810 get#15,a$,b$:es=(asc(a$+nu$)-48)*10+(asc(b$+nu$)-48)
55830 close2:close15
55890 return
55900 open2,ga,0,"system header"
55910 get#2,a$,a$
55920 get#2,a$
55921 get#2,dc$,d1$,d2$,dh$,dl$
55935 fori=6to63:get#2,a$:next
55940 get#2,a$
55941 get#2,gc$,g1$,g2$,gh$,gl$
55950 close2
55960 dc=asc(dc$+nu$):dh=asc(dh$+nu$):dl=asc(dl$+nu$)
55963 d1=asc(d1$+nu$):d2=asc(d2$+nu$):db=so+(d2*256+d1)/512
55970 gc=asc(gc$+nu$):gh=asc(gh$+nu$):gl=asc(gl$+nu$)
55973 g1=asc(g1$+nu$):g2=asc(g2$+nu$):gb=so+(g2*256+g1)/512
55990 return
58000 print"  ";
58010 forip=0to511step32:print".";:gosub58500:next
58020 print:print"{up}";sp$;sp$;"{up}"
58090 return
58100 print"  ";
58110 forip=0to511step32:print".";:gosub58400:next
58120 print:print"{up}";sp$;sp$;"{up}"
58190 return
58200 by=rh:gosub60200:rh$=he$
58201 by=rm:gosub60200:rm$=he$
58202 by=rl:gosub60200:rl$=he$
58220 he$="280000"+rh$+rm$+rl$+"00000100":gosub60100:sc$=by$
58230 gosub59800
58290 return
58300 by=wh:gosub60200:wh$=he$
58301 by=wm:gosub60200:wm$=he$
58302 by=wl:gosub60200:wl$=he$
58320 he$="2a0000"+wh$+wm$+wl$+"00000100":gosub60100:sc$=by$
58330 gosub59800
58390 return
58400 j=0:goto58450
58410 j=2
58450 ad=sb+ip+j:hi=int(ad/256):lo=ad-hi*256
58470 print#15,"m-r"chr$(lo)chr$(hi)chr$(32-j)
58480 fori=jto31:get#15,a$:bu(ip+i)=asc(a$+nu$):next
58490 return
58500 j=0:goto58550
58510 j=2
58550 ad=sb+ip+j:hi=int(ad/256):lo=ad-hi*256
58570 sc$="":fori=jto31:sc$=sc$+chr$(bu(ip+i)):next
58580 print#15,"m-w"chr$(lo)chr$(hi)chr$(32-j)sc$
58590 return
58800 fori=0to511:bu(i)=0:next:return
58900 bh=int(ba/65536)
58901 bm=int((ba-bh*65536)/256)
58902 bl=ba-bh*65536-bm*256
58940 return
58950 ba=bh*65536+bm*256+bl
58990 return
59100 he$="000000000000":gosub60100:sc$=by$
59110 open15,dv,15
59120 gosub59900:get#15,a$:es=asc(a$+nu$)
59130 close15
59190 return
59200 he$="120000002400":gosub60100: sc$=by$
59210 open15,dv,15
59220 gosub59900
59230 print#15,"m-r"chr$(sl)chr$(sh)chr$(36)
59240 get#15,a$:si(sd)=asc(a$+nu$)
59241 get#15,a$:sm(sd)=asc(a$+nu$)
59242 get#15,a$,a$,a$,a$,a$,a$
59250 sv$(sd)="":sp$(sd)="":sr$(sd)=""
59251 fori=0to7:get#15,a$:gosub60300:sv$(sd)=sv$(sd)+a$:next
59252 fori=0to15:get#15,a$:gosub60300:sp$(sd)=sp$(sd)+a$:next
59253 fori=0to3:get#15,a$:gosub60300:sr$(sd)=sr$(sd)+a$:next
59260 close15
59290 return
59300 he$="030000001b00":gosub60100:sc$=by$
59320 gosub59800:ifes>0thengoto59390
59330 print#15,"m-r"chr$(sl)chr$(sh)chr$(28)
59331 fori=0to27:get#15,a$:ec(i)=asc(a$+nu$):next
59340 print"  scsi status:";
59341 by=ec( 0)and127:gosub60200:print" ";he$;
59342 by=ec( 2)and 15:gosub60200:print" ";he$;
59343 by=ec(12):gosub60200:print" ";he$
59350 print"  block address:";
59351 forba=3to6:by=ec(ba):gosub60200:print" ";he$;:next
59352 print
59390 return
59400 he$="25000000000000000000":gosub60100:sc$=by$
59410 gosub59800:ifes>0thengoto59440
59420 print#15,"m-r"chr$(sl)chr$(sh)chr$(4)
59421 get#15,a$,bh$,bm$,bl$
59430 bh=asc(bh$+nu$)
59431 bm=asc(bm$+nu$)
59432 bl=asc(bl$+nu$)
59433 bl=bl+1:ifbl>255thenbl=0:bm=bm+1
59434 ifbm>255thenbm=0:bh=bh+1
59435 tb=bh*65536+bm*256+bl
59440 return
59450 gosub59400:ifes>0thengoto59490
59460 print"  total count of 512-byte blocks:"
59461 print"  dez:";tb;" / hex:";
59462 by=bh:gosub60200:print" $";he$;":";
59463 by=bm:gosub60200:printhe$;
59464 by=bl:gosub60200:printhe$
59470 print
59471 print"  total count of bytes:"
59472 print" ";int(tb*512/1000/1000);"{left}mb";
59473 print"  (1mb = 1.000.000 bytes){down}"
59490 return
59500 he$="1b0000000300":gosub60100:sc$=by$
59510 open15,dv,15
59520 gosub59800
59530 close15
59590 return
59600 es=0:ifsm(sd)=0thengoto59690
59610 he$="1b0100000200":gosub60100:sc$=by$
59611 goto59670
59650 es=0:ifsm(sd)>0thengoto59690
59660 he$="1b0100000000":gosub60100:sc$=by$
59670 open15,dv,15
59671 gosub59800
59674 close15
59690 return
59800 ec=2
59810 gosub59900:get#15,a$:es=asc(a$+nu$)
59820 ifes>0thenec=ec-1:ifec>0thengoto59810
59890 return
59900 print#15,"s-c"chr$(sd)chr$(sl)chr$(sh)sc$:return
60100 by$="":fori=1tolen(he$)step2
60110 hi=asc(mid$(he$,i+0,1))-48:ifhi>9thenhi=hi-7
60120 lo=asc(mid$(he$,i+1,1))-48:iflo>9thenlo=lo-7
60130 by$=by$+chr$(hi*16+lo)
60140 next
60190 return
60200 he$=""
60210 i=(byand240)/2/2/2/2
60220 gosub60240
60230 i=(byand15)
60240 he$=he$+mid$("0123456789abcdef",i+1,1)
60290 return
60300 ifasc(a$)>=96thena$=chr$(asc(a$)-32)
60390 return
60400 gosub9010
60410 getkb$:ifkb$<>chr$(13)thengoto60410
60420 print"{up}";sl$;"{up}"
60440 return
