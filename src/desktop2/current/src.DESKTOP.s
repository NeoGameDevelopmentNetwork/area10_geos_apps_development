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
; V0.2 - Added zpage label to fix code.
;        Added application icon.
;        Renamed menu labels.
;
; V0.3 - Source code analysis complete.
;
; V0.4 - Split code into smaller files.
;
; V0.5 - Added english translation.
;
; V1.0 - Updated to V2.1.
;
; Note: Start DESKTOP from drive A:/B:!
;       No support for drive C:/D:!
;       CMD/NativeMode not supported!
;
if .p
			t "TopSym"
;			t "TopMac"
			t "SymTab.ext"
			t "lang.DESKTOP.ext"

;-- Build-Optionen:
;
; Ungültige Startdisketten "löschen".
:EN_KILLSYS  = FALSE
;
; GEOS-Ser.Nr. auf Programmdisk schreiben.
:EN_WRSERNUM = FALSE
endif

;			n "DESK TOP"
			n "obj.DeskTop"
			a "Brian Dougherty",NULL
			o DTOP_BASE
			p MainInit
			z $00
			f SYSTEM

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			c "deskTopDE   V2.1",NULL
			h "deskTop verwaltet Ihre Disketten und Dateien."
endif
if LANG = LANG_EN
			c "deskTopEN   V2.1",NULL
			h "Use the deskTop to manage and manipulate your files."
endif

;*** Disk-/FileCopy-Routinen.
			t "src.DTop.JobCopy"

;*** Laufwerksroutinen.
			t "src.DTop.DiskDrv"

;*** DiskCopy-Hauptroutine.
			t "src.DTop.DCopy"

;*** BAM-Routinen Teil #1.
			t "src.DTop.BAM#1"

;*** Block von Disk nach ":diskBlkBuf" lesen.
;Übergabe: r5 = Verzeichniseintrag.
;          Y  = Zeiger auf Tr/Se (z.B. $13 = Infoblock).
.getDiskBlock_r5	lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H

;*** Block von Disk nach ":diskBlkBuf" lesen.
;Übergabe: r1L/r1H = Track/Sektor.
.getDiskBlock		jsr	r4_diskBlkBuf
			jmp	GetBlock

;*** Block in ":diskBlkBuf" auf Disk schreiben.
;Übergabe: r1L/r1H = Track/Sektor.
:putDiskBlock		jsr	r4_diskBlkBuf
			jmp	PutBlock

;*** BAM-Routinen Teil #2.
			t "src.DTop.BAM#2"

;*** FileCopy-Hauptroutine.
			t "src.DTop.FCopy"

;*** RecoverVector auf eigene Routine umleiten.
.setUserRecVec		lda	RecoverVector +1
			sta	bufRecoverVec +1
			lda	RecoverVector +0
			sta	bufRecoverVec +0
			lda	#> clearRecArea
			sta	RecoverVector +1
			lda	#< clearRecArea
			sta	RecoverVector +0
			rts

;*** RecoverVector zurücksetzen.
.resetRecVec		lda	bufRecoverVec +1
			sta	RecoverVector +1
			lda	bufRecoverVec +0
			sta	RecoverVector +0
			rts

;*** Bereich löschen.
:clearRecArea		lda	#ST_WR_FORE
			sta	dispBufferOn
			jsr	setPattern0
			jmp	Rectangle

;*** BAM für Laufwerkswechsel speichern.
			t "src.DTop.SDrvBAM"

;*** Test auf Diskette im neuen Laufwerk.
;Übergabe: A = Laufwerksadresse.
:setDrvDkChanged	jsr	setNewDevice

;*** Test ob Disk im Laufwerk gewechselt.
;Übergabe: curDrive = Laufwerk.
.testDiskChanged	jsr	chkCurDrvDkNm
			beq	exit0			;Keine Disk, Ende...

;*** Test ob Ziel-Disk im Ziel-Laufwerk liegt.
;Wird nur bei FCopy aufgerufen.
:testErrOtherDisk	jsr	testDkNmInDrive

			php
			ldx	#NO_ERROR
			plp				;Diskette gewechselt?
			bne	:err			; => Ja, InsertDisk.

			ldy	#$ff			;Diskette gültig.
			sty	flagDiskRdy
			rts

::err			jsr	r5_buf_TempName

			ldx	#r1L			;Diskname kopieren.
			ldy	#r5L
			lda	#18
			jsr	copyNameA0_a

			lda	curDrive		;Laufwerks-Nr.
			clc				;definieren.
			adc	#"A" -8
			sta	dbtxDriveAdr

			lda	r1H			;Zeiger auf
			pha				;Diskname sichern.
			lda	r1L
			pha
			ldx	#> dbox_InsertDisk
			lda	#< dbox_InsertDisk
			jsr	openDlgBox		;Dialogbox öffnen.
			pla
			sta	r1L
			pla				;Zeiger auf Diskname
			sta	r1H			;zurückschreiben.

			ldx	#CANCEL_ERR
			lda	r0L
			cmp	#CANCEL			;Abbruch? => Ende.
			bne	testErrOtherDisk

;*** Abbruch, DeskTop neu starten.
:restartDeskTop		lda	flagBootDT		;DeskTop zerstört?
			beq	clrScrnEnterDT

			lda	#> MainInit		;Neustart DeskTop.
			sta	r7H
			lda	#< MainInit
			sta	r7L
			lda	#$00
			sta	r0L
			jmp	StartAppl

;*** Bildschirm löschen, zurück zum DeskTop.
.clrScrnEnterDT		jsr	clearScreen		;Zurück zu GEOS.
			jmp	EnterDeskTop

;*** Aktuelles Laufwerk öffnen.
:openCurDkDrive		lda	a6H
			jmp	setNewDevice

;*** Diskette im aktuellen Laufwerk gewechselt?
:testDkNmCurDrive	jsr	chkCurDrvDkNm

;*** Diskette im Laufwerk gewechselt?
:testDkNmInDrive	lda	r1H
			pha
			lda	r1L
			pha
			jsr	OpenDisk
			pla
			sta	r1L
			pla
			sta	r1H

			jsr	exitOnDiskErr

			ldx	#r5L
			ldy	#r1L
			lda	#18
			jmp	CmpFString

;*** Dialogbox: Diskette einlegen.
:dbox_InsertDisk	b %10000001
			b DBTXTSTR,$10,$10
			w dbtxInsertDisk
			b DBTXTSTR,$10,$20
			w buf_TempName
			b DBTXTSTR,$10,$30
			w dbtxIDskInDrv
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

;*** Dateiname kopieren.
.copyNameA0_16		lda	#16

;*** Diskname kopieren.
;Übergabe: AKKU = Länge (18Z).
:copyNameA0_a		stx	:1 +1
			sty	:2 +1
			sty	:4 +1
			sta	r15L

			ldy	#$00
::1			lda	(zpage),y
::2			sta	(zpage),y
			cmp	#$a0
			beq	:3
			sty	r15H
::3			iny
			dec	r15L
			bne	:1

			ldy	r15H
			iny
			lda	#NULL
::4			sta	(zpage),y
			rts

;*** Laufwerk auf 1571 testen.
:is1571_curDrv		ldy	curDrive
:is1571_yReg		lda	driveType -8,y
			and	#ST_DMODES
			cmp	#Drv1571
			rts

;*** Füllmuster 0/2 setzen.
.setPattern0		lda	#PAT_DESKPAD
			b $2c
:setPattern2		lda	#PAT_DESKTOP
			jmp	SetPattern

;*** Dialogbox anzeigen.
			t "src.DTop.DlgBox"

;*** Bildschirm für LdApplic/GetFile löschen.
:resetScreen		lda	#ST_WR_FORE!ST_WR_BACK
			sta	dispBufferOn

;*** Bildschirm für GEOS löschen.
.clearScreen		lda	r9H
			pha
			lda	r9L
			pha

			jsr	drawScrnPadCol
			jsr	i_GraphicsString
			b NEWPATTERN
			b PAT_DESKTOP
			b MOVEPENTO
			w $0000
			b $00
			b RECTANGLETO
			w $013f
			b $c7
			b NULL

			pla
			sta	r9L
			pla
			sta	r9H
			rts

;*** Auto GEOS V2 testen.
;Rückgabe: C-Flag=1: GEOS >= V2.0
;          C-Flag=0: GEOS V1.x
:isGEOS_V2		pha
			lda	version
			cmp	#$20
			pla
			rts

;*** Bei Fehler zurück zur aufrufenden Routine.
.exitOnDiskErr		txa
			beq	:ok
			pla
			pla
::ok			rts

;*** 2 Byte zu r10 addieren.
:add_2_r10		clc
			lda	#$02
			adc	r10L
			sta	r10L
			bcc	:1
			inc	r10H
::1			rts

;*** Zeiger in r4 auf ":diskBlkBuf" setzen.
:r4_diskBlkBuf		lda	#> diskBlkBuf
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L
			rts

;*** Zeiger in r5/r6 setzen.
.r5_r6_TempName		jsr	r6_buf_TempStr2

;*** Zeiger in r5 auf ":buf_TempName" setzen.
.r5_buf_TempName	lda	#> buf_TempName
			sta	r5H
			lda	#< buf_TempName
			sta	r5L
			rts

;*** Zeiger in r6 auf ":buf_TempStr2" setzen.
:r6_buf_TempStr2	lda	#> buf_TempStr2
			sta	r6H
			lda	#< buf_TempStr2
			sta	r6L
			rts

;*** Zeiger in r6 auf ":buf_TempName" setzen.
:r6_buf_TempName	lda	#> buf_TempName
			sta	r6H
			lda	#< buf_TempName
			sta	r6L
			rts

;*** Zeiger in r10 auf DeskTop-Klasse setzen.
:r10_classDTop		lda	#> classDeskTop
			sta	r10H
			lda	#< classDeskTop
			sta	r10L
			rts

;*** Fehlermeldung anzeigen.
			t "src.DTop.ErrBox"

;*** Bildschirmfarben zeichnen.
			t "src.DTop.ScrnCol"

;*** GEOS-Klasse DeskTop-Systemdatei.
if LANG = LANG_DE
:classDeskTop		b "deskTopDE   V2.1",NULL
endif
if LANG = LANG_EN
:classDeskTop		b "deskTopEN   V2.1",NULL
endif

;*** Texte für Fehlermeldungen, Teil #1.
			t "src.DTop.TxErr#1"

;*** System-Icons, Teil #1.
			t "src.DTop.Icons#1"

;*** Zeichensatz für Icon-Titel.
if LANG = LANG_DE
			t "src.DTop.Font_DE"
endif
if LANG = LANG_EN
			t "src.DTop.Font_EN"
endif

;*** Systemtexte, Teil #1.
			t "src.DTop.Text#1"

;*** Systemdateien.
;Name mit $a0 auf 16Z. aufgefüllt.
:fileNamePref		b "Preferences",$a0,$a0,$a0,$a0,$a0
:fileNamePadCol		b "Pad Color Pref",$a0,$a0

;*** Systemtexte, Teil #2.
			t "src.DTop.Text#2"

;*** GEOS-Dateitypen.
			t "src.DTop.TxGType"

;*** Texte für Fehlermeldungen, Teil #2.
			t "src.DTop.TxErr#2"

;*** Systemtexte, Teil #3.
			t "src.DTop.Text#3"

;*** Name DeskTop-Systemdatei.
.nameDESKTOP		b "DESK TOP",NULL

;*** Systemtexte, Teil #4.
			t "src.DTop.Text#4"

;*** GEOS-Menü, Teil #1.
			t "src.DTop.Menu#1"

;*** Systemtexte, Teil #5.
			t "src.DTop.Text#5"

;*** Fehler ausgeben, Diskette testen.
.errTestCurDkRdy	jsr	openErrBox1Line

;*** Ist Diskette im Laufwerk gültig?
;Übergabe: X = Fehlercode.
.testCurDiskReady	lda	diskOpenFlg
			beq	testErrCloseDisk

			jsr	testDiskChanged

			jsr	getIconNumCurDrv
			jsr	clrDeskPadIcon

			jsr	reopenCurDisk
:testErrCloseDisk	txa
			beq	:ok

			jsr	openErrBox1Line
			jsr	closeCurDisk

::ok			rts

;*** Neue Diskette im Laufwerk öffnen.
.openNewDisk		jsr	clrSlctFileData
			jsr	initNewDisk
			jsr	exitOnDiskErr
			sta	a0L
			lda	#$00			;Papierkorb leer.
			sta	a8H

			lda	isGEOS
			bne	initCurDiskData

			ldx	#> dbox_ConvertGEOS
			lda	#< dbox_ConvertGEOS
			jsr	openDlgBox
			cmp	#YES
			bne	initCurDiskData

			jsr	GetDirHead
			jsr	exitOnDiskErr

			jsr	cbmBootSek
			cpx	#BAD_BAM
			beq	:1
			jsr	exitOnDiskErr

			jsr	PutDirHead
			jsr	exitOnDiskErr

::1			jsr	SetGEOSDisk
			txa
			beq	openNewDisk
			rts

;*** Aktuelle Diskette erneut öffnen.
.reopenCurDisk		jsr	initNewDisk
			txa
			bne	exitOpenDisk

;*** Disketten-Informationen einlesen.
:initCurDiskData	jsr	disableFileDnD
if EN_WRSERNUM = TRUE
			jsr	writeSerialGEOS
endif
			jsr	openDeskPad
			txa
			bne	:err
			jsr	applyPrefData
			jsr	drawCurDTopScrn

			lda	PrntFilename
			bne	:1
			ldx	vec1stPrint +1
			beq	:1

			lda	#ICON_PRINT
			jsr	prepDrawIconNm
			ldx	vec1stPrint +1
			ldy	vec1stPrint +0
			lda	#> PrntFilename
			sta	r3H
			lda	#< PrntFilename
			jsr	copyDevName
			jsr	setNewPrinter

::1			jsr	testLoadInputDev
			jsr	restartProcClock

			ldx	#NO_ERROR
::err			lda	#$ff
			sta	diskOpenFlg
:exitOpenDisk		rts

;*** Nach Eingabetreiber suchen.
.testLoadInputDev	lda	inputDevName
			bne	:exit

			ldx	vec1stInput +1
			beq	:exit

			ldy	vec1stInput +0
			lda	#> inputDevName
			sta	r3H
			lda	#< inputDevName
			jsr	copyDevName
			jsr	setNewInputDev

::exit			rts

;*** Gerätename kopieren.
;Übergabe: a/r3H = Zeiger auf Ablagebereich.
;          X,Y   = Zeiger auf Gerätename.
:copyDevName		sta	r3L
			stx	r2H
			sty	r2L
			ldx	#r2L
			ldy	#r3L
			jmp	copyNameA0_16

;*** GEOS-Menü (für DAs) zurücksetzen und Diskette öffnen.
.initNewDisk		jsr	resetMenuGEOS
			jmp	OpenDisk

;*** Größe GEOS-Menü zurücksetzen.
:resetMenuGEOS		lda	#$04

;*** Größe GEOS-Menü aktualisieren.
;Übergabe: A = Anzahl Einträge
:updateMenuGEOS		sta	r0L
			ora	#VERTICAL
			sta	dm_geos_count

			lda	#14
			sta	r1L
			ldy	#r0L
			ldx	#r1L
			jsr	BBMult

			clc				;Hauptmenü addieren.
			adc	#12
			clc				;Untere Kante auf
			adc	#$07			;ganzes Card setzen.
			and	#%11111000
			sec
			sbc	#$01
			sta	dm_geos_y1
			clc
			adc	#$02
			sta	menuDataGEOS +3
			rts

;*** Dialogbox: Disk nach GEOS konvertieren?
:dbox_ConvertGEOS	b %10000001
			b DBTXTSTR,$0c,$20
			w textConvDisk1
			b DBTXTSTR,$0c,$30
			w textConvDisk2
			b YES     ,$01,$48
			b NO      ,$11,$48
			b NULL

;*** GEOS-Seriennummer auf Disk schreiben.
if EN_WRSERNUM = TRUE
			t "src.DTop.SerGEOS"
endif

;*** DeskPad zeichnen.
			t "src.DTop.DeskPad"

;*** Datei-Icons der aktuellen Seite einlesen.
.loadIconsCurPage	lda	#< dirDiskBuf +2
			sta	r5L
			lda	#> dirDiskBuf +2
			clc
			adc	a0L
			sta	r5H

			lda	#8			;Max. 8 Icons.
			sta	r8L

			lda	#> tabFIconBitmaps
			sta	r13H
			lda	#< tabFIconBitmaps
			sta	r13L

::next			ldy	#$00
			lda	(r5L),y			;Datei vorhanden?
			beq	:1			; => Nein, weiter...
			ldy	#$16
			lda	(r5L),y			;GEOS-Datei?
			beq	:1			; => Nein, weiter...

			ldy	#$13			;Infoblock einlesen.
			jsr	getDiskBlock_r5
			jsr	exitOnDiskErr

			ldx	#r4L			;68 Bytes in
			ldy	#r13L			;Bitmap-Speicher
			lda	#68			;kopieren.
			jsr	CopyFString

::1			clc				;Zeiger auf
			lda	#68			;nächstes Icon.
			adc	r13L
			sta	r13L
			bcc	:2
			inc	r13H

::2			clc				;Zeiger auf nächsten
			lda	#$20			;Verzeichniseintrag.
			adc	r5L
			sta	r5L
			bcc	:3
			inc	r5H

::3			dec	r8L			;Seite eingelesen?
			bne	:next			; => Nein, weiter...

			ldx	#NO_ERROR
			rts

;*** Voreinstellungen anwenden.
			t "src.DTop.PadPref"

;*** Systemdateien löschen.
if EN_KILLSYS = TRUE
			t "src.DTop.KillSys"
endif

;*** CBM-Bootsektor retten.
			t "src.DTop.CBMBOOT"

;*** Sektor in BAM belegen.
.allocCurBlock		lda	r1H
			sta	r6H
			lda	r1L
			sta	r6L
			lda	dvTypSource
			cmp	#Drv1571
			bcc	:alloc_1541
::alloc_1571_1581	jmp	AllocateBlock

::alloc_1541		jsr	FindBAMBit
			beq	:err
			lda	r8H
			eor	#$ff
			and	curDirHead,x
			sta	curDirHead,x
			ldx	r7H
			dec	curDirHead,x
			ldx	#NO_ERROR
			rts
::err			ldx	#BAD_BAM
			rts

;*** Diskette schließen.
:menuDiskClose		jsr	DoPreviousMenu
:keybDiskClose		lda	diskOpenFlg
			beq	exit1

;*** Aktuelle Disk schließen.
.closeCurDisk		jsr	unselectIcons

			lda	#$02			;Scroll/Close-Icon
			sta	r12L			;aus Tabelle löschen.

			lda	#ICON_PGNAV
			jsr	iconTabRemove
			jsr	drawEmptyDeskPad
			jsr	getIconNumCurDrv
			jsr	clrDeskPadIcon

			lda	#NULL
			sta	bufOpenDiskNm
			jsr	resetMenuGEOS

;*** Laufwerk-Info zurücksetzen.
.resetDriveData		ldx	#r1L			;Zeiger auf Diskname.
			jsr	setVecDkNmBuf

			lda	#$00			;Diskname löschen.
			tay
			sta	(r1L),y

			ldy	curDrive		;Zeiger auf
			ldx	#r0L			;Laufwerkstitel.
			jsr	setVecDrvTitle

			lda	#%00000000		;Icon-Nummer für das
			sta	r1L			;aktuelle Laufwerk.
			jsr	getIconNumCurDrv

			jsr	updDriveIcons

			jsr	clearTrashName

			ldx	#NO_ERROR
			stx	a8H			;Papierkorb leer.
			stx	diskOpenFlg		;Disk geschlossen.
:exit1			rts

;*** Laufwerkicons anzeigen.
			t "src.DTop.DrvIcon"

;*** Laufwerk A/B öffnen.
:func_OpenDrvAB		lda	curDrive
			sta	a6H

			bit	a2H			;Datei-DnD aktiv?
			bvc	slctNewDrive		; => Nein, weiter...

			ldx	#> batchJobCopyFile
			lda	#< batchJobCopyFile
			jsr	execBatchJob

			jsr	chkBIconOpenDkNm
			bne	:exit

			jmp	reopenCurDisk

::exit			rts

;*** Batch: Dateien kopieren.
:batchJobCopyFile	jsr	getFTypeGEOS
			cmp	#SYSTEM_BOOT
			bne	:1
			jmp	doErrStartFile

::1			jsr	testDnDTarget
			jsr	chkErrReopenDisk

			jsr	findFirstFSlct

			lda	a2L
			cmp	curDrive
			bne	:2

			jsr	removeJobIcon
			jmp	testCurDiskReady

::2			jsr	testDkNmCurDrive
			beq	:3

			lda	#$00			;Diskette ungültig.
			sta	flagDiskRdy
			jsr	testDiskChanged

::3			jsr	loadDirectory
			jsr	drawDeskPadICol

			jsr	chkErrRestartDT
			jmp	unselectJobIcon

;*** Neues Laufwerk setzen.
:slctNewDrive		lda	r0L
:slctOtherDrive		jsr	clrDeskPadIcon
			jsr	convIconNumDrv
			sta	a6H

			ldx	diskOpenFlg
			beq	:1
			cmp	curDrive
			beq	:1

			jsr	getIconNumCurDrv
			jsr	invertIcon

::1			jsr	openCurDkDrive
			jmp	testSwapDrives

;*** Laufwerk C mit A/B tauschen.
:func_SwapDriveC	lda	flagLockMseDrv
			beq	:1
			jmp	mseDvUnlock

::1			bit	a2H			;Datei-DnD aktiv?
			bvc	:mseDvLock		; => Nein, weiter...
			jmp	unselectIcons

::mseDvLock		jsr	unselectIcons

;--- DnD-Icon für Laufwerkstausch.
			lda	#ICON_DRVC		;Icon Drive C.
			jsr	setPicDnDSpr

;--- Mauszeiger begrenzen.
			lda	#>AREA_DRIVES_X0
			sta	mouseLeft +1
			lda	#<AREA_DRIVES_X0
			sta	mouseLeft +0
			lda	#AREA_DRIVES_Y1
			sta	mouseBottom
			lda	#AREA_DRIVES_Y0
			sta	mouseTop

			lda	#$ff
			sta	flagLockMseDrv
			rts

;*** Laufwerk A öffnen.
:keybOpenDrvA		lda	#8			;Laufwerk #9 öffnen.
			bne	openDriveAB

;*** Laufwerk B öffnen.
:keybOpenDrvB		ldy	numDrives
			dey				;Mehr als 1 Laufwerk?
			bne	:1			; => Ja, weiter...
			rts

::1			lda	#9			;Laufwerk #9 öffnen.

;*** Laufwerk A/B öffnen.
;Übergabe: A = Laufwerksadresse 8/9.
:openDriveAB		pha
			jsr	unselectIcons
			pla
			jsr	getIconNumDrive
			jmp	slctOtherDrive

;*** Ablage auf Laufwerks-Icon testen.
;Übergabe: r0L = Nr. Laufwerks-Icon (ICON_DRVA, ICON_DRVB)
:testDnDTarget		lda	curDrive		;Geöffnetes Laufwerk.
			sta	a6H

			lda	a3L			;Gewähltes Icon.
			sta	a3H			;Icon für FileCopy.

			lda	r0L
			jsr	convIconNumDrv
			sta	a2L			;Laufwerk 8/9.
			tay
			ldx	#r1L			;Zeiger auf Diskname.
			jsr	setVecDkNmBuf_A

			lda	numDrives
			cmp	#2			;Mehr als ein Lfwk.?
			bcc	:1			; => Nein, weiter...

			tya				;Zuerst das andere
			eor	#%00000001		;Laufwerk testen.
			tay

::1			sty	a1H			;Quell-Laufwerk.

			ldy	#$00			;Ist Diskette im
			lda	(r1L),y			;Ziel-Lfwk. geöffnet?
			beq	:err			; => Nein, Abbruch...

			lda	a3L			;Ist Ziel-Diskette =
			ldx	#r2L			;aktuelle Diskette?
			jsr	getCurIconDkNm
			ldy	#r1L
			lda	#18
			jsr	CmpFString
			beq	:err			; => Ja, Abbruch...

			lda	r2H			;Source-Diskette.
			sta	nmDkSrc +1
			lda	r2L
			sta	nmDkSrc +0

			lda	r1H			;Target-Diskette.
			sta	nmDkTgt +1
			lda	r1L
			sta	nmDkTgt +0

			jsr	copyBuf2DirHead
			txa				;BAM-Fehler?
			bne	:exit			; => Ja, Abbruch...

;			lda	#$00
			jsr	checkFileExist
			txa
			bne	:exit
			sta	a0H			;Directory-Anfang.

;			lda	#$00			;Modus: Kopieren.
			jsr	doJobCopyFile
			txa				;Diskfehler?
			bne	:exit			; => Ja, Abbruch...

::ok			ldx	#$00			;DnD ausgeführt.
			beq	:exit

::err			ldx	#$ff			;Nicht ausgeführt.

::exit			txa
			pha
			jsr	openCurDkDrive
			pla
			tax
			rts

;*** Zeiger auf Puffer für Diskname setzen.
:setVecDkNmBuf		lda	curDrive
:setVecDkNmBuf_A	cmp	#8
			beq	:drive_a
			cmp	#9
			beq	:drive_b

::drive_c		lda	#< bufDiskNmC
			sta	zpage +0,x
			lda	#> bufDiskNmC
			sta	zpage +1,x
			rts

::drive_b		lda	#< bufDiskNmB
			sta	zpage +0,x
			lda	#> bufDiskNmB
			sta	zpage +1,x
			rts

::drive_a		lda	#< bufDiskNmA
			sta	zpage +0,x
			lda	#> bufDiskNmA
			sta	zpage +1,x
			rts

;*** Zeiger Name der geöffneten Diskette setzen.
.setVecOpenDkNm		lda	#< bufOpenDiskNm
			sta	zpage +0,x
			lda	#> bufOpenDiskNm
			sta	zpage +1,x
			rts

;*** Disknamen in Laufwerk A (und B) unverändert?
:testSrcTgtDkRdy	lda	numDrives
			cmp	#2
			bcc	:drv_0

::drv_1			jsr	swapCurDrive
			jsr	testDiskChanged
			txa
			pha
			jsr	swapCurDrive
			pla
			bne	:exit

::drv_0			jsr	testDiskChanged

::exit			rts

;*** Name der Diskette im aktuellen Laufwerk testen.
;Übergabe: curDrive = Laufwerk.
;Rückgabe: Z-Flag=1 : Kein Name definiert.
;          r1       = Zeiger auf Puffer für Diskname.
:chkCurDrvDkNm		ldx	#r1L
			jsr	setVecDkNmBuf
			ldx	#$00
			ldy	#$00
			lda	(r1L),y
			rts

;*** Verzeichnis analysieren.
			t "src.DTop.DirTest"

;*** Dateityp "TEMPORARY" löschen.
:delTempFile		jsr	FreeFile		;Datei freigeben.

			ldy	#$00			;Eintrag löschen.
			tya
			sta	(r9L),y

			lda	r9H			;Directory schreiben.
			cmp	#> buf_diskSek3
			bne	:1
			jmp	updateBorderBlk

::1			sec
			sbc	#> dirDiskBuf
			jmp	updateDirBlock

;*** Verzeichnis einlesen.
			t "src.DTop.DirLOAD"

;*** Verzeichnis aktualisieren.
			t "src.DTop.DirSAVE"

;*** GEOS-System aktualisieren.
			t "src.DTop.UpdGEOS"

;*** Zeiger auf Laufwerksname setzen.
;Übergabe: Y = Laufwerk #8-10
;          X = Zeiger auf ZP-Register
:setVecDrvTitle		tya
			pha
			sec
			sbc	#8
			tay
			lda	tabVecDrvNmH,y
			sta	zpage +1,x
			lda	tabVecDrvNmL,y
			sta	zpage +0,x
			pla
			tay
			rts

;*** Zeiger auf Laufwerkstitel.
:tabVecDrvNmH		b > textDriveA
			b > textDriveB
			b > textDriveC
:tabVecDrvNmL		b < textDriveA
			b < textDriveB
			b < textDriveC

;*** DeskTop-Informationen aktualisieren.
			t "src.DTop.DeskUpd"

;*** Datei öffnen.
:menuFileOpen		jsr	DoPreviousMenu
:keybFileOpen		lda	curDrive
			sta	a6H			;Aktuelles Laufwerk.

			bit	a2H			;Dateiwahl aktiv?
			bpl	exit3			; => Nein, Ende...

			lda	a6L			;Mehr als eine Datei?
			beq	:1			; => Nein, weiter...

			jmp	doErrMultiFile

::1			jsr	findLastFSlct

			lda	a4L			;Icon auf akt. Disk?
			bne	:2			; => Ja, weiter...

			jsr	doErrFOtherDk
			jmp	unselectJobIcon

::2			jsr	testSrcTgtDkRdy

			lda	#$ff			;Laufwerk bereit.
			sta	flagTestTgtDrv

			lda	numDrives		;Anzahl Laufwerke
			pha				;zwischenspeichern.

			lda	flagDriverReady
			beq	:3			; => REU-Treiber.

;--- TurboDOS Laufwerk 9 abschalten.
;Nur DeskTop V2 kann zwei verschiedene
;Laufwerke ohne REU verwalten.
;Bevor eine Anwendung geöffnet wird
;Laufwerk 9 abschalten.
			jsr	swapCurDrive
			jsr	PurgeTurbo
			jsr	swapCurDrive

;--- Nur ein Lafwerk.
;Keine REVU -> Max. ein Laufwerk.
			lda	#1			;Nur ein Laufwerk.
			sta	numDrives

::3			jsr	getFTypeGEOS

			jsr	openFileSelected

;--- Hinweis:
;Rückkehr nur bei DA oder wenn die
;Datei nicht geöffnet werden kann.
			pla				;Anzahl Laufwerke
			sta	numDrives		;zurücksetzen.

;--- Laufwerke teste?
			lda	flagTestTgtDrv
			beq	exit3			; => Nein, Ende...

			jsr	testSrcTgtDkRdy
			jsr	chkErrRestartDT

:exit3			rts

:flagTestTgtDrv		b $00				;$ff = Laufwerk testen.

;*** Gewählte Datei öffnen.
			t "src.DTop.FOpen"

;*** Start für max. Kopierspeicher.
:APPRAM_2A

;*** Anwendung/Systemdatei suchen.
			t "src.DTop.FindApp"

;*** Code für Auswahl-Liste erzeugen.
;Übergabe: A = 0 - 7: Datei-Icon.
;              8 -15: Border-Icon.
;
;Aufbau Code für die Auswahl-Liste:
;Bit %7-5: Eintrag 0-7 in Dir-Block.
;Bit %4-0: Seite, 31 = Borderblock.
;
:defTabFSlctCode	asl
			asl
			asl
			asl
			asl
			bcc	:1
			ora	#%00011111		;Datei / Border.
			bne	:2
::1			ora	a0L			;Datei / Verzeichnis.
::2			rts

;*** Offset gewählte Datei in dirDiskBuf berechnen.
;Übergabe: X = Zeiger auf Tabelle mit gewählten Dateien.
:getOffSlctTabX		lda	tabSlctFiles,x

;*** Offset für Datei in dirDiskBuf berechnen.
;Übergabe: A = Codierter Zeiger auf dirDiskBuf:
;              Bit %7-5: = High-Nibble:
;                          Lowbyte Adr. dirDiskBuf
;              Bit %4-0: = Low-Nibble:
;                          Directory-Seite max. 0 bis 30.
;                          31 = Dateien im Border.
;Rückgabe: Y = Seitennummer, $1f = Border.
;          A = Icon-Nr. 0-15 in Tabelle.
:getOffSlctFile		pha
			and	#%00011111		;Seitennummer.
			tay
			pla
			lsr				;Low-Byte Adresse
			lsr				;innerhalb Seite.
			lsr
			lsr
			lsr
			cpy	#%00011111		;Datei / Border?
			bne	:1			; => Nein, weiter...
			clc
			adc	#ICON_BORDER
::1			rts

;*** Verzeichniseintrag für gewählte Datei suchen.
:findFirstFSlct		ldx	batchStatus		;Das Flag ist hier
			b $2c				;immer #0=Auswahl#1.

;*** Verzeichniseintrag für zuletzt gewählte Datei suchen.
.findLastFSlct		ldx	a6L			;Letzte Auswahl.
:findFSlctEntryX	lda	r0H			;Datei im X-Register.
			pha
			lda	r0L
			pha

			txa
			pha

			jsr	getOffSlctTabX
			sta	a3L
			cmp	#ICON_BORDER
			bcs	:found

;--- Deskpad-Seite für gesuchte Datei öffnen.
			tya				;Seitennummer.
			jsr	openNewPadPage
			cpx	#$ff			;Seite gültig?
			bne	:found			; => Ja, weiter...

;--- Seite nicht gefunden, Abbruch...
			jmp	restartDeskTop

::found			lda	a3L
			jsr	chkCIconOpenDkNm
			stx	a4L			;$ff = Icon auf Disk.

			ldx	#r3L
			jsr	setVecIcon2File

			lda	r3H			;Zeiger auf
			sta	a5H			;Verzeichniseintrag.
			lda	r3L
			sta	a5L

			pla
			tax

			pla
			sta	r0L
			pla
			sta	r0H
			rts

;*** Datei-Icon oder Border-Icon angeklickt.
:func_ClkOnFile		jsr	testCurViewMode
			bcc	:exit			; => Text-Modus...

			lda	diskOpenFlg
			beq	:exit
			bit	a2H			;Datei-Modus:
			bpl	:select			; => Keine Dateiwahl.
			bvc	:add_slct		; => Kein Datei-DnD.
			jmp	u_otherPressVec

::add_slct		lda	r0L
			jsr	getSlctIconEntry
			cpx	#$ff			;Border-Icon?
			bne	:border			; => Ja, weiter...

			jsr	chkSameFileSlct
			beq	:select

;--- Mehrfach-Auswahl mit C=-Taste?
			jsr	chkMseCBMkey
			beq	:select

;--- Nein, Auswahl aufheben.
			jsr	undoFileSelect
::select		jmp	doJobSelectFile

::border		lda	a3L
			pha
			jsr	findFSlctEntryX
			pla
			sec
			sbc	a3L			;r14L = $00:
			sta	r14L			;Gleiche Datei.
			jsr	chkMseCBMkey
			bne	:open_or_dnd
::unselect		jmp	unselectJobIcon

;--- DnD starten oder Datei öffnen.
::open_or_dnd		ldx	r0H
			beq	:dnd
			ldx	a6L			;Mehr als 1 Datei?
			bne	:dnd			; => Ja, weiter...
			lda	r14L			;Gleiche Datei?
			bne	:unselect		; => Nein...
			jmp	keybFileOpen
::dnd			jmp	setDnDFileIcon
::exit			rts

;*** Wurde Icon aus der gleichen Gruppe gewählt?
;Es können entweder Dateien auf dem Pad
;oder im Border ausgewählt werden.
:chkSameFileSlct	cmp	#ICON_BORDER
			bcs	chkBorderSelect

			lda	a2H
			and	#%00100000
			beq	chkSameFSlctOK

:undoFileSelect		lda	a0L
			pha
			lda	a3L
			pha
			jsr	unselectIcons
			pla
			sta	a3L
			pla
			sta	a0L

			ldx	#$00			;Modus gewechselt.
			rts

:chkBorderSelect	lda	a2H
			and	#%00100000
			beq	undoFileSelect

:chkSameFSlctOK		ldx	#$ff			;Modus unverändert.
			rts

;*** Datei als "ausgewählt" markieren.
;Es können entweder Dateien auf dem Pad
;oder im Border ausgewählt werden.
:doJobSelectFile	lda	a2H
			ldx	r0L
			cpx	#ICON_BORDER
			bcc	:file
::border		ora	#%00100000		;Dateiwahl Border.
			bne	:1
::file			and	#%11011111
::1			sta	a2H

			jsr	disableFileDnD

			bit	a2H			;Dateiwahl aktiv?
			bpl	:2			; => Nein, weiter...
			inc	a6L			;Auswahl +1.
::2			lda	#%10000000		;Dateiwahl aktiv.
			ora	a2H
			sta	a2H

			ldx	a6L
			lda	r0L
			jsr	defTabFSlctCode
			sta	tabSlctFiles,x
			jsr	findFSlctEntryX

			lda	r0L
			jsr	invertIcon

			lda	a3L
			jsr	chkCIconOpenDkNm
			stx	a4L			;$ff = Icon auf Disk.
			jsr	prntStatSlctFile

			ldx	#$00
			rts

;*** Datei-Icon abwählen.
.unselectJobIcon	lda	#$ff
			sta	r3H
			bne	clrSelectedMode

;*** Datei-Icon aus Auswahl entfernen.
.removeJobIcon		lda	#$00
			sta	r3H

;*** Auswahl-Status löschen.
:clrSelectedMode	lda	r0H
			pha
			lda	r0L
			pha
			lda	r1H
			pha
			lda	r1L
			pha

			lda	a3L
			jsr	isIconInSlctTab
			beq	:2

			jsr	disableFileDnD

			lda	r3H
			beq	:1

			jsr	invertCurIcon

::1			jsr	delEntryTabFSlct

::2			pla
			sta	r1L
			pla
			sta	r1H
			pla
			sta	r0L
			pla
			sta	r0H
			ldx	#$00
			rts

;*** Eintrag aus der Auswahl-Liste löschen.
;Übergabe: a6L = Zeiger auf letzte gewählte Datei.
:delEntryTabFSlct	ldx	a6L			;Zähler einlesen.
			stx	r0H

			jsr	chkCurIconSlct

::1			lda	r0H			;Icons abgewählt?
			beq	:done			; => Ja, Ende...
			lda	tabSlctFiles +1,x
			sta	tabSlctFiles +0,x
			inx				;Eintrag löschen.
			cpx	r0H			;Tabelle bearbeitet?
			bcc	:1			; => Nein, weiter...

			dec	batchStatus		;Job bearbeitet.

			dec	a6L			;Alle Dateien in
			lda	a6L			;der Warteschlange
			cmp	#$ff			;bearbeitet?
			bne	:exit			; => Nein, weiter...

;--- Auswahl aufheben.
::done			jsr	clrSlctFileData
::exit			jmp	prntStatSlctFile

;*** Ist Icon ausgewählt?
.isIconInSlctTab	jsr	getSlctIconEntry
			cpx	#$ff
			rts

;*** Ist aktuelles Icon ausgewählt?
:chkCurIconSlct		lda	a3L

;*** Ist Icon ausgewählt?
:getSlctIconEntry	pha

			bit	a2H			;Dateiwahl aktiv?
			bpl	:err			; => Nein, weiter...
			sta	r3L

			ldx	a6L
::search		jsr	getOffSlctTabX
			cmp	#ICON_BORDER
			bcs	:border

			cpy	a0L			;Icon auf akt.Seite?
			bne	:next			; => Nein, weiter...

::border		cmp	r3L			;Gewähltes Icon?
			beq	:found			; => Ja, Ende...
::next			dex
			cpx	#$ff			;Icons durchsucht?
			bne	:search			; => Nein, weiter...

::err			ldx	#$ff			; => Nicht gefunden.
::found			pla
			rts

;*** Alle Icons abwählen.
.unselectIcons		lda	diskOpenFlg
			beq	doneDnDClrData
			lda	r0L
			pha
			lda	#ICON_PAD +16 -1
::1			pha
			jsr	isIconInSlctTab
			beq	:2
			jsr	invertIcon
::2			pla
			sec
			sbc	#$01
			bpl	:1
			jsr	doneDnDClrData
			jsr	prntStatSlctFile
			pla
			sta	r0L
			rts

;*** Datei-DnD beenden.
:doneDnDClrData		jsr	disableFileDnD

;*** Dateiauswahl zurücksetzen.
:clrSlctFileData	lda	#$00
			sta	a2H			;Dateimodi löschen.
			sta	a6L			;FileSelect löschen.
			sta	batchStatus
			sta	a4L			;$ff = Icon auf Disk.
			sta	a3L			;Kein Icon gewählt.
			sta	a5L			;Zeiger auf Datei-
			sta	a5H			;Eintrag löschen.
			rts

;*** Icon für DnD setzen.
:setDnDFileIcon		lda	a2H
			ora	#%01000000		;Datei-DnD aktiv.
			sta	a2H
			lda	#$0d
			sta	mouseTop

			ldx	a6L			;Mehr als 1 Datei?
			beq	:1			; => Nein, weiter...

			lda	#< icon_MultiFile
			sta	r4L
			lda	#> icon_MultiFile
			sta	r4H
			clv
			bvc	enableDnDSpr

;--- Single-File-DnD: Zeiger auf Datei-Icon.
::1			lda	tabSlctFiles
			jsr	getOffSlctFile

;*** DnD-Sprite definieren.
:setPicDnDSpr		ldx	#r5L
			jsr	setRegXIconData

			ldy	#$00			;Zeiger auf Grafik-
			lda	(r5L),y			;Daten für Sprite.
			clc
			adc	#$01			;Adresse +1 wegen
			sta	r4L			;Icon-Kopfbyte.
			iny
			lda	(r5L),y
			sta	r4H
			bcc	enableDnDSpr
			inc	r4H

;*** DnD-Sprite aktivieren.
:enableDnDSpr		lda	#$01
			sta	r3L
			jsr	DrawSprite

			lda	#IO_IN
			sta	CPU_DATA
			lda	mob0clr
			sta	mob1clr
			lda	#RAM_64K
			sta	CPU_DATA

			lda	#$01
			sta	flag_DnDActive

			lda	#$01
			sta	r3L
			jmp	EnablSprite

;*** System-Icons, Teil #2.
			t "src.DTop.Icons#2"

;*** Routine für ":otherPressVec".
:u_otherPressVec	bit	mouseData		;Maustaste gedrückt?
			bmi	:exit			; => Nein, Ende...

			jsr	u_IsMseInRegion
			b AREA_CLOCK_Y0,AREA_CLOCK_Y1
			w AREA_CLOCK_X0,AREA_CLOCK_X1

			beq	:1			;Nicht im Bereich.

;--- Mausklick auf Uhr, Zeit setzen.
			jmp	func_SetClock

::1			bit	a2H			;Dateiwahl aktiv?
			bmi	:2			; => Ja, weiter...

			lda	flagLockMseDrv
			beq	:unselect
			jmp	mseDvUnlock

::2			bvc	:3			;DnD aktiv? => Nein.
			jmp	execFilesDnD

::3			jsr	chkMseCBMkey
			beq	:exit
::unselect		jsr	unselectIcons
::exit			rts

;*** Datei-DnD abschalten.
.disableFileDnD		bit	a2H			;Datei-DnD aktiv?
			bvc	mseDvUnlock		; => Nein, weiter...

			jsr	disableDnDSpr
			lda	a2H
			and	#%10111111		;Datei-DnD löschen.
			sta	a2H

;*** Mauszeigerbereich zurücksetzen.
:mseDvUnlock		jsr	disableDnDSpr
			sta	flagLockMseDrv
			sta	mouseLeft +0
			sta	mouseLeft +1
			sta	mouseTop
			lda	#$c7
			sta	mouseBottom
			rts

;*** Zusätzliches Sprite für DnD deaktivieren.
:disableDnDSpr		lda	#$01
			sta	r3L
			jsr	DisablSprite
			lda	#$00
			sta	flag_DnDActive
			sta	mouseTop
			rts

;*** Zur ersten gewählten Datei wechseln.
.keybGo1stSlct		bit	a2H			;Dateiwahl aktiv?
			bpl	:exit			; => Nein, weiter...
			ldx	#$00
			jsr	findFSlctEntryX
::exit			rts

;*** Datei-DnD ausführen.
:execFilesDnD		lda	#$ff
			sta	flagKeepMsePos
			ldx	#> batchJobBorder
			lda	#< batchJobBorder
			jsr	execBatchJob
			lda	#$00
			sta	flagKeepMsePos
			rts

;*** DnD-Mehrfachauswahl ausführen.
:batchJobBorder		jsr	testSrcTgtDkRdy

			lda	a3L			;Border gewählt?
			cmp	#ICON_BORDER
			bcs	:mv_deskpad		; => Ja, weiter...

;--- DnD Dateien nach Border.
			jsr	isMseAreaBorder
			beq	:swap_files		;Außerhalb Border.
			lda	isGEOS			;GEOS-Disk?
			bne	:mv_border		; => Ja, weiter...
			jsr	doErrNoGEOSDisk
			clv
			bvc	:cancel

::mv_border		jmp	moveFileToBorder

;--- DnD Dateien nach Deskpad.
::mv_deskpad		jsr	isMseAreaPadPage
			beq	:cancel			;Außerhalb Deskpad.
			lda	a4L			;Datei auf Disk?
			beq	:1
			jmp	moveBorderToPad
::1			jmp	copyBorderToPad

;--- DnD Dateiein innerhalb Deskpad.
::swap_files		jmp	func_SwapFiles

;--- DnD ungültig, Abbruch...
::cancel		jmp	unselectIcons

;*** Datei auf Border ablegen.
:moveFileToBorder	jsr	getFTypeGEOS
			cmp	#SYSTEM_BOOT
			bne	:1
			jmp	doErrStartFile

::1			jsr	getFreeBorderPos
			bcc	:2			; => Frei, weiter...
			ldy	#ERR_MXBORDER
			jsr	openMsgDlgBox
			ldx	#$ff
			rts

::2			lda	r5H
			pha
			lda	r5L
			pha
			lda	a5H
			pha
			lda	a5L
			pha

			lda	a3L
			jsr	iconTabDelEntry

			pla
			sta	r4L
			pla
			sta	r4H
			pla
			sta	r5L
			pla
			sta	r5H
			jsr	doMoveDirEntry

			jsr	updateCurDirPage
			jsr	chkErrRestartDT

			jsr	updateBorderBlk
			jsr	chkErrRestartDT

			lda	a5H
			sta	r14H
			lda	a5L
			sta	r14L
			jsr	readBorderIcon
			jsr	chkErrRestartDT

			jsr	removeJobIcon
			jsr	updInfoScreen

			ldx	#NO_ERROR
			rts

;*** Datei vom Border auf Deskpad verschieben.
:moveBorderToPad
if EN_KILLSYS = TRUE
			jsr	sysDkDelSysFiles
endif

			lda	a0L
			sta	r10L
;			sta	v024e			;Nicht verwendet?
			jsr	GetFreeDirBlk
			jsr	chkErrRestartDT

			tya
			pha

			lda	r10L
			cmp	a1L
			bcc	setNewPadPage
			beq	setNewPadPage

			pha
			jsr	PutDirHead
			txa
			bne	:err

			jsr	loadDirectory

::err			pla
			cpx	#NO_ERROR
			beq	setNewPadPage
			jmp	errTestCurDkRdy

;*** Neue DeskPad-Seite setzen.
:setNewPadPage		sta	a0L

			pla
			clc
			adc	#< dirDiskBuf
			sta	r5L
			lda	a0L
			adc	#> dirDiskBuf
			sta	r5H

			jsr	move_a5_r4
			jsr	doCopyDirEntry

			lda	a3L
			pha
			jsr	unselectJobIcon
			pla

			jsr	removeFileEntry
			jsr	updDTopViewData

			jsr	prntCurPadPage
			jsr	updInfoScrnSlct

			ldx	#NO_ERROR
			rts

;*** Verzeichnisseite/Borderblock speichern.
.updDTopViewData	jsr	updateCurDirPage
			jsr	chkErrRestartDT
			jsr	updateBorderBlk
			jsr	chkErrRestartDT
			jsr	loadIconsCurPage
			jmp	chkErrRestartDT

;*** Datei vom Rand auf Disk kopieren.
:copyBorderToPad
if EN_KILLSYS = TRUE
			jsr	sysDkDelSysFiles
endif

			lda	numDrives
			cmp	#1			;Mehr als 1 Lwfk.?
			bne	:1			; => Ja, weiter...

			lda	a6L			;Mehr als eine Datei?
			beq	:1			; => Nein, weiter...
			jmp	doErrMultiFile

::1			lda	#$00			;Papierkorb leer.
			sta	a8H

			lda	curDrive		;Aktuelles Laufwerk.
			sta	a6H

			lda	a3L			;Gewähltes Icon.
			sta	a3H			;Icon für FileCopy.
			lda	#$ff
			jsr	checkFileExist
			txa
			bne	:exit

			lda	#> bufOpenDiskNm
			sta	nmDkTgt +1
			lda	#< bufOpenDiskNm
			sta	nmDkTgt +0
			lda	a3H
			ldx	#r2L
			jsr	getCurIconDkNm

			lda	r2H
			sta	nmDkSrc +1
			lda	r2L
			sta	nmDkSrc +0

			lda	curDrive
			sta	a2L

			ldy	numDrives
			cpy	#2			;Mehr als 1 Lfwk.?
			bcc	:2			; => Nein, weiter...
			eor	#$01			;Laufwerk wechseln...
::2			sta	a1H

			lda	a0L			;Freier Eintrag ab
			sta	a0H			;aktueller Seite.

			lda	#$00			;Modus: Kopieren.
			jsr	doJobCopyFile
			txa
			bne	:exit

			lda	a0H
			sta	a0L
			cmp	a1L
			bcc	:3
			sta	a1L

::3			lda	a3H			;Icon für FileCopy.
			jsr	removeFileEntry

::exit			jsr	unselectJobIcon
			jsr	openCurDkDrive
			jmp	testCurDiskReady

;*** Überprüfen ob Ziel-Datei bereits existiert.
			t "src.DTop.ChkFile"

;*** Border-Icons definieren.
			t "src.DTop.Border"

;*** Verzeichnis-Eintrag kopieren.
.doCopyDirEntry		lda	#%00000000
			beq	doDirEntryJob

;*** Verzeichnis-Eintrag verschieben.
:doMoveDirEntry		lda	#%10000000
			bne	doDirEntryJob

;*** Verzeichnis-Einträge tauschen.
:doSwapDirEntry		lda	#%01000000
:doDirEntryJob		sta	r2L

			ldy	#$00
::1			lda	(r4L),y
			tax
			lda	(r5L),y

			bit	r2L			;Eintrag löschen?
			bpl	:2			; => Nein, weiter...

			lda	#$00			;Quell-Eintrag
			sta	(r4L),y			;löschen.
			beq	:3

::2			bit	r2L			;Einträge tauschen?
			bvc	:3			; => Nein, weiter...
			sta	(r4L),y

::3			txa				;Ziel-Eintrag
			sta	(r5L),y			;schreiben.

			iny
			cpy	#30
			bne	:1
			rts

;*** Icon in Zwischenspeicher kopieren.
:copyFIcon2Buf		pha
			ldx	#r4L
			jsr	setVec2FileIcon
			ldx	#r2L
			jsr	setRegXIconData
			ldx	#r3L
			jsr	setVecIcon2File

			ldy	#$00
			tya
			sta	(r2L),y
			iny
			sta	(r2L),y

			ldy	#$00
			lda	(r3L),y			;Dateityp definiert?
			beq	:exit			; => Nein, Ende...
			ldy	#$16
			lda	(r3L),y			;GEOS-Datei?
			bne	:1			; => Ja, weiter...

			pla				;Kein Info-Block:
			pha				;Standard-Icon.
			jsr	addIconNotGEOS
			clv
			bvc	:2

::1			jsr	addFileIconGEOS

::2			lda	r3L
			clc
			adc	#$03
			sta	r0L
			lda	r3H
			adc	#$00
			sta	r0H

			pla
			pha
			jsr	saveVecIconNm_r0
			jsr	setDoIconsXYpos

::exit			pla
			rts

;*** Daten für GEOS-Icon in Tabelle kopieren.
:addFileIconGEOS	ldy	#$00
			lda	r4L
			clc
			adc	#$04
			sta	(r2L),y
			tya
			adc	r4H
			iny
			sta	(r2L),y

			lda	#$03
			ldy	#$04
			sta	(r2L),y
			lda	#$15
			iny
			sta	(r2L),y

			iny
			lda	#< func_ClkOnFile
			sta	(r2L),y
			iny
			lda	#> func_ClkOnFile
			sta	(r2L),y
			rts

;*** Position der Icons für DoIcons berechnen.
:setDoIconsXYpos	pha

			ldx	#r5L			;Zeiger Icon-Daten.
			jsr	setRegXIconData

			ldy	#$02			;Zeiger auf X/Y-Pos.
			cmp	#ICON_BORDER
			bcs	:border

::files			tax
			lda	tabXPosFiles,x
			sta	(r5L),y			;X-Position/Cards.
			iny
			lda	tabYPosFiles,x
			sta	(r5L),y			;Y-Position/Pixel.
			bne	:exit

::border		sec
			sbc	#ICON_BORDER
			tax
			lda	tabXPosBorder,x
			sta	(r5L),y			;X-Position/Cards.
			iny
			lda	tabYPosBorder,x
			sta	(r5L),y			;Y-Position/Pixel.

::exit			pla
			rts

;*** Position der Datei-Icons.
.tabXPosFiles		b $05,$0c,$13,$1a,$05,$0c,$13,$1a
.tabYPosFiles		b $30,$30,$30,$30,$58,$58,$58,$58

;*** Position der Border-Icons.
:tabXPosBorder		b $0b,$11,$17,$1d,$08,$0e,$14,$1a
:tabYPosBorder		b $98,$98,$98,$98,$a4,$a4,$a4,$a4

;*** Position der Datei-Icons im FarbRAM.
:tabIconPosXH		b > COLOR_MATRIX + 6*40 + 5
			b > COLOR_MATRIX + 6*40 +12
			b > COLOR_MATRIX + 6*40 +19
			b > COLOR_MATRIX + 6*40 +26
			b > COLOR_MATRIX +11*40 + 5
			b > COLOR_MATRIX +11*40 +12
			b > COLOR_MATRIX +11*40 +19
			b > COLOR_MATRIX +11*40 +26
:tabIconPosXL		b < COLOR_MATRIX + 6*40 + 5
			b < COLOR_MATRIX + 6*40 +12
			b < COLOR_MATRIX + 6*40 +19
			b < COLOR_MATRIX + 6*40 +26
			b < COLOR_MATRIX +11*40 + 5
			b < COLOR_MATRIX +11*40 +12
			b < COLOR_MATRIX +11*40 +19
			b < COLOR_MATRIX +11*40 +26

;*** Eintrag im Verzeichnis-Cache löschen.
.removeFileEntry	pha
			jsr	iconTabDelEntry

			ldx	#r6L
			jsr	setVecIcon2File
			cmp	#ICON_BORDER
			bcs	:border

::file			ldx	#r6L
			jsr	addByteNULL
			pla
			rts

::border		jsr	chkCIconOpenDkNm
			beq	:1

			jsr	getDEntryCurBlk

			ldx	#r7L			;Eintrag im Border-
			jsr	addByteNULL		;Block löschen.
::1			ldx	#r6L			;Name Border-Icon
			jsr	addByteNULL		;löschen.

			ldy	#0			;Diskname für
			tya				;Border-Icon löschen.
::2			sta	(r0L),y
			iny
			cpy	#18
			bne	:2

			pla
			rts

;*** Verzeichniseintrag in Sektor suchen.
;Übergabe: r6 = Zeiger auf Dateieintrag.
.getDEntryCurBlk	lda	#> buf_diskSek3 +2
			sta	r7H
			lda	#< buf_diskSek3 +2
			sta	r7L

::1			ldx	#r6L
			ldy	#r7L
			lda	#30
			jsr	CmpFString
			beq	:found

			clc
			lda	#$20
			adc	r7L
			sta	r7L
			bcc	:2
			inc	r7H

::2			lda	r7H
			cmp	#> buf_diskSek3
			beq	:1

			ldx	#FILE_NOT_FOUND
			bne	:exit
::found			ldx	#NO_ERROR
::exit			rts

;*** NULL-Byte in Adresse schreiben.
;Übergabe: X = Zeiger auf Register.
:addByteNULL		stx	:1 +1
			ldy	#$00
			tya
::1			sta	(r0L),y
			rts

;*** Icon-Speicher für Verzeichniseintrag suchen.
.setVecIcon2File	pha
			cmp	#ICON_BORDER
			bcs	:border

::files			pha
			jsr	setVec2CurPage
			pla
			clv
			bvc	:entry

::border		sec
			sbc	#ICON_BORDER
			pha
			lda	#< tabBIconDEntry
			sta	zpage +0,x
			lda	#> tabBIconDEntry
			sta	zpage +1,x
			pla
::entry			asl
			asl
			asl
			asl
			asl
			clc
			adc	zpage +0,x
			sta	zpage +0,x
			bcc	:1
			inc	zpage +1,x
::1			pla
			rts

;*** Border-Icons und Papierkorb zeichnen.
:drawBIconsTrash	lda	#> AREA_BORDER_X1 -10
			sta	rightMargin +1
			lda	#< AREA_BORDER_X1 -10
			sta	rightMargin +0

			lda	#$08			;Acht Border-Icons.
			sta	r13L
			lda	#ICON_BORDER
			jsr	prntIconTabA

			lda	#ICON_TRASH		;TrashCan-Icon.
			jsr	prntIconTab1

			lda	#> $013f
			sta	rightMargin +1
			lda	#< $013f
			sta	rightMargin +0
			rts

;*** Border-Icons löschen und Drucker-Titel aktualsieren.
:clrBIconsUpdPrnt	jsr	setPattern2
			jsr	i_Rectangle
			b AREA_BORDER_Y0,AREA_BORDER_Y1
			w AREA_BORDER_X0 +17,AREA_BORDER_X1 -10

;*** Druckername anzeigen.
:updatePrntName		jsr	setVecPrntName

			lda	#ICON_PRINT
			jmp	printIconName

;*** Zeiger auf Icon berechnen.
:setVec2FileIcon	pha
			txa
			tay
			iny
			iny
			pla
			pha
			cmp	#ICON_BORDER
			bcc	:1
			sec
			sbc	#ICON_BORDER
::1			sta	zpage,x
			lda	#68
			sta	zpage,y
			jsr	BBMult
			pla
			pha
			cmp	#ICON_BORDER
			bcs	:border_icons

;--- Datei-Icon.
::file_icons		lda	#< tabFIconBitmaps
			clc
			adc	zpage +0,x
			sta	zpage +0,x
			lda	#> tabFIconBitmaps
			adc	zpage +1,x
			sta	zpage +1,x
			clv
			bvc	:exit

;--- Border-Icon.
::border_icons		lda	#< tabBIconBitmaps
			clc
			adc	zpage +0,x
			sta	zpage +0,x
			lda	#> tabBIconBitmaps
			adc	zpage +1,x
			sta	zpage +1,x
::exit			pla
			rts

;*** Border-Icon auf aktueller Disk?
.chkBIconOpenDkNm	lda	a5H
			cmp	#> dirDiskBuf
			bcc	:1
			cmp	#> buf_diskSek3
			bcc	noBIconEntry

::1			lda	a3L

;*** Datei-Icon auf aktueller Disk?
:chkCIconOpenDkNm	pha

			ldx	#r0L
			jsr	getCurIconDkNm
			ldx	#r1L
			jsr	setVecOpenDkNm

			ldx	#r0L
			ldy	#r1L
			lda	#18
			jsr	CmpFString
			beq	:ok

::fail			pla
			ldx	#$00
			rts

::ok			pla
:noBIconEntry		ldx	#$ff
			rts

;*** Zeiger auf Diskname für Icon setzen.
.getCurIconDkNm		pha
			cmp	#ICON_BORDER
			bcs	:border
::files			jsr	setVecOpenDkNm
			pla
			rts

::border		sec
			sbc	#ICON_BORDER
			sta	r14L			;Icon-Nr.

			lda	#18
			sta	r15L			;Länge Diskname.

			txa
			pha

			ldy	#r14L
			ldx	#r15L
			jsr	BBMult			;Icon x 18.

			pla
			tax
			lda	#< tabBIconDkNm
			clc
			adc	r15L
			sta	zpage +0,x
			lda	#> tabBIconDkNm
			adc	#$00			;Zeiger auf Diskname
			sta	zpage +1,x		;für Icon berechnen.

			pla
			rts

;*** Zeiger auf verzeichnisseite setzen.
:setVec2CurPage		lda	#< dirDiskBuf +2
			sta	zpage +0,x
			lda	#> dirDiskBuf +2
			clc
			adc	a0L
			sta	zpage +1,x
			rts

;*** GEOS-Dateityp einlesen.
.getFTypeGEOS		ldy	#$16
			lda	(a5L),y
			rts

;*** Icon-Menü aktualisieren.
:resetIconMenu		ldx	#MAX_ICONS *8 +4
			lda	#$00
::1			sta	tabIconMenu -1,x
			dex
			bne	:1

			ldx	#MAX_ICONS *2
			lda	#$00
::2			sta	tabVecSysIconNm -1,x
			dex
			bne	:2

			lda	#MAX_ICONS		;Anzahl Icons immer
			sta	tabIconMenu		;max. 23!

			jsr	addIconPrntTrash

			lda	#> tabIconMenu
			sta	r0H
			lda	#< tabIconMenu
			sta	r0L
			jsr	DoIcons

			jsr	setVecPrntName

			lda	#0
::3			jsr	printIconName
			clc
			adc	#1
			cmp	#MAX_ICONS
			bcc	:3

			rts

;*** Drucker und Papierkorb in Icon-Tabelle kopieren.
:addIconPrntTrash	lda	#> tabIconsDTop
			sta	r0H
			lda	#< tabIconsDTop
			sta	r0L
			lda	#$02			;Zwei Icons.
			sta	r13L
			lda	#ICON_TRASH		;Pos. 16+17 DoIcons.
			jmp	addXIcons2Tab

:tabIconsDTop		w icon_TrashCan
			b $23,$99,$03,$15
			w func_TrashCan

			w icon_Printer
			b $03,$9c,$03,$11
			w func_FilePrnDnD

;*** Icon-Name ausgeben.
:printIconName		pha
			jsr	loadVecIconNm_r0
			ora	r0L
			beq	:2
			jsr	copyIconFName
			pla
			pha
			jsr	setIconRecArea
			clc
			adc	r3L
			sta	r3L
			bcc	:1
			inc	r3H
::1			lda	r3H
			sta	r11H
			lda	r3L
			sta	r11L
			clc
			lda	r2H
			adc	#$08
			sta	r1H
			jsr	setDTopFont
			jsr	r0_buf_TempName
			jsr	prntCenterText
			jsr	UseSystemFont
::2			pla
			rts

;*** DeskTop-Zeichensaz aktivieren.
:setDTopFont		lda	#> fontDTop6px
			sta	r0H
			lda	#< fontDTop6px
			sta	r0L
			jmp	LoadCharSet

;*** Icon-Nummer für Laufwerk A bis C ermitteln.
.getIconNumCurDrv	lda	curDrive
:getIconNumDrive	and	#%00000011
			clc
			adc	#ICON_DRVA
			rts

;*** Icon-Nummer in Laufwerk konvertieren.
:convIconNumDrv		sec
			sbc	#ICON_DRVA
			clc
			adc	#$08
			rts

;*** Zeiger auf Icon-Name in Tabelle speichern.
:saveVecIconNm_r0	pha
			asl
			tax
			lda	r0L
			sta	tabVecSysIconNm,x
			inx
			lda	r0H
			sta	tabVecSysIconNm,x
			pla
			rts

;*** Icon auf Seite löschen.
.clrDeskPadIcon		pha
			jsr	isIconGfxInTab
			beq	:exit
			pla
			jsr	setIconBackPat
			pha
			jsr	setIconRecArea
			jsr	Rectangle
			pla
			pha
			jsr	prepDrawIconNm
			pla
			pha
			cmp	#ICON_BORDER
			bcs	:exit
			jsr	drawIconNoColor
::exit			pla
			rts

;** Eintrag aus Tabelle löschen.
:iconTabDelEntry	ldx	#$01
			stx	r12L

:iconTabRemove		jsr	clrDeskPadIcon
			ldx	#r5L
			jsr	setRegXIconData
			tax
			lda	#$00
			tay
			sta	(r5L),y
			iny
			sta	(r5L),y
			inx
			txa
			dec	r12L
			bne	iconTabRemove
			dex
			txa
			rts

:invertCurIcon		lda	a3L
:invertIcon		tay
			jsr	isIconGfxInTab
			beq	:exit
			tya
			pha
			jsr	setIconRecArea
			jsr	InvertRectangle
			pla
			jsr	setAreaIconTitle
			jsr	InvertRectangle
::exit			rts

;*** Ist Icon-Adresse definiert?
.isIconGfxInTab		asl
			asl
			asl
			tax
			lda	tabIconData,x
			inx
			ora	tabIconData,x
			rts

;*** Hintergrundmuster für Icon setzen.
:setIconBackPat		pha
			tay
			lda	tabIconBackPat,y
			jsr	SetPattern
			pla
			rts

;*** Hintergrundmuster für System-Icons.
:tabIconBackPat		b PAT_DESKPAD			;Icons 0-7: Pad
			b PAT_DESKPAD
			b PAT_DESKPAD
			b PAT_DESKPAD
			b PAT_DESKPAD
			b PAT_DESKPAD
			b PAT_DESKPAD
			b PAT_DESKPAD
			b PAT_DESKTOP			;Icons 8-15: Border
			b PAT_DESKTOP
			b PAT_DESKTOP
			b PAT_DESKTOP
			b PAT_DESKTOP
			b PAT_DESKTOP
			b PAT_DESKTOP
			b PAT_DESKTOP
			b PAT_DESKTOP			;Icon 16: TrashCan
			b PAT_DESKTOP			;Icon 17: Printer
			b PAT_DESKPAD			;Icon 18: Scroll U/D
			b PAT_TITLE			;Icon 19: Close Disk
			b PAT_DESKTOP			;Icon 20: Drive A
			b PAT_DESKTOP			;Icon 21: Drive B
			b PAT_DESKTOP			;Icon 22: Drive C

;*** Anzeigebereich für Icon-Titel initialisieren.
.prepDrawIconNm		jsr	setIconBackPat
			pha
			jsr	isIconNmInTab
			beq	:1
			pla
			pha
			jsr	setAreaIconTitle
			jsr	Rectangle
::1			pla
			rts

;*** Ist Icon-Name in Tabelle vorhanden?
:isIconNmInTab		asl
			tax
			lda	tabVecSysIconNm,x
			inx
			ora	tabVecSysIconNm,x
			rts

;*** Koordinaten für Icon-Titel definieren.
:setAreaIconTitle	pha
			jsr	setDTopFont
			pla
			pha
			jsr	setIconRecArea
			clc
			adc	r3L
			sta	r3L
			bcc	:1
			inc	r3H
::1			pla

			pha
			jsr	loadVecIconNm_r0
			jsr	copyIconFName
			jsr	r0_buf_TempName
			jsr	getStringWidth

			lda	r4L
			lsr
			sta	r13L

			lda	r3L
			sec
			sbc	r13L
			sta	r3L
			lda	r3H
			sbc	#$00
			sta	r3H
			bpl	:2

			lda	#$00
			sta	r3L
			sta	r3H

::2			jsr	r3_add_width_r4

			lda	#> AREA_DRIVES_X1
			sta	r13H
			lda	#< AREA_DRIVES_X1
			sta	r13L
			jsr	limitRightXPos

			lda	r2H
			sta	r2L
			lda	r2L
			clc
			adc	#$04
			sta	r2L

			lda	curHeight
			clc
			adc	r2L
			sec
			sbc	#$01
			sta	r2H

			pla
			cmp	#ICON_DRVA		;Laufwerk A-C ?
			bcc	:3			; => Nein, weiter...

			lda	#> AREA_DRIVES_X0
			sta	r13H
			lda	#< AREA_DRIVES_X0
			sta	r13L
			jsr	limitLeftXPos

::3			jmp	UseSystemFont

;*** Linken Rand begrenzen.
:limitLeftXPos		ldx	r13H
			lda	r13L
			cpx	r3H
			bne	:1
			cmp	r3L
::1			bcc	:2
			stx	r3H
			sta	r3L
::2			rts

;*** Rechten Rand begrenzen.
:limitRightXPos		ldx	r13H
			lda	r13L
			cpx	r4H
			bne	:1
			cmp	r4L
::1			bcs	:2
			stx	r4H
			sta	r4L
::2			rts

;*** Bereich für Icon berechnen.
:setIconRecArea		ldx	#r5L
			jsr	setRegXIconData

			lda	#$00
			sta	r3H

			ldy	#$02
			lda	(r5L),y
			asl
			asl
			asl
			rol	r3H
			sta	r3L
			iny
			lda	(r5L),y
			sta	r2L
			iny
			lda	#$00
			sta	r4H
			lda	(r5L),y
			asl
			asl
			pha
			asl
			rol	r4H
			sec
			sbc	#$01
			sta	r4L
			bcs	:1
			dec	r4H
::1			jsr	r3_add_width_r4
			iny
			lda	(r5L),y
			clc
			adc	r2L
			sec
			sbc	#$01
			sta	r2H
			pla
			rts

;*** Rechte X-Koordinate berechnen.
:r3_add_width_r4	lda	r3L
			clc
			adc	r4L
			sta	r4L
			lda	r3H
			adc	r4H
			sta	r4H
			rts

;*** Zeiger auf Icon-Name nach r0.
:loadVecIconNm_r0	asl
			tax
			lda	tabVecSysIconNm,x
			sta	r0L
			inx
			lda	tabVecSysIconNm,x
			sta	r0H
			rts

;*** Register auf Icon-Daten setzen.
;Übergabe: XReg = Zeiger auf Register.
;          Akku = Zeiger auf Icon in Tabelle.
:setRegXIconData	pha
			asl
			asl
			asl
			clc
			adc	#< tabIconData
			sta	zpage +0,x
			lda	#> tabIconData
			adc	#$00
			sta	zpage +1,x
			pla
			rts

;*** C64Map-Icon zu DoIcons-Tabelle hinzufügen.
;Übergabe: Akku = Position in DoIcons-Tabelle.
:addIconNotGEOS		ldy	#> tabIconsC64Map
			sty	r0H
			ldy	#< tabIconsC64Map
			sty	r0L

;*** Einzelnes Icon zu DoIcons-Tabelle hinzufügen.
;Übergabe: r0 = Zeiger auf Icon-Eintrag.
;          Akku = Position in DoIcons-Tabelle.
:add1Icon2Tab		ldx	#$01			;Ein Icon.
			stx	r13L

;*** Mehrere Icons zu DoIcons-Tabelle hinzufügen.
;Übergabe: r0   = Zeiger auf Icon-Tabelle.
;          Akku = Position in DoIcons-Tabelle.
;          r13L = Anzahl Icons.
:addXIcons2Tab		asl
			asl
			asl
			tax
			ldy	#$00
::1			lda	#$08
			sta	r13H
::2			lda	(r0L),y
			sta	tabIconData,x
			inx
			iny
			dec	r13H
			bne	:2
			dec	r13L
			bne	:1
			rts

:tabIconsC64Map		w icon_C64Map
			b $00,$00,$03,$15
			w func_ClkOnFile

;*** Einzelnes Icon ausgeben.
;Übergabe: Akku = Position in Icon-Tabelle.
.prntIconTab1		ldx	#$01			;Ein Icon.
			stx	r13L

;*** Mehrere Icons ausgeben.
;Übergabe: Akku = Position in Icon-Tabelle.
;          r13L = Anzahl Icons.
:prntIconTabA		tay

			lda	r13L
			pha
			tya
			pha

			jsr	testIconExist
			beq	:3			; => Kein Icon.

			dey
::1			lda	(r5L),y			;Icon-Daten nach
			sta	r0,x			;r0-r2 kopieren.
			inx
			iny
			cpy	#$06
			bne	:1

			jsr	BitmapUp		;Icon ausgeben.

			pla
			pha
			cmp	#ICON_BORDER
			bcs	:2

			ldx	flagDiskRdy		;Diskette gültig?
			beq	:2			; => Nein, weiter...
			jsr	drawIconColor

::2			pla
			pha
			jsr	printIconName

			pla
			pha
			jsr	getSlctIconEntry
			cpx	#$ff
			beq	:3

			jsr	invertIcon

::3			pla
			tax
			inx
			pla
			sta	r13L
			txa
			dec	r13L
			bne	prntIconTabA

			dex
			txa
			rts

;*** Testen ob Icon-Grafik definiert.
;Übergabe: Akku = Eintrag in Tabelle.
;Rückgabe: Akku = $00, Icon nicht definiert.
:testIconExist		ldx	#r5L
			jsr	setRegXIconData

			ldy	#$00
			ldx	#$00
			lda	(r5L),y
			iny
			ora	(r5L),y
			rts

;*** Icon-Farben anzeigen.
			t "src.DTop.IconCol"

;*** Seite vor/zurück.
:keybPageDown		ldy	#$01
			b $2c
:keybPageUp		ldy	#$ff
			lda	diskOpenFlg
			beq	:1
			sty	r1L
			bne	switchPadPage
::1			rts

;*** Alle Dateien auf Seite auswählen.
:func_SlctPage		jsr	testMsePageUpDn

;*** Auf andere Seite wechseln.
;Übergabe: r1L = Seite vor ($01).
;                Seite zurück ($ff).
:switchPadPage		lda	r1L
			pha
			jsr	animatePageSlct
			pla
			clc
			adc	a0L			;Erste Seite?
			bpl	:1			; => Nein, weiter...
			lda	a1L			;Zur letzten Seite...

::1			cmp	a1L
			bcc	updateDirPage
			beq	updateDirPage
			lda	#$00			;Zur ersten Seite...

;*** Directory-Seite aktualisieren.
:updateDirPage		cmp	a0L
			beq	:1
			sta	a0L
			jsr	loadIconsCurPage
			jsr	chkErrRestartDT
::1			jmp	prntByIcon

;*** Neue Directory-Seite öffnen.
.openNewPadPage		cmp	a1L
			beq	:1
			bcs	:exit

::1			cmp	a0L
			beq	:exit
			pha
			bcs	:2

			lda	#$ff
			sta	r1L
			bne	:3

::2			lda	#$01
			sta	r1L

::3			jsr	animatePageSlct
			pla
			jsr	updateDirPage
::exit			rts

;*** Mausklick auf Eselsohr auswerten.
;Rückgabe: Y/r1L = $01: Seite vor.
;                  $ff: Seite zurück.
:testMsePageUpDn	lda	#$01
			ldx	#r0L
			jsr	setZPage_Mult8

			lda	mouseXPos +0
			sec
			sbc	r0L
			clc
			adc	#AREA_PADPAGE_Y1 -14

::next			ldy	#$01
			cmp	mouseYPos
			beq	:last
			bcs	:set

::last			ldy	#$ff

::set			sty	r1L
			rts

;*** Seitenwechsel animieren.
			t "src.DTop.Animate"

;*** Navigationsicons anzeigen.
			t "src.DTop.NavIcon"

;*** GEOS-Menü, Teil #2.
			t "src.DTop.Menu#2"

:nameGEOSBOOT		b "GEOS BOOT",$a0

;*** Menü "geos" öffnen.
:dynMenu_geos		ldx	#$04
			jsr	putScreenToBuf
			lda	#< dm_geos
			ldy	#> dm_geos
			bne	openDynMenu

;*** Menü "Datei" öffnen.
:dynMenu_file		ldx	#$08
			jsr	putScreenToBuf
			lda	#< dm_file
			ldy	#> dm_file
			bne	openDynMenu

;*** Menü "Anzeige" öffnen.
:dynMenu_view		ldx	#$0c
			jsr	putScreenToBuf
			lda	#< dm_view
			ldy	#> dm_view
			bne	openDynMenu

;*** Menü "Diskette" öffnen.
:dynMenu_disk		ldx	#$10
			jsr	putScreenToBuf
			lda	#< dm_disk
			ldy	#> dm_disk
			bne	openDynMenu

;*** Menü "Auswahl" öffnen.
:dynMenu_slct		ldx	#$14
			jsr	putScreenToBuf
			lda	#< dm_select
			ldy	#> dm_select
			bne	openDynMenu

;*** Menü "Seite" öffnen.
:dynMenu_page		ldx	#$18
			jsr	putScreenToBuf
			lda	#< dm_page
			ldy	#> dm_page
			bne	openDynMenu

;*** Menü "Optionen" öffnen.
:dynMenu_opt		ldx	#$1c
			jsr	putScreenToBuf
			lda	#< dm_options
			ldy	#> dm_options

;*** DYN_MENU öffnen.
:openDynMenu		sty	r0H
			sta	r0L
			jmp	grfxScrColRec

;*** Bildschirmpuffer.
			t "src.DTop.ScrnBuf"

;*** DA aus geos-Menü öffnen.
:menuOpenDA		pha
			jsr	DoPreviousMenu
			pla
			sec
			sbc	#$04
			sta	r6L
			asl
			asl
			asl
			asl
			clc
			adc	r6L
			adc	#< tabNameDeskAcc
			sta	r6L
			lda	#$00
			adc	#> tabNameDeskAcc
			sta	r6H
			jsr	FindFile
			jsr	chkErrRestartDT

;*** DA öffnen.
:openFileDeskAcc	jsr	unselectIcons
			jsr	r9_dirEntryBuf

			ldx	#$00
			stx	r10L
			stx	r0L

			lda	dm_file
			pha
			lda	dm_file -1
			pha
			jsr	LdDeskAcc
			lda	#ST_WR_FORE
			sta	dispBufferOn
			pla
			sta	dm_file -1
			pla
			sta	dm_file

			txa
			pha

			lda	screencolors
			sta	:col
			jsr	i_FillRam
			w 1000
			w COLOR_MATRIX
::col			b $00

			pla
			beq	:done
			tax
			jsr	openErrBox1Line
::done			jmp	MainInit

;*** Diskette öffnen.
:menuDiskOpen		jsr	DoPreviousMenu

;*** C: öffnen, Laufwerke tauschen?
:testSwapDrives		lda	flagLockMseDrv
			beq	keybDiskOpen
			jsr	disableFileDnD

			lda	curDrive
			cmp	#8
			beq	:swap_ac
::swap_bc		jmp	keybSwapDrvBC
::swap_ac		jmp	keybSwapDrvAC

;*** Diskette öffnen.
:keybDiskOpen		jsr	getIconNumCurDrv
			jsr	clrDeskPadIcon
			jsr	openNewDisk
			jmp	testErrCloseDisk

;*** Diskette kopieren.
:menuDiskCopy		jsr	DoPreviousMenu
:keybDiskCopy		lda	diskOpenFlg
			bne	:1
			rts

::1			jsr	testDiskChanged
			jsr	unselectIcons

			jsr	GetDirHead
			txa
			bne	:err

			jsr	testDiskMode
			cmp	#Drv1581
			beq	:2
			bcs	:exitOnErr

::2			sta	dvTypSource

			jsr	getUsedBlocks

			lda	r0L
			ldy	isGEOS
			beq	:3
			and	#%11111110
::3			ora	r0H
			bne	:testCopySysDk

			ldx	#> dbox_DiskEmpty
			lda	#< dbox_DiskEmpty
			jsr	openDlgBox
			cmp	#YES
			beq	:testCopySysDk
			rts

;--- Auf Systemdiskette testen.
::testCopySysDk		lda	GEOS_DISK_TYPE
			cmp	#"B"			;$42 = Startdiskette.
			bne	:11
			jmp	doErrNotAllowed

::11			lda	curDrive
			sta	a6H
			sta	a1H			;Source-Laufwerk.

			ldy	numDrives
			cpy	#$02			;Mehr als 1 Lfwk.?
			bcc	:12			; => Nein, weiter...
			eor	#$01
::12			sta	a2L			;Target-Laufwerk.

			tay
			lda	driveType -8,y
			and	#ST_DTYPES
			cmp	#Drv1581
::exitOnErr		beq	:21
			bcs	:errDiskCopy

::21			cmp	dvTypSource
			beq	:22
			cmp	#Drv1581
			beq	:errDiskCopy
			cmp	dvTypSource
			bcc	:errDiskCopy
::22			sta	dvTypTarget
			lda	driveType -8,y
			bmi	:testdisk

			tya
			clc
			adc	#"A" -8
			sta	dbtxInsertTgtDrv

			ldx	#> dbox_InsertTgtD
			lda	#< dbox_InsertTgtD
			jsr	openDlgBox
			cmp	#CANCEL
			bne	:testdisk
::err			rts

::testdisk		lda	a2L
			jsr	setNewDevice
			jsr	NewDisk			;Diskette öffnen.
			txa				;Diskfehler?
			bne	:newdisk		; => Ja, Fehler...
			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskfehler?
			beq	:disk_ok		; => Nein, weiter...

::newdisk		jsr	func_CopyFrmtDk
			txa
			beq	:testdisk
			cpx	#CANCEL_ERR
			beq	cancelBack2DTop
			jsr	openErrBox1Line
			clv
			bvc	cancelBack2DTop

::errDiskCopy		ldy	#ERR_DISKCOPY
			jsr	openMsgDlgBox
			clv
			bvc	cancelBack2DTop

;--- Ziel-Disk vorhanden.
::disk_ok		lda	GEOS_DISK_TYPE
			beq	:31			; => Arbeitsdiskette.
			jsr	doErrNotAllowed
			clv
			bvc	cancelBack2DTop

;--- Ziel-Disk darf überschrieben werden.
::31			lda	dvTypTarget
			cmp	#Drv1571		;Ziel = 1571?
			bne	:32			; => Nein, weiter...

			bit	curDirHead +3
			bmi	:32			; => Doppelseitig.

			lda	#Drv1541		;Bei 1571/Einseitig
			sta	dvTypTarget		;auf 1541 wechseln.
			cmp	dvTypSource		;Gleicher Typ?
			bne	:errDiskCopy

;--- Sicherheitsabfrage.
::32			jsr	setNmSrcTgtDisk

			ldx	#> dbox_ReplaceDisk
			lda	#< dbox_ReplaceDisk
			jsr	openDlgBox
			cmp	#CANCEL
			beq	cancelBack2DTop

;--- Diskette kopieren.
			jsr	doJobCopyDisk		;Dateien kopieren.

;--- Zurück zum DeskTop.
:cancelBack2DTop	jsr	openCurDkDrive
			jmp	MainInit

;*** Dialogbox: leere Diskette kopieren?
:dbox_DiskEmpty		b %10000001
			b DBTXTSTR,$0c,$20
			w dbtxDiskEmpty1
			b DBTXTSTR,$0c,$30
			w dbtxDiskEmpty2
			b YES     ,$01,$48
			b NO      ,$11,$48
			b NULL

;*** Laufwerksmodus testen.
;Rückgabe: A = 1541 (SingleSided 1571), 1571 oder 1581.
.testDiskMode		ldy	curDrive
			lda	driveType -8,y
			and	#ST_DTYPES
			cmp	#Drv1571
			bne	:exit

			bit	curDirHead +3
			bmi	:exit			; => Dopelseitig.

			lda	#Drv1541
::exit			rts

;*** Namen für Quell-/Ziel-Disk festlegen.
:setNmSrcTgtDisk	jsr	r2_curDirHeadNm
			jsr	r6_buf_TempStr2
			ldy	#r6L
			jsr	copyNameA0_16

			ldx	#r2L
			lda	#> buf_TempStr0
			sta	r3H
			lda	#< buf_TempStr0
			sta	r3L
			ldy	#r3L
			lda	#18
			jsr	CopyFString

			lda	#> bufOpenDiskNm
			sta	r2H
			lda	#< bufOpenDiskNm
			sta	r2L
			lda	#> buf_TempStr1
			sta	r7H
			lda	#< buf_TempStr1
			sta	r7L
			ldx	#r2L
			ldy	#r7L
			jsr	copyNameA0_16

			lda	#> buf_TempStr0
			sta	nmDkTgt +1
			lda	#< buf_TempStr0
			sta	nmDkTgt +0
			lda	#> bufOpenDiskNm
			sta	nmDkSrc +1
			lda	#< bufOpenDiskNm
			sta	nmDkSrc +0
			rts

;*** Dialogbox: Bitte Zieldisk einlegen.
:dbox_InsertTgtD	b %10000001
			b DBTXTSTR,$10,$20
			w dbtxInsertDk1
			b DBTXTSTR,$10,$30
			w dbtxInsertDk2
			b OK      ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

;*** Dialogbox: Inhalt von Disk ersetzen?
:dbox_ReplaceDisk	b %10000001
			b DBTXTSTR,$10,$10
			w dbtxReplFiles1
			b DBVARSTR,$10,$20
			b r6L
			b DBTXTSTR,$10,$30
			w dbtxReplFiles2
			b DBVARSTR,$10,$40
			b r7L
			b YES     ,$01,$48
			b CANCEL  ,$11,$48
			b NULL

;*** Systemdatei kopieren?
.testSystemFile		jsr	getFTypeGEOS
			cmp	#SYSTEM
			beq	exitErrSysFile
			cmp	#SYSTEM_BOOT
			beq	exitErrStartFile
			rts

;*** Fehler: Nicht möglich, da keine GEOS-Diskette.
:doErrNoGEOSDisk	ldy	#< txErrNoGEOSDisk
			ldx	#> txErrNoGEOSDisk
			bne	openSysErrDBox

;*** Fehler: Nicht auf Start-/Hauptdiskette möglich.
.doErrNotAllowed	cmp	#"B"			;$42 = Startdiskette.
			bne	:main

::boot			ldy	#< txErrBootDisk
			ldx	#> txErrBootDisk
			bne	openSysErrDBox

::main			ldy	#< txErrMainDisk
			ldx	#> txErrMainDisk
			bne	openSysErrDBox

.testFileOtherDk	lda	a4L
			beq	exitErrFOtherDk
			rts

;--- Fehler: Nicht auf Datei von anderer Disk anwendbar.
:exitErrFOtherDk	pla
			pla
.doErrFOtherDk		ldy	#< txErrOtherDisk
			ldx	#> txErrOtherDisk
			bne	openSysErrDBox

;--- Fehler: Nicht auf Systemprogramm anwendbar.
:exitErrSysFile		pla
			pla
			ldy	#< txErrSysFile
			ldx	#> txErrSysFile
			bne	openSysErrDBox

;--- Fehler: Nicht auf Startprogramm anwendbar.
:exitErrStartFile	pla
			pla
.doErrStartFile		ldy	#< txErrStartFile
			ldx	#> txErrStartFile

:openSysErrDBox		sty	r5L
			stx	r5H

			ldx	#> dbox_Forbidden
			lda	#< dbox_Forbidden
			jsr	openDlgBox
			ldx	#CANCEL_ERR
			rts

;*** Dialogbox: Nicht auf dieser Disk möglich.
:dbox_Forbidden		b %10000001
			b DBTXTSTR,$10,$10
			w dbtxForbidden1
			b DBTXTSTR,$10,$20
			w dbtxForbidden2
			b DBVARSTR,$10,$30
			b r5L
			b DBTXTSTR,$10,$40
			w dbtxForbidden3
			b OK      ,$11,$48
			b NULL

;*** Zeiger auf Directory-Eintrag initialisieren.
.initVecCurDEntry	lda	a5L
			sta	r9L
			sta	r6L
			sta	r7L
			lda	a5H
			sta	r9H
			sta	r6H
			sta	r7H

;--- Datei im Verzeichnis-Cache?
			cmp	#> dirDiskBuf
			bcs	:1			; => Ja, weiter...

			jsr	getDEntryCurBlk

::1			rts

;*** Anzeigemodus wechseln.
:menuViewMode		pha
			jsr	DoPreviousMenu
			pla
			cmp	a7L
			beq	:exit

			ldx	diskOpenFlg
			beq	:exit
			sta	a7L

			cmp	#$00			;Icon-Modus?
			bne	:1			; => Nein, weiter...

			jsr	loadIconsCurPage

::1			jsr	unselectIcons
			jsr	clearCurPadPage
			jsr	prntCurPadPage
			jsr	setPageNavIcon

::exit			rts

;*** DeskTop neu starten.
:menuOptReset		jsr	DoPreviousMenu
:keybOptReset		jsr	disableFileDnD
			jmp	MainInit		;Evtl. unnötig?
							;":MainInit" folgt
							;direkt im Anschluss!

;*** DeskTop-MainInit.
.MainInit		t "src.DTop.DTMain"

;*** Erweiterte MainLoop-Routine.
			t "src.DTop.DoMLoop"

;*** Tastaturabfrage.
			t "src.DTop.TestKey"

;*** Laufwerke tauschen.
			t "src.DTop.SwapDrv"

;*** DeskTop-Modul laden.
			t "src.DTop.LoadMod"

;*** Datei/Drucken.
:menuFilePrint		jsr	DoPreviousMenu
:keybFilePrint		jsr	loadDTopMod1
			jmp	vlirModBase +0

;*** DnD/Datei drucken.
:func_FilePrnDnD	jsr	loadDTopMod1
			jmp	vlirModBase +3

;*** Datei/Löschen.
:menuFileDel		jsr	DoPreviousMenu
:keybFileDel		jsr	loadDTopMod1
			jmp	vlirModBase +6

;*** Undelete.
:func_TrashCan		jsr	loadDTopMod1
			jmp	vlirModBase +9

;*** Diskette/Validate.
:menuDiskValid		jsr	DoPreviousMenu
:keybDiskValid		jsr	loadDTopMod1
			jmp	vlirModBase +12

;*** Diskette/Formatieren.
:menuDiskFormat		jsr	DoPreviousMenu
:keybDiskFormat		jsr	setDrvNotRdy
			jsr	loadDTopMod1
			jmp	vlirModBase +15

;*** Zieldisk für DiskCopy formatieren.
:func_CopyFrmtDk	jsr	setDrvNotRdy
			jsr	loadDTopMod1
			jmp	vlirModBase +18

;*** Datei/Undelete.
:menuFileUndel		jsr	DoPreviousMenu
.keybFileUndel		jsr	loadDTopMod1
			jmp	vlirModBase +21

;*** Diskette/Löschen.
:menuDiskErease		jsr	DoPreviousMenu
:keybDiskErease		jsr	setDrvNotRdy
			jsr	loadDTopMod1
			jmp	vlirModBase +24

;*** Directory-Einträge tauschen.
:func_SwapFiles		jsr	loadDTopMod1
			jmp	vlirModBase +27

;*** Auswahl/Alle Seiten.
:menuSlctAll		jsr	DoPreviousMenu
:keybSlctAll		jsr	loadDTopMod1
			jmp	vlirModBase +30

;*** Auswahl/Aktuelle Seite.
:menuSlctPage		jsr	DoPreviousMenu
:keybSlctPage		jsr	loadDTopMod1
			jmp	vlirModBase +33

;*** Auswahl/Border.
:menuSlctBorder		jsr	DoPreviousMenu
:keybSlctBorder		jsr	loadDTopMod1
			jmp	vlirModBase +36

;*** Datei/Info.
:menuFileInfo		jsr	DoPreviousMenu
:keybFileInfo		jsr	loadDTopMod2
			jmp	vlirModBase +0

;*** geos/Drucker wählen.
:menuSlctPrint		jsr	DoPreviousMenu
			jsr	loadDTopMod3
			jmp	vlirModBase +0

;*** geos/Eingabegerät wählen.
:menuSlctInput		jsr	DoPreviousMenu
:keybSlctInput		jsr	loadDTopMod3
			jmp	vlirModBase +3

;*** Seite/Anhängen.
:menuPageAdd		jsr	DoPreviousMenu
:keybPageAdd		jsr	loadDTopMod3
			jmp	vlirModBase +6

;*** Seite/Löschen.
:menuPageDel		jsr	DoPreviousMenu
:keybPageDel		jsr	loadDTopMod3
			jmp	vlirModBase +9

;*** Anzeige/Format wählen.
:prntBySize		jmp	vlirModBase +0
:prntByType		jmp	vlirModBase +3
:prntByDate		jmp	vlirModBase +6
:prntByName		jmp	vlirModBase +9

;*** Seite wechseln.
:func_ScrollUpDn	jsr	loadDTopMod4
			jmp	vlirModBase +12

;*** Optionen/BASIC.
:menuOptBasic		jsr	DoPreviousMenu
			jsr	setDrvNotRdy
			jsr	loadDTopMod4
			jmp	vlirModBase +15

;*** BASIC-Datei starten.
:startFileBASIC		jsr	loadDTopMod4
			jmp	vlirModBase +18

;*** Diskette/Umbenennen.
:menuDiskRName		jsr	DoPreviousMenu
:keybDiskRName		jsr	loadDTopMod4
			jmp	vlirModBase +21

;*** Datei/Umbenennen.
:menuFileRName		jsr	DoPreviousMenu
:keybFileRName		jsr	loadDTopMod4
			jmp	vlirModBase +24

;*** Datei/Kopieren.
:menuFileCopy		jsr	DoPreviousMenu
:keybFileCopy		jsr	loadDTopMod4
			jmp	vlirModBase +27

;*** Optionen/Uhrzeit setzen.
:menuOptClock		jsr	DoPreviousMenu
:func_SetClock		jsr	loadDTopMod5
			jmp	vlirModBase +0

;*** Fehler/DeskTop-Version.
:errIncompatible	jsr	loadDTopMod5
			jmp	vlirModBase +3

;*** Optionen/ShortCuts.
:menuOptKeys		jsr	DoPreviousMenu
			jsr	loadDTopMod5
			jmp	vlirModBase +6

;*** geos/Info.
:menuInfoGEOS		jsr	DoPreviousMenu
			jsr	loadDTopMod5
			jmp	vlirModBase +9

;*** geos/DeskTop-Info.
:menuInfoDTOP		jsr	DoPreviousMenu
			jsr	loadDTopMod5
			jmp	vlirModBase +12

;*** Flag setzen: Laufwerk nicht bereit.
:setDrvNotRdy		lda	#$ff
			sta	flagDrivesRdy
			rts

;*** Datei-Mehrfach-Operation ausführen.
			t "src.DTop.DoBatch"

;*** Mehrfach-Operation: Fehler.
.doErrMultiFile		ldy	#ERR_NOMULTIF
			jsr	openMsgDlgBox
			jsr	unselectIcons
			ldx	#$ff
			rts

;*** DeskTop-Uhr.
if LANG = LANG_DE
			t "src.DTop.Clock24"
endif
if LANG = LANG_EN
			t "src.DTop.Clock12"
endif

;*** Titel für Icon nach ":buf_TempName" kopieren.
;Übergabe: A/X = Adr. Dateiname.
.copyIconTitle		stx	r0H
			sta	r0L

;*** Dateiname für Icon nach ":buf_TempName" kopieren.
;Leerzeichen am Anfang/Ende hinzufügen.
:copyIconFName		ldx	#$00
			stx	r1L
			lda	#" "			;Leerzeichen Anfang.
			sta	buf_TempName,x
			inx

			jsr	convIconText

			ldx	r1L
			inx
			lda	#" "			;Leerzeichen Ende.
			sta	buf_TempName,x

			inx
			lda	#NULL
			sta	buf_TempName,x
			rts

;*** Icon-Beschriftung konvertieren.
;Übergabe: r0  = Zeiger auf Name.
;Rückgabe: r1L = Zeiger auf letztes Textzeichen
;                in buf_TempName
.convIconText		ldy	#0
::1			lda	(r0L),y
			beq	:5

			and	#$7f
			cmp	#$20
			bcc	:2
			cmp	#$7f
			bcc	:3

::2			lda	#"*"
::3			sta	buf_TempName,x
			cmp	#" "
			beq	:4
			stx	r1L

::4			inx
			iny
			cpy	#16
			bne	:1
::5			rts

;*** Text rechtsbündig ausgeben.
;Übergabe: r0  = Zeiger auf Text.
;          r11 = X-Koordinate (Rechts).
.prntRJustedText	jsr	getStringWidth
			clv
			bvc	prntJustedText

;*** Text zentriert ausgeben.
;Übergabe: r0  = Zeiger auf Text.
;          r11 = X-Koordinate (Mitte).
.prntCenterText		jsr	getStringWidth

			lsr	r4H
			ror	r4L

;*** Text mittig/rechtsbündig ausgeben.
:prntJustedText		lda	r11L
			sec
			sbc	r4L
			sta	r11L
			lda	r11H
			sbc	r4H
			sta	r11H
			bcs	:prnt			; => X > 0, weiter...

;--- Hinweis:
;Unterlauf X-Koordinate. In diesem Fall
;würde kein Name angezeigt werden!
			lda	#0			;X-Koordinate
			sta	r11L			;zurücksetzen.
			sta	r11H

::prnt			jmp	PutString

;*** Breite Textstring ermitteln.
:getStringWidth		ldy	#$00
			sty	r4L
			sty	r4H
::1			lda	(r0L),y
			beq	:3
			sty	curPosStrWidth
			jsr	GetCharWidth
			ldy	curPosStrWidth
			clc
			adc	r4L
			sta	r4L
			bcc	:2
			inc	r4H
::2			iny
			bne	:1
::3			rts

;*** Name Icon in Zwischenspeicher kopieren.
.getIconTitle		ldx	#$00
			jsr	convIconText
			ldy	r1L
			iny
			jsr	r6_buf_TempName
			lda	#$00
			sta	(r6L),y
			rts

:setZPage_Mult8		ldy	#$00
			sty	zpage +1,x
			asl
			asl
			asl
			rol	zpage +1,x
			sta	zpage +0,x
			rts

;*** Mausposition abfragen.
			t "src.DTop.MseArea"

;*** Inhalt von DeskPad-Seite löschen.
:clearCurPadPage	jsr	setPattern0

			lda	#ST_WR_FORE
			sta	dispBufferOn

			jsr	i_Rectangle
			b AREA_PADPAGE_Y0,AREA_PADPAGE_Y1
			w AREA_PADPAGE_X0,AREA_PADPAGE_X1

			jmp	drawDeskPadCol

;*** Text über PutString ausgeben.
;Übergabe: A/X = Zeiger auf String.
;          r11 = X-Koordinate.
;          r1H = Y-Koordinate.
.putStringAX		stx	r0H
			sta	r0L
			jmp	PutString

;*** Datei-Bereich löschen.
.clearFilePad		jsr	setPattern0

			jsr	i_Rectangle
			b AREA_FILEPAD_Y0,AREA_FILEPAD_Y1
			w AREA_FILEPAD_X0,AREA_FILEPAD_X1

			jmp	drawDeskPadCol

;*** Zeiger auf Verzeichnis-Eintrag.
.r4_r5_dirEntry		lda	#> tempDirEntry
			sta	r5H
			lda	#< tempDirEntry
			sta	r5L

.move_a5_r4		lda	a5H
			sta	r4H
			lda	a5L
			sta	r4L
			rts

;*** Zeiger auf Verzeichnisblock setzen.
;Übergabe: a0L = Directory-Seite.
.setVecDirBlock		lda	#< dirDiskBuf
			sta	r0L
			lda	a0L
			clc
			adc	#> dirDiskBuf
			sta	r0H
			rts

;*** Zeiger auf Name für Druckersymbol setzen.
:setVecPrntName		ldy	#> textPrinter
			ldx	#< textPrinter
			lda	PrntFilename
			beq	:1
			ldy	#> PrntFilename
			ldx	#< PrntFilename
::1			sty	vecIconPrntName +1
			stx	vecIconPrntName +0
			rts

;*** Drucker "NICHT AUF DISKETTE" anzeigen.
:updatePrntStatus	lda	vecIconPrntName +0
			sta	r6L
			lda	vecIconPrntName +1
			sta	r6H
			jsr	FindFile
			txa
			cmp	#FILE_NOT_FOUND
			beq	prntNotFound

			ldy	#$16			;GEOS-Dateityp
			lda	(r5L),y			;einlesen.
			cmp	#PRINTER
			bne	prntNotFound

;*** Druckername löschen.
.clrPrntName		lda	# PRNAME_Y0		;Drucker gefunden,
			sta	r2L			;Untertitel löschen.
			lda	# PRNAME_Y1
			sta	r2H

			lda	#> PRNAME_X0
			sta	r3H
			lda	#< PRNAME_X0
			sta	r3L

			lda	#> PRNAME_X1
			sta	r4H
			lda	#< PRNAME_X1
			sta	r4L

			jmp	doPat2Rectangle

;*** Drucker nicht gefunden.
:prntNotFound		lda	#> textPrntNotOnDsk
			sta	r2H
			lda	#< textPrntNotOnDsk
			sta	r2L

			lda	# PRNAME_Y0 +4
			sta	r1H
			lda	#> PRNAME_CX
			sta	r11H
			lda	#< PRNAME_CX
			sta	r11L

;*** Druckername / Name Mülleimer anzeigen.
;Übergabe: r2  = Zeiger auf Text.
;          r11 = X-Koordinate (mitte).
;          r1H = Y-Koordinate.
:doPrntTrashName	jsr	setDTopFont

			lda	r2H
			sta	r0H
			lda	r2L
			sta	r0L

			jsr	prntCenterText
			jmp	UseSystemFont

:doPat2Rectangle	jsr	setPattern2
			jmp	Rectangle

;*** Aktuellen Anzeigemodus testen.
.testCurViewMode	pha

			lda	a7L
			beq	:icon

::other			pla				;Text-Modus.
			clc
			rts

::icon			pla				;Icon-Modus.
			sec
			rts

;*** Zuletzt gelöschte Datei speichern.
.setLastDelFile		clc
			lda	#$03
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H

::1			jsr	copyIconFName

			lda	#> buf_TempName
			sta	r2H
			lda	#< buf_TempName
			sta	r2L

			lda	# TRASH_Y0 +4
			sta	r1H
			lda	#> TRASH_CX
			sta	r11H
			lda	#< TRASH_CX
			sta	r11L
			jmp	doPrntTrashName

;*** name gelöschte Datei entfernen.
.clearTrashName		lda	# TRASH_Y0
			sta	r2L
			lda	# TRASH_Y1
			sta	r2H

			lda	#> TRASH_X0
			sta	r3H
			lda	#< TRASH_X0
			sta	r3L

			lda	#> TRASH_X1
			sta	r4H
			lda	#< TRASH_X1
			sta	r4L

			jmp	doPat2Rectangle

:move_r1_r0		lda	r1H
			sta	r0H
			lda	r1L
			sta	r0L
			rts

;*** Tastatur abfragen.
:chkMseCBMkey		lda	#%11001111		;Bit%5=CBM, %4=Mouse.
			bne	chkKeyBoard
.chkStopKey		lda	#%01111111		;Bit%7=STOP.
:chkKeyBoard		sta	r15L

			php
			sei
			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	#%01111111
			sta	cia1base +0		;Port A.
			ldx	cia1base +1		;Port B.

			pla
			sta	CPU_DATA
			plp

			txa
			sec
			sbc	r15L
			rts

;*** DeskTop neu starten?
.chkErrRestartDT	txa
			beq	:ok
			cmp	#CANCEL_ERR
			bne	:err
::ok			rts

::err			jsr	openErrBox1Line
			jmp	restartDeskTop

;*** Diskette erneut öffnen?
.chkErrReopenDisk	txa
			beq	:ok
			cmp	#CANCEL_ERR
			beq	:ok
			pla
			pla
			jsr	testCurDiskReady
			ldx	#$ff
::ok			rts

;*** Laufwerkstyp einlesen.
.get_DrvY_TypeA		ldy	curDrive
			lda	driveType -8,y
			rts

;*** Zeiger in r0 auf ":buf_TempName" setzen.
.r0_buf_TempName	lda	#> buf_TempName
			sta	r0H
			lda	#< buf_TempName
			sta	r0L
			rts

:r1_tabBIconDkNm	lda	#> tabBIconDkNm
			sta	r1H
			lda	#< tabBIconDkNm
			sta	r1L
			rts

:r2_bufTempStr0		lda	#> buf_TempStr0
			sta	r2H
			lda	#< buf_TempStr0
			sta	r2L
			rts

:r2_curDirHeadNm	lda	#> curDirHead +$90
			sta	r2H
			lda	#< curDirHead +$90
			sta	r2L
			ldx	#BAD_BAM
			rts

:r3_bufTempStr1		lda	#> buf_TempStr1
			sta	r3H
			lda	#< buf_TempStr1
			sta	r3L
			rts

.r4_bufDiskSek1		lda	#> buf_diskSek1
			sta	r4H
			lda	#< buf_diskSek1
			sta	r4L
			rts

:r5_bufTempStr2		lda	#> buf_TempStr2
			sta	r5H
			lda	#< buf_TempStr2
			sta	r5L
			rts

:r9_dirEntryBuf		lda	#> dirEntryBuf
			sta	r9H
			lda	#< dirEntryBuf
			sta	r9L
			rts

;*** Laufwerkskonfiguration.
			t "src.DTop.DrvConf"

;*** Startadresse für VLIR-Module.
.vlirModBase
.vlirModSize		= tempDataBuf - vlirModBase
.vlirModEnd		= ( vlirModBase + vlirModSize )

;*** Max. Datenpuffer für FileCopy.
;Nur für "One-Drive-Copy"!
:tempDataBufMax		= icon_TrashCan
:sizeDataBufMax		= (vlirHdrBuf - icon_TrashCan)
