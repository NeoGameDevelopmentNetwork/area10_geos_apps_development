; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GEOS-Dateiname/Info.
			n "GEODESK.mod"			;Name VLIR-Datei.

			h "Additional modules for"
			h "   GeoDesk64..."
			h ""
			h "For C64 and GDOS64 only!"

;--- Hinweis:
;Beim hinzu8fügen von Modulen muss auch
;der Modul-Installer angepasst werden.
; -> ":moduleNames" ff.

			m

;00... Modul-Installer
			- "obj.GD00.Mod"		;Menü-Routine.

;01... GeoDesk-Module
			- "obj.GD90"			;Hile/Info.
			- "obj.GD91"			;Dateien sortieren.
			- "obj.GD92"			;FileCVT.
			- "obj.GD93"			;GPShow.
			- "obj.GD94"			;SendTo.
			- "obj.GD95"			;CBM-Werkzeuge.
			- "obj.GD96"			;CMD-Werkzeuge.
			- "obj.GD97"			;Icon-Manager.
			- "obj.GD98"			;SD-Werkzeuge.

			/
