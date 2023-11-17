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
			t "SymbTab_MMAP"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.PSPL.ext"
endif

;*** GEOS-Header.
			n "obj.GDC.Spooler"
			c "GDC.SPOOLER V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Spooler konfigurieren"
endif
if LANG = LANG_EN
			h "Configure printerspooler"
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
:DoAppStart		jsr	e_InitSpoolData		;Externe Routinen initialisieren.

			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:1			; => Ja, keine Parameterübernahme.

			jsr	e_ClrSpoolSize		;SpoolerRAM freigeben.
			jsr	GetSpoolSizeKB		;Reservierten Speicher umwandeln.

::1			lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Konfiguration speichern.
:SaveConfig		bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:no_update		; => Ja, keine Parameterübernahme.

			lda	BootSpooler		;Spooler-Status einlesen und
			and	#%10000000		;in BootKonfiguration speichern.
			sta	Flag_Spooler

			ldx	BootSpoolDelay		;Verzögerungszeit festlegen.
			stx	Flag_SpoolCount

			ldy	#$00			;Vorgabe: Spoolergröße zurücksetzen.

			tax				;Spooler aktiv ?
			beq	:1			; => Nein, Ende...

			lda	Flag_SpoolMinB
			ora	Flag_SpoolMaxB		;SpoolerRAM reserviert ?
			beq	:1			; => Nein, weiter...

			jsr	e_GetSizeSpooler	;Größe SpoolerRAM berechnen.
			tay

::1			sty	BootSpoolSize		;Größe SpoolerRAM speichern.

::no_update		ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** Modus für Druckerspooler wechseln.
:SwapSpooler		bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:exit			; => Ja, keine Parameterübernahme.

			jsr	e_ResetSpooler		;Spooler zurücksetzen.

			bit	BootSpooler		;Spooler aktiviert ?
			bpl	:off			; => Nein, Ende...

			lda	BootSpoolSize		;Größe SpoolerRAM definiert ?
			bne	:on			; => Ja, weiter...
			lda	#MAX_SPOOL_STD		;Standardgröße Spooler verwenden.
			sta	BootSpoolSize		;Größe SpoolerRAM festlegen.

::on			jsr	e_InitSpooler		;Spooler initialisieren.

			lda	Flag_Spooler		;Spooler-Status in Boot-
			sta	BootSpooler		;Konfiguration übernehmen.
			bne	:setsize		;SpoolerRAM-Größe bestimmen.

::off			lda	#$00			;Vorgabe: SpoolerRAM zurücksetzen.
			sta	BootSpoolSize		;Größe SpoolerRAM festlegen.
			sta	BootSpooler		;Spooler deaktivieren.

::setsize		jsr	GetSpoolSizeKB		;SpoolerRAM-Größe bestimmen.

::exit			rts

;*** Neuen Wert für Spooler-Verzögerung eingeben.
:Swap_SpoolDelay	lda	r1L			;Register-Menü im Aufbau ?
			beq	Draw_SpoolDelay		; => Ja, nur Anzeige ausgeben.

			lda	BootSpooler
			bmi	:1
			rts

::1			jsr	DefMouseXPos		;Aktivierungszeit = $00 ?
			bne	:2			; => Nein, weiter...
			lda	#$01

::2			asl				;neue Aktivierungszeit berechnen.
			asl	Flag_SpoolCount		;Bit 7 übernehmen.
			ror
			sta	Flag_SpoolCount
			sta	BootSpoolDelay

;*** Verzögerungszeit für ScreenSaver festlegen.
:Draw_SpoolDelay	lda	C_InputField		;Farbe für Schiebeegler setzen.
			jsr	DirectColor

:Updt_SpoolDelay	jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_DELAY
			b	$09,$50,Icon_DELAY_x,Icon_DELAY_y

			lda	Flag_SpoolCount		;berechnen.
			beq	Draw_SpoolTime

			ldx	#$09			;Position für Schieberegler
			and	#%00111111
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff
			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_SpoolCount		;berechnen.
			and	#%00111111
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx
::3			stx	:6 +2

			ldx	#< Icon_SETPOS2		;Typ für Regler-Icon ermitteln.
			ldy	#> Icon_SETPOS2
			lda	Flag_SpoolCount
			and	#%00111111
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#< Icon_SETPOS1		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#> Icon_SETPOS1
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_DELAY
::6			b	$0c,$53,$01,$05

;*** Aktivierungszeit anzeigen.
:Draw_SpoolTime		LoadW	r0,RegTText2_02 + 6

			lda	Flag_SpoolCount		;Aktivierungszeit in Minuten und
			and	#%00111111		;Sekunden umrechnen.
			sta	:1 +1
			asl
			asl
			clc
::1			adc	#$ff
			lsr
			ldx	#$00
::2			cmp	#60
			bcc	:3
;			sec
			sbc	#60
			inx
			bne	:2
::3			jsr	SetDelayTime

			LoadB	currentMode,$00
			LoadW	r0,RegTText2_02
			jsr	PutString		;Aktivierungszeit anzeigen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;*** Maus-Position für Schieberegler definieren.
:DefMouseXPos		lda	mouseXPos
			sec
			sbc	#< $0048
			lsr
			lsr
			rts

;*** Zahl nach ASCII wandeln.
:SetDelayTime		pha
			txa
			ldy	#$01
			jsr	:1
			pla

::1			ldx	#$30
::2			cmp	#10
			bcc	:3
			inx
			sbc	#10
			bcs	:2
::3			adc	#$30
			sta	(r0L),y
			dey
			txa
			sta	(r0L),y
			iny
			iny
			iny
			iny
			rts

;*** Neue Größe SpoolerRAM berechnen.
:Swap_SpoolRAM		jsr	e_ClrSpoolSize		;SpoolerRAM freigeben.

			ldy	BootSpoolSize

			lda	mouseYPos
			sec
			sbc	#$90
			cmp	#$04			;Mehr oder weniger ?
			bcs	:1			; => Weniger, weiter...

;--- Spooler +64k.
			iny
			cpy	#RAM_MAX_SIZE		;Max. Speicher erreicht ?
			bcc	:enable			; => Nein, weiter...
::exit			rts

;--- Spooler -64k.
::1			tya				;SpoolerRAM = 0Kb ?
			beq	:exit			; => Ja, Ende...
			dey				;SpoolerRAM -64K.
			bne	:enable

::disable		lda	#%00000000		;Spooler deaktivieren.
			b $2c
::enable		lda	#%10000000		;Spooler aktivieren.
			sta	BootSpooler		;Spooler-Modus speichern.

::2			sty	BootSpoolSize

			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	GetSpoolSizeKB		; => Ja, keine Parameterübernahme.

			jsr	e_InitSpooler		;Spooler initialisieren.

			lda	Flag_Spooler		;Spooler-Status in Boot-
			sta	BootSpooler		;Konfiguration übernehmen.

;*** Größe des SpoolerRAMs in KByte berechnen.
:GetSpoolSizeKB		lda	#$00			;Größe SpoolerRAM zurücksetzen.
			sta	SpoolSizeKB +0
			sta	SpoolSizeKB +1

			bit	BootSpooler		;Spooler aktiviert?
			bpl	:1			; => Nein, weiter...

			lda	BootSpoolSize		;Größe SpoolerRAM berechnen.
			lsr
			ror	SpoolSizeKB +0
			lsr
			ror	SpoolSizeKB +0
			sta	SpoolSizeKB +1

::1			rts

;*** Systemvariablen.
:SpoolSizeKB		w $0000

;*** Register-Menü.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1			;Register: "Drucker".
			w RegTMenu1

			w RegTName2			;Register: "Drucker".
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

;*** Daten für Register "SPOOLER".
:RegTMenu1		b 3

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $40,$af
				w $0040,$012f
			b BOX_OPTION
				w RegTText1_02
				w SwapSpooler
				b $48
				w $0048
				w BootSpooler
				b %10000000
			b BOX_OPTION
				w RegTText1_03
				w $0000
				b $58
				w $0048
				w BootSpoolDelay
				b %10000000

;*** Texte für Register "SPOOLER".
if LANG = LANG_DE
:RegTText1_01		b	 "DRUCKERSPOOLER",0
:RegTText1_02		b	$58,$00,$4e, "Spooler zum Drucken verwenden",0
:RegTText1_03		b	$58,$00,$5e, "Spooler manuell über Menü 'DRUCKER'"
			b GOTOXY,$58,$00,$66, "im TaskManager starten",0
endif
if LANG = LANG_EN
:RegTText1_01		b	 "PRINTERSPOOLER",0
:RegTText1_02		b	$58,$00,$4e, "Use spooler to print documents",0
:RegTText1_03		b	$58,$00,$5e, "Start spooler manually from menu"
			b GOTOXY,$58,$00,$66, "'PRINTER' at the TaskManager",0
endif

;*** Daten für Register "EINSTELLUNGEN".
:RegTMenu2		b 6

			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$6f
				w $0040,$012f
			b BOX_USER
				w $0000
				w Swap_SpoolDelay
				b $50,$57
				w $004c,$00e7

			b BOX_FRAME
				w RegTText2_03
				w $0000
				b $80,$af
				w $0040,$012f
::u01			b BOX_NUMERIC_VIEW
				w RegTText2_04
				w GetSpoolSizeKB
				b $90
				w $00f8
				w SpoolSizeKB
				b 4!NUMERIC_RIGHT!NUMERIC_WORD
			b BOX_FRAME
				w $0000
				w $0000
				b $8f,$98
				w $0118,$0120
			b BOX_ICON
				w $0000
				w Swap_SpoolRAM
				b $90
				w $0118
				w RIcon_UpDown
				b (:u01 - RegTMenu2 -1)/11 +1

;*** Texte für Register "EINSTELLUNGEN".
if LANG = LANG_DE
:RegTText2_01		b	 "Aktivierungszeit:",0
:RegTText2_02		b GOTOXY,$48,$00,$5e, "( 00:00 MIN. ) "
			b GOTOXY,$48,$00,$4e, "<->"
			b GOTOX,$71,$00, "00:30"
			b GOTOX,$a0,$00, "01:00"
			b GOTOX,$d8,$00, "<+>",0
:RegTText2_03		b	 "SPEICHER",0
:RegTText2_04		b	$48,$00,$8e, "Reservierter Speicher für"
			b GOTOXY,$48,$00,$96, "DruckerSpooler in KByte:",0
endif
if LANG = LANG_EN
:RegTText2_01		b	 "Delay-time:",0
:RegTText2_02		b GOTOXY,$48,$00,$5e, "( 00:00 MIN. ) "
			b GOTOXY,$48,$00,$4e, "<->"
			b GOTOX,$71,$00, "00:30"
			b GOTOX,$a0,$00, "01:00"
			b GOTOX,$d8,$00, "<+>",0
:RegTText2_03		b	 "MEMORY",0
:RegTText2_04		b	$48,$00,$8e, "Reserved memory for"
			b GOTOXY,$48,$00,$96, "printerspooler in KByte:",0
endif

;*** System-Icons einbinden.
if .p
:EnableMSelect		= FALSE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= TRUE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Icons.
:Icon_DELAY
<MISSING_IMAGE_DATA>
:Icon_DELAY_x		= .x
:Icon_DELAY_y		= .y

:Icon_SETPOS1
<MISSING_IMAGE_DATA>
:Icon_SETPOS1_x		= .x
:Icon_SETPOS1_y		= .y

:Icon_SETPOS2
<MISSING_IMAGE_DATA>
:Icon_SETPOS2_x		= .x
:Icon_SETPOS2_y		= .y

;*** Register-Icon.
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
