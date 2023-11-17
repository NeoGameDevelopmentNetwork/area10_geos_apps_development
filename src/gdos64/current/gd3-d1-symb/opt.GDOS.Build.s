; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** HINWEIS ***
;DEVELOPER-Versionen / SnapShots
;immer als `DEV`-Version!
;
;Der String darf max. 20 Zeichen wegen
;"GD.RBOOT" nicht überschreiten.

;*** Versions-Nummer angeben.
:BUILD			b "V0.00"			;Nur Großbuchstaben verwenden!
			b "-"

;*** Automatische Datumsangabe für Build-Info.
;MegaAssembler: DD.MM.YY:HHMM
;			k				;Aktuelles Datum.
;			b ":"
;			x				;Aktuelle Uhrzeit.

;*** Statische Datumsangabe für Build-Info.
;Benutzerdefiniert: YYMMDD:HHMM
			b "230820"			;Statisches Datum vorgeben.

;*** SnapShots immer mit Uhrzeit.
			b ":"
			b "2000"			;Statische Uhrzeit vorgeben.

;*** SnapShots kennzeichnen:
::develop		b "DEV"
;::kernal_driver	b "KDV"
