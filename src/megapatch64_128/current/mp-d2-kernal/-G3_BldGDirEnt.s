; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Verzeichniseintrag erzeugen.
:xBldGDirEntry		ldx	#30 -1
			lda	#$00			;Verzeichnis-Eintrag löschen.
::1			sta	dirEntryBuf,x
			dex
			bpl	:1

			tay
			lda	(r9L),y
			sta	r3L
			iny
			lda	(r9L),y
			sta	r3H
			sty	r1H
			dey
			sty	fileHeader +0		;Sektorverkettung im
			stx	fileHeader +1		;Infoblock löschen.

			ldx	#3			;Dateiname kopieren.
::2			lda	(r3L),y
			bne	:4
			sta	r1H
::3			lda	#$a0
::4			sta	dirEntryBuf,x
			inx
			iny
			cpy	#16
			beq	:5

			lda	r1H			;Ende erreicht?
			bne	:2			; => Nein, weiter...
			beq	:3			; => Ja, mit $A0 auffüllen...

::5			ldy	#$44
			lda	(r9L),y			;CBM -Dateityp.
			sta	dirEntryBuf + 0
			iny
			lda	(r9L),y			;GEOS-Dateityp.
			sta	dirEntryBuf +22
			iny
			lda	(r9L),y			;Datei-Struktur.
			sta	dirEntryBuf +21

;--- Ergänzung: 30.12.22/M.Kanet
;":BldGDirEntry" greift direkt auf
;":fileTrScTab" zu, anstatt den
;Speicherbereich in r6 zu verwenden.
;			ldy	fileTrScTab + 2		;Ersten Sektor merken.
;			sty	dirEntryBuf + 1
;			ldy	fileTrScTab + 3
;			sty	dirEntryBuf + 2
;
;			ldy	fileTrScTab + 0		;Zeiger auf Infoblock.
;			sty	dirEntryBuf +19
;			ldy	fileTrScTab + 1
;			sty	dirEntryBuf +20
;---
			pha				;Datei-Struktur speichern.

			ldy	#0
			lda	(r6L),y			;Zeiger auf Infoblock.
			sta	dirEntryBuf +19
			iny
			lda	(r6L),y
			sta	dirEntryBuf +20
			iny
			lda	(r6L),y			;Ersten Sektor merken.
			sta	dirEntryBuf + 1
			iny
			lda	(r6L),y
			sta	dirEntryBuf + 2

			ldy	r2L			;Dateigröße übernehmen.
			sty	dirEntryBuf +28
			ldy	r2H
			sty	dirEntryBuf +29

			pla				;Datei-Struktur einlesen.
;---
;			tay				;VLIR-Datei ?
			beq	:6			; => Nein, weiter...

;--- VLIR-Header reservieren.
			jsr	SetVecToSek		;Zeiger auf nächsten Sektor
							;in Sektortabelle setzen.

;--- Infoblock reservieren.
::6			jmp	SetVecToSek		;Zeiger auf nächsten Sektor
							;in Sektortabelle setzen.
