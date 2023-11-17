; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Aufbau analog zu "-G3_MP3_COLOR"
			b $05				;Scrollbalken.
			b $0d				;Registerkarten: Aktiv.
			b $0c				;Registerkarten: Inaktiv.
			b $0d				;Registerkarten: Hintergrund.
			b $02				;Mausfarbe (nicht verwendet).
			b $f0				;Dialogbox: Titel.
			b $07				;Dialogbox: Hintergrund + Text.
			b $0f				;Dialogbox: System-Icons.
			b $f0				;Dateiauswahlbox: Titel.
			b $03				;Dateiauswahlbox: Hintergrund + Text.
			b $0f				;Dateiauswahlbox: System-Icons.
			b $07				;Dateiauswahlbox: Dateifenster.
			b $f0				;Fenster: Titel.
			b $0e				;Fenster: Hintergrund.
			b $00				;Fenster: Schatten.
			b $05				;Fenster: System-Icons.
			b $07				;PullDown-Menu.
			b $0f				;Registerkarten: Text-Eingabefeld.
			b $0e				;Registerkarten: Inaktives Optionsfeld.
			b $1e				;GEOS-Standard: Hintergrund.
			b $00				;GEOS-Standard: Rahmen.
			b $02				;GEOS-Standard: Mauszeiger.
