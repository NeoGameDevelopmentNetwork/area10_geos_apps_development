; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "s.GDC.Config.ext"

;--- Speicherverwaltung.
.BankCode_GEOS		= %10000000
.BankCode_Disk		= %01000000
.BankCode_Task		= %00100000
.BankCode_Spool		= %00010000
.BankCode_Block		= %00001000
.BankCode_Free		= %00000000

;--- Bankbelegung.
.BankType_GEOS		= %11000000
.BankType_Disk		= %10000000
.BankType_Block		= %01000000
endif

;*** GEOS-Header.
			n "obj.CFG.DACC"
			f DATA

			o BASE_GCFG_BOOT

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	BOOT_GDC_DACC
;******************************************************************************

;*** AutoBoot: GD.CONF.RAM.
:BOOT_GDC_DACC		lda	ramExpSize
			cmp	#$08 +1			;Mehr als 512K GEOS-DACC ?
			bcs	:1			; => Ja, weiter...

			lda	#$00			;Nicht genügend Speicher, das
			sta	BootHelpSysMode		;Hilfesystem abschalten.

::1			lda	#$00
			bit	BootHelpSysMode		;Hilfe installieren ?
			bpl	:2			; => Nein, weiter...
			clc				;Speicherbank für Hilfesystem
			adc	#$01			;reservieren.
::2			clc				;Für Anwendungen reservierter
			adc	BootBankAppl		;Speicher addieren.

			cmp	#$00			;Speicher reservieren?
			beq	:4			; => Nein, weiter...
			sta	r0L			;Anzahl Speicherbänke.

			lda	ramExpSize		;Speichergröße einlesen.
			sec				;GDOS-Speicher für SYSTEM/DATA ist
			sbc	#$02			;bereits reserviert.

::3			sec
			sbc	#$01			;Gesamter Speicher belegt ?
			beq	:4			; => Ja, Abbruch...
			pha
			ldx	#%11000000
			jsr	AllocateBank		;64K-Speicherbank reservieren.
			pla
			cpx	#NO_ERROR		;Bank reserviert?
			bne	:3a			; => Nein, Sonderbehandlung...

			dec	r0L			;Alle Bänke reserviert ?
			bne	:3			; => Nein, weiter...
			beq	:4			; => Ja, reserviertes RAM belegen.

::3a			lda	BootBankAppl		;Max.reservierten Speicher
			sec				;korrigieren.
			sbc	r0L
			cmp	#4			;Weniger als 4 Bänke reserviert?
			bcs	:3b			; => Nein, weiter...
			lda	#4			;GeoDesk erfordert 256Kb RAM!
::3b			sta	BootBankAppl		;Reservierten Speicher setzen.

::4			ldx	#$00			;Speicherbänke in GEOS-RAM
::5			txa				;als "Reserviert" markieren.
			pha

			lda	BootBankBlocked,x	;Aktuelle Bank reserviert ?
			beq	:6			; => Nein, weiter...
			txa
			ldx	#BankType_Block
			jsr	AllocateBank		;Speicherbank reservieren.

::6			pla
			tax
			inx				;Zeiger auf nächste Speicherbank.
			cpx	ramExpSize		;Alle Bänke geprüft ?
			bne	:5			; => Nein, weiter...

			ldx	#NO_ERROR
			rts

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_DDRV_INFO
;******************************************************************************
