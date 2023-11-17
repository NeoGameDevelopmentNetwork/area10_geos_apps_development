; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Laufwerksmodus wechseln.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"

;--- "TreiberInRAM"-Datentabelle.
;Der Original-Bereich für GD.CONFIG ist
;durch GeoDesk bereits belegt.
;Die Daten für die Laufwerkstreiber im
;RAM werden daher am Ende des Modul-
;speicher eingelesen.
:DDRV_DATA_SIZE		= $0300
:DDRV_DATA_START	= (BASE_DIRDATA   - DDRV_DATA_SIZE)
:DDRV_DATA_DACC		= $0000
:DDRV_INFO_START	= DDRV_DATA_START
:DDRV_INFO_SIZE		= (DRVINF_NG_SIZE  - DRVINF_NG_START) + DDRV_INFO_START
:DDRV_INFO_BANK		= (DRVINF_NG_RAMB  - DRVINF_NG_SIZE ) + DDRV_INFO_SIZE
:DDRV_INFO_FOUND	= (DRVINF_NG_FOUND - DRVINF_NG_RAMB ) + DDRV_INFO_BANK
:DDRV_INFO_TYPES	= (DRVINF_NG_TYPES - DRVINF_NG_FOUND) + DDRV_INFO_FOUND
:DDRV_INFO_NAMES	= (DRVINF_NG_NAMES - DRVINF_NG_TYPES) + DDRV_INFO_TYPES

;--- Variablenspeicher Laufwerkstreiber.
:DDRV_JMP_SIZE		= 3*3
;:DDRV_VAR_SIZE		= 20 -DDRV_JMP_SIZE
:DDRV_VAR_START		= BASE_DDRV_DATA +DDRV_JMP_SIZE
:DDRV_VAR_GADR		= DDRV_VAR_START +0
;:DDRV_VAR_MODE		= DDRV_VAR_START +1
;:DDRV_VAR_TYPE		= DDRV_VAR_START +2
;--- Konfigurationsregister:
;%1xxxxxxx = CMDHD-PP-Modus aktiv.
;%x1xxxxxx = CMDHD-PP-Modus wählen.
;%xx1xxxxx = Keine Partition wählen.
:DDRV_VAR_CONF		= DDRV_VAR_START +3
;--- Treiberspezifische Register.
:DDRV_ADR_HDPP		= DDRV_VAR_START +4
;
;--- Titel für Treiber-Installation.
;:DDRV_SYS_TITLE	= (BASE_DDRV_DATA +DDRV_JMP_SIZE +DDRV_VAR_SIZE)
;--- Start Laufwerkstreiber.
;:DDRV_SYS_DEVDATA	= (BASE_DDRV_DATA +64)

;--- Sprungtabelle für Installationsroutine.
:DDRV_INST_APPL		= BASE_DDRV_DATA +0
:DDRV_INST		= BASE_DDRV_DATA +3
:DDRV_SLCT_PART		= BASE_DDRV_DATA +6

;--- Installationsroutine.
:TEMP_INST_BASE		= $7f00

;--- Speicheraufteilung:
;Bank#0:
;$0000-$02FF : Treiber-Informationen.
;  $0000     : Treiber-Startadresse in DACC.
;  $0040     : Treiber-Größe in Bytes.
;  $0080     : Treiber-Bank.
;  $00A0     : Treiber verfügbar.
;  $00C0     : Treiber-Typ.
;  $00E0     : Treiber-Name.
;$0300-$FFFF : Treiber Teil #1.
;Bank#1:
;$0000-$FFFF : Treiber Teil #2.

;:R2A_DDRVCORE		= $e378
;:R2S_DDRVCORE		= SIZE_DDRV_CORE
endif

;*** GEOS-Header.
			n "obj.GD55"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSETDRVMODE

;*** Laufwerksmodus wechseln.
;Übergabe: TempDrive = Ziel-Laufwerk.
;          TempMode  = Laufwerksmodus.
:xSETDRVMODE		LoadW	r0,DDRV_DATA_START
			LoadW	r1,DDRV_DATA_DACC
			LoadW	r2,DDRV_DATA_SIZE
			lda	MP3_64K_DISK
			sta	r3L
			jsr	FetchRAM		;"Treiber-in-RAM"-Daten einlesen.

			lda	#$00			;Liste der verfügbaren
			sta	SlctDvTypeTab +0	;Laufwerksmodi löschen.
			sta	SlctDvTypeTab +1
			sta	SlctDvTypeTab +2
			sta	SlctDvTypeTab +3

			sta	r2L			;Anzahl Laufwerksmodi zurücksetzen.

			ldx	#0
::1			lda	DDRV_INFO_FOUND,x	;Laufwerkstyp verfügbar ?
			beq	:next			; => Nein, weiter...
			lda	DDRV_INFO_TYPES,x	;Laufwerksmodus definiert ?
			beq	:next			; => Nein, weiter...

			sta	r0L			;Laufwerksmodus speichern.
			and	#%11111000		;Gerätetyp isolieren und
			sta	r0H			;zwischenspeichern.

			ldy	curDrive
			lda	RealDrvType -8,y	;Laufwerkstyp einlesen.
			and	#%11111000		;Gerätetyp isolieren.
			cmp	r0H			;Passt Typ zum aktuellen Treiber ?
			bne	:next			; => Nein, weiter...

::found			lda	r0L			;Laufwerkstyp einlesen.
			and	#%00000111		;Laufwerksmodus isolieren.
			beq	:next			; => $00 = Ungültig, weiter...
			cmp	#$05			;Auf 41/71/81/NM testen.
			bcs	:next			; => Ungültig, weiter...

			tay
			dey
			txa
			sta	SlctDvTypeTab,y		;Laufwerksmodus verfügbar.

			tya				;Zeiger auf Dialogbox-Text
			asl				;für aktuellen Modus einlesen.
			tay
			lda	SlctDvModeTab +0,y
			sta	r1L
			lda	SlctDvModeTab +1,y
			sta	r1H

			lda	#BOLDON			;Standard-Text "N.V."
			ldy	#$00			;überschreiben.
			sta	(r1L),y			;Dadurch wird bei vorhandensein des
			iny				;Treibers der Standard-Text durch
			sta	(r1L),y			;den Modus 41/71/81/NM ersetzt.
			iny
			sta	(r1L),y
			iny
			sta	(r1L),y
			iny
			sta	(r1L),y

			inc	r2L			;Anzahl Modi +1.

::next			inx
			cpx	#DDRV_MAX		;Alle Treiber durchsucht ?
			bcc	:1			; => Nein, weiter...

			ldy	r2L			;Laufwerk-Modi gefunden ?
			beq	:cancel			; => Nein, Abbruch...

			lda	TempMode		;Laufwerksmodus vorgeben ?
			bne	:skipmenu		; => Ja, weiter...

			ldx	#PLAINTEXT
			cpy	#4			;Alle Modi verfügbar ?
			bcc	:setnote		; => Nein, weiter...
			ldx	#NULL			;Hinweis "N.V." deaktivieren.
::setnote		stx	dModeNote

			LoadW	r0,Dlg_SlctDevMode
			jsr	DoDlgBox		;Laufwerkstyp auswählen.

			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:cancel			; => Ja, Ende...

			and	#%00000111		;Neuen Modus isolieren.
::skipmenu		sta	newDrvMode
			tax
			dex
			lda	SlctDvTypeTab,x		;Laufwerksmodus verfügbar ?
			beq	:cancel			; => Nein, Abbruch...

			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerk für Fenster definiert ?
			bne	:2			; => Ja, weiter...
			ldy	TempDrive		;Laufwerk bereits definiert ?
			bne	:2			; => Ja, weiter...
			ldy	curDrive		;Arbeitsplatz = aktuelles Laufwerk.
::2			sty	TempDrive
			lda	RealDrvType -8,y	;Laufwerkstyp einlesen.
			and	#%00000111		;Gerätetyp isolieren.
			cmp	newDrvMode		;Laufwerkstyp bereits installiert ?
			beq	:cancel			; => Ja, Abbruch...

			jmp	InitNewDrvMode		;Neuen Modus installieren.

;--- Zurück zum DeskTop.
::cancel		jsr	SET_LOAD_CACHE		;Dateien/Partitionen neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Neuen Modus aktivieren.
:InitNewDrvMode		ldy	#$00			;Installations-Code in
::loop			lda	:initcode,y		;Zwischenspeicher kopieren.
			sta	TEMP_INST_BASE,y
			iny
			bne	:loop

			ldx	#r1L			;Zeiger auf aktuellen Disknamen.
			jsr	GetPtrCurDkNm

			ldy	#16			;Diskname im RAM löschen.
			lda	#NULL
::1			sta	(r1L),y
			dey
			bpl	:1

			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerk für Fenster definiert ?
			bne	:2			; => Ja, weiter...
			ldy	TempDrive		;Arbeitsplatz = Aktuelles Laufwerk.
			bne	:3			;Keine Fensterdaten aktualisieren.

::2			lda	WIN_DATAMODE,x		;Partitions-/DiskImage-Modus
			and	#%00111111		;zurücksetzen.
			sta	WIN_DATAMODE,x

			lda	TempPart
			beq	:setmode

			lda	RealDrvMode -8,y
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:setmode		; => Kein CMD/SD2IEC, weiter...
			bmi	:part

::dimg			lda	#%01000000		; => SD2IEC.
			b $2c
::part			lda	#%10000000		; => CMD-FD/HD/RL.
::setmode		ora	WIN_DATAMODE,x
			sta	WIN_DATAMODE,x		;Partitionsmodus setzen.

			lda	#NULL
			sta	WIN_PART,x		;Partitionsnummer löschen.

			sta	WIN_SDIR_T,x		;Hauptverzeichnis aktivieren.
			sta	WIN_SDIR_S,x

			sta	WIN_DIR_START,x		;Verzeichnis von Anfang an lesen.

;			ldy	WIN_DRIVE,x		;Neuen Laufwerksmodus speichern.
			lda	RealDrvType -8,y
			and	#%11111000
			ora	newDrvMode
			sta	WIN_REALTYPE,x

;--- Hinweis:
;Aktive Partition löschen, da die
;Routine zum öffnen des Fenster-
;Laufwerks bei ":WIN_PART"=0 auch den
;Wert in ":drivePartData" auswertet.
::3			lda	#$00			;Aktive Partition löschen.
			sta	drivePartData -8,y

			lda	RealDrvMode -8,y	;Laufwerkstyp isolieren.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk ?
			bne	:sd2iec			; => Ja, weiter...
::cmd			lda	#%10000000		;Andere Fenster nicht schließen.
			b $2c
::sd2iec		lda	#%11000000		;SD2IEC: Andere Fenster schließen.
			sta	drvUpdFlag

			tya
			pha

			jsr	SET_LOAD_DISK		;Verzeichnis neu einlesen.

			lda	#NULL			;Fenster für Cache löschen.
			sta	getFileWin

;HINWEIS:
;Die Werte des Fenstermanagers wurden
;verändert, daher müssen die Werte im
;DACC aktualisiert werden.
			jsr	BACKUP_WMCORE		;Fenstermanager speichern.

			pla
			jsr	SetDevice		;Laufwerk aktivieren.

			ldy	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:install		; => Nein, weiter...

			bit	TempPart
			bvc	:install		; => Nein, weiter...

			jsr	SUB_OPEN_SD_EXIT	;SD2IEC: DiskImage verlassen.

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Installations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
::install		jsr	PurgeTurbo		;TurboDOS entfernen.
;------------------------------------------------------------------------------

			ldx	newDrvMode
			dex
			lda	SlctDvTypeTab,x		;Neuen Laufwerksmodus einlesen.
			jmp	TEMP_INST_BASE

;*** Installationsroutine.
;Übergabe: AKKU = Treiber-Nr.
::initcode		tax
			asl
			tay
			lda	#< BASE_DDRV_DATA
			sta	r0L
			lda	#> BASE_DDRV_DATA
			sta	r0H
			lda	DDRV_INFO_START +0,y
			sta	r1L
			lda	DDRV_INFO_START +1,y
			sta	r1H
			lda	DDRV_INFO_SIZE +0,y
			sta	r2L
			lda	DDRV_INFO_SIZE +1,y
			sta	r2H
			lda	DDRV_INFO_BANK,x
			sta	r3L
			jsr	FetchRAM		;Treiber aus REU einlesen.

			LoadW	r0,BASE_DDRV_CORE
			LoadW	r1,R2A_DDRVCORE
			LoadW	r2,R2S_DDRVCORE
			lda	MP3_64K_SYSTEM
			sta	r3L
			jsr	FetchRAM		;DiskCore aus REU einlesen.

			lda	DDRV_VAR_CONF		;Konfigurationsregister
			and	#%00011111		;initialisieren.
			sta	DDRV_VAR_CONF

			ldx	curDrive		;Laufwerksadresse übergeben.
			stx	DDRV_VAR_GADR

			lda	RealDrvType -8,x
			and	#%11111000
			cmp	#DrvHD			;CMD-HD ?
			bne	:nopp			; => Nein, weiter...

			lda	RealDrvMode -8,x	;PP-Modus aktiv ?
			and	#SET_MODE_FASTDISK
			beq	:nopp			; => Nein,weiter...
			lda	#%10000000		;FastPP-Modus vorgeben.
			b $2c
::nopp			lda	#%00000000
			ora	#%00100000		;Keine Partitionsauswahl.
			ora	DDRV_VAR_CONF
			sta	DDRV_VAR_CONF		;Konfigurationsregister setzen.

::exec			lda	#> EnterDeskTop-1	;Rücksprung zum DeskTop.
			pha
			lda	#< EnterDeskTop-1
			pha
			jmp	DDRV_INST		;Treiber installieren.

;--- Größe InitCode testen:
			g :initcode +256
;------------------------------------------------------------------------------

;*** Liste der Laufwerksmodi.
:skipSlctMode		b $00
:newDrvMode		b $00
:SlctDvTypeTab		s 4
:SlctDvModeTab		w dMode1541
			w dMode1571
			w dMode1581
			w dModeNative

;*** Dialogbox: "Emulationsmodus wählen:"
:Dlg_SlctDevMode	b %01100001
			b $30,$a7
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$0c,$0b
			w dModeTitle

			b DBTXTSTR ,$40,$25
			w dMode1541
			b DBUSRICON,$01,$18
			w :i41

			b DBTXTSTR ,$40,$35
			w dMode1571
			b DBUSRICON,$01,$28
			w :i71

			b DBTXTSTR ,$40,$45
			w dMode1581
			b DBUSRICON,$01,$38
			w :i81

			b DBTXTSTR ,$40,$55
			w dModeNative
			b DBUSRICON,$01,$48
			w :inm

			b DBTXTSTR ,$0c,$6b
			w dModeNote

			b CANCEL   ,$11,$60
			b NULL

;--- Icon-Tabelle.
::i41			w Icon_41
			b $00,$00,Icon_41x,Icon_41y
			w :set41

::i71			w Icon_71
			b $00,$00,Icon_41x,Icon_41y
			w :set71

::i81			w Icon_81
			b $00,$00,Icon_41x,Icon_41y
			w :set81

::inm			w Icon_NM
			b $00,$00,Icon_41x,Icon_41y
			w :setnm

;--- Emulationsmodus definieren.
::set41			lda	#%10000000 ! Drv1541
			b $2c
::set71			lda	#%10000000 ! Drv1571
			b $2c
::set81			lda	#%10000000 ! Drv1581
			b $2c
::setnm			lda	#%10000000 ! DrvNative
			sta	sysDBData
			jmp	RstrFrmDialogue

if LANG = LANG_DE
:dModeTitle		b PLAINTEXT,BOLDON
			b "Laufwerks-Modus wählen:",NULL
:dMode1541		b "N.V.",NULL
			b "C=1541-Modus",NULL
:dMode1571		b "N.V.",NULL
			b "C=1571-Modus",NULL
:dMode1581		b "N.V.",NULL
			b "C=1581-Modus",NULL
:dModeNative		b "N.V.",NULL
			b "CMD NativeMode",NULL
:dModeNote		b PLAINTEXT
			b "( N.V. = Nicht verfügbar )",NULL
endif
if LANG = LANG_EN
:dModeTitle		b PLAINTEXT,BOLDON
			b "Select drive mode:",NULL
:dMode1541		b "N.A.",NULL
			b "C=1541 mode",NULL
:dMode1571		b "N.A.",NULL
			b "C=1571 mode",NULL
:dMode1581		b "N.A.",NULL
			b "C=1581 mode",NULL
:dModeNative		b "N.A.",NULL
			b "CMD NativeMode",NULL
:dModeNote		b PLAINTEXT
			b "( N.A. = Not available )",NULL
endif

;*** Icons.
:Icon_41
<MISSING_IMAGE_DATA>
:Icon_41x		= .x
:Icon_41y		= .y

:Icon_71
<MISSING_IMAGE_DATA>

:Icon_71x		= .x
:Icon_71y		= .y

:Icon_81
<MISSING_IMAGE_DATA>

:Icon_81x		= .x
:Icon_81y		= .y

:Icon_NM
<MISSING_IMAGE_DATA>

:Icon_NMx		= .x
:Icon_NMy		= .y

;*** Endadresse testen:
			g (BASE_DIRDATA - DDRV_DATA_SIZE) -1
;***
