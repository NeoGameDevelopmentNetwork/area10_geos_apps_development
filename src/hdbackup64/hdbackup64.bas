0 if(f>0)thengoto10
1 rem check for rdwrseklib in ram
2 fora=49152to49455:b=(b+peek(a))and255:next
3 if(b=25)thengoto10
4 :
5 ld=peek(186):rem load library from last device
6 print"loading 'rdwrseklib' file..."
7 print"device:";ld
8 f=1:load"rdwrseklib",ld,1
9 :
10 clr
11 poke53280,0:poke53281,0:poke646,5
99 :
100 dv=10 :rem cmd-hd device
105 bd=8  :rem backup device
110 sd=0  :rem scsi-id of the cmd-hd
120 vt$="":rem platform c64/c128 or vice emulator
199 :
200 se=0: rem start sector adress
210 mx=0: rem scsi counter for each chunk
220 ds=20320: rem chunk size in scsi-blocks / 40960 cbm blocks
230 sc=65536: rem sector count, will be replaced by size of the hdd
240 dc=0: rem chunk counter
250 dt$="backup#":rem backup file name
299 :
300 ba=49152+512: rem buffer adress c64/ram
999 :
1000 print"{clr}";chr$(14);chr$(8)
1010 print" HDBackup64 - V0.02 (w)2020/21 by M.K."
1011 print
1012 print" This program can be used to copy the"
1013 print" entire contents of a CMD-HD device to"
1014 print" an SD2IEC / VICE filesystem device."
1015 print
1020 print" Since drives up to 8Gb are possible"
1021 print" here, the copy is divided into smaller"
1022 print" sections of 10Mb each, which must be"
1023 print" joined together later on the PC."
1024 print
1030 print" WARNING!"
1031 print" If the program is used under VICE, the"
1032 print" option '-driveXfixedsize 0' must be"
1033 print" used for the CMD-HD drive, otherwise"
1034 print" VICE will report back a wrong value"
1035 print" for the drive size!"
1036 print
1040 print" Note: 1Mb will take up to 15min!!!"
1041 print"       (with RAMLink + parallel cable)"
1042 print
1050 print" Press any key to continue!"
1051 geta$:ifa$=""thengoto1051
1099 :
1100 print"{clr}{down} HDBackup64{down}"
1110 input" CMD-HD device (8-29)";dv
1111 if(dv<8)or(dv>29)thengoto1100
1112 open15,dv,15:close15:if(st<>0)thengoto1100
1113 open15,dv,15
1114 print#15,"m-r"+chr$(160)+chr$(254)+chr$(6)
1115 e$="":fori=1to6:get#15,a$:e$=e$+a$:next
1116 close15
1117 if(e$<>"cmd hd")thengoto1100
1119 :
1120 print"{down}{down} (No DiskImage must be mounted!)"
1121 print" On VICE use a filesystem device.{up}{up}{up}"
1122 input" SD2IEC device (8-29)";bd
1123 if(bd<8)or(bd>29)thengoto1100
1124 open15,bd,15:close15:if(st<>0)thengoto1100
1125 open15,bd,15:open2,bd,2,"#0"
1126 print#15,"u1 2 0 1 1":input#15,e$,ee$,e0$,e1$
1127 close2:close15:if(e$<>"30")and(e$<>"20")thengoto1100
1128 vt$="C64/C128":if(e$="30")thenvt$="VICE Emulator"
1129 :
1130 print"{down}{down}{down}{down} (Default = 0, change at your own risk){up}{up}"
1131 input" CMD-HD SCSI Device ID (0-6)";sd
1132 if(sd<0)or(sd>6)thengoto1100
1139 :
1140 print"{down}{down}{down} Resume with ";dt$;"NR (NR=1-x){up}{up}"
1141 input" Restart or resume (0=restart)";dc
1142 if(dc<0)thengoto1100
1143 if(dc=0)thengoto2000
1144 se=dc*ds:rem caluulate first sector
1149 :
2000 rem main program
2010 open15,dv,15
2020 print"{clr}{down} HDBackup64{down}"
2021 print" Waiting for CMD-HD device...{down}"
2022 gosub9000:rem wait for device ready
2023 gosub12000:rem send capacity
2024 gosub13000:rem read capacity
2025 rem if(int(tb*512/1024/1024)=8191)thentb=sc:rem workaround for vice
2026 tr=tb:rem backup total block count
2027 tb=tb-se: rem calculate remaining blocks
2030 print" Platform       : ";vt$
2031 print" CMD-HD device  :";dv;":";sd
2032 print" SD2IEC device  :";bd
2033 print
2034 print" CMD-HD capacity:";int(tr*512/1024/1024);"mb"
2035 print" (";tr;"512b-sectors ){down}"
2040 gosub14000:rem send scsi-inquiry command
2041 print" Vendor: ";i0$
2042 print" Model : ";i1$
2043 print"{down} Start with backup file:";dc
2044 print" Remaining backup size :";int(tb*512/1024/1024);"mb{down}"
2045 pa=int(tr/ds):if(pa<>(tr/ds))thenpa=pa+1
2046 print" Number of backup files:";pa
2047 print" (";int(ds*512/254);"blocks /";int(ds*512);"bytes ){down}"
2050 close15
2051 if((dc*ds)<tr)thengoto2060:rem test start backup file
2052 print"{down} Resume not possible:"
2053 print" Start with backup file";dc;"> max.";int(tr/ds)
2054 print" Press any key to restart..."
2055 geta$:ifa$=""thengoto2055
2056 goto1100
2059 :
2060 print"{down} Everything OK? Press 'SPACE' to"
2071 print" continue or any other key to CANCEL."
2080 geta$:ifa$=""thengoto2080
2081 if(a$<>" ")thengoto1100
2099 :
2100 print"{clr}{down} HDBackup64{down}"
2101 print" Sector: "
2102 print" Total :";tr;"sectors"
2110 open15,dv,15
2120 sc=tb:rem initialize sector count
2199 :
2200 rem loop / create dump files
2210 mx=sc:if(mx>ds)thenmx=ds
2220 open2,bd,2,"@0:"+dt$+mid$(str$(dc),2)+",p,w"
2230 mb=mx:gosub10000:rem read mx sectors to backup file
2240 close2:if(e>2)thengoto2300:rem error
2250 sc=sc-mb:if(sc>0)thendc=dc+1:goto2210
2299 :
2300 close15
2310 if(e=<2)thengoto2400
2320 print"{down}{down}{down}{down} Error";e
2330 stop
2399 :
2400 print"{clr}{down} HDBackup64{down}"
2410 print" All done!{down}"
2411 print" Except for the last part all files"
2412 print" must have a size of";int(ds*512/254);"blocks or"
2413 print int(ds*512);"bytes.{down}"
2414 print" Next step is to concatenate the"
2415 print" multiple backup files into one"
2416 print" DHD file. Examples:{down}"
2419 :
2420 print" Windows/DOS-shell:"
2421 print" copy /b ";dt$;"0 + ";dt$;".. backup.dhd"
2430 print" Linux/BASH:"
2431 print" cat ";dt$;"0 ";dt$;".. >backup.dhd"
2440 end
2999 :
9000 rem wait for device ready
9010 sc$=chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)+chr$(0)
9020 print#15,"s-c"+chr$(sd)+chr$(0)+chr$(64)+sc$
9030 get#15,a$:ifasc(a$+chr$(0))>127then9030
9090 return
9099 :
10000 rem loop / read mx sectors
10010 sh=int(se/65536):sm=int((se-sh*65536)/256):sl=se-sh*65536-sm*256
10020 print"{home}{down}{down}{down}{right}{right}{right}{right}{right}{right}{right}{right}";(se+1)
10030 gosub11000:if(e>2)thengoto10090
; 10040 gosub20000: rem basic read ram
10040 sys49152: rem rdwrseklib / read ram
; 10045 gosub21000: rem basic write data
10050 sys49161: rem rdwrseklib / write data
10050 se=se+1:mx=mx-1:ifmx>0then10010
10090 return
10099 :
11000 rem send scsi-read command
11010 sc$=chr$(40)+chr$(0)
11020 sc$=sc$+chr$(0)+chr$(sh)+chr$(sm)+chr$(sl)
11030 sc$=sc$+chr$(0)
11040 sc$=sc$+chr$(0)+chr$(1)
11050 sc$=sc$+chr$(0)
11060 print#15,"s-c"+chr$(sd)+chr$(0)+chr$(64)+sc$
11070 get#15,e$:e=asc(e$+chr$(0))
11090 return
11099 :
12000 rem send scsi-capacity command
12010 sc$=chr$(37)+chr$(0)
12020 sc$=sc$+chr$(0)+chr$(0)+chr$(0)+chr$(0)
12030 sc$=sc$+chr$(0)
12040 sc$=sc$+chr$(0)
12050 sc$=sc$+chr$(0)
12060 sc$=sc$+chr$(0)
12070 print#15,"s-c"+chr$(sd)+chr$(0)+chr$(64)+sc$
12090 return
12099 :
13000 rem read capacity
13010 print#15,"m-r"+chr$(0)+chr$(64)+chr$(4)
13020 get#15,a$,bh$,bm$,bl$
13030 bh=asc(bh$+chr$(0))
13031 bm=asc(bm$+chr$(0))
13032 bl=asc(bl$+chr$(0))
13040 bl=bl+1
13050 ifbl>255thenbl=0:bm=bm+1
13051 ifbm>255thenbm=0:bh=bh+1
13060 tb=bh*65536+bm*256+bl
13090 return
13099 :
14000 rem send scsi-inquiry command
14010 sc$=chr$(18)
14020 sc$=sc$+chr$(0)
14030 sc$=sc$+chr$(0)
14040 sc$=sc$+chr$(0)
14050 sc$=sc$+chr$(36)
14060 sc$=sc$+chr$(0)
14070 print#15,"s-c"+chr$(sd)+chr$(0)+chr$(64)+sc$
14099 :
14100 print#15,"m-r"+chr$(8)+chr$(64)+chr$(8)
14110 fori=0to7:get#15,a$:i0$=i0$+a$:next
14120 print#15,"m-r"+chr$(16)+chr$(64)+chr$(16)
14130 fori=0to15:get#15,a$:i1$=i1$+a$:next
14190 return
14199 :
; 20000 rem read sektor from hd-ram
; 20010 fora=0to511step32:printa;
; 20020 : ad=16384+a
; 20030 : hi=int(ad/256):lo=ad-hi*256
; 20040 : print#15,"m-r"+chr$(lo)+chr$(hi)+chr$(32)
; 20050 : forb=0to31:get#15,a$:c=asc(a$+chr$(0)):poke(ba+a+b),c:next
; 20060 next
; 20070 print
; 20090 return
; 20099 :
; 21000 rem send sektor to backup file
; 21010 fora=0to511
; 21020 : print#2,chr$(peek(ba+a));
; 21030 next
; 21090 return
