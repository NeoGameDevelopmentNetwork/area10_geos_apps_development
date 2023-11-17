; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#204.obj"
			o	ModStart
			r	EndAreaCBM

			jmp	CBMtoCBM

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetSourceCBM"
			t   "-SetTargetCBM"

			t   "-FileExist"
			t   "-GetConvTab2"
			t   "-CBM_SetName"

;*** L204: Datei von CBM nach CBM kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

;*** Datei von CBM nach CBM kopieren
;xReg = %00000000	-> Text nach Text.
;       %10000000	-> Text nach GeoWrite.
;       %01000000	-> GeoWrite nach Text.
;       %00100000	-> GeoWrite nach GeoWrite.
;       %00010000	-> CBM nach CBM 1:1.
;       %00001000	-> Duplizieren.

:CBMtoCBM		jsr	Init_1			;Register initialisieren.

:CBMtoCBM_1		jsr	GetFileToCopy		;Dateien auswählen.
			txa
			bmi	L204ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	GetTarget		;Ziel-Partition wählen
			txa
			bmi	L204ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

:CBMtoCBM_2		jsr	Init_2			;Register initialisieren.

			jsr	GetFileData		;Datei-Informationen einlesen.
			txa
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	TestFiles		;Dateien auf Ziel-Laufwerk testen.
			txa
			bmi	L204ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	CalcBytesFree		;Speicher auf Ziel-Laufwerk testen.
			txa
			beq	InitForCopy

			jsr	NoDiskSpace		;Fehler: "Zu wenig freier Speicher..."
			txa
			beq	CBMtoCBM_1

;*** Zurück zu geoDOS.
:L204ExitGD		jmp	InitScreen		;Zurück zum Hauptmenü.
:ExitDskErr		jmp	DiskError		;Diskettenfehler anzeigen.

;*** Dateien kopieren.
:InitForCopy		jsr	InitForIO
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00

;*** Konvertierungstabelle laden.
:GetConvTab		lda	CBMCopyMode
			and	#%00111000		;"GW-GW", "CBM 1:1" oder "Duplicate" ?
			bne	CopyFileInfo		;Ja, Keine Übersetzungstabellen.

			lda	CTabCBMtoCBM
			ldx	#<SCREEN_BASE
			ldy	#>SCREEN_BASE
			jsr	LoadConvTab

;*** Dateidaten in Zwischenspeicher kopieren.
:CopyFileInfo		jsr	i_MoveData
			w	FileNTab,SCREEN_BASE+   256,16*256
			jsr	i_MoveData
			w	FileDTab,SCREEN_BASE+17*256,10*256

			lda	CBMCopyMode		;Kopiermodus einlesen.
			and	#%11111000
			beq	:101			;-> Text nach Text.
			cmp	#%10000000
			beq	:102			;-> Text nach GeoWrite.
			cmp	#%01000000
			beq	:103			;-> GeoWrite nach Text.
			cmp	#%00100000
			beq	:104			;-> GeoWrite nach GeoWrite.
			cmp	#%00010000
			beq	:105			;-> CBM nach CBM 1:1.
			cmp	#%00001000
			beq	:105			;-> Duplizieren.
			jmp	L204ExitGD		;Zurück zu geoDOS.

::101			jmp	vC_CBMtoCBM
::102			jmp	vC_CBMtoGW
::103			jmp	vC_GWtoCBM
::104			jmp	vC_GWtoGW
::105			jmp	vC_CBMtoCBM_F

;*** Routinen initialisieren.
:Init_1			stx	CBMCopyMode		;Kopiermodus merken.
			txa
			ldy	#$00
			and	#%00000001
			beq	:101
			ldy	#$80
::101			sty	CCM2

			ldy	#$02
			lda	#$00			;Partitionsdaten löschen.
::102			sta	TDrvPart,y
			sta	SDrvPart,y
			sta	TDrvNDir,y
			sta	SDrvNDir,y
			dey
			bpl	:102
			rts

;*** Dateien auswählen.
:Init_2			ClrB	Duplicate		;"Duplicate"-Flag löschen.

			ldx	Source_Drv		;Physikalische Geräteadressen
			ldy	Target_Drv		;vergleichen.
			lda	DriveAdress-8,x
			ora	DriveAdress-8,y
			beq	:101

			lda	DriveAdress-8,x
			cmp	DriveAdress-8,y
			bne	:105
			beq	:102

;--- Ergänzung: 22.11.18/M.Kanet
;Bei NativeMode-Laufwerken auch Unterverzeichnis prüfen um
;Duplicate oder Copy festzustellen.
::101			lda	DriveModes -8,x
			and	#%00100000
			bne	:102
			lda	DriveModes -8,y
			and	#%00100000
			bne	:102
			cpx	Target_Drv
			bne	:105
			beq	:104

::102			ldy	#$02
::103			lda	SDrvPart,y		;Quell- und Ziel-Partition
			cmp	TDrvPart,y		;vergleichen.
			bne	:105
			lda	SDrvNDir,y		;Quell- und Ziel-Verzeichnis
			cmp	TDrvNDir,y		;vergleichen.
			bne	:105
			dey
			bpl	:103

::104			dec	Duplicate		;Quelle und Ziel sind gleich.

::105			rts

;*** Zeiger auf Datenspeicher.
:Init_3			LoadW	a6,FileNTab		;Tabelle Datei-Namen.
			LoadW	a7,FileDTab		;Tabelle Datei-Datum.
			rts

;*** Zeiger auf nächste Datei.
:Init_4			AddVBW	16,a6
			AddVBW	10,a7			;Zeiger auf nächste CBM-Datei.
			rts

;*** Dateien wählen.
:GetFileToCopy		ldx	Source_Drv		;Quell-Laufwerk aktivieren.
			lda	CBMCopyMode		;Kopiermodus einlesen.
			and	#%00001000		;Datein 1:1 kopieren ?
			beq	:101			;Ja, Alle Dateien anzeigen.
			ldx	Target_Drv		;Quell-Laufwerk aktivieren.
::101			stx	Source_Drv
			txa
			jsr	NewDrive
			txa
			bne	:104

			LoadW	r10,FileNTab		;Zeiger auf Zwischenspeicher.
			jsr	InitSlctFiles
			txa				;Diskettenfehler oder "Abbruch" ?
			bne	:104			;Ja, Ende.

;--- Ergänzung: 01.12.18/M.Kanet
;Bei NativeMode-Laufwerken Verzeichnis speichern.
			lda	curDrvMode
			and	#%00100000		;NativeMode-Laufwerk ?
			beq	:90			;Nein, weiter...

			jsr	InitCMD3		;Native-Verzeichnis einlesen und
							;Verzeichnistyp ermitteln.

::90			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Nein, weiter...

			jsr	InitCMD2		;Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

::102			ldy	#$02			;Partitionsdaten für Quell-Laufwerk
::103			lda	TDrvPart,y		;merken.
			sta	SDrvPart,y
			lda	TDrvNDir,y
			sta	SDrvNDir,y
			dey
			bpl	:103

			ldx	#$00			;Kein Fehler.
::104			rts				;Ende.

;*** Dateiauswahl initialisieren.
:InitSlctFiles		lda	CBMCopyMode		;Kopiermodus einlesen.
			and	#%00011000		;Datein 1:1 kopieren ?
			beq	:102			;Ja, Alle Dateien anzeigen.

;*** => Kopieren 1:1.
;    => Dateien duplizieren.
::101			lda	#<V204e1		;Zeiger auf Titel für "Dateien".
			ldx	#>V204e1
			ldy	#%00100000		;Dateityp-Auswahl möglich.
			jsr	CBM_GetFiles		;Dateien einlesen.
			txa
			beq	:105			;xReg =  $00, OK.
			jmp	:106			;xReg =  $FF, Ende.
							;     <> $00, Diskettenfehler.

;*** => Sequentielle Dateien kopieren.
;    => GeoWrite - Dokumente kopieren.
;    Keine Dateityp-Auswahl!
::102			lda	CBMCopyMode
			and	#%01100000		;GeoWrite-Texte kopieren ?
			bne	:103			;Ja, Auswahlbox mit GW-Dokumenten.

			lda	#<V204e1		;Zeiger auf Titel für "SEQ-Dateien".
			ldx	#>V204e1
			ldy	#%00000000		;Sequentielle Dateien einlesen.
			jmp	:104

::103			lda	#<V204e2		;Zeiger auf Titel für "GW-Dateien".
			ldx	#>V204e2
			ldy	#%01000000		;GeoWrite-Dateien einlesen.
			jmp	:104

::104			jsr	CBM_GetFiles		;Dateien einlesen.
			txa
			bne	:106			;xReg =  $FF, Ende.
							;     <> $00, Diskettenfehler.

;*** Dateien ausgewählt, Ende.
;    xReg ist hier auf NULL!
::105			lda	r13H			;Anzahl Dateien merken.
			sta	AnzahlFiles
			ldx	#$00
::106			rts

;*** Ziel-Partition öffnen.
:GetTarget		lda	Target_Drv
			jsr	NewDrive
			txa
			bne	:103

			ldx	#$00
;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für SD2IEC/RAMNative ergänzt.
			lda	curDrvMode		;CMD-Laufwerk ?
			bmi	:100a			;Ja, weiter...
			and	#%00100000		;NativeMode?
			bne	:100a			;Ja, weiter...
			ldy	#$02
			lda	#$00			;Partitionsdaten und Verzeichnis-
::100b			sta	TDrvPart,y		;Daten für Ziel-Laufwerk löschen.
			sta	TDrvNDir,y
			dey
			bpl	:100b
			rts

::100a			lda	CBMCopyMode		;Kopiermodus einlesen.
			and	#%00001000		;Dateien duplizieren ?
			bne	:103			;Ja, weiter...

			jsr	SaveCopyFiles		;Dateinamentabelle sichern.
			txa
			bne	:101

			lda	curDrvMode		;CMD-Laufwerk ?
			bpl	:101a			;Nein, übergehen.

			lda	Target_Drv
			ora	CCM2
			ldx	#<V204e0		;Zeiger auf Titel setzen.
			ldy	#>V204e0
			jsr	CMD_SlctPart		;Partition wählen, falls CMD-Laufwerk.
			jmp	:101b

;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für SD2IEC/RAMNative ergänzt.
::101a			lda	Target_Drv
			ora	CCM2
			ldx	#<V204e7		;Zeiger auf Titel setzen.
			ldy	#>V204e7
			jsr	CMD_SlctNDir		;Verzeichnis wählen, falls NativeMode.
::101b			stx	:102 +1

			jsr	LoadCopyFiles		;Dateinamentabelle sichern.
			txa
			beq	:102
::101			jmp	GDDiskError

::102			ldx	#$ff
::103			rts

;*** Dateinamentabelle sichern.
:SaveCopyFiles		jsr	OpenSysDrive		;Systemdiskette öffnen.

			jsr	DelFileList		;Vorhandene Dateiliste löschen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile		;Dateinamenliste speichern.
			txa
::101			pha
			jsr	OpenUsrDrive		;Arbeitsdiskette öffnen.
			pla
			tax
			rts

;*** Dateinamenliste laden.
:LoadCopyFiles		jsr	OpenSysDrive		;Systemdiskette öffnen.

			jsr	PrepGetFile
			LoadB	r0L,%00000001
			LoadW	r6 ,HdrName
			LoadW	r7 ,FileNTab
			jsr	GetFile			;Dateinamenliste einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	DelFileList		;Vorhandene Dateiliste löschen.
			txa
::101			pha
			jsr	OpenUsrDrive		;Arbeitsdiskette öffnen.
			pla
			tax
			rts

;*** Dateiliste auf Diskette löschen.
:DelFileList		LoadW	r0,HdrName
			jsr	DeleteFile
			txa
			beq	DelFileList
			cpx	#$05
			bne	:101
			ldx	#$00
::101			rts

;*** CBM-File-Tabelle erzeugen.
:GetFileData		jsr	DoInfoBox		;Hinweis: "Daten werden eingelesen..."
			PrintStrgV204f0

			jsr	SetSource

			jsr	Init_3			;Zeiger auf Datenspeicher.

::101			ldy	#$0f			;CBM-Dateinamen erzeugen.
::102			lda	(a6L),y			;SHIFT-SPACE durch $00-Bytes
			cmp	#$a0			;ersetzen.
			bne	:103
			lda	#$00
			sta	(a6L),y
::103			sta	V204a0,y
			dey
			bpl	:102

			jsr	Test1File
			txa
			beq	:105
::104			rts				;Disketten-Fehler.

::105			lda	r5L
			pha
			lda	#<dirEntryBuf+23
			ldx	#>dirEntryBuf+23
			ldy	SetDateTime		;Datum-Modus ermitteln.
			beq	:107			;Datum-/Uhrzeit aus Quell-Datei.
			lda	#<year			;Datum-/Uhrzeit aus GEOS-Uhr.
			ldx	#>year
::107			sta	r0L			;Zeiger auf Datum-/Uhrzeit merken.
			stx	r0H

			ldy	#$00
::108			lda	(r0L),y			;Datum-/Uhrzeit für Ziel-Datei
			sta	(a7L),y			;speichern.
			iny
			cpy	#$05
			bne	:108

			lda	dirEntryBuf+28		;Anzahl Sektoren der CBM-Datei.
			sta	(a7L),y
			iny
			lda	dirEntryBuf+29
			sta	(a7L),y
			iny
			lda	r1L			;Zeiger auf Verzeichnis-Sektor mit
			sta	(a7L),y			;Dateieintrag.
			iny
			lda	r1H
			sta	(a7L),y
			iny
			pla				;Zeiger auf Dateieintrag in
			sta	(a7L),y			;Verzeichnis-Sektor.

			jsr	Init_4			;Zeiger auf nächste CBM-Datei.

			ldy	#$00
			lda	(a6L),y			;Ende der Tabelle erreicht ?
			beq	:109			;Ja, freien Speicher prüfen.
			jmp	:101			;Nein, weiter...

::109			ldx	#$00
			rts

;*** Dateitypen-Auswahl.
:GetFileTyp		jsr	i_MoveData		;Dateityp-Tabelle erzeugen.
			w	V204i0
			w	FileNTab
			w	V204i1-V204i0

			lda	#<V204d0
			ldx	#>V204d0
			jsr	SelectBox		;Dateityp wählen.

			lda	r13L
			cmp	#$01
			beq	:102
			bcs	:101
			ldx	r13H			;"< Alle Dateien >" ?
			bne	:103			;Nein, weiter...
::101			ldx	#$ff 			;Ja, Alle Dateien einlesen.
			stx	V204c3
::102			rts

::103			lda	V204j0,x		;Dateityp & Zeiger auf ":Class"
			sta	V204c3			;einlesen.
			txa
			asl
			tax
			lda	V204j1+0,x
			sta	V204c4+0
			lda	V204j1+1,x
			sta	V204c4+1
			rts

;*** Datei-Namen testen.
:TestFiles		jsr	SetTarget		;Ziel-Laufwerk aktivieren.
							;Zwischenspeichern.
			jsr	Init_3			;Zeiger auf Datenspeicher.

			ClrB	LinkModeOn
			bit	CBMCopyMode		;Kopiermodus einlesen.
			bpl	TestAllFiles		;CBM -> GW ? Nein, weiter...
			lda	LinkFiles		;Dateien verbinden ?
			beq	TestAllFiles		;Nein, weiter...
			dec	LinkModeOn

;*** Linkdatei erzeugen.
:TestLinkFile		jsr	ClrBox			;Infobox löschen.

			lda	#<V204a2		;"LinkFile" als Vorgabename setzen.
			ldx	#>V204a2
			jsr	CopyCurName

::101			LoadW	r3,V204e5
			jsr	GetNewName		;Name der Link-Datei eingeben.
			cmp	#$01			;"OK" ?
			bne	:106			;Nein, Abbruch.

::102			jsr	DoInfoBox		;Info: "Überprüfe Ziel-Verzeichnis..."
::103			PrintStrgV204f2

			lda	#<V204a1		;Neuer Dateiname für Link-Datei
			ldx	#>V204a1		;in Zwischenspeicher kopieren.
			jsr	CopyCurName

			jsr	Test1File		;Datei auf Ziel-Laufwerk suchen.
			txa
			beq	:104			; -> Datei vorhanden.
			jsr	ReWriteName		;Neuen Namen übernehmen.
			ldx	#$00			;"OK" !
			rts

::104			jsr	AskUser			;Sicherheitsabfrage in jedem Fall!
			cmp	#$01			;Ziel-Datei löschen ?
			bne	:105			;Nein, weiter...
			jsr	DoInfoBox		;Info: "Lösche Datei..."
			jsr	DelCBMFile		;Ziel-Datei löschen.
			jsr	ClrBoxText		;Infobox löschen.
			jmp	:103			;Datei erneut testen.

::105			cmp	#$03			;Name ändern ?
			beq	:101			;Ja, Namen für Link-Datei eingeben.
::106			ldx	#$ff			;Abbruch.
			rts

;*** Alle Dateien testen.
:TestAllFiles		jsr	ClrBoxText		;Info: "Zielverzeichnis..."
			PrintStrgV204f2
:TestNewFile		lda	a6L
			ldx	a6H
			jsr	CopyCurName		;Aktuelle Datei in Zwischenspeicher.
			bit	Duplicate		;Dateien duplizieren ?
			bpl	TestCurFile		;Nein, weiter...

			jsr	ClrBox			;Infobox löschen.
			LoadW	r3,V204e4
			jsr	SetNewName		;Name für Duplikatdatei eingeben.
			txa
			bmi	:101
			beq	:102			;"OK" ? -> Ja, weiter...
			jsr	IgnCBMFile		;Aktuelle Datei übergehen.
			txa				;Weitere Dateien ?
			bne	:101			;Nein, Abbruch.
			jmp	TestNewFile		;Weiter mit nächster Datei...
::101			ldx	#$ff
			rts

::102			lda	#<V204a1		;Neuer Dateiname für Link-Datei
			ldx	#>V204a1		;in Zwischenspeicher kopieren.
			jsr	CopyCurName
			jsr	DoInfoBox		;Info: "Zielverzeichnis..."
			PrintStrgV204f2
:TestCurFile		jsr	Test1File		;Datei auf Ziel-Laufwerk suchen.
			txa
			bne	:101			; -> Nicht gefunden, OK!
			jmp	FileIsOnDsk		;Datei vorhanden -> User-Abfrage.

::101			jsr	ReWriteName		;Name übernehmen.

;*** Nächste Datei testen.
:TestNextFile		jsr	Init_4			;Zeiger auf nächste CBM-Datei.

;*** Auf Ende der Tabelle testen.
:TestEndTab		ldy	#$00			;Tabellen-Ende erreicht ?
			lda	(a6L),y
			bne	TestNewFile
			ldx	#$00			;OK.
			rts

;*** Einzelne Datei testen.
:Test1File		LoadW	r6,V204a0		;Datei auf Ziel-Laufwerk suchen.
			jmp	FindFile

;*** Sicherheitsabfrage
;Rückgabewert:
;xReg			= $80	Nächste Datei testen.
;			= $81	Auf Tabellenende testen.
;			= $FF	Abbruch.
:FileIsOnDsk		lda	OverWrite		;Sicherheitsabfrage: Datei vorhanden.
			bmi	DoUsrInfo		; -> User-Abfrage.
			bne	IgnFile			; -> Datei ignorieren.

:DelFile		jsr	DelCBMFile		; -> Datei löschen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.
			jmp	TestNextFile		;Nächste Datei testen.
::101			rts				;Abbruch.

:IgnFile		jsr	IgnCBMFile		; -> Datei ignorieren.
			txa				;Weitere Dateien ?
			bne	:101			;Nein, Abbruch.
			jmp	TestEndTab		;Nächste Datei testen.
::101			rts				;Abbruch.

:DoUsrInfo		jsr	AskUser			; -> "File Exist" ausgeben.
			cmp	#$01			;"OK" -> Ziel-Datei wurde gelöscht.
			bne	:101			;Weiter...
			jsr	ReWriteName		;Name zurückschreiben und
			jmp	TestNextFile		;nächste Datei testen.

::101			cmp	#$02			;"Nein" -> Quell-Datei ignorieren.
			bne	:102			;Weiter...
			jmp	TestEndTab		;Nächste Datei testen.

::102			cmp	#$03			;"Name" -> Neuen Namen eingeben.
			bne	:103			;Nein, Abbruch.

			LoadW	r3,V204e3
			jsr	SetNewName		;Neuen Namen für Datei eingeben.
			txa
			bmi	:103
			bne	DoUsrInfo		;Abbruch, Modus erneut abfragen.
			lda	#<V204a1
			ldx	#>V204a1
			jsr	CopyCurName		;Neuer Name in Zwischenspeicher.

			jsr	DoInfoBox		;Infobox anzeigen.
			PrintStrgV204f2
			jmp	TestCurFile		;Datei auf Existenz testen.

::103			ldx	#$ff			;Abbruch.
			rts

;*** User-Abfrage: "Datei löschen ?"
:AskUser		jsr	ClrBox			;Infobox löschen.

::101			LoadW	r15,V204a0
			jsr	FileExist		;Abfrage: Datei löschen ?
			cmp	#$00			;"Close"...
			beq	:106			;Ja, Abbruch.

			bit	LinkModeOn		;Dateien verbinden ?
			bmi	:106			;Ja, Rücksprung...

			cmp	#$03			;"Name"...
			beq	:106			;Ja, Rücksprung...

			pha				;Rückkehr-Status merken.
			jsr	DoInfoBox		;Infobox aufbauen.
			pla

			pha				;Rückkehr-Status merken.
			cmp	#$01			;"Ja"...
			bne	:103			;Nein, weiter...
			jsr	DelCBMFile		;Ziel-Datei löschen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Datei ignorieren.
			jmp	:104			;Weiter mit nächster Datei.

::103			PrintStrgV204f2
			jsr	IgnCBMFile		;Datei übergehen.
			txa				;Weitere Dateien ?
			bne	:105			;Nein, Abbruch.

::104			jsr	ClrBoxText		;Info: "Prüfe Ziel-Verzeichnis..."
			PrintStrgV204f2
			pla
			bne	:106

::105			jsr	ClrBox			;Abbruch, oder Close-Icon.
			pla
			lda	#$00
::106			rts				;Rückkehr.

;*** Vorhandene CBM-Datei löschen.
:DelCBMFile		jsr	ClrBoxText
			PrintStrgV204f3			;Info: "Datei wird gelöscht..."
			PrintStrgV204a0

			jsr	Test1File		;Datei-Eintrag suchen.
			txa				;Gefunden ?
			beq	:101			; -> OK, Eintrag löschen.
			cpx	#$05			;Fehler: "File not found" ?
			beq	:104			; -> Nicht auf Disk, OK.
			bne	:105			; -> Diskettenfehler.

::101			LoadW	r0,V204a0
			jsr	DeleteFile
			txa
			bne	:105

			jsr	ReWriteName		;Name übernehmen.
::104			ldx	#$00			;OK.
::105			rts				;Ende...

;*** CBM-Datei ignorieren.
:IgnCBMFile		PushW	a6			;Zeiger auf Dateitabelle sichern.
			PushW	a7

::101			ldx	#$03
::102			lda	a6L,x
			sta	r0L,x
			dex
			bpl	:102

			jsr	Init_4			;Zeiger auf nächste CBM-Datei.

			ldy	#16 -1			;Eintrag verschieben.
::103			lda	(a6L),y
			sta	(r0L),y
			dey
			bpl	:103

			ldy	#10 -1
::104			lda	(a7L),y
			sta	(r1L),y
			dey
			bpl	:104

			ldy	#$00			;Alkle Dateien verschieben.
			lda	(r0L),y
			bne	:101

			PopW	a7
			PopW	a6

			ldx	#$00
			dec	AnzahlFiles		;Anzahl Dateien -1.
			bne	:105
			dex				;Abbruch, keine Dateien im Speicher.
::105			rts				;Ende.

;*** Neuen Namen für Datei eingeben.
:SetNewName		MoveW	r3,V204a3

::101			MoveW	V204a3,r3
			jsr	GetNewName		;Neuen Dateinamen eingeben.
			cmp	#$01			;"OK"...
			beq	:103
			cmp	#$02			;"Exit"...
			beq	:102
			ldx	#$ff			;Abbruch.
			b $2c
::102			ldx	#$7f			;Ungültiger Dateiname.
			rts

::103			lda	r2L			;Länge Dateiname = 0 ?
			beq	:102			;Ja, ungültiger Dateiname.

			MoveW	a6,r1
			jsr	IsNameInTab		;Name in Dateinamentabelle ?
			beq	:101			;Ja, neuer Name.
			cmp	#$ff			;Abbruch.
			bne	:102

			ldy	#$0f			;Dateiname übernehmen.
::104			lda	V204a1,y
			sta	V204a0,y
			dey
			bpl	:104

			ldx	#$00			;OK.
			rts

;*** Datei umbennen.
:GetNewName		LoadW	r0,V204a0
			LoadW	r1,V204a1		;Zwischenspeicher.
			LoadB	r2L,$ff			;Vorgabe.
			ldx	#$ff
			lda	CBMCopyMode
			and	#%00001000		;Dateien duplizieren ?
			beq	:101			;Nein, weiter...
			inx
::101			stx	r2H			;Vorgabe anzeigen.
			jmp	cbmSetName		;Name eingeben.

;*** Dateiname zwischenspeichern.
:CopyCurName		sta	r0L
			stx	r0H
			lda	#<V204a0
			ldx	#>V204a0

:CNameString		sta	r1L
			stx	r1H

			ldy	#$00
::101			lda	(r0L),y			;Name kopieren.
			beq	:102
			sta	(r1L),y
			iny
			cpy	#$10
			bne	:101
			beq	:103
::102			sta	(r1L),y
			iny
			cpy	#$10
			bne	:102
::103			rts

;*** Dateiname zurückschreiben.
:ReWriteName		LoadW	r0,V204a0
			lda	a6L
			ldx	a6H
			jmp	CNameString

;*** Einzel-Datei umbenennen.
:IsNameInTab		LoadW	r0,FileNTab		;Prüfen ob Name bereits vergeben.

::101			ldy	#$00
			lda	(r0L),y			;Ende der Tabelle erreicht ?
			beq	:105			;Ja, Name OK!

::102			lda	(r0L),y			;Name aus Tabelle mit
			cmp	V204a1,y		;eingegebenem Namen vergleichen.
			bne	:104			;Unterschiedlich, nächster Name.
			iny
			cpy	#$10
			bne	:102

			bit	Duplicate
			bmi	:103

			CmpW	r1,r0
			beq	:106

::103			DB_OK	V204g0
			lda	#$00
			rts

::104			AddVBW	16,r0			;Zeiger auf nächsten Namen
			jmp	:101			;Tabelle.

::105			lda	#$ff			;Name OK!
			rts

::106			lda	#$7f
			rts

;*** Freien Speicher auf Ziel-Laufwerk prüfen.
:CalcBytesFree		jsr	ClrBoxText		;Hinweis: "Prüfe freien Speicher..."
			PrintStrgV204f1

			jsr	GetDirHead
			LoadW	r5,curDirHead		;Max. Anzahl freier Blocks berechnen.
			jsr	CalcBlksFree

			jsr	Init_3			;Zeiger auf Datenspeicher.

			ClrW	r0			;Anzahl benötigter Blocks löschen.
::101			ldy	#$05			;Anzahl Blocks jeder Datei addieren.
			lda	(a7L),y
			clc
			adc	r0L
			sta	r0L
			iny
			lda	(a7L),y
			adc	r0H
			sta	r0H

			jsr	Init_4			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a6L),y			;Ende Tabelle erreicht ?
			bne	:101			;Nein, weiter...

			CmpW	r4,r0			;Genügend Speicher für alle Dateien ?
			bcs	:102			;Ja, weiter...

			ldx	#$ff			;Zuwenig Speicher.
			b $2c
::102			ldx	#$00			;OK.
			rts

;*** Fehler-Meldung: "Nicht genügend Speicher auf Ziel!"
:NoDiskSpace		MoveW	r0,V204a4+0
			MoveW	r4,V204a4+2

			jsr	ClrBox

			jsr	i_C_DBoxTitel
			b	$06,$05,$1c,$01
			jsr	i_C_DBoxBack
			b	$06,$06,$1c,$0c

			FillPRec$00,$28,$2f,$0030,$010f

			jsr	UseGDFont
			Print	$38,$2e
			b	PLAINTEXT,"Information",NULL

			LoadW	r0,V204h0
			DB_RecBoxL204RVec_a

			ldx	#$00
			CmpBI	sysDBData,1
			beq	:101
			dex
::101			rts

;*** Freien Speicher ausgeben.
:PrintBlocks		PrintStrgV204h1
			MoveW	V204a4+0,r0
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV204h3

			PrintStrgV204h2
			MoveW	V204a4+2,r0
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV204h3

			jsr	i_C_DBoxDIcon
			b	$08,$0f,$06,$02
			jsr	i_C_DBoxDIcon
			b	$1a,$0f,$06,$02
			jmp	ISet_Achtung

;*** Farben zurücksetzen.
:L204RVec_a		jsr	i_C_ColorClr
			b	$06,$05,$1c,$0d
			FillPRec$00,$28,$8f,$0030,$010f
			rts

;*** Dateien einlesen
:CBM_GetFiles		sta	V204d3 +0		;Zeiger auf Titel für Auswahlbox.
			stx	V204d3 +1
			sty	V204c2			;Dateimodus.

:GetFiles_a		lda	Source_Drv 		;Ziel-Laufwerk.
			ldx	#$00			;Diskette einlegen.
			jsr	InsertDisk
			cmp	#$01
			beq	L204a0
			ldx	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

;*** Zeiger auf ersten Datei-Eintrag.
:L204a0			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			rts				;Diskettenfehler anzeigen.

::101			lda	curDirHead+0		;Ersten Verzeichnis-Sektor speichern.
			sta	V204b1    +0
			lda	curDirHead+1
			sta	V204b1    +1
			lda	#$00
			sta	V204b2			;Zeiger auf Eintrag.
			sta	V204b0			;"Verzeichnisende"-Flag löschen.

;*** Dateien einlesen..
:L204a1			jsr	L204b0			;Dateien einlesen.
			txa
			beq	L204a2
			rts

;*** Datei-Auswahl-Box.
:L204a2			MoveB	r1L,V204b1+0		;Verzeichnis-Position merken.
			MoveB	r1H,V204b1+1
			lda	V204b0			;"Dateien auf Diskette"-Flag setzen.
			ora	#%01000000
			sta	V204b0

			MoveB	V204c1,V204d2		;Anzahl Action-Files in Tabelle.

			lda	#<V204d1		;Dateien auswählen.
			ldx	#>V204d1
			jsr	SelectBox

			lda	r13L
			beq	:105			;$00 = Dateien gewählt.
			cmp	#$01
			beq	:102			;$01 = "OK" ohne Dateiauswahl.
			cmp	#$90
			beq	:106			;$90 = Partition wählen.
			cmp	#$ff
			beq	:104			;$FF = Action-File gewählt.
::101			ldx	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

::102			bit	V204b0			;Verzeichnisende erreicht ?
			bpl	:103			;Nein, weiter...
			jmp	L204a0			;Zum Anfang zurück.
::103			jmp	L204a1			;Directory weiterlesen.

::104			ldx	#$00			;Dateien gewählt.
			rts				;Ende.

::105			jsr	GetFileTyp		;Dateityp wählen.
			jmp	GetFiles_a		;Dateien einlesen.

::106			lda	Source_Drv
			jsr	NewDrive
			txa
			bne	:107
			jsr	CMD_NewTarget		;Partition wählen.

			ldy	#$02
::106a			lda	TDrvPart,y
			sta	SDrvPart,y
			lda	TDrvNDir,y
			sta	SDrvNDir,y
			dey
			bpl	:106a

			jsr	SetSource

::107			jmp	GetFiles_a		;Dateien einlesen.

;*** max. 255 Dateien einlesen.
:L204b0			jsr	DoInfoBox		;Infobox anzeigen.
			PrintStrgDB_RdFile

			LoadW	r15,FileNTab		;Zeiger auf Dateitabelle.
			lda	#$00
			sta	V204c0			;Anzahl Dateien löschen.
			sta	V204c1			;Anzahl Action-Files löschen.

			lda	V204c2			;Dateimodus einlesen.
			and	#%00100000		;Dateiauswahl erlauben ?
			beq	:101			;Nein, weiter...

			jsr	i_MoveData		;"< Dateityp wählen >"-Eintrag
			w	V204e6+1		;in Tabelle kopieren.
			w	FileNTab
			w	$0010

			AddVBW	16,r15			;Zeiger auf nächsten Eintrag.
			inc	V204c1

::101			MoveB	V204b1+0,r1L		;Zeiger auf nächsten Verzeichnis-
			MoveB	V204b1+1,r1H		;Sektor in Zwischenspeicher.

;*** Max. 255 Dateien einlesen.
:L204b1			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor lesen.
			jsr	GetBlock
			txa
			beq	:104			;Auf Verzeichnisende prüfen.
::101			rts

::102			lda	V204b2			;Zeiger auf Eintrag berechnen.
			asl
			asl
			asl
			asl
			asl
			sta	V204b3
			inc	V204b2

::103			jsr	ChkDirEntry		;Eintrag auf Gültigkeit testen.
			txa				;Eintrag OK ?
			bmi	:104			;Nein, weiter...
			bne	:101			;Diskettenfehler.

			jsr	CopyFileInTab		;Eintrag in Tabelle kopieren.
			txa				;Speicher voll ?
			bne	:106			;Ja, Ende.

;*** Noch ein Eintrag im Sektor ?
::104			lda	V204b2			;Folgt weiterer Eintrag im Sektor ?
			cmp	#$08
			bne	:102			;Nächster Eintrag.

			ClrB	V204b2			;Zeiger auf Eintrag löschen.

			lda	diskBlkBuf+0		;Folgt weiterer Verzeichnis-Sektor ?
			beq	:105			;Nein, Ende.
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	L204b1			;Nächsten Verzeichnis-Sektor lesen.

::105			lda	V204b0
			ora	#%10000000
			sta	V204b0

;*** Tabellen-Ende markieren.
::106			ldy	#$00
			tya
			sta	(r15L),y		;Tabellen-Ende markieren.
			jsr	ClrBox
			ldx	#$00
			rts

;*** Infoblock einlesen.
:L204b2			PushW	r1			;Zeiger auf Verzeichnis-Sektor sichern.

			lda	diskBlkBuf+21,x
			sta	r1L
			lda	diskBlkBuf+22,x
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;Fileheader einlesen.

			PopW	r1

			rts

;*** ":Class" vergleichen.
:L204b3			ldy	#$00			;Auf GeoWrite-Dokument testen.
::101			lda	(r0L),y
			beq	:102
			cmp	fileHeader+77,y
			bne	:103
			dey
			bpl	:101

::102			ldx	#$00
			rts

::103			ldx	#$ff
			rts

;*** Eintrag überprüfen.
;Übergabewert:
;V204b3 = Zeiger auf Eintrag in Dir-Sektor (0-7).
;
;Rückgabewert:
;xReg = $00, Datei übernehmen.
;
:ChkDirEntry		ldx	V204b3			;Zeiger auf Verzeichniseintrag.
			lda	diskBlkBuf+2,x		;Dateityp-Byte einlesen.
;			and	#%01111111		;Nur SEQ,PRG,USR Dateien auswählen.
;			beq	:101
;---
			and	#%00001111		;Dateityp Bit%0-3 isolieren.
			beq	:101			;$x0 = Deleted, ignorieren.
;---
			cmp	#$04			;Dateityp SEQ,PRG,USR ?
			bcc	:103			;Ja, weiter...
::101			ldx	#$ff			;Eintrag nicht übernehmen.
::102			rts

;*** Dateityp testen.
::103			bit	V204c2			;Alle Dateien einlesen ?
			bmi	:106			;Ja, weiter...
			bvs	:104			;VLIR-Files suchen...

;*** Sequentielle Dateien.
			lda	V204c2			;Auswahlmodus einlesen.
			and	#%00100000		;GEOS-Dateityp beachten ?
			bne	:105			;Ja, Dateityp prüfen.
			lda	diskBlkBuf+23,x
			bne	:101			;VLIR-Datei ? Ja, nächste Datei.
			beq	:106			;Nein, Datei übernehmen.

;*** GeoWrite-Dateien.
::104			lda	diskBlkBuf+23,x		;GEOS-Dateityp <> $00 ?
			beq	:101			;Ja  , keine VLIR-Datei, übergehen.
			lda	diskBlkBuf+21,x		;Infoblock vorhanden ?
			beq	:101			;Nein, keine VLIR-Datei, übergehen.

			jsr	L204b2			;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			LoadW	r0,V204k0
			jsr	L204b3			;GEOS-Klasse vergleichen.
			txa
			bne	:101			;Kein GeoWrite-Dokument.
			beq	:106			;GeoWrite-Dokument übernehmen.

;*** VLIR-Dateien mit GEOS-Klasse.
::105			bit	V204c3			;GEOS-Dateityp testen ?
			bmi	:106			;Nein, weiter...
			lda	diskBlkBuf+24,x		;GEOS-Dateityp
			cmp	V204c3			;mit Maske vergleichen.
			bne	:101			;Falscher Dateityp, übergehen.

			lda	V204c4+1		;GEOS-Klasse vergleichen ?
			beq	:106			;Nein, weiter...

			jsr	L204b2			;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			MoveW	V204c4,r0
			jsr	L204b3			;GEOS-Klasse vergleichen.
			txa
			bne	:101			;Falsche GEOS-Klasse, übergehen.

::106			ldx	#$00			;Datei übernehmen.
			rts

;*** Dateieintrag in Tabelle kopieren.
;Übergabewert:
;
;Rückgabewert:
;xReg = $00, OK.
;     = $FF, Speicher voll.
:CopyFileInTab		ldx	V204b3			;Zeiger auf Verzeichniseintrag.
			ldy	#$00			;Dateinae übertragen.
::101			lda	diskBlkBuf+5,x
			cmp	#$a0
			bne	:102
			lda	#$00
::102			sta	(r15L),y
			iny
			inx
			cpy	#$10
			bne	:101

			AddVBW	16,r15			;Zeiger auf nächsten Speicherplatz
			inc	V204c0			;für Datei-Einträge.

			ldx	#$00
			lda	V204c0
			cmp	#$ff			;Speicher voll ?
			bne	:103			;Ja, Ende...
			dex
::103			rts

;*** Variablen.
:CBMCopyMode		b $00				;Kopiermodus.
:CCM2			b $00				;Kopiermodus.
:Duplicate		b $00				;$FF = Dateien duplizieren.
:LinkModeOn		b $00				;Dateien linken.

;*** Info-Block für Parameter-Textdatei.
:HdrB000		w HdrName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w FileNTab
			w FileNTab + 16*256
			w FileNTab
:HdrClass		b "GD_FileList V"		;Klasse.
			b "1.0"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64",$00		;Autor.
:HdrEnd			b $00

:HdrName		b "GD_FileList.temp",NULL

;*** Variablen.
:V204a0			s 17				;Zwischenspeicher Dateiname.
:V204a1			s 17				;Eingabe Dateiname.
:V204a2			b "LinkFile",0,0,0,0,0,0,0,0,0
:V204a3			w $0000				;Zeiger auf Titel.
:V204a4			s $04

:V204b0			b $00				;$FF = Directory-Ende.
:V204b1			b $00,$00			;Aktueller Directory-Sektor.
:V204b2			b $00				;Zeiger auf Eintrag.
:V204b3			b $00				;Zeiger auf Byte in Sektor.

:V204c0			b $00				;Anzahl Dateien.
:V204c1			b $00				;Anzahl ACTION-Files
:V204c2			b $00				;%1xxxxxxx = Alle Dateien.
							;%00xxxxxx = Seq.-Dateien.
							;%01xxxxxx = GeoWrite-Dateien.
							;%001xxxxx = Dateityp-Auswahl nach Vorgabe.
:V204c3			b $ff				;$FF = Alle Dateien.
							;$xx = Dateityp.
:V204c4			w $0000				;Zeiger auf ":Class"

;*** Dateiauswahlbox.
:V204d0			b $00				;Dateityp wählen.
			b $00
			b $00
			b $10
			b $00
			w V204e6
			w FileNTab

:V204d1			b $ff				;Dateien wählen.
			b $ff
			b $ff
			b $10
:V204d2			b $00
:V204d3			w $ffff
			w FileNTab

if Sprache = Deutsch
;*** Titel.
:V204e0			b PLAINTEXT,"Partition Ziel-Laufwerk",NULL
:V204e1			b PLAINTEXT,"Dateien wählen",NULL
:V204e2			b PLAINTEXT,"GeoWrite-Texte wählen",NULL
:V204e3			b PLAINTEXT,"Dateiname ändern",NULL
:V204e4			b PLAINTEXT,"Neuer Dateiname",NULL
:V204e5			b PLAINTEXT,"Name der Gesamtdatei",NULL
:V204e6			b PLAINTEXT,"Dateityp wählen",NULL
:V204e7			b PLAINTEXT,"Ziel-Verzeichnis",NULL
endif

if Sprache = Englisch
;*** Titel.
:V204e0			b PLAINTEXT,"Partition target-drive",NULL
:V204e1			b PLAINTEXT,"Select files",NULL
:V204e2			b PLAINTEXT,"Select write-document",NULL
:V204e3			b PLAINTEXT,"Edit filename",NULL
:V204e4			b PLAINTEXT,"New filename",NULL
:V204e5			b PLAINTEXT,"Name of targetfile",NULL
:V204e6			b PLAINTEXT,"Select filetype",NULL
:V204e7			b PLAINTEXT,"Target directory",NULL
endif

if Sprache = Deutsch
;*** Infoboxen.
:V204f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei-Informationen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

:V204f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Prüfe freien Speicher"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf dem Ziel-Laufwerk..."
			b NULL

:V204f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Überprüfe das"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Zielverzeichnis..."
			b NULL

:V204f3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Fehlermeldungen.
:V204g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Der gewählte Dateiname",NULL
::102			b        "ist bereits vergeben!",NULL

;*** Fehler: "Nicht genügend freier Speicher auf Ziel-Disk!"
:V204h0			b %00100000
			b 48,143
			w 48,271
			b OK        ,  2, 72
			b CANCEL    , 20, 72
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w :101
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w :102
			b DB_USR_ROUT
			w PrintBlocks
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Nicht genügend freier",NULL
::102			b "Speicher auf Zieldiskette!",NULL

:V204h1			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Benötigt ca."
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V204h2			b GOTOXY
			w DBoxLeft +$0030
			b 109
			b "Verfügbar"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V204h3			b " Block(s)",NULL
endif

if Sprache = Englisch
;*** Infoboxen.
:V204f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Reading file-"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "information..."
			b NULL

:V204f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Check free diskspace"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on targetdisk..."
			b NULL

:V204f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Check directory"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on targetdisk..."
			b NULL

:V204f3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Delete file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Fehlermeldungen.
:V204g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Selected filename",NULL
::102			b        "already exist!",NULL

;*** Fehler: "Nicht genügend freier Speicher auf Ziel-Disk!"
:V204h0			b %00100000
			b 48,143
			w 48,271
			b OK        ,  2, 72
			b CANCEL    , 20, 72
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w :101
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w :102
			b DB_USR_ROUT
			w PrintBlocks
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Not enough diskspace",NULL
::102			b "available on targetdisk!",NULL

:V204h1			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Needed"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V204h2			b GOTOXY
			w DBoxLeft +$0030
			b 109
			b "Available"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V204h3			b " Block(s)",NULL
endif

if Sprache = Deutsch
;*** GEOS-Dateitypen.
:V204i0			b "< Alle Dateien >"
			b "Anwendungen     "
			b "Assembler       "
			b "BASIC           "
			b "Datenfiles      "
			b "DeskAccessories "
			b "Dokumente       "
			b "Dok. GeoWrite   "
			b "Dok. GeoPaint   "
			b "Druckertreiber  "
			b "Eingabetreiber  "
			b "Eingabetr. C128 "
			b "GateWay-Dokument"
			b "GeoShell-Befehle"
			b "GeoFAX-Drucker  "
			b "Laufwerkstreiber"
			b "Nicht GEOS      "
			b "Selbstausführend"
			b "Startprogramme  "
			b "System-Dateien  "
			b "Temporärdateien "
			b "Zeichensätze    "
			b NULL
endif

if Sprache = Englisch
;*** GEOS-Dateitypen.
:V204i0			b "<  All types   >"
			b "Applications    "
			b "Assembler       "
			b "BASIC           "
			b "Datafiles       "
			b "DeskAccessories "
			b "Documents       "
			b "Doc. GeoWrite   "
			b "Doc. GeoPaint   "
			b "Printerdriver   "
			b "Inputdriver     "
			b "Input C128      "
			b "GateWay-Document"
			b "GeoShell-command"
			b "GeoFAX-printer  "
			b "Diskdriver      "
			b "Not GEOS        "
			b "Auto-execute    "
			b "Bootfiles       "
			b "Systemfiles     "
			b "Temporary       "
			b "Fonts           "
			b NULL
endif

:V204i1

:V204j0			b $00
			b $06,$02,$01,$03,$05,$07,$07,$07
			b $09,$0a,$0f,$11,$15,$16,$0b,$00
			b $0e,$0c,$04,$0d,$08

:V204j1			w $0000
			w $0000,$0000,$0000,$0000,$0000,$0000,V204k0,V204k1
			w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
			w $0000,$0000,$0000,$0000,$0000

:V204k0			b "Write Image ",NULL
:V204k1			b "Paint Image ",NULL
