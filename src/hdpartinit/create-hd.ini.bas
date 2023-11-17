; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

  100 dv=peek(186)
  110 ff$="hd.ini"
  149 :
  150 print"{clr}create a hd.ini file"
  151 print"{down}enter device address:"
  152 print"(leave blank for default";dv;")"
  153 inputa
  154 ifa>7anda<29thendv=a
  155 print"target device:";dv
  159 :
  160 print"{down}enter filename:"
  161 print"(leave blank for default 'hd.ini')
  162 inputa$
  163 ifa$<>""thenff$=a$
  164 print"filename:";ff$
  169 :
  170 print"{down}reading partition data..."
  199 :
  200 open2,dv,2,"@:"+ff$+",s,w"
  210 readpn:ifpn=-1thenes=0:goto300
  220 readpn$,pt,ps
  221 cf$=cd$
  230 ifpn<1orpn>254thenes=1:es$="bad partition number":goto300
  231 iflen(pn$)=0orlen(pn$)>16thenes=2:es$="bad filename":goto300
  232 ifpt<1orpt>7thenes=3:es$="bad partition type":goto300
  240 ifpt=2thenps=684/2:goto260
  241 ifpt=3thenps=1366/2:goto260
  242 ifpt=4thenps=3200/2:goto260
  250 if(ps/128)<>int(ps/128)thenes=4:es$="bad partition size":goto300
  251 ifps<128orps>32640thenes=5:es$="bad partition size":goto300
  260 printpn;",";pn$;",";pt;",";ps
  265 print#2,pn;",";pn$;",";pt;",";ps
  270 goto210
  299 :
  300 close2
  310 print"{down}status:"
  320 ifes=0thenprint"ok"
  330 ifes>0thenprint"part";pn;": err";es;"= "es$
  340 end
  399 :
 1000 rem partition data
 1001 rem format:
 1002 rem pn,pn$,pt,ps
 1003 rem pn = partition number 1-254
 1004 rem pn$= partition name
 1005 rem pt = partition type 1-7
 1006 rem ps = partition size
 1007 rem      in 512 byte blocks, must
 1008 rem      be between 128 and 32640!
 1009 :
 1010 data 1,part1541,2,342
 1020 data 2,part1571,3,683
 1030 data 3,part1581,4,1600
 1040 data 4,native-min,1,128
 1050 data 5,native-max,1,32640
 1990 data -1
