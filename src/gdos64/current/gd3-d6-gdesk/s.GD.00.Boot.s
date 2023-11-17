; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk Erststart.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_APPS"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- GeoDesk-Optionen.
			t "e.GD.10.Options"

;--- GeoDesk-Systemdaten.
			t "e.GD.10.System"

;--- Sprungtabelle.
:BOOT_SYSTEM		= BASE_GEODESK +0		;Erst-Start.
:BOOT_ENTERDT		= BASE_GEODESK +3		;EnterDeskTop.
endif

;*** GEOS-Header.
			n "obj.GD00"
			t "opt.GDesk.Class"
			t "opt.Author"
			f APPLICATION
			z $80 ;nur GEOS64

			o BASE_BOOTLOAD
			p MainInit

			i
<MISSING_IMAGE_DATA>

;*** System initialisieren.
:MainInit		lda	bootName +1		;GDOS-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:gdoserr		; => Nein, weiter...
			lda	bootName +7
			cmp	#"V"
			beq	:testgd3active		; => Ja, GDOS64.

::gdoserr		jmp	:nogdos

;--- Testen ob GDOS bereits aktiv.
;Falls ja, GeoDesk aus Speicher löschen
;und neu starten.
::testgd3active		jsr	GetBackScreen		;Hintergrundbild laden.
							;Damit verschwindet beim Boot-
							;Vorgang der graue Bildschirm.

			jsr	SetADDR_EnterDT		;Original EnterDeskTop-Routine
			jsr	FetchRAM		;einlesen.

			ldy	#:GD3CODEPOS		;Auf GDOS-Kennung testen.
			ldx	#$00
::3			lda	(r0L),y
			cmp	:GD3CODE,x
			bne	:init_config		; => GDOS nicht aktiv, weiter...
			iny
			inx
			cpx	#:GD3LEN
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

;--- Konfigurationsbereich initialisieren.
::init_config		LoadW	r0,GDA_OPTIONS
			LoadW	r1,R3A_CFG_GDSK
			LoadW	r2,GDS_OPTIONS
			lda	MP3_64K_DATA
			sta	r3L
			jsr	FetchRAM		;GeoDesk-Optionen aus DACC laden.

;--- Auf 256K Speicher testen und Menü starten.
::testram		jsr	DACC_FIND_BANK		;64K für ScreenBuffer.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			tya
			sta	GD_SCRN_STACK
			ldx	#%11000000		;Bank-Typ: System.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

			jsr	DACC_FIND_BANK		;64K für Bildschirm/Verzeichnis.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			tya
			sta	GD_SYSDATA_BUF
			ldx	#%11000000		;Bank-Typ: System.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

			jsr	DACC_FIND_BANK		;64K/1 für GeoDesk-Desktop.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			tya
			sta	GD_RAM_GDESK1
			ldx	#%11000000		;Bank-Typ: System.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

			jsr	DACC_FIND_BANK		;64K/2 für GeoDesk-Desktop.
			cpx	#NO_ERROR		;Speicher gefunden?
			bne	:noram			; => Nein, Fehler...
			tya
			sta	GD_RAM_GDESK2
			ldx	#%11000000		;Bank-Typ: System.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

;--- Auf optionalen Speicher testen.
			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:no_cache
			jsr	DACC_FIND_BANK		;64K für Icon-Daten.
			cpx	#NO_ERROR		;Speicher gefunden?
			beq	:icon_cache		; => Ja, weiter...
			bne	:no_cache

;--- Fehler: Kein GDOS.
::nogdos		lda	#< Dlg_NoGDOS		;Fehlermeldung "Kein GDOS64!"
			ldx	#> Dlg_NoGDOS		;ausgeben.
			bne	:syserr

;--- Fehler: Laufwerk nicht erkannt.
::nosdrive		lda	#< Dlg_GDOS_Drive	;Fehlermeldung "Kein Laufwerk!"
			ldx	#> Dlg_GDOS_Drive	;ausgeben.

;--- Fehler: Kein Speicher frei.
::noram			jsr	FreeGDeskRAM		;GeoDesk-Speicher freigeben.

;--- Fehler ausgeben, zurück zum DeskTop.
::noram_exit		jsr	GetBackScreen		;Bildschirm zurücksetzen.

			lda	#< Dlg_GDOS_NoRAM	;Fehlermeldung ausgeben:
			ldx	#> Dlg_GDOS_NoRAM	;"Nicht genügend Speicher"
::syserr		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	EnterDeskTop		;Zurück zum DeskTop Vx.

;--- Cache abschalten.
::no_cache		lda	#$00			;Kein Speicher für Icon-Cache
			sta	GD_ICON_CACHE		;frei, Icon-Cache abschalten.
			sta	GD_ICONDATA_BUF
			beq	:continue

;--- Cache aktivieren.
::icon_cache		tya
			sta	GD_ICONDATA_BUF
			ldx	#%11000000		;Bank-Typ: System.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

;--- Startkonfiguration speichern.
::continue		jsr	infoBootGeoDesk		;Boot-Meldung ausgeben.
			jsr	setBootConfig		;Laufwerkskonfiguration speichern.
			beq	:bootOK			;Fehler? => Nein, weiter...
			jmp	:nosdrive		;Abbruch...

;--- GeoDesk installieren.
::bootOK		jsr	LoadGDesk2RAM		;GeoDesk in RAM laden.

			dec	GD_DACC_ADDR +1		;Größe Hauptmodul um Speicher für
			inc	GD_DACC_ADDR +3		;Systemdaten erweitern.

;--- EnterDeskTop ersetzen.
			jsr	SetADDR_EnterDT		;Original EnterDeskTop-Routine
			jsr	FetchRAM		;einlesen.
			lda	#$00			;Zeiger auf Zwischenspeicher
			sta	r1L			;im GEOS-DACC setzen.
			sta	r1H
			lda	GD_RAM_GDESK1
			sta	r3L
			jsr	StashRAM		;Original-Routine speichern.

			lda	GD_DACC_ADDR +0		;Startadresse GeoDesk im GEOS-DACC
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

;--- Status Hintergrundbild übernehmen.
			bit	GD_BACKSCRN		;Hintergrundbild verwenden?
			bpl	:setback		; => Nein, weiter...

			bit	Flag_BackScrn		;GDOS-Hintergrund geladen ?
			bmi	:setback		; => Ja, weiter...

			lda	#FALSE			;Kein GDOS-Hintergrundbild,
			sta	GD_BACKSCRN		; => Kein GeoDesk-Hintergrundbild.

::setback		lda	sysRAMFlg
			and	#%11110111
			bit	GD_BACKSCRN		;GeoDesk-Hintergrundbild verwenden?
			bpl	:noback			; => Nein, weiter...
			ora	#%00001000		; => Ja, System-Wert ändern.
::noback		sta	sysRAMFlg
			sta	sysFlgCopy

			jsr	StashRAM		;GeoDesk-Optionen in DACC speichern.

;--- GeoDesk starten.
			jsr	updSysConfig		;System-Konfiguration übernehmen.

			LoadW	r0,GDA_SYSTEM
			MoveW	GD_DACC_ADDR +0,r1
			MoveW	GD_DACC_ADDR +2,r2
			MoveB	GD_DACC_ADDR_B ,r3L
			jsr	FetchRAM		;GeoDesk-Hauptmodul einlesen.

			jmp	BOOT_SYSTEM		;GeoDesk starten.

;--- Neue EnterDeskTop-Routine.
;ACHTUNG! Die Routine ist Relokatibel!
;Keine absoluten Adressen verwenden!
::GDeskEnterDT		sei				;GEOS initialisieren.
			cld
			ldx	#$ff
			stx	firstBoot
			txs
			jsr	GEOS_InitSystem
;			jsr	GetBackScreen

			lda	#< GDA_SYSTEM		;GeoDesk-Hauptmodul einlesen.
			sta	r0L
			lda	#> GDA_SYSTEM
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

			lda	#$00
			sta	r0L
			LoadW	r7,BOOT_ENTERDT
			jmp	StartAppl		;GeoDesk-Hauptmodul starten.

::ramBakOffset		= (:ramBank-:GDeskEnterDT) +1

;--- Kennung für "GeoDesk aktiv".
::GD3CODE		b "GD64V3"
			b NULL
::GD3END
::GD3LEN		= ( :GD3END - :GD3CODE )

;--- Füllbytes.
::dummy			;s $0200 - (:dummy - :GDeskEnterDT)

;--- Zeiger auf GD3-Kennung innerhalb der neuen EnterDT-Routine.
::GD3CODEPOS		= ( :GD3CODE - :GDeskEnterDT )

;*** Größe EnterDeskTop testen:
			g (:GDeskEnterDT + R2S_ENTER_DT) -1
;***

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
			LoadW	r0,GDA_SYSTEM
			LoadW	r1,DACC_GEODESK
			LoadW	r2,GDS_SYSTEM
			lda	GD_RAM_GDESK1
			sta	r3L
			jsr	FetchRAM		;GeoDesk-Systemdaten einlesen.

;*** GeoDesk-Speicher freigeben.
:FreeGDeskRAM		lda	GD_SCRN_STACK		;Speicher für ScreenBuffer
			beq	:1			;freigeben.
			jsr	DACC_FREE_BANK

::1			lda	GD_SYSDATA_BUF		;Speicher für Desktop- und
			beq	:2			;Verzeichnisdaten freiegebn.
			jsr	DACC_FREE_BANK

::2			lda	GD_RAM_GDESK1		;Speicher #1 für GeoDesk-Desktop
			beq	:3			;freigeben.
			jsr	DACC_FREE_BANK

::3			lda	GD_RAM_GDESK2		;Speicher #2 für GeoDesk-Desktop
			beq	:4			;freigeben.
			jsr	DACC_FREE_BANK

::4			lda	GD_ICONDATA_BUF		;Speicher für Icon-Daten
			beq	:5			;freigeben.
			jsr	DACC_FREE_BANK
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
			sta	bootGDeskDrive
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
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	:0			; => Nein, weiter...
			lda	driveType -8,x		;CMD-RAMLink?
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
			sta	bootGDeskRBase

			lda	RealDrvType -8,x	;Laufwerkstyp sichern.
			sta	bootGDeskType

			lda	RealDrvMode -8,x	;Laufwerksmodi sichern.
			sta	bootGDeskMode		;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	:1			; => Nein, weiter...
			lda	drivePartData-8,x	;Aktuelle Partition sichern.
::1			sta	bootGDeskPart

			lda	RealDrvMode -8,x	;NativeMode?
			and	#SET_MODE_SUBDIR
			tax
			beq	:2			; => Nein, weiter...
			lda	curDirHead +32		;Aktuellen Verzeichnis-Header
			ldx	curDirHead +33		;sichern.
::2			sta	bootGDeskSDir +0
			stx	bootGDeskSDir +1

::ok			ldx	#NO_ERROR
::err			rts

;*** Systemkonfiguration übernehmen.
:updSysConfig		LoadW	r0,GDA_SYSTEM

			MoveW	GD_DACC_ADDR +0,r1
			MoveB	GD_DACC_ADDR_B ,r3L

			LoadW	r2,GDS_SYSTEM
			jsr	StashRAM		;DACC-Informationen speichern.

			LoadW	r0,bootGDeskName
			AddVW	GDS_SYSTEM +6,r1
			LoadW	r2,16 +1 +21 +7		;Dateiname +NULL +Klasse +Laufwerk.

			jmp	StashRAM		;GeoDesk-Systemdaten speichern.

;*** GeoDesk in GEOS-DACC übertragen.
:LoadGDesk2RAM		jsr	i_FillRam		;Speicher für
			w	GD_VLIR_COUNT * 5	;VLIR-Informationen löschen.
			w	GD_DACC_ADDR
			b	NULL

			lda	#APPLICATION		;GeoDesk über die GEOS-Klasse
			sta	r7L			;suchen.
			lda	#$01
			sta	r7H
			LoadW	r6 ,bootGDeskName
			LoadW	r10,bootGDeskClass
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:error_sys		; => Ja, Abbruch...

			lda	r7H			;Modul gefunden ?
			bne	:error_sys		; => Nein, Abbruch...
			sta	curVLIRset		;Aktuelles VLIR-Modul.
			sta	curModule		;Aktuelles GDesk-Modul.
			sta	ramBankPointer		;GeoDesk-Speicherbank.

;			lda	#< DACC_GEODESK		;Startadresse VLIR-Module im DACC.
			sta	a0L			;Bereich $0000-DACC_GEODESK ist für
			lda	#> DACC_GEODESK		;die Original EnterDeskTop-Routine
			sta	a0H			;reserviert.

			inc	a0H			;Systemdaten überspringen.

::open			LoadW	r0,bootGDeskName	;VLIR-Header einlesen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

::loop2			lda	curVLIRset		;Aktuelle Modul-Nr. einlesen.
			cmp	#127 -1			;Letztes Modul erreicht?
			bcs	:continue		; => Ja, Ende...
			jsr	readVlirRec		;VLIR-Datensatz einlesen.
			cpx	#$ff			;Ende erreicht?
			beq	:next			; => Ja, Ende...
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

::save			jsr	saveVlir2RAM		;VLIR-Modusl speichern.

::next			inc	curModule
			lda	curModule
			cmp	#GD_VLIR_COUNT		;Alle Module eingelesen ?
			bcs	:continue		; => Ja, Ende...

			inc	curVLIRset		;Zeiger auf nächstes VLIR-Modul.
			bne	:loop2			;Nächstes Modul kopieren.

;--- Alle VLIR-Module kopiert.
::continue		jmp	CloseRecordFile		;VLIR-Datei schließen.

;--- Fehlermeldung ausgeben.
::vlir_error		jsr	CloseRecordFile		;VLIR-Datei schließen.

::error_disk		lda	#< Dlg_GDOS_LdErr	;Fehler beim Öffnen der VLIR-Datei.
			ldx	#> Dlg_GDOS_LdErr
			bne	:error_exit
::error_sys		lda	#< Dlg_GDOS_Error	;Systemdatei nicht gefunden.
			ldx	#> Dlg_GDOS_Error
;			bne	:error_exit
::error_exit		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jsr	FreeGDeskRAM		;GeoDesk-Speicher freigeben.
			jmp	EnterDeskTop		;Zurück zum DeskTop Vx.

;*** VLIR-Datensatz einlesen.
:readVlirRec		asl				;Zeiger auf VLIR-Daten berechnen.
			tax
			lda	fileHeader+4,x		;Zeiger auf ersten Datensatz-Sektor
			beq	:skip			;einlesen und speichern.
			sta	r1L
			lda	fileHeader+5,x
			sta	r1H
			LoadW	r2,SIZE_VLIRDATA	;Max.Größe setzen.
			LoadW	r7,BASE_VLIRDATA	;Ladeadresse setzen.
			jmp	ReadFile		;VLIR-Datensatz einlesen.

::skip			ldx	#$ff
			rts

;*** VLIR-Datensatz in GEOS-DACC speichern.
:saveVlir2RAM		lda	a0L			;Zeiger auf Speicher in GEOS-DACC.
			sta	r1L
			lda	a0H
			sta	r1H

			lda	r7L			;Größe VLIR-Modul berechnen.
			sec
			sbc	#< BASE_VLIRDATA
			sta	r2L
			lda	r7H
			sbc	#> BASE_VLIRDATA
			sta	r2H

			clc				;Wird 64K-Speichergrenze
			lda	r1L			;überschritten?
			adc	r2L
			lda	r1H
			adc	r2H
			bcc	:1			; => Nein, weiter...

			inc	ramBankPointer		;Zeiger auf nächste Speicherbank.

			lda	#$00
			sta	r1L
			sta	r1H
			sta	a0L
			sta	a0H

::1			lda	curModule		;Startadresse und Größe für
			asl				;Modul in Tabelle speichern.
			asl
			tay
			ldx	#0
::2			lda	r1L,x
			sta	GD_DACC_ADDR,y
			iny
			inx
			cpx	#4
			bne	:2

			ldx	ramBankPointer		;Speicherbank für das aktuelle
			lda	GD_RAM_GDESK1,x		;Modul in Tabelle speichern.
			ldy	curModule
			sta	GD_DACC_ADDR_B,y
			sta	r3L			;GEOS-DACC-64K-Bank setzen.

			LoadW	r0,BASE_VLIRDATA	;C64-Speicher.

			jsr	StashRAM		;Modul speichern.

			lda	r2L			;Zeiger für nächstes Modul
			clc				;berechnen.
			adc	a0L
			sta	a0L
			lda	r2H
			adc	a0H
			sta	a0H

			rts

;*** Titelzeile in Dialogbox löschen.
:DBoxDrawTitle		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Speicherverwaltung.
			t "-DA_FindBank"
			t "-DA_FreeBank"
			t "-DA_AllocBank"
			t "-DA_GetBankByte"

;*** Aktuelles VLIR-Modul.
:curVLIRset		b $00
:curModule		b $00
:ramBankPointer		b $00

;*** GEOS-Name/-Klasse für GeoDesk.
:bootGDeskName		s 17
:bootGDeskClass		t "opt.GDesk.Build"
			e bootGDeskClass +21

;*** Systemlaufwerk für GeoDesk.
:bootGDeskDrive		b $00
:bootGDeskPart		b $00
:bootGDeskType		b $00
:bootGDeskMode		b $00
:bootGDeskSDir		b $00,$00
:bootGDeskRBase		b $00

;*** Kein GDOS64.
:Dlg_NoGDOS		b %10000001
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
			b "Dieses Programm kann nur mit",NULL
::3			b "GDOS64 verwendet werden!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT, BOLDON
			b "SYSTEM ERROR!",NULL

::2			b PLAINTEXT
			b "This program can only be",NULL
::3			b "used with GDOS64!",NULL
endif

;*** Dialogboxen.
:Dlg_GDOS_Error		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DBoxDrawTitle
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
:Dlg_GDOS_Drive		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DBoxDrawTitle
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
:Dlg_GDOS_NoRAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DBoxDrawTitle
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
:Dlg_GDOS_LdErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DBoxDrawTitle
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
			b "GeoDesk konnte nicht im GEOS-",NULL
::3			b "Speicher installiert werden!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT, BOLDON
			b "SYSTEM EERROR!",NULL

::2			b PLAINTEXT
			b "GeoDesk could not be installed",NULL
::3			b "in the extended GEOS memory!",NULL
endif

;*** Zwischenspeicher für Icondaten.
:dataIconBuf
:sizeIconBuf = $0300

;*** Endadresse testen:
			g (BASE_BOOTLOAD + SIZE_BOOTLOAD) -sizeIconBuf -1
;***
