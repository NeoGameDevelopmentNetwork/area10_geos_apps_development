; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "SymbTab_GRAM"
			t "SymbTab_GRFX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- GD.INI-Version.
			t "opt.INI.Version"
endif

;*** GEOS-Header.
			n "GD.RBOOT.SYS"
			c "GDOSBOOT    V3.0"
			t "opt.Author"
;--- Hinweis:
;Startprogramme können von DESKTOP 2.x
;nicht kopiert werden.
;			f SYSTEM_BOOT ;Typ Startprogramm.
			f SYSTEM      ;Typ Systemdatei.
			z $80 ;nur GEOS64

			o BASE_GEOSBOOT -2
			p InitBootProc

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "RBOOT-System für"
			h "GDOS64..."
endif
if LANG = LANG_EN
			h "RBOOT system for"
			h "GDOS64..."
endif

;*** Ladeadresse für BASIC-Programm.
:L_KernelData		w BASE_GEOSBOOT			;Dummy-Bytes da Programm über
							;BASIC-Routine geladen wird!
;*** Einsprung aus GEOS-Startprogramm.
:InitBootProc		jmp	MainInit

;*** Angaben zur Speichererweiterung.
;Wird aus GD.INI eingelesen.
;BOOT_RAM_TYPE: $00 = RAM nicht gewählt.
;               $10 = RAMCard gewählt.
;               $20 = BBGRAM  gewählt.
;               $40 = C=REU   gewählt.
;               $80 = RAMLink gewählt.
;               $FF = DACC neu wählen.
:BOOT_RAM_TYPE		b $00    ;DACC-Speicher: Typ.
:BOOT_RAM_SIZE		b $00    ;DACC-Speicher: Größe.
:BOOT_RAM_BANK		w $0000  ;Adresse erste Speicherbank RAMLink/RAMCard.
:BOOT_RAM_PART		b $00    ;Nicht verwendet.

;*** Auswahl einer RAM-Erweiterung.
:MainInit		jsr	LoadConfigDACC		;Speichererweiterung einlesen.
			txa				;Fehler?
			beq	:init			; => Nein, weiter...
			jmp	NoRAMfound		;GD.INI nicht lesbar, => Kein RAM.

::init			sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
			ldx	#$ff			;Stack-Pointer löschen.
			txs

			jsr	PrintBootInfo

			jsr	CheckSCPU		;SuperCPU erkennen.
			jsr	CheckRLNK		;RAMLink erkennen.

			lda	#KRNL_BAS_IO_IN		;Kernal-ROM + I/O einblenden.
			sta	CPU_DATA

			lda	BOOT_RAM_SIZE		;RAM-Größe konfiguriert?
			beq	NoRAMfound		; => Nein, Abbruch...
			sta	ramExpSize		;Größe GEOS-DACC speichern.

			lda	BOOT_RAM_BANK +0
			sta	RamBankFirst  +0
			lda	BOOT_RAM_BANK +1
			sta	RamBankFirst  +1

;--- RAMCard.
::test_SCPU		lda	BOOT_RAM_TYPE		;Speichererweiterung definiert ?
			beq	NoRAMfound		; => Nein, Abbruch...
			cmp	#$ff			;DACC neu wählen?
			beq	NoRAMfound		; => Ja, Abbruch...
			cmp	#RAM_SCPU		;RAMCard für RBoot verwenden ?
			bne	:test_RLNK		; => Nein, weiter...

			jsr	DetectSCPU		;Speichererweiterung testen.
			txa				;RAMCard installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...

			sta	SCPU_HW_EN
			lda	RamBankFirst +1		;SuperCPU-Variablen aktualisieren.
			clc				;Neues Ende des belegten RAMs nur
			adc	ramExpSize		;dann setzen, wenn Ende unterhalb
			cmp	SRAM_FIRST_BANK		;GEOS-DACC liegt. Passiert nur bei
			bcc	:53			;einem Warmstart des Computers.

			ldx	#$00
			stx	SRAM_FIRST_PAGE
			sta	SRAM_FIRST_BANK

::53			sta	SCPU_HW_DIS

			jmp	ReBoot_SCPU		;ReBoot für SCPU/RAMCard.

;--- RAMLink.
::test_RLNK		cmp	#RAM_RL			;RAMLink für RBoot verwenden ?
			bne	:test_CREU		; => Nein, weiter...

			jsr	DetectRLNK		;Speichererweiterung testen.
			txa				;RAMLink installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...
			jmp	ReBoot_RL		;ReBoot für SCPU/RAMCard.

;--- REU.
::test_CREU		cmp	#RAM_REU		;REU für RBoot verwenden ?
			bne	:test_GRAM		; => Nein, weiter...

			jsr	DetectCREU		;Speichererweiterung testen.
			txa				;REU installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...
			jmp	ReBoot_REU		;ReBoot für SCPU/RAMCard.

;--- BBGRAM.
::test_GRAM		cmp	#RAM_BBG		;BBGRAM für RBoot verwenden ?
			bne	NoRAMfound		; => Nein, Abbruch...

			jsr	DetectGRAM		;Speichererweiterung testen.
			txa				;BBGRAM installiert ?
			bne	NoRAMfound		; => Nein, Abbruch...
			jmp	ReBoot_BBG		;ReBoot für SCPU/RAMCard.

;*** Keine Speichererweiterung, Ende...
:NoRAMfound		lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA
			cli

			jsr	Strg_RamExp_Exit	;Installationsmeldung ausgeben.
			jmp	ROM_BASIC_READY		;Zurück zum C64-BASIC.

;*** ReBoot-Routine für RAMLink.
:ReBoot_RL		lda	BOOT_RAM_PART		;BOOT-Partition setzen und
			sta	r3H			;Partitionsdaten einlesen.
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

			jsr	SetArea1
			jsr	GetRAM_RL
			jsr	SetArea2
			jsr	GetRAM_RL
			jmp	SystemReBoot		;ReBoot initialisieren.
::51			jmp	NoRAMfound

;*** FetchRAM-Routine für ReBoot.
:GetRAM_RL		jsr	EN_SET_REC		;RL-Hardware aktivieren.

			lda	r0L			;Computer Address Pointer.
			sta	EXP_BASE2 + 2
			lda	r0H
			sta	EXP_BASE2 + 3

			lda	r1L			;RAMLink System Address Pointer.
			sta	EXP_BASE2 + 4
			lda	r1H
			clc				;Start-Adresse der Partition
			adc	BOOT_RAM_BANK +0	;zur RAMCard-Adresse addieren.
			sta	EXP_BASE2 + 5
			lda	r3L
			adc	BOOT_RAM_BANK +1
			sta	EXP_BASE2 + 6

			lda	r2L			;Transfer-Length.
			sta	EXP_BASE2 + 7
			lda	r2H
			sta	EXP_BASE2 + 8

			lda	#$00
;			sta	EXP_BASE2 + 9		;Not used.
			sta	EXP_BASE2 +10		;Address Control.

			lda	#$91			;Job-Code.
			sta	EXP_BASE2 + 1

			jsr	EXEC_REC_REU		;Job ausführen und
			jmp	RL_HW_DIS2		;RL-Hardware abschalten.

;*** ReBoot-Routine für RAMCard.
:ReBoot_SCPU		jsr	SetArea1
			jsr	GetRAM_SCPU
			jsr	SetArea2
			jsr	GetRAM_SCPU
			jmp	SystemReBoot		;ReBoot initialisieren.

;*** FetchRAM-Routine für ReBoot.
:GetRAM_SCPU		ldy	#jobFetch		;JobCode "FetchRAM".
			lda	BOOT_RAM_BANK +1	; -> RamBankFirst +1
			jmp	DoRAMOp_SRAM		;Job ausführen.

;*** ReBoot-Routine für REU.
:ReBoot_REU		jsr	SetArea1
			jsr	GetRAM_REU
			jsr	SetArea2
			jsr	GetRAM_REU
			jmp	SystemReBoot		;ReBoot initialisieren.

;*** FetchRAM-Routine für ReBoot.
:GetRAM_REU		ldy	#jobFetch		;JobCode "FetchRAM".
			jmp	DoRAMOp_CREU

;*** Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;--- Ergänzung: 11.09.18/M.Kanet
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden, der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00

;*** ReBoot-Routine für BBGRAM.
:ReBoot_BBG		php
			sei				;Interrupt sperren.

			jsr	GRamGetBankSize		;Bank-Größe für GeoRAM ermitteln.

			plp				;IRQ-Status zurücksetzen.

			txa				;Speicherfehler?
			bne	:51

			jsr	SetArea1
			jsr	GetRAM_BBG
			jsr	SetArea2
			jsr	GetRAM_BBG
			jmp	SystemReBoot		;ReBoot initialisieren.
::51			jmp	NoRAMfound

;*** FetchRAM-BBG-Routine für ReBoot.
:GetRAM_BBG		lda	GRAM_BANK_SIZE
			ldy	#jobFetch		;JobCode "FetchRAM".
			jmp	DoRAMOp_GRAM

;*** Zeiger auf RAM-Speicherbereiche.
:SetArea1		LoadW	r0 ,OS_LOW		;$9D80
			LoadW	r1 ,$b900
			LoadW	r2 ,$0280
			LoadB	r3L,$00
			lda	BOOT_RAM_BANK +1
			sta	r3H
			rts

:SetArea2		LoadW	r0 ,OS_HIGH		;$C000
			LoadW	r1 ,$bc40
			LoadW	r2 ,$0100
			LoadB	r3L,$00
			lda	BOOT_RAM_BANK +1
			sta	r3H
			rts

;*** Texte ausgeben.
:Strg_Titel		lda	#$00			;BootText00  = System.
			b $2c
:Strg_Autor		lda	#$01 			;Boottext00a = Autor.
			b $2c
:Strg_RamExp_Exit	lda	#$02			;BootText20  = Version.
			asl
			tax
			lda	StrgVecTab1 +0,x	;Zeiger auf Text einlesen.
			ldy	StrgVecTab1 +1,x

:Strg_CurText		php				;BASIC-ROM aktivieren.
			sei
			tax
			lda	CPU_DATA
			pha
			lda	#KRNL_BAS_IO_IN
			sta	CPU_DATA
			txa
			jsr	ROM_OUT_STRING		;Text ausgeben.
			pla
			sta	CPU_DATA
			plp
			rts

;*** Dateiname für Konfiguration.
:FNamGDINI		b "GD.INI",NULL

;*** Zeiger auf Textausgabe-Strings.
:StrgVecTab1		w BootText00
			w BootText00a
			w BootText20

;*** Texte für Start-Sequenz.
if LANG = LANG_DE
:BootText20		b CR,	"GD.RBOOT WURDE NOCH NICHT KONFIGURIERT"
			b CR,	"ODER DIE SPEICHERERWEITERUNG WURDE"
			b CR,	"NICHT ERKANNT. START ABGEBROCHEN..."
			b CR,CR,NULL
endif

if LANG = LANG_EN
:BootText20		b CR,	"GD.RBOOT WAS NOT CONFIGURED YET OR"
			b CR,	"RAM-EXPANSION-UNIT NOT DETECTED."
			b CR,	"START CANCELLED..."
			b CR,CR,NULL
endif

;*** Erweiterte Systemroutinen.

;--- Hardware-Erkennung.
			t "-G3_CheckSCPU"		;SuperCPU erkennen.
			t "-G3_CheckRLNK"		;RAMLink erkennen.

;--- Startmeldungen ausgeben.
			t "-G3_GetPAL_NTSC"
			t "-G3_PrntBootInf"
			t "-G3_PrntCoreInf"

;--- GEOS-DACC.
			t "-G3_LdDACCdev"
			t "-G3_GetRLPEntry"

;--- Speichererweiterung.
			t "-R3_DetectRLNK"
			t "-R3_DetectSCPU"
			t "-R3_DetectCREU"
			t "-R3_DetectGRAM"

			t "-R3_DoRAMOpCREU"

			t "-R3_DoRAMOpGRAM"
			t "-R3_GetSBnkGRAM"

			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"
