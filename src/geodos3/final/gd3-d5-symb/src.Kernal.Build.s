; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.BuildID"

			c "BuildID     V1.0"
			t "G3_Sys.Author"
			h "Datum und Revision für das aktuelle GeoDOS-Build"
			f 3 ;DATA

			o $0400

;*** Versions-Nummer angeben.
			b "V0.00"			;Nur Großbuchstaben verwenden!
			b "-"

;*** HINWEIS ***
;DEVELOPER-Versionen / SnapShots
;immer als `DEV`-Version!

;*** Automatische Datumsangabe für Build-Info.
;MegaAssembler: DDMMYY.HHMM
;			k				;Aktuelles Datum.
;			b ":"
;			x				;Uhrzeit

;*** Feste Datumsangabe für Build-Info.
;Benutzerdefiniert: YY/MM/DD:HHMM
			b "21/10/26"			;Festes Datum vorgeben.

;*** SnapShots immer mit Uhrzeit.
			b ":"
			b "2000"			;Uhrzeit

;*** SnapShots kennzeichnen:
::develop		b "DEV"
;::kernal_driver	b "KDV"
