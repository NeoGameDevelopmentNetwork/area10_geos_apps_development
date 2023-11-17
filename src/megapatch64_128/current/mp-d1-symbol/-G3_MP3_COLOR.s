; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
			b $0d				;Scrollbalken.
			b $07				;Registerkarten: Aktiv.
			b $08				;Registerkarten: Inaktiv.
			b $07				;Registerkarten: Hintergrund.
			b $06				;Mausfarbe (nicht verwendet).
			b $10				;Dialogbox: Titel.
			b $03				;Dialogbox: Hintergrund + Text.
			b $01				;Dialogbox: System-Icons.
			b $10				;Dateiauswahlbox: Titel.
			b $0e				;Dateiauswahlbox: Hintergrund + Text.
			b $01				;Dateiauswahlbox: System-Icons.
			b $03				;Dateiauswahlbox: Dateifenster.
			b $10				;Fenster: Titel.
			b $0f				;Fenster: Hintergrund.
			b $00				;Fenster: Schatten.
			b $0d				;Fenster: System-Icons.
			b $03				;PullDown-Menu.
			b $01				;Registerkarten: Text-Eingabefeld.
			b $0f				;Registerkarten: Inaktives Optionsfeld.
			b $bf				;GEOS-Standard: Hintergrund.
			b $00				;GEOS-Standard: Rahmen.
			b $06				;GEOS-Standard: Mauszeiger.
