; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einzelnen Datei-Eintrag ausgeben.
;    Aufruf aus Fenster-Manager.
;    Übergabe: r0 = Aktueller Eintrag.
;              r1L/r1H = XPos/YPos.
;              r2L/r2H = MaxX/MaxY.
;              r3L/r3H = GridX/GridY
:GD_PRINT_ENTRY		MoveB	r0L,r15L
if MAXENTRY16BIT = TRUE
			MoveB	r0H,r15H
endif
			ldx	#r15L			;Zeiger auf Verzeichnis-Eintrag
			jsr	SET_POS_RAM		;im RAM berechnen.

			jsr	ReadFName		;Dateiname kopieren.

			ldx	WM_WCODE
			lda	WMODE_VICON,x		;Anzeige-Modus einlesen.
			bne	:20			; => Keine Icons anzeigen.

;--- Icon-Ausgabe.
			jsr	WM_TEST_ENTRY_X		;Eintrag noch innerhalb der Zeile?
			bcs	:exit			; => Nein, Ende...

			AddVBW	3,r1L			;Für Icon-Anzeige XPos +3 Cards.

;--- Icons in Farbe oder S/W?
			bit	GD_COL_MODE		;Farb-Modus aktiv?
			bmi	:10			; => Nein, weiter...

			jsr	DefGTypeID		;Zeiger auf Farb-Tabelle setzen.
			tax
			lda	GDESK_ICOLTAB,x		;Icon-Farbe aus Tabelle einlesen.
			bne	:13			;GEOS-Datei => Systemfarbe.
			beq	:12			;BASIC-Datei => Standardfarbe.

;--- Ende, kein Icon angezeigt.
::exit			ldx	#$00			;Ende.
			rts

;--- Icons in S/W, Debug aktiv?
::10			bit	GD_COL_DEBUG		;Debug-Modus aktiv?
			bpl	:12			; => Nein, weiter...

			ldy	#$01
			lda	(r15L),y		;Icon im Cache?
			cmp	#GD_MODE_ICACHE
			bne	:12			; => Nein, weiter...

::11			lda	GD_COL_CACHE		;Debug-Modus: Farbe für
			jmp	:13			;"Icon im Cache" setzen.

::12			lda	C_WinBack		;S/W-Modus: Textfarbe für Fenster
			and	#%11110000		;als Icon-Farbe verwenden.
::13			sta	r3L
			lda	C_WinBack		;Mit Hintergrundfarbe verknüpfen.
			and	#%00001111
			ora	r3L

			pha
			jsr	GetFileIcon_r0		;Datei-Icon einlesen.
			pla
			sta	r3L			;Farbwert speichern.

			LoadB	r2L,$03			;Breite Icon in Cards.
			LoadB	r2H,$15			;Höhe Icon in Pixel.
;			LoadB	r3L,$01			;Farbe für Icon (Bereits gesetzt).
			LoadB	r3H,$04			;DeltaY in Cards für Ausgabe Name.
			LoadW	r4 ,FNameBuf		;Zeiger auf Dateiname.
			jsr	GD_FICON_NAME

			lda	#$ff			;Weitere Einträge in Zeile möglich.
			jmp	:invert_entry		;Ggf. Eintrag invertieren.

;--- Text-Ausgabe.
::20			lda	r1H			;Y-Koordinate für
			clc				;Textausgabe berechnen.
			adc	#$06
			sta	r1H

			ldx	WM_WCODE
			lda	WMODE_VINFO,x		;Detail-Modus aktiv?
			bne	:30			; => Ja, weiter...
			jsr	WM_TEST_ENTRY_X		;Eintrag noch innerhalb der Zeile?
			bcc	:21			; => Ja, weiter...

			ldx	#$00			; => Kein Eintrag ausgegeben.
			rts

::21			lda	r1L			;X-Koordinate für Textausgabe
			pha				;von CARDs nach Pixel wandeln.
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r11L
			ldy	#$03
			jsr	DShiftLeft

			PushW	rightMargin		;Rechten Rand zwischenspeichern.
							;Wird für InvertEntry benötigt.

			jsr	WM_GET_GRID_X		;Breite Eintrag ermitteln.
			asl				;Von CARDs nach Pixel wandeln.
			asl
			asl
			clc				;Begrenzung rechter Rand für
			adc	r11L			;Textausgabe berechnen.
			sta	rightMargin +0
			lda	#$00
			adc	r11H
			sta	rightMargin +1

			lda	rightMargin +0		;2 Pixel Abstand zwischen Spalten.
			sec
			sbc	#$02
			sta	rightMargin +0
			bcs	:22
			dec	rightMargin +1

::22			jsr	PrintFName		;Dateiname ausgeben.

			PopW	rightMargin		;Rechten Rand zurücksetzen.

			pla				;X-Koordinate zurücksetzen.
			sta	r1L

			lda	r1H			;Y-Koordinate zurücksetzen.
			sec
			sbc	#$06
			sta	r1H

			jsr	WM_GET_GRID_X
			sta	r2L
			jsr	WM_GET_GRID_Y
			sta	r2H

			lda	#$ff			;Weitere Einträge in Zeile möglich.
			jmp	:invert_entry		;Ggf. Eintrag invertieren.

;--- Text-Ausgabe/Details.
::30			lda	r2L
			pha

			lda	r1L			;X-Koordinate für Textausgabe
			pha				;von CARDs nach Pixel wandeln.
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r11L
			ldy	#$03
			jsr	DShiftLeft

			PushW	r11			;X-Koordinate zwischenspeichern.

			jsr	PrintFName		;Dateiname ausgeben.

			PopW	r11			;X-Koordinate zurücksetzen.

			jsr	DrawDetails		;Details zu Datei-Eintrag ausgeben.

			pla				;X-Koordinate zurücksetzen.
			sta	r1L

			lda	r1H			;Y-Koordinate zurücksetzen.
			sec
			sbc	#$06
			sta	r1H

			pla
			sec
			sbc	r1L
			sta	r2L
			jsr	WM_GET_GRID_Y		;Zeiger auf nächste Zeile.
			sta	r2H

			lda	#$7f			;Zeilenende erreicht.

;--- Aktueller Eintrag ausgewählt?
;    Wenn ja, dann Eintrag invertieren.
::invert_entry		pha

			ldy	#$00
			lda	(r15L),y		;Eintrag ausgewählt?
			and	#GD_MODE_MASK
			beq	:43			; => Nein, weiter...

			jsr	WM_CONVERT_CARDS	;Koordinaten nach Pixel wandeln.

			CmpW	r4,rightMargin		;Rechter Rand überschritten?
			bcc	:41			; => Nein, Weiter...
			MoveW	rightMargin,r4		;Fensterbegrenzung setzen.

::41			CmpB	r2H,windowBottom	;Unterer Rand überschritten?
			bcc	:42			; => Nein, Weiter...
			MoveB	windowBottom,r2H	;Fensterbegrenzung setzen.

::42			jsr	InvertRectangle		;Eintrag invertieren.

::43			pla
			tax
			rts

;*** Dateiname kopieren.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
;    Rückgabe: FNameBuf = Dateiname.
:ReadFName		LoadW	r9,FNameBuf
			ldx	#r15L
			ldy	#r9L
			jmp	SysCopyFName

:PrintFName		LoadW	r0,FNameBuf		;Zeiger auf Dateiname.
			jmp	smallPutString		;Dateiname ausgeben.

;*** Zeiger auf Datei-Icon setzen.
;    Übergabe: r0  = Eintrag-Nr.
;              r15 = Zeiger auf Verzeichnis-Eintrag.
;    Rückgabe: r0  = Zeiger auf Datei-Icon.
:GetFileIcon_r0		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			beq	:1			; => Nein, weiter...

			ldy	#$02
			lda	(r15L),y		;Typ Datei-Eintrag einlesen.
			and	#%00000111		;Dateityp-Bits isolieren.
			asl
			tay
			lda	:tab +0,y		;Icon für Partitions-/DiskImage-Typ
			sta	r0L			;bzw. Verzeichnis einlesen.
			lda	:tab +1,y
			sta	r0H
			rts

::tab			w Icon_Deleted
			w Icon_41_71
			w Icon_41_71
			w Icon_81_NM
			w Icon_81_NM
			w Icon_Deleted
			w Icon_Map			;Verzeichnis bei SD2IEC.
			w Icon_Deleted

;--- Verzeichnis-Modus.
::1			PushB	r1L			;r1L/r1H enthält XPos/YPos.
			PushB	r1H			;Register r1L/r1H sichern.

			MoveB	r0L,r14L
if MAXENTRY16BIT = TRUE
			MoveB	r0H,r14H
endif
			jsr	SET_POS_CACHE		;Zeiger auf Cache setzen.

			LoadW	r0,dataBufDir
			MoveW	r14,r1
			LoadW	r2,32
			MoveB	r12H,r3L		;Speicherbank.
			jsr	FetchRAM		;Cache-Eintrag einlesen.

			;bit	GD_ICON_PRELOAD		;Alle Icons in Cache laden?
			;bmi	:2			; => Ja, weiter...
			lda	dataBufDir +1		;Icon bereits im Cache?
			bne	:3			; => Nein, Icon von Disk laden.

;--- Verzeichnis-Eintrag und Icon aus Cache.
::2			LoadW	r0,dataBufIcon
			MoveW	r13,r1
			LoadW	r2,64
			MoveB	r12L,r3L		;Speicherbank.
			jsr	FetchRAM		;Cache-Eintrag einlesen.

			lda	#<dataBufIcon		;Zeiger auf Datei-Icon in Puffer.
			ldx	#>dataBufIcon
			bne	:4

;--- Datei-Icon von Disk/Cache laden.
::3			jsr	GetVecFileIcon		;Datei-Icon von Disk laden.

;--- Zeiger auf Datei-Icon setzen, Ende.
::4			sta	r0L			;Zeiger auf Datei-Icon
			stx	r0H			;speichern.

			PopB	r1H			;Register r1L/r1H zurücksetzen.
			PopB	r1L

			rts

;*** Datei-Icon von Disk/aus Cache einlesen.
;    Übergabe: r12L = Cache/Speicherbank Icon-Eintrag.
;              r12H = Cache/Speicherbank Verzeichnis-Eintrag.
;              r13  = Zeiger auf Cache/Icon-Eintrag
;              r14  = Zeiger auf Cache/Verzeichnis-Eintrag.
;              r15  = Zeiger auf Speicher/Verzeichnis-Eintrag.
;    Rückgabe: AKKU/XReg  = Zeiger auf Datei-Icon.
:GetVecFileIcon		ldy	#$02
			lda	(r15L),y		;Dateityp = Gelöscht?
			beq	:1			; => Ja, weiter...
			cmp	#GD_MORE_FILES		;"More files..." ?
			bne	:2			; => Nein, weiter...

			lda	#<Icon_MoreFiles	;Icon "Weitere Dateien".
			ldx	#>Icon_MoreFiles
			rts

::1			lda	#<Icon_Deleted		;Icon "Gelöscht".
			ldx	#>Icon_Deleted
			rts

::2			and	#FTYPE_MODES
			cmp	#FTYPE_DIR		;Dateityp = Verzeichnis?
			bne	:4			; => Nein, weiter...
			lda	#<Icon_Map		;Icon "Verzeichnis".
			ldx	#>Icon_Map
			rts

::3			lda	#<Icon_CBM		;Icon "CBM".
			ldx	#>Icon_CBM
			rts

::4			ldy	#$15			;Spur/Sektor Infoblock einlesen.
			lda	(r15L),y		;Infoblock definiert?
			beq	:3			; => Nein, keine GEOS-Datei.
			sta	r1L
			iny
			lda	(r15L),y
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;Info-Block einlesen.
			txa				;Fehler?
			bne	:3			; => Ja, kein Infoblock => CBM.

			jsr	SaveIcon2Cache		;Icon in Cache speichern.

			lda	#<fileHeader +4		;Zeiger auf Icon in Infoblock.
			ldx	#>fileHeader +4
			rts

;*** Icon in fileHeader in Cache speichern.
;    Übergabe: r12H = Cache/Speicherbank.
;              r13  = Zeiger auf Cache/Icon-Eintrag
;              r14  = Zeiger auf Cache/Verzeichnis-Eintrag.
;              r15  = Zeiger auf Datei-Eintrag/Speicher.
:SaveIcon2Cache		bit	GD_ICON_PRELOAD		;PreLoad-Option aktiv?
			bmi	:1			; => Ja, Ende...
			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bmi	:2			; => Ja, weiter...
::1			rts				;Ende, Icon bereits im Cache.

::2			LoadW	r0,fileHeader +4
			MoveW	r13,r1
			LoadW	r2,64
			MoveB	r12L,r3L
			jsr	StashRAM		;Datei-Icon in Cache speichern.

			ldy	#$01			;Kennung "Icon im Cache" in
			lda	#GD_MODE_ICACHE		;Verzeichnis-Eintrag setzen.
			sta	(r15L),y		;(Byte#1 = $00)

			MoveW	r15,r0			;Zeiger auf Verzeichnis-Eintrag.
			MoveW	r14,r1			;Verzeichnis-Eintrag im Cache.
			LoadW	r2,2			;Nur Byte #0/1 sichern.
			MoveB	r12H,r3L		;Speicherbank.
			jmp	StashRAM		;Verzeichnis-Eintrag sichern.

;*** Textausgabe/Details ausgeben.
:DrawDetails		AddVBW	$40,r11			;X-Koordinate für Details setzen.

			ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitions-Modus aktiv?
			beq	:1			; => Nein, weiter...

;--- Partitionen/DiskImages.
			jsr	Detail_Size		;Partitionsgröße ausgeben.

			lda	#" "			;Abstandhalter ausgeben.
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen.
			and	#FTYPE_MODES		;Laufwerksmodus isolieren.
			asl				;Zeiger auf Dateityp/Text setzen.
			tay
			lda	:tab1 +0,y
			sta	r0L
			lda	:tab1 +1,y
			sta	r0H
			jsr	PutString		;Dateityp ausgeben.

			lda	#" "
			jsr	SmallPutChar
			lda	#"/"
			jsr	SmallPutChar

			ldy	#$03
			lda	(r15L),y		;Dateityp einlesen.
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jmp	PutDecimal		;Partitions-Nr. ausgeben.

::tab1			w :t0
			w :t1
			w :t2
			w :t3
			w :t4
			w :t0
			w :t6
			w :t0

if LANG = LANG_DE
::t0			b "?",NULL
::t1			b "1541",NULL
::t2			b "1571",NULL
::t3			b "1581",NULL
::t4			b "Native",NULL
::t6			b "Verzeichnis",NULL
endif
if LANG = LANG_EN
::t0			b "?",NULL
::t1			b "1541",NULL
::t2			b "1571",NULL
::t3			b "1581",NULL
::t4			b "Native",NULL
::t6			b "Directory",NULL
endif

;--- Standard-Datei-Modus.
::1			jsr	chkDateTime		;Auf gültiges Datum/Uhrzeit testen.

			ldy	#$02
			lda	(r15L),y		;Dateityp einlesen.
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien"?
			beq	:3			; => Ja, Ausgabe beenden.

			lda	#$00			;Zeiger für Spalten auf Anfang.
::2			pha
			jsr	nextColumn		;X-Position auf nächste Spalte.
			pla

			ldy	r11H			;X-Position für Textausgabe
			cpy	rightMargin +1		;noch innerhalb des Fensters?
			bne	:compare
			ldy	r11L
			cpy	rightMargin +0
::compare		bcs	:3			; => Nein, Ende...

			pha
			asl				;Zeiger auf Routine zur Detail-
			tay				;Ausgabe berechnen.
			lda	:columnData +0,y
			ldx	:columnData +1,y
			jsr	CallRoutine		;Detail-Informationen ausgeben.

			pla
			clc
			adc	#$01
			cmp	#$05			;Alle Details ausgegeben?
			bcc	:2			; => Nein, weiter...
::3			rts

;--- Hinweis:
;Wenn die Reihenfolge geändert wird ist
;ggf. für CType das setzen der nächsten
;XPos wieder zu aktivieren.
; => ":nextInfoCType" / ":Detail_CType"
::columnData		w Detail_Size			;Datei/Größe.
			w Detail_Date			;Datei/Datum.
			w Detail_Time			;Datei/Uhrzeit.
			w Detail_GType			;GEOS-Dateityp.
			w Detail_CType			;Commodore-Dateityp.

;*** X-Position auf nächste Position setzen.
;    Übergabe: AKKU = Spaltenbreite.
;              XREG/YREG = Aktuelle X-Position.
:nextColumn		lda	#6			;Spaltenabstand.
			b $2c
:skipPrntDate		lda	#3*11			;Datum überspringen.
			b $2c
:skipPrntTime		lda	#2*11			;Uhrzeit überspringen.

			ldx	r11L
			ldy	r11H
			bpl	setNewXPos

:nextNumPos		lda	#1*11			;Zeiger auf nächste Zahlenposition.
			b $2c
:nextInfoGType		lda	#$50			;GEOS-Dateityp.

;--- Hinweis:
;Nach Spalte CType erfolgt keine
;weitere Datenausgabe mehr: Am C64 ist
;hier das Fensterende bereits erreicht.
if FALSE
			b $2c
:nextInfoCType		lda	#$18			;CBM-Dateityp.
endif

:setNewXPos		sta	r11L
			txa
			clc
			adc	r11L
			sta	r11L
			tya
			adc	#$00
			sta	r11H
			rts

;*** Dateigröße ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_Size		ldy	#$1e			;Anzahl Blocks einlesen.
			lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H

			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Anzeige in KBytes?
			beq	:1			; => Nein, weiter...

			lda	r0L
			pha
			ldx	#r0L
			ldy	#$02
			jsr	DShiftRight		;Blocks in KBytes umrechnen.
			pla
			and	#%00000011		;Auf volle KByte aufrunden?
			beq	:1			; => Bereits volle KByte, weiter...

			IncW	r0			;Anzahl KBytes +1.
							;Sonst 0-2 Blocks = 0Kbyte.

::1			lda	#$20 ! SET_RIGHTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Breite für Größenausgabe.

			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Anzeige in KBytes?
			beq	:2			; => Nein, weiter...
			lda	#"K"
			jsr	SmallPutChar		;"K"byte-Suffix ausgeben.

::2			rts

;*** Dateidatum ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_Date		bit	validDate		;Datum/Uhrzeit gültig?
			bpl	:1			; => Ja, weiter...

			jmp	skipPrntDate		;Fehlerhaftes Datum überspringen.

;--- Datum OK.
::1			ldy	#$1b
			lda	(r15L),y		;Tag.
			tax
			ldy	#"."
			jsr	Detail_Num

			ldy	#$1a
			lda	(r15L),y		;Monat.
			tax
			ldy	#"."
			jsr	Detail_Num

			ldy	#$19
			lda	(r15L),y		;Jahr.
			tax
			ldy	#" "
			jmp	Detail_Num

;*** Dateizeit ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_Time		bit	validDate		;Datum/Uhrzeit gültig?
			bpl	:1			; => Ja, weiter...

			jmp	skipPrntTime		;Fehlerhafte Zeit überspringen.

;--- Uhrzeit OK.
::1			ldy	#$1c
			lda	(r15L),y		;Stunde.
			tax
			ldy	#":"
			jsr	Detail_Num

			ldy	#$1d
			lda	(r15L),y		;Minute.
			tax
			ldy	#" "
			jmp	Detail_Num

;*** Auf gültiges Datum/Uhrzeit testen.
:chkDateTime		ldx	#$ff			;Datum/Uhrzeit ungültig.

			ldy	#25
			lda	(r15L),y		;Jahr.
			beq	:exit
			cmp	#99 +1			;Jahr =< 99?
			bcs	:exit			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Monat.
			beq	:exit
			cmp	#12 +1			;Monat =< 12?
			bcs	:exit			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Tag.
			beq	:exit
			cmp	#31 +1			;Tag =< 31?
			bcs	:exit			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Stunde.
			cmp	#24			;Stunde < 24?
			bcs	:exit			; => Nein, Fehler...

			iny
			lda	(r15L),y		;Minute.
			cmp	#60			;Minute < 60?
			bcs	:exit			; => Nein, Fehler...

			inx				;Datum/Uhrzeit gültig.
::exit			stx	validDate
			rts

;*** Zweistellige Zahl ausgeben.
;    Für Datum/Uhrzeit.
;    Übergabe: XReg = Zahl.
;              YReg = Zahlentrenner, z.B. "."(Datum) oder ":"(Zeit).
:Detail_Num		lda	r11H			;X-Koordinate sichern.
			pha
			lda	r11L
			pha

			tya				;Zahlentrenner sichern.
			pha

			txa
			jsr	DEZ2ASCII		;Zahl nach ASCII wandeln.
			pha				;LOW-Nibble sichern.
			txa
			jsr	SmallPutChar		;10er ausgeben.
			pla
			jsr	SmallPutChar		;1er ausgeben.

			pla
			jsr	SmallPutChar		;Zahlentrenner ausgeben.

			pla				;X-Koordinate auf nächste
			tax				;Position setzen.
			pla
			tay
			jmp	nextNumPos

;*** GEOS-Dateityp ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_GType		lda	r11H			;X-Koordinate sichern.
			pha
			lda	r11L
			pha

			jsr	GetGeosType		;Zeiger auf Text für
			sta	r0L			;GEOS-Dateityp einlesen.
			sty	r0H
			jsr	PutString		;GEOS-Dateityp ausgeben.

			pla				;X-Koordinate auf nächste
			tax				;Position setzen.
			pla
			tay
			jmp	nextInfoGType

;*** CBM-Dateityp ausgeben.
;    Übergabe: r15 = Zeiger auf Verzeichnis-Eintrag.
:Detail_CType

;--- Hinweis:
;Nach Spalte CType erfolgt keine
;weitere Datenausgabe mehr: Am C64 ist
;hier das Fensterende bereits erreicht.
if FALSE
			lda	r11H			;X-Koordinate sichern.
			pha
			lda	r11L
			pha
endif

			ldy	#$02
			lda	(r15L),y		;CBM-Dateityp einlesen.
			pha
			and	#FTYPE_MODES		;Datei-Typ isolieren.
			asl
			asl

			clc				;Zeiger auf CBM-Dateityp
			adc	#<cbmFType		;berechnen und Dateityp ausgeben.
			sta	r0L
			lda	#$00
			adc	#>cbmFType
			sta	r0H
			jsr	PutString

			pla
			pha				;Datei "geöffnet" ?
			bmi	:3			; => Nein, weiter...
			lda	#"*"
			jsr	SmallPutChar		;"Datei geöffnet"-Kennung.

::3			pla
			and	#%01000000		;Datei schreibgeschützt?
			beq	:4			; => Nein, weiter...
			lda	#"<"
			jsr	SmallPutChar		;"Datei schreibgeschützt"-Kennung.

::4			rts

;--- Hinweis:
;Nach Spalte CType erfolgt keine
;weitere Datenausgabe mehr: Am C64 ist
;hier das Fensterende bereits erreicht.
if FALSE
::4			pla				;X-Koordinate auf nächste
			tax				;Position setzen.
			pla
			tay
			jmp	nextInfoCType
endif

;*** Variablen.
:FNameBuf		s 17				;Puffer für Dateiname.
:validDate		b $00				;$00 = Datum/Zeit OK.
