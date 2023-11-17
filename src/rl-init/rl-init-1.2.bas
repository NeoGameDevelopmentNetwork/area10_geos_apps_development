; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;
; rl-init 1.2
; This program will read a partition list for a configuration
; file 'rl.ini' and will then create and format the partitions.
; Use rl-edit to create such a configuration file.
; Note that this tool will wipe all your ramlink data and then
; re-create all partitions from scratch.
; This program is useful if you have many different partitions and
; don't want to re-create all partitions manually after a crash
; or after a power loss.
; WARNING: USE AT YOUR OWN RISK! IT WILL REMOVE ANY EXISTING
;          DATA FROM YOUR RAMLINK!
;

  100 xt=49152
  110 rl=0:id=peek(186)
  120 dim fp%(32)
  130 dim fp$(32)
  140 ve$="1.2"
  199 :
  200 t0$="{grn}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{gry3}"
  999 :
 1000 poke53280,0:poke53281,0
 1010 print"{blk}{clr}{gry3}ramlink installation v";ve$
 1020 printt0$
 1030 gosub29000
 1040 gosub30000
 1050 gosub31000
 1060 gosub32000
 1070 print"{blk}{clr}{gry3}ramlink installation v";ve$
 1080 printt0$
 1099 :
 1100 print"{down}1. ";:gosub60000
 1110 print"{down}2. ";:gosub50000
 1120 print"{down}3. ";:gosub60200
 1130 print"{down}4. ";:gosub40000
 1140 print"{down}5. ";:gosub60100
 1150 print"{down}6. ";:gosub44000
 1160 print"{gry3}{clr}installation complete !"
 1170 printt0$
 1180 print"all done!"
 1190 end
 1199 :
 29000 rem laufwerk waehlen
 29010 print"{blk}{clr}{gry3}ramlink installation v";ve$
 29020 printt0$
 29030 print "{down}load 'rl.ini'-file from drive  ";id
 29040 poke198,0:input "{up}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}";a0
 29050 if a0>=8 and a0<=31 then 29070
 29060 goto 29040
 29070 open15,a0,15:close15
 29080 if st<>0 then 29040
 29099 :
 29100 print"{blk}{clr}{gry3}ramlink installation v";ve$
 29110 printt0$
 29120 id=a0:return
 29999 :
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
 30210 print"{blk}{clr}{gry3}ramlink installation v";ve$
 30220 printt0$
 30230 return
 30299 :
 31000 rem searching for rl.ini
 31010 print"{down}   searching for file 'rl.ini'..."
 31020 poke144,0:open15,id,15:close15
 31030 if(st<>0)then31130
 31099 :
 31100 open15,id,15,"r0:rl.ini=rl.ini"
 31110 input#15,a0,a$,a$,a$
 31120 close15:ifa0=63thenreturn
 31130 print"{gry3}{clr}installation error !"
 31140 printt0$
 31150 print"{down}can't find file 'rl.ini' or drive"id"{left}:"
 31160 print"is not connected !"
 31170 end
 31999 :
 32000 rem print summary
 32010 print"{blk}{clr}{gry3}ramlink installation v";ve$
 32020 printt0$
 32099 :
 32100 print"{down}{down}  summary:"
 32110 print"{down}  load 'rl.ini' from drive : ";id
 32120 print"{down}  ramlink device adress    : ";rl
 32199 :
 32200 print"{down}{down}";t0$;"{down}{down}"
 32210 print"{grn}  {gry3}ready for ramlink initialization"
 32220 print"{grn}  {gry3}note: this will delete all data!"
 32230 print"{grn}  {gry3}press <return> to start"
 32240 print"{down}{down}";t0$;"{down}"
 32250 print"{gry3}  hit run/stop + restore to abort!{home}"
 32299 :
 32300 poke 198,0:wait 198,1:get sp$
 32310 return
 32399 :
 32500 a1=0
 32510 print"{blk}{clr}{gry3}ramlink installation v";ve$
 32520 printt0$"{down}"
 32530 a2=16:ifa1>0thena2=15
 32540 fora0=1toa2:print right$("   "+str$(a1+a0),3)" - ";
 32550 if(a1+a0)>rpthen32630
 32560 ifval(rp$(a1+a0,1))=0then32630
 32570 print rp$(a1+a0,1)",";
 32580 print rp$(a1+a0,2)",";
 32590 a3=val(rp$(a1+a0,3))
 32600 print mid$("????cmd 154115711581????????dacc????c81+",1+a3*4,4);",";
 32610 print rp$(a1+a0,4)
 32620 goto32640
 32630 print " not in use..."
 32640 next
 32699 :
 32700 print"{down}"t0$:print"hit any key to continue"
 32710 poke 198,0:wait198,1
 32720 a1=a1+16:ifa1=16then32510
 32730 return
 32799 :
 40000 rem create partitions
 40010 print"create partition table..."
 40020 open15,id,15,"r0:rl.ini=rl.ini"
 40030 input#15,a0,a$,a$,a$
 40040 close15:ifa0=63then40100
 40050 print"{gry3}{clr}installation error !"
 40060 printt0$
 40070 print"{down}can't find file 'rl.ini'!"
 40090 end
 40099 :
 40100 open2,id,2,"rl.ini,s,r"
 40110 if(st=0)thengosub41000:goto40110
 40120 close2
 40130 print "   {SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}"
 40140 print"   "right$("00"+mid$(str$(pa),2),2)" partitions created."
 40150 print"   "right$("00000"+mid$(str$(mx),2),5)" free blocks left."
 40160 return
 40199 :
 40200 print"{gry3}{clr}installation error !"
 40210 printt0$
 40220 print"{down}data-error in 'rl.ini'-file !"
 40230 end
 40999 :
 41000 input#2,pn,pt,pn$,ps
 41010 ifpn<1orpn>31then40200
 41099 :
 41100 ifpt=  0then40200
 41110 ifpt=  5then40200
 41120 ifpt=  6then40200
 41130 ifpt=  8then40200
 41140 ifpt>  9then40200
 41199 :
 41200 pn$=left$(pn$,16)
 41210 v0=asc(right$(pn$,1)):ifv0<>32andv0<>160then41240
 41220 pn$=left$(pn$,len(pn$)-1)
 41230 goto41210
 41240 iflen(pn$)<16thenpn$=pn$+chr$(160):goto41240
 41299 :
 41300 ifpt=1thenps=ps
 41310 ifpt=2thenps=683
 41320 ifpt=3thenps=1366
 41330 ifpt=4thenps=ps
 41340 ifpt=7thenps=ps
 41350 ifpt=9thenps=3200
 41360 ifps=-1thenps=int(mx/256)*256
 41370 print"   * "pn$" => ";
 41399 :
 42000 if(mx-ps)<0then42200
 42010 ba=xt+256+pn*32+2
 42020 zh=int(sa/(256^2))
 42030 zm=int((sa-zh)/256)
 42040 zl=sa-((zh*256^2)+(zm*256))
 42050 sh=int(ps/(256^2))
 42060 sm=int((ps-sh)/256)
 42070 sl=ps-((sh*256^2)+(sm*256))
 42080 a$=chr$(pt):ifpt=9thena$=chr$(4)
 42090 a$=a$+chr$(0)+chr$(0)+pn$
 42100 a$=a$+chr$(zh)+chr$(zm)+chr$(zl)
 42110 a$=a$+chr$(0)+chr$(0)+chr$(0)
 42120 a$=a$+chr$(0)+chr$(0)
 42130 a$=a$+chr$(sh)+chr$(sm)+chr$(sl)
 42140 ifpeek(ba)<>0then42200
 42150 fora0=0to29
 42160 pokeba+a0,asc(mid$(a$,1+a0,1))
 42170 next
 42180 goto42300
 42200 print"cancelled !"
 42210 return
 42299 :
 42300 print"ok !"
 42310 sa=sa+ps:ifpt=9thensa=sa+128
 42320 mx=mx-ps:ifpt=9thenmx=mx-128
 42330 pa=pa+1
 42340 ifpt=1thengosub43000
 42350 ifpt=2thengosub43000
 42360 ifpt=3thengosub43000
 42370 ifpt=4thengosub43000
 42380 ifpt=9thengosub43000
 42390 return
 42999 :
 43000 fp%(pa)=pn:fp$(pa)=pn$:return
 43099 :
 44000 rem format partitions
 44010 print"formatting partitions..."
 44020 fora0=1to31
 44030 iffp%(a0)=0then44080
 44040 a$=right$("00"+mid$(str$(fp%(a0)),2),2)
 44050 open15,rl,15,"uj:"
 44060 print#15,"n"+a$+":"+fp$(a0)+",rl"
 44070 input#15,a$,b$,c$,d$:close15
 44080 next
 44090 return
 44099 :
 50000 rem get ramlink-size
 50010 print"testing ramlink-size..."
 50020 ba=xt+256
 50030 sa=0
 50040 bh=peek(ba+21):sh=peek(ba+29)
 50050 bm=peek(ba+22):sm=peek(ba+30)
 50060 bl=peek(ba+23):sl=peek(ba+31)
 50070 os=bh*256^2+bm*256+bl
 50080 si=sh*256^2+sm*256+sl
 50090 mx=os-sa
 50099 :
 50100 mm=os+si
 50110 print"   (memory located: ";
 50120 printright$("00000"+mid$(str$(int(mm/4)),2),5)" kbytes)"
 50130 return
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
 60100 rem write partition table
 60110 print"writing partition table..."
 60120 tr=1:ad=xt+256
 60130 forse=0to4
 60140 gosub61100
 60150 ad=ad+256
 60160 next
 60170 return
 60199 :
 60200 rem clear partition table
 60210 print"clearing partition table..."
 60220 fora0=xt+256+32toxt+256+255
 60230 pokea0,0:next
 60240 fora0=2to4:fora1=2to255
 60250 pokext+a0*256+a1,0
 60260 next:next
 60270 return
 60299 :
 61000 rem read sector to buffer
 61010 sys57513
 61020 poke56865,tr:poke56866,se
 61030 poke56867,ad-(int(ad/256)*256)
 61040 poke56868,int(ad/256)
 61050 poke56869,255:poke56864,128
 61060 sys65057
 61070 return
 61099 :
 61100 rem write buffer to sektor
 61110 sys57513
 61120 poke56865,tr:poke56866,se
 61130 poke56867,ad-(int(ad/256)*256)
 61140 poke56868,int(ad/256)
 61150 poke56869,255:poke56864,144
 61160 sys65057
 61170 return
 61199 :
 62000 rem create partitions
