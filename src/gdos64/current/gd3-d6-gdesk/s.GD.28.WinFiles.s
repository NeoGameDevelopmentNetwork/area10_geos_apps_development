; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei-Eintrag einlesen/ausgeben.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "s.GD.21.Desk.ext"
endif

;*** GEOS-Header.
			n "obj.GD28"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
:VlirJumpTable		rts				;Programm-Routine #1.
			b $00,$00			;(Nicht verwendet)

			rts				;Programm-Routine #2.
			b $00,$00			;(Nicht verwendet)

			rts				;Programm-Routine #3.
			b $00,$00			;(Nicht verwendet)

			jmp	e_InitEntryCnt		;Zeiger auf Anfang.
			jmp	e_InitWinDirData	;Verzeichnisdaten zurücksetzen.
			jmp	e_InitWinData		;Fenster initialisieren.
			jmp	e_InitWinGrid		;Raster initialisieren.
			jmp	e_GetDirData		;Dateien einlesen.
			jmp	e_GetCacheData		;Dateien aus Cache einlesen.
			jmp	e_PrintEntry		;Eintrag ausgeben.
			jmp	e_SetFSlctMode		;Auswahlmodus festlegen.
			jmp	e_WinDataSSlct		;Einzel-Auswahl.
			jmp	e_WinDataMSlct		;Mehrfach-Auswahl.
			jmp	e_WinDataUpdate		;Fensterinhalt speichern.
			jmp	e_ResetDirData		;Dateien in Speicher laden.
			jmp	e_UnslctDirData		;Auswahl aufheben.

			rts				;Menü linke Maustaste.
			b $00,$00			;(Nicht verwendet)

			rts				;Menü rechte Maustaste.
			b $00,$00			;(Nicht verwendet)

;*** Systemroutinen.
			t "-SYS_GTYPE"
			t "-SYS_GTYPE_TXT"
			t "-SYS_CTYPE"

;*** Dateizähler zurücksetzen.
:e_InitEntryCnt		lda	#$00
			sta	WM_DATA_MAXENTRY
			sta	WM_DATA_CURENTRY
			rts

;*** Verzeichnisdaten zurücksetzen.
:e_InitWinDirData	ldx	WM_WCODE		;Anzahl gewählte Dateien löschen.
			lda	#$00
			sta	WIN_DIR_TR,x		;Start-Position Verzeichnis
			sta	WIN_DIR_SE,x		;zurücksetzen.
			sta	WIN_DIR_POS,x
			sta	WIN_DIR_NR,x
			sta	WIN_DIR_START,x		;Die ersten Dateien einlesen.
			rts

;*** Laufwerksfenster initialisieren.
:e_InitWinData		jsr	e_InitEntryCnt		;Datei-Zähler löschen.
			jsr	e_InitWinDirData	;Verzeichnisdaten zurücksetzen.

;			ldx	WM_WCODE
;			lda	#$00
			sta	WMODE_SLCT,x		;Dateiauswahl aufheben.

;			lda	#GMNU_WINFILES
;			sta	WM_DATA_OPTIONS

;			lda	#< extWin_MSlctData
;			ldy	#> extWin_MSlctData
;			sta	WM_DATA_WINMSLCT +0
;			sty	WM_DATA_WINMSLCT +1

;			lda	#< extWin_SSlctData
;			ldy	#> extWin_SSlctData
;			sta	WM_DATA_WINSSLCT +0
;			sty	WM_DATA_WINSSLCT +1

;			lda	#< extWin_PrntEntry
;			ldy	#> extWin_PrntEntry
;			sta	WM_DATA_PRNFILE +0
;			sty	WM_DATA_PRNFILE +1

;			lda	#< extWin_GetData
;			ldy	#> extWin_GetData
;			sta	WM_DATA_GETFILE +0
;			sty	WM_DATA_GETFILE +1

			jsr	WM_SAVE_WIN_DATA	;Fenster-Daten speichern.

;*** Fenster-Grid initialisieren.
:e_InitWinGrid		ldx	WM_WCODE
			lda	WMODE_VICON,x		;Icon-Modus aktiv?
			bne	:1			; => Nein, Info/Text-Modus...

;--- Icon-Modus.
			lda	#$ff			;Standard-Verschieben für Icons.
			ldx	#$00			;Automatische Spaltenanzahl.
			ldy	#$00			;Standard Zeilenhöhe.
			beq	:3			;Grid-Daten setzen.

;--- Text-Modus.
::1			lda	WMODE_VINFO,x		;Text-Modus aktiv?
			bne	:2			; => Nein, Info-Modus.

			lda	#$ee			;Standard-Verschieben für Text.
			ldx	#$00			;Automatische Spaltenanzahl.
			ldy	#$08			;8 Pixel Zeilenhöhe.
			bne	:3			;Grid-Daten setzen.

;--- Info-Modus.
::2			lda	#$ee			;Verschieben für Text-Modus.
			ldx	#$01			;Max. 1 Spalte.
			ldy	#$08			;8 Pixel Zeilenhöhe.

;--- Werte an Fenstermanager übergeben.
::3			sta	r0L
			stx	r1L
			sty	r1H

			jsr	WM_LOAD_WIN_DATA	;Fenster-Daten einlesen.

			lda	r0L			;Verschiebe-Routine festlegen.
			sta	WM_DATA_WINMOVE+0
			sta	WM_DATA_WINMOVE+1

			lda	r1L			;Anzahl Spalten setzen.
			sta	WM_DATA_COLUMN

			lda	r1H			;Zeilenhöhe setzen.
			sta	WM_DATA_GRID_Y

			jmp	WM_SAVE_WIN_DATA	;Fenster-Daten speichern.

;*** Dateien einlesen.
:e_GetDirData		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partition oder Dateien einlesen ?
			beq	:load_files		; => Dateien einlesen, weiter...

;--- Partitionen/DiskImages einlesen.
::load_part		lda	GD_RELOAD_DIR		;Dateien direkt von Disk laden ?
			beq	:1			; => Nein, weiter...

			jmp	SUB_GETPART		;Partitionen/DiskImages einlesen.

::1			lda	getFileWin		;Dateien bereits im RAM ?
			cmp	WM_WCODE
			beq	:exit			; => Ja, Ende...
			bne	:load_cache

;--- Dateien einlesen.
::load_files		lda	GD_RELOAD_DIR		;Dateien direkt von Disk laden ?
			beq	:2			; => Nein, weiter...

			jmp	SUB_GETFILES		;Dateien einlesen.

::2			lda	getFileWin		;Dateien bereits im RAM ?
			cmp	WM_WCODE
			beq	:exit			; => Ja, Ende...

;--- Ergänzung: 09.05.21/M.Kanet
;Dateien direkt aus Cache einlesen.
;Dazu muss das Laufwerk gewechselt, die
;Dateien aus dem Cache geladen und dann
;das aktuelle Fenster in ":getFileWin"
;gespeichert werden.
::load_cache		jsr	WM_OPEN_DRIVE		;Ziel-Laufwerk öffnen.

			jsr	SET_CACHE_DATA		;Verzeichnisdaten direkt aus
			jsr	FetchRAM		;dem Cache einlesen.

			lda	WM_WCODE		;Aktuelle Fensternummer.
			sta	getFileWin		;Daten für Fenster im RAM.
::exit			rts

;*** Dateien aus Cache einlesen.
;HINWEIS:
;Bei SET_CACHE_DATA/FetchRAM auch das
;Laufwerk für GetFiles setzen.
;
;Damit wird der Routine signalisiert
;welche Dateien von welchem Laufwerk
;im RAM vorhanden sind.
;Dadurch wird verhindert das die
;GetFiles-Routine den Cache mit den
;falschen Dateien aktualisiert.
;
:e_GetCacheData
;--- Ergänzung: 24.11.19/M.Kanet
;Nicht auf WM_STACK zurückgreifen, da
;sich der Stack ggf. geändert hat.
;Immer das aktuelle Fenster verwenden!
;			ldx	WM_STACK
			ldx	WM_WCODE		;Laufwerksdaten für die Dateien
			stx	getFileWin		;im RAM setzen.

			lda	WIN_DRIVE,x		;Laufwerk setzen.
			sta	getFileDrv

			lda	WIN_PART,x		;Ggf. Partition setzen.
			sta	getFilePart

			lda	WIN_SDIR_T,x		;Ggf. Unterverzeichnis setzen.
			sta	getFileSDir +0
			lda	WIN_SDIR_S,x
			sta	getFileSDir +1

			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache setzen.
			jmp	FetchRAM		;Cache im RAM einlesen.

;*** Einzel-Auswahl von Dateien.
:e_WinDataSSlct		ldx	WM_WCODE
			ldy	WIN_DATAMODE,x		;Partitionen oder DiskImages ?
			bne	NO_SLCT_DDATA		; => Ja, keine Auswahl möglich.

			jmp	WM_SLCT_SINGLE		; => Einzel-Auswahl.

;*** Mehrfach-Auswahl von Dateien.
:e_WinDataMSlct		ldx	WM_WCODE
			ldy	WIN_DATAMODE,x		;Partitionen oder DiskImages ?
			bne	NO_SLCT_DDATA		; => Ja, keine Auswahl möglich.

			jmp	WM_SLCT_MULTI		; => Mehrfach-Auswahl.

;*** Fensterinhalt speichern.
:e_WinDataUpdate	jsr	SET_CACHE_DATA		;Verzeichnisdaten aktualisieren.
			jsr	StashRAM

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

			jsr	WM_SAVE_SCREEN		;Fenster in Cache speichern.

:NO_SLCT_DDATA		rts

;*** Fenster/Verzeichnis-Daten aktivieren.
:e_ResetDirData		ldx	WM_STACK		;DeskTop aktiv?
			beq	NO_SLCT_DDATA		; => Ja, Abbruch...

			lda	WIN_DRIVE,x		;Laufwerksfenster?
			beq	NO_SLCT_DDATA		; => Nein, Ende...

			stx	WM_WCODE		;Oberstes Fenster aktivieren.
			jsr	WM_LOAD_WIN_DATA

:e_UnslctDirData	jsr	e_GetCacheData		;Verzeichnis aus Cache einlesen.

			lda	#GD_MODE_UNSLCT
			sta	r10L
			jsr	e_SetFSlctMode		;Datei-Auswahl aufheben.

;			jsr	SET_CACHE_DATA		;Verzeichnisdaten aktualisieren.
			jsr	StashRAM

			jmp	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

;
;Routine  : e_SetFSlctMode
;Parameter: r10L = Auswahlmodus:
;                  $00 -> Nicht ausgewählt.
;                  $FF -> Ausgewählt.
;Rückgabe : -
;Verändert: A,X,Y,r11,r12
;Funktion : Auswahlflag für alle Dateien setzen/löschen.
;
:e_SetFSlctMode		lda	WM_DATA_MAXENTRY
			beq	:exit			; => Dateien vorhanden, weiter.

			lda	#< BASE_DIRDATA		;Zeiger auf Verzeichnisdaten.
			sta	r12L
			lda	#> BASE_DIRDATA
			sta	r12H

			lda	WM_DATA_MAXENTRY
			sta	r11L

::loop			ldy	#$02
			lda	(r12L),y		;Dateityp-Byte einlesen.
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:next			; => Ja, Ende...

			ldy	#$00
			lda	r10L			;Markierungsmodus in Speicher
			sta	(r12L),y		;schreiben.

::next			lda	r12L			;Zeiger auf nächsten Eintrag/Cache.
			clc
			adc	#32
			sta	r12L
			bcc	:add
			inc	r12H

::add			dec	r11L
			bne	:loop			; => Nein, weiter...

::exit			rts

;*** Einzelnen Datei-Eintrag ausgeben.
;    Aufruf aus Fenster-Manager.
;    Übergabe: r0 = Aktueller Eintrag.
;              r1L/r1H = XPos/YPos.
;              r2L/r2H = MaxX/MaxY.
;              r3L/r3H = GridX/GridY
:e_PrintEntry		lda	r0L
			sta	r15L

			ldx	#r15L			;Zeiger auf Verzeichnis-Eintrag
			jsr	WM_SETVEC_ENTRY		;im RAM berechnen.

			jsr	ReadFName		;Dateiname kopieren.

			ldx	WM_WCODE
			lda	WMODE_VICON,x		;Anzeige-Modus einlesen.
			bne	:20			; => Keine Icons anzeigen.

;--- Icon-Ausgabe.
			jsr	WM_TEST_ENTRY_X		;Eintrag noch innerhalb der Zeile?
			bcs	:exit			; => Nein, Ende...

			lda	r1L			;Für Icon-Anzeige XPos +3 Cards.
			clc
			adc	#3
			sta	r1L

;--- Icons in Farbe oder S/W?
			bit	GD_COL_MODE		;Farb-Modus aktiv?
			bmi	:10			; => Nein, weiter...

			jsr	DefGTypeID		;Zeiger auf Farb-Tabelle setzen.
			tax
			lda	GD_COLICON,x		;Icon-Farbe aus Tabelle einlesen.
			bne	:13			;GEOS-Datei => Systemfarbe.
			beq	:12			;BASIC-Datei => Standardfarbe.

;--- Ende, kein Icon angezeigt.
::exit			ldx	#$00			;Ende.
			rts

;--- Icons in S/W, Debug aktiv?
::10			bit	GD_COL_DEBUG		;Debug-Modus aktiv?
			bpl	:12			; => Nein, weiter...

			ldy	#$01
			lda	(r15L),y		;Icon im Cache?
			cmp	#GD_MODE_ICACHE
			bne	:12			; => Nein, weiter...

::11			lda	GD_COL_CACHE		;Debug-Modus: Farbe für
			jmp	:13			;"Icon im Cache" setzen.

::12			lda	C_WinBack		;S/W-Modus: Textfarbe für Fenster
			and	#%11110000		;als Icon-Farbe verwenden.
::13			sta	r3L
			lda	C_WinBack		;Mit Hintergrundfarbe verknüpfen.
			and	#%00001111
			ora	r3L

			pha
			jsr	GetFileIcon_r0		;Datei-Icon einlesen.
			pla
			sta	r3L			;Farbwert speichern.

			lda	#$03			;Breite Icon in Cards.
			sta	r2L
			lda	#$15			;Höhe Icon in Pixel.
			sta	r2H

;			lda	#$01			;Farbe für Icon (Bereits gesetzt).
;			sta	r3L

			lda	#$04			;DeltaY in Cards für Ausgabe Name.
			sta	r3H

			lda	#< FNameBuf		;Zeiger auf Dateiname.
			sta	r4L
			lda	#> FNameBuf
			sta	r4H
			jsr	GD_FICON_NAME

			lda	#$ff			;Weitere Einträge in Zeile möglich.
			jmp	:invert_entry		;Ggf. Eintrag invertieren.

;--- Text-Ausgabe.
::20			lda	r1H			;Y-Koordinate für
			clc				;Textausgabe berechnen.
			adc	#$06
			sta	r1H

			ldx	WM_WCODE
			lda	WMODE_VINFO,x		;Detail-Modus aktiv?
			bne	:30			; => Ja, weiter...
			jsr	WM_TEST_ENTRY_X		;Eintrag noch innerhalb der Zeile?
			bcc	:21			; => Ja, weiter...

			ldx	#$00			; => Kein Eintrag ausgegeben.
			rts

::21			lda	r1L			;X-Koordinate für Textausgabe
			pha				;von CARDs nach Pixel wandeln.
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r11L
			ldy	#$03
			jsr	DShiftLeft

			lda	rightMargin +1		;Rechten Rand zwischenspeichern.
			pha				;Wird für InvertEntry benötigt.
			lda	rightMargin +0
			pha

			jsr	WM_GET_GRID_X		;Breite Eintrag ermitteln.
			asl				;Von CARDs nach Pixel wandeln.
			asl
			asl
			clc				;Begrenzung rechter Rand für
			adc	r11L			;Textausgabe berechnen.
			sta	rightMargin +0
			lda	#$00
			adc	r11H
			sta	rightMargin +1

			lda	rightMargin +0		;2 Pixel Abstand zwischen Spalten.
			sec
			sbc	#$02
			sta	rightMargin +0
			bcs	:22
			dec	rightMargin +1

::22			jsr	PrintFName		;Dateiname ausgeben.

			pla				;Rechten Rand zurücksetzen.
			sta	rightMargin +0
			pla
			sta	rightMargin +1

			pla				;X-Koordinate zurücksetzen.
			sta	r1L

			lda	r1H			;Y-Koordinate zurücksetzen.
			sec
			sbc	#$06
			sta	r1H

			jsr	WM_GET_GRID_X
			sta	r2L
			jsr	WM_GET_GRID_Y
			sta	r2H

			lda	#$ff			;Weitere Einträge in Zeile möglich.
			jmp	:invert_entry		;Ggf. Eintrag invertieren.

;--- Text-Ausgabe/Details.
::30			lda	r2L
			pha

			lda	r1L			;X-Koordinate für Textausgabe
			pha				;von CARDs nach Pixel wandeln.
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r11L
			ldy	#$03
			jsr	DShiftLeft

			lda	r11H			;X-Koordinate zwischenspeichern.
			pha
			lda	r11L
			pha

			jsr	PrintFName		;Dateiname ausgeben.

			pla				;X-Koordinate zurücksetzen.
			sta	r11L
			pla
			sta	r11H

			jsr	DrawDetails		;Details zu Datei-Eintrag ausgeben.

			pla				;X-Koordinate zurücksetzen.
			sta	r1L

			lda	r1H			;Y-Koordinate zurücksetzen.
			sec
			sbc	#$06
			sta	r1H

			pla
			sec
			sbc	r1L
			sta	r2L
			jsr	WM_GET_GRID_Y		;Zeiger auf nächste Zeile.
			sta	r2H

			lda	#$7f			;Zeilenende erreicht.

;--- Aktueller Eintrag ausgewählt?
;    Wenn ja, dann Eintrag invertieren.
::invert_entry		pha

			ldy	#$00
			lda	(r15L),y		;Eintrag ausgewählt?
			and	#GD_MODE_MASK
			beq	:43			; => Nein, weiter...

			jsr	WM_CONVERT_CARDS	;Koordinaten nach Pixel wandeln.

			lda	r4H
			cmp	rightMargin +1		;Rechter Rand überschritten?
			bne	:40
			lda	r4L
			cmp	rightMargin +0
::40			bcc	:41			; => Nein, Weiter...

			lda	rightMargin +0		;Fensterbegrenzung setzen.
			sta	r4L
			lda	rightMargin +1
			sta	r4H

::41			lda	r2H
			cmp	windowBottom		;Unterer Rand überschritten?
			bcc	:42			; => Nein, Weiter...

			lda	windowBottom		;Fensterbegrenzung setzen.
			sta	r2H

::42			jsr	InvertRectangle		;Eintrag invertieren.

::43			pla
			tax
			rts

;*** Dateiname kopieren.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
;    Rückgabe: FNameBuf = Dateiname.
:ReadFName		lda	#< FNameBuf		;Zeiger auf Zwischenspeicher.
			sta	r9L
			lda	#> FNameBuf
			sta	r9H

			ldx	#r15L			;Dateiname kopieren.
			ldy	#r9L
			jmp	SysCopyFName

:PrintFName		lda	#< FNameBuf		;Zeiger auf Dateiname.
			sta	r0L
			lda	#> FNameBuf
			sta	r0H

			jmp	smallPutString		;Dateiname ausgeben.

;*** Zeiger auf Datei-Icon setzen.
;    Übergabe: r0  = Eintrag-Nr.
;              r15 = Zeiger auf Verzeichnis-Eintrag.
;    Rückgabe: r0  = Zeiger auf Datei-Icon.
:GetFileIcon_r0		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			beq	:1			; => Nein, weiter...

			ldy	#$02
			lda	(r15L),y		;Typ Datei-Eintrag einlesen.
			and	#%00000111		;Dateityp-Bits isolieren.
			asl
			tay
			lda	:tab +0,y		;Icon für Partitions-/DiskImage-Typ
			sta	r0L			;bzw. Verzeichnis einlesen.
			lda	:tab +1,y
			sta	r0H
			rts

::tab			w Icon_DEL
			w Icon_41_71
			w Icon_41_71
			w Icon_81_NM
			w Icon_81_NM
			w Icon_DEL
			w Icon_Map			;Verzeichnis bei SD2IEC.
			w Icon_DEL

;--- Verzeichnis-Modus.
::1			lda	r1L			;r1L/r1H enthält XPos/YPos.
			pha				;Register r1L/r1H sichern.
			lda	r1H
			pha

			lda	r0L
			sta	r14L
			jsr	SET_POS_CACHE		;Zeiger auf Cache setzen.

			lda	#< diskBlkBuf
			sta	r0L
			lda	#> diskBlkBuf
			sta	r0H

			lda	r14L
			sta	r1L
			lda	r14H
			sta	r1H

			lda	#< 32			;Größe Datei-Eintrag.
			sta	r2L
			lda	#> 32
			sta	r2H

			lda	r12H			;Speicherbank.
			sta	r3L

			jsr	FetchRAM		;Cache-Eintrag einlesen.

			;bit	GD_ICON_PRELOAD		;Alle Icons in Cache laden?
			;bmi	:2			; => Ja, weiter...
			lda	diskBlkBuf +1		;Icon bereits im Cache?
			bne	:3			; => Nein, Icon von Disk laden.

;--- Verzeichnis-Eintrag und Icon aus Cache.
::2			lda	#< fileHeader +4
			sta	r0L
			lda	#> fileHeader +4
			sta	r0H

			lda	r13L
			sta	r1L
			lda	r13H
			sta	r1H

			lda	#< 64			;Größe Datei-Icon.
			sta	r2L
			lda	#> 64
			sta	r2H

			lda	r12L			;Speicherbank.
			sta	r3L

			jsr	FetchRAM		;Cache-Eintrag einlesen.

			lda	#< fileHeader +4	;Zeiger auf Datei-Icon in Puffer.
			ldx	#> fileHeader +4
			bne	:4

;--- Datei-Icon von Disk/Cache laden.
::3			jsr	GetVecFileIcon		;Datei-Icon von Disk laden.

;--- Zeiger auf Datei-Icon setzen, Ende.
::4			sta	r0L			;Zeiger auf Datei-Icon
			stx	r0H			;speichern.

			pla				;Register r1L/r1H zurücksetzen.
			sta	r1H
			pla
			sta	r1L

			rts

;*** Datei-Icon von Disk/aus Cache einlesen.
;    Übergabe: r12L = Cache/Speicherbank Icon-Eintrag.
;              r12H = Cache/Speicherbank Verzeichnis-Eintrag.
;              r13  = Zeiger auf Cache/Icon-Eintrag
;              r14  = Zeiger auf Cache/Verzeichnis-Eintrag.
;              r15  = Zeiger auf Speicher/Verzeichnis-Eintrag.
;    Rückgabe: AKKU/XReg  = Zeiger auf Datei-Icon.
:GetVecFileIcon		ldy	#$02
			lda	(r15L),y		;Dateityp = Gelöscht?
			beq	:1			; => Ja, weiter...
			cmp	#GD_MORE_FILES		;"More files..." ?
			bne	:2			; => Nein, weiter...

			lda	#< Icon_MoreFiles	;Icon "Weitere Dateien".
			ldx	#> Icon_MoreFiles
			rts

::1			lda	#< Icon_DEL		;Icon "Gelöscht".
			ldx	#> Icon_DEL
			rts

::2			and	#ST_FMODES
			cmp	#DIR			;Dateityp = Verzeichnis?
			bne	:4			; => Nein, weiter...
			lda	#< Icon_Map		;Icon "Verzeichnis".
			ldx	#> Icon_Map
			rts

::3			lda	#< Icon_CBM		;Icon "CBM".
			ldx	#> Icon_CBM
			rts

::4			ldy	#$15			;Spur/Sektor Infoblock einlesen.
			lda	(r15L),y		;Infoblock definiert?
			beq	:3			; => Nein, keine GEOS-Datei.
			sta	r1L
			iny
			lda	(r15L),y
			sta	r1H
			lda	#< fileHeader
			sta	r4L
			lda	#> fileHeader
			sta	r4H
			jsr	GetBlock		;Info-Block einlesen.
			txa				;Fehler?
			bne	:3			; => Ja, kein Infoblock => CBM.

			jsr	SaveIcon2Cache		;Icon in Cache speichern.

			lda	#< fileHeader +4	;Zeiger auf Icon in Infoblock.
			ldx	#> fileHeader +4
			rts

;*** Icon in fileHeader in Cache speichern.
;    Übergabe: r12H = Cache/Speicherbank.
;              r13  = Zeiger auf Cache/Icon-Eintrag
;              r14  = Zeiger auf Cache/Verzeichnis-Eintrag.
;              r15  = Zeiger auf Datei-Eintrag/Speicher.
:SaveIcon2Cache		bit	GD_ICON_PRELOAD		;PreLoad-Option aktiv?
			bmi	:1			; => Ja, Ende...
			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bmi	:2			; => Ja, weiter...
::1			rts				;Ende, Icon bereits im Cache.

::2			lda	#< fileHeader +4
			sta	r0L
			lda	#> fileHeader +4
			sta	r0H

			lda	r13L
			sta	r1L
			lda	r13H
			sta	r1H

			lda	#< 64			;Größe Datei-Icon.
			sta	r2L
			lda	#> 64
			sta	r2H

			lda	r12L			;Speicherbank.
			sta	r3L

			jsr	StashRAM		;Datei-Icon in Cache speichern.

			ldy	#$01			;Kennung "Icon im Cache" in
			lda	#GD_MODE_ICACHE		;Verzeichnis-Eintrag setzen.
			sta	(r15L),y		;(Byte#1 = $00)

			lda	r15L			;Zeiger auf Verzeichnis-Eintrag.
			sta	r0L
			lda	r15H
			sta	r0H

			lda	r14L			;Verzeichnis-Eintrag im Cache.
			sta	r1L
			lda	r14H
			sta	r1H

			lda	#< 2			;Nur Byte #0/1 sichern.
			sta	r2L
			lda	#> 2
			sta	r2H

			lda	r12H			;Speicherbank.
			sta	r3L

			jmp	StashRAM		;Verzeichnis-Eintrag sichern.

;*** Textausgabe/Details ausgeben.
:DrawDetails		lda	r11L			;X-Koordinate für Details setzen.
			clc
			adc	#$40
			sta	r11L
			bcc	:add
			inc	r11H
::add

			ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitions-Modus aktiv?
			beq	:1			; => Nein, weiter...

;--- Partitionen/DiskImages.
			jsr	Detail_Size		;Partitionsgröße ausgeben.

			lda	#" "			;Abstandhalter ausgeben.
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen.
			and	#ST_FMODES		;Laufwerksmodus isolieren.
			asl				;Zeiger auf Dateityp/Text setzen.
			tay
			lda	:tab1 +0,y
			sta	r0L
			lda	:tab1 +1,y
			sta	r0H
			jsr	PutString		;Dateityp ausgeben.

			lda	#" "
			jsr	SmallPutChar
			lda	#"/"
			jsr	SmallPutChar

			ldy	#$03
			lda	(r15L),y		;Dateityp einlesen.
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jmp	PutDecimal		;Partitions-Nr. ausgeben.

::tab1			w :t0
			w :t1
			w :t2
			w :t3
			w :t4
			w :t0
			w :t6
			w :t0

if LANG = LANG_DE
::t0			b "?",NULL
::t1			b "1541",NULL
::t2			b "1571",NULL
::t3			b "1581",NULL
::t4			b "Native",NULL
::t6			b "Verzeichnis",NULL
endif
if LANG = LANG_EN
::t0			b "?",NULL
::t1			b "1541",NULL
::t2			b "1571",NULL
::t3			b "1581",NULL
::t4			b "Native",NULL
::t6			b "Directory",NULL
endif

;--- Standard-Datei-Modus.
::1			jsr	chkDateTime		;Auf gültiges Datum/Uhrzeit testen.

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen.
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien"?
			beq	:3			; => Ja, Ausgabe beenden.

			lda	#$00			;Zeiger für Spalten auf Anfang.
::2			pha
			jsr	nextColumn		;X-Position auf nächste Spalte.
			pla

			ldy	r11H			;X-Position für Textausgabe
			cpy	rightMargin +1		;noch innerhalb des Fensters?
			bne	:compare
			ldy	r11L
			cpy	rightMargin +0
::compare		bcs	:3			; => Nein, Ende...

			pha
			asl				;Zeiger auf Routine zur Detail-
			tay				;Ausgabe berechnen.
			lda	:columnData +0,y
			ldx	:columnData +1,y
			jsr	CallRoutine		;Detail-Informationen ausgeben.

			pla
			clc
			adc	#$01
			cmp	#$05			;Alle Details ausgegeben?
			bcc	:2			; => Nein, weiter...
::3			rts

;--- Hinweis:
;Wenn die Reihenfolge geändert wird ist
;ggf. für CType das setzen der nächsten
;XPos wieder zu aktivieren.
; => ":nextInfoCType" / ":Detail_CType"
::columnData		w Detail_Size			;Datei/Größe.
			w Detail_Date			;Datei/Datum.
			w Detail_Time			;Datei/Uhrzeit.
			w Detail_GType			;GEOS-Dateityp.
			w Detail_CType			;Commodore-Dateityp.

;*** X-Position auf nächste Position setzen.
;    Übergabe: AKKU = Spaltenbreite.
;              XREG/YREG = Aktuelle X-Position.
:nextColumn		lda	#6			;Spaltenabstand.
			b $2c
:skipPrntDate		lda	#3*11			;Datum überspringen.
			b $2c
:skipPrntTime		lda	#2*11			;Uhrzeit überspringen.

			ldx	r11L
			ldy	r11H
			bpl	setNewXPos

:nextNumPos		lda	#1*11			;Zeiger auf nächste Zahlenposition.
			b $2c
:nextInfoGType		lda	#$50			;GEOS-Dateityp.

;--- Hinweis:
;Nach Spalte CType erfolgt keine
;weitere Datenausgabe mehr: Am C64 ist
;hier das Fensterende bereits erreicht.
if FALSE
			b $2c
:nextInfoCType		lda	#$18			;CBM-Dateityp.
endif

:setNewXPos		sta	r11L
			txa
			clc
			adc	r11L
			sta	r11L
			tya
			adc	#$00
			sta	r11H
			rts

;*** Dateigröße ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_Size		ldy	#$1e			;Anzahl Blocks einlesen.
			lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H

			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Anzeige in KBytes?
			beq	:1			; => Nein, weiter...

			lda	r0L
			pha
			ldx	#r0L
			ldy	#$02
			jsr	DShiftRight		;Blocks in KBytes umrechnen.
			pla
			and	#%00000011		;Auf volle KByte aufrunden?
			beq	:1			; => Bereits volle KByte, weiter...

			inc	r0L			;Anzahl KBytes +1.
			bne	:1			;Sonst 0-2 Blocks = 0Kbyte.
			inc	r0H

::1			lda	#$20 ! SET_RIGHTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Breite für Größenausgabe.

			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Anzeige in KBytes?
			beq	:2			; => Nein, weiter...
			lda	#"K"
			jsr	SmallPutChar		;"K"byte-Suffix ausgeben.

::2			rts

;*** Dateidatum ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_Date		bit	validDate		;Datum/Uhrzeit gültig?
			bpl	:1			; => Ja, weiter...

			jmp	skipPrntDate		;Fehlerhaftes Datum überspringen.

;--- Datum OK.
::1			ldy	#$1b
			lda	(r15L),y		;Tag.
			tax
			ldy	#"."
			jsr	Detail_Num

			ldy	#$1a
			lda	(r15L),y		;Monat.
			tax
			ldy	#"."
			jsr	Detail_Num

			ldy	#$19
			lda	(r15L),y		;Jahr.
			tax
			ldy	#" "
			jmp	Detail_Num

;*** Dateizeit ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_Time		bit	validDate		;Datum/Uhrzeit gültig?
			bpl	:1			; => Ja, weiter...

			jmp	skipPrntTime		;Fehlerhafte Zeit überspringen.

;--- Uhrzeit OK.
::1			ldy	#$1c
			lda	(r15L),y		;Stunde.
			tax
			ldy	#":"
			jsr	Detail_Num

			ldy	#$1d
			lda	(r15L),y		;Minute.
			tax
			ldy	#" "
			jmp	Detail_Num

;*** Auf gültiges Datum/Uhrzeit testen.
:chkDateTime		ldx	#$ff			;Datum/Uhrzeit ungültig.

			ldy	#25
			lda	(r15L),y		;Jahr.
			beq	:1
			cmp	#99 +1			;Jahr =< 99?
			bcs	:1			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Monat.
			beq	:1
			cmp	#12 +1			;Monat =< 12?
			bcs	:1			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Tag.
			beq	:1
			cmp	#31 +1			;Tag =< 31?
			bcs	:1			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Stunde.
			cmp	#24			;Stunde < 24?
			bcs	:1			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Minute.
			cmp	#60			;Minute < 60?
			bcs	:1			; => Nein, Fehler...

			inx				;Datum/Uhrzeit gültig.
::1			stx	validDate
			rts

;*** Zweistellige Zahl ausgeben.
;    Für Datum/Uhrzeit.
;    Übergabe: XReg = Zahl.
;              YReg = Zahlentrenner, z.B. "."(Datum) oder ":"(Zeit).
:Detail_Num		lda	r11H			;X-Koordinate sichern.
			pha
			lda	r11L
			pha

			tya				;Zahlentrenner sichern.
			pha

			txa
			jsr	DEZ2ASCII		;Zahl nach ASCII wandeln.
			pha				;LOW-Nibble sichern.
			txa
			jsr	SmallPutChar		;10er ausgeben.
			pla
			jsr	SmallPutChar		;1er ausgeben.

			pla
			jsr	SmallPutChar		;Zahlentrenner ausgeben.

			pla				;X-Koordinate auf nächste
			tax				;Position setzen.
			pla
			tay
			jmp	nextNumPos

;*** GEOS-Dateityp ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_GType		lda	r11H			;X-Koordinate sichern.
			pha
			lda	r11L
			pha

			jsr	GetGeosType		;Zeiger auf Text für
			sta	r0L			;GEOS-Dateityp einlesen.
			sty	r0H
			jsr	PutString		;GEOS-Dateityp ausgeben.

			pla				;X-Koordinate auf nächste
			tax				;Position setzen.
			pla
			tay
			jmp	nextInfoGType

;*** CBM-Dateityp ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_CType

;--- Hinweis:
;Nach Spalte CType erfolgt keine
;weitere Datenausgabe mehr: Am C64 ist
;hier das Fensterende bereits erreicht.
if FALSE
			lda	r11H			;X-Koordinate sichern.
			pha
			lda	r11L
			pha
endif

			ldy	#$02
			lda	(r15L),y		;CBM-Dateityp einlesen.
			pha
			and	#ST_FMODES		;Datei-Typ isolieren.
			asl
			asl

			clc				;Zeiger auf CBM-Dateityp
			adc	#< cbmFType		;berechnen und Dateityp ausgeben.
			sta	r0L
			lda	#$00
			adc	#> cbmFType
			sta	r0H
			jsr	PutString

			pla
			pha				;Datei "geöffnet" ?
			bmi	:3			; => Nein, weiter...
			lda	#"*"
			jsr	SmallPutChar		;"Datei geöffnet"-Kennung.

::3			pla
			and	#%01000000		;Datei schreibgeschützt?
			beq	:4			; => Nein, weiter...
			lda	#"<"
			jsr	SmallPutChar		;"Datei schreibgeschützt"-Kennung.

::4			rts

;--- Hinweis:
;Nach Spalte CType erfolgt keine
;weitere Datenausgabe mehr: Am C64 ist
;hier das Fensterende bereits erreicht.
if FALSE
::4			pla				;X-Koordinate auf nächste
			tax				;Position setzen.
			pla
			tay
			jmp	nextInfoCType
endif

;*** Variablen.
:FNameBuf		s 17				;Puffer für Dateiname.
:validDate		b $00				;$00 = Datum/Zeit OK.

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Desktop-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
