; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateiliste initialisieren.
:InitSortMenu		LoadW	keyVector,testKeys
			rts

;*** Tastaturabfrage.
:testKeys		php				;IRQ sperren.
			sei

			ldx	#$00
::loop			lda	keyTab,x		;Nächste Taste einlesen.
			beq	:exit			;$00 => Ja, Ende...
			cmp	keyData			;Taste gedrückt?
			beq	:found			; => Ja, weiter...
			inx				;Zeiger auf nächste Taste.
			bne	:loop			;Weitersuchen.

::exit			plp				;Keine Taste gefunden.
			rts				;Ende.

::found			txa				;Zeiger auf Tastenfunktion
			asl				;einlesen.
			tay
			jsr	execRout		;Funktion aufrufen.
			plp				;IRQ wieder freigeben.
			rts				;Ende.

:execRout		lda	keyRout +0,y
			ldx	keyRout +1,y
			jmp	CallRoutine

;*** Liste der Funktionstasten.
:keyTab			b 17				;Cursor down.
			b 16				;Cursor up.
			b 30				;Cursor right.
			b 8				;Cursor left.
			b 99				;"c" = TakeSource.
			b 115				;"s" = S_SetPage.
			b 120				;"x" = ResetDir.
			b 83				;"S" = Verzeichnis speichern.
			b 97				;"a" = S_SetAll.
			b 100				;"d" = S_Reset.
			b NULL

;*** Liste der Routinen zu den Funktionstasten.
:keyRout		w S_FileDown
			w S_FileUp
			w S_NextPage
			w S_LastPage
			w TakeSource
			w S_SetPage
			w ResetDir
			w EXEC_REG_ROUT
			w S_SetAll
			w S_Reset

;*** Dauerfunktion ?
;Hinweis:
;Das RegisterMenü erlaubt nicht die
;Auswertung einer Dauerfunktion über
;die Maustaste, da nach dem anklicken
;einer Option gewartet wird, bis die
;Maustaste losgelassen wird.
;Als Ersatz wird hier auf die C=-Taste
;geprüft: Ist diese aktuell gedrückt,
;dann ist Dauerfunktion aktiv.
:TestMouse		jsr	SCPU_Pause		;Wartezeit.

			jsr	testCBMkey		;CBM-Taste gedrückt?
			beq	:1			; => Ja, weiter...

			pla				;Keine Dauerfunktion:
			pla				;Rücksprungadresse vom Stack holen.
::1			rts				;Ende.

;*** Auf C= Taste prüfen.
:testCBMkey		php
			sei
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
			lda	#%01111111
			sta	CIA_PRA
			lda	CIA_PRB
			stx	CPU_DATA
			plp
			and	#%00100000
			rts

;*** SHIFT-Taste testen.
if SORTMODE64K = TRUE
:testShiftKeys		php				;Tastaturabfrage:
			sei				;Linke/Rechte SHIFT-Taste für
			ldx	CPU_DATA		;Datei-Info anzeigen bei aktivem
			lda	#$35			;AutoSelect-Modus.
			sta	CPU_DATA
			ldy	#%10111101
			sty	CIA_PRA
			ldy	CIA_PRB
			stx	CPU_DATA
			plp

;--- Hinweis:
;Nur SHIFT/Links testen, da die
;rechte SHIFT-Taste den Mauszeiger
;in der Position verändert.
			cpy	#%01111111		;SHIFT Links gedrückt?
;			beq	:exit
;			cpy	#%11101111		;SHIFT Rechts gedrückt?
;			bne	:exit			; => Nein, Abbruch...

::exit			rts
endif

;*** Anzahl Dateien ausgeben.
:PrintFiles		ClrB	currentMode

			lda	SortS_Max		;Anzahl Dateien Quelle.
			sta	r0L
if SORTMODE64K  = FALSE
			lda	#$00
			sta	r0H
endif
if SORTMODE64K  = TRUE
			lda	SortS_MaxH
			sta	r0H
endif

			lda	#< (R1SizeX0 +$08)
			ldx	#> (R1SizeX0 +$08)
			jsr	:prntCount

			lda	SortT_Max		;Anzahl Dateien Ziel.
			sta	r0L
if SORTMODE64K  = FALSE
			lda	#$00
			sta	r0H
endif
if SORTMODE64K  = TRUE
			lda	SortT_MaxH
			sta	r0H
endif

			lda	#< (R1SizeX1 -$a0 +$08 +$01)
			ldx	#> (R1SizeX1 -$a0 +$08 +$01)

;--- Anzahl Dateien Quelle/Ziel ausgeben.
::prntCount		sta	r11L			;X/Y-Position setzen.
			stx	r11H
			lda	#R1SizeY1 -$1e +$01
			sta	r1H

			lda	#<textNumFiles		;Infotext ausgeben.
			ldx	#>textNumFiles

;*** Zahl und Infotext ausgeben.
;Übergabe: r11 = X-Koordinate.
;          r1H = Y-Koordinate
;          A/X = Zeiger auf Infotext.
:prntNumText		pha
			txa
			pha

			lda	#%11000000		;Zahl linksbündig ausgeben.
			jsr	PutDecimal

			pla				;Infotext ausgeben.
			sta	r0H
			pla
			sta	r0L
			jmp	PutString

;*** Eintrag ausgeben.
;Übergabe: a7  = Zeiger auf Eintrag.
;          a2  = X-Position.
;          a3L = Y-Position.
;          a8H = Bit%7=1 = Datei ausgewählt.
:PrintEntry		ldy	#$02
			lda	(a7L),y			;Datei verfügbar ?
			beq	:end			;Nein, weiter...

			jsr	DefRectangle

			lda	#$00			;Füllmuster Standard.
			tax				;Standard-Darstellung.
			bit	a8H			;Eintrag angewählt ?
			bpl	:1			; => Nein, weiter...
			lda	#$01			;Füllmuster Revers.
			ldx	#%00100000		;Reverse Darstellung.
::1			stx	currentMode		;Textmodus setzen.
			jsr	SetPattern		;Füllmuster setzen.
			jsr	Rectangle		;Bereich löschen.

			MoveW	a2,r11			;Position für Text festlegen.
			MoveB	a3L,r1H
			ldy	#$05			;Zeiger auf erstes Zeichen.
			lda	#$05 +16 -1		;Zeiger auf letztes Zeichen.
			jmp	PrintFName

::end			rts

;*** Dateiname ausgeben.
;Übergabe: a7  = Zeiger auf 32-Byte Verzeichniseintrag.
;          r11 = X-Koordinate.
;          r1H = Y-Koordinate.
;          Y   = Zeiger auf erstes Zeichen.
;          A   = Zeiger auf letztes Zeichen.
:PrintFName		sta	:maxChars +1		;Dateiname ausgeben.
::loop			lda	(a7L),y
			cmp	#$00			;Ende Dateiname erreicht?
			beq	:end			; => Ja, Ende...
			cmp	#$a0			;SHIFT+SPACE?
			beq	:end			; => Ja, Ende...
			and	#%01111111		;Unter GEOS nur Zeichen $20 bis $7e.
			cmp	#$20			;ASCII < $20?
			bcc	:replace		; => Ja, Zeichen ersetzen.
			cmp	#$7f			;ASCII < $7f?
			bcc	:print			; => Ja, weiter...
::replace		lda	#GD_REPLACE_CHAR	;Zeichen ersetzen.

::print			sty	:next +1		;Zeiger zwischenspeichern.
			jsr	SmallPutChar		;Zeichen ausgeben.

::next			ldy	#$ff
::maxChars		cpy	#$15
			beq	:end
			iny
			bne	:loop

::end			lda	#PLAINTEXT
			jmp	PutChar

;*** Datei-Informationen anzeigen.
if SORTFINFO = TRUE

;*** Datei-Icon anzeigen.
:prntFIcon		lda	r1L			;Aufbau Registermenü?
			beq	:exit			; => Ja, Ende...
			bit	OPT_SORTFINFO		;Option "Dateiinfo" aktiv?
			bpl	:exit			; => Nein, Ende...

			lda	dirEntryBuf		;Dateityp einlesen.
			and	#FTYPE_MODES
			cmp	#FTYPE_DIR		;Typ "Verzeichnis"?
			bne	:1			; => Nein weiter...
::directory		lda	#<Icon_Map
			ldx	#>Icon_Map
			bne	:setIcon		;Icon für Verzeichnis anzeigen.

::1			lda	fileHeader +0
			ora	fileHeader +1		;Datei-Header eingelesen?
			bne	:2			; => Nein weiter...

			lda	dirEntryBuf +22		;GEOS-Datei?
			bne	:2			; => Ja, weiter...
::nonGEOS		lda	#<Icon_CBM
			ldx	#>Icon_CBM
			bne	:setIcon		;Icon für CBM-Datei anzeigen.

::2			lda	#<(fileHeader +4)	;Zeiger auf GEOS-Icon setzen.
			ldx	#>(fileHeader +4)

::setIcon		sta	:iconAdr +0		;Adresse Icon speichern.
			stx	:iconAdr +1
			jsr	i_BitmapUp		;Datei-Icon ausgeben.
::iconAdr		w	fileHeader +4
			b	(R1SizeX1 -$08 -$18 +$01)/8
			b	R1SizeY0 +$08
			b	$03
			b	$15
::exit			rts

;*** Datei-Name/-Klasse ausgeben.
:prntFInfo		lda	r1L			;Aufbau Registermenü?
			beq	:skip			; => Ja, Ende...
			bit	OPT_SORTFINFO		;Option "Dateiinfo" aktiv?
			bmi	:name			; => Ja, weiter...
::skip			jmp	:exit

;--- Textgrenzen setzen.
::name			LoadW	rightMargin,R1SizeX1 -$10 -$18 -1

;--- Dateiname ausgeben.
			LoadW	a7,dirEntryBuf -2
			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$01
			LoadB	r1H,R1SizeY0 +$08 +$06
			ldy	#$05			;Zeiger auf erstes Zeichen.
			lda	#$05 +16 -1		;Zeiger auf letztes Zeichen.
			jsr	PrintFName

			lda	fileHeader +0
			ora	fileHeader +1		;GEOS-Dateiheader vorhanden?
			beq	:size			; => Nein, weiter...

;--- GEOS-Klasse ausgeben.
			LoadW	a7,fileHeader
			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$01
			LoadB	r1H,R1SizeY0 +$08 +$08 +$06
			ldy	#77			;Zeiger auf erstes Zeichen.
			lda	#77 +18 -1		;Zeiger auf letztes Zeichen.
			jsr	PrintFName

;--- Dateigröße ausgeben.
::size			LoadB	r1H,R1SizeY0 +$08 +$08 +$08 +$06

			lda	dirEntryBuf +28		;Dateigröße einlesen und
			sta	r0L			;in KiB umwandeln.
			lda	dirEntryBuf +29
			lsr
			ror	r0L
			lsr
			ror	r0L
			sta	r0H
			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$01
			lda	#<textKByte
			ldx	#>textKByte
			jsr	prntNumText		;Dateigröße ausgeben.

			LoadW	r11,R1SizeX1 -$a0 +$08 +$01 +$30 +$01
			lda	#"/"
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar		;Trennzeichen ausgeben.

			lda	dirEntryBuf +28		;Dateigröße einlesen.
			sta	r0L
			lda	dirEntryBuf +29
			sta	r0H
			lda	#<textBlocks
			ldx	#>textBlocks
			jsr	prntNumText		;Dateigröße ausgeben.

;--- Textgrenzen löschen.
::end			LoadW	rightMargin,$013f
::exit			rts

;*** Option "Datei-Info" ändern.
:setOptFInfo		lda	r1L			;Aufbau Register-Menü?
			beq	:end			; => Ja, Ende...
			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	UpdateFInfo		; => Nein, Info löschen.
::end			rts

;*** Datei-Info aktualisieren.
:UpdateFInfo		lda	#$00			;Kennung :"Datei-Header" löschen.
			sta	fileHeader +0
			sta	fileHeader +1

			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	:1			; => Nein, weiter...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Datei-Header einlesen.
;			txa				;Nicht auf Fehler prüfen.
;			bne	:exit			;Kein Infoblock = Anzeige löschen!

::1			LoadW	r15,RTabMenu1_1a	;Datei-Info aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RTabMenu1_1b
			jsr	RegisterUpdate

::exit			rts
endif

;*** Fensterparameter setzen.
; yReg = $00, Source
; yReg = $06, Target
:SetWinData		lda	fileListData+0,y
			sta	a0L
			lda	fileListData+1,y
			sta	a0H
			lda	fileListData+2,y
			sta	a1L
			lda	fileListData+3,y
			sta	a1H
			lda	fileListData+4,y
			sta	a2L
			lda	fileListData+5,y
			sta	a2H

			ldx	#$00
			cpy	#$00
			beq	:1
			inx
::1			stx	a3H
			rts

;*** X-Koordinaten berechnen.
:DefRectangle		lda	a3L
			tax
			sec
			sbc	#6
			sta	r2L
			inx
			stx	r2H

:DefXPos		sec
			lda	a2L
			sbc	#$08
			sta	r3L
			lda	a2H
			sbc	#$00
			sta	r3H

			clc
			lda	r3L
			adc	#$87
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H
			rts

;*** Verzeichnis zurücksetzen.
:ResetDir		jsr	ImportFiles
;			jmp	DrawFileList_ST

;*** Daten neu anzeigen.
:DrawFileList_ST	jsr	PrintFiles		;Anzahl Dateien ausgeben.
			jsr	S_ResetBit		;Quell-Auswahl löschen.
			jsr	T_ResetBit		;Ziel -Auswahl löschen.
			jsr	S_Top			;Zum Anfang Quell-Tabelle.
			jmp	T_Top			;Zum Anfang Ziel -Verzeichnis.

;*** Quell-Datei wählen.
:SlctSource		lda	r1L			;Wird RegisterMenü aufgebaut?
			beq	:exit			; => Ja, Ende...
			ldy	#$00			;Quell-Bereich aktivieren.
			jsr	SetWinData
			lda	#<setMseBorderS
			ldx	#>setMseBorderS
			jsr	Slct1File
if SORTMODE64K = TRUE
			jsr	SlctSource_a		;Dateien automatisch übernehmen.
endif
if SORTFINFO = TRUE
			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	:exit			; => Nein, Ende...
			jsr	UpdateFInfo		;Datei-Info aktualisieren.
endif
::exit			rts

;*** Ziel-Datei wählen.
:SlctTarget		lda	r1L			;Wird RegisterMenü aufgebaut?
			beq	:exit			; => Ja, Ende...
			ldy	#$06			;Ziel-Bereich einlesen.
			jsr	SetWinData
			lda	#<setMseBorderT
			ldx	#>setMseBorderT
			jsr	Slct1File
if SORTMODE64K = TRUE
			jsr	SlctTarget_a		;Dateien automatisch übernehmen.
endif
if SORTFINFO = TRUE
			bit	OPT_SORTFINFO		;Datei-Info aktiv?
			bpl	:exit			; => Nein, Ende...
			jsr	UpdateFInfo		;Datei-Info aktualisieren.
endif
::exit			rts

;*** Seite im Quell-Tabelle markieren.
:S_SetPage		lda	SortS_Max		;Dateien ausgewählt?
if SORTMODE64K = TRUE
			ora	SortS_MaxH
endif
			beq	:exit			; => Nein, Ende...

			jsr	S_SetPage_a		;Dateien markieren.

if SORTMODE64K = TRUE
			jsr	SlctSource_a		;Dateien automatisch übernehmen.
endif
::exit			rts

;*** Seite im Ziel-Tabelle markieren.
:T_SetPage		lda	SortT_Max		;Dateien ausgewählt?
if SORTMODE64K = TRUE
			ora	SortT_MaxH
endif
			beq	:exit			; => Nein, Ende...

			jsr	T_SetPage_a		;Dateien markieren.

if SORTMODE64K = TRUE
			jsr	SlctTarget_a		;Dateien automatisch übernehmen.
endif
::exit			rts

;*** Dateien automatisch nach Ziel übernehmen.
if SORTMODE64K = TRUE
:SlctSource_a		bit	OPT_AUTOSLCT		;AutoSelect aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	testShiftKeys		;SHIFT gedrückt?
			beq	:1			; => Ja, weiter...
			jsr	TakeSource		;Dateien von Quelle nach Ziel.
::1			rts
endif

;*** Dateien automatisch nach Quelle übernehmen.
if SORTMODE64K = TRUE
:SlctTarget_a		bit	OPT_AUTOSLCT		;AutoSelect aktiv?
			bpl	:1			; => Nein, weiter...
			jsr	testShiftKeys		;SHIFT gedrückt?
			beq	:1			; => Ja, weiter...
			jsr	TakeTarget		;Dateien von Ziel nach Quelle.
::1			rts
endif

;*** In der Quell-Tabelle eine Datei vorwärts.
:S_FileDown		ldy	#$00
			jsr	SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	NextFile
::1			lda	#$00
			jmp	invertArrowIcon

;*** In der Quell-Tabelle eine Datei zurück.
:S_FileUp		ldy	#$00
			jsr	SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	LastFile
::1			lda	#$01
			jmp	invertArrowIcon

;*** In der Ziel-Tabelle eine Datei vorwärts.
:T_FileDown		ldy	#$06
			jsr	SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	NextFile
::1			lda	#$02
			jmp	invertArrowIcon

;*** In der Ziel-Tabelle eine Datei zurück.
:T_FileUp		ldy	#$06
			jsr	SetWinData
			jsr	InitBalkenData
			jsr	:1
			jsr	LastFile
::1			lda	#$03

;*** Scrollpfeile invertieren.
:invertArrowIcon	asl				;Bereich für angeklickten
			sta	r2L			;Pfeil einlesen und für Funktions-
			asl				;Anzeige invertieren.
			clc
			adc	r2L
			tay
			ldx	#$00
::1			lda	arrowIconData,y
			sta	r2L,x
			iny
			inx
			cpx	#$06
			bne	:1

			jmp	InvertRectangle

;*** Alle Markierungen im Quell-Tabelle löschen.
:S_Reset		jsr	S_ResetBit
			jmp	S_SetPos

;*** Alle Markierungen im Ziel -Verzeichnis löschen.
:T_Reset		jsr	T_ResetBit
			jmp	T_SetPos

;*** Variablen.
:SekInMem		b $00				;Anzahl gelesender Sektoren.

if SORTFINFO = TRUE
:OPT_SORTFINFO		b $ff				;$FF = Datei-Informationen anzeigen.
endif
if SORTMODE64K = TRUE
:OPT_AUTOSLCT		b $ff				;$FF = Dateien nach Auswahl übernehmen.
endif

:SortS_Max		b $00				;Max. Dateien im Original Verzeichnis.
:SortT_Max		b $00				;Max. Dateien im Neuen Verzeichnis.
:SortS_Top		b $00				;Erster angezeigter Eintrag in Tabelle.
:SortT_Top		b $00
:SortS_Slct		b $00				;Anzahl markierter Einträge in Tabelle.
:SortT_Slct		b $00

if SORTMODE64K  = TRUE
:SortS_MaxH		b $00				;Max. Dateien im Original Verzeichnis.
:SortT_MaxH		b $00				;Max. Dateien im Neuen Verzeichnis.
:SortS_TopH		b $00				;Erster angezeigter Eintrag in Tabelle.
:SortT_TopH		b $00
:SortS_SlctH		b $00				;Anzahl markierter Einträge in Tabelle.
:SortT_SlctH		b $00
endif

;*** Daten für Quell-/Ziel-Tabelle.
:fileListData		w FLIST_SOURCE			;Dateinummern Quelle.
if SORTMODE64K  = FALSE
			w FSLCT_SOURCE			;Tabelle mit Auswahlmodus.
endif
if SORTMODE64K  = TRUE
			w FLIST_SOURCE			;64K: Auswahl = Bit%7 von Datei-Nr.
endif
			w $0010				;X-Position.

			w FLIST_TARGET			;Dateinummern Ziel.
if SORTMODE64K  = FALSE
			w FSLCT_TARGET			;Tabelle mit Auswahlmodus.
endif
if SORTMODE64K  = TRUE
			w FLIST_TARGET			;64K: Auswahl = Bit%7 von Datei-Nr.
endif
			w $00b0				;X-Position.

;*** Texte.
if LANG = LANG_DE
:textNumFiles		b " Datei(en)     ",NULL
endif
if LANG = LANG_EN
:textNumFiles		b " File(s)     ",NULL
endif

if SORTFINFO = TRUE
:textKByte		b "Kb",NULL
:textBlocks		b "Blk",NULL
endif

;*** Daten für Anzeige-Balken.
:scrBarData		b $12                 ;SB_XPos      Cards.
			b SB_YPosMin +8       ;SB_YPos      Pixel.
			b SB_MaxFiles*8 -2*8  ;SB_MaxYlen   Pixel.
			b SB_MaxFiles         ;SB_MaxEScr   Bildschirmeinträge.
			w $ffff               ;SB_MaxEntry  Max. Einträge in Tabelle.
			w $ffff               ;SB_PosEntry  Pos. 1.Eintrag/Seite.

;*** X-Position für Anzeige-Balken.
:scrBarXPosCards	b $12,$26

;*** Maus-Fenstergrenzen zurücksetzen.
:noMseBorder		w mouseTop
			b $06
			b $00,$c7
			w $0000,$013f
			w $0000

;*** Maus-Fenstergrenzen zurücksetzen.
:setMseBorderS		w mouseTop
			b $06
			b SB_YPosMin,SB_YPosMin +SB_Height -$01
			w $0008,$008f
			w $0000

;*** Maus-Fenstergrenzen zurücksetzen.
:setMseBorderT		w mouseTop
			b $06
			b SB_YPosMin,SB_YPosMin +SB_Height -$01
			w $00a8,$012f
			w $0000

;*** Startadressen Grafikbereich für Dateiausgabe.
:GrafxDatLo		b <SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH
			b <SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH +(SCRN_WIDTH/2)
:GrafxDatHi		b >SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH
			b >SCREEN_BASE +(SB_YPosMin/8)*SCRN_WIDTH +(SCRN_WIDTH/2)

;*** Position der Scrollpfeile.
:arrowIconData		b SB_YPosMin+SB_Height-$08
			b SB_YPosMin+SB_Height-$01
			w $0090,$0097

			b SB_YPosMin
			b SB_YPosMin+$07
			w $0090,$0097

			b SB_YPosMin+SB_Height-$08
			b SB_YPosMin+SB_Height-$01
			w $0130,$0137

			b SB_YPosMin
			b SB_YPosMin+$07
			w $0130,$0137
