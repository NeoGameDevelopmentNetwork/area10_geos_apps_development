; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- LOGO-Farben:
:COLOR_SYS_INFO1	= $10
:COLOR_SYS_INFO2	= $f0
:COLOR_SYS_INFO3	= $c0
:COLOR_SYS_INFO4	= $b0

;*** Titelbild ausgeben.
:LogoScreen		php
			sei				;Interrupt sperren.

			ldx	CPU_DATA
			lda	#IO_IN			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	extclr			;Rahmenfarbe einlesen.
			and	#%00001111		;Rahmenfarbe isolieren.
			sta	r0L

			asl				;Farbe für Vorder- und
			asl				;Hintergrundfarbe berechnen.
			asl
			asl

			ora	r0L

			stx	CPU_DATA		;I/O-Bereich abschalten.

			plp				;IRQ-Status zurücksetzen.

;--- Ergänzung: 07.03.21/M.Kanet
;Diese Routine wird auch von GD.UPDATE
;verwendet. Da hier auch ein GEOS 2.x
;aktiv sein kann, kein ":i_UserColor"
;verwenden!
;			jsr	i_UserColor		;Hintergrund mit Rahmenfarbe
;			b	$00,$00,$28,$19		;löschen.

			sta	r2L
			LoadW	r0,1000
			LoadW	r1,COLOR_MATRIX
			jsr	FillRam

			jsr	i_FillRam		;Grafikspeicher löschen.
			w	8000
			w	SCREEN_BASE
			b	$00

			jsr	i_BitmapUp		;Logo anzeigen.
			w	Icon_Logo
			b	$01,$00,Icon_Logo_x,Icon_Logo_y

			ldx	#0
::1			lda	#COLOR_SYS_INFO1
			sta	COLOR_MATRIX + 0*40,x
			lda	#COLOR_SYS_INFO2
			sta	COLOR_MATRIX + 1*40,x
			lda	#COLOR_SYS_INFO3
			sta	COLOR_MATRIX + 2*40,x
			lda	#COLOR_SYS_INFO4
			sta	COLOR_MATRIX + 3*40,x
			sta	COLOR_MATRIX + 4*40,x
			inx
			cpx	#40
			bcc	:1

			rts

;*** GDOS64-Logo.
:Icon_Logo
<MISSING_IMAGE_DATA>
:Icon_Logo_x		= .x
:Icon_Logo_y		= .y
