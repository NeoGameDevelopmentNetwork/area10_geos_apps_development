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
			n "GD.CONF.RAM"
			c "GDC.RAM     V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Speicher konfigurieren"
endif
if Sprache = Englisch
			h "Configure memory"
endif

;*** Sprungtabelle.
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts

;******************************************************************************
;*** Speicherverwaltung.
;******************************************************************************
:BankCode_GEOS		= %10000000
:BankCode_Disk		= %01000000
:BankCode_Task		= %00100000
:BankCode_Spool		= %00010000
:BankCode_Block		= %00001000
:BankCode_Free		= %00000000

:BankType_GEOS		= %11000000
:BankType_Disk		= %10000000
:BankType_Block		= %01000000

;*** Speicher für Belegungstabelle der 64K-Speicherbänke.
:BankUsed		s RAM_MAX_SIZE
;******************************************************************************

;*** Menü initialisieren.
:InitMenu		bit	firstBoot		;GEOS-BootUp ?
			bpl	:1			; => Ja, weiter...

if GD_NG_MODE = TRUE
;Datei für "Alle Treiber in REU"
;einlesen, da evtl. Einsprung aus
;einer anderen Routine als ":DISK".
			lda	MP3_64K_DISK		;"Alle Treiber in RAM" ?
			beq	:start_init		; => Nein, weiter...
			sta	r3L

			LoadW	r0,BASE_EDITOR_DATA_NG
			LoadW	r1,$0000
			LoadW	r2,SIZE_EDITOR_DATA_NG
			jsr	FetchRAM
endif

::start_init		lda	#$00			;Speichergröße in KB berechnen.
			sta	RAM_SIZE_KB +0
			lda	ramExpSize
			lsr
			lsr
			sta	RAM_SIZE_KB +1

			jsr	DefUsedRAM		;Bank-Tabelle erstellen.
			jsr	regDefDACC		;DACC-Speichertyp definieren.

			jsr	regDefUserRAM		;Reservierten Speicher berechnen.

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

;--- AutoBoot
::1			ldx	#$00			;Speicherbänke in GEOS-RAM
::2			txa				;als "Reserviert" markieren.
			pha

			lda	BootBankBlocked,x	;Aktuelle Bank reserviert ?
			beq	:3			; => Nein, weiter...
			txa
			ldx	#BankType_Block
			jsr	AllocateBank		;Speicherbank reservieren.

::3			pla
			tax
			inx				;Zeiger auf nächste Speicherbank.
			cpx	ramExpSize		;Alle Bänke geprüft ?
			bne	:2			; => Nein, weiter...
			rts

;*** Aktuelle Konfiguration speichern.
:SaveConfig		ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** Speicherbank-Informationen sammeln.
:DefUsedRAM		jsr	DefRAM_Blocked		;Anwender-RAM einlesen.
			jsr	DefRAM_TaskMan		;TaskMan -RAM einlesen.
			jmp	DefRAM_Spooler		;Spooler -RAM einlesen.

;*** Reservierte Speicherbänke einlesen.
:DefRAM_Blocked		ldx	#$00			;Zeiger auf Bank #0.
::1			txa				;Aktuelle Bank zwischenspeichern.
			pha
			lda	#$00			;Bank-Status löschen.
			sta	BankUsed,x

::2			pla				;Aktuellen Bank-Status einlesen.
			pha
			tax
			jsr	BankUsed_GetByte
			jsr	BankUsed_Type
			tay
			pla
			tax

			lda	#BankCode_GEOS
			cpy	#BankType_GEOS		;Durch GEOS belegt ?
			beq	:3			; => Ja, weiter...

			lda	#BankCode_Disk
			cpy	#BankType_Disk		;Durch Laufwerkstreiber belegt ?
			beq	:3			; => Ja, weiter...

			lda	#BankCode_Block
			cpy	#BankType_Block		;Durch Anwender belegt ?
			beq	:3			; => Ja, weiter...

			lda	#NULL			;Bank ist nicht belegt.

::3			sta	BankUsed,x		;Bank-Status merken.
			tay
			lda	#$00
			sta	BootBankBlocked,x
			cpy	#BankCode_Block		;Durch Anwender belegt ?
			bne	:4			; => Nein, weiter...
			tya
			sta	BootBankBlocked,x	;In Boot-Konfiguration speichern.

::4			inx				;Zeiger auf nächste Speicherbank.
			cpx	ramExpSize		;Alle Bänke durchsucht ?
			bne	:1			; =: Nein, weiter...
			rts

;*** Durch TaskManager belegte Speicherbänke einlesen.
:DefRAM_TaskMan		bit	BootTaskMan		;TaskManager installiert ?
			bmi	:3			; => Nein, weiter...

			LoadW	r0 ,BankTaskAdr
			LoadW	r1 ,RT_ADDR_TASKMAN +3
			LoadW	r2 ,2*9 +1
			lda	Flag_TaskBank
			sta	r3L
			jsr	FetchRAM		;TaskManager-Variablen einlesen.

			ldy	#$00
::1			ldx	BankTaskAdr,y		;Task installiert ?
			beq	:2			; => Nein weiter...

			lda	#BankCode_Task		;Speicherbank-Status
			sta	BankUsed,x		;zwischenspeichern.

::2			iny				;Zeiger auf nächsten Task.
			cpy	#MAX_TASK_ACTIV		;Alle Tasks überprüft ?
			bcc	:1			; => Nein, weiter...
::3			rts

;*** Durch Spooler belegte Speicherbänke einlesen.
:DefRAM_Spooler		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:2			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:2			; => Nein, weiter...

			lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			tay
			ldx	Flag_SpoolMinB
			lda	#BankCode_Spool		;Speicherbank-Status
::1			sta	BankUsed,x		;zwischenspeichern.
			inx
			dey
			bne	:1
::2			rts

;*** DACC-Speichertyp definieren.
:regDefDACC		ldx	#<Text_RAM_RL		;"RAMLink DACC"
			ldy	#>Text_RAM_RL
			lda	GEOS_RAM_TYP
			asl
			bcs	:1
			ldx	#<Text_RAM_CBM		;"C=REU"
			ldy	#>Text_RAM_CBM
			asl
			bcs	:1
			ldx	#<Text_RAM_BBG		;"GeoRAM/BBGRAM"
			ldy	#>Text_RAM_BBG
			asl
			bcs	:1
			ldx	#<Text_RAM_SCPU		;"SuperCPU/RAMCard"
			ldy	#>Text_RAM_SCPU
::1			stx	RegTMenu_1a +0
			sty	RegTMenu_1a +1
			rts

;*** Speicherübersicht ausgeben.
;    Max. 64 Bänke a 64KByte = 4 MByte DACC-Speicher!
:regDrawRAM_1Mb		ldx	#$00			;Bereich 1Mb anzeigen.
			b $2c
:regDrawRAM_2Mb		ldx	#$10			;Bereich 2Mb anzeigen.
			b $2c
:regDrawRAM_3Mb		ldx	#$20			;Bereich 3Mb anzeigen.
			b $2c
:regDrawRAM_4Mb		ldx	#$30			;Bereich 4Mb anzeigen.
			stx	r0L

			lda	r1L			;Modus "Daten ändern" ?
			bne	regSwapRAMmode		; => Ja, weiter...

;*** Speicherbelegungs-Tabelle ausgeben.
:Draw_64KBankTab	lda	#$10
			sta	r0H
::1			lda	r0L
			jsr	Draw_64KBank		;Bank-Status ausgeben.
			inc	r0L
			dec	r0H
			bne	:1
			rts

;*** Speicherbank reservieren/freigeben.
:regSwapRAMmode		lda	mouseData		;Maustaste noch gedrückt ?
			bpl	regSwapRAMmode		; => Ja, warten...
			ClrB	pressFlag		;Tastenstatus löschen.

			php				;IRQ sperren.
			sei

			lda	mouseYPos		;Gewählte Speicherbank
			sec				;berechnen.
			sbc	#$60
			and	#%11110000
			sta	r2L

			lda	mouseXPos +0
			sec
			sbc	#< $00a0
			sta	r3L
			lda	mouseXPos +1
			sbc	#> $00a0
			sta	r3H

			lda	r3L
			lsr
			lsr
			lsr
			clc
			adc	r2L
			tax
			lda	BankUsed,x		;Speicherbank belegt ?
			beq	:1			; => Nein, weiter...
			cmp	#BankCode_Block		;Speicherbank reserviert ?
			bne	:9			; => GEOS/System... Abbruch...

::0			lda	#NULL			;Speicherbank freigeben.
			b $2c
::1			lda	#BankCode_Block		;Speicherbank reservieren.
::2			sta	BankUsed,x
			sta	BootBankBlocked,x
			tay				;Wurde Speicherbank reserviert ?
			beq	:3			; => Nein, weiter...

			txa
			ldx	#BankType_Block		;Speicherbank als "Reserviert"
			jsr	AllocateBank		;markieren.
			jmp	:4

::3			txa				;Speicherbank als "Frei"
			jsr	FreeBank		;markieren.

::4			jsr	Draw_64KBankTab		;Speicherübersicht aktualisieren.

::9			plp				;IRQ-Status zurücksetzen.
			rts

;*** Status für aktuelle Speicherbank anzeigen.
:Draw_64KBank		pha
			jsr	GetBankArea		;Koordinaten für Bank berechnen.
			pla
			tax
			cpx	ramExpSize		;RAM-Bank installiert ?
			bcs	regPrnInf_NoRAM		; => Nein, weiter...

			lda	BankUsed ,x		;Ist Bank frei ?
			beq	regPrnInf_Free		; => Ja, weiter...
			cmp	#BankCode_Disk		;Ist Bank durch Laufwerk belegt ?
			beq	regPrnInf_Disk		; => Ja, weiter...
			cmp	#BankCode_Task		;Ist Bank durch TaskMan belegt ?
			beq	regPrnInf_Task		; => Ja, weiter...
			cmp	#BankCode_Spool		;Ist Bank durch Spooler belegt ?
			beq	regPrnInf_Spool		; => Ja, weiter...
			cmp	#BankCode_Block		;Ist Bank reserviert ?
			beq	regPrnInf_Block		; => Ja, weiter...
			cmp	#BankCode_GEOS		;Ist Bank durch GEOS belegt ?
			bne	regPrnInf_GEOS		; => Ja, weiter...

			cpx	#$00
			beq	regPrnInf_GEOS		; => GEOS-Speicherbank.
			cpx	MP3_64K_SYSTEM
			beq	regPrnInf_GEOS		; => GD3-Kernal.
			cpx	MP3_64K_DATA
			beq	regPrnInf_GEOS		; => GD3-Daten.

;--- GeoDOS64 V3-Kernal aktiv ?
;GD.CONFIG kann auch von MP3 aus gestartet werden.
			lda	SysName +1		;GeoDOS64-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:nohelp			; => Nein, weiter...
			lda	SysName +7
			cmp	#"V"
			bne	:nohelp			; => Nein, weiter...

			bit	HelpSystemActive
			bpl	:nohelp
			cpx	HelpSystemBank
			beq	regPrnInf_Help		; => GD3-Hilfefunktion.

::nohelp		lda	MP3_64K_DISK
			beq	regPrnInf_Block

if GD_NG_MODE = FALSE
			cpx	MP3_64K_DISK
			beq	regPrnInf_DDrv
			dex
			cpx	MP3_64K_DISK
			beq	regPrnInf_DDrv
			bne	regPrnInf_Block		; => Anwendung.
endif

if GD_NG_MODE = TRUE
			txa
			ldy	#$00
::1			cmp	DRVINF_NG_RAMB,y
			beq	regPrnInf_DDrv
			iny
			cpy	#DDRV_MAX
			bcc	:1
			bcs	regPrnInf_Block		; => Anwendung.
endif

;*** Legende für Speichertabelle anzeigen.
:regPrnInf_GEOS		lda	#2			;GEOS -> Rot
			b $2c
:regPrnInf_Help		lda	#10			;Hile -> Hellrot
			b $2c
:regPrnInf_Block	lda	#5			;Reserviert -> Grün
			b $2c
:regPrnInf_DDrv		lda	#4			;Treiber -> Pink
			b $2c
:regPrnInf_Spool	lda	#3			;Spooler -> Cyan
			b $2c
:regPrnInf_Task		lda	#6			;TaskMan -> Dunkelblau
			b $2c
:regPrnInf_Disk		lda	#13			;Laufwerk -> Hellgrün
			b $2c
:regPrnInf_NoRAM	lda	#0			;N.V. -> Schwarz
			b $2c
:regPrnInf_Free		lda	#1			;Frei -> Weiß
			jsr	DirectColor
			lda	#$00
			jsr	SetPattern		;Füllmuster definieren.
			jsr	Rectangle
			lda	#%11111111
			jmp	FrameRectangle		;Bank-Status anzeigen.

;*** Koordinaten für 64K-Bank berechnen.
:GetBankArea		pha				;Y-Koordinate für Status-Feld
			and	#%11110000		;berechnen.
			clc
			adc	#$60
			sta	r2L
			clc
			adc	#$07
			sta	r2H

			pla				;X-Koordinate für Status-Feld
			and	#%00001111		;berechnen.
			asl
			asl
			asl
			clc
			adc	#< $00a0
			sta	r3L
			lda	#$00
			adc	#> $00a0
			sta	r3H

			lda	r3L
			clc
			adc	#< $0007
			sta	r4L
			lda	r3H
			adc	#> $0007
			sta	r4H
			rts

;*** Neue Größe User-RAM berechnen.
:regSwapUserRAM		lda	r1L			;Register-Menü im Aufbau ?
			beq	:exit			; => Ja, nur Anzeige ausgeben.

			ldy	BootBankAppl

			lda	mouseYPos
			sec
			sbc	#$58
			cmp	#$04			;Mehr oder weniger ?
			bcs	:1			; => Weniger, weiter...

;--- Spooler +64k.
			iny
			cpy	#RAM_MAX_SIZE -3	;Max. Speicher erreicht ?
			bcs	:exit			; => Ja, weiter...
			bcc	:2

;--- Spooler -64k.
::1			tya				;SpoolerRAM = 0Kb ?
			beq	:exit			; => Ja, Ende...
			dey				;SpoolerRAM -64K.

::2			sty	BootBankAppl

			jsr	regDefUserRAM		;Reservierten Speicher berechnen.

::exit			rts

;*** Größe des SpoolerRAMs in KByte berechnen.
:regDefUserRAM		lda	#$00
			sta	USER_RAM_KB +0
			sta	USER_RAM_KB +1

			lda	BootBankAppl
			lsr
			ror	USER_RAM_KB +0
			lsr
			ror	USER_RAM_KB +0
			sta	USER_RAM_KB +1
			rts

;******************************************************************************
;*** Daten für Taskmanager.
;******************************************************************************
			t "-G3_TaskManData"
;******************************************************************************

;*** Speichererweiterungen.
:Text_RAM_RL		b "RAMLINK",NULL
:Text_RAM_CBM		b "C=REU",NULL
:Text_RAM_BBG		b "GEORAM",NULL
:Text_RAM_SCPU		b "RAMCard",NULL

:RAM_SIZE_KB		w $0000
:USER_RAM_KB		w $0000

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

;*** Daten für Register "SPEICHER".
:RegTMenu_1		b 16

			b BOX_STRING_VIEW		;----------------------------------------
				w RegTText_1_02
				w $0000
				b $40
				w $00a0
:RegTMenu_1a			w $ffff
				b 8
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b $40
				w $00f0
				w RAM_SIZE_KB
				b 4!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $58,$b7
				w $0040,$012f
			b BOX_USER			;----------------------------------------
				w RegTText_1_03
				w regDrawRAM_1Mb
				b $60,$67
				w $00a0,$011f
			b BOX_USER			;----------------------------------------
				w RegTText_1_04
				w regDrawRAM_2Mb
				b $70,$77
				w $00a0,$011f
			b BOX_USER			;----------------------------------------
				w RegTText_1_05
				w regDrawRAM_3Mb
				b $80,$87
				w $00a0,$011f
			b BOX_USER			;----------------------------------------
				w RegTText_1_06
				w regDrawRAM_4Mb
				b $90,$97
				w $00a0,$011f

			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_12
				w regPrnInf_NoRAM
				b $a0,$a7
				w $0048,$004f
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_07
				w regPrnInf_Free
				b $a0,$a7
				w $0070,$0077
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_13
				w regPrnInf_Block
				b $a0,$a7
				w $00a0,$00a7
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_14
				w regPrnInf_Disk
				b $a0,$a7
				w $00f0,$00f7

			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_08
				w regPrnInf_GEOS
				b $a8,$af
				w $0048,$004f
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_15
				w regPrnInf_Help
				b $a8,$af
				w $0078,$007f
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_09
				w regPrnInf_DDrv
				b $a8,$af
				w $00a8,$00af
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_10
				w regPrnInf_Task
				b $a8,$af
				w $00d0,$00d7
			b BOX_USER_VIEW			;----------------------------------------
				w RegTText_1_11
				w regPrnInf_Spool
				b $a8,$af
				w $00f8,$00ff

if Sprache = Deutsch
:RegTText_1_01		b	 "SPEICHERBELEGUNG",NULL
endif
if Sprache = Englisch
:RegTText_1_01		b	 "USED MEMORY",NULL
endif

:RegTText_1_02		b	$48,$00,$46, "GEOS-DACC:"
			b GOTOX,$14,$01, "Kb",0
:RegTText_1_03		b	$48,$00,$66, "Bank"
			b GOTOX,$68,$00, "#0"
			b GOTOX,$7a,$00, "-15",0
:RegTText_1_04		b	$48,$00,$76, "Bank"
			b GOTOX,$68,$00, "#16"
			b GOTOX,$7a,$00, "-31",0
:RegTText_1_05		b	$48,$00,$86, "Bank"
			b GOTOX,$68,$00, "#32"
			b GOTOX,$7a,$00, "-47",0
:RegTText_1_06		b	$48,$00,$96, "Bank"
			b GOTOX,$68,$00, "#48"
			b GOTOX,$7a,$00, "-63",0

if Sprache = Deutsch
:RegTText_1_12		b	$52,$00,$a6, "N.V.",0
:RegTText_1_07		b	$7a,$00,$a6, "Frei",0
:RegTText_1_13		b	$aa,$00,$a6, "Anwendung",0
:RegTText_1_09		b	$fa,$00,$a6, "Laufwerk",0
:RegTText_1_08		b	$52,$00,$ae, "GEOS",0
:RegTText_1_15		b	$82,$00,$ae, "Hilfe",0
:RegTText_1_14		b	$b2,$00,$ae, "Disk",0
:RegTText_1_10		b	$da,$00,$ae, "Task",0
:RegTText_1_11		b	$02,$01,$ae, "Spooler",0
endif
if Sprache = Englisch
:RegTText_1_12		b	$52,$00,$a6, "N.V.",0
:RegTText_1_07		b	$7a,$00,$a6, "Free",0
:RegTText_1_13		b	$aa,$00,$a6, "Reserved",0
:RegTText_1_14		b	$fa,$00,$a6, "Drive",0
:RegTText_1_08		b	$52,$00,$ae, "GEOS",0
:RegTText_1_14		b	$82,$01,$ae, "Help",0
:RegTText_1_09		b	$b2,$00,$ae, "Disk",0
:RegTText_1_10		b	$da,$00,$ae, "Task",0
:RegTText_1_11		b	$02,$01,$ae, "Spooler",0
endif

;*** Daten für Register "OPTIONEN".
:RegTMenu_2		b 4

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$af
				w $0040,$012f

::u01			b BOX_NUMERIC_VIEW		;----------------------------------------
				w RegTText_2_02
				w regDefUserRAM
				b $58
				w $00f0
				w USER_RAM_KB
				b 4!NUMERIC_RIGHT!NUMERIC_WORD
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $57,$60
				w $0110,$0118
			b BOX_ICON			;----------------------------------------
				w $0000
				w regSwapUserRAM
				b $58
				w $0110
				w RegTIcon1_2_01
				b (:u01 - RegTMenu_2 -1)/11 +1

:RegTIcon1_2_01		w Icon_10
			b $00,$00,Icon_10x,Icon_10y
			b $ff

if Sprache = Deutsch
:RegTText_2_01		b	 "SPEICHER",0
:RegTText_2_02		b	$48,$00,$4e, "Reservierter Speicher für"
			b GOTOXY,$48,$00,$56, "Anwendungen während des"
			b GOTOXY,$48,$00,$5e, "Systemstarts:"
			b GOTOXY,$1c,$01,$5e, "Kb"
			b GOTOXY,$48,$00,$96, "Hinweis:"
			b GOTOXY,$48,$00,$9e, "Für GeoDesk64 werden mind. 256Kb an"
			b GOTOXY,$48,$00,$a6, "reserviertem Speicher benötigt!",0
endif
if Sprache = Englisch
:RegTText_2_01		b	 "MEMORY",0
:RegTText_2_02		b	$48,$00,$4e, "Reserved system memory for"
			b GOTOXY,$48,$00,$56, "GEOS applications during"
			b GOTOXY,$48,$00,$5e, "system boot-up:"
			b GOTOXY,$1c,$01,$5e, "Kb"
			b GOTOXY,$48,$00,$96, "Note:"
			b GOTOXY,$48,$00,$9e, "For GeoDesk64 at least 256Kb of"
			b GOTOXY,$48,$00,$a6, "reserved memory are required!",0
endif

;*** Icons.
:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

if Sprache = Deutsch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y

:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y

endif

if Sprache = Englisch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y

:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + Icon_20x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
