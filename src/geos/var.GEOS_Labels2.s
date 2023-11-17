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

;":iconSelFlag" definieren.
:ST_FLASH		= %10000000
:ST_INVERT		= %01000000

;":GetFile" definieren.
:ST_LD_AT_ADDR		= %00000001
:ST_LD_DATA		= %10000000
:ST_PR_DATA		= %01000000

;":dispBufferOn" definieren.
:ST_WRGS_FORE		= %00100000
:ST_WR_BACK		= %01000000
:ST_WR_FORE		= %10000000

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

;*** Modi für Dialogbox.
:DBTXTSTR		= $0b
:DBVARSTR		= $0c
:DBGETSTRING		= $0d
:DBSYSOPV		= $0e
:DBGRPHSTR		= $0f
:DBGETFILES		= $10
:DBOPVEC		= $11
:DBUSRICON		= $12
:DB_USR_ROUT		= $13

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

;*** Fehlermeldungen.
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
:HDR_CHKSUM_ERR		= $27
:DSK_ID_MISMAT		= $29
:BYTE_DEC_ERR		= $2e
:DOS_MISMATCH		= $73
