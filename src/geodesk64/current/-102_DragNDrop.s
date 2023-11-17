; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Icon verschieben.
;    Übergabe: r4 = Zeiger auf Icon-Daten.
;    Rückgabe: XReg = $00/Kein Fehler.
;              AKKU = Fenster-Nr. für Icon-Ablage.
:DRAG_N_DROP_ICON	jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Farbe Sprite#1 = Icon.
			sta	mob1clr
			lda	#$07			;Farbe Sprite#2 = Hintergrund.
			sta	mob2clr

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	#$ff			;Hintergrund-Sprite#2 löschen.
			ldy	#$3e 			;Dieses Sprite deckt dann den
::1			sta	spr2pic,y		;Bildschirm-Hintergrund ab.
			dey
			bpl	:1

			LoadB	r3L,1			;Icon-Daten in Sprite#1 kopieren.
			jsr	DrawSprite
			jsr	EnablSprite

			LoadB	r3L,2			;Hintergrund-Sprite#2 einschalten.
			jsr	EnablSprite

			LoadB	mouseTop   ,$00
			LoadB	mouseBottom,MIN_AREA_BAR_Y -$08 -$18
			LoadW	mouseLeft  ,$0010
			LoadW	mouseRight ,SCRN_WIDTH   -$10 -$18

			MoveW	appMain,:appMain_Buf
			LoadW	appMain,:chkMouse

			pla
			sta	:returnAdr_Buf +1
			pla
			sta	:returnAdr_Buf +0
			rts

::appMain_Buf		w $0000
::returnAdr_Buf		w $0000

;--- DnD-Icon mit Mauszeiger synchronisieren.
::chkMouse		MoveW	mouseXPos,r4
			MoveB	mouseYPos,r5L
			LoadB	r3L,1
			jsr	PosSprite
			LoadB	r3L,2
			jsr	PosSprite

			lda	mouseData		;Maustaste gedrückt?
			bmi	:2			; => Nein, weiter...

			lda	:appMain_Buf +0		;Original-MainLoop fortsetzen.
			ldx	:appMain_Buf +1
			jmp	CallRoutine

;--- Icon wurde abgelegt:
::2			LoadB	r3L,1			;DnD-Icon abschalten.
			jsr	DisablSprite
			LoadB	r3L,2
			jsr	DisablSprite

			jsr	WM_NO_MOUSE_WIN		;Grenzen für Mauszeiger löschen.

			lda	:appMain_Buf +0		;MainLoop zurücksetzen.
			sta	appMain +0
			lda	:appMain_Buf +1
			sta	appMain +1

			lda	:returnAdr_Buf +0	;Rücksprungadresse setzen.
			pha
			lda	:returnAdr_Buf +1
			pha

			jsr	WM_FIND_WINDOW		;Wurde Icon auf Fenster abgelegt?
			cpx	#NO_ERROR		;DeskTop = Fenster #0!
			bne	:3			; => Nein, Ende.
			lda	WM_STACK,y		;Fenster-Nr. einlesen.
::3			rts
