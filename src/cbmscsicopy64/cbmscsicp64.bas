; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

0 rem partition copy tool for cmd-hd and attached scsi devices
1 vn$="cbmscsicopy64":vd$="(w)2020 by m.k.":vv$="v0.10"
10 sp$="          "
11 tt$=vn$+" "+vv$+" "+vd$
12 tt$=right$(sp$+sp$+tt$,len(tt$)+(20-(len(tt$)/2)))
13 tt$="{clr}"+tt$+"{down}"
100 ts=162
110 hs=-1:ht=-1
120 cs=-1:ct=-1
130 fs=-1:ft=-1:fm=-1
140 os=-1:ot=-1
150 s0=-1:t0=-1
160 s1=-1:t1=-1
200 so=-1
300 dimty$(9)
301 ty$(0)="del":ty$(1)="seq":ty$(2)="prg"
302 ty$(3)="usr":ty$(4)="rel":ty$(5)="cbm"
303 ty$(6)="dir":ty$(9)="???"
400 sl$=left$(sp$+sp$+sp$+sp$,37)
410 li$="":fori=0to36:li$=li$+chr$(192):next
411 c0$=chr$(176):c1$=chr$(174)
412 c2$=chr$(173):c3$=chr$(189)
413 vi$=chr$(125)
420 po$="{home}":fori=0to23:po$=po$+"{down}":next
430 ta$="":fori=0to38:ta$=ta$+"{right}":next
440 gf$=chr$(34)
500 dimpd$(9)
501 pd$(0)="null"
502 pd$(1)="natm":pd$(2)="1541":pd$(3)="1571":pd$(4)="1581"
503 pd$(5)="cp/m":pd$(6)="prnt":pd$(7)="fmod"
504 pd$(8)="sysp":pd$(9)="????"
600 ga=peek(186):es=0:dv=0:dd=0
610 dim hd(30):hc=0:hd=30
700 sb=12288:sh=int(sb/256):sl=sb-sh*256
800 dim si(6),sm(6),sv$(6),sp$(6),sr$(6)
810 dim bu(512),ec(28)
990 nu$=chr$(0)
1000 if(abs(peek(65533)=255)=0)thengoto1100
1010 key 1,chr$(133):key 3,chr$(134):key 5,chr$(135):key 7,chr$(136)
1011 key 2,chr$(137):key 4,chr$(138):key 6,chr$(139):key 8,chr$(140)
1020 goto1200
1100 poke53280,0:poke53281,0:poke646,5
1200 print"{clr}"
1210 rem ifpeek(57513)=120then: ::@p0:
1500 printtt$
1505 gosub1800
1510 ifdv=0thengosub10200:ifes<>0thenstop
1520 ifhs>=0thengoto1530
1521 gosub50600
1522 hs=sd:gosub3150:ht=sd
1530 es=0
1535 gosub2000
1540 getmk$:ifmk$=""thengoto1540
1541 ifmk$=chr$(95)thengoto1790
1550 ifmk$="h"thengosub3000:goto1700
1551 ifmk$=chr$(133)thengosub3100:goto1530
1552 ifmk$=chr$(134)thengosub3110:goto1530
1553 ifmk$=chr$(137)andhs>=0thensd=hs:so=os:gosub48500:goto1500
1554 ifmk$=chr$(138)andht>=0thensd=ht:so=ot:gosub48500:goto1500
1555 ifmk$=chr$(135)thengosub3300:goto1530
1556 ifmk$="+"thengosub3310:goto1530
1557 ifmk$=chr$(136)andcs>0thengosub3400:goto1530
1558 ifmk$="*"andcs>0thengosub3410:goto1530
1559 ifmk$=chr$(139)thengosub3600:goto1530
1560 ifmk$=chr$(140)thengosub3700:goto1530
1565 ifmk$="c"thengosub20000:goto1530
1570 if(mk$="s")and(hs>=0)and(cs>0)thengosub30000:goto1500
1571 if(mk$="t")and(ht>=0)and(ct>0)thengosub30100:goto1500
1580 ifmk$="a"thengosub10300:goto1530
1581 ifmk$="b"thengosub10350:goto1530
1590 goto1540
1700 ifes>=0thengoto1520
1710 end
1790 print"{clr}good bye!":end
1800 gosub1900
1801 gosub1910
1802 gosub1920
1803 gosub1930
1850 printleft$(po$,17);
1851 print"  f1/f3 - source/target scsi device"
1852 print"  f2/f4 - source/target partition list"
1853 print"  f5/f7 - source/target partition +1"
1854 print"  f6/f8 - enter source/target part."
1855 print"  + / * - source/target partition +10"
1856 print"  c / h - begin copying/select cmd-hd"
1857 print"  s / t - source/target directory"
1858 print"  a / b - eject source/target media"
1859 print"  _     - exit program";
1890 return
1900 printleft$(po$,3);
1901 printc0$;li$;c1$
1902 printvi$;sl$;vi$
1903 printc2$;li$;c3$
1904 printleft$(po$,3);left$(ta$,30);"cmd-hd"
1909 return
1910 printleft$(po$,6);
1911 printc0$;li$;c1$
1912 printvi$;sl$;vi$
1913 printvi$;sl$;vi$
1914 printc2$;li$;c3$
1915 printleft$(po$,6);left$(ta$,30);"source"
1919 return
1920 printleft$(po$,10);
1921 printc0$;li$;c1$
1922 printvi$;sl$;vi$
1923 printvi$;sl$;vi$
1924 printc2$;li$;c3$
1925 printleft$(po$,10);left$(ta$,30);"target"
1929 return
1930 printleft$(po$,14);
1931 printc0$;li$;c1$
1932 printvi$;sl$;vi$
1933 printc2$;li$;c3$
1934 printleft$(po$,14);left$(ta$,30);"status"
1939 return
2000 gosub2100
2010 gosub2200
2020 gosub2300
2030 gosub2900
2090 return
2100 printleft$(po$,3)
2110 print"{right}{right}";
2120 print"cmd-hd device:";right$("   "+str$(dd),2);
2190 return
2200 printleft$(po$,6)
2210 print"{right}{right}";
2220 print"id:";right$(str$(hs),1);"  ";
2221 print"<";sv$(hs);"> <";sp$(hs);">"
2230 ifcs<1thenprintleft$(po$,8);"{right}";sl$:goto2290
2231 print"{right}{right}";
2240 printright$("000"+mid$(str$(cs),2),3);":";sn$
2241 pt=fs:gosub48900
2242 printleft$(po$,8);left$(ta$,23);
2243 print"b:";left$(mid$(str$(s1*2),2)+sp$,6);
2244 print"t:";left$(pt$+sp$,4)
2290 return
2300 printleft$(po$,10)
2310 print"{right}{right}";
2320 print"id:";right$(str$(ht),1);"  ";
2321 print"<";sv$(ht);"> <";sp$(ht);">"
2330 ifct<1thenprintleft$(po$,12);"{right}";sl$:goto2390
2331 print"{right}{right}";
2340 printright$("000"+mid$(str$(ct),2),3);":";tn$
2341 pt=ft:gosub48900
2342 printleft$(po$,12);left$(ta$,23);
2343 print"b:";left$(mid$(str$(t1*2),2)+sp$,6);
2344 print"t:";left$(pt$+sp$,4)
2390 return
2900 printleft$(po$,14)
2910 print"{right}";sl$
2920 print"{up}{right}{right}select menu action"
2990 return
3000 dv=dd
3010 dv=dv+1:ifdv=30thendv=8
3020 ifdv=ddthengoto3090
3030 ifhd(dv)=0thengoto3010
3080 dd=dv:hs=-1:ht=-1:cs=-1:ct=-1:fs=-1:ft=-1
3090 return
3100 sd=hs:gosub3150
3101 hs=sd:cs=-1:ct=-1:fs=-1:ft=-1
3109 return
3110 sd=ht:gosub3150
3111 ht=sd:ct=-1:ft=-1
3119 return
3150 sx=sd
3151 sx=sx+1:ifsx=7thensx=0
3152 ifsx=sdthengoto3190
3153 ifsi(sx)<0thengoto3151
3154 sd=sx
3190 return
3200 ifso<0thengosub51400:ifes>0thengoto3290
3201 px=pn:ifpx<0thenpx=0
3202 gosub50700:ifes>2thengoto3290
3203 printleft$(po$,14):print"{right}";sl$
3204 print"{up}{right}{right}searching for partition..."
3205 pb=-1:pf=0
3210 open15,dv,15
3220 if(px<254)thenif((px+sk)>(254+sk-1))thenpx=254:goto3222
3221 px=px+sk:ifpx>254thenpx=1:pf=1
3222 if(px=pn)thengoto3285
3223 if((pf=1)and(px>pn))thengoto3285
3224 printleft$(po$,15);left$(ta$,34);right$("   "+str$(px),3)
3225 ba=so+128+int(px/16)
3226 ifpb=bathengoto3230
3227 gosub58900:rh=bh:rm=bm:rl=bl
3228 pb=ba:gosub58200
3230 ip=(px and 15)*32
3231 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
3232 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
3233 get#15,a$:p=asc(a$+nu$)
3234 if(p=0)or(p=255)thengoto3220
3235 iffm>0thenifp<>fmthengoto3220
3240 ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
3241 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
3242 fp$="":fori=1to16:get#15,a$:fp$=fp$+a$:next
3250 ad=sb+ip+21:hi=int(ad/256):lo=ad-hi*256
3251 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
3252 get#15,a$:bh=asc(a$+nu$)
3253 get#15,a$:bm=asc(a$+nu$)
3254 get#15,a$:bl=asc(a$+nu$)
3255 gosub58950:ax=ba
3260 ad=sb+ip+29:hi=int(ad/256):lo=ad-hi*256
3261 print#15,"m-r"chr$(lo)chr$(hi)chr$(3)
3262 get#15,a$:bh=asc(a$+nu$)
3263 get#15,a$:bm=asc(a$+nu$)
3264 get#15,a$:bl=asc(a$+nu$)
3265 gosub58950:bx=ba
3280 iffm<0thengoto3284
3281 if((fs=1)and(s1>bx))thengoto3220
3284 fm=p:pn=px:pn$=fp$
3285 close15
3290 return
3300 sk=1:goto3350
3310 sk=10
3350 fm=-1:sd=hs:so=os:pn=cs:pn$=sn$
3360 gosub3200:ifes>0thengoto3365
3361 iffm=-1thenfm=fs
3362 ifpn>0thengoto3380
3365 printleft$(po$,14):print"{right}";sl$
3366 print"{up}{right}{right}no partition found!  press <return>"
3367 pn=-1:fm=-1:sn$=""
3370 gosub60400
3380 os=so:cs=pn:fs=fm:s0=ax:s1=bx:sn$=pn$
3381 iffs<>ftthenct=-1
3390 return
3400 sk=1:goto3450
3410 sk=10
3450 fm=fs:sd=ht:so=ot:pn=ct:pn$=tn$
3460 gosub3200:ifes>0thengoto3465
3462 ifpn>0thengoto3480
3465 printleft$(po$,14):print"{right}";sl$
3466 print"{up}{right}{right}no partition found!  press <return>"
3467 pn=-1:fm=-1:tn$=""
3470 gosub60400
3480 ot=so:ct=pn:ft=fm:t0=ax:t1=bx:tn$=pn$
3490 return
3600 printleft$(po$,14):print"{right}";sl$
3610 input"{up}{right}{right}enter source partition (1-254)";a$
3620 if(val(a$)<1)or(val(a$)>254)thengoto3690
3630 gosub1930
3640 cs=val(a$)-1:gosub3300
3690 return
3700 printleft$(po$,14):print"{right}";sl$
3710 input"{up}{right}{right}enter target partition (1-254)";a$
3720 if(val(a$)<1)or(val(a$)>254)thengoto3790
3730 gosub1930
3740 ct=val(a$)-1:gosub3400
3790 return
9100 printtt$
9101 print"{down}no cmd-hd found!"
9110 print"exiting now!"
9120 return
10200 gosub50100:ifes<>0thengoto10290
10220 dv=dd:gosub50400:ifes<>0thengoto10290
10230 gosub50900
10240 gosub59200
10290 return
10300 ifhs<0thengoto10330
10310 sd=hs:gosub59600
10320 cs=-1:ct=-1:cs=0:ct=0
10330 return
10350 ifht<0thengoto10380
10360 sd=ht:gosub59600
10370 ct=-1:ct=0
10380 return
20000 ifcs<1orct<1thengoto20900
20010 iffs<>ftthengoto20910
20011 if((fs<>1)and(s1<>t1))or((fs=1)and(s1>t1))thengoto20920
20012 if(hs=ht)and(s0=t0)thengoto20940
20030 printleft$(po$,15);"{right}";sl$
20031 print"{up}{right}{right}are you really sure (y/n) ?";
20032 getk$:ifk$=""thengoto20032
20033 if(k$<>"y")and(k$<>"Y")thengoto20990
20040 printleft$(po$,15);"{right}";sl$
20041 print"{up}{right}{right}copying partition...";
20042 printleft$(po$,15);left$(ta$,37);
20050 gosub50900:as=sd
20060 open15,dv,15:print#15,"g-p":get#15,a$,b$,b$:close15
20061 at=asc(a$+chr$(0)):ap=0
20062 if(at>=0)and(at<=4)thenap=asc(b$+chr$(0))
20063 if(ap<1)or(ap>254)thenat=0:ap=0
20090 bc=s1:b0=s0:b1=t0
20100 open15,dv,15:close15:ifst<>0thenes=st:goto20930
20110 open15,dv,15
20200 print"{left}{left}{left}{left}";right$("   "+str$(int((s1-bc)*100/s1)),3);"%";
20300 bs=16:ifbs>bcthenbs=bc
20400 ba=b0:gosub58900
20410 by=bh:gosub60200:rh$=he$
20420 by=bm:gosub60200:rm$=he$
20430 by=bl:gosub60200:rl$=he$
20440 ba=bs:gosub58900
20450 by=bl:gosub60200
20490 he$="280000"+rh$+rm$+rl$+"0000"+he$+"00":gosub60100:sc$=by$
20491 sd=hs:gosub59800:ifes>0thengoto20700
20500 ba=b1:gosub58900
20510 by=bh:gosub60200:wh$=he$
20520 by=bm:gosub60200:wm$=he$
20530 by=bl:gosub60200:wl$=he$
20540 ba=bs:gosub58900
20550 by=bl:gosub60200
20590 he$="2a0000"+wh$+wm$+wl$+"0000"+he$+"00":gosub60100:sc$=by$
20591 sd=ht:gosub59800:ifes>0thengoto20700
20600 b0=b0+bs
20610 b1=b1+bs
20620 bc=bc-bs:ifbc>0thengoto20200
20700 close15
20701 ifes0thengoto20930
20710 print"{left}{left}{left}{left}100%";
20720 if(fs<1)or(fs>4)thengoto20800
20721 ifas<>htthengoto20800
20722 ifap<>ctthengoto20800
20730 printleft$(po$,14):print"{right}";sl$;"{up}"
20731 print"{right}{right}updating disk/partition info..."
20740 if(fs>1)or(s1=t1)thengoto20760
20750 open15,dv,15
20751 ba=t0+1:gosub58900:rh=bh:rm=bm:rl=bl
20752 sd=ht:gosub58200:ifes>0thengoto20790
20753 ad=sb+8:hi=int(ad/256):lo=ad-hi*256
20757 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(t1/128)
20758 wh=bh:wm=bm:wl=bl:gosub58300:ifes>0thengoto20790
20759 close15
20760 open15,dv,15
20770 print#15,"cP"+chr$(ct)
20771 input#15,a$:es=val(a$):ifes>2thengoto20790
20780 print#15,"i:"
20781 input#15,a$:es=val(a$)
20790 close15
20791 gosub51800
20795 ifes>0thengoto20930
20800 printleft$(po$,14):print"{right}";sl$;"{up}"
20810 em$="copy completed!":goto20980
20900 em$="select partitions!":goto20980
20910 em$="not compatible!":goto20980
20920 em$="different size!":goto20980
20930 em$="disk error!":goto20980
20940 em$="source=target!"
20980 printleft$(po$,14):print"{right}";sl$
20981 print"{up}{right}{right}";left$(em$+sp$+sp$+sp$+sp$,21);"press <return>"
20982 gosub60400
20990 return
30000 sd=hs:so=os:pn=cs:fm=fs:b0=s0:goto31000
30100 sd=ht:so=ot:pn=ct:fm=ft:b0=t0
31000 iffm>=1andfm=<4thengoto31010
31001 em$="not supported!"
31002 printleft$(po$,14):print"{right}";sl$
31003 print"{up}{right}{right}";left$(em$+sp$+sp$,21);"press <return>"
31004 goto32990
31010 onfmgosub39820,39800,39800,39810
31020 open15,dv,15:close15:ifst<>0thenes=st:goto32990
31030 open15,dv,15
31100 ba=b0+d0:gosub58900:rh=bh:rm=bm:rl=bl
31110 gosub58200
31120 dn$=""
31130 ad=sb+d1+d2:hi=int(ad/256):lo=ad-hi*256
31131 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
31132 fori=0to15
31133 get#15,a$:a=asc(a$+nu$)
31134 if(a<32)or((a>=128)and(a<160))thena=32
31135 if(a>=97)and(a=<122)thena=a-32
31136 dn$=dn$+chr$(a)
31137 next
31200 printtt$
31210 printleft$(po$,3);
31211 printc0$;li$;c1$
31212 printvi$;sl$;vi$
31213 printc2$;li$;c3$
31214 printleft$(po$,4);left$(ta$,2);"disk ";
31215 printright$("  "+str$(dv),2);":";mid$(str$(sd),2);
31216 print" ";chr$(34);dn$;chr$(34)
31217 printleft$(po$,4);left$(ta$,32);"p:";
31218 printright$("000"+mid$(str$(pn),2),3)
31220 gosub39600
31230 c0=0:c1=0
32000 ad=sb+d1:hi=int(ad/256):lo=ad-hi*256
32010 print#15,"m-r"chr$(lo)chr$(hi)chr$(2)
32020 get#15,a$,b$:tr=asc(a$+nu$):se=asc(b$+nu$)
32021 iftr=0thengoto32300
32030 d0=0:onfmgosub39750,39700,39700,39730
32031 d1=(((d0/2)-int(d0/2))*2)*256
32040 ba=b0+int(d0/2):gosub58900:rh=bh:rm=bm:rl=bl
32050 gosub58200:ifes>0thengoto32300
32100 forii=0to255step32
32110 ip=d1+ii
32120 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
32130 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
32131 get#15,a$:ty=asc(a$+nu$)
32140 ifty=0thengoto32190
32150 ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
32151 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
32152 ff$="":forj=0to15
32153 get#15,a$:a=asc(a$+nu$):ifa=160thenj=15:goto32156
32154 if(a<32)or((a>=128)and(a<160))thena=32
32155 if(a>=97)and(a=<122)thena=a-32
32156 ff$=ff$+chr$(a)
32157 next
32158 printleft$(po$,7+c0);left$(ta$,3);ff$
32160 ty=tyand15:ifty>6thenty=9
32161 printleft$(po$,7+c0);left$(ta$,33);ty$(ty)
32170 c1=c1+1:c0=c0+1:ifc0<16thengoto32180
32171 printleft$(po$,24);
32172 print"  <return> next page    <";chr$(95);"> main menu"
32173 getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto32173
32174 ifk$=chr$(13)thenc0=0:gosub39600
32175 ifk$=chr$(95)thenii=255:tr=0
32176 goto32190
32180 getk$:ifk$=chr$(95)thenk$="":ii=255:tr=0
32190 next
32200 iftr>0thengoto32000
32300 close15
32310 ifes>0thengoto32990
32400 ifc1=0thenprintleft$(po$,8);left$(ta$,3);"empty disk"
32410 goto39982
32990 return
39600 printleft$(po$,6);
39610 printc0$;li$;c1$
39620 fori=0to15:printvi$;sl$;vi$:next
39630 printc2$;li$;c3$
39640 printleft$(po$,24);
39641 print"  searching...    press <";chr$(95);"> to cancel";
39690 return
39700 iftr>0thend0=d0+(tr-1)*21
39701 iftr>=18andtr<25thend0=d0+(tr-17-1)*19
39702 iftr>=25andtr<31thend0=d0+(tr-7-17-1)*18
39703 iftr>=31andtr<36thend0=d0+(tr-6-7-17-1)*17
39710 iftr>=36andtr<53thend0=d0+(tr-5-6-7-17-1)*21
39711 iftr>=53andtr<60thend0=d0+(tr-17-5-6-7-17-1)*19
39712 iftr>=60andtr<66thend0=d0+(tr-7-17-5-6-7-17-1)*18
39713 iftr>=66andtr<71thend0=d0+(tr-6-7-17-5-6-7-17-1)*17
39720 d0=d0+se
39721 return
39730 d0=d0+(tr-1)*40+se
39740 return
39750 d0=d0+(tr-1)*256+se
39760 return
39800 d0=178:d1=256:d2=144:return
39810 d0=780:d1=0:d2=4:return
39820 d0=0:d1=256:d2=4:return
39900 em$="unknown error!"
39980 printleft$(po$,24);left$(ta$,2);em$;
39982 ifk$=chr$(95)thengoto39999
39983 printleft$(po$,24);sl$
39984 print"{up}  press <return> to continue."
39990 gosub60400
39999 return
48500 ifso<0thengosub51400:ifes>0thengoto48590
48501 gosub50700:ifes>2thengoto48590
48510 printtt$
48511 printleft$(po$,3);
48512 printc0$;li$;c1$
48513 printvi$;sl$;vi$
48514 printc2$;li$;c3$
48515 printleft$(po$,4);left$(ta$,2);
48516 print"  partition list: cmd-hd";str$(dv);":";chr$(48+sd)
48517 gosub39600:printleft$(po$,5)
48518 pc=0:px=0:pb=-1:mp=16
48519 open15,dv,15
48520 forpn=1to254
48521 ba=so+128+int(pn/16)
48522 ifpb=bathengoto48525
48523 gosub58900:rh=bh:rm=bm:rl=bl
48524 pb=ba:gosub58200
48525 printleft$(po$,24);left$(ta$,11);
48526 printint(100*pn/254);"{left}%";
48528 ip=(pn and 15)*32
48530 ad=sb+ip+2:hi=int(ad/256):lo=ad-hi*256
48531 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
48532 get#15,a$:pt=asc(a$+nu$)
48533 if(pt=0)or(pt=255)thengoto48560
48535 printleft$(po$,7+pc);
48540 print"{right}{right}";right$(sp$+str$(pn),4);" ";
48541 ad=sb+ip+5:hi=int(ad/256):lo=ad-hi*256
48542 print#15,"m-r"chr$(lo)chr$(hi)chr$(16)
48543 printgf$;:fori=1to16:get#15,a$:printa$;:next:printgf$;
48544 ad=sb+ip+30:hi=int(ad/256):lo=ad-hi*256
48545 print#15,"m-r"chr$(lo)chr$(hi)chr$(2)
48546 get#15,a$,b$:ba=asc(a$+nu$)*256+asc(b$+nu$)
48547 printright$(sp$+str$(ba*2),6);" ";
48548 gosub48900:printpt$
48550 px=px+1:pc=pc+1:ifpc<mpthengoto48560
48551 printleft$(po$,24);
48552 print"  <return> next page    <";chr$(95);"> main menu";
48553 getk$:if(k$<>chr$(13))and(k$<>chr$(95))thengoto48553
48554 ifk$=chr$(13)thengoto48559
48555 ifk$=chr$(95)thenpn=254:goto48561
48556 goto48553
48559 pc=0:gosub39600
48560 getk$:ifk$=chr$(95)thenk$="":pn=254
48561 next
48563 close15
48564 ifk$=chr$(95)thengoto48590
48565 if(pc>0)thengoto48580
48566 if(px=0)thengoto48575
48570 print"{down}{down}      no more partitions found!"
48571 goto48580
48575 print"{down}{down}      no partitions found!"
48580 printleft$(po$,24);"  press <return> to continue.        ";
48581 getk$:ifk$<>chr$(13)thengoto48581
48590 return
48900 ifpt=255thenpt$=pd$(8):return
48910 ifpt>7thenpt$=pd$(9):return
48920 pt$=pd$(pt):return
50100 printleft$(po$,14)
50110 print"{right}{right}scanning for cmd-hd devices...     ";
50120 es=0:hc=0:dd=0:for dv=8 to 30
50130 print"{left}{left}";right$("  "+str$(dv),2);
50132 open15,dv,15:close15
50133 hd(dv)=0:ifst<>0thengoto50140
50134 gosub50300:ifes<>0thengoto50140
50135 hd(dv)=dv:hc=hc+1:ifdd=0thendd=dv
50140 next
50150 ifhc=0thengosub9100:es=-1:goto50190
50160 es=0:ed=0:fordv=8to29
50161 ifhd(dv)=0thengoto50167
50162 gosub50400:ifes<>0thengoto50167
50163 if(h1>0)and(dv<>h1)thenes=es+1
50164 if(h2>0)thenes=es+1
50165 if(h3>0)thenes=es+1
50166 if((h1+h2+h3)>0)and(ed=0)thened=dv
50167 next
50170 ifes=0thengoto50180
50171 printleft$(po$,15);"{right}";sl$
50172 print"{up}{right}{right}";
50173 print"bad cmd-hd address!  press <return>"
50174 getk$:ifk$<>chr$(13)thengoto50174
50175 printleft$(po$,15);"{right}";sl$
50176 print"{up}{right}{right}";
50177 print"reset cmd-hd #";mid$(str$(ed),2);" and press <return>"
50178 goto50100
50180 dv=dd:gosub50400
50190 return
50300 b$="":open15,dv,15
50310 print#15,"m-r"chr$(160)chr$(254)chr$(6)
50320 fora=1to6:get#15,a$:b$=b$+a$:next
50330 close15
50350 es=0:ifb$<>"cmd hd"thenes=-1
50360 return
50400 open15,dv,15:close15:ifst<>0thenes=st:goto50490
50410 open15,dv,15
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
50600 printleft$(po$,14)
50610 print"{right}{right}scanning for scsi devices...       ";
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
50740 printleft$(po$,14):print"{right}";sl$
50741 print"{up}{right}{right}insert media: ";
50742 printright$("   "+str$(dv),2);":";mid$(str$(sd),2);
50750 print"   (x to cancel)"
50760 getk$:ifk$="x"thengoto50790
50761 gosub59100:ifes>=2thengoto50760
50790 return
50900 open15,dv,15
50910 print#15,"m-r"chr$(0)chr$(144)chr$(1)
50920 get#15,a$:a=asc(a$+nu$)/2/2/2/2
50930 sd=0:if(a>0)and(a<7)thensd=a
50940 close15
50990 return
51400 gosub50700:ifes>2thenreturn
51410 es=0:so=-1
51430 open15,dv,15
51431 gosub59400
51432 mx=int(tb*512/65536)-1
51433 ifmx>255thenmx=255
51434 ifmm<0thengoto51460
51440 printleft$(po$,14)
51441 print"{right}{right}searching for system area...   ";
51442 forbc=0tomx
51443 printright$("   "+str$(int(bc*100/mx)),3);"%{left}{left}{left}{left}";
51444 gosub51500:ifes>0thengoto51450
51445 gosub51550:ifes>0thengoto51450
51447 so=bc*128:bc=255
51450 next
51460 close15
51470 ifso>=0thengoto51480
51471 printleft$(po$,14):print"{right}";sl$
51472 print"{up}{right}{right}error! no system area found! press <return>"
51473 gosub60400
51474 es=128:return
51480 printleft$(po$,14):print"{right}";sl$
51481 print"{up}{right}{right}found system area at offset:    ";right$("   "+str$(so),3);
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
59500 he$="1b0000000300":gosub60100:sc$=by$
59510 open15,dv,15
59520 gosub59800
59530 close15
59590 return
59600 es=0:ifsm(sd)=0thengoto59690
59610 he$="1b0100000200":gosub60100:sc$=by$
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
60400 getkb$:ifkb$<>chr$(13)thengoto60400
60490 return
