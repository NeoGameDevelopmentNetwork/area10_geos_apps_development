; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_KEYS"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
endif

;*** GEOS-Header.
			n "obj.Register"
			f DATA

			o LOAD_REGISTER

if 0=1
;******************************************************************************
;*** Definition der Register-Tabelle (nur Beispiel!).
;******************************************************************************
:RegisterTab		b $30,$b7			;Größe der Registerkarte. ACHTUNG!
			w $0008,$0137			;Kartenreiter werden am oberen Rand
							;angefügt!!!

			b 3				;Anzahl Registerkarten.

			w RegName01			;Zeiger auf Name  von Register #1.
			w RegMenu01			;Zeiger auf Daten von Register #1.

			w RegName02			;Zeiger auf Name  von Register #2.
			w RegMenu02			;Zeiger auf Daten von Register #2.

			w RegName03			;Zeiger auf Name  von Register #3.
			w RegMenu03			;Zeiger auf Daten von Register #3.

;*** Daten für Registereinträge.
:RegName01		b $28,$2f			;Größe des Registerfeldes. ACHTUNG!
			w $0018,$0047			;Registerfelde wird am rechten Rand
							;um 8 Pixel gekürzt (Grafikeffekt).
			b "DOKUMENT",NULL		;Name des Registers.

:RegName02		b $28,$2f			;Größe des Registerfeldes. ACHTUNG!
			w $0048,$0077			;Registerfelde wird am rechten Rand
							;um 8 Pixel gekürzt (Grafikeffekt).
			b "OPTIONEN",NULL		;Name des Registers.

:RegName03		b $28,$2f			;Größe des Registerfeldes. ACHTUNG!
			w $0078,$00a7			;Registerfelde wird am rechten Rand
							;um 8 Pixel gekürzt (Grafikeffekt).
			b "DRUCKER",NULL		;Name des Registers.

;*** Daten für Register.
:RegMenu01		b 6

;---
			b BOX_OPTION			;Kennbyte für Optionsfeld.
			w RegMenuText01_a		;Bezeichnung, $0000 = keine Bez.
			w $0000				;Anwender-Routine, wird ausgeführt
							;nach der Anwahl des Optionsfeldes
							;und vor dem anzeigen des neuen
							;Wertes.
			b $38				;Linke, obere Ecke für
			w $0018				;Optionsfeld.
			w DataAddr_1			;Adresse für Options-Flag.
			b %01000000			;Bit für Option setzen/löschen.

;---
			b BOX_STRING			;Kennbyte für Texteingabe.
			w RegMenuText01_b		;Zeiger auf Text für Option.
			w $0000				;Anwender-Routine.
			b $98				;Linke, obere Ecke für
			w $0068				;Optionsfeld.
			w TextAddr			;Zeiger auf Textstring.
			b $10				;Länge der Eingabe.

;---
			b BOX_NUMERIC			;Kennbyte für Zahleingabe.
			w RegMenuText01_c		;Zeiger auf Text für Option.
			w $0000				;Anwender-Routine.
			b $58				;Linke, obere Ecke für
			w $0068				;Optionsfeld.
			w DataAddr_2			;Zeiger auf Adresse mit Zahlenbyte.
			b $02				;Länge der Eingabe.

;---
			b BOX_USER			;Kennbyte für Anwenderroutine.
			w RegMenuText01_b		;Zeiger auf Text für Option.
			w UserAddr			;Routinefür Optionsfeld:
							;":r1L" = $00, => Grafik zeichnen.
							;":r1L" = $FF, => Job nach Auswahl.
			b $98,$9f			;Grenzen für Rechteck-Bereich,
			w $0068,$009f

;---
			b BOX_FRAME			;Kennbyte für Anwenderroutine.
			w RegMenuText01_b		;Titel für Rahmen.
			w $0000				;Dummy-Bytes!
			b $98,$9f			;Grenzen für Rechteck-Bereich,
			w $0068,$009f

;---
			b BOX_ICON			;Kennbyte für Anwender-Icon.
			w RegMenuText01_d		;Zeiger auf Text für Icon.
			w BoxRoutine			;Anwender-Routine.
			b $58				;Linke, obere Ecke für Icon.
			w $0068
			w IconTabelle			;Zeiger auf Adresse mit Zahlenbyte.
			b $01				;Eintrag-Nr.1 aktualisieren.
							;NO_OPT_UPDATE=Nichts aktualisieren.

;*** Bezeichnungen für Optionsfelder.
:RegMenuText01_a	w $0028				;X/Y-Koordinate.
			b $3e
			b "Option anwählen",NULL

:RegMenuText01_b	w $0028
			b $4e
			b "Text eingeben",NULL

:RegMenuText01_c	w $0028
			b $5e
			b "Zahl eingeben",NULL

:RegMenuText01_d	w $006c
			b $5e
			b "Icon anklicken",NULL

;*** Icon-Tabellen.
:IconTabelle		w IconAdr			;Zeiger auf Icon-Grafik.
			b %10000000			;Bit%7=1: iconSelFlag beachten.
			 				;Bit%6=1: Icon nicht invertieren.
			b $00				;Reserved for future use.
			b icon_x,icon_y			;Breite/Höhe für Icon.
			b Farbwert			;Farbwert für Vorder-/Hintergrund.
							;USE_COLOR_REG  = Registerkarte.
							;USE_COLOR_INPUT= Farbe Eingabefeld.
endif

;*** Variablen definieren.
if .p
.BOX_USER		= $01				;Anwenderbereich definieren.
.BOX_USER_VIEW		= $02				;Wie BOX_USER   , nur anzeigen, ändern nicht möglich.
.BOX_USEROPT		= $03				;Anwenderbereich mit Optionsrahmen definieren.
.BOX_USEROPT_VIEW	= $04				;Wie BOX_USEROPT, nur anzeigen, ändern nicht möglich.
.BOX_FRAME		= $05				;Rahmen mit Titel zeichnen.
.BOX_ICON		= $06				;Icon zeichnen.
.BOX_ICON_VIEW		= $07				;Wie BOX_Icon   , nur anzeigen, ändern nicht möglich.
.BOX_OPTION		= $08				;Optionsauswahl.
.BOX_OPTION_VIEW	= $09				;Option nur anzeigen, ändern nicht möglich.
.BOX_STRING		= $0a				;Stringeingabe.
.BOX_STRING_VIEW	= $0b				;String nur anzeigen, ändern nicht möglich.
.BOX_NUMERIC		= $0c				;Zahleneingabe.
.BOX_NUMERIC_VIEW	= $0d				;Zahl   nur eingeben, ändern nicht möglich.

:MAX_REGTYPES		= 14

.NUMERIC_LEFT		= $00				;Zahl linksbündig.
.NUMERIC_RIGHT		= $80				;Zahl rechtsbündig.
.NUMERIC_SETSPC		= $00				;Führende Leerzeichen ausgeben.
.NUMERIC_SET0		= $40				;Führende "0"-Zeichen ausgeben.
.NUMERIC_BYTE		= $00				;Zahl im BYTE-Format.
.NUMERIC_WORD		= $20				;Zahl im WORD-Format.

.NO_OPT_UPDATE		= NULL				;Bei Klick auf Icon keine Option aktualisieren.
.USE_COLOR_INPUT	= $ff				;Icon-Farbe = Eingabefeld.
.USE_COLOR_REG		= $ee				;Icon-Farbe = Registerfarbe.
endif

;*** Einsprungtabelle für ":DoRegister".
.RegMenuBase						;Ladeadresse Registermenü.
.DoRegister		jmp	xDoRegister		;Registermenü starten.
.ExitRegisterMenu	jmp	xExitRegister		;Registermenü beenden.
.RegisterInitMenu	jmp	xRegisterInitMenu	;Registermenü initialisieren.
.RegisterUpdate		jmp	xRegisterUpdate		;Registerkarte aktualisieren.
.RegisterAllOpt		jmp	xRegisterAllOpt		;Alle Optionen aktualisieren.
.RegisterNextOpt	jmp	xRegisterNextOpt	;Nächste Option aktualisieren.
.RegDrawOptFrame	jmp	xRegDrawOptFrame	;Optionsrahmen zeichnen.
.RegClrOptFrame		jmp	xRegClrOptFrame		;Optionsrahmen löschen.
.RegisterSetFont	jmp	UseFontG3		;Font Registermenü aktivieren.

;*** Extern verwendete Register.
.regMenuCurrent		b $00

;*** Intern verwendete Register.
:RegisterOPVec		w $0000
:RegisterVektor		w $0000
:RegisterPages		b $00
:RegisterNumEntry	b $00
:RegisterEntry		w $0000
:RegisterFields		b $00
:RegisterMseBuf		w $0000
:RegisterKeyBuf		w $0000
:RegisterStack		b $00
:RegisterString		s $06
:RegisterNumMode	b $00
:Flag_DrawFrame		b $00				;$FF = Rahmen nicht neu zeichnen.

;******************************************************************************
;*** Auf Optionsfeld prüfen.
:RegTab_TestCode	w Register_OptOK		;BOX_USER
			w Register_OptErr		;BOX_USER_VIEW
			w Register_OptOK		;BOX_USEROPT
			w Register_OptErr		;BOX_USEROPT_VIEW
			w Register_OptErr		;BOX_FRAME
			w Register_OptOK		;BOX_ICON
			w Register_OptErr		;BOX_ICON_VIEW
			w Register_OptOK		;BOX_OPTION
			w Register_OptErr		;BOX_OPTION_VIEW
			w Register_OptOK		;BOX_STRING
			w Register_OptErr		;BOX_STRING_VIEW
			w Register_OptOK		;BOX_NUMERIC
			w Register_OptErr		;BOX_NUMERIC_VIEW

;*** Register-Option darstellen.
:RegTab_DrawBox		w RegDraw_User
			w RegDraw_User
			w RegDraw_UserOpt
			w RegDraw_UserOpt
			w RegDraw_Frame
			w RegDraw_Icon
			w RegDraw_Icon
			w RegDraw_SlctOpt
			w RegDraw_SlctOpt
			w RegDraw_String
			w RegDraw_String
			w RegDraw_Numeric
			w RegDraw_Numeric

;*** Rahmen um Register-Option definieren.
:RegTab_SetFrame	w RegSetF_User
			w RegSetF_User
			w RegSetF_UserOpt
			w RegSetF_UserOpt
			w $0000
			w RegSetF_UsrIcon
			w RegSetF_UsrIcon
			w RegSetF_SlctOpt
			w RegSetF_SlctOpt
			w RegSetF_InpArea
			w RegSetF_InpArea
			w RegSetF_InpArea
			w RegSetF_InpArea

;*** Register-Optionsfeld löschen (Eingabe von Zahlen/Strings).
:RegTab_NewField	w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w RegDrawNewField
			w RegDrawNewField
			w RegDrawNewField
			w RegDrawNewField
			w RegDrawNewField
			w RegDrawNewField

;*** Register-Option ändern.
:RegTab_EditData	w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w RegEdit_Option
			w $0000
			w RegEdit_String
			w $0000
			w RegEdit_Numeric
			w $0000

;*** Register-Option testen.
:RegTab_TestInpt	w $0000
			w $0000
			w $0000
			w $0000
			w $0000
			w RegisterTestData
			w RegisterTestData
			w RegisterTestData
			w RegisterTestData
			w RegisterTestData
			w RegisterTestData
			w RegisterTestData
			w RegisterTestData

;*** Register-Option aktualisieren.
:RegTab_Update		w RegUpdt_User
			w RegUpdt_User
			w RegUpdt_UserOpt
			w RegUpdt_UserOpt
			w RegUpdt_Frame
			w RegUpdt_Icon
			w RegUpdt_Icon
			w RegUpdt_SlctOpt
			w RegUpdt_SlctOpt
			w RegUpdt_String
			w RegUpdt_String
			w RegUpdt_Numeric
			w RegUpdt_Numeric

;*** Register-Tabelle ausgeben.
:xDoRegister		LoadB	dispBufferOn,ST_WR_FORE
			MoveW	r0,RegisterVektor

			ldy	#6
			lda	(r0L),y			;Anzahl Register einlesen.
			and	#%00111111		;Da Zeiger über asl/asl berechnet
			sta	RegisterPages		;wird, max. 63 Registerkarten.

			lda	#$01			;Zeiger auf erstes Register.
			sta	regMenuCurrent

			jsr	xRegisterInitMenu	;Aktuelle Registerkarte zeichnen.

			lda	otherPressVec +0	;Mausvektor zwischenspeichern.
			sta	RegisterOPVec +0
			lda	otherPressVec +1
			sta	RegisterOPVec +1

			lda	#< RegisterMseTest	;Neue Mausabfrage installieren.
			sta	otherPressVec +0
			lda	#> RegisterMseTest
			sta	otherPressVec +1

			bit	mouseOn			;Mauszeiger bereits aktiviert ?
			bmi	:53			;Ja, weiter...

			php				;Mauszeiger aktivieren.
			sei
			LoadW	r11,$0000
			clc
			jsr	StartMouseMode
			plp

::53			rts

;*** Register aufbauen.
:xRegisterInitMenu
;			lda	#$00
;			sta	Flag_DrawFrame		;Optionsrahmen aktualisieren.
			MoveW	RegisterVektor,r15
			jsr	RegisterSetArea		;Bereich für Registerkarte setzen.

			lda	#$00			;Registerkarte löschen.
			jsr	SetPattern
			jsr	Rectangle
			lda	C_RegisterBack
			jsr	DirectColor
			lda	#%11111111
			jsr	FrameRectangle

			jsr	RegisterTopics		;Kartenreiter darstellen.
			jmp	RegisterNextOpt		;Inhalt auf Karte darstellen.

;*** Registermenü beenden.
:xExitRegister		jsr	UseSystemFont

			lda	RegisterOPVec +0	;Neue Mausabfrage installieren.
			sta	otherPressVec +0
			lda	RegisterOPVec +1
			sta	otherPressVec +1

			jmp	MouseOff

;*** Aktuelles Register ausgeben.
:xRegisterAllOpt	jsr	RegisterClear		;Inhalt Regfisterkarte löschen.

;*** Ausgabe der ersten Rgisterkarte.
:xRegisterNextOpt	jsr	RegisterSetData		;Zeiger auf Registertabelle.

			ldy	#0
			lda	(r15L),y		;Mind. ein Eintrag vorhanden?
			beq	:52			; => Nein, Ende...

			lda	#$00
			sta	Flag_DrawFrame		;Optionsrahmen aktualisieren.
::51			sta	RegisterNumEntry	;Zähler für Eintrag speichern.
			jsr	RegSetCurEntry		;Zeiger auf Eintrag nach r15.

			ldy	#0
			lda	(r15L),y		;Optionstyp einlesen.
			beq	:err			; => NULL, Fehler...
			cmp	#MAX_REGTYPES		;Optionstyp gültig?
			bcs	:err			; => Nein, Fehler...

			jsr	RegisterDrawBox		;Eintrag definieren.

			lda	RegisterNumEntry	;Zeiger auf nächsten Eintrag.
			clc
			adc	#$01
			cmp	RegisterFields		;Alle Einträge geprüft ?
			bcc	:51			; => Nein, weiter...

::52			rts

;--- Fehlerhafte Registertabelle.
::err			jsr	RegisterSetData		;Zeiger auf Registertabelle.

			ldy	#0
			lda	RegisterNumEntry	;Anzahl gültige Einträge in
			sta	(r15L),y		;Registertabelle korrigieren.

			rts

;*** Text für Optionsfeld ausgeben.
:RegisterPrnText	ldy	#1			;Zeiger auf Options-Bezeichnung
			lda	(r15L),y		;einlesen.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ora	r0L			;Text ausgeben ?
			beq	:51			;Nein, Ende...

			ldy	#$00
			sty	currentMode
			lda	(r0L),y			;Position für Text-Ausgabe
			sta	r11L			;einlesen.
			iny
			lda	(r0L),y
			sta	r11H
			iny
			lda	(r0L),y
			sta	r1H

			lda	r0L			;Zeiger auf Ausgabetext berechnen.
			clc
			adc	#$03
			sta	r0L
			lda	r0H
			adc	#$00
			sta	r0H
			jsr	PutString		;Text ausgeben.

::51			rts

;*** Grenzen für Rechteck einlesen.
:RegisterSetArea	ldy	#$00
:RegisterGetArea	ldx	#$00
::51			lda	(r15L),y
			sta	r2L,x
			iny
			inx
			cpx	#$06
			bcc	:51
			rts

;*** Zeiger auf Options-Adresse einlesen.
:RegSetOptAdr		ldy	#8
			lda	(r15L),y
			sta	r3L
			iny
			lda	(r15L),y
			sta	r3H
			rts

;*** Eingabefeld definieren.
:RegPrintInpArea	jsr	RegisterNewField	;Rahmen um Eingabefeld zeichnen.

			ldy	#5			;Position für Textausgabe
			lda	(r15L),y		;berechnen.
			clc
			adc	baselineOffset
			sta	r1H
			iny
			lda	(r15L),y
			clc
			adc	#$02
			sta	r11L
			iny
			lda	(r15L),y
			adc	#$00
			sta	r11H
			rts

;*** Zeiger auf Register-Eintrag.
:RegSetCurEntry		pha

			jsr	RegisterSetData		;Zeiger auf Registertabelle.

			ldy	#0
			lda	(r15L),y		;Anzahl Einträge in Datentabelle
			sta	RegisterFields		;einlesen und speichern.

			inc	r15L			;Zeiger auf ersten Dateneintrag.
			bne	:51
			inc	r15H

::51			pla
			sta	r1L
			lda	#11
			sta	r2L
			ldx	#r1L
			ldy	#r2L
			jsr	BBMult

			lda	r1L
			clc
			adc	r15L
			sta	r15L
			lda	r1H
			adc	r15H
			sta	r15H

			rts

;*** Zeiger auf Register-Optionen.
:RegisterSetData	lda	#9
			jsr	RegisterSetVec		;Zeiger auf Registertabelle.

			ldy	regMenuCurrent		;Zeiger auf Datentabelle für
			dey				;aktuelles Menü.
			tya
			asl
			asl
			tay
			lda	(r15L),y
			tax
			iny
			lda	(r15L),y
			stx	r15L			;Zeiger auf Register-Menüdaten
			sta	r15H			;für die aktuelle Register-Karte.
			rts

;*** Zeiger auf RegisterTabelle.
:RegisterSetVec		clc
			adc	RegisterVektor +0
			sta	r15L
			lda	#$00
			adc	RegisterVektor +1
			sta	r15H
			rts

;*** Registerfenster löschen.
:RegisterClear		jsr	RegisterTopics		;Kartenreiter anzeigen.

			lda	#$00
			jsr	RegisterSetVec		;Zeiger auf Registertabelle.
			jsr	RegisterSetArea		;Kartenbereich definieren.

			lda	C_RegisterBack		;Kartenbereich löschen.
			jsr	DirectColor

;*** Rechteck-Bereich löschen.
:RegisterClrRec		dec	r2H
:RegisterClrRec_a	inc	r2L
			AddVW	1,r3
			SubVW	1,r4
			lda	#$00
			jsr	SetPattern
			jmp	Rectangle

;*** Registetitel anzeigen.
:RegisterTopics		ldy	RegisterPages		;Anzahl Kartenreiter einlesen.
::51			tya
			pha
			jsr	PrintRegTitel		;Kartenreiter ausgeben.
			pla
			tay
			dey				;Alle Kartenreiter ausgegeben ?
			bne	:51			;Nein, weiter...
			rts

;*** Registertitel anzeigen.
;    Übergabe: yReg = Eintrag in Tabelle.
:PrintRegTitel		tya				;Zeiger auf Tabelle
			pha				;zwischenspeichern.
			lda	#$07
			jsr	RegisterSetVec		;Zeiger auf Registertabelle.
			pla

			pha				;Zeiger auf Tabelle wieder
			sec
			sbc	#$01
			jsr	RegSetF_TopIcon

			pla				;Farbe für Kartenreiter bestimmen.
			tax
			lda	C_RegisterOff		; => Inaktiv.
			cpx	regMenuCurrent
			php
			bne	:51
			lda	C_Register		; => Aktiv.
::51			jsr	DirectColor		;Farbe ausgeben.

			inc	r3L
			bne	:51a
			inc	r3H
::51a			lda	r4L
			bne	:51b
			dec	r4H
::51b			dec	r4L

			lda	#%00000000
			plp
			beq	:52
			lda	#%11111111
::52			ldx	r2H
			inx
			stx	r11L
			jsr	HorizontalLine

			jsr	RegSet_IconData
			jmp	BitmapUp

;*** Ist BOX-Code ein Optionsfeld ?
;    Übergabe: r15  = Zeiger auf Eintrag.
:RegisterTestCode	lda	#< RegTab_TestCode
			ldx	#> RegTab_TestCode
			jmp	RegisterExecCode

;***Optionsfeld auswerten.
:Register_OptOK		sec
			rts
:Register_OptErr	clc
			rts

;*** Befehl aus Tabelle ausführen.
;    Übergabe: r15  = Zeiger auf Eintrag.
:RegisterDrawBox	lda	#< RegTab_DrawBox
			ldx	#> RegTab_DrawBox
			jmp	RegisterExecCode

;*** Grenzen des Optionsfeldes festlegen.
;    Übergabe: r15  = Zeiger auf Eintrag.
:RegisterSetFrame	lda	#< RegTab_SetFrame
			ldx	#> RegTab_SetFrame
			jmp	RegisterExecCode

;*** Inhalt des Optionsfeldes löschen.
;    Übergabe: r15  = Zeiger auf Eintrag.
:RegisterNewField	lda	#< RegTab_NewField
			ldx	#> RegTab_NewField
			jmp	RegisterExecCode

;*** Optionsdaten ändern.
;    Übergabe: r15  = Zeiger auf Eintrag.
:RegisterEditData	lda	#< RegTab_EditData
			ldx	#> RegTab_EditData
			jmp	RegisterExecCode

;*** Optionsdaten prüfen.
;    Übergabe: r15  = Zeiger auf Eintrag.
:RegisterTestInpt	lda	#< RegTab_TestInpt
			ldx	#> RegTab_TestInpt
			jmp	RegisterExecCode

;*** Inhalt des Optionsfeldes aktualisieren.
;    Übergabe: r15  = Zeiger auf Eintrag.
:xRegisterUpdate	lda	#$ff
			sta	Flag_DrawFrame		;Optionsrahmen nicht neu zeichnen.
			lda	#< RegTab_Update
			ldx	#> RegTab_Update
			jsr	RegisterExecCode	;Menü-Eintrag aktualisieren.
			lda	#$00
			sta	Flag_DrawFrame		;Optionsrahmen wieder aktualisieren.
			rts

;*** Register-Code ausführen.
;    Übergabe: r0   = Zeiger auf Eintrag.
;              AKKU = LOW - Byte auf Sprungtabelle.
;              xReg = HIGH- Byte auf Sprungtabelle.
:RegisterExecCode	sta	r1L
			stx	r1H

			ldy	#0
			lda	(r15L),y		;Register-Optionstyp einlesen.
			asl
			tay
			dey
			lda	(r1L),y			;Zeiger auf Options-Routine
			tax				;einlesen.
			dey
			lda	(r1L),y
			jmp	CallRoutine		;Options-Routine ausführen.

;*** Rahmen und leeres Optionsfeld zeichnen.
;    Übergabe:		r15 = Zeiger auf Befehlstabelle.
:RegDrawNewField	jsr	RegisterSetFrame

;*** Rahmen und leeres Optionsfeld zeichnen.
;    Übergabe:		Koordinaten in r2-r4.
:RegDrawOptField	ldx	C_InputField		;Farbe für Optionsfeld.
			ldy	#0
			lda	(r15L),y
			cmp	#BOX_OPTION_VIEW	;Befehl "BOX_OPTION_VIEW" ?
			bne	:51			; => Nein, weiter...
			ldx	C_InputFieldOff
::51			txa				;Farbe für inaktives Optionsfeld.
			jsr	DirectColor
			lda	#$00			;Inhalt des Optionsfeldes löschen.
			jsr	SetPattern
			jsr	Rectangle

;*** Rahmen um Eingabefeld zeichnen.
;    Übergabe:		Koordinaten des Eingabefeldes in r2-r4.
:xRegDrawOptFrame	ldx	#%11111111
			b $2c
:xRegClrOptFrame	ldx	#%00000000
			dec	r2L
			inc	r2H
			SubVW	1,r3
			AddVW	1,r4
			txa

			bit	Flag_DrawFrame		;Optionsrahmen zeichnen?
			bmi	:1			; => Nein, weiter...

			jsr	FrameRectangle		;Optionsrahmen zeichen.

::1			rts

;*** Job: BOX_USER
;    Optionsfeld ausgeben.
:RegDraw_User		jsr	RegisterPrnText		;Options-Bezeichnung ausgeben.
			jsr	RegSetF_User
			jmp	RegisterUserJob

;*** Aktuelle Option anzeigen.
:RegUpdt_User		jsr	RegSetF_User
			jmp	RegisterTestData

;*** Job: BOX_USEROPT
;    Optionsfeld ausgeben.
:RegDraw_UserOpt	jsr	RegisterPrnText		;Options-Bezeichnung ausgeben.
			jsr	RegDrawNewField
			jsr	RegSetF_UserOpt
			jmp	RegisterUserJob

;*** Aktuelle Option anzeigen.
:RegUpdt_UserOpt	jsr	RegDrawNewField
			jsr	RegSetF_UserOpt
			jmp	RegisterTestData

;*** Koordinaten für Optionsfeld definieren.
:RegSetF_User
:RegSetF_UserOpt	ldy	#$05
			jsr	RegisterGetArea

			lda	r2L
			clc
			adc	baselineOffset
			sta	r1H

			lda	r3L
			clc
			adc	#$04
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H
			rts

;*** Optionsfeld ausgeben.
:RegisterUserJob	lda	#$00
			b $2c

;*** Option ändern.
:RegisterTestData	lda	#$ff
			sta	r1L

			ldy	#4			;Anwender-Routine ausführen:
			lda	(r15L),y		;  Diese Routine kann z.B. Daten
			tax				;  auf Gültigkeit testen oder
			dey				;  voneinander abhaengige Optionen
			lda	(r15L),y		;  aufeinander abstimmen.
			jmp	CallRoutine		;Bei der Funktion BOX_USER wird die
							;Routine ebenfalls aufgerufen, wenn
							;die Registerkarte aufgebaut wird.
							;Ob Daten dargestellt oder getestet
							;werden sollen, kann über Register
							;":r1L" getestet werden.

;*** Job: BOX_FRAME
;    Optionsfeld ausgeben.
:RegDraw_Frame		ldy	#$05
			jsr	RegisterGetArea
			lda	#%11111111
			jsr	FrameRectangle

			lda	r2L
			sta	r1H
			lda	r3L
			clc
			adc	#$08
			sta	r11L
			lda	r3H
			adc	#$00
			sta	r11H

			ldy	#$00
			sty	currentMode

			iny				;Zeiger auf Options-Bezeichnung
;			ldy	#1			;einlesen.
			lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ora	r0L			;Text ausgeben ?
			beq	RegUpdt_Frame		;Nein, Ende...

			jsr	PutString

;*** Job: BOX_FRAME
;    Optionsfeld aktualisieren.
:RegUpdt_Frame		PushW	r15
			jsr	RegisterUserJob
			PopW	r15
			rts

;*** Job: BOX_ICON
;    Optionsfeld ausgeben.
:RegDraw_Icon		jsr	RegisterPrnText		;Options-Bezeichnung ausgeben.
:RegDraw_IconGrfx	jsr	RegSetF_UsrIcon

			ldy	#$06
			lda	(r10L),y		;Farbcode einlesen.
			cmp	#USE_COLOR_INPUT	;Icon-Farbe= Farbe für Eingabefeld ?
			bne	:1			; => Nein, weiter...
			lda	C_InputField		;Z.B. für SelectIcons neben
			jmp	:2			;Auswahlfenster.

::1			cmp	#USE_COLOR_REG		;Icon-Farbe= Farbe für Register ?
			bne	:2			; => Nein, weiter...
			lda	C_RegisterBack		;Z.B. Icons auf Registerkarte.
::2			jsr	DirectColor

:RegView_Icon		jsr	RegSet_IconData
			jsr	RegSetXY_Icon		;X/Y-Koordinate einlesen.
			jmp	BitmapUp

:RegSet_IconVec		lda	(r15L),y		;Zeiger auf Eintrag einlesen.
			sta	r10L
			iny
			lda	(r15L),y
			sta	r10H
			rts

:RegSet_IconData	ldy	#$05
			ldx	#$05
::51			lda	(r10L),y
			sta	r0L   ,x
			dey
			dex
			bpl	:51
			rts

;*** Bitmap-Koordinaten einlesen.
:RegSetXY_Icon		ldy	#6			;X-Koordinate einlesen.
			lda	(r15L),y
			sta	r1L
			iny
			lda	(r15L),y
			sta	r1H

			ldx	#r1L			;X-Koordinate in CARDs umwandeln.
			ldy	#$03
			jsr	DShiftRight

			ldy	#5			;Y-Koordinate einlesen.
			lda	(r15L),y
			sta	r1H
			rts

;*** Aktuelles Icon anzeigen.
:RegUpdt_Icon		jsr	RegDraw_IconGrfx

			PushW	r15

			ldy	#10
			lda	(r15L),y		;Eintrag aktualisieren?
			beq	:51			; => Nein, weiter...

			sec
			sbc	#$01
			cmp	RegisterFields		;Eintrag > max. Anzahl?
			bcs	:51			; => Ja, Ende...

			jsr	RegSetCurEntry		;Zeiger auf Eintrag nach r15.
			jsr	RegisterUpdate

::51			PopW	r15
			rts

;*** Koordinaten für Iconfeld definieren.
:RegSetF_TopIcon	asl
			asl
			tay
			jsr	RegSet_IconVec
			jsr	RegSet_IconData
			jmp	RegSetF_AllIcon

:RegSetF_UsrIcon	ldy	#$08
			jsr	RegSet_IconVec
			jsr	RegSet_IconData
			jsr	RegSetXY_Icon		;X/Y-Koordinate einlesen.

:RegSetF_AllIcon	lda	r1L
			sta	r3L
			clc
			adc	r2L
			sta	r4L

			lda	r1H
			sta	r2L
			clc
			adc	r2H
			sta	r2H
			dec	r2H

			lda	#$00
			sta	r3H
			sta	r4H

			ldx	#r3L			;X-Koordinate in Pixel umwandeln.
			ldy	#$03
			jsr	DShiftLeft
			ldx	#r4L			;X-Koordinate in Pixel umwandeln.
			ldy	#$03
			jsr	DShiftLeft
			SubVW	1,r4
			rts

;*** Job: BOX_USEROPT
;    Optionsfeld ausgeben.
:RegDraw_SlctOpt	jsr	RegisterPrnText		;Options-Bezeichnung ausgeben.

;*** Aktuelle Option anzeigen.
:RegUpdt_SlctOpt	jsr	RegisterNewField	;Optionsfeld zeichnen.

			jsr	RegSetXY_Icon		;X/Y-Koordinate einlesen.

			LoadB	r2L,RegIcon01_x		;Größe des Icons für
			LoadB	r2H,RegIcon01_y		;"Option gewählt/nicht gewählt"

			jsr	RegSetOptAdr		;Zeiger auf Options-Flag.

			ldy	#$00
			lda	(r3L),y			;Optionswert einlesen und
			ldy	#10			;benötigtes BIT isolieren.
			and	(r15L),y
			ldx	#< RegIcon01		; Vorgabe: "Option gewählt".
			ldy	#> RegIcon01
			cmp	#$00			;Ist Option gewählt ?
			bne	:51			;Ja, weiter...
			ldx	#< RegIcon02		;          "Option nicht gewählt".
			ldy	#> RegIcon02
::51			stx	r0L			;Zeiger auf Icon und
			sty	r0H			;Bitmap ausgeben.
			jmp	BitmapUp

;*** Koordinaten für Optionsfeld definieren.
:RegSetF_SlctOpt	ldy	#5
			lda	(r15L),y
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			iny
;			ldy	#6
			lda	(r15L),y
			sta	r3L
			clc
			adc	#$07
			sta	r4L
			iny
			lda	(r15L),y
			sta	r3H
			adc	#$00
			sta	r4H
			rts

;*** Job: BOX_STRING
;    Optionsfeld ausgeben.
:RegDraw_String		jsr	RegisterPrnText		;Bezeichnung für Textfeld ausgeben.

;*** Aktuelle Option anzeigen.
:RegUpdt_String		jsr	RegPrintInpArea		;Eingabefeld darstellen.

			ldy	#8			;Zeiger auf Text einlesen und
			lda	(r15L),y		;zwischenspeichern.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			lda	#$00
			sta	currentMode
			jmp	PutString		;Text ausgeben.

;*** Job: BOX_NUMERIC
;    Optionsfeld ausgeben.
:RegDraw_Numeric	jsr	RegisterPrnText		;Bezeichnung für Textfeld ausgeben.

;*** Aktuelle Option anzeigen.
:RegUpdt_Numeric	jsr	RegPrintInpArea		;Eingabefeld darstellen.
			jsr	RegSetOptAdr		;Zeiger auf Byte mit Zahl für
							;Eingabefeld setzen.
			jsr	RegDefString		;Zahl nach ASCII wandeln.

			bit	RegisterNumMode
			bpl	:53

			lda	r4L
			sec
			sbc	#$02
			sta	r11L
			lda	r4H
			sbc	#$00
			sta	r11H

			ldx	#$00
::51			lda	RegisterString,x
			beq	:53
			jsr	GetCharWidth
			sta	:52 +1

			lda	r11L
			sec
::52			sbc	#$04
			sta	r11L
			lda	r11H
			sbc	#$00
			sta	r11H

			inx
			bne	:51

::53			LoadW	r0,RegisterString
			jmp	PutString		;Zahl ausgeben.

;*** Koordinaten für Eingabefeld definieren.
:RegSetF_InpArea	ldy	#5
			lda	(r15L),y
			sta	r2L			; => Grenze oben.
			clc
			adc	#$07
			sta	r2H			; => Grenze unten.
			iny
;			ldy	#6
			lda	(r15L),y
			sta	r3L			; => Grenze links.
			iny
			lda	(r15L),y
			sta	r3H

			ldy	#10			; => Grenze rechts
			lda	(r15L),y
			asl
			asl
			asl
			sec
			sbc	#$01
			clc
			adc	r3L
			sta	r4L
			lda	#$00
			adc	r3H
			sta	r4H
			rts

;*** Mausabfrage für Registerkarten.
:RegisterMseTest	lda	mouseData		;Maustaste gedrückt ?
			bpl	:51			;Ja, weiter...
			rts

::51			jsr	RegisterNoSlct		;Warten bis keine Maustaste
							;mehr gedrückt.

;*** Testen ob Register gewählt wurde.
:RegTestMseTopic	lda	RegisterPages		;Register definiert ?
			beq	:54			;Nein, Abbruch...

			php				;IRQ sperren.
			sei

			lda	#$00
			sta	RegisterFields		;Zeiger auf erste Karte.

::51			lda	#$07
			jsr	RegisterSetVec		;Zeiger auf Registertabelle.

			lda	RegisterFields
			cmp	RegisterPages		;Letzte Karte erreicht ?
			beq	:53			;Ja, weiter...

			jsr	RegSetF_TopIcon		;Grenze für Kartenreiter einlesen.
			jsr	IsMseInRegion		;Mausbereich abfragen.
			tax				;Mausklick in Bereich ?
			bne	RegMseOnTopic		;Ja, weiter...

			inc	RegisterFields		;Zeiger auf nächste Karte und
			bne	:51			;weitertesten.

::53			jmp	RegTestMseOption	;Registerdaten abfragen.
::54			rts

;*** Neues Register aktivieren.
:RegMseOnTopic		plp				;IRQ wieder freigeben.

			ldy	RegisterFields
			iny
			cpy	regMenuCurrent		;Register bereits aktiv ?
			beq	:51			; => Ja, weiter...

			sty	regMenuCurrent		;Neues Register setzen und
			jsr	RegisterAllOpt		;Register-Inhalt ausgeben.

::51			jmp	RegisterNoSlct		;Ende...

;*** Mausabfrage für Daten in Registerkarte.
:RegTestMseOption	lda	#$00
::51			sta	RegisterNumEntry
			jsr	RegSetCurEntry		;Zeiger auf Eintrag nach r15.
			jsr	RegisterTestCode	;Optionsfeld ?
			bcc	:52			;Nein, weiter...

			jsr	RegisterSetFrame	;Grenzen für Optionsbereich setzen.
			jsr	IsMseInRegion		;Mausbereich abfragen.
			tax				;Mausklick im Optionsbereich ?
			bne	RegMseOnOption		;Ja, weiter...

::52			lda	RegisterNumEntry
			clc
			adc	#$01
			cmp	RegisterFields		;Alle Einträge geprüft ?
			bcc	:51			;Nein, weiter...

			plp

			lda	RegisterOPVec +0	;Zurück zur GEOS-Abfrage.
			ldx	RegisterOPVec +1
			jmp	CallRoutine

;*** Warten bis keine Maustaste mehr gedrückt.
:RegisterNoSlct		ldx	#$00			;Fenstergrenzen zwischenspeichern.
::51			lda	mouseTop,x
			pha
			inx
			cpx	#$06
			bcc	:51

			lda	mouseYPos		;Maus an Position festhalten.
			sta	mouseTop
			sta	mouseBottom
			lda	mouseXPos  +0
			sta	mouseLeft  +0
			sta	mouseRight +0
			lda	mouseXPos  +1
			sta	mouseLeft  +1
			sta	mouseRight +1

::52			lda	mouseData		;Warten bis keine Maustaste
			bpl	:52			;mehr gedrückt.
			LoadB	pressFlag,NULL

			ldx	#$05			;Fenstergrenzen zurücksetzen.
::53			pla
			sta	mouseTop,x
			dex
			bpl	:53
			rts

;*** Option auf Registerkarte angewählt.
:RegMseOnOption		plp				;IRQ wieder freigeben.

;			lda	RegisterNumEntry	;r15 auf aktuellen Eintrag setzen.
;			jsr	RegSetCurEntry		;(Hier bereits gesetzt)

			ldy	#0
			lda	(r15L),y		;Optionstyp einlesen.
			cmp	#BOX_ICON		;BOX_ICON?
			bne	:exec			; => Nein, weiter...

;--- Register-Eintrag "BOX_ICON".
			ldy	#8
			jsr	RegSet_IconVec		;Zeiger auf Icon-Tabelle nach r10.
			ldy	#2
			lda	(r10L),y		;Icon-Flag einlesen.
			asl				;Bit%7 in C-Flag, Bit%6 in N-Flag.
			bmi	:exec			;Bit%6=1: Icon nicht invertieren.
			bcc	:system			;Bit%7=0: System-Flag auswerten.

;--- BOX_ICON: iconSelFlag auswerten.
::default		lda	#%11000000		;ST_FLASH!ST_INVERT
			bit	iconSelFlag		;Icon-Status anzeigen?
			bmi	:flash			; => Ja, weiter...

;--- BOX_ICON: System-Flag auswerten.
::system		lda	Flag_MenuStatus
			and	#%00010000		;Icon-Status anzeigen?
			beq	:exec			; => Nein, weiter...

;--- BOX_ICON: Icon-Status anzeigen.
::flash			jsr	RegisterSetFrame	;Grenzen für Optionsbereich setzen.
			jsr	InvertRectangle		;Icon invertieren.

			lda	selectionFlash		;Zähler für Menü-Blinken setzen.
			sta	r0L
			lda	#$00
			sta	r0H
			jsr	Sleep			;Pause/Blinken ausführen.

;--- Hinweis:
;Das "Blinken" muss hier nicht wieder
;rückgängig gemacht werden, da hier das
;Register-Menü zuerst die Icon-Routine
;ausführt und anschließend das Icon
;aktualisiert (=neu darstellt).
;			lda	RegisterNumEntry
;			jsr	RegSetCurEntry		;Zeiger auf Eintrag nach r15.
;
;			jsr	RegisterSetFrame	;Grenzen für Optionsbereich setzen.
;			jsr	InvertRectangle		;Icon invertieren.

;--- Andere Register-Einträge.
::exec			jsr	RegisterEditData	;Daten im Optionsfeld ändern.
			jsr	RegisterTestInpt	;Anwender-Routine ausführen.

			lda	RegisterNumEntry
			jsr	RegSetCurEntry		;Zeiger auf Eintrag nach r15.

			jsr	RegisterUpdate		;Optionsdaten aktualisieren.
::exit			jmp	RegisterNoSlct		;Ende...

;*** Register-Option wechseln.
:RegEdit_Option		jsr	RegSetOptAdr		;Zeiger auf Options-Flag.

			ldy	#10			;Optionsflag einlesen und
			lda	(r15L),y		;benötigtes BIT ändern.
			ldy	#$00
			eor	(r3L),y
			sta	(r3L),y
			rts

;*** Eingabe eines Textes, max. 32 Zeichen.
:RegEdit_String		jsr	RegInitGetStrg		;GetString initialisieren.

			ldy	#8			;Zeiger auf Textstring einlesen.
			lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H

			LoadW	keyVector,RegEditStrgCont

;*** Tastatureingabe starten.
:RegStartGetStrg	jsr	GetString		;Eingaberoutine aufrufen.

			tsx				;Stack-Zeiger einlesen und
			stx	RegisterStack		;zwischenspeichern.
			jmp	MainLoop		;MainLoop starten.

:RegEditStrgCont	MoveW	RegisterEntry,r0

;*** Tastatureingabe beenden.
:RegEndGetStrg		MoveW	RegisterMseBuf,mouseVector
			MoveW	RegisterKeyBuf,keyVector
			ldx	RegisterStack		;Stack-Zeiger zurücksetzen.
			txs
			rts

;*** Eingabe einer Zahl von $00 bis $FF.
:RegEdit_Numeric	jsr	RegInitGetStrg		;GetString initialisieren.
			jsr	RegSetOptAdr		;Zeiger auf Options-Byte.
			jsr	RegDefString		;ASCII wandeln.

			ldy	#10			;Modi für Zahleneingabe
			lda	(r15L),y		;bestimmen.
			and	#%11100000
			sta	RegisterNumMode

			LoadW	r0,RegisterString	;Zeiger auf Eingabestring und
			LoadW	keyVector,RegEditNumCont
			jmp	RegStartGetStrg		;Tastatureingabe starten.

:RegEditNumCont		MoveW	RegisterEntry,r0

			jsr	RegSetOptAdr		;Zeiger auf Options-Byte und
			jsr	RegDefNumeric		;Ergebnis nach Dezimal wandeln.
			jmp	RegEndGetStrg		;Tastatureingabe beenden.

;*** Tastatur-Eingabe initialisieren.
:RegInitGetStrg		lda	#$ff
			sta	Flag_DrawFrame		;Optionsrahmen nicht neu zeichnen.
			jsr	RegisterNewField	;Eingabefeld zeichnen.
			lda	#$00
			inc	Flag_DrawFrame		;Optionsrahmen wieder aktualisieren.

			MoveW	keyVector  ,RegisterKeyBuf
			MoveW	mouseVector,RegisterMseBuf

			LoadW	mouseVector,MouseExitInput

			MoveW	r15,RegisterEntry	;Zeiger auf Tabelle retten.

			ldy	#5			;Position für Texteingabe
			lda	(r15L),y		;berechnen.
			sta	r1H
			iny
			lda	(r15L),y
			clc
			adc	#$02
			sta	r11L
			iny
;			ldy	#7
			lda	(r15L),y
			adc	#$00
			sta	r11H

			ldy	#10			;Länge des Eingabefeldes bestimmen.
			lda	(r15L),y
			and	#%00011111
			sta	r2L

			ldy	#$00			;Fehlerflag löschen.
			sty	r1L
			rts

;*** Tastatureingabe über Mausklick beenden.
:MouseExitInput		lda	#KEY_CR
			jmp	PutKeyInBuffer

;*** ASCII-String nach Dezimal umwandeln.
;    Übergabe:		r15 = Zeiger auf Register-Eintrag.
;			r3  = Zeiger auf Adresse mit der zu konvertierenden Zahl.
:RegDefNumeric		lda	#$00
			sta	r10L
			sta	r10H
			sta	r11L
			lda	#10
			sta	r12L

::51			ldy	r11L
			lda	RegisterString +0,y
			cmp	#$30
			bcs	:52
			lda	#"0"
::52			cmp	#$3a
			bcc	:53
			lda	#"9"
::53			sec
			sbc	#$30
			clc
			adc	r10L
			sta	r10L
			bcc	:54
			inc	r10H

::54			inc	r11L
			lda	RegisterString +1,y
			beq	:55

			ldx	#r10L
			ldy	#r12L
			jsr	BMult
			lda	r11L
			cmp	#$05
			bcc	:51

::55			ldy	#$00			;Ergebnis speichern.
			lda	r10L			;LOW-Byte der Eingabe einlesen und
			sta	(r3L),y			;in Ziel-Speicher kopieren.
			lda	RegisterNumMode
			and	#NUMERIC_WORD		;WORD-Eingabe ?
			beq	:56			;Nein, weiter...
			iny
			lda	r10H			;HIGH-Byte der Eingabe einlesen und
			sta	(r3L),y			;in Ziel-Speicher kopieren.
::56			rts

;*** Zahl in ASCII umwandeln.
;    Übergabe:		r15 = Zeiger auf Register-Eintrag.
;			r3  = Zeiger auf Adresse mit der zu konvertierenden Zahl.
:RegDefString		ldy	#$00
			sty	r12L
			lda	(r3L),y			;LOW-Byte einlesen und in
			sta	r10L			;Eingabespeicher kopieren.
			sty	r10H

			ldy	#10
			lda	(r15L),y
			and	#%11100000
			sta	RegisterNumMode
			and	#NUMERIC_WORD		;WORD-Eingabe ?
			beq	:50			;Nein, weiter...
			ldy	#1
			lda	(r3L),y			;HIGH-Byte einlesen und in
			sta	r10H			;Eingabespeicher kopieren.

::50			ldy	#10
			lda	(r15L),y
			and	#%00011111
			sta	r14H

			ldy	#4			;Zeiger auf 10000er.
			sty	r12H
			lda	#$00			;Zeiger auf Eingabespeicher.
			sta	r13L
			iny				;Eingabespeicher löschen.
::51			sta	RegisterString,y
			dey
			bpl	:51

::52			lda	#$00			;Zähler löschen.
			sta	r13H

			ldx	r12H
::53			lda	r10L			;Wert 10^x von Dezimal-Zahl
			sec				;subtrahieren.
			sbc	DEZ_DATA_L,x
			tay
			lda	r10H
			sbc	DEZ_DATA_H,x
			bcc	:54			;Unterlauf ? Ja, weiter...
			sty	r10L			;Neuen Wert speichern.
			sta	r10H
			inc	r13H			;Zähler korrigieren.
			jmp	:53			;Subtraktion fortsetzen.

::54			lda	r13H 			;Stelle in ASCII-Zahl > 0 ?
			beq	:54a			;Nein, weiter...
			stx	r12L
::54a			ldy	r12L
			bne	:55
			cpx	#$00			;Einer-Stelle erreicht ?
			beq	:55			;Ja, "0" in String kopieren.

			bit	RegisterNumMode		;Rechts-/Linksbündig ?
			bpl	:57			; => Linksbündig ausgeben, weiter...

			bit	RegisterNumMode		;Führende '0' ausgeben ?
			bvs	:55			; => Ja, weiter...
			lda	#" "
			bne	:56

::55			ora	#$30			;Zahl in Zwischenspeicher
::56			ldx	r13L			;übertragen.
			sta	RegisterString,x
			inc	r13L

::57			dec	r12H			;Nächste Ziffer des
			bpl	:52			;ASCII-Strings berechnen.

			lda	r14H
			cmp	r13L
			bcs	:59
			lda	r13L
			sec
			sbc	r14H
			tay
			ldx	#$00
::58			lda	RegisterString,y
			sta	RegisterString,x
			beq	:59
			iny
			inx
			bne	:58
::59			rts

;*** Register-Icons.
:RegIcon01
<MISSING_IMAGE_DATA>
:RegIcon01_x		= .x
:RegIcon01_y		= .y

:RegIcon02		;Icon ist 8x8 Pixel (leer)!!!
<MISSING_IMAGE_DATA>

:RegIcon02_x		= .x
:RegIcon02_y		= .y

;*** MP3-Zeichensatz.
			t "-G3_UseFontG3"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_REGISTER + R2S_REGISTER -1
;******************************************************************************
