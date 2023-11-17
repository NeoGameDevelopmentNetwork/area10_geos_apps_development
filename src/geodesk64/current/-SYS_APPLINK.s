; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aufbau der AppLink-
;    Konfigurationsdatei:
:LINK_DATA_FILE		= 0				;AppLink-Name.
:LINK_DATA_NAME		= 17				;Dateiname.
:LINK_DATA_TYPE		= 34				;AppLink-Typ:
							; $00=Anwendung.
							; $80=Arbeitsplatz.
							; $FF=Laufwerk.
							; $FE=Drucker.
							; $FD=Verzeichnis.	
:LINK_DATA_XPOS		= 35				;Icon XPos (Cards).
:LINK_DATA_YPOS		= 36				;Icon YPos (Cards).
:LINK_DATA_COLOR	= 37				;Farbdaten (3x3 Bytes).
:LINK_DATA_DRIVE	= 46				;Laufwerk: Adresse.
:LINK_DATA_DVTYP	= 47				;Laufwerk: RealDrvType.
:LINK_DATA_DPART	= 48				;Laufwerk: Partition.
:LINK_DATA_DSDIR	= 49				;Laufwerk: SubDir Tr/Se.
:LINK_DATA_ENTRY	= 51				;Verzeichnis-Eintrag.
:LINK_DATA_WMODE	= 54				;Fensteroptionen.
							; Bit#7 = 1 : Gelöschte Dateien anzeigen.
							; Bit#6 = 1 : Icons anzeigen.
							; Bit#5 = 1 : Größe in KByte anzeigen.
							; Bit#4 = 1 : Textmodus/Details anzeigen.
:LINK_DATA_FILTER	= 55				;Dateifilter.
							; Bit#7 = 0 : Nicht verwendet, immer 0.
							; Bit#0-6   : GEOS-Dateityp/Filter.
:LINK_DATA_SORT		= 56				;Dateiliste sortieren.
							; Bit#7 = 0 : Nicht verwendet, immer 0.
							; Bit#0-6   : Sortiermodus.

:LINK_DATA_BUFSIZE	= 57				;Größe AppLink-Datensatz.
:LINK_COUNT_MAX		= 25				;Max. Anzahl AppLinks.

:LINK_ICON_BUFSIZE	= 64				;Größe AppLink-Icon-Datensatz.
