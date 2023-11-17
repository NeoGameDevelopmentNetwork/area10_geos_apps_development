; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk Erststart.

if .p
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.IO"
			t "TopSym.GD"
			t "TopMac.GD"
endif

			n "mod.#100.obj"
			t "-SYS_CLASS.h"
			f APPLICATION
			o VLIR_BOOT_START
			p MainInit
			a "Markus Kanet"
			z $80 ;Nur GEOS64.
			i
<MISSING_IMAGE_DATA>

;------------------------------------------------------------------------------
;Reservierter Bereich für System-
;Variablen. Bereich nicht verschieben,
;da Boot/SaveConfig darauf zugreift.
;------------------------------------------------------------------------------
;*** Systemvariablen.
			t "-SYS_VAR"

;*** Programmvariablen.
			t "-101_VarDataGD"
			t "-101_VarDataWM"
;------------------------------------------------------------------------------

;*** Speicherverwaltung.
			t "-SYS_RAM_FREE"
			t "-SYS_RAM_ALLOC"
			t "-SYS_RAM_SHARED"

;*** Systemroutinen.
			t "-SYS_COLCONFIG"

;*** System initialisieren.
:MainInit		lda	MP3_CODE +0		;Auf MP3/G3-Kennung testen.
			cmp	#"M"
			bne	:npmpg3			; => Kein MP3/G3...
			lda	MP3_CODE +1
			cmp	#"P"
			beq	:testgd3active		; => OK, weiter...

;--- Fehler: Kein G3/MP3.
::npmpg3		lda	#<Dlg_NoMP		;Fehlermeldung "Kein MegaPatch!"
			ldx	#>Dlg_NoMP		;ausgeben.
			bne	:syserr

;--- Fehler: Laufwerk nicht erkannt.
::nosdrive		lda	#<Dlg_GeoDeskSDrv	;Fehlermeldung "Kein Laufwerk!"
			ldx	#>Dlg_GeoDeskSDrv	;ausgeben.

;--- Fehler: Kein Speicher frei.
::noram			jsr	FreeGDeskRAM		;GeoDesk-Speicher freigeben.

;--- Fehler ausgeben, zurück zum DeskTop.
::noram_exit		jsr	GetBackScreen		;Bildschirm zurücksetzen.

			lda	#<Dlg_NoFreeRAM		;Fehlermeldung ausgeben:
			ldx	#>Dlg_NoFreeRAM		;"Nicht genügend Speicher"
::syserr		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	EnterDeskTop		;Zurück zum DeskTop Vx.

;--- Testen ob GD3 bereits aktiv.
;Falls ja, GeoDesk aus Speicher löschen
;und neu starten.
::testgd3active		jsr	GetBackScreen		;Hintergrundbild laden.
							;Damit verschwindet beim Boot-
							;Vorgang der graue Bildschirm.

			jsr	SetADDR_EnterDT		;Original EnterDeskTop-Routine
			jsr	FetchRAM		;einlesen.

			ldy	#:GD3CODEPOS		;Auf GD3-Kennung testen.
			ldx	#$00
::3			lda	(r0L),y
			cmp	:GD3CODE,x
			bne	:testram		; => GD3 nicht aktiv, weiter...
			iny
			inx
			cpx	#$04
			bcc	:3

;--- GeoDesk deaktivieren.
;Damit kann auch bei laufendem GeoDesk
;z.B. eine neue Version von GeoDesk
;gestartet werden.
;ACHTUNG! Entwickler-Hinweis:
;Funktioniert nur solange der HEADER
;von APP_RAM bis SYSVAR_END identisch
;ist mit der installierten Version!!!
			ldy	#:ramBakOffset		;64K-Speicherbank aus EnterDeskTop
			lda	(r0L),y			;auslesen und speichern.
			sta	GD_RAM_GDESK1
			jsr	ExitGeoDesk		;GeoDesk aus DACC löschen.

;--- Auf 256K Speicher testen und Menü starten.
::testram		jsr	FindFreeBank		;64K für ScreenBuffer.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			sty	GD_SCRN_STACK
			jsr	AllocateBank		;Speicher reservieren.

			jsr	FindFreeBank		;64K für Bildschirm/Verzeichnis.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			sty	GD_SYSDATA_BUF
			jsr	AllocateBank		;Speicher reservieren.

			jsr	FindFreeBank		;64K/1 für GeoDesk-Desktop.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			sty	GD_RAM_GDESK1
			jsr	AllocateBank		;Speicher reservieren.

			jsr	FindFreeBank		;64K/2 für GeoDesk-Desktop.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			sty	GD_RAM_GDESK2
			jsr	AllocateBank		;Speicher reservieren.

			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:no_cache
			jsr	FindFreeBank		;64K für Icon-Daten.
			cpx	#NO_ERROR		;Speicher gefunden?
			beq	:icon_cache		; => Ja, weiter...

::no_cache		lda	#$00			;Kein Speicher für Icon-Cache
			sta	GD_ICON_CACHE		;frei, Icon-Cache abschalten.
			sta	GD_ICONDATA_BUF
			beq	:continue

::icon_cache		sty	GD_ICONDATA_BUF
			jsr	AllocateBank		;Speicher reservieren.

;--- GeoDesk starten.
::continue		jsr	infoBootGeoDesk		;Boot-Meldung ausgeben.
			jsr	setBootConfig		;Laufwerkskonfiguration speichern.
			beq	:bootOK			;Fehler? => Nein, weiter...
			jmp	:nosdrive		;Abbruch...

;--- Hinweis:
;Routine wurde bereits eingelesen um
;auf aktiven GeoDesk zu testen.
;Allerdings können seither die Register
;r0-r3L verändert worden sein.
::bootOK		jsr	SetADDR_EnterDT		;Original EnterDeskTop-Routine
			jsr	FetchRAM		;einlesen.
			lda	#$00			;Zeiger auf GDesk3-Systemspeicher
			sta	r1L			;im GEOS-DACC setzen.
			sta	r1H
			lda	GD_RAM_GDESK1
			sta	r3L
			jsr	StashRAM		;Original-Routine speichern.

			jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	MP3_COLOR_DATA
			w	GEOS_SYS_COLS_A
			w	(GEOS_SYS_COLS_E - GEOS_SYS_COLS_A)

			jsr	LoadColConfig		;Falls vorhanden > Farbprofil laden.
			jsr	LoadGDesk2RAM		;GDesk3 in RAM laden.

			lda	GD_DACC_ADDR +0		;Startadresse GD3 im GEOS-DACC
			sta	:ramAddrL +1		;in neue EnterDeskTop-Routine
			lda	GD_DACC_ADDR +1		;kopieren.
			sta	:ramAddrH +1
			lda	GD_DACC_ADDR +2
			sta	:ramSizeL +1
			lda	GD_DACC_ADDR +3
			sta	:ramSizeH +1
			lda	GD_RAM_GDESK1
			sta	:ramBank +1

			jsr	SetADDR_EnterDT		;Neue EnterDeskTop-Routine
			LoadW	r0,:GDeskEnterDT	;installieren.
			jsr	StashRAM

			lda	#$00			;GDesk3 bereits im Speicher.
			sta	r0L			;Hauptprogramm starten.
			LoadW	r7,APP_RAM
			jmp	StartAppl

;--- Neue EnterDeskTop-Routine.
;ACHTUNG! Die Routine ist Relokatibel!
;Keine absoluten Adressen verwenden!
::GDeskEnterDT		sei				;GEOS initialisieren.
			cld
			ldx	#$ff
			stx	firstBoot
			txs
			jsr	GEOS_InitSystem
			jsr	ResetScreen

			lda	#<APP_RAM		;GDesk3-Hauptprogramm laden.
			sta	r0L
			lda	#>APP_RAM
			sta	r0H
::ramAddrL		lda	#$00
			sta	r1L
::ramAddrH		lda	#$00
			sta	r1H
::ramSizeL		lda	#$00
			sta	r2L
::ramSizeH		lda	#$00
			sta	r2H
::ramBank		lda	#$00
			sta	r3L
			jsr	FetchRAM
			lda	#$00			;GeoDesk3-Hauptprogramm starten.
			sta	r0L
			LoadW	r7,GD_ENTER_DT
			jmp	StartAppl

::ramBakOffset		= (:ramBank-:GDeskEnterDT) +1

;--- Kennung für GD3-DeskTop aktiv.
::GD3CODE		b "GD3",NULL

;--- Füllbytes.
::dummy			s $0200 - (:dummy - :GDeskEnterDT)

;--- Zeiger auf GD3-Kennung innerhalb der neuen EnterDT-Routine.
::GD3CODEPOS		= ( :GD3CODE - :GDeskEnterDT )

;*** GeoDesk beenden.
;    Übergabe: GD_RAM_GDESK1/2 = 128K Speicher für GeoDesk.
:ExitGeoDesk		jsr	SetADDR_EnterDT		;Original EnterDeskTop-Routine
			lda	#$00			;aus dem Speicher holen und
			sta	r1L			;wieder im System installieren.
			sta	r1H
			lda	GD_RAM_GDESK1
			sta	r3L
			jsr	FetchRAM
			jsr	SetADDR_EnterDT
			jsr	StashRAM

;--- Systemvariablen GeoDesk einlesen.
;Damit holt sich der Boot-Loader die
;Informationen über die verwendeten
;Speicherbänke im laufenden GeoDesk.
			LoadW	r0,APP_RAM +GD_JMPTBL_COUNT*3
			LoadW	r1,GD_START_DACC +GD_JMPTBL_COUNT*3
			LoadW	r2,(SYSVAR_END - SYSVAR_START)
			lda	GD_RAM_GDESK1
			sta	r3L
			jsr	FetchRAM

			jsr	i_MoveData		;Variablen übernehmen.
			w	APP_RAM +GD_JMPTBL_COUNT*3
			w	SYSVAR_START
			w	(SYSVAR_END - SYSVAR_START)

;*** GeoDesk-Speicher freigeben.
:FreeGDeskRAM		ldy	GD_SCRN_STACK		;Speicher für ScreenBuffer
			beq	:1			;freigeben.
			jsr	FreeBank

::1			ldy	GD_SYSDATA_BUF		;Speicher für Desktop- und
			beq	:2			;Verzeichnisdaten freiegebn.
			jsr	FreeBank

::2			ldy	GD_RAM_GDESK1		;Speicher #1 für GeoDesk-Desktop
			beq	:3			;freigeben.
			jsr	FreeBank

::3			ldy	GD_RAM_GDESK2		;Speicher #2 für GeoDesk-Desktop
			beq	:4			;freigeben.
			jsr	FreeBank

::4			ldy	GD_ICONDATA_BUF		;Speicher für Icon-Daten
			beq	:5			;freigeben.
			jsr	FreeBank
::5			rts

;*** Boot-Meldung ausgeben.
:infoBootGeoDesk	lda	#ST_WR_FORE
			sta	dispBufferOn

			jsr	i_GraphicsString	;Boot-Meldung ausgeben.
			b	NEWPATTERN
			b	$00
			b	MOVEPENTO
			w	$0000
			b	$b8
			b	RECTANGLETO
			w	$013f
			b	$c7
			b	FRAME_RECTO
			w	$0000
			b	$b8
			b	ESC_PUTSTRING
			w	$0008
			b	$c2
			b	PLAINTEXT
			b	BOLDON
if LANG = LANG_DE
			b	"GeoDesk wird gestartet..."
endif
if LANG = LANG_EN
			b	"Loading GeoDesk..."
endif
			b	NULL

			lda	C_WinBack
			jsr	i_UserColor
			b	$00,$17,$28,$02

			rts

;*** Laufwerkskonfiguration übernehmen.
:setBootConfig		lda	curDrive		;Startlaufwerk speichern.
			sta	BootDrive
			sta	LinkDrive
			jsr	SetDevice
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

;--- Hinweis:
;Der folgende Code umgeht ein Problem
;mit MegaPatch V3.3r6 und einer CMD-FD:
;Direkt nach dem Boot-Vorgang ist die
;Adresse ":drivePartData" noch nicht
;initialisiert. In dem Fall kann das
;Programm die Einstellungen nicht mehr
;speichern da die Partition=0 ist.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

;--- Hinweis:
;Ab V3.3r7/2020.11.10 sollte das durch
;":OpenDisk" behoben sein.
			ldx	curDrive
			lda	drivePartData -8,x
			bne	:0			; => Partition bereits bekannt...

;--- Hinweis:
;Problem nicht behoben, V3.3r6 oder
;früher.
			lda	RealDrvMode -8,x
			and	#%10000000		;CMD-Laufwerk?
			beq	:0			; => Nein, weiter...
			lda	driveType -8,x		;RAMLink?
			bmi	:0			; => Ja, weiter...

			lda	#$ff			;Aktive Partition ermitteln.
			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldx	curDrive		;Partitionsnummer speichern.
			lda	dirEntryBuf +2
			sta	drivePartData -8,x

::0			lda	ramBase -8,x
			sta	BootRBase
			sta	LinkRBase

			lda	RealDrvType -8,x	;Laufwerkstyp sichern.
			sta	BootType
			sta	LinkType

			lda	RealDrvMode -8,x	;Laufwerksmodi sichern.
			sta	BootMode
			sta	LinkMode
			and	#%10000000		;CMD-Laufwerk?
			beq	:1			; => Nein, weiter...
			lda	drivePartData-8,x	;Aktuelle Partition sichern.
::1			sta	BootPart
			sta	LinkPart

			lda	RealDrvMode -8,x
			and	#%01000000		;NativeMode?
			tax
			beq	:2			; => Nein, weiter...
			lda	curDirHead +32		;Aktuellen Verzeichnis-Header
			ldx	curDirHead +33		;sichern.
::2			sta	BootSDir +0
			stx	BootSDir +1
			sta	LinkSDir +0
			stx	LinkSDir +1

			ldx	#NO_ERROR
::err			rts

;*** GDesk3 in GEOS-DACC übertragen.
:LoadGDesk2RAM		lda	#APPLICATION		;GeoDesk über die GEOS-Klasse in
			sta	r7L			;":bootGDeskClass" suchen.
			lda	#$01			;":GD_CLASS" wird bei der Übernahme
			sta	r7H			;von Daten einer bereits aktiven
			LoadW	r6,GD_SYS_NAME		;Instanz überschrieben!
			LoadW	r10,bootGDeskClass
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:error_sys		; => Ja, Abbruch...

			lda	r7H			;Modul gefunden ?
			bne	:error_sys		; => Nein, Abbruch...
			sta	curModule		;Aktuelles VLIR-Modul.
			sta	ramBankPointer		;GeoDesk-Speicherbank.

;			lda	#< GD_START_DACC	;Startadresse VLIR-Module im DACC.
			sta	a0L			;Bereich $0000-GD_START_DACC ist für
			lda	#> GD_START_DACC	;die Original EnterDeskTop-Routine
			sta	a0H			;reserviert.

::open			LoadW	r0,GD_SYS_NAME		;VLIR-Header einlesen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

::loop2			lda	curModule		;Aktuelle Modul-Nr. einlesen.
;			cmp	#127 -1			;Letztes Modul erreicht?
			cmp	#GD_VLIR_COUNT
			bcs	:continue		; => Ja, Ende...
			jsr	:readVlirRec		;VLIR-Datensatz einlesen.
			cpx	#$ff			;Ende erreicht?
			beq	:continue		; => Ja, Ende...
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

			lda	curModule		;Aktuelle Modul-Nr. einlesen.
			bne	:save			;Hauptmodul? => Nein, weiter...
			jsr	LoadConfig

::save			jsr	saveVlir2RAM		;VLIR-Modusl speichern.

			inc	curModule		;Zeiger auf nächstes VLIR-Modul.
			bne	:loop2			;Nächstes Modul kopieren.

;--- Alle VLIR-Module kopiert.
::continue		jsr	CloseRecordFile

;--- Hauptprogramm einlesen und
;Zeiger auf Unterprogramme speichern.
			ClrB	curModule
			jsr	:setRamVec		;Hauptmodul einlesen.
			jsr	FetchRAM

			jsr	i_MoveData		;VLIR-Daten speichern.
			w	SYSVAR_START
			w	APP_RAM +GD_JMPTBL_COUNT*3
			w	(SYSVAR_END - SYSVAR_START)

			jsr	:setRamVec		;Hauptmodul aktualisieren.
			jmp	StashRAM

;--- Fehlermeldung ausgeben.
::vlir_error		jsr	CloseRecordFile

::error_disk		lda	#<Dlg_LdDiskErr		;Fehler beim Öffnen der VLIR-Datei.
			ldx	#>Dlg_LdDiskErr
			bne	:error_exit
::error_sys		lda	#<Dlg_GeoDeskNFnd	;Systemdatei nicht gefunden.
			ldx	#>Dlg_GeoDeskNFnd
;			bne	:error_exit
::error_exit		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	EnterDeskTop		;Zurück zum DeskTop Vx.

;--- Zeiger auf Hauptprogramm in GEOS-DACC setzen.
::setRamVec		ldx	#$03
::loop3			lda	GD_DACC_ADDR,x
			sta	r1L,x
			dex
			bpl	:loop3

			ldx	curModule
			lda	GD_DACC_ADDR_B,x
			sta	r3L

			LoadW	r0,APP_RAM

			rts

;--- VLIR-Datensatz einlesen.
::readVlirRec		asl				;Zeiger auf VLIR-Daten berechnen.
			tax
			lda	fileHeader+4,x		;Zeiger auf ersten Datensatz-Sektor
			beq	:skip			;einlesen und speichern.
			sta	r1L
			lda	fileHeader+5,x
			sta	r1H
			LoadW	r2,(BASE_DIR_DATA - APP_RAM) -1
			LoadW	r7,APP_RAM
			jmp	ReadFile		;VLIR-Datensatz einlesen.

::skip			ldx	#$ff
			rts

;*** VLIR-Datensatz in GEOS-DACC speichern.
:saveVlir2RAM		lda	curModule		;Zeiger auf Speicher in GEOS-DACC.
			asl
			asl
			tax
			lda	a0L
			sta	r1L
			lda	a0H
			sta	r1H

			lda	r7L			;Größe VLIR-Modul berechnen.
			sec
			sbc	#<APP_RAM
			sta	r2L
			lda	r7H
			sbc	#>APP_RAM
			sta	r2H

			clc
			lda	r1L
			adc	r2L
			lda	r1H
			adc	r2H
			bcc	:1

			inc	ramBankPointer

			lda	#$00
			sta	r1L
			sta	r1H
			sta	a0L
			sta	a0H

::1			lda	curModule
			asl
			asl
			tay
			ldx	#0
::2			lda	r1L,x
			sta	GD_DACC_ADDR,y
			iny
			inx
			cpx	#4
			bne	:2

			ldx	ramBankPointer
			lda	GD_RAM_GDESK1,x
			ldy	curModule
			sta	GD_DACC_ADDR_B,y
			sta	r3L			;GEOS-DACC-64K-Bank setzen.

			LoadW	r0,APP_RAM		;C64-Speicher.

			clc				;Zeiger für nächstes Modul
			lda	r2L			;berechnen.
			adc	a0L
			sta	a0L
			lda	r2H
			adc	a0H
			sta	a0H

			jmp	StashRAM		;Modul speichern.

;*** Aktuelles VLIR-Modul.
:curModule		b $00
:ramBankPointer		b $00

;*** Boot-Konfiguration in Hauptmodul übertragen.
:LoadConfig		bit	GD_BACKSCRN		;Hintergrundbild verwenden?
			bpl	:3			; => Nein, weiter...

			LoadW	r0,backScrCode
			LoadW	r1,backScrCodeRAM
			LoadW	r2,backScrCodeLen
			lda	GD_SYSDATA_BUF
			sta	r3L

			lda	sysRAMFlg
			and	#%00001000		;MegaPatch-Hintergrundbild aktiv?
			beq	:1			; => Ja, weiter...

			jsr	StashRAM		;Prüfcode in Speicher schreiben.
			jmp	:3

::1			jsr	VerifyRAM		;Prüfcode testen.
			and	#%00100000		;Hintergrundbild im Speicher?
			beq	:3			; => Ja, weiter...

::2			lda	#$00			;Kein MegaPatch-Hintergrundbild,
			sta	GD_BACKSCRN		; => Kein GeoDesk-Hintergrundbild.

::3			lda	sysRAMFlg
			and	#%11110111
			bit	GD_BACKSCRN		;GeoDesk-Hintergrundbild verwenden?
			bpl	:4			; => Nein, weiter...
			ora	#%00001000		; => Ja, System-Wert ändern.
::4			sta	sysRAMFlg
			sta	sysFlgCopy

			ldy	#0			;Boot-GEOS-Klasse in Konfiguration
::5			lda	bootGDeskClass,y	;übertragen. Damit wird es möglich
			sta	GD_CLASS,y		;zwischen der englischen und
			beq	:6			;deutschen Version zu wechseln, da
			iny				;sonst die Klasse aus der Version
			bne	:5			;im RAM übernommen wird.

::6			jsr	i_MoveData		;Konfiguration in Hauptmodul
			w	GD_VAR_START		;übertragen.
			w	APP_RAM +GD_JMPTBL_COUNT*3 +SYSVAR_SIZE
			w	GD_VAR_SIZE

			jsr	i_MoveData		;GEOS-Farben installieren.
			w	GEOS_SYS_COLS_A
			w	MP3_COLOR_DATA
			w	(GEOS_SYS_COLS_E - GEOS_SYS_COLS_A)

			jmp	ApplyConfig

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** GEOS-Klasse für GeoDesk.
:bootGDeskClass		t "-SYS_CLASS"

;*** Kein GEOS-MegaPatch.
:Dlg_NoMP		b %10000001
			b DBTXTSTR   ,$10,$10
			w :1
			b DBTXTSTR   ,$10,$24
			w :2
			b DBTXTSTR   ,$10,$30
			w :3
			b CANCEL     ,$02,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT, BOLDON
			b "SYSTEMFEHLER!",NULL

::2			b PLAINTEXT
			b "Dieses Programm ist nur mit",NULL
::3			b "GEOS MegaPatch V3 lauffähig!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT, BOLDON
			b "SYSTEM ERROR!",NULL

::2			b PLAINTEXT
			b "This program requires",NULL
::3			b "GEOS MegaPatch V3!",NULL
endif

;*** Dialogboxen.
:Dlg_GeoDeskNFnd	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "SYSTEMFEHLER!",NULL
::2			b "GeoDesk konnte die System-",NULL
::3			b "Datei nicht finden!",NULL
::4			b "Programm wird beendet.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "SYSTEM ERROR!",NULL
::2			b "GeoDesk cannot find the",NULL
::3			b "application system file!",NULL
::4			b "Exiting now.",NULL
endif

;*** Dialogboxen.
:Dlg_GeoDeskSDrv	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "SYSTEMFEHLER!",NULL
::2			b "GeoDesk konnte das Start-",NULL
::3			b "Laufwerk nicht finden!",NULL
::4			b "Programm wird beendet.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "SYSTEM ERROR!",NULL
::2			b "GeoDesk cannot find the",NULL
::3			b "application system drive!",NULL
::4			b "Exiting now.",NULL
endif

;*** Nicht genügend freier Speicher.
:Dlg_NoFreeRAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "SYSTEMFEHLER!",NULL

::2			b PLAINTEXT
			b "GeoDesk benötigt mindestens",NULL
::3			b "256Kb freien GEOS-Speicher!",NULL
::4			b "Das Programm wird beendet.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "SYSTEM ERROR!",NULL

::2			b PLAINTEXT
			b "GeoDesk requires at least",NULL
::3			b "256Kb free GEOS memory!",NULL
::4			b "Exiting now.",NULL
endif

;*** Diskettenfehler.
:Dlg_LdDiskErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b CANCEL     ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT, BOLDON
			b "SYSTEMFEHLER!",NULL

::2			b PLAINTEXT
			b "GeoDesk konnte nicht in den",NULL
::3			b "GEOS-Speicher kopiert werden!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT, BOLDON
			b "SYSTEM EERROR!",NULL

::2			b PLAINTEXT
			b "GeoDesk could not be installed",NULL
::3			b "in the extended GEOS memory!",NULL
endif

;******************************************************************************
			g (VLIR_BOOT_START + VLIR_BOOT_SIZE) -1
;******************************************************************************
