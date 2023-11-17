; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** DescAccessory: Neu laden.
;Nach dem starten eines DA den Inhalt
;von keinem, dem obersten oder von
;allen Fenstern neu laden.
:switchReloadDA		bit	r1L			;Regiser-Menü aufbauen?
			bpl	updateReloadDA		; => Ja, weite...

			lda	GD_DA_RELOAD_DIR	;Aktuellen Modus einlesen und
			bne	:1			;auf nächsten Modus wechseln.
			lda	#$7f			; => Nur oberstes Fenster.
			bne	:3
::1			bmi	:2
			lda	#$ff			; => Alle Fenster aktualisieren.
			bne	:3
::2			lda	#$00			; => Nichts aktualisieren.
::3			sta	GD_DA_RELOAD_DIR

;*** DescAccessory: Status anzeigen.
;RegisterMenü / Tri-State-Option.
:updateReloadDA		lda	GD_DA_RELOAD_DIR	;Aktuellen Modus einlesen.
			beq	:off
			bmi	:all

::top			lda	#$02			; => Nur oberstes Fenster.
			b $2c
::all			lda	#$01			; => Alle Fenster aktualisieren.
			b $2c
::off			lda	#$00			; => Nichts aktualisieren.
			jsr	SetPattern		;Füllmuster setzen.

			jsr	i_Rectangle		;Tri-State-Option anzeigen.
			b RPos1_y +RLine1_6 +1
			b RPos1_y +RLine1_6 +6
			w RPos1_x +1
			w RPos1_x +6

			rts

;*** Laufwerk #1/#2 für DualWin-Modus ändern.
:setDualWin1		ldx	#$00			;Fenster #1.
			b $2c
:setDualWin2		ldx	#$01			;Fenster #1.

			lda	GD_DUALWIN_MODE		;DualWin-Modus aktiv?
			beq	:4			; => Nein, Ende...

			lda	GD_DUALWIN_DRV1,x	;Laufwerk Fenster #1/#2 einlesen.

;--- Zeiger auf nächstes Laufwerk.
::1			clc				;Zeiger auf nächstes Laufwerk.
			adc	#$01

			cmp	#4			;Laufwerk #4 erreicht?
			bcc	:2			; => Nein, weiter...
			lda	#$00			;Auf erstes Laufwerk zurücksetzen.

::2			cmp	GD_DUALWIN_DRV1,x	;Alle Laufwerke getestet?
			beq	:4			; => Ja, Ende.

			tay
			lda	driveType,y		;Laufwerk verfügbar?
			beq 	:1			; => Nein, weiter...

			tya
			sta	GD_DUALWIN_DRV1,x	;Neues Laufwerk speichern.

			pha

			txa				;Fensterdaten einlesen:
			asl				;r14: Zeiger auf Laufwerkstext.
			asl				;r15: Zeiger auf Reg.-Option.
			tay
			ldx	#$00
::3			lda	:dualWinRegTab,y
			sta	r14L,x
			iny
			inx
			cpx	#4
			bcc	:3

			pla

			clc				;Neuen Laufwerksbuchstaben
			adc	#"A"			;speichern.
			ldy	#$00
			sta	(r14L),y

			jsr	RegisterUpdate		;Register-Option aktualisieren.

::4			rts

::dualWinRegTab		w drvWin1Text, updDrv1Text
			w drvWin2Text, updDrv2Text

;*** Sortiermodus setzen.
:setSortMode		lda	GD_STD_SORTMODE		;Auf nächsten Sortiermodus
			clc				;wechseln...
			adc	#$01
			cmp	#$07
			bcc	:1
			lda	#$00
::1			sta	GD_STD_SORTMODE

			jsr	defSortModTx		;Text für Sortiermodus einlesen.

			LoadW	r15,updSortMode
			jmp	RegisterUpdate		;Register-Menü aktualisieren.

;*** Sortiermodus in Text wandeln.
:defSortModTx		lda	GD_STD_SORTMODE
			asl
			tax
			lda	sortModTxTab+0,x
			sta	r0L
			lda	sortModTxTab+1,x
			sta	r0H

			LoadW	r1,sortModeText
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Sortiermodus.
:sortModTxTab		w sortMode0
			w sortMode1
			w sortMode2
			w sortMode3
			w sortMode4
			w sortMode5
			w sortMode6

;*** Texte für Sortiermodus.
;Hinweis:
;Max. 20 Zeichen da Puffer begrenzt.
;Aktuell Max. 14 wegen Register-Menu.
if LANG = LANG_DE
:sortMode0		b "Unsortiert",NULL
:sortMode1		b "Dateiname",NULL
:sortMode2		b "Dateigröße",NULL
:sortMode3		b "Datum Alt->Neu",NULL
:sortMode4		b "Datum Neu->Alt",NULL
:sortMode5		b "Dateityp",NULL
:sortMode6		b "GEOS-Dateityp",NULL
endif
if LANG = LANG_EN
:sortMode0		b "Unsorted",NULL
:sortMode1		b "File name",NULL
:sortMode2		b "File size",NULL
:sortMode3		b "Date old->new",NULL
:sortMode4		b "Date new->old",NULL
:sortMode5		b "File type",NULL
:sortMode6		b "GEOS-File type",NULL
endif

;*** Anzeigemodus definieren.
:defViewMode		lda	#$ff
			sta	GD_STD_VIEWMODE

			LoadW	r15,updViewMode
			jmp	RegisterUpdate

;*** Icon-Cache ein-/ausschalten.
:setupIconCache		bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:disable_cache

			jsr	FindFreeBank		;64K für Icon-Daten.
			cpx	#NO_ERROR		;Speicher gefunden?
			beq	:icon_cache		; => Ja, weiter...

			LoadW	r0,Dlg_RamCacheErr
			jsr	DoDlgBox		;Fehler: Kein Speicher frei.

			lda	#$00			;Kein Icon-Cache aktiv.
			sta	GD_ICON_CACHE

			LoadW	r15,RTabMenu1_1a	;Register-Option aktialisieren.
			jsr	RegisterUpdate

;--- Icon-Cache ausschalten.
::disable_cache		ldy	GD_ICONDATA_BUF		;Speicher für Icon-Cache belegt?
			beq	:1			; => Nein, weiter...
			jsr	FreeBank 		;Speicher freigeben.

			lda	#$00			;Kein Icon-Cache aktiv.
			sta	GD_ICONDATA_BUF

::1			jmp	setReloadDir		;Dateien von Disk neu einlesen.

;--- icon-Cache einschalten.
::icon_cache		sty	GD_ICONDATA_BUF
			jsr	AllocateBank		;Speicher reservieren.

;--- Alle Dateien neu einlesen.
;Damit wird ggf. der Status "Icon im Cache" gelöscht.
::continue		jmp	setReloadDir		;Dateien von Disk neu einlesen.

;*** Nicht genügend freier Speicher.
:Dlg_RamCacheErr	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$30
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Nicht genügend Speicher frei!",NULL
::3			b "Für den Icon-Cache werden 64Kb",NULL
::4			b "freier DACC-Speicher benötigt.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Not enough free GEOS memory!",NULL
::3			b "64Kb free DACC memory is",NULL
::4			b "required for the icon cache.",NULL
endif

;*** Systeminformationen aufbereiten.
;Angaben für Registerkarte "INFO".
;Weitere Angaben werden aus ":-SYS_VAR"
;direkt über Registerkarte angezeigt.
:doInitSysInfo		lda	BootDrive		;Startlaufwerk nach ASCII wandeln.
			clc
			adc	#"A" -8
			sta	infoBootDrive

			lda	BootType		;RealDrvType.
			jsr	HEX2ASCII
			stx	infoBootType +0
			sta	infoBootType +1

			lda	BootMode		;RealDrvMode.
			jsr	HEX2ASCII
			stx	infoBootMode +0
			sta	infoBootMode +1
			rts

;*** Variablen.
:infoBootDrive		b "x:",NULL
:infoBootType		b "XX",NULL
:infoBootMode		b "XX",NULL

;*** Debug-Informationen ausgeben.
if DEBUG_SYSINFO = TRUE
:doInitRAMInfo		lda	GD_SCRN_STACK		;64K: Bildschirmspeicher.
			jsr	HEX2ASCII
			stx	bankSys +0
			sta	bankSys +1

			lda	GD_SYSDATA_BUF		;64K: Systemspeicher.
			jsr	HEX2ASCII
			stx	bankData +0
			sta	bankData +1

			lda	GD_ICONDATA_BUF		;64K: Icon-Cache.
			jsr	HEX2ASCII
			stx	bankCache +0
			sta	bankCache +1

			ldx	bankPointer
			lda	GD_RAM_GDESK1,x		;64K: GeoDesk #1/#2.
			jsr	HEX2ASCII
			stx	bankGDesk1 +0
			sta	bankGDesk1 +1

			rts

;*** GeoDesk-Speicherbank wechseln.
:SwapBankGD		lda	bankPointer		;Zwischen Bank#1 und #2 umschalten.
			eor	#$01
			sta	bankPointer
			tax
			lda	GD_RAM_GDESK1,x		;64K: GeoDesk #1/#2.
			jsr	HEX2ASCII
			stx	bankGDesk1 +0
			sta	bankGDesk1 +1

			LoadW	r15,RTabMenu1_9a	;RegisterMenü aktualisieren.
			jsr	RegisterUpdate

			jmp	prntVlirInfo		;Modul-Daten anzeigen.
endif

;*** Debug-Info: GeoDesk-Speicher.
;Gibt Lage der VLIR-Module im GeoDesk-
;Speicher aus. Max. $0000-$FFFF.
;Wird der Wert überschritten, dann ist
;eine Anpassung der Speicherroutine
;und eine weitere 64K-Speicherbank
;erforderlich...
;
if DEBUG_SYSINFO = TRUE
:prntVlirInfo		lda	#$00			;Info-Bereich löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b RPos9_y +RLine9_2 -$01
			b R1SizeY1 -$06 -$01
			w R1SizeX0 +$08 +$24
			w R1SizeX1 -$08 -$01

			lda	#$00
			sta	r15H			;VLIR-Zähler löschen.

			LoadW	r14,$0020		;Erste Spalte.

::next_column		lda	#(RPos9_y +RLine9_2 +$06)
			sta	r15L			;Zeile auf Anfang.

			ClrB	:lineCount		;Zeilenzähler auf Anfang.

::loop			ldx	r15H			;Modul innerhalb der
			lda	GD_DACC_ADDR_B,x	;aktiven Speicherbank?
			ldx	bankPointer
			cmp	GD_RAM_GDESK1,x
			bne	:next			; => Nein, weiter...

			lda	r14L			;X-Koordinate Spalte berechnen.
			clc
			adc	#<RPos9_x
			sta	r11L
			pha
			lda	r14H
			adc	#>RPos9_x
			sta	r11H
			pha

			lda	r15L			;Y-Koordinate Zeile setzen.
			sta	r1H

			lda	r15H			;VLIR-Modul ausgeben.
			clc
			adc	#$01
			jsr	HEX2ASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			lda	#":"
			jsr	SmallPutChar

			ldy	#$00			;Startadresse ausgeben.
			jsr	:printWord

			pla				;X-Position für Speicherende
			tax				;berechnen.
			pla
			clc
			adc	#$30
			sta	r11L
			txa
			adc	#$00
			sta	r11H

			lda	#"-"
			jsr	SmallPutChar

			ldy	#$02			;Endadresse ausgeben.
			jsr	:printWord

			lda	r15L			;Zeiger auf nächste Zeile.
			clc
			adc	#$08
			sta	r15L

			inc	:lineCount		;Anzahl Zeilen +1.

::next			inc	r15H			;Zeiger auf nächstes VLIR-Modul.
			lda	r15H
			cmp	#GD_VLIR_COUNT		;Alle Module ausgegeben?
			bcs	:exit			; => Ja, Ende.

			lda	:lineCount		;Zeilenzähler einlesen.
			cmp	#$08			;Spalte voll?
			bcc	:loop			; => Nein, weiter...

			AddVBW	$58,r14			;Zeiger auf nächste Spalte.
			jmp	:next_column		;Zeile zurücksetzen.

::exit			rts				;Ende.

::lineCount		b $00

;--- Start-/End-Adresse ausgeben.
::printWord		lda	r15H			;Zeiger auf Adress-Tabelle
			asl				;berechnen.
			asl
			tax
			cpy	#$00			;Start- oder Endadresse?
			bne	:1			; => Ende-Adresse...

			lda	GD_DACC_ADDR +0,x	;Startadresse einlesen.
			sta	r0L
			lda	GD_DACC_ADDR +1,x
			sta	r0H
			jmp	:2

::1			lda	GD_DACC_ADDR +0,x	;Startadresse + Größe =
			clc				;Endadresse berechnen.
			adc	GD_DACC_ADDR +2,x
			sta	r0L
			lda	GD_DACC_ADDR +1,x
			adc	GD_DACC_ADDR +3,x
			sta	r0H

			SubVW	1,r0			;Endadresse -1.

::2			PushB	r1H			;Register ":r1H" zwischenspeichern.

			LoadW	r1,:adr +1		;WORD nach ASCII wandeln.
			jsr	HEXW2ASCII

			PopB	r1H			;Register ":r1H" zurücksetzen.

			LoadW	r0,:adr
			jmp	PutString		;WORD/ASCII-Zahl ausgeben.

::adr			b "$0000",NULL			;Zwischenspeicher.
endif

;*** Variablen.
if DEBUG_SYSINFO = TRUE
:bankSys		b "00",NULL
:bankData		b "00",NULL
:bankCache		b "00",NULL
:bankGDesk1		b "00",NULL
:bankPointer		b $00
endif
