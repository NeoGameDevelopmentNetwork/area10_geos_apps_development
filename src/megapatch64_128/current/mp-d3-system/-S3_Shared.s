; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Programm initialisieren.
;******************************************************************************
;*** Zeiger auf Tastatur-Abfrage für Programm-Abbruch.
:MainMenu		LoadW	keyVector,TestExitKey

;--- Aktuelles Laufwerk zwischenspeichern.
			lda	curDrive		;Startlaufwerk als Vorgabe für
			sta	SourceDrv		;Quell-/Ziellaufwerk.
			sta	TargetDrv

;******************************************************************************
;*** Programm initialisieren.
;******************************************************************************
;*** Setup-Hauptmenu.
if Flag64_128 = TRUE_C64
:RestartSetup		jsr	ClearScreen		;Bildschirm löschen.
endif
if Flag64_128 = TRUE_C128
:RestartSetup		bit	graphMode		;Grafikmodus testen.
			bpl	:40			;>40 Zeichen ?
			lda	#2			;Ja, 80 Zeichenmodus.
			jsr	VDC_ModeInit		;VDC-Farbmodus GEOS2.x aktivieren.
::40			jsr	ClearScreen		;Bildschirm löschen.
endif

			jsr	AddOnWin		;Menü-Fenster zeichnen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?
			LoadW	r0,InfoText0		;Menü ausgeben.
			jsr	PutString

;--- Gepacktes MP3-Archiv analysieren.
			lda	#$01
::50			sta	ExtractFileType		;Dateigruppe speichern.

			jsr	ClrInfoScreen		;Infobereich löschen.

			jsr	FindStartMP		;Archivdatei suchen.
			txa				;Datei gefunden ?
			beq	:52			; => Ja, weiter...
			cpx	#$0c			;CANCEL-Error ?
			beq	:51a			; => Ja, Abbruch...
::51			jmp	ANALYZE_ERROR		;Fehler ausgeben, Ende...
::51a			jmp	ExitToDeskTop		;Zurück zum DeskTop.

::52			LoadW	r0 ,InfoText0c		;Name der Archiv-Teildatei ausgeben.
			jsr	PutString

			LoadW	r0,FNameSETUP
			jsr	PutString

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	ExtractFileType
			asl
			tax
			lda	fileHeader  +2		;Erster Sektor "Infodaten".
			sta	PatchInfoTS -2,x
			lda	fileHeader  +3
			sta	PatchInfoTS -1,x
			lda	fileHeader  +4		;Erster Sektor "Patchdaten".
			sta	PatchDataTS -2,x
			lda	fileHeader  +5
			sta	PatchDataTS -1,x

;--- "Archiv testen".
			LoadW	r0 ,InfoText0a		;"Archiv wird untersucht..."
			jsr	PutString

			jsr	LoadStartMPinfo		;Archiv-Informationen einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	AddFileSize		;Dateigrößen addieren.

;--- CRC-Prüfsumme testen.
			lda	ExtractFileType
			asl
			tay
			lda	PatchDataTS -2,y
			ldx	PatchDataTS -1,y
			jsr	PatchCRC		;Prüfsumme für Patchdaten
			txa				;erstellen. Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			CmpW	a0,CRC_CODE		;Prüfsummenfehler ?
			beq	:55			; => Nein, weiter...
			jmp	CRCFILE_ERROR		;Fehlermeldung ausgeben.

::55			jsr	AnalyzeFileDAT		;Archiv untersuchen. Rückkehr nur
							;wenn Archiv ohne Fehler.

			lda	ExtractFileType		;Zeiger auf nächste Gruppe.
			clc
			adc	#$01
			cmp	#$05 +1			;Alle Gruppen untersucht?
			bcs	:57			; => Nein, weiter...
			jmp	:50

::57			jsr	AddOnWin		;Menü-Fenster zeichnen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?
			LoadW	r0,Icon_Tab0		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text0
			jmp	PutString

;******************************************************************************
;*** Ziel-Laufwerk wählen.
;******************************************************************************
;*** Ziel-Laufwerk auswählen.
:SlctTarget		jsr	AddOnWin		;Menü-Fenster zeichnen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?
			LoadW	r0,Icon_Tab1		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text1
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
:SlctInstallMode	jsr	AddOnWin		;Menü-Fenster zeichnen.
			jsr	CheckREU		;Speichererweiterung vorhanden ?
			LoadW	r0,Icon_Tab2		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text2
			jmp	PutString

;*** Alle Dateien entpacken.
:CopyAllFiles		lda	#$00			; => Komplette Installation.
			b $2c
:CopySlctFiles		lda	#$ff			; => Teilweise Installation.
			sta	CopyMode

;*** Ziel-Laufwerk überprüfen.
:FindSysFiles		lda	#< Inf_ChkDkSpace
			ldx	#> Inf_ChkDkSpace
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			jsr	GetSysFiles		;Suche nach Systemdateien.
			lda	a1L			;Dateien bereits vorhanden ?
			beq	CopyFiles		; => Nein, weiter...

			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab11		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text11
			jmp	PutString		;Menü: "Ziel-Dateien löschen ?"

;*** Vorhandene Systemdatein löschen.
:DeleteSysFiles		lda	#< Inf_DelSysFiles
			ldx	#> Inf_DelSysFiles
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			lda	#$00			;Flag für "Alle Dateien".
			sta	ExtractFileType
			jsr	SetVecGroupData

::51			jsr	DefName_a6		;Dateiname definieren.

			LoadW	r0,FNameBuffer
			jsr	DeleteFile		;Datei löschen.

			AddVBW	4,a6			;Zeiger auf nächste Datei.

			inc	EntryPosInArchiv
			lda	EntryPosInArchiv
			cmp	MaxMP3FData		;Alle Dateien untersucht?
			bne	:51			; => Nein, weiter...

;******************************************************************************
;*** Einzelne Programmgruppe kopieren.
;******************************************************************************
;*** Speicher auf Ziel-Laufwerk überprüfen.
:CopyFiles		lda	CopyMode		;Alle Dateien kopieren ?
			bne	CopyMenu		; => Nein, weiter...

			lda	#$00
			jsr	ChkDskSpace		;Speicherplatz überprüfen.
			txa				;Genügend Speicher frei ?
			beq	:51			; => Ja, weiter...

			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab3		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text3
			jmp	PutString		;Menü: "Nicht genügend Speicher!"

::51			jsr	CopySystemFile		;Kopieren: System-Dateien.
			jsr	CopyRBootFile		;Kopieren: ReBoot-Dateien.
			jsr	CopyBackScrnFile	;Kopieren: Bildschirmhintergrund.
			jsr	CopyScrSaverFile	;Kopieren: Bildschirmschoner.
			jsr	CopyDskDevFile		;Kopieren: Laufwerkstreiber.

			lda	ramExpSize		;Speichererweiterung vorhanden ?
			bne	RunMP3Menu		; => Ja, weiter...

			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab8a		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text8a		;Hinweis ausgeben:
			jmp	PutString		;Keine Speichererweiterung erkannt.

;*** Installationsmenü ausgeben.
:RunMP3Menu		jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab7		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text7
			jmp	PutString

;*** Auswahl der zu kopierenden Dateien.
:CopyMenu		jsr	ClearCurFName
			jsr	AddOnWin		;Menü-Fenster zeichnen.
			jsr	PrntCurDkSpace
			jsr	PrintMP3Size
			LoadW	r0,Icon_Tab4		;Menü ausgeben.
			jsr	DoColorMIcons
			LoadW	r0,Icon_Text4
			jmp	PutString		;Menü: "Dateien auswählen"

;*** System-Dateien kopieren..
:CopySystem		jsr	CopySystemFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
:CopySystemFile		lda	#$ff
			sta	CopyFlgSystem
			lda	#< Inf_CopySystem
			ldx	#> Inf_CopySystem
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$01			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** ReBoot-Dateien kopieren..
:CopyRBoot		jsr	CopyRBootFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
:CopyRBootFile		lda	#$ff
			sta	CopyFlgRBOOT
			lda	#< Inf_CopyRBoot
			ldx	#> Inf_CopyRBoot
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$02			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Hintergrundbilder kopieren.
:CopyBackScrn		jsr	CopyBackScrnFile	;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
:CopyBackScrnFile	lda	#$ff
			sta	CopyFlgBackScrn
			lda	#< Inf_CopyBkScr
			ldx	#> Inf_CopyBkScr
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$04			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Bildschirmschoner kopieren.
:CopyScrSaver		jsr	CopyScrSaverFile	;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
:CopyScrSaverFile	lda	#$ff
			sta	CopyFlgScrSave
			lda	#< Inf_CopyScrSv
			ldx	#> Inf_CopyScrSv
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$05			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;******************************************************************************
;*** Einzelne Programmgruppe kopieren.
;******************************************************************************
;*** Laufwerkstreiber kopieren.
:CopyDskDvMenu		jsr	AddOnWin		;Menü-Fenster zeichnen.
			jsr	PrntCurDkSpace
			LoadW	r0,Icon_Tab5		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text5
			jmp	PutString

;*** Alle Laufwerkstreiber kopieren.
:CopyDskDev		jsr	CopyDskDevFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
:CopyDskDevFile		lda	#$ff
			sta	CopyFlgDskDrive
			lda	#< Inf_CopyDskDrv
			ldx	#> Inf_CopyDskDrv
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$03			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Zu kopierende Laufwerkstreiber wählen.
:CopySlctDkDv		lda	#$03			;Systemdateien aus Archiv
			sta	ExtractFileType
			jsr	FindStartMP
			txa
			beq	:50
			cpx	#$0c			;CANCEL-Error ?
			beq	:49a			; => Ja, Abbruch...
::49			jmp	EXTRACT_ERROR		;Fehlermeldung ausgeben.
::49a			jmp	ExitToDeskTop		;Zurück zum DeskTop.

::50			jsr	LoadStartMPinfo		;Archiv-Informationen einlesen.
			txa				;Diskettenfehler ?
			bne	:49			; => Ja, Abbruch...

			jsr	GetPackerCode		;Packer-Kennbyte einlesen.
			txa				;Diskettenfehler ?
			bne	:49			; => Ja, Abbruch...

			jsr	GetDskDrvInfo		;Informationen aus Datei mit
							;Laufwerkstreibern einlesen.

			ldy	#$00			;VLIR-Informationen der Treiber-
::51			lda	DskInfTab+2*254,y	;Datei zwischenspeichern.
			sta	DskDvVLIR    +2,y
			sta	DskDvVLIR_org+2,y
			iny
			cpy	#254
			bcc	:51

			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab6		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text6
			jsr	PutString

			LoadB	a0L,1
			LoadW	a1 ,DskInf_Names +17

;--- Aktuellen Treiber anzeigen und Abfrage starten.
:PrntCurDkDev		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$71,$7b
			w	$0020 ! DOUBLE_W
			w	$00ff ! DOUBLE_W ! ADD1_W

			MoveW	a1 ,r0
			LoadW	r11,$0020 ! DOUBLE_W
			LoadB	r1H,$7a
			jsr	PutString

			LoadW	r0,Icon_Text6a
			jmp	PutString

;--- Treiber nicht kopieren.
:ReSlctDkDrv		ldy	a0L
			lda	#$00
			sta	DskInf_Modes,y

;--- Zeiger auf nächste Datei.
:NextDkDrv		AddVBW	17,a1			;Zeiger auf nächsten Treiber.

			inc	a0L
			CmpBI	a0L,64			;Alle Treiber überprüft ?
			beq	:51			; => Ja, Ende...

			ldy	#$00
			lda	(a1L),y			;Noch ein Treiber in Tabelle ?
			bne	PrntCurDkDev		; => Ausgeben und Abfrage starten.
::51			jmp	ModifyDriver		;Treiber kopieren.

;******************************************************************************
;*** Einzelne Laufwerkstreiber kopieren.
;******************************************************************************
;*** Informationsdatei packen & korrigieren.
:ModifyDriver		lda	#$ff
			sta	CopyFlgDskDrive
			lda	#< Inf_CopyDskDrv
			ldx	#> Inf_CopyDskDrv
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			lda	#< DskInf_Modes		;Vektor auf Laufwerkstyp.
			sta	r0L
			sta	r1L
			lda	#> DskInf_Modes
			sta	r0H
			sta	r1H
			lda	#< DskInf_VlirSet	;Vektor auf VLIR-Zeiger.
			sta	r2L
			sta	r3L
			lda	#> DskInf_VlirSet
			sta	r2H
			sta	r3H
			lda	#< DskInf_Names		;Vektor auf Treibernamen.
			sta	r4L
			sta	r5L
			lda	#> DskInf_Names
			sta	r4H
			sta	r5H

			ldy	#$00
			sty	r6L			;Zeiger auf ersten Eintrag in neuer
			sty	r6H			;und alter Tabelle setzen.
			beq	:52

::51			ldy	#$00
			lda	(r0L),y			;Treiber übernehmen ?
			beq	:54			; => Nein, weiter...

::52			lda	(r0L),y			;Informationen für aktuellen
			sta	(r1L),y			;Treiber in neue Liste kopieren.
			lda	(r2L),y
			sta	(r3L),y
			iny
			lda	(r2L),y
			sta	(r3L),y

			ldy	#$00
::53			lda	(r4L),y
			sta	(r5L),y
			iny
			cpy	#17
			bcc	:53

			ldx	#r1L
			jsr	Pos2NxEntry
			inc	r6H

::54			ldx	#r0L
			jsr	Pos2NxEntry
			inc	r6L
			lda	r6L
			cmp	#64			;Alle Treiber-Einträge kopiert ?
			bcc	:51			; => Nein, weiter...
::55			lda	r6H			;Den Rest der neuen Treiber-
			cmp	#64			;Tabelle löschen.
			beq	:57

			ldy	#$00
			tya
			sta	(r1L),y
			sta	(r3L),y
			iny
			sta	(r3L),y
			dey
::56			sta	(r5L),y
			iny
			cpy	#17
			bcc	:56

			ldx	#r1L
			jsr	Pos2NxEntry
			inc	r6H
			jmp	:55
::57			jmp	PrepareCopyDkDv		;Laufwerkstreiber kopieren.

;*** Zeiger auf nächsten Eintrag.
:Pos2NxEntry		inc	zpage +0,x
			bne	:51
			inc	zpage +1,x

::51			lda	#2
			jsr	:52
			lda	#17
::52			sta	:53 +1
			inx
			inx
			inx
			inx
			lda	zpage +0,x
			clc
::53			adc	#$02
			sta	zpage +0,x
			bcc	:54
			inc	zpage +1,x
::54			rts

;******************************************************************************
;*** Einzelne Laufwerkstreiber kopieren.
;******************************************************************************
;*** Informationen für Kopiervorgang aufbereiten.
:PrepareCopyDkDv	ldy	#$04
::51			lda	DskDvVLIR_org,y		;Nicht verfügbare VLIR-Datensätze
			beq	:52			;in Original-Treiberdatei in der
			lda	#$00			;Kopie ebenfalls als "Nicht vor-
			sta	DskDvVLIR    ,y		;handen" markieren.
			iny
			lda	#$ff
			sta	DskDvVLIR    ,y
			dey
::52			iny
			iny
			bne	:51

			ldy	#$02
			sty	r0L
::53			lda	DskInf_VlirSet ,y	;Verfügbare VLIR-Datensätze in
			beq	:54			;Original-Treiberdatei in der
			asl				;Kopie ebenfalls als "Verfügbar"
			tax				;markieren.
			lda	DskDvVLIR_org+2,x
			sta	DskDvVLIR    +2,x
			lda	DskDvVLIR_org+3,x
			sta	DskDvVLIR    +3,x
			iny
			cpy	#126			;Max. 63 Treiber möglich.
			bcc	:53

::54			jsr	ExtractDskDrv		;Laufwerkstreiber entpacken.
			jmp	CopyMenu		;zurück zum Hauptmenü.
::55			jmp	EXTRACT_ERROR

;******************************************************************************
;*** Vorhandene Installation suchen.
;******************************************************************************
;*** Systemdateien suchen.
:CheckFiles		lda	#< Inf_InstallMP
			ldx	#> Inf_InstallMP
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			jsr	GetSysFiles		;Systemdateien suchen.

;--- Alle Dateien kopiert.
			lda	a1L
			cmp	#MP3_Files		;Alle Dateien verfügbar ?
			bne	:51			; => Nein, weiter...
			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab8		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text8
			jmp	PutString

;--- Nicht alle Dateien kopiert, aber alle Systemdateien verfügbar.
::51			lda	a1H			;Fehlen Systemdateien ?
			bne	:52			; => Ja, weiter...
			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab9		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text9
			jmp	PutString

;--- Nicht alle Dateien kopiert, einige Systemdateien fehlen.
::52			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,Icon_Tab10		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,Icon_Text10
			jmp	PutString

;*** Systemdateien suchen.
:GetSysFiles		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.

			lda	#$00
			sta	a1L			;Zähler für kopierte Dateien.
			sta	a1H			;Zähler für fehlende Systemdateien.

			sta	ExtractFileType		;Flag für "Alle Dateien".
			jsr	SetVecGroupData

::51			inc	a1L
			jsr	DefName_a6

			LoadW	r6,FNameBuffer
			jsr	FindFile		;Systemdatei suchen.
			txa				;Datei auf Diskette gefunden ?
			beq	:52			; => Ja, weiter...

			dec	a1L			;Anzahl kopierte Dateien -1.

;--- Änderung: 17.07.18/M.Kanet
;Im bisherigen Code wurde der Zähler für die aktuelle Datei
;dazu verwendet einen Zeiger in :a6 auf den Dateieintrag zu
;berechnen. Das war falsch, da :a6 bei jedem Durchlauf auf den
;jeweils nächsten Dateieintrag gesetzt wird.
			ldy	#3
			lda	(a6L),y			;Fehlt eine Systemdatei ?
			bne	:52			; => Nein, weiter...
			inc	a1H			; => Ja, Zähler korrigieren.

::52			AddVBW	4,a6			;Zeiger auf nächste Datei.

			inc	EntryPosInArchiv
			lda	EntryPosInArchiv
			cmp	MaxMP3FData		;Alle Dateien untersucht?
			bne	:51			; => Nein, weiter...
			rts

;*** MegaPatch installieren.
:InstallMP		lda	#$00			;Tastaturabfrage löschen.
			sta	keyVector +0
			sta	keyVector +1

			lda	TargetDrv		;Ziel-Diskette öffnen.
			jsr	SetDevice
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	SetSerialNumber		;Aktuelle GEOS-ID übernehmen.

			jsr	ClearScreen
			jsr	AddOnWin		;Menü-Fenster zeichnen.
			LoadW	r0,InfoText1		;Infomeldung ausgeben.
			jsr	PutString

			lda	#>ExitToDeskTop-1	;Rücksprungadresse bereitstellen.
			pha				;(Wird ausgeführt falls Disketten-
			lda	#<ExitToDeskTop-1	; fehler auftritt).
			pha
			LoadB	r0L,%00000000
			LoadW	r6 ,FNameMP3
			jmp	GetFile			;Startprg. laden und starten.

::51			jsr	DiskError		;Diskettenfehler ausgeben.
			jmp	ExitToDeskTop		;Zurück zum DeskTop.

;******************************************************************************
;*** GEOS-ID kopieren.
;******************************************************************************
;*** Serien-ID anpassen.
:SetSerialNumber	LoadW	r6,File_MP3_1
			jsr	FindFile		;Systemdatei mit GEOS-ID suchen.
			txa				;Diskettenfehler ?
			bne	:52			; => Nein, weiter...

			lda	#< SerialNumber
			sec
			sbc	#< DISK_BASE -2		;2 Bytes für Dummy-WORD am Beginn
			sta	r10L			;der Startdatei abziehen.
			lda	#> SerialNumber		;(BASIC-Loader!)
			sbc	#> DISK_BASE -2
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
::52			jmp	GEOS_ID_ERROR

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

;******************************************************************************
;*** Laufwerksinformationen ausgeben.
;******************************************************************************
;*** Ausgabe der verfügbaren Laufwerke für die Ziel-Auswahl.
;    Laufwerk A: bis D: ausgeben.
:PrntDriveA		ldx	#$08
			b $2c
:PrntDriveB		ldx	#$09
			b $2c
:PrntDriveC		ldx	#$0a
			b $2c
:PrntDriveD		ldx	#$0b
;--- Änderung: 12.07.18/M.Kanet
;Der ursprüngliche Code an dieser Stelle zum setzen der Cursor-Position
;zur Ausgabe des Laufwerks- und Diskettennamens wurde in eine eigene
;Routine ausgelagert um mehrere Code-Instanzen zusammenzufassen.
			jsr	SetDrvTextPos

;--- aktuelles Laufwerk ausgeben.
:PrintDrive		lda	driveType -8,x		;Laufwerk verfügbar ?
			bne	:51			; => Ja, weiter...
			LoadW	r0,NoDrvText		;Text "Kein Laufwerk" ausgeben.
			jsr	PutString
			jmp	:58

::51			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...

			ldx	curDrive
			jsr	SetDrvTextPos
			LoadW	r0,NoDskText		;Text "Keine Diskette" ausgeben.
			jsr	PutString
			jmp	:58

::52			ldx	#r0L			;Diskettenname ausgeben.
			jsr	GetPtrCurDkNm

			ldx	curDrive
			jsr	SetDrvTextPos

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
::56			jsr	PutChar
			pla
			clc
			adc	#$01
			cmp	#16
			bcc	:53

::57			LoadW	r5,curDirHead		;Verfügbaren Speicherplatz
			jsr	CalcBlksFree		;berechnen.
			ldx	#r4L
			ldy	#$02
			jsr	DShiftRight

			ldx	curDrive
			jsr	SetDrvTextPos
			lda	r1H
			clc
			adc	#10
			sta	r1H
			MoveW	r4,r0			;Speicherplatz ausgeben.
			lda	#%11000000
			jsr	PutDecimal
			LoadW	r0,KFreeText		;Text "Kb frei" ausgeben.
			jsr	PutString

::58			LoadW	rightMargin,319		;Rechten Rand zurücksetzen.
if Flag64_128 = TRUE_C128
			bit	graphMode		;80-Zeichen-Modus?
			bpl	:59			;Nein, weiter...
			sec
			rol	rightMargin +0		;Rechten Rand verdoppeln und
			rol	rightMargin +1		;1 addieren (DOUBLE_W!ADD1_W)
endif
::59			rts

;*** Koordinaten für Textausgabe setzen.
:SetDrvTextPos		lda	YPos  -8,x		;Position für Textausgabe.
			sta	r1H
			lda	XPosL -8,x
			sta	r11L
			lda	XPosH -8,x
			sta	r11H
			lda	WinMaxXL  -8,x		;Rechten Rand definieren.
			sta	rightMargin +0		;Damit wird verhindert das z.B.
			lda	WinMaxXH  -8,x		;die Anzeige des Diskettennamens
			sta	rightMargin +1		;den rechten Rand überschreitet.
if Flag64_128 = TRUE_C128
			bit	graphMode		;80-Zeichen-Modus?
			bpl	:1			;Nein, weiter...
			sec
			rol	rightMargin +0		;Rechten Rand verdoppeln und
			rol	rightMargin +1		;1 addieren (DOUBLE_W!ADD1_W)
endif
::1			rts

;******************************************************************************
;*** Freien Diskettenspeicher ausgeben.
;******************************************************************************
;*** Freien Speicher ausgeben.
:PrntCurDkSpace		jsr	GetDskSpace		;Freien Diskettenspeicher
							;berechnen.

			jsr	ResetInfoArea		;Farbe für Hinweis setzen.

			LoadW	r0,InfoText2
			jsr	PutString
			MoveW	TargetFreeB,r0
			lda	#%11000000
			jsr	PutDecimal		;Freien Speicher ausgeben.

			lda	#"K"
			jmp	PutChar

;*** Freien Speicher prüfen.
:ChkDskSpace		jsr	GetDskSpace		;Freien Diskettenspeicher
							;berechnen.
			lda	#$00
			sta	r13L
			sta	r13H
			ldx	#$05
::51			cpx	#$03			;Laufwerkstreiber ?
			beq	:52			; => Ja, übergehen.
			lda	r13L
			clc
			adc	PatchSizeKB -1,x
			sta	r13L
			bcc	:52
			inc	r13H
::52			dex
			bne	:51

			AddVBW	3*6,r13			;18K für 1541,71,81,RAM41,71,81
			MoveW	r13,TargetNeedB		;Minimal-Treiber addieren.

			ldx	#$00
			lda	TargetNeedB +1
			cmp	TargetFreeB +1
			bne	:53
			lda	TargetNeedB +0
			cmp	TargetFreeB +0
::53			bcc	:54
			ldx	#$02
::54			rts

;*** Größe der entpackten Dateien berechnen für "teilw. Installation".
:AddFileSize		lda	#$00
			sta	r13L
			sta	r13H
			sta	r14L

			LoadW	r15,FNameTab1

::53			ldy	#$1e			;Dateigröße addieren.
			lda	(r15L),y
			clc
			adc	r13L
			sta	r13L
			iny
			lda	(r15L),y
			adc	r13H
			sta	r13H

			AddVBW	32,r15

			ldx	ExtractFileType
			inc	r14L
			lda	r14L
			cmp	FilesInGroup ,x
			bcc	:53

			ldx	#r13L			;Anzahl Blocks in KByte umrechnen.
			ldy	#$02
			jsr	DShiftRight

			ldx	ExtractFileType
			lda	r13L
			sta	PatchSizeKB -1,x
			rts

;*** Freien Speicher einlesen.
:GetDskSpace		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			LoadW	r5,curDirHead
			jsr	CalcBlksFree		;Freien Speicher berechnen.
			ldx	#r4L
			ldy	#$02
			jsr	DShiftRight		;Freien Speicher in KByte
			MoveW	r4,TargetFreeB		;umrechnen.
			rts

;******************************************************************************
;*** Größe der Dateigruppen ausgeben.
;******************************************************************************
;*** Benutzerdefinierte Installation.
;    Benötigten Speicher für Programmgruppen anzeigen.
:PrintMP3Size		LoadW	a1,Icon_Tab4 +6		;Zeiger auf Icon-Tabelle.

			lda	#$01
			sta	a2L
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
			jsr	DShiftLeft

			ldy	#$01
			lda	(a1L),y
			clc
			adc	#$14
			sta	r1H
if Flag64_128 = TRUE_C128
			lda	r11H
			ora	#%10000000		;Double-Bit einblenden
			sta	r11H
endif
			lda	#" "
			jsr	PutChar

			ldx	a2L
			lda	PatchSizeKB -1,x
			sta	r0L
			LoadB	r0H,$00			;Größe der Dateigruppe
			lda	#%11000000		;ausgeben.
			jsr	PutDecimal

			lda	#"K"			;"K"(byte) ausgeben.
			jsr	PutChar

			AddVBW	8,a1
			inc	a2L			;Nächste Dateigruppe.
			CmpBI	a2L,6			;Alle Dateigruppen bearbeitet ?
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
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W
			b	%11111111
			jsr	Frame

			LoadW	r0,ExtractFName
			jsr	PutString

			LoadW	r0,FNameBuffer
			jmp	PutString

;*** Aktuelle Datei von Bildschirm löschen.
:ClearCurFName		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$a8,$bf
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W
			rts

;*** Dateiname definieren.
:DefName_a6		ldy	#$00			;Zeiger auf Dateiname berechnen.
			lda	(a6L),y
			sec
			sbc	#$05
			sta	a7L
			iny
			lda	(a6L),y
			sbc	#$00
			sta	a7H

:DefName		ldy	#$05			;Dateiname aus Verzeichniseintrag
::51			lda	(a7L)      ,y		;einlesen dateiname kopieren.
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

;******************************************************************************
;*** Startposition für Dateien in Archiv ermitteln.
;******************************************************************************
;*** Gepacktes MP3-Archiv analysieren.
:AnalyzeFileDAT		LoadW	r0,InfoText0b		;Menü ausgeben.
			jsr	PutString

			jsr	GetPackerCode
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	ANALYZE_ERROR

::52			lda	#$00			;Packer-Information löschen.
			sta	firstByte
			sta	PackedByteCode
			sta	PackedBytCount
			sta	PackedBytes
			sta	WrTmpSekCount +0
			sta	WrTmpSekCount +1
			lda	#$02
			sta	BytesInTmpWSek
			lda	#$ff
			sta	PutByteToDisk

			jsr	SetVecTopArchiv		;Zeiger auf Tabelle mit Dateinamen.

			lda	ExtractFileType
			asl
			tax
			lda	PackFileVecAdr -2,x
			sta	a5L
			lda	PackFileVecAdr -1,x
			sta	a5H

;--- Startadresse aktuelle Datei speichern.
:AnalyzeNxFile		lda	EntryPosInArchiv	;Zeiger auf aktuelle Datei.
			asl
			asl
			tay
			lda	r1L			;Startadresse des ersten Sektors
			sta	(a5L),y			;zwischenspeichern.
			iny
			lda	r1H
			sta	(a5L),y
			iny
			lda	Vec2SourceByte		;Zeiger auf Byte innerhalb Sektor
			sta	(a5L),y			;zwischenspeichern.
			iny
			lda	#$00
			sta	(a5L),y			;Dummy-Byte löschen.
			sta	WrTmpSekCount +0
			sta	WrTmpSekCount +1
			jsr	InitTargetFile
			txa
			beq	AnalyzeNxByte
			jmp	ANALYZE_ERROR

;--- Bytes aus Archiv entpacken.
:AnalyzeNxByte		jsr	GetNxDataByte		;Nächstes Datenbyte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:52			; => Ja, Ende...
			cpx	#$00			;Diskettenfehler ?
			beq	:51			; => Ja, Abbruch...
			jmp	ANALYZE_ERROR

::51			jsr	PutBytDskDrv		;Byte in Zieldatei speichern.

;--- Ende aktuelle Datei erreicht ?
			lda	WrTmpSekCount +1
			cmp	SizeSourceFile+1
			bne	AnalyzeNxByte
			lda	WrTmpSekCount +0
			cmp	SizeSourceFile+0	;Alle Bytes kopiert ?
			bne	AnalyzeNxByte		; => Nein, weiter...

;--- Zeiger auf nächste Datei.
			jsr	SetVecNxEntry		;Alle Dateien analysiert ?
			bne	AnalyzeNxFile		; => Weiter mit nächstem Byte.

;--- Ende erreicht.
::52			rts

;******************************************************************************
;*** Datei aus MP-Archiv entpacken.
;*** EntryPosInArchiv	= Datei-Nr.
;*** ExtractFileType	= Dateityp.
;*** PackedByteCode	= Gepackte Daten: Bytewert.
;*** PackedBytCount	= Gepackte Daten: Anzahl Bytes.
;*** BytesInCurWSek	= Anzahl Bytes in aktuellem Sektor für Ziel-Datei.
;*** BytesInLastSek	= Anzahl Bytes in letztem Sektor der Ziel-Datei.
;*** SizeSourceFile	= Anzahl Sektoren für Ziel-Datei.
;*** WriteSekCount	= Zähler geschriebene Sektoren.
;*** a7			= Zeiger auf Tabelle mit Dateieinträgen.
;*** a8			= Zeiger auf Speicher für Treiberdatei-Info.
;*** a9			= Zeiger auf Sektoren-Tabelle.
;******************************************************************************
:ExtractFiles		sta	ExtractFileType
			jsr	FindStartMP
			txa
			bne	:50

			jsr	LoadStartMPinfo
			txa
			bne	:51

			jsr	GetPackerCode
			txa
			bne	:51

			lda	ExtractFileType
			asl
			tax
			lda	PackFileVecAdr -2,x
			sta	a5L
			lda	PackFileVecAdr -1,x
			sta	a5H

			lda	ExtractFileType
			jsr	ExtractCurFile
			txa
			beq	:51
::50			cpx	#$0c			;CANCEL-Error ?
			beq	:50a			; => Ja, Abbruch...
			jmp	EXTRACT_ERROR		;Fehlermeldung ausgeben.
::50a			jmp	ExitToDeskTop		;Zurück zum DeskTop.
::51			rts

;*** Aktuelle Datei entpacken.
:ExtractCurFile		sta	ExtractFileType

			jsr	SetVecTopArchiv		;Zeiger auf Tabelle mit Dateinamen.

::51			lda	EntryPosInArchiv	;Entspricht Datei der geforderten
			asl				;Dateigruppe ?
			asl
			tay
			iny
			iny
			lda	(a6L),y
			cmp	ExtractFileType
			bne	:52			; => Nein, weiter...
			txa
			jsr	Decode1File		;Datei entpacken.
			txa				;Diskettenfehler ?
			bne	:53			; => Nein, weiter...

::52			jsr	SetVecNxEntry		;Alle Dateien analysiert ?
			bne	:51			; => Nein, weiter...
			ldx	#$00
::53			rts

;*** Datei entpacken.
;    Übergabe:		a7               = Zeiger auf Dateiinformationen.
;			EntryPosInArchiv  = Datei-Nr.
:Decode1File		jsr	DeleteTarget		;Ziel-Datei löschen.

			jsr	AllocFileSek		;Erforderlichen Speicher belegen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	SetVec1stByte		;Zeiger auf erstes Byte.

			LoadW	a9,FreeSekTab		;Zeiger auf Tabelle mit freien
			jsr	DecodeNxByte		;Sektoren und Datei entpacken.
			jmp	CreateDirEntry
::51			rts

;*** Verzeichnis-Eintrag erstellen.
:CreateDirEntry		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			LoadB	r10L,$00
			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			tya
			tax
			lda	#$81			;Dateityp SEQ.
			sta	diskBlkBuf,x
			inx
			lda	Data1stSek +0		;Ersten Datensektor setzen.
			sta	diskBlkBuf,x
			inx
			lda	Data1stSek +1
			sta	diskBlkBuf,x
			inx
			ldy	#$05			;Dateiname kopieren.
::51			lda	(a7L),y
			sta	diskBlkBuf,x
			inx
			iny
			cpy	#$1e
			bcc	:51

			lda	WriteSekCount +0	;Größe der gepackten Datei
			sta	diskBlkBuf,x		;festlegen.
			inx
			lda	WriteSekCount +1
			sta	diskBlkBuf,x
			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Eintrag schreiben.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...
			jmp	Convert1File		;Datei nach GEOS wandeln.
::52			rts

;*** Packer-Kennbyte einlesen.
:GetPackerCode		jsr	OpenSourceDrive		;Quell-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			lda	ExtractFileType
			asl
			tax
			lda	PatchDataTS -2,x
			sta	r1L
			lda	PatchDataTS -1,x
			sta	r1H
			lda	#$02
			sta	Vec2SourceByte
			jsr	GetSek_dskBlkBuf	;Ersten Sektor laden und
			jsr	GetNxPackBytSrc		;Packer-Code einlesen.
			sta	PackerCodeByte
::51			rts

;******************************************************************************
;*** Datei aus MP-Archiv entpacken.
;******************************************************************************
:DecodeNxByte		jsr	GetNxDataByte		;Nächstes Byte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#$00			;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutBytTarget		;Byte in Zieldatei schreiben.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			lda	SizeSourceFile+1
			cmp	WriteSekCount +1
			bne	DecodeNxByte
			lda	SizeSourceFile+0
			cmp	WriteSekCount +0	;Alle Sektoren entpackt ?
			bne	DecodeNxByte		; => Nein, weiter...

::51			jmp	WriteLastSektor
::52			rts

;*** Byte in Ziel-Datei speichern.
:PutBytTarget		bit	firstByte		;Erstes Byte schreiben ?
			bmi	:51			; => Nein, weiter...
			dec	firstByte

			pha				;Byte speichern und freien
			jsr	GetSekTarget		;Sektor einlesen. Byte wieder
			pla				;zurücksetzen.

			ldy	r3L			;Ersten Sektor zwischenspeichern.
			sty	DataSektor +0
			sty	Data1stSek +0
			ldy	r3H
			sty	DataSektor +1
			sty	Data1stSek +1

			ldy	#$02
			bne	:52

::51			ldy	BytesInCurWSek		;Aktueller Sektor voll ?
			bne	:52			; => Nein, weiter...

			pha
			jsr	WrCurSektor		;Sektor auf Diskette schreiben.
			pla
			cpx	#$00
			bne	:54

			ldy	#$02
::52			sta	CopyBuffer,y		;Byte in Sektorspeicher
			iny				;kopieren.
			sty	BytesInCurWSek		;Speicher voll ?
			bne	:53			; => Nein, weiter...

			inc	WriteSekCount +0	;Anzahl Sektoren korrigieren.
			bne	:53
			inc	WriteSekCount +1

::53			ldx	#$00
::54			rts

;*** Aktuellen Sektor auf Diskette schreiben.
:WrCurSektor		jsr	GetSekTarget		;Nächsten freien Sektor einlesen.

			lda	r3L			;LinkBytes in aktuellem Sektor
			sta	CopyBuffer +0		;vermerken und Sektor auf
			lda	r3H			;Diskette schreiben.
			sta	CopyBuffer +1
			jsr	PutSekTarget
			txa
			bne	:51

			jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.

			lda	CopyBuffer +0
			sta	DataSektor +0
			lda	CopyBuffer +1
			sta	DataSektor +1
::51			rts

;******************************************************************************
;*** Datei aus MP-Archiv entpacken.
;******************************************************************************
;*** Zeiger auf erstes Byte einer datei im Archiv setzen.
:SetVec1stByte		jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.

			lda	ExtractFileType
			asl
			tax
			lda	PackFileVecAdr -2,x
			sta	a5L
			lda	PackFileVecAdr -1,x
			sta	a5H

			lda	EntryPosInArchiv	;Zeiger auf ersten Sektor und
			asl				;erstes Byte innerhalb des Sektors
			asl				;speichern.
			tay
			lda	(a5L),y
			sta	r1L
			iny
			lda	(a5L),y
			sta	r1H
			iny
			lda	(a5L),y
			sta	Vec2SourceByte

			jsr	GetSek_dskBlkBuf	;Ersten Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	InitError		; => Ja, Abbruch...

			lda	#$00
			sta	firstByte		;Flag: "Ersten Sektor merken".
			sta	PackedByteCode		;Anzahl gepackter Bytes.
			sta	PackedBytCount		;Gepacktes Byte.
			sta	PackedBytes		;Flag: "Packer nicht aktiv".

;*** Anzahl Sektoren in entpackter Datei auslesen.
:InitTargetFile		ldy	#$1e			;Anzahl benötigter Blocks einlesen.
			lda	(a7L),y
			sta	SizeSourceFile+0
			iny
			lda	(a7L),y
			sta	SizeSourceFile+1

			ldy	#$01			;Anzahl Bytes in letztem Sektor
			lda	(a7L),y			;einlesen.
			sta	BytesInLastSek

			lda	#$02			;Zeiger innerhalb Sektorspeicher
			sta	BytesInCurWSek		;auf Startwert zurücksetzen.

			ldx	#$00			;Sektorzähler löschen.
			stx	WriteSekCount +0
			stx	WriteSekCount +1
:InitError		rts

;*** Freie Sektoren für Datei belegen.
:AllocFileSek		jsr	InitTargetFile
			txa
			bne	AllocSekErr

			lda	SizeSourceFile+0	;Anzahl Sektoren in Desamtdatei
			sta	AllocSekCount +0	;einlesen.
			lda	SizeSourceFile+1
			sta	AllocSekCount +1

;*** Freie Sektoren auf Diskette belegen.
;    Übergabe:		AllocSekCount = Anzahl benötigte Sektoren.
:AllocUsrFSek		LoadW	a9 ,FreeSekTab		;Zeiger auf Sektortabelle.

			jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa
			bne	AllocSekErr

::51			lda	AllocSekCount +0
			ora	AllocSekCount +1	;Speicher für Ziel-Datei belegt ?
			bne	:52			; => Nein, weiter...
			jmp	PutDirHead		;BAM aktualisieren.

::52			lda	#$01
			sta	r3L
			sta	r3H
			jsr	SetNextFree		;Freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	AllocSekErr		; => Ja, Abbruch...

			ldy	#$00			;Freien Sektor in Sektortabelle
			lda	r3L			;übertragen.
			sta	(a9L),y
			iny
			lda	r3H
			sta	(a9L),y
			AddVBW	2,a9

			lda	AllocSekCount +0
			bne	:53
			dec	AllocSekCount +1
::53			dec	AllocSekCount +0	;Sektorzähler korrigieren und
			jmp	:51			;weiter mit nächstem Sektor.
:AllocSekErr		rts

;******************************************************************************
;*** Datei zurück nach GEOS wandeln.
;******************************************************************************
;*** CBM-Datei nach GEOS konvertieren.
:Convert1File		jsr	OpenTargetDrive		;Ziel-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

			LoadW	r6,FNameBuffer
			jsr	FindFile		;.CVT-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

			jsr	Sv_EntryPosCNV		;Verzeichnis-Position speichern.

			ldy	#$1d			;Eintrag der Datei in Zwischen-
::51			lda	dirEntryBuf  ,y		;speicher kopieren.
			sta	FileEntryBuf1,y
			dey
			bpl	:51

::52			lda	FileEntryBuf1 +1	;Zeiger auf ersten Sektor der
			sta	r1L			;.CNV-Datei setzen.
			lda	FileEntryBuf1 +2
			sta	r1H
			jsr	GetSek_dskBlkBuf	;Ersten Sektor der Datei einlesen.
			bne	:55			; => Diskettenfehler, Abbruch...

			ldx	#$0a			;Fehler: "Falsches Dateiformat".
			ldy	#$19
::53			lda	diskBlkBuf +35,y
			cmp	FormatCode2   ,y	;Formatkennung prüfen.
			bne	:55			;Fehler -> Keine CVT-Datei.
			dey
			bpl	:53

			ldx	#$1d			;Original-Dateieintrag
::54			lda	diskBlkBuf  +2,x	;aus Datensektor kopieren.
			sta	FileEntryBuf2 ,x
			dex
			bpl	:54

			lda	diskBlkBuf   +0		;Zeiger auf Infoblock in
			sta	FileEntryBuf2+19	;Verzeichniseintrag kopieren.
			sta	r1L
			lda	diskBlkBuf   +1
			sta	FileEntryBuf2+20
			sta	r1H
			jsr	GetSek_dskBlkBuf	;Sektor für Infoblock einlesen.
			beq	:56			; => Diskettenfehler, Abbruch.
::55			rts

::56			lda	diskBlkBuf   +0		;Zeiger auf Datensektor/VLIR-Header
			sta	FileEntryBuf2+1		;einlesen und speichern.
			lda	diskBlkBuf   +1
			sta	FileEntryBuf2+2

			lda	#$00			;Sektorverkettung im
			sta	diskBlkBuf   +0		;Infoblock löschen.
			lda	#$ff
			sta	diskBlkBuf   +1
			jsr	PutBlock		;InfoBlock aktualisieren.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

;--- Verzeichniseintrag aktualisieren.
			jsr	GetFileDirSek
			txa
			bne	:55

			ldy	#$1d
::57			lda	FileEntryBuf2,y		;Eintrag in Verzeichnissektor
			sta	(r5L)        ,y		;übertragen.
			dey
			bpl	:57

			jsr	PutBlock		;Verzeichnis aktualisieren.
			txa
			bne	:55

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch.

			lda	FileEntryBuf1 +1	;Zeiger auf Datensektor mit
			sta	r6L			;.CVT-Kennung.
			lda	FileEntryBuf1 +2
			sta	r6H
			jsr	FreeBlock		;Sektor freigeben.

::58			jsr	PutDirHead		;BAM aktualsieren.
			txa				;Diskettenfehler ?
			bne	:55			;Ja, Abbruch.

			lda	FileEntryBuf2 +21	;VLIR-Datei ?
			bne	Convert1VLIR		; => Ja, weiter...

			LoadW	r0,100
			jsr	PrintCurPercent

			ldx	#NO_ERROR
			rts

;******************************************************************************
;*** Datei zurück nach GEOS wandeln.
;******************************************************************************
;*** VLIR-Datei konvertieren.
:Convert1VLIR		jsr	EnterTurbo
			jsr	InitForIO

			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	ReadBlock		;Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

			lda	FileHdrBlock +0		;Zeiger auf ersten Sektor der
			sta	r1L			;Programmdaten.
			lda	FileHdrBlock +1
			sta	r1H

			lda	#$02
			sta	CNV_VlirSize +0
			lda	#$00
			sta	CNV_VlirSize +1
			ldy	#$02			;Zeiger auf VLIR-Eintrag.
::51			sty	CNV_VlirEntry
			lda	FileHdrBlock +0,y	;VLIR-Datensatz belegt ?
			beq	:57			;Nein, übergehen.
			sta	CNV_VlirSekCnt		;Anzahl Sektoren/Datensatz merken.
			lda	FileHdrBlock +1,y	;Anzahl Bytes in letztem
			sta	CNV_VlirSekByt		;Datensatz-Sektor merken.

			lda	r1L			;Start-Sektor des aktuellen
			sta	FileHdrBlock +0,y	;Datensatzes in VLIR-Header.
			lda	r1H
			sta	FileHdrBlock +1,y
			LoadW	r4,diskBlkBuf
::52			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			beq	:54			; => Ja, Abbruch.
::53			jmp	DoneWithIO

::54			inc	CNV_VlirSize +0
			bne	:55
			inc	CNV_VlirSize +1

::55			dec	CNV_VlirSekCnt		;Alle Sektoren gelesen ?
			beq	:56			;Ja, Ende...

			lda	diskBlkBuf   +0		;Zeiger auf nächsten Sektor.
			sta	r1L
			lda	diskBlkBuf   +1
			sta	r1H
			jmp	:52			;Nächsten Sektor lesen.

::56			lda	diskBlkBuf   +0		;Zeiger auf nächsten Sektor
			pha				;zwischenspeichern.
			lda	diskBlkBuf   +1
			pha

			lda	#$00			;Letzten Sektor
			sta	diskBlkBuf   +0		;kennzeichnen.
			lda	CNV_VlirSekByt		;Anzahl Bytes in letztem
			sta	diskBlkBuf   +1		;Sektor festlegen.
			jsr	WriteBlock		;Sektor schreiben.
			pla				;Zeiger auf nächsten Sektor.
			sta	r1H
			pla
			sta	r1L
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch.

::57			ldy	CNV_VlirEntry		;Zeiger auf nächsten Datensatz.
			iny
			iny				;Alle Datensätze erzeugt ?
			bne	:51			; => Nein, weiter...

			lda	#$00			;Sektorverkettung für
			sta	FileHdrBlock  +0	;Linkzeiger löschen.
			lda	#$ff
			sta	FileHdrBlock  +1
			jsr	SetVecHdrVLIR		;Zeiger auf VLIR-Sektor.
			jsr	WriteBlock		;Sektor speichern.
::58			jsr	DoneWithIO

;*** Dateigröße korrigieren.
:NewFileSize		jsr	GetFileDirSek		;Verzeichnissektor lesen.
			txa
			bne	:51

			ldy	#$1c
			lda	CNV_VlirSize +0
			sta	(r5L),y
			iny
			lda	CNV_VlirSize +1
			sta	(r5L),y
			jsr	PutBlock
			txa
			bne	:51

			LoadW	r0,100
			jsr	PrintCurPercent

			ldx	#NO_ERROR
::51			rts

;******************************************************************************
;*** Datei zurück nach GEOS wandeln.
;******************************************************************************
;*** Zeiger auf Verzeichnis-Eintrag zwischenspeichern.
:Sv_EntryPosCNV		lda	r1L			;Zeiger auf Verzeichnis-Sektor
			sta	CNV_DirSek_S		;zwischenspeichern.
			lda	r1H
			sta	CNV_DirSek_T
			lda	r5L			;Zeiger auf Verzeichnis-Eintrag
			sta	CNV_DirSek_Vec +0	;zwischenspeichern.
			lda	r5H
			sta	CNV_DirSek_Vec +1
			rts

;*** Verzeichnis-Sektor einlesen.
:GetFileDirSek		lda	CNV_DirSek_S
			sta	r1L
			lda	CNV_DirSek_T
			sta	r1H
			lda	CNV_DirSek_Vec +0
			sta	r5L
			lda	CNV_DirSek_Vec +1
			sta	r5H

;*** Sektor nach ":diskBlkBuf" einlesen.
:GetSek_dskBlkBuf	LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Sektor der Datei einlesen.
			txa				;Diskettenfehler ?
			rts

;*** Zeiger auf VLIR-Header.
:SetVecHdrVLIR		lda	FileEntryBuf2 +1
			sta	r1L
			lda	FileEntryBuf2 +2
			sta	r1H
			LoadW	r4,FileHdrBlock
			rts

;******************************************************************************
;*** Informationen zu Laufwerkstreibern einlesen.
;******************************************************************************
;*** Informationen aus Datei mit Laufwerkstreibern einlesen.
;    Dazu werden aus der gepackten Datei die Sektoren in den Speicher
;    entpackt, welche a).CVT-Kennung, b)InfoBlock, c)VLIR-Header und
;    d)die Treiberliste enthalten.
:GetDskDrvInfo		jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.
			jsr	FindDskDvEntry		;Eintrag für Treiberdatei suchen.
			cpx	#$00			;Eintrag gefunden ?
			beq	:51			; => Ja, weiter...
			rts

::51			jsr	SetVec1stByte		;Zeiger auf erstes Byte setzen.

			LoadW	a8,DskInfTab

;*** Daten einlesen.
:DecodeDskDrvInf	jsr	GetNxDataByte		;Nächstes Byte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#$00			;Diskettenfehler ?
			bne	EndDkInfoFile		; => Ja, Abbruch...

			jsr	WrDskInfByte		;Byte in Speicher kopieren.

			lda	WriteSekCount +0
			cmp	#$04			;Alle Infos eingelesen ?
			bcc	DecodeDskDrvInf		; => Nein, weiter...

			lda	#$02
			clc
			adc	DskInfTab +2*254
			cmp	WriteSekCount +0
			bcs	DecodeDskDrvInf

::51			ldx	#$00
:EndDkInfoFile		rts

;*** Byte in Ziel-Speicher übertragen.
:WrDskInfByte		ldy	#$00
			sta	(a8L),y
			inc	a8L
			bne	:51
			inc	a8H
::51			inc	BytesInCurWSek
			bne	:52

			ldy	#$02
			sty	BytesInCurWSek
			inc	WriteSekCount +0
			bne	:51
			inc	WriteSekCount +1
::52			rts

;******************************************************************************
;*** Benötigte Laufwerkstreiber entpacken.
;******************************************************************************
:ExtractDskDrv		jsr	FindDskDvEntry		;Eintrag für Treiberdatei suchen.
			cpx	#$00			;Eintrag gefunden ?
			bne	:51			; => Nein, Abbruch...

			jsr	DecodeDskDrvFile	;Laufwerkstreiber entpacken.
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			LoadW	r6,File_MP3_Disk
			jsr	FindFile		;Treiberdatei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			LoadW	r0,File_MP3_Disk
			jsr	OpenRecordFile		;Treiberdatei öffnen und
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			lda	#$00			;Informationen über verfügbare
			jsr	PointRecord		;Treiber aktualisieren.
			LoadW	r2,64+64*2+64*17
			LoadW	r7,DskInfTab +3*254
			jsr	WriteRecord
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			jsr	UpdateRecordFile
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			jmp	CloseRecordFile

::51			jmp	EXTRACT_ERROR

;******************************************************************************
;*** Laufwerkstreiber-Datei entpacken.
;******************************************************************************
;*** Datei entpacken.
;    Übergabe:		a7  = Zeiger auf Datei-Eintrag.
:DecodeDskDrvFile	jsr	DeleteTarget		;Ziel-Datei löschen.

;--- Speicher für Treiberdatei in BAM reservieren.
			lda	#$03			;Die ersten beiden Bytes im VLIR-
			sta	DskDvVLIR_org +0	;Header sind unbenutzt. Diese werden
			sta	DskDvVLIR     +0	;hier mit den Daten für den .CVT-
			lda	#$ff			;Header gefüllt:
			sta	DskDvVLIR_org +1	;Anzahl Sektoren        : $03
			sta	DskDvVLIR     +1	;Bytes in letztem Sektor: $FF = 256

			ldy	#$00			;Anzahl benötigter Sektoren
			sty	AllocSekCount +0	;für Ziel-Datei berechnen.
			sty	AllocSekCount +1
::51			lda	DskDvVLIR      ,y
			clc
			adc	AllocSekCount +0
			sta	AllocSekCount +0
			bcc	:52
			inc	AllocSekCount +1
::52			iny
			iny
			bne	:51

			jsr	AllocUsrFSek		;Erforderlichen Speicher belegen.
			txa
			bne	:55

;--- Kopiervorgang initialisieren.
			jsr	SetVec1stByte		;Zeiger auf erstes Byte.

			lda	#$02
			sta	BytesInTmpWSek

			lda	#$00
			sta	VecDskFileHdr		;Zeiger auf VLIR-Datensatz.
			sta	PutByteToDisk		;$00 = VLIR-Datensatz schreiben.

			LoadW	a9,FreeSekTab		;Zeiger auf "Freier Sektor"-Tabelle.

;--- Treiberdatei kopieren.
::53			jsr	InitNxDskDvVLIR		;Nächsten Treiber kopieren.
			txa
			bne	:55

			inc	VecDskFileHdr
			CmpBI	VecDskFileHdr,127	;Alle Treiber kopiert ?
			bne	:53			; => Nein, weiter...

			jsr	WriteLastSektor		;Letzten Sektor aktualisieren.
			txa
			bne	:55

;--- Treiberdatei kopiert.
;    VLIR-Header in .CVT-Datei korrigieren.
			LoadW	r4,diskBlkBuf		;Informationen der .CVT-Datei
							;über die VLIR-Datei aktualisieren.
			lda	Data1stSek +0		;Da nicht alle VLIR-Datensätze
			ldx	Data1stSek +1		;kopiert wurden, ist der Inhalt der
			jsr	GetDskDvBlock		;.CVT-Datei nicht korrekt. Der
			bne	:55			;VLIR-Header wird hier durch den
							;beim kopieren erstellten Header
			lda	diskBlkBuf +0		;ersetzt.
			ldx	diskBlkBuf +1
			jsr	GetDskDvBlock
			bne	:55

			lda	diskBlkBuf +0
			ldx	diskBlkBuf +1
			jsr	GetDskDvBlock
			bne	:55

			ldx	#$02
::54			lda	diskBlkBuf,x
			sta	fileHeader,x
			lda	DskDvVLIR ,x
			sta	diskBlkBuf,x
			inx
			bne	:54
			jsr	PutBlock
			txa
			bne	:55

			jmp	CreateDirEntry
::55			rts

;--- Einzelnen Sektor einlesen.
:GetDskDvBlock		sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			rts

;******************************************************************************
;*** Benötigte Laufwerkstreiber entpacken.
;******************************************************************************
:InitNxDskDvVLIR	lda	#$00			;Zähler für geschriebene Sektoren
			sta	WrTmpSekCount +0	;in datensatz löschen.
			sta	WrTmpSekCount +1

			lda	VecDskFileHdr
			asl
			tax
			lda	DskDvVLIR_org+0,x	;Anzahl Sektoren in
			sta	VDataSekCount		;aktuellem Datensatz einlesen.
			beq	:51

			lda	#$ff
			sta	PutByteToDisk
			lda	DskDvVLIR    +0,x	;Datensatz kopieren ?
			beq	DecodeNxDkDvByte	; => Ja, weiter...
			inc	PutByteToDisk		; => Nein, nicht kopieren...
			lda	DskDvVLIR_org+1,x	;Anzahl Bytes in letztem Datensatz
			sta	BytesInLastSek		;bzw. im letzten Sektor der
			jmp	DecodeNxDkDvByte	;Treiberdatei einlesen und merken.

::51			ldx	#$00
			rts

;*** Bytes für einzelnen Treiber kopieren.
:DecodeNxDkDvByte	jsr	GetNxDataByte		;Nächstes Byte einlesen.
			cpx	#$ff			;Dateiende erreicht ?
			beq	:51			; => Ja, Ende...
			cpx	#$00			;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			jsr	PutBytDskDrv		;Byte in Zieldatei speichern.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

			lda	WrTmpSekCount +0
			cmp	VDataSekCount +0	;Alle Sektoren / Treiber kopiert ?
			bne	DecodeNxDkDvByte	; => Nein, weiter...
::51			ldx	#$00
::52			rts

;*** Byte in Ziel-Datei speichern.
:PutBytDskDrv		inc	BytesInTmpWSek		;Anzahl Bytes +1. Sektor voll ?
			bne	:52			; => Nein, weiter...

			inc	WrTmpSekCount +0	;Anzahl Sektoren +1.
			bne	:51
			inc	WrTmpSekCount +1
::51			ldy	#$02			;Zeiger auf Byte zurücksetzen.
			sty	BytesInTmpWSek

::52			bit	PutByteToDisk		;Byte auf Diskette schreiben ?
			bmi	:53			; => Nein, weiter...
			jmp	PutBytTarget		; => Byte auf Diskette schreiben.

::53			ldx	#$00			; => Byte ignorieren.
			rts

;*** Eintrag für Treiberdatei in Dateiliste suchen.
:FindDskDvEntry		jsr	SetVecTopArchiv

			ldx	#$00
::51			lda	EntryPosInArchiv
			asl
			asl
			tay
			iny
			iny
			lda	(a6L),y			;Eintrag in Dateitabelle für
			cmp	#$03			;Treiberdatei suchen.
			beq	:52			; => Gefunden, weiter...

			jsr	SetVecNxEntry
			bne	:51
			ldx	#$05			;Fehler: "File not found!"
::52			rts

;******************************************************************************
;*** Unterprogramme.
;******************************************************************************
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

;*** Zeiger auf ersten Eintrag in Archiv-Dateiliste.
:SetVecTopArchiv	LoadW	a7,FNameTab1

:SetVecGroupData	ldx	#$00
			stx	EntryPosInArchiv

			ldx	ExtractFileType
			lda	VecFileGroupL,x
			sta	a6L
			lda	VecFileGroupH,x
			sta	a6H
			lda	FilesInGroup ,x
			sta	MaxMP3FData
			rts

;*** Zeiger auf nächsten Eintrag in Archiv-Dateiliste.
:SetVecNxEntry		AddVBW	32,a7

			inc	EntryPosInArchiv
			lda	EntryPosInArchiv
			cmp	MaxMP3FData
			rts

;*** Archiv-Datei suchen.
:FindStartMP		lda	ExtractFileType		;GEOS-Klasse definieren.
			clc
			adc	#"0"
			sta	Class_Group
			sta	Class_Group2

::50			jsr	OpenSourceDrive
			txa				;Diskettenfehler?
			bne	:53			;Ja, Dialogbox anzeigen.

			LoadW	r6 ,FNameSETUP		;Setup-Datei suchen.
			LoadB	r7L,SYSTEM
			LoadB	r7H,1
			LoadW	r10,Class_StartMP
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H			;Datei gefunden ?
			beq	:52			; => Ja, weiter...

::53			LoadW	r0,InfoText0d		;Hinweis ausgeben:
			jsr	PutString		;"Diskwechsel erforderlich!"

			LoadW	r0,Dlg_InsertDisk	;Dialogbox anzeigen:
			jsr	DoDlgBox		;"Diskette mit Archiv einlegen!"

			jsr	Dlg_FlipDiskClr		;Farbe für Dialogbox löschen.
			jsr	ClrInfoScreen		;Infobereich löschen.

			lda	sysDBData
			cmp	#OK			;Nochmal versuchen?
			beq	:50			; => Ja, weiter...

			ldx	#$0c			;CANCEL-Error.
::51			rts

::52			LoadW	r6 ,FNameSETUP		;Verzeichnis-Eintrag einlesen.
			jmp	FindFile

;*** Verzeichnis-Informationen aus Archivdatei einlesen.
:LoadStartMPinfo	jsr	OpenSourceDrive		;Quell-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	ExtractFileType
			asl
			tax
			lda	PatchInfoTS -2,x
			sta	r1L
			lda	PatchInfoTS -1,x
			sta	r1H
			LoadW	r2,(MP3_Files * 32) +1 +3
			LoadW	r7,CRC_CODE
			jmp	ReadFile		;Informationsdaten einlesen.
::51			rts

;******************************************************************************
;*** Byte aus Archiv-Datei einlesen..
;******************************************************************************
:GetNxDataByte		lda	PackedBytes		;Gepackte Daten aktiv ?
			beq	:52			; => Nein, weiter...

			lda	PackedByteCode		;Nächstes gepacktes Byte einlesen.
			dec	PackedBytCount
			bne	:51
			ldy	#$00
			sty	PackedByteCode
			sty	PackedBytes
::51			ldx	#$00
			rts

::52			jsr	GetNxPackBytSrc		;Neues Byte einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			cmp	PackerCodeByte		;Packer-Code ?
			beq	:54			; => Ja, weiter...
::53			rts

::54			jsr	GetNxPackBytSrc		;PackByte einlesen und
			sta	PackedByteCode		;zwischenspeichern.
			jsr	GetNxPackBytSrc		;Anzahl gepackter Bytes einlesen und
			sta	PackedBytCount		;zwischenspeichern.
			lda	#$ff
			sta	PackedBytes
			jmp	GetNxDataByte

;*** Nächstes Byte aus Archiv einlesen.
;    Diese Routine wird universell von allen Unterprogrammen verwendet.
;    Dazu zählen: ":AnalyzeFile", ":ExtractFiles" und ":ExtractDskDrv".
:GetNxPackBytSrc	jsr	SwapSourceDrive		;Quell-Laufwerk öffnen.

			lda	diskBlkBuf +0
			bne	:52
			ldy	diskBlkBuf +1
			iny
			cpy	Vec2SourceByte
			bne	:52
::51			ldx	#$ff
			rts

::52			ldy	Vec2SourceByte
			bne	:53
			cmp	#$00
			beq	:51
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jsr	GetBlock

			ldy	#$02			;Byte aus Sektor einlesen und
::53			lda	diskBlkBuf,y		;dekodieren.
			eor	#%11001010
			iny
			sty	Vec2SourceByte
			ldx	#$00
			rts

;*** Freien Sektor auf Ziel-Laufwerk einlesen.
:GetSekTarget		ldy	#$00			;Zeiger auf Sektortabelle und
			lda	(a9L),y			;nächsten Sektor einlesen.
			sta	r3L
			iny
			lda	(a9L),y
			sta	r3H
			AddVBW	2,a9
			rts

;*** Aktuellen Sektor auf Diskette schreiben.
:PutSekTarget		PushW	r1			;Register zwischenspeichern.
			PushW	r4

			jsr	SwapTargetDrive		;Ziel-Laufwerk aktivieren.
			jsr	PrintPercent

			lda	DataSektor +0		;Zeiger auf Ziel-Sektor setzen.
			sta	r1L
			lda	DataSektor +1
			sta	r1H
			LoadW	r4,CopyBuffer
			jsr	PutBlock		;Sektor auf Diskette schreiben.
			PopW	r4
			PopW	r1
			rts

;*** Datei wurde entpackt, letzte daten auf Diskette schreiben.
:WriteLastSektor	jsr	SwapTargetDrive		;Ziel-Laufwerk aktivieren.
			jsr	PrintPercent

			lda	#$00			;Anzahl Bytes in letztem Sektor
			sta	CopyBuffer +0		;zwischenspeichern.
			lda	BytesInLastSek
			sta	CopyBuffer +1
			lda	DataSektor +0
			sta	r1L
			lda	DataSektor +1
			sta	r1H
			LoadW	r4,CopyBuffer
			jmp	PutBlock		;Sektor auf Diskette schreiben.

;******************************************************************************
;*** Fehlermeldungen.
;******************************************************************************
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
:PrintCurPercent	LoadW	r11,$0118 ! DOUBLE_W
			LoadB	r1H,$b6
			lda	#%11000000
			jsr	PutDecimal
			lda	#"%"
			jsr	PutChar
			lda	#" "
			jmp	PutChar

;*** Fehlercode ausgeben.
:PrntErrCode		LoadW	r0,DskErrInfText
			jsr	PutString

			lda	DskErrCode
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Diskettenfehler ausgeben.
:DiskError		ldy	#$00
			b $2c
:GEOS_ID_ERROR		ldy	#$02
			b $2c
:EXTRACT_ERROR		ldy	#$04
			b $2c
:ANALYZE_ERROR		ldy	#$06
			b $2c
:CRCFILE_ERROR		ldy	#$08
			stx	DskErrCode
			lda	DskErrVecTab +0,y
			sta	r0L
			lda	DskErrVecTab +1,y
			sta	r0H
			jsr	DoDlgBox

;*** Zurück zum DeskTop.
:ExitToDeskTop		lda	screencolors
			sta	:51
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::51			b	$00
			jmp	EnterDeskTop

;*** Tastatur-Abfrage: "!" beendet Setup.
:TestExitKey		lda	keyData
			cmp	#$21
			beq	ExitToDeskTop
			rts

;******************************************************************************
;*** Titelgrafik anzeigen.
;******************************************************************************
:ClearScreen		LoadB	dispBufferOn,ST_WR_FORE
			jsr	UseSystemFont

			jsr	BlackScreen
			jsr	DoLogoColor

			jsr	i_BitmapUp
			w	LOGO_2
			b	$00 ! DOUBLE_B
			b	$00
			b	LOGO_2_x ! DOUBLE_B
			b	LOGO_2_y

			LoadW	r0,LOGO_TEXT
			jsr	PutString
			jmp	UseFontG3

;*** Infobereich löschen.
:ClrInfoScreen		lda	#$00			;Anzeigefeld auf dem Bildschirm
			jsr	SetPattern		;löschen.
			jsr	i_Rectangle
			b	$88,$af
			w	$0010 ! DOUBLE_W
			w	$012f ! DOUBLE_W ! ADD1_W
			rts

;*** Bildschirminhalt/Farbe löschen.
:BlackScreen		lda	#$00
			jsr	SetPattern
			LoadW	r3,0 ! DOUBLE_W
			LoadW	r4,319 ! DOUBLE_W ! ADD1_W
			LoadB	r2L,0
			LoadB	r2H,199
			jsr	Rectangle

if Flag64_128 = TRUE_C128
			bit	graphMode		;80-Zeichen-Modus?
			bpl	:1			;Nein, weiter...
			lda	#$00			;Bildschirmbereich noch
			jmp	_DirectColor		;in r2L,r2H,r3,r4.
endif

::1			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
			b	$00
			rts

;*** Logo einfärben: C64/C128(40Z).
:DoLogoColor
if Flag64_128 = TRUE_C128
			bit	graphMode		;80-Zeichen-Modus?
			bmi	:60			;Ja, weiter...
endif
::50			ldy	#$00			;Zeiger Anfang Farbspeicher.
			lda	#$d0			;Card 0-39    : Hellgrün
			jsr	:51
			lda	#$30			;Card 40-79   : Türkis
			jsr	:51
			lda	#$e0			;Card 80-119  : Hellblau
			jsr	:51
			lda	#$60			;Card 120-159 : Blau
::51			ldx	#$00
::52			sta	COLOR_MATRIX,y
			iny
			inx
			cpx	#LOGO_2_x		;Ende Logo erreicht?
			bcc	:52			;Nein, weiter...
			lda	#$e0			;Bis Ende aktuelle Zeile
::53			sta	COLOR_MATRIX,y		;Farbe Hellblau setzen.
			iny
			inx
			cpx	#40
			bcc	:53
			rts

;*** Logo einfärben: C128(80Z).
if Flag64_128 = TRUE_C128
::60			LoadW	r3,(LOGO_2_x * 8) * 2
			LoadW	r4,639
			LoadB	r2L,0
			LoadB	r2H,4*8
			lda	#$30
			jsr	_DirectColor

			lda	#$00
			sta	r3L
			sta	r3H
			sta	r2L
			sta	r2H
			LoadW	r4,(LOGO_2_x * 8) * 2
			lda	#$50
			jsr	_DirectColor
			lda	#8
			sta	r2L
			sta	r2H
			lda	#$70
			jsr	_DirectColor
			lda	#16
			sta	r2L
			sta	r2H
			lda	#$30
			jsr	_DirectColor
			lda	#24
			sta	r2L
			sta	r2H
			lda	#$20
			jmp	_DirectColor
endif

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$2f
			w	$0040 ! DOUBLE_W
			w	$00ff ! DOUBLE_W ! ADD1_W

			LoadB	r5L,8
			LoadB	r5H,4
			LoadB	r6L,24
			LoadB	r6H,12
			LoadB	r7L,$03
			jsr	ColorRecBox
			LoadB	r6H,2
			LoadB	r7L,$16
			jsr	ColorRecBox
			jmp	UseSystemFont

;*** DiskWechsel initialisieren.
:Dlg_FlipDiskInit	jsr	i_FrameRectangle
			b	$2f,$40
			w	$000f ! DOUBLE_W
			w	$0130 ! DOUBLE_W ! ADD1_W
			b	%11111111

			jmp	UseFontG3

;*** Farbe für DiskWechsel setzen.
:Dlg_FlipDiskCol	ldx	#$10
			jsr	initFlipDiskCol

			LoadB	r5L,$02 ! DOUBLE_B
			LoadB	r5H,$06
			LoadB	r6L,$24 ! DOUBLE_B
			LoadB	r6H,$02
			LoadB	r7L,$12
			jsr	ColorRecBox

			LoadB	r5L,$1a ! DOUBLE_B
;			LoadB	r5H,$06
			LoadB	r6L,$0c ! DOUBLE_B
;			LoadB	r6H,$02
			LoadB	r7L,$01
			jmp	ColorRecBox

;*** Farbe für DiskWechsel löschen.
:Dlg_FlipDiskClr	ldx	#$00
			jsr	initFlipDiskCol

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$47
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W

			rts

;*** Farbe für FlipDisk initialisieren/löschen.
;Übergabe: XReg = Farbe
:initFlipDiskCol	LoadB	r5L,$00 ! DOUBLE_B
			LoadB	r5H,$05
			LoadB	r6L,$28 ! DOUBLE_B
			LoadB	r6H,$04
			stx	r7L
			jmp	ColorRecBox

;*** Informationstext für Kopierstatus ausgeben.
:ViewInfoBox		pha
			txa
			pha

			jsr	ClrAddOnWin

			jsr	i_FrameRectangle
			b	$48,$87
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W
			b	%11111111
			jsr	Frame

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
			jsr	ResetInfoArea		;Farbe für Hinweis setzen.
			LoadW	r0,InfoNoREU		;Hinweis ausgeben:
			jsr	PutString		;Keine Speichererweiterung erkannt!
::1			rts

;*** Farbe für Hinweisbereich setzen.
:ResetInfoArea		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W
			ldx	#$10
			jmp	SetColorRec

;*** Menüfenster zeichnen.
:AddOnWin		jsr	ClrAddOnWin
			jsr	i_FrameRectangle
			b	$48,$bf
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W
			b	%11111111
			jmp	Frame

;*** Menüfenster löschen.
:ClrAddOnWin
if Flag64_128 = TRUE_C128
			bit	graphMode		;40-Zeichen-Modus?
			bpl	:1			;Ja, weiter...
			lda	#$00			;80Zeichen-Modus,
			jsr	SetPattern		;Infobildschirm löschen.
			jsr	i_Rectangle
			b	48,199
			w	0,639
			lda	#$00
			jmp	_DirectColor
endif
::1			jsr	i_FillRam
			w	1000         -6*40
			w	COLOR_MATRIX +6*40
			b	$00
			jsr	i_FillRam
			w	8000         -6*40*8
			w	SCREEN_BASE  +6*40*8
			b	$00
			rts

;******************************************************************************
;*** Rahmen anzeigen.
;******************************************************************************
;*** Rahmen zeichnen.
:Frame			ldx	#$03
			jsr	SetColorRec

if Flag64_128 = TRUE_C128
			lda	graphMode		;80Z-Modus?
			bpl	:1			;Nein, weiter...
			lda	r4H			;Double-Bit gesetzt?
			bpl	:1			;Nein, nicht verdoppeln.
			sec				;X-rechts verdoppeln.
			rol	r4L
			rol	r4H
::1			lda	r3H			;DOUBLE_W/ADD1_W aus X-links/rechts
			and	#%00011111		;löschen.
			sta	r3H
			lda	r4H
			and	#%00011111
			sta	r4H
endif

			jsr	SetSmall
			lda	#$00
			jsr	SetPattern
			jsr	Rectangle
			jsr	SetSmall
			jsr	SetSmall
			lda	#%11111111
			jsr	FrameRectangle
			jsr	SetSmall
			lda	#%11111111
			jsr	FrameRectangle

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

;******************************************************************************
;*** Farbe anzeigen.
;******************************************************************************
;*** Farbe für ":DoIcons" aktivieren.
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

			ldy	#$01
			bit	r7H			;Menü zeichnen ?
			bpl	:53			; => Nein, weiter...
			ldx	r1L
			cpx	#$05
			bcs	:53
			lda	CopyFlgSystem,x		;Dateien bereits kopiert ?
			beq	:53			; => Nein, weiter...
			ldy	#$0f			;Farbe für "kopierte dateien".
::53			sty	r7L			;Farbe setzen und
			jsr	ColorRecBox		;Farbe zeichnen.

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

;******************************************************************************
;*** Farbe anzeigen.
;******************************************************************************
if Flag64_128 = TRUE_C128
			t "-S3_Color2"
endif

;*** Farbrechteck C64/C128(40Z)/C128(80Z) zeichnen.
;    Übergabe: r5L=X, r5H=Y, r6L=Breite, r6H=Höhe.
;    Angaben in Cards!
:ColorRecBox

;*** Spezielle Routinen für C128 einbinden.
if Flag64_128 = TRUE_C128
			t "-S3_Color1"
endif

;*** Farbrechteck zeichnen.
:ColorRecBox40		lda	#<COLOR_MATRIX
			sta	r8L
			lda	#>COLOR_MATRIX
			sta	r8H

			ldx	r5H
::101			jsr	:110			;Zeiger auf erste Zeile für
			bne	:101			;Farbdaten berechnen.

			lda	r5L			;Zeiger auf X-Koordinate setzen.
			and	#%01111111		;Double-Bit ausblenden
			clc
			adc	r8L
			sta	r8L
			bcc	:102
			inc	r8H
::102			ldx	r6H			;Höhe des Rechtecks.
::103			lda	r6L			;Breite des Rechtecks.
			and	#%01111111		;Double-Bit ausblenden
			tay
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

;*** Farbkonvertierungstabelle 80Z <-> 40Z.
if Flag64_128 = TRUE_C128
:VDCFarbtab		b	0			;schwarz (0)
			b	15			;weiß (1)
			b	8			;rot (2)
			b	7			;türkis (3)
			b	11			;violett (4)
			b	4			;grün (5)
			b	2			;blau (6)
			b	13			;gelb (7)
			b	10			;orange (8)
			b	12			;braun (9)
			b	9			;hellrot (10)
			b	1			;grau 1 dunkelgrau (11)
			b	6			;grau 2 mittelgrau (12)
			b	5			;hellgrün (13)
			b	3			;hellblau (14)
			b	14			;grau 3 hellgrau (15)
endif

;******************************************************************************
;*** Variablen
;******************************************************************************
;*** Kopiermodus
:CopyMode		b $00				;$00 = Alle Dateien kopieren.
:CopyFlgSystem		b $00
:CopyFlgRBOOT		b $00
:CopyFlgDskDrive	b $00
:CopyFlgBackScrn	b $00
:CopyFlgScrSave		b $00

;*** Dateinamen.
:FNameSETUP		s 17
:FNameBuffer		s 17

:TargetDrv		b $00				;Quell-Laufwerk.
:SourceDrv		b $00				;Ziel -Laufwerk.
:TargetFreeB		w $0000				;Freier Speicher.
:TargetNeedB		w $0000				;Belegter Speicher.

:firstByte		b $00				;Variablen für Kopiermodus.
:DataSektor		b $00,$00
:Data1stSek		b $00,$00

:PackedBytes		b $00
:PackedByteCode		b $00
:PackedBytCount		b $00
:PackerCodeByte		b $00				;Kennung für gepackte Daten.

:EntryPosInArchiv	b $00
:ExtractFileType	b $00
:VecMP3FDataTab		w $0000
:MaxMP3FData		b $00

:BytesInCurWSek		b $00
:BytesInLastSek		b $00
:BytesInTmpWSek		b $00
:Vec2SourceByte		b $00

:VecDskFileHdr		b $00
:PutByteToDisk		b $00

:VDataSekCount		b $00
:AllocSekCount		w $0000
:WriteSekCount		w $0000
:WrTmpSekCount		w $0000
:SizeSourceFile		w $0000

;*** Koordinaten für Ausgabe der Laufwerksbezeichnungen.
:YPos			b IconT1y
			b IconT2y
			b IconT1y
			b IconT2y
:XPosL			b <IconT1x+3
			b <IconT1x+3
			b <IconT2x+3
			b <IconT2x+3
:XPosH			b >IconT1x+3 ! DOUBLE_B
			b >IconT1x+3 ! DOUBLE_B
			b >IconT2x+3 ! DOUBLE_B
			b >IconT2x+3 ! DOUBLE_B
:WinMaxXL		b $9f,$9f,$1f,$1f
:WinMaxXH		b $00,$00,$01,$01

;*** Variablen für .CVT-Konvertierung.
:CNV_DirSek_S		b $00
:CNV_DirSek_T		b $00
:CNV_DirSek_Vec		w $0000
:CNV_VlirSize		w $0000
:CNV_VlirEntry		b $00
:CNV_VlirSekCnt		b $00
:CNV_VlirSekByt		b $00

:FileEntryBuf1		s 30
:FileEntryBuf2		s 30
:FileHdrBlock		s 256

:FormatCode1		b "MP3"
:FormatCode2		b " formatted GEOS file V1.0",NULL
