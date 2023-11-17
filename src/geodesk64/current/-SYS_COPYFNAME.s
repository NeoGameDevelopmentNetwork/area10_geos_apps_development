; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei-Eigenschaften anzeigen.
:COPY_FILE_NAMES	ldx	#r0L
			jsr	ADDR_RAM_x		;Zeiger auf Anfang Verzeichnis.

			LoadW	r1,SYS_FNAME_BUF	;Speicher für ausgewählte Dateien.

			ldx	#$00			;Anzahl ausgewählte Dateien
			stx	slctFiles		;löschen.

			stx	r3L			;Zeiger auf erste Datei.
if MAXENTRY16BIT = TRUE
			stx	r3H
endif

::loop			ldy	#$00
			lda	(r0L),y			;Datei ausgewählt?
			and	#GD_MODE_MASK
			beq	:next_file		; => Nein, weiter...

			lda	#GD_MODE_UNSLCT 		;Auswahl-Flag zurücksetzen.
			sta	(r0L),y

			ldy	#$02
			lda	(r0L),y			;Dateityp einlesen?
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien>"?
			beq	:next_file

			clc				;Zeiger auf Anfang Dateiname
			lda	r0L			;setzen.
			adc	#<5
			sta	r2L
			lda	r0H
			adc	#>5
			sta	r2H

			ldx	#r2L			;Dateiname in Tabelle kopieren.
			ldy	#r1L
			jsr	SysCopyName

			AddVBW	17,r1			;Anzahl Dateien +1.
			inc	slctFiles

::next_file		AddVBW	32,r0			;Zeiger auf nächsten Eintrag.

			inc	r3L			;Datei-Zähler +1.
if MAXENTRY16BIT = TRUE
			bne	:1
			inc	r3H
endif
::1
if MAXENTRY16BIT = TRUE
			lda	r3H
			cmp	WM_DATA_MAXENTRY +1
			bne	:2
endif
			lda	r3L
			cmp	WM_DATA_MAXENTRY +0
::2			bcc	:loop			; => Weiter mit nächster Datei.

			jsr	SET_CACHE_DATA		;Verzeichnisdaten ohne Auswahl-
			jmp	StashRAM		;Flag in Cache zurückschreiben.

;*** Variablen.
:slctFiles		b $00

;--- HINWEIS:
;Die Variable ":SYS_FNAME_BUF" muss im
;Hauptmodul definiert werden, sonst
;wird der reservierte Speicher mehrfach
;in GeoDesk-Modulen reserviert.
;SYS_FNAME_BUF		s MAX_DIR_ENTRIES * 17
