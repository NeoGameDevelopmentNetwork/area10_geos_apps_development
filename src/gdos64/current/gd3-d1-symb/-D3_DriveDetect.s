; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Geräteerkennung/Laufwerkstabelle.
;******************************************************************************
;
;Wird von o.DiskCore, GD.BOOT und
;GD.UPDATE verwendet.
;Übergabe der gefundenen Laufwerke
;intern direkt über ":listDevType" und
;extern über ":_DDC/_PRG_DEVTYPE".
;
;Wenn diese Routine aufgerufen wird,
;dann darf auf dem aktiven Laufwerk das
;TurboDOS nicht mehr aktiv sein!
;
;--- DISKCORE/BOOT/UPDATE
;
;C=1541/1571/1581 = $01/$02/03
;CMD FD/HD/RL     = $10/$20/$30
;SD2IEC           = $41/$42/$43/$44
:listDevType		s 22 ;(#8-29)
;
;--- DISKCORE
;
;Wird verwendet wenn DriveDetect in
;DiskCore eingebunden wird.
;
if DETECT_MODE = %10000000
;$00 = Frei
;$FF = Durch GEOS belegt
:listDevUsed		s 22 ;(#8-29)
;
._DDC_DEVTYPE		= listDevType
._DDC_DEVUSED		= listDevUsed
endif
;
;--- BOOT/UPDATE
;
;Wird verwendet wenn DriveDetect direkt
;in ein Programm integriert wird.
;
if DETECT_MODE = %01000000
:_PRG_DEVTYPE		= listDevType
endif
;******************************************************************************

;*** Laufwerke am ser.Bus erkennen.
:_SER_GETALLDRV		ldy	#8			;Informationstabelle löschen.
			lda	#$00
::1			sta	listDevType -8,y
			iny
			cpy	#29 +1
			bcc	:1

			lda	curDevice		;GEOS-TurboDOS auf allen
			pha				;Laufwerken abschalten.

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#$08			;Zeiger auf erstes Laufwerk.
::loop			stx	curDevice

			jsr	_SER_GETCURDRV		;Laufwerk in AKKU testen.

::next			ldx	curDevice		;Nächstes Laufwerk.
			inx
			cpx	#29 +1			;Alle Laufwerke getestet?
			bcc	:loop			; => Nein, weiter...

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

;--- Alle Laufwerke erkannt, Ende.
			ldx	#NO_ERROR		; => "OK".
			rts

;*** Aktuelles Laufwerk testen.
;Übergabe: XReg = Geräteadresse #8-29
:_SER_GETCURDRV		lda	#2			;Laufwerksadresse einlesen und
;			ldx	curDevice		;testen ob Laufwerk aktiv.
			tay				;Nicht Sek.Adr #15 verwenden, macht
			jsr	SETLFS			;am C128 Probleme, da hier dann das
							;Status-Byte nicht gesetzt wird.
			lda	#0			;Kein Dateiname erforderlich.
;			tax
;			tay
			jsr	SETNAM
			jsr	OPENCHN			;Datenkanal öffnen.

			lda	#2
			jsr	CLOSE			;Datenkanal schließen.

			ldx	#DEV_NOT_FOUND
			lda	STATUS			;STATUS = OK ?
			cmp	#NO_ERROR
			bne	:exit			; => Nicht vorhanden, weiter...

			jsr	serFComOpen		;Befehlskanal öffnen.

;--- Hinweis:
;Wenn hier auf C=15x1 getestet wird,
;dann wird auch ein SD2IEC mit einem
;aktivierten Laufwerks-ROM als echtes
;C=15x1-Laufwerk erkannt.
;			jsr	testDrvROM		;Reset-Meldung auswerten.
;			txa				;Laufwerk erkannt ?
;			bne	:testDevModes		; => Nein, Eigenschaften testen...
;
;			jmp	:setDevData		;Laufwerk erkannt, Ende...

::testDevModes		jsr	testViceFS		;VICE/VDRIVE (Not supported).
			txa				;Laufwerk erkannt?
			beq	:setDevData		; => Ja, weiter...

			jsr	testSD2IEC		;SD2IEC.
			txa				;Laufwerk erkannt?
			bne	:testROM		; => Nein, weiter...

::isSD2IEC		ldx	curDevice		;SD2IEC-Modus speichern.
			tya
			sta	listDevType -8,x
			jmp	:CBM

;--- Hinweis:
;Nach ViceFS und SD2IEC auf andere
;Laufwerkstypen testen.
;Dabei wird zuerst das ROM ausgelesen
;und danach die Eigenschaften des
;Laufwerks getestet.
::testROM		jsr	testDrvROM		;ROM-Meldung auswerten.
			txa				;Laufwerk erkannt ?
			beq	:setDevData		; => Nein, Eigenschaften testen...

::CMD			jsr	testCMD			;CMD-Laufwerk.
			txa				;Laufwerk erkannt?
			bne	:CBM			; => Nein, weiter...

			ldx	curDevice		;CMD-Modus speichern.
			tya
			sta	listDevType -8,x
			bne	:close

::CBM			jsr	testNative		;SD2IEC-Native.
			txa				;Laufwerk erkannt?
			beq	:setDevData		; => Ja, weiter...

			jsr	testC1581		;C=1581.
			txa				;Laufwerk erkannt?
			beq	:setDevData		; => Ja, weiter...

			jsr	testC1571		;C=1581.
			txa				;Laufwerk erkannt?
			beq	:setDevData		; => Ja, weiter...

			jsr	testC1541		;C=1581.
			txa				;Laufwerk erkannt?
			beq	:setDevData		; => Ja, weiter...

;--- Kein C=-Laufwerk.
			ldx	curDevice
			lda	listDevType   -8,x	;SD2IEC-Laufwerk ?
			beq	:noDevice		; => Nein, Laufwek nicht erkannt.

			ldy	#DrvNative		;SD2IEC-Native als Vorgabe.
			b $2c

;--- Kein Laufwerk erkannt.
::noDevice		ldy	#$00			;Kein Laufwerk.
::setDevData		ldx	curDevice
			tya
			ora	listDevType -8,x	;Ggf. mit SD2IEC-Flag verknüpfen.
			sta	listDevType -8,x	;Laufwerksemulation speichern.

::close			jsr	serFComClose		;Befehlskanal schließen.

			ldx	#NO_ERROR		;Kein Fehler.
::exit			rts

;*** Partitionsdaten einlesen.
;Übergabe: AKKU = Partitionsnummer.
:_SER_GETCMDPART	sta	:FCom_GP +3

			lda	#< :FCom_GP
			ldx	#> :FCom_GP
			ldy	#:FCom_GP_len
			jsr	serSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	#< devDataBuf
			ldx	#> devDataBuf
			ldy	#31
			jmp	serReadData

::FCom_GP		b "G-P",$00,CR
::FCom_GP_end
::FCom_GP_len		= (:FCom_GP_end - :FCom_GP)

;*** Laufwerks-ROM auswerten.
:testDrvROM		lda	#< $fea1		;$FEA0 +1
			ldx	#> $fea1
			jsr	:readDrvInfo

			ldx	#0			;CMD-FD
			jsr	:findDevice
			beq	:found_cmd
			ldx	#4			;CMD-HD
			jsr	:findDevice
			beq	:found_cmd
			ldx	#8			;CMD-RL
			jsr	:findDevice
			bne	:no_cmd
::found_cmd		rts

::no_cmd		lda	#< $a6e7		;$A6E7
			ldx	#> $a6e7
			jsr	:readDrvInfo

			ldx	#12			;1581
			jsr	:findDevice
			bne	:no_1581
::found_1581		rts

::no_1581		lda	#< $e5c4		;$E5C4
			ldx	#> $e5c4
			jsr	:readDrvInfo

			ldx	#16			;1541
			jsr	:findDevice
			beq	:found_cbm
			ldx	#20			;1570
			jsr	:findDevice
			beq	:found_cbm
			ldx	#24			;1571
			jsr	:findDevice
			bne	:no_cbm
::found_cbm		rts

::no_cbm		ldx	#DEV_NOT_FOUND
			rts

::findDevice		ldy	#0
			dex
::l1			inx
			lda	:romData,y
			cmp	:drvData,x
			bne	:failed
			iny
			cpy	#4
			bcc	:l1

			txa
			lsr
			lsr
			tax
			ldy	:drvType,x		;Laufwerkstyp aus Tabelle einlesen.
			ldx	#NO_ERROR		;Laufwerk erkannt.

::failed		rts

::readDrvInfo		sta	:FCom_ROM_adr +0
			stx	:FCom_ROM_adr +1

			lda	#< :FCom_ROM		;Disk initialisieren.
			ldx	#> :FCom_ROM
			ldy	#:FCom_ROM_len
			jsr	serSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK
			bne	:err

			ldy	#0
::loop			jsr	ACPTR
			and	#%01111111		;Bit#7 löschen (Textende-Kennung).
			sta	:romData,y
			iny
			cpy	#4
			bcc	:loop

			jsr	UNTALK

			ldx	#NO_ERROR
			b $2c
::err			ldx	#DEV_NOT_FOUND
			rts

::FCom_ROM		b "M-R"
::FCom_ROM_adr		w $ffff
			b $04
::FCom_ROM_end
::FCom_ROM_len		= (:FCom_ROM_end - :FCom_ROM)

::romData		s $04

;--- Tabelle mit 4-Byte-ROM-Kennung.
::drvData		b "MD F"
			b "MD H"
			b "MD R"
			b "1581"
			b "1541"
			b "1570"
			b "1571"

;--- Tabelle mit Laufwerkstypen.
::drvType		b DrvFD				;CMD FD
			b DrvHD				;CMD HD
			b DrvRAMLink			;CMD RAMLink
			b Drv1581			;CBM 1581
			b Drv1541			;CBM 1541
			b Drv1541			;CBM 1570
			b Drv1571			;CBM 1571

;*** Auf CMD-Laufwerk testen.

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
;Da aber ":serFComOpen" evtl. auch in
;anderen Routinen Verwendung findet,
;wird hier "I0:" manuell gesendet.
:testCMD		lda	#< :FCom_I0		;Disk initialisieren.
			ldx	#> :FCom_I0
			ldy	#:FCom_I0_len
			jsr	serSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	#$00			;Systempartition.
			jsr	_SER_GETCMDPART		;Partitionsdaten einlesen.

::testFD		ldx	#NO_ERROR

			ldy	#0			;Auf CMD-FD ohne Diskette testen.
			tya				;ACTUNG:
::1			clc				;Wenn die Diskette entfernt wurde,
			adc	devDataBuf,y		;dann findet sich die letzte
			iny				;System-Partition noch im RAM!
			cpy	#30 +1
			bcc	:1
			cmp	#CR			;Alle Bytes = $00 ?
			beq	:devFD			; => Ja, CMD-FD.

			lda	devDataBuf +0		;Partitionstyp einlesen.
			cmp	#255			;System = 255?
			bne	:err			; => Nein, kein CMD-Laufwerk.
			lda	devDataBuf +2		;Partitionsnummer = 0 ?
			bne	:err			; => Nein, kein CMD-Laufwerk.
			lda	devDataBuf +19		;High-Byte Sektor = 0 ?
			bne	:err			; => Nein, kein CMD-Laufwerk.
			lda	devDataBuf +27		;High-Byte Partitionsgröße = 0 ?
			bne	:err			; => Nein, kein CMD-Laufwerk.

			lda	devDataBuf +1		;Diskette im CMD-Laufwerk ?
			bmi	:devFD			; => Ja, CMD-FD.

::testHD		lda	devDataBuf +28		;Größe Systempartition gültig?
			bne	:err			; => Nein, kein CMD-Laufwerk.
			lda	devDataBuf +29
			cmp	#144			;Größe = 144 x 512B-Sektoren?
			beq	:devHD			; => Ja, CMD-HD.

::testRL		lda	devDataBuf +29
			cmp	#16			;Größe = 16 x 512B-Sektoren?
			beq	:devRL			; => Ja, CMD-RL.

::err			ldx	#DEV_NOT_FOUND		;Kein CMD-Laufwerk.
			ldy	#$00
			b $2c
::devFD			ldy	#DrvFD
			b $2c
::devHD			ldy	#DrvHD
			b $2c
::devRL			ldy	#DrvRAMLink
::exit			rts

::FCom_I0		b "I0:"
::FCom_I0_end
::FCom_I0_len		= (:FCom_I0_end - :FCom_I0)

;*** Auf 1541/1571/1581/SD2IEC testen.
;Rückgabe: XReg = NO_ERROR/DEV_NOT_FOUND
;          YReg = Drv1541/71/81/Native
:testC1541		ldy	#0 *3
			b $2c
:testC1571		ldy	#1 *3
			b $2c
:testC1581		ldy	#2 *3
			b $2c
:testNative		ldy	#3 *3

			lda	:sekData +0,y
			jsr	:dez2ascii
			stx	:FCom_U1 + 7
			sta	:FCom_U1 + 8

			lda	:sekData +1,y
			jsr	:dez2ascii
			stx	:FCom_U1 +10
			sta	:FCom_U1 +11

			lda	:sekData +2,y
			pha

			jsr	serDataOpen		;Datenkanal öffnen.

			lda	#< :FCom_U1
			ldx	#> :FCom_U1
			ldy	#:FCom_U1_len
			jsr	serSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	serDataClose		;Datenkanal schließen.

			jsr	serReadStatus		;Laufwerksstatus einlesen.

			pla
			tay

			ldx	#NO_ERROR

			lda	#"0"
			cmp	devDataBuf +0
			bne	:err
			cmp	devDataBuf +1
			bne	:err
			lda	#","
			cmp	devDataBuf +2
			beq	:exit

::err			ldx	#DEV_NOT_FOUND		;Keine 1581.
::exit			rts

::FCom_U1		b "U1 5 0 01 01"
::FCom_U1_end
::FCom_U1_len		= (:FCom_U1_end - :FCom_U1)

::sekData		b 35, 1,Drv1541
			b 79, 1,Drv1571
			b 80,39,Drv1581
			b  1,99,DrvNative

;*** Dezimalzahl nach ASCII wandeln.
;    Übergabe: AKKU = Dezimal-Zahl 0-99.
;    Rückgabe: XREG/AKKU = 10er/1er Dezimalzahl.
::dez2ascii		ldx	#"0"
::dez10			cmp	#10			;Restwert < 10?
			bcc	:dez1			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:dez10			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::dez1			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
			rts

;*** Auf VICE/VDRIVE-Laufwerk testen.
;Sendet U1-Befehl an das Laufwerk, ein
;"30,SYNTAX ERROR" deutet auf ein VICE
;Dateisystem-Laufwerk hin.
;Rückgabe: YReg = 127 / VICE-FS.
;          XReg = Laufwerk erkannt.
:testViceFS		lda	#< :FCom_U1
			ldx	#> :FCom_U1
			ldy	#:FCom_U1_len
			jsr	serSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			jsr	serReadStatus		;Laufwerksstatus einlesen.

			ldx	#NO_ERROR		;Kein Fehler.

			ldy	#DrvVICEFS		;Kennung für VICE/VDRIVE.
			lda	devDataBuf +0
			cmp	#"3"
			bne	:err
			lda	devDataBuf +1
			cmp	#"0"
			bne	:err
			lda	devDataBuf +2
			cmp	#","
			beq	:exit

::err			ldx	#DEV_NOT_FOUND		;Kein VICE/VDRIVE.
::exit			rts

::FCom_U1		b "U1 5 0 1 1"
::FCom_U1_end
::FCom_U1_len		= (:FCom_U1_end - :FCom_U1)

;*** Auf SD2IEC-Laufwerk testen.
:testSD2IEC		lda	#< :FCom_MR
			ldx	#> :FCom_MR
			ldy	#:FCom_MR_len
			jsr	serSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	#< devDataBuf
			ldx	#> devDataBuf
			ldy	#3
			jsr	serReadData

			ldx	#NO_ERROR
			ldy	#%01000000
			lda	devDataBuf +0
			cmp	#"0"
			bne	:err
			lda	devDataBuf +1
			cmp	#"0"
			bne	:err
			lda	devDataBuf +2
			cmp	#","
			beq	:exit

::err			ldx	#DEV_NOT_FOUND		;Kein SD2IEC.
::exit			rts

::FCom_MR		b "M-R"
			w $0300
			b $03
::FCom_MR_end
::FCom_MR_len		= (:FCom_MR_end - :FCom_MR)

;*** Befehlskanal öffnen.
:serFComOpen		lda	#$00			;Status löschen.
			sta	STATUS

;			lda	#$00
			tax
			tay
			jsr	SETNAM			;Kein Dateiname.
			lda	#15			;open 15,dv,15
			tay
			ldx	curDevice
			jsr	SETLFS			;Daten für Befehlskanal.
			jsr	OPENCHN			;Befehlskanal #15 öffnen.

			ldx	STATUS			;Fehler?
			beq	:1			; => Nein, weiter...
			jsr	serFComClose		;Befehlskanal schließen.
			ldx	#CANCEL_ERR		;Laufwerksfehler.
::1			rts

;*** Datenkanal öffnen.
:serDataOpen		lda	#$00			;Status löschen.
			sta	STATUS

			lda	# :comDBufLen		;open x,y,z,"#"
			ldx	#< :comDBufChan
			ldy	#> :comDBufChan
			jsr	SETNAM			;Datenkanal, Name "#".
			lda	#5			;open 5,dv,5
			tay
			ldx	curDevice
			jsr	SETLFS			;Daten für Datenkanal.
			jsr	OPENCHN			;Datenkanal öffnen.

			ldx	STATUS			;Fehler?
			beq	:1			; => Nein, weiter...
			jsr	serDataClose		;Datenkanal schließen.
			ldx	#CANCEL_ERR		;Laufwerksfehler.
::1			rts

::comDBufChan		b "#0"
::comDBufEnd
::comDBufLen		= (:comDBufEnd - :comDBufChan)

;*** Datenkanal schließen.
:serDataClose		lda	#5			;Datenkanal schließen.
			jmp	CLOSE

;*** Befehlskanal schließen.
:serFComClose		lda	#15			;Befehlskanal schließen.
			jmp	CLOSE

;*** Floppy-Befehl mit variabler Länge an Laufwerk senden.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:serSendComVLen		sta	:51 +1			;Zeiger auf Floppy-Befehl sichern.
			stx	:51 +2
			sty	:52 +1

;			jsr	UNTALK			;Aufruf durch ":initDevLISTEN".

			jsr	initDevLISTEN		;Laufwerk auf Empfang schalten.
			bne	:53			;Fehler? => Ja, Abbruch...

			ldy	#$00
::51			lda	$ffff,y			;Bytes an Floppy-Laufwerk senden.
			jsr	CIOUT
			iny
::52			cpy	#$ff
			bcc	:51

			ldx	#NO_ERROR
::53			rts

;Reference: "Serial bus control codes"
;https://codebase64.org/doku.php?id=base:how_the_vic_64_serial_bus_works
;$20-$3E : LISTEN  , device number ($20 + device number #0-30)
;$3F     : UNLISTEN, all devices
;$40-$5E : TALK    , device number ($40 + device number #0-30)
;$5F     : UNTALK  , all devices
;$60-$6F : REOPEN  , channel ($60 + secondary address / channel #0-15)
;$E0-$EF : CLOSE   , channel ($E0 + secondary address / channel #0-15)
;$F0-$FF : OPEN    , channel ($F0 + secondary address / channel #0-15)

;*** Laufwerk auf Senden schalten.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:initDataTALK		lda	#5			;Datenkanal.
			b $2c
:initDevTALK		lda	#15			;Befehlskanal.
			sta	devChan

			jsr	UNTALK			;Laufwerk abschalten.

			jsr	:startTALK		;Laufwerk aktivieren.
			beq	:exit			;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startTALK		ClrB	STATUS			;Status-Byte löschen.

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	TALK			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	devChan			;REOPEN -> DO NOT CHANGE!!!
			ora	#%01100000 			;Der Befehlskanal ist hier bereits
							;durch ":serFComOpen" geöffnet!
			jsr	TKSA			;Laufwerk auf Senden schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exit			; => Nein, Ende...

::error			jsr	UNTALK			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exit			rts

;*** Laufwerk auf Empfang schalten.
;Rückgabe: Z-Flag = 1: OK
;          Z-Flag = 0: Fehler
:initDataLISTEN		lda	#5			;Datenkanal.
			b $2c
:initDevLISTEN		lda	#15			;Befehlskanal.
			sta	devChan

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	startLISTEN		;Laufwerk aktivieren.
			beq	exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

:startLISTEN		lda	#$60			;"REOPEN". -> DO NOT CHANGE!!!
							;Der Befehlskanal ist hier bereits
							;durch ":serFComOpen" geöffnet!
			b $2c
:closeLISTEN		lda	#$e0			;"CLOSE".
			sta	:ieccom +1

			ClrB	STATUS			;Status-Byte löschen.

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	devChan
::ieccom		ora	#$ff
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
:exitLISTEN		rts

;*** Laufwerkskanal.
:devChan		b $00

;*** Bytes über ser. Bus einlesen.
;    Übergabe:		AKKU/xReg , Zeiger auf Bytespeicher.
;			yReg      , Anzahl Bytes.
:serReadData		sta	r0L
			stx	r0H

			sty	r1L

			ldy	#0
			tya
::1			sta	(r0L),y
			iny
			cpy	r1L
			bne	:1

			jsr	initDevTALK
			bne	:err

::2			jsr	ACPTR

			ldy	#$00
			sta	(r0L),y

			inc	r0L
			bne	:3
			inc	r0H

::3			dec	r1L
			bne	:2

			jsr	UNTALK

			lda	#NO_ERROR
::err			tax
			rts

;*** Bytes über ser. Bus bis Zeilenende einlesen.
:serReadStatus		LoadW	r0,devDataBuf

			ldy	#0
			tya
::1			sta	(r0L),y
			iny
			cpy	#32
			bcc	:1

			jsr	initDevTALK
			bne	:err

			ldy	#0
::2			jsr	ACPTR
			sta	(r0L),y
			cmp	#13
			beq	:3
			iny
			cpy	#32
			bcc	:2

::3			jsr	UNTALK

			lda	#NO_ERROR
::err			tax
			rts

;*** Speicher für Laufwerksdaten.
:devDataBuf		s 32
