; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DBOX"
endif

;*** GEOS-Header.
			n "GD.GEOHELP.DA"
			c "GD.HELPINIT V2.0"
			t "G3_Sys.Author"
			f DESK_ACC
			z $80				;nur GEOS64

			o APP_RAM
			p MainInit

			i

<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Startet das Hilfesystem als DeskAccessory"
endif
if Sprache = Englisch
			h "Start helpsystem as a desk accessory"
endif

;*** Standard-Dateinamen.
:FileClassLGH		b "GD.HELPINIT V2",NULL		;LoadGeoHelp
:FileClass		b "GD.HELP     V2",NULL		;40-Zeichen.

:FileName_LGH		s 17

:BackToRoutine		w $0000

;*** Daten für den zu sichernden Speicherbereich.
:ramCopyData		w Memory
			w $0000
			w (OS_VARS - Memory)
:ramBank		b $00

;*** SwapFile speichern.
:MainInit		jsr	i_MoveData		;Speicher für Dialogboxen
			w	dlgBoxRamBuf		;zwischenspeichern.
			w	b_dlgBoxBuf
			w	417

			lda	#$00			;SwapFile auf Diskette.
			sta	ramBank

			jsr	FindFreeBank		;Freie Speicherbank suchen.
			tya				;Speicherbank gefunden ?
			bne	:2			; => Ja, weiter...
::1			jmp	DoSwapHelp		;Speicher auf Disk auslagern.

::2			cmp	ramExpSize		;Speicherbank gültig ?
			bcs	:1			; => Nein, SwapFile auf Diskette.
			pha
			jsr	AllocateBank		;Speicherbank reservieren.
			pla
			sta	ramBank

;*** Speicher in REU übertragen.
:DoRamHelp		jsr	SetRAMdata		;Register definieren.
			jsr	StashRAM		;Speicher in REU übertragen.

			jsr	GetStdHelp		;Hilfe aufrufen.

			jsr	SetRAMdata		;Register definieren.
			jsr	FetchRAM		;Speicher aus REU auslesen.

;*** LoadGeoHelp beenden.
:ExitRout		ldy	ramBank
			beq	:1
			jsr	FreeBank

::1			jsr	i_MoveData		;Speicher für Dialogboxen wieder
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
:GetStdHelp		jsr	Get1stFile

			lda	#<FileClass
			ldx	#>FileClass
			ldy	#APPLICATION
			jsr	FindFile_LGH		;GeoHelpView suchen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			LoadW	r6,FileName_LGH
			jsr	FindFile
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
			LoadW	r2,(OS_VARS-BASE_HELPSYS)
			LoadW	r7,BASE_HELPSYS
			jsr	ReadFile		;GeoHelpView in Speicher laden.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	BASE_HELPSYS+3		;Hilfesystem aufrufen.

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

;*** Freie 64K-Speicherbank suchen.
:FindFreeBank		ldy	#$00
::51			jsr	GetBankByte
			beq	:52
			iny
			cpy	ramExpSize
			bne	:51
			ldy	#$00
::52			rts

;*** Tabellenwert für Speicherbank finden.
:GetBankByte		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
::51			cpx	#$00
			beq	:52
			asl
			asl
			dex
			bne	:51
::52			and	#%11000000
			rts

;*** Speicherbank reservieren.
:AllocateBank		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
			ora	:DOUBLE_BIT,x
			pha
			tya
			lsr
			lsr
			tax
			pla
			sta	RamBankInUse,x
			rts

::DOUBLE_BIT		b %11000000
			b %00110000
			b %00001100
			b %00000011

;*** Speicherbank freigeben.
:FreeBank		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
			and	:DOUBLE_BIT,x
			pha
			tya
			lsr
			lsr
			tax
			pla
			sta	RamBankInUse,x
			rts

::DOUBLE_BIT		b %00111111
			b %11001111
			b %11110011
			b %11111100

;*** Nach erster Anzeigeseite suchen.
;    Infoblock einlesen. Kennung "=>" vorhanden, Hilfedatei laden.
;    Sonst "GeoHelpView.001" laden.
:Get1stFile		lda	curDrive
			sta	HelpSystemDrive

			lda	#$00
			sta	HelpSystemPart
			sta	HelpSystemFile
			sta	HelpSystemPage

			lda	#<FileClassLGH
			ldx	#>FileClassLGH
			ldy	#DESK_ACC
			jsr	FindFile_LGH		;GeoHelpView suchen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch.

			LoadW	r6,FileName_LGH
			jsr	FindFile		;Verzeichnis-Eintrag suchen.
			txa				;Datei Gefunden ?
			bne	:1			; => Nein, weiter...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Systemfehler.

			ldx	#"="			;Erstes Zeichen für Datei-Kennung.
			cpx	fileHeader+$a0		;Zeichen vorhanden ?
			bne	:1			; => Nein, Standardhilfe anzeigen.
			ldx	#">"			;Zweites Zeichen für Datei-Kennung.
			cpx	fileHeader+$a1		;Zeichen vorhanden ?
			bne	:1			; => Nein, Standardhilfe anzeigen.
			jmp	CheckSettings		;Laufwerkskonfiguration testen.
::1			rts

;******************************************************************************
;*** Hilfe-Laufwerk festlegen.
;******************************************************************************
;*** Auf Laufwerk/Partition testen.
;    (w:xyz)=(Laufwerk:Partition)
;    A,B,C,D Laufwerk A:,B:,C:,D:
;    R       RAMLink
;    H       CMD HD
;    F       CMD RL
:CheckSettings		lda	fileHeader +$a2
			cmp	#"("			;Folgt Laufwerksangabe ?
			beq	:1			; => Ja, weiter...

;--- Hilfe von aktuellem Laufwerk öffnen.
			ldy	#$a2
			jmp	CheckSlctPage

;--- Hilfe von fremden Laufwerk öffnen.
::1			jsr	CheckHPartData		;Partitionsangabe suchen.
			jsr	CheckDrvAdr		;Laufwerksangabe suchen.
			txa				;Laufwerk gefunden ?
			beq	:3			; => Ja, weiter...

			jsr	CheckDrvType		;Laufwerkstyp suchen.
			txa				;Typ gefunden ?
			beq	:3			; => Ja, weiter...

::2			ldy	curDrive
::3			sty	HelpSystemDrive		;Laufwerk speichern.

			lda	HelpSystemPart		;Partition wechseln ?
			bne	:4			; => Ja, weiter...

			ldy	#$a5
			b $2c
::4			ldy	#$a9
			jmp	CheckSlctPage		;Dokument öffnen.

;*** Partition für Hilfetexte festlegen.
:CheckHPartData		lda	#$00
			ldx	fileHeader +$a4
			cpx	#":"			;Folgt Partitionsangabe ?
			bne	:1			; => Nein, weiter...

			ldy	#$a5
			LoadW	r0,fileHeader		;Partitions-Nr. einlesen.
			jsr	Get100DezCode
::1			sta	HelpSystemPart
			rts

;******************************************************************************
;*** Hilfe-Laufwerk festlegen.
;******************************************************************************
;*** Auf Laufwerk A: bis D: testen.
:CheckDrvAdr		ldx	#NO_ERROR
			lda	fileHeader +$a3		;Laufwerkstyp einlesen.

			ldy	#$08			;Zeiger auf Laufwerk #8.
			cmp	#"A"			;Hilfe von Laufwerk A: starten ?
			beq	:1			; => Ja, weiter...
			iny				;Zeiger auf Laufwerk #9.
			cmp	#"B"			;Hilfe von Laufwerk B: starten ?
			beq	:1			; => Ja, weiter...
			iny				;Zeiger auf Laufwerk #10.
			cmp	#"C"			;Hilfe von Laufwerk C: starten ?
			beq	:1			; => Ja, weiter...
			iny				;Zeiger auf Laufwerk #11.
			cmp	#"D"			;Hilfe von Laufwerk D: starten ?
			beq	:1			; => Ja, weiter...
			ldx	#DEV_NOT_FOUND
::1			rts

;*** Laufwerkstyp (FD,HD,RL) suchen.
:CheckDrvType		ldx	#NO_ERROR
			lda	fileHeader +$a3		;Laufwerkstyp einlesen.

			ldy	#DrvFD			;Zeiger auf CMD-FD.
			cmp	#"F"			;Hilfetext auf CMD-FD ?
			beq	:1			; => Ja, weiter...
			ldy	#DrvHD			;Zeiger auf CMD-HD.
			cmp	#"H"			;Hilfetext auf CMD-HD ?
			beq	:1			; => Ja, weiter...
			ldy	#DrvRAMLink		;Zeiger auf CMD-RL.
			cmp	#"R"			;Hilfetext auf CMD-RL ?
			beq	:1			; => Ja, weiter...
			ldx	#DEV_NOT_FOUND
::1			rts

;******************************************************************************
;*** Hilfe-Dokument festlegen.
;******************************************************************************
;*** Dateiname aus Infoblock in Zwischenspeicher kopieren.
:CheckSlctPage		tya
			clc
			adc	#$03
			sta	:CheckSlctFile +1

			LoadW	r0,fileHeader		;Seiten-Nr. einlesen.
			jsr	GetDezCode
			sec
			sbc	#$01
			bcc	:1
			cmp	#61
			bcc	:2
::1			lda	#$01
::2			sta	HelpSystemPage		;Seite merken.

;--- Dateiname prüfen.
::CheckSlctFile		ldy	#$ff			;Dateiname einlesen.
			ldx	#$00
::11			lda	fileHeader ,y
			beq	:12
			cmp	#CR
			beq	:12
			sta	HelpSystemFile,x
			iny
			inx
			cpx	#16
			bcc	:11

::12			lda	#$00			;Dateiname mit $00-Bytes
			sta	HelpSystemFile,x	;auffüllen.
			inx
			cpx	#17
			bcc	:12
			rts

;*** ASCII-Zahl (Drei Zeichen) nach DEZIMAL.
:Get100DezCode		lda	(r0L),y			;100er-Wert einlesen.
			sec
			sbc	#$30			;Zahlenwert ermitteln.
			tax				;100er-Wert = $00 ?
			beq	:2			; => Ja, weiter...

			lda	#$00			;100er-Wert berechnen.
::1			clc
			adc	#$64
			dex
			bne	:1
::2			iny				;Zeiger auf 10er-Wert setzen.

			b $2c				;2Byte-Befehl übergehen.

;*** ASCII-Zahl (Zwei Zeichen) nach DEZIMAL.
:GetDezCode		lda	#$00			;Startwert für Umwandlung.
			sta	:1 +1			;Wert zwischenspeichern.

			lda	(r0L),y			;10er-Wert einlesen.
			sec
			sbc	#$30			;Zahlenwert ermitteln und
			tax				;zwischenspeichern.
			iny				;Zeiger auf 1er-Wert setzen.
			lda	(r0L),y			;1er-Wert einlesen.
			sec
			sbc	#$30			;Zahlenwert ermitteln

			clc
::1			adc	#$ff			;Startwert addieren (0,100,200)
			cpx	#$00			;10er-Wert = $00 ?
			beq	:3			; => Ja, weiter...

::2			clc
			adc	#$0a			;10er-Wert berechnen.
			dex
			bne	:2
::3			rts				;Ende.

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
			w OS_VARS
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

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_HELPSYS -1
;******************************************************************************

;*** Startadresse der zu speichernden Daten (SwapDatei).
:Memory
