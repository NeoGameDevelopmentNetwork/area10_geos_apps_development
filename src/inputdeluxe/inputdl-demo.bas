1000 rem ******************************
1001 rem **                          **
1002 rem ** print-at & input de luxe **
1003 rem **                          **
1004 rem **       demoprogramm       **
1005 rem **                          **
1006 rem **   written '90-2020 by:   **
1007 rem **                          **
1008 rem **       markus kanet       **
1009 rem **                          **
1010 rem ******************************
1020 :
1100 rem
1101 rem variablen definieren
1102 rem
1110 pr=2090:rem print-at
1111 in=2093:rem input de luxe
1112 cd=2099:rem chardef
1113 so=2102:rem syntax output
1114 pe=2105:rem parameter-editor
1115 ef=2108:rem efkey-editor
1120 b$="{CTRL-K} "
1125 z$="{CTRL-Z}"
1130 s$="_!#$%&'()+-\@*^~:;=[],./<>?"
1135 e$=chr$(13)
1137 ek$="{up}{down}{wht}"+e$
1140 vo=0   :rem kein vorgabetext
1145 fm=1   :rem feld-flag       = ein
1150 hm=0   :rem hide-flag       = aus
1155 po=1   :rem position        = 1
1160 at=0   :rem anzahl tasten   = >=0
1165 fa=3   :rem eingabefarbe cyan
1170 fe=0   :rem endfarbe     weiss
1175 rm=0   :rem revers-flag bit0= aus                   revers-flag bit1= aus
1180 cm=0   :rem multicolormodus = aus
1185 ev=0   :rem end-taste nach ev
1190 cv=0   :rem crsr-pos  nach cv
1195 dim a$(10):q$=" ":fm$="{CBM-@}":hc$="#":re$="  "
1200 def fn x(a)=int(cos(a)*7+8)
1210 def fn y(a)=int(sin(a)*12+17)
1999 :
2000 rem
2001 rem programm initialisieren
2002 rem
2010 poke53280,0:poke53281,0:poke53282,2:poke53283,5:poke53284,6:print"{clr}"
2020 poke650,0:poke657,128
2030 fora=0to95:readx:poke828+a,x:next
2999 :
3000 rem
3001 rem demo i  : copyright 1988-2020
3002 rem
3010 a1$="{rvon}{blu}{CBM-A}{lblu}{SHIFT-*}{cyn}{SHIFT-*}{lgrn}{SHIFT-*}{wht}{SHIFT-*}{yel}{SHIFT-*}{orng}{SHIFT-*}{brn}{CBM-S}"
3020 a2$="{rvon}{blu}{SHIFT--}{lblu}p{cyn}a{lgrn}&{wht}i{yel}d{orng}l{brn}{SHIFT--}"
3030 a3$="{rvon}{blu}{CBM-Z}{lblu}{SHIFT-*}{cyn}{SHIFT-*}{lgrn}{SHIFT-*}{wht}{SHIFT-*}{yel}{SHIFT-*}{orng}{SHIFT-*}{brn}{CBM-X}"
3040 a4$="{down}{left}{left}{left}{left}{left}{left}{left}{left}"
3050 ag$=a1$+a4$+a2$+a4$+a3$
3060 fora=1.5to7.9step.08:syspr,fnx(a),fny(a),ag$:nexta
3070 fora=28to16step-1:syspr,8,a,ag$"{rvof} {up}{left} {up}{left} ";:nexta:print"{down}{rght}{rght}{rght}{rght}{cyn}2020"
3080 syspr,21,2,"{wht}print-at & input de luxe version 4.4"
3090 syspr,22,2,"written 1990-2020 by :  markus kanet":gosub30000:print"{clr}"
3999 :
4000 rem
4001 rem demo ii : bildschirm verzieren
4002 rem
4010 fora=0to50:x=rnd(0)*32:y=rnd(0)*18:syspr,y,x,ag$:next
4020 syspr,21,6,"{wht}bildschirm verzieren mit dem"
4030 syspr,22,12,"{wht}print-at befehl":gosub30000:print"{clr}"
5000 rem
5001 rem demo iii: idl-befehl
5002 rem
5010 a$(1)="fm":a$(2)="hm":a$(3)="po":a$(4)="an":a$(5)="fa":a$(6)="fe"
5020 a$(7)="rm":a$(8)="cm":a$(9)="ev":a$(10)="cv"
5030 syspr,0,6,"{cyn}der magische input-befehl !":gosub30000
5035 syspr,2,9,"{lgrn}***{cyn} input de luxe {lgrn}***":gosub30000
5040 syspr,4,0,"{grn}kuerzester aufruf :":syspr,6,0,"{cyn}sys2093,z,s,l,t$,q$,ek$,vo"
5050 syspr,9,0,"{grn}laengster aufruf :":syspr,10,0,"{cyn}";:sysso,0
5060 a=0
5065 syspr,15,0,"{grn}beispiele fuer optionale parameter :"
5070 syspr,17,0,"{cyn}sys 2093,ze,sp,la,t$,q$,e$,vo,{grn}parameter"
5080 syspr,19,0,"{grn},optionale parameter :"
5090 syspr,20,0,"{cyn}                                        "
5095 syspr,22,0,"{cyn}                                        "
5100 k$=""
5110 forb=1to10:f=0
5120 fork=1to20-b
5130 a1=int(rnd(0)*11)
5140 ifb=a1thenk$=k$+","+a$(b):k=20-b:f=1:z=0
5150 nextk:iff=0thenk$=k$+",":z=z+1
5160 nextb:ifz<>0thenforb=zto1step-1:k$=left$(k$,len(k$)-1):next
5170 syspr,20,0,k$
5180 syspr,22,7,"{cyn}noch ein beispiel ? [j/n]"
5190 geta$:on-(a$="")-2*(a$="j")goto5190,5090
5200 gosub30000
6000 rem
6001 rem demo iv : aenderungen
6002 rem
6010 print"{clr}":co$="#"+fm$+re$
6020 syspr,0,0,"{wht}i.  {grn}das eingabefeld kann durch ein frei"
6030 syspr,1,0,"    waehlbares zeichen markiert werden."
6040 syspr,5,0,"{grn}markierungs-code aendern  {cyn}ctrl + c"
6050 syscd,co$
6060 syspr,6,0,"{grn}ende                      {cyn}ctrl + e"
6070 sysin,8,0,40,"{CTRL-A}",q$,"{wht}{stop}",q$,fm,hm,255,0,3,3,0,0,ev,cv
6080 ifev=1thenonhm+1goto7000,7100
6090 syspr,10,0,"{cyn}bitte zeichen eingeben : >"chr$(asc(fm$+"{CBM-@}"))"<"
6100 sysin,10,26,1,"{CTRL-A}",fm$,e$,fm$,0,0,1,0,1,1,0,0,ev,cv
6110 syspr,10,0,"{cyn}                                       "
6120 co$="#"+fm$+re$:ifhm=1thenco$=fm$+"{CBM-@}"+re$
6130 goto6040
6999 :
7000 rem
7001 rem demo v :rem text verstecken
7002 rem
7010 syspr,0,0,"{wht}ii. {grn}der text kann auch versteckt       "
7020 syspr,1,0,"    werden.                            "
7030 syspr,5,0,"{grn}hide-code aendern         {cyn}ctrl + c":co$="#{CBM-@}  "
7040 syscd,co$
7050 fm$="#":hm=1:rm=3:goto6050
7099 :
7100 rem
7101 rem demo v :rem demo v text zeigen
7102 rem
7110 syspr,11,0,"{cyn}sie haben folgendes eingegeben !":gosub30000
7120 syspr,12,0,"{lblu}"q$;:iflen(q$)<1thenprint"nichts !"
7130 gosub30000
7140 syspr,20,10,"{wht}noch einmal ? [j/n]"
7150 geta$:ifa$<>"j"anda$<>"n"then7150
7160 ifa$="j"thenq$="":fm$="{CBM-@}":hm=0:rm=0:goto6000
8000 rem
8001 rem farbwerte fa + rm
8002 rem
8020 syspr,0,0,"{wht}{clr}i.  {grn}die farbe des eingabefeldes kann"
8030 syspr,1,0,"    frei definiert werden."
8040 syspr,3,0,"    auch kann das eingabefeld revers"
8050 syspr,4,0,"    dargestellt werden."
8060 fa=3:fe=3:fa$="3":fe$="3":rm=0:rm$="0"
8070 syspr,6,0,"{grn}wert von fa aendern mit {cyn}ctrl + c : {grn}"fa$
8080 syspr,7,0,"{grn}wert von rm aendern mit {cyn}ctrl + d : {grn}"rm$
8090 syspr,8,0,"{grn}ende {cyn}ctrl + e"
8100 sysin,10,0,40,"{CTRL-A}",q$,"{stop}{CTRL-D}{wht}",1,1,0,255,0,fa,fe,rm,0,ev,cv
8110 ifev=3thengosub30000:goto9000
8120 ifev=2then8300
8130 syspr,12,0,"{cyn}neuer fa-wert [0-15] : >  <{left}{left}{left}";
8140 sysin,255,255,2,z$,fa$,e$,fa$,1,0,1,1,3,3,0,0:fa=val(fa$)
8150 poke781,12:sys59903:goto8070
8300 syspr,12,0,"{cyn}neuer rm-wert [0,1]  : > <{left}{left}";
8310 sysin,255,255,1,"01",rm$,e$,rm$,1,0,1,1,3,3,0,0:rm=val(rm$)
8320 poke781,12:sys59903:goto8070
9000 rem
9001 rem farbwerte fe + rm
9002 rem
9020 syspr,0,0,"{wht}{clr}ii. {grn}die farbe nach beendigung der"
9030 syspr,1,0,"    eingabe kann frei definiert werden."
9040 syspr,3,0,"    auch kann das eingabefeld revers"
9050 syspr,4,0,"    dargestellt werden."
9060 fa=3:fe=3:fa$="3":fe$="3":rm=0:rm$="0"
9070 syspr,6,0,"{grn}wert von fe aendern mit {cyn}ctrl + c : {grn}"fe$
9080 syspr,7,0,"{grn}wert von rm aendern mit {cyn}ctrl + d : {grn}"rm$
9090 syspr,8,0,"{grn}ende {cyn}ctrl + e"
9100 sysin,10,0,40,"{CTRL-A}",q$,"{stop}{CTRL-D}{wht}",1,1,0,1,0,fa,fe,rm,0
9110 ifev=3thengosub30000:goto10000
9120 ifev=2then9300
9130 syspr,12,0,"{cyn}neuer fe-wert [0-15]  : >  <{left}{left}{left}";
9140 sysin,255,255,2,z$,fe$,e$,fe$,1,0,1,1,3,3,0,0:fe=val(fe$)
9150 poke781,12:sys59903:goto9070
9300 syspr,12,0,"{cyn}neuer rm-wert [0,2,3] : > <{left}{left}";
9310 sysin,255,255,1,"023",rm$,e$,rm$,1,0,1,0,3,3,0,0:rm=val(rm$)
9320 poke781,12:sys59903:goto9070
10000 rem
10001 rem fa=*
10002 rem
10010 print"{clr}"
10020 syspr,0,0,"{grn}{clr}eine nette spielerei :"
10030 syspr,1,0,"{cyn}im aufruf fa=255 und fe=255 angeben."
10035 syspr,2,0,"die farben an der position des"
10037 syspr,3,0,"eingabefeldes werden uebernommen"
10038 syspr,4,0,"[fa=255] und bleiben nach der eingabe"
10039 syspr,5,0,"erhalten [fe=255]!"
10040 syspr,9,0,"{blu}     {lblu}     {cyn}     {lgrn}     {wht}     {yel}     {orng}     {brn}     "
10050 syspr,7,0,"{grn}ende mit {cyn}ctrl+e"
10060 sysin,9,0,40,"",q$,"{wht}",0,1,0,1,0,255,255,3,0
10070 gosub 30000:print"{clr}"
11000 rem
11001 rem multicolormodus
11002 :
11010 syspr,0,0,"{grn}{clr}das eingabefeld kann auch im multicolor-modus des c64 ";
11020 print"dargestellt werden."
11030 print"{down}{wht}farbe 1{lgrn} = poke 53281,hintergrundfarbe"
11040 print"{wht}FARBE{$a0}{CBM-R}{lgrn} = poke 53282,multicolor 1"
11050 print"{wht}{rvon}farbe 3{rvof}{lgrn} = poke 53283,multicolor 2"
11060 print"{wht}{rvon}FARBE{$a0}{CBM-W}{rvof}{lgrn} = poke 53284,multicolor 3"
11070 poke53265,91:syscd,"#.  "
11080 syspr,8,0,"farbe wechseln : 1-4"
11090 syspr,9,0,"ende mit       : ctrl + e"
11092 syspr,14,0,"{grn}in diesem modus koennen nur die"
11094 syspr,15,0,"zeichen mit den ascii-codes"
11096 syspr,16,0,"von 32-95 [$20-$5f] eingegeben werden."
11100 cm=1
11110 sysin,11,0,40,"",q$,"1234{wht}",1,1,0,1,0,1,1,0,cm,ev,cv
11120 ifev=5thengosub30000:poke53265,27:goto12000
11130 cm=ev:goto11110
11998 end
12000 rem
12001 rem demo : textprogramm
12002 rem
12010 syspr,0,0,"{lgrn}{clr} textstar version 4.4  ende mit {cyn}ctrl + e"
12015 syspr,24,0,"dieser editor besteht aus 6 basiczeile!{left}{inst}n{home}";:syscd,"#{CBM-@}  "
12020 fora=1to23:poke646,14:ifa/2=int(a/2)thenpoke646,6
12030 syspr,a,0,"{rvon}                                       {left}{left}{inst}  ";:next
12040 z=1:cv=1
12050 sysin,z,0,40,"",q$,ek$,1,1,0,cv,0,255,255,3,0,ev,cv
12060 ifev=1thenz=z-1-(z=1):goto12050
12070 ifev=2thenz=z+1+(z=23):goto12050
12080 ifev=4orev=5thenev=2:cv=1:goto12070
12090 poke781,24:sys59903:poke199,0:gosub30000:print"{clr} ";:run
12999 :
29999 :
30000 rem
30001 rem warten auf return
30002 rem
30010 syspr,24,8,"hit return to continue !{home}":poke198,0:sys828:poke53280,0
30020 syspr,24,0,"                                       {home}";:return
31999 :
32000 data160,39,185,116,3,153,192,219,136,16,247,173,192,219,72,160,0,185,193
32001 data219,153,192,219,200,192,40,208,245,104,141,231,219,141,32,208,32,228
32002 data255,201,13,208,1,96,162,33,160,80,136,208,253,202,208,248,76,71,3
32003 data6,6,6,6,14,14,14,14,3,3,3,3,13,13,13,13,1,1,1,1,7,7,7,7,8,8,8,8,9,9
32004 data9,9,2,2,2,2,4,4,4,4
