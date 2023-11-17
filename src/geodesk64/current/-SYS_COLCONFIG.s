; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration laden.
:LoadColConfig		LoadW	r6,configName		;Name der Konfigurationsdatei.
:LoadColConfig_r6	PushW	r6
			jsr	FindFile		;Datei auf Disk suchen.
			PopW	r6
			txa				;Gefunden?
			bne	:exit			; => Nein, Abbruch...

			LoadB	r0L,%00000001
;			LoadW	r6,configName
			LoadW	r7,GD_SYSCOL_A		;Startadresse Farb-/Musterdaten.
			jsr	GetFile			;Datei einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	GEOS_SYS_COLS_A
			w	MP3_COLOR_DATA
			w	(GEOS_SYS_COLS_E - GEOS_SYS_COLS_A)

			lda	C_GEOS_PATTERN		;GEOS-Füllmuster übernehmen.
			sta	BackScrPattern

			lda	C_GEOS_MOUSE		;Standardfarbe Mauszeiger überhmen.
			sta	C_Mouse

			jsr	ApplyConfig		;Farbe Mauszeiger übernehmen.

			ldx	#NO_ERROR		;Kein Fehler.
::exit			rts

:configName		b "GeoDesk.col",0,0,0,0,0,NULL

;*** Farbe Mauszeiger übernehmen.
:ApplyConfig		php
			sei

			ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr

			lda	C_GEOS_FRAME
			sta	BORDER_COL

			stx	CPU_DATA

			plp
			rts
