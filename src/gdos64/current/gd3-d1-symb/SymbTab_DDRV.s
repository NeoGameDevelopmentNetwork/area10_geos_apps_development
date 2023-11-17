; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Laufwerkstreiber.
;******************************************************************************
;--- Ergänzung: 16.11.19/M.Kanet
;DDX ergänzt. Standardisierung von ":Flag_SD2IEC" und ":GeoRAMBSize",
;sowie Ergänzung zweier zusätzlicher Adressen für künftige Anwendungen.

;*** Kennung für "DiskDriver Xtended"
;    Nur für DDX-Treiber ab Nov.2019!
:DiskDrvTypeExt		= $9074				;"DDX"+NULL

;*** Daten innerhalb der Laufwerkstreiber.
;    Nicht für externe Anwendung bestimmt!
;--- Wird intern von 1541/71/81/SD2IEC zum setzen von RealDrvMode genutzt.
:Flag_SD2IEC		= $9078
;--- Wird von RAMNM_GRAM genutzt um die Bankgröße zu speichern.
;    Adresse siehe s.RAMNM_GRAM.ext!!!
:GeoRAMBSize		= $9079

;*** Reserviert für künftige Erweiterungen.
;    Nur für DDX-Treiber ab Nov.2019!
:DDRV_EXT_DATA1		= $907a
:DDRV_EXT_DATA2		= $907b

;*** Erweiterte Einsprungadressen.
;    Nur für DDX-Treiber ab Nov.2019!
:InitForDskDvOp		= $907c				;Zeiger auf Treiber im RAM.
:DoneWithDskDvOp	= $907f				;Register r0 bis r3L zurücksetzen.

;*** Ende DDX-Funktionen.
:EndOfDDX		= $9082

;*** Laufwertsreiber-Register.
;Werden u.a. von den TurboDOS-Routinen
;der Laufwerkstreiber verwendet. Die
;Verwendung der Register ist aber nicht
;standardisiert. Die hier aufgeführte
;Verwendung gilt nur exemplarisch!
:d0			= $008b				;Zeiger auf Zwischenspeicher.
:d0L			= $8b
:d0H			= $8c
:d1L			= $8d				;Anzahl Datenbytes.
:d2L			= $8e				;TurboDOS/Modus-Flag #1.
:d2H			= $8f				;TurboDOS/Modus-Flag #2.
