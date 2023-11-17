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
:DB_DblBit		= $8871
endif

			n	"mod.#105.obj"
			o	ModStart
			r	EndAreaCBM

			jmp	DoUserJob

			t	"-GetDriver"

;*** Job ausführen.
:DoUserJob		txa
			bmi	:101
			asl
			tax
			lda	JumpTable+0,x
			sta	r0L
			lda	JumpTable+1,x
			sta	r0H
			jmp	(r0)
::101			jmp	OpenFile

;*** Zurück zu GeoDOS.
:L105ExitGD		jmp	InitScreen

;*** Bildschirm-Modus wechseln (C128).
:SwapGraphMode		lda	graphMode
			eor	#$80
			sta	graphMode
			jmp	SetNewMode

;*** Anzeige "Öffne..."
:PrintInfo		FillPRec$00,$b8,$c7,$0000,$013f
			lda	#%11111111
			jsr	FrameRectangle

			jsr	UseSystemFont

			lda	NameOfDok
			bne	:101

			PrintStrgV105c0
			PrintStrgNameOfAppl
			rts

::101			bit	OpenDokMode
			bpl	:102
			PrintStrgV105c1
			jmp	:103

::102			PrintStrgV105c2
::103			PrintStrgNameOfDok
			rts

;*** GEOS-Farben auf Standardwerte.
:OrgGEOSCol		jsr	ClrBackCol
			jsr	Clr2BitMap
			jsr	i_C_GEOS
			b	$00,$00,$28,$19
			jmp	SetGEOSCol

;*** Druckertreiber wählen.
:Get_PrnDrv		jsr	SelectPrinter
			jsr	Ld2DrvData
			jmp	InitScreen

;*** Eingabegerät wählen.
:Get_InpDrv		jsr	SelectInput
			txa
			bne	:102

			jsr	PrepGetFile		;":dlgBoxRamBuf" löschen.

			LoadB	r0L,%00000001
			LoadW	r6,inputDevName
			LoadW	r7,MOUSE_BASE
			jsr	GetFile
			txa
			beq	:101
			jmp	DiskError

::101			jsr	InitMouse

::102			jsr	Ld2DrvData
			jmp	InitScreen		;Zum Menü zurück.

;*** Datei öffnen.
:OpenFile		lda	APP_VAR +31
			jsr	NewDrive
			jsr	NewOpenDisk

			ldy	#$03
			ldx	#$00
::101			lda	APP_VAR    ,y
			cmp	#$a0
			beq	:102
			sta	APP_VAR +32,x
			iny
			inx
			cpx	#$10
			bne	:101
::102			lda	#$00
			sta	APP_VAR +32,x

			LoadW	r15,APP_VAR +32

			lda	APP_VAR +$16
			cmp	#APPLICATION
			beq	:104
			cmp	#APPL_DATA
			beq	:105
			cmp	#AUTO_EXEC
			beq	:104
			cmp	#DESK_ACC
			beq	:106
::103			jmp	L105ExitGD

;*** Anwendung starten.
::104			jmp	Load_Appl

;*** Dokument öffnen.
::105			lda	#%10000000
			sta	OpenDokMode
			jmp	Load_Dok

;*** Hilfsmittel starten.
::106			jmp	Load_DA

;*** GeoWrite starten.
:Get_gW			lda	#<FileClass1
			ldx	#>FileClass1
			jsr	IsApplOnDsk
			txa
			beq	:101

			DB_OK	V105b0
			jmp	InitScreen		;Zurück zu GeoDOS.
::101			jmp	OpenAppl

;*** GeoWrite-Texte öffnen.
:Get_gW_Doks		LoadW	GetFileTitel,V105a4
			lda	#%10000000
			jmp	Open_gW_Dok

;*** GeoWrite-Texte drucken.
:Prn_gW_Doks		LoadW	GetFileTitel,V105a5
			lda	#%01000000

;*** GeoWrite-Dokumente öffnen/drucken.
:Open_gW_Dok		sta	OpenDokMode

:Open_gW_Dok1		lda	#<FileClass2
			ldx	#>FileClass2
			jsr	LookForDoks
			jsr	PrepFileTab

			lda	#<GetFileTab
			ldx	#>GetFileTab
			ldy	#$02
			sty	GetFileTab
			jsr	SelectBox		;Verzeichnisauswahlbox.

			lda	r13L
			beq	Load_gW_Dok
			cmp	#$80
			bcc	:102
			cmp	#$90
			beq	:101

			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	Open_gW_Dok1

::101			jsr	CMD_NewTarget
			jmp	Open_gW_Dok1

::102			jmp	InitScreen

;*** Dokument öffnen/drucken.
:Load_gW_Dok		ldx	#r14L
			jsr	GetPtrCurDkNm

			ldy	#$0f
::101			lda	(r14L),y
			sta	NameOfDokDisk,y
			lda	(r15L),y
			sta	NameOfDok,y
			dey
			bpl	:101

			lda	#<FileClass1
			ldx	#>FileClass1
			jsr	IsApplOnDsk
			txa
			beq	:102

			DB_OK	V105b0
			jmp	InitScreen		;Zurück zu GeoDOS.

::102			jmp	OpenDokument

;*** Applikationen laden.
:Get_Appl		LoadW	GetFileTitel,V105a0

			lda	#APPLICATION
			ldx	#<$0000
			ldy	#>$0000
			jsr	LookForFiles

			lda	r7H
			pha
			jsr	ConvertFNames
			MoveW	r14,Vec1File
			pla
			eor	#%11111111
			sta	r7H
			lda	#255
			suba	r7H
			sta	MaxReadFiles

			lda	#AUTO_EXEC
			ldx	#<$0000
			ldy	#>$0000
			jsr	LookForFiles1
			jsr	PrepFileTab

			lda	#<GetFileTab
			ldx	#>GetFileTab
			ldy	#$04
			sty	GetFileTab
			jsr	SelectBox		;Verzeichnisauswahlbox.

			lda	r13L
			beq	Load_Appl
			cmp	#$80
			bcc	:102
			cmp	#$90
			beq	:101
			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	Get_Appl

::101			jsr	CMD_NewTarget
			jmp	Get_Appl
::102			jmp	InitScreen

;*** Applikation laden.
:Load_Appl		ldy	#$0f
::101			lda	(r15L),y
			sta	NameOfAppl,y
			dey
			bpl	:101
			jmp	OpenAppl

;*** Hilfsmittel laden.
:Get_DA			LoadW	GetFileTitel,V105a1

			lda	#DESK_ACC
			ldx	#<$0000
			ldy	#>$0000
			jsr	LookForFiles
			jsr	PrepFileTab

			lda	#<GetFileTab
			ldx	#>GetFileTab
			ldy	#$04
			sty	GetFileTab
			jsr	SelectBox		;Verzeichnisauswahlbox.

			lda	r13L
			beq	Load_DA
			cmp	#$80
			bcc	:102
			cmp	#$90
			beq	:101

			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	Get_DA

::101			jsr	CMD_NewTarget
			jmp	Get_DA
::102			jmp	InitScreen

;*** Hilfsmittel laden.
:Load_DA		ldy	#$0f
::101			lda	(r15L),y
			sta	NameOfDA,y
			dey
			bpl	:101

			LoadW	r6,NameOfDA
			jsr	ChkFlag_40_80
			txa
			bne	:102

			jsr	OrgGEOSCol
			jsr	PrepGetFile		;":dlgBoxRamBuf" löschen.

			LoadW	r6,NameOfDA
			LoadB	r0L,%00000000
;			LoadB	r10L,$00		;Wird durch ":PrepGetFile" gelöscht.
			jsr	GetFile			;DA laden.
			txa
			beq	:102
			jmp	DiskError		;Disketten-Fehler.
::102			jmp	InitScreen		;Zum Menü zurück.

;*** Dokumente öffnen.
:Get_Doks		LoadW	GetFileTitel,V105a2
			lda	#%10000000
			jmp	Open_Dok

;*** Dokumente drucken.
:Prn_Doks		LoadW	GetFileTitel,V105a3
			lda	#%01000000

;*** Dokumente öffnen/drucken.
:Open_Dok		sta	OpenDokMode

:Open_Dok1		lda	#<$0000
			ldx	#>$0000
			jsr	LookForDoks
			jsr	PrepFileTab

			lda	#<GetFileTab
			ldx	#>GetFileTab
			ldy	#$02
			sty	GetFileTab
			jsr	SelectBox		;Verzeichnisauswahlbox.

			lda	r13L
			beq	Load_Dok
			cmp	#$80
			bcc	:102
			cmp	#$90
			beq	:101

			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	Open_Dok1

::101			jsr	CMD_NewTarget
			jmp	Open_Dok1

::102			jmp	InitScreen

;*** Dokument öffnen/drucken.
:Load_Dok		ldx	#r14L
			jsr	GetPtrCurDkNm

			ldy	#$0f
::101			lda	(r14L),y
			sta	NameOfDokDisk,y
			lda	(r15L),y
			sta	NameOfDok,y
			dey
			bpl	:101

			jsr	LoadDokInfos
			txa
			beq	:102

			DB_OK	V105b1
			jmp	InitScreen

::102			lda	#<FileClass3
			ldx	#>FileClass3
			jsr	IsApplOnDsk
			txa
			beq	:103

			DB_OK	V105b2
			jmp	InitScreen		;Zurück zu GeoDOS.

::103			jmp	OpenDokument

;*** Dokument öffnen.
:OpenAppl		LoadW	r6,NameOfAppl
			jsr	ChkFlag_40_80
			txa
			bne	:103

			jsr	PrepareExit		;Farben zurücksetzen.
			jsr	SetMode_40_80
			jsr	PrintInfo

::101			jsr	PrepGetFile		;":dlgBoxRamBuf" löschen.

			LoadW	r6,NameOfAppl
			LoadB	r0L,%00000000
			jsr	GetFile			;GeoWrite starten.
::102			jmp	EnterDeskTop		;Zum DeskTop!
::103			jmp	InitScreen		;Zum Menü zurück.

;*** Dokument öffnen.
:OpenDokument		LoadW	r6,NameOfAppl
			jsr	ChkFlag_40_80
			txa
			bne	:104

			ldy	#$0f
::101			lda	NameOfDokDisk,y
			sta	dataDiskName ,y
			lda	NameOfDok    ,y
			sta	dataFileName ,y
			dey
			bpl	:101

			jsr	PrepareExit		;Farben zurücksetzen.
			jsr	SetMode_40_80
			jsr	PrintInfo

::102			jsr	PrepGetFile		;":dlgBoxRamBuf" löschen.

			LoadW	r2,dataDiskName
			LoadW	r3,dataFileName
			LoadW	r6,NameOfAppl
			MoveB	OpenDokMode,r0L
			jsr	GetFile			;GeoWrite starten.
::103			jmp	EnterDeskTop		;Zum DeskTop!
::104			jmp	InitScreen		;Zum Menü zurück.

;*** C128: 40/80Z-Modus testen.
:ChkFlag_40_80		jsr	FindFile
			txa
			bne	:4

			LoadW	r9,dirEntryBuf		;Infoblock einlesen.
			jsr	GetFHdrInfo
			txa				;Info-Block gefunden ?
			bne	:4			; => Nein, BASIC-File, Abbruch...

			lda	fileHeader+$60		;40/80Z-Flag einlesen.
			ldx	c128Flag		;C64/C128?
			bne	:1			; => C128, Weiter...
;--- Ergänzung: 15.03.19/M.Kanet
;Unter GEOS gibt es kein Flag für "Nur GEOS128". Eine Anwendung die für den
;40+80Z-Modus entwickelt wurde kann auch für GEOS64 existieren. Es kannn aber
;auch eine reine GEOS128-Anwendung sein.
;Unter GEOS64 werden daher GEOS64, 40ZOnly und 40/80Z akzeptiert.
			cmp	#$c0			;Nur 80Z?
			beq	:2			; => GEOS128-App auf GEOS64... Abbruch.
			bne	:3			;Evtl. GEOS64 App... weiter...

;--- Ergänzung: 15.03.19/M.Kanet
;Unter GEOS128 werden 40ZOnly, 80ZOnly und 40/80Z akzeptiert.
::1			cmp	#%00000000		;40/80Z-Flag einlesen.
			beq	:40
			cmp	#%01000000		;40/80Z ?
			beq	:80			;Ja -> 80Z-Modus setzen.
			cmp	#%10000000		;40/80Z ?
			beq	:2			;Ja -> 80Z-Modus setzen.
			cmp	#%11000000		;Nur 80Z ?
			beq	:80			;Ja -> 80Z-Modus setzen.
::2			ldx	#INCOMPATIBLE		; -> Nur GEOS64, Abbruch.
			bne	:4
::80			lda	#%10000000		;80Z-Modus setzen.
			b $2c
::40			lda	#%00000000		;40Z-Modus setzen.
			sta	appScrnMode
::3			ldx	#$00
::4			rts

:appScrnMode		b $00

;*** Neuen Modus für Anwendung setzen.
:SetMode_40_80		ldx	c128Flag		;C64/C128?
			beq	:2			; => C64, Ende...

			lda	appScrnMode
			cmp	graphMode		;Neuer Modus bereits aktiv?
			beq	:1			; -> Ja, weiter...
			sta	graphMode
			jsr	SetNewMode		;Neuen Modus aktivieren.

::1			lda	#%00000000		;Verdopplung abschalten.
			sta	DB_DblBit
::2			rts

;*** Applikation suchen.
:IsApplOnDsk		sta	ClassOfAppl+0
			stx	ClassOfAppl+1

;*** Laufwerke ermitteln.
			ldy	#4
			lda	#$00			;Tabelle mit den verfügbaren
::101			sta	ApplDrives-1,y		;Laufwerken für Applikationen löschen.
			dey
			bne	:101

			ldx	#8
::102			lda	DriveTypes-8,x		;Laufwerk vorhanden ?
			beq	:103			;Nein, weiter...
			lda	DriveModes-8,x		;Laufwerksmodus einlesen...
			and	#%00001000		;Aktuelles Laufwerk = RAM-Laufwerk ?
			beq	:103			;Nein, weiter...
			txa				;Laufwerk in Tabelle eintragen.
			sta	ApplDrives,y
			iny				;Zähler für "Laufwerke in Tabelle"
			cpy	#4			;korrigieren. Tabelle voll ?
			beq	InitSearch		;Ja, Ende...
::103			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Laufwerke 8-11 getestet ?
			bne	:102			;Nein, weiter...

			ldx	#8
::104			lda	DriveTypes-8,x		;Laufwerk vorhanden ?
			beq	:105			;Nein, weiter...
			lda	DriveModes-8,x		;Laufwerksmodus einlesen.
			and	#%00001000		;Aktuelles Laufwerk = RAM-Laufwerk ?
			bne	:105			;Ja, weiter...
			txa				;Laufwerk in Tabelle eintragen.
			sta	ApplDrives,y
			iny				;Zähler für "Laufwerke in Tabelle"
			cpy	#4			;korrigieren. Tabelle voll ?
			beq	InitSearch		;Ja, Ende...
::105			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Laufwerke 8-11 getestet ?
			bne	:104			;Nein, weiter...

;*** Suche initialisieren.
:InitSearch		ldx	#$00
::101			stx	LookOnDrive
			lda	ApplDrives,x
			beq	:103
			jsr	NewDrive

			jsr	NewOpenDisk
			txa
			bne	:102

			LoadW	r6,NameOfAppl
			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			MoveW	ClassOfAppl,r10
			jsr	FindFTypes
			txa
			bne	:102
			lda	r7H
			bne	:102
			rts

;*** Suche auf nächstem Laufwerk.
::102			ldx	LookOnDrive
			inx
			cpx	#$04
			bcc	:101

::103			ldx	#$05
			rts				;Ende.

;*** Dateien suchen.
:LookForFiles		sta	LookFileType
			stx	ClassOfAppl+0
			sty	ClassOfAppl+1

			jsr	DoInfoBox
			PrintStrgDB_RdFile

			LoadW	Vec1File,FileNTab
			LoadB	MaxReadFiles,255
			jmp	LookForFiles2

:LookForFiles1		sta	LookFileType
			stx	ClassOfAppl+0
			sty	ClassOfAppl+1

:LookForFiles2		jsr	NewOpenDisk
			txa
			bne	:102

			MoveW	Vec1File    ,r6
			MoveB	LookFileType,r7L
			MoveB	MaxReadFiles,r7H
			MoveW	ClassOfAppl ,r10
			jsr	FindFTypes
			txa
			bne	:102
			CmpBI	r7H,255
			beq	:102
			rts

;*** Keine Dateien gefunden, Speicher löschen.
::102			jsr	i_FillRam
			w	17*255
			w	FileNTab
			b	$00
			rts

;*** Dokumente suchen.
:LookForDoks		sta	ClassOfDok+0
			stx	ClassOfDok+1

			jsr	DoInfoBox
			PrintStrgDB_RdFile

			LoadW	Vec1File,FileNTab
			LoadB	MaxReadFiles,255

			lda	curDrive
			cmp	#10
			bcc	:101
			lda	#8
::101			jsr	NewDrive

			jsr	NewOpenDisk
			txa
			bne	:102

			MoveW	Vec1File    ,r6
			LoadB	r7L,APPL_DATA
			MoveB	MaxReadFiles,r7H
			MoveW	ClassOfDok  ,r10
			jsr	FindFTypes
			txa
			bne	:102
			CmpBI	r7H,255
			beq	:102
			rts

;*** Keine dokumente gefunden, Speicher löschen.
::102			jsr	i_FillRam
			w	17*255
			w	FileNTab
			b	$00
			rts

;*** Dokument-Infos einlesen.
:LoadDokInfos		LoadW	r6,NameOfDok		;Dateieintrag suchen.
			jsr	FindFile
			txa				;Diskettenfehler ?
			bne	:102			;Nein, weiter...

			LoadW	r9,dirEntryBuf		;Infoblock einlesen.
			jsr	GetFHdrInfo
			txa
			bne	:102

			ldy	#11			;"Class" der Application einlesen.
::101			lda	fileHeader+$75,y
			sta	FileClass3    ,y
			dey
			bpl	:101

			ldx	#$00			;Kein Fehler...
::102			rts				;Ende.

;*** Variablen.
:NameOfAppl		s 17				;Name für Applikation.
:NameOfDA		s 17				;Name für Hilfsmittel.
:NameOfDok		s 17				;Name für Dokument.
:NameOfDokDisk		s 17				;Name für Dokumentendiskette.
:ClassOfAppl		w $0000				;Klasse für Applikation.
:ClassOfDok		w $0000				;Klasse für Dokumente.
:ApplDrives		s $04				;Laufwerke für Suche nach Applikationen.
:DokDrives		s $02				;Laufwerke für Suche nach Dokumenten.
:LookOnDrive		b $00				;Zeiger auf ":ApplDrives".
:OpenDokMode		b $00				;$80 Dok. öffnen, $40 Dok. drucken.
:LookFileType		b $00				;Dateityp.

:FileClass1		b "geoWrite    ",NULL
:FileClass2		b "Write Image ",NULL
:FileClass3		s 17

;*** Dialogboxen.
:GetFileTab		b $00
			b $ff
			b $00
			b $10
			b $00
:GetFileTitel		w V105a4
			w FileNTab

;*** Sprungtabelle.
:JumpTable		w Get_gW
			w Get_gW_Doks
			w Prn_gW_Doks

			w Get_Appl
			w Get_Doks
			w Prn_Doks
			w Get_DA

			w Get_PrnDrv
			w Get_InpDrv

if Sprache = Deutsch
:V105a0			b PLAINTEXT,"Anwendung starten",NULL
:V105a1			b PLAINTEXT,"Hilfsmittel starten",NULL
:V105a2			b PLAINTEXT,"Dokument öffnen",NULL
:V105a3			b PLAINTEXT,"Dokument drucken",NULL
:V105a4			b PLAINTEXT,"GeoWrite-Dokument öffnen",NULL
:V105a5			b PLAINTEXT,"GeoWrite-Dokument drucken",NULL

;*** Fehlermeldungen.
:V105b0			w :101, :102, ISet_Achtung
::101			b BOLDON,"GeoWrite nicht auf",NULL
::102			b        "Laufwerk A: bis D: !",NULL

:V105b1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Fehler beim öffnen",NULL
::102			b        "des Dokuments!",NULL

:V105b2			w :101, :102, ISet_Achtung
::101			b BOLDON,"Benötigte Applikation",NULL
::102			b        "nicht auf Diskette!",NULL

;*** Texte.
:V105c0			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0008
			b $c2
			b "Starte Applikation: ",NULL

:V105c1			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0008
			b $c2
			b "Öffne Dokument: ",NULL

:V105c2			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0008
			b $c2
			b "Drucke Dokument: ",NULL
endif

if Sprache = Englisch
:V105a0			b PLAINTEXT,"Open application",NULL
:V105a1			b PLAINTEXT,"Open desc-accessory",NULL
:V105a2			b PLAINTEXT,"Open document",NULL
:V105a3			b PLAINTEXT,"Print document",NULL
:V105a4			b PLAINTEXT,"Open GeoWrite-document",NULL
:V105a5			b PLAINTEXT,"Open GeoWrite-document",NULL

;*** Fehlermeldungen.
:V105b0			w :101, :102, ISet_Achtung
::101			b BOLDON,"GeoWrite not found",NULL
::102			b        "on drive A: to D: !",NULL

:V105b1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Error while open",NULL
::102			b        "document!",NULL

:V105b2			w :101, :102, ISet_Achtung
::101			b BOLDON,"Application for",NULL
::102			b        "document not found!",NULL

;*** Texte.
:V105c0			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0008
			b $c2
			b "Open application: ",NULL

:V105c1			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0008
			b $c2
			b "Open document: ",NULL

:V105c2			b PLAINTEXT,BOLDON
			b GOTOXY
			w $0008
			b $c2
			b "Print document: ",NULL
endif

;*** Infoblock für .INI-Datei.
:HdrPrnDrv		w V105d0
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w PrntFileName
			w PrntFileName + 16
			w PrntFileName
			b "GD_PRINTER  V"		;Klasse.
			b "2.0"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64"			;Autor.
:HdrEnd1		s (HdrPrnDrv+161)-HdrEnd1

;*** Infoblock für .INI-Datei.
:HdrInpDrv		w V105d1
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w inputDevName
			w inputDevName + 16
			w inputDevName
			b "GD_INPUT    V"		;Klasse.
			b "2.0"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64"			;Autor.
:HdrEnd2		s (HdrInpDrv+161)-HdrEnd2

:V105d0			b "PRINTER.INI",NULL
:V105d1			b "INPUT.INI",NULL
