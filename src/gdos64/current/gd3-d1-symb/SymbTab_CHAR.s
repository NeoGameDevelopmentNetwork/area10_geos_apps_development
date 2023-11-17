; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Symbole für Zeichenausgabe.
;******************************************************************************

;*** Symbole für PutString.
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

;*** Symbole für GraphicsString.
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
