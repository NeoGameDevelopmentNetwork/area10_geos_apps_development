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

			n	"mod.#202.obj"
			o	ModStart
			r	FileDTab -1

			jmp	DOStoCBM

;*** Quell- und Ziel-Laufwerk setzen.
			t   "-SetSourceDOS"
			t   "-SetTargetCBM"

			t   "-FileExist"
			t   "-GetConvTab2"
			t   "-CBM_SetName"

;*** L202: Datei von MS-DOS nach CBM kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

;*** Datei von MS-DOS nach CBM kopieren
;xReg = %00000000	-> Text nach Text.
;       %10000000	-> Text nach GeoWrite.
;       %01000000	-> DOS  nach CBM 1:1.

:DOStoCBM		jsr	Init_1			;Register initialisieren.

:DOStoCBM_1		jsr	GetFileToCopy		;Dateien auswählen.
			txa
			bmi	L202ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	GetTarget		;Ziel-Partition wählen
			txa
			bmi	L202ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

:DOStoCBM_2		jsr	InitFileData		;Datei-Informationen sortieren.
			txa
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	TestFiles		;Dateien auf Ziel-Laufwerk testen.
			txa
			bmi	L202ExitGD		;Zurück zum Hauptmenü.
			bne	ExitDskErr		;Diskettenfehler anzeigen.

			jsr	CalcBytesFree		;Speicher auf Ziel-Laufwerk testen.
			txa
			beq	InitForCopy

			jsr	NoDiskSpace		;Fehler: "Zu wenig freier Speicher..."
			txa
			beq	DOStoCBM_1

;*** Ende. Zurück zu GeoDOS.
:L202ExitGD		jmp	InitScreen		;Zurück zum Hauptmenü.
:ExitDskErr		jmp	DiskError		;Diskettenfehler anzeigen.

;*** Dateien kopieren.
:InitForCopy		jsr	InitForIO
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00

;*** Konvertierungstabelle laden.
:GetConvTab		lda	CTabDOStoCBM
			ldx	#<SCREEN_BASE
			ldy	#>SCREEN_BASE
			jsr	LoadConvTab

;*** Dateidaten in Zwischenspeicher kopieren.
			jsr	i_MoveData
			w	FileNTab
			w	SCREEN_BASE+   256
			w	16*256
			jsr	i_MoveData
			w	FileDTab
			w	SCREEN_BASE+17*256
			w	9 *256

			lda	DOSCopyMode		;Kopiermodus einlesen.
			and	#%11000000
			beq	:101			;-> DOS-Text  nach CBM-Text.
			cmp	#%10000000
			beq	:102			;-> DOS-Text  nach GW -Text.
			cmp	#%01000000
			beq	:103			;-> DOS-Datei nach CBM-Datei.
			jmp	L202ExitGD		;Zurück zu GeoDOS,

::101			jmp	vC_DOStoCBM
::102			jmp	vC_DOStoGW
::103			jmp	vC_DOStoCBM_F

;*** Routinen initialisieren.
:Init_1			stx	DOSCopyMode		;Kopiermodus merken.
			txa
			ldy	#$00
			and	#%00000001
			beq	:101
			ldy	#$80
::101			sty	DCM2

			ldy	#$02
			lda	#$00			;Partitionsdaten löschen.
::102			sta	TDrvPart,y
			sta	TDrvNDir,y
			dey
			bpl	:102

			rts

;*** Zeiger auf Datenspeicher.
:Init_3			LoadW	a6,FileNTab		;Tabelle Datei-Namen.
			LoadW	a7,FileDTab		;Tabelle Datei-Datum.
			rts

;*** Zeiger auf nächste Datei.
:Init_4			AddVBW	16,a6
			AddVBW	 9,a7			;Zeiger auf nächste CBM-Datei.
			rts

;*** Zeiger auf Datenspeicher.
:Init_5			LoadW	a6,FileNTab		;Tabelle Datei-Namen.
			rts

;*** Zeiger auf nächste Datei.
:Init_6			AddVBW	16,a6			;Zeiger auf nächste CBM-Datei.
			rts

;*** Dateien auswählen.
:GetFileToCopy		lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive
			txa
			bne	:101			;Fehler, Abbruch.

			jsr	DOS_GetFiles		;Dateien auswählen.
			txa
			bne	:101			;Abbruch.

;*** Dateien ausgewählt, Ende.
			lda	r13H			;Anzahl Dateien merken.
			sta	AnzahlFiles
			ldx	#$00			;Kein Fehler.
::101			rts

;*** Ziel-Partition öffnen.
:GetTarget		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive
			txa
			bne	:103			;Fehler, Abbruch.

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

::100a			jsr	SaveCopyFiles		;Dateinamentabelle sichern.
			txa
			bne	:101

			lda	curDrvMode		;CMD-Laufwerk ?
			bpl	:101a			;Nein, übergehen.

			lda	Target_Drv
			ora	DCM2
			ldx	#<V202e0
			ldy	#>V202e0
			jsr	CMD_SlctPart		;Partition wählen, falls CMD-Laufwerk.
			jmp	:101b

;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für SD2IEC/RAMNative ergänzt.
::101a			lda	Target_Drv
			ora	DCM2
			ldx	#<V202e2		;Zeiger auf Titel setzen.
			ldy	#>V202e2
			jsr	CMD_SlctNDir		;Verzeichnis wählen, falls NativeMode.
::101b			stx	:102 +1

			jsr	LoadCopyFiles		;Dateinamentabelle laden.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...
::101			jmp	GDDiskError		;Fehler im Anwendunsprogramm.

::102			ldx	#$ff
::103			rts

;*** Dateinamentabelle sichern.
:SaveCopyFiles		jsr	OpenSysDrive		;Systemdiskette öffnen.

			jsr	DelFileList		;Vorhandene Dateiliste löschen.
			txa
			bne	:101

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

;*** Daten für ausgewählte Dateien sortieren.
:InitFileData		jsr	Init_3			;Zeiger initialisieren.

::102			ldy	#$0f
			lda	(a6L),y
			jsr	SetPosEntry

			ldy	#$08
::103			lda	(r0L),y
			sta	(a7L),y
			dey
			bpl	:103

			jsr	Init_4			;Zeiger auf nächsten Eintrag.

			ldy	#$00
			lda	(a6L),y
			bne	:102

;*** Dateinamen packen.
:PackFileName		bit	FileNameFormat		;DOS 8+3 Dateinamen packen ?
			bpl	:102			;Nein, weiter...

			jsr	Init_5			;Zeiger initialisieren.

::101			ldy	#$00
			lda	(a6L),y			;Tabellenende erreicht ?
			bne	:103			;Nein, weiter...
::102			ldx	#$00			;Ende, OK.
			rts

::103			lda	(a6L),y			;Dateiname in Zwischenspeicher
			sta	V202a0,y		;kopieren.
			iny
			cpy	#$10
			bne	:103

			ldx	#$00
			ldy	#$00
::104			lda	V202a0,x		;Leerzeichen aus Dateiname filtern.
			cmp	#" "
			beq	:105
			sta	(a6L),y
			iny
::105			inx
			cpx	#$10
			bcc	:104

			tya				;Kein gültiges Zeichen im
			beq	:107			;Dateinamen ? Ja, nächste Datei.

			lda	#$00			;Gepackter Dateiname in Tabelle
::106			cpy	#$10			;zurückschreiben.
			beq	:107
			sta	(a6L),y
			iny
			bne	:106

::107			jsr	Init_6			;Zeiger auf nächsten Eintrag.
			jmp	:101

;*** Datei-Namen testen.
:TestFiles		jsr	SetTarget		;Ziel-Laufwerk aktivieren.

			jsr	Init_3			;Zeiger initialisieren.

			bit	DOSCopyMode		;Kopiermodus einlesen.
			bpl	TestAllFiles		;DOS -> GW ? Nein, weiter...
			lda	LinkFiles		;Dateien verbinden ?
			beq	TestAllFiles		;Nein, weiter...

;*** Linkdatei erzeugen.
:TestLinkFile		lda	#<V202a2		;"LinkFile" als Vorgabename setzen.
			ldx	#>V202a2
			jsr	CopyCurName

::101			jsr	GetNewName		;Name der Link-Datei eingeben.
			cmp	#$01			;"OK" ?
			bne	:106			;Nein, Abbruch.

::102			jsr	DoInfoBox		;Info: "Überprüfe Ziel-Verzeichnis..."
::103			PrintStrgV202f0

			lda	#<V202a1		;Neuer Name für Link-Datei in
			ldx	#>V202a1		;Zwischenspeicher kopieren.
			jsr	CopyCurName

			jsr	Test1File		;Datei auf Ziel-Laufwerk suchen.
			txa				;Datei vorhanden ?
			beq	:104			;Ja, weiter...
			jsr	ReWriteName		;Neuen Namen übernehmen.
			ldx	#$00			;"OK".
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
:TestAllFiles		jsr	DoInfoBox		;Info: "Überprüfe Ziel-Verzeichnis..."
			PrintStrgV202f0

:TestNewFile		lda	a6L
			ldx	a6H
			jsr	CopyCurName		;Aktuelle Datei in Zwischenspeicher.

:TestCurFile		jsr	Test1File		;Datei auf Ziel-Laufwerk suchen.
			txa
			bne	:101			; -> Nicht gefunden, OK!
			jmp	FileIsOnDsk		;Datei vorhanden -> User-Abfrage.

::101			jsr	ReWriteName		;Name übernehmen.

;*** Nächste Datei testen.
:TestNextFile		jsr	Init_4			;Zeiger auf nächsten Eintrag.

;*** Auf Ende der Tabelle testen.
:TestEndTab		ldy	#$00			;Tabellen-Ende erreicht ?
			lda	(a6L),y
			bne	TestNewFile
			ldx	#$00			;OK.
			rts

;*** Einzelne Datei testen.
; Erg.:			$FF = Datei nicht vorhanden.
;			$00 = Datei bereits vorhanden.
:Test1File		LoadW	r6,V202a0
			jsr	FindFile
			txa
			beq	:101
			ldx	#$ff
::101			rts

;*** Sicherheitsabfrage.
:FileIsOnDsk		lda	OverWrite		;Sicherheitsabfrage: Datei vorhanden.
			bmi	DoUsrInfo		; -> User-Abfrage.
			bne	IgnFile			; -> Datei ignorieren.

:DelFile		jsr	DelCBMFile		; -> Datei löschen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.
			jmp	TestNextFile		;Nächste Datei testen.
::101			rts				;Abbruch.

:IgnFile		jsr	IgnDOSFile		; -> Datei ignorieren.
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

			jsr	SetNewName		;Neuen Name für Datei eingeben.
			txa
			bmi	:103
			bne	DoUsrInfo		;Abbruch, Modus erneut abfragen.
			lda	#<V202a1
			ldx	#>V202a1
			jsr	CopyCurName		;Neuen Namen in Zwischenspeicher.

			jsr	DoInfoBox		;Infobox anzeigen.
			PrintStrgV202f0
			jmp	TestCurFile		;Datei auf Existenz testen.

::103			ldx	#$ff			;Abbruch.
			rts

;*** User-Abfrage: "Datei löschen ?"
:AskUser		jsr	ClrBox			;Infobox löschen.

::101			LoadW	r15,V202a0
			jsr	FileExist		;Abfrage: Datei löschen ?
			cmp	#$00			;"Close"...
			beq	:106			;Ja, Abbruch.

			bit	LinkFiles		;Dateien verbinden ?
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

::103			PrintStrgV202f0
			jsr	IgnDOSFile		;Datei übergehen.
			txa				;Weitere Dateien ?
			bne	:105			;Nein, Abbruch.

::104			jsr	ClrBoxText		;Info: "Prüfe Ziel-Verzeichnis..."
			PrintStrgV202f0
			pla
			bne	:106

::105			jsr	ClrBox			;Abbruch, oder Close-Icon.
			pla
			lda	#$00
::106			rts				;Rückkehr.

;*** CBM-Datei löschen.
:DelCBMFile		jsr	ClrBoxText
			PrintStrgV202f2			;Info: "Datei wird gelöscht..."
			PrintStrgV202a0

			LoadW	r0,V202a0		;CBM-Datei löschen.
			jsr	DeleteFile
			txa
			bne	:101

			jsr	ReWriteName
			ldx	#$00
::101			rts

;*** DOS-Datei ignorieren.
:IgnDOSFile		PushW	a6			;Zeiger auf Dateitabelle sichern.
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
:SetNewName		jsr	GetNewName		;Neuen Dateinamen eingeben.
			cmp	#$01			;"OK"...
			beq	:103
			cmp	#$02			;"Exit"...
			beq	:102
::101			ldx	#$7f
			b $2c
::102			ldx	#$ff			;Ungültiger Dateiname.
			rts

::103			lda	r2L			;Länge Dateiname = 0 ?
			beq	:102			;Ja, ungültiger Dateiname.

			MoveW	a6,r1
			jsr	IsNameInTab		;Name in Dateinamentabelle ?
			beq	SetNewName		;Ja, Neuer Name.
			cmp	#$ff			;Abbruch.
			bne	:102

			ldy	#$0f			;Dateiname übernehmen.
::104			lda	V202a1,y
			sta	V202a0,y
			dey
			bpl	:104

			ldx	#$00			;OK.
			rts

;*** Datei umbennen.
:GetNewName		LoadW	r0,V202a0
			LoadW	r1,V202a1		;Zwischenspeicher.
			LoadB	r2L,$ff			;Vorgabe.
			LoadB	r2H,$ff			;Vorgabe anzeigen.
			LoadW	r3,V202e1		;Titel.
			jmp	cbmSetName		;Name eingeben.

;*** Dateiname zwischenspeichern.
:CopyCurName		sta	r0L
			stx	r0H
			lda	#<V202a0
			ldx	#>V202a0

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
:ReWriteName		LoadW	r0,V202a0
			lda	a6L
			ldx	a6H
			jmp	CNameString

;*** Einzel-Datei umbenennen.
:IsNameInTab		LoadW	r0,FileNTab		;Prüfen ob Name bereits vergeben.

::101			ldy	#$00
			lda	(r0L),y			;Ende der Tabelle erreicht ?
			beq	:104			;Ja, Name OK!

::102			lda	(r0L),y			;Name aus Tabelle mit
			cmp	V202a1,y		;eingegebenem Namen vergleichen.
			bne	:103			;Unterschiedlich, nächster Name.

			iny
			cpy	#$10
			bne	:102

			CmpW	r1,r0
			beq	:105

			DB_OK	V202g0			;Fehler: "Name vorhanden!"
			lda	#$00
			rts

::103			AddVBW	16,r0			;Zeiger auf nächsten Namen
			jmp	:101			;Tabelle.

::104			lda	#$ff			;Name OK!
			rts

::105			lda	#$7f
			rts

;*** Anzahl Blocks berechnen.
:CalcBytesFree		jsr	ClrBoxText		;Info: "Prüfe freien Speicher..."
			PrintStrgV202f1

			jsr	Init_3			;Zeiger initialisieren.

			ClrW	V202a3			;Benötigte Blocks = $0000.

::101			ldy	#$00
			lda	(a6L),y			;Tabellen-Ende erreicht ?
			bne	:102			;Nein, DOS-Datei-Länge addieren.
			jmp	:201			;Freien Speicher auf Ziel-Disk testen.

::102			ldy	#$06			;DOS-Dateilänge in Zwischenspeicher
::103			lda	(a7L),y			;kopieren.
			sta	r10-6,y
			iny
			cpy	#$09
			bcc	:103

::104			lda	r11L			;Dateilänge < 254 Bytes ?
			bne	:105			;Nein, addieren.
			lda	r10H
			bne	:105
			lda	r10L
			beq	:106
			cmp	#255
			bcc	:107			;Ja, letzten Sektor addieren.

::105			sec				;DOS-Dateilänge -254 Bytes.
			lda	r10L
			sbc	#254
			sta	r10L
			lda	r10H
			sbc	#$00
			sta	r10H
			lda	r11L
			sbc	#$00
			sta	r11L
			IncWord	V202a3			;CBM-Blocks +1.
			jmp	:104

;*** Rest-Dateilänge < 255 Bytes.
::106			lda	#$00			;Dateilänge ohne Rest / 254.
			b $2c
::107			lda	#$01			;Dateilänge mit  Rest / 254.
			bit	DOSCopyMode		;GeoWrite-Datei erzeugen ?
			bpl	:108			;Nein, weiter...
			add	3			;Daten für Infoblock/VLIR-Header.
::108			clc
			adc	V202a3+0
			sta	V202a3+0
			bcc	:109
			inc	V202a3+1

::109			jsr	Init_4			;Zeiger auf nächsten Eintrag.
			jmp	:101			;Nächsten Eintrag testen.

;*** Freien Speicher auf Ziel-Disk ermitteln.
::201			jsr	GetDirHead
			txa
			bne	:204

			LoadW	r5,curDirHead		;Freie Blocks berechnen.
			jsr	CalcBlksFree

			lda	r4L
			sta	V202a3 +2
			ldx	r4H
			stx	V202a3 +3
			cpx	V202a3 +1
			bcc	:202
			bne	:203
			cmp	V202a3 +0
			bcs	:203

::202			ldx	#$ff			;Zuwenig Speicher.
			b $2c
::203			ldx	#$00			;OK.

::204			txa				;Status merken.
			pha
			jsr	ClrBox			;Infobox löschen.
			pla
			tax				;Status-Register wiederherstellen.
			rts				;Ende.

;*** Fehler-Meldung: "Nicht genügend Speicher auf Ziel!"
:NoDiskSpace		jsr	ClrBox

			jsr	i_C_DBoxTitel
			b	$06,$05,$1c,$01
			jsr	i_C_DBoxBack
			b	$06,$06,$1c,$0c

			FillPRec$00,$28,$2f,$0030,$010f

			jsr	UseGDFont
			Print	$38,$2e
			b	PLAINTEXT,"Information",NULL

			LoadW	r0,V202h0
			DB_RecBoxL202RVec_a

			ldx	#$00
			CmpBI	sysDBData,1
			beq	:101
			dex
::101			rts

;*** Freien Speicher ausgeben.
:PrintBlocks		PrintStrgV202h1
			MoveW	V202a3+0,r0
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV202h3

			PrintStrgV202h2
			MoveW	V202a3+2,r0
			lda	#%11000000
			jsr	PutDecimal
			PrintStrgV202h3

			jsr	i_C_DBoxDIcon
			b	$08,$0f,$06,$02
			jsr	i_C_DBoxDIcon
			b	$1a,$0f,$06,$02
			jmp	ISet_Achtung

;*** Farben zurücksetzen.
:L202RVec_a		jsr	i_C_ColorClr
			b	$06,$05,$1c,$0d
			FillPRec$00,$28,$8f,$0030,$010f
			rts

;*** Dateien löschen / umbenennen.
:DOS_GetFiles		ldx	#$00			;Diskette prüfen.
			b $2c
:GetFiles_a		ldx	#$ff			;Diskette einlegen.
			lda	Source_Drv		;Auf "Diskette in Laufwerk" testen.
			jsr	InsertDisk
			cmp	#$01
			beq	OpenDOS_Disk
			ldx	#$ff
			rts

;*** Neue DOS-Diskette öffnen-
:OpenDOS_Disk		jsr	DOS_GetSys		;DOS-Verzeichnis einlesen.
			jsr	DOS_GetDskNam		;Diskettenname einlesen.
			jsr	ClrBox			;Infofenster löschen.

;*** Dateien in Speicher einlesen.
:InitGetFiles		lda	#$00
			sta	V202b0			;Hauptverzeichnis einlesen.
			sta	V202c0			;Zeiger auf Anfang Verzeichnis.

			jsr	i_FillRam
			w	16*256,FileNTab
			b	$00
			jsr	i_FillRam
			w	9 *256,FileDTab
			b	$00

;*** Dateien einlesen und auswerten.
:ReadDiskDir		jsr	ReadDir			;Einträge einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			lda	V202b3			;Anzahl Dateien = 0 ?
			bne	SlctFileList		;Nein, Dateien anzeigen.

			DB_UsrBoxV202g1			;Fehler: "Keine Dateien..."
			CmpBI	sysDBData,YES		;Neue Diskette öffnen ?
			beq	GetFiles_a		;Ja, weiter...
			ldx	#$ff			;Ende.
::101			rts

;*** Datei-Auswahl-Box.
:SlctFileList		MoveB	Seite ,V202c10+0	;Aktuelle Sektorwerte merken.
			MoveB	Spur  ,V202c10+1
			MoveB	Sektor,V202c10+2
			MoveW	a8    ,V202c15		;Zeiger auf Eintrag merken.

			MoveB	V202b1,V202d1		;Anzahl Verzeichnisse = Action-Files.

			lda	#<V202d0
			ldx	#>V202d0
			jsr	SelectBox

			lda	r13L			;Verzeichnis wählen ?
			beq	:201			;Ja, weiter...
			cmp	#$01			;Directory weiterlesen ?
			beq	:102			;Ja, weiter...
			cmp	#$80			;Diskette wechseln ?
			beq	:104			;Ja, weiter...
			cmp	#$ff			;Dateiauswahl ?
			beq	:101			;Ja, weiter...

::100			ldx	#$ff			;Abruch!
			b $2c
::101			ldx	#$00			;Dateien ausgewählt.
			rts

;*** Verzeichnis weiterblättern.
::102			lda	V202b5			;Weiterblättern.
			bne	:103			;Ende erricht ?
			lda	#$ff			;Nein, weiterlesen.
			b $2c
::103			lda	#$00			;Ja, zum Anfang zurück.
			sta	V202c0			;Modus merken.
			jmp	ReadDiskDir		;Directory weiterlesen.
::104			jmp	GetFiles_a

;*** SubDir auswählen.
::201			ldy	#$0f
			lda	(r15L),y		;Zeiger auf Datei-Daten
			jsr	SetPosEntry		;berechnen.

			ldy	#$04			;Ist Cluster = 0 ?
			lda	(r0L),y
			bne	:202
			iny
			lda	(r0L),y
			bne	:202			;Nein -> SubDir.
			sta	V202b0			;Ja, Zurück zum Hauptverzeichnis.
			sta	V202c0
			sta	V202c2+0
			sta	V202c2+1
			jmp	ReadDiskDir		;Dateien einlesen.

::202			ldy	#$04			;Cluster-Nr. als Startadresse für.
			lda	(r0L),y			;Unterverzeichnis setzen.
			sta	V202c2+0
			iny
			lda	(r0L),y
			sta	V202c2+1
			LoadB	V202b0,$ff		;Sub-Directory
			ClrB	V202c0			;Dateien aus SubDir lesen.
			jmp	ReadDiskDir		;Dateien einlesen.

;*** Disketteninhalt einlesen.
:ReadDir		lda	#$00
			sta	V202b1			;Zähler Directorys auf NULL.
			sta	V202b2			;Zähler Dateien auf NULL.
			sta	V202b3			;Zähler Einträge auf NULL.

			jsr	Init_3			;Zeiger initialisieren.

			jsr	DoInfoBox		;Info-Box.
			PrintStrgDB_RdSDir
			lda	#%00010000		;Directory-Einträge in Tabelle
			ldy	#$00			;kopieren.
			jsr	ReadFiles
			cpx	#$00
			bne	:101
			cmp	#$00
			bne	:101

			jsr	ClrBoxText		;Info-Box.
			PrintStrgDB_RdFile
			LoadB	V202c0,$7f		;Zeiger zurück auf Verzeichnis-Anfang.
			lda	#%00000000		;Datei-Einträge in Tabelle
			ldy	#$01			;kopieren.
			jsr	ReadFiles

::101			txa
			pha
			jsr	ClrBox
			pla
			tax
			rts

;*** Dateien & Directorys einlesen.
:ReadFiles		sta	:102 +1			;Eintrags-Typ (SubDir/Datei) merken.
			sty	:103 +1
			jsr	ResetDir
			txa
			beq	:105
			rts

::102			lda	#%00000000		;Eintrag auf SubDir/Datei testen.
			jsr	ChkFileName
			cmp	#$00			;$00 = Verzeichnis-Ende ?
			beq	:106			;Ja, Ende...
			cmp	#$ff			;$FF = Ungültiger Eintrag ?
			beq	:104			;Ja, überspringen...

::103			ldx	#$ff			;Eintrag in Tabelle kopieren.
			jsr	CopyFileName
			jsr	NextEntry		;Zeiger auf nächsten Eintrag.
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			beq	:105			;Ja, weiter...

			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a6L),y
			lda	#$ff
			ldx	#$00			;Kein Diskettenfehler.
			rts				;Ende.

;*** Nächsten Eintrag in Tabelle prüfen.
::104			jsr	NextEntry		;Zeiger auf nächsten Eintrag.

::105			CmpBI	V202c14,16		;Alle Einträge aus Sektor gelesen ?
			bne	:102			;Nein, weiter...

			ClrB	V202c14			;Zähler für Sektor-Einträge löschen.
			jsr	GetNxDirSek		;Nächsten Directory-Sektor lesen.
			txa
			beq	:102
			bpl	:107

::106			LoadB	V202b5,$ff		;Verzeichnis-Ende erreicht, Abbruch.

			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a6L),y

			ldx	#$00
::107			rts				;Ende...

;*** Zeiger auf nächsten Sektor-Eintrag.
:NextEntry		pha
			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V202c14			;Eintrag.
			pla
			rts

;*** Datei-Namen testen.
:ChkFileName		sta	:102 +1			;Datei-Maske merken.

			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			bne	:101
			rts				;Ja, Ende.

::101			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:104			;Ja, Datei ignorieren.

			ldy	#$0b
			lda	(a8L),y			;Datei-Maske einlesen.
			and	#%00010000		;Hat Datei gewünschtes
::102			cmp	#%00000000		;Dateiformat ?
			bne	:104			;Nein, Datei ignorieren.
			cmp	#%00010000		;Verzeichnis ?
			beq	:103			;Ja, Kein "Cluster = $0000"-Test.

			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y			;Ja, keine gültige Datei.
			bne	:103
			iny
			lda	(a8L),y
			beq	:104

::103			lda	#$7f			;Gültiger Eintrag.
			rts
::104			lda	#$ff			;Ungültiger Eintrag.
			rts

;*** Dateiname in Tabelle übertragen.
:CopyFileName		inc	V202b1,x		;Zähler (SubDir/Datei) erhöhen.

			lda	#" "			;Trennzeichen für Verzeichnisse.
			cpx	#$00
			beq	:101
			lda	#"."			;Trennzeichen für Dateien.
::101			sta	:107 +1			;Zeichen zwischen "NAME" + "EXT"

			lda	#$00			;Zeiger initialisieren.
			sta	:102 +1
			sta	:106 +1

::102			ldy	#$00			;Datei-Name in Speicher kopieren und
			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:104			;Code < $20 ? Nein, weiter.
::103			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:105
::104			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:103
::105			inc	:102 +1			;Zeiger auf nächstes Zeichen.
::106			ldy	#$00
			sta	(a6L),y			;Zeichen in Speicher kopieren.
			inc	:106 +1			;Zeiger auf nächstes Zeichen.
::107			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpy	#$07			;einfügen.
			beq	:106
			cpy	#$0b
			bne	:102

			lda	#$00
::108			iny				;Dateinamen auf 16 Zeichen
			sta	(a6L),y			;mit $00-Bytes auffüllen.
			cpy	#$0f
			bne	:108

			lda	V202b3			;Nr. des Eintrags in Datei-Tabelle.
			sta	(a6L),y			;(als Zeiger auf Daten-Tabelle).

			ldx	#$00
			lda	#$16			;Daten des Eintrags in Daten-Tabelle.
::109			pha				;Uhrzeit, Datum, Erster Cluster und
			tay				;Datei-Größe.
			lda	(a8L),y
			pha
			txa
			tay
			pla
			sta	(a7L),y
			inx
			pla
			add	$01
			cmp	#$1f
			bne	:109

			jsr	Init_4			;Zeiger auf nächsten Eintrag.

			inc	V202b3			;Zähler für Anzahl Einträge +1.
			CmpBI	V202b3,255		;Tabelle voll ?
			beq	:110			;Ja, Ende...
			lda	#$00			;Nein, weiter...
			rts
::110			lda	#$ff
			rts

;*** Zeiger auf Eintrag positionieren.
:SetPosEntry		sta	r0L			;Zeiger auf Datei in Daten-Tabelle
			LoadB	r1L,9			;berechnen.
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			AddVW	FileDTab,r0
			rts

;*** Directory initialisieren.
:ResetDir		ldy	V202c0			;Verzeichnis-Startwerte ermitteln ?
			bne	:104			;Nein, weiter...

			bit	V202b0			;Zeiger auf Anfang Hauptverzeichnis ?
			bmi	:101			;Nein, Zeiger auf Unterverzeichnis...

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor +0
			sta	V202b4    +0
			lda	MdrSektor +1
			sta	V202b4    +1
			jmp	:102

::101			lda	V202c2+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V202c2+1
			sta	V202c11+0
			stx	V202c11+1
			jsr	Clu_Sek

::102			lda	Seite			;Startposition merken.
			sta	V202c1+0
			sta	V202c10+0
			lda	Spur
			sta	V202c1+1
			sta	V202c10+1
			lda	Sektor
			sta	V202c1+2
			sta	V202c10+2

			MoveB	V202b4,V202c12
			MoveB	SpClu ,V202c13

			lda	#$00
			sta	V202c14			;Zähler Dateien auf 0.
			sta	V202b5			;Verzeichnis-Anfang markieren.
			lda	#<Disk_Sek
			sta	a8L
			sta	V202c15+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V202c15+1
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:103
			jsr	SaveDirData		;Directory-Position speichern.
			ldx	#$00
::103			rts

::104			cpy	#$7f			;Zeiger auf Anfang Verzeichnis zurück ?
			bne	:105			;Nein, weiterlesen.

			jsr	LoadDirData		;Directory-Zeiger wieder setzen.
			MoveB	V202c10+0,Seite
			MoveB	V202c10+1,Spur
			MoveB	V202c10+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:103			;Disketten-Fehler.

			MoveW	V202c15,a8
			ldx	#$00
			stx	V202b5			;Directory-Ende nicht erreicht.
			rts				;Ende.

::105			jsr	SaveDirData		;Directory weiterlesen.
			MoveB	V202c10+0,Seite
			MoveB	V202c10+1,Spur
			MoveB	V202c10+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:103			;Disketten-Fehler.

			MoveW	V202c15,a8
			ldx	#$00
			rts

;*** Zeiger auf aktuelle Directory-Position wieder herstellen.
:LoadDirData		ldy	#$09
::101			lda	V202c20,y
			sta	V202c10,y
			dey
			bpl	:101
			rts

;*** Zeiger auf aktuelle Directory-Position sichern.
:SaveDirData		ldy	#$09
::101			lda	V202c10,y
			sta	V202c20,y
			dey
			bpl	:101
			rts

;*** Nächsten Sektor lesen.
:GetNxDirSek		lda	V202b5			;Directory-Ende ?
			bne	:101			;Ja, Ende...

			bit	V202b0			;Hauptverzeichnis ?
			bmi	:103			;Nein, weiter...

			CmpBI	V202c12,1		;Alle Sektoren
			beq	:101			;gelesen ?

			dec	V202c12			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jmp	D_Read			;Sektor lesen.

::101			ldx	#$ff			;Directory-Ende...
::102			rts

;*** Nächster Sektor aus Unterverzeichnis.
::103			CmpBI	V202c13,1		;Alle Sektoren
			beq	:104			;gelesen ?

			dec	V202c13			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jmp	D_Read

::104			lda	V202c11+0		;Nächsten Cluster lesen.
			ldx	V202c11+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H
			sta	V202c11+0
			stx	V202c11+1

;*** Cluster Einlesen.
:GetSDirClu		cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:101			;Nein, weiter...
			cpx	#$0f
			bcc	:101
			ldx	#$ff
			rts

::101			jsr	Clu_Sek			;Cluster berechnen.

			lda	SpClu
			sta	V202c13			;Zähler setzen.

			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jmp	D_Read			;Ersten Sektor lesen.

;*** Variablen.
:DOSCopyMode		b $00				;$00 = ->CBM, $FF= ->GW.
:DCM2			b $00				;$FF = Aktuelle Partition übernehmen.

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
:V202a0			s 17				;Zwischenspeicher für Datei-Name.
:V202a1			s 17				;Zwischenspeicher für Datei-Name.
:V202a2			b "LinkFile",0,0,0,0,0,0,0,0,0

:V202a3			w $0000				;Benötigter Speicher.
			w $0000				;Freier Speicher.

;*** Variablen und Texte.
:V202b0			b $00				;Directory-Typ.
:V202b1			b $00				;Anzahl Directorys.
:V202b2			b $00				;Anzahl Dateien.
:V202b3			b $00				;Anzahl Einträge.
:V202b4			w $0000				;Anzahl Sektoren im Hauptverzeichnis
:V202b5			b $00				;$FF = Directory-Ende.

;*** Variablen: Lesen des Directory.
:V202c0			b $00				;$00 = Ersten Dir-Sektor ermitteln.
							;$7F = Startwerte auf ersten Directory-Sektor.
							;$FF = Directory weiterlesen.
:V202c1			s $03				;Startadresse Directory (Sektor)
:V202c2			w $0000				;       "               (Cluster)

:V202c10		s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V202c11		w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V202c12		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V202c13		b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V202c14		b $00				;Zähler Einträge in Sektor.
:V202c15		w $0000				;Zeiger auf Anfang Eintrag in Sektor.

:V202c20		s $03				;Startadresse aktive Datei-Tabelle (Sektor)
:V202c21		w $0000				;       "                          (Cluster)
:V202c22		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V202c23		b $00				;Zwischenspeicher: Zeiger auf Sektor in Cluster.
:V202c24		b $00				;Zwischenspeicher: Zähler Einträge in Sektor.
:V202c25		w $0000				;Zwischenspeicher: Zeiger auf Eintrag in Sektor.

;*** Variablen.
:V202d0			b $80
			b $00
			b $ff
			b $0c
:V202d1			b $00
			w Titel_File
			w FileNTab

if Sprache = Deutsch
;*** Titel.
:V202e0			b PLAINTEXT,"Partition Ziel-Laufwerk",NULL
:V202e1			b PLAINTEXT,"Dateiname ändern",NULL
:V202e2			b PLAINTEXT,"Ziel-Verzeichnis",NULL
endif

if Sprache = Englisch
;*** Titel.
:V202e0			b PLAINTEXT,"Partition target-drive",NULL
:V202e1			b PLAINTEXT,"Edit filename",NULL
:V202e2			b PLAINTEXT,"Target directory",NULL
endif

if Sprache = Deutsch
;*** Info: "Überprüfe das Zielverzeichnis..."
:V202f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Überprüfe das"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Zielverzeichnis..."
			b NULL

;*** Info: "Prüfe freien Speicher auf Ziel-Laufwerk..."
:V202f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Prüfe freien Speicher"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf Ziel-Laufwerk..."
			b NULL

;*** Hinweis "Datei wird gelöscht!"
:V202f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Fehler: "Datei-Name bereits vergeben!"
:V202g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Der gewählte Dateiname",NULL
::102			b        "ist bereits vergeben!",NULL

;*** Fehler: "Keine Dateien auf Disk!"
:V202g1			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Diskette ist leer!",NULL
::102			b        "Eine neue Diskette öffnen ?",NULL

;*** Fehler: "Nicht genügend freier Speicher auf Ziel-Disk!"
:V202h0			b %00100000
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

:V202h1			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Benötigt ca."
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V202h2			b GOTOXY
			w DBoxLeft +$0030
			b 109
			b "Verfügbar"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V202h3			b " Block(s)",NULL
endif

if Sprache = Englisch
;*** Info: "Überprüfe das Zielverzeichnis..."
:V202f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Check target-"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory..."
			b NULL

;*** Info: "Prüfe freien Speicher auf Ziel-Laufwerk..."
:V202f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Check free diskspace"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on target-drive..."
			b NULL

;*** Hinweis "Datei wird gelöscht!"
:V202f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Delete file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

;*** Fehler: "Datei-Name bereits vergeben!"
:V202g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Selected filename",NULL
::102			b        "already exists!",NULL

;*** Fehler: "Keine Dateien auf Disk!"
:V202g1			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Disk is empty!",NULL
::102			b        "Open new disk ?",NULL

;*** Fehler: "Nicht genügend freier Speicher auf Ziel-Disk!"
:V202h0			b %00100000
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

:V202h1			b PLAINTEXT,BOLDON
			b GOTOXY
			w DBoxLeft +$0030
			b 98
			b "Needed"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V202h2			b GOTOXY
			w DBoxLeft +$0030
			b 109
			b "Available"
			b GOTOX
			w DBoxLeft +$0072
			b ": ",NULL

:V202h3			b " Block(s)",NULL
endif
