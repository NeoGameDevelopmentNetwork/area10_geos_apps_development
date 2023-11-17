; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei speichern.
:xSaveFile		ldy	#$00
::51			lda	(r9L)      ,y		;Infoblock zwischenspeichern.
			sta	fileHeader ,y
			iny
			bne	:51

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	GetFileSize		;Dateigröße berechnen.
			jsr	Vec_fileTrScTab

			jsr	BlkAlloc		;Sektor belegen.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	Vec_fileTrScTab

			jsr	SetGDirEntry		;Verzeichnis-Eintrag erzeugen.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			sta	fileHeader+$a0
			lda	dirEntryBuf+20
			sta	r1H
			lda	dirEntryBuf+19
			sta	r1L
			jsr	Vec_fileHeader

			jsr	PutBlock		;Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	SaveVLIR
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	GetLoadAdr		;Ladeadresse ermitteln.
			jmp	WriteFile		;Speicher auf Disk schreiben.
:SaveExit		rts

;*** VLIR-Header speichern.
:SaveVLIR		ldx	#$00
			ldy	dirEntryBuf+21
			dey				;VLIR-Datei ?
			bne	SaveExit		;Nein, weiter...

			lda	dirEntryBuf+2
			sta	r1H
			lda	dirEntryBuf+1
			sta	r1L

			tya
::51			sta	diskBlkBuf +0,y
			iny
			bne	:51
			dey
			sty	diskBlkBuf +1
			jmp	PutBlock_dskBuf		;Sektor auf Diskette schreiben.

;*** Dateigröße berechnen.
:GetFileSize		lda	fileHeader+$49		;Programmgröße berechnen.
			sec
			sbc	fileHeader+$47
			sta	r2L
			lda	fileHeader+$4a
			sbc	fileHeader+$48
			sta	r2H

			jsr	:51			;254 Bytes für Infoblock.

			ldx	fileHeader+$46
			dex				;VLIR-Datei ?
			bne	:52			;Nein, weiter...

::51			clc				;254 Bytes für VLIR-Header.
			lda	#$fe
			adc	r2L
			sta	r2L
			bcc	:52
			inc	r2H
::52			rts
