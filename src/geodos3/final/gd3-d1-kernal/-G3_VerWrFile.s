; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Sektor schreiben/vergleichen.
.VerWriteSek		lda	VerWriteFlag		;Datei schreiben/vergleichen ?
			beq	:1			; -> Datei schreiben.
			jmp	VerWriteBlock		; -> Datei vergleichen.
::1			jmp	WriteBlock

;*** Datei schreiben oder vergleichen.
;    Abhängig von ":VerWriteFlag".
;    ":r6" zeigt auf Tr/Se-Tabelle.
:VerWriteFile		ldy	#$00
			lda	(r6L),y			;Letzer Sektor erreicht ?
			beq	:3			;Ja, Ende...
			sta	r1L			;Sektor-Adresse kopieren.
			iny
			lda	(r6L),y
			sta	r1H
			dey
			jsr	SetVecToSek		;Zeiger auf nächsten Sektor.

			lda	(r6L),y			;Verkettungszeiger berechnen.
			sta	(r4L),y			;(Für den letzten Sektor auch
			iny				; Anzahl der Bytes eintragen!)
			lda	(r6L),y
			sta	(r4L),y

			ldy	#$fe			;Immer 255 Bytes schreiben.
			lda	#RAM_64K		;64Kb-RAM aktivieren.
			sta	CPU_DATA

::1			dey
			lda	(r7L),y			;Daten aus Speicher lesen und
			sta	diskBlkBuf+2,y		;in Zwischenspeicher kopieren.
			tya
			bne	:1

			lda	#KRNL_IO_IN		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			jsr	VerWriteSek		;Sektor schreiben/vergleichen.
			txa				;Diskettenfehler ?
			bne	:4			;Ja, Abbruch...

			clc				;Zeiger auf Speicher
			lda	#$fe			;korrigieren.
			adc	r7L
			sta	r7L
			bcc	:2
			inc	r7H
::2			jmp	VerWriteFile		;Nächster Sektor.

::3			tax
::4			rts

;*** Zeiger auf ":fileTrSeTab".
.SetVecToSek		clc				;Externes Label wegen C128!
			lda	#$02
			adc	r6L
			sta	r6L
			bcc	:1
			inc	r6H
::1			rts
