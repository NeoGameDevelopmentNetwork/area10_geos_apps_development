; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* CMD-Partitionen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"
endif

;*** GEOS-Header.
			n "obj.GD96"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xCMDPART
			jmp	xCMDPARTNUM

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** CMD-Partitionen umbenennen.
:xCMDPARTNUM
:xCMDPART		ldx	curDrive		;CMD-Laufwerk?
			lda	RealDrvMode -8,x
			and	#SET_MODE_PARTITION
			beq	ExitRegMenuUser		; => Nein, Ende...

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			bit	reloadDir		;Partition geändert?
			bpl	:2			; => Nein, Ende...

;--- Hier ohne Funktion.
;			lda	exitCode
;			bne	...

::1			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "X" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;*** Register-Menü.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

:RegMenu1a		b 1				;Anzahl Einträge.

			w RegTName1			;Register: "CMD".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** Icons.
:RIcon_Name		w Icon_Name
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Name_x,Icon_Name_y
			b USE_COLOR_INPUT

:Icon_Name
<MISSING_IMAGE_DATA>

:Icon_Name_x		= .x
:Icon_Name_y		= .y

:RIcon_FileUp		w Icon_FileUp
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FileUp_x,Icon_FileUp_y
			b USE_COLOR_INPUT

:Icon_FileUp
<MISSING_IMAGE_DATA>

:Icon_FileUp_x		= .x
:Icon_FileUp_y		= .y

:RIcon_FileDown		w Icon_FileDown
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_FileDown_x,Icon_FileDown_y
			b USE_COLOR_INPUT

:Icon_FileDown
<MISSING_IMAGE_DATA>

:Icon_FileDown_x	= .x
:Icon_FileDown_y	= .y

:RIcon_PageUp		w Icon_PageUp
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_PageUp_x,Icon_PageUp_y
			b USE_COLOR_INPUT

:Icon_PageUp
<MISSING_IMAGE_DATA>

:Icon_PageUp_x		= .x
:Icon_PageUp_y		= .y

:RIcon_PageDown		w Icon_PageDown
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_PageDown_x,Icon_PageDown_y
			b USE_COLOR_INPUT

:Icon_PageDown
<MISSING_IMAGE_DATA>

:Icon_PageDown_x	= .x
:Icon_PageDown_y	= .y

;*** Daten für Register "CMD".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0028
:RTab1_2  = $0078
:RTab1_3  = $00a0
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $38

:RegTMenu1		b 15

			b BOX_FRAME
				w R1T01
				w initPartData
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_1 +$28 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;--- Partition.
:RegTMenu1a		b BOX_NUMERIC
				w $0000
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x
				w partNr
				b 3!NUMERIC_RIGHT
:RegTMenu1b		b BOX_STRING
				w $0000
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w partName
				b 16
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -1
				b RPos1_y +RLine1_1 +8
				w RPos1_x +RTab1_1 -1
				w RPos1_x +RTab1_1 +20*8
			b BOX_ICON
				w $0000
				w renamePart
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1 +16*8
				w RIcon_Name
				b NO_OPT_UPDATE

:RegTMenu1c		b BOX_STRING_VIEW
				w R1T02
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_1
				w partType
				b 4
:RegTMenu1d		b BOX_NUMERIC
				w R1T03
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_3
				w partSize
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

;--- Optionen.
:RegTMenu1e		b BOX_OPTION
				w R1T04
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w partSetDName
				b %10000000

;--- Partitionsliste.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_4 -1
				b R1SizeY1 -$08 +1
				w R1SizeX0 +$08 -1
				w R1SizeX1 -$08 +1
			b BOX_ICON
				w $0000
				w movePrevPart
				b RPos1_y +RLine1_4 +0
				w R1SizeX1 -$10 +1
				w RIcon_FileUp
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w movePrevPage
				b RPos1_y +RLine1_4 +8
				w R1SizeX1 -$10 +1
				w RIcon_PageUp
				b NO_OPT_UPDATE
			b BOX_ICON
				w R1TGfx
				w moveNextPage
				b RPos1_y +RLine1_4 +24
				w R1SizeX1 -$10 +1
				w RIcon_PageDown
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w moveNextPage
				b RPos1_y +RLine1_4 +32
				w R1SizeX1 -$10 +1
				w RIcon_FileDown
				b NO_OPT_UPDATE
			b BOX_USER
				w $0000
				w slctNewPart
				b RPos1_y +RLine1_4
				b R1SizeY1 -$08
				w R1SizeX0 +$08
				w R1SizeX1 -$10
			b BOX_USEROPT_VIEW
				w $0000
				w printPartList
				b RPos1_y +RLine1_4
				b R1SizeY1 -$08
				w R1SizeX0 +$08
				w R1SizeX1 -$10

;*** Texte für Register "CMD".
if LANG = LANG_DE
:R1T01			b "PARTITION",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Typ:",NULL
:R1T03			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_2 +$06
			b "Größe:",NULL
:R1T04			w RPos1_x +12
			b RPos1_y +RLine1_3 +$06
			b "Diskname anpassen",NULL
endif
if LANG = LANG_EN
:R1T01			b "PARTITION",NULL

:R1T02			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_2 +$06
			b "Type:",NULL
:R1T03			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_2 +$06
			b "Size:",NULL
:R1T04			w RPos1_x +12
			b RPos1_y +RLine1_3 +$06
			b "Update disk name",NULL
endif

;--- Dummy-Scrollbalken.
:R1TGfx			w $0000				;Text-Position ignorieren.
			b $00
			b ESC_GRAPHICS			;Auf Grafik-Befehle umschalten.
			b NEWPATTERN
			b $01
			b MOVEPENTO
			w R1SizeX1 -$10 +1
			b RPos1_y +RLine1_4 +16
			b RECTANGLETO
			w R1SizeX1 -$10 +1 +7
			b RPos1_y +RLine1_4 +16 +7
			b NULL

;*** Position der Partitionsliste.
:LIST_BASE_Y		= (RPos1_y +RLine1_4)/8
:LIST_BASE_X		= (R1SizeX0 +8)/8
:LIST_BASE		= SCREEN_BASE +(LIST_BASE_Y *40 *8) +(LIST_BASE_X *8)

;*** Partitionsdaten einlesen.
:initPartData		lda	#$00
			sta	partCount		;Anzahl Partitionen löschen.
			sta	partCurPos		;Zeiger auf Anfang der Liste.

			ldx	curDrive		;Max. Anzahl Partitionen
			lda	RealDrvType -8,x	;ermitteln:
			and	#DrvCMD
			beq	:nopart
			cmp	#DrvHD
			beq	:cmd_hd
::cmd_fd_rl		lda	#32			;CMD FD/RL: 0- 31 =  32 Partitionen.
			b $2c
::cmd_hd		lda	#255			;CMD HD   : 0-254 = 255 Partitionen.
			sta	partMax

			LoadW	r4,partList
			jsr	GetPTypeData		;Partitionstypen einlesen.
			txa				;Laufwerksfehler?
			bne	:nopart			; => Ja, Ende...

			ldy	#0			;Partitionsliste komprimieren.
			ldx	#1			;Die Liste beinhaltet dann nur noch
::1			lda	partList,x		;die Partitionsnummern.
			beq	:2			;Nicht vorhandene Partitionen sind
			txa				;in der Liste nicht mehr enthalten.
			sta	partList,y
			iny
::2			inx
			bne	:1
			sty	partCount

			ldx	curDrive		;Aktive Partition in Liste suchen.
			lda	drivePartData -8,x

			ldx	#0
::3			cpx	partCount		;Ende der Liste erreicht?
			beq	:4			; => Ja, weiter...
			cmp	partList,x		;Partition gefunden?
			beq	:5			; => Ja, weiter...
			inx
			bne	:3			; => Nein, weitersuchen...

::4			ldx	#$00			;Zeiger auf erste Partition.
::5			txa				;Erste Position in Anzeige-Liste
			clc				;berechnen.
			adc	#5
			cmp	partCount
			bcc	:6

			lda	partCount
::6			sec
			sbc	#5
			bcs	:7
			lda	#$00
::7			sta	partCurPos		;Position in Anzeige-Liste setzen.

;			ldx	partCurPos		;Gesuchte Partition bereits im XReg!
			jsr	getPartInfo		;Partitionsdaten einlesen.

::nopart		rts

;*** Aktuelle Partitionsliste ausgeben.
:printPartList		lda	#$00			;Anzeige-Liste löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b RPos1_y +RLine1_4
			b R1SizeY1 -$08
			w R1SizeX0 +$08
			w R1SizeX1 -$10

			lda	partCount		;Partitionen vorhanden?
			bne	:1			; => Ja, weiter...

			LoadW	r11,R1SizeX0 +$08 +12
			LoadB	r1H,RPos1_y +RLine1_4 +12
			LoadW	r0,partError
			jmp	PutString		;"Keine Partitionen!", Ende...

::1			lda	partCurPos		;Anfangsposition einlesen.
			sta	r15L
			lda	#$00			;Anzahl Einträge löschen.
			sta	r15H

			lda	#RPos1_y +RLine1_4 +6
			sta	r14H			;Y-Position für Textausgabe.

::loop			ldx	r15L
			cpx	partCount		;Ende der Partitions-Liste erreicht?
			bcs	:end			; => Ja, Ende...

			lda	partList,x		;Partition definiert?
			beq	:next			; => Nein, weiter...

			sta	r3H			;Partitions-Nr. setzen und
			jsr	printPartLine		;Eintrag ausgeben.

			inc	r15H			;Anzahl Einträge +1.

			lda	r14H			;Y-Position auf nächste Zeile.
			clc
			adc	#8
			sta	r14H

::next			inc	r15L			;Zeiger auf nächsten Eintrag.
			beq	:end			; => Ende erreicht...
			lda	r15H
			cmp	#5			;Max. 5 Einträge ausgegeben?
			bcc	:loop			; => Nein, weiter...

::end			rts

;*** Zeile in Partitionsliste ausgeben.
;Übergabe: r14H = YPos für Textausgabe.
;          r3H  = Partitionsnummer.
:printPartLine		LoadW	r4,partData
			jsr	GetPDirEntry		;Partitionsdaten einlesen.
			txa
			pha				;Laufwerksstatus zwischenspeichern.

			LoadW	r11,R1SizeX0 +$08 +2
			MoveB	r14H,r1H		;Position für Textausgabe.

			lda	r3H
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#SET_RIGHTJUST!SET_SUPRESS!20
			jsr	PutDecimal		;Partitions-Nr. ausgeben.

			LoadW	r11,R1SizeX0 +$08 +2 +20 +8

			pla				;Laufwerksfehler?
			beq	:cont			; => Nein, weiter...

			lda	#"?"
			jsr	SmallPutChar

			LoadW	r11,R1SizeX0 +$08 +2 +20 +8 +3*8 +6

			lda	#"?"
			jmp	SmallPutChar		;Keine Partitionsdaten, Ende...

::cont			jsr	getVecPType		;Zeiger auf Partitionstyp nach :r0.

			ldy	#0			;Vier Zeichen Partitionstyp
::1			tya				;ausgeben.
			pha
			lda	(r0L),y
			jsr	SmallPutChar
			pla
			tay
			iny
			cpy	#4
			bcc	:1

			LoadW	r11,R1SizeX0 +$08 +2 +20 +8 +3*8 +6

			ldy	#0			;Partitionsname ausgeben.
::2			tya				;Sonderzeichen konvertieren.
			pha
			lda	partData +3,y
			bpl	:3
			sec
			sbc	#128
::3			cmp	#" "
			bcc	:4
			cmp	#$7f
			bcc	:5
::4			lda	#"."			;Ersatzzeichen.
::5			jsr	SmallPutChar
			pla
			tay
			iny
			cpy	#16
			bcc	:2

::err			rts

;*** Eine Seite nach oben.
:movePrevPage		lda	partCount		;Partitonen vorhanden?
			beq	:exit			; => Nein, Ende...

			lda	partCurPos		;Position einlesen.
			sec				;Eine Seite zurück.
			sbc	#5			;Anfang überschritten?
			bcs	:1			; => Nein, weiter...
			lda	#0			;Auf Anfang zurücksetzen.
::1			jsr	moveToPage		;Neue Seite anzeigen.
::exit			rts

;*** Eine Seite nach unten.
:moveNextPage		lda	partCount		;Partitonen vorhanden?
			beq	:exit			; => Nein, Ende...

			lda	partCurPos		;Position einlesen.
			clc
			adc	#10
			cmp	partCount		;Volle Seite möglich?
			bcc	:1			; => Ja, weiter...
			lda	partCount		;Zum Ende der Liste.
::1			sec
			sbc	#5			;Position korrigieren.
			jsr	moveToPage		;Neue Seite anzeigen.
::exit			rts

;*** Seite an neuer Pos. anzeigen.
:moveToPage		cmp	partCurPos		;Position verändert?
			beq	:exit			; => Nein, Ende...
			sta	partCurPos		;Neue Position setzen und
			jsr	printPartList		;Partitionsliste ausgeben.
::exit			rts

;*** Eine Partition nach oben.
:movePrevPart		lda	partCount		;Partitonen vorhanden?
			beq	:exit			; => Nein, Ende...

			lda	partCurPos		;Position einlesen.
			beq	:exit
			jsr	scrollDown		;Anzeige-Liste scrollen.
			dec	partCurPos		;Neue Position setzen.
			ldx	partCurPos		;Partition für neue Zeile einlesen.
			lda	partList,x
			sta	r3H
			LoadB	r14H,(LIST_BASE_Y *8) +6
			jsr	printPartLine		;Eintrag ausgeben.
::exit			rts

;*** Eine Partition nach unten.
:moveNextPart		lda	partCount		;Partitonen vorhanden?
			beq	:exit			; => Nein, Ende...

			lda	partCurPos		;Position einlesen.
			clc
			adc	#5
			cmp	partCount		;Weitere Zeile möglich?
			bcs	:exit			; => Nein, Ende...
			pha
			jsr	scrollUp		;Anzeige-Liste scrollen.
			pla
			tax
			lda	partList,x		;Partition für neue Zeile einlesen.
			sta	r3H
			LoadB	r14H,(LIST_BASE_Y +4)*8 +6
			jsr	printPartLine		;Eintrag ausgeben.
			inc	partCurPos		;Neue Position setzen.
::exit			rts

;*** Partitionsliste nach oben.
:scrollUp		LoadW	r0,LIST_BASE
			LoadW	r1,LIST_BASE +40*8

			ldx	#0			;Grafikdaten kopieren.
::1			ldy	#0
::2			lda	(r1L),y
			sta	(r0L),y
			iny
			cpy	#26*8
			bcc	:2

			lda	r1L			;Zeiger auf nächste Zeile.
			sta	r0L
			clc
			adc	#< (40*8)
			sta	r1L
			lda	r1H
			sta	r0H
			adc	#> (40*8)
			sta	r1H

			inx
			cpx	#4			;Alle Zeilen kopiert?
			bcc	:1			; => Nein, weiter...
			bcs	scrollClrLine		;Freie Zeile löschen.

;*** Partitionsliste nach unten.
:scrollDown		LoadW	r1,LIST_BASE +40*8*3
			LoadW	r0,LIST_BASE +40*8*4

			ldx	#0			;Grafikdaten kopieren.
::1			ldy	#0
::2			lda	(r1L),y
			sta	(r0L),y
			iny
			cpy	#26*8
			bcc	:2

			lda	r1L			;Zeiger auf vorherige Zeile.
			sta	r0L
			sec
			sbc	#< (40*8)
			sta	r1L
			lda	r1H
			sta	r0H
			sbc	#> (40*8)
			sta	r1H

			inx
			cpx	#4			;Alle Zeilen kopiert?
			bcc	:1			; => Nein, weiter...

:scrollClrLine		ldy	#0			;Freie Zeile löschen.
			tya
::1			sta	(r0L),y
			iny
			cpy	#26*8
			bcc	:1

			rts

;*** Partitionsdaten einlesen.
;Übergabe: XREG = Nr. in Liste.
:getPartInfo		lda	partList,x
			sta	partNr			;Partitions-Nr. speichern.
			sta	r3H
			LoadW	r4,partData
			jsr	GetPDirEntry		;Partitionsdaten einlesen.
			txa				;Laufwerksfehler?
			beq	:1			; => Nein, weiter...

::err			lda	#NULL			;Partitionsdaten löschen.
			sta	partData
			sta	partName
			sta	partType
			sta	partSize +0
			sta	partSize +1
			beq	setRegOptDName		;Option "Diskname anpassen" setzen.

;--- Partitionsname einlesen.
::1			ldy	#0			;Partitionsname einlesen und
::2			lda	partData +3,y		;dabei nach GEOS konvertieren.
			bpl	:3
			cmp	#$a0			;Ende erreicht?
			beq	:6			; => Ja, weiter...
			sec
			sbc	#128
::3			cmp	#" "
			bcc	:4
			cmp	#$7f
			bcc	:5
::4			lda	#"."
::5			sta	partName,y
			iny
			cpy	#16
			bcc	:2

::6			lda	#NULL			;Rest des Namens mit $00 füllen.
::7			sta	partName,y
			iny
			cpy	#16 +1
			bcc	:7

;--- Partitionsgröße einlesen.
			lda	partData +29		;Sonderbehandlung für 16M-Partition
			ora	partData +28		;erforderlich?
			bne	:11			; => Nein, weiter...

			lda	#$ff			;Größe auf 65535 reduzieren.
			tax
			bne	:12

::11			lda	partData +29
			ldx	partData +28
::12			sta	partSize +0		;Partitionsgröße setzen.
			stx	partSize +1

;--- Partitionstyp einlesen.
			jsr	getVecPType		;Zeiger auf Partitionstyp nach :r0.

			ldy	#0			;Partitionstyp setzen.
::21			lda	(r0L),y
			sta	partType,y
			iny
			cpy	#4
			bcc	:21

;*** Register-Option anpassen.
:setRegOptDName		lda	partData
			beq	:off
			cmp	#$05
			bcs	:off
::on			lda	#BOX_OPTION
			b $2c
::off			lda	#BOX_OPTION_VIEW	;Option "Diskname anpassen"
			sta	RegTMenu1e		;deaktivieren.

			rts

;*** Zeiger auf Partitionstyp berechnen.
;Übergabe: partData = Typ.
;Rückgabe: r0 = Zeiger auf Textstring.
:getVecPType		lda	partData		;Zeiger auf Partitionstyp
			cmp	#8			;berechnen.
			bcc	:0
			lda	#0
::0			asl
			asl
			clc
			adc	#< partTypeList
			sta	r0L
			lda	#$00
			adc	#> partTypeList
			sta	r0H
			rts

;*** Neue Partition auswählen.
:slctNewPart		bit	r1L			;Grafikaufbau?
			bmi	:select			; => Nein, weiter...
::exit			rts

::select		lda	partCount		;Partitionen vorhanden?
			beq	:exit			; => Nein, Ende...

			lda	mouseYPos		;Mauspoisition einlesen.
			sec
			sbc	#< (LIST_BASE_Y *8)
			lsr
			lsr
			lsr
			clc
			adc	partCurPos		;Angeklickten Eintrag berechnen.
			tax
			cpx	partCount		;Partition vorhanden?
			bcs	:exit			; => Nein, Abbruch...
			jsr	getPartInfo		;Partitionsdaten einlesen.
;			jmp	printPartInfo

;*** Partitionsdaten anzeigen.
:printPartInfo		LoadW	r15,RegTMenu1a		;Partition: Nr.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1b		;Partition: Name.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1c		;Partition: Typ.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1d		;Partition: Größe.
			jsr	RegisterUpdate
			LoadW	r15,RegTMenu1e		;Option: Diskname anpassen.
			jmp	RegisterUpdate

;*** Partition umbenennen.
:renamePart		lda	partData		;Typ = 0?
			beq	:err			; => Ja, Abbruch...
			cmp	#$08			;Partitionstyp gültig?
			bcs	:err			; => Nein, Abbruch...

			lda	partNr			;Partitions-Nr. einlesen/setzen.
			sta	r3H
			LoadW	r4,partData
			jsr	GetPDirEntry		;Partitionsdaten einlesen.
			txa				;Laufwerksfehler?
			beq	:rename			; => Nein, weiter...
::err			rts

::rename		ldy	#0			;Neuen Partitionsnamen für
::1			lda	partName,y		;"R-P" und "R-H" übernehmen.
			beq	:2
			sta	com_RP +4,y
			sta	com_RH +7,y
			iny
			cpy	#16
			bcc	:1
::2			lda	#"="
			sta	com_RP +4,y

			tya
			clc
			adc	#7
			sta	com_RH_len		;Befehlslänge "R-H" setzen.

			iny
			lda	#NULL
			sta	com_RH +7,y

			ldx	#0			;Original Partitionsname für
::3			lda	partData +3,x		;"R-P"-Befehl übernehmen.
			cmp	#$a0
			beq	:4
			sta	com_RP +4,y
			iny
			inx
			cpx	#16
			bcc	:3
::4			lda	#NULL
			sta	com_RP +4,y

			tya
			clc
			adc	#4
			sta	com_RP_len

			ldy	#"0"			;Partitionsnummer nach ASCII
			ldx	#"0"			;wandeln (für "R-H"-Befehl).

			lda	r3H
::11			cmp	#100
			bcc	:12
;			sec
			sbc	#100
			iny
			bne	:11
::12			cmp	#10
			bcc	:13
;			sec
			sbc	#10
			inx
			bne	:12
::13			clc
			adc	#"0"

			sty	com_RH +3		;Partitions-Nr. setzen.
			stx	com_RH +4
			sta	com_RH +5

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			LoadW	r0,com_RP
			lda	com_RP_len
			sta	r2L
			jsr	SendCommand		;"R-P" = Rename Partition.
			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			bit	partSetDName		;Diskname/Header anpassen?
			bpl	:21			; => Nein, weiter...

			lda	partData		;Partitionstyp einlesen.
			cmp	#$05			;Typ = 1-4?
			bcs	:21			; => Nein, Header nicht ändern...

			LoadW	r0,com_RH
			lda	com_RH_len
			sta	r2L
			jsr	SendCommand		;"R-H" = Rename Header.
			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

::21			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			ldx	curDrive		;Name aktuelle Partition geändert?
			lda	partNr
			cmp	drivePartData -8,x
			bne	:22			; => Nein, weiter...
			jsr	OpenDisk		;Diskette/Partition initialisieren.

::22			jsr	printPartList		;Partitionsliste aktualisieren.
			jsr	printPartInfo		;Partitionsdaten aktualisieren.

			jmp	setReloadDir		;GeoDesk: Verzeichnis neu laden.

;*** Variablen.
:partCount		b $00
:partCurPos		b $00
:partMax		b $00
:partData		s 32

:partError		b "Keine Partitionen",NULL

:partNr			b 254
:partName		b "Test"
			e partName +17
:partType		b "NATM"
			e partType +5
:partSize		w $ffff
:partSetDName		b %10000000

:partTypeList		b "????"
			b "1541"
			b "1571"
			b "1581"
			b "NATM"
			b "CP/M"
			b "PRNT"
			b "DACC"
			b NULL

:com_RP_len		b $00
:com_RP			b "R-P:"
			b "1234567890123456"
			b "="
			b "1234567890123456"
			b NULL

:com_RH_len		b $00
:com_RH			b "R-H000:"
			b "1234567890123456"
			b NULL

;*** Reservierter Speicher.
;Hinweis: Der reservierte Speicher ist
;nicht initialisiert!
:sysMemA

:partList_S		= 256
:partList		= sysMemA

:sysMemE		= partList + partList_S
:sysMemS		= (sysMemE - sysMemA)

;*** Endadresse testen:
			g RegMenuBase - sysMemS
;***
