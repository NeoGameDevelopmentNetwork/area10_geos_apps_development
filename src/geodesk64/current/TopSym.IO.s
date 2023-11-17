; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Adressen im I/O-Bereich
; Version 04.07.2019

:BORDER_COL		= $d020				;Border color.
:mob0clr		= $d027				;Farbe Sprite #0.
:mob1clr		= $d028				;Farbe Sprite #1.
:mob2clr		= $d029				;Farbe Sprite #2.
:CIA_PRA		= $dc00				;CIA Register DataPort A, Bits PA0 to PA7.
:CIA_PRB		= $dc01				;CIA Register DataPort B, Bits PB0 to PB7.
:CIA_TOD10		= $dc08				;CIA TOD 1/10 Sekunden.
:CIA_TODSEC		= $dc09				;CIA TOD Sekunden.
:CIA_TODMIN		= $dc0a				;CIA TOD Minuten.
:CIA_TODHR		= $dc0b				;CIA TOD Jahr.
