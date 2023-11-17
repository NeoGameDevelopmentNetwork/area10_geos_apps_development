; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
;			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
endif

;*** GEOS-Header.
			n "obj.ClrDlgScreen"
			f DATA

			o LOAD_DB_SCREEN

;*** Bildschirm für Dialogbox wiederherstellen/zwischenspeichern.
:xDB_SCREEN_SAVE	ldy	#$90			;Job-Code für ":StashRAM"
			b $2c
:xDB_SCREEN_LOAD	ldy	#$91			;Job-Code für ":FetchRAM"
			sty	DataJobCode		;Aktuellen Job-Code speichern.

			php
			sei
			ldx	#$1f			;ZeroPage retten.
::51			lda	r0L,x
			pha
			dex
			bpl	:51

			lda	dispBufferOn		;Bildschirmflag retten und
			pha				;Grafik nur in Vordergrund.
			lda	#ST_WR_FORE
			sta	dispBufferOn

::52			jsr	ResetDlgGrafx		;Job ausführen.

			pla
			sta	dispBufferOn		;Bildschirmflag zurücksetzen.

			ldx	#$00
::53			pla				;ZeroPage zurückschreiben.
			sta	r0L,x
			inx
			cpx	#$20
			bcc	:53
			plp

			jmp	SwapRAM 			;Ende

;*** Dialogbox-Grafik zurücksetzen.
:ResetDlgGrafx		clc				;Größe der Box berechnen.
			jsr	DB_TestUpsize

			lda	r3H			;Linken Rand der Box in Cards
			lsr				;berechnen.
			lda	r3L
			and	#%11111000
			sta	r3L
			ror
			lsr
			lsr
			sta	DB_Margin_Left

			lda	r2L			;Oberen Rand der Box in Cards
			lsr				;berechnen.
			lsr
			lsr
			sta	DB_Margin_Top
			sta	CurDBoxLine		;Startwert für Job-Routine.

			lda	r2H			;Höhe der Box in Cards
			lsr				;berechnen.
			lsr
			lsr
			sec
			sbc	CurDBoxLine
			clc
			adc	#$01
			sta	CountLines

			lda	r4L			;Anzahl Grafik-Bytes pro Zeile
			ora	#%00000111
			sta	r4L
			sec				;berechnen.
			sbc	r3L
			sta	r0L
			lda	r4H
			sbc	r3H
			sta	r0H

			inc	r0L
			bne	:51
			inc	r0H
::51			lda	r0L			;Anzahl Bytes in Zwischenspeicher.
			sta	GrfxDataBytes +0
			lda	r0H
			sta	GrfxDataBytes +1

			ldx	#r0L			;Bytes in Cards umrechnen.
			ldy	#$03
			jsr	DShiftRight

			lda	r0L			;Anzahl Cards in Zwischenspeicher.
			sta	ColsDataBytes

::52			jsr	DefCurLineCols		;Zeiger auf Farbdaten berechnen.
			ldy	DataJobCode		;Job-Code einlesen und
			jsr	DoRAMOp			;Daten speichern/einlesen.
			jsr	DefCurLineGrfx		;Zeiger auf Grafikdaten berechnen.
			ldy	DataJobCode		;Job-Code einlesen und
			jsr	DoRAMOp			;Daten speichern/einlesen.

			inc	CurDBoxLine		;Zeiger auf nächste Zeile.
			dec	CountLines		;Zähler korrigieren.
			bmi	:53			; => Box + Schatten bearbeitet.
			bne	:52			;Box weiter bearbeiten.

			lda	Flag_DBoxType		;Dialogbox-Kennbyte einlesen und
			and	#%00011111		;auf Schatten testen.
			bne	:52			; => Schatten bearbeiten.
::53			rts

;*** Daten für aktuelle Zeile definieren.
:DefCurLineGrfx		ldx	CurDBoxLine		;Zeiger auf Grafikzeile
			lda	SCREEN_LINE_L,x		;berechnen.
			clc
			adc	#< SCREEN_BASE
			sta	r0L
			lda	SCREEN_LINE_H,x
			adc	#> SCREEN_BASE
			sta	r0H

			lda	SCREEN_LINE_L,x		;Zeiger auf Zwischenspeicher
			clc				;berechnen.
			adc	#< R2A_DB_GRAFX
			sta	r1L
			lda	SCREEN_LINE_H,x
			adc	#> R2A_DB_GRAFX
			sta	r1H

			ldx	DB_Margin_Left		;Zeiger auf Grafikzeile
			lda	SCREEN_COLUMN_L,x	;berechnen.
			clc
			adc	r0L
			sta	r0L
			lda	SCREEN_COLUMN_H,x
			adc	r0H
			sta	r0H

			lda	SCREEN_COLUMN_L,x	;Zeiger auf Zwischenspeicher
			clc				;berechnen.
			adc	r1L
			sta	r1L
			lda	SCREEN_COLUMN_H,x
			adc	r1H
			sta	r1H

			lda	GrfxDataBytes +0	;Anzahl Grafikbytes festlegen.
			sta	r2L
			lda	GrfxDataBytes +1
			sta	r2H

			lda	MP3_64K_SYSTEM		;MegaPatch-Bank in REU festlegen.
			sta	r3L

;*** Daten anpassen (erste/letzte Zeile).
			lda	Flag_DBoxType		;Dialogbox-Kennbyte einlesen und
			and	#%00011111		;auf Schatten testen.
			beq	:53			; => Kein Schatten, Ende...

			lda	CurDBoxLine
			cmp	DB_Margin_Top		;Erste Zeile ?
			beq	:53			;Ja, weiter...

			lda	CountLines		;Schatten am unteren Rand ?
			bne	:54			;Nein, weiter...

			clc				;Linker Rand für Grafikdaten um
			lda	r0L			;8-Pixel nach rechts verschieben.
			adc	#$08			;Damit wird der Schatten am unteren
			sta	r0L			;Rand der Dialogbox definiert.
			bcc	:52
			inc	r0H
::52			clc
			lda	r1L
			adc	#$08
			sta	r1L
			bcc	:53
			inc	r1H
::53			rts

::54			clc				;Grafikzeile um 8 Bytes verlängern.
			lda	r2L			;Damit wird eine Zeile der Dialog-
			adc	#$08			;box mit Schatten definiert.
			sta	r2L
			bcc	:55
			inc	r2H
::55			rts

;*** Daten für aktuelle Zeile definieren.
:DefCurLineCols		ldx	CurDBoxLine		;Zeiger auf Grafikzeile
			lda	COLOR_LINE_L,x		;berechnen.
			clc
			adc	#< COLOR_MATRIX
			sta	r0L
			lda	COLOR_LINE_H,x
			adc	#> COLOR_MATRIX
			sta	r0H

			lda	COLOR_LINE_L,x		;Zeiger auf Zwischenspeicher
			clc				;berechnen.
			adc	#< R2A_DB_COLOR
			sta	r1L
			lda	COLOR_LINE_H,x
			adc	#> R2A_DB_COLOR
			sta	r1H

			lda	DB_Margin_Left		;Zeiger auf Grafikzeile
			clc				;berechnen.
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H

			lda	DB_Margin_Left		;Zeiger auf Zwischenspeicher
			clc				;berechnen.
			adc	r1L
			sta	r1L
			lda	#$00
			adc	r1H
			sta	r1H

			lda	ColsDataBytes		;Anzahl Farbbytes festlegen.
			sta	r2L
			lda	#$00
			sta	r2H

			lda	MP3_64K_SYSTEM		;MegaPatch-Bank in REU festlegen.
			sta	r3L

;*** Daten anpassen (erste/letzte Zeile).
			lda	Flag_DBoxType		;Dialogbox-Kennbyte einlesen und
			and	#%00011111		;auf Schatten testen.
			beq	:53			; => Kein Schatten, Ende...

			lda	CurDBoxLine
			cmp	DB_Margin_Top		;Erste Zeile ?
			beq	:53			;Ja, weiter...

			lda	CountLines		;Schatten am unteren Rand ?
			bne	:54			;Nein, weiter...

			inc	r0L			;Linker Rand für Farbdaten um
			bne	:52			;1 Byte nach rechts verschieben.
			inc	r0H			;Damit wird der Schatten am unteren
::52			inc	r1L			;Rand der Dialogbox definiert.
			bne	:53
			inc	r1H
::53			rts

::54			inc	r2L			;Farbdaten um 1 Byte vergrößern.
			rts				;Damit wird eine Zeile der Dialog-
							;box mit Schatten definiert.

;*** Variablen.
:DataJobCode		b $00
:DB_Margin_Left		b $00
:DB_Margin_Top		b $00
:CountLines		b $00
:ColsDataBytes		b $00
:GrfxDataBytes		w $0000
:CurDBoxLine		b $00

;*** Startadressen der Grafikzeilen.
:SCREEN_LINE_L		b <  0*8*40
			b <  1*8*40
			b <  2*8*40
			b <  3*8*40
			b <  4*8*40
			b <  5*8*40
			b <  6*8*40
			b <  7*8*40
			b <  8*8*40
			b <  9*8*40
			b < 10*8*40
			b < 11*8*40
			b < 12*8*40
			b < 13*8*40
			b < 14*8*40
			b < 15*8*40
			b < 16*8*40
			b < 17*8*40
			b < 18*8*40
			b < 19*8*40
			b < 20*8*40
			b < 21*8*40
			b < 22*8*40
			b < 23*8*40
			b < 24*8*40

:SCREEN_LINE_H		b >  0*8*40
			b >  1*8*40
			b >  2*8*40
			b >  3*8*40
			b >  4*8*40
			b >  5*8*40
			b >  6*8*40
			b >  7*8*40
			b >  8*8*40
			b >  9*8*40
			b > 10*8*40
			b > 11*8*40
			b > 12*8*40
			b > 13*8*40
			b > 14*8*40
			b > 15*8*40
			b > 16*8*40
			b > 17*8*40
			b > 18*8*40
			b > 19*8*40
			b > 20*8*40
			b > 21*8*40
			b > 22*8*40
			b > 23*8*40
			b > 24*8*40

;*** Startadressen der Grafikspalten.
:SCREEN_COLUMN_L	b < 8 * 0
			b < 8 * 1
			b < 8 * 2
			b < 8 * 3
			b < 8 * 4
			b < 8 * 5
			b < 8 * 6
			b < 8 * 7
			b < 8 * 8
			b < 8 * 9
			b < 8 * 10
			b < 8 * 11
			b < 8 * 12
			b < 8 * 13
			b < 8 * 14
			b < 8 * 15
			b < 8 * 16
			b < 8 * 17
			b < 8 * 18
			b < 8 * 19
			b < 8 * 20
			b < 8 * 21
			b < 8 * 22
			b < 8 * 23
			b < 8 * 24
			b < 8 * 25
			b < 8 * 26
			b < 8 * 27
			b < 8 * 28
			b < 8 * 29
			b < 8 * 30
			b < 8 * 31
			b < 8 * 32
			b < 8 * 33
			b < 8 * 34
			b < 8 * 35
			b < 8 * 36
			b < 8 * 37
			b < 8 * 38
			b < 8 * 39

:SCREEN_COLUMN_H	b > 8 * 0
			b > 8 * 1
			b > 8 * 2
			b > 8 * 3
			b > 8 * 4
			b > 8 * 5
			b > 8 * 6
			b > 8 * 7
			b > 8 * 8
			b > 8 * 9
			b > 8 * 10
			b > 8 * 11
			b > 8 * 12
			b > 8 * 13
			b > 8 * 14
			b > 8 * 15
			b > 8 * 16
			b > 8 * 17
			b > 8 * 18
			b > 8 * 19
			b > 8 * 20
			b > 8 * 21
			b > 8 * 22
			b > 8 * 23
			b > 8 * 24
			b > 8 * 25
			b > 8 * 26
			b > 8 * 27
			b > 8 * 28
			b > 8 * 29
			b > 8 * 30
			b > 8 * 31
			b > 8 * 32
			b > 8 * 33
			b > 8 * 34
			b > 8 * 35
			b > 8 * 36
			b > 8 * 37
			b > 8 * 38
			b > 8 * 39

;*** Startadressen der Grafikzeilen.
:COLOR_LINE_L		b <  0*40
			b <  1*40
			b <  2*40
			b <  3*40
			b <  4*40
			b <  5*40
			b <  6*40
			b <  7*40
			b <  8*40
			b <  9*40
			b < 10*40
			b < 11*40
			b < 12*40
			b < 13*40
			b < 14*40
			b < 15*40
			b < 16*40
			b < 17*40
			b < 18*40
			b < 19*40
			b < 20*40
			b < 21*40
			b < 22*40
			b < 23*40
			b < 24*40

:COLOR_LINE_H		b >  0*40
			b >  1*40
			b >  2*40
			b >  3*40
			b >  4*40
			b >  5*40
			b >  6*40
			b >  7*40
			b >  8*40
			b >  9*40
			b > 10*40
			b > 11*40
			b > 12*40
			b > 13*40
			b > 14*40
			b > 15*40
			b > 16*40
			b > 17*40
			b > 18*40
			b > 19*40
			b > 20*40
			b > 21*40
			b > 22*40
			b > 23*40
			b > 24*40

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_DB_SCREEN + R2S_DB_SCREEN -1
;******************************************************************************
