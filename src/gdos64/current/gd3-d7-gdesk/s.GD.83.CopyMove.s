; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei kopieren/verschieben.

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
			t "SymbTab_MMAP"
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"

;--- Variablen für Status-Box:
:STATUS_X		= $0040
:STATUS_W		= $00c0
:STATUS_Y		= $30
:STATUS_H		= $50

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_X1		= STATUS_X +96
:INFO_Y1		= STATUS_Y +26
:INFO_Y2		= STATUS_Y +36
:INFO_Y3		= STATUS_Y +46
:INFO_Y4		= STATUS_Y +56

;--- Kopierstatus.
:flagExitCopy		= $ff
:flagDelFile		= $fe
:flagSkipFile		= $fd
endif

;*** GEOS-Header.
			n "obj.GD83"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xFILE_COPYMOVE

;*** Programmroutinen.
			t "-Gxx_MakeDir"
			t "-Gxx_CopyFSlct"
			t "-Gxx_NxtDirEntry"
			t "-Gxx_IBoxCore"
			t "-Gxx_IBoxDisk"
			t "-Gxx_IBoxFile"

;*** Systemroutinen.
			t "-SYS_STATMSG"

;*** Dateien/Verzeichnisse kopieren/verschieben.
:xFILE_COPYMOVE		php				;Tastaturabfrage:
			sei				;Linke SHIFT + C= -Taste für
			ldx	CPU_DATA		;Dateien verschieben.
			lda	#$35
			sta	CPU_DATA
			ldy	#%01111101
			sty	cia1base +0
			ldy	cia1base +1
			stx	CPU_DATA
			plp

			ldx	#$00			;Modus: Dateien kopieren.
			cpy	#%01011111		;SHIFT + C= gedrückt?
			bne	:copy			; => Nein, weiter...
::move			dex				;Modus: Dateien verschieben.
::copy			stx	flagMoveFiles		;Kopiermodus speichern.

			jsr	_ext_CopyFSlct		;Dateinamen in Speicher kopieren.

			ldx	slctFiles		;Dateien ausgewählt?
			beq	ExitCopyMove		; => Nein, Ende...
			stx	statusMax		;Max.Anzahl Dateien für Statusbox.

			lda	sysSource +2		;Aktuelles Verzeichnis für
			sta	SourceSDirOrig +0	;SubDir-Copy speichern.
			lda	sysSource +3
			sta	SourceSDirOrig +1

			lda	sysTarget +2		;Aktuelles Verzeichnis für
			sta	TargetSDirOrig +0	;SubDir-Copy speichern.
			lda	sysTarget +3
			sta	TargetSDirOrig +1

			jsr	doCopyMoveJob		;Dateien löschen.
			txa				;Fehler?
			beq	ExitCopyMove		; => Nein, Ende...
			cpx	#flagExitCopy		;Abbruch?
			beq	ExitCopyMove		; => Ja, weiter...

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
;			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

;*** Zurück zum DeskTop.
:ExitCopyMove		jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			bit	reloadDir		;Verzeichnis neu laden?
			bpl	:1			; => Nein, weiter...

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

;--- RELOAD-Flag für Quelle/Ziel.
			lda	#GD_LOAD_CACHE		;Quelle: Dateien aus Cache.
			ldx	flagMoveFiles		;Dateien verschieben?
			beq	:0			; => Nein, weiter...
			lda	#GD_LOAD_DISK		;Quelle: Dateien von Disk laden.
::0			sta	updateSource

			lda	#GD_LOAD_DISK		;Ziel: Dateien von Disk laden.
			sta	updateTarget

			ldx	flagDuplicate		;Dateien duplizieren?
			bne	:1			; => Nein, weiter...
			sta	updateSource		;Quelle aktualisieren.

::1			jmp	MOD_UPDATE_WIN		;Zurück zum Hauptmenü.

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawTitel2		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$18,$27
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	_ext_InitIBox		;Status-Box anzeigen.
			jsr	_ext_InitStat		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			lda	#< jobInfTxCopy		;"Dateien kopieren"
			ldx	#> jobInfTxCopy
			bit	flagMoveFiles
			bpl	:1
			lda	#< jobInfTxMove		;"Dateien verschieben"
			ldx	#> jobInfTxMove
::1			sta	r0L
			stx	r0H
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxRemain		;"Auswahl:"
			LoadW	r11,STATUS_X +8		;(Anzahl verbleibender Dateien)
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,infoTxFile		;"Datei"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jsr	PutString

			LoadW	r0,infoTxBlocks		;"Blocks"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y4
			jsr	PutString

			LoadW	r0,infoTxStruct		;"Typ"
			LoadW	r11,STATUS_X +80
			LoadB	r1H,INFO_Y4
			jmp	PutString		;Titelzeile ausgeben.

;*** Anzeigebereich Dateistruktur löschen.
:clrFStructInfo		lda	#$00
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y4 -6
			b	INFO_Y4 +1
			w	INFO_X1
			w	(STATUS_X + STATUS_W) -8
			rts

;*** Texte.
if LANG = LANG_DE
:jobInfTxCopy		b PLAINTEXT,BOLDON
			b "DATEIEN KOPIEREN"
			b PLAINTEXT,NULL
:jobInfTxMove		b PLAINTEXT,BOLDON
			b "DATEIEN VERSCHIEBEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
:infoTxRemain		b "Verbleibend: ",NULL
:infoTxBlocks		b "Blocks: ",NULL
:infoTxStruct		b "Typ: ",NULL
:infoTypVLIR		b "VLIR / #",NULL
:infoTypSEQ		b "Sequentiell",NULL
endif
if LANG = LANG_EN
:jobInfTxCopy		b PLAINTEXT,BOLDON
			b "COPYING FILES"
			b PLAINTEXT,NULL
:jobInfTxMove		b PLAINTEXT,BOLDON
			b "MOVING FILES"
			b PLAINTEXT,NULL

:infoTxFile		b "File: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
:infoTxRemain		b "Remaining: ",NULL
:infoTxBlocks		b "Blocks: ",NULL
:infoTxStruct		b "Type: ",NULL
:infoTypVLIR		b "VLIR / #",NULL
:infoTypSEQ		b "Sequential",NULL
endif

;*** DiskName für StatusBox.
:curDiskName		s 17

;*** Dateien/Verzeichnisse kopieren/verschieben.
:doCopyMoveJob		ClrB	statusPos		;Zeiger auf erste Datei.
			jsr	DrawStatusBox		;Statusbox aufbauen.

			jsr	_ext_PrntDInfo		;Disk-/Verzeichnisname ausgeben.

			LoadB	reloadDir,$ff		;GeoDesk: Verzeichnis neu laden.

			LoadW	r15,SYS_FNAME_BUF	;Zeiger auf Anfang Dateiliste.

			sei
			clc				;Mauszeigerposition nicht ändern.
			jsr	StartMouseMode		;Mausabfrage starten.
			cli				;Interrupt zulassen.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

;--- Schleife: Einträge kopieren.
::loop			lda	pressFlag		;Kopieren abbrechen?
			bne	:exit			; => Ja, Ende...

			lda	#$00			;Variablen löschen:
			sta	dirNotEmpty		; => "Verzeichnis nicht leer".
			sta	flagMoveDirEntry	; => "Datei-Einträge verschieben".
			sta	flagDuplicate		; => "Dateien duplizieren".

			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			MoveW	r15,r6			;Zeiger auf Dateiname.
			jsr	FindFile		;Aktuelle Datei suchen.
			txa				;Datei Gefunden?
			bne	:error			; => Nein, Abbruch...

			ldx	sysSource
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode Laufwerk?
			beq	:is_file		; => Nein, weiter...

			lda	dirEntryBuf
			and	#ST_FMODES		;Dateityp isolieren.
			cmp	#DIR			;Verzeichnis?
			beq	:is_dir			; => Ja, weiter...

;--- Datei kopieren.
::is_file		jsr	doCopyFile		;Einzelne Datei kopieren.
			jmp	:test_error

;--- Verzeichnis kopieren.
::is_dir		lda	dirEntryBuf +1		;Ist aktuelles Verzeichnis das
			cmp	TargetSDirOrig +0	;Ziel-Verzeichnis ?
			bne	:1			; => Nein, weiter...
			lda	dirEntryBuf +2
			cmp	TargetSDirOrig +1
			beq	:next_file		; => Ja, überspringen...

::1			ldx	sysTarget
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Target = NativeMode ?
			bne	:copy_files		; => Ja, weiter...

			bit	GD_COPY_NM_DIR		;Dateien kopieren?
			bpl	:next_file		; => Nein, Verz. überspringen...
			bvc	:copy_files		; => Kein, Hinweis anzeigen.

			PushW	r15			;Zeiger auf Dateiliste sichern.

			LoadW	r0,Dlg_NMD_Warn		;"Dateien werden kopiert"
			jsr	DoDlgBox		;Hinweis anzeigen.

;--- Hinweis:
;Warten bis Maustaste nicht mehr
;gedrückt. Führt sonst zu Problemen
;bei der Tastaturabfrage.
			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

			PopW	r15			;Zeiger auf Dateiliste sichern.

			lda	sysDBData
			cmp	#NO			;Nicht kopieren?
			beq	:next_file		; => Ja, Verzeichnis überspringen.
			cmp	#YES			;Dateien kopieren oder Abbruch?
			beq	:copy_files		; => Kopieren, weiter...
;			bne	:exit			; => Abbruch, Ende...

;--- Ende oder Disk-Fehler.
::exit			inc	statusPos		;100% Fortschrittsanzeige.
			jsr	_ext_UpdStatus		;Statusanzeige aktualisieren.
			jsr	_ext_PrntStat		;Fortschrittsbalken aktualisieren.

			ldx	#NO_ERROR
::error			rts				;"Datei kopieren" beenden.

;--- Dateien kopieren.
::copy_files		lda	dirEntryBuf +1		;Tr/Se für Verzeichnis-Header
			sta	curDirHeader +0		;als Startverzeichnis speichern.
			lda	dirEntryBuf +2
			sta	curDirHeader +1
			jsr	doCopyDir		;Verzeichnis kopieren.

;--- Datei/Verzeichnis kopiert.
::test_error		cpx	#$7f			;Schreibschutz ignoriert?
			beq	:next_file		; => Ja, nächste Datei.
;			cpx	#flagExitCopy		;Abbruch bei "Schreibschutz"?
;			beq	:exit			; => Ja, Ende...
			txa				;Fehler?
			bne	:error			; => Ja, Ende...

;--- Weiter mit nächster Datei.
::next_file		AddVBW	17,r15			;Zeiger auf nächste Datei.
			inc	statusPos		;Pos. für Fortschrittsanzeige.

			lda	statusPos
			cmp	slctFiles		;Alle Dateien gelöscht?
			beq	:exit			; => Ja, Ende...
			jmp	:loop			; => Nein, weiter...

;*** Datei kopieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
:doCopyFile		jsr	copyFileName		;Dateiname kopieren.

			jsr	copySourceDate		;Datum für Vergleich sichern.

			jsr	_ext_UpdStatus		;Statusanzeige.
			jsr	clrFStructInfo		;Anzeige Dateistruktur zurücksetzen.
			jsr	_ext_PrntStat		;Fortschrittsbalken aktualisieren.

			jsr	testCopyMode		;Kopiermodus ermitteln.

			jsr	checkTargetFile		;Datei auf Target-Laufwerk suchen.
			cpx	#flagSkipFile		;Datei überspringen?
			beq	:exit			; => Ja, weiter...
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Source-Laufwerk wieder aktivieren.
;Hier muss jetzt auch der Eintrag in
;dirEntryBuf erneut eingelesen werden,
;da checkTargetFile dirEntryBuf evtl.
;überschreibt.
			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	r6,origFileName		;Zeiger auf Original-Dateiname.
							;curFileName enthält evtl. Suffix.
			jsr	FindFile		;Datei auf Disk suchen.
			txa				;Gefunden?
			bne	:error			; => Nein, weiter...

;--- Auf Verschieben testen.
;Modus: Dateien zwischen verschiedenen
;Verzeichnissen innerhalb des Laufwerks
;verschieben.
			lda	dirEntryBuf
			and	#ST_FMODES		;Dateityp einlesen.
			cmp	#DIR			;Verzeichnis?
			beq	:copy			; => Ja, weiter...

			bit	flagMoveFiles		;Dateien verschieben?
			bpl	:copy			; => Nein, weiter...
			bit	flagMoveDirEntry	;Innerhalb Laufwerk verschieben?
			bpl	:copy			; => Nein, weiter...
			jsr	moveDirEntry		;Eintrag verschieben.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			beq	:exit			; => Nein, Ende...

;--- Datei kopieren.
;Code stammt von GeoDOS64 CBM-to-CBMF.
;Angepasst an GeoDesk.
::copy			jsr	InitCopy		;Kopieren initialisieren und
			jsr	StartCopy		;aktuelle Datei kopieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			bit	flagMoveFiles		;Dateien verschieben?
			bpl	:exit			; => Nein, Ende...
			jmp	doDeleteFile		; => Ja, Source-Datei löschen.

::exit			ldx	#NO_ERROR		;Kein Fehler.
::error			rts				;Ende.

;*** Datei auf Source-Laufwerk löschen.
:doDeleteFile		jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			LoadW	r6,origFileName		;Zeiger auf Original-Dateiname.
							;curFileName enthält evtl. Suffix.
			jsr	FindFile		;Datei auf Disk suchen.
			txa				;Gefunden?
			bne	:1			; => Nein, weiter...

			jsr	copyFileName		;Dateiname kopieren.

			jsr	testWrProtOn		;Schreibschutz testen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
			bmi	:1			; => Abbruch, Ende...
			ldx	#NO_ERROR		;Schreibschutz-Datei nicht löschen.
::1			rts				;Ende.

::2			LoadW	r0,origFileName		;Source-Datei löschen.
			jmp	DeleteFile

;*** Datum für Vergleich sichern.
:copySourceDate		ldy	#$00
			b $2c
:copyTargetDate		ldy	#$06
			ldx	#19			;Jahr 19xx...
			lda	dirEntryBuf +23		;Jahr einlesen.
			cmp	#80			;Jahr >= 1980?
			bcs	:1			; => Ja, weiter...
			inx				;Jahr 20xx...
::1			sta	sourceDate +1,y		;Jahr.
			txa
			sta	sourceDate +0,y		;Jahrtausend.

			lda	dirEntryBuf +24		;Monat.
			sta	sourceDate +2,y
			lda	dirEntryBuf +25		;Tag.
			sta	sourceDate +3,y

			lda	dirEntryBuf +26		;Stunde.
			sta	sourceDate +4,y
			lda	dirEntryBuf +27		;Stunde.
			sta	sourceDate +5,y

			rts

;*** Datei innerhalb Laufwerk verschieben.
;Wird verwendet wenn auf NativeMode
;Dateien zwischen Unterverzeichnissen
;verschoben werden sollen.
;Die Dateien werden dann nicht kopiert
;und gelöscht, sondern es wird nur der
;Verzeichnis-Eintrag selbst in das
;andere Unterverzeichnis verschoben.
:moveDirEntry		MoveB	r1L,:dirEntryTr		;Zeiger auf Verzeichnis-Eintrag
			MoveB	r1H,:dirEntrySe		;zwischenspeichern.
			MoveW	r5,:dirEntryAdr

			lda	dirEntryBuf +28		;Dateilänge für Status-Info
			sta	File1Len + 0		;initialisieren.
			lda	dirEntryBuf +29
			sta	File1Len + 1

			jsr	prntBlocksJob		;Dateigröße ausgeben.
			jsr	prntFStructJob		;Dateistruktur ausgeben.

			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ClrB	r10L
			jsr	GetFreeDirBlk		;Freien Verzeichnis-Eintrag suchen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;			ldx	#0			;Datei-Eintrag Source-Datei in
::1			lda	dirEntryBuf,x		;Target-Verzeichnis kopieren.
			sta	diskBlkBuf,y
			iny
			inx
			cpx	#30
			bcc	:1

			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Block zurückschreiben.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Hinweis:
;":GetFreeDirBlk" legt ggf. einen neuen
;Verzeichnis-Sektor an und markiert den
;Block in der aktuellen BAM im Speicher
;als "belegt". Daher BAM speichern...
			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			MoveB	:dirEntryTr,r1L		;Zeiger auf Verzeichnis-Eintrag
			MoveB	:dirEntrySe,r1H		;zurücksetzen.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			MoveW	:dirEntryAdr,r5		;Eintrag Source-Datei.

			ldy	#$00			;Datei-Eintrag Source-Datei löschen.
			tya
			sta	(r5L),y
			jsr	PutBlock		;Verzeichnis-Block zurückschreiben.
;			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...
::error			rts

;*** Zwischenspeicher Verzeichnis-Eintrag.
::dirEntryTr		b $00
::dirEntrySe		b $00
::dirEntryAdr		w $0000

;*** Prüfen ob Datei bereits existiert.
:checkTargetFile	jsr	OpenTargetDrive		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::checkTgtAgain		LoadW	r6,curFileName		;Zeiger auf Verzeichnisname.
			jsr	FindFile		;Verzeichnis auf Disk suchen.
			txa				;Gefunden?
			beq	:fileExists		; => Ja, weiter...
			cpx	#FILE_NOT_FOUND		;Fehler "FILE NOT FOUND"?
			bne	:error			; => Nein, Diskfehler / Abbruch.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;--- Duplizieren/Verschieben?
::fileExists		lda	flagDuplicate		;Source=Target = Duplizieren?
			beq	:duplicateName		; => Ja, weiter...

			bit	GD_SKIP_EXIST		;Automatisch überspringen?
			bmi	:skipExisting		; => Ja, weiter...
			bit	GD_OVERWRITE
			bpl	:overwriteName		; => Dateien nicht überschreiben.

;--- Verzeichnisse nicht überschreiben.
::deleteExisting	lda	dirEntryBuf		;Dateityp einlesen.
			and	#ST_FMODES
			cmp	#DIR			;Verzeichnis?
			bne	:deleteFile		; => Nein, weiter...

::skipDirectory		lda	#< curFileName		;Dateiname in Zwischenspeicher
			sta	r0L			;kopieren, da die Status-Routine
			lda	#> curFileName		;evtl. den Bereich mit dem Datei-
			sta	r0H			;namen überschreibt
			lda	#< dataFileName
			sta	r1L
			sta	errDrvInfoF +0
			lda	#> dataFileName
			sta	r1H
			sta	errDrvInfoF +1

			ldx	#r0L
			ldy	#r1L
			jsr	CopyString		;Verzeichnisname kopieren.

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;			jsr	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.

			LoadB	errDrvCode,$86		;"SKIP_DIRECTORY"
			jsr	SUB_STATMSG		;Statusmeldung ausgeben.

			jsr	DrawStatusBox		;Statusbox wieder herstellen.
			jsr	_ext_PrntDInfo		;Disk-/Verzeichnisname ausgeben.

			jmp	:skip			;Verzeichnis überspringen.

::deleteFile		LoadW	r0,curFileName		;Zeiger auf Datei-Name und
			jsr	DeleteFile		;Datei löschen.
::error			rts

;--- Duplizieren oder Kopieren.
;Datei existiert bereits, Vorschlag für
;neuen Dateinamen mit Suffix "_0".
::skipExisting		bit	GD_SKIP_NEWER		;Neuere Dateien überspringen?
			bpl	:skip			; => Nein, Ende...

			jsr	copyTargetDate		;Datum für Vergleich sichern.

			ldx	#$00
::loop			lda	targetDate,x		;Source-/Target-Datum vergleichen.
			cmp	sourceDate,x		;Target älter als Source?
			bcc	:replaceOlder		; => Ja, weiter...
			inx
			cpx	#$06
			bcc	:loop
			bcs	:skip			; => Nein, Datei überspringen.

::replaceOlder		bit	GD_OVERWRITE
			bmi	:deleteExisting		; => Dateien überschreiben.

::overwriteName		ldx	#$00			;Neuer Dateiname mit "Löschen".
			b $2c
::duplicateName		ldx	#$7f			;Neuer Dateiname ohne "Löschen".
			LoadW	r6,curFileName		;Zeiger auf Datei-Name.
			jsr	GetNewName		;Neuen Namen eingeben.
			cpx	#flagExitCopy		;CANCEL?
			beq	:exit			; => Ja, Abbruch...
			cpx	#flagDelFile		;Existierende Datei löschen?
			beq	:deleteExisting		; => Ja, weiter...
			cpx	#flagSkipFile		;Datei überspringen?
			beq	:exit			; => Ja, weiter...
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r0,newName		;Zeiger auf neuen Namen.
			LoadW	r1,curFileName		;Zeiger auf Target-Dateiname.
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyName		;Name in Zwischenspeicher kopieren.
			jmp	:checkTgtAgain		;Erneut testen.

::skip			ldx	#flagSkipFile		;Datei überspringen.
::exit			rts

;*** Verzeichnis kopieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;Hinweis: Die Routine kopiert rekursiv
;alle Dateien und weitere Unterver-
;zeichnisse im gewählten Verzeichnis.
:doCopyDir		jsr	doOpenDirectory		;Verzeichnis Source/Target öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	_ext_PrntDInfo		;Verzeichnisname ausgeben.

;--- Zeiger auf Anfang Verzeichnis.
			jsr	usr1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:exitDirectory		; => Ja, weiter...

;--- Verzeichnis-Eintrag auswerten.
::loop			lda	pressFlag		;Taste gedrückt?
			beq	:0			; => Nein, weiter...
			jmp	cancelDirCopy		;Dateien kopieren abbrechen.

::0			ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			and	#ST_FMODES		;"Gelöscht"?
			beq	:next_entry		; => Ja, nächste Datei...

			pha				;Dateityp zwischenspeichern.

			jsr	copyDirEntry		;Verzeichnis-Eintrag in
							;Zwischenspeicher kopieren.

			pla				;Dateityp wieder einlesen.

;			lda	dirEntryBuf
;			and	#ST_FMODES		;Dateityp einlesen.
			cmp	#DIR			;Verzeichnis?
			bne	:1			; => Nein, Datei kopieren.

;--- Weiteres Unterverzeichnis kopieren.
			jmp	doCopyDir		;Verzeichnis Rekursiv kopieren.

;--- Disk-Fehler, Abbruch.
::error			rts

;--- Datei im Verzeichnis kopieren.
::1			PushW	r5			;Zeiger Verzeichnis-Eintrag sichern.

			PushB	r1L			;Tr/Se für Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.

			jsr	doCopyFile		;Einzel-Datei kopieren.
			stx	:2 +1			;Fehlerstatus speichern.

			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.

			PopB	r1H			;Tr/Se für Verzeichnis-Eintrag
			PopB	r1L			;zurücksetzen.

			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor wieder
			jsr	GetBlock		;einlesen.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag.

			txa				;Fehler bei Verzeichnis einlesen?
			bne	:error			; => Ja, Abbruch...

::2			ldx	#$ff 			;Fehler bei Datei kopieren?
			bne	:error			; => Ja, Abbruch...

;--- Weiter mit nächsten Eintrag,
::next_entry		jsr	usrNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Verzeichnis-Eintrag kopiert.
;An dieser Stelle die alle Dateien im
;aktuellen Unterverzeichnis kopiert.
;Hier wird jetzt das Unterverzeichnis
;selbst gelöscht, wenn Verschieben von
;Dateien gewählt wurde.
::exitDirectory		jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	reloadDirEntry		;Zeiger auf Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Hinweis:
;Elternverzeichnis öffnen.
;r1L/r1H und r5 nicht verändern!
			jsr	openParentDir		;Eltern-Verzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			bit	flagMoveFiles		;Dateien verschieben?
			bpl	:nextDirectory		; => Nein, weiter...

			ldx	dirNotEmpty		;Verzeichnis leer?
			bmi	:nextDirectory		; => Nein, weiter...

			jsr	copyDirEntry		;Verzeichnis-Eintrag in
							;Zwischenspeicher kopieren.
;--- Hinweis:
;Für freeCurFile muss r1L/r1H auf den
;Tr/Se des Verzeichnis-Eintrages
;zeigen und r5 auf den Eintrag im
;Verzeichnis-Sektor selbst!
;r1L/r1H und r5 nicht verändern!
			jsr	freeCurFile		;Verzeichnis-Eintrag selbst löschen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Verzeichnis-Ende erreicht.
::nextDirectory		ldy	#$01			;Zuerst gewähltes Verzeichnis
			lda	(r5L),y			;oder Unterverzeichnis?
			cmp	curDirHeader +0
			bne	:9
			iny
			lda	(r5L),y
			cmp	curDirHeader +1
			beq	:exit			; => Verzeichnis kopiert.

::9			jmp	:next_entry		; => Weiter im Unterverzeichnis.

;--- Verzeichnis bearbeitet.
::exit			jsr	_ext_PrntDInfo		;Verzeichnisname zurücksetzen.

			ldx	#NO_ERROR		;Kein Fehler, Ende...
			rts

;*** Kopieren abbrechen.
;Zurück zum ersten Verzeichnis.
:cancelDirCopy		jsr	OpenTargetDrive		;Source-Laufwerk öffnen.

			ldx	sysTarget
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			lda	TargetSDirOrig +0	;Eltern-Verzeichnis vom
			sta	r1L			;aktuellen Verzeichnis öffnen.
			lda	TargetSDirOrig +1
			sta	r1H
			jsr	OpenSubDir

::1			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.

			ldx	sysSource
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:2			; => Nein, weiter...

			lda	SourceSDirOrig +0	;Eltern-Verzeichnis vom
			sta	r1L			;aktuellen Verzeichnis öffnen.
			lda	SourceSDirOrig +1
			sta	r1H
			jsr	OpenSubDir

::2			ldx	#flagExitCopy		;Kopieren abbrechen.
			rts

;*** Zeiger auf Verzeichnis-Eintrag.
;Setzt r1L/r1H auf Tr/Se für Sektor des
;Verzeichnis-Eintrages für das aktuelle
;Unterverzeichnis und lädt den dazu-
;gehörigen Verzeichnis-Sektor.
:reloadDirEntry		lda	curDirHead +36		;Zeiger auf Tr/Se im Verzeichnis-
			sta	r1L			;Eintrag Elternverzeichnis setzen.
			lda	curDirHead +37
			sta	r1H

			lda	curDirHead +38		;Zeiger auf Byte für Verzeichnis-
			sta	r5L			;Eintrag in Sektor setzen.
			lda	#>diskBlkBuf
			sta	r5H

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jmp	GetBlock		;Verzeichnis-Sektor einlesen.

;*** Aktuellen Verzeichnis-Eintrag löschen.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;              r1L/r1H = Tr/Se Verzeichnis-Sektor.
;              r5 = Zeiger auf Verzeichnis-Eintrag in Verzeichnis-Sektor.
;Hinweis: r1/r5 dürfen nicht verändert
;werden (:GetNxtDirEntry).
:freeCurFile		PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			LoadW	r9,dirEntryBuf		;Zeiger auf Datei-Eintrag.
			jsr	FreeFile		;Datei löschen.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			txa				;Fehler?
			beq	:2			; => Ja, Abbruch...

			lda	dirEntryBuf +22		;GEOS-Dateityp einlesen.
			cmp	#TEMPORARY		;Typ Swap_File ?
			bne	:1			; => Nein, weiter...
			cpx	#BAD_BAM		;Fehler "BAD_BAM" ?
			bne	:1			; => Nein, weiter...
			ldx	#NO_ERROR		; => Kein Fehler.
::1			rts

::2			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher setzen.
			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			tay				;Dateityp "Gelöscht" setzen.
			sta	(r5L),y
			jmp	PutBlock		;Verzeichnis-Sektor schreiben.

;*** Datei kopieren.
:InitCopy		ldx	sysTarget
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:1			; => Nein, weiter...
			lda	#64			;Suche ab $01/$40 = CMD-Standard.
::1			sta	NxFreeSek +1
			lda	#1
			sta	NxFreeSek +0

			jsr	i_FillRam		;Variablenspeicher löschen.
			w	(EndVarMem-StartVarMem)
			w	StartVarMem
			b	$00
			rts

;*** Dateilänge -1
:Sub1FileLen		lda	File1Len +0		;Alle Blocks kopiert?
			ora	File1Len +1
			beq	:1			; => Ja, übergehen.
			SubVW	1,File1Len		;Anzahl Blocks -1.
::1			rts

;*** prntBlocks ausgeben.
:prntBlocks		jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	prntBlocksJob
			jmp	Reset_IO

;*** VLIR-Datensatz ausgeben.
:prntFStruct		jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	prntFStructJob
			jmp	Reset_IO

;*** Verbleibende Blocks ausgeben.
:prntBlocksJob		LoadW	r11,INFO_X0		;Anzahl noch zu kopierender Blocks
			LoadB	r1H,INFO_Y4		;ausgeben.

			MoveW	File1Len,r0

			lda	#SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal
			lda	#" "			;Anzeige-Reste löschen.
			jmp	SmallPutChar

;*** Dateistruktur ausgeben.
:prntFStructJob		LoadW	r11,INFO_X1
			LoadB	r1H,INFO_Y4

			lda	jobDirEntry +21		;Dateiformat bestimmen.
			bne	:101			;VLIR-Datei, -> Datensatz ausgeben.

			LoadW	r0,infoTypSEQ		;"Sequentiell" ausgeben.
			jmp	PutString

::101			LoadW	r0,infoTypVLIR		;"VLIR: (Datensatz) " ausgeben.
			jsr	PutString

			lda	LastReadRec		;Nr. des VLIR-Datensatz ausgeben.
			sec
			sbc	#1
			lsr
			sta	r0L
			ClrB	r0H

			lda	#SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal
			lda	#" "			;Anzeige-Reste löschen.
			jmp	SmallPutChar

;*** BAM der Ziel-Diskette "updaten".
:IO_Update		jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler?
			bne	ExitNewDrive		; => Ja, Abbruch...

			jsr	OpenSourceDrive		;Quell-Laufwerk aktivieren.
			jmp	EnableTurboIO		;TurboDOS + I/O-Bereich aktivieren.

;*** Quell-Laufwerk aktivieren.
;Hinweis:
;Wird aktuell nicht verwendet.
;:IO_SetSource		jsr	DoneWithIO		;I/O-Bereich ausblenden.
;			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
;			jmp	EnableTurboIO		;TurboDOS + I/O-Bereich aktivieren.

;*** Ziel-Laufwerk aktivieren.
:IO_SetTarget		jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.

;*** TurboDOS + I/O-Bereich aktivieren.
:EnableTurboIO		txa				;Fehler?
			bne	ExitNewDrive		; => Ja, Abbruch...
:Reset_IO		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa
:ExitNewDrive		pha
			jsr	InitForIO		;I/O-Bereich einblenden.
			pla
			tax
			rts

;*** Einzeldatei kopieren.
;    Übergabe: dirEntryBuf = 30Byte Verzeichnis-Eintrag.
;              curFileName = Name Ziel-Datei.
:StartCopy		jsr	OpenSourceDrive		;Quell-Laufwerk aktivieren.

;--- Dateiname kopieren.
;Ziel-Dateiname kann hier bereits ein
;Suffix "_1" enthalten, daher nicht
;aus dirEntryBuf übernehmen.
			ldy	#$00
::1			lda	curFileName,y		;Dateiname in Zwischenspeicher
			beq	:2			;für neuen Dateieintrag kopieren.
			sta	jobDirEntry +3,y
			iny
			cpy	#16
			bcc	:1
			bcs	:4

::2			lda	#$a0			;Mit "$A0" auf 16 Zeichen auffüllen.
::3			sta	jobDirEntry +3,y
			iny
			cpy	#16
			bcc	:3

::4			ldy	#$00
::103			lda	dirEntryBuf,y		;Datei-Eintrag in Zwischenspeicher
			sta	jobDirEntry,y		;kopieren.
::104			iny
			cpy	#3
			bcc	:103
			cpy	#19			;Dateiname überspringen.
			bcc	:104
			cpy	#30
			bne	:103

			lda	jobDirEntry +28		;Dateilänge Quell-Datei als
			sta	File1Len + 0		;Zähler initialisieren.
			lda	jobDirEntry +29
			sta	File1Len + 1

			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00
			sta	FreeSekBuf +0
			sta	File2Len   +0		;Länge der Zieldatei löschen.
			sta	File2Len   +1

			lda	jobDirEntry +22		;Dateityp = $00?
			beq	:106			; -> Ja, keine GEOS-Datei.

			jsr	GetInfoSek		;Track/Sektor Infoblock einlesen.
			jsr	SetInfoMem		;Zeiger auf Speicher für Infoblock.
			jsr	ReadBlock		;Infoblock einlesen.
			txa				;Diskettenfehler?
			bne	:107			; => Ja, Abbruch...

			jsr	Sub1FileLen		;Blockzähler -1.

			lda	jobDirEntry +21		;Dateiformat bestimmen.
			beq	:106
			jmp	FileIsVLIR		; -> VLIR-Datei kopieren.
::106			jmp	FileIsSEQ		; -> SEQ -Datei kopieren.
::107			jmp	DoneWithIO		;I/O-Bereich ausblenden, Fehler!
::101			rts

;*** Seq. Datei kopieren.
:FileIsSEQ		jsr	prntFStruct		;Dateistruktur anzeigen.

			jsr	GetHeaderSek		;Zeiger auf ersten Sektor einlesen.
			bne	:101			;Sektor verfügbar? Ja, kopieren...

;--- HINWEIS:
;Sonderbehandlung für TopDesk-Ordner.
;Hier sind keine Daten vorhanden. Der
;erste Sektor ist Tr/Se = $00/$FF.
;Daher Ziel-Laufwerk aktivieren und
;einen freien Sektor für den Infoblock
;suchen/reservieren.
			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:100			;festgelegt? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...
::100			jmp	WriteDirEntry		;Infoblock schreiben.

::101			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.
			jsr	LoadFileData		;Sektor-Kette in Speicher einlesen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			MoveW	r1,NextSekBuf		;Nächsten Sektor merken.

			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:102			;festgelegt? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			lda	FreeSekBuf +0		;Freien Sektor merken.
			sta	jobDirEntry   +1	;(Reserviert für Infoblock!)
			lda	FreeSekBuf +1
			sta	jobDirEntry   +2

::102			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			PushW	FreeSekBuf		;Ersten freien Sektor merken.
			jsr	SaveFileData		;Sektorkette auf Disk schreiben.
			PopW	r1			;Startadresse Sektorkette einlesen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			jsr	ChkFileData		;Sektorkette vergleichen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

::103			bit	EndOfData		;Alle Daten kopiert?
			bpl	:105			; => Nein, weiter...
::104			jmp	WriteDirEntry		;Infoblock schreiben.

::105			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:106			; => Ja, Abbruch...

			MoveW	NextSekBuf,r1		;Zeiger auf nächsten Quell-Sektor.
			jmp	:101			;Sektorkette weiterlesen...

;*** Abbruch mit Fehlermeldung im xReg.
::106			jmp	DoneWithIO		;I/O-Bereich ausblenden, Fehler!

;*** VLIR-Datei kopieren.
:FileIsVLIR		jsr	GetHeaderSek		;VLIR-Header einlesen.

			LoadW	r4,fileTrScTab
			jsr	ReadBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler?
			beq	:102			; => Nein, weiter...
::101			jmp	DoneWithIO		;I/O-Bereich ausblenden, Abbruch.

::102			jsr	Sub1FileLen		;Blockzähler -1.

			lda	#$00
			sta	DataCopied

			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			ldy	#2			;Zeiger auf ersten zu lesenden
			sty	WriteCurRec		;Record richten.

::103			lda	#$ff			;Neuen Record lesen.
			sta	ContinueCopy

::104			lda	#$00
			sta	EndOfData

			lda	fileTrScTab+0,y		;Track-Adresse aus VLIR-Header für
			sta	r1L			;aktuellen Record einlesen.
			ldx	fileTrScTab+1,y		;Sektor-Adresse aus VLIR-Header für
			stx	r1H			;aktuellen Record einlesen.

			iny
			sty	LastReadRec		;Zeiger auf gelesenen Record setzen.

			tay				;Track -Adresse = $00?
			beq	:106			; => Ja, Record übergehen...

			PushW	r1
			jsr	prntFStruct
			PopW	r1

::105			jsr	LoadFileData		;Sektorkette einlesen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			MoveW	r1,NextSekBuf		;Nächsten Sektor merken.

			bit	EndOfData		;Dateiende erreicht?
			bpl	:201			; => Ja, weiter...

			jsr	AddSekToMem		;Kopierspeicher voll?
			bcs	:201			; => Ja, weiter...

::106			ldy	LastReadRec		;Zeiger auf nächsten Record.
			iny				;Ende erreicht?
			bne	:104			; => Nein, nächsten Record kopieren

;*** Record-Daten im Speicher kopieren.
::201			jsr	IO_SetTarget		;Ziel-Laufwerk öffnen.
			txa				;Diskettenfehler?
			beq	:203			; => Nein, weiter...
::202			jmp	DoneWithIO		;I/O-Bereich ausblenden.

::203			lda	FreeSekBuf +0		;Startsektor für Sektorsuche schon
			bne	:204			;festgelegt? -> Ja, weiter...
			jsr	Get1stBlock		;Ersten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:202			; => Ja, Abbruch...

::204			lda	DataCopied		;Wurden Daten kopiert?
			bne	:205			; => Ja, weiter...
			jmp	WriteDirEntry		; -> Infoblock schreiben.

::205			lda	ContinueCopy		;Sektorkette weiterschreiben?
			beq	:208			; -> Ja, Sonderbehandlung.

::206			ldy	WriteCurRec		;Track des zu schreibenden
			lda	fileTrScTab+0,y		;Records. War Adresse = $00?
			bne	:207			; => Nein, Daten schreiben.

			inc	WriteCurRec		;Zeiger auf nächsten Record.
			inc	WriteCurRec		;Alle Records kopiert?
			beq	:212			; => Ja, Daten verifizieren.
			bne	:206			;Weiterkopieren...

;*** Neuen Record auf Diskette schreiben.
::207			lda	FreeSekBuf +0		;Ersten Sektor in VLIR-Header
			sta	fileTrScTab+0,y		;übertragen.
			lda	FreeSekBuf +1
			sta	fileTrScTab+1,y

::208			PushW	FreeSekBuf		;Ersten Sektor merken.
			PushB	WriteCurRec		;Zeiger auf aktuellen Record merken.

			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

::209			jsr	SaveFileData		;Sektorkette auf Disk schreiben.
			txa				;Diskettenfehler?
			bne	:212			; => Ja, Abbruch...

			ldy	#0
			lda	(a6L),y			;Wurde kompletter Record kopiert?
			bne	:212			; => Nein, weiter...

::210			ldy	WriteCurRec
			iny
			iny
			sty	WriteCurRec		;Alle Records kopiert?
			beq	:212			; => Ja, Daten verifizieren...

			lda	fileTrScTab+0,y		;Nächster Record verfügbar?
			beq	:210			; => Ja, Record schreiben.

::211			jsr	AddSekToMem		;Kopierspeicher voll?
			bcs	:212			; => Ja, Daten verifizieren...

			lda	FreeSekBuf +0		;Startadresse Sektorkette in
			sta	fileTrScTab+0,y		;VLIR-Header eintragen.
			lda	FreeSekBuf +1
			sta	fileTrScTab+1,y
			jmp	:209			;Nächsten Record schreiben.

::212			PopB	WriteCurRec		;Zeiger auf Record einlesen.
			PopW	r1			;Zeiger auf ersten Sektor einlesen.

			txa				;Diskettenfehler?
			beq	:301			; => Nein, weiter...
::213			jmp	DoneWithIO		;I/O-Bereich ausblenden, Abbruch...

;*** Neue Daten verifizieren.
::301			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

::302			jsr	ChkFileData		;Sektorkette vergleichen.
			txa				;Diskettenfehler?
			bne	:213			; => Ja, Abbruch...

			ldy	#0
			lda	(a6L),y			;Wurde kompletter Record kopiert?
			bne	:307			; => Nein, weiter...

::303			ldy	WriteCurRec
			iny
			iny
			sty	WriteCurRec		;Alle Records kopiert?
			beq	:304			; => Ja, Infoblock schreiben.

			lda	fileTrScTab+0,y		;Zeiger auf nächsten Record.
			sta	r1L
			ldx	fileTrScTab+1,y
			stx	r1H

			cmp	#$00			;Daten im nächsten Record?
			bne	:305			;Ja   -> Record vergleichen.
			beq	:303			;Nein -> Zeiger auf nächsten Record.

::304			jmp	WriteDirEntry

;*** Alle Daten vergleichen.
::305			jsr	AddSekToMem		;Kopierspeicher voll?
			bcc	:302			; => Nein, weiter...

;*** Neue Sektorkette lesen.
::306			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:308			; => Ja, Abbruch.

			stx	DataCopied		;Flags für "Daten im Speicher" und
			dex				;"Sektorkette weiterlesen" löschen.
			stx	ContinueCopy
			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			jmp	:106			;Nächsten Record einlesen.

;*** Letzte Sektorkette weiterlesen.
::307			jsr	IO_Update		;Quell-Laufwerk öffnen.
			txa				;Diskettenfehler?
			bne	:308			; => Ja, Abbruch.

			stx	DataCopied		;Flag "Daten im Speicher" löschen.
			stx	ContinueCopy		;Flag "Sektorkette lesen" setzen.
			jsr	SetDataTop		;Zeiger auf Start Datenspeicher.

			MoveW	NextSekBuf,r1		;Zeiger auf nächsten Quell-Sektor.
			jmp	:105			;Sektorkette weiterlesen.

;*** Diskettenfehler.
::308			jmp	DoneWithIO		;I/O-Bereich ausblenden, Abbruch...

;*** Sektorkette einlesen.
:LoadFileData		MoveW	a6,r4
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

			jsr	Sub1FileLen		;Blockzähler -1.
			jsr	prntBlocks		;Info ausgeben.

			jsr	MoveSekAdr		;Verkettungszeiger kopieren.
			beq	:102			;Noch ein Sektor? Nein, Ende.

			jsr	IsMemoryFull		;Speicher voll?
			bcs	:101			; => Nein, weiterlesen...

			inc	a6H			;Zeiger auf nächsten Sektor.
			jmp	LoadFileData

::101			lda	#$00
			b $2c
::102			lda	#$ff
			sta	EndOfData

			lda	#$ff
			sta	DataCopied

::103			rts

;*** Sektorkette schreiben.
:SaveFileData		lda	FreeSekBuf +0		;Nächster Sektor in Speicher für
			sta	r3L			;aktuellen Sektor und in Adresse für
			sta	r1L			;"Nächster freien Sektor suchen"
			lda	FreeSekBuf +1		;kopieren.
			sta	r3H
			sta	r1H

::101			jsr	GetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch.

			ldy	#0
			lda	(a6L),y			;Noch ein Sektor in aktueller Kette?
			beq	:102			; => Nein, Ende...

			lda	r3L			;Nächsten Sektor als
			sta	(a6L),y			;Verkettungszeiger für aktuellen
			iny				;Sektor merken.
			lda	r3H
			sta	(a6L),y

::102			MoveW	a6,r4
			jsr	WriteBlock		;Sektor auf Diskette schreiben.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

			IncW	File2Len		;Blockzähler Zieldatei +1.

			lda	r3L			;Adresse des nächsten Sektors in
			sta	r1L			;Zwischenspeicher kopieren und als
			sta	FreeSekBuf +0		;neue Adresse für "Sektor suchen"
			lda	r3H			;setzen.
			sta	r1H
			sta	FreeSekBuf +1

			ldy	#0
			lda	(a6L),y			;Folgt noch ein Sektor?
			beq	:103			; => Nein, Ende...

			jsr	IsMemoryFull		;Speicher voll?
			bcs	:103			; => Nein, weiterschreiben...

			inc	a6H
			jmp	:101

::103			rts				;Ende...

;*** Sektorkette vergleichen.
:ChkFileData		MoveW	a6,r4
			jsr	VerWriteBlock		;Sektor vergleichen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			jsr	MoveSekAdr		;Verkettungszeiger kopieren.
			beq	:101			;Noch ein Sektor? Nein, Ende.

			jsr	IsMemoryFull		;Speicher voll?
			bcs	:101			; => Nein, weiterlesen...

			inc	a6H			;Zeiger auf nächsten Sektor.
			jmp	ChkFileData

::101			rts

;*** Infoblock auf Diskette schreiben.
;    Sektor liegt ab ":Copy1Sek" im
;    Speicher des Computers!
:WriteDirEntry		jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	jobDirEntry +22		;GEOS-Datei?
			bne	:writeInfoBlk		; => Ja, weiter...

			ldx	FreeSekBuf +0		;Seektor Infoblock reserviert?
			beq	:exit			; => Nein, Ende...
			stx	r6L
			lda	FreeSekBuf +1
			sta	r6H
			jsr	FreeBlock		;Sektor für Infoblock freigeben.
			txa				;Diskettenfehler?
			beq	NewDirEntry		; => Nein, Dateieintrag erzeugen.
::exit			rts				;Abbruch...

::writeInfoBlk		lda	FreeSekBuf +0		;Sektor für Infoblock in
			sta	r1L			;Zwischenspeicher und Verzeichnis-
			sta	jobDirEntry   +19	;eintrag für Zieldatei kopieren.
			lda	FreeSekBuf +1
			sta	r1H
			sta	jobDirEntry   +20

			jsr	SetInfoMem		;Zeiger auf Speicher für Infoblock.
			jsr	PutBlock		;Sektor auf Diskette speichern.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			IncW	File2Len		;Blockzähler Zieldatei +1.

			lda	jobDirEntry +21		;VLIR-Datei?
			beq	NewDirEntry		; => Nein, weiter...

			MoveW	FreeSekBuf,r3		;Freien Sektor für
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			lda	r3L			;Sektor für VLIR-Header in
			sta	r1L			;Zwischenspeicher und Verzeichnis-
			sta	jobDirEntry +1		;eintrag für Zieldatei kopieren.
			lda	r3H
			sta	r1H
			sta	jobDirEntry +2

			LoadW	r4,fileTrScTab		;VLIR-Header speichern.
			jsr	PutBlock
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			IncW	File2Len		;Blockzähler Zieldatei +1.

;*** Verzeichniseintrag erzeugen.
:NewDirEntry		LoadB	r10L,0
			jsr	GetFreeDirBlk		;Freien Verzeichniseintrag suchen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...

;			ldx	#0			;Verzeichniseintrag in
::1			lda	jobDirEntry ,x		;Verzeichnis-Sektor kopieren.
			sta	diskBlkBuf  ,y
			iny
			inx
			cpx	#28			;30Bytes - 2Bytes Dateigröße.
			bcc	:1

			lda	File2Len  +0		;Dateilänge der Ziel-Datei in
			sta	diskBlkBuf+0,y		;Verzeichnis-Eintrag schreiben.
			lda	File2Len  +1
			sta	diskBlkBuf+1,y

			LoadW	r4,diskBlkBuf		;Verzeichniseintrag
			jsr	PutBlock		;zurück auf Diskette schreiben.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...

			jmp	PutDirHead		;BAM auf Diskette sichern, Ende...

::error			rts				;Diskettenfehler...

;*** Nächsten freien Sektor auf
;    Ziel-Laufwerk suchen.
:Get1stBlock		lda	NxFreeSek+0
			sta	r3L
			lda	NxFreeSek+1
			sta	r3H
			jsr	GetNextFree		;Nächsten freien Sektor suchen.
			MoveW	r3,FreeSekBuf		;Sektor merken.
			rts

;*** Nächsten freien Sektor suchen.
:GetNextFree		jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	SetNextFree		;Freien Sektor suchen.
			txa
			pha
			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.
			pla
			tax				;Fehlerstatus setzen.
			rts

;*** Zeiger auf Anfang Datenspeicher.
:SetDataTop		LoadW	a6,StartBuffer		;Zeiger auf Startadresse
			rts				;für Datenspeicher.

;*** Zeiger auf Anfang Datenspeicher.
:SetInfoMem		LoadW	r4,Copy1Sek		;Zeiger auf Startadresse
			rts				;für Datenspeicher.

;*** Kopierspeicher voll?
:AddSekToMem		inc	a6H			;Zeiger auf Speicher korrigieren.
			lda	a6H
			cmp	#>EndBuffer		;Speicher voll?
			rts

:IsMemoryFull		ldy	a6H
			iny
			cpy	#>EndBuffer
			rts

;*** Verkettungszeiger nach ":r1" kopieren.
:MoveSekAdr		ldy	#1			;Verkettungszeiger einlesen.
			lda	(a6L),y
			sta	r1H
			dey
			lda	(a6L),y
			sta	r1L			;Nächster Sektor verfügbar?
			rts

;*** Sektoradresse aus ":dirEntryBuf" nach ":r1" kopieren.
;    xReg = zeigt auf Byte-Position!
:GetHeaderSek		ldx	#1
			b $2c
:GetInfoSek		ldx	#19

			lda	jobDirEntry+1,x
			sta	r1H
			lda	jobDirEntry+0,x
			sta	r1L
			rts

;*** Kopiermodus ermitteln.
;1) Duplizieren: XREG=$00
;Wenn SourceDrv = TargetDrv, dann
;werden die Dateien dupliziert, egal
;ob verschiedene Fenster.
;2) Kopieren: XREG<>$00
;Nur wenn Laufwerk/Partition gleich,
;aber SubDir verschieden, dann werden
;die Datei-Einträge direkt in das
;andere Verzeichnis verschoben, wenn
;Verschieben statt kopieren aktiv.
:testCopyMode		ClrB	flagMoveDirEntry	;Dateien in Verzeichnis kopieren.

			ldx	#INCOMPATIBLE		;Vorgabe: Kopieren.

			ldy	#$00			;Quell-/Ziel-Laufwerk vergleichen.
::1			lda	sysSource,y
			cmp	sysTarget,y		;Laufwerke gleich?
			bne	:2			; => Nein, Abbruch...
			iny
			cpy	#$04
			bcc	:1
			bcs	:duplicate		;Quelle=Ziel, duplizieren.

::2			ldx	sysSource
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:copy			; => Nein, weiter...

			cpy	#$02			;Nur Verzeichnis unterschiedlich?
			bcc	:copy			; => Nein, kopieren...

			dec	flagMoveDirEntry	;Modus "Kopieren" zwischen
							;NativeMode-Verzeichnissen.
			b $2c				;Modus: Kopieren.
::duplicate		ldx	#NO_ERROR		;Modus: Duplizieren.
::copy			stx	flagDuplicate		;Kopiermodus speichern.
			rts

;*** Auf Schreibschutz testen.
:testWrProtOn		lda	dirEntryBuf		;Dateityp einlesen.
			and	#%0100 0000		;Schreibschutz aktiv?
			beq	:no_error		; => Nein, weiter...

			PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			LoadW	r0,Dlg_ErrWrProt	;Fehler ausgeben:
			jsr	DoDlgBox		;"Datei schreibgeschützt".

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			lda	sysDBData		;Auf Schreibschutz testen.
			cmp	#YES			;Schreibschutz ignorieren?
			beq	:no_error		; => Ja, Datei löschen.

			cmp	#NO			;Schreibschutz akzeptieren?
			bne	:cancel			; => Nein, weiter...

			lda	#$ff
			sta	dirNotEmpty		;Verzeichnis-Inhalte nicht löschen.

::skip_file		ldx	#$7f			;Rückmeldung: "Nicht löschen".
			rts

::cancel		ldx	curDrive
			lda	RealDrvMode -8,y
			and	#SET_MODE_SUBDIR	;Native-Mode Laufwerk?
			beq	:1			; => Nein, weiter...

			lda	drvUpdFlag		;Laufwerksdaten aktualisieren.
			ora	#%10000000
			sta	drvUpdFlag

			lda	curDirHead +32		;Verzeichnis als "Aktuell" für
			sta	drvUpdSDir +0		;Fenster setzen. Nach Rückkehr
			lda	curDirHead +33		;zu GeoDesk zeigt das Fenster
			sta	drvUpdSDir +1		;die schreibgeschützte Datei an.

::1			ldx	#flagExitCopy		;Rückmeldung: "Abbruch".
			rts

::no_error		ldx	#NO_ERROR		;Rückmeldung: "Löschen".
			rts

;*** Source-Laufwerk öffnen.
;-Laufwerk aktivieren.
;-Partition öffnen.
;-Native-Verzeichnis öffnen.
;-Bei Nicht-CMD/-Native-Laufwerk:
; Diskette öffnen/BAM einlesen.
;-Partition/Verzeichnis für das
; aktuelle Laufwerk speichern.
:OpenSourceDrive	lda	sysSource		;Source-Laufwerk einlesen.
			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			sta	flagOpenDisk		;Flag löschen: "Disk öffnen".

::open_part		lda	sysSource +1		;CMD-Partition definiert?
			beq	:open_sdir		; => Nein, weiter...

			ldx	curDrive		;Ist Partition auf Laufwerk
			cmp	activePart -8,x		;noch aktiv?
			beq	:open_sdir		; => Ja, weiter...
			sta	activePart -8,x		;Neue Partition für Laufwerk.

			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

			ldx	curDrive		;Bei Partitionswechsel immer das
			lda	#$00			;richtige Verzeichnis aktivieren.
			sta	activeNDirTr -8,x
			sta	activeNDirSe -8,x

::open_sdir		lda	sysSource +2		;Native-Verzeichnis definiert?
			beq	:open_disk		; => Nein, weiter...

			ldx	curDrive		;Ist Verzeichnis auf Laufwerk
			cmp	activeNDirTr -8,x	;noch aktiv?
			bne	:1			; => Nein, Verzeichnis öffnen...
			lda	sysSource +3
			cmp	activeNDirSe -8,x
			beq	:open_disk		; => Ja, weiter...

::1			lda	sysSource +2		;Zeiger auf Verzeichnis einlesen
			sta	r1L			;und für ":OpenSubDir" setzen.
			ldy	sysSource +3
			sty	r1H

			ldx	curDrive		;Neues Verzeichnis für Laufwerk.
			sta	activeNDirTr -8,x
			tya
			sta	activeNDirSe -8,x

			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

::open_disk		bit	flagOpenDisk		;Disk geöffnet?
			bmi	:no_error		; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::no_error		ldx	#NO_ERROR
::error			rts

;*** Target-Laufwerk öffnen.
;-Laufwerk aktivieren.
;-Partition öffnen.
;-Native-Verzeichnis öffnen.
;-Bei Nicht-CMD/-Native-Laufwerk:
; Diskette öffnen/BAM einlesen.
;-Partition/Verzeichnis für das
; aktuelle Laufwerk speichern.
:OpenTargetDrive	lda	sysTarget		;Target-Laufwerk einlesen.
			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			sta	flagOpenDisk		;Flag löschen: "Disk öffnen".

::open_part		lda	sysTarget +1		;CMD-Partition definiert?
			beq	:open_sdir		; => Nein, weiter...

			ldx	curDrive		;Ist Partition auf Laufwerk
			cmp	activePart -8,x		;noch aktiv?
			beq	:open_sdir		; => Ja, weiter...
			sta	activePart -8,x		;Neue Partition für Laufwerk.

			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

			ldx	curDrive		;Bei Partitionswechsel immer das
			lda	#$00			;richtige Verzeichnis aktivieren.
			sta	activeNDirTr -8,x
			sta	activeNDirSe -8,x

::open_sdir		lda	sysTarget +2		;Native-Verzeichnis definiert?
			beq	:open_disk		; => Nein, weiter...

			ldx	curDrive		;Ist Verzeichnis auf Laufwerk
			cmp	activeNDirTr -8,x	;noch aktiv?
			bne	:1			; => Nein, Verzeichnis öffnen...
			lda	sysTarget +3
			cmp	activeNDirSe -8,x
			beq	:open_disk		; => Ja, weiter...

::1			lda	sysTarget +2		;Zeiger auf Verzeichnis einlesen
			sta	r1L			;und für ":OpenSubDir" setzen.
			ldy	sysTarget +3
			sty	r1H

			ldx	curDrive		;Neues Verzeichnis für Laufwerk.
			sta	activeNDirTr -8,x
			tya
			sta	activeNDirSe -8,x

			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

::open_disk		bit	flagOpenDisk		;Disk geöffnet?
			bmi	:no_error		; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::no_error		ldx	#NO_ERROR
::error			rts

;*** Verzeichnis auf Source-/Target-Laufwerk öffnen.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;Hinweis:
;Wenn das Verzeichnis auf dem Target-
;Laufwerk nicht existiert, dann wird
;ein neues Verzeichnis erstellt.
;Hinweis #2:
;Wenn Ziel-Laufwerk kein NativeMode-
;Laufwerk ist, dann werden Dateien in
;das Hauptverzeichnis kopiert.
:doOpenDirectory	lda	dirEntryBuf +1		;Tr/Se für neuen Verzeichnis-
			sta	sysSource +2		;Header in Laufwerksdaten speichern.
			lda	dirEntryBuf +2
			sta	sysSource +3

			ldx	sysTarget
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	checkTargetDir		;Ziel-Verzeichnis überprüfen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::1			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

::error			rts

;*** Ziel-Verzeichnis überprüfen.
;    Übergabe: dirEntryBuf = 30Byte Verzeichnis-Eintrag.
;Hinweis:
;Ziel-Laufwerk muss aktiv sein.
;Wenn das Verzeichnis nicht existiert,
;dann wird es neu erstellt.
:checkTargetDir		LoadW	r0,dirEntryBuf +3	;Zeiger auf Verzeichnisname.
			LoadW	r1,newDirName		;Zeiger auf Zwischenspeicher.
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyName		;Name in Zwischenspeicher kopieren.

::1			LoadW	r6,newDirName		;Zeiger auf Verzeichnisname.
			jsr	FindFile		;Verzeichnis auf Disk suchen.
			cpx	#FILE_NOT_FOUND		;Nicht gefunden?
			beq	:2			; => Ja, weiter...
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			bit	GD_REUSE_DIR		;In Verzeichnis kopieren?
			bmi	:3			; => Ja, weiter...

			LoadW	r6,newDirName		;Zeiger auf Verzeichnisname.
			ldx	#$ff			;Neuer Verzeichnisname.
			jsr	GetNewName		;Neuen Namen eingeben.
			txa				;CANCEL?
			bne	:error			; => Ja, Abbruch...

			LoadW	r0,newName		;Zeiger auf Verzeichnisname.
			LoadW	r1,newDirName		;Zeiger auf Zwischenspeicher.
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyName		;Name in Zwischenspeicher kopieren.
			jmp	:1			;Erneut überprüfen.

::2			jsr	MakeNDir		;Verzeichnis erstellen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	r6,newDirName		;Zeiger auf Verzeichnisname.
			jsr	FindFile		;Verzeichnis auf Disk suchen.
			txa				;Gefunden?
			bne	:error			; => Nein, Abbruch...

::3			lda	dirEntryBuf +1		;Zeiger auf Verzeichnis-Header
			sta	sysTarget +2		;einlesen und als aktives
			lda	dirEntryBuf +2		;Verzeichnis für Target-Laufwerk
			sta	sysTarget +3		;speichern.

::error			rts

;*** Eltern-Verzeichnis auf Source-/Target-Laufwerk öffnen.
;Hinweis:
;r1/r5 dürfen nicht verändert werden.
;(:doCopyDir/:GetNxtDirEntry).
:openParentDir		PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			ldx	sysTarget
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	curDirHead +34		;Tr/Se für Eltern-Verzeichnis
			sta	sysTarget +2		;einlesen und in Laufwerksdaten.
			ldx	curDirHead +35		;speichern.
			stx	sysTarget +3

			sta	r1L			;Zeiger auf Eltern-Verzeichnis.
			stx	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Hinweis:
;Routine wird nur von doCopyDir
;aufgerufen, das Source-Laufwerk muss
;also ein NativeMode-Laufwerk sein.
::1			;ldx	sysSource
			;lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			;and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			;beq	:exit			; => Nein, weiter...

			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	curDirHead +34		;Tr/Se für Eltern-Verzeichnis
			sta	sysSource +2		;einlesen und in Laufwerksdaten.
			ldx	curDirHead +35		;speichern.
			stx	sysSource +3

			sta	r1L			;Zeiger auf Eltern-Verzeichnis.
			stx	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

::exit			PopW	r5			;Zeiger auf Verzeichnis-Eintrag für
			PopB	r1H			;":GetNxtDirEntry" zurücksetzen.
			PopB	r1L

			rts

;*** Verzeichnis-Eintrag kopieren.
;    Übergabe: r5 = Verzeichnis-Eintrag.
:copyDirEntry		ldy	#30 -1			;Verzeichnis-Eintrag in
::1			lda	(r5L),y			;Zwischenspeicher kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:1
			rts

;*** Datei-/Verzeichnis-Name kopieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;    Rückgabe: curFileName = Datei-/Verzeichnis-Name.
:copyFileName		LoadW	r10,dirEntryBuf +3
			LoadW	r11,curFileName
			ldx	#r10L
			ldy	#r11L
			jsr	SysCopyName

			ldy	#15			;Kopie des Dateinamens in
::1			lda	curFileName,y		;Zwischenspeicher kopieren.
			sta	origFileName,y		;Wird für Dateien verschieben
			dey				;benötigt um die Datei auf dem
			bpl	:1			;Source-Laufwerk zu löschen.
			rts

;*** Aktuellen Disk-/Verzeichnis-Namen kopieren.
:copyDirName		ldx	#r4L			;Zeiger auf aktuellen
			jsr	GetPtrCurDkNm		;Disk-/Verzeichnis-Namen setzen.

			LoadW	r0,newDirName
			ldx	#r4L
			ldy	#r0L
			jmp	SysCopyName		;Name in Zwischenspeicher kopieren.

;*** Neuen Namen eingeben.
;    Übergabe: r6 = Zeiger auf Name.
;              XREG = $00/$FF für Datei-/Verzeichnisname.
:GetNewName		stx	dlgBoxMode

			LoadW	r10,newName		;Original-Name in
			ldx	#r6L			;Eingabespeicher kopieren.
			ldy	#r10L
			jsr	SysFilterName

			jsr	i_MoveData		;Original-Dateiname speichern.
			w	newName
			w	oldName
			w	16

			jsr	AddSuffix		;Suffix "_x" für neuen Namen.

;--- HINWEIS:
;    Übergabe: r6  = Original Name.
;              r10 = Neuer Name.
::restart		PushW	r6			;Zeiger auf Original-Name sichern.

			lda	#< dlgBox_Text1a
			sta	dlgMsgInfo +0
			lda	#> dlgBox_Text1a
			sta	dlgMsgInfo +1

			ldx	#< Dlg_NewNmDir		;Neuer Verzeichnisname.
			ldy	#> Dlg_NewNmDir
			lda	dlgBoxMode
			bmi	:0

			pha

			lda	#< dlgBox_Text1b	;Neuer Dateiname ohne "Löschen".
			sta	dlgMsgInfo +0
			lda	#> dlgBox_Text1b
			sta	dlgMsgInfo +1

			pla
			bne	:0

			ldx	#< Dlg_NewNmFile	;Neuer Dateiname mit "Löschen".
			ldy	#> Dlg_NewNmFile

::0			stx	r0L
			sty	r0H
			jsr	DoDlgBox		;Neuen Namen eingeben.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

			PopW	r6			;Zeiger Original-Name zurücksetzen.

			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt?
			beq	:cancel			; => Ja, Ende...

			cmp	#YES			;Datei überschreiben?
			beq	:delete			; => Ja, weiter...
			cmp	#NO			;Datei überspringen?
			beq	:skip			; => Ja, weiter...

			ldy	#$00			;Alter/Neuer Name vergleichen.
::1			lda	(r6L),y
			cmp	newName,y
			bne	:ok
			tax
			beq	:ok
			iny
			cpy	#16
			bcc	:1
			bcs	:restart		; => Name unverändert, Neustart...

::ok			ldx	#NO_ERROR		;Neuer Name OK.
			b $2c
::skip			ldx	#flagSkipFile		;Datei überspringen.
			b $2c
::delete		ldx	#flagDelFile		;Datei löschen.
			b $2c
::cancel		ldx	#flagExitCopy		;Abbruch gewählt.
			rts

;*** Suffix "_1", "_2"... anhängen.
;Suffix an Name anhängen.
;-Name < 2 Zeichen:
; Suffix wird angehängt.
;-Name < 14 Zeichen:
; Die letzten beiden Zeichen werden
; auf ein Suffix geprüft. Bei einem
; Suffix wird der Zähler erhöht.
;-Name >= 15 Zeichen:
; Die letzten beiden Zeichen werden
; mit dem Suffix überschrieben.
;
;Der Suffix wird nur von "0" bis "8"
;erhöht. Ist der Suffix "_9", dann
;wird der Suffix zurückgesetzt.
;
:AddSuffix		ldy	#$00			;Ende Dateiname suchen.
::1			lda	newName,y		;Ende erreicht?
			beq	:2			; => Ja, weiter...
			iny				;Weitersuchen.
			cpy	#16 +1			;Ende erreicht?
			bcc	:1			; => Nein, weiter...

::2			cpy	#2			;Weniger als 3 Zeichen?
			bcc	:5			; => Ja, weiter...

			lda	newName -2,y		;Letztes Zeichen einlesen.
			cmp	#"_"			;Zeichen <> "_"?
			bne	:3			; => Ja, neuer Suffix.

			ldx	newName -1,y		;Suffix einlesen.
			cpx	#"0"			;Suffix < "0"?
			bcc	:3			; => Ja, neuer Suffix.
			cpx	#"9"			;Suffix >= "9"?;
			bcs	:3			; => Ja, neuer Suffix.

			dey				;Zeiger auf Suffix korrigieren.

			inx				;Suffix +1.
			bne	:6

::3			cpy	#14 +1			;Max. 14 Zeichen?
			bcc	:5			; => Nein, weiter...
			ldy	#14			;Die letzten 2 Zeichen ersetzen.

::5			ldx	#"0"			;Neuen Suffix schreiben.
			lda	newName -1,y
			cmp	#"_"
			beq	:6
			lda	#"_"
			sta	newName,y
			iny
::6			txa
			sta	newName,y

			lda	#$00			;Rest des Namens löschen.
::7			iny
			sta	newName,y
			cpy	#16
			bcc	:7
			rts

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.
:flagMoveFiles		b $00				;$FF = Dateien verschieben.
:flagMoveDirEntry	b $00
:flagDuplicate		b $00
:curDirHeader		b $00,$00			;Tr/Se für aktuellen Dir-Header.
:curFileName		s 17				;Name Target-Datei, evtl. +Suffix.
:origFileName		s 17				;Name der Source-Datei.
:newName		s 17
:oldName		s 17
:newDirName		s 17
:dlgBoxMode		b $00
:dirNotEmpty		b $00				;Datei schreibgeschützt.
							;Eltern-Verzeichnis nicht löschen.

;*** Variablen für Kopierroutine.
:NxFreeSek		b $00,$00

:StartVarMem		;--- Start Variablenspeicher.
:FreeSekBuf		b $00,$00 ;Erster Sektor VLIR-Datensatz.
:NextSekBuf		b $00,$00 ;Nächster freier Sektor.
:EndOfData		b $00     ;$FF = Datensatz vollständig.
:ContinueCopy		b $00     ;$00 = Datensatz weiterlesen.
:DataCopied		b $00     ;$FF = Daten im Speicher.
:WriteCurRec		b $00     ;Zeiger auf aktuellen Datensatz.
:LastReadRec		b $00     ;Zeiger auf nächsten Datensatz.
:jobDirEntry		s 30      ;Speicher für Verzeichniseintrag.
:File1Len		w $0000   ;Dateilänge Quelldatei.
:File2Len		w $0000   ;Dateilänge Zieldatei.
:EndVarMem		;--- Ende Variablenspeicher.

;*** Partition/Verzeichnisse für Laufwerk A: bis D:
:activePart		b $00,$00,$00,$00
:activeNDirTr		b $00,$00,$00,$00
:activeNDirSe		b $00,$00,$00,$00

;*** Startverzeichnis Quelle/Ziel.
:SourceSDirOrig		b $00,$00
:TargetSDirOrig		b $00,$00

;*** Datum/Zeit für Quell-/Ziel-Vergleich.
:sourceDate		b $00,$00,$00,$00,$00,$00
:targetDate		b $00,$00,$00,$00,$00,$00

;*** Flag für "Disk geöffnet".
;OpenPartition und OpenSubDir öffnen
;die aktuelle Diskette bereits.
;Ist dieses Flag gesetzt, dann wird
;OpenDisk übersprungen.
:flagOpenDisk		b $00

;*** Hinweis: Ziel-Laufwerk unterstützt keine Verzeichnisse.
:Dlg_NMD_Warn		b %01100001
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
			b DBTXTSTR   ,$0c,$3e
			w :4
			b DBTXTSTR   ,$0c,$4a
			w :5
			b YES        ,$01,$50
			b NO         ,$09,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Ziel-Laufwerk unterstützt keine",NULL
::3			b "NativeMode-Unterverzeichnisse!",NULL
::4			b "Nur Verzeichnisinhalte kopieren?",NULL
::5			b "(Max: 1541/71=144, 1581=288 Dateien)",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The target drive does not support",NULL
::3			b "NativeMode subdirectories!",NULL
::4			b "Only copy files from this directory?",NULL
::5			b "(Max: 1541/71=144, 1581=288 files)",NULL
endif

;*** Neuen Verzeichnisnamen eingeben.
:Dlg_NewNmDir		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
:dlgMsgInfo		w dlgBox_Text1a
			b DBTXTSTR   ,$0c,$2b
			w dlgBox_Text2
			b DBTXTSTR   ,$30,$2b
			w oldName
			b DBTXTSTR   ,$0c,$3a
			w dlgBox_Text3
			b DBTXTSTR   ,$0c,$45
			w dlgBox_Text2
			b DBGETSTRING,$30,$45 -6
			b r10L,16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
;			b DBTXTSTR   ,$3b,$5c
;			w dlgBox_Text6
			b DBTXTSTR   ,$0c,$56
			w dlgBox_Text4
			b CANCEL     ,$11,$50
			b NULL

;*** Neuen Dateinamen eingeben.
:Dlg_NewNmFile		b %01100001
			b $18,$a7
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel2
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w dlgBox_Text1b
			b DBTXTSTR   ,$0c,$2b
			w dlgBox_Text2
			b DBTXTSTR   ,$30,$2b
			w oldName
			b DBTXTSTR   ,$0c,$3a
			w dlgBox_Text3
			b DBTXTSTR   ,$0c,$45
			w dlgBox_Text2
			b DBGETSTRING,$30,$45 -6
			b r10L,16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
;			b DBTXTSTR   ,$3b,$5c
;			w dlgBox_Text6
			b DBTXTSTR   ,$0c,$57
			w dlgBox_Text4
			b CANCEL     ,$11,$50

			b DBTXTSTR   ,$0c,$62
			w dlgBox_Text4a
			b DBTXTSTR   ,$0c,$74
			w dlgBox_Text5
			b YES        ,$01,$78
			b DBTXTSTR   ,$3b,$84
			w dlgBox_Text7
			b NO         ,$11,$78
			b NULL

if LANG = LANG_DE
:dlgBox_Text1a		b PLAINTEXT
			b "Das Verzeichnis existiert bereits!"
			b NULL
:dlgBox_Text1b		b PLAINTEXT
			b "Die folgende Datei existiert bereits!"
			b NULL
:dlgBox_Text2		b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
:dlgBox_Text3		b "Bitte neuen Namen eingeben:"
			b NULL
:dlgBox_Text4		b BOLDON
			b "Weiter mit 'RETURN'"
			b PLAINTEXT,NULL
:dlgBox_Text4a		b "oder alternativ:"
			b NULL
:dlgBox_Text5		b BOLDON
			b "Die vorhandene Datei löschen?"
			b PLAINTEXT,NULL
:dlgBox_Text7		b PLAINTEXT
			b "(Löschen)"
			b NULL
endif
if LANG = LANG_EN
:dlgBox_Text1a		b PLAINTEXT
			b "The directory does already exist!"
			b NULL
:dlgBox_Text1b		b PLAINTEXT
			b "The file does already exists!"
			b NULL
:dlgBox_Text2		b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
:dlgBox_Text3		b "Please enter a new name:"
			b NULL
:dlgBox_Text4		b BOLDON
			b "Continue with 'RETURN'"
			b PLAINTEXT,NULL
:dlgBox_Text4a		b "Alternatively:"
			b NULL
:dlgBox_Text5		b BOLDON
			b "Delete existing file?"
			b PLAINTEXT,NULL
:dlgBox_Text7		b PLAINTEXT
			b "(Delete)"
			b NULL
endif

;*** Fehler: Datei ist Schreibgeschützt.
:Dlg_ErrWrProt		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w curFileName
			b DBTXTSTR   ,$0c,$40
			w :4
			b NO         ,$01,$50
			b CANCEL     ,$11,$50
			b YES        ,$09,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Datei ist schreibgeschützt!",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Schreibschutz ignorieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The file is write protected!",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Ignore write protection?",NULL
endif

;*** Startadresse Dateinamen.
:SYS_FNAME_BUF		;s MAX_DIR_ENTRIES * 17

;*** Startadresse Kopierspeicher.
:Memory1		= SYS_FNAME_BUF + (MAX_DIR_ENTRIES * 17)
:Memory2		= (Memory1 / 256 +1)*256
:Copy1Sek		= Memory2
:StartBuffer		= Memory2 +256
:EndBuffer		= OS_BASE ;$8000

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Dateinamen und Kopierspeicher
;verfügbar ist.
			g OS_BASE -(MAX_DIR_ENTRIES * 17) -$2000
;***
