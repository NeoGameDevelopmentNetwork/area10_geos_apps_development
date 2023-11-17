; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GEOS-Dateiname/Info.
			n "GD.CONFIG"			;Name VLIR-Datei.

			m
			- "obj.GDC.CORE"		;GD.CONFIG: Menü
			- "obj.CFG.INIT"		;GD.CONFIG: Initialisierung

;--- Konfigurationsroutinen der Module:
;VLIR-Adressen werden in GD.CFG.INIT in
;eine interne Tabelle übernommen!
			- "obj.CFG.DACC"		;RAM
			- "obj.CFG.SDEV"		;Print/Input
			-				;Drives
			- "obj.CFG.SCRN"		;Screen
			- "obj.CFG.GEOS"		;GEOS
			- "obj.CFG.HELP"		;GeoHelp
			- "obj.CFG.TASK"		;TaskMan
			- "obj.CFG.PSPL"		;Spooler

			/
