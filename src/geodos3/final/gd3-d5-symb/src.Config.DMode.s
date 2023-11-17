; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modus für Laufwerkserkennung.
;
;CFG_DRV_DETECT = 1:
;Auslesen von ROM-Informationen um den
;genauen Laufwerktyp zu erkennen.
;Benötigt unter GEOS die Einstellung
;"TRUE-DRIVE-EMULATION" für VICE.
;
;CFG_DRV_DETECT = 2:
;Erkennt Laufwerk über Eigenschaften.
;Erfordert unter VICE ein DiskImage im
;Laufwerk, da sonst das Laufwerk nicht
;erkannt wird.
;
:CFG_DRV_DETECT		= 1				;ROM-basierte Laufwerkserkennung.
;:CFG_DRV_DETECT	= 2				;Laufwerkseigenschaften testen.
