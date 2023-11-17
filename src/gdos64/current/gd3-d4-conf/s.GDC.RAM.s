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
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.DACC.ext"
endif

;*** GEOS-Header.
			n "GD.CONF.RAM"
			c "GDC.RAM     V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Speicher konfigurieren"
endif
if LANG = LANG_EN
			h "Configure memory"
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

;*** Speicher für Belegungstabelle der 64K-Speicherbänke.
:BankUsed		s RAM_MAX_SIZE

;*** Menü initialisieren.
:InitMenu		lda	MP3_64K_DISK		;"Alle Treiber in RAM" aktiv?
			beq	:start_init		; => Nein, weiter...
			sta	r3L

			LoadW	r0,BASE_DDRV_INFO	;Daten u den Laufwerkstreibern im
			LoadW	r1,$0000		;RAM einlesen.
			LoadW	r2,SIZE_DDRV_INFO
			jsr	FetchRAM

::start_init		lda	#$00			;Speichergröße in KB berechnen.
			sta	RAM_SIZE_KB +0
			lda	ramExpSize
			lsr
			lsr
			sta	RAM_SIZE_KB +1

			lda	#NULL			;Hinweis auf Installationsmodus
			bit	Copy_firstBoot		;in Speicherübersicht ergänzen.
			bmi	:1			;(Nur bei GEOS-BootUp)
			lda	#PLAINTEXT
::1			sta	RegTText1_01a

			jsr	DefUsedRAM		;Bank-Tabelle erstellen.
			jsr	regDefDACC		;DACC-Speichertyp definieren.

			jsr	regDefUserRAM		;Reservierten Speicher berechnen.

			lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Aktuelle Konfiguration speichern.
:SaveConfig		ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;*** Speicherbank-Informationen sammeln.
:DefUsedRAM		jsr	DefRAM_Blocked		;Anwender-RAM einlesen.
			jsr	DefRAM_TaskMan		;TaskMan -RAM einlesen.
			jmp	DefRAM_Spooler		;Spooler -RAM einlesen.

;*** Reservierte Speicherbänke einlesen.
:DefRAM_Blocked		ldy	#$00			;Zeiger auf Bank #0.
::1			lda	#BankCode_Free		;Bank-Status löschen.
			sta	BankUsed,y

::2			jsr	GetBankByte
			tax

			lda	#BankCode_GEOS
			cpx	#BankType_GEOS		;Durch GEOS belegt ?
			beq	:3			; => Ja, weiter...

			lda	#BankCode_Disk
			cpx	#BankType_Disk		;Durch Laufwerkstreiber belegt ?
			beq	:3			; => Ja, weiter...

			lda	#BankCode_Block
			cpx	#BankType_Block		;Durch Anwender belegt ?
			beq	:3			; => Ja, weiter...

			lda	#NULL			;Bank ist nicht belegt.

::3			sta	BankUsed,y		;Bank-Status merken.
			tax
			lda	#$00
			sta	BootBankBlocked,y
			cpx	#BankCode_Block		;Durch Anwender belegt ?
			bne	:4			; => Nein, weiter...
			tya
			sta	BootBankBlocked,y	;In Boot-Konfiguration speichern.

::4			iny				;Zeiger auf nächste Speicherbank.

			cpy	ramExpSize		;Alle Bänke durchsucht ?
			beq	:exit			; => Ja, Ende...
			cpy	#RAM_MAX_SIZE		;Max. Speicher durchsucht ?
			bne	:1			; => Nein, weiter...

::exit			rts

;*** Durch TaskManager belegte Speicherbänke einlesen.
:DefRAM_TaskMan		bit	Copy_BootTaskMan	;TaskManager installiert ?
			bmi	:3			; => Nein, weiter...

			LoadW	r0,BankTaskAdr
			LoadW	r1,RTA_TASKMAN +3
			LoadW	r2,2*9 +1
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
:regDefDACC		ldx	#< Text_RAM_RL		;"RAMLink DACC"
			ldy	#> Text_RAM_RL
			lda	GEOS_RAM_TYP
			asl
			bcs	:1
			ldx	#< Text_RAM_CBM		;"C=REU"
			ldy	#> Text_RAM_CBM
			asl
			bcs	:1
			ldx	#< Text_RAM_BBG		;"GeoRAM/BBGRAM"
			ldy	#> Text_RAM_BBG
			asl
			bcs	:1
			ldx	#< Text_RAM_SCPU	;"SuperCPU/RAMCard"
			ldy	#> Text_RAM_SCPU
::1			stx	RegTMenu1a +0
			sty	RegTMenu1a +1
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
			bcs	regPrnInf_NoRAM		; => Nein, Bank nicht verfügbar.
			cpx	#RAM_MAX_SIZE		;Max. Speicher überschritten ?
			bcs	regPrnInf_NoRAM		; => Ja, Bank nicht verfügbar.

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
			beq	regPrnInf_GEOS		; => GDOS-Kernal.
			cpx	MP3_64K_DATA
			beq	regPrnInf_GEOS		; => GDOS-System.

			bit	Copy_firstBoot		;GEOS-BootUp ?
			bmi	:chkhelp		; => Nein, weiter...

			bit	BootHelpSysMode		;Hilfesystem aktivierten ?
			bpl	:nohelp			; => Nein, weiter...
			inx
			cpx	MP3_64K_DATA		;64Kb-Speicher für Hilfesystem ?
			beq	regPrnInf_Help		; => Ja, GDOS-Hilfesystem.
			dex				;Bankzeiger korrigieren.
			bne	:nohelp			; => Nein, weitertesten...

::chkhelp		bit	HelpSystemActive	;Hilfesystem aktiviert ?
			bpl	:nohelp			; => Nein, weiter...
			cpx	HelpSystemBank		;Speicher Hilfesystem reserviert ?
			beq	regPrnInf_Help		; => GDOS-Hilfesystem.

::nohelp		lda	MP3_64K_DISK		;"Treiber-in-RAM" aktiv ?
			beq	regPrnInf_Block		; => Nein, durch Anwendung belegt.

			txa
			ldy	#$00
::1			cmp	DRVINF_NG_RAMB,y	;Für Laufwerkstreiber reserviert ?
			beq	regPrnInf_DDrv		; => "Treiber-in-RAM"-Speicherbank.
			iny
			cpy	#DDRV_MAX		;Alle 64K-Bänke geprüft ?
			bcc	:1			; => Nein, weiter...
			bcs	regPrnInf_Block		; => Ja, durch Anwendung belegt.

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
:regPrnInf		jsr	DirectColor
			lda	#0
			jsr	SetPattern		;Füllmuster definieren.
			jsr	Rectangle		;Anzeigebereich löschen ( ).
			lda	#%11111111
			jmp	FrameRectangle		;Bank-Status anzeigen.

;*** Legende für Hilfe/Task/Spool während BootUp.
:testTask		lda	#6			;TaskMan -> Dunkelblau
			b $2c
:testSpool		lda	#3			;Spooler -> Cyan

			bit	Copy_firstBoot		;GEOS-BootUp?
			bmi	regPrnInf		; => Nein, weiter...

			lda	#1			;Installationsmodus:
			jsr	DirectColor		;Task/Spooler nicht installiert.
			lda	#11
			jsr	SetPattern		;Füllmuster definieren.
			jsr	Rectangle		;Anzeigebereich löschen (/).
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

;*** Größe des reservierten Speichers in KByte berechnen.
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

;*** Daten für Taskmanager.
			t "-G3_TaskManData"

;*** Speichererweiterungen.
:Text_RAM_RL		b "RAMLINK",NULL
:Text_RAM_CBM		b "C=REU",NULL
:Text_RAM_BBG		b "GEORAM",NULL
:Text_RAM_SCPU		b "RAMCard",NULL

;*** Variablen.
:RAM_SIZE_KB		w $0000
:USER_RAM_KB		w $0000

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
:RIcon_Swap		w Icon_MUpDown
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MUpDown_x,Icon_MUpDown_y
			b USE_COLOR_INPUT

;*** Daten für Register "SPEICHER".
:RegTMenu1		b 16

			b BOX_STRING_VIEW
				w RegTText1_02
				w $0000
				b $40
				w $00a0
:RegTMenu1a			w $ffff
				b 8
			b BOX_NUMERIC_VIEW
				w $0000
				w $0000
				b $40
				w $00f0
				w RAM_SIZE_KB
				b 4!NUMERIC_RIGHT!NUMERIC_WORD

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $58,$b7
				w $0040,$012f
			b BOX_USER
				w RegTText1_03
				w regDrawRAM_1Mb
				b $60,$67
				w $00a0,$011f
			b BOX_USER
				w RegTText1_04
				w regDrawRAM_2Mb
				b $70,$77
				w $00a0,$011f
			b BOX_USER
				w RegTText1_05
				w regDrawRAM_3Mb
				b $80,$87
				w $00a0,$011f
			b BOX_USER
				w RegTText1_06
				w regDrawRAM_4Mb
				b $90,$97
				w $00a0,$011f

			b BOX_USER_VIEW
				w RegTText1_12
				w regPrnInf_NoRAM
				b $a0,$a7
				w $0048,$004f
			b BOX_USER_VIEW
				w RegTText1_07
				w regPrnInf_Free
				b $a0,$a7
				w $0070,$0077
			b BOX_USER_VIEW
				w RegTText1_13
				w regPrnInf_Block
				b $a0,$a7
				w $00a0,$00a7
			b BOX_USER_VIEW
				w RegTText1_14
				w regPrnInf_Disk
				b $a0,$a7
				w $00f0,$00f7

			b BOX_USER_VIEW
				w RegTText1_08
				w regPrnInf_GEOS
				b $a8,$af
				w $0048,$004f
			b BOX_USER_VIEW
				w RegTText1_15
				w regPrnInf_Help
				b $a8,$af
				w $0078,$007f
			b BOX_USER_VIEW
				w RegTText1_09
				w regPrnInf_DDrv
				b $a8,$af
				w $00a8,$00af
			b BOX_USER_VIEW
				w RegTText1_10
				w testTask
				b $a8,$af
				w $00d0,$00d7
			b BOX_USER_VIEW
				w RegTText1_11
				w testSpool
				b $a8,$af
				w $00f8,$00ff

;*** Texte für Register "SPEICHER".
if LANG = LANG_DE
:RegTText1_01		b	 "SPEICHERBELEGUNG"
:RegTText1_01a		b PLAINTEXT
			b GOTOXY,$48,$00,$3a
			b "HINWEIS: Installationsmodus aktiv!"
			b NULL
endif
if LANG = LANG_EN
:RegTText1_01		b	 "USED MEMORY"
:RegTText1_01a		b PLAINTEXT
			b GOTOXY,$48,$00,$3a
			b "NOTE: Installation mode active!"
			b NULL
endif

:RegTText1_02		b	$48,$00,$46, "GEOS-DACC:"
			b GOTOX,$14,$01, "Kb",0
:RegTText1_03		b	$48,$00,$66, "Bank"
			b GOTOX,$68,$00, "#0"
			b GOTOX,$7a,$00, "-15",0
:RegTText1_04		b	$48,$00,$76, "Bank"
			b GOTOX,$68,$00, "#16"
			b GOTOX,$7a,$00, "-31",0
:RegTText1_05		b	$48,$00,$86, "Bank"
			b GOTOX,$68,$00, "#32"
			b GOTOX,$7a,$00, "-47",0
:RegTText1_06		b	$48,$00,$96, "Bank"
			b GOTOX,$68,$00, "#48"
			b GOTOX,$7a,$00, "-63",0

if LANG = LANG_DE
:RegTText1_12		b	$52,$00,$a6, "N.V.",0
:RegTText1_07		b	$7a,$00,$a6, "Frei",0
:RegTText1_13		b	$aa,$00,$a6, "Anwendung",0
:RegTText1_09		b	$fa,$00,$a6, "Laufwerk",0
:RegTText1_08		b	$52,$00,$ae, "GEOS",0
:RegTText1_15		b	$82,$00,$ae, "Hilfe",0
:RegTText1_14		b	$b2,$00,$ae, "Disk",0
:RegTText1_10		b	$da,$00,$ae, "Task",0
:RegTText1_11		b	$02,$01,$ae, "Spooler",0
endif
if LANG = LANG_EN
:RegTText1_12		b	$52,$00,$a6, "N.V.",0
:RegTText1_07		b	$7a,$00,$a6, "Free",0
:RegTText1_13		b	$aa,$00,$a6, "Reserved",0
:RegTText1_09		b	$fa,$00,$a6, "Drive",0
:RegTText1_08		b	$52,$00,$ae, "GEOS",0
:RegTText1_15		b	$82,$00,$ae, "Help",0
:RegTText1_14		b	$b2,$00,$ae, "Disk",0
:RegTText1_10		b	$da,$00,$ae, "Task",0
:RegTText1_11		b	$02,$01,$ae, "Spooler",0
endif

;*** Daten für Register "OPTIONEN".
:RegTMenu2		b 4

			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$af
				w $0040,$012f

::u01			b BOX_NUMERIC_VIEW
				w RegTText2_02
				w regDefUserRAM
				b $58
				w $00f0
				w USER_RAM_KB
				b 4!NUMERIC_RIGHT!NUMERIC_WORD
			b BOX_FRAME
				w $0000
				w $0000
				b $57,$60
				w $0110,$0118
			b BOX_ICON
				w $0000
				w regSwapUserRAM
				b $58
				w $0110
				w RIcon_Swap
				b (:u01 - RegTMenu2 -1)/11 +1

;*** Texte für Register "OPTIONEN".
if LANG = LANG_DE
:RegTText2_01		b	 "SPEICHER",0
:RegTText2_02		b	$48,$00,$4e, "Reservierter Speicher für"
			b GOTOXY,$48,$00,$56, "Anwendungen während des"
			b GOTOXY,$48,$00,$5e, "Systemstarts:"
			b GOTOXY,$1c,$01,$5e, "Kb"
			b GOTOXY,$48,$00,$80, "Hinweis:"
			b GOTOXY,$48,$00,$8a, "Für GeoDesk64 werden mind. 256Kb an"
			b GOTOXY,$48,$00,$92, "reserviertem Speicher benötigt."
			b GOTOXY,$48,$00,$9e, "Für Zusatzfunktionen werden weitere"
			b GOTOXY,$48,$00,$a6, "128Kb an Speicher benötigt.",0
endif
if LANG = LANG_EN
:RegTText2_01		b	 "MEMORY",0
:RegTText2_02		b	$48,$00,$4e, "Reserved system memory for"
			b GOTOXY,$48,$00,$56, "GEOS applications during"
			b GOTOXY,$48,$00,$5e, "system boot-up:"
			b GOTOXY,$1c,$01,$5e, "Kb"
			b GOTOXY,$48,$00,$80, "Note:"
			b GOTOXY,$48,$00,$8a, "GeoDesk64 requires at least"
			b GOTOXY,$48,$00,$92, "256Kb of RAM."
			b GOTOXY,$48,$00,$9e, "Additional features may require"
			b GOTOXY,$48,$00,$a6, "another 128Kb.",0
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
if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>
:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RTabIcon2
<MISSING_IMAGE_DATA>
:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

endif

if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>
:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

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
