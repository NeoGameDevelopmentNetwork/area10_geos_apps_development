; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Standard-Dialogbox "OK" / "CANCEL".
; Datum			: 02.07.97
; Aufruf		: JSR  BOX_OK
;			  JSR  BOX_CANCEL
; Übergabe		: AKKU,xRegWord Zeiger auf Definitions-Tabelle
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -DoDlgBox Dialogbox aufrufen
;			  -SetPattern Füllmuster setzen
;			  -Rectangle Rechteck zeichnen
;			  -i_C_DBoxTitel									 Farbe für Titelzeile
;			  -i_C_DBoxBack Farbe für Dialogbox
;			  -i_C_DBoxDIcon									 Farbe für Icons
;******************************************************************************

;******************************************************************************
; Funktion		: Standard-Dialogbox.
; Datum			: 02.07.97
; Aufruf		: JSR  DoUserBox									 Dialogbox ausgeben
; Übergabe		: AKKU,xRegWord Zeiger auf Definitions-Tabelle
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -DoDlgBox Dialogbox aufrufen
;			  -SetPattern Füllmuster setzen
;			  -Rectangle Rechteck zeichnen
;			  -i_C_DBoxTitel									 Farbe für Titelzeile
;			  -i_C_DBoxBack Farbe für Dialogbox
;			  -i_C_DBoxDIcon									 Farbe für Icons
;******************************************************************************

;******************************************************************************
; Funktion		: GEOS-Dialogbox mit ":RecoverVector".
; Datum			: 02.07.97
; Aufruf		: JSR  DBRECVBOX									 Dialogbox ausgeben
; Übergabe		: AKKU,xRegWord RecoverVector-Routine (l,h)
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -DoDlgBox Dialogbox aufrufen
;******************************************************************************

;*** "OK"/"CLOSE"-Userbox.
.BOX_OK			ldy	#OK			;Dialogbox mit "OK" ausgeben.
			b $2c
.BOX_CANCEL		ldy	#CANCEL			;Dialogbox mit "CANCEL" ausgeben.
			sty	StdDlgBoxData+7

			jsr	InitDBvec		;Dialogbox initialisieren.
			ClrB	DlgIconTyp2		;Zweites Icon abschalten.

			ldy	#< DB_1Icon		;Farbe für ein Icon und
			ldx	#> DB_1Icon		;Dialogbox starten.
			jmp	DoUserBox1

.DoUserBox		jsr	InitDBvec		;Dialogbox initialisieren.
			iny
			lda	(r0L),y
			sta	DlgIconTyp1		;Erstes Icon definieren.
			iny
			lda	(r0L),y
			sta	DlgIconTyp2		;Zweites Icon definieren.

			ldy	#< DB_2Icon		;Farbe für zwei Icons und
			ldx	#> DB_2Icon		;Dialogbox starten.

;*** Dialogbox aufrufen.
:DoUserBox1		sty	DB_Init1 +1		;Zeiger auf Routine zum setzen der
			stx	DB_Init1 +2		;Icon-Farben merken.

			lda	#< :111
			ldx	#> :111
			jsr	:102			;":RecoverVecktor" definieren.

			jsr	i_C_DBoxTitel
			b	$06,$05,$1c,$01
			jsr	i_C_DBoxBack
			b	$06,$06,$1c,$0b

			jsr	UseGDFont		;GeoDOS-Zeichensatz aktivieren.

			LoadB	dispBufferOn,ST_WR_FORE

			lda	#$00			;Bereich Titelzeile löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$2f
			w	$0030,$010f

			jsr	i_PutString		;Text für Titelzeile ausgeben.
			w	$0038
			b	$2e
			b	PLAINTEXT
			b	"Information"
			b	NULL

			jsr	UseSystemFont

			LoadW	r0,StdDlgBoxData	;Dialogbox aufrufen.
			jsr	DoDlgBox

			lda	#< RecoverRectangle
			ldx	#> RecoverRectangle
::102			sta	RecoverVector+0
			stx	RecoverVector+1
			rts

;*** Hintergrund wieder herstellen.
::111			jsr	i_C_ColorClr
			b	$06,$05,$1c,$0c

			LoadB	dispBufferOn,ST_WR_FORE

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$87
			w	$0030,$010f
			rts

;*** Farbe für Dialogbox-Icons ausgeben.
:DB_2Icon		jsr	i_C_DBoxDIcon
			b	$08,$0e,$06,$02
:DB_1Icon		jsr	i_C_DBoxDIcon
			b	$1a,$0e,$06,$02
			rts

;*** Dialogbox initialisieren.
:InitDBvec		sta	r0L
			stx	r0H
			ldy	#$00
::101			lda	(r0L),y
			sta	r14,y
			iny
			cpy	#$04
			bne	:101
			lda	(r0L),y
			sta	DB_Init2 +1
			iny
			lda	(r0L),y
			sta	DB_Init2 +2
			rts

;*** Dialogbox.
:StdDlgBoxData		b %00100000
			b 48,135
			w 48,271
:DlgIconTyp1		b CANCEL    , 20, 64
			b DBVARSTR  ,DBoxLeft,DBoxBase1
			b r14L
			b DBVARSTR  ,DBoxLeft,DBoxBase2
			b r15L
			b DB_USR_ROUT
			w DB_Init
:DlgIconTyp2		b OK        ,  2, 64
			b NULL

;*** Dialogbox initialisieren.
:DB_Init
:DB_Init1		jsr	$ffff			;Iconfarbe setzen.
:DB_Init2		jmp	$ffff			;Infoicon ausgeben.

;*** ":RecoverVector" setzen und Dialogbox aufrufen.
.DBRECVBOX		sta	RecoverVector +0
			stx	RecoverVector +1
			jmp	DoDlgBox
