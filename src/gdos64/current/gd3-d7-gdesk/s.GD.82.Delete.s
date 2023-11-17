; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei löschen.

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
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

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
:INFO_Y1		= STATUS_Y +26
:INFO_Y2		= STATUS_Y +36
:INFO_Y3		= STATUS_Y +46
endif

;*** GEOS-Header.
			n "obj.GD82"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xFILE_DELETE

;*** Programmroutinen.
			t "-Gxx_CopyFSlct"
			t "-Gxx_NxtDirEntry"
			t "-Gxx_IBoxCore"
			t "-Gxx_IBoxDisk"
			t "-Gxx_IBoxFile"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Dateien löschen.
:xFILE_DELETE		php				;Tastaturabfrage:
			sei				;Linke/Rechte SHIFT-Taste für
			ldx	CPU_DATA		;Dateien duplizieren.
			lda	#$35
			sta	CPU_DATA
			ldy	#%00111101
			sty	cia1base +0
			ldy	cia1base +1
			stx	CPU_DATA
			plp

			sty	delKeyMode		;Tastenstatus zwischenspeichern.

			cpy	#%11011111		;C= Taste gedrückt?
			bne	:1

			lda	#$00			;C= Taste gedrückt...
			sta	GD_DEL_MENU		;AutoDelete-Flag löschen.

::1			jsr	_ext_CopyFSlct		;Dateinamen in Speicher kopieren.

			LoadB	switchFile,$00		;Zeiger auf erste Datei.
			LoadW	curFileVec,SYS_FNAME_BUF

			ldx	slctFiles		;Dateien ausgewählt?
			beq	ExitRegMenuUser		; => Nein, Ende...
			dex				;Mehr als 1 Datei?
			beq	:do_single		; => Ja, weiter...

;--- Mehrere Dateien löschen.
::do_multiple		jsr	i_MoveData		;Vorgabe: "Mehrere Dateien löschen".
			w	multipleFiles
			w	curFileName
			w	16

			lda	#$ff
			bne	:2

;--- Einzelne Datei löschen.
::do_single		jsr	i_MoveData		;Vorgabe: "Einzelne Datei löschen".
			w	SYS_FNAME_BUF
			w	curFileName
			w	16

			lda	#$00

;--- Register-Menü initialisieren.
::2			sta	switchFile		;Einzelne Datei/Mehrere Dateien.

			lda	delKeyMode		;Tastenstatus wieder einlesen.
			and	#%10010000		;SHIFT Links oder Rechts gedrückt?
			cmp	#%10010000
			bne	:2a			; => Ja, direkt löschen...

			bit	GD_DEL_MENU		;Ohne Nachfragen löschen?
			bpl	:3			; => Nein, weiter...

::2a			jsr	ExecRegMenuUser		;Dateien löschen.
			stx	exitCode		;Rückgabewert speichern.
			jmp	ExitRegMenuUser		;Zurück zum DeskTop.

::3			ClrB	reloadDir		;Flag löschen "Verzeichnis laden".

;--- Register-Menü anzeigen.
			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;Dateien löschen?
			cmp	#$7f
			bne	:2			; => Nein, Ende...

			jsr	doDeleteJob		;Dateien löschen.

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

::1			bit	reloadDir		;Verzeichnis neu laden?
			bpl	:2			; => Nein, weiter...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Dateien löschen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Register-Menü.
:R1SizeY0 = $28
:R1SizeY1 = $9f
:R1SizeX0 = $0028
:R1SizeX1 = $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "LÖSCHEN".
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

;*** Icons "Löschen"/"Abbruch".
:RIcon_Delete		w Icon_Delete
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Delete_x,Icon_Delete_y
			b USE_COLOR_INPUT

:Icon_Delete
<MISSING_IMAGE_DATA>

:Icon_Delete_x		= .x
:Icon_Delete_y		= .y

;*** Icon für Seitenwechsel.
:RIcon_SetPage		w Icon_SetPage
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SetPage_x,Icon_SetPage_y
			b USE_COLOR_INPUT

:Icon_SetPage
<MISSING_IMAGE_DATA>

:Icon_SetPage_x		= .x
:Icon_SetPage_y		= .y

:PosSlctPage_x		= (R1SizeX1 +1) -$10
:PosSlctPage_y		= (R1SizeY1 +1) -$10

;*** Daten für Register "LÖSCHEN".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RTab1_1  = $0048
:RLine1_1 = $00
:RLine1_2 = $20
:RLine1_3 = $30

:RegTMenu1		b 6

			b BOX_ICON
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_SetPage
				b NO_OPT_UPDATE

			b BOX_ICON
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Delete
				b NO_OPT_UPDATE

			b BOX_STRING
				w R1T01
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w curFileName
				b 16

			b BOX_FRAME
				w R1T02
				w $0000
				b RPos1_y +RLine1_2 -$08
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION
				w R1T03
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w GD_DEL_EMPTY
				b %11111111

			b BOX_OPTION
				w R1T04
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w GD_DEL_MENU
				b %11111111

;*** Texte für Register "LÖSCHEN".
if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Dateien"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "löschen",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Dateiname:",NULL

:R1T02			b "OPTIONEN",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Nur leere Verzeichnisse löschen",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Dateien ohne Nachfragen löschen"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$0f
			b "Im PopUp-Menü C=Taste drücken"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$18
			b "um Nachfragen einzuschalten.",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Delete"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "files",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Filename:",NULL

:R1T02			b "OPTIONS",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Delete empty directories only",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Delete files without prompting"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$0f
			b "Press C= key in popup menu to"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$18
			b "enable asking for delete files.",NULL
endif

;*** Seite wechseln.
:SwitchPage		sec				;Y-Koordinate der Maus einlesen.
			lda	mouseYPos		;Testen ob Maus innerhalb des
			sbc	#PosSlctPage_y		;"Eselsohrs" angeklickt wurde.
			bcs	:102
::101			rts				;Nein, Rücksprung.

::102			tay
			sec
			lda	mouseXPos+0
			sbc	#< PosSlctPage_x
			tax
			lda	mouseXPos+1
			sbc	#> PosSlctPage_x
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
			adc	#< SYS_FNAME_BUF
			sta	curFileVec +0
			lda	r0H
			adc	#> SYS_FNAME_BUF
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

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	_ext_InitIBox		;Status-Box anzeigen.
			jsr	_ext_InitStat		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont

			LoadW	r0,jobInfTxDelete	;"Dateien löschen"
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
			jmp	PutString

;*** Texte.
if LANG = LANG_DE
:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "DATEIEN LÖSCHEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
:infoTxRemain		b "Verbleibend: ",NULL
endif
if LANG = LANG_EN
:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "DELETING FILES"
			b PLAINTEXT,NULL

:infoTxFile		b "Filename: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
:infoTxRemain		b "Remaining: ",NULL
endif

;*** DiskName für StatusBox.
:curDiskName		s 17

;*** Dateien/Verzeichnisse löschen.
:doDeleteJob		LoadB	statusPos,$00		;Zeiger auf erste Datei.
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	_ext_PrntDInfo		;Disk-/Verzeichnisname ausgeben.

			LoadB	reloadDir,$ff		;GeoDesk: Verzeichnis neu laden.
			ClrB	delDirFiles		;Abfrage: Verzeichnisse löschen?

			LoadW	r15,SYS_FNAME_BUF	;Zeiger auf Anfang Dateiliste.

			MoveB	slctFiles,r14H		;Dateizähler löschen.
			sta	statusMax		;Max.Anzahl Dateien für Statusbox.

			sei
			clc				;Mauszeigerposution nicht ändern.
			jsr	StartMouseMode		;Mausabfrage starten.
			cli				;Interrupt zulassen.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

;--- Schleife: Einträge löschen.
::loop			lda	pressFlag		;Kopieren abbrechen?
			bne	:exit			; => Ja, Ende...

			ClrB	dirNotEmpty		;Flag: Verzeichnis leer.

			MoveW	r15,r6			;Zeiger auf Dateiname.
			jsr	FindFile		;Aktuelle Datei suchen.
			txa				;Datei Gefunden?
			bne	:error			; => Nein, Abbruch...

			MoveW	r15,r0			;Zeiger auf Dateiname.

			ldy	curDrive		;Aktuelles Laufwerk einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode Laufwerk?
			beq	:is_file		; => Nein, weiter...

			lda	dirEntryBuf
			and	#ST_FMODES		;Dateityp isolieren.
			cmp	#DIR			;Verzeichnis?
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
			jsr	_ext_PrntStat		;Fortschrittsbalken aktualisieren.

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

			jsr	_ext_UpdStatus		;Verzeichnis/Datei anzeigen.

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

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

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

			jsr	_ext_PrntDInfo		;Disk-/Verzeichnisname ausgeben.

;--- Zeiger auf Anfang Verzeichnis.
			jsr	usr1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
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
			and	#ST_FMODES		;"Gelöscht"?
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
			and	#ST_FMODES		;Dateityp einlesen.
			cmp	#DIR			;Verzeichnis?
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
::next_file		jsr	usrNxtDirEntry		;Nächster Verzeichnis-Eintrag.
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
::exit			jsr	_ext_PrntDInfo		;Verzeichnisname zurüksetzen.

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

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

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

::cancel		ldy	curDrive
			lda	RealDrvMode -8,y
			and	#%0100 0000
			beq	:1

			lda	drvUpdFlag		;Laufwerksdaten aktualisieren.
			ora	#%10000000
			sta	drvUpdFlag

			lda	curDirHead +32		;Zurück zum aktuellen
			sta	drvUpdSDir +0		;Verzeichnis.
			lda	curDirHead +33
			sta	drvUpdSDir +1

::1			ldx	#$ff			;Rückmeldung: "Abbruch".
			rts

::no_error		ldx	#NO_ERROR		;Rückmeldung: "Löschen".
			rts

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.
:delKeyMode		b $00
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

;*** Fehler: Verzeichnis kann nicht gelöscht werden.
:Dlg_dirNEmpty		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
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

;*** Startadresse Dateinamen.
:SYS_FNAME_BUF		;s MAX_DIR_ENTRIES * 17

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Dateinamen und Kopierspeicher
;verfügbar ist.
			g RegMenuBase -(MAX_DIR_ENTRIES * 17)
;***
