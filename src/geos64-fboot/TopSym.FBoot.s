; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Sprache festlegen.
:Deutsch		= $0110
:Englisch		= $0220
:Sprache		= Deutsch

;--- GEOS/MP3-Symbole.
:MP3_CODE		= $c014
:RAM_SIZE		= $40
:BASE_AUTO_BOOT		= $5000
:SIZE_AUTO_BOOT		= $0500
:SCPU_OptOn		= $c0f7
:NO_ERROR		= $00
:DEV_NOT_FOUND		= $0d
:RamBankFirst		= $9fa6
:RamBankInUse		= $9f96
:Flag_LoadPrnt		= $9fae
:PrntFileNameRAM	= $9faf
:GEOS_InitSystem	= $c0ee

;--- Definition der RAM-Typen.
:RAM_SCPU		= $10				;SuperCPU/RAMCard ab ROM V1.4!
:RAM_BBG		= $20				;GeoRAM/BBGRAM allgemein.
:RAM_BBG16		= $21				;GeoRAM/BBGRAM: Bankgröße 16Kb.
:RAM_BBG32		= $22				;GeoRAM/BBGRAM: Bankgröße 32Kb.
:RAM_BBG64		= $23				;GeoRAM/BBGRAM: Bankgröße 64Kb.
:RAM_REU		= $40				;Commodore C=REU.
:RAM_RL			= $80				;RAMLink.

;--- C64 RAM/ROM-Adsressen.
:IRQ_VEC		= $0314
:ROM_BASIC_READY	= $a474
:ROM_OUT_STRING		= $ab1e
:extclr			= $d020
:bakclr0		= $d021
:SETMSG			= $ff90

;--- CIA.
:cia1base		= $dc00				;1st communications interface adaptor (CIA).
:cia2base		= $dd00				;2nd communications interface adaptor (CIA).

;--- C64-Uhrzeit (BCD-Format).
:cia1tod_t		= $dc08				;1/10 seconds.
:cia1tod_s		= $dc09				;Seconds.
:cia1tod_m		= $dc0a				;Minutes.
:cia1tod_h		= $dc0b				;Hours, Bit#7=1: PM.
