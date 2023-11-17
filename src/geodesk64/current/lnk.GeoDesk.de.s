; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GEOS-Dateiname/Info.
			n "GeoDesk64"			;Name VLIR-Datei.

			h "Eine neue Generation der"
			h "   DeskTop-Oberflächen..."
			h ""
			h "Für C64 und MegaPatch64!"

;--- Hinweis:
;Beim hinzufügen eines VLIR-Moduls muss
;auch ":GD_VLIR_COUNT" in "TopSym.GD"
;angepasst werden!

			m
			- "mod.#100.obj"		;Boot-Routine.
			- "mod.#101.obj"		;WindowManager.
			- "mod.#102.obj"		;DeskTop.
			- "mod.#103.obj"		;Partition wechseln.
			- "mod.#104.obj"		;AppLink laden/speichern.
			- "mod.#105.obj"		;Datei öffnen.
			- "mod.#106.obj"		;Dateien einlesen.
			- "mod.#107.obj"		;Konfiguration speichern.
			- "mod.#108.obj"		;Datei-Eigenschaften.
			- "mod.#109.obj"		;Dateien löschen.
			- "mod.#110.obj"		;Verzeichnisse erstellen.
			- "mod.#111.obj"		;Validate.
			- "mod.#112.obj"		;Disk-Info.
			- "mod.#113.obj"		;Disk löschen.
			- "mod.#114.obj"		;Dateien kopieren/verschieben.
			- "mod.#115.obj"		;Farben ändern.
			- "mod.#116.obj"		;Diskette kopieren.
			- "mod.#117.obj"		;Info anzeigen.
			- "mod.#118.obj"		;GEOS<->CVT.
			- "mod.#119.obj"		;SD-Image erzeugen.
			- "mod.#120.obj"		;Verzeichnis sortieren.
			- "mod.#121.obj"		;Systeminfos anzeigen.
			- "mod.#122.obj"		;Systemzeit setzen.
			- "mod.#123.obj"		;Laufwerksfehler.
			/
