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
			n "GD.CONF.TASKMAN"
			c "GDC.TASKMAN V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "TaskManager konfigurieren"
endif
if Sprache = Englisch
			h "Configure TaskManager"
endif

;*** Sprungtabelle.
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts

;******************************************************************************
;*** TaskSwitcher.
;******************************************************************************
:x_TaskMan		d "obj.TaskSwitch"
:x_TaskManEnd
;******************************************************************************

;*** Menü initialisieren.
:InitMenu		bit	firstBoot		;GEOS-BootUp ?
			bpl	DoAutoBoot		; => Ja, automatisch installieren.
			bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	DoAppStart		; => Ja, keine Parameterübernahme.

;--- Erststart initialisieren.
			jsr	GetTaskInstalled	;Anzahl installierter Tasks
			sty	BootTaskSize		;einlesen und speichern.

;*** Menü starten.
:DoAppStart		ldx	#$00
			lda	#%11011011
			cmp	TaskManKey2 +1
			beq	:1
			dex
::1			stx	BootTaskStart

			jsr	InitTaskManager

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

;*** System-Boot.
:DoAutoBoot		lda	BootTaskMan		;TaskManager-Status festlegen.
			sta	Copy_BootTaskMan
			bmi	:1			; => Nein, weiter...
			jsr	InitTaskManager		;TaskManager installieren.
::1			rts

;*** Aktuelle Konfiguration speichern.
:SaveConfig		lda	BootTaskMan		;TaskManager-Status festlegen.
			sta	Copy_BootTaskMan

			ldx	#$00
			lda	#%11011011
			cmp	TaskManKey2 +1
			beq	:1
			dex
::1			stx	BootTaskStart

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;******************************************************************************
;*** TaskManager-Routinen.
;******************************************************************************
;*** TaskManager de-/aktivieren.
:Swap_TaskAktiv		lda	BootTaskMan		;TaskManager installiert ?
			bmi	:2			; => Nein, Ende...

			lda	BootTaskSize		;Anzahl Tasks > 0 ?
			bne	:1			; => Ja, weiter...

			inc	BootTaskSize		;Mind. 1 Task installieren.
::1			jmp	InitTaskManager		;TaskManager installieren.

::2			jsr	ClrTaskManBank		;TaskManager-Daten löschen.
			jsr	ClrRAM_Spooler		;Druckerspooler neu installieren.
			jmp	SetRAM_Spooler

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
			lda	#%11111111		;TaskManager deaktivieren.
			sta	BootTaskMan

::2			sty	BootTaskSize		;Anzahl Tasks aktualisieren.
			jmp	InitTaskManager
::3			rts

;*** Anzahl verfügbarer Tasks im aktuellen TaskManager ermitteln.
:GetTaskInstalled	bit	BootTaskMan		;TaskManager aktiv ?
			bpl	:2			; => Ja, weiter...

			ldx	#MAX_TASK_ACTIV-1
			lda	#$00			;TaskManager-Daten löschen.
::1			sta	BankTaskAdr ,x
			sta	BankTaskActive,x
			dex
			bpl	:1

			ldy	#$00
			rts

;--- Variablen aus TaskManager einlesen.
::2			LoadW	r0 ,BankTaskAdr
			LoadW	r1 ,RT_ADDR_TASKMAN +3
			LoadW	r2 ,2*9 +1
			lda	Flag_TaskBank
			sta	r3L
			jsr	FetchRAM

;--- Anzahl Tasks ermitteln.
			ldx	#MAX_TASK_ACTIV -1
			ldy	#$00
::3			lda	BankTaskAdr,x
			beq	:4
			iny
::4			dex
			bpl	:3
			rts

;******************************************************************************
;*** TaskManager-Routinen.
;******************************************************************************
;*** TaskManager-Speicherbänke freigeben.
:ClrTaskManBank		ldy	#$00
::1			sty	r2L
			lda	#$00
			sta	BankTaskActive ,y

			ldx	BankTaskAdr  ,y
			beq	:2
			lda	#$00
			sta	BankTaskAdr  ,y
			txa
			jsr	FreeBank

::2			ldy	r2L
			iny
			cpy	#MAX_TASK_ACTIV
			bcc	:1
			rts

;*** Startart wechseln.
:SwapTaskMode1		lda	StartTaskManMse
			eor	#$ff
			sta	BootTaskStart
			jmp	SwapTaskMode

:SwapTaskMode2		lda	BootTaskStart
			eor	#$ff
			sta	StartTaskManMse

:SwapTaskMode		jsr	InitTaskManKey

			LoadW	r15,RegTMenu_2a		;Registerkarte aktualisieren.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu_2b		;Registerkarte aktualisieren.
			jmp	RegisterUpdate

;*** Startart für TaskManager definieren.
:InitTaskManKey		lda	#%01111111		;CBM/CTRL.
			sta	TaskManKey1 +1
			lda	#%11011011
			sta	TaskManKey2 +1

			lda	BootTaskStart
			beq	:1

			lda	#%01111111		;Linke/rechte Maustaste.
			sta	TaskManKey1 +1
			lda	#%11101110
			sta	TaskManKey2 +1

::1			lda	BootTaskStart
			eor	#$ff
			sta	StartTaskManMse
			rts

;******************************************************************************
;*** TaskManager-Routinen.
;******************************************************************************
;*** TaskManager installieren.
:InitTaskManager	lda	BootTaskSize		;TaskManager aktivieren ?
			beq	:6			; => Nein, weiter...

::1			jsr	ClrTaskManBank		;TaskManager-Bänke freigeben.
			jsr	ClrRAM_Spooler		;Spooler-RAM freigeben.

			lda	#$00
			sta	r2L
::2			jsr	GetFreeBankL		;Speicherbank suchen.
			cpx	#NO_ERROR		;Bank gefunden ?
			bne	:5			; => Nein, weiter...

			ldy	r2L			;Bank in Tabelle eintragen.
			sta	BankTaskAdr ,y
			tax
			cpy	#$00			;TaskManager-Suystembank ?
			bne	:3			; => Nein, weiter...
			lda	#$ff			;Systembank als "Belegt" markieren.
			sta	BankTaskActive,y

::3			txa
			ldx	#%11000000		;Speicherbank reservieren.
			jsr	AllocateBank

::4			inc	r2L
			lda	r2L
			cmp	BootTaskSize		;Alle Tasks definiert ?
			bne	:2			; => Nein, weiter...

::5			lda	r2L
			sta	BootTaskSize		;TaskManager installiert ?
			bne	:7			; => Ja, weiter...

::6			lda	#%11111111		;TaskManager deaktivieren.
			b $2c
::7			lda	#%00000000		;TaskManager aktivieren.
;			sta	BootTaskMan
			sta	Copy_BootTaskMan
			tax				;TaskManager installieren ?
			bne	:9			; => Nein, weiter...

			lda	BankTaskAdr		;Lage von Systemspeicherbank
			sta	r3L			;geändert ?
			cmp	Flag_TaskBank
			beq	:8			; => Nein, weiter...

;--- TaskManager in neue Systemspeicherbank kopieren.
			LoadW	r0 , x_TaskMan
			LoadW	r1 ,RT_ADDR_TASKMAN
			LoadW	r2 ,(x_TaskManEnd - x_TaskMan)
			jsr	StashRAM

;--- TaskManager-Variablen festlegen.
::8			lda	BootTaskSize
			sta	MaxTaskInstalled

			LoadW	r0 ,BankTaskAdr
			LoadW	r1 ,RT_ADDR_TASKMAN +3
			LoadW	r2 ,2*9 +1
			jsr	StashRAM

			lda	BankTaskAdr
			sta	Flag_TaskBank

			jsr	InitTaskManKey
::9			jmp	SetRAM_Spooler

;*** TaskManager-RAM freigeben.
:ClrRAM_Spooler		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:1			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:1			; => Nein, weiter...

			lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			tay
			lda	Flag_SpoolMinB
			jsr	FreeBankTab		;Speicher freigeben.
::1			rts

;*** SpoolerRAM reservieren.
:SetRAM_Spooler		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:3			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:3			; => Nein, weiter...

			lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			sta	BootSpoolSize		;Speicher für Spooler suchen.

::1			ldy	BootSpoolSize		;Speicher für Spooler suchen.
			jsr	GetFreeBankLTab
			cpx	#NO_ERROR		;Speicher frei ?
			beq	:2			; => Ja, weiter...
			dec	BootSpoolSize		;SpoolerRAM -64K
			bne	:1			; => weitersuchen.

			lda	#$00			;Kein Speicher für Spooler frei.
			sta	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
			sta	Flag_Spooler
			sta	BootSpooler
			rts

::2			ldx	#$00
			stx	Flag_SpoolADDR +0
			stx	Flag_SpoolADDR +1
			sta	Flag_SpoolMinB
			sta	Flag_SpoolADDR +2
			ldx	#%11000000
			jsr	AllocateBankTab		;SpoolerRAM belegen.

			ldy	BootSpoolSize
			dey
			tya
			clc
			adc	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
::3			rts

;******************************************************************************
;*** Daten für Taskmanager.
;******************************************************************************
			t "-G3_TaskManData"
;******************************************************************************

:StartTaskManMse	b $00				;$FF = TaskMan über Maustasten starten.

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1_1			;Register: "TaskManager".
			w RegTMenu_1

			w RegTName1_2			;Register: "Einstellungen".
			w RegTMenu_2

:RegTName1_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x,Icon_20y

:RegTName1_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x,Icon_21y

;*** Daten für Register "TASKMANAGER".
:RegTMenu_1		b 2

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu_1a		b BOX_OPTION			;----------------------------------------
				w RegTText_1_02
				w Swap_TaskAktiv
				b $50
				w $0048
				w BootTaskMan
				b %11111111

if Sprache = Deutsch
:RegTText_1_01		b	 "TASKMANAGER",0
:RegTText_1_02		b	$58,$00,$56, "TaskManager nicht installieren",0
endif
if Sprache = Englisch
:RegTText_1_01		b	 "TASKMANAGER",0
:RegTText_1_02		b	$58,$00,$56, "Do not install the TaskManager",0
endif

;*** Daten für Register "EINSTELLUNGEN".
:RegTMenu_2		b 7

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$5f
				w $0040,$012f
::u01			b BOX_NUMERIC_VIEW		;----------------------------------------
				w RegTText_2_02
				w $0000
				b $48
				w $0108
				w BootTaskSize
				b 2!NUMERIC_RIGHT!NUMERIC_BYTE
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $47,$50
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w Swap_TaskSize
				b $48
				w $0118
				w RegTIcon1_1_01
				b (:u01 - RegTMenu_2 -1)/11 +1

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_03
				w $0000
				b $70,$af
				w $0040,$012f
:RegTMenu_2a		b BOX_OPTION			;----------------------------------------
				w RegTText_2_04
				w SwapTaskMode1
				b $78
				w $0048
				w StartTaskManMse
				b %11111111
:RegTMenu_2b		b BOX_OPTION			;----------------------------------------
				w RegTText_2_05
				w SwapTaskMode2
				b $90
				w $0048
				w BootTaskStart
				b %11111111

:RegTIcon1_1_01		w Icon_10
			b $00,$00,$01,$08
			b $ff

if Sprache = Deutsch
:RegTText_2_01		b	 "ANWENDUNGEN",0
:RegTText_2_02		b	$48,$00,$4e, "Max. gleichzeitig verfügbare"
			b GOTOXY,$48,$00,$56, "Anwendungen im TaskManager:",0
:RegTText_2_03		b	 "AKTIVIEREN",0
:RegTText_2_04		b	$58,$00,$7e, "TaskManager über Tastatur mit"
			b GOTOXY,$58,$00,$86, "<CBM> + <CTRL> starten",0
:RegTText_2_05		b	$58,$00,$96, "TaskManager über linke und"
			b GOTOXY,$58,$00,$9e, "rechte Maustaste starten",0
endif
if Sprache = Englisch
:RegTText_2_01		b	 "APPLICATIONS",0
:RegTText_2_02		b	$48,$00,$4e, "Select a maximum of"
			b GOTOXY,$48,$00,$56, "available applications:",0
:RegTText_2_03		b	 "ACTIVATE",0
:RegTText_2_04		b	$58,$00,$7e, "Activate TaskManager by using"
			b GOTOXY,$58,$00,$86, "<CBM> + <CTRL>-keys",0
:RegTText_2_05		b	$58,$00,$96, "Activate TaskManager by using"
			b GOTOXY,$58,$00,$9e, "left and right mouse-button",0
endif

;*** Icons.
:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y

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
