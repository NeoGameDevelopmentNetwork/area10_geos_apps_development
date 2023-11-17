; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "MacTab"
endif

;*** GEOS-Header.
			n "obj.GetBackScrn"
			f DATA

			o LOAD_GETBSCRN

;*** Startbild laden.
:xGETBACKSCRN		php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	extclr			;Rahmenfarbe einlesen.
			and	#%00001111		;Rahmenfarbe isolieren.
			sta	r0L

			asl				;Farbe für Vorder- und
			asl				;Hintergrundfarbe berechnen.
			asl
			asl

			ora	r0L

			stx	CPU_DATA
			plp

			jsr	i_UserColor
			b	$00,$00,$28,$19

			lda	sysRAMFlg
			and	#%00001000
			bne	ViewPaintFile

;*** Kein Startbild, Hintergrund löschen.
:NoStartScreen		lda	dispBufferOn
			pha

			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	BackScrPattern
			jsr	SetPattern

			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			pla
			sta	dispBufferOn

;HINWEIS:
;":GetBackScreen" wird nur von GDOS64
;oder GEOS/MP3-Anwendungen aufgerufen.
;Für die Kompatibilität zu den GDOS64-
;Farbprofilen die Farbe des Schattens
;von Dialogboxen für den Hintergrund
;verwenden.
;Ansonsten ist der Hintergrund immer
;Grau => GEOS-Standard.
;			lda	screencolors		;GEOS-Hintergrundfarbe.
			lda	C_WinShadow		;Farbe Schatten für Dialogbox.
::80			jsr	DirectColor

			jsr	SetADDR_BackScrn	;Speicherbereich wieder
			jmp	SwapRAM

;*** Neue Datei anzeigen.
:ViewPaintFile		lda	MP3_64K_SYSTEM
			sta	r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2A_BS_GRAFX
			LoadW	r2,R2S_BS_GRAFX
			jsr	FetchRAM
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2A_BS_COLOR
			LoadW	r2,R2S_BS_COLOR
			jsr	FetchRAM

			jsr	SetADDR_BackScrn	;Speicherbereich wieder
			jmp	SwapRAM

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_GETBSCRN + R2S_GETBSCRN -1
;******************************************************************************
