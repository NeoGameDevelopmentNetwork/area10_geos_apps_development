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
; Programmversion:	"Calendar I  V1.2"
; Programmversion vom:	29.12.87  16:04

; Autor des Patchtextes:Markus Kanet
; Version des Patchtextes:Version 1.0

; durchzuführende Änderungen:Hintergrundfarbe von MegaPatch
;			für Kalender verwenden

; zusammengehörende Patches:keine

; optionale Patches:	Patch für Y2K

; Hinweise:		Patchtext enthält Checksummen-Test

; kommentiert:		ja

; ******************************
"Calendar I  V1.2",0	;GEOS-Klasse
5			;GEOS-Dateityp "DeskAccessory"

; Hinweis zum Datensatz:
; Datensatz ist bei SEQ-Dateien immer 0.
; Datensatz bei VLIR-Dateien 0-126.
; Datensatz für Infoblock ist 254.
; Patch-Ende mit Datensatz = 255.
; ==================================== Anfang
0			; Datensatz-Nr bearbeiten
;#$0400			; Anfangsadresse wenn Datensatz > 0
#0			; Keine neue Datensatz-Länge

2			; Anzahl Änderungen im Datensatz

; Adressen und Länge als Word-Wert, da der
; Datensatz aus mehr 256 Bytes bestehen kann.
; ------------------------------ Änderung: #1
1			; Anzahl Checksummen, 0 = Keine

; Für jede Prüfsumme drei Words:
; - Startadresse
; - Anzahl Bytes
; - Prüfsumme vom Programm CHECKSUMMER

; Testen auf LDA $8C27
#$253a			; Anfangsadresse Prüfsummenbereich
#3			; Prüfsummen-Länge
#$fc24			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$253a			; ab Adresse $253A
#3			; 3 Byte ändern

; Ändern in LDA #$bf+NOP / Dunklegrau/Hellgrau
			;	$a9,$bf,$ea		; Feste Anwendungsfarbe setzen
; Ändern in LDA $9FFD / C_GEOS_BACK
			;	$ad,$fd,$9f		; Bildschirmfarbe für MP3 in $9FFD
; Ändern in LDA $9FF7 / C_WINBACK
				$ad,$f7,$9f		; Fensterfarbe für MP3 in $9FF7

; ------------------------------ Änderung: #2
1			; Anzahl Checksummen, 0 = Keine

; Testen auf LDA $8C27
#$2e21			; Anfangsadresse Prüfsummenbereich
#3			; Prüfsummen-Länge
#$fc24			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$2e21			; ab Adresse $2E21
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
;#$0400			; Anfangsadresse wenn Datensatz > 0
#0			; keine neue Datensatz-Länge

1			; Anzahl Änderungen im Datensatz

; ------------------------------ Änderung: #1
1			; Anzahl Checksummen, 0 = Keine

; Testen auf Calendar-Initialisierung
#$0400			; Anfangsadresse Prüfsummenbereich
#8			; Prüfsummen-Länge
#$520e			; Prüfsummen-Wert

2			; Anzahl Bereiche ändern

#$0406			; ab Adresse $0406
#1			; 1 Byte ändern
$02			; Jahrtausend

#$0407			; ab Adresse $0407
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
#61			; Prüfsummen-Länge
#$028e			; Prüfsummen-Wert

1			; Anzahl Bereiche ändern

#$dc			; Ändern ab Infoblock-Adresse
#18			; Anzahl Bytes ändern
" Version für MP3!",0	; Infotext ergänzen

; Workaround für PATCH-SYSTEM, da hier immer(!)
; die Programm-Endadresse geändert wird.
; Bei Calendar wird dadurch kein Speicher mehr für
; zusätzliche Daten in das SwapFile mit ausgelagert.
; Mit dieser Änderung wird eine Routine ergänzt, die
; beim ersten Start den Infoblock korrigiert und zum
; aufrufenden Programm zurückkehrt.
; Danach kann Calendar normal genutzt werden.
; ==================================== Anfang
0			; Datensatz-Nr bearbeiten
;#$0400			; Anfangsadresse wenn Datensatz > 0
#$2f1a			; Neue Datensatz-Länge

1			; Anzahl Änderungen im Datensatz

; ------------------------------ Änderung: #1
0			; Anzahl Checksummen, 0 = Keine

1			; Anzahl Bereiche ändern

#$32e8			; Startadresse Patch-Routine
#50			; Länge der Patch-Routine

; lda dirEntryBuf +$13	=> Adresse für Infoblock setzen
; sta r1L
$ad,$13,$84,$85,$04
; lda dirEntryBuf +$14
; sta r1H
$ad,$14,$84,$85,$05

; lda #< fileHeader	=> Zeiger auf ":fileHeader" setzen
; sta r4L
; lda #> fileHeader
; sta r4H
$a9,$00,$85,$0a
$a9,$81,$85,$0b

; lda #< $57e1		=> Endadresse korrigieren
; sta fileHeader +$49
; lda #> $57e1
; sta fileHeader +$4a
$a9,$e1,$8d,$49,$81
$a9,$57,$8d,$4a,$81

; lda #< $0408		=> Startadresse zurücksetzen
; sta fileHeader +$4b
; lda #> $0408
; sta fileHeader +$4c
$a9,$08,$8d,$4b,$81
$a9,$04,$8d,$4c,$81

; jsr PutBlock		=> PutBlock ausführen
; txa			=> Fehler ?
; beq :ok		=> Nein, => weiter...
; jmp Panic		=> PANIC-Fehler!
;:ok
; jmp RstrAppl		=> Calendar beenden
$20,$e7,$c1
$8a
$f0,$03
$4c,$c2,$c2
$4c,$3e,$c2

; Startadresse im Infoblock temporär auf neue
; Patchroutine umleiten, damit der Patch beim
; ersten Start automatisch ausgeführt wird.
; ==================================== Infoblock
254			; Infoblock bearbeiten

1			; Anzahl Änderungen im Datensatz

; ------------------------------ Änderung: #1
0			; Anzahl Checksummen, 0 = Keine

1			; Anzahl Bereiche ändern

#$4b			; Ändern ab Infoblock-Adresse
#2			; Anzahl Bytes ändern
$e8,$32			; Neue temp. Startadresse

; ==================================== Ende
255			; Patch-Ende
