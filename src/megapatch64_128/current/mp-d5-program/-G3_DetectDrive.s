; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Alle Laufwerke am ser. Bus ermitteln und Typ feststellen.
;******************************************************************************
:GetAllSerDrive		ldy	#$17
			lda	#$00
::1			sta	DriveInfoTab,y
			dey
			bpl	:1

			lda	curDevice
			pha

			jsr	PurgeTurbo
			jsr	InitForIO

			lda	#$08
			sta	DriveAddress

::2			lda	DriveAddress
			jsr	DetectDrive
			tax
			bne	:6

			jsr	testCMD			;CMD-Kennung einlesen.
			cpx	#NO_ERROR		;Laufwerksfehler ?
			bne	:6			; => Ja, Abbruch...
			cmp	#$ff			;CMD-Laufwerk ?
			beq	:3			; => Nein, weiter...

			ldy	#DrvRAMLink
			cmp	#"R"			;RAMLink erkannt ?
			beq	:5			; => Ja, weiter...

			ldy	#DrvHD
			cmp	#"H"			;HD erkannt ?
			beq	:5			; => Ja, weiter...

			ldy	#DrvFD
			cmp	#"F"			;FD erkannt ?
			beq	:5			; => Nein, Laufwerk unbekannt.

;*** Ab hier Erkennung für 1541,71,81-Laufwerke.
::3			LoadW	r0,$e580		;Auf 1541/71 testen.
			jsr	testCBM
			cpx	#NO_ERROR		;Fehler aufgetreten ?
			bne	:6			; => Ja, Abbruch...
			cmp	#$00			;Laufwerk erkannt ?
			bne	:4			; => Ja, weiter...

			LoadW	r0,$a6c0		;Auf 1581 testen.
			jsr	testCBM
			cpx	#NO_ERROR		;Fehler aufgetreten ?
			bne	:6			; => Ja, Abbruch...

::4			ldy	#Drv1541		;Kennbyte für #1541.
			cmp	#$41			;1541-Laufwerk erkannt ?
			beq	:5			; => Ja, weiter...
			ldy	#Drv1571		;Kennbyte für #1571.
			cmp	#$71			;1571-Laufwerk erkannt ?
			beq	:5			; => Ja, weiter...
			ldy	#Drv1581		;Kennbyte für #1581.
			cmp	#$81			;1581-Laufwerk erkannt ?
			beq	:5			; => Ja, weiter...

			jsr	testSD2IEC		;Auf SD2IEC-Laufwerk testen.
			cpx	#NO_ERROR		;Laufwerksfehler ?
			bne	:6			; => Ja, Abbruch...
			cmp	#$00			;SD2IEC-Laufwerk ?
			bne	:6			; => Nein, weiter...

			ldy	#DrvNative		;SD2IEC ohne "M-R"-Emulation.
::5			tya
			ldx	DriveAddress
			sta	DriveInfoTab -8,x	;Laufwerktyp speichern.

::6			inc	DriveAddress		;Laufwerkszähler +1.
			lda	DriveAddress
			cmp	#29 +1			;Alle Laufwerke am ser.Bus geprüft?
			bcc	:2			; => Nein, weiter...

			pla
			sta	curDevice

			ldx	#NO_ERROR		; => "OK".
			jmp	DoneWithIO

;*** Prüfen ob Laufwerk am ser.Bus aktiv ist.
:DetectDrive		tax				;Laufwerksadresse einlesen und
			lda	#2			;testen ob Laufwerk aktiv.
			tay				;Nicht Sek.Adr #15 verwenden, macht
			jsr	SETLFS			;am C128 Probleme, da hier dann das
							;Status-Byte nicht gesetzt wird.
			lda	#0			;Kein Dateiname erforderlich.
;			tax
;			tay
			jsr	SETNAM
			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#2
			jsr	CLOSE			;Befehlskanal schließen.

			lda	STATUS			;STATUS = OK ?
			rts

;******************************************************************************
;*** Aktuelles Laufwerk erkennen.
;******************************************************************************
;*** CMD-Laufwerkstyp ermitteln.
;    Dazu Speicherbereich aus Floppy-ROM einlesen.
;    Anschließend innerhalb des gelesenen Bereichs die Kennung "CMD" suchen.
;    Das übernächste Byte gibt dann den Laufwerkstyp an.
:testCMD		LoadW	r0,$fea0		;Adresse für CMD-Kennung.
			jsr	InitFloppyCom
			jsr	ReadROM_Info
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch.
			cmp	#"C"			;"CMD" gefunden ?
			beq	:3			;Evtl. Ja, weiter...
::1			lda	#$ff			;Kein CMD-Laufwerk.
::2			rts

::3			jsr	ReadROM_Info
			cmp	#"M"			;"CMD" gefunden ?
			bne	:1			;Nein, kein CMD-Laufwerk...
			jsr	ReadROM_Info
			cmp	#"D"			;"CMD" gefunden ?
			bne	:1			;Nein, kein CMD-Laufwerk...

			jsr	ReadROM_Info		;Leerzeichen übergehen.
			jsr	ReadROM_Info		;Laufwerkstyp einlesen.
			cmp	#"F"			;CMD_FD ?
			beq	:4			;Ja, CMD-Laufwerk gefunden.
			cmp	#"H"			;CMD_HD ?
			beq	:4			;Ja, CMD-Laufwerk gefunden.
			cmp	#"R"			;CMD_RL ?
			bne	:1			;Nein, kein CMD-Laufwerk...
::4			ldx	#NO_ERROR
			rts

;*** Laufwerkstyp ermitteln.
;    Dazu Speicherbereich aus Floppy-ROM einlesen.
;    Anschließend innerhalb des gelesenen Bereichs die Kennung "15" suchen.
;    Das folgende Byte gibt dann den Laufwerkstyp an.
:testCBM		jsr	InitFloppyCom

			LoadW	r2,$0100		;Max. 256 Bytes testen.
::nxBuf			jsr	ReadROM_Info		;ROM-Daten einlesen.
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:exit			;Ja, Abbruch.
			cmp	#$31			;Byte #1 von "15xx" gefunden ?
			bne	:nxByte			;Nein, weitersuchen.

			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			cmp	#$35			;Byte #2 von "15xx" gefunden ?
			bne	:nxByte			;Nein, weiter...

			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			sta	r1L			;Kennbyte speichern.
			and	#%01110000
			cmp	#$30			;Ist Zeichen eine Zahl ?
			bne	:nxByte			;Nein, weiter...

			lda	r1L			;Kennbyte wieder einlesen.
			asl				;High-Nibble isolieren.
			asl
			asl
			asl
			sta	r1L
			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			sta	r1H			;Kennbyte speichern.
			and	#%01110000
			cmp	#$30			;Ist Zeichen eine Zahl ?
			bne	:nxByte			;Nein, weiter...

			lda	r1H			;Laufwerkskennung berechnen.
			and	#$0f			;Rückgabe ist dann "41","71","81".
			ora	r1L
			ldx	#NO_ERROR
::exit			rts

;*** Kennung noch nicht gefunden, weitersuchen.
::nxByte		lda	r2L
			bne	:1
			dec	r2H
::1			dec	r2L
			lda	r2L
			ora	r2H
			bne	:nxBuf
			ldx	#NO_ERROR
			rts

;******************************************************************************
;*** Aktuelles Laufwerk erkennen.
;******************************************************************************
;*** Auf SD2IEC-Laufwerk prüfen.
;Dabei wird auf "00, OK, 00, 00" getestet.
;Wenn der Wert vom Laufwerk übertragen wird, dann
;verwendet das SD2IEC keine "M-R"-Emulation.
:testSD2IEC		LoadW	r0,$fe00		;Adresse für SD2IEC-Test.
			jsr	InitFloppyCom		;"M-R" liefert hier "00, OK..."
			jsr	ReadROM_Info		;wenn keine "M-R"-Emulation aktiv.
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch.
			cmp	#"0"			;Bei SD2IEC "0" gefunden ?
			beq	:3			; => Evtl. Ja, weiter...
::1			lda	#$ff			;Kein SD2IEC-Laufwerk.
::2			rts

::3			jsr	ReadROM_Info
			cmp	#"0"			;Bei SD2IEC "0" gefunden ?
			bne	:1			; => Nein, kein SD2IEC.
			jsr	ReadROM_Info
			cmp	#","			;Bei SD2IEC "," gefunden ?
			bne	:1			; => Nein, kein SD2IEC.

			lda	#$00			;SD2IEC.
			rts

;******************************************************************************
;*** Aktuelles Laufwerk erkennen.
;******************************************************************************
;*** Zeiger auf ROM-Adresse in Floppy-Befehl kopieren.
:InitFloppyCom		lda	r0H
			sta	ROM_AddrH
			lda	r0L
			sta	ROM_AddrL
			lda	#$20
			sta	PosROM_Data
			rts

;*** Speicherbereich aus Floppy-ROM einlesen.
:ReadROM_Info		ldy	PosROM_Data		;Zeiger auf Datenspeicher.
			cpy	#$20			;32 Bytes gelesen ?
			bcs	RdNxROMBytes		;Ja, die nächsten 32 Byte einlesen.
			lda	DrvROM_Data,y		;Nächstes Byte aus Datenspeicher.
			inc	PosROM_Data		;Zeiger auf nächstes Byte.
			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
			rts

;*** Weitere 32 Byte aus Floppy-ROM einlesen.
:RdNxROMBytes		LoadW	r0,FloppyCom
			jsr	SendFloppyCom_6		;"M-R"-befehl an Floppy senden.
			beq	:1			;Kein Fehler, weiter...
			rts

::1			lda	DriveAddress		;Laufwerk auf "Senden" umschalten.
			jsr	$ffb4
			lda	#$ff
			jsr	$ff96

			ldy	#$00
::2			jsr	$ffa5			;ROM-Kennung einlesen.
			sta	DrvROM_Data,y
			iny
			cpy	#$20
			bcc	:2

			jsr	$ffab			;Laufwerk abschalten.

			lda	DriveAddress
			jsr	$ffb1
			lda	#$ef
			jsr	$ff93
			jsr	$ffae

			lda	#$00			;Zeiger auf erstes Byte in
			sta	PosROM_Data		;Datenspeicher.

			clc				;"M-R"-Befehl auf die nächsten
			lda	#$20			;32 Byte im Floppy-ROM richten.
			adc	ROM_AddrL
			sta	ROM_AddrL
			bcc	:3
			inc	ROM_AddrH
::3			jmp	ReadROM_Info		;Nächstes Byte aus Datenspeicher.

;*** Befehl an Floppy senden.
:SendFloppyCom_5	lda	#$05
			b $2c
:SendFloppyCom_6	lda	#$06
			sta	:2 +1

			lda	#$00			;Status-Byte löschen.
			sta	STATUS

			jsr	$ffab
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:3			;Ja, Abbruch...

			lda	DriveAddress
			jsr	$ffb1			;Laufwerk aktivieren.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:3			;Ja, Abbruch...

			lda	#$ff
			jsr	$ff93			;Laufwerk auf Empfang schalten.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:3			;Ja, Abbruch...

			ldy	#$00
::1			lda	(r0L),y			;Kommando-Befehl an Floppy senden.
			jsr	$ffa8
			iny
::2			cpy	#$06
			bcc	:1

			jsr	$ffae			;Laufwerk abschalten.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:3			;Ja, Abbruch...

			ldx	#NO_ERROR		;OK, Kein Fehler...
			rts

;*** Laufwerk nicht verfügbar!
::3			jsr	$ffae			;Laufwerk abschalten.
			ldx	#DEV_NOT_FOUND		;Fehler: "Device not present".
			rts

;*** Zwischenspeicher für Laufwerkserkennung.
:DriveAddress		b $00
:FloppyCom		b "M-R"
:ROM_AddrL		b $00
:ROM_AddrH		b $00
:ROM_Bytes		b $20
:PosROM_Data		b $00
:DrvROM_Data		s $20
:DriveInfoTab		s $18
