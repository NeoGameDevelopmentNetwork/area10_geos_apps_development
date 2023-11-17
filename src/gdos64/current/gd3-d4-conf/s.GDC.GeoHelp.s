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
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.HELP.ext"
endif

;*** GEOS-Header.
			n "GD.CONF.GEOHELP"
			c "GDC.GEOHELP V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "HilfeSystem konfigurieren"
endif
if LANG = LANG_EN
			h "Configure HelpSystem"
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

;*** Menü initialisieren.
:InitMenu		bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	DoAppStart		; => Ja, keine Parameterübernahme.

;--- Erststart initialisieren.
			jsr	SaveConfig		;Konfiguration übernehmen.

;*** Menü starten.
:DoAppStart		lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Aktuelle Konfiguration speichern.
:SaveConfig		lda	HelpSystemActive
			sta	BootHelpSysMode
			lda	HelpSystemDrive
			sta	BootHelpSysDrv
			lda	HelpSystemPart
			sta	BootHelpSysPart
			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** HilfeSystem de-/aktivieren.
:Swap_HelpSystem	lda	HelpSystemActive	;HilfeSystem aktiviert ?
			bpl	:1			; => Nein, weiter...

			jsr	e_InitHelpSys		;HilfeSystem nachladen.
			txa				;System installiert ?
			beq	:3			; => Ja, Ende...

::1			lda	HelpSystemBank		;Bereits belegte Speicherbank
			beq	:2			;für Hilfesystem wieder freigeben.
			jsr	FreeBank

::2			lda	#$00			;Hilfesystem kann nicht
			sta	HelpSystemActive	;aktiviert werden.
::3			rts

;*** Hilfe-Laufwerk wechseln.
:Swap_HelpDrive		lda	HelpSystemDrive
			jsr	e_ChkHelpDrv		;Hilfe-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			beq	:found			; => Ja, weiter...

::err			jsr	InitHelpDrive		;Hilfe-Laufwerk initialisieren.

			ldy	HelpSystemActive	;Hilfe-Laufwerk gefunden?
			bne	:found			; => Ja, weiter...
			rts

::found			tya
::setHelpDrv		jsr	SetDevice		;Hilfe-Laufwerk aktivieren.

			lda	#$00			;Aktive Partition einlesen und
			ldx	curDrive		;zwischenspeichern. Bei CBM-
			stx	r15L			;Laufwerken Partition = #0 setzen.
			ldy	RealDrvMode -8,x
			bpl	:1

			jsr	OpenDisk

			lda	#$00
			cpx	#NO_ERROR
			bne	:1

			ldx	curDrive
			lda	drivePartData -8,x
::1			sta	r15H

			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName		;Für DBGETFILES erforderlich!
			jsr	DoDlgBox		;Partition/Laufwerk wählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:ok_cancel		; => Nein, weiter...
			and	#%00001111

;--- Laufwerk/Partition wechseln.
			pha
			jsr	:resetDrive		;Partition auf aktivem Laufwerk
			pla				;wieder zurücksetzen.
			bne	:setHelpDrv		;Laufwerk/Partition wechseln.

;--- OK/Abbruch gewählt.
::ok_cancel		cmp	#CANCEL			;"ABBRUCH" gewählt ?
			beq	:resetDrive		; => Ja, Ende...

			ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bmi	:cmd			; => Ja, Partition auswerten.

::cbm			ldx	curDrive		;Aktives Laufwerk und
			lda	#$00			;Keine Partition.
			jmp	:setHelpData		; => Ende...

::cmd			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:cbm			; => Ja, Laufwerk zurücksetzen.

			ldx	curDrive		;Partitioniertes Laufwerk.
			lda	drivePartData-8,x	;Laufwerkstyp und Partition
			tay				;übernehmen.
			lda	RealDrvType  -8,x
			tax
			tya

::setHelpData		sta	HelpSystemPart		;Partition und Laufwerk
			stx	HelpSystemDrive		;festlegen.

;--- Laufwerk zurücksetzen.
::resetDrive		lda	r15L
			jsr	SetDevice

			ldx	curDrive		;Partition auf Laufwerk
			lda	RealDrvMode -8,x	;wieder zurücksetzen.
			bpl	:exit
			lda	r15H
			beq	:exit
			sta	r3H
			jsr	OpenPartition
::exit			rts

;*** Hilfe-Laufwerk anzeigen.
:PrintHelpDrive		lda	HelpSystemDrive		;Hilfe-Laufwerk definiert?
			beq	InitHelpDrive		; => Ja, weiter...

:PrntCurHelpDrv		tax
			and	#%11110000		;CMD-Laufwerk?
			bne	PrintDriveCMD		; => Ja, Typ+Partition ausgeben.

;			ldx	HelpSystemDrive
			lda	driveType -8,x		;Laufwerk definiert?
			beq	InitHelpDrive		; => Nein, System-Laufwerk testen.

			jmp	PrintDriveABCD		; => Nein, Laufwerk ausgeben.

;*** Hilfe-Laufwerk initialisieren.
:InitHelpDrive		ldx	SystemDevice
			lda	driveType -8,x		;System-Laufwerk definiert?
			bne	:setHelpDrv		; => Ja, weiter...

			ldx	#8			;Erstes gültiges Laufwerk suchen.
::search		lda	driveType -8,x
			bne	:setHelpDrv
			inx
			cpx	#12
			bcc	:search
			bcs	disableHelp

::setHelpDrv		txa
			sta	HelpSystemDrive		;Hilfe-Laufwerk speichern.
			jmp	PrntCurHelpDrv

:disableHelp		lda	#$00			;Kein Laufwerk, Hilfe abschalten.
			sta	HelpSystemActive
			sta	HelpSystemDrive
			rts

;*** CMD-Laufwerk ausgeben.
:PrintDriveCMD		lda	HelpSystemDrive
			jsr	e_ChkHelpDrv		;Hilfe-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			beq	:found			; => Ja, weiter...

::err			lda	HelpSystemDrive
			and	#%11110000		;CMD-Laufwerk?
			beq	disableHelp		; => Nein, Hilfe abschalten...
			bne	InitHelpDrive		; => Ja, System-Laufwerk testen...

::found			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	HelpSystemPart		;Partitionsdaten einlesen.
			bne	:11
			lda	#$ff
::11			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			LoadW	r11,$0072
			LoadB	r1H,$56

			ldy	#$00			;Laufwerkstyp suchen um
::21			lda	HelpSystemDrive		;Text für Ausgabe zu ermitteln.
			and	#DrvCMD
			cmp	CMDNameTab,y
			beq	:22
			iny
			iny
			iny
			iny
			cpy	#3 *4			;HD/RL/FD getestet?
			bne	:21
			beq	:err

::22			iny				;Laufwerkstyp ausgeben.
			tya
			clc
			adc	#< CMDNameTab
			sta	r0L
			lda	#$00
			adc	#> CMDNameTab
			sta	r0H
			jsr	PutString
			lda	#":"
			jsr	SmallPutChar

			ldy	#$00			;Partitions-Name ausgeben.
::31			tya
			pha
			lda	dirEntryBuf +3,y
			beq	:41
			cmp	#$a0
			beq	:41
			cmp	#$20
			bcc	:32
			jsr	SmallPutChar
::32			pla
			tay
			iny
			cpy	#$10
			bcc	:31
			rts

::41			pla
			rts

;*** GEOS-Laufwerk ausgeben.
:PrintDriveABCD		lda	HelpSystemDrive		;Zeiger auf Laufwerkstext
			sec				;berechnen und ausgeben.
			sbc	#$08
			asl
			asl
			asl
			asl
			clc
			adc	#< DrvNameTab
			sta	r0L
			lda	#$00
			adc	#> DrvNameTab
			sta	r0H
			jmp	PutString

;*** Variablen.
:DrvNameTab
if LANG = LANG_DE
			b "Laufwerk A:    ",0
			b "Laufwerk B:    ",0
			b "Laufwerk C:    ",0
			b "Laufwerk D:    ",0
endif
if LANG = LANG_EN
			b "Drive A:       ",0
			b "Drive B:       ",0
			b "Drive C:       ",0
			b "Drive D:       ",0
endif

:CMDNameTab		b DrvFD     ,"FD",0
			b DrvHD     ,"HD",0
			b DrvRAMLink,"RL",0

:NoHelpActive		b $00

;*** Dialogbox: Datei wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Register-Menü.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1			;Register: "TaskManager".
			w RegTMenu1

			w RegTName2			;Register: "Einstellungen".
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

;*** Daten für Register "HILFESYSTEM".
:RegTMenu1		b 2

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu1a		b BOX_OPTION
				w RegTText1_02
				w Swap_HelpSystem
				b $50
				w $0048
:RegTMenu1b			w HelpSystemActive
				b %11111111

if LANG = LANG_DE
:RegTText1_01		b	 "HILFESYSTEM",0
:RegTText1_02		b	$58,$00,$56, "Hilfesystem installieren"
			b GOTOXY,$48,$00,$86, "Diese Option benötigt 64K des"
			b GOTOXY,$48,$00,$8e, "erweiterten Speichers"
			b GOTOXY,$48,$00,$9e, "Über <F1> ist dann das HilfeSystem"
			b GOTOXY,$48,$00,$a6, "von GDOS64 jederzeit erreichbar.",0
endif
if LANG = LANG_EN
:RegTText1_01		b	 "HELPSYSTEM",0
:RegTText1_02		b	$58,$00,$56, "Install HelpSystem"
			b GOTOXY,$48,$00,$86, "This option need 64K of your"
			b GOTOXY,$48,$00,$8e, "extended memory"
			b GOTOXY,$48,$00,$9e, "At any time you can hit <F1> to"
			b GOTOXY,$48,$00,$a6, "start the GDOS64 help system.",0
endif

;*** Daten für Register "EINSTELLUNGEN".
:RegTMenu2		b 4

			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu2a		b BOX_USEROPT_VIEW
				w RegTText2_02
				w PrintHelpDrive
				b $50,$57
				w $0070,$010f
			b BOX_FRAME
				w $0000
				w $0000
				b $4f,$58
				w $0110,$0118
:RegTMenu2b		b BOX_ICON
				w $0000
				w Swap_HelpDrive
				b $50
				w $0110
				w RIcon_Select
				b (RegTMenu2a - RegTMenu2 -1)/11 +1

;*** Texte für Register "EINSTELLUNGEN".
if LANG = LANG_DE
:RegTText2_01		b	 "HILFETEXT-LAUFWERK",0
:RegTText2_02		b	$48,$00,$56, "Typ:"
			b GOTOXY,$48,$00,$7e, "GDOS64 wird auf diesem Laufwerk"
			b GOTOXY,$48,$00,$86, "nach den Hilfetexten suchen."
			b GOTOXY,$48,$00,$96, "Bei Standard-Laufwerken wird die"
			b GOTOXY,$48,$00,$9e, "aktuelle Diskette verwendet, bei CMD"
			b GOTOXY,$48,$00,$a6, "Laufwerken die angegebene Partition."
			b NULL
endif
if LANG = LANG_EN
:RegTText2_01		b	 "HELPFILE-DRIVE",0
:RegTText2_02		b	$48,$00,$56, "Type:"
			b GOTOXY,$48,$00,$7e, "GDOS64 will search onb this drive"
			b GOTOXY,$48,$00,$86, "for the needed help documents."
			b GOTOXY,$48,$00,$96, "When using standard diskdrives the"
			b GOTOXY,$48,$00,$9e, "current disk is used. CMD-drives"
			b GOTOXY,$48,$00,$a6, "will use the selected partition.",0
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
