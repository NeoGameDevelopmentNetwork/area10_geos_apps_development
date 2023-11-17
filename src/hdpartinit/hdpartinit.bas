; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

0 rem partition creation tool for cmd-hd
1 vn$="hdpartinit":vd$="(w)2020 by m.k.":vv$="v0.05"
10 sp$="          "
11 tt$=" "+vn$+" - "+vv$+" / "+vd$+sp$+sp$+sp$+sp$
12 tt$="{clr}{rvon}"+left$(tt$,39)+"{rvof}{down}{down}"
100 ts=162
110 af$="f":ap=1
120 dimpt(254),pn$(254),ps(254),pa(254)
121 dimpp(254)
130 hm=254
131 mp=16
200 so=-1
210 pl=-1
220 cd$="hd.ini"
221 cf$=cd$
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
810 dim bu(512)
900 ch$="0123456789"
901 ch$=ch$+"abcdefghijklmnopqrstuvwxyz"
902 ch$=ch$+"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
903 ch$=ch$+".-_#~=!%&"
990 nu$=chr$(0)
1000 if(abs(peek(65533)=255)=0)thengoto1100
1010 key 1,chr$(133):key 3,chr$(134):key 5,chr$(135):key 7,chr$(136)
1011 key 2,chr$(137):key 4,chr$(138):key 6,chr$(139):key 8,chr$(140)
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
1555 ifmk$=chr$(139)thengosub48500:goto1505
1560 ifmk$="d"thengosub10100:goto1505
1561 ifmk$="e"thengosub10300:goto1505
1562 ifmk$="l"thengosub30200:goto1505
1563 ifmk$="s"thengosub30000:goto1505
1564 ifmk$="c"thengosub30100:goto1505
1565 ifmk$="p"thengosub31000:goto1505
1566 ifmk$="w"thengosub35000:goto1505
1567 ifmk$="v"thengosub30400:goto1505
1568 ifmk$="$"thengosub15000:goto1505
1580 ifmk$="i"thengosub32000:goto1505
1581 ifmk$="r"thengoto1630
1582 ifmk$="+"ormk$="*"ormk$="f"thengoto1600
1583 ifmk$="4"ormk$="7"ormk$="8"ormk$="n"thengoto1620
1584 ifmk$="m"ormk$="0"ormk$="b"thengoto1620
1585 ifmk$="a"thenap=1-ap:goto1520
1590 goto1540
1600 ifpf<0thengosub30300
1601 ifpf=0thengosub38090:goto1530
1602 ifmk$="+"thengosub39100
1603 ifmk$="*"thengosub39150
1604 ifmk$="f"thenpn=1:gosub39000
1605 gosub1850
1610 goto1540
1620 ifpf<0thengosub30300
1630 ifmk$="4"thengosub38000
1631 ifmk$="7"thengosub38010
1632 ifmk$="8"thengosub38020
1633 ifmk$="m"thengosub38025
1634 ifmk$="n"thengosub38030
1635 ifmk$="0"thengosub38040
1636 ifmk$="b"thengosub38045
1640 ifmk$="r"thengosub38100
1650 goto1505
1700 ifes>=0thengoto1500
1710 end
1790 print"{clr}good bye!":end
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
1850 sz$=po$+"{rvon} "
1851 sz$=sz$+"hd:"+mid$(str$(dd),2)+":"+chr$(48+sd)+" "
1852 sz$=sz$+"- l:"+mid$(str$(ga),2)+" "
1860 ifpf<0thengosub30300
1861 sz$=sz$+"- p:"+mid$(str$(pf),2)+" "
1870 if(so<0)or(tb<=0)thengoto1880
1871 sz$=sz$+"- f:"+mid$(str$(br*2),2)
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
9560 print"  create new partition:{down}":return
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
10071 pl=-1:so=-1:tb=-1
10080 gosub50900
10090 return
10100 printtt$
10110 printleft$(po$,5)
10111 print"  must be a device between 8 and 29."
10112 print"  (do not use active cmd-hd:";dv;"{left}){down}"
10113 print"  enter '0' to return to menu."
10114 printleft$(po$,4)
10120 print"{up}";sl$
10121 input"{up}  load config from device";ga
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
10300 printtt$
10310 printleft$(po$,5)
10311 print"  enter new configuration filename.{down}"
10312 print"  up to 16 characters are allowed,"
10313 print"  default filename is '";cd$;"'.{down}"
10314 print"  name without file extension '.ini'!{down}"
10315 print"  leave blank to return to menu."
10316 printleft$(po$,4)
10320 print"{up}";sl$
10321 a$="":input"{up}  new filename";a$
10323 ifa$=""thengoto10390
10330 j=len(a$):fori=1toj
10331 b$=mid$(a$,i,4)
10332 ifb$=".ini"thena$=left$(a$,i-1):i=j
10333 next
10340 j=len(a$):fori=1toj
10341 b$=mid$(a$,i,1)
10342 es=0:forii=1tolen(ch$)
10343 ifmid$(a$,i,1)=mid$(ch$,ii,1)thenes=1:ii=len(ch$)
10344 next
10345 ifes=0theni=j
10346 next
10350 ifes>0then10380
10360 printtt$
10361 print"{down}  invalid config file name!"
10362 print"    -> 34 syntax error 01 00{down}"
10370 gosub60400
10371 goto10300
10380 cf$=left$(left$(a$,12)+".ini",16)
10390 return
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
11090 pl=-1:br=-1:so=-1:return
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
12061 pl=-1:so=-1:tb=-1
12080 gosub60400
12090 return
13900 print"    cmd-hd  :";dv
13901 print"    scsi id :";sd
13903 print"    vendor  : '";sv$(sd);"'"
13904 print"    product : '";sp$(sd);"'{down}"
13909 return
15000 open1,ga,15:close1
15010 ifst=0thengoto15100
15020 printtt$:print"  hd.ini config directory:{down}"
15030 print"  error:"
15035 print"  device not present!"{down}"
15040 goto15300
15100 open1,ga,0,"$:*.ini=s"
15110 get#1,a$,a$:e$=chr$(0)
15200 i=0:printtt$:print"  hd.ini config directory:{down}"
15210 get#1,a$,a$,h$,l$:ifstthenclose1:print:goto15300
15220 print"{left}"asc(h$+nu$)+256*asc(l$+nu$);
15230 fors=0to1:get#1,a$,b$:ifa$thenprinta$b$;:s=abs(st):next
15240 printa$:i=i+1
15250 ifi>16thenprint:gosub60400:goto15200
15260 goto15210
15300 ifi>0thengosub60400
15390 return
30000 printtt$:print"  saving config '";cf$;"'..."
30001 open1,ga,15:close1
30002 ifst>0thenes=st:e$="device error":tr=-1:se=-1:goto30082
30010 open15,ga,15:open2,ga,2,"@0:"+cf$+",s,w"
30011 input#15,es,e$,tr,se
30012 ifes<>0thengoto30080
30020 forii=1tohm
30030 ifpt(ii)=0thengoto30060
30040 print#2,ii;",";pn$(ii);",";pt(ii);",";ps(ii)
30060 next
30080 close2:close15
30081 ifes=0thengosub9000:goto30085
30082 print"{down}  unable to write partitions to file!"
30083 print"    ->";es;e$;tr;se;"{down}"
30085 gosub60400
30090 return
30100 printtt$:gosub9500
30110 gosub38800
30120 gosub30300
30190 return
30200 printtt$:print"  loading config '";cf$;"'...{down}"
30201 open1,ga,15:close1
30202 ifst<>0thenes=st:e$="device error":tr=-2:se=-1:goto30285
30210 gosub38800
30220 es=0:br=-1:pc=0
30221 ifso>0theniftb>0thenbr=tb
30230 open15,ga,15
30231 open2,ga,2,cf$+",s,r"
30232 input#15,es,e$,tr,se
30233 if(es<>0)thengoto30276
30235 get#2,a$
30236 if(st>0)thengoto30276
30237 close2
30240 open2,ga,2,cf$+",s,r"
30250 input#2,pn,pn$,pt,ps
30260 ifpt<1orpt>7thenes=127:e$="bad partition":tr=pt:se=pn:goto30276
30261 ifpt=2thenps=684/2:goto30270
30262 ifpt=3thenps=1366/2:goto30270
30263 ifpt=4orpt=5thenps=3200/2:goto30270
30264 ifps<128thenps=128:goto30268
30265 ifps>32768thenps=32768
30266 if(pt=1)and(ps>32640)thenps=32640
30268 ps=int(ps/128)*128
30270 ifso>0theniftb>0thenif(br-ps)<0thengoto30275
30271 pc=pc+1:pn$(pn)=pn$:pt(pn)=pt:ps(pn)=ps
30272 iftb>0thenbr=br-ps
30275 if(pc<hm)thenif(st=0)then30250
30276 close2:close15
30280 ifes>0thengoto30285
30281 print"  imported partitions:";pc;"{up}"
30282 gosub9000
30283 gosub30300
30284 goto30288
30285 print"{down}  unable to read partitions from file!"
30286 print"    ->";abs(es);e$;abs(tr);abs(se);"{down}"
30288 gosub60400
30290 return
30300 pf=-1:br=-1
30301 ifso>0theniftb>0thenbr=tb
30310 forii=0tohm
30320 if(ii>0)and(pt(ii)=0)and(pf=<0)thenpf=ii
30330 ifpt(ii)=0thengoto30380
30340 iftb>0thenbr=br-ps(ii)
30380 next
30390 return
30400 printtt$:print"  validating partition data:{down}"
30401 es=0:ifso<0thengosub51400:ifes>0thenso=-1:tb=-1:goto30410
30405 open15,dv,15
30406 gosub59450
30407 gosub51800
30408 close15
30410 print"{down}  validate in progress...{down}"
30411 es=0:pf=-1
30412 ifso>0theniftb>0thenbr=tb
30420 forii=0tohm
30421 print"{up}  partition:";ii;"{left} "
30422 if(pt(ii)=0)and(pf=<0)thenpf=ii
30423 if(pt(ii)=0)thengoto30470
30424 if(pt(ii)=255)thengoto30442
30430 ifpt(ii)<1orpt(ii)>7thengoto30450
30431 ifpt(ii)=2thenps(ii)=684/2:goto30440
30432 ifpt(ii)=3thenps(ii)=1366/2:goto30440
30433 ifpt(ii)=4orpt(ii)=5thenps(ii)=3200/2:goto30440
30434 ifps(ii)<128thenps(ii)=128:goto30438
30435 ifps(ii)>32768thenps(ii)=32768
30436 if(pt(ii)=1)and(ps(ii)>32640)thenps(ii)=32640
30438 ps(ii)=int(ps(ii)/128)*128
30440 iflen(pn$(ii))>16thenpn$(ii)=left$(pn$(ii),16)
30441 iftb>0thenif(br-ps)<0thengoto30450
30442 iftb>0thenbr=br-ps(ii)
30443 goto30470
30450 es=es+1:pn$(ii)="":pt(ii)=0:ps(ii)=0:pa(ii)=0
30470 next
30471 gosub9000
30472 ifes=0thengoto30480
30473 print"{down} ";es;"partitions bad/removed!{down}"
30480 gosub60400
30490 return
31000 gosub31200
31015 pc=0:px=0:pb=-1:k$=""
31020 forpn=1tohm
31030 ifpt(pn)=0thengoto31060
31031 printright$(sp$+str$(pn),4);" ";
31043 printleft$("'"+pn$(pn)+"'"+sp$+sp$,18);
31047 printright$(sp$+str$(ps(pn)*2),6);" ";
31048 pt=pt(pn):gosub48900:printpt$
31050 px=px+1:pc=pc+1:ifpc<mpthengoto31060
31051 printleft$(po$,25);
31052 print"  <return> next page    <";chr$(95);"> main menu";
31053 getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto31053
31054 ifk$=chr$(13)thengoto31059
31055 ifk$=chr$(95)thenpn=254:goto31060
31056 goto31053
31059 pc=0:gosub31200
31060 next
31061 close15
31064 ifk$=chr$(95)thengoto31090
31065 if(px=0)thengoto31075
31066 if(pc>0)thengoto31080
31070 print"{down}{down}";:gosub9510
31071 goto31080
31075 print"{down}{down}      no partitions found!"
31080 printleft$(po$,25);"  press <return> to continue.";
31081 getk$:ifk$<>chr$(13)thengoto31081
31090 return
31200 printtt$
31210 print"  partition configuration{down}"
31220 print"  nr  partition          size type"
31230 printli$
31240 fori=0to15:printsl$:next
31250 printli$
31260 printsl$;left$(po$,7)
31290 return
32000 printtt$:print"  import partitions:{down}"
32005 es=0:ifso<0thengosub51400:ifes>0thengoto32190
32010 print"  reading partition table"
32011 print"  ";
32015 gosub38800
32020 open15,dv,15
32030 pc=0:pb=-1:pf=-1
32040 forii=0tohm
32050 pt(ii)=0:pn$(ii)="":ps(ii)=0:pa(ii)=0
32060 ba=so+128+int(ii/16)
32100 ifpb=bathengoto32110
32101 print".";
32102 gosub58900:rh=bh:rm=bm:rl=bl
32103 pb=ba:gosub58200
32110 ip=(ii and 15)*32
32120 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
32122 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
32123 get#15,a$:pt(ii)=asc(a$+nu$)
32124 ifpf<0thenifpt(ii)=0thenpf=ii
32125 ifpt(ii)=0thengoto32180
32130 ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
32131 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
32132 b$="":forj=0to15
32133 get#15,a$:a=asc(a$+chr$(0))
32134 ifa>0anda<>160thenb$=b$+a$
32135 next
32136 pn$(ii)=b$
32160 ad=sb+ip+29:hi=int(ad/256):lo=ad-hi*256
32161 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
32162 get#15,a$:bh=asc(a$+nu$)
32163 get#15,a$:bm=asc(a$+nu$)
32164 get#15,a$:bl=asc(a$+nu$)
32165 gosub58950
32166 ps(ii)=ba
32170 if(pt(ii)<>255)and(pt(ii)>0)thenpc=pc+1
32180 next
32181 print
32182 print"{up}";sp$;sp$;"{up}"
32183 close15
32184 print"{down}  imported partitions:";pc;"{up}"
32185 gosub9000
32186 pn=1:gosub39000
32187 gosub30300
32188 gosub60400
32190 return
35000 printtt$:print"  init partition table:{down}"
35010 dv=dd:gosub13900
35020 print"  this will clear the current partition"
35021 print"  table on the selected scsi device.{down}"
35022 print"  warning: continuing will cause any"
35023 print"  data and partitions to be lost!{down}"
35030 print"  press <s> to select new scsi device."
35031 print"  continue (y/n/s)?"
35040 getkb$:ifkb$=""thengoto35040
35041 if(kb$="y")or(kb$="Y")thengoto35100
35042 if(kb$="n")or(kb$="N")thengoto35490
35043 if(kb$="s")or(kb$="S")thengosub11000:goto35000
35050 goto35040
35100 printtt$
35110 es=0:ifso<0thengosub51400:ifes>0thengoto35490
35200 print"  writing partition table and"
35201 print"  formatting partitions.{down}"
35202 print"  please be patient, this may take"
35203 print"  some time...{down}{down}"
35210 pn=0:gosub49200:ifes>0thengoto35475
35211 bh=bu(ip+29):bm=bu(ip+30):bl=bu(ip+31)
35212 gosub58950:pa=so+ba
35220 open15,dv,15
35221 gosub59400
35222 close15
35300 forpn=1tohm
35310 print"{up}  creating partitions";int(pn*100/hm);"{left}% "
35320 pa(pn)=pa:gosub35500:pa=pa+ps(pn)
35325 gosub49400
35330 ifpt(pn)<1orpt(pn)>4thengoto35370
35332 gosub52000:ifes>0thengoto35345
35333 gosub50570
35340 es=0:open15,dv,15
35341 print#15,"cp"+mid$(str$(pn),2)
35342 input#15,es,e$,tr,se:ifes>2thentr=pn:se=0:goto35345
35343 print#15,"n:"+pn$(pn)+",hd"
35344 input#15,es,e$,tr,se:ifes>0thentr=pn:se=0:goto35345
35345 close15
35346 ifes>0thenpn=hm
35370 next
35371 ifes>0thengoto35475
35380 print"{up}";sp$;sp$
35390 pl=-1
35400 print"{up}  updating partition table"
35401 gosub52000:ifes>0thengoto35475
35410 gosub50500
35420 gosub9000
35430 goto35480
35475 gosub9200
35476 print"    ->";es;e$;tr;se;"{down}"
35480 gosub60400
35490 return
35500 ip=(pn and 15)*32
35510 fori=2to31:bu(ip+i)=0:next
35520 ifpt(pn)=0thengoto35590
35521 bu(ip+ 2)=pt(pn)
35530 pn$=left$(pn$(pn),16)
35531 iflen(pn$)<16thenpn$=pn$+chr$(160):goto35531
35532 fori=0to15:bu(ip+ 5+i)=asc(mid$(pn$,i+1,1)):next
35540 ba=pa(pn):gosub58900
35541 bu(ip+21)=bh:bu(ip+22)=bm:bu(ip+23)=bl
35550 ba=ps(pn):gosub58900
35551 bu(ip+29)=bh:bu(ip+30)=bm:bu(ip+31)=bl
35590 return
38000 pt=2:pr=684/2:goto38050
38010 pt=3:pr=1366/2:goto38050
38020 pt=4:pr=3200/2:goto38050
38025 pt=5:pr=3200/2:goto38050
38030 pt=1:pr=(255*256)/2:goto38050
38040 pt=7:pr=(256*256)/2:goto38050
38045 pt=6:pr=(256*256)/2
38050 printtt$
38051 gosub9560
38052 dv=dd:gosub13900
38055 ifpf<1thenes=1:goto38090
38060 pn=pf
38065 gosub48900
38070 ifpt<>1andpt<>6andpt<>7thengoto38080
38071 ifap=0thengosub38300
38072 if(tb>0)and(pr>br)thenpr=br
38073 ifpr=0thengoto38095
38074 ifpr<(256/2)thenpr=(256/2)
38075 ifpt=1andpr>((255*256)/2)thenpr=((255*256)/2)
38076 ifpt=6andpr>((256*256)/2)thenpr=((256*256)/2)
38077 ifpt=7andpr>((256*256)/2)thenpr=((256*256)/2)
38080 if(tb>0)and(pr>br)thengoto38095
38081 gosub38200:ifpn$=""thengoto38099
38082 gosub38400
38083 if(tb>0)thenbr=br-pr
38084 return
38090 printtt$:print"{down}  no more free partition!"
38091 goto38098
38095 printtt$:print"{down}  not enough free blocks!"
38098 gosub60400
38099 return
38100 printtt$:print"  remove partition from config:{down}"
38110 input"  which partition (1-254) ";pn
38111 if(pn<1)or(pn>254)thengoto38199
38112 ifpt(pn)=0thengoto38199
38120 printli$
38121 printright$(sp$+str$(pn),4);" ";
38122 print"'";pn$(pn);"'";
38125 printright$(sp$+str$(ps(pn)*2),6);" ";
38126 pt=pt(pn):gosub48900:printpt$
38127 printli$;"{down}"
38130 print"  delete partition (y/n) ? ";
38140 getkb$:ifkb$=""thengoto38140
38141 if(kb$="y")or(kb$="Y")thengoto38150
38142 if(kb$="n")or(kb$="N")thengoto38199
38143 goto38140
38150 printkb$;"{down}"
38160 pt(pn)=0:pn$(pn)="":ps(pn)=0:pa(pn)=0
38190 print"  partition deleted!"
38191 gosub30300
38195 gosub51800
38199 return
38200 gosub48900
38201 ifap=0thengoto38250
38210 by=pf:gosub60200
38220 pn$=pt$+"#"+he$
38230 goto38290
38250 printtt$
38251 print"  create new ";pt$;"-mode partition{down}{down}"
38252 print"  please enter partition name:"
38253 print"  (leave blank to go back to menu){down}"
38254 printleft$(po$,20)
38255 print"  note: only 16 characters or less are"
38256 print"        allowed. it is recommended to"
38257 print"        use letters and numbers only."
38260 printleft$(po$,10);"  ";
38270 pn$="":inputpn$
38280 iflen(pn$)>16thengoto38260
38290 return
38300 printtt$
38301 print"  create new ";pt$;"-mode partition{down}"
38302 print"  free blocks remaining: ";
38303 iftb>0thenprintbr*2
38304 iftb<=0thenprint"unknwon"
38310 printleft$(po$,13);
38311 print"  press +/-/* to change partiton size,"
38312 print"  press <x> to go back to menu or"
38313 gosub9010
38320 pr=1024
38321 px=32640:ifpt=6orpt=7thenpx=32768
38330 printleft$(po$,9);
38331 print"  new partition size:";pr*2;"{left} blocks   "
38332 print"  ( about";pr*512/1024;"{left} kb )    "
38340 getkb$:ifkb$=""thengoto38340
38350 ifkb$="+"thenpr=pr+128:ifpr>pxthenpr=128
38351 ifkb$="-"thenpr=pr-128:ifpr<128thenpr=px
38352 ifkb$="*"thenpr=pr+1024:ifpr>pxthenpr=128
38360 if(tb>0)and(pr>br)thenpr=br
38370 ifkb$="x"thenpr=0:goto38390
38380 ifkb$<>chr$(13)thengoto38330
38390 return
38400 printtt$
38410 gosub9560
38411 print"    partition :";pn
38412 print"    name      : ";pn$
38413 print"    type      : ";pt$
38414 print"    size      :";pr*2;"blocks{down}"
38420 pt(pn)=pt:pn$(pn)=pn$:ps(pn)=pr:pa(pn)=0
38430 gosub39000
38440 print"  partition created!{down}"
38450 ifap=0thengoto38460
38451 gosub51800
38452 goto38490
38460 gosub60400
38490 return
38800 forii=1tohm
38810 pn$(ii)="":pt(ii)=0:ps(ii)=0:pa(ii)=0
38820 next
38890 return
39000 pf=-1:fori=pnto254
39001 ifpt(i)=0thenpf=i:i=254
39002 next
39010 if(pf>0)or(pn=1)thengoto39090
39020 fori=1topn
39021 ifpt(i)=0thenpf=i:i=pn
39022 next
39090 return
39100 pn=pf+1:ifpn>254thenpn=1
39101 goto39000
39150 pn=pf+10:ifpn>254thenpn=1
39151 goto39000
40900 ifpl>=0thengoto40990
40910 gosub48000
40990 return
48000 es=0:ifso<0thengosub51400:ifes>0thengoto48190
48010 print"  analyzing partition table"
48011 print"  ";
48020 open15,dv,15
48030 pc=0:pa=0:ps=0:pb=-1:pl=-1
48040 forii=0tohm
48050 pp(ii)=0
48060 ba=so+128+int(ii/16)
48100 ifpb=bathengoto48110
48101 print".";
48102 gosub58900:rh=bh:rm=bm:rl=bl
48103 pb=ba:gosub58200
48110 ip=(ii and 15)*32
48120 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
48122 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
48123 get#15,a$:pp(ii)=asc(a$+nu$)
48124 ifpp(ii)>0thenpl=ii
48180 next
48181 print
48182 print"{up}";sp$;sp$;"{up}"
48183 close15
48190 return
48500 if(so>=0)thenifpl>0thengoto48510
48501 printtt$:print"  partition menu:{down}"
48502 dv=dd:gosub13900
48503 es=0:ifso<0thengosub51400:ifes>0thengoto48590
48504 gosub40900:ifes>0thengoto48590
48510 gosub48600
48515 pc=0:px=0:pb=-1:k$=""
48516 open15,dv,15
48520 forpn=1tohm
48530 ifpp(pn)=0thengoto48560
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
48548 pt=pp(pn):gosub48900:printpt$
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
49420 open15,dv,15:gosub58500:close15
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
50500 gosub 50580
50510 print"  cmd-hd device address: ";
50511 printmid$(str$(dv),2);":";chr$(48+sd)
50520 return
50570 dv=h1
50580 ifh2=0thengoto50590
50582 open15,dv,15,"s-"+chr$(48+h2):close15
50585 dv=h2
50590 ifh3=0thengoto50599
50592 open15,dv,15,"u0>"+chr$(h3):close15
50595 dv=h3
50599 return
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
51474 tb=-1:pt(0)=0:pn$(0)="error":ps(0)=0:pa(0)=0
51475 es=128:return
51480 print"ok! "
51481 print"  found system area at offset:";so;"{down}"
51482 pt(0)=255:pn$(0)="system":ps(0)=144:pa(0)=so
51483 es=0:return
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
58320 he$="2e0000"+wh$+wm$+wl$+"00000100":gosub60100:sc$=by$
58330 gosub59800
58390 return
58400 j=0:goto58450
58410 j=2
58450 ad=sb+ip+j:hi=int(ad/256):lo=ad-hi*256
58470 print#15,"m-r"chr$(lo)chr$(hi)chr$(32-j)
58480 fori=jto31:get#15,a$:bu(ip+i)=asc(a$+nu$):next
58490 return
58500 j=2
58550 ad=sb+ip+j:hi=int(ad/256):lo=ad-hi*256
58570 sc$="":fori=jto31:sc$=sc$+chr$(bu(ip+i)):next
58580 print#15,"m-w"chr$(lo)chr$(hi)chr$(32-j)sc$
58590 return
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
