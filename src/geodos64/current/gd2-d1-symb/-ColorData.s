; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Systemfarben.
; Datum			: 05.07.97
; Aufruf		: -
; Übergabe		: -
; Rückgabe		: -
; Verändert		: -
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Systemfarben.
.colSystem
.C_ScreenBack		b $05				;Hintergrund.
.C_ScreenClear		b $55				;Hintergrund ohne Vordergrund!

.C_MenuBack		b $0f				;Dialogbox.
.C_MenuTBox		b $0d				;Textfenster.
.C_MenuMIcon		b $0d				;Icons.
.C_MenuDIcon		b $0d				;System-Icons.
.C_MenuClose		b $01				;Close-Icon.
.C_MenuTitel		b $12				;Titel-Zeile.

.C_Balken		b $03				;Scrollbalken.
.C_Register		b $16				;Karteikarten.
.C_Bubble		b $07				;Bubble-Farbe.
.C_Mouse		b $06				;Mausfarbe.

.C_DBoxClose		b $01				;Dialogbox: Close-Icon.
.C_DBoxTitel		b $12				;Dialogbox: Titel.
.C_DBoxBack		b $0f				;Dialogbox: Hintergrund + Text.
.C_DBoxDIcon		b $01				;Dialogbox: System-Icons.

.C_IBoxBack		b $03				;Infobox  : Hintergrund + Text.

.C_FBoxClose		b $01				;Dateiauswahlbox: Close-Icon.
.C_FBoxTitel		b $12				;Dateiauswahlbox: Titel.
.C_FBoxBack		b $0f				;Dateiauswahlbox: Hintergrund + Text.
.C_FBoxDIcon		b $01				;Dateiauswahlbox: System-Icons.

.C_MainIcon		b $01				;Icons Hauptmenü.

.C_GEOS_BACK		b $bf				;Hintergrund: Farbe GEOS-Standard-Applikationen.
.C_GEOS_FRAME		b $00				;Rahmen     : Farbe GEOS-Standard-Applikationen.
.C_GEOS_MOUSE		b $06				;Mauszeiger : Farbe GEOS-Standard-Applikationen.
.colSystemEnd
