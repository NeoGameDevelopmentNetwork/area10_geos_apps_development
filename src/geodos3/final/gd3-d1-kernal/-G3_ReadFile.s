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
			beq	:0			; => Nein, weiter...
			rts

::0			jsr	InitForIO		;I/O aktivieren.

			jsr	Vec_diskBlkBuf		;Zeiger auf Zwischenspeicher.

			lda	#$02
			sta	r5L

			lda	r1H			;Ersten Sektor in Tabelle
			sta	fileTrScTab+3		;eintragen.
			lda	r1L
			sta	fileTrScTab+2

::1			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:7			;Ja, Abbruch...

			ldy	#$fe			;Anzahl Bytes in Sektor
			lda	diskBlkBuf+0		;berechnen.
			bne	:2
			ldy	diskBlkBuf+1
			dey
			beq	:6

::2			lda	r2H			;Buffer voll ?
			bne	:3			;Nein, weiter...
			cpy	r2L
			bcc	:3
			beq	:3
			ldx	#$0b			;Fehler "Buffer full" setzen
			bne	:7			;und Abbruch...
::3			sty	r1L			;Anzahl Bytes merken.

			lda	#RAM_64K		;64Kb RAM einblenden.
			sta	CPU_DATA

::4			lda	diskBlkBuf+1,y		;Daten in RAM übertragen.
			dey
			sta	(r7L),y
			bne	:4

			lda	#KRNL_IO_IN		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	r1L			;Startadresse für näachste
			clc				;Daten vorbereiten.
			adc	r7L
			sta	r7L
			bcc	:5
			inc	r7H
::5			lda	r2L			;Buffergröße korrigieren.
			sec
			sbc	r1L
			sta	r2L
			bcs	:6
			dec	r2H
::6			inc	r5L			;Sektorzähler korrigieren.
			inc	r5L

			ldy	r5L
			lda	diskBlkBuf +1		;Sektor-Adresse in Tabelle
			sta	r1H			;eintragen.
			sta	fileTrScTab+1,y
			lda	diskBlkBuf +0
			sta	r1L
			sta	fileTrScTab+0,y
			bne	:1			;Max. 127 Sektoren lesen.
			tax				;xReg = $00, OK!
::7			jmp	DoneWithIO

;*** Zeiger auf Sektorspeicher setzen.
:Vec_diskBlkBuf		lda	#>diskBlkBuf		;Zeiger auf Zwischenspeicher.
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L
			rts
