; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Verzeichniseintrag speichern.
:xSetGDirEntry		jsr	BldGDirEntry		;Verzeichnis-Eintrag erzeugen.
			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	SetDirExit		;Ja, Abbruch...

			tya
			clc
			adc	#<diskBlkBuf
			sta	r5L
			lda	#>diskBlkBuf
			adc	#$00
			sta	r5H

			ldy	#$1d
::1			lda	dirEntryBuf,y		;Verzeichnis-Eintrag kopieren.
			sta	(r5L)      ,y
			dey
			bpl	:1

			jsr	SetFileDate
			jmp	PutBlock_dskBuf

;*** Aktuelles Datum in Verzeichnis-
;    eintrag schreiben.
:SetFileDate		ldy	#$17
::1			lda	year -$17,y
			sta	(r5L)    ,y
			iny
			cpy	#$1c
			bne	:1
:SetDirExit		rts
