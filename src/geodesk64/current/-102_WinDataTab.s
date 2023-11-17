; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Fenster-Daten für Desktop.
:WIN_DESKTOP		b $ff				;$00 = Standardfenster
							;$ff = Feste Größe.
			b $00,$b7			;Fenstergröße wenn erstes Byte = $FF.
			w $0000,$013f

			b $00				;Breite eines Eintrages.
							;$00 = Standard-Icon-Breite.
			b $00				;Höhe eines Eintrages.
							;$00 = Standard-Icon-Höhe.

			b $00				;Anzahl Spalten.
							;$00 = Wird berechnet.
			b $00				;Anzahl Zeilen.
							;$00 = Wird berechnet.

			w $0000				;Zeiger auf Routine für Titelzeile.
			w $0000				;Zeiger auf Routine für Infozeile.
			w $0000				;Neues Fenster initialisieren.
							;(z.B. 64K-Bank für Datei-Cache suchen)
			w $0000				;Routine zur Ausgabe der Daten.
			w MseClkAppLink			;Routine wenn Fenster angeklickt.
			w $0000				;Routine zum verschieben der Daten.
							;$FFFF = Systemroutine (für Icons).

			b $00				;Scrollbalken.
							;$00 = Kein Scrollbalken.

			w PM_PROPERTIES			;Routine für rechten Mausklick.
			w $0000				;Routine zum Fenster schließen.

			w $0000				;Routine für Mehrfachauswahl.
							;$0000=Nicht möglich, $ffff=Standard.
			w $0000				;Routine für Einzelauswahl.
							;$0000=Nicht möglich, $ffff=Standard.

			w $0000				;Routine zur Ausgabe eines Eintrages.
			w $0000				;Dateieinträge einlesen.

			b $00				;WM_DATA_OPTIONS, Ungenutzt?

if MAXENTRY16BIT = FALSE
			b $00				;Anzahl Einträge.
			b $00				;Zeiger auf ersten Eintrag der Seite.
endif
if MAXENTRY16BIT = TRUE
			w $0000				;Anzahl Einträge.
			w $0000				;Zeiger auf ersten Eintrag der Seite.
endif

;*** Fenster-Daten für Arbeitsplatz.
:WIN_MYCOMP		b $00				;$00 = Standardfenster
							;$ff = Feste Größe.
			b $00,$00			;Fenstergröße wenn erstes Byte = $FF.
			w $0000,$0000

			b $00				;Breite eines Eintrages.
							;$00 = Standard-Icon-Breite.
			b $00				;Höhe eines Eintrages.
							;$00 = Standard-Icon-Höhe.

			b $00				;Anzahl Spalten.
							;$00 = Wird berechnet.
			b $00				;Anzahl Zeilen.
							;$00 = Wird berechnet.

			w :101				;Zeiger auf Routine für Titelzeile.
			w $0000				;Zeiger auf Routine für Infozeile.
			w $0000				;Neues Fenster initialisieren.
							;(z.B. 64K-Bank für Datei-Cache suchen)
			w $ffff				;Routine zur Ausgabe der Daten.
			w MseClkMyComputer		;Routine wenn Fenster angeklickt.
			w $ffff				;Routine zum verschieben der Daten.
							;$FFFF = Systemroutine (für Icons).

			b $ff				;Scrollbalken.
							;$00 = Kein Scrollbalken.
			w PM_MYCOMP			;Routine für rechten Mausklick.
			w CloseMyComputer		;Routine zum Fenster schließen.

			w $0000				;Routine für Mehrfachauswahl.
							;$0000=Nicht möglich, $ffff=Standard.
			w $0000				;Routine für Einzelauswahl.
							;$0000=Nicht möglich, $ffff=Standard.

			w DrawMyComputer		;Routine zur Ausgabe eines Eintrages.
			w $0000				;Dateieinträge einlesen.

			b $00				;WM_DATA_OPTIONS, Ungenutzt?

if MAXENTRY16BIT = FALSE
			b $06				;Anzahl Einträge.
			b $00				;Zeiger auf ersten Eintrag der Seite.
endif
if MAXENTRY16BIT = TRUE
			w $0006				;Anzahl Einträge.
			w $0000				;Zeiger auf ersten Eintrag der Seite.
endif

::101			LoadW	r0,:102
			jmp	PutString

if LANG = LANG_DE
::102			b "ARBEITSPLATZ",0
endif
if LANG = LANG_EN
::102			b "My Computer",0
endif

;*** Fenster-Daten für Laufwerksfenster.
:WIN_FILES		b $00				;$00 = Standardfenster
							;$ff = Feste Größe.
			b $00,$00			;Fenstergröße wenn erstes Byte = $FF.
			w $0000,$0000

			b $00				;Breite eines Eintrages.
							;$00 = Standard-Icon-Breite.
			b $00				;Höhe eines Eintrages.
							;$00 = Standard-Icon-Höhe.

			b $00				;Anzahl Spalten.
							;$00 = Wird berechnet.
			b $00				;Anzahl Zeilen.
							;$00 = Wird berechnet.

			w PrntCurDkName			;Zeiger auf Routine für Titelzeile.
			w PrntCurDkInfo			;Zeiger auf Routine für Infozeile.
			w InitWIN			;Neues Fenster initialisieren.
							;(z.B. 64K-Bank für Datei-Cache suchen)
			w $ffff				;Routine zur Ausgabe der Daten.
			w MseClkFileWin			;Routine wenn Fenster angeklickt.
			w $ffff				;Routine zum verschieben der Daten.
							;$FFFF = Systemroutine (für Icons).

			b $ff				;Scrollbalken.
							;$00 = Kein Scrollbalken.
			w PM_FILE			;Routine für rechten Mausklick.
			w ExitWIN			;Routine zum Fenster schließen.

			w $ffff				;Routine für Mehrfachauswahl.
							;$0000=Nicht möglich, $ffff=Standard.
			w $ffff				;Routine für Einzelauswahl.
							;$0000=Nicht möglich, $ffff=Standard.

			w GD_PRINT_ENTRY		;Routine zur Ausgabe eines Eintrages.
			w SUB_GETFILES			;Dateieinträge einlesen.

			b $00				;WM_DATA_OPTIONS, Ungenutzt?

if MAXENTRY16BIT = FALSE
			b $00				;Anzahl Einträge.
			b $00				;Zeiger auf ersten Eintrag der Seite.
endif
if MAXENTRY16BIT = TRUE
			w $0000				;Anzahl Einträge.
			w $0000				;Zeiger auf ersten Eintrag der Seite.
endif
