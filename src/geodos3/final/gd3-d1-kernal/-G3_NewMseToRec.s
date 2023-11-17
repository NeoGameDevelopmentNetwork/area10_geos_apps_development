; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Mauszeiger in Bereich festsetzen.
:SetMseToArea		ldy	mouseLeft  +0
			ldx	mouseLeft  +1
			lda	mouseXPos  +1		;Mauszeiger über linken Rand ?
			bmi	:2			;Ja, Fehler anzeigen.
			cpx	mouseXPos  +1		;Mauszeiger links von
			bne	:1			;aktueller Bereichsgrenze ?
			cpy	mouseXPos  +0
::1			bcc	:3			;Nein, weiter...
			beq	:3			;Nein, weiter...

::2			jsr	:setFaultLeft
;			lda	#%00100000		;Mauszeiger hat linke Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;linke Grenze setzen.
			sty	mouseXPos  +0
			stx	mouseXPos  +1

::3			ldy	mouseRight +0
			ldx	mouseRight +1
			cpx	mouseXPos  +1		;Mauszeiger über rechten Rand ?
			bne	:4
			cpy	mouseXPos  +0
::4			bcs	:5			;Nein, weiter...

			jsr	:setFaultRight
;			lda	#%00010000		;Mauszeiger hat rechte Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;rechte Grenze setzen.
			sty	mouseXPos  +0
			stx	mouseXPos  +1

::5			ldy	mouseTop
			lda	mouseYPos		;Hat Mauszeiger die untere
			cmp	#$e4			;Bildgrenze überschritten ?
			bcs	:6			;Ja, Fehler anzeigen.
			cpy	mouseYPos		;Mauszeiger über obere Grenze ?
			bcc	:7			;Nein, weiter...
			beq	:7			;Nein, weiter...

::6			jsr	:setFaultTop
;			lda	#%10000000		;Mauszeiger hat obere Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;obere Grenze setzen.
			sty	mouseYPos

::7			ldy	mouseBottom
			cpy	mouseYPos		;Mauszeiger über untere Grenze?
			bcs	:8			;Nein, weiter...

			jsr	:setFaultBottom
;			lda	#%01000000		;Mauszeiger hat untere Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;untere Grenze setzen.
			sty	mouseYPos

;--- PullDown-Menüs testen.
::8			bit	mouseOn			;PullDown-Menü aktiv ?
			bvc	:exit			; => Nein, Ende...

			lda	mouseYPos		;Ist Mauszeiger zwischen oberer
			cmp	DM_MenuRange+0		;und untere Grenze des Menü-
			bcc	:setFaultMenu		;fensters ?
			cmp	DM_MenuRange+1
			beq	:9
			bcc	:9

			lda	menuNumber		;Hauptmenü ?
			beq	:setFaultMenu		; => Ja, Menü beenden.
			bit	Flag_MenuStatus		;Menüs nach unten verlassen ?
			bvc	:setFaultMenu		; => Ja, Menü beenden.

			lda	DM_MenuRange+1
			sta	mouseYPos		;Mauszeiger festsetzen.

::9			lda	mouseXPos+1		;Ist Mauszeiger zwischen linker
			cmp	DM_MenuRange+3		;und rechter Grenze des Menü-
			bne	:10			;fensters ?
			lda	mouseXPos+0
			cmp	DM_MenuRange+2
::10			bcc	:setFaultMenu		; => Nein, Menü beenden.
			lda	mouseXPos+1
			cmp	DM_MenuRange+5
			bne	:11
			lda	mouseXPos+0
			cmp	DM_MenuRange+4
::11			bcc	:exit			; => Ja, Ende...
			beq	:exit			; => Ja, Ende...

;*** Bereichsgrenzen erreicht.
::setFaultMenu		lda	#%00001000		;Aktuelles Menü verlassen.
			b $2c
::setFaultLeft		lda	#%00100000		;Grenze erreicht: Links.
			b $2c
::setFaultRight		lda	#%00010000		;Grenze erreicht: Rechts.
			b $2c
::setFaultTop		lda	#%10000000		;Grenze erreicht: Oben.
			b $2c
::setFaultBottom	lda	#%01000000		;Grenze erreicht: Unten.
			ora	faultData		;":faultData" aktualisieren.
			sta	faultData
::exit			rts
