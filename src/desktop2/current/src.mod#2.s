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
; Revision V1.0
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
; V1.0 - Updated to V2.1.
;

if .p
			t "TopSym"
;			t "TopMac"
			t "src.DESKTOP.ext"
			t "lang.DESKTOP.ext"

;--- Abmessungen Infobox.
;Werden im Hauptmodul definiert, da die
;Koordinaten auch für die Bildschirm-
;Wiederherstellung benötigt werden.
;AREA_INFOBOX_Y0	= $28
;AREA_INFOBOX_Y1	= $b5
;AREA_INFOBOX_X0	= $0048
;AREA_INFOBOX_X1	= $00ef

;--- Positionen innerhalb der Infobox.
:AREA_INFOBOX_CX	= (AREA_INFOBOX_X0 + AREA_INFOBOX_X1) /2
:AREA_INFOBOX_TX	= AREA_INFOBOX_X0 +$2f
:AREA_INFOBOX_IX	= AREA_INFOBOX_TX +$06
:AREA_INFOBOX_LH	= 11
:AREA_INFOBOX_L1	= AREA_INFOBOX_Y0 + AREA_INFOBOX_LH*2
:AREA_INFOBOX_L2	= AREA_INFOBOX_Y0 + AREA_INFOBOX_LH*9
:AREA_INFOBOX_TW	= $0035

;--- Koordinaten für Infotext-Bereich:
:AREA_INFOTXT_Y0	= AREA_INFOBOX_Y1 -5 -32
:AREA_INFOTXT_Y1	= AREA_INFOBOX_Y1 -5
:AREA_INFOTXT_X0	= AREA_INFOBOX_X0 +6
:AREA_INFOTXT_X1	= AREA_INFOBOX_X1 -6

;--- Bit-Masken für WordWrap:
:CLRWRAPBIT		= %01111111
:SETWRAPBIT		= %10000000
endif

			n "obj.mod#2"
			o vlirModBase

;*** Sprungtabelle.
:vlirJumpTab		jmp	doFileInfo		;Datei/Info.

;*** Datei-Info anzeigen.
:doFileInfo		jsr	testDiskChanged

			ldx	#> batchJobFileInfo
			lda	#< batchJobFileInfo
			jmp	execBatchJob

;*** Info einer einzelnen Datei anzeigen.
:batchJobFileInfo	ldx	#$20			;":menuDataInfo"
			jsr	putScreenToBuf

			lda	#> dbox_FileInfo +1
			sta	r0H
			lda	#< dbox_FileInfo +1
			sta	r0L
			jsr	grfxScrColRec

			lda	#> dbox_FileInfo
			sta	r0H
			lda	#< dbox_FileInfo
			sta	r0L
			jsr	DoDlgBox

			lda	a5H			;Icon für aktuellen
			pha				;Job abwählen.
			lda	a5L
			pha
			jsr	unselectJobIcon
			pla
			sta	a5L
			pla
			sta	a5H

			jsr	testDiskChanged
			jsr	chkErrRestartDT

			jsr	initVecCurDEntry

			ldx	#$00
			ldy	#$00
			lda	tempDirEntry,y
			cmp	(r9L),y			;Schreibschutz neu?
			beq	:done			; => Nein, weiter...

			sta	(r7L),y			;Status Schreibschutz
			sta	(r9L),y			;speichern.

			jsr	updateCurDirPage
			jsr	updateBorderBlk

::done			rts

;*** Dialogbox für Datei-Info.
:dbox_FileInfo		b %00000000
			b AREA_INFOBOX_Y0,AREA_INFOBOX_Y1
			w AREA_INFOBOX_X0,AREA_INFOBOX_X1
			b DBGRPHSTR
			w graphStrHeader
			b DBUSRICON,$12,$01
			w tabIconClose
			b DBOPVEC
			w checkMseWrProt
			b DB_USR_ROUT
			w prntAllFileInfo
			b NULL

;*** Close-Icon für Dialogbox.
:tabIconClose		w icon_CloseDisk
			b $00,$00,$02,$0b
			w closeFileInfo

;*** Datei-Info beenden.
:closeFileInfo		lda	tempDirEntry +22
			beq	:exit			;Keine GEOS-Datei.

			lda	a4L			;Datei auf Disk?
			beq	:exit			; => Nein, Ende...

			lda	flagInfoText
			beq	:exit

			jsr	disableTxInput

			bit	tabInputData +off_Modes
			bpl	:exit			;Text nicht geändert.

			lda	tempDirEntry +20
			sta	r1H
			lda	tempDirEntry +19
			sta	r1L
			jsr	r4_bufDiskSek1
			jsr	PutBlock		;Infoblock speichern.

::exit			jmp	RstrFrmDialogue

;*** Info-Auswahl-Flag.
:flagFTypeGEOS		b $00				;$00 = GEOS-Datei.

;*** Datei-Informationen ausgeben.
:prntAllFileInfo	jsr	r4_r5_dirEntry
			jsr	doCopyDirEntry

			jsr	r4_bufDiskSek1

			lda	a4L			;Datei auf Disk?
			bne	:1			; => Ja, weiter...

			lda	#$ff
			sta	flagFTypeGEOS
			clv
			bvc	:2

::1			ldy	#19			;Infoblock.
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	GetBlock
			stx	flagFTypeGEOS

::2			lda	buf_diskSek1 +2
			cmp	#$03			;GEOS-Icon?
			bne	:3
			lda	buf_diskSek1 +3
			cmp	#$15
			beq	:4			; => Ja, weiter...
::3			sta	flagFTypeGEOS

;--- Dateiname.
::4			ldx	#> tempDirEntry +3
			lda	#< tempDirEntry +3
			jsr	copyIconTitle

;--- Dateiname zentriert im Titel ausgeben.
			jsr	r0_buf_TempName

			lda	#> AREA_INFOBOX_CX
			sta	r11H
			lda	#< AREA_INFOBOX_CX
			sta	r11L
			lda	#  AREA_INFOBOX_Y0 +8
			sta	r1H
			jsr	prntCenterText

;--- Zeilen-Titel für Info ausgeben.
			ldx	#> AREA_INFOBOX_TX
			stx	r11H
			lda	#< AREA_INFOBOX_TX
			sta	r11L
			lda	#  AREA_INFOBOX_Y0 +22
			sta	r1H

;			ldx	#$00
::prnt			lda	tabInfoTitleL,x
			sta	r0L
			lda	tabInfoTitleH,x
			sta	r0H

			txa
			pha
			jsr	prntRJustedText
			pla
			tax

			lda	r1H
			clc
			adc	#11
			sta	r1H

			inx
			cpx	#6			;Autor?
			bcc	:prnt			; => Nein, weiter...

			beq	:chkAuthor		;6 = Autor testen.
			bcs	:author			;7 = Autor ausgeben.

;			...

;--- Autor möglich?
;Bei bestimmten Dateitypen wird kein
;Autor ausgegeben.
::chkAuthor		lda	tempDirEntry +22
			cmp	#INPUT_128
			bcs	:datetime

			tay
			lda	tabPrntAuthor,y
			bne	:prnt
			beq	:datetime

;--- GEOS-Autor.
::author		lda	#SET_BOLD
			sta	currentMode

			jsr	setXYPosInfo

			lda	flagFTypeGEOS
			bne	:datetime

			ldx	#> buf_diskSek1 +97
			lda	#< buf_diskSek1 +97
			jsr	putStringAX		;Autor.

;--- Dateidatum ausgeben.
;Nur bei GEOS-Dateien, bei Lafwerken
;mit RTC-uhr (CMD-Laufwerke) wird bei
;BASIC-Dateien kein Datum ausgegeben!
::datetime		lda	#SET_BOLD
			sta	currentMode

			jsr	setXYPosInfo

			lda	tempDirEntry +22
			beq	:size			;Keine GEOS-Datei.

			jsr	prntFileDateTime

;--- Dateigröße ausgeben.
::size			jsr	setXYPosInfo

			jsr	prntLJustFSize

;--- Dateistruktur ausgeben.
::struct		jsr	setXYPosInfo

			lda	tempDirEntry +21
			tax
			lda	tabFileStructL,x
			pha
			lda	tabFileStructH,x
			tax
			pla
			jsr	putStringAX		;SEQ/VLIR.

;--- GEOS-Klasse ausgeben.
::class			jsr	setXYPosInfo

			lda	flagFTypeGEOS
			bne	:ftype

			lda	tempDirEntry +22
			beq	:ftype			;Keine GEOS-Datei.

			ldx	#> buf_diskSek1 +77
			lda	#< buf_diskSek1 +77
			jsr	putStringAX		;GEOS-Klasse.

;--- CBM-/GEOS-Dateityp ausgeben.
::ftype			jsr	setXYPosInfo
			jsr	prntInfoFType

;--- Dateiname ausgeben.
::fname			jsr	setXYPosInfo

			lda	a3L
			ldx	#r4L
			jsr	getCurIconDkNm

			jsr	r0_buf_TempName

			ldx	#r4L
			ldy	#r0L
			jsr	copyNameA0_16
			jsr	PutString

;			...

;--- Schreibschutz ausgeben.
::wrprot		jsr	setRecWrProt

			lda	#$ff
			jsr	FrameRectangle

			lda	tempDirEntry
			and	#%01000000		;Schreibschutz?
			beq	:5			; => Nein, weiter...

			jsr	setRecWrProt
			jsr	InvertRectangle

::5			lda	#> AREA_INFOBOX_IX
			sta	r11H
			lda	#< AREA_INFOBOX_IX
			sta	r11L
			lda	#  AREA_INFOBOX_L2
			sta	r1H

			ldx	#> txWrProt
			lda	#< txWrProt
			jsr	putStringAX

			lda	#$00
			sta	flagInfoText

			lda	a4L			;Datei auf Disk?
			beq	:6			; => Nein, weiter...

			lda	flagFTypeGEOS
			bne	:exit

::6			lda	tempDirEntry +22
			bne	:infotext

::exit			rts

::infotext		lda	a4L			;Datei auf Disk?
			bne	:doinfo			; => Ja, weiter...

::noinfo		jsr	setXYPosErrInfo

			ldx	#> txErrOtherDisk
			lda	#< txErrOtherDisk
			jmp	putStringAX		;Kein Infotext.

::doinfo		lda	#$ff
			sta	flagInfoText

			jmp	prntInfoText

;*** Autor anzeigen?
;Bei bestimmten Dateitypen wird kein
;Autor ausgegeben ($00 = kein Autor).
:tabPrntAuthor		b $00				;x NOT_GEOS
			b $ff				;  BASIC
			b $ff				;  ASSEMBLER
			b $00				;x DATA
			b $00				;x SYSTEM
			b $ff				;  DESK_ACC
			b $ff				;  APPLICATION
			b $ff				;+ APPL_DATA  - ab V2.1...
			b $ff				;+ FONT       - ab V2.1...
			b $ff				;  PRINTER
			b $ff				;  INPUT_DEVICE
			b $ff				;  DISK_DEVICE
			b $ff				;  SYSTEM_BOOT
			b $00				;x TEMPORARY
			b $ff				;  AUTO_EXEC

;*** Kein Infotext, Position für Fehler setzen.
:setXYPosErrInfo	lda	#> AREA_INFOTXT_X0 +10
			sta	r11H
			lda	#< AREA_INFOTXT_X0 +10
			sta	r11L
			lda	#  AREA_INFOTXT_Y0 +18
			sta	r1H
			rts

;*** Position für Info setzen.
:setXYPosInfo		sec
			lda	r1H
			sbc	#AREA_INFOBOX_LH
			sta	r1H

			lda	#> AREA_INFOBOX_IX
			sta	r11H
			lda	#< AREA_INFOBOX_IX
			sta	r11L
			rts

;*** Koordinaten für Schreibschutz-Box setzen.
:setRecWrProt		ldy	#6 -1
::1			lda	:tabRecWrProt,y
			sta	r2,y
			dey
			bpl	:1
			rts

::tabRecWrProt		b AREA_INFOBOX_L2 -7,AREA_INFOBOX_L2
			w AREA_INFOBOX_TX -7,AREA_INFOBOX_TX

;*** Prüfen ob Schreibschutz angeklickt wurde.
:checkMseWrProt		bit	mouseData		;Maustaste gedrückt?
			bmi	:exit			; => Nein, Ende...

			jsr	chkBIconOpenDkNm
			txa
			beq	:exit

			jsr	setRecWrProt

			jsr	IsMseInRegion
			beq	:exit

			lda	tempDirEntry +0
			eor	#%01000000		;Schreibschutz.
			sta	tempDirEntry +0

			jsr	InvertRectangle

::exit			rts

;*** Info-Überschriften.
:tabInfoTitleL		b < txInfoDisk
			b < txInfoType
			b < txInfoClass
			b < txInfoStruct
			b < txInfoSize
			b < txInfoUpdated
			b < txInfoAuthor
:tabInfoTitleH		b > txInfoDisk
			b > txInfoType
			b > txInfoClass
			b > txInfoStruct
			b > txInfoSize
			b > txInfoUpdated
			b > txInfoAuthor

;*** Dateistruktur-Typen.
:tabFileStructL		b < txStructSEQ
			b < txStructVLIR
:tabFileStructH		b > txStructSEQ
			b > txStructVLIR

;*** Titelzeile zeichnen.
:graphStrHeader		b NEWPATTERN
			b PAT_TITLE
			b MOVEPENTO
			w AREA_INFOBOX_X0 +1
			b AREA_INFOBOX_Y0 +1
			b RECTANGLETO
			w AREA_INFOBOX_X1 -1
			b AREA_INFOBOX_Y0 +13
			b MOVEPENTO
			w AREA_INFOTXT_X0 -2
			b AREA_INFOTXT_Y0 -1
			b FRAME_RECTO
			w AREA_INFOTXT_X1 +2
			b AREA_INFOTXT_Y1 +1
			b NULL

;*** Eingaberoutine für Infotext.
;
;--- Max. Breite Eingabefeld:
:max_Width		= $270f

;--- Input-Optionen:
:off_BufVec		= 0
:off_MaxChars		= 2
:off_posText		= 4
:off_posCursor		= 6
:off_Modes		= 8				;%10000000: Text geändert.
							;%01000000: Kein RETURN möglich.
							;%00100000: Text-Scrolling.
							;%00010000: RecoverRectangle.
:off_InputRout		= 9
:off_minY		= 11
:off_maxY		= 12
:off_minX		= 13
:off_maxX		= 15
:off_charMode		= 17
:off_Font		= 18

;--- Definition für Eingabefeld.
:tabInputData		w buf_diskSek1 +160
			w $005f				;max. 95 Zeichen.
			w $0000				;Aktuelle Text-Position.
			w $0000				;Aktuelle Cursor-Position.
			b $00				;Input-Optionen.
			w $0000				;Input-Routine.
			b AREA_INFOTXT_Y0
			b AREA_INFOTXT_Y1
			w AREA_INFOTXT_X0
			w AREA_INFOTXT_X1
			b $40				;currentMode.
			w $0000				;Zeiger auf Zeichensatz.
			b $00
			b $00

;--- Zwischenspeicher für System-Routinen.
:bufOPressVec		w $0000
:bufKeyVec		w $0000

;--- Zeiger auf aktuelle Textposition.
:poiCurTextPos		w $0000

;--- Status für Infotext.
:flagInfoTxData		b $00				;$ff = Kein Infotext.

;*** Infotext ausgeben.
:prntInfoText		lda	#> tabInputData
			sta	r0H
			lda	#< tabInputData
			sta	r0L

			lda	r0H
			sta	string +1
			lda	r0L
			sta	string +0

			jsr	getSizeInputArea
			jsr	clearCurTxLine
			jsr	setCurInputData

			lda	#$00
			sta	flagInfoTxData

			jsr	redrawCurTxLines
			bcc	enableTxInput

;*** Eingaberoutine aufrufen.
;Übergabe: %10000000: Text neu ausgeben.
;          %01000000: Textspeicher voll.
;          %00100000: Sonderbehandlung für RETURN.
:execInputReDraw	ldy	#%10000000
:execInputRout		sty	r2L

			ldy	#off_InputRout
			lda	(string),y
			pha
			iny
			lda	(string),y
			tax
			pla
			ldy	r2L
			jmp	CallRoutine

;*** Texteingae initialisieren.
:enableTxInput		jsr	loadCurFontInfo

			lda	otherPressVec +1
			sta	bufOPressVec +1
			lda	otherPressVec +0
			sta	bufOPressVec +0

			lda	keyVector +1
			sta	bufKeyVec +1
			lda	keyVector +0
			sta	bufKeyVec +0

			lda	#> userChkMseClk
			sta	otherPressVec +1
			lda	#< userChkMseClk
			sta	otherPressVec +0

			lda	#> userChkKeyboard
			sta	keyVector +1
			lda	#< userChkKeyboard
			sta	keyVector +0

			jsr	setCurInputData
			jsr	getPosBaseLine
			pha
			jsr	loadCurFontInfo
			pla
			jsr	InitTextPrompt
			jsr	getSizeInputArea

;--- Cursor setzen.
			lda	r4H
			sta	r7H
			lda	r4L
			sta	r7L			;Neue X-Koordinate.

			lda	r2H
			sta	r8L			;Neue Y-Koordinate.

;*** Texteingabe an neuer Position fortsetzen.
:doNxInput		jsr	setCurInputData
			jsr	getSizeInputArea

::loop			jsr	getPosBaseLine
			sec
			adc	r2L
			cmp	r8L
			beq	:1
			bcs	findCursorPos
::1			sta	r6L

			lda	r0H			;Aktuelle Position
			sta	r9H			;zwischenspeichern.
			lda	r0L
			sta	r9L

::2			ldy	#$00
			lda	(r0L),y			;Textende?
			beq	:end			; => Ja, Ende...
			php
			jsr	inc_r0
			plp				;WordWrap gefunden?
			bpl	:2			; => Nein, weiter...

			lda	r6L
			sta	r2L
			clv
			bvc	:loop

::end			lda	r9H			;Aktuelle Position
			sta	r0H			;zurücksetzen.
			lda	r9L
			sta	r0L

			lda	#>max_Width
			sta	r7H
			lda	#<max_Width
			sta	r7L

;*** Aktuelle Cursor-Position suchen.
:findCursorPos		ldy	#$00
			lda	(r0L),y			;Textende?
			beq	:done			; => Ja, weiter...
			and	#CLRWRAPBIT
			cmp	#CR			;Zeilenende?
			beq	:done			; => Ja, weiter...

			ldx	currentMode		;Die reale
			jsr	GetRealSize		;Zeichenbreite
			tya				;ermitteln und
			sta	r6L			;addieren.
			clc
			adc	r3L
			sta	r3L
			bcc	:1
			inc	r3H

::1			ldy	#$00
			lda	(r0L),y
			jsr	inc_r0
			cmp	#NULL			;Letztes Zeichen?
			bmi	:done			; => Ja, weiter...

			lda	r3H
			cmp	r7H
			bne	:2
			lda	r3L
			cmp	r7L
::2			bcc	findCursorPos

			lda	r7H
			cmp	#>max_Width		;Max.Breite erreicht?
			beq	:done			; => Ja, weiter...

			lda	r3L
			sec
			sbc	r7L
			asl
			cmp	r6L
			bcc	:done

			jsr	dec_r0

			lda	r3L
			sec
			sbc	r6L
			sta	r3L
			bcs	:done
			dec	r3H

::done			ldy	#off_posText
			lda	r0L
			sta	(string),y
			iny
			lda	r0H
			sta	(string),y

			ldy	#off_posCursor
			lda	r0L
			sta	(string),y
			iny
			lda	r0H
			sta	(string),y

			lda	r3H			;X-Koordinate Cursor.
			sta	stringX +1
			lda	r3L
			sta	stringX +0

			ldy	#off_maxY
			lda	(string),y
			cmp	r2L
			bcs	:3
			sta	r2L

::3			lda	r2L			;Y-Koordinate Cursor.
			sta	stringY

			jsr	PromptOn		;Cursor ein.

;*** Zeichensatz-Informationen zurücksetzen.
:loadCurFontInfo	ldx	#$08
::1			lda	saveFontTab -1,x
			sta	baselineOffset -1,x
			dex
			bne	:1

			lda	saveFontTab +8
			sta	currentMode
			rts

;*** Eingabe Infotext abschalten.
:disableTxInput		jsr	setCurInputData
			jsr	clrWordWrapBit
			jsr	loadCurFontInfo

			jsr	PromptOff		;Cursor aus.

			lda	#%01111111
			and	alphaFlag
			sta	alphaFlag

;--- Vektoren zurücksetzen.
			lda	bufOPressVec +1
			sta	otherPressVec +1
			lda	bufOPressVec +0
			sta	otherPressVec +0

			lda	bufKeyVec +1
			sta	keyVector +1
			lda	bufKeyVec +0
			sta	keyVector +0
			rts

;*** Mausklick auswerten / Cursor setzen.
:userChkMseClk		lda	mouseData		;Maustaste gedrückt?
			bmi	:sys			; => Nein, weiter...

			jsr	getSizeInputArea
			jsr	chkSetCursorPos
			bcc	:sys

			lda	mouseXPos +1
			sta	r7H
			lda	mouseXPos +0
			sta	r7L			;Neue X-Koordinate.
			lda	mouseYPos
			sta	r8L			;Neue Y-Koordinate.

			jmp	doNxInput		;Eingabe fortsetzen.

::sys			lda	bufOPressVec +0
			ldx	bufOPressVec +1
			jmp	CallRoutine

;*** Tastaturabfrage.
:userChkKeyboard	lda	keyData
			bmi	:exit

			cmp	#KEY_LEFT
			beq	delCharInfoText
			cmp	#KEY_DELETE
			beq	delCharInfoText
			cmp	#KEY_INSERT
			beq	delCharInfoText
			cmp	#KEY_RIGHT
			beq	delCharInfoText

			cmp	#CR
			beq	:edit
			cmp	#" "			;SPACE?
			bcc	:exit

::edit			jmp	addCharInfoText

::exit			rts

;*** Zeichen links vom Cursor löschen.
:delCharInfoText	jsr	setCurInputData
			jsr	getStartCurLine

			lda	r0H
			cmp	r4H
			bne	:1
			lda	r0L
			cmp	r4L
::1			beq	:exit

			jsr	dec_r4

			lda	r4L
			ldy	#off_posText +0
			sta	(string),y
			ldy	#off_posCursor +0
			sta	(string),y

			lda	r4H
			ldy	#off_posText +1
			sta	(string),y
			ldy	#off_posCursor +1
			sta	(string),y

			ldy	#$00
::delete		iny
			lda	(r4L),y
			dey
			sta	(r4L),y

			jsr	inc_r4

			cmp	#NULL
			bne	:delete

			jsr	setFlagUpdInfo

			lda	#$ff
			sta	flagInfoTxData
			jmp	chkCurLine1stPos

::exit			jmp	loadCurFontInfo

;*** Neues Zeichen in Text aufnehmen.
;Übergabe: A = Zeichencode.
:addCharInfoText	cmp	#CR
			bne	:test_add

			pha

			ldy	#off_Modes
			lda	(string),y
			and	#%01000000		;RETURN möglich?
			beq	:add_cr			; => Ja, weiter...

			pla
			ldy	#%00100000		;RETURN gedrückt.
			jmp	execInputRout

::add_cr		pla
::test_add		pha				;Neues Zeichen.

			jsr	setCurInputData
			jsr	getStartCurLine
			jsr	getLenCurInfoTx

			ldy	#off_MaxChars
			lda	r2L
			cmp	(string),y
			bne	:new_char
			iny
			lda	r2H
			cmp	(string),y		;Speicher voll?
			bne	:new_char		; => Nein, weiter..

			pla
			jsr	loadCurFontInfo

			ldy	#%01000000		;Textspeicher voll.
			jmp	execInputRout

::new_char		lda	r4L
			clc
			adc	#$01
			ldy	#off_posText +0
			sta	(string),y
			ldy	#off_posCursor +0
			sta	(string),y

			lda	r4H
			bcc	:1
			clc
			adc	#$01
::1			ldy	#off_posText +1
			sta	(string),y
			ldy	#off_posCursor +1
			sta	(string),y

			pla
			pha
			tax				;Neues Zeichen.

			ldy	#$00
			lda	(r4L),y
			sta	r2L			;Aktuelles Zeichen.

::insert		lda	(r4L),y			;Plaz für ein
			pha				;neues Zeichen
			txa				;vorbereiten.
			sta	(r4L),y
			jsr	inc_r4
			pla
			tax				;Zeilenende?
			bne	:insert			; => Nein, weiter...

			sta	(r4L),y			;Ende-Kennung.

			jsr	setFlagUpdInfo

			lda	#$00
			sta	flagInfoTxData

			pla
			cmp	#CR			;Neues Zeichen = CR?
			beq	:next_line		; => Ja, weiter...

			jsr	chkPrntLastChar
			bcc	:exit

			jmp	chkCurLine1stPos

::next_line		jmp	setCursorNxLine

::exit			rts

;*** Test ob nur letztes Zeichen ausgegeben werden muss.
;Übergabe: A   = Eingefügtes Zeichen.
;          r2L = Nächstes Zeichen.
;Rückgabe: C-Flag = 0: Letztes Zeichen wurde ausgegeben.
;                 = 1: Zeile neu ausgeben.
:chkPrntLastChar	sta	r5L
			lda	r2L
			and	#CLRWRAPBIT		;Textende?
			beq	:test			; => Ja, weiter...
			cmp	#CR			;RETURN?
			beq	:test			; => Ja, weiter...
::fail			sec				;Zeilenende wurde
			rts				;noch nicht erreicht.

::test			lda	r5L			;Neues Zeichen.
			ldx	currentMode		;Realze Zeichenbreite
			jsr	GetRealSize		;ermitteln.

			tya				;Neue X-Position
			clc				;für Zeicheneingabe
			adc	stringX +0		;berechnen.
			sta	r4L
			lda	#$00
			adc	stringX +1
			sta	r4H

			ldy	#off_maxX +1
			lda	(string),y
			cmp	r4H
			bne	:1
			dey
			lda	(string),y		;Max.Breite Eingabe-
			cmp	r4L			;feld überschritten?
::1			bcc	:fail
			beq	:fail			;Ja, Ende...

			lda	windowBottom
			pha

			ldy	#off_maxY		;Max. Unterkante für
			lda	(string),y		;Eingabefeld setzen.
			sta	windowBottom

			lda	stringX +1		;Aktuelle Position
			sta	r11H			;Cursor für
			lda	stringX +0		;Textausgabe setzen.
			sta	r11L
			lda	stringY
			sta	r1H

			lda	r5L			;Neues Zeichen.
			jsr	prntCharBaseLine

			pla
			sta	windowBottom

			ldy	#off_Modes
			lda	(string),y
			and	#%00010000		;RecoverRectangle ?
			beq	:newcpos		; => Nein, weiter...

			jsr	getSizeInputArea

			lda	r1H			;Position baseline.
			sta	r2L			;Als Ober- und
			sta	r2H			;Unterkante setzen.
			cmp	windowBottom
			beq	:clrbline		;Baseline löschen.
			bcs	:newcpos		; => Nicht löschen.

::clrbline		lda	stringX +1		;Bereich für
			sta	r3H			;Zeichenausgabe
			lda	stringX +0		;löschen.
			sta	r3L
			jsr	move_r11_r4
			jsr	move_r11_strgX
			jsr	dec_r4
			jsr	doPat0Rect
			clv
			bvc	:setcursor

::newcpos		jsr	move_r11_strgX
::setcursor		jsr	doneNewCursor
			clc
			rts

;*** Auf Zeilenwechsel testen.
:chkCurLine1stPos	lda	stringX +1
			cmp	r11H
			bne	:1
			lda	stringX +0
			cmp	r11L
::1			beq	setCursorNxLine

			lda	r3H
			pha
			lda	r3L
			pha
			jsr	PromptOff
			jsr	copyInputCurPos
			pla				;Zeiger auf erstes
			sta	r0L			;Zeichen der
			pla				;aktuellen Zeile
			sta	r0H			;zurücksetzen.

			lda	stringY			;Y-Koordinate für
			sta	r1H			;aktuelle Zeile.

;*** Infotext ab aktueller Zeile neu Zeichnen.
:updateInfoText		jsr	redrawCurTxLines
			bcc	doneNewCursor
			jmp	execInputReDraw

;*** Cursor neu positioniert, Cursor einschalten.
:doneNewCursor		jsr	PromptOn
			jmp	loadCurFontInfo

;*** Cursor auf neue Zeile setzen.
:setCursorNxLine	lda	#$ff
			sta	flagInfoTxData
			jsr	PromptOff
			jsr	copyInputCurPos
			jmp	updateInfoText

;*** Anfang der aktuellen Zeile suchen:
;- Erstes Zeichen im Infotext.
;- Erstes Zeichen nach letztem WordWrap.
;- Erstes Zeichen nach letztem CR.
:getStartCurLine	lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L

			jsr	dec_r3

			ldy	#$00
::1			lda	r3H
			cmp	r0H
			bne	:2
			lda	r3L
			cmp	r0L
::2			beq	:done			;Anfang Infotext.

			jsr	dec_r3

			lda	(r3L),y
			bpl	:1

			jsr	:inc_r3			;WordWrap.

::done			lda	(r3L),y
			cmp	#CR
			bne	:exit

::inc_r3		inc	r3L			;CR.
			bne	:exit
			inc	r3H
::exit			rts

;*** Aktuelle Cursorposition einlesen.
:copyInputCurPos	ldy	#off_posText
			lda	(string),y
			sta	poiCurTextPos +0
			iny
			lda	(string),y
			sta	poiCurTextPos +1
			rts

;*** Anzahl Zeichen im Infotext ermitteln.
:getLenCurInfoTx	lda	r0H
			sta	r2H
			lda	r0L
			sta	r2L

			ldy	#$00
::1			lda	(r2L),y
			beq	:3
			inc	r2L
			bne	:2
			inc	r2H
::2			clv
			bvc	:1

::3			lda	r2L
			sec
			sbc	r0L
			sta	r2L
			lda	r2H
			sbc	r0H
			sta	r2H

			rts

;*** Modus "Text geändert" setzen.
:setFlagUpdInfo		ldy	#off_Modes
			lda	(string),y
			ora	#%10000000		;Text geändert.
			sta	(string),y
			rts

;*** Infotext ab aktueller Zeile neu ausgeben.
;Rückgabe: C-Flag = 1: Externe Scrolling-Routine aufrufen.
:redrawCurTxLines	lda	windowBottom
			pha

			ldy	#off_maxY
			lda	(string),y
			sta	windowBottom

			jsr	move_r11_strgX
			lda	r1H
			sta	stringY

::cur_line		jsr	clrInputCurPos
::next_word		jsr	checkCursorPos

			ldy	#$00
			lda	(r0L),y
			and	#CLRWRAPBIT
			beq	:end_text
			cmp	#CR
			beq	:next_line

			jsr	testWordWrap
			bcs	:next_line		;Word-Wrap notwendig.

::next			jsr	checkCursorPos

			ldy	#$00
			lda	(r0L),y
			and	#CLRWRAPBIT		;Word-Wrap-Flag
			sta	(r0L),y			;aus Zeichen löschen.
			cmp	#CR			;Neue Zeile?
			beq	:next_line		; => Ja, weiter...

			jsr	prntCurInfoLine
			beq	:end_text
			cmp	#" "			;Word-Wrapping?
			bne	:next			; => Ja, weiter...
			beq	:next_word

::next_line		jsr	redrawCharLine
			jsr	chkSetWWrapBit
			jsr	testMaxInpYPos
			jsr	getPosBaseLine
			clc
			adc	r1H
			cmp	windowBottom
			bcc	:no_scroll

			ldy	#off_Modes
			lda	(string),y
			and	#%00100000		;Text-Scrolling?
			beq	:no_scroll		; => Nein, weiter...

			pla
			sta	windowBottom
			sec
			rts

::no_scroll		ldy	#off_minX
			lda	(string),y
			sta	r11L
			iny
			lda	(string),y
			sta	r11H
			clv
			bvc	:cur_line

::end_text		bit	flagInfoTxData
			bpl	:no_text		; => Kein Text.

			jsr	testMaxInpYPos
			jsr	getSizeInputArea
			lda	r1H
			sta	r2L
			jsr	testSizeClrLine

::no_text		pla
			sta	windowBottom
			clc
			rts

;*** Größe für aktuelle Textzeile testen.
:testSizeClrLine	lda	r2L
			cmp	r2H
			beq	:1
			bcs	noClr
::1			lda	windowBottom
			cmp	r2H
			bcs	clearCurTxLine
			sta	r2H

;*** Aktuelle Textzeile löschen.
:clearCurTxLine		ldy	#off_Modes
			lda	(string),y
			and	#%00010000		;RecoverRectangle ?
			beq	doPat0Rect		; => Nein, weiter...
			jmp	RecoverRectangle

;*** Bereich mit Pattern #0 löschen.
:doPat0Rect		lda	curPattern +1
			pha
			lda	curPattern +0
			pha
			jsr	setPattern0
			jsr	Rectangle
			pla
			sta	curPattern +0
			pla
			sta	curPattern +1
:noClr			rts

;*** Zeile ab Zeichen neu ausgeben.
;Übergabe: Y = Zeiger auf aktuelles Zeichen in Infotext.
:redrawCharLine		sty	r4L

			ldy	#off_minX
			lda	(string),y
			cmp	r11L
			bne	:exit
			iny
			lda	(string),y
			cmp	r11H
			bne	:exit

::1			lda	r4L
			beq	:exit
			pha
			jsr	checkCursorPos
			jsr	prntCurInfoLine
			pla
			sta	r4L
			dec	r4L
			bne	:1
::exit			rts

;*** Eingabefeld ab aktueller Zeile löschen.
;Übergabe: r11 = X-Koordinate links.
;          r1H = Y-Koordinate oben (Baseline).
:clrInputCurPos		jsr	getSizeInputArea

			lda	r11H
			sta	r3H
			lda	r11L
			sta	r3L

			lda	r1H
			sta	r2L

;			lda	r2L
			cmp	windowBottom
			beq	:1
			bcs	:exit

::1			jsr	getPosBaseLine
			sec
			adc	r2L
			sta	r2H

			lda	r11H
			pha
			lda	r11L
			pha
			jsr	testSizeClrLine
			pla
			sta	r11L
			pla
			sta	r11H
::exit			rts

;*** Bereich unterhalb Textzeile löschen.
:clrInfoBelowLine	ldy	#off_Modes
			lda	(string),y
			and	#%00010000		;RecoverRectanle ?
			beq	:exit			; => Nein, weiter...

			jsr	getSizeInputArea

			lda	r1H
			sta	r2L
			sta	r2H
			cmp	windowBottom
			beq	:1
			bcs	:exit

::1			lda	r11H
			cmp	r3H
			bne	:2
			lda	r11L
			cmp	r3L
::2			beq	:exit

			jsr	move_r11_r4

			lda	r11H
			pha
			lda	r11L
			pha
			jsr	doPat0Rect
			pla
			sta	r11L
			pla
			sta	r11H

::exit			rts

;*** Cursor-Position an Textposition setzen.
:checkCursorPos		lda	poiCurTextPos +1
			cmp	r0H
			bne	:1
			lda	poiCurTextPos +0
			cmp	r0L
::1			bne	:exit

			jsr	move_r11_strgX

			lda	r1H
			sta	stringY
::exit			rts

;*** Prüfen ob WordWrap-Bit gesetzt werden muss.
:chkSetWWrapBit		ldy	#$00
			lda	(r0L),y
			and	#CLRWRAPBIT
			cmp	#CR
			bne	:1

			jsr	checkCursorPos
			clv
			bvc	:2

::1			jsr	dec_r0

::2			lda	(r0L),y
			ora	#SETWRAPBIT		;WordWrap setzen!
			sta	(r0L),y

;*** Position auf nächstes Textzeichen setzen.
:inc_r0			inc	r0L
			bne	:1
			inc	r0H
::1			rts

;*** Aktuelle Zeile ausgeben.
:prntCurInfoLine	ldy	#$00
			lda	(r0L),y
			and	#CLRWRAPBIT
			sta	(r0L),y
			beq	:exit

			jsr	prntCharBaseLine

			ldy	#$00
			lda	(r0L),y
			jsr	inc_r0
			cmp	#NULL

::exit			rts

;*** Zeichen auf Baseline ausgeben.
:prntCharBaseLine	tax

			lda	r1H
			pha

			txa
			pha

			ldx	currentMode
			lda	#"A"
			jsr	GetRealSize
			sec
			adc	r1H
			sta	r1H

			pla
			jsr	PutChar

			pla
			sta	r1H
			jmp	clrInfoBelowLine

;*** Max. Y-Position für Eingabe testen.
:testMaxInpYPos		jsr	getPosBaseLine
			sec
			adc	r1H
			cmp	windowBottom
			bcc	:1
			beq	:1

			lda	windowBottom
			clc
			adc	#$01
::1			sta	r1H
			rts

;*** Position der Baseline ermitteln.
:getPosBaseLine		ldx	currentMode
			lda	#"A"
			jsr	GetRealSize
			txa
			rts

;*** Auf WordWrap testen.
:testWordWrap		lda	r11H
			sta	r2H
			lda	r11L
			sta	r2L

			ldy	#off_maxX
			lda	(string),y
			sta	r3L
			iny
			lda	(string),y
			sta	r3H

			ldy	#$00
::loop			lda	(r0L),y
			and	#CLRWRAPBIT
			beq	:ok
			sta	r4L

			cmp	#CR
			beq	:ok

			sty	r4H
			ldx	currentMode
			jsr	GetRealSize
			tya
			ldy	r4H
			clc
			adc	r2L
			sta	r2L
			bcc	:1
			inc	r2H

::1			lda	r2H
			cmp	r3H
			bne	:2
			lda	r2L
			cmp	r3L
::2			bcs	:fail

			iny
			lda	r4L			;Aktuelles Zeichen.
			cmp	#" "			;Ende Wort erreicht?
			bne	:loop			; => Nein, weiter...

::ok			clc				;Wort passt in Zeile.
::fail			rts

;*** Daten für Texteingabe setzen.
; - Benutzerfont (falls definiert)
; - Textmodus (currentMode)
:setCurInputData	jsr	saveCurFontInfo

			ldy	#off_Font
			lda	(string),y
			sta	r0L
			iny
			lda	(string),y
			sta	r0H
			ora	r0L
			bne	:userfont

			jsr	UseSystemFont
			clv
			bvc	:setmode

::userfont		jsr	LoadCharSet		;Benutzerfont.

::setmode		ldy	#off_charMode
			lda	(string),y
			sta	currentMode		;Textmodus.

			ldy	#off_minX
			lda	(string),y
			sta	r11L
			iny
			lda	(string),y
			sta	r11H			;Start-X-Koordinate.

			ldy	#off_minY
			lda	(string),y
			sta	r1H			;Start-Y-Koordinate.

			ldy	#off_BufVec
			lda	(string),y
			sta	r0L
			iny
			lda	(string),y
			sta	r0H			;Eingabespeicher.

			ldy	#off_posText
			lda	(string),y
			sta	r4L
			iny
			lda	(string),y
			sta	r4H			;Aktuelle Position.

			rts

;*** WordWrap-Bit im Infotext löschen.
:clrWordWrapBit		ldy	#$00
::1			lda	(r0L),y
			and	#CLRWRAPBIT
			sta	(r0L),y
			beq	:end

			jsr	inc_r0
			clv
			bvc	:1

::end			rts

;*** Zeichensatzdaten speichern.
:saveCurFontInfo	ldx	#$08
::1			lda	baselineOffset -1,x
			sta	saveFontTab -1,x
			dex
			bne	:1

			lda	currentMode
			sta	saveFontTab +8

			rts

;*** Größe Eingabefeld einlesen.
:getSizeInputArea	ldy	#off_minY
			ldx	#$00
::1			lda	(string),y
			sta	r2,x
			iny
			inx
			cpx	#$06
			bne	:1
			rts

;*** Mausklick innerhalb Infotext?
;Rückgabe: C-Flag = 0: Nein
;                   1: Ja
:chkSetCursorPos	lda	mouseYPos
			cmp	r2L
			bcc	:fail
			cmp	r2H
			beq	:1
			bcs	:fail

::1			lda	mouseXPos +0
			ldx	mouseXPos +1
			cpx	r3H
			bne	:2
			cmp	r3L
::2			bcc	:fail

			cpx	r4H
			bne	:3
			cmp	r4L
::3			beq	:ok
			bcs	:fail

::ok			sec
			rts

::fail			clc
			rts

;*** Cursor an Textposition setzen.
:move_r11_strgX		lda	r11H
			sta	stringX +1
			lda	r11L
			sta	stringX +0
			rts

;*** Rechten Rand für RECTANGLE setzen.
:move_r11_r4		lda	r11H
			sta	r4H
			lda	r11L
			sta	r4L
			rts

;*** Zeiger auf nächstes Zeichen für INSERT/DELETE setzen.
:inc_r4			inc	r4L
			bne	:1
			inc	r4H
::1			rts

;*** Zeiger auf vorheriges Zeichen setzen.
:dec_r0			lda	r0L
			bne	:1
			dec	r0H
::1			dec	r0L
			rts

;*** Vorheriges Zeichen für Suche nach Zeilenanfang.
:dec_r3			lda	r3L
			bne	:1
			dec	r3H
::1			dec	r3L
			rts

;*** Vorheriges Zeichen / Rechter Rand setzen.
:dec_r4			lda	r4L
			bne	:1
			dec	r4H
::1			dec	r4L
			rts

;*** CBM-/GEOS-Dateityp ausgeben.
:prntInfoFType		lda	tempDirEntry +22
			bne	:geos			;Keine GEOS-Datei.

			lda	tempDirEntry +0
			sec
			sbc	#$01			;CBM-Dateityp.
			and	#%00001111
			cmp	#$05			;Unbekannt?
			bcs	:exit			; => Ja, Ende...

			clc
			adc	#15			;Zeiger für Tabelle.
			clv
			bvc	:prnt

::geos			cmp	#INPUT_128		;GEOS-Typ gültig?
			bcs	:exit			; => Nein, Ende...

::prnt			tax

			lda	tempDirEntry +0
			pha				;Dateityp merken.

			lda	tabInfoFTypL,x
			pha
			lda	tabInfoFTypH,x
			tax
			pla
			jsr	putStringAX		;Dateityp anzeigen.

			pla
			and	#%01000000		;Schreibschutz?
			beq	:exit			; => Nein, weiter...

			ldx	#> prntWrProtStatus
			lda	#< prntWrProtStatus
			jsr	putStringAX

::exit			rts

;*** Zeiger auf Texte für GEOS-Dateityp.
:tabInfoFTypL		b < txFTyp_NotGEOS
			b < txFTyp_BASIC
			b < txFTyp_ASSEMBLE
			b < txFTyp_DATA
			b < txFTyp_SYSTEM
			b < txFTyp_DESKACC
			b < txFTyp_APPLIC
			b < txFTyp_APPLDATA
			b < txFTyp_FONT
			b < txFTyp_PRINTER
			b < txFTyp_INPUT
			b < txFTyp_DISK
			b < txFTyp_BOOT
			b < txFTyp_TEMP
			b < txFTyp_AUTOEXEC
			b < txFTyp_CBM_SEQ
			b < txFTyp_CBM_PRG
			b < txFTyp_CBM_USR
			b < txFTyp_CBM_REL
			b < txFTyp_CBM_DIR

:tabInfoFTypH		b > txFTyp_NotGEOS
			b > txFTyp_BASIC
			b > txFTyp_ASSEMBLE
			b > txFTyp_DATA
			b > txFTyp_SYSTEM
			b > txFTyp_DESKACC
			b > txFTyp_APPLIC
			b > txFTyp_APPLDATA
			b > txFTyp_FONT
			b > txFTyp_PRINTER
			b > txFTyp_INPUT
			b > txFTyp_DISK
			b > txFTyp_BOOT
			b > txFTyp_TEMP
			b > txFTyp_AUTOEXEC
			b > txFTyp_CBM_SEQ
			b > txFTyp_CBM_PRG
			b > txFTyp_CBM_USR
			b > txFTyp_CBM_REL
			b > txFTyp_CBM_DIR

;*** Sonstige Dateiinfo-Angaben.
:txFTyp_CBM_SEQ		b PLAINTEXT
			b $80				;C= SEQ
			b BOLDON
			b " SEQ"
			b NULL

:txFTyp_CBM_PRG		b PLAINTEXT
			b $80				;C= PRG
			b BOLDON
			b " PRG"
			b NULL

:txFTyp_CBM_USR		b PLAINTEXT
			b $80				;C= USR
			b BOLDON
			b " USR"
			b NULL

:txFTyp_CBM_REL		b PLAINTEXT
			b $80				;C= REL
			b BOLDON
			b " REL"
			b NULL

:txFTyp_CBM_DIR		b PLAINTEXT
			b $80				;C= CBM
			b BOLDON
			b " CBM"
			b NULL

:prntWrProtStatus	b GOTOX
			w AREA_FILEPAD_X1 -8
			b REV_ON," ",REV_OFF
			b NULL

;*** Datum/Zeit der Änderung ausgeben.
:prntFileDateTime	lda	tempDirEntry +22
			beq	:exit

			lda	r11H
			pha
			lda	r11L
			pha

if LANG = LANG_DE
			lda	tempDirEntry +25
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Tag.

			lda	tempDirEntry +24
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Monat.
endif
if LANG = LANG_EN
			lda	tempDirEntry +24
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Month.

			lda	tempDirEntry +25
			sec				;"/" ausgeben.
			jsr	prntDateNum		;Day.
endif

			lda	tempDirEntry +23
			clc				;Ende-Kennung.
			jsr	prntDateNum		;Jahr.

			pla				;Tabulator für
			clc				;Ausgabe Uhrzeit.
			adc	#< AREA_INFOBOX_TW
			sta	r11L
			pla
			adc	#> AREA_INFOBOX_TW
			sta	r11H

			jsr	prntFileTime

::exit			rts

;*** Jahr/Monat/Tag ausgeben.
:prntDateNum		php
			jsr	prntSetDecimal
			plp
			bcc	:exit
			lda	#"/"
			jsr	PutChar
::exit			rts

;*** Uhrzeit ausgeben.
if LANG = LANG_DE
:prntFileTime		lda	tempDirEntry +26
			bne	:1
			lda	#12
::1			sta	r0L

			lda	#SET_RIGHTJUST! SET_SUPRESS  ! 12
			jsr	prntDecimal

			lda	#"."
			jsr	PutChar

			lda	tempDirEntry +27
			pha

			cmp	#9
			beq	:2
			bcs	:3

::2			lda	#"0"
			jsr	PutChar

::3			pla
endif

;*** Zahl im Akku linksbündig ausgeben.
:prntSetDecimal		sta	r0L
			lda	#SET_LEFTJUST ! SET_SUPRESS ! 16

;*** Zahl 0-255 in r0 links-/rechtsbündig ausgeben.
;Übergabe: AKKU = Formatierung für PutDecimal.
:prntDecimal		ldy	#$00
			sty	r0H
			jmp	PutDecimal

;*** Uhrzeit ausgeben.
if LANG = LANG_EN
:prntFileTime		lda	tempDirEntry +26
			ldy	#1
			tax
			sec
			sbc	#12
			bpl	:1
			ldy	#0
			txa
::1			bne	:2
			lda	#12
::2			sta	r0L

			tya
			pha

			lda	#SET_RIGHTJUST ! SET_SUPRESS ! 12
			jsr	prntDecimal

			lda	#":"
			jsr	PutChar

			lda	r11H
			pha
			lda	r11L
			pha

			lda	tempDirEntry +27
			pha
			cmp	#10
			bcs	:3

			lda	#"0"
			jsr	PutChar

::3			pla
			jsr	prntSetDecimal

			pla
			clc
			adc	#< 16
			sta	r11L
			pla
			adc	#> 16
			sta	r11H

			ldx	#> txAM
			ldy	#< txAM
			pla
			beq	:4

			ldx	#> txPM
			ldy	#< txPM

::4			tya
			jmp	putStringAX
endif

;*** Dateigröße linksbündig ausgeben.
:prntLJustFSize		lda	#SET_LEFTJUST ! SET_SUPRESS

;*** Dateigröße ausgeben.
;Übergabe: AKKU = Formatierung für PutDecimal.
:prntFileSize		pha

			lda	tempDirEntry +28
			sta	r0L
			lda	tempDirEntry +29
			lsr
			ror	r0L
			lsr
			ror	r0L
			sta	r0H			;Größe < 1Kb = 0?
			ora	r0L
			bne	:1

			lda	#$01			;Größe korrigieren.
			sta	r0L

::1			pla
			jsr	PutDecimal		;Größe ausgeben.

			lda	#"K"
			jmp	PutChar

;*** Schreibschutz-Status.
if LANG = LANG_DE
:txWrProt		b "schreibgeschützt",NULL
endif
if LANG = LANG_EN
:txWrProt		b "Write Protect",NULL
endif

;*** Überschriften für Dateiinfo.
if LANG = LANG_DE
:txInfoDisk		b "Diskette:",NULL
:txInfoType		b "Typ:",NULL
:txInfoClass		b "Klasse:",NULL
:txInfoStruct		b "Struktur:",NULL
:txInfoSize		b "Größe:",NULL
:txInfoUpdated		b "geändert:",NULL
:txInfoAuthor		b "Autor:",NULL
endif
if LANG = LANG_EN
:txInfoDisk		b "disk:",NULL
:txInfoType		b "type:",NULL
:txInfoClass		b "class:",NULL
:txInfoStruct		b "structure:",NULL
:txInfoSize		b "size:",NULL
:txInfoUpdated		b "modified:",NULL
:txInfoAuthor		b "author:",NULL
endif

;*** Dateistrukturen.
if LANG = LANG_DE
:txStructSEQ		b "SEQUENTIELL",NULL
:txStructVLIR		b "VLIR",NULL
endif
if LANG = LANG_EN
:txStructSEQ		b "SEQUENTIAL",NULL
:txStructVLIR		b "VLIR",NULL
endif

;*** Infotext-Flag.
:flagInfoText		b $00				;$ff = GEOS-Datei mit Infotext.

;Endadresse VLIR-Modul testen:
			g vlirModEnd
