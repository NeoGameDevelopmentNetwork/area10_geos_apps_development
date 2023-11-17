; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Info/Hilfe anzeigen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD90"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xPRINT_INFO

;*** Hilfeseite anzeigen.
:xPRINT_INFO		jsr	sys_SvBackScrn		;Bildschirm speichern.

			jsr	ResetFontGD		;Zeichensatz zurücksetzen.

			lda	C_WinBack		;Farben löschen.
			jsr	i_UserColor
			b	0,0,40,25

			lda	#$00			;Füllmuster / "Bildschirm löschen".
			jsr	SetPattern

			lda	#< InfoText1		;Hilfe Seite 1.
			ldx	#> InfoText1
			jsr	printHelpPage

			lda	#< InfoText2		;Hilfe Seite 2.
			ldx	#> InfoText2
			jsr	printHelpPage

			lda	#< InfoText3		;Hilfe Seite 3.
			ldx	#> InfoText3
			jsr	printHelpPage

			jmp	sys_LdBackScrn		;Bildschirm wieder herstellen.

;*** Hilfeseite anzeigen.
:printHelpPage		sta	r0L
			stx	r0H

			jsr	i_Rectangle		;Bildschirm löschen.
			b	$00,$c7
			w	$0000,$013f

			jsr	PutString		;Infotext ausgeben.

;*** Auf Maustaste warten.
:waitMseKey		jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

::1			lda	mouseData		;Warten bis Maustaste gedrückt ist.
			bmi	:1
::2			lda	mouseData		;Warten bis Maustaste nicht mehr
			bpl	:2			;gedrückt ist.

			ClrB	pressFlag		;Tastenstatus löschen.

			rts

;*** Macros für Hiletexte.
if .p
:IPosXY m
b GOTOXY
w §0
b §1
/
:IPosX m
b GOTOX
w §0
/
endif

;*** Infotext S1.
:l1pos0 = $0004
:l1pos1 = $000c
:l1tab0 = $0058
:l1tab1 = $00a0
:l1tab2 = $00c0

:l1y00 = $06
:l1y01 = l1y00 +8 +2
:l1y02 = l1y01 +8
:l1y03 = l1y02 +8 +1
:l1y04 = l1y03 +8
:l1y05 = l1y04 +8
:l1y06 = l1y05 +8
:l1y07 = l1y06 +8
:l1y08 = l1y07 +8
:l1y09 = l1y08 +8
:l1y10 = l1y09 +8
:l1y11 = l1y10 +8
:l1y12 = l1y11 +8
:l1y13 = l1y12 +8
:l1y14 = l1y13 +8
:l1y15 = l1y14 +8 +1
:l1y16 = l1y15 +8
:l1y17 = l1y16 +8
:l1y18 = l1y17 +8
:l1y19 = l1y18 +8 +1
:l1y20 = l1y19 +8
:l1y21 = l1y20 +8 +1
:l1y22 = l1y21 +8
:l1y23 = l1y22 +8

if LANG = LANG_DE
:InfoText1
IPosXY l1pos0,l1y00
b "*** INFORMATIONEN ZU GEODESK SEITE 1 ***"

IPosXY l1pos0,l1y01
			b "*"
IPosX l1pos1
			b "FENSTER-NAVIGATION:"

IPosXY l1pos1,l1y02
			b "C= / Mausklick Scroll-Up: "
			b "Zum Anfang"

IPosX l1tab1
			b "C= / Mausklick Scroll-Down: "
			b "Zum Ende"

IPosXY l1pos0,l1y03
			b "*"
IPosX l1pos1
			b "DATEI-AUSWAHL:"

IPosXY l1pos1,l1y04
			b "Datei auswählen:"
IPosXY l1tab0,l1y04
			b "C=-Taste und linke Maustaste"

IPosXY l1pos1,l1y05
			b "Mehrere Dateien auswählen:"

IPosXY l1pos1,l1y06
			b "Modus `Auswahl`"
IPosXY l1tab0,l1y06
			b "Maustaste gedrückt halten und Maus von links nach rechts"
IPosXY l1tab0,l1y07
			b "bewegen, dann die Maustaste loslassen."
IPosXY l1tab0,l1y08
			b "Dateinamen innerhalb des Gummibandes werden ausgewählt."

IPosXY l1pos1,l1y09
			b "Modus `Markieren`"
IPosXY l1tab0,l1y09
			b "Maustaste gedrückt halten und Maus von rechts nach links"
IPosXY l1tab0,l1y10
			b "bewegen, dann die Maustaste loslassen."
IPosXY l1tab0,l1y11
			b "Dateinamen müssen nur zum Teil innerhalb des Gummibandes"
IPosXY l1tab0,l1y12
			b "liegen um markiert zu werden."

IPosXY l1pos1,l1y13
			b "SHIFT `Links` drücken um bei Mehrfachauswahl Mausklick auf Dateieintrag zu"
IPosXY l1pos1,l1y14
			b "ignorieren und direkt mit der Dateiauswahl zu beginnen."

IPosXY l1pos0,l1y15
			b "*"
IPosX l1pos1
			b "DATEIEN KOPIEREN:"

IPosXY l1pos1,l1y16
			b "Dateien über Drag`n`Drop auf ein Fenster ziehen."
IPosXY l1pos1,l1y17
			b "SHIFT + C= drücken um Dateien zu verschieben."
IPosXY l1pos1,l1y18
			b "SHIFT drücken um Dateien innerhalb des gleichen Fensters zu duplizieren."

IPosXY l1pos0,l1y19
			b "*"
IPosX l1pos1
			b "DATEIEN LÖSCHEN:"

IPosXY l1pos1,l1y20
			b "C= Taste drücken um `Datei löschen` anzuzeigen (Standard)."

IPosXY l1pos0,l1y21
			b "*"
IPosX l1pos1
			b "DISKETTEN KOPIEREN:"

IPosXY l1pos1,l1y22
			b "Laufwerk aus Arbeitsplatz-Fenster mit Drag`n`Drop auf ein zweites Laufwerk oder"
IPosXY l1pos1,l1y23
			b "ein anderes Fenster ziehen und ablegen."

b NULL
endif

if LANG = LANG_EN
:InfoText1
IPosXY l1pos0,l1y00
b "*** INFORMATIONS ABOUT GEODESK PAGE 1 ***"

IPosXY l1pos0,l1y01
			b "*"
IPosX l1pos1
			b "WINDOW NAVIGATION:"

IPosXY l1pos1,l1y02
			b "C= / mouse click Scroll-Up: "
			b "Top of list"

IPosX l1tab1
			b "C= / mouse click Scroll-Down: "
			b "End of list"

IPosXY l1pos0,l1y03
			b "*"
IPosX l1pos1
			b "FILE SELECTION:"

IPosXY l1pos1,l1y04
			b "Select a file:"
IPosXY l1tab0,l1y04
			b "C= and left mouse button"

IPosXY l1pos1,l1y05
			b "Select multiple files:"

IPosXY l1pos1,l1y06
			b "Mode `Selection`"
IPosXY l1tab0,l1y06
			b "Keep mouse button pressed and move mouse from left"
IPosXY l1tab0,l1y07
			b "to right, then release mouse button."
IPosXY l1tab0,l1y08
			b "File names inside the rubber band are selected."

IPosXY l1pos1,l1y09
			b "Mode `Mark`"
IPosXY l1tab0,l1y09
			b "Keep mouse button pressed and move mouse from right"
IPosXY l1tab0,l1y10
			b "to left, then release mouse button."
IPosXY l1tab0,l1y11
			b "File names must onl1y partiall1y inside the rubber band"
IPosXY l1tab0,l1y12
			b "to be marked."

IPosXY l1pos1,l1y13
			b "Press SHIFT `Left` to ignore the file entry and start file selection"
IPosXY l1pos1,l1y14
			b "directl1y when selecting multiple files."

IPosXY l1pos0,l1y15
			b "*"
IPosX l1pos1
			b "COPY FILES:"

IPosXY l1pos1,l1y16
			b "Drag`n`Drop files to another file window."
IPosXY l1pos1,l1y17
			b "Press SHIFT + C= to move files between windows."
IPosXY l1pos1,l1y18
			b "Press SHIFT to duplicate files within the same window."

IPosXY l1pos0,l1y19
			b "*"
IPosX l1pos1
			b "DELETE FILES:"

IPosXY l1pos1,l1y20
			b "Press C= to display `DELETE FILES` options (default)."

IPosXY l1pos0,l1y21
			b "*"
IPosX l1pos1
			b "COPY DISK:"

IPosXY l1pos1,l1y22
			b "Drag`n`Drop a drive icon from MyComputer window to a second drive"
IPosXY l1pos1,l1y23
			b "or drop the icon to some other file window."

b NULL
endif

;*** Infotext S2.
:l2pos0 = $0004		;*
:l2pos1 = $000c		;Titel/ShortCut.
:l2pos2 = $0028		;Funktion.
:l2pos3 = $00a8		;ShortCut.
:l2pos4 = $00c4		;Funktion.
:l2pos5 = $00dc		;Funktion.

:l2y00 = $06
:l2y01 = l2y00 +8 +2

:l2y02 = l2y01 +8 +3
:l2y03 = l2y02 +8 +1
:l2y04 = l2y03 +8
:l2y05 = l2y04 +8
:l2y06 = l2y05 +8
:l2y07 = l2y06 +8

:l2y08 = l2y07 +8 +3
:l2y09 = l2y08 +8 +1
:l2y10 = l2y09 +8
:l2y11 = l2y10 +8
:l2y12 = l2y11 +8
:l2y13 = l2y12 +8
:l2y14 = l2y13 +8
:l2y94 = l2y14 +8

:l2y15 = l2y14 +8 +3
:l2y16 = l2y15 +8 +1
:l2y17 = l2y16 +8
:l2y18 = l2y17 +8
:l2y19 = l2y18 +8
:l2y20 = l2y19 +8
:l2y21 = l2y20 +8
:l2y22 = l2y21 +8

if LANG = LANG_DE
:InfoText2
IPosXY l2pos0,l2y00
b "*** INFORMATIONEN ZU GEODESK SEITE 2 ***"

IPosXY l2pos0,l2y01
			b "*"
			IPosX l2pos1
			b "TASTATURBEFEHLE:"

IPosXY l2pos1,l2y02
b "DISKETTE/LAUFWERK:"

IPosXY l2pos1,l2y03
			b "C= N"
			IPosX l2pos2
			b "Umbenennen/Eigenschaften"
IPosXY l2pos1,l2y04
			b "C= E/B"
			IPosX l2pos2
			b "Verzeichnis/Diskette löschen"
IPosXY l2pos1,l2y05
			b "C= F"
			IPosX l2pos2
			b "Laufwerk formatieren"
IPosXY l2pos1,l2y06
			b "C= V"
			IPosX l2pos2
			b "Laufwerk überprüfen (Validate)"
IPosXY l2pos1,l2y07
			b "C= J"
			IPosX l2pos2
			b "Partition/DiskImage wechseln"

IPosXY l2pos3,l2y02
b "DATEI:"

IPosXY l2pos3,l2y03
			b "C= Z"
			IPosX l2pos4
			b "Öffnet Datei unter Mauszeiger"
IPosXY l2pos3,l2y04
			b "C= Q"
			IPosX l2pos4
			b "Umbenennen/Eigenschaften"
IPosXY l2pos3,l2y05
			b "C= D"
			IPosX l2pos4
			b "Löschen (auch Verzeichnisse)"
IPosXY l2pos3,l2y06
			b "C= T"
			IPosX l2pos4
			b "Vertauscht die Position von"
			IPosXY l2pos4,l2y07
			b "zwei markierten Dateien"

IPosXY l2pos1,l2y08
b "FENSTER:"

IPosXY l2pos1,l2y09
			b "C= W"
			IPosX l2pos2
			b "(+SHIFT) Dateien wählen/abwählen"
IPosXY l2pos1,l2y10
			b "C= R"
			IPosX l2pos2
			b "Verzeichnis neu einlesen"
IPosXY l2pos1,l2y11
			b "C= S"
			IPosX l2pos2
			b "Fenster stapeln"
IPosXY l2pos1,l2y12
			b "C= L"
			IPosX l2pos2
			b "Fenster anordnen"
IPosXY l2pos1,l2y13
			b "C= C"
			IPosX l2pos2
			b "Alle Fenster schließen"
IPosXY l2pos1,l2y14
			b "C= Y"
			IPosX l2pos2
			b "Oberstes Fenster schließen"

IPosXY l2pos3,l2y08
b "ANZEIGE:"

IPosXY l2pos3,l2y09
			b "F2"
			IPosX l2pos4
			b "Schnellauswahl Eingabegerät"
IPosXY l2pos3,l2y10
			b "F3/F4"
			IPosX l2pos4
			b "Icon-/Detail-/Kompakt-Modus"
IPosXY l2pos3,l2y11
			b "F5"
			IPosX l2pos4
			b "Nach Name sortieren"
IPosXY l2pos3,l2y12
			b "F6"
			IPosX l2pos4
			b "Nach Datum sortieren (Neu>Alt)"
IPosXY l2pos3,l2y13
			b "F7"
			IPosX l2pos4
			b "Dateifilter: Dokumente"
IPosXY l2pos3,l2y14
			b "F8"
			IPosX l2pos4
			b "Dateifilter: Anwendungen"
IPosXY l2pos3,l2y94
			b "(at)"
			IPosX l2pos4
			b "Nur gelöschte Dateien"

IPosXY l2pos1,l2y15
b "SONSTIGES:"

IPosXY l2pos1,l2y16
			b "C= H"
			IPosX l2pos2
			b "Diese Hilfe anzeigen"
IPosXY l2pos1,l2y17
			b "C= A"
			IPosX l2pos2
			b "Arbeitsplatz öffnen"
IPosXY l2pos1,l2y18
			b "C= 8"
			IPosX l2pos2
			b "(+SHIFT) Laufwerk A:/8 öffnen"
IPosXY l2pos1,l2y19
			b "C= 9"
			IPosX l2pos2
			b "(+SHIFT) Laufwerk B:/9 öffnen"
IPosXY l2pos1,l2y20
			b "C= 0"
			IPosX l2pos2
			b "(+SHIFT) Laufwerk C:/10 öffnen"
IPosXY l2pos1,l2y21
			b "C= 1"
			IPosX l2pos2
			b "(+SHIFT) Laufwerk D:/11 öffnen"
IPosXY l2pos1,l2y22
			b "C= O"
			IPosX l2pos2
			b "Dateien im Verzeichnis ordnen"

IPosXY l2pos3,l2y16
			b "C= E"
			IPosX l2pos4
			b "+<SHIFT>  Systemeinstellungen"
IPosXY l2pos3,l2y17
			b "C= U"
			IPosX l2pos4
			b "Verzeichnis erstellen"
IPosXY l2pos3,l2y18
			b "C= / <-"
			IPosX l2pos4
			b "Haupt-/Elternverzeichnis öffnen"
IPosXY l2pos3,l2y19
			b "CRSR-Tasten"
			IPosX l2pos5
			b "In Dateiliste blättern"
IPosXY l2pos3,l2y20
			b "HOME / CLR"
			IPosX l2pos5
			b "Dateiliste Anfang / Ende"
IPosXY l2pos3,l2y21
			b "C= DEL"
			IPosX l2pos4
			b "Bildschirmschoner starten"
IPosXY l2pos3,l2y22
			b "C= X"
			IPosX l2pos4
			b "PopUp-Menü öffnen"

b NULL
endif

if LANG = LANG_EN
:InfoText2
IPosXY l2pos0,l2y00
b "*** INFORMATIONS ABOUT GEODESK PAGE 2 ***"

IPosXY l2pos0,l2y01
b "*"
IPosX l2pos1
b "SHORTCUTS:"

IPosXY l2pos1,l2y02
b "DISK/DRIVE:"

IPosXY l2pos1,l2y03
			b "C= N"
			IPosX l2pos2
			b "Rename/properties"
IPosXY l2pos1,l2y04
			b "C= E/B"
			IPosX l2pos2
			b "Delete directory/disk contents"
IPosXY l2pos1,l2y05
			b "C= F"
			IPosX l2pos2
			b "Format disk"
IPosXY l2pos1,l2y06
			b "C= V"
			IPosX l2pos2
			b "Validate disk"
IPosXY l2pos1,l2y07
			b "C= J"
			IPosX l2pos2
			b "Switch partition/diskimage"

IPosXY l2pos3,l2y02
b "FILE:"

IPosXY l2pos3,l2y03
			b "C= Z"
			IPosX l2pos4
			b "Open file at mouse position"
IPosXY l2pos3,l2y04
			b "C= Q"
			IPosX l2pos4
			b "Rename/properties"
IPosXY l2pos3,l2y05
			b "C= D"
			IPosX l2pos4
			b "Delete (incl. directories)"
IPosXY l2pos3,l2y06
			b "C= T"
			IPosX l2pos4
			b "Swap position of two"
			IPosXY l2pos4,l2y07
			b "selected files"

IPosXY l2pos1,l2y08
b "WINDOWS:"

IPosXY l2pos1,l2y09
			b "C= W"
			IPosX l2pos2
			b "(+SHIFT) Select/Unselect files"
IPosXY l2pos1,l2y10
			b "C= R"
			IPosX l2pos2
			b "Reload directory"
IPosXY l2pos1,l2y11
			b "C= S"
			IPosX l2pos2
			b "Sort windows"
IPosXY l2pos1,l2y12
			b "C= L"
			IPosX l2pos2
			b "Align windows"
IPosXY l2pos1,l2y13
			b "C= C"
			IPosX l2pos2
			b "Close all windows"
IPosXY l2pos1,l2y14
			b "C= Y"
			IPosX l2pos2
			b "Close top window"

IPosXY l2pos3,l2y08
b "VIEW MODE:"

IPosXY l2pos3,l2y09
			b "F2"
			IPosX l2pos4
			b "Fast select input device"
IPosXY l2pos3,l2y10
			b "F3/F4"
			IPosX l2pos4
			b "Icon-/Detail-/Compact mode"
IPosXY l2pos3,l2y11
			b "F5"
			IPosX l2pos4
			b "Sort by file name"
IPosXY l2pos3,l2y12
			b "F6"
			IPosX l2pos4
			b "Sort by date (new>old)"
IPosXY l2pos3,l2y13
			b "F7"
			IPosX l2pos4
			b "Filter: Documents"
IPosXY l2pos3,l2y14
			b "F8"
			IPosX l2pos4
			b "Filter: Applications"
IPosXY l2pos3,l2y94
			b "(at)"
			IPosX l2pos4
			b "Deleted files only"

IPosXY l2pos1,l2y15
b "MISCELLANEOUS:"

IPosXY l2pos1,l2y16
			b "C= H"
			IPosX l2pos2
			b "Open this help page"
IPosXY l2pos1,l2y17
			b "C= A"
			IPosX l2pos2
			b "Open MyComputer"
IPosXY l2pos1,l2y18
			b "C= 8"
			IPosX l2pos2
			b "(+SHIFT) Open drive A:/8"
IPosXY l2pos1,l2y19
			b "C= 9"
			IPosX l2pos2
			b "(+SHIFT) Open drive B:/9"
IPosXY l2pos1,l2y20
			b "C= 0"
			IPosX l2pos2
			b "(+SHIFT) Open drive C:/10"
IPosXY l2pos1,l2y21
			b "C= 1"
			IPosX l2pos2
			b "(+SHIFT) Open drive D:/11"
IPosXY l2pos1,l2y22
			b "C= O"
			IPosX l2pos2
			b "Organize files in directory"

IPosXY l2pos3,l2y16
			b "C= E"
			IPosX l2pos4
			b "+<SHIFT>  System settings"
IPosXY l2pos3,l2y17
			b "C= U"
			IPosX l2pos4
			b "Create directory"
IPosXY l2pos3,l2y18
			b "C= / <-"
			IPosX l2pos4
			b "Open root/parent directory"
IPosXY l2pos3,l2y19
			b "CRSR keys"
			IPosX l2pos5
			b "Navigate in file list"
IPosXY l2pos3,l2y20
			b "HOME / CLR"
			IPosX l2pos5
			b "Move to top/end"
IPosXY l2pos3,l2y21
			b "C= DEL"
			IPosX l2pos4
			b "Start screen saver"
IPosXY l2pos3,l2y22
			b "C= X"
			IPosX l2pos4
			b "Open PopUp menu"

b NULL
endif

;*** Infotext S3.
:l3pos0 = $0004		;*
:l3pos1 = $000c		;Titel/ShortCut.
:l3pos2 = $0024		;Funktion.
:l3pos3 = $0048		;Funktion.

:l3y00 = $06
:l3y01 = l3y00 +8 +2

:l3y02 = l3y01 +8 +3
:l3y03 = l3y02 +8 +1
:l3y04 = l3y03 +8
:l3y05 = l3y04 +8
:l3y06 = l3y05 +8
:l3y07 = l3y06 +8 +2
:l3y08 = l3y07 +8
:l3y09 = l3y08 +8
:l3y10 = l3y09 +8

:l3y11 = l3y10 +8 +3
:l3y12 = l3y11 +8 +1
:l3y13 = l3y12 +8

:l3y14 = l3y13 +8 +3

:l3y15 = l3y14 +8 +2
:l3y16 = l3y15 +8

:l3y17 = l3y16 +8 +3

:l3y18 = l3y17 +8 +2
:l3y19 = l3y18 +8
:l3y20 = l3y19 +8

if LANG = LANG_DE
:InfoText3
IPosXY l3pos0,l3y00
b "*** INFORMATIONEN ZU GEODESK SEITE 3 ***"

IPosXY l3pos0,l3y01
			b "*"
			IPosX l3pos1
			b "TASTATURBEFEHLE FÜR `VERZEICHNIS SORTIEREN`:"

IPosXY l2pos1,l2y02
b "ORIGINAL-VERZEICHNIS:"

IPosXY l3pos1,l3y03
			b "A"
			IPosX l3pos2
			b "Alle Dateien auswählen"
IPosXY l3pos1,l3y04
			b "D"
			IPosX l3pos2
			b "Alle Dateien abwählen"
IPosXY l3pos1,l3y05
			b "S"
			IPosX l3pos2
			b "Dateien der aktuellen Seite markieren"
IPosXY l3pos1,l3y06
			b "C"
			IPosX l3pos2
			b "Markierte Dateien in Ziel-Verzeichnis übertragen"

IPosXY l3pos1,l3y07
			b "Cursor rauf"
			IPosX l3pos3
			b "Eine Zeile rauf"
IPosXY l3pos1,l3y08
			b "Cursor runter"
			IPosX l3pos3
			b "Eine Zeile runter"
IPosXY l3pos1,l3y09
			b "Cursor links"
			IPosX l3pos3
			b "Eine Seite zurück"
IPosXY l3pos1,l3y10
			b "Cursor rechts"
			IPosX l3pos3
			b "Eine Seite vorwärts"

IPosXY l3pos1,l3y11
b "SORTIERTES VERZEICHNIS:"

IPosXY l3pos1,l3y12
			b "X"
			IPosX l3pos3
			b "Verzeichnis zurücksetzen"
IPosXY l3pos1,l3y13
			b "SHIFT + S"
			IPosX l3pos3
			b "Ziel-Verzeichnis schreiben"

IPosXY l3pos0,l3y14
			b "*"
			IPosX l3pos1
			b "MAUSSTEUERUNG FÜR `VERZEICHNIS SORTIEREN`:"

IPosXY l3pos1,l3y15
			b "Dauerfunktion mit gedrückter C=-Taste aktivieren für die Dateiauswahl und die"
IPosXY l3pos1,l3y16
			b "`Zeile hoch/runter`-Funktion. C=-Taste freigeben um Dauerfunktion zu beenden."

IPosXY l3pos0,l3y17
			b "*"
			IPosX l3pos1
			b "ERWEITERTES RECHTS-KLICK-MENÜ FÜR LAUFWERKSFENSTER:"

IPosXY l3pos1,l3y18
			b "C=-Taste und rechte Maustaste öffnet das erweiterte Laufwerks-Menü:"
IPosXY l3pos1,l3y19
			b ">>Verzeichnis"
			IPosX l3pos3
			b "Schnelle Verzeichnisanzeige für Laufwerke am seriellen Bus."
IPosXY l3pos1,l3y20
			b "Befehl senden"
			IPosX l3pos3
			b "Befehl an Laufwerk am seriellen Bus senden."

b NULL
endif

if LANG = LANG_EN
:InfoText3
IPosXY l3pos0,l3y00
b "*** INFORMATIONS ABOUT GEODESK PAGE 3 ***"

IPosXY l3pos0,l3y01
			b "*"
			IPosX l3pos1
			b "SHORTCUTS FOR `SORT DIRECTORY`:"

IPosXY l2pos1,l2y02
b "ORIGINAL DIRECTORY:"

IPosXY l3pos1,l3y03
			b "A"
			IPosX l3pos2
			b "Select all files"
IPosXY l3pos1,l3y04
			b "D"
			IPosX l3pos2
			b "Unselect all files"
IPosXY l3pos1,l3y05
			b "S"
			IPosX l3pos2
			b "Select all files from the current page"
IPosXY l3pos1,l3y06
			b "C"
			IPosX l3pos2
			b "Move files to target directory"

IPosXY l3pos1,l3y07
			b "Cursor up"
			IPosX l3pos3
			b "Scroll one line up"
IPosXY l3pos1,l3y08
			b "Cursor down"
			IPosX l3pos3
			b "Scroll one line down"
IPosXY l3pos1,l3y09
			b "Cursor left"
			IPosX l3pos3
			b "Go to last page"
IPosXY l3pos1,l3y10
			b "Cursor right"
			IPosX l3pos3
			b "Go to next page"

IPosXY l3pos1,l3y11
b "SORTED DIRECTORY:"

IPosXY l3pos1,l3y12
			b "X"
			IPosX l3pos3
			b "Reset directory"
IPosXY l3pos1,l3y13
			b "SHIFT + S"
			IPosX l3pos3
			b "Write new directory"

IPosXY l3pos0,l3y14
			b "*"
			IPosX l3pos1
			b "NAVIGATION FOR `SORT DIRECTORY`:"

IPosXY l3pos1,l3y15
			b "Continuous function with C=-key enabled for file selection and `line up/down`-"
IPosXY l3pos1,l3y16
			b "function. Release C=-key to exit the continuous function."

IPosXY l3pos0,l3y17
			b "*"
			IPosX l3pos1
			b "EXTENDED POPUP-MENÜ FOR DRIVE WINDOWS:"

IPosXY l3pos1,l3y18
			b "Hold down C=-key and right mouse button will open the extended drive menu:"
IPosXY l3pos1,l3y19
			b ">>Directory"
			IPosX l3pos3
			b "Fast directory listing of drives connected to the serial bus."
IPosXY l3pos1,l3y20
			b "Send command"
			IPosX l3pos3
			b "Send command to drives connected to the serial bus."

b NULL
endif

;*** Endadresse testen:
			g BASE_DIRDATA
;***
