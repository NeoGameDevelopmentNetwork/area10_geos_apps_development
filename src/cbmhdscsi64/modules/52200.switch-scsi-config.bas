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
; 52200.switch-scsi-config.bas - set new scsi device with config mode
;
; note: device must be initialized/formatted
; parameter: h1    = cmd-hd default device address
;            sd    = cmd-hd scsi device id
; return   : -
; temporary: he$,by
;

; Switch SCSI-device
; Note: Configuration mode must be active!
;       CMD-HD must be set to device #30.
;
; After enable config mode and switch the
; SCSI device HD-TOOLS.64 can be used to
; edit the partition table.
52200 dv=hd:rem hd=cmd-hd in config mode
52201 by=sd:gosub60200:sd$=he$

; Create small assembler application that will
; be executed in ram of the CMD-HD to switch
; the currently active SCSI device.
52210 he$=    "a901"   :rem lda #$01
52211 he$=he$+"8daa30" :rem sta $30aa
; set new scsi-id and read new system header
52212 he$=he$+"a9"+sd$ :rem lda #$xx
52213 he$=he$+"200ed1" :rem jsr $d10e
52214 he$=he$+"4c3de5" :rem jmp $e53d

; Send program to CMD-HD and execute it
52250 gosub51950:return
