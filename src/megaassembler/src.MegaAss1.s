; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Hauptprogramm/Hauptmenü.
if .p
			t "TopSym"
			t "TopMac"
			t "src.MegaAss0.ext"

:MP3_CODE		= $c014
:RealDrvMode		= $9f92
:DBSELECTPART		= %10000000

:MaxTextEntry		= 13
endif

			n "mod.#1"
			o VLIR_BASE
			p StartMegaAss

;*** Parameter-Bytes im Infoblock.
;    $90 = Opt_SourceDrive
;    $91 = Opt_TargetDrive
;    $92 = Opt_ErrFileDrive
;    $93 = Opt_SymbTabDrive
;    $94 = Opt_AutoTxtDrive
;    $95 = Opt_AutoMode
;    $96 = Opt_SymbTabMode
;    $97 = Opt_ExtSTabMode
;    $98 = Opt_OverWrite
;    $99 = Opt_IgnoreFileMode
;    $9a = Opt_FileLenMode
;    $9b = Opt_POpcodeTest
;    $9c = Opt_MouseCancel

;*** MegaAssembler starten.
:StartMegaAss

;*** Laufwerkstabelle erzeugen.
:InitDriveTab		ldx	#$04 -1
			lda	#$00			;Tabelle für Suchreihenfolge
::0			sta	FindFileDriveTab,x	;der Laufwerke löschen.
			dex
			bpl	:0

			inx				;LDX #$00

			lda	Opt_SourceDrive		;Suchreihenfolge 1.Laufwerk.
			sta	FindFileDriveTab +0
			sta	r1L
			inx

			lda	Opt_TargetDrive		;Suchreihenfolge 2.Laufwerk.
			cmp	r1L
			beq	:1
			sta	FindFileDriveTab +1
			sta	r1H
			inx

;--- RAM-Laufwerke in Tabelle übernehmen.
::1			ldy	#$00
::2			tya				;Laufwerksadresse berechnen.
			clc
			adc	#$08
			sta	r0L

			cmp	r1L			;Laufwerk bereits in Tabelle?
			beq	:3
			cmp	r1H
			beq	:3			; => Ja, überspringen...

			lda	driveType,y		;RAM-Laufwerk?
			bpl	:3			; => Nein, überspringen...

			lda	r0L			;Laufwerk für Suchreihenfolge
			sta	FindFileDriveTab,x	;in Tabelle übernehmen.
			inx

::3			iny
			cpy	#$04			;Alle Laufwerke überprüft?
			bne	:2			; => Nein, weiter...

;--- Disk-Laufwerke in Tabelle übernehmen.
			ldy	#$00
::4			tya				;Laufwerksadresse berechnen.
			clc
			adc	#$08
			sta	r0L

			cmp	r1L			;Laufwerk bereits in Tabelle?
			beq	:5
			cmp	r1H
			beq	:5			; => Ja, überspringen...

			lda	driveType,y		;Disk-Laufwerk?
			beq	:5			; => Nein, überspringen...
			bmi	:5			; => Nein, überspringen...

			lda	r0L			;Laufwerk für Suchreihenfolge
			sta	FindFileDriveTab,x	;in Tabelle übernehmen.
			inx

::5			iny
			cpy	#$04			;Alle Laufwerke überprüft?
			bne	:4			; => Nein, weiter...

;*** MegaAssembler initialisieren.
:InitMegaAss		lda	Flag_AutoAssInWork	;AutoAssembler aktiv ?
			beq	:1			;Nein, weiter...
			lda	ErrCount		;Fehler aufgetreten ?
			bne	:1			;Ja, AutoAssembler abbrechen.
			lda	Flag_StopAssemble	;Fehler aufgetreten ?
			bne	:1			;Ja, AutoAssembler abbrechen.
			lda	Flag_FatalError		;Fehler aufgetreten ?
			bne	:1			;Ja, AutoAssembler abbrechen.
			jmp	GetNextCom		;Nächsten AutoAss-Befehl laden.

;*** Systembildschirm ausgeben.
::1			lda	#$00			;AutoAssembler beenden.
			sta	Flag_AutoAssInWork
			sta	Flag_StopAssemble
			sta	Flag_FatalError

			bit	Flag_FirstBoot		;Erster Start von MegaAss ?
			bpl	DoInfoScreen		;Nein, weiter...

;			lda	#$00
			sta	Flag_FirstBoot		;Boot-Flag löschen.

;			lda	#$00			;Variablen initialisieren.
			sta	SelectedFile
			sta	ErrFileName
			sta	SymFileName
			sta	ExtFileName
			sta	Flag_FileCreated
			sta	Flag_SymbFileOK
			sta	Flag_ExtSFileOK
			sta	Poi_1stEntryInTab

			jsr	LoadParameter		;Parameter einlesen.
			jsr	SetMenParData		;Menü-Anzeige initialisieren.

			LoadB	Flag_SaveTime,$ff

;*** Infobildschirm aufbauen.
:DoInfoScreen		jsr	SetXpos40_80		;40/80-Zeichenkoordinaten.
			jsr	DefMenu_GEOS		;Hilfsmittel einlesen.
			jsr	GetMenu_Text		;Textdateien einlesen.
			jsr	GetDiskNames

			LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK
			jsr	ClrScreen		;Bildschirm löschen.

			jsr	PrntMenuScrn		;Menübildschirm zeichnen.
			jsr	PrntCodeInfo		;QuellCode-Informationen.
			jsr	PrntSymbTabInfo		;Symbolspeicher-Informationen.
			jsr	PrntFileInfo		;Datei-Informationen.

;*** Menü aktivieren.
:StartMainMenu		jsr	SetMenParData		;Menü-Anzeige initialisieren.

			LoadW	r0,SysIconMenu		;Icon-Menü.
			jsr	DoIcons

			LoadW	r0,DM_MainMenu		;Haupt-Menü.
			lda	#$01
			jmp	DoMenu

;*** Infobox über MegaAssembler anzeigen.
:InfoBox		jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			LoadW	r0,DlgInfoBox		;MegaAss-Info zeigen.
			jmp	DoDlgBox

;*** Opcode-Informationen anzeigen
:DlgOpcodes		jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			LoadW	r0,DlgOpcodesInfo	;MegaAss-Info zeigen.
			jmp	DoDlgBox

;*** VLink aufrufen.
:StartVLink		jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			lda	Opt_BootDrive
			jsr	SetDevice
			jsr	OpenDisk
			jmp	Mod_VLink		;Linker starten.

;*** MegaAss neu starten.
:ReBootMegaAss		jsr	FindMegaAss		;MegaAssembler suchen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch.

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			LoadB	r0L,%00000000
			LoadW	r6 ,NameMegaAss
			jsr	GetFile			;MegaAssembler starten.
::1			jmp	ExitDT			;Abbruch, zm DeskTop.

;*** Variablenspeicher löschen.
:LoadFileInit		jsr	i_FillRam
			w	417
			w	dlgBoxRamBuf
			b	$00

			ldx	#r0L
			lda	#$00
::1			sta	$00,x
			inx
			cpx	#r15H +1
			bcc	:1
			rts

;*** Assembliertes Programm testen.
:StartProgramm		jsr	GotoFirstMenu		;Hauptmenü aktivieren.

			lda	Flag_FileCreated
			beq	ExitTestProgramm

			lda	Opt_TargetDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,ObjectFileName
			jsr	FindFile
			txa
			bne	ExitTestProgramm

			lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00
			b	$c7
:K601			w	$0000
			w	$013f

::1			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			LoadW	r6 ,ObjectFileName
			LoadB	r0L,%00000000
			jsr	GetFile
			cpx	#$0e
			bne	ExitTestProgramm

			lda	graphMode
			eor	#$80
			sta	graphMode
			sta	ScreenMode
			jsr	SetNewMode
			jsr	ClrScreen
			jmp	:1

;*** Programm kann nicht getestet werden.
:ExitTestProgramm	jmp	ExitDT

;*** Hilfsmittel laden.
:LoadDA_File		sta	a0L			;Gewähltes DA merken.
			jsr	GotoFirstMenu		;Hauptmenü aktivieren.

			lda	Opt_BootDrive
			jsr	NewSetDevice		;Laufwerk aktivieren.
			jsr	NewOpenDisk		;Diskette öffnen.

			dec	a0L			;Zeiger auf Dateiname
			dec	a0L			;berechnen.
			LoadB	a0H,$00
			LoadW	a1 ,$0011
			ldx	#a0L
			ldy	#a1L
			jsr	DMult

			AddVW	MT02c,a0		;Dateiname kopieren.
			LoadW	a1,Buf_FileName
			ldx	#a0L
			ldy	#a1L
			jsr	CopyString

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			LoadB	r0L,%00000000
			LoadW	r6,Buf_FileName
			jsr	GetFile			;Hilfsmittel laden.

			lda	screencolors
			sta	:1
			jsr	i_FillRam		;Bildschirmfarben zurücksetzen.
			w	1000
			w	COLOR_MATRIX
::1			b	$00

			jsr	i_RecoverRectangle	;Grafik zurücksetzen.
			b	$10
			b	$c7
:K602			w	$0000
			w	$013f

			jmp	StartMainMenu		;Zurück zum Hauptmenü.

;*** Quelltext öffnen.
:OpenSrcCode		lda	Opt_SourceDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			jsr	FindGeoWrite		;GeoWrite suchen.
			txa
			bne	:1

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			lda	Opt_SourceDrive
			jsr	GetDskNameVec

			lda	#< SelectedFile
			ldx	#> SelectedFile
			jmp	OpenWriteFile
::1			jmp	StartMainMenu

;*** Fehlerliste öffnen.
:OpenErrFile		bit	Flag_ErrFileOK		;Fehlerdatei verfügbar ?
			bmi	:1			;Ja, weiter...
			jmp	GotoFirstMenu		;Nein, zurück zum Hauptmenü.

::1			lda	Opt_ErrFileDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			jsr	FindGeoWrite		;GeoWrite suchen.
			txa
			bne	:2

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			lda	Opt_ErrFileDrive
			jsr	GetDskNameVec

			lda	#< ErrFileName
			ldx	#> ErrFileName
			jmp	OpenWriteFile
::2			jmp	StartMainMenu

;*** Symboltabelle öffnen.
:OpenSymFile		bit	Flag_SymbFileOK		;Symboldatei verfügbar ?
			bmi	:1			;Ja, weiter...
			jmp	GotoFirstMenu		;Nein, zurück zum Hauptmenü.

::1			lda	Opt_SymbTabDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			jsr	FindGeoWrite		;GeoWrite suchen.
			txa
			bne	:2

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			lda	Opt_SymbTabDrive
			jsr	GetDskNameVec

			lda	#< SymFileName
			ldx	#> SymFileName
			jmp	OpenWriteFile
::2			jmp	StartMainMenu

;*** Symboltabelle öffnen.
:OpenExtFile		bit	Flag_ExtSFileOK		;Ext. Symboldatei verfügbar ?
			bmi	:1			;Ja, weiter...
			jmp	GotoFirstMenu		;Nein, zurück zum Hauptmenü.

::1			lda	Opt_SymbTabDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			jsr	FindGeoWrite		;GeoWrite suchen.
			txa
			bne	:2

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			lda	Opt_SymbTabDrive
			jsr	GetDskNameVec

			lda	#< ExtFileName
			ldx	#> ExtFileName
			jmp	OpenWriteFile
::2			jmp	StartMainMenu

:OpenWriteFile		sta	r0L
			stx	r0H

			ldy	#16 -1
::1			lda	(r0L),y
			sta	dataFileName,y
			dey
			bpl	:1

			LoadW	r3 ,dataFileName
			LoadW	r6 ,GW_FileName
			LoadB	r0L,%10000000
			jsr	GetFile			;ext. Symboltabelle öffnen.

			jmp	StartMainMenu

;*** GeoWrite normal starten.
:OpenGeoWrite		lda	Opt_BootDrive
			jsr	FindGeoWrite		;GeoWrite suchen.

			jsr	LoadFileInit		;GEOS-Variablen löschen.
			jsr	UseSystemFont		;GEOS-Font aktivieren.

			LoadW	r6,GW_FileName
			LoadB	r0L,%00000000
			jmp	GetFile			;GeoWrite starten.

;*** Initialisieren "GW-Datei öffnen".
:FindGeoWrite		jsr	GotoFirstMenu		;Hauptmenü aktivieren.

			lda	#$00
			sta	:1 +1
::1			ldx	#$ff
			cpx	#$04
			beq	:2
			lda	FindFileDriveTab,x
			bne	:4
::2			lda	Opt_BootDrive
			jsr	NewSetDevice
			jsr	GetDirHead
			ldx	#$05
::3			rts

::4			jsr	NewSetDevice
			jsr	GetDirHead

			LoadW	r6 ,GW_FileName
			LoadB	r7L,APPLICATION
			LoadB	r7H,$01
			LoadW	r10,ClassGeoWrite
			jsr	FindFTypes		;GeoWrite suchen.
			txa
			bne	:5

			ldx	r7H
			beq	:3
::5			inc	:1 +1
			jmp	:1

;*** Zeiger auf Diskettennamen berechnen.
:GetDskNameVec		sec
			sbc	#$08
			asl
			tax
			lda	DiskNameVec +0,x
			sta	r0L
			lda	DiskNameVec +1,x
			sta	r0H

			lda	#< dataDiskName
			sta	r2L
			lda	#> dataDiskName
			sta	r2H

			ldy	#16 -1
::1			lda	(r0L),y
			sta	(r2L),y
			dey
			bpl	:1

			rts

;*** Menü "Parameter" aktualisieren.
:SetMenParData		lda	#PLAINTEXT
			bit	c128Flag
			bmi	:1
			lda	#ITALICON
::1			sta	MT02b

			lda	Opt_SourceDrive
			clc
			adc	#$39
			sta	MT04a +10

			lda	#ITALICON
			ldx	Opt_SourceDrive
			cpx	Opt_BootDrive
			beq	:2
			lda	#PLAINTEXT
::2			sta	MT04b

			lda	#ITALICON
			ldx	Opt_TargetDrive
			cpx	Opt_BootDrive
			beq	:3
			lda	#PLAINTEXT
::3			sta	MT04r

			lda	#ITALICON
			ldx	Opt_AutoTxtDrive
			cpx	Opt_BootDrive
			beq	:3a
			lda	#PLAINTEXT
::3a			sta	MT04s

			lda	Opt_TargetDrive
			clc
			adc	#$39
			sta	MT04c +9

			lda	Opt_ErrFileDrive
			clc
			adc	#$39
			sta	MT04d +9

			lda	Opt_SymbTabDrive
			clc
			adc	#$39
			sta	MT04e +9

			lda	Opt_AutoMode
			jsr	DefCurrentMode
			sta	MT04f

			lda	Opt_AutoTxtDrive
			clc
			adc	#$39
			sta	MT04g +9

			lda	Opt_SymbTab
			jsr	DefCurrentMode
			sta	MT04h

			lda	Opt_ExtSymbTab
			jsr	DefCurrentMode
			sta	MT04i

			lda	Opt_OverWrite
			jsr	DefCurrentMode
			sta	MT04l

			lda	Opt_POpcodeTest
			jsr	DefCurrentMode
			sta	MT04n

			lda	Opt_MouseCancel
			jsr	DefCurrentMode
			sta	MT04o

			ldy	#$00
			ldx	#$00
::4			lda	#PLAINTEXT
			sta	DriveTextA,x
			lda	driveType,y
			bne	:5
			lda	#ITALICON
			sta	DriveTextA,x
::5			txa
			clc
			adc	#13
			tax
			iny
			cpy	#$04
			bne	:4

			bit	Flag_FileCreated
			bpl	:7

			lda	Hdr_GEOS_Type
			cmp	#APPLICATION
			beq	:6
			cmp	#AUTO_EXEC
			bne	:7

::6			LoadW	r0,ObjectFileName
			LoadW	r1,MT06c1
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

::7			LoadW	r0,ScreenText4
			LoadW	r1,MT06c1
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Modus für Menüanzeige festlegen.
:DefCurrentMode		cmp	#$00
			beq	:1
			lda	#"*"
			b $2c
::1			lda	#" "
			rts

;*** Befehlszähler löschen.
:ClearCounter		ldy	#$03
			lda	#$00
::1			sta	CodeCounter,y
			sta	ByteCounter,y
			sta	IconCounter,y
			dey
			bpl	:1

;*** Befehlszähler ausgeben.
:PrntCodeCount		jsr	i_PutString
:K304			w	$000f
			b	$38
			b	"Befehle/Bytes/Icons",NULL
			jsr	SetInfoXPos

			PushB	r1H
			jsr	GetCodeCounter
			PopB	r1H

			jsr	PrintCount
			lda	#"/"
			jsr	SmallPutChar

			PushB	r1H
			jsr	GetByteCounter
			PopB	r1H

			jsr	PrintCount
			lda	#"/"
			jsr	SmallPutChar

			PushB	r1H
			jsr	GetIconCounter
			PopB	r1H

			jsr	PrintCount

			LoadW	r0,ScreenText6
			jmp	PutString

:PrintCount		LoadW	r0,ComCountTxt1

			ldy	#$00
::3			lda	(r0L),y
			beq	:4
			cmp	#"0"
			bne	:5
			iny
			bne	:3
			beq	:6

::4			dey
::5			tya
			clc
			adc	r0L
			sta	r0L
			bcc	:6
			inc	r0H
::6			jmp	PutString

;*** Anzahl Befehle in Menü eintragen.
:GetCodeCounter		MoveB	CodeCounter +0,r0L
			MoveB	CodeCounter +1,r0H
			MoveB	CodeCounter +2,r1L
			MoveB	CodeCounter +3,r1H
			jmp	DefCountText

;*** Anzahl Bytes in Menü eintragen.
:GetByteCounter		MoveB	ByteCounter +0,r0L
			MoveB	ByteCounter +1,r0H
			MoveB	ByteCounter +2,r1L
			MoveB	ByteCounter +3,r1H
			jmp	DefCountText

;*** Anzahl Icons in Menü eintragen.
:GetIconCounter		MoveB	IconCounter +0,r0L
			MoveB	IconCounter +1,r0H
			MoveB	IconCounter +2,r1L
			MoveB	IconCounter +3,r1H

:DefCountText		ldx	#$09
			lda	#"0"
::1			sta	ComCountTxt1,x
			dex
			bpl	:1

			ldx	#$00
			ldy	#$00
::2			lda	r1H
			cmp	DezimalData +3,y
			bne	:3
			lda	r1L
			cmp	DezimalData +2,y
			bne	:3
			lda	r0H
			cmp	DezimalData +1,y
			bne	:3
			lda	r0L
			cmp	DezimalData +0,y
::3			bcc	:4

			sec
			lda	r0L
			sbc	DezimalData +0,y
			sta	r0L
			lda	r0H
			sbc	DezimalData +1,y
			sta	r0H
			lda	r1L
			sbc	DezimalData +2,y
			sta	r1L
			lda	r1H
			sbc	DezimalData +3,y
			sta	r1H
			inc	ComCountTxt1,x
			jmp	:2

::4			iny
			iny
			iny
			iny
			inx
			cpx	#10
			bcc	:2
			rts

;*** Menübildschirm zeichnen.
:PrntMenuScrn		lda	#$01
			jsr	SetPattern
			jsr	i_Rectangle
			b	$02,$0e
:K201			w	$00c3,$013b
			jsr	i_Rectangle
			b	$03,$0e
:K202			w	$00c1,$013d
			jsr	i_Rectangle
			b	$04,$0e
:K203			w	$00c0,$013e

			lda	#$09
			jsr	SetPattern
			jsr	i_Rectangle
			b	$02,$0e
:K204			w	$00c4,$013a
			jsr	i_Rectangle
			b	$03,$0e
:K205			w	$00c2,$013c
			jsr	i_Rectangle
			b	$04,$0e
:K206			w	$00c1,$013d

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$03,$0d
:K207			w	$00c8,$0136

			jsr	i_PutString
:K208			w	$00d0
			b	$0b
			b	PLAINTEXT,BOLDON
			b	"* MegaAssembler *",NULL

			lda	#$0e
			jsr	ClrInfoArea

			lda	#$09
			jsr	SetPattern
			jsr	i_Rectangle
			b	$0e,$1a
:K210			w	$0000,$013f

			jsr	i_PutString
:K211			w	$000f
			b	$16
			b	BOLDON
			b	" Systeminformationen ",NULL
			rts

;*** Teilbereich Infobildschirm löschen.
:ClrInfoArea		sta	:1

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
::1			b	$0e,$c7
:K209			w	$0000,$013f

			rts

;*** Infofenster zeichnen.
:PrntCodeInfo		jsr	i_PutString
:K301			w	$000f
			b	$24
			b	"Quelltext",NULL
			LoadW	r0 ,SelectedFile
			jsr	PrintInfoText

			jsr	i_PutString
:K302			w	$000f
			b	$2e
			b	"Objektdatei",NULL
			jsr	SetInfoXPos

			bit	Flag_FileCreated
			bpl	:1
			LoadW	r0 ,ObjectFileName
			jsr	PutString

::1			jsr	PrntCodeCount
			jsr	DefAssTime

			jsr	i_PutString
:K303			w	$000f
			b	$4c
			b	"Fehlerliste",NULL
			lda	#$00
			tax
			bit	Flag_ErrFileOK
			bpl	:1
			lda	#<ErrFileName
			ldx	#>ErrFileName
::1			sta	r0L
			stx	r0H
			jsr	PrintInfoText

			jsr	i_PutString
:K306			w	$000f
			b	$56
			b	"Fehler im Quelltext",NULL
			jsr	SetInfoXPos

			lda	ErrCount
			beq	:1

			MoveB	ErrCount,r0L
			LoadB	r0H,$00
			lda	#%11000000
			jsr	PutDecimal

			bit	ErrOverflow
			bpl	:1
			LoadW	r0,ScreenText3
			jmp	PutString

::1			rts

;*** Symbolspeicher-Informationen.
:PrntSymbTabInfo	jsr	i_PutString
:K401			w	$000f
			b	$60
			b	"Symboltabelle",NULL
			lda	#$00
			tax
			bit	Flag_SymbFileOK
			bpl	:1
			lda	#<SymFileName
			ldx	#>SymFileName
::1			sta	r0L
			stx	r0H
			jsr	PrintInfoText

			jsr	i_PutString
:K402			w	$000f
			b	$6a
			b	"Externe Symboltabelle",NULL
			lda	#$00
			tax
			bit	Flag_ExtSFileOK
			bpl	:1
			lda	#<ExtFileName
			ldx	#>ExtFileName
::1			sta	r0L
			stx	r0H
			jsr	PrintInfoText

			jsr	i_PutString
:K403			w	$000f
			b	$74
			b	"Freier Symbolspeicher",NULL

			jsr	SetInfoXPos

			lda	Vec_EndLabelTab +0
			sec
			sbc	Vec_EndLabels1  +0
			sta	r0L
			lda	Vec_EndLabelTab +1
			sbc	Vec_EndLabels1  +1
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal
			LoadW	r0,:1
			jmp	PutString

::1			b " Bytes",NULL

:PrnWordHex_Sub		MoveW	r0,WordBuffer		;Word-Adresse merken.

			lda	#"$"
			jsr	PutChar			;HEX-Kennbyte ausgeben.

			jsr	ConvWord2HEX		;Wert nach HEX wandeln und
			LoadW	r0,BufferHEX		;HEX-Text auf Bildschirm
			jmp	PutString		;ausgeben.

;*** Datei-Informationen ausgeben.
:PrntFileInfo		jsr	i_PutString
:K501			w	$000f
			b	$7e
			b	"Ladeadresse (o)",NULL
			jsr	SetInfoXPos
			MoveW	Header +$47,r0
			jsr	PrnWordHex_Sub

			jsr	i_PutString
:K502			w	$000f
			b	$88
			b	"Startadresse (p)",NULL
			jsr	SetInfoXPos
			MoveW	Header +$4b,r0
			jsr	PrnWordHex_Sub

			jsr	i_PutString
:K503			w	$000f
			b	$92
			b	"Endadresse (q)",NULL
			jsr	SetInfoXPos
			lda	Header +$49
			ldx	Header +$4a
			cmp	Header +$47
			bne	:1
			cpx	Header +$48
			beq	:2
::1			sec
			sbc	#$01
			bcs	:2
			dex
::2			sta	r0L
			stx	r0H
			jsr	PrnWordHex_Sub

			jsr	i_PutString
:K505			w	$000f
			b	$9c
			b	"Maximale Endadresse (r)",NULL
			jsr	SetInfoXPos
			MoveW	ProgMaxEndAdr,r0
			jsr	PrnWordHex_Sub

			jsr	i_PutString
:K504			w	$000f
			b	$a6
			b	"Bereich Objectcode",NULL

			LoadB	AssCodeArea +6,$00
			LoadW	r0,ScreenText2
			jsr	PrintInfoText
			LoadW	r0,AssCodeArea
			jsr	PutString
			LoadW	r0,ScreenText1
			jsr	PutString
			LoadW	r0,AssCodeArea +7
			jsr	PutString

			jsr	i_PutString
:K505a			w	$000f
			b	$b0
			b	"Bereichsgrenze (g/e)",NULL
			jsr	SetInfoXPos
			MoveW	LastTestAdr,r0
			jsr	PrnWordHex_Sub

;*** Disknamen aktualisieren.
:PrntDiskInfo		lda	#$b4
			jsr	ClrInfoArea

			jsr	i_PutString
:K506			w	$000f
			b	$ba
			b	BOLDON,"Disk A:",PLAINTEXT,NULL
			LoadW	r0 ,DrvADskNam
			jsr	PutString

			jsr	i_PutString
:K507			w	$000f
			b	$c4
			b	BOLDON,"Disk B:",PLAINTEXT,NULL
			LoadW	r0 ,DrvBDskNam
			jsr	PutString

			jsr	i_PutString
:K508			w	$00a0
			b	$ba
			b	BOLDON,"Disk C:",PLAINTEXT,NULL
			LoadW	r0 ,DrvCDskNam
			jsr	PutString

			jsr	i_PutString
:K509			w	$00a0
			b	$c4
			b	BOLDON,"Disk D:",PLAINTEXT,NULL
			LoadW	r0 ,DrvDDskNam
			jmp	PutString

;*** X-Position berechnen.
:PrintInfoText		jsr	SetInfoXPos
			lda	r0L
			ora	r0H
			beq	:1
			jmp	PutString
::1			rts

;*** Info-Textausgabe definieren.
:SetInfoXPos		lda	#$ff
			sta	r11L
			lda	#$ff
			sta	r11H
			lda	#":"
			jsr	SmallPutChar
			lda	#" "
			jmp	SmallPutChar

;*** Zahl in Hex und Dezimal ausgeben.
:PrnWordHexDez		jsr	SetInfoXPos
			jsr	PrnWordHex_Sub

			lda	#" "			;Abstand zwischen HEX und DEZ.
			jsr	PutChar

			lda	#"("			;Zahl in Klammern ausgeben.
			jsr	PutChar
			MoveW	WordBuffer,r0		;Dezimal-Zahl auf Bildschirm
			lda	#%11000000		;ausgeben.
			jsr	PutDecimal
			lda	#")"
			jmp	PutChar

;*** Byte in DezimalASCII wandeln.
:ConvDezASCII_Byte	LoadB	r0L,$00
			ldx	Buffer1 +0
			beq	:3
			lda	Buffer1 +1
			bne	:1
			txa
			ldx	#$30
::1			sec
			sbc	#$30
			sta	r0L
			txa
			sec
			sbc	#$30
			tax
			beq	:3
::2			AddVB	10,r0L
			dex
			bne	:2
::3			rts

;*** Byte in DezimalASCII wandeln.
:ConvByte_DezASCII	ldx	#"0"
::1			cmp	#10
			bcc	:2
			sbc	#10
			inx
			bne	:1
::2			adc	#"0"
			sta	r0L
			stx	r0H
			rts

;*** Word nach HEX wandeln.
:ConvWord2HEX		lda	r0H
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +0
			lda	r0H
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +1
			lda	#$00
			sta	BufferHEX +2
			lda	r0L
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +2
			lda	r0L
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +3
			lda	#$00
			sta	BufferHEX +4
			rts

;*** Zeitmessung neu starten.
:ClearTimeFlag		lda	#$ff
			sta	Flag_SaveTime
			lda	#$00
			sta	StartAssTime +0
			sta	StartAssTime +1
			sta	StartAssTime +2
			jmp	DefAssTime

;*** Uhrzeit aktualisieren.
:UpdateTime		LoadW	appMain,:1		;Zeiger auf Programm.
			jmp	MainLoop		;MainLoop starten. Dadurch die
							;Uhrzeit aktualisieren.

::1			pla				;MainLoop-Rücksprung löschen.
			pla
			lda	#$00			;Programmvektor löschen.
			sta	appMain
			sta	appMain +1
			rts

;*** Start der Assemblierung merken.
:SetStartAssTime	bit	Flag_SaveTime		;Uhrzeit speichern ?
			bpl	:1			;Nein, Ende...

			jsr	UpdateTime		;Aktuelle Uhrzeit holen.

			lda	hour			;Uhrzeit zwischenspeichern.
			sta	StartAssTime +0
			lda	minutes
			sta	StartAssTime +1
			lda	seconds
			sta	StartAssTime +2

			lda	#$00
			sta	Flag_SaveTime
::1			rts

;*** Uhrzeit anzeigen.
:DefAssTime		bit	Flag_SaveTime
			bpl	:1
			lda	#$00			;Uhrzeit noch nicht definiert,
			pha				;"00:00:00" anzeigen.
			pha
			pha
			jmp	:5

::1			jsr	UpdateTime		;Aktuelle Uhrzeit holen.

			sec				;Differenz zwischen Start- und
			lda	seconds			;Endzeit berechnen.
			sbc	StartAssTime +2
			bcs	:2
			sec
			sbc	#196
			clc
::2			pha
			lda	minutes
			sbc	StartAssTime +1
			bcs	:3
			sec
			sbc	#196
			clc
::3			pha
			lda	hour
			sbc	StartAssTime +0
			bcs	:4
			sec
			sbc	#232
::4			pha

::5			jsr	i_PutString
:K305			w	$000f
			b	$42
			b	"Benötigte Zeit",NULL
			jsr	SetInfoXPos

			pla
			jsr	ConvByte_DezASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			pla
			jsr	ConvByte_DezASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			pla
			jsr	ConvByte_DezASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			LoadW	r0,ScreenText6
			jmp	PutString

;*** Einträge für Menü "geos" berechnen.
:DefMenu_GEOS		lda	Opt_BootDrive		;Start-Laufwerk öffnen.
			jsr	NewSetDevice
			jsr	NewOpenDisk

			lda	DM_geos  +0
			clc
			adc	#29
			sta	DM_geos  +1
			LoadB	DM_geos  +6,$02 ! VERTICAL ! UN_CONSTRAINED

			LoadW	a0 ,DM_geos
			LoadW	r6 ,MT02c
			LoadB	r7L,DESK_ACC
			LoadB	r7H,8
			LoadW	r10,$0000

;*** Dateitypen suchen.
:FindFileTypes		lda	r7H
			pha
			jsr	FindFTypes
			pla
			sec
			sbc	r7H

;*** Länge des Menüs "geos" berechnen.
::1			sta	a2L

			ldy	#$06
			lda	(a0L),y
			and	#%00111111
			clc
			adc	a2L
			ora	#VERTICAL ! UN_CONSTRAINED
			sta	(a0L),y

			LoadB	a2H,$00
			LoadW	a3 ,$000e
			ldx	#a2L
			ldy	#a3L
			jsr	DMult

			ldy	#$01
			lda	(a0L),y
			clc
			adc	a2L
			sta	(a0L),y
			clc
			rts

;*** Textdateien einlesen.
:DefMenu_Text		lda	#$00
			sta	Poi_1stEntryInTab
:GetMenu_Text		lda	#$00
			sta	TxtFilesOnDsk

			LoadB	DM_Texte +6,$00 ! VERTICAL ! UN_CONSTRAINED

			bit	Opt_AutoMode
			bmi	:1

			lda	Opt_SourceDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk
			LoadW	r6 ,$4000
			LoadB	r7L,APPL_DATA
			LoadB	r7H,144
			LoadW	r10,ClassWriteImage
			jmp	:2

::1			lda	Opt_AutoTxtDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk
			LoadW	r6 ,$4000
			LoadB	r7L,SYSTEM
			LoadB	r7H,144
			LoadW	r10,ClassAutoExec

::2			jsr	FindFTypes

			lda	#144
			sec
			sbc	r7H
			sta	MaxTextFiles
			cmp	#$00
			bne	CopyNewFiles

			LoadW	r4,NoTextFile
			LoadW	r5,MT03a
			ldx	#r4L
			ldy	#r5L
			jsr	CopyString

			LoadB	DM_Texte +1,$1d
			LoadB	DM_Texte +6,$01 ! VERTICAL ! UN_CONSTRAINED
			LoadB	SelectedFile,NULL
			inc	TxtFilesOnDsk
			rts

;*** Weitere texte in Menü einblenden.
:CopyNewFiles		lda	Poi_1stEntryInTab
			cmp	MaxTextFiles
			bcc	:1
			lda	#$00
			sta	Poi_1stEntryInTab

::1			lda	Poi_1stEntryInTab
			sta	r0L
			LoadB	r0H,$00
			LoadW	r1 ,$0011
			ldx	#r0L
			ldy	#r1L
			jsr	DMult
			AddVW	$4000,r0
			LoadW	r1,MT03a
			LoadB	r2L,$00
			LoadB	r2H,$0f

			lda	Poi_1stEntryInTab
			sta	r3L

			lda	MaxTextFiles
			cmp	#MaxTextEntry
			bcc	:3

			lda	MaxTextFiles
			sec
			sbc	r3L
			cmp	#MaxTextEntry -1
			bcs	:2

			LoadW	r4,Go1stTextFile
			ldx	#r4L
			jsr	AddTextToList
			jmp	:3

::2			LoadW	r4,MoreTextFiles
			ldx	#r4L
			jsr	AddTextToList

::3			ldy	#$00
			lda	(r0L),y
			beq	:4

			ldx	#r0L
			jsr	AddTextToList
			AddVW	17,r0
			inc	r3L

			lda	r2L
			cmp	#MaxTextEntry
			beq	:4
			lda	r3L
			cmp	MaxTextFiles
			bcc	:3
::4			lda	r2L
			ora	#VERTICAL ! UN_CONSTRAINED
			sta	DM_Texte +6
			lda	r2H
			sta	DM_Texte +1
			rts

;** Eintrag in Tabelle kopieren.
:AddTextToList		ldy	#r1L
			jsr	CopyString

			AddVW	17,r1
			AddVB	14,r2H
			inc	r2L
			rts

;*** Diskettennamen einlesen.
:GetDiskNames		lda	#$00			;Keine Diskette in...
			sta	DrvADskNam		;Laufwerk A: verfügbar.
			sta	DrvBDskNam		;Laufwerk B: verfügbar.
			sta	DrvCDskNam		;Laufwerk C: verfügbar.
			sta	DrvDDskNam		;Laufwerk D: verfügbar.

			LoadW	r15,DrvADskNam
			ldx	#$08
			jsr	GetDiskName

			LoadW	r15,DrvBDskNam
			ldx	#$09
			jsr	GetDiskName

			LoadW	r15,DrvCDskNam
			ldx	#$0a
			jsr	GetDiskName

			LoadW	r15,DrvDDskNam
			ldx	#$0b

;*** Diskettenname aus Laufwerk X: einlesen.
:GetDiskName		lda	driveType -8,x
			bne	:2
::1			rts

::2			txa
			jsr	NewSetDevice		;Laufwerk A: aktivieren.
			jsr	NewOpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:1			;Nein, weiter...

			ldx	#r14L
			jsr	GetPtrCurDkNm

			ldy	#$00
::3			lda	(r14L),y
			jsr	ConvertChar
			sta	(r15L),y
			iny
			cpy	#$10
			bcc	:3
			rts

;*** Zeichen für ":PutChar" konvertieren.
:ConvertChar		cmp	#$00
			beq	:1
			and	#$7f
			cmp	#" "
			bcs	:1
			lda	#"."
::1			rts

;*** Diskette wechseln.
:ChangeAutoDisk		lda	Opt_AutoTxtDrive
			jmp	ChangeDisk

:ChangeSrcDisk		lda	Opt_SourceDrive
			jmp	ChangeDisk

:ChangeTgtDisk		lda	Opt_TargetDrive

:ChangeDisk		cmp	Opt_BootDrive		;Diskwechsel möglich ?
			beq	:exit			;Nein, Abbruch...

			pha
			jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			pla
			tax

			lda	MP3_CODE +0
			cmp	#"M"
			bne	:skip
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:skip

			lda	RealDrvMode -8,x
			bpl	:skip

			txa
			jsr	SetDevice
			jsr	NewDisk
			txa
			bne	:skip

			lda	#< Dlg_SlctPart
			sta	r0L
			lda	#> Dlg_SlctPart
			sta	r0H
			lda	#< dataFileName
			sta	r5L
			lda	#> dataFileName
			sta	r5H
			jsr	DoDlgBox

::skip			LoadB	SelectedFile,NULL

			jsr	GetDiskNames
			jsr	DefMenu_Text
			jmp	PrntDiskInfo
::exit			jmp	ReDoMenu

;*** Modus für "Symboltabelle erzeugen" festlegen.
:DefSymbTab		lda	Opt_SymbTab
			eor	#$ff
			sta	Opt_SymbTab
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Modus für "ext. Symboltabelle erzeugen" festlegen.
:DefExtSymbTab		lda	Opt_ExtSymbTab
			eor	#$ff
			sta	Opt_ExtSymbTab
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Modus für "Sicherheitsabfrage" festlegen.
:OverWriteMode		lda	Opt_OverWrite
			eor	#$ff
			sta	Opt_OverWrite
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Modus für "PseudoOpcodes testen" festlegen.
:POpcodeTestMode	lda	Opt_POpcodeTest
			eor	#$ff
			sta	Opt_POpcodeTest
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Modus für Abbruch-Funktion.
:MouseCancelMode	lda	Opt_MouseCancel
			eor	#$ff
			sta	Opt_MouseCancel
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Modus für "Auto-Assembler" festlegen.
:DefAutoMode		jsr	RecoverMenu

			lda	Opt_AutoMode
			eor	#$ff
			sta	Opt_AutoMode

			jsr	SetMenParData

			lda	#$00
			sta	Flag_FileCreated
			jsr	DefMenu_Text
			jmp	ReDoMenu

;*** Aktuelle Parameter speichern.
:SaveParameter		jsr	FindMegaAss
			txa
			beq	:2
::1			jmp	SystemError

::2			lda	dirEntryBuf +$13
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock einlesen.

			lda	Opt_SourceDrive
			sta	diskBlkBuf +$90		;Laufwerk für Quelltext.
			lda	Opt_TargetDrive
			sta	diskBlkBuf +$91		;Laufwerk für Code-Ausgabe.
			lda	Opt_ErrFileDrive
			sta	diskBlkBuf +$92		;Laufwerk für Fehlerdatei.
			lda	Opt_SymbTabDrive
			sta	diskBlkBuf +$93		;Laufwerk für Symboltabellen.
			lda	Opt_AutoTxtDrive
			sta	diskBlkBuf +$94		;Laufwerk für AutoText-Datei.

			lda	Opt_AutoMode
			sta	diskBlkBuf +$95		;Modus für AutoText.
			lda	Opt_SymbTab
			sta	diskBlkBuf +$96		;Modus für ext. Symboltabelle.
			lda	Opt_ExtSymbTab
			sta	diskBlkBuf +$97		;Modus für Symboltabelle.
			lda	Opt_OverWrite
			sta	diskBlkBuf +$98		;Modus für Sicherheitsabfrage.
			lda	Opt_POpcodeTest
			sta	diskBlkBuf +$9b		;Modus für PseudoOpcodes testen.
			lda	Opt_MouseCancel
			sta	diskBlkBuf +$9c		;Modus für Abbruch-Funktion.

			lda	dirEntryBuf +$13
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Infoblock speichern.
			jmp	GotoFirstMenu		;Hauptmenü aktivieren.

;*** Parameter einlesen.
:LoadParameter		jsr	FindMegaAss
			txa
			beq	:2
::1			jmp	SystemError

::2			lda	dirEntryBuf +$13
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock einlesen.
			txa
			bne	:1

			lda	diskBlkBuf +$90		;Laufwerk für Quelltext.
			bne	:3
			lda	Opt_BootDrive
::3			sta	Opt_SourceDrive
			sta	Opt_SourceDriveOrig

			lda	diskBlkBuf +$91		;Laufwerk für Code-Ausgabe.
			bne	:4
			lda	Opt_BootDrive
::4			sta	Opt_TargetDrive

			lda	diskBlkBuf +$92		;Laufwerk für Fehlerdatei.
			bne	:5
			lda	Opt_BootDrive
::5			sta	Opt_ErrFileDrive

			lda	diskBlkBuf +$93		;Laufwerk für Symboltabellen.
			bne	:6
			lda	Opt_BootDrive
::6			sta	Opt_SymbTabDrive

			lda	diskBlkBuf +$94		;Laufwerk für AutoText-Datei.
			bne	:7
			lda	Opt_BootDrive
::7			sta	Opt_AutoTxtDrive

			lda	diskBlkBuf +$95		;Modus für AutoText.
			sta	Opt_AutoMode
			lda	diskBlkBuf +$96		;Modus für Symboltabelle.
			sta	Opt_SymbTab
			lda	diskBlkBuf +$97		;Modus für ext. Symboltabelle.
			sta	Opt_ExtSymbTab
			lda	diskBlkBuf +$98		;Modus für Sicherheitsabfrage.
			sta	Opt_OverWrite
			lda	diskBlkBuf +$99		;Modus für Sicherheitsabfrage.
			sta	Opt_IgnoreFileMode
			lda	diskBlkBuf +$9a		;Modus für Dateilänge.
			sta	Opt_FileLenMode
			lda	diskBlkBuf +$9b		;Modus für PseudoOpcodes testen.
			sta	Opt_POpcodeTest
			lda	diskBlkBuf +$9c		;Modus für Abbruch-Funktion.
			sta	Opt_MouseCancel

			jmp	SetMenParData

;*** Laufwerk wählen.
:SlctSourceDrv		ldx	#$00
			b $2c
:SlctTargetDrv		ldx	#$01
			b $2c
:SlctErrFileDrv		ldx	#$02
			b $2c
:SlctSymbTabDrv		ldx	#$03
			b $2c
:SlctAutoTxtDrv		ldx	#$04
			stx	DrvSlctMode
			lda	DrvMenuYPos,x
			sta	DM_SlctDrive +0
			clc
			adc	#4*14 +1
			sta	DM_SlctDrive +1
			LoadW	r0,DM_SlctDrive
			rts

:DefDriveA		lda	#$08
			b $2c
:DefDriveB		lda	#$09
			b $2c
:DefDriveC		lda	#$0a
			b $2c
:DefDriveD		lda	#$0b
			ldx	DrvSlctMode
			bne	:1
			sta	Opt_SourceDrive
			sta	Opt_SourceDriveOrig
			jsr	DefMenu_Text
			jmp	:5

::1			dex
			bne	:2
			sta	Opt_TargetDrive
			beq	:5

::2			dex
			bne	:3
			sta	Opt_ErrFileDrive
			beq	:5

::3			dex
			bne	:4
			sta	Opt_SymbTabDrive
			beq	:5

::4			dex
			bne	:5
			sta	Opt_AutoTxtDrive
			jsr	DefMenu_Text

::5			jsr	SetMenParData
			jmp	DoPreviousMenu

;*** Quelltext wählen.
:SlctTextFile		pha
			lda	TxtFilesOnDsk		;Quelltexte verfügbar ?
			beq	:0			;Ja, weiter...
			pla
			jmp	DoPreviousMenu

::0			jsr	MouseUp
::1			lda	mouseData
			bpl	:1
			LoadB	pressFlag,NULL
			jsr	MouseOff

			jsr	SetStartAssTime

			pla
			sta	a0L
			LoadB	a0H,$00
			LoadW	a1, $0011
			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			AddVW	MT03a,a0		;Zeiger auf Eintrag berechnen.

			ldy	#$01
			lda	(a0L),y
			cmp	#BOLDON
			beq	:3

			jsr	GotoFirstMenu		;Hauptmenü aktivieren.

			bit	Opt_AutoMode
			bmi	:2
			jmp	StartAssemble

::2			LoadW	a1,NameOfAutoExec
			ldx	#a0L
			ldy	#a1L
			jsr	CopyString		;Dateiname kopieren.
			jmp	StartAutoExec

::3			jsr	RecoverMenu

			lda	DM_Texte +6
			and	#%00111111
			sec
			sbc	#$02
			adc	Poi_1stEntryInTab
			sta	Poi_1stEntryInTab

			jsr	CopyNewFiles
			jmp	ReDoMenu

;*** Gewählte Datei assemblieren.
:StartAssemble		LoadW	a1,SelectedFile
			ldx	#a0L
			ldy	#a1L
			jsr	CopyString		;Dateiname kopieren.

			jsr	FindMegaAss
			txa
			beq	:2
::1			jmp	SystemError

::2			LoadW	r3,StdFileName
			LoadW	r4,ObjectFileName
			ldx	#r3L
			ldy	#r4L
			jsr	CopyString
			jmp	Mod_Assembler

;*** AutoAssembler-Funktion aktivieren..
:StartAutoExec		jsr	FindAutoAssFile
			txa
			beq	:1
			jmp	StartMegaAss

::1			lda	#$ff
			sta	Flag_AutoAssInWork
			LoadW	Vec_AutoAssText,$4000
			jmp	GetNextCom

;*** AutoExec-Datei suchen.
:FindAutoAssFile	lda	Opt_AutoTxtDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,NameOfAutoExec
			jsr	FindFile
			txa
			bne	:1

			LoadW	r7,$4000
			LoadW	r2,16384
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	ReadFile
::1			rts

;*** Nächsten Befehl auswerten.
:GetNextCom		jsr	FindAutoAssFile
			txa
			beq	CheckCommand

;Zurück zum MegaAssembler.
;Quelltext-Laufwerk auf Benutzer-Einstellung
;zurücksetzen falls über $f2='Quelltext-Laufwerk wechseln'
;das Laufwerk verändert wurde.
:ExitAutoAss		lda	#$00
			sta	Flag_AutoAssInWork
			lda	Opt_SourceDriveOrig
			sta	Opt_SourceDrive
			jmp	DoInfoScreen

:CheckCommand		MoveW	Vec_AutoAssText,a0

			ldy	#$00
			lda	(a0L),y
			inc	a0L
			bne	:1
			inc	a0H

::1			cmp	#$f0
			bne	:2
			jmp	AutoSelectFile

::2			cmp	#$f1
			bne	:3
			jmp	AutoUserJob

::3			cmp	#$f2
			bne	:4
			jmp	AutoSwitchSrcDrv

::4			cmp	#$f5
			bne	:5
			jmp	AutoStartVLink

::5			jmp	ExitAutoAss

;*** Nächste Datei assemblieren.
:AutoSelectFile		ldy	#$00
::1			lda	(a0L),y
			sta	Buf_FileName,y
			beq	:2
			iny
			cpy	#17
			bcc	:1
			jmp	ExitAutoAss

::2			iny
			tya
			clc
			adc	a0L
			sta	a0L
			bcc	:3
			inc	a0H
::3			MoveW	a0,Vec_AutoAssText
			LoadW	a0,Buf_FileName
			jmp	StartAssemble

;*** Anwender-Routine ausführen.
:AutoUserJob		jsr	:1
			MoveW	a0,Vec_AutoAssText
			jmp	StartMegaAss

::1			MoveB	Opt_SourceDrive,a1L
			MoveB	Opt_TargetDrive,a1H
			MoveB	Opt_SourceDriveOrig,a2L
			jmp	(a0)

;*** Quelltext-Laufwerk wechseln.
:AutoSwitchSrcDrv	ldy	#$00
			lda	(a0L),y
			inc	a0L
			bne	:1
			inc	a0H
::1			tax
			bne	:2
			lda	Opt_SourceDriveOrig
::2			sta	Opt_SourceDrive
			jsr	NewSetDevice
			txa
			bne	:3
			jsr	NewOpenDisk
			txa
			bne	:3
			MoveW	a0,Vec_AutoAssText
			jmp	StartMegaAss
::3			jmp	ExitAutoAss

;*** VLink starten.
:AutoStartVLink		MoveW	a0,Vec_AutoAssText
			jmp	Mod_VLink

;*** Zwischen 40 und 80-Zeichen-Modus wechseln.
:Switch40_80		jsr	GotoFirstMenu		;Hauptmenü aktivieren.

			lda	c128Flag		;C128-Modus ?
			bpl	:1			;Nein, Abbruch...
			jsr	SwapGrfxMode		;Grafikmodus umschalten.
			lda	Opt_BootDrive		;MegaAssembler-Laufwerk
			jsr	NewSetDevice		;aktivieren.
			jsr	NewOpenDisk
			jmp	DoInfoScreen
::1			rts

;*** Grafikmodus wechseln, X-Koordinaten anpassen.
:SwapGrfxMode		lda	graphMode		;Grafikmodus umschalten.
			eor	#$80
			sta	graphMode
			sta	ScreenMode
			jsr	SetNewMode

:SetXpos40_80		lda	c128Flag		;C128-Modus ?
			bpl	:1			;Nein, 40-Zeichen aktivieren.
			lda	graphMode		;80-Zeichen-Modus aktiv ?
			bmi	:2			;Ja, weiter...

::1			LoadW	r0,Word40_Data		;40-Zeichen-Modus.
			jsr	DefWordData
			LoadW	r0,Byte40_Data
			jmp	DefByteData

::2			LoadW	r0,Word80_Data		;80-Zeichen-Modus.
			jsr	DefWordData
			LoadW	r0,Bye80_Data
			jmp	DefByteData

;*** 40/80-Zeichen Words definieren.
:DefWordData		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			ora	r1L
			beq	:1
			iny
			lda	(r0L),y
			sta	r2L
			iny
			lda	(r0L),y
			sta	r2H
			ldy	#$00
			lda	r2L
			sta	(r1L),y
			iny
			lda	r2H
			sta	(r1L),y
			AddVW	4,r0
			jmp	DefWordData
::1			rts

;*** 40/80-Zeichen Bytes definieren.
:DefByteData		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			ora	r1L
			beq	:2
			iny
			lda	(r0L),y
			ldy	#$00
			sta	(r1L),y
			AddVW	3,r0
			jmp	DefByteData
::2			rts

;*** Zurück zum BASIC des C64/C128.
:ExitBASIC		jsr	GotoFirstMenu

			lda	curDrive		;Laufwerk aktivieren.
			jsr	NewSetDevice
			jsr	PurgeTurbo		;TurboDOS desktivieren, sonst ist
							;kein BASIC-Zugriff möglich!

			bit	c128Flag		;C64 / C128 ?
			bpl	C64BASIC		; -> C64-Reset!

;*** Nach BASIC verlassen: C128.
:C128BASIC		sei
			LoadB	$ff00,%01001111
			lda	#$00
			sta	$fff5
			sta	$1c00
			sta	$1c01
			sta	$1c02
			sta	$1c03
			jmp	($fffc)

;*** Nach BASIC verlassen: C64.
:C64BASIC		sei				;IRQ abschalten.

			lda	$01			;Sicherstellen, das neben dem Kernal
			and	#%11000000		;auch das BASIC-ROM eingeblendet ist.
			ora	#%00110111		;Bit 6/7 für SuperCPU - nicht ändern!
			sta	$01

			ldy	#$00			;Neue Boot-Routine nach $8000
::1			lda	L8000,y			;kopieren.
			sta	$8000,y
			iny
			bne	:1

			lda	$e394 +1		;Einsprung zur Initialisierung der
			sta	$801c +1		;Vektoren ab ":$0300" aus Original-
			lda	$e394 +2		;Kernal entnehmen. Ist bei einem:
			sta	$801c +2		;Jiffy-DOS ROM = $E4B7.
							;Original  ROM = $E453.
			jmp	($fffc)			;C64-Reset auslösen.

;*** Neue Boot-Routine.
:L8000			w	$8009			;Zeiger auf RESET-Routine.
:L8002			w	$8009			;Zeiger auf RESET-Routine.
:L8004			b	$c3,$c2,$cd		;":CBM80"  Kennung "CBM80" für
:L8007			b	$38,$30			;          Neue Boot-Routine.
:L8009			sei
:L800A			ldx	#$ff			;          VIC-Register löschen.
:L800C			stx	$d016
:L800F			jsr	$fda3			;":IOINIT" CIA-Register löschen.
:L8012			jsr	$fd50			;":RAMTAS" RAM-Reset
							;          Kassettenpuffer einrichten.
							;          Bildschirm auf $0400.
:L8015			jsr	$fd15			;":RESTOR" Standard I/O-Vektoren.
:L8018			jsr	$ff5b			;":CINT"   Bildschirm-Editor-Reset.
:L801B			cli				;          IRQ freigeben.
:L801C			jsr	$e453			;":INIVEC" Vektoren ab $0300 setzen.
							;          Bei Jiffy-DOS zusätzlich
							;          F-Tasten und JD-Befehle
							;          wieder aktivieren.
:L801F			jsr	$e3bf			;":INITMP" Reset RAM-Hilfsspeicher.
:L8022			jsr	$e422			;":MSGNEW" Einschaltmeldung/NEW.
:L8025			ldx	#$fb			;          Stapelzeiger löschen.
:L8027			txs
:L8028			stx	$8005			;          CBM80-Kennung löschen.
:L802B			jmp	$e386			;          BASIC-Warmstart/READY.

;*** Menü-Variablen.
:TxtFilesOnDsk		b $00
:DrvSlctMode		b $00

:FindFileDriveTab	s $04
:DiskNameVec		w DrACurDkNm
			w DrBCurDkNm
			w DrCCurDkNm
			w DrDCurDkNm

:ClassGeoWrite		b "geoWrite    ",NULL
:ClassWriteImage	b "Write Image V",NULL
:ClassAutoExec		b "ass.SysFile V",NULL

:StdFileName		b "Objektcode",NULL
:Buf_FileName		s 17
:GW_FileName		s 17
:GW_SearchDrive		b $00

:DrvADskNam		s 17
:DrvBDskNam		s 17
:DrvCDskNam		s 17
:DrvDDskNam		s 17

:ScreenText1		b " bis ",NULL
:ScreenText2		b "von",NULL
:ScreenText3		b " >> Überlauf!",NULL
:ScreenText4		b "(Kein Programm!)",NULL
:ScreenText5		b " / ",NULL
:ScreenText6		b "          ",NULL

:NoTextFile		b "Kein Quelltext!",NULL
:MoreTextFiles		b PLAINTEXT,BOLDON,">> Weiter",PLAINTEXT,NULL
:Go1stTextFile		b PLAINTEXT,BOLDON,"<< Anfang",PLAINTEXT,NULL

:Buffer1		s $03

:DezimalData		b $00,$ca,$9a,$3b
			b $00,$e1,$f5,$05
			b $80,$96,$98,$00
			b $40,$42,$0f,$00
			b $a0,$86,$01,$00
			b $10,$27,$00,$00
			b $e8,$03,$00,$00
			b $64,$00,$00,$00
			b $0a,$00,$00,$00
			b $01,$00,$00,$00

:ComCountTxt1		b "0000000000",NULL

;*** Daten für Hauptmenü.
:DM_MainMenu		b $00
			b $0e
			w $0000
			w $00aa

			b $04 ! HORIZONTAL ! UN_CONSTRAINED

			w MT01a
			b SUB_MENU
			w DM_geos

			w MT01b
			b SUB_MENU
			w DM_Texte

			w MT01c
			b SUB_MENU
			w DM_Parameter

			w MT01d
			b SUB_MENU
			w DM_Verlassen

:MT01a			b "geos",NULL
:MT01b			b "Texte",NULL
:MT01c			b "Parameter",NULL
:MT01d			b "Verlassen",NULL
:MT01e			b "Info",NULL

;*** Daten für Menü "GEOS".
:DM_geos		b $0e
			b $0e +9*14 +1
			w $0000
			w $0055

			b $09 ! VERTICAL ! UN_CONSTRAINED

			w MT02a
			b MENU_ACTION
			w InfoBox

			w MT02b
			b MENU_ACTION
			w Switch40_80

			w MT02c
			b MENU_ACTION
			w LoadDA_File

			w MT02d
			b MENU_ACTION
			w LoadDA_File

			w MT02e
			b MENU_ACTION
			w LoadDA_File

			w MT02f
			b MENU_ACTION
			w LoadDA_File

			w MT02g
			b MENU_ACTION
			w LoadDA_File

			w MT02h
			b MENU_ACTION
			w LoadDA_File

			w MT02i
			b MENU_ACTION
			w LoadDA_File

			w MT02j
			b MENU_ACTION
			w LoadDA_File

:MT02a			b PLAINTEXT,"Info MegaAss",NULL
:MT02b			b PLAINTEXT,"Switch 40/80",PLAINTEXT,NULL
:MT02c			s 17
:MT02d			s 17
:MT02e			s 17
:MT02f			s 17
:MT02g			s 17
:MT02h			s 17
:MT02i			s 17
:MT02j			s 17

;*** Daten für Menü "Texte".
:DM_Texte		b $0e
			b $1d
			w $001c
			w $0071

			b $01 ! VERTICAL ! UN_CONSTRAINED

			w MT03a
			b MENU_ACTION
			w SlctTextFile

			w MT03b
			b MENU_ACTION
			w SlctTextFile

			w MT03c
			b MENU_ACTION
			w SlctTextFile

			w MT03d
			b MENU_ACTION
			w SlctTextFile

			w MT03e
			b MENU_ACTION
			w SlctTextFile

			w MT03f
			b MENU_ACTION
			w SlctTextFile

			w MT03g
			b MENU_ACTION
			w SlctTextFile

			w MT03h
			b MENU_ACTION
			w SlctTextFile

			w MT03i
			b MENU_ACTION
			w SlctTextFile

			w MT03j
			b MENU_ACTION
			w SlctTextFile

			w MT03k
			b MENU_ACTION
			w SlctTextFile

			w MT03l
			b MENU_ACTION
			w SlctTextFile

			w MT03m
			b MENU_ACTION
			w SlctTextFile

:MT03a			s 17
:MT03b			s 17
:MT03c			s 17
:MT03d			s 17
:MT03e			s 17
:MT03f			s 17
:MT03g			s 17
:MT03h			s 17
:MT03i			s 17
:MT03j			s 17
:MT03k			s 17
:MT03l			s 17
:MT03m			s 17

;*** Daten für "Parameter"-Menü.
:DM_Parameter		b $0e
			b $0e +11*14 +1
			w $003b
			w $00ba

			b 11 ! VERTICAL ! UN_CONSTRAINED

			w MT04a
			b DYN_SUB_MENU
			w SlctSourceDrv

			w MT04b
			b MENU_ACTION
			w ChangeSrcDisk

			w MT04c
			b DYN_SUB_MENU
			w SlctTargetDrv

			w MT04r
			b MENU_ACTION
			w ChangeTgtDisk

			w MT04d
			b DYN_SUB_MENU
			w SlctErrFileDrv

			w MT04e
			b DYN_SUB_MENU
			w SlctSymbTabDrv

			w MT04f
			b MENU_ACTION
			w DefAutoMode

			w MT04g
			b DYN_SUB_MENU
			w SlctAutoTxtDrv

			w MT04s
			b MENU_ACTION
			w ChangeAutoDisk

			w MT04p
			b SUB_MENU
			w DM_Options

			w MT04m
			b MENU_ACTION
			w SaveParameter

:MT04a			b PLAINTEXT,"Laufwerk A: Quelltexte",NULL
:MT04b			b PLAINTEXT,"Quelldiskette wechseln",PLAINTEXT,NULL
:MT04c			b           "Laufwerk A: Programmcode",NULL
:MT04r			b PLAINTEXT,"Zieldiskette wechseln",PLAINTEXT,NULL
:MT04d			b           "Laufwerk A: Fehlerliste",NULL
:MT04e			b           "Laufwerk A: Symboltabellen",NULL
:MT04f			b           "  AutoAssembler aktiv",NULL
:MT04g			b           "Laufwerk A: AutoAssembler",NULL
:MT04s			b PLAINTEXT,"Systemdiskette wechseln",PLAINTEXT,NULL
:MT04p			b           ">> Optionen", NULL
:MT04m			b           "Parameter speichern",NULL

;*** Daten für "Optionen"-Menü.
:DM_Options		b $0e +5*14 +7
			b $0e +5*14 +7 +5*14 +1
			w $003b
			w $00da

			b 5 ! VERTICAL ! UN_CONSTRAINED

			w MT04h
			b MENU_ACTION
			w DefSymbTab

			w MT04i
			b MENU_ACTION
			w DefExtSymbTab

			w MT04l
			b MENU_ACTION
			w OverWriteMode

			w MT04n
			b MENU_ACTION
			w POpcodeTestMode

			w MT04o
			b MENU_ACTION
			w MouseCancelMode

:MT04h			b           "  Symboltabelle",NULL
:MT04i			b           "  Ext. Symboltabelle",NULL
:MT04l			b           "  Sicherheitsabfrage",NULL
:MT04n			b           "  Pseudo-Opcodes testen",NULL
:MT04o			b	   "  Abbruch deaktivieren",NULL

;*** Daten für "Laufwerk"-Menü.
:DM_SlctDrive		b $15
			b $4e
			w $003b
			w $00ba

			b $04 ! VERTICAL ! UN_CONSTRAINED

			w DriveTextA
			b MENU_ACTION
			w DefDriveA

			w DriveTextB
			b MENU_ACTION
			w DefDriveB

			w DriveTextC
			b MENU_ACTION
			w DefDriveC

			w DriveTextD
			b MENU_ACTION
			w DefDriveD

:DriveTextA		b PLAINTEXT,"Laufwerk A:",NULL
:DriveTextB		b PLAINTEXT,"Laufwerk B:",NULL
:DriveTextC		b PLAINTEXT,"Laufwerk C:",NULL
:DriveTextD		b PLAINTEXT,"Laufwerk D:",NULL

:DrvMenuYPos		b $15,$31,$3f,$4d,$69

;*** Daten für "Verlassen"-Menü.
:DM_Verlassen		b $0e
			b $0e +7*14 +1
			w $006d
			w $00e0

			b $07 ! VERTICAL ! UN_CONSTRAINED

			w MT06a
			b MENU_ACTION
			w StartVLink

			w MT06b
			b SUB_MENU
			w DM_GeoWrite

			w MT06c
			b MENU_ACTION
			w StartProgramm

			w MT06d
			b MENU_ACTION
			w ExitDT

			w MT06e
			b MENU_ACTION
			w ExitBASIC

			w MT06f
			b MENU_ACTION
			w ReBootMegaAss

			w MT06g
			b MENU_ACTION
			w DlgOpcodes

:MT06a			b BOLDON,">> ",PLAINTEXT,"MegaLinker",NULL
:MT06b			b BOLDON,">> ",PLAINTEXT,"GeoWrite aufrufen",NULL
:MT06c			b BOLDON,">> ",PLAINTEXT
:MT06c1			b "(Kein Programm!)",NULL
:MT06d			b BOLDON,">> ",PLAINTEXT,"DeskTop",NULL
:MT06e			b BOLDON,">> ",PLAINTEXT,"BASIC aufrufen",NULL
:MT06f			b BOLDON,">> ",PLAINTEXT,"Neustart",NULL
:MT06g			b BOLDON,"MegaAss-OpCodes",NULL

:DM_GeoWrite		b $20
			b $67
			w $00c1
			w $0137

			b $05 ! VERTICAL ! UN_CONSTRAINED

			w MT07a
			b MENU_ACTION
			w OpenSrcCode

			w MT07b
			b MENU_ACTION
			w OpenErrFile

			w MT07c
			b MENU_ACTION
			w OpenSymFile

			w MT07d
			b MENU_ACTION
			w OpenExtFile

			w MT07e
			b MENU_ACTION
			w OpenGeoWrite

:MT07a			b BOLDON,">> ",PLAINTEXT,"Quelltext öffnen",NULL
:MT07b			b BOLDON,">> ",PLAINTEXT,"Fehlerliste",NULL
:MT07c			b BOLDON,">> ",PLAINTEXT,"Symboltabelle",NULL
:MT07d			b BOLDON,">> ",PLAINTEXT,"Ext. Symboltabelle",NULL
:MT07e			b BOLDON,">> ",PLAINTEXT,"Ohne Text starten",NULL

;*** Dialogbox: Partition wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Infobox MegaAssembler.
:DlgInfoBox		t "src.MegaAss.info"

;*** Verfügbare OpCodes anzeigen.
:DlgOpcodesInfo		b %00000000
			b $00,$c7
:DlgOpInf_a		w $0000,$013f
			b DBTXTSTR    ,$00,$0a
			w :1
			b DBSYSOPV
			b NULL

::1			b PLAINTEXT,BOLDON
			b GOTOX,$08,$00
			b "***** MegaAssembler - OpCodes *****   (* = NEU)",CR
			b BOLDON
			b GOTOX,$18,$00,"a,c,n"
			b GOTOX,$48,$00,"'NAME'"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Autor/Klasse/Name festlegen."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"f"
			b GOTOX,$48,$00,"TYPE"
			b GOTOX,$98,$00,PLAINTEXT
			b               "GEOS-Dateityp festlegen."
			b CR

			b BOLDON
			b GOTOX,$08,$00,"*"
			b GOTOX,$18,$00,"h"
			b GOTOX,$48,$00,"'TEXT'"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Text für Infoblock festlegen."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"i"
			b GOTOX,$48,$00,"ICON"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Infoblock-Icon für Objektdatei."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"o,p,q"
			b GOTOX,$48,$00,"$XXXX"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Lade-/Start-/Endadr. festlegen."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"z"
			b GOTOX,$48,$00,"$XX"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Bildschirm-Modus festlegen."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"b"
			b GOTOX,$48,$00,"$XX,'TEXT'"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Byte-Tabelle einbinden."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"s"
			b GOTOX,$48,$00,"$XX"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Anzahl $00-Bytes einbinden."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"w"
			b GOTOX,$48,$00,"$XXXX"
			b GOTOX,$98,$00,PLAINTEXT
			b               "WORD-Tabelle einbinden."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"j"
			b GOTOX,$48,$00,"ICON"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Infoblock-Icon einbinden."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"d"
			b GOTOX,$48,$00,"'NAME'"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Seq. Datei einbinden."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"t"
			b GOTOX,$48,$00,"'NAME'"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Textdatei einbinden."
			b CR

			b BOLDON
			b GOTOX,$18,$00,"v,u"
			b GOTOX,$48,$00,"NR,'NAME'"
			b GOTOX,$98,$00,PLAINTEXT
			b               "VLIR-Datensatz/Foto einbinden."
			b CR

			b BOLDON
			b GOTOX,$08,$00,"*"
			b GOTOX,$18,$00,"e,g"
			b GOTOX,$48,$00,"$XXXX"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Adr. auf Überschreitung testen und"
			b CR
			b GOTOX,$98,$00,"bei `e` mit $00-Bytes auffüllen."
			b CR

			b BOLDON
			b GOTOX,$08,$00,"*"
			b GOTOX,$18,$00,"r"
			b GOTOX,$48,$00,"$XXXX"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Max. Programm-Endadresse festlegen."
			b CR

			b BOLDON
			b GOTOX,$08,$00,"*"
			b GOTOX,$18,$00,"k,l"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Datum (kurz/lang) einbinden."
			b CR

			b BOLDON
			b GOTOX,$08,$00,"*"
			b GOTOX,$18,$00,"x,y"
			b GOTOX,$98,$00,PLAINTEXT
			b               "Zeit (kurz/lang) einbinden."
			b NULL

;*** Dummy-Menütabelle.
:SysIconMenu		b $02
			w $0000
			b $00

			w icon_01
:SysIconMenu_a		b $26,$31,$01,$08
			w ClearCounter

			w icon_01
:SysIconMenu_b		b $26,$3b,$01,$08
			w ClearTimeFlag

:icon_01
<MISSING_IMAGE_DATA>

;*** 40-Zeichen-Daten.
:Word40_Data		w DM_MainMenu+4 ,$009d
			w DM_geos+4 ,$0060
			w DM_Texte+2 ,$001c
			w DM_Texte+4 ,$007c
			w DM_Parameter+2 ,$003b
			w DM_Parameter+4 ,$00c3
			w DM_Options+2 ,$0080
			w DM_Options+4 ,$00f7
			w DM_SlctDrive+2 ,$0090
			w DM_SlctDrive+4 ,$00cf
			w DM_Verlassen+2 ,$006d
			w DM_Verlassen+4 ,$00f3
			w DM_GeoWrite+2 ,$00b0
			w DM_GeoWrite+4 ,$0127
			w DlgOpInf_a+2,$013f
			w K201	+0 ,$00c3
			w K201	+2 ,$013b
			w K202	+0 ,$00c1
			w K202	+2 ,$013d
			w K203	+0 ,$00c0
			w K203	+2 ,$013e
			w K204	+0 ,$00c4
			w K204	+2 ,$013a
			w K205	+0 ,$00c2
			w K205	+2 ,$013c
			w K206	+0 ,$00c1
			w K206	+2 ,$013d
			w K207	+0 ,$00c8
			w K207	+2 ,$0136
			w K208	 ,$00cc
			w K209	+2 ,$013f
			w K210	+2 ,$013f
			w K211	 ,$0010
			w K301	 ,$0010
			w K302	 ,$0010
			w K303	 ,$0010
			w K304	 ,$0020
			w K305	 ,$0020
			w K306	 ,$0010
			w K401	 ,$0010
			w K402	 ,$0010
			w K403	 ,$0010
			w K501	 ,$0010
			w K502	 ,$0010
			w K503	 ,$0010
			w K504	 ,$0010
			w K505	 ,$0010
			w K505a	 ,$0010
			w K506	 ,$0010
			w K507	 ,$0010
			w K508	 ,$00a0
			w K509	 ,$00a0
			w K601 +2,$013f
			w K602 +2,$013f
			w $0000

:Byte40_Data		w SetInfoXPos+1
			b $9c
			w SetInfoXPos+5
			b $00
			w SysIconMenu_a
			b $02
			w SysIconMenu_a+2
			b $01
			w SysIconMenu_b
			b $02
			w SysIconMenu_b+2
			b $01
			w $0000

;*** 80-Zeichen-Daten.
:Word80_Data		w DM_MainMenu+4 ,$00d4
			w DM_geos+4 ,$0090
			w DM_Texte+2 ,$0024
			w DM_Texte+4 ,$00b4
			w DM_Parameter+2 ,$004f
			w DM_Parameter+4 ,$011f
			w DM_Options+2 ,$00b0
			w DM_Options+4 ,$015f
			w DM_SlctDrive+2 ,$00b0
			w DM_SlctDrive+4 ,$010f
			w DM_Verlassen+2 ,$0094
			w DM_Verlassen+4 ,$0154
			w DM_GeoWrite+2 ,$0100
			w DM_GeoWrite+4 ,$01b7
			w DlgOpInf_a+2,$027f
			w K201	+0 ,$80c3
			w K201	+2 ,$813b
			w K202	+0 ,$80c1
			w K202	+2 ,$813d
			w K203	+0 ,$80c0
			w K203	+2 ,$813e
			w K204	+0 ,$80c4
			w K204	+2 ,$813a
			w K205	+0 ,$80c2
			w K205	+2 ,$813c
			w K206	+0 ,$80c1
			w K206	+2 ,$813d
			w K207	+0 ,$80c8
			w K207	+2 ,$8136
			w K208	 ,$80cc
			w K209	+2 ,$027f
			w K210	+2 ,$027f
			w K211	 ,$0020
			w K301	+0 ,$0020
			w K302	+0 ,$0020
			w K303	+0 ,$0020
			w K304	 ,$0040
			w K305	 ,$0040
			w K306	+0 ,$0020
			w K401	+0 ,$0020
			w K402	+0 ,$0020
			w K403	+0 ,$0020
			w K501	+0 ,$0020
			w K502	+0 ,$0020
			w K503	+0 ,$0020
			w K504	+0 ,$0020
			w K505	+0 ,$0020
			w K505a	+0 ,$0020
			w K506	+0 ,$0020
			w K507	+0 ,$0020
			w K508	+0 ,$0140
			w K509	+0 ,$0140
			w K601 +2,$027f
			w K602 +2,$027f
			w $0000

:Bye80_Data		w SetInfoXPos+1
			b $38
			w SetInfoXPos+5
			b $01
			w SysIconMenu_a
			b $04
			w SysIconMenu_a+2
			b $81
			w SysIconMenu_b
			b $04
			w SysIconMenu_b+2
			b $81
			w $0000
