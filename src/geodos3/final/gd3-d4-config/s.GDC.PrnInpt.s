; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;*** GEOS-Header.
			n "GD.CONF.PRNINPT"
			c "GDC.PRNINPT V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Drucker/Maus konfigurieren"
endif
if Sprache = Englisch
			h "Configure printer/mouse"
endif

;*** Sprungtabelle.
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts

;*** Menü initialisieren.
:InitMenu		bit	firstBoot		;GEOS-BootUp ?
			bpl	DoAutoBoot		; => Ja, automatisch installieren.
			bit	Copy_firstBoot
			bpl	DoAppStart

;--- Erststart initialisieren.
			lda	Flag_LoadPrnt		;Aktuelle Konfiguration
			sta	BootPrntMode		;in Boot-Variablen kopieren.

			ldy	#$10
::1			lda	PrntFileName,y
			sta	BootPrntName,y
			lda	inputDevName,y
			sta	BootInptName,y
			dey
			bpl	:1

;--- Ergänzung: 21.02.21/M.Kanet
;Status GCalcFix einlesen.
			jsr	GetGCalcFix		;Status GCalcFix einlesen.

;*** Menü starten.
:DoAppStart		jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

;*** System-Boot.
:DoAutoBoot		lda	BootPrntMode		;Modus zum Laden des
			sta	Flag_LoadPrnt		;Druckertreibers festlegen.

			jsr	InitGCalcFix		;GeoCalc-BugFix aktivieren.

			jsr	InitPrntDevice		;Drucker installieren.
			jmp	InitInptDevice		;Eingabetreiber installieren.

;*** Aktuelle Konfiguration speichern.
:SaveConfig

;--- Ergänzung: 21.02.21/M.Kanet
;Status GCalcFix einlesen.
			jsr	GetGCalcFix		;Status GCalcFix einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;******************************************************************************
;*** Drucker-Routinen.
;******************************************************************************
;*** Neuen Druckertreiber laden.
:GetNewPrinter		LoadB	r7L,PRINTER
			LoadW	r10,$0000
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:1			; => Nein, weiter...
			rts

::1			LoadW	r0,dataFileName		;Druckertreiber laden.
			jmp	LoadPrntDevice

;*** Ersten Druckertreiber auf Diskette suchen/laden.
:InitPrntDevice		lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			lda	#<BootPrntName
			ldx	#>BootPrntName
			ldy	BootPrntName		;Druckername definiert ?
			bne	:2			; => Ja, weiter...

			sta	r6L
			stx	r6H
			LoadB	r7L,PRINTER
			jsr	FindSysDevice
			txa
			beq	:1

			lda	#<NoPrntName
			ldx	#>NoPrntName
			bne	:2			; => Nein, Abbruch...

::1			lda	#<BootPrntName
			ldx	#>BootPrntName
::2			sta	r0L
			stx	r0H

;*** Druckertreiber laden.
;    Übergabe:		r0 = Zeiger auf Dateiname.
:LoadPrntDevice		lda	#<BootPrntName
			ldx	#>BootPrntName
			jsr	CopyStrg_Device

:BootPrntDevice		lda	#<PrntFileName
			ldx	#>PrntFileName
			jsr	CopyStrg_Device

;*** Druckertreiber laden.
;    Beim C64 wird damit automatisch der Treiber auch in die
;    Speichererweiterung kopiert.
:GetPrntDrvFile		LoadW	r0 ,NoPrntName
			LoadW	r6 ,PrntFileName
			ldx	#r0L
			ldy	#r6L
			jsr	CmpString		;Drucker definiert ?
			beq	:1			; => Nein, weiter...

			LoadW	r7 ,PRINTBASE
			LoadB	r0L,%00000001
			jmp	GetFile			;Druckertreiber einlesen.
::1			rts

;*** "Druckertreiber-von-Disk" aktualisieren.
:Swap_PrntRAM		lda	Flag_LoadPrnt
			sta	BootPrntMode
;--- Ergänzung: 31.12.18/M.Kanet
;geoCalc64 nutzt beim drucken ab $5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert.
;Wird der Druckertreiber von Disk geladen, dann kann der Fix nicht
;auf den aktuellen Druckertreiber angewendet werden.
			beq	:1
			lda	#$00			;Treiber von Disk => GCalcFix=Aus.
			sta	BootGCalcFix
			LoadW	r15,RegTMenu_1a
			jsr	RegisterUpdate
::1			rts

;--- Ergänzung: 31.12.18/M.Kanet
;*** GeoCalc-BugFix aktivieren.
;Die Option reduziert die erlaubte Größe von Druckertreibern im RAM/Spooler
;um 1Byte, da GeoCalc ab $7F3F Programmcode nutzt. Dieses Byte ist aber noch
;für Druckertreiber reserviert.
:InitGCalcFix		ldx	#$40			;Größe: $7900 - $7F3F.
			bit	BootGCalcFix		;GCalc-Fix aktiv?
			bpl	:1			; => Nein, weiter...
			dex
::1			stx	GCalcFix1 +4
			stx	GCalcFix2 +4
			rts

;--- Ergänzung: 21.02.21/M.Kanet
;*** GeoCalc-Fix aktiv?
:GetGCalcFix		lda	#$40
			cmp	GCalcFix1 +4
			bne	:gcalcfix_on
			cmp	GCalcFix2 +4
			bne	:gcalcfix_on
::gcalcfix_off		lda	#%00000000
			b $2c
::gcalcfix_on		lda	#%10000000
			sta	BootGCalcFix
			rts

;******************************************************************************
;*** Eingabegeräte-Routinen.
;******************************************************************************
;*** Neues Eingabegerät laden.
:GetNewInput		LoadB	r7L,INPUT_DEVICE
			LoadW	r10,$0000
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:1			; => Nein, weiter...
			rts

::1			LoadW	r0,dataFileName		;Eingabetreiber laden.
			jmp	LoadInptDevice

;*** Ersten Eingabetreiber auf Diskette suchen/laden.
:InitInptDevice		lda	#<BootInptName
			ldx	#>BootInptName
			ldy	BootInptName		;Eingabegerät definiert ?
			bne	:2			; => Ja, weiter...

			sta	r6L
			stx	r6H

			LoadB	r7L,INPUT_DEVICE
			jsr	FindSysDevice
			txa
			beq	:1

			lda	#<NoInptName
			ldx	#>NoInptName
			bne	:2			; => Nein, Abbruch...

::1			lda	#<BootInptName
			ldx	#>BootInptName
::2			sta	r0L
			stx	r0H

;*** Eingabetreiber laden.
;    Übergabe:		r0 = Zeiger auf Dateiname.
:LoadInptDevice		lda	#<BootInptName
			ldx	#>BootInptName
			jsr	CopyStrg_Device

:BootInptDevice		lda	#<inputDevName
			ldx	#>inputDevName
			jsr	CopyStrg_Device

;*** Eingabegerät laden.
:GetInpDrvFile		LoadW	r0 ,NoInptName
			LoadW	r6 ,inputDevName
			ldx	#r0L
			ldy	#r6L
			jsr	CmpString		;Eingabegerät definiert ?
			beq	:1			; => Nein, weiter...

			jsr	ClearMouseMode

			LoadB	r0L,%00000001
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile
			jsr	InitMouse

			clc
			jsr	StartMouseMode

			lda	mouseOn
			ora	#%00100000
			sta	mouseOn
::1			rts

;*** Dateiname für Eingabe-/Druckertreiber kopieren.
:CopyStrg_Device	sta	r1L
			stx	r1H
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;******************************************************************************
;*** Drucker-/Eingabegeräte-Routinen.
;******************************************************************************
;*** Druckertreiber/Eingabetreiber auf Diskette suchen.
:FindSysDevice		lda	SystemDevice
			jsr	SetDevice
			jsr	FindDevice		;Treiber suchen.
			txa				;Diskettenfehler ?
			beq	:6			; => Nein, weiter...

;--- Auf allen Laufwerken nach erstem Treiber suchen.
::1			ldx	#8			;Suche initialisieren.
::2			cpx	SystemDevice		;Systemlaufwerk untersuchen ?
			beq	:4			; => Ja, übergehen.

			lda	driveType -8,x		;Ist Laufwerk definiert ?
			beq	:4			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, nächstes Laufwerk.

			jsr	FindDevice		;Treiber suchen.
			txa				;Diskettenfehler ?
			beq	:6			; => Nein, weiter...

::3			ldx	curDrive		;Aktuelles Laufwerk einlesen.
::4			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke durchsucht ?
			bcc	:2			; => Nein, weiter...

::5			ldx	#FILE_NOT_FOUND
			rts
::6			ldx	#NO_ERROR
			rts

;*** Druckertreiber-Datei uchen.
:FindDevice		PushW	r6
			PushB	r7L

			LoadB	r7H,$01
			LoadW	r10,$0000
			jsr	FindFTypes		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			lda	r7H
			beq	:1
			ldx	#FILE_NOT_FOUND

::1			PopB	r7L
			PopW	r6
			rts

;*** Systemtexte.
if Sprache = Deutsch
:NoPrntName		b "Kein Drucker!",NULL
:NoInptName		b "Keine Maus!",NULL
endif
if Sprache = Englisch
:NoPrntName		b "No printer!",NULL
:NoInptName		b "No mouse!",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1_1			;Register: "Drucker".
			w RegTMenu_1

			w RegTName1_2			;Register: "Eingabegerät".
			w RegTMenu_2

:RegTName1_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x,Icon_20y

:RegTName1_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x,Icon_21y

;*** Daten für Register "DRUCKER".
:RegTMenu_1		b 7

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $40,$67
				w $0040,$012f
::u01			b BOX_STRING			;----------------------------------------
				w RegTText_1_02
				w GetPrntDrvFile
				b $50
				w $0070
				w PrntFileName
				b 16
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $4f,$58
				w $00f0,$00f8
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewPrinter
				b $50
				w $00f0
				w RegTIcon1_1_01
				b (:u01 - RegTMenu_1 -1)/11 +1

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_03
				w $0000
				b $78,$af
				w $0040,$012f
			b BOX_OPTION			;----------------------------------------
				w RegTText_1_04
				w Swap_PrntRAM
				b $80
				w $0048
				w Flag_LoadPrnt
				b %10000000
:RegTMenu_1a		b BOX_OPTION			;----------------------------------------
				w RegTText_1_05
				w InitGCalcFix
				b $98
				w $0048
				w BootGCalcFix
				b %10000000

:RegTIcon1_1_01		w Icon_09
			b $00,$00,$01,$08
			b $ff

if Sprache = Deutsch
:RegTText_1_01		b	 "AKTIVER DRUCKER",0
:RegTText_1_02		b	$48,$00,$56, "Name:",0
:RegTText_1_03		b	 "OPTIONEN",0
:RegTText_1_04		b	$58,$00,$86, "Druckertreiber immer von"
			b GOTOXY,$58,$00,$8e, "Diskette laden",0
:RegTText_1_05		b	$58,$00,$9e, "GeoCalc-Fix"
			b GOTOXY,$58,$00,$a6, "(Bei Druckproblemen mit geoCalc64)",0
endif
if Sprache = Englisch
:RegTText_1_01		b	 "CURRENT PRINTER",0
:RegTText_1_02		b	$48,$00,$56, "Name:",0
:RegTText_1_03		b	 "OPTIONS",0
:RegTText_1_04		b	$58,$00,$86, "Always load current printer-"
			b GOTOXY,$58,$00,$8e, "driver from disk",0
:RegTText_1_05		b	$58,$00,$9e, "GeoCalc-Fix"
			b GOTOXY,$58,$00,$a6, "(Fix printing issues with "
			b                      "geoCalc64)",0
endif

;*** Daten für Register "EINGABEGERÄT".
:RegTMenu_2		b 4

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$67
				w $0040,$012f
::u01			b BOX_STRING			;----------------------------------------
				w RegTText_2_02
				w $0000
				b $50
				w $0070
				w inputDevName
				b 16
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $4f,$58
				w $00f0,$00f8
			b BOX_ICON			;----------------------------------------
				w $0000
				w GetNewInput
				b $50
				w $00f0
				w RegTIcon1_1_01
				b (:u01 - RegTMenu_2 -1)/11 +1

if Sprache = Deutsch
:RegTText_2_01		b	 "AKTIVES EINGABEGERÄT",0
:RegTText_2_02		b	$48,$00,$56, "Name:",0
:RegTText_2_03		b	$38,$00,$ab, "(Wird beim Booten automatisch "
			b	 "installiert)",0
endif
if Sprache = Englisch
:RegTText_2_01		b	 "CURRENT INPUTDRIVER",0
:RegTText_2_02		b	$48,$00,$56, "Name:",0
:RegTText_2_03		b	$38,$00,$ab, "(Becomes automatically installed "
			b	 "at system-bootup)",0
endif

;*** Icons.
:Icon_09
<MISSING_IMAGE_DATA>
:Icon_09x		= .x
:Icon_09y		= .y

if Sprache = Deutsch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

if Sprache = Englisch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

if Sprache = Deutsch
:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y
endif

if Sprache = Englisch
:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + Icon_20x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
