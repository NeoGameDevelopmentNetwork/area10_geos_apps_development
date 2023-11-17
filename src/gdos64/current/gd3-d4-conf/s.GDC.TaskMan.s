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
			t "SymbTab_MMAP"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.TASK.ext"
endif

;*** GEOS-Header.
			n "obj.GDC.TaskMan"
			c "GDC.TASKMAN V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "TaskManager konfigurieren"
endif
if LANG = LANG_EN
			h "Configure TaskManager"
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

;*** Variablen.
;BootTaskStart beinhaltet den System-
;wert, StartTaskMamMse den invertierten
;Wert für das Register-Menü.
:StartTaskManMse	b $00				;$FF = TaskMan über Maustasten starten.

;*** Menü initialisieren.
:InitMenu		bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	DoAppStart		; => Ja, keine Parameterübernahme.

;--- Erststart initialisieren.
			jsr	GetTaskInstalled	;Anzahl möglicher Tasks einlesen.

			jsr	SaveConfig		;Konfiguration übernehmen.

;*** Menü starten.
:DoAppStart		lda	BootTaskStart		;Register-Optionen initialisieren.
			eor	#$ff
			sta	StartTaskManMse

			jsr	e_InitTaskData		;Externe Routinen initialisieren.

			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:1			; => Ja, keine Parameterübernahme.
			bit	Copy_BootTaskMan
			bmi	:1

			jsr	e_InitTaskMan		;TaskManager installieren.

			lda	BootTaskMan		;Status für TaskManager
			sta	Copy_BootTaskMan	;übernehmen.

::1			lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Aktuelle Konfiguration speichern.
:SaveConfig		bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:no_update		; => Ja, keine Parameterübernahme.

			lda	BootTaskMan		;TaskManager-Status festlegen.
			sta	Copy_BootTaskMan

			ldx	#$00
			lda	#%11011011
			cmp	TaskManKey2 +1
			beq	:1
			dex
::1			stx	BootTaskStart

::no_update		ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** TaskManager de-/aktivieren.
:Swap_TaskAktiv		bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:3			; => Ja, keine Parameterübernahme.

			bit	BootTaskMan		;TaskManager installiert ?
			bmi	:2			; => Nein, Ende...

			lda	BootTaskSize		;Anzahl Tasks > 0 ?
			bne	:1			; => Ja, weiter...

			lda	#MAX_TASK_STD
			sta	BootTaskSize		;Standardvorgabe für Anzahl Tasks.

::1			lda	BootTaskMan		;Status für TaskManager
			sta	Copy_BootTaskMan	;übernehmen.

			jsr	e_InitTaskMan		;TaskManager installieren.

			rts

::2			lda	#%10000000		;Inaktiv-Status für TaskManger
			sta	Copy_BootTaskMan	;übernehmen.

			jsr	e_ResetTaskMan		;TaskManager-Daten löschen.

			jsr	e_ResetSpooler		;Druckerspooler neu installieren.
			jsr	e_ReloadSpooler

::3			rts

;*** Neue Größe SpoolerRAM berechnen.
:Swap_TaskSize		ldy	BootTaskSize

			lda	mouseYPos
			sec
			sbc	#$48
			cmp	#$04			;Mehr/Weniger ?
			bcs	:1			; => Weniger, weiter...

			cpy	#MAX_TASK_ACTIV		;Max. Anzahl Tasks erreicht ?
			beq	:3			; => Ja, Ende...

			iny				;Anzahl Tasks +1.
			lda	#%00000000		;TaskManager aktivieren.
			sta	BootTaskMan
			jmp	:2			;Anzahl Tasks aktualisieren.

::1			tya				;Anzahl Tasks = 0 ?
			beq	:3			; => Ja, Ende...
			dey				;Anzahl Tasks -1.
			bne	:2
			lda	#%10000000		;TaskManager deaktivieren.
			sta	BootTaskMan

::2			sty	BootTaskSize		;Anzahl Tasks aktualisieren.

			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:3			; => Ja, keine Parameterübernahme.

			jmp	e_InitTaskMan		;TaskManager installieren.

::3			rts

;*** Anzahl verfügbarer Tasks im aktuellen TaskManager ermitteln.
:GetTaskInstalled	bit	Copy_BootTaskMan	;War TaskManager aktiv ?
			bpl	:2			; => Nein, weiter...

::off			lda	#$00			;TaskManager-Daten löschen.
			sta	Flag_TaskBank

			ldx	#MAX_TASK_ACTIV -1
::1			sta	e_BankTaskAdr ,x	;Speicherbänke löschen.
			sta	e_BankTaskOpen,x
			dex
			bpl	:1

			lda	#%10000000		;TaskManager deaktivieren.
			sta	BootTaskMan

			rts

;--- Variablen aus TaskManager einlesen.
::2			LoadW	r0,e_BankTaskAdr
			LoadW	r1,RTA_TASKMAN +3
			LoadW	r2,2*9 +1
			lda	Flag_TaskBank		;TaskManager-Bank vorhanden ?
			beq	:off			; => Nein, TaskMan deaktivieren.
			sta	r3L
			jsr	FetchRAM		;TaskManager-Daten einlesen.

;--- Anzahl Tasks ermitteln.
			ldx	#MAX_TASK_ACTIV -1
			ldy	#$00
::3			lda	e_BankTaskAdr,x		;Bank reserviert?
			beq	:4			; => Nein, weiter...
			iny				;Anzahl Tasks +1.
::4			dex				;Alle Tasks überprüft?
			bpl	:3			; => Nein, weiter...

			sty	BootTaskSize		;Max. Anzahl Tasks speichern.

			lda	#%00000000		;TaskManager aktivieren.
			sta	BootTaskMan

			rts

;*** Startart wechseln.
:SwapTaskMode1		lda	StartTaskManMse
			eor	#$ff
			sta	BootTaskStart
			jmp	SwapTaskMode

:SwapTaskMode2		lda	BootTaskStart
			eor	#$ff
			sta	StartTaskManMse

:SwapTaskMode		jsr	e_InitTManKey

			lda	BootTaskStart
			eor	#$ff
			sta	StartTaskManMse

			LoadW	r15,RegTMenu2a		;Registerkarte aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu2b		;Registerkarte aktualisieren.
			jmp	RegisterUpdate

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
:RIcon_UpDown		w Icon_MUpDown
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MUpDown_x,Icon_MUpDown_y
			b USE_COLOR_INPUT

;*** Daten für Register "TASKMANAGER".
:RegTMenu1		b 2

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu1a		b BOX_OPTION
				w RegTText1_02
				w Swap_TaskAktiv
				b $50
				w $0048
				w BootTaskMan
				b %10000000

;*** Texte für Register "TASKMANAGER".
if LANG = LANG_DE
:RegTText1_01		b	 "TASKMANAGER",0
:RegTText1_02		b	$58,$00,$56, "TaskManager nicht installieren",0
endif
if LANG = LANG_EN
:RegTText1_01		b	 "TASKMANAGER",0
:RegTText1_02		b	$58,$00,$56, "Do not install the TaskManager",0
endif

;*** Daten für Register "EINSTELLUNGEN".
:RegTMenu2		b 7

			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$5f
				w $0040,$012f
::u01			b BOX_NUMERIC_VIEW
				w RegTText2_02
				w $0000
				b $48
				w $0108
				w BootTaskSize
				b 2!NUMERIC_RIGHT!NUMERIC_BYTE
			b BOX_FRAME
				w $0000
				w $0000
				b $47,$50
				w $0118,$0120
			b BOX_ICON
				w $0000
				w Swap_TaskSize
				b $48
				w $0118
				w RIcon_UpDown
				b (:u01 - RegTMenu2 -1)/11 +1

			b BOX_FRAME
				w RegTText2_03
				w $0000
				b $70,$af
				w $0040,$012f
:RegTMenu2a		b BOX_OPTION
				w RegTText2_04
				w SwapTaskMode1
				b $78
				w $0048
				w StartTaskManMse
				b %11111111
:RegTMenu2b		b BOX_OPTION
				w RegTText2_05
				w SwapTaskMode2
				b $90
				w $0048
				w BootTaskStart
				b %11111111

;*** Texte für Register "EINSTELLUNGEN".
if LANG = LANG_DE
:RegTText2_01		b	 "ANWENDUNGEN",0
:RegTText2_02		b	$48,$00,$4e, "Max. gleichzeitig verfügbare"
			b GOTOXY,$48,$00,$56, "Anwendungen im TaskManager:",0
:RegTText2_03		b	 "AKTIVIEREN",0
:RegTText2_04		b	$58,$00,$7e, "TaskManager über Tastatur mit"
			b GOTOXY,$58,$00,$86, "<CBM> + <CTRL> starten",0
:RegTText2_05		b	$58,$00,$96, "TaskManager über linke und"
			b GOTOXY,$58,$00,$9e, "rechte Maustaste starten",0
endif
if LANG = LANG_EN
:RegTText2_01		b	 "APPLICATIONS",0
:RegTText2_02		b	$48,$00,$4e, "Select a maximum of"
			b GOTOXY,$48,$00,$56, "available applications:",0
:RegTText2_03		b	 "ACTIVATE",0
:RegTText2_04		b	$58,$00,$7e, "Activate TaskManager by using"
			b GOTOXY,$58,$00,$86, "<CBM> + <CTRL>-keys",0
:RegTText2_05		b	$58,$00,$96, "Activate TaskManager by using"
			b GOTOXY,$58,$00,$9e, "left and right mouse-button",0
endif

;*** System-Icons einbinden.
if .p
:EnableMSelect		= FALSE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= TRUE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Register-Icons.
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

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
