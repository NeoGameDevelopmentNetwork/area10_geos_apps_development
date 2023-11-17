; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
;*** Größe der Dateiauswahlbox.
:X_DBox			= $0010
:Y_DBox			= $10
:B_DBox			= $0118
:H_DBox			= $a0

;*** Größe des Dateiauswahl-Fensters.
:X_FWin			= X_DBox +$08
:Y_FWin			= Y_DBox +$10
:B_FWin			= $0080
:H_FWin			= $38

;*** Position des Eingabefeldes für Suche nach Dateiname.
:X_NBox			= X_FWin + B_FWin +16
:Y_NBox			= Y_FWin + 8
:B_NBox			= $0078
:H_NBox			= $08

;*** Position der erweiterten Icons.
:X_Sort			= X_DBox + 8
:Y_Sort			= Y_DBox + H_DBox -24
:B_Sort			= $0008
:H_Sort			= $08

;*** Bereich für Anzeige-Modus.
:X_VMod			= X_FWin + B_FWin -8
:Y_VMod			= Y_FWin + H_FWin +8
:B_VMod			= $0008
:H_VMod			= $08

;*** Bereich für Schreibschutz-Modus.
:X_WPrt			= X_NBox + B_NBox -8
:Y_WPrt			= Y_FWin + H_FWin +8
:B_WPrt			= $0008
:H_WPrt			= $08

;*** Bereich für Info-Anzeige.
:X_Info			= X_FWin + B_FWin +16
:Y_Info			= Y_FWin + 24
:B_Info			= B_NBox
:H_Info			= $10

;*** Bereich für Größen-Anzeige.
:X_Size			= X_FWin + B_FWin +16 +B_NBox -48
:Y_Size			= Y_FWin + 48
:B_Size			= $0030
:H_Size			= $08

;*** Erste Bildschirmzeile mit Grafikdaten (40-Zeichen).
;    Zeiger auf erstes Byte.
:TabFirstL_x		= (X_FWin            /8)*8
:TabFirstL_y		= (Y_FWin            /8)*8*40
:TabFirstL		= SCREEN_BASE + TabFirstL_x + TabFirstL_y

;*** Erste Bildschirmzeile mit Grafikdaten (80-Zeichen).
;    Zeiger auf erstes Byte.
:TabFirstL80_x		= (X_FWin * 2)      /8
:TabFirstL80_y		= (Y_FWin            /8)*8*80
:TabFirstL80		= $0000 + TabFirstL80_x + TabFirstL80_y

;*** Letzte Bildschirmzeile mit Grafikdaten (40-Zeichen).
;    Zeiger auf erstes Byte.
:TabLastL_x		= (X_FWin               /8)*8
:TabLastL_y		= ((Y_FWin + H_FWin -8)/8)*8*40
:TabLastL		= SCREEN_BASE + TabLastL_x  + TabLastL_y

;*** Letzte Bildschirmzeile mit Grafikdaten (80-Zeichen).
;    Zeiger auf erstes Byte.
:TabLastL80_x		= (X_FWin * 2)          /8
:TabLastL80_y		= ((Y_FWin + H_FWin -8)/8)*8*80
:TabLastL80		= $0000 + TabLastL80_x  + TabLastL80_y

;*** Anzahl zu verschiebender Bytes in Zeile.
:TabScrollX		= ((B_FWin -8)/ 8) *8
:TabScrollX80		= ((B_FWin -8)/ 8) * 2

;*** Anzahl Dateien im Fenster.
:TabScrollY		= H_FWin/8
:TabScrollY80		= H_FWin

endif
