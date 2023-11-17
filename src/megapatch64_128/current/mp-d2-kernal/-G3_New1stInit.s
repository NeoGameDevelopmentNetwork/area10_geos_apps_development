; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Variablen löschen.
:xFirstInit		sei
			cld

if Flag64_128 = TRUE_C128
			LoadB	scr80polar,%01000000
endif

			jsr	GEOS_Init1

			lda	#>xEnterDeskTop
			sta	EnterDeskTop   +2
			lda	#<xEnterDeskTop
			sta	EnterDeskTop   +1

			lda	#$7f
			sta	maxMouseSpeed
			sta	mouseAccel
			lda	#$1e
			sta	minMouseSpeed

			jsr	xResetScreen

			ldy	#63 -1			;Speicher für Mauspfeil
			lda	#$00			;löschen.
::2			sta	mousePicData,y
			dey
			bpl	:2

if Flag64_128 = TRUE_C128
;			lda	#0
			sta	r0L
			sta	r0H
			jsr	xSetMsePic		;80-Zeichen Mausdaten setzen
endif

			ldx	#$15
::3			lda	OrgMouseData,x		;40-Zeichen Mausdaten setzen
			sta	mousePicData,x
			dex
			bpl	:3

;--- Ergänzung: 24.12.22/M.Kanet
;In VIC-Bank#0 ist der Bereich von
;$07E8-$07F7 "unused". Für die in GEOS
;aktive VIC-Bank#2 = $8FE8-$8FF7.
;Es gibt im Kernal an keiner Stelle
;einen Zugriff auf diese Adressen, die
;Spritepointer liegen ab $8FF8 und
;werden durch GEOS_Init1 gesetzt.
;
; -> sysApplData
;
;GEOS V2 mit DESKTOP V2 legt hier über
;das Programm "pad color mgr" Farben
;für den DeskTop und Datei-Icons ab.
;Ab $8FE8 finden sich in 8 Byte bzw.
;16 Halb-Nibble die Farben für GEOS-
;Dateitypen 0-15, und ab $8FF0 findet
;sich die Farbe für den Arbeitsplatz.
;
;*** "pad color mgr"-Vorgaben setzen.
::DefPadCol		lda	#$bf			;Standardfarbe Arbeitsplatz.
			sta	sysApplData +8

			ldx	#7			;Standardfarbe für die ersten
			lda	#$bb			;16 GEOS-Dateitypen.
::1			sta	sysApplData +0,x
			dex
			bpl	:1
;---

			rts
