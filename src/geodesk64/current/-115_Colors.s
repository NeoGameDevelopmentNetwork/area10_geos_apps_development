; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Hintergrundmuster/GEOS wechseln.
:SetPrevBackPat		lda	BackScrPattern		;Vorheriges Füllmuster setzen.
			bne	:1
			lda	#32
::1			sec
			sbc	#$01
			jmp	SetNewBackPat		;Neues Füllmuster anzeigen.

:SetNextBackPat		lda	BackScrPattern		;Nächstes Füllmuster setzen.
			clc
			adc	#$01
			cmp	#32
			bcc	SetNewBackPat
			lda	#$00
:SetNewBackPat		sta	BackScrPattern

;*** Aktuelles Füllmuster anzeigen.
:PrintPatGEOS		lda	BackScrPattern		;Füllmuster aktivieren.
			jsr	SetPattern

			jsr	i_Rectangle		;Füllmuster darstellen.
			b	RPos2_y +RLine2_1
			b	RPos2_y +RLine2_1 +$10 -$01
			w	RPos2_x +$20
			w	RPos2_x +$20 +RPat -$08 -$01

			lda	C_GEOS_BACK		;GEOS-Hintergrundfarbe setzen.
			jmp	DirectColor

;*** Hintergrundmuster/GeoDesk wechseln.
:SetPrevBackPatGD	lda	C_GDESK_PATTERN		;Vorheriges Füllmuster setzen.
			bne	:1
			lda	#32
::1			sec
			sbc	#$01
			jmp	SetNewBackPatGD		;Neues Füllmuster anzeigen.

:SetNextBackPatGD	lda	C_GDESK_PATTERN		;Nächstes Füllmuster setzen.
			clc
			adc	#$01
			cmp	#32
			bcc	SetNewBackPatGD
			lda	#$00
:SetNewBackPatGD	sta	C_GDESK_PATTERN

;*** Aktuelles Füllmuster anzeigen.
:PrintPatGDesk		lda	C_GDESK_PATTERN		;Füllmuster aktivieren.
			jsr	SetPattern

			jsr	i_Rectangle		;Füllmuster darstellen.
			b	RPos2_y +RLine2_1
			b	RPos2_y +RLine2_1 +$10 -$01
			w	RPos2_x +RWidth2a +$28
			w	RPos2_x +RWidth2a +$28 +RPat -$08 -$01

			lda	C_GDesk_DeskTop		;GeoDesk-Hintergrundfarbe setzen.
			jmp	DirectColor

;*** Hintergrundmuster/TaskBar wechseln.
:SetPrevBackPatTB	lda	C_GTASK_PATTERN		;Vorheriges Füllmuster setzen.
			bne	:1
			lda	#32
::1			sec
			sbc	#$01
			jmp	SetNewBackPatTB		;Neues Füllmuster anzeigen.

:SetNextBackPatTB	lda	C_GTASK_PATTERN		;Nächstes Füllmuster setzen.
			clc
			adc	#$01
			cmp	#32
			bcc	SetNewBackPatTB
			lda	#$00
:SetNewBackPatTB	sta	C_GTASK_PATTERN

;*** Aktuelles Füllmuster anzeigen.
:PrintPatTaskB		lda	C_GTASK_PATTERN		;Füllmuster aktivieren.
			jsr	SetPattern

			jsr	i_Rectangle		;Füllmuster darstellen.
			b	RPos2_y +RLine2_1
			b	RPos2_y +RLine2_1 +$10 -$01
			w	RPos2_x +RWidth2b +$00
			w	RPos2_x +RWidth2b +$00 +RPat -$08 -$01

			lda	C_GDesk_TaskBar		;TaskBar-Hintergrundfarbe setzen.
			jmp	DirectColor

;*** Systemfarben wechseln.
:PrintCurColName	lda	#$00			;Füllmuster für Farbbereich.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos1_y +RLine1_1
			b	RPos1_y +RLine1_1 +$10 -$01
			w	RPos1_x +RWidth1
			w	R1SizeX1 -$18

			lda	C_InputField		;Farbe für Anzeigebereich setzen.
			jsr	DirectColor

			jsr	InitVecColTab		;Farb-Tabelle initialisieren.

			tya				;Zeiger auf Farbwert einlesen.
			and	#%01111111
			asl
			asl
			pha
			tay
			lda	(r15L),y		;Zeiger auf Text/Zeile#1.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos1_y +RLine1_1 +$06)
			jsr	:prntCurLine		;Textzeile ausgeben.

			pla
			tay
			iny
			iny
			lda	(r15L),y		;Zeiger auf Text/Zeile#2.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#(RPos1_y +RLine1_1 +$08 +$06)

::prntCurLine		sty	r1H			;Cursorposition festlegen.
			LoadW	r11,(RPos1_x +RWidth1 +$02)

			jmp	PutString		;Textzeile ausgeben.

;*** Zeiger auf Tabelle mit Farbbereichen setzen.
:InitVecColTab		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			ldy	Vec2ColorTab,x		;GEOS/MegaPatch- oder GeoDesk?
			bmi	:colNameGDesk		; => GeoDesk, weiter...

::colNameGEOS		lda	#<Vec2ColNames1		;Zeiger auf GEOS/MegaPatch-Farben.
			ldx	#>Vec2ColNames1
			bne	:1

::colNameGDesk		lda	#<Vec2ColNames2		;Zeiger auf GeoDesk-Farben.
			ldx	#>Vec2ColNames2

::1			sta	r15L			;Zeiger auf Tabelle mit den
			stx	r15H			;Farbtexten festlegen.
			rts

;*** Zeiger auf nächsten Bereich.
:NextColEntry		ldx	Vec2Color		;Nächster Bereich.
::2			inx
			cpx	#ignoreColor
			beq	:2
			cpx	#MaxColSettings
			bcc	:1
			ldx	#$00
::1			jmp	SetColEntry

;*** Zeiger auf letzten Bereich.
:LastColEntry		ldx	Vec2Color		;Vorheriger Bereich.
			bne	:1
			ldx	#MaxColSettings
::1			dex
			cpx	#ignoreColor
			beq	:1

:SetColEntry		stx	Vec2Color
			jsr	PrintCurColName		;Farbbereich ausgeben.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

;*** Aktuelle Farbeinstellungen anzeigen.
:UpdateCurColor		LoadW	r15,RegTMenu_1a		;Farbbereiche für Vorder- und
			jsr	RegisterUpdate		;Hintergrund anzeigen.
			LoadW	r15,RegTMenu_1b
			jmp	RegisterUpdate

;*** Aktuellen Farbwert für Text ausgeben.
:PrintCurColorT		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			lda	Vec2ColorTab,x		;GEOS/MegaPatch- oder GeoDesk?
			bmi	:colDataGDesk		; => GeoDesk, weiter...

::colDataGEOS		tax				;Aktuellen Farbwert aus
			lda	MP3_COLOR_DATA,x	;GEOS/MegaPatch-Farbtabelle holen.
			jmp	:prntColData

::colDataGDesk		and	#%01111111
			tax				;Aktuellen Farbwert aus
			lda	GDESK_COLS_A,x		;GeoDesk-Farbtabelle holen.

::prntColData		lsr				;Farbbereich anzeigen.
			lsr
			lsr
			lsr
			jmp	DirectColor

;*** Aktuellen Farbwert für Hintergrund ausgeben.
:PrintCurColorB		ldx	Vec2Color		;Aktuelle Farbe aus Tabelle holen.
			lda	Vec2ColorTab,x		;GEOS/MegaPatch- oder GeoDesk?
			bmi	:colDataGDesk		; => GeoDesk, weiter...

::colDataGEOS		tax				;Aktuellen Farbwert aus
			lda	MP3_COLOR_DATA,x	;GEOS/MegaPatch-Farbtabelle holen.
			jmp	:prntColData

::colDataGDesk		and	#%01111111
			tax				;Aktuellen Farbwert aus
			lda	GDESK_COLS_A,x		;GeoDesk-Farbtabelle holen.

::prntColData		and	#%00001111		;Farbbereich anzeigen.
			jmp	DirectColor

;*** Icon-Farbe wechseln.
:PrintCurIColName	lda	#$00			;Füllmuster für Farbbereich.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos3_y +RLine3_1
			b	RPos3_y +RLine3_1 +$08 -$01
			w	RPos3_x +RWidth3
			w	R1SizeX1 -$18

			lda	C_InputField		;Farbe für Anzeigebereich setzen.
			jsr	DirectColor

;--- Icon-Typ festlegen.
			lda	Vec2ICol		;Zeiger auf Icon-Typ einlesen.
			asl
			tay
			lda	vecGTypeText,y		;Zeiger auf Text einlesen.
			sta	r0L
			iny
			lda	vecGTypeText,y
			sta	r0H

;--- Cursorposition festlegen.
			LoadB	r1H,(RPos3_y +RLine3_1 +$06)
			LoadW	r11,(RPos1_x +RWidth1 +$02)

			jmp	PutString		;Textzeile ausgeben.

;*** Zeiger auf nächsten Icon-Typ.
:NextIColEntry		ldx	Vec2ICol		;Nächster Icon-Typ.
			inx
			cpx	#MaxIColSettings
			bcc	:1
			ldx	#$00
::1			stx	Vec2ICol
			jsr	PrintCurIColName	;Farbbereich ausgeben.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

;*** Aktuelle Farbeinstellungen anzeigen.
:UpdateCurIColor	jsr	setColPreview		;Farbe für Vorschau-Icon.

			LoadW	r15,RegTMenu_3a		;Farbbereiche für Vorder- und
			jmp	RegisterUpdate		;Hintergrund anzeigen.

;*** Aktuellen Farbwert für Icon ausgeben.
:PrintCurIColor		ldx	Vec2ICol		;Zeiger auf Tabelle holen.
			ldy	Vec2IColTab,x
			lda	GDESK_ICOLTAB,y		;Icon-Farbe aus Farbtabelle holen.
			lsr				;Farbbereich anzeigen.
			lsr
			lsr
			lsr
			jmp	DirectColor		;Farbe anzeigen.

;*** Farbe für Vorschau-Icon.
:setColPreview		ldx	Vec2ICol		;Zeiger auf Tabelle holen.
			ldy	Vec2IColTab,x
			lda	GDESK_ICOLTAB,y		;Icon-Farbe aus Farbtabelle holen.
			bne	:1
			lda	C_WinBack		;Farbe verknüpfen.
			and	#%11110000
::1			sta	r7L			;Farbwert für Icon mit Hintergund-
			lda	C_WinBack		;Farbe verknüpfen.
			and	#%00001111
			ora	r7L
			jsr	i_UserColor		;Vorschau-Icon einfärben.
			b	(R1SizeX1 -$28 +$01) / 8
			b	(RPos3_y +RLine3_4) / 8
			b	3,3
			rts

;*** Farbtabelle Text/Hintergrund ausgeben.
;    Übergabe: r1L = $00=Farbtabelle anzeigen/$FF=aktualisieren.
;              Wird durch RegisterMenü gesetzt.
:ColorInfoT		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorT		; => Nein, weiter...
			lda	#(RPos1_y +RLine1_2)/8
			bne	ColorInfo

:ColorInfoB		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorB		; => Nein, weiter...
			lda	#(RPos1_y +RLine1_3)/8
			bne	ColorInfo

:ColorInfoI		lda	r1L			;Farbtabelle anzeigen?
			bne	SetColorI		; => Nein, weiter...
			lda	#(RPos3_y +RLine3_2)/8

:ColorInfo		sta	:2 +1

			lda	#(RPos1_x +RWidth1)/8
			sta	:2 +0

			ldx	#$00			;Farbtabelle ausgeben.
::1			txa
			pha
			lda	ColorTab,x		;Farbwert einlesen und
			jsr	i_UserColor		;anzeigen.
::2			b	$00,$11,$01,$01
			inc	:2 +0
			pla
			tax
			inx				;Zeiger auf nächste Farbe setzen.
			cpx	#$10			;Alle Farben angezeigt?
			bne	:1			; => Nein, weiter...
			rts

;*** Neue Textfarbe setzen.
:SetColorT		lda	#$00
			b $2c

;*** Neue Hintergrundfarbe setzen.
:SetColorB		lda	#$ff
			sta	r13H

			jsr	InitVecDataTab		;Zeiger auf Systemfarben setzen.

			jsr	getSlctColor		;Zeiger auf Farbdaten berechnen.

			lda	ColorTab,x		;Farbwert einlesen und
			sta	r0L			;zwischenspeichern.

			ldx	Vec2Color
			lda	Vec2ColorTab,x
			and	#%01111111
			asl
			pha
			tay

			bit	r13H			;Vorder- oder Hintergrundfarbe?
			bpl	:0			; => Vordergrund, weiter...
			iny

::0			lda	(r14L),y		;Modus einlesen.
			and	#%11110000		;Vordergrund anzeigen?
			beq	:1			; => Nein, weiter...
			jsr	Add1High		;High-Nibble Farbwert erzeugen.

::1			pla
			tay

			bit	r13H			;Vorder- oder Hintergrundfarbe?
			bpl	:2			; => Vordergrund, weiter...
			iny

::2			lda	(r14L),y		;Modus einlesen.
			and	#%00001111		;Hintergrund anzeigen?
			beq	:3			; => Nein, weiter...
			jsr	Add1Low			;Low-Nibble Farbwert erzeugen.

::3			jmp	UpdateCurColor		;Farbwert anzeigen.

;*** Neue Icon-Farbe setzen.
:SetColorI		jsr	getSlctColor		;Zeiger auf Farbdaten berechnen.

			lda	ColorTab,x		;Farbwert einlesen.
			asl
			asl
			asl
			asl
			ldx	Vec2ICol		;Zeiger auf Farbtabelle.
			ldy	Vec2IColTab,x
			sta	GDESK_ICOLTAB,y		;Neuen Farbwert speichern.
			jmp	UpdateCurIColor

;*** Gewählte Farbe berechnen.
:getSlctColor		lda	mouseXPos +1		;Position Mauszeiger einlesen und
			lsr				;in Zeiger auf Farbtabelle wandeln.
			lda	mouseXPos +0
			ror
			lsr
			lsr
			sec
			sbc	#(RPos1_x +RWidth1)/8
			tax
			rts

;*** Textfarbe wechseln.
:Add1High		ldx	Vec2Color
			lda	Vec2ColorTab,x
			and	#%01111111		;GEOS/GeoDesk-Bit ausblenden.
			tay
			lda	(r15L),y		;Farbwert einlesen und
			and	#%00001111		;Low-Nibble isolieren.
			sta	r0H
			lda	r0L			;Aktueller Farbwert in High-Nibble
			asl				;umwandeln.
			asl
			asl
			asl
			ora	r0H			;High-/Low-Nibble erzeugen und
			sta	(r15L),y		;neuen Farbwert speichern.
			rts

;*** Hintergrundfarbe wechseln.
:Add1Low		ldx	Vec2Color
			lda	Vec2ColorTab,x
			and	#%01111111		;GEOS/GeoDesk-Bit ausblenden.
			tay
			lda	(r15L),y		;Farbwert einlesen und
			and	#%11110000		;Low-Nibble isolieren.
			ora	r0L			;High-/Low-Nibble erzeugen und
			sta	(r15L),y		;neuen Farbwert speichern.
			rts

;*** Tabellenzeiger initialisieren.
;    Rückgabe: r14 = High-/Low-Nibble-Informationen.
;              r15 = Zeiger auf Farbdaten GEOS/GeoDesk.
:InitVecDataTab		ldx	Vec2Color
			ldy	Vec2ColorTab,x
			bmi	:colDataGDesk

::colDataGEOS		lda	#<MP3_COLOR_DATA
			ldx	#>MP3_COLOR_DATA
			bne	:1

::colDataGDesk		lda	#<GDESK_COLS_A
			ldx	#>GDESK_COLS_A

::1			sta	r15L			;Zeiger auf Farbdaten festlegen.
			stx	r15H

			tya
			bmi	:colModeGDesk

::colModeGEOS		lda	#<ColModifyTab1
			ldx	#>ColModifyTab1
			bne	:2

::colModeGDesk		lda	#<ColModifyTab2
			ldx	#>ColModifyTab2

::2			sta	r14L			;Zeiger auf High-/Low-Nibble
			stx	r14H			;Farbinformationen speichern.

			rts

;*** GEOS-Farben auf Standard setzen.
:ResetCol_GEOS		lda	ORIG_C_GEOS_PAT		;Füllmuster zurücksetzen.
			sta	BackScrPattern
			sta	C_GEOS_PATTERN

			jsr	i_MoveData		;GEOS-Farben zurücksetzen.
			w	ORIG_COL_GEOS_A
			w	MP3_COLOR_DATA
			w	(ORIG_COL_GEOS_E - ORIG_COL_GEOS_A)

			jmp	RegisterAllOpt		;RegisterMenü aktualisieren.

;*** GeoDesk-Farben auf Standard setzen.
:ResetCol_GDESK		lda	ORIG_C_GDESK_PAT	;Füllmuster zurücksetzen.
			sta	C_GDESK_PATTERN
			lda	ORIG_C_GTASK_PAT
			sta	C_GTASK_PATTERN

			jsr	i_MoveData		;GeoDesk-Farben zurücksetzen.
			w	ORIG_GDESK_COLS_A
			w	GDESK_COLS_A
			w	(ORIG_GDESK_COLS_E - ORIG_GDESK_COLS_A)

			jmp	RegisterAllOpt		;RegisterMenü aktualisieren.

;*** Datei-Icon-Farben auf Standard setzen.
:ResetCol_FICON		jsr	i_MoveData		;Datei-Icon-Farben zurücksetzen.
			w	ORIG_GDESK_ICOLTAB_A
			w	GDESK_ICOLTAB
			w	(ORIG_GDESK_ICOLTAB_E - ORIG_GDESK_ICOLTAB_A)

			jmp	RegisterAllOpt		;RegisterMenü aktualisieren.

;*** Konfiguration speichern.
:svColorConfig		jsr	TempBootDrive		;Boot-Laufwerk aktivieren.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::1			LoadW	r6,configName
			jsr	FindFile		;Farbdatei suchen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
			cpx	#$05			;"FILE NOT FOUND"?
			beq	:3			; => Ja, ignorieren...
			bne	:reset			;Diskfehler anzeigen.

::2			LoadW	r0,configName
			jsr	DeleteFile		;Vorhandene Datei löschen.
			txa				;Fehler?
			bne	:reset			; => Ja, Diskfehler anzeigen.

::3			jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	MP3_COLOR_DATA
			w	GEOS_SYS_COLS_A
			w	(GEOS_SYS_COLS_E - GEOS_SYS_COLS_A)

			lda	BackScrPattern		;GEOS-Füllmuster übernehmen.
			sta	C_GEOS_PATTERN

			LoadB	r10L,0			;Zeiger auf Infoblock für
			LoadW	r9,HdrB000		;neue Konfigurationsdatei.
			jsr	SaveFile		;Datei speichern.
			txa				;Fehler?
			bne	:reset			; => Ja, Diskfehler anzeigen.

			LoadW	r6,configName
			jsr	FindFile		;Konfigurationsdatei suchen.
			txa				;Datei gefunden?
			bne	:reset			; => Ja, Diskfehler anzeigen.

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler?
			bne	:reset			; => Ja, Diskfehler anzeigen.

			lda	HdrB160			;SaveFile löscht Byte #160,
			sta	fileHeader +160		;Byte wieder herstellen.

			lda	dirEntryBuf+19
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	PutBlock		;Infoblock schreiben.
			txa				;Fehler?
			bne	:reset			; => Ja, Diskfehler anzeigen.

			jsr	getCfgDriveNm		;Laufwerksname übernehmen.

			LoadW	r0,Dlg_DiskSave
			jsr	DoDlgBox		;Hinweis: Konfiguration gespeichert.

			LoadB	reloadDir,$ff		;Fenster aktualisieren.

			jmp	BackTempDrive		;Laufwerk zurücksetzen.

;*** Diskfehler ausgeben.
::reset			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			jmp	BackTempDrive		;Laufwerk zurücksetzen.

;*** Konfiguration laden.
:ldColorConfig		jsr	TempBootDrive		;Boot-Laufwerk aktivieren.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			jmp	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

::1			jsr	LoadColConfig		;Farbeinstellungen laden.
			txa				;Fehler?
			bne	:reset			; => Ja, Abbruch...

			jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	GEOS_SYS_COLS_A
			w	MP3_COLOR_DATA
			w	(GEOS_SYS_COLS_E - GEOS_SYS_COLS_A)

			lda	C_GEOS_PATTERN		;GEOS-Füllmuster übernehmen.
			sta	BackScrPattern

			lda	C_GEOS_MOUSE		;Standardfarbe Mauszeiger.
			sta	C_Mouse

			jsr	ApplyConfig		;Farbe Mauszeiger übernehmen.

			jsr	RegisterAllOpt		;Register-Menü aktualisieren.

			jsr	getCfgDriveNm		;Laufwerksname übernehmen.

			LoadW	r0,Dlg_DiskLoad
			jsr	DoDlgBox		;Hinweis: Konfiguration geladen.

			jmp	BackTempDrive		;Laufwerk zurücksetzen.

::reset			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			jmp	BackTempDrive		;Laufwerk zurücksetzen.

;*** Laufwerksadresse übernehmen.
:getCfgDriveNm		lda	BootDrive		;Laufwerksname in
			clc				;DialogBox übernehmen.
			adc	#"A" -$08
			sta	configDrive
			rts

;*** Sortierte Farbtabelle.
:ColorTab		b $01,$0f,$0c,$0b,$00,$09,$08,$07
			b $0a,$02,$04,$06,$0e,$03,$05,$0d

;*** Farbeinstellungen.
:Vec2Color		b $00				;Zeiger aktueller Farbbereich.
:Vec2ICol		b $00				;Zeiger aktueller Icon-Typ.

;*** Datei-Icon-Farben.
:MaxIColSettings	= 21
:Vec2IColTab		b $00				;#1  : Nicht GEOS.
			b $01				;#2  : BASIC-Programm.
			b $02				;#3  : Assembler-Programm.
			b $03				;#4  : Datenfile.
			b $04				;#5  : Systemdatei.
			b $05				;#6  : Hilfsprogramm.
			b $06				;#7  : Anwendung.
			b $07				;#8  : Dokument.
			b $08				;#9  : Zeichensatz.
			b $09				;#10 : Druckertreiber.
			b $0a				;#11 : Eingabetreiber.
			b $0b				;#12 : Laufwerkstreiber.
			b $0c				;#13 : Startprogramm.
			b $0d				;#14 : Temporäre Datei (SWAP FILE).
			b $0e				;#15 : Selbstausführend (AUTO_EXEC).
			b $0f				;#16 : Eingabetreiber C128.
			b $11				;#17 : gateWay-Dokument.
			b $15				;#18 : geoShell-Befehl.
			b $16				;#19 : geoFax-Dokument.
			b $17				;#20 : Unbekannt.
			b $18				;#21 : Verzeichnis.

;*** GEOS- oder GeoDesk-Farben?
;    GEOS    = %0xxxxxxx
;    GeoDesk = %1xxxxxxx
:MaxColSettings		= 32
:ignoreColor		= 4 -1
:Vec2ColorTab		b $01				;#1  : GEOS/Registerkarten: Aktives Register.
			b $02				;#2  : GEOS/Registerkarten: Inaktives Register.
			b $03				;#3  : GEOS/Registerkarten: Hintergrund/Text.
			b $04				;#4  : GEOS/Zeiger: Mauspfeil/Pointer.
			b $05				;#5  : GEOS/Dialogbox: Titel.
			b $06				;#6  : GEOS/Dialogbox: Hintergrund/Text.
			b $07				;#7  : GEOS/Dialogbox: System-Icons.
			b $0e				;#14 : GEOS/Dialogbox: Schatten.
			b $08				;#8  : GEOS/Dateiauswahlbox: Titel.
			b $09				;#9  : GEOS/Dateiauswahlbox: Hintergrund/Text.
			b $0a				;#10 : GEOS/Dateiauswahlbox: System-Icons.
			b $0b				;#11 : GEOS/Dateiauswahlbox: Dateifenster.
			b $00				;#0  : GEOS/Dateiauswahlbox: Balken und Pfeile.
			b $0c				;#12 : GEOS/Fenster: Titel.
			b $0d				;#13 : GEOS/Fenster: Hintergrund/Text.
			b $0f				;#15 : GEOS/Fenster: System-Icons.
			b $10				;#16 : GEOS/PullDown: GEOS-Menü für Anwendungen.
			b $11				;#17 : GEOS/Eingabefelder: Eingabefeld.
			b $12				;#18 : GEOS/Eingabefelder: Inaktives Optionsfeld.
			b $13				;#19 : GEOS/Standard: Hintergrund.
			b $14				;#20 : GEOS/Standard: Rahmen.
			b $15				;#21 : GEOS/Standard: Mauszeiger.

			b $83				;#3  : GeoDesk: GEOS-Hauptmenü.
			b $82				;#2  : GeoDesk: Datum und Uhrzeit.
			b $85				;#5  : GeoDesk: TaskBar.
			b $89				;#9  : GeoDesk: DeskTop.
			b $86				;#6  : GeoDesk/AppLinks: AppLink-Icon.
			b $87				;#7  : GeoDesk/AppLinks: AppLink-Titel.
			b $88				;#8  : GeoDesk/AppLinks: Arbeitsplatz.
			b $80				;#0  : GeoDesk/Fenster: Scollbalken.
			b $81				;#1  : GeoDesk/Fenster: Scoll-Icons Up/Down.
			b $84				;#4  : GeoDesk/Registermenü: Menü beenden.

;*** Tabelle zum ändern des Farbwertes.
;    Highbyte:		Textfarbe ändern.
;    Lowbyte:		Hintergrundfarbe ändern.
;    Byte #1:		Textfarbe.
;    Byte #2:		Hintergrundfarbe.
:ColModifyTab1		b %11110000,%00001111		;#0
			b %11110000,%00001111		;#1
			b %11110000,%00001111		;#2
			b %11110000,%00001111		;#3
			b %11111111,%11111111		;#4
			b %11110000,%00001111		;#5
			b %11110000,%00001111		;#6
			b %11110000,%00001111		;#7
			b %11110000,%00001111		;#8
			b %11110000,%00001111		;#9
			b %11110000,%00001111		;#10
			b %11110000,%00001111		;#11
			b %11110000,%00001111		;#12
			b %11110000,%00001111		;#13
			b %11111111,%11111111		;#14
			b %11110000,%00001111		;#15
			b %11110000,%00001111		;#16
			b %11110000,%00001111		;#17
			b %11110000,%00001111		;#18
			b %11110000,%00001111		;#19
			b %11111111,%11111111		;#20
			b %11111111,%11111111		;#21

:Vec2ColNames1		w Text_1_05, Text_2_01		;#0
			w Text_1_02, Text_2_02		;#1
			w Text_1_02, Text_2_03		;#2
			w Text_1_02, Text_2_04		;#3
			w Text_1_03, Text_2_05		;#4
			w Text_1_04, Text_2_06		;#5
			w Text_1_04, Text_2_04		;#6
			w Text_1_04, Text_2_07		;#7
			w Text_1_05, Text_2_06		;#8
			w Text_1_05, Text_2_04		;#9
			w Text_1_05, Text_2_07		;#10
			w Text_1_05, Text_2_08		;#11
			w Text_1_06, Text_2_16		;#12
			w Text_1_06, Text_2_04		;#13
			w Text_1_04, Text_2_09		;#14
			w Text_1_06, Text_2_07		;#15
			w Text_1_07, Text_2_10		;#16
			w Text_1_08, Text_2_11		;#17
			w Text_1_08, Text_2_12		;#18
			w Text_1_09, Text_2_13		;#19
			w Text_1_09, Text_2_14		;#20
			w Text_1_09, Text_2_15		;#21

if LANG = LANG_DE
:Text_1_02		b "GEOS/Registerkarten:",NULL
:Text_1_03		b "GEOS/Zeiger",NULL
:Text_1_04		b "GEOS/Dialogbox:",NULL
:Text_1_05		b "GEOS/Dateiauswahlbox:",NULL
:Text_1_06		b "GEOS/Fenster:",NULL
:Text_1_07		b "GEOS/PullDown-Menu",NULL
:Text_1_08		b "GEOS/Eingabefelder:",NULL
:Text_1_09		b "GEOS/Standard:",NULL

:Text_2_01		b "Balken und Pfeile",NULL
:Text_2_02		b "Aktives Register",NULL
:Text_2_03		b "Inaktives Register",NULL
:Text_2_04		b "Textfarbe/Hintergrund",NULL
:Text_2_05		b "Mauspfeil/Pointer",NULL
:Text_2_06		b "Titel",NULL
:Text_2_07		b "System-Icons",NULL
:Text_2_08		b "Dateifenster",NULL
:Text_2_09		b "Schatten",NULL
:Text_2_10		b "(Für GEOS-Anwendungen)",NULL
:Text_2_11		b "Text-Eingabefeld",NULL
:Text_2_12		b "Inaktives Optionsfeld",NULL
:Text_2_13		b "Hintergrund/Anwendungen",NULL
:Text_2_14		b "Rahmen",NULL
:Text_2_15		b "Mauszeiger",NULL
:Text_2_16		b "Titelzeile/Statuszeile",NULL
endif
if LANG = LANG_EN
:Text_1_02		b "GEOS/Register cards:",NULL
:Text_1_03		b "GEOS/Pointer",NULL
:Text_1_04		b "GEOS/Dialogue box:",NULL
:Text_1_05		b "GEOS/File selector box:",NULL
:Text_1_06		b "GEOS/Window:",NULL
:Text_1_07		b "GEOS/PullDown menu",NULL
:Text_1_08		b "GEOS/Input fields:",NULL
:Text_1_09		b "GEOS/Default:",NULL

:Text_2_01		b "Scrollbar and arrows",NULL
:Text_2_02		b "Active register",NULL
:Text_2_03		b "Inactive register",NULL
:Text_2_04		b "Text color/Background",NULL
:Text_2_05		b "Mouse/Pointer",NULL
:Text_2_06		b "Title",NULL
:Text_2_07		b "System icons",NULL
:Text_2_08		b "File window",NULL
:Text_2_09		b "Shadow",NULL
:Text_2_10		b "(For GEOS applications)",NULL
:Text_2_11		b "Input field for text",NULL
:Text_2_12		b "Inactive option field",NULL
:Text_2_13		b "Background/Applications",NULL
:Text_2_14		b "Border",NULL
:Text_2_15		b "Mouse",NULL
:Text_2_16		b "Titlebar/Statusbar",NULL
endif

;*** Tabelle zum ändern des Farbwertes.
;    Highbyte:		Textfarbe ändern.
;    Lowbyte:		Hintergrundfarbe ändern.
;    Byte #1:		Textfarbe.
;    Byte #2:		Hintergrundfarbe.
:ColModifyTab2		b %11110000,%00001111		;#0
			b %11110000,%00001111		;#1
			b %11110000,%00001111		;#2
			b %11110000,%00001111		;#3
			b %11110000,%00001111		;#4
			b %11110000,%00001111		;#5
			b %11110000,%00001111		;#6
			b %11110000,%00001111		;#7
			b %11110000,%00001111		;#8
			b %11110000,%00001111		;#9

:Vec2ColNames2		w Text_3_01, Text_4_01		;#0
			w Text_3_01, Text_4_02		;#1
			w Text_3_02, Text_4_03		;#2
			w Text_3_02, Text_4_04		;#3
			w Text_3_03, Text_4_05		;#4
			w Text_3_02, Text_4_06		;#5
			w Text_3_04, Text_4_07		;#6
			w Text_3_04, Text_4_08		;#7
			w Text_3_04, Text_4_09		;#8
			w Text_3_02, Text_4_10		;#9

if LANG = LANG_DE
:Text_3_01		b "GeoDesk/Fenster:",NULL
:Text_3_02		b "GeoDesk/DeskTop:",NULL
:Text_3_03		b "GeoDesk/Registermenu:",NULL
:Text_3_04		b "GeoDesk/AppLinks:",NULL

:Text_4_01		b "Scrollbalken",NULL
:Text_4_02		b "Scroll Up/Down",NULL
:Text_4_03		b "Datum und Uhrzeit",NULL
:Text_4_04		b "GEOS-Hauptmenü",NULL
:Text_4_05		b "Menü beenden",NULL
:Text_4_06		b "TaskBar",NULL
:Text_4_07		b "AppLink-Icon",NULL
:Text_4_08		b "AppLink-Titel/Name",NULL
:Text_4_09		b "Arbeitsplatz-Icon",NULL
:Text_4_10		b "DeskTop-Hintergrund",NULL
endif
if LANG = LANG_EN
:Text_3_01		b "GeoDesk/Window:",NULL
:Text_3_02		b "GeoDesk/DeskTop:",NULL
:Text_3_03		b "GeoDesk/Register menu:",NULL
:Text_3_04		b "GeoDesk/AppLinks:",NULL

:Text_4_01		b "Scrollbar",NULL
:Text_4_02		b "Scroll up/down",NULL
:Text_4_03		b "Date and Time",NULL
:Text_4_04		b "GEOS main menu",NULL
:Text_4_05		b "Exit menu",NULL
:Text_4_06		b "TaskBar",NULL
:Text_4_07		b "AppLink icon",NULL
:Text_4_08		b "AppLink title/name",NULL
:Text_4_09		b "MyComputer icon",NULL
:Text_4_10		b "DeskTop background",NULL
endif

;******************************************************************************
:ORIG_COL_GEOS_A					;Beginn der Farbtabelle.
::C_Balken		b $0d				;Scrollbalken.
::C_Register		b $07				;Karteikarten: Aktiv.
::C_RegisterOff		b $08				;Karteikarten: Inaktiv.
::C_RegisterBack	b $07				;Karteikarten: Hintergrund.
::C_Mouse		b $06				;Mausfarbe.
::C_DBoxTitel		b $10				;Dialogbox: Titel.
::C_DBoxBack		b $03				;Dialogbox: Hintergrund + Text.
::C_DBoxDIcon		b $01				;Dialogbox: System-Icons.
::C_FBoxTitel		b $10				;Dateiauswahlbox: Titel.
::C_FBoxBack		b $0e				;Dateiauswahlbox: Hintergrund + Text.
::C_FBoxDIcon		b $01				;Dateiauswahlbox: System-Icons.
::C_FBoxFiles		b $03				;Dateiauswahlbox: Dateifenster.
::C_WinTitel		b $10				;Fenster: Titel.
::C_WinBack		b $0f				;Fenster: Hintergrund.
::C_WinShadow		b $00				;Fenster: Schatten.
::C_WinIcon		b $0d				;Fenster: System-Icons.
::C_PullDMenu		b $03				;PullDown-Menu.
::C_InputField		b $01				;Text-Eingabefeld.
::C_InputFieldOff	b $0f				;Inaktives Optionsfeld.
::C_GEOS_BACK		b $bf				;GEOS-Standard: Hintergrund.
::C_GEOS_FRAME		b $00				;GEOS-Standard: Rahmen.
::C_GEOS_MOUSE		b $06				;GEOS-Standard: Mauszeiger.
:ORIG_COL_GEOS_E					;Ende der Farbtabelle.

;******************************************************************************
:ORIG_GDESK_COLS_A					;Beginn der Farbtabelle.
::C_WinScrBar		b $01				;Fenster/Scrollbalken.
::C_WinMovIcons		b $10				;Scroll Up/Down-Icons.
::C_GDesk_Clock		b GD_COLOR_CLOCK		;GeoDesk-Uhr.
::C_GDesk_GEOS		b $03				;GEOS-Menübutton.
::C_RegisterExit	b $0d				;Karteikarten: Beenden.
::C_GDesk_TaskBar	b $10				;GeoDesk-Taskbar.
::C_GDesk_ALIcon	b $01				;Farbe für AppLink-Icons/Standard.
::C_GDesk_ALTitle	b $07				;Farbe für AppLink-Titel.
::C_GDesk_MyComp	b $01				;Farbe für Arbeitsplatz-Icon.
::C_GDesk_DeskTop	b $bf				;Farbe für GeoDesk ohne BackScreen.
:ORIG_GDESK_COLS_E					;Ende der Farbtabelle.

;******************************************************************************
:ORIG_C_GEOS_PAT	b $02				;GEOS-Hintergrund-Füllmuster.
:ORIG_C_GDESK_PAT	b $02				;GeoDesk-Hintergrund-Füllmuster.
:ORIG_C_GTASK_PAT	b $00				;GeoDesk/TaskBar-Füllmuster.

;******************************************************************************
:ORIG_GDESK_ICOLTAB_A
::fileColorTab		b $00				;$00-Nicht GEOS.
			b $60				;$01-BASIC-Programm.
			b $60				;$02-Assembler-Programm.
			b $c0				;$03-Datenfile.
			b $20				;$04-Systemdatei.
			b $60				;$05-Hilfsprogramm.
			b $60				;$06-Anwendung.
			b $50				;$07-Dokument.
			b $d0				;$08-Zeichensatz.
			b $40				;$09-Druckertreiber.
			b $40				;$0A-Eingabetreiber.
			b $40				;$0B-Laufwerkstreiber.
			b $20				;$0C-Startprogramm.
			b $c0				;$0D-Temporäre Datei (SWAP FILE).
			b $60				;$0E-Selbstausführend (AUTO_EXEC).
			b $40				;$0F-Eingabetreiber C128.
			b $c0				;$10-Unbekannt.
			b $40				;$11-gateWay-Dokument.
			b $c0				;$12-Unbekannt.
			b $c0				;$13-Unbekannt.
			b $c0				;$14-Unbekannt.
			b $40				;$15-geoShell-Befehl.
			b $50				;$16-geoFax-Dokument.
			b $c0				;$17-Unbekannt.
			b $b0				;$18-Verzeichnis.
:ORIG_GDESK_ICOLTAB_E

;*** Variablen.
:configDrive		b "A:",PLAINTEXT,NULL
;findFileName		s 17

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w configName
::byte002		b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00001101
			b %10011100,%00111000,%00010001
			b %10011100,%00111000,%00010001
			b %10011100,%00111000,%00010001
			b %10000000,%00000000,%00001101
			b %10111110,%01111100,%00000001
			b %10000000,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10000000,%00000011,%00111001
			b %10111110,%00000100,%00100101
			b %10000000,%00000101,%10100101
			b %10000000,%00000100,%10100101
			b %10000000,%00000011,%10111001
			b %10000000,%00000000,%00000001
			b %10101010,%10101010,%10101011
			b %11010101,%01010101,%01010101
			b %11111111,%11111111,%11111111

::byte068		b $82				;SEQ.
::byte069		b SYSTEM			;GEOS-Systemdatei.
::byte070		b SEQUENTIAL			;GEOS-Dateityp VLIR.
::byte071		w GD_SYSCOL_A			;Programm-Anfang.
::byte073		w GD_SYSCOL_E			;Programm-Ende.
::byte075		w $0000				;Programm-Start.
::byte077		b "geoDeskCol  "		;Klasse
::byte089		b "V1.0"			;Version
::byte093		b NULL
::byte094		b $00,$00			;Reserviert
::byte096		b $00				;Bildschirmflag
::byte097		b "GeoDesk64"			;Autor
::byte106		s 11				;Reserviert
::byte117		s 12  				;Anwendung/Klasse
::byte129		s 4  				;Anwendung/Version
::byte133		b NULL
::byte134		s 26				;Reserviert.

if LANG = LANG_DE
:HdrB160		b "Konfigurationsdatei",CR
			b "für GeoDesk Farben",NULL
endif
if LANG = LANG_EN
:HdrB160		b "Configuration file",CR
			b "for GeoDesk colors",NULL
endif

::HdrEnd		s (HdrB000+256)-:HdrEnd

;*** Info: Konfiguration gespeichert.
:Dlg_DiskSave		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$18,$3a
			w :4
			b DBTXTSTR   ,$38,$3a
			w configDrive
			b DBTXTSTR   ,$42,$3a
			w configName
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Voreinstellungen wurden auf dem",NULL
::3			b "GeoDesk-Startlaufwerk gespeichert:",NULL
::4			b BOLDON
			b "Datei:",PLAINTEXT,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The default color settings were",NULL
::3			b "saved on the GeoDesk boot drive:",NULL
::4			b BOLDON
			b "File:",PLAINTEXT,NULL
endif

;*** Info: Konfiguration geladen.
:Dlg_DiskLoad		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$18,$3a
			w :4
			b DBTXTSTR   ,$38,$3a
			w configDrive
			b DBTXTSTR   ,$42,$3a
			w configName
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Voreinstellungen wurden vom",NULL
::3			b "GeoDesk-Startlaufwerk eingelesen:",NULL
::4			b BOLDON
			b "Datei:",PLAINTEXT,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The default color settings were",NULL
::3			b "loaded from the GeoDesk boot drive:",NULL
::4			b BOLDON
			b "File:",PLAINTEXT,NULL
endif
