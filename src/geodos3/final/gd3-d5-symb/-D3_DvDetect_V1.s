; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aktuelles Laufwerk testen.
:DetectCurDrive		jsr	xTestSBusDrive		;Laufwerk in AKKU testen.

			ldx	#DEV_NOT_FOUND
			cmp	#NO_ERROR
			bne	:exit			; => Nicht vorhanden, weiter...

;--- Ergänzung: 11.07.21/M.Kanet
;Workaround für VICE/RAMLink:
;Wenn zuvor die RL-Partition gelöscht
;wurde, dann wird ohne "I:"-Befehl beim
;öffnen der Disk über ":OpenDisk" nicht
;die aktuelle BAM zurückgemeldet.
;Der Fehler tritt erst auf, wenn hier
;der Befehlskanal geöffnet wird.
;Wenn der Befehlskanal mit "I0:" als
;Dateiname geöffnet wird, dann tritt
;das Problem nicht mehr auf.
;Da aber ":openFComChan" evtl. auch in
;anderen Routinen Verwendung findet,
;wird hier "I0:" manuell gesendet.
			jsr	openFComChan		;Befehlskanal öffnen.

			lda	#< :FCom_I0		;Disk initialisieren.
			ldx	#> :FCom_I0
			ldy	#:FCom_I0_len
			jsr	xSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	closeFComChan		;Befehlskanal schließen.
;---

			jsr	openFComChan		;Befehlskanal öffnen.
			jsr	openDataChan		;Datenkanal öffnen.

			jsr	testViceFS		;VICE/VDRIVE (Not supported).
			txa				;Laufwerk erkannt ?
			beq	:setDevData		; => Ja, weiter...

			jsr	testSD2IEC		;SD2IEC.
			txa				;Laufwerk erkannt?
			bne	:CMD			; => Nein, weiter...

			ldx	curDevice		;SD2IEC-Modus speichern.
			tya
			sta	sysDevInfo -8,x
			bne	:CBM

;--- Ab hier CMD-Laufwerke finden.
::CMD			jsr	testCMD			;CMD-Laufwerk.
			txa				;Laufwerk erkannt ?
			bne	:CBM			; => Nein, weiter...

			ldx	curDevice		;CMD-Modus speichern.
			tya
			sta	sysDevInfo   -8,x
			bne	:close

;--- Ab hier Erkennung für 1541,71,81-Laufwerke.
::CBM			jsr	testCBM			;C=1581.
			txa				;Laufwerk erkannt?
			beq	:setDevData		; => Ja, weiter...

;--- Kein C=-Laufwerk.
			ldx	curDevice
			lda	sysDevInfo   -8,x	;SD2IEC-Laufwerk ?
			beq	:noDevice		; => Nein, Laufwek nicht erkannt.

			ldy	#DrvNative		;SD2IEC ohne "M-R"-Emulation.
			b $2c

;--- Kein Laufwerk erkannt.
::noDevice		ldy	#$00			;Kein Laufwerk.

;--- Emulationsmodus mit SD2IEC-Flag verknüpfen.
::setDevData		ldx	curDevice
			tya				;Laufwerkstyp speichern.
			ora	sysDevInfo   -8,x
			sta	sysDevInfo   -8,x

::close			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.

			ldx	#NO_ERROR		;Kein Fehler.
::exit			rts

::FCom_I0		b "I0:"
::FCom_I0_end
::FCom_I0_len		= (:FCom_I0_end - :FCom_I0)

;*** Auf CMD-Laufwerk testen.
;    Dazu Speicherbereich aus Floppy-ROM einlesen.
;    Anschließend innerhalb des gelesenen Bereichs die Kennung "CMD" suchen.
;    Das übernächste Byte gibt dann den Laufwerkstyp an.
:testCMD		lda	#< $fea0		;Adresse für CMD-Kennung.
			ldx	#> $fea0
			jsr	InitFloppyCom

			jsr	ReadROM_Info
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch.
			cmp	#"C"			;"CMD" gefunden ?
			bne	:err			;Evtl. Ja, weiter...

			jsr	ReadROM_Info
			cmp	#"M"			;"CMD" gefunden ?
			bne	:err			;Nein, kein CMD-Laufwerk...

			jsr	ReadROM_Info
			cmp	#"D"			;"CMD" gefunden ?
			bne	:err			;Nein, kein CMD-Laufwerk...

			jsr	ReadROM_Info		;Leerzeichen übergehen.
			jsr	ReadROM_Info		;Laufwerkstyp einlesen.
			ldx	#NO_ERROR
			cmp	#"F"			;"F"D ?
			beq	:devFD			; => Ja, CMD-FD.
			cmp	#"H"			;"H"D ?
			beq	:devHD			; => Ja, CMD-HD.
			cmp	#"R"			;"R"AMLink ?
			beq	:devRL			; => Ja, CMD-RAMLink.

::err			ldx	#DEV_NOT_FOUND		;Kein CMD-Laufwerk.
			ldy	#$00
			b $2c
::devFD			ldy	#DrvFD
			b $2c
::devHD			ldy	#DrvHD
			b $2c
::devRL			ldy	#DrvRAMLink
::exit			rts

;*** Auf Commodore-Laufwerk testen.
;    Dazu Speicherbereich aus Floppy-ROM einlesen.
;    Anschließend innerhalb des gelesenen Bereichs die Kennung "15" suchen.
;    Die beiden folgenden Bytes geben dann den Laufwerkstyp an.
:testCBM		lda	#< $e580		;Auf 1541/71 testen.
			ldx	#> $e580
			jsr	:read_rom
			cpx	#NO_ERROR		;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abbruch...
			cmp	#$00			;Laufwerk erkannt ?
			bne	:test			; => Ja, weiter...

			lda	#< $a6c0		;Auf 1581 testen.
			ldx	#> $a6c0
			jsr	:read_rom
			cpx	#NO_ERROR		;Fehler aufgetreten ?
			bne	:exit			; => Ja, Abbruch...

::test			ldy	#Drv1541		;Kennbyte für #1541.
			cmp	#$41			;1541-Laufwerk erkannt ?
			beq	:exit			; => Ja, weiter...
			ldy	#Drv1571		;Kennbyte für #1571.
			cmp	#$71			;1571-Laufwerk erkannt ?
			beq	:exit			; => Ja, weiter...
			ldy	#Drv1581		;Kennbyte für #1581.
			cmp	#$81			;1581-Laufwerk erkannt ?
			beq	:exit			; => Ja weiter...

			ldx	#DEV_NOT_FOUND
			ldy	#$00
::exit			rts

;--- ROM-Daten auslesen.
::read_rom		jsr	InitFloppyCom

			LoadW	r2,$0100		;Max. 256 Bytes testen.
::nxBuf			jsr	ReadROM_Info		;ROM-Daten einlesen.
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:error			;Ja, Abbruch.
			cmp	#"1"			;Byte #1 von "15xx" gefunden ?
			bne	:nxByte			;Nein, weitersuchen.

			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			cmp	#"5"			;Byte #2 von "15xx" gefunden ?
			bne	:nxByte			; => Nein, weiter...

;--- Kennung erzeugen: Text "41" => Hex-Zahl $41.
			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			sta	r1L			;Kennbyte speichern.
			and	#%01110000		;Bit#7 ausblenden (String-Ende-Bit).
			cmp	#"0"			;Ist Zeichen eine Zahl ?
			bne	:nxByte			; => Nein, weiter...

			lda	r1L			;Kennbyte wieder einlesen.
			asl				;High-Nibble isolieren.
			asl
			asl
			asl
			sta	r1L
			jsr	ReadROM_Info		;Nächstes Byte aus ROM einlesen.
			sta	r1H			;Kennbyte speichern.
			and	#%01110000		;Bit#7 ausblenden (String-Ende-Bit).
			cmp	#"0"			;Ist Zeichen eine Zahl ?
			bne	:nxByte			; => Nein, weiter...

			lda	r1H			;Laufwerkskennung berechnen.
			and	#%00001111		;Rückgabe ist dann $41/$71/$81.
			ora	r1L

			ldx	#NO_ERROR
::error			rts

;--- Kennung noch nicht gefunden, weitersuchen.
::nxByte		lda	r2L
			bne	:1
			dec	r2H
::1			dec	r2L

			lda	r2L
			ora	r2H			;Puffer durchsucht?
			bne	:nxBuf			; => Ja, weitere Daten einlesen.

			ldx	#NO_ERROR
			rts

;*** Zeiger auf ROM-Adresse in Floppy-Befehl kopieren.
:InitFloppyCom		sta	fCom_MR_Adr +0		;ROM-Adresse.
			stx	fCom_MR_Adr +1

			lda	#32			;Lesen der ersten ROM-Daten
			sta	PosROM_Data		;durch Position setzen erzwingen.
			rts

;*** Weitere 32 Byte aus Floppy-ROM einlesen.
:RdNxROMBytes		lda	#< fCom_MR
			ldx	#> fCom_MR
			ldy	#6
			jsr	xSendComVLen		;"M-R"-Befehl an Floppy senden.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk aktivieren.
			beq	:ok			; => Kein Fehler, weiter...
::err			ldx	#DEV_NOT_FOUND
			rts

::ok			ldy	#$00
::loop			jsr	ACPTR			;ROM-Kennung einlesen.
			sta	DrvROM_Data,y
			iny
			cpy	#32
			bcc	:loop

			jsr	UNTALK			;Laufwerk abschalten.

			lda	#$00			;Zeiger auf erstes Byte in
			sta	PosROM_Data		;Datenspeicher.

			clc				;"M-R"-Befehl auf die nächsten
			lda	#32			;32 Byte im Floppy-ROM richten.
			adc	fCom_MR_Adr +0
			sta	fCom_MR_Adr +0
			bcc	ReadROM_Info
			inc	fCom_MR_Adr +1

;*** Speicherbereich aus Floppy-ROM einlesen.
:ReadROM_Info		ldy	PosROM_Data		;Zeiger auf Datenspeicher.
			cpy	#32			;32 Bytes gelesen ?
			bcs	RdNxROMBytes		;Ja, die nächsten 32 Byte einlesen.

			lda	DrvROM_Data,y		;Nächstes Byte aus Datenspeicher.
			inc	PosROM_Data		;Zeiger auf nächstes Byte.

			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
			rts

;*** Zwischenspeicher für Laufwerkserkennung
:fCom_MR		b "M-R"
:fCom_MR_Adr		w $0000
:fCom_MR_Count		b 32
:PosROM_Data		b $00
:DrvROM_Data		s 32
