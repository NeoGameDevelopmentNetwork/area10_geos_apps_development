; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Eingabetreiber wählen.
;* QuickSelect Eingabetreiber.
;* Eingabetreiber laden.
;* Druckertreiber wählen.
;* Druckertreiber laden.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DBOX"
			t "SymbTab_KEYS"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"

;--- Dialogbox:
:MAX_FNAMES		= 15				;Max. 15! (:tabFNames = 256 Bytes!)

:DLG_LEFT		= $0060
:DLG_WIDTH		= $0090
:DLG_TOP		= $20
:DLG_HEIGHT		= $30

:BOX_LEFT		= (DLG_LEFT +8)/8
:BOX_WIDTH		= (DLG_WIDTH -2*8)/8
:BOX_TOP		= (DLG_TOP +2*8)/8
:BOX_HEIGHT		= 1

:INP_OFF_X		= 2
:INP_WIDTH		= BOX_WIDTH -INP_OFF_X

:GFX_BASE1		= SCREEN_BASE  +(BOX_TOP+0)*8*40 +BOX_LEFT*8
:COL_BASE1		= COLOR_MATRIX +(BOX_TOP+0)  *40 +BOX_LEFT

endif

;*** GEOS-Header.
			n "obj.GD27"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
:MAININIT		lda	r10L
			bmi	:printer		;Bit%7=1: Druckertreiber laden.

::input			asl
			bmi	:iopen			;Bit%6=1: Eingabetreiber wählen.
			asl
			bmi	:iload			;Bit%5=1: Eingabetreiber laden.
;			asl
;			bmi	:iselect		;Bit%4=1: Schnellauswahl.
::iselect		jmp	OpenInptQuick
::iload			jmp	OpenInptDev
::iopen			jmp	OpenInptDBox

::printer		asl
			bmi	:popen			;Bit%6=1: Druckertreiber wählen.
			asl
			bmi	:pload			;Bit%5=1: Druckertreiber laden.
			asl
			bmi	:palnk			;Bit%4=1: AppLink-Druckertreiber.
;			asl
;			bmi	:pload_err		;Bit%3=1: Drucker-AppLink-Fehler.
::pload_err		jmp	msgPrntError
::palnk			jmp	OpenPrntALnk
::pload			jmp	OpenPrntDev
::popen			jmp	OpenPrntDBox

;*** Dateiauswahlbox.
			t "-Gxx_DBOpenFile"

;*** Statusmeldung ausgeben.
:doStatusMsg		sta	errDrvCode		;Fehlernummer zwischenspeichern.

			jsr	SUB_STATMSG		;Statusmeldung ausgeben.

			ldx	#CANCEL_ERR
			bit	errDrvCode		;Fehler?
			bvc	:exit			; => Nein, weiter...
			ldx	#NO_ERROR
::exit			rts

;*** MyComp und Status aktualisieren.
:updateInfo		jsr	SUB_SYSINFO		;Statuszeile aktualisieren.

;--- Hinweis
;Arbeitsplatz aktualisieren.
; -Oberstes Fenster zwischenspeichern
; -Arbeitsplatz aktualisieren
; -Oberstes Fenster wieder aktivieren
;
;Damit wird sichergestellt, das die
;Drucker im Arbeitsplatz-Fenster
;aktuell sind und das Fenster mit dem
;Druckertreiber weiterhin aktiv ist.
			lda	WM_MYCOMP		;Fenster "MyComputer" geöffnet?
			beq	:exit			; => Nein, Ende...

			sta	WM_WCODE
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
			jsr	WM_CALL_DRAW		;Fenster "MyComputer" aktualisieren.

;--- Hinweis:
;WM einlesen, da ":WM_CALL_DRAW" die
;Daten für den ScrollBalken des aktiven
;Fensters überschreibt!
			jsr	MOD_WM			;Fenstermanager laden.

::exit			rts

;*** Fenster zurücksetzen.
:resetTopWindow		lda	WM_STACK		;Oberstes Fenster = DeskTop?
			beq	:exit			; => Ja, Ende...

			ldx	WM_MYCOMP		;Fenster MyComp geöffnet?
			beq	:setTopWin		; => Nein, weiter...
			cpx	WM_STACK		;MyComp = Oberstes Fenster?
			bne	:updWindows		; => Nein, Fenster neu laden...

;--- Hinweis:
;Sonderbehandlung für Drucker über
;AppLink öffnen: Hier sind jetzt die
;Fensterdaten des DeskTop aktiv.
::setTopWin		sta	WM_WCODE
			jmp	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.

;--- Hinweis:
;Alle Fenster oberhalb von MyComp neu
;aus dem ScreenBuffer laden. Es reicht
;nicht aus nur das oberste Fenster zu
;laden, da sonst evtl. die Reihenfolge
;aller Fenster nicht mehr stimmt.
::updWindows		ldx	#MAX_WINDOWS -1		;Zeiger auf letztes Fenster.
::1			lda	WM_STACK,x		;Fenster-Typ einlesen.
			cmp	WM_MYCOMP		;MyComp-Fenster gefunden?
			beq	:2			; => Ja, weiter...
			dex				;Alle Fenster durchsucht?
			bpl	:1			; => Nein, weiter...
			bmi	:exit			; => Nicht gefunden, Abbruch...

::2			dex				;Ist MyComp oberstes Fenster?
			bmi	:exit			; => Ja, Ende...

::3			txa				;Fenster-Nr. zwischenspeichern.
			pha

			lda	WM_STACK,x		;Fenster-Typ einlesen.
			sta	WM_WCODE
			jsr	WM_LOAD_WIN_DATA	;Fensterdaten einlesen.
;			jsr	WM_OPEN_DRIVE		;Fensterlaufwerk öffnen.

;--- Hinweis:
;":WM_CALL_DRAW" darf hier nicht mehr
;aufgerufen werden, da dann die Routine
;":extWin_GetData" ausgeführt, welche
;dieses Modul überschreiben würde:
;Nach der Rückkehr: Absturz!
;			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.
;			jsr	WM_CALL_DRAW		;Fenster neu laden.

;--- Hinweis:
;Nur Fenster aus ScreenBuffer einlesen.
			jsr	WM_LOAD_SCREEN		;Fenster aus ScreenBuffer laden.

			pla
			tax
			dex				;Alle Fenster aktualisiert?
			bpl	:3			; => Nein, weiter...

::exit			rts

;*** Druckertreiber wählen und laden.
:OpenPrntDBox		jsr	find1stDrive		;Aktuelles Laufwerk speichern und
			jsr	Sys_SvTempDrive		;erstes Laufwerk aktivieren.

			jsr	doPrntDBox		;Druckertreiber wählen.
			txa				;Datei ausgewählt?
			bne	:exit			; => Nein, Abbruch..

			jsr	OpenPrntDev		; => Ja, weiter...
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	updateInfo		;MyComp/Status aktualisieren.
			jsr	resetTopWindow		;Oberstes Fenster aktivieren.

::exit			jmp	BackTempDrive		;Original-Laufwerk zurücksetzen.

;*** Druckertreiber für AppLink wählen.
:OpenPrntALnk		jsr	find1stDrive		;Erstes Laufwerk aktivieren.
			jsr	SetDevice

;			jmp	doPrntDBox		;Druckertreiber wählen.

;*** Neuen Druckertreiber wählen.
:doPrntDBox		lda	#PRINTER		;GEOS-Dateityp festlegen.
			sta	r7L

			lda	#$00			;Keine GEOS-Klasse.
			sta	r10L
			sta	r10H

			jmp	DBoxOpenFile		;Druckertreiber auswählen.

;*** Druckertreiber aus Fenster öffnen.
:OpenPrntDev		jsr	LoadPrinter		;Druckertreiber laden.
			txa				;Fehler?
			beq	msgPrntOK		; => Nein, Status ausgeben...

			cmp	#FILE_NOT_FOUND		;Nicht gefunden?
			beq	msgPrntError		; => Ja, Fehler "Nicht installiert".
			bne	msgPrntSysErr		; => Nein, Fehler ausgeben.

;*** Info: Drucker installiert.
:msgPrntOK		lda	#$c0			;"PRNT_UPDATED"
			b $2c

;*** Fehler: Drucker nicht gefunden.
:msgPrntError		lda	#$80			;"PRNT_NOT_UPDATED"

;*** Fehler: Drucker konnte nicht geladen werden.
:msgPrntSysErr		jsr	doStatusMsg		;Statusmeldung ausgeben.
			txa				;Fehler/Abbruch?
			bne	:exit			; => Ja, Ende...

			jsr	updateInfo		;MyComp/Status aktualisieren.
			jsr	resetTopWindow		;Oberstes Fenster aktivieren.

::exit			rts

;*** Druckertreiber laden.
:LoadPrinter		lda	#< dataFileName		;Druckertreiber suchen.
			sta	r6L
			sta	errDrvInfoF +0
			lda	#> dataFileName
			sta	r6H
			sta	errDrvInfoF +1

			jsr	FindFile
			txa				;Datei gefunden?
			bne	:exit			; => Nein, weiter...

;--- Hinweis:
;FensterManager speichern, da beim
;laden des Druckertreibers und dem
;aktualisieren der Fenster Teile des
;FensterManagers überschrieben werden.
			jsr	BACKUP_WMCORE		;FensterManager sichern.

			lda	#< dataFileName
			sta	r0L
			lda	#> dataFileName
			sta	r0H

			lda	#< PrntFileName
			sta	r6L
			lda	#> PrntFileName
			sta	r6H

			ldx	#r0L
			ldy	#r6L
			jsr	CopyString		;Druckername kopieren.

			lda	#< PRINTBASE
			sta	r7L
			lda	#> PRINTBASE
			sta	r7H

			lda	#%00000001
			sta	r0L

			jsr	GetFile			;Druckertreiber einlesen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

;--- Hinweis:
;WM nachladen, da der Druckertreiber
;beim laden Teile des WM überschreibt!
			txa				;Fehler zwischenspeichern.
			pha
			jsr	MOD_WM			;Fenstermanager laden.
			pla
			tax

::exit			rts

;*** Neuen Eingabetreiber wählen.
:OpenInptDBox		lda	#INPUT_DEVICE		;GEOS-Dateityp festlegen.
			sta	r7L

			lda	#$00			;Keine GEOS-Klasse.
			sta	r10L
			sta	r10H

			jsr	find1stDrive		;Aktuelles Laufwerk speichern und
			jsr	Sys_SvTempDrive		;erstes Laufwerk aktivieren.

			jsr	DBoxOpenFile		;Datei auswählen.
			txa				;Datei ausgewählt?
			bne	:exit			; => Nein, Ende...

			jsr	OpenInptDev		;Eingabetreiber laden.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	updateInfo		;MyComp/Status aktualisieren.
			jsr	resetTopWindow		;Oberstes Fenster aktivieren.

::exit			jmp	BackTempDrive		;Original-Laufwerk zurücksetzen.

;*** Eingabetreiber laden/Status anzeigen.
:OpenInptDev		jsr	LoadInput		;Eingabetreiber laden.
			txa				;Fehler?
			beq	msgInptOK		; => Nein, Status ausgeben...

			cmp	#FILE_NOT_FOUND		;Nicht gefunden?
			beq	msgInptError		; => Ja, Fehler "Nicht installiert".
			bne	msgInptSysErr		; => Nein, Fehler ausgeben.

;*** Info: Eingabegerät installiert.
:msgInptOK		lda	#$c1			;"INPT_UPDATED"
			b $2c

;*** Fehler: Eingabegerät nicht gefunden.
:msgInptError		lda	#$81			;"INPT_NOT_UPDATED"

;*** Fehler: Eingabegerät konnte nicht installiert werden.
:msgInptSysErr		jsr	doStatusMsg		;Statusmeldung ausgeben.
			txa				;Fehler/Abbruch?
			bne	:exit			; => Ja, Ende...

			jsr	updateInfo		;MyComp/Status aktualisieren.
			jsr	resetTopWindow		;Oberstes Fenster aktivieren.

::exit			rts

;*** Eingabetreiber laden.
:LoadInput		lda	#< dataFileName		;Name Eingabetreiber kopieren.
			sta	r6L
			sta	errDrvInfoF +0
			lda	#> dataFileName
			sta	r6H
			sta	errDrvInfoF +1

			jsr	FindFile		;Eingabetreiber auf Disk suchen.
			txa				;Datei gefunden?
			bne	:exit			; => Nein, Abbruch...

;--- Hinweis:
;FensterManager speichern, da beim
;aktualisieren der Fenster Teile des
;FensterManagers überschrieben werden.
			jsr	BACKUP_WMCORE		;FensterManager sichern.

			lda	#< dataFileName
			sta	r0L
			lda	#> dataFileName
			sta	r0H

			lda	#< inputDevName
			sta	r6L
			lda	#> inputDevName
			sta	r6H

			ldx	#r0L
			ldy	#r6L
			jsr	CopyString		;Name Eingabetreiber kopieren.

			lda	#< MOUSE_BASE
			sta	r7L
			lda	#> MOUSE_BASE
			sta	r7H

			lda	#%00000001
			sta	r0L

			jsr	GetFile			;Eingabetreiber einlesen.
			txa				;Fehler?
			bne	:exit			; => Nein, OK ausgeben...

			jsr	InitMouse		;Eingabetreiber initialisieren.

			ldx	#NO_ERROR
::exit			rts

;*** QuickSelect Eingabegerät.
:OpenInptQuick		jsr	find1stDrive		;Aktuelles Laufwerk speichern und
			jsr	Sys_SvTempDrive		;erstes Laufwerk aktivieren.

			lda	curDrive		;Start-Laufwerk merken.
			sta	drvFNames

			jsr	FindInpDev		;Max. 15 Eingabetreiber suchen.

			lda	#< Dlg_SlctInput
			sta	r0L
			lda	#> Dlg_SlctInput
			sta	r0H

			jsr	DoDlgBox		;Treiberauswahl über Dialogbox.

			lda	sysDBData
			cmp	#OK			;RETURN?
			bne	:exit			; => Nein, Ende...

;--- Hinweis:
;Der Name des gewählten Eingabetreibers
;steht in ":dataFilename".
			jsr	LoadInput		;Eingabetreiber laden.
			txa				;Fehler?
			beq	:ok			; => Nein, weiter...

::err			jsr	doStatusMsg		; => Ja, Fehler ausgeben...
			txa				;XREG = CANCEL_ERR:
			bne	:exit			; => Abbruch.

::ok			jsr	updateInfo		;MyComp/Status aktualisieren.
			jsr	resetTopWindow		;Oberstes Fenster aktivieren.

::exit			jmp	BackTempDrive		;Original-Laufwerk zurücksetzen.

;*** Erstes Laufwerk finden.
:find1stDrive		ldy	#8
::1			lda	driveType -8,y		;Laufwerk vorhanden?
			bne	:found			; => Ja, weiter...
			iny
			cpy	#12			;Alle Laufwerke geprüft?
			bcc	:1			; => Nein, weitersuchen...
			ldy	#8			;Eigentlich nicht möglich...
::found			tya				;Laufwerksadresse übergeben.
			rts

;*** Laufwerk wechseln.
:SetNewDevice		jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			beq	:ok			; => Nein, weiter..

::exit			rts

::ok			lda	curDrive		;Neues Laufwerk speichern.
			sta	drvFNames

;*** Eingabetreiber suchen.
:FindInpDev		ldy	#0			;Namenspeicher löschen.
;			lda	#$00
			tya
::1			sta	tabFNames,y
			iny
			bne	:1

;			lda	#0			;Zeiger auf ersten Eintrag.
			sta	poiFName
			sta	dataFileName		;Dateiname löschen.

			lda	#< tabFNames		;Zeiger auf Datentabelle.
			sta	r6L
			lda	#> tabFNames
			sta	r6H

			lda	#INPUT_DEVICE		;GEOS-Dateityp: Eingabetreiber.
			sta	r7L

			lda	#MAX_FNAMES		;Max. 15 Dateien.
			sta	r7H

			lda	#NULL			;Keine GEOS-Klasse testen.
			sta	r10L
			sta	r10H

			jsr	FindFTypes		;Dateitypen suchen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	#MAX_FNAMES		;Anzahl Dateien berechnen.
			sec
			sbc	r7H
			tay				;Mind. 1 Datei?
			bne	:done			; => Ja, weiter...

::err			ldy	#0
::done			sty	maxFNames
			tya
			bne	getCurFName		;Zeiger auf ersten Dateinamen.

			rts

;*** Aktuellen Eintrag in Zwischenspeicher.
:getCurFName		ldx	poiFName		;Zeiger auf Dateiname in Tabelle.
			lda	vecFNameTab,x
			clc
			adc	#< tabFNames
			sta	r0L
			lda	#0
			adc	#> tabFNames
			sta	r0H

			ldy	#0			;Name in Zwischenspeicher
::1			lda	(r0),y			;kopieren und mit NULL-Bytes
			sta	dataFileName,y		;auffüllen.
			beq	:2
			iny
			bne	:1
::2			cpy	#16
			beq	:3
			sta	dataFileName,y
			iny
			bne	:2

::3			rts

;*** Tastaturabfrage initialisieren.
:DB_INIT_KEYB		lda	#< :chkKeyB		;Tastaturabfrage installieren.
			sta	keyVector +0
			lda	#> :chkKeyB
			sta	keyVector +1
			rts

::chkKeyB		lda	keyData			;Taste gedrückt?
			beq	:exit			; => Nein, Ende...
			cmp	#"x"			;Taste "X"?
			beq	:cancel			; => Ja, Auswahl abbrechen...
			cmp	#KEY_CR			;Taste "RETURN"?
			bne	:1			; => Nein, weiter...

			lda	#OK
::cancel		sta	sysDBData
			jmp	RstrFrmDialogue		;Dialogbox beenden.

::1			cmp	#"a"			;Tasten "A" bis "D"?
			bcc	:2
			cmp	#"d" +1
			bcs	:2			; => Nein, weiter...
			sec
			sbc	#"a" -8

			tay
			lda	driveType -8,y		;Laufwerk verfügbar?
			beq	:exit			; => Nein, ignorieren.

			tya
			jsr	SetNewDevice		;Neues Laufwerk aktivieren.

			jsr	DB_CLR_GFX		;Textfeld komplett löschen.
			jsr	DB_DRAW_DRIVE		;Laufwerk ausgeben.
			jsr	DB_DRAW_INPUT		;Dateiname ausgeben.

::exit			rts

::2			cmp	#KEY_DOWN		;"CURSOR DOWN"?
			bne	:3			; => Nein, weiter...

			ldx	poiFName		;Zeiger auf nächsten Namen in
			inx				;Tabelle berechnen.
			cpx	maxFNames
			bcs	:exit
			stx	poiFName
			bcc	:update			;Neuen Namen ausgeben.

::3			cmp	#KEY_UP			;"CURSOR UP"?
			bne	:exit			; => Nein, Ende...

			ldx	poiFName		;Zeiger auf vorherigen Namen in
			beq	:exit			;Tabelle berechnen.
			dex
			stx	poiFName

::update		jsr	getCurFName		;Neuen Namen ausgeben.

			jsr	DB_CLR_INPUT		;Bereich Dateiname löschen.
			jsr	DB_DRAW_INPUT		;Dateiname ausgeben.

			rts

;*** Ausgabebereich löschen.
:DB_CLR_GFX		lda	#$00
			ldx	#BOX_WIDTH*8 -1
::1			sta	GFX_BASE1,x
			dex
			cpx	#$ff
			bne	:1
			rts

;*** Bereich Dateiname löschen.
:DB_CLR_INPUT		lda	#$00
			ldx	#INP_WIDTH*8 -1
::1			sta	GFX_BASE1 +INP_OFF_X*8,x
			dex
			cpx	#$ff
			bne	:1
			rts

;*** Farben setzen.
:DB_CLR_COL		lda	C_InputField
			ldx	#BOX_WIDTH -1
::1			sta	COL_BASE1,x
			dex
			bpl	:1
			rts

;*** Rahmen um Eingabefeld zeichnen.
:DB_DRAW_BOX		jsr	i_FrameRectangle
			b	BOX_TOP*8 -1
			b	BOX_TOP*8 +BOX_HEIGHT*8
			w	BOX_LEFT*8 -1
			w	BOX_LEFT*8 +BOX_WIDTH*8
			b	%11111111
			rts

;*** Aktuelles Laufwerk ausgaben.
:DB_DRAW_DRIVE		lda	#< (BOX_LEFT*8) +4
			sta	r11L
			lda	#> (BOX_LEFT*8) +4
			sta	r11H

			lda	# (BOX_TOP*8) +6
			sta	r1H

			lda	drvFNames
			clc
			adc	#"A" -8
			jsr	SmallPutChar

			lda	#":"
			jmp	SmallPutChar

;*** Aktuelle Dateinamen ausgaben.
:DB_DRAW_INPUT		lda	#< (BOX_LEFT*8) +4 +12
			sta	r11L
			lda	#> (BOX_LEFT*8) +4 +12
			sta	r11H

			lda	# (BOX_TOP*8) +6
			sta	r1H

			lda	#< dataFileName
			sta	r0L
			lda	#> dataFileName
			sta	r0H

			jmp	PutString

;*** Dateiauswahlbox.
:Dlg_SlctInput		b %00000001

			b DLG_TOP ,DLG_TOP  +DLG_HEIGHT -1
			w DLG_LEFT,DLG_LEFT +DLG_WIDTH  -1

			b DB_USR_ROUT
			w DB_INIT_KEYB

			b DB_USR_ROUT
			w ResetFontGD

			b DB_USR_ROUT
			w DB_DRAW_BOX

			b DB_USR_ROUT
			w DB_CLR_COL

			b DB_USR_ROUT
			w DB_DRAW_DRIVE

			b DB_USR_ROUT
			w DB_DRAW_INPUT

			b DBTXTSTR ,$08,$09
			w :info
			b DBTXTSTR ,$08,$22
			w :info1
			b DBTXTSTR ,$08,$2b
			w :info2

			b NULL

if LANG = LANG_DE
::info			b "Eingabegerät wählen:",NULL
::info1			b "A/B/C/D=Laufwerk, RETURN=Auswahl",NULL
::info2			b "CRSR UP/DOWN=Wechseln, X=Abbruch",NULL
endif
if LANG = LANG_EN
::info			b "Select input device:",NULL
::info1			b "A/B/C/D=Drive, RETURN=Select",NULL
::info2			b "CRSR UP/DOWN=Switch, X=Cancel",NULL
endif

;*** Speicher für Dateinamen.
:maxFNames		b $00
:drvFNames		b $00
:poiFName		b $00
:vecFNameTab		b  0*17,  1*17,  2*17,  3*17
			b  4*17,  5*17,  6*17,  7*17
			b  8*17,  9*17, 10*17, 11*17
			b 12*17, 13*17, 14*17, 15*17

:tabFNames		; s 256

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Desktop-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1 -MAX_FNAMES*17
;***
