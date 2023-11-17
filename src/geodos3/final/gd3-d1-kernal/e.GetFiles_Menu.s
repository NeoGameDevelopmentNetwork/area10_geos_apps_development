; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_FBOX"
endif

;*** GEOS-Header.
			n "obj.GetFilesMenu"
			t "G3_Data.V.Class"

			o LD_ADDR_GFILMENU

;*** Einsprungtabelle.
:xGetFiles_Init		jmp	yGetFiles_Init		;Bildschirm speichern/Menü zeichnen.
:xGetFiles_Menu		jmp	yGetFiles_Menu		;Menü und Icons ausgeben.
:xGetFiles_Box		jmp	yGetFiles_Box		;Menü zeichnen.
:xDlgBoxIcons		jmp	yDlgBoxIcons

;*** Bildschirm speichern und Menü/Icons ausgeben.
:yGetFiles_Init		PushW	DB_VecDefTab
			PushB	Flag_DBoxType		;Dialogbox-Kennbyte einlesen und

			lda	#%01000001		;Farbe für alle Icons setzen.
			sta	Flag_DBoxType		;Wichtig für Icons deren Größe
							;unterhalb der min. Größe für Farbe
							;liegt (sh. GeoFAX V1.6! bei der
							;Dateiauswahlbox!)

			lda	#< DB_FBoxData		;Zeiger auf Tabelle für Größe
			sta	DB_VecDefTab  +0	;des GetFiles-Fensters und
			lda	#> DB_FBoxData		;Bildschirminhalt zwischenspeichern.
			sta	DB_VecDefTab  +1
			jsr	DB_SaveScreen

			PopB	Flag_DBoxType		;Register zurücksetzen.
			PopW	DB_VecDefTab

			ldx	#11			;Einsprungadressen für weitere
::51			lda	ExitRoutTab,x		;Routinen auf Stack speichern.
			pha
			dex
			bpl	:51

;*** Icon-Menü ausgeben.
:yGetFiles_Menu		jsr	DrawGetFileIcon

;--- Ergänzung: 02.10.21/M.Kanet
;Icons müssen über den Kernal auf dem
;Bildschirm ausgegeben werden, da z.B.
;GateWay das Icon bei Dateiinfo über
;den Infoblock ausgibt und der Bereich
;durch ":GetFiles_Menu" belegt ist.
:Exit_DrawIcons		lda	#> (DB_DrawIcons -1)
			pha
			lda	#< (DB_DrawIcons -1)
			pha

:Exit_DrawMenu		jsr	SetADDR_GFilMenu
			jmp	SwapRAM

;*** Routinen die noch ausgeführt werden müssen, nachdem diese Routine
;    wieder aus dem Speicher entfernt wurde. Daher müssen die Adressen der
;    Routinen auf den Stack gelegt werden.
:ExitRoutTab		w SetADDR_GFilData -1
			w SwapRAM          -1
			w LD_ADDR_GFILDATA -1
			w SetADDR_GetFiles -1
			w SwapRAM          -1
			w LD_ADDR_GETFILES -1

;*** GetFiles-Menü zeichnen (ohne Icons).
:yGetFiles_Box		jsr	DB_DrawBox		;Dialogbox zeichnen.
			jmp	Exit_DrawMenu

;*** Standard-Dialogbox-Icons zeichnen.
:yDlgBoxIcons		lda	DB_SetDrvIcons		;Laufwerk-Icons zeichnen ?
			beq	:51			; => Nein, weiter...
			jsr	DrvIcon_XYpos		;Laufwerk-Icons in Tabelle kopieren.

::51			lda	DB_Icon_Tab		;Icons definiert ?
			beq	:52			; => Nein, weiter...
			jsr	DoDlgBoxIcons		;Icons ausgeben.

::52			jmp	Exit_DrawIcons		;Zurück zum Kernal.

;*** Icons für GetFile-Menu ausgeben.
:DrawGetFileIcon	PushB	Flag_DBoxType		;Dialogbox-Kennbyte einlesen und

			lda	#%01000001		;Farbe für alle Icons setzen.
			sta	Flag_DBoxType		;Wichtig für Icons deren Größe
							;unterhalb der min. Größe für Farbe
							;liegt (sh. GeoFAX V1.6! bei der
							;Dateiauswahlbox!)

			jsr	DefIconData		;Icons positionieren.

			jsr	DB_DrawBox		;Dialogbox zeichnen.
			jsr	DoDlgBoxIcons		;Icons ausgeben.

			PopB	Flag_DBoxType
			rts

;*** Icons zeichnen und Icon-Farbe setzen wenn Flags gesetzt.
:DoDlgBoxIcons		lda	DB_Icon_Tab
			beq	:50

			bit	Flag_GetFiles
			bmi	:51
			bit	Flag_ColorDBox		; Box-Farbe unterdrücken ?
			bpl	:51
::50			rts				; -> Ja, weiter...

::51			lda	#>DB_Icon_Tab +4	;Zeiger auf Icon-Tabelle.
			sta	r0H
			lda	#<DB_Icon_Tab +4
			sta	r0L

			ldx	#$00			;Icon-Zähler löschen und auf
			beq	:57			;Icons in Tabelle testen.

::52			stx	r1L			;Zähler zwischenspeichern.

			ldy	#$05
::53			lda	(r0L),y			;Icon-Daten einlesen.
			sta	r4   ,y
			dey
			bpl	:53

;			lda	r4L			;Testen ob Bitmap = $0000.
			ora	r4H			;Notwendig, da einige Programme
			beq	:55			;Standard-Dialogboxen nutzen,
							;in denen nicht benötigte Icons
							;mit einem Bitmap-Zeiger $0000
							;definiert werden.

			bit	Flag_DBoxType		;Farb-Flag gesetzt ?
			bvs	:54			;Ja, weiter...

			lda	r5H			;Ist Y-Koordinate innerhalb
			and	#%00000111		;eines 8-Byte-Blocks ?
			bne	:55			;Nein, keine Farbe setzen.

			lda	r4H			;Systemicon ?
			bmi	:54			; => Ja, weiter...

			lda	r6L			;Prüfen ob Breite des Icons
			cmp	Flag_IconMinX		;dem Mindestwert für Icons mit
			bcc	:55 			;Farbe entspricht.
			lda	r6H			;Prüfen ob Höhe des Icons
			cmp	Flag_IconMinY		;dem Mindestwert für Icons mit
			bcc	:55			;Farbe entspricht.

::54			lda	r6H			;Ist Höhe des Icons innerhalb
			and	#%00000111		;eines 8-Byte-Blocks ?
			bne	:55			;Nein, keine Farbe setzen.

			ldy	#$03
::54a			lsr	r5H			;Y-Koordinate und Höhe des
			lsr	r6H			;Icons in CARDs umrechnen.
			dey
			bne	:54a

;			ldx	r1L			;Zeiger auf Icon.
			lda	DB_IconColor,x		;Icon-Farbe einlesen.
			sta	r7L			;Farbe für Dialogbox.
			jsr	RecColorBox		;Farbe zeichnen.

::55			lda	#$08			;Zeiger auf nächstes Icon.
			clc
			adc	r0L
			sta	r0L
			bcc	:56
			inc	r0H

::56			ldx	r1L			;Icon-Zähler einlesen und
			inx				;auf nächstes Icon setzen.
::57			cpx	DB_Icon_Tab		;Alle Icon-Farben ausgegeben ?
			bne	:52			;Weiter mit Farbe ausgeben.
			rts				;Ende...

;*** Dialogbox-Icons positionieren.
;    Es stehen drei Zeilen für Icons zur Verfügung. Die Zeile #0 am unteren
;    Rand der Auswahlbox ist für System-Icons reserviert. Ist die Zeile nicht
;    komplett gefüllt, werden weitere Icons mit einer Größe von 48x16 Pixel
;    in die Zeile mit aufgenommen.
;    Weitere Icons oder Icons die eine andere Größe als 48x16 Pixel haben
;    werden in Zeile #1 positioniert. Ist Zeile #1 gefüllt, werden weitere
;    Icons in Zeile #2 positioniert. Diese ist gegenüber Zeile #1 und jeweils
;    8 Pixel nach rechts/unten versetzt.
:DefIconData		bit	DB_GetFilesOpt		;Laufwerkicons anzeigen ?
			bvc	DefUsrIconData		; => Nein, weiter...
			jsr	DrvIcon_XYpos

;*** Icons neu positionieren.
:DefUsrIconData		ldx	#$00			;Tabelle mit Flags für
			txa				;"Icon ist neu positioniert"
::51			cpx	DB_Icon_Tab		;löschen.
			beq	:52
			sta	r10L,x
			inx
			bne	:51

::52			lda	#%10000000		;Flag setzen:
			sta	r1H			;"Icon-Position initialisieren".

			jsr	DB_IconXY_CANCEL	;Position für System-Icons
			jsr	DB_IconXY_OK		;festlegen. Die icons erscheinen
			jsr	DB_IconXY_NO		;dabei in dieser Reihenfolge im
			jsr	DB_IconXY_YES		;unteren Bereich der Auswahlbox.
			jsr	DB_IconXY_OPEN		;Ist der bereich voll, wird der
			jsr	DB_IconXY_DISK		;Bereich für Anwender-Icons
							;mitverwendet.

			lda	#< DB_SetIconPos1	;Alle Icons mit einer Größe von
			ldx	#> DB_SetIconPos1	;48x16 Pixel positionieren (ist =
			jsr	DB_TestUsrIcons		;(Größe der System-Icons...)

			lda	r1H			;Zeiger auf Icon-Zeile einlesen.
			beq	:53			; => Zeiger auf Zeile #1 setzen.
			bpl	:54			; => Zeiger nicht mehr in Zeile #0.
::53			lda	#%11000000		;Icons für Zeile #1 und #2 neu
			sta	r1H			;positionieren (Anwender-Icons).

::54			lda	#< DB_SetIconPos2	;Restliche Icons positionieren.
			ldx	#> DB_SetIconPos2

;*** Position/Größe für Anwender-Icons definieren.
;    Übergabe:		AKKU/xReg = Zeiger auf Test-Routine.
:DB_TestUsrIcons	sta	:52 +1			;Zeiger auf Testroutine
			stx	:52 +2			;zwischenspeichern.

			ldy	#$00
::51			cpy	DB_Icon_Tab		;Alle Icons positioniert ?
			beq	:54			; => Ja, Ende...
			lda	r10L,y			;Aktuelles Icon positioniert ?
			bne	:53			; => Ja, weiter...

			tya
			asl
			asl
			asl
			tax
			lda	DB_Icon_Tab +4,x
			ora	DB_Icon_Tab +5,x	;Ist Icon definiert ?
			beq	:53			; => Nein, weiter...

			tya
			pha
::52			jsr	$ffff			;Icon positionieren.
			pla
			tay
::53			iny				;Zeiger auf nächstes Icon und
			bne	:51			;weitertesten.
::54			rts

;*** Laufwerk-Icons in Tabelle übertragen.
:DrvIcon_XYpos		ldy	#$00
::51			ldx	DB_Icon_Tab		;Anzahl vorhandener Icons einlesen.
			cpx	#$08			;Icon-Tabelle voll ?
			beq	:53			; => Ja, Ende...

			lda	driveType,y		;Laufwerk verfügbar ?
			beq	:52			; => Nein, weiter...

			lda	C_DBoxDIcon		;Vorgabe für Icon-Farbe und
			sta	DB_IconColor,x		;Icon-Farbe festlegen.

			tya				;Zeiger auf Icon-Eintrag
			pha				;berechnen.
			asl
			asl
			asl
			clc
			adc	#< DrvIconTab
			sta	r5L
			lda	#$00
			adc	#> DrvIconTab
			sta	r5H

			lda	DB_SetDrvXYpos +0
			sta	r3L
			lda	DB_SetDrvXYpos +1
			sta	r2L
			inc	DB_SetDrvXYpos +0
			inc	DB_SetDrvXYpos +0

			jsr	DB_CopyIconInTab	;Icon in Tabelle kopieren (Kernal).

			pla
			tay
::52			iny
			cpy	#$04			;Alle Icons kopiert ?
			bcc	:51			; => Nein, weiter...
::53			rts

;*** "OK"		-Icon suchen und Position setzen.
:DB_IconXY_OK		lda	#< Icon_OK
			ldx	#> Icon_OK
			bne	DB_FindIcon

;*** "CANCEL"		-Icon suchen und Position setzen.
:DB_IconXY_CANCEL	lda	#< Icon_CANCEL
			ldx	#> Icon_CANCEL
			bne	DB_FindIcon

;*** "YES"		-Icon suchen und Position setzen.
:DB_IconXY_YES		lda	#< Icon_YES
			ldx	#> Icon_YES
			bne	DB_FindIcon

;*** "NO"		-Icon suchen und Position setzen.
:DB_IconXY_NO		lda	#< Icon_NO
			ldx	#> Icon_NO
			bne	DB_FindIcon

;*** "OPEN"		-Icon suchen und Position setzen.
:DB_IconXY_OPEN		lda	#< Icon_OPEN
			ldx	#> Icon_OPEN
			bne	DB_FindIcon

;*** "DISK"		-Icon suchen und Position setzen.
:DB_IconXY_DISK		lda	#< Icon_DISK
			ldx	#> Icon_DISK

;*** System-Icon in Tabelle suchen und Position setzen.
:DB_FindIcon		jsr	DB_IsIconInTab
			cpx	#$00
			bne	:51
			jmp	DB_SetIconPos2
::51			rts

;*** Befindet sich Icon in Tabelle ?
:DB_IsIconInTab		sta	:52 +1			;Zeiger auf Icon-Bitmap speichern.
			stx	:53 +1

			ldy	#$00
::51			cpy	DB_Icon_Tab		;Alle Icons geprüft ?
			beq	:56			; => Ja, Ende...
			jsr	DB_GetIconAdr		;Bitmap-Adresse einlesen und
::52			cmp	#$ff			;mit Adresse für System-Icon
			bne	:54			;vergleichen.
::53			cpx	#$ff			;Wenn System-Icon gefunden, dann
			beq	:55			;Icon positionieren.
::54			iny				;Zeiger auf nächstes Icon und
			bne	:51			;weitertesten.
::55			ldx	#$00
			b $2c
::56			ldx	#$05
			rts

;*** Zeiger auf Bitmap aus Icon-Tabelle einlesen.
:DB_GetIconAdr		sty	:51 +1
			tya
			asl
			asl
			asl
			tay
			lda	DB_Icon_Tab + 4,y
			ldx	DB_Icon_Tab + 5,y
::51			ldy	#$ff
			rts

;*** Position/Größe für Anwender-Icons definieren.
;    Hier: Icons mit fester Größe von 48x16 Pixel.
;    Übergabe:		yReg = Zeiger auf Icon-Nr
:DB_SetIconPos1		tya				;Zeiger auf Daten für aktuelles
			asl				;Icon in Icon-Tabelle berechnen.
			asl
			asl
			tax
			lda	DB_Icon_Tab + 8,x	;Icon-Größe auf 48x16 testen.
			cmp	#$06
			bne	:51
			lda	DB_Icon_Tab + 9,x
			cmp	#$10
			beq	DB_SetIconPos2		;Icon-Größe OK => positionieren.
::51			rts

;*** Position/Größe für Anwender-Icons definieren.
;    Hier: Icons jeder Größe.
;    Übergabe:		yReg = Zeiger auf Icon-Nr
:DB_SetIconPos2		lda	#$ff			;Flag setzen:
			sta	r10L,y			;"Icon ist neu positioniert"

			tya				;Zeiger auf Icon-Nr. auf Stack
			pha				;retten und Zeiger auf Daten für
			asl				;Icon in Tabelle berechnen.
			asl
			asl
			tay

			bit	r1H			;Icon-Positionen setzen ?
			bpl	:51			; => Bereits gesetzt, weiter...
			bvs	:52			; => Position für Zeile #1 setzen.

;*** Hier: Zeiger auf Position für System-Icons + Icons mit 48x16 Pixel.
			lda	#(X_DBox + B_DBox)/8 - 1
			sta	r0L
			lda	#(Y_DBox + H_DBox    -24)
			sta	r0H

			lda	#(X_DBox + B_DBox)/8 - 1 - 4*6
			sta	r1L
			lda	#$00
			sta	r1H

::51			lda	r1H			;Icons in Zeile #0 ?
			bne	:54			; => Nein, weiter...

			lda	r0L
			sec
			sbc	DB_Icon_Tab + 8,y
			cmp	r1L			;Noch Platz für icon in Zeile #0 ?
			bcc	:53			; => Nein, weiter in Zeile #1...
			sta	r0L			;X/Y-Koordinate festlegen.
			sta	DB_Icon_Tab + 6,y
			lda	r0H
			sta	DB_Icon_Tab + 7,y
			pla
			tay
			rts

;*** Hier: Zeiger auf Position für alle restlichen Icons.
::52			lda	#$00
			sta	r1H

::53			lda	#X_DBox/8 + 1		;Position für Icons in Zeile #1 und
			clc				;Zeile #2 berechnen.
			adc	r1H
			sta	r0L			;r0L = X-Koordinate in Cards

			lda	r1H
			asl
			asl
			asl
			clc
			adc	# Y_DBox + H_DBox    -24 -40
			sta	r0H			;r0H = Y-Koordinate

			lda	#(X_DBox + B_DBox)/8 - 1
			clc
			adc	r1H
			sta	r1L
			inc	r1H			;Zeiger auf Zeile korrigieren.

::54			lda	r0L			;X/Y-Koordinate festlegen.
			sta	DB_Icon_Tab + 6,y
			lda	r0H
			sta	DB_Icon_Tab + 7,y

			lda	DB_Icon_Tab + 9,y	;Größe der Icons auf 24 Pixel
			cmp	#$18 +1			;in der Höhe begrenzen.
			bcc	:55
			lda	#$18
			sta	DB_Icon_Tab + 9,y

::55			lda	r0L
			clc
			adc	DB_Icon_Tab + 8,y	;Überschreitet Icon mit Breite den
			cmp	r1L			;rechten Rand ?
			bcs	:53			; => Ja, Icon in nächste Zeile
			sta	r0L			;    verschieben.

			pla
			tay
			rts

;*** Dialogbox zeichnen.
:DB_DrawBox		jsr	UseSystemFont
			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	#$00			;Füllmuster für Schatten und
			jsr	SetPattern		;Hintergrund der Dialogbox.
			jsr	i_Rectangle
			b	Y_DBox+ 8,Y_DBox + H_DBox + 7
			w	(X_DBox+ 8)
			w	(X_DBox + B_DBox + 7)
			lda	C_WinShadow		;Farbe immer zuerst setzen!
			jsr	DirectColor

			jsr	i_Rectangle
			b	Y_DBox,Y_DBox + H_DBox - 1
			w	X_DBox
			w	(X_DBox + B_DBox - 1)
			lda	C_FBoxBack
			jsr	DirectColor
			lda	#%11111111
			jsr	FrameRectangle

			jsr	i_Rectangle
			b	Y_DBox,Y_DBox + 7
			w	X_DBox
			w	(X_DBox + B_DBox - 1)
			lda	C_FBoxTitel
			jsr	DirectColor

			jsr	i_Rectangle		;Anzeige-Bereich löschen.
			b	Y_FWin,Y_FWin + H_FWin - 1
			w	X_FWin
			w	(X_FWin + B_FWin - 1)
			lda	C_FBoxFiles
			jsr	DirectColor		;Farbe setzen.

			dec	r2L
			inc	r2H
			SubVW	1,r3
			AddVW	1,r4
			lda	#%11111111		;Rahmen um Anzeige-Bereich
			jsr	FrameRectangle		;darstellen.

			LoadW	r3,(X_DBox + 8)
			LoadW	r4,(X_DBox + B_DBox - 8)

			lda	#Y_DBox + H_DBox -28
			sta	r11L
			lda	#%11111111
			jsr	HorizontalLine

			lda	#Y_DBox + H_DBox -28
			sec
			sbc	#$28
			sta	r11L
			lda	#%11111111
			jsr	HorizontalLine

			LoadW	r0,WaitInfo
			jmp	PutString

;*** Texte.
if Sprache = Deutsch
:WaitInfo		b GOTOXY
			w (X_FWin +$08)
			b Y_FWin +$17
			b PLAINTEXT,BOLDON
			b "Bitte warten..."
			b PLAINTEXT
			b NULL
endif

if Sprache = Englisch
:WaitInfo		b GOTOXY
			w (X_FWin +$08)
			b Y_FWin +$17
			b PLAINTEXT,BOLDON
			b "Please wait..."
			b PLAINTEXT
			b NULL
endif

;*** Eintrag für Laufwerk-Icons.
:DrvIconTab		w Icon_DRIVE_A
			b $00,$00,$02,$10
			w DB_Icon_DrvA

			w Icon_DRIVE_B
			b $00,$00,$02,$10
			w DB_Icon_DrvB

			w Icon_DRIVE_C
			b $00,$00,$02,$10
			w DB_Icon_DrvC

			w Icon_DRIVE_D
			b $00,$00,$02,$10
			w DB_Icon_DrvD

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_GFILMENU + R2_SIZE_GFILMENU -1
;******************************************************************************
