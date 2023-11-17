; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei-Eigenschaften anzeigen.
:xFILE_INFO		jsr	i_FillRam		;Speicher initialisieren.
			w	sysMemS
			w	sysMemA
			b	$00

			jsr	copyDirEntryData	;Dateinamen in Speicher kopieren.

			ldx	slctFiles		;Dateien ausgewählt?
			beq	ExitFileInfo		;=> Nein, Ende...

			LoadB	curFile,$00		;Zeiger auf erste Datei.
			LoadW	curFileVec,dirEntryData

			jsr	GetFileData		;Datei-Info einlesen.
			jsr	chkDateAndTime		;Datum/Uhrzeit überprüfen.

;--- Register-Menü initialisieren.
;			ClrB	regUpdate		;Flag löschen "Update Register".
			ClrB	reloadDir		;Flag löschen "Verzeichnis laden".

			jsr	SetADDR_Register	;RegisterMenü-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Register-Font aktivieren.

			LoadW	r0,RegMenu1
			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" initialisieren.
			lda	C_RegisterExit		;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
			b	(R1SizeX0/8) +1
			b	(R1SizeY0/8) -1
			b	IconExit_x
			b	IconExit_y/8

			LoadW	r0,IconMenu
			jmp	DoIcons			;Icon-Menü aktivieren.

;*** Zurück zum DeskTop.
:Exit			bit	GD_INFO_SAVE		;Datei-Info automatisch speichern?
			bpl	:1			; => Nein, weiter...
			jsr	doSaveData		;Datei-Info speichern.

::1			jsr	StopTextEdit		;Datei-Infotext-Eingabe beenden.
			jsr	ExitRegisterMenu	;Register-Menü beenden.

:ExitFileInfo		bit	reloadDir		;Verzeichnis neu laden?
			bpl	:2			; => Nein, weiter...

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen, da
							;evtl. Dateien umbenannt.

::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Verzeichniseinträge sichern.
;HINWEIS:
;Hier werden ganze Verzeichniseinträge
;gesichert und nicht nur die Datei-
;namen => Über ":FindFile" können keine
;gelöschten Dateien gesucht werden.
:copyDirEntryData	lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
			bne	:find_files		; => Dateien vorhanden, weiter...
			sta	slctFiles		; => Keine Dateien ausgewählt, Ende.
			rts

::find_files		LoadW	r0,BASE_DIR_DATA	;Zeiger auf Verzeichnis-Daten.
			LoadW	r1,dirEntryData		;Zeiger auf Zwischenspeicher.
			LoadW	r2,32			;Größe Verzeichnis-Eintrag.

			ClrB	r3L			;Dateizähler auf Angang.
if MAXENTRY16BIT = TRUE
			sta	r3H
endif

			sta	slctFiles		;Anzahl Dateien im Speicher.

::loop			ldy	#$00
			lda	(r0L),y			;Datei ausgewählt?
			beq	:next_file		; => Nein, weiter...

			jsr	MoveData		;Verzeichnis-Eintrag speichern.

			inc	slctFiles		;Anzahl Dateien +1.
			AddVBW	32,r1			;Zeiger auf nächsten Speicher.

			lda	slctFiles
			cmp	#255			;Speicher voll?
			beq	:buffer_full		; => Ja, Ende...

			CmpWI	r1,LD_ADDR_REGISTER
			beq	:buffer_full		; => Ja, Ende...

::next_file		inc	r3L			;Dateizähler +1.
if MAXENTRY16BIT = TRUE
			bne	:1
			inc	r3H
endif

::1			AddVBW	32,r0			;Nächster Verzeichnis-Eintrag.

if MAXENTRY16BIT = TRUE
			lda	r3H
			cmp	WM_DATA_MAXENTRY +1
			bne	:2
endif
			lda	r3L			;Alle markierte Einträge kopiert?
			cmp	WM_DATA_MAXENTRY +0
::2			bcc	:loop			; => Nein, weiter...

::buffer_full		rts

;*** Datei-Informationen einlesen.
:GetFileData		ClrB	setDateTime

			jsr	i_FillRam		;Datei-Informationen löschen.
			w	(FILE_VAR_END - FILE_VAR_START)
			w	FILE_VAR_START
			b	$00

			MoveW	curFileVec,r6		;Zeiger auf aktuellen
							;Verzeichnis-Eintrag setzen.

			ldy	#2			;Verzeichnis-Eintrag in
::1			lda	(r6L),y			;Zwischenspeicher kopieren.
			sta	curDirEntry,y
			iny
			cpy	#32
			bcc	:1

			LoadW	r7,curDirEntry +5
			LoadW	r8,curFileName		;Zwischenspeicher Dateiname.

			ldx	#r7L
			ldy	#r8L
			jsr	SysFilterName		;Dateiname kopieren.

			ldy	#0
::backupName		lda	curFileName,y
			sta	bakFileName,y
			iny
			cpy	#16
			bcc	:backupName

			lda	curDirEntry +30		;Größe in Blocks einlesen.
			sta	r0L
			lda	curDirEntry +31
			sta	r0H

			lda	r0L
			pha
			ldx	#r0L
			ldy	#$02
			jsr	DShiftRight		;Blocks in KBytes umrechnen.
			pla
			and	#%00000011		;Auf volle KByte aufrunden?
			beq	:2			; => Bereits volle KByte, weiter...

			IncW	r0

::2			MoveW	r0,curDirEntry		;Größe in KByte in den ungenutzen
							;Bytes #0 und #1 speichern.

			jsr	getCBMFType		;CBM-Dateityp definieren.

::fileSEQ		lda	#<fileStructSEQ		;Zeiger auf Text "SEQ" für
			ldx	#>fileStructSEQ		;Sequentielle Dateistruktur.
			ldy	curDirEntry +23		;Dateistruktur = SEQ?
			beq	:5			; => Ja, weiter...

::fileVLIR		lda	#<fileStructVLIR	;Zeiger auf Text "SEQ" für
			ldx	#>fileStructVLIR	;GEOS-VLIR Dateistruktur.

::5			sta	RTabMenu1_1a +0		;Zeiger auf Text für
			stx	RTabMenu1_1a +1		;Dateistruktur speichern.

			lda	#BOX_STRING_VIEW
			sta	RTabMenu1_2e		;GEOS-Autor deaktivieren.
			sta	RTabMenu1_2g		;GEOS-Klasse deaktivieren.
			sta	RTabMenu1_2h		;GEOS-Klasse/Version deaktivieren.
			lda	#BOX_ICON_VIEW
			sta	RTabMenu1_2c		;GEOS-Dateityp deaktivieren.
			sta	RTabMenu1_2f		;GEOS-ScreenMode deaktivieren.

			lda	curDirEntry +24		;GEOS-Datei?
			beq	:exit			; => Nein, Ende...
			lda	curDirEntry +21		;Infoblock definiert?
			beq	:exit			; => Nein, Ende...

			jsr	readGeosHeader		;GEOS-InfoBlock einlesen.
			txa				;Header-Fehler?
			bne	:exit			; => Ja, keine GEOS-Info anzeigen.

			lda	#$ff			;GEOS-Datei.
			b $2c
::exit			lda	#$00			;CBM-Datei/Verzeichnis.
			sta	curFileGEOS

			jmp	DefGEOSType		;GEOS-Dateityp/Verzeichnis setzen.

;*** Daten aus GEOS-InfoBlock einlesen.
:readGeosHeader		LoadW	r9,curDirEntry +2	;Zeiger auf Verzeichnis-Eintrag.
			jsr	GetFHdrInfo		;InfoBlock einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#0
::1			lda	fileHeader,y
			cmp	headerCode,y
			bne	:err
			iny
			cpy	#5
			bcc	:1
			bcs	:ok

::err			jsr	i_FillRam		;Speicher initialisieren.
			w	256
			w	curFHdrInfo
			b	$00

			LoadB	curFileBadHdr,$ff	;Header als "Defekt" markieren.

			ldx	#STRUCT_MISMAT		;GEOS-Header fehlerhaft.
			rts

::ok			jsr	i_MoveData		;InfoBlock in Zwischenspeicher.
			w	fileHeader
			w	curFHdrInfo
			w	256

			jsr	i_MoveData		;GEOS-Klasse in Zwischenspeicher.
			w	fileHeader +$4d
			w	curClass
			w	12

			jsr	i_MoveData		;Klasse/Version in Zwischenspeicher.
			w	fileHeader +$4d +12
			w	curClassVer
			w	6

			jsr	i_MoveData		;GEOS-Autor in Zwischenspeicher.
			w	fileHeader +$61
			w	curAuthor
			w	19

			lda	#BOX_STRING
			sta	RTabMenu1_2e		;GEOS-Autor aktivieren.
			sta	RTabMenu1_2g		;GEOS-Klasse aktivieren.
			sta	RTabMenu1_2h		;GEOS-Klasse/Version aktivieren.
			lda	#BOX_ICON
			sta	RTabMenu1_2c		;GEOS-Dateityp aktivieren.
			sta	RTabMenu1_2f		;GEOS-ScreenMode aktivieren.

			jsr	DefScrnMode		;Bildschirm-Modus einlesen.

			jsr	DefGEOSAuthor		;GEOS-Autor definieren.

			jsr	DefGEOSload		;GEOS-Lade/Ende/Start-Adressen.
			jsr	DefGEOSend
			jsr	DefGEOSrun

			ldx	#NO_ERROR
::exit			rts

;*** Datei im Verzeichnis suchen.
;    Übergabe: r6 = Zeiger auf 32Byte Verzeichnis-Eintrag.
;    Rückgabe: r1L/r1H = Track/Sektor Verzeichnis-Eintrag.
;              r5      = Zeiger auf 30Byte-Verzeichnis-Eintrag.
;
;Hinweis:
;":FindFile" kann hier nicht verwendet
;werden, da hier auch gelöschte Dateien
;gesucht werden (Dateityp = $x0).
:userFindFile		jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:no_error		; => Ja, weiter...

;--- Ergänzung: 09.10.21/M.Kanet
;Bei gelöschten Dateien den genauen
;Dateieintrag suchen. Bei anderen
;Dateien nur Typ+Name vergleichen.
;Falls die Daten im Verzeichnis-Cache
;veraltet sind (z.B. Datum geändert)
;dann erzeugt diese Routine einen
;"FILE NOT FOUND"-Fehler.
;Test:
;* Laufwerk A: geöffnet.
;* MegaAssembler starten.
;* Datei auf A: neu assemblieren.
;  Dabei wird ein neues Datum vergeben.
;* Rückkehr zu GeoDesk.
;* Dateieintrag hat noch altes Datum.
;* Dateiinfo aufrufen und beenden.
;* Bei AutoSave -> "FILE NOT FOUND",
;  da die Datei auf Disk ein neueres
;  Datum enthält.
			tay
			lda	(r5L),y			;CBM-Dateityp einlesen und als
			sta	saveSearchFlg		;Suchmodus speichern.

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#0			;Zeiger auf erstes Byte.
::1			bit	saveSearchFlg		;Gelöschte Datei suchen ?
			bpl	:testByte		; => Ja, weiter...
			dey				;Zeiger korrigieren.
::skipPos		iny
			cpy	#$01
			beq	:skipPos		; => Datei/Track übergehen.
			cpy	#$02
			beq	:skipPos		; => Datei/Sektor übergehen.
			cpy	#$13
			beq	:skipPos		; => Infoblock/Track übergehen.
			cpy	#$14
			beq	:skipPos		; => Infoblock/Track übergehen.
			cpy	#$17
			bcs	:found			; => Datum/Zeit/Größe übergehen.
::testByte		lda	(r5L),y			;Eintrag im Verzeichnis mit
			iny				;gesuchtem Eintrag im Speicher
			iny				;vergleichen.
			cmp	(r6L),y			;Dateieintrag gefunden?
			bne	:next_file		; => Nein, nächste Datei.
			dey
			cpy	#30			;Alle Bytes geprüft ?
			bcc	:1			; => Nein, weiter...

::found			ldy	#30 -1 			;Dateieintrag kopieren.
::copy			lda	(r5L),y
			sta	dirEntryBuf,y
			dey
			bpl	:copy

::no_error		ldx	#NO_ERROR		;Ende.
			rts

;--- Weiter mit nächsten Eintrag.
::next_file		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Verzeichnis bearbeitet.
			ldx	#FILE_NOT_FOUND
::error			rts				;Ende.

;*** Datei-Informationen speichern.
;Am Ende Register-Karte neu laden.
:SaveFileData		jsr	doSaveData		;Datei-Informationen speichern.
			jmp	ResetFileInfo		;Register-Karte zurücksetzen.

;*** Datei-Informationen speichern.
:doSaveData		lda	curDirEntry +0		;Datei-Info gültig?
			cmp	#$ff
			bne	:1			; => Ja, weiter...
			lda	curDirEntry +1
			cmp	#$ff
			bne	:1			; => Ja, weiter...
			rts				; => Nein, Ende.

::1			lda	curFileVec +0		;Zeiger auf Dateiname im aktuellen
			clc				;Verzeichnis-Eintrag setzen.
			adc	#< $0005
			sta	r7L
			lda	curFileVec +1
			adc	#> $0005
			sta	r7H

			LoadW	r8,testFileName		;Zwischenspeicher Dateiname.

			ldx	#r7L
			ldy	#r8L
			jsr	SysCopyName		;Dateiname kopieren.

			LoadW	r6,curFileName		;Zeiger auf neuen Dateiname.

			ldx	#r6L
			ldy	#r8L
			jsr	CmpString		;Wurde Name geändert?
			beq	:skip_file_name		; => Nein, weiter...

			jsr	FindFile		;Neue Datei suchen.
			cpx	#FILE_NOT_FOUND		;Datei vorhanden?
			beq	:rename_ok		; => Nein, weiter...
			txa				;Laufwerksfehler?
			bne	:diskError		; => Ja, Abbruch...
							;Hinweis: gelöschte Dateien
							;werden bei der Suche ignoriert.

			LoadW	r0,Dlg_ErrRename	;Fehler anzeigen "File exist!".
			jsr	DoDlgBox

::skip_file_name	lda	#$ff			;Datei nicht umbenennen.
			b $2c
::rename_ok		lda	#$00			;Datei umbenennen.
			sta	renameFile		;Rename-Flag speichern.

			MoveW	curFileVec,r6
			jsr	userFindFile		;Aktuelle Datei suchen.
			txa				;Gefunden?
			bne	:diskError		; => Nein, Ende...

::copy_data		LoadB	reloadDir,$ff		;Dateien geändert, Verzeichnis
							;in GeoDesk neu einlesen.

::rename_file		bit	renameFile		;Datei umbenennen?
			bmi	:2			; => Nein, weiter...

			jsr	updateFileName		;Dateiname ändern.

::2			jsr	updateDirEntry		;CBM-Daten speichern.
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	curFileBadHdr		;Header beschädigt?
			bmi	:badHeader		; => Nein, weiter...

			bit	curFileGEOS		;GEOS-Datei?
			bmi	:updGEOSHdr		; => Ja, weiter...

			bit	renameFile		;Verzeichnis umbenennen?
			bmi	:exit			; => Nein, weiter...

::updDirHdr		jmp	updateDirHeader		;Verzeichnis-Header umbenennen.
::updGEOSHdr		jmp	updateGeosHeader	;GEOS-InfoBlock aktualisieren.
::diskError		jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;--- Defekter GEOS-Header.
::badHeader		LoadW	r0,Dlg_BadHdr
			jmp	DoDlgBox		;Fehlermeldung anzeigen.

;*** Dateiname aktualisieren.
;    Übergabe: curEntryVec = Zeiger auf 32Byte Verzeichnis-Eintrag.
;              curFileName = Neuer Dateiname.
:updateFileName		lda	curFileVec +0		;Zeiger auf aktuellen
			clc				;Verzeichnis-Eintrag im Speicher.
			adc	#< $0002
			sta	r8L
			lda	curFileVec +1
			adc	#> $0002
			sta	r8H

			ldy	#3			;Dateiname in aktueller
			ldx	#0			;Dateiliste aktualisieren und
::1			lda	curFileName,x		;in Verzeichnis-Eintrag speichern.
			beq	:2
			sta	(r5L),y
			sta	(r8L),y
			iny
			inx
			cpx	#16
			bcc	:1
			bcs	:4

::2			lda	#$a0			;Auf 16 Zeichen mit $A0
::3			sta	(r5L),y			;auffüllen.
			sta	(r8L),y
			iny
			inx
			cpx	#16
			bcc	:3
::4			rts

;*** Datei-Informationen aktualisieren.
;    Übergabe: r1L/r1H = Track/Sektor Verzeichnis-Eintrag.
;              r5      = Zeiger auf 30Byte-Verzeichnis-Eintrag.
;              curEntryVec = Zeiger auf 32Byte Original-Eintrag.
;              curDirEntry = Kopie Verzeichnis-Eintrag.
:updateDirEntry		lda	curFileVec +0		;Zeiger auf aktuellen
			clc				;Verzeichnis-Eintrag im Speicher.
			adc	#< $0002
			sta	r8L
			lda	curFileVec +1
			adc	#> $0002
			sta	r8H

			ldy	#0
			lda	curDirEntry +2,y	;Dateityp-Flag mit "Geschlossen" und
			sta	(r5L),y			;"Schreibschutz"-Status speichern.
			sta	(r8L),y

			ldy	#22			;GEOS-Dateityp speichern.
			lda	curDirEntry +2,y
			sta	(r5L),y

			bit	setDateTime		;Datum geändert ?
			bpl	:3			; => Nein, weiter...

			ldy	#23			;Datum und Uhrzeit speichern.
::1			lda	curDirEntry +2,y
			sta	(r5L),y
			sta	(r8L),y
			iny
			cpy	#27 +1
			bcc	:1
			bcs	:4

::2			ldy	#23			;Datum und Uhrzeit einlesen.
::3			lda	(r5L),y			;(Falls Datum im Cache veraltet!)
			sta	(r8L),y
			sta	curDirEntry +2,y
			iny
			cpy	#27 +1
			bcc	:3

::4			;LoadW	r4,diskBlkBuf		;r4 noch gesetzt
			jsr	PutBlock		;Verzechnis-Sektor speichern.
			txa				;Laufwerksfehler?
			beq	:exit			; => Nein, Ende...
			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;*** Verzeichnis-Header aktualisieren.
;    Übergabe: curDirEntry = Kopie Verzeichnis-Eintrag.
:updateDirHeader	ldx	#NO_ERROR
			lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#FTYPE_MODES		;Dateityp-Bits isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis?
			bne	:exit			; => Nein, Ende.

			lda	curDirEntry +3
			sta	r1L
			lda	curDirEntry +4
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Verzeichnis-Header einlesen.
			txa				;Fehler?
			bne	:diskError		; => Ja, Abbruch...

			ldx	#0
::3			lda	curFileName,x		;Dateiname=Diskname in
			beq	:4			;Verzeichnis-Header kopieren.
			sta	diskBlkBuf +4,x
			inx
			cpx	#16
			bcc	:3
			beq	:6
::4			lda	#$a0			;Auf 16 Zeichen mit $A0
::5			sta	diskBlkBuf +4,x		;auffüllen.
			inx
			cpx	#16
			bcc	:5

::6			;LoadW	r4,diskBlkBuf		;r4 noch gesetzt
			jsr	PutBlock		;Verzechnis-Sektor speichern.
			txa				;Laufwerksfehler?
			beq	:exit			; => Nein, Ende...
::diskError		jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;*** GEOS-InfoBlock aktualisieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
:updateGeosHeader	LoadW	r9,curDirEntry +2	;Zeiger auf Verzeichnis-Eintrag.
			jsr	GetFHdrInfo		;InfoBlock einlesen.
			txa				;Fehler?
			bne	:diskError		; => Ja, Abbruch...

			ldy	#$02			;InfoBlock aus Zwischenspeicher
::1			lda	curFHdrInfo,y		;In Sektor kopieren.
			sta	fileHeader,y
			iny
			bne	:1

			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
;			LoadW	r4,diskBlkBuf		;r4 noch gesetzt
			jsr	PutBlock		;Verzechnis-Sektor speichern.
			txa				;Laufwerksfehler?
			beq	:exit			; => Nein, Ende...
::diskError		jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
::exit			rts

;*** Seite wechseln.
:SwitchPage		bit	GD_INFO_SAVE
			bpl	:100
			jsr	doSaveData

::100			sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#PosSlctPage_y		;"Eselsohrs" angeklickt wurde.
			bcs	:102
::101			rts				;Nein, Rücksprung.

::102			tay
			sec
			lda	mouseXPos+0
			sbc	#<PosSlctPage_x
			tax
			lda	mouseXPos+1
			sbc	#>PosSlctPage_x
			bne	:101
			cpx	#16			;Ist Maus innerhalb "Eselsohr" ?
			bcs	:101			;Nein, Rücksprung.
			cpy	#16
			bcs	:101
			sty	r0L
			txa				;Feststellen: Seite vor/zurück ?
			eor	#%00001111
			cmp	r0L
			bcs	:111			;Seite vor.
			bcc	:121			;Seite zurück.

;*** Weiter auf nächste Seite.
::111			ldx	curFile
			inx
			cpx	slctFiles
			bcc	:131
			ldx	#$00
			beq	:131

;*** Zurück zur letzten Seite.
::121			ldx	curFile
			bne	:122
			ldx	slctFiles
::122			dex

::131			stx	curFile			;Dateiposition speichern.

			stx	r0L			;Zeiger auf Verzeichnis-Eintrag
			LoadB	r0H,0			;im Speicher berechnen.
			ldx	#r0L
			ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.
			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			lda	r0L
			clc
			adc	#<dirEntryData
			sta	curFileVec +0
			lda	r0H
			adc	#>dirEntryData
			sta	curFileVec +1

;*** Datei-Informationen einlesen.
:ResetFileInfo		jsr	GetFileData		;Datei-Info einlesen.
			jsr	chkDateAndTime		;Datum/Uhrzeit überprüfen.

;--- Hinweis:
;regUpdate ist nur notwendig wenn
;die InfoBox der letzte Eintrag in der
;Register-Tabelle ist.
;ToDo: Evtl. Fehler in Register-Code?
:UpdateRegData
;			LoadB	regUpdate,$ff
			jsr	RegisterNextOpt
;			ClrB	regUpdate

			rts

;*** Dateiname auf Gültigkeit testen.
:chkFileName		bit	r1L			;RegisterKarte aufbauen?
			bpl	:exit			; => Ja, weiter...

			ldy	curFileName
			bne	:exit
::1			lda	bakFileName,y
			sta	curFileName,y
			iny
			cpy	#16
			bcc	:1

::exit			rts

;*** Datum und Uhrzeit auf Gültigkeit testen.
:chkDateAndTime		lda	curDirEntry +27		;Tag.
			bne	:1

;--- Fehlerhaftes Datum ersetzen.
::errDate		lda	#1
			sta	curDirEntry +27		;Tag.
			sta	curDirEntry +26		;Monat.
			lda	#80
			sta	curDirEntry +25		;Jahr.

;--- Fehlerhafte Uhrzeit ersetzen.
::errTime		lda	#00
			sta	curDirEntry +28		;Stunde.
			sta	curDirEntry +29		;Minute.
			rts

;--- Datum testen.
::1			cmp	#31 +1			;Tag =< 31?
			bcs	:errDate		; => Nein, Fehler...

			lda	curDirEntry +26		;Monat.
			beq	:errDate

			cmp	#12 +1			;Monat =< 12?
			bcs	:errDate		; => Nein, Fehler...

			lda	curDirEntry +25		;Jahr.
			beq	:errDate

			cmp	#99 +1			;Jahr =< 99?
			bcs	:errDate		; => Nein, Fehler...

;--- Uhrzeit testen.
::chkTime		lda	curDirEntry +28		;Stunde.
			cmp	#24			;Stunde >= 24?
			bcs	:errDate		; => Ja, Fehler...

			lda	curDirEntry +29		;Minute.
			cmp	#60			;Minute >= 60?
			bcs	:errDate		; => Ja, Fehler...

			rts

;*** Datum auf Gültigkeit testen.
:chkDateDay		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +27		;Tag einlesen.
			beq	:1			; => Tag ungültig...

			cmp	#31 +1			;Tag > 31?
			bcc	:2			; => Nein, weiter...

			lda	#31			;max.Wert für Tag setzen.
			b $2c
::1			lda	#1			;min.Wert für Tag setzen.
			sta	curDirEntry +27		;Korrigierter Wert für Tag.
::2			rts

:chkDateMonth		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +26		;Monat einlesen.
			beq	:1			; => Monat ungültig...

			cmp	#12 +1			;Monat > 12?
			bcc	:2			; => Nein, weiter...

			lda	#12			;max.Wert für Monat setzen.
			b $2c
::1			lda	#1			;min.Wert für Monat setzen.
			sta	curDirEntry +26		;Korrigierter Wert für Monat.
::2			rts

;*** Jahreszahl testen.
;Hinweis: Ist immer gültig.
;hier könnte aber das Jahrtausend
;für die Anzeige gesetzt werden.
:chkDateYear		rts

;*** Uhrzeit auf Gültigkeit testen.
:chkDateHour		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +28		;Stunde einlesen.
			cmp	#23 +1			;Stunde > 23?
			bcc	:1			; => Nein, weiter...

			lda	#23			;max.Wert für Stunde setzen.
			sta	curDirEntry +28		;Korrigierter Wert für Stunde.

::1			rts

:chkDateMinute		bit	r1L			;RegisterKarte aufbauen?
			bpl	:0			; => Ja, weiter...

			LoadB	setDateTime,$ff		;Flag setzen: Datum geändert.

::0			lda	curDirEntry +29		;Minute einlesen.
			cmp	#59 +1			;Minute > 59?
			bcc	:1

			lda	#59			;max.Wert für Minute setzen.
			sta	curDirEntry +29		;Korrigierter Wert für Minute.

::1			rts

;*** Aktuelles Datum auf Datei anwenden.
:SetCurDate		lda	day			;Datum übernehmen.
			sta	curDirEntry +27
			lda	month
			sta	curDirEntry +26
			lda	year
			sta	curDirEntry +25

			LoadW	r15,RTabMenu1_1c	;Tag aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RTabMenu1_1d	;Monat aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RTabMenu1_1e	;Jahr aktualisieren.
			jmp	RegisterUpdate

;*** Aktuelle Uhrzeit auf Datei anwenden.
:SetCurTime		lda	hour			;Uhrzeit übernehmen.
			sta	curDirEntry +28
			lda	minutes
			sta	curDirEntry +29

			LoadW	r15,RTabMenu1_1f	;Stunde aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RTabMenu1_1g	;Minute aktualisieren.
			jmp	RegisterUpdate

;*** Zeit für ausgwählte Dateien speichern.
:svTimeDiskFiles	ldy	#$ff			;Datum für alle Dateien auf Disk.
			b $2c
:svTimeAllFiles		ldy	#$00			;Datum für ausgewählte Dateien.
			sty	svTimeMode

			bit	GD_INFO_SAVE		;Automatisch speichern?
			bmi	:100			; => Ja, weiter...

			lda	#<Dlg_SetADate		;Datum für ausgewählte Dateien.
			ldx	#>Dlg_SetADate
			cpy	#$00
			beq	:99
			lda	#<Dlg_SetDDate		;Datum für alle Dateien auf Disk.
			ldx	#>Dlg_SetDDate
::99			sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Hinweistext ausgeben.

			lda	sysDBData
			cmp	#YES			;Datum aktualisieren?
			beq	:100			; => Ja, weiter...
			rts

::100			jsr	chkDateAndTime		;Datum/Uhrzeit überprüfen.

			bit	svTimeMode		;Alle Dateien auf Disk/Auswahl?
			bmi	:101			; => Alle Dateien auf Disk...

			jsr	doSelectedFiles		;Datum für ausgewählte Dateien.
			jmp	:102

::101			jsr	doAllFiles		;Datum für alle Dateien auf Disk.

::102			txa				;Laufwerksfehler?
			bne	:104			; => Ja, Abbruch...

			ldx	#$ff			;Dateien geändert, Verzeichnis
			stx	reloadDir		;in GeoDesk neu einlesen.
			inx
			stx	setDateTime

;--- Hinweis:
;Bei Bedarf Hinweistext am Ende nur
;anzeigen wenn AutoSave aktiv.
;Damit wird immer nur eine Dialogbox
;als Rückmeldung angezeigt:
;
;AutoSave aktiv:
; => Dateien aktualisiert.
;AutoSave inaktiv:
; => Datum aktualisieren?
;
;Vorläufig deaktiviert, damit wird bei
;AutoSave inaktiv ein Hinweis am Anfang
;und eine Info am Ende angezeigt.
;
;			bit	GD_INFO_SAVE		;Automatisch speichern?
;			bpl	:104			; => Nein, weiter...

			lda	#<Dlg_SetADatDone	;Ausgewählte Dateien...
			ldx	#>Dlg_SetADatDone

			bit	svTimeMode		;Alle Dateien auf Disk/Auswahl?
			bpl	:103			; => Alle Dateien auf Disk...

			lda	#<Dlg_SetDDatDone	;Dateien im Verzeichnis...
			ldx	#>Dlg_SetDDatDone

::103			sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Hinweistext ausgeben.

::104			jmp	GetFileData		;Datei-Info einlesen.

;*** Datum für markierte Dateien übernehmen.
:doSelectedFiles	LoadW	r6,dirEntryData		;Zeiger auf Dateinamentabelle.

			ldy	#$00			;Dateizähler zurücksetzen.
::1			sty	r14H

;			MoveW	curFileVec,r6
			jsr	userFindFile		;Datei auf Disk suchen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::2			ldy	#23			;Datum in Datei-Eintrag kopieren.
::3			lda	curDirEntry +2,y
			sta	(r5L),y
			iny
			iny
			sta	(r6L),y
			dey
;			dey
;			iny
			cpy	#27 +1
			bcc	:3

			jsr	PutBlock		;Verzeichnis-Eintrag speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			AddVBW	32,r6			;Zeiger auf nächsten Dateinamen.

			ldy	r14H			;Dateizähler +1.
			iny
			cpy	slctFiles		;Alle Dateien bearbeitet?
			bcc	:1			; => Nein, weiter...
;			ldx	#NO_ERROR
			rts

;*** Datum für alle Dateien auf Disk übernehmen.
:doAllFiles		jsr	Get1stDirEntry		;Zeiger auf Anfang Verzeichnis.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...
			cpy	#$00			;Verzeichnis-Ende erreicht?
			beq	:1			; => Nein, weiter...
			cpy	#$ff
			beq	:doFilesRAM		; => Ja, Ende...
			ldx	#CANCEL_ERR
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::1			ldy	#$00
			lda	(r5L),y			;Dateieintrag gültig?
			beq	:3			; => Nein, überspringen.
							;Hinweis: Datum wird damit nicht
							;für gelöschte Dateien gesetzt.

			ldy	#23			;Datum in Datei-Eintrag kopieren.
::2			lda	curDirEntry +2,y
			sta	(r5L),y
			iny
			cpy	#27 +1
			bcc	:2

::3			lda	r5L			;Letzter Eintrag im Sektor
			cmp	#$e0			;bearbeitet ($E0=LB 8ter Eintrag)?
			bcs	:4			; => Ja, weiter...

			AddVBW	32,r5			;Zeiger auf nächsten Eintrag.
			jmp	:1			;Nächsten Eintrag bearbeiten.

::4			jsr	PutBlock		;Verzeichnis-Sektor speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	GetNxtDirEntry		;Zeiger nächste Verzeichnis-Sektor.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch.
			tya				;Verzeichnis-Ende erreicht?
			beq	:1			; => Nein, weiter...

;*** Zusätzlich Datum für markierte Dateien im RAM übernehmen.
::doFilesRAM		LoadW	r6,dirEntryData		;Zeiger auf Dateinamentabelle.

			ldy	#$00			;Dateizähler zurücksetzen.
::11			sty	r14H

			ldy	#25			;Datum in Datei-Eintrag kopieren.
::12			lda	curDirEntry,y
			sta	(r6L),y
			iny
			cpy	#29 +1
			bcc	:12

			AddVBW	32,r6			;Zeiger auf nächste Datei.

			ldy	r14H			;Dateizähler +1.
			iny
			cpy	slctFiles		;Alle Dateien bearbeitet?
			bcc	:11			; => Nein, weiter...
;			ldx	#NO_ERROR
			rts

;*** Texteingabe für InfoText beenden.
:InitRegTab		bit	r1L			;RegisterKarte aufbauen?
			bmi	:exit			; => Nein, Ende...
			jsr	StopTextEdit		;Texteingabe beenden.
::exit			rts

;*** Infotext eingeben
:DefInfoText
;			bit	regUpdate		;RegisterKarte zurücksetzen?
;			bmi	StopTextEdit		; => Ja, Texteingabe beenden...

			bit	curFileGEOS		;GEOS-Datei?
			bpl	StopTextEdit		; => Nein, Texteingabe beenden...

			LoadW	r0,curFHdrInfo +160
			jsr	InputText		;Texteingabe-Routine starten.
			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** Texteingabe abschließen.
:StopTextEdit		jsr	InitForIO		;I/O-Bereich aktivieren.
			lda	C_Mouse			;Farbe für Cursor zurücksetzen.
			sta	$d027
			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	PromptOff		;Cursor abschalten.

			lda	#$00			;Tastenabfrage löschen.
			sta	keyVector +0
			sta	keyVector +1

			lda	alphaFlag		;Cursor ausblenden.
			and	#%01111111
			sta	alphaFlag

::exit			jmp	RegisterSetFont		;Register-Font aktivieren.

;*** InfoText löschen.
:ClrInfoText		ldy	#$a0			;Zeiger auf erstes Zeichen InfoText.
			lda	#$00			;InfoText löschen.
::1			sta	curFHdrInfo,y
			iny
			bne	:1

			LoadW	r15,RTabMenu1_3b	;InfoText-Option aktualisieren.
			jmp	RegisterUpdate

;*** InfoBlock-Icon ausgeben.
:DefInfoIcon		lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#FTYPE_MODES		;Dateityp-Bits isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis?
			bne	:1			; => Nein, weiter...

			ldx	#<Icon_Map		;Zeiger auf Verzeichnis-Icon.
			ldy	#>Icon_Map
			jsr	drawIcon		;Icon ausgeben.

			LoadW	r0,textDIR		;"DIR" als Icon-Kennung ausgeben.
			SubVB	3,r1H
			AddVBW	11,r11
			jmp	PutString

::1			bit	curFileGEOS		;GEOS-Datei?
			bpl	:2			; => Nein, weiter...

			ldx	#<curFHdrInfo +4	;Zeiger auf InfoBlock-Icon.
			ldy	#>curFHdrInfo +4
			jsr	drawIcon		;Icon ausgeben.

			LoadW	r0,textGEOS		;"GEOS" als Icon-Kennung ausgeben.
			SubVB	3,r1H
			AddVBW	8,r11
			jmp	PutString

::2			ldx	#<Icon_CBM		;Zeiger auf CBM-Icon.
			ldy	#>Icon_CBM
			jsr	drawIcon		;Icon ausgeben.

			LoadW	r0,textCBM		;"CBM" als Icon-Kennung ausgeben.
			SubVB	3,r1H
			AddVBW	10,r11
			jmp	PutString

;*** Datei-Icon ausgeben.
:drawIcon		stx	r0L			;Zeiger auf Bitmap-Daten speichern.
			sty	r0H

			PushB	r2H			;Register zwischenspeichern.
			PushW	r3

			ldx	#r3L			;X-Koordinate in CARDs umrechnen.
			ldy	#3
			jsr	DShiftRight

			lda	r3L			;Größe für Icon-Leinwand
			clc				;berechnen.
			adc	#$01
			sta	r1L
			lda	r2L
			clc
			adc	#$08
			sta	r1H
			lda	#3
			sta	r2L
			lda	#21
			sta	r2H
			jsr	BitmapUp		;Bitmap darstellen.

			PopW	r11			;Register zurücksetzen als
			PopB	r1H			;Position für Icon-Kennung.

::exit			rts

;*** Neuen Dateityp setzen.
:setCBMFType		lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#%11111000
			sta	r0L
			lda	curDirEntry +2
			and	#FTYPE_MODES		;Dateityp-Bits isolieren.
			clc
			adc	#$01			;Dateityp wechseln.
			and	#FTYPE_MODES		;Dateityp auf $x0-$x7 begrenzen.
			ora	r0L
			sta	curDirEntry +2		;Neuen CBM-Dateityp speichern.
			jsr	getCBMFType

			LoadW	r15,RTabMenu1_1b	;Dateityp-Option aktualisieren.
			jmp	RegisterUpdate

;*** CBM-Dateityp definieren.
:getCBMFType		lda	curDirEntry +2		;CBM-Dateityp einlesen.
			and	#FTYPE_MODES		;Dateityp-Bits isolieren.
			asl				;Zeiger auf Text für Dateityp
			asl				;berechnen.
			tax
			ldy	#$00
::3			lda	cbmFType,x		;CBM-Dateityp als Text in
			sta	curFileType,y		;Zwischenspeicher kopieren.
			inx
			iny
			cpy	#3
			bcc	:3
			rts

;*** Neuen Bildschirm-Modus setzen.
;Dabei wird zwischen folgenden Werten
;gewechselt:
; $00 = Nur 40 Zeichen.
; $40 = 40- und 80-Zeichen.
; $80 = Nur GEOS64.
; $c0 = Nur 80 Zeichen.
:SetScrnMode		lda	curFHdrInfo +96		;Bildschirm-Modus einlesen.
			bne	:1
			lda	#%01000000		;Neuer Modus: "40- und 80-Zeichen".
			bne	:set_new_mode

::1			cmp	#%01000000
			bne	:2
			lda	#%10000000		;Neuer Modus: "Nur GEOS64".
			bne	:set_new_mode

::2			cmp	#%10000000
			bne	:3
			lda	#%11000000		;Neuer Modus: "Nur 80-Zeichen".
			bne	:set_new_mode

::3			lda	#%00000000		;Neuer Modus: "Nur 40-Zeichen".

::set_new_mode		sta	curFHdrInfo +96		;Neuen Modus speichern.
			jsr	DefScrnMode		;Text für RegisterMenü erzeugen.

			LoadW	r15,RTabMenu1_2d	;ScreenMode-Option aktualisieren.
			jmp	RegisterUpdate

;*** Text für Bildschirm-Modus für Registerenü erzeugen.
:DefScrnMode		lda	curFHdrInfo +96		;Bildschirm-Modus einlesen.
			jsr	GetScreenMode		;Zeiger auf Text setzen.
			sta	r0L			;Zeiger zwischenspeichern.
			sty	r0H

			LoadW	r1,curScrnMode		;Zeiger auf Zwischenspeicher.

			ldx	#r0L			;Textstring für Bildschirm-Modus in
			ldy	#r1L			;Zwischenspeicher kopieren.
			jmp	CopyString

;*** Neuen GEOS-Dateityp setzen.
:SetGEOSType		bit	curFileGEOS		;GEOS-Datei?
			bpl	:exit			; => Nein, weiter...

			ldx	curDirEntry +24		;GEOS-Dateityp einlesen.
			inx
			cpx	#15			;Unbekannter Typ?
			bcc	:1			; => Nein, weiter...
			ldx	#0			;Typ "Unknown" setzen.
::1			stx	curDirEntry +24		;GEOS-Dateityp speichern und
			stx	curFHdrInfo +69		;auch im InfoBlock anpassen.
			jsr	DefGEOSType		;Text für GEOS-Dateityp erzeugen.

			LoadW	r15,RTabMenu1_2b	;GEOS-Typ-Option aktualisieren.
			jmp	RegisterUpdate
::exit			rts

;*** Text für GEOS-Dateityp für Registerenü erzeugen.
:DefGEOSType		LoadW	r15,curDirEntry		;Zeiger auf Text für
			jsr	GetGeosType		;GEOS-Dateityp einlesen.
			sta	r0L			;Zeiger zwischenspeichern.
			sty	r0H

			LoadW	r1,curGEOSType		;Zeiger auf Zwischenspeicher.

			ldx	#r0L			;Textstring für Bildschirm-Modus in
			ldy	#r1L			;Zwischenspeicher kopieren.
			jmp	CopyString

;*** GEOS-Klasse/Version testen.
:ChkGEOSClass		LoadW	r0,curClass
			LoadW	r1,curFHdrInfo +77
			lda	#" "
			ldx	#12
			bne	chkStrData

:ChkGEOSVersion		LoadW	r0,curClassVer
			LoadW	r1,curFHdrInfo +77 +12
			lda	#$00
			ldx	#6

:chkStrData		sta	r2L			;Füllzeichen speichern.
			ldy	#$00
::1			lda	(r0L),y			;Zeichen aus String einlesen.
			beq	:2			; => Ende erreicht.
			sta	(r1L),y			;In GEOS-Header kopieren.
			iny				;Zeiger auf nächstes Zeichen.
			dex				;Alle Zeichen geprüft?
			bne	:1			; => Nein, weiter...
			beq	:4			; => Ja, Ende...
::2			lda	r2L			;Füllzeichen einlesen.
::3			sta	(r0L),y			;String bis zur max.Länge auffüllen.
			sta	(r1L),y			;GEOS-Header anpassen.
			iny
			dex
			bne	:3
::4			rts

;*** GEOS-Autor übernehmen.
;Wenn bei einem PhotoScrap der Autor
;ungültig ist, dann wird der Name nicht
;automatisch im InfoBlock gelöscht.
;Nur wenn der Autor geändert wird, dann
;den neuen Namen in den GEOS-InfoBlock
;übernehmen.
:SetGEOSAuthor		bit	r1L			;RegisterKarte aufbauen?
			bpl	:exit			; => Ja, Ende...

			ldy	#0
::1			lda	curAuthor,y
			beq	:3
			sta	curFHdrInfo +$61,y
			iny
			cpy	#19
::2			lda	#NULL
::3			sta	curFHdrInfo +$61,y
			iny
			cpy	#20
			bcc	:3

::exit			rts

;*** GEOS-Auto testen.
;Ein PhotoScrap kann einen ungültigen
;GEOS-Autor beinhalten. Daher hier auf
;gültige Zeichen testen und ggf. den
;Autor löschen.
:DefGEOSAuthor		ldy	#0
::1			lda	curAuthor,y
			beq	:ok
			cmp	#$20
			bcc	:skip
			cmp	#$7f
			bcs	:skip
			iny
			cpy	#19
			bcc	:1
::ok			rts

::skip			lda	#NULL
			sta	curAuthor
			rts

;*** GEOS-Ladeadresse einlesen.
:DefGEOSload		lda	curFHdrInfo +$47
			sta	r0L
			lda	curFHdrInfo +$48
			sta	r0H
			LoadW	r1,curAdrGEOSload
			jmp	HEXW2ASCII

;*** GEOS-Endadresse einlesen.
:DefGEOSend		lda	curFHdrInfo +$49
			sta	r0L
			lda	curFHdrInfo +$4a
			sta	r0H
			LoadW	r1,curAdrGEOSend
			jmp	HEXW2ASCII

;*** GEOS-Startadresse einlesen.
:DefGEOSrun		lda	curFHdrInfo +$4b
			sta	r0L
			lda	curFHdrInfo +$4c
			sta	r0H
			LoadW	r1,curAdrGEOSrun
			jmp	HEXW2ASCII

;*** InfoText in Zwischenspeicher #1-#3 kopieren.
:doSaveBuf1		lda	#<bufInfoText1		;Adresse Zwischenspeicher #1.
			ldx	#>bufInfoText1
			bne	doSaveBuf

:doSaveBuf2		lda	#<bufInfoText2		;Adresse Zwischenspeicher #2.
			ldx	#>bufInfoText2
			bne	doSaveBuf

:doSaveBuf3		lda	#<bufInfoText3		;Adresse Zwischenspeicher #3.
			ldx	#>bufInfoText3

:doSaveBuf		bit	curFileGEOS		;GEOS-Datei?
			bpl	:exit			; => Nein, Ende...

			sta	r1L			;Zeiger auf Zwischenspeicher
			stx	r1H			;sichern.

			LoadW	r0,curFHdrInfo +160
			jmp	CopyInfoText		;InfoText in Zwischenspeicher.
::exit			rts

;*** InfoText aus Zwischenspeicher #1-#3 einlesen.
:doLoadBuf1		lda	#<bufInfoText1		;Adresse Zwischenspeicher #1.
			ldx	#>bufInfoText1
			bne	doLoadBuf

:doLoadBuf2		lda	#<bufInfoText2		;Adresse Zwischenspeicher #2.
			ldx	#>bufInfoText2
			bne	doLoadBuf

:doLoadBuf3		lda	#<bufInfoText3		;Adresse Zwischenspeicher #3.
			ldx	#>bufInfoText3

:doLoadBuf		bit	curFileGEOS		;GEOS-Datei?
			bpl	:exit			; => Nein, Ende...

			sta	r0L			;Zeiger auf Zwischenspeicher
			stx	r0H			;sichern.

			LoadW	r1,curFHdrInfo +160
			jmp	CopyInfoText		;InfoText aus Zwischenspeicher.
::exit			rts

;*** InfoText von/nach InfoBlock kopieren.
:CopyInfoText		ldy	#$00
::1			lda	(r0L),y			;Zeichen einlesen.
			beq	:2			; => Ende...
			sta	(r1L),y
			iny
			cpy	#95
			bcc	:1

::2			lda	#$00			;Rest von InfoText löschen.
::3			sta	(r1L),y
			iny
			cpy	#96
			bcc	:3

			LoadW	r15,RTabMenu1_3b
			jmp	RegisterUpdate		;InfoText-Option aktualisieren.

;*** Variablen.
:renameFile		b $00				;$FF = Datei umbenennen.
;regUpdate		b $00				;Register-Karte aktualisieren.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.
:svTimeMode		b $00				;$00=Auswahl/$FF=Verzeichnis.
:slctFiles		b $00				;Anzahl ausgewählte Dateien.
:setDateTime		b $00
:saveSearchFlg		b $00

;*** Aktuelle Datei.
:curFile		b $00				;Nummer aktuelle Datei.
:curFileVec		w $0000				;Zeiger auf aktuelle Datei.
:testFileName		s 17
:bakFileName		s 17

;*** Zwischenspeicher für RegisterMenü.
:FILE_VAR_START
:curDirEntry		s 32				;Verzeichnis-Eintrag.
:curFileGEOS		b $00				;$FF = GEOS-Datei.
:curFileBadHdr		b $00				;$FF = Header beschädigt.
:curFileName		s 17				;Dateiname.
:curFileType		s 4				;CBM-Dateityp.
:curGEOSType		s 24				;GEOS-Dateityp.
:curScrnMode		s 20				;GEOS-Bildschirm-Modus.
:curClass		s 13				;GEOS-Klasse.
:curClassVer		s 7				;GEOS-Klasse/Version.
:curAuthor		s 20				;GEOS-Autor.
:curAdrGEOSload		s 5				;GEOS-Ladeadresse.
:curAdrGEOSend		s 5				;GEOS-Endadresse.
:curAdrGEOSrun		s 5				;GEOS-Startadresse.
:FILE_VAR_END

;*** Text für Datei-Modus.
:textCBM		b "CBM",NULL
:textGEOS		b "GEOS",NULL
:textDIR		b "DIR",NULL

;*** Texte für GEOS-Dateistruktur.
:fileStructSEQ		b "SEQ",NULL
:fileStructVLIR		b "VLIR",NULL

;*** Kennung für GEOS-Dateiheader.
:headerCode		b $00,$ff,$03,$15,$bf

;*** Reservierter Speicher.
;Hinweis:
;Der reservierte Speicher ist nicht
;initialisiert!

;--- Zwischenspeicher für Borderblock.
;curFHdrInfo		s 256

;--- Zwischenspeicher für InfoText.
;bufInfoText1		s 96
;bufInfoText2		s 96
;bufInfoText3		s 96

;*** Fehler: Infoblock beschädigt.
:Dlg_BadHdr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w curFileName
			b DBTXTSTR   ,$0c,$40
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "GEOS-Infoblock nicht gespeichert:",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Der Infoblock ist beschädigt!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The GEOS infoblock was not updated:",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "The infoblock is damaged!",NULL
endif

;*** Fehler: Datei kann nicht umbenannt werden.
:Dlg_ErrRename		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w curFileName
			b DBTXTSTR   ,$0c,$40
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Umbenennen der Datei fehlgeschlagen:",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Die Datei existiert bereits!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Error when renaming the file:",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "File already exist!",NULL
endif

;*** Hinweis: Datum wird für markierte Dateien gespeichert.
:Dlg_SetADate		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w :4
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Datum wird für alle ausgewählten",NULL
::3			b "Dateien direkt auf Disk gespeichert.",BOLDON,NULL
::4			b BOLDON
			b "Datum aktualisieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The date will be saved directly to",NULL
::3			b "disk for all selected files.",BOLDON,NULL
::4			b BOLDON
			b "Update date and time?",NULL
endif

;*** Hinweis: Datum wird für alle Dateien auf Disk gespeichert.
:Dlg_SetDDate		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w :4
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Datum wird für alle Dateien im",NULL
::3			b "aktuellen Verzeichnis gespeichert.",BOLDON,NULL
::4			b BOLDON
			b "Datum aktualisieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The date will be saved directly for",NULL
::3			b "all files in the current directory.",BOLDON,NULL
::4			b BOLDON
			b "Update date and time?",NULL
endif

;*** Hinweis: Datum wurde gespeichert.
:Dlg_SetADatDone	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Datum und Uhrzeit wurden für alle",NULL
::3			b "ausgewählten Dateien aktualisiert.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Date and time has been updated for",NULL
::3			b "all selected files.",NULL
endif

;*** Hinweis: Datum wurde gespeichert.
:Dlg_SetDDatDone	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Datum und Uhrzeit wurden für alle",NULL
::3			b "Dateien im Verzeichnis aktualisiert.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Date and time has been updated for",NULL
::3			b "all files in the current directory.",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $af
:R1SizeX0		= $0028
:R1SizeX1		= $0117

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 3				;Anzahl Einträge.

			w RTabName1_1			;Register: "CBM".
			w RTabMenu1_1

			w RTabName1_2			;Register: "GEOS".
			w RTabMenu1_2

			w RTabName1_3			;Register: "GEOS-INFO".
			w RTabMenu1_3

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabName1_2		w RTabIcon2
			b RCardIconX_2,R1SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

:RTabName1_3		w RTabIcon3
			b RCardIconX_3,R1SizeY0 -$08
			b RTabIcon3_x,RTabIcon3_y

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Icons zum laden/speichern der Datei-Eigenschaften.
:RIcon_Save		w SaveInfo
			b $00,$00
			b SaveInfo_x,SaveInfo_y
			b $01

:RIcon_Load		w ResetInfo
			b $00,$00
			b ResetInfo_x,ResetInfo_y
			b $01

;*** Icon für Seitenwechsel.
:RIcon_Page		w SlctPage
			b $00,$00
			b SlctPage_x,SlctPage_y
			b $01

:PosSlctPage_x		= (R1SizeX1 +1) -$10
:PosSlctPage_y		= (R1SizeY1 +1) -$10

;*** Icons für Optionen.
:RIcon_Down		w RIconDown
			b $00,$00
			b RIconDown_x,RIconDown_y
			b $01

:RIcon_Opt		w RIconOpt
			b $00,$00
			b RIconOpt_x,RIconOpt_y
			b $01

:RIcon_Slct		w RIconSlct
			b $00,$00
			b RIconSlct_x,RIconSlct_y
			b $01

:RIcon_All		w RIconAll
			b $00,$00
			b RIconAll_x,RIconAll_y
			b $01

;*** Icons für InfoText-Zwischenspeicher.
:RIcon_SaveBuf1		w SaveBuf1
			b $00,$00
			b SaveBuf1_x,SaveBuf1_y
			b $01

:RIcon_LoadBuf1		w LoadBuf1
			b $00,$00
			b LoadBuf1_x,LoadBuf1_y
			b $01

:RIcon_SaveBuf2		w SaveBuf2
			b $00,$00
			b SaveBuf2_x,SaveBuf2_y
			b $01

:RIcon_LoadBuf2		w LoadBuf2
			b $00,$00
			b LoadBuf2_x,LoadBuf2_y
			b $01

:RIcon_SaveBuf3		w SaveBuf3
			b $00,$00
			b SaveBuf3_x,SaveBuf3_y
			b $01

:RIcon_LoadBuf3		w LoadBuf3
			b $00,$00
			b LoadBuf3_x,LoadBuf3_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "CBM".
:DIGIT_2_BYTE		= $02 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:RPos1_x  = R1SizeX0 +$08
:RPos1_y  = R1SizeY0 +$20
:RWidth1  = $0050
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $30
:RLine1_5 = $40
:RLine1_6 = $50

:RTabMenu1_1		b 22

			b BOX_ICON			;----------------------------------------
				w $0000
				w SaveFileData
				b R1SizeY0 +$08
				w RPos1_x
				w RIcon_Save
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w ResetFileInfo
				b R1SizeY0 +$08
				w RPos1_x +$18
				w RIcon_Load
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b $00

			b BOX_OPTION			;----------------------------------------
				w R1T00
				w $0000
				b R1SizeY0 +$10
				w RPos1_x +RWidth1 +$78
				w GD_INFO_SAVE
				b %11111111

			b BOX_USER_VIEW			;----------------------------------------
				w $0000
				w InitRegTab
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$0f
				w RPos1_x
				w RPos1_x +$0f

			b BOX_STRING			;----------------------------------------
				w R1T01
				w chkFileName
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1
				w curFileName
				b 16

:RTabMenu1_1c		b BOX_NUMERIC			;----------------------------------------
				w R1T02
				w chkDateDay
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1
				w curDirEntry +27
				b DIGIT_2_BYTE
:RTabMenu1_1d		b BOX_NUMERIC			;----------------------------------------
				w R1T02a
				w chkDateMonth
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$18
				w curDirEntry +26
				b DIGIT_2_BYTE
:RTabMenu1_1e		b BOX_NUMERIC			;----------------------------------------
				w R1T02b
				w chkDateYear
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$30
				w curDirEntry +25
				b DIGIT_2_BYTE
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetCurDate
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$40
				w RIcon_Opt
				b $00

:RTabMenu1_1f		b BOX_NUMERIC			;----------------------------------------
				w $0000
				w chkDateHour
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$50
				w curDirEntry +28
				b DIGIT_2_BYTE
:RTabMenu1_1g		b BOX_NUMERIC			;----------------------------------------
				w R1T03
				w chkDateMinute
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$68
				w curDirEntry +29
				b DIGIT_2_BYTE
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetCurTime
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$78
				w RIcon_Opt
				b $00

			b BOX_ICON			;----------------------------------------
				w R1T09
				w svTimeAllFiles
				b RPos1_y +RLine1_3
				w RPos1_x +$50
				w RIcon_Slct
				b $00
if LANG = LANG_DE
			b BOX_ICON			;----------------------------------------
				w $0000
				w svTimeDiskFiles
				b RPos1_y +RLine1_3
				w RPos1_x +$88
				w RIcon_All
				b $00
endif
if LANG = LANG_EN
			b BOX_ICON			;----------------------------------------
				w $0000
				w svTimeDiskFiles
				b RPos1_y +RLine1_3
				w RPos1_x +$90
				w RIcon_All
				b $00
endif

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R1T04
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RWidth1
				w curDirEntry +30
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R1T05
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RWidth1 +$48
				w curDirEntry +0
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_ICON			;----------------------------------------
				w $0000
				w setCBMFType
				b RPos1_y +RLine1_5
				w RPos1_x +RWidth1 -$08
				w RIcon_Down
				b $00
:RTabMenu1_1b		b BOX_STRING_VIEW		;----------------------------------------
				w R1T06
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RWidth1
				w curFileType
				b $03
			b BOX_STRING_VIEW		;----------------------------------------
				w R1T06a
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RWidth1 +$20 +$38
:RTabMenu1_1a			w $ffff
				b $05
			b BOX_OPTION			;----------------------------------------
				w R1T07
				w $0000
				b RPos1_y +RLine1_6
				w RPos1_x +RWidth1 +$78
				w curDirEntry +2
				b %01000000
			b BOX_OPTION			;----------------------------------------
				w R1T08
				w $0000
				b RPos1_y +RLine1_6
				w RPos1_x +RWidth1
				w curDirEntry +2
				b %10000000

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if LANG = LANG_DE
:R1T00			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0f
			b "Eingaben beim beenden"
			b GOTOXY
			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$17
			b "automatisch speichern:",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Dateiname:",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Datum/Zeit:",NULL
:R1T02a			w RPos1_x +RWidth1 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
:R1T02b			w RPos1_x +RWidth1 +$18 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL

:R1T03			w RPos1_x +RWidth1 +$18 +$18 +$18 +$18 +$02
			b RPos1_y +RLine1_2 +$06
			b ":",NULL

:R1T04			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "Dateigröße:"
			b GOTOXY
			w RPos1_x +RWidth1 +$28 +$04
			b RPos1_y +RLine1_4 +$06
			b "Blks",NULL

:R1T05			w RPos1_x +RWidth1 +$28 +$04 +$48
			b RPos1_y +RLine1_4 +$06
			b "KB",NULL

:R1T06			w RPos1_x
			b RPos1_y +RLine1_5 +$06
			b "Dateityp:",NULL
:R1T06a			w RPos1_x +RWidth1 +$20
			b RPos1_y +RLine1_5 +$06
			b "Struktur:",NULL

:R1T07			w RPos1_x +RWidth1 +$20
			b RPos1_y +RLine1_6 +$06
			b "Schreibschutz:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "Geschlossen:",NULL

:R1T09			w RPos1_x +$00
			b RPos1_y +RLine1_3 +$06
			b "->Übernehmen"
			b GOTOXY
			w RPos1_x +$5a
			b RPos1_y +RLine1_3 +$06
			b "Auswahl"
			b GOTOXY
			w RPos1_x +$92
			b RPos1_y +RLine1_3 +$06
			b "Verzeichnis"
			b NULL
endif
if LANG = LANG_EN
:R1T00			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0f
			b "Update file properties"
			b GOTOXY
			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$17
			b "automatically on exit:",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Filename:",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Date/Time:",NULL
:R1T02a			w RPos1_x +RWidth1 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
:R1T02b			w RPos1_x +RWidth1 +$18 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL

:R1T03			w RPos1_x +RWidth1 +$18 +$18 +$18 +$18 +$02
			b RPos1_y +RLine1_2 +$06
			b ":",NULL

:R1T04			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "Filesize:"
			b GOTOXY
			w RPos1_x +RWidth1 +$28 +$04
			b RPos1_y +RLine1_4 +$06
			b "Blks",NULL

:R1T05			w RPos1_x +RWidth1 +$28 +$04 +$48
			b RPos1_y +RLine1_4 +$06
			b "KB",NULL

:R1T06			w RPos1_x
			b RPos1_y +RLine1_5 +$06
			b "Filetype:",NULL
:R1T06a			w RPos1_x +RWidth1 +$20
			b RPos1_y +RLine1_5 +$06
			b "Filemode:",NULL

:R1T07			w RPos1_x +RWidth1 +$18
			b RPos1_y +RLine1_6 +$06
			b "Write protected:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "File closed:",NULL

:R1T09			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "-> Apply to"
			b GOTOXY
			w RPos1_x +$5a
			b RPos1_y +RLine1_3 +$06
			b "Selected"
			b GOTOXY
			w RPos1_x +$9a
			b RPos1_y +RLine1_3 +$06
			b "Directory"
			b NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "GEOS".
:RPos2_x  = R1SizeX0 +$08
:RPos2_y  = R1SizeY0 +$28
:RWidth2  = $0040
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $20
:RLine2_4 = $30
:RLine2_5 = $40

:RTabMenu1_2		b 15

			b BOX_ICON			;----------------------------------------
				w $0000
				w SaveFileData
				b R1SizeY0 +$08
				w RPos2_x
				w RIcon_Save
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w ResetFileInfo
				b R1SizeY0 +$08
				w RPos2_x +$18
				w RIcon_Load
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b $00
			b BOX_STRING_VIEW		;----------------------------------------
				w R2T01
				w $0000
				b R1SizeY0 +$10
				w RPos2_x +$18 +$18 +$10
				w curFileName
				b 16

			b BOX_USER_VIEW			;----------------------------------------
				w $0000
				w InitRegTab
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$0f
				w RPos2_x
				w RPos2_x +$0f

:RTabMenu1_2b		b BOX_STRING_VIEW		;----------------------------------------
				w R2T02
				w $0000
				b RPos2_y +RLine2_1
				w RPos2_x +RWidth2
				w curGEOSType
				b 16
:RTabMenu1_2c		b BOX_ICON			;----------------------------------------
				w $0000
				w SetGEOSType
				b RPos2_y +RLine2_1
				w RPos2_x +RWidth2 +$80
				w RIcon_Down
				b $00
:RTabMenu1_2g		b BOX_STRING			;----------------------------------------
				w R2T03
				w ChkGEOSClass
				b RPos2_y +RLine2_2
				w RPos2_x +RWidth2
				w curClass
				b 12
:RTabMenu1_2h		b BOX_STRING			;----------------------------------------
				w $0000
				w ChkGEOSVersion
				b RPos2_y +RLine2_2
				w RPos2_x +RWidth2 +$68
				w curClassVer
				b 6
:RTabMenu1_2e		b BOX_STRING			;----------------------------------------
				w R2T04
				w SetGEOSAuthor
				b RPos2_y +RLine2_3
				w RPos2_x +RWidth2
				w curAuthor
				b 19
:RTabMenu1_2d		b BOX_STRING_VIEW		;----------------------------------------
				w R2T05
				w $0000
				b RPos2_y +RLine2_4
				w RPos2_x +RWidth2
				w curScrnMode
				b 16
:RTabMenu1_2f		b BOX_ICON			;----------------------------------------
				w $0000
				w SetScrnMode
				b RPos2_y +RLine2_4
				w RPos2_x +RWidth2 +$80
				w RIcon_Down
				b $00
			b BOX_STRING_VIEW		;----------------------------------------
				w R2T06
				w $0000
				b RPos2_y +RLine2_5
				w RPos2_x +RWidth2 +$08
				w curAdrGEOSload
				b 4
			b BOX_STRING_VIEW		;----------------------------------------
				w R2T06a
				w $0000
				b RPos2_y +RLine2_5
				w RPos2_x +RWidth2 +$08 +$30
				w curAdrGEOSend
				b 4
			b BOX_STRING_VIEW		;----------------------------------------
				w R2T06b
				w $0000
				b RPos2_y +RLine2_5
				w RPos2_x +RWidth2 +$08 +$30 +$30
				w curAdrGEOSrun
				b 4

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if LANG = LANG_DE
:R2T01			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0d
			b "Aktuelle Datei:",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Dateityp:",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "Klasse:",NULL

:R2T04			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "Autor:",NULL

:R2T05			w RPos2_x
			b RPos2_y +RLine2_4 +$06
			b "Modus:",NULL

:R2T06			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "Adressen:"
			b GOTOXY
			w RPos2_x +RWidth2
			b RPos2_y +RLine2_5 +$06
			b "L",NULL
:R2T06a			w RPos2_x +RWidth2 +$08 +$27
			b RPos2_y +RLine2_5 +$06
			b "E",NULL
:R2T06b			w RPos2_x +RWidth2 +$08 +$30 +$27
			b RPos2_y +RLine2_5 +$06
			b "S",NULL
endif
if LANG = LANG_EN
:R2T01			w RPos2_x +$18 +$18 +$10
			b R1SizeY0 +$0d
			b "Current file:",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Filetype:",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "Class:",NULL

:R2T04			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "Author:",NULL

:R2T05			w RPos2_x
			b RPos2_y +RLine2_4 +$06
			b "Mode:",NULL

:R2T06			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "Address:"
			b GOTOXY
			w RPos2_x +RWidth2
			b RPos2_y +RLine2_5 +$06
			b "L",NULL
:R2T06a			w RPos2_x +RWidth2 +$08 +$27
			b RPos2_y +RLine2_5 +$06
			b "E",NULL
:R2T06b			w RPos2_x +RWidth2 +$08 +$30 +$27
			b RPos2_y +RLine2_5 +$06
			b "S",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "GEOS-INFO".
:RPos3_x   = R1SizeX0 +$08
:RPos3_y   = R1SizeY0 +$28
:RWidth3  = $00b8
:RLine3_1 = $00
:RLine3_2 = $48

:RTabMenu1_3		b 14

			b BOX_ICON			;----------------------------------------
				w $0000
				w SaveFileData
				b R1SizeY0 +$08
				w RPos3_x
				w RIcon_Save
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w ResetFileInfo
				b R1SizeY0 +$08
				w RPos3_x +$18
				w RIcon_Load
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b $00
			b BOX_STRING_VIEW		;----------------------------------------
				w R2T01
				w $0000
				b R1SizeY0 +$10
				w RPos3_x +$18 +$18 +$10
				w curFileName
				b 16

			b BOX_USER_VIEW			;----------------------------------------
				w $0000
				w InitRegTab
				b R1SizeY0 +$08
				b R1SizeY0 +$08 +$0f
				w RPos3_x
				w RPos3_x +$0f

			b BOX_USEROPT			;----------------------------------------
				w R3T02
				w DefInfoIcon
				b RPos3_y +RLine3_1 +$08
				b RPos3_y +RLine3_1 +$08 +$30 -1
				w RPos3_x +RWidth3
				w RPos3_x +RWidth3 +$28 -1
:RTabMenu1_3b		b BOX_USEROPT			;----------------------------------------
				w R3T01
				w DefInfoText
				b RPos3_y +RLine3_1 +$08
				b RPos3_y +RLine3_1 +$08 +$30 -1
				w RPos3_x
				w RPos3_x +$a8 -1
			b BOX_ICON			;----------------------------------------
				w $0000
				w ClrInfoText
				b RPos3_y +RLine3_1
				w RPos3_x +$a0
				w RIcon_Opt
				b $00

			b BOX_ICON			;----------------------------------------
				w R3T03
				w doSaveBuf1
				b RPos3_y +RLine3_2
				w RPos3_x +$00
				w RIcon_SaveBuf1
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w doLoadBuf1
				b RPos3_y +RLine3_2
				w RPos3_x +$18
				w RIcon_LoadBuf1
				b $00

			b BOX_ICON			;----------------------------------------
				w $0000
				w doSaveBuf2
				b RPos3_y +RLine3_2
				w RPos3_x +$40
				w RIcon_SaveBuf2
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w doLoadBuf2
				b RPos3_y +RLine3_2
				w RPos3_x +$58
				w RIcon_LoadBuf2
				b $00

			b BOX_ICON			;----------------------------------------
				w $0000
				w doSaveBuf3
				b RPos3_y +RLine3_2
				w RPos3_x +$80
				w RIcon_SaveBuf3
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w doLoadBuf3
				b RPos3_y +RLine3_2
				w RPos3_x +$98
				w RIcon_LoadBuf3
				b $00

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
if LANG = LANG_DE
:R3T01			w RPos3_x
			b RPos3_y +RLine3_1 +$04
			b "Infotext:",NULL

:R3T02			w RPos3_x +RWidth3
			b RPos3_y +RLine3_1 +$04
			b "Icon:",NULL

:R3T03			w RPos3_x
			b RPos3_y +RLine3_2 -$04
			b "Infotext-Zwischenspeicher:",NULL
endif
if LANG = LANG_EN
:R3T01			w RPos3_x
			b RPos3_y +RLine3_1 +$04
			b "Info text:",NULL

:R3T02			w RPos3_x +RWidth3
			b RPos3_y +RLine3_1 +$04
			b "Icon:",NULL

:R3T03			w RPos3_x
			b RPos3_y +RLine3_2 -$04
			b "Buffers for info text:",NULL
endif

;*** Icons für Registerkarten.
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

:RTabIcon3
<MISSING_IMAGE_DATA>

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x
:RCardIconX_3		= RCardIconX_2 + RTabIcon2_x

;*** Register-System-Icons.
:RIconDown
<MISSING_IMAGE_DATA>

:RIconDown_x		= .x
:RIconDown_y		= .y

:RIconOpt
<MISSING_IMAGE_DATA>

:RIconOpt_x		= .x
:RIconOpt_y		= .y

:RIconSlct
<MISSING_IMAGE_DATA>

:RIconSlct_x		= .x
:RIconSlct_y		= .y

:RIconAll
<MISSING_IMAGE_DATA>

:RIconAll_x		= .x
:RIconAll_y		= .y

;*** Register-Funktions-Icons.
:ResetInfo
<MISSING_IMAGE_DATA>
:ResetInfo_x		= .x
:ResetInfo_y		= .y

:SaveInfo
<MISSING_IMAGE_DATA>
:SaveInfo_x		= .x
:SaveInfo_y		= .y

:SlctPage
<MISSING_IMAGE_DATA>
:SlctPage_x		= .x
:SlctPage_y		= .y

:SaveBuf1
<MISSING_IMAGE_DATA>
:SaveBuf1_x		= .x
:SaveBuf1_y		= .y

:LoadBuf1
<MISSING_IMAGE_DATA>
:LoadBuf1_x		= .x
:LoadBuf1_y		= .y

:SaveBuf2
<MISSING_IMAGE_DATA>
:SaveBuf2_x		= .x
:SaveBuf2_y		= .y

:LoadBuf2
<MISSING_IMAGE_DATA>
:LoadBuf2_x		= .x
:LoadBuf2_y		= .y

:SaveBuf3
<MISSING_IMAGE_DATA>
:SaveBuf3_x		= .x
:SaveBuf3_y		= .y

:LoadBuf3
<MISSING_IMAGE_DATA>
:LoadBuf3_x		= .x
:LoadBuf3_y		= .y

;******************************************************************************
;*** Icon-Menü.
;******************************************************************************
;*** Icon-Menü "Beenden".
:IconMenu		b $01
			w $0000
			b $00

			w IconExit
			b (R1SizeX0/8) +1,R1SizeY0 -$08
			b IconExit_x,IconExit_y
			w Exit

;*** Icon zum schließen des Menüs.
:IconExit
<MISSING_IMAGE_DATA>

:IconExit_x		= .x
:IconExit_y		= .y
