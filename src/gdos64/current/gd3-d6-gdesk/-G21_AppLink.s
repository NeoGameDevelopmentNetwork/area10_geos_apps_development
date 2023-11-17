; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** AppLink-Icon unter Mauszeiger suchen.
;    Rückgabe: XREG = $00, Icon unter Mauszeiger.
;              r14  = Zeiger auf AppLink-Daten.
;              r15  = Zeiger auf AppLink-Icon.
:AL_FIND_ICON		php				;IRQ-Status speichern und
			sei				;Interrupt sperren.

			jsr	initALDataVec		;AppLink-Register initialisieren.
::1			jsr	getALIconSize		;Position/Größe für Icon.

			jsr	IsMseInRegion		;Mauszeiger auf Icon?
			tax
			bne	:2			; => Ja, gefunden. Ende.

			jsr	setVecNxALEntry		;Zeiger auf nächste AppLink-Daten.

			lda	r13H
			cmp	LinkData		;Alle AppLink-Icons geprüft?
			bne	:1			; => Nein, weiter...

			plp				;IRQ-Status zurücksetzen.
			ldx	#FILE_NOT_FOUND		;Kein AppLink unter Mauszeiger.
			rts

::2			plp				;IRQ-Status zurücksetzen.
			ldx	#NO_ERROR		;AppLink unter Mauszeiger gefunden.
			rts

;*** Zeiger auf AppLink-Daten initialisieren.
;    Rückgabe: r13H = Aktueller AppLink.
;              r14  = Zeiger auf AppLink-Daten.
;              r15  = Zeiger auf AppLink-Icon.
;              AL_CNT_ENTRY = Anzahl AppLinks.
.initALDataVec		ldy	#$00			;Aktuelle AppLink-Nr.
			sty	r13H

			LoadW	r14,LinkData		;Zeiger auf AppLink-Daten.
			LoadW	r15,appLinkIBufA	;Zeiger auf AppLink-Icon.

;			ldy	#$00
			lda	(r14L),y		;Anzahl AppLinks einlesen.
			sta	AL_CNT_ENTRY

			IncW	r14			;AppLink-Zähler überspringen.
			rts

;*** Zeiger auf nächste AppLink-Daten.
.setVecNxALEntry	AddVBW	LINK_DATA_BUFSIZE,r14
			AddVBW	64,r15
			inc	r13H
			rts

;*** AppLink für MyComputer/Laufwerk.
:AL_DnD_Drive		lda	#AL_ID_DRIVE

;*** AppLink für Laufwerksfenster als Laufwerk/Verzeichnis.
:AL_DnD_DrvSubD		pha

			jsr	setVecNmDirData		;Zeiger auf Verzeichnisdaten.

			ldx	#r12L			;Zeiger auf Disknamen setzen.
			jsr	GetPtrCurDkNm

			pla				;AppLink-ID für AppLink-Tabelle.
			ldx	r12L			;Zeiger auf Diskname.
			ldy	r12H
			jmp	setALDatDrvSDir		;AppLink für Verzeichnis erstellen.

;*** AppLink für MyComputer/Drucker.
:AL_DnD_Printer		lda	#AL_ID_PRNT		;AppLink-ID für AppLink-Tabelle.
			ldx	#< dataFileName		;Zeiger auf Druckername.
			ldy	#> dataFileName
			jmp	setALDatFilePrnt	;AppLink für Drucker erstellen.

;*** AppLink für Laufwerksfenster/Verzeichnis.
;    Übergabe: r0 = Zeiger auf 32Byte Verzeichnis-Eintrag.
:AL_DnD_SubDir		lda	r1L			;Track/Sektor für Verzeichnis-
			sta	r10L			;Header.
			lda	r1H
			sta	r10H

			lda	#< diskBlkBuf		;Zeiger auf BAM im Speicher.
			sta	r11L
			lda	#> diskBlkBuf
			sta	r11H

			jsr	setVecNmDirEntry	;Zeiger auf Dateiname.

			lda	#AL_ID_SUBDIR		;AppLink-ID für AppLink-Tabelle.
			jmp	setALDatDrvSDir		;AppLink für Verzeichnis erstellen.

;*** AppLink für Laufwerksfenster/Dateien.
;    Übergabe: r0 = Zeiger auf 32Byte Verzeichnis-Eintrag.
:AL_DnD_Files		jsr	setVecNmDirEntry	;Zeiger auf Dateiname.

			lda	#AL_ID_FILE		;AppLink-ID für AppLink-Tabelle.
			jmp	setALDatFilePrnt	;AppLink für Datei erstellen.

;*** AppLink für Laufwerksfenster/Drucker.
;Übergabe  : r0 = Zeiger auf Dateiname.
:AL_DnD_FilePrnt	lda	#< dataFileName		;Zeiger auf Zwischenspeicher für
			sta	r12L			;Druckername.
			lda	#> dataFileName
			sta	r12H

			ldx	#r0L
			ldy	#r12L
			jsr	SysCopyFName

			lda	#AL_ID_PRNT
			ldx	r12L			;Zeiger auf Druckername.
			ldy	r12H
			jmp	setALDatFilePrnt	;AppLink für Drucker erstellen.

;*** Zeiger auf Dateiname setzen.
;    Übergabe: r0 = Zeiger auf 32Byte Verzeichnis-Eintrag.
;    Rückgabe: XREG/YREG = Zeiger auf 16Byte Dateiname.
:setVecNmDirEntry	lda	r0L
			clc
			adc	#$05
			tax
			lda	r0H
			adc	#$00
			tay
			rts

;*** Verzeichnisdaten initialisieren.
;Bei NativeMode Zeiger auf Verzeichnis
;setzen, sonst die Zeiger löschen.
:initVecNmDirData	txa				;XReg zwischenspeichern.
			pha

;--- Hinweis:
;X-/Y-Reg darf nicht geändert werden!!!
			ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;SUBDIR-Bit isolieren.
			bne	:1			; => NativeMode-Laufwerk.

;			lda	#$00			; => Kein NativeMode-Laufwerk.
			sta	r10L			;Kein Track/Sektor für
			sta	r10H			;Verzeichnis-Header.
			sta	r11L			;Kein Zeiger auf BAM erforderlich.
			sta	r11H
			beq	:2

::1			jsr	setVecNmDirData		;Zeiger auf Verzeichnis erzeugen.

::2			pla
			tax				;XReg zurücksetzen.
			rts

;*** Zeiger auf Verzeichnisdaten setzen.
:setVecNmDirData	lda	curDirHead +32		;Track/Sektor für Verzeichnis-
			sta	r10L			;Header.
			lda	curDirHead +33
			sta	r10H

			lda	#< curDirHead		;Zeiger auf BAM im Speicher.
			sta	r11L
			lda	#> curDirHead
			sta	r11H

			rts

;*** AppLink-Daten schreiben:
;    Drucker oder Dateien.
;    Übergabe: AKKU = AppLink-ID ":AL_ID_..."
;              X/Y  = Low/High-Zeiger auf Name.
:setALDatFilePrnt	pha				;AppLink-ID retten.

;--- Hinweis:
;Hier muss geprüft werden, ob das
;aktuelle Laufwerk NativeMode ist.
;In diesem Fall muss auch das aktuelle
;Verzeichnis im AppLink gespeichert
;werden, da sonst der AppLink nur
;geöffnet werden kann wenn auch das
;Verzeichnis bereits aktiv ist.
			jsr	initVecNmDirData	;Zeiger auf NativeMode-SubDir.

			pla				;AppLink-ID zurücksetzen.

;*** AppLink-Daten schreiben:
;    Laufwerk oder Verzeichnis.
;    Übergabe: AKKU = AKKU = AppLink-ID ":AL_ID_..."
;              X/Y  = Low/High-Zeiger auf Name.
;              r10 = Track/Sektor Verzeichnis-Header.
;              r11 = Zeiger auf Puffer mit dirHead/BAM.
:setALDatDrvSDir	sta	:id			;AppLink-ID speichern.

			tya				;Zeiger auf Dateiname speichern.
			pha
			txa
			pha

			jsr	setVecALEntry		;Zeiger auf Speicher für Link/Icon.

			pla
			sta	r3L
			pla
			sta	r3H

			jsr	setALDat_FName		;Dateiname kopieren.
			jsr	setALDat_Title		;Dateiname als Titel setzen.

			lda	:id
			jsr	setALDat_Icon		;Icon für AppLink speichern.

			lda	:id
			asl
			tay
			lda	:colors +0,y
			ldx	:colors +1,y
			jsr	setALDat_Color		;Farbe für AppLink-Icon.

			jsr	setALDat_XYpos		;Position für AppLink auf DeskTop.

			ldy	:id
			lda	:types,y
			jsr	setALDat_Type		;AppLink-Typ speichern.

			jsr	setALDat_DvAdr		;Laufwerks-Adresse speichern.
			jsr	setALDat_DvType		;RealDrvType speichern.

			ldx	curDrive		;CMD-Partition und NativeMode.
			lda	RealDrvMode -8,x
			pha
			and	#SET_MODE_PARTITION
			beq	:1			; => Kein CMD-Laufwerk.
			jsr	setALDat_DvPart
::1			pla
			and	#SET_MODE_SUBDIR
			beq	:2			; => Kein NativeMode-Laufwerk.

			lda	r10L			;Track/Sektor für
			ldx	r10H			;Verzeichnis-Header speichern.
			jsr	setALDat_DvSDir

			ldy	#36			;Zeiger auf Verzeichnis-Eintrag
			lda	(r11L),y		;für aktuelles Verzeichnis.
			pha				;Die Angaben werden später dazu
			iny				;Verwendet um zu prüfen ob das
			lda	(r11L),y		;Verzeichnis noch existiert.
			tax
			iny
			lda	(r11L),y
			tay
			pla
			jsr	setALDat_DvSDirE	;AppLink-Verzeichnis-Eintrag.

::2			ldy	:id			;AppLink-ID einlesen.
			lda	:wmodes,y		;Fensteroptionen speichern?
			beq	:3			; => Nein, weiter...
			jsr	setALDat_WMode		;AppLink/Fensteroptionen speichern.

			jsr	setALDat_Filter		;Dateifilter speichern.
			jsr	setALDat_Sort		;Sortiermodus speichern.

::3			inc	LinkData		;Anzahl AppLinks +1.

			jsr	MainDTopUpdate		;DeskTop+AppLinks neu zeichen.
			jmp	WM_DRAW_ALL_WIN		;Fenster neu zeichnen.

;*** Variablen.
::id			b $00

;*** AppLink-Typen.
::types			b AL_TYPE_FILE
			b AL_TYPE_DRIVE
			b AL_TYPE_PRNT
			b AL_TYPE_SUBDIR

;*** Fenster-Optionen speichern.
::wmodes		b AL_WMODE_FILE
			b AL_WMODE_DRIVE
			b AL_WMODE_PRNT
			b AL_WMODE_SUBDIR

;*** Farben für AppLink-Icons.
::colors		w $0000				;Std.-Farbe durch C_GDesk_ALIcon.
			w Color_Drive
			w Color_Prnt
			w Color_SDir

;*** Position/Größe für AppLink-Icon.
;    Rückgabe: r2L/r2H = Y oben/unten.
;              r3/r4   = X links/rechts.
.getALIconSize		ldy	#LINK_DATA_YPOS
			lda	(r14L),y		;Y-Position in CARDs einlesen.
			asl				;Nach Pixel wandeln.
			asl
			asl
			sta	r2L
			clc
			adc	#$17			;Untere Grenze für Icon
			sta	r2H			;berechnen.

			ldy	#LINK_DATA_XPOS
			lda	(r14L),y		;X-Position in CARDs einlesen.
			asl				;Nach Pixel wandeln.
			asl
			asl
			sta	r3L
			lda	#$00
			rol
			sta	r3H

			lda	r3L			;Rechte Grenze für Icon
			clc				;berechnen.
			adc	#$17
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H
			rts

;*** Zeiger auf AppLink-Daten berechnen.
;    Übergabe: LinkData = AppLink-Nr. 0-23.
;    Rückgabe: r0 = Zeiger auf AppLink-Daten.
;              r1 = Zeiger auf AppLink-Icon.
:setVecALEntry		lda	LinkData		;AppLink-Nr. einlesen.
			sta	r0L
			lda	#$00
			sta	r0H

			lda	#< LINK_DATA_BUFSIZE
			sta	r1L
			lda	#> LINK_DATA_BUFSIZE
			sta	r1H			;Größe AppLink-Eintrag.

			ldx	#r0L
			ldy	#r1L
			jsr	DMult			;Zeiger innerhalb AppLink-Tabelle.

			AddVW	LinkData+1,r0		;Zeiger auf AppLink-Daten. Erstes
							;Byte übrspringen = AppLink-Zähler.

			lda	LinkData		;AppLink-Nr. einlesen.
			sta	r1L
			lda	#$00
			sta	r1H

			ldx	#r1L
			ldy	#$06
			jsr	DShiftLeft		;Zeiger innerhalb AppLink-Icons.

			AddVW	appLinkIBufA,r1		;Zeiger auf AppLink-Icons.
			rts

;*** AppLink-Dateiname/Titel speichern.
:setALDat_FName		ldy	#LINK_DATA_FILE
			b $2c
:setALDat_Title		ldy	#LINK_DATA_NAME
			sty	r4L			;Position in AppLink-Daten.

			ldy	#$00
			sty	r4H			;Zeichenzähler löschen.

::1			ldy	r4H			;Zeichen aus Name einlesen.
			lda	(r3L),y			;Ende erreicht?
			beq	:2			; => Ja, weiter...
			cmp	#$a0			;$A0 = Füllbyte erreicht?
			beq	:2			; => Ja, weiter...
			ldy	r4L
			sta	(r0L),y			;Zeichen in AppLink-Daten schreiben.

			inc	r4L			;Zeiger auf nächstes Zeichen.
			inc	r4H

			lda	r4H
			cmp	#16			;Max. 16 Zeichen eingelesen?
			bcc	:1			; => Nein, weiter...

::2			ldy	r4L			;Dateiname oder Titel mit
			ldx	r4H			;$00-Bytes auffüllen und mit
			lda	#$00			;einem $00-Byte beenden.
::3			sta	(r0L),y
			iny
			inx
			cpx	#16 +1
			bcc	:3
			rts

;*** Icon in AppLink-Daten kopieren.
;Übergabe  : A  = AppLink-ID.
;            r1 = Zeiger auf Icon-Speicher.
:setALDat_Icon		ldx	#< spr1pic -1		;Zeiger auf DnD-Sprite.
			ldy	#> spr1pic -1		;1Byte Kopfbyte überspringen.

			cmp	#AL_ID_PRNT		;AppLink für Drucker?
			bne	:set_icon		; => Nein, weiter...

			ldx	#< Icon_Printer		;Zeiger auf Drucker-Icon.
			ldy	#> Icon_Printer
;			bne	:set_icon

::set_icon		stx	:2 +1			;Zeiger auf AppLink-Icon-Daten.
			sty	:2 +2

			ldy	#$3f			;63 Bytes an Icon-Daten in
::2			lda	$ffff,y			;AppLink-Daten kopieren.
			sta	(r1),y
			dey
			bne	:2

			lda	#$bf			;Kennung für GEOS-Icon-Bitmap.
			sta	(r1),y
			rts

;*** Farbe für Icon in AppLink-Daten schreiben.
;Übergabe  : A/X = Zeiger auf Farbtabelle.
;                  Wenn Zeiger = $0000: Standardfarbe setzen.
;            r1  = Zeiger auf Farbspeicher.
:setALDat_Color		sta	:1 +1			;Zeiger auf Farb-Tabelle speichern.
			stx	:1 +2
			ora	:1 +2			;Standard-Farben setzen?
			beq	:setStdColor		; => Ja, weiter...

			ldx	#$00
			ldy	#LINK_DATA_COLOR
::1			lda	$ffff,x			;Farbangaben in AppLink-Daten
			sta	(r0),y			;kopieren: 3x3 Bytes.
			inx
			iny
			cpx	#$09
			bcc	:1
			rts

::setStdColor		ldx	#$00
			ldy	#LINK_DATA_COLOR
			lda	C_GDesk_ALIcon		;Farbangaben in AppLink-Daten
::2			sta	(r0),y			;kopieren: 3x3 Bytes.
			inx
			iny
			cpx	#$09
			bcc	:2
			rts

;*** AppLink-Typ festlegen.
;    Übergabe: AKKU =  AppLink-Typ:
;              AL_TYPE_FILE   : Datei.
;              AL_TYPE_SUBDIR : Verzeichnis.
;              AL_TYPE_PRNT   : Druckertreiber.
;              AL_TYPE_DRIVE  : Laufwerkstreiber.
:setALDat_Type		ldy	#LINK_DATA_TYPE
			sta	(r0),y
			rts

;*** AppLink-Position auf DeskTop speichern.
;Dabei wird auch die X-/Y-Position
;geprüft, da AppLinks nur innerhalb
;eines kleineren Bildschirm-Bereichs
;abgelegt werden können, da noch Platz
;für den Titel links/rechts/unterhalb
;des Icons erforderlich ist.
:setALDat_XYpos		CmpBI	mouseYPos,MIN_AREA_BAR_Y -$08 -$18
			bcc	:1
			LoadB	mouseYPos,MIN_AREA_BAR_Y -$08 -$18

::1			CmpWI	mouseXPos,$0010
			bcs	:2
			LoadW	mouseXPos,$0010

::2			CmpWI	mouseXPos,SCRN_WIDTH   -$10 -$18
			bcc	:3
			LoadW	mouseXPos,SCRN_WIDTH   -$10 -$18

::3			lda	mouseXPos +1
			lsr
			lda	mouseXPos +0
			ror
			lsr
			lsr
			ldy	#LINK_DATA_XPOS
			sta	(r0L),y

			lda	mouseYPos
			lsr
			lsr
			lsr
			ldy	#LINK_DATA_YPOS
			sta	(r0L),y
			rts

;*** Laufwerksdaten in AppLink-Daten speichern.
:setALDat_DvAdr		lda	curDrive		;Laufwerksadresse speichern.
			ldy	#LINK_DATA_DRIVE
			sta	(r0L),y
			rts

:setALDat_DvType	ldx	curDrive		;RealDrvType speichern.
			lda	RealDrvType   -8,x
			ldy	#LINK_DATA_DVTYP
			sta	(r0L),y
			rts

:setALDat_DvPart	ldx	curDrive		;CMD-Partition speichern.
			lda	drivePartData -8,x
			ldy	#LINK_DATA_DPART
			sta	(r0L),y
			rts

:setALDat_DvSDir	ldy	#LINK_DATA_DSDIR	;Native-Verzeichnis speichern.
			sta	(r0L),y
			iny
			txa
			sta	(r0L),y
			rts

:setALDat_DvSDirE	pha				;Verzeichniseintrag speichern.
			tya
			ldy	#LINK_DATA_ENTRY +2
			sta	(r0L),y			;Zeiger auf Eintrag in Sektor.
			dey
			txa
			sta	(r0L),y			;Verzeichnis-Eintrag/Sektor.
			dey
			pla
			sta	(r0L),y			;Verzeichnis-Eintrag/Spur.
			rts

;*** Dateifilter in AppLink-Daten speichern.
:setALDat_Filter	ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	WMODE_FILTER,x		;Dateifilter.
			ldy	#LINK_DATA_FILTER
			sta	(r0L),y
			rts

;*** Sortiermodus in AppLink-Daten speichern.
:setALDat_Sort		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	WMODE_SORT,x		;Sortiermodus.
			ldy	#LINK_DATA_SORT
			sta	(r0L),y
			rts

;*** Fensteroptionen in AppLink-Daten speichern.
;    Übergabe: r0 = Zeiger auf AppLink-Daten.
;
;HINWEIS:
;Belegung der Bits in "e.GD.10.AppLink"
;
:setALDat_WMode		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			cpx	WM_MYCOMP		;Fenster=Arbeitsplatz?
			bne	:1

			lda	GD_STD_TEXTMODE		;Icon- oder Text-Modus.
			and	#%10000000
			sta	r1L

			lda	GD_STD_SIZEMODE		;Blocks oder KBytes.
			and	#%10000000
			lsr
			ora	r1L
			sta	r1L

			lda	GD_STD_TEXTMODE		;Text- oder Detail-Modus.
			and	#%10000000
			lsr
			lsr
			ora	r1L
;			sta	r1L

			ldy	#LINK_DATA_WMODE	;Fenster-Optionen speichern.
;			lda	r1L
			sta	(r0L),y
			rts

::1			ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	WMODE_VICON,x		;Icon- oder Text-Modus.
			and	#%10000000
			sta	r1L

			lda	WMODE_VSIZE,x		;Blocks oder KBytes.
			and	#%01000000
			ora	r1L
			sta	r1L

			lda	WMODE_VINFO,x		;Text- oder Detail-Modus.
			and	#%00100000
			ora	r1L
;			sta	r1L

			ldy	#LINK_DATA_WMODE
;			lda	r1L
			sta	(r0L),y			;Fenster-Optionen speichern.
			rts

;*** Fensteroptionen aus AppLink-Daten einlesen.
;    Übergabe: XREG = Fenster-Nr.
;              r14  = Zeiger auf AppLink-Daten.
:getALDat_WMode		ldy	#LINK_DATA_WMODE	;Fensteroptionen einlesen.
			lda	(r14L),y

			asl
			pha
			ldy	#$00
			bcc	:1
			dey
::1			tya
			sta	WMODE_VICON,x		;Icon- oder Text-Modus.
			pla

			asl
			pha
			ldy	#$00
			bcc	:2
			dey
::2			tya
			sta	WMODE_VSIZE,x		;Blocks oder KBytes.
			pla

			asl
			ldy	#$00
			bcc	:3
			dey
::3			tya
			sta	WMODE_VINFO,x		;Text- oder Detail-Modus.

			ldy	#LINK_DATA_FILTER	;Dateifilter einlesen.
			lda	(r14L),y
			sta	WMODE_FILTER,x

			ldy	#LINK_DATA_SORT		;Sortiermodus einlesen.
			lda	(r14L),y
			sta	WMODE_SORT,x

			rts

;*** AppLink auf DeskTop verschieben.
;    Übergabe: r14 = Zeiger auf AppLink-Daten.
;              r15 = Zeiger auf AppLink-Icon.
:AL_MOVE_ICON		MoveW	r14,AL_VEC_FILE		;Zeiger auf AppLink-Daten.

			lda	r15L			;GEOS-Icon-Bitmap-Kennung $BF
			clc				;übergehen und Zeiger auf Icon-
			adc	#$01			;Daten korrigieren.
			sta	r4L
			lda	r15H
			adc	#$00
			sta	r4H

			jsr	DRAG_N_DROP_ICON	;Drag`n`Drop-Routine aufrufen.
			cpx	#NO_ERROR		;Icon abgelegt?
			bne	:1			; => Nein, Abbruch...
			tay				;AppLink für "MyComputer"?
			bne	:1			; => Ja, Ende...

			MoveW	AL_VEC_FILE,r0		;Zeiger auf neue Icon-Position in
			jsr	setALDat_XYpos		;AppLink-Daten speichern.

			jsr	MainDTopUpdAppl		;DeskTop+AppLinks neu zeichnen.

			bit	GD_HIDEWIN_MODE		;Fenster ausgeblendet?
			bmi	:1			; => Ja, Ende...

			jsr	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

::1			rts

;*** AppLink öffnen.
.AL_OPEN_ENTRY		MoveW	r14,AL_VEC_FILE

			ldy	#LINK_DATA_TYPE
			lda	(r14L),y
;			cmp	#AL_TYPE_FILE		;":AL_TYPE_FILE" = $00.
			beq	:openALFile		;AppLink/Datei öffnen.

			cmp	#AL_TYPE_PRNT
			beq	AL_OPEN_PRNT		;AppLink/Drucker installieren.

			pha				;Modus "Fenster ausblenden"
			jsr	WM_HIDEWIN_OFF		;beenden.
			pla

			cmp	#AL_TYPE_SUBDIR
			beq	:1			;AppLink/Verzeichnis öffnen.

			cmp	#AL_TYPE_DRIVE
			beq	:2			;AppLink/Laufwerk öffnen.

			cmp	#AL_TYPE_MYCOMP
			beq	:3			;AppLink/MyComputer öffnen.

			rts				;AppLink-Typ unbekannt, Ende.

::1			jmp	AL_OPEN_SDIR		;NativeMode-Verzeichnis öffnen.
::2			jmp	AL_OPEN_DRIVE		;Laufwerk/Partition öffnen.
::3			jmp	OpenMyComputer		;"MyComputer" öffnen.

;*** AppLink öffnen: Datei.
::openALFile		jsr	AL_SET_DEVICE		;AppLink-Laufwerk aktivieren.
			txa				;Fehler?
			bne	:findALFile		; => Ja, Fehler ausgeben, Abbruch.

			MoveW	r14,r6
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:findALFile		; => Ja, Fehler ausgeben, Abbruch.

			LoadW	r0,dirEntryBuf -2	;Zeiger auf Verzeichnis-Eintrag.
			jmp	StartFile_r0		;Datei öffnen.

;--- Ergänzung: 06.04.21/M.Kanet
;Wird die AppLink-Datei nicht mehr
;gefunden, dann wird die Suche auf
;allen Laufwerken fortgesetzt.
;Wie bei ":StartFile_r0" müssen aber
;auch hier die GeoDesk-Daten in der
;REU gesichert werden, da sonst nach
;der Rückkehr aus der Anwendung evtl.
;geöffnete Fenster nicht angezeigt
;werden.
::findALFile		jsr	UPDATE_GD_CORE		;Fensterdaten/Variablen speichern.

			MoveW	r14,a0			;AppLink-Datei auf allen
			jmp	MOD_FIND_ALFILE		;Laufwerken suchen.

;*** AppLink öffnen: Drucker.
.AL_OPEN_PRNT		MoveW	AL_VEC_FILE,r14		;Zeiger auf AppLink-Eintrag.

			ldy	#LINK_DATA_DRIVE	;Laufwerk für AppLink/Drucker
			lda	(r14L),y		;einlesen.

			jsr	Sys_SvTempDrive		;Laufwerk temporär speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Fehler ausgeben, Abbruch.

			jsr	AL_SET_DEVICE		;AppLink-Laufwerk aktivieren.
			txa				;Fehler?
			bne	:err			; => Ja, Fehler ausgeben, Abbruch.

			MoveW	AL_VEC_FILE,r0		;Druckername in Zwischenspeicher
			LoadW	r6,dataFileName		;übernehmen.
			ldx	#r0L
			ldy	#r6L
			jsr	CopyString

			jsr	EXT_PRINTLOAD		;Druckertreiber wechseln.

			jmp	BackTempDrive		;Original-Laufwerk zurücksetzen.

;--- Hinweis:
;Die ":err"-Routine wird nur verwendet
;wenn das Laufwerk mit dem Treiber
;nicht geöffnet werden konnte. Hier ist
;noch kein Treiber geladen und damit
;kein Speicher überschrieben worden.
::err			jmp	EXT_PRINTLDERR		;Druckertreiber-Fehler ausgeben.

;*** AppLink öffnen: Verzeichnis.
.AL_OPEN_SDIR		jsr	AL_SET_DEVICE		;AppLink-Laufwerk aktivieren.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
::1			jmp	AL_ERRTEST_DRV		; => Ja, Laufwerk testen...

::2			ldx	curDrive
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	:3			; =>  Nein, weiter...

			ldy	#LINK_DATA_DPART	;CMD-Partition einlesen.
			lda	(r14L),y
			beq	:3
			sta	r3H
			jsr	OpenPartition		;Partition aktivieren.
			txa				;Fehler?
			bne	:1			; => Ja, Laufwerk testen.

::3			ldx	curDrive
			lda	RealDrvMode -8,x	;NativeMode-Laufwerk?
			and	#SET_MODE_SUBDIR
			beq	:3			; =>  Nein, weiter...

			ldy	#LINK_DATA_ENTRY
			lda	(r14L),y		;Verzeichnis-Eintrag gesetzt?
			beq	:4			; => Nein, Fehler ausgeben.

			sta	r1L			;Track/Sektor für Verzeichnis-
			iny				;Eintrag setzen und Sektor
			lda	(r14L),y		;einlesen.
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Fehler?
			bne	:4			; => Ja, Fehler ausgeben.

			ldy	#LINK_DATA_ENTRY +2
			lda	(r14L),y
			tax
			lda	diskBlkBuf,x
			and	#ST_FMODES
			cmp	#DIR			;Ist Eintrag noch ein Verzeichnis?
			bne	:4			; => Nein, Fehler ausgeben.

			ldy	#LINK_DATA_DSDIR
			lda	(r14L),y		;Ist Track/Sektor noch Zeiger auf
			cmp	diskBlkBuf+1,x		;gespeicherten Verzeichnis-Header?
			bne	:4			; => Nein, Fehler ausgeben.
			sta	r1L
			iny
			lda	(r14L),y
			cmp	diskBlkBuf+2,x
			bne	:4
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa
			bne	:4

			jmp	AL_OPEN_NEW_DSK		;Neues Fenster für AppLink öffnen.
::4			rts

;*** AppLink öffnen: Partition.
.AL_OPEN_DSKIMG		jsr	AL_SET_DEVICE		;AppLink-Laufwerk aktivieren.
			txa				;Fehler?
			bne	AL_ERRTEST_DRV		; => Ja, Laufwerk testen...
			beq	AL_OPEN_NEW_PART	;Partition wechseln.

;*** AppLink öffnen: Laufwerk.
:AL_OPEN_DRIVE		jsr	AL_SET_DEVICE		;AppLink-Laufwerk aktivieren.
			txa				;Fehler?
			bne	AL_ERRTEST_DRV		; => Ja, Laufwerk testen...

			ldx	curDrive
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	AL_OPEN_NEW_DSK		; => Nein, weiter...

			ldy	#LINK_DATA_DPART	;CMD-Partition einlesen.
			lda	(r14L),y		;Partitition gesetzt?
			beq	AL_OPEN_NEW_DSK		; => Nein, weiter...
			sta	r3H
			jsr	OpenPartition		;Partition aktivieren.
			txa				;Fehler?
			beq	AL_OPEN_NEW_DSK		; => Nein, weiter...

;*** Laufwerksfehler.
;Bei CMD-/SD2IEC-Laufwerken den
;Partitions-/DiskImage-Modus öffnen.
;Sonst Abbruch mit XReg=Fehler.
:AL_ERRTEST_DRV		ldy	curDrive
			lda	RealDrvMode -8,y	;CMD/SD2IEC-Laufwerk?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			bne	AL_OPEN_NEW_PART	; => Nein, weiter...
			rts				;Abbruch, XReg=Fehler.

:AL_OPEN_NEW_DSK	lda	#%00000000		;Partition-/DiskImage-Modus löschen.
			b $2c
:AL_OPEN_NEW_PART	lda	#%11000000		;Partition-/DiskImage-Modus setzen.

			sta	:set_win_mode +1	;Modus speichern.

			jsr	WM_IS_WIN_FREE		;Freies Fenster suchen.
			cpx	#NO_ERROR		;Freies Fenster gefunden?
			bne	:exit			; => Nein, Ende...

			tax				;Fenster-Nr. als Zeiger setzen.
::set_win_mode		lda	#$ff
			sta	WIN_DATAMODE,x		;Partitionsmodus für Fenster.

			jsr	getALDat_WMode		;Fensteroptionen einlesen.

			ldy	#LINK_DATA_DRIVE	;AppLink-Laufwerk einlesen.
			lda	(r14L),y
			sec
			sbc	#$08
			tax
			ldy	#$00
			jmp	MYCOMP_DRVUSRWIN	;Neues Fenster öffnen.
::exit			rts

;*** AppLink: Eintrag löschen.
.AL_DEL_ENTRY		ldx	AL_CNT_FILE		;AppLink-Nr. einlesen.
			bne	:0			; => MyComputer? Nein, weiter...
			rts

::0			inx
			cpx	LinkData		;Letzter Eintrag?
			beq	:1			; => Ja, weiter...

			lda	AL_VEC_FILE +0		;AppLink-Daten aus Tabelle löschen.
			sta	r1L
			clc
			adc	#< LINK_DATA_BUFSIZE
			sta	r0L
			lda	AL_VEC_FILE +1
			sta	r1H
			adc	#> LINK_DATA_BUFSIZE
			sta	r0H

			lda	#< LinkDataEnd
			sec
			sbc	r1L
			sta	r2L
			lda	#> LinkDataEnd
			sbc	r1H
			sta	r2H

			jsr	MoveData

			lda	AL_VEC_ICON +0		;AppLink-Icon aus Tabelle löschen.
			sta	r1L
			clc
			adc	#$40
			sta	r0L
			lda	AL_VEC_ICON +1
			sta	r1H
			adc	#$00
			sta	r0H

			lda	#< appLinkIBufE		;Ende Speicher für
			sec				;AppLink-Icons.
			sbc	r1L
			sta	r2L
			lda	#> appLinkIBufE
			sbc	r1H
			sta	r2H

			jsr	MoveData

;--- Letzten AppLink-Eintrag löschen.
::1			ldy	#LINK_DATA_BUFSIZE -1
			lda	#$00
::2			sta	LinkDataEnd -LINK_DATA_BUFSIZE,y
			dey
			bpl	:2

			ldy	#LINK_ICON_BUFSIZE -1
::3			sta	appLinkIBufE -LINK_ICON_BUFSIZE,y
			dey
			bpl	:3

			dec	LinkData		;Anzahl AppLinkss -1.

			jsr	MainDTopUpdAppl		;DeskTop+AppLinks neu zeichnen.
			jmp	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

;*** AppLink: Umbennen.
.AL_RENAME_ENTRY	jsr	SUB_LNK_RENAME		;AppLink umbennen.

			jsr	MainDTopUpdAppl		;DeskTop+AppLinks neu zeichnen.
			jmp	WM_DRAW_ALL_WIN		;Fenster aus ScreenBuffer laden.

;*** AppLink: Drucker wechseln.
.AL_SWAP_PRINTER	MoveW	AL_VEC_FILE,r14		;Zeiger auf AppLink-Eintrag.

			jsr	AL_SET_DEVICE		;AppLink-Laufwerk öffnen.
			jmp	EXT_PRINTDBOX		;Drucker auswählen.

;*** Variablen.
.AL_CNT_ENTRY		b $00
:AL_CNT_FILE		b $00
:AL_VEC_FILE		w $0000
:AL_VEC_ICON		w $0000
