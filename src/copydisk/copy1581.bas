; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;
   10 ps=peek(49152)+peek(49155)+peek(49158)+peek(49161)+peek(49164)
   20 if(f=0)and(ps<>380)thenf=1:load"rdwrseklib",peek(186),1
   39 :
   40 rem systemaufrufe
   41 dd=49152 :rem copy disk->disk
   42 rem systemaufrufe ohne open/close
   43 du=49155 :rem copy disk->disk
   44 di=49158 :rem copy disk->image
   45 id=49161 :rem copy image->disk
   46 dn=49164 :rem get max.track on dnp
   49 :
   50 sd=49152 +15:rem source device
   51 td=49152 +16:rem target device
   52 ta=49152 +17:rem track to copy
   53 mx=49152 +18:rem max.sectors on track (0=256)
   54 ds=49152 +19:rem source dual disk drive 0/1
   55 dt=49152 +20:rem source dual disk drive 0/1
   56 em=49152 +21:rem error mode
   57 mt=49152 +22:rem max.track on dnp
   58 ec=49152 +23:rem error count
   59 ex=49152 +24:rem error on drive x
   60 et=49152 +25:rem error on track x
   61 es=49152 +26:rem error status code
   69 :
   70 ex$=".d81":na$="1581"
   71 tc=80 :rem track count
   72 sc=40 :rem sector count
   79 :
   80 t0$="                                       "
   99 :
  100 print"{clr}{down}copy ";na$;" disk"
  110 input"{home}{down}{down}{down}source drive";d0:if(d0=<0)thengoto220
  111 open15,d0,15:close15:if(st<>0)thengoto110
  112 pokesd,d0 :rem source drive
  120 input"{home}{down}{down}{down}{down}target drive";d1:if(d1=<0)thengoto220
  121 open15,d1,15:close15:if(st<>0)thengoto120
  122 poketd,d1 :rem target drive
  129 :
  130 pokeec,0 :rem clear error count
  131 pokeex,0 :rem clear error on drive x
  132 pokeet,0 :rem clear error on track x
  133 pokees,0 :rem clear error status byte
  199 :
  200 print"{down}select copy mode:{down}"
  201 print"1 / a  = disk  to disk"
  202 print"2 / b  = disk  to image"
  203 print"3 / c  = image to disk"
  204 print
  205 print"mode: (1-3) count/skip errors"
  206 print"      (a-c) exit on error"
  207 print"{down}press any other key to exit."
  210 getcm$:ifcm$=""then210
  220 ee=0:pokeem,ee :rem skip errors
  221 if(cm$="1")thengoto1000
  222 if(cm$="2")thengoto2000
  223 if(cm$="3")thengoto3000
  230 ee=1:pokeem,ee :rem exit on error
  231 if(cm$="a")then:goto1000
  232 if(cm$="b")then:goto2000
  233 if(cm$="c")then:goto3000
  239 :
  250 print"bye..."
  290 end
  299 :
  300 print"{home}{down}{down}{down}{down}{down}{down}track :";tr;
  310 print"{left}   (";int((tr-1)*100/tc);"{left}% )"
  320 return
  399 :
  400 if(ee<>0)thenif(peek(ec)>0)thengoto450
  410 print"{home}{down}{down}{down}{down}{down}{down}copy completed...     "
  411 print"errors:";peek(ec):if(peek(ec)=0)thengoto440
  420 goto470 :rem show last error
  440 return
  449 :
  450 print"{home}{down}{down}{down}{down}{down}{down}copy failed...        "
  460 print"errors:";peek(ec)
  470 print"{down}last error:"
  471 print"drive :";peek(ex)
  472 print"track :";peek(et)
  473 print"status:";peek(es)
  490 return
  499 :
 1000 rem copy disk to disk
 1001 print"{clr}{down}copy ";na$;"-disk to ";na$;"-disk{down}"
 1010 print"source:";d0
 1011 print"target:";d1
 1099 :
 1100 rem open10,d0,15:open2,d0,2,"#"
 1110 rem open11,d1,15:open3,d1,3,"#"
 1199 :
 1200 fortr=1totc
 1210 : gosub300  :rem print status
 1230 : poketa,tr :rem set track
 1240 : pokemx,sc :rem set sector count
 1250 : sysdd     :rem copy track with open/close
 1251 : rem sysdu :rem copy track
 1255 : if(ee<>0)thenif(peek(ec)>0)thentr=tc
 1260 next
 1299 :
 1300 rem close2:close10:close3:close11
 1310 gosub400 :rem job done
 1399 :
 1990 end
 1999 :
 2000 rem copy disk to image
 2001 print"{down}target file name (without ";ex$;")"
 2009 :
 2010 inputf$:if(f$="")thengoto2010
 2011 open2,d1,0,f$+ex$:get#2,a$:close2
 2012 if(st<>0)thengoto2020
 2015 print"{down}file exists! -> ";f$;ex$
 2016 print"replace (y/n) ?"
 2017 getk$:if(k$="")thengoto2017
 2018 if(k$<>"y")thenprint"{up}{up}";t0$;chr$(13);t0$;"{up}{up}{up}{up}":goto2010
 2019 :
 2020 print"{clr}{down}copy ";na$;"-disk to ";ex$;"-image{down}"
 2030 print"source:";d0
 2031 print"target:";d1;"{left}:";f$;ex$
 2099 :
 2100 open10,d0,15:open2,d0,2,"#"
 2110 open11,d1,15:open3,d1,3,"@:"+f$+ex$+",p,w"
 2199 :
 2200 fortr=1totc
 2210 : gosub300  :rem print status
 2230 : poketa,tr :rem set track
 2240 : pokemx,sc :rem set sector count
 2250 : sysdi     :rem read sector/send data
 2255 : if(ee<>0)thenif(peek(ec)>0)thentr=tc
 2260 next
 2299 :
 2300 close2:close10:close3:close11
 2310 gosub400 :rem job done
 2399 :
 2990 end
 2999 :
 3000 rem copy image to disk
 3001 print"{down}source file name (without ";ex$;")"
 3010 inputf$:if(f$="")thengoto3010
 3015 open2,d0,0,f$+ex$:get#2,a$:close2:if(st=0)thengoto3020
 3016 print"{down}file not found! -> ";f$;ex$;"{up}{up}{up}"
 3017 goto3010
 3019 :
 3020 print"{clr}{down}copy ";ex$;"-image to ";na$;"-disk{down}"
 3030 print"source:";d0;"{left}:";f$;ex$
 3031 print"target:";d1
 3099 :
 3100 open10,d0,15:open2,d0,2,f$+ex$+",p,r"
 3110 open11,d1,15:open3,d1,3,"#"
 3199 :
 3200 fortr=1totc
 3210 : gosub300  :rem print status
 3230 : poketa,tr :rem set track
 3240 : pokemx,sc :rem set sector count
 3250 : sysid     :rem receive data/write sector
 3255 : if(ee<>0)thenif(peek(ec)>0)thentr=tc
 3260 next
 3299 :
 3300 close2:close10:close3:close11
 3310 gosub400 :rem job done
 3399 :
 3990 end
 3999 :
