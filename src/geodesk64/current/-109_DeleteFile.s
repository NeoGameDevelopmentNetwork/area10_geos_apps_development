; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien/Verzeichnisse löschen.
:doDeleteJob		jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			LoadB	statusPos,$00		;Zeiger auf erste Datei.
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

			LoadB	reloadDir,$ff		;GeoDesk: Verzeichnis neu laden.
			ClrB	delDirFiles		;Abfrage: Verzeichnisse löschen?

			LoadW	r15,SYS_FNAME_BUF	;Zeiger auf Anfang Dateiliste.

			MoveB	slctFiles,r14H		;Dateizähler löschen.
			sta	statusMax		;Max.Anzahl Dateien für Statusbox.

			sei
			clc				;Mauszeigerposution nicht ändern.
			jsr	StartMouseMode		;Mausabfrage starten.
			cli				;Interrupt zulassen.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

;--- Schleife: Einträge löschen.
::loop			lda	pressFlag		;Kopieren abbrechen?
			bne	:exit			; => Ja, Ende...

			ClrB	dirNotEmpty		;Flag: Verzeichnis leer.

			MoveW	r15,r6			;Zeiger auf Dateiname.
			jsr	FindFile		;Aktuelle Datei suchen.
			txa				;Datei Gefunden?
			bne	:error			; => Nein, Abbruch...

			MoveW	r15,r0			;Zeiger auf Dateiname.

			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Aktuelles Laufwerk einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode Laufwerk?
			beq	:is_file		; => Nein, weiter...

			lda	dirEntryBuf
			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis?
			beq	:is_dir			; => Ja, weiter...

;--- Datei löschen.
::is_file		jsr	doDeleteFile		;Datei löschen.
			jmp	:test_error

;--- Verzeichnis löschen.
::is_dir		lda	dirEntryBuf +1		;Tr/Se für Verzeichnis-Header
			sta	curDirHeader +0		;als Startverzeichnis speichern.
			lda	dirEntryBuf +2
			sta	curDirHeader +1
			jsr	doDeleteDir		;Verzeichnis löschen.

;--- Datei/Verzeichnis gelöscht.
::test_error		cpx	#$ff			;Abbruch bei "Schreibschutz"?
			beq	:exit			; => Ja, Ende...

			cpx	#$7f			;Datei nicht löschen?
			beq	:next_file		; => Ja, nächste Datei...

			txa				;Laufwerksfehler?
			bne	:error			; => Nein, weiter...

;--- Weiter mit nächster Datei.
::next_file		AddVBW	17,r15			;Zeiger auf nächste Datei.

			inc	statusPos
			jsr	sysPrntStatus		;Fortschrittsbalken aktualisieren.

			dec	r14H			;Alle Dateien gelöscht?
			beq	:exit			; => Ja, Ende...

			jmp	:loop			; => Nein, weiter...

;--- Ende oder Disk-Fehler.
::exit			ldx	#NO_ERROR
::error			rts				;"Datei kopieren" beenden.

;*** CBM-Datei löschen.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
:doDeleteFile		jsr	copyDirEntry		;Verzeichnis-Eintrag in
							;Zwischenspeicher kopieren.

			jsr	copyFileName		;Dateiname kopieren.

			jsr	testWrProtOn		;Schreibschutz testen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
			bmi	:1			; => Abbruch, Ende...
			ldx	#NO_ERROR		;Schreibschutz-Datei nicht löschen.
::1			rts				;Ende.

;--- Datei löschen.
::2			ldx	#$00			;Flag "Datei löschen".
;			jmp	freeCurFile		;Aktuelle Datei löschen.

;*** Aktuellen Verzeichnis-Eintrag löschen.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;              XREG = $00/Datei, $FF/Verzeichnis.
;              r1L/r1H = Tr/Se Verzeichnis-Sektor.
;              r5 = Zeiger auf Verzeichnis-Eintrag in Verzeichnis-Sektor.
;Hinweis: r1/r5 dürfen nicht verändert
;werden (:doDeleteDir/:GetNxtDirEntry).
:freeCurFile		PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			jsr	prntStatus		;Verzeichnis/Datei anzeigen.

			LoadW	r9,dirEntryBuf		;Zeiger auf Datei-Eintrag.
			jsr	FreeFile		;Datei löschen.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			txa				;Fehlerstatus speichern.
			pha

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher setzen.
			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			tay				;Dateityp "Gelöscht" setzen.
			sta	(r5L),y
			jsr	PutBlock		;Verzeichnis-Sektor schreiben.

::1			pla				;Fehlerstatus zurücksetzen.

;--- Fehler Verzeichniseintrag?
			cpx	#NO_ERROR		;Fehler?
			bne	:2			; => Ja, Abbruch...

;--- Fehler Datei löschen?
			tax				;Fehler?
			beq	:2			; => Nein, Ende...

			lda	dirEntryBuf +22		;GEOS-Dateityp einlesen.
			cmp	#TEMPORARY		;Typ Swap_File ?
			bne	:2			; => Nein, weiter...
			cpx	#BAD_BAM		;Fehler "BAD_BAM" ?
			bne	:2			; => Nein, weiter...
			ldx	#NO_ERROR		; => "BAD_BAM" ignorieren.
::2			rts

;*** Verzeichnis löschen.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;Hinweis: Die Routine löscht rekursiv
;alle Dateien und weiteren Unterver-
;zeichnisse im gewählten Verzeichnis.
:doDeleteDir		bit	GD_DEL_MENU		;Dateien ohne Nachfrage löschen?
			bpl	:initDelDir		; => Nein, weiter...

			bit	GD_DEL_EMPTY		;Nur leere Verzeichnisse löschen?
			bmi	:initDelDir		; => Ja, weiter...

			lda	delDirFiles		;Verzeichnis-Inhalte löschen?
			bne	:initDelDir		; => Bereits definiert, weiter...

;--- Abfrage: Dateien in Verzeichnissen automatisch löschen?
			LoadB	delDirFiles,$ff		;Inhalte in Verz. nicht löschen.

			LoadW	r0,Dlg_AskDelDir	;Abfrage:
			jsr	DoDlgBox		;Verzeichnis-Inhalte löschen?

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			lda	sysDBData		;Ergebnis auswerten.
			cmp	#YES			;"Automatisch löschen"?
			bne	:initDelDir		; => Nein, weiter...

			LoadB	delDirFiles,$7f		;Verzeichnis-Inhalte löschen.

;--- Inhalte in Verzeichnis löschen.
::initDelDir		lda	dirEntryBuf +1		;Tr/Se auf Verzeichnis-Header
			sta	r1L			;einlesen.
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

;--- Zeiger auf Anfang Verzeichnis.
			jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:delDirEntry		; => Ja, weiter...

;--- Verzeichnis-Eintrag auswerten.
::loop			lda	pressFlag		;Taste gedrückt?
			beq	:0			; => Nein, weiter...
			jmp	:cancelDirDelete	;Dateien löschen abbrechen...

::0			ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			and	#FTYPE_MODES		;"Gelöscht"?
			beq	:next_file		; => Ja, nächste Datei...

			lda	delDirFiles		;Verzeichnisinhalt löschen?
			bmi	:skip_dir		; => Nein, nächste Datei.

			bit	GD_DEL_EMPTY		;Nur "Leere Verzeichnisse" löschen?
			bpl	:deleteDir		; => Nein, weiter...

;--- Verzeichnis nicht leer.
;Aktuelles Verzeichnis nicht löschen.
::skip_dir		jsr	reloadDirEntry		;Zeiger auf Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	openParentDir		;Eltern-Verzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			jmp	:exitDirectory		;Das Verzeichnis überspringen und
							;weiter mit nächstem Datei-Eintrag.

;--- Verzeichnis nicht leer.
;Modus: Auch nicht-leere-Verzeichnisse
;       löschen.
::deleteDir		jsr	copyDirEntry		;Verzeichnis-Eintrag in
							;Zwischenspeicher kopieren.

			jsr	copyFileName		;Dateiname kopieren.

			jsr	testWrProtOn		;Schreibschutz testen.
			txa
			beq	:1
			bmi	:error
			bne	:next_file

::1			lda	dirEntryBuf
			and	#FTYPE_MODES		;Dateityp einlesen.
			cmp	#FTYPE_DIR		;Verzeichnis?
			bne	:2			; => Nein, Datei löschen.

;--- Weiteres Unterverzeichnis löschen.
			jmp	doDeleteDir		;Verzeichnis Rekursiv löschen.

;--- Disk-Fehler, Abbruch.
::error			rts

;--- Datei im Verzeichnis löschen.
::2			ldx	#$ff
			jsr	freeCurFile		;Aktuelle Datei löschen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Weiter mit nächsten Eintrag,
::next_file		jsr	GetNxtDirEntry
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Verzeichnis-Eintrag löschen.
;An dieser Stelle die alle Dateien im
;aktuellen Unterverzeichnis gelöscht.
;Hier wird jetzt das Unterverzeichnis
;selbst gelöscht.
::delDirEntry		jsr	testDirEmpty		;Auf leeres Verzeichnis prüfen.

			jsr	reloadDirEntry		;Verzeichnis-Eintrag einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldx	dirNotEmpty		;Verzeichnis leer?
			bmi	:3			; => Nein, löschen überspringen.

			jsr	doDeleteFile		;Verzeichnis-Eintrag selbst löschen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::3			jsr	openParentDir		;Eltern-Verzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Verzeichnis-Ende erreicht.
::exitDirectory		ldy	#$01			;Zuerst gewähltes Verzeichnis
			lda	(r5L),y			;gelöscht oder Unterverzeichnis?
			cmp	curDirHeader +0
			bne	:9
			iny
			lda	(r5L),y
			cmp	curDirHeader +1
			beq	:exit			; => Verzeichnis gelöscht.

::9			jmp	:next_file		; => Weiter im Unterverzeichnis.

;--- Verzeichnis bearbeitet.
::exit			jsr	prntDiskInfo		;Verzeichnisname zurüksetzen.

			ldx	#NO_ERROR
			rts				;Ende.

;--- Kopieren abbrechen.
;Zurück zum ersten Verzeichnis.
::cancelDirDelete	lda	curDirHeader +0		;Zum ersten Verzeichnis zurück.
			sta	r1L
			lda	curDirHeader +1
			sta	r1H
			jsr	OpenSubDir

			lda	curDirHead +34		;Eltern-Verzeichnis vom
			sta	r1L			;aktuellen Verzeichnis öffnen.
			lda	curDirHead +35
			sta	r1H
			jsr	OpenSubDir

			ldx	#$ff			;Kopieren abbrechen.
			rts

;*** Aktuelles Verzeichnis testen.
;Wenn Verzeichnis nicht leer, dann
;Hinweis anzeigen.
:testDirEmpty		bit	dirNotEmpty		;Verzeichnis leer?
			bpl	:1			; => Ja, weiter...

			jsr	copyDirName		;Verzeichnisname kopieren.

			LoadW	r0,Dlg_dirNEmpty	;Fehler ausgeben:
			jsr	DoDlgBox		;"Verzeichnis nicht leer".

::1			rts				;Ende.

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

;*** Eltern-Verzeichnis öffnen.
;Hinweis: r1/r5 dürfen nicht verändert
;werden (:doDeleteDir/:GetNxtDirEntry).
:openParentDir		PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			lda	curDirHead +34		;Zurück zum vorherigen
			sta	r1L			;Verzeichnis.
			lda	curDirHead +35
			sta	r1H
			jsr	OpenSubDir

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
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
			jmp	SysFilterName

;*** Aktuellen Disk-/Verzeichnis-Namen kopieren.
:copyDirName		ldx	#r4L			;Zeiger auf aktuellen
			jsr	GetPtrCurDkNm		;Disk-/Verzeichnis-Namen setzen.

			LoadW	r0,curDirName
			ldx	#r4L
			ldy	#r0L
			jmp	SysFilterName		;Name in Zwischenspeicher kopieren.

;*** Auf Schreibschutz testen.
:testWrProtOn		lda	dirEntryBuf		;Dateityp einlesen.
			and	#%0100 0000		;Schreibschtu aktiv?
			beq	:no_error		; => Nein, weiter...

			PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			LoadW	r0,Dlg_ErrWrProt	;Fehler ausgeben:
			jsr	DoDlgBox		;"Datei schreibgeschützt".

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			lda	sysDBData		;Auf Schreibschutz testen.
			cmp	#YES			;Schreibschutz ignorieren?
			beq	:no_error		; => Ja, Datei löschen.

			cmp	#NO			;Schreibschutz übernehmen?
			bne	:cancel			; => Nein, weiter...

			lda	#$ff
			sta	dirNotEmpty		;Verzeichnis-Inhalte nicht löschen.

::skip_file		ldx	#$7f			;Rückmeldung: "Nicht löschen".
			rts

::cancel		ldx	WM_WCODE
			ldy	WIN_DRIVE,x
			lda	RealDrvMode -8,y
			and	#%0100 0000
			beq	:1

			lda	curDirHead +32		;Zurück zum aktuellen
			sta	WIN_SDIR_T,x		;Verzeichnis.
			lda	curDirHead +33
			sta	WIN_SDIR_S,x

::1			ldx	#$ff			;Rückmeldung: "Abbruch".
			rts

::no_error		ldx	#NO_ERROR		;Rückmeldung: "Löschen".
			rts

;*** Seite wechseln.
:SwitchPage		sec				;Y-Koordinate der Maus einlesen.
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
::111			ldx	switchFile
			cpx	#$ff
			beq	:112
			inx
			cpx	slctFiles
			bcc	:131
::112			ldx	#$00
			beq	:131

;*** Zurück zur letzten Seite.
::121			ldx	switchFile
			beq	:122
			cpx	#$ff
			beq	:122
			bne	:123
::122			ldx	slctFiles
::123			dex

::131			stx	switchFile

			stx	r0L
			LoadB	r1L,17
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

			lda	r0L
			clc
			adc	#<SYS_FNAME_BUF
			sta	curFileVec +0
			lda	r0H
			adc	#>SYS_FNAME_BUF
			sta	curFileVec +1

;*** Datei-Informationen einlesen.
:ResetFileInfo		lda	curFileVec +0		;Zeiger auf aktuellen
			sta	r6L			;Dateinamen setzen.
			lda	curFileVec +1
			sta	r6H

			LoadW	r7,curFileName

			ldx	#r6L			;Aktuellen Dateinamen in
			ldy	#r7L			;Zwischenspeicher kopieren.
			jsr	SysFilterName

			jmp	RegisterNextOpt

;*** Aktuelle Datei.
:switchFile		b $00				;Nummer aktuelle Datei.

;--- SYS_COPYFNAME:
;slctFiles		b $00
;--- Siehe VLIR-Header:
;SYS_FNAME_BUF		s MAX_DIR_ENTRIES * 17

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.
:dirNotEmpty		b $00
:delDirFiles		b $00

;*** Aktuelle Datei.
:curFileVec		w $0000				;Zeiger auf aktuelle Datei.
:curFileName		s 17
:curDirHeader		b $00,$00			;Tr/Se für aktuellen Dir-Header.
:curDirName		s 17

;*** Texte.
if LANG = LANG_DE
:multipleFiles		b "MEHRFACH-AUSWAHL",NULL
endif
if LANG = LANG_EN
:multipleFiles		b "MULTIPLE FILES",NULL
endif

;*** Fehler: Datei ist Schreibgeschützt.
:Dlg_ErrWrProt		b %01100001
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

;*** Fehler: Verzeichnis kann nicht gelöscht werden.
:Dlg_dirNEmpty		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w curDirName
			b DBTXTSTR   ,$0c,$40
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Verzeichnis ist nicht leer!",BOLDON,NULL
::3			b PLAINTEXT
			b "Verzeichnis wird nicht gelöscht.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Directory is not empty!",BOLDON,NULL
::3			b PLAINTEXT
			b "The directory will not be deleted.",NULL
endif

;*** Frage: Verzeichnis rekursiv löschen?
:Dlg_AskDelDir		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2e
			w :3
			b NO         ,$11,$50
			b YES        ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Dateien in Unterverzeichnissen",NULL
::3			b "automatisch löschen?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Delete files in subdirectories",NULL
::3			b "automatically?",NULL
endif
