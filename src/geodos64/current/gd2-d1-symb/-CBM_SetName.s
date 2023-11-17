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
; :r3  = Zeiger auf Titelzeile.
;
; Rückgabe:
; AKKU = $01 -> OK
;              :r1  = Zeiger auf Text.
;              :r2L = Anzahl Zeichen.
;        $02 -> EXIT-Icon.
;        $03 -> CLOSE-Icon.
;
;******************************************************************************

;--- Ergänzung: 21.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrfache MoveB/W-Befehle durch Schleife ersetzen.
:cbmSetName		ldx	#$05			;Zeiger auf Vorgabetext,
::0			lda	r0L,x			;Eingabespeicher und Optionen
			sta	V460a0,x		;zwischenspeichern.
			dex
			bpl	:0

			lda	r3L			;Zeiger auf Titelzeile speichern.
			sta	V460c1 +0
			lda	r3H
			sta	V460c1 +1

			ldx	#111			;Eingabe mit/ohne Vorgabetext ?
			lda	V460a2
;			cmp	#$00			;Vorgabetext möglich?
			beq	:1			; => Nein, weiter...
			ldx	#135
::1			stx	V460c0+2

			LoadW	r1,V460a4		;Gültige Zeichen aus
			jsr	L460e0			;Vorgabetext filtern.

			LoadW	r0,V460a4		;Leerzeichen am Ende aus
			jsr	L460b0			;Vorgabetext filtern.

			ldy	#$00
::2			lda	#$00			;Eingabefeld definieren.
			bit	V460a2			;Keine Vorgabe, Eingabefeld löschen.
			bpl	:3
			bit	V460a3
			bpl	:3
			lda	V460a4,y		;Vorgabetext in Eingebespeicher
::3			sta	V460a5,y		;kopieren.
			iny
			cpy	#$10
			bne	:2

:L460a0			LoadW	r0 ,V460c0
			LoadW	r10,V460a5
			DB_RecBoxL460c1			;Texteingabe.
			lda	sysDBData
			cmp	#DBGETSTRING		;RETURN -> Eingabe auswerten.
			beq	L460a1
			rts				;Eingabe abgebrochen.

:L460a1			LoadW	r0,V460a5		;Leerzeichen am Ende aus
			jsr	L460b0			;Eingabetext filtern.

			MoveW	V460a1,r1		;Gültige Zeichen aus
			jsr	L460e0			;Eingabetext kopieren.
			bne	L460a0			; => Eingabe ungültig.

			lda	#$01			;Ende, OK.
			rts

;*** Leerzeichen am Ende rausfiltern.
:L460b0			ldy	#$0f
::101			lda	(r0L),y
			cmp	#" "
			beq	:102
			cmp	#$a0
			bne	:103
::102			lda	#$00
			sta	(r0L),y
			dey
			bpl	:101
::103			rts

;*** Farben setzen und Titel ausgeben.
:L460c0			jsr	i_C_MenuClose
			b	$08,$05,$01,$01
			jsr	i_C_MenuTitel
			b	$09,$05,$17,$01

			lda	#$08			;Größe Dialogbox ohne Vorgabetext.
			bit	V460a2			;Vorgabetext möglich?
			bpl	:101			; => Nein, weiter...
			lda	#$0b			;Größe Dialogbox mit Vorgabetext.
::101			sta	:102 +3

			jsr	i_C_MenuBack
::102			b	$08,$06,$18,$08
			jsr	i_C_MenuMIcon
			b	$0a,$07,$02,$02
			jsr	i_C_MenuMIcon
			b	$0d,$07,$02,$02

			FillPRec$00,$28,$2f,$0040,$00ff

			jsr	UseGDFont
			MoveW	V460c1,r0
			LoadW	r11,80
			LoadB	r1H,46
			jsr	PutString

			jsr	i_BitmapUp		;"Löschen"-Icon.
			w	Icon_01
			b	$1c,$38,$02,$10
			jsr	i_C_MenuMIcon
			b	$1c,$07,$02,$02

			bit	V460a2			;Vorgabetext möglich ?
			bpl	:103			;Nein, weiter...
			jsr	i_BitmapUp		;"Vorgabe kopieren"-Icon.
			w	Icon_02
			b	$19,$38,$02,$10
			jsr	i_C_MenuMIcon
			b	$19,$07,$02,$02

::103			jsr	i_ColorBox
			b	$0a,$0a,$14,$02,$01
			LoadW	r0,V460d0		;Fenster für Texteingabe.
			jsr	GraphicsString

			bit	V460a2			;Vorgabetext möglich ?
			bpl	:104			;Nein, weiter...
			jsr	i_ColorBox
			b	$0a,$0e,$14,$02,$01
			LoadW	r0,V460d1		;Fenster für Vorgabetext.
			jsr	GraphicsString

			PrintStrgV460c5			;Vorgabetext ausgeben.
			LoadW	r0,V460a4
			jsr	PutString

::104			ClrB	currentMode
			rts

;*** Farben zurücksetzen..
:L460c1			jsr	i_C_ColorClr
			b	$08,$05,$18,$10
			FillPRec$00,$28,$8f,$0040,$00ff
			rts

;*** Tastatur-Abfrage installieren und
;    Cursor-Farbe festlegen.
:L460c2			php				;Interrupt sperren.
			sei

			lda	keyVector +0		;Aktuellen Tastaturabfrage-Vektor
			sta	V460a7    +0		;zwischenspeichern.
			lda	keyVector +1
			sta	V460a7    +1

			lda	#<L460d3		;Zeiger auf Eingaberoutine setzen.
			sta	keyVector +0
			lda	#>L460d3
			sta	keyVector +1

			ldx	CPU_DATA		;Cursorfarbe setzen.
			lda	#$35
			sta	CPU_DATA
			lda	#$00
			sta	$d028
			stx	CPU_DATA

			plp				;Interrupt wieder zurücksetzen.
			rts

;*** Dialogbox beenden.
:L460d0			lda	#$03			;"EXIT"-Icon.
			b $2c
:L460d1			lda	#$02			;"CLOSE"-Icon.
			sta	sysDBData
			jmp	RstrFrmDialogue

:L460d2			LoadB	keyData,CR		;"OK"-Icon simulieren.
			lda	keyVector+0
			ldx	keyVector+1
			jmp	CallRoutine

;*** Auswertung von RETURN.
:L460d3			php				;IRQ sperren und AKKU retten.
			sei

			pha

			CmpBI	keyData,CR		;RETURN gedrückt ?
			bne	:101			;Nein, weiter...

			LoadB	keyData,$ff		;$FF als Taste definieren, um Anzahl
			jsr	:102			;Zeichen in Puffer zu ermitteln.
			tya				;Tasten in Speicher ?
			beq	:103			;Nein, Abbruch...

			LoadB	keyData,CR		;RETURN-Taste in Tastaturspeicher.
			lda	V460a7    +0		;Tastatur-Vector zurücksetzen.
			sta	keyVector +0
			lda	V460a7    +1
			sta	keyVector +1

::101			pla				;Zur Tastaturabfrage.
			plp
::102			jmp	(V460a7)

::103			pla
			plp
			rts

;*** Zulässige Zeichen ausfiltern.
:L460e0			ldy	#$00
			sty	r2L
			sty	:102 +1
::101			sty	:103 +1
			lda	(r0L),y
			beq	:104
			jsr	L460e1			;Ist Zeichen erlaubt?
			cpx	#$00			; => Nein, Zeichen ignorieren.
			bne	:103
::102			ldy	#$ff
			sta	(r1L),y
			iny
			inc	r2L
			inc	:102 +1
			CmpBI	:102 +1,16
			beq	:104
::103			ldy	#$ff
			iny
			cpy	#$10			;Gesamten Text durchsucht?
			bne	:101			;=> Nein, weiter...

::104			ldy	:102 +1			;Textspeicher mit $00-Bytes
::105			lda	#$00			;auffüllen.
			sta	(r1L),y
			iny
			cpy	#$11
			bne	:105

			ldx	#r0L			;Vergleich Text = Vorgabetext?
			ldy	#r1L
			jmp	CmpString

;*** Prüfen ob Zeichen erlaubt.
:L460e1			ldy	#$00
::101			ldx	V460b0,y		;Ende Zeichenliste erreicht?
			beq	:102			; => Ja, Zeichen ungültig.
			cmp	V460b0,y		;Zeichen gültig?
			beq	:103			; => Ja, weiter...
			iny
			bne	:101
::102			ldx	#$ff
			rts
::103			ldx	#$00
			rts

;*** Mausklick auf Icon.
:L460f0			ldy	#$00
			jsr	L460g0
			sei
			php
			jsr	IsMseInRegion
			plp
			tax
			beq	:101
			jmp	L460f1

::101			bit	V460a2
			bpl	:102

			ldy	#$06
			jsr	L460g0
			sei
			php
			jsr	IsMseInRegion
			plp
			tax
			beq	:102
			jmp	L460f2

::102			rts

;*** Eingabe löschen.
:L460f1			jsr	InvertRectangle
			jsr	L460g1
			jsr	L460g2
			ldy	#$00
			jsr	L460g0
			jmp	InvertRectangle

;*** Vorgabetext auf Bildschirm.
:L460f2			jsr	InvertRectangle
			jsr	L460g1

			ldy	#$00
::101			sty	:102 +1
			lda	V460a4,y
			beq	:103

			sta	keyData
			lda	keyVector+0
			ldx	keyVector+1
			jsr	CallRoutine

::102			ldy	#$ff
			iny
			cpy	#$10
			bne	:101

::103			jsr	L460g2

			ldy	#$06
			jsr	L460g0
			jmp	InvertRectangle

;*** Daten kopieren.
:L460g0			ldx	#$00
::101			lda	V460e0,y
			sta	r2L,x
			iny
			inx
			cpx	#6
			bne	:101
			rts

;*** Texteingabe löschen.
:L460g1			lda	#$00
::101			pha
			LoadB	keyData,30
			lda	keyVector+0
			ldx	keyVector+1
			jsr	CallRoutine
			pla
			add	1
			cmp	#$10
			bne	:101

			lda	#$00
::102			pha
			LoadB	keyData,29
			lda	keyVector+0
			ldx	keyVector+1
			jsr	CallRoutine
			pla
			add	1
			cmp	#$10
			bne	:102
			rts

;*** Warten bis keine Maustaste gedrückt.
:L460g2			php
			cli
::621			lda	mouseData
			bpl	:621
			ClrB	pressFlag
			plp
			rts

;*** Variablen.
:V460a0			w $0000				;Adr. Vorgabetext.
:V460a1			w $0000				;Adr. Eingabespeiher.
:V460a2			b $00				;$FF = Vorgabetext möglich.
:V460a3			b $00				;$FF = Vorgabetext vorgeben.
:V460a4			s 17				;Text für Vorgabe.
:V460a5			s 17				;Texteingabe.
:V460a6			s 17				;Zwischenspeicher.
:V460a7			w $0000				;Zeiger auf Tastaturabfrage.

:V460b0			b " !#%&'`^/()+-.0123456789;<=>"
			b "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜß"
			b "abcdefghijklmnopqrstuvwxyzäöü_"
			b NULL

;*** Dialogbox: Eingabe CBM-Datei-Name.
:V460c0			b %00100000
			b 40,143
			w 64,255
			b DBUSRICON  ,  0,  0
			w V460c2
			b DBUSRICON  ,  2, 16
			w V460c3
			b DBUSRICON  ,  5, 16
			w V460c4
			b DB_USR_ROUT
			w L460c0
			b DBGETSTRING, 20, 44
			b r10L,16
			b DB_USR_ROUT
			w L460c2
			b DBOPVEC
			w L460f0
			b NULL

:V460c1			w $0000

:V460c2			w Icon_Close
			b $00,$00,$01,$08
			w L460d1
:V460c3			w Icon_00
			b $00,$00,$02,$10
			w L460d0
:V460c4			w Icon_03
			b $00,$00,$02,$10
			w L460d2

:V460c5			b PLAINTEXT
			b GOTOXY
			w 80
			b 108

if Sprache = Deutsch
			b "Vorgabetext: "
endif

if Sprache = Englisch
			b "Default: "
endif

			b GOTOXY
			w 84
			b 122
			b NULL

;*** Eingabefenster.
:V460d0			b MOVEPENTO
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

:V460d1			b MOVEPENTO
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

:V460e0			b $38,$47
			w $1c*8,$1c*8+15
			b $38,$47
			w $19*8,$19*8+15

:Buffer			s 100

;*** Icons.
:Icon_00
<MISSING_IMAGE_DATA>

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>
