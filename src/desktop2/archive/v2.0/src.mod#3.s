; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Source code for DESK TOP V2
;
; Reassembled (w)2020-2023:
;   Markus Kanet
;
; Original authors:
;   Brian Dougherty
;   Doug Fults
;   Jim Defrisco
;   Tony Requist
; (c)1986,1988 Berkeley Softworks
;
; DeskTop GE V2.0 - 11.10.1988 / 17:02
;
; Revision V0.4
; Date: 23/03/25
;
; History:
; V0.1 - Initial reassembled code.
;
; V0.2 - Initial code analysis.
;
; V0.3 - Source code analysis complete.
;
; V0.4 - Added english translation.
;

if .p
			t "TopSym"
;			t "TopMac"
			t "SymTab.rom"
			t "src.DESKTOP.ext"
			t "lang.DESKTOP.ext"

;--- Erweiterte Diskettenroutinen:
:jobNewDirBlk		= 0
:jobGetDskBlk		= 1
:jobPutDskBlk		= 2

;--- Fehlermeldungen:
:ERR_WRPROT		= 0
:ERR_NOTGEOS		= 1
:ERR_DELPAGE		= 2
:ERR_BORDER		= 3

;--- Größe Dateiauswahlbox:
:AREA_FBOX_Y0		= $2a
:AREA_FBOX_Y1		= $72
:AREA_FBOX_X0		= $004b
:AREA_FBOX_X1		= $00bf
:AREA_FBOX_LH		= 12
:MXFBOX			= 6

:MAX_FBOX_FILES		= 94
endif

			n "obj.mod#3"
			o vlirModBase

;*** Sprungtabelle.
:vlirJumpTab		jmp	doSlctPrint		;GEOS/SelectPrint.
			jmp	doSlctInput		;GEOS/SelectInput.
			jmp	doPageAdd		;Page/Add.
			jmp	doPageDel		;Page/Del.

;*** Neuen Drucker auswählen.
:doSlctPrint		lda	diskOpenFlg		;Diskette geöffnet?
			bne	:slct			; => Ja, weiter...
			rts

::slct			jsr	testDiskChanged
			jsr	chkErrRestartDT

			jsr	unselectIcons

			lda	#$ff
			sta	flagSlctFileRdy

			lda	#$11
			jsr	prepDrawIconNm

			jsr	clrPrntName

			lda	a0L
			pha

			lda	#PRINTER
			sta	r9L

			jsr	findFTypeDiskBuf
			txa				;Datei gefunden?
			beq	:found			; => Ja, weiter...

;--- Keine Druckertreiber, leere Box anzeigen.
			lda	#$00
			sta	flagSlctFileRdy

			pla
			sta	a0L

			clv
			bvc	:dispFileBox

;--- Druckertreiber gefunden.
::found			jsr	move_r0_r8

;--- Wurde Treiber auf erster Seite gefunden?
			lda	a0L			;Erste Seite?
			bne	:page			; => Nein, weiter...

;--- Default-Eintrag ab erster Seite suchen.
			jsr	setSwapNxPage
			clv
			bvc	:init

;--- Default-Eintrag ab vorheriger Seite suchen.
::page			jsr	setDefPrevPage

;--- Dateiauswahl initialisieren.
::init			pla				;DeskPad-Seite
			sta	a0L			;zurücksetzen.

			jsr	putPageDefEntry
			jsr	saveSekDefEntry
			jsr	saveAdrDefEntry
			jsr	saveFTypDEntry

;--- Hinweis:
;Das entfernen des Druckernamens vom
;Bildschirm kann das 5. Icon im Border
;teilweise überschrieben.
;Border-Icon neu anzeigen.

;--- Dateiauswahlbox anzeigen.
::dispFileBox		lda	#ICON_BORDER +4
			jsr	prntIconTab1

if LANG = LANG_DE
			lda	#> textPrnEmpty
			sta	r8H
			lda	#< textPrnEmpty
			sta	r8L

			lda	#> textPrinter
			sta	r9H
			lda	#< textPrinter
			sta	r9L
endif
if LANG = LANG_EN
			lda	#> textPrinter
			sta	r8H
			lda	#< textPrinter
			sta	r8L

			lda	#> textPrnEmpty
			sta	r9H
			lda	#< textPrnEmpty
			sta	r9L
endif

			lda	#> PrntFilename
			sta	r5H
			lda	#< PrntFilename
			sta	r5L

			lda	#PRINTER
			sta	r7L

			jsr	doFileSlctBox

;			...

;--- Neuen Drucker setzen.
;":setNewPrinter" liefert keinen
;Fehlerstatus im X-Register zurück.
			jsr	setNewPrinter

			lda	flagSlctFileRdy
			beq	:chkBorder

			lda	vecIconPrntName +0
			sta	r6L
			lda	vecIconPrntName +1
			sta	r6H
			jsr	FindFile
			jsr	chkErrRestartDT

			jsr	move_r5_r6

;--- Ist Datei im BorderBlock?
			jsr	getDEntryCurBlk
			txa
			bne	:setDefault

;--- Datei ist im Borderblock.
;Ist Datei auf aktueller Diskette?
::chkBorder		lda	#> buf_TempStr1
			sta	r6H
			lda	#< buf_TempStr1
			sta	r6L

			lda	#PRINTER
			sta	r7L

			lda	#$01
			sta	r7H

			lda	#$00
			sta	r10L
			sta	r10H
			jsr	FindFTypes

			lda	r7H			;Datei auf Disk?
			bne	:exit			; => Nein, weiter...

;--- Fehler: Datei auf Disk im BorderBlock.
			ldy	#ERR_BORDER
			jsr	openUserErrBox
			clv
			bvc	:exit

;--- Neuen Drucker als Vorgabe setzen.
::setDefault		jsr	move_r1_r3
			jsr	findDirBlock
			jsr	getEntryDiskBuf
			jsr	move_r5_r4
			jsr	loadAdrDefEntry

;--- Zeiger auf Default/Swap-Eintrag identisch?
			lda	r5H			;Default.
			cmp	r4H			;Swap.
			bne	:1
			lda	r5L			;Wenn Default=Swap
			cmp	r4L			;dann nur 1 Treiber.
::1			beq	:exit			; => Ende...

;--- Verzeichnis-Einträge tauschen.
			jsr	doCopyDirEntry
			jsr	writeSwapEntry

;--- Hinweis:
;Hier scheint der Code durcheinander
;geraten zu sein. Vergleiche gleichen
;Abschnitt bei ":doSlctInput".
;			jsr	chkErrRestartDT

;--- Neue Vorgabe speichern.
			jsr	loadSekDefEntry

;--- Hinweis:
;Hier hätte man die gleiche Routine
;wie bei der Auswahl eines neuen
;Eingabetreibers nutzen können.
;			jsr	getPageDefEntry
			lda	adrPageDefEntry +1
			sta	r4H
			lda	adrPageDefEntry +0
			sta	r4L

;--- Hinweis:
;Falsche Position für Fehlerabfrage.
;Siehe Hinweis oben!
			jsr	chkErrRestartDT

			jsr	PutBlock
			jsr	chkErrRestartDT

;--- Hinweis:
;Die Ausgabe des Druckernamens auf dem
;Bildschirm kann das 5. Icon im Border
;teilweise überschrieben.
;Border-Icon neu anzeigen.
			lda	#ICON_BORDER +4
			jsr	prntIconTab1
			jmp	chkUpdCurPage

::exit			lda	#ICON_BORDER +4
			jsr	prntIconTab1
			jmp	reopenCurDisk

;*** Directory-Block suchen.
;Übergabe: r3L/r3H = Tr/Se des gesuchten Blocks.
;Rückgabe: r0      = Zeiger auf ":dirDiskBuf".
:findDirBlock		lda	a0L
			pha

			lda	#$00			;Zeiger auf erste
			sta	a0L			;DeskPad-Seite.

			jsr	testCurDrv1581
			tya
			beq	:not1581

::is1581		lda	r1H
			cmp	#$03
			clv
			bvc	:testblk

::not1581		lda	r1H
			cmp	#$01

::testblk		beq	:exit			; => Block gefunden.

			jsr	setVecDirBlock
			jsr	setPoiNxDirBlk

			lda	r1H			;Verzeichnis-Block
			cmp	r3H			;gefunden?
			bne	:1
			lda	r1L
			cmp	r3L
::1			beq	:found			; => Ja, Weiter...

			inc	a0L
			bne	:testblk		;Weitersuchen...

::found			inc	a0L			;DeskPad-Seite.

;--- Zeiger auf Verzeichnis-Seite in ":dirDiskBuf" setzen
::exit			jsr	setVecDirBlock

			pla
			sta	a0L
			rts

;*** Zeiger auf Eintrag in ":dirDiskBuf" berechnen.
:getEntryDiskBuf	lda	r5L
			sec
			sbc	#< diskBlkBuf
			sta	r5L
			lda	r5H
			sbc	#> diskBlkBuf
			sta	r5H

			lda	r0L
			clc
			adc	r5L
			sta	r5L
			lda	r0H
			adc	r5H
			sta	r5H
			rts

;*** Ersten GEOS-Dateityp in ":dirDiskBuf" suchen.
;Übergabe: r9L = GEOS-Dateityp.
;Rückgabe: r5  = Zeiger auf Verzeichnis-Eintrag.
;          r0  = Zeiger auf verzeichnis-Seite.
:findFTypeDiskBuf	ldy	a1L
			iny
			sty	a0L
			jsr	setVecDirBlock

			lda	r0H			;Endadresse für
			sta	r8H			;Verzeichnis-Suche.

			lda	#$00			;Zeiger auf
			sta	a0L			;Anfang Verzeichnis.
			jsr	setVecDirBlock

			lda	#> dirDiskBuf +2
			sta	r5H
			lda	#< dirDiskBuf +2
			sta	r5L

			lda	#8			;Max. 8 Dateien je
			sta	r7L			;Verzeichnis-Block.

::search		ldy	#$00
			lda	(r5L),y			;Datei vorhanden?
			beq	:next			; => Nein, weiter...

			ldy	#$16
			lda	(r5L),y			;GEOS-Dateityp.
			cmp	r9L			;Dateityp gefunden?
			beq	:found			; => Ja, weiter...

::next			dec	r7L			;Letzter Eintrag?
			beq	:nxpage			; => Ja, weiter...
			bne	:nxfile			;Weitersuchen...

;--- Nächste Verzeichnis-Seite setzen.
::nxpage		inc	a0L
			jsr	setVecDirBlock

			lda	#8			;Eintrag-Zähler
			sta	r7L			;zurücksetzen.

;--- Zeiger auf nächsten Eintrag.
::nxfile		clc
			lda	#$20
			adc	r5L
			sta	r5L
			bcc	:1
			inc	r5H

::1			lda	r5H			;Alle Verzeichnis-
			cmp	r8H			;Seiten durchsucht?
			bcc	:search			; => Nein, weiter...

;--- Keine Datei gefunden.
			ldx	#FILE_NOT_FOUND
			clv
			bvc	:err

;--- Datei gefunden.
::found			ldx	#NO_ERROR
::err			rts

;*** Swap ab 2. Seite suchen und
;    Default ab 1. Seite suchen.
:setSwapNxPage		jsr	setPoiNxDirBlk
			jsr	saveSekSwapEntry

::first_page		jsr	get1stDirTrSe
			sty	r1H
			rts

;*** Swap ab nächster Seite suchen und
;    Default ab vorheriger Seite suchen.
:setDefPrevPage		jsr	setPoiNxDirBlk
			jsr	saveSekSwapEntry

::prev_page		dec	a0L
			jsr	setVecDirBlock
			jsr	setPoiNxDirBlk
			rts

;*** Verzeichniseintrag zwischenspeichern.
;Entweder erster Drucker oder erstes
;Eingabegerät auf Diskette.
;Übergabe: r5 = Zeiger auf Verzeichnis-Eintrag.
:saveFTypDEntry		jsr	move_r5_r4

			lda	#> tempDirEntry
			sta	r5H
			lda	#< tempDirEntry
			sta	r5L
			jmp	doCopyDirEntry

;*** Eintrag des bisherigen Treibers schreiben.
;Übergabe: r4      = Verzeichnis-Eintrag in ":dirDiskBuf".
;          r0      = Seite in ":dirDiskBuf".
;          r1L/r1H = Tr/Se für Verzeichnis-Block.
;Rückgabe: X = Diskfehler.
:writeSwapEntry		lda	r4H			;Zeiger auf Eintrag
			sta	r5H			;in ":dirDiskBuf".
			lda	r4L
			sta	r5L

			lda	#> tempDirEntry
			sta	r4H
			lda	#< tempDirEntry
			sta	r4L
			jsr	doCopyDirEntry

			lda	r0H			;Verzeichnis-Seite
			sta	r4H			;in ":dirDiskBuf".
			lda	r0L
			sta	r4L

			lda	r3H			;Sektor-Adresse für
			sta	r1H			;Verzeichnis-Block.
			lda	r3L
			sta	r1L

			jmp	PutBlock		;Block schreiben.

;*** Muss Seite neu geladen werden?
:chkUpdCurPage		jsr	setVecDirBlock
			jsr	setPoiNxDirBlk

;--- Ist Default-Gerät auf aktueller DeskPad-Seite?
			lda	r1H
			cmp	diskBlkBuf +1
			bne	:1
			lda	r1L
			cmp	diskBlkBuf +0
::1			beq	:reload			; => Ja, neu laden.

;--- Ist altes Default-Gerät auf aktueller DeskPad-Seite?
			lda	r1H
			cmp	sekDevSwapEntry +1
			bne	:2
			lda	r1L
			cmp	sekDevSwapEntry +0
::2			bne	:skip

;--- Seite mit neuem/alten Default aktualisieren.
::reload		jsr	loadIconsCurPage
			txa
			beq	:skip

			lda	#$ff
			sta	flagSlctFileRdy

			jmp	errTestCurDkRdy

;--- Nichts aktualisieren.
::skip			jmp	reopenCurDisk

;*** Neues Eingabegerät wählen.
:doSlctInput		lda	diskOpenFlg		;Diskette geöffnet?
			bne	:slct			; => Ja, weiter...
			rts

::slct			jsr	testDiskChanged
			jsr	chkErrRestartDT

			jsr	unselectIcons

			lda	#$ff
			sta	flagSlctFileRdy

			lda	a0L
			pha

			lda	#INPUT_DEVICE
			sta	r9L

			jsr	findFTypeDiskBuf
			txa				;Datei gefunden?
			beq	:found			; => Ja, weiter...

;--- Keine Eingabetreiber, leere Box anzeigen.
			lda	#$00
			sta	flagSlctFileRdy

			pla
			sta	a0L

			clv
			bvc	:dispFileBox

;--- Eingabetreiber gefunden.
::found			jsr	move_r0_r8		;Verzeichnis-Seite.

;--- Wurde Treiber auf erster Seite gefunden?
			lda	a0L			;Erste Seite?
			bne	:page			; => Nein, weiter...

;--- Default-Eintrag ab erster Seite suchen.
			jsr	setSwapNxPage
			clv
			bvc	:init

;--- Default-Eintrag ab vorheriger Seite suchen.
::page			jsr	setDefPrevPage

;--- Dateiauswahl initialisieren.
::init			pla				;DeskPad-Seite
			sta	a0L			;zurücksetzen.

			jsr	putPageDefEntry
			jsr	saveSekDefEntry
			jsr	saveAdrDefEntry
			jsr	saveFTypDEntry

;--- Dateiauswahlbox anzeigen.
::dispFileBox		lda	#> textInput
			sta	r8H
			lda	#< textInput
			sta	r8L

			lda	#> textInputDev
			sta	r9H
			lda	#< textInputDev
			sta	r9L

			lda	#> inputDevName
			sta	r5H
			lda	#< inputDevName
			sta	r5L

			lda	#INPUT_DEVICE
			sta	r7L

			jsr	doFileSlctBox

;			...

;--- Neues Eingabegerät setzen.
			jsr	setNewInputDev
			bne	:err

			lda	flagSlctFileRdy
			beq	:chkBorder

			ldy	#< inputDevName
			ldx	#> inputDevName
			sty	r6L
			stx	r6H
			jsr	FindFile
			jsr	chkErrRestartDT

			jsr	move_r5_r6

;--- Ist Datei im BorderBlock?
			jsr	getDEntryCurBlk
			txa				;Datei gefunden?
			bne	:setDefault		; => Nein, OK...

;--- Datei ist im Borderblock.
;Ist Datei auf aktueller Diskette?
::chkBorder		lda	#> buf_TempStr1
			sta	r6H
			lda	#< buf_TempStr1
			sta	r6L

			lda	#INPUT_DEVICE
			sta	r7L

			lda	#1
			sta	r7H

			lda	#$00
			sta	r10L
			sta	r10H
			jsr	FindFTypes

			lda	r7H			;Datei auf Disk?
			bne	:exit			; => Nein, weiter...

;--- Fehler: Datei auf Disk im BorderBlock.
			ldy	#ERR_BORDER
			jsr	openUserErrBox
			clv
			bvc	:exit

;--- Neues Eingabegerät als Vorgabe setzen.
::setDefault		jsr	move_r1_r3
			jsr	findDirBlock
			jsr	getEntryDiskBuf
			jsr	move_r5_r4
			jsr	loadAdrDefEntry

;--- Zeiger auf Default/Swap-Eintrag identisch?
			lda	r5H			;Default.
			cmp	r4H			;Swap.
			bne	:1
			lda	r5L			;Wenn Default=Swap
			cmp	r4L			;dann nur 1 Treiber.
::1			beq	:exit			; => Ende...

;--- Verzeichnis-Einträge tauschen.
			jsr	doCopyDirEntry
			jsr	writeSwapEntry
			jsr	chkErrRestartDT

;--- Neue Vorgabe speichern.
			jsr	loadSekDefEntry
			jsr	getPageDefEntry
			jsr	PutBlock
			jsr	chkErrRestartDT

			jmp	chkUpdCurPage

::exit			jmp	reopenCurDisk

::err			jmp	errTestCurDkRdy

;*** Dateien suchen und Auswahlbox anzeigen.
;Übergabe: r5  = Zeiger auf Ablagespeicher Dateiname.
;          r7L = GEOS-Dateityp.
:doFileSlctBox		lda	r5H
			sta	tmpVecFNamBuf +1
			lda	r5L
			sta	tmpVecFNamBuf +0

			lda	#$00			;Keine GEOS-Klasse.
			sta	r10L
			sta	r10H

			lda	#MAX_FBOX_FILES
			sta	r7H			;Max. Dateianzahl.

			lda	#> tempDataBuf
			sta	r6H
			lda	#< tempDataBuf
			sta	r6L			;Dateiliste.

			jsr	FindFTypes		;Dateien suchen.

			lda	#MAX_FBOX_FILES
			sec
			sbc	r7H
			clc
			adc	#1			;Anzahl Dateien
			sta	endFListEntries		;berechnen.

;--- Kein wiederherstellen aus dem Hintergrundbild!
			jsr	setUserRecVec

;--- Mauszeiger auf ersten Eintrag.
			lda	#> AREA_FBOX_X0 +5
			sta	mouseXPos +1
			lda	#< AREA_FBOX_X0 +5
			sta	mouseXPos +0
			lda	#  AREA_FBOX_Y0 +3
			sta	mouseYPos

			ldx	#> dbox_SlctFile
			lda	#< dbox_SlctFile
			jsr	openDlgBox		;Dateiauswahl.

			jmp	resetRecVec		;RecoverVector wieder
							;zurücksetzen.

;*** Variablen für Dateiauswahl.
:endFListEntries	b $00
:bufCurSlctFile		b $00
:bufFirstFile		b $00

;*** Zeiger auf Ablagespeicher Dateiname.
:tmpVecFNamBuf		w $0000

;*** Dialogbox: Dateiauswahl.
:dbox_SlctFile		b %10000001
if LANG = LANG_DE
			b DBTXTSTR ,$84,$30
			w textSlctDev
			b DBVARSTR ,$84,$10
			b r8L
			b DBVARSTR ,$84,$20
			b r9L
endif
if LANG = LANG_EN
			b DBTXTSTR ,$84,$10
			w textSlctDev
			b DBVARSTR ,$84,$20
			b r8L
			b DBVARSTR ,$84,$30
			b r9L
endif
			b OK       ,$11,$4b
			b DBUSRICON,$07,$53
			w :tabIconMoveUp
			b DBUSRICON,$09,$53
			w :tabIconMoveDown
			b DBOPVEC
			w dboxChkMseClk
			b DB_USR_ROUT
			w dboxInitSlctFile
			b NULL

::tabIconMoveUp		w :icon_MoveUp
			b $00,$00,$02,$08
			w func_MoveUp

::tabIconMoveDown	w :icon_MoveDown
			b $00,$00,$02,$08
			w func_MoveDown

;--- System-Icon: Aufwärts scrollen.
::icon_MoveUp		b $80 +5*2			;=$8a
			b %11111111,%11111111
			b %10000001,%10000001
			b %10000011,%11000001
			b %10000111,%11100001
			b %10001111,%11110001
			b $04				;Gepackte Daten.
			b $81
;			b %10000001,%10000001
;			b %10000001,%10000001
			b $80 +2*2			;Fehler? => $80 +1*2
			b %11111111,%11111111

			b $bf				;Farbe für Icon?

;--- System-Icon: Abwärts scrollen.
::icon_MoveDown		b $80 +1*2			;=$82
			b %11111111,%11111111
			b $04				;Gepackte Daten.
			b $81
;			b %10000001,%10000001
;			b %10000001,%10000001
			b $80 +6*2			;Fehler? => $80 +5*2
			b %10001111,%11110001
			b %10000111,%11100001
			b %10000011,%11000001
			b %10000001,%10000001
			b %11111111,%11111111

			b $bf				;Farbe für Icon?

;*** Dateiliste: Seite nach oben.
:func_MoveUp		lda	endFListEntries
			cmp	#MXFBOX +2		;Mehr als 1 Seite?
			bcc	:exit			; => Nein, Ende...

			ldx	bufFirstFile
			beq	:repeat			; => :exit ???

			dec	bufFirstFile

;--- Markierte Datei noch im Fenster?
			lda	bufFirstFile
			clc
			adc	#MXFBOX -3
			cmp	bufCurSlctFile
			bcs	:update
			sta	bufCurSlctFile

::update		jsr	prntCurFBoxPage

::repeat		lda	mouseData
			bpl	func_MoveUp
::exit			rts

;*** Dateiliste: Seite nach unten.
:func_MoveDown		lda	endFListEntries
			cmp	#MXFBOX +2		;Mehr als 1 Seite?
			bcc	:exit			; => Nein, Ende...

			lda	endFListEntries
			sec
			sbc	#MXFBOX +2		;Bereits am Ende?
			cmp	bufFirstFile
			bcc	:exit			; => Ja, Ende...

			inc	bufFirstFile

;--- Markierte Datei noch im Fenster?
			lda	bufCurSlctFile
			cmp	bufFirstFile
			bcs	:update
			inc	bufCurSlctFile

::update		jsr	prntCurFBoxPage

			lda	mouseData
			bpl	func_MoveDown
::exit			rts

;*** Mausklick in Dateiauswahlbox auswerten.
:dboxChkMseClk		bit	mouseData
			bmi	:exit

			lda	#> AREA_FBOX_X0 -1
			sta	r3H
			lda	#< AREA_FBOX_X0 -1
			sta	r3L

			lda	#> AREA_FBOX_X1 +1
			sta	r4H
			lda	#< AREA_FBOX_X1 +1
			sta	r4L

			lda	#AREA_FBOX_Y1 +1
			sta	r2H
			lda	#AREA_FBOX_Y1 +1 -AREA_FBOX_LH
			sta	r2L

			ldx	#MXFBOX -1
::next			jsr	IsMseInRegion
			bne	:found			;Datei angeklickt.

			sec
			lda	r2L
			sbc	#AREA_FBOX_LH
			sta	r2L

			sec
			lda	r2H
			sbc	#AREA_FBOX_LH
			sta	r2H

			dex
			bpl	:next
			bmi	:no_slct

::found			txa				;Eintrag vorhanden?
			clc
			adc	#$01
			cmp	endFListEntries
			bcs	:no_slct		; => Nein, Ende...

			txa				;Neue Datei
			clc				;ausgewählt...
			adc	bufFirstFile
			pha

;--- Vorherige Auswahl löschen.
			ldx	bufCurSlctFile
			jsr	invertFileEntry

			pla
			sta	bufCurSlctFile

;--- Neue Auswahl anzeigen.
			pha
			tax
			jsr	invertFileEntry
			jsr	copySlctFName
			pla

;--- Auf Doppelklick testen.
			ldy	dblClickCount
			beq	:wait_dblclk

;--- Doppelklick auf gleiche Datei?
			cmp	bufLastFileSlct
			bne	:wait_dblclk

;--- Ja, Datei auswählen, Ende...
			jmp	exitDBoxFileSlct

;--- Verzögerung für Doppelklick setzen.
::wait_dblclk		sta	bufLastFileSlct

			lda	#30
			sta	dblClickCount
			rts

;--- Doppelklick abbrechen.
::no_slct		lda	#0
			sta	dblClickCount

::exit			rts

;*** Zuletzt gewählte Datei.
:bufLastFileSlct	b $00

;*** Dateiauswahlbox initialisieren.
:dboxInitSlctFile	jsr	initChkCrsrKeys

			lda	#$00
			sta	bufCurSlctFile
			sta	bufFirstFile

			jsr	drawFrameFBox

;*** Aktuelle Seite anzeigen.
:prntCurFBoxPage	jsr	clearFileBox

			lda	bufFirstFile
			clc
			adc	#$07
			cmp	endFListEntries
			bmi	:1
			lda	endFListEntries
::1			sta	r15L

			ldx	bufFirstFile
			inx

::next			txa
			pha
			jsr	setVecSlctEntry
			pla

			pha
			jsr	prntNxFBoxFile
			pla

			tax
			inx
			cpx	r15L
			bcc	:next

			ldx	bufCurSlctFile
			jsr	invertFileEntry

;--- Überflüssiger JMP-Befehl?
			jmp	copySlctFName

;*** Name der gewählten Datei in Zwischenspeicher.
:copySlctFName		ldx	bufCurSlctFile
			inx
			txa
			jsr	setVecSlctEntry

			lda	tmpVecFNamBuf +1
			sta	r1H
			lda	tmpVecFNamBuf +0
			sta	r1L

			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Nächste Datei anzeigen.
:prntNxFBoxFile		pha
			sec
			sbc	bufFirstFile
			tax
			dex

			lda	tabEntryPosBase,x
			sta	r1H

			lda	#> AREA_FBOX_X1
			sta	rightMargin +1
			lda	#< AREA_FBOX_X1
			sta	rightMargin +0

			lda	#> AREA_FBOX_X0 +3
			sta	r11H
			lda	#< AREA_FBOX_X0 +3
			sta	r11L

			lda	#SET_BOLD
			sta	currentMode

			pla
			tax
			jsr	PutString

			lda	#> $013f
			sta	rightMargin +1
			lda	#< $013f
			sta	rightMargin +0
			rts

;*** Zeiger auf Baseline für Eintrag.
:tabEntryPosBase	b AREA_FBOX_Y0 +0*AREA_FBOX_LH +8
			b AREA_FBOX_Y0 +1*AREA_FBOX_LH +8
			b AREA_FBOX_Y0 +2*AREA_FBOX_LH +8
			b AREA_FBOX_Y0 +3*AREA_FBOX_LH +8
			b AREA_FBOX_Y0 +4*AREA_FBOX_LH +8
			b AREA_FBOX_Y0 +5*AREA_FBOX_LH +8

;*** Dateieintrag invertieren.
;Übergabe: X = Zeiger auf Eintrag (max. 0-93).
:invertFileEntry	txa
			sec
			sbc	bufFirstFile
			tax
			lda	tabEntryPosTop,x
			sta	r2L
			clc
			adc	#12
			sta	r2H

			lda	#> AREA_FBOX_X0
			sta	r3H
			lda	#< AREA_FBOX_X0
			sta	r3L

			lda	#> AREA_FBOX_X1
			sta	r4H
			lda	#< AREA_FBOX_X1
			sta	r4L

			jmp	InvertRectangle

;*** Zeiger auf erste Grafikzeile für Eintrag.
:tabEntryPosTop		b AREA_FBOX_Y0 +0*AREA_FBOX_LH
			b AREA_FBOX_Y0 +1*AREA_FBOX_LH
			b AREA_FBOX_Y0 +2*AREA_FBOX_LH
			b AREA_FBOX_Y0 +3*AREA_FBOX_LH
			b AREA_FBOX_Y0 +4*AREA_FBOX_LH
			b AREA_FBOX_Y0 +5*AREA_FBOX_LH

;*** Inhalt Dateibox löschen.
:clearFileBox		jsr	i_Rectangle
			b AREA_FBOX_Y0,AREA_FBOX_Y1
			w AREA_FBOX_X0,AREA_FBOX_X1
			rts

;*** Rahmen um Dateibox zeichen.
:drawFrameFBox		jsr	i_FrameRectangle
			b AREA_FBOX_Y0 -1,AREA_FBOX_Y1 +1
			w AREA_FBOX_X0 -1,AREA_FBOX_X1 +1
			b %11111111
			rts

;*** Nicht verwendet?
:l6095			lda	tmpVecFNamBuf +0
			sta	zpage,x
			inx
			lda	tmpVecFNamBuf +1
			sta	zpage,x
			rts

;*** Dateiauswahlbox beenden.
:exitDBoxFileSlct	lda	#OK
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Zeiger auf gewählten Dateinamen setzen.
;Übergabe: A  = Datei-Nummer (1-94).
;Rückgabe: r0 = Zeiger auf Dateiname.
:setVecSlctEntry	tay

			lda	#< tempDataBuf
			sta	r0L
			lda	#> tempDataBuf
			sta	r0H

::search		dey
			beq	:found

			lda	r0L
			clc
			adc	#17
			sta	r0L
			bcc	:search
			inc	r0H

			clv
			bvc	:search

::found			rts

;*** Mauspfeil über Tastatur bewegen.
:checkKeyboard		ldy	keyData

			lda	#< (-10)
			ldx	#> (-10)
			cpy	#KEY_LEFT
			beq	:movePointerX

			lda	#<  10
			ldx	#>  10
			cpy	#KEY_RIGHT
			beq	:movePointerX

			lda	#< (-8)
			cpy	#KEY_UP
			beq	:movePointerY

			lda	#<  8
			cpy	#KEY_DOWN
			beq	:movePointerY

			cpy	#CR
			bne	:exit

			lda	mouseData
			and	#%01111111
			sta	mouseData

			lda	pressFlag
			ora	#%00100000
			sta	pressFlag

::exit			rts

;--- Mauszeiger links/rechts.
::movePointerX		clc
			adc	mouseXPos +0
			sta	mouseXPos +0
			txa
			adc	mouseXPos +1
			sta	mouseXPos +1
			rts

;--- Mauszeiger hoch/runter.
::movePointerY		clc
			adc	mouseYPos
			sta	mouseYPos

;--- Fehler?
;Fehlt hier ein RTS?
;Wenn der Mauszeiger hoch oder runter
;bewegt wird, dann wird auch immer die
;Tastaturabfrage neu installiert.

;*** Tastaturabfrage installieren.
:initChkCrsrKeys	lda	#> checkKeyboard
			sta	keyVector +1
			lda	#< checkKeyboard
			sta	keyVector +0
			rts

;*** Zeiger auf Sektor mit Swap-Gerät einlesen.
:loadSekDefEntry	lda	sekDefaultEntry +1
			sta	r1H
			lda	sekDefaultEntry +0
			sta	r1L
			rts

;*** Zeiger auf Default-Eintrag in ":dirDiskBuf" einlesen.
:loadAdrDefEntry	lda	adrDefaultEntry +1
			sta	r5H
			lda	adrDefaultEntry +0
			sta	r5L
			rts

;*** Seite in ":dirDiskBuf" mit Default-Eintrag einlesen.
:getPageDefEntry	lda	adrPageDefEntry +1
			sta	r4H
			lda	adrPageDefEntry +0
			sta	r4L
			rts

;*** Zeiger auf Verzeichnis-Seite zwischenspeichern.
:move_r0_r8		lda	r0H
			sta	r8H
			lda	r0L
			sta	r8L
			rts

;*** Zeiger auf Sektor mit Default-Gerät speichern.
:saveSekDefEntry	lda	r1H
			sta	sekDefaultEntry +1
			lda	r1L
			sta	sekDefaultEntry +0
			rts

;*** Zeiger auf Verzeichnis-Block nach :r3.
:move_r1_r3		lda	r1H
			sta	r3H
			lda	r1L
			sta	r3L
			rts

;*** Zeiger auf Sektor mit Swap-Gerät speichern.
:saveSekSwapEntry	lda	r1H
			sta	sekDevSwapEntry +1
			lda	r1L
			sta	sekDevSwapEntry +0
			rts

;*** Zeiger auf Default-Eintrag in ":dirDiskBuf" speichern.
:saveAdrDefEntry	lda	r5H
			sta	adrDefaultEntry +1
			lda	r5L
			sta	adrDefaultEntry +0
			rts

;*** Zeiger auf Verzeichnis-Seite nach :r4.
:move_r5_r4		lda	r5H
			sta	r4H
			lda	r5L
			sta	r4L
			rts

;*** Zeiger auf Eintrag in ":diskBlkBuf" speichern.
:move_r5_r6		lda	r5H
			sta	r6H
			lda	r5L
			sta	r6L
			rts

;*** Seite in ":dirDiskBuf" mit Default-Eintrag speichern.
:putPageDefEntry	lda	r8H
			sta	adrPageDefEntry +1
			lda	r8L
			sta	adrPageDefEntry +0
			rts

;*** Variablen für Treiber-Auswahl.
:flagSlctFileRdy	b $00				;$ff = Treiber ausgewählt.

:adrDefaultEntry	w $0000				;Eintrag in ":dirDiskBuf".

:adrPageDefEntry	w $0000				;Seite in ":dirDiskBuf".

:sekDefaultEntry	w $0000				;Sektor-Adresse Default-Eintrag.
:sekDevSwapEntry	w $0000				;Sektor-Adresse Swap-Eintrag.

;*** System-Texte.
if LANG = LANG_DE
:dbtx_ErrBorder1	b BOLDON
			b "Der Treiber liegt am Rand",NULL

:dbtx_ErrBorder2	b "und wird nicht zur"
			b GOTOXY
			w $0050
			b $60
			b "Voreinstellung.",NULL
endif
if LANG = LANG_EN
:dbtx_ErrBorder1	b BOLDON
			b "The driver is on the border",NULL

:dbtx_ErrBorder2	b "and it won't be set as the"
			b GOTOXY
			w $0050
			b $60
			b "default.",NULL
endif

;*** Neue Verzeichnis-Seite einfügen.
:doPageAdd		lda	diskOpenFlg		;Diskette geöffnet?
			beq	:exit			; => Nein, Ende...

			jsr	testCurViewMode
			bcc	:exit			;Kein Icon-Modus.

			jsr	testDiskChanged

			php
			sei

			jsr	unselectIcons

			ldy	a0L
			cpy	#$11			;Max. 17 Seiten
			bcs	:errDirFull

			sty	r6L
			jsr	get1stDirTrSe
			sty	r1H

::findCurPage		ldy	#jobGetDskBlk
			jsr	execDiskBlkJob
			txa
			bne	:err

			dec	r6L
			bmi	:found

			lda	diskBlkBuf +0
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			clv
			bvc	:findCurPage

::found			lda	diskBlkBuf +0
			beq	:new
			sta	r9L
			lda	diskBlkBuf +1
			sta	r9H

;--- Seite an aktueller Position einfügen.
			ldy	#jobNewDirBlk
			jsr	execDiskBlkJob
			txa
			bne	:err

			lda	r9H
			sta	diskBlkBuf +1
			lda	r9L
			sta	diskBlkBuf +0

			ldy	#jobPutDskBlk
			jsr	execDiskBlkJob
			txa
			bne	:err

			clv
			bvc	:update

::new			ldy	#jobNewDirBlk
			jsr	execDiskBlkJob
			txa
			bne	:err

::update		inc	a0L
			inc	a1L
			jsr	PutDirHead
			txa
			bne	:err

			jsr	reopenCurDisk
			txa
			bne	:err

			clv
			bvc	:ok

::errDirFull		ldx	#FULL_DIRECTORY
::err			jsr	errTestCurDkRdy

::ok			plp
::exit			rts

;*** Erweiterte Diskettenroutinen ausführen.
;Übergabe: Y = $00: Neuen Verzeichnisblock erstellen.
;              $01: Block von Diskette einlesen.
;              $02: Block auf Diskette schreiben.
:execDiskBlkJob		lda	:tabDJobL,y
			ldx	:tabDJobH,y
			jsr	CallRoutine
			rts

::tabDJobH		b >CreateNewDirBlk
			b >GetDiskBlkBuf
			b >PutDiskBlkBuf
::tabDJobL		b <CreateNewDirBlk
			b <GetDiskBlkBuf
			b <PutDiskBlkBuf

;*** Aktuelle Verzeichnis-Seite löschen.
:doPageDel		lda	diskOpenFlg		;Diskette geöffnet?
			beq	:exit			; => Nein, Ende...

			jsr	testCurViewMode
			bcc	:exit			;Kein Icon-Modus.

			jsr	testDiskChanged
			jsr	unselectIcons

			lda	a0L			;Erste Seite?
			bne	:1			; => Nein, weiter..

			jmp	:err1stPage		;Fehler!

::1			lda	#$00			;Dateizähler löschen.
			sta	flagFilesOnPage

			lda	#8 -1
::find			sta	a3H
			jsr	isIconGfxInTab
			beq	:next

			sta	flagFilesOnPage

			lda	a3H
			ldx	#r9L
			jsr	setVecIcon2File

;--- System- oder Hauptdiskette?
			lda	curDirHead +$bd
			beq	:wrprot			; => Arbeitsdiskette.

			jmp	doErrNotAllowed

;--- Schreibgeschützte Datei?
::wrprot		ldy	#$00
			lda	(r9L),y
			and	#%01000000		;Schreibschutz?
			beq	:cbmdir			; => Nein, weiter...

			ldy	#ERR_WRPROT
			jmp	openUserErrBox

::cbmdir		ldy	#$00
			lda	(r9L),y
			and	#%00001111
			cmp	#CBMDIR			;CBM-Verzeichnis?
			bne	:next			; => Nein, weiter...

;--- Fehler?
;Die Fehlermeldung die hier angezeigt
;wird ist "Seite enthält Nicht-GEOS-
;Dateien"... es wird aber nur auf CBM-
;Verzeichnisse getestet!

			ldy	#ERR_NOTGEOS
			jmp	openUserErrBox

::next			lda	a3H			;Alle Einträge
			sec				;geprüft?
			sbc	#1
			bpl	:find			; => Nein, weiter...

			lda	flagFilesOnPage
			beq	:jobDelPage		; => Keine Dateien...

;--- Dialogbox: Alle Dateien auf Seite werden gelöscht.
			ldx	#> dbox_PageFiles
			lda	#< dbox_PageFiles
			jsr	openDlgBox
			cmp	#CANCEL			;Abbruch?
			bne	:jobDelPage		; => Nein, weiter...

::exit			rts

;			...

;--- Aktuelle Seite löschen.
::jobDelPage		dec	a0L
			jsr	setVecDirBlock
			jsr	setPoiNxDirBlk

			ldy	#jobGetDskBlk
			jsr	execDiskBlkJob
			txa
			beq	:curDirBlk
			jmp	:err

::curDirBlk		lda	diskBlkBuf +0
			sta	r9L
			lda	diskBlkBuf +1
			sta	r9H			;Link nächster Block.

			jsr	delFilesOnPage
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			lda	r6H			;Tr/Se aktueller
			pha				;Verzeichnisblock.
			lda	r6L
			pha

			lda	diskBlkBuf +0
			beq	:endOfDir		; => Letzte Seite.

			lda	a0L			;Vorherige Seite =
			beq	:setLink1stBlk		;erste Seite?

			dec	r0H
			jsr	setPoiNxDirBlk
			inc	r0H

;--- Neuen Link zu nächstem Verzeichnis-Sektor setzen.
::updLinkPoi		jsr	writeNewDirLink
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			pla
			sta	r1L
			pla
			sta	r1H

			inc	a0L
			jsr	setVecDirBlock
			dec	a0L

			lda	r0H
			sta	r4H
			lda	r0L
			sta	r4L

;--- Hinweis:
;":PutBlock" liefert immer Z-Flag=1
;zurück. Grund ist der interne Aufruf
;von ":EnterTurbo", das mit X=$00 für
;"Kein Fehler" beendet wird.
;Danach wird ":InitForIO" aufgerufen
;und zuerst der Prozessor-Status inkl.
;Z-Flag=1 zwischengespeichert.
;Am Ende wird dann intern ":DoneWithIO"
;aufgerufen und der Prozessor-Status
;inkl. Z-Flag=1 wieder hergestellt.
;Auch wenn das X-Register einen Fehler
;meldet ist Z-Flag=1 und es wird kein
;Fehler ausgewertet.
;Nur wenn ":EnterTurbo" einen Fehler
;Fehler meldet, dann würde hier eine
;(falsche) Fehlermeldung angezeigt.
			jsr	PutBlock
			beq	:update			;Nicht immer TRUE!

::err1stPage		ldy	#ERR_DELPAGE
			jmp	openUserErrBox

;			...

;--- Verzeichnis-Ende erreicht.
::endOfDir		lda	a0L			;Erste Seite?
			bne	:getPrev		; => Nein, weiter...

;--- Tr/Se für ersten Verzeichnis-Sektor.
			jsr	get1stDirTrSe
			sty	r1H
			bne	:setLinkNxBlk

;--- Link auf nächste Seite aus vorherigem Block lesen.
;Übergabe: r0 = Zeiger auf ":dirDiskBuf".
::getPrev		dec	r0H
			jsr	setPoiNxDirBlk

;--- Link auf nächste Seite übernehmen.
::setLinkNxBlk		jsr	writeNewDirLink
			txa
			bne	:err

			pla
			sta	r1L
			pla
			sta	r1H

			inc	a0L
			jsr	setVecDirBlock
			dec	a0L

			lda	r0H
			sta	r4H
			lda	r0L
			sta	r4L

;--- Hinweis:
;":PutBlock" liefert immer Z-Flag=1
;zurück, siehe oben...
;Nur wenn ":EnterTurbo" einen Fehler
;Fehler meldet, dann würde hier das
;Programm nicht korrekt fortgesetzt.
			jsr	PutBlock
			beq	:update			;Nicht immer TRUE!

::setLink1stBlk		jsr	get1stDirTrSe
			sty	r1H

			clv
			bvc	:updLinkPoi

::err			jmp	errTestCurDkRdy

::update		dec	a1L
			jsr	PutDirHead
			txa
			bne	:err

			jsr	reopenCurDisk
			txa
			bne	:err
			rts

;*** Dateien auf nächster Seite löschen.
;Übergabe: a0L = Vorherige Verzeichnis-Seite.
:delFilesOnPage		lda	r1H
			pha
			lda	r1L
			pha

			lda	r0H
			pha
			lda	r0L
			pha

			lda	r9H
			pha
			lda	r9L
			pha

			inc	a0L

			lda	#ICON_PAD +7
::find			sta	a3H
			jsr	isIconGfxInTab
			beq	:next

			lda	a3H
			ldx	#r9L
			jsr	setVecIcon2File
			jsr	FreeFile

			lda	a3H
			jsr	removeFileEntry

			lda	#$00			;Papierkorb leeren.
			sta	a8H

::next			lda	a3H
			sec
			sbc	#1
			bpl	:find

			dec	a0L

			pla
			sta	r9L
			pla
			sta	r9H

			pla
			sta	r0L
			pla
			sta	r0H

			pla				;Verzeichnis-Block
			sta	r6L			;freigeben.
			pla
			sta	r6H
			jsr	FreeBlock

			rts

;*** Zeiger auf nächsten Verzeichnisblock einlesen.
:setPoiNxDirBlk		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			rts

;*** Neuen Linkzeiger in Verzeichnisblock schreiben.
:writeNewDirLink	ldy	#jobGetDskBlk
			jsr	execDiskBlkJob
			jsr	exitOnDiskErr

			lda	r9H
			sta	diskBlkBuf +1
			lda	r9L
			sta	diskBlkBuf +0

			ldy	#jobPutDskBlk
			jmp	execDiskBlkJob

;*** Dialogbox: Alle Dateien auf Seite werden gelöscht.
:dbox_PageFiles		b %10000001
			b DBTXTSTR   ,$10,$20
			w dbtx_delete1
			b DBTXTSTR   ,$10,$30
			w dbtx_delete2
			b OK         ,$01,$48
			b CANCEL     ,$11,$48
			b NULL

;*** Dialogbox: Kann Seite nicht löschen.
;Übergabe: Y = 0: Schreibgeschützte Dateien.
;              1: Nicht-GEOS-Dateien / CBM1581-Partitionen.
;              2: Kann Seite 1 nicht löschen.
;              3: Treiber liegt im Border.
:openUserErrBox		lda	:tabLine1L,y
			sta	:dbtx1 +0
			lda	:tabLine1H,y
			sta	:dbtx1 +1

			lda	:tabLine2L,y
			sta	:dbtx2 +0
			lda	:tabLine2H,y
			sta	:dbtx2 +1

			ldx	#> :dbox_ErrMsg
			lda	#< :dbox_ErrMsg
			jmp	openDlgBox

;--- Zeiger auf Texte für Zeile #1.
::tabLine1H		b >dbtx_ErrPageHdr
			b >dbtx_ErrPageHdr
			b >dbtx_ErrPage1a
			b >dbtx_ErrBorder1
::tabLine1L		b <dbtx_ErrPageHdr
			b <dbtx_ErrPageHdr
			b <dbtx_ErrPage1a
			b <dbtx_ErrBorder1

;--- Zeiger auf Texte für Zeile #2.
::tabLine2H		b >dbtx_ErrWrProt
			b >dbtx_ErrCBM81
			b >dbtx_ErrPage1b
			b >dbtx_ErrBorder2
::tabLine2L		b <dbtx_ErrWrProt
			b <dbtx_ErrCBM81
			b <dbtx_ErrPage1b
			b <dbtx_ErrBorder2

;--- Dialogbox: Fehlermeldung.
::dbox_ErrMsg		b %10000001
			b DBTXTSTR  ,$10,$20
::dbtx1			w $0000
			b DBTXTSTR  ,$10,$30
::dbtx2			w $0000
			b OK        ,$11,$48
			b NULL

;*** Dateien auf der aktuellen DeskPad_Seite?
:flagFilesOnPage	b $00

;*** Fehler-Texte.
if LANG = LANG_DE
:dbtx_delete1		b BOLDON
			b "Alle Dateien dieser Seite",NULL
:dbtx_delete2		b "gehen verloren.",NULL
endif
if LANG = LANG_EN
:dbtx_delete1		b BOLDON
			b "All files on this page will",NULL
:dbtx_delete2		b "be lost.",NULL
endif

if LANG = LANG_DE
:dbtx_ErrPageHdr	b BOLDON
			b "Nicht löschbar: Seite enthält",NULL
:dbtx_ErrWrProt		b "schreibgeschützte Dateien.",NULL

;--- Fehler?
;Die Fehlermeldung die hier angezeigt
;wird ist "Seite enthält Nicht-GEOS-
;Dateien"... es wird aber nur auf CBM-
;Verzeichnisse getestet!
:dbtx_ErrCBM81		b "Nicht-GEOS-Dateien",NULL
endif
if LANG = LANG_EN
:dbtx_ErrPageHdr	b BOLDON
			b "Can't delete a page with",NULL
:dbtx_ErrWrProt		b "write protected files.",NULL
:dbtx_ErrCBM81		b "CBM files",NULL
;--- Hinweis:
;Alternativer Fehlertext.
;:dbtx_ErrCBM81		b "CBM 1581 partitions.",NULL
endif

if LANG = LANG_DE
:dbtx_ErrPage1a		b BOLDON
			b "Kann Seite 1 des deskTop",NULL
:dbtx_ErrPage1b		b "nicht löschen.",NULL
endif
if LANG = LANG_EN
:dbtx_ErrPage1a		b BOLDON
			b "Can't delete first page",NULL
:dbtx_ErrPage1b		b "on deskTop.",NULL
endif

;Endadresse VLIR-Modul testen:
			g vlirModEnd
