; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Position für Border-Icon suchen.
:findFreeBIconPos	jsr	r1_tabBIconDkNm

			ldy	#$00

			lda	#ICON_BORDER
			sta	a4H

::1			lda	(r1L),y			;Freier Eintrag?
			beq	:setpos			; => Ja, Ende...

			inc	a4H
			jsr	setNxBIconDkNm
			bcc	:1			; => Weitersuchen...

;--- Alle Einträge im Border belegt.
;Suche nach Dateien von einer anderen
;Disk im Border.
			ldx	#r0L
			jsr	setVecOpenDkNm
			jsr	r1_tabBIconDkNm

			lda	#ICON_BORDER
			sta	a4H

::2			ldx	#r0L			;Border-Datei auf
			ldy	#r1L			;der aktuellen Disk?
			lda	#18
			jsr	CmpFString
			bne	:setpos			; => Nein, weiter...

			inc	a4H
			jsr	setNxBIconDkNm
			bcc	:2			; => Weitersuchen...

;--- Hinweis:
;Der BRK-Befehl wird nicht erreicht,
;da max. 8 Dateien im Border enthalten
;sein können.
			brk				;Panic!

;--- Zeiger auf Dateieintrag ermitteln.
::setpos		lda	a4H
			ldx	#r5L
			jsr	setVecIcon2File
			ldx	#NO_ERROR
			rts

;*** Zeiger auf Diskname für nächstes Icon setzen.
;Rückgabe: C-Flag=1: Diskname für Icon nicht gefunden.
;          C-Flag=0: Suche noch nicht beendet.
:setNxBIconDkNm		lda	r1L
			clc
			adc	#18
			sta	r1L
			tax
			bcc	:1
			inc	r1H
::1			cmp	#> tabBIconDkNm +7*18
			bcc	:ok
			cpx	#< tabBIconDkNm +7*18
			bcc	:ok
			beq	:ok

::fail			sec
			rts

::ok			clc
			rts

;*** Freie Position im Border suchen.
:getFreeBorderPos	ldy	#$02
			lda	#> buf_diskSek3
			sta	r5H
			lda	#< buf_diskSek3
			sta	r5L
::1			lda	(r5L),y
			beq	:found
			tya
			clc
			adc	#$20
			tay
			bcc	:1
			bcs	:exit
::found			tya
			clc
			adc	r5L
			sta	r5L
			bcc	:2
			inc	r5H
::2			clc
::exit			rts

;*** Icon für Datei im Border einlesen.
:readBorderIcon		ldy	#$00
			lda	(r14L),y		;Datei vorhanden?
			beq	:ok			; => Nein, Ende...

			jsr	findFreeBIconPos

			ldx	#r14L
			ldy	#r5L
			lda	#30
			jsr	CopyFString

			ldx	#r0L
			jsr	setVecOpenDkNm

			ldx	#r0L
			ldy	#r1L
			lda	#18
			jsr	CopyFString

			ldy	#$16
			lda	(r14L),y		;GEOS-Datei?
			beq	:skip			; => Nein, weiter...

			ldy	#$13			;Infoblock einlesen.
			lda	(r14L),y
			sta	r1L
			iny
			lda	(r14L),y
			sta	r1H
			jsr	getDiskBlock
			txa
			bne	:exit

			lda	a4H
			ldx	#r5L
			jsr	setVec2FileIcon

			ldx	#r4L
			ldy	#r5L
			lda	#68
			jsr	CopyFString

::skip			lda	a4H
			jsr	copyFIcon2Buf

::ok			ldx	#NO_ERROR
::exit			rts
