; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; initHDtools64.bas
; (w)2020 Markus Kanet
;
; Demo zum einschalten des Konfigurationsmodus
; an der CMD-HD und setzen eines neuen SCSI-Laufwerks.
; Das Programm setzt die Datei "COPYRIGHT CMD 89"-Datei
; auf der Standard-Partition der CMD-HD voraus.
;

  100 rem initialisierung
  110 hd=30  : rem fix / hd konfigmodus
  120 dv=15  : rem adresse cmd-hd
  130 sd=5   : rem scsi-geraet
  140 ld=8   : rem laufwerk hd-tools.64
  150 ht$="hd-tools.64"
  199 :
  200 rem hauptprogramm
  210 print "konfigurationsmodus ein..."
  215 gosub 1100 :rem konfigmodus ein
  219 :
  220 print "scsi-geraet testen..."
  221 print "(ggf. medium einlegen!)"
  225 gosub 1500 :rem geraet testen
  229 :
  230 print "scsi-geraet festlegen..."
  235 gosub 1300 :rem geraet festlegen
  239 :
  240 print "scsi-geraet starten..."
  245 gosub 1400 :rem geraet starten
  249 :
  250 print "hd-tools nachladen..."
  255 load ht$,ld
  259 :
  260 rem abbruch...
  270 print "datei nicht gefunden!"
  275 break
  299 :
  300 end
  999 :
 1000 rem warteschleife
 1010 poke162,0
 1020 ifpeek(162)<120then1020
 1030 return
 1099 :
 1100 rem konfigurationsmodus ein
 1110 open15,dv,15
 1120 s$="m-w"+chr$(0)+chr$(64)
 1130 c$=s$+chr$(3)
 1140 c$=c$+chr$(76)+chr$(6)+chr$(142)
 1150 print#15,c$
 1160 gosub1200
 1170 close15
 1180 return
 1199 :
 1200 rem hd-programm starten
 1210 print#15,"m-e"+chr$(0)+chr$(64)
 1220 gosub1000
 1230 return
 1299 :
 1300 rem scsi-geraet festlegen
 1310 open15,hd,15
 1320 c$=s$+chr$(13)
 1330 c$=c$+chr$(169)+chr$(1)
 1331 c$=c$+chr$(141)+chr$(170)+chr$(48)
 1340 c$=c$+chr$(169)+chr$(sd)
 1341 c$=c$+chr$(32)+chr$(14)+chr$(209)
 1350 c$=c$+chr$(76)+chr$(61)+chr$(229)
 1360 print#15,c$
 1370 gosub1200
 1380 close15
 1390 return
 1399 :
 1400 rem laufwerk starten
 1410 open15,hd,15
 1420 c$="s-c"+chr$(sd)+chr$(0)+chr$(64)
 1430 c$=c$+chr$(27)+chr$(0)+chr$(0)
 1440 c$=c$+chr$(0)+chr$(1)+chr$(0)
 1450 print#15,c$
 1460 gosub1200
 1470 close15
 1480 return
 1499 :
 1500 rem laufwerk testen
 1510 open15,hd,15
 1520 c$="s-c"+chr$(sd)+chr$(0)+chr$(64)
 1530 c$=c$+chr$(0)+chr$(0)+chr$(0)
 1540 c$=c$+chr$(0)+chr$(0)+chr$(0)
 1550 print#15,c$
 1551 get#15,a$:ifa$=""thena$=chr$(0)
 1552 ifasc(a$)<>0then1550
 1560 gosub1200
 1570 close15
 1580 return
