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
; 01000.main-init.bas - init program
;

; Main init, test for C64/C128
1000 if(abs(peek(65533)=255)=0)thengoto1100

; C128 only: Redefine function keys
1010 key 1,chr$(133):key 3,chr$(134):key 5,chr$(135):key 7,chr$(136)
1011 key 2,chr$(137):key 4,chr$(138):key 6,chr$(139):key 8,chr$(140)
1020 goto1200

; C64 only: Set screen colors
; > 53280,0 = border color
; > 53281,0 = backscreen color
; > 646,5   = text color
1100 poke53280,0:poke53281,0:poke646,5

; C64/C128: Switch to upper case
1200 print"{clr}":rem chr$(142) forced upper case disabled for now...

; Disable parallel cable between CMD-RAMLink/CMD-HD.
; ::@p0: may be helpful for some basic compilers...
; Note: Looks like this command is not really needed.
;       Disabled for now...
1210 rem ifpeek(57513)=120then: ::@p0:

