; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Disk-Info.

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
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Laufwerkstreiber.
			t "opt.Disk.Config"
endif

;*** GEOS-Header.
			n "obj.GD60"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xDISKINFO

;*** Programmroutinen.
			t "-Gxx_DiskMaxTr"		;Anzahl Track auf Disk ermitteln.
			t "-Gxx_DiskNewName"		;Diskname ändern.

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Disk-Info anzeigen.
:xDISKINFO		jsr	doGetDiskInfo		;DiskInfo einlesen.
			txa				;Fehler?
			bne	:err			; => Nein, weiter...

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			ldy	#13			;Nur GEOS-Disk V1.

			lda	curType
			cmp	#DrvRAMNM		;RAMNative-Laufwerk?
			bne	:setMenu		; => Nein, weiter...

			ldx	curDrive		;CMD-Laufwerk?
			lda	RealDrvMode -8,x
			and	#SET_MODE_PARTITION
			bne	:setMenu		; => Ja, weiter...

			ldy	#14			;GEOS-Disk V2 aktivieren.
::setMenu		sty	RegTMenu1

			lda	#BOX_OPTION
			bit	geosDiskFlg		;GEOS-Disk?
			bmi	:setOptV2		; => Ja, weiter...
			lda	#BOX_OPTION_VIEW	;"GEOS-Disk V2" deaktivieren.
::setOptV2		sta	RegTMenu1d
endif

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

::err			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			jsr	PurgeTurbo		;TurboDOS entfernen.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			bit	reloadDir		;Disk-Name/GEOS-Disk geändert?
			bmi	:update			; => Ja, Disk aktualisieren...

;--- Hinweis:
;Bei NativeMode wird beim einlesen der
;Disk-Daten das Hauptverzeichnis
;aktiviert, daher am Ende entweder
;die Disk aktualisieren oder nur bei
;Native das Verzeichnis von Disk laden.
			lda	curType
			and	#ST_DMODES
			cmp	#DrvNative		;Native-kompatibles Laufwerk ?
			bne	:2			; => Nein, Ende...
			beq	:1			; => Ja, Verzeichnis neu laden.

::update		jsr	UpdateDisk		;Disk-Name/GEOS-Disk aktualisieren.

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.
			beq	:1			; => Kein Fehler, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

::1			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "X" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;*** Register-Menü.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 2				;Anzahl Einträge.

			w RegTName1			;Register: "DISK-INFO".
			w RegTMenu1

			w RegTName2			;Register: "STATISTIK".
			w RegTMenu2

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RegTName2		w RTabIcon2
			b RCardIconX_2,R1SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

if LANG = LANG_DE
:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif
if LANG = LANG_EN
:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= FALSE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Icons.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

:RIcon_Status		w Icon_Status
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Status_x,Icon_Status_y
			b USE_COLOR_REG

:Icon_Status
<MISSING_IMAGE_DATA>

:Icon_Status_x		= .x
:Icon_Status_y		= .y

:Icon_BadID
<MISSING_IMAGE_DATA>

:Icon_BadID_x		= .x
:Icon_BadID_y		= .y

:Icon_NoStat
<MISSING_IMAGE_DATA>

:Icon_NoStat_x		= .x
:Icon_NoStat_y		= .y

;*** Daten für Register "DISKINFO".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0040
:RTab1_2  = $0048
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $40

:RegTMenu1		b 13

			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_1 +$28 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:RegTMenu1f		b BOX_STRING_VIEW
				w R1T02
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_2
:targetDrvType			w $ffff
				b 16

			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -1
				b RPos1_y +RLine1_2 +8
				w RPos1_x -1
				w RPos1_x +16*8 +8
			b BOX_STRING
				w $0000
				w setReloadDir
				b RPos1_y +RLine1_2
				w RPos1_x
				w targetDrvDisk
				b 16
			b BOX_ICON
				w $0000
				w selectPart
				b RPos1_y +RLine1_2
				w RPos1_x +16*8
				w RIcon_Select
				b NO_OPT_UPDATE

;--- Disk-ID/DOS-Version.
			b BOX_STRING
				w $0000
				w chkDiskID
				b RPos1_y +RLine1_2
				w R1SizeX1 -$10 -$18 -$20 +$01
				w targetDrvDkID
				b 2
			b BOX_STRING_VIEW
				w $0000
				w $0000
				b RPos1_y +RLine1_2
				w R1SizeX1 -$10 -$18 +$01
				w targetDrvDkDOS
				b 2

:RegTMenu1c		b BOX_ICON
				w $0000
				w repair1581DOS
				b RPos1_y +RLine1_2
				w R1SizeX1 -$10 -$08 -$20 +$01
				w RIcon_Status
				b NO_OPT_UPDATE

;--- Speicherplatz.
			b BOX_FRAME
				w R1T08
				w $0000
				b RPos1_y +RLine1_4 -$05
				b RPos1_y +RLine1_4 +$18 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_USEROPT_VIEW
				w R1T07
				w prntDiskFree
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +$07
				w R1SizeX0 +$20
				w R1SizeX1 -$28

;--- GEOS-Format.
:RegTMenu1e		b BOX_OPTION
				w R1T03
				w setOptGEOSv1
				b RPos1_y +RLine1_3
				w RPos1_x
				w geosDiskFlg
				b %11111111
:RegTMenu1a		b BOX_NUMERIC_VIEW
				w R1T06
				w $0000
				b RPos1_y +RLine1_3
				w R1SizeX1 -$10 -$18 -$08 -$18 +$01
				w adrBorderBlock +0
				b 3!NUMERIC_RIGHT!NUMERIC_BYTE
:RegTMenu1b		b BOX_NUMERIC_VIEW
				w $0000
				w $0000
				b RPos1_y +RLine1_3
				w R1SizeX1 -$10 -$18 +$01
				w adrBorderBlock +1
				b 3!NUMERIC_RIGHT!NUMERIC_BYTE

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
:RegTMenu1d		b BOX_OPTION
				w R1T04
				w setOptGEOSv2
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_1
				w geosDiskV2Flg
				b %11111111
endif

;*** Texte für Register "DISKINFO".
if LANG = LANG_DE
:R1T01			b "DISKETTE",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Laufwerk:",NULL
endif
if LANG = LANG_EN
:R1T01			b "DISK",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Drive type:",NULL
endif

;--- GEOS-Disk V1.
if LANG!TEST_RAMNM_SHARED = LANG_DE!SHAREDDIR_DISABLED
:R1T03			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "GEOS-Format",NULL
endif
if LANG!TEST_RAMNM_SHARED = LANG_EN!SHAREDDIR_DISABLED
:R1T03			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "GEOS format",NULL
endif

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
:R1T03			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "GEOS V1",NULL
:R1T04			w RPos1_x +RTab1_1 +$0c
			b RPos1_y +RLine1_3 +$06
			b "V2",NULL
endif

:R1T06			w RPos1_x +$64
			b RPos1_y +RLine1_3 +$06
			b "Border:",NULL

;--- Speicherplatz.
:R1T07			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "0%"
			b GOTOXY
			w R1SizeX1 -$28 +$04
			b RPos1_y +RLine1_4 +$06
			b "100%"
			b GOTOXY
			w R1SizeX0 +$10
			b RPos1_y +RLine1_4 +$10
			b "Max:"

if LANG = LANG_DE
			b GOTOXY
			w R1SizeX0 +$10 +$66
			b RPos1_y +RLine1_4 +$10
			b "Frei:",NULL

:R1T08			b "SPEICHER",NULL
endif
if LANG = LANG_EN
			b GOTOXY
			w R1SizeX0 +$10 +$66
			b RPos1_y +RLine1_4 +$10
			b "Free:",NULL

:R1T08			b "DISK SPACE",NULL
endif

;*** Daten für Register "STATISTIK".
:RPos2_x  = R1SizeX0 +$10
:RPos2_y  = R1SizeY0 +$10
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $20
:RLine2_4 = $40
:RLine2_5 = $50

:RegTMenu2		b 7

			b BOX_FRAME
				w R2T01
				w $0000
				b RPos2_y -$04
				b RPos2_y +RLine2_3 +$08 +$03
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_FRAME
				w R2T05
				w initDiskFileInfo
				b RPos2_y +RLine2_4 -$04
				b RPos2_y +RLine2_5 +$08 +$03
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_NUMERIC_VIEW
				w R2T02
				w $0000
				b RPos2_y +RLine2_1
				w R1SizeX1 -$10 -$28 +1
				w countFiles
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW
				w R2T03
				w $0000
				b RPos2_y +RLine2_2
				w R1SizeX1 -$10 -$28 +1
				w countDir
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW
				w R2T04
				w $0000
				b RPos2_y +RLine2_3
				w R1SizeX1 -$10 -$28 +1
				w countWrProt
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW
				w R2T06
				w $0000
				b RPos2_y +RLine2_4
				w R1SizeX1 -$10 -$28 +1
				w countBASIC
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW
				w R2T07
				w $0000
				b RPos2_y +RLine2_5
				w R1SizeX1 -$10 -$28 +1
				w countGEOS
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

;*** Texte für Register "STATISTIK".
if LANG = LANG_DE
:R2T01			b "STATISTIK"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Bitte warten...",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Anzahl Dateien ",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "Anzahl Verzeichnisse",NULL

:R2T04			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "Schreibgeschützt",NULL

:R2T05			b "GEOS",NULL

:R2T06			w RPos2_x
			b RPos2_y +RLine2_4 +$06
			b "Anzahl Nicht-GEOS-Dateien",NULL

:R2T07			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "Anzahl GEOS-Dateien",NULL
endif
if LANG = LANG_EN
:R2T01			b "STATISTICS"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Please wait...",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Number of files",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_2 +$06
			b "Number of directories",NULL

:R2T04			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "Write protected",NULL

:R2T05			b "GEOS",NULL

:R2T06			w RPos2_x
			b RPos2_y +RLine2_4 +$06
			b "Number of not-GEOS files",NULL

:R2T07			w RPos2_x
			b RPos2_y +RLine2_5 +$06
			b "Number of GEOS files",NULL
endif

;*** Disk-Info einlesen.
; Info:
; - Laufwerkstyp
; - Disketten-Name
; - GEOS-Disk
; - Gesamt/Freier Speicher
; Statistik:
; - Anzahl Dateien/Verzeichnisse
; - Anzahl Schreibgeschütze Dateien
; - Anzahl Nicht-GEOS/GEOS-Dateien
:doGetDiskInfo		lda	#"?"			;Diskinformationen löschen.
			sta	targetDrvDisk

			lda	#"6"
			sta	targetDrvDkID +0
			lda	#"4"
			sta	targetDrvDkID +1

			lda	#"1"
			sta	targetDrvDkDOS +0
			lda	#"A"
			sta	targetDrvDkDOS +1

			lda	#$00
			sta	geosDiskFlg
			sta	adrBorderBlock +0
			sta	adrBorderBlock +1

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			sta	startUpDirTr
			sta	startUpDirSe
endif

			tax
::init			sta	countFiles,x
			inx
			cpx	#5*2
			bcc	:init

			jsr	OpenDisk
			txa				;Fehler?
			bne	:error			; => Ja, Ende...

			ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen und
			sta	targetDrvMode		;zwischenspeichern.
			and	#SET_MODE_SUBDIR	;NativeMode?
			beq	:getID			; => Nein, weiter...

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			lda	curDirHead +$20
			sta	startUpDirTr
			lda	curDirHead +$21
			sta	startUpDirSe
endif

			jsr	OpenRootDir		;Native: ROOT-Verzeichnis öffnen.
			txa				;Fehler?
			beq	:getID			; => Nein, weiter...

::error			rts				;Diskfehler, Abbruch...

::getID			lda	curDirHead +162		;Aktuelle Disk-ID einlesen.
			sta	targetDrvDkID +0
			lda	curDirHead +163
			sta	targetDrvDkID +1

			lda	curType
			and	#%00000111
			cmp	#Drv1581		;1581-kompatibles Laufwerk ?
			bne	:1			; => Nein, weiter...

			jsr	test1581DOS		;DOS-Kennung testen.

::1			jsr	setStatusIcon		;Status-Icon für Laufwerk setzen.

			lda	curDirHead +25 +140
			sta	targetDrvDkDOS +0
			lda	curDirHead +26 +140
			sta	targetDrvDkDOS +1	;Aktuelle DOS-Kennung einlesen.

			ldy	curDrive		;Laufwerks-Adresse einlesen.
			lda	gd_bufadr_lo -8,y
			sta	targetDrvType +0
			lda	gd_bufadr_hi -8,y
			sta	targetDrvType +1	;Zeiger auf Laufwerkstyp setzen.

			ldx	#r0L			;Zeiger auf Disk-Name setzen.
			jsr	GetPtrCurDkNm

			LoadW	r1,targetDrvDisk

			ldx	#r0L			;Disk-Name in Zwischenspeicher
			ldy	#r1L			;kopieren.
			jsr	SysCopyName

			lda	isGEOS			;Status "GEOS-Diskette" kopieren.
			tax
			stx	geosDiskFlg
			beq	:3

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			lda	curDirHead +218		;"2"
			eor	curDirHead +219		;"."
			eor	curDirHead +220		;"0"
			cmp	#$2c			;"Shared/Dir" vorhanden?
			bne	:2			; => Nein, weiter...

			stx	geosDiskV2Flg
			stx	geosDiskV2orig
endif

::2			lda	curDirHead +171
			ldx	curDirHead +172

::3			sta	adrBorderBlock +0
			stx	adrBorderBlock +1

			jsr	getMaxTracks		;Max. Anzahl Tracks einlesen.

;			jsr	getDiskFileInfo		;Datei-Statistiken einlesen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Ende...

			ldx	#NO_ERROR		; => Kein Fehler...
::exit			rts				;Ende.

;*** Datei-Statistiken einlesen.
:initDiskFileInfo	lda	countFiles +0
			ora	countFiles +1		;Statistiken bereits eingelesen?
			beq	getDiskFileInfo		; => Nein, weiter...
			ldx	#NO_ERROR		; => Ja, Ende...
			rts

:getDiskFileInfo	jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:testEndOfDir		; => Ja, weiter...

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			and	#ST_FMODES		;"Gelöscht"?
			beq	:next_file		; => Ja, nächste Datei...

			ldy	#30 -1			;Verzeichnis-Eintrag in
::1			lda	(r5L),y			;Zwischenspeicher kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:1

			jsr	getFileStats		;Daten auswerten.

			lda	targetDrvMode		;Laufwerks-Modus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Verzeichnis?
			beq	:next_file		; => Nein, nächste Datei.

			lda	dirEntryBuf
			and	#ST_FMODES		;Dateityp einlesen.
			cmp	#DIR			;Verzeichnis?
			bne	:next_file		; => Nein, nächste Datei.

;--- Unterverzeichnis öffnen.
			lda	dirEntryBuf +1		;Tr/Se auf Verzeichnis-Header
			sta	r1L			;einlesen.
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			beq	getDiskFileInfo		; => Nein, weiter...
::error			rts				;Fehler, Abbruch.

;--- Weiter mit nächsten Eintrag.
::next_file		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Ende ROOT-Verzeichnis erreicht?
::testEndOfDir		lda	targetDrvMode		;Laufwerks-Modus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Verzeichnis?
			beq	:exit			; => Nein, Ende...

			lda	curDirHead +32		;Aktuelles Verzeichnis gleich
			cmp	#$01			;ROOT-Verzeichnis?
			bne	:2
			lda	curDirHead +33
			cmp	#$01
			beq	:exit			; => Ja, Ende...

::2			lda	curDirHead +36		;Zeiger auf Tr/Se im Verzeichnis-
			sta	r1L			;Eintrag Elternverzeichnis setzen.
			lda	curDirHead +37
			sta	r1H

			lda	curDirHead +38		;Zeiger auf Byte für Verzeichnis-
			sta	r5L			;Eintrag in Sektor setzen.
			lda	#>diskBlkBuf
			sta	r5H

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			lda	curDirHead +34		;Zurück zum vorherigen
			sta	r1L			;Verzeichnis.
			lda	curDirHead +35
			sta	r1H
			jsr	OpenSubDir

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Verzeichnis-Ende erreicht.
::exitDirectory		jmp	:next_file		; => Weiter im Unterverzeichnis.

;--- Verzeichnis bearbeitet.
::exit			ldx	#NO_ERROR
			rts				;Ende.

;*** Verzeichnis-Eintrag auswerten.
; Statistik:
; - Anzahl Dateien/Verzeichnisse
; - Anzahl Schreibgeschütze Dateien
; - Anzahl Nicht-GEOS/GEOS-Dateien
:getFileStats		lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#%0100 0000		;Schreibschutz aktiv?
			beq	:1			; => Nein, weiter...

			IncW	countWrProt		;Zähler Schreibschutz +1.

::1			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Bits isolieren.
			cmp	#DIR			;Verzeichnis?
			bne	:2			; => Nein, weiter...

			IncW	countDir		;Zähler Verzeichnisse +1.
			rts

::2			IncW	countFiles		;Zähler Dateien +1.

			lda	dirEntryBuf +22		;GEOS-Dateityp einlesen.
			bne	:3			; => GEOS-Datei, weiter...

			IncW	countBASIC		;Zähler BASIC-Dateien +1.
			jmp	:4			; => Weiter...

::3			IncW	countGEOS		;Zähler GEOS-Dateien +1.

::4			rts				;Ende.

;*** Speichernutzung ausgeben.
;
;Größe für Balken/Speichernutzung:
:minBarX = R1SizeX0 +$20
:maxBarX = R1SizeX1 -$28
;
:prntDiskFree		jsr	OpenDisk		;Diskette für CalcBlksFree öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Ende...

;--- Hinweis:
;OpenDisk ist hier erforderlich um
;sicherzustellen das BAM im Speicher
;aktuell ist. Sonst liefert die
;Routine CalcBlksFree falsche Werte.
			LoadW	r5,curDirHead		;Zeiger auf aktuelle BAM.
			jsr	CalcBlksFree		;Anzahl freie Blocks berechnen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			rts

::1			lda	r3L			;Anzahl belegte Blocks
			sec				;berechnen.
			sbc	r4L
			sta	r5L
			lda	r3H
			sbc	r4H
			sta	r5H

			PushW	r4			;Anzahl belegte Blocks/Gesamt für
			PushW	r3			;Ausgabe KBytes zwischenspeichern.

			PushW	r4			;Anzahl belegte Blocks/Gesamt für
			PushW	r3			;Ausgabe Blocks zwischenspeichern.

			CmpW	r3,r4			;Anzahl Frei = Gesamt?
			bne	:2			; => Nein, weiter...
			jmp	prntSekInfo		;Disk leer, nur Werte ausgeben.

;--- Speicherübersicht ausgeben.
::2			lda	r4L			;Disk voll?
			ora	r4H
			bne	:3			; => Nein, weiter...

			sta	r8L			;Rest-Wert Infobalken löschen für
			sta	r8H			;"Ganzen Balken füllen".
			beq	:4			;Infobalken darstellen.

;--- Prozentwert für Infobalken berechnen.
::3			LoadW	r6,(maxBarX-minBarX)
			ldx	#r3L
			ldy	#r6L
			jsr	Ddiv			;Gesamt/Breite_Balken.

			PushW	r8			;Restwert sichern.

			ldx	#r5L
			ldy	#r3L
			jsr	Ddiv			;Belegt/(Gesamt/Breite_Balken)

			PopW	r8			;Restwert zurücksetzen.

			lda	r5L			;Prozentwert = 0?
			ora	r5H
			beq	prntSekInfo		; => Ja, Nur Gesamt/Frei ausgeben.

			lda	r5L			;Ende Füllwert für Infobalken
			clc				;berechnen.
			adc	#< minBarX
			sta	r4L
			lda	r5H
			adc	#> minBarX
			sta	r4H

			CmpWI	r4,maxBarX		;Füllwert > Breite_Balken?
			bcc	:5			; => Nein, weiter...

::4			LoadW	r4,maxBarX		;Max. Breite Füllwert setzen.

::5			CmpWI	r4,minBarX		;Rechter Rand = Linker Rand ?
			beq	prntSekInfo		; => Ja, keinen Balken anzeigen.

			LoadB	r2L,RPos1_y +RLine1_4
			LoadB	r2H,RPos1_y +RLine1_4 +$07
			LoadW	r3,minBarX

			lda	#$02			;Füllmuster setzen.
			jsr	SetPattern

			jsr	Rectangle		;Infobalken füllen.

;--- Gsamt/Freier Speicher ausgeben.
:prntSekInfo		PopW	r0			;Max. Blocks.
			LoadB	r1H,RPos1_y +RLine1_4 +$08 +$08
			LoadW	r11,R1SizeX0 +$2c
			jsr	:doBlocks

			PopW	r0			;Freie Blocks.
			LoadW	r11,R1SizeX0 +$60 +$38
			jsr	:doBlocks

			PopW	r0			;Max. KByte.
			LoadB	r1H,RPos1_y +RLine1_4 +$08 +$12
			LoadW	r11,R1SizeX0 +$2c
			jsr	:doKByte

			LoadW	r0,textSpacer
			jsr	PutString

			lda	maxTrack
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Zahl ausgeben.

			LoadW	r0,textTR
			jsr	PutString

			PopW	r0			;Freie KByte.
			LoadW	r11,R1SizeX0 +$60 +$38
			jmp	:doKByte

;--- Zahl "0 Blks" ausgeben.
::doBlocks		lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Zahl ausgeben.

			LoadW	r0,textBlks		;Text "Blks" ausgeben.
			jmp	PutString

;--- Zahl "0 Kb" ausgeben.
::doKByte		ldx	#r0L			;Blocks in KByte umrechnen.
			ldy	#$02
			jsr	DShiftRight

			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Zahl ausgeben.

			LoadW	r0,textKB		;Text "KByte" ausgeben.
			jmp	PutString

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
;*** Registermenü aktualisieren.
:setOptGEOSv2		bit	geosDiskV2Flg		;"GEOS-Disk V2"?
			bpl	setOptGEOSv1		; => Nein, weiter...

			lda	#$ff			;"GEOS-Disk V1" aktivieren.
			sta	geosDiskFlg

			LoadW	r15,RegTMenu1e		;"GEOS-Disk V1" aktualisieren.
			jsr	RegisterUpdate

:setOptGEOSv1		bit	geosDiskFlg		;GEOS-Diskette zurücksetzen?
			bmi	:1			; => Nein, weiter...

			lda	#$00			;Adresse Borderblock löschen.
			sta	adrBorderBlock +0
			sta	adrBorderBlock +1

			LoadW	r15,RegTMenu1a		;Anzeige Borderblock
			jsr	RegisterUpdate		;aktualisieren.
			LoadW	r15,RegTMenu1b
			jsr	RegisterUpdate

::1			lda	#BOX_OPTION
			bit	geosDiskFlg		;GEOS-Diskette?
			bmi	:2			; => Ja, weiter...

			lda	#NULL			;Option GEOSv2 deaktivieren.
			sta	geosDiskV2Flg
			lda	#BOX_OPTION_VIEW

::2			sta	RegTMenu1d		;Registeroption festlegen.

			LoadW	r15,RegTMenu1d		;"GEOS-Disk V2" aktualisieren.
			jsr	RegisterUpdate
endif

;--- GEOS-Disk V1.
if TEST_RAMNM_SHARED = SHAREDDIR_DISABLED
:setOptGEOSv1		= setReloadDir
endif

;*** Diskette aktualiseren.
:UpdateDisk		LoadW	r10,targetDrvDisk
			jsr	saveDiskName		;Disk-name in BAM übertragen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			bit	idUpdateFlg		;Disk-ID aktualisieren ?
			bpl	:11			; => Nein, weiter...
			jsr	saveDiskID		;Disk-ID/DOS-Kennung aktualisieren.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::11			lda	geosDiskFlg
			cmp	isGEOS			;"GEOS-Disk V1"-Status geändert?
			bne	:updDiskGEOS		; => Ja, Diskette anpassen.

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			lda	geosDiskV2Flg
			cmp	geosDiskV2orig		;"GEOS-Disk V2"-Status geändert?
			bne	:testGEOSv2		; => Nein, Ende..
endif

;			ldx	#NO_ERROR		;Keine Änderung, Ende...
::err			rts

;--- GEOS-Diskette ändern.
::updDiskGEOS		tax				;GEOS-Disk erstellen?
			bne	:setGEOSv1		; => Ja, weiter...

::clrGEOS		jmp	delGEOSHdr		;GEOS-Disk löschen.

::setGEOSv1		jsr	SetGEOSDisk		;GEOS-Disk erzeugen.

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			txa				;GEOS-Disk erstellt?
			bne	:exit			; => Nein, Abbruch...

::testGEOSv2		bit	geosDiskV2Flg		;V2-Diskette erstellen?
			bmi	:setGEOSv2		; => Ja, weiter...

::clrGEOSv2		lda	#NULL			;V2-Kennung löschen.
			sta	curDirHead +218
			sta	curDirHead +219
			sta	curDirHead +220
			tax
			beq	:setDirAdr

::setGEOSv2		lda	#1			;Hauptverzeichnis?
			cmp	startUpDirTr
			bne	:21
			cmp	startUpDirSe
			beq	:exit			; => Ja, Ende...

::21			jsr	moveBorderFiles		;Dateien im Borderblock löschen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	startUpDirTr
			sta	r1L
			lda	startUpDirSe
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Verzeichnis-Header einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	#"2"			;"GEOS-Disk V2"-Kennung erzeugen.
			sta	curDirHead +218
			lda	#"."
			sta	curDirHead +219
			lda	#"0"
			sta	curDirHead +220

			lda	diskBlkBuf +0		;Zeiger auf Shared/Dir setzen.
			ldx	diskBlkBuf +1

::setDirAdr		sta	curDirHead +203
			stx	curDirHead +204

			jsr	PutDirHead		;Disk-Header aktualisieren.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...
endif

::exit			rts				;Ende.

;*** Borderblock: GEOS-Header löschen.
:delGEOSHdr		jsr	moveBorderFiles		;Dateien im Borderblock löschen.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

			lda	curDirHead +171
			beq	:1			; => Nein, weiter...
			sta	r6L
			lda	curDirHead +172
			sta	r6H
			jsr	FreeBlock		;Borderblock freigeben.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

::1			lda	#$00			;GEOS-Kennung löschen.
			sta	isGEOS

			ldy	#173
::2			sta	curDirHead,y
			iny
			cpy	#173 +16
			bcc	:2

;			lda	#$00
			sta	curDirHead +171		;Adresse Borderblock löschen.
			sta	curDirHead +172
			sta	curDirHead +189		;Diskettentyp löschen.

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
			sta	curDirHead +218		;"GEOS-Disk V2"-Kennung löschen.
			sta	curDirHead +219
			sta	curDirHead +220

			sta	curDirHead +203		;Adresse Shared/Dir löschen.
			sta	curDirHead +204
endif

			jsr	PutDirHead		;BAM speichern.
;			txa				;Fehler?
;			bne	:3			; => Ja, Abbruch...

::3			rts				;Abbruch...

;*** Borderblock: Dateien retten.
:moveBorderFiles	ldx	curDirHead +171		;Borderblock vorhanden?
			beq	:exit			; => Nein, weiter...
			stx	r1L
			lda	curDirHead +172
			sta	r1H
			LoadW	r4,borderBlock
			jsr	GetBlock		;Borderblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	#$ff
			sta	r10L			;Update-Flag Borderblock löschen.

			ldy	#2			;Zeiger auf ersten Eintrag.
::loop			sty	r10H

			lda	borderBlock,y		;Datei belegt?
			beq	:next			; => Nein, weiter...

			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Fehler?
			bne	:done			; => Ja, Abbruch...

			lda	#30
			sta	r0L

			ldx	r10H
::copy			lda	borderBlock,x		;Verzeichniseintrag vom Borderblock
			sta	diskBlkBuf,y		;in Verzeichnis verschieben.
			lda	#$00			;Eintrag im Borderblock löschen.
			sta	borderBlock,x
			inx
			iny
			dec	r0L
			bne	:copy

;			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnisblock aktualisieren.
			txa				;Fehler?
			bne	:done			; => Ja, Abbruch...

			sta	r10L			;Borderblock aktualisieren.

::next			lda	r10H
			clc
			adc	#32			;Zeiger auf nächste Datei.
			tay				;Letzte Datei?
			bcc	:loop			; => Nein, weiter...

::done			bit	r10L			;Dateien verschoben?
			bmi	:exit			; => Nein, weiter...

			txa				;Fehlerstatus speichern.
			pha

			lda	curDirHead +171
			sta	r1L
			lda	curDirHead +172
			sta	r1H
			LoadW	r4,borderBlock
			jsr	PutBlock		;Borderblock aktualisieren.

			pla
			cpx	#NO_ERROR		;Borderblock gespeichert?
			bne	:exit			; => Nein, Abbruch...

			tax				;Alle Dateien verschoben?
;			bne	:exit			; => Nein, Abbruch...

;			jsr	PutDirHead		;BAM aktualisieren -> ":delGEOSHdr".
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** Disk-ID geändert.
:chkDiskID		bit	r1L
			bpl	:exit

			jsr	setReloadDir		;Verzeichnis neu laden.

;			lda	#$ff
			sta	idUpdateFlg		;Disk-ID aktualisieren.
			sta	dosReadyFlg		;DOS-Kennung ungültig.

			jsr	setStatusIcon		;Status-Icon für Laufwerk setzen.

			LoadW	r15,RegTMenu1c		;Status-Icon aktualisieren.
			jsr	RegisterUpdate

::exit			rts

;*** Disk-ID aktualisieren.
:saveDiskID		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	targetDrvDkID +0	;Disk-ID aktualisieren.
			sta	curDirHead +162
			lda	targetDrvDkID +1
			sta	curDirHead +163

			jsr	PutDirHead		;BAM auf Disk speichern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	curType
			and	#%00000111
			cmp	#Drv1581		;1581-kompatibles Laufwerk ?
			beq	:upd1581		; => Ja, weiter...
			cmp	#DrvNative		;NativeMode-Laufwerk ?
			bne	:exit			; => Nein, weiter...

;--- Sonderbehandlung: NativeMode.
::updNative		ldx	#1			;Zeiger auf Native/BAM-Block #2.
			stx	r1L			;Spur #1.
			inx
			stx	r1H			;Sektor #2.
;			ldx	#< diskBlkBuf
			stx	r4L
			ldx	#> diskBlkBuf
			stx	r4H
			jsr	GetBlock		;BAM-Block #2 einlesen.

			lda	targetDrvDkID +0	;Disk-ID aktualisieren.
			sta	diskBlkBuf +6
			lda	targetDrvDkID +1
			sta	diskBlkBuf +7

			jsr	PutBlock		;BAM-Block #2 speichern.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

			rts

;--- Sonderbehandlung: 1581.
::upd1581		jsr	write1581DOS		;DOS-Kennung auf Disk ändern.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** Status-Icon setzen/löschen.
:setStatusIcon		ldx	#< Icon_NoStat		;Bei 1541/71/Native kein
			ldy	#> Icon_NoStat		;Status-Icon anzeigen.
			lda	dosReadyFlg		;Laufwerk gültig ?
			beq	:set			; => Nein, weiter...
			bmi	:bad			; => Status auf "BAD" setzen.

::ok			ldx	#< Icon_Status		;Status: OK
			ldy	#> Icon_Status
			bne	:set

::bad			ldx	#< Icon_BadID		;Status: BAD
			ldy	#> Icon_BadID

::set			stx	RIcon_Status +0		;Status-Icon speichern.
			sty	RIcon_Status +1
			rts

;*** DOS-Status auf Diskette testen.
:test1581DOS		jsr	getBlockBAM1		;BAM-Block 40/0 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	testBlockBAM1		;DOS-Kennung testen.
			txa				;Gültig ?
			bne	:DOS_BAD		; => Nein, Status = "BAD".

			jsr	getBlockBAM2		;BAM-Block 40/1 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	testBlockBAM2		;DOS-Kennung testen.
			txa				;Gültig ?
			bne	:DOS_BAD		; => Nein, Status = "BAD".

			jsr	getBlockBAM3		;BAM-Block 40/2 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	testBlockBAM2		;DOS-Kennung testen.
			txa				;Gültig ?
			bne	:DOS_BAD		; => Nein, Status = "BAD".

::DOS_OK		lda	#$7f			;Status: OK
			b $2c
::DOS_BAD		lda	#$ff			;Status: BAD
			sta	dosReadyFlg		;Status speichern.
::exit			rts

;*** DOS-Status auf Diskette reparieren.
:repair1581DOS		bit	r1L			;Aufbau Registermenü ?
			bpl	:exit			; => Ja, Ende...
			bit	dosReadyFlg		;DOS-Status "BAD" ?
			bpl	:exit			; => Nein, Ende...

			jsr	setReloadDir		;Verzeichnis neu laden.

			jsr	write1581DOS		;DOS-Kennung auf Disk ändern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	#$7f			;DOS-Kennung gültig.
			sta	dosReadyFlg
			lda	#$00			;Disk-ID ist aktuell.
			sta	idUpdateFlg
			jsr	setStatusIcon		;Status-Icon für Laufwerk setzen.

			LoadW	r15,RegTMenu1c		;Status-Icon aktualisieren.
			jsr	RegisterUpdate

			LoadW	r0,Dlg_UpdateDOS	;Dialogbox anzeigen:
			jsr	DoDlgBox		;"Reparatur erfolgreich!"

::exit			rts

;*** Neue DOS-Kennung speichern.
:write1581DOS		jsr	getBlockBAM1		;BAM-Block 40/0 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	fixBlockBAM1		;DOS-Kennung schreiben.
			jsr	PutBlock		;BAM-Block speichern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	getBlockBAM2		;BAM-Block 40/1 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	fixBlockBAM2		;DOS-Kennung schreiben.
			jsr	PutBlock		;BAM-Block speichern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	getBlockBAM3		;BAM-Block 40/2 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	fixBlockBAM2		;DOS-Kennung schreiben.
			jsr	PutBlock		;BAM-Block speichern.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** 1581/BAM-Block einlesen.
:getBlockBAM1		lda	#0			;BAM-Block #40/0.
			b $2c
:getBlockBAM2		lda	#1			;BAM-Block #40/1.
			b $2c
:getBlockBAM3		lda	#2			;BAM-Block #40/2.
			sta	r1H
			LoadB	r1L,40
			LoadW	r4,diskBlkBuf
			jmp	GetBlock		;BAM-Block einlesen.

;*** 1581/BAM-Block 40/0 testen.
;Byte $02 = "D"
;     $03 = $00
;     $19 = "3" -> Achtung! Unter GEOS ab Byte $A5!
;     $1A = "D" -> Achtung! Unter GEOS ab Byte $A6!
:testBlockBAM1		lda	diskBlkBuf +2
			cmp	#"D"
			bne	:failed
			lda	diskBlkBuf +3
			cmp	#NULL
			bne	:failed
			lda	diskBlkBuf +25 +140
			cmp	#"3"
			bne	:failed
			lda	diskBlkBuf +26 +140
			cmp	#"D"
			bne	:failed

::ok			ldx	#NO_ERROR
			b $2c
::failed		ldx	#BAD_BAM
			rts

;*** 1581/BAM-Block 40/1 und 40/2 testen.
;Byte $02 = "D"
;     $03 = "B"       -> "D" EOR %11111111
;     $04 = ID1
;     $05 = ID2
;     $06 = %11000000 -> I/O-Byte (Verify ON, check header CRC ON)
;     $07 = %00000000 -> AutoLoad (OFF)
;     $08-$0F = Unused
:testBlockBAM2		lda	diskBlkBuf +2
			cmp	#"D"
			bne	:failed
			eor	#%11111111
			cmp	diskBlkBuf +3
			bne	:failed
			lda	diskBlkBuf +4
			cmp	targetDrvDkID +0
			bne	:failed
			lda	diskBlkBuf +5
			cmp	targetDrvDkID +1
			bne	:failed

			lda	diskBlkBuf +6
			cmp	#%11000000		;Verify + Check Header = ON.
			bne	:failed
			lda	diskBlkBuf +7
			cmp	#%00000000		;AutoLoad = OFF.
			bne	:failed

			ldy	#8
::1			lda	diskBlkBuf,y
			bne	:failed
			iny
			cpy	#16
			bcc	:1

::ok			ldx	#NO_ERROR
			b $2c
::failed		ldx	#BAD_BAM
			rts

;*** 1581/BAM-Block 40/0 reparieren.
;Byte $02 = "D"
;     $03 = $00
;     $16 = ID1 -> Achtung! Unter GEOS ab Byte $A2!
;     $17 = ID2 -> Achtung! Unter GEOS ab Byte $A3!
;     $19 = "3" -> Achtung! Unter GEOS ab Byte $A5!
;     $1A = "D" -> Achtung! Unter GEOS ab Byte $A6!
:fixBlockBAM1		lda	#"D"
			sta	diskBlkBuf +2
			lda	#NULL
			sta	diskBlkBuf +3
			lda	#"3"
			sta	diskBlkBuf +25 +140
			lda	#"D"
			sta	diskBlkBuf +26 +140

			lda	targetDrvDkID +0
			sta	diskBlkBuf +22 +140
			lda	targetDrvDkID +1
			sta	diskBlkBuf +23 +140

			lda	#NULL
			ldy	#$04
::1			sta	diskBlkBuf,y
			iny
			cpy	#$90
			bcc	:1

;			lda	#NULL
			ldy	#$bd			;$AB-$AC = GEOS-Info.
::2			sta	diskBlkBuf,y
			iny
;			cpy	#$ff +1
			bne	:2

			rts

;*** 1581/BAM-Block 40/1 und 40/2 reparieren.
;Byte $02 = "D"
;     $03 = "B"       -> "D" EOR %11111111
;     $04 = ID1
;     $05 = ID2
;     $06 = %11000000 -> I/O-Byte (Verify ON, check header CRC ON)
;     $07 = %00000000 -> AutoLoad (OFF)
;     $08-$0F = Unused
:fixBlockBAM2		lda	#"D"
			sta	diskBlkBuf +2
			eor	#%11111111
			sta	diskBlkBuf +3
			lda	targetDrvDkID +0
			sta	diskBlkBuf +4
			lda	targetDrvDkID +1
			sta	diskBlkBuf +5

			lda	#%11000000		;Verify + Check Header = ON.
			sta	diskBlkBuf +6
			lda	#%00000000		;AutoLoad = OFF.
			sta	diskBlkBuf +7

;			lda	#NULL			;Ungenutzte Datenbytes löschen.
			ldy	#$08
::1			sta	diskBlkBuf,y
			iny
			cpy	#$10
			bne	:1

			rts

;*** Partition wählen.
:selectPart		bit	r1L
			bpl	:exit

			jsr	setReloadDir		;Verzeichnis neu laden.

			ldx	curDrive
			lda	RealDrvMode -8,x
			and	#SET_MODE_PARTITION
			bpl	:open

			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Partition auswählen.

::open			lda	#$00
			sta	countFiles +0
			sta	countFiles +1

			jsr	doGetDiskInfo		;Diskinformationen einlesen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

			jsr	RegisterAllOpt		;Menü aktualisieren.

::exit			rts

;*** Variablen.
:countFiles		w $0000
:countDir		w $0000
:countBASIC		w $0000
:countGEOS		w $0000
:countWrProt		w $0000

:adrBorderBlock		b $00,$00

:targetDrvMode		b $00
:targetDrvDisk		s 17
:targetDrvDkID		s 3
:targetDrvDkDOS		s 3

:idUpdateFlg		b $00
:dosReadyFlg		b $00
:geosDiskFlg		b $00

;--- Zeiger auf Laufwerkstypen.
:gd_bufadr_lo		b < GD_DRVTYPE_A
			b < GD_DRVTYPE_B
			b < GD_DRVTYPE_C
			b < GD_DRVTYPE_D
:gd_bufadr_hi		b > GD_DRVTYPE_A
			b > GD_DRVTYPE_B
			b > GD_DRVTYPE_C
			b > GD_DRVTYPE_D

;--- GEOS-Disk V2.
if TEST_RAMNM_SHARED = SHAREDDIR_ENABLED
:geosDiskV2Flg		b $00
:geosDiskV2orig		b $00

:startUpDirTr		b $00
:startUpDirSe		b $00
endif

:textBlks		b " Blks",NULL
:textKB			b " Kb",NULL
:textSpacer		b " / ",NULL
:textTR			b " Tr",NULL

;*** GEOS-Header-Kennung.
:textHeader		b "GEOS format V1.0"

;*** Dialogboxen.
:Dlg_UpdateDOS		b %01100001
			b $30,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b OK         ,$11,$40
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "DOS-Kennung auf der Diskette",NULL
::3			b "oder Partition wurde repariert!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "DOS version type on diskette",NULL
::3			b "or partition has been repaired!",NULL
endif

;*** Dialogbox: Partition wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Reservierter Speicher.
;Hinweis: Der reservierte Speicher ist
;nicht initialisiert!

;*** Reservierter Speicher.
:sysMemA

:borderBlock_S		= 256
:borderBlock		= sysMemA

:sysMemE		= borderBlock + borderBlock_S
:sysMemS		= (sysMemE - sysMemA)

;*** Endadresse testen:
			g RegMenuBase - sysMemS
;***
