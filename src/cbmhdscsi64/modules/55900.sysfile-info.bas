; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmHDscsi64
;
; 55900.sysfile-info.bas - read system header info
;
; parameter: ga    = system file device
; return   : es    = error status
; temporary: a$,b$
; extern   : dc    = hdos block counter
;            dh/dl = hdos checksum hash
;            d1/d2 = hdos system ram base address low/high
;            db    = hdos system ram base address
;            gc    = geos block counter
;            gh/dl = geos checksum hash
;            g1/g2 = geos system ram base address
;            gb    = geos system ram base address
;

; Read system header info
55900 open2,ga,0,"system header"

; Skip load address
55910 get#2,a$,a$

; Unknown byte
55920 get#2,a$

; Block count, system address, hash high/low
55921 get#2,dc$,d1$,d2$,dh$,dl$

; Skip data bytes
55935 fori=6to63:get#2,a$:next

; Unknown byte
55940 get#2,a$

; Block count, system address, hash high/low
55941 get#2,gc$,g1$,g2$,gh$,gl$

; Close system file
55950 close2

; Create external variables for main o.s.
55960 dc=asc(dc$+nu$):dh=asc(dh$+nu$):dl=asc(dl$+nu$)
55963 d1=asc(d1$+nu$):d2=asc(d2$+nu$):db=so+(d2*256+d1)/512

; Create external variables for main geos/hd driver.
55970 gc=asc(gc$+nu$):gh=asc(gh$+nu$):gl=asc(gl$+nu$)
55973 g1=asc(g1$+nu$):g2=asc(g2$+nu$):gb=so+(g2*256+g1)/512

55990 return
