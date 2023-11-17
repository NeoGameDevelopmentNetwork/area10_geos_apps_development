; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"
endif

;*** GEOS-Header.
			n "GD.GEOHELP.DA"
			c "GD.HELPINIT V2.0"
			t "opt.Author"
			f DESK_ACC
			z $80 ;nur GEOS64

			o APP_RAM
			p MainInit
			q END_OF_DESKACC

			i

<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Startet das Hilfesystem als DeskAccessory"
endif
if LANG = LANG_EN
			h "Start helpsystem as a desk accessory"
endif

;*** Variablen.
:FileClassDA		b "GD.HELPINIT V2",NULL		;GeoHelp-DeskAccesory.
:FileClassAppl		b "GD.HELP     V2",NULL		;GeoHelp-Anwendung.

:FileNameBuf		s 17

:BackToRoutine		w $0000

:SwapFileName		b "GD_TEMP",NULL

:bufHelpDrive		b $00
:bufHelpPart		b $00

;*** Daten für den zu sichernden Speicherbereich.
:ramCopyData		w DATA_BASE
			w $0000
			w (OS_BASE - DATA_BASE)
:ramBankSwap		b $00

;*** Speicherverwaltung.
			t "-DA_FindBank"
			t "-DA_FreeBank"
			t "-DA_AllocBank"
			t "-DA_GetBankByte"

;*** SwapFile speichern.
:MainInit		jsr	i_MoveData		;Speicher für Dialogboxen
			w	dlgBoxRamBuf		;zwischenspeichern.
			w	b_dlgBoxBuf
			w	417

			lda	HelpSystemDrive		;Hilfe-Laufwerk speichern.
			sta	bufHelpDrive
			lda	HelpSystemPart		;Hilfe-Partition speichern.
			sta	bufHelpPart

			lda	#$00			;SwapFile auf Diskette.
			sta	ramBankSwap

			jsr	DACC_FIND_BANK		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;Speicher frei ?
			bne	OpenGeoHelp		; => Nein, auf Disk auslagern.
			tya				;Speicherbank gefunden ?
			beq	OpenGeoHelp		; => Nein, auf Disk auslagern.

			cmp	ramExpSize		;Speicherbank gültig ?
			bcs	OpenGeoHelp		; => Nein, SwapFile auf Diskette.

			sta	ramBankSwap		;Adresse Speicherbank definieren.

			ldx	#%00000001
			jsr	DACC_ALLOC_BANK		;Speicherbank reservieren.

;*** Speicher in REU übertragen.
:OpenGeoHelp		jsr	writeSwapFile		;SwapFile speichern.
			txa				;Fehler?
			bne	ExitRout		; => Ja, Abbruch...

			jsr	GetStdHelp		;GeoHelp aufrufen.

			jsr	readSwapFile		;SwapFile einlesen.
			txa				;Fehler?
			beq	ExitRout		; => Nein, weiter...

			jmp	Panic			;Speicher nicht mehr gültig, Ende.

;*** LoadGeoHelp beenden.
:ExitRout		lda	ramBankSwap		;SwapFile im RAM?
			beq	:1			; => Nein, weiter...

			jsr	DACC_FREE_BANK		;Speicherbak freigeben.

::1			lda	bufHelpDrive		;Hilfe-Laufwerk zurücksetzen.
			sta	HelpSystemDrive
			lda	bufHelpPart		;Hilfe-Partition zurücksetzen.
			sta	HelpSystemPart

			jsr	i_MoveData		;Speicher für Dialogboxen wieder
			w	b_dlgBoxBuf		;herstellen.
			w	dlgBoxRamBuf
			w	417

			LoadW	appMain,RstrAppl	;Zurück zur Anwendung.
			rts

;*** Register für RAM-Austausch definieren.
:SetRAMdata		ldx	#6
::1			lda	ramCopyData,x
			sta	r0L,x
			dex
			bpl	:1
			rts

;*** Speicher in SwapFile auslagern.
:writeSwapFile		lda	ramBankSwap		;SwapFile in RAM?
			beq	:disk			; => Nein, weiter...

::ram			jsr	SetRAMdata		;Register definieren.
			jsr	StashRAM		;Speicher in REU übertragen.

;			ldx	#NO_ERROR
			rts

::disk			jsr	delSwapFile		;SWAP-Datei auf Diskette löschen.

			LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile		;Speicher auf Disk auslagern.
			txa				;Diskettenfehler ?
			beq	:exit			; => Ja, Abbruch.

			pha
			LoadW	r0,SysErrBox		;Fehlermeldung, SwapDatei kann nicht
			jsr	DoDlgBox		;gespeichert werden.
			pla
			tax

::exit			rts

;*** Speicher aus SwapFile einlesen.
:readSwapFile		lda	ramBankSwap		;SwapFile in RAM?
			beq	:disk			; => Nein, weiter...

::ram			jsr	SetRAMdata		;Register definieren.
			jsr	FetchRAM		;Speicher aus REU auslesen.

;			ldx	#NO_ERROR
			rts

::disk			LoadW	r6,SwapFileName
			jsr	FindFile
			txa
			bne	:exit

			jsr	InitSysRAM		;Speicherbereiche initialisieren.

			lda	dirEntryBuf+1
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r2,($7fff-DATA_BASE)
			LoadW	r7,DATA_BASE
			jsr	ReadFile		;SwapFile in Speicher laden.
			txa
			bne	:exit

			jsr	delSwapFile		;SwapFile auf Diskette löschen.

			ldx	#NO_ERROR
::exit			rts

;*** SWAP-Datei auf Diskette löschen.
:delSwapFile		LoadW	r0,SwapFileName
			jmp	DeleteFile

;*** GeoHelp laden und starten.
:GetStdHelp		jsr	Get1stFile		;Hilfetext definieren.

			lda	#< FileClassAppl
			ldx	#> FileClassAppl
			ldy	#APPLICATION
			jsr	FindSysFile		;GeoHelp suchen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch.

			LoadW	r6,FileNameBuf
			jsr	FindFile
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch.

			PopW	BackToRoutine		;Rücksprungadresse sichern.

			jsr	i_MoveData		;Bildschirmbereich retten.
			w	SCREEN_BASE		;Nicht alle Anwendungen stellen
			w	b_SCREEN_BASE		;nach dem beenden des DA's den
			w	2*40*8			;kompletten Bildschirm wieder her.

			jsr	InitSysRAM		;Speicherbereiche initialisieren.

			lda	dirEntryBuf+1
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r2,(OS_BASE-BASE_HELPSYS)
			LoadW	r7,BASE_HELPSYS
			jsr	ReadFile		;GeoHelp in Speicher laden.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

			jsr	BASE_HELPSYS+3		;Hilfesystem aufrufen.

::err			jsr	i_MoveData		;Bildschirm wieder herstellen.
			w	b_SCREEN_BASE
			w	SCREEN_BASE
			w	2*40*8

			PushW	BackToRoutine		;Rücksprngadresse zurückschreiben.

::exit			rts

;*** GeoHelp-Systemdatei suchen.
;Übergabe: A/X = Zeiger auf Klasse.
;          Y   = GEOS-Dateityp.
;Rückgabe: FileNameBuf = Dateiname.
;          X   = Fehler.
:FindSysFile		sta	r10L			;Zeiger auf Klasse.
			stx	r10H
			sty	r7L			;Zeiger auf Dateityp.
			LoadB	r7H,$01			;Anzahl Dateien.
			LoadW	r6,FileNameBuf		;Speicher für Dateiname.
			jsr	FindFTypes		;Dateitypen suchen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch.
			lda	r7H			;Datei gefunden ?
			beq	:exit			; => Ja, weiter...
			ldx	#FILE_NOT_FOUND		;Fehler: "File not found!".
::exit			rts

;*** Speicherbereiche initialisieren.
;":dlgBoxRamBuf"/Zeropage löschen.
;Notwendig da ":GetFile" in einigen
;Fällen Probleme bereitet!
:InitSysRAM		jsr	i_FillRam
			w	417
			w	dlgBoxRamBuf
			b	$00

			lda	#$00
			tax
::1			sta	r0L,x
			inx
			cpx	#(r15H-r0L) +1
			bcc	:1
			rts

;*** Nach erster Anzeigeseite suchen.
;Infoblock einlesen.
;Wenn die Kennung "=>" vorhanden ist,
;dann Hilfedatei laden.
:Get1stFile		lda	curDrive
			sta	HelpSystemDrive

			lda	#$00
			sta	HelpSystemPart
			sta	HelpSystemFile
			sta	HelpSystemPage

			lda	#< FileClassDA
			ldx	#> FileClassDA
			ldy	#DESK_ACC
			jsr	FindSysFile		;GeoHelp suchen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch.

			LoadW	r6,FileNameBuf
			jsr	FindFile		;Verzeichnis-Eintrag suchen.
			txa				;Datei Gefunden ?
			bne	:exit			; => Nein, weiter...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Systemfehler.

			ldx	#"="			;Erstes Zeichen für Datei-Kennung.
			cpx	fileHeader+$a0		;Zeichen vorhanden ?
			bne	:exit			; => Nein, Standardhilfe anzeigen.
			ldx	#">"			;Zweites Zeichen für Datei-Kennung.
			cpx	fileHeader+$a1		;Zeichen vorhanden ?
			bne	:exit			; => Nein, Standardhilfe anzeigen.

			jmp	CheckSettings		;Laufwerkskonfiguration testen.

::exit			rts

;*** Hilfe-Laufwerk festlegen.
;Auf Laufwerk/Partition testen.
;    (w:xyz)=(Laufwerk:Partition)
;    A,B,C,D Laufwerk A:,B:,C:,D:
;    R       RAMLink
;    H       CMD HD
;    F       CMD RL
:CheckSettings		lda	fileHeader +$a2
			cmp	#"("			;Folgt Laufwerksangabe ?
			beq	:1			; => Ja, weiter...

;--- Hilfe von aktuellem Laufwerk öffnen.
			ldy	#$a2
			jmp	CheckSlctPage

;--- Hilfe von fremden Laufwerk öffnen.
::1			jsr	CheckHPartData		;Partitionsangabe suchen.
			jsr	CheckDrvAdr		;Laufwerksangabe suchen.
			txa				;Laufwerk gefunden ?
			beq	:3			; => Ja, weiter...

			jsr	CheckDrvType		;Laufwerkstyp suchen.
			txa				;Typ gefunden ?
			beq	:3			; => Ja, weiter...

::2			ldy	curDrive
::3			sty	HelpSystemDrive		;Laufwerk speichern.

			lda	HelpSystemPart		;Partition wechseln ?
			bne	:4			; => Ja, weiter...

			ldy	#$a5
			b $2c
::4			ldy	#$a9
			jmp	CheckSlctPage		;Dokument öffnen.

;*** Partition für Hilfetexte festlegen.
:CheckHPartData		lda	#$00
			ldx	fileHeader +$a4
			cpx	#":"			;Folgt Partitionsangabe ?
			bne	:1			; => Nein, weiter...

			ldy	#$a5
			LoadW	r0,fileHeader		;Partitions-Nr. einlesen.
			jsr	Get100DezCode
::1			sta	HelpSystemPart
			rts

;*** Auf Laufwerk A: bis D: testen.
:CheckDrvAdr		ldx	#NO_ERROR
			lda	fileHeader +$a3		;Laufwerkstyp einlesen.

			ldy	#$08			;Zeiger auf Laufwerk #8.
			cmp	#"A"			;Hilfe von Laufwerk A: starten ?
			beq	:1			; => Ja, weiter...
			iny				;Zeiger auf Laufwerk #9.
			cmp	#"B"			;Hilfe von Laufwerk B: starten ?
			beq	:1			; => Ja, weiter...
			iny				;Zeiger auf Laufwerk #10.
			cmp	#"C"			;Hilfe von Laufwerk C: starten ?
			beq	:1			; => Ja, weiter...
			iny				;Zeiger auf Laufwerk #11.
			cmp	#"D"			;Hilfe von Laufwerk D: starten ?
			beq	:1			; => Ja, weiter...
			ldx	#DEV_NOT_FOUND
::1			rts

;*** Laufwerkstyp (FD,HD,RL) suchen.
:CheckDrvType		ldx	#NO_ERROR
			lda	fileHeader +$a3		;Laufwerkstyp einlesen.

			ldy	#DrvFD			;Zeiger auf CMD-FD.
			cmp	#"F"			;Hilfetext auf CMD-FD ?
			beq	:1			; => Ja, weiter...
			ldy	#DrvHD			;Zeiger auf CMD-HD.
			cmp	#"H"			;Hilfetext auf CMD-HD ?
			beq	:1			; => Ja, weiter...
			ldy	#DrvRAMLink		;Zeiger auf CMD-RL.
			cmp	#"R"			;Hilfetext auf CMD-RL ?
			beq	:1			; => Ja, weiter...
			ldx	#DEV_NOT_FOUND
::1			rts

;*** Hilfe-Dokument festlegen.
;HINWEIS:
;Dateiname wird aus dem Infoblock in
;den Zwischenspeicher kopiert.
:CheckSlctPage		tya
			clc
			adc	#$03
			sta	:CheckSlctFile +1

			LoadW	r0,fileHeader		;Seiten-Nr. einlesen.
			jsr	GetDezCode
			sec
			sbc	#$01
			bcc	:1
			cmp	#61
			bcc	:2
::1			lda	#$01
::2			sta	HelpSystemPage		;Seite merken.

;--- Dateiname prüfen.
::CheckSlctFile		ldy	#$ff			;Dateiname einlesen.
			ldx	#$00
::11			lda	fileHeader ,y
			beq	:12
			cmp	#CR
			beq	:12
			sta	HelpSystemFile,x
			iny
			inx
			cpx	#16
			bcc	:11

::12			lda	#$00			;Dateiname mit $00-Bytes
			sta	HelpSystemFile,x	;auffüllen.
			inx
			cpx	#17
			bcc	:12
			rts

;*** ASCII-Zahl (Drei Zeichen) nach DEZIMAL.
:Get100DezCode		lda	(r0L),y			;100er-Wert einlesen.
			sec
			sbc	#$30			;Zahlenwert ermitteln.
			tax				;100er-Wert = $00 ?
			beq	:2			; => Ja, weiter...

			lda	#$00			;100er-Wert berechnen.
::1			clc
			adc	#$64
			dex
			bne	:1
::2			iny				;Zeiger auf 10er-Wert setzen.

			b $2c				;2Byte-Befehl übergehen.

;*** ASCII-Zahl (Zwei Zeichen) nach DEZIMAL.
:GetDezCode		lda	#$00			;Startwert für Umwandlung.
			sta	:1 +1			;Wert zwischenspeichern.

			lda	(r0L),y			;10er-Wert einlesen.
			sec
			sbc	#"0"			;Zahlenwert ermitteln und
			tax				;zwischenspeichern.
			iny				;Zeiger auf 1er-Wert setzen.
			lda	(r0L),y			;1er-Wert einlesen.
			sec
			sbc	#"0"			;Zahlenwert ermitteln

			clc
::1			adc	#$ff			;Startwert addieren (0,100,200)
			cpx	#$00			;10er-Wert = $00 ?
			beq	:3			; => Ja, weiter...

::2			clc
			adc	#10			;10er-Wert berechnen.
			dex
			bne	:2
::3			rts				;Ende.

;******************************************************************************
;*** Auf Endadresse < $0C00 testen.
;******************************************************************************
			g BASE_HELPSYS -1 -417 -2*40*8 -$0400
;******************************************************************************

;*** Startadresse der zu speichernden Daten (SwapDatei).
;HINWEIS:
;Der Speicherbereich wird vor Aufruf
;von GeoHelp überschrieben!
:DATA_BASE

;*** Dialogbox für Hilfedatei-Fehler.
;HINWEIS:
;Wird nur vor dem Aufruf von GeoHelp
;benötigt und wird nach dem speichern
;des SwapFile überschrieben.
:SysErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

if LANG = LANG_DE
::101			b PLAINTEXT,BOLDON
			b "Kann SwapDatei nicht",NULL
::102			b "auf Diskette speichern!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT,BOLDON
			b "SwapFile can not be",NULL
::102			b "saved to disk!",NULL
endif

;*** Infoblock für SWAP-Datei.
:HdrB000		w SwapFileName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w DATA_BASE
			w OS_BASE
			w DATA_BASE
			b "GD_SwapFile V"		;Klasse.
			b "1.0"				;Version.
			s $04				;Reserviert.
			b "GDOS64"			;Autor.
			b NULL
:HdrEnd			s (HdrB000+256)-HdrEnd

;*** Anfang Datenspeicher.
:b_SCREEN_BASE		= DATA_BASE			;s 2*40*8

;*** Speicher für dlgBoxRamBuf.
:b_dlgBoxBuf		= DATA_BASE +2*40*8		;s 417

;*** Endadresse DeskAccessory.
:END_OF_DESKACC		= DATA_BASE +2*40*8 +417

;--- Hinweis:
;":END_OF_DESKACC" muss < $0C00 sein,
;da GeoHelp ab $0C00 Daten für eine
;Dialogbox zwischenspeichert:
;$0C00-$0FFF = Farbdaten.
;$6000-$7FFF = Grafikdaten.
