; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Ausgewählte Dateinamen kopieren.
:_ext_CopyFSlct		LoadW	r0,BASE_DIRDATA		;Zeiger auf Anfang Verzeichnis.
			LoadW	r1,SYS_FNAME_BUF	;Speicher für ausgewählte Dateien.

			ldx	#$00			;Anzahl ausgewählte Dateien
			stx	slctFiles		;löschen.

			stx	r3L			;Zeiger auf erste Datei.

::1			ldy	#$00
			lda	(r0L),y			;Datei ausgewählt?
			and	#GD_MODE_MASK
			beq	:2			; => Nein, weiter...

			lda	#GD_MODE_UNSLCT 		;Auswahl-Flag zurücksetzen.
			sta	(r0L),y

			ldy	#$02
			lda	(r0L),y			;Dateityp einlesen?
			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien>"?
			beq	:2

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

::2			AddVBW	32,r0			;Zeiger auf nächsten Eintrag.

			inc	r3L			;Datei-Zähler +1.
::3			lda	r3L
			cmp	fileEntryCount +0
::4			bcc	:1			; => Weiter mit nächster Datei.

			rts

;*** Variablen.
:slctFiles		b $00

;--- HINWEIS:
;Die Variable ":SYS_FNAME_BUF" muss im
;Hauptmodul definiert werden, sonst
;wird der reservierte Speicher mehrfach
;in GeoDesk-Modulen reserviert.
;SYS_FNAME_BUF		s MAX_DIR_ENTRIES * 17
