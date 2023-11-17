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
; 01800.main-menu-screen.bas - print main menu screen
;

; Print main menu
1800 gosub1900:rem cmd-hd device
1801 gosub1910:rem source device
1802 gosub1920:rem target device
1803 gosub1930:rem status info

; Print menu shortcuts
1850 printleft$(po$,17);
1851 print"  f1/f3 - source/target scsi device"
1852 print"  f2/f4 - source/target partition list"
1853 print"  f5/f7 - source/target partition +1"
1854 print"  f6/f8 - enter source/target part."
1855 print"  + / * - source/target partition +10"
1856 print"  c / h - begin copying/select cmd-hd"
1857 print"  s / t - source/target directory"
1858 print"  a / b - eject source/target media"
1859 print"  _     - exit program";
1890 return

; Print menu screen for cmd-hd device
1900 printleft$(po$,3);
1901 printc0$;li$;c1$
1902 printvi$;sl$;vi$
1903 printc2$;li$;c3$
1904 printleft$(po$,3);left$(ta$,30);"cmd-hd"
1909 return

; Print menu screen for source device
1910 printleft$(po$,6);
1911 printc0$;li$;c1$
1912 printvi$;sl$;vi$
1913 printvi$;sl$;vi$
1914 printc2$;li$;c3$
1915 printleft$(po$,6);left$(ta$,30);"source"
1919 return

; Print menu screen for target device
1920 printleft$(po$,10);
1921 printc0$;li$;c1$
1922 printvi$;sl$;vi$
1923 printvi$;sl$;vi$
1924 printc2$;li$;c3$
1925 printleft$(po$,10);left$(ta$,30);"target"
1929 return

; Print menu screen for status info
1930 printleft$(po$,14);
1931 printc0$;li$;c1$
1932 printvi$;sl$;vi$
1933 printc2$;li$;c3$
1934 printleft$(po$,14);left$(ta$,30);"status"
1939 return
