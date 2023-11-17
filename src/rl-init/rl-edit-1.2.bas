; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;
; rl-edit 1.2
; This program can be used to create a partition configuration
; file for rl-init which will automatically create all the partitions
; from the configuration file and will format all partitions.
; This program will not modify any data on your ramlink.
;

  100 xt=49152
  110 rl=0:id=peek(186)
  120 dim fp%(32)
  130 dim fp$(32)
  140 dim rp$(32,4)
  150 rp=0
  160 rs=0
  199 :
  200 t0$="{grn}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{gry3}"
  900 poke53280,0:poke53281,0
  999 :
 1000 print"{blk}{clr}{gry3}ramlink installation 1.1"
 1010 printt0$
 1020 gosub 30000
 1030 gosub 29000
 1040 gosub 20000
 1050 gosub 10000
 1060 print"{blk}{clr}{gry3}ramlink installation 1.1"
 1070 printt0$
 1080 print"{down}{gry3}all done...{down}"
 1090 end
 1099 :
 1900 end
 10000 open 2,id,2,"@0:rl.ini,s,w"
 10010 for p0=1 to rp
 10020 print#2,rp$(p0,1);",";
 10030 print#2,rp$(p0,3);",";
 10040 print#2,rp$(p0,2);",";
 10050 print#2,rp$(p0,4)
 10060 next
 10070 close2:return
 10099 :
 10100 open 2,id,2,"rl.ini,s,r":rp=0:fm=mm
 10110 if(st=0)theninput#2,pn,pt,pn$,ps
 10120 ifpn$=""then10170
 10130 rp=rp+1
 10140 rp$(rp,1)=right$("  "+str$(pn),2)
 10145 rp$(rp,2)=left$(pn$+"                ",16)
 10150 rp$(rp,3)=right$("  "+str$(pt),2)
 10155 rp$(rp,4)=right$("      "+str$(ps),5)
 10160 fm=fm-ps:if(st=0)then10110
 10170 close2:goto21000
 10199 :
 10200 ifrp>0thenfm=fm+val(rp$(rp,4)):rp$(rp,1)="":rp=rp-1
 10210 goto21000
 20000 print"{blk}{clr}{gry3}ramlink installation 1.1"
 20010 printt0$:gosub 60000:gosub 51000
 20099 :
 21000 print"{blk}{clr}{gry3}ramlink installation 1.1"
 21010 printt0$:gosub21300
 21020 print"{down}{grn}-1- {gry3}partition typ native"
 21030 print"{down}{grn}-2- {gry3}partition typ 1541"
 21040 print"{down}{grn}-3- {gry3}partition typ 1571"
 21050 print"{down}{grn}-4- {gry3}partition typ 1581"
 21060 print"{down}{grn}-5- {gry3}partition typ dacc"
 21070 print"{down}{grn}-6- {gry3}partition typ 1581, 3328 blocks"
 21072 print"{grn}    {gry3}(Only for GEOSV2 and Config2RL!)"
 21075 print"{down}{grn}-7- {gry3}delete last 'rl.ini'-entry"
 21080 print"{grn}-8- {gry3}show 'rl.ini'-file data"
 21085 print"{grn}-9- {gry3}load 'rl.ini'-file from disk"
 21090 print"{grn}-0- {gry3}exit, save 'rl.ini' to disk.{down}"
 21095 printt0$:print"{gry3}hit run/stop + restore to abort!{home}"
 21099 :
 21200 poke 198,0:wait 198,1:get sp$
 21210 if sp$="0" then return
 21220 if sp$="1" then 22000
 21230 if sp$="2" then 22000
 21240 if sp$="3" then 22000
 21250 if sp$="4" then 22000
 21260 if sp$="5" then 22000
 21270 if sp$="6" then 22000
 21275 if sp$="7" then 10200
 21280 if sp$="8" then 22100
 21285 if sp$="9" then 10100
 21290 goto 21200
 21299 :
 21300 print"{blk}{clr}{gry3}ramlink installation 1.1"
 21310 printt0$"{home}{down}{grn}{CBM-R}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{CBM-R}"
 21320 print"{grn}{SHIFT--}{gry3}free blocks:      {grn}{SHIFT--}{gry3}{left}{left}{left}{left}{left}{left}{left}"fm
 21330 print"{grn}{CBM-Z}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{CBM-X}"
 21340 return
 21999 :
 22000 gosub 28900
 22010 rp=rp+1
 22020 rp$(rp,1)=right$("  "+str$(pn),2)
 22030 rp$(rp,2)=left$(pn$+"                ",16)
 22040 rp$(rp,3)=right$("  "+str$(pt),2)
 22050 rp$(rp,4)=right$("      "+str$(ps),5)
 22060 fm=fm-ps
 22070 ifrp=31thenreturn
 22080 goto21000
 22099 :
 22100 a1=0
 22110 print"{blk}{clr}{gry3}ramlink installation 1.1"
 22120 printt0$"{down}"
 22130 a2=16:ifa1>0thena2=15
 22140 fora0=1toa2:print right$("   "+str$(a1+a0),3)" - ";
 22150 if(a1+a0)>rpthen22230
 22160 ifval(rp$(a1+a0,1))=0then22230
 22170 print rp$(a1+a0,1)",";
 22180 print rp$(a1+a0,2)",";
 22190 a3=val(rp$(a1+a0,3))
 22200 print mid$("????cmd 154115711581????????dacc????c81+",1+a3*4,4);",";
 22210 print rp$(a1+a0,4)
 22220 goto22240
 22230 print " not in use..."
 22240 next
 22299 :
 22300 print"{down}"t0$:print"hit any key to continue"
 22310 poke 198,0:wait198,1
 22320 a1=a1+16:ifa1=16then22110
 22330 goto21000
 28000 rem input part.-no.
 28010 print"{home}{down}{down}{down}{down}partition-nr. ?";val(rp$(rp,1))+1
 28020 input"{home}{down}{down}{down}{down}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}";pn
 28030 if pn<1orpn>31 then 28010
 28040 f%=0:for a0=1 to 31
 28050 if val(rp$(a0,1))=pnthenf%=-1
 28060 next
 28070 return
 28099 :
 28100 rem input part.-name
 28110 input"{home}{down}{down}{down}{down}{down}{down}partition-name ";pn$
 28120 if pn$="" then pn$="rl"+str$(pn)
 28130 return
 28199 :
 28200 rem input part.-type
 28210 if sp$="1" then pt=1
 28220 if sp$="2" then pt=2
 28230 if sp$="3" then pt=3
 28240 if sp$="4" then pt=4
 28250 if sp$="5" then pt=7
 28260 if sp$="6" then pt=9
 28270 return
 28299 :
 28300 rem input part.size
 28310 ifpt=2thenps=683:return
 28320 ifpt=3thenps=1366:return
 28330 ifpt=4thenps=3200:return
 28340 ifpt=9thenps=3328:return
 28350 ps=0:input"{home}{down}{down}{down}{down}{down}{down}{down}{down}partition-size ";ps
 28360 if(ps=-1)and(pt=1)thenps=int(fm/256)*256:return
 28370 ifps=0then28350
 28380 if(ps/128)<>int(ps/128)then28350
 28390 ifpt<>1thenreturn
 28400 if(ps/256)<>int(ps/256)then28350
 28410 return
 28499 :
 28900 print"{blk}{clr}{gry3}ramlink installation 1.1"
 28910 printt0$
 28920 gosub 28000:iff%<>0then28020
 28930 gosub 28100
 28940 gosub 28200
 28950 gosub 28300
 28960 return
 29000 rem laufwerk waehlen
 29010 print"{blk}{clr}{gry3}ramlink installation 1.1"
 29020 printt0$
 29030 print "{down}save 'rl.ini'-file to drive  ";id
 29040 poke198,0:input "{up}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}";a0
 29050 if a0>=8 and a0<=31 then 29070
 29060 goto 29040
 29070 open15,a0,15:close15
 29080 if st<>0 then 29040
 29099 :
 29100 print"{blk}{clr}{gry3}ramlink installation 1.1"
 29110 printt0$
 29120 id=a0:return
 29990 end
 29999 end
 30000 rem get ramlink-device
 30010 print"{down}   searching for ramlink..."
 30020 a0=8:rl=0
 30030 poke144,0:open15,a0,15:close15:ifst<>0thengoto30090
 30040 a$="":open15,a0,15
 30050 print#15,"m-r"+chr$(160)+chr$(254)+chr$(6)
 30060 fori=1to6:get#15,b$:a$=a$+b$:next
 30070 close15
 30080 ifa$="cmd rl"then30200
 30090 a0=a0+1:ifa0<32then30030
 30100 print"{gry3}{clr}installation error !"
 30110 printt0$
 30120 print"{down}ramlink not available !"
 30130 end
 30199 :
 30200 rl=a0
 30210 print"{blk}{clr}{gry3}ramlink installation 1.1":printt0$
 30220 return
 30299 :
 39999 :
 51000 ba=xt+256
 51010 sa=0
 51020 bh=peek(ba+21):sh=peek(ba+29)
 51030 bm=peek(ba+22):sm=peek(ba+30)
 51040 bl=peek(ba+23):sl=peek(ba+31)
 51050 os=bh*256^2+bm*256+bl
 51060 si=sh*256^2+sm*256+sl
 51070 mx=os-sa
 51080 mm=os+si:fm=mx:mm=fm
 51090 return
 51999 :
 59990 end
 60000 rem read partition table
 60010 print"reading partition table..."
 60020 tr=1:ad=xt+256
 60030 forse=0to4
 60040 gosub61000
 60050 ad=ad+256
 60060 next
 60070 return
 60099 :
 61000 rem read sector to buffer
 61010 sys57513
 61020 poke56865,tr:poke56866,se
 61030 poke56867,ad-(int(ad/256)*256)
 61040 poke56868,int(ad/256)
 61050 poke56869,255:poke56864,128
 61060 sys65057
 61070 return
 61099 :
