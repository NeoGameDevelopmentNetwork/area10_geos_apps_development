﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "RBOOT128.BOOT"
			t "G3_SymMacExt"
			t "G3_V.Cl.128.Boot"

			o BASE_GEOSBOOT -2		;BASIC-Start beachten!
			p InitBootProc

			z $40
			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "ReBoot-Programm / System"
			h "GEOS-MegaPatch 128..."
endif

if Sprache = Englisch
			h "ReBoot-Programm / System"
			h "GEOS-MegaPatch 128..."
endif

;*** Füllbytes.
:L_KernelData		w BASE_GEOSBOOT			;DummyBytes, da Programm über
							;BASIC-LOAD geladen wird!!!

;*** Einsprung aus GEOS-Startprogramm.
:InitBootProc		jmp	MainInit

;*** Boot-Informationen einbinden.
			t "-G3_BootVar"

; Dieses Programm befindet sich sowohl in Bank 0 alsauch in Bank 1
; Beachte geänderte Variablen beim Bankwechsel !
;*** Hardware erkennen.
:MainInit		sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
			ldx	#$ff			;Stack-Pointer löschen.
			txs

			LoadB	RAM_Conf_Reg,$07	;Common Area $0000 - $4000 aktiv
			lda	#%00001110		;ROM ab $c000 aktiv + IO
			sta	MMU

			jsr	PrintBootInfo

			ldx	#$ff			;SuperCPU verügbar ?
			lda	$d0bc
			bpl	:51
			inx
::51			stx	Device_SCPU

			ldx	#$ff			;RAMLink verügbar ?
			lda	$e0a9
			cmp	#$78
			beq	:52
			inx
::52			stx	Device_RL

			lda	#$7e
			sta	MMU

			lda	BOOT_RAM_SIZE
			sta	ramExpSize
			beq	NoRAMfound

			lda	BOOT_RAM_BANK +0
			sta	RamBankFirst  +0
			lda	BOOT_RAM_BANK +1
			sta	RamBankFirst  +1

			lda	#%00001110		;ROM ab $c000 aktiv + IO
			sta	MMU

;--- RAMCard.
			lda	BOOT_RAM_TYPE		;Speichererweiterung definiert ?
			beq	NoRAMfound		; => Nein, Abbruch...
			cmp	#RAM_SCPU		;RAMCard für RBoot verwenden ?
			bne	:54			; => Nein, weiter...

			jsr	sysDetectSCPU		;Speichererweiterung testen.
			txa				;RAMCard installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...

			sta	$d07e

			lda	#$7e
			sta	MMU

			lda	RamBankFirst +1		;SuperCPU-Variablen aktualisieren.
			clc				;Neues Ende des belegten RAMs nur
			adc	ramExpSize		;dann setzen, wenn Ende unterhalb
			cmp	$d27d			;GEOS-DACC liegt. Passiert nur bei
			bcc	:53			;einem Warmstart des Computers.

			ldx	#$00
			stx	$d27c
			sta	$d27d
::53			sta	$d07f
			jmp	ReBoot_SCPU		;ReBoot für SCPU/RAMCard.

;--- RAMLink.
::54			cmp	#RAM_RL			;RAMLink für RBoot verwenden ?
			bne	:55			; => Nein, weiter...

			jsr	sysDetectRLNK		;Speichererweiterung testen.
			txa				;RAMLink installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...
			jmp	ReBoot_RL		;ReBoot für SCPU/RAMCard.

;--- REU.
::55			cmp	#RAM_REU		;REU für RBoot verwenden ?
			bne	:56			; => Nein, weiter...

			jsr	sysDetectCREU		;Speichererweiterung testen.
			txa				;REU installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...
			jmp	ReBoot_REU		;ReBoot für SCPU/RAMCard.

;--- BBGRAM.
::56			cmp	#RAM_BBG		;BBGRAM für RBoot verwenden ?
			bne	NoRAMfound		; => Nein, Abbruch...

			jsr	sysDetectGRAM		;Speichererweiterung testen.
			txa				;BBGRAM installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...
			jmp	ReBoot_BBG		;ReBoot für SCPU/RAMCard.

;*** Keine Speichererweiterung, Ende...
:NoRAMfound		lda	#$00			;Standard-RAM-Bereiche einblenden.
			sta	MMU
			cli

			jsr	Strg_RamExp_Exit	;Installationsmeldung ausgeben.
			jmp	ROM_BASIC_READY		;Zurück zum C64-BASIC.

;*** ReBoot-Routine für RAMLink.
:ReBoot_RL		lda	BOOT_RAM_PART		;BOOT-Partition setzen und
			sta	r3H			;Partitionsdaten einlesen.
			LoadB	r15L,%00001110		;MMU-Wert für RamLink Transfer
			jsr	GetRLPartEntry

			lda	dirEntryBuf +0
			cmp	#$07			;DACC-Partition ?
			bne	:51			; => Nein, Fehler...

			lda	dirEntryBuf +21		;Stimmt Startadresse ?
			cmp	BOOT_RAM_BANK +0
			bne	:51
			lda	dirEntryBuf +20
			cmp	BOOT_RAM_BANK +1
			bne	:51			; => Nein, Fehler...

			lda	#$7e
			sta	MMU
			LoadB	RAM_Conf_Reg,$00
			jsr	SetArea1
			jsr	GetRAM_RL
			jsr	SetArea2
			jsr	GetRAM_RL
			jmp	$c000			;ReBoot initialisieren.
::51			jmp	NoRAMfound

;*** FetchRAM-Routine für ReBoot.
:GetRAM_RL		lda	MMU			;Konfiguration sichern
			pha
			LoadB	MMU,%00001110		;Ram1 bis $bfff + IO + Kernal
							;I/O-Bereich und Kernal für
							;RAMLink-Transfer aktivieren.
			lda	RAM_Conf_Reg		;Konfiguration sichern
			pha
			and	#%11110000
			ora	#%00000100		;Common Area $0000 bis $0400
			sta	RAM_Conf_Reg

			jsr	EN_SET_REC		;RL-Hardware aktivieren.

			lda	r0L
			sta	$de02
			lda	r0H
			sta	$de03

			lda	r1L
			sta	$de04
			lda	r1H
			clc
			adc	RamBankFirst +0
			sta	$de05
			lda	r3L
			adc	RamBankFirst +1
			sta	$de06

			lda	r2L
			sta	$de07
			lda	r2H
			sta	$de08

			lda	#$00
			sta	    $de09
			sta	    $de0a

			lda	#$91
			sta	    $de01

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			PopB	RAM_Conf_Reg
			PopB	MMU
			rts

;*** ReBoot-Routine für RAMCard.
:ReBoot_SCPU		lda	#$00
			sta	RAM_Conf_Reg
			jsr	SetArea1
			jsr	GetRAM_SCPU
			jsr	SetArea2
			jsr	GetRAM_SCPU
			jmp	$c000			;ReBoot initialisieren.

;*** FetchRAM-Routine für ReBoot.
:GetRAM_SCPU		ldy	#%10010001		;JobCode "FetchRAM".
			jmp	DoRAMOp_SRAM

;*** ReBoot-Routine für REU.
:ReBoot_REU		lda	#$7e
			sta	MMU
			lda	#$00
			sta	RAM_Conf_Reg
			jsr	SetArea1
			jsr	GetRAM_REU
			jsr	SetArea2
			jsr	GetRAM_REU
			jmp	$c000			;ReBoot initialisieren.

;*** FetchRAM-Routine für ReBoot.
:GetRAM_REU		lda	CLKRATE
			pha
			lda	#$00
			sta	CLKRATE
			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_CREU
			pla
			sta	CLKRATE
			rts

;*** Definierenn der GeoRAM-Register.
:GRAM_PAGE_DATA		= $de00
:GRAM_PAGE_SLCT		= $dffe
:GRAM_BANK_SLCT		= $dfff

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet:
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00

;*** ReBoot-Routine für BBGRAM.
:ReBoot_BBG		lda	#$7e
			sta	MMU
			lda	#$00
			sta	RAM_Conf_Reg

			php
			sei

			jsr	GRamGetBankSize

			plp				;IRQ-Status zurücksetzen.

			txa
			bne	:51

			jsr	SetArea1
			jsr	GetRAM_BBG
			jsr	SetArea2
			jsr	GetRAM_BBG
			jmp	$c000			;ReBoot initialisieren.
::51			jmp	NoRAMfound

;*** FetchRAM-BBG-Routine für ReBoot.
:GetRAM_BBG		lda	GRAM_BANK_SIZE
			ldy	#%10010001		;JobCode "FetchRAM".
			jmp	DoRAMOp_GRAM

;*** Zeiger auf RAM-Speicherbereiche.
:SetArea1		LoadW	r0 ,$9d80
			LoadW	r1 ,$b900
			LoadW	r2 ,$0280
			LoadB	r3L,$00
			LoadB	RAM_Conf_Reg,$07
			lda	BOOT_RAM_BANK +1
			ldx	#$00
			stx	RAM_Conf_Reg
			sta	r3H
			rts

:SetArea2		LoadW	r0 ,$c000
			LoadW	r1 ,$bc40
			LoadW	r2 ,$0100
			LoadB	r3L,$00
			LoadB	RAM_Conf_Reg,$07
			lda	BOOT_RAM_BANK +1
			ldx	#$00
			stx	RAM_Conf_Reg
			sta	r3H
			rts

;*** Texte ausgeben.
:Strg_Titel		lda	#$00			;BootText00
			b $2c
:Strg_Autor		rts
			b NULL
			b $2c
:Strg_RamExp_Exit	lda	#$01			;BootText20
			asl
			tax
			lda	StrgVecTab1 +0,x	;Zeiger auf Text einlesen.
			ldy	StrgVecTab1 +1,x

:Strg_CurText		php				;BASIC-ROM aktivieren.
			sei
			sta	r0L
			sty	r0H

			PushB	MMU
			lda	#$00			;RAM bis $3fff sonst ROM und IO
			sta	MMU

::loop			ldy	#0
			lda	(r0),y
			beq	:end
			jsr	$ffd2			;Text ausgeben.
			inc	r0L
			bne	:loop
			inc	r0H
			jmp	:loop

::end			pla
			sta	MMU
			plp
			rts

;*** Zeiger auf Textausgabe-Strings.
:StrgVecTab1		w BootText00
			w BootText20

;*** Texte für Start-Sequenz.
if Sprache = Deutsch
:BootText20		b CR,	"RBOOT WURDE NOCH NICHT KONFIGURIERT"
			b CR,	"ODER DIE SPEICHERERWEITERUNG WURDE"
			b CR,	"NICHT ERKANNT. START ABGEBROCHEN..."
			b CR,CR,NULL
endif

if Sprache = Englisch
:BootText20		b CR,	"RBOOT WAS NOT CONFIGURED YET OR"
			b CR,	"RAM-EXPANSION NOT DETECTED."
			b CR,	"GEOS-START CANCELLED..."
			b CR,CR,NULL
endif

;******************************************************************************
;*** Zusatzprogramme.
;******************************************************************************
			t "-R3_DetectRLNK"
			t "-R3_DetectSRAM"
			t "-R3_DetectCREU"
			t "-R3_DetectGRAM"
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"
			t "-R3_DoRAMOpCREU"
			t "-R3_DoRAMOpGRAM"
			t "-R3_GetSBnkGRAM"
			t "-G3_GetRLPEntry"
			t "-G3_SysInfo"
;******************************************************************************
