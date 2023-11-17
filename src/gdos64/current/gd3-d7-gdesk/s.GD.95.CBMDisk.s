; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* CBM-Verzeichnis anzeigen.
;* Befehl an Laufwerk senden.
;
;--- Speicherbelegung:
;$0400-$6CFF: GeoDesk/CBM-Menü
;$6D00-$78FF: Registermenü
;$7900-$7FFF: Drucker/Zwischenspeicher

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Ausgabefenster.
:DIR_WIN_X		= 8 *4
:DIR_WIN_W		= 8 *32
:DIR_WIN_Y		= 8 *1
:DIR_WIN_H		= 8 *21
:DIR_WIN_BASE		= SCREEN_BASE +(DIR_WIN_Y/8)*40*8 +(DIR_WIN_X/8)*8
endif

;*** GEOS-Header.
			n "obj.GD95"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xDIRECTORY		;Verzeichnis anzeigen.
			jmp	xSENDCOM		;Befehl senden.

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** CBM-Verzeichnis anzeigen.
:xDIRECTORY		jsr	sys_SvBackScrn		;Grafikbildschirm zwischenspeichern.

			jsr	copyCharSet		;Zeichensatz #2 einlesen.

			lda	getFileDrv		;Vorgabe: Laufwerksadresse.
			sta	DRIVE_ADR
			lda	#$ff			;Vorgabe: Anzeige im ASCII-Modus.
			sta	PRNT_MODE

			jsr	PrintDirectory		;Verzeichnis ausgeben.

			jsr	sys_LdBackScrn		;Grafikbildschirm zurücksetzen.
			jmp	MOD_RESTART		;Zurück zum Hauptmenü.

;*** Befehl an Laufwerk senden.
:xSENDCOM		jsr	InitDrvTab		;Laufwerke suchen.
			txa				;Laufwerke am ser.Bus vorhanden?
			bne	:1			; => Ja, weiter...

			ldx	#DEV_NOT_FOUND		;Fehler: "Laufwerk nicht vorhanden"
			jsr	doXRegStatus		;Fehlermeldung ausgeben.
			jmp	MOD_RESTART		;Zurück zum DeskTop.

::1			lda	DRIVE_LIST		;Zeiger auf erstes Laufwerk.
			sta	DRIVE_ADR

			lda	#$00			;Zeiger auf erstes Laufwerk.
			sta	DRIVE_LIST_POS

			jsr	copyCharSet		;Zeichensatz #2 einlesen.

:RestartSendCom		LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "X" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Register-Menü.
:R1SizeY0 = $20
:R1SizeY1 = $8f
:R1SizeX0 = $0010
:R1SizeX1 = $0127

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "LAUFWERK".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif
if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons einbinden.
if .p
:EnableMSelect		= FALSE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= TRUE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Icons.
:RIcon_UpDown		w Icon_MUpDown
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MUpDown_x,Icon_MUpDown_y
			b USE_COLOR_INPUT

:RIcon_Status		w Icon_Status
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Status_x,Icon_Status_y
			b USE_COLOR_INPUT

:Icon_Status
<MISSING_IMAGE_DATA>

:Icon_Status_x		= .x
:Icon_Status_y		= .y

:RIcon_SendCom		w Icon_SendCom
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SendCom_x,Icon_SendCom_y
			b USE_COLOR_INPUT

:Icon_SendCom
if LANG = LANG_DE
<MISSING_IMAGE_DATA>

endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>

endif

:Icon_SendCom_x		= .x
:Icon_SendCom_y		= .y

:RIcon_ShowDir		w Icon_ShowDir
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_ShowDir_x,Icon_ShowDir_y
			b USE_COLOR_INPUT

:Icon_ShowDir
<MISSING_IMAGE_DATA>

:Icon_ShowDir_x		= .x
:Icon_ShowDir_y		= .y

:RIcon_InfoText		w Icon_InfoText
			b %01000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_InfoText_x,Icon_InfoText_y
			b USE_COLOR_INPUT

:Icon_InfoText
if LANG = LANG_DE
<MISSING_IMAGE_DATA>

endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>

endif

:Icon_InfoText_x	= .x
:Icon_InfoText_y	= .y

:RIcon_ClrText		w Icon_ClrText
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_ClrText_x,Icon_ClrText_y
			b USE_COLOR_INPUT

:Icon_ClrText
<MISSING_IMAGE_DATA>

:Icon_ClrText_x		= .x
:Icon_ClrText_y		= .y

;*** Daten für Register "LAUFWERK".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0048
:RTab1_2  = $0070
:RTab1_3  = $00b0
:RLine1_1 = $00
:RLine1_2 = $18
:RLine1_3 = $40
:RLine1_4 = $10
:mxComLen = 30

:RegTMenu1		b 14

			b BOX_FRAME
				w R1T00
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_2 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;--- Laufwerksadresse.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$08
				w R1SizeX0 +RTab1_1 +$08
				w R1SizeX0 +RTab1_1 +$08 +$10
::u01a			b BOX_NUMERIC
				w R1T02
				w $0000
				b RPos1_y +RLine1_1
				w R1SizeX0 +RTab1_1
				w DRIVE_ADR
				b 2!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setDrvAdr
				b RPos1_y +RLine1_1
				w R1SizeX0 +RTab1_1 +$10
				w RIcon_UpDown
				b (:u01a - RegTMenu1 -1)/11 +1

;--- Status abfragen.
			b BOX_ICON
				w R1T05
				w $0000
				b RPos1_y +RLine1_1
				w R1SizeX0 +RTab1_2
				w RIcon_Status
				b (:u01c - RegTMenu1 -1)/11 +1

;--- Verzeichnis anzeigen.
			b BOX_ICON
				w R1T04
				w execShowDir
				b RPos1_y +RLine1_1
				w R1SizeX0 +RTab1_3
				w RIcon_ShowDir
				b NO_OPT_UPDATE

;--- Befehl senden.
::u01b			b BOX_STRING
				w $0000
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w DRIVE_COM
				b mxComLen
			b BOX_ICON
				w $0000
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w RIcon_InfoText
				b NO_OPT_UPDATE
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_2 -1
				b RPos1_y +RLine1_2 +8
				w RPos1_x -1
				w RPos1_x +mxComLen*8 +8
			b BOX_ICON
				w $0000
				w clrCommand
				b RPos1_y +RLine1_2
				w RPos1_x +mxComLen*8
				w RIcon_ClrText
				b (:u01b - RegTMenu1 -1)/11 +1

;--- Senden.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_4 -1
				b RPos1_y +RLine1_4 +7
				w RPos1_x -1
				w RPos1_x +Icon_SendCom_x*8
			b BOX_ICON
				w $0000
				w sendCommand
				b RPos1_y +RLine1_4
				w RPos1_x
				w RIcon_SendCom
				b (:u01c - RegTMenu1 -1)/11 +1

;--- Status.
			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y +RLine1_3 -$0d
				b RPos1_y +RLine1_3 +$10 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

::u01c			b BOX_USEROPT_VIEW
				w $0000
				w prntStatus
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$0f
				w R1SizeX0 +$10
				w R1SizeX1 -$10

;*** Texte für Register "LAUFWERK".
if LANG = LANG_DE
:R1T00			b "BEFEHL SENDEN",NULL
:R1T01			b "STATUS",NULL
:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Laufwerk:",NULL
:R1T04			w R1SizeX0 +RTab1_3 +$18 +$04
			b RPos1_y +RLine1_1 +$06
			b "Verzeichnis"
			b GOTOXY
			w R1SizeX0 +RTab1_3 +$18 +$04
			b RPos1_y +RLine1_1 +$08 +$06
			b "anzeigen"
			b NULL
:R1T05			w R1SizeX0 +RTab1_2 +$10 +$04
			b RPos1_y +RLine1_1 +$06
			b "Status"
			b GOTOXY
			w R1SizeX0 +RTab1_2 +$10 +$04
			b RPos1_y +RLine1_1 +$08 +$06
			b "Info"
			b NULL
endif
if LANG = LANG_EN
:R1T00			b "SEND COMMAND",NULL
:R1T01			b "STATUS",NULL
:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Drive:",NULL
:R1T04			w R1SizeX0 +RTab1_3 +$18 +$04
			b RPos1_y +RLine1_1 +$06
			b "View"
			b GOTOXY
			w R1SizeX0 +RTab1_3 +$18 +$04
			b RPos1_y +RLine1_1 +$08 +$06
			b "directory"
			b NULL
:R1T05			w R1SizeX0 +RTab1_2 +$10 +$04
			b RPos1_y +RLine1_1 +$06
			b "Query"
			b GOTOXY
			w R1SizeX0 +RTab1_2 +$10 +$04
			b RPos1_y +RLine1_1 +$08 +$06
			b "status"
			b NULL
endif

;*** Laufwerksmenü initialisieren.
:InitDrvTab		php				;Intrerrupt sperren.
			sei

			lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Anzahl Laufwerke.
			sta	r0L
			ldx	#$08			;Startadresse Laufwerke ser.Bus.
			stx	r0H

			tay
::clr			sta	DRIVE_LIST,y		;Liste mit Laufwerken löschen.
			iny
			cpy	#8
			bcc	:clr

::loop			lda	#$00
			sta	STATUS
;			ldx	#< fname
;			ldy	#> fname
			jsr	SETNAM			;Kein Dateiname.

			lda	#5
			tay
			ldx	r0H
			jsr	SETLFS			;Daten für Laufwerk.
			jsr	OPENCHN			;Datenkanal öffnen.

			lda	#5			;Datenkanal schließen.
			jsr	CLOSE

			lda	STATUS			;Laufwerk vorhanden?
			bne	:next			; => Nein, weiter...

			ldx	r0L			;Eintrag in Laufwerksliste
			lda	r0H			;erstellen.
			sta	DRIVE_LIST,x

			inc	r0L
			lda	r0L
			cmp	#8 +1			;Max. 8 Laufwerke gefunden?
			bcs	:end			; => Ja, Ende...

::next			inc	r0H
			lda	r0H
			cmp	#29 +1			;Alle Laufwerke getestet?
			bcc	:loop			; => Nein, weiter...

::end			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			plp				;Interrupt zurücksetzen.

			ldx	r0L			;Anzahl Laufwerke zurückmelden.
			rts

;*** Laufwerksadresse wechseln.
:setDrvAdr		lda	mouseYPos		;Position Mauszeiger einlesen.
			and	#%00000111		;Up/Down?
			cmp	#4			; Y>=4?
			bcc	:down			; => Ja, runterzählen...

::up			ldx	DRIVE_LIST_POS		;Laufwerks-Adresse einlesen.
			bne	:u1			;Anfang erreicht? => Nein, weiter...
			ldx	#$08			;Zeiger auf Ende der Liste.
::u1			dex
			lda	DRIVE_LIST,x		;Adresse aus Liste = $00?
			beq	:u1			; => Ja, nächste Adresse.

			sta	DRIVE_ADR		;Neue Adresse setzen.
			stx	DRIVE_LIST_POS		;Neue Positon setzen.
			rts

::down			ldx	DRIVE_LIST_POS		;Laufwerks-Adresse einlesen.
::d1			inx
			cpx	#$08
			bcc	:d2
			ldx	#$00
::d2			lda	DRIVE_LIST,x		;Adresse aus Liste = $00?
			beq	:d1			; => Ja, nächste Adresse.

			sta	DRIVE_ADR		;Neue Adresse setzen.
			stx	DRIVE_LIST_POS		;Neue Positon setzen.
			rts

;*** Befehl löschen.
:clrCommand		ldx	#0
			txa
::1			sta	DRIVE_COM,x		;String-Ende erreicht?
			inx				;Zeiger auf nächstes Zeichen.
			cpx	#mxComLen +1		;Alle Zeichen ausgegeben?
			bcc	:1			; => Nein, weiter...
			rts

;*** Befehl an Laufwerk senden.
:sendCommand		php				;Intrerrupt sperren.
			sei

			lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00
;			ldx	#< DRIVE_COM
;			ldy	#> DRIVE_COM
			jsr	SETNAM			;Befehl als Dateiname.

			lda	#12
			ldx	DRIVE_ADR
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal.
			jsr	OPENCHN			;Befehlskanal öffnen.

			ldx	#12			;Ausgabekanal festlegen.
			jsr	CKOUT

			ldx	#0
::1			lda	DRIVE_COM,x		;String-Ende erreicht?
			beq	:end			; => Ja, Ende...

			cmp	#"$"			;HEX-Zahl verwenden?
			bne	:2			; => Nein, weiter...

			jsr	:getHex			;HEX-Wert für Zeichen einlesen.
			bne	:4

::2			cmp	#$41			;Zeichen von GEOS/ASCII nach
			bcc	:4			;PETSCII wandeln.
			cmp	#$60
			bcs	:3

			clc				;SHIFT A-Z nach PETSCII.
			adc	#$80
			bne	:4

::3			sec
			sbc	#$20			;A-Z nach PETSCII.

::4			jsr	CIOUT			;Zeichen auf ser.Bus ausgeben.

			inx				;Zeiger auf nächstes Zeichen.
			cpx	#mxComLen +1		;Alle Zeichen ausgegeben?
			bcc	:1			; => Nein, weiter...

::end			jsr	CLRCHN			;Standard-I/O herstellen.

			lda	#12			;Laufwerk schließen.
			jsr	CLOSE

			jsr	DoneWithIO		;I/O-Bereich einblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			plp				;Interrupt zurücksetzen.
			rts

;--- ASCII-Byte nach HEX-Byte wandeln.
::getHex		inx
			jsr	:getNibble		;ASCII-Zeichen einlesen/wandeln.
			asl
			asl
			asl
			asl
			sta	r0L			;High-Nibble zwischenspeichern.
			inx
			jsr	:getNibble		;ASCII-Zeichen einlesen/wandeln.
			ora	r0L			;Mit High-Nibble-verbinden.
			rts

;--- ASCII-Zeichen nach HEX $0-$F wandeln.
::getNibble		lda	DRIVE_COM,x
			cmp	#"9" +1
			bcs	:11
			sec
			sbc	#"0"
			rts

::11			and	#%11011111
			sec
			sbc	#"A" -10
			rts

;*** Status einlesen.
:queryStatus		php				;Intrerrupt sperren.
			sei

			lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#0
;			ldx	#< DRIVE_COM
;			ldy	#> DRIVE_COM
			jsr	SETNAM			;Befehl als Dateiname.

			lda	#12
			ldx	DRIVE_ADR
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal.
			jsr	OPENCHN			;Befehlskanal öffnen.

			ldx	#12			;Eingabe von Befehlskanal.
			jsr	CHKIN

			ldy	#$00
::loop			jsr	READST			;Ende erreicht?
			bne	:end			; => Ja, Ende...

			jsr	CHRIN			;Zeichen einlesen.
			cpy	#63			;Speicher voll?
			bcs	:skip			; => Ja, Zeichen ignorieren.

			sta	DRIVE_STATUS,y		;Zeichen in Puffer speichern.
			iny
::skip			jmp	:loop			; => Weiter, nächstes Zeichen...

;--- Ende Status-Meldung.
::end			lda	#NULL			;Ende Fehler-Status markieren.
			sta	DRIVE_STATUS,y

			jsr	CLRCHN			;Standard-I/O herstellen.

			lda	#12			;Befehlskanal schließen.
			jsr	CLOSE

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			plp				;Interrupt zurücksetzen.
			rts

;*** Status anzeigen.
:prntStatus		jsr	queryStatus		;Fehler-Status abfragen.

			lda	#$00
			sta	currentMode		;PLAINTEXT.

			LoadW	r14,R1SizeX1 -$10 -2

			ldx	#$00
			stx	r15L			;Zeichenzähler.
			inx
			stx	r15H			;Zeilenzähler.

			LoadW	r0,DRIVE_STATUS		;Zeiger auf Status-Text.

			LoadW	r1H,RPos1_y +RLine1_3 +6
::loop			LoadW	r11,R1SizeX0 +$10 +2

::1			ldy	r15L			;Zeichenposition einlesen.
			cpy	#64			;Max. 64 Zeichen ausgegeben?
			bcs	prntDirName		; => Ja, Ende...

			lda	(r0L),y			;Nächstes Zeichen einlesen.
			beq	prntDirName		;$00-Byte erreicht? => Ja, Ende...
			jsr	GetCharWidth		;Zeichenbreite einlesen.

			clc				;Wird der rechte Rand im Ausgabe-
			adc	r11L			;Bereich überschritten?
			sta	r13L
			lda	#0
			adc	r11H
			sta	r13H

;			lda	r13H
			cmp	r14H
			bne	:2
			lda	r13L
			cmp	r14L
::2			bcs	:line			; => Ja, Neue Zeile...

			ldy	r15L
			lda	(r0L),y
			jsr	SmallPutChar		;Zeichen ausgeben.

			inc	r15L			;Nächstes Zeichen ausgeben.
			bne	:1

::line			lda	r1H			;Zeiger auf nächste Zeile.
			clc
			adc	#$08
			sta	r1H

			dec	r15H			;Alle Zeilen ausgebeben?
			bpl	:loop			; => Nein, weiter...

:prntDirName		lda	#0			;Ausgabebereich löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	RPos1_y +RLine1_3 -$10 +4
			b	RPos1_y +RLine1_3 -$08 +6
			w	R1SizeX0 +$10
			w	R1SizeX1 -$10

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#FCom_Dir_len
			ldx	#< FCom_Dir
			ldy	#> FCom_Dir
			jsr	SETNAM			;Dateiname "$" setzen.

			lda	#2
			ldx	DRIVE_ADR
			ldy	#$00
			jsr	SETLFS			;Datenkanal festlegen.

			jsr	OPENCHN			;Laufwerk öffnen.

			ldx	#2			;Eingabe vom ser.Bus.
			jsr	CHKIN

			php				;IRQ sperren.
			sei

			lda	#"?"			;Vorgabe für
			sta	DIR_HEADER +0		;"Keine Diskette".
			sta	DIR_HEADER +1
			lda	#NULL
			sta	DIR_HEADER +2
			sta	r0L
			sta	r0H

			sta	r15L			;$00 = Kein Header ausgegeben.

;			lda	#NO_ERROR
			sta	STATUS

			jsr	ACPTR			;Low- Byte Lade-Adresse einlesen.
			lda	STATUS			;Fehler?
			bne	:end			; => Ja, Abbruch...

			jsr	ACPTR			;High-Byte Lade-Adresse einlesen.
			lda	STATUS			;Fehler?
			bne	:end			; => Ja, Abbruch...

			jsr	ACPTR			;Link-Bytes einlesen.
			cmp	#$00			;Verzeichnis-Ende erreicht?
			beq	:end			; => Ja, Ende...
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	ACPTR			;Low -Byte Dateigröße.
			sta	r0L
			jsr	ACPTR			;High-Byte Dateigröße.
			sta	r0H

			ldx	#$00
::1			jsr	ACPTR			;Zeichen einlesen.
			cmp	#$00			;Zeilenende?
			beq	:end			; => Ja, Ende...

			cmp	#$20			;PETSCII nach ASCII wandeln...
			bcc	:1
			cmp	#$40
			bcc	:2

			cmp	#$60
			bcs	:1a
			clc
			adc	#$20
			bne	:2

::1a			cmp	#$c0
			bcc	:1b
			sec
			sbc	#$80
			bcs	:2

::1b			lda	#"?"			;Unbekanntes Zeichen.
::2			sta	DIR_HEADER,x		;Zeichen zwischenspeichern.

			inx
			cpx	#31			;Zwischenspeicher voll?
			bcc	:1			; => Nein, weiter...

			dec	r15L			;Status "Header eingelesen".

::end			plp				;IRQ-Status zurücksetzen.

			jsr	CLRCHN			;Standard-I/O aktivieren.

			lda	#2			;Datenkanel schließen.
			jsr	CLOSE

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	#$00
			sta	currentMode		;PLAINTEXT.

			LoadW	r11,RPos1_x
			LoadB	r1H,RPos1_y +RLine1_3 -$08 +4

			PushW	r0			;Größe/Partition zwischenspeichern.

			LoadW	r0,DIR_INFO		;Infotext ausgeben.
			jsr	PutString

			PopW	r0			;Größe/Partition zurücksetzen.

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Größe/Partition ausgeben.

			lda	#" "
			jsr	SmallPutChar		;Abstandhalter.

			LoadW	r0,DIR_HEADER
			jsr	PutString		;Header ausgeben.

			bit	r15L			;Status abfragen?
			bmi	:exit			; => Nein, weiter...

			jsr	queryStatus		;Fehler-Status abfragen.

::exit			rts

;*** Verzeichnis anzeigen.
:execShowDir		lda	mouseXPos +0		;Positon Mauszeiger abfragen.
			sec
			sbc	#< (R1SizeX0 +RTab1_3)
			tax
			lda	mouseXPos +1
			sbc	#> (R1SizeX0 +RTab1_3)
			bne	:exit
			cpx	#24			;0-11 ?
			bcs	:exit			; => Ja, PETSCII...
			cpx	#12			;12-23 ?
			bcs	:ascii			; => Ja, ASCII...

::petscii		lda	#$00			;PETSCII setzen.
			b $2c
::ascii			lda	#$ff			;ASCII setzen.
			sta	PRNT_MODE

			LoadW	appMain,:dir		;Verzeichnis über GEOS anzeigen.
::exit			rts

;--- appMain-Routine für "Verzeichnis anzeigen".
::dir			lda	#0			;appMain-Vektor löschen.
			sta	appMain +0
			sta	appMain +1

			jsr	ExitRegisterMenu	;Register-Menü beenden.
			jsr	sys_LdBackScrn		;Grafikbildschirm zurücksetzen.

			jsr	PrintDirectory		;Verzeichnis ausgeben.

			jsr	sys_LdBackScrn		;Grafikbildschirm zurücksetzen.
			jmp	RestartSendCom		;RegisterMenü aktivieren.

;*** CBM-Zeichensatz #2 laden.
; - Klein-/Großbuchstaben
; - Nicht invertierte Zeichen
:copyCharSet		jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			php				;IRQ sperren.
			sei
			lda	CPU_DATA		;CHAR-ROM aktivieren.
			pha
			lda	#$31
			sta	CPU_DATA

			ldy	#$00			;Zeichensatz in RAM kopieren.
::1			lda	$d800,y
			sta	CHARSET +0,y
			lda	$d900,y
			sta	CHARSET +256,y
			lda	$da00,y
			sta	CHARSET +512,y
			lda	$db00,y
			sta	CHARSET +768,y
			iny
			bne	:1

			pla
			sta	CPU_DATA		;CHAR-ROM abschalten.
			plp				;IRQ zurücksetzen.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Verzeichnis auf Bildschirm ausgeben.
:PrintDirectory		lda	#0			;Ausgabebereich löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	DIR_WIN_Y, DIR_WIN_Y +DIR_WIN_H -1
			w	DIR_WIN_X, DIR_WIN_X +DIR_WIN_W -1

			lda	#%11111111		;Rahmen anzeigen.
			jsr	FrameRectangle

			lda	C_WinBack		;Fensterfarbe setzen.
			jsr	DirectColor

			jsr	i_Rectangle		;Titelzeile löschen.
			b	DIR_WIN_Y, DIR_WIN_Y +7
			w	DIR_WIN_X, DIR_WIN_X +DIR_WIN_W -1

			lda	C_WinTitel		;Farbe für Titelzeile setzen.
			jsr	DirectColor

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#FCom_Dir_len
			ldx	#< FCom_Dir
			ldy	#> FCom_Dir
			jsr	SETNAM			;Dateiname "$" setzen.

			lda	#2
			ldx	DRIVE_ADR
			ldy	#$00
			jsr	SETLFS			;Datenkanal festlegen.
			jsr	OPENCHN			;Datenkanal öffnen.

			ldx	#2			;Eingabe vom ser.Bus.
			jsr	CHKIN

			php				;IRQ sperren.
			sei

;--- Verzeichnis ausgeben.
			lda	#< (DIR_WIN_BASE +8*1)
			sta	a0L
			clc
			adc	#< (40 *8 *2)
			sta	a1L
			lda	#> (DIR_WIN_BASE +8*1)
			sta	a0H
			adc	#> (40 *8 *2)
			sta	a1H

			LoadB	a2L,(DIR_WIN_H /8) -2 -2

			lda	#NO_ERROR		;Fehler-Status löschen.
			sta	STATUS

			jsr	ACPTR			;Low- Byte Lade-Adresse einlesen.
			lda	STATUS			;Fehler?
			bne	:EOD			; => Ja, Abbruch...

			jsr	ACPTR			;High-Byte Lade-Adresse einlesen.
			lda	STATUS			;Fehler?
			bne	:EOD			; => Ja, Abbruch...

			jsr	printDirLine		;Header ausgeben.

			AddVW	40*8*2,a0		;Ausgabezeile setzen.

;--- Zeile aus Verzeichnis ausgeben.
::loop			lda	#%01111111		;Abfrage CTRL und RUN/STOP.
			sta	cia1base +0
			lda	cia1base +1
			cmp	#%11101111		;SPACE gedrückt?
			bne	:nowait			; => Nein, weiter...

;--- Pause/SPACE.
			jsr	waitNoKeyPress		;Warten bis keine Taste gedrückt.

::space			lda	#%01111111
			sta	cia1base +0
			lda	cia1base +1
			cmp	#%01111111		;RUN/STOP gedrückt?
			bne	:nostop1		; => Nein, weiter...

			jsr	waitNoKeyPress		;Warten bis keine Taste gedrückt.
			jmp	:done			; => RUN/STOP, Ende...

::nostop1		cmp	#%11101111		;SPACE gedrückt?
			bne	:space			; => Nein, warten.

			jsr	waitNoKeyPress		;Warten bis keine Taste gedrückt.
			beq	:1			;Anzeige fortsetzen.

;--- Auf Abbruch testen.
::nowait		cmp	#%01111111		;RUN/STOP gedrückt?
			bne	:nostop2		; => Nein, weiter...

			jsr	waitNoKeyPress		;Warten bis keine Taste gedrückt.
			jmp	:EOD			; => RUN/STOP, Ende...

;--- Auf Verzögerung testen.
::nostop2		cmp	#%11111011		;CTRL gedrückt?
			bne	:1			; => Nein, weiter...

			jsr	SCPU_Pause		;1/10sec. Pause.
			jsr	SCPU_Pause		;1/10sec. Pause.

;--- Zeile ausgeben.
::1			jsr	printDirLine		;Aktuelle Zeile ausgeben.
			tax				;Verzeichnisende erreicht?
			beq	:EOD			; => Ja, Ende...

			lda	a2L			;Bildschirm voll?
			bne	:2			; => Nein, weiter...

			jsr	scrollScreen		;Fenster nach oben scrollen.
			jmp	:loop			;Nächste Zeile ausgeben.

::2			AddVW	40*8,a0			;Nächste Ausgabezeile setzen.

			dec	a2L			;Zeilenzähler -1.
			jmp	:loop			;Nächste Zeile ausgeben.

;--- Verzeichnis-Ende.
::EOD			lda	a2L			;Bildschirm voll?
			beq	:scroll			; => Ja, weiter...

			AddVW	40*8,a1			;Nächste Ausgabezeile setzen.
			jmp	:3			; => Ende-Hinweis anzeigen.

::scroll		jsr	scrollScreen		;Leerzeile ausgeben.

::3			MoveW	a0,a1			;Cursor auf Zeilenanfang.

			lda	#< ExitMsgP		;PETSCII-Modus.
			ldx	#> ExitMsgP
			bit	PRNT_MODE
			bpl	:4
			lda	#< ExitMsgA		;ASCII-Modus.
			ldx	#> ExitMsgA
::4			sta	a7L
			stx	a7H			;Zeiger auf Abschlussmeldung.

			ldy	#0			;Hinweis "Taste drücken" ausgeben.
::5			sty	a6H
			lda	(a7L),y
			beq	:wait
			jsr	printChar
			ldy	a6H
			iny
			bne	:5

;--- Auf Tastendruck warten.
::wait			lda	#%00000000
			sta	cia1base +0
			lda	cia1base +1
			cmp	#%11111111		;Taste gedrückt?
			beq	:wait			; => Nein, warten...

			jsr	waitNoKeyPress		;Warten bis keine Taste gedrückt.

::done			plp				;IRQ-Status zurücksetzen.

			jsr	CLRCHN			;Standard-I/O aktivieren.

			lda	#2			;Datenkanel schließen.
			jsr	CLOSE

			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Auf keine Taste warten.
:waitNoKeyPress		lda	#%00000000		;Abfrage CTRL und RUN/STOP.
			sta	cia1base +0
			lda	cia1base +1
			cmp	#%11111111
			bne	waitNoKeyPress
			rts

;*** Aktuelle Zeile ausgeben.
;Rückgabe: AKKU = $00: Ende erreicht.
;               = $FF: Zeile OK.
:printDirLine		MoveW	a0,a1			;Cursor auf Zeilenanfang.

			jsr	ACPTR
			cmp	#$00			;Verzeichnis-Ende erreicht?
			beq	:end			; => Ja, Ende...
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	printBlocks		;Dateigröße ausgeben.
			jsr	printName		;Dateiname ausgeben.

			lda	#$ff			;Status: Ende nicht erreicht.
::end			rts

;*** Bildschirm-Scrolling.
:scrollScreen		LoadW	a8,DIR_WIN_BASE +40*8*3
			LoadW	a9,DIR_WIN_BASE +40*8*2

			ldx	#(DIR_WIN_H /8) -2 -2

			ldy	#$00			;Grafikzeile verschieben.
::1			lda	(a8L),y
			sta	(a9L),y
			iny
			bne	:1

			lda	a8L			;Zeiger auf nächste Zeile berechnen.
			sta	a9L
			clc
			adc	#< 40*8
			sta	a8L
			lda	a8H
			sta	a9H
			adc	#> 40*8
			sta	a8H

			dex				;Alle Zeilen verschoben?
			bne	:1			; => Nein, weiter...

			ldy	#$08			;Letzte Zeile löschen.
			lda	#$00
::2			sta	(a9L),y
			iny
			cpy	#$f8
			bne	:2

			rts

;*** Dateigröße ausgeben.
;Zahl wird rechtsbündig formatiert!
:printBlocks		jsr	ACPTR			;Low -Byte Dateigröße.
			sta	r10L
			jsr	ACPTR			;High-Byte Dateigröße.
			sta	r10H

;--- Ausgabe initialisieren.
			lda	#$ff			;Flag für führende Leerzeichen.
			sta	r12L
			ldy	#$04			;Zeiger auf 10000er.
			sty	r12H

::loop			lda	#$00			;Zähler löschen.
			sta	r13H

			ldx	r12H
::1			lda	r10L			;Wert 10^x von Dezimal-Zahl
			sec				;subtrahieren.
			sbc	DEZ_DATA_L,x
			tay
			lda	r10H
			sbc	DEZ_DATA_H,x
			bcc	:2			;Unterlauf ? Ja, weiter...

			sty	r10L			;Neuen Wert speichern.
			sta	r10H

			inc	r13H			;Zähler korrigieren.
			bne	:1			;Subtraktion fortsetzen.

;--- Zahl ausgeben.
::2			lda	r13H 			;Zahl = 0 ?
			bne	:3			; => Nein, weiter...
			bit	r12L			;Erste Ziffer?
			bmi	:4			; => Nein, "0" inorieren.
::3			ora	#%00110000		;Nach ASCII wandeln...
			sta	r12L			;Flag "Erste Ziffer" löschen.
			b $2c
::4			lda	#" "			;Leerzeichen / Zahlenformatierung.
			jsr	printChar		;Zahl/Leerzeichen ausgeben.

			dec	r12H			;Nächste Ziffer des
			bne	:loop			;ASCII-Strings berechnen.

			lda	r10L			;1er nach ASCII wandeln.
			ora	#%00110000
			jsr	printChar		;Zahl ausgeben.

			lda	#" "
			jmp	printChar		;Abstandszteichen ausgeben.

;*** Dateiname ausgeben.
:printName		jsr	ACPTR			;Zeichen einlesen.
			cmp	#$00			;Zeilenende?
			beq	:end			; => Ja, Ende...
			cmp	#$20			;Leerzeichen?
			beq	printName		; => Ja, ignorieren...

::1			jsr	printChar		;Zeichen ausgeben.

			jsr	ACPTR			;Nächsten Zeichen einlesen.
			cmp	#$00			;Zeilenende?
			bne	:1			; => Nein, weiter...

::end			rts

;*** Einzelnes Zeichen ausgeben.
;Dabei wird der C64-Zeichensatz#2
;verwendet. Groß-/Kleinbuchstaben
;werden aber getauscht.
; -> Anpassung an GEOS-ASCII.
:printChar		cmp	#$12			;REVERSE-ON?
			beq	:end			; => Ja, ignorieren...

			cmp	#$20			;PETSCII < 32?
			bcc	:bad			; => Ja, ungültig...

			beq	:skip			; => Leerzeichen, nur Cursor setzen.
			bne	:convert		; => Zeichen konvertieren.
::end			rts

;--- Zeichen konvertieren.
;screen      petscii      ascii
;BAD     <-  00-1F,80-9F  00-1F
;00-1F   <-  40-5F        60-7F
;20-3F   <-  20-3F        20-3F
;40-5F   <-  60-7F,C0-DF  40-5F
;60-7F   <-  A0-BF,E0-FF
::convert		cmp	#$5f			;GEOS "_"?
			beq	:conv1			; => Konvertieren...

			bit	PRNT_MODE
			bmi	:ascii

::petscii		cmp	#$40			;Zahlen...
			bcc	:prnt
			cmp	#$60			;a-z...
			bcc	:p40
			cmp	#$80			;Sondewrzeichen...
			bcc	:p20
			cmp	#$a0			;Steuerzeichen...
			bcc	:bad
			cmp	#$c0			;Sonderzeichen...
			bcc	:p40
;			cmp	#$e0			;A-Z...
;			bcc	:p80
;			bcs	:p80			;Sonderzeichen...

::p80			sec
			sbc	#$80
			bcs	:prnt
::p40			sec
			sbc	#$40
			bcs	:prnt
::p20			sec
			sbc	#$20
			bcs	:prnt

::ascii			cmp	#$40			;Zahlen...
			bcc	:prnt
			cmp	#$60			;A-Z...
			bcc	:prnt
			cmp	#$80			;a-z...
			bcc	:a60
			cmp	#$a0			;Steuerzeichen...
			bcc	:bad
			cmp	#$c0			;Sonderzeichen...
			bcc	:p40
			cmp	#$e0			;a-z...
			bcc	:ac0
			bcs	:p80			;Sonderzeichen...

::a60			sec
			sbc	#$60
			bcs	:prnt
::ac0			sec
			sbc	#$c0
			bcs	:prnt

;--- Sonderzeichen.
::conv1			lda	#$64			;Ersatzzeichen für "_".
			b $2c
::bad			lda	#"."			;Zeichen ungültig, Ersatzzeichen.

;--- SCREEN-Char ausgeben.
::prnt			ldx	#$00			;Zeiger auf CHARSET berechnen.
			stx	r1H
			asl
			rol	r1H
			asl
			rol	r1H
			asl
			rol	r1H
			clc
			adc	#< CHARSET
			sta	r1L
			lda	r1H
			adc	#> CHARSET
			sta	r1H

			ldy	#7			;Zeichen in Grafik-RAM schreiben.
::1			lda	(r1L),y
			sta	(a1L),y
			dey
			bpl	:1

::skip			AddVBW	8,a1			;Cursor auf nächstes Zeichen.

			rts

;*** Variablen.
:DRIVE_STATUS		b NULL
::end			s 64 -(:end - DRIVE_STATUS)

;--- Liste mit Laufwerken.
:DRIVE_ADR		b $08
:DRIVE_LIST_POS		b $00

;--- Laufwerks-Befehl.
:DRIVE_COM		b NULL
::end			s mxComLen +1 -(:end - DRIVE_COM)
:DRIVE_LIST		s 8

;--- Verzeichnis-Status.
:DIR_HEADER		s 32
:DIR_INFO		b "Disk: ",NULL

;--- Ausgabe-Modus.
:PRNT_MODE		b $00

;--- Verzeichnisanzeige.
:FCom_Dir		b "$"
:FCom_Dir_end
:FCom_Dir_len		= FCom_Dir_end - FCom_Dir

;--- Dezimal/ASCII-Umwandlung.
:DEZ_DATA_L		b < 1,< 10,< 100,< 1000,< 10000
:DEZ_DATA_H		b > 1,> 10,> 100,> 1000,> 10000

;--- Hinweis: Ausgabe beendet.
if LANG = LANG_DE
:ExitMsgP		b "wEITER MIT BELIEBIGER tASTE!",NULL
:ExitMsgA		b "Weiter mit beliebiger Taste!",NULL
endif
if LANG = LANG_EN
:ExitMsgP		b "pRESS ANY KEY TO CONTINUE!",NULL
:ExitMsgA		b "Press any key to continue!",NULL
endif

;*** Zwischenspeicher.
:DATABUF

:CHARSET		= (DATABUF /256 +1) *256

:BUF_START		= CHARSET +1024
:BUF_END		= BASE_DIRDATA

;*** Endadresse testen:
			g RegMenuBase
;***
