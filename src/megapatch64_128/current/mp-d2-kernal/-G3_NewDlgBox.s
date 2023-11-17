; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Dialogbox erzeugen.
;******************************************************************************
; Kopfbyte:		%1xxxxxxx = Standard-Dialogbox.
;			%x1xxxxxx = Header-Daten um Farb-Angabe ergänzt.
;			            Nicht bei Standard-Box!
;			            Bsp.: b yo,yu
;			                  w xl,xr
;			                  b color
;				     Außerdem muß der Icon-Befehl um den Farbwert
;				     für das Icon ergänzt werden!
;				     Bsp.: b DBUSRICON  ,$01,$02,farbe
;				           w IconTab1
;				           b OK         ,$02,$02,farbe
;				           b DISK       ,$04,$09,farbe
;			%xx1xxxxx = Keine Box-Farben setzen.
;
;Flag_SetColor hat höchste Priorität!
;******************************************************************************

;*** Dialogbox erzeugen.
:xDoDlgBox		lda	r0H			;Zeiger auf Dialogboxtabelle
			sta	DB_VecDefTab+1		;zwischenspeichern.
			lda	r0L
			sta	DB_VecDefTab+0

			ldy	#$00			;Icon-Tabelle löschen.
			sty	DB_Icon_Tab +0
			sty	DB_Icon_Tab +1
			sty	DB_Icon_Tab +2

			sty	DB_SetDrvIcons		;Keine Laufwerk-Icons anzeigen.

			lda	(DB_VecDefTab),y	;Dialogbox-Kopfbyte einlesen
			sta	Flag_DBoxType		;und zwischenspeichern.
			and	#%01100000
			cmp	#%01100000		;Bit #6 und #5 gesetzt ?
			bne	:mp3box			; => Nein, weiter...

			lda	Flag_DBoxType		;Bit #6 und Bit #5 löschen, da
			and	#%10011111		;Farbe gesetzt werden soll und
			sta	Flag_DBoxType		;gleichzeitig Farbe unterdrückt
			jmp	:2			;werden soll => Standard...

::mp3box		asl				;MP3-Dialogbox in Farbe ?
			bmi	:2			; => Ja, Farbe setzen.
			asl				;MP3-Dialogbox ohne Farbe ?
			bmi	:3			; => Ja, Farbe nicht setzen.

;--- GEOS-V2_Dialogbox.
			bit	Flag_SetColor		;Farbe setzen ?
			bmi	:2			; => Immer setzen, weiter...
			bvc	:1			; => Nur bei Standard-DlgBox.
			bit	Flag_DBoxType		;Standard-Dialogbox ?
			bmi	:2			; => Ja, Farbe setzen.
::1			lda	#%10000000		;Bit #7 setzen, wenn Farbe
			b $2c				;nicht gesetzt werden soll.
::2			lda	#%00000000
::3			sta	Flag_ColorDBox

;*** Auf GetFile-Funktion testen.
:DB_TestGetFiles	jsr	DB_SetVec1stCode	;Zeiger auf letztes Headerbyte.
::1			iny
::2			tya				;Zeiger auf nächsten Dialogbox-
			jsr	Add_A_r0		;code berechnen.

::3			ldy	#$00
			lda	(r0L),y			;Dialogbox-Code einlesen
			beq	:4			;$00 ? Ja, Ende...

;--- Auf DBUSRFILES testen.
;Dies muß vor dem and-Befehl geschehen,
;da GetFile-Optionen nicht für diesen
;JobCode gelten!
;--- Ergänzung: 13.01.2019/M.Kanet
;DBSETDRVICON kann mit DBUSRFILES
;kombiniert werden.
			and	#%10111111		;DBSETDRVICON-Flag löschen
			cmp	#DBUSRFILES		; => DBUSRFILES ?
			beq	:5			; Ja, weiter...

			and	#%00111111		;GetFiles-Bits löschen.
			cmp	#DBGETFILES		; => DBGETFILES ?
			beq	:5			; Ja, weiter...

			tax
			ldy	CodeLenTab -1,x

			bit	Flag_DBoxType		;Farbe in Box gesetzt ?
			bvc	:2			; => Nein, weiter...
			cpx	#DBUSRICON		;Bei allen Icons-Codes ein
			beq	:1			;zusätzliches Byte addieren.
			cpx	#DISK +1		;Damit wird der Farbcode
			bcc	:1			;in der Tabelle überlesen.
			bcs	:2

::4			jsr	DB_SaveScreen		;Bildschirm in REU
							;zwischenspeichern.

			lda	#%00000000		;Bit 6+7=0: Keine Auswahlbox.
			b $2c
::5			lda	#%10000000		;Bit 7=1: Dateiauswahlbox.
			sta	Flag_GetFiles

;*** Dialogbox-Funktionen ausführen.
:StdDlgBox		lda	Flag_ExtRAMinUse	;Hintergrundspeicher für
			ora	#%01000000		;Dialogbox sperren.
			sta	Flag_ExtRAMinUse

			ldx	#0
::1			lda	r5L,x			;Register r5 bis r10
			pha				;zwischenspeichern.
			inx
			cpx	#6*2
			bcc	:1

if Flag64_128 = TRUE_C128
			jsr	TempHideMouse		;80Z-Modis Mauspfeil entfernen
endif
			jsr	SaveGEOS_Data		;Dialogbox initialisieren.

			jsr	DB_DrawBox		;Dialogbox zeichnen.

			lda	r2L			;Größe der Dialogbox (Y)
			sta	DBoxSize +0		;zwischenspeichern.
			lda	r2H
			sta	DBoxSize +1

			lda	#$00
			sta	r11L
			sta	r11H
			jsr	StartMouseMode		;Mauszeiger aktivieren.

			jsr	UseSystemFont		;Systemzeichensatz starten.

			ldx	#6*2 -1
::2			pla	 			;Register r5 bis r10
			sta	r5L,x			;zurücksetzen.
			dex
			bpl	:2

			jsr	DB_SetVec1stCode	;Zeiger auf letztes Headerbyte.
::3			iny

::4			lda	(DB_VecDefTab),y	;Dialogbox-Code einlesen.
			beq	StartDB_Box		; = $00 ? => Ja, Ende...
			sta	r0L

			ldx	#0
::5			lda	r5L,x			;Register r5 bis r10
			pha				;zwischenspeichern.
			inx
			cpx	#6*2
			bcc	:5

			iny				;Zeiger auf Dialogbox-Tabelle
			sty	r1L			;zwischenspeichern.

			lda	r0L			;Dialogbox-Code einlesen.
			and	#%00111111		;GetFiles-Bits löschen.
			tay
			lda	DB_BoxCTabL -1,y	;Routine zum DlgBox-Code
			ldx	DB_BoxCTabH -1,y	;aufrufen.
			jsr	CallRoutine

			ldy	r1L			;Zeiger auf Dialogboxtabelle.

			ldx	#6*2 -1
::6			pla	 			;Register r5 bis r10
			sta	r5L,x			;zurücksetzen.
			dex
			bpl	:6
			bmi	:4			;Tabelle weiter auswerten.

;*** Zeiger auf erstes Befehlsbyte setzen.
:DB_SetVec1stCode	ldy	#$00			;Zeiger auf erstes Datenbyte.
			bit	Flag_DBoxType		;Dialogbox-Code einlesen
			bmi	:1
			ldy	#$06
			bvc	:1
			iny
::1			rts

;*** Dialogbox definiert -> starten.
:StartDB_Box		bit	Flag_GetFiles		;GetFiles aufrufen ?
			bpl	:1			;Nein, weiter...
			jsr	DB_NewGetFiles		;Dateiauswahlbox starten.
			jmp	:3

::1			bit	DB_SetDrvIcons
			bmi	:2
			lda	DB_Icon_Tab		;Icons in Dialogbox ?
			beq	:3			;Nein, weiter...
::2			jsr	DB_InitIcons		;Icons initialisieren.

::3			pla
			sta	DB_ReturnAdr+0		;LOW -Byte Rücksprungadresse.
			pla
			sta	DB_ReturnAdr+1		;HIGH-Byte Rücksprungadresse.
			tsx
			stx	DB_RetStackP		;Stackzeiger merken.

			ldx	#%00000000		;":appMain" auf Routine
			lda	appMain +0		;":RstrFrmDialogue" testen.
			cmp	#< RstrFrmDialogue	;Ist dies der Fall, dann soll
			bne	:4			;die Dialogbox gleich wieder
			lda	appMain +1		;gelöscht werden. Im Falle
			cmp	#> RstrFrmDialogue	;von GeoFile müssen aber die
			bne	:4			;Icons erhalten bleiben!!!
			ldx	#%10000000
::4			stx	DB_ResetGrafx		;Dialogbox am Ende löschen.

			jmp	MainLoop		;Zur Mainloop.

;*** Dialogbox-Bildschirm zwischenspeichern.
.DB_SaveScreen		jsr	SetADDR_DB_SCRN		;Bildschirm in REU
			jsr	SwapRAM			;zwischenspeichern.
			jmp	DB_SCREEN_SAVE

;*** Dialogbox-Icons darstellen.
:DB_InitIcons		jsr	SetADDR_GFilMenu	;Auswahlbox darstellen und
			jsr	SwapRAM			;Icons initialisieren.
			jmp	LD_ADDR_DBOXICON

;*** Dialogbox zeichen.
:DB_DrawBox		lda	#%10100000
			sta	dispBufferOn		;Nur im Vordergrund zeichen.

;--- Ergänzung: 19.11.22/M.Kanet
;Die Dialogbox verwendet DOUBLE_W um
;die X-Koordinaten am C128 an den 80Z-
;Bildschirm anzupassen. Das setzen von
;DB_DblBit geschieht normalerweise in
;DB_DrawBox durch das auswerten der
;X-Koordinate. Für GetFiles wurde der
;Wert bisher aber nicht gesetzt und
;bei gelöschtem DB_DblBit werden die
;Systemicons nur mit halber Breite
;gezeichnet. Bisher wurden auch die
;Icon-Angaben direkt im Kernal durch
;das setzen von Bit%7 geändert, daher
;trat dieser Fehler nur in sehr selten
;Fällen auf.
			bit	Flag_GetFiles		;GetFiles aktiv ?
			bmi	:5			;Ja, übergehen.

			lda	Flag_DBoxType		;Definitionsbyte einlesen.
			and	#%00011111		;Schatten zeichnen ?
			beq	:2			;Nein, weiter...
			jsr	SetPattern		;Füllmuster für Schatten.
			sec				;Position für Schatten
			jsr	DB_TestUpsize		;berechnen.

			lda	C_WinShadow		;Farbe für Schatten setzen.
			jsr	:3			;(Nur wenn erwünscht!)
			bit	Flag_ColorDBox		;Wurde Box-Farbe gesetzt ?
			bpl	:2			;-> Ja, weiter...

::1			jsr	Rectangle		;Schatten zeichnen, nur wenn
							;S/W-Schatten verwendet wird!

::2			lda	#$00			;Füllmuster für Dialogbox.
			jsr	SetPattern
			clc				;Position für Dialogbox
			jsr	DB_TestUpsize		;berechnen.

			jsr	Rectangle		;Dialogbox zeichnen.

			lda	r4H			;Grenze für Textausgaben
			sta	rightMargin+1		;definieren.
			lda	r4L
			sta	rightMargin+0

;			clc				;Position für Dialogbox
;			jsr	DB_TestUpsize		;berechnen.
			lda	#$ff			;Rahmen um Dialogbox
			jsr	FrameRectangle		;zeichnen.

			lda	DB_CurColor		;Farbe für Dialogbox.

;*** Farbe für Dialogbox/Schatten setzen.
::3			bit	Flag_ColorDBox		; Box-Farbe unterdrücken ?
			bmi	:4			; -> Nein, weiter...
			jsr	DirectColor		;Farbe setzen.

::4
;--- Ergänzung: 19.11.22/M.Kanet
;C128: DB_DblBit über die X-Koordinate
;setzen, wenn DOUBLE_W verwendet wird.
;Übergabe: r2-r4 = Koordinaten der Box
if Flag64_128 = TRUE_C128
			lda	r3H			;Double-Bit aus X-Koordinate.
endif
::5
;--- Ergänzung: 19.11.22/M.Kanet
;C128: DB_DblBit für GetFiles immer
;setzen (Verwendet immer DOUBLE_W).
;Übergabe: Akku = Flag_GetFiles/$80
if Flag64_128 = TRUE_C128
			and	#%10000000		;Bit%7 isolieren und in
			sta	DB_DblBit		;Double-Flag sichern.
endif
			rts

;*** Dialogbox löschen.
:DB_ClearBox		bit	Flag_GetFiles		;Dateiauswahlbox aktiv ?
			bmi	:1			;Ja, weiter...

			jsr	SetADDR_DB_SCRN		;Bildschirm wieder auf
			jsr	SwapRAM			;Anfangsbild zurücksetzen.
			jsr	DB_SCREEN_LOAD

			lda	DB_ResetGrafx		;Icons auf Bildschirm
			bpl	:1			;belassen ? => Nein, weiter...
			sta	Flag_ColorDBox
			jsr	DB_InitIcons		;Icons initialisieren.
			jsr	LoadGEOS_Data		;Variablen zurücksetzen.

::1			lda	RecoverVector +1	;Ist RecoverVector gesetzt ?
			beq	NOFUNC10
			cmp	#> RecoverRectangle
			bne	DB_RecoverRec		;Nein, weiter...
			lda	RecoverVector +0	;Ist RecoverVector gesetzt ?
			cmp	#< RecoverRectangle
			bne	DB_RecoverRec		;Nein, weiter...
:NOFUNC10		rts

;*** Grafik im Bereich der Dialogbox über ":RecoverVector" wieder herstellen.
:DB_RecoverRec		lda	Flag_DBoxType		;Definitionsbyte einlesen.
			and	#%00011111		;Schatten zeichnen ?
			beq	:1			;Nein, weiter...
			sec				;Schatten löschen.
			jsr	:2
::1			clc				;Dialogbox löschen.
::2			jsr	DB_DefBoxPos
::3			jmp	RecoverMenuRect		;Menü-Rechteck zurücksetzen.

;*** Position für Dialogbox berechnen.
:DB_DefBoxPos		lda	#$00			;Dialogbox berechnen ?
			bcc	:1			;Ja, weiter...
			lda	#$08			;Schatten berechnen.
::1			sta	r1H			;Zeiger auf 8-Pixel Differenz.

			lda	DB_VecDefTab+1		;Zeiger auf Dialogboxtabelle
			pha				;zwischenspeichern.
			lda	DB_VecDefTab+0
			pha

			bit	Flag_DBoxType		;Standard-Dialogbox ?
			bpl	:2			;Nein, weiter...

			lda	#> DB_StdBoxSize -1	;Zeiger auf Standard-
			sta	DB_VecDefTab    +1	;Dialogboxtabelle setzen.
			lda	#< DB_StdBoxSize -1
			sta	DB_VecDefTab    +0
;<*>			lda	C_DBoxBack		;Standard-Farbe setzen.
;			sta	DB_StdBoxSize   +6

::2			ldx	#$00
			ldy	#$01
::3			lda	(DB_VecDefTab),y	;YOben/YUnten berechnen.
			clc
			adc	r1H
			sta	r2L,x
			iny
			inx
			cpx	#$02
			bne	:3

::4			lda	(DB_VecDefTab),y	;XLinks/XRechts berechnen.
			clc
			adc	r1H
			sta	r2L,x
			iny
			inx
			lda	(DB_VecDefTab),y
			bcc	:5
			adc	#$00
::5			sta	r2L,x
			iny
			inx
			cpx	#$06
			bne	:4

			bit	Flag_DBoxType		;Farbe definiert ?
			bmi	:6a			;<*> >Standardbox
			bvs	:6			;Ja, weiter...
::6a			lda	C_DBoxBack		;Standard-Farbe verwenden.
			b $2c
::6			lda	(DB_VecDefTab),y	;Farbe aus Header einlesen.
			sta	DB_CurColor		;Aktuelle Farbe setzen.

			pla				;Zeiger auf Dialogboxtabelle
			sta	DB_VecDefTab+0		;zurücksetzen.
			pla
			sta	DB_VecDefTab+1
			rts

;*** Dialogbox auf 8x8 Pixel vergrößern ?
.DB_TestUpsize		jsr	DB_DefBoxPos		;BOX-Koordinaten einlesen.

			bit	Flag_ColorDBox		;Standard-Box ?
			bmi	:2			;Ja, weiter...
			bit	Flag_DBoxType		;Box vergrößern ?
			bmi	:2			;Nein, weiter...

			lda	r2L			;Box-Koordinaten auf 8-Pixel
			and	#%11111000		;Farbsystem vergrößern.
			sta	r2L

			lda	r2H
			ora	#%00000111
			sta	r2H

			lda	r3L
			and	#%11111000
			sta	r3L

			lda	r4L
			ora	#%00000111
			sta	r4L

::2			rts

;--- Ergänzung: 02.10.21/M.Kanet
;Icons müssen über den Kernal auf dem
;Bildschirm ausgegeben werden, da z.B.
;GateWay das Icon bei Dateiinfo über
;den Infoblock ausgibt und der Bereich
;durch ":GetFiles_Menu" belegt ist.

;*** DoIcons für Dialogbox aufrufen.
.DB_DrawIcons		lda	DB_Icon_Tab		;Icons definiert ?
			beq	NOFUNC11

			lda	#< DB_Icon_Tab
			sta	r0L
			lda	#> DB_Icon_Tab
			sta	r0H
			jmp	DoIcons			;Icons darstellen.

;*** Laufwerk-Icons einbinden.
:DB_Drive		dec	DB_SetDrvIcons
			jsr	DB_DefIconPos		;Ausgabeposition berechnen.
			lda	r3L			;X-Koordinate einlesen.
if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit einblenden.
endif
			sta	DB_SetDrvXYpos+0	;X-Position zwischenspeichern.
			lda	r2L			;Y-Koordinate einlesen und als
			sta	DB_SetDrvXYpos+1	;Y-Position zwischenspeichern.
:NOFUNC11		rts

;*** Dialogbox-Icon darstellen.
:DB_SysIcon		dey				;Icon "OK" ?
			bne	:1			;Nein, weiter...

			lda	keyVector    +0
			ora	keyVector    +1		;Tastaturabfrage aktiv ?
			bne	:1			;Ja, weiter...

			lda	#> DB_ChkEnter		;Tastaturabfrage installieren,
			sta	keyVector    +1		;bei <RETURN> wird das "OK" -
			lda	#< DB_ChkEnter		;Icon aktiviert !
			sta	keyVector    +0

::1			tya				;Zeiger auf Icon-Eintrag für
			asl				;Dialogbox-Icon berechnen.
			asl
			asl
			clc
			adc	#< SysIconTab
			sta	r5L
			lda	#$00
			adc	#> SysIconTab
			sta	r5H

			jsr	DB_DefIconPos		;Ausgabeposition berechnen

;--- Ergänzung: 22.11.22/M.Kanet
;Das DOUBLE-Bit in der Breite darf nur
;für System-Icons gesetzt werden, da es
;hier keine Möglichkeit gibt die Breite
;über DOUBLE_B zu verdoppeln: System-
;Icons haben immer eine feste Größe.
;Bisher wurde hier aber das DOUBLE-Bit
;direkt in der Kernal-Tabelle gesetzt.
;Eine Dialogbox, die ohne Verdopplung
;arbeitet, kann dann aber keine System-
;Icons ohne DOUBLE-Bit mehr nutzen.
;Daher hier das DOUBLE-Bit löschen und
;ggf. DB_DblBit aus der Breite der
;Dialogbox anwenden.
;Die Standard-Dialogbox unter GEOS128
;hat immer das DOUBLE-Bit gesetzt.
;Damit werden die System-Icons immer
;in der Breite verdoppelt.
;Eine benutzerdefinierte Dialogbox muss
;in der X-Koordinate das DOUBLE-Bit
;setzen, damit ein System-Icon in der
;Breite verdoppelt wird.
;Es gibt aber auch Programme, die eine
;benutzerdefinierte Dialogbox ohne das
;DOUBLE-Bit in den Koordinaten nutzen.
;Um hier auch Sysem-Icons zu verdoppeln
;wird über DBUSRROUT eine Routine in
;den Aufbau der Dialogbox eingebunden,
;die das DB_DblBit setzt.
;Siehe Bsp. "TopDesk->Speziell->Farben"
if Flag64_128 = TRUE_C128
			ldy	#$04
			lda	(r5L),y			;Double-Bit für X-Breite.
			and	#%01111111
			ora	DB_DblBit
			sta	(r5L),y			;X-Breite korrigieren.
endif

			jsr	DB_TestIconPos

;*** Icon-Daten in Tabelle für die
;    Routine ":DoIcons" kopieren.
.DB_CopyIconInTab	ldx	DB_Icon_Tab
			cpx	#$08			;Icon-Tabelle voll ?
			bcs	:4			;Ja, Ende...

			txa
			inx
			stx	DB_Icon_Tab		;Anzahl Icons +1.
			jsr	DI_SetToEntry		;Zeiger auf Icon-Eintrag.
			tax

			ldy	#$00			;Icon-Eintrag in
::1			lda	(r5L)         ,y	;die interne Icontabelle
			sta	DB_Icon_Tab   ,x	;kopieren.
			inx
			iny
			cpy	#$08
			bne	:1

			lda	r3L			;X-Koordinate einlesen.
if Flag64_128 = TRUE_C128
			ora	DB_DblBit		;Double-Bit für X-Position.
endif
			sta	DB_Icon_Tab -6,x	;X-Position festlegen.
			lda	r2L			;Y-Koordinate festlegen.
			sta	DB_Icon_Tab -5,x
::4			rts

;*** User-Icon darstellen.
:DB_UsrIcon		jsr	DB_DefIconPos		;Ausgabeposition berechnen
			lda	(DB_VecDefTab),y	;Zeiger auf Icon-Eintrag
			sta	r5L			;des User-Icons einlesen.
			iny
			lda	(DB_VecDefTab),y
			sta	r5H
			iny
			tya
			pha
			jsr	DB_TestIconPos
			jsr	DB_CopyIconInTab	;Icon in Tabelle kopieren.
			jmp	DB_ExitRout2

;*** Position für System-/User-Icon berechnen.
:DB_DefIconPos		clc				;Koordinaten der Dialogbox
			jsr	DB_DefBoxPos		;in r2-r4 setzen.

			lsr	r3H			;X-Position in Cards
			lda	r3L			;umrechnen.
			ror
			lsr
			lsr
			ldy	r1L
			clc
			adc	(DB_VecDefTab),y	;Offset addieren.
			sta	r3L			;X-Position für Icon speichern.

			lda	r2L			;Y-Position einlesen.
			iny
			clc
			adc	(DB_VecDefTab),y	;Offset addieren.
			sta	r2L			;Y-Position für Icon speichern.

			iny				;Zeiger auf nächstes Byte.
			ldx	DB_Icon_Tab		;Icon-Nr. einlesen.

			lda	C_DBoxDIcon		;Vorgabe für Dialogbox-Icon.
			bit	Flag_GetFiles		;Dateiauswahlbox?
			bpl	:2			; => Nein, weiter...
			lda	C_FBoxDIcon		;Vorgabe für Auswahlbox-Icon.

::2			bit	Flag_DBoxType		;Color-Flag gesetzt?
			bvc	:1			;Nein, weiter...
			lda	(DB_VecDefTab),y	;Farbe einlesen.
			iny				;Farbcode übergehen.

::1			sta	DB_IconColor,x		;Icon-Farbe festlegen.
			sty	r1L			;Länge Icon-Befehl definieren.
			rts

;*** Icon-Position testen.
:DB_TestIconPos		bit	Flag_ColorDBox		;Icons für Farbe verschieben ?
			bmi	:5			;Nein, weiter...

::1			ldy	#$04			;Icon-Größe auf Mindestgröße
			lda	(r5L),y			;testen. Nicht alle Icons
if Flag64_128 = TRUE_C128
			and	#%01111111		;Double-Bit ausblenden
endif
			cmp	Flag_IconMinX		;dürfen in Ihrer Position
			bcc	:5			;verändert werden.
			iny
			lda	(r5L),y
			cmp	Flag_IconMinY
			bcc	:5

::2			lda	r2L			;Ist Y-Koordinate bereits im
			and	#%00000111		;8x8-Pixel-Raster ?
			beq	:5			;Ja, Ende.
			cmp	Flag_IconDown		;Icon nach oben/unten ?
			bcc	:3			;Nach oben, weiter...

			lda	r2L			;Icon nach unten verschieben.
			and	#%11111000
			clc
			adc	#$08
			bne	:4

::3			lda	r2L			;Icon nach oben verschieben.
			and	#%11111000

::4			jsr	TestUpIcon		;Neue Position gültig ?
			jsr	TestDownIcon
			sta	r2L			;Neue Y-Position setzen.
::5			rts

;*** Icon-Position testen ( kleiner Y-Koordinate DlgBox).
:TestUpIcon		cmp	DBoxSize +0		;Icon am oberen DlgBox-Rand ?
			bne	exitTestMv2		;Nein, Ende...

::1			clc				;Icon um 8-Pixel nach unten.
			adc	#$08

			pha				;Icon-Position merken.
			jsr	AddYSize		;Icon-Größe addieren.
			beq	exitTestMv1		;Icon über untere DB-Grenze ?
			bcc	exitTestMv1		;Nein, weiter...

			pla				;Icon nicht verschieben.
			sec
			sbc	#$08
			rts

;*** Icon-Position testen ( größer Y-Koordinate DlgBox).
:TestDownIcon		pha				;Icon-Position merken.
			jsr	AddYSize		;Icon-Größe addieren.
			bcc	exitTestMv1		; => DB-Rand überschritten.

::1			pla
			pha
			sec				;Icon nach oben verschieben.
			sbc	#$08

			cmp	DBoxSize +0		;Neue Position erlaubt ?
			bcc	exitTestMv1		;Nein, Ende...

			tay				;Neue Position merken.
			pla
			tya
			rts

:exitTestMv1		pla
:exitTestMv2		rts

;*** Y-Größe des Icons addieren.
:AddYSize		ldy	#$05
			clc
			adc	(r5L),y
			sec
			sbc	#$01
			cmp	DBoxSize +1
			rts

;*** GEOS-Tastaturabfrage für die Dialogbox zum "OK"/"CANCEL"-Icon.
:DB_ChkEnter		lda	keyData
			cmp	#$0d
			beq	DB_Icon_OK
:NOFUNC12		rts

;*** DBSYSOPV-Routine.
:DB_ChkSysOpV		bit	mouseData		;Maustaste gedrückt ?
			bmi	NOFUNC12		;Nein, weiter...
			lda	#$0e			;DBSYSOPV
			b $2c

;*** Dialogbox beenden / System-Icon.
:DB_Icon_OK		lda	#$01			;OK
			b $2c
:DB_Icon_CANCEL		lda	#$02			;CANCEL
			b $2c
:DB_Icon_YES		lda	#$03			;YES
			b $2c
:DB_Icon_NO		lda	#$04			;NO
			b $2c
:DB_Icon_OPEN		lda	#$05			;OPEN
			b $2c
:DB_Icon_DISK		lda	#$06			;DISK
			b $2c
:DB_EndGetStrg		lda	#$0d			;GETSTRING
			b $2c
.DB_Icon_DrvA		lda	#$88			;Laufwerk A:
			b $2c
.DB_Icon_DrvB		lda	#$89			;Laufwerk B:
			b $2c
.DB_Icon_DrvC		lda	#$8a			;Laufwerk C:
			b $2c
.DB_Icon_DrvD		lda	#$8b			;Laufwerk D:
:DB_SetIcon		sta	sysDBData 		;Rückgabewert festlegen und
							;Dialogbox beenden.
;*** Dialogbox beenden.
:xRstrFrmDialogue	jsr	LoadGEOS_Data		;Variablen zurücksetzen.
			jsr	DB_ClearBox		;Hintergrund herstellen.

;*** Zurück zum aufrufenden Programm.
			lda	sysDBData
			sta	r0L
			ldx	DB_RetStackP
			txs
			lda	DB_ReturnAdr+1
			pha
			lda	DB_ReturnAdr+0
			pha
			lda	Flag_ExtRAMinUse	;Hintergrundspeicher für
			and	#%10111111		;Dialogbox wieder freigeben.
			sta	Flag_ExtRAMinUse
			rts

;*** Steuercode: DBSYSOPV
:DB_SysOpV		lda	#> DB_ChkSysOpV
			sta	otherPressVec+1
			lda	#< DB_ChkSysOpV
			sta	otherPressVec+0
::1			rts

;*** Steuercode: DBOPVEC
:DB_OpVec		ldy	r1L
			lda	(DB_VecDefTab),y	;Mausklick-Routine
			sta	otherPressVec+0		;installieren.
			iny
			lda	(DB_VecDefTab),y
			sta	otherPressVec+1

;*** Zeiger auf Dialogbox-Tabelle um zwei Bytes erhöhen.
:DB_ExitRout1		inc	r1L
			inc	r1L
			rts

;*** Steuercode: DBGRAPHSTR
:DB_GraphStrg		jsr	DB_GetAddress
			tya
			pha
			bit	Flag_GetFiles
			bmi	DB_ExitRout2
			jsr	GraphicsString		;Grafikbefehle ausführen.

;*** Zeiger auf Dialogbox-Tabelle wieder zurücksetzen.
:DB_ExitRout2		pla
			sta	r1L
:DB_ExitRout3		rts

;*** Steuercode: DB_USR_ROUT
:DB_UserRout		jsr	DB_GetAddress
			tya
			pha
			bit	Flag_GetFiles
			bmi	:1
			lda	r0L
			ldx	r0H
			jsr	CallRoutine		;Anwender-Routine ausführen.
::1			jmp	DB_ExitRout2

;*** Steuercode: DBSETCOL
:DB_SetCol		ldy	r1L
			ldx	#$00
::1			lda	(DB_VecDefTab),y	;COLOR-Daten einlesen.
			sta	r5L           ,x
			iny
			inx
			cpx	#$05
			bne	:1
			sty	r1L
			jmp	xRecColorBox

;*** Steuercode: DBTXTSTR
:DB_TextStrg		jsr	DB_SubRout2
			jsr	DB_GetCurAdr
			jmp	DB_TextOutput

;*** Steuercode: DBVARSTR
:DB_VarTxtStrg		jsr	DB_SubRout1
:DB_TextOutput		tya
			pha
			bit	Flag_GetFiles
			bmi	:1
			jsr	PutString		;Text ausgeben.
::1			jmp	DB_ExitRout2

;*** Steuercode: DBGETSTRING
:DB_GetString		jsr	DB_SubRout1
			lda	(DB_VecDefTab),y	;Max. Anzahl Zeichen
			sta	r2L			;einlesen.
			iny
			tya
			pha
			bit	Flag_GetFiles
			bmi	:1
			lda	#> DB_EndGetStrg	;Tastaturabfrage für <RETURN>
			sta	keyVector+1		;installieren.
			lda	#< DB_EndGetStrg
			sta	keyVector+0
			lda	#$00
			sta	r1L
			jsr	GetString
::1			jmp	DB_ExitRout2

;*** Unterprogramme für Dialogbox.
:DB_SubRout1		jsr	DB_SubRout2
			lda	(DB_VecDefTab),y	;Zeiger auf Textstring
			iny				;einlesen.
			tax
			lda	zpage+0,x
			sta	r0L
			lda	zpage+1,x
			sta	r0H
			rts

;*** X-/Y-Koordinaten aus Text einlesen.
:DB_SubRout2		clc				;Dialogbox-Koordinaten
			jsr	DB_DefBoxPos		;berechnen.
;			jmp	DB_GetTextPos		;Textposition berechnen.

;*** X/Y-Koordinate für Textausgabe.
:DB_GetTextPos		ldy	r1L
			lda	(DB_VecDefTab),y
			clc
			adc	r3L
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H
			iny
			lda	(DB_VecDefTab),y
			iny
			clc
			adc	r2L
			sta	r1H
			rts

;*** Adresse aus Text einlesen.
:DB_GetAddress		ldy	r1L
:DB_GetCurAdr		lda	(DB_VecDefTab),y	;Zeiger auf Grafikbefehle
			sta	r0L			;einlesen.
			iny
			lda	(DB_VecDefTab),y
			sta	r0H
			iny
			rts

;*** Steuercode: DBGETFILES
:DB_GetFiles		lda	#%10000000		;Bit 7=1: Datei-Auswahlbox.
			b $2c

;*** Anwender-Dateinamen in Zwischenspeicher übertragen.
:DB_UsrGetFiles		lda	#%11000000		;Bit 6=1: Listen-Auswahlbox.
			sta	Flag_GetFiles
			ldx	r0L			;Dialogbox-Code einlesen und
			stx	DB_GetFilesOpt		;GetFile-Optionen speichern.
			ldx	r5L
			stx	DB_ExitGetFiles + 6
			ldx	r5H
			stx	DB_ExitGetFiles + 7
			asl				;DBGETFILES oder DBUSRFILES?
			bmi	:1			; => Listen-Auswahlbox.

			lda	r7L			;Parameter für GetFile
			sta	DB_GFileType    + 0	;zwischenspeichern.
			lda	r10L
			sta	DB_GFileClass   + 0
			lda	r10H
			sta	DB_GFileClass   + 1
			jmp	DB_ExitRout1		;DB-tabelle weiter auswerten.

::1			jsr	DB_GetAddress		;Startadresse der Dateinamen
			sty	r1L			;nach ":r0" kopieren.

			lda	r0L
			sta	DB_VecFNameBuf +0
			lda	r0H
			sta	DB_VecFNameBuf +1
			rts

;*** GetFile ausführen.
:DB_NewGetFiles		jsr	SetADDR_GFilMenu	;Auswahlbox darstellen und
			jsr	SwapRAM			;Icons initialisieren.
			jsr	LD_ADDR_GFILMENU

:DB_ExitGetFiles	ldy	#$10
::1			lda	DB_SlctFileName,y	;Name der ausgewählten Datei
			sta	$ffff          ,y	;an Ziel-Position kopieren.
			dey
			bpl	:1
:NoColors		rts

;*** Wert im AKKU-Register zu ":r0" addieren.
:Add_A_r0		clc
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H
::1			rts

;*** Daten für Standard-Dialogbox.
:DBoxSize		s $02				;Größe der Dialogbox, nur Y-Koordinaten.

;*** Größe der neuen Auswahlbox.
;    Wird für Screen-LOAD/SAVE benötigt, da sonst nur die Bereiche mit der
;    Größe der tatsächlichen Dialogbox gesichert/restauriert werden und nicht
;    die Bildschirmbereiche der neuen Auswahlbox!
			t "-G3_FBoxSize"
.DB_FBoxData		b %01000001
			b Y_DBox
			b Y_DBox + H_DBox -1
			w X_DBox ! DOUBLE_W
			w (X_DBox + B_DBox -1) ! DOUBLE_W ! ADD1_W

;*** Variablen.
.DB_CurColor		b $00
.DB_IconColor		s $08
.DB_VecFNameBuf		w $0000
.DB_SlctFileName	s 17
.DB_GetFilesOpt		b $00
.DB_SetDrvIcons		b $00
.DB_SetDrvXYpos		b $00,$00
.DB_ResetGrafx		b $00

;*** Tabelle mit Einsprungadressen für
;    Dialogbox-Steuercodes.
:DB_BoxCTabL		b <DB_SysIcon    , <DB_SysIcon, <DB_SysIcon  , <DB_SysIcon
			b <DB_SysIcon    , <DB_SysIcon, <DB_Drive    , <DB_ExitRout3
			b <DB_UsrGetFiles, <DB_SetCol , <DB_TextStrg , <DB_VarTxtStrg
			b <DB_GetString  , <DB_SysOpV , <DB_GraphStrg, <DB_GetFiles
			b <DB_OpVec      , <DB_UsrIcon, <DB_UserRout

:DB_BoxCTabH		b >DB_SysIcon    , >DB_SysIcon, >DB_SysIcon  , >DB_SysIcon
			b >DB_SysIcon    , >DB_SysIcon, >DB_Drive    , >DB_ExitRout3
			b >DB_UsrGetFiles, >DB_SetCol , >DB_TextStrg , >DB_VarTxtStrg
			b >DB_GetString  , >DB_SysOpV , >DB_GraphStrg, >DB_GetFiles
			b >DB_OpVec      , >DB_UsrIcon, >DB_UserRout

;*** Tabelle mit Länge der
;    Dialogbox-Steuercodes.
:CodeLenTab		b $03,$03,$03,$03
			b $03,$03,$03,$01
			b $05,$06,$05,$04
			b $05,$01,$03,$03
			b $03,$05,$03

;*** Icon-Tabellen für System-Icons.
:SysIconTab		w Icon_OK
			b $00,$00,$06,$10
			w DB_Icon_OK

			w Icon_CANCEL
			b $00,$00,$06,$10
			w DB_Icon_CANCEL

			w Icon_YES
			b $00,$00,$06,$10
			w DB_Icon_YES

			w Icon_NO
			b $00,$00,$06,$10
			w DB_Icon_NO

			w Icon_OPEN
			b $00,$00,$06,$10
			w DB_Icon_OPEN

			w Icon_DISK
			b $00,$00,$06,$10
			w DB_Icon_DISK
