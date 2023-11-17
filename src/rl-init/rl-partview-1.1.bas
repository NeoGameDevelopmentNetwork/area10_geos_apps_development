; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;
; rl-partview 1.1
; This program will list all partitions on your ramlink
; sorted by start-adress in the ramlink memory table.
;

  100 ve$="1.1"
  110 dv=8:mp=31
  120 dim p%(mp),pn$(mp),pl(mp),pm(mp),ph(mp),pt(mp),pd%(mp,31)
  130 hb=65536:mb=256:lb=1
  200 t0$="{grn}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{SHIFT-*}{gry3}"
  210 t1$="{home}{down}{down}{down}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}"
  900 poke53280,0:poke53281,0
  999 :
 1000 print"{swlc}{dish}{blk}{clr}{gry3} ramlink partview v";ve$
 1010 printt0$:gosub10000
 1020 print"{swlc}{dish}{blk}{clr}{gry3} ramlink partview v";ve$
 1030 printt0$
 1040 print"{down} 1. Einlesen der Partitionen...":gosub20000
 1050 print"{down} 2. Sortieren...":gosub22000
 1060 gosub23000
 1070 print"{swlc}{dish}{blk}{clr}{gry3} ramlink partview v";ve$
 1080 printt0$
 1090 print"{down}{gry3} all done...{down}"
 1110 end
 1999 :
 10000 input"{home}{down}{down}{down} Laufwerksadresse CMD RL ";a0:ifa0<8then10000
 10010 open15,a0,15:close15:ifst<>0then10000
 10020 dv=a0:return
 19999 :
 20000 open15,dv,15:fora0=1tomp:printt1$"["a0"{left} ]"
 20010 print#15,"g-p"+chr$(a0):get#15,a$:a1=asc(a$+chr$(0)):ifa1=0then20030
 20020 ap=ap+1:pd%(ap,0)=a1:fora1=1to30:get#15,a$:pd%(ap,a1)=asc(a$+chr$(0)):next
 20030 next:return
 20099 :
 20999 :
 22000 fora0=1toap:printt1$"{down}{down}["a0"{left} ]":fora1=aptoa0+1step-1
 22010 v0=pd%(a0,19)*hb+pd%(a0,20)*mb+pd%(a0,21)
 22020 v1=pd%(a1,19)*hb+pd%(a1,20)*mb+pd%(a1,21):ifv0<v1then22040
 22030 fora2=0to30:a3=pd%(a0,a2):pd%(a0,a2)=pd%(a1,a2):pd%(a1,a2)=a3:next
 22040 next:next:printt1$"{down}{down}       ":return
 22999 :
 23000 a0=0:fora1=1toap
 23010 ifa0<>0anda0<>16then23030
 23020 a0=0:print"{blk}{clr}{gry3} ramlink partview v";ve$:printt0$"{down}"
 23030 printright$("    "+str$(pd%(a1,2)),4)" ";
 23040 fora2=3to18:printchr$(pd%(a1,a2));:next
 23050 v0=pd%(a1,19)*hb+pd%(a1,20)*mb+pd%(a1,21)
 23060 printright$("          "+str$(v0),10)
 23070 a0=a0+1:ifa0<16then23090
 23080 print"{down}"t0$:print" Weiter mit Taste...":poke198,0:wait198,1
 23090 next:ifa0>0thenprint"{down}"t0$:print" Weiter mit Taste...":poke198,0:wait198,1
 23100 return
 23999 :
