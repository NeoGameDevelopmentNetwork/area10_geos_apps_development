; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Fortschrittsanzeige ausgeben.
;    Übergabe: statusPos = Position innerhalb Einträge.
:prntStatus		jsr	clrFileInfo		;Anzeigebereich Dateiname löschen.

			LoadW	r0,curFileName
			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y3
			jsr	smallPutString		;Dateiname anzeigen.

			lda	slctFiles		;Verbleibende Dateien anzeigen.
			sec
			sbc	statusPos
			sta	r0L
			ClrB	r0H
			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y1
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal
			lda	#" "
			jmp	SmallPutChar		;Anzeige korrigieren.

;*** Anzeigebereich Dateiname löschen.
:clrFileInfo		lda	#$00
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y3 -6
			b	INFO_Y3 +1
			w	INFO_X0
			w	(STATUS_X + STATUS_W) -8
			rts
