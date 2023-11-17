; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* HotCorner-Routinen ausführen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "s.GD.21.Desk.ext"
endif

;*** GEOS-Header.
			n "obj.GD26"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	ExecHC_Action

;*** HotCorner-Aktion ausführen.
:ExecHC_Action		ldy	r10L

			tya
			asl
			tax
			lda	:tabMsePosX +0,x
			sta	mouseXPos +0
			lda	:tabMsePosX +1,x
			sta	mouseXPos +1
			lda	:tabMsePosY,y
			sta	mouseYPos

			lda	GD_HC_CFG1,y
			and	#%00000111
			asl
			tax
			lda	funcTab +0,x
			pha
			lda	funcTab +1,x
			tax
			pla
			jmp	CallRoutine

;--- Mausposition ausserhalb HotCorner.
::tabMsePosX		w	16 ,320 -1 -16, 16, 320 -1 -16
::tabMsePosY		b	16 ,16 ,200 -1 -16, 200 -1 -16

;*** Aktions-Routinen.
:funcTab		w funcScrnSvr
			w funcHideWin
			w funcGDConfig
			w funcGDOptions
			w funcOpenMyComp
			w funcHelpPage

;*** Aktion: Bildschirmschoner starten.
:funcScrnSvr		bit	mouseData		;Maustaste gedrückt?
			bpl	funcScrnSvr		; => Ja, warten...

			bit	Flag_ScrSaver		;Bildschirmschoner aktiv?
			bmi	:exit			; => Nein, Ende...

			lda	#%10000000		;Bildschirmschoner über MainLoop
			sta	Flag_RunScrSvr		;und ":appMain" (DrawClock) starten.

::exit			rts				;Ende.

;*** Aktion: Fenster verstecken.
:funcHideWin		ldy	WM_WCOUNT_OPEN
			dey
			beq	:w3

			bit	GD_HIDEWIN_MODE
			bmi	:w1

			jsr	WM_DRAW_BACKSCR
			jmp	:w2

::w1			jsr	WM_DRAW_ALL_WIN

			lda	#$00
			b $2c
::w2			lda	#$ff
			sta	GD_HIDEWIN_MODE

::w3			rts

;*** Aktion: GD.CONFIG starten.
:funcGDConfig		jmp	OpenGDConfig		;GD.CONFIG starten.

;*** Aktion: GeoDesk-Optionen öffnen.
;
;HINWEIS:
;Bei Menü-Routinen wird der Bildschirm
;automatisch gespeichert.
;Wird die Routine manuell aufgerufen,
;dann muss der Bildschirm gesichert
;manuell gespeichert werden.
;
:funcGDOptions		jsr	sys_SvBackScrn		;Bildschirm speichern.

			jsr	UPDATE_GD_CORE		;GeoDesk-Systemvariablen speichern.
			jmp	MOD_OPTIONS		;GeoDesk-Optionen öffnen.

;*** Aktion: Arbeitsplatz öffnen.
:funcOpenMyComp		lda	WM_MYCOMP		;Ist "MyComputer" bereits geöffnet?
			bne	:1			; => Nein, weiter...

			jsr	WM_HIDEWIN_OFF
			jmp	OpenMyComputer

::1			lda	#$00
			sta	GD_HIDEWIN_MODE
			jmp	OpenMyComputer

;*** Aktion: Hilfeseite aufrufen.
:funcHelpPage		jmp	SUB_SHOWHELP

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Desktop-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
