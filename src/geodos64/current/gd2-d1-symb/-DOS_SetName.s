; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; :r0  = Zeiger auf Vorgabetext.
; :r1  = Zeiger auf Eingabespeicher.
; :r2L = $00 -> Kein Vorgabetext möglich.
;      = $FF -> Vorgabetext möglich.
; :r2H = $00 -> Vorgabetext beim Start nicht vorgeben.
;      = $FF -> Vorgabetext beim Start vorgeben.
;      = $BF -> Diskettenname eingeben.
; :r3  = Zeiger auf Titelzeile.
;
; Rückgabe:
; AKKU = $01 -> OK
;              :r1  = Zeiger auf Text.
;        $02 -> EXIT-Icon.
;        $03 -> CLOSE-Icon.
;
;******************************************************************************

:dosSetName		MoveW	r0 ,V360a0		;Startparameter zwischenspeichern.
			MoveW	r1 ,V360a1
			MoveW	r3 ,V360d1
			MoveB	r2H,NameTypeDOS
			MoveB	r2L,V360a2

			ldx	#111			;Eingabe mit/ohne Vorgabetext ?
			cmp	#$00			;Größe der Dialogbox definieren.
			beq	:101
			ldx	#135
::101			stx	V360c0+2

			MoveW	V360a0,r0
			jsr	ConvTextDOS

			LoadW	r1,V360a3		;Gültige Zeichen aus Vorgabetext
			jsr	ConvNameDOS		;in Zwischenspeicher kopieren.
			LoadW	r0,V360a3		;Gültige Zeichen aus Vorgabetext
			jsr	L360f0

;*** Vorgabetext vorbereiten.
:L360a0			ldy	#0
::101			lda	#$00			;Eingabefeld definieren.
			bit	V360a2
			bpl	:102
			bit	NameTypeDOS
			bpl	:102
			lda	V360a5,y
::102			sta	V360a4,y
			iny
			cpy	#12
			bne	:101

;*** Eingabe initialisieren.
:L360a1			ldx	#12
			bit	NameTypeDOS
			bvs	:111
			dex
::111			stx	V360c1+1

			LoadW	r0 ,V360c0
			LoadW	r10,V360a4
			DB_RecBoxL360b1			;Texteingabe.
			lda	sysDBData
			cmp	#DBGETSTRING		;RETURN -> Eingabe auswerten.
			beq	L360a2
			rts				;Eingabe abgebrochen.

;*** Eingabe prüfen.
:L360a2			LoadW	r0,V360a4		;Zeichen in PCDOS-Format umwandeln.
			jsr	ConvTextDOS

			LoadW	r0,V360a4
			LoadW	r1,NameBufDOS
			jsr	ConvNameDOS		;Eingabe nach PCDOS wandeln.
			txa
			pha

			LoadW	r0,NameBufDOS		;Text komprimieren.
			jsr	L360f0

			pla
			bne	:113
			txa
			beq	:114
::113			jmp	L360a0			;Eingabe ungültig.

::114			lda	r4H			;Länge = 0 ?
			bne	:113			;Ja, ungültig.

			LoadW	r0,V360a5		;Auf PCDOS-reservierte Dateinamen
			jsr	L360g0			;testen.
			txa
			bne	:113			;Ungültig.

			LoadW	r0,V360a4		;Eingabe nach 8+3 wandeln.
			MoveW	V360a1,r1
			jsr	ConvNameDOS

			lda	#$01			;Ende, OK.
			rts

;*** Farben setzen und Titel ausgeben.
:L360b0			jsr	i_C_MenuClose
			b	$08,$05,$01,$01
			jsr	i_C_MenuTitel
			b	$09,$05,$17,$01

			lda	#$08
			bit	V360a2
			bpl	:201
			lda	#$0b
::201			sta	:202 +3

			jsr	i_C_MenuBack
::202			b	$08,$06,$18,$08
			jsr	i_C_MenuMIcon
			b	$0a,$07,$02,$02
			jsr	i_C_MenuMIcon
			b	$0d,$07,$02,$02

			FillPRec$00,$28,$2f,$0040,$00ff

			jsr	UseGDFont
			MoveW	V360d1,r0
			LoadW	r11,80
			LoadB	r1H,46
			jsr	PutString

			jsr	i_BitmapUp		;"Löschen"-Icon.
			w	Icon_01
			b	$1c,$38,2,16
			jsr	i_C_MenuMIcon
			b	$1c,$07,$02,$02

			bit	V360a2			;Vorgabetext möglich ?
			bpl	:203			;Nein, weiter...
			jsr	i_BitmapUp		;"Vorgabe"-Icon.
			w	Icon_02
			b	$19,$38,2,16
			jsr	i_C_MenuMIcon
			b	$19,$07,$02,$02

::203			jsr	i_ColorBox
			b	$0a,$0a,$14,$02,$01
			LoadW	r0,V360e0		;Fenster für Texteingabe.
			jsr	GraphicsString

			bit	V360a2			;Vorgabetext möglich ?
			bpl	:204			;Nein, weiter...
			jsr	i_ColorBox
			b	$0a,$0e,$14,$02,$01
			LoadW	r0,V360e1		;Fenster für Vorgabetext.
			jsr	GraphicsString

			LoadW	r0,V360d0
			jsr	PutString		;Vorgabetext ausgeben.
			LoadW	r0,V360a3
			jsr	PutString

::204			ClrB	currentMode
			rts

;*** Farben zurücksetzen..
:L360b1			jsr	i_C_ColorClr
			b	$08,$05,$18,$10
			FillPRec$00,$28,$8f,$0040,$00ff
			rts

;*** Cursorfarbe festlegen.
:L360b2			php
			sei
			lda	keyVector +0
			sta	V360a6    +0
			lda	keyVector +1
			sta	V360a6    +1
			lda	#<L360c3
			sta	keyVector +0
			lda	#>L360c3
			sta	keyVector +1

			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
			lda	#$00
			sta	$d028
			stx	CPU_DATA
			plp
			rts

;*** Window beenden.
:L360c0			lda	#$03			;"EXIT"-Icon.
			b $2c
:L360c1			lda	#$02			;"CLOSE"-Icon.
			sta	sysDBData
			jmp	RstrFrmDialogue

:L360c2			LoadB	keyData,CR		;"OK"-Icon.
			lda	keyVector+0
			ldx	keyVector+1
			jmp	CallRoutine

;*** Auswertung von RETURN.
:L360c3			php				;IRQ sperren und AKKU retten.
			sei
			pha

			CmpBI	keyData,CR		;RETURN gedrückt ?
			bne	:101			;Nein, weiter...

			LoadB	keyData,$ff		;$FF als Taste definieren, um Anzahl
			jsr	:102			;Zeichen in Puffer zu ermitteln.
			tya				;Tasten in Speicher ?
			beq	:103			;Nein, Abbruch...

			LoadB	keyData,CR		;RETURN-Taste in Tastaturspeicher.
			lda	V360a6    +0		;Tastatur-Vector zurücksetzen.
			sta	keyVector +0
			lda	V360a6    +1
			sta	keyVector +1
::101			pla				;Zur Tastaturabfrage.
			plp
::102			jmp	(V360a6)
::103			pla
			plp
			rts

;*** Mausklick auf Icon.
:L360d0			ldy	#$00			;Test auf Icon "Löschen".
			jsr	L360d3
			sei
			php
			jsr	IsMseInRegion
			plp
			tax
			beq	:301
			jmp	L360d1			;Text löschen.

::301			bit	V360a2			;Vorgabe erlaubt ?
			bpl	:302			;Nein, weiter...

			ldy	#$06			;Test auf Icon "Vorgabe".
			jsr	L360d3
			sei
			php
			jsr	IsMseInRegion
			plp
			tax
			beq	:302
			jmp	L360d2			;Vorgabetext ausgeben.

::302			rts

;*** Eingabe löschen.
:L360d1			jsr	InvertRectangle
			jsr	L360d4			;Eingabe löschen.
			jsr	L360e0			;Warten bis keine Maustaste gedrückt.
			ldy	#$00			;Icon invertieren.
			jsr	L360d3
			jmp	InvertRectangle

;*** Vorgabetext auf Bildschirm.
:L360d2			jsr	InvertRectangle
			jsr	L360d4			;Eingabe löschen.

			LoadW	r0,V360a3		;Vorgabetext nach 8+3 wandeln.
			jsr	L360f0
			txa
			bne	:323

			ldy	#$00
::321			sty	:322 +1
			lda	V360a5,y		;Zeichen aus Vorgabetext ausgeben.
			beq	:323
			sta	keyData
			lda	keyVector+0
			ldx	keyVector+1
			jsr	CallRoutine

::322			ldy	#$ff
			iny
			cpy	#12
			bne	:321

::323			jsr	L360e0			;Warten bis keine Maustaste gedrückt.

			ldy	#$06			;Icon invertieren.
			jsr	L360d3
			jmp	InvertRectangle

;*** Daten kopieren.
:L360d3			ldx	#$00
::331			lda	V360f0,y
			sta	r2L,x
			iny
			inx
			cpx	#6
			bne	:331
			rts

;*** Texteingabe löschen.
:L360d4			lda	#30			;16x "CURSOR RECHTS".
			jsr	:341
			lda	#29			;16x "DELETE".

::341			sta	:342 +2
			lda	#$00
::342			pha
			lda	#$ff			;Zeichen ausgeben.
			sta	keyData
			lda	keyVector+0
			ldx	keyVector+1
			jsr	CallRoutine
			pla
			add	1
			cmp	#$10
			bne	:342
			rts

;*** Warten bis keine Maustaste gedrückt.
:L360e0			php
			cli
::351			lda	mouseData
			bpl	:351
			LoadB	pressFlag,NULL
			plp
			rts

;*** Dateinamen konvertieren.
:ConvNameDOS		ldy	#11
::401			lda	#$00			;Zwischenspeicher löschen.
			sta	V360a5,y
			sta	(r1L),y
			dey
			bpl	:401

			ldy	#11
			lda	#" "			;Zieltextspeicher löschen.
::402			sta	(r1L),y
			dey
			bpl	:402

			iny
			sty	r2L
			sty	r2H
			sty	r3L
			sty	r4H

::403			lda	(r0L),y			;Zeichen aus Text einlesen.
			beq	:407			;$00-Byte ? Ja, Textende...

			cmp	#"."			;Mit Punkt vergleichen.
			bne	:404			;Kein Punkt, weiter...
			bit	NameTypeDOS
			bvc	:405

			ldx	r2L			;Schon ein Punkt im Dateinamen ?
			bne	:406			;Ja, weiter...
			ldx	r2H			;Bereits ein Zeichen im Dateinamen ?
			beq	:406			;Nein, weiter...
			stx	r2L			;Position Punkt speichern.
			jmp	:405			;Punkt in Zieltext übernehmen.

::404			jsr	L360g1			;Zeichen erlaubt ?
			cpx	#$ff
			beq	:405			;Ja, weiter...
			inc	r4H			;Nein, Zähler für "ungültige Zeichen"
			jmp	:406			;korrigieren, nächstes Zeichen.

::405			ldy	r2H			;Zeichen in Zwischenspeicher.
			sta	V360a5,y
			cpy	#15			;max. 16 Zeichen übernehmen.
			beq	:407			;Erreicht, ende...
			inc	r2H

::406			inc	r3L			;Zeiger auf nächstes Zeichen.
			ldy	r3L
			cpy	#16			;Max. 16 Zeichen.
			beq	:407			;Erreicht ? Ja, Ende...
			bne	:403			;Nein, nächstes Zeichen.

::407			ldy	r2H			;Textlänge = 0 ?
			bne	:409			;Nein, weiter...
			ldx	#$ff			;Ungültiger Text.
			bit	NameTypeDOS
			bvs	:408
			inx
::408			rts

::409			ldy	#$00
			sty	r3L
			sty	r3H

::410			lda	V360a5,y		;Zeichen aus Zwischenspeicher holen.
			beq	:427			;$00-Byte = Textende.
			cmp	#"."			;"." erreicht ? (max. 1 Punkt im
			bne	:411			;Dateinamen, siehe oben!) Ja, weiter...
			bit	NameTypeDOS
			bvs	:420

::411			ldy	r3H
			sta	(r1L),y			;Zeichen in PCDOS 8+3-Speicher
			inc	r3H			;übertragen.
			cpy	#$07			;Name 8 Zeichen erreicht ?
			beq	:420			;Ja, Ende...

			inc	r3L			;Nächstes Zeichen kopieren.
			ldy	r3L
			jmp	:410

;*** Dateinamen konvertieren.
::420			ldy	#$08			;Punkt zwischen Name und Extension
			bit	NameTypeDOS
			bvc	:421
			lda	#"."			;einfügen.
			sta	(r1L),y
			iny
::421			sty	r3H

::422			ldx	r3L			;Zeiger innerhalb Zwischenspeicher
			lda	r2L			;setzen. Falls "." vorhanden, Zeiger
			beq	:423			;hinter "." setzen.
			tax
::423			inx
			stx	r3L

::424			ldy	r3L
			cpy	r2H			;Ende Zwischenspeicher erreicht ?
			beq	:425			;Nein, weiter...
			bcs	:427			;Ja, Ende...
::425			lda	V360a5,y		;Extension erzeugen.
			beq	:427
			ldy	r3H
			sta	(r1L),y
			cpy	#11
			beq	:427
			inc	r3H
::426			inc	r3L
			jmp	:424

::427			ldx	#$00			;Eingabe OK!
			rts

;*** Textstring verdichten.
:L360f0			ldy	#$00
			ldx	#$00
::451			lda	(r0L),y			;Zeichen aus Text einlesen.
			beq	:454			;$00-Byte ? Ja, Ende...

			bit	NameTypeDOS
			bvc	:452
			cmp	#" "			;Leerzeichen ?
			beq	:453			;Ja, überlesen.

::452			sta	V360a5,x		;In Zwischenspeicher übertragen.
			inx
::453			iny
			cpy	#12
			bne	:451

::454			txa
			tay

::455			cpy	#12
			beq	:456

			lda	#$00			;Rest des Speicher mit $00-Bytes
			sta	V360a5,y		;auffüllen.
			iny
			jmp	:455

::456			txa				;Länge des Strings = 0 ?
			bne	:458			;Nein, weiter...
			bit	NameTypeDOS
			bvc	:461
::457			ldx	#$ff			;Eingabe ungültig.
			rts

::458			dex
			lda	V360a5,x
			cmp	#"."			;Letztes Zeichen = Punkt ?
			bne	:459			;Nein, Ende...

			cpx	#$00			;Nur ein Zeichen (".") im Text ?
			beq	:457
			beq	:460			;Ja, Fehler...

::459			cmp	#" "
			bne	:461

::460			lda	#$00
			sta	V360a5,x		;Punkt löschen.
			jmp	:458

::461			ldx	#$00
			rts

;*** Auf ungültige Dateinamen testen
:L360g0			ldx	#$00
::501			stx	:505 +1
			lda	V360b1,x		;Ende Tabelle erreicht ?
			bne	:502			;Nein, weiter...
			ldx	#$00			;Name OK!
			rts

::502			ldy	#$00
::503			lda	(r0L),y
			bne	:504
			lda	#" "
::504			cmp	V360b1,x		;Zeichen mit DOS-Namen
			bne	:505			;vergleichen.
			inx
			iny
			cpy	#8
			bne	:503

			ldx	#$ff			;Übereinstimmung, Fehler.
			rts

::505			lda	#$ff			;Zeiger auf nächsten Namen.
			add	8
			tax
			jmp	:501

;*** Prüfen ob Zeichen erlaubt.
:L360g1			sty	:514 +1

			ldy	#$00
::511			ldx	V360b0,y
			beq	:512
			cmp	V360b0,y
			beq	:513
			iny
			jmp	:511

::512			bit	NameTypeDOS
			bvs	:514
			cmp	#" "
			bne	:514

::513			ldx	#$ff
::514			ldy	#$ff
			rts

;*** Zeichen in PCDOS-Format wandeln.
:ConvTextDOS		ldy	#$00
::521			lda	(r0L),y
			beq	:523
			cmp	#$60
			bcc	:522
			sbc	#$20
			sta	(r0L),y
			bcs	:521
::522			iny
			bne	:521
::523			rts

;*** Variablen.
:NameTypeDOS		b $00				;$FF = Vorgabetext vorgeben.
:NameBufDOS		s 13				;Zwischenspeicher.

:V360a0			w $0000				;Adr. Vorgabetext.
:V360a1			w $0000				;Adr. Eingabespeiher.
:V360a2			b $00				;$FF = Vorgabetext möglich.
:V360a3			s 13				;Text für Vorgabe.
:V360a4			s 13				;Texteingabe.
:V360a5			s 17				;Zwischenspeicher.
:V360a6			w $0000				;Tastatureingabe.
:V360b0			b "_()-0123456789"
			b "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			b NULL
:V360b1			b "NUL     CON     PRN     AUX     "
			b "COM1    COM2    COM3    COM4    "
			b "LPT1    LPT2    LPT3    LPT4    "
			b "CLOCK$  "
			b $00

;*** Dialogbox: Eingabe DOS-Datei-Name.
:V360c0			b %00100000
			b 40,143
			w 64,255
			b DBUSRICON  ,  0,  0
			w V360c2
			b DBUSRICON  ,  2, 16
			w V360c3
			b DBUSRICON  ,  5, 16
			w V360c4
			b DB_USR_ROUT
			w L360b0
			b DBGETSTRING, 20, 44
:V360c1			b r10L,12
			b DB_USR_ROUT
			w L360b2
			b DBOPVEC
			w L360d0
			b NULL

:V360c2			w Icon_Close
			b $00,$00,$01,$08
			w L360c1
:V360c3			w Icon_00
			b $00,$00,$02,$10
			w L360c0
:V360c4			w Icon_03
			b $00,$00,$02,$10
			w L360c2

:V360d0			b PLAINTEXT
			b GOTOXY
			w 80
			b 108

if Sprache = Deutsch
			b "Vorgabetext:"
endif

if Sprache = Englisch
			b "Default:"
endif

			b GOTOXY
			w 84
			b 122
			b NULL

:V360d1			w $0000

;*** Eingabefenster.
:V360e0			b MOVEPENTO
			w 79
			b 79
			b FRAME_RECTO
			w 240
			b 96
			b NEWPATTERN,$00
			b MOVEPENTO
			w 80
			b 80
			b RECTANGLETO
			w 239
			b 95
			b NULL

:V360e1			b MOVEPENTO
			w 79
			b 111
			b FRAME_RECTO
			w 240
			b 128
			b NEWPATTERN,$00
			b MOVEPENTO
			w 80
			b 112
			b RECTANGLETO
			w 239
			b 127
			b NULL

:V360f0			b $38,$47
			w $1c*8,$1c*8+15
			b $38,$47
			w $19*8,$19*8+15

;*** Icons.
:Icon_00
<MISSING_IMAGE_DATA>

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>
