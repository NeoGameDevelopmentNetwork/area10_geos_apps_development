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
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "s.GDC.Config.ext"
endif

;*** GEOS-Header.
			n "obj.CFG.PSPL"
			f DATA

			o BASE_GCFG_BOOT

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	BOOT_GDC_SPOOL
;******************************************************************************

;*** AutoBoot: GD.CONF.SPOOLER.
:BOOT_GDC_SPOOL		jsr	e_ResetSpooler		;Spooler zurücksetzen.

			jsr	e_InitSpoolData		;Externe Routinen initialisieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	e_InitSpooler		;Spooler-Menü installieren.
			txa				;Fehler ?
			beq	:ok			; => Nein, weiter...

::err			jsr	e_ResetSpooler		;Spooler deaktivieren.

::ok			lda	Flag_Spooler		;Spooler-Status in Boot-
			sta	BootSpooler		;Konfiguration übernehmen.

			rts

;*** Zeiger auf externe Routinen einlesen.
.e_InitSpoolData	lda	#CFG_MOD_SPOOL
			jsr	LoadVlirHdr		;VLIR-Header GD.CONF.SPOOLER laden.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	fileHeader +4		;Erster Tr/Se Spooler-Menü.
			sta	vlirSpoolMenu +0
			lda	fileHeader +5
			sta	vlirSpoolMenu +1

			lda	fileHeader +6
			sta	vlirSpoolPrnt +0	;Erster Tr/Se Spooler-Treiber.
			lda	fileHeader +7
			sta	vlirSpoolPrnt +1

::err			rts

;*** Spooler-Menü nachladen.
:loadSpoolMenu		ldx	#FILE_NOT_FOUND
			lda	vlirSpoolMenu +0	;Spooler-Menü verfügbar?
			beq	:err			; => Nein, Spooler abschalten.
			sta	r1L
			lda	vlirSpoolMenu +1
			sta	r1H
			LoadW	r7,LOAD_SPOOLER
			LoadW	r2,R2S_SPOOLER
			jsr	ReadFile		;Spooler-Menü einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Spooler deaktivieren.

::err			rts

;*** Spooler-Treiber nachladen.
:loadSpoolPrnt		ldx	#FILE_NOT_FOUND
			lda	vlirSpoolPrnt +0	;Spooler-Treiber verfügbar?
			beq	:err			; => Nein, Spooler abschalten.
			sta	r1L
			lda	vlirSpoolPrnt +1
			sta	r1H
			LoadW	r7,PRINTBASE
			LoadW	r2,R2S_PRNSPOOL
			jsr	ReadFile		;Spooler-Treiber einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Spooler deaktivieren.

::err			rts

;*** Druckerspooler initialisieren.
.e_InitSpooler		jsr	e_SetSpoolSize		;Speicher für Spooler reservieren.
			txa				;Fehler ?
			bne	:exit			; => Nein, weiter...

			bit	Copy_firstBoot		;GEOS-BootUp ?
			bpl	:load			; => Ja, von Disk installieren.

			LoadW	r0,tempDataBuf		;Spooler installiert?
			LoadW	r1,R2A_SPOOLER
			LoadW	r2,sizeDataBuf
			lda	MP3_64K_SYSTEM
			sta	r3L
			jsr	FetchRAM

			lda	tempDataBuf +5
			cmp	#$4c			;"jmp SpoolData" ?
			bne	:load			; => Nein, neu installieren...
			lda	tempDataBuf +8
			cmp	#$4c			;"jmp SpoolMenu" ?
			beq	:init			; => Ja, bereits installiert...

::load			jsr	swapRAM_SplPrnt		;RAM-Bereich Spooler sichern.

			jsr	loadSpoolPrnt		;Spooler-Treiber nachladen.
			txa				;Fehlerstatus zwischenspeichern.
			pha

			jsr	swapRAM_SplPrnt		;Spooler in DACC speichern.

			pla				;Diskettenfehler?
			bne	:exit			; => Ja, Spooler deaktivieren.

			jsr	swapRAM_SplMenu		;RAM-Bereich Spooler sichern.

			jsr	loadSpoolMenu		;Spooler-Menü nachladen.
			txa				;Fehlerstatus zwischenspeichern.
			pha

			jsr	swapRAM_SplMenu		;Spooler in DACC speichern.

			pla				;Diskettenfehler?
			bne	:exit			; => Ja, Spooler deaktivieren.

::init			lda	BootSpooler		;Spooler aktivieren.
			sta	Flag_Spooler
			beq	:skip

			lda	BootSpoolDelay		;Verzögerungszeit festlegen.
			bne	:skip
			lda	#STD_SPOOL_DELAY	;Standard-Verzögerung: 15sek.
::skip			sta	Flag_SpoolCount

::exit			rts

;*** Speicher für Spooler-Menu laden/speichern.
:swapRAM_SplMenu	LoadW	r0,LOAD_SPOOLER		;Spooler-Menü.
			LoadW	r1,R2A_SPOOLER
			LoadW	r2,R2S_SPOOLER
			lda	MP3_64K_SYSTEM
			sta	r3L
			jmp	SwapRAM

;*** Speicher für Spooler-Drucker laden/speichern.
:swapRAM_SplPrnt	LoadW	r0,PRINTBASE		;Spooler-Drucker.
			LoadW	r1,R2A_PRNSPOOL
			LoadW	r2,R2S_PRNSPOOL
			lda	MP3_64K_SYSTEM
			sta	r3L
			jmp	SwapRAM

;*** Spooler zurücksetzen.
.e_ResetSpooler		jsr	e_ClrSpoolSize		;SpoolerRAM freigeben.

			lda	#$00			;Spooler-Variablen löschen.
			sta	Flag_Spooler
			sta	Flag_SpoolCount
			sta	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
			sta	Flag_SpoolADDR +0
			sta	Flag_SpoolADDR +1
			sta	Flag_SpoolADDR +2

			rts

;*** SpoolerRAM freigeben.
.e_ClrSpoolSize		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:1			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:1			; => Nein, weiter...

			jsr	e_GetSizeSpooler
			tay
			lda	Flag_SpoolMinB
			jsr	FreeBankTab		;Speicher freigeben.
::1			rts

;*** SpoolerRAM reservieren.
.e_SetSpoolSize		lda	BootSpoolSize		;SpoolerRAM aktiviert ?
			bne	:1			; => Nein, weiter...

			ldx	#NO_FREE_RAM
			bit	BootSpooler		;Spooler aktivieren.
			bpl	:3

			lda	#MAX_SPOOL_STD
			sta	BootSpoolSize

::1			ldy	BootSpoolSize		;Speicher für Spooler suchen.
			jsr	GetFreeBankLTab
			cpx	#NO_ERROR		;Speicher frei ?
			beq	:2			; => Ja, weiter...
			dec	BootSpoolSize		;SpoolerRAM -64K
			bne	:1			; => weitersuchen.

			ldx	#NO_FREE_RAM		;Kein Speicher für Spooler frei.
			rts

::2			sta	Flag_SpoolMinB
			sta	Flag_SpoolADDR +2
			ldx	#%11000000
			ldy	BootSpoolSize
			jsr	AllocateBankTab		;SpoolerRAM belegen.

			ldy	BootSpoolSize		;Erste und letzte Speicherbank
			dey				;für Spooler bestimmen.
			tya
			clc
			adc	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
			ldx	#NO_ERROR
::3			rts

;*** Anzahl 64K-Bänke in SpoolerRAM berechnen.
.e_GetSizeSpooler	lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			rts

;*** Startadressen VLIR-Daten.
:vlirSpoolMenu		b $00,$00
:vlirSpoolPrnt		b $00,$00

;*** temp. Ladeadresse für Daten.
:tempDataBuf
:sizeDataBuf = 3+2+3+3

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_DDRV_INFO - sizeDataBuf
;******************************************************************************
