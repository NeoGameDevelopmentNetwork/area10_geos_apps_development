; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RegisterMenü aktivieren.
:ENABLE_REG_MENU	PushW	r0			;Zeiger auf Register-Menü speichern.

			ClrB	exitCode		;Rückgabewert löschen.

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Register-Font aktivieren.

			PopW	r0			;Zeiger auf Register-Menü.

			ldy	#$00			;Position für "X"-Icon
			lda	(r0L),y			;aus Register-Menü berechnen.
			sec
			sbc	#$08
			sta	IconExitPos +1		;Y-Koorfinate.
			iny
			iny
			lda	(r0L),y
			sta	IconExitPos +0		;X-Koordinate, wird in CARDs
			iny				;umgerechnet.
			lda	(r0L),y
			lsr
			ror	IconExitPos +0
			lsr
			ror	IconExitPos +0
			lsr
			ror	IconExitPos +0
			inc	IconExitPos +0

			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" initialisieren.
			lda	IconExitPos +0		;X-Position für Farbe.
			sta	:x

			lda	IconExitPos +1		;Y-Position für Farbe.
			lsr				;In CARDs umrechnen.
			lsr
			lsr
			sta	:y

			lda	C_RegisterExit		;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
::x			b	(R1SizeX0/8) +1
::y			b	(R1SizeY0/8) -1
			b	IconExit_x
			b	IconExit_y/8

			LoadW	r0,IconMenu1		;Zeiger auf "X"-Icon-Menü.
			jmp	DoIcons			;Icon-Menü aktivieren.

;*** Zurück zum DeskTop.
:DISABLE_REG_MENU	lda	#$00			;MainLoop-Routine löschen.
			sta	appMain +0
			sta	appMain +1

			jsr	ExitRegisterMenu	;Register-Menü beenden.
			jmp	ExitRegMenuUser		;Weitere Funktionen ausführen.

;*** Benutzer-Routine aufrufen.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop	exitCode = $00
;    $FF = RegisterMenü	exitCode = $FF
;    $xx = Fehler		exitCode = $7F
:EXEC_REG_ROUT		jsr	ExecRegMenuUser		;Benutzer-Routine ausführen.
			cpx	#NO_ERROR		;Zurück zum DeskTop?
			beq	QuitRegMenu		; => Ja, Ende...

			cpx	#$ff			;Zurück zum RegisterMenü?
			beq	:1			; => Ja, weiter...

			lda	#$7f			;Sonderfunktion.
			b $2c

::1			lda	#$ff			;Ende, ggf. Zurück zum Menü.
			b $2c

;*** "Abbruch", zurück zum DeskTop.
;Das Register-Menü kann nicht durch ein
;Icon/Option direkt beendet werden, da
;hier das Registermenü noch aktiv ist.
;
;Das Menü muss in diesem Fall über die
;MainLoop beendet werden, analog zur
;Verwendung eines DoIcon-Menüs.
;
;Dazu appMain auf die eigentliche EXIT-
;Routine setzen und zum RegisterMenü
;zurückkehren.
;
:QuitRegMenu		lda	#$00			;Abbruch, zurück zum DeskTop.

;--- Benutzerdefinierter Rückgabewert.
;Hinweis:
;Die Einsprungsadresse wird aktuell
;nicht verwendet.
::QuitRegMenuUser	sta	exitCode

;--- Register-Menü beenden.
			LoadW	appMain,DISABLE_REG_MENU
			rts

;*** Variablen.
:exitCode		b $00

;******************************************************************************
;*** Icon-Menü "Beenden".
;******************************************************************************
:IconMenu1		b $01
			w $0000
			b $00

			w IconExit
:IconExitPos		b (R1SizeX0/8) +1,R1SizeY0 -$08
			b IconExit_x,IconExit_y
			w DISABLE_REG_MENU

;*** Icon zum schließen des Menüs.
:IconExit
<MISSING_IMAGE_DATA>

:IconExit_x		= .x
:IconExit_y		= .y
