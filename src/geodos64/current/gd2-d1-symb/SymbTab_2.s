; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Systemlabels.
;******************************************************************************

;*** Tastatur-Labels.
:KEY_F1			= $01
:KEY_F2			= $02
:KEY_F3			= $03
:KEY_F4			= $04
:KEY_F5			= $05
:KEY_F6			= $06
:KEY_F7			= $0e
:KEY_F8			= $0f

:KEY_LEFT		= $08
:KEY_UP			= $10
:KEY_DOWN		= $11
:KEY_HOME		= $12
:KEY_CLEAR		= $13
:KEY_LARROW		= $14
:KEY_UPARROW		= $15
:KEY_STOP		= $16
:KEY_RUN		= $17
:KEY_BPS		= $18
:KEY_INSERT		= $1c
:KEY_DELETE		= $1d
:KEY_RIGHT		= $1e
:KEY_INVALID		= $1f

;*** Flags setzen/löschen.
;Schriftstil definieren.
:SET_PLAINTEXT		= %00000000
:SET_SUBSCRIPT		= %00000010
:SET_SUPERSCRIPT	= %00000100
:SET_OUTLINE		= %00001000
:SET_ITALIC		= %00010000
:SET_REVERSE		= %00100000
:SET_BOLD		= %01000000
:SET_UNDERLINE		= %10000000

;Prozesse definieren.
:SET_RUNABLE		= %10000000
:SET_BLOCKED		= %01000000
:SET_FROZEN		= %00100000
:SET_NOTIMER		= %00010000

:SET_DB_POS		= %00000000

;":mouseOn" definieren.
:SET_MSE_ON		= %10000000
:SET_MENUON		= %01000000
:SET_ICONSON		= %00100000

;":pressFlag" definieren.
:SET_KEYPRESS		= %10000000
:SET_INPUTCHG		= %01000000
:SET_MOUSE		= %00100000

;":PutDecimal" definieren.
:SET_LEFTJUST		= %10000000
:SET_RIGHTJUST		= %00000000
:SET_SUPRESS		= %01000000
:SET_NOSUPRESS		= %00000000

;":faultData" definieren.
:SET_OFFTOP		= %10000000
:SET_OFFBOTTOM		= %01000000
:SET_OFFLEFT		= %00100000
:SET_OFFRIGHT		= %00010000
:SET_OFFMENU		= %00001000

;":GetFile" definieren.
:ST_LD_AT_ADDR		= %00000001
:ST_LD_DATA		= %10000000
:ST_PR_DATA		= %01000000

;*** RAM-Modi.
:RAM_64K		= $30
:IO_IN			= $35
:KRNL_IO_IN		= $36
:KRNL_BAS_IO_IN		= $37

;*** Labels für Menüdefinition.
:UN_CONSTRAINED		= %00000000
:CONSTRAINED		= %01000000

:MENU_ACTION		= %00000000
:DYN_SUB_MENU		= %01000000
:SUB_MENU		= %10000000

:HORIZONTAL		= %00000000
:VERTICAL		= %10000000

;*** Labels für Disketteninformationen.
;Dateityp definieren.
:SEQ			= $01
:PRG			= $02
:USR			= $03
:REL			= $04
:CBM			= $05
:NATIVE_DIR		= $06

;Dateiformat definieren.
:SEQUENTIAL		= $00
:VLIR			= $01

;Schreibschutz definieren.
:ST_WR_PR		= %01000000
:ST_NO_WR_PR		= %00000000

;*** Labels zur Zeichenausgabe.
:BACKSPACE		= $08
:FORWARDSPACE		= $09
:TAB			= $09
:LF			= $0a
:HOME			= $0b
:PAGE_BREAK		= $0c
:UPLINE			= $0c
:CR			= $0d
:ULINEON		= $0e
:ULINEOFF		= $0f
:ESC_GRAPHICS		= $10
:ESC_RULER		= $11
:REV_ON			= $12
:REV_OFF		= $13
:GOTOX			= $14
:GOTOY			= $15
:GOTOXY			= $16
:NEWCARDSET		= $17
:BOLDON			= $18
:ITALICON		= $19
:OUTLINEON		= $1a
:PLAINTEXT		= $1b
:SHORTCUT		= $80

;*** Labels für GraphicsString.
:MOVEPENTO		= $01
:LINETO			= $02
:RECTANGLETO		= $03
:PENFILL		= $04
:NEWPATTERN		= $05
:ESC_PUTSTRING		= $06
:FRAME_RECTO		= $07
:PEN_X_DELTA		= $08
:PEN_Y_DELTA		= $09
:PEN_XY_DELTA		= $0a

;*** Einsprünge im Druckertreiber.
:InitForPrint		= $7900
:StartPrint		= $7903
:PrintBuffer		= $7906
:StopPrint		= $7909
:GetDimensions		= $790c
:PrintASCII		= $790f
:StartASCII		= $7912
:SetNLQ			= $7915

;*** Fehlermeldungen.
:NO_ERROR		= $00
:NO_BLOCKS		= $01
:INV_TRACK		= $02
:INSUFF_SPACE		= $03
:FULL_DIRECTORY		= $04
:FILE_NOT_FOUND		= $05
:BAD_BAM		= $06
:UNOPENED_VLIR		= $07
:INV_RECORD		= $08
:OUT_OF_RECORDS		= $09
:STRUCT_MISMAT		= $0a
:BFR_OVERFLOW		= $0b
:CANCEL_ERR		= $0c
:DEV_NOT_FOUND		= $0d
:INCOMPATIBLE		= $0e
:HDR_NOT_THERE		= $20
:NO_SYNC		= $21
:DBLK_NOT_THERE		= $22
:DAT_CHKSUM_ERR		= $23
:WR_VER_ERR		= $25
:WR_PR_ON		= $26
:HDR_CHKSUM_ERR		= $27
:DSK_ID_MISMAT		= $29
:BYTE_DEC_ERR		= $2e
:NO_PARTITION		= $30
:PART_FORMAT_ERR	= $31
:ILLEGAL_PARTITION	= $32
:NO_PART_FD_ERR		= $33
:ILLEGAL_DEVICE		= $40
:NO_FREE_RAM		= $60
:DOS_MISMATCH		= $73

;*** GEOS-Dateytyp definieren.
:NOT_GEOS		= $00
:BASIC			= $01
:ASSEMBLY		= $02
:DATA			= $03
:SYSTEM			= $04
:DESK_ACC		= $05
:APPLICATION		= $06
:APPL_DATA		= $07
:FONT			= $08
:PRINTER		= $09
:INPUT_DEVICE		= $0a
:DISK_DEVICE		= $0b
:SYSTEM_BOOT		= $0c
:TEMPORARY		= $0d
:AUTO_EXEC		= $0e
:INPUT_128		= $0f
:GATEWAY_DIR		= $10
:GATEWAY_DOC		= $11
:GEOSHELL_COM		= $15
:GEOFAX_PRINTER		= $16

;*** Anwender-Register.
:a0L			= $fb
:a0H			= $fc
:a0			= $00fb
:a1L			= $fd
:a1H			= $fe
:a1			= $00fd
:a2L			= $70
:a2H			= $71
:a2			= $0070
:a3L			= $72
:a3H			= $73
:a3			= $0072
:a4L			= $74
:a4H			= $75
:a4			= $0074
:a5L			= $76
:a5H			= $77
:a5			= $0076
:a6L			= $78
:a6H			= $79
:a6			= $0078
:a7L			= $7a
:a7H			= $7b
:a7			= $007a
:a8L			= $7c
:a8H			= $7d
:a8			= $007c
:a9L			= $7e
:a9H			= $7f
:a9			= $007e
