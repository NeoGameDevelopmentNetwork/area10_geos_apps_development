; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
;--- UCI: Control/Status-Register
:UCI_CONTROL             = $df1c  ;Write
:UCI_STATUS              = $df1c  ;Read
:UCI_COMDATA             = $df1d  ;Write
:UCI_IDENTIFY            = $df1d  ;Read
:UCI_DATAINFO            = $df1e  ;Read only
:UCI_DATASTATUS          = $df1f  ;Read only

;--- UCI: Status-Bits
;Siehe firmware/command_intf.h
:CMD_NEW_CMD             = %00000001
:CMD_DATA_ACC            = %00000010
:CMD_ABORT               = %00000100
:CMD_ERROR               = %00001000

:CMD_STATE_BITS          = %00110000

:CMD_STATE_IDLE          = %00000000
:CMD_STATE_BUSY          = %00010000
:CMD_STATE_DLAST         = %00100000
:CMD_STATE_DMORE         = %00110000
;CMD_STATE_STAT_AV       = %01000000
;CMD_STATE_DATA_AV       = %10000000

;--- UCI: Kennbyte
:UCI_IDENTIFIER          = $c9

;--- UCI: Targets
:UCI_TARGET_DOS1         = $01
:UCI_TARGET_DOS2         = $02
:UCI_TARGET_NET          = $03
:UCI_TARGET_CTRL         = $04
endif

if .p
;--- UCI: Target/DOS
;Siehe firmware/software/filemanager/dos.h
:DOS_CMD_IDENTIFY        = $01
:DOS_CMD_OPEN_FILE       = $02
:DOS_CMD_CLOSE_FILE      = $03
:DOS_CMD_READ_DATA       = $04
:DOS_CMD_WRITE_DATA      = $05
:DOS_CMD_FILE_SEEK       = $06
:DOS_CMD_FILE_INFO       = $07
:DOS_CMD_FILE_STAT       = $08
:DOS_CMD_DELETE_FILE     = $09
:DOS_CMD_RENAME_FILE     = $0a
:DOS_CMD_COPY_FILE       = $0b
:DOS_CMD_CHANGE_DIR      = $11
:DOS_CMD_GET_PATH        = $12
:DOS_CMD_OPEN_DIR        = $13
:DOS_CMD_READ_DIR        = $14
:DOS_CMD_CREATE_DIR      = $16
:DOS_CMD_COPY_HOME_PATH  = $17
:DOS_CMD_LOAD_REU        = $21
:DOS_CMD_SAVE_REU        = $22
:DOS_CMD_MOUNT_DISK      = $23
:DOS_CMD_UMOUNT_DISK     = $24
:DOS_CMD_SWAP_DISK       = $25
:DOS_CMD_GET_TIME        = $26
:DOS_CMD_SET_TIME        = $27

;--- UCI: Target/Control
;Siehe firmware/software/io/command_interface/control_target.h
:CTRL_CMD_IDENTIFY       = $01
:CTRL_CMD_FREEZE         = $05
:CTRL_CMD_REBOOT         = $06
:CTRL_CMD_GET_HWINFO     = $28
:CTRL_CMD_GET_DRVINFO    = $29
:CTRL_CMD_ENABLE_DISK_A  = $30
:CTRL_CMD_DISABLE_DISK_A = $31
:CTRL_CMD_ENABLE_DISK_B  = $32
:CTRL_CMD_DISABLE_DISK_B = $33
:CTRL_CMD_DISK_A_POWER   = $34
:CTRL_CMD_DISK_B_POWER   = $35

;--- UCI: Target/Network
;Siehe firmware/software/network/network_target.h
:NET_CMD_IDENTIFY        = $01
:NET_CMD_GET_IF_COUNT    = $02
;NET_CMD_SET_INTERFACE   = $03  ;Nicht in Firmware enthalten.
:NET_CMD_GET_MAC         = $04
:NET_CMD_GET_IPADDR      = $05
;NET_CMD_SET_IPADDR      = $06
:NET_CMD_OPEN_TCP        = $07
:NET_CMD_OPEN_UDP        = $08
:NET_CMD_CLOSE_SOCKET    = $09
:NET_CMD_READ_SOCKET     = $10
:NET_CMD_WRITE_SOCKET    = $11

:NET_INTERFACE           = $00  ;Netzwerk-Schnittstelle, immer $00.
endif

if .p
;-- Datenspeicher (mind. 512Bytes!):
:UCI_DATA_MSG            = diskBlkBuf

;--- Timout-Zähler:
:CMD_TIMEOUT             = 100  ;C64: ca.10+5sek, C128: ca.5+5sek.
;Hinweis: Von 5-0 wird in der Timeout-
;Schleife zusätzlich 1Sek. gewartet.
:CMD_DELAY               = 64   ;Nur Werte von 1-255!
:NET_RETRY               = 10   ;Wiederholungszähler für READ_SOCKET.

;--- Fehlercodes:
:UCI_NO_ERROR            = $00
:UCI_ERR_NOUDEV          = $40
:UCI_ERR_TIMEOUT         = $41
:UCI_ERR_STATUS          = $42
:UCI_NO_STATUS           = $43
:UCI_NO_DATA             = $44

:NO_ERROR                = $00
:FILE_NOT_FOUND          = $05
:CANCEL_ERR              = $0c
:DEV_NOT_FOUND           = $0d

;--- C64-Uhrzeit (BCD-Format):
:cia1tod_t               = $dc08  ;1/10 seconds.
:cia1tod_s               = $dc09  ;Seconds.
:cia1tod_m               = $dc0a  ;Minutes.
:cia1tod_h               = $dc0b  ;Hours, Bit#7=1: PM.

;--- C128:
:MMU128                  = $ff00
:RAMCONF128              = $d506
:CLKRATE128              = $d030

;--- Laufwerksformate:
:Drv1541                 = $01
:Drv1571                 = $02
:Drv1581                 = $03
:DrvNative               = $04
:ST_DMODES               = %00000111

;--- Adressen:
:ZPAGE                   = $0000
:CREU_RAMREG             = $df00
:GRAM_RAMDATA            = $de00
:GRAM_RAMPAGE            = $dffe
:GRAM_RAMBANK            = $dfff
endif
