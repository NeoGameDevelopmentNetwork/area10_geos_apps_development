; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei einlesen.
:xReadFile		jsr	EnterTurbo		;Turbo-DOS aktivieren.
			txa				;Diskettenfehler ?
			beq	:50			; => Nein, weiter...
			rts

::50			jsr	InitForIO		;I/O aktivieren.

			jsr	Vec_diskBlkBuf		;Zeiger auf Zwischenspeicher.

			lda	#$02
			sta	r5L

			lda	r1H			;Ersten Sektor in Tabelle
			sta	fileTrScTab+3		;eintragen.
			lda	r1L
			sta	fileTrScTab+2

::51			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:57			;Ja, Abbruch...

			ldy	#$fe			;Anzahl Bytes in Sektor
			lda	diskBlkBuf+0		;berechnen.
			bne	:52
			ldy	diskBlkBuf+1
			dey
			beq	:56

::52			lda	r2H			;Buffer voll ?
			bne	:53			;Nein, weiter...
			cpy	r2L
			bcc	:53
			beq	:53
			ldx	#$0b			;Fehler "Buffer full" setzen
			bne	:57			;und Abbruch...
::53			sty	r1L			;Anzahl Bytes merken.

;--- C64: Daten in RAM kopieren.
if Flag64_128 = TRUE_C64
			lda	#%00110000		;64Kb RAM einblenden.
			sta	CPU_DATA

::54			lda	diskBlkBuf+1,y		;Daten in RAM übertragen.
			dey
			sta	(r7L),y
			bne	:54

			lda	#%00110110		;I/O-Bereich aktivieren.
			sta	CPU_DATA
endif

;--- C128: Daten in RAM kopieren.
if Flag64_128 = TRUE_C128
			lda	#%01111111		;64Kb RAM einblenden.
			sta	MMU

::54			lda	diskBlkBuf+1,y		;Daten in RAM übertragen.
			dey
			sta	(r7L),y
			bne	:54

			lda	#%01111110		;I/O-Bereich aktivieren.
			sta	MMU
endif

			lda	r1L			;Startadresse für näachste
			clc				;Daten vorbereiten.
			adc	r7L
			sta	r7L
			bcc	:55
			inc	r7H
::55			lda	r2L			;Buffergröße korrigieren.
			sec
			sbc	r1L
			sta	r2L
			bcs	:56
			dec	r2H
::56			inc	r5L			;Sektorzähler korrigieren.
			inc	r5L

			ldy	r5L
			lda	diskBlkBuf +1		;Sektor-Adresse in Tabelle
			sta	r1H			;eintragen.
			sta	fileTrScTab+1,y
			lda	diskBlkBuf +0
			sta	r1L
			sta	fileTrScTab+0,y
			bne	:51			;Max. 127 Sektoren lesen.
			tax				;xReg = $00, OK!
::57			jmp	DoneWithIO
