; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Source-Code zur Datei:
;    "COPYRIGHT CMD 89"
;Die Datei wird auf dem Boot-Laufwerk
;in der Startpartition erwartet.
;(Bei NativeMode im Hauptverzeichnis)
;
;Bei einem RESET oder Neustart wird die
;Datei via AutoLoad des HDDOS in das
;RAM der CMD-HD geladen.
;Das Programm stellt zusätzlichen Code
;für andere Programme für die CMD-HD
;wie "SCSI-Connect" zur Verfügung.
;
;SourceCode disassembliert/dokumentiert:
;2019/12/25 M.Kanet
;2020/02/16 Beschreibung aktualisiert
;

			o $8e00 -3
			n "COPYRIGHT CMD 89"
			f $01

;*** Hinweis:
;Die Struktur der AutoStart-Datei der
;CMD-HD entspricht dem Format der 1581:
;http://www.unusedino.de/ec64/technical/formats/d81.html
;
;Description of 1581 AutoBoot loader:
;The format for this auto-loader is
;fairly basic:
;It starts with a two-byte load
;address, a size byte, proramm data,
;and a checksum at the end.
;
;Bytes: 00-01: Load address lo/hi
;          02: Size SZ of program <256B
;     03+SZ-1: Program data
;       03+SZ: Checksum byte
;

;*** Datenbytes der AutoStart-Datei.
			w $8e00				;Ladeadresse.
			b $df				;Anzahl Bytes.

;*** Sprungtabelle.
:l8e00			jmp	$ff33
:l8e03			jmp	l8e19			;Controller-Reset.
:l8e06			jmp	l8e1c			;KonfigModusOn+Controller-Reset.
:l8e09			jmp	l8e1f			;KonfigModusOn.
:l8e0c			jmp	l8e22			;KonfigModusOff+Controller-Reset.
:l8e0f			jmp	l8e38			;Einsprung SCSI-Connect.
							;AKKU enthält neue SCSI-ID.
:l8e12			jmp	l8e36

;*** Kennung für Boot-ROM V2.80.
:BOOTROMV		b "2.80"
:ROMVER			= $feb4

;*** Hauptprogramm.
:l8e19			lda	#$00			;Controller-Reset.
			b $2c
:l8e1c			lda	#$08			;KonfigModusOn+Controller-Reset.
			b $2c
:l8e1f			lda	#$06			;KonfigModusOn.
			b $2c
:l8e22			lda	#$14			;KonfigModusOff+Controller-Reset.
			pha

			lda	#$00			;Fehler-Code löschen.
			sta	$8eff

			jsr	initReg
			jsr	ckBootROM

			pla
			clc
			php
			jmp	$deed

:l8e36			sec
			b $24
:l8e38			clc				;KonfigModus/SCSI-ID wechseln.
			php
			sta	devID +1
			lda	$90e1			;CMD-HD Standard-Adresse.
			sta	devHD +1

			lda	#$00			;Interner Fehlerspeicher.
			sta	$8eff

			jsr	initReg
			jsr	ckBootROM
			jsr	$d1ba
			jsr	setID			;ID setzen, Hardware-Block lesen.

			lda	#$01			;Fehler-Code $01.
			bcs	errorSTOP

			jsr	update			;Hardware-Tabelle aktualisieren.

			jsr	$dcb6

			lda	#$02			;Fehler-Code $02.
			bcs	errorSTOP

			plp
			bcc	:1

			ldx	#$00
			jsr	$dd4e

			lda	#$03			;Fehler-Code $03.
			bcs	errorSTOP

			jsr	update			;Hardware-Tabelle aktualisieren.

			jsr	$d264
			jmp	$ff06

::1			jmp	$d09f

:initReg		sei
			lda	#$92
			sta	$8803
			lda	#$e3
			sta	$8802
			rts

:ckBootROM		ldx	#$04
::1			lda	BOOTROMV -1,x
			cmp	ROMVER   -1,x
			bne	:2
			dex
			bne	:1
::2			bne	errorROM
			rts

:errorROM		lda	#$04			;Fehler-Code $04.
:errorSTOP		sta	$8eff			;Fehler-Code speichern.

			lda	$8f00			;Front-Panel-LED-Anzeige.
			and	#%00110000

			ldx	#$00
::1			sta	$8f00
			ldy	#$40
::2			dex
			bne	:2
			dey
			bne	:2
			eor	#%11001111
			jmp	:1

:setID			lda	#$01
			sta	$30aa
:devID			lda	#$00			;SCSI-ID.
			jmp	$d10e

;*** Hardware-tabelle aktualisieren.
;Ab $9000 liegt der Hardware-Block im
;Speicher der CMD-HD.
;Nachdem ein neues Laufwerk aktiviert
;wurde, wird dieser vom neuen Laufwerk
;eingelesen.
;Die Adresse der CMD-HD muss hier dann
;auf den Original-Wert gesetzt werden.
:update			lda	$8f00			;Front-Panel-LED-Anzeige.
			ora	#%00100000
			sta	$8f00

:devHD			lda	#$00
			sta	$90e1			;CMD-HD Standard-Adresse.
			sta	$90e4			;Adresse / SWAP-Status.

			lda	devID +1
			asl
			asl
			asl
			asl
			sta	$9000			;SCSI-ID, LUN(low-nibble)=0.

			lda	$8f00			;Front-Panel-LED-Anzeige.
			and	#%11011111
			sta	$8f00
			rts

			b $9e				;Prüfbyte.
