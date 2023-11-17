; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Standard GEOS-Farben.
::C_Balken		b $0d				;Scrollbalken.
::C_Register		b $07				;Karteikarten: Aktiv.
::C_RegisterOff		b $08				;Karteikarten: Inaktiv.
::C_RegisterBack	b $07				;Karteikarten: Hintergrund.
::C_Mouse		b $06				;Mausfarbe.
::C_DBoxTitel		b $10				;Dialogbox: Titel.
::C_DBoxBack		b $03				;Dialogbox: Hintergrund + Text.
::C_DBoxDIcon		b $01				;Dialogbox: System-Icons.
::C_FBoxTitel		b $10				;Dateiauswahlbox: Titel.
::C_FBoxBack		b $0e				;Dateiauswahlbox: Hintergrund + Text.
::C_FBoxDIcon		b $01				;Dateiauswahlbox: System-Icons.
::C_FBoxFiles		b $03				;Dateiauswahlbox: Dateifenster.
::C_WinTitel		b $10				;Fenster: Titel.
::C_WinBack		b $0f				;Fenster: Hintergrund.
::C_WinShadow		b $00				;Fenster: Schatten.
::C_WinIcon		b $0d				;Fenster: System-Icons.
::C_PullDMenu		b $03				;PullDown-Menu.
::C_InputField		b $01				;Text-Eingabefeld.
::C_InputFieldOff	b $0f				;Inaktives Optionsfeld.
::C_GEOS_BACK		b $bf				;GEOS-Standard: Hintergrund.
::C_GEOS_FRAME		b $00				;GEOS-Standard: Rahmen.
::C_GEOS_MOUSE		b $06				;GEOS-Standard: Mauszeiger.
