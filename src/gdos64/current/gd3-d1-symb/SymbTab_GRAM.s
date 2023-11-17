; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GeoRAM-Konfigurationsdaten:
;Register zur Auswahl der 16Kb/32Kb/64Kb-Speicherbank:
;GRAM_BANK_SLCT		= $DFFF
;
;Register zur Auswahl der 256Byte-Speicherseite innerhalb
;der gewählten Speicherbank:
;GRAM_PAGE_SLCT		= $DFFE
;
;Zugriff auf die gwählte Speicherbank/Speicherseite:
;GRAM_PAGE_DATA		= $DE00-$DEFF
;
;Mögliche Werte für die Größe der Speicherbänke:
;    GeoRAM    64Kb = 16Kb
;    GeoRAM   128Kb = 16Kb
;    GeoRAM   256Kb = 16Kb
;    GeoRAM   512Kb = 16Kb
;    GeoRAM  1024Kb = 16Kb
;    GeoRAM  2048Kb = 16Kb
;    GeoRAM  4096Kb = 16Kb
;    GeoRAM  8192Kb = 32Kb
;    GeoRAM 16384Kb = 64Kb
;
;Mögliche Werte für die Anzahl der Speicher-Bänke:
;    GeoRAM   64Kb bis  4096Kb: 0-255, Bankgröße 16Kb
;    GeoRAM 4097Kb bis  8192Kb:   255, Bankgröße 32Kb
;    GeoRAM 8193Kb bis 16384Kb:   255, Bankgröße 64Kb
;
;

;*** Definierenn der GeoRAM-Register.
:GRAM_PAGE_DATA		= $de00
:GRAM_PAGE_SLCT		= $dffe
:GRAM_BANK_SLCT		= $dfff

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64
