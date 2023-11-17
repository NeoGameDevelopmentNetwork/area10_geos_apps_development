; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Variablen im Bereich $0000-$00FF.
.zpage			= $0000
.CPU_DATA		= $0001

.r0L			= $02
.r0H			= $03
.r0			= $0002
.r1L			= $04
.r1H			= $05
.r1			= $0004
.r2L			= $06
.r2H			= $07
.r2			= $0006
.r3L			= $08
.r3H			= $09
.r3			= $0008
.r4L			= $0a
.r4H			= $0b
.r4			= $000a
.r5L			= $0c
.r5H			= $0d
.r5			= $000c
.r6L			= $0e
.r6H			= $0f
.r6			= $000e
.r7L			= $10
.r7H			= $11
.r7			= $0010
.r8L			= $12
.r8H			= $13
.r8			= $0012
.r9L			= $14
.r9H			= $15
.r9			= $0014
.r10L			= $16
.r10H			= $17
.r10			= $0016
.r11L			= $18
.r11H			= $19
.r11			= $0018
.r12L			= $1a
.r12H			= $1b
.r12			= $001a
.r13L			= $1c
.r13H			= $1d
.r13			= $001c
.r14L			= $1e
.r14H			= $1f
.r14			= $001e
.r15L			= $20
.r15H			= $21
.r15			= $0020

.curPattern		= $0022				;   1 Word
.string			= $0024				;   1 Word
.baselineOffset		= $0026				;   1 Byte
.curSetWidth		= $0027				;   1 Word
.curSetHight		= $0029				;   1 Byte
.curIndexTable		= $002a				;   1 Word
.cardDataPntr		= $002c				;   1 Word
.currentMode		= $002e				;   1 Byte
.dispBufferOn		= $002f				;   1 Byte %1xxxxxxx = Vordergrund.
							; %x1xxxxxx = Hintergrund.
							; %xx1xxxxx = Wert nicht verändern.
							;             (Für Dialogbox nötig)

.mouseOn		= $0030				;   1 Byte
.msePicPtr		= $0031				;   1 Word
.windowTop		= $0033				;   1 Byte
.windowBottom		= $0034				;   1 Byte
.leftMargin		= $0035				;   1 Word
.rightMargin		= $0037				;   1 Word
.pressFlag		= $0039				;   1 Byte
.mouseXPos		= $003a				;   1 Word
.mouseYPos		= $003c				;   1 Byte
.returnAddress		= $003d				;   1 Word
.graphMode		= $003f				;   1 Byte Nur C128 !!!
.DI_VecDefTab		= $003f				;   1 Word Nur C64  !!!
.CallRoutVec		= $0041				;   1 Word
.DB_VecDefTab		= $0043				;   1 Word
.SetStream		= $0045				;   8 Byte;Zwischenspeicher Zeichensatz.

.STATUS			= $0090				;   1 Byte

.curDevice		= $00ba				;   1 Byte
