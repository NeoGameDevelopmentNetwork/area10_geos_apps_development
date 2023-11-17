; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Adressen im I/O-Bereich.
;******************************************************************************

;*** VIC/SID.
:vicbase		= $d000				;video interface chip base address.
:sidbase		= $d400				;sound interface device base address.
:paddleX		= $d419				;paddle x direction.
:paddleY		= $d41a				;paddle y direction.

;*** CIA.
:cia1base		= $dc00				;1st communications interface adaptor (CIA).
:cia2base		= $dd00				;2nd communications interface adaptor (CIA).

;*** Speichererweiterung.
;EXP_BASE		= $df00				;Base address of RAM expansion unit #1 & 2
:EXP_BASE1		= $df00				;Base address of RAM expansion unit #1
:EXP_BASE2		= $de00				;Base address of RAM expansion unit #2

;*** C64-Uhrzeit (BCD-Format).
:cia1tod_t		= $dc08				;1/10 seconds.
:cia1tod_s		= $dc09				;Seconds.
:cia1tod_m		= $dc0a				;Minutes.
:cia1tod_h		= $dc0b				;Hours, Bit#7=1: PM.
