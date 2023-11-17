; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L210: Datei von MS-DOS nach CBM kopieren
:ConvTabBase		= SCREEN_BASE
:File_Name		= SCREEN_BASE +256
:File_Datum		= File_Name   +256*16

:DOS_Datum		= CopyOptions +0
:DOS_OverWrite		= CopyOptions +1
:DOS_CBMType		= OptDOStoCBM +0
:DOS_LfCode		= OptDOStoCBM +1

;*** Ende. Zurück zu geoDOS.
:L210ExitGD		jmp	InitScreen		;Ende...

;*** Datei von MS-DOS nach CBM kopieren
:DOStoCBM		stx	DOSCopyMode		;Kopier-Modus merken.
			jsr	InitGWCopy		;geoWrite-Variablen initialisieren.

			lda	Source_Drv		;Source-Drive aktivieren.
			jsr	NewDrive

			lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			jmp	SetMenu

::1			jsr	DoInfoBox
			PrintStrgV210i0

			jsr	GetBSek			;Boot-Sektor lesen.
			jsr	Load_FAT		;FAT einlesen.

			jsr	ClrBox

;*** Dialogbox aufbauen, Dateien wählen.
:DoFileBox		lda	#$00
			sta	V210a0			;Einsprung: Neustart+Hauptverzeichnis.
			sta	V210d0			;Einsprung: Weiterlesen des Directory.

;*** Dateien einlesen..
:ReadDir		jsr	i_FillRam		;Speicher löschen.
			w	$7fff-V210z1
			w	V210z1
			b	$00

			jsr	GetDir			;Einträge einlesen.
			jsr	ClrBox

			lda	V210a3			;Anzahl Dateien = 0 ?
			beq	:1			;Nein, weiter...
			jmp	ShowDlgBox

::1			LoadW	r0,V210h0		;Ja, Meldung ausgeben...
			ClrDlgBoxCSet_Grau

			jmp	L210ExitGD

;*** geoWrite-Copy initialisieren.
:InitGWCopy		ldx	DOSCopyMode		;DOS nach geoWrite kopieren ?
			bne	:1			;Ja, weiter.
			rts

::1			lda	#<$02f0			;Standard-Seitenlänge.
			sta	OptDOStoGW+4
			lda	#>$02f0
			sta	OptDOStoGW+5

			jsr	GetStartDrv		;Startlaufwerk aktivieren.
			txa
			beq	:3
::2			jmp	DiskError		;Disketten-Fehler.

::3			LoadW	r6,PrntFileName
			jsr	FindFile		;Drucker-Treiber suchen.
			txa
			beq	:4
			cpx	#$05
			bne	:2
			jmp	:5

::4			LoadW	r6,PrntFileName
			LoadB	r0L,%00000001
			LoadW	r7,PRINTBASE
			jsr	GetFile			;Drucker-Treiber laden.
			txa
			bne	:2
			jsr	GetDimensions		;Seitenlänge einlesen.
			ClrB	OptDOStoGW+5
			tya
			asl
			rol	OptDOStoGW+5
			asl
			rol	OptDOStoGW+5
			asl
			rol	OptDOStoGW+5
			sta	OptDOStoGW+4

::5			jsr	GetWorkDrv		;Konfiguration wieder herstellen.
			txa
			beq	:6
			jmp	DiskError

::6			rts				;Ende.

;*** SubDirectorys einlesen.
:GetDir			jsr	DoInfoBox
			PrintStrgV210i1

			lda	Source_Drv		;Quell-Laufwerk aktivieren.
			jsr	NewDrive

			lda	#$00
			sta	V210a1			;Zähler Directorys.
			sta	V210a2			;Zähler Dateien.
			sta	V210a3			;Zähler Einträge.

			LoadW	a6,V210z2
			LoadW	a7,V210z1		;Zeiger auf Datei-Tabelle.

			lda	#%00010000		;Directory-Eintrag in Tabelle
			ldy	#$00			;kopieren.
			jsr	ReadEntry
			cmp	#$00
			bne	:1

			jsr	ClrBoxText
			PrintStrgV210i2

			LoadB	V210d0,$7f
			lda	#%00000000		;Directory-Eintrag in Tabelle
			ldy	#$01			;kopieren.
			jsr	ReadEntry
::1			rts

;*** Dateien & Directorys einlesen.
:ReadEntry		sta	:1  +1
			sty	:2a +1

			jsr	ResetDir
			jmp	:4			;Alle Einträge aus Sektor gelesen ?

::1			lda	#%00000000		;Einträge lesen.
			jsr	TestName
			cmp	#$00			;$00 = Verzeichnis-Ende ?
			bne	:2			;Ja, Ende...
			LoadB	V210d15,$ff
			jmp	:5

::2			cmp	#$ff			;$FF = Ungültiger Eintrag ?
			beq	:3			;Ja, überspringen...

::2a			ldx	#$ff			;Directory-Eintrag in Tabelle
			jsr	CopyName		;kopieren.
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			beq	:3			;Ja, weiter...

			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			lda	#$ff
			rts				;Ende...

::3			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V210d7			;Eintrag.
::4			CmpBI	V210d7,16		;Ende erreicht ?
			bne	:1			;Nein, weiter...
			ClrB	V210d7

			jsr	GetNxDirSek		;Directory-Sektor
			cpx	#$00			;lesen.
			beq	:1
			LoadB	V210d15,$ff

::5			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			rts				;Ende...

;*** Datei-Namen testen.
:TestName		sta	:2 +1			;Datei-Maske merken.

			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			bne	:1
			rts				;Ja, Ende.

::1			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:4			;Ja, ignorieren.

			ldy	#$0b
			lda	(a8L),y
			and	#%00010000		;Datei = gewünschtes
::2			cmp	#%00000000		;Dateiformat ?
			bne	:4

			cmp	#%00010000		;Verzeichniss ?
			beq	:3			;Ja, Kein Cl.-Test.

			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y			;Ja, keine Datei.
			bne	:3
			iny
			lda	(a8L),y
			beq	:4

::3			lda	#$7f			;Gültiger Eintrag.
			b	$2c
::4			lda	#$ff			;Ungültiger Eintrag.
			rts

;*** Dateiname in Tabelle übertragen.
:CopyName		inc	V210a1,x		;Zähler erhöhen.

			lda	#" "
			cpx	#$00
			beq	:0
			lda	#"."
::0			sta	:6 +1

			lda	#$00			;Zeiger initialisieren.
			sta	:1 +1
			sta	:5 +1

::1			ldy	#$00			;Datei-Name in Speicher kopieren und
			lda	(a8L),y			;in CBM-Format konvertieren.
			cmp	#" "
			bcs	:3
::2			lda	#"_"
			bne	:4
::3			cmp	#$7f
			bcs	:2
::4			inc	:1 +1
::5			ldy	#$00
			sta	(a7L),y
			inc	:5 +1
::6			lda	#"."
			cpy	#$07
			beq	:5
			cpy	#$0b
			bne	:1

			lda	#$00
::7			iny
			sta	(a7L),y
			cpy	#$0f
			bne	:7

			lda	V210a3
			sta	(a7L),y

			ldx	#$00
			lda	#$16
::8			pha
			tay
			lda	(a8L),y
			pha
			txa
			tay
			pla
			sta	(a6L),y
			inx
			pla
			add	$01
			cmp	#$1f
			bne	:8

			AddVBW	 9,a6
			AddVBW	16,a7			;Zeiger auf den

			inc	V210a3			;nächsten Eintrag.
			CmpBI	V210a3,255		;Tabelle voll ?
			beq	:9			;Ja, ende...

			lda	#$00			;Nein, weiter...
			rts
::9			lda	#$ff
			rts

;*** Zeiger auf Eintrag positionieren.
:SetPosEntry		sta	r0L
			LoadB	r1L,9
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			AddVW	V210z2,r0
			rts

;*** Datei-Auswahl-Box.
:ShowDlgBox		MoveB	Seite,V210d3+0		;Sektorwerte merken.
			MoveB	Spur,V210d3+1
			MoveB	Sektor,V210d3+2
			MoveW	a8,V210d8

			LoadW	r14,V210g0		;Dateien wählen.
			LoadW	r15,V210z1
			lda	#$ff
			ldx	#$0c
			ldy	V210a1
			jsr	DoScrTab

			ldy	sysDBData		;Ergebiss prüfen.
			cpy	#$02			;"Abbruch" ?
			beq	:4			;Ja, Ende...
			cmp	#$ff			;Datei-Auswahl ?
			beq	:1			;Ja, weiter...

			jsr	SlctSubDir
			jmp	ReadDir			;Box aufbauen.

::1			cpx	#$00			;Dateien ausgewählt ?
			beq	:2
			jmp	GetFileData		;Ja, kopieren.

::2			CmpBI	V210d15,$ff		;Dir-Ende erreicht ?
			beq	:3			;Ja, zum Anfang.

			LoadB	V210d0,$ff
			jmp	ReadDir			;Directory weiterlesen.

::3			LoadB	V210d0,$00
			jmp	ReadDir			;Zum Directory-Anfang.

::4			jmp	L210ExitGD

;*** SubDir auswählen.
:SlctSubDir		ldy	#$0f
			lda	(r15L),y
			jsr	SetPosEntry

			ldy	#$04			;Cluster = 0 ?
			lda	(r0L),y
			bne	:1
			iny
			lda	(r0L),y
			bne	:1			;Nein -> SubDir.
			sta	V210a0			;$00 im Akku,
			sta	V210d0
			rts

::1			ldy	#$04			;Cluster-Nr. setzen.
			lda	(r0L),y
			sta	V210d2+0
			iny
			lda	(r0L),y
			sta	V210d2+1
			LoadB	V210a0,1		;Sub-Directory
			ClrB	V210d0
			rts

;*** Daten für ausgewählte Dateien sortieren.
:GetFileData		stx	AnzahlFiles		;Anzahl Dateien merken.

			lda	Target_Drv		;Target-Drive aktivieren.
			jsr	NewDrive
			jsr	OpenDisk
			txa
			beq	:1
			jmp	DiskError

::1			LoadW	a6,V210z1
			LoadW	a7,V210z2

::2			ldy	#$0f
			lda	(a6L),y
			jsr	SetPosEntry

			ldy	#$08
::3			lda	(r0L),y
			sta	(a7L),y
			dey
			bpl	:3

			AddVBW	16,a6
			AddVBW	 9,a7

			ldy	#$00
			lda	(a6L),y
			bne	:2

			jsr	CalcDOSBlks
			cpx	#$00
			beq	GetConvTab

;*** Fehler-Meldung: "Nicht genügend Speicher auf Ziel!"
:NoDiskSpace		LoadW	r0,V210h3
			ClrDlgBoxCSet_Grau
			jmp	ReadDir

;*** Konvertierungstabelle laden.
:GetConvTab		jsr	ClrBox
			lda	CTabDOStoCBM
			beq	TestFiles

			jsr	GetStartDrv		;geoDOS-Laufwerk aktivieren.
			txa
			beq	:2
::1			jmp	GDDiskError

::2			LoadW	r6,CTabDOStoCBM
			LoadW	r7,V210z0
			LoadB	r0L,%00000001
			jsr	GetFile			;Tabelle in Speicher einlesen.
			txa
			bne	:1
			jsr	GetWorkDrv		;Arbeits-Laufwerk aktivieren.

;*** Datei-Namen testen.
:TestFiles		LoadW	a6,V210z1		;Zeiger auf File-Tabelle.
			LoadW	a7,V210z2
			lda	LinkFiles
			beq	:0
			jmp	:8

::0			jsr	DoInfoBox		;Info: "Überprüfe Ziel-Verzeichnis..."
			PrintStrgV210i3

::1			ldy	#$00
::2			lda	(a6L),y			;Name kopieren.
			beq	:3
			sta	V210b0,y
			iny
			cpy	#$10
			bne	:2
::3			lda	#$00			;Punkt als Trennung in Datei-Name
			sta	V210b0,y		;einfügen.

			LoadW	r6,V210b0		;Datei auf dem Ziel-Laufwerk suchen.
			jsr	FindFile
			cpx	#$00
			beq	:5
			cpx	#$05			;"FILE NOT FOUND" aufgetreten ?
			beq	:4
			jmp	DiskError
::4			jmp	:13

::5			lda	DOS_OverWrite		;Datei bereits vorhanden.
			bpl	:10
			jsr	ClrBox
::6			LoadW	r15,V210b0		;Abfrage: Datei löschen ?
			jsr	FileExist
			cmp	#$00
			bne	:7
			jmp	L210ExitGD

::7			cmp	#$03
			beq	:8
			pha
			jsr	DoInfoBox
			pla
			cmp	#$01			;Ja...
			beq	:11
			cmp	#$02			;Nein...
			beq	:12
			jmp	L210ExitGD		;Abbruch...

;*** Neuen Namen für Datei eingeben.
::8			MoveW	a6,r0
			jsr	RenCBMFile
			cpx	#$7f
			beq	:6

			ldy	#$0f
::9			lda	V210e0,y
			sta	(a6L),y
			dey
			bpl	:9

			jmp	:0			;Abbruch...

::10			lda	DOS_OverWrite		;Datei bereits vorhanden.
			bne	:12

::11			jsr	DelCBMFile
			jmp	:13

::12			jsr	IgnDOSFile
			jmp	:14

::13			AddVBW	16,a6			;Zeiger auf nächsten Datei-Namen.
			AddVBW	 9,a7

::14			lda	a6L
			cmp	#<V210z1
			beq	:15
			lda	LinkFiles
			bne	:16

::15			ldy	#$00			;Tabellen-Ende erreicht ?
			lda	(a6L),y
			bne	:17
::16			jmp	InitForCopy

::17			jmp	:1

;*** CBM-Datei löschen.
:DelCBMFile		jsr	ClrBoxText
			PrintStrgV210i4			;Info: "Datei wird gelöscht..."
			PrintStrgV210b0

			LoadW	r0,V210b0		;CBM-Datei löschen.
			jsr	DeleteFile
			txa
			beq	:1
			jmp	DiskError

::1			jsr	ClrBoxText		;Info: "Prüfe Ziel-Verzeichnis..."
			PrintStrgV210i3
			rts

;*** DOS-Datei ignorieren.
:IgnDOSFile		jsr	ClrBoxText
			PrintStrgV210i3

			MoveW	a6,r0
			MoveW	a7,r2

::1			clc				;Zeiger auf nächsten Datei-Namen.
			lda	r0L
			sta	r1L
			adc	#$10
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#$00
			sta	r0H

			clc				;Zeiger auf nächste Datei-Daten.
			lda	r2L
			sta	r3L
			adc	#$09
			sta	r2L
			lda	r2H
			sta	r3H
			adc	#$00
			sta	r2H

			ldy	#$0f
::2			lda	(r0L),y
			sta	(r1L),y
			dey
			bpl	:2

			ldy	#$08
::3			lda	(r2L),y
			sta	(r3L),y
			dey
			bpl	:3

			ldy	#$00
			lda	(r1L),y
			bne	:1

			dec	AnzahlFiles		;Anzahl Dateien -1.
			beq	:4
			rts

::4			jsr	ClrBox			;Keine Dateien mehr im Speicher.
			jmp	L210ExitGD

;*** Dateien kopieren.
:InitForCopy		jsr	ClrBox
			lda	AnzahlFiles
			bne	:1
			jmp	L210ExitGD

::1			SetColRam1000,0,$00

			jsr	i_MoveData
			w	V210z0			;Tabelle verschieben.
			w	SCREEN_BASE
			w	V210z3-V210z0

			lda	DOSCopyMode
			bne	:2

			jmp	m_copyDOStoCBM
::2			jmp	m_copyDOStoGW

;*** Einzel-Datei umbenennen.
:RenCBMFile		MoveW	r0,V210e1		;Zeiger auf Datei-Name speichern.

:InitRename		ldy	#$0f			;CBM-Datei-Name in Puffer kopieren.
::1			lda	(r0L),y
			sta	V210e0,y
			dey
			bpl	:1

			jsr	i_FillRam		;Eingabe-Puffer löschen.
			w	17,InpNamBuf
			b	$00

::2			LoadW	r10,InpNamBuf		;Dialogbox zur Eingabe des neuen
			LoadW	r0,V210f0		;Datei-Namens.
			ClrDlgBoxL210RVec

			lda	sysDBData
			cmp	#$ff			;Name nochmals eingeben.
			beq	:2
			cmp	#$02			;Abbruch ?
			bne	:4			;Nein, Name übernehmen.
::3			ldx	#$7f			;Ja, Abbruch.
			rts

::4			lda	InpNamBuf		;Leeres Eingabefeld ?
			beq	:3			;Ja, Abbruch.

::5			ldy	#$00			;Name aus Eingabepuffer in
::6			lda	InpNamBuf,y		;Übergabepuffer kopieren.
			beq	:7
			sta	V210e0,y
			iny
			cpy	#$10
			bne	:6
::7			lda	#$00
::8			sta	V210e0,y
			iny
			cpy	#$11
			bne	:8

			LoadW	r0,V210z1		;Prüfen ob Name bereits vergeben.

::9			ldy	#$00
			lda	(r0L),y			;Ende der Tabelle erreicht ?
			beq	:12			;Ja, Name OK!
::10			lda	(r0L),y			;Name aus Tabelle mit
			cmp	V210e0,y		;eingegebenem Namen vergleichen.
			bne	:11			;Unterschiedlich, nächster Name.
			iny
			cpy	#$10
			bne	:10

			LoadW	r0,V210f7		;Fehler: "Name vorhanden!"
			ClrDlgBoxCSet_Grau
			MoveW	V210e1,r0
			jmp	InitRename

::11			AddVBW	16,r0			;Zeiger auf nächsten Namen
			jmp	:9			;Tabelle.

::12			ldx	#$00			;Name OK!
			rts

;*** Farben zurücksetzen..
:L210RVec		PushB	r2L
			jsr	i_FillRam
			w	24,COLOR_MATRIX+6*40+8
			b	$b1
			PopB	r2L
			rts

;*** Farben setzen und Titel ausgeben.
:L210Col_1		jsr	i_FillRam
			w	23,COLOR_MATRIX+6*40+9
			b	$61

			Pattern	1
			FillRec	48,55,72,255

			jsr	UseGDFont
			PrintXY	80,54,V210f1
			jsr	UseSystemFont
			PrintXY	80,68,V210f6
			LoadW	r0,V210e0
			jmp	PutString

;*** Window beenden.
:L210ExitW		LoadB	sysDBData,2
			jmp	RstrFrmDialogue

;*** Aktuelle Eingabe löschen.
:No_Name		ClrB	InpNamBuf
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Aktuelle Eingabe löschen.
:CBM_Name		ldy	#$10
::1			lda	V210e0,y
			sta	InpNamBuf,y
			dey
			bpl	:1
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Datei-Tabelle prüfen...
:CalcDOSBlks		LoadW	a6,V210z1
			LoadW	a7,V210z2
			ClrW	V210c0

::1			ldy	#$00
			lda	(a6L),y			;Datei-Ende erreicht ?
			bne	:2			;Nein, DOS-Datei-Länge addieren.
			jmp	ChkDskBlkFree		;Freien Speicher auf Ziel-Disk testen.

::2			jsr	InitForBA		;Dateilänge berechnen.
			lda	#<V210c1
			ldy	#>V210c1
			jsr	MOVMA
			ldy	#$08
			lda	(a7L),y
			ldx	#$00
			jsr	Word_FAC
			jsr	x_MULT			;High-Byte * 65536.
			jsr	MOVFA
			ldy	#$07
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jsr	Word_FAC
			jsr	ADDFAC			;FAC: = FAC + Middle- & Low-Byte.
			jsr	MOVFA
			lda	#<V210c2
			ldy	#>V210c2
			jsr	MOVMF
			jsr	x_DIVAF			;FAC: = FAC / 254.
			ldx	#<V210c3
			ldy	#>V210c3
			jsr	MOVFM			;FAC: in Speicher verschieben und
			jsr	FACWRD			;in 2-Byte-Integer wandeln.
			AddW	r9,V210c0		;Gesamt-Summe addieren.
			lda	r9L
			ldx	r9H
			jsr	Word_FAC		;Anzahl 254-Byte-Blocks in FAC:
			lda	#<V210c3		;(DOS-Datei-Länge / 254) wieder in ARG:
			ldy	#>V210c3
			jsr	MOVMA
			jsr	SUBFAC			;Rest-Betrag ermitteln.
			lda	#<V210c2
			ldy	#>V210c2
			jsr	MOVMA			;Anzahl Bytes errechnen.
			jsr	x_MULT
			jsr	FACWRD			;Erfebniss in 2-Byte-Integer.
			jsr	DoneWithBA

			CmpW0	r9			;Rest = 0 ?
			beq	:3			;Ja, weiter.--

			IncWord	V210c0			;Anzahl 254-Byte-Blocks +1.

::3			AddVBW	16,a6
			AddVBW	 9,a7			;Zeiger auf nächste DOS-Datei.
			jmp	:1

;*** Freien Speicher auf Ziel-Disk ermitteln.
:ChkDskBlkFree		jsr	GetDirHead
			txa
			beq	:1
			jmp	DiskError

::1			LoadW	r5,curDirHead		;Freie Blocks berechnen.
			jsr	CalcBlksFree
			CmpW	r4,V210c0		;Genug Speicher auf Ziel-Disk frei ?
			bcc	:2
			ldx	#$00			;Ja.
			rts

::2			ldx	#$ff			;Nein.
			rts

;*** Directory initialisieren.
:ResetDir		ldy	V210d0
			bne	:3

			ldy	V210a0			;Zeiger auf Anfang Directory setzen.
			bne	:1

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			MoveW	MdrSektor,V210a4
			jmp	:2

::1			lda	V210d2+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V210d2+1
			sta	V210d4+0
			stx	V210d4+1
			jsr	Clu_Sek

::2			MoveB	Seite ,V210d1+0		;Startposition merken.
			MoveB	Spur  ,V210d1+1
			MoveB	Sektor,V210d1+2
			MoveB	V210a4,V210d5
			MoveB	SpClu ,V210d6
			lda	#$00
			sta	V210d7
			sta	V210d15
			lda	#<Disk_Sek
			sta	a8L
			sta	V210d8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V210d8+1
			jsr	D_Read
			txa
			bne	:2a
			jmp	SaveDirPos
::2a			jmp	DiskError

::3			cpy	#$7f
			bne	:4

			jsr	LoadDirPos		;Directory-Zeiger wieder setzen.
			MoveB	V210d1+0,Seite
			MoveB	V210d1+1,Spur
			MoveB	V210d1+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			bne	:3a
			MoveW	V210d8,a8
			ClrB	V210d15
			rts
::3a			jmp	DiskError

::4			jsr	SaveDirPos		;Directory weiterlsen.
			MoveB	V210d1+0,Seite
			MoveB	V210d1+1,Spur
			MoveB	V210d1+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			bne	:3a
			MoveW	V210d8,a8
			rts

;*** Zeiger auf aktuelle Directory-Position wieder herstellen.
:LoadDirPos		ldy	#$09
::1			lda	V210d9,y
			sta	V210d3,y
			dey
			bpl	:1
			rts

;*** Zeiger auf aktuelle Directory-Position sichern.
:SaveDirPos		ldy	#$09
::1			lda	V210d3,y
			sta	V210d9,y
			dey
			bpl	:1
			rts

;*** Nächsten Sektor lesen.
:GetNxDirSek		LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			lda	V210d15			;Directory-Ende ?
			bne	:1			;Ja, Ende...

			lda	V210a0			;Hauptverzeichnis ?
			bne	NxSDirSek		;Nein, weiter...

			CmpBI	V210d5,1		;Alle Sektoren
			beq	:1			;gelesen ?

			dec	V210d5			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			jsr	D_Read			;Sektor lesen.
			txa
			bne	ExitErr_1
			ldx	#$00			;OK...
			b	$2c
::1			ldx	#$ff			;Directory-Ende...
			stx	V210d15
			rts
:ExitErr_1		jmp	DiskError

:NxSDirSek		CmpBI	V210d6,1		;Alle Sektoren
			beq	:1			;gelesen ?

			dec	V210d6			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			jsr	D_Read
			txa
			bne	ExitErr_1
			rts

::1			lda	V210d4+0		;Nächsten Cluster lesen.
			ldx	V210d4+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H
			sta	V210d4+0
			stx	V210d4+1

;*** Cluster Einlesen.
:GetSDirClu		ldy	FAT_Typ
			bne	:1

			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$0f
			bcc	:2
			ldx	#$ff
			bne	:3			;Ja, Ende...

::1			cmp	#$f8			;FAT16. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$ff
			bne	:2
			ldx	#$ff
			bne	:3			;Ja, Ende...

::2			jsr	Clu_Sek			;Cluster berechnen.
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			bne	ExitErr_1
			MoveB	SpClu,V210d6		;Zähler setzen.
			ldx	#$00
::3			stx	V210d15
			rts				;Ende...

;*** Kopier-Modus.
:DOSCopyMode		b $00				;$00= ->CBM, $FF= ->GW.

;*** Variablen und Texte.
:V210a0			b $00				;Directory-Typ.
:V210a1			b $00				;Anzahl Directorys.
:V210a2			b $00				;Anzahl Dateien.
:V210a3			b $00				;Anzahl Einträge.
:V210a4			w $0000				;Anzahl Sektoren im Hauptverzeichnis

;*** Zwischenspeicher für Datei-Name.
:V210b0			s $11				;Zwischenspeicher für Datei-Name.

;*** Berechnung der benötigten Blocks auf Ziel-Laufwerk.
:V210c0			w $0000
:V210c1			b $91,$00,$00,$00,$00
:V210c2			b $88,$7e,$00,$00,$00
:V210c3			b $00,$00,$00,$00,$00

;*** Variablen: Lesen des Directory.
:V210d0			b $00				;$00 = Ersten Dir-Sektor ermitteln.
							;$7F = Startwerte auf ersten Directory-Sektor.
							;$FF = Directory weiterlesen.
:V210d1			s $03				;Startadresse Directory (Sektor)
:V210d2			w $0000				;       "               (Cluster)

:V210d3			s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V210d4			w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V210d5			b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V210d6			b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V210d7			b $00				;Zähler Einträge in Sektor.
:V210d8			w $0000				;Zeiger auf Anfang Eintrag in Sektor.

:V210d9			s $03				;Startadresse aktive Datei-Tabelle (Sektor)
:V210d10		w $0000				;       "                          (Cluster)
:V210d11		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V210d12		b $00				;Zwischenspeicher: Zeiger auf Sektor in Cluster.
:V210d13		b $00				;Zwischenspeicher: Zähler Einträge in Sektor.
:V210d14		w $0000				;Zwischenspeicher: Zeiger auf Eintrag in Sektor.

:V210d15		b $00				;$FF = Directory-Ende.

:V210e0			s 17				;Zwischenspeicher für Datei-Name.
:V210e1			w $0000				;Zeiger auf Datei-Name.

;*** Dialogbox: Eingabe CBM-Datei-Name.
:V210f0			b $01
			b 48,135
			w 64,255
			b CANCEL     , 16, 64
			b DBUSRICON  ,  0,  0
			w V210f3
			b DBUSRICON  ,  2, 64
			w V210f4
			b DBUSRICON  , 10, 64
			w V210f5
			b DB_USR_ROUT
			w L210Col_1
			b DBGRPHSTR
			w V210f2
			b DBGETSTRING, 20, 32
			b r10L,14
			b NULL

:V210f1			b PLAINTEXT,REV_ON
			b "Datei-Name ändern",PLAINTEXT,NULL

:V210f2			b MOVEPENTO
			w 80
			b 77
			b FRAME_RECTO
			w 239
			b 92
			b NULL

:V210f3			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L210ExitW
:V210f4			w icon_None
			b $00,$00
			b icon_None_x,icon_None_y
			w No_Name
:V210f5			w icon_CBM
			b $00,$00
			b icon_CBM_x,icon_CBM_y
			w CBM_Name

:V210f6			b PLAINTEXT,BOLDON
			b "CBM-Datei: ",NULL

:InpNamBuf		s 17

:icon_None
<MISSING_IMAGE_DATA>
:icon_None_x		= .x
:icon_None_y		= .y

:icon_CBM
<MISSING_IMAGE_DATA>
:icon_CBM_x		= .x
:icon_CBM_y		= .y

;*** Fehler: "Datei-Name bereits vergeben!"
:V210f7			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V210f8
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V210f9
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V210f8			b PLAINTEXT,BOLDON
			b "Gewählter Datei-Name",NULL
:V210f9			b "ist bereits vergeben!",PLAINTEXT,NULL

;*** Titel: "Dateien wählen"
:V210g0			b PLAINTEXT,REV_ON
			b "Dateien wählen",PLAINTEXT,NULL

;*** Fehler: "Keine Dateien auf Disk!"
:V210h0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V210h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V210h2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V210h1			b PLAINTEXT,BOLDON
			b "Keine Dateien auf",NULL
:V210h2			b "Diskette !",PLAINTEXT,NULL

;*** Fehler: "Nicht genügend freier Speicher auf Ziel-Disk!"
:V210h3			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V210h4
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V210h5
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V210h4			b PLAINTEXT,BOLDON
			b "Nicht genügend freier",NULL
:V210h5			b "Speicher auf Ziel-Disk!",PLAINTEXT,NULL

;*** Info: "Disketten-Daten werden eingelesen..."
:V210i0			b PLAINTEXT,BOLDON
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
:V210i1			b PLAINTEXT,BOLDON
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
:V210i2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche Dateien..."
			b NULL

;*** Info: "Überprüfe das Ziel-Verzeichnis..."
:V210i3			b PLAINTEXT,BOLDON
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
:V210i4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei: "
			b NULL

;*** Konvertierungstabelle
:V210z0			b $00,$01,$02,$03,$04,$05,$06,$07
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
:V210z1

;*** Speicher für Datumstabelle.
:V210z2			= V210z1 + 16*256

;***Ende Daten-Speicher.
:V210z3			= V210z2 + 9*256
