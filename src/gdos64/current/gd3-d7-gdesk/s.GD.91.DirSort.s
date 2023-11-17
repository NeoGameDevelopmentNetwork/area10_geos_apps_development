; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Verzeichnis sortieren.
;* Zwei Dateien im Verzeichnis tauschen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "SymbTab_KEYS"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Fenstergröße für Registermenü.
:R1SizeY0 = $08
:R1SizeY1 = $b7
:R1SizeX0 = $0000
:R1SizeX1 = $013f

;--- Sortier-Modi:
;Sortieren von Dateien mit 64Kb
;GEOS-DACC Speicher verwenden.
:SORTMODE64K = TRUE

;Erweiterte Datei-Informationen
;bei Auwahl einer Datei anzeigen.
:SORTFINFO = TRUE
endif

;*** GEOS-Header.
			n "obj.GD91"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSORTDIR
			jmp	xSWAP2FPOS

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** SortInfo-Modus definieren.
if SORTFINFO = FALSE
:SORTINFO_MODE = 0
endif
if SORTFINFO = TRUE
:SORTINFO_MODE = 1
endif

;*** Benötigter Speicher für SORTFINFO.
;Zahl muss durch 16 teilbar sein!
:SORTFINFO_SIZE = $0160 * SORTINFO_MODE

;*** Anzahl zusätzlicher Registermenü-Einträge.
:SORTFINFO_ENTRIES = SORTINFO_MODE * 3

;*** RAM-Sortierung.
if SORTMODE64K = FALSE
:SORT64K_ENTRIES = 0
			t "-G91_DSortRAM"

;--- Speicherbelegung (ohne Datei-Info):
;Max. 28Sek/224 Dateien.
;$0000-$03FF: GEOS-System
;$0400-$1D5B: GeoDesk Core
;$1D5C-$2EAC: GeoDesk/DirSort
;$2EAD-$4CFF: Frei
;$4D00-$4DFF: FLIST_SOURCE
;$4E00-$4EFF: FSLCT_SOURCE
;$4F00-$4FFF: FLIST_TARGET
;$5000-$50FF: FSLCT_TARGET
;$5100-$6CFF: DIRSEK_SOURCE
;$6D00-$78FF: Register-Menü
;$7900-$7F3F: Druckertreiber
;$7F40-$7FFF: Application data
;$8000-$FFFF: GEOS-System

;--- Speicherbelegung (mit Datei-Info):
;Max. 26Sek/208 Dateien.
;$0000-$03FF: GEOS-System
;$0400-$1D5B: GeoDesk Core
;$1D5C-$2FFE: GeoDesk/DirSort
;$2FFF-$4EFF: Frei
;$4F00-$4FFF: FLIST_SOURCE
;$5000-$50FF: FSLCT_SOURCE
;$5100-$51FF: FLIST_TARGET
;$5200-$52FF: FSLCT_TARGET
;$5300-$6CFF: DIRSEK_SOURCE
;$6D00-$78FF: Register-Menü
;$7900-$7F3F: Druckertreiber
;$7F40-$7FFF: Application data
;$8000-$FFFF: GEOS-System

;--- Max. Speicherbelegung:
;Max. 31 Sektoren/248 Dateien.
;$0000-$03FF: GEOS-System
;$0400-$1D5B: GeoDesk Core
;$1D5C-$2FFE: GeoDesk/DirSort
;$2FFF-$49FF: Frei
;$4A00-$4AFF: FLIST_SOURCE
;$4B00-$4BFF: FSLCT_SOURCE
;$4C00-$4CFF: FLIST_TARGET
;$4D00-$4DFF: FSLCT_TARGET
;$4E00-$6CFF: DIRSEK_SOURCE
;$6D00-$78FF: Register-Menü
;$7900-$7F3F: Druckertreiber
;$7F40-$7FFF: Application data
;$8000-$FFFF: GEOS-System

;--- Startadresse Dateinamen.
;Max. 28Sek/224 Dateien ohne Datei-Info.
;Max. 26Sek/208 Dateien mit Datei-Info.
;--- Hinweis:
;Max. Speicher nach Variante mit oder
;ohne Datei-Info berechnen.
;:MaxReadSek		= 28 - ((SORTFINFO_SIZE + 255) / 256)
;--- Hinweis:
;Aktuell steht ausreichend Speicher für
;beide Varianten zur Verfügung.
;Max. 31Sek/248 Dateien.
:MaxReadSek		= 31
:MaxSortFiles		= MaxReadSek  *8
:DIRSEK_SOURCE		= RegMenuBase - (MaxReadSek * 256)
;--- Hinweis:
;Für diese Datenbereiche könnte auch
;$7900-$7FFF verwendet werden.
:FSLCT_TARGET		= DIRSEK_SOURCE - 256
:FLIST_TARGET		= FSLCT_TARGET  - 256
:FSLCT_SOURCE		= FLIST_TARGET  - 256
:FLIST_SOURCE		= FSLCT_SOURCE  - 256
:END_APP_RAM		= FLIST_SOURCE
;END_APP_RAM		= DIRSEK_SOURCE
endif

;*** DACC-Sortierung.
if SORTMODE64K = TRUE
:SORT64K_ENTRIES = 1
			t "-G91_DSortDACC"

;--- Speicherverwaltung.
			t "-DA_FindBank"
			t "-DA_FreeBank"
			t "-DA_AllocBank"
			t "-DA_GetBankByte"

;--- Speicherbelegung (ohne Datei-Info):
;Max. 226Sek/1808 Dateien.
;$0000-$03FF: GEOS-System
;$0400-$1D5B: GeoDesk Core
;$1D5C-$3354: GeoDesk/DirSort
;$3355-$50BF: Frei
;$50C0-$5EDF: FLIST_SOURCE
;$5EE0-$6CFF: FLIST_TARGET
;$6D00-$78FF: Register-Menü
;$7900-$7F3F: Druckertreiber
;$7F40-$7FFF: Application data
;$8000-$80FF: DIRSEK_SOURCE
;$8100-$FFFF: GEOS-System

;--- Speicherbelegung (mit Datei-Info):
;Max. 210Sek/1680 Dateien.
;$0000-$03FF: GEOS-System
;$0400-$1D5B: GeoDesk Core
;$1D5C-$34A6: GeoDesk/DirSort
;$34A7-$52BF: Frei
;$52C0-$5FDF: FLIST_SOURCE
;$5FE0-$6CFF: FLIST_TARGET
;$6D00-$78FF: Register-Menü
;$7900-$7F3F: Druckertreiber
;$7F40-$7FFF: Application data
;$8000-$80FF: DIRSEK_SOURCE
;$8100-$FFFF: GEOS-System

;--- Max. Speicherbelegung:
;Max. 255Sek/2039 Dateien.
;$0000-$03FF: GEOS-System
;$0400-$1D5B: GeoDesk Core
;$1D5C-$34A6: GeoDesk/DirSort
;$34A7-$4D1F: Frei
;$4D20-$5D0F: FLIST_SOURCE
;$5D10-$6CFF: FLIST_TARGET
;$6D00-$78FF: Register-Menü
;$7900-$7F3F: Druckertreiber
;$7F40-$7FFF: Application data
;$8000-$80FF: DIRSEK_SOURCE
;$8100-$FFFF: GEOS-System

;--- Startadresse Dateinummern.
;Bit %0-%10 = Dateinummer 0-2047.
;Bit %15    = 1 / Datei markiert.
;--- Hinweis:
;Max. Speicher nach Variante mit oder
;ohne Datei-Info berechnen.
;Max. 226Sek/1808 Dateien ohne Datei-Info.
;Max. 210Sek/1680 Dateien mit Datei-Info.
;:MaxReadSek		= 226 - ((SORTFINFO_SIZE + 255) / 256) *8
;--- Hinweis:
;Aktuell steht ausreichend Speicher für
;beide Varianten zur Verfügung.
;Max. 255Sek/2039 Dateien.
:MaxReadSek		= 255
:MaxSortFiles		= MaxReadSek  *8
:DIRSEK_SOURCE		= diskBlkBuf
:FLIST_TARGET		= RegMenuBase - MaxSortFiles*2
:FLIST_SOURCE		= FLIST_TARGET     - MaxSortFiles*2
:END_APP_RAM		= FLIST_SOURCE
endif

;*** Dateien tauschen.
;Dabei werden zwei markierte Dateien im
;Verzeichnis gegeneinander getauscht.
:xSWAP2FPOS		LoadW	r15,BASE_DIRDATA	;Zeiger auf Anfang Verzeichnis.

			lda	#$00			;Dateizähler zurücksetzen.
			sta	r3L

			sta	fileName1		;Dateiname #1 und #2 löschen.
			sta	fileName2

			LoadW	r4,fileName1
			jsr	getFileName		;Erste markierte Datei suchen.
			lda	fileName1		;Datei gefunden?
			beq	:exit			; => Nein, Ende...

			LoadW	r4,fileName2
			jsr	getNextFile		;Zweite markierte Datei suchen.
			lda	fileName2		;Datei gefunden?
			beq	:exit			; => Nein, Ende...

			jsr	swap2FPos		;Einträge tauschen.

;--- Ergänzung: 17.08.21/M.Kanet
;Fehlerstatus abfragen und auswerten.
			txa				;Diskettenfehler ?
			beq	:update

			pha				;Fehlercode zwischenspeichern.
			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			pla				;Fehlercode wieder einlesen.
			cmp	#WR_PR_ON		;Schreibschutz aktiv ?
			beq	:exit			; => Ja, weiter...
;---

::update		jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::exit			jmp	MOD_UPDATE		;Zurück zum FensterManager.

;*** Markierte Datei suchen.
:getFileName		ldy	#$00
			lda	(r15L),y		;Datei ausgewählt?
			and	#GD_MODE_MASK
			beq	getNextFile		; => Nein, weiter...

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen.
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien"?
			beq	getNextFile		; => Ja, ignorieren.

			lda	r15L			;Zeiger auf Dateiname in
			clc				;Verzeichnis-Eintrag berechnen.
			adc	#$05
			sta	r5L
			lda	r15H
			adc	#$00
			sta	r5H

			ldx	#r5L
			ldy	#r4L
			jmp	SysCopyName		;Dateiname kopieren.

:getNextFile		AddVBW	32,r15			;Zeiger auf nächsten Eintrag.

			inc	r3L			;Datei-Zähler +1.
::1			lda	r3L
			cmp	fileEntryCount
::2			bcc	getFileName		; => Weiter mit nächster Datei.
			rts

;*** Dateieinträge tauschen.
:swap2FPos		LoadW	r6,fileName1
			jsr	FindFile		;Erste Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			MoveB	r1L,r11L		;Track/Sektor/Position des
			MoveB	r1H,r11H		;Verzeichnis-Eintrages sichern.
			MoveW	r5,r15

			ldy	#$00			;Verzeichnis-Eintrag
::1			lda	(r5L),y			;zwischenspeichern.
			sta	fileHeader,y
			iny
			cpy	#30
			bcc	:1

			LoadW	r6,fileName2
			jsr	FindFile		;Erste Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$00			;Verzeichnis-Eintrag von
::2			lda	(r5L),y			;Datei #2 mit Datei #1 tauschen.
			pha
			lda	fileHeader,y
			sta	(r5L),y
			pla
			sta	fileHeader,y
			iny
			cpy	#30
			bcc	:2

			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Sektor speichern.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			MoveB	r11L,r1L		;Track/Sektor/Position für erste
			MoveB	r11H,r1H		;Datei wieder herstellen.
			MoveW	r15,r5

			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$00			;Verzeichnis-Eintrag Datei #2
::3			lda	fileHeader,y		;an die Stelle von Datei #1
			sta	(r5L),y			;kopieren.
			iny
			cpy	#30
			bcc	:3

			jsr	PutBlock		;Verzeichnis-Sektor speichern.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- NativeMode-Verzeichnisse korrigieren.
			lda	curType			;Laufwerkstyp einlesen.
			and	#ST_DMODES
			cmp	#DrvNative		;NativeMode ?
			bne	:exit			; => Nein, weiter...

			jsr	VerifyNMDir		;Verzeichnis-Header korrigieren.
::exit			rts

;*** Zwischenspeicher für Dateinamen.
:fileName1		s 17
:fileName2		s 17

;*** Unterverzeichnis-Header überprüfen.
;Version #1: Prüft nur das aktuelle Unterverzeichnis.
:VerifyNMDir		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			LoadW	r4,diskBlkBuf

			lda	curDirHead +0		;Zeiger auf ersten vVerzeichnis-
			ldx	curDirHead +1		;Sektor einlesen.

;--- Verzeichnis-Sektoren einlesen.
::1			sta	r1L			;Verzeichnis-Sektor setzen.
			stx	r1H
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler?
			beq	:2			; => Nein, weiter...
::exit_io		jsr	DoneWithIO		;I/O-Bereich ausblenden.
::exit			rts				;Diskettenfehler ausgeben.

;--- Verzeichnis-Einträge überprüfen.
::2			ldy	#$02
			lda	(r4L),y			;Dateityp einlesen.
			beq	:3			; => $00, keine Datei.
			and	#ST_FMODES
			cmp	#DIR			;Typ "Verzeichnis"?
			bne	:3			; => Nein, weiter...

			jsr	UpdateHeader		;Verzeichnis-Header aktualisieren.
			txa				;Diskettenfehler?
			bne	:exit_io		; => Ja, Abbruch...

::3			clc				;Zeiger auf nächsten Eintrag.
			lda	r4L
			adc	#$20
			sta	r4L			;Sektor-Ende erreicht?
			bne	:2			; => Nein, weiter...

			ldx	diskBlkBuf +1		;Zeiger auf nächsten Sektor einlesen.
			lda	diskBlkBuf +0		;Letzter Verzeichnis-Sektor?
			bne	:1			; => Nein, weiter...

			ldx	#NO_ERROR
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Verzeichnis-Header einlesen und anpassen.
:UpdateHeader		MoveB	r1L,r11L		;Zeiger auf aktuellen
			MoveB	r1H,r11H		;Verzeichnis-Eintrag sichern.
			MoveB	r4L,r14L
			MoveB	r4H,r14H

			ldy	#$03
			lda	(r4L),y			;Track/Sektor für neuen
			sta	r1L			;Verzeichnis-Header setzen.
			iny
			lda	(r4L),y
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
			jsr	ReadBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:1			; => Ja, Abbruch...

			lda	r11L			;Zeiger auf zugehörigen Eltern-
			sta	fileHeader +36		;Verzeichnis-Sektor in Header
			lda	r11H			;übertragen.
			sta	fileHeader +37
			lda	r14L			;Zeiger auf Verzeichnis-Eintrag
			clc				;in Header übertragen.
			adc	#$02			;(Byte zeigt auf Byte#0=Dateityp).
			sta	fileHeader +38

			jsr	WriteBlock		;Verzeichnis-Header schreiben.
			txa
			bne	:1

			MoveB	r11L,r1L		;Zeiger auf aktuellen
			MoveB	r11H,r1H		;Verzeichnis-Eintrag zurücksetzen.
			MoveB	r14L,r4L
			MoveB	r14H,r4H

::1			rts

;
; Funktion     : Auswahltabelle
; Datum        : 15.08.20 / Änderung auf 16Bit-Werte.
; Aufruf       : JSR  InitScrBar16
; Übergabe     : r0 = Zeiger auf Datentabelle.
;                b    Zeiger auf xPos (in CARDS!)
;                b    Zeiger auf yPos (in PIXEL!)
;                b    max. Länge des Balken (in PIXEL!)
;                b    max. Einträge auf einer Seite.
;                w    max. Anzahl Einträge in Tabelle.
;                w    Tabellenzeiger = Nr. der ersten Datei auf der Seite!
;
;'InitScrBar16'  Muß als erstes aufgerufen werden um die Daten (r0-r2) für
;                den Anzeigebalken zu definieren und den Balken auf dem
;                Bildschirm auszugeben.
;'SetNewPos16'   Setzt den Füllbalken auf neue Position. Dazu muß im AKKU die
;                neue Position des Tabellenzeigers übergeben werden.
;'PrntScrBar16'   Zeichnet den Anzeige- und Füllbalken erneut. Dazu muß aber
;                vorher mindestens 1x 'InitBalken' aufgerufen worden sein!
;'ReadSB_Data'   Übergibt folgende Werte an die aufrufende Routine:
;                r0L = SB_XPos        Byte  X-Position Balken in CARDS.
;                r0H = SB_YPos        Byte  Y-Position in Pixel.
;                r1L = SB_MaxYlen     Byte  Länge des Balkens.
;                r1H = SB_MaxEScr     Byte  Anzahl Einträge auf Seite.
;                r2  = SB_MaxEntry16  Word  Anzahl Einträge in Tabelle.
;                r3  = SB_PosEntry16  Word  Aktuelle Position in Tabelle.
;                r4  = SB_PosTop      Word  Startadresse im Grafikspeicher.
;                r5L = SB_Top         Byte  Oberkante Füllbalken.
;                r5H = SB_End         Byte  Unterkante Füllbalken.
;                r6L = SB_Length      Byte  Länge Füllbalken.
;'IsMseOnPos'    Mausklick auf Anzeigebalken auswerten. Ergebnis im AKKU:
;                $01 = Mausklick Oberhalb Füllbalken.
;                $02 = Mausklick auf Füllbalken.
;                $03 = Mausklick Unterhalb Füllbalken.
;'StopMouseMove' Schränkt Mausbewegung ein.
;'SetRelMouse'   Setzt neue Mausposition. Wird beim Verschieben des
;                Füllbalkens benötigt. Vorher muß ein 'JSR SetNewPos16'
;                erfolgen!
;

;*** Balken initialiseren.
:InitScrBar16		ldy	#8 -1			;Parameter speichern.
::1			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:1

			jsr	Anzeige_Ypos		;Position Anzeigebalkens berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.

			lda	SB_XPos
			sta	:colData +0

			lda	SB_YPos			;Position für "UP"-Icon berechnen.
			lsr
			lsr
			lsr
			sta	:colData +1

			lda	SB_MaxYlen
			lsr
			lsr
			lsr
			sta	:colData +3

			lda	#$01
			jsr	i_UserColor
::colData		b	$00,$00,$01,$00

			jmp	PrntScrBar16		;Balken ausgeben.

;*** Neue Balkenposition defnieren und anzeigen.
:SetNewPos16		sta	SB_PosEntry16 +0	;Neue Position Füllbalken setzen.
			sty	SB_PosEntry16 +1

;*** Balken ausgeben.
:PrntScrBar16		jsr	Balken_Ypos		;Y-Position Füllbalken berechnen.

			MoveW	SB_PosTop,r0		;Grafikposition berechnen.
			ClrB	r1L			;Zähler für Balkenlänge löschen.

			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::1			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:4			;Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.
			bcc	:4			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:3			;Ja, Quer-Linie ausgeben.
			bcs	:4			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:4			;Ja, Quer-Linie ausgeben.

::2			lda	#%10000000		;Wert für Füllbalken.
			b $2c
::3			lda	#%11111111
			b $2c
::4			lda	#%11111111
::5			sta	(r0L),y			;Byte in Grafikspeicher schreiben.
			inc	r1L
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:6			;Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:1			;Nein, weiter...

			AddVW	SCRN_XBYTES,r0		;Zeiger auf nächstes CARD berechnen.
			ldy	#$00
			beq	:1			;Schleife...
::6			rts				;Ende.

;*** Position des Anzeigebalken berechnen.
:Anzeige_Ypos		MoveB	SB_XPos,r0L		;Zeiger auf X_CARD berechnen.
			LoadB	r0H,NULL
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	SCREEN_BASE,r0		;Zeiger auf Grafikspeicher.

			lda	SB_YPos			;Zeiger auf Y-Position
			lsr				;berechnen.
			lsr
			lsr
			tay
			beq	:2
::1			AddVW	40*8,r0
			dey
			bne	:1
::2			MoveW	r0,SB_PosTop		;Grafikspeicher-Adresse merken.
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	#$00
			ldx	SB_MaxEntry16 +1	;Mehr als 255 Einträge?
			bne	:1			; => Ja, Balken immer möglich.
			ldx	SB_MaxEScr
			cpx	SB_MaxEntry16 +0	;Balken möglich?
			bcs	:2			; => Nein, weiter...

::1			MoveB	SB_MaxYlen,r0L		;Länge Balken berechnen.
			MoveB	SB_MaxEScr,r1L
			ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jsr	BBMult

			MoveW	SB_MaxEntry16,r1
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L
			cmp	#8			;Balken kleiner 8 Pixel?
			bcs	:2			; => Nein, weiter...
			lda	#$08			;Mindestgröße für Balken.
::2			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		lda	SB_MaxEntry16 +1	;Mehr als 255 Einträge?
			bne	:1			; => Balken immer erforderlich.

			ldx	#NULL
			ldy	SB_Length

			lda	SB_MaxEScr
			cmp	SB_MaxEntry16 +0	;Balken möglich?
			bcs	:2			; => Nein, weiter...

::1			MoveW	SB_PosEntry16,r0

			lda	SB_MaxYlen
			sec
			sbc	SB_Length
			sta	r1L
			lda	#$00
			sta	r1H

			ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jsr	BMult

			lda	SB_MaxEntry16 +0
			sec
			sbc	SB_MaxEScr
			sta	r1L
			lda	SB_MaxEntry16 +1
			sbc	#$00
			sta	r1H

			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L
			tax
			clc
			adc	SB_Length
			tay
::3			cpy	SB_MaxYlen
			beq	:2
			bcc	:2
			dey
			dex
			bne	:3
::2			stx	SB_Top
			dey
			sty	SB_End
			rts

;*** Daten für Scrollbalken übergeben.
;Hinweis:
;Wurde von GeoDOS übernommen und wird
;wird in GeoDesk nicht verwendet.
;:ReadSB_Data		ldx	#13 -1
;::1			lda	SB_XPos,x
;			sta	r0L,x
;			dex
;			bpl	:1
;			rts

;*** Mausklick überprüfen.
:IsMseOnPos		lda	mouseYPos
			sec
			sbc	SB_YPos
			cmp	SB_Top
			bcc	:3
::1			cmp	SB_End
			bcc	:2
			lda	#$03
			b $2c
::2			lda	#$02
			b $2c
::3			lda	#$01
			rts

;*** Mausbewegung kontrollieren.
:StopMouseMove		lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1
			lda	mouseYPos
			jmp	SetNewRelMse

:SetRelMouse		lda	#$ff
			clc
			adc	SB_Top
:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			sec
			sbc	SB_Top
			sta	SetRelMouse+1
			rts

;*** Variablen für Scrollbalken.
:SB_XPos		b $00				;r0L
:SB_YPos		b $00				;r0H
:SB_MaxYlen		b $00				;r1L
:SB_MaxEScr		b $00				;r1H
:SB_MaxEntry16		w $0000				;r2
:SB_PosEntry16		w $0000				;r3

:SB_PosTop		w $0000				;r4
:SB_Top			b $00				;r5L
:SB_End			b $00				;r5H
:SB_Length		b $00				;r6L

;*** Verzeichnis sortieren.
:xSORTDIR		php				;Mausrad-Unterstütung aktivieren?
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	$d419
			cmp	$d41a
			bne	:mouse
			eor	#%11111111
			bne	:mouse

::joystick		lda	#FALSE			; => Nein, Joystick...
			b $2c
::mouse			lda	#TRUE			; => Ja, Maus...

			stx	CPU_DATA
			plp

			sta	Flag_MWheel

if SORTMODE64K  = TRUE
			jsr	DACC_FIND_BANK		;64K für DACC-Sortieren suchen.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			tya
			sta	sort64Kbank		;Speicherbank merken.
			ldx	#%01000000		;Bank-Typ: Anwendung.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.
			jmp	:readFiles		; => Weiter...

::noram			LoadW	r0,Dlg_NoFreeRAM	; => Kein freier Speicher.
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	ExitRegMenuUser		;Zurück zum DeskTop.

::readFiles		jsr	Read64kDir		;Dateien in DACC einlesen.
endif

if SORTMODE64K  = FALSE
::readFiles		jsr	Read224Dir		;Dateien in RAM einlesen.
endif

;--- Dateien eingelesen, Fortsetzung.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

if SORTMODE64K  = TRUE
			lda	SortS_MaxH		;Max. Anzahl Dateien einlesen.
			bne	:1
			lda	SortS_Max
			cmp	#2			;Nichts zum sortieren?
			bcc	exitDirSort		; => Ja, Ende...
::1
endif

if SORTMODE64K  = FALSE
			lda	SortS_Max		;Max. Anzahlk Dateien einlesen.
			cmp	#2			;Nichts zum sortieren?
			bcc	exitDirSort		; => Ja, Ende...
endif

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;--- Laufwerksfehler.
::error			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

if SORTMODE64K  = TRUE
			lda	sort64Kbank		;Speicher für DACC-Sortierung
			beq	:1			;freigeben.
			jsr	DACC_FREE_BANK
::1
endif

			bit	reloadDir		;Verzeichnis aktualisieren?
			bpl	exitDirSort		; => Nein, Ende...

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
:exitDirSort		jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Verzeichnis schreiben" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	jsr	S_SetAll
			jsr	TakeSource

if SORTMODE64K  = FALSE
			jsr	Write224Dir		;Verzeichnis aktualisieren.
endif

if SORTMODE64K  = TRUE
			jsr	Write64kDir		;Verzeichnis aktualisieren.
endif

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.
			beq	:1			; => Kein Fehler, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

			lda	#$00			;Verzeichnis nicht aktualisieren.
			b $2c
::1			lda	#$ff			;Verzeichnis aktualisieren.
			sta	reloadDir

			ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;*** Register-Menü.
:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "DIRSORT".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons.
:RIcon_MoveUp		w Icon_MoveUp
			b %01000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MoveUp_x,Icon_MoveUp_y
			b USE_COLOR_INPUT

:Icon_MoveUp
<MISSING_IMAGE_DATA>

:Icon_MoveUp_x		= .x
:Icon_MoveUp_y		= .y

:RIcon_MoveDown		w Icon_MoveDown
			b %01000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MoveDown_x,Icon_MoveDown_y
			b USE_COLOR_INPUT

:Icon_MoveDown
<MISSING_IMAGE_DATA>

:Icon_MoveDown_x	= .x
:Icon_MoveDown_y	= .y

:RIcon_FileAdd		w Icon_FileAdd
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FileAdd_x,Icon_FileAdd_y
			b USE_COLOR_INPUT

:Icon_FileAdd
<MISSING_IMAGE_DATA>

:Icon_FileAdd_x		= .x
:Icon_FileAdd_y		= .y

:RIcon_FRemove		w Icon_FRemove
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FRemove_x,Icon_FRemove_y
			b USE_COLOR_INPUT

:Icon_FRemove
<MISSING_IMAGE_DATA>

:Icon_FRemove_x		= .x
:Icon_FRemove_y		= .y

:RIcon_PSelect		w Icon_PSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_PSelect_x,Icon_PSelect_y
			b USE_COLOR_INPUT

:Icon_PSelect
<MISSING_IMAGE_DATA>

:Icon_PSelect_x		= .x
:Icon_PSelect_y		= .y

:RIcon_FSelect		w Icon_FSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FSelect_x,Icon_FSelect_y
			b USE_COLOR_INPUT

:Icon_FSelect
<MISSING_IMAGE_DATA>

:Icon_FSelect_x		= .x
:Icon_FSelect_y		= .y

:RIcon_FUnSlct		w Icon_FUnSlct
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FUnSlct_x,Icon_FUnSlct_y
			b USE_COLOR_INPUT

:Icon_FUnSlct
<MISSING_IMAGE_DATA>

:Icon_FUnSlct_x		= .x
:Icon_FUnSlct_y		= .y

:RIcon_FReset		w Icon_FReset
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FReset_x,Icon_FReset_y
			b USE_COLOR_INPUT

:Icon_FReset
<MISSING_IMAGE_DATA>

:Icon_FReset_x		= .x
:Icon_FReset_y		= .y

:RIcon_FWrite		w Icon_FWrite
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FWrite_x,Icon_FWrite_y
			b USE_COLOR_INPUT

:Icon_FWrite
<MISSING_IMAGE_DATA>

:Icon_FWrite_x		= .x
:Icon_FWrite_y		= .y

;*** Daten für Register "DIRSORT".
:RegTMenu1		b (22 + SORT64K_ENTRIES + SORTFINFO_ENTRIES)

;--- Source.
::1			b BOX_USER
				w $0000
				w SlctSource
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX0 +$08
				w R1SizeX0 +$a0 -$10 -$01
::2			b BOX_USEROPT_VIEW
				w $0000
				w $0000
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX0 +$08
				w R1SizeX0 +$a0 -$10 -$01
::3			b BOX_ICON
				w $0000
				w S_FileUp
				b R1SizeY0 +SB_YPosMin -$08
				w R1SizeX0 +$a0 -$10
				w RIcon_MoveUp
				b NO_OPT_UPDATE
::4			b BOX_ICON
				w $0000
				w S_FileDown
				b R1SizeY1 -$30 +$01
				w R1SizeX0 +$a0 -$10
				w RIcon_MoveDown
				b NO_OPT_UPDATE
::5			b BOX_ICON
				w $0000
				w TakeSource
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$08
				w RIcon_FileAdd
				b NO_OPT_UPDATE
::6			b BOX_ICON
				w $0000
				w S_Reset
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$30
				w RIcon_FUnSlct
				b NO_OPT_UPDATE
::7			b BOX_ICON
				w $0000
				w S_SetAll
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$40
				w RIcon_FSelect
				b NO_OPT_UPDATE
::8			b BOX_ICON
				w $0000
				w S_SetPage
				b R1SizeY1 -$18 +$01
				w R1SizeX0 +$50
				w RIcon_PSelect
				b NO_OPT_UPDATE
::9			b BOX_USER
				w $0000
				w S_ChkBalken
				b R1SizeY0 +SB_YPosMin
				b R1SizeY1 -$30
				w R1SizeX0 +$a0 -$10
				w R1SizeX0 +$a0 -$08 -$01
::10			b BOX_FRAME
				w R1T01
				w DrawFileList_ST
				b R1SizeY0 +SB_YPosMin -$08 -$01
				b R1SizeY1 -$28 +$01
				w R1SizeX0 +$08 -$01
				w R1SizeX0 +$a0 -$08

;--- Target.
::11			b BOX_USER
				w $0000
				w SlctTarget
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX1 -$a0 +$08 +$01
				w R1SizeX1 -$10
::12			b BOX_USEROPT_VIEW
				w $0000
				w $0000
				b R1SizeY0 +SB_YPosMin -$08
				b R1SizeY1 -$28
				w R1SizeX1 -$a0 +$08 +$01
				w R1SizeX1 -$10
::13			b BOX_ICON
				w $0000
				w T_FileUp
				b R1SizeY0 +SB_YPosMin -$08
				w R1SizeX1 -$10 +$01
				w RIcon_MoveUp
				b NO_OPT_UPDATE
::14			b BOX_ICON
				w $0000
				w T_FileDown
				b R1SizeY1 -$30 +$01
				w R1SizeX1 -$10 +$01
				w RIcon_MoveDown
				b NO_OPT_UPDATE
::15			b BOX_ICON
				w $0000
				w TakeTarget
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$08 +$01
				w RIcon_FRemove
				b NO_OPT_UPDATE
::16			b BOX_ICON
				w $0000
				w T_Reset
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$30 +$01
				w RIcon_FUnSlct
				b NO_OPT_UPDATE
::17			b BOX_ICON
				w $0000
				w T_SetAll
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$40 +$01
				w RIcon_FSelect
				b NO_OPT_UPDATE
::18			b BOX_ICON
				w $0000
				w T_SetPage
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$50 +$01
				w RIcon_PSelect
				b NO_OPT_UPDATE
::19			b BOX_ICON
				w $0000
				w ResetDir
				b R1SizeY1 -$18 +$01
				w R1SizeX1 -$a0 +$68 +$01
				w RIcon_FReset
				b NO_OPT_UPDATE
::20			b BOX_USER
				w $0000
				w T_ChkBalken
				b R1SizeY0 +SB_YPosMin
				b R1SizeY1 -$30
				w R1SizeX1 -$10 +$01
				w R1SizeX1 -$08
::21			b BOX_FRAME
				w R1T02
				w InitSortMenu
				b R1SizeY0 +SB_YPosMin -$08 -$01
				b R1SizeY1 -$28 +$01
				w R1SizeX1 -$a0 +$08
				w R1SizeX1 -$08 +$01

;--- SAVE-Icon.
::22			b BOX_ICON
				w R1T03
				w EXEC_REG_ROUT
				b R1SizeY0 +$08
				w R1SizeX0 +$10
				w RIcon_FWrite
				b NO_OPT_UPDATE

;--- Datei-Informationen anzeigen.
if SORTFINFO = TRUE
:RegTMenu1a		b BOX_USEROPT_VIEW
				w $0000
				w prntFIcon
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$18 -$01
				w R1SizeX1 -$08 -$18 +$01
				w R1SizeX1 -$08

:RegTMenu1b		b BOX_USEROPT_VIEW
				w $0000
				w prntFInfo
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$18 -$01
				w R1SizeX1 -$a0 +$08 +$01
				w R1SizeX1 -$10 -$18

::25			b BOX_OPTION
				w R1T04
				w setOptFInfo
				b R1SizeY0 +$08
				w R1SizeX1 -$a0 -$28 +$01
				w OPT_SORTFINFO
				b %11111111
endif

;--- AutoSelect-Modus.
if SORTMODE64K = TRUE
::26			b BOX_OPTION
				w R1T05
				w $0000
				b R1SizeY0 +$08 +SORTINFO_MODE*$10
				w R1SizeX1 -$a0 -$28 +$01
				w OPT_AUTOSLCT
				b %11111111
endif

;*** Texte für Register "DIRSORT".
if LANG = LANG_DE
:R1T01			b "ORIGINAL",NULL

:R1T02			b "SORTIERT",NULL

:R1T03			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$06
			b "Verzeichnis"
			b GOTOXY
			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$08 +$06
			b "speichern",NULL
endif
if LANG = LANG_EN
:R1T01			b "ORIGINAL",NULL

:R1T02			b "SORTED",NULL

:R1T03			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$06
			b "Write sorted"
			b GOTOXY
			w R1SizeX0 +$10 +$10 +$04
			b R1SizeY0 +$08 +$08 +$06
			b "directory",NULL
endif

;--- Datei-Info.
:R1T04			w R1SizeX1 -$a0 -$28 +$01 +$0c
			b R1SizeY0 +$08 +$06
			b "Info",NULL
;--- AutoSelect.
:R1T05			w R1SizeX1 -$a0 -$28 +$01 +$0c
			b R1SizeY0 +$08 +SORTINFO_MODE*$10 +$06
			b "Auto",NULL

;*** Dateiliste initialisieren.
:InitSortMenu		lda	#< testKeys		;Tastenstatus abfragen.
			sta	keyVector +0
			lda	#> testKeys
			sta	keyVector +1

			bit	Flag_MWheel		;Maus verfügbar?
			bpl	:exit			; => Nein, weiter...

			lda	#< testWheel		;Mausrad abfragen.
			sta	appMain +0
			lda	#> testWheel
			sta	appMain +1

			lda	#$00			;Tastenstatus löschen.
			sta	inputData +1

::exit			rts

;*** Mausrad abfragen.
:testWheel		lda	inputData +1		;Tastenstatus einlesen.
			beq	:exit			; => Keine Taste gedrückt.

			ldx	#$00			;Tastenstatus löschen.
			stx	inputData +1

			jsr	TestMousePos
			bcs	:target

::source		cmp	#%00010000		;Wheel-UP?
			bne	:1			; => Nein, weiter...
			jmp	S_FileUp

::1			cmp	#%00001000		;Wheel-DOWN?
			bne	:exit			; => Nein, Ende...
			jmp	S_FileDown

::target		cmp	#%00010000		;Wheel-UP?
			bne	:2			; => Nein, weiter...
			jmp	T_FileUp

::2			cmp	#%00001000		;Wheel-DOWN?
			bne	:exit			; => Nein, Ende...
			jmp	T_FileDown

::exit			rts

;*** Tastaturabfrage.
:testKeys		php				;IRQ sperren.
			sei

			ldx	#$00
::loop			lda	keyTab,x		;Nächste Taste einlesen.
			beq	:exit			;$00 => Ja, Ende...
			cmp	keyData			;Taste gedrückt?
			beq	:found			; => Ja, weiter...
			inx				;Zeiger auf nächste Taste.
			bne	:loop			;Weitersuchen.

::exit			plp				;Keine Taste gefunden.
			rts				;Ende.

::found			txa				;Zeiger auf Tastenfunktion
			asl				;einlesen.
			tay
			jsr	execRout		;Funktion aufrufen.
			plp				;IRQ wieder freigeben.
			rts				;Ende.

:execRout		lda	keyRout +0,y
			ldx	keyRout +1,y
			jmp	CallRoutine

;*** Liste der Funktionstasten.
:keyTab			b " "        ;Wechsel Source/Target für Cursor-Tasten.
			b KEY_DOWN   ;Cursor down.
			b KEY_UP     ;Cursor up.
			b KEY_RIGHT  ;Cursor right.
			b KEY_LEFT   ;Cursor left.
			b KEY_HOME   ;Zum Anfang.
			b KEY_CLEAR  ;Zum Ende.
			b "c"        ;TakeSource.
			b "s"        ;S_SetPage.
			b "x"        ;ResetDir.
			b "S"        ;Verzeichnis speichern.
			b "a"        ;S_SetAll.
			b "d"        ;S_Reset.
			b NULL

;*** Liste der Routinen zu den Funktionstasten.
:keyRout		w keySwitchTab
			w keyNextLine
			w keyLastLine
			w keyNextPage
			w keyLastPage
			w keyPosTop
			w keyPosEnd
			w TakeSource
			w S_SetPage
			w ResetDir
			w EXEC_REG_ROUT
			w S_SetAll
			w S_Reset

;*** Zwischen Source/Target wechseln.
:keySwitchTab		php
			sei

			jsr	TestMousePos
			bcc	:target

::source		lda	#$5f
			b $2c
::target		lda	#$ff
			sta	mouseXPos +0
			lda	#$00
			sta	mouseXPos +1

			lda	#100
			sta	mouseYPos

			plp
			rts

;*** Letzte Zeile.
:keyLastLine		jsr	TestMousePos
			bcs	:target
::source		jmp	S_FileUp
::target		jmp	T_FileUp

;*** Nächste Zeile.
:keyNextLine		jsr	TestMousePos
			bcs	:target
::source		jmp	S_FileDown
::target		jmp	T_FileDown

;*** Letzte Seite.
:keyLastPage		jsr	TestMousePos
			bcs	:target
::source		jmp	S_LastPage
::target		jmp	T_LastPage

;*** Nächste Seite.
:keyNextPage		jsr	TestMousePos
			bcs	:target
::source		jmp	S_NextPage
::target		jmp	T_NextPage

;*** Zum Anfang.
:keyPosTop		jsr	TestMousePos
			bcs	:target
::source		jmp	S_Top
::target		jmp	T_Top

;*** Zum Ende.
:keyPosEnd		jsr	TestMousePos
			bcs	:target
::source		jmp	S_End
::target		jmp	T_End

;*** Mausposition testen.
:TestMousePos		ldx	mouseXPos +1
			cpx	#> 160
			bne	:1
			ldx	mouseXPos +0
			cpx	#< 160
::1			rts

;*** Dauerfunktion ?
;Hinweis:
;Das RegisterMenü erlaubt nicht die
;Auswertung einer Dauerfunktion über
;die Maustaste, da nach dem anklicken
;einer Option gewartet wird, bis die
;Maustaste losgelassen wird.
;Als Ersatz wird hier auf die C=-Taste
;geprüft: Ist diese aktuell gedrückt,
;dann ist Dauerfunktion aktiv.
:TestMouse		jsr	SCPU_Pause		;Wartezeit.

			jsr	testCBMkey		;CBM-Taste gedrückt?
			beq	:1			; => Ja, weiter...

			pla				;Keine Dauerfunktion:
			pla				;Rücksprungadresse vom Stack holen.
::1			rts				;Ende.

;*** Auf C= Taste prüfen.
:testCBMkey		php
			sei
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
			lda	#%01111111
			sta	cia1base +0
			lda	cia1base +1
			stx	CPU_DATA
			plp
			and	#%00100000
			rts

;*** SHIFT-Taste testen.
if SORTMODE64K = TRUE
:testShiftKeys		php				;Tastaturabfrage:
			sei				;Linke/Rechte SHIFT-Taste für
			ldx	CPU_DATA		;Datei-Info anzeigen bei aktivem
			lda	#$35			;AutoSelect-Modus.
			sta	CPU_DATA
			ldy	#%10111101
			sty	cia1base +0
			ldy	cia1base +1
			stx	CPU_DATA
			plp

;--- Hinweis:
;Nur SHIFT/Links testen, da die
;rechte SHIFT-Taste den Mauszeiger
;in der Position verändert.
			cpy	#%01111111		;SHIFT Links gedrückt?
;			beq	:exit
;			cpy	#%11101111		;SHIFT Rechts gedrückt?
;			bne	:exit			; => Nein, Abbruch...

::exit			rts
endif

;*** Anzahl Dateien ausgeben.
:PrintFiles		ClrB	currentMode

			lda	SortS_Max		;Anzahl Dateien Quelle.
			sta	r0L
if SORTMODE64K  = FALSE
			lda	#$00
			sta	r0H
endif
if SORTMODE64K  = TRUE
			lda	SortS_MaxH
			sta	r0H
endif

			lda	#< R1SizeX0 +8
			ldx	#> R1SizeX0 +8
			jsr	:prntCount

			lda	SortT_Max		;Anzahl Dateien Ziel.
			sta	r0L
if SORTMODE64K  = FALSE
			lda	#$00
			sta	r0H
endif
if SORTMODE64K  = TRUE
			lda	SortT_MaxH
			sta	r0H
endif

			lda	#< R1SizeX1 -$a0 +8 +1
			ldx	#> R1SizeX1 -$a0 +8 +1

;--- Anzahl Dateien Quelle/Ziel ausgeben.
::prntCount		sta	r11L			;X/Y-Position setzen.
			stx	r11H
			lda	#R1SizeY1 -30 +1
			sta	r1H

			lda	#< textNumFiles		;Infotext ausgeben.
			ldx	#> textNumFiles

;*** Zahl und Infotext ausgeben.
;Übergabe: r11 = X-Koordinate.
;          r1H = Y-Koordinate
;          A/X = Zeiger auf Infotext.
:prntNumText		pha
			txa
			pha

			lda	#%11000000		;Zahl linksbündig ausgeben.
			jsr	PutDecimal

			pla				;Infotext ausgeben.
			sta	r0H
			pla
			sta	r0L
			jmp	PutString

;*** Eintrag ausgeben.
;Übergabe: a7  = Zeiger auf Eintrag.
;          a2  = X-Position.
;          a3L = Y-Position.
;          a8H = Bit%7=1 = Datei ausgewählt.
:PrintEntry		ldy	#$02
			lda	(a7L),y			;Datei verfügbar ?
			beq	:end			;Nein, weiter...

			jsr	DefRectangle

			lda	#$00			;Füllmuster Standard.
			tax				;Standard-Darstellung.
			bit	a8H			;Eintrag angewählt ?
			bpl	:1			; => Nein, weiter...
			lda	#$01			;Füllmuster Revers.
			ldx	#%00100000		;Reverse Darstellung.
::1			stx	currentMode		;Textmodus setzen.
			jsr	SetPattern		;Füllmuster setzen.
			jsr	Rectangle		;Bereich löschen.

			MoveW	a2,r11			;Position für Text festlegen.
			MoveB	a3L,r1H
			ldy	#$05			;Zeiger auf erstes Zeichen.
			lda	#$05 +16 -1		;Zeiger auf letztes Zeichen.
			jmp	PrintFName

::end			rts

;*** Dateiname ausgeben.
;Übergabe: a7  = Zeiger auf 32-Byte Verzeichniseintrag.
;          r11 = X-Koordinate.
;          r1H = Y-Koordinate.
;          Y   = Zeiger auf erstes Zeichen.
;          A   = Zeiger auf letztes Zeichen.
:PrintFName		sta	:maxChars +1		;Dateiname ausgeben.
::loop			lda	(a7L),y
			cmp	#$00			;Ende Dateiname erreicht?
			beq	:end			; => Ja, Ende...
			cmp	#$a0			;SHIFT+SPACE?
			beq	:end			; => Ja, Ende...
			and	#%01111111		;Unter GEOS nur Zeichen $20 bis $7e.
			cmp	#$20			;ASCII < $20?
			bcc	:replace		; => Ja, Zeichen ersetzen.
			cmp	#$7f			;ASCII < $7f?
			bcc	:print			; => Ja, weiter...
::replace		lda	#GD_REPLACE_CHAR	;Zeichen ersetzen.

::print			sty	:next +1		;Zeiger zwischenspeichern.
			jsr	SmallPutChar		;Zeichen ausgeben.

::next			ldy	#$ff
::maxChars		cpy	#$15
			beq	:end
			iny
			bne	:loop

::end			lda	#PLAINTEXT
			jmp	PutChar

;*** Datei-Informationen anzeigen.
if SORTFINFO = TRUE

;*** Datei-Icon anzeigen.
:prntFIcon		lda	r1L			;Aufbau Registermenü?
			beq	:exit			; => Ja, Ende...
			bit	OPT_SORTFINFO		;Option "Dateiinfo" aktiv?
			bpl	:exit			; => Nein, Ende...

			lda	dirEntryBuf		;Dateityp einlesen.
			and	#ST_FMODES
			cmp	#DIR			;Typ "Verzeichnis"?
			bne	:1			; => Nein weiter...
::directory		lda	#< Icon_Map
			ldx	#> Icon_Map
			bne	:setIcon		;Icon für Verzeichnis anzeigen.

::1			lda	fileHeader +0
			ora	fileHeader +1		;Datei-Header eingelesen?
			bne	:2			; => Nein weiter...

			lda	dirEntryBuf +22		;GEOS-Datei?
			bne	:2			; => Ja, weiter...
::nonGEOS		lda	#< Icon_CBM
			ldx	#> Icon_CBM
			bne	:setIcon		;Icon für CBM-Datei anzeigen.

::2			lda	#< fileHeader +4	;Zeiger auf GEOS-Icon setzen.
			ldx	#> fileHeader +4

::setIcon		sta	:iconAdr +0		;Adresse Icon speichern.
			stx	:iconAdr +1
			jsr	i_BitmapUp		;Datei-Icon ausgeben.
::iconAdr		w	fileHeader +4
			b	(R1SizeX1 -$08 -$18 +$01)/8
			b	R1SizeY0 +$08
			b	$03
			b	$15
::exit			rts

;*** Datei-Name/-Klasse ausgeben.
:prntFInfo		lda	r1L			;Aufbau Registermenü?
			beq	:skip			; => Ja, Ende...
			bit	OPT_SORTFINFO		;Option "Dateiinfo" aktiv?
			bmi	:name			; => Ja, weiter...
::skip			jmp	:exit

;--- Textgrenzen setzen.
::name			LoadW	rightMargin,R1SizeX1 -$10 -$18 -1

;--- Dateiname ausgeben.
			LoadW	a7,dirEntryBuf -2
			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$01
			LoadB	r1H,R1SizeY0 +$08 +$06
			ldy	#$05			;Zeiger auf erstes Zeichen.
			lda	#$05 +16 -1		;Zeiger auf letztes Zeichen.
			jsr	PrintFName

			lda	fileHeader +0
			ora	fileHeader +1		;GEOS-Dateiheader vorhanden?
			beq	:size			; => Nein, weiter...

;--- GEOS-Klasse ausgeben.
			LoadW	a7,fileHeader
			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$01
			LoadB	r1H,R1SizeY0 +$08 +$08 +$06
			ldy	#77			;Zeiger auf erstes Zeichen.
			lda	#77 +18 -1		;Zeiger auf letztes Zeichen.
			jsr	PrintFName

;--- Dateigröße ausgeben.
::size			LoadB	r1H,R1SizeY0 +$08 +$08 +$08 +$06

			lda	dirEntryBuf +28		;Dateigröße einlesen und
			sta	r0L			;in KiB umwandeln.
			lda	dirEntryBuf +29
			lsr
			ror	r0L
			lsr
			ror	r0L
			sta	r0H
			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$01
			lda	#< textKByte
			ldx	#> textKByte
			jsr	prntNumText		;Dateigröße ausgeben.

			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$30 +$01
			lda	#"/"
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar		;Trennzeichen ausgeben.

			lda	dirEntryBuf +28		;Dateigröße einlesen.
			sta	r0L
			lda	dirEntryBuf +29
			sta	r0H
			lda	#< textBlocks
			ldx	#> textBlocks
			jsr	prntNumText		;Dateigröße ausgeben.

;--- Textgrenzen löschen.
::end			LoadW	rightMargin,$013f
::exit			rts

;*** Option "Datei-Info" ändern.
:setOptFInfo		lda	r1L			;Aufbau Register-Menü?
			beq	:end			; => Ja, Ende...
			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	UpdateFInfo		; => Nein, Info löschen.
::end			rts

;*** Datei-Info aktualisieren.
:UpdateFInfo		lda	#$00			;Kennung :"Datei-Header" löschen.
			sta	fileHeader +0
			sta	fileHeader +1

			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	:1			; => Nein, weiter...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Datei-Header einlesen.
;			txa				;Nicht auf Fehler prüfen.
;			bne	:exit			;Kein Infoblock = Anzeige löschen!

::1			LoadW	r15,RegTMenu1a		;Datei-Info aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1b
			jsr	RegisterUpdate

::exit			rts
endif

;*** Fensterparameter setzen.
; yReg = $00, Source
; yReg = $06, Target
:S_SetWinData		ldy	#0
			b $2c
:T_SetWinData		ldy	#6
:SetWinData		lda	fileListData+0,y
			sta	a0L
			lda	fileListData+1,y
			sta	a0H
			lda	fileListData+2,y
			sta	a1L
			lda	fileListData+3,y
			sta	a1H
			lda	fileListData+4,y
			sta	a2L
			lda	fileListData+5,y
			sta	a2H

			ldx	#$00
			cpy	#$00
			beq	:1
			inx
::1			stx	a3H
			rts

;*** X-Koordinaten berechnen.
:DefRectangle		lda	a3L
			tax
			sec
			sbc	#6
			sta	r2L
			inx
			stx	r2H

:DefXPos		sec
			lda	a2L
			sbc	#$08
			sta	r3L
			lda	a2H
			sbc	#$00
			sta	r3H

			clc
			lda	r3L
			adc	#$87
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H
			rts

;*** Verzeichnis zurücksetzen.
:ResetDir		jsr	ImportFiles
;			jmp	DrawFileList_ST

;*** Daten neu anzeigen.
:DrawFileList_ST	jsr	PrintFiles		;Anzahl Dateien ausgeben.
			jsr	S_ResetBit		;Quell-Auswahl löschen.
			jsr	T_ResetBit		;Ziel -Auswahl löschen.
			jsr	S_Top			;Zum Anfang Quell-Tabelle.
			jmp	T_Top			;Zum Anfang Ziel -Verzeichnis.

;*** Quell-Datei wählen.
:SlctSource		lda	r1L			;Wird RegisterMenü aufgebaut?
			beq	:exit			; => Ja, Ende...
			jsr	S_SetWinData		;Quell-Bereich aktivieren.

			lda	#< setMseBorderS
			ldx	#> setMseBorderS
			jsr	Slct1File
if SORTMODE64K = TRUE
			jsr	SlctSource_a		;Dateien automatisch übernehmen.
endif
if SORTFINFO = TRUE
			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	:exit			; => Nein, Ende...
			jsr	UpdateFInfo		;Datei-Info aktualisieren.
endif
::exit			rts

;*** Ziel-Datei wählen.
:SlctTarget		lda	r1L			;Wird RegisterMenü aufgebaut?
			beq	:exit			; => Ja, Ende...
			jsr	T_SetWinData		;Ziel-Bereich einlesen.

			lda	#< setMseBorderT
			ldx	#> setMseBorderT
			jsr	Slct1File
if SORTMODE64K = TRUE
			jsr	SlctTarget_a		;Dateien automatisch übernehmen.
endif
if SORTFINFO = TRUE
			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	:exit			; => Nein, Ende...
			jsr	UpdateFInfo		;Datei-Info aktualisieren.
endif
::exit			rts

;*** Seite im Quell-Tabelle markieren.
:S_SetPage		lda	SortS_Max		;Dateien ausgewählt?
if SORTMODE64K = TRUE
			ora	SortS_MaxH
endif
			beq	:exit			; => Nein, Ende...

			jsr	S_SetPage_a		;Dateien markieren.

if SORTMODE64K = TRUE
			jsr	SlctSource_a		;Dateien automatisch übernehmen.
endif
::exit			rts

;*** Seite im Ziel-Tabelle markieren.
:T_SetPage		lda	SortT_Max		;Dateien ausgewählt?
if SORTMODE64K = TRUE
			ora	SortT_MaxH
endif
			beq	:exit			; => Nein, Ende...

			jsr	T_SetPage_a		;Dateien markieren.

if SORTMODE64K = TRUE
			jsr	SlctTarget_a		;Dateien automatisch übernehmen.
endif
::exit			rts

;*** Dateien automatisch nach Ziel übernehmen.
if SORTMODE64K = TRUE
:SlctSource_a		bit	OPT_AUTOSLCT		;AutoSelect aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	testShiftKeys		;SHIFT gedrückt?
			beq	:1			; => Ja, weiter...
			jsr	TakeSource		;Dateien von Quelle nach Ziel.
::1			rts
endif

;*** Dateien automatisch nach Quelle übernehmen.
if SORTMODE64K = TRUE
:SlctTarget_a		bit	OPT_AUTOSLCT		;AutoSelect aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	testShiftKeys		;SHIFT gedrückt?
			beq	:1			; => Ja, weiter...
			jsr	TakeTarget		;Dateien von Ziel nach Quelle.
::1			rts
endif

;*** In der Quell-Tabelle eine Datei vorwärts.
:S_FileDown		jsr	S_SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	NextFile
::1			lda	#$00
			jmp	invertArrowIcon

;*** In der Quell-Tabelle eine Datei zurück.
:S_FileUp		jsr	S_SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	LastFile
::1			lda	#$01
			jmp	invertArrowIcon

;*** In der Ziel-Tabelle eine Datei vorwärts.
:T_FileDown		jsr	T_SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	NextFile
::1			lda	#$02
			jmp	invertArrowIcon

;*** In der Ziel-Tabelle eine Datei zurück.
:T_FileUp		jsr	T_SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	LastFile
::1			lda	#$03

;*** Scrollpfeile invertieren.
:invertArrowIcon	asl				;Bereich für angeklickten
			sta	r2L			;Pfeil einlesen und für Funktions-
			asl				;Anzeige invertieren.
			clc
			adc	r2L
			tay
			ldx	#$00
::1			lda	arrowIconData,y
			sta	r2L,x
			iny
			inx
			cpx	#$06
			bne	:1

			jmp	InvertRectangle

;*** Alle Markierungen im Quell-Tabelle löschen.
:S_Reset		jsr	S_ResetBit
			jmp	S_SetPos

;*** Alle Markierungen im Ziel -Verzeichnis löschen.
:T_Reset		jsr	T_ResetBit
			jmp	T_SetPos

;*** Daten für Anzeige-Balken.
:scrBarData		b $12                 ;SB_XPos      Cards.
			b SB_YPosMin +8       ;SB_YPos      Pixel.
			b SB_MaxFiles*8 -2*8  ;SB_MaxYlen   Pixel.
			b SB_MaxFiles         ;SB_MaxEScr   Bildschirmeinträge.
			w $ffff               ;SB_MaxEntry  Max. Einträge in Tabelle.
			w $ffff               ;SB_PosEntry  Pos. 1.Eintrag/Seite.

;*** X-Position für Anzeige-Balken.
:scrBarXPosCards	b $12,$26

;*** Maus-Fenstergrenzen zurücksetzen.
:noMseBorder		w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

;*** Maus-Fenstergrenzen zurücksetzen.
:setMseBorderS		w mouseTop
			b $06
			b SB_YPosMin,SB_YPosMin +SB_Height -$01
			w $0008,$008f
			w $0000

;*** Maus-Fenstergrenzen zurücksetzen.
:setMseBorderT		w mouseTop
			b $06
			b SB_YPosMin,SB_YPosMin +SB_Height -$01
			w $00a8,$012f
			w $0000

;*** Startadressen Grafikbereich für Dateiausgabe.
:GrafxDatLo		b <SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH
			b <SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH +(SCRN_WIDTH/2)
:GrafxDatHi		b >SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH
			b >SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH +(SCRN_WIDTH/2)

;*** Position der Scrollpfeile.
:arrowIconData		b SB_YPosMin+SB_Height-$08
			b SB_YPosMin+SB_Height-$01
			w $0090,$0097

			b SB_YPosMin
			b SB_YPosMin+$07
			w $0090,$0097

			b SB_YPosMin+SB_Height-$08
			b SB_YPosMin+SB_Height-$01
			w $0130,$0137

			b SB_YPosMin
			b SB_YPosMin+$07
			w $0130,$0137

;*** Modus für Mausrad-Unterstützung.
:Flag_MWheel		b $00				;$FF = Mausrad aktiv.

;*** Variablen.
:SekInMem		b $00				;Anzahl gelesender Sektoren.

if SORTFINFO = TRUE
:OPT_SORTFINFO		b $ff				;$FF = Datei-Informationen anzeigen.
endif
if SORTMODE64K = TRUE
:OPT_AUTOSLCT		b $ff				;$FF = Dateien nach Auswahl übernehmen.
endif

:SortS_Max		b $00				;Max. Dateien im Original Verzeichnis.
:SortT_Max		b $00				;Max. Dateien im Neuen Verzeichnis.
:SortS_Top		b $00				;Erster angezeigter Eintrag in Tabelle.
:SortT_Top		b $00
:SortS_Slct		b $00				;Anzahl markierter Einträge in Tabelle.
:SortT_Slct		b $00

if SORTMODE64K  = TRUE
:SortS_MaxH		b $00				;Max. Dateien im Original Verzeichnis.
:SortT_MaxH		b $00				;Max. Dateien im Neuen Verzeichnis.
:SortS_TopH		b $00				;Erster angezeigter Eintrag in Tabelle.
:SortT_TopH		b $00
:SortS_SlctH		b $00				;Anzahl markierter Einträge in Tabelle.
:SortT_SlctH		b $00
endif

;*** Daten für Quell-/Ziel-Tabelle.
:fileListData		w FLIST_SOURCE			;Dateinummern Quelle.
if SORTMODE64K  = FALSE
			w FSLCT_SOURCE			;Tabelle mit Auswahlmodus.
endif
if SORTMODE64K  = TRUE
			w FLIST_SOURCE			;64K: Auswahl = Bit%7 von Datei-Nr.
endif
			w $0010				;X-Position.

			w FLIST_TARGET			;Dateinummern Ziel.
if SORTMODE64K  = FALSE
			w FSLCT_TARGET			;Tabelle mit Auswahlmodus.
endif
if SORTMODE64K  = TRUE
			w FLIST_TARGET			;64K: Auswahl = Bit%7 von Datei-Nr.
endif
			w $00b0				;X-Position.

;*** Texte.
if LANG = LANG_DE
:textNumFiles		b " Datei(en)     ",NULL
endif
if LANG = LANG_EN
:textNumFiles		b " File(s)     ",NULL
endif

if SORTFINFO = TRUE
:textKByte		b "Kb",NULL
:textBlocks		b "Blk",NULL
endif

;*** Speicherbank für DACC-Modus.
if SORTMODE64K = TRUE
:sort64Kbank		b $00				;Speicherbank für DACC-Sortieren.

;*** Nicht genügend freier Speicher.
:Dlg_NoFreeRAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL
endif

if SORTMODE64K!LANG = TRUE!LANG_DE
::1			b PLAINTEXT,BOLDON
			b "FEHLER!",NULL

::2			b PLAINTEXT
			b "Dateien ordnen erfordert",NULL
::3			b "64Kb freien GEOS-Speicher!",NULL
::4			b "Funktion wird abgebrochen.",NULL
endif
if SORTMODE64K!LANG = TRUE!LANG_EN
::1			b PLAINTEXT,BOLDON
			b "ERROR!",NULL

::2			b PLAINTEXT
			b "Sorting files requires 64Kb",NULL
::3			b "of free GEOS memory!",NULL
::4			b "Function cancelled.",NULL
endif

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Dateinamen verfügbar ist.
			g END_APP_RAM
;***
