; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;  *** Patchtext zum GEOS Patch System von Falk Rehwagen
;  *** Copyright (C) 2022 Markus Kanet

; Patchtext für das Programm:Blackjack
; Programmautor:	Clayton Jung
; Programmversion:	"Blackjack   V1.0"
; Programmversion vom:	09.10.86  15:00

; Autor des Patchtextes:Markus Kanet
; Version des Patchtextes:Version 1.0

; durchzuführende Änderungen:Hintergrundfarbe von MegaPatch
;			für Blackjack verwenden

; zusammengehörende Patches:keine

; optionale Patches:	keine

; Hinweise:		Patchtext enthält Checksummen-Test

; kommentiert:		ja

; ******************************
"Blackjack   V1.0",0	;GEOS-Klasse
5			;GEOS-Dateityp "DeskAccessory"

; Hinweis zum Datensatz:
; Datensatz ist bei SEQ-Dateien immer 0.
; Datensatz bei VLIR-Dateien 0-126.
; Datensatz für Infoblock ist 254.
; Patch-Ende mit Datensatz = 255.
; ==================================== Anfang
0			; Datensatz-Nr bearbeiten
;#$2d00			; Anfangsadresse wenn Datensatz > 0
#0			; keine neue Datensatz-Länge

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
#$2d46			; Anfangsadresse Prüfsummenbereich
#3			; Prüfsummen-Länge
#$fc24			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$2d46			; ab Adresse $2D46
#3			; 3 Byte ändern

; Ändern in LDA #$bf+NOP / Dunklegrau/Hellgrau
			;	$a9,$bf,$ea		; Feste Anwendungsfarbe setzen
; Ändern in LDA $9FFD / C_GEOS_BACK
			;	$ad,$fd,$9f		; Bildschirmfarbe für MP3 in $9FFD
; Ändern in LDA $9FF7 / C_WINBACK
				$ad,$f7,$9f		; Fensterfarbe für MP3 in $9FF7

; Adressen und Länge als Byte-Wert, da der
; Infoblock nur aus 254 Bytes bestehen kann.
; ==================================== Infoblock
254			; Infoblock bearbeiten

1			; Anzahl Änderungen im Datensatz

; ------------------------------ Änderung: #1
1			; Anzahl Checksummen, 0 = Keine

#$a0			; Anfangsadresse Prüfsummenbereich
#63			; Prüfsummen-Länge
#$d4d6			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$de			; Ändern ab Infoblock-Adresse
#14			; Anzahl Bytes ändern
" MP3 edition!",0	; Infotext ergänzen

; ==================================== Ende
255			; Patch-Ende
