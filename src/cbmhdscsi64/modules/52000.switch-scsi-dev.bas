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
; 52000.switch-scsi-dev.bas - set new scsi device
;
; note: device must be initialized/formatted
; parameter: h1    = cmd-hd default device address
;            sd    = cmd-hd scsi device id
; return   : -
; temporary: he$,by
;

; Set new scsi-device
52000 by=h1:gosub60200:h1$=he$
52001 by=sd:gosub60200:sd$=he$

; Create small assembler application that will
; be executed in ram of the CMD-HD to switch
; the currently active SCSI device.
52010 he$=    "78"     :rem sei
; enable config mode
52011 he$=he$+"a992"   :rem lda #$92
52012 he$=he$+"8d0388" :rem sta $8803
52013 he$=he$+"a9e3"   :rem lda #$e3
52014 he$=he$+"8d0288" :rem sta $8802
52015 he$=he$+"20bad1" :rem jsr $d1ba

52016 he$=he$+"a901"   :rem lda #$01
52017 he$=he$+"8daa30" :rem sta $30aa
; set new scsi-id and read new system header
52018 he$=he$+"a9"+sd$ :rem lda #$xx
52019 he$=he$+"200ed1" :rem jsr $d10e
; enable LEDs?
52020 he$=he$+"ad008f" :rem lda $8f00
52021 he$=he$+"0920"   :rem ora #$20
52022 he$=he$+"8d008f" :rem sta $8f00
; set default address in new config data
52023 he$=he$+"a9"+h1$ :rem lda #$xx
52024 he$=he$+"8de190" :rem sta $90e1
52025 he$=he$+"8de490" :rem sta $90e4
; set new scsi-id/lun(0) in new hardware table
52030 he$=he$+"a9"+sd$ :rem lda #$xx
52031 he$=he$+"0a"     :rem asl
52032 he$=he$+"0a"     :rem asl
52033 he$=he$+"0a"     :rem asl
52034 he$=he$+"0a"     :rem asl
52035 he$=he$+"8d0090" :rem sta $9000
; disable LEDs?
52040 he$=he$+"ad008f" :rem lda $8f00
52041 he$=he$+"29df"   :rem and #$df
52042 he$=he$+"8d008f" :rem sta $8f00
; disable config mode and exit hd program
52043 he$=he$+"20b6dc" :rem jsr $dcb6
52044 he$=he$+"4c9fd0" :rem jmp $d09f

; Send program to CMD-HD and execute it
52050 gosub51950:return
