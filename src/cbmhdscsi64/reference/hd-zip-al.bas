; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; HD-ZIP(al).bas - Written by AL(?)
;
; A tool for C64/C128 which can be used to
; set a new SCSI device for the CMD-HD.
;
; Additional comments by Markus Kanet
; Version: V1.00 02/07/2020
;

   10 ifld>0then40
   20 clr:poke53280,0:poke53281,0:ga=peek(186):ifga<8thenga=8
   30 ld=1:load"HD-ZIP(al).ass",ga,1

; Enter new SCSI device address
; The new device address will be written into the programm
; that will be installed in the HD-RAM at $4000.
; See also HD-ZIP(al).ass

   40 input"{yel}{clr}{swlc}Neue SCSI-Geraeteadresse";dv:poke49194,dv

; Display note about setting CMD-HD into configuration mode
; Note: It should be possible to replace this using the CMD-89
;       autoexec code. Since there might be an unformatted disk
;       inside of the CMD-HD the autoexec code must be sent to
;       the CMD-HD manually. Enable config mode is then at $8E06.

   50 open15,30,15:close15:ifst<>0thenprint"{red}{down}{down}Bitte schalten Sie den Konfigurations-":print"modus Ihrer HD ein!"

; Install the HD-ZIP(al).ass programm in HD-RAM.
; Note: Most code of the program is used to find the correct
;       ROM routines in different HD-ROM versions.
;       Since only HD-ROM 2.80 supports the "COPYRIGHT CMD 89"
;       autoexec file the programm could be shortened.

   60 forx=0to136:a=peek(49152+x):a1$=a1$+chr$(a):next
   70 forx=0to136:a=peek(49152+137+x):a2$=a2$+chr$(a):next
   80 forx=0to18:a=peek(49152+2*137+x):a3$=a3$+chr$(a):next
   90 ifst<>0thenopen15,30,15:close15:goto90
  100 open15,30,15:print#15,"m-w"chr$(0)chr$(64)chr$(137)a1$
  110 print#15,"m-w"chr$(137)chr$(64)chr$(137)a2$
  120 print#15,"m-w"chr$(18)chr$(65)chr$(19)a3$

; Exit configuration mode after new SCSI device has been selected?

  130 print"{yel}{down}Konfigurationsmodus wieder abschalten?";
  140 getk$:ifk$<>"j"andk$<>"n"then140
  150 print" "k$

; Set SCSI device address and exit configuration mode.

  160 ifk$="j"thenprint#15,"m-e"chr$(9)chr$(64):goto180

; Only set SCSI device address.

  170 print#15,"m-e"chr$(0)chr$(64)

; Check for errors and exit.

  180 close15:ifst and 128<>0then210
  190 open15,30,15:get#15,er$:ifer$<>"0"then160
  200 close15

; Call CINT:$FF81 Reset screen editor.

  210 sys65409:end
