; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;** GEOS-Header.
			n "GD.CONF.SPOOLER"
			c "GDC.SPOOLER V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Spooler konfigurieren"
endif
if Sprache = Englisch
			h "Configure printerspooler"
endif

;*** Sprungtabelle.
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts

;******************************************************************************
;*** SpoolerRoutinen.
;******************************************************************************
:x_SpoolMenu		d "obj.SpoolMenu"
:x_SpoolMenuEnd

:x_SpoolPrint		d "obj.SpoolPrinter"
:x_SpoolPrintEnd
;******************************************************************************

;*** Menü initialisieren.
:InitMenu		bit	firstBoot		;GEOS-BootUp ?
			bpl	DoAutoBoot		; => Ja, automatisch installieren.
			bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	DoAppStart		; => Ja, keine Parameterübernahme.

;--- Erststart initialisieren.
			jsr	SaveConfig		;Aktuelle Konfiguration
							;übernehmen.

;*** Menü starten.
:DoAppStart		jsr	ClrSpoolSize		;SpoolerRAM freigeben.
			jsr	GetSpoolSizeKB		;Reservierten Speicher umwandeln.

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

;*** System-Boot / Spooler initialisieren.
:DoAutoBoot		jsr	ClrSpoolSize		;SpoolerRAM freigeben.

			lda	#$00			;Spooler-Variablen löschen.
			sta	Flag_Spooler
			sta	Flag_SpoolCount
			sta	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
			sta	Flag_SpoolADDR +0
			sta	Flag_SpoolADDR +1
			sta	Flag_SpoolADDR +2

			bit	BootSpooler		;Spooler-Status festlegen.
			bpl	:exit			; => Nicht aktiviert, Ende...

			jsr	SetSpoolSize		;Speicher für Spooler reservieren.
			txa				;Fehler ?
			bne	:exit			; => Nein, weiter...

			lda	BootSpooler		;Spooler aktivieren.
			sta	Flag_Spooler

			lda	BootSpoolCount		;Verzögerungszeit festlegen.
			sta	Flag_SpoolCount

			LoadW	r0 ,x_SpoolMenu		;Spooler installieren.
			LoadW	r1 ,R2_ADDR_SPOOLER
			LoadW	r2 ,R2_SIZE_SPOOLER
			lda	MP3_64K_SYSTEM
			sta	r3L
			jsr	StashRAM

			LoadW	r0 ,x_SpoolPrint
			LoadW	r1 ,R2_ADDR_PRNSPOOL
			LoadW	r2 ,R2_SIZE_PRNSPOOL
			lda	MP3_64K_SYSTEM
			sta	r3L
			jsr	StashRAM

::exit			lda	Flag_Spooler
			sta	BootSpooler

			rts

;*** Konfiguration speichern.
:SaveConfig		lda	Flag_Spooler		;Spooler-Status einlesen und
			and	#%10000000		;in BootKonfiguration speichern.
			sta	Flag_Spooler
			sta	BootSpooler

			ldx	Flag_SpoolCount		;Verzögerungszeit festlegen.
			stx	BootSpoolCount

			ldy	#$00			;Vorgabe: Spoolergröße zurücksetzen.
			tax				;Spooler aktiv ?
			beq	:1			; => Nein, Ende...

			lda	Flag_SpoolMinB
			ora	Flag_SpoolMaxB		;SpoolerRAM reserviert ?
			beq	:1			; => Nein, weiter...

			jsr	GetSizeSpoolRAM		;Größe SpoolerRAM berechnen.
			tay

::1			sty	BootSpoolSize

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;******************************************************************************
;*** Druckerspooler-Routinen.
;******************************************************************************
;*** Modus für Druckerspooler wechseln.
:SwapSpooler		jsr	ClrSpoolSize		;SpoolerRAM freigeben.

			bit	BootSpooler		;Spooler aktiviert ?
			bpl	:2			; => Nein, Ende...

			lda	BootSpoolSize		;Größe SpoolerRAM definiert ?
			bne	:1			; => Ja, weiter...
			lda	#MAX_SPOOL_STD		;Standardgröße Spooler verwenden.
			sta	BootSpoolSize		;Größe SpoolerRAM festlegen.

::1			jsr	DoAutoBoot		;Spooler initialisieren.
			jmp	GetSpoolSizeKB		;SpoolerRAM-Größe bestimmen.

::2			lda	#$00			;Vorgabe: SpoolerRAM zurücksetzen.
			sta	BootSpoolSize		;Größe SpoolerRAM festlegen.
			rts

;*** SpoolerRAM reservieren.
:SetSpoolSize		ldx	#NO_FREE_RAM
			lda	BootSpoolSize		;SpoolerRAM aktiviert ?
			beq	:3			; => Nein, weiter...

::1			ldy	BootSpoolSize		;Speicher für Spooler suchen.
			jsr	GetFreeBankLTab
			cpx	#NO_ERROR		;Speicher frei ?
			beq	:2			; => Ja, weiter...
			dec	BootSpoolSize		;SpoolerRAM -64K
			bne	:1			; => weitersuchen.

			ldx	#NO_FREE_RAM		;Kein Speicher für Spooler frei.
			rts

::2			sta	Flag_SpoolMinB
			sta	Flag_SpoolADDR +2
			ldx	#%11000000
			ldy	BootSpoolSize
			jsr	AllocateBankTab		;SpoolerRAM belegen.

			ldy	BootSpoolSize		;Erste und letzte Speicherbank
			dey				;für Spooler bestimmen.
			tya
			clc
			adc	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
			ldx	#NO_ERROR
::3			rts

;******************************************************************************
;*** Druckerspooler-Routinen.
;******************************************************************************
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
			sta	BootSpoolCount

;*** Verzögerungszeit für ScreenSaver festlegen.
:Draw_SpoolDelay	lda	C_InputField		;Farbe für Schiebeegler setzen.
			jsr	DirectColor

:Updt_SpoolDelay	jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_06
			b	$09,$50,Icon_06x,Icon_06y

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

			ldx	#<Icon_08		;Typ für Regler-Icon ermitteln.
			ldy	#>Icon_08
			lda	Flag_SpoolCount
			and	#%00111111
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#<Icon_07		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#>Icon_07
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_06
::6			b	$0c,$53,$01,$05

;*** Aktivierungszeit anzeigen.
:Draw_SpoolTime		LoadW	r0,RegTText_2_02 + 6

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
			LoadW	r0,RegTText_2_02
			jsr	PutString		;Aktivierungszeit anzeigen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;******************************************************************************
;*** Druckerspooler-Routinen.
;******************************************************************************
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

;******************************************************************************
;*** Druckerspooler-Routinen.
;******************************************************************************
;*** Neue Größe SpoolerRAM berechnen.
:Swap_SpoolRAM		jsr	ClrSpoolSize		;SpoolerRAM freigeben.

			ldy	BootSpoolSize

			lda	mouseYPos
			sec
			sbc	#$90
			cmp	#$04			;Mehr oder weniger ?
			bcs	:1			; => Weniger, weiter...

;--- Spooler +64k.
			iny
			cpy	#MAX_SPOOL_SIZE		;Max. Speicher erreicht ?
			bcs	:exit			; => Ja, weiter...
			bcc	:enable

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
			jsr	GetSpoolSizeKB

			jmp	DoAutoBoot

::exit			rts

;*** Anzahl 64K-Bänke in SpoolerRAM berechnen.
:GetSizeSpoolRAM	lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			rts

;*** Größe des SpoolerRAMs in KByte berechnen.
:GetSpoolSizeKB		lda	#$00
			sta	SpoolSizeKB +0
			sta	SpoolSizeKB +1
			bit	BootSpooler
			bpl	:1
			lda	BootSpoolSize
			lsr
			ror	SpoolSizeKB +0
			lsr
			ror	SpoolSizeKB +0
			sta	SpoolSizeKB +1
::1			rts

;*** SpoolerRAM freigeben.
:ClrSpoolSize		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:1			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:1			; => Nein, weiter...

			jsr	GetSizeSpoolRAM
			tay
			lda	Flag_SpoolMinB
			jsr	FreeBankTab		;Speicher freigeben.
::1			rts

;*** Systemvariablen.
:SpoolSizeKB		w $0000

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1_1			;Register: "Drucker".
			w RegTMenu_1

			w RegTName1_2			;Register: "Drucker".
			w RegTMenu_2

:RegTName1_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x,Icon_20y

:RegTName1_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x,Icon_21y

;*** Daten für Register "SPOOLER".
:RegTMenu_1		b 3

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $40,$af
				w $0040,$012f
			b BOX_OPTION			;----------------------------------------
				w RegTText_1_02
				w SwapSpooler
				b $48
				w $0048
				w BootSpooler
				b %10000000
			b BOX_OPTION			;----------------------------------------
				w RegTText_1_03
				w $0000
				b $58
				w $0048
				w BootSpoolCount
				b %10000000

if Sprache = Deutsch
:RegTText_1_01		b	 "DRUCKERSPOOLER",0
:RegTText_1_02		b	$58,$00,$4e, "Spooler zum Drucken verwenden",0
:RegTText_1_03		b	$58,$00,$5e, "Spooler manuell über Menü 'DRUCKER'"
			b GOTOXY,$58,$00,$66, "im TaskManager starten",0
endif
if Sprache = Englisch
:RegTText_1_01		b	 "PRINTERSPOOLER",0
:RegTText_1_02		b	$58,$00,$4e, "Use spooler to print documents",0
:RegTText_1_03		b	$58,$00,$5e, "Start spooler manually from menu"
			b GOTOXY,$58,$00,$66, "'PRINTER' at the TaskManager",0
endif

;*** Daten für Register "EINSTELLUNGEN".
:RegTMenu_2		b 6

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$6f
				w $0040,$012f
			b BOX_USER			;----------------------------------------
				w $0000
				w Swap_SpoolDelay
				b $50,$57
				w $004c,$00e7

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_03
				w $0000
				b $80,$af
				w $0040,$012f
::u01			b BOX_NUMERIC_VIEW		;----------------------------------------
				w RegTText_2_04
				w GetSpoolSizeKB
				b $90
				w $00f8
				w SpoolSizeKB
				b 4!NUMERIC_RIGHT!NUMERIC_WORD
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $8f,$98
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w Swap_SpoolRAM
				b $90
				w $0118
				w RegTIcon1_1_01
				b (:u01 - RegTMenu_2 -1)/11 +1

:RegTIcon1_1_01		w Icon_10
			b $00,$00,Icon_10x,Icon_10y
			b $ff

if Sprache = Deutsch
:RegTText_2_01		b	 "Aktivierungszeit:",0
:RegTText_2_02		b GOTOXY,$48,$00,$5e, "( 00:00 MIN. ) "
			b GOTOXY,$48,$00,$4e, "<->"
			b GOTOX,$71,$00, "00:30"
			b GOTOX,$a0,$00, "01:00"
			b GOTOX,$d8,$00, "<+>",0
:RegTText_2_03		b	 "SPEICHER",0
:RegTText_2_04		b	$48,$00,$8e, "Reservierter Speicher für"
			b GOTOXY,$48,$00,$96, "DruckerSpooler in KByte:",0
endif
if Sprache = Englisch
:RegTText_2_01		b	 "Delay-time:",0
:RegTText_2_02		b GOTOXY,$48,$00,$5e, "( 00:00 MIN. ) "
			b GOTOXY,$48,$00,$4e, "<->"
			b GOTOX,$71,$00, "00:30"
			b GOTOX,$a0,$00, "01:00"
			b GOTOX,$d8,$00, "<+>",0
:RegTText_2_03		b	 "MEMORY",0
:RegTText_2_04		b	$48,$00,$8e, "Reserved memory for"
			b GOTOXY,$48,$00,$96, "printerspooler in KByte:",0
endif

;*** Icons.
:Icon_06
<MISSING_IMAGE_DATA>
:Icon_06x		= .x
:Icon_06y		= .y

:Icon_07
<MISSING_IMAGE_DATA>
:Icon_07x		= .x
:Icon_07y		= .y

:Icon_08
<MISSING_IMAGE_DATA>
:Icon_08x		= .x
:Icon_08y		= .y

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
