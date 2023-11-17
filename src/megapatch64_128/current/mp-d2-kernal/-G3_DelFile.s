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
			beq	:1			;Ja, Abbruch...
			rts

::1			lda	#>dirEntryBuf		;Zeiger auf Dateieintrag.
			sta	r9H
			lda	#<dirEntryBuf
			sta	r9L

;*** Belegte Blocks einer Datei freigeben.
:xFreeFile		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	DelFileExit		;Ja, Abbruch...

			ldy	#$14
			jsr	Get1stSek		;Infoblock freigeben.
			beq	:1			; => Keine Daten, weiter...
			jsr	FreeSeqChain
			txa				;Diskettenfehler ?
			bne	DelFileExit		; => Ja, Abbruch...

::1			ldy	#$02
			jsr	Get1stSek		;Programmdaten freigeben.
			beq	:3			; => Keine Daten, weiter...
			jsr	FreeSeqChain
			txa				;Diskettenfehler ?
			bne	DelFileExit		; => Ja, Abbruch...

			ldy	#$15
			lda	(r9L),y
			cmp	#$01			;VLIR-Datei freigeben ?
			bne	:3			;Nein, weiter...

			ldy	#$02
			jsr	Get1stSek		;Programmdaten freigeben.
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	DelFileExit		; => Ja, Abbruch...

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
			bne	DelFileExit

::3			jsr	PutDirHead		;BAM aktualisieren.
:DelFileExit		rts

;*** Sektorkette freigeben.
;    yReg Offset auf Verzeichnis-Eintrag in ":r9".
:Get1stSek		lda	(r9L),y
			sta	r1H
			dey
			lda	(r9L),y
			sta	r1L
			rts

;*** Datei löschen, nur für SEQ-Dateien.
;    ":r3" zeigt auf Tr/Se-Tabelle.
:xFastDelFile		jsr	DelFileEntry		;Datei-Eintrag löschen.
			txa				;Diskettenfehler ?
			bne	DelEntryExit		;Ja, Abbruch...

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
			bne	DelEntryExit		;Ja, Abbruch...

			clc				;Zeiger auf nächsten Eintrag.
			lda	#$02
			adc	r3L
			sta	r3L
			bcc	:2
			inc	r3H
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
			bne	DelEntryExit		; => Ja, weiter...

			pla				;Rücksprungadresse aus
			pla				;"DeleteFile" und "FastDelFile"
			lda	Flag_ExtRAMinUse	;löschen und SwapRAM freigeben.
			bpl	DelEntryExit		;=> Bereits freigegeben, dann
							;Fehler "FILE NOT FOUND"!!!
			and	#%01111111
			sta	Flag_ExtRAMinUse
			ldx	#$00			;SwapFile "gelöscht".
:DelEntryExit		rts
