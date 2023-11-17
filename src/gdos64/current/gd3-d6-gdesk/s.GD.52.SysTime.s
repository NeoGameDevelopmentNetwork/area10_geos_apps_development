; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Systemzeit setzen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_RLNK"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"
endif

;*** GEOS-Header.
			n "obj.GD52"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSYSTIME

;*** Systemroutinen.
			t "-SYS_DISKFILE"

;*** Systemzeit setzen.
:xSYSTIME		jsr	copySystemTime

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode
			cmp	#$7f			;Systemzeit setzen?
			bne	:1			; => Nein, Ende...

			jsr	setSystemTime		;Systemzeit setzen.

;--- Hinweis:
;":MOD_UPDATE" lädt den WindowManager
;bei der Rückkehr zum Menü, da dieser
;durch das Register-Menü teilweise
;überschrieben wurde.
;":MOD_RESTART" startet den im Speicher
;befindlichen WindowMmanager neu.
;::1			jmp	MOD_RESTART
::1			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Disk löschen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Register-Menü.
:R1SizeY0		= $40
:R1SizeY1		= $7f
:R1SizeX0		= $0048
:R1SizeX1		= $00ef

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "UHRZEIT".
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

;*** Icon "Uhrzeit setzen".
:RIcon_SetTime		w Icon_SetTime
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SetTime_x,Icon_SetTime_y
			b USE_COLOR_INPUT

;*** Register-Funktions-Icons.
:Icon_SetTime
<MISSING_IMAGE_DATA>

:Icon_SetTime_x		= .x
:Icon_SetTime_y		= .y

;*** Daten für Register "SYSTEMZEIT".
:DIGIT_2_BYTE = $02 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RWidth1  = $0038
:RLine1_1 = $00
:RLine1_2 = $10

:RegTMenu1		b 7

			b BOX_ICON
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_SetTime
				b NO_OPT_UPDATE

			b BOX_NUMERIC
				w R1T01
				w chkTimeHour
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1
				w varHour
				b DIGIT_2_BYTE
			b BOX_NUMERIC
				w R1T01a
				w chkTimeMinute
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1 +$18
				w varMinute
				b DIGIT_2_BYTE
			b BOX_NUMERIC
				w R1T01b
				w chkTimeSecond
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1 +$30
				w varSecond
				b DIGIT_2_BYTE

			b BOX_NUMERIC
				w R1T02
				w chkDateDay
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1
				w varDay
				b DIGIT_2_BYTE
			b BOX_NUMERIC
				w R1T02a
				w chkDateMonth
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$18
				w varMonth
				b DIGIT_2_BYTE
			b BOX_NUMERIC
				w R1T02b
				w chkDateYear
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$30
				w varYear
				b $04 ! NUMERIC_LEFT ! NUMERIC_WORD

;*** Texte für Register "SYSTEMZEIT".
if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Uhrzeit"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "setzen",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Uhrzeit:",NULL
:R1T01a			w RPos1_x +RWidth1 +$12
			b RPos1_y +RLine1_1 +$06
			b ":",NULL
:R1T01b			w RPos1_x +RWidth1 +$18 +$12
			b RPos1_y +RLine1_1 +$06
			b ":",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Datum:",NULL
:R1T02a			w RPos1_x +RWidth1 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
:R1T02b			w RPos1_x +RWidth1 +$18 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Set date"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "and time",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Time:",NULL
:R1T01a			w RPos1_x +RWidth1 +$12
			b RPos1_y +RLine1_1 +$06
			b ":",NULL
:R1T01b			w RPos1_x +RWidth1 +$18 +$12
			b RPos1_y +RLine1_1 +$06
			b ":",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_2 +$06
			b "Date:",NULL
:R1T02a			w RPos1_x +RWidth1 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
:R1T02b			w RPos1_x +RWidth1 +$18 +$12
			b RPos1_y +RLine1_2 +$06
			b ".",NULL
endif

;*** Systemzeit kopieren.
:copySystemTime		lda	hour			;Stunde einlesen und
			sta	varHour			;in Zwischenspeicher schreiben.
			jsr	chkTimeHour		;Stunde auf Gültigkeit testen.

			lda	minutes			;Minute einlesen und
			sta	varMinute		;in Zwischenspeicher schreiben.
			jsr	chkTimeMinute		;Minute auf Gültigkeit testen.

			lda	seconds			;Sekunde einlesen und
			sta	varSecond		;in Zwischenspeicher schreiben.
			jsr	chkTimeSecond		;Sekunde auf Gültigkeit testen.

			lda	day			;Tag einlesen und
			sta	varDay			;in Zwischenspeicher schreiben.
			jsr	chkDateDay		;Tag auf Gültigkeit testen.

			lda	month			;Monat einlesen und
			sta	varMonth		;in Zwischenspeicher schreiben.
			jsr	chkDateMonth		;Monat auf Gültigkeit testen.

			lda	millenium		;Jahr von 2-Byte-Wert in
			sta	r0L			;Dezimalzahl umrechnen.
			LoadB	r1L,100
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			lda	r0L
			clc
			adc	year			;Jahr einlesen und
			sta	varYear +0		;in Zwischenspeicher schreiben.
			lda	r0H
			adc	#$00
			sta	varYear +1
			jsr	chkDateYear		;Jahr auf Gültigkeit testen.

			rts

;*** Neue Uhrzeit setzen.
:setSystemTime		jsr	InitForIO		;I/O-Bereich einblenden.

			MoveW	varYear,r0		;Jahr von Dezimalzahl in
			LoadW	r1,100			;2-Byte-Wert umrechnen.
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L			;Jahr/Millenium übernehmen.
			sta	millenium
			lda	r8L
			sta	year

			lda	varMonth		;Monat übernehmen.
			sta	month

			lda	varDay			;Tag übernehmen.
			sta	day

			lda	varHour			;Stunde nach BCD wandeln.
			sta	hour
			jsr	DEZtoBCD
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:102
			sbc	#$12
			ora	#%10000000
::102			tax
			lda	cia1tod_h		;Uhrzeit anhalten.
			ldy	cia1tod_t
			txa
			sta	cia1tod_h		;Stunde setzen.
			cld

			lda	varMinute
			sta	minutes
			jsr	DEZtoBCD		;Minute nach BCD wandeln.
			sta	cia1tod_m		;Minute setzen.

			lda	varSecond
			sta	seconds
			jsr	DEZtoBCD		;Sekunde nach BCD wandeln.
			sta	cia1tod_s		;Sekunde setzen.

			ClrB	cia1tod_t		;Uhrzeit starten.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Dezimal nach BCD.
:DEZtoBCD		ldx	#0
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			sta	r0L
			txa
			asl
			asl
			asl
			asl
			ora	r0L
			rts

;*** Datum auf Gültigkeit testen.
:chkDateDay		lda	varDay			;Tag einlesen.
			beq	:1			; => Tag ungültig...

			cmp	#31 +1			;Tag > 31?
			bcc	:2			; => Nein, weiter...

			lda	#31			;max.Wert für Tag setzen.
			b $2c
::1			lda	#1			;min.Wert für Tag setzen.
			sta	varDay			;Korrigierter Wert für Tag.
::2			rts

:chkDateMonth		lda	varMonth		;Monat einlesen.
			beq	:1			; => Monat ungültig...

			cmp	#12 +1			;Monat > 12?
			bcc	:2			; => Nein, weiter...

			lda	#12			;max.Wert für Monat setzen.
			b $2c
::1			lda	#1			;min.Wert für Monat setzen.
			sta	varMonth		;Korrigierter Wert für Monat.
::2			rts

:chkDateYear		lda	varYear +1		;Jahr einlesen.
			cmp	#>1980			;Jahr > 1980 ?
			beq	:1			; => Vielleicht...
			bcs	:3			; => Ja, weiter...
			bcc	:2			; => Nein, Jahr zurücksetzen.

::1			lda	varYear +0
			cmp	#<1980
			bcs	:3

::2			LoadW	varYear,1980		;Default für Jahr setzen.

::3			rts

;*** Uhrzeit auf Gültigkeit testen.
:chkTimeHour		lda	varHour			;Stunde einlesen.
			cmp	#23 +1			;Stunde > 23?
			bcc	:1			; => Nein, weiter...

			lda	#23			;max.Wert für Stunde setzen.
			sta	varHour			;Korrigierter Wert für Stunde.

::1			rts

:chkTimeMinute		lda	varMinute		;Minute einlesen.
			cmp	#59 +1			;Minute > 59?
			bcc	:1

			lda	#59			;max.Wert für Minute setzen.
			sta	varMinute		;Korrigierter Wert für Minute.

::1			rts

:chkTimeSecond		lda	varSecond		;Sekunde einlesen.
			cmp	#59 +1			;Sekunde > 59?
			bcc	:1

			lda	#59			;max.Wert für Sekunde setzen.
			sta	varSecond		;Korrigierter Wert für Sekunde.

::1			rts

;*** Variablen.
:varHour		b $00
:varMinute		b $00
:varSecond		b $00
:varDay			b $00
:varMonth		b $00
:varYear		w $0000

;*** Endadresse testen:
			g BASE_DIRDATA
;***
