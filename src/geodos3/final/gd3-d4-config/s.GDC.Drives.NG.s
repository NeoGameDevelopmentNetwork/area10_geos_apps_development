; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_RLNK"
			t "SymbTab_64ROM"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "s.GD.DRV.Cor.ext"
			t "ext.DiskCore"

;--- SuperCPU-Register.
;Werden für das freigeben von Speicher
;eines SuperRAM-Laufwerks benötigt.
;Da der freie Symbolspeicher aber nicht
;mehr ausreicht, nur die benötigten
;Register direkt einbinden.
;			t "SymbTab_SCPU"
:SCPU_HW_EN		= $d07e
:SCPU_HW_DIS		= $d07f
:SRAM_FIRST_BANK	= $d27d
endif

;*** GEOS-Header.
			n "GD.CONF.DRIVES"
			c "GDC.DRIVES  V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Laufwerke konfigurieren"
endif
if Sprache = Englisch
			h "Configure drive"
endif

;*** Zusätzliche Symbole.
if .p
;--- Verfügbare Laufwerkstreiber.
;Verwendet den Speicher für Laufwerks-
;treiber um eine Liste für ":GetFiles"
;zu erstellen.
:SlctDvNameTab		= BASE_DDRV_DATA_NG
:SlctDvTypeTab		= BASE_DDRV_DATA_NG +DDRV_MAX*17

;--- Laufwerke am ser.Bus erkennen.
:GetAllSerDrives	= xGetAllSerDrives

;--- Sprungtabelle für Installationsroutine.
:DDrv_ApplInstall	= BASE_DDRV_DATA_NG +0
:DDrv_Install		= BASE_DDRV_DATA_NG +3
:DDrv_SlctPart		= BASE_DDRV_DATA_NG +6

;--- Laufwerksvariablen.
:DDrv_AdrGEOS		= DDRV_VAR_START +0
:DDrv_Type		= DDRV_VAR_START +1
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMain
:SaveData		jmp	SaveConfig
:CheckData		jmp	CheckConfig
;******************************************************************************

;******************************************************************************
;*** GD.CONFIG - Systemroutinen.
;******************************************************************************
			t "-GC_Drives.Core"
			t "-DD_FindDCore"
:LookForDkDvFile	= FindDiskCore
;******************************************************************************

;******************************************************************************
;*** Daten für Taskmanager.
;******************************************************************************
			t "-G3_TaskManData"
;******************************************************************************

;*** Informationen zu den Laufwerkstreibern laden.
:GetDrvInfo		lda	MP3_64K_DISK		;"Treiber von Diskette laden ?"
			beq	GetDrvInfoDisk		; => Ja, weiter...

;*** Laufwerkstreiber aus RAM installieren.
:GetDrvInfoRAM		jsr	LookForDkDvFile		;GD.DISK.CORE von REU/Disk laden.
			txa				;Fehler ?
			bne	:reset			; => Ja, Treiber/RAM abschalten.

			jsr	SetDiskDatReg		;Treiber bereits im RAM. Treiber-
			jsr	FetchRAM		;Informationen einlesen.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

::reset			jsr	TurnOffDskDvRAM		;Treiber/RAM abschalten und
;			jmp	GetDrvInfoDisk		;Daten von Diskette einlesen.

;*** Laufwerkstreiber auf Diskette suchen.
:GetDrvInfoDisk		jsr	FindDiskDrvFile		;Laufwerkstreiber-Datei suchen.
			txa				;Datei gefunden ?
			beq	:found			; => Ja, weiter...
::not_found		rts

::found			LoadW	r10,DRVINF_NG_NAMES

			ldx	#0			;Zeiger auf erste Treiberanwendung.
::loop			stx	r11L

			MoveW	r10,r6			;Zeiger auf Dateiname.
			jsr	FindFile		;Datei suchen.
			txa				;Diskettenfehler ?
			beq	:ok			; => Nein, weiter...

			ldx	r11L			;Treiberanwendung nicht
			lda	#$00			;verfügbar => Deaktivieren.
			sta	DRVINF_NG_FOUND,x
			beq	:next

::ok			ldx	r11L			;Laufwerk für Treiberanwendung
			lda	curDrive		;zwischenspeichern.
			sta	DRVINF_NG_FOUND,x

::next			AddVBW	17,r10			;Zeiger auf nächsten Treiber.

			ldx	r11L
			inx
			cpx	#DDRV_MAX		;Alle Laufwerkstreiber durchsucht ?
			bne	:loop			; => Nein, weiter...

			rts

;*** Nr. des Laufwerkstreibers berechnen.
;    Übergabe:		AKKU	= Laufwerkstyp ($01,$41,$83,$23 usw...)
;    Rückgabe:		r6	= Zeiger auf Dateiname.
;			AKKU	= $FF = unbekanntes Laufwerk.
;			xReg	= Nr. Eintrag in Typentabelle.
:GetDrvModVec		tax				;Typ = $00 ?
			beq	:exit			; => Ja, Ende...

			ldx	#1			;Zeiger auf Typen-Tabelle.
::loop			ldy	DRVINF_NG_TYPES,x	;Typ aus Tabelle einlesen.
			beq	:unknown		; => Ende erreicht ? Ja, Ende...
			cmp	DRVINF_NG_TYPES,x	;Mit aktuellem Modus vergleichen.
			beq	:found			; => Gefunden ? Ja, weiter...
			inx				;Zeiger auf nächsten Typ.
			cpx	#DDRV_MAX		;Max. Anzahl Typen durchsucht ?
			bne	:loop			; => Nein, weiter...

::unknown		lda	#$ff			;Modus: "Kein Laufwerk".
::exit			rts				;Ende.

::found			txa
			pha

			jsr	SetDrvNmVec
			MoveW	r0,r6

			pla
			tax
			rts

;*** Zeiger auf Name Laufwerkstreiber.
;Übergabe: XReg = Nummer.
;Rückgabe: r0   = Zeiger auf Name.
:SetDrvNmVec		stx	r0L			;Zeiger auf Laufwerkstyp berechnen.
			LoadB	r1L,17

			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

			AddVW	DRVINF_NG_NAMES,r0
			rts

;*** Installationsroutine und Laufwerkstreiber einlesen.
;    Übergabe:		AKKU	= Laufwerkstyp.
;    Rückgabe:		xReg	= Fehlermeldung.
:LoadDkDvData		ldx	DrvAdrGEOS
			cpx	#$08			;Erstes Laufwerk installieren ?
			beq	:1			; => Ja, weiter...
			cmp	DDrv_Type		;Treiber bereits geladen ?
			beq	LoadDkDvInit		; => Ja, weiter...

::1			tax				;Laufwerkstyp = $00 ?
			beq	:exit			; => Ja, Ende...

			jsr	GetDrvModVec		;Vektor auf Datensatz mit Treiber
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:err			; => Ja, Ende...
			tay				;Laufwerk deinstallieren?
			beq	:ok			; => Ja, Ende...

			lda	MP3_64K_DISK		;Alle Treiber in RAM ?
			bne	:load_ram		; => Nein, weiter...

;			jsr	FindDiskCore		;Treiberdatei suchen.
;			txa				;Datei gefunden ?
;			bne	:exit			; => Nein, Abbruch...

::load_disk		jmp	LoadDkDvDisk		;Treiber von Diskette laden.
::load_ram		jmp	LoadDkDvRAM		;Treiber aus RAM einlesen.

::err			ldx	#DEV_NOT_FOUND
			rts

::ok			ldx	#NO_ERROR
::exit			rts

;*** Treiber aus RAM laden.
;Übergabe: XReg = Nr. Laufwerkstreiber in Tabelle.
:LoadDkDvRAM		txa
			jsr	SetVecDskInREU		;Zeiger auf Treiber in REU.

;			lda	r3L			;Speicherbank definiert ?
			beq	LoadDkDvDisk		; => Nein, von Disk laden.

			LoadW	r0,BASE_DDRV_DATA_NG
			jsr	FetchRAM		;Treiber aus REU einlesen.

:LoadDkDvInit		lda	DrvAdrGEOS		;Ziel-Laufwerk für die
			sta	DDrv_AdrGEOS		;Laufwerksinstallation festlegen.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Treiber von Diskette laden.
;Übergabe: r6   = Zeiger auf Dateiname.
;          XReg = Nr. Laufwerkstreiber in Tabelle.
:LoadDkDvDisk		lda	DRVINF_NG_FOUND,x	;Ist Treiber verfügbar ?
			bne	:1			; => Nein, Abbruch...
			lda	SystemDevice
::1			cmp	curDrive
			beq	:2

			jsr	SetDevice		;Treiberlaufwerk aktivieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

;--- Hinweis:
;Falls das Systemlaufwerk bereits aktiv
;ist, dann nur ":SetDevice" übergehen.
;":OpenDisk" ist erforderlich, damit
;auf CMD-Laufwerken der Treiber und die
;Partition initialisiert wird.
::2			jsr	OpenDisk		;Diskette/Partition öffnen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	FindFile
			txa
			bne	:err

			MoveB	dirEntryBuf +1,r1L
			MoveB	dirEntryBuf +2,r1H
			LoadW	r7,BASE_DDRV_DATA_NG
			LoadW	r2,SIZE_DDRV_DATA_NG
			jsr	ReadFile		;Treiberdatei einlesen.
			txa				;Fehler ?
			beq	LoadDkDvInit		; => Nein, Ende...

::err			ldx	#DEV_NOT_FOUND		;Treiber nicht gefunden.
::exit			rts

;*** Zeiger auf Laufwerkstreiber in DACC setzen.
:SetVecDskInREU		tax
			asl
			tay
			lda	DRVINF_NG_START +0,y
			sta	r1L
			lda	DRVINF_NG_START +1,y
			sta	r1H
			lda	DRVINF_NG_SIZE +0,y
			sta	r2L
			lda	DRVINF_NG_SIZE +1,y
			sta	r2H
			lda	DRVINF_NG_RAMB,x
			sta	r3L
::1			rts

;*** Speicher für RAM-Laufwerkstreiber reservieren.
:AllocRAMDskDrv		ldx	#$00			;Tabelle mit Adresse der
			txa				;Speicherbank für Laufwerkstreiber
::1			sta	DRVINF_NG_RAMB,x	;löschen.
			inx
			cpx	#DDRV_MAX
			bcc	:1

			jsr	AllocRAMDsk64K		;Speicher reservieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			lda	r0L			;Erste Speicherbank für
			sta	MP3_64K_DISK		;Laufwerkstreiber in REU speichern.

::err			rts

;*** Nächste Speicher für RAM-Laufwerkstreiber reservieren.
:AllocRAMDsk64K		jsr	GetFreeBankL		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;Speicher frei ?
			bne	:err			; => Nein, Abbruch...

;			lda	r0L
			ldx	#%11000000		;GEOS/System-Speicherbank.
			jsr	AllocateBank		;Speicher reservieren.

::err			rts

;*** Speicher für RAM-Laufwerkstreiber reservieren.
:FreeRAMDskDrv		ldx	MP3_64K_DISK		;Auf MP3-Speicher für
			inx				;"Alle Treiber in REU" testen.
			inx
			cpx	MP3_64K_DATA
			bne	:ng			; => GD3/NG, weiter...

;--- Standard-Laufwerkstreiber.
			lda	MP3_64K_DISK		;2x64K Speicher freigeben.
			ldy	#$02
			jsr	FreeBankTab
			jmp	:off			;Funktion abschalten.

;--- NextGeneration-Laufwerkstreiber.
::ng			lda	MP3_64K_DISK
			sta	r0L
			jsr	FreeBank		;Erste Speicherbank freigeben.

			ldx	#$00			;Weitere Treiberanwendungen suchen.
::1			txa
			pha
			lda	DRVINF_NG_RAMB,x	;Treiberanwendung gespeichert ?
			beq	:2			; => Nein, weiter...
			cmp	r0L			;Speicher bereits freigegeben ?
			beq	:2			; => Ja, weiter...
			jsr	FreeBank		;Speicher freigeben.
::2			pla
			tax
			inx
			cpx	#DDRV_MAX		;Alle Speicherbänke geprüft ?
			bcc	:1			; => Nein, weiter...

;--- "Treiber in RAM" deaktivieren.
::off			lda	#$00
			sta	MP3_64K_DISK
			rts

;*** Laufwerkstreiber in REU kopieren.
:LoadDkDv2RAM		jsr	FindDiskDrvFile		;Systemlaufwerk aktivieren und
			txa				;GD.DISK.CORE suchen. Gefunden ?
			beq	:start			; => Ja, weiter...

;-- Ergänzung: 31.07.21/M.Kanet
;":GetDRvInfoDisk" muss hier nicht
;ausgeführt werden, da in GD.CONFIG
;bei der Intitialisierung bereits die
;Standardnamen vordefiniert werden.
;Siehe ":InitDiskCoreData".
;			jsr	GetDrvInfoDisk		;Treiber-Informationen einlesen.

			LoadW	r0,Dlg_ErrLdDk2RAM
			jsr	DoDlgBox
			ldx	#$ff
			rts

;--- Speicheraufteilung:
; :r13  = Zeiger auf Speicher in REU.
; :r14  = Zeiger auf Dateiname.
; :r15L = Zeiger auf 64K-Disk-Speicherbank #0/#1.
; :r15H = Zeiger auf Eintrag.
::start			LoadW	r13,SIZE_EDITOR_DATA_NG
			LoadW	r14,DRVINF_NG_NAMES

			lda	MP3_64K_DISK		;Speicherbank festlegen.
			sta	r15L

			lda	#0			;Zeiger auf ersten Laufwerkstreiber.
			sta	r15H

::loop			ldx	r15H
			lda	DRVINF_NG_FOUND,x	;Laufwerkstreiber verfügbar ?
			bne	:search			; => Nein, weiter...

			lda	DDRV_FDRV		;Laufwerk mit Treiberdatei
			sta	DRVINF_NG_FOUND,x	;zwischenspeichern.

::search		MoveW	r14,r6
			jsr	LoadDkDvDisk		;Laufwerkstreiber einlesen.
			txa				;Fehler ?
			beq	:found			; => Ja, Treiber ignorieren...

			ldx	r15H
			lda	#$00
			sta	DRVINF_NG_FOUND,x	;Laufwerkstreiber verfügbar ?
			beq	:next			; => Nein, weiter...

::found			lda	r7L			;Größe des eingelesenen
			sec				;Datensatzes berechnen.
			sbc	#<BASE_DDRV_DATA_NG
			sta	r2L
			lda	r7H
			sbc	#>BASE_DDRV_DATA_NG
			sta	r2H

			LoadW	r0 ,BASE_DDRV_DATA_NG
			MoveW	r13,r1			;Startadresse in REU.
			MoveB	r15L,r3L		;64K-Speicherbank in REU.

;--- Hinweis:
;":StashDskDrv" prüft ob der aktuelle
;Treiber noch in die aktuelle 64K-Bank
;passt. Falls nicht wird die Speicher-
;bank entsprechend korrigiert.
			jsr	StashDskDrv		;Treiber in DACC kopieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			lda	r15H			;Position des aktuellen Datensatz
			asl				;in REU zwischenspeichern.
			tax
			lda	r1L			;Startadresse.
			sta	DRVINF_NG_START +0,x
			lda	r1H
			sta	DRVINF_NG_START +1,x
			lda	r2L			;Größe.
			sta	DRVINF_NG_SIZE +0,x
			lda	r2H
			sta	DRVINF_NG_SIZE +1,x

			ldx	r15H
			lda	r3L			;Speicherbank.
			sta	r15L
			sta	DRVINF_NG_RAMB,x

			lda	r1L			;Position für nächsten Datensatz.
			clc
			adc	r2L
			sta	r13L
			lda	r1H
			adc	r2H
			sta	r13H
			bcc	:next

			jsr	AllocRAMDsk64K		;Zeiger auf nächste Speicherbank.

			lda	r3L			;Neue Speicherbank
			sta	r15L			;zwischenspeichern.

::next			AddVBW	17,r14			;Zeiger auf nächsten Treibernamen.

			inc	r15H			;Alle Treiber eingelesen ?
			CmpBI	r15H,DDRV_MAX
			beq	:done			; => Ja, Ende...
			jmp	:loop			; => Nein, weiter...

::done			jsr	SetDiskDatReg		;Treiberinformationen in
			jsr	StashRAM		;REU zwischenspeichern.

			ldx	#NO_ERROR		;Kein Fehler.
::err			rts

;*** Laufwerkstreiber in Speicher kopieren.
:StashDskDrv		lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3H
			lda	r1H
			adc	r2H
			bcc	:1			; => Nein, weiter...
			ora	r3H
			beq	:1			; => Nein, weiter...

			lda	r0L			;":r0" zwischenspeichern.
			pha
			lda	r0H
			pha

			jsr	GetFreeBankL		;Zeiger auf nächste Speicherbank.
			cpx	#NO_ERROR		;Speicher frei ?
			bne	:err			; => Nein, Fehler...

;			lda	r0L
			ldx	#%11000000
			jsr	AllocateBank		;Speicher reservieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			lda	r0L			;Neue Speicherbank setzen.
			sta	r3L

			lda	#$00			;Zeiger auf anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

::err			pla				;":r0" zurücksetzen.
			sta	r0H
			pla
			sta	r0L

::1			jmp	StashRAM		;Treiber in REU kopieren.

;*** Zeiger auf DACC für Laufwerksdaten setzen.
:SetDiskDatReg		LoadW	r0,BASE_EDITOR_DATA_NG
			LoadW	r1,$0000
			LoadW	r2,SIZE_EDITOR_DATA_NG
			lda	MP3_64K_DISK
			sta	r3L
			rts

;*** Neuen Laufwerksmodus auswählen.
:SlctNewDrvMode		jsr	i_FillRam
			w	DDRV_MAX*17 +DDRV_MAX
			w	SlctDvNameTab
			b	$00

			LoadW	r10,SlctDvNameTab
			LoadW	r11,DRVINF_NG_NAMES
			LoadB	r12L,0

			ldx	#0
::1			txa
			beq	:2
			lda	DRVINF_NG_FOUND,x	;Laden von Laufwerk definiert ?
			beq	:4			; => Nein, weiter...
			lda	DRVINF_NG_TYPES,x	;Laufwerksmodus definiert ?
			beq	:4			; => Nein, weiter...

::2			ldy	r12L			;Laufwerksmodus in
			sta	SlctDvTypeTab,y		;Tabelle übernehmen.

			ldy	#0			;Laufwerksname in
::3			lda	(r11L),y		;Tabelle übernehmen.
			sta	(r10L),y
			iny
			cpy	#16
			bcc	:3

			inc	r12L
			AddVBW	17,r10

::4			AddVBW	17,r11

			inx
			cpx	#DDRV_MAX
			bcc	:1

			LoadW	r0,Dlg_SlctDMode
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Laufwerkstyp auswählen.

			ldx	#CANCEL_ERR
			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:exit			; => Ja, Ende...

			ldx	DB_GetFileEntry
			ldy	SlctDvTypeTab,x

			ldx	#NO_ERROR
::exit			rts

;*** Laufwerkstreiber-Datei.
:DDRV_FDRV		b $00

;*** Titelzeile für FindDCore.
:DlgBoxTitle		b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "Laufwerksinstallation"
endif
if Sprache = Englisch
			b "Drive installation"
endif
			b NULL

;*** Dialogbox: "Laufwerkstreiber nicht gefunden!"
:Dlg_NoDskFile		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$20,$36
			w :3
			b DBTXTSTR   ,$0c,$42
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Laden der Laufwerkstreiber",NULL
::2			b "ist nicht möglich. Die Datei",NULL
::3			b "GD.DISK.CORE",NULL
::4			b "wurde nicht gefunden!",NULL
endif
if Sprache = Englisch
::1			b "Unable to load drivedrivers.",NULL
::2			b "The following system-file ",NULL
::3			b "GD.DISK.CORE",NULL
::4			b "was not found on any drive!",NULL
endif

;*** Dialogbox: "Laufwerksmodus wählen:"
:Dlg_SlctDMode		b $81
			b DBUSRFILES
			w BASE_DDRV_DATA_NG
			b CANCEL    ,$00,$00
			b DBUSRICON ,$00,$00
			w :icon
			b NULL

::icon			w Icon_01
			b $00,$00,Icon_01x,Icon_01y
			w :exit

::exit			lda	#OPEN
			sta	sysDBData
			jmp	RstrFrmDialogue

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
