; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.SDEV.ext"
endif

;*** GEOS-Header.
			n "GD.CONF.PRNINPT"
			c "GDC.PRNINPT V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Drucker/Maus konfigurieren"
endif
if LANG = LANG_EN
			h "Configure printer/mouse"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts
;******************************************************************************
;*** Systemkennung.
;******************************************************************************
			b "GDCONF10"
;******************************************************************************

;*** Programmroutinen.
			t "-GC_OpenFile"

;*** Menü initialisieren.
:InitMenu		bit	Copy_firstBoot
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

			jsr	SaveConfig		;Konfiguration übernehmen.

;*** Menü starten.
:DoAppStart		lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Aktuelle Konfiguration speichern.
:SaveConfig

;--- Ergänzung: 21.02.21/M.Kanet
;Status GCalcFix einlesen.
			jsr	GetGCalcFix		;Status GCalcFix einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** Neuen Druckertreiber laden.
:GetNewPrinter		lda	SystemDevice
			jsr	SetDevice

			LoadB	r7L,PRINTER
			LoadW	r10,$0000
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:1			; => Nein, weiter...
			rts

::1			LoadW	r0,dataFileName		;Druckertreiber laden.
			jmp	e_CopyPrntNam

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
			LoadW	r15,RegTMenu1a
			jsr	RegisterUpdate
::1			rts

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

;*** Neues Eingabegerät laden.
:GetNewInput		lda	SystemDevice
			jsr	SetDevice

			LoadB	r7L,INPUT_DEVICE
			LoadW	r10,$0000
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:1			; => Nein, weiter...
			rts

::1			LoadW	r0,dataFileName		;Eingabetreiber laden.
			jmp	e_CopyInptNam

;*** Register-Menü.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1			;Register: "Drucker".
			w RegTMenu1

			w RegTName2			;Register: "Eingabegerät".
			w RegTMenu2

:RegTName1		w RTabIcon1
			b RegCardIconX_1,$28,RTabIcon1_x,RTabIcon1_y

:RegTName2		w RTabIcon2
			b RegCardIconX_2,$28,RTabIcon2_x,RTabIcon2_y

;*** System-Icons.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

;*** Daten für Register "DRUCKER".
:RegTMenu1		b 7

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $40,$67
				w $0040,$012f
::u01			b BOX_STRING
				w RegTText1_02
				w e_LoadPrntDev
				b $50
				w $0070
				w PrntFileName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b $4f,$58
				w $00f0,$00f8
			b BOX_ICON
				w $0000
				w GetNewPrinter
				b $50
				w $00f0
				w RIcon_Select
				b (:u01 - RegTMenu1 -1)/11 +1

			b BOX_FRAME
				w RegTText1_03
				w $0000
				b $78,$af
				w $0040,$012f
			b BOX_OPTION
				w RegTText1_04
				w Swap_PrntRAM
				b $80
				w $0048
				w Flag_LoadPrnt
				b %10000000
:RegTMenu1a		b BOX_OPTION
				w RegTText1_05
				w e_InitGCalcFix
				b $98
				w $0048
				w BootGCalcFix
				b %10000000

;*** Texte für Register "DRUCKER".
if LANG = LANG_DE
:RegTText1_01		b	 "AKTIVER DRUCKER",0
:RegTText1_02		b	$48,$00,$56, "Name:",0
:RegTText1_03		b	 "OPTIONEN",0
:RegTText1_04		b	$58,$00,$86, "Druckertreiber immer von"
			b GOTOXY,$58,$00,$8e, "Diskette laden",0
:RegTText1_05		b	$58,$00,$9e, "GeoCalc-Fix verwenden"
			b GOTOXY,$58,$00,$a6, "(Bei Druckproblemen mit geoCalc64)",0
endif
if LANG = LANG_EN
:RegTText1_01		b	 "CURRENT PRINTER",0
:RegTText1_02		b	$48,$00,$56, "Name:",0
:RegTText1_03		b	 "OPTIONS",0
:RegTText1_04		b	$58,$00,$86, "Always load current printer-"
			b GOTOXY,$58,$00,$8e, "driver from disk",0
:RegTText1_05		b	$58,$00,$9e, "Enable GeoCalc-Fix"
			b GOTOXY,$58,$00,$a6, "(Fix printing issues with "
			b                      "geoCalc64)",0
endif

;*** Daten für Register "EINGABEGERÄT".
:RegTMenu2		b 4

			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$67
				w $0040,$012f
::u01			b BOX_STRING
				w RegTText2_02
				w $0000
				b $50
				w $0070
				w inputDevName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b $4f,$58
				w $00f0,$00f8
			b BOX_ICON
				w $0000
				w GetNewInput
				b $50
				w $00f0
				w RIcon_Select
				b (:u01 - RegTMenu2 -1)/11 +1

;*** Texte für Register "EINGABEGERÄT".
if LANG = LANG_DE
:RegTText2_01		b	 "AKTIVES EINGABEGERÄT",0
:RegTText2_02		b	$48,$00,$56, "Name:",0
:RegTText2_03		b	$38,$00,$ab, "(Wird beim Booten automatisch "
			b	 "installiert)",0
endif
if LANG = LANG_EN
:RegTText2_01		b	 "CURRENT INPUTDRIVER",0
:RegTText2_02		b	$48,$00,$56, "Name:",0
:RegTText2_03		b	$38,$00,$ab, "(Becomes automatically installed "
			b	 "at system-bootup)",0
endif

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= FALSE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Register-Icons.
if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

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
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + RTabIcon1_x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g RegMenuBase
;******************************************************************************
