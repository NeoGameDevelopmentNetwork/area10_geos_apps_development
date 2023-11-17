; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemzeit setzen.
:xSYSTIME		jsr	copySystemTime

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			lda	exitCode
			cmp	#$7f			;Systemzeit setzen?
			bne	:1			; => Nein, Ende...

			jsr	setSystemTime		;Systemzeit setzen.

::1			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Disk löschen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $40
:R1SizeY1		= $7f
:R1SizeX0		= $0048
:R1SizeX1		= $00ef

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RTabName1_1			;Register: "UHRZEIT".
			w RTabMenu1_1

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

;*** Icon "Uhrzeit setzen".
:RIcon_SetTime		w IconSetTime
			b $00,$00
			b IconSetTime_x,IconSetTime_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "SYSTEMZEIT".
:DIGIT_2_BYTE = $02 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RWidth1  = $0038
:RLine1_1 = $00
:RLine1_2 = $10

:RTabMenu1_1		b 7

			b BOX_ICON			;----------------------------------------
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_SetTime
				b $00

			b BOX_NUMERIC			;----------------------------------------
				w R1T01
				w chkTimeHour
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1
				w varHour
				b DIGIT_2_BYTE
			b BOX_NUMERIC			;----------------------------------------
				w R1T01a
				w chkTimeMinute
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1 +$18
				w varMinute
				b DIGIT_2_BYTE
			b BOX_NUMERIC			;----------------------------------------
				w R1T01b
				w chkTimeSecond
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1 +$30
				w varSecond
				b DIGIT_2_BYTE

			b BOX_NUMERIC			;----------------------------------------
				w R1T02
				w chkDateDay
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1
				w varDay
				b DIGIT_2_BYTE
			b BOX_NUMERIC			;----------------------------------------
				w R1T02a
				w chkDateMonth
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$18
				w varMonth
				b DIGIT_2_BYTE
			b BOX_NUMERIC			;----------------------------------------
				w R1T02b
				w chkDateYear
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1 +$30
				w varYear
				b $04 ! NUMERIC_LEFT ! NUMERIC_WORD

if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Uhrzeit"
			b GOTOXY
			w R1SizeX0 +$10 +$18
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

;*** Icons für Registerkarten.
:RTabIcon1
if LANG = LANG_DE
<MISSING_IMAGE_DATA>

endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>

endif

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** Register-Funktions-Icons.
:IconSetTime
<MISSING_IMAGE_DATA>

:IconSetTime_x		= .x
:IconSetTime_y		= .y
