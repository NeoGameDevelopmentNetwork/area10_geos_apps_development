; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "SymbTab_GSPR"
			t "SymbTab_DISK"
			t "MacTab"

;--- Externe Labels.
			t "s.GDC.Config.ext"

;--- Anzahl Zufallsbilder:
;Text ändern bei Label ":R2T06"
.GrfxMaxRandom		= 16
endif

;*** GEOS-Header.
			n "obj.CFG.SCRN"
			f DATA

			o BASE_GCFG_BOOT

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	BOOT_GDC_SCREEN
;******************************************************************************

;*** GeoPaint-Loader.
.e_ViewPaintFile	t "-G3_ReadGPFile"

;*** AutoBoot: GD.CONF.SCREEN.
:BOOT_GDC_SCREEN	lda	BootPattern		;Füllmuster setzen.
			sta	BackScrPattern

			lda	#FALSE			;Kein Hintergrundbild geladen.
			sta	Flag_BackScrn

			lda	sysRAMFlg		;Hintergrundbild-Modus.
			and	#%11110111
			sta	sysRAMFlg
			lda	BootRAM_Flag
			and	#%00001000
			ora	sysRAMFlg
			sta	sysRAMFlg
			sta	sysFlgCopy

;--- Hintergrundgrafik:
::do_backscrn		lda	BootRAM_Flag		;Statusbyte einlesen.
			and	#%00001000		;Hintergrundbild laden ?
			bne	:testrandom

			jsr	e_StdClrScreen		; => Nein, weiter...
			jmp	:do_scrsaver

::testrandom		bit	BootGrfxRandom		;Zufallsmodus aktiv ?
			bpl	:viewpaint		; => Nein, weiter...

			php				;Zufallszahl initialisieren.
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	$d012
			sta	random +0
			asl
			sta	random +1

			stx	CPU_DATA

			plp

			jsr	GetRandom		;Zufallszahl einlesen.

			jsr	e_GetRandomGrfx		;Zufällige Grafik auswählen.

::viewpaint		jsr	e_LdScrnFrmDisk		;Hintergrundbild von Disk einlesen.

;--- Bildschirmschoner:
::do_scrsaver		bit	BootScrSaver
			bmi	:do_colsetup
			lda	BootSaverName		;Bildschirmschoner nachladen ?
			beq	:do_colsetup		; => Nein, weiter...

			LoadW	r6,BootSaverName	;Neuen Bildschirmschoner starten.
			jsr	e_InitScrSaver		;Bildschirmschoner initialisieren.
			txa				;Fehler?
			bne	:do_colsetup		; => Ja, Nicht aktivieren.

			lda	BootScrSvCnt		;Aktivierungszeit einlesen.
			sta	Flag_ScrSvCnt
			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

;--- Farbkonfiguration:
::do_colsetup		jsr	e_InitColConfig		;Standard-Farbprofil suchen.
			jmp	e_UpdateColRAM		;Farbeinstellungen übernehmen.

;*** Hintergrundbild einlesen.
;Name in ":BootGrfxFile" übergeben!
.e_LdScrnFrmDisk	lda	BootGrfxFile		;Name definiert ?
			beq	:3			; => Nein, kein Startbild.

			ldx	#0			;Für GeoPaint-Loader den
::1			lda	BootGrfxFile,x		;Dateinamen umkopieren.
			sta	dataFileName,x
			beq	:2
			inx
			cpx	#16
			bcc	:1

::2			LoadB	a0L,%10000000		;Farb-RAM löschen.
			LoadW	a2,GrfxData		;Zeiger auf Zwischenspeicher.
			jsr	e_ViewPaintFile		;Hintergrundbild anzeigen.
			txa				;Diskettenfehler ?
			beq	SvBackScrn		; => Nein, Startbild speichern.

::3			jsr	e_TurnOff_BkScr		;Hintergrundbild abschalten und
			jsr	e_StdClrScreen		;Standardgrafik speichern.

;*** Hintergrundgrafik speichern.
;    Grafik wird immer aus der REU eingelesen! Ist keine "Grafik" aktiv,
;    wird der Hintergrund durch ein Füllmuster definiert und diese Grafik
;    als Hintergrundgrafik gespeichert.
:SvBackScrn		lda	MP3_64K_SYSTEM		;Zeiger auf MP3-Systembank.
			sta	r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2A_BS_GRAFX
			LoadW	r2,R2S_BS_GRAFX
			jsr	StashRAM		;Grafik speichern.
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2A_BS_COLOR
			LoadW	r2,R2S_BS_COLOR
			jsr	StashRAM		;Farben speichern.

			lda	#TRUE			;Hintergrundbild geladen.
			sta	Flag_BackScrn

			rts

;*** Hintergrundbild abschalten.
.e_TurnOff_BkScr	lda	BootRAM_Flag		;Startbild nicht gefunden,
			and	#%11110111		;Kein Hintergrundbild verwenden.
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Achtung! ":BootRAM_Flag" und
			and	#%11110111		;sysRAM_Flag getrennt bearbeiten,
			sta	sysRAMFlg		;da diese Routine auch im laufenden
			sta	sysFlgCopy		;GEOS-Betrieb aufgerufen wird!
			rts

;*** Bildschirm löschen.
;Hinweis:
;Die Kernal-Routine ":GetBackScreen"
;testet auf ":sysRAMFlg" und kann hier
;nicht verwendet werden.
.e_StdClrScreen		lda	#ST_WR_FORE		;Nur Vordergrund-Bildschirm.
			sta	dispBufferOn

			lda	C_WinShadow		;Bildschirm-Farben löschen.
			jsr	i_UserColor
			b	$00,$00,$28,$19

			lda	BackScrPattern
			jsr	SetPattern		;Bildschirm-Muster setzen.

			jsr	i_Rectangle		;Bildschirm löschen.
			b	$00,$c7
			w	$0000,$013f

			rts

;*** Zufällige GeoPaint-Grafik wählen.
.e_GetRandomGrfx	LoadW	r6,GrfxFNameBuf
			LoadB	r7L,APPL_DATA
			LoadB	r7H,GrfxMaxRandom
			LoadW	r10,Class_GeoPaint
			jsr	FindFTypes		;Dateien suchen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			ldx	#FILE_NOT_FOUND
			lda	#GrfxMaxRandom
			sec
			sbc	r7H			;Mind. 1 Datei gefunden ?
			beq	:exit			; => Nein, Ende...

			sta	r0L			;Anzahl Dateien merken.

			lda	random +0		;Zufallszahl setzen.
			eor	random +1
			and	#%00000111
			sta	r0H

::loop			LoadW	r1,GrfxFNameBuf		;Zeiger auf ersten Eintrag.

			ldx	r0L
			cpx	#2			;Mehr als eine Datei ?
			bcc	:found			; => Nein, erste Datei wählen...

::test			lda	r0H			;Zähler abgelaufen ?
			beq	:found			; => Ja, Bild auswählen.
			dec	r0H

			lda	r1L			;Zeiger auf nächsten Namen.
			clc
			adc	#17
			sta	r1L
			bcc	:2
			inc	r1H

::2			dex				;Alle Namen durchsucht ?
			bne	:test			; => Nein, weiter...
			beq	:loop			; => Ja, Neustart...

::found			LoadW	r2,BootGrfxFile		;Eintrag gefunden.
			ldx	#r1L
			ldy	#r2L
			jsr	CopyString

			ldx	#NO_ERROR
::exit			rts

;*** Passendes Farbprofil für Zufallsbild suchen.
.e_GetRandomCols	ldy	#0
::1			lda	BootGrfxFile,y		;Name Grafikdatei übernehmen.
			beq	:2			;(Nur die ersten 12 Zeichen)
			sta	configColName,y
			iny
			cpy	#12
			bcc	:1

::2			ldx	#0
::3			lda	configColExt,x		;Erweiterung ".col" anhängen.
			sta	configColName,y
			iny
			inx
			cpx	#4
			bcc	:3

			lda	#NULL			;Ende-Kennung schreiben.
			sta	configColName,y

			LoadW	r6,configColName	;Zeiger auf Dateiname setzen.
			jsr	FindFile		;Datei suchen.
			txa				;Gefunden ?
			bne	:exit			; => Nein, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r0,fileHeader +77	;Klasse des Farbprofils prüfen.
			LoadW	r1,Class_ColConf
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString
			bne	:exit			; => Kein, Farbprofil, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6,configColName
			LoadW	r7,GD_PROFILE		;Startadresse Farb-/Musterdaten.
			jsr	GetFile			;Datei einlesen.
			txa				;Fehler?
			beq	:ok			; => Nein, Ende...

::exit			ldx	#FILE_NOT_FOUND
::ok			rts

;*** Neuen Bildschirmschoner installieren.
;    r6 = Zeiger auf Dateiname.
.e_InitScrSaver		jsr	FindFile		;Datei suchen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	dirEntryBuf +19		;Infoblock einlesen.
			beq	:err			; => Fehler, keine GEOS-Datei.
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			ldx	#FILE_NOT_FOUND
			ldy	#12 -1			;Bildschirmschoner-Datei?
::check			lda	fileHeader +77,y
			cmp	Class_ScrSaver,y
			bne	:err			; => Nein, deaktivieren...
			dey
			bpl	:check

			jsr	SetADDR_ScrSaver	;RAM im Bereich Bildschirmschoner
			jsr	SwapRAM			;zwischenspeichern.

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r2,R2S_SCRSAVER
			LoadW	r7,LOAD_SCRSAVER
			jsr	ReadFile		;Bildschirmschoner einlesen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch...

			jsr	LOAD_SCRSVINIT		;Bildschirmschoner initialisieren.
;--- Ergänzung: 20.07.18/M.Kanet
;In der MegaPatch/2003-Version wurde nicht auf Initialisierungsfehler
;geprüft. 64erMove kann z.B. nicht verwendet werden wenn kein freier
;Speicher verfügbar ist.
			txa				;Initialisierung OK?
			beq	:1			; => Ja, Ende..

			jsr	e_TurnOff_ScrSv		;Bildschirmschoner abschalten.

			ldx	#INCOMPATIBLE		;Fehlerstatus setzen.
::1			txa
			pha
			jsr	SetADDR_ScrSaver	;Bildschirmschoner in RAM kopieren.
			jsr	SwapRAM
			pla
			tax				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Ergänzung: 16.02.21/M.Kanet
;Sicherstellen das Bildschirmschoner
;in das externe RAM geladen wurde.
			jsr	e_Test_ScrSvNm		;Name Bildschirmschoner prüfen.
;			txa				;Fehler?
;			beq	:exit			; => Nein, OK...

::err			rts

;*** Bildschirmschoner abschalten.
;--- Ergänzung: 20.07.18/M.Kanet
;Abschalten durch setzen von Bit#7!
.e_TurnOff_ScrSv	lda	#%10000000		;Bildschirmschoner abschalten und
			sta	Flag_ScrSaver		;Konfiguration speichern.
			sta	BootScrSaver
			lda	#NULL			;Name Bildschirmschoner
			sta	BootSaverName		;löschen.
			rts

;*** Name Bildschirmschoner prüfen.
.e_Test_ScrSvNm		jsr	SetADDR_ScrSaver	;Zeiger auf Bildschirmschoner.

			lda	#< tempScrSvNam
			sta	r0L
			lda	#> tempScrSvNam
			sta	r0H

			lda	r1L
			clc
			adc	#< $0006
			sta	r1L
			lda	r1H
			adc	#> $0006
			sta	r1H

			LoadW	r2,17
			jsr	FetchRAM

			ldy	#0
::1			lda	(r0L),y
			beq	:ok
			cmp	BootSaverName,y
			bne	:not_found
			iny
			cpy	#16
			bcc	:1

::ok			ldx	#NO_ERROR
			b $2c
::not_found		ldx	#FILE_NOT_FOUND
			rts

;*** Farbprofil laden.
.e_InitColConfig	lda	BootRAM_Flag		;Statusbyte einlesen.
			and	#%00001000		;Hintergrundbild laden ?
			beq	e_FindStdColCfg		; => Nein, weiter...

			bit	BootGrfxRandom		;Zufallsmodus aktiv ?
			bpl	e_FindStdColCfg		; => Nein, weiter...
			bvc	:cont			; => Nein, weiter...

			jsr	e_GetRandomCols		;Passendes Farbprofil suchen.
			txa				;Datei gefunden ?
			beq	:ok			; => Nein, Ende...

::cont			lda	BootGrfxRandom
			and	#%00100000		;Standard-Farben verwenden ?
			beq	e_FindStdColCfg

			jsr	e_ResetColGEOS		;GEOS-Farben zurücksetzen.
			jsr	e_ResetColGDESK		;GeoDesk-Farben zurücksetzen.
			jsr	e_ResetColFICON		;Datei-Farben zurücksetzen.

::ok			jsr	e_ApplyColors		;Farben übernehmen.

			ldx	#NO_ERROR
			rts

;*** Standard/"GeoDesk.col" suchen.
.e_FindStdColCfg	LoadB	r0L,%00000001
			LoadW	r6,configColStd
			LoadW	r7,GD_PROFILE		;Startadresse Farb-/Musterdaten.
			jsr	GetFile			;Datei einlesen.
			txa				;Fehler?
			beq	:load			; => Nein, weiter...

			cpx	#FILE_NOT_FOUND		;Fehler: "Datei nicht gefunden"?
			bne	:err			; => Nein, Abbruch...

::load			jsr	e_ApplyColors		;Farbprofil anwenden.

			ldx	#NO_ERROR
::err			rts				;Disk-/Laufwerksfehler ausgeben.

;*** Farbprofil in DACC speichern.
.e_UpdateColRAM		LoadW	r0,GD_PROFILE
			LoadW	r1,R3A_CPROFILE
			LoadW	r2,R3S_CPROFILE
			lda	MP3_64K_DATA
			sta	r3L
			jsr	StashRAM		;Farbprofil speichern.

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** GEOS-Farben zurücksetzen.
.e_ResetColGEOS		lda	ORIG_C_GEOS_PAT		;Füllmuster zurücksetzen.
			sta	C_GEOS_PATTERN

			jsr	i_MoveData		;GEOS-Farben zurücksetzen.
			w	ORIG_COLOR_GEOS
			w	GD_COLOR_GEOS
			w	COLVAR_SIZE

			rts

;*** GeoDesk-Farben zurücksetzen.
.e_ResetColGDESK	lda	ORIG_C_GDESK_PAT	;Füllmuster zurücksetzen.
			sta	C_GDESK_PATTERN
			lda	ORIG_C_GTASK_PAT
			sta	C_GTASK_PATTERN

			jsr	i_MoveData		;GeoDesk-Farben zurücksetzen.
			w	ORIG_COLOR_GDESK
			w	GD_COLOR
			w	GD_COLOR_SIZE

			rts

;*** Datei-Farben zurücksetzen.
.e_ResetColFICON	jsr	i_MoveData		;Datei-Icon-Farben zurücksetzen.
			w	ORIG_COLOR_ICONS
			w	GD_COLICON
			w	GD_COLICON_SIZE

			rts

;*** Farbe Mauszeiger übernehmen.
.e_ApplyColors		jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	GD_COLOR_GEOS
			w	COLVAR_BASE
			w	COLVAR_SIZE

			lda	C_GEOS_PATTERN		;GEOS-Füllmuster übernehmen.
			sta	BackScrPattern

			lda	C_GEOS_MOUSE		;Standardfarbe Mauszeiger überhmen.
			sta	C_Mouse

			php
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr

			lda	C_GEOS_FRAME
			sta	extclr

			stx	CPU_DATA

			plp

;--- Ergänzung: 24.12.22/M.Kanet
;Fabren für DESKTOP V2 übernehmen.
;Die Werte liegen ab ":sysApplData" im
;Speicher und können unter DESKTOP V2
;durch "pad color mgr" geändert werden.
;Es werden allerdings nur die GEOS-
;Dateitypen 0-15 unterstützt.
			ldx	#0
::1			txa
			lsr				;Zeiger auf Nible in sysApplData
			tay				;berechnen (zwei Farben je Byte).
			lda	GD_COLICON,x		;System-Farbwert einlesen.
			and	#%11110000		;Vordergrundfarbe isolieren.
			bcc	:2			; => Low-Nibble definieren.

			ora	sysApplData,y		;High-Nibble, Low-Nibble ergänzen.
			bcs	:3			; => High-/Low-Nibble speichern.

::2			lsr				;Farbwert in Low-Nibble
			lsr				;umwandeln.
			lsr
			lsr

::3			sta	sysApplData,y		;Farbwert speichern.

			inx
			cpx	#16			;Max. 16 Systemfarben für
			bcc	:1			;DeskTop V2 übernehmen.

			lda	C_WinBack		;Farbe für Arbeitsplatz
			sta	sysApplData +8		;in DeskTop V2 übernehmen.

			rts

;*** GEOS-Klasse für GeoPaint-Dateien.
.Class_GeoPaint		b "Paint Image ",NULL

;*** GEOS-Klasse für Bildschirmschoner.
.Class_ScrSaver		b "ScrSaver64  V1.0",NULL
:tempScrSvNam		s 17

;*** GEOS-Klasse für FarbSetup-Dateien.
.Class_ColConf		b "geoDeskCol  V1.0",NULL
.configColStd		b "GeoDesk"
:configColExt		b ".col"
			e configColStd +17
.configColName		s 17

;******************************************************************************
:ORIG_COLOR_GEOS	t "-G3_StdColors"

;******************************************************************************
:ORIG_COLOR_GDESK					;Beginn der Farbtabelle.
::C_WinScrBar		b $01				;Fenster/Scrollbalken.
::C_WinMovIcons		b $10				;Scroll Up/Down-Icons.
::C_GDesk_Clock		b $07				;GeoDesk-Uhr.
::C_GDesk_GEOS		b $03				;GEOS-Menübutton.
::C_RegisterExit	b $0d				;Karteikarten: Beenden.
::C_GDesk_TaskBar	b $10				;GeoDesk-Taskbar.
::C_GDesk_ALIcon	b $01				;Farbe für AppLink-Icons/Standard.
::C_GDesk_ALTitle	b $07				;Farbe für AppLink-Titel.
::C_GDesk_MyComp	b $01				;Farbe für Arbeitsplatz-Icon.
::C_GDesk_DeskTop	b $bf				;Farbe für GeoDesk ohne BackScreen.

;******************************************************************************
:ORIG_C_GEOS_PAT	b $02				;GEOS-Hintergrund-Füllmuster.
:ORIG_C_GDESK_PAT	b $02				;GeoDesk-Hintergrund-Füllmuster.
:ORIG_C_GTASK_PAT	b $00				;GeoDesk/TaskBar-Füllmuster.

;******************************************************************************
:ORIG_COLOR_ICONS
::fileColorTab		b $c0				;$00-Nicht GEOS.
			b $60				;$01-BASIC-Programm.
			b $60				;$02-Assembler-Programm.
			b $c0				;$03-Datenfile.
			b $20				;$04-Systemdatei.
			b $60				;$05-Hilfsprogramm.
			b $60				;$06-Anwendung.
			b $50				;$07-Dokument.
			b $d0				;$08-Zeichensatz.
			b $40				;$09-Druckertreiber.
			b $40				;$0A-Eingabetreiber.
			b $40				;$0B-Laufwerkstreiber.
			b $20				;$0C-Startprogramm.
			b $c0				;$0D-Temporäre Datei (SWAP FILE).
			b $60				;$0E-Selbstausführend (AUTO_EXEC).
			b $40				;$0F-Eingabetreiber C128.
			b $c0				;$10-Unbekannt.
			b $40				;$11-gateWay-Dokument.
			b $c0				;$12-Unbekannt.
			b $c0				;$13-Unbekannt.
			b $c0				;$14-Unbekannt.
			b $40				;$15-geoShell-Befehl.
			b $50				;$16-geoFax-Dokument.
			b $c0				;$17-Unbekannt.
			b $b0				;$18-Verzeichnis.

;******************************************************************************
;
;Hinweis:
;Der Bereich von ":GD_PROFILE"
;bis ":GD_PROFILE_END" wird in den
;Farbprofil-Dateien gespeichert.
;
.GD_PROFILE

;******************************************************************************
.GD_COLOR_GEOS		t "-G3_StdColors"

			g GD_COLOR_GEOS + COLVAR_SIZE

;******************************************************************************
.GD_COLOR						;Beginn der Farbtabelle.
:C_WinScrBar		b $01				;Fenster/Scrollbalken.
:C_WinMovIcons		b $10				;Scroll Up/Down-Icons.
:C_GDesk_Clock		b $07				;GeoDesk-Uhr.
:C_GDesk_GEOS		b $03				;GEOS-Menübutton.
:C_RegisterExit		b $0d				;Karteikarten: Beenden.
.C_GDesk_TaskBar	b $10				;GeoDesk-Taskbar.
:C_GDesk_ALIcon		b $01				;Farbe für AppLink-Icons/Standard.
:C_GDesk_ALTitle	b $07				;Farbe für AppLink-Titel.
:C_GDesk_MyComp		b $01				;Farbe für Arbeitsplatz-Icon.
.C_GDesk_DeskTop	b $bf				;Farbe für GeoDesk ohne BackScreen.

:GD_COLOR_END						;Endde der Farbtabelle.
:GD_COLOR_SIZE = (GD_COLOR_END - GD_COLOR)

;******************************************************************************
.C_GEOS_PATTERN		b $02				;GEOS-Hintergrund-Füllmuster.
.C_GDESK_PATTERN	b $02				;GeoDesk-Hintergrund-Füllmuster.
.C_GTASK_PATTERN	b $00				;GeoDesk/TaskBar-Füllmuster.

;*** Farben für GEOS-Datei-Icons.
;    Hintergrund-Farb-Nibble immer $x0.
;
; $0x = Schwarz   $8x = Orange
; $1x = Weiß      $9x = Braun
; $2x = Rot       $Ax = Hellrot
; $3x = Türkis    $Bx = Dunkelgrau
; $4x = Violett   $Cx = Grau
; $5x = Grün      $Dx = Hellgrün
; $6x = Blau      $Ex = Hellblau
; $7x = Gelb      $Fx = Hellgrau
;
.GD_COLICON
if FALSE
;
;    Hinweis: Standard-Farbtabelle.
;             Farbe nach Dateityp.
;
::fileColorTab		b $00				;$00-Nicht GEOS.
			b $00				;$01-BASIC-Programm.
			b $30				;$02-Assembler-Programm.
			b $30				;$03-Datenfile.
			b $20				;$04-Systemdatei.
			b $60				;$05-Hilfsprogramm.
			b $60				;$06-Anwendung.
			b $30				;$07-Dokument.
			b $70				;$08-Zeichensatz.
			b $50				;$09-Druckertreiber.
			b $50				;$0A-Eingabetreiber.
			b $20				;$0B-Laufwerkstreiber.
			b $20				;$0C-Startprogramm.
			b $00				;$0D-Temporäre Datei (SWAP FILE).
			b $60				;$0E-Selbstausführend (AUTO_EXEC).
			b $50				;$0F-Eingabetreiber C128.
			b $70				;$10-Unbekannt.
			b $60				;$11-gateWay-Dokument.
			b $70				;$12-Unbekannt.
			b $70				;$13-Unbekannt.
			b $70				;$14-Unbekannt.
			b $60				;$15-geoShell-Befehl.
			b $50				;$16-geoFax-Dokument.
			b $70				;$17-Unbekannt.
			b $b0				;$18-Verzeichnis.
endif

if TRUE
;
;    Hinweis: Überarbeitete Farbtabelle.
;             Farbe nach Sytemtyp.
;
;    Hinweis: $0x vermeiden, da $0x im
;             Dateifenster durch die
;             Text/Vordergrundfarbe im
;             Fenster ersetzt wird.
;
; Nicht-GEOS      $Cx
; Anwendungen     $6x
; Dokumente       $5x
; System          $2x
; Zeichensatz     $Dx
; Treiber         $4x
; Sonstiges       $Cx
; Verzeichnisse   $Bx
;
::fileColorTab		b $c0				;$00-Nicht GEOS.
			b $60				;$01-BASIC-Programm.
			b $60				;$02-Assembler-Programm.
			b $c0				;$03-Datenfile.
			b $20				;$04-Systemdatei.
			b $60				;$05-Hilfsprogramm.
			b $60				;$06-Anwendung.
			b $50				;$07-Dokument.
			b $d0				;$08-Zeichensatz.
			b $40				;$09-Druckertreiber.
			b $40				;$0A-Eingabetreiber.
			b $40				;$0B-Laufwerkstreiber.
			b $20				;$0C-Startprogramm.
			b $c0				;$0D-Temporäre Datei (SWAP FILE).
			b $60				;$0E-Selbstausführend (AUTO_EXEC).
			b $40				;$0F-Eingabetreiber C128.
			b $c0				;$10-Unbekannt.
			b $40				;$11-gateWay-Dokument.
			b $c0				;$12-Unbekannt.
			b $c0				;$13-Unbekannt.
			b $c0				;$14-Unbekannt.
			b $40				;$15-geoShell-Befehl.
			b $50				;$16-geoFax-Dokument.
			b $c0				;$17-Unbekannt.
			b $b0				;$18-Verzeichnis.
endif
:GD_COLICON_END
:GD_COLICON_SIZE = (GD_COLICON_END - GD_COLICON)

;*** Ende Profil-Datei.
.GD_PROFILE_END
.GD_PROFILE_SIZE = (GD_PROFILE_END - GD_PROFILE)

;*** Zwischenspeicher Hintergrundbild:
:GrfxData		;s (640 * 2) + 8 + (80 * 2)
:GrfxFNameBuf

;*** Zwischenspeicher Dateinamen.
:ColsFNameBuf

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
;Speicher für GeoPaint-Loader:
			g BASE_DDRV_INFO - (640 * 2) + 8 + (80 * 2)
;Speicher für Dateinamen:
			g BASE_DDRV_INFO - (255 * 17)	;Dateinamen.
;******************************************************************************
