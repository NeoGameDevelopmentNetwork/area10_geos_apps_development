; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L010: Word in FAC übertragen.
.Word_FAC		sta	$63
			stx	$62
			ldx	#$90
			sec
			jmp	BINFAC

;*** L011: BASIC-ROM einblenden.
.InitForBA		jsr	InitForIO
			LoadB	$01,$37
			ldx	#$10
::1			lda	$20,x
			sta	V011a0,x
			lda	$61,x
			sta	V011a1,x
			dex
			bpl	:1
			MoveB	$47,V011a2+0
			MoveB	$5d,V011a2+1
			rts

;*** L012: BASIC-ROM ausblenden.
.DoneWithBA		ldx	#$10
::1			lda	V011a0,x
			sta	$20,x
			lda	V011a1,x
			sta	$61,x
			dex
			bpl	:1
			MoveB	V011a2+0,$47
			MoveB	V011a2+1,$5d
			jmp	DoneWithIO

:V011a0			s 17
:V011a1			s 17
:V011a2			b $00,$00

;*** L013: Zahl formatiert ausgeben.
;			r11   = X-Koordinate
;			r1H   = Y-Koordinate
;":Do_Zahl"		a     = Anzahl Zeichen
;			y     = Auszugebende Zahl
;":Do_ZFAC		y     = Anzahl Zeichen
;              $0100 = Textzahl
.Do_Zahl		sta	V013a1
			tya
			pha
			jsr	InitForBA
			pla
			tay
			jsr	BYTFAC
			jsr	x_FLPSTR
			jsr	DoneWithBA
			ldy	V013a1
			lda	#"0"
			bne	L013a
.Do_ZFAC		lda	#" "
			sty	V013a1
:L013a			sta	V013a0
			ldx	#$01
::1			lda	$0100,x
			beq	:2
			inx
			dec	V013a1
			bne	:1
::2			ldy	V013a1
			beq	:3
			lda	V013a0
			jsr	SmallPutChar
			dec	V013a1
			jmp	:2

::3			LoadW	r0,$0101
			jmp	PutString

:V013a0			b $00
:V013a1			b $00

;*** L014: Bitmap-Farbe setzen.
.CSet_Rot		lda	#$21
			b	$2c
.CSet_Blau		lda	#$61
			b	$2c
.CSet_Grau		lda	#$b1
			ldy	#$02
::1			sta	COLOR_MATRIX+ 9*40+10,y
			sta	COLOR_MATRIX+10*40+10,y
			sta	COLOR_MATRIX+11*40+10,y
			dey
			bpl	:1
			rts

;*** L015: Bitmaps auf Screen.
.ISet_Info		jsr	CSet_Blau
			jsr	i_BitmapUp
			w	icon_Info
			b	10,72,icon_Info_x,icon_Info_y
			rts
.ISet_Achtung		jsr	CSet_Rot
			jsr	i_BitmapUp
			w	icon_Warnung
			b	10,72,icon_Warnung_x,icon_Warnung_y
			rts
.ISet_Frage		jsr	CSet_Rot
			jsr	i_BitmapUp
			w	icon_Frage
			b	10,72,icon_Frage_x,icon_Frage_y
			rts

;*** L016: Font laden.
.UseGDFont		LoadW	r0,Font
			jmp	LoadCharSet

;*** L017: Info-Fenster öffnen
.DoInfoBox		jsr	SetInfoBox
			jmp	ISet_Info

.SetInfoBox		jsr	UseSystemFont
			Display	ST_WR_FORE

			Pattern	1
			FillRec	64,119,72,263
			Pattern	0
			FillRec	56,111,64,255
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec58,109,67,252,%11111111
			FrameRec59,108,68,251,%11111111
			rts

;*** L018: Info-Box wieder herstellen.
.ReDoBox		jsr	CSet_Grau
			jsr	i_RecoverRectangle
			b	56,119
			w	64,263
			rts

;*** L019: Info-Box wieder löschen.
.ClrBox			jsr	CSet_Grau
			Display	ST_WR_FORE
			Pattern	2
			FillRec	56,119,64,263
			rts

;*** L020: Info-Box-Text löschen.
.ClrBoxText		Pattern	0
			FillRec	68,92,110,250
			rts

;*** L021: Farbige Dialogbox wiederherstellen.
.DoRecDlgBox		LoadW	ReDoCDlgBox+16,RecoverRectangle
			jmp	DoCDlgBox

;*** L022: Farbige Dialogbox löschen.
.DoClrDlgBox		LoadW	ReDoCDlgBox+16,Rectangle

;*** L023: Farbige Dialogbox.
.DoCDlgBox		sty	ReDoCDlgBox +5
			stx	ReDoCDlgBox +6
			ClrB	ReDoCDlgBox +1
			SetRecVecReDoCDlgBox
			Display	ST_WR_FORE
			jsr	DoDlgBox
			SetRecVecRecoverRectangle
			rts

;*** L024: Farbige Dialogbox wiederherstellen.
.ReDoCDlgBox		lda	#$00
			bne	:1
			jsr	$ffff
			inc	ReDoCDlgBox +1
::1			lda	#$02
			jsr	SetPattern
			jmp	$ffff

;*** Info-Box Icons.
.icon_Info

<MISSING_IMAGE_DATA>
.icon_Info_x			= .x
.icon_Info_y			= .y

.icon_Warnung
<MISSING_IMAGE_DATA>
.icon_Warnung_x		= .x
.icon_Warnung_y		= .y

.icon_Frage
<MISSING_IMAGE_DATA>
.icon_Frage_x		= .x
.icon_Frage_y		= .y

;*** System-Icons.
.icon_Close
<MISSING_IMAGE_DATA>
.icon_Close_x		= .x
.icon_Close_y		= .y
