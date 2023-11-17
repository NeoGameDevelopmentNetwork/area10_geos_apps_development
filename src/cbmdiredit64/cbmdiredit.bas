; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** screen layout *****************************************************
;  1234567890123456789012345678901234567890
; 1              cbmdiredit64
; 2 +------------------------------------+
; 3 ! drive: 8         type: 1541/d64    !
; 4 +------------------------------------+
; 5 ! [1234567890123456/1234567890123456 !
; 6 ! tr:001 se:001                      !
; 7 +------------------------------------+
; 8 ! 1 1234567890123456 xx/xx/xx  xx:xx !
; 9 !   prg [x] [x]            12345 bl. !
;10 ! 2 1234567890123456 xx/xx/xx  xx:xx !
;11 !   prg [x] [x]            12345 bl. !
;12 ! 3 1234567890123456 xx/xx/xx  xx:xx !
;13 !   prg [x] [x]            12345 bl. !
;14 ! 4 1234567890123456 xx/xx/xx  xx:xx !
;15 !   prg [x] [x]            12345 bl. !
;16 ! 5 1234567890123456 xx/xx/xx  xx:xx !
;17 !   prg [x] [x]            12345 bl. !
;18 ! 6 1234567890123456 xx/xx/xx  xx:xx !
;19 !   prg [x] [x]            12345 bl. !
;20 ! 7 1234567890123456 xx/xx/xx  xx:xx !
;21 !   prg [x] [x]            12345 bl. !
;22 ! 8 1234567890123456 xx/xx/xx  xx:xx !
;23 !   prg [x] [x]            12345 bl. !
;24 +------------------------------------+
;25  f1:top f3:next f7:re-read f8:write ?

;*** program description
10 rem cbmdiredit64 - a simple and lame directory editor
11 rem copyright (c) 2020  markus kanet
12 rem

;*** program name / author / version
50 vn$="cbmdiredit64":vv$="v0.1":vd$="(w)2020 by m.k."

;*** define title
60 sp$="          "
61 tt$=vn$+" "+vv$+"  "+vd$
62 tt$=right$(sp$+sp$+tt$,len(tt$)+(20-(len(tt$)/2)))
63 tt$="{clr}{lgrn}"+tt$+"{grn}{down}"

;*** active entry
70 ac=0:rem selected entry
71 nr=0:rem print entry

;*** device data
100 dv=peek(186):rem drive address
101 if(dv<8)or(dv>29)thendv=8
102 dt=0:rem drive mode
110 tr=1:se=1:rem disk i/o track and sector
120 dimbu(256):rem data buffer
130 e$="":ei$="":et$="":es$="":rem drive error
200 dt$(0)="unknown   "
210 dt$(1)="1541/d64  "
220 dt$(2)="1571/d71  "
230 dt$(3)="1581/d81  "
240 dt$(4)="native/dnp"

;*** directory file types
300 dimty$(9)
301 ty$(0)="del":ty$(1)="seq":ty$(2)="prg"
302 ty$(3)="usr":ty$(4)="rel":ty$(5)="cbm"
303 ty$(6)="dir":ty$(9)="???"

;*** define ui elements
400 sl$=left$(sp$+sp$+sp$+sp$,36)
410 li$="":fori=0to35:li$=li$+chr$(192):next
411 c0$=chr$(176):c1$=chr$(174)
412 c2$=chr$(173):c3$=chr$(189)
413 c4$=chr$(171):c5$=chr$(179)
414 vi$=chr$(125)
420 gf$=chr$(34)
430 dimx$(40),y$(25):x$="":y$="{home}":x=0:y=0
431 forx=0to39:x$=x$+"{right}":next
432 fory=0to24:y$=y$+"{down}":next
433 forx=1to38:x$(x)=left$(x$,x):next
434 fory=1to25:y$(y)=left$(y$,y):next

;*** define native directory track/sector
500 rt=1:rs=1:nt=rt:ns=rs
510 md=100:dimn0(md),n1(md),n$(md)

;*** date/time buffers
600 pp=0:dimpu(5,5)

;*** c64 only: zero-page, i/o and kernal routines
; > 53280 = border color
; > 53281 = backscreen color
; > 204   = cursor visibility switch / $00 = cursor on
; > 207   = cursor phase switch / $01 = cursor on phase
; > 646   = current color, cursor color
; > 647   = color of character under cursor
900 poke53280,0:poke53281,0:rem set screen color

;*** init main menu
1000 gosub10000:rem print screen

;*** get device info
1100 gosub63000:rem get device type
1110 gosub10400:rem print device info
1120 if(e$="00")and(dt>0)thengoto1400

;*** get new device
1200 dv=dv+1:if(dv=30)thendv=8
1210 if(dv=lo)thengoto9100
1220 open15,dv,15:close15
1221 if(st<>0)thengoto1200
1230 goto1100

;*** get disk info
1400 gosub62200:rem get disk name
1410 if(e$="00")thengoto1500
1420 gosub11900:rem print error
1425 gosub31000:rem select other drive
1490 goto1200

;*** get first directory block
1500 gosub62000:rem define first sector

;*** main loop
2000 gosub61200:rem read block
2010 if(e$="00")thengoto2300
2030 gosub11900:rem print error
2035 gosub31000:rem select other drive
2040 goto1400

;*** print menu data
2300 gosub10500:rem clear status
2310 gosub11000:rem print disk name
2320 gosub11100:rem print directory block
2330 ac=0:gosub50000:rem print files

;*** print menu shortcuts
2400 y=25:gosub10900:rem clear line
2410 printy$(25);x$(2);
2420 print"{lgrn}f1:{grn}top {lgrn}f3:{grn}next ";
2430 print"{lgrn}f7:{grn}re-read {lgrn}f8:{grn}write {lgrn}? ";

;*** wait for a key...
;see help pages for details...
2500 getk$:if(k$="")thengoto2500

2510 if(k$="{down}")and(ac<7)thengosub12000:goto2500
2511 if(k$="{up}")and(ac>0)thengosub12100:goto2500

2520 if(k$>="1")and(k$=<"8")thennn=val(k$)-1:gosub12200:goto2500
2521 if(k$="x")thengosub22900:goto2500
2522 if(k$="g")thengosub21800:goto2500
2523 if(k$="G")thengosub21850:goto2500
2524 if(k$=chr$(165))thengosub21900:goto2500

2530 if(k$=chr$( 13))and(bu(ac*32+2)>0)thengosub20000:goto2400

2540 if(k$=chr$(144))and(bu(ac*32+2)>0)thengosub22800:goto2500
2541 if(k$=chr$(  5))and(bu(ac*32+2)>0)thengosub22801:goto2500
2542 if(k$=chr$( 28))and(bu(ac*32+2)>0)thengosub22802:goto2500
2543 if(k$=chr$(159))and(bu(ac*32+2)>0)thengosub22803:goto2500
2544 if(k$=chr$(156))and(bu(ac*32+2)>0)thengosub22804:goto2500

2545 if(k$=chr$(129))and(bu(ac*32+2)>0)thengosub22850:goto2500
2546 if(k$=chr$(149))and(bu(ac*32+2)>0)thengosub22851:goto2500
2547 if(k$=chr$(150))and(bu(ac*32+2)>0)thengosub22852:goto2500
2548 if(k$=chr$(151))and(bu(ac*32+2)>0)thengosub22853:goto2500
2549 if(k$=chr$(152))and(bu(ac*32+2)>0)thengosub22854:goto2500

2550 if(k$="?")thengosub19000:gosub10000:gosub10400:goto2300
2551 if(k$="_")thengoto2900
2552 if(k$="d")thengosub31000:goto1400

2570 if(k$="{f1}")thengoto1500
2571 if(k$="{f3}")and(bu(0)>0)thend0=bu(0):d1=bu(1):goto2000
2572 if(k$="{f7}")thengoto2000
2573 if(k$="{f8}")thengosub61400:goto2500

2580 if(dt<>4)thengoto2590
2581 if(k$="{f2}")thengosub62400:goto1500
2582 if(k$="{f4}")thengosub62500:goto1500
2583 if(k$="{f5}")thengosub30000:goto1500
2584 if(k$="{f6}")and((bu(ac*32+2)and127)=6)thengosub62300:goto1500

2590 goto2500

;*** exit program
2900 print"{clr}bye!"
2910 end

;*** error messages
9000 print"{clr}error: unknown device mode for drive";dv
9001 stop

9100 print"{clr}error: no valid device found!"
9101 stop


;*** print main menu screen
10000 printtt$:printy$(2);
10010 print" ";c0$;li$;c1$
10011 print" ";vi$;sl$;vi$
10012 print" ";c4$;li$;c5$
10020 print" ";vi$;sl$;vi$
10021 print" ";vi$;sl$;vi$
10030 print" ";c4$;li$;c5$
10040 fornr=0to15
10041 : print" ";vi$;sl$;vi$
10042 next
10050 print" ";c2$;li$;c3$
10090 return

;*** clear file table
10100 fornr=0to7:gosub10200:next
10190 return

;*** clear file entry
10200 y=8+nr*2+0:gosub10900
10210 y=8+nr*2+1:gosub10900
10290 return

;*** clear device and drive mode
10300 y=3:gosub10900
10390 return

;*** print device and drive mode
10400 printy$(3);x$(3);"{grn}drive:{lgrn}";dv;"{left} "
10401 printy$(3);x$(20);"{grn}mode:{lgrn}";dt$(dt)
10490 return

;*** clear status or directory track/sector
10500 y=5:gosub10900
10510 y=6:gosub10900
10590 return

;*** select new device
10600 gosub10500:rem clear status
10610 printy$(5);x$(3);"{lgrn}select new disk device"
10690 return

;*** analyzing device
10700 gosub10500:rem clear status
10710 printy$(5);x$(3);"{lgrn}analyzing device..."
10790 return

;*** analyzing directory
10800 gosub10500:rem clear status
10801 printy$(5);x$(3);"{lgrn}analyzing directory..."
10840 return

;*** updatinging directory
10850 gosub10500:rem clear status
10851 printy$(5);x$(3);"{lgrn}updating directory..."
10890 return

;*** clear single line
10900 printy$(y);x$(2);"{grn}";sl$;
10990 return




;*** print disk / status information ***********************************
;*** disk name
11000 y=5:gosub10900:rem clear line
11010 printy$(y);x$(3);"[{lgrn}";dn$;"{grn}]{up}"
11030 if(dt<>4)thengoto11090
11040 printx$(20);"{lgrn}/";
11050 if(nt=1)and(ns=1)thendd$=left$("root directory"+sp$,16)
11060 printdd$;"{grn}]"
11090 return

;*** directory track/sector
11100 y=6:gosub10900:rem clear line
11110 printy$(6);x$(3);
11120 print"{grn}tr:{lgrn}";right$("00"+mid$(str$(d0),2),3);" ";
11130 print"{grn}se:{lgrn}";right$("00"+mid$(str$(d1),2),3)
11190 return

;*** drive status
11900 gosub10500:rem clear status
11910 printy$(5);x$(3);"{grn}status:{lgrn}"
11920 printy$(6);x$(3);" ";e$;",";ei$;",";et$;",";es$
11930 getk$:if(k$="")thengoto11930
11990 return




;*** select file *******************************************************
;*** next file
12000 if(ac=7)thengoto12090
12001 if(at(ac+1)=0)thengoto12090
12010 nr=ac:ac=-1:gosub50100
12011 ac=nr+1:nr=ac:gosub50100
12090 return

;*** last file
12100 if(ac=0)thengoto12190
12110 nr=ac:ac=-1:gosub50100
12111 ac=nr-1:nr=ac:gosub50100
12190 return

;*** specific file
12200 if(at(nn)=0)thengoto12290
12210 nr=ac:ac=-1:gosub50100
12211 ac=nn:nr=ac:gosub50100
12290 return




;*** list shortcuts ****************************************************
;*** help page #1
19000 printtt$
19010 print"{lgrn}{rvon}[              main menu              ]{rvof}"
19019 print
19020 print"{lgrn}f1:{grn} read first directory block"
19021 print"{lgrn}f2:{grn}  [native/dnp] open root directory"
19022 print"{lgrn}f3:{grn} read next directory block"
19024 print"{lgrn}f4:{grn}  [native/dnp] open parent directory"
19025 print"{lgrn}f5:{grn}  [native/dnp] select new directory"
19026 print"{lgrn}f6:{grn}  [native/dnp] open directory"
19027 print"{lgrn}f7:{grn} re-read current directory"
19028 print"{lgrn}f8:{grn} write directory block"
19029 print
19030 print"{lgrn}d :{grn} select device, use +/-"
19039 print
19040 print"{lgrn}crsr up/dn{grn} or {lgrn}1...8:{grn} select entry"
19041 print
19042 print"{lgrn}return   :{grn} edit current entry"
19043 print"{lgrn}x        :{grn} reset date/time"
19044 print"{lgrn}g/shift+g:{grn} convert geos<->petscii"
19045 print"{lgrn}cbm+g    :{grn} convert to lower case"
19047 print
19048 print"use {lgrn}_{grn} to exit the program"
19049 print
19050 print"press any key to continue...";
19090 getk$:if(k$="")thengoto19090

;*** help page #2
19100 printtt$
19110 print"{lgrn}{rvon}[              edit mode              ]{rvof}"
19119 print
19120 print"{lgrn}[date/time]"
19121 print"{lgrn}crsr lt/rt:{grn}move cursor"
19122 print"{lgrn}crsr up/dn:{grn}select input field"
19123 print
19124 print"{lgrn}[file name]"
19125 print"{lgrn}del/inst  :{grn} delete/insert char"
19129 print
19130 print"{lgrn}[file type]"
19131 print"{lgrn}crsr lt/rt:{grn}del/seq/prg/rel/cbm/dir"
19132 print"{lgrn}*         :{grn}file closed/open"
19133 print"{lgrn}<         :{grn}file write-protected"
19139 print
19140 print"{lgrn}[file size]"
19141 print"{lgrn}crsr lt/rt:{grn}+/- 1 block"
19142 print"{lgrn}+ / -     :{grn}+/- 10 blocks"
19143 print"{lgrn}< / >     :{grn}+/- 100 blocks"
19144 print"{lgrn}_ / ^     :{grn}+/- 1000 blocks"
19147 print
19148 print
19149 print
19150 print"press any key to continue...";
19190 getk$:if(k$="")thengoto19190

;*** help page #3
19200 printtt$
19210 print"{lgrn}{rvon}[          date/time buffers          ]{rvof}"
19219 print
19220 print"{lgrn}ctrl + <1>...<5>{grn}"
19221 print"copy date/time from current file entry"
19222 print"into buffer 1-5"
19223 print
19224 print"{lgrn}cbm + <1>...<5>{grn}"
19225 print"read date/time for current file entry"
19226 print"from buffer 1-5"
19229 print
19230 print"{lgrn}current buffers"
19231 print"{lgrn} <1>:{grn} ";
19232 pp=0:gosub22950:print" ";:gosub22960:print
19233 print"{lgrn} <2>:{grn} ";
19234 pp=1:gosub22950:print" ";:gosub22960:print
19235 print"{lgrn} <3>:{grn} ";
19236 pp=2:gosub22950:print" ";:gosub22960:print
19237 print"{lgrn} <4>:{grn} ";
19238 pp=3:gosub22950:print" ";:gosub22960:print
19239 print"{lgrn} <5>:{grn} ";
19240 pp=4:gosub22950:print" ";:gosub22960:print
19241 print
19245 print
19246 print
19247 print
19248 print
19249 print
19250 print"press any key to continue...";
19290 getk$:if(k$="")thengoto19290

19990 return




;*** data editor *******************************************************
;*** edit date and time...
20000 y=25:gosub10900:rem clear line
20001 printy$(25);x$(2);
20002 print"{lgrn}return:{grn}done ";
20003 print"{lgrn}crsr lt/rt:{grn}select";

20010 fi=2:rem edit day
20020 ch=0:rem set first position
20030 nr=ac
20040 poke646,13:poke647,13

;*** call edit modes
20100 if(fi<1)thenfi=8
20101 if(fi>8)thenfi=1
20102 ch=0:rem set first position
20110 onfigoto22000,22100,22200,22300,22400,22500,22600,22700
20190 stop:rem should never happen...

;*** move to next field...
20200 if(k$="{left}")thenfi=fi-1:ch=0:goto20100
20201 if(k$="{rght}")thenfi=fi+1:ch=0:goto20100
20210 if(k$<>chr$(13))thengoto20100
20220 nr=ac:gosub61950:gosub61900:gosub50100
20290 return




;*** input values ******************************************************
;*** input 16-char file name
21000 printy$(y+ac*2+1);x$(x+ch);
21010 poke207,1:poke204,0:rem cursor on
21011 getk$:if(k$="")thengoto21011
21012 wait207,1:poke204,1:rem cursor off
21020 if(k$=chr$(20))thenif(ch>0)thengoto21040
21021 if(k$=chr$(148))thengoto21050
21022 if(k$="{up}")thenk$="{left}":goto21090
21023 if(k$="{down}")thenk$="{right}":goto21090
21024 if(k$="{left}")thenif(ch>0)thench=ch-1:goto21000
21025 if(k$="{right}")thenif(ch<15)thench=ch+1:goto21000
21026 if(k$=chr$(13))thengoto21090
21027 if(asc(k$)<32)or((asc(k$)>127)and(asc(k$)<160))thengoto21010

;*** add new char
21030 bu$=left$(bu$,ch)+k$+right$(bu$,len(bu$)-(ch+1))
21031 printk$;
21033 ch=ch+1:if(ch<16)thengoto21010
21034 k$="{rght}"
21035 goto21090

;*** delete
21040 bu$=left$(bu$,ch)+right$(bu$,len(bu$)-(ch+1))+chr$(160)
21041 an$(ac)=bu$:ch=ch-1:nr=ac:po=nr*32:gosub50200
21042 goto21000

;*** insert
21050 bu$=left$(left$(bu$,ch)+" "+mid$(bu$,(ch+1)),16)
21051 an$(ac)=bu$:nr=ac:po=nr*32:gosub50200
21052 goto21000

;*** exit
21090 return


;*** input 2-digit number
21500 printy$(y+ac*2+1);x$(x+ch);
21510 poke207,1:poke204,0:rem cursor on
21511 getk$:if(k$="")thengoto21511
21512 wait207,1:poke204,1:rem cursor off
21520 if(ch=0)thenif(k$="{left}")thengoto21590
21521 if(ch=0)thenif(k$="{rght}")thenprintk$;:ch=1:goto21510
21522 if(ch=1)thenif(k$="{rght}")thengoto21590
21523 if(ch=1)thenif(k$="{left}")thenprintk$;:ch=0:goto21510
21524 if(k$="{up}")thenk$="{left}":goto21590
21525 if(k$="{down}")thenk$="{right}":goto21590
21526 if(k$=chr$(13))thengoto21590
21527 if(k$<"0")or(k$>"9")thengoto21510

;*** add digit
21530 bu$=left$(bu$,ch)+k$+right$(bu$,(1-ch))
21531 printk$;
21532 ch=ch+1:if(ch=1)thengoto21510
21533 k$="{rght}"

;*** exit
21590 return


;*** convert filename from geos to petscii
21800 a$="":fori=1to16
21810 : j=asc(mid$(an$(ac),i,1))
21811 : if(j>=65)and(j=< 90)thenj=j+128:goto21820
21812 : if(j>=97)and(j=<122)thenj=j-32
21820 : a$=a$+chr$(j):bu(ac*32+5+(i-1))=j
21830 next
21840 nr=ac:an$(ac)=a$:gosub50200
21849 return

;*** convert filename from petscii to geos
21850 a$="":fori=1to16
21860 : j=asc(mid$(an$(ac),i,1))
21861 : if(j>= 65)and(j=< 90)thenj=j+32:goto21870
21862 : if(j>=193)and(j=<218)thenj=j-128
21870 : a$=a$+chr$(j):bu(ac*32+5+(i-1))=j
21880 next
21890 nr=ac:an$(ac)=a$:gosub50200
21899 return

;*** convert filename from geos to lower case
21900 a$="":fori=1to16
21910 : j=asc(mid$(an$(ac),i,1))
21911 : if(j>=97)and(j=<122)thenj=j-32
21920 : a$=a$+chr$(j):bu(ac*32+5+(i-1))=j
21930 next
21940 nr=ac:an$(ac)=a$:gosub50200
21949 return





;*** input file data ***************************************************
;*** edit filename
22000 bu$=an$(ac):y=7:x=5
22010 gosub21000:an$(ac)=bu$
22020 fori=0to15:bu(ac*32+5+i)=asc(mid$(bu$,1+i,1)):next
22090 goto20200


;*** edit day
22100 bu$=ad$(ac):y=7:x=22
22110 gosub21500
22111 if(val(bu$)>31)thenbu$="31":k$=""
22130 ad$(ac)=bu$:bu(ac*32+27)=val(ad$(ac))
22190 nr=ac:gosub50300:goto20200


;*** edit month
22200 bu$=am$(ac):y=7:x=25
22210 gosub21500
22211 if(val(bu$)>12)thenbu$="12":k$=""
22220 am$(ac)=bu$:bu(ac*32+26)=val(am$(ac))
22290 nr=ac:gosub50300:goto20200


;*** edit year
22300 bu$=ay$(ac):y=7:x=28
22310 gosub21500
22320 ay$(ac)=bu$:bu(ac*32+25)=val(ay$(ac))
22390 nr=ac:goto20200


;*** edit hour
22400 bu$=a0$(ac):y=7:x=32
22410 gosub21500
22411 if(val(bu$)>23)thenbu$="23":k$=""
22420 a0$(ac)=bu$:bu(ac*32+28)=val(a0$(ac))
22490 nr=ac:gosub50400:goto20200


;*** edit minute
22500 bu$=a1$(ac):y=7:x=35:ch=0
22510 gosub21500
22511 if(val(bu$)>59)thenbu$="59":k$=""
22530 a1$(ac)=bu$:bu(ac*32+29)=val(a1$(ac))
22590 nr=ac:gosub50400:goto20200


;*** select file type and modes
22600 print"{rvon}";:gosub50500
22610 getk$:if(k$="")thengoto22610
22620 if(k$="{up}")thenk$="{left}":goto22690
22621 if(k$="{down}")thenk$="{right}":goto22690
22622 if(k$=chr$(13))thengoto22690
22623 if(k$="{left}")thenft=(at(ac)and15)-1:goto22630
22624 if(k$="{right}")thenft=(at(ac)and15)+1:goto22630
22625 if(k$="*")thengoto22640
22627 if(k$="<")thengoto22650
22629 goto22610

;*** set new file type
22630 at(ac)=ft+(at(ac)and128)+(at(ac)and64)
22631 goto22680

;*** switch open/closed file mode
22640 mo=128-(at(ac)and128):ft=(at(ac)and15)
22641 at(ac)=(at(ac)and127)+mo
22642 goto22680

;*** switch write-protection mode
22650 mo=64-(at(ac)and64):ft=(at(ac)and15)
22651 at(ac)=(at(ac)and191)+mo
;22652 goto22680:rem not necessary

;*** set new file type/modes
22680 bu(ac*32+2)=at(ac):ai$(ac)=ty$(ft)
22681 if((at(ac)and64)>0)thenai$(ac)=ai$(ac)+"<"
22682 if((at(ac)and128)=0)and(at(ac)>0)thenai$(ac)=ai$(ac)+"*"
22683 ai$(ac)=left$(ai$(ac)+"  ",5)
22689 goto22600

;*** exit
22690 print"{rvof}";:gosub50500:goto20200


;*** select file size
22700 print"{rvon}";:gosub50600
22710 getk$:if(k$="")thengoto22710
22720 if(k$="{up}")thenk$="{left}":goto22790
22721 if(k$="{down}")thenk$="{right}":goto22790
22722 if(k$=chr$(13))thengoto22790
22730 if(k$="{left}")thenas(ac)=as(ac)-1:goto22740
22731 if(k$="{right}")thenas(ac)=as(ac)+1:goto22740
22732 if(k$="-")thenas(ac)=as(ac)-10:goto22740
22733 if(k$="+")thenas(ac)=as(ac)+10:goto22740
22734 if(k$="<")thenas(ac)=as(ac)-100:goto22740
22735 if(k$=">")thenas(ac)=as(ac)+100:goto22740
22736 if(k$="_")thenas(ac)=as(ac)-1000:goto22740
22737 if(k$="^")thenas(ac)=as(ac)+1000:goto22740
22739 goto22710

22740 if(as(ac)<0)thenas(ac)=0
22741 if(as(ac)>65535)thenas(ac)=65535
22742 bu(ac*32+31)=int(as(ac)/256):bu(ac*32+30)=as(ac)-bu(ac*32+31)
22743 goto22700

22790 print"{rvof}";:gosub50600:goto20200


;*** copy date/time to buffer 1-5
22800 pp=0:goto22810
22801 pp=1:goto22810
22802 pp=2:goto22810
22803 pp=3:goto22810
22804 pp=4:rem goto22810

22810 fori=0to4
22811 : pu(pp,i)=bu(ac*32+25+i)
22812 next

22819 return


;*** read date/time from buffer 1-5
22850 pp=0:goto22860
22851 pp=1:goto22860
22852 pp=2:goto22860
22853 pp=3:goto22860
22854 pp=4:rem goto22860

22860 fori=0to4
22861 : bu(ac*32+25+i)=pu(pp,i)
22862 next

22870 nr=ac
22871 gosub61900:rem convert date/time to ascii
22872 gosub50300:gosub50400:rem print date and time

22879 return


;*** reset date/time
22900 ay$(ac)="00":bu(ac*32+25)=0
22901 am$(ac)="00":bu(ac*32+26)=0
22902 ad$(ac)="00":bu(ac*32+27)=0
22903 nr=ac:gosub50300:rem update date
22910 a0$(ac)="00":bu(ac*32+28)=0
22911 a1$(ac)="00":bu(ac*32+29)=0
22912 nr=ac:gosub50400:rem update time
22949 return


;*** print buffer/date
22950 printright$("00"+mid$(str$(pu(pp,2)),2),2);"/";
22951 printright$("00"+mid$(str$(pu(pp,1)),2),2);"/";
22952 printright$("00"+mid$(str$(pu(pp,0)),2),2);
22959 return


;*** print buffer/time
22960 printright$("00"+mid$(str$(pu(pp,3)),2),2);":";
22961 printright$("00"+mid$(str$(pu(pp,4)),2),2);
22969 return




;*** select native-mode sub-directory **********************************
;*** initialize
30000 tr=nt:se=ns:dc=0
30010 gosub10800:rem analyzing directory
30011 gosub10100:rem clear file table
30020 gosub60100:rem open i/o
30030 y=6:gosub10900:rem clear line

30100 printy$(6);x$(3);
30101 print"{grn}tr:{lgrn}";right$("00"+mid$(str$(tr),2),3);" ";
30102 print"{grn}se:{lgrn}";right$("00"+mid$(str$(se),2),3)

30110 gosub61000:rem read block
30120 gosub60300:rem read status
30125 if(e$<>"00")thengoto30300
30130 fori=0to255step32
30135 : printy$(6);x$(19);dc
30140 : print#15,"b-p";5;i+2
30145 : get#5,a$:at=asc(a$+chr$(0))and127
30150 : if(at<>6)thengoto30180
30160 : dc=dc+1
30161 : get#5,a$:n0(dc)=asc(a$+chr$(0))
30162 : get#5,a$:n1(dc)=asc(a$+chr$(0))
30170 : n$(dc)="":forj=1to16:get#5,a$:n$(dc)=n$(dc)+a$:next
30180 next

;*** get link bytes
30200 gosub61010:rem set position to 1st byte in buffer
30210 get#5,a$:tr=asc(a$+chr$(0))
30215 get#5,a$:se=asc(a$+chr$(0))
30220 if(tr>0)and((dc+8)<md)thengoto30100

;*** directory buffer full/disk error
30300 gosub60200:rem close i/o
30310 if(e$<>"00")thengosub11900:goto30590

;*** get parent directory
30320 gosub60100:rem open i/o
30321 tr=nt:se=ns:gosub61000:rem read block
30322 gosub60300:rem read status
30323 if(e$<>"00")thengoto30350

;*** get tr/se for parent directory
30330 print#15,"b-p";5;34
30331 get#5,a$:pt=asc(a$+chr$(0))
30332 get#5,a$:ps=asc(a$+chr$(0))

;*** get directory name
30340 if(pt=0)thendd$="root":goto30350
30341 print#15,"b-p";5;4
30342 dd$="":fori=1to16:get#5,a$:dd$=dd$+a$:next

;*** done...
30350 gosub60200:rem close i/o
30351 if(e$<>"00")thengosub11900:goto30590
30360 if(dc=0)and(pt=0)thengoto30590
30370 n$(0)="..":n0(0)=pt:n1(0)=ps

;*** initialize select directory
30400 if(pt=0)thencd=1:rem root directory
30405 if(pt>0)thencd=0:rem subdirectory
30410 gosub10500:rem clear status
30420 printy$(5);x$(3);
30430 print"{grn}select directory:{lgrn}/";dd$

30440 y=25:gosub10900:rem clear line
30441 printy$(25);x$(2);
30442 print"{lgrn}return:{grn}open ";
30443 print"{lgrn}crsr up/dn:{grn}select {lgrn}_:{grn}done";

;*** print current selected directory
30500 y=6:gosub10900:rem clear line
30501 printy$(6);x$(3);
30505 print"{lgrn}";n$(cd)

;*** let the user select a new directory
30510 getk$:if(k$="")thengoto30510
30520 if(k$="{up}")and(cd>0)thencd=cd-1:goto30500
30521 if(k$="{down}")and(cd<dc)thencd=cd+1:goto30500
30522 if(k$="_")or(k$="^")thengoto30590
30523 if(k$<>chr$(13))thengoto30510
30530 if(n0(cd)=0)thengoto30510
30540 nt=n0(cd):ns=n1(cd)
30550 goto30000

; exit
30590 return




;*** select new disk drive *********************************************
;*** initialize
31000 y=25:gosub10900:rem clear line
31001 printy$(25);x$(2);
31002 print"{lgrn}return:{grn}done ";
31003 print"{lgrn}+/-:{grn}select drive {lgrn}_:{grn}cancel";

31100 db=dv:dm=dt
31110 gosub10500:rem clear status
31120 gosub10100:rem clear file table

;*** select new device
31200 lo=dv:gosub10600:rem print "select new device..."
31210 getk$:if(k$="")thengoto31210
31220 if(k$=chr$(13))and(dt>0)thengoto31400
31221 if(k$="_")thendv=db:dt=dm:gosub10400:goto31490

;*** switch device address
31230 if(k$="+")thendv=dv+1:if(dv=30)thendv=8
31231 if(k$="-")thendv=dv-1:if(dv<8)thendv=29
31232 if(k$<>"+")and(k$<>"-")goto31210

;*** test device address
31300 dt=0:gosub10400:rem print device info
31310 open15,dv,15:close15
31311 if(st=0)thengoto31320
31312 if(lo=dv)thengoto31200
31313 goto31230

;*** new device found
31320 gosub10700:rem print "analyzing device..."
31330 gosub63000:rem get device type
31331 if(e$<>"00")or(dt=0)thengoto31230
31332 if(k$=chr$(13))and(dt>0)thengoto31400
31333 if(e$="00")thenlo=dv
31340 gosub10400:rem print device info
31390 goto31200

;*** device selected, exit...
31400 gosub10300:rem clear device info
31410 gosub10400:rem print device info
31420 gosub10500:rem clear status
31490 return




;*** print file information ********************************************
;*** print complete file table
50000 fornr=0to7
50010 : gosub10200:rem clear file entry
50020 : gosub50100:rem print file entry
50030 next
50090 return

;*** print complete file entry
50100 po=nr*32
50110 if(nr=ac)thenprint"{lgrn}";
50111 if(nr<>ac)thenprint"{grn}";
50120 gosub50200:print" ";:rem print file name
50125 if(bu(po+2)=0)thengoto50190
50130 gosub50310:rem print date
50140 gosub50410:rem print time
50150 gosub50500:print" ";:rem print file info
50160 gosub50610:rem print file size
50190 return

;*** print file name
50200 printy$(8+nr*2);x$(3);chr$(48+nr+1);" ";
50210 if((bu(po+2)and127)>0)thenprintan$(nr);
50220 if((bu(po+2)and127)=0)thenprint"-----empty!-----";
50290 return

;*** print date
50300 printy$(8+nr*2);x$(22);
50310 printad$(nr);"/";am$(nr);"/";ay$(nr);"  ";
50390 return

;*** print time
50400 printy$(8+nr*2);x$(32);
50410 printa0$(nr);":";a1$(nr)
50490 return

;*** print file info
50500 printy$(8+nr*2+1);x$(5);
50510 print"type: ";ai$(nr);"     ";
50590 return

;*** print file size
50600 printy$(8+nr*2+1);x$(22);
50610 print"size: ";right$(sp$+str$(as(nr)),5);" bl."
50690 return




;*** core disk i/o *****************************************************
;*** open i/o channel
60100 open15,dv,15
60110 open 5,dv, 5,"#"
60190 return

;*** close i/o channel
60200 close5:close15
60290 return

;*** get device status
60300 input#15,e$,ei$,et$,es$
60390 return




;*** disk i/o **********************************************************
;*** read block
61000 print#15,"u1 5 0 ";tr;se:return
;*** set buffer pointer
61010 print#15,"b-p";5;0:return
;*** write block
61020 print#15,"u2 5 0 ";tr;se:return


;*** read block from disk
61100 gosub60100:rem open i/o
61101 tr=d0:se=d1
61102 gosub61000:rem read block
61110 gosub60300:rem read status
61111 if(e$<>"00")thengoto61180
61120 y=6:gosub10900:rem clear line
61130 fori=0to255step32:print#15,"b-p";5;i
61131 : printy$(6);x$(3);"{grn}reading data:{lgrn}";int(i/32)+1;"{left} "
61132 : forj=0to31:get#5,a$:bu(i+j)=asc(a$+chr$(0)):next
61133 next
61180 gosub60200:rem close i/o
61190 return

;*** read buffer from disk
61200 gosub10800:rem print "analyzing directory"
61210 gosub61100:rem get directory block
61211 if(e$<>"00")thengoto61290
61230 gosub61800:rem convert block data
61290 return


;*** write block to disk
61300 gosub60100:rem open i/o
61310 gosub60300:rem read status
61311 if(e$<>"00")thengoto61380
61320 y=6:gosub10900:rem clear line
61330 fori=0to255step32:print#15,"b-p";5;i
61331 : printy$(6);x$(3);"{grn}writing data:{lgrn}";int(i/32)+1;"{left} "
61332 : forj=0to31:print#5,chr$(bu(i+j));:next
61333 next
61340 tr=d0:se=d1:gosub61020
61350 gosub60300:rem get status
61380 gosub60200:rem close i/o
61390 return

;*** write buffer to disk
61400 gosub10850:rem print "updating directory"
61410 gosub61300:rem put directory block
61420 if(e$="00")thengoto61440
61430 gosub11900:rem print error
61440 gosub10500:rem clear status
61450 gosub11000:rem print disk name
61460 gosub11100:rem print directory block
61490 return


;*** read block using "u1" command...
61500 gosub60100:rem open i/o
61510 gosub61000:rem read block
61520 gosub60300:rem get status
61530 gosub60200:rem close i/o
61590 return


;*** convert buffer data to internal variables
61800 y=6:gosub10900:rem clear line
61801 printy$(6);x$(3);
61802 print"{grn}converting data:{lgrn}";

61810 fori=0to255step32
61811 : nr=int(i/32):printy$(6);x$(19);(nr+1)
61812 : gosub61950:gosub61900
61813 next

61890 return


;*** convert date/time to ascii
61900 ay$(nr)=right$("00"+mid$(str$(bu(nr*32+25)),2),2)
61901 am$(nr)=right$("00"+mid$(str$(bu(nr*32+26)),2),2)
61902 ad$(nr)=right$("00"+mid$(str$(bu(nr*32+27)),2),2)
61903 a0$(nr)=right$("00"+mid$(str$(bu(nr*32+28)),2),2)
61904 a1$(nr)=right$("00"+mid$(str$(bu(nr*32+29)),2),2)
61949 return

;*** convert name, type and size
61950 po=nr*32
61960 at(nr)=bu(po+2):ft=(at(nr)and15):if(ft>6)thenft=9
61961 ai$(nr)=ty$(ft)
61962 if((bu(po+2)and64)>0)thenai$(nr)=ai$(nr)+"<"
61963 if((bu(po+2)and128)=0)thenif(bu(po+2)>0)thenai$(nr)=ai$(nr)+"*"
61964 ai$(nr)=left$(ai$(nr)+"  ",5)
61965 an$(nr)="":forj=0to15:an$(nr)=an$(nr)+chr$(bu(po+5+j)):next
61966 as(nr)=bu(po+30)+bu(po+31)*256
61999 return




;*** get device mode data **********************************************
;*** define first directory sector...
;  -> c=1541/1571/1581
62000 if(dt=1)thend0=18:d1=1:return
62010 if(dt=2)thend0=18:d1=1:return
62020 if(dt=3)thend0=40:d1=3:return
; -> native mode
62030 gosub60100
62031 tr=nt:se=ns:gosub61000:gosub61010
62032 get#5,a$,b$:d0=asc(a$+chr$(0)):d1=asc(b$+chr$(0))
62033 gosub60200
62090 return


;*** define directory header sector
62100 if(dt=1)thend0=18:d1=0:d2=144:return
62110 if(dt=2)thend0=18:d1=0:d2=144:return
62120 if(dt=3)thend0=40:d1=0:d2=4:return
62130 if(dt=4)thend0=rt:d1=rs:d2=4:return


;*** get disk name
62200 gosub62100
62210 gosub60100:rem open i/o
62220 tr=d0:se=d1:gosub61000
62230 print#15,"b-p";5;d2
62240 dn$="":fori=1to16:get#5,a$:dn$=dn$+a$:next
62250 gosub60200:rem close i/o
62290 return


;*** open selected directory
;ac points to the current entry in the disk buffer.
62300 nt=bu(ac*32+3):ns=bu(ac*32+4):dd$=an$(ac)
62390 return


;*** open root directory
;this will set the current directory to /root.
62400 nt=rt:ns=rs
62490 return


;*** open parent directory
62500 gosub60100:rem open i/o
62510 tr=nt:se=ns:gosub61000
62520 print#15,"b-p";5;34
62530 get#5,a$:nt=asc(a$+chr$(0))
62531 get#5,a$:ns=asc(a$+chr$(0))
62540 tr=nt:se=ns:gosub61000
62541 print#15,"b-p";5;4
62542 dd$="":fori=1to16:get#5,a$:dd$=dd$+a$:next
62550 gosub60200:rem close i/o
62590 return




;*** detect device mode ************************************************
;the following code is used to recognize a 1541/71/81/nm
;mode for the selected drive. the mode is detected with
;a "u1" block-read command. depending on track/sector, an
;error is returned if the sector is not available.
63000 gosub60100:print#15,"i0:":gosub60200
63010 dt=4:tr= 1:se=100:gosub61500:if(e$="00")thengosub62400:goto63090
63011 dt=3:tr=80:se=  1:gosub61500:if(e$="00")thengoto63090
63012 dt=2:tr=70:se=  1:gosub61500:if(e$="00")thengoto63090
63013 dt=1:tr= 1:se=  1:gosub61500:if(e$="00")thengoto63090
63020 dt=0:rem unknwon device mode
63090 return
