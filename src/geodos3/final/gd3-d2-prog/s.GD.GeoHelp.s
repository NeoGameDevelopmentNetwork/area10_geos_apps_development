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
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"

:EndMemory		= $6000				;Ende des Textspeichers.
:LoadAdress		= $4000				;Ladeadresse für GeoWrite-Seite.
							;Größe also von $4000 - $5FFF. GeoWrite
							;verwaltet Seiten mit 4100 Zeichen = $1060.
							;Sollte der Speicher nicht ausreichen, kann
							;er auch auf $3000 heruntergesetzt werden,
							;es kann dann aber passieren das beim kon-
							;vertieren der Textseite es zu Speicher-
							;überschneidungen kommt.
endif

;*** GEOS-Header.
			n "GD.GEOHELP"
			c "GD.HELP     V2.0"
			t "G3_Sys.Author"
			f APPLICATION
			z $80				;nur GEOS64

			o LD_ADDR_HELPSYS		;Ab $0400 - $0FFF liegt LoadGeoHelp!
			p JumpAdr1			;Nur falls vom DeskTop aus gestartet.
			q Memory

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Online-Hilfe für GeoDOS64"
endif
if Sprache = Englisch
			h "OnlineHelpSystem for GeoDOS64"
endif

;*** Einsprungtabelle.
:JumpAdr1		jmp	MainInit		;Einsprung aus Anwendung.
:JumpAdr2		jmp	MainInit_DA		;Ensprung aus "LoadGeoHelp".

;*** Standard-Dateinamen.
;    Ist im Infoblock der Datei kein Dateiname eingetragen, so öffnet
;    GeoHelpView diese Datei:
if Sprache = Deutsch
:Help001		b "DHS_Index.001",$00,NULL
endif

if Sprache = Englisch
:Help001		b "EHS_Index.001",$00,NULL
endif

;*** Klasse für GeoWrite-Dokumente.
:WriteImage		b "Write Image V2",NULL

;*** Zeichensatz für GeoHelpView.
if Sprache = Deutsch
:HelpFont		v 8,"fnt.GeoHelp.de"
endif

if Sprache = Englisch
:HelpFont		v 8,"fnt.GeoHelp.us"
endif

;*** Dialogboxen/Texte.
			t "d.GD.GeoHelp"
			t "t.GD.GeoHelp"

;*** GeoHelp initialisieren.
;Aufruf aus DeskTop.
:MainInit		jsr	GetBackScreen		;Hintergrundbild laden.
			jsr	InitHelp		;Hilfesystem aufrufen.
:MainExit		lda	#$08			;Auf Laufwerk #8 umschalten.
			jsr	SetDevice		;(Wichtig für EnterDeskTop/GEOSV2)
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** GeoHelp initialisieren.
;Aufruf aus "LoadGeoHelp".
:MainInit_DA		PopW	ExitToDA		;Rücksprungadresse sichern.
			jsr	InitHelp		;Hilfesystem aufrufen.
			PushW	ExitToDA		;Rücksprungadresse herstellen.
			rts				;Zurück zu "LoadGeoHelp".

;*** Hilfe initialisieren.
:InitHelp		PopW	ExitToRoutine		;Rücksprungadresse sichern.
			tsx
			stx	Stack

			jsr	InitForIO		;Maus und Rahmenfarbe sichern.
			lda	screencolors
			sta	B_GEOS_BACK
			lda	$d020
			sta	B_GEOS_FRAME
			lda	$d027
			sta	B_GEOS_MOUSE
			jsr	DoneWithIO

			jsr	i_FillRam		;Variablenspeicher löschen.
			w	(VariablenEnd-VariablenStart)
			w	VariablenStart
			b	$00

;*** GEOS-Systemwerte zwischenspeichern.
			jsr	i_MoveData		;Speicher für Dialogboxen
			w	dlgBoxRamBuf		;zwischenspeichern.
			w	b_dlgBoxRamBuf
			w	417

			MoveB	dispBufferOn ,b_dispBufferOn
			MoveW	StringFaultVec ,b_StringFaultVec
			MoveW	rightMargin ,b_rightMargin
			MoveW	otherPressVec ,b_otherPressVec
			MoveW	RecoverVector ,b_RecoverVector
			MoveB	HelpSystemActive ,b_HelpSystem

;*** Variablen initialisieren.
			LoadB	HelpSystemActive ,$00
			LoadB	dispBufferOn ,ST_WR_FORE
			LoadW	StringFaultVec ,EndOfLine
			LoadW	rightMargin ,$0130
			LoadW	otherPressVec ,ChkMseKlick
			LoadW	RecoverVector ,$0000

			lda	C_TopText		;Farbe für Überschrift und
			and	#%11110000		;Querverweise bestimmen.
			ora	C_HelpGround
			sta	C_TopText

			lda	C_LinkText
			and	#%11110000
			ora	C_HelpGround
			sta	C_LinkText

;*** Nach erster Anzeigeseite suchen.
;    Infoblock einlesen. Kennung "=>" vorhanden, Hilfedatei laden.
;    Sonst "GeoHelpView.001" laden.
:Get1stFile		lda	#$00			;Start-/Hilfepartition
			sta	Drive_SPart		;löschen.
			lda	curDrive		;Start-Laufwerk speichern.
			sta	Drive_System

			lda	HelpSystemDrive
			bne	:0
			lda	curDrive
::0			sta	Drive_Help
			and	#%11110000
			beq	:0a
			jsr	CheckDrive
			txa
			bne	:2

::0a			ldx	Drive_Help
			lda	driveType -8,x
			beq	:2

			txa
			jsr	SetDevice
			txa
			bne	:2

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Ende...

			ldx	Drive_Help
			lda	RealDrvMode -8,x
			bpl	:1

			ldy	Drive_Help
			lda	drivePartData-8,y	;Aktive Partition speichern.
			sta	Drive_SPart

			lda	HelpSystemPart
			beq	:1
			sta	r3H
			jsr	OpenPartition
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Ende...

::1			LoadW	r6,HelpFileName
			jsr	FindFile		;Hilfedatei suchen.
			txa				;Gefunden ?
			bne	:GetStdHelp		;Nein, Standard-Hilfe anzeigen.

			ldy	#$0f
::1a			lda	HelpFileName,y		;Name der Hilfedatei in Speicher für
			sta	Help001,y		;"Datei #1" übertragen.
			dey
			bpl	:1a

			lda	HelpSystemPage		;Gewünschte Ziel-Seite.
			b $2c

;*** Hilfedatei suchen, Seite #1 laden.
::GetStdHelp		lda	#$00			;Seite #1 einlesen.
			pha				;Zielseite merken.
			jsr	CopyStdName		;Name von "Datei #1" kopieren.
			pla
			jsr	LoadPage		;Seite einlesen.
			txa
			bne	:1c
			jmp	InitScreen		;Bildschirm aufbauen.
::1c			jmp	GHV_FileErr
::2			jmp	GHV_SysErr		;Systemfehler.

;*** Hilfe verlassen.
:ExitHelp		lda	Drive_Help		;Partition zurücksetzen.
			jsr	SetDevice
			lda	Drive_SPart
			beq	:1
			sta	r3H
			jsr	OpenPartition

::1			lda	Drive_System		;Laufwerk zurücksetzen.
			jsr	SetDevice

::2			jsr	SetOrgCol		;GEOS-Bildschirm zurücksetzen.

			MoveB	b_HelpSystem ,HelpSystemActive
			MoveB	b_dispBufferOn ,dispBufferOn
			MoveW	b_StringFaultVec ,StringFaultVec
			MoveW	b_rightMargin ,rightMargin
			MoveW	b_otherPressVec ,otherPressVec
			MoveW	b_RecoverVector ,RecoverVector

			jsr	i_MoveData		;Speicher für Dialogboxen
			w	b_dlgBoxRamBuf		;zurücksetzen.
			w	dlgBoxRamBuf
			w	417

			ldx	Stack
			txs
			PushW	ExitToRoutine		;Rücksprungadresse wieder
			rts				;herstellen und Ende...

:Stack			b $00

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
			sta	:1

			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::1			b	$00

			jsr	UseSystemFont

;*** Bildschirm löschen.
:ClrScreen		jsr	i_FillRam
			w	8000
			w	SCREEN_BASE
			b	$00

;*** Rechte Bildschirmgrenze erreicht.
;    Kein Text mehr ausgeben.
:EndOfLine		rts

;*** Laufwerkstyp mit gültiger Partition suchen.
:CheckDrive		sta	:DriveType		;Laufwerkstyp speichrn.

			ldx	#$08
::1			lda	driveType   -8,x	;Laufwerk verfügbar ?
			beq	:3			; => Nein, weiter...

			lda	RealDrvType -8,x	;Laufwerkstyp überprüfen.
			and	#%11110000
			cmp	:DriveType		;Stimmt Laufwerksformat ?
			bne	:3			; => Nein, weiter...

			txa
			pha
			jsr	SetDevice		;Laufwerk aktivieren.

			lda	HelpSystemPart
			bne	:1a
			lda	#$ff
::1a			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry		;Partitionsdaten einlesen.
			txa				;Laufwerksfehler ?
			bne	:2			; => Ja, weiter...

			pla
			tax
			lda	driveType -8,x
			and	#%00001111
			cmp	dirEntryBuf		;Stimmt Partitionsformat ?
			bne	:3			; => Nein, weitersuchen.
			beq	:5			; => Ja, Partition öffnen.

::2			pla
			tax
::3			inx
			cpx	#$0c			;Alle Laufwerke durchsucht ?
			bcc	:1			; => Nein, weiter...

::4			ldx	#DEV_NOT_FOUND
			rts

::5			stx	Drive_Help
			ldx	#NO_ERROR
			rts

::DriveType		b $00

;*** Bildschirm initialisieren.
:InitScreen		jsr	SetMenuScreen		;GeoHelp-Menü zeichnen.
			jsr	ViewHelpPage		;Aktuelle Seite anzeigen.

:InitMenu		LoadW	r0,MoveBarData
			jsr	InitBalken		;Anzeigebalken initialisieren.

;*** GeoHelpView-Menü aktivieren.
			lda	C_WinIcon
			jsr	i_UserColor		;Farbe für Menü-Icons.
			b	$00,$01,$28,$03

			LoadW	r0,icon_Tab1
			jsr	DoIcons			;Icons-Menü aktivieren.
			jmp	MainLoop

;*** Menübildschirm aufbauen.
:SetMenuScreen		StartMouse			;Maustreiber aktivieren und warten
			NoMseKey			;bis keine Maustaste gedrückt.

			jsr	InitForIO
			lda	C_GEOS_FRAME
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027
			jsr	DoneWithIO

			jsr	ClrScreen		;Bildschirm löschen.

			lda	C_WinTitel		;Bildschirmfarben setzen.
			jsr	i_UserColor
			b	$00,$00,$28,$01
			lda	C_WinBack
			jsr	i_UserColor
			b	$00,$01,$28,$03
			lda	C_HelpText
			jsr	i_UserColor
			b	$00,$04,$28,$15

			LoadW	r0,HelpFont		;GeoHelpView-Font aktivieren.
			jsr	LoadCharSet
			LoadW	r0,HelpText01
			jmp	PutString

;******************************************************************************
; Dialogbox-Routine.
; Erklärung:
; Beim Aufruf einer Dialogbox wird der Bildschirm-Bereich unter der DlgBox
; in der REU zwischengespeichert. War beim Aufruf des TaskManagers eine DlgBox
; geöffnet, dann ist dieser Bereich nun belegt. Soll nun innerhalb des Menüs
; eine weitere DlgBox geöffnet werden, so muß der Zwischenspeicher für die
; Bildschirmgrafik unter der geöffneten DlgBox ausgelesen werden, bevor eine
; neue DlgBox geöffnet werden kann. Nach Abschluß der neuen DlgBox wird der
; ausgelesene Zwischenspeicher wieder in die REU zurückkopiert.
;******************************************************************************
:DoSysDlgBox		lda	Flag_ExtRAMinUse	;Systemflag zwischenspeichern.
			pha
			tya				;Zeiger auf Definitionstabelle für
			pha				;Dialogboxtabelle zwischenspeichern.
			txa
			pha
			jsr	SetDlgBoxGrfx		;Grafik-/Farbspeicher unter einer
			jsr	FetchRAM		;evtl. geöffneten Dialogbox retten.
			jsr	SetDlgBoxCols
			jsr	FetchRAM
			pla				;Zeiger auf Dialogboxtabelle.
			sta	r0L
			pla
			sta	r0H
			jsr	DoDlgBox		;Dialogbox ausführen.
			jsr	SetDlgBoxCols		;Grafik-/Farbspeicher unter einer
			jsr	StashRAM		;evtl. geöffneten Dialogbox wieder
			jsr	SetDlgBoxGrfx		;zurückschreiben.
			jsr	StashRAM
			pla
			sta	Flag_ExtRAMinUse	;Systemflag zurücksetzen.
			rts

;*** Zeiger auf Grafikspeicher richten.
:SetDlgBoxGrfx		LoadW	r0 ,$2000
			LoadW	r1 ,R2_ADDR_DB_GRAFX
			LoadW	r2 ,R2_SIZE_DB_GRAFX
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

;*** Zeiger auf Farbspeicher richten.
:SetDlgBoxCols		LoadW	r0 ,$1c00
			LoadW	r1 ,R2_ADDR_DB_COLOR
			LoadW	r2 ,R2_SIZE_DB_COLOR
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

;*** Akku zu ":r15" addieren.
:AddAto_r15		ldx	#r15L
			b $2c

;*** Akku zu ":r11" addieren.
:AddAto_r11		ldx	#r11L
			b $2c

;*** Akku zu ":r0" addieren.
:AddAto_r0		ldx	#r0L
			clc
			adc	$00,x
			sta	$00,x
			bcc	:1
			inc	$01,x
::1			rts

;*** X-Koordinate auf Anfang.
:SetXtoStart		ldx	#<$0008
			stx	r11L
			ldx	#>$0008
			stx	r11H
			rts

;*** Zeilenadresseberechnen.
:SetLineAdr		ldy	#$00			;Startadresse der aktuellen
			asl				;Zeile einlesen.
			bcc	:1
			iny
::1			clc
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

;*** Aktuelle Cursorposition auf nächstes CARD setzen.
:MoveToCard		lda	r11L
			and	#%00000111
			beq	:1
			lda	r11L
			ora	#%00000111
			sta	r11L
			inc	r11L
			bne	:1
			inc	r11H
::1			rts

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

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawError		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0030,$010f
			lda	C_DBoxTitel
			jsr	DirectColor

			jsr	i_BitmapUp
			w	icon_Warning
			b	$07,$48,$03,$18

			lda	C_DBoxBack
			and	#%00001111
			ora	#%01110000
			jsr	i_UserColor
			b	$07,$09,$03,$03
			lda	#$70
			jsr	i_UserColor
			b	$08,$0a,$01,$01
			rts

;*** ASCII-Zahl (zwei Zeichen) nach DEZIMAL.
:GetHexCode		jsr	:3
			tax
			iny
			jsr	:3
			cpx	#$00
			beq	:2
::1			clc
			adc	#$10
			dex
			bne	:1
::2			rts

::3			lda	(r0L),y
			sec
			sbc	#$30
			cmp	#$0a
			bcc	:4
			and	#%00011111
			sec
			sbc	#$07
::4			rts

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

;*** Hilfedatei suchen.
:FindMainHelp		jsr	CopyStdName		;Name in Zwischenspeicher.

			lda	#$00			;Titel-Seite lesen.
			b $2c

;*** Indexseite der aktuellen Hilfedatei.
:GotoIndex		lda	#$01			;Index-Seite lesen.

			ldx	#$00			;Zeiger auf Zeile 1 richten.
			stx	LinePointer		;(Seitenanfang anzeigen).

;*** Neue Seite anzeigen.
;    Seiten-Nr. im AKKU.
:OpenNewPage		jsr	LoadPage		;Seite aus datei einlesen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, "Page not found" ausgeben.
			jmp	ViewHelpPage		;Zum Anfang der Seite/ausgeben.
::1			jmp	GHV_FileErr

;*** Letzte Hilfeseite öffnen.
:LastHelpPage		lda	curHelpPage		;Seitenzeiger einlesen.

::1			sec
			sbc	#$01			;Seitenzahl -1.
			bcs	:2			;Noch im erlaubten Bereich ?
			lda	#60			;Nein, letzte, mögliche Seite lesen.

::2			pha				;Seitenzeiger merken.
			jsr	PointRecord		;Seite aufrufen.
			pla				;Seitenzeiger einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.
			cpy	#$00			;Seite verfügbar ?
			beq	:1			;Nein, eine Seite zurück...

			stx	LinePointer		;Zeiger auf Anfang der Seite.
			jmp	OpenNewPage		;Neue Seite anzeigen.

::3			jmp	GHV_FileErr		;Dateifehler ausgeben.

;*** Nächste Hilfeseite öffnen.
:NextHelpPage		lda	curHelpPage		;Seitenzeiger einlesen.

::1			clc
			adc	#$01			;Seitenzahl +1.
			cmp	#61
			bcc	:2			;Noch im erlaubten Bereich ?
			lda	#0			;Nein, auf Seite 1.

::2			pha				;Seitenzeiger merken.
			jsr	PointRecord		;Seite aufrufen.
			pla				;Seitenzeiger einlesen.
			cpx	#$00			;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.
			cpy	#$00			;Seite verfügbar ?
			beq	:1			;Nein, eine Seite zurück...

			stx	LinePointer		;Zeiger auf Anfang der Seite.
			jmp	OpenNewPage		;Neue Seite anzeigen.

::3			jmp	GHV_FileErr		;Dateifehler ausgeben.

;*** Name der Startdatei in Zwischenspeicher.
:CopyStdName		ldy	#$0f			;Name der Titel-Hilfedatei in
::1			lda	Help001,y		;Zwischenspeicher kopieren.
			sta	NewHelpFile,y
			dey
			bpl	:1
			rts

;*** Zum letzten Thema zurückblättern.
:CallLastTheme		ldx	HelpFileVec		;Stackzeiger einlesen.
			cpx	#$02			;Weitere Seite im Stackspeicher ?
			bcs	:1			; => Ja, weiter...

			ClrB	HelpFileVec		;Nein, Seite #1 von "Datei #1"
			jmp	FindMainHelp		;einlesen und anzeigen.

::1			dex				;Zeiger auf letzten Stackeintrag.
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
::2			lda	HelpFileName,x		;Zwischenspeicher kopieren.
			sta	NewHelpFile,y
			inx
			iny
			cpy	#$10
			bcc	:2

			pla
			sta	LinePointer		;Zeiger innerhalb der Seite setzen.
			pla
			jmp	OpenNewPage		;Seite einlesen.

;*** Aktuelle Seite in Stackspeicher eintragen.
:PageInBuffer		lda	HelpFileVec		;Stackzeiger merken.
			pha
			cmp	#10			;Stackspeicher voll ?
			bcc	:1			;Nein, weiter...

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
			sec
			sbc	#$01
			pha

::1			pla				;Stackzeiger einlesen.
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

			ldy	#$00			;Dateiname in Stackspeicher
::2			lda	curHelpFile,y		;kopieren.
			sta	HelpFileName,x
			inx
			iny
			cpy	#$10
			bcc	:2

			pla
			clc
			adc	#$01
			sta	HelpFileVec		;Stackzeiger korrigieren.
			rts

;*** Maus abfragen.
; - Querverweise
; - Rollbalken
:ChkMseKlick		ClrB	r0L
::1			jsr	CopyMouseData		;Mausbereich einlesen.

			php
			sei
			jsr	IsMseInRegion
			plp
			tax				;Mausklick innerhalb Bereich ?
			beq	:2			;Nein, weiter...
			jmp	(r5)			; => Ja, Routine aufrufen.

::2			inc	r0L
			lda	r0L
			cmp	#$05			;Alle Bereiche überprüft ?
			bne	:1			;Nein, weiter...
			rts				; => Ja, Keine Funktion!

;*** Bereichsdaten einlesen.
:CopyMouseData		asl
			asl
			asl
			tay
			ldx	#$00
::1			lda	Tab_MseSlctArea,y
			sta	r2L,x
			iny
			inx
			cpx	#$08
			bne	:1
			rts

;*** Dauerfunktion ?
:TestMouse		lda	mouseData		;Maustaste noch gedrückt ?
			bne	:1			;Nein, weiter...
			sec
			rts

::1			ClrB	pressFlag
			clc
			rts

;*** Mausklick beenden.
:EndSlctIcon		jsr	CopyMouseData
			jsr	InvertRectangle
			NoMseKey
			LoadW	r0,Tab_MseScrnArea
			jmp	InitRam

;*** Seite anzeigen und auf Maustaste warten.
:NPageAndMse		jsr	ViewHelpPage
			NoMseKey
			rts

;*** Balken verschieben.
:MoveBar		lda	LinesInMem
			cmp	#21 +1			;Mehr als 21 Zeilen ?
			bcc	:1			;Nein, Ende...

			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:2			; => Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:3			; => Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:4			; => Ja, eine Seite vorwärts.
::1			rts

::2			jmp	LastPage
::3			jmp	MoveToPos
::4			jmp	NextPage

;*** Balken verschieben.
:MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

			lda	LinePointer		;Aktuelle Position merken.
			sta	r15L

::1			jsr	UpdateMouse		;Mausdaten aktualisieren.
			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:2			;Nein, neue Position anzeigen.
			lda	inputData		;Mausbewegung einlesen.
			bne	:4			;Mausbewegung auswerten.
			beq	:1			;Keine Bewegung, Schleife...

::2			ClrB	pressFlag		;Maustastenklick löschen.
			LoadW	r0,Tab_MseScrnArea
			jsr	InitRam
			lda	LinePointer
			cmp	r15L
			beq	:3
			jmp	ViewHelpPage		;Position anzeigen.
::3			rts

::4			cmp	#$02			;Maus nach oben ?
			beq	:5			; => Ja, auswerten.
			cmp	#$06			;Maus nach unten ?
			beq	:6			; => Ja, auswerten.
			jmp	:1			;Keine Bewegung, Schleife...

::5			jsr	LastLine_a
			bcs	:1			;Geht nicht, Abbruch.
			dec	LinePointer		;Zeiger auf letzte Datei.
			jmp	:7			;Neue Position anzeigen.

::6			jsr	NextLine_a		;Eine Datei vorwärts.
			bcs	:1			;Geht nicht, Abbruch.
			inc	LinePointer		;Zeiger auf nächste Datei.
::7			lda	LinePointer		;Tabellenposition einlesen und
			jsr	SetPosBalken		;Anzeigebalken setzen und
			jsr	SetRelMouse		;Maus entsprechend verschieben.
			jmp	:1			;Maus weiter auswerten.

;*** Eine Seite vor.
:NextPage		lda	LinePointer
			clc
			adc	#$26
			bcs	:1
			cmp	LinesInMem
			bcc	:3

::1			lda	LinesInMem
			sec
			sbc	#$13
			bcc	:2
			cmp	LinePointer
			bne	:4
::2			rts

::3			sec
			sbc	#$13
::4			sta	LinePointer
			jmp	NPageAndMse

;*** Eine Seite zurück.
:LastPage		lda	LinePointer
			sec
			sbc	#$13
			bcs	:1
			lda	#$00
			cmp	LinePointer
			beq	:2
::1			sta	LinePointer
			jmp	NPageAndMse
::2			rts

;*** Textseite bewegen: Nach unten.
:NextLine		jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle

::1			jsr	NextLine_a		;Scrolling möglich ?
			bcs	:2			;Nein, Ende...
			jsr	ScrollDown		;Eine Zeile scrollen.

			lda	LinePointer		;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:1			;Weiterscrollen.

::2			lda	#$01
			jmp	EndSlctIcon

:NextLine_a		lda	LinesInMem
			cmp	#21
			bcc	:1
			lda	LinePointer
			clc
			adc	#$15
			cmp	LinesInMem
			bcc	:2
::1			sec
			rts
::2			clc
			rts

;*** Eine Datei vorwärts.
:ScrollDown		php
			sei

			LoadW	r0,SCREEN_BASE  + 5*40*8 + 1*8
			LoadW	r1,SCREEN_BASE  + 4*40*8 + 1*8
			LoadW	r2,COLOR_MATRIX + 5*40   + 1
			LoadW	r3,COLOR_MATRIX + 4*40   + 1

			ldx	#20
::1			lda	#2
::2			pha
			ldy	#$00			;18 Grafikzeilen a 296 Byte.
::3			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#152
			bne	:3

			AddVBW	152,r0			;Grafikzeile wird in zwei Teilen
			AddVBW	152,r1			;kopiert, da > 256 Byte.

			pla
			sec
			sbc	#$01
			bne	:2

			AddVBW	16,r0
			AddVBW	16,r1

			ldy	#$25			;Farbe kopieren.
::4			lda	(r2L),y
			sta	(r3L),y
			dey
			bpl	:4

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
			bne	:1
			plp

			inc	LinePointer

;*** Letzte Zeile ausgeben.
:PrintEndLine		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$c0,$c7
			w	$0000,$0137
			lda	C_HelpText
			jsr	DirectColor

			lda	LinePointer		;Zeiger auf letzte Zeile.
			clc
			adc	#$14
			ldy	#$c6
			jmp	InitPrntLine

;*** Textseite bewegen: Nach oben.
:LastLine		jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle

::1			jsr	LastLine_a
			bcs	:2
			jsr	ScrollUp		;Eine Zeile scrollen.

			lda	LinePointer		;Balken neu positionieren.
			jsr	SetPosBalken

			jsr	TestMouse		;Maustaste noch gedrückt ?
			bcs	:1			;Weiterscrollen.

::2			lda	#$00
			jmp	EndSlctIcon

:LastLine_a		lda	LinesInMem
			cmp	#21
			bcc	:1
			lda	LinePointer
			bne	:2
::1			sec
			rts
::2			clc
			rts

;*** Eine Zeile zurück.
:ScrollUp		php
			sei

			LoadW	r0,SCREEN_BASE  + 23*40*8 + 1*8 + 152
			LoadW	r1,SCREEN_BASE  + 24*40*8 + 1*8 + 152
			LoadW	r2,COLOR_MATRIX + 23*40   + 1
			LoadW	r3,COLOR_MATRIX + 24*40   + 1

			ldx	#20
::1			lda	#$02
::2			pha
			ldy	#151			;18 Grafikzeilen a 296 Byte.
::3			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			dey
			cpy	#255
			bne	:3

			SubVW	152,r0			;Grafikzeile wird in zwei Teilen
			SubVW	152,r1			;kopiert, da > 256 Byte.

			pla
			sec
			sbc	#$01
			bne	:2

			SubVW	16,r0
			SubVW	16,r1

			ldy	#$25			;Farbe kopieren.
::4			lda	(r2L),y
			sta	(r3L),y
			dey
			bpl	:4

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
			bne	:1
			plp

			dec	LinePointer

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$27
			w	$0000,$0137
			lda	C_HelpText
			jsr	DirectColor

			lda	LinePointer		;Zeiger auf erste Zeile.
			ldy	#$26
			jmp	InitPrntLine

;*** Balken initialiseren.
:InitBalken		ldy	#$05			;Paraeter speichern.
::1			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:1

			jsr	Anzeige_Ypos		;Position Anzeigebalken berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.

			lda	SB_XPos
			sta	:2 +0
			sta	:3 +0
			sta	:4 +0

			lda	SB_YPos			;Position für "UP"-Icon berechnen.
			clc
			adc	SB_MaxYlen
			sta	:2 +1

			lda	SB_YPos			;Position für "DOWN"-Icon berechnen.
			clc
			adc	SB_MaxYlen
			clc
			adc	#$08
			sta	:3 +1

			lda	SB_YPos			;Position für Balken berechnen.
			lsr
			lsr
			lsr
			sta	:4 +1

			lda	SB_MaxYlen		;Länge des Farbbalkens berechnen.
			lsr
			lsr
			lsr
			clc
			adc	#$02
			sta	:4 +3

			jsr	i_BitmapUp		;"UP"-Icon ausgeben.
			w	icon_UP
::2			b	$17,$ff,$01,$08
			jsr	i_BitmapUp		;"DOWN"-Icon ausgeben.
			w	icon_DOWN
::3			b	$17,$ff,$01,$08
			lda	C_Balken
			jsr	i_UserColor
::4			b	$00,$00,$01,$00

			jmp	PrintBalken		;Balken ausgeben.

;*** Neue Balkenposition defnieren und anzeigen.
:SetPosBalken		sta	SB_PosEntry		;Neue Position Füllbalken setzen.

;*** Balken ausgeben.
:PrintBalken		jsr	Balken_Ypos		;Y-Position Füllbalken berechnen.

:PrintCurBalken		MoveW	SB_PosTop,r0		;Grafikposition berechnen.

			ClrB	r1L			;Zähler für Balkenlänge löschen.
			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::1			lda	#%01010101
			sta	r1H
			lda	r1L
			lsr
			bcc	:2
			asl	r1H

::2			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:5			; => Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:4			; => Ja, Quer-Linie ausgeben.
			bcc	:5			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:4			; => Ja, Quer-Linie ausgeben.
			bcs	:5			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:5			; => Ja, Quer-Linie ausgeben.

::3			lda	r1H
			and	#%10000001
			ora	#%01100110		;Wert für Füllbalken.
			bne	:6

::4			lda	r1H
			ora	#%01111110
			bne	:6

::5			lda	r1H
::6			sta	(r0L),y			;Byte in Grafikspeicher schreiben.
			inc	r1L
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:7			; => Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:1			;Nein, weiter...

			AddVW	320,r0			;Zeiger auf nächstes CARD berechnen.
			ldy	#$00
			beq	:1			;Schleife...
::7			rts				;Ende.

;*** Position des Anzeigebalken berechnen.
:Anzeige_Ypos		MoveB	SB_XPos,r0L		;Zeiger auf X-CARD berechnen.
			LoadB	r0H,NULL
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	SCREEN_BASE,r0		;Zeiger auf Grafikspeicher.

			lda	SB_YPos			;Zeiger auf Y-Position
			lsr				;berechnen.
			lsr
			lsr
			tay
			beq	:2
::1			AddVW	40*8,r0
			dey
			bne	:1
::2			MoveW	r0,SB_PosTop		;Grafikspeicher-Adresse merken.
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	#$00
			ldx	SB_MaxEScr
			cpx	SB_MaxEntry		;Balken möglich ?
			bcs	:1			;Nein, weiter...
			MoveB	SB_MaxYlen,r0L		;Länge Balken berechnen.
			MoveB	SB_MaxEScr,r1L
			jsr	Mult_r0r1
			MoveB	SB_MaxEntry,r1L
			jsr	Div_r0r1
			CmpBI	r0L,8			;Balken kleiner 8 Pixel ?
			bcs	:1			;Nein, weiter...
			lda	#$08			;Mindestgröße für Balken.
::1			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		ldx	#NULL
			ldy	SB_Length
			CmpB	SB_MaxEScr,SB_MaxEntry
			bcs	:1

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
			clc
			adc	SB_Length
			tay
::1			stx	SB_Top
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
::1			lda	SB_XPos,x
			sta	r0L,x
			dex
			bpl	:1
			rts

;*** Mausklick überprüfen.
:IsMseOnPos		lda	mouseYPos
			suba	SB_YPos
			cmp	SB_Top
			bcc	:3
::1			cmp	SB_End
			bcc	:2
			lda	#$03
			b $2c
::2			lda	#$02
			b $2c
::3			lda	#$01
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
			clc
			adc	SB_Top

:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			suba	SB_Top
			sta	SetRelMouse+1
			rts

;*** Einzelne Seite drucken.
:PrintHelpPage		jsr	InitPrintHelp		;Ausdruck initialisieren.
			txa				;Initialisierungsfehler ?
			bne	:2			; => Ja, Abbruch...

			jsr	SetzeGAdresse		;Zeiger auf Druckdaten-Speicher.
			jsr	StartPrint		;Drucker initialisieren.
			txa
			bne	:1			;Fehler, Abbruch.

			StartMouse
			NoMseKey			;Maustaste gedrückt ? Ja, warten...

			jsr	DruckStarten		;Hilfeseite drucken.
::1			jmp	ExitPrnMenu		;Menü-Funktionen wieder aktivieren.
::2			jmp	RestartCurPage

;*** Gesamte Hilfedatei drucken.
:PrintAllHelp		jsr	InitPrintHelp		;Ausdruck initialisieren.
			txa				;Initialisierungsfehler ?
			bne	:4			; => Ja, Abbruch...

			jsr	SetzeGAdresse		;Zeiger auf Druckdaten-Speicher.
			jsr	StartPrint		;Drucker initialisieren.
			txa
			bne	:3			;Fehler, Abbruch.

			StartMouse
			NoMseKey			;Maustaste gedrückt ? Ja, warten...

			lda	#$00
::1			pha
			jsr	LoadHelpPage		;Seite einlesen.
			txa				;Seite verfügbar ?
			bne	:2			;Nein, Druckende...

			jsr	SetPrntData2		;Bildschirmdaten anzeigen.

			jsr	DruckStarten		;Hilfeseite drucken.
			txa				;Abbruch ?
			bne	:2			;Nein, weiter drucken.

			pla
			clc
			adc	#$01
			cmp	#61			;Zeiger auf nächste Seite.
			bcc	:1			;Weiterdrucken.
			pha

::2			pla
::3			jmp	ExitPrnMenu		;Ausdruck beenden.
::4			jmp	RestartCurPage		;Zurück zur Hilfe.

;*** Druckmenü initialisieren.
:InitPrintHelp		jsr	SetOrgCol		;Farben zurücksetzen.

			LoadW	r9,HdrB000		;Speicherbereich für Druckertreiber
			ClrB	r10L			;auf Diskette auslagern.
			jsr	SaveFile
			txa				;Diskettenfehler ?
			beq	:LoadPrntDrv		; => Ja, Abbruch.

			ldx	#< Dlg_PrnSwapErr
			ldy	#> Dlg_PrnSwapErr
			jsr	DoSysDlgBox		;Diskettenfehler anzeigen.
			ldx	#$02
			rts

;--- Druckertreiber laden.
::LoadPrntDrv		LoadW	r6,PrntFileName
			LoadW	r7,PRINTBASE
			LoadB	r0L,%00000001
			jsr	GetFile			;Druckertreiber einladen.
			txa
			beq	:InitPrntDrv

			pha
			LoadW	r0,HdrFileName		;Swapdatei auf Diskette löschen.
			jsr	DeleteFile
			ldx	#< Dlg_LdPrnDrvErr
			ldy	#> Dlg_LdPrnDrvErr
			jsr	DoSysDlgBox
			pla
			tax
			rts

;--- Aysdruck initialisieren.
::InitPrntDrv		lda	curHelpPage		;Aktuelle Seite merken.
			sta	ExitToHelpPage

			jsr	InitForPrint		;Druckertreiber initialisieren.

			jsr	SetPrntData1		;Bildschirm initialisieren.
			jsr	SetPrntData2

			ldx	#$ff			;Keine Farbe setzen.
			stx	Flag_ColorText
			inx				;Flag: "Kein Fehler!".
			rts

;*** Druckmenü verlassen.
:ExitPrnMenu		LoadW	r6,HdrFileName		;Speicherbereich wieder herstellen.
			LoadW	r7,PRINTBASE
			LoadB	r0L,%00000001
			jsr	GetFile

			LoadW	r0,HdrFileName		;Swapdatei auf Diskette löschen.
			jsr	DeleteFile

:RestartCurPage		ClrB	Flag_ColorText		;Farbe wieder anzeigen.
			jsr	SetMenuScreen

			lda	ExitToHelpPage
			jsr	LoadHelpPage		;Seite aus GW-Dokument einlesen.
			txa				;Diskettenfehler ?
			beq	:1			;Nein, weiter...
			jmp	GHV_FileErr

::1			lda	LinesInMem		;Scrollbalken initialisieren.
			sta	MoveBarData +3
			lda	LinePointer
			sta	MoveBarData +5

			LoadW	r0,MoveBarData
			jsr	InitBalken		;Scrollbalken anzeigen.
			jsr	ViewHelpPage 		;Alte Seite wieder einlesen.
			jmp	InitMenu		;Menü-Funktionen wieder aktivieren.

;*** Druck-Bildschirm aufbauen.
:SetPrntData1		jsr	InitForIO
			LoadB	$d020,$00
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36
			jsr	i_ColorBox
			b	$00,$01,$28,$01,$bf
			LoadW	r0,HelpFont		;GeoHelpView-Font aktivieren.
			jmp	LoadCharSet

:SetPrntData2		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$b8,$c7
			w	$0000,$013f

			LoadW	r0,HelpText02
			jsr	PutString

;*** Aktuelle Seiten-Nr. anzeigen.
:PrntCurPage		LoadW	r0,curHelpFile
			jsr	PutString
			LoadW	r0,TextPage
			jsr	PutString

			ldx	curHelpPage
			inx
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Aktuelle Seite drucken.
:DruckStarten		LoadW	r0,HelpText03		;Infomeldung ausgeben.
			jsr	PutString

			jsr	PrntCurPage		;Aktuelle Seite anzeigen.
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
::1			cmp	LinesInMem		;Bildschirm ausgeben und drucken.
			bcs	:3
			sta	LinePointer
			jsr	SetLineAdr
			beq	:3

			LoadB	r1H,$0e
			jsr	SetXtoStart
			jsr	ViewNextTextLine
			jsr	Drucke1GZeile		;Zeile drucken.

			ldx	pressFlag		;Taste gedrückt ?
			bne	:4			; => Ja, Abruch.
::2			lda	LinePointer
			clc
			adc	#$01 			;Zeiger auf nächste Zeile.
			bne	:1			;Nächste Zeile drucken.

::3			ldx	#$00

::4			txa
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

;*** Seite anzeigen.
:ViewHelpPage		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$c7
			w	$0000,$0137
			lda	C_HelpText
			jsr	DirectColor

			LoadB	r1H,$26
			ClrB	currentMode
			MoveB	LinePointer,r14L

::1			lda	r14L
			jsr	SetLineAdr		;Zeiger auf aktuelle Zeile.
			beq	:3			;Zeile nicht verfügbar, Ende.

::2			jsr	SetXtoStart		;X-Koordinate auf Anfang.
			jsr	ViewNextTextLine	;Zeile ausgeben.

			AddVBW	8,r1H			;Zeiger auf nächste Zeile.
			inc	r14L
			CmpBI	r1H,$ce			;Bildschirmende erreicht ?
			bcc	:1			;Nein, weiter...

;*** Seiteninformtionen ausgeben.
::3			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$07
			w	$0000,$013f
			lda	C_WinTitel
			jsr	DirectColor

			LoadW	r0,HelpText01
			jsr	PutString

			LoadW	r11,$0068
			LoadB	r1H,$06
			LoadW	r0,curHelpFile
			jsr	PutString

			LoadW	r0,TextPage
			jsr	PutString

			ldx	curHelpPage		;Aktuelle Seiten-Nr. ausgeben.
			inx
			stx	r0L
			LoadB	r0H,$00
			lda	#%11000000
			jsr	PutDecimal

			lda	#" "
			jsr	SmallPutChar
			lda	#"("
			jsr	SmallPutChar

			lda	UsedMem
			sta	r0L
			LoadB	r0H,$00
			lda	#%11000000
			jsr	PutDecimal
			lda	#"%"
			jsr	SmallPutChar
			lda	#")"
			jsr	SmallPutChar

			jsr	i_BitmapUp
			w	icon_DOWN
			b	$0c,$00,$01,$08

			lda	LinePointer		;Balken neu positionieren.
			jmp	SetPosBalken

;*** Erste/Letzte Textzeile ausgeben.
:InitPrntLine		sty	r1H			;Zeilendaten berechnen.
			jsr	SetXtoStart
			jsr	SetLineAdr

;*** Aktuellen Zeile ausgeben.
:ViewNextTextLine	jsr	CheckAlignText

			lda	#$00			;Space-Zähler löschen.
			sta	Data_CountSpace		;(Für Blocksatz notwendig).

:ViewNxLineCont		ldy	#$00
			lda	(r15L),y		;Zeichen aus Text einlesen.

			cmp	#CR			;Zeilenende erreicht ?
			beq	:ViewNxLineEnd		; => Ja, nächste Zeile.

			cmp	#NULL			;Seitenende erreicht ?
			bne	:ViewScriptCode		;Nein, weiter...

;--- Zeilen-Ende erreicht, Ende.
::ViewNxLineEnd		bit	Flag_ColorActive	;Farbmodus aktiv ?
			bpl	:ViewLineEnd		;Nein, weiter...
			jsr	DoColorText		;Farbe anzeigen.

;--- Zeichen auf nächstes Zeichen.
::ViewLineEnd		lda	#$01			;Zeiger auf nächstes Zeichen.
			jmp	AddAto_r15		;Nächstes Zeichen der

;*** GHV-Steuerzeichen auswerten.
;    Ungültige Textzeichen ($00-$1f, $80-$ff) ignorieren.
::ViewScriptCode	cmp	#$ff			;Blockende = Textende erreicht ?
			beq	:ViewLineEnd		; => Ja, Ende...
			cmp	#$f0			;GHV-Steuercode ?
			bcc	:21			;Nein, weiter...
			jmp	ExecGHVcode		;GHV-Code ausführen.

::21			cmp	#$20			;GEOS-ASCII-Zeichen ausgeben.
			bcc	ViewNxChar		;Leerzeichen ?
			bne	:22			; => Nein, weiter...

			bit	Flag_AlignText		;Blocksatz aktiv ?
			bpl	:23			; => Nein, weiter...

			ldx	Data_CountSpace		;Position für Space-Zeichen und
			lda	Tab_SpacePosL,x		;nachfolgenden Text einlesen.
			sta	r11L
			lda	Tab_SpacePosH,x
			sta	r11H
			inc	Data_CountSpace
			jmp	ViewNxChar

::22			cmp	#$7f			;Sonderzeichen ?
			bcs	ViewNxChar		; => Ja, weiter...
::23			jsr	SmallPutChar		;Textzeichen ausgeben.

;--- Zeiger auf nächstes Zeichen.
:ViewNxChar		lda	#$01			;Zeiger auf nächstes Zeichen.

;--- Zeiger auf nächsten Text.
:ViewNxText		jsr	AddAto_r15		;Nächstes Zeichen der
			jmp	ViewNxLineCont		;aktuellen Zeile ausgeben.

;*** GeoWrite-Formatierung: "Blocksatz"
:CheckAlignText		lda	#$00
			sta	Flag_AlignText		;Flag für Blocksatz löschen.
			sta	Data_CountSpace		;Anzahl Leerzeichen/Zeile löschen.

			PushW	r15			;Position der Leerzeichen für
			PushW	r11			;Blocksatz bestimmen.
			jsr	SetXtoStart
			jsr	:FindAlignCode
			MoveW	r11,VarMaxXPos
			PopW	r11
			PopW	r15

			lda	Data_CountSpace		;Leerzeichen gefunden ?
			beq	:Found_NoAlign		; => Nein, weiter...
			bit	Flag_AlignText		;Blocksatz aktiviert ?
			bpl	:CheckAlignEnd		; => Nein, weiter...
			jmp	MakeSpcWidth		;Breite der Leerzeichen berechnen.

;--- Steuercode $F7=Blocksatz suchen.
::FindAlignCode		ldy	#$00			;Zeichen einlesen.
			lda	(r15L),y		;Zeilenende erreicht ?
			beq	:CheckAlignEnd		; => Ja, Ende...
			cmp	#$f1			;Tabulator ?
			beq	:Found_NoAlign		; => X-Koordinate korrigieren.
			cmp	#$f7			;Blocksatz aktivieren ?
			beq	:Found_Align		; => Ja, weiter...
			cmp	#CR			;Zeilenende ?
			beq	:CheckAlignEnd		; => Ja, Ende...
			cmp	#$20			;Sonderzeichen ?
			bcc	:Found_Illegal		; => Ja, ignorieren.
			cmp	#$f0			;Steuercode ?
			bcs	:Found_Code		; => Ja, ausführen.

			cmp	#" "			;Leerzeichen ?
			bne	:Found_Char		; => Nein, weiter...
			pha
			ldx	Data_CountSpace		;X-Koordinate speichern.
			lda	r11L
			sta	Tab_SpacePosL,x
			lda	r11H
			sta	Tab_SpacePosH,x
			pla
			inc	Data_CountSpace		;Anzahl Space +1.
			jmp	:Found_Illegal

;--- Textzeichen gefunden.
::Found_Char		jsr	GetCharWidth		;Zeichenbreite ermitteln.
			jsr	AddAto_r11		;X-Koordinate korrigieren.

;--- Illegaler Steuercode gefunden.
::Found_Illegal		lda	#$01
			jsr	AddAto_r15		;Nächstes Zeichen der
			jmp	:FindAlignCode		;Zeile bearbeiten.

;--- Blocksatz gefunden.
::Found_Align		ldx	#$ff			;Flag "Blocksatz" setzen.
			stx	Flag_AlignText

;--- Steuercode gefunden.
::Found_Code		jsr	GetCodeLen_r15		;Länge für Steuercode ermitteln und
			txa				;Steuercode überlesen.
			jsr	AddAto_r15
			jmp	:FindAlignCode

;--- Kein Blocksatz.
::Found_NoAlign		ldx	#$00
			stx	Flag_AlignText
::CheckAlignEnd		rts

;*** Breite für Leerzeichen bei "Blocksatz" berechnen.
:MakeSpcWidth		ldx	#39			;Tabelle für "Space"-Daten löschen.
			lda	#$00
::1			sta	Tab_SpaceWidth,x
			dex
			bpl	:1

			lda	#< 303			;Breite aller Textzeichen berechnen.
			sec
			sbc	VarMaxXPos +0
			sta	VarMaxXPos +0
			lda	#> 303
			sbc	VarMaxXPos +1
			sta	VarMaxXPos +1

;--- Breite Leerzeichen berechnen.
::CalcSpaceSize		ldx	#$00			;Alle Space-Zeichen um 1 Pixel
::11			lda	VarMaxXPos +0		;vergrößern bis Textzeile gefüllt
			ora	VarMaxXPos +1		;ist.
			beq	:MakeSpaceXPos

			lda	VarMaxXPos +0		;Ein Pixel weniger.
			bne	:12
			dec	VarMaxXPos +1
::12			dec	VarMaxXPos +0

			inc	Tab_SpaceWidth,x
			inx
			cpx	Data_CountSpace
			bcc	:13
			ldx	#$00
::13			jmp	:11

;--- X-Koordinaten der Leerzeichen berechnen.
::MakeSpaceXPos		ldx	#$00
::21			txa
			tay
::22			lda	Tab_SpacePosL ,x
			clc
			adc	Tab_SpaceWidth,y
			sta	Tab_SpacePosL ,x
			bcc	:23
			inc	Tab_SpacePosH ,x
::23			dey
			bpl	:22
			inx
			cpx	Data_CountSpace
			bne	:21
			rts

;*** GHV-Code ausführen.
:ExecGHVcode		cmp	#$f1			;Tabulator ?
			beq	:2			; => Ja, ausführen...
			cmp	#$f2			;Link-Verweis ?
			beq	:3			; => Ja, ausführen....
			cmp	#$f3			;Titelfarbe setzen ?
			beq	:4			; => Ja, ausführen....
			cmp	#$f4			;Farbe setzen ?
			beq	:5			; => Ja, ausführen....
			cmp	#$f5			;Grafik anzeigen ?
			beq	:6			; => Ja, ausführen....
			cmp	#$f6			;Link/Farbe abschließen ?
			beq	:7			; => Ja, ausführen....
			cmp	#$f7			;Blocksatz akktivieren ?
			beq	:8			; => Ja, ausführen....
			cmp	#$f8			;Blocksatz akktivieren ?
			beq	:9			; => Ja, ausführen....
			cmp	#$f9			;Blocksatz akktivieren ?
			beq	:10			; => Ja, ausführen....
::1			jmp	ViewNxChar		;Zeichen übergehen.
::2			jmp	ExecSetTab
::3			jmp	ExecDoLink
::4			jmp	ExecTitel
::5			jmp	ExecColor
::6			jmp	ExecGrafx
::7			jmp	ExecEndCol
::8			jmp	ExecBlock
::9			jmp	ExecColBlk
::10			jmp	ExecColArea

;*** GHV-Code $F1:Tabulator ausführen.
:ExecSetTab		jsr	Do_SetTab		;Tabulator setzen.
			jmp	ViewNxText		;3 Byte überlesen.

;--- Tabulatorposition einlesen.
:Do_SetTab		ldy	#$01
			lda	(r15L),y
			sta	r11L
			iny
			lda	(r15L),y
			sta	r11H

			lda	#$03
			rts

;*** GHV-Code $F2:Querverweis anzeigen.
:ExecDoLink		lda	C_LinkText		;Farbe für Linkverweis anzeigen.
			jsr	SetCodeColor

			lda	#$02			;2 Byte überlesen.
			jmp	ViewNxText

;*** GHV-Code $F3:Überschrift anzeigen.
:ExecTitel		lda	C_TopText		;Farbe für Titelzeile anzeigen.
			jsr	SetCodeColor

			lda	#$01			;1 Byte überlesen.
			jmp	ViewNxText

;*** GHV-Code $F4:Farbe anzeigen.
:ExecColor		ldy	#$01
			lda	(r15L),y		;Farbe anzeigen.
			jsr	SetCodeColor

			lda	#$02			;2 Byte überlesen.
			jmp	ViewNxText

;*** $F6:Farbe abschließen.
:ExecEndCol		bit	Flag_ColorActive	;Farbmodus aktiv ?
			bpl	:1			;Nein, weiter...
			jsr	DoColorText		;Farbe anzeigen.
::1			jmp	ViewNxChar

;*** Farbe für Querverweis/Überschrift/Farbtext ausgeben.
:DoColorText		ClrB	Flag_ColorActive	;Farbmodus löschen.

			bit	Flag_ColorText		;Darf Farbe gesetzt werden ?
			bmi	SetColEnd		;Nein, weiter...

			jsr	MoveToCard		;Zeiger auf nächstes CARD.
			jsr	PixelToCard		;Pixel nach CARD umrechnen.
			txa
			suba	ColData+0		;Anzahl FarbCARDS berechnen.
			sta	ColData+2
			beq	SetColEnd

			lda	r1H			;Y-Koordinate für Farbbereich
			sec
			sbc	#$06			;berechnen.
			lsr
			lsr
			lsr
			sta	ColData+1

			jsr	i_ColorBox
:ColData		b	$00,$00,$00,$01,$00
:SetColEnd		rts

;*** GHV-Code $F8:Farbblock zeichnen.
:ExecColBlk		lda	#$00
			sta	Flag_ColorActive

			jsr	MoveToCard		;Zeiger auf nächstes CARD.
			jsr	PixelToCard		;Pixel nach CARD umrechnen.
			stx	:2

			lda	r1H			;Y-Koordinate für Farbbereich
			sec
			sbc	#$06			;berechnen.
			lsr
			lsr
			lsr
			sta	:2 +1

			ldy	#$01
			lda	(r15L),y		;Farbe anzeigen.
			sta	:CountColor
			iny
::1			sty	:Vec_ColBlk

			lda	:CountColor
			beq	:3

			lda	(r15L),y		;Farbe anzeigen.
			jsr	i_UserColor
::2			b	$00,$00,$01,$01

			dec	:CountColor
			inc	:2

			ldy	:Vec_ColBlk
			iny
			bne	:1

::3			tya
			jmp	ViewNxText

::Vec_ColBlk		b $00
::CountColor		b $00

;*** GHV-Code $F9:Farbrechteck zeichnen.
:ExecColArea		lda	#$00
			sta	Flag_ColorActive

			jsr	MoveToCard		;Zeiger auf nächstes CARD.
			jsr	PixelToCard		;Pixel nach CARD umrechnen.
			stx	:2

			lda	r1H			;Y-Koordinate für Farbbereich
			sec
			sbc	#$06			;berechnen.
			lsr
			lsr
			lsr
			sta	:2 +1

			ldy	#$01
			lda	(r15L),y		;Farbe anzeigen.
			sta	:CountColor
			iny
::1			sty	:Vec_ColBlk

			lda	:CountColor
			beq	:3

			lda	(r15L),y		;Farbe anzeigen.
			sta	:2 +2
			iny
			lda	(r15L),y
			jsr	i_UserColor
::2			b	$00,$00,$01,$01

			lda	:2 +0
			clc
			adc	:2 +2
			sta	:2 +0

			dec	:CountColor

			ldy	:Vec_ColBlk
			iny
			iny
			bne	:1

::3			tya
			jmp	ViewNxText

::Vec_ColBlk		b $00
::CountColor		b $00

;*** GHV-Code $F5:Grafik anzeigen.
:ExecGrafx		jsr	GetIconAdr		;Startadr. Icon im RAM ermitteln.
			beq	:1			;Icon verfügbar ?

			PushW	r11			;Cursor-Position speichern.
			PushB	r1H

			jsr	SetCodeXCard		;X-Koordinate in CARDs
			stx	r1L			;umrechnen und zwischenspeichern.

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

::1			lda	#$02			;Nein, Icon überlesen.
			jsr	AddAto_r15
			jmp	ExecEndCol

;*** Startadresse Icon ermitteln.
:GetIconAdr		ldy	#$02
			lda	(r15L),y
			sta	r13H
			dey
			lda	(r15L),y
			sta	r13L
			sec
			sbc	#$01			;Zeiger aus Scrap im Speicher
			asl				;berechnen und auf $0000 testen.
			tax
			lda	IconAdrTab+0,x
			sta	r0L
			lda	IconAdrTab+1,x
			sta	r0H
			ora	r0L
			rts

;*** Position für Farbe setzen.
:SetCodeColor		sta	ColData+4		;Farbwert merken.

			LoadB	Flag_ColorActive,$ff	;Farbmodus aktiv.

			jsr	SetCodeXCard		;Cursor auf nächstes CARD.
			stx	ColData+0		;Startadr. für Farbe berechnen.
			rts

;*** X-Koordinate in CARDs umrechnen.
:SetCodeXCard		jsr	MoveToCard
			jmp	PixelToCard

;*** GHV-Code $F7: Blocksatz aktivieren.
:ExecBlock		lda	#$ff
			sta	Flag_AlignText
			lda	#$01			;2 Byte überlesen.
			jmp	ViewNxText

;*** Querverweis ausführen.
; - Zeiger auf Textzeile berechnen.
; - Innerhalb Zeile Link-Verweise suchen.
; - Prüfen ob Verweis angeklickt wurde.
; - =>Ja, ausführen, =>Nein, weitersuchen.
:ExecuteLink		NoMseKey

			MoveW	mouseXPos,r10		;X-Register merken.

			lda	mouseYPos		;Zeile berechnen.
			sec
			sbc	#$20
			lsr
			lsr
			lsr
			clc
			adc	LinePointer
			jsr	SetLineAdr		;Textzeile für Mausklick berechnen.

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

			ClrB	r12H			;Linkzähler löschen.

:L900c0			ldy	#$00
			lda	(r15L),y		;Zeichen aus Zeile einlesen.
			beq	L900c1			;Seitenende erreicht ? Ja, Ende...
			cmp	#$ff			;Blockende erreicht ?
			beq	L900c1			; => Ja, Ende...
			cmp	#CR			;Zeilenende erreicht ?
			bne	L900c2			;Nein, weiter...
:L900c1			rts

:L900c2			cmp	#$f0			;GHV-Steuercode ?
			bcs	L900d0			; => Ja, auswerten.

:L900c3			jsr	GetCharWidth		;Zeichenbreite ermitteln.

:L900c4			jsr	AddAto_r11		;X-Koordinate korrigieren.
			lda	#$01

:L900c5			jsr	AddAto_r15		;Zeiger auf nächstes Zeichen.
			jmp	L900c0

;*** GHV-Codes in Zeile überlesen.
;Überlesen der Codes um Querverweise
;innerhalb der aktuellen Textzeile zu
;finden.
:L900d0			cmp	#$f1			;Tabulator setzen ?
			bne	:1			;Nein, weiter...
			jsr	Do_SetTab		;Cursor auf neuen X-Wert setzen.
			jmp	L900c5

::1			cmp	#$f2			;Linkverweis setzen ?
			bne	:2			;Nein, weiter...
			ldy	#$01
			lda	(r15L),y		;Nr. des Links in
			sta	r12L			;Zwischenspeicher kopieren.
			LoadB	r12H,$ff		;Link-Modus aktiv.
			jsr	SetCodeXCard		;Zeiger auf nächstes CARD.
			MoveW	r11,r8			;Startadresse Linkbereich merken.
			lda	#$02
			jmp	L900c5

::2			cmp	#$f3			;Titel anzeigen ?
			bne	:3			;Nein, weiter...
			jsr	SetCodeXCard		;Zeiger auf nächstes CARD.
			lda	#$01
			jmp	L900c5

::3			cmp	#$f4			;Farbe anzeigen ?
			bne	:4			;Nein, weiter...
			jsr	SetCodeXCard		;Zeiger auf nächstes CARD.
			lda	#$02
			jmp	L900c5

::4			cmp	#$f5			;Grafik anzeigen ?
			bne	:6			;Nein, weiter...
			jsr	GetIconAdr		;Icon-Adresse einlesen.
			beq	:5			;Icon verfügbar ? Nein, weiter...
			jsr	SetCodeXCard		;Zeiger auf nächstes CARD.
			stx	r11L			;Cursor hinter Icon setzen.
			ldy	#$00
			sty	r11H
			lda	(r0L),y
			jsr	AddAto_r11
			jsr	CardToPixel
::5			lda	#$03
			jmp	L900c5

::6			cmp	#$f6			;Ende Link/Farbe erreicht ?
			bne	:9			;Nein, weiter...
			jsr	SetCodeXCard		;Zeiger auf nächstes CARD.
			bit	r12H			;Linkbereich abgeschlossen ?
			bmi	:8			;Ja Link gefunden ?
::7			lda	#$01
			jmp	L900c5

::8			CmpW	r10,r8			;Mausklick innerhalb des
			bcc	:7			;gefundenen Links ?
			CmpW	r10,r11
			bcs	:7
			jmp	DoLinkJob		; => Ja, Seite aufrufen.

::9			lda	#$01
			jmp	L900c5

;*** Andere Seite anzeigen.
:DoLinkJob		lda	StartGoto+0		;Zeiger auf Bereich Linkadressen.
			sta	r0L
			lda	StartGoto+1
			sta	r0H

			ClrB	r12H			;Zaähler für Linkadressen löschen.

::1			ldy	#$00
			lda	(r0L),y			;Zeichen aus Text einlesen.
			cmp	#$22			;Dateiname gefunden ?
			bne	:5			;Nein, weitersuchen.
			CmpB	r12L,r12H		;Dateiname für Link gefunden ?
			bne	:2			;Nein, Dateiname überlesen.
			jmp	DoLink			;Adresse gefunden, Seite aufrufen.

::2			inc	r12H			;Zähler für Dateinamen +1.

::3			lda	#$01
			jsr	AddAto_r0
			lda	(r0L),y
			beq	:4			;Textende erreicht ?
			cmp	#CR			;Zeilenende erreicht ?
			beq	:6			; => Ja, Nächsten Dateinamen suchen.
			cmp	#$ff			;Blockende erreicht ?
			bne	:3			;Nein, weitersuchen.
::4			rts				;Linkadresse nicht gefunden.

::5			cmp	#NULL			;Textende erreicht ?
			beq	:4			; => Ja, Fehler...
			cmp	#$ff			;Blockende erreicht ?
			beq	:4			; => Ja, Fehler...

::6			lda	#$01
			jsr	AddAto_r0
			jmp	:1

;*** Linkadresse gefunden.
:DoLink			ldx	HelpFileVec		;Zeiger innerhalb der Seite merken,
			dex				;um bei "Thema zurück" an diese
			lda	LinePointer		;Stelle im Text zurückzukehren.
			sta	HelpFileLine ,x

			ldy	#$00
			tya
			sta	LinePointer		;Zeiger auf Anfang der Seite.
::1			sta	NewHelpFile,y		;Dateinamenspeicher löschen.
			iny
			cpy	#$11
			bcc	:1

			lda	#$01
			jsr	AddAto_r0

			ldy	#$00
::2			lda	(r0L),y			;Dateiname in Zwischenspeicher.
			cmp	#$22
			beq	:4
			sta	NewHelpFile,y
			iny
			cpy	#$10
			bne	:2

::3			lda	(r0L),y
			cmp	#$22
			beq	:4
			iny
			bne	:3

::4			iny
			iny
			jsr	GetDezCode		;Seiten-Nr. einlesen.
			cmp	#$00			;Seite gültig ?
			beq	:5
			cmp	#62
			bcc	:6
::5			lda	#$01			;Seite ungültig, Seite #1 lesen.
::6			sec
			sbc	#$01			;Seite in Datensatz umrechnen.
			jmp	OpenNewPage		;Seite einlesen.

;*** Diskettenfehler anzeigen.
:GHV_FileErr		cpx	#$05			;Fehler: "File not found" ?
			beq	PageError		; => Ja, weiter...
			cpx	#$08			;Fehler: "Invalid Record" ?
			beq	PageError		; => Ja, weiter...
			cpx	#$ff			;Fehler: "Falsches Textformat" ?
			beq	PageError		; => Ja, weiter...

;*** GeoHelpView-Systemfehler.
:GHV_SysErr		jsr	SetOrgCol		;GEOS-Bildschirm zurücksetzen.

			ldx	#< Dlg_SysErrBox
			ldy	#> Dlg_SysErrBox
			jsr	DoSysDlgBox		;Diskettenfehler anzeigen.
			jmp	ExitHelp		;GeoHelpView beenden.

;*** Seite nicht verfügbar:
:PageError		ldy	#$00			;Dateiname der
::1			lda	NewHelpFile,y		;fehlerhaften Datei kopieren.
			beq	:2
			sta	FNF_1a,y
			sta	PNF_1a,y
			sta	FE_1a ,y
			iny
			cpy	#$10
			bcc	:1
::2			cpy	#$10
			beq	:3
			lda	#" "
			sta	FNF_1a,y
			sta	PNF_1a,y
			sta	FE_1a ,y
			iny
			bne	:2

::3			lda	curHelpPage
			clc
			adc	#$01
			ldy	#$30
::4			cmp	#10
			bcc	:5
			iny
			sec
			sbc	#$0a
			bcs	:4
::5			clc
			adc	#$30
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

;*** Fehlerseite erstellen.
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
			jsr	ViewHelpPage		;Zum Anfang der Seite und ausgeben.
			jmp	InitMenu

;*** Index aller Textdateien erstellen.
:LoadHelpIndex		NoMseKey

			lda	#$00
			sta	curHelpPage		;Nr. der Seite löschen.
			sta	LinePointer		;Zum Anfang der Seite gehen.

			jsr	i_FillRam		;Speicher für Hilfe-Seite löschen.
			w	TxtBufSize
			w	HelpTextMem
			b	$00

			jsr	i_FillRam
			w	(PageData_End - PageData_Start)
			w	PageData_Start
			b	$00

			LoadW	r6,HelpTextMem		;Name der neuen Hilfedatei merken.
			LoadB	r7L,APPL_DATA
			LoadB	r7H,255
			LoadW	r10,WriteImage
			jsr	FindFTypes
			txa
			pha

			LoadW	r0,HelpTextMem
			LoadW	r1,LoadAdress

			ldy	#$00			;Überschrift zu Seite
::1			lda	HelpTextIndex,y		;hinzufügen.
			beq	:2
			jsr	AddByte
			iny
			bne	:1

::2			pla				;Laufwerksfehler ?
			bne	:skip			; => Ja, Abbruch...

			lda	r7H			;Anzahl Textdokumente einlesen.
			cmp	#255			;Anzahl = Vorgabe 255 ?
			beq	:skip			; => Ja, keine Dateien gefunden...
			pha				;Anzahl Dokumente speichern.

			ldy	#$00
::3			lda	#"^"
			jsr	AddByte
			jsr	AddULine
			jsr	AddName
			jsr	AddPlain

			lda	#CR
			jsr	AddByte
			jsr	AddInfoText

			AddVBW	17,r0
			inc	r7H
			CmpBI	r7H,255
			bcc	:3

			jsr	AddPart

			pla				;Anzahl Dokumente
			sta	r7H			;zurücksetzen.

			LoadW	r0,HelpTextMem
::4			lda	#$22
			jsr	AddByte
			jsr	AddName
			lda	#$22
			jsr	AddByte
			lda	#","
			jsr	AddByte
			lda	#"0"
			jsr	AddByte
			lda	#"1"
			jsr	AddByte
			lda	#CR
			jsr	AddByte

			AddVBW	17,r0
			inc	r7H
			CmpBI	r7H,255
			bcc	:4

::skip			jsr	AddPart
			jsr	AddPart

			jsr	InitPageData

			lda	LinesInMem		;Scrollbalken initialisieren.
			sta	MoveBarData +3
			lda	LinePointer
			sta	MoveBarData +5

			jsr	PageInBuffer		;Aktuelle Seite in Stackspeicher.

			LoadW	r0,MoveBarData
			jsr	InitBalken		;Scrollbalken anzeigen.
			jmp	ViewHelpPage		;Zum Anfang der Seite/ausgeben.

;*** GeoWrite-Steuercodes erzeugen.
:AddPlain		lda	#"`"
			jmp	AddByte

:AddULine		lda	#"`"
			jsr	AddByte
			lda	#"1"

;*** Zeichen in GeoWrite-Seitenspeicher kopieren.
:AddByte		sty	:1 +1
			ldy	#$00
			sta	(r1L),y
			inc	r1L
			bne	:1
			inc	r1H
::1			ldy	#$ff
			rts

;*** GehoHelp-Steuercode "§§§" einfügen.
:AddPart		lda	#"§"
			jsr	AddByte
			jsr	AddByte
			jsr	AddByte
			lda	#CR
			jmp	AddByte

;*** Dateiname in Zielspeicher kopieren.
:AddName		ldy	#$00
::1			lda	(r0L),y
			beq	:2
			jsr	AddByte
			iny
			cpy	#$10
			bcc	:1
::2			rts

;*** Infotext in Zielspeicher übertragen.
:AddInfoText		PushW	r0
			PushW	r1
			PushB	r7H
			MoveW	r0,r6
			jsr	FindFile		;GeoWrite-Text suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Header einlesen.

::1			PopB	r7H
			PopW	r1
			PopW	r0
			txa				;Diskettenfehler ?
			bne	:4			; => Ja, Abbruch...

			lda	fileHeader +$a0		;Infotext gespeichert ?
			beq	:4			; => Nein, Ende...

			ldy	#$00			;Infotext in Zielspeicher kopieren.
::2			lda	fileHeader +$a0,y
			beq	:3
			jsr	AddByte
			iny
			bne	:2

::3			lda	#CR			;Zwei Leerzeilen einfügen.
			jsr	AddByte
			jmp	AddByte

::4			rts

;*** Neue Seite initialisieren.
; - Textseite einlesen
; - Rollbalken initialisieren
; - Seite in Seitenspeicher kopieren
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
			beq	:2			; => Ja, Abbruch...
::1			rts

::2			LoadW	r0,NewHelpFile
			jsr	OpenRecordFile		;Hilfedatei öffnen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			lda	curHelpPage		;Zeiger auf Seite.
			jsr	PointRecord
			cpx	#$00			;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.
			cpy	#$00			;Seite verfügbar ?
			bne	:4			; => Ja, weiter...
::3			jsr	CloseRecordFile
			ldx	#$08			;Fehler: "Invalid Record".
			rts

::4			LoadW	r7,LoadAdress
			LoadW	r2,TxtBufSize
			jsr	ReadRecord		;Seite einlesen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.

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

;*** Speicherauslastung berechnen.
;    Formel: (Belegter Speicher/16)  * 100
;            -----------------------------
;              (Max. freier Speicher/16)
;    Division durch 16 ist nötig, da sonst Werte über 65536 erreicht
;    werden und dann fehlerhafte Ergebnisse entstehen.
			sec				;Belegten Speicher berechnen.
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
			jsr	Ddiv			;Ergebnis durch max. Speicher
							;teilen.

			lda	r0L
			sta	UsedMem			;Prozent-Ergebnis merken.

			ldx	#$00			;Kein Fehler...
			rts

;*** Icondaten suchen.
;Beim konvertieren der Seite in das
;GHV-Format benötigt das Programm die
;Angaben über die Breite der auf der
;Seite enthaltenen Icons.
;Diese werden hier vorab eingelesen.
:CheckIcons		LoadW	r0,LoadAdress		;Zeiger auf Startadresse richten.
			LoadW	r1,IconAdrTab		;Zwischenspeicher für Icon-Daten.

::1			ldy	#$00
			lda	(r0L),y			;Zeichen einlesen.
			cmp	#NULL			;Ende erreicht ?
			beq	:2			; => Ja, Ende.
			cmp	#PAGE_BREAK		;Ende erreicht ?
			bne	:5			;Nein, weiter...
::2			rts				;Ende.

::3			ldx	#$01			;Zeiger auf nächstes Zeichen.
::4			txa				;Anz. Zeichen in xReg überspringen.
			jsr	AddAto_r0
			jmp	:1			;Nächstes Zeichen einlesen.

::5			ldx	#$04
			cmp	#NEWCARDSET		;Steuercode ?
			beq	:4			; => Ja, überspringen.
			ldx	#$1b
			cmp	#ESC_RULER		;Steuercode ?
			beq	:4			; => Ja, überspringen.
			ldx	#$01
			cmp	#FORWARDSPACE		;Steuercode ?
			beq	:4			; => Ja, überspringen.
			cmp	#ESC_GRAPHICS		;Steuercode ?
			bne	:3			;Nein, Zeichen übergehen.

			iny
			lda	(r0L),y			;Breite des Icons einlesen.
			dey
			sta	(r1L),y			;Breite in Tabelle eintragen.

			inc	r1L
			bne	:6
			inc	r1H

::6			ldx	#$05			;Steuercode übergehen.
			jmp	:4

;*** Seite konvertieren.
;    Um das Anzeigen der Textseite zu vereinfachen, werden die GeoWrite-
;    Steuercodes umgewandelt:
;
;GHV-Steuercode		Bytefolge
;--------------------------------------
;Tabulator		b $F1, xPos in Pixel									(Word!)
;Linkverweis		b $F2, Nr, Seite									(Nr = Tabelleneintrag, Seite = 1,2...)
;Titel erzeugen		b $F3
;Farbe setzen		b $F4, Farbe(Byte wie in COLOR_MATRIX)
;Grafik zeigen		b $F5, Nr, Zeile									(Nr = Tabelleneintrag, Zeile = 0,1...)
;Ende Link/Farbe	b $F6
;Blocksatz		b $F7
;Blockende		b $FF
;Textende		b $00
;--------------------------------------
;
;Die Textseite wird dabei umkopiert, von der Ladeadresse in den Text-
;Speicher. Notwendig da auch Zeichen eingefügt werden müssen und damit
;die Länge des Textes verändert wird.
;Um die Tabulator-Positionen zu bestimmen, wird die Zeile berechnet.

:ConvertPage		LoadW	r0,HelpFont		;GeoHelpView-Font aktivieren.
			jsr	LoadCharSet

			LoadB	currentMode,0

			lda	#<LoadAdress		;Zeiger auf Ladeadresse.
			sta	r0L
			lda	#>LoadAdress
			sta	r0H
			lda	#<HelpTextMem		;Zeiger auf Anfang Textspeicher.
			sta	r1L
			lda	#>HelpTextMem
			sta	r1H

			lda	#$00
			sta	r10H			;Anzahl Links/Text.
			sta	Flag_CodeActive		;Daten für Blocksatz löschen.
			sta	Flag_SpaceFound
			sta	Flag_StyleMode
			sta	Flag_StyleColor
			sta	Flag_StyleBold
			sta	Data_CountSpace

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

;--- Nächstes Zeichen einlesen.
:ConvNextByte		CmpWI	r11,$0130		;Rechter Rand erreicht ?
			bcc	:1			; => Nein, weiter...

			jsr	MakeWrapping		;Automatischer Zeilenumbruch.

::1			ldy	#$00
			lda	(r0L),y			;Zeichen aus Speicher einlesen.
			cmp	#$20			;Seutercode ?
			bcc	TestEndPage		; => Ja, weiter.
			bne	:2			; => Kein Leerzeichen, weiter...

			pha
			MoveW	r0,Data_PosLastSpcX
			MoveW	r1,Data_AdrLastSpc
			lda	#$ff
			sta	Flag_SpaceFound
			inc	Data_CountSpace
			pla

::2			cmp	#"`"			;GHV-Steuercode ?
			bne	:3			;Nein, weiter...
			jmp	MakeGHVcode		;GHV-Code erzeugen.

::3			cmp	#"§"			;Blockende ?
			bne	WrCharByte		;Nein, weiter...
			jmp	MakeEndBlock		;Blockende-Code erzeugen.

;--- Text-Zeichen in Zwischenspeicher kopieren.
:WrCharByte		pha				;Zeichen merken.
			jsr	GetCharWidth		;Zeichenbreite ermitteln.
			jsr	AddAto_r11		;Breite zu X-Koordinate addieren.
			pla

;--- Byte in Zwischenspeicher schreiben.
:WriteByte		jsr	StoreByte		;Aktuelles Byte in Textspeicher.
			lda	#$01			;Zeiger auf nächstes Zeichen.
:PosNextByte		jsr	AddAto_r0
			jmp	ConvNextByte

;*** GeoWrite-Steuercode auswerten.
:TestEndPage		cmp	#NULL			;Ende erreicht ?
			beq	:1			; => Ja, weiter...
			cmp	#PAGE_BREAK		;Ende erreicht ?
			bne	TestGWcode		;Nein, weitertesten.
::1			jsr	MakeEndStyle
			lda	#$00			;Textende markieren.
			jmp	StoreByte

;*** GeoWrite-Steuercode auswerten.
:TestGWcode		cmp	#NEWCARDSET		;Steuercode ?
			bne	:1			;Nein, weter...
			jmp	MakeStyle		;Code ignorieren.

::1			cmp	#FORWARDSPACE		;Steuercode ?
			bne	:2			;Nein, weter...
			jmp	MakeTab			;Tabulator erzeugen.

::2			cmp	#CR			;Steuercode ?
			bne	:3			;Nein, weter...
			jmp	MakeEOL			;Zeilenende erzeugen.

::3			cmp	#ESC_RULER		;Steuercode ?
			bne	:4			;Nein, weter...
			jmp	MakeTabData		;Tabulatordaten einlesen.

::4			cmp	#ESC_GRAPHICS		;Steuercode ?
			bne	:5			;Nein, weter...
			jmp	MakeGrafxData		;Grafikdaten einlesen.
::5			jmp	WrCharByte		;Zeichen übertragen.

;*** Byte in Zielseite übertragen.
:StoreByte		ldy	#$00
			sta	(r1L),y
			inc	r1L
			bne	:1
			inc	r1H
::1			rts

;*** Stilart erzeugen.
:MakeStyle		lda	#$04			;4 Byte überlesen.
			jmp	PosNextByte

;*** Tabulator erzeugen.
:MakeTab		bit	Flag_CodeActive		;GHV-Codes erzeugen ?
			bmi	:1			;Nein, Steuercode ignorieren.

			lda	#$f1
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.
			jsr	SetTabPos		;Neue X-Koordinate bestimmen.

			lda	r11L			;X-Koordinate direkt hinter
			jsr	StoreByte		;Steuercode zwischenspeichern.
			lda	r11H
			jsr	StoreByte

::1			lda	#$01			;1 Byte überlesen.
			jmp	PosNextByte

;*** Zeilenende kennzeichnen.
:MakeEOL		pha
			jsr	MakeEndStyle
			pla

			jsr	StoreByte		;Zeilenende in Speicher übertragen.

			lda	#$00
			sta	Flag_SpaceFound
			sta	Data_CountSpace
			sta	Flag_StyleColor

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

			jsr	MakeStyleMode

			lda	#$01			;1 Byte überlesen.
			jmp	PosNextByte

;*** Tabulator-Positionen speichern.
:MakeTabData		bit	Flag_CodeActive		;GHV-Codes erzeugen ?
			bmi	:3			;Nein, Steuercode ignorieren.

			ldy	#26			;Seiteninformationen in
::1			lda	(r0L),y			;Zwischenspeicher kopieren.
			sta	RulerData,y
			dey
			bpl	:1
			iny
			sty	Flag_StyleMode

			lda	RulerData +23
			and	#%00000011
			cmp	#%00000011		;Blocksatz in GW-Text ?
			bne	:2			; => Nein, weiter...
			dec	Flag_StyleMode		;Blocksatz aktivieren.

::2			lda	RulerData +21
			ora	RulerData +22		;Tabulator gesetzt ?
			bne	:4			; => Nein, weiter...

::3			lda	#$1b			;27 Bytes überlesen.
			jmp	PosNextByte

::4			ldy	#$00
::5			lda	RulerData + 1,y
			sec
			sbc	RulerData +21
			sta	RulerData + 1,y
			lda	RulerData + 2,y
			sbc	RulerData +22
			sta	RulerData + 2,y
			iny
			iny
			cpy	#21
			bcc	:5
			jmp	:3

;*** Grafikcode erzeugen.
:MakeGrafxData		ldx	#$00			;Steuercode "ESC_GRAPHICS"
::1			txa				;unverändert übernehmen.
			tay
			lda	(r0L),y
			jsr	StoreByte
			inx
			cpx	#$05
			bne	:1

			lda	#$05			;5 Bytes überlesen.
			jmp	PosNextByte

;*** Blockende kennzeichnen.
:MakeEndBlock		ldy	#$01			;Auf Blockende testen.
			cmp	(r0L),y			;(3x § - Zeichen ohne Leerzeichen!)
			bne	:1
			iny
			cmp	(r0L),y
			beq	:2
::1			jmp	WrCharByte		;Nicht gefunden, speichern.

::2			lda	#$ff
			sta	Flag_CodeActive
			jsr	StoreByte		;GHV-Code "Blockende" übertragen.

			lda	#$03			;3 Bytes überlesen.
			jmp	PosNextByte

;*** GHV-Codes erzeugen.
:MakeGHVcode		bit	Flag_CodeActive		;GHV-Codes erzeugen ?
			bmi	:1			;Nein, Steuercode ignorieren.

			iny
			lda	(r0L),y
			cmp	#"1"			;`1 = Link-verweis.
			beq	:2
			cmp	#"2"			;`2 = Titel erzeugen.
			beq	:3
			cmp	#"3"			;`3 = Farbe setzen.
			beq	:4
			cmp	#"4"			;`4 = Grafik anzeigen.
			beq	:5
			cmp	#"5"			;`4 = Grafik anzeigen.
			beq	:6
			cmp	#"6"			;`4 = Grafik anzeigen.
			beq	:7

;*** Ende GHV-Code markieren.
			bit	Flag_CodeActive		;GHV-Codes erzeugen ?
			bmi	:1			;Nein, Steuercode ignorieren.
			lda	#$00
			sta	Flag_StyleColor

			jsr	MoveToCard		;X-Koordinate korrigieren.
							;(Linkbereiche und Farbe immer
							; auf ganze CARD-Bereiche!)

			lda	#$f6			;Link-Verweise müssen mit einem `
			jsr	StoreByte		;beendet werden. Ersetzen durch $F6.

::1			lda	#$01			;1 Byte überlesen.
			jmp	PosNextByte

::2			jmp	MakeLink		;Link-Verweis erzeugen.
::3			jmp	MakeTitel		;Titel erzeugen.
::4			jmp	MakeColor		;Farbe erzeugen.
::5			jmp	MakeGrafx		;Grafik erzeugen.
::6			jmp	MakeColBlk		;Farbblock erzeugen.
::7			jmp	MakeColArea		;Farbblock erzeugen.

;*** Linkverweis erzeugen.
:MakeLink		jsr	MoveToCard		;X-Koordinate korrigieren.
							;(Linkbereiche beziehen sich immer
							; auf ganze CARD-Bereiche!)
			lda	#$f2
			jsr	StoreByte		;GHV-Code "Link-Verweis" übertragen.

			lda	r10H
			jsr	StoreByte		;Nr. des Links übertragen.
			inc	r10H			;Linkzähler +1.

			lda	#$02			;2 Byte überlesen.
			jmp	PosNextByte

;*** Titelfarbe erzeugen.
:MakeTitel		lda	#$f3
			jsr	StoreByte		;GHV-Code "Titel" übertragen.

			lda	C_TopText
			sta	Flag_StyleColor +1
			jsr	MakeStyleCols

			lda	#$02			;2 Byte überlesen.
			jmp	PosNextByte

;*** Farbe erzeugen.
:MakeColor		ldy	#$02
			jsr	GetHexCode		;HEX-Zahl einlesen.
			sta	Flag_StyleColor +1

			jsr	MakeStyleCols

			lda	#$04			;4 Byte überlesen.
			jmp	PosNextByte

;*** Farbbereich erzeugen.
:MakeColArea		lda	#$f9
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.

			lda	r1L
			sta	:2 +1
			sta	:3 +1
			lda	r1H
			sta	:2 +2
			sta	:3 +2

			lda	#$00
			jsr	StoreByte

			ldy	#$02
::1			sty	:Vec_ColBlk
			jsr	GetHexCode		;HEX-Zahl einlesen.
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.
::2			inc	$ffff

			ldy	:Vec_ColBlk
			iny
			iny
			lda	(r0L),y
			cmp	#"`"
			bne	:1

::3			lsr	$ffff

			iny
			tya
			jmp	PosNextByte

::Vec_ColBlk		b $00

;*** Farbblock erzeugen.
:MakeColBlk		lda	#$f8
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.

			lda	r1L
			sta	:2 +1
			lda	r1H
			sta	:2 +2

			lda	#$00
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.

			ldy	#$02
::1			sty	:Vec_ColBlk

			lda	(r0L),y
			cmp	#"`"
			beq	:3
			jsr	GetHexCode		;HEX-Zahl einlesen.
			jsr	StoreByte		;GHV-Code "Tabulator" übertragen.
::2			inc	$ffff

			ldy	:Vec_ColBlk
			iny
			iny
			bne	:1

::3			iny
			tya
			jmp	PosNextByte

::Vec_ColBlk		b $00

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

			lda	#$06			;6 Byte überlesen.
			jmp	PosNextByte

;*** Tabulatorposition setzen.
:SetTabPos		SubVW	8,r11

			ldy	#$06			;Ersten Tabulator suchen, der
::1			lda	RulerData,y		;größer ist als aktuelle Cursorpos.
			dey
			cmp	r11H
			bne	:2
			lda	RulerData,y
			cmp	r11L
::2			beq	:3
			bcs	:4
::3			iny
			iny
			iny
			cpy	#$15
			bne	:1
			AddVW	8,r11
			rts

::4			lda	RulerData+0,y		;Tabulator gesetzt (Nicht der Fall,
			ldx	RulerData+1,y		;wenn der Wert dem für den rechten
			cmp	RulerData+3		;Rand entspricht!)
			bne	:5
			cpx	RulerData+4
			beq	:6
::5			sta	r11L			;Neue Cursor-Position setzen.
			stx	r11H
::6			AddVW	8,r11
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

;*** Automatischer Zeilenumbruch.
:MakeWrapping		lda	Flag_SpaceFound
			ldx	#$00
			stx	Flag_SpaceFound
			tax
			beq	:1

			MoveW	Data_PosLastSpcX,r0
			MoveW	Data_AdrLastSpc,r1

			lda	#$01			;Zeiger auf nächstes Zeichen.
			jsr	AddAto_r0

::1			bit	Flag_StyleMode
			bpl	:2
			lda	#$f7
			jsr	StoreByte
::2			lda	#CR
			jsr	StoreByte		;Zeilenende in Speicher übertragen.

			jsr	SetXtoStart		;X-Koordinate auf Anfang.

;--- StyleModes fortsetzen.
:MakeStyleMode		bit	Flag_StyleColor
			bmi	MakeStyleCols
			rts

;--- Farbigen Text fortsetzen.
:MakeStyleCols		lda	#$ff
			sta	Flag_StyleColor

			jsr	MoveToCard		;X-Koordinate korrigieren.

			lda	#$f4
			jsr	StoreByte		;GHV-Code "Farbe" übertragen.
			lda	Flag_StyleColor +1
			jmp	StoreByte		;Farbe übertragen.

;--- StyleModes beenden.
:MakeEndStyle		bit	Flag_StyleColor
			bpl	:2
::1			lda	#$f6
			jmp	StoreByte
::2			rts

;*** Startadressen der Zeile berechnen.
:GetPageInfo		jsr	i_FillRam		;Speicher für Zeilenadr. löschen.
			w	512
			w	LineStartAdr
			b	$00

			lda	#$00
			sta	LinesInMem		;Anzahl Zeilen im Speicher löschen.

			LoadW	r0,HelpTextMem		;Zeiger auf Textanfang.
			LoadW	r1,LineStartAdr		;Zeiger auf Zeilenadressen.

;*** Neue Zeile beginnen.
::Info_NewPage		MoveW	r0,r2			;Anfang akt. Zeile merken.

;*** Nächstes Zeilenende suchen.
::1			ldy	#$00
			lda	(r0L),y			;Zeichen aus Speicher einlesen.
			bmi	:Info_ScriptCode	;GHV-Steuercode ? Ja, weiter...
			cmp	#" "			;GeoWrite-Steuercode ?
			bcc	:11			; => Ja, auswerten.
::2			lda	#$01			;Zeiger auf nächstes Zeichen.
::3			jsr	AddAto_r0
			jmp	:1			;Weitertesten.

;*** "NULL" oder "CR"-Code gefunden.
::11			cmp	#NULL			;Seitenende erreicht ?
			beq	:Info_EndPage		; => Ja, weiter...

			jsr	:12			;Zeilenanfang in Tabelle übertragen.

			lda	#$01
			jsr	AddAto_r0
			jmp	:Info_NewPage		;Neue Zeile testen.

::12			ldy	#$00			;Anfang der Aktuellen Zeile in
			lda	r2L			;Zeilenspeicher übertragen.
			sta	(r1L),y
			iny
			lda	r2H
			sta	(r1L),y
			AddVBW	2,r1
			inc	LinesInMem		;Zeiger auf nächsten Eintrag.
			rts

;*** Seitenende erreicht.
::Info_EndPage		jsr	:12			;Zeilenanfang in Tabelle übertragen.
			ldx	#$00			;Kein Fehler, OK.
			rts

;*** GHV-Code gefunden.
::Info_ScriptCode	jsr	GetCodeLen_r0		;Länge des GHV-Codes ermitteln.
			cpx	#$00			;Gültiger Code ?
			bne	:21			; => Ja, weiter...
			jmp	:2			;Zeichen unverändert übernehmen.

::21			cmp	#$ff			;Blockende erreicht ?
			beq	:22			; => Ja, weiter...
			txa				;GHV-Code überlesen.
			jmp	:3

::22			jmp	GetLinkAdr		;Linkverweise prüfen.

;*** Codelänge ermitteln.
:GetCodeLen_r0		ldx	#r0L
			b $2c
:GetCodeLen_r15		ldx	#r15L
			stx	:12 +1

			ldx	#$01			;GHV-Codes mit ein Byte Länge.
			cmp	#$f3
			beq	:2
			cmp	#$f6
			beq	:2
			cmp	#$f7
			beq	:2
			cmp	#$ff
			beq	:2
			inx				;GHV-Codes mit zwei Byte Länge.
			cmp	#$f2
			beq	:2
			cmp	#$f4
			beq	:2
			inx				;GHV-Codes mit drei Byte Länge.
			cmp	#$f1
			beq	:2
			cmp	#$f5
			beq	:2
			cmp	#$f8
			beq	:11
			cmp	#$f9
			beq	:21
::1			ldx	#$00			;GHV-Codes nicht erkannt.
::2			rts

::11			pha
			tya
			pha
			ldy	#$01
::12			lda	(r0L),y
			tax
			inx
			inx
			pla
			tay
			pla
			rts

::21			pha
			jsr	:11
			dex
			dex
			txa
			asl
			tax
			inx
			inx
			pla
			rts

;*** Linktabelle erzeugen.
:GetLinkAdr		lda	#$01
			jsr	AddAto_r0

			lda	r0L			;Blockende erreicht, Adresse für
			sta	StartGoto+0		;Querverweise merken.
			lda	r0H
			sta	StartGoto+1

::1			ldy	#$00
			lda	(r0L),y			;Zeichen aus Text einlesen.
			bne	:2			;Ende erreicht ? Nein, weiter...
			tax				; => Ja, $00 = Kein Fehler.
			rts

::2			cmp	#$ff			;Blockende erreicht ?
			beq	GetGrfxAdr		; => Ja, Icondaten einlesen.

			lda	#$01
			jsr	AddAto_r0
			jmp	:1

;*** Scraptabelle erzeugen.
;GeoHelpView holt alle Scraps der
;direkt in den Speicher damit diese
;später direkt angezeigt werden können.
:GetGrfxAdr		lda	#$01
			jsr	AddAto_r0

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

::1			ldy	#$00
			lda	(r14L),y		;Zeichen aus Text einlesen.
			beq	:2			;Seitenende ? Ja, Ende.
			cmp	#$ff			;Blockende = Seitenende erreicht ?
			bne	:3			;Nein, weiter...
::2			ldx	#$00			;$00 = Kein Fehler.
			rts

::3			cmp	#ESC_GRAPHICS		;Photoscrap-Eintrag gefunden ?
			beq	:11			; => Ja, weiter...

::4			inc	r14L
			bne	:5
			inc	r14H
::5			jmp	:1

;*** Photoscrap gefunden, einlesen.
::11			lda	r13H 			;Startadresse für Grafik in Tabelle.
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
			ldx	r15H
			cpx	#>EndMemory		;Speicher voll ?
			bcs	:12			; => Ja, Abbruch.

			inc	r13H
			CmpBI	r13H,64			;Max. Photoscrap #64 erreicht ?
			beq	:12			; => Ja, Ende...

			AddVBW	5,r14
			jmp	:1			;Nächstes Photoscrap suchen.

::12			ldx	#$00			;$00 = Kein Fehler.
			rts

;*** Rücksprungadresse sichern.
:ExitToRoutine		w $0000				;Rücksprungadresse (Programm).
:ExitToDA		w $0000				;Rücksprungadresse (Hilfsmittel).
:ExitToHelpPage		b $00

:Drive_System		b $00
:Drive_SPart		b $00
:Drive_Help		b $00

;*** Daten für Scrollbalken.
:MoveBarData		b $27,$20,$98,$00,$15,$00

;*** Variablen für Scrollbalken.
:SB_XPos		b $00				;r0L
:SB_YPos		b $00				;r0H
:SB_MaxYlen		b $00				;r1L
:SB_MaxEntry		b $00				;r1H
:SB_MaxEScr		b $00				;r2L
:SB_PosEntry		b $00				;r2H
:SB_PosTop		w $0000				;r3
:SB_Top			b $00				;r4L
:SB_End			b $00				;r4H
:SB_Length		b $00				;r5L

;*** Daten für Mausabfrage.
:Tab_MseSlctArea	b $b8,$bf
			w $0138,$013f,LastLine
			b $c0,$c7
			w $0138,$013f,NextLine
			b $20,$b7
			w $0137,$013f,MoveBar
			b $20,$c7
			w $0008,$012f,ExecuteLink
			b $00,$07
			w $0060,$00cf,LoadHelpIndex

;*** Maus-Fenstergrenzen.
:Tab_MseScrnArea	w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

;*** Farben.
:C_HelpText		b $b1				;Hilfefenster.
:C_HelpGround		b $01
:C_TopText		b $20				;Farbe für Überschriften.
:C_LinkText		b $50				;Farbe für Querverweise.
:B_GEOS_BACK		b $bf				;Farbe GEOS-Standard-Hintergrund.
:B_GEOS_FRAME		b $00				;Farbe GEOS-Standard-Frame.
:B_GEOS_MOUSE		b $06				;Farbe GEOS-Standard-Maus.

;*** Datenspeicher (Wird mit $00-Bytes vorbelegt)
:VariablenStart

;*** Zwischenspeicher für Systemwerte.
:b_dispBufferOn		b $00
:b_StringFaultVec	w $0000
:b_rightMargin		w $0000
:b_otherPressVec	w $0000
:b_RecoverVector	w $0000
:b_FrameColor		b $00
:b_MouseColor		b $00
:b_HelpSystem		b $00
:b_dlgBoxRamBuf		s 417

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
:LinePointer		b $00				;Darf nicht gelöscht werden!

:PageData_Start
:LineStartAdr		s 512
:LinesInMem		b $00
:StartGoto		w $0000
:StartIcon		w $0000
:StartFreeMem		w $0000
:IconAdrTab		s 128
:PageData_End

;*** Variablen für Aktuelle Textseite.
:UsedMem		b $00

;*** Variablen für Textausgabe.
:RulerData		s 32
:VarMaxXPos		w $0000
:Tab_SpacePosL		s 40
:Tab_SpacePosH		s 40
:Tab_SpaceWidth		s 40

:Flag_CodeActive	b $00
:Flag_ColorActive	b $00
:Flag_ColorText		b $00
:Flag_StyleMode		b $00
:Flag_AlignText		b $00
:Flag_StyleULine	b $00
:Flag_StyleBold		b $00
:Flag_StyleColor	b $00,$00
:Flag_MakeStyle		b $00

:Flag_SpaceFound	b $00
:Data_AdrLastSpc	w $0000
:Data_PosLastSpcX	w $0000
:Data_CountSpace	b $00

;*** Neues Textdokument öffnen.
:WriteImageLink		s 1+16+1+1+2+1			; "name",Nr(0)
:VariablenEnd

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
			w CallLastTheme

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

:icon_Warning
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

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_HELPSYS + RH_SIZE_HELPSYS -1
;******************************************************************************

;*** Speicher für Hilfeseite.
;    Beginnt immer ab $xy00 <= Wichtig!
:Memory
:HelpTextMem		= (Memory / 256 +1) * 256
:TxtBufSize		= EndMemory - HelpTextMem
