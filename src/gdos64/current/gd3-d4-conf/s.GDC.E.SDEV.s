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
			n "obj.CFG.SDEV"
			f DATA

			o BASE_GCFG_BOOT

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	BOOT_GDC_SYSDEV
;******************************************************************************

;*** AutoBoot: GD.CONF.PRNINPT.
:BOOT_GDC_SYSDEV	lda	BootPrntMode		;Modus zum Laden des
			sta	Flag_LoadPrnt		;Druckertreibers festlegen.

			jsr	e_InitGCalcFix		;GeoCalc-BugFix aktivieren.

			jsr	e_InitPrntDev		;Drucker installieren.
			txa				;Diskettenfehler?
			beq	:1			; => Nein, weiter...

			lda	#NULL			;Druckername löschen.
			sta	BootPrntName
			jsr	e_InitPrntDev		;Drucker suchen und installieren.

::1			jsr	e_InitInptDev		;Eingabetreiber installieren.
			txa				;Diskettenfehler?
			beq	:2			; => Nein, weiter...

			lda	#NULL			;Inputname löschen.
			sta	BootInptName
			jsr	e_InitInptDev		;Input suchen und installieren.

::2			rts

;--- Ergänzung: 31.12.18/M.Kanet
;*** GeoCalc-BugFix aktivieren.
;Die Option reduziert die erlaubte Größe von Druckertreibern im RAM/Spooler
;um 1Byte, da GeoCalc ab $7F3F Programmcode nutzt. Dieses Byte ist aber noch
;für Druckertreiber reserviert.
.e_InitGCalcFix		ldx	#$40			;Größe: $7900 - $7F3F.
			bit	BootGCalcFix		;GCalc-Fix aktiv?
			bpl	:1			; => Nein, weiter...
			dex
::1			stx	GCalcFix1 +4
			stx	GCalcFix2 +4
			rts

;*** Ersten Druckertreiber auf Diskette suchen/laden.
.e_InitPrntDev		lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			lda	#< BootPrntName
			ldx	#> BootPrntName
			ldy	BootPrntName		;Druckername definiert ?
			bne	:setprnt		; => Ja, weiter...

			sta	r6L
			stx	r6H
			LoadB	r7L,PRINTER
			LoadB	r7H,1
			LoadW	r10,$0000
			jsr	FindFTypes		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:noprnt			; => Ja, Kein Drucker...
			lda	r7H			;Druckertreiber gefunden?
			beq	:found			; => Ja, weiter...

::noprnt		lda	#< NoPrntName		;Kein Druckertreiber...
			ldx	#> NoPrntName
			bne	:setprnt

::found			lda	#< BootPrntName		;Druckertreiber gefunden...
			ldx	#> BootPrntName
::setprnt		sta	r0L
			stx	r0H

;*** Druckertreiber laden.
;    Übergabe:		r0 = Zeiger auf Dateiname.
.e_CopyPrntNam		lda	#< BootPrntName
			ldx	#> BootPrntName
			jsr	copyDevName

			lda	#< PrntFileName
			ldx	#> PrntFileName
			jsr	copyDevName

;*** Druckertreiber laden.
;    Beim C64 wird damit automatisch der Treiber auch in die
;    Speichererweiterung kopiert.
.e_LoadPrntDev		LoadW	r0 ,NoPrntName
			LoadW	r6 ,PrntFileName	;Zeiger auf Druckername.
			ldx	#r0L
			ldy	#r6L
			jsr	CmpString		;Drucker definiert?
			bne	:load			; => Ja, weiter...

			ldx	#DEV_NOT_FOUND		;Kein Drucker verfügbar.
			rts

::load			LoadW	r7 ,PRINTBASE
			LoadB	r0L,%00000001
			jmp	GetFile			;Druckertreiber einlesen.

;*** Ersten Eingabetreiber auf Diskette suchen/laden.
.e_InitInptDev		lda	#< BootInptName
			ldx	#> BootInptName
			ldy	BootInptName		;Eingabegerät definiert ?
			bne	:setinpt		; => Ja, weiter...

			sta	r6L
			stx	r6H

			LoadB	r7L,INPUT_DEVICE
			LoadB	r7H,1
			LoadW	r10,$0000
			jsr	FindFTypes		;Eingabetreiber suchen.
			txa				;Diskettenfehler ?
			bne	:noinpt			; => Ja, Kein Eingabetreiber...
			lda	r7H			;Eingabetreiber gefunden?
			beq	:found			; => Ja, weiter...

::noinpt		lda	#< NoInptName		;Kein Eingabegerät...
			ldx	#> NoInptName
			bne	:setinpt

::found			lda	#< BootInptName		;Eingabetreiber gefunden...
			ldx	#> BootInptName
::setinpt		sta	r0L
			stx	r0H

;*** Eingabetreiber laden.
;    Übergabe:		r0 = Zeiger auf Dateiname.
.e_CopyInptNam		lda	#< BootInptName
			ldx	#> BootInptName
			jsr	copyDevName

			lda	#< inputDevName
			ldx	#> inputDevName
			jsr	copyDevName

;*** Eingabegerät laden.
.e_LoadInptDev		jsr	ClearMouseMode		;Mauszeiger abschalten.

			LoadW	r0 ,NoInptName
			LoadW	r6 ,inputDevName	;Name auf Eingabegerät.
			ldx	#r0L
			ldy	#r6L
			jsr	CmpString		;Eingabegerät definiert?
			bne	:load			; => Ja, weiter...

;-- Hinweis:
;Hier ist in GD.CONFIG kein Eingabe-
;gerät definiert ("Keine Maus!").
;Im Kernal ist aber immer der Treiber
;Mouse1351 enthalten.
			ldx	#NO_ERROR
			beq	:init			;Mauszeiger nur initialisieren.

::load			LoadB	r0L,%00000001
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile			;Eingabegerät einlesen.
::init			txa
			pha				;Fehlerstatus zwischenspeichern.

			jsr	InitMouse		;Eingabegerät initialisieren.

			clc
			jsr	StartMouseMode		;Eingabegerät starten.

			lda	mouseOn
			ora	#%00100000
			sta	mouseOn			;Icon-Menü wieder einschalten.

			pla
			tax

::1			rts

;*** Dateiname für Eingabe-/Druckertreiber kopieren.
:copyDevName		sta	r1L
			stx	r1H
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;*** Systemtexte.
if LANG = LANG_DE
:NoPrntName		b "Kein Drucker!",NULL
:NoInptName		b "Keine Maus!",NULL
endif
if LANG = LANG_EN
:NoPrntName		b "No printer!",NULL
:NoInptName		b "No mouse!",NULL
endif

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_DDRV_INFO
;******************************************************************************
