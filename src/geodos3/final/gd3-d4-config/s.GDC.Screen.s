; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DBOX"
endif

;*** GEOS-Header.
			n "GD.CONF.SCREEN"
			c "GDC.SCREEN  V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Anzeige konfigurieren"
endif
if Sprache = Englisch
			h "Configure display"
endif

;*** Variablen für Hintergrundbild-Routine.
:ByteCopyBuf		= BASE_DDRV_INIT		;s $08
:GrfxData		= BASE_DDRV_INIT +8		;s (640 * 2) + 8 + (80 * 2)

;*** Sprungtabelle.
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts

;*** Menü initialisieren.
:InitMenu		bit	firstBoot		;GEOS-BootUp ?
			bpl	:do_autoboot		; => Ja, automatisch installieren.
			bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	:0			; => Ja, keine Parameterübernahme.

;--- Hintergrundbild.
			lda	BackScrPattern
			sta	BootPattern

			lda	BootRAM_Flag
			and	#%11110111
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Modus für Hintergrundbild
			and	#%00001000		;aktualisieren.
			ora	BootRAM_Flag
			sta	BootRAM_Flag

;--- Bildschirmschoner.
			lda	Flag_ScrSaver		;Bildschirmschoner ein/aus.
			sta	BootScrSaver
			ldx	Flag_ScrSvCnt		;Bildschirmschoner Vrzögerung.
			stx	BootScrSvCnt

			and	#%10000000		;Bildschirmschoner aktiv?
			bne	:0			; => Nein, kein Name einlesen.
			jsr	GetScrSvName		;Name Bildschirmschoner einlesen.

::0			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

;--- AutoBoot
::do_autoboot		lda	BootPattern		;Füllmuster setzen.
			sta	BackScrPattern

			lda	sysRAMFlg		;Hintergrundbild-Modus.
			and	#%11110111
			sta	sysRAMFlg
			lda	BootRAM_Flag
			and	#%00001000
			ora	sysRAMFlg
			sta	sysRAMFlg
			sta	sysFlgCopy

::do_backscrn		jsr	LdBackScrn		;Hintergrundbild laden.

			bit	BootScrSaver
			bmi	:do_colsetup
			lda	BootSaverName		;Bildschirmschoner nachladen ?
			beq	:do_colsetup		; => Nein, weiter...

			LoadW	r6,BootSaverName	;Neuen Bildschirmschoner starten.
			jsr	InitScrSaver
			txa
			bne	:do_colsetup

			lda	BootScrSvCnt
			sta	Flag_ScrSvCnt
			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

::do_colsetup		jsr	i_MoveData
			w	 BootC_FarbTab
			w	 C_FarbTab
			w	(C_FarbTabEnd - C_FarbTab)
			rts

;*** Aktuelle Konfiguration speichern.
:SaveConfig		jsr	i_MoveData
			w	C_FarbTab
			w	BootC_FarbTab
			w	(C_FarbTabEnd - C_FarbTab)

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;******************************************************************************
;*** Bildschirmschoner-Routinen.
;******************************************************************************
;*** Bezeichnung des Bildschirmschoner einlesen.
:GetScrSvName		jsr	SwapRAM_ScrSaver	;Bildschirmschoner einlesen.

			LoadW	r0,LD_ADDR_SCRSAVER +6
			LoadW	r1,BootSaverName
			ldx	#r0L
			ldy	#r1L			;Name des ScreenSavers in
			jsr	CopyString		;Konfigurationstabelle übernehmen.

			jmp	SwapRAM_ScrSaver	;Speicher zurücksetzen.

;*** Modus für Bildschirmschoner wechseln.
:Swap_ScrSaver		lda	BootSaverName		;Bildschirmschoner definiert?
			beq	GetNoScrSaver		; => Nein, abschalten.

			lda	Flag_ScrSaver		;Modus Bildchirmschoner in
			and	#%10000000		;Boot-Konfiguration übernehmen.
			sta	BootScrSaver		;Bildschirmschone abgeschaltet?
			bne	:exit			; => Ja, weiter...

;--- Ergänzung: 16.02.21/M.Kanet
;Prüfen ob der angezeigte Bildschirm-
;schoner bereits geladen wurde.
;Sonst nachladen, bei Fehler abbrechen.
			jsr	Verify_ScrSvNam		;Name Bildschirmschoner prüfen.
			beq	:exit			;Ist im Speicher, weiter...

			jsr	GetScrSvFile		;Bildschirmschoner laden.
			txa				;Fehler?
			bne	GetNewScrSaver		; => Ja, Neu laden.

::exit			rts

;*** Name Bildschirmschoner prüfen.
:Verify_ScrSvNam	jsr	SwapRAM_ScrSaver	;Bildschirmschoner einlesen.

			ldy	#$00
::1			lda	LD_ADDR_SCRSAVER +6,y
			beq	:ok
			cmp	BootSaverName,y
			bne	:not_found
			iny
			cpy	#$10
			bcc	:1

::ok			lda	#NO_ERROR
			b $2c
::not_found		lda	#FILE_NOT_FOUND

			pha
			jsr	SwapRAM_ScrSaver	;Speicher zurücksetzen.
			pla
			tax
			rts

;*** Neuen Bildschirmschoner laden.
:GetNewScrSaver		LoadB	r7L,SYSTEM
			LoadW	r10,Class_ScrSaver
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			bne	GetNoScrSaver		; => Ja, Ende...

			LoadW	r0,dataFileName		;Name des ScreenSavers in
			LoadW	r1,BootSaverName	;Konfigurationstabelle übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Bildschirmschoner laden.
:GetScrSvFile		LoadW	r6,BootSaverName
			jsr	InitScrSaver		;Neuen ScreenSaver installieren.
			txa				;Diskettenfehler ?
			bne	GetNoScrSaver		; => Nein, weiter...

			lda	#%01000000		;ScreenSaver neu starten.
			sta	Flag_ScrSaver

;--- Ergänzung: 16.02.21/M.Kanet
;Name muss nicht eingelesen werden, da
;der Name der Bildschirmschoners dem
;Dateinamen entsprechen muss und dieser
;ist bereits definiert.
;			jsr	GetScrSvName		;Name Bildschirmschoner einlesen.
			jmp	UpdateScrSvOpt		;Registermenü aktualisieren.

;*** Bildschirmschoner abschalten.
;--- Ergänzung: 20.07.18/M.Kanet
;Abschalten durch setzen von Bit#7!
:GetNoScrSaver		lda	#%10000000		;Bildschirmschoner abschalten und
			sta	Flag_ScrSaver		;Konfiguration speichern.
			sta	BootScrSaver
			lda	#NULL			;Name Bildschirmschoner
			sta	BootSaverName		;löschen.

;*** Registermenü aktualisieren.
:UpdateScrSvOpt		LoadW	r15,RegTMenu_1a
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu_1b
			jmp	RegisterUpdate

;*** Bildschirmschoner testen.
;    Dazu wird der Zähler im ":Flag_ScrSaver" gelöscht, was beim nächsten
;    Interrupt den Bildschirmschoner startet.
:StartScrnSaver		lda	r1L			;Register-Grafikaufbau ?
			beq	:exit			; => Ja, Ende...

::wait			bit	mouseData		;Maustaste gedrückt ?
			bpl	:wait			; => Ja, warten bis keine Maustaste.

;--- Ergänzung: 01.07.18/M.Kanet
;Das testen funktioniert nicht wenn der
;Bildschirmschoner deaktiviert ist.
			bit	Flag_ScrSaver		;Bildschirmschoner aktiv?
			bmi	:exit			; => Nein, Ende...

;--- Ergänzung: 16.02.21/M.Kanet
;Bildschirmschoner testen. Wenn die
			php				;IRQ sperren um den Bildschirm-
			sei				;schoner einzulesen und zu starten.
			jsr	SwapRAM_ScrSaver	;Bildschirmschoner einlesen.
			jsr	LD_ADDR_SCRSVINIT	;Starten...
			txa
			pha
			jsr	SwapRAM_ScrSaver	;Speicher zurücksetzen.
			pla
			tax				;Fehler-Register zurücksetzen.
			plp

			cpx	#NO_ERROR		;Test erfolgreich?
			beq	:start_ScrSv		; => Ja, weiter...

			LoadW	r0,Dlg_ScrSvErr		;Fehlermeldung ausgeben.
			jsr	DoDlgBox

			jmp	GetNoScrSaver		;Bildschirmschoner abschalten.

;--- Bildschirmschoner starten.
::start_ScrSv		lda	#%00000000		;Zähler löschen und
			sta	Flag_ScrSaver		;Bildschirmschoner starten.
::exit			rts

;******************************************************************************
;*** Bildschirmschoner-Routinen.
;******************************************************************************
;*** Neuen Wert für ScreenSaver eingeben.
:Swap_ScrSvDelay	lda	r1L			;Register-Grafikaufbau ?
			beq	Draw_ScrSvDelay		; => Ja, weiter...

			jsr	DefMouseXPos		;Neuen Wert für Aktivierungszeit
			cmp	#1
			bcs	:1
			lda	#1
::1			sta	Flag_ScrSvCnt		;berechnen.
			sta	BootScrSvCnt

;--- Ergänzung: 01.07.18/M.Kanet
;in der MegaPatch/2003-Version von 1999-2003 wurde hier der Bildschirmschoner
;grundsätzlich neu gestartet, auch wenn dieser deaktiviert war.
			lda	Flag_ScrSaver		;ScreenSaver initialisieren.
			ora	#%01000000		;Dabei nur das "Initialize"-Bit
			sta	Flag_ScrSaver		;setzen, das "On/Off"-Bit#7 nicht
							;löschen, da sonst der Bildschirm-
							;schoner auch eingeschaltet wird.

;*** Verzögerungszeit für ScreenSaver festlegen.
:Draw_ScrSvDelay	lda	C_InputField		;Farbe für Schieberegler setzen.
			jsr	DirectColor

			jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_06
			b	$09,$90,Icon_06x,Icon_06y

			ldx	#$09			;Position für Schieberegler
			lda	Flag_ScrSvCnt		;berechnen.
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff
			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_ScrSvCnt		;berechnen.
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx
::3			stx	:6 +2

			ldx	#<Icon_08		;Typ für Regler-Icon ermitteln.
			ldy	#>Icon_08
			lda	Flag_ScrSvCnt
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#<Icon_07		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#>Icon_07
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_06
::6			b	$0c,$93,$ff,$05

;*** Aktivierungszeit anzeigen.
:Draw_ScrSvTime		LoadW	r0, RegTText_1_03 + 6

			lda	Flag_ScrSvCnt		;Aktivierungszeit in Minuten und
			asl				;Sekunden umrechnen.
			asl
			clc
			adc	Flag_ScrSvCnt
			ldx	#$00
::1			cmp	#60
			bcc	:2
			sec
			sbc	#60
			inx
			bne	:1
::2			jsr	SetDelayTime

			LoadB	currentMode,$00
			LoadW	r0,RegTText_1_03
			jsr	PutString		;Aktivierungszeit anzeigen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;******************************************************************************
;*** Bildschirmschoner-Routinen.
;******************************************************************************
;*** Zahl nach ASCII wandeln.
:SetDelayTime		pha
			txa
			ldy	#$01
			jsr	:1
			pla

::1			ldx	#$30
::2			cmp	#10
			bcc	:3
			inx
			sbc	#10
			bcs	:2
::3			adc	#$30
			sta	(r0L),y
			dey
			txa
			sta	(r0L),y
			iny
			iny
			iny
			iny
			rts

;*** Maus-Position für Schieberegler definieren.
:DefMouseXPos		lda	mouseXPos
			sec
			sbc	#< $0048
			lsr
			lsr
			rts

;*** Neuen Bildschirmschoner installieren.
;    r6 = Zeiger auf Dateiname.
:InitScrSaver		jsr	FindSysFile		;Datei suchen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

			jsr	SwapRAM_ScrSaver	;RAM im Bereich ScreenSaver
							;zwischenspeichern.
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r2,R2_SIZE_SCRSAVER
			LoadW	r7,LD_ADDR_SCRSAVER
			jsr	ReadFile		;ScreenSaver einlesen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch...

			jsr	LD_ADDR_SCRSVINIT	;ScreenSaver initialisieren.
;--- Ergänzung: 20.07.18/M.Kanet
;In der MegaPatch/2003-Version wurde nicht auf Initialisierungsfehler
;geprüft. 64erMove kann z.B. nicht verwendet werden wenn kein freier
;Speicher verfügbar ist.
			txa				;Initialisierung OK?
			beq	:1			; => Ja, Ende..

			LoadW	r0,Dlg_ScrSvErr		;Fehlermeldung ausgeben.
			jsr	DoDlgBox

			jsr	GetNoScrSaver		;Bildschirmschoner abschalten.

			ldx	#FILE_NOT_FOUND		;Fehlerstatus setzen.
::1			txa
			pha
			jsr	SwapRAM_ScrSaver	;ScreenSaver in ext.RAM kopieren.
			pla
			tax				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Ergänzung: 16.02.21/M.Kanet
;Sicherstellen das Bildschirmschoner
;in das externe RAM geladen wurde.
			jsr	Verify_ScrSvNam		;Name Bildschirmschoner prüfen.
;			txa				;Fehler?
;			beq	:exit			; => Nein, OK...

::err			rts

;*** Aktuellen Bildschirmschoner einlesen.
:SwapRAM_ScrSaver	jsr	SetADDR_ScrSaver
			jmp	SwapRAM

;******************************************************************************
;*** Hintergrundbild-Routinen.
;******************************************************************************
;*** Modus für Hintergrund wechseln.
:Swap_BackScrn		lda	BootGrfxFile		;Hintergrundbild definiert?
			beq	GetNoBackScrn		; => Nein, abschalten...

			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			bne	GetNoBackScrn		; => Nein, weiter...
			jmp	GetBackScrFile		; => Ja, Hintergrundbild laden.

;*** Neues Hintergrundbild laden.
:GetNewBackScrn		LoadB	r7L,APPL_DATA
			LoadW	r10,Class_GeoPaint
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler / Abbruch ?
			bne	SetNoBackScrn		; => Ja, Ende...

			LoadW	r0,dataFileName		;Name des ScreenSavers in
			LoadW	r1,BootGrfxFile		;Konfigurationstabelle übernehmen.
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Bildschirmgrafik einlesen.
:GetBackScrFile		lda	sysRAMFlg
			ora	#%00001000
			sta	sysRAMFlg
			sta	sysFlgCopy
			lda	BootRAM_Flag
			ora	#%00001000
			sta	BootRAM_Flag

;*** Grafik von Diskette einlesen und speichern.
:GetScrnFromDisk	jsr	LdScrnFrmDisk
			jsr	DrawCfgMenu
			jmp	RegisterInitMenu

;*** Hintergrundbild löschen.
;--- Ergänzung: 13.01.19/M.Kanet
;Wenn die Auswahl des Hintergrundbildes
;abgebrochen wurde, dann auch das
;Hintergrundbild deaktivieren.
:SetNoBackScrn		lda	#NULL
			sta	BootGrfxFile

:GetNoBackScrn		lda	BootRAM_Flag		;Startbild nicht gefunden,
			and	#%11110111		;Kein Hintergrundbild verwenden.
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Achtung! ":BootRAM_Flag" und
			and	#%11110111		;sysRAM_Flag getrennt bearbeiten,
			sta	sysRAMFlg		;da diese Routine auch im laufwenden
			sta	sysFlgCopy		;da diese Routine auch im laufwenden
			jsr	DrawCfgMenu
			jmp	RegisterInitMenu

;*** Aktuelles Hintergrundbild anzeigen.
:PrintCurBackScrn	lda	r1L			;Aufbau Registermenü ?
			beq	:1			; => Ja, Ende...
			lda	sysRAMFlg
			and	#%00001000		;Hintergrundbild aktiv ?
			beq	:1			; => Nein, weiter...
			LoadW	r0,Dlg_GetBScrn
			jmp	DoDlgBox		;Hintergrundbild anzeigen.
::1			rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Hintergrundgrafik darstellen.
;    Boot-Vorgang :	Grafik von Diskette nachladen.
;    Programmstart:	Grafik aktiv ? Ja  => Grafik aus RAM einlesen.
;				               Nein=> Füllmuster ausgeben.
:LdBackScrn		bit	firstBoot		;GEOS-BootUp ?
			bmi	LdBootScrn		; => Nein, weiter...

			lda	BootRAM_Flag		;Statusbyte einlesen.
			and	#%00001000		;Hintergrundbild laden ?
			beq	StdClrScrn		; => Nein, weiter...
			jmp	LdScrnFrmDisk		;Hintergrundbild von Disk einlesen.

;*** Hintergrundgrafik aus RAM / Füllmuster darstellen.
:LdBootScrn		lda	sysRAMFlg		;Statusbyte einlesen.
			and	#%00001000		;Hintergrundbild laden ?
			beq	StdClrScrn		; => Nein, weiter...

			lda	#ST_WR_FORE		;Nur Vordergrund-Bildschirm.
			sta	dispBufferOn
			jmp	GetBackScreen		;Hintergrundbild von Ram einlesen.

;*** Bildschirm (Farbe/Grafik) löschen.
:StdClrScrn		lda	screencolors		;Farben löschen.
			jsr	i_UserColor
			b	$00,$00,$28,$19

			lda	BackScrPattern		;Bildschirm löschen.
			jsr	SetPattern

;*** Bildschirm (nur Grafik) löschen.
:StdClrGrfx		lda	#ST_WR_FORE		;Nur Vordergrundgrafik.
			sta	dispBufferOn
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f
			rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Hintergrundbild einlesen.
;    Name muss in ":BootGrfxFile" übergeben werden!
:LdScrnFrmDisk		lda	BootGrfxFile		;Name definiert ?
			beq	NoBackScrn		; => Nein, kein Startbild.

			LoadW	r6 ,BootGrfxFile
			jsr	FindSysFile		;Startbild auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	NoBackScrn		; => Ja, kein Startbild.

			php				;Hintergrundfarbe löschen.
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	$d020
			sta	r0L
			lsr	r0L
			rol
			lsr	r0L
			rol
			lsr	r0L
			rol
			lsr	r0L
			rol

			stx	CPU_DATA
			plp

			jsr	i_UserColor
			b	$00 ,$00,$28,$19

			jsr	ViewPaintFile		;Hintergrundbild anzeigen.
			txa				;Diskettenfehler ?
			beq	SvBackScrn		; => Nein, Startbild speichern.

			jsr	NoBackScrn		;Hintergrundbild abschalten und
							;Standardgrafik speichern.

;*** Hintergrundgrafik speichern.
;    Grafik wird immer aus der REU eingelesen! Ist keine "Grafik" aktiv,
;    wird der Hintergrund durch ein Füllmuster definiert und diese Grafik
;    als Hintergrundgrafik gespeichert.
:SvBackScrn		lda	MP3_64K_SYSTEM		;Zeiger auf MP3-Systembank.
			sta	r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_BS_GRAFX
			LoadW	r2,R2_SIZE_BS_GRAFX
			jsr	StashRAM		;Grafik speichern.
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_BS_COLOR
			LoadW	r2,R2_SIZE_BS_COLOR
			jmp	StashRAM		;Farben speichern.

;*** Kein Startbild, Hintergrund löschen.
:NoBackScrn		lda	BootRAM_Flag		;Startbild nicht gefunden,
			and	#%11110111		;Kein Hintergrundbild verwenden.
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Achtung! ":BootRAM_Flag" und
			and	#%11110111		;sysRAM_Flag getrennt bearbeiten,
			sta	sysRAMFlg		;da diese Routine auch im laufenden
			sta	sysFlgCopy		;GEOS-Betrieb aufgerufen wird!
			jmp	StdClrScrn

;*** Neue Datei anzeigen.
:ViewPaintFile		LoadW	r0,BootGrfxFile
			jsr	OpenRecordFile
			txa
			bne	:53

			LoadW	r14,SCREEN_BASE
			LoadW	r15,COLOR_MATRIX

			lda	#0
::51			sta	a9H

			jsr	Get80Cards
			jsr	Prnt_Grfx_Cols

			inc	a9H
			lda	a9H
			cmp	usedRecords
			bcs	:52
			cmp	#13
			bcc	:51
::52			ldx	#NO_ERROR
::53			txa
			pha
			jsr	CloseRecordFile
			pla
			tax
			rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Grafikdaten ausgeben.
:Prnt_Grfx_Cols		lda	#<GrfxData +   0
			ldx	#>GrfxData +   0
			jsr	MoveGrfx
			lda	#<GrfxData +1288
			ldx	#>GrfxData +1288
			jsr	MoveCols

			lda	a9H			;12*2 +1 Zeilen.
			cmp	#12
			bcs	:51

			lda	#<GrfxData + 640
			ldx	#>GrfxData + 640
			jsr	MoveGrfx
			lda	#<GrfxData +1368
			ldx	#>GrfxData +1368
			jmp	MoveCols

::51			rts

;*** Grafikdaten in Bildschirm kopieren.
:MoveGrfx		sta	r0L
			stx	r0H
			MoveW	r14,r1
			AddVW	320,r14
			LoadW	r2 ,$0140
			jmp	MoveData

;*** Grafikdaten in Bildschirm kopieren.
:MoveCols		sta	r0L
			stx	r0H
			MoveW	r15,r1
			AddVW	40 ,r15
			LoadW	r2 ,$0028
			jmp	MoveData

;*** Eine Grafikzeile (80 Cards/8 Pixel hoch) einlesen.
:Get80Cards		jsr	PointRecord
			txa
			bne	NoGrfxData
			tya
			bne	LoadVLIR_Data

:NoGrfxData		jsr	i_FillRam
			w	1280
			w	GrfxData +   0
			b	$00
			jsr	i_FillRam
			w	160
			w	GrfxData +1288
			b	$bf
			rts

;*** Grafikbytes aus Datensatz einlesen.
:LoadVLIR_Data		LoadW	r4,diskBlkBuf		;Zeiger auf Diskettenspeicher.
			jsr	GetBlock		;Ersten Sektor des aktuellen
			txa				;Datensatzes einlesen. Fehler ?
			bne	NoGrfxData		;Nein, weiter...

			LoadW	r0 ,GrfxData		;Zeiger auf Grafikdatenspeicher.

			ldx	#$01			;Zeiger auf erstes Byte in Datei.
			stx	r5H
:GetNxDataByte		jsr	GetNxByte		;Nächstes Byte einlesen.
			sta	r2H			;Byte zwischenspeichern.

			ldy	#$00
			bit	r2H			;Gepackte Daten ?
			bmi	GetPackedBytes		;Ja, weiter...

			lda	r2H
			and	#$3f			;Anzahl Bytes ermitteln.
			beq	EndOfData		;$00 = Keine Daten.
			sta	r2H			;Anzahl Bytes merken.
			bvs	Repeat8Byte		;Bit #6 = 1, 8-Byte-Packformat.

::51			jsr	GetNxByte		;Byte einlesen und in Grafikdaten-
			sta	(r0L),y			;speicher kopieren.
			iny
			cpy	r2H			;Alle Bytes gelesen ?
			bne	:51			;Nein, weiter...

;*** Zeiger auf Grafikdatenspeicher korrigieren.
:SetNewMemPos		tya				;Zeiger auf Grafikdatenspeicher
			clc				;korrigieren.
			adc	r0L
			sta	r0L
			bcc	GetNxDataByte
			inc	r0H
			bne	GetNxDataByte		;Nächstes Byte einlesen.
:EndOfData		rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** 8-Byte-Daten wiederholen.
:Repeat8Byte		jsr	GetNxByte		;Nächstes Byte aus Datensatz
			sta	ByteCopyBuf,y		;einlesen und in Zwischenspeicher.
			iny				;Zeiger auf nächstes Byte.
			cpy	#$08			;8 Byte eingelesen ?
			bne	Repeat8Byte		;Nein, weiter...

			ldx	#$00
::51			ldy	#$07			;8 Byte in Grafikdatenspeicher.
::52			lda	ByteCopyBuf,y
			sta	(r0L),y
			dey
			bpl	:52

			lda	r0L			;Zeiger auf Grafikdatenspeicher
			clc				;korrigieren.
			adc	#$08
			sta	r0L
			bcc	:53
			inc	r0H

::53			inx				;Anzahl Wiederholungen +1.
			cpx	r2H			;Wiederholungen beendet ?
			bne	:51			;Nein, weiter...
			beq	GetNxDataByte		;Weiter mit nächstem Byte.

;*** Gepackte Daten einlesen.
:GetPackedBytes		lda	r2H			;Anzahl gepackte Daten berechnen.
			and	#$7f
			beq	EndOfData		;$00 = Keine Daten, Ende...
			sta	r2H			;Anzahl Bytes merken.
			jsr	GetNxByte		;Datenbyte einlesen.

			ldy	r2H
			dey				;Byte in Grafikdatenspeicher
::51			sta	(r0L),y			;kopieren (Anzahl in ":r2H")
			dey
			bpl	:51

			ldy	r2H			;Zeiger auf Grafikdatenspeicher
			bne	SetNewMemPos		;korrigieren.

;*** Nächstes Byte aus Paint-Datei einlesen.
:GetNxByte		ldx	r5H
			inx
			bne	RdBytFromSek
			lda	r1L
			bne	GetNxSektor
:GetByteError		pla
			pla
			rts

;*** Nächsten Sektor aus Paint-Datensatz einlesen.
:GetNxSektor		lda	diskBlkBuf +$00
			sta	r1L
			lda	diskBlkBuf +$01
			sta	r1H
			sty	a9L
			jsr	GetBlock		;Sektor einlesen.
			ldy	a9L
			txa				;Diskettenfehler ?
			beq	:51			;Ja, Abbruch...
			pla
			pla
			jmp	GetNoBackScrn

::51			ldx	#$02			;Zeiger auf erstes Byte in Sektor.

;*** Nächstes Byte aus Sektor einlesen.
:RdBytFromSek		lda	r1L
			bne	:51
			cpx	r1H
			bcc	:51
			beq	:51
			bne	GetByteError
::51			lda	diskBlkBuf +$00,x	;Byte aus Sektor einlesen.
			stx	r5H			;Bytezeiger speichern.
			rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Hintergrundbild auf Diskette suchen.
:FindSysFile		lda	SystemDevice
			jsr	SetDevice
			jsr	FindGPfile		;Hintergrundbild suchen.
			txa				;Diskettenfehler ?
			beq	:6			; => Nein, weiter...

;--- Auf allen Laufwerken nach erstem Treiber suchen.
::1			ldx	#8			;Suche initialisieren.
::2			cpx	SystemDevice		;Systemlaufwerk untersuchen ?
			beq	:4			; => Ja, übergehen.

			lda	driveType -8,x		;Ist Laufwerk definiert ?
			beq	:4			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, nächstes Laufwerk.

			jsr	FindGPfile		;Hintergrundbild suchen.
			txa				;Diskettenfehler ?
			beq	:6			; => Nein, weiter...

::3			ldx	curDrive		;Aktuelles Laufwerk einlesen.
::4			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke durchsucht ?
			bcc	:2			; => Nein, weiter...

::5			ldx	#FILE_NOT_FOUND
			rts
::6			ldx	#NO_ERROR
			rts

;*** Druckertreiber-Datei uchen.
:FindGPfile		PushW	r6
			jsr	FindFile		;Hintergrundbild suchen.
			PopW	r6
			rts

;******************************************************************************
;*** Hintergrundmuster wechseln.
;******************************************************************************
;*** Zeiger auf nächstes Füllmuster.
:SetNxBackPattern	lda	BootPattern
			clc
			adc	#$01
			cmp	#32
			bcc	:1
			lda	#$00
::1			sta	BackScrPattern
			sta	BootPattern
			rts

;*** Füllmuster anzeigen.
:PrintCurPattern	lda	BackScrPattern
			jsr	SetPattern
			jsr	i_Rectangle
			b	$98,$a7
			w	$0058,$011f
			rts

;******************************************************************************
;*** Systemfarben wechseln.
;******************************************************************************
:PrintCurColName	PushW	r11

			lda	Vec2Color
			asl
			asl
			tax
			lda	Vec2ColNames +0,x
			sta	r0L
			lda	Vec2ColNames +1,x
			sta	r0H
			jsr	PutString

			PopW	r11
			AddVB	8,r1H

			lda	Vec2Color
			asl
			asl
			tax
			lda	Vec2ColNames +2,x
			sta	r0L
			lda	Vec2ColNames +3,x
			sta	r0H
			jsr	PutString

;*** Aktuelle Farbeinstellungen anzeigen.
:UpdateCurColor		LoadW	r15,RegTMenu_3a
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu_3b
			jmp	RegisterUpdate

;*** Zeiger auf nächsten Bereich.
:NextColEntry		ldx	Vec2Color
			inx
			cpx	#22
			bcc	:1
			ldx	#$00
::1			stx	Vec2Color
			rts

;*** Zeiger auf letzten Bereich.
:LastColEntry		ldx	Vec2Color
			bne	:1
			ldx	#22
::1			dex
			stx	Vec2Color
			rts

;*** Aktuellen Farbwert für Text ausgeben.
:PrintCurColorT		ldx	Vec2Color
			lda	C_FarbTab,x
			lsr
			lsr
			lsr
			lsr
			jmp	DirectColor

;*** Aktuellen Farbwert für Hintergrund ausgeben.
:PrintCurColorB		ldx	Vec2Color
			lda	C_FarbTab,x
			and	#%00001111
			jmp	DirectColor

;*** Farbtabelle Text/Hintergrund ausgeben.
:ColorInfoT		lda	r1L
			bne	SetColorT
			lda	#$0f
			bne	ColorInfo

:ColorInfoB		lda	r1L
			bne	SetColorB
			lda	#$14
:ColorInfo		sta	:2 +1

			lda	#$0f
			sta	:2 +0

			ldx	#$00
::1			txa
			pha
			lda	ColorTab,x
			jsr	i_UserColor
::2			b	$00,$11,$01,$01
			inc	:2 +0
			pla
			tax
			inx
			cpx	#$10
			bne	:1
			rts

;******************************************************************************
;*** Systemfarben wechseln.
;******************************************************************************
;*** Neue Textfarbe setzen.
:SetColorT		jsr	SetColor
			lda	ColorTab,x
			sta	r0L
			lda	Vec2Color
			asl
			tax
			lda	ColModifyTab +0,x
			and	#%11110000
			beq	:1
			jsr	Add1High
::1			lda	Vec2Color
			asl
			tax
			lda	ColModifyTab +0,x
			and	#%00001111
			beq	:2
			jsr	Add1Low
::2			jmp	UpdateCurColor

;*** Neue Hintergrundfarbe setzen.
:SetColorB		jsr	SetColor
			lda	ColorTab,x
			sta	r0L
			lda	Vec2Color
			asl
			tax
			lda	ColModifyTab +1,x
			and	#%11110000
			beq	:1
			jsr	Add1High
::1			lda	Vec2Color
			asl
			tax
			lda	ColModifyTab +1,x
			and	#%00001111
			beq	:2
			jsr	Add1Low
::2			jmp	UpdateCurColor

;*** Gewählte Farbe berechnen.
:SetColor		lda	mouseXPos +1
			lsr
			lda	mouseXPos +0
			ror
			lsr
			lsr
			sec
			sbc	#15
			tax
			rts

;*** Textfarbe wechseln.
:Add1High		ldx	Vec2Color
			lda	C_FarbTab,x
			and	#%00001111
			sta	C_FarbTab,x
			lda	r0L
			asl
			asl
			asl
			asl
			ora	C_FarbTab,x
			sta	C_FarbTab,x
			rts

;*** Hintergrundfarbe wechseln.
:Add1Low		ldx	Vec2Color
			lda	C_FarbTab,x
			and	#%11110000
			ora	r0L
			sta	C_FarbTab,x
			rts

;*** Systemvariablen.
:Class_ScrSaver		b "ScrSaver64  V1.0",NULL
:Class_GeoPaint		b "Paint Image ",NULL

:ColorTab		b $01,$0f,$0c,$0b,$00,$09,$08,$07
			b $0a,$02,$04,$06,$0e,$03,$05,$0d

;*** Farbeinstellungen.
:Vec2Color		b $00

;*** Tabelle zum ändern des Farbwertes.
;    Highbyte:		Textfarbe ändern.
;    Lowbyte:		Hintergrundfarbe ändern.
;    Byte #1:		Textfarbe.
;    Byte #2:		Hintergrundfarbe.
:ColModifyTab		b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11111111,%11111111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11111111,%11111111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11110000,%00001111
			b %11111111,%11111111
			b %11111111,%11111111

:Vec2ColNames		w Text_1_01,Text_2_01
			w Text_1_02,Text_2_02
			w Text_1_02,Text_2_03
			w Text_1_02,Text_2_04
			w Text_1_03,Text_2_05
			w Text_1_04,Text_2_06
			w Text_1_04,Text_2_04
			w Text_1_04,Text_2_07
			w Text_1_05,Text_2_06
			w Text_1_05,Text_2_04
			w Text_1_05,Text_2_07
			w Text_1_05,Text_2_08
			w Text_1_06,Text_2_06
			w Text_1_06,Text_2_04
			w Text_1_06,Text_2_09
			w Text_1_06,Text_2_07
			w Text_1_07,Text_2_10
			w Text_1_08,Text_2_11
			w Text_1_08,Text_2_12
			w Text_1_09,Text_2_13
			w Text_1_09,Text_2_14
			w Text_1_09,Text_2_15

if Sprache = Deutsch
:Text_1_01		b "Scrollbalken",0
:Text_1_02		b "Registerkarten:",0
:Text_1_03		b "Mausfarbe",0
:Text_1_04		b "Dialogbox:",0
:Text_1_05		b "Dateiauswahlbox:",0
:Text_1_06		b "Fenster:",0
:Text_1_07		b "PullDown-Menu",0
:Text_1_08		b "Eingabefelder:",0
:Text_1_09		b "GEOS-Standard:",0
endif
if Sprache = Deutsch
:Text_2_01		b "(Balken und Pfeile)",0
:Text_2_02		b "Aktives Register",0
:Text_2_03		b "Inaktives Register",0
:Text_2_04		b "Hintergrund/Text",0
:Text_2_05		b "(Vorgabewert)",0
:Text_2_06		b "Titel",0
:Text_2_07		b "System-Icons",0
:Text_2_08		b "Dateifenster",0
:Text_2_09		b "Schatten",0
:Text_2_10		b "(Für GEOS-Anwendungen)",0
:Text_2_11		b "Text-Eingabefeld",0
:Text_2_12		b "Inaktives Optionsfeld",0
:Text_2_13		b "Hintergrund",0
:Text_2_14		b "Rahmen",0
:Text_2_15		b "Mauszeiger",0
endif
if Sprache = Englisch
:Text_1_01		b "Scrollbar",0
:Text_1_02		b "Registercard:",0
:Text_1_03		b "Mousecolor",0
:Text_1_04		b "Dialogbox:",0
:Text_1_05		b "File-selector:",0
:Text_1_06		b "Window:",0
:Text_1_07		b "PullDown-menu",0
:Text_1_08		b "Input field:",0
:Text_1_09		b "GEOS-standard:",0
endif
if Sprache = Englisch
:Text_2_01		b "(Bar and arrows)",0
:Text_2_02		b "Active register",0
:Text_2_03		b "Inactive register",0
:Text_2_04		b "Background/text",0
:Text_2_05		b "(Preference)",0
:Text_2_06		b "Title",0
:Text_2_07		b "System-icons",0
:Text_2_08		b "File-window",0
:Text_2_09		b "Shadow",0
:Text_2_10		b "(for GEOS-applications)",0
:Text_2_11		b "Input-field for text",0
:Text_2_12		b "inactive optionfield",0
:Text_2_13		b "Background",0
:Text_2_14		b "Frame",0
:Text_2_15		b "Mousearrow",0
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
if Sprache = Deutsch
:DLG_T_ERR		b PLAINTEXT,BOLDON
			b "Fehlermeldung",0
:DLG_T_INF		b PLAINTEXT,BOLDON
			b "Information",0
endif
if Sprache = Englisch
:DLG_T_ERR		b PLAINTEXT,BOLDON
			b "Systemerror",0
:DLG_T_INF		b PLAINTEXT,BOLDON
			b "Information",0
endif

;*** Dialogbox: Hintergrundbild zeigen.
:Dlg_GetBScrn		b $00
			b $00,$c7
			w $0000,$013f
			b DB_USR_ROUT
			w LdBootScrn
			b DBSYSOPV
			b NULL

;*** Bildschirmschoner - Initialisierung fehlgeschlagen.
:Dlg_ScrSvErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$10,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$10,$20
			w :1
			b DBTXTSTR   ,$10,$2b
			w :2
			b DBTXTSTR   ,$10,$3b
			w :3
			b OK         ,$02,$50
			b NULL

if Sprache = Deutsch
::1			b PLAINTEXT
			b "Der Bildschirmschoner konnte",0
::2			b "nicht initialisiert werden!",0
::3			b "Bildschirmschoner deaktiviert.",0
endif
if Sprache = Englisch
::1			b PLAINTEXT
			b "Unable to initialize the",0
::2			b "screen saver!",0
::3			b "Screensaver has been disabled.",0
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 3				;Anzahl Einträge.

			w RegTName_1			;Register: "Drucker".
			w RegTMenu_1

			w RegTName_2			;Register: "Eingabegerät".
			w RegTMenu_2

			w RegTName_3			;Register: "Eingabegerät".
			w RegTMenu_3

:RegTName_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x,Icon_20y

:RegTName_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x,Icon_21y

:RegTName_3		w Icon_22
			b RegCardIconX_3,$28,Icon_22x,Icon_22y

;*** Daten für Register "BILDSCHIRMSCHONER".
:RegTMenu_1		b 7

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $40,$af
				w $0040,$012f
			b BOX_USER			;----------------------------------------
				w $0000
				w StartScrnSaver
				b $48,$4f
				w $0060,$00df
:RegTMenu_1a		b BOX_STRING_VIEW		;----------------------------------------
				w RegTText_1_02
				w StartScrnSaver
				b $48
				w $0070
				w BootSaverName
				b 16
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $47,$50
				w $00f0,$00f8
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewScrSaver
				b $48
				w $00f0
				w RegTIcon1_1_01
				b $03
			b BOX_USER			;----------------------------------------
				w $0000
				w Swap_ScrSvDelay
				b $90,$97
				w $004c,$00e7
:RegTMenu_1b		b BOX_OPTION			;----------------------------------------
				w RegTText_1_04
				w Swap_ScrSaver
				b $58
				w $0048
				w Flag_ScrSaver
				b %10000000

:RegTIcon1_1_01		w Icon_09
			b $00,$00,$01,$08
			b $ff

if Sprache = Deutsch
:RegTText_1_01		b	 "BILDSCHIRMSCHONER",0
:RegTText_1_02		b 	$48,$00,$4e, "Name:",0
:RegTText_1_03		b GOTOXY,$48,$00,$9e, "( 00:00 MIN. ) "
			b GOTOXY,$48,$00,$7e, "Aktivierungszeit:"
			b GOTOXY,$48,$00,$8e, "<->"
			b GOTOX,$71,$00, "01:00"
			b GOTOX,$a0,$00, "02:00"
			b GOTOX,$d8,$00, "<+>",0
:RegTText_1_04		b	$58,$00,$5e, "Bildschirmschoner deaktivieren",0
endif
if Sprache = Englisch
:RegTText_1_01		b	 "SCREENSAVER",0
:RegTText_1_02		b 	$48,$00,$4e, "Name:",0
:RegTText_1_03		b GOTOXY,$48,$00,$9e, "( 00:00 MIN. ) "
			b GOTOXY,$48,$00,$7e, "Sacreensaver-delay:"
			b GOTOXY,$48,$00,$8e, "<->"
			b GOTOX,$71,$00, "01:00"
			b GOTOX,$90,$00, "02:00"
			b GOTOX,$d8,$00, "<+>",0
:RegTText_1_04		b	$58,$00,$5e, "Shut off screensaver",0
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DESKTOP".
:RegTMenu_2		b 9

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$6f
				w $0040,$012f
			b BOX_OPTION			;----------------------------------------
				w RegTText_2_03
				w Swap_BackScrn
				b $48
				w $0048
				w BootRAM_Flag
				b %00001000
			b BOX_USER			;----------------------------------------
				w $0000
				w PrintCurBackScrn
				b $58,$5f
				w $0058,$00cf
			b BOX_STRING_VIEW		;----------------------------------------
				w RegTText_2_03
				w $0000
				b $58
				w $0058
				w BootGrfxFile
				b 16
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $57,$60
				w $00d8,$00e0
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewBackScrn
				b $58
				w $00d8
				w RegTIcon1_1_01
				b $04

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_04
				w $0000
				b $7f,$af
				w $0040,$012f
			b BOX_ICON			;----------------------------------------
				w RegTText_2_05
				w SetNxBackPattern
				b $88
				w $0048
				w RegTIcon1_2_01
				b $09
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PrintCurPattern
				b $98,$a7
				w $0058,$011f

:RegTIcon1_2_01		w Icon_10
			b $00,$00,$01,$08
			b $ee

if Sprache = Deutsch
:RegTText_2_01		b	 "HINTERGRUNDBILD",0
:RegTText_2_02		b	$48,$00,$5e, "Name:",0
:RegTText_2_03		b	$58,$00,$4e, "Hintergrundbild verwenden",0
:RegTText_2_04		b 	 "HINTERGRUNDMUSTER",0
:RegTText_2_05		b	$58,$00,$8e, "Hintergrundmuster wechseln",0
endif
if Sprache = Englisch
:RegTText_2_01		b	 "BACKGROUND-IMAGE",0
:RegTText_2_02		b	$48,$00,$5e, "Name:",0
:RegTText_2_03		b	$58,$00,$4e, "Use background-image",0
:RegTText_2_04		b 	 "BACKGROUND-PATTERN",0
:RegTText_2_05		b	$58,$00,$8e, "Change background-pattern",0
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "FARBE".
:RegTMenu_3		b 13

			b BOX_FRAME			;----------------------------------------
				w RegTText_3_01
				w $0000
				b $40,$5f
				w $0040,$012f
			b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_3_02
				w PrintCurColName
				b $48,$57
				w $0078,$0117
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $47,$58
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w NextColEntry
				b $48
				w $0118
				w RegTIcon1_3_01
				b $02
			b BOX_ICON			;----------------------------------------
				w $0000
				w LastColEntry
				b $50
				w $0118
				w RegTIcon1_1_01
				b $02

			b BOX_FRAME			;----------------------------------------
				w RegTText_3_03
				w $0000
				b $70,$87
				w $0040,$012f
:RegTMenu_3a		b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_3_04
				w PrintCurColorT
				b $78,$7f
				w $0108,$011f
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $77,$80
				w $0077,$00f8
			b BOX_USER			;----------------------------------------
				w $0000
				w ColorInfoT
				b $78,$7f
				w $0078,$00f7

			b BOX_FRAME			;----------------------------------------
				w RegTText_3_05
				w $0000
				b $98,$af
				w $0040,$012f
:RegTMenu_3b		b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_3_06
				w PrintCurColorB
				b $a0,$a7
				w $0108,$011f
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $9f,$a8
				w $0077,$00f8
			b BOX_USER			;----------------------------------------
				w $0000
				w ColorInfoB
				b $a0,$a7
				w $0078,$00f7

:RegTIcon1_3_01		w Icon_11
			b $00,$00,Icon_11x,Icon_11y
			b $ff

if Sprache = Deutsch
:RegTText_3_01		b	 "BEREICH",0
:RegTText_3_02		b	$48,$00,$4e, "Name:",0
:RegTText_3_03		b	 "TEXT",0
:RegTText_3_04		b	$48,$00,$7e, "Farbe:",0
:RegTText_3_05		b	 "HINTERGRUND",0
:RegTText_3_06		b	$48,$00,$a6, "Farbe:",0
endif
if Sprache = Englisch
:RegTText_3_01		b	 "AREA",0
:RegTText_3_02		b	$48,$00,$4e, "Name:",0
:RegTText_3_03		b	 "TEXT",0
:RegTText_3_04		b	$48,$00,$7e, "Color:",0
:RegTText_3_05		b	 "BACKGROUND",0
:RegTText_3_06		b	$48,$00,$a6, "Color:",0
endif

;*** Icons.
:Icon_06
<MISSING_IMAGE_DATA>
:Icon_06x		= .x
:Icon_06y		= .y

:Icon_07
<MISSING_IMAGE_DATA>
:Icon_07x		= .x
:Icon_07y		= .y

:Icon_08
<MISSING_IMAGE_DATA>
:Icon_08x		= .x
:Icon_08y		= .y

:Icon_09
<MISSING_IMAGE_DATA>
:Icon_09x		= .x
:Icon_09y		= .y

:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

:Icon_11
<MISSING_IMAGE_DATA>
:Icon_11x		= .x
:Icon_11y		= .y

if Sprache = Deutsch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

if Sprache = Englisch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y

if Sprache = Deutsch
:Icon_22
<MISSING_IMAGE_DATA>
:Icon_22x		= .x
:Icon_22y		= .y
endif

if Sprache = Englisch
:Icon_22
<MISSING_IMAGE_DATA>
:Icon_22x		= .x
:Icon_22y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + Icon_20x
:RegCardIconX_3		= RegCardIconX_2 + Icon_21x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
