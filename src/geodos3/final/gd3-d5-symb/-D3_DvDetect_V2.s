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

			jsr	openFComChan		;Befehlskanal öffnen.

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
			sta	sysDevInfo -8,x
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
			sta	sysDevInfo -8,x
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
			lda	sysDevInfo   -8,x	;SD2IEC-Laufwerk ?
			beq	:noDevice		; => Nein, Laufwek nicht erkannt.

			ldy	#DrvNative		;SD2IEC-Native als Vorgabe.
			b $2c

;--- Kein Laufwerk erkannt.
::noDevice		ldy	#$00			;Kein Laufwerk.
::setDevData		ldx	curDevice
			tya
			ora	sysDevInfo -8,x		;Ggf. mit SD2IEC-Flag verknüpfen.
			sta	sysDevInfo -8,x		;Laufwerksemulation speichern.

::close			jsr	closeFComChan		;Befehlskanal schließen.

			ldx	#NO_ERROR		;Kein Fehler.
::exit			rts

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
			jsr	xSendComVLen		;Befehl senden.
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
;Da aber ":openFComChan" evtl. auch in
;anderen Routinen Verwendung findet,
;wird hier "I0:" manuell gesendet.
:testCMD		lda	#< :FCom_I0		;Disk initialisieren.
			ldx	#> :FCom_I0
			ldy	#:FCom_I0_len
			jsr	xSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.

			lda	#$00			;Systempartition.
			jsr	cmdGetPartData		;Partitionsdaten einlesen.

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
			jsr	DEZ2ASCII
			stx	:FCom_U1 + 7
			sta	:FCom_U1 + 8

			lda	:sekData +1,y
			jsr	DEZ2ASCII
			stx	:FCom_U1 +10
			sta	:FCom_U1 +11

			lda	:sekData +2,y
			pha

			jsr	openDataChan		;Datenkanal öffnen.
			lda	#< :FCom_U1
			ldx	#> :FCom_U1
			ldy	#:FCom_U1_len
			jsr	xSendComVLen		;Befehl senden.
			jsr	UNLSN			;Laufwerk abschalten.
			jsr	closeDataChan		;Datenkanal schließen.

			jsr	getStatusBytes		;Laufwerksstatus einlesen.

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
:DEZ2ASCII		ldx	#"0"
::1			cmp	#10			;Restwert < 10?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:1			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::2			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
			rts
