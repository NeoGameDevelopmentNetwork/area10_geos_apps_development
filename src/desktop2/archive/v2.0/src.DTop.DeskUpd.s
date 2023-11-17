; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DeskTop aktualisieren.
:drawCurDTopScrn	lda	a8H			;Papierkorb voll?
			bne	:1			; => Ja, weiter...
			jsr	clearTrashName
::1			jsr	prntCurPadPage
			jsr	setPageNavIcon
			jmp	updInfoScrnSlct

;*** Aktuelle Deskpad-Seite anzeigen
.prntCurPadPage		jsr	clearFilePad
			jsr	testCurViewMode
			bcs	:1			; => Icon-Modus...

			lda	#$ff			;Bei Modul-Ladefehler
			sta	a9H			;immer Rückkehr.

			jsr	loadDTopMod4
			beq	:1			; => OK, weiter...

			lda	#$00			;Auf Icon-Modus
			sta	a7L			;zurückwechseln.

			jsr	clearCurPadPage
			jsr	setPageNavIcon

;--- Inhalt anzeigen.
::1			ldy	a7L
			lda	:tabVModeL,y
			ldx	:tabVModeH,y
			jmp	CallRoutine

;--- Zeiger auf Routinen für Dateiausgabe.
::tabVModeL		b < prntByIcon
			b < prntBySize
			b < prntByType
			b < prntByDate
			b < prntByName
::tabVModeH		b > prntByIcon
			b > prntBySize
			b > prntByType
			b > prntByDate
			b > prntByName

;*** Aktuelle Seite mit Icons ausgeben.
:prntByIcon		lda	#$00
::1			jsr	copyFIcon2Buf
			clc
			adc	#$01
			cmp	#ICON_PAD +8
			bcc	:1
			sec				;Makro-Madness!
			sbc	#$01 			;Icons ausgeben.
::2			jsr	prntIconTab1
			sec
			sbc	#$01
			bpl	:2

			lda	#> AREA_FULLPAD_X0 + FULLPAD_CX
			sta	r11H
			lda	#< AREA_FULLPAD_X0 + FULLPAD_CX
			sta	r11L
			lda	# AREA_FULLPAD_Y1 -16
			sta	r1H

			lda	#$00
			sta	r0H
			ldx	a0L
			inx
			stx	r0L
			lda	# SET_LEFTJUST ! SET_SUPRESS
			jmp	PutDecimal		;Seitenzahl ausgeben.

;*** Anzahl gewählte Dateien aktualisieren.
.updInfoScrnSlct	bit	a2H			;Dateiwahl aktiv?
			bmi	updCurInfoScrn

:updInfoScreen		jsr	clrBIconCurDisk

			lda	#> buf_diskSek3 +2
			sta	r14H
			lda	#< buf_diskSek3 +2
			sta	r14L

::1			jsr	readBorderIcon
			jsr	chkErrRestartDT
			clc
			lda	#$20
			adc	r14L
			sta	r14L
			bcc	:2
			inc	r14H
::2			lda	r14H
			cmp	#> buf_diskSek3 +256
			bcc	:1

:updCurInfoScrn		jsr	clrBIconsUpdPrnt
			jsr	drawBIconsTrash
			lda	a8H			;Papierkorb leer?
			beq	:exit			; => Ja, weiter...
			lda	#> bufLastDelEntry
			sta	r0H
			lda	#< bufLastDelEntry
			sta	r0L
			jsr	setLastDelFile
::exit			rts

;*** Border-Icons von aktueller Disk vom Rand entfernen.
.clrBIconCurDisk	ldx	#r14L
			jsr	setVecOpenDkNm

			lda	#> tabBIconDkNm
			sta	r15H
			lda	#< tabBIconDkNm
			sta	r15L

			lda	#ICON_BORDER
			sta	a4H
::find			ldx	#r15L
			ldy	#r14L
			lda	#18
			jsr	CmpFString		;Border-Icon-Disk?
			bne	:skip			; => Nein, weiter...

			lda	#$00
			tay
			sta	(r15L),y
			lda	a4H
			ldx	#r5L
			jsr	setVecIcon2File
			lda	#$00
			tay
			sta	(r5L),y
			lda	a4H
			jsr	iconTabDelEntry

::skip			clc				;Zeger auf Diskname
			lda	#18			;für das nächste
			adc	r15L			;Border-Icon.
			sta	r15L
			bcc	:1
			inc	r15H

::1			inc	a4H
			lda	a4H
			cmp	#ICON_BORDER +8
			bcc	:find
			rts
