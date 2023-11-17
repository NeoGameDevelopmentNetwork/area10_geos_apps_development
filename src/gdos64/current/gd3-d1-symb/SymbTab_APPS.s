; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Symbole für Anwendungen.
;******************************************************************************

;*** Schriftstil definieren.
:SET_PLAINTEXT		= %00000000
:SET_SUBSCRIPT		= %00000010
:SET_SUPERSCRIPT	= %00000100
:SET_OUTLINE		= %00001000
:SET_ITALIC		= %00010000
:SET_REVERSE		= %00100000
:SET_BOLD		= %01000000
:SET_UNDERLINE		= %10000000

;*** Prozesse definieren.
:SET_RUNABLE		= %10000000
:SET_BLOCKED		= %01000000
:SET_FROZEN		= %00100000
:SET_NOTIMER		= %00010000

;*** ":mouseOn" definieren.
:SET_MSE_ON		= %10000000
:SET_MENUON		= %01000000
:SET_ICONSON		= %00100000

;*** ":pressFlag" definieren.
:SET_KEYPRESS		= %10000000
:SET_INPUTCHG		= %01000000
:SET_MOUSE		= %00100000

;*** ":PutDecimal" definieren.
:SET_LEFTJUST		= %10000000
:SET_RIGHTJUST		= %00000000
:SET_SUPRESS		= %01000000
:SET_NOSUPRESS		= %00000000

;*** ":faultData" definieren.
:SET_OFFTOP		= %10000000
:SET_OFFBOTTOM		= %01000000
:SET_OFFLEFT		= %00100000
:SET_OFFRIGHT		= %00010000
:SET_OFFMENU		= %00001000

;*** ":GetFile" definieren.
:ST_LD_AT_ADDR		= %00000001
:ST_LD_DATA		= %10000000
:ST_PR_DATA		= %01000000

;*** Symbole für Menüdefinition.
:UN_CONSTRAINED		= %00000000
:CONSTRAINED		= %01000000

:MENU_ACTION		= %00000000
:DYN_SUB_MENU		= %01000000
:SUB_MENU		= %10000000

:HORIZONTAL		= %00000000
:VERTICAL		= %10000000

;*** CBM-Dateityp definieren.
:SEQ			= $01
:PRG			= $02
:USR			= $03
:REL			= $04
:CBM			= $05
:DIR			= $06

;** Filter CBM-Dateityp.
:ST_FMODES		= %00000111

;*** Dateiformat definieren.
:SEQUENTIAL		= $00
:VLIR			= $01

;*** Schreibschutz definieren.
:ST_WR_PR		= %01000000
:ST_NO_WR_PR		= %00000000

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
