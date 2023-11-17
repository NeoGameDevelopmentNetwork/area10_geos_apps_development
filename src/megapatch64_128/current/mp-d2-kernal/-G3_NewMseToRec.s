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
			bmi	:102			;Ja, Fehler anzeigen.
			cpx	mouseXPos  +1		;Mauszeiger links von
			bne	:101			;aktueller Bereichsgrenze ?
			cpy	mouseXPos  +0
::101			bcc	:103			;Nein, weiter...
			beq	:103			;Nein, weiter...

::102			lda	#%00100000		;Mauszeiger hat linke Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;linke Grenze setzen.
			sty	mouseXPos  +0
			stx	mouseXPos  +1

::103			ldy	mouseRight +0
			ldx	mouseRight +1
			cpx	mouseXPos  +1		;Mauszeiger über rechten Rand ?
			bne	:104
			cpy	mouseXPos  +0
::104			bcs	:105			;Nein, weiter...

			lda	#%00010000		;Mauszeiger hat rechte Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;rechte Grenze setzen.
			sty	mouseXPos  +0
			stx	mouseXPos  +1

::105			ldy	mouseTop
			lda	mouseYPos		;Hat Mauszeiger die untere
			cmp	#$e4			;Bildgrenze überschritten ?
			bcs	:106			;Ja, Fehler anzeigen.
			cpy	mouseYPos		;Mauszeiger über obere Grenze ?
			bcc	:107			;Nein, weiter...
			beq	:107			;Nein, weiter...

::106			lda	#%10000000		;Mauszeiger hat obere Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;obere Grenze setzen.
			sty	mouseYPos

::107			ldy	mouseBottom
			cpy	mouseYPos		;Mauszeiger über untere Grenze?
			bcs	:108			;Nein, weiter...

			lda	#%01000000		;Mauszeiger hat untere Grenze
			ora	faultData		;überschritten. Mauszeiger auf
			sta	faultData		;untere Grenze setzen.
			sty	mouseYPos

::108			bit	mouseOn			;PullDown-Menü aktiv ?
			bvc	:113			;Nein, weiter...
			lda	mouseYPos		;Ist Mauszeiger zwischen oberer
			cmp	DM_MenuRange+0		;und untere Grenze des Menü-
			bcc	:112			;fensters ?
			cmp	DM_MenuRange+1
			beq	:109
			bcc	:109

			lda	menuNumber		;Hauptmenü ?
			beq	:112			;Ja, weiter...
			bit	Flag_MenuStatus		;Menüs nach unten verlassen ?
			bvc	:112			;Ja, weiter...
			lda	DM_MenuRange+1
			sta	mouseYPos		;Mauszeiger festsetzen.

::109			lda	mouseXPos+1		;Ist Mauszeiger zwischen linker
			cmp	DM_MenuRange+3		;und rechter Grenze des Menü-
			bne	:110			;fensters ?
			lda	mouseXPos+0
			cmp	DM_MenuRange+2
::110			bcc	:112			;Nein, Fehler anzeigen.
			lda	mouseXPos+1
			cmp	DM_MenuRange+5
			bne	:111
			lda	mouseXPos+0
			cmp	DM_MenuRange+4
::111			bcc	:113			;Ja, weiter...
			beq	:113			;Ja, weiter...
::112			lda	#%00001000		;Mauszeiger hat aktuelles
			ora	faultData		;PullDown-Menü verlassen.
			sta	faultData
::113			rts
