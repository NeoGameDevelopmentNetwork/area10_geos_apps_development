; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien im Verzeichnis analysieren.
;Die Datei-Einträge liegen bereits im
;Speicher ab ":dirDiskBuf"!
.analyzeDirFiles	lda	#$00
			sta	r0L
			sta	bufTrSePrefs +0
			sta	bufTrSePadCol +0
			sta	vec1stInput +1
			sta	vec1stPrint +1
			sta	r9H
			sta	r3L
			lda	#> tabNameDeskAcc -4
			sta	r1H
			lda	#< tabNameDeskAcc -4
			sta	r1L
			lda	#> dirDiskBuf
			sta	r2H

::next_block		ldy	#< dirDiskBuf
;			ldy	#$00
			sty	r2L

			lda	(r2L),y			;Link-Track nächste
			pha				;Directory-Seite.

::next_entry		jsr	testDirEntryType

			clc
			lda	#$20
			adc	r2L
			sta	r2L
			bcc	:1
			inc	r2H

::1			lda	r2L
			bne	:next_entry

			pla				;Ende erreicht?
			bne	:next_block		; => Nein, weiter...

			lda	isGEOS			;GEOS-Diskette?
			beq	:2			; => Nein, weiter...
			lda	#$7f			;Border-Block bereits
			cmp	r2H			;eingelesen?
			bcc	:2			; => Ja, weiter...
			sta	r2H			;Dateien Border-Block
			clv				;einlesen.
			bvc	:next_block

::2			lda	r0L
			pha
			lda	r3L
			clc
			adc	#$04
			jsr	updateMenuGEOS

			lda	r9H
			pha
			lda	r9L
			pha
			jsr	updatePrntStatus
			pla
			sta	r9L
			pla
			sta	r9H
			lda	#$ff			;Diskette gültig.
			sta	flagDiskRdy
			pla
			sta	r0L
			lda	#$00
			sta	r0H
			rts

;*** Dateityp auswerten.
.testDirEntryType	ldy	#$02
			lda	(r2L),y
			bne	:test_da
			rts

::test_da		inc	r0L

			ldy	#$18
			lda	(r2L),y
			cmp	#DESK_ACC
			bne	:test_input

			lda	r3L			;Max. 8 DAs.
			cmp	#$08			;GEOS-Menü voll?
			bcs	:test_input		; => Ja, weiter...

			ldy	#$15			;Name DeskAccessory
			bne	:2			;in GEOS-Menü
::1			lda	(r2L),y			;übernehmen.
			cmp	#$a0
			bne	:3
::2			lda	#$00
::3			dey
			sta	(r1L),y
			cpy	#$05
			bcs	:1

			clc
			lda	#17
			adc	r1L
			sta	r1L
			bcc	:4
			inc	r1H
::4			inc	r3L
			rts

;--- Dateityp "Eingabegerät" gefunden?
::test_input		cmp	#INPUT_DEVICE
			bne	:test_printer

			lda	vec1stInput +1
			bne	:test_printer

			lda	r2L
			clc
			adc	#< $0005
			sta	vec1stInput +0
			lda	r2H
			adc	#> $0005
			sta	vec1stInput +1
			rts

;--- Dateityp "Drucker" gefunden?
::test_printer		cmp	#PRINTER
			bne	:test_system

			lda	vec1stPrint +1
			bne	:test_system

			lda	r2L
			clc
			adc	#< $0005
			sta	vec1stPrint +0
			lda	r2H
			adc	#> $0005
			sta	vec1stPrint +1
			rts

;--- Dateityp "SYSTEM" gefunden?
::test_system		cmp	#SYSTEM
			bne	:test_temp

;--- Datei "Preferences" gefunden?
::sys_pref		lda	#> fileNamePref -5
			sta	r5H
			lda	#< fileNamePref -5
			sta	r5L
			jsr	cmpDirEntryFNam
			bne	:sys_padcol

			ldy	#$03
			lda	(r2L),y
			sta	bufTrSePrefs +0
			iny
			lda	(r2L),y
			sta	bufTrSePrefs +1
			rts

;--- Datei "Pad Color Pref" gefunden?
::sys_padcol		lda	#> fileNamePadCol -5
			sta	r5H
			lda	#< fileNamePadCol -5
			sta	r5L
			jsr	cmpDirEntryFNam
			bne	:exit

			ldy	#$03
			lda	(r2L),y
			sta	bufTrSePadCol +0
			iny
			lda	(r2L),y
			sta	bufTrSePadCol +1
			rts

;*** Dateityp "TEMPORARY" gefunden?
::test_temp		cmp	#TEMPORARY
			bne	:exit

			lda	r2L
			clc
			adc	#$02
			sta	r9L
			lda	r2H
			adc	#$00
			sta	r9H
::exit			rts

;*** Dateiname vergleichen.
;Übergabe: r2 = Zeiger auf Verzeichniseintrag #1.
;          r5 = Zeiger auf Verzeichniseintrag #2.
:cmpDirEntryFNam	ldy	#$05
::1			lda	(r2L),y
			cmp	(r5L),y
			bne	:2
			iny
			cpy	#$15
			bcc	:1
::2			rts
