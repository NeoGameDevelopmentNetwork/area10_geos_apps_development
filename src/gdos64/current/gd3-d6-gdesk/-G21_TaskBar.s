; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Taskleiste zeichnen.
.InitTaskBar		lda	C_GTASK_PATTERN		;Füllmuster setzen.
			jsr	SetPattern

			jsr	i_Rectangle		;Taskbar "löschen".
			b	TASKBAR_MIN_Y,TASKBAR_MAX_Y
			w	TASKBAR_MIN_X,TASKBAR_MAX_X

			lda	C_GDesk_TaskBar		;Farbe für TaskBar setzen.
			jsr	DirectColor

;--- Bereich für GeoDesk-Uhr löschen.
			lda	#$00			;Füllmuster für "Bereich löschen".
			jsr	SetPattern

			jsr	i_FrameRectangle
			b	MIN_AREA_BAR_Y    ,MAX_AREA_BAR_Y
			w	MAX_AREA_BAR_X-$3f,MAX_AREA_BAR_X-$10
			b	%11111111

			jsr	i_Rectangle
			b	MIN_AREA_BAR_Y+$01,MAX_AREA_BAR_Y
			w	MAX_AREA_BAR_X-$3e,MAX_AREA_BAR_X-$11

			lda	C_GDesk_Clock		;Farbe für GEOS-Uhr.
			jsr	DirectColor

			jsr	GD_INITCLOCK		;Uhrzeit anzeigen.

;--- Bereich für GEOS-Button initialisieren.
			lda 	C_GDesk_GEOS
			jsr	i_UserColor
			b	MIN_AREA_BAR_X/8
			b	MIN_AREA_BAR_Y/8
			b	$06
			b	$02

;--- Bereich für Fenster-Icon initialisieren.
			lda 	C_GDesk_GEOS
			jsr	i_UserColor
			b	MAX_AREA_BAR_X/8 -1
			b	MIN_AREA_BAR_Y/8
			b	$02
			b	$02

;*** Uhrzeiut starten und GEOS-Menü aktivieren.
:ReStartTaskBar		LoadW	r0,:geos
			jmp	DoIcons

;*** Icon-Tabelle für GEOS-Menü.
::geos			b $02
			w $0000
			b $00

			w :i1
			b MIN_AREA_BAR_X / 8
			b MIN_AREA_BAR_Y
			b :i1x,:i1y
			w OPEN_MENU_GEOS

			w :i2
			b MAX_AREA_BAR_X / 8 -1
			b MIN_AREA_BAR_Y
			b :i2x,:i2y
			w OPEN_MENU_SCRN

::i1
<MISSING_IMAGE_DATA>
::i1x			= .x
::i1y			= .y

::i2
<MISSING_IMAGE_DATA>
::i2x			= .x
::i2y			= .y
