; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien/Verzeichnisse kopieren/verschieben.
:xFILE_COPYMOVE		php				;Tastaturabfrage:
			sei				;Linke SHIFT + C= -Taste für
			ldx	CPU_DATA		;Dateien verschieben.
			lda	#$35
			sta	CPU_DATA
			ldy	#%01111101
			sty	CIA_PRA
			ldy	CIA_PRB
			stx	CPU_DATA
			plp

			ldx	#$00			;Modus: Dateien kopieren.
			cpy	#%01011111		;SHIFT + C= gedrückt?
			bne	:copy			; => Nein, weiter...
::move			dex				;Modus: Dateien verschieben.
::copy			stx	flagMoveFiles		;Kopiermodus speichern.

			jsr	COPY_FILE_NAMES		;Dateinamen in Speicher kopieren.

			ldx	slctFiles		;Dateien ausgewählt?
			beq	ExitCopyMove		; => Nein, Ende...
			stx	statusMax		;Max.Anzahl Dateien für Statusbox.

			jsr	GetSrcDrvData		;Daten Source-Laufwerk einlesen.
			jsr	GetTgtDrvData		;Daten Target-Laufwerk einlesen.

			jsr	doCopyMoveJob		;Dateien löschen.
			txa				;Fehler?
			beq	ExitCopyMove		; => Nein, Ende...
			cpx	#$ff			;Abbruch?
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
			pha
			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.
			pla
			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

;*** Zurück zum DeskTop.
:ExitCopyMove		;jsr	WM_LOAD_BACKSCR		;Status-Box löschen.

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

;*** Dateien/Verzeichnisse kopieren/verschieben.
:doCopyMoveJob		ClrB	statusPos		;Zeiger auf erste Datei.
			jsr	DrawStatusBox		;Statusbox aufbauen.

			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

			LoadB	reloadDir,$ff		;GeoDesk: Verzeichnis neu laden.

			LoadW	r15,SYS_FNAME_BUF	;Zeiger auf Anfang Dateiliste.

			sei
			clc				;Mauszeigerposition nicht ändern.
			jsr	StartMouseMode		;Mausabfrage starten.
			cli				;Interrupt zulassen.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

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

			lda	SourceMode		;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode Laufwerk?
			beq	:is_file		; => Nein, weiter...

			lda	dirEntryBuf
			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis?
			beq	:is_dir			; => Ja, weiter...

;--- Datei kopieren.
::is_file		jsr	doCopyFile		;Einzelne Datei kopieren.
			jmp	:test_error

;--- Verzeichnis kopieren.
::is_dir		lda	TargetMode		;Laufwerksmodus einlesen.
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
			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			PopW	r15			;Zeiger auf Dateiliste sichern.

			lda	sysDBData
			cmp	#NO			;Nicht kopieren?
			beq	:next_file		; => Ja, Verzeichnis überspringen.
			cmp	#YES			;Dateien kopieren oder Abbruch?
			beq	:copy_files		; => Kopieren, weiter...
;			bne	:exit			; => Abbruch, Ende...

;--- Ende oder Disk-Fehler.
::exit			inc	statusPos		;100% Fortschrittsanzeige.
			jsr	prntStatus		;Statusanzeige aktualisieren.
			jsr	sysPrntStatus		;Fortschrittsbalken aktualisieren.

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
;			cpx	#$ff			;Abbruch bei "Schreibschutz"?
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

			jsr	prntStatus		;Statusanzeige.
			jsr	clrFStructInfo		;Anzeige Dateistruktur zurücksetzen.
			jsr	sysPrntStatus		;Fortschrittsbalken aktualisieren.

			jsr	testCopyMode		;Kopiermodus ermitteln.

			jsr	checkTargetFile		;Datei auf Target-Laufwerk suchen.
			cpx	#$fd			;Datei überspringen?
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
			and	#FTYPE_MODES		;Dateityp einlesen.
			cmp	#FTYPE_DIR		;Verzeichnis?
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

			bit	GD_SKIP_EXISTING	;Automatisch überspringen?
			bmi	:skipExisting		; => Ja, weiter...
			bit	GD_OVERWRITE_FILES
			bpl	:overwriteName		; => Dateien nicht überschreiben.

;--- Verzeichnisse nicht überschreiben.
::deleteExisting	lda	dirEntryBuf		;Dateityp einlesen.
			and	#FTYPE_MODES
			cmp	#FTYPE_DIR		;Verzeichnis?
			bne	:deleteFile		; => Nein, weiter...

::skipDirectory		lda	#<curFileName		;Dateiname in Zwischenspeicher
			sta	r0L			;kopieren, da die Status-Routine
			lda	#>curFileName		;evtl. den Bereich mit dem Datei-
			sta	r0H			;namen überschreibt
			lda	#<dataFileName
			sta	r1L
			sta	errDrvInfoF +0
			lda	#>dataFileName
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
			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.

			LoadB	errDrvCode,$86		;"SKIP_DIRECTORY"
			jsr	SUB_STATMSG		;Statusmeldung ausgeben.

			jsr	DrawStatusBox		;Statusbox wieder herstellen.
			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

			jmp	:skip			;Verzeichnis überspringen.

::deleteFile		LoadW	r0,curFileName		;Zeiger auf Datei-Name und
			jmp	DeleteFile		;Datei löschen.
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

::replaceOlder		bit	GD_OVERWRITE_FILES
			bmi	:deleteExisting		; => Dateien überschreiben.

::overwriteName		ldx	#$00			;Neuer Dateiname mit "Löschen".
			b $2c
::duplicateName		ldx	#$7f			;Neuer Dateiname ohne "Löschen".
			LoadW	r6,curFileName		;Zeiger auf Datei-Name.
			jsr	GetNewName		;Neuen Namen eingeben.
			cpx	#$ff			;CANCEL?
			beq	:exit			; => Ja, Abbruch...
			cpx	#$fe			;Existierende Datei löschen?
			beq	:deleteExisting		; => Ja, weiter...
			cpx	#$fd			;Datei überspringen?
			beq	:exit			; => Ja, weiter...
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r0,newName		;Zeiger auf neuen Namen.
			LoadW	r1,curFileName		;Zeiger auf Target-Dateiname.
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyName		;Name in Zwischenspeicher kopieren.
			jmp	:checkTgtAgain		;Erneut testen.

::skip			ldx	#$fd			;Datei überspringen.
::exit			rts

;*** Verzeichnis kopieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;Hinweis: Die Routine kopiert rekursiv
;alle Dateien und weiteren Unterver-
;zeichnisse im gewählten Verzeichnis.
:doCopyDir		jsr	doOpenDirectory		;Verzeichnis Source/Target öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	prntDiskInfo		;Verzeichnisname ausgeben.

;--- Zeiger auf Anfang Verzeichnis.
			jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
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
			and	#FTYPE_MODES		;"Gelöscht"?
			beq	:next_entry		; => Ja, nächste Datei...

			jsr	copyDirEntry		;Verzeichnis-Eintrag in
							;Zwischenspeicher kopieren.

			lda	dirEntryBuf
			and	#FTYPE_MODES		;Dateityp einlesen.
			cmp	#FTYPE_DIR		;Verzeichnis?
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
::next_entry		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
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
::exit			jsr	prntDiskInfo		;Verzeichnisname zurücksetzen.

			ldx	#NO_ERROR		;Kein Fehler, Ende...
			rts

;*** Kopieren abbrechen.
;Zurück zum ersten Verzeichnis.
:cancelDirCopy		jsr	OpenTargetDrive		;Source-Laufwerk öffnen.

			lda	TargetMode		;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			lda	TargetSDirOrig +0	;Eltern-Verzeichnis vom
			sta	r1L			;aktuellen Verzeichnis öffnen.
			lda	TargetSDirOrig +1
			sta	r1H
			jsr	OpenSubDir

::1			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.

			lda	TargetMode		;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:2			; => Nein, weiter...

			lda	SourceSDirOrig +0	;Eltern-Verzeichnis vom
			sta	r1L			;aktuellen Verzeichnis öffnen.
			lda	SourceSDirOrig +1
			sta	r1H
			jsr	OpenSubDir

::2			ldx	#$ff			;Kopieren abbrechen.
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

;--- SYS_COPYFNAME:
;slctFiles		b $00
;--- Siehe VLIR-Header:
;SYS_FNAME_BUF		s MAX_DIR_ENTRIES * 17

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.
:flagMoveFiles		b $00				;$FF = Dateien verschieben.
:flagMoveDirEntry	b $00
:flagDuplicate		b $00

;*** Aktuelle Datei.
:curFileName		s 17				;Name Target-Datei, evtl. +Suffix.
:origFileName		s 17				;Name der Source-Datei.

;*** Aktuelles Verzeichnis.
:curDirHeader		b $00,$00			;Tr/Se für aktuellen Dir-Header.

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
