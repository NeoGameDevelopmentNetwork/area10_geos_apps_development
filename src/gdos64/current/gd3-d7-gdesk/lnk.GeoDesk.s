; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GEOS-Dateiname/Info.
			n "GEODESK"			;Name VLIR-Datei.

			h "A new generation of"
			h "   deskTop workplace..."
			h ""
			h "For C64 and GDOS64!"

;--- Hinweis:
;Beim hinzufügen eines VLIR-Moduls muss
;auch ":GD_VLIR_COUNT" in "TopSym.GD"
;angepasst werden!

			m

;00... Boot-Loader!
			- "obj.GD00"			;Boot-Routine.

;00... GD-System mit Variablen!
			- "obj.GD10"			;System.

;01...
			- "obj.GD20"			;WindowManager.
			- "obj.GD21"			;DeskTop.

			- "obj.GD25"			;Menü: Desktop zeichnen.
			- "obj.GD26"			;Menü: HotCorner-Aktionen ausführen.
			- "obj.GD27"			;Menü: QuickSelect Eingabegerät.
			- "obj.GD28"			;Dateien einlesen/ausgeben.
			- "obj.GD29"			;Menü: ShortCuts auswerten.

;08...
			- "obj.GD30"			;Menü: "GEOS".
			- "obj.GD31"			;Menü: "Fenster".
			- "obj.GD32"			;Menü: "Arbeitsplatz".
			- "obj.GD33"			;Menü: "Desktop".
			- "obj.GD34"			;Menü: "AppLink".
			- "obj.GD35"			;Menü: "Laufwerk".
			- "obj.GD36"			;Menü: "Datei".
			- "obj.GD37"			;Menü: "Titelzeile".
			- "obj.GD38"			;Menü: "SD2IEC".
			- "obj.GD39"			;Menü: "DiskImage/Partition".

;18...
			- "obj.GD40"			;Partition wechseln.
			- "obj.GD41"			;AppLink laden/speichern.
			- "obj.GD42"			;Datei öffnen.
			- "obj.GD43"			;Datei mit Borderblock tauschen.
			- "obj.GD45"			;Dateien einlesen.
			- "obj.GD48"			;Hintergrundbild.

;24...
			- "obj.GD50"			;Systeminfos anzeigen.
			- "obj.GD52"			;Systemzeit setzen.
			- "obj.GD53"			;Farben ändern.
			- "obj.GD54"			;Konfiguration speichern.
			- "obj.GD55"			;Laufwerksmodus wechseln.
			- "obj.GD56"			;Laufwerksfehler.

;30...
			- "obj.GD60"			;Disk-Info.
			- "obj.GD61"			;SD-Image erzeugen.
			- "obj.GD62"			;Disk löschen.
			- "obj.GD63"			;Diskette kopieren.
			- "obj.GD64"			;Validate.

;35...
			- "obj.GD80"			;Datei-Eigenschaften.
			- "obj.GD81"			;Verzeichnisse erstellen.
			- "obj.GD82"			;Dateien löschen.
			- "obj.GD83"			;Dateien kopieren/verschieben.

;39...
			- 				;Modul: Info anzeigen.
			- 				;Modul: Verzeichnis sortieren.
			- 				;Modul: GEOS<->CVT.
			- 				;Modul: GeoPaint-SlideShow.
			- 				;Modul: Dateien senden.
			- 				;Modul: CBM-Werkzeuge.
			- 				;Modul: CMD-Werkzeuge.
			- 				;Modul: Icon-Manager.
			- 				;Modul: SD-Werkzeuge.

			/
