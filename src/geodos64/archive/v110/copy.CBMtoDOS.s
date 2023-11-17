; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L220: Datei von CBM nach MS-DOS kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:CBM_Datum		= CopyOptions +0
:CBM_OverWrite		= CopyOptions +1
:CBM_DOSName		= OptCBMtoDOS +0
:CBM_LfCode		= OptCBMtoDOS +1
:CBM_ZielDir		= OptCBMtoDOS +2
:CBM_ZielDirCl		= OptCBMtoDOS +3
:CBM_FFCode		= OptGWtoDOS  +0

;*** Zurück zu geoDOS.
:L220ExitGD		jmp	InitScreen		;Ende...

;*** Datei von CBM/GW nach MS-DOS kopieren
:CBMtoDOS		stx	CBMCopyMode

			lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			jmp	L220ExitGD

::1			jsr	DoInfoBox
			PrintStrgV220i0

			jsr	GetBSek			;Boot-Sektor lesen.
			jsr	Load_FAT		;FAT einlesen.

			jsr	ClrBox

			lda	#$00			;Directory-Typ für
			sta	CBM_ZielDirCl+0
			sta	CBM_ZielDirCl+1

;*** Zeiger auf Hauptverzeichnis.
:SlctRootDir		lda	#$00			;Zeiger auf Hauptverzeichnis.
			sta	CBM_ZielDir
			sta	V220a0			;Directory-Typ "Root-Dir".
			sta	V220b0			;Zeiger auf ersten Directory-Sektor.

;*** Verzeichnisse einlesen..
:RdDirEntry		jsr	GetDirEntry		;Unterverzeichnisse einlesen.
			lda	V220a1			;Weitere Verzeichnisse gefunden ?
			bne	:1			;Ja, anzeigen.
			jmp	SelectFiles		;Nein, Dateien einlesen.

;*** Datei-Auswahl-Box.
::1			MoveB	Seite,V220b3+0		;Sektorwerte merken.
			MoveB	Spur,V220b3+1
			MoveB	Sektor,V220b3+2
			MoveW	a8,V220b8

			LoadW	r14,V220g0		;Unterverzeichnis wählen.
			LoadW	r15,V220z1
			lda	#$ff
			ldx	#$0c
			ldy	V220a1
			jsr	DoScrTab

			ldy	sysDBData		;Ergebiss prüfen.
			cpy	#$01			;"Abbruch" ?
			beq	:2
			jmp	L220ExitGD 		;Ja, Ende...

::2			cmp	#$00			;"OK" ?
			bne	SelectFiles		;Ja, Dateien einlesen.

;*** SubDir auswählen.
			ldy	#$0e			;Cluster = 0 ?
			lda	(r15L),y
			bne	:3
			iny
			lda	(r15L),y
			bne	:3			;Nein -> Unterverzeichnis.
			jmp	SlctRootDir		;Ja   -> Hauptverzeichnis.

;*** SubDir auswählen.
::3			ldy	#$0e			;Cluster-Nr. setzen.
			lda	(r15L),y
			sta	CBM_ZielDirCl+0
			sta	V220b2+0
			iny
			lda	(r15L),y
			sta	CBM_ZielDirCl+1
			sta	V220b2+1

			LoadB	V220a0,$01		;Sub-Directory
			ClrB	V220b0
			lda	#$ff
			sta	CBM_ZielDir
			jmp	RdDirEntry		;Box aufbauen.

;*** Dateien auswählen.
:SelectFiles		lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive

			lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			jmp	L220ExitGD

::1			jsr	DoInfoBox
			PrintStrgV220i2

			jsr	OpenDisk		;Diskette öffnen.
			txa
			beq	:2
			jmp	DiskError		;Disketten-Fehler.

::2			lda	CBMCopyMode		;geoWrite nach DOS ?
			beq	:3			;Nein, weiter.
			jmp	SelectGWFiles		;Ja, geoWrite-Dokumente anzeigen.

;*** CBM-dateien auswählen.
::3			jsr	Get1stDirEntry		;Ersten Directory-Sektor einlesen.
			ClrB	V220c0			;Anzahl Dateien löschen.
			LoadW	a7,V220z1		;Zeiger auf Anfang Zwischenspeicher.

::4			ldx	#$00			;Datei-Größe testen.
::5			lda	diskBlkBuf+31,x
			bne	:6
			lda	diskBlkBuf+30,x
			beq	:8

::6			lda	diskBlkBuf+2,x
			and	#%00000111		;Datei-Typ = $x0 ? Übergehen.
			beq	:8
			cmp	#$04			;Datei-Typ = $x4 ? Übergehen.
			beq	:8
			lda	diskBlkBuf+23,x		;VLIR-File       ? Übergehen.
			bne	:8

			ldy	#$00			;Datei-Name in Tabelle.
::7			lda	diskBlkBuf+5,x
			sta	(a7L),y
			inx
			iny
			cpy	#$10
			bne	:7

			AddVBW	16,a7
			inc	V220c0			;Anzahl Files in Tabelle erhöhen.
			CmpBI	V220c0,255		;Tabelle voll ?
			beq	:9			;Ja, Abbruch...

::8			txa
			and	#%11100000		;Zeiger auf nächsten Eintrag.
			add	32
			tax
			bne	:5

			lda	diskBlkBuf +0		;Nächsten Directory-Sektor lesen.
			beq	:9			;Ende erreicht ? Ja, Ende...
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Sektor lesen.
			txa
			beq	:4
			jmp	DiskError		;Disketten-Fehler.

::9			ldy	#$00			;Tabellen-Ende kennzeichnen.
			tya
			sta	(a7L),y

			jsr	ClrBox

			lda	V220c0			;Anzahl Dateien = 0 ?
			bne	:10			;Nein, weiter...
			jmp	NoFiles			;Fehler: "Keine Dateien gefunden..."

::10			jmp	DoCBMFileBox		;Auswahlbox.

;*** geoWrite-Files einlesen.
:SelectGWFiles		LoadB	r7L,APPL_DATA		;GEOS-Datei-Typ "APPL_DATA".
			LoadB	r7H,255			;Max. 255 Dateien.
			LoadW	r10,V220c1		;GEOS-Klasse "Write Image".
			LoadW	r6,V220z1		;Startadresse Zwischenspeicher.
			jsr	FindFTypes
			txa
			beq	:1
			jmp	DiskError		;Disketten-Fehler.

::1			lda	r7H
			cmp	#$ff
			bne	:2

			jsr	ClrBox
			jmp	NoFiles			;Fehler: "Keine Dateien auf Disk!"

::2			lda	#<V220z1		;Zeiger auf Anfang Zwischenspeicher.
			sta	a6L
			sta	a7L
			lda	#>V220z1
			sta	a6H
			sta	a7H

::3			ldy	#$00			;16 +NULL Dateie-Namen in 16-Zeichen
::4			lda	(a6L),y			;Datei-Namen umwandeln.
			sta	(a7L),y
			iny
			cpy	#$10
			bne	:4

			AddVW	17,a6			;Zeiger auf nächsten Datei-Namen.
			AddVW	16,a7

			inc	r7H
			lda	r7H
			cmp	#$ff			;Ende der Tabelle erreicht ?
			bne	:3			;Nein, weiter.

			ldy	#$00			;Tabellen-Ende markieren.
			tya
			sta	(a7L),y

			jsr	ClrBox

;*** Datei-Auswahlbox.
:DoGWFileBox		lda	#<V220g2		;Titel: "geoWrite-Dokumente"
			ldx	#>V220g2
			jmp	DoAllTypeBox

:DoCBMFileBox		lda	#<V220g1		;Titel: "Dateien wählen"
			ldx	#>V220g1

:DoAllTypeBox		sta	r14L			;Adresse Titelzeile merken.
			stx	r14H
			LoadW	r15,V220z1
			lda	#$ff
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab		;Dateien auswählen.

			ldy	sysDBData		;Abbruch ?
			cpy	#$01			;Nein.
			beq	:2			;Weiter.
::1			jmp	L220ExitGD		;Zurück zu geoDOS.

::2			cpx	#$00
			beq	:1

;*** CBM-File-Tabelle erzeugen.
:GetFileData		jsr	DoInfoBox		;Hinweis: "Daten werden eingelesen..."
			PrintStrgV220i3

			ClrB	V220c0			;Datei-Tabelle erzeugen.
			LoadW	a6,V220z2		;Tabelle Datei-Datum.
			LoadW	a7,V220z1		;Tabelle Datei-Namen.

::1			ldy	#$0f			;DOS-Datei-Namen erzeugen.
::2			lda	(a7L),y
			cmp	#$a0
			bne	:3
			lda	#$00
			sta	(a7L),y
::3			sta	V220d1,y
			dey
			bpl	:2

			LoadW	r6,V220d1		;CBM-Datei-Eintrag lesen.
			jsr	FindFile
			txa
			beq	:5
::4			jmp	DiskError

::5			ldx	#$04			;Datei-Datum, -Uhrzeit.
::6			lda	dirEntryBuf+23,x
			sta	r2L,x
			dex
			bpl	:6

			jsr	SetDate			;DOS-Datum erzeugen.

			ldy	#$03
::7			lda	r0,y
			sta	(a6L),y
			dey
			bpl	:7

			ldy	#$04			;Anzahl Sektoren der CBM-Datei.
			lda	dirEntryBuf+28
			sta	(a6L),y
			iny
			lda	dirEntryBuf+29
			sta	(a6L),y

			ldy	#$06			;Erster Sektor der Datei.
			lda	dirEntryBuf +1
			sta	(a6L),y
			iny
			lda	dirEntryBuf +2
			sta	(a6L),y

			inc	V220c0

			AddVBW	8,a6			;Zeiger auf nächste CBM-Datei.
			AddVBW	16,a7

			ldy	#$00
			lda	(a7L),y			;Ende erreicht ?
			bne	:1			;Nein, weiter...

;*** Anzahl freie Cluster/freie Bytes auf DOS-Diskette berechnen.
:CalcFreeClu		jsr	ClrBoxText
			PrintStrgV220i4

			lda	Target_Drv		;Target-Drive aktivieren.
			jsr	NewDrive

			jsr	InitForBA		;Anzahl freier Sektoren berechnen.
			jsr	Max_Free
			jsr	DoneWithBA

			lda	#$00
			sta	V220e0+0		;Zähler Cluster Initialisieren.
			sta	V220e0+1
			sta	V220e1+0		;Zähler freie Cluster Initialisieren.
			sta	V220e1+1
			LoadW	a1,FAT			;Zeiger auf FAT bereitstellen.
			MoveW	Free_Clu,V220e2
			MoveW	Clu_Byte,V220e3

::1			clc				;Zeiger auf Cluster in FAT setzen und
			lda	V220e0			;Zeiger einlesen.
			adc	#$02
			tay
			lda	V220e0+1
			adc	#$00
			tax
			tya
			jsr	Get_Clu

			CmpW0	r1
			bne	:2

			IncWord	V220e1			;Anzahl freie Cluster um 1 erhöhen.
::2			IncWord	V220e0			;Zähler +1 bis alle Cluster geprüft.
			CmpW	V220e0,Free_Clu
			bne	:1

			CmpW	V220e1,V220c0		;Genügend Cluster für Dateien ?
			bcs	CalcBytesFree
			jmp	NoDOSClu		;Fehler: "Zuwenig freie Cluster!"

;*** Prüfen ob genügend freie Bytes in Clustern für alle Dateien vorhanden.
:CalcBytesFree		LoadW	a6,V220z1
			LoadW	a7,V220z2
			ClrB	AnzahlFiles

::1			ldy	#$04			;CBM-Datei-Länge
			lda	(a7L),y			;berrechnen.
			sta	r0L
			iny
			lda	(a7L),y
			sta	r0H
			LoadB	r1L,254
			ldx	#r0L
			ldy	#r1L
			jsr	BMult

::2			SubVW	1,V220e1		;Benötigte Cluster belegen.
			bcs	:3			;Kein Cluster mehr frei ?
			jmp	NoDOSByt		;Fehler: "Nicht genügend freie Bytes!"

::3			IncWord	V220e4			;Anzahl benötigte Cluster +1.
			SubW	V220e3,r0		;Anzahl Bytes/Cluster von Datei-Länge
			bcs	:2			;abziehen. Weiter bis Datei-Ende.

			inc	AnzahlFiles
			AddVBW	16,a6			;Zeiger auf nächste Datei.
			AddVBW	8,a7

			ldy	#$00			;Weitere Datei ?
			lda	(a6L),y
			bne	:1			;Ja, weiter...

;*** Konvertierungstabelle laden.
:GetConvTab		jsr	ClrBox
			lda	CTabCBMtoDOS
			beq	SetDOSName

			jsr	GetStartDrv		;geoDOS-Laufwerk aktivieren.
			txa
			beq	:1
			jmp	GDDiskError

::1			LoadW	r6,CTabCBMtoDOS
			LoadW	r7,V220z0
			LoadB	r0L,%00000001
			jsr	GetFile			;Tabelle in Speicher einlesen.
			txa
			beq	:2
			jmp	DiskError

::2			jsr	GetWorkDrv		;Arbeits-Laufwerk aktivieren.

;*** MS-DOS-Dateinamen definieren.
:SetDOSName		lda	CBM_DOSName
			beq	:1			;DOS-Namen automatisch erzeugen ?
			jmp	NewDOSName		;Nein, alle Namen neu eingeben.

::1			LoadW	a7,V220z1		;Zeiger auf Datei-Tabelle.
::2			ldy	#$0f			;CBM-Name in Puffer kopieren.
::3			lda	(a7L),y
			sta	V220d1,y
			dey
			bpl	:3

			MoveW	a7,r0			;CBM-Datei-Name nach MS-DOS wandeln.
			jsr	ConvertDOS

			AddVBW	16,a7			;Zeiger auf nächste CBM-Datei.

			ldy	#$00			;Ende der Tabelle erreicht ?
			lda	(a7L),y
			bne	:2			;Nein, weiter...

:DoDOSNameTab		LoadW	r14,V220f1		;Tabelle aufbauen.
			LoadW	r15,V220z1
			lda	#$00
			ldx	#$0c
			ldy	#$00
			jsr	DoScrTab

			ldy	sysDBData		;Ergebniss auswerten.
			cpy	#$01			;Datei ausgewählt ?
			beq	:2			;Ja, Name ändern.
			cmp	#$01			;"Abbruch" ?
			bne	:3
::1			jmp	TestFileTab		;Ziel-Verzeichnis prüfen.

::2			MoveW	r15,r0			;Ausgewählte Datei umbenennen.
			jsr	RenDOSFile
			cpx	#$ff			;Kein neuer gültiger Datei-Name.
			beq	DoDOSNameTab
			MoveW	r15,r0			;Datei-Name ins MSDOS-Format wandeln.
			jsr	ReWriteName
			jmp	DoDOSNameTab		;Zurück zur Auswahl-Tabelle.

::3			jmp	L220ExitGD		;Zurück zum Options-Menü.

;*** Neuen Namen eingeben.
:NewDOSName		LoadW	a7,V220z1		;Vektor auf File-Tabelle.
::1			MoveW	a7,r0			;Nächste Datei umbenennen.
			jsr	RenDOSFile
			cpx	#$ff			;Kein neuer gültiger Datei-Name.
			bne	:2
			jmp	L220ExitGD

::2			MoveW	a7,r0			;Datei-Name ins MSDOS-Format wandeln.
			jsr	ConvertDOS
			MoveW	a7,r0
			jsr	ReWriteName

			AddVBW	16,a7			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a7L),y			;Ende der Tabelle erreicht ?
			bne	:1			;Nein, nächste Datei.
			jmp	TestFileTab

;*** Dateie-Namen zurück in Tabelle kopieren.
:ReWriteName		ldy	#$00
::1			lda	InpNamBuf,y
			beq	:2
			sta	(r0L),y
			iny
			cpy	#$10
			bne	:1
			beq	:4
::2			lda	#$00
::3			sta	(r0L),y
			iny
			cpy	#$10
			bne	:3
::4			rts

;*** Einzel-Datei umbenennen.
:RenDOSFile		MoveW	r0,V220d2		;Zeiger auf Datei-Name speichern.

:InitRename		ldy	#$0f			;CBM-Datei-Name in Puffer kopieren.
::1			lda	(r0L),y
			sta	V220d1,y
			dey
			bpl	:1

			jsr	i_FillRam		;Eingabe-Puffer löschen.
			w	17,InpNamBuf
			b	$00

::2			LoadW	r10,InpNamBuf		;Dialogbox zur Eingabe des neuen
			LoadW	r0,V220f0		;Datei-Namens.
			ClrDlgBoxL220RVec

			lda	sysDBData
			cmp	#$ff			;Name nochmals eingeben.
			beq	:2
			cmp	#$02			;Abbruch ?
			bne	:4			;Nein, Name übernehmen.
::3			ldx	#$ff			;Ja, Abbruch.
			rts

::4			lda	InpNamBuf		;Leeres Eingabefeld ?
			beq	:3			;Ja, Abbruch.

::5			ldy	#$00			;Name aus Eingabepuffer in
::6			lda	InpNamBuf,y		;Übergabepuffer kopieren.
			beq	:7
			sta	V220d1,y
			iny
			cpy	#$10
			bne	:6
::7			lda	#$00
::8			sta	V220d1,y
			iny
			cpy	#$11
			bne	:8

			LoadW	r0,InpNamBuf		;Name in DOS-Format wandeln.
			jsr	ConvertDOS

			LoadW	r0,V220z1		;Prüfen ob Name bereits vergeben.

::9			ldy	#$00
			lda	(r0L),y			;Ende der Tabelle erreicht ?
			beq	:12			;Ja, Name OK!
::10			lda	(r0L),y			;Name aus Tabelle mit
			cmp	InpNamBuf,y		;eingegebenem Namen vergleichen.
			bne	:11			;Unterschiedlich, nächster Name.
			iny
			cpy	#$10
			bne	:10

			LoadW	r0,V220h9		;Fehler: "Name vorhanden!"
			ClrDlgBoxCSet_Grau
			MoveW	V220d2,r0
			jmp	InitRename

::11			AddVBW	16,r0			;Zeiger auf nächsten Namen
			jmp	:9			;Tabelle.

::12			ldx	#$00			;Name OK!
			rts

;*** Datei-Namen konvertieren.
:ConvertDOS		ldy	#$00
			ldx	#$00
::1			lda	V220d1,x		;Zeichen aus Datei-Namen einlesen.
			beq	:2
			cmp	#"."			;Punkt ?
			beq	:3			;Ja, Abbruch.
			cmp	#" "			;Leerzeichen ?
			bne	:4			;Nein, weiter...
			inx				;Ja, überlesen.
			cpx	#$10
			bne	:1
::2			lda	#$20			;Datei-Namen oder Extension auf
			sta	(r0L),y			;volle Länge mit Leerzeichen auffüllen.
			iny
::3			cpy	#$08			;Ende Datei-Name erreicht ?
			beq	:6			;Ja, weiter.
			cpy	#$0b			;Ende Extension erreicht ?
			bne	:2			;Nein, weiter auffüllen.
			beq	:7			;Ja, Ende.
::4			cmp	#$60			;Zeichen auf Zulässigkeit testen.
			bcc	:5
			sub	$20
			bcs	:4
::5			sta	(r0L),y			;Zeichen in Datei-Namen schreiben.
			iny
::6			inx				;Weiter mit nächstem Zeichen.
			cpy	#$0b			;Ende erreicht ?
			bne	:1			;Nein, weiter...

::7			lda	#$00			;Rest des Datei-Namens löschen.
			sta	(r0L),y
			iny
			cpy	#$10
			bne	:7

			ldy	#$0a			;Punkt zwischen Namen und Extension
::8			lda	(r0L),y			;einfügen.
			iny
			sta	(r0L),y
			dey
			dey
			cpy	#$07
			bne	:8
			iny
			lda	#"."			;Punkt in Datei-Namen einfügen.
			sta	(r0L),y
			rts

;*** Datei-Namen testen.
:TestFileTab		jsr	DoInfoBox		;Hinweis: "Prüfe Ziel-Verzeichnis..."
			PrintStrgV220i5

			lda	Target_Drv		;Target-Drive aktivieren.
			jsr	NewDrive

			ClrB	V220b0			;Zeiger auf Anfang Ziel-Verzeichnis.
			jsr	ResetDir

:TestFile		ldy	#$00			;Byte aus Verzeichnis einlesen.
			lda	(a8L),y
			bne	:1
			jmp	FreeDirEntry		;Verzeichnis-Test beendet.

::1			cmp	#$e5
			bne	:2
			jmp	ChkNxFile

::2			LoadW	a7,V220z1		;Zeiger auf File-Tabelle.

;*** DOS-Datei mit Datei-Tabelle vergleichen.
:TestCBMFile		ldy	#$0a			;Prüfen ob DOS-Datei in Tabelle
::1			lda	(a8L),y			;enthalten -> "File Exist!"
			cpy	#$08
			bcc	:2
			iny
::2			cmp	(a7L),y
			beq	:3
			jmp	ChkNxFile		;Name ungleich, nächster Name.
::3			cpy	#$09
			bcc	:4
			dey
::4			dey
			bpl	:1

			ldy	#$0b			;Falls DOS-Eintrag ein Sub-Dir ist,
			lda	(a8L),y			;CBM-Datei immer ignorieren.
			cmp	#%00010000
			bne	L220c0
			jmp	L220c2

;*** Datei vorhanden.
:L220c0			lda	CBM_OverWrite		;Datei bereits vorhanden.
			bpl	L220c3			;-> Keine Abfrage.

			jsr	ClrBox

;*** Hinweis: "Datei existiert bereits!"
:L220c1			MoveW	a7,r15			;Abfrage: Datei löschen ?
			jsr	FileExist
			cmp	#$00
			bne	:1
			jmp	L220ExitGD

::1			cmp	#$03
			beq	L220c2
			pha
			jsr	DoInfoBox
			pla
			cmp	#$01			;Ja...
			beq	L220c4
			cmp	#$02			;Nein...
			beq	L220c5
			jmp	L220ExitGD

;*** Neuen Namen für Datei eingeben.
:L220c2			MoveW	a7,r0
			jsr	RenDOSFile
			cpx	#$7f
			beq	L220c1
			MoveW	a7,r0
			jsr	ConvertDOS
			jmp	TestFileTab		;Abbruch...

:L220c3			lda	CBM_OverWrite		;Datei automatisch löschen ?
			bne	L220c5			;Nein... Datei übergehen.

;*** Hinweis: "Datei wird gelöscht..."
:L220c4			jsr	ClrBoxText
			PrintStrgV220i6			;Hinweis: "Datei wird gelöscht..."

			lda	#$00			;Datei-Name ausgeben.
::1			pha
			tay
			lda	(a7L),y
			jsr	SmallPutChar
			pla
			add	$01
			cmp	#$0c
			bne	:1
			PrintStrgV220i7

			jsr	DelDOSFile		;DOS-Datei löschen.

			jsr	ClrBoxText
			PrintStrgV220i5
			jmp	ChkNxFile

;*** CBM-Datei übergehen.
:L220c5			jsr	ClrBoxText
			PrintStrgV220i5
			jsr	IgnCBMFile		;CBM-Datei übergehen.
			lda	AnzahlFiles
			bne	ChkFileAgain
			jsr	ClrBox
			jmp	L220ExitGD

;*** Nächste Datei testen.
:ChkNxFile		AddVBW	16,a7			;Zeiger auf nächste Datei
:ChkFileAgain		ldy	#$00			;in File-Tabelle.
			lda	(a7L),y
			beq	:1
			jmp	TestCBMFile

::1			AddVBW	32,a8
			inc	V220b7
			CmpBI	V220b7,16
			beq	:2
			jmp	TestFile

::2			jsr	GetNxDirSek		;Nächsten Directory-Sektor
			cpx	#$00			;lesen.
			bne	FreeDirEntry
			jmp	TestFile

;*** Suche nach freiem Eintrag im Verzeichnis.
:FreeDirEntry		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			LoadB	V220b0,$7f
			ClrB	V220a4

;*** Freie Directory-Einträge suchen.
			jsr	ResetDir
			jmp	L220d1			;Alle Einträge aus Sektor gelesen ?

:L220d0			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			beq	:1
			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			bne	:2			;Ja, ignorieren.
::1			inc	V220a4
			CmpB	V220a4,AnzahlFiles
			bne	:2

			jmp	InitForCopy

::2			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V220b7			;Eintrag.

:L220d1			CmpBI	V220b7,16		;Ende erreicht ?
			bne	L220d0			;Nein, weiter...
			ClrB	V220b7

			jsr	GetNxDirSek		;Directory-Sektor
			cpx	#$00			;lesen.
			beq	L220d0
			lda	V220a0
			bne	L220d2

			ldx	#$47
			jmp	DiskError

;*** Freien Cluster suchen.
:L220d2			LoadW	r2,$0002		;Zeiger auf ersten Cluster.

::1			lda	r2L
			ldx	r2H
			jsr	Get_Clu
			CmpW0	r1			;Ist Cluster frei ?
			beq	:2			;Ja...

			IncWord	r2			;Nein, Zeiger auf nächsten Cluster.
			SubVW	1,Free_Clu
			CmpW0	Free_Clu		;Alle Cluster belegt ?
			bne	:1			;Nein, weiter...

			ldx	#$48			;Disk voll...
			jmp	DiskError

::2			lda	r2L			;Cluster-Nummer merken.
			pha
			sta	r4L
			lda	r2H
			pha
			sta	r4H
			lda	V220b4+0		;Zeiger auf neuen Cluster korrigieren.
			ldx	V220b4+1
			jsr	Set_Clu

			LoadW	r4,$fff8		;Letzten Cluster kennzeichnen.
			pla
			tax
			pla
			jsr	Set_Clu

			lda	r2L			;Cluster löschen.
			ldx	r2H
			jsr	GetSDirClu

			jsr	i_FillRam		;DOS-Puffer löschen.
			w	512,Disk_Sek
			b	$00

			lda	SpClu			;Neuen Cluster auf Diskette schreiben.
::3			pha
			jsr	D_Write
			txa
			beq	:4
			jmp	DiskError		;Disketten-Fehler.

::4			jsr	Inc_Sek
			pla
			sub	$01
			bne	:3

			lda	V220b4+0		;Zeiger auf neuen Cluster korrigieren.
			ldx	V220b4+1
			jsr	Clu_Sek

			LoadB	BAM_Modify,$ff
			jmp	L220d0

;*** Dateien kopieren.
:InitForCopy		jsr	ClrBoxText
			PrintStrgV220i8

			jsr	Save_FAT
			jsr	ClrBox

			jsr	SetGEOSDate

			lda	AnzahlFiles
			bne	:1
			jmp	L220ExitGD

::1			SetColRam1000,0,$00

			LoadW	r0,V220z0		;Tabelle verschieben.
			LoadW	r1,SCREEN_BASE
			LoadW	r2,V220z3-V220z0
			jsr	MoveData

			lda	CBMCopyMode
			bne	:2
			jmp	m_copyCBMtoDOS		;Kopieren.
::2			jmp	m_copyGWtoDOS

;*** Fehlermeldungen.
:NoFiles		LoadW	r0,V220h0		;Keine Files.
			jmp	L220Error
:NoDOSClu		LoadW	r0,V220h3		;Zu wenig freie Cluster.
			jmp	L220Error
:NoDOSByt		LoadW	r0,V220h3		;Zu wenig freie Bytes.
			jmp	L220Error

:L220Error		ClrDlgBoxCSet_Grau
			jmp	L220ExitGD

;*** Window beenden.
:L220ExitW		LoadB	sysDBData,2
			jmp	RstrFrmDialogue

;*** Farben zurücksetzen..
:L220RVec		PushB	r2L
			jsr	i_FillRam
			w	24,COLOR_MATRIX+6*40+8
			b	$b1
			PopB	r2L
			rts

;*** Farben setzen und Titel ausgeben.
:L220Col_1		jsr	i_FillRam
			w	23,COLOR_MATRIX+6*40+9
			b	$61

			lda	#$01
			jsr	SetPattern
			jsr	i_Rectangle
			b	48,55
			w	72,255

			jsr	UseGDFont
			PrintXY	80,54,V220f1
			jsr	UseSystemFont
			PrintXY	80,68,V220f6
			LoadW	r0,V220d1
			jsr	PutString
			rts

;*** Aktuelle Eingabe löschen.
:No_Name		ClrB	InpNamBuf
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Aktuelle Eingabe löschen.
:DOS_Name		LoadW	r0,InpNamBuf
			jsr	ConvertDOS
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Unterverzeichnisse einlesen.
:GetDirEntry		jsr	DoInfoBox
			PrintStrgV220i1

			lda	#$00
			sta	V220a1			;Zähler Directorys.
			sta	V220a2			;Zähler Einträge.
			LoadW	a7,V220z1		;Zeiger auf Datei-Tabelle.

;*** Verzeichnisse einlesen.
:RdDOSFiles		jsr	ResetDir
			jmp	:3			;Alle Einträge aus Sektor gelesen ?

::1			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			beq	:4
			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:2			;Ja, ignorieren.

			ldy	#$0b
			lda	(a8L),y
			and	#%00010000		;Eintrag = Verzeichnis ?
			beq	:2			;Ja, Kein Cluster-Test.

			inc	V220a1			;Zähler Anzahl Directorys erhöhen.
			jsr	CopyName
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			bne	:5			;Ja, weiter...

::2			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V220b7			;Eintrag.
::3			CmpBI	V220b7,16		;Ende erreicht ?
			bne	:1			;Nein, weiter...
			ClrB	V220b7

			jsr	GetNxDirSek		;Directory-Sektor
			cpx	#$00			;lesen.
			beq	:1

			lda	#$ff
			b $2c
::4			lda	#$00
			sta	V220b15
::5			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			jsr	ClrBox
			rts

;*** Dateiname in Tabelle übertragen.
:CopyName		lda	#$00			;Zeiger initialisieren.
			sta	:1 +1
			sta	:2 +1

::1			ldy	#$00			;Directory-Name
			lda	(a8L),y			;übertragen.
			inc	:1 +1
::2			ldy	#$00
			sta	(a7L),y
			inc	:2 +1
			lda	#$20
			cpy	#$07
			beq	:2
			cpy	#$0b
			bne	:1

;*** Start-Cluster in Tabelle übertragen.
			ldy	#$1a			;Cluster aus Eintrag
			lda	(a8L),y			;lesen.
			pha
			iny
			lda	(a8L),y
			ldy	#$0f			;In Tabelle kopieren.
			sta	(a7L),y
			dey
			pla
			sta	(a7L),y

			AddVBW	16,a7			;Zeiger auf den
			inc	V220a2			;nächsten Eintrag.
			CmpBI	V220a2,255		;Tabelle voll ?
			beq	:3			;Ja, ende...

			lda	#$00			;Nein, weiter...
			rts

::3			lda	#$ff
			rts

;*** Directory initialisieren.
:ResetDir		ldy	V220b0
			bne	:3

			ldy	V220a0			;Zeiger auf Anfang Directory setzen.
			bne	:1

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			MoveW	MdrSektor,V220a3
			jmp	:2

::1			lda	V220b2+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V220b2+1
			sta	V220b4+0
			stx	V220b4+1
			jsr	Clu_Sek

::2			MoveB	Seite ,V220b1+0		;Startposition merken.
			MoveB	Spur  ,V220b1+1
			MoveB	Sektor,V220b1+2
			MoveB	V220a3,V220b5
			MoveB	SpClu ,V220b6
			lda	#$00
			sta	V220b7
			sta	V220b15
			lda	#<Disk_Sek
			sta	a8L
			sta	V220b8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V220b8+1
			jsr	D_Read
			txa
			bne	:2a
			jmp	SaveDirPos
::2a			jmp	DiskError

::3			cpy	#$7f
			bne	:4

			jsr	LoadDirPos		;Directory-Zeiger wieder setzen.
			MoveB	V220b1+0,Seite
			MoveB	V220b1+1,Spur
			MoveB	V220b1+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			bne	:2a
			MoveW	V220b8,a8
			ClrB	V220b15
			rts

::4			jsr	SaveDirPos		;Directory weiterlsen.
			MoveB	V220b1+0,Seite
			MoveB	V220b1+1,Spur
			MoveB	V220b1+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			bne	:2a
			MoveW	V220b8,a8
			rts

;*** Zeiger auf aktuelle Directory-Position wieder herstellen.
:LoadDirPos		ldy	#$09
::1			lda	V220b9,y
			sta	V220b3,y
			dey
			bpl	:1
			rts

;*** Zeiger auf aktuelle Directory-Position sichern.
:SaveDirPos		ldy	#$09
::1			lda	V220b3,y
			sta	V220b9,y
			dey
			bpl	:1
			rts

;*** Nächsten Sektor lesen.
:GetNxDirSek		LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			lda	V220b15			;Directory-Ende ?
			bne	:2			;Ja, Ende...

			lda	V220a0			;Hauptverzeichnis ?
			bne	:3			;Nein, weiter...

			CmpBI	V220b5,1		;Alle Sektoren
			beq	:2			;gelesen ?

			dec	V220b5			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			jsr	D_Read			;Sektor lesen.
			txa
			beq	:1
			jmp	DiskError		;Disketten-Fehler.

::1			ldx	#$00			;OK...
			b	$2c
::2			ldx	#$ff			;Directory-Ende...
			stx	V220b15
			rts

::3			CmpBI	V220b6,1		;Alle Sektoren
			beq	:5			;gelesen ?

			dec	V220b6			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			jsr	D_Read
			txa
			beq	:4
			jmp	DiskError		;Disketten-Fehler.

::4			rts

::5			lda	V220b4+0		;Nächsten Cluster lesen.
			ldx	V220b4+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H

;*** Cluster Einlesen.
:GetSDirClu		ldy	FAT_Typ
			bne	:1

			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$0f
			bcc	:2
			ldx	#$ff
			bne	:4			;Ja, Ende...

::1			cmp	#$f8			;FAT16. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$ff
			bne	:2
			ldx	#$ff
			bne	:4			;Ja, Ende...

::2			sta	V220b4+0
			stx	V220b4+1
			jsr	Clu_Sek			;Cluster berechnen.
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			beq	:3
			jmp	DiskError		;Disketten-Fehler.

::3			MoveB	SpClu,V220b6		;Zähler setzen.

			ldx	#$00
::4			stx	V220b15
			rts				;Ende...

;*** Datum der Dateien auf GEOS-Standard-Zeit setzen.
:SetGEOSDate		lda	CBM_Datum
			bne	:1
			rts

::1			LoadW	a6,V220z1		;Tabelle Datei-Namen.
			LoadW	a7,V220z2		;Tabelle Datei-Namen.

			ldx	#$04			;Datei-Datum, -Uhrzeit, -Größe.
::2			lda	year,x
			sta	r2L,x
			dex
			bpl	:2
			jsr	SetDate			;DOS-Datum erzeugen.

::3			ldy	#$03
::4			lda	r0,y
			sta	(a7L),y
			dey
			bpl	:4

			AddVBW	16,a6			;Zeiger auf nächste CBM-Datei.
			AddVBW	8 ,a7

			ldy	#$00
			lda	(a6L),y			;Ende erreicht ?
			bne	:3			;Nein, weiter...
			rts

;*** DOS-Datum generieren.
:SetDate		lda	r3H
			asl
			asl
			asl
			ldx	#$05
::3			asl
			rol	r0L
			rol	r0H
			dex
			bne	:3

			lda	r4L
			asl
			asl
			ldx	#$06
::4			asl
			rol	r0L
			rol	r0H
			dex
			bne	:4

			ldx	#$05
::5			asl	r0L
			rol	r0H
			dex
			bne	:5

			sec
			lda	r2L
			sbc	#80
			bcs	:51
			adc	#100
::51			asl
			ldx	#$07
::6			asl
			rol	r1L
			rol	r1H
			dex
			bne	:6

			lda	r2H
			asl
			asl
			asl
			asl
			ldx	#$04
::7			asl
			rol	r1L
			rol	r1H
			dex
			bne	:7

			lda	r3L
			asl
			asl
			asl
			ldx	#$05
::8			asl
			rol	r1L
			rol	r1H
			dex
			bne	:8

			rts

;*** Vorhandene DOS-Datei löschen.
:DelDOSFile		ldy	#$00			;Datei-Name löschen.
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

::7			lda	r1L			;Zeiger auf aktuellen Cluster
			ldx	r1H
			cmp	#$00
			bne	:8
			cpx	#$00
			beq	:9
::8			jsr	Get_Clu			;Link auf nächsten Cluster lesen.
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
			bne	:7
			cpy	#$f8
			bcc	:7
::9			LoadB	BAM_Modify,$ff
			rts

;*** CBM-Datei ignorieren.
:IgnCBMFile		MoveW	a7,a5

::1			clc
			lda	a5L
			sta	a6L
			adc	#$10
			sta	a5L
			lda	a5H
			sta	a6H
			adc	#$00
			sta	a5H

			ldy	#$0f
::2			lda	(a5L),y
			sta	(a6L),y
			dey
			bpl	:2
			ldy	#$00
			lda	(a5L),y
			bne	:1
			dec	AnzahlFiles
			rts

;*** Variablen: Lesen des DOS-Directory.
:CBMCopyMode		b $00				;$FF = geoWrite nach DOS.

:V220a0			b $00				;Directory-Typ.
:V220a1			b $00				;Anzahl Directorys.
:V220a2			b $00				;Anzahl Einträge.
:V220a3			w $0000				;Anzahl Sektoren im Hauptverzeichnis
:V220a4			b $00				;Anzahl freie Einträge im Directory.

;*** Variablen: Lesen des DOS-Directory.
:V220b0			b $00				;$00 = Ersten Dir-Sektor ermitteln.
							;$7F = Startwerte auf ersten Directory-Sektor.
							;$FF = Directory weiterlesen.
:V220b1			s $03				;Startadresse Directory (Sektor)
:V220b2			w $0000				;       "               (Cluster)
:V220b3			s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V220b4			w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V220b5			b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V220b6			b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V220b7			b $00				;Zähler Einträge in Sektor.
:V220b8			w $0000				;Zeiger auf Anfang Eintrag in Sektor.
:V220b9			s $03				;Startadresse aktive Datei-Tabelle (Sektor)
:V220b10		w $0000				;       "                          (Cluster)
:V220b11		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V220b12		b $00				;Zwischenspeicher: Zeiger auf Sektor in Cluster.
:V220b13		b $00				;Zwischenspeicher: Zähler Einträge in Sektor.
:V220b14		w $0000				;Zwischenspeicher: Zeiger auf Eintrag in Sektor.

:V220b15		b $00				;$FF = Directory-Ende.

;*** Variablen: Einlesen des CBM-Directory.
:V220c0			w $0000				;Anzahl CBM-Files.
:V220c1			b "Write Image ",NULL

;*** Variablen:
:V220d0			b $00				;Flag für "BAM verändert"
:V220d1			s $11				;Zwischenspeicher Dateiname.
:V220d2			w $0000				;Zwischenspeicher Zeiger auf Datei-Name.

;*** Variablen: Berechnung freier Speicher auf Ziel-Disk.
:V220e0			w $0000				;Zähler für Cluster.
:V220e1			w $0000				;Zähler für freie Cluster.
:V220e2			w $0000				;Anzahl Cluster.
:V220e3			w $0000				;Anzahl Bytes pro Cluster.
:V220e4			w $0000				;Anzahl benötigte Cluster für CBM-Files.

;*** Dialogbox: Eingabe DOS-Datei-Name.
:V220f0			b $01
			b 48,135
			w 64,255

			b CANCEL     , 16, 64
			b DBUSRICON  ,  0,  0
			w V220f3
			b DBUSRICON  ,  2, 64
			w V220f4
			b DBUSRICON  , 10, 64
			w V220f5
			b DB_USR_ROUT
			w L220Col_1
			b DBGRPHSTR
			w V220f2
			b DBGETSTRING, 20, 32
			b r10L,12
			b NULL

:V220f1			b PLAINTEXT,REV_ON
			b "MSDOS-Datei-Name ändern",PLAINTEXT,NULL

:V220f2			b MOVEPENTO
			w 80
			b 77
			b FRAME_RECTO
			w 239
			b 92
			b NULL

:V220f3			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L220ExitW

:V220f4			w icon_None
			b $00,$00
			b icon_None_x,icon_None_y
			w No_Name

:V220f5			w icon_DOS
			b $00,$00
			b icon_DOS_x,icon_DOS_y
			w DOS_Name

:V220f6			b PLAINTEXT,BOLDON
			b "CBM-Datei: ",NULL

:InpNamBuf		s 17

:icon_None
<MISSING_IMAGE_DATA>
:icon_None_x		= .x
:icon_None_y		= .y

:icon_DOS
<MISSING_IMAGE_DATA>
:icon_DOS_x		= .x
:icon_DOS_y		= .y

;*** Titel für Auswahlboxen.
:V220g0			b PLAINTEXT,REV_ON
			b "Ziel-Verzeichnis",PLAINTEXT,NULL
:V220g1			b PLAINTEXT,REV_ON
			b "Dateien wählen",PLAINTEXT,NULL
:V220g2			b PLAINTEXT,REV_ON
			b "geoWrite-Dokumente",PLAINTEXT,NULL

;*** Fehler: "Keine Dateien auf Disk!"
:V220h0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V220h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V220h2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V220h1			b PLAINTEXT,BOLDON
			b "Keine Dateien auf",NULL
:V220h2			b "Diskette !",PLAINTEXT,NULL

;*** Fehler: "Nicht genügend freie Cluster auf Ziel-Disk!"
:V220h3			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V220h4
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V220h5
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V220h4			b PLAINTEXT,BOLDON
			b "Nicht genügend freie",NULL
:V220h5			b "Cluster auf Ziel-Disk!",PLAINTEXT,NULL

;*** Fehler: "Nicht genügend freier Speicher auf Ziel-Disk!"
:V220h6			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V220h7
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V220h8
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V220h7			b PLAINTEXT,BOLDON
			b "Nicht genügend freier",NULL
:V220h8			b "Speicher auf Ziel-Disk!",PLAINTEXT,NULL

;*** Fehler: "Datei-Name bereits vergeben!"
:V220h9			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V220h10
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V220h11
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V220h10		b PLAINTEXT,BOLDON
			b "Gewählter Datei-Name",NULL
:V220h11		b "ist bereits vergeben!",PLAINTEXT,NULL

;*** Info: "Disketten-Daten werden eingelesen!"
:V220i0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Daten"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Suche weitere Unterverzeichnisse..."
:V220i1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche weitere"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Unterverzeichnisse..."
			b NULL

;*** Info: "Suche Dateien..."
:V220i2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche Dateien..."
			b NULL

;*** Info: "Datei-Informationen..."
:V220i3			b PLAINTEXT,BOLDON
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
:V220i4			b PLAINTEXT,BOLDON
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
:V220i5			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Überprüfe das"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Ziel-Verzeichnis..."
			b NULL

;*** Hinweis "Datei: ... wird gelöscht!"
:V220i6			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei: "
			b NULL

:V220i7			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gelöscht..."
			b NULL

;*** Info: "Verzeichnis wird aktualisiert..."
:V220i8			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Verzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL

;*** Konvertierungstabelle
:V220z0			b $00,$01,$02,$03,$04,$05,$06,$07
			b $08,$09,$0a,$0b,$0c,$0d,$0e,$0f
			b $10,$11,$12,$13,$14,$15,$16,$17
			b $18,$19,$1a,$1b,$1c,$1d,$1e,$1f
			b $20,$21,$22,$23,$24,$25,$26,$27
			b $28,$29,$2a,$2b,$2c,$2d,$2e,$2f
			b $30,$31,$32,$33,$34,$35,$36,$37
			b $38,$39,$3a,$3b,$3c,$3d,$3e,$3f
			b $40,$41,$42,$43,$44,$45,$46,$47
			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
			b $50,$51,$52,$53,$54,$55,$56,$57
			b $58,$59,$5a,$5b,$5c,$5d,$5e,$5f
			b $60,$61,$62,$63,$64,$65,$66,$67
			b $68,$69,$6a,$6b,$6c,$6d,$6e,$6f
			b $70,$71,$72,$73,$74,$75,$76,$77
			b $78,$79,$7a,$7b,$7c,$7d,$7e,$7f
			b $80,$81,$82,$83,$84,$85,$86,$87
			b $88,$89,$8a,$8b,$8c,$8d,$8e,$8f
			b $90,$91,$92,$93,$94,$95,$96,$97
			b $98,$99,$9a,$9b,$9c,$9d,$9e,$9f
			b $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7
			b $a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
			b $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7
			b $b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
			b $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7
			b $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
			b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7
			b $d8,$d9,$da,$db,$dc,$dd,$de,$df
			b $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7
			b $e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef
			b $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7
			b $f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff

;*** Speicher für Datei-Namen-Tabelle.
:V220z1

;*** Speicher für Datumstabelle & Datei-Grö								ße.
:V220z2			= V220z1 + 16*256

;*** Speicher für Auswahl Konvertierungstabelle.
:V220z3			= V220z2 + 8*256
