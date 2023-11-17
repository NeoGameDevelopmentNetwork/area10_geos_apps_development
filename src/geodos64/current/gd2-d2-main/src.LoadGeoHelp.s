; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
			t "GD_Mac"
			t "-GD_Sprache"

:OS_VARS		= $8000
:EndMemory		= $6000
:LoadAdress		= $0c00
:SetNewMode		= $c2dd
:graphMode		= $003f

endif

			n "LoadGeoHelp"
			a "M. Kanet"
			c "LoadGeoHelp V1.0"
			f DESK_ACC
			i
<MISSING_IMAGE_DATA>
			z $00
			o $0400
			p MainInit
			r $0bff

			h "*"
			h "*    = SwapDatei auf Diskette"
			h "01-xx= RAM-Bank verwenden"

;*** Standard-Dateinamen.
:FileClassLGH		b "LoadGeoHelp ",NULL		;LoadGeoHelp
:FileClass40		b "GeoHelpView ",NULL		;40-Zeichen.
:FileClass80		b "GeoHelp128  ",NULL		;80-Zeichen.

:FileName_LGH		s 17

:BackToRoutine		w $0000
:ScreenMode		b $00
:graphModeBuf		b $00

;*** Daten für den zu sichernden Speicherbereich.
:ramCopyData		w Memory
			w $0000
			w (EndMemory - Memory)
:ramBank		b $00

;*** SwapFile speichern.
:MainInit		jsr	i_MoveData		;Speicher für Dialogboxen
			w	dlgBoxRamBuf		;zwischenspeichern.
			w	b_dlgBoxBuf
			w	417

			ldx	#$00
			bit	c128Flag
			bpl	:100
			lda	graphMode
			sta	graphModeBuf
			bpl	:100
			dex
::100			stx	ScreenMode

			ldx	ramExpSize		;Speichererweiterung vorhanden ?
			beq	:101			;Nein, Speicher auf Disk auslagern.

			lda	#<FileClassLGH		;"LoadGeoHelp" auf Diskette suchen.
			ldx	#>FileClassLGH
			ldy	#DESK_ACC
			jsr	FindFile_LGH
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Speicher auf Disk auslagern.

			jsr	GetFileData		;Verzeichniseintrag einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Speicher auf Disk auslagern.

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Speicher auf Disk auslagern.

			jsr	GetDezZahl		;2stellige Dezimalzahl einlesen.
			bcc	:102			;Zahl gefunden -> weiter...
::101			jmp	DoSwapHelp		;Speicher auf Disk auslagern.

::102			cmp	ramExpSize		;Gewählte RAM-Bank verfügbar ?
			bcs	:101			;Nein, Speicher auf Disk auslagern.

			sta	ramBank			;Speicher in RAM-Bank sichern.

;*** Speicher in REU übertragen.
:DoRamHelp		jsr	SetRAMdata		;Register definieren.
			jsr	StashRAM		;Speicher in REU übertragen.

			jsr	GetStdHelp		;Hilfe aufrufen.

			jsr	SetRAMdata		;Register definieren.
			jsr	FetchRAM		;Speicher aus REU auslesen.

:ExitRout		jsr	i_MoveData		;Speicher für Dialogboxen wieder
			w	b_dlgBoxBuf		;herstellen.
			w	dlgBoxRamBuf
			w	417

			LoadW	appMain,RstrAppl
			rts

;*** Register für RAM-Austausch definieren.
:SetRAMdata		ldx	#$06
::101			lda	ramCopyData,x
			sta	r0L,x
			dex
			bpl	:101
			rts

;*** Speicher auf Disk auslagern.
:DoSwapHelp		jsr	:102			;SWAP-Datei auf Diskette löschen.

			LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile		;Speicher auf Disk auslagern.
			txa				;Diskettenfehler ?
			beq	:100			;Ja, Abbruch.

			LoadW	r0,SysErrBox		;Fehlermeldung, SwapDatei kann nicht
			jsr	DoDlgBox		;gespeichert werden.
			jmp	:101

::100			jsr	GetStdHelp		;Hilfe aufrufen.

			LoadW	r6,HdrFileName
			jsr	FindFile
			txa
			bne	:101

			jsr	InitGetFile

			lda	dirEntryBuf+1
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r2,($7fff-Memory)
			LoadW	r7,Memory
			jsr	ReadFile		;GeoHelpView in Speicher laden.

::101			jsr	:102			;SWAP-Datei auf Diskette löschen.
			jmp	ExitRout

;*** SWAP-Datei auf Diskette löschen.
::102			LoadW	r0,HdrFileName
			jsr	DeleteFile
			txa
			beq	:102
			rts

;*** Hilfedatei suchen, Seite #1 laden.
:GetStdHelp		bit	ScreenMode
			bpl	:100
			lda	#<FileClass80
			ldx	#>FileClass80
			ldy	#APPLICATION
			jsr	FindFile_LGH		;GeoHelpView 80Z. suchen.
			txa				;Diskettenfehler ?
			beq	:100a			;Nein, weiter.

			lda	graphMode
			and	#%10000000
			eor	#%10000000
			sta	graphMode
			sta	ScreenMode
			jsr	SetNewMode

::100			lda	#<FileClass40
			ldx	#>FileClass40
			ldy	#APPLICATION
			jsr	FindFile_LGH		;GeoHelpView 40Z. suchen.
			txa				;Diskettenfehler ?
			beq	:100a			;Ja, Abbruch.

			bit	c128Flag		;64 / C128 ?
			bpl	:102			;C64, Ende...
			lda	graphModeBuf
			sta	graphMode
			jsr	SetNewMode
			jmp	:102

::100a			jsr	GetFileData		;Verzeichniseintrag einlesen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			PopW	BackToRoutine		;Rücksprungadresse sichern.

			jsr	i_MoveData		;Bildschirmbereich retten.
			w	SCREEN_BASE		;Nicht alle Anwendungen initialisieren
			w	b_SCREEN_BASE		;nach dem beenden des DA's wieder den
			w	2*40*8			;kompletten Bildschirm.

			jsr	InitGetFile		;":dlgBoxRamBuf"-Speicher löschen.

			lda	dirEntryBuf+1
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r2,($7fff-LoadAdress)
			LoadW	r7,LoadAdress
			jsr	ReadFile		;GeoHelpView in Speicher laden.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	LoadAdress +3		;Hilfesystem aufrufen.

::101			jsr	i_MoveData		;Bildschirm wieder herstellen.
			w	b_SCREEN_BASE
			w	SCREEN_BASE
			w	2*40*8

			PushW	BackToRoutine		;Rücksprngadresse zurückschreiben.

::102			rts

;*** Dateityp suchen.
:FindFile_LGH		sta	r10L			;Zeiger auf Klasse.
			stx	r10H
			sty	r7L			;Zeiger auf Dateityp.
			LoadB	r7H,$01			;Anzahl Dateien.
			LoadW	r6,FileName_LGH		;Speicher für Dateiname.
			jsr	FindFTypes		;Dateitypen suchen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.
			lda	r7H			;Datei gefunden ?
			beq	:101			;Ja, weiter...
			ldx	#$05			;Fehler: "File not found!".
::101			rts

;*** Verzeichniseintrag einlesen.
:GetFileData		LoadW	r6,FileName_LGH
			jmp	FindFile

;*** ASCII-Zahl (Zwei Zeichen) nach DEZIMAL.
;RAM-Bank aus Infoblock einlesen.
:GetDezZahl		ldy	#$a0
			jsr	:110
			bcs	:103
			tax

			iny
			jsr	:110
			bcs	:103

			cpx	#$00
			beq	:102
::101			add	10
			dex
			bne	:101
::102			clc
::103			rts

::110			lda	fileHeader,y
			sub	$30
			cmp	#10
			rts

;*** "dlgBoxRamBuf"-Speicher löschen.
;    Notwendig da sonst GetFile ab & zu
;    Probleme bereitet!
:InitGetFile		jsr	i_FillRam
			w	417
			w	dlgBoxRamBuf
			b	$00

			lda	#$00
			tax
::101			sta	r0L,x
			inx
			cpx	#(r15H-r0L) +1
			bcc	:101
			rts

if Sprache = Deutsch
;*** Dialogbox für Hilfedatei-Fehler.
:SysErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Kann SwapDatei nicht",NULL
::102			b "auf Diskette speichern!",NULL
endif

if Sprache = Englisch
;*** Dialogbox für Hilfedatei-Fehler.
:SysErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

::101			b PLAINTEXT,BOLDON
			b "SwapFile can not be",NULL
::102			b "saved to disk!",NULL
endif

;*** Infoblock für SWAP-Datei.
:HdrB000		w HdrFileName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b DATA
			b SEQUENTIAL
			w Memory
			w EndMemory
			w Memory
			b "GD_SwapFile V"		;Klasse.
			b "1.0"				;Version.
			s $04				;Reserviert.
			b "GeoDOS 64"			;Autor.
:HdrEnd			s (HdrB000+256)-HdrEnd

;*** Dateiname für SWAP-File.
:HdrFileName		b "GD_TEMP",NULL

;*** Speicher für dlgBoxRamBuf.
:b_dlgBoxBuf		s 417

;*** Anfang Datenspeicher.
:b_SCREEN_BASE		s 2*40*8

;*** Startadresse der zu speichernden Daten (SwapDatei).
:Memory
