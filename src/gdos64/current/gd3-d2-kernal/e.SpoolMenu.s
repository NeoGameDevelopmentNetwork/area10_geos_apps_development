﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_CSYS"
			t "SymbTab_GEXT"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_PRNT"
			t "SymbTab_GRFX"
			t "SymbTab_GSPR"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "e.Register.ext"
endif

;*** GEOS-Header.
			n "obj.SpoolMenu"
			f DATA

			o LOAD_SPOOLER

if .p
;*** Variablen für Füllstandsanzeige im Spooler-Menu.
:Balken_B		= 64
:Balken_H		= 8
:Balken_X		= $00e0
:Balken_Y		= $10

;*** Variablen für Fortschrittsanzeige während des druckens.
:Status_H		= 21
:Status_X		= $0120
:Status_Y		= $ab
endif

;*** Spooler starten.
;    Wird der Spooler aus dem Druckertreiber heraus ausgerufen, so werden alle
;    Daten gedruckt, die sich bis dahin im Speicher befinden.
:StartSpoolMenu		lda	AllDataPrinted
			beq	:51
			jmp	SpoolData
::51			jmp	SpoolMenu

;*** Angaben zum aktuellen Dokument.
;Opt0			Bit7: 1 = Dokument drucken.
;			Bit6: 1 = Alle Seiten drucken.
;			Bit5: 1 = Nur bestimmte Seiten drucken.
;			Bit4: 0 = Ungerade Seiten drucken.
;			Bit4: 1 = Ungerade Seiten nicht drucken.
;			Bit3: 0 = Gerade Seiten drucken.
;			Bit3: 1 = Gerade Seiten nicht drucken.
;			Bit2: 0 = Optionen noch nicht angezeigt.
;			Bit2: 1 = Optionen bereits angezeigt..
;			Bit1: 0 = Dokument in Warteschlange.
;			Bit1: 1 = Dokument wird gedruckt.
;			Bit0: 0 = Dokument noch nicht gedruckt.
;			Bit0: 1 = Dokument bereits gedruckt.

;--- Zeiger auf Dokument-Name.
:DokNameVec		b 0,17,34,51,68,85,102,119,136,153,170,187,204,221,238,255

;--- Spoolervariablen.
:SpoolSysVar
:CurrentDokument	b $00				;Zeiger auf aktuelles Dokument.
:DokumentVector		b $00				;Zeiger auf Dokumentdaten-Speicher.
:DokumentCount		b $00				;Zähler für neue Dokumente.

:DokumentNr		s 15				;Lfd. Nr. in Warteschlange.
:DokumentName		s 15 * 17			;Name des Druckauftrags.
:DokumentOpt		s 15				;Optionen für aktuelles Dokument.
:DokumentPFirst		s 15				;Erste Seite im Dokument.
:DokumentPStart		s 15				;Erste Druckseite.
:DokumentPEnd		s 15				;Letzte Druckseite.
:DokumentPMax		s 15				;Letzte Seite im Dokument.
:DokumentCopy		s 15				;Anzahl Kopien.
:DokStartAdrL		s 15				;Startadresse im Druckspeicher.
:DokStartAdrM		s 15
:DokStartAdrH		s 15

:TempDokNr		b $00				;Temporäre Kopie des aktuellen
:TempDokName		s 17				;Druckauftrages.
:TempDokOpt		b $00
:TempDokPFirst		b $00
:TempDokPStart		b $00
:TempDokPEnd		b $00
:TempDokPMax		b $00
:TempDokCopy		b $00

:SpoolDokument		b $00				;Aktuell gespooltes Dokument.
:SpoolDokPage		b $00				;Aktuelle Seite.
:SpoolVector		b $00,$00,$00			;Zeiger auf Aktuelle Druckdaten.
:SpoolLastByte		b $00,$00,$00			;Letztes im Druckspeicher geprüftes Byte.
:SpoolSysVarEnd

:Copy_SpoolADDR		b $00,$00,$00			;Kopie der MP3-Systemvariablen.
:Copy_Spooler		b $00				;Innerhalb des Spoolers wird mit diesen
:Copy_SplCurDok		b $00				;Variablen gearbeitet!!!
:Copy_SplMaxDok		b $00

:Buffer			b $00				;Puffer für DruckerSpooler.
:NewPage		b $00				;Flag: "Neue Seite"
:AllDataPrinted		b $00				;Flag: "Daten werden gedruckt"
:AnalyzeMode		b $00				;Flag: "$FF = Nur neue Dokumente einlesen"
:LastJobCode		b $00				;Flag: "Letzter JobCode=FF"

;*** Zwischenspeicher.
:SystemAdrStack		b $00				;Stackzeiger.
:zpageBuf		s 256				;ZeroPage.

:spr6Buf		s 63				;Sprite-Daten C64
:spr7Buf		s 63
:obj6Buf		b $00
:obj7Buf		b $00
:col6Buf		b $00
:col7Buf		b $00
:sprXYBuf		s $05
:mobx2Buf		b $00
:moby2Buf		b $00
:mobenbleBuf		b $00

;*** Sprite-Grafik für "Fortschrittsanzeige".
:SprBufCalc		b %00000000,%00000111,%11111111
			b %00100110,%00110000,%10000001
			b %01101001,%01001000,%10000001
			b %00101001,%01001000,%10000001
			b %00101001,%01001000,%10000001
			b %00100110,%00110000,%10000001
			b %00000000,%00000000,%10000001
			b %00000000,%00000000,%10000001
			b %01100100,%00000000,%10000001
			b %01101000,%00000000,%10000001
			b %00010000,%00000111,%10000001
			b %00101100,%00000000,%10000001
			b %01001100,%00000000,%10000001
			b %00000000,%00000000,%10000001
			b %00000000,%00000000,%10000001
			b %00000000,%00110000,%10000001
			b %00000000,%01001000,%10000001
			b %00000000,%01001000,%10000001
			b %00000000,%01001000,%10000001
			b %00000000,%00110000,%10000001
			b %00000000,%00000111,%11111111

;*** DruckerSpooler initialisieren.
;    Aufruf wenn die nächsten Daten gedruckt werden sollen.
;    Menü muß bereits initialisiert sein!
:SpoolData		php				;IRQ sperren.
			sei

			jsr	SaveSysData		;Systemdaten zwischenspeichern.

			ldy	#$00			;GEOS-Vektoren löschen. Dies soll
::51			lda	appMain,y		;verhindern das andere Programme
			pha				;über IRQ/Mainloop auf den
			lda	#$00			;Speicherbereich des Spooler
			sta	appMain,y		;zurgreifen können.
			iny
			cpy	#$14
			bne	:51

			LoadW	intTopVector,InterruptMain

			cli
			jsr	DoSpoolData		;Daten zum Drucker senden.
			sei

			ldy	#$13			;GEOS-Vektoren zurücksetzen.
::52			pla
			sta	appMain,y
			dey
			bpl	:52

			jmp	EndSpooler		;Spooler beenden.

;*** DruckerSpooler-Menu initialisieren.
;    Aufruf wenn die ersten Daten gedruckt werden sollen.
;    Menü wird vorher initialisiert!
:SpoolMenu		php				;IRQ sperren.
			sei

			lda	Flag_Spooler		;Spooler deaktivieren.
			and	#%10000000
			sta	Flag_Spooler

			jsr	SaveSysData		;Systemdaten zwischenspeichern.
			jsr	SaveMemData

			jsr	GEOS_InitSystem		;GEOS-Reset der Systemvariablen.
			lda	#ST_WR_FORE		;Grafik nur im Vordergrundspeicher.
			sta	dispBufferOn

			jsr	AnalyzeAllFiles		;Druckspeicher analysieren.
			cli

			tsx
			stx	SystemAdrStack

;*** Register-Menü starten.
:RestartMenu		lda	#$00
			sta	CurrentDokument
			jsr	GetCurDokData

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	PrintSpoolMenu		;Hauptmenü ausgeben und

			LoadW	r0,RegisterTab		;Register-Menü aktivieren.
			jsr	DoRegister
			jmp	MainLoop		;zurück zur MainLoop.

;*** "Drucken" gewählt, mit dem Ausdruck der Daten beginnen.
:SpoolMenuPrint		jsr	UpdateDokData		;Aktuelle Seitendaten speichern.

			jsr	SetOptionFlag
			jsr	LoadScrData		;Bildschirm-Inhalt zurücksetzen.

			jsr	DoSpoolData		;DruckerSpooler-Menu aktivieren.

			lda	Copy_Spooler		;Spooler-Flag einlesen.
			and	#%01000000		;Soll Menü gestartet werden ?
			bne	RestartMenu		; => Hauptmenü starten.
			beq	SpoolMenuEnd

;*** Druckerspooler-Reset, Warteschlange löschen.
:SpoolReset		jsr	ClearSpooler
			jmp	SpoolMenuEnd

;*** "Beenden" gewählt, Spooler verlassen.
:SpoolMenuExit		jsr	UpdateDokData		;Aktuelle Seitendaten speichern.

			lda	#%10000000
			sta	Copy_Spooler

;*** Alle Druckaufträge beendet.
:SpoolMenuEnd		ldx	SystemAdrStack		;Stack zurücksetzen.
			txs

			jsr	LoadMemData
:EndSpooler		jsr	LoadSysData		;Systemdaten zurücksetzen.

			ldx	AllDataPrinted		;Alle Daten gedruckt ?
			beq	:51			; => Ja, weiter...
			lda	keyData 			;Gedrückte Taste einlesen.
			jsr	PutKeyInBuffer		;Taste in Tastaturpuffer kopieren.

::51			plp
			rts

;*** Hauptmenü ausgeben.
:PrintSpoolMenu		jsr	RegisterSetFont		;8-Punkte-Font aktivieren.

			lda	#ST_WR_FORE		;Nur Vordergrund-Bildschirm.
			sta	dispBufferOn

			jsr	GetBackScreen		;Hintergrundbild laden.

			lda	#$00			;Fenster für Hauptmenü zeichnen.
			jsr	SetPattern

			jsr	i_Rectangle		;Titelzeile für Menüfenster.
			b	$00,$07
			w	$0000,$013f

			lda	C_WinTitel		;Farbe 40 Zeichen
			jsr	DirectColor

			LoadW	r0,MenuText00		;Titelzeile ausgeben.
			jsr	PutString
			jsr	PrintMemUsed		;Belegten Speicher ausgeben.

			lda	C_WinIcon		;Farbe für Icons setzen.
			jsr	i_UserColor
			b	$00,$01,$0f,$03

			LoadW	r0,Icon_Tab
			jmp	DoIcons

;*** Speicherauslastung anzeigen.
:PrintMemUsed		lda	#$00			;Fenster für Hauptmenü zeichnen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$08,$1f
			w	$00a0,$013f
			lda	#%11111111
			jsr	FrameRectangle
			dec	r2H
			SubVW	1,r4
			lda	#%11111111
			jsr	FrameRectangle
			lda	C_WinIcon		;Farbe 40 Zeichen
			jsr	DirectColor

			LoadW	r0,MenuText01		;Titelzeile ausgeben.
			jsr	PutString

			lda	Copy_SpoolADDR +1	;Größe des belegten Speichers
			sta	r0L			;ermitteln.
			lda	Copy_SpoolADDR +2
			sec
			sbc	Flag_SpoolMinB
			sta	r0H
			lda	#Balken_B
			sta	r1L			;Formel: GRÖßE  * Max_B_Balken
			ldx	#r0L			;        ---------------------
			ldy	#r1L			;           Max_Size_Buffer
			jsr	BMult

			lda	#$00
			sta	r1L
			lda	Flag_SpoolMaxB
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			sta	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv
			lda	#$05			;Leeres Balkenfeld zeichnen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	Balken_Y,(Balken_Y + Balken_H -1)
			w	Balken_X,(Balken_X + Balken_B -1)
			lda	#%11111111
			jsr	FrameRectangle
			lda	C_Balken		;Farbe 40 Zeichen
			jsr	DirectColor

			lda	#$01			;Füllmuster "schwarz" für die
			jsr	SetPattern		;Anzeige des belegten Speichers.

			lda	r0L			;Belegten Speicher anzeigen.
			clc
			adc	#< Balken_X
			sta	r4L
			lda	r0H
			adc	#> Balken_X
			sta	r4H
			jsr	Rectangle

			LoadB	r1L,100			;Prozent-Zahl berechnen.
			ldx	#r0L			;Formel: MAX_%_BALKEN * 100
			ldy	#r1L			;        ------------------
			jsr	BMult			;           Max_B_BALKEN

			LoadW	r1,Balken_B
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			LoadW	r11,Balken_X + Balken_B + 2
			LoadB	r1H,Balken_Y            + 6
			lda	#%11000000
			jsr	PutDecimal		;Prozentzahl ausgeben.
			lda	#"%"
			jmp	SmallPutChar

;******************************************************************************
;*** Unterprogramme für Register-Menü.
;******************************************************************************
;*** Druckertreiber wählen.
:SelectPrinter		jsr	LoadScrData		;Bildschirm-Inhalt zurücksetzen.

			lda	Flag_ExtRAMinUse	;Dialogbox-Flag einlesen.
			and	#%01000000		;Ist Dialogbox aktiv ?
			beq	:51			; => Nein, weiter...

			jsr	SetADDR_DB_SCRN		;Bildschirm unter der Dialogbox
			jsr	SwapRAM			;wieder herstellen.
							;Die Dateiauswahlbox überschreibt
			jsr	DB_SCREEN_LOAD		;sonst den Bildschirminhalt!!!

::51			PushB	Flag_ExtRAMinUse	;Dialogbox-Flag retten.
			jsr	DoFileBox
			bcs	:53			;Abbruch ? Ja, Ende...

			LoadW	r6,dataFileName
			jsr	FindFile		;Druckertreiber auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			LoadB	r0L,%00000001		;Druckertreiber laden.
			LoadW	r6 ,dataFileName	;(Dadurch wird beim C64 der Treiber
			LoadW	r7 ,PRINTBASE		; ins ext.RAM geladen!)
			jsr	GetFile
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			ldy	#$0f
::52			lda	dataFileName  ,y
			sta	PrntFileName,y
			dey
			bpl	:52

			jsr	SetADDR_PrntName
			jsr	StashRAM

::53			PopB	Flag_ExtRAMinUse	;Dialogbox-Flag retten.

			jsr	PrintSpoolMenu
			jmp	RegisterInitMenu

;*** Dateiauswahlbox.
;    Laufwerk-Icons ("A" bis "D") für Dateiauswahlbox definieren:
;    Icons für nicht vorhandene Laufwerke aus Dialogboxtabelle löschen.
:DoFileBox		lda	curDrive
::53			jsr	SetDevice		;Neues Laufwerk aktivieren.
::54			jsr	OpenDisk		;Diskette öffnen.

::55			LoadW	r0 ,Dlg_SlctFile
			LoadW	r5 ,dataFileName	;Zeiger auf Dateiname.
			LoadB	r7L,PRINTER		;Zeiger auf Dateityp.
			LoadW	r10,$0000		;Zeiger auf Datei-Klasse.
			jsr	DoDlgBox		;Dateiauswahlbox aufrufen.

			lda	sysDBData		;Dialogbox-Flag einlesen.
			bpl	:56			;Laufwerkswechsel = Nein, weiter...
			and	#%00001111		;Laufwerksadresse isolieren und
			jmp	:53			;neues Laufwerk aktivieren.

::56			cmp	#OPEN			;Datei öffnen ?
			bne	:57			; => Nein, weiter...
			clc
			rts

::57			cmp	#CANCEL			;Abbruch ?
			beq	:58			; => Ja, Ende...
			cmp	#DISK			;Diskette wechseln ?
			beq	:54			; => Ja, weiter...
::58			sec
			rts

;******************************************************************************
;*** Unterprogramme für Register-Menü.
;******************************************************************************
;*** Nächstes Dokument in Liste wählen.
:NextDokument		jsr	UpdateDokData		;Aktuelle Seitendaten speichern.

			lda	#$00			;Zähler für Einträge löschen.
			sta	r0L

			ldy	CurrentDokument
::51			inc	r0L
			CmpBI	r0L,15			;Alle Einträge durchsucht ?
			beq	:53			; => Ja, Abbruch...

			iny				;Zeiger auf nächstes Dokument.
			cpy	#15			;Tabellenende erreicht ?
			bne	:52			; => Nein, weiter...
			ldy	#$00			;Zeiger auf Tabellenanfang.

::52			lda	DokumentNr    ,y	;Dokument verfügbar ?
			beq	:51			; => Nein, weitersuchen.
			sty	CurrentDokument
			jsr	GetCurDokData		;Daten einlesen und
			jmp	RegisterNextOpt		;Register aktualisieren.
::53			rts

;*** Dokument-Daten aktualisieren.
:UpdateDokData		ldy	CurrentDokument
			ldx	DokNameVec   ,y
			ldy	#$00
::51			lda	TempDokName  ,y
			sta	DokumentName ,x
			inx
			iny
			cpy	#17
			bcc	:51

			ldx	CurrentDokument
			lda	TempDokOpt
			sta	DokumentOpt   ,x
			lda	TempDokPFirst
			sta	DokumentPFirst,x
			lda	TempDokPStart
			sta	DokumentPStart,x
			lda	TempDokPEnd
			sta	DokumentPEnd  ,x
			lda	TempDokPMax
			sta	DokumentPMax  ,x
			lda	TempDokCopy
			sta	DokumentCopy  ,x
			rts

;*** Daten für aktuelles Dokument einlesen.
:GetCurDokData		ldy	CurrentDokument
			lda	DokumentNr    ,y
			sta	TempDokNr
			ldx	DokNameVec    ,y
			ldy	#$00
::51			lda	DokumentName  ,x
			sta	TempDokName   ,y
			inx
			iny
			cpy	#17
			bcc	:51

			ldx	CurrentDokument
			lda	DokumentOpt   ,x
			sta	TempDokOpt
			lda	DokumentPFirst,x
			sta	TempDokPFirst
			lda	DokumentPStart,x
			sta	TempDokPStart
			lda	DokumentPEnd  ,x
			sta	TempDokPEnd
			lda	DokumentPMax  ,x
			sta	TempDokPMax
			lda	DokumentCopy  ,x
			sta	TempDokCopy
			rts

;*** Flag setzen: "Optionen eingestellt".
;    Es werden nur Dokumente gedruckt bei denen dieses Flag gesetzt ist.
:SetOptionFlag		ldx	#$00
::51			lda	DokumentNr,x
			beq	:52
			lda	DokumentOpt,x
			and	#%11111110
			ora	#%00000100
			sta	DokumentOpt,x
::52			inx
			cpx	#15
			bcc	:51
			rts

;******************************************************************************
;*** Unterprogramme für Register-Menü.
;******************************************************************************
;*** Register-Modi definieren.
;    Routinen werden aus Register-Menü aufgerufen.
;    Wird die Option "Alle Seiten drucken" aktiviert, muß die andere Option
;    "Bestimmte Seiten drucken" deaktiviert werden.
:DefMod_Page_All	lda	#%00100000
			b $2c
:DefMod_Page_Some	lda	#%01000000
			eor	TempDokOpt
			sta	TempDokOpt
			jmp	RegisterNextOpt

;*** Eingabe für erste Seite prüfen.
:DefMod_PStart		jsr	TstMod_PStart
			jsr	TstMod_PEnd
			jmp	DefMod_SomePage

;*** Eingabe für letzte Seite prüfen.
:DefMod_PEnd		jsr	TstMod_PEnd
			jsr	TstMod_PStart

;*** Nur bestimmte Seiten drucken.
:DefMod_SomePage	lda	TempDokOpt
			and	#%10011111
			ora	#%00100000
			sta	TempDokOpt
			jmp	RegisterNextOpt

;*** Erste Seite auf Gültigkeit testen.
:TstMod_PStart		lda	TempDokPStart
			bne	:51
			lda	#$01
::51			cmp	TempDokPMax
			beq	:52
			bcc	:52
			lda	TempDokPMax
::52			cmp	TempDokPEnd
			bcc	:53
			sta	TempDokPEnd
::53			sta	TempDokPStart
			rts

;*** Letzte Seite auf Gültigkeit testen.
:TstMod_PEnd		lda	TempDokPEnd
			bne	:51
			lda	#$01
::51			cmp	TempDokPMax
			beq	:52
			bcc	:52
			lda	TempDokPMax
::52			cmp	TempDokPStart
			bcs	:53
			ldx	TempDokPStart
			sta	TempDokPStart
			txa
::53			sta	TempDokPEnd
			rts

;*** Anzahl Kopien überprüfen.
:DefMod_Doks_Copy	lda	TempDokCopy
			bne	:51
			lda	#$01
::51			sta	TempDokCopy
			rts

;******************************************************************************
;*** Druckspeicher analysieren.
;******************************************************************************
;*** Anzahl Seiten zählen.
:AnalyzeAllFiles	lda	#$00
			b $2c
:AnalyzeNewFiles	lda	#$ff
			sta	AnalyzeMode

			lda	Copy_SpoolADDR +0	;Wurden neue Dokumente in den
			ora	Copy_SpoolADDR +1	;Speicher aufgenommen ?
			bne	:51
			lda	Copy_SpoolADDR +2
			cmp	Flag_SpoolMinB
			bne	:51			; => Ja, neue Dokumente einlesen.
			jmp	ResetSpooler

::51			PushB	SpoolVector +0		;Aktuelle Spooler-Position
			PushB	SpoolVector +1		;zwischenspeichern.
			PushB	SpoolVector +2

			bit	AnalyzeMode		;Nur neue Dokumente einlesen ?
			bmi	:52			; => Ja, weiter...

			lda	#$00			;Zeiger auf erstes Byte setzen.
			sta	SpoolVector +0
			sta	SpoolVector +1
			lda	Flag_SpoolMinB
			sta	SpoolVector +2
			jmp	:54

::52			lda	SpoolLastByte+0		;Zeiger auf neue Druckdaten setzen.
			sta	SpoolVector +0
			lda	SpoolLastByte+1
			sta	SpoolVector +1
			lda	SpoolLastByte+2
			bne	:53
			lda	Flag_SpoolMinB
::53			sta	SpoolVector +2

::54			lda	#$00
			sta	DokumentVector		;Zähler für Dokumente löschen.
			sta	DokumentCount

;*** Spoolerdaten decodieren.
:AnalyzeNxByte		jsr	GetByteFromBuf		;Byte aus Speicher einlesen.
			cmp	#$00			;Speicherende erreicht ?
			beq	AnalyzeEnd		;Ja, Ende...
			sta	LastJobCode		;JobCode zwischenspeichern.
			cmp	#$f0			;Grafik-Daten ?
			beq	AnalyzeGrafx		; => Ja, weiter...
			cmp	#$f1			;Farb-Daten ?
			beq	AnalyzeColor		; => Nein, weiter...
			cmp	#$f2			;Text-Daten ?
			beq	AnalyzeText		; => Nein, weiter...
;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: In der MP3/2003-Version gibt es einen zusätzlichen
;Steuerbefehl. Genaue Funktion ist noch unklar.
;In Verbindung dazu wurde eine neue Einsprungadresse im Spooler bei
;:PrintDATA=$7918 ergänzt.
			cmp	#$f3			;Daten ?
			beq	AnalyzeText		; => Nein, weiter...
			cmp	#$fe			;Dokument-Ende ?
			beq	AnalyzeNewDok		; => Nein, weiter...
			cmp	#$ff			;Seiten-Ende ?
			beq	AnalyzeNewPage		; => Nein, weiter...
			lda	#$00
			sta	Buffer
			jsr	StashRAM

;*** Alle Daten eingelesen.
:AnalyzeEnd		inc	LastJobCode		;Zuvor Seite beendet ?
			beq	:51			; => Ja, weiter...
			ldx	DokumentVector		;Anzahl Seiten korrigieren.
			inc	DokumentPEnd ,x
			inc	DokumentPMax ,x

::51			lda	SpoolVector +0		;Letztes analysiertes Byte
			sec				;zwischenspeichern.
			sbc	#$01
			sta	SpoolLastByte+0
			lda	SpoolVector +1
			sbc	#$00
			sta	SpoolLastByte+1
			lda	SpoolVector +2
			sbc	#$00
			sta	SpoolLastByte+2

			PopB	SpoolVector +2		;Aktuelle Spooler-Position
			PopB	SpoolVector +1		;zurücksetzen.
			PopB	SpoolVector +0
			rts

;******************************************************************************
;*** Druckspeicher analysieren.
;******************************************************************************
;*** JobCode: Grafikdaten.
:AnalyzeGrafx		LoadW	r2,640			;Zeiger auf Datenspeicher
			jsr	AddBytes		;korroigieren.
			jmp	AnalyzeNxByte

;*** JobCode: Farbdaten.
:AnalyzeColor		LoadW	r2,80			;Zeiger auf Datenspeicher
			jsr	AddBytes		;korroigieren.
			jmp	AnalyzeNxByte

;*** JobCode: Textzeile.
:AnalyzeText		jsr	GetByteFromBuf
			pha
			jsr	GetByteFromBuf
			sta	r2H
			pla
			sta	r2L			;Zeiger auf Datenspeicher
			jsr	AddBytes		;korroigieren.
			jmp	AnalyzeNxByte

;*** JobCode: Neue Seite.
:AnalyzeNewPage		ldx	DokumentVector
			inc	DokumentPEnd ,x
			inc	DokumentPMax ,x
			jmp	AnalyzeNxByte

;******************************************************************************
;*** Druckspeicher analysieren.
;******************************************************************************
;*** JobCode: Neues Dokument.
:AnalyzeNewDok		inc	DokumentCount		;Dokumente +1.
			jsr	GetByteFromBuf		;Dokument-Nr. einlesen und
			sta	TempDokNr		;zwischenspeichern.

			LoadW	r0,TempDokName		;Name für aktuelles Dokument
			LoadW	r2,$0011		;einlesen und zwischenspeichern.
			jsr	DoFetchRAM

			lda	TempDokNr		;Freien Eintrag oder vorhandenen
			jsr	FindDokEntry		;Eintrag im Speicher suchen.
			txa				;Eintrag gefunden ?
			bpl	:52			; => Ja, weiter...

			ldx	DokumentVector		;Kein freien Eintrag gefunden.
			inx				;Zeiger auf nächsten Eintrag in
			txa				;Liste setzen und Eintrag löschen.
			and	#%00001111
			tax

			lda	#$00
			sta	DokumentNr    ,x
			sta	DokumentOpt   ,x
			sta	DokumentPFirst,x
			sta	DokumentPStart,x
			sta	DokumentPEnd  ,x
			sta	DokumentPMax  ,x
			sta	DokumentCopy  ,x
			sta	DokStartAdrL  ,x
			sta	DokStartAdrM  ,x
			sta	DokStartAdrH  ,x
			tay				;Dokumentname löschen.
::51			sta	DokumentName  ,y
			iny
			cpy	#17
			bcc	:51

::52			stx	DokumentVector		;Zeiger auf Eintrag speichern.

			lda	DokumentNr    ,x	;Wurde Dokument bereits eingelesen ?
			beq	:53			; => Nein, neues Dokument...

			lda	DokumentOpt   ,x
			and	#%00000001		;Dokument bereits gedruckt ?
			beq	:53			; => Ja, Eintrag überschreiben.

;--- Vorhandenes Dokument aktualisieren.
			jsr	SaveDokStartAdr

			lda	DokumentPEnd  ,x	;Seiteninformationen aktualisieren.
			clc
			adc	#$01
			sta	DokumentPFirst,x
			sta	DokumentPStart,x
			sta	DokumentPEnd  ,x
			lda	DokumentOpt   ,x
			and	#%00000011
			ora	#%10000000
			sta	DokumentOpt   ,x
			jmp	AnalyzeNxByte

;--- Neues Dokument in Warteschleife aufnehmen.
::53			lda	TempDokNr		;Eintrag als "belegt" markieren.
			sta	DokumentNr    ,x
			jsr	SaveDokStartAdr		;Startadresse zwischenspeichern.

			lda	#%11011000		;Daten für Dokument mit
			sta	DokumentOpt   ,x	;Standardwerten vorbelegen.
			lda	#$01
			sta	DokumentCopy  ,x
			sta	DokumentPFirst,x
			sta	DokumentPStart,x
			lda	#$00
			sta	DokumentPEnd  ,x
			sta	DokumentPMax  ,x

			ldy	DokNameVec    ,x	;Dokumentname kopieren.
			ldx	#$00
::54			lda	TempDokName   ,x
			sta	DokumentName  ,y
			iny
			inx
			cpx	#17
			bcc	:54
			jmp	AnalyzeNxByte

;******************************************************************************
;*** Druckspeicher analysieren.
;******************************************************************************
;*** Startadresse Dokument zwischenspeichern.
:SaveDokStartAdr	lda	SpoolVector  +0
			sta	DokStartAdrL  ,x
			lda	SpoolVector  +1
			sta	DokStartAdrM  ,x
			lda	SpoolVector  +2
			sta	DokStartAdrH  ,x
			rts

;*** Eintrag für aktuelles Dokument suchen.
:FindDokEntry		ldx	#$00
::51			cmp	DokumentNr    ,x	;Dokument-Nr. identisch ?
			beq	:53			; => Ja, Dokument gefunden, Ende...
			inx				;Zeiger auf nächstes Dokument.
			cpx	#15			;Alle Dokumente getestet ?
			bcc	:51			; => Nein, weiter...

			ldx	#$00			;Freien Eintrag in Tabelle suchen.
::52			lda	DokumentNr    ,x	;Eintrag frei ?
			beq	:53			; => Ja, Eintrag gefunden, Ende...
			inx				;Zeiger auf nächstes Dokument.
			cpx	#15			;Alle Dokumente getestet ?
			bcc	:52			; => Nein, weiter...
			ldx	#$ff			;Tabelle voll!
::53			rts

;*** Variablen löschen.
:ResetSpooler		jsr	i_FillRam
			w	(SpoolSysVarEnd-SpoolSysVar)
			w	SpoolSysVar
			b	$00

			lda	#$00
			sta	SpoolVector +0
			sta	SpoolVector +1
			lda	Flag_SpoolMinB
			sta	SpoolVector +2
			rts

;*** Byte aus Buffer einlesen.
:GetByteFromBuf		LoadW	r0,Buffer
			LoadW	r2,$0001
			jsr	DoFetchRAM
			lda	Buffer
			rts

;*** Zeiger auf Datenspeicher korrigieren.
:AddBytes		lda	r2L
			clc
			adc	SpoolVector +0
			sta	SpoolVector +0
			lda	r2H
			adc	SpoolVector +1
			sta	SpoolVector +1
			lda	#$00
			adc	SpoolVector +2
			sta	SpoolVector +2
			rts

;*** Mehrere Bytes aus Speicher einlesen.
;    Übergabe:		r0 = Zeiger auf Speicher.
;			r2 = Anzahl Bytes.
:DoFetchRAM		lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	SpoolVector +0		;Startadresse SpoolerRAM innerhalb
			sta	r1L			;64K-Speicherbank.
			lda	SpoolVector +1
			sta	r1H

			ldx	SpoolVector +2		;Zeiger auf aktuelle Speicherbank.

			lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3L
			lda	r1H
			adc	r2H
			bcc	:51			; => Nein, weiter...
			ora	r3L
			beq	:51			; => Nein, weiter...

			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	#$00			;Anzahl Bytes innerhalb
			sec				;aktueller 64K-Speicherbank
			sbc	r1L			;berechnen.
			sta	r2L
			lda	#$00
			sbc	r1H
			sta	r2H

			ldx	SpoolVector +2		;Zeiger auf aktuelle Speicherbank.
			stx	r3L
			jsr	FetchRAM		;Daten in REU speichern.

			lda	#$00			;Zeiger auf anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

			pla				;Anzahl Bytes in nächster
			sec				;Speicherbank berechnen.
			sbc	r2L
			sta	r2L
			pla
			sbc	r2H
			sta	r2H

			ldx	r3L			;Zeiger auf nächste Speicherbank
			inx				;für Restbytes setzen.

::51			stx	r3L			;Zeiger auf Speicherbank setzen.
			jsr	FetchRAM		;Bytes in REU kopieren.

			pla
			sta	r2L
			pla
			sta	r2H
			jmp	AddBytes

;******************************************************************************
;*** Fortschritts-Anzeige für Drucker-Spooler.
;******************************************************************************
;*** Sprites initialisieren.
;    Die "Fortschrittsanzeige" wird beim C64 mit Sprites erstellt. Während des
;    Ausdrucks darf der Bereich des Bildschirmspeichers nicht verändert werden,
;    da die Applikation in diesem Bereich die Druckdaten ablegen könnte. Dies
;    ist z.B. bei GeoPublish und GeoHelpView der Fall. Würde der Bildschirm-
;    speicher durch die Anzeige modifiziert, dann würden auch die zu druckenden
;    Daten verändert. Dies ist aber nur bei der Aufnahme der Druckdaten
;    in den Speicher der Fall. Der Druckerspooler hat diese Probleme nicht, da
;    bereits alle Daten zum drucken in der REU vorliegen. Um aber ein einheit-
;    liches Erscheinungsbild zu gewährleisten, verwendet der Druckerspooler
;    das gleiche Verfahren wie der Druckertreiber.
:InitSprites		ldy	#62			;Original-Sprite-Grafiken speichern
::51			lda	spr6pic   ,y		;und Sprite für Fortschrittsanzeige
			sta	spr6Buf   ,y		;erstellen.
			lda	SprBufCalc,y
			sta	spr6pic   ,y
			lda	spr7pic   ,y
			sta	spr7Buf   ,y
			lda	#$ff
			sta	spr7pic   ,y
			dey
			bpl	:51

			ldx	obj6Pointer		;Zeiger auf Sprites retten und
			stx	obj6Buf			;Zeiger auf Sprites für die
			ldx	obj7Pointer		;Fortschrittsanzeige setzen.
			stx	obj7Buf

			ldx	#$2e
			stx	obj6Pointer
			inx
			stx	obj7Pointer

			php				;Spritedaten zwischenspeichern.
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	mobenble
			sta	mobenbleBuf

			ldy	#$03
::52			lda	mob6xpos,y
			sta	sprXYBuf,y
			dey
			bpl	:52
			lda	msbxpos
			sta	sprXYBuf +4

			lda	mobx2
			sta	mobx2Buf
			and	#%00111111
			sta	mobx2
			lda	moby2
			sta	moby2Buf
			and	#%00111111
			sta	moby2

			lda	$d02d
			sta	col6Buf
			lda	$d02e
			sta	col7Buf

			lda	#$00			;Farbe für Sprite-Anzeige
			sta	$d02d			;definieren.
			lda	#$03
			sta	$d02e

			stx	CPU_DATA
			plp
			rts

;******************************************************************************
;*** Fortschritts-Anzeige für Drucker-Spooler.
;******************************************************************************
;*** Info-Anzeige berechnen.
:CalcInfoSprite		PushW	r0			;Register ":r0" bis ":r2" zwischen-
			PushW	r1			;speichern (Zeiger auf Druckdaten).
			PushW	r2

			lda	SpoolVector +1		;Belegten Speicher berechnen:
			sta	r0L			;Formel:
			sec				;           CUR_BUFFER
			sbc	Flag_SpoolMinB		;  ------------------------------
			sta	r0H			;  MAX_BUFFER_USED / Max_H_Balken
			lda	SpoolVector +2
			LoadW	r1,Status_H
			ldx	#r0L
			ldy	#r1L
			jsr	DMult

			lda	Copy_SpoolADDR +1
			sta	r1L
			lda	Copy_SpoolADDR +2
			sec
			sbc	Flag_SpoolMinB
			sta	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	#Status_H -1		;"Anzeigebalken" füllen.
			sec
			sbc	r0L
			bcs	:51
			lda	#$00
::51			sta	:52 +1
			asl
			clc
::52			adc	#$ff
			clc
			adc	#$02
			tay
			lda	#$ff
::53			sta	spr6pic,y
			iny
			iny
			iny
			cpy	#63
			bcc	:53

			LoadB	r3L,6			;Sprites aktivieren.
			LoadW	r4 ,Status_X
			LoadB	r5L,Status_Y
			jsr	PosSprite
			jsr	EnablSprite
			inc	r3L
			jsr	PosSprite
			jsr	EnablSprite

			PopW	r2			;Register ":r0" bis ":r2" zurück-
			PopW	r1			;setzen.
			PopW	r0

			ldx	#$00			;Wichtig: Flag für "Kein Fehler".
			rts

;******************************************************************************
;*** Fortschritts-Anzeige für Drucker-Spooler.
;******************************************************************************
;*** Sprites initialisieren.
:KillSprites		ldy	#62			;Sprite-Grafiken zurücksetzen.
::51			lda	spr6Buf   ,y
			sta	spr6pic   ,y
			lda	spr7Buf   ,y
			sta	spr7pic   ,y
			dey
			bpl	:51

			lda	obj6Buf			;Sprite-Vektoren zurücksetzen.
			sta	obj6Pointer
			lda	obj7Buf
			sta	obj7Pointer

			php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	mobenbleBuf		;Sprite-Daten zurücksetzen.
			sta	mobenble

			ldy	#$03
::52			lda	sprXYBuf,y
			sta	mob6xpos,y
			dey
			bpl	:52
			lda	sprXYBuf +4
			sta	msbxpos

			lda	mobx2Buf
			sta	mobx2
			lda	moby2Buf
			sta	moby2

			lda	col6Buf			;Sprite-Farben zurücksetzen.
			sta	$d02d
			lda	col7Buf
			sta	$d02e

			stx	CPU_DATA
			plp
			rts

;******************************************************************************
;*** Drucker-Spooler.
;******************************************************************************
:DoSpoolData		jsr	SetADDR_SpoolDat	;Puffer-Bereich speichern.
			jsr	StashRAM		;(Druckspeicher).
			jsr	InitSprites		;Fortschrittsanzeige aktivieren.
			jsr	GetPrntDrv		;Druckertreiber laden
			jsr	SpoolIntNxDok		;Daten drucken.
			jsr	KillSprites		;Sprites löschen.
			jsr	SetADDR_SpoolDat	;Puffer-Bereich zurücksetzen.
			jsr	FetchRAM

;*** Druckertreiber wieder laden
:GetPrntDrv		jsr	SetADDR_Printer		;Zeiger auf Druckertreiber in REU,
			jsr	SwapRAM			;Druckertreiber einlesen.
			jsr	SetADDR_PrntHdr		;Zeiger auf Infoblock für
			jmp	SwapRAM			;aktuellen Druckertreiber.

;*** Druckdaten ausgeben.
:SpoolIntNxDok		jsr	FindSpoolDok		;Aktives Dokument suchen.

			ldx	SpoolDokument		;Dokument gefunden ?
			bpl	SpoolNextDok		; => Ja, weiter...
			inx				;Flag löschen: "Daten im Speicher".
			stx	AllDataPrinted

			lda	r0H			;Anzahl noch nicht gedruckter
			pha				;Dokumente zwischenspeichern.
			jsr	AnalyzeNewFiles		;Warteschlange aufnehmen.
			pla
			tay

			ldx	DokumentCount		;Neue Dokumente in Warteschlange ?
			bne	SpoolIntNxDok		; => Ja, weiter...

			lda	#%11000000		;Existieren noch nicht gedruckte
			cpy	#$00			;Dokumente in der Warteschlange ?
			bne	SpoolDataEnd		; => Nein, Ende...

;*** Spoolerdaten löschen, Reset ausführen.
:ClearSpooler		lda	#$00			;Spooler deaktivieren.
			sta	Copy_SplCurDok
			sta	Copy_SplMaxDok
			sta	Copy_SpoolADDR +0
			sta	Copy_SpoolADDR +1
			lda	Flag_SpoolMinB
			sta	Copy_SpoolADDR +2

			jsr	ResetSpooler

			lda	#%10000000
:SpoolDataEnd		sta	Copy_Spooler		;Spooler-Flag setzen.
			rts				;Spooler beenden.

;*** Weitere Dokumente drucken.
:SpoolNextDok		lda	#$ff			;Flag setzen: "Daten im Speicher".
			sta	AllDataPrinted
			lda	SpoolDokument		;Daten für aktuelles Dokument in
			sta	CurrentDokument		;Zwischenspeicher einlesen.
			jsr	GetCurDokData
			jsr	InitForPrint		;Druckertreiber initialisieren.

;*** Nächste Kopie eines Dokuments drucken.
:SpoolNextCopy		ldx	SpoolDokument
			lda	DokumentPFirst ,x	;Zeiger auf erste Seite im
			sta	SpoolDokPage		;Dokument setzen.
			jsr	SetCurDokStart		;Zeiger auf Startadr. Dokument.

;*** Nächste Seite spoolen.
:SpoolNewPage		lda	#$ff			;Flag für "Neue Seite" setzen um
			sta	NewPage			;Druckertreiber zu initialisieren.

;*** Spoolerdaten decodieren.
:SpoolerLoop		jsr	CalcInfoSprite		;Fortschrittsanzeige aktualisieren.

			lda	pressFlag		;Abbruch gewünscht ?
			bpl	:52			; => Nein, weiter...
			sei				;Anwender-Abbruch, IRQ sperren.
			LoadW	appMain,:51		;MainLoop ausführen und damit die
			jmp	MainLoop		;gedrückte Taste einlesen.

::51			pla				;Rücksprung aus MainLoop löschen.
			pla				;(Vektor wird später gelöscht!)
			lda	#%10000000		;Spoolermenü-Flag löschen und
			ora	Flag_SpoolCount		;Verzögerungszeit aktivieren.
			sta	Copy_Spooler
			rts

;*** Spooler fortsetzen. Zeichen einlesen und Daten drucken.
::52			jsr	GetByteFromBuf		;Befehlscode einlesen.
			cmp	#$00			;Speicherende erreicht ?
			beq	:63			; => Ja, nächstes Dokument/Ende...
			cmp	#$f0			;Grafikdaten ?
			beq	:61			; => Ja, Grafikzeile drucken...
			cmp	#$f2			;Textdaten ?
			beq	:62			; => Ja, Textzeile drucken...
;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: In der Version von 2003 gibt es einen zusätzlichen
;Steuerbefehl. Genaue Funktion ist noch unklar.
;In Verbindung dazu wurde eine neue Einsprungadresse im Spooler bei
;:PrintDATA=$7918 ergänzt.
			cmp	#$f3			;Textdaten ?
			beq	:65			; => Ja, Textzeile drucken...
			cmp	#$fe			;Neues Dokument ?
			beq	:63			; => Ja, Dokument auswerten...
			cmp	#$ff			;Neue Seite ?
			beq	:64			; => Nächste Seite auswerten...
			bne	:63			;Illegaler Code, nächstes Dokument!

;*** Sprungtabelle für DruckerCodes.
::61			jmp	DoGrafx			; => Grafik drucken.
::62			jmp	DoASCII			; => Text drucken.
::65			jmp	DoDATA			; => Text drucken.
::63			jmp	DoNewDok		; => Neues Dokument drucken.
::64			jmp	DoNewPage		; => Neue Seite drucken.

;******************************************************************************
;*** Drucker-Spooler.
;******************************************************************************
;*** Nächste Kopie drucken oder weiter mit nächstem Dokument.
:DoNewDok		dec	TempDokCopy		;Alle Kopien gedruckt ?
			bne	:52			; => Nein, nächste Kopie drucken.

			ldx	SpoolDokument
			lda	DokumentOpt,x
			and	#%01000000		;Alle Seiten drucken ?
			beq	:51			; => Nein, nicht löschen.
			lda	#%10000011		;Dokument aus Warteschlange löschen.
			b $2c
::51			lda	#%00000011
			eor	DokumentOpt,x		;und aus Warteschlange entfernen.
			sta	DokumentOpt,x
			jmp	SpoolIntNxDok		; => Nächstes Dokument.
::52			jmp	SpoolNextCopy 		; => Nächste Kopie.

;*** Nächste Seite drucken oder weiter mit nächstem Dokument.
:DoNewPage		bit	NewPage			;Neue Seite begonnen?
			bmi	:noStop			;>ja dann kein StopPrint
			jsr	StopPrint		;Seitenende, Papiervorschub.
::noStop		inc	SpoolDokPage		;Zeiger auf nächste Seite.

			ldx	SpoolDokument
			lda	SpoolDokPage
			cmp	DokumentPEnd   ,x	;Alle Seiten gedruckt ?
			beq	:51			; => Nein, weiter...
			bcs	DoNewDok		; => Ja, nächste Kopie/Dokument.
::51			jmp	SpoolNewPage		;Nächste Seite drucken.

;*** Grafikdaten ausgeben.
:DoGrafx		LoadW	r2,640
			jsr	SetVec_GrafxBuf
			jsr	DoFetchRAM

			PushW	SpoolVector +0		;Nächstes Zeichen einlesen.
			PushB	SpoolVector +2		;Dieses Zeichen gibt Auskunft
			jsr	GetByteFromBuf		;darüber ob auch Farbdaten
			tax				;gespeichert wurden.
			PopB	SpoolVector +2
			PopW	SpoolVector +0

			lda	#$00
			sta	r2L
			sta	r2H
			cpx	#$f1			;Farbdaten gespeichert ?
			bne	:51			;Nein, weiter...

			jsr	GetByteFromBuf		;Befehlscode "Farbe" überlesen.
			LoadW	r0,ColorBuffer		;Farbdaten aus REU einlesen.
			LoadW	r2,80
			jsr	DoFetchRAM

::51			jsr	TestCurPage		;Aktuelle Seite drucken ?
			txa
			bne	:53			; => Nein, weiter...

			bit	NewPage			;Neue Seite beginnen ?
			bpl	:52			; => Nein, weiter...
			inc	NewPage			;Flag für "Neue Seite" löschen.
			jsr	SetVec_DataBuf		;Druckertreiber initialisieren.
			jsr	StartPrint

::52			LoadW	r2,ColorBuffer
			jsr	SetVec_GrafxBuf
			jsr	SetVec_DataBuf
			jsr	PrintBuffer		;Grafikzeile drucken.
::53			jmp	SpoolerLoop		;Nächste Zeile drucken.

;*** Daten in Druckspeicher übertragen.
:Label1			b $00

:DoDATA			dec	Label1

;*** Textdaten in Druckspeicher übertragen.
;    xReg = $00, Daten gespeichert.
;    xReg = $0D, Speicher voll!
:DoASCII		jsr	GetByteFromBuf		;Anzahl Zeichen in Zeile
			pha				;einlesen.
			jsr	GetByteFromBuf
			sta	r2H
			pla
			sta	r2L

			jsr	SetVec_GrafxBuf
			jsr	DoFetchRAM		;TextDaten einlesen.

			jsr	TestCurPage		;Aktuelle Seite drucken ?
			txa
			bne	:52			; => Nein, weiter...

			ldx	NewPage			;Neue Seite beginnen ?
			bpl	:51			; => Nein, weiter...
			inc	NewPage			;Flag für "Neue Seite" löschen.
			jsr	SetVec_DataBuf		;Druckertreiber initialisieren.
			jsr	StartASCII
			jsr	SetVec_DataBuf
			jsr	SetNLQ
::51			jsr	SetVec_GrafxBuf
			jsr	SetVec_DataBuf

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: In der MP3/2003-Version wurde folgender Code bis zum
;Label :51a ergänzt. Genaue Funktion noch unklar.
			bit	Label1
			bpl	:51a
			inc	Label1
			jsr	PrintDATA		;Daten drucken.
			jmp	SpoolerLoop		;Nächste Zeile drucken.

::51a			jsr	PrintASCII		;Textzeile drucken.
::52			jmp	SpoolerLoop		;Nächste Zeile drucken.

;*** Zeiger auf Datenpuffer setzen.
:SetVec_DataBuf		LoadW	r1,Data_Buffer
			rts

;*** Zeiger auf Datenpuffer setzen.
:SetVec_GrafxBuf	LoadW	r0,GrafxBuffer
			rts

;******************************************************************************
;*** Drucker-Spooler.
;******************************************************************************
;*** Aktuelle Seite drucken ?
:TestCurPage		ldx	#$00
			lda	TempDokOpt
::51			and	#%01000000		;Alle Seiten drucken ?
			bne	:55			; => Ja, weiter...

			lda	SpoolDokPage		;Seite im gültigen Bereich ?
			cmp	TempDokPStart
			bcc	:54
			cmp	TempDokPEnd
			beq	:52			; => Ja, weiter...
			bcs	:54			; => Nein, Ende...

::52			lsr
			bcc	:53
			lda	TempDokOpt
			and	#%00010000		;Ungerade Seiten drucken ?
			bne	:55			; => Ja  , weiter...
			beq	:54			; => Nein, Ende...

::53			lda	TempDokOpt
			and	#%00001000		;Gerade Seiten drucken ?
			bne	:55			; => Ja  , weiter...

::54			ldx	#$ff			;Flag: "Seite ungültig".
::55			rts

;*** Aktuelles Dokument in Warteschlange suchen.
;    Entweder ist in einem der Optionsbytes der 15 Dokumente Bit #1 gesetzt
;    (Dokument in Bearbeitung) oder es wird mit dem ersten Dokument begonnen,
;    welches gedruckt werden soll und noch nicht gedruckt wurde.
:FindSpoolDok		ldx	#$ff			;Nr. des Dokuments das gedruckt
			stx	r0L			;werden soll, löschen.
			inx				;Zähler für nicht gedruckte
			stx	r0H			;Dokumente löschen.

			ldx	#14
::51			lda	DokumentNr   ,x		;Dokument gültig ?
			beq	:55			; => Nein, weiter...

			ldy	DokumentOpt,x		;Optionsdaten einlesen.
			tya
			and	#%00000010		;Dokument in Bearbeitung ?
			bne	:52			; => Ja, Dokument gefunden, Ende...

			tya
			and	#%00000001		;Dokument bereits gedruckt ?
			bne	:53			; => Ja, nicht drucken.

			tya
			and	#%00000100		;Optionen bereits festgelegt ?
			beq	:54			; => Nein, nicht drucken.

			tya
			and	#%10000000		;Soll Dokument gedruckt werden ?
			beq	:54			; => Nein, weiter...
			stx	r0L			;Dokument merken und
			bne	:55 			;weitersuchen.
::52			stx	SpoolDokument		;Dokument merken und Ende...
			rts

::53			tya				;Optionsdaten einlesen.
			and	#%01000000		;Dokument in Bearbeitung ?
			bne	:55			; => Ja, Dokument gefunden, Ende...

::54			inc	r0H			;Nicht gedruckte Dokumente +1.
::55			dex				;Alle Dokumente getestet ?
			bpl	:51			; => Nein, weiter...

			ldx	r0L			;Zu druckendes Dokument gefunden ?
			bmi	:52			; => Nein, Ende...
			stx	SpoolDokument		;Aktives Dokument setzen.
			lda	DokumentOpt,x		;Optionsdaten einlesen und
			ora	#%00000010		;Bearbeitungsflag setzen.
			sta	DokumentOpt,x

;*** Zeiger auf Startadresse Dokument setzen.
:SetCurDokStart		ldx	SpoolDokument
			lda	DokStartAdrL ,x
			sta	SpoolVector +0
			lda	DokStartAdrM ,x
			sta	SpoolVector +1
			lda	DokStartAdrH ,x
			sta	SpoolVector +2
			rts

;*** Aktuelle Position des Spooler speichern.
:SaveSysData		lda	Flag_SpoolADDR +0
			sta	Copy_SpoolADDR +0
			lda	Flag_SpoolADDR +1
			sta	Copy_SpoolADDR +1
			lda	Flag_SpoolADDR +2
			sta	Copy_SpoolADDR +2
			lda	Flag_Spooler
			sta	Copy_Spooler
			lda	Flag_SplCurDok
			sta	Copy_SplCurDok
			lda	Flag_SplMaxDok
			sta	Copy_SplMaxDok

			ldy	#$00			;ZeroPage zwischenspeichern.
::51			lda	zpage   ,y
			sta	zpageBuf,y
			iny
			bne	:51

;--- Ergänzung: 04.09.21/M.Kanet
;GeoWrite verändert ZeroPage-Adressen
;im Bereich von $0080-$00FF. Einige der
;Kernal-Routinen verursachen Probleme,
;wenn hier ungültige Werte vorliegen:
;Innerhalb von GeoWrite wird ab $0094
;ein Zeiger auf die aktuelle Cursor-
;Position innerhalb der Seite abgelegt.
;In Verbindung nur mit einer RAMLink
;(ohne SuperCPU) führt dann ein Aufruf
;von ":LISTEN"=$FFB1 zum Absturz.
;Ursache ist die Adresse $0094 die hier
;ausgelesen wird und in Abhängigkeit
;des Wertes <$80 oder >=$80 das ROM der
;RAMLink umgeschaltet wird. Bei einem
;Wert >=$80 führt das zum Absturz bei
;$ED2D: JMP $(DE34)
			lda	#$00			;ZeroPage-Adressen
			sta	STATUS			;initialisieren.
			sta	C3PO
			sta	BSOUR
			rts

;*** Aktuelle Position des Spooler zurücksetzen.
:LoadSysData		lda	Copy_SpoolADDR +0
			sta	Flag_SpoolADDR +0
			lda	Copy_SpoolADDR +1
			sta	Flag_SpoolADDR +1
			lda	Copy_SpoolADDR +2
			sta	Flag_SpoolADDR +2
			lda	Copy_Spooler
			sta	Flag_Spooler
			lda	Copy_SplCurDok
			sta	Flag_SplCurDok
			lda	Copy_SplMaxDok
			sta	Flag_SplMaxDok

			ldy	#$00			;ZeroPage zurücksetzen.
::51			lda	zpageBuf,y
			sta	zpage   ,y
			iny
			bne	:51
			rts

;*** Variablen und Speicherbereiche retten.
:SaveMemData		jsr	SetADDR_RegMem		;Bereich Register-Speicher retten.
			jsr	StashRAM
			jsr	SetADDR_OSVarBuf	;Bereich $8000-$8BFF speichern.
			jsr	StashRAM		;(GEOS-Variablen)
			jsr	SetADDR_MPVarBuf	;Bereich $9F00-$9FFF speichern.
			jsr	StashRAM		;(MP3-Variablen)

:SaveScrData		jsr	SetADDR_SpoolScr	;Bereich $A000-$BF3F speichern.
			jsr	StashRAM		;(Grafikspeicher).
			jsr	SetADDR_SpoolCol	;Bereich $8C00-$8FE7 speichern.
			jmp	StashRAM		;(Farbdatenspeicher).

;*** Variablen und Speicherbereiche zurücksetzen.
:LoadMemData		jsr	SetADDR_MPVarBuf	;Bereich $9F00-$9FFF zurücksetzen.
			jsr	FetchRAM
			jsr	SetADDR_OSVarBuf	;Bereich $8000-$8BFF zurücksetzen.
			jsr	FetchRAM
			jsr	SetADDR_RegMem		;Bereich Register-Speicher laden.
			jsr	FetchRAM
:LoadScrData		jsr	SetADDR_SpoolCol	;Bereich $8C00-$8FE7 zurücksetzen.
			jsr	FetchRAM
			jsr	SetADDR_SpoolScr	;Bereich $A000-$BF3F zurücksetzen.
			jmp	FetchRAM

;*** Zeiger auf neue GEOS-Routinen im RAM.
:SetADDR_SpoolScr	ldy	#$01 *6 -1
			b $2c
:SetADDR_SpoolCol	ldy	#$02 *6 -1
			b $2c
:SetADDR_SpoolDat	ldy	#$03 *6 -1
			b $2c
:SetADDR_OSVarBuf	ldy	#$04 *6 -1
			b $2c
:SetADDR_MPVarBuf	ldy	#$05 *6 -1
			b $2c
:SetADDR_RegMem		ldy	#$06 *6 -1
			b $2c
:SetADDR_PrntName	ldy	#$07 *6 -1
			ldx	#$05
::51			lda	MP3_64K_ADDR,y
			sta	r0L         ,x
			dey
			dex
			bpl	:51
			lda	MP3_64K_DATA
			sta	r3L
			rts

;*** Zeiger auf externe Routinen in REU.
:MP3_64K_ADDR		w SCREEN_BASE,R3A_SP_GRAFX
			w	 R3S_SP_GRAFX
			w COLOR_MATRIX,R3A_SP_COLOR
			w	 R3S_SP_COLOR
			w StartBuffer,R3A_SPOOLDAT
			w	 R3S_SPOOLDAT
			w SYSVAR_BASE,R3A_OSVARBUF
			w	 R3S_OSVARBUF
			w EXTVAR_BASE,R3A_MPVARBUF
			w	 R3S_MPVARBUF
			w LOAD_REGISTER,R3A_REGMEMBUF
			w	 R3S_REGMEMBUF
			w PrntFileName,R3A_OSVARBUF +(PrntFileName -OS_BASE)
			w	 17

;*** Daten für Dialogbox.
:Dlg_SlctFile		b %10000001
			b DBGETFILES!DBSETDRVICON ,$03,$03
			b OPEN                    ,$11,$08
			b DISK                    ,$11,$38
			b CANCEL                  ,$11,$4c
			b NULL

;*** Menütexte.
if LANG = LANG_DE
:MenuText00		b GOTOXY
			w $0008
			b $06
			b PLAINTEXT
			b "GDOS64 - Druckerspooler",NULL

:MenuText01		b GOTOXY
			w $00a8
			b $16
			b "Speicher:"
			b NULL
endif

if LANG = LANG_EN
:MenuText00		b GOTOXY
			w $0008
			b $06
			b PLAINTEXT
			b "GDOS64 - Printer spooler",NULL

:MenuText01		b GOTOXY
			w $00a8
			b $16
			b "Memory:"
			b NULL

endif

;*** Icon-Tabelle.
:Icon_Tab		b $03
			w $0000
			b $00

			w Icon_00
			b $00,$08,Icon_00x,Icon_00y
			w SpoolMenuExit

			w Icon_01
			b $05,$08,Icon_01x,Icon_01y
			w SpoolMenuPrint

			w Icon_02
			b $0a,$08,Icon_02x,Icon_02y
			w SpoolReset

;*** Register-Tabelle.
:RegisterTab		b $30,$bf
			w $0008,$0137

			b 2				;Anzahl Einträge.

			w RegTName1
			w RegTMenu1

			w RegTName2
			w RegTMenu2

:RegTName1		w Icon_10
			b $02,$28,Icon_10x,Icon_10y

:RegTName2		w Icon_11
			b $08,$28,Icon_11x,Icon_11y

;*** Daten für Register "Dokument".
:RegTMenu1		b 14

			b BOX_NUMERIC
				w RegTText1_01
				w $0000
				b $40
				w $0040
				w TempDokNr
				b $02 ! NUMERIC_RIGHT ! NUMERIC_BYTE
::u01			b BOX_STRING_VIEW
				w $0000
				w $0000
				b $40
				w $0058
				w TempDokName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b $3f,$48
				w $00d8,$00e0
			b BOX_ICON
				w $0000
				w NextDokument
				b $40
				w $00d8
				w RegTIcon1_01
				b (:u01 - RegTMenu1 -1)/11 +1
			b BOX_FRAME
				w RegTText1_00
				w $0000
				b $58,$af
				w $0018,$0127
			b BOX_OPTION
				w RegTText1_02
				w $0000
				b $a0
				w $00a8
				w TempDokOpt
				b %10000000
			b BOX_OPTION
				w RegTText1_03
				w DefMod_Page_All
				b $60
				w $0028
				w TempDokOpt
				b %01000000
			b BOX_OPTION
				w RegTText1_04
				w DefMod_Page_Some
				b $70
				w $0028
				w TempDokOpt
				b %00100000
			b BOX_NUMERIC
				w RegTText1_05
				w DefMod_PStart
				b $80
				w $0038
				w TempDokPStart
				b $02 ! NUMERIC_LEFT ! NUMERIC_BYTE
			b BOX_NUMERIC
				w RegTText1_06
				w DefMod_PEnd
				b $90
				w $0038
				w TempDokPEnd
				b $02 ! NUMERIC_LEFT ! NUMERIC_BYTE
			b BOX_OPTION
				w RegTText1_07
				w DefMod_SomePage
				b $80
				w $00a8
				w TempDokOpt
				b %00010000
			b BOX_OPTION
				w RegTText1_08
				w DefMod_SomePage
				b $90
				w $00a8
				w TempDokOpt
				b %00001000
			b BOX_NUMERIC
				w RegTText1_09
				w DefMod_Doks_Copy
				b $a0
				w $0028
				w TempDokCopy
				b $02 ! NUMERIC_LEFT ! NUMERIC_BYTE
			b BOX_OPTION_VIEW
				w RegTText1_10
				w $0000
				b $40
				w $00e8
				w TempDokOpt
				b %00000001

:RegTIcon1_01		w Icon_40
			b $1c,$68,$01,$08
			b USE_COLOR_INPUT

;*** Texte für Register-Karte: "Einstellungen".
if LANG = LANG_DE
:RegTText1_00		b "EINSTELLUNGEN:",0
:RegTText1_01		b	$20,$00,$46, "Nr.",0
:RegTText1_02		b	$b8,$00,$a6, "Dokument drucken",0
:RegTText1_03		b	$38,$00,$66, "Alle Seiten drucken",0
:RegTText1_04		b	$38,$00,$76, "Nur bestimmte Seiten drucken",0
:RegTText1_05		b	$50,$00,$86, "Erste Seite",0
:RegTText1_06		b	$50,$00,$96, "Letzte Seite",0
:RegTText1_07		b	$b8,$00,$86, "Ungerade Seiten",0
:RegTText1_08		b	$b8,$00,$96, "Gerade Seiten",0
:RegTText1_09		b	$40,$00,$a6, "Anzahl Kopien",0
:RegTText1_10		b	$f4,$00,$46, "Gedruckt",0
endif

if LANG = LANG_EN
:RegTText1_00		b "SETTINGS:",0
:RegTText1_01		b	$20,$00,$46, "No.",0
:RegTText1_02		b	$b8,$00,$a6, "Print file",0
:RegTText1_03		b	$38,$00,$66, "Print all pages",0
:RegTText1_04		b	$38,$00,$76, "Print only selected pages",0
:RegTText1_05		b	$50,$00,$86, "First page",0
:RegTText1_06		b	$50,$00,$96, "Last page",0
:RegTText1_07		b	$b8,$00,$86, "Odd pages",0
:RegTText1_08		b	$b8,$00,$96, "Even pages",0
:RegTText1_09		b	$40,$00,$a6, "Number of copies",0
:RegTText1_10		b	$f4,$00,$46, "printed",0
endif

;*** Register-Karte: "DRUCKER".
:RegTMenu2		b 4
			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$6f
				w $0018,$0127
::u01			b BOX_STRING_VIEW
				w RegTText2_02
				w $0000
				b $48
				w $0048
				w PrntFileName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b $47,$50
				w $00c8,$0d0
			b BOX_ICON
				w RegTText2_03
				w SelectPrinter
				b $48
				w $00c8
				w RegTIcon1_01
				b (:u01 - RegTMenu2 -1)/11 +1

;*** Texte für Register-Karte: "DRUCKER".
if LANG = LANG_DE
:RegTText2_01		b "AKTUELLER DRUCKER:",0
:RegTText2_02		b	$20,$00,$4e, "Name:",0
:RegTText2_03		b	$20,$00,$5e, "Dieser Druckertreiber wird für alle"
			b GOTOXY,$20,$00,$66, "Druckaufträge verwendet.",0
endif

if LANG = LANG_EN
:RegTText2_01		b "CURRENT PRINTER:",0
:RegTText2_02		b	$20,$00,$4e, "Name:",0
:RegTText2_03		b	$20,$00,$5e, "This printerdriver would be used"
			b GOTOXY,$20,$00,$66, "for all print-jobs.",0
endif

;*** Icons.
if LANG = LANG_DE
:Icon_00
<MISSING_IMAGE_DATA>
:Icon_00x		= .x
:Icon_00y		= .y

:Icon_01
<MISSING_IMAGE_DATA>
:Icon_01x		= .x
:Icon_01y		= .y
endif

if LANG = LANG_EN
:Icon_00
<MISSING_IMAGE_DATA>
:Icon_00x		= .x
:Icon_00y		= .y

:Icon_01
<MISSING_IMAGE_DATA>
:Icon_01x		= .x
:Icon_01y		= .y
endif

:Icon_02
<MISSING_IMAGE_DATA>
:Icon_02x		= .x
:Icon_02y		= .y

if LANG = LANG_DE
:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

:Icon_11
<MISSING_IMAGE_DATA>
:Icon_11x		= .x
:Icon_11y		= .y
endif

if LANG = LANG_EN
:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

:Icon_11
<MISSING_IMAGE_DATA>
:Icon_11x		= .x
:Icon_11y		= .y
endif

:Icon_40
<MISSING_IMAGE_DATA>

:SpoolerLastByte	brk

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_SPOOLER + R2S_SPOOLER -1
;******************************************************************************

;*** Startadresse Druckdatenspeicher.
;    Der Original-Inhalt wird vor dem Druckbeginn in die REU ausgelagert.
:StartBuffer
:GrafxBuffer		= StartBuffer
:ColorBuffer		= StartBuffer +640
:Data_Buffer		= StartBuffer +640 +80

;******************************************************************************
			g LOAD_REGISTER - R3S_SPOOLDAT -1
;******************************************************************************
