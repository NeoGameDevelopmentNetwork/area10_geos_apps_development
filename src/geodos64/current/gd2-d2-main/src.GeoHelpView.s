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

:FONT_TYPE		= SET_PLAINTEXT			;Text-Darstellung "PLAINTEXT".
:OS_VARS		= $8000
:EndMemory		= $6000				;Ende des Textspeichers.
:LoadAdress		= $4000				;Ladeadresse für GeoWrite-Seite.
							;Größe also von $4000 - $5FFF. GeoWrite
							;verwaltet Seiten mit 4100 Zeichen = $1060.
							;Sollte der Speicher nicht ausreichen, kann
							;er auch auf $3000 heruntergesetzt werden,
							;es kann dann aber passieren das beim kon-
							;vertieren der Textseite es zu Speicher-
							;überschneidungen kommt.

;*** C64-Kernal Einsprünge.
:SECOND			= $ff93				;Sekundär-Adresse nach LISTEN senden.
:TKSA			= $ff96				;Sekundär-Adresse nach TALK senden.
:ACPTR			= $ffa5				;Byte-Eingabe vom IEC-Bus.
:CIOUT			= $ffa8				;Byte-Ausgabe auf IEC-Bus.
:UNTALK			= $ffab				;UNTALK-Signal auf IEC-Bus senden.
:UNLSN			= $ffae				;UNLISTEN-Signal auf IEC-Bus senden.
:LISTEN			= $ffb1				;LISTEN-Signal auf IEC-Bus senden.
:TALK			= $ffb4				;TALK-Signal auf IEC-Bus senden.
:SETLFS			= $ffba				;Dateiparameter setzen.
:SETNAM			= $ffbd				;Dateiname setzen.
:OPENCHN		= $ffc0				;Datei öffnen.
:CLOSE			= $ffc3				;Datei schließen.
:CHKIN			= $ffc6				;Eingabefile setzen.
:CKOUT			= $ffc9				;Ausgabefile setzen.
:CLRCHN			= $ffcc				;Standard-I/O setzen.
:CLALL			= $ffe7				;Alle Kanäle schließen.

endif

			n "GeoHelpView"
			a "M. Kanet"
			c "GeoHelpView V1.5"
			f APPLICATION
			i
<MISSING_IMAGE_DATA>
			z $00

			o $0c00				;Ab $0400 - $0BFF liegt LoadGeoHelp!
			p JumpAdr1			;Nur falls vom DeskTop aus gestartet.
			q Memory

if Sprache = Deutsch
			h "=>01,GeoHelpView.001"
			h ""
			h "(Startet Übersicht Seite #1)"
			h "Offline-Hilfe für GEOS 64/128"
endif

if Sprache = Englisch
			h "=>01,GeoHelpView.en"
			h ""
			h "(Open help page #1)"
			h "Offline-help for GEOS 64/128"
endif

;*** Einsprungtabelle.
:JumpAdr1		jmp	MainInit		;Einsprung aus Anwendung.
:JumpAdr2		jmp	MainInit_DA		;Ensprung aus "LoadGeoHelp".

;*** Standard-Dateinamen.
;    Ist im Infoblock der Datei kein
;    Dateiname eingetragen, so öffnet
;    GeoHelpView diese Datei:
if Sprache = Deutsch
:Help001		b "GeoHelpView.001",$00,NULL
endif
if Sprache = Englisch
:Help001		b "GeoHelpView.en",$00,NULL
endif

;*** Klasse für Anwendung.
;    Wird benötigt um die Anwendung auf
;    Diskette zu suchen und Infoblock
;    einzulesen:
:FileClass		b "GeoHelpView ",NULL

;*** Zeichensatz für GeoHelpView.
:HelpFont		v 8,"GeoHelp.Edit.Fnt"

;*** Aufruf aus DeskTop.
:MainInit		jsr	InitHelp		;Hilfesystem aufrufen.
:MainExit		lda	#$08			;Auf Laufwerk #8 umschalten.
			jsr	SetDevice
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Aufruf aus "LoadGeoHelp".
:MainInit_DA		PopW	BackToDA		;Rücksprungadresse sichern.
			jsr	InitHelp		;Hilfesystem aufrufen.
			PushW	BackToDA		;Rücksprungadresse herstellen.
			rts				;Zurück zu "LoadGeoHelp".

;*** Hilfe initialisieren.
:InitHelp		PopW	ExitToRoutine		;Rücksprungadresse sichern.

			jsr	InitForIO		;Maus und Rahmenfarbe sichern.
			lda	screencolors
			sta	B_GEOS_BACK
			lda	$d020
			sta	B_GEOS_FRAME
			lda	$d027
			sta	B_GEOS_MOUSE
			jsr	DoneWithIO

;--- Hinweis:
;RAMLink-Systemwerte initialisieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, weiter...
;---

			LoadB	r0L,%00000001		;Datei "COLOR.INI" nachladen.
			LoadW	r6,ColFileName
			LoadW	r7,Memory
			jsr	GetFile
			txa				;Diskettenfehler ?
			bne	:101			;Ja, weiter...

			jsr	i_MoveData
			w	Memory
			w	colSystem
			w	(EndColors-colSystem)

::101			jsr	i_FillRam		;Variablenspeicher löschen.
			w	(Memory-Variablen)
			w	Variablen
			b	$00

;*** GEOS-Systemwerte zwischenspeichern.
			MoveB	dispBufferOn ,b_dispBufferOn
			MoveW	StringFaultVec ,b_StringFaultVec
			MoveW	rightMargin ,b_rightMargin
			MoveW	otherPressVec ,b_otherPressVec
			MoveW	RecoverVector ,b_RecoverVector

;*** Variablen initialisieren.
			LoadB	dispBufferOn ,ST_WR_FORE
			LoadW	StringFaultVec ,EndOfLine
			LoadW	rightMargin ,$0130
			LoadW	otherPressVec ,ChkMseKlick
			ClrW	RecoverVector

			lda	C_Hinweis
			and	#%11110000
			ora	C_HelpBack
			sta	C_Hinweis

			lda	C_Seite
			and	#%11110000
			ora	C_HelpBack
			sta	C_Seite

			ClrB	VLIR_Open

;*** Nach erster Anzeigeseite suchen.
;    Infoblock einlesen. Kennung "=>"
;    vorhanden, Hilfedatei laden.
;    Sonst "GeoHelpView.001" laden.
:Get1stFile		LoadW	r6 ,FileNameBuf
			LoadB	r7L,APPLICATION
			LoadB	r7H,$01
			LoadW	r10,FileClass
			jsr	FindFTypes		;GeoHelpView suchen.
			txa				;Gefunden ?
			beq	:102			;Ja, weiter...
::101			jmp	GHV_SysErr		;Systemfehler.

::102			LoadW	r6,FileNameBuf
			jsr	FindFile		;Verzeichnis-Eintrag suchen.
			txa				;Gefunden ?
			bne	:101			;Nein, weiter...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Systemfehler.

::103			ldx	#"="			;Erstes Zeichen für Datei-Kennung.
			cpx	fileHeader+$a0		;Zeichen vorhanden ?
			bne	:104			;Nein, Standardhilfedatei anzeigen.

			ldx	#">"			;Zweites Zeichen für Datei-Kennung.
			cpx	fileHeader+$a1		;Zeichen vorhanden ?
			beq	CopyDrive		;Nein, Standardhilfedatei anzeigen.
::104			jmp	GetStdHelp

;*** Auf Laufwerk/Partition testen.
;    (w:xyz) (Laufwerk:Partition)
;    A,B,C,D Laufwerk A:,B:,C:,D:
;    R       RAMLink
;    H       CMD HD
;    F       CMD RL
:CopyDrive		lda	fileHeader +$a2
			cmp	#"("
			beq	:102

::101			lda	#$00
			sta	Flag_SetDrive
			jmp	CopyPageName1

::102			lda	fileHeader +$a3

			ldy	#$06
::103			cmp	Drive_Types,y
			beq	:104
			dey
			bpl	:103
			bmi	:101

::104			iny
			sty	Flag_SetDrive

			lda	curDrive
			sta	Drive_Start

			tya
			cmp	#$05
			bcc	:105
			jsr	FindCMD_Drive
			tax
			bmi	:111

::105			clc
			adc	#$08 -1
			sta	Drive_Adress
			jsr	SetDevice

;--- Hinweis:
;RAMLink-Systemwerte initialisieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:111			;Ja, weiter...
;---

			lda	fileHeader +$a4
			cmp	#":"
			beq	:106
			jmp	CopyPageName2

::106			jsr	GetCMD_Code
			txa
			bne	:111

			ldy	#$a5
			LoadW	r0,fileHeader		;Partitions-Nr. einlesen.
			jsr	Get100DezCode
			sta	Drive_HPart

			ldx	curDrive
			lda	driveType   -8,x
			bpl	:107

			lda	ramBase     -8,x
			sta	Drive_RPart +0
			lda	driveData   +3
			sta	Drive_RPart +1
			jmp	:108

::107			jsr	GetCurPInfo
			txa
			bne	:111
			sty	Drive_SPart

::108			lda	Drive_HPart
			jsr	SetNewPart
			txa
			bne	:111

::109			lda	#$ff
			sta	Flag_SetPart

::110			jmp	CopyPageName3
::111			jmp	DriveError

;*** Laufwerk zurücksetzen.
:ResetDrive		lda	Flag_SetDrive
			beq	:103
			lda	Flag_SetPart
			beq	:102

			lda	Drive_Adress
			jsr	SetDevice

			ldx	curDrive
			lda	driveType -8,x
			bpl	:101

			lda	Drive_RPart +0
			sta	ramBase     -8,x
			lda	Drive_RPart +1
			sta	driveData   +3
			jmp	:102

::101			lda	Drive_SPart
			jsr	SetNewPart

::102			lda	Drive_Start
			jsr	SetDevice
::103			rts

;*** Laufwerksfehler.
:DriveError		ldy	#$00
::101			lda	fileHeader +$a3,y
			beq	:102
			cmp	#CR
			beq	:102
			cmp	#")"
			beq	:102
			sta	DNF_1a,y
			iny
			cpy	#15
			bne	:101

::102			lda	#" "
::103			sta	DNF_1a,y
			iny
			cpy	#16
			bne	:103

::104			lda	#<DrvNotFound
			ldy	#>DrvNotFound
			jmp	ExecError

;*** CMD-Laufwerk suchen.
:FindCMD_Drive		lda	#$08
::101			sta	:102 +1
			sta	Drive_Adress
			jsr	SetDevice

			jsr	GetCMD_Code
			txa
			bne	:102

			tya
			ldx	Flag_SetDrive
			dex
			cmp	Drive_Types  ,x
			bne	:102

			lda	curDrive
			sec
			sbc	#$07
			rts

::102			ldx	#$ff
			inx
			txa
			cmp	#12
			bne	:101

			lda	#$ff
			rts

;*** Dateiname aus Infoblock in
;    Zwischenspeicher kopieren.
:CopyPageName1		ldy	#$a2
			b $2c
:CopyPageName2		ldy	#$a5
			b $2c
:CopyPageName3		ldy	#$a9
			sty	:101 +1

			LoadW	r0,fileHeader		;Seiten-Nr. einlesen.
			jsr	GetDezCode
			sub	1
			bcc	GetStdHelp
			cmp	#61
			bcs	GetStdHelp
			sta	:105 +1			;Ja, Seite merken.

::101			lda	#$ff
			clc
			adc	#$03
			tay
			ldx	#$00
::102			lda	fileHeader ,y
			beq	:103
			cmp	#CR
			beq	:103
			sta	FileNameBuf,x
			iny
			inx
			cpx	#16
			bcc	:102

::103			lda	#$00
			sta	FileNameBuf,x
			inx
			cpx	#17
			bcc	:103

			LoadW	r6,FileNameBuf
			jsr	FindFile		;Hilfedatei suchen.
			txa				;Gefunden ?
			bne	GetStdHelp		;Nein, Standardhilfedatei anzeigen.

			ldy	#$0f
::104			lda	FileNameBuf,y		;Name der Hilfedatei in Speicher für
			sta	Help001,y		;"Datei #1" übertragen.
			dey
			bpl	:104

::105			lda	#$ff			;Gewünschte Ziel-Seite.
			b $2c

;*** Hilfedatei suchen, Seite #1 laden.
:GetStdHelp		lda	#$00			;Seite #1 einlesen.
			pha				;Zielseite merken.
			jsr	CopyStdName		;Name von "Datei #1" kopieren.
			pla
			jsr	LoadPage		;Seite einlesen.
			txa
			bne	:101
			jmp	InitScreen		;Bildschirm aufbauen.
::101			jmp	GHV_FileErr

;*** Bildschirm initialisieren.
:InitScreen		jsr	SetMenuScreen

			jsr	PrintPage		;Aktuelle Seite anzeigen.

:InitMenu		LoadW	r0,MoveBarData
			jsr	InitBalken		;Anzeigebalken initialisieren.

;*** GeoHelpView-Menü aktivieren.
			jsr	i_IconCol		;Farbe für Menü-Icons.
			b	$00,$01,$28,$03

			LoadW	r0,icon_Tab1
			jmp	DoIcons			;Icons-Menü aktivieren.

;*** Menübildschirm aufbauen.
:SetMenuScreen		StartMouse			;Maustreiber aktivieren.
			NoMseKey			;Warten bis keine Maustaste gedrückt.

			jsr	InitForIO
			lda	C_Back
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027
			jsr	DoneWithIO

			jsr	ClrScreen		;Bildschirm löschen.

			jsr	i_TitelCol		;Bildschirmfarben setzen.
			b	$00,$00,$28,$01
			jsr	i_BoxCol
			b	$00,$01,$28,$04
			jsr	i_TxtCol
			b	$00,$05,$28,$13
			jsr	i_BoxCol
			b	$00,$18,$28,$01

			LoadW	r0,HelpFont		;GeoHelpView-Font aktivieren.
			jsr	LoadCharSet
			LoadW	r0,HelpText01
			jmp	PutString

;*** Textausgabe.
:PutXYText		sty	r1H
:PutText		sta	r0L
			stx	r0H
			jmp	PutString

;*** Hilfe verlassen.
:ExitHelp		jsr	ResetDrive
			jsr	SetOrgCol		;GEOS-Bildschirm zurücksetzen.

			MoveB	b_dispBufferOn ,dispBufferOn
			MoveW	b_StringFaultVec ,StringFaultVec
			MoveW	b_rightMargin ,rightMargin
			MoveW	b_otherPressVec ,otherPressVec
			MoveW	b_RecoverVector ,RecoverVector

			PushW	ExitToRoutine		;Rücksprungadresse wieder herstellen.
			rts				;Ende...

;*** Farbe für Bildschirm und Mauszeiger setzen.
:SetOrgCol		jsr	InitForIO
			lda	B_GEOS_BACK
			sta	screencolors
			lda	B_GEOS_FRAME
			sta	$d020
			lda	B_GEOS_MOUSE
			sta	$d027
			jsr	DoneWithIO

			lda	screencolors
			sta	:101

			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::101			b	$00

			jsr	UseSystemFont

;*** Bildschirm löschen.
:ClrScreen		jsr	i_FillRam
			w	8000
			w	SCREEN_BASE
			b	$00

;*** Rechte Bildschirmgrenze erreicht.
;    Kein Text mehr ausgeben.
:EndOfLine		rts

;*** Speicherauslastung berechnen.
;    Formel:
;    (Belegter Speicher/16)  * 100
;    -----------------------------
;      (Max. freier Speicher/16)
;Division durch 16 ist nötig, da sonst
;Werte über 65536 erreicht werden und
;dann fehlerhafte Ergebnisse entstehen.
:GetUsedMem		sec				;Belegten Speicher berechnen.
			lda	StartFreeMem+0
			sbc	#<HelpTextMem
			sta	r0L
			lda	StartFreeMem+1
			sbc	#>HelpTextMem
			sta	r0H

			ldx	#r0L			;Speicher durch 16 teilen.
			ldy	#$04
			jsr	DShiftRight

			LoadB	r1L,100

			ldx	#r0L
			ldy	#r1L
			jsr	BMult			;Mit 100 multiplizieren.

			LoadW	r1,(TxtBufSize/16)

			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv			;Ergebnis durch max. Speicher teilen.

			lda	r0L
			sta	UsedMem			;Prozent-Ergebnis merken.
			rts

;*** System-Dialogbox.
;    Bildschirm löschen,
;    Farben zurücksetzen,
;    Dialogbox ausführen.
:DoSysDlgBox		PushW	RecoverVector
			PushW	r0

			lda	#$02
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			LoadW	RecoverVector,:101
			PopW	r0
			jsr	DoDlgBox
			PopW	RecoverVector
			rts

::101			lda	#$02
			jsr	SetPattern
			jmp	Rectangle

;*** Diskettenfehler anzeigen.
:GHV_FileErr		cpx	#$05			;Fehler: "File not found" ?
			beq	PageError		;Ja, weiter...
			cpx	#$08			;Fehler: "Invalid Record" ?
			beq	PageError		;Ja, weiter...
			cpx	#$ff			;Fehler: "Falsches Textformat" ?
			beq	PageError		;Ja, weiter...

;*** GeoHelpView-Systemfehler.
:GHV_SysErr		jsr	SetOrgCol		;GEOS-Bildschirm zurücksetzen.

			LoadW	r0,SysErrBox
			jsr	DoSysDlgBox		;Diskettenfehler anzeigen.
			jmp	ExitHelp		;GeoHelpView beenden.

;*** Seite nicht verfügbar:
:PageError		ldy	#$00			;Dateiname der
::101			lda	NewHelpFile,y		;fehlerhaften Datei kopieren.
			beq	:102
			sta	FNF_1a,y
			sta	PNF_1a,y
			sta	FE_1a ,y
			iny
			cpy	#$10
			bcc	:101
::102			cpy	#$10
			beq	:103
			lda	#" "
			sta	FNF_1a,y
			sta	PNF_1a,y
			sta	FE_1a ,y
			iny
			bne	:102

::103			lda	curHelpPage
			add	1
			ldy	#$30
::104			cmp	#10
			bcc	:105
			iny
			sub	10
			bcs	:104
::105			add	$30
			sty	PNF_2a +0
			sta	PNF_2a +1

			lda	#<FileNotFound		;Zeiger auf Fehlertext für
			ldy	#>FileNotFound		;"File not found".
			cpx	#$05
			beq	ExecError
			lda	#<PageNotFound		;Zeiger auf Fehlertext für
			ldy	#>PageNotFound		;"Invalid Record".
			cpx	#$ff
			bne	ExecError
			lda	#<FormatError		;Zeiger auf Fehlertext für
			ldy	#>FormatError		;"Falsches Textformat".

:ExecError		sta	r0L
			sty	r0H
			LoadW	r1,LoadAdress
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString		;Fehlertext in Textspeicher.

			ClrB	curHelpPage
			jsr	InitPageData		;Seite initialisieren.
			jsr	LoadPageData		;Seiten-Informationen ermitteln.
			jsr	SetMenuScreen
			jsr	PrintPage		;Zum Anfang der Seite und ausgeben.
			jmp	InitMenu

;*** Zum letzten Thema zurückblättern.
:CallLastPage		ldx	HelpFileVec		;Stackzeiger einlesen.
			cpx	#$02			;Weitere Seite im Stackspeicher ?
			bcs	:101			;Ja, weiter...

			ClrB	HelpFileVec		;Nein, Seite #1 von "Datei #1"
			jmp	FindMainHelp		;einlesen und anzeigen.

::101			dex				;Zeiger auf letzten Stackeintrag.
			dex
			stx	HelpFileVec

			lda	HelpFilePage,x		;Seitenzeiger merken.
			pha
			lda	HelpFileLine ,x		;Zeiger innerhalb Seite merken.
			pha

			txa				;Zeiger auf Dateiname berechnen.
			asl
			asl
			asl
			asl
			tax

			ldy	#$00			;Dateiname aus Stackspeicher in
::102			lda	HelpFileName,x		;Zwischenspeicher kopieren.
			sta	NewHelpFile,y
			inx
			iny
			cpy	#$10
			bcc	:102

			pla
			sta	LinePointer		;Zeiger innerhalb der Seite setzen.
			pla
			jmp	GotoNewPage		;Seite einlesen.

;*** Aktuelle Seite in Stackspeicher eintragen.
:PageInBuffer		lda	HelpFileVec		;Stackzeiger merken.
			pha
			cmp	#10			;Stackspeicher voll ?
			bcc	:103			;Nein, weiter...

			jsr	i_MoveData		;Ersten Eintrag löschen.
			w	HelpFileName+16
			w	HelpFileName+ 0
			w	9 * 16

			jsr	i_MoveData
			w	HelpFilePage+ 1
			w	HelpFilePage+ 0
			w	9 *  1

			jsr	i_MoveData
			w	HelpFileLine + 1
			w	HelpFileLine + 0
			w	9 *  1

			pla				;Stackzeiger -1.
			sub	1
			pha

::103			pla				;Stackzeiger einlesen.
			pha
			tax
			lda	curHelpPage		;Aktuelle Seite merken.
			sta	HelpFilePage,x

			txa				;Zeiger auf Dateiname berechnen.
			asl
			asl
			asl
			asl
			tax

			ldy	#$00			;Dateiname in Stackspeicher kopieren.
::104			lda	curHelpFile,y
			sta	HelpFileName,x
			inx
			iny
			cpy	#$10
			bcc	:104

			pla
			add	1
			sta	HelpFileVec		;Stackzeiger korrigieren.
			rts

;******************************************************************************
;*** GeoHelpView-Codes ausführen.
;******************************************************************************
:MakeGHVcode		bit	SetGHVcode		;GHV-Codes erzeugen ?
			bmi	:100			;Nein, Steuercode ignorieren.

			iny
			lda	(r0L),y
			cmp	#"1"			;`1 = Link-verweis.
			beq	:101
			cmp	#"2"			;`2 = Titel erzeugen.
			beq	:102
			cmp	#"3"			;`3 = Farbe setzen.
			beq	:103
			cmp	#"4"			;`4 = Grafik anzeigen.
			beq	:104

;*** Ende GHV-Code markieren.
			bit	SetGHVcode		;GHV-Codes erzeugen ?
			bmi	:100			;Nein, Steuercode ignorieren.

			jsr	MoveToCard		;X-Koordinate korrigieren.
							;(Linkbereiche und Farbe beziehen sich
							; immer auf ganze CARD-Bereiche!)

			lda	#$f6			;Link-Verweise müssen mit einzelnem `
			jsr	StoreByte		;beendet werden. Ersetzen durch $F6.

::100			lda	#$01			;1 Byte überlesen.
			jmp	PosNextByte

::101			jmp	MakeLink		;Link-Verweis erzeugen.
::102			jmp	MakeTitel		;Titel erzeugen.
::103			jmp	MakeColor		;Farbe erzeugen.
::104			jmp	MakeGrafx		;Grafik erzeugen.

;*** Linkverweis erzeugen.
:MakeLink		jsr	MoveToCard		;X-Koordinate korrigieren.
							;(Linkbereiche beziehen sich immer auf
							; ganze CARD-Bereiche!)
			lda	#$f2
			jsr	StoreByte		;GHV-Code "Link-Verweis" übertragen.

			lda	r10H
			jsr	StoreByte		;Nr. des Links übertragen.
			inc	r10H			;Linkzähler +1.

::101			lda	#$02			;2 Byte überlesen.
			jmp	PosNextByte

;*** Titelfarbe erzeugen.
:MakeTitel		lda	#$f3
			jsr	StoreByte		;GHV-Code "Titel" übertragen.

::101			lda	#$02			;2 Byte überlesen.
			jmp	PosNextByte

;*** Farbe erzeugen.
:MakeColor		lda	#$f4
			jsr	StoreByte		;GHV-Code "Farbe" übertragen.

			ldy	#$02
			jsr	GetHexCode		;HEX-Zahl einlesen.
			jsr	StoreByte		;Farbe übertragen.

::101			lda	#$04			;4 Byte überlesen.
			jmp	PosNextByte

;*** Grafik anzeigen.
:MakeGrafx		lda	#$f5
			jsr	StoreByte		;GHV-Code "Grafik" übertragen.

			ldy	#$02
			jsr	GetDezCode		;Grafik-Nr. einlesen.
			pha
			jsr	StoreByte		;Nr. in Zwischenspeicher übertragen.
			ldy	#$04
			jsr	GetDezCode		;Zeilen-Nr. einlesen.
			jsr	StoreByte		;In Zwischenspeicher übertragen.
			pla
			jsr	SetGrafxEnd		;X-Koordinate korrigieren.

::101			lda	#$06			;6 Byte überlesen.
			jmp	PosNextByte

;******************************************************************************
;*** Seite ausgeben.
;******************************************************************************
:PrintPage		FillPRec$00,$28,$c7,$0000,$0137
			jsr	i_TxtCol
			b	$00,$05,$27,$13

			LoadB	r1H,$2e
			ClrB	currentMode
			MoveB	LinePointer,r14L

::101			lda	r14L
			jsr	SetLineAdr		;Zeiger auf aktuelle Zeile.
			beq	:103			;Zeile nicht verfügbar, Ende.

::102			jsr	SetXtoStart		;X-Koordinate auf Anfang.
			jsr	PrintLine		;Zeile ausgeben.

			AddVBW	8,r1H			;Zeiger auf nächste Zeile.
			inc	r14L
			CmpBI	r1H,$c6			;Bildschirmende erreicht ?
			bcc	:101			;Nein, weiter...

;*** Seiteninformtionen ausgeben.
::103			PrintXY	$0008,$c6,curHelpFile

			PrintStrgUsedMemTxt		;Speicherauslastung in Prozent
			MoveB	UsedMem,r0L		;ausgeben.
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			lda	#"%"
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			PrintStrgTextPage		;"Seite:" ausgeben.

			ldx	curHelpPage		;Aktuelle Seiten-Nr. ausgeben.
			inx
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			lda	#" "
			jsr	SmallPutChar

			lda	LinePointer		;Balken neu positionieren.
			jmp	SetPosBalken

;*** Zeilenadresseberechnen.
:SetLineAdr		ldy	#$00			;Startadresse der aktuellen
			asl				;Zeile einlesen.
			bcc	:101
			iny
::101			clc
			adc	#<LineStartAdr
			sta	r0L
			tya
			adc	#>LineStartAdr
			sta	r0H

			ldy	#$00
			lda	(r0L),y
			sta	r15L
			iny
			lda	(r0L),y
			sta	r15H			;Seite vorhanden ?
			ora	r15L			;Nur wenn low/high <> $00 !
			rts

;*** Erste Zeile ausgeben.
:PrintTopLine		FillPRec$00,$28,$2f,$0000,$0137
			jsr	i_TxtCol
			b	$00,$05,$27,$01

			lda	LinePointer		;Zeiger auf erste Zeile.
			ldy	#$2e
			jmp	InitPrntLine

;*** Letzte Zeile ausgeben.
:PrintEndLine		FillPRec$00,$b8,$bf,$0000,$0137
			jsr	i_TxtCol
			b	$00,$17,$27,$01

			lda	LinePointer		;Zeiger auf letzte Zeile.
			add	18
			ldy	#$be

:InitPrntLine		sty	r1H			;Zeilendaten berechnen.
			jsr	SetXtoStart
			jsr	SetLineAdr

;*** Aktuellen Zeile ausgeben.
:PrintLine		ldy	#$00
			lda	(r15L),y		;Zeichen aus Text einlesen.

			cmp	#CR			;Zeilenende erreicht ?
			beq	L900a0			;Ja, nächste Zeile.

			cmp	#NULL			;Seitenende erreicht ?
			bne	L900b0			;Nein, weiter...

:L900a0			bit	SetColMode		;Farbmodus aktiv ?
			bpl	L900a1			;Nein, weiter...
			jsr	SetGHVcol		;Farbe anzeigen.
:L900a1			IncWord	r15			;Zeiger auf nächstes Zeichen.
			rts

;*** GHV-Steuerzeichen auswerten.
;    Ungültige Textzeichen ($00-$1f, $80-$ff) ignorieren.
:L900b0			cmp	#$ff			;Blockende = Textende erreicht ?
			beq	L900a1			;Ja, Ende...
			cmp	#$f0			;GHV-Steuercode ?
			bcc	L900b1			;Nein, weiter...
			jmp	ExecGHVcode		;GHV-Code ausführen.

:L900b1			cmp	#$20			;GEOS-ASCII-Zeichen ausgeben.
			bcc	L900b2
			cmp	#$7f
			bcs	L900b2
			jsr	SmallPutChar

:L900b2			lda	#$01			;Zeiger auf nächstes Zeichen.

:L900b3			jsr	AddAto_r15		;Nächstes Zeichen der
			jmp	PrintLine		;aktuellen Zeile ausgeben.

;******************************************************************************
;*** GHV-Code ausführen.
;******************************************************************************
:ExecGHVcode		cmp	#$f1			;Tabulator ?
			beq	:102			;Ja, ausführen...
			cmp	#$f2			;Link-Verweis ?
			beq	:103			;Ja, ausführen....
			cmp	#$f3			;Titelfarbe setzen ?
			beq	:104			;Ja, ausführen....
			cmp	#$f4			;Frabe setzen ?
			beq	:105			;Ja, ausführen....
			cmp	#$f5			;Grafik anzeigen ?
			beq	:106			;Ja, ausführen....
			cmp	#$f6			;Link/Farbe abschließen ?
			beq	:107			;Ja, ausführen....
			jmp	L900b2			;Zeichen übergehen.

::102			jmp	ExecSetTab
::103			jmp	ExecDoLink
::104			jmp	ExecTitel
::105			jmp	ExecColor
::106			jmp	ExecGrafx
::107			jmp	ExecEndCol

;*** Tabulator ausführen.
:ExecSetTab		jsr	Do_SetTab		;Tabulator setzen.
			jmp	L900b3			;3 Byte überlesen.

:Do_SetTab		ldy	#$01
			lda	(r15L),y
			sta	r11L
			iny
			lda	(r15L),y
			sta	r11H

			lda	#$03
			rts

;*** Link anzeigen.
:ExecDoLink		lda	C_Seite			;Farbe für Linkverweis anzeigen.
			jsr	GHV_Init_1

			lda	#$02			;2 Byte überlesen.
			jmp	L900b3

;*** Titel anzeigen.
:ExecTitel		lda	#$21			;Farbe für Titelzeile anzeigen.
			jsr	GHV_Init_1

			lda	#$01			;1 Byte überlesen.
			jmp	L900b3

;*** Farbe anzeigen.
:ExecColor		ldy	#$01
			lda	(r15L),y		;Farbe anzeigen.
			jsr	GHV_Init_1

			lda	#$02			;2 Byte überlesen.
			jmp	L900b3

;*** Farbe abschließen.
:ExecEndCol		bit	SetColMode		;Farbmodus aktiv ?
			bpl	:101			;Nein, weiter...
			jsr	SetGHVcol		;Farbe anzeigen.
::101			jmp	L900b2

:SetGHVcol		ClrB	SetColMode		;Farbmodus löschen.

			bit	SetColOK		;Darf Farbe gesetzt werden ?
			bmi	SetColEnd		;Nein, weiter...

			jsr	MoveToCard		;Zeiger auf nächstes CARD.
			jsr	PixelToCard		;Pixel nach CARD umrechnen.
			txa
			suba	ColData+0		;Anzahl FarbCARDS berechnen.
			sta	ColData+2

			lda	r1H			;Y-Koordinate für Farbbereich
			sub	6			;berechnen.
			lsr
			lsr
			lsr
			sta	ColData+1

			PushW	r15			;Register zwischenspeichern.
			PushB	r1H
			PushW	r11

			jsr	i_ColorBox
:ColData		b	$00,$00,$00,$01,$00

			PopW	r11			;Register wieder herstellen.
			PopB	r1H
			PopW	r15

:SetColEnd		rts

;*** Grafik anzeigen.
:ExecGrafx		jsr	GetIconAdr		;Startadr. Icon im RAM ermitteln.
			bne	:102			;Icon verfügbar ?
::101			AddVBW	2,r15			;Nein, Icon nicht ausgeben.
			jmp	ExecEndCol

::102			PushW	r11			;Cursor-Position speichern.
			PushB	r1H

			jsr	GHV_Init_3
			stx	r1L

			SubVB	6,r1H			;Y-Koordinate für Grafik berechnen.

			ldy	#$00
			lda	(r0L),y
			sta	r2L			;Breite des Ausschnitts.
			pha
			lda	#$08			;Höhe des Ausschnitts.
			sta	r2H			;(Immer nur 8 Pixel!).

			LoadB	r11L,$00		;Icon auf gesamte Breite ausgeben.
			LoadB	r11H,$00

			MoveB	r13H,r12L		;Anzahl Zeilen bis Ausschnitt
			ClrB	r12H			;beginnt.
			ldx	#r12L
			ldy	#$03
			jsr	DShiftLeft

			AddVBW	3,r0			;Zeiger auf Icon-Daten.
			jsr	BitmapClip		;Ausschnitt ausgeben.

			pla				;Icon-Breite speichern.
			sta	r0L
			ClrB	r0H

			PopB	r1H			;Cursor-Position zurücksetzen.
			PopW	r11

			jsr	MoveToCard		;Neue Cursor-Position berechnen.

			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddW	r0,r11

			AddVBW	2,r15
			jmp	ExecEndCol

;*** Startadresse Icon ermitteln.
:GetIconAdr		ldy	#$02
			lda	(r15L),y
			sta	r13H
			dey
			lda	(r15L),y
			sta	r13L
			sub	1			;Zeiger aus Scrap im Speicher
			asl				;berechnen und auf $0000 testen.
			tax
			lda	IconAdrTab+0,x
			sta	r0L
			lda	IconAdrTab+1,x
			sta	r0H
			ora	r0L
			rts

;*** Position für Farbe setzen.
:GHV_Init_1		sta	ColData+4		;Farbwert merken.

:GHV_Init_2		LoadB	SetColMode,$ff		;Farbmodus aktiv.

			jsr	GHV_Init_3		;Cursor auf nächstes CARD.
			stx	ColData+0		;Startadr. für Farbe berechnen.
			rts

:GHV_Init_3		jsr	MoveToCard
			jmp	PixelToCard

;*** Akku zu ":r0" addieren.
:AddAto_r0		ldx	#r0L
			b $2c

;*** Akku zu ":r11" addieren.
:AddAto_r11		ldx	#r11L
			b $2c

;*** Akku zu ":r15" addieren.
:AddAto_r15		ldx	#r15L

			clc
			adc	$00,x
			sta	$00,x
			bcc	:101
			inc	$01,x
::101			rts

;*** X-Koordinate auf Anfang.
:SetXtoStart		ldx	#<$0008
			stx	r11L
			ldx	#>$0008
			stx	r11H
			rts

;*** Aktuelle Cursorposition auf nächstes CARD setzen.
:MoveToCard		lda	r11L
			and	#%00000111
			beq	:101
			lda	r11L
			and	#%11111000
			add	8
			sta	r11L
			bcc	:101
			inc	r11H
::101			rts

;*** Aktuelles Cursorposition in CARDS umwandeln.
:PixelToCard		PushW	r11
			ldx	#r11L
			ldy	#$03
			jsr	DShiftRight
			ldx	r11L
			PopW	r11
			rts

;*** Aktuelles Cursorposition in CARDS umwandeln.
:CardToPixel		ldx	#r11L
			ldy	#$03
			jmp	DShiftLeft

;*** ASCII-Zahl (zwei Zeichen) nach DEZIMAL.
:GetHexCode		jsr	:111
			tax
			iny
			jsr	:111
			cpx	#$00
			beq	:102
::101			add	16
			dex
			bne	:101
::102			rts

::111			lda	(r0L),y
			sub	$30
			cmp	#$0a
			bcc	:112
			and	#%00011111
			sub	$07
::112			rts

;*** ASCII-Zahl (Drei Zeichen) nach DEZIMAL.
:Get100DezCode		lda	(r0L),y			;100er-Wert einlesen.
			sub	$30			;Zahlenwert ermitteln.
			tax				;100er-Wert = $00 ?
			beq	:102			;Ja, weiter...

			lda	#$00			;100er-Wert berechnen.
::101			add	100
			dex
			bne	:101
::102			iny				;Zeiger auf 10er-Wert setzen.

			b $2c				;2Byte-Befehl übergehen.

;*** ASCII-Zahl (Zwei Zeichen) nach DEZIMAL.
:GetDezCode		lda	#$00			;Startwert für Umwandlung.
			sta	:101 +1			;Wert zwischenspeichern.

			lda	(r0L),y			;10er-Wert einlesen.
			sub	$30			;Zahlenwert ermitteln und
			tax				;zwischenspeichern.
			iny				;Zeiger auf 1er-Wert setzen.
			lda	(r0L),y			;1er-Wert einlesen.
			sub	$30			;Zahlenwert ermitteln

			clc
::101			adc	#$ff			;Startwert addieren (0 oder 100, 200)
			cpx	#$00			;10er-Wert = $00 ?
			beq	:103			;Ja, weiter...

::102			add	10			;10er-Wert berechnen.
			dex
			bne	:102
::103			rts				;Ende.

;******************************************************************************
;*** Maus abfragen, testen ob Link-Verweis gewählt.
;******************************************************************************
:ChkMseKlick		ClrB	r0L
::101			jsr	CopyMouseData		;Mausbereich einlesen.

			php
			sei
			jsr	IsMseInRegion
			plp
			tax				;Mausklick innerhalb Bereich ?
			beq	:102			;Nein, weiter...
			jmp	(r5)			;Ja, Routine aufrufen.

::102			inc	r0L
			lda	r0L
			cmp	#$04			;Alle Bereiche überprüft ?
			bne	:101			;Nein, weiter...
			rts				;Ja, Keine Funktion!

;*** Bereichsdaten einlesen.
:CopyMouseData		asl
			asl
			asl
			tay
			ldx	#$00
::101			lda	V402f1,y
			sta	r2L,x
			iny
			inx
			cpx	#$08
			bne	:101
			rts

;*** Dauerfunktion ?
:TestMouse		lda	mouseData		;Maustaste noch gedrückt ?
			bne	:101			;Nein, weiter...
			sec
			rts

::101			ClrB	pressFlag
			clc
			rts

;*** Mausklick beenden.
:EndSlctIcon		jsr	CopyMouseData
			jsr	InvertRectangle
			NoMseKey
			LoadW	r0,V402f2
			jmp	InitRam

;*** Seite anzeigen und auf Maustaste warten.
:NPageAndMse		jsr	PrintPage
			NoMseKey
			rts

;******************************************************************************
;*** Link-Verweis ausführen.
;*** - Zeiger auf Textzeile berechnen.
;*** - Innerhalb Zeile Link-Verweise suchen.
;*** - Prüfen ob Verweis angeklickt wurde.
;*** - Ja, ausführen, Nein, weitersuchen.
;******************************************************************************
:ExecuteLink		NoMseKey			;Warten bis keine Maustaste gedrückt.

			MoveW	mouseXPos,r10		;X-Register merken.

			lda	mouseYPos		;Zeile berechnen.
			sub	$28
			lsr
			lsr
			lsr
			adda	LinePointer
			jsr	SetLineAdr		;Textzeile für Mausklick berechnen.

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

			ClrB	r12H			;Linkzähler löschen.

:L900c0			ldy	#$00
			lda	(r15L),y		;Zeichen aus Zeile einlesen.
			beq	L900c1			;Seitenende erreicht ? Ja, Ende...
			cmp	#$ff			;Blockende erreicht ?
			beq	L900c1			;Ja, Ende...
			cmp	#CR			;Zeilenende erreicht ?
			bne	L900c2			;Nein, weiter...
:L900c1			rts

:L900c2			cmp	#$f0			;GHV-Steuercode ?
			bcs	L900d0			;Ja, auswerten.

:L900c3			jsr	GetCharWidth		;Zeichenbreite ermitteln.

:L900c4			jsr	AddAto_r11		;X-Koordinate korrigieren.
			lda	#$01

:L900c5			jsr	AddAto_r15		;Zeiger auf nächstes Zeichen.
			jmp	L900c0

;******************************************************************************
;*** Überlesen der GHV-Codes um Link-Verweise innerhalb
;*** der aktuellen Textzeile zu finden.
;******************************************************************************
:L900d0			cmp	#$f1			;Tabulator setzen ?
			bne	:101			;Nein, weiter...
			jsr	Do_SetTab		;Cursor auf neuen X-Wert setzen.
			jmp	L900c5

::101			cmp	#$f2			;Linkverweis setzen ?
			bne	:102			;Nein, weiter...
			ldy	#$01
			lda	(r15L),y		;Nr. des Links in
			sta	r12L			;Zwischenspeicher kopieren.
			LoadB	r12H,$ff		;Link-Modus aktiv.
			jsr	GHV_Init_3		;Zeiger auf nächstes CARD.
			MoveW	r11,r8			;Startadresse Linkbereich merken.
			lda	#$02
			jmp	L900c5

::102			cmp	#$f3			;Titel anzeigen ?
			bne	:103			;Nein, weiter...
			jsr	GHV_Init_3		;Zeiger auf nächstes CARD.
			lda	#$01
			jmp	L900c5

::103			cmp	#$f4			;Farbe anzeigen ?
			bne	:104			;Nein, weiter...
			jsr	GHV_Init_3		;Zeiger auf nächstes CARD.
			lda	#$02
			jmp	L900c5

::104			cmp	#$f5			;Grafik anzeigen ?
			bne	:105			;Nein, weiter...
			jsr	GetIconAdr		;Icon-Adresse einlesen.
			beq	:104a			;Icon verfügbar ? Nein, weiter...
			jsr	GHV_Init_3		;Zeiger auf nächstes CARD.
			stx	r11L			;Cursor hinter Icon setzen.
			ldy	#$00
			sty	r11H
			lda	(r0L),y
			jsr	AddAto_r11
			jsr	CardToPixel
::104a			lda	#$03
			jmp	L900c5

::105			cmp	#$f6			;Ende Link/Farbe erreicht ?
			bne	:106			;Nein, weiter...
			jsr	GHV_Init_3		;Zeiger auf nächstes CARD.
			bit	r12H			;Linkbereich abgeschlossen ?
			bmi	:105b			;Ja Link gefunden ?
::105a			lda	#$01
			jmp	L900c5

::105b			CmpW	r10,r8			;Mausklick innerhalb des
			bcc	:105a			;gefundenen Links ?
			CmpW	r10,r11
			bcs	:105a
			jmp	DoLinkJob		;Ja, Seite aufrufen.

::106			lda	#$01
			jmp	L900c5

;******************************************************************************
;*** Andere Seite anzeigen.
;******************************************************************************
:DoLinkJob		lda	StartGoto+0		;Zeiger auf Bereich Linkadressen.
			sta	r0L
			lda	StartGoto+1
			sta	r0H

			ClrB	r12H			;Zaähler für Linkadressen löschen.

::101			ldy	#$00
			lda	(r0L),y			;Zeichen aus Text einlesen.
			cmp	#$22			;Dateiname gefunden ?
			bne	:104			;Nein, weitersuchen.
			CmpB	r12L,r12H		;Dateiname für Link gefunden ?
			bne	:102			;Nein, Dateiname überlesen.
			jmp	DoLink			;Adresse gefunden, Seite aufrufen.

::102			inc	r12H			;Zähler für Dateinamen +1.

::102a			IncWord	r0			;Dateiname überlesen.
			lda	(r0L),y
			beq	:103			;Textende erreicht ?
			cmp	#CR			;Zeilenende erreicht ?
			beq	:105			;Ja, Nächsten Dateinamen suchen.
			cmp	#$ff			;Blockende erreicht ?
			bne	:102a			;Nein, weitersuchen.
::103			rts				;Linkadresse nicht gefunden.

::104			cmp	#NULL			;Textende erreicht ?
			beq	:103			;Ja, Fehler...
			cmp	#$ff			;Blockende erreicht ?
			beq	:103			;Ja, Fehler...

::105			IncWord	r0			;Zeiger auf nächstes Zeichen.
			jmp	:101

;*** Linkadresse gefunden.
:DoLink			ldx	HelpFileVec		;Zeiger innerhalb der Seite merken, um
			dex				;bei "Thema zurück" an diese Stelle im
			lda	LinePointer		;Text zurückzukehren.
			sta	HelpFileLine ,x

			ldy	#$00
			tya
			sta	LinePointer		;Zeiger auf Anfang der Seite.
::101			sta	NewHelpFile,y		;Dateinamenspeicher löschen.
			iny
			cpy	#$11
			bcc	:101

			IncWord	r0			;Zeiger auf dateiname richten.

			ldy	#$00
::103			lda	(r0L),y			;Dateiname in Zwischenspeicher.
			cmp	#$22
			beq	:105
			sta	NewHelpFile,y
			iny
			cpy	#$10
			bne	:103

::104			lda	(r0L),y
			cmp	#$22
			beq	:105
			iny
			bne	:104

::105			iny
			iny
			jsr	GetDezCode		;Seiten-Nr. einlesen.
			cmp	#$00			;Seite gültig ?
			beq	:106
			cmp	#62
			bcc	:107
::106			lda	#$01			;Seite ungültig, Seite #1 lesen.
::107			sub	1			;Seite in Datensatz umrechnen.
			jmp	GotoNewPage		;Seite einlesen.

;******************************************************************************
;*** Textseite bewegen.
;******************************************************************************
:NextLine		jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle

::101			jsr	NextLine_a		;Scrolling möglich ?
			bcs	:102			;Nein, Ende...
			jsr	ScrollDown		;Eine Zeile scrollen.

			lda	LinePointer		;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:101			;Weiterscrollen.

::102			lda	#$01
			jmp	EndSlctIcon

:NextLine_a		lda	LinesInMem
			cmp	#19
			bcc	:101
			lda	LinePointer
			add	19
			cmp	LinesInMem
			bcc	:102
::101			sec
			rts
::102			clc
			rts

;*** Eine Datei vorwärts.
:ScrollDown		php
			sei

			LoadW	r0,SCREEN_BASE  + 6*40*8 + 1*8
			LoadW	r1,SCREEN_BASE  + 5*40*8 + 1*8
			LoadW	r2,COLOR_MATRIX + 6*40   + 1
			LoadW	r3,COLOR_MATRIX + 5*40   + 1

			ldx	#18
::101			lda	#2
::102			pha
			ldy	#$00			;18 Grafikzeilen a 296 Byte.
::103			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#152
			bne	:103

			AddVBW	152,r0			;Grafikzeile wird in zwei Teilen
			AddVBW	152,r1			;kopiert, da > 256 Byte.

			pla
			sub	1
			bne	:102

			AddVBW	16,r0
			AddVBW	16,r1

			ldy	#$25			;Farbe kopieren.
::104			lda	(r2L),y
			sta	(r3L),y
			dey
			bpl	:104

			clc
			lda	r2L
			sta	r3L
			adc	#$28
			sta	r2L
			lda	r2H
			sta	r3H
			adc	#$00
			sta	r2H

			dex
			bne	:101
			plp

			inc	LinePointer
			jmp	PrintEndLine		;Eintrag ausgeben.

;******************************************************************************
;*** Textseite bewegen.
;******************************************************************************
:LastLine		jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle

::101			jsr	LastLine_a
			bcs	:102
			jsr	ScrollUp		;Eine Zeile scrollen.

			lda	LinePointer		;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:101			;Weiterscrollen.

::102			lda	#$00
			jmp	EndSlctIcon

:LastLine_a		lda	LinesInMem
			cmp	#19
			bcc	:101
			lda	LinePointer
			bne	:102
::101			sec
			rts
::102			clc
			rts

;*** Eine Datei zurück.
:ScrollUp		php
			sei

			LoadW	r0,SCREEN_BASE  + 22*40*8 + 1*8 + 152
			LoadW	r1,SCREEN_BASE  + 23*40*8 + 1*8 + 152
			LoadW	r2,COLOR_MATRIX + 22*40   + 1
			LoadW	r3,COLOR_MATRIX + 23*40   + 1

			ldx	#18
::101			lda	#$02
::102			pha
			ldy	#151			;18 Grafikzeilen a 296 Byte.
::103			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			dey
			cpy	#255
			bne	:103

			SubVW	152,r0			;Grafikzeile wird in zwei Teilen
			SubVW	152,r1			;kopiert, da > 256 Byte.

			pla
			sub	1
			bne	:102

			SubVW	16,r0
			SubVW	16,r1

			ldy	#$25			;Farbe kopieren.
::104			lda	(r2L),y
			sta	(r3L),y
			dey
			bpl	:104

			sec
			lda	r2L
			sta	r3L
			sbc	#$28
			sta	r2L
			lda	r2H
			sta	r3H
			sbc	#$00
			sta	r2H

			dex
			bne	:101
			plp

			dec	LinePointer
			jmp	PrintTopLine		;Eintrag ausgeben.

;******************************************************************************
;*** Seite drucken.
;******************************************************************************
:PrintHelpPage		jsr	LoadPrinter		;Druckertreiber laden.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter.
::101			jmp	InitScreen

::102			jsr	InitForPrint		;Druckertreiber initialisieren.

			lda	curHelpPage		;Aktuelle Seite merken.
			pha

			jsr	PrntScreen1		;Bildschirm initialisieren.
			jsr	PrntScreen2

			LoadB	SetColOK,$ff		;Keine Farbe setzen.

			jsr	SetzeGAdresse		;Zeiger auf Druckdaten-Speicher.
			jsr	StartPrint		;Drucker initialisieren.
			txa
			bne	:103			;Fehler, Abbruch.

			StartMouse
			NoMseKey			;Maustaste gedrückt ? Ja, warten...

			jsr	DruckStarten		;Hilfeseite drucken.
::103			jmp	ExitPrnMenu		;Menü-Funktionen wieder aktivieren.

;******************************************************************************
;*** Seite drucken.
;******************************************************************************
:PrintAllHelp		jsr	LoadPrinter		;Druckertreiber laden.
			txa				;Status merken.
			beq	:102
			jmp	InitScreen

::102			jsr	InitForPrint		;Druckertreiber initialisieren.

			lda	curHelpPage		;Aktuelle Seite merken.
			pha

			jsr	PrntScreen1		;Bildschirm initialisieren.
			jsr	PrntScreen2

			LoadB	SetColOK,$ff		;Keine Farbe setzen.

			jsr	SetzeGAdresse		;Zeiger auf Druckdaten-Speicher.
			jsr	StartPrint		;Drucker initialisieren.
			txa
			bne	ExitPrnMenu		;Fehler, Abbruch.

			StartMouse
			NoMseKey			;Maustaste gedrückt ? Ja, warten...

			lda	#$00
::103			pha
			jsr	LoadHelpPage		;Seite einlesen.
			txa				;Seite verfügbar ?
			bne	:104			;Nein, Druckende...

			jsr	PrntScreen2		;Bildschirmdaten anzeigen.

			jsr	DruckStarten		;Hilfeseite drucken.
			txa				;Abbruch ?
			beq	:105			;Nein, weiter drucken.

::104			pla
			jmp	ExitPrnMenu

::105			pla
			add	1
			cmp	#61			;Zeiger auf nächste Seite.
			bcc	:103			;Weiterdrucken.

;******************************************************************************
;*** Druckmenü verlassen.
;******************************************************************************
:ExitPrnMenu		LoadW	r6,HdrFileName		;Speicherbereich wieder herstellen.
			LoadW	r7,PRINTBASE
			LoadB	r0L,%00000001
			jsr	GetFile

			LoadW	r0,HdrFileName		;Swapdatei auf Diskette löschen.
			jsr	DeleteFile

			ClrB	SetColOK		;Farbe wieder anzeigen.
			jsr	SetMenuScreen

			pla
			jsr	LoadHelpPage		;Seite aus GW-Dokument einlesen.
			txa				;Diskettenfehler ?
			beq	:103			;Nein, weiter...
::102			jmp	INV_PAGE

::103			lda	LinesInMem		;Scrollbalken initialisieren.
			sta	MoveBarData +3
			lda	LinePointer
			sta	MoveBarData +5

			LoadW	r0,MoveBarData
			jsr	InitBalken		;Scrollbalken anzeigen.
			jsr	PrintPage 		;Alte Seite wieder einlesen.
			jmp	InitMenu		;Menü-Funktionen wieder aktivieren.

;******************************************************************************
;*** Druckertreiber laden.
;******************************************************************************
:LoadPrinter		jsr	SetOrgCol

			LoadW	r9,HdrB000		;Speicherbereich für Druckertreiber
			ClrB	r10L			;auf Diskette auslagern.
			jsr	SaveFile
			txa				;Diskettenfehler ?
			beq	:101			;Ja, Abbruch.

			LoadW	r0,SysPrnErrBox
			jsr	DoSysDlgBox		;Diskettenfehler anzeigen.
			ldx	#$02
			rts

::101			LoadW	r6,PrntFileName
			LoadW	r7,PRINTBASE
			LoadB	r0L,%00000001
			jsr	GetFile			;Druckertreiber einladen.
			txa
			bne	:102
			rts

::102			pha
			LoadW	r0,HdrFileName		;Swapdatei auf Diskette löschen.
			jsr	DeleteFile
			LoadW	r0,SysPLdErrBox
			jsr	DoSysDlgBox
			pla
			tax
			rts

;******************************************************************************
;*** Druck-Bildschirm aufbauen.
;******************************************************************************
:PrntScreen1		jsr	InitForIO
			LoadB	$d020,$00
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			FillPRec$00,$00,$c7,$0000,$013f

			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36
			jsr	i_ColorBox
			b	$00,$01,$28,$01,$bf
			LoadW	r0,HelpFont		;GeoHelpView-Font aktivieren.
			jmp	LoadCharSet

:PrntScreen2		FillPRec$00,$b8,$c7,$0000,$013f
			LoadW	r0,HelpText02
			jsr	PutString

:PrntCurPage		PrintStrgcurHelpFile
			PrintStrgTextPage

			ldx	curHelpPage
			inx
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;******************************************************************************
;*** Aktuelle Seite drucken.
;******************************************************************************
:DruckStarten		LoadW	r0,HelpText03
			jsr	PutString

			jsr	PrntCurPage
			jsr	Drucke1GZeile		;Zeile drucken.

			ClrW	r3			;Trennzeile drucken.
			LoadW	r4,$013f
			LoadB	r11L,$0b
			lda	#%11111111
			jsr	HorizontalLine
			jsr	Drucke1GZeile		;Zeile drucken.

			lda	LinePointer		;Seitenzeiger sichern.
			pha

			lda	#$00			;Alle Zeilen der Seite auf
::101			cmp	LinesInMem		;Bildschirm ausgeben und drucken.
			bcs	:103
			sta	LinePointer
			jsr	SetLineAdr
			beq	:103

			LoadB	r1H,$0e
			jsr	SetXtoStart
			jsr	PrintLine
			jsr	Drucke1GZeile		;Zeile drucken.

			ldx	pressFlag		;Taste gedrückt ?
			bne	:104			;Ja, Abruch.
::102			lda	LinePointer
			add	1 			;Zeiger auf nächste Zeile.
			bne	:101			;Nächste Zeile drucken.

::103			ldx	#$00

::104			txa
			pha
			jsr	SetzeGAdresse		;Zeiger auf Druckdaten-Speicher.
			jsr	StopPrint		;Ausdruck beenden.
			pla
			tax
			pla
			sta	LinePointer		;Seitenzeiger zurücksetzen.
			rts

;*** Zeiger auf Grafikspeicher richten.
:SetzeGAdresse		LoadW	r0,SCREEN_BASE + 20 * 8
			LoadW	r1,SCREEN_BASE + 40 * 8 * 5
			LoadW	r2,$0000
			rts

;*** Grafikspeicher drucken.
:Drucke1GZeile		jsr	SetzeGAdresse		;Zeiger auf Druckdaten richten
			jsr	PrintBuffer		;Zeile drucken.
			jsr	i_FillRam		;Druckdaten-Speicher löschen.
			w	640
			w	SCREEN_BASE + 20 * 8
			b	$00
			rts

;******************************************************************************
;*** Balken verschieben.
;******************************************************************************
:MoveBar		lda	LinesInMem
			cmp	#21 +1			;Mehr als 21 Zeilen ?
			bcc	:101			;Nein, Ende...

			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:102			;Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:103			;Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:104			;Ja, eine Seite vorwärts.
::101			rts

::102			jmp	LastPage
::103			jmp	MoveToPos
::104			jmp	NextPage

;*** Balken verschieben.
:MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

			lda	LinePointer		;Aktuelle Position merken.
			sta	r15L

::101			jsr	UpdateMouse		;Mausdaten aktualisieren.
			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:102			;Nein, neue Position anzeigen.
			lda	inputData		;Mausbewegung einlesen.
			bne	:104			;Mausbewegung auswerten.
			beq	:101			;Keine Bewegung, Schleife...

::102			ClrB	pressFlag		;Maustastenklick löschen.
			LoadW	r0,V402f2
			jsr	InitRam
			lda	LinePointer
			cmp	r15L
			beq	:103
			jmp	PrintPage		;Position anzeigen.
::103			rts

::104			cmp	#$02			;Maus nach oben ?
			beq	:105			;Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:106			;Ja, auswerten.
			jmp	:101			;Keine Bewegung, Schleife...

::105			jsr	LastLine_a
			bcs	:101			;Geht nicht, Abbruch.
			dec	LinePointer		;Zeiger auf letzte Datei.
			jmp	:107			;Neue Position anzeigen.

::106			jsr	NextLine_a		;Eine Datei vorwärts.
			bcs	:101			;Geht nicht, Abbruch.
			inc	LinePointer		;Zeiger auf nächste Datei.
::107			lda	LinePointer		;Tabellenposition einlesen und
			jsr	SetPosBalken		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:101			;Maus weiter auswerten.

;*** Eine Seite vor.
:NextPage		lda	LinePointer
			add	38
			bcs	:101
			cmp	LinesInMem
			bcc	:103

::101			lda	LinesInMem
			sub	19
			bcc	:102
			cmp	LinePointer
			bne	:104
::102			rts

::103			sub	19
::104			sta	LinePointer
			jmp	NPageAndMse

;*** Eine Seite zurück.
:LastPage		lda	LinePointer
			sub	19
			bcs	:101
			lda	#$00
			cmp	LinePointer
			beq	:102
::101			sta	LinePointer
			jmp	NPageAndMse
::102			rts

;******************************************************************************
;*** Balken initialiseren.
;******************************************************************************
:InitBalken		ldy	#$05			;Paraeter speichern.
::101			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:101

			jsr	Anzeige_Ypos		;Position des Anzeigebalkens berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.

			lda	SB_XPos
			sta	:102 +0
			sta	:103 +0
			sta	:104 +0

			lda	SB_YPos			;Position für "UP"-Icon berechnen.
			sub	8
			sta	:102 +1
			lsr
			lsr
			lsr
			sta	:104 +1

			lda	SB_YPos			;Position für "DOWN"-Icon berechnen.
			adda	SB_MaxYlen
			sta	:103 +1

			lda	SB_MaxYlen
			lsr
			lsr
			lsr
			add	2
			sta	:104 +3

			jsr	i_BitmapUp		;"UP"-Icon ausgeben.
			w	icon_UP
::102			b	$19,$ff,$01,$08

			jsr	i_BitmapUp		;"DOWN"-Icon ausgeben.
			w	icon_DOWN
::103			b	$19,$ff,$01,$08

			jsr	i_ScrBarCol
::104			b	$00,$00,$01,$00

			jmp	PrintBalken		;Balken ausgeben.

;*** Neue Balkenposition defnieren und anzeigen.
:SetPosBalken		sta	SB_PosEntry		;Neue Position Füllbalken setzen.

;*** Balken ausgeben.
:PrintBalken		jsr	Balken_Ypos		;Y-Position für Füllbalken berechnen.

			MoveW	SB_PosTop,r0		;Grafikposition berechnen.
			ClrB	r1L			;Zähler für Balkenlänge löschen.

			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::101			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:104			;Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:103			;Ja, Quer-Linie ausgeben.
			bcc	:104			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:103			;Ja, Quer-Linie ausgeben.
			bcs	:104			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:104			;Ja, Quer-Linie ausgeben.

::102			lda	#%11100111		;Wert für Füllbalken.
			b $2c

::103			lda	#%11111111
			b $2c

::104			lda	#%10000001

::105			sta	(r0L),y			;Byte in Grafikspeicher schreiben.
			inc	r1L
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:106			;Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:101			;Nein, weiter...

			AddVW	320,r0			;Zeiger auf nächstes CARD berechnen.
			ldy	#$00
			beq	:101			;Schleife...

::106			rts				;Ende.

;*** Position des Anzeigebalken berechnen.
:Anzeige_Ypos		MoveB	SB_XPos,r0L
			LoadB	r0H,NULL
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	SCREEN_BASE,r0
			lda	SB_YPos
			lsr
			lsr
			lsr
			tay
			beq	:102
::101			AddVW	40*8,r0
			dey
			bne	:101
::102			MoveW	r0,SB_PosTop
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	#$00
			ldx	SB_MaxEScr
			cpx	SB_MaxEntry
			bcs	:101
			MoveB	SB_MaxYlen,r0L
			MoveB	SB_MaxEScr,r1L
			jsr	Mult_r0r1
			MoveB	SB_MaxEntry,r1L
			jsr	Div_r0r1
			CmpBI	r0L,8
			bcs	:101
			lda	#$08
::101			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		ldx	#NULL
			ldy	SB_Length
			CmpB	SB_MaxEScr,SB_MaxEntry
			bcs	:101

			MoveB	SB_PosEntry,r0L
			lda	SB_MaxYlen
			suba	SB_Length
			sta	r1L
			jsr	Mult_r0r1
			lda	SB_MaxEntry
			suba	SB_MaxEScr
			sta	r1L
			jsr	Div_r0r1
			lda	r0L
			tax
			adda	SB_Length
			tay
::101			stx	SB_Top
			dey
			sty	SB_End
			rts

:Mult_r0r1		ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jmp	BBMult

:Div_r0r1		LoadB	r1H,NULL		;Division durchführen.
			ldx	#r0L
			ldy	#r1L
			jmp	Ddiv

;*** Balken initialiseren.
:ReadSB_Data		ldx	#$0a
::101			lda	SB_XPos,x
			sta	r0L,x
			dex
			bpl	:101
			rts

;*** Mausklick überprüfen.
:IsMseOnPos		lda	mouseYPos
			suba	SB_YPos
			cmp	SB_Top
			bcc	:103
::101			cmp	SB_End
			bcc	:102
			lda	#$03
			b $2c
::102			lda	#$02
			b $2c
::103			lda	#$01
			rts

;*** Mausbewegung kontrollieren.
:StopMouseMove		lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1
			lda	mouseYPos
			jmp	SetNewRelMse
:SetRelMouse		lda	#$ff
			adda	SB_Top
:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			suba	SB_Top
			sta	SetRelMouse+1
			rts
;******************************************************************************
;*** Farbbox zeichnen.
;******************************************************************************
;			jsr	i_ColorBox
;			b	xl,yl,xb,yb,co
.i_BoxCol		ldx	#$02
			b $2c
.i_TxtCol		ldx	#$19
			b $2c
.i_IconCol		ldx	#$04
			b $2c
.i_SysIconCol		ldx	#$05
			b $2c
.i_ClIconCol		ldx	#$06
			b $2c
.i_TitelCol		ldx	#$07
			b $2c
.i_ScrBarCol		ldx	#$08
			b $2c
.i_GeosCol		ldx	#$16
			lda	colSystem,x
:SetColor		sta	r2L
			pla				;Rücksprungadresse sichern.
			sta	returnAddress+0
			pla
			sta	returnAddress+1
			ldy	#$05
			jmp	GetColData

.i_ColorBox		pla				;Rücksprungadresse sichern.
			sta	returnAddress+0
			pla
			sta	returnAddress+1

			ldy	#$06			;Daten einlesen.
:GetColData		sty	:102 +1
			dey
::101			lda	(returnAddress),y
			sta	r0 -1,y
			dey
			bne	:101
			jsr	ColorBox		;Box zeichnen.
			php				;Zurück zur aufrufenden Routine.
::102			lda	#$06
			jmp	DoInlineReturn

.ColorBox		PushW	r3
			LoadW	r3,COLOR_MATRIX

			ldx	r0H
::101			jsr	:110
			bne	:101
			AddB	r0L,r3L
			bcc	:102
			inc	r3H
::102			ldx	r1H
::103			ldy	r1L
			dey
			lda	r2L
::104			sta	(r3L),y
			dey
			bpl	:104
			jsr	:111
			bne	:103
			PopW	r3
			rts

::110			beq	:113
::111			clc
			lda	r3L
			adc	#40
			sta	r3L
			bcc	:112
			inc	r3H
::112			dex
::113			rts

;******************************************************************************
; Funktion		: Neue Partition aktivieren.
; Datum			: 07.07.97
; Aufruf		: JSR  SetNewPart
; Übergabe		: AKKU	Byte Partitions-Nr.
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -Part_ChangeBefehl Partition aktvieren
;			  -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -OpenDisk Diskette öffnen
;			  -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -IsPartOK Partition testen
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;*** Partition auf Laufwerk wechseln.
:SetNewPart		sta	Part_Change+4		;Partitions-Nr. merken.

			jsr	ClrPartInfo		;Partitionsdaten löschen.

			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren.
			jsr	InitForIO		;I/O aktivieren.
			CxSend	Part_Change		;Neue Partition aktivieren.

			lda	#$ff
			sta	Part_GetInfo+5		;Zeiger auf aktuelle Partition.
			CxSend	Part_GetInfo		;Partitions-Informationen einlesen.
			CxReceivePart_Info
			jsr	DoneWithIO		;I/O abschalten.

			jsr	IsPartOK		;Partition testen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			ldx	curDrive
			lda	driveType -8,x
			bpl	:101

			ldx	curDrive		;Startadresse RAM-Partition setzen.
			lda	Part_Info +22
			sta	ramBase    - 8,x
			lda	Part_Info +23
			sta	driveData  + 3

::101			jsr	OpenDisk		;Diskette öffnen.
			ldy	Part_Info + 4
::102			rts

;******************************************************************************
; Funktion		: Aktuelle Partition einlesen.
; Datum			: 05.07.97
; Aufruf		: JSR  GetCurPInfo
; Übergabe		: AKKU	Byte Partitions-Nr.
; Rückgabe		: xReg	Byte $00 = Partition OK
;			  yReg	Byte Partitions-Nr.
;			  Part_InfoDaten Partitions-Informationen
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;******************************************************************************
; Funktion		: Partitionsdaten einlesen.
; Datum			: 04.07.97
; Aufruf		: JSR  GetPartInfo
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Partition OK
;			  yReg	Byte Partitions-Nr.
;			  Part_InfoDaten Partitions-Informationen
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;******************************************************************************
; Funktion		: Neue Partition aktivieren.
; Datum			: 03.07.97
; Aufruf		: JSR  IsPartOK
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Partition OK
;			  yReg	Byte Partitions-Nr.
; Verändert		: AKKU,xReg,yReg
; Variablen		: -Part_InfoDaten Aktuelle Partition
; Routinen		: -
;******************************************************************************

;*** Partition auf Laufwerk wechseln.
:GetCurPInfo		lda	#$ff
:GetPartInfo		sta	Part_GetInfo +5

			jsr	ClrPartInfo		;Partitionsdaten löschen.

			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren.
			jsr	InitForIO		;I/O aktivieren.
			CxSend	Part_GetInfo		;Partitions-Informationen einlesen.
			CxReceivePart_Info
			jsr	DoneWithIO		;I/O abschalten.

:IsPartOK		ldy	Part_Info +4		;Partitions-Nr. einlesen.
			lda	Part_Info +2		;Partitionstyp einlesen.
			beq	Part_NotOK		;Partition vorhanden ? Nein, weiter...
			cmp	#$ff			;System-Partition ?
			bcc	Part_OK			;Nein, weiter...
:Part_NotOK		ldx	#$05			;Partition nicht gefunden.
			b $2c
:Part_OK		ldx	#$00			;Partition OK.
			rts

;******************************************************************************
; Funktion		: Partitions-Informationen löschen.
; Datum			: 05.07.97
; Aufruf		: JSR  ClrPartInfo
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r2
; Variablen		: -Part_InfoDaten Aktuelle Partition
; Routinen		: -i_FillRam Speicherbereich löschen
;******************************************************************************

;*** Neue Partition auf Laufwerk anmelden.
:ClrPartInfo		jsr	i_FillRam
			w	$0020
			w	Part_Info +2
			b	$00
			rts

;******************************************************************************
; Funktion		: Befehl an Floppy senden.
; Datum			: 04.07.97
; Aufruf		: JSR  SendCom_a
; Übergabe		: AKKU,xRegWord Zeiger auf Befehl
;				 w (Anzahl Bytes)
;				 b Befehlsbytes
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r14 und r15
; Variablen		: -
; Routinen		: -SECONDSekundär-Adresse nach LISTEN senden.
;			  -CIOUTByte-Ausgabe auf IEC-Bus.
;			  -UNLSNUNLISTEN-Signal auf IEC-Bus senden.
;			  -LISTENLISTEN-Signal auf IEC-Bus senden.
;******************************************************************************

;******************************************************************************
; Funktion		: Daten von Floppy empfangen.
; Datum			: 04.07.97
; Aufruf		: JSR  GetCom_a
; Übergabe		: AKKU,xRegWord Zeiger auf Befehl
;				 w (Anzahl Bytes)
;				 b Speicherbytes
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r14 und r15
; Variablen		: -
; Routinen		: -TKSA	Sekundär-Adresse nach TALK senden.
;			  -ACPTRByte-Eingabe vom IEC-Bus.
;			  -UNTALKUNTALK-Signal auf IEC-Bus senden.
;			  -TALK	TALK-Signal auf IEC-Bus senden.
;******************************************************************************

;*** Daten an Floppy senden.
:SendCom_a		sta	r15L
			stx	r15H
:SendCom_b		ClrB	STATUS			;Status löschen.
			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			lda	Drive_Adress
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff
			jsr	SECOND			;Sekundär-Adresse nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...
			jsr	ComInit			;Zähler für Anzahl Bytes einlesen.
			jmp	:102

::101			lda	(r15L),y		;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:102
			inc	r15H
::102			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:101			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts
::103			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Daten von Floppy empfangen.
:GetCom_a		sta	r15L
			stx	r15H
:GetCom_b		ClrB	STATUS			;Status löschen.
			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			lda	Drive_Adress
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			lda	#$ff
			jsr	TKSA			;Sekundär-Adresse nach TALK senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...
			jsr	ComInit			;Zähler für Anzahl Bytes einlesen.
			jmp	:102

::101			jsr	ACPTR			;Byte einlesen und in
			sta	(r15L),y		;Speicher schreiben.
			iny
			bne	:102
			inc	r15H
::102			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:101

			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts
::103			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Zeiger auf Befehl initialisieren.
:ComInit		ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r15L),y
			sta	r14H
			dey
			lda	(r15L),y
			sta	r14L
			AddVBW	2,r15
			rts

;******************************************************************************
; Funktion		: Auf CMD-Gerät testen.
; Datum			: 04.07.97
; Aufruf		: JSR  GetCMD_Code
; Übergabe		: -
; Rückgabe		: yReg	Byte Geräte-Typ (R,H,F)
;			  xReg	Byte $00 = CMD-Gerät
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -
; Routinen		: -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;******************************************************************************

:GetCMD_Code		jsr	PurgeTurbo
			jsr	InitForIO

			CxSend	Code_GetCMD
			CxReceiveCode_GetInfo

			jsr	DoneWithIO

			ldy	#$02
::101			lda	Code_CMD       ,y
			cmp	Code_GetInfo +2,y
			bne	:103
			dey
			bpl	:101

			ldy	Code_GetInfo +6
			ldx	#$00
			rts

::103			ldx	#$0d
			rts

;*** Rücksprungadresse sichern.
:ExitToRoutine		w $0000
:BackToDA		w $0000
:VLIR_Open		b $00
:GW_DokVersion		b $00

:Flag_SetDrive		b $00
:Flag_SetPart		b $00
:Drive_Start		b $00
:Drive_Adress		b $00
:Drive_Help		b $00
:Drive_SPart		b $00
:Drive_RPart		b $00,$00
:Drive_HPart		b $00
:Drive_Types		b "ABCDFHR"

;*** Partitions-Befehle.
:Part_Change		b $04,$00, 67,208,$00,$0d
:Part_GetInfo		b $05,$00, "G-P" ,$00,$0d
:Part_Info		w $001f
			s 32

:Code_CMD		b "CMD"
:Code_GetCMD		b $06,$00, "M-R",$a0,$fe,$06
:Code_GetInfo		w $0006
			s $07

;*** Daten für Scrollbalken.
:MoveBarData		b $27,$30,$88,$00,$13,$00

;*** Daten für Mausabfrage.
:V402f1			b $28,$2f
			w $0138,$013f,LastLine
			b $b8,$bf
			w $0138,$013f,NextLine
			b $30,$b7
			w $0137,$013f,MoveBar
			b $28,$bf
			w $0008,$012f,ExecuteLink

;*** Maus-Fenstergrenzen.
:V402f2			w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

;*** Systemfarben.
:colSystem
:C_Back			b $05				;Hintergrund.
:C_NoGrafx		b $55				;Hintergrund ohne Vordergrund!
:C_DlgBox		b $0f				;Dialogbox.
:C_TxtBox		b $0d				;Textfenster.
:C_Icon			b $0d				;Icons.
:C_SysIcon		b $0d				;System-Icons.
:C_ClIcon		b $01				;Close-Icon.
:C_Titel		b $12				;Titel-Zeile.
:C_Balken		b $03				;Scrollbalken.
:C_Register		b $16				;Karteikarten.
:C_Bubble		b $07				;Bubble-Farbe.
:C_Mouse		b $06				;Mausfarbe.
:C_DClIcon		b $01				;Dialogbox: Close-Icon.
:C_DTitel		b $12				;Dialogbox: Titel.
:C_DBoxCol		b $0f				;Dialogbox: Hintergrund + Text.
:C_DSysIcon		b $01				;Dialogbox: System-Icons.
:C_InfoBox		b $03				;Infobox  : Hintergrund + Text.
:C_FClIcon		b $01				;Dialogbox: Close-Icon.
:C_FTitel		b $12				;Dateiauswahlbox: Titel.
:C_FBoxCol		b $0f				;Dateiauswahlbox: Hintergrund + Text.
:C_FSysIcon		b $01				;Dateiauswahlbox: System-Icons.
:C_MenuIcon		b $01				;Icons Hauptmenü.
:C_GEOS_BACK		b $bf				;Hintergrund: Farbe GEOS-Standard-Applikationen.
:C_GEOS_FRAME		b $00				;Rahmen     : Farbe GEOS-Standard-Applikationen.
:C_GEOS_MOUSE		b $06				;Mauszeiger : Farbe GEOS-Standard-Applikationen.
:EndColors

:C_HelpWin		b $b1				;Hilfefenster.
:C_HelpBack		b $01
:C_Hinweis		b $20				;Farbe für Überschriften.
:C_Seite		b $50				;Farbe für Querverweise.

:B_GEOS_BACK		b $bf				;Hintergrund: Farbe GEOS-Standard-Applikationen.
:B_GEOS_FRAME		b $00				;Rahmen     : Farbe GEOS-Standard-Applikationen.
:B_GEOS_MOUSE		b $06				;Mauszeiger : Farbe GEOS-Standard-Applikationen.

;*** Name der Farbdatei.
:ColFileName		b "COLOR.INI",NULL

if Sprache = Deutsch
;*** Texte für Bildaufbau.
:HelpText01		b GOTOXY
			w $0008
			b $06
			b PLAINTEXT
			b "Hilfesystem",NULL

:HelpText02		b GOTOXY
			w $0010
			b $c2
			b PLAINTEXT
			b "Seite wird gedruckt... ",NULL

:HelpText03		b GOTOXY
			w $0000
			b $0e
			b PLAINTEXT
			b "Hilfesystem: ",NULL

:TextPage		b GOTOX
			w $0100
			b "Seite: ",NULL

:UsedMem		b $00				;Belegter Speicher in Prozent.
:UsedMemTxt		b GOTOX
			w $0080
			b "Speicher: ",NULL
endif

if Sprache = Englisch
;*** Texte für Bildaufbau.
:HelpText01		b GOTOXY
			w $0008
			b $06
			b PLAINTEXT
			b "Helpsystem",NULL

:HelpText02		b GOTOXY
			w $0010
			b $c2
			b PLAINTEXT
			b "Page would be printed... ",NULL

:HelpText03		b GOTOXY
			w $0000
			b $0e
			b PLAINTEXT
			b "Helpsystem : ",NULL

:TextPage		b GOTOX
			w $0100
			b "Page: ",NULL

:UsedMem		b $00				;Belegter Speicher in Prozent.
:UsedMemTxt		b GOTOX
			w $0080
			b "Memory: ",NULL
endif

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
			b "Fehler im GeoHelpView",NULL
::102			b "Hauptprogramm !",NULL

;*** Dialogbox für Hilfedatei-Fehler.
:SysPrnErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Fehler beim erzeugen",NULL
::102			b "der Auslagerungsdatei !",NULL

;*** Dialogbox für Hilfedatei-Fehler.
:SysPLdErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Fehler beim einlesen",NULL
::102			b "des Druckertreibers !",NULL

;*** Datei nicht verfügbar.
:FileNotFound		b CR,CR
			b "`2Fehler `: `361Datei nicht gefunden!",CR
:FNF_1			b "`2Datei  `: `3b1"
:FNF_1a			b "________________",CR,CR,CR,CR
			b "`2*** ENDE ***",CR,NULL

;*** Seite nicht verfügbar.
:PageNotFound		b CR,CR
			b "`2Fehler `: `361Seite nicht verfügbar!",CR
:PNF_1			b "`2Datei  `: `3b1"
:PNF_1a			b "________________",CR
:PNF_2			b "`2Seite  `: `3b1"
:PNF_2a			b "__",CR,CR,CR,CR
			b "`2*** ENDE ***",CR,NULL

;*** Seite nicht verfügbar.
:DrvNotFound		b CR,CR
			b "`2Fehler `: `361Das angegebene Laufwerk oder die",CR
			b "         `361CMD-Partition ist nicht verfügbar!",CR,CR
:DNF_1			b "`2Laufwerk/Partition `: `3b1"
:DNF_1a			b "________________",CR
			b CR,CR,CR
			b "`2*** ENDE ***",CR,NULL

;*** Seite nicht verfügbar.
:FormatError		b CR,CR
			b "`2Fehler `: `361Falsches Text-Format!",CR
:FE_1			b "`2Datei  `: `3b1"
:FE_1a			b "________________",CR,CR
			b "Format V2.0 oder höher wird benötigt!",CR,CR,CR,CR
			b "`2*** ENDE ***",CR,NULL
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
			b "Fatal error:",NULL
::102			b "Corrupt GeoHelpView !",NULL

;*** Dialogbox für Hilfedatei-Fehler.
:SysPrnErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Fatal error:",NULL
::102			b "Creating SwapFile !",NULL

;*** Dialogbox für Hilfedatei-Fehler.
:SysPLdErrBox		b $81
			b DBTXTSTR, 16,20
			w :101
			b DBTXTSTR, 16,32
			w :102
			b OK      , 16,72
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Fatal error:",NULL
::102			b "Load print-driver !",NULL

;*** Datei nicht verfügbar.
:FileNotFound		b CR,CR
			b "`2Error `: `361File not found!",CR
:FNF_1			b "`2File  `: `3b1"
:FNF_1a			b "________________",CR,CR,CR,CR
			b "`2*** END ***",CR,NULL

;*** Seite nicht verfügbar.
:PageNotFound		b CR,CR
			b "`2Error `: `361Page not available!",CR
:PNF_1			b "`2File  `: `3b1"
:PNF_1a			b "________________",CR
:PNF_2			b "`2Page  `: `3b1"
:PNF_2a			b "__",CR,CR,CR,CR
			b "`2*** END ***",CR,NULL

;*** Seite nicht verfügbar.
:DrvNotFound		b CR,CR
			b "`2Error `: `361The defined drive or partition",CR
			b "        `361is not available!",CR,CR
:DNF_1			b "`2Drive/Partition `: `3b1"
:DNF_1a			b "________________",CR
			b CR,CR,CR
			b "`2*** END ***",CR,NULL

;*** Seite nicht verfügbar.
:FormatError		b CR,CR
			b "`2Error `: `361Illegal text-format!",CR
:FE_1			b "`2File  `: `3b1"
:FE_1a			b "________________",CR,CR
			b "Version 2.x or higher is required!",CR,CR,CR,CR
			b "`2*** END ***",CR,NULL
endif

;*** Infoblock für SWAP-Datei.
:HdrB000		w HdrFileName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b TEMPORARY
			b SEQUENTIAL
			w $7900
			w $8000
			w $0000
			b "GD_PrntData V"		;Klasse.
			b "1.0"				;Version.
			s $04				;Reserviert.
			b "GHV"				;Autor.
:HdrEnd			s (HdrB000+256)-HdrEnd

;*** Dateiname für SWAP-File.
:HdrFileName		b "GD_PrntData",NULL

;*** Icon-Menü.
:icon_Tab1		b $08
			w $0000
			b $00

			w icon_01
			b $00,$08,$05,$18
			w ExitHelp

			w icon_03
			b $05,$08,$05,$18
			w FindMainHelp

			w icon_02
			b $0a,$08,$05,$18
			w GotoIndex

			w icon_04
			b $0f,$08,$05,$18
			w LastHelpPage

			w icon_05
			b $14,$08,$05,$18
			w NextHelpPage

			w icon_08
			b $19,$08,$05,$18
			w CallLastPage

			w icon_06
			b $1e,$08,$05,$18
			w PrintHelpPage

			w icon_07
			b $23,$08,$05,$18
			w PrintAllHelp

;*** Icons.
:icon_UP
<MISSING_IMAGE_DATA>

:icon_DOWN
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:icon_01
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_01
<MISSING_IMAGE_DATA>
endif

:icon_02
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:icon_03
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_03
<MISSING_IMAGE_DATA>
endif

:icon_04
<MISSING_IMAGE_DATA>

:icon_05
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
:icon_06
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_06
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:icon_07
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_07
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:icon_08
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:icon_08
<MISSING_IMAGE_DATA>
endif

;*** Hilfedatei suchen.
:FindMainHelp		jsr	CopyStdName		;Name in Zwischenspeicher.

			lda	#$00			;Titel-Seite lesen.
			b $2c

;*** Indexseite der aktuellen Hilfedatei.
:GotoIndex		lda	#$01			;Index-Seite lesen.

			ldx	#$00			;Zeiger auf Zeile 1 richten.
			stx	LinePointer		;(Seitenanfang anzeigen).

;*** Neue Seite aktivieren.
;    Seiten-Nr. im AKKU.
:GotoNewPage

;*** Neue Seite anzeigen.
;    Seiten-Nr. im AKKU.
:ShowNewPage		jsr	LoadPage		;Seite aus datei einlesen.
			txa				;Diskettenfehler ?
			bne	INV_PAGE		;Ja, "Page not found" ausgeben.
			jmp	PrintPage		;Zum Anfang der Seite/ausgeben.
:INV_PAGE		jmp	GHV_FileErr

;*** Letzte Hilfeseite öffnen.
:LastHelpPage		lda	curHelpPage		;Seitenzeiger einlesen.

::101			sub	1			;Seitenzahl -1.
			bcs	:102			;Noch im erlaubten Bereich ?
			lda	#60			;Nein, letzte, mögliche Seite lesen.

::102			pha				;Seitenzeiger merken.
			jsr	PointRecord		;Seite aufrufen.
			pla				;Seitenzeiger einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.
			cpy	#$00			;Seite verfügbar ?
			beq	:101			;Nein, eine Seite zurück...

			stx	LinePointer		;Zeiger auf Anfang der Seite.
			jmp	ShowNewPage		;Neue Seite anzeigen.

::103			jmp	GHV_FileErr		;Dateifehler ausgeben.

;*** Nächste Hilfeseite öffnen.
:NextHelpPage		lda	curHelpPage		;Seitenzeiger einlesen.

::101			add	1			;Seitenzahl +1.
			cmp	#61
			bcc	:102			;Noch im erlaubten Bereich ?
			lda	#0			;Nein, auf Seite 1.

::102			pha				;Seitenzeiger merken.
			jsr	PointRecord		;Seite aufrufen.
			pla				;Seitenzeiger einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.
			cpy	#$00			;Seite verfügbar ?
			beq	:101			;Nein, eine Seite zurück...

			stx	LinePointer		;Zeiger auf Anfang der Seite.
			jmp	ShowNewPage		;Neue Seite anzeigen.

::103			jmp	GHV_FileErr		;Dateifehler ausgeben.

;*** Name der Startdatei in Zwischenspeicher.
:CopyStdName		ldy	#$0f			;Name der Titel-Hilfedatei in
::101			lda	Help001,y		;Zwischenspeicher kopieren.
			sta	NewHelpFile,y
			dey
			bpl	:101
			rts

;******************************************************************************
;*** Neue Seite initialisieren.
;*** - Textseite einlesen,
;*** - Rollbalken initialisieren,
;*** - Seite in Seitenspeicher kopieren,
;******************************************************************************
:LoadPage		jsr	LoadHelpPage		;Seite aus GW-Dokument einlesen.
			txa				;Diskettenfehler ?
			beq	LoadPageData		;Nein, weiter...
			rts

:LoadPageData		lda	LinesInMem		;Scrollbalken initialisieren.
			sta	MoveBarData +3
			lda	LinePointer
			sta	MoveBarData +5

			jsr	PageInBuffer		;Aktuelle Seite in Stackspeicher.

			LoadW	r0,MoveBarData
			jsr	InitBalken		;Scrollbalken anzeigen.
			ldx	#$00			;Kein Fehler, OK.
			rts

;******************************************************************************
;*** Textseite aus der Hilfedatei einlesen.
;******************************************************************************
:LoadHelpPage		sta	curHelpPage		;Nr. der Seite merken.

			jsr	i_FillRam		;Speicher für Hilfe-Seite löschen.
			w	TxtBufSize
			w	HelpTextMem
			b	$00

			jsr	i_FillRam
			w	(PageData_End - PageData_Start)
			w	PageData_Start
			b	$00

			LoadW	r6,NewHelpFile		;Name der neuen Hilfedatei merken.
			LoadW	r7,curHelpFile
			ldx	#r6L
			ldy	#r7L
			jsr	CopyString		;Name in Zwischenspeicher kopieren.
			jsr	FindFile		;Hilfedatei auf Diskette suchen.
			txa				;Diskettenfehler ?
			beq	:102			;Ja, Abbruch...
::101			rts

::102			lda	dirEntryBuf +19		;Textformat ermitteln.
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:101

			lda	diskBlkBuf +$5a
			cmp	#"2"
			bne	:103
			lda	diskBlkBuf +$5c
			sec
			sbc	#$30
			sta	GW_DokVersion

			LoadW	r0,NewHelpFile
			jsr	OpenRecordFile		;Hilfedatei öffnen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch...

			lda	curHelpPage		;Zeiger auf Seite.
			jsr	PointRecord
			cpx	#$00			;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.
			cpy	#$00			;Seite verfügbar ?
			bne	:104			;Ja, weiter...
::103			jsr	CloseRecordFile
			ldx	#$08			;Fehler: "Invalid Record".
			rts

::104			LoadW	r7,LoadAdress
			LoadW	r2,TxtBufSize
			jsr	ReadRecord		;Seite einlesen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.

			jsr	CloseRecordFile

;*** Seiteninformationen einlesen.
:InitPageData		jsr	CheckIcons		;Icondaten einlesen.
			jsr	ConvertPage		;Textseite konvertieren.

			lda	r1L			;Endadresse akt. Seite merken.
			sta	StartGoto   +0
			sta	StartIcon   +0
			sta	StartFreeMem+0
			lda	r1H
			sta	StartGoto   +1
			sta	StartIcon   +1
			sta	StartFreeMem+1

			jsr	GetPageInfo		;Seiteninformationen einlesen.
			jsr	GetUsedMem		;Speicherauslastung berechnen.

			ldx	#$00			;Kein Fehler...
			rts

;*** Icondaten suchen.
;Beim konvertieren der Seite in das
;GHV-Format benötigt das Programm die
;Angaben über die Breite der auf der
;Seite enthaltenen Icons. Diese werden
;hier vorab eingelesen.
:CheckIcons		LoadW	r0,LoadAdress		;Zeiger auf Startadresse richten.
			LoadW	r1,IconAdrTab		;Zwischenspeicher für Icon-Daten.

::101			ldy	#$00
			lda	(r0L),y			;Zeichen einlesen.
			cmp	#NULL			;Ende erreicht ?
			beq	:102			;Ja, Ende.
			cmp	#PAGE_BREAK		;Ende erreicht ?
			bne	:106			;Nein, weiter...
::102			rts				;Ende.

::103			ldx	#$01			;Zeiger auf nächstes Zeichen.
::104			txa				;Anz. Zeichen in xReg überspringen.
			jsr	AddAto_r0
			jmp	:101			;Nächstes Zeichen einlesen.

::106			ldx	#$04
			cmp	#NEWCARDSET		;Steuercode ?
			beq	:104			;Ja, überspringen.
			ldx	#$1b
			cmp	#ESC_RULER		;Steuercode ?
			beq	:104			;Ja, überspringen.
			ldx	#$01
			cmp	#FORWARDSPACE		;Steuercode ?
			beq	:104			;Ja, überspringen.
			cmp	#ESC_GRAPHICS		;Steuercode ?
			bne	:103			;Nein, Zeichen übergehen.

			iny
			lda	(r0L),y			;Breite des Icons einlesen.
			dey
			sta	(r1L),y			;Breite in Tabelle eintragen.
			IncWord	r1			;Speicherzeiger korrigieren.

			ldx	#$05			;Steuercode übergehen.
			jmp	:104

;*** Seite konvertieren.
;Um das Anzeigen der Textseite zu
;vereinfachen, werden die GeoWrite-
;Steuercodes umgewandelt:

;GHV-Steuercode		Bytefolge
;--------------------------------------
;Tabulator		b $F1, xPos in Pixel									(Word!)
;Linkverweis		b $F2, Nr, Seite									(Nr = Tabelleneintrag, Seite = 1,2...)
;Titel erzeugen		b $F3
;Farbe setzen		b $F4, Farbe(Byte wie in COLOR_MATRIX)
;Grafik zeigen		b $F5, Nr, Zeile									(Nr = Tabelleneintrag, Zeile = 0,1...)
;Ende Link/Farbe	b $F6
;Blockende		b $FF
;Textende		b $00
;--------------------------------------
;
;Die Textseite wird dabei umkopiert,
;von der Ladeadresse in den Text-
;Speicher. Notwendig da auch Zeichen
;eingefügt werden müssen und damit
;die Länge des Textes verändert wird.
;
;Um die Tabulator-Positionen zu be-
;stimmen, wird die Zeile berechnet.

:ConvertPage		lda	#<LoadAdress		;Zeiger auf Ladeadresse.
			sta	r0L
			lda	#>LoadAdress
			sta	r0H
			lda	#<HelpTextMem		;Zeiger auf Anfang Textspeicher.
			sta	r1L
			lda	#>HelpTextMem
			sta	r1H

			lda	#$00
			sta	r10H			;Anzahl Links/Text.
			sta	SetGHVcode		;GHV-Code erzeugen.

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

:ConvNextByte		ldy	#$00
			lda	(r0L),y			;Zeichen aus Speicher einlesen.
			cmp	#" "			;Steuercode ?
			bcc	TestEndPage		;Ja, auswerten.

			cmp	#"`"			;GHV-Steuercode ?
			bne	:101			;Nein, weiter...
			jmp	MakeGHVcode		;GHV-Code erzeugen.

::101			cmp	#"§"			;Blockende ?
			bne	WrCharByte		;Nein, weiter...
			jmp	MakeEndBlock		;Blockende-Code erzeugen.

:WrCharByte		pha				;Zeichen merken.
			jsr	GetCharWidth		;Zeichenbreite ermitteln.
			jsr	AddAto_r11		;Breite zu X-Koordinate addieren.
			pla				;Zeichen wieder einlesen.

:WriteByte		jsr	StoreByte		;Aktuelles Byte in Textspeicher.
			lda	#$01			;Zeiger auf nächstes Zeichen.
:PosNextByte		jsr	AddAto_r0
			jmp	ConvNextByte

;*** GeoWrite-Steuercode auswerten.
:TestEndPage		cmp	#NULL			;Ende erreicht ?
			beq	:101			;Ja, weiter...
			cmp	#PAGE_BREAK		;Ende erreicht ?
			bne	TestGWcode		;Nein, weitertesten.
::101			lda	#$00			;Textende markieren.
			jsr	StoreByte
::102			rts

;*** GeoWrite-Steuercode auswerten.
:TestGWcode		cmp	#NEWCARDSET		;Steuercode ?
			bne	:311			;Nein, weter...
			jmp	MakeStyle		;Code ignorieren.

::311			cmp	#FORWARDSPACE		;Steuercode ?
			bne	:321			;Nein, weter...
			jmp	MakeTab			;Tabulator erzeugen.

::321			cmp	#CR			;Steuercode ?
			bne	:331			;Nein, weter...
			jmp	MakeEOL			;Zeilenende erzeugen.

::331			cmp	#ESC_RULER		;Steuercode ?
			bne	:341			;Nein, weter...
			jmp	MakeTabData		;Tabulatordaten einlesen.

::341			cmp	#ESC_GRAPHICS		;Steuercode ?
			bne	:351			;Nein, weter...
			jmp	MakeGrafxData		;Grafikdaten einlesen.

::351			jmp	WrCharByte		;Zeichen übertragen.

;*** Byte in Zielseite übertragen.
:StoreByte		ldy	#$00
			sta	(r1L),y
			IncWord	r1
			rts

;*** GHV-Codes erzeugen.
;Bestimmt Codes werden nur erzeugt,
;wenn SetGHVcode = $00 ist. Diese Wert
;wird auf $FF gesetzt, nachdem das 1te
;Blockende-Kennzeichen gefunden wurde.
;Im restlichen Textbereich werden keine
;Steuercodes mehr benötigt.

;*** Stilart erzeugen.
:MakeStyle		lda	#$04			;4 Byte überlesen.
			jmp	PosNextByte

;*** Tabulator erzeugen.
:MakeTab		bit	SetGHVcode		;GHV-Codes erzeugen ?
			bmi	:101			;Nein, Steuercode ignorieren.

			lda	#$f1
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.
			jsr	SetTabPos		;Neue X-Koordinate bestimmen.

			lda	r11L			;X-Koordinate direkt hinter
			jsr	StoreByte		;Steuercode zwischenspeichern.
			lda	r11H
			jsr	StoreByte

::101			lda	#$01			;1 Byte überlesen.
			jmp	PosNextByte

;*** Zeilenende kennzeichnen.
:MakeEOL		jsr	StoreByte		;Zeilenende in Speicher übertragen.

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

			lda	#$01			;1 Byte überlesen.
			jmp	PosNextByte

;*** Tabulator-Positionen speichern.
:MakeTabData		bit	SetGHVcode		;GHV-Codes erzeugen ?
			bmi	:102			;Nein, Steuercode ignorieren.

			ldy	#26			;Seiteninformationen in
::101			lda	(r0L),y			;Zwischenspeicher kopieren.
			sta	RulerData,y
			dey
			bpl	:101

			lda	RulerData +21
			ora	RulerData +22
			bne	:103

::102			lda	#$1b			;27 Bytes überlesen.
			jmp	PosNextByte

::103			ldy	#$00
::104			lda	RulerData + 1,y
			sec
			sbc	RulerData +21
			sta	RulerData + 1,y
			lda	RulerData + 2,y
			sbc	RulerData +22
			sta	RulerData + 2,y
			iny
			iny
			cpy	#21
			bcc	:104
			jmp	:102

;*** Grafikcode erzeugen.
:MakeGrafxData		ldx	#$00			;Steuercode "ESC_GRAPHICS"
::101			txa				;unverändert übernehmen.
			tay
			lda	(r0L),y
			jsr	StoreByte
			inx
			cpx	#$05
			bne	:101

			lda	#$05			;5 Bytes überlesen.
			jmp	PosNextByte

;*** Blockende kennzeichnen.
:MakeEndBlock		ldy	#$01			;Auf Blockende testen.
			cmp	(r0L),y			;(3x § - Zeichen ohne Leerzeichen!)
			bne	:101
			iny
			cmp	(r0L),y
			beq	:102
::101			jmp	WrCharByte		;Nicht gefunden, speichern.

::102			lda	#$ff
			sta	SetGHVcode
			jsr	StoreByte		;GHV-Code "Blockende" übertragen.

			lda	#$03			;3 Bytes überlesen.
			jmp	PosNextByte

;*** Tabulatorposition setzen.
:SetTabPos		SubVW	8,r11

			ldy	#$06			;Ersten Tabulator suchen, der
::101			lda	RulerData,y		;größer ist als aktuelle Cursorpos.
			dey
			cmp	r11H
			bne	:102
			lda	RulerData,y
			cmp	r11L
::102			beq	:103
			bcs	:104
::103			iny
			iny
			iny
			cpy	#$15
			bne	:101
			AddVW	8,r11
			rts

::104			lda	RulerData+0,y		;Tabulator gesetzt (Nicht der Fall,
			ldx	RulerData+1,y		;wenn der Wert dem für den rechten
			cmp	RulerData+3		;Rand entspricht!)
			bne	:105
			cpx	RulerData+4
			beq	:106
::105			sta	r11L			;Neue Cursor-Position setzen.
			stx	r11H
::106			AddVW	8,r11
			rts

;*** Breite von Icon zu X-Koordinate addieren.
:SetGrafxEnd		tax
			dex
			lda	IconAdrTab,x		;Iconbreite einlesen.
			pha
			jsr	MoveToCard		;Cursor auf nächstes CARD.
			jsr	PixelToCard		;Pixel nach CARD umrechnen.
			stx	r11L
			ClrB	r11H
			pla
			jsr	AddAto_r11
			jmp	CardToPixel		;CARD nach Pixel umrechnen.

;******************************************************************************
;*** Startadressen der Zeile berechnen.
;******************************************************************************
:GetPageInfo		jsr	i_FillRam		;Speicher für Zeilenadr. löschen.
			w	512
			w	LineStartAdr
			b	$00

			lda	#$00
			sta	LinesInMem		;Anzahl Zeilen im Speicher löschen.

			LoadW	r0,HelpTextMem		;Zeiger auf Textanfang.
			LoadW	r1,LineStartAdr		;Zeiger auf Zeilenadressen.

;*** Neue Zeile beginnen.
::100			MoveW	r0,r2			;Anfang akt. Zeile merken.

;*** Nächstes Zeilenende suchen.
::101			ldy	#$00
			lda	(r0L),y			;Zeichen aus Speicher einlesen.
			bmi	:201			;GHV-Steuercode ? Ja, weiter...
			cmp	#" "			;GeoWrite-Steuercode ?
			bcc	:111			;Ja, auswerten.
::102			lda	#$01			;Zeiger auf nächstes Zeichen.
::103			jsr	AddAto_r0
			jmp	:101			;Weitertesten.

;*** "NULL" oder "CR"-Code gefunden.
::111			cmp	#NULL			;Seitenende erreicht ?
			beq	:121			;Ja, weiter...

			jsr	:112			;Zeilenanfang in Tabelle übertragen.
			IncWord	r0			;Zeiger auf nächstes Zeichen.

			jmp	:100			;Neue Zeile testen.

::112			ldy	#$00			;Anfang der Aktuellen Zeile in
			lda	r2L			;Zeilenspeicher übertragen.
			sta	(r1L),y
			iny
			lda	r2H
			sta	(r1L),y
			AddVBW	2,r1
			inc	LinesInMem		;Zeiger auf nächsten Eintrag.
			rts

;*** Seitenende erreicht.
::121			jsr	:112			;Zeilenanfang in Tabelle übertragen.
			ldx	#$00			;Kein Fehler, OK.
			rts

;*** GHV-Code gefunden.
::201			jsr	GetCodeLen		;Länge des GHV-Codes ermitteln.
			cpx	#$00			;Gültiger Code ?
			bne	:202			;Ja, weiter...
			jmp	:102			;Zeichen unverändert übernehmen.

::202			cmp	#$ff			;Blockende erreicht ?
			beq	:203			;Ja, weiter...
			txa				;GHV-Code überlesen.
			jmp	:103

::203			jmp	GetLinkAdr		;Linkverweise prüfen.

;*** Codelänge ermitteln.
:GetCodeLen		ldx	#$01			;GHV-Codes mit ein Byte Länge.
			cmp	#$f3
			beq	:211
			cmp	#$f6
			beq	:211
			cmp	#$ff
			beq	:211
			inx				;GHV-Codes mit zwei Byte Länge.
			cmp	#$f2
			beq	:211
			cmp	#$f4
			beq	:211
			inx				;GHV-Codes mit drei Byte Länge.
			cmp	#$f1
			beq	:211
			cmp	#$f5
			beq	:211
			ldx	#$00			;GHV-Codes nicht erkannt.
::211			rts

;*** Linktabelle erzeugen.
:GetLinkAdr		IncWord	r0

			lda	r0L			;Blockende erreicht, Adresse für
			sta	StartGoto+0		;Querverweise merken.
			lda	r0H
			sta	StartGoto+1

::101			ldy	#$00
			lda	(r0L),y			;Zeichen aus Text einlesen.
			bne	:102			;Ende erreicht ? Nein, weiter...
			tax				;Ja, $00 = Kein Fehler.
			rts

::102			cmp	#$ff			;Blockende erreicht ?
			beq	GetGrfxAdr		;Ja, Icondaten einlesen.

			IncWord	r0			;Zeiger auf nächstes Zeichen.
			jmp	:101

;*** Scraptabelle erzeugen.
;GeoHelpView holt alle Scraps der
;direkt in den Speicher damit diese
;später direkt angezeigt werden können.
:GetGrfxAdr		IncWord	r0

			lda	r0L			;Blockende erreicht, Adresse für
			sta	r14L			;Icondaten merken.
			sta	StartIcon+0
			lda	r0H
			sta	r14H
			sta	StartIcon+1

			ldx	#$00			;Zeiger auf Speicher für Icon-
			stx	r15L			;grafiken im Speicher berechnen.
			stx	StartFreeMem+0
			ldx	StartFreeMem+1
			inx
			stx	r15H
			stx	StartFreeMem+1

			ClrB	r13H			;Anzahl Icons = NULL.

::101			ldy	#$00
			lda	(r14L),y		;Zeichen aus Text einlesen.
			beq	:102			;Seitenende ? Ja, Ende.
			cmp	#$ff			;Blockende = Seitenende erreicht ?
			bne	:103			;Nein, weiter...
::102			ldx	#$00			;$00 = Kein Fehler.
			rts

::103			cmp	#ESC_GRAPHICS		;Photoscrap-Eintrag gefunden ?
			beq	:201			;Ja, weiter...

::104			IncWord	r14			;Zeiger auf nächstes Zeichn.
			jmp	:101

;*** Photoscrap gefunden, einlesen.
::201			lda	r13H 			;Startadresse für Grafik in Tabelle.
			asl
			tax
			lda	r15L
			sta	IconAdrTab+0,x
			lda	r15H
			sta	IconAdrTab+1,x

			ldy	#$04			;Zeiger auf Scrap-Datensatz.
			lda	(r14L),y
			jsr	PointRecord

			MoveW	r15,r7			;Startadresse für ":ReadRecord".

			sec				;Max. Länge für ":ReadBytes"
			lda	#<EndMemory
			sbc	r15L
			sta	r2L
			lda	#>EndMemory
			sbc	r15H
			sta	r2H

			jsr	ReadRecord		;Scrap einlesen.

			ldx	r7H			;Adresse für nächstes Photoscrap
			inx				;berechnen.
			stx	r15H
			stx	StartFreeMem+1

;*** Nächstes Iconlabel suchen.
::110			ldx	r15H
			cpx	#>EndMemory		;Speicher voll ?
			bcs	:111			;Ja, Abbruch.

			inc	r13H
			CmpBI	r13H,64			;Max. Photoscrap #64 erreicht ?
			beq	:111			;Ja, Ende...

			AddVBW	5,r14
			jmp	:101			;Nächstes Photoscrap suchen.

::111			ldx	#$00			;$00 = Kein Fehler.
			rts

;*** Datenspeicher.
;    Wird durch $00-Bytes vorbelegt.
:Variablen

;*** Zwischenspeicher für Systemwerte.
:b_dispBufferOn		b $00
:b_StringFaultVec	w $0000
:b_rightMargin		w $0000
:b_otherPressVec	w $0000
:b_RecoverVector	w $0000
:b_FrameColor		b $00
:b_MouseColor		b $00

;*** Variablen für Scrollbalken.
:SB_XPos		b $00
:SB_YPos		b $00
:SB_MaxYlen		b $00
:SB_MaxEntry		b $00
:SB_MaxEScr		b $00
:SB_PosEntry		b $00

:SB_PosTop		w $0000
:SB_Top			b $00
:SB_End			b $00
:SB_Length		b $00

;*** Zwischenspeicher für Dateinamen.
:AppFile		s 17
:FileNameBuf		s 17
:NewHelpFile		s 17
:curHelpFile		s 17
:curHelpPage		b $00
:HelpFileName		s 10 * 16
:HelpFilePage		s 10
:HelpFileLine		s 10
:HelpFileVec		b $00

;*** Seiteninformationen:
:PageData_Start
:LineStartAdr		s 512
:LinePointer		b $00
:LinesInMem		b $00
:StartGoto		w $0000
:StartIcon		w $0000
:StartFreeMem		w $0000
:IconAdrTab		s 128
:PageData_End

;*** Speicher für Seitenaufbau am Bildschirm.
:RulerData		s 32
:SetGHVcode		b $00
:SetColMode		b $00
:SetColOK		b $00
:ColorTyp		b $00

;*** Speicher für Hilfeseite.
;    Beginnt immer ab $xy00 <= Wichtig!
:Memory
:HelpTextMem		= (Memory / 256 +1) * 256
:TxtBufSize		= EndMemory - HelpTextMem
