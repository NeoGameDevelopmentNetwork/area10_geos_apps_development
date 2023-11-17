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
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_DISK"
			t "SymbTab_DBOX"
			t "SymbTab_KEYS"
			t "MacTab"

;--- Externe Labels.
			t "s.GDC.Config.ext"

;--- Dialogbox:
:MAX_FNAMES		= 15				;Max. 15! (:tabFNames = 256 Bytes!)

:DLG_LEFT		= $0050
:DLG_WIDTH		= $00a8
:DLG_TOP		= $20
:DLG_HEIGHT		= $38

:BOX_LEFT		= (DLG_LEFT +8)/8
:BOX_WIDTH		= (DLG_WIDTH -2*8)/8
:BOX_TOP		= (DLG_TOP +2*8)/8
:BOX_HEIGHT		= 2

:INP_OFF_X		= 2
:INP_WIDTH		= BOX_WIDTH -INP_OFF_X

:GFX_BASE1		= SCREEN_BASE  +(BOX_TOP+0)*8*40 +BOX_LEFT*8
:GFX_BASE2		= SCREEN_BASE  +(BOX_TOP+1)*8*40 +BOX_LEFT*8
:COL_BASE1		= COLOR_MATRIX +(BOX_TOP+0)  *40 +BOX_LEFT
:COL_BASE2		= COLOR_MATRIX +(BOX_TOP+1)  *40 +BOX_LEFT
endif

;*** GEOS-Header.
			n "obj.CFG.INIT"
			f DATA

			o BASE_CONFIG_TOOL

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMain
::dummy1		ldx	#FILE_NOT_FOUND
			rts
::dummy2		ldx	#FILE_NOT_FOUND
			rts
;******************************************************************************

;*** GD.CONFIG intialisieren.
:InitMain		ldx	#0
::1			lda	fileHeader +6,x
			sta	sysCfgInitAdr,x
			inx
			cpx	#8*2
			bcc	:1

			jsr	FindCfgTools		;Konfigurations-Module suchen.
			txa				;Fehler?
			bne	:doErrExit		; => Ja, Abbruch...

;--- GD.INI einlesen.
			LoadW	r0,BASE_GCFG_DATA	;Zeiger auf GD.INI in DACC.
			LoadW	r1,R3A_CFG_GDOS
			LoadW	r2,R3S_CFG_GDOS
			lda	MP3_64K_DATA
			sta	r3L
			jsr	FetchRAM		;GD.INI einlesen.

;--- DiskCore einlesen.
			LoadW	r0,BASE_DDRV_CORE	;Zeiger auf GD.DISK.CORE in DACC.
			LoadW	r1,R2A_DDRVCORE
			LoadW	r2,R2S_DDRVCORE
			lda	MP3_64K_SYSTEM
			sta	r3L
			jsr	FetchRAM		;GD.DISK.CORE einlesen.

;--- Treiberliste initialisieren.
			jsr	InitDevList

;--- Menü starten/AutoBoot ausführen.
			bit	Copy_firstBoot		;GEOS-BootUp ?
			bmi	:doAppStart		; => Nein, weiter...

::doAutoBoot		jsr	chkSlctInput		;Eingabetreiber wechseln?

			ldx	#$ff
			rts

::doAppStart		ldx	#$00
::doErrExit		rts

;*** Eingabetreiber wählen?
:chkSlctInput		php
			sei				;IRQ-Status speichern.

			ldx	CPU_DATA

			lda	#IO_IN			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	#%01111111		;C=-Taste abfragen.
			sta	cia1base +0
			lda	cia1base +1

			stx	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;IRQ-Status zurücksetzen.

			and	#%00100000		;C=-Taste gedrückt?
			beq	:doSlctInput		; => Ja, Treiber auswählen.

::exit			rts				;Ende.

;--- Treiberauswahl starten.
::doSlctInput		lda	curDrive		;Nur Boot-Laufwerk verfügbar.
			sta	drvFNames

			jsr	FindInpDev		;Max. 15 Eingabetreiber suchen.

			lda	maxFNames		;Eingabetreiber gefunden?
			beq	:exit			; => Nein, Abbruch...

			lda	#< Dlg_SlctInput
			sta	r0L
			lda	#> Dlg_SlctInput
			sta	r0H

			jsr	DoDlgBox		;Treiberauswahl über Dialogbox.

			lda	sysDBData
			cmp	#OK			;RETURN?
			bne	:exit			; => Nein, Ende...

			ldx	#0			;Treibername in
::copy			lda	curFName,x		;Systemkonfiguration übernehmen.
			sta	BootInptName,x
			beq	:end
			inx
			cpx	#16
			bcc	:copy

			lda	#NULL
::clr			sta	BootInptName,x
::end			inx
			cpx	#17
			bcc	:clr

			rts

;*** Eingabetreiber suchen.
:FindInpDev		ldy	#0			;Namenspeicher löschen.
;			lda	#$00
			tya
::1			sta	tabFNames,y
			iny
			bne	:1

;			lda	#0			;Zeiger auf ersten Eintrag.
			sta	poiFName
			sta	curFName

			lda	#< tabFNames
			sta	r6L
			lda	#> tabFNames
			sta	r6H

			lda	#INPUT_DEVICE		;GEOS-Dateityp: Eingabetreiber.
			sta	r7L

			lda	#MAX_FNAMES		;Max. 15 Dateien.
			sta	r7H

			lda	#NULL			;Keine GEOS-Klasse testen.
			sta	r10L
			sta	r10H

			jsr	FindFTypes		;Dateitypen suchen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	#MAX_FNAMES		;Anzahl Dateien berechnen.
			sec
			sbc	r7H
			tay				;Mind. 1 Datei?
			bne	:done			; => Ja, weiter...

::err			ldy	#0
::done			sty	maxFNames
			tya
			bne	getCurFName		;Zeiger auf ersten Dateinamen.

			rts

;*** Aktuellen Eintrag in Zwischenspeicher.
:getCurFName		ldx	poiFName		;Zeiger auf Dateiname in Tabelle.
			lda	vecFNameTab,x
			clc
			adc	#< tabFNames
			sta	r0L
			lda	#0
			adc	#> tabFNames
			sta	r0H

			ldy	#0			;Name in Zwischenspeicher
::1			lda	(r0),y			;kopieren und mit NULL-Bytes
			sta	curFName,y		;auffüllen.
			beq	:2
			iny
			bne	:1
::2			cpy	#16
			beq	:3
			sta	curFName,y
			iny
			bne	:2

::3			rts

;*** Tastaturabfrage initialisieren.
:DB_INIT_KEYB		lda	#< :chkKeyB		;Tastaturabfrage installieren.
			sta	keyVector +0
			lda	#> :chkKeyB
			sta	keyVector +1
			rts

::chkKeyB		lda	keyData			;Taste gedrückt?
			beq	:exit			; =>  Nein, Ende...
			cmp	#"x"			;Taste "X"?
			beq	:cancel			; => Ja, Auswahl abbrechen...
			cmp	#KEY_CR			;Taste "RETURN"?
			bne	:1			; => Nein, weiter...

			lda	#OK
::cancel		sta	sysDBData
			jmp	RstrFrmDialogue		;Dialogbox beenden.

::1			cmp	#KEY_DOWN		;"CURSOR DOWN"?
			bne	:2			; => Nein, weiter...

			ldx	poiFName		;Zeiger auf nächsten Namen in
			inx				;Tabelle berechnen.
			cpx	maxFNames
			bcs	:exit
			stx	poiFName
			bcc	:update			;Neuen Namen ausgeben.

::2			cmp	#KEY_UP			;"CURSOR UP"?
			bne	:exit			; => Nein, Ende...

			ldx	poiFName		;Zeiger auf vorherigen Namen in
			beq	:exit			;Tabelle berechnen.
			dex
			stx	poiFName

::update		jsr	getCurFName		;Neuen Namen ausgeben.

			jsr	DB_CLR_INPUT
			jsr	DB_DRAW_INPUT

::exit			rts

;*** Ausgabebereich löschen.
:DB_CLR_GFX		lda	#$00
			ldx	#BOX_WIDTH*8 -1
::1			sta	GFX_BASE1,x
			sta	GFX_BASE2,x
			dex
			cpx	#$ff
			bne	:1
			rts

:DB_CLR_INPUT		lda	#$00
			ldx	#INP_WIDTH*8 -1
::1			sta	GFX_BASE1 +INP_OFF_X*8,x
			sta	GFX_BASE2 +INP_OFF_X*8,x
			dex
			cpx	#$ff
			bne	:1
			rts

:DB_CLR_COL		lda	C_InputField
			ldx	#BOX_WIDTH -1
::1			sta	COL_BASE1,x
			sta	COL_BASE2,x
			dex
			bpl	:1
			rts

:DB_DRAW_BOX		jsr	i_FrameRectangle
			b	BOX_TOP*8 -1
			b	BOX_TOP*8 +BOX_HEIGHT*8
			w	BOX_LEFT*8 -1
			w	BOX_LEFT*8 +BOX_WIDTH*8
			b	%11111111
			rts

;*** Aktuelles Laufwerk ausgaben.
:DB_DRAW_DRIVE		lda	#< (BOX_LEFT*8) +4
			sta	r11L
			lda	#> (BOX_LEFT*8) +4
			sta	r11H

			lda	# (BOX_TOP*8) +10
			sta	r1H

			lda	drvFNames
			clc
			adc	#"A" -8
			jsr	SmallPutChar

			lda	#":"
			jmp	SmallPutChar

;*** Aktuelle Namen ausgaben.
:DB_DRAW_INPUT		lda	#< (BOX_LEFT*8) +4 +12
			sta	r11L
			lda	#> (BOX_LEFT*8) +4 +12
			sta	r11H

			lda	# (BOX_TOP*8) +10
			sta	r1H

			lda	#< curFName
			sta	r0L
			lda	#> curFName
			sta	r0H

			jmp	PutString

;*** Konfigurationsmodule suchen.
:FindCfgTools		php
			sei

			jsr	Get1stDirEntry		;Erster DIR-Sektor lesen.
			txa				;Diskettenfehler?
			bne	:8			; => Ja, Abbruch.

;			ldx	#$00			;Cache löschen.
;			lda	#$00
::0			sta	sysCfgToolAdr,x
			inx
			cpx	#8*2
			bcc	:0

			LoadB	r7H,8			;Modulzähler initialisieren.

::1			tay				;yReg=$00.
			lda	(r5L),y			;Gelöschter Eintrag?
			beq	:4			; => Ja, weiter...
			iny
			lda	(r5L),y			;Sektoradresse gültig?
			beq	:4			; => Nein, weiter...

			iny				;"GD.C..." ?
			iny
			lda	(r5L),y
			cmp	#"G"
			bne	:4
			iny
			lda	(r5L),y
			cmp	#"D"
			bne	:4
			iny
			iny
			lda	(r5L),y
			cmp	#"C"
			bne	:4			; => Nein, weiter...

			PushW	r1
			PushW	r4

			jsr	testCfgNames		;Auf Konfigurationsmodul testen.

			PopW	r4
			PopW	r1

			txa				;Modul gefunden?
			bne	:4			; => Nein, weiter...

			dec	r7H			;Alle Module gefunden?
			beq	:8			; => Ja, Ende...

::4			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler?
			bne	:8			; => Ja, Abbruch...
			tya				;Verzeichnis-Ende erreicht?
			beq	:1			; => Nein, weiter...

::8			plp
			rts

;*** Auf Konfigurationsmodul testen.
:testCfgNames		lda	#0			;Modul-Zähler zurücksetzen.
::1			sta	r7L			;Zeiger auf ersten Track/Sektor
			asl				;in Systemtabelle/Cache kopieren.
			tax
			lda	sysCfgToolAdr +0,x
			bne	:4			;Modul bereits gefunden, weiter...

			lda	sysCfgToolNmVec +0,x
			sec
			sbc	#< $0003
			sta	r6L
			lda	sysCfgToolNmVec +1,x
			sbc	#> $0003
			sta	r6H

			ldy	#$03
::2			lda	(r6L),y			;Dateinamen vergleichen.
			beq	:3			; => Ende Modul-Name erreicht...
			cmp	(r5L),y
			bne	:4			; => Falsche Datei...
			iny				;Kompletter Modul-Name geprüft?
			bne	:2			; => Nein, weiter...

::3			cpy	#$13
			beq	:5			; => Richtige Datei...
			lda	(r5L),y
			iny
			cmp	#$a0
			beq	:3
			bne	:4			; => Falsche Datei...

::5			ldy	#1			;Zeiger auf ersten Track/Sektor
			lda	(r5L),y			;einlesen.
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H

			ldy	#21
			lda	(r5L),y			;SEQ oder VLIR?
			beq	:6			; => SEQ, weiter...

			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Fehler?
			bne	:4			; => Ja, Datei ignorieren...

			lda	fileHeader +2		;Zeiger auf ersten Track/Sektor
			sta	r1L			;einlesen.
			lda	fileHeader +3
			sta	r1H

::6			lda	r7L			;Zeiger auf ersten Track/Sektor
			asl				;in Systemtabelle/Cache kopieren.
			tax
			lda	r1L
			sta	sysCfgToolAdr +0,x
			lda	r1H
			sta	sysCfgToolAdr +1,x

			ldx	#NO_ERROR
			rts

::4			lda	r7L			;Nächstes Konfigurationsmodul.
			clc
			adc	#$01
			cmp	#8			;Alle Module getestet?
			bcc	:1			; => Nein, weiter...

			ldx	#FILE_NOT_FOUND
			rts

;*** Treiberinformationen initialisieren.
; - Tabelle mit gültigen Laufwerkstypen initialisieren.
; - Tabelle mit verfügbaren Laufwerkstreibern löschen.
:InitDevList		jsr	i_FillRam		;Speicher für Treiber löschen.
			w	SIZE_DDRV_DATA
			w	BASE_DDRV_DATA
			b	$00

			jsr	i_FillRam		;DiskDataRAM_A/S/B
			w	DDRV_MAX*2 +DDRV_MAX*2 +DDRV_MAX
			w	DRVINF_NG_START
			b	$00

			jsr	i_FillRam		;DiskDrvData
			w	DDRV_MAX
			w	DRVINF_NG_FOUND
			b	$00

			jsr	i_MoveData		;DiskDrvTypes
			w	DskDrvTypes
			w	DRVINF_NG_TYPES
			w	DDRV_MAX

			jsr	i_MoveData		;DiskDrvNames
			w	DskDrvNames
			w	DRVINF_NG_NAMES
			w	DDRV_MAX*17

			rts

;--- Hinweis:
;Die Laufwerkstypen werden beim Start
;von GD.CONFIG an die richtige Adresse
;im Speicher kopiert.
			t "-D3_DrvTypes"

;*** Dateiauswahlbox.
:Dlg_SlctInput		b %00000001

			b DLG_TOP ,DLG_TOP  +DLG_HEIGHT -1
			w DLG_LEFT,DLG_LEFT +DLG_WIDTH  -1

			b DB_USR_ROUT
			w DB_INIT_KEYB

			b DB_USR_ROUT
			w DB_DRAW_BOX

			b DB_USR_ROUT
			w DB_CLR_COL

			b DB_USR_ROUT
			w DB_DRAW_DRIVE

			b DB_USR_ROUT
			w DB_DRAW_INPUT

			b DBTXTSTR ,$08,$09
			w :info
			b DBTXTSTR ,$08,$2a
			w :info1
			b DBTXTSTR ,$08,$33
			w :info2

			b NULL

if LANG = LANG_DE
::info			b "Eingabegerät wählen:",NULL
::info1			b "RETURN=Auswahl, X=Abbruch",NULL
::info2			b "CRSR UP/DOWN=Wechseln",NULL
endif
if LANG = LANG_EN
::info			b "Select input device:",NULL
::info1			b "RETURN=Select, X=Cancel",NULL
::info2			b "CRSR UP/DOWN=Switch",NULL
endif

;*** Speicher für Dateinamen.
:maxFNames		b $00
:drvFNames		b $00
:poiFName		b $00
:curFName		s 17
:vecFNameTab		b  0*17,  1*17,  2*17,  3*17
			b  4*17,  5*17,  6*17,  7*17
			b  8*17,  9*17, 10*17, 11*17
			b 12*17, 13*17, 14*17, 15*17

:tabFNames		; s 256

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g OS_BASE -256
;******************************************************************************
