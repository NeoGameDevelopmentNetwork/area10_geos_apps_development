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
			n "obj.CFG.HELP"
			f DATA

			o BASE_GCFG_BOOT

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	BOOT_GDC_HELPSYS
;******************************************************************************

;*** AutoBoot: GD.CONF.GEOHELP.
:BOOT_GDC_HELPSYS	lda	ramExpSize
;			sec				;Letze Speicherbank = DACC -1.
;			sbc	#$01
			sec				;2x64K für GDOS-System abziehen.
			sbc	#$02 +1			;Bank-Adresse Hilfesystem berechnen.
			jsr	FreeBank		;Speicher freigeben.

			jsr	e_InitHelpSys		;GeoHelp nachladen.
			txa				;System installiert ?
			bne	:exit			; => Nein, Ende...

			lda	BootHelpSysMode		;Hilfesystem-Status festlegen.
			sta	HelpSystemActive

			lda	BootHelpSysDrv		;Hilfe-Laufwerk definiert ?
			bne	:setHelpDrv		; => Ja, weiter...

			ldx	SystemDevice		;Start-Laufwerk übernehmen.
			lda	RealDrvMode -8,x	;Laufwerk vom Typ CMD-FD/HD/RL?
			and	#SET_MODE_PARTITION
			beq	:useSysDrv		; => Nein, weiter...

			lda	RealDrvType -8,x	;Laufwerkstyp als Hilfe-Laufwerk.
			bne	:setHelpDrv

::useSysDrv		lda	SystemDevice		;GEOS-Adresse als Hilfe-Laufwerk.
::setHelpDrv		sta	HelpSystemDrive

			and	#DrvCMD			;CMD-Laufwerk?
			beq	:setNoPart		; => Nein, weiter...

			lda	HelpSystemDrive
			jsr	e_ChkHelpDrv		;Hilfe-Laufwerk suchen.
			txa				;Laufwerk gefunden ?
			bne	:useSysDrv		; => Nein, weiter...
			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:useSysDrv		; => Ja, Ende...

			lda	BootHelpSysPart		;Hilfe-Partition definiert ?
			bne	:setHelpPart		; => Ja, weiter...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:useSysDrv		; => Ja, Abbruch...

			ldx	curDrive
			lda	drivePartData-8,x	;Hilfe-Partition vorbelegen.
			b $2c
::setNoPart		lda	#$00
::setHelpPart		sta	HelpSystemPart
::exit			rts

;*** Laufwerkstyp mit gültiger Partition suchen.
;Übergabe: AKKU = CBM-Laufwerk: #8, #9, #10, #11
;                 CMD-Laufwerk: DrvFD81,DrvRL81...
;Rückgabe: YREG = Laufwerksadresse.
;          XREG = >$00 = Fehler.
.e_ChkHelpDrv		sta	r0L			;Laufwerkstyp speichrn.
			tay
			and	#%11110000		;CMD-Laufwerk?
			beq	:5			; => Nein, Ende...

			ldy	#8
::1			lda	driveType   -8,y	;Laufwerk verfügbar ?
			beq	:3			; => Nein, weiter...

			lda	RealDrvType -8,y	;Laufwerkstyp überprüfen.
			cmp	r0L			;Stimmt Laufwerksformat ?
			beq	:5			; => Nein, weiter...

::3			iny
			cpy	#12			;Alle Laufwerke durchsucht ?
			bcc	:1			; => Nein, weiter...

::4			ldx	#DEV_NOT_FOUND
			rts

::5			ldx	#NO_ERROR
			rts

;*** Hilfesystem nachladen und installieren.
.e_InitHelpSys		jsr	GetFreeBankL		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;Speicher frei ?
			beq	:init			; => Ja, Hilfesystem einlesen.
			txa
			bne	:err			; => Nein, Hilfesystem deaktivieren.

::init			sta	HelpSystemBank		;Bank-Adresse speichern.
			ldx	#%11000000		;Speicherbank reservieren.
			jsr	AllocateBank

;--- Hilfesystem nachladen.
::load			jsr	swapRAM_HelpSys		;RAM-Bereich Hilfesystem sichern.

			jsr	loadHelpMenu		;Hilfesystem nachladen.
			txa				;Fehlerstatus zwischenspeichern.
			pha

			jsr	swapRAM_HelpSys		;Hilfesystem in DACC speichern.

			pla				;Diskettenfehler?
			beq	:exit			; => Ja, Hilfesystem deaktivieren.

::err			pha

			lda	HelpSystemBank		;Bereits belegte Speicherbank
			beq	:off			;wieder freigeben.
			jsr	FreeBank

::off			lda	#$00			;Hilfesystem kann nicht
			sta	HelpSystemActive	;aktiviert werden.
			sta	HelpSystemBank

			pla
::exit			tax

			rts

;*** Speicher für Hilfesystem laden/speichern.
:swapRAM_HelpSys	LoadW	r0,BASE_GCFG_MAIN	;Hilfesystem.
			LoadW	r1,RHA_HELPSYS
			LoadW	r2,RHS_HELPSYS
			lda	HelpSystemBank
			sta	r3L
			jmp	SwapRAM

;*** Hilfesystem nachladen.
:loadHelpMenu		LoadW	r6 ,dataFileName
			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,Class_GeoHelp
			jsr	FindFTypes		;Hilfesystem suchen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			ldx	#FILE_NOT_FOUND
			lda	r7H			;Datei gefunden ?
			bne	:err			; => Nein, Abbruch...

			LoadW	r6,dataFileName
			jsr	FindFile		;Verzeichnis-Eintrag einlesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r7,BASE_GCFG_MAIN
			LoadW	r2,RHS_HELPSYS
			jsr	ReadFile		;Hilfesystem einlesen.
;			txa				;Diskettenfehler?
;			bne	:err			; => Ja, Hilfesystem deaktivieren.

::err			rts

;*** GEOS-Klasse für GeoHelp.
:Class_GeoHelp		b "GD.HELP     V2",0

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_DDRV_INFO
;******************************************************************************
