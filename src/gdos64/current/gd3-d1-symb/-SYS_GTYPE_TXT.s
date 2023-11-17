; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tabelle auf Texte für GEOS-Dateityp.
:vecGTypeText		w :t0
			w :t1
			w :t2
			w :t3
			w :t4
			w :t5
			w :t6
			w :t7
			w :t8
			w :t9
			w :t10
			w :t11
			w :t12
			w :t13
			w :t14
			w :t15
			w :tx
			w :t17
			w :tx
			w :tx
			w :tx
			w :t21
			w :t22
			w :tx
			w :tdir

;*** Texte für GEOS-Dateityp.
if LANG = LANG_DE
::t0			b "Nicht GEOS",NULL
::t1			b "BASIC",NULL
::t2			b "Assembler",NULL
::t3			b "Datenfile",NULL
::t4			b "System-Datei",NULL
::t5			b "DeskAccessory",NULL
::t6			b "Anwendung",NULL
::t7			b "Dokument",NULL
::t8			b "Zeichensatz",NULL
::t9			b "Druckertreiber",NULL
::t10			b "Eingabetreiber",NULL
::t11			b "Laufwerkstreiber",NULL
::t12			b "Startprogramm",NULL
::t13			b "Temporär",NULL
::t14			b "Selbstausführend",NULL
::t15			b "Eingabetreiber 128",NULL
::t17			b "gateWay-Dokument",NULL
::t21			b "geoShell-Kommando",NULL
::t22			b "geoFAX Druckertreiber",NULL
::tx			b "GEOS ???",NULL
::tdir			b "Verzeichnis",NULL
endif
if LANG = LANG_EN
::t0			b "Not GEOS",NULL
::t1			b "BASIC",NULL
::t2			b "Assembler",NULL
::t3			b "Datafile",NULL
::t4			b "Systemfile",NULL
::t5			b "DeskAccessory",NULL
::t6			b "Application",NULL
::t7			b "Document",NULL
::t8			b "Font",NULL
::t9			b "Printerdriver",NULL
::t10			b "Inputdriver",NULL
::t11			b "Diskdriver",NULL
::t12			b "Bootfile",NULL
::t13			b "Temporary",NULL
::t14			b "Autoexecute",NULL
::t15			b "Inputdriver 128",NULL
::t17			b "gateWay-document",NULL
::t21			b "GeoShell-command",NULL
::t22			b "Printer/GeoFAX",NULL
::tx			b "GEOS ???",NULL
::tdir			b "Directory",NULL
endif

;*** Text für 1581-Partition.
;    Hinweis: Wird aktuell nicht unterstützt.
if FALSE
::t81dir		b "< 1581 - Partition >",NULL
endif
