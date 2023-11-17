; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "GEOS_QuellCo.ext"

:VARTAB			= $002b
:TAPE1			= $00b2
:PNTR			= $00d3
:NDX			= $00c6
:KEYD			= $0277
:MEMSTR			= $0281
:MEMSIZ			= $0283
:HIBASE			= $0288
:TBUFFR			= $033c
:IOINIT			= $fda3
:CINT			= $ff81
:NMIINV			= $0318

endif

			n "GEOS_9D80.OBJ"
			f $06
			c "KERNAL_9D80 V1.0"
			a "M. Kanet"
			o $9d80
			p $0000
			i
<MISSING_IMAGE_DATA>

;*** Zeiger auf ":fileTrSeTab".
.SetVecToSek		clc
			lda	#$02
			adc	r6L
			sta	r6L
			bcc	Exit1
			inc	r6H
:Exit1			rts

;*** Datei einlesen.
.xReadFile		jsr	EnterTurbo		;Turbo-DOS aktivieren.
			txa				;Diskettenfehler ?
			bne	Exit1			;Ja, Abbruch...

			jsr	InitForIO		;I/O aktivieren.

			lda	r0H			;Register ":r0" speichern.
			pha
			lda	r0L
			pha

			lda	#>diskBlkBuf		;Zeiger auf Zwischenspeicher.
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L

			lda	#$02
			sta	r5L

			lda	r1H			;Ersten Sektor in Tabelle
			sta	fileTrScTab+3		;eintragen.
			lda	r1L
			sta	fileTrScTab+2

::101			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch...

			ldy	#$fe			;Anzahl Bytes in Sektor
			lda	diskBlkBuf+0		;berechnen.
			bne	:102
			ldy	diskBlkBuf+1
			dey
			beq	:106

::102			lda	r2H			;Buffer voll ?
			bne	:103			;Nein, weiter...
			cpy	r2L
			bcc	:103
			beq	:103
			ldx	#$0b			;Fehler "Buffer full" setzen
			bne	:107			;und Abbruch...

::103			sty	r1L			;Anzahl Bytes merken.

			lda	#%00110000		;64Kb RAM einblenden.
			sta	CPU_DATA

::104			lda	diskBlkBuf+1,y		;Daten in RAM übertragen.
			dey
			sta	(r7L),y
			bne	:104

			lda	#%00110110		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	r1L			;Startadresse für näachste
			clc				;Daten vorbereiten.
			adc	r7L
			sta	r7L
			bcc	:105
			inc	r7H

::105			lda	r2L			;Buffergröße korrigieren.
			sec
			sbc	r1L
			sta	r2L
			bcs	:106
			dec	r2H

::106			inc	r5L			;Sektorzähler korrigieren.
			inc	r5L

			ldy	r5L
			lda	diskBlkBuf +1		;Sektor-Adresse in Tabelle
			sta	r1H			;eintragen.
			sta	fileTrScTab+1,y
			lda	diskBlkBuf +0
			sta	r1L
			sta	fileTrScTab+0,y
			bne	:101			;Max. 127 Sektoren lesen.

			ldx	#$00			;OK!

::107			pla
			sta	r0L
			pla
			sta	r0H
			jmp	DoneWithIO

;*** Sektor schreiben/vergleichen.
.VerWriteSek		lda	VerWriteFlag		;Datei schreiben/vergleichen ?
			beq	:101			; -> Datei schreiben.
			jmp	VerWriteBlock		; -> Datei vergleichen.
::101			jmp	WriteBlock

;*** Datei auf Diskette speichern.
.xWriteFile		jsr	EnterTurbo		;Turbo-DOS aktivieren.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch...
			sta	VerWriteFlag		;Datei schreiben.

			jsr	InitForIO		;I/O aktivieren.

			lda	#>diskBlkBuf
			sta	r4H
			lda	#<diskBlkBuf
			sta	r4L

			lda	r6H
			pha
			lda	r6L
			pha
			lda	r7H
			pha
			lda	r7L
			pha
			jsr	VerWriteFile		;Datei speichern.
			pla
			sta	r7L
			pla
			sta	r7H
			pla
			sta	r6L
			pla
			sta	r6H
			txa
			bne	:101
			dec	VerWriteFlag		;Flag für "Datei vergleichen".
			jsr	VerWriteFile		;Datei vergleichen.
::101			jsr	DoneWithIO		;I/O abschalten.
::102			rts

;*** Datei schreiben oder vergleichen.
;    Abhängig von ":VerWriteFlag".
;    ":r6" zeigt auf Tr/Se-Tabelle.
.VerWriteFile		ldy	#$00
			lda	(r6L),y			;Letzer Sektor erreicht ?
			beq	:103			;Ja, Ende...
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

			lda	#%00110000		;64Kb-RAM aktivieren.
			sta	CPU_DATA

::101			dey
			lda	(r7L),y			;Daten aus Speicher lesen und
			sta	diskBlkBuf+2,y		;in Zwischenspeicher kopieren.
			tya
			bne	:101

			lda	#%00110110		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			jsr	VerWriteSek		;Sektor schreiben/vergleichen.
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch...

			clc				;Zeiger auf Speicher
			lda	#$fe			;korrigieren.
			adc	r7L
			sta	r7L
			bcc	:102
			inc	r7H
::102			clv
			bvc	VerWriteFile		;Nächster Sektor.

::103			tax
::104			rts

;*** Serien-Nummer des GEOS-Systems.
.SerialNumber		w $962b

;*** Füllbyte ohne Wirkung.
			b $ff

;*** Einsprungtabelle RAM-Tools.
.xVerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			bne	xDoRAMOp
.xStashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			bne	xDoRAMOp
.xSwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			bne	xDoRAMOp
.xFetchRAM		ldy	#%10010001		;RAM-Bereich laden.

.xDoRAMOp		ldx	#$0d

			lda	r3L
			cmp	ramExpSize		;REU verfügbar ?
			bcs	l9f00

			ldx	CPU_DATA		;CPU-Register speichern.
			lda	#%00110101		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	r0H			;Speicher-Adresse.
			sta	ramExpBase2 + 3
			lda	r0L
			sta	ramExpBase2 + 2
			lda	r1H
			sta	ramExpBase2 + 5		;REU-Adresse.
			lda	r1L
			sta	ramExpBase2 + 4
			lda	r3L			;Bank in der REU.
			sta	ramExpBase2 + 6
			lda	r2H			;Anzahl Bytes.
			sta	ramExpBase2 + 8
			lda	r2L
			sta	ramExpBase2 + 7
			lda	#$00
			sta	ramExpBase2 + 9
			sta	ramExpBase2 +10
			sty	ramExpBase2 + 1

:l9ef5			lda	ramExpBase2 + 0		;Job ausführen.
			and	#%01100000
			beq	l9ef5

			stx	CPU_DATA		;CPU-Register zurücksetzen.

			ldx	#$00
:l9f00			rts

:BasicCommand		s 40				;40 Byte für BASIC-Befehl.

:ResetTimer		b $00
:BasicBackData		b $00,$00,$00
:EndBasicL		b $00
:EndBasicH		b $00

;*** Nach BASIC verlassen.
.JumpToBasic		sei

			lda	#$36			;Kernal einblenden.
			sta	CPU_DATA

			ldy	#$02
::101			lda	$0800,y			;BASIC-Daten
			sta	BasicBackData,y		;zwischenspeichern.
			dey
			bpl	:101

			lda	r7H			;Endadresse speichern.
			sta	EndBasicH
			lda	r7L
			sta	EndBasicL

			inc	CPU_DATA		;BASIC-ROM einblenden.

			ldx	#$ff			;Stackzeiger löschen.
			txs

			lda	#$00			;VIC initialisieren.
			sta	grcntrl2

			jsr	IOINIT

			ldx	curDevice

			lda	#$00
			tay
:l9f5b			sta	$0002,y			;ZeroPage löschen.
			sta	$0200,y
			sta	$0300,y
			iny
			bne	l9f5b

			stx	curDevice

			lda	#> $a000		;Ende BASIC-RAM.
			sta	MEMSIZ +1

			lda	#< TBUFFR		;Startadresse
			sta	TAPE1  +0		;Kassettenpuffer.
			lda	#> TBUFFR
			sta	TAPE1  +1

			lda	#> $0800		;Startadresse BASIC-RAM.
			sta	MEMSTR +1
			lsr
			sta	HIBASE			;Zeiger auf Bildschirmanfang.

			jsr	SetKernalVec		;Kernal-Vektoren setzen.
			jsr	CINT			;Bildschirm initialisieren.

			lda	#> NewNMI		;NMI-Routine setzen.
			sta	NMIINV +1
			lda	#< NewNMI
			sta	NMIINV +0

			lda	#$06			;Wartezeit nach Reset.
			sta	ResetTimer

			lda	$dd0d			;I/O zurücksetzen.
			lda	#$ff
			sta	$dd04
			sta	$dd05
			lda	#$81
			sta	$dd0d
			lda	#$01
			sta	$dd0e

			jmp	($a000)			;Warmstart.

;*** Neue NMI-Routine.
.NewNMI			pha
			tya
			pha

			lda	$dd0d

			dec	ResetTimer		;Timer abgelaufen ?
			bne	:104			;Nein, weiter...

			lda	#$7f
			sta	$dd0d

			lda	#> SystemReBoot		;SystemReBoot über NMI.
			sta	NMIINV +1		; (Druck auf RESTORE)
			lda	#< SystemReBoot
			sta	NMIINV +0

			ldy	#$02
::101			lda	BasicBackData,y
			sta	$0800,y
			dey
			bpl	:101

			lda	EndBasicH		;Endadresse BASIC-Programm.
			sta	VARTAB +1
			lda	EndBasicL
			sta	VARTAB +0

			iny
::102			lda	BasicCommand,y		;BASIC-Befehl
			beq	:103			;auf Bildschirm ausgeben.
			sta	($d1),y
			lda	#$0e			;Farb-RAM setzen.
			sta	$d8f0,y
			iny
			bne	:102

::103			tya				;Befehl ausführen ?
			beq	:104			;Nein, weiter...

			lda	#$28			;Zeiger auf Cursor-Spalte.
			sta	PNTR

			lda	#$01			;Eine Taste im Puffer.
			sta	NDX

			lda	#$0d			;<RETURN> in Tastaturpuffer.
			sta	KEYD

::104			pla				;NMI abschließen.
			tay
			pla
			rti
