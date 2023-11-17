; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Disk-Info anzeigen.
:xDISKINFO		jsr	doGetDiskInfo		;DiskInfo einlesen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

			jmp	ExitRegMenuUser		;Zurück zum DeskTop.

::1			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	bit	reloadDir		;Disk-Name/GEOS-Disk geändert?
			bpl	:2			; => Nein, Ende...

			jsr	UpdateDisk		;Disk-Name/GEOS-Disk aktualisieren.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
;			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

::1			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "DiskInfo" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 2				;Anzahl Einträge.

			w RTabName1_1			;Register: "DISK-INFO".
			w RTabMenu1_1

			w RTabName1_2			;Register: "STATISTIK".
			w RTabMenu1_2

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabName1_2		w RTabIcon2
			b RCardIconX_2,R1SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

;*** Icons.
:RIcon_Status		w IconStatus
			b $00,$00
			b IconStatus_x,IconStatus_y
			b $ee ;Farbe Registerkarte.

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DISKINFO".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RWidth1  = $0028
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $40

:RTabMenu1_1		b 10

			b BOX_FRAME			;----------------------------------------
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_1 +$28 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R1T02
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1
				w targetDrvType
				b 16

			b BOX_STRING			;----------------------------------------
				w R1T03
				w setReloadDir
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1
				w targetDrvDisk
				b 16
			b BOX_STRING			;----------------------------------------
				w $0000
				w chkDiskID
				b RPos1_y +RLine1_2
				w R1SizeX1 -$10 -$18 +$01
				w targetDrvDkID
				b 2

:RTabMenu1_1c		b BOX_ICON			;----------------------------------------
				w $0000
				w repair1581DOS
				b RPos1_y +RLine1_2
				w R1SizeX1 -$10 -$08 +$01
				w RIcon_Status
				b $00

			b BOX_OPTION			;----------------------------------------
				w R1T05
				w setReloadDir
				b RPos1_y +RLine1_3
				w RPos1_x
				w geosDiskFlg
				b %11111111
:RTabMenu1_1a		b BOX_NUMERIC_VIEW		;----------------------------------------
				w R1T05a
				w $0000
				b RPos1_y +RLine1_3
				w R1SizeX1 -$10 -$18 -$08 -$18 +$01
				w adrBorderBlock +0
				b 3!NUMERIC_RIGHT!NUMERIC_BYTE
:RTabMenu1_1b		b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_3
				w R1SizeX1 -$10 -$18 +$01
				w adrBorderBlock +1
				b 3!NUMERIC_RIGHT!NUMERIC_BYTE

			b BOX_FRAME			;----------------------------------------
				w R1T06
				w $0000
				b RPos1_y +RLine1_4 -$05
				b RPos1_y +RLine1_4 +$18 +$06
				 w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_USEROPT_VIEW		;----------------------------------------
				w R1T07
				w prntDiskFree
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +$07
				w R1SizeX0 +$20
				w R1SizeX1 -$28

if LANG = LANG_DE
:R1T01			b "DISKETTE/LAUFWERK",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Typ:",NULL

:R1T03			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Name:",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "GEOS-Format",NULL
:R1T05a			w RPos1_x +$60
			b RPos1_y +RLine1_3 +$06
			b "Border:",NULL

:R1T06			b "SPEICHER",NULL

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
			b GOTOXY
			w R1SizeX0 +$10 +$66
			b RPos1_y +RLine1_4 +$10
			b "Frei:",NULL
endif
if LANG = LANG_EN
:R1T01			b "DISK/DRIVE",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Type:",NULL

:R1T03			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Name:",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "GEOS format",NULL

:R1T05a			w RPos1_x +$60
			b RPos1_y +RLine1_3 +$06
			b "Border:",NULL

:R1T06			b "DISK SPACE",NULL

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
			b GOTOXY
			w R1SizeX0 +$10 +$66
			b RPos1_y +RLine1_4 +$10
			b "Free:",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "STATISTIK".
:RPos2_x  = R1SizeX0 +$10
:RPos2_y  = R1SizeY0 +$10
:RWidth2  = $0060
:RLine2_1 = $00
:RLine2_2 = $10
:RLine2_3 = $20
:RLine2_4 = $40
:RLine2_5 = $50

:RTabMenu1_2		b 7

			b BOX_FRAME			;----------------------------------------
				w R2T01
				w $0000
				b RPos2_y -$04
				b RPos2_y +RLine2_3 +$08 +$03
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R2T02
				w $0000
				b RPos2_y +RLine2_1
				w R1SizeX1 -$10 -$28 +1
				w countFiles
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R2T03
				w $0000
				b RPos2_y +RLine2_2
				w R1SizeX1 -$10 -$28 +1
				w countDir
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R2T04
				w $0000
				b RPos2_y +RLine2_3
				w R1SizeX1 -$10 -$28 +1
				w countWrProt
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_FRAME			;----------------------------------------
				w R2T05
				w $0000
				b RPos2_y +RLine2_4 -$04
				b RPos2_y +RLine2_5 +$08 +$03
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R2T06
				w $0000
				b RPos2_y +RLine2_4
				w R1SizeX1 -$10 -$28 +1
				w countBASIC
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R2T07
				w $0000
				b RPos2_y +RLine2_5
				w R1SizeX1 -$10 -$28 +1
				w countGEOS
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

if LANG = LANG_DE
:R2T01			b "STATISTIK",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Anzahl Dateien",NULL

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
:R2T01			b "STATISTICS",NULL

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

;*** Icons für Registerkarten.
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RTabIcon2
if LANG = LANG_DE
<MISSING_IMAGE_DATA>
endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>
endif

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

:IconStatus
<MISSING_IMAGE_DATA>

:IconStatus_x		= .x
:IconStatus_y		= .y

:IconWarn
<MISSING_IMAGE_DATA>

:IconWarn_x		= .x
:IconWarn_y		= .y

:IconOff
<MISSING_IMAGE_DATA>

:IconOff_x		= .x
:IconOff_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x
