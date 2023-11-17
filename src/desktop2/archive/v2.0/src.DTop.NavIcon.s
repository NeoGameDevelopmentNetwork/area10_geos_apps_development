; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Navigationsicons anzeigen.
:setPageNavIcon		lda	#> tabIconSlctPage
			sta	r0H
			lda	#< tabIconSlctPage
			sta	r0L			;Page-Icon.

			lda	a7L			;Icon-Modus?
			beq	:1			; => Ja, weiter...

;--- Untere Navigationsleiste.
			jsr	i_FrameRectangle
			b AREA_FULLPAD_Y1 -19,AREA_FULLPAD_Y1 -4
			w AREA_FULLPAD_X0    ,AREA_FULLPAD_X1
			b %11111111

			lda	#> tabIconScrUpDn
			sta	r0H
			lda	#< tabIconScrUpDn
			sta	r0L			;Scroll-Icon.

;--- Navigation installieren.
::1			lda	#ICON_PGNAV		;Page-/Scroll-Icon.
			jsr	add1Icon2Tab

;--- Close-Icon installieren.
			lda	#> tabIconDkClose
			sta	r0H
			lda	#< tabIconDkClose
			sta	r0L

			lda	#ICON_CLOSE		;Close-Disk-Icon.
			jsr	add1Icon2Tab

			lda	#$02
			sta	r13L

			lda	#ICON_PGNAV
			jmp	prntIconTabA

;*** Anzeige nach Icons.
:tabIconSlctPage	w icon_SlctPage
			b $01,$7c,$02,$10
			w func_SlctPage

;*** Textanzeige.
:tabIconScrUpDn		w icon_ScrollUpDn
			b $10,$7c,$02,$10
			w func_ScrollUpDn

;*** Diskette schließen.
:tabIconDkClose		w icon_CloseDisk
			b $1e,$11,$02,$0b
			w keybDiskClose
