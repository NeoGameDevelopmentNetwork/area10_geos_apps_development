; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Pull-Down-Menü erzeugen.
:xDoMenu		sta	DM_MseOnEntry		;Mauszeiger auf Menü-Eintrag.

			ldx	#$00			;Hauptmenü aktivieren.
			stx	menuNumber
			beq	DM_SaveMenu		;Neues Menü aktivieren.

;*** Neues Menü öffnen.
:DM_OpenMenu		ldx	menuNumber
			lda	#$00
			sta	DM_MseOnEntry,x

;*** Menüzeiger speichern.
:DM_SaveMenu		lda	r0L			;Zeiger auf Menütabelle
			sta	DM_MenuTabL,x		;zwischenspeichern.
			lda	r0H
			sta	DM_MenuTabH,x
			jsr	DM_SetMenuData		;Menüdaten einlesen.
			sec

;*** Menü initialisieren.
:DM_InitMenu		php
			lda	dispBufferOn		;Bildschirm-Flag
			pha				;zwischenspeichern.
			lda	#%10000000		;Menü nur im Vordergrund
			sta	dispBufferOn		;aufbauen.
			lda	r11H			;Register ":r11"
			pha				;zwischenspeichern.
			lda	r11L
			pha
			jsr	DM_SetMenuRec		;Menüfenster berechnen.

			lda	curPattern+1		;Zeiger auf Füllmuster
			pha				;zwischenspeichern.
			lda	curPattern+0
			pha
			lda	#$00			;Füllmuster #0 für Menü-
			jsr	SetPattern		;rechteck setzen.
			jsr	Rectangle		;Menü-Rechteck zeichnen.
			pla				;Füllmuster zurückschreiben.
			sta	curPattern+0
			pla
			sta	curPattern+1
			lda	#%11111111		;Rahmen um Menü-Rechteck
			jsr	FrameRectangle		;zeichnen.
			pla				;Register ":r11" zurücksetzen.
			sta	r11L
			pla
			sta	r11H
			jsr	DM_PrintMenu
			jsr	DM_SetMenuLine
			pla				;Bildschirm-Flag
			sta	dispBufferOn		;zurückschreiben.
			plp
			bit	DM_MenuType		;Menüdefinition testen.
			bvs	:1			; -> Mauszeiger einschränken.
			bcc	:4

;*** Position für Mauszeiger setzen.
::1			ldx	menuNumber
			ldy	DM_MseOnEntry,x
			bit	DM_MenuType		;Menü Vertikal / Horizontal ?
			bmi	:2			; -> Vertikal.

			lda	DM_MenuPosL,y		;Mauszeiger auf die mitte des
			sta	r11L			;gewählten Menüpunktes setzen.
			lda	DM_MenuPosH,y
			sta	r11H
			iny
			lda	DM_MenuPosL,y
			clc
			adc	r11L
			sta	r11L
			lda	DM_MenuPosH,y
			adc	r11H
			ror
			sta	r11H
			ror	r11L
			lda	DM_MenuRange+0
			clc
			adc	DM_MenuRange+1
			ror
			tay
			jmp	:3

::2			lda	DM_MenuPosL,y		;Mauszeiger auf die mitte des
			iny				;gewählten Menüpunktes setzen.
			clc
			adc	DM_MenuPosL,y
			ror				;Hier stand früher ein LSR-
							;Befehl. Maus Y-Position > 128
							;war somit nicht möglich!
			tay
			lda	DM_MenuRange+2
			clc
			adc	DM_MenuRange+4
			sta	r11L
			lda	DM_MenuRange+3
			adc	DM_MenuRange+5
			ror
			sta	r11H
			ror	r11L

;*** Menü initialisieren.
::3			sec				;Mausposition setzen.
::4			lda	mouseOn			;PullDown-Menü aktivieren.
			ora	#%01000000
			sta	mouseOn
			jmp	xStartMouseMode		;Mausabfrage starten.

;*** Menü nochmals anzeigen.
:xReDoMenu		jsr	xMouseOff		;Mauszeiger abschalten.
			jmp	DM_OpenCurMenu		;Letztes Menü aktivieren.

;*** Zurück zum Hauptmenü.
:xGotoFirstMenu		php
			sei				;IRQ sperren.

::1			lda	menuNumber		;Hauptmenü aktiv ?
			beq	:2			;Ja, Ende...
			jsr	xDoPreviousMenu		;Zum letzten Menü zurück.
			jmp	:1

::2			plp				;IRQ freigeben.
			rts

;*** Mausklick auf Menü ?
; C-Flag = 1, Maus außerhalb Menü.
; C-Flag = 0, Maus innerhalb Menü.
:DM_TestMenuPos		lda	mouseYPos
			cmp	DM_MenuRange +0
			bcc	:5
			cmp	DM_MenuRange +1
			beq	:1
			bcs	:5

::1			lda	mouseXPos    +1
			cmp	DM_MenuRange +3
			bne	:2
			lda	mouseXPos    +0
			cmp	DM_MenuRange +2
::2			bcc	:5
			lda	mouseXPos    +1
			cmp	DM_MenuRange +5
			bne	:3
			lda	mouseXPos    +0
			cmp	DM_MenuRange +4
::3			beq	:4
			bcs	:5
::4			clc				;Mausklick OK.
			rts
::5			sec				;Mausklick ungültig.
			rts

;*** Vorheriges Menü öffnen.
:xDoPreviousMenu	jsr	xMouseOff		;Maus abschalten.
			jsr	xRecoverMenu		;Aktives Menü löschen und
			dec	menuNumber		;zum letzten Menü zurück.

;*** Eingestelltes Menü öffnen (auch über ":ReDoMenu")
:DM_OpenCurMenu		jsr	DM_SetMenuData		;Neues Menü einlesen.
			clc
			jmp	DM_InitMenu		;Menü aktivieren.

;*** Zeiger auf Menüeintrag.
:DM_VecToEntry		pha
			jsr	DM_MenuVec_r0		;Zeiger auf Menüdaten einlesen.
			pla
			sta	r8L
			asl
			asl
			adc	r8L
			adc	#$07
			tay
			rts

;*** Menü-Daten einlesen.
:DM_SetMenuData		jsr	DM_ClrMseBuf
			jsr	DM_MenuVec_r0		;Zeiger auf Menüdaten einlesen.

			ldy	#$06
			lda	(r0L),y			;Menüdefinition einlesen
			sta	DM_MenuType		;merken.
			dey
::1			lda	(r0L),y			;Menügrenzen einlesen und
			sta	mouseTop,y		;zwischenspeichern.
			sta	DM_MenuRange,y
			dey
			bpl	:1

			jsr	DM_SetTextXPos		;Zeiger auf X_Position und
			lda	DM_MenuRange+0		;Zeiger auf Y_Position für
			sta	r1H			;Menütabelle setzen.
			bit	DM_MenuType
			bvs	DM_Exit1

;*** Mausbewegungsgrenzen löschen.
.SetMseFullWin		ldy	#$05
::1			lda	MaxScrnArea,y
			sta	mouseTop,y
			dey
			bpl	:1
			rts

;*** Zeiger auf Menüeintrag einrichten.
:DM_MenuVec_r0		ldy	menuNumber
			lda	DM_MenuTabL,y
			sta	r0L
			lda	DM_MenuTabH,y
			sta	r0H
:DM_Exit1		rts

;*** Alle Menüeinträge ausgeben.
:DM_PrintMenu		jsr	DM_SvFntData		;Zeichensatzdaten speichern.
			jsr	xUseSystemFont		;Systemzeichensatz aktivieren.
			lda	#$00
			sta	r10H			;Zähler für Einträge löschen.
			sta	currentMode		;Schriftstil "PLAINTEXT".
			sec				;Zeiger auf nächste Position
			jsr	DM_SetNextPos		;für Menüeintrag.

::1			jsr	DM_SvEntryPos		;Position Trennzeile merken.
			clc				;Überstand Menüeintrag setzen.
			jsr	DM_SetNextPos
			jsr	DM_PrintEntry		;Aktuellen Eintrag ausgeben.
			clc				;Überstand Menüeintrag setzen.
			jsr	DM_SetNextPos

			bit	DM_MenuType		;Menü: Vertikal/Horizontal ?
			bpl	:2			; -> Horizontal.
			lda	r1H			; -> Vertikal.
			sec				;Zeiger auf nächste Zeile für
			adc	curSetHight		;Menüeintrag berechnen.
			sta	r1H
			jsr	DM_SetTextXPos		;Zeiger auf linken Rand setzen.
			sec
			jsr	DM_SetNextPos

::2			inc	r10H			;Zeiger auf nächsten Eintrag
							;in Definitionstabelle.

			lda	DM_MenuType
			and	#%00011111
			cmp	r10H			;Alle Einträge ausgegeben ?
			bne	:1			;Nein, weiter...
			jsr	DM_LdFntData		;Zeichensatz zurücksetzen.
			jmp	DM_SvEntryPos		;Position Trennzeile merken.

;*** X-Koordinate für Textausgabe setzen.
:DM_SetTextXPos		lda	DM_MenuRange+3		;Zeiger auf linken Rand des
			sta	r11H			;Menüfensters.
			lda	DM_MenuRange+2
			sta	r11L
			rts

;*** Menüeintrag ausgeben.
:DM_PrintEntry		lda	r10L			;Zähler für Menüeinträge
			pha				;zwischenspeichern.
			lda	r10H
			pha
			jsr	DM_VecToEntry		;Zeiger auf Menüeintrag
							;berechnen.
			lda	(r0L),y			;Zeiger auf Menütext aus
			tax				;Definitionstabelle einlesen.
			iny
			lda	(r0L),y
			sta	r0H
			stx	r0L

			ldx	#$04
::1			lda	leftMargin -1,x		;Grenzen für linken und
			pha				;rechten Textrand merken.
			dex
			bne	:1

			stx	leftMargin    +0	;Grenze für linken Rand bei
			stx	leftMargin    +1	;Textausgaben löschen.

			lda	StringFaultVec+1	;Vektor für Fehlerbehandlung
			pha				;bei Bereichsüberschreitung
			lda	StringFaultVec+0	;merken.
			pha

			sec				;Grenze für rechten Rand bei
			lda	DM_MenuRange  +4	;Textausgaben auf Begrenzung
			sbc	#$01			;des Menüfensters setzen.
			sta	rightMargin   +0
			lda	DM_MenuRange  +5
			sbc	#$00
			sta	rightMargin   +1

			lda	#>DM_StopPrint		;Fehlerbehandlungsroutine
			sta	StringFaultVec+1	;installieren.
			lda	#<DM_StopPrint
			sta	StringFaultVec+0

			lda	r1H			;Aktuelle Y-Koordiante
			pha				;zwischenspeichern.
			clc				;Y-Koordinate korrigieren.
			lda	baselineOffset
			adc	r1H
			sta	r1H
			inc	r1H
			jsr	xPutString		;Menutext ausgeben.
			pla				;Aktuelle Y-Koordinate
			sta	r1H			;zurücksetzen.

			pla				;Vektor auf Fehlerbehandlung
			sta	StringFaultVec+0	;bei überschreiten des
			pla				;rechten Randes zurücksetzen.
			sta	StringFaultVec+1

			ldx	#$00
::2			pla				;Grenzen für linken und
			sta	leftMargin,x		;rechten Rand zurücksetzen.
			inx
			cpx	#$04
			bcc	:2

			pla
			sta	r10H
			pla				;Zähler für Icon-Einträge
			sta	r10L			;zurücksetzen.
			rts

;*** Fehlerroutine Menütext-Ausgabe.
:DM_StopPrint		lda	mouseRight+1
			sta	r11H
			lda	mouseRight+0
			sta	r11L
			rts

;*** Position für Trennzeile merken.
:DM_SvEntryPos		ldy	r10H
			ldx	r1H
			bit	DM_MenuType
			bmi	:1
			lda	r11H
			sta	DM_MenuPosH,y
			ldx	r11L
::1			txa
			sta	DM_MenuPosL,y
			rts

;*** Zeiger auf nächste Position für
;    Menüpunkt berechnen.
:DM_SetNextPos		bcc	DM_NextPos
			bit	DM_MenuType		;Menü: Vertikal/Horizontal ?
			bpl	DM_NextVPos		; -> Horizontal.
			bmi	DM_NextHPos

:DM_NextPos		bit	DM_MenuType
			bpl	DM_NextHPos

;*** Nächste Position (vertikal).
:DM_NextVPos		inc	r1H
			inc	r1H
			rts

;*** Nächste Position (horizontal).
:DM_NextHPos		lda	r11L
			clc
			adc	#$04
			sta	r11L
			bcc	:1
			inc	r11H
::1			rts

;*** Alle Menüs löschen.
:xRecoverAllMenus	jsr	DM_SetMenuData		;Zeiger auf aktuelles Menü.
			jsr	xRecoverMenu		;Menü zurücksetzen.
			dec	menuNumber		;Eine Menüebene zurück.
			bpl	xRecoverAllMenus	;Noch ein Menü ? ja, weiter...
			inc	menuNumber		;Menüzeiger löschen.

;*** Folgende Routine wurde eingefügt.
;    Nach dem löschen aller Menüs auch das Flag löschen, welches ein aktives
;    Menü signalisiert. Sonst wäre es theoretisch möglich auf ein unsicht-
;    bares Menü mit der Maus zu klicken!
:DM_SetMenuOff		lda	mouseOn			;Da alle Menüs vom Bildschirm
			and	#%10111111		;gelöscht wurden, auch das
			sta	mouseOn			;Flag "Menüs aktiv" löschen!
			rts

;*** Menü/Dialogbox löschen.
:xRecoverMenu		jsr	DM_SetMenuRec		;Zeiger auf aktuelles Menü.
			jsr	RecoverMenuRect

;*** Speicher für aktiven Menüeintrag löschen.
:DM_ClrMseBuf		ldx	#$06
			lda	#$00
::1			sta	DM_LastEntry,x
			dex
			bpl	:1
			rts

;*** Menürechteck wiederherstellen.
:RecoverMenuRect	lda	RecoverVector+0		;Routine zum zurücksetzen des
			ora	RecoverVector+1		;Hintergrunds installiert ?
			bne	:1			;Ja, weiter...
;			lda	#$00			;Bereich über Füllmuster #0
			jsr	SetPattern		;löschen.
			jmp	Rectangle
::1			jmp	(RecoverVector)		;Hintergrund kopieren.

;*** Trennzeile zwischen Menüeinträgen.
:DM_SetMenuLine		bit	Flag_SetMLine
			bpl	:6

			lda	DM_MenuType
			and	#%00011111
			sec
			sbc	#$01			;Anzahl Einträge = $01 ?
			beq	:5			;Ja, keine Ausgabe.
			sta	r2L			;Anzahl Trennzeilen merken.

			bit	DM_MenuType		;Vertikales Menü ?
			bmi	:2			;Nein, weiter...

			ldx	DM_MenuRange+0		;Obere Grenze für Trennlinie
			inx				;berechnen.
			stx	r3L
			ldx	DM_MenuRange+1		;Untere Grenze für Trennlinie
			dex				;berechnen.
			stx	r3H

::1			ldx	r2L			;X-Koordinate für Trennzeile
			lda	DM_MenuPosL,x		;einlesen.
			sta	r4L
			lda	DM_MenuPosH,x
			sta	r4H
			lda	#%10101010		;Linie zeichnen.
			jsr	xVerticalLine
			dec	r2L			;Alle Linien gezeichnet ?
			bne	:1			;Nein, weiter...
::6			rts

::2			jsr	DM_SetLR_Margin		;Grenze für linken und rechten
							;Rand berechnen.

::4			ldx	r2L			;Y-Koordinate für Trennzeile
			lda	DM_MenuPosL,x		;einlesen.
			sta	r11L
			lda	#%01010101		;Linie zeichnen.
			jsr	xHorizontalLine
			dec	r2L			;Alle Linien gezeichnet ?
			bne	:4			;Nein, weiter...
::5			rts

;*** Menüfenstergrenzen kopieren.
:DM_SetMenuRec		ldx	#$06
::1			lda	DM_MenuRange-1,x
			sta	r2L         -1,x
			dex
			bne	:1
:DM_NoFunc1		rts

;*** Routine ausführen, Menü öffnen.
:DM_OpenDynMenu		jsr	DM_GotoUsrAdr		;Routine ausführen.
			lda	r0L
			ora	r0H			;Menü verfügbar ?
			beq	DM_NoFunc1		; => Nein, Ende...

;*** Nächstes Menü öffnen.
:DM_OpenNxMenu		inc	menuNumber		;Zeiger auf nächstes Menü.
			jmp	DM_OpenMenu		;Menü öffnen.

;*** Menu-Eintrag ausführen.
:DM_ExecMenuJob		bit	Flag_MenuStatus
			bmi	:1
			jsr	DM_InvertCurMenu	;Aktuelles Menü invertieren.
			jmp	:2

::1			jsr	ExecViewMenu		;Gewähltes Menü invertieren.
::2			jsr	DM_ClrMseBuf		;Aktive Menügrenzen löschen.

			jsr	xMouseOff		;Maus abschalten.
			jsr	DM_EntryRange		;Gewählten Eintrag suchen.
			lda	r9L
			ldx	menuNumber		;Gewählten Menüeintrag
			sta	DM_MseOnEntry,x		;zwischenspeichern.
			jsr	DM_GetEntryInfo		;Menüeintrag-Infos einlesen.

			bit	r1L			;Funktion bestimmen.
			bmi	DM_OpenNxMenu		; -> Untermenü öffnen.
			bvs	DM_OpenDynMenu		; -> Routine + Untermenü.

:DM_ExecUsrJob		bit	Flag_MenuStatus
			bpl	:1
			jsr	DM_InvertCurMenu	;Aktuelles Menü invertieren.
::1			jsr	DoUserSleep		;Pause ausführen.
			jsr	DM_InvertCurMenu	;Aktuelles Menü invertieren.

			lda	Flag_MenuStatus
			and	#%00100000		;Doppelflash ausführen ?
			beq	DM_GotoUsrAdr		; => Nein, weiter...

			jsr	DoUserSleep		;Pause ausführen.
			jsr	DM_InvertCurMenu	;Aktuelles Menü invertieren.
			jsr	DoUserSleep		;Pause ausführen.
			jsr	DM_InvertCurMenu	;Diese Routinen dürfen wegen
			jsr	DoUserSleep		;DoUsrSleep nicht verkürzt
			jsr	DM_InvertCurMenu	;werden!!! Sonst Fehlverhalten.
			jsr	DoUserSleep
			jsr	DM_InvertCurMenu

;*** Menüdaten lesen und
;    Anwenderroutine starten.
:DM_GotoUsrAdr		ldx	menuNumber
			lda	DM_MseOnEntry,x		;Nummer des gewählten Menüs
			pha				;zwischenspeichern.
			jsr	DM_GetEntryInfo		;Grenzen für Menü einlesen.
			pla
			jmp	(r0)			;Routine aufrufen.

;*** Aktuelles Menü invertieren.
:DM_InvertCurMenu	jsr	DM_EntryRange		;Gewählten Eintrag suchen.
							;Eintrag invertieren.

;*** Bereich im Vordergrund invertieren.
:InvertMenuArea		lda	dispBufferOn
			pha
			lda	#%10000000		;Nur Vordergrund-Grafik.
			sta	dispBufferOn
			jsr	InvertRectangle		;Menü-Eintrag invertieren.
			pla
			sta	dispBufferOn
			rts

;*** Ausgewählten Menüeintrag suchen.
:DM_EntryRange		lda	DM_MenuType
			and	#%00011111
			tay
			lda	DM_MenuType		;Vertikal / Horizontal ?
			bmi	:4			; -> Vertikal.

::1			dey
			lda	mouseXPos+1		;Mauszeiger links von
			cmp	DM_MenuPosH,y		;aktuellem Menüeintrag ?
			bne	:2
			lda	mouseXPos+0
			cmp	DM_MenuPosL,y
::2			bcc	:1			;Ja, -> falscher Eintrag.

			iny				;Linke und rechte Grenze des
			lda	DM_MenuPosL,y		;aktuellen Menüeintrages
			sta	r4L			;berechnen.
			lda	DM_MenuPosH,y
			sta	r4H

			dey
			lda	DM_MenuPosL,y
			sta	r3L
			lda	DM_MenuPosH,y
			sta	r3H

			sty	r9L
			cpy	#$00
			bne	:3
			jsr	SetNxByte_r3

::3			ldx	DM_MenuRange+0		;Obere und untere Grenze für
			inx				;aktuellen Menüeintrag
			stx	r2L			;berechnen.
			ldx	DM_MenuRange+1
			dex
			stx	r2H
			rts

::4			lda	mouseYPos
::5			dey
			cmp	DM_MenuPosL,y		;Mauszeiger über Trennlinie ?
			bcc	:5			;Nein, weiter...

			iny
			lda	DM_MenuPosL,y		;Untere und obere Grenze für
			sta	r2H			;aktuellen Menüeintrag
			dey				;berechnen.
			lda	DM_MenuPosL,y
			sta	r2L
			sty	r9L
			cpy	#$00
			bne	DM_SetLR_Margin
			inc	r2L

;*** Grenze für linken/rechten Rand setzen.
:DM_SetLR_Margin	ldx	#$02
::1			lda	DM_MenuRange+3,x	;Linke und rechte Grenze für
			sta	r3H           ,x	;aktuellen Menüeintrag
			lda	DM_MenuRange+2,x	;berechnen.
			sta	r3L           ,x
			dex
			dex
			bpl	:1

			jsr	SetNxByte_r3
			ldx	#r4L
			jmp	Ddec

;*** Menüeintrag-Information einlesen.
:DM_GetEntryInfo	jsr	DM_VecToEntry
			iny
			iny
			lda	(r0L),y			;Anzahl Menü-Einträge.
			sta	r1L
			iny
			lda	(r0L),y			;Zeiger auf Menü-Routine.
			tax
			iny
			lda	(r0L),y
			sta	r0H
			stx	r0L
			rts

;*** Zeichensatzdaten zwischenspeichern.
:DM_SvFntData		ldx	#$09
::1			lda	baselineOffset-1,x
			sta	saveFontTab   -1,x
			dex
			bne	:1
			rts

;*** Zeichensatzdaten zurückschreiben.
:DM_LdFntData		ldx	#$09
::1			lda	saveFontTab   -1,x
			sta	baselineOffset-1,x
			dex
			bne	:1
			rts

;*** Pause für Menüauswahl.
:DoMenuSleep		lda	selectionFlash		;Zähler für Menu-Blinken
			b $2c				;setzen.

;*** Pause für Funktionsauswahl.
:DoUserSleep		lda	#$03			;Für Menü-Funktionen wird
			sta	r0L			;ein kurzes "Blinken" erzeugt.
			lda	#$00
			sta	r0H
			jmp	xSleep			;Pause ausführen.

;*** Aktuelles Menü Testen.
:ExecViewMenu		bit	Flag_MenuStatus
			bpl	:4

			php
			sei

			bit	mouseOn			;Maus / Menüs aktiv ?
			bvc	:3			; => Keine Menüs, Ende...
			bpl	:1			; => Keine Maus, Menü löschen.

			jsr	DM_TestMenuPos		;Maus auf aktuellem Menü ?
			bcc	:5			;Ja, weiter...

::1			lda	DM_LastEntry +1
			beq	:3

			ldx	#$05
::2			lda	DM_LastEntry,x		;Maus noch auf aktuellem
			sta	r2L,x			;(invertierten) Eintrag ?
			dex
			bpl	:2
			jsr	InvertMenuArea		;Aktuellen Eintrag invertieren.
			jsr	DM_ClrMseBuf
::3			plp
::4			rts

::5			jsr	DM_EntryRange		;Aktuellen Eintrag bestimmen.

			lda	menuNumber
			cmp	DM_LastNumEntry		;Maus auf neuem Menü ?
			beq	:6			;Nein, weiter...

			sta	DM_LastNumEntry		;Neues Menü merken und
			bne	:8			;aktuellen Eintrag invertieren.

::6			ldx	#$05
::7			lda	r2L,x			;Maus noch auf aktuellem
			cmp	DM_LastEntry,x		;(invertierten) Eintrag ?
			bne	:8			; => Neuen Eintrag invertieren.
			dex
			bpl	:7
			bmi	:a			; => Mausposition unverändert.

::8			jsr	InvertMenuArea		;Aktuellen Eintrag invertieren.

			ldx	#$05			;Grenzen des aktuellen Menü-
::9			lda	r2L,x			;Eintrages merken und Grenzen
			pha				;des letzten Menü-Eintrages
			lda	DM_LastEntry,x		;einlesen.
			sta	r2L,x
			pla
			sta	DM_LastEntry,x
			dex
			bpl	:9

			lda	r2H			;<*> Änderung: Ist Invert-
			beq	:a			;Rechteck definiert ? => Nein.
			jsr	InvertMenuArea		;Letzten Eintrag invertieren.
::a			plp
			rts
