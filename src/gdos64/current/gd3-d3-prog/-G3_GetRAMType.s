; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf RAMCard testen.
:Check_RAMCard		jsr	Strg_RamExp_SCPU	;Installationsmeldung ausgeben.
			jsr	DetectSCPU		;Installierte SuperCPU erkennen.
			txa				;SuperCPU verfügbar?
			bne	:51			; => Nein, Ende...

			jsr	sysGetBCntSRAM		;Anzahl Speicherbänke ermitteln.
			lda	SRAM_BANK_COUNT		;Speicher verfügbar?
			beq	:51			; => Nein, Ende...

;--- SuperCPU mit RAMCard gefunden.
			ldy	SRAM_FREE_START		;Start des freien Speichers in der
			sty	RAMBANK_SCPU+1		;RAMCard zwischenspeichern.

			ldy	SRAM_BANK_COUNT
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4MByte ?
			bcc	:50			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::50			sta	RAMSIZE_SCPU

			ldx	#NO_ERROR		;RAMCard erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine RAMCard erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_SCPU		;Kennung für RAMCard speichern.
			sta	RAMUNIT_SCPU

::52			rts

;*** Auf C=REU/CMD-REU testen.
:Check_REU		jsr	Strg_RamExp_REU		;Installationsmeldung ausgeben.
			jsr	DetectCREU		;Installierte C=REU erkennen.
			txa				;C=REU verfügbar?
			bne	:51			; => Nein, Ende...

			jsr	sysGetBCntCREU		;Anzahl Speicherbänke ermitteln.
			lda	CREU_BANK_COUNT		;Speicher verfügbar?
			beq	:51			; => Nein, Ende...

;--- C=REU gefunden.
			ldy	CREU_BANK_COUNT
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4MByte ?
			bcc	:50			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::50			sta	RAMSIZE_REU

			ldx	#NO_ERROR		;C=REU erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine C=REU erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_REU		;Kennung für C=REU speichern.
			sta	RAMUNIT_REU

::52			rts

;*** Auf GeoRAM/BBGRAM testen.
:Check_BBG		jsr	Strg_RamExp_BBG		;Installationsmeldung ausgeben.
			jsr	DetectGRAM		;Installierte GeoRAM erkennen.
			txa				;GeoRAM verfügbar?
			bne	:51			; => Nein, Ende...

			jsr	sysGetBCntGRAM		;Anzahl Speicherbänke ermitteln.
			lda	GRAM_BANK_VIRT64	;Speicher verfügbar?
			beq	:51			; => Nein, Ende...

;--- GeoRAM/BBGRAM gefunden.
			lda	GRAM_BANK_SIZE
			sta	Code3a + (DvRAM_GRAM_BSIZE - DvRAM_GRAM_START) +1
			ldx	#%11111110		;Bankgröße 64Kb: Page #254, Bank #0.
			ldy	#%00000000
			cmp	#$40
			beq	:49
			ldx	#%01111110		;Bankgröße 32Kb: Page #126, Bank #1.
			ldy	#%00000001
			cmp	#$20
			beq	:49
			ldx	#%00111110		;Bankgröße 16Kb: Page  #62, Bank #3.
			ldy	#%00000011
::49			stx	Code3a + (DvRAM_GRAM_SYSP - DvRAM_GRAM_START) +1
			sty	Code3a + (DvRAM_GRAM_SYSB - DvRAM_GRAM_START) +1

			ldy	GRAM_BANK_VIRT64
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4MByte ?
			bcc	:50			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::50			sta	RAMSIZE_BBG

			ldx	#NO_ERROR		;GeoRAM erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine GeoRAM erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_BBG		;Kennung für GeoRAM speichern.
			sta	RAMUNIT_BBG

::52			rts

;*** Auf RAMLink testen.
:Check_RAMLink		jsr	Strg_RamExp_RL		;Installationsmeldung ausgeben.
			jsr	DetectRLNK		;Installierte RAMLink erkennen.
			txa				;RAMLink verfügbar?
			bne	:51			; => Nein, Ende...

			jsr	GetSizeRAM_RL		;RAMLink-Speicher ermitteln.

			cpy	#$00			;Speicher in RAMLink installiert?
			beq	:51			; => Nein, weiter...

;--- RAMLink gefunden.
			ldx	#NO_ERROR		;RAMLink erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine RAMLink erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_RL			;Kennung für RAMLink speichern.
			sta	RAMUNIT_RL

::52			rts

;*** Größe des RAMLink-Speichers ermitteln.
:GetSizeRAM_RL		ldx	#$00
			stx	r3L
			inx				;Partitions-Nr. auf #1 setzen.
			stx	r3H

::51			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

			lda	dirEntryBuf +0
			cmp	#$07			;DACC-Partition?
			bne	:53			; => Nein, weiter...

			lda	dirEntryBuf +28		;Partitionsgröße einlesen.
			cmp	#$03			;Mind. 3x64KByte ?
			bcc	:53			; => Nein, weiter...
			sta	RAMSIZE_RL

			ldx	dirEntryBuf +21		;Startadresse der Partition
			stx	RAMBANK_RL  +0		;einlesen.
			ldx	dirEntryBuf +20
			stx	RAMBANK_RL  +1

			lda	r3H			;Partitionsnummer merken.
			sta	RAMPART_RL

			inc	r3L			;DACC-Partitionszähler +1.
::53			inc	r3H			;Zähler auf nächste Partition.
			CmpBI	r3H,32			;Ende erreicht (max. 32Part.)?
			bcc	:51			; => Nein, weiter...

			dec	r3L			;Nur eine DACC-Partition?
			beq	:54			; => Ja, Ende...
			lda	#$ff			;Auswahlmenü anzeigen.
			tay
			sty	RAMPART_RL
			bne	:56

::54			ldy	RAMSIZE_RL
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4MByte ?
			bcc	:55			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::55			sta	RAMSIZE_RL
::56			rts

;*** RAMLink-Startpartition suchen.
:FindRL_Part		lda	Boot_Type
			and	#%11110000		;CMD-Geräte-Daten isolieren.
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			bne	:exit			; => Nein, Ende...

			jsr	Strg_DvInit_RL		;Installationsmeldung ausgeben.

			lda	curDevice		;Geräteadresse der RAMLink
			sta	RL_BootAddr		;zwischenspeichern.

			php
			sei

			lda	CPU_DATA
			pha
			lda	#KRNL_BAS_IO_IN		;Kernal-ROM + I(O einblenden.
			sta	CPU_DATA

			jsr	GetPartInfo		;Daten der aktiven Partition
							;einlesen.
			pla
			sta	CPU_DATA
			plp

;			lda	GP_Data   +21		;RAM-Startadresse speichern.
;			sta	Boot_Part + 0		;HighByte reicht, da der MP3-RL-
			lda	GP_Data   +20		;Treiber die Adresse selbst
			sta	Boot_Part + 1		;ermittelt!

			ldx	GP_Data   + 2		;Partitions-Nr. ausgeben.
			stx	Boot_Part + 0
			lda	#$00
			jsr	ROM_OUT_NUMERIC

::exit			lda	#CR			;Leerzeile ausgeben.
			jmp	BSOUT

;*** Daten an Floppy senden.
:GetPartInfo		lda	#$00
			sta	STATUS			;Status löschen.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			lda	RL_BootAddr
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff
			jsr	SECOND			;Sekundär-Adr. nach LISTEN senden.

			bit	STATUS			;Laufwerk vorhanden ?
			bmi	:52			;Nein, Abbruch...

			ldy	#$00
::51			lda	GP_Befehl,y		;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			cpy	#$05
			bne	:51

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			jmp	ReadPartInfo

::52			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Daten von Floppy empfangen.
:ReadPartInfo		lda	#$00
			sta	STATUS			;Status löschen.

			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.

			lda	RL_BootAddr
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			lda	#$ff
			jsr	TKSA			;Sekundär-Adresse nach TALK senden.

			bit	STATUS			;Laufwerk vorhanden ?
			bmi	:52			;Nein, Abbruch...

			ldy	#$00
::51			jsr	ACPTR			;Byte einlesen und in
			sta	GP_Data,y		;Speicher schreiben.
			iny
			cpy	#31
			bne	:51

			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts
::52			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** RAM-Erkennung.
:RAMUNIT_COUNT		b $00
:RAMUNIT		b $00

;******************************************************************************
;*** Start der RAMUNIT Daten.
;******************************************************************************
:RAMUNIT_DATA

:RAMUNIT_BBG		b $00				;$00 = BBG-RAM nicht verfügbar.
:RAMSIZE_BBG		b $00				;DACC-Größe.
:RAMBANK_BBG		w $0000				;Dummy-Bytes.
:RAMPART_BBG		b $00				;Dummy-Byte.
:RAMNAME_BBG		w BootText14

:RAMUNIT_REU		b $00				;$00 = C=REU nicht verfügbar.
:RAMSIZE_REU		b $00				;DACC-Größe.
:RAMBANK_REU		w $0000				;Dummy-Bytes.
:RAMPART_REU		b $00				;Dummy-Byte.
:RAMNAME_REU		w BootText13

:RAMUNIT_RL		b $00				;$00 = RAMLink nicht verfügbar.
:RAMSIZE_RL		b $00				;DACC-Größe.
:RAMBANK_RL		w $0000				;DACC-Startadresse.
:RAMPART_RL		b $00				;DACC-Partition.
:RAMNAME_RL		w BootText12

:RAMUNIT_SCPU		b $00				;$00 = RAMCARD nicht verfügbar.
:RAMSIZE_SCPU		b $00				;DACC-Größe.
:RAMBANK_SCPU		w $0000				;DACC-Startadresse.
:RAMPART_SCPU		b $00				;Dummy-Byte.
:RAMNAME_SCPU		w BootText11
;******************************************************************************

:RAM_RL_MENU_TXT	b " -MENU- )",0
