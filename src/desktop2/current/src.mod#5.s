; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Source code for DESK TOP V2
;
; Reassembled (w)2020-2023:
;   Markus Kanet
;
; Original authors:
;   Brian Dougherty
;   Doug Fults
;   Jim Defrisco
;   Tony Requist
; (c)1986,1988 Berkeley Softworks
;
; Revision V1.0
; Date: 23/03/25
;
; History:
; V0.1 - Initial reassembled code.
;
; V0.2 - Initial code analysis.
;
; V0.3 - Source code analysis complete.
;
; V0.4 - Added english translation.
;
; V1.0 - Updated to V2.1.
;

if .p
			t "TopSym"
;			t "TopMac"
			t "src.DESKTOP.ext"
			t "lang.DESKTOP.ext"
endif

if LANG = LANG_DE
:OFF_DAY   = 0
:OFF_MONTH = 3
:OFF_YEAR  = 6
endif
if LANG = LANG_EN
:OFF_DAY   = 3
:OFF_MONTH = 0
:OFF_YEAR  = 6
endif

			n "obj.mod#5"
			o vlirModBase

;*** Sprungtabelle.
:vlirJumpTab		jmp	doSetClock		;Options/Set clock.
			jmp	doWarnDTop		;DeskTop/GEOS V2.
			jmp	doShortCuts		;Options/ShortCuts.
			jmp	doInfoGEOS		;Info/GEOS.
			jmp	doInfoDTop		;Info/DeskTop.

;*** Uhrzeit setzen.
:doSetClock		jsr	MouseOff

			php
			sei

			jsr	blockProcClock

			lda	keyVector +1
			sta	bufKeyVec +1
			lda	keyVector +0
			sta	bufKeyVec +0

			lda	#> chkKeyBoard
			sta	keyVector +1
			lda	#< chkKeyBoard
			sta	keyVector +0

			lda	#$ff
			sta	flagCrsrMode

			jsr	resetCursor

			lda	#$ff
			sta	flagUpdClock

			plp
			rts

;*** Cursor-Position zurücksetzen.
:resetCursor		lda	#> POS_CLOCK_DATE
			sta	bufXPos +1
			lda	#< POS_CLOCK_DATE
			sta	bufXPos +0

			lda	#$00
			sta	editClockPos

if LANG = LANG_DE
			lda	stringCurDate +OFF_DAY +0
			sta	charCursor
endif
if LANG = LANG_EN
			lda	stringCurDate +OFF_MONTH +0
			sta	charCursor
endif

			jmp	invertCursor

;*** Tastaturabfrage.
:chkKeyBoard		lda	keyData
			cmp	#CR
			bne	:1

;--- Hinweis:
;Wird die Eingabe beendet wenn man den
;Monat auf einen neuen Wert gesetzt
;hat, dann gibt es keine Prüfung ob der
;aktuelle Tag gültig ist. Das erlaubt
;11/31/yy als Datum.
;Der folgende Code setzt den Cursor auf
;den Tag und testet den aktuellen Wert
;bevor dieser übernommen wird.
if FALSE
			lda	#OFF_DAY
			sta	editClockPos
			lda	stringCurDate +OFF_DAY +0
			sta	bufCurCharNum
			jsr	setClkDay1
endif
			jmp	exitSetClock

::1			cmp	#" "			;SPACE?
			bne	:2
			jmp	moveCrsrRight

::2			cmp	#KEY_DELETE
			bne	:3
			jmp	moveCrsrLeft

::3			cmp	#KEY_RIGHT
			bne	:4
			jmp	moveCrsrRight

::4			cmp	#KEY_LEFT
			bne	:cont
			jmp	moveCrsrLeft

;--- AM/PM-Flag für 12h-Format.
if LANG = LANG_DE
::cont
endif
if LANG = LANG_EN
::cont			cmp	#"a"
			bne	:pm
			lda	#"A"
			bne	:5
::pm			cmp	#"p"
			bne	:5
			lda	#"P"
endif

::5			sta	bufCurCharNum

if LANG = LANG_EN
			ldx	editClockPos
			cpx	#16
			bne	:num
			cmp	#"A"
			beq	:set
			cmp	#"P"
			beq	:set
endif

::num			sec
			sbc	#"0"
			bmi	:exit
			cmp	#10
			bpl	:exit

::set			jmp	execSetValues

::exit			rts

;*** Zahleneingabe auswerten.
:execSetValues		lda	#> tabSetValues
			sta	r0H
			lda	#< tabSetValues
			sta	r0L

			lda	editClockPos
			asl
			asl
			sta	r1L

;			lda	r1L
			clc
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H
::1			jmp	(r0)

;*** Eingabefelder Datum/Uhrzeit.
;Der Einsprung in diese Tabelle wird
;berechnet. Dazu wird ein Zeiger mit
;4 multipliziert und zur Startadresse
;der Tabelle addiert.
;Das Ergebnis wird dann für einen
;indirekten JMP-Befehl verwendet.
:tabSetValues

if LANG = LANG_DE
			jmp	setClkDay1		;Tag.
			nop
			jmp	setClkDay2
			nop
endif
if LANG = LANG_EN
			jmp	setClkMon1		;Monat.
			nop
			jmp	setClkMon2
			nop
endif

			jmp	:skip			;Überspringen...
			nop

if LANG = LANG_DE
			jmp	setClkMon1		;Monat.
			nop
			jmp	setClkMon2
			nop
endif
if LANG = LANG_EN
			jmp	setClkDay1		;Tag.
			nop
			jmp	setClkDay2
			nop
endif

			jmp	:skip			;Überspringen...
			nop

			jmp	setClkYear1		;Jahr.
			nop
			jmp	setClkYear2
			nop

			jmp	:skip			;Überspringen...
			nop
			jmp	:skip			;Überspringen...
			nop

			jmp	setClkHour1		;Stunde.
			nop
			jmp	setClkHour2
			nop

			jmp	:skip			;Überspringen...
			nop

			jmp	setClkMin1		;Minute.
			nop
			jmp	setClkMin2

if LANG = LANG_EN
			nop

			jmp	:skip			;Überspringen...
			nop

			jmp	setClkAMPM		;AM/PM-Flag setzen.
endif

::skip			rts

;*** Zeit aktualisieren.
:updateTime		jsr	invertCursor
			jmp	prntCurTime

;*** Datum aktualisieren.
:updateDate		jsr	invertCursor
			jmp	prntCurDate

;*** Erste Ziffer Monat eingeben.
:setClkMon1		lda	bufCurCharNum
			tax
			cpx	#"1"			;Monat 11/12 ?
			beq	:1			; => Ja, weiter...
			cpx	#"0"			;Monat 1-9 ?
			bne	:exit			; => Ungültig...

			cpx	stringCurDate +OFF_MONTH +1
			bne	:1

;--- Monat = 00, dann auf 01 ändern.
			pha
			lda	#"1"
			sta	stringCurDate +OFF_MONTH +1
			pla

;--- Eingabe setzen.
::1			sta	stringCurDate +OFF_MONTH +0

			jsr	updateDate		;Datum aktualisieren.
			jsr	setNxEditPos

;--- Zweite Ziffer Monat prüfen.
			lda	stringCurDate +OFF_MONTH +0
			cmp	#"0"
			beq	:exit

			lda	#"2"
			cmp	stringCurDate +OFF_MONTH +1
			bcs	:exit
			sta	stringCurDate +OFF_MONTH +1

;--- Zweite Ziffer war ungültig...
			jsr	updateDate		;Datum aktualisieren.
			jmp	invertCursor

::exit			rts

;*** Zweite Ziffer Monat eingeben.
:setClkMon2		lda	stringCurDate  +OFF_MONTH +0
			cmp	#"0"			;Monat 1-9?
			beq	:0			; => Ja, weiter...

			lda	bufCurCharNum
			cmp	#"3"			;Monat > 12?
			bcs	:exit			; => Ja, Ende...
			bcc	:1

::0			lda	bufCurCharNum
			cmp	#"0"			;Monat 00?
			beq	:exit			; => Ja, Ende...

;--- Eingabe setzen.
::1			sta	stringCurDate +OFF_MONTH +1

			jsr	updateDate		;Datum aktualisieren.
			jmp	setNxEditPos

::exit			rts

;*** Erste Ziffer Tag eingeben.
:setClkDay1		lda	#"0"			;Tag = 00?
			cmp	bufCurCharNum
			bne	:1			; => Nein, weiter...
			cmp	stringCurDate +OFF_DAY +1
			bne	:1

;--- Tag = 00, dann auf 01 ändern.
			lda	#"1"
			sta	stringCurDate +OFF_DAY +1

;--- Max. Anzahl Tage/Monat testen.
::1			lda	stringCurDate +OFF_MONTH +1
			ldx	stringCurDate +OFF_MONTH +0
			jsr	convASCII2Dez
			tax
			dex
			lda	tabDayMaxH,x
			cmp	bufCurCharNum
			bmi	:exit			;Zahl ungültig...
			beq	:2			;Zweite Ziffer?
			bcs	:ok

;--- Zweite Ziffer Tag prüfen.
::2			lda	tabDayMaxL,x
			cmp	stringCurDate +OFF_DAY +1
			bpl	:ok			; => Ok, weiter...

;--- Zweite Ziffer war ungültig...
			lda	#"0"
			sta	stringCurDate +OFF_DAY +1

;--- Eingabe setzen.
::ok			lda	bufCurCharNum
			sta	stringCurDate +OFF_DAY +0

			jsr	updateDate		;Datum aktualisieren.
			jmp	setNxEditPos

::exit			rts

;*** Max. Anzahl Tage / Monat, erste Ziffer.
:tabDayMaxH		b "3"				;Jan.
			b "2"				;Feb.
			b "3"				;...
			b "3"
			b "3"
			b "3"
			b "3"
			b "3"
			b "3"
			b "3"				;...
			b "3"				;Nov.
			b "3"				;Dez.

;*** Zweite Ziffer Tag eingeben.
:setClkDay2		lda	stringCurDate +OFF_MONTH +1
			ldx	stringCurDate +OFF_MONTH +0
			jsr	convASCII2Dez
			tax
			dex
			lda	tabDayMaxH,x
			cmp	stringCurDate +OFF_DAY +0
			bne	:1

;--- Zweite Ziffer Tag prüfen.
			lda	tabDayMaxL,x
			cmp	bufCurCharNum
			bmi	:exit
			jmp	:ok

::1			lda	stringCurDate +OFF_DAY +0
			cmp	#"0"			;Tag 1-9?
			bne	:ok			; => Nein, weiter...
			lda	bufCurCharNum
			cmp	#"0"			;Tag = 00?
			beq	:exit			; => Ja, Ende...

;--- Eingabe setzen.
::ok			lda	bufCurCharNum
			sta	stringCurDate +OFF_DAY +1

			jsr	updateDate		;Datum aktualisieren.
			jmp	setNxEditPos

::exit			rts

;*** Max. Anzahl Tage / Monat, zweite Ziffer.
:tabDayMaxL		b "1"				;Jan.
			b "9"				;Feb.
			b "1"				;...
			b "0"
			b "1"
			b "0"
			b "1"
			b "1"
			b "0"
			b "1"				;...
			b "0"				;Nov.
			b "1"				;Dez.

;*** Erste Ziffer Jahr eingeben.
:setClkYear1		lda	bufCurCharNum
			sta	stringCurDate +OFF_YEAR +0

			jsr	updateDate		;Datum aktualisieren.
			jmp	setNxEditPos

;*** Zweite Ziffer Jahr eingeben.
:setClkYear2		lda	bufCurCharNum
			sta	stringCurDate +OFF_YEAR +1

			jsr	updateDate		;Datum aktualisieren.
			jmp	setNxEditPos

;*** 24h-Format: Erste Ziffer Stunde setzen.
if LANG = LANG_DE
:setClkHour1		lda	bufCurCharNum
			cmp	#"3"			;Stunde 0x-2x?
			bpl	:exit			; => Nein, Ende...

			sta	stringCurTime +0

			jsr	updateTime		;Zeit aktualisieren.
			jsr	setNxEditPos

			lda	stringCurTime +0
			cmp	#"2"			;Stunde 20-23?
			bne	:exit			; => Nein, Ende...

;--- Zweite Ziffer Stunde prüfen.
			lda	stringCurTime +1
			cmp	#"4"			;Stunde < 24?
			bcc	:exit			; => Ja, Ende...

			lda	#"0"

;--- Zweite Ziffer war ungültig...
			sta	stringCurTime +1

			jsr	updateTime		;Zeit aktualisieren.
			jmp	invertCursor

::exit			rts

;*** 24h-Format: Zweite Ziffer Stunde setzen.
:setClkHour2		lda	stringCurTime
			cmp	#"2"			;Stunde >= 20?
			php
			lda	bufCurCharNum
			plp
			bne	:1			; => Nein, weiter...
			cmp	#"4"			;Stunde > 23?
			bcs	:exit			; => Ja, Ende...

;--- Eingabe setzen.
::1			sta	stringCurTime +1

			jsr	updateTime		;Zeit aktualisieren.
			jmp	setNxEditPos

::exit			rts
endif

;*** 12h-Format: Erste Ziffer Stunde setzen.
if LANG = LANG_EN
:setClkHour1		lda	bufCurCharNum
			cmp	#"2"			;Stunde 0x-1x?
			bpl	:exit			; => Nein, Ende...
			cmp	#"1"
			beq	:1

			cmp	stringCurTime +1
			bne	:1

			ldx	#"1"
			stx	stringCurTime +1

::1			sta	stringCurTime +0

			jsr	updateTime		;Zeit aktualisieren.
			jsr	setNxEditPos

			lda	stringCurTime +0
			cmp	#"0"			;Stunde 00-09?
			beq	:exit			; => Ja, Ende...

;--- Zweite Ziffer Stunde prüfen.
			lda	#"2"			;Stunde > 12?
			cmp	stringCurTime +1
			bcs	:exit			; => Ja, Ende...

;--- Zweite Ziffer war ungültig...
			sta	stringCurTime +1

			jsr	updateTime		;Zeit aktualisieren.
			jmp	invertCursor

::exit			rts

;*** 12h-Format: Zweite Ziffer Stunde setzen.
:setClkHour2		lda	stringCurTime +0
			cmp	#"0"			;Stunde = 00?
			bne	:1			; => Nein, weiter...

			lda	bufCurCharNum
			cmp	#"0"			;Stunde = 00?
			bne	:set			; => Ja, Ende...
::exit			rts

::1			lda	bufCurCharNum
			cmp	#"3"
			bpl	:exit

;--- Eingabe setzen.
::set			sta	stringCurTime +1

			jsr	updateTime		;Zeit aktualisieren.
			jmp	setNxEditPos
endif

;*** Erste Ziffer Minute setzen.
:setClkMin1		lda	bufCurCharNum
			cmp	#"6"			;Minute >= 60?
			bpl	:exit			; => Ja, Ende...

;--- Eingabe setzen.
			sta	stringCurTime +3

			jsr	updateTime		;Zeit aktualisieren.
			jmp	setNxEditPos

::exit			rts

;*** Zweite Ziffer Minute setzen.
:setClkMin2		lda	bufCurCharNum
			sta	stringCurTime +4

			jsr	updateTime		;Zeit aktualisieren.
			jmp	setNxEditPos

if LANG = LANG_EN
;*** AM/PM-Flag setzen.
:setClkAMPM		lda	bufCurCharNum
			cmp	#"A"
			beq	:set
			cmp	#"P"
			beq	:set
::exit			rts

::set			sta	stringCurTime +6
			jsr	updateTime		;Zeit aktualisieren.
			jmp	setNxEditPos
endif

;*** Cursor nach rechts bewegen.
:moveCrsrRight		jsr	invertCursor

:setNxEditPos		ldx	editClockPos
			lda	tabMvCrsrRight,x
			bpl	:init

			jsr	resetCursor
			clv
			bvc	:exit

::init			tay

::loop			tya
			pha
			lda	stringCurDate,x
			jsr	GetCharWidth
			clc
			adc	bufXPos +0
			sta	bufXPos +0
			bcc	:1
			inc	bufXPos +1
::1			inx
			pla
			tay
			dey
			bne	:loop

			stx	editClockPos

			cpx	#10
			bne	:2

			lda	#> POS_CLOCK_TIME
			sta	bufXPos +1
			lda	#< POS_CLOCK_TIME
			sta	bufXPos +0

::2			ldx	editClockPos
			lda	stringCurDate,x
			sta	charCursor
			jmp	invertCursor

::exit			rts

;*** Abstand von akt. Position bis zur nächsten Position.
:tabMvCrsrRight
::00h			b $01				;Tag1  -> Tag2.
::01h			b $02				;Tag2  -> Skip  -> Mon1.
::02h			b $01				;Skip  -> Mon1.
::03h			b $01				;Mon1  -> Mon2.
::04h			b $02				;Mon2  -> Skip  -> Jahr1.
::05h			b $01				;Skip  -> Jahr1.
::06h			b $01				;Jahr1 -> Jahr2.
::07h			b $03				;Jahr2 -> Skip2 -> Std1.
::08h			b $02				;Skip2 -> Std1.
::09h			b $01				;Skip  -> Std1.
::0ah			b $01				;Std1  -> Std2.
::0bh			b $02				;Std2  -> Skip  -> Min1.
::0ch			b $01				;Skip  -> Min1.
::0dh			b $01				;Min1  -> Min2.

;--- Beim ersten negativen Wert den
;    Cursor zurücksetzen.
if LANG = LANG_DE
::0eh			b $f2				;Überreste von AM/PM-Flag.
::0fh			b $f1				;Entfällt bei 24h-Anzeige.
endif
if LANG = LANG_EN
::0eh			b $02				;Min2  -> Skip  -> AM/PM.
::0fh			b $01				;Skip  -> AM/PM.
endif

::10h			b $f0

;--- Wird auch mit AM/PM nicht erreicht.
if LANG = LANG_EN
::11h			b $ef				;Evtl. Überreste aus der Anzeige
::12h			b $ee				;von HH:MM:SS AM/PM?
::13h			b $ed
endif

;*** Abstand von akt. Position bis zur letzen Position.
:tabMvCrsrLeft
if LANG = LANG_DE
::00h			b $0e				;Tag1  -> Min2.
endif
if LANG = LANG_EN
::00h			b $10				;Tag1  -> AM/PM.
endif
::01h			b $ff				;Tag2  -> Tag1.
::02h			b $ff				;Skip  -> Tag2.
::03h			b $fe				;Mon1  -> Skip  -> Tag2.
::04h			b $ff				;Mon2  -> Mon1.
::05h			b $ff				;Skip  -> Mon2.
::06h			b $fe				;Jahr1 -> Skip  -> Mon2.
::07h			b $ff				;Jahr2 -> Jahr1.
::08h			b $ff				;Skip  -> Jahr2.
::09h			b $fe				;Skip2 -> Jahr2.
::0ah			b $fd				;Std1  -> Skip2 -> Jahr2.
::0bh			b $ff				;Std2  -> Std1.
::0ch			b $ff				;Skip  -> Std2.
::0dh			b $fe				;Min1  -> Skip  -> Std2.
::0eh			b $ff				;Min2  -> Min1.

;--- Wird ohne AM/PM nicht erreicht.
::0fh			b $ff				;Überreste von AM/PM-Flag.
::10h			b $fe				;Entfällt bei 24h-Anzeige.

;--- Wird auch mit AM/PM nicht erreicht.
if LANG = LANG_EN
::11h			b $ff				;Evtl. Überreste aus der Anzeige
::12h			b $fe				;von HH:MM:SS AM/PM?
::13h			b $fd
endif

;*** Cursor nach links bewegen.
:moveCrsrLeft		jsr	invertCursor

			lda	editClockPos
			tax
			clc
			adc	tabMvCrsrLeft,x
			sta	tmpNewClkPos

			lda	#$00
			sta	flagCrsrMode

;--- Cursor ganz nach links setzen.
			jsr	resetCursor

;--- Cursor nach rechts bis neue Position gefunden.
::search		jsr	setNxEditPos

			lda	editClockPos
			cmp	tmpNewClkPos
			bne	:search

			lda	#$ff
			sta	flagCrsrMode

;*** Zeichen unter "Cursor" invertieren.
:invertCursor		lda	flagCrsrMode
			beq	:exit

			php
			sei

			lda	CPU_DATA
			pha
			lda	#RAM_64K
			sta	CPU_DATA

			lda	#AREA_CLOCK_Y0 +2
			sta	r2L
			lda	#AREA_CLOCK_Y0 +10
			sta	r2H

			lda	bufXPos +0		;X-Koordinate links.
			sta	r3L
			sta	r4L
			lda	bufXPos +1
			sta	r3H
			sta	r4H

			ldx	editClockPos		;Nicht verwendet?
			lda	charCursor		;Zeichencode.
			jsr	GetCharWidth

			clc				;X-Koordinate rechts.
			adc	r4L
			sta	r4L
			bcc	:1
			inc	r4H

::1			jsr	InvertRectangle

			pla
			sta	CPU_DATA

			plp
::exit			rts

;*** Uhrzeit setzen.
:exitSetClock		php
			sei

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	cia1base +15
			and	#$7f
			sta	cia1base +15

;--- Uhrzeit nach BCD wandeln.
			jsr	convertTimeBCD

;--- Stunde.
			lda	r1L			;Uhrzeit vom 24H-
if LANG = LANG_DE
			cmp	#$13			;Format nach 12h-
			bcc	:1			;Format wandeln und
			sed				;AM/PM-Flag setzen.
			sec
			sbc	#$12
			cld
endif
if LANG = LANG_EN
			cmp	#$12			;Format nach 12h-
			bne	:0			;Format wandeln und
			lda	#$00			;AM/PM-Flag setzen.
::0			ldx	stringCurTime +6
			cpx	#"A"
			beq	:1
endif
			ora	#%10000000		;AM/PM-Flag.
::1			sta	cia1base +11

if LANG = LANG_DE
			lda	r1L
endif
if LANG = LANG_EN
			bit	cia1base +11
			bpl	:2
			sed
			clc
			adc	#$12
			cld
endif
::2			jsr	convBCD2Dez
			sta	hour

;--- Minute.
			lda	r1H
			sta	cia1base +10

			jsr	convBCD2Dez
			sta	minutes

;--- Sekunde löschen.
			lda	#$00
			sta	cia1base +9
			sta	seconds
			sta	cia1base +8

			pla
			sta	CPU_DATA

;--- Monat.
			ldy	#$00
			ldx	stringCurDate +OFF_MONTH +0
			lda	stringCurDate +OFF_MONTH +1
			jsr	convASCII2Dez
			sta	month

;--- Tag.
			iny
			ldx	stringCurDate +OFF_DAY +0
			lda	stringCurDate +OFF_DAY +1
			jsr	convASCII2Dez
			sta	day

;--- Jahr.
			iny
			ldx	stringCurDate +OFF_YEAR +0
			lda	stringCurDate +OFF_YEAR +1
			jsr	convASCII2Dez
			sta	year

			jsr	invertCursor

			lda	bufKeyVec +1
			sta	keyVector +1
			lda	bufKeyVec +0
			sta	keyVector +0

			lda	#$00
			sta	flagUpdClock

			jsr	updateProcClock

			jsr	MouseUp

			plp
			rts

;*** Text für Uhrzeit nach BCD wandeln.
:convertTimeBCD		ldx	stringCurTime +0
			lda	stringCurTime +1
			jsr	convASCII2BCD
			sta	r1L

			ldx	stringCurTime +3
			lda	stringCurTime +4
			jsr	convASCII2BCD
			sta	r1H
			rts

;*** Zahl von ASCII nach Dezimal wandeln.
;Übergabe: X/A = High/Low-Nibble ASCII-Zahl.
;Rückgabe: A   = Dezimalzahl.
:convASCII2Dez		pha
			txa
			sec
			sbc	#"0"
			tax
			pla
			sec
			sbc	#"0"
::1			dex
			bmi	:done
			clc
			adc	#10
			bne	:1
::done			rts

;*** ASCII-Zahl nach BCD wandeln.
;Übergabe: X/A = ASCII-Zahl.
;Rückgabe: A   = BCD-Zahl.
:convASCII2BCD		sec
			sbc	#"0"
			sta	r2H
			txa
			sec
			sbc	#"0"
			asl
			asl
			asl
			asl
			ora	r2H
			rts

;*** BCD-Zahl nach Dezimal wandeln.
;Übergabe: A = BCD-Zahl.
;Rückgabe: A = Dezimal-Zahl.
:convBCD2Dez		pha
			and	#%11110000
			lsr
			lsr
			lsr
			lsr
			tay
			pla
			and	#%00001111
			clc
::1			dey
			bmi	:done
			adc	#10
			bne	:1
::done			rts

:bufCurCharNum		b $00
:bufKeyVec		w $0000
:bufXPos		w $0000
:editClockPos		b $00
:charCursor		b $00
:tmpNewClkPos		b $00
:flagCrsrMode		b $00				;$00 = Cursor nicht sichtbar.

;*** Dialogbox: Texte für DeskTop2-Warnhinweis.
if LANG = LANG_DE
:dbtx_Compat1		b BOLDON
			b "deskTop V2.0 läuft nur auf"
			b NULL
:dbtx_Compat2		b "GEOS-Kernals ab V2.0.  Disk mit"
			b NULL
:dbtx_Compat3		b "deskTop V1.3 einlegen, oder erneut"
			b NULL
:dbtx_Compat4		b "booten (aber mit GEOS V2.0)."
			b NULL
endif
if LANG = LANG_EN
:dbtx_Compat1		b "DeskTop V2.0 requires a kernal that"
			b NULL
:dbtx_Compat2		b "is V2.0 or higher. To continue, "
			b ULINEON,"either",ULINEOFF
			b NULL
:dbtx_Compat3		b "insert a disk with an earlier version"
			b NULL
:dbtx_Compat4		b "of the desktop "
			b ULINEON,"or",ULINEOFF
			b " power off and"
			b NULL
:dbtx_Compat5		b "boot up with GEOS V2.0."
			b NULL
endif

;*** Kompatibilitätswarnung anzeigen.
:doWarnDTop		jsr	initDAMenuInpDev
			jsr	clearScreen

			lda	#ST_WR_FORE
			sta	dispBufferOn

			ldx	#> dbox_CompatErr
			lda	#< dbox_CompatErr
			jsr	openDlgBox

			jmp	clrScrnEnterDT

;*** Verzeichnis analysieren und ggf. Eingabetreiber laden.
:initDAMenuInpDev	jsr	initNewDisk

			jsr	loadDirectory
			jsr	chkErrRestartDT

			lda	#$00
			sta	r0L
			sta	vec1stInput +1
			sta	r9H
			sta	r3L

;--- Die Liste mit DAs aktualisieren.
;Ist hier eigentlich nicht notwendig,
;da kein Menü angezeigt wird. Über die
;Routine wird aber auch der erste
;Eingabetreiber auf Diskette gesucht.
			lda	#> tabNameDeskAcc -4
			sta	r1H
			lda	#< tabNameDeskAcc -4
			sta	r1L

			lda	#> dirDiskBuf
			sta	r2H

::search		ldy	#$00
			sty	r2L

			lda	(r2L),y
			pha

::1			jsr	testDirEntryType

			clc
			lda	#$20
			adc	r2L
			sta	r2L
			bcc	:2
			inc	r2H

::2			lda	r2L
			bne	:1

			pla				;Ende erreicht?
			bne	:search			; => Nein, weiter...

			lda	isGEOS			;GEOS-Diskette?
			beq	:done			; => Nein, Ende...

			lda	#$7f
			cmp	r2H			;Borderblock aktiv?
			bcc	:done			; => Ja, Ende...

			sta	r2H			;Zeiger auf
			clv				;Borderblock ($7F00).
			bvc	:search			;Weitersuchen...

;--- Am Ende Eingabetreiber laden falls kein Treiber aktiv.
::done			jmp	testLoadInputDev

;*** Dialogbox: Kompatibilitätswarnung anzeigen.
:dbox_CompatErr		b %10000001
if LANG = LANG_DE
			b DBTXTSTR,$05,$10
			w dbtx_Compat1
			b DBTXTSTR,$05,$20
			w dbtx_Compat2
			b DBTXTSTR,$05,$30
			w dbtx_Compat3
			b DBTXTSTR,$05,$40
			w dbtx_Compat4
endif
if LANG = LANG_EN
			b DBTXTSTR,$10,$10
			w dbtx_Compat1
			b DBTXTSTR,$10,$20
			w dbtx_Compat2
			b DBTXTSTR,$10,$30
			w dbtx_Compat3
			b DBTXTSTR,$10,$40
			w dbtx_Compat4
			b DBTXTSTR,$10,$50
			w dbtx_Compat5
endif
			b OK      ,$11,$48
			b NULL

;*** Größe Dialogbox/ShortCuts:
:AREA_KEYINFO_Y0	= $10
:AREA_KEYINFO_Y1	= $be
:AREA_KEYINFO_X0	= $0008
:AREA_KEYINFO_X1	= $012f

;*** Liste mit ShortCuts anzeigen.
:doShortCuts		jsr	drawScrnPadCol

			lda	#> dbox_ShortCuts
			sta	r0H
			lda	#< dbox_ShortCuts
			sta	r0L
			jsr	DoDlgBox

			jmp	MainInit

;*** Dialogbox: ShortCuts.
:dbox_ShortCuts		b %00000001
			b AREA_KEYINFO_Y0,AREA_KEYINFO_Y1
			w AREA_KEYINFO_X0,AREA_KEYINFO_X1

			b DBSYSOPV

			b DBTXTSTR   ,$10,$0b
			w dbtx_Keys01

			b DBTXTSTR   ,$10,$16
			w dbtx_Keys02
			b DBTXTSTR   ,$1a,$21
			w dbtx_Keys03
			b DBTXTSTR   ,$1a,$2c
			w dbtx_Keys04

			b DBTXTSTR   ,$10,$37
			w dbtx_Keys05
			b DBTXTSTR   ,$1a,$42
			w dbtx_Keys06
			b DBTXTSTR   ,$1a,$4d
			w dbtx_Keys07

			b DBTXTSTR   ,$10,$58
			w dbtx_Keys08
			b DBTXTSTR   ,$1a,$63
			w dbtx_Keys09
			b DBTXTSTR   ,$1a,$6e
			w dbtx_Keys10

			b DBTXTSTR   ,$10,$79
			w dbtx_Keys11
			b DBTXTSTR   ,$1a,$84
			w dbtx_Keys12
			b DBTXTSTR   ,$1a,$8f
			w dbtx_Keys13
			b DBTXTSTR   ,$1a,$9a
			w dbtx_Keys14
			b DBTXTSTR   ,$1a,$a5
			w dbtx_Keys15

			b NULL

;*** Dialogbox: ShortCut-Texte/DE, Teil #1.
if LANG = LANG_DE
:dbtx_Keys01		b BOLDON
			b "WEITERE TASTENKÜRZEL:"
			b NULL

:dbtx_Keys02		b ULINEON
			b BOLDON
			b "Laufwerksbehandlung:"
			b ULINEOFF
			b NULL

:dbtx_Keys03		b BOLDON
			b "C= A"
			b PLAINTEXT
			b " und "
			b BOLDON
			b "C= B"
			b PLAINTEXT
			b " öffnet Laufwerk A bzw. B."
			b NULL

:dbtx_Keys04		b BOLDON
			b "C= Shift A"
			b PLAINTEXT
			b " und "
			b BOLDON
			b "C= Shift B"
			b PLAINTEXT
			b " tauschen mit Laufwerk C."
			b NULL

:dbtx_Keys05		b ULINEON
			b BOLDON
			b "Datei-Auswahl "
			b "(Piktogramm-Modus):"
			b ULINEOFF
			b NULL

:dbtx_Keys06		b BOLDON
			b "C= 1"
			b PLAINTEXT
			b " bis "
			b BOLDON
			b "C= 8"
			b PLAINTEXT
			b " zur Datei-Auswahl"
			b " auf aktueller Seite."
			b NULL

:dbtx_Keys07		b BOLDON
			b "C= Shift 1"
			b PLAINTEXT
			b " bis "
			b BOLDON
			b "C= Shift 8"
			b PLAINTEXT
			b " Datei-Auswahl auf Rand."
			b NULL

:dbtx_Keys08		b ULINEON
			b BOLDON
			b "Mehrdateien-Operationen "
			b "(Piktogramm-Modus):"
			b ULINEOFF
			b NULL

:dbtx_Keys09		b BOLDON
			b "RUN/STOP"
			b PLAINTEXT
			b " zum Abbruch von Operationen."
			b NULL
endif

;*** Dialogbox: ShortCut-Texte/DE, Teil #2.
if LANG = LANG_DE
:dbtx_Keys10		b BOLDON
			b "C= G"
			b PLAINTEXT
			b ", um erste Datei aus"
			b " Liste zu sehen."
			b NULL

:dbtx_Keys11		b ULINEON
			b BOLDON
			b "Bewegung in Arbeitsblatt "
			b "(Piktogramm-Modus):"
			b ULINEOFF
			b NULL

:dbtx_Keys12		b BOLDON
			b "v"
			b PLAINTEXT
			b " und "
			b BOLDON
			b "^"
			b PLAINTEXT
			b " (CRSR-Taste) für"
			b " Seite vor/zurück."
			b NULL

:dbtx_Keys13		b BOLDON
			b "1"
			b PLAINTEXT
			b " bis "
			b BOLDON
			b "9"
			b PLAINTEXT
			b " führt auf die Seiten"
			b " 1 bis 9."
			b NULL

:dbtx_Keys14		b BOLDON
			b "0"
			b PLAINTEXT
			b " führt auf Seite 10."
			b NULL

:dbtx_Keys15		b BOLDON
			b "Shift 1"
			b PLAINTEXT
			b " bis "
			b BOLDON
			b "Shift 8"
			b PLAINTEXT
			b " führt auf die Seiten"
			b " 11 bis 18."
			b NULL
endif

;*** Dialogbox: ShortCut-Texte/EN, Teil #1.
if LANG = LANG_EN
:dbtx_Keys01		b BOLDON
			b "OTHER KEYBOARD SHORTCUTS:"
			b NULL

:dbtx_Keys02		b ULINEON
			b BOLDON
			b "Drive Manipulation:"
			b ULINEOFF
			b NULL

:dbtx_Keys03		b BOLDON
			b "C= A"
			b PLAINTEXT
			b " and "
			b BOLDON
			b "C= B"
			b PLAINTEXT
			b " to open drives A and B."
			b NULL

:dbtx_Keys04		b BOLDON
			b "C= Shift A"
			b PLAINTEXT
			b " und "
			b BOLDON
			b "C= Shift B"
			b PLAINTEXT
			b " to swap drive with drive C."
			b NULL

:dbtx_Keys05		b ULINEON
			b BOLDON
			b "File Selection "
			b "(Icon Mode):"
			b ULINEOFF
			b NULL

:dbtx_Keys06		b BOLDON
			b "C= 1"
			b PLAINTEXT
			b " through "
			b BOLDON
			b "C= 8"
			b PLAINTEXT
			b " to select page files."
			b NULL

:dbtx_Keys07		b BOLDON
			b "C= Shift 1"
			b PLAINTEXT
			b " through "
			b BOLDON
			b "C= Shift 8"
			b PLAINTEXT
			b " to select border files."
			b NULL

:dbtx_Keys08		b ULINEON
			b BOLDON
			b "Multiple File Operations "
			b "(Icon Mode):"
			b ULINEOFF
			b NULL

:dbtx_Keys09		b BOLDON
			b "RUN/STOP"
			b PLAINTEXT
			b " to abort operations."
			b NULL
endif

;*** Dialogbox: ShortCut-Texte/EN, Teil #2.
if LANG = LANG_EN
:dbtx_Keys10		b BOLDON
			b "C= G"
			b PLAINTEXT
			b " to view the first file"
			b " in the queue."
			b NULL

:dbtx_Keys11		b ULINEON
			b BOLDON
			b "Movement through the Pad "
			b "(Icon Mode):"
			b ULINEOFF
			b NULL

:dbtx_Keys12		b BOLDON
			b "v"
			b PLAINTEXT
			b " and "
			b BOLDON
			b "^"
			b PLAINTEXT
			b " (CRSR key) to page"
			b " forwards and backwards."
			b NULL

:dbtx_Keys13		b BOLDON
			b "1"
			b PLAINTEXT
			b " through "
			b BOLDON
			b "9"
			b PLAINTEXT
			b " to go to pages 1 to 9."
			b NULL

:dbtx_Keys14		b BOLDON
			b "0"
			b PLAINTEXT
			b " to go to page 10."
			b NULL

:dbtx_Keys15		b BOLDON
			b "Shift 1"
			b PLAINTEXT
			b " through "
			b BOLDON
			b "Shift 8"
			b PLAINTEXT
			b " to go to pages 11 to 18."
			b NULL
endif

;*** Info/GEOS anzeigen.
:MP3_CODE		= $c014				;Kennung GEOS/MegaPactch.
:doInfoGEOS		lda	MP3_CODE +0
			cmp	#"M"
			bne	:geos
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:geos

			ldx	#< dbtx_MP3
			ldy	#> dbtx_MP3
			stx	r5L
			sty	r5H
			ldx	#< dbtx_Author4
			ldy	#> dbtx_Author4
			bne	:dbox

::geos			ldx	#< noText
			ldy	#> noText
			stx	r5L
			sty	r5H

::dbox			stx	r6L
			sty	r6H

			ldx	#> dbox_InfoGEOS
			lda	#< dbox_InfoGEOS
			jmp	openDlgBox

;*** Dialogbox: Info/GEOS.
:dbox_InfoGEOS		b %10000001

			b DBTXTSTR   ,$19,$12
			w dbtx_Kernal
			b DBTXTSTR   ,$14,$1f
			w dbtx_Author1
			b DBTXTSTR   ,$16,$29
			w dbtx_Author2

			b DBVARSTR   ,$0e,$3c
			b r5L
			b DBVARSTR   ,$3c,$48
			b r6L

			b DBTXTSTR   ,$06,$58
			w dbtx_Copyright
			b DBSYSOPV

:noText			b NULL

;*** Info/DeskTop anzeigen.
:doInfoDTop		ldx	#> dbox_InfoDTOP
			lda	#< dbox_InfoDTOP
			jmp	openDlgBox

;*** Dialogbox: Info/DeskTop.
:dbox_InfoDTOP		b %10000001

			b DBTXTSTR   ,$18,$0f
			w dbtx_DeskTop
			b DBTXTSTR   ,$16,$1a
			w dbtx_Author1

			b DBTXTSTR   ,$1d,$28
			w dbtx_Update
			b DBTXTSTR   ,$10,$33
			w dbtx_Author3

			b DBTXTSTR   ,$18,$41
			w dbtx_Update2
			b DBTXTSTR   ,$3c,$4c
			w dbtx_Author4

			b DBTXTSTR   ,$06,$58
			w dbtx_Copyright
			b DBSYSOPV
			b NULL

;*** Info-Texte.
:dbtx_Kernal		b PLAINTEXT
			b OUTLINEON
			b "GEOS"
			b PLAINTEXT
			b BOLDON
			b " Kernal designed by:"
			b NULL

:dbtx_MP3		b PLAINTEXT
			b OUTLINEON
			b "GEOS"
			b PLAINTEXT
			b BOLDON
			b "/MegaPatch designed by:"
			b NULL

:dbtx_Author1		b "Brian Dougherty  Doug Fults",NULL
:dbtx_Author2		b "Jim Defrisco  Tony Requist",NULL
:dbtx_Author3		b "Gia Ferry und Cheng-Yew Tan",NULL
:dbtx_Author4		b "Markus Kanet",NULL

:dbtx_Copyright		b PLAINTEXT
			b "Copyright 1986, 1988, "
			b "Berkeley Softworks",NULL

:dbtx_DeskTop		b OUTLINEON
			b "GEOS"
			b PLAINTEXT,BOLDON
			b " deskTop designed by:"
			b NULL

if LANG = LANG_DE
:dbtx_Update		b "Erweiterung auf V2.0 von:",NULL
:dbtx_Update2		b "Reassembliert für V2.1 von:",NULL
endif
if LANG = LANG_EN
:dbtx_Update		b "  Upgraded to V2.0 by:",NULL
:dbtx_Update2		b " Reassembled for V2.1 by:",NULL
endif

;Endadresse VLIR-Modul testen:
			g vlirModEnd
