; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Farben für Info-Icons setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  CSet_Rot Icon-Farbe "Rot"  Warnung
;			: JSR  CSet_Blau									 Icon-Farbe "Blau" Information
; Übergabe		: -
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5L,r5H,r6L,r6H
;			  r7L,r8
; Variablen		: -C_DBoxColByte Hintergrundfarbe Infobox
; Routinen		: -i_ColorBox Farbrechteck zeichnen
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Info-Icons setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  CSet_RB_xy									 Beliebige Icon-Farbe setzen.
; Übergabe		: AKKU	Byte Farbwert für Icon.
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5L,r5H,r6L,r6H
;			  r7L,r8
; Variablen		: -
; Routinen		: -i_ColorBox Farbrechteck zeichnen
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Info-Icons setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  CSet_Col Beliebige Icon-Farbe an
;				 freie X/Y-Position setzen
; Übergabe		: AKKU	Byte Farbwert für Icon
;			  xReg	Byte X-Koordinate in CARDs
;			  yReg	Byte Y-Koordinate in CARDs
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5L,r5H,r6L,r6H
;			  r7L,r8
; Variablen		: -
; Routinen		: -i_ColorBox Farbrechteck zeichnen
;******************************************************************************

;******************************************************************************
; Funktion		: GeODOS-Info-Icons ausgeben.
; Datum			: 02.07.97
; Aufruf		: JSR  ISet_Info									 Icon: Info
;			: JSR  ISet_Achtung									 Icon: Warnung
;			: JSR  ISet_Frage									 Icon: Frage
; Übergabe		: AKKU,xRegWord Zeiger auf Bitmap (low,high)
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r9L
; Variablen		: -
; Routinen		: -i_BitmapUp Bitmap ausgeben
;******************************************************************************

;******************************************************************************
; Funktion		: Infobox zeichnen.
; Datum			: 02.07.97
; Aufruf		: JSR  DoInfoBox									 Infobox mit Icon ausgeben
;			: JSR  SetInfoBox									 Leere Infobox zeichnen
;			: JSR  ClrBox Infobox wieder löschen
;			  JSR  ClrBoxText									 Textbereich in Infobox löschen
; Übergabe		: -
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r2 bis r9, r11
; Variablen		: -
; Routinen		: -SetPattern Füllmuster setzen
;			  -i_Rectangle Rechteck zeichnen
;			  -i_BitmapUp Bitmap ausgeben
;			  -i_GraphicsString									 Grafikbefehle ausführen
;			  -i_InfoCol Infobox-Farbe ausgeben
;			  -i_NoBackCol Infobox löschen
;******************************************************************************

;*** Bitmap-Farbe setzen.
.CSet_Rot		lda	C_DBoxBack
			and	#%00001111
			ora	#$20
			bne	CSet_RB_xy

.CSet_Blau		lda	C_DBoxBack
			and	#%00001111
			ora	#$60

.CSet_RB_xy		ldx	#$08
			ldy	#$08

.CSet_Col		sta	:102      +7
			and	#%11110001
			ora	#%00000001
			sta	:103      +7

			stx	:102 +3
			inx
			stx	:103 +3

			sty	:102 +4
			sty	:103 +4

::102			jsr	i_ColorBox
			b	$08,$08,$03,$03,$ff
::103			jsr	i_ColorBox
			b	$09,$08,$01,$02,$ff
			rts

;*** Bitmaps auf Screen.
.ISet_Info		jsr	CSet_Blau
			lda	#<Icon_Info
			ldx	#>Icon_Info
			bne	ISet_Icon

.ISet_Achtung		jsr	CSet_Rot
			lda	#<Icon_Warnung
			ldx	#>Icon_Warnung
			bne	ISet_Icon

.ISet_Frage		jsr	CSet_Rot
			lda	#<Icon_Frage
			ldx	#>Icon_Frage

:ISet_Icon		sta	:101 +0
			stx	:101 +1
			jsr	i_BitmapUp
::101			w	$ffff
			b	$08,$40,$03,$15
			rts

;*** Info-Fenster öffnen
.DoInfoBox		jsr	SetInfoBox		;Infobox darstellen.

			lda	C_IBoxBack		;Farbe für Infobox-Icon
			and	#%00001111		;berechnen.
			ora	#$60
			ldx	#$09			;X/Y-Koordinaten für Infobox-Icon
			ldy	#$09			;berechnen.
			jsr	CSet_Col		;Farbe für Infobox-Icon ausgeben.

			jsr	i_BitmapUp		;Info-Icon ausgeben.
			w	Icon_Info
			b	$09,$48,$03,$15
			rts

;*** Infobox ausgeben.
.SetInfoBox		jsr	i_C_IBoxBack		;Farbe für Infobox ausgeben.
			b	$07,$07,$19,$07

			LoadB	dispBufferOn,ST_WR_FORE
			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0038
			b	$38
			b	RECTANGLETO
			w	$00ff
			b	$6f

			b	FRAME_RECTO
			w	$0038
			b	$38

			b	MOVEPENTO
			w	$003b
			b	$3a
			b	FRAME_RECTO
			w	$00fc
			b	$6d

			b	MOVEPENTO
			w	$003c
			b	$3b
			b	FRAME_RECTO
			w	$00fb
			b	$6c
			b	NULL

			jmp	UseSystemFont

;*** Info-Box wieder löschen.
.ClrBox			jsr	i_C_ColorClr
			b	$07,$07,$19,$07

			LoadB	dispBufferOn,ST_WR_FORE

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$38,$77
			w	$0030,$00ff
			rts

;*** Info-Box-Text löschen.
.ClrBoxText		LoadB	dispBufferOn,ST_WR_FORE

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$44,$5c
			w	$0066,$00fa
			rts

;*** Icons.
.Icon_Info
<MISSING_IMAGE_DATA>

.Icon_Warnung
<MISSING_IMAGE_DATA>

.Icon_Frage
<MISSING_IMAGE_DATA>

.Icon_Close
<MISSING_IMAGE_DATA>
