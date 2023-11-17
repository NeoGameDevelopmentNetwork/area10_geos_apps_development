; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei löschen.
:xDeleteFile		jsr	DelFileEntry		;Dateieintrag löschen.
			txa				;Diskettenfehler ?
			bne	DelFileExit1		;Ja, Abbruch...

			lda	#>dirEntryBuf		;Zeiger auf Dateieintrag.
			sta	r9H
			lda	#<dirEntryBuf
			sta	r9L

;*** Belegte Blocks einer Datei freigeben.
:xFreeFile		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	DelFileExit1		;Ja, Abbruch...

			ldy	#$14
			jsr	Get1stSek		;Infoblock freigeben.
			beq	:1			; => Keine Daten, weiter...
			jsr	FreeSeqChain
			txa				;Diskettenfehler ?
			bne	DelFileExit1		; => Ja, Abbruch...

::1			ldy	#$02
			jsr	Get1stSek		;Programmdaten freigeben.
			beq	:3			; => Keine Daten, weiter...
			jsr	FreeSeqChain
			txa				;Diskettenfehler ?
			bne	DelFileExit1		; => Ja, Abbruch...

			ldy	#$15
			lda	(r9L),y
			cmp	#$01			;VLIR-Datei freigeben ?
			bne	:3			;Nein, weiter...

			ldy	#$02
			jsr	Get1stSek		;Programmdaten freigeben.
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	DelFileExit1		; => Ja, Abbruch...

			ldy	#$02
::2			tya				;Alle Datensätze gelöscht ?
			beq	:3			;Ja, Ende...
			lda	fileHeader +0,y		;Zeiger VLIR-Eintrag und
			sta	r1L			;Track/Sektor einlesen.
			iny
			lda	fileHeader +0,y
			sta	r1H
			iny
			lda	r1L
			beq	:2
			tya
			pha
			jsr	FreeSeqChain		;Datensatz freigeben.
			pla				;Zeiger auf Datensatz
			tay				;zurücksetzen.
			txa				;Diskettenfehler ?
			beq	:2			;Nein, weiter...
			bne	DelFileExit1

::3			jmp	PutDirHead		;BAM aktualisieren.

;*** Sektorkette freigeben.
;    yReg Offset auf Verzeichnis-Eintrag in ":r9".
:Get1stSek		lda	(r9L),y
			sta	r1H
			dey
			lda	(r9L),y
			sta	r1L
:DelFileExit1		rts

;*** Datei löschen, nur für SEQ-Dateien.
;    ":r3" zeigt auf Tr/Se-Tabelle.
:xFastDelFile		jsr	DelFileEntry		;Datei-Eintrag löschen.
			txa				;Diskettenfehler ?
			bne	DelFileExit2		;Ja, Abbruch...

;*** Sektoren in ":fileTrSeTab" freigeben.
:FreeSekTab		jsr	GetDirHead		;BAM einlesen.

::1			ldy	#$00
			lda	(r3L),y			;Noch ein Sektor ?
			beq	:3			;Nein, weiter...
			sta	r6L
			iny
			lda	(r3L),y
			sta	r6H
			jsr	FreeBlock		;Sektor freigeben.
			txa				;Diskettenfehler ?
			bne	DelFileExit2		;Ja, Abbruch...

;--- Ergänzung: 01.02.21/M.Kanet
;Durch diverse Fehlerbehebungen wurde
;zusätzlicher Speicherplatz benötigt,
;z.B. der ":SetDevice"-Fix.
;Da es bereits eine SetNxByte_r3-
;Routine gibt wurde hier die Addition
;durch zwei Funktionsaufrufe ersetzt.
;Einsparung: 5 Bytes.
			jsr	SetNxByte_r3		;Zeiger auf nächsten Eintrag.
			jsr	SetNxByte_r3

;			clc				;Zeiger auf nächsten Eintrag.
;			lda	#$02
;			adc	r3L
;			sta	r3L
;			bcc	:2
;			inc	r3H
;---

::2			jmp	:1			;Nächsten Sektor freigeben.
::3			jmp	PutDirHead		;BAM zurückschreiben.

;*** Dateieintrag suchen, Aufruf durch ":FastDelFile" und ":DeleteFile".
:DelFileEntry		lda	r0H
			sta	r6H
			lda	r0L
			sta	r6L
			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch...
			tay
			sta	(r5L),y			;Datei-Eintrag löschen.
			jmp	PutBlock_dskBuf		;Sektor zurückschreiben.

;*** SwapFile soll gelöscht werden, SwapRAM wieder freigeben.
::1			ldy	#$00
			lda	(r0L),y
			cmp	#$1b			;SwapFile löschen ?
			bne	DelFileExit2		; => Ja, weiter...

			pla				;Rücksprungadresse aus
			pla				;"DeleteFile" und "FastDelFile"
			lda	Flag_ExtRAMinUse	;löschen und SwapRAM freigeben.
			bpl	DelFileExit2		;=> Bereits freigegeben, dann
							;Fehler "FILE NOT FOUND"!!!
			and	#%01111111
			sta	Flag_ExtRAMinUse
			ldx	#$00			;SwapFile "gelöscht".
:DelFileExit2		rts
