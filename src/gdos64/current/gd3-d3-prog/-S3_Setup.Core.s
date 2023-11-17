; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeiger auf Tastatur-Abfrage für Programm-Abbruch.
:MainMenu		lda	#< TestExitKey
			sta	keyVector +0
			lda	#> TestExitKey
			sta	keyVector +1

			lda	#NULL
			sta	keyData

;--- Aktuelles Laufwerk zwischenspeichern.
			lda	curDrive		;Startlaufwerk als Vorgabe für
			sta	SourceDrv		;Quell-/Ziellaufwerk.
			sta	TargetDrv

;*** Setup-Hauptmenu.
:RestartSetup		jsr	ClearScreen		;Bildschirm löschen.

			jsr	FindSetupGD		;Archiv-Datei suchen.
			txa				;Diskettenfehler ?
			beq	GetSetupData		; => Nein, weiter...
:ErrorSetup		stx	DskErrCode

			LoadW	r0,DLG_ANALYZE_ERR
			jsr	DoDlgBox		;Fehler anzeigen.
			jmp	Exit2DT			;Zurück zum DeskTop.

:GetSetupData		lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	ErrorSetup		; => Ja, Abbruch...

			lda	fileHeader  +4		;Erster Sektor "Infodaten"
			sta	PatchInfoTS +0		;einlesen.
			lda	fileHeader  +5
			sta	PatchInfoTS +1

			lda	fileHeader  +6		;Erster Sektor "Patchdaten"
			sta	PatchDataTS +0		;einlesen.
			lda	fileHeader  +7
			sta	PatchDataTS +1

;--- Hauptmenü starten.
			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?

			LoadW	r0,mnuWelcome		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txWelcome1
			jmp	PutString

;*** SETUP-Datei überprüfen.
:CheckSETUP		jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?

			jsr	AnalyzeFile		;Archiv-Datei analysieren.
			txa				;Fehler?
			bne	ErrorSetup		; => Ja, Abbruch...

			jsr	CalcGroupSize		;Größe der Programmgruppe holen.

;*** Ziel-Laufwerk auswählen.
:SlctTarget		jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?

			LoadW	r0,mnuTarget		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txTarget1
			jsr	PutString

			jsr	PrntDriveA		;Laufwerksinformationen ausgeben.
			jsr	PrntDriveB
			jsr	PrntDriveC
			jmp	PrntDriveD

;--- Ziel-Laufwerk auswählen.
:SlctDrvA		ldx	#$08			; => Laufwerk A:
			b $2c
:SlctDrvB		ldx	#$09			; => Laufwerk B:
			b $2c
:SlctDrvC		ldx	#$0a			; => Laufwerk C:
			b $2c
:SlctDrvD		ldx	#$0b			; => Laufwerk D:
			stx	TargetDrv		;Laufwerksadresse speichern.
			lda	driveType -8,x		;Laufwerk verfügbar ?
			beq	:51			; => Nein, Ende...
			txa
			jsr	SetDevice		;Laufwerk aktivieren und
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	SlctInstallMode		; => Nein, weiter...
::51			rts				;Laufwerksauswahl fehlerhaft.

;*** Installationsmodus wählen.
:SlctInstallMode	jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	PrntCurDkSpace		;Freier Speicher auf Ziel-Laufwerk.
			LoadW	r0,mnuInstMode		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txInstMode1
			jsr	PutString

;--- Ergänzung: 06.03.21/M.Kanet
;Max. benötigten Speicherplatz für eine
;Komplett-Installation anzeigen.
			LoadW	r0,txInstMode2		;Max. benötigten Speicherplatz
			jsr	PutString		;anzeigen.

			MoveW	PatchSizeMax,r0

			lsr	r0H			;Anzahl Blocks in KByte umrechnen.
			ror	r0L
			lsr	r0H
			ror	r0L

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			LoadW	r0,txInstMode4
			jsr	PutString

			LoadW	r0,txInstMode3		;Min. benötigten Speicherplatz
			jsr	PutString		;anzeigen.

			MoveW	PatchSizeKB,r0

			lsr	r0H			;Anzahl Blocks in KByte umrechnen.
			ror	r0L
			lsr	r0H
			ror	r0L

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			LoadW	r0,txInstMode4
			jmp	PutString

;*** Laufwerkstreiber-Menü anzeigen.
:SlctDskCopyMode	lda	PatchSizeKB +6		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +7
			beq	:exit			; => Nein, Ende...
			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	PrntCurDkSpace		;Freien Speicher ausgeben.
			LoadW	r0,mnuCpyDkMod		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txCpyDkMod1
			jmp	PutString
::exit			rts

;*** Alle Dateien entpacken.
:CopyAllFiles		lda	#$00			; => Komplette Installation.
			b $2c
:CopySlctFiles		lda	#$ff			; => Teilweise Installation.
			sta	CopyMode

;*** Ziel-Laufwerk überprüfen.
:FindSysFiles		lda	#< Inf_ChkDkSpace
			ldx	#> Inf_ChkDkSpace
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			jsr	FindAllSysFiles		;Suche nach Systemdateien.
			lda	a1L			;Dateien bereits vorhanden ?
			beq	:do_copy		; => Nein, weiter...

			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,mnuDelOld		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txDelOld1
			jmp	PutString		;Menü: "Ziel-Dateien löschen ?"

::do_copy		jmp	CopyFiles

;*** Vorhandene Systemdatein löschen.
:DeleteSysFiles		lda	#< Inf_DelSysFiles
			ldx	#> Inf_DelSysFiles
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			jsr	SetVecTopArchiv		;Zeiger auf Tabelle mit Dateinamen.
::51			jsr	DefName			;Dateiname definieren.

			LoadW	r0,FNameBuffer
			jsr	DeleteFile		;Datei löschen.

			jsr	SetVecNxEntry		;Alle Dateien gelöscht ?
			bne	:51			; => Nein, weiter...

::do_copy		jmp	CopyFiles

;*** Einzelne Programmgruppe kopieren.
:CopyFiles		jsr	ClearInfoArea		;Info-Bereich löschen.

			lda	CopyMode		;Alle Dateien kopieren ?
			bne	CopyMenu		; => Nein, weiter...

;--- Speicher auf Ziel-Laufwerk überprüfen.
			jsr	ChkDskSpace		;Speicherplatz überprüfen.
			txa				;Genügend Speicher frei ?
			bne	errLowDskSpace		; => Ja, weiter...

			jsr	CopySystemFile		;Kopieren: System-Dateien.
			jsr	CopyRBootFile		;Kopieren: ReBoot-Dateien.
			jsr	CopyExtraFiles		;Kopieren: Extras.
			jsr	CopyHelpFiles		;Kopieren: Hilfesystem.
			jsr	CopyDskDevFile		;Kopieren: Laufwerkstreiber.

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			bne	CopyCompleted		; => Ja, weiter...

			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	ClearInfoArea		;Info-Bereich löschen.

			LoadW	r0,mnuNoREU		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txNoREU		;Hinweis ausgeben:
			jmp	PutString		;Keine Speichererweiterung erkannt.

;*** Dateien kopieren beendet, Installation fortsetzen.
:CopyCompleted		jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	ClearInfoArea		;Info-Bereich löschen.

			LoadW	r0,mnuSysCheck		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txSysCheck1
			jmp	PutString

;*** Nicht genügend Speicher frei.
:errLowDskSpace		jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,mnuDskSpace		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txDskSpace1
			jmp	PutString		;Menü: "Nicht genügend Speicher!"

;*** Auswahl der zu kopierenden Dateien.
:CopyMenu		jsr	ClearCurFName		;Dateiname löschen.

			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	ClearInfoArea		;Info-Bereich löschen.
			jsr	PrntCurDkSpace		;Freier Speicher auf Ziel-Laufwerk.

			jsr	CalcGroupSize		;Größe der Programmgruppe holen.
			jsr	PrntGroupSize		;Größe der Programmgruppen ausgeben.

			LoadW	r0,mnuCustom		;Menü ausgeben.
			jsr	DoColorMIcons
			LoadW	r0,txCustom1
			jmp	PutString		;Menü: "Dateien auswählen"

;*** Systemdateien suchen.
:ChkAllSysFiles		lda	#< Inf_InstallMP
			ldx	#> Inf_InstallMP
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			jsr	FindAllSysFiles		;Systemdateien suchen.

;--- Alle Dateien kopiert.
			lda	a1L
			cmp	#GD3_FILES_NUM		;Alle Dateien verfügbar ?
			bne	:51			; => Nein, weiter...
			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,mnuAllDone		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txAllDone1
			jmp	PutString

;--- Nicht alle Dateien kopiert, aber alle Systemdateien verfügbar.
::51			lda	a1H			;Fehlen Systemdateien ?
			bne	:52			; => Ja, weiter...
			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,mnuMissing		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txMissing1
			jmp	PutString

;--- Nicht alle Dateien kopiert, einige Systemdateien fehlen.
::52			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,mnuCopyMore		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txCopyMore1
			jmp	PutString

;*** Systemdateien suchen.
:FindAllSysFiles	jsr	OpenTargetDrive		;Ziel-Diskette öffnen.

			lda	#$00
			sta	a1L			;Zähler für kopierte Dateien.
			sta	a1H			;Zähler für fehlende Systemdateien.

			jsr	SetVecTopArchiv		;Zeiger auf Tabelle mit Dateinamen.

::51			jsr	DefName

			LoadW	r6,FNameBuffer
			jsr	FindFile		;Systemdatei suchen.
			txa				;Datei auf Diskette gefunden ?
			beq	:52			; => Ja, weiter...

			lda	EntryPosInArchiv
			asl
			tay
			lda	FileModeTab +0,y	;Fehlt ein Laufwerkstreiber ?
			beq	:53			; => Ja, ignorieren...
			lda	FileModeTab +1,y	;Fehlt eine Systemdatei ?
			bne	:53			; => Nein, weiter...

			inc	a1H			;Fehlende Systemdateien +1.
			b $2c
::52			inc	a1L			;Anzahl kopierte Dateien +1.

::53			jsr	SetVecNxEntry		;Alle Dateien überprüft ?
			bne	:51			; => Nein, weiter...
			rts

;*** GDOS installieren.
:StartGDUpdate		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	SetSerialNumber		;Aktuelle GEOS-ID übernehmen.

			jsr	ClearScreen		;Bildschirm löschen.

			jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			LoadW	r0,txConfigure		;Infomeldung ausgeben.
			jsr	PutString

			lda	#> Exit2DT-1		;Rücksprungadresse bereitstellen.
			pha				;(Wird ausgeführt falls Disketten-
			lda	#< Exit2DT-1		; fehler auftritt).
			pha
			LoadB	r0L,%00000000
			LoadW	r6 ,FNameUpdate
			jmp	GetFile			;Startprg. laden und starten.
::51			rts

;*** Serien-ID anpassen.
:SetSerialNumber	LoadW	r6,File_GD3_1
			jsr	FindFile		;Systemdatei mit GEOS-ID suchen.
			txa				;Diskettenfehler ?
			bne	:52			; => Nein, weiter...

			lda	#< SerialNumber
			sec
			sbc	#< OS_LOW -2		;2 Bytes für Dummy-WORD am Beginn
			sta	r10L			;der Startdatei abziehen.
			lda	#> SerialNumber		;(BASIC-Loader!)
			sbc	#> OS_LOW -2
			sta	r10H

			LoadW	r4,diskBlkBuf
			lda	dirEntryBuf +1		;Sektor mit GEOS-ID innerhalb
			ldx	dirEntryBuf +2		;der Startdatei suchen.
::51			sta	r1L
			stx	r1H
			jsr	GetBlock

			CmpWI	r10,254			;Sektor gefunden ?
			bcc	:53			; => Ja, weiter...

			SubVW	254,r10

			ldx	diskBlkBuf +1
			lda	diskBlkBuf +0
			bne	:51

			ldx	#BYTE_DEC_ERR
::52			stx	DskErrCode

			LoadW	r0,DLG_GEOS_ID_ERR
			jsr	DoDlgBox		;Fehler anzeigen.
			jmp	Exit2DT			;Zurück zum DeskTop.

::53			jsr	GetSerialNumber		;Aktuelle GEOS-ID einlesen.

			ldx	r10L			;LowByte der GEOS-ID speichern.
			inx
			inx
			lda	r0L
			sta	diskBlkBuf,x
			inx				;HighByte noch innerhalb Sektor ?
			bne	:54			; => Ja, weiter...

			jsr	PutBlock		;Aktuellen Sektor speichern.
			txa
			bne	:52

			lda	diskBlkBuf +0		;Nächsten Sektor einlesen.
			ldx	diskBlkBuf +1
			sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			bne	:52

			ldx	#$02			;Zeiger auf erstes Byte.
::54			lda	r0H			;HighByte der GEOS-ID speichern.
			sta	diskBlkBuf,x
			jsr	PutBlock
			txa
			bne	:52
			rts

;*** Ausgabe der verfügbaren Laufwerke für die Ziel-Auswahl.
;    Laufwerk A: bis D: ausgeben.
:PrntDriveA		ldx	#$08
			b $2c
:PrntDriveB		ldx	#$09
			b $2c
:PrntDriveC		ldx	#$0a
			b $2c
:PrntDriveD		ldx	#$0b
;--- Ergänzung: 12.07.18/M.Kanet
;Der ursprüngliche Code an dieser Stelle zum setzen der Cursor-Position
;zur Ausgabe des Laufwerks- und Diskettennamens wurde in eine eigene
;Routine ausgelagert um mehrere Code-Instanzen zusammenzufassen.
			jsr	SetDrvTextPos		;Position für Textausgabe.

;--- Aktuelles Laufwerk ausgeben.
:PrintDrive		lda	driveType -8,x		;Laufwerk verfügbar ?
			bne	:51			; => Ja, weiter...
			LoadW	r0,NoDrvText		;Text "Kein Laufwerk" ausgeben.
			jsr	PutString
			jmp	:57

::51			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...

			ldx	curDrive
			jsr	SetDrvTextPos		;Position für Textausgabe.

			LoadW	r0,NoDskText		;Text "Keine Diskette" ausgeben.
			jsr	PutString
			jmp	:57

;--- Diskettenname ausgeben.
::52			ldx	#r0L			;Diskettenname ausgeben.
			jsr	GetPtrCurDkNm

			ldx	curDrive
			jsr	SetDrvTextPos		;Position für Textausgabe.

			lda	#$00
::53			pha
			tay
			lda	(r0L),y
			bne	:54
			pla
			jmp	:57

::54			cmp	#$20
			bcc	:55
			cmp	#$7f
			bcc	:56
::55			lda	#" "
::56			jsr	SmallPutChar
			pla
			clc
			adc	#$01
			cmp	#16
			bcc	:53

;--- Freien Speicher ausgeben.
			LoadW	r5,curDirHead		;Verfügbaren Speicherplatz
			jsr	CalcBlksFree		;berechnen.
			ldx	#r4L
			ldy	#$02
			jsr	DShiftRight		;Blocks in KByte umwandeln.

			ldx	curDrive
			jsr	SetDrvTextPos		;Position für Textausgabe.
			lda	r1H
			clc
			adc	#10
			sta	r1H

			MoveW	r4,r0			;Speicherplatz ausgeben.
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			LoadW	r0,KFreeText		;Text "Kb frei" ausgeben.
			jsr	PutString

::57			LoadW	rightMargin,319		;Rechten Rand zurücksetzen.
			rts

;*** Koordinaten für Textausgabe setzen.
;Übergabe: XReg = Laufwerksadresse 8-11
:SetDrvTextPos		lda	YPos  -8,x		;Position für Textausgabe.
			sta	r1H
			lda	XPosL -8,x
			sta	r11L
			lda	XPosH -8,x
			sta	r11H
			lda	WinMaxXL  -8,x		;Rechten Rand definieren.
			sta	rightMargin +0		;Damit wird verhindest das z.B.
			lda	WinMaxXH  -8,x		;die Anzeige des Diskettennamens
			sta	rightMargin +1		;den rechten Rand überschreitet.
			rts

;*** Freien Speicher ausgeben.
:PrntCurDkSpace		jsr	GetDskSpace		;Freien Diskettenspeicher
							;berechnen.

			jsr	ClearInfoArea		;Info-Bereich löschen.

			LoadW	r0,txFreeSpace
			jsr	PutString

			MoveW	TargetFreeB,r0

			lsr	r0H			;Anzahl Blocks in KByte umrechnen.
			ror	r0L
			lsr	r0H
			ror	r0L

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Freien Speicher ausgeben.

			lda	#"K"
			jmp	SmallPutChar

;*** Freien Speicher prüfen.
:ChkDskSpace		jsr	GetDskSpace		;Freien Diskettenspeicher
			txa				;berechnen.
			bne	:52

			lda	PatchSizeKB +0		;Benötigter Speicher für eine
			sta	TargetNeedB +0		;Komplettinstallation einlesen.
			lda	PatchSizeKB +1
			sta	TargetNeedB +1

			ldx	#NO_ERROR
			lda	TargetNeedB +1		;Genügend Speicher frei?
			cmp	TargetFreeB +1
			bne	:51
			lda	TargetNeedB +0
			cmp	TargetFreeB +0
::51			bcc	:52

			ldx	#INSUFF_SPACE		;Nein, Fehler.
::52			rts

;*** Freien Speicher einlesen.
:GetDskSpace		lda	#$00			;Freien Speicher löschen.
			sta	TargetFreeB +0
			sta	TargetFreeB +1

			jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			LoadW	r5,curDirHead
			jsr	CalcBlksFree		;Freien Speicher berechnen.

			MoveW	r4,TargetFreeB

			ldx	#NO_ERROR
::err			rts

;*** Benutzerdefinierte Installation.
;    Benötigten Speicher für Programmgruppen anzeigen.
:PrntGroupSize		LoadW	a1,mnuCustom +6		;Zeiger auf Icon-Tabelle.

			lda	#1			;Zeiger auf erste Programmgruppe.
			sta	ExtractFileType

::51			ldy	#$00			;Position für Textausgabe
			lda	(a1L),y			;berechnen.
			iny
			iny
			clc
			adc	(a1L),y
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r11L
			ldy	#$03
			jsr	DShiftLeft		;X-Koordinate.

			ldy	#$01
			lda	(a1L),y
			clc
			adc	#$14
			sta	r1H			;Y-Koordinate.

			lda	#" "
			jsr	SmallPutChar

			lda	ExtractFileType		;Aktuelle Dateigruppe einlesen und
			asl				;benötigten Speicher berechnen.
			tay
			lda	PatchSizeKB +0,y
			sta	r0L
			lda	PatchSizeKB +1,y
			sta	r0H

			lsr	r0H			;Anzahl Blocks in KByte umrechnen.
			ror	r0L
			lsr	r0H
			ror	r0L

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Speicherplatz ausgeben.

			lda	#"K"
			jsr	SmallPutChar

			AddVBW	8,a1

			inc	ExtractFileType		;Nächste Dateigruppe.
			lda	ExtractFileType
			cmp	#5 +1			;Alle Dateigruppen bearbeitet ?
			bcc	:51			; => Nein, weiter...
			rts

;*** Ziel-Datei löschen.
;    Übergabe:		a7 = Zeiger auf Dateieintrag.
:DeleteTarget		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			jsr	DefName			;Zeiger auf Dateiname setzen.
			LoadW	r0,FNameBuffer
			jsr	DeleteFile		;Datei löschen.

;*** Aktuelle Datei auf Bildschirm ausgeben.
:PrntCurFName		jsr	i_FrameRectangle
			b	$a8,$bf
			w	$0000,$013f
			b	%11111111
			jsr	FrameMenuArea

			LoadW	r0,txExtractFile
			jsr	PutString

			LoadW	r0,FNameBuffer
			jmp	PutString

;*** Aktuelle Datei von Bildschirm löschen.
:ClearCurFName		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$a8,$bf
			w	$0000,$013f
			rts

;*** Dateiname definieren.
:DefName		ldy	#$05			;Dateiname aus Verzeichniseintrag
::51			lda	(a7L),y			;einlesen und in Dateiname kopieren.
			beq	:52
			cmp	#$a0
			beq	:52
			sta	FNameBuffer -5,y
			iny
			cpy	#$15
			bcc	:51
			bcs	:53
::52			lda	#$00
			sta	FNameBuffer -5,y
::53			rts

;*** Prozentanzeige.
:PrintPercent		MoveW	WriteSekCount,r0
			LoadB	r1L,100
			ldx	#r0L
			ldy	#r1L
			jsr	BMult

			MoveW	SizeSourceFile,r1
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			CmpWI	r0,100
			bcc	PrintCurPercent
			LoadW	r0,99

;*** Prozentwert "Daten kopiert" anzeigen.
:PrintCurPercent	LoadW	r11,$0118
			LoadB	r1H,$b6
			lda	#%11000000
			jsr	PutDecimal
			lda	#"%"
			jsr	SmallPutChar
			lda	#" "
			jmp	SmallPutChar

;*** Fehlercode ausgeben.
:PrntErrCode		LoadW	r0,DskErrInfText
			jsr	PutString

			lda	DskErrCode
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Quell-Diskette öffnen.
:OpenSourceDrive	jsr	SwapSourceDrive
			jmp	OpenDisk

;*** Ziel -Diskette öffnen.
:OpenTargetDrive	jsr	SwapTargetDrive
			jmp	OpenDisk

;*** Quell-Laufwerk aktivieren.
:SwapSourceDrive	lda	SourceDrv
			bne	SwapDrive

;*** Ziel -Laufwerk aktivieren.
:SwapTargetDrive	lda	TargetDrv

;*** Laufwerk wechseln.
:SwapDrive		cmp	curDrive
			beq	:51
			jmp	SetDevice

::51			ldx	#$00
			rts

;*** Diskettenfehler ausgeben.
:DiskError		stx	DskErrCode

			LoadW	r0,DLG_DISKERROR
			jsr	DoDlgBox		;Fehler anzeigen.
;			jmp	Exit2DT			;Zurück zum DeskTop.

;*** Zurück zum DeskTop.
:Exit2DT		lda	#$00			;Farben löschen.
			jsr	:resetColors

			lda	#2			;Bildscirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			lda	screencolors		;Standardfarben setzen.
			jsr	:resetColors

			jmp	EnterDeskTop		;Zurück zum DeskTop.

::resetColors		sta	:col
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::col			b	$00
			rts

;*** Tastatur-Abfrage: "!" beendet Setup.
:TestExitKey		lda	keyData			;Taste im Puffer einlesen.
			cmp	#"!"			;'!'-Taste?
			beq	Exit2DT			; => Ja, Abbruch...

;--- Hinweis:
;Während der CRC-Prüfung wird von GEOS
;die Tastatur nicht ausgewertet, da die
;GEOS-MainLoop nicht ausgeführt wird.
;Daher pressFlag/currentKey testen, die
;über den IRQ gesetzt werden.
			bit	pressFlag		;Neue Taste gedrückt?
			bpl	:1			; => Nein, weiter...

			lda	currentKey
			cmp	#"!"			;'!'-Taste?
			beq	Exit2DT			; => Ja, Abbruch...

::1			rts

;*** Titelgrafik anzeigen.
:ClearScreen		LoadB	dispBufferOn,ST_WR_FORE
			jsr	UseSystemFont

			jsr	i_FillRam		;FarbRAM löschen.
			w	1000
			w	COLOR_MATRIX
			b	$00
			jsr	i_FillRam		;Grafikbildschirm löschen.
			w	8000
			w	SCREEN_BASE
			b	$00

			jsr	LogoScreen		;GD-Logo mit Farbe anzeigen.

			jsr	ClearInfoArea		;Info-Bereich löschen.

			jsr	UseFontG3		;Neuen Zeichensatz aktivieren.

			LoadW	r0,Build_ID		;Release / Build-ID ausgeben.
			jmp	PutString

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$2f
			w	$0040,$00ff

			LoadB	r5L,8
			LoadB	r5H,4
			LoadB	r6L,24
			LoadB	r6H,12
			LoadB	r7L,COLOR_DLG_BOX
			jsr	ColorRecBox

			LoadB	r6H,2
			LoadB	r7L,COLOR_DLG_TITLE
			jsr	ColorRecBox

			jmp	UseSystemFont

;*** Informationstext für Kopierstatus ausgeben.
:ViewInfoBox		pha
			txa
			pha

			jsr	ClearMenuArea		;Menü-/Status-Fenster löschen.

			jsr	ClearInfoArea		;Info-Bereich löschen.

			jsr	i_FrameRectangle
			b	$48,$87
			w	$0000,$013f
			b	%11111111
			jsr	FrameMenuArea

			LoadW	r0,Inf_Wait
			jsr	PutString

			pla
			sta	r0H
			pla
			sta	r0L
			jmp	PutString

;*** Auf REU testen.
:CheckREU		lda	ramExpSize		;Speichererweiterung vorhanden ?
			bne	:1			; => Ja, weiter...
			jsr	ClearInfoArea		;Farbe für Hinweis setzen.
			LoadW	r0,txWarnNoREU		;Hinweis ausgeben:
			jsr	PutString		;Keine Speichererweiterung erkannt!
::1			rts

;*** Info-Bereich löschen.
:ClearInfoArea		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$47
			w	$0000,$013f
			ldx	#COLOR_MENU_INFO
			jmp	SetColorRec

;*** Menü-/Status-Fenster löschen.
:ClearScrnArea		jsr	ClearMenuArea
			jsr	i_FrameRectangle
			b	$48,$bf
			w	$0000,$013f
			b	%11111111
			jmp	FrameMenuArea

;*** Menüfenster löschen.
:ClearMenuArea		jsr	i_FillRam
			w	1000         -9*40
			w	COLOR_MATRIX +9*40
			b	$00
			jsr	i_FillRam
			w	8000         -9*40*8
			w	SCREEN_BASE  +9*40*8
			b	$00
			rts

;*** Menü-/Status-Bereich zeichnen.
:FrameMenuArea		ldx	#COLOR_MENU_AREA
			jsr	SetColorRec

			jsr	SetSmall
			lda	#$00
			jsr	SetPattern
			jsr	Rectangle
			jsr	SetSmall
			jsr	SetSmall
			lda	#%11111111
			jsr	FrameRectangle
;			jsr	SetSmall
;			lda	#%11111111
;			jsr	FrameRectangle

;--- X/Y-Koordinaten korrigieren.
:SetSmall		inc	r2L
			dec	r2H

			inc	r3L
			bne	:51
			inc	r3H
::51			lda	r4L
			bne	:52
			dec	r4H
::52			dec	r4L
			rts

;*** CARD-Werte für Farbrechteck berechnen.
:SetColorRec		lda	r2L
			lsr
			lsr
			lsr
			sta	r5H
			lda	r2H
			lsr
			lsr
			lsr
			sec
			sbc	r5H
			sta	r6H
			inc	r6H
			lda	#$00
			sta	r5L
			lda	#$28
			sta	r6L
			stx	r7L
			jmp	ColorRecBox

;*** Farbe für ":DoIcons"-Menü aktivieren.
:DoColorIcons		lda	#$00
			b $2c
:DoColorMIcons		lda	#$ff
			sta	r7H

			PushW	r0

::51			ldy	#$00
			lda	(r0L),y
			sta	r1H

			AddVBW	4,r0

			ldx	#$00			;Icon-Zähler löschen und auf
			beq	:56			;Icons in Tabelle testen.
::52			jsr	DefIconArea
			beq	:54

			ldy	#COLOR_ICON_STD
			bit	r7H			;Menü zeichnen ?
			bpl	:53			; => Nein, weiter...
			ldx	r1L
			cpx	#$05
			bcs	:53
			lda	CopyFlgSystem,x		;Dateien bereits kopiert ?
			beq	:53			; => Nein, weiter...
			ldy	#COLOR_ICON_OFF		;Farbe für "kopierte Dateien".
::53			sty	r7L			;Farbe setzen und
			jsr	ColorRecBox		;Farbrechteck zeichnen.

::54			clc				;Zeiger auf nächstes Icon.
			lda	r0L
			adc	#$08
			sta	r0L
			bcc	:55
			inc	r0H
::55			ldx	r1L			;Icon-Zähler einlesen und
			inx				;auf nächstes Icon setzen.
::56			cpx	r1H			;Alle Icon-Farben ausgegeben ?
			bne	:52			;Weiter mit Farbe ausgeben.

			PopW	r0
			jmp	DoIcons

;*** Größe aktuelles Icon berechnen.
:DefIconArea		stx	r1L			;Zähler zwischenspeichern.

			ldy	#$05
::51			lda	(r0L),y			;Icon-Daten einlesen.
			sta	r4   ,y
			dey
			bpl	:51

			lda	r4L			;Testen ob Bitmap = $0000.
			ora	r4H
			beq	:52			; => Keine Farbe...
			lsr	r5H			;Y-Koordinate und Höhe des
			lsr	r5H			;Icons in CARDs umrechnen.
			lsr	r5H
			lsr	r6H
			lsr	r6H
			lsr	r6H
			lda	#$ff
::52			rts

;*** Farbrechteck zeichnen.
;    Übergabe: r5L=X, r5H=Y, r6L=Breite, r6H=Höhe.
;    Angabe in Cards!
:ColorRecBox		lda	#< COLOR_MATRIX
			sta	r8L
			lda	#> COLOR_MATRIX
			sta	r8H

			ldx	r5H
::101			jsr	:110			;Zeiger auf erste Zeile für
			bne	:101			;Farbdaten berechnen.

			lda	r5L			;Zeiger auf X-Koordinate setzen.
			clc
			adc	r8L
			sta	r8L
			bcc	:102
			inc	r8H
::102			ldx	r6H			;Höhe des Rechtecks.
::103			ldy	r6L			;Breite des Rechtecks.
			dey
			lda	r7L			;Farbe einlesen und
::104			sta	(r8L),y			;in Farbspeicher kopieren.
			dey
			bpl	:104

			jsr	:111
			bne	:103
			rts

;*** Zeiger auf Datenzeile berechnen.
::110			txa
			beq	:113
::111			clc
			lda	r8L
			adc	#40
			sta	r8L
			bcc	:112
			inc	r8H
::112			dex
::113			rts

;*** Kopiermodus
:CopyMode		b $00				;$00 = Alle Dateien kopieren.
:CopyFlgSystem		b $00
:CopyFlgRBOOT		b $00
:CopyFlgDskDrive	b $00
:CopyFlgExtras		b $00
:CopyFlgHelp		b $00

;*** Dateinamen.
:FNameSETUP		s 17
:FNameBuffer		s 17

:TargetDrv		b $00				;Quell-Laufwerk.
:SourceDrv		b $00				;Ziel -Laufwerk.
:TargetFreeB		w $0000				;Freier Speicher.
:TargetNeedB		w $0000				;Belegter Speicher.

:DskErrCode		b $00

;*** Koordinaten für Ausgabe der Laufwerksbezeichnungen.
:YPos			b IconT1y
			b IconT2y
			b IconT1y
			b IconT2y
:XPosL			b <IconT1x+3
			b <IconT1x+3
			b <IconT2x+3
			b <IconT2x+3
:XPosH			b >IconT1x+3
			b >IconT1x+3
			b >IconT2x+3
			b >IconT2x+3
:WinMaxXL		b $9f,$9f,$2f,$2f
:WinMaxXH		b $00,$00,$01,$01

;*** Texte für Diskettenfehler.
:DskErrInfText		b PLAINTEXT,BOLDON
			b GOTOXY
			w $0050
			b $74
if LANG = LANG_DE
			b "Fehler-Code:"
endif
if LANG = LANG_EN
			b "Error code:"
endif
			b NULL

;*** Titel für Dialogboxen.
if LANG = LANG_DE
:DskErrTitel		b PLAINTEXT,BOLDON
			b "FEHLER!"
			b NULL
:DlgInfoTitel		b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b NULL
endif
if LANG = LANG_EN
:DskErrTitel		b PLAINTEXT,BOLDON
			b "ERROR:"
			b NULL
:DlgInfoTitel		b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b NULL
endif

;*** Dialogbox: Diskettenfehler.
:DLG_DISKERROR		b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w :11
			b DBTXTSTR ,$10,$2a
			w :12
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

if LANG = LANG_DE
::11			b PLAINTEXT
			b "Es ist ein Fehler aufgetreten,",NULL
::12			b "die Installation wird abgebrochen!",NULL
endif
if LANG = LANG_EN
::11			b PLAINTEXT
			b "An error has occurred, the",NULL
::12			b "installation is aborted!",NULL
endif

;*** Dialogbox: GEOS-ID konnte nicht gespeichert werden.
:DLG_GEOS_ID_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w :11
			b DBTXTSTR ,$10,$2a
			w :12
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

if LANG = LANG_DE
::11			b PLAINTEXT
			b "Die GEOS-ID konnte nicht",NULL
::12			b "gespeichert werden!",NULL
endif
if LANG = LANG_EN
::11			b PLAINTEXT
			b "Unable to write GEOS-ID to",NULL
::12			b "the system disk!",NULL
endif

;*** Dialogbox: Fehler beim analysieren der Systemdatei.
:DLG_ANALYZE_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w :11
			b DBTXTSTR ,$10,$2a
			w :12
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

if LANG = LANG_DE
::11			b PLAINTEXT
			b "Die Programm-Datei 'SetupGD' ist",NULL
::12			b "fehlerhaft oder beschädigt!",NULL
endif
if LANG = LANG_EN
::11			b PLAINTEXT
			b "The program file 'SetupGD' is",NULL
::12			b "faulty or damaged!",NULL
endif

;*** Text für Release-Hinweis.
:Build_ID		b PLAINTEXT
			b GOTOXY
			w $0018
			b $3a
			b "Release: "
			t "opt.GDOS.Build"
			b NULL

;*** Systemtexte.
if LANG = LANG_DE
:NoDrvText		b PLAINTEXT,"Laufwerk ?",NULL
:NoDskText		b PLAINTEXT,"Diskette ?",NULL
:KFreeText		b PLAINTEXT,"Kb frei",NULL
endif
if LANG = LANG_EN
:NoDrvText		b PLAINTEXT,"Drive ?",NULL
:NoDskText		b PLAINTEXT,"Disk ?",NULL
:KFreeText		b PLAINTEXT,"Kb free",NULL
endif

:txWarnNoREU		b PLAINTEXT
			b GOTOXY
			w $0018
			b $3a
if LANG = LANG_DE
			b "Keine Speichererweiterung erkannt!"
endif
if LANG = LANG_EN
			b "No ram expansion unit detected!"
endif
			b NULL

:txFreeSpace		b PLAINTEXT
			b GOTOXY
			w $0018
			b $3a
if LANG = LANG_DE
			b "Freier Speicher auf Ziel-Diskette: "
endif
if LANG = LANG_EN
			b "Free space on target-disk: "
endif
			b NULL

:txExtractFile		b PLAINTEXT
			b GOTOXY
			w $0010
			b $b6
if LANG = LANG_DE
			b "Entpacke Datei: "
endif
if LANG = LANG_EN
			b "Extracting file: "
endif
			b NULL

;*** GDOS konfigurieren.
:txConfigure		b PLAINTEXT
			b GOTOXY
			w $0020
			b $76
if LANG = LANG_DE
			b "Bitte haben Sie einen kleinen Augenblick"
endif
if LANG = LANG_EN
			b "Please be patient for a moment while"
endif
			b GOTOXY
			w $0020
			b $80
if LANG = LANG_DE
			b "Geduld, während Setup die Startdiskette"
endif
if LANG = LANG_EN
			b "Setup configures your GDOS64 bootdisk..."
endif
			b GOTOXY
			w $0020
			b $8a
if LANG = LANG_DE
			b "für GDOS64 konfiguriert..."
endif
if LANG = LANG_EN
			b ""
endif
			b NULL

;*** Information über Kopierstatus.
:Inf_Wait		b GOTOXY
			w $0010
			b $5a
			b PLAINTEXT,OUTLINEON
if LANG = LANG_DE
			b "Bitte warten!"
endif
if LANG = LANG_EN
			b "Please wait!"
endif
			b GOTOXY
			w $0010
			b $70
			b PLAINTEXT
			b NULL

if LANG = LANG_DE
:Inf_DelSysFiles	b "Systemdateien werden gelöscht...",NULL
:Inf_CopySystem		b "Systemdateien werden kopiert...",NULL
:Inf_CopyRBoot		b "ReBoot-Routine wird kopiert...",NULL
:Inf_CopyExtras		b "Hintergrundbilder, Bildschirmschoner, Farbprofile"
			b GOTOXY
			w $0010
			b $7a
			b "und weitere Eingabetreiber werden kopiert...",NULL
:Inf_CopyHelp		b "Hilfesystem wird kopiert...",NULL
:Inf_CopyDskDrv		b "Laufwerkstreiber werden kopiert...",NULL
:Inf_InstallMP		b "Systemdiskette wird untersucht...",NULL
:Inf_ChkDkSpace		b "Zieldiskette wird überprüft...",NULL
endif
if LANG = LANG_EN
:Inf_DelSysFiles	b "Deleting system files...",NULL
:Inf_CopySystem		b "Copying system files...",NULL
:Inf_CopyRBoot		b "Copying ReBoot system...",NULL
:Inf_CopyExtras		b "Copying wallpapers, screen savers, color profiles"
			b GOTOXY
			w $0018
			b $7a
			b "and additional input drivers...",NULL
:Inf_CopyHelp		b "Copying help system...",NULL
:Inf_CopyDskDrv		b "Copying disk drivers...",NULL
:Inf_InstallMP		b "Checking bootdisk...",NULL
:Inf_ChkDkSpace		b "Checking target drive...",NULL
endif

;*** Setup starten.
:mnuWelcome		b $02
			w $0000
			b $00

			w Icon_07
			b Icon1x  ,Icon2y
			b Icon_07x,Icon_07y
			w CheckSETUP

			w Icon_12
			b Icon2x  ,Icon2y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Setup starten.
:txWelcome1		b PLAINTEXT
			b GOTOXY
			w $0010
			b $58
if LANG = LANG_DE
			b "Willkommen zum GEOS-Update 'GDOS64'"
endif
if LANG = LANG_EN
			b "Welcome to the GEOS update 'GDOS64'"
endif
			b GOTOXY
			w $0010
			b $66
if LANG = LANG_DE
			b "Das SETUP-Programm wird Sie bei der Installation"
endif
if LANG = LANG_EN
			b "The SETUP program will assist you with the"
endif
			b GOTOXY
			w $0010
			b $6e
if LANG = LANG_DE
			b "von GDOS64 unterstützen."
endif
if LANG = LANG_EN
			b "intallation of GDOS64."
endif
			b GOTOXY
			w $0010
			b $78
if LANG = LANG_DE
			b "Hinweise: SuperCPU / TurboChameleon64 empfohlen,"
endif
if LANG = LANG_EN
			b "Notes: SuperCPU / TurboChameleon64 recommended,"
endif
			b GOTOXY
			w $0010
			b $80
if LANG = LANG_DE
			b "für schnelle Installation von RAM-Laufwerk starten!"
endif
if LANG = LANG_EN
			b "for a quick installation run SETUP from RAM drive!"
endif
			b GOTOXY
			w $0010
			b $8a
if LANG = LANG_DE
			b "Mit der Taste '!' kann der Installationsvorgang"
endif
if LANG = LANG_EN
			b "If you want to cancel the installation process,"
endif
			b GOTOXY
			w $0010
			b $92
if LANG = LANG_DE
			b "innerhalb eines Menüs beendet werden."
endif
if LANG = LANG_EN
			b "press the '!' key when a menu is displayed."
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Installation"
endif
if LANG = LANG_EN
			b "Continue with"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "fortsetzen"
endif
if LANG = LANG_EN
			b "installation"
endif

			b GOTOXY
			w IconT2x
			b IconT2y
if LANG = LANG_DE
			b "Setup"
endif
if LANG = LANG_EN
			b "Cancel"
endif
			b GOTOXY
			w IconT2x
			b IconT2ay
if LANG = LANG_DE
			b "abbrechen"
endif
if LANG = LANG_EN
			b "Setup"
endif
			b NULL

;*** Ziel-Laufwerk wählen.
:mnuTarget		b $05
			w $0000
			b $00

			w Icon_08
			b Icon1x  ,Icon1y
			b Icon_08x,Icon_08y
			w SlctDrvA

			w Icon_08
			b Icon1x  ,Icon2y
			b Icon_08x,Icon_08y
			w SlctDrvB

			w Icon_08
			b Icon2x  ,Icon1y
			b Icon_08x,Icon_08y
			w SlctDrvC

			w Icon_08
			b Icon2x  ,Icon2y
			b Icon_08x,Icon_08y
			w SlctDrvD

			w Icon_14
			b IconX1x ,IconX1y
			b Icon_14x,Icon_14y
			w SlctTarget

;*** Ziel-Laufwerk wählen.
:txTarget1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Wählen Sie das Laufwerk, auf das die"
endif
if LANG = LANG_EN
			b "Please choose the drive, on which the"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "Systemdateien kopiert werden sollen:"
endif
if LANG = LANG_EN
			b "system files should be copied to:"
endif
			b GOTOXY
			w $0018
			b $6a
if LANG = LANG_DE
			b "Hinweis: Leerdisk empfohlen! Nicht auf"
endif
if LANG = LANG_EN
			b "Note: Empty disk recommended! Do not"
endif
			b GOTOXY
			w $0018
			b $72
if LANG = LANG_DE
			b "eine GEOS V2 Bootdisk installieren!"
endif
if LANG = LANG_EN
			b "install on a GEOS V2 bootdisk!"
endif

			b GOTOXY
			w IconT1x  -41
			b IconT1ay +3
			b "A:"
			b GOTOXY
			w IconT1x  -41
			b IconT2ay +3
			b "B:"
			b GOTOXY
			w IconT2x  -41
			b IconT1ay +3
			b "C:"
			b GOTOXY
			w IconT2x  -41
			b IconT2ay +3
			b "D:"
			b NULL

;*** Installationsmodus wählen.
:mnuInstMode		b $02
			w $0000
			b $00

			w Icon_00
			b Icon1x  ,Icon1y
			b Icon_00x,Icon_00y
			w CopyAllFiles

			w Icon_01
			b Icon1x  ,Icon2y
			b Icon_01x,Icon_01y
			w CopySlctFiles

;*** Installationsmodus wählen.
:txInstMode1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Installationsprogramm für GDOS64"
endif
if LANG = LANG_EN
			b "Installation program for GDOS64"
endif
			b GOTOXY
			w $0018
			b $68
if LANG = LANG_DE
			b "Bitte wählen Sie die Art der Installation:"
endif
if LANG = LANG_EN
			b "Please choose the type of installation:"
endif

			b GOTOXY
			w IconT1x
			b IconT1y -2
if LANG = LANG_DE
			b "Komplette Installation mit allen Dateien"
endif
if LANG = LANG_EN
			b "Complete installation with all files"
endif
			b GOTOXY
			w IconT1x
			b IconT1ay -2
if LANG = LANG_DE
			b "auf Diskette oder CMD-Partition."
endif
if LANG = LANG_EN
			b "on disk or CMD partition."
endif
			b GOTOXY
			w IconT1x
			b IconT2y -2
if LANG = LANG_DE
			b "Benutzerdefinierte Installation oder"
endif
if LANG = LANG_EN
			b "Custom installation or update an"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay -2
if LANG = LANG_DE
			b "ändern einer Startdiskette."
endif
if LANG = LANG_EN
			b "existing bootdisk."
endif
			b NULL

;--- Installation: Vollständig.
:txInstMode2		b GOTOXY
			w IconT1x
			b IconT1ay -2 +9
if LANG = LANG_DE
			b "(Benötigt max. "
endif
if LANG = LANG_EN
			b "(Max. "
endif
			b NULL

;--- Installation: Benutzerdefiniert.
:txInstMode3		b GOTOXY
			w IconT1x
			b IconT2ay -2 +9
if LANG = LANG_DE
			b "(Benötigt min. "
endif
if LANG = LANG_EN
			b "(Min. "
endif
			b NULL

;--- Speicher erforderlich.
:txInstMode4
if LANG = LANG_DE
			b "Kb freien Speicher)"
endif
if LANG = LANG_EN
			b "Kb free disk space required)"
endif
			b NULL

;*** Vorhandene Installation löschen.
:mnuDelOld		b $03
			w $0000
			b $00

			w Icon_13
			b Icon1x  ,Icon1y
			b Icon_13x,Icon_13y
			w DeleteSysFiles

			w Icon_07
			b Icon2x  ,Icon1y
			b Icon_07x,Icon_07y
			w CopyFiles

			w Icon_12
			b Icon2x  ,Icon2y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Vorhandene Installation löschen.
:txDelOld1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Das Ziel-Laufwerk enthält bereits einige Dateien"
endif
if LANG = LANG_EN
			b "The target drive allready includes some system"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "von GDOS64. Sollen die vorhandenen Dateien"
endif
if LANG = LANG_EN
			b "files of GDOS64. Should the existing files"
endif
			b GOTOXY
			w $0018
			b $68
if LANG = LANG_DE
			b "gelöscht werden ?"
endif
if LANG = LANG_EN
			b "be deleted ?"
endif

			b GOTOXY
			w IconT1x
			b IconT1y
if LANG = LANG_DE
			b "Systemdateien"
endif
if LANG = LANG_EN
			b "Delete"
endif
			b GOTOXY
			w IconT1x
			b IconT1ay
if LANG = LANG_DE
			b "löschen"
endif
if LANG = LANG_EN
			b "Systemfiles"
endif

			b GOTOXY
			w IconT2x
			b IconT1y
if LANG = LANG_DE
			b "Installation"
endif
if LANG = LANG_EN
			b "Continue with"
endif
			b GOTOXY
			w IconT2x
			b IconT1ay
if LANG = LANG_DE
			b "fortsetzen"
endif
if LANG = LANG_EN
			b "installation"
endif

			b GOTOXY
			w IconT2x
			b IconT2y
if LANG = LANG_DE
			b "Setup"
endif
if LANG = LANG_EN
			b "Cancel"
endif
			b GOTOXY
			w IconT2x
			b IconT2ay
if LANG = LANG_DE
			b "abbrechen"
endif
if LANG = LANG_EN
			b "Setup"
endif
			b NULL

;*** Nicht genügend freier Speicher.
:mnuDskSpace		b $02
			w $0000
			b $00

			w Icon_07
			b Icon1x  ,Icon1y
			b Icon_07x,Icon_07y
			w CopyMenu

			w Icon_09
			b Icon1x  ,Icon2y
			b Icon_09x,Icon_09y
			w SlctTarget

;*** Nicht genügend freier Speicher.
:txDskSpace1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Auf dem Ziel-Laufwerk ist nicht genügend Speicher"
endif
if LANG = LANG_EN
			b "There is not enough free space available on the"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "frei um alle Dateien zu entpacken!"
endif
if LANG = LANG_EN
			b "target drive to unpack all the files!"
endif

			b GOTOXY
			w IconT1x
			b IconT1y
if LANG = LANG_DE
			b "Installation forsetzen und nicht"
endif
if LANG = LANG_EN
			b "Continue with installation and copy"
endif
			b GOTOXY
			w IconT1x
			b IconT1ay
if LANG = LANG_DE
			b "alle Dateien kopieren."
endif
if LANG = LANG_EN
			b "only selected files."
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Ein anderes Laufwerk für die"
endif
if LANG = LANG_EN
			b "Choose another target drive and try"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "Installation wählen."
endif
if LANG = LANG_EN
			b "installation again."
endif
			b NULL

;*** Benutzerdefinierte Installation #1.
:mnuCustom		b $06
			w $0000
			b $00

			w Icon_02
			b Icon6x1 ,Icon6y1
			b Icon_02x,Icon_02y
			w CopySystem

			w Icon_03
			b Icon6x2 ,Icon6y1
			b Icon_03x,Icon_03y
			w CopyRBoot

			w Icon_06
			b Icon6x3 ,Icon6y1
			b Icon_06x,Icon_06y
			w SlctDskCopyMode

			w Icon_04
			b Icon6x1 ,Icon6y2
			b Icon_04x,Icon_04y
			w CopyExtras

			w Icon_05
			b Icon6x2 ,Icon6y2
			b Icon_05x,Icon_05y
			w CopyHelpSys

			w Icon_07
			b Icon6x3 ,Icon6y2
			b Icon_07x,Icon_07y
			w CopyCompleted

;*** Benutzerdefinierte Installation.
:txCustom1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Kopieren Sie jetzt die GDOS64-Dateien."
endif
if LANG = LANG_EN
			b "Now copy the GDOS64 system files."
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "Ein '*' markiert benötigte Systemdateien."
endif
if LANG = LANG_EN
			b "A '*' marks required system files."
endif

			b GOTOXY
			w IconT6x1 +46
			b Icon6y1  +8
			b "*"
			b GOTOXY
			w IconT6x1
			b IconT6y1_1
if LANG = LANG_DE
			b "Startdateien"
endif
if LANG = LANG_EN
			b "System files"
endif

			b GOTOXY
			w IconT6x2
			b IconT6y1_1
if LANG = LANG_DE
			b "ReBoot System"
endif
if LANG = LANG_EN
			b "ReBoot system"
endif

			b GOTOXY
			w IconT6x3 +46
			b Icon6y1  +8
			b "*"
			b GOTOXY
			w IconT6x3
			b IconT6y1_1
if LANG = LANG_DE
			b "Laufwerks-"
endif
if LANG = LANG_EN
			b "DiskDriver"
endif
			b GOTOXY
			w IconT6x3
			b IconT6y1_2
if LANG = LANG_DE
			b "treiber"
endif
if LANG = LANG_EN
			b ""
endif

			b GOTOXY
			w IconT6x1
			b IconT6y2_1
if LANG = LANG_DE
			b "Extras"
endif
if LANG = LANG_EN
			b "Extras"
endif
			b GOTOXY
			w IconT6x1
			b IconT6y2_2
if LANG = LANG_DE
			b "(Bilder usw.)"
endif
if LANG = LANG_EN
			b "(Images etc.)"
endif

			b GOTOXY
			w IconT6x2
			b IconT6y2_1
if LANG = LANG_DE
			b "Hilfesystem"
endif
if LANG = LANG_EN
			b "Help system"
endif
			b GOTOXY
			w IconT6x2
			b IconT6y2_2
if LANG = LANG_DE
			b ""
endif
if LANG = LANG_EN
			b ""
endif

			b GOTOXY
			w IconT6x3
			b IconT6y2_1
if LANG = LANG_DE
			b "Installation"
endif
if LANG = LANG_EN
			b "Continue with"
endif
			b GOTOXY
			w IconT6x3
			b IconT6y2_2
if LANG = LANG_DE
			b "fortsetzen"
endif
if LANG = LANG_EN
			b "installation"
endif
			b NULL

;*** Alle Laufwerkstreiber kopieren ?
:mnuCpyDkMod		b $02
			w $0000
			b $00

			w Icon_00
			b Icon1x  ,Icon1y
			b Icon_00x,Icon_00y
			w CopyDskDev

			w Icon_01
			b Icon1x  ,Icon2y
			b Icon_01x,Icon_01y
			w CopySlctDkDv

;*** Alle Laufwerkstreiber kopieren ?
:txCpyDkMod1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Bitte wählen Sie den Modus zum Kopieren der"
endif
if LANG = LANG_EN
			b "Please choose the copy-mode for the"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "einzelnen Laufwerkstreiber:"
endif
if LANG = LANG_EN
			b "disk-driver installation:"
endif

			b GOTOXY
			w IconT1x
			b IconT1y
if LANG = LANG_DE
			b "Alle Laufwerkstreiber kopieren"
endif
if LANG = LANG_EN
			b "Copy all disk-drivers"
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Nur bestimmte Laufwerkstreiber"
endif
if LANG = LANG_EN
			b "Select only specific disk-drivers"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "für die Installation wählen."
endif
if LANG = LANG_EN
			b "for installation."
endif
			b NULL

;*** Startdiskette untersuchen.
:mnuSysCheck		b $02
			w $0000
			b $00

			w Icon_02
			b Icon1x  ,Icon2y
			b Icon_02x,Icon_02y
			w ChkAllSysFiles

			w Icon_12
			b Icon2x  ,Icon2y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Startdiskette untersuchen.
:txSysCheck1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Kopieren der GDOS64-Systemdateien abgeschlossen."
endif
if LANG = LANG_EN
			b "Copying the GDOS64 system files is completed."
endif
			b GOTOXY
			w $0018
			b $64
if LANG = LANG_DE
			b "Die GDOS64-Startdiskette wird jetzt auf fehlende"
endif
if LANG = LANG_EN
			b "Next, the GDOS64 boot disk is checked for missing"
endif
			b GOTOXY
			w $0018
			b $6c
if LANG = LANG_DE
			b "oder optionale Systemdateien untersucht."
endif
if LANG = LANG_EN
			b "or optional system files."
endif

			b GOTOXY
			w $0018
			b $78
if LANG = LANG_DE
			b "Nach der Überprüfung wird GDOS64 installiert und"
endif
if LANG = LANG_EN
			b "After the verification GDOS64 is installed and the"
endif
			b GOTOXY
			w $0018
			b $80
if LANG = LANG_DE
			b "die Startdiskette wird konfiguriert."
endif
if LANG = LANG_EN
			b "boot disk will be configured."
endif
			b GOTOXY
			w $0018
			b $8c
if LANG = LANG_DE
			b "ACHTUNG: Die Installation ist noch nicht beendet!"
endif
if LANG = LANG_EN
			b "WARNING: The installation is not yet completed!"
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Startdiskette"
endif
if LANG = LANG_EN
			b "Check"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "überprüfen"
endif
if LANG = LANG_EN
			b "system files"
endif

			b GOTOXY
			w IconT2x
			b IconT2y
if LANG = LANG_DE
			b "Setup"
endif
if LANG = LANG_EN
			b "Cancel"
endif
			b GOTOXY
			w IconT2x
			b IconT2ay
if LANG = LANG_DE
			b "abbrechen"
endif
if LANG = LANG_EN
			b "Setup"
endif
			b NULL

;*** Installation beenden, keine REU.
:mnuNoREU		b $01
			w $0000
			b $00

			w Icon_12
			b Icon1x  ,Icon2y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Installation beenden, keine REU.
:txNoREU		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Alle Systemdateien, die bei der Installation"
endif
if LANG = LANG_EN
			b "All system files selected during installation"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "ausgewählt wurden, sind kopiert worden."
endif
if LANG = LANG_EN
			b "have been copied."
endif

			b GOTOXY
			w $0018
			b $74
if LANG = LANG_DE
			b "GDOS64 kann nicht installiert werden:"
endif
if LANG = LANG_EN
			b "GDOS64 can not be installed:"
endif
			b GOTOXY
			w $0018
			b $80
if LANG = LANG_DE
			b "Es wurde keine Speichererweiterung erkannt!"
endif
if LANG = LANG_EN
			b "No ram expansion unit detected! Please check"
endif
			b GOTOXY
			w $0018
			b $88
if LANG = LANG_DE
			b "Bitte Kompatibilität von GEOS und REU prüfen!"
endif
if LANG = LANG_EN
			b "the compatibility of GEOS and REU!"
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Setup"
endif
if LANG = LANG_EN
			b "Exit"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "beenden"
endif
if LANG = LANG_EN
			b "Setup"
endif
			b NULL

;*** Alle Dateien vohanden, Update starten.
:mnuAllDone		b $02
			w $0000
			b $00

			w Icon_07
			b Icon1x  ,Icon2y
			b Icon_07x,Icon_07y
			w StartGDUpdate

			w Icon_12
			b Icon2x  ,Icon2y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Alle Dateien vohanden, Update starten.
:txAllDone1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Die Startdiskette wurde überprüft und alle"
endif
if LANG = LANG_EN
			b "The boot disk was checked and all GDOS64"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "GDOS64-Systemdateien sind vorhanden."
endif
if LANG = LANG_EN
			b "system files do exist."
endif

			b GOTOXY
			w $0018
			b $74
if LANG = LANG_DE
			b "GDOS64 kann jetzt installiert werden."
endif
if LANG = LANG_EN
			b "GDOS64 can now be installed."
endif

;--- Hinweis:
;GDOS64 beinhaltet einen DeskTop.
;Der DESKTOP-Hinweis kann entfallen.
;			b GOTOXY
;			w $0018
;			b $80
;if LANG = LANG_DE
;			b "Nach Abschluss der Installation bitte noch die"
;endif
;if LANG = LANG_EN
;			b "After installation is completed please copy the"
;endif
;			b GOTOXY
;			w $0018
;			b $88
;if LANG = LANG_DE
;			b "Datei 'GEODESK' auf die Startdiskette kopieren."
;endif
;if LANG = LANG_EN
;			b "file 'GEODESK' to the bootdisk."
;endif

			b GOTOXY
			w $0018
			b $80
if LANG = LANG_DE
			b "Tipp: Nach der Installation mit <F1> GeoHelp"
endif
if LANG = LANG_EN
			b "Hint: After installation, press <F1> key to"
endif
			b GOTOXY
			w $0018
			b $88
if LANG = LANG_DE
			b "starten um neue Funktionen zu entdecken."
endif
if LANG = LANG_EN
			b "start GeoHelp and discover new features."
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Installation"
endif
if LANG = LANG_EN
			b "Continue with"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "fortsetzen"
endif
if LANG = LANG_EN
			b "installation"
endif

			b GOTOXY
			w IconT2x
			b IconT2y
if LANG = LANG_DE
			b "Setup"
endif
if LANG = LANG_EN
			b "Cancel"
endif
			b GOTOXY
			w IconT2x
			b IconT2ay
if LANG = LANG_DE
			b "abbrechen"
endif
if LANG = LANG_EN
			b "Setup"
endif
			b NULL

;*** Dateien fehlen, Update trotzdem starten.
:mnuMissing		b $03
			w $0000
			b $00

			w Icon_02
			b Icon3x1 ,Icon3y
			b Icon_02x,Icon_02y
			w CopyMenu

			w Icon_07
			b Icon3x2 ,Icon3y
			b Icon_07x,Icon_07y
			w StartGDUpdate

			w Icon_12
			b Icon3x3 ,Icon3y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Dateien fehlen, Update trotzdem starten.
:txMissing1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Auf der GDOS64-Systemdiskette fehlen einige"
endif
if LANG = LANG_EN
			b "The GDOS64 system disk is missing some files."
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "Dateien. Die fehlenden Dateien sind optional"
endif
if LANG = LANG_EN
			b "However, the missing files are optional and"
endif
			b GOTOXY
			w $0018
			b $68
if LANG = LANG_DE
			b "und für eine Startdiskette nicht erforderlich."
endif
if LANG = LANG_EN
			b "not essential for a boot disk."
endif

			b GOTOXY
			w $0018
			b $74
if LANG = LANG_DE
			b "GDOS64 kann jetzt installiert werden."
endif
if LANG = LANG_EN
			b "GDOS64 can be installed now."
endif

			b GOTOXY
			w IconT3x1
			b IconT3y
if LANG = LANG_DE
			b "Dateien"
endif
if LANG = LANG_EN
			b "Add extra"
endif
			b GOTOXY
			w IconT3x1
			b IconT3ay
if LANG = LANG_DE
			b "kopieren"
endif
if LANG = LANG_EN
			b "files"
endif
			b GOTOXY
			w IconT3x2
			b IconT3y
if LANG = LANG_DE
			b "Installation"
endif
if LANG = LANG_EN
			b "Continue with"
endif
			b GOTOXY
			w IconT3x2
			b IconT3ay
if LANG = LANG_DE
			b "fortsetzen"
endif
if LANG = LANG_EN
			b "installation"
endif
			b NULL

;*** Dateien fehlen, zurück zum Menü.
:mnuCopyMore		b $02
			w $0000
			b $00

			w Icon_02
			b Icon1x  ,Icon2y
			b Icon_02x,Icon_02y
			w CopyMenu

			w Icon_12
			b Icon2x  ,Icon2y
			b Icon_12x,Icon_12y
			w Exit2DT

;*** Dateien fehlen, zurück zum Menü.
:txCopyMore1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Auf der GDOS64-Startdiskette fehlen Dateien, die"
endif
if LANG = LANG_EN
			b "The GDOS64 system disk is missing some files"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "für den Systemstart notwendig sind."
endif
if LANG = LANG_EN
			b "that are necessary for the system boot."
endif

			b GOTOXY
			w $0018
			b $6e
if LANG = LANG_DE
			b "GDOS64 kann damit nicht gestartet werden!"
endif
if LANG = LANG_EN
			b "GDOS64 cannot be started from this disk!"
endif
			b GOTOXY
			w $0018
			b $80
if LANG = LANG_DE
			b "Bitte mit SETUP fehlende Systemdateien ergänzen."
endif
if LANG = LANG_EN
			b "Please add missing system files using SETUP."
endif

			b GOTOXY
			w IconT1x
			b IconT2y
if LANG = LANG_DE
			b "Systemdateien"
endif
if LANG = LANG_EN
			b "Copy"
endif
			b GOTOXY
			w IconT1x
			b IconT2ay
if LANG = LANG_DE
			b "kopieren"
endif
if LANG = LANG_EN
			b "system files"
endif

			b GOTOXY
			w IconT2x
			b IconT2y
if LANG = LANG_DE
			b "Setup"
endif
if LANG = LANG_EN
			b "Cancel"
endif
			b GOTOXY
			w IconT2x
			b IconT2ay
if LANG = LANG_DE
			b "abbrechen"
endif
if LANG = LANG_EN
			b "Setup"
endif
			b NULL
