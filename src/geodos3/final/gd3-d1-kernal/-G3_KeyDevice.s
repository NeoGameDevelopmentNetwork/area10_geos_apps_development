; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Tastaturmatrix für Abfrage über
;    Register $DC00/$DC01
;
;-----------------------------------------------------------------------------
;Spalte      #0      #1      #2      #3      #4      #5      #6      #7
;-----------------------------------------------------------------------------
;Reihe
; #0         DEL     RET     CRSR/LR F1      F3      F7      F5      CRSR/UD
;
; #1         3       W       A       4       Z       S       E       SHIFT/L
;
; #2         5       R       D       6       C       F       T       X
;
; #3         7       Y       G       8       B       H       U       V
;
; #4         9       I       J       0       M       K       O       N
;
; #5         +       P       L       -       .       :       (at)    ,
;
; #6         E       *       ;       HOME    SHIFTR  =       ^       /
;
; #7         1       <-      CTRL    2       SPACE   C=      Q       RSTOP
;
;-----------------------------------------------------------------------------
;
;
;******************************************************************************

;*** Wurde Taste gedrückt ?
:GetMatrixCode		lda	keyMode			;Taste in ":currentKey" ?
			bne	:1			;Nein, weiter...
			lda	currentKey
			jsr	NewKeyInBuf
			lda	Flag_CrsrRepeat		;Repeat-Geschwindigkeit neu
			sta	keyMode			;initialisieren.

::1			lda	#$00			;Keine Taste gedrückt.
			sta	r1H
			jsr	CheckKeyboard		;Wurde Taste gedrückt ?
			bne	:5			;Nein, Ende...
			jsr	SHIFT_CBM_CTRL		;SHIFT/CBM/CTRL auswerten.
							;In r1H steht das Ergebnis!

			ldy	#$07
::2			jsr	CheckKeyboard		;Wurde Taste gedrückt ?
			bne	:5			;Nein, Ende...

			lda	KeyMatrixData,y		;Reihe #0 bis #7 durchsuchen.
			sta	$dc00

			lda	$dc01			;Spaltenregister einlesen und
			cmp	KB_LastKeyTab,y		;mit letztem Wert vergleichen.
			sta	KB_LastKeyTab,y		;Neuen Wert merken.
			bne	:4			;Wurde Taste gedrückt ?
							;Ja, weiter...

			cmp	KB_MultipleKey,y	;Mit letzter Taste vergleichen.
			beq	:4			;Übereinstimmung, weiter...
			pha
			eor	KB_MultipleKey,y	;War vorher Taste gedrückt ?
			beq	:3			;Ja, -> Dauerfunktion.
			jsr	MultipleKeyMod		;Neue Taste einlesen.
::3			pla
			sta	KB_MultipleKey,y	;Neue Taste merken.
::4			dey
			bpl	:2			;Nächste Reihe testen.
::5			rts

;*** Tastatur abfragen.
;    Wurde Taste gedrückt ?
:CheckKeyboard		lda	#$ff
			sta	$dc00
			lda	$dc01
			cmp	#$ff
			rts

;*** Taste auswerten, auf Dauerfunktion testen.
:MultipleKeyMod		sta	r0L
			lda	#$07
			sta	r1L

::1			lda	r0L
			ldx	r1L
			and	BitData2,x
			beq	:a
			tya
			asl
			asl
			asl
			adc	r1L
			tax

			bit	r1H			;Wurde SHIFT/CBM gedrückt ?
			bpl	:2			;Nein, weiter...
			lda	keyTab1,x		;Taste mit SHIFT einlesen.
			clv
			bvc	:3

::2			lda	keyTab0,x		;Taste ohne SHIFT einlesen.
::3			sta	r0H			;Taste speichern.

			lda	r1H
			and	#%00100000		;Wurde CTRL-Taste gedrückt ?
			beq	:4			;Nein, weiter...

			lda	r0H			;Tastencode einlesen.
			jsr	TestForLowChar		;Zeichenwert isolieren.
			cmp	#$41			;Buchstabentaste gedrückt ?
			bcc	:4			;Nein, weiter...
			cmp	#$5b
			bcs	:4			;Nein, weiter...

			sec				;Ja, CTRL-Taste erzeugen.
			sbc	#$40			;(Codes von $01-$1A)
			sta	r0H

::4			bit	r1H			;Wurde CBM-Taste gedrückt ?
			bvc	:5			;Nein, weiter...
			lda	r0H			;Ja, Bit #7 aktivieren.
			ora	#%10000000
			sta	r0H

::5			lda	r0H
			sty	r0H

if Sprache = Deutsch
			ldy	#$02			;Wurde Taste "<",">" oder "^"
endif

if Sprache = Englisch
			ldy	#$08			;Wurde Taste "<",">" oder "^"
endif

::6			cmp	SpecialKeyTab,y		;gedrückt ?
			beq	:7			;Ja, weiter...
			dey
			bpl	:6
			bmi	:8			;Keine Sondertaste.

::7			lda	ReplaceKeyTab,y		;Ersatzcode für Tasten "<",

::8			ldy	r0H
			sta	r0H
			and	#$7f			;Tastencode isolieren.
			cmp	#%00011111		;Taste SHIFT/CBM/CTRL ?
			beq	:9			;Ja, übergehen...

			ldx	r1L
			lda	r0L
			and	BitData2,x
			and	KB_MultipleKey,y
			beq	:9

			lda	#%00001111		;Dauerfunktion, Taste max. 16x
			sta	keyMode			;ausführen -> Puffer voll.
			lda	r0H
			sta	currentKey		;Neue Taste merken und
			jsr	NewKeyInBuf		;in Tastaturpuffer schreiben.
			clv
			bvc	:a

::9			lda	#%11111111		;Keine Taste in
			sta	keyMode			;":currentKey" gespeichert.
			lda	#$00
			sta	currentKey

::a			dec	r1L			;Nächste Spalte testen.
			bmi	:b
			jmp	:1

::b			rts

;*** Tabelle mit Tastaturabfrage-
;    adressen für Reihe #0 bis #7.
:KeyMatrixData		b $fe,$fd,$fb,$f7
			b $ef,$df,$bf,$7f

;******************************************************************************
;*** C64:Deutsch:Beta (Y/Z vertauscht, Stop=TAB)
;*** Da es künftig keine BETA-Versionen mehr geben wird,
;*** ist diese Tastaturmatrix deaktiviert.
;*** Zur Dokumentation verbleibt die Matrix hier erhalten.
;******************************************************************************
;
;if Sprache = Deutsch
;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
;:SpecialKeyTab		b $bb,$ba,$e0
;:ReplaceKeyTab		b $3c,$3e,$5e
;			s 12				;Dummy-Bytes Englisch/Deutsch!
;
;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
;:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
;			b $33,$77,$61,$34,$7a,$73,$65,$1f
;			b $35,$72,$64,$36,$63,$66,$74,$78
;			b $37,$79,$67,$38,$62,$68,$75,$76
;			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
;			b $7e,$70,$6c,$27,$2e,$7c,$7d,$2c
;			b $1f,$2b,$7b,$12,$1f,$23,$1f,$2d
;			b $31,$14,$1f,$32,$20,$1f,$71,$09
;
;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
;:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
;			b $40,$57,$41,$24,$5a,$53,$45,$1f
;			b $25,$52,$44,$26,$43,$46,$54,$58
;			b $2f,$59,$47,$28,$42,$48,$55,$56
;			b $29,$49,$4a,$3d,$4d,$4b,$4f,$4e
;			b $3f,$50,$4c,$60,$3a,$5c,$5d,$3b
;			b $5e,$2a,$5b,$13,$1f,$27,$1f,$5f
;			b $21,$14,$1f,$22,$20,$1f,$51,$17
;endif

;******************************************************************************
;*** C64:Deutsch (DIN)
;******************************************************************************

if Sprache = Deutsch
;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
:SpecialKeyTab		b $bb,$ba,$e0
:ReplaceKeyTab		b $3c,$3e,$5e
			s 12				;Dummy-Bytes Englisch/Deutsch!

;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
			b $33,$77,$61,$34,$79,$73,$65,$1f
			b $35,$72,$64,$36,$63,$66,$74,$78
			b $37,$7a,$67,$38,$62,$68,$75,$76
			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
			b $7e,$70,$6c,$27,$2e,$7c,$7d,$2c
			b $1f,$2b,$7b,$12,$1f,$23,$1f,$2d
			b $31,$14,$1f,$32,$20,$1f,$71,$16

;Zusätzliche Label um im GD.CONFIG die Umschaltung
;zwischen QWERTZ/QWERTY zu ermöglchen.
.key0z = keyTab0+12
.key0y = keyTab0+25

;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
			b $40,$57,$41,$24,$59,$53,$45,$1f
			b $25,$52,$44,$26,$43,$46,$54,$58
			b $2f,$5a,$47,$28,$42,$48,$55,$56
			b $29,$49,$4a,$3d,$4d,$4b,$4f,$4e
			b $3f,$50,$4c,$60,$3a,$5c,$5d,$3b
			b $5e,$2a,$5b,$13,$1f,$27,$1f,$5f
			b $21,$14,$1f,$22,$20,$1f,$51,$17

;--- Ergänzung: 03.01.19/M.Kanet
;Zusätzliche Label um im GEOS.Editor die Umschaltung
;zwischen QWERTZ/QWERTY zu ermöglchen.
.key1z = keyTab1+12
.key1y = keyTab1+25
endif

;******************************************************************************
;*** C64:Englisch (Standard)
;******************************************************************************

if Sprache = Englisch
;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
:SpecialKeyTab		b $db,$dd,$de,$ad,$af,$aa,$c0,$ba,$bb
:ReplaceKeyTab		b $7b,$7d,$7c,$5f,$5c,$7e,$60,$7b,$7d

;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
			b $33,$77,$61,$34,$7a,$73,$65,$1f
			b $35,$72,$64,$36,$63,$66,$74,$78
			b $37,$79,$67,$38,$62,$68,$75,$76
			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
			b $2b,$70,$6c,$2d,$2e,$3a,$40,$2c
			b $18,$2a,$3b,$12,$1f,$3d,$5e,$2f
			b $31,$14,$1f,$32,$20,$1f,$71,$16

;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
			b $23,$57,$41,$24,$5a,$53,$45,$1f
			b $25,$52,$44,$26,$43,$46,$54,$58
			b $27,$59,$47,$28,$42,$48,$55,$56
			b $29,$49,$4a,$30,$4d,$4b,$4f,$4e
			b $2b,$50,$4c,$2d,$3e,$5b,$40,$3c
			b $18,$2a,$5d,$13,$1f,$3d,$5e,$3f
			b $21,$14,$1f,$22,$20,$1f,$51,$17
endif

;*** Neue Taste in Tastaturpuffer.
:NewKeyInBuf		php
			sei
			pha
			lda	#$80
			ora	pressFlag
			sta	pressFlag
			ldx	MaxKeyInBuf
			pla
			sta	keyBuffer,x
			jsr	Add1Key
			cpx	keyBufPointer
			beq	:1
			stx	MaxKeyInBuf
::1			plp
			rts

;*** Zeichen aus Tastaturpuffer holen.
:GetKeyFromBuf		php
			sei
			ldx	keyBufPointer
			lda	keyBuffer,x
			sta	keyData
			jsr	Add1Key
			stx	keyBufPointer
			cpx	MaxKeyInBuf
			bne	:1
			pha
			lda	#$7f
			and	pressFlag
			sta	pressFlag
			pla
::1			plp
			rts

;*** Zähler für ":MaxKeyInBuf" und
;    ":keyBufPointer" korrigieren.
:Add1Key		inx
			cpx	#$10
			bne	:1
			ldx	#$00
::1			rts

;*** Zeichen über Tastatur einlesen.
:xGetNextChar		bit	pressFlag
			bpl	:1
			jmp	GetKeyFromBuf
::1			lda	#$00			;Keine Taste gedrückt.
			rts

;*** Gedrückte Taste aus Matrix mit
;    SHIFT/CBM/CTRL verknüpfen.
:SHIFT_CBM_CTRL		lda	#%11111101		;Linke SHIFT-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #1.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%10000000		;Bit #7 = Spalte 7 gesetzt ?
			bne	:1			;Ja, SHIFT-Taste gedrückt.

			lda	#%10111111		;Rechte SHIFT-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #6.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00010000		;Bit #4 = Spalte 4 gesetzt ?
			beq	:2			;Nein, weiter...

::1			lda	#%10000000		;Zeichen in Tastenspeicher
			ora	r1H			;mit SHIFT verknüpfen.
			sta	r1H

::2			lda	#%01111111		;CBM-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #7.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00100000		;Bit #5 = Spalte 5 gesetzt ?
			beq	:3			;Nein, weiter...

			lda	#%01000000		;Zeichen in Tastenspeicher
			ora	r1H			;mit CBM verknüpfen.
			sta	r1H

::3			lda	#%01111111		;CTRL-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #7.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00000100		;Bit #2 = Spalte 2 gesetzt ?
			beq	:4

			lda	#%00100000		;Zeichen in Tastenspeicher
			ora	r1H			;mit CTRL verknüpfen.
			sta	r1H
::4			rts

;*** Auf Taste für Kleinbuchstaben testen.
:TestForLowChar		pha				;Zeichen merken.
			and	#%01111111		;GEOS nur von $20 - $7F !!!
			cmp	#$61			;Kleinbuchstabe ?
			bcc	:1			;Nein, weiter...
			cmp	#$7b
			bcs	:1			;Nein, weiter...
			pla
			sec				;Ja, in Großbuchstaben
			sbc	#$20			;umrechnen.
			pha
::1			pla
			rts
