; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;  *** Patchtext zum GEOS Patch System von Falk Rehwagen
;  *** Copyright (C) 2022 Markus Kanet

; Patchtext für das Programm:Calendar
; Programmautor:	Jung and Wegdwood
; Programmversion:	"Calendar I  V1.0"
; Programmversion vom:	9.10.86  15:00

; Autor des Patchtextes:Markus Kanet
; Version des Patchtextes:Version 1.0

; durchzuführende Änderungen:Hintergrundfarbe von MegaPatch
;			für Kalender verwenden

; zusammengehörende Patches:keine

; optionale Patches:	Patch für Y2K

; Hinweise:		Patchtext enthält Checksummen-Test

; kommentiert:		ja

; ******************************
"Calendar I  V1.0",0	;GEOS-Klasse
5			;GEOS-Dateityp "DeskAccessory"

; Hinweis zum Datensatz:
; Datensatz ist bei SEQ-Dateien immer 0.
; Datensatz bei VLIR-Dateien 0-126.
; Datensatz für Infoblock ist 254.
; Patch-Ende mit Datensatz = 255.
; ==================================== Anfang
0			; Datensatz-Nr bearbeiten
;#$066d			; Anfangsadresse wenn Datensatz > 0
#0			; Keine neue Datensatz-Länge

1			; Anzahl Änderungen im Datensatz

; Adressen und Länge als Word-Wert, da der
; Datensatz aus mehr 256 Bytes bestehen kann.
; ------------------------------ Änderung: #1
1			; Anzahl Checksummen, 0 = Keine

; Für jede Prüfsumme drei Words:
; - Startadresse
; - Anzahl Bytes
; - Prüfsumme vom Programm CHECKSUMMER

; Testen auf LDA $8C27
#$2b49			; Anfangsadresse Prüfsummenbereich
#3			; Prüfsummen-Länge
#$fc24			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$2b49			; ab Adresse $2B49
#3			; 3 Byte ändern

; Ändern in LDA #$bf+NOP / Dunklegrau/Hellgrau
			;	$a9,$bf,$ea		; Feste Anwendungsfarbe setzen
; Ändern in LDA $9FFD / C_GEOS_BACK
			;	$ad,$fd,$9f		; Bildschirmfarbe für MP3 in $9FFD
; Ändern in LDA $9FF7 / C_WINBACK
				$ad,$f7,$9f		; Fensterfarbe für MP3 in $9FF7

; Anpassung an das Jahr 2000 (Y2K-Patch)
; ==================================== Anfang
0			; Datensatz-Nr bearbeiten
;#$066d			; Anfangsadresse wenn Datensatz > 0
#0			; keine neue Datensatz-Länge

1			; Anzahl Änderungen im Datensatz

; ------------------------------ Änderung: #1
1			; Anzahl Checksummen, 0 = Keine

; Testen auf Calendar-Initialisierung
#$0679			; Anfangsadresse Prüfsummenbereich
#10			; Prüfsummen-Länge
#$e6d3			; Prüfsummen-Wert

2			; Anzahl Bereiche ändern

#$067a			; ab Adresse $067A
#1			; 1 Byte ändern
$02			; Jahrtausend

#$067f			; ab Adresse $067F
#1			; 1 Byte ändern
$00			; Jahrhundert

; Adressen und Länge als Byte-Wert, da der
; Infoblock nur aus 254 Bytes bestehen kann.
; ==================================== Infoblock
254			; Infoblock bearbeiten

1			; Anzahl Änderungen im Datensatz

; ------------------------------ Änderung: #1
1			; Anzahl Checksummen, 0 = Keine

#$a0			; Anfangsadresse Prüfsummenbereich
#76			; Prüfsummen-Länge
#$f5d4			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$eb			; Ändern ab Infoblock-Adresse
#14			; Anzahl Bytes ändern
" MP3 edition!",0	; Infotext ergänzen

; ==================================== Ende
255			; Patch-Ende
