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
			t	"src.DOSDRIVE.ext"
endif

			n	"mod.#203.obj"
			o	ModStart
			r	FileDTab2 -1

			jmp	CBMtoDOS

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetSourceCBM"
			t   "-SetTargetDOS"

			t   "-FileExist"
			t   "-GetConvTab2"
			t   "-DOS_SetName"

;*** L203: Datei von CBM nach MS-DOS kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

;*** Datei von CBM nach CBM kopieren
;xReg = %00000000	-> Text nach Text.
;       %10000000	-> GeoWrite nach Text.
;       %01000000	-> CBM  nach DOS 1:1.

:CBMtoDOS		jsr	Init_1			;Register initialisieren.
:CBMtoDOS_1		jsr	GetFileToCopy		;Dateien auswählen.
			txa
			bmi	L203ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	GetTarget		;Ziel-Partition wählen
			txa
			bmi	L203ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

:CBMtoDOS_2		jsr	GetFileData		;Datei-Informationen einlesen.
			txa
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	SetDOSName		;MSDOS-Dateinamen definieren.
			txa
			bne	L203ExitGD		;Zurück zum Hauptmenü.

			jsr	TestFiles		;Dateien auf Ziel-Laufwerk testen.
			txa
			bmi	L203ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	FreeDirEntry		;Freie Einträge auf Diskette prüfen.
			txa
			bmi	L203ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	CalcFreeClu
			txa
			beq	:101			;Zurück zum Hauptmenü.

			jsr	NoDirCluster		;Fehler: "Unterverzeichnis voll!"
			txa
			beq	CBMtoDOS_1
			bne	L203ExitGD

::101			jsr	CalcBytesFree		;Speicher auf Ziel-Laufwerk testen.
			txa
			beq	InitForCopy

			jsr	GetFreeBytes
			jsr	NoDiskByte		;Fehler: "Zu wenig freier Speicher..."
			txa
			beq	CBMtoDOS_1

;*** Zurück zu GeoDOS.
:L203ExitGD		jmp	InitScreen		;Zurück zum Hauptmenü.
:ExitDskErr		jmp	DiskError		;Diskettenfehler anzeigen.

;*** Dateien kopieren.
:InitForCopy		jsr	ClrBoxText		;Diskettenverzeichnis
			PrintStrgV203i4			;aktualisieren.

			jsr	Save_FAT
			jsr	ClrBox

			jsr	SetGEOSDate		;Datum erzeugen.

			jsr	InitForIO
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00

;*** Konvertierungstabelle laden.
:GetConvTab		lda	CTabCBMtoDOS
			ldx	#<SCREEN_BASE
			ldy	#>SCREEN_BASE
			jsr	LoadConvTab

;*** Dateiudaten in Zwischenspeicher kopieren.
			jsr	i_MoveData
			w	FileNTab
			w	SCREEN_BASE+ 1*256
			w	16*256
			jsr	i_MoveData
			w	FileDTab2
			w	SCREEN_BASE+17*256
			w	8 *256

			lda	CBMCopyMode		;Kopiermodus einlesen.
			and	#%11000000
			beq	:101			;-> Text nach Text.
			cmp	#%10000000
			beq	:102			;-> Text nach GeoWrite.
			cmp	#%01000000
			beq	:103			;-> CBM  nach DOS 1:1.
			jmp	L203ExitGD		;Zurück zu GeoDOS.
::101			jmp	vC_CBMtoDOS
::102			jmp	vC_GWtoDOS
::103			jmp	vC_CBMtoDOS_F
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

;*** Zeiger auf Datenspeicher.
:Init_3			LoadW	a6,FileNTab		;Tabelle Datei-Namen.
			LoadW	a7,FileDTab2		;Tabelle Datei-Datum.
			rts

;*** Zeiger auf nächste Datei.
:Init_4			AddVBW	16,a6
			AddVBW	8 ,a7			;Zeiger auf nächste CBM-Datei.
			rts

;*** Dateien wählen.
:GetFileToCopy		lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive
			txa
			bne	:104

::101			LoadW	r10,FileNTab		;Zeiger auf Zwischenspeicher.
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
:InitSlctFiles		bit	CBMCopyMode		;Kopiermodus einlesen.
			bmi	:102			;-> GW-Dokumente kopieren.

::101			lda	#<Titel_File		;Zeiger auf Titel für "SEQ-Dateien".
			ldx	#>Titel_File
			jmp	:103

::102			lda	#<V203f1		;Zeiger auf Titel für "GW-Dateien".
			ldx	#>V203f1

::103			jsr	CBM_GetFiles		;Dateien einlesen.
			txa
			bne	:105			;xReg =  $FF, Ende.
							;     <> $00, Diskettenfehler.

;*** Dateien ausgewählt, Ende.
;    xReg ist hier auf NULL!
::104			lda	r13H			;Anzahl Dateien merken.
			sta	AnzahlFiles
			ldx	#$00
::105			rts

;*** Ziel-Partition öffnen.
:GetTarget		lda	Target_Drv
			jsr	NewDrive
			txa
			bne	:105

			jsr	SaveCopyFiles		;Dateinamentabelle sichern.
			txa
			bne	:104

			jsr	DOS_GetTDir
			txa
			bne	:103

			pha
			lda	r0L
			sta	DOS_TargetDir
			bne	:101
			tax
			tay
			beq	:102
::101			ldx	r1L
			ldy	r1H
::102			stx	DOS_TargetClu+0
			sty	DOS_TargetClu+1
			pla

::103			sta	:105 +1
			jsr	LoadCopyFiles		;Dateinamentabelle sichern.
			txa
			beq	:105
::104			jmp	GDDiskError

::105			ldx	#$ff
			rts

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
			PrintStrgV203i0

			jsr	SetSource		;Quell-Laufwerk aktivieren.

			jsr	Init_3			;Zeiger auf Datenspeicher.

			ClrB	V203a1			;Anzahl Dateien = 0.

::101			LoadW	r6,V203a3		;CBM-Datei-Eintrag lesen.
			ldx	#a6L
			ldy	#r6L
			lda	#16
			jsr	CopyFString
			jsr	FindFile
			txa
			beq	:103
::102			rts

::103			ldx	#$04			;Datei-Datum, -Uhrzeit.
::104			lda	dirEntryBuf+23,x
			sta	r2L,x
			dex
			bpl	:104

			jsr	SetDate			;DOS-Datum erzeugen.

			ldy	#$03
::105			lda	r0,y
			sta	(a7L),y
			dey
			bpl	:105

			ldy	dirEntryBuf+28		;Anzahl Sektoren der CBM-Datei.
			ldx	dirEntryBuf+29
			lda	dirEntryBuf+19		;Infoblock vorhanden ?
			beq	:107
			dey				;Ja, Dateigröße -1.
			cpy	#$ff
			bne	:107
			dex
::107			lda	dirEntryBuf+21		;VLIR-File ?
			beq	:108
			dey				;Ja, Dateigröße -1.
			cpy	#$ff
			bne	:108
			dex
::108			tya
			ldy	#$04			;Dateigröße merken.
			sta	(a7L),y
			iny
			txa
			sta	(a7L),y
			iny
			lda	dirEntryBuf +1		;Erster Sektor der Datei.
			sta	(a7L),y
			iny
			lda	dirEntryBuf +2
			sta	(a7L),y

			inc	V203a1			;Zähler für Anzahl Dateien +1.
			jsr	Init_4			;Zeiger auf nächste CBM-Datei.

			ldy	#$00
			lda	(a6L),y			;Ende erreicht ?
			beq	:109
			jmp	:101			;Nein, weiter...

::109			ldx	#$00
			rts

;*** MSDOS-Dateinamen definieren.
:SetDOSName		jsr	ClrBox

			lda	FileNameMode
			beq	DefDOSName		;DOS-Namen automatisch erzeugen ?
			jmp	NewDOSName		;Nein, alle Namen neu eingeben.

;*** MSDOS-Dateinamen vorschlagen.
:DefDOSName		jsr	Init_3			;Zeiger auf Datenspeicher.

::101			ldy	#$00
			lda	(a6L),y			;Ende der Tabelle erreicht ?
			bne	:102			;Nein, Dateiname nach MSDOS wandeln.
			jmp	DoDOSNameTab		;Ja, Auswahlbox anzeigen.

::102			jsr	PrepNameDOS		;CBM-Dateiname nach MSDOS wandeln.
			cpx	#$00			;Dateiname gültig ?
			bne	:103			;Nein, neu eingeben.

			MoveW	a6,r1
			jsr	IsNameInTab		;Prüfen ob Dateiname schon vergeben.
			txa
			bne	:103			;Ja, neu eingeben.
			jmp	:104			;Weiter mit nächster Datei.

::103			ldx	#%01000000
			jsr	SetNewName
			txa				;Eingabe mit "OK" beendet ?
			beq	:104			;Ja, weiter...
			ldx	#$ff			;Zurück zu GeoDOS.
			rts

::104			jsr	ReWriteName

::105			jsr	Init_4			;Zeiger auf nächste CBM-Datei.
			jmp	:101

;*** Neuen Namen eingeben.
:NewDOSName		jsr	Init_3			;Zeiger auf Datenspeicher.

::101			jsr	PrepNameDOS		;CBM-Dateiname nach MSDOS wandeln.

			ldx	#%01000000
			jsr	SetNewName
			txa				;Eingabe mit "OK" beendet ?
			beq	:102			;Ja, weiter...
			ldx	#$ff			;Zurück zu GeoDOS.
			rts

::102			jsr	ReWriteName		;Name in Tabelle zurückschreiben.

			jsr	Init_4			;Zeiger auf nächste CBM-Datei.

			ldy	#$00
			lda	(a6L),y			;Ende der Tabelle erreicht ?
			bne	:101			;Nein, nächste Datei.

;*** Tabelle mit Dateinamen anzeigen.
:DoDOSNameTab		lda	#<V203e0
			ldx	#>V203e0
			jsr	SelectBox

			lda	r13L			;"OK" mit Dateiauswahl ?
			beq	:102			;Ja, Dateiname ändern.
			cmp	#$01			;"OK" ?
			bne	:103			;Ja, Eingabe beenden.
::101			ldx	#$00
			rts

::102			lda	r15L
			ldx	r15H
			sta	a6L
			stx	a6H
			jsr	CopyCurName

			ldx	#%11111111
			jsr	SetNewName
			txa				;Eingabe mit "OK" beendet ?
			bne	:103			;Nein, Abbruch...

			jsr	ReWriteName
			jmp	DoDOSNameTab		;Zurück zur Auswahl-Tabelle.

::103			ldx	#$ff			;Zurück zu GeoDOS.
			rts

;*** Datei-Namen testen.
:TestFiles		jsr	SetTarget		;Target-Drive aktivieren.

			jsr	DoInfoBox		;Hinweis: "Prüfe Ziel-Verzeichnis..."
			PrintStrgV203i2

			jsr	Init_3			;Zeiger auf Datenspeicher.

;*** Nächste Datei testen.
:TestNewFile		lda	a6L
			ldx	a6H
			jsr	CopyCurName

:TestCurFile		jsr	Test1File
			txa
			bmi	:102
			bne	:101
			jmp	FileIsOnDsk
::101			rts

::102			jsr	ReWriteName

;*** Nächste Datei testen.
:TestNextFile		jsr	Init_4			;Zeiger auf nächsten Eintrag.

;*** Auf Ende der Tabelle testen.
:TestEndTab		ldy	#$00
			lda	(a6L),y
			bne	TestNewFile
			ldx	#$00
			rts

;*** Aktuelle Datei in Tabelle suchen.
:Test1File		LoadW	r10,V203a3
			jsr	LookDOSfile
			cpx	#$05
			bne	:101
			ldx	#$ff
::101			rts

;*** Sicherheitsabfrage
:FileIsOnDsk		ldy	#$0b			;Falls DOS-Eintrag ein Sub-Dir ist,
			lda	(a8L),y			;CBM-Datei immer ignorieren.
			cmp	#%00010000
			beq	IgnFile

			lda	OverWrite		;Sicherheitsabfrage: Datei vorhanden.
			bmi	DoUsrInfo		; -> User-Abfrage.
			bne	IgnFile			; -> Datei ignorieren.

:DelFile		jsr	DelDOSFile		; -> Datei löschen.
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

			ldx	#%11111111
			jsr	SetNewName		;Neuen Namen für Datei eingeben.
			txa
			bmi	:103
			bne	DoUsrInfo		;Abbruch, Modus erneut abfragen.
			lda	#<V203a4
			ldx	#>V203a4
			jsr	CopyCurName		;Neuer Name in Zwischenspeicher.

			jsr	DoInfoBox		;Infobox anzeigen.
			PrintStrgV203i2
			jmp	TestCurFile		;Datei auf Existenz testen.

::103			ldx	#$ff			;Abbruch.
			rts

;*** User-Abfrage: "Datei löschen ?"
:AskUser		jsr	ClrBox			;Infobox löschen.

::101			LoadW	r15,V203a3
			jsr	FileExist		;Abfrage: Datei löschen ?
			cmp	#$00			;"Close"...
			beq	:106			;Ja, Abbruch.

			cmp	#$03			;"Name"...
			beq	:106			;Ja, Rücksprung...

::102			pha				;Rückkehr-Status merken.
			jsr	DoInfoBox		;Infobox aufbauen.
			pla

			pha				;Rückkehr-Status merken.
			cmp	#$01			;"Ja"...
			bne	:103			;Nein, weiter...
			jsr	DelDOSFile		;Ziel-Datei löschen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Datei ignorieren.
			jmp	:104			;Weiter mit nächster Datei.

::103			PrintStrgV203i2
			jsr	IgnCBMFile		;Datei übergehen.
			txa				;Weitere Dateien ?
			bne	:105			;Nein, Abbruch.

::104			jsr	ClrBoxText		;Info: "Prüfe Ziel-Verzeichnis..."
			PrintStrgV203i2
			pla
			bne	:106

::105			jsr	ClrBox			;Abbruch, oder Close-Icon.
			pla
			lda	#$00
::106			rts				;Rückkehr.

;*** Vorhandene DOS-Datei löschen.
:DelDOSFile		jsr	ClrBoxText
			PrintStrgV203i3			;Hinweis: "Datei wird gelöscht..."
			PrintStrgV203a3

			ldy	#$00			;Datei-Name löschen.
			lda	#$e5
			sta	(a8L),y

			PushW	a8			;Veränderten Dir-Sektor speichern.
			LoadW	a8,Disk_Sek
			jsr	D_Write
			PopW	a8

			ldy	#$1a			;Start-Cluster einlesen.
			lda	(a8L),y
			sta	r1L
			iny
			lda	(a8L),y
			sta	r1H

			ClrW	r4

::101			lda	r1L			;Zeiger auf aktuellen Cluster
			ldx	r1H
			cmp	#$00
			bne	:102
			cpx	#$00
			beq	:103
::102			jsr	Get_Clu			;Link auf nächsten Cluster lesen.
			PushW	r1			;Link-Wert merken.
			lda	r2L
			ldx	r2H
			jsr	Set_Clu			;Aktuellen Cluster freigeben.
			pla				;Nächsten Cluster bestimmen.
			sta	r1L
			tay
			pla
			sta	r1H
			and	#%00001111
			cmp	#$0f
			bne	:101
			cpy	#$f8
			bcc	:101

::103			LoadB	BAM_Modify,$ff

			jsr	ReWriteName		;Name zurück in Tabelle schreiben.
			ldx	#$00
			rts

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

;*** CBM-Dateiname nach MSDOS wandeln.
:PrepNameDOS		MoveW	a6,r0
			jsr	ConvTextDOS		;Zeichen nach MSDOS wandeln.

			LoadW	r1,V203a3
			LoadB	NameTypeDOS,$ff
			jsr	ConvNameDOS		;Dateiname nach 8+3 wandeln.

			ldy	#12
			lda	#$00
::101			sta	V203a3,y
			iny
			cpy	#17
			bcc	:101
			rts

;*** Neuen Namen für Datei eingeben.
:SetNewName		stx	InputMode

::101			jsr	GetNewName		;Neuen Dateinamen eingeben.
			cmp	#$01			;"OK"...
			beq	:103
			cmp	#$02			;"Exit"...
			beq	:102
			ldx	#$ff			;Abbruch.
			b $2c
::102			ldx	#$7f			;Ungültiger Dateiname.
			rts

::103			MoveW	a6,r1
			jsr	IsNameInTab		;Name in Dateinamentabelle ?
			txa
			bne	:101			;Ja, neuer Name.

			ldy	#11			;Dateiname übernehmen.
::104			lda	V203a4,y
			sta	V203a3,y
			dey
			bpl	:104
			ldx	#$00			;OK.
			rts

;*** Datei umbennen.
:GetNewName		LoadW	r0,V203a3
			LoadW	r1,V203a4		;Zwischenspeicher.
			LoadB	r2L,$ff			;Vorgabe.
			MoveW	InputMode,r2H
			LoadW	r3,V203f2
			jmp	dosSetName		;Name eingeben.

;*** Dateiname zwischenspeichern.
:CopyCurName		sta	r0L
			stx	r0H
			lda	#<V203a3
			ldx	#>V203a3
			jmp	CNameString

;*** Dateiname zurückschreiben.
:ReWriteName		LoadW	r0,V203a3

			lda	a6L
			ldx	a6H

;*** Dateiname kopieren.
:CNameString		sta	r1L
			stx	r1H

			ldy	#$00
::101			lda	(r0L),y			;Name kopieren.
			beq	:103
			sta	(r1L),y
			iny
::102			cpy	#12
			bne	:101
			lda	#$00
::103			sta	(r1L),y
			iny
			cpy	#$10
			bne	:103
			rts

;*** Prüfen ob Dateiname schon vergeben.
:IsNameInTab		LoadW	r0,FileNTab		;Zeiger auf Anfang Dateitabelle.

::101			ldy	#$00
			lda	(r0L),y			;Ende der Tabelle erreicht ?
			beq	:106			;Ja, Name OK!
::102			lda	(r0L),y			;Name aus Tabelle mit
			cmp	V203a3,y		;eingegebenem Namen vergleichen.
			bne	:105			;Unterschiedlich, nächster Name.
			iny
			cpy	#$0c
			bne	:102

::103			CmpW	r0,r1			;Name = Quell-Dateiname ?
			beq	:105			;Ja, ignorieren.

::104			DB_OK	V203g0			;Fehler: "Name vorhanden!"
			ldx	#$ff
			rts

::105			AddVBW	16,r0			;Zeiger auf nächsten Dateinamen.
			jmp	:101			;Tabelle.

::106			ldx	#$00			;Name OK!
			rts
;*** Suche nach freiem Eintrag im Verzeichnis.
:FreeDirEntry		lda	#$00
			sta	V203a0			;Anzahl freie Directory-Einträge = 0.
			jsr	ResetDir		;Zeiger auf Verzeichnis zurücksetzen.
			txa
			beq	L203a1			;Alle Einträge aus Sektor gelesen ?
			rts

;*** Nächsten Eintrag prüfen.
:L203a0			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			beq	:101
			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			bne	:102			;Ja, ignorieren.

::101			inc	V203a0			;Anzahl freie Directory-Einträge + 1.

			lda	V203a0			;Genügend freie Einträge für alle
			cmp	AnzahlFiles		;Dateien verfügbar ?
			bne	:102			;Nein, weitersuchen.
			ldx	#$00			;Ende, OK
			rts

::102			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V203d8			;Eintrag im Verzeichnis.

;*** Alle Einträge aus Sektor geprüft ?
:L203a1			CmpBI	V203d8,16		;Alle Einträge geprüft ?
			bne	L203a0			;Nein, weiter...

			ClrB	V203d8			;Zeiger auf Sektor-Eintrag löschen.

			jsr	GetNxDirSek		;Nächsten Directory-Sektor lesen.
			txa				;Verzeichnis-Sektor gefunden ?
			beq	L203a0			;Ja, weiter...
			bpl	:101			; -> Diskettenfehler.

			lda	V203d0			;Unterverzeichnis ?
			bne	GetNxFreClu		;Ja, weiter...
			ldx	#$47			;Fehler: "Hauptverzeichnis voll".
::101			rts

;*** Freien Cluster suchen.
:GetNxFreClu		jsr	Max_Free		;Diskettendaten berechnen.
			LoadW	r2,$0002		;Zeiger auf ersten Cluster.

::101			lda	r2L
			ldx	r2H			;Link-Pointer des Clusters
			jsr	Get_Clu			;einlesen.
			CmpW0	r1			;Ist Cluster frei ?
			beq	:102			;Ja, weiter...

			IncWord	r2			;Nein, Zeiger auf nächsten Cluster.

			SubVW	1,FreeClu
			CmpW0	FreeClu			;Alle Cluster geprüft ?
			bne	:101			;Nein, weiter...
			ldx	#$48 			;Fehler: "Diskette voll".
			rts

::102			lda	r2L			;Cluster-Nummer merken.
			pha
			sta	r4L
			lda	r2H
			pha
			sta	r4H
			lda	V203d5+0
			ldx	V203d5+1		;Letzten Cluster aus Unterverzeichnis
			jsr	Set_Clu			;mit neuem Cluster verbinden.

			LoadW	r4,$fff8
			pla
			tax
			pla				;Letzten Cluster im Unterverzeichnis
			jsr	Set_Clu			;markieren.

;*** Inhalt des Neuen Clusters löschen.
			lda	r2L
			ldx	r2H
			jsr	GetSDirClu		;Ersten Sektor des Clusters einlesen.

			jsr	i_FillRam		;Sektor-Inhalt löschen.
			w	512
			w	Disk_Sek
			b	$00

			lda	SpClu
::103			pha
			jsr	D_Write			;Sektor in Cluster zurückschreiben.
			txa				;Diskettenfehler ?
			beq	:104			;Nein, weiter...
			pla
			rts				;Abbruch.

::104			jsr	Inc_Sek			;Zeiger auf nächsten Sektor in Cluster.

			pla				;Alle Sektoren im neuen Cluster
			sub	$01			;gelöscht ?
			bne	:103			;Nein, weiter...

			lda	V203d5+0
			ldx	V203d5+1
			jsr	Clu_Sek			;Zeiger auf neuen Cluster richten.

			LoadB	BAM_Modify,$ff		;"BAM verändert".
			jmp	L203a0			;Freie Verzeichnis-Einträge suchen.

;*** Anzahl freie Cluster/freie Bytes auf DOS-Diskette berechnen.
:CalcFreeClu		jsr	ClrBoxText		;Info: "Prüfe freien Speicher..."
			PrintStrgV203i1

			jsr	SetTarget		;Ziel-Laufwerk aktivieren.
			jsr	Max_Free		;Max. Diskettenspeicher berechnen.

			ldy	#14
			lda	#$00
::101			sta	V203b0,y		;Bereich für Informationen über
			dey				;Diskettenspeicher löschen.
			bpl	:101

			LoadW	a1,FAT			;Zeiger auf FAT bereitstellen.

::102			clc
			lda	V203b0+0
			adc	#$02
			tay
			lda	V203b0+1
			adc	#$00
			tax
			tya
			jsr	Get_Clu			;Zeiger auf aktuellen Cluster setzen.
			CmpW0	r1			;Link-Pointer = 0 ?
			bne	:103			;Nein, weiter...

			IncWord	V203b1			;Anzahl freie Cluster um 1 erhöhen.

::103			IncWord	V203b0			;Aktueller Cluster +1.

			CmpW	V203b0,FreeClu		;Alle Cluster überprüft ?
			bne	:102			;Nein, weiter...

			ldx	#$00
			CmpW	V203b1,V203d1		;Genügend Cluster für Dateien ?
			bcs	:104
			ldx	#$ff			;Fehler: "Zuwenig freie Cluster!"
::104			rts

;*** Prüfen ob genügend freie Bytes in Clustern für alle Dateien vorhanden.
:CalcBytesFree		jsr	Init_3			;Zeiger auf Datenspeicher.

::101			ldy	#$04			;Länge der aktuellen Datei
			lda	(a7L),y			;einlesen.
			sta	r0L
			iny
			lda	(a7L),y
			sta	r0H
			ora	r0L			;Dateilänge = 0 ?
			beq	:103			;Ja, weiter....

::102			clc				;Anzahl Blocks * 254 Bytes.
			lda	V203b4 +0
			adc	#<254
			sta	V203b4 +0
			lda	V203b4 +1
			adc	#>254
			sta	V203b4 +1
			lda	V203b4 +2
			adc	#$00
			sta	V203b4 +2

			ldx	#r0L
			jsr	Ddec
			bne	:102

::103			lda	V203b5 +2		;Bytes für CBM-datei in Disketten-
			cmp	V203b4 +2		;speicher (Bytes pro Cluster)
			bne	:104			;umrechnen.
			lda	V203b5 +1
			cmp	V203b4 +1
			bne	:104
			lda	V203b5 +0
			cmp	V203b4 +0
::104			bcs	:106			;Speicher berechnet, weiter...

::105			clc				;Anzahl Bytes pro Cluster addieren.
			lda	V203b5 +0
			adc	CluByte+0
			sta	V203b5 +0
			lda	V203b5 +1
			adc	CluByte+1
			sta	V203b5 +1
			lda	V203b5 +2
			adc	#$00
			sta	V203b5 +2

			IncWord	V203b3			;Anzahl benötigter Cluster +1.
			jmp	:103			;Weiter...

::106			jsr	Init_4			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a6L),y			;Ende der tabelle erreicht ?
			beq	:107			;Ja, weiter...
			jmp	:101			;Nein, Speicher berechnen.

::107			ldx	#$00
			CmpW	V203b1,V203b3
			bcs	:108
			dex
::108			rts

;*** Freie Bytes auf Disk berechnen.
:GetFreeBytes		ldx	V203b1+0
			stx	r0L
			ldy	V203b1+1
			sty	r0H
			bne	:101
			txa
			beq	:102

::101			clc
			lda	V203b2 +0
			adc	CluByte+0
			sta	V203b2 +0
			lda	V203b2 +1
			adc	CluByte+1
			sta	V203b2 +1
			lda	V203b2 +2
			adc	#$00
			sta	V203b2 +2

			ldx	#r0L
			jsr	Ddec
			bne	:101

::102			rts

;*** Fehlermeldungen.
:NoDiskByte		LoadW	V203h0a,V203h1		;Zu wenig freie Cluster.
			LoadW	V203h0b,V203h2
			lda	#$00
			jmp	NoDiskSpace

:NoDirCluster		LoadW	V203h0a,V203h3		;Zu wenig freie Cluster.
			LoadW	V203h0b,V203h4
			lda	#$ff

;*** Fehler-Meldung: "Nicht genügend Speicher auf Ziel!"
;AKKU = $00, Kein Diskettenspeicher.
;     = $FF, Unterverzeichnis voll.
:NoDiskSpace		sta	V203h10			;Fehlercode merken.

			jsr	ClrBox			;Infobox löschen.

			jsr	i_C_DBoxTitel
			b	$06,$05,$1c,$01
			jsr	i_C_DBoxBack
			b	$06,$06,$1c,$0c

			FillPRec$00,$28,$2f,$0030,$010f

			jsr	UseGDFont
			Print	$38,$2e
			b	PLAINTEXT,"Information",NULL

			LoadW	r0,V203h0
			DB_RecBoxL203RVec_a

			ldx	#$00
			CmpBI	sysDBData,1
			beq	:101
			dex
::101			rts

;*** Freien Speicher ausgeben.
:PrintBlocks		bit	V203h10			;Fehlermodus einlesen.
			bpl	:102			; -> Diskettenspeicher zu klein.

;*** Anzahl benötigter Cluster ausgeben.
			PrintStrgV203h6
			lda	V203d1+0
			ldx	V203d1+1
			jsr	:101

			PrintStrgV203h7
			lda	V203b1+0
			ldx	V203b1+1

::101			sta	r0L
			stx	r0H
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV203h8
			jmp	:104

;*** Anzahl benötigter Bytes ausgeben.
::102			PrintStrgV203h5
			lda	V203b5+0
			ldx	V203b5+1
			ldy	V203b5+2
			jsr	:103

			PrintStrgV203h7
			lda	V203b2+0
			ldx	V203b2+1
			ldy	V203b2+2

::103			sta	r0L
			stx	r0H
			sty	r1L
			jsr	ZahlToASCII
			PrintStrgASCII_Zahl
			PrintStrgV203h9

::104			jsr	i_C_DBoxDIcon
			b	$08,$0f,$06,$02
			jsr	i_C_DBoxDIcon
			b	$1a,$0f,$06,$02
			jmp	ISet_Achtung

;*** Farben zurücksetzen.
:L203RVec_a		jsr	i_C_ColorClr
			b	$06,$05,$1c,$0d
			FillPRec$00,$28,$8f,$0030,$010f
			rts

;*** Datum der Dateien auf GEOS-Standard-Zeit setzen.
:SetGEOSDate		lda	SetDateTime
			bne	:101
			rts

::101			jsr	Init_3			;Zeiger auf Datenspeicher.

			ldx	#$04
::102			lda	year,x			;GEOS-Uhrzeit in Zwischenspeicher.
			sta	r2L,x
			dex
			bpl	:102
			jsr	SetDate			;DOS-Datum erzeugen.

::103			ldy	#$03			;DOS-Dateum in Dateitabelle
::104			lda	r0,y			;zurückschreiben.
			sta	(a7L),y
			dey
			bpl	:104

			jsr	Init_4			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a6L),y			;Ende der Tabelle erreicht ?
			bne	:103			;Nein, weiter...
			rts

;*** DOS-Datum generieren.
:SetDate		lda	r3H
			asl
			asl
			asl
			ldx	#$05
::101			asl
			rol	r0L
			rol	r0H
			dex
			bne	:101

			lda	r4L
			asl
			asl
			ldx	#$06
::102			asl
			rol	r0L
			rol	r0H
			dex
			bne	:102

			ldx	#$05
::103			asl	r0L
			rol	r0H
			dex
			bne	:103

			lda	r2L
			bne	:104
			lda	#100
::104			sec
			sbc	#80
			asl
			ldx	#$07
::105			asl
			rol	r1L
			rol	r1H
			dex
			bne	:105

			lda	r2H
			asl
			asl
			asl
			asl
			ldx	#$04
::106			asl
			rol	r1L
			rol	r1H
			dex
			bne	:106

			lda	r3L
			asl
			asl
			asl
			ldx	#$05
::107			asl
			rol	r1L
			rol	r1H
			dex
			bne	:107

			rts

;*** Dateien einlesen
:CBM_GetFiles		sta	V203e1 +5		;Zeiger auf Titel für Auswahlbox.
			stx	V203e1 +6

:GetFiles_a		lda	Source_Drv 		;Ziel-Laufwerk.
			ldx	#$00			;Diskette einlegen.
			jsr	InsertDisk
			cmp	#$01
			beq	L203b0
			ldx	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

;*** Zeiger auf ersten Datei-Eintrag.
:L203b0			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			rts				;Diskettenfehler anzeigen.

::101			lda	curDirHead+0		;Ersten Verzeichnis-Sektor speichern.
			sta	V203c1    +0
			lda	curDirHead+1
			sta	V203c1    +1
			lda	#$00
			sta	V203c2			;Zeiger auf Eintrag.
			sta	V203c4			;"Verzeichnisende"-Flag löschen.

;*** Dateien einlesen..
:L203b1			jsr	L203c0			;Dateien einlesen.
			txa
			beq	L203b2
			rts

;*** Datei-Auswahl-Box.
:L203b2			MoveB	r1L,V203c1+0		;Verzeichnis-Position merken.
			MoveB	r1H,V203c1+1
			lda	V203c4			;"Dateien auf Diskette"-Flag setzen.
			ora	#%01000000
			sta	V203c4

			MoveB	V203c6,V203e1+4		;Anzahl Action-Files in Tabelle.

			lda	#<V203e1
			ldx	#>V203e1
			jsr	SelectBox

			lda	r13L
			cmp	#$01
			beq	:102			;$01 = "OK" ohne Dateiauswahl.
			cmp	#$90
			beq	:105			;$90 = Partition wählen.
			cmp	#$ff
			beq	:104			;$FF = Dateien gewählt.
::101			ldx	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

::102			bit	V203c4			;Verzeichnisende erreicht ?
			bpl	:103			;Nein, weiter...
			jmp	L203b0			;Zum Anfang zurück.
::103			jmp	L203b1			;Directory weiterlesen.

::104			ldx	#$00			;Dateien gewählt.
			rts				;Ende.

::105			lda	Source_Drv
			jsr	NewDrive
			txa
			bne	:106
			jsr	CMD_NewTarget		;Partition wählen.
::106			jmp	GetFiles_a		;Dateien einlesen.

;*** max. 255 Dateien einlesen.
:L203c0			jsr	DoInfoBox		;Infobox anzeigen.
			PrintStrgDB_RdFile

			LoadW	r15,FileNTab		;Zeiger auf Dateitabelle.
			lda	#$00
			sta	V203c5			;Anzahl Dateien löschen.
			sta	V203c6			;Anzahl Action-Files löschen.

::101			MoveB	V203c1+0,r1L		;Zeiger auf nächsten Verzeichnis-
			MoveB	V203c1+1,r1H		;Sektor in Zwischenspeicher.

;*** Max. 255 Dateien einlesen.
:L203c1			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor lesen.
			jsr	GetBlock
			txa
			beq	:104			;Auf Verzeichnisende prüfen.
::101			rts

::102			lda	V203c2			;Zeiger auf Eintrag berechnen.
			asl
			asl
			asl
			asl
			asl
			sta	V203c3
			inc	V203c2

::103			jsr	ChkDirEntry		;Eintrag auf Gültigkeit testen.
			txa				;Eintrag OK ?
			bmi	:104			;Nein, weiter...
			bne	:101			;Diskettenfehler.

			jsr	CopyFileInTab		;Eintrag in Tabelle kopieren.
			txa				;Speicher voll ?
			bne	:106			;Ja, Ende.

;*** Noch ein Eintrag im Sektor ?
::104			lda	V203c2			;Folgt weiterer Eintrag im Sektor ?
			cmp	#$08
			bne	:102			;Nächster Eintrag.

			ClrB	V203c2			;Zeiger auf Eintrag löschen.

			lda	diskBlkBuf+0		;Folgt weiterer Verzeichnis-Sektor ?
			beq	:105			;Nein, Ende.
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	L203c1			;Nächsten Verzeichnis-Sektor lesen.

::105			lda	V203c4
			ora	#%10000000
			sta	V203c4

;*** Tabellen-Ende markieren.
::106			ldy	#$00
			tya
			sta	(r15L),y		;Tabellen-Ende markieren.
			jsr	ClrBox
			ldx	#$00
			rts

;*** Infoblock einlesen.
:L203c2			PushW	r1			;Zeiger auf Verzeichnis-Sektor sichern.

			lda	diskBlkBuf+21,x
			sta	r1L
			lda	diskBlkBuf+22,x
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;Fileheader einlesen.

			PopW	r1

			rts

;*** ":Class" vergleichen.
:L203c3			ldy	#$00			;Auf GeoWrite-Dokument testen.
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
;V203c3 = Zeiger auf Eintrag in Dir-Sektor (0-7).
;
;Rückgabewert:
;xReg = $00, Datei übernehmen.
;
:ChkDirEntry		ldx	V203c3			;Zeiger auf Verzeichniseintrag.
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
::103			ldy	CBMCopyMode		;Kopiermodus einlesen.
			bmi	:104			; -> GeoWrite-Dokumente suchen.

;*** Sequentielle Dateien.
			lda	diskBlkBuf+23,x		;VLIR-Datei ?
			bne	:101			;Ja, Datei übergehen.
			tya				;Dateien 1:1 kopieren ?
			bne	:105			;Ja, datei übernehmen.
			lda	diskBlkBuf+24,x		;GEOS-Datei ?
			bne	:101			;Ja, Datei übergehen.
			beq	:105			;Datei OK!

;*** GeoWrite-Dateien.
::104			lda	diskBlkBuf+23,x		;Dateistruktur = $00 ?
			beq	:101			;Ja  , keine VLIR-Datei, übergehen.
			lda	diskBlkBuf+24,x
			cmp	#APPL_DATA		;Dateityp = Dokument ?
			bne	:101			;Nein, keine Dokument  , übergehen.
			lda	diskBlkBuf+21,x		;Infoblock vorhanden ?
			beq	:101			;Nein, keine VLIR-Datei, übergehen.

			jsr	L203c2			;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			LoadW	r0,V203c0
			jsr	L203c3			;GEOS-Klasse vergleichen.
			txa
			bne	:101			;Kein GeoWrite-Dokument.

::105			ldx	#$00			;Datei übernehmen.
			rts

;*** Dateieintrag in Tabelle kopieren.
;Übergabewert:
;
;Rückgabewert:
;xReg = $00, OK.
;     = $FF, Speicher voll.
:CopyFileInTab		ldx	V203c3			;Zeiger auf Verzeichniseintrag.
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
			inc	V203c5			;für Datei-Einträge.

			ldx	#$00
			lda	V203c5
			cmp	#$ff			;Speicher voll ?
			bne	:103			;Ja, Ende...
			dex
::103			rts

;*** Ziel-Verzeichnis wählen.
:DOS_GetTDir		ldx	#$00			;Diskette einlegen.
			b $2c
:DOS_GetTDir_a		ldx	#$ff
			lda	Target_Drv
			jsr	InsertDisk
			cmp	#$01
			beq	L203d0
			ldx	#$ff
			rts

;*** Systemdaten einlesen.
:L203d0			jsr	DOS_GetSys		;DOS-Verzeichnis einlesen.
			jsr	DOS_GetDskNam		;Diskettennamen einlesen.
			jsr	ClrBox			;Infofenster löschen.

;*** Dateien in Speicher einlesen.
:L203d1			lda	#$00
			sta	V203d0			;Zeiger auf Hauptverzeichnis.

			jsr	i_FillRam		;Datenspeicher löschen.
			w	16*256
			w	FileNTab
			b	$00
			jsr	i_FillRam
			w	8 *256
			w	FileDTab2
			b	$00

;*** Dateien einlesen und auswerten.
:L203d2			jsr	ReadSubDir		;Unterverzeichnisse einlesen.
			txa
			beq	:101
			rts

::101			lda	V203e2+4		;Anzahl Verzeichnisse = 0 ?
			beq	L203d4			;Ja, Ende.

;*** Datei-Auswahl-Box.
:L203d3			MoveB	Seite,V203d4+0		;Aktuelle Sektorwerte merken.
			MoveB	Spur,V203d4+1
			MoveB	Sektor,V203d4+2
			MoveW	a8,V203d9

			lda	#<V203e2
			ldx	#>V203e2
			jsr	SelectBox

			lda	r13L
			beq	L203d5			; -> Verzeichnis öffnen.
			cmp	#$01
			beq	L203d4			; -> OK, Verzeichnis gewählt.
			cmp	#$80
			beq	DOS_GetTDir_a		; -> Diskette wechseln.
			ldx	#$ff
			rts

:L203d4			MoveB	V203d0,r0L		;Verzeichnistyp übergeben.
			MoveW	V203d3,r1		;SubDir-Cluster übergeben.
			ldx	#$00			;Verzeichnis gewählt.
			rts

;*** SubDir auswählen.
:L203d5			MoveB	r13H,a7L
			ClrB	a7H
			ldx	#a7L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	FileDTab2,a7

			ldy	#$01			;Cluster-Nr. einlesen.
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			ldy	#$00
			cmp	#$00			;Cluster = 0 ? -> Nein, SubDir.
			bne	:101
			cpx	#$00			;Cluster = 0 ? -> Nein, SubDir.
			beq	:102
::101			dey
::102			sta	V203d3+0		;Cluster-Nr. als Startadresse für.
			stx	V203d3+1		;Unterverzeichnis setzen.
			sty	V203d0			;Verzeichnistyp festlegen.
			jmp	L203d2			;Verzeichnisse einlesen.

;*** SubDirectorys einlesen.
:ReadSubDir		jsr	DoInfoBox		;Info-Box.
			PrintStrgDB_RdSDir

			ClrB	V203e2+4		;Zähler für Anzahl Directorys auf 0.

			jsr	Init_3			;Zeiger auf Datenspeicher.

;*** Dateien & Directorys einlesen.
:L203e0			jsr	ResetDir
			txa
			beq	:104			;Alle Einträge aus Sektor gelesen ?
			rts

::101			jsr	TestFileName
			cmp	#$00			;$00 = Verzeichnis-Ende ?
			beq	:105			;Ja, Ende...
			cmp	#$ff			;$FF = Ungültiger Eintrag ?
			beq	:103			;Ja, überspringen...

::102			jsr	CopyCurEntry
			jsr	PoiToNxSek		;Zeiger auf nächsten Eintrag.
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			beq	:104			;Ja, weiter...
			jmp	:105 			;Ende.

::103			jsr	PoiToNxSek		;Zeiger auf nächsten Eintrag.

::104			CmpBI	V203d8,16		;Alle Einträge aus Sektor gelesen ?
			bne	:101			;Nein, weiter...

			ClrB	V203d8			;Zähler für Sektor-Einträge löschen.
			jsr	GetNxDirSek		;Nächsten Directory-Sektor lesen.
			txa				;Sektor gefunden ?
			beq	:101			;Ja, weiter...
			bpl	:106			; -> Diskettenfehler.

::105			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a6L),y

			jsr	ClrBox
			ldx	#$00
::106			rts

;*** Zeiger auf nächsten Sektor-Eintrag.
:PoiToNxSek		pha
			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V203d8			;Eintrag.
			pla
			rts

;*** Datei-Namen testen.
:TestFileName		ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			bne	:101
			rts				;Ja, Ende.

::101			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:104			;Ja, Datei ignorieren.

			ldy	#$0b
			lda	(a8L),y			;Ist Eintrag = Verzeichnis ?
			and	#%00010000		;Hat Datei gewünschtes
::102			beq	:104			;Nein, Datei ignorieren.

::103			lda	#$7f			;Gültiger Eintrag.
			rts
::104			lda	#$ff			;Ungültiger Eintrag.
			rts

;*** Dateiname in Tabelle übertragen.
:CopyCurEntry		lda	#$00			;Zeiger initialisieren.
			sta	:101 +1
			sta	:105 +1

::101			ldy	#$00			;Datei-Name in Speicher kopieren und
			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:103			;Code < $20 ? Nein, weiter.
::102			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:104
::103			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:102
::104			inc	:101 +1			;Zeiger auf nächstes Zeichen.
::105			ldy	#$00
			sta	(a6L),y			;Zeichen in Speicher kopieren.
			inc	:105 +1			;Zeiger auf nächstes Zeichen.
::106			lda	#" "			;Trennung zwischen "NAME" + "EXT"
			cpy	#$07			;einfügen.
			beq	:105
			cpy	#$0b
			bne	:101

			lda	#$00
::107			iny				;Dateinamen auf 16 Zeichen
			sta	(a6L),y			;mit $00-Bytes auffüllen.
			cpy	#$10
			bne	:107

			ldy	#$1a			;Ersten Cluster der Datei
			lda	(a8L),y			;einlesen und speichern.
			pha
			iny
			lda	(a8L),y
			ldy	#$01
			sta	(a7L),y
			dey
			pla
			sta	(a7L),y

			jsr	Init_4			;Zeiger auf nächsten Eintrag.

			inc	V203e2+4		;Zähler SubDir erhöhen.
			CmpBI	V203e2+4,255		;Tabelle voll ?
			beq	:108			;Ja, Ende...
			lda	#$00			;Nein, weiter...
			rts
::108			lda	#$ff
			rts

;*** Datei-Eintrag suchen.
;    r10 zeigt auf Suchdateiname.
:LookDOSfile		jsr	ResetDir
			txa
			beq	L203f0
			rts

:L203f0			CmpBI	V203d8,16		;Alle Einträge des Sektors durchsucht ?
			bne	:103			;Nein, weiter...

			ClrB	V203d8			;Nächsten Sektor lesen.
			jsr	GetNxDirSek
			txa				;Sektor gefunden ?
			beq	:103			;Ja, weiter...
			bpl	:102			; -> Diskettenfehler.

::101			ldx	#$05			;Datei nicht gefunden.
::102			rts

;*** Dateiparameter prüfen.
::103			ldy	#$00
			lda	(a8L),y
			beq	:101			; -> Verzeichnis-Ende erreicht.

;*** Name in Puffer kopieren und in GEOS-Formt wandeln.
::104			ldy	#$00
			ldx	#$00			;Dateiname in Speicher kopieren und
::105			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:107			;Code < $20 ? Nein, weiter.
::106			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:108
::107			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:106
::108			iny
::109			sta	V203a5,x		;Zeichen in Speicher kopieren.
			inx
			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpx	#$08			;einfügen.
			beq	:109
			cpx	#$0c
			bne	:105

			ldy	#$0b			;Aktuellen Eintrag mit Suchdatei
::110			lda	V203a5,y		;vergleichen.
			cmp	(r10L),y
			bne	:111
			dey
			bpl	:110

			ldx	#$00			;Datei gefunden.
			rts

;*** Zeiger auf nächste Datei
::111			jsr	PoiToNxSek		;Nächsten Eintrag vergleichen.
			jmp	L203f0

;*** Directory initialisieren.
:ResetDir		bit	V203d0			;Zeiger auf Anfang Hauptverzeichnis ?
			bmi	:101			;Nein, Zeiger auf Unterverzeichnis...

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor +0
			sta	V203d1    +0
			lda	MdrSektor +1
			sta	V203d1    +1
			jmp	:102

::101			lda	V203d3+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V203d3+1
			sta	V203d5+0
			stx	V203d5+1
			jsr	Clu_Sek

::102			lda	Seite			;Startposition merken.
			sta	V203d2+0
			sta	V203d4+0
			lda	Spur
			sta	V203d2+1
			sta	V203d4+1
			lda	Sektor
			sta	V203d2+2
			sta	V203d4+2

			MoveB	V203d1,V203d6
			MoveB	SpClu ,V203d7

			lda	#$00
			sta	V203d8			;Zähler Dateien auf 0.
			lda	#<Disk_Sek
			sta	a8L
			sta	V203d9+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V203d9+1
			jmp	D_Read			;Sektor lesen.

;*** Nächsten Sektor lesen.
:GetNxDirSek		bit	V203d0			;Hauptverzeichnis ?
			bmi	:102			;Nein, weiter...

			CmpBI	V203d6,1		;Alle Sektoren
			beq	:101			;gelesen ?

			dec	V203d6			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jmp	D_Read			;Sektor lesen.

::101			ldx	#$ff			;Directory-Ende...
			rts

;*** Nächster Sektor aus Unterverzeichnis.
::102			CmpBI	V203d7,1		;Alle Sektoren
			beq	:103			;gelesen ?

			dec	V203d7			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jmp	D_Read

::103			lda	V203d5+0		;Nächsten Cluster lesen.
			ldx	V203d5+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H
			sta	V203d5+0
			stx	V203d5+1

;*** Nächster Cluster verfügbar ?
:GetSDirClu		cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:101			;Nein, weiter...
			cpx	#$0f
			bcc	:101
			ldx	#$ff			;Verzeichnis-Ende erreicht.
			rts

::101			ldy	SpClu			;Zähler "Sektoren/Cluster" setzen.
			sty	V203d7

;*** Nächsten Cluster einlesen.
;    Akku und xReg enthalten Zeiger auf Cluster!
			jsr	Clu_Sek			;Cluster berechnen.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jmp	D_Read			;Ersten Sektor lesen.

;*** Variablen: Lesen des DOS-Directory.
:CBMCopyMode		b $00				;Kopiermodus.
:CCM2			b $00				;Kopiermodus.
:InputMode		b $00				;$00 = Keine Textvorgabe
							;$FF = Textvorgabe bei Datei umbenennen.

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
:V203a0			b $00				;Anzahl freie Einträge im Directory.
:V203a1			w $0000				;Anzahl CBM-Files als Word!
:V203a2			w $0000				;Zeiger auf Quell-Dateiname.
:V203a3			s 17				;Aktueller Dateiname für Test.
:V203a4			s 17				;Eingabespeicher für neuen Dateinamen.
:V203a5			s 17				;Zwischenspeicher Dateiname.

:V203b0			w $0000				;Zähler für Cluster.
:V203b1			w $0000				;Zähler für freie Cluster.
:V203b2			s $03				;Freie Bytes auf Diskette.
:V203b3			w $0000				;Anzahl benötigte Cluster/Bytes.
:V203b4			s $03				;Benötigte Bytes für CBM-Dateien.
:V203b5			s $03				;Benötigter Speicher (in Bytes/Cluster) CBM-Dateien.

;*** Variablen.
:V203c0			b "Write Image ",NULL
:V203c1			b $00,$00			;Aktueller Directory-Sektor.
:V203c2			b $00				;Zeiger auf Eintrag.
:V203c3			b $00				;Zeiger auf Byte in Sektor.
:V203c4			b $00				;$FF = Directory-Ende.

:V203c5			b $00				;Anzahl Dateien.
:V203c6			b $00				;Anzahl ACTION-Files

;*** Variablen: Lesen des Directory.
:V203d0			b $00				;Directory-Typ.
:V203d1			w $0000				;Anzahl Sektoren im Hauptverzeichnis
:V203d2			s $03				;Startadresse Directory (Sektor)
:V203d3			w $0000				;       "               (Cluster)

:V203d4			s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V203d5			w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V203d6			b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V203d7			b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V203d8			b $00				;Zähler Einträge in Sektor.
:V203d9			w $0000				;Zeiger auf Anfang Eintrag in Sektor.

;*** Dialogboxen.
:V203e0			b $00				;Dateinamen ändern.
			b $00
			b $00
			b $0c
			b $00
			w V203f2
			w FileNTab

:V203e1			b $ff				;Dateien wählen.
			b $ff
			b $ff
			b $10
			b $00
			w $ffff
			w FileNTab

:V203e2			b $80				;Ziel-Verzeichnis wählen.
			b $00
			b $00
			b $0c
			b $00
			w V203f0
			w FileNTab

if Sprache = Deutsch
;*** Titel für Auswahlboxen.
:V203f0			b PLAINTEXT,"Ziel-Verzeichnis",NULL
:V203f1			b PLAINTEXT,"GeoWrite-Texte wählen",NULL
:V203f2			b PLAINTEXT,"Dateiname ändern",NULL

;*** Fehler: "Dateiname bereits vergeben!"
:V203g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Der gewählte Dateiname",NULL
::102			b        "ist bereits vergeben!",NULL
endif

if Sprache = Englisch
;*** Titel für Auswahlboxen.
:V203f0			b PLAINTEXT,"Target-directory",NULL
:V203f1			b PLAINTEXT,"Select write-document",NULL
:V203f2			b PLAINTEXT,"Edit filename",NULL

;*** Fehler: "Dateiname bereits vergeben!"
:V203g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Selected filename",NULL
::102			b        "already exist!",NULL
endif

if Sprache = Deutsch
;*** Fehler: "Nicht genügend freie Cluster auf Ziel-Disk!"
:V203h0			b %00100000
			b 48,143
			w 48,271
			b OK        ,  2, 72
			b CANCEL    , 20, 72
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
:V203h0a		w V203h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
:V203h0b		w V203h2
			b DB_USR_ROUT
			w PrintBlocks
			b NULL

:V203h1			b PLAINTEXT,BOLDON
			b "Nicht genügend freier",NULL
:V203h2			b "Speicher auf Zieldiskette!",NULL
:V203h3			b PLAINTEXT,BOLDON
			b "Nicht genügend freie Cluster",NULL
:V203h4			b "auf Diskette verfügbar!",NULL

:V203h5			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Benötigt ca."
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V203h6			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Benötigt"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V203h7			b GOTOXY
			w DBoxLeft +$0030
			b 109
			b "Verfügbar"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V203h8			b " Cluster",NULL
:V203h9			b " Byte(s)",NULL
:V203h10		b $00
endif

if Sprache = Englisch
;*** Fehler: "Nicht genügend freie Cluster auf Ziel-Disk!"
:V203h0			b %00100000
			b 48,143
			w 48,271
			b OK        ,  2, 72
			b CANCEL    , 20, 72
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
:V203h0a		w V203h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
:V203h0b		w V203h2
			b DB_USR_ROUT
			w PrintBlocks
			b NULL

:V203h1			b PLAINTEXT,BOLDON
			b "Not enough diskspace",NULL
:V203h2			b "available on targetdisk!",NULL
:V203h3			b PLAINTEXT,BOLDON
			b "Not enough clusters",NULL
:V203h4			b "available on targetdisk!",NULL

:V203h5			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Needed"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V203h6			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Needed"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V203h7			b GOTOXY
			w DBoxLeft +$0030
			b 109
			b "Available"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V203h8			b " Cluster",NULL
:V203h9			b " Byte(s)",NULL
:V203h10		b $00
endif

if Sprache = Deutsch
;*** Info: "Datei-Informationen..."
:V203i0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei-Informationen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Prüfe freien Speicher auf dem Ziel-Laufwerk..."
:V203i1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Prüfe freien Speicher"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf Ziel-Laufwerk..."
			b NULL

;*** Info: "Überprüfe das Ziel-Verzeichnis..."
:V203i2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Überprüfe das"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Zielverzeichnis..."
			b NULL

;*** Hinweis "Datei wird gelöscht!"
:V203i3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Info: "Verzeichnis wird aktualisiert..."
:V203i4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenverzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL
endif

if Sprache = Englisch
;*** Info: "Datei-Informationen..."
:V203i0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Loading file-"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "information..."
			b NULL

;*** Info: "Prüfe freien Speicher auf dem Ziel-Laufwerk..."
:V203i1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Check free diskspace"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on targetdisk..."
			b NULL

;*** Info: "Überprüfe das Ziel-Verzeichnis..."
:V203i2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Check directory"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on targetdisk..."
			b NULL

;*** Hinweis "Datei wird gelöscht!"
:V203i3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Delete file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Info: "Verzeichnis wird aktualisiert..."
:V203i4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Update directory."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Please wait..."
			b NULL
endif
