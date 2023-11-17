; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette formatieren.
:doFormatDisk		jsr	DrawFormatBox		;"Disk wird formatiert..."

			jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O aktivieren.

;--- Auf 1571 testen.
			ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvType -8,x	;Laufwerkstyp einlesen.
			cmp	#Drv1571		;1571-Laufwerk?
			bne	:setFormatMode		; => Nein, weiter...

			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			bne	:setFormatMode		; => Ja, weiter...

			jsr	Set1571Mode		;1571: Einseitig/Doppelseitig.
			jsr	Init1571		;Disk neu initialisieren.

			jsr	GetStatus		;Fehlerstatus einlesen.

;--- HINWEIS:
;Die Abfrage des Fehlerstatus gibt dem
;Laufwerk die Zeit den Init-Befehl
;auszuführen (Format1571-Problem).
;Die Rückantwort aber nicht auswerten,
;da bei nicht formatierten Disketten
;ein Fehler zurückgemeldet wird.
if FALSE
			lda	FComReply +0		;Fehlerstatus prüfen.
			cmp	#"0"
			bne	:1
			lda	FComReply +1
			cmp	#"0"
			beq	:setFormatMode
::1			jsr	DoneWithIO		;I/O abschalten.
			ldx	#DEV_NOT_FOUND		;Fehler beim Initialize.
			rts
endif

;--- Format-Modus wählen.
::setFormatMode		bit	optQuickFrmt		;QuickFormat?
			bmi	:doQuick		; => Ja, weiter...

::doStandard		lda	#<stdFormat		;Zeiger auf Standard-Format-Befehl.
			ldx	#>stdFormat
			ldy	#stdFormatLen		;Länge Standard-Format-Befehl.
			bne	:doFormat

::doQuick		lda	#<quickFormat		;Zeiger auf Quick-Format-Befehl.
			ldx	#>quickFormat
			ldy	#quickFormatLen		;Länge Quick-Format-Befehl.

::doFormat		sta	r0L			;Zeiger auf Format-Befehl.
			stx	r0H
			sty	r2L			;Länge Format-Befehl.
			jsr	SendFloppyCom		;Format-Befehl senden.
			jsr	UNLSN			;UNLISTEN an Laufwerk senden, da
							;SendFloppyCom den Kanal nach dem
							;senden des Befehls offen lässt!

;--- Formatieren beendet.
::endFormat		jsr	DoneWithIO		;I/O abschalten.

;--- VICE/DD8 Workaround:
;BUGFIX: VICE kann keine D81 DiskImages
;formatieren -> FORMAT ERROR.
;Wenn das DiskImage nur aus $00-Bytes
;besteht, dann Disk zusätzlich löschen.
			ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvType -8,x	;Laufwerkstyp einlesen.
			and	#%11111000
			cmp	#DrvFD			;CMD-FD-Laufwerk?
			bne	:skipfix		; => Nein, weiter...

			lda	RealDrvType -8,x	;Laufwerkstyp einlesen.
			and	#%00000111
			cmp	#Drv1581		;1581-Modus ?
			bne	:skipfix		; => Nein, weiter...

			LoadB	r1L,40
			LoadB	r1H,0
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten BAM-Sektor einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	diskBlkBuf		;BAM gültig ?
			bne	:skipfix		; => Ja, weiter...

			jsr	doClearDisk		;Diskette löschen.
;---

::skipfix		jsr	saveDiskName		;Disk-Name ersetzen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

			bit	curDiskGEOS		;GEOS-Disk erzeugen?
			bpl	:exit			; => Nein, Ende...

			jsr	SetGEOSDisk		;GEOS-Diskette erzeugen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::exit			ldx	#NO_ERROR
::err			rts

;*** 1571: Laufwerksmodus festlegen.
:Set1571Mode		bit	optDoubleSided		;1571: Doppelseitig?
			bmi	:set1571S2		; => Ja, weiter...

::set1571S1		lda	#<mode1Sided		;1571: SingleSided.
			ldx	#>mode1Sided
			bne	:setMode

::set1571S2		lda	#<mode2Sided		;1571: DoubleSided.
			ldx	#>mode2Sided

::setMode		sta	r0L			;Floppy-Befehl "U0>Mx".
			stx	r0H

			LoadB	r2L,6			;Länge Floppy-Befehl.
			jsr	SendFloppyCom		;Laufwerksmodus 1571 setzen.
			jmp	UNLSN			;UNLISTEN an Laufwerk senden.

;*** Laufwerk initialisieren.
:Init1571		LoadW	r0,modeInitDisk		;Floppy-Befehl "I0:".
			LoadB	r2L,4			;Länge Floppy-Befehl.
			jsr	SendFloppyCom		;Disk neu initialisieren.
			jmp	UNLSN			;UNLISTEN an Laufwerk senden.

;*** Rückmeldung von Floppy empfangen.
:GetStatus		lda	#$00
			tax
			tay
			jsr	SETNAM			;Kein Dateiname.

			lda	#15
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal #15 öffnen.

			LoadW	r0,FComReply
			LoadB	r1L,3

			lda	#$00
			sta	STATUS

			ldx	#15
			jsr	CHKIN

			lda	#$00
			sta	:101 +4
::101			jsr	GETIN
			ldy	#$ff
			cpy	r1L
			beq	:102
			sta	(r0L),y
			inc	:101 +4
			jmp	:101

::102			jsr	CLRCHN

			lda	#15
			jmp	CLOSE

;*** Variablen.
:optQuickFrmt		b $00
:optDoubleSided		b $ff

:FComReply		s $03

:stdFormat		b "N0:EMPTY,64",CR
:stdFormatEnd
:stdFormatLen		= (stdFormatEnd - stdFormat)

:quickFormat		b "N0:EMPTY",CR
:quickFormatEnd
:quickFormatLen		= (quickFormatEnd - quickFormat)

:mode1Sided		b "U0>M0",CR
:mode2Sided		b "U0>M1",CR
:modeInitDisk		b "I0:",CR
