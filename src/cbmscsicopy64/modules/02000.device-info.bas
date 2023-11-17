; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 02000.device-info.bas - print device info
;

; Print all device info
2000 gosub2100:rem print cmd-hd device
2010 gosub2200:rem print scsi source
2020 gosub2300:rem print scsi target
2030 gosub2900:rem print menu message
2090 return


2100 printleft$(po$,3)
2110 print"{right}{right}";
2120 print"cmd-hd device:";right$("   "+str$(dd),2);
2190 return

;1234567890123456789012345678901234567890
;xx123:1234567890123456 b:12345 t:1234xx
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
