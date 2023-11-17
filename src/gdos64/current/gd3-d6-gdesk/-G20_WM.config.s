; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Größe Fenster-Datensatz.
:WINDOW_DATA_SIZE	= 41

;--- Max. Anzahl Fenster inkl. DESKTOP.
;Hinweis:
;Mehr als 6 Dateifenster erfordern eine
;Anpassung der Speicherverwaltung für
;die Verzeichnisdaten und Icon-Cache!
.MAX_WINDOWS		= 7

;--- Fehlermeldungen Fenstermanager.
:NO_MORE_WINDOWS	= $80
;NO_WIN_SELECT		= $81
;NO_LNK_SELECT		= $82
;WINDOW_CLOSED		= $83
:WINDOW_NOT_FOUND	= $84
:JOB_NOT_FOUND		= $85
:WINDOW_BLOCKED		= $86

;--- Größe Task-/Infobar.
:TASKBAR_HEIGHT		= $10
.TASKBAR_MIN_Y		= SCRN_HEIGHT - TASKBAR_HEIGHT
.TASKBAR_MAX_Y		= TASKBAR_MIN_Y + TASKBAR_HEIGHT -1
.TASKBAR_MIN_X		= $0000 + $0030
.TASKBAR_MAX_X		= SCRN_WIDTH - $0040 -1

;--- Größe Systemleiste.
.MIN_AREA_BAR_Y		= SCRN_HEIGHT - TASKBAR_HEIGHT
.MAX_AREA_BAR_Y		= SCRN_HEIGHT - 1
.MIN_AREA_BAR_X		= $0000
.MAX_AREA_BAR_X		= SCRN_WIDTH - 1

;--- Bildschirmbereich für Fenster.
.MIN_AREA_WIN_Y		= $00
.MIN_AREA_WIN_X		= $0000
.MAX_AREA_WIN_X		= SCRN_WIDTH
.MAX_AREA_WIN_Y		= SCRN_HEIGHT - TASKBAR_HEIGHT
:MIN_SIZE_WIN_X		= $0050
:MIN_SIZE_WIN_Y		= $0030

;--- Standardposition Dateifenster.
:WIN_STD_POS_X		= $0018
:WIN_STD_POS_Y		= $18
:WIN_STD_SIZE_X		= $00d8
:WIN_STD_SIZE_Y		= $78

;--- Standardbreite/Höhe für Eintrag.
:WM_GRID_ICON_XC	= 8
:WM_GRID_ICON_X		= WM_GRID_ICON_XC *8
:WM_GRID_ICON_Y		= 4*8

;--- Zeiger auf Original-Mausroutine.
:mouseOldVec		w $0000

;--- Fenster-Scroll-Modus.
:WM_MOVE_MODE		b $00

;--- Rechtsklick auf Titelzeile.
.WM_TITEL_STATUS	b $00				;$FF=Rechtsklick auf Titelzeile.

;--- Anzahl Icons.
:WM_COUNT_ICON_X	b $00
:WM_COUNT_ICON_Y	b $00
:WM_COUNT_ICON_XY	b $00

;--- Anzahl offener Fenster.
.WM_WCOUNT_OPEN		b $01

;--- MyComputer-Flag.
.WM_MYCOMP		b $00				;$00=Nicht geöffnet od. Fenster-Nr.

;--- Aktuelles Fenster.
.WM_WCODE		b $00

;--- Fenster-Stack.
.WM_STACK		b $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

;--- Daten für aktuelles Fenster..
.WM_DATA_BUF		s WINDOW_DATA_SIZE

;--- BYTE: Fenstertyp.
;$00 = Standardfenster.
;$ff = Feste Größe.
:WM_DATA_SIZE		= WM_DATA_BUF +0
;--- BYTE/WORD: Fenstergröße.
;NULL wenn Typ=$00.
;yo,yu,xl,xr wenn Typ=$FF.
:WM_DATA_Y0		= WM_DATA_BUF +1
:WM_DATA_Y1		= WM_DATA_BUF +2
:WM_DATA_X0		= WM_DATA_BUF +3
:WM_DATA_X1		= WM_DATA_BUF +5
;--- BYTE: Breite eines Eintrages.
;$00 = Standard-Icon-Breite.
:WM_DATA_GRID_X		= WM_DATA_BUF +7
;--- BYTE: Höhe eines Eintrages.
;$00 = Standard-Icon-Höhe.
.WM_DATA_GRID_Y		= WM_DATA_BUF +8
;--- BYTE: Anzahl Spalten.
;$00 = Wird berechnet.
.WM_DATA_COLUMN		= WM_DATA_BUF +9
;--- BYTE: Anzahl Zeilen.
;$00 = Wird berechnet.
:WM_DATA_ROW		= WM_DATA_BUF +10
;--- WORD: Routine für Titelzeile.
:WM_DATA_TITLE		= WM_DATA_BUF +11
;--- WORD: Routine für Infozeile.
:WM_DATA_INFO		= WM_DATA_BUF +13
;--- WORD: Routine für Fenster initialisieren.
;(z.B. 64K-Bank für Datei-Cache suchen)
:WM_DATA_WININIT	= WM_DATA_BUF +15
;--- WORD: Routine zur Ausgabe der Daten.
:WM_DATA_WINPRNT	= WM_DATA_BUF +17
;--- WORD: Routine wenn Fenster angeklickt.
:WM_DATA_WINSLCT	= WM_DATA_BUF +19
;--- WORD: Routine zum verschieben der Daten.
;$FFFF = Systemroutine (für Icons).
;$EEEE = Systemroutine (für Textmodus)
.WM_DATA_WINMOVE	= WM_DATA_BUF +21
;--- BYTE: Scrollbalken.
;$00 = Kein Scrollbalken.
:WM_DATA_MOVEBAR	= WM_DATA_BUF +23
;--- WORD: Routine für rechten Mausklick.
:WM_DATA_RIGHTCLK	= WM_DATA_BUF +24
;--- WORD: Routine zum Fenster schließen.
:WM_DATA_WINEXIT	= WM_DATA_BUF +26
;--- WORD: Routine für Mehrfachauswahl.
;$0000=Nicht möglich, $FFFF=Standard.
.WM_DATA_WINMSLCT	= WM_DATA_BUF +28
;--- WORD: Routine für Einzelauswahl.
;$0000=Nicht möglich, $FFFF=Standard.
.WM_DATA_WINSSLCT	= WM_DATA_BUF +30
;--- WORD: Routine für Fensterupdate.
;$0000=Nicht erforderlich.
:WM_DATA_WINUPD		= WM_DATA_BUF +32
;--- WORD: Routine zur Ausgabe eines Eintrages.
:WM_DATA_PRNFILE	= WM_DATA_BUF +34
;--- WORD: Routine für Einträge einlesen.
:WM_DATA_GETFILE	= WM_DATA_BUF +36

;--- BYTE: VLIR-Modul für Fensterinhalt.
.WM_DATA_OPTIONS	= WM_DATA_BUF +38

;--- BYTE: Anzahl Einträge.
.WM_DATA_MAXENTRY	= WM_DATA_BUF +39
;--- BYTE: Zeiger auf ersten Eintrag der Seite.
.WM_DATA_CURENTRY	= WM_DATA_BUF +40

;--- Speicher für alle Fensterdaten.
:WM_DATA_ALLWIN		s MAX_WINDOWS  *WINDOW_DATA_SIZE

;--- Angaben zum Laufwerk, Partition, Verzeichnis.
.WIN_DRIVE		s MAX_WINDOWS			;Laufwerk für aktuelles Fenster.
.WIN_PART		s MAX_WINDOWS			;Partition für aktuelles Fenster.
.WIN_SDIR_T		s MAX_WINDOWS			;Zeiger auf Verzeichnis-Header für
.WIN_SDIR_S		s MAX_WINDOWS			;aktuelles Fenster.
.WIN_REALTYPE		s MAX_WINDOWS			;RealDrvType für Laufwerk.
.WIN_DATAMODE		s MAX_WINDOWS			;$00=Std, $80=CMD-Part., $40=DImage.

;--- Angaben zum Start der aktuellen Dateien im Verzeichnis.
.WIN_DIR_TR		s MAX_WINDOWS			;Erster Verzeichis-Eintrag: Track
.WIN_DIR_SE		s MAX_WINDOWS			;Erster Verzeichis-Eintrag: Sektor
.WIN_DIR_POS		s MAX_WINDOWS			;Erster Verzeichis-Eintrag: Pos.
.WIN_DIR_NR		s MAX_WINDOWS			;Erster Verzeichis-Eintrag: Nummer/L
.WIN_DIR_START		s MAX_WINDOWS			;$00 = Verzeichnis ab Anfang.
							;$7F = Verzeichnis ab Position.
							;$FF = Weitere Dateien einlesen.

;--- Angaben zum Start der nächsten Dateien im Verzeichnis.
.WIN_DIR_NX_TR		s MAX_WINDOWS			;Nächster Verzeichis-Eintrag: Track
.WIN_DIR_NX_SE		s MAX_WINDOWS			;Nächster Verzeichis-Eintrag: Sektor
.WIN_DIR_NX_POS		s MAX_WINDOWS			;Nächster Verzeichis-Eintrag: Pos.

;--- Variablen für Fenster.
.WMODE_SLCT		s MAX_WINDOWS			;Anzahl ausgewählter Einträge.

:WMODE_MAXIMIZED	s MAX_WINDOWS			;$FF=Fenster maximiert.
.WMODE_VICON		s MAX_WINDOWS			;$00=Icon-Modus, $FF=Text-Modus.
.WMODE_VSIZE		s MAX_WINDOWS			;$FF=Größen in KBytes.
.WMODE_VINFO		s MAX_WINDOWS			;$FF=Text-Modus mit Details.
.WMODE_FILTER		s MAX_WINDOWS			;$00=Kein Dateifilter.
							;$8x=Filter aktiv.
							;    => Bit#0-6 = GEOS-Dateityp.
.WMODE_SORT		s MAX_WINDOWS			;$00=Dateiliste nicht sortieren.
							;Sonst Modus 1-6, siehe PopUpFunc.
