; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Sektor schreiben/vergleichen.
.VerWriteSek		lda	VerWriteFlag		;Datei schreiben/vergleichen ?
			beq	:51			; -> Datei schreiben.
			jmp	VerWriteBlock		; -> Datei vergleichen.
::51			jmp	WriteBlock

;*** Datei schreiben oder vergleichen.
;    Abhängig von ":VerWriteFlag".
;    ":r6" zeigt auf Tr/Se-Tabelle.
:VerWriteFile		ldy	#$00
			lda	(r6L),y			;Letzer Sektor erreicht ?
			beq	:53			;Ja, Ende...
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

;--- C64: Daten in RAM vergleichen.
if Flag64_128 = TRUE_C64
			lda	#%00110000		;64Kb-RAM aktivieren.
			sta	CPU_DATA

::51			dey
			lda	(r7L),y			;Daten aus Speicher lesen und
			sta	diskBlkBuf+2,y		;in Zwischenspeicher kopieren.
			tya
			bne	:51

			lda	#%00110110		;I/O-Bereich aktivieren.
			sta	CPU_DATA
endif

;--- C128: Daten in RAM vergleichen.
if Flag64_128 = TRUE_C128
			lda	#%01111111		;64Kb-RAM aktivieren.
			sta	MMU

::51			dey
			lda	(r7L),y			;Daten aus Speicher lesen und
			sta	diskBlkBuf+2,y		;in Zwischenspeicher kopieren.
			tya
			bne	:51

			lda	#%01111110		;I/O-Bereich aktivieren.
			sta	MMU
endif

			jsr	VerWriteSek		;Sektor schreiben/vergleichen.
			txa				;Diskettenfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf Speicher
			lda	#$fe			;korrigieren.
			adc	r7L
			sta	r7L
			bcc	:52
			inc	r7H
::52			jmp	VerWriteFile		;Nächster Sektor.

::53			tax
::54			rts

;*** Zeiger auf ":fileTrSeTab".
.SetVecToSek		clc				;Externes Label wegen C128!
			lda	#$02
			adc	r6L
			sta	r6L
			bcc	:51
			inc	r6H
::51			rts
