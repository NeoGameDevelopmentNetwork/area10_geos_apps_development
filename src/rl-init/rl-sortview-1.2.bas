; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;
; rl-sortview 1.2
; This program will display a list of all partitions with size
; and partition type info.
;

  100 ve$="1.2"
  110 xt=49152
  120 rl=0:id=peek(186)
  130 dim rp(31)
  199 :
  200 t0$="{grn}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{gry3}"
  900 poke53280,0:poke53281,0
  999 :
 1000 print"{blk}{clr}{gry3} ramlink sortview v";ve$
 1010 printt0$
 1020 gosub 30000
 1030 gosub 60000
 1040 gosub 51000
 1050 gosub 20000
 1060 print"{blk}{clr}{gry3} ramlink sortview v";ve$
 1070 printt0$
 1080 print"{down}{gry3} all done...{down}"
 1090 end
 1099 :
 20000 print"{blk}{clr}{gry3} ramlink sortview v";ve$
 20010 printt0$
 20099 :
 20100 rem erste 1581-partition suchen
 20110 s8=0:al=255:am=255:ah=255
 20120 ad=xt+256:fora0=1to31:a1=ad+a0*32
 20130 pt=peek(a1+2):if(pt<>4)then20180
 20140 s0=peek(a1+21):s1=peek(a1+22):s2=peek(a1+23)
 20150 v0=s0*65536+s1*256+s2
 20160 v1=ah*65536+am*256+al
 20170 if(v0<v1)thens8=a0:ah=s0:am=s1:al=s2
 20180 ifpt>0thenap=ap+1:rp(ap)=a0
 20190 next
 20199 :
 20200 rem partitionstabelle zeigen.
 20299 :
 20300 ph=0:pm=0:pl=0
 20310 fora0=0to1:a1=a0*16:a2=16-a0
 20320 print" nr name              hb  mb  lb blocks "t0$"{down}"
 20330 pp=0:fora3=(a1+1)to(a1+a2)
 20340 fora4=1toap:pn=rp(a4)
 20350 if(pn>0)thengosub20400
 20360 next:next:ifpp=0then20390
 20370 print"{down}"t0$:print" hit any key..."
 20380 poke198,0:wait198,1
 20390 print"{blk}{clr}{gry3} ramlink sortview v";ve$:printt0$:next:return
 20399 :
 20400 a5=ad+pn*32
 20410 ch=peek(a5+21):cm=peek(a5+22):cl=peek(a5+23)
 20420 sh=peek(a5+29):sm=peek(a5+30):sl=peek(a5+31)
 20430 v0=ch*65536+cm*256+cl
 20440 v1=ph*65536+pm*256+pl
 20450 v2=sh*65536+sm*256+sl
 20460 if(v0<>v1)and((v1-v0)<>-128)thenreturn
 20470 pt=peek(a5+2)
 20499 :
 20500 p1=ph*65536+pm*256+pl
 20510 p2=sh*65536+sm*256+sl
 20520 p1=p1+p2-(v1-v0)
 20530 ph=int(p1/65536)
 20540 p1=p1-ph*65536
 20550 pm=int(p1/  256)
 20560 p1=p1-pm*  256
 20570 pl=p1
 20580 rp(a4)=0:a4=ap:pp=pp+1
 20600 printright$("   "+str$(pn),3)",";
 20610 forb0=0to15:printchr$(peek(a5+5+b0));:next:print",";
 20620 printright$("    "+str$(ch),3)",";
 20630 printright$("    "+str$(cm),3)",";
 20640 printright$("    "+str$(cl),3)",";
 20650 printright$("      "+str$(p2),5);
 20660 if(pt=4)thenif(s8>0)thenif(cl=al)thenprint"*"
 20670 if(pt<>4)or(s8=0)or(cl<>al)thenprint
 20680 return
 29900 end
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
 30100 print"{gry3}{clr} installation error !"
 30110 printt0$
 30120 print"{down} ramlink not available !"
 30130 end
 30199 :
 30200 rl=a0
 30210 print"{blk}{clr}{gry3} ramlink sortview v";ve$:printt0$
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
 51080 mm=os+si:fm=mx
 51090 return
 51999 :
 59990 end
 60000 rem read partition table
 60010 print"{down}{rght}{rght}{rght}reading partition table..."
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
