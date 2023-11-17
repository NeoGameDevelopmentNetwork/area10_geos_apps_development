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
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "e.Register.ext"
			t "o.DiskCore.ext"

;--- Modul-Nummern:
.CFG_MOD_RAM		= 1 ;RAM.
.CFG_MOD_DEV		= 2 ;Ein-/Ausgabegeräte.
.CFG_MOD_DRIVE		= 3 ;Laufwerksauswahl.
.CFG_MOD_SCREEN		= 4 ;Anzeige.
.CFG_MOD_GEOS		= 5 ;GEOS.
.CFG_MOD_HELP		= 6 ;Hilfesystem.
.CFG_MOD_TASK		= 7 ;TaskManager.
.CFG_MOD_SPOOL		= 8 ;Spooler.

;--- BASIC-LOAD:2Bytes
;000
;LOAD_CFG_GDOS		= BASE_GCFG_DATA +0

;--- DACC-Typ:5Bytes
;Direkt nach BASIC-LOAD, wird von der
;Datei GD.BOOT beim Systemstart über
;Kernal-Routinen aus GD.INI eingelesen.
;002
:BOOT_RAM_TYPE		= BASE_GCFG_DATA +2
:BOOT_RAM_SIZE		= BASE_GCFG_DATA +3
:BOOT_RAM_BANK		= BASE_GCFG_DATA +4
:BOOT_RAM_PART		= BASE_GCFG_DATA +6

;--- GDC.DRIVES:25Bytes
;Direkt nach DACC-Typ. Wird in INITSYS
;an dieser Stelle in der GD.INI-Datei
;nach dem Update gespeichert.
;007
.BootConfig		= BASE_GCFG_DATA +7
.BootPartRL		= BASE_GCFG_DATA +11
.BootPartType		= BASE_GCFG_DATA +15
.BootRamBase		= BASE_GCFG_DATA +19
;023
.BootRAM_Flag		= BASE_GCFG_DATA +23
.BootDrvToRAM		= BASE_GCFG_DATA +24
.BootUseFastPP		= BASE_GCFG_DATA +25
.BootDrvReplace		= BASE_GCFG_DATA +26
.BootDrvRAMLink		= BASE_GCFG_DATA +27

;--- GD.CONFIG:0Bytes
;028

;--- GDC.RAM:65Bytes (RAM_MAX_SIZE)
;028
.BootBankAppl		= BASE_GCFG_DATA +28
.BootBankBlocked	= BASE_GCFG_DATA +29

;--- GDC.GEOS:30Bytes
;093
.BootSpeed		= BASE_GCFG_DATA +93
.BootOptimize		= BASE_GCFG_DATA +94
.BootMenuStatus		= BASE_GCFG_DATA +95
.BootMLineMode		= BASE_GCFG_DATA +96
.BootColsMode		= BASE_GCFG_DATA +97
.BootCRSR_Repeat	= BASE_GCFG_DATA +98
.BootQWERTZ		= BASE_GCFG_DATA +99
.BootRTCdrive		= BASE_GCFG_DATA +100
.BootNameDT		= BASE_GCFG_DATA +101
.BootFileDT		= BASE_GCFG_DATA +114

;--- GDC.SCREEN:61Bytes
;123
.BootColorGEOS		= BASE_GCFG_DATA +123
;145
.BootSaveColors		= BASE_GCFG_DATA +145
;--- Hintergrundbild:
;146
.BootGrfxFile		= BASE_GCFG_DATA +146
.BootGrfxRandom		= BASE_GCFG_DATA +163
.BootPattern		= BASE_GCFG_DATA +164
;--- Bildschirmschoner:
;165
.BootScrSaver		= BASE_GCFG_DATA +165
.BootScrSvCnt		= BASE_GCFG_DATA +166
.BootSaverName		= BASE_GCFG_DATA +167

;--- GDC.PRNINPT:36Bytes
;BootInptName wird bei einem Update
;gelöscht, damit der neu installierte
;Eingabetreiber verwendet wird.
;Siehe dazu auch "-G3_InitInpDev"!
;184
.BootInptName		= BASE_GCFG_DATA +184
.BootPrntName		= BASE_GCFG_DATA +201
.BootPrntMode		= BASE_GCFG_DATA +218
.BootGCalcFix		= BASE_GCFG_DATA +219

;--- GDC.GEOHELP:3Bytes
;220
.BootHelpSysMode  = BASE_GCFG_DATA +220
.BootHelpSysDrv		= BASE_GCFG_DATA +221
.BootHelpSysPart	= BASE_GCFG_DATA +222

;--- GDC.TASKMAN:3Bytes
;223
.BootTaskMan		= BASE_GCFG_DATA +223
.BootTaskSize		= BASE_GCFG_DATA +224
.BootTaskStart		= BASE_GCFG_DATA +225

;--- GDC.SPOOLER:3Byte
;226
.BootSpooler		= BASE_GCFG_DATA +226
.BootSpoolDelay		= BASE_GCFG_DATA +227
.BootSpoolSize		= BASE_GCFG_DATA +228

;--- EOF
;229
;254 ;Max. 254 Bytes!
endif

;*** GEOS-Header.
			n "obj.GDC.CORE"
			t "opt.Config.Class"
			t "opt.Author"
;			f AUTO_EXEC
			f APPLICATION
			z $80 ;nur GEOS64

			o BASE_GCFG_MAIN
			p MAIN_INIT

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "GEOS/GDOS konfigurieren:"
			h "Laufwerke, Drucker usw..."
endif
if LANG = LANG_EN
			h "Configure GEOS/GDOS:"
			h "Drives, printer and more..."
endif

;*** Einsprung aus GD.BOOT.
:MAIN_INIT		jmp	InitConfig		;GD.CONFIG initialisieren.

;******************************************************************************
;*** System-Register.
;******************************************************************************
;Die folgenden Register werden auch von
;anderen Modulen verwendet.

;--- Kopie von ":firstBoot"-Flag.
.Copy_firstBoot		b $00

;--- Kopie von ":Flag_TaskMan".
;Der TaskManager wird beim Start von
;GD.CONFIG deaktiviert!
.Copy_BootTaskMan b %10000000;TaskMan-Status.

;--- System-Laufwerk/Startdatei.
.SystemDevice		b $00

;--- Hinweis:
;Nicht mehr erforderlich, da die Module
;direkt über ReadFile geladen werden.
;.SysFileClass		t "opt.Config.Build"
;.SysFileName		s 17

;******************************************************************************
;*** Einsprungtabelle.
;******************************************************************************
.DrawCfgMenu		jmp	xDrawCfgMenu
.GetFreeBankL		jmp	DACC_LAST_BANK
.GetFreeBankLTab	jmp	DACC_LAST_RAM
.AllocateBank		jmp	DACC_ALLOC_BANK
.AllocateBankTab	jmp	DACC_ALLOC_RAM
.FreeBank		jmp	DACC_FREE_BANK
.FreeBankTab		jmp	DACC_FREE_RAM
.GetBankByte		jmp	DACC_BANK_BYTE

;******************************************************************************
;*** GD.CONFIG - Systemroutinen.
;******************************************************************************
;			t "-G3_Kernal2REU"		;Kernal in REU kopieren.
;			t "-G3_UseFontG3"		;Neuen Zeichensatz aktivieren.
			t "-G3_LogoScreen"		;GDOS64-Logo anzeigen.
.DrawDBoxTitel		t "-G3_DBoxTitel"		;Titelzeile in Dialogbox löschen.
.SysHEX2ASCII		t "-G3_HEX2ASCII"		;HEX-Zahl nach ASCII wandeln.
			t "-DA_LastRAM"			;Freien Speicher suchen.
			t "-DA_GetBankByte"		;Status Speicherbank ermitteln.
			t "-DA_FreeBank"		;Speicherbank freiegeben.
			t "-DA_FreeRAM"			;Speicher freiegeben.
			t "-DA_AllocBank"		;Speicherbank reservieren.
			t "-DA_AllocRAM"		;Speicher reservieren.
;******************************************************************************

;*** Menü initialisieren.
:InitConfig		jsr	FindGD3			;GDOS-Kernal suchen.

			lda	firstBoot		;GEOS-Flag zwischenspeichern.
			sta	Copy_firstBoot		;GEOS-BootUp ?
			bmi	:1			; => Nein, weiter...

			jsr	Stash_AutoBoot		;AutoBoot-Routine retten.

;--- Ergänzung: 26.02.21/M.Kanet
;Kein BackScreen-Buffer verwenden, da
;die einzelnen Konfigurations-Module
;den Speicherbereich bis zum Beginn
;des Register-Menüs verwenden dürfen!
::1			lda	#ST_WR_FORE
			sta	dispBufferOn

;--- Hinweis:
;RegisterFont laden. Muss ausserhalb
;von DrawCfgMenu erfolgen, da im Menü
;"Bildschirm" über ":RegisterInitMenu"
;das aktuelle Menü erneut angezeigt
;wird. Dabei wird zuvor ":DrawCfgMenu"
;aufgerufen, was dann den Zeiger auf
;das aktuelle Menü löschen würde.
			lda	#NULL			;Kein Menü aktivieren, aber
			tax				;RegisterMenu-Code laden.
			jsr	EnableRegMenu		;Registerfont aktivieren.

;--- Hinweis:
;":curDevice" an Stelle von ":curDrive"
;verwenden, da beim Systemstart von
;einem Laufwerk #12 ":curDrive" auf
;das Laufwerk A: umgestellt wurde.
			lda	curDevice		;Start-Laufwerk speichern.
			sta	SystemDevice		;Bei CMD-HD/RL auch >= #12!

;--- Initialisierung starten.
			jsr	GetCurVlirHdr		;VLIR-Header für GD.CONFIG laden.
			txa				;Fehler?
			bne	DoExitDeskTop		; => Ja, Abbruch...

			lda	fileHeader +4		;Zeiger auf VLIR-Datendatz für
			beq	DoExitDeskTop		;Initialisierung.
			sta	r1L
			lda	fileHeader +5
			sta	r1H

			LoadW	r2,LOAD_REGISTER - BASE_CONFIG_TOOL
			LoadW	r7,BASE_CONFIG_TOOL
			jsr	ReadFile		;Initialisierung einlesen.
			txa				;Diskettenfehler?
			bne	DoExitDeskTop		; => Ja, Abbruch...

			jsr	BASE_CONFIG_TOOL	;Initialisierung starten.
			txa
			beq	DoAppStart		;GD.CONFIG ausführen.
			bmi	DoAutoBoot		;GEOS-AutoBoot ausführen.

;*** Zurück zum DeskTop.
:DoExitDeskTop		jmp	EnterDeskTop

;*** GD.CONFIG-Menü starten.
:DoAppStart		lda	Flag_TaskAktiv		;TaskManager-Status einlesen und
			sta	BootTaskMan		;zwischenspeichern.
			sta	Copy_BootTaskMan	;Status vor GD.CONFIG speichern.
			lda	#%10000000		;TaskManager deaktivieren.
			sta	Flag_TaskAktiv

			jmp	LoadCfgDrive		;Sprung zur Laufwerksauswahl.

;*** GEOS-AutoBoot.
:DoAutoBoot		jsr	LogoScreen		;GDOS64-Logo anzeigen.

			lda	#$00			;GEOS-Speicherbank #0
			ldx	#%11000000		;reservieren.
			jsr	DACC_ALLOC_BANK		;(GEOS-System)

			lda	MP3_64K_SYSTEM		;GDOS-Speicherbank SYSTEM
			ldx	#%11000000		;reservieren.
			jsr	DACC_ALLOC_BANK		;(MP3_64K_SYSTEM)

			lda	MP3_64K_DATA		;GDOS-Speicherbank DATA
			ldx	#%11000000		;reservieren.
			jsr	DACC_ALLOC_BANK		;(MP3_64K_DATA)

;Spooler+TaskMan+GeoHelp abschalten.
;Wenn die Konfigurationsmodule fehlen,
;dann werden die Funktionen nicht im
;System installiert!
			lda	#%00000000
			sta	HelpSystemActive	;GeoHelp deaktivieren.
			sta	Flag_Spooler		;Spooler deaktivieren.
			lda	#%10000000
			sta	Copy_BootTaskMan	;TaskManager deaktivieren.

;--- System-Farben initialisieren.
			jsr	i_MoveData		;GEOS-Farbprofil übernehmen.
			w	BootColorGEOS		;Damit werden auch die Icons beim
			w	COLVAR_BASE		;Startvorgang in der gespeicherten
			w	COLVAR_SIZE		;Farbe angezeigt.

;--- Config-Tools starten.
::StartCfgTools		jsr	BootInfoRAM		;Setup: Speicher
			jsr	LoadCfgRAM

			jsr	BootInfoInOut		;Setup: Drucker/Eingabegeräte
			jsr	LoadCfgInOut

			jsr	BootInfoDrive		;Setup: Laufwerke
			jsr	LoadCfgDrive

			jsr	BootInfoScreen		;Setup: Anzeige
			jsr	LoadCfgScreen

			jsr	BootInfoGEOS		;Setup: GEOS
			jsr	LoadCfgGEOS

			jsr	BootInfoHelp		;Setup: GeoHelp
			bit	BootHelpSysMode		;GeoHelp aktivieren?
			bpl	:1			; => Nein, weiter...
			jsr	LoadCfgHelp

::1			jsr	BootInfoTask		;Setup: TaskManager
			bit	BootTaskMan		;TaskManager aktivieren?
			bmi	:2			; => Nein, weiter...
			jsr	LoadCfgTask

::2			jsr	BootInfoSpool		;Setup: Spooler
			bit	BootSpooler		;Spooler aktivieren?
			bpl	:3			; => Nein, weiter...
			jsr	LoadCfgSpool

::3			lda	#NULL			;Menü-Flag löschen, damit kein
			sta	sysCurMenu		;Konfigurationstest ausgeführt wird.

;--- Reservierten Speicher freigeben.
			lda	BootBankAppl		;Speicher reserviert ?
			beq	ExitSetup		; => Nein, weiter...
			sta	r0L

			lda	ramExpSize
			sec
			sbc	#$01			;Zeiger auf letzte Speicherbank.

			sec
			sbc	#$02			;GDOS Speicherbank #1/#2.

			bit	BootHelpSysMode		;Hilfe installieren ?
			bpl	:free			; => Nein, weiter...
			sec
			sbc	#$01			;GDOS Speicherbank Hilfesystem.

::free			pha
			jsr	DACC_FREE_BANK		;Speicher freigeben.
			pla

			sec				;Zeiger auf nächste reservierte
			sbc	#$01			;64K-Speicherbank.
			beq	ExitSetup		;Bank #0 -> Nicht freigeben, Ende...

			dec	r0L			;Reservierter Speicher freigegeben ?
			bne	:free			; => Nein, weiter...

;*** Setup beenden (AutoBoot und Menü).
:ExitSetup		LoadW	r0,BASE_GCFG_DATA
			LoadW	r1,R3A_CFG_GDOS
			LoadW	r2,R3S_CFG_GDOS
			lda	MP3_64K_DATA
			sta	r3L
			jsr	StashRAM		;GD.INI in DACC aktualisieren.

			lda	SystemDevice		;Start-Laufwerk aktivieren.
			jsr	SetDevice
			jsr	OpenDisk		;Diskette/Partition initialisieren.

			lda	#NULL			;Modul-Nummer löschen. Damit wird
			sta	r14H			;bei GD.SCREEN das Farbprofil nicht
							;automatisch auf Disk gespeichert.

			jsr	SaveCfgMENU		;Aktuelle Einstellungen speichern.
			txa				;Konfigurationsfehler ?
			beq	:0			; => Nein, weiter...

			jmp	DoAppStart		;Zurück zum GD.CONFIG-Menü.

::0			lda	Copy_firstBoot		;GEOS/firstBoot-Flag zurücksetzen.
			sta	firstBoot

			lda	bufStackPointer		;Menü-Aufruf aus AutoBoot-Setup ?
			beq	:1			; => Nein, weiter...

;HINWEIS:
;Bei einem Konfigurationsfehler beim
;Startvorgang das Register-Menü vom
;Bildschirm löschen.
			jsr	LogoScreen		;GDOS64-Logo anzeigen.
			jmp	LoadCfgExitBoot		;AutoBoot-Setup fortsetzen.

::1			lda	Copy_BootTaskMan	;Taskmanager-Status festlegen.
			sta	Flag_TaskAktiv

;--- GD.CONFIG beenden.
			jsr	ResetScreen		;Bildschirm löschen.

;******************************************************************************
;Beim GEOS-BootUp wird der aktuelle Kernal erst am Ende des Bootvorgangs von
;der AutoBoot-Routine in der REU gespeichert.
;Wird GD.CONFIG als Anwendung gestartet, dann muß am Ende der Kernal
;in der REU gespeichert werden, da sonst Änderungen beim RBOOT nicht
;berücksichtigt werden!
;******************************************************************************
			bit	firstBoot		;GEOS-BootUp ?
			bmi	Update_Kernel		; => Nein, weiter...

			jsr	Fetch_AutoBoot		;AutoBoot-Routine einlesen.
			jmp	EnterDeskTop		;Zurück zum DeskTop/Boot-Routine.

;--- Ende, zum DeskTop zurück.
:Update_Kernel		jsr	_DDC_UPDATEKERNAL	;Kernal für RBOOT aktualisieren.
			jmp	EnterDeskTop		;Zurück zum DeskTop/Boot-Routine.

;******************************************************************************

;*** BootUp-Information anzeigen.
:BootInfoSpool		lda	#< Icon_CfgSpool
			ldx	#> Icon_CfgSpool
			ldy	#$23
			jsr	BootInfoIcon
:BootInfoTask		lda	#< Icon_CfgTask
			ldx	#> Icon_CfgTask
			ldy	#$1e
			jsr	BootInfoIcon
:BootInfoHelp		lda	#< Icon_CfgHelp
			ldx	#> Icon_CfgHelp
			ldy	#$19
			jsr	BootInfoIcon
:BootInfoGEOS		lda	#< Icon_CfgGEOS
			ldx	#> Icon_CfgGEOS
			ldy	#$14
			jsr	BootInfoIcon
:BootInfoScreen		lda	#< Icon_CfgScreen
			ldx	#> Icon_CfgScreen
			ldy	#$0f
			jsr	BootInfoIcon
:BootInfoDrive		lda	#< Icon_CfgDrive
			ldx	#> Icon_CfgDrive
			ldy	#$0a
			jsr	BootInfoIcon
:BootInfoInOut		lda	#< Icon_CfgInOut
			ldx	#> Icon_CfgInOut
			ldy	#$05
			jsr	BootInfoIcon
:BootInfoRAM		lda	#< Icon_CfgRAM
			ldx	#> Icon_CfgRAM
			ldy	#$00
:BootInfoIcon		sta	r0L
			stx	r0H
			sty	r1L
			sty	:1			;Icon-Position speichern.
			LoadB	r1H,$b0
			LoadB	r2L,$05			;Breite in CARDs.
			LoadB	r2H,$18			;Höhe in Pixel.
			jsr	BitmapUp		;Icon darstellen.

			lda	C_WinIcon		;Farbe setzen.
			jsr	i_UserColor
::1			b	$ff,$16,$05,$03

			lda	#NULL
			sta	sysCurMenu
			rts

;*** Konfigurationsmenü nachladen.
:LoadCfgRAM		lda	#CFG_MOD_RAM		;RAM.
			b $2c
:LoadCfgInOut		lda	#CFG_MOD_DEV		;Ein-/Ausgabegeräte.
			b $2c
:LoadCfgDrive		lda	#CFG_MOD_DRIVE		;Laufwerksauswahl.
			b $2c
:LoadCfgScreen		lda	#CFG_MOD_SCREEN		;Anzeige.
			b $2c
:LoadCfgGEOS		lda	#CFG_MOD_GEOS		;GEOS.
			b $2c
:LoadCfgHelp		lda	#CFG_MOD_HELP		;Hilfesystem.
			b $2c
:LoadCfgTask		lda	#CFG_MOD_TASK		;TaskManager.
			b $2c
:LoadCfgSpool		lda	#CFG_MOD_SPOOL		;Spooler.
			cmp	sysCurMenu		;Modul bereits geöffnet ?
			beq	:exit			; => Ja, Ende...

			sta	r14H			;Neue Modul-Nr. merken.

			bit	firstBoot
			bpl	:skip

			jsr	SaveCfgMENU		;Konfigurationsdaten speichern.
			txa				;Konfigurationsfehler ?
			bne	:exit			; => Ja, Ende...

::skip			jsr	LoadCfgTool		;Konfigurationsmenü laden.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Ende...

;--- Konfigurationsmenü starten.
;			lda	#$00			;":appMain"-Vektor löschen. Wird
			sta	appMain +0		;z.B. von Modul "GEOS" für SCPU-
			sta	appMain +1		;Abfrage gesetzt.
			sta	otherPressVec +0	;Evtl. aktives Register-Menü
			sta	otherPressVec +1	;deaktivieren.

			lda	r14H			;Menü-Nr. speichern.
			sta	sysCurMenu

			bit	firstBoot		;GEOS-BootUp ?
			bpl	:boot			; => Ja, weiter...

			jsr	DrawCfgMenu		;Bildschirm löschen.
			jmp	BASE_CONFIG_TOOL	;Konfigurationsmenü starten.

;--- Fehler beim laden eines Setup-Tools.
::1			bit	firstBoot		;GEOS-BootUp ?
			bpl	:2			; => Ja, Ende...

			LoadW	r0,Dlg_NoCfgFile
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

::2			ldx	sysCurMenu		;Systemdatei-Fehler ?
			dex				;(Nur GD.CONFIG.DRIVE)
			bne	:exit			; => Nein, weiter...

			LoadW	r0,Dlg_CfgFileErr	;Start abbrechen und
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

::exit			rts

;--- Konfiguration starten.
::boot			lda	sysCurMenu
			cmp	#CFG_MOD_DRIVE		;Laufwerke konfigurieren?
			beq	:drive			; => Ja, weiter...

;--- RAM, SCREEN, SYSDEV...
::other			jmp	BASE_GCFG_BOOT		;Konfiguration starten.

;--- Sonderbehandlung: Laufwerke.
::drive			jsr	BASE_CONFIG_TOOL	;Konfiguration starten.
			jsr	BASE_CONFIG_TEST	;GEOS-Konfiguration testen.
			txa				;Gültig ?
			beq	:exit			; => Ja, weiter...

;--- Konfigurationsfehler:
;Nur für Laufwerke während GEOS-BootUp.
; => Hauptmenü nachladen.
:LoadErrCfgMenu		tsx
			stx	bufStackPointer		;Stack-Position speichern.

			lda	#$ff			;GEOS-Boot-Flag löschen.
			sta	firstBoot

			jsr	DrawCfgMenu		;Bildschirm löschen.
			jsr	BASE_CONFIG_TOOL	;Konfigurationsmenü starten.

			jmp	MainLoop		;Zur MainLoop.

;*** Hauptmenü während GEOS-BootUp verlassen.
:LoadCfgExitBoot	ldx	bufStackPointer		;StackPointer zurücksetzen.
			txs

			lda	#$00			;AutoBoot-Flag löschen.
			sta	bufStackPointer

			lda	Copy_firstBoot		;GEOS-Boot-Flag zurücksetzen und
			sta	firstBoot		;zurück zur AutoBoot-Routine des
			rts				;Hauptprogramms.

;*** Konfigurationsmenü nachladen.
:LoadCfgTool		lda	SystemDevice
			cmp	#12			;GEOS-Laufwerk?
			bcs	:skip			; => Nein, weiter...
			cmp	curDevice		;Laufwerk bereits aktiv?
			beq	:skip			; => Ja, weiter...

			jsr	SetDevice		;Systemlaufwerk öffnen und

;--- Hinweis:
;Ohne OpenDisk stürzt GDOS64 beim Start
;von der CMD-HD nach dem "GEOS"-Modul
;während des ladens vom "GEOEHLP"-
;Modul/Init ab. Dabei werden falsche
;Daten von der HD gelesen. Evtl. muss
;der Treiber nach dem "GEOS"-Modul und
;dem lesen der Uhrzeit initialisiert
;werden. Weitere Tests erforderlich...
;OpenDisk umgeht aktuell das Problem.
::skip			jsr	OpenDisk		;Treiber initialisieren.

			lda	r14H			;Zeiger auf Class-Info berechnen.
			sec
			sbc	#$01
			asl
			tax
			lda	sysCfgInitAdr +0,x
			beq	:load			; => Keine ext.Konfiguration...

			bit	firstBoot		;GEOS-BootUp?
			bpl	:boot			; => Ja, ext.Konfiguration laden.

;--- Konfigurations-Menü laden.
::load			lda	sysCfgToolNmVec +0,x
			sta	r15L
			lda	sysCfgToolNmVec +1,x
			sta	r15H			;Zeiger auf Modul-Name einlesen.

			lda	sysCfgToolAdr +0,x
			beq	:err			; => Fehler, Modul nicht vorhanden.
			sta	r1L
			lda	sysCfgToolAdr +1,x
			sta	r1H

::read			LoadW	r2,LOAD_REGISTER - BASE_CONFIG_TOOL
			LoadW	r7,BASE_CONFIG_TOOL
			jsr	ReadFile		;Konfigurationsmodul einlesen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#8 -1			;Systemkennung überprüfen.
::verify		lda	sysCfgCode,y
			cmp	BASE_CONFIG_TOOL +9,y
			bne	:err			; => Fehler, Abbruch...
			dey
			bpl	:verify

;--- Konfiguration laden.
::boot			lda	r14H			;Modul-Nr. einlesen und
			sec
			sbc	#$01
			asl
			tax
			lda	sysCfgInitAdr +0,x
			beq	:ok			; => Keine ext.Konfiguration...
			sta	r1L
			lda	sysCfgInitAdr +1,x
			sta	r1H

			LoadW	r2,SIZE_GCFG_BOOT
			LoadW	r7,BASE_GCFG_BOOT
			jsr	ReadFile		;Externe Routinen einlesen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

::ok			ldx	#NO_ERROR		;Kein Fehler...
			rts

::err			ldx	#FILE_NOT_FOUND		;Nicht gefunden, Abbruch...
::exit			rts

;*** VLIR-Header einlesen.
.LoadVlirHdr		sec
			sbc	#$01
			asl
			tax
			lda	sysCfgToolNmVec +0,x
			sta	r6L
			lda	sysCfgToolNmVec +1,x
			sta	r6H
			jsr	FindFile		;Konfigurationsmodul suchen.
			txa				;Diskettenfehler?
			bne	errVlirHdr		; => Ja, Abbruch...

:GetCurVlirHdr		lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header einlesen.

:errVlirHdr		rts

;*** Aktuelle Einstellungen speichern.
:SaveCfgMENU		ldx	sysCurMenu		;Konfigurationsmenü geladen ?
			beq	:1			; => Nein, weiter...
			jsr	BASE_CONFIG_SAVE	;Einstellungen aktualsieren.
::1			rts

;*** Aktuelle Konfiguration speichern.
:SaveCfgBOOT		lda	sysCurMenu
			sta	r14H			;Modul-Nr. speichern.
			jsr	SaveCfgMENU		;Einstellungen aktualsieren.

			lda	SystemDevice		;Start-Laufwerk aktivieren.
			jsr	SetDevice

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			LoadW	r6,FNamGDINI
			jsr	FindFile		;GD.INI suchen.
			txa				;Datei gefunden?
			beq	:replace		; => Ja, weiter...

			cpx	#FILE_NOT_FOUND
			beq	:create			;Nicht vorhanden, speichern...
::err			jmp	:error			; => Diskfehler, Abbruch...

::replace		LoadW	r0,FNamGDINI
			jsr	DeleteFile		;Vorhandene GD.INI löschen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...

::create		LoadB	r10L,0
			LoadW	r9,HdrB000
			jsr	SaveFile		;Neue GD.INI erzeugen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...

::1			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;GDOS-Konfiguration einlesen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			ldy	#0
::2			lda	BASE_GCFG_DATA,y	;Konfiguration aktualisieren.
			sta	diskBlkBuf +2,y
			iny
			cpy	#R3S_CFG_GDOS
			bcc	:2

			jsr	PutBlock		;Konfiguration speichern.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			lda	diskBlkBuf +0
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
;			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;GeoDesk-Konfiguration einlesen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			PushB	r1L			;Sektor-Adresse zwischenspeichern.
			PushB	r1H

			LoadW	r0,diskBlkBuf +2
			LoadW	r1,R3A_CFG_GDSK
			LoadW	r2,R3S_CFG_GDSK
			lda	MP3_64K_DATA
			sta	r3L
			jsr	FetchRAM		;Konfiguration aktualisieren.

			PopB	r1H			;Sektor-Adresse zurücksetzen.
			PopB	r1L

			jsr	PutBlock		;Konfiguration speichern.
			txa				;Diskettenfehler ?
			beq	:exit			; => Nein, Ende...

;*** Konfiguration konnte nicht gespeichert werden.
;Übergabe: XReg = Fehlercode.
::error			txa				;Fehlercode zwischenspeichern.
;			pha

;			lda	#error
			jsr	SysHEX2ASCII		;Fehlercode nach ASCII wandeln und
			stx	DiskErrCode +1		;in Fehlermeldung übernehmen.
			sta	DiskErrCode +2

			LoadW	r0,Dlg_SvCfgError
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

;			pla
;			tax				;Fehlercode wieder herstellen.

::exit			rts

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w FNamGDINI
::002			b $03,$15
			b $bf
			b %10101010,%10101010,%10101011
			b %01010101,%01010101,%01010111
			b %10000000,%00000000,%00000011
			b %01001111,%00111110,%00000011
			b %10011000,%00110011,%00000011
			b %01011011,%10110011,%00000011
			b %10011001,%10110011,%00000011
			b %01001111,%10111110,%00000011
			b %10000000,%00000000,%00000011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01001000,%10100101,%00010011
			b %10001100,%10110101,%00110011
			b %01001100,%10101101,%00110011
			b %10001000,%10100101,%00010011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01111111,%11111111,%11111111
			b %11111111,%11111111,%11111111

::068			b $82				;PRG
			b SYSTEM			;GEOS-Systemdatei
			b $00				;GEOS-Dateityp SEQUENTIELL

;--- Speicherbereich GD.INI definieren.
::data_start		= BASE_GCFG_DATA
			w :data_start			;Programm-Anfang

::data_end		= BASE_GCFG_DATA +R3S_CFG_GDOS +R3S_CFG_GDSK
			w :data_end			;Programm-Ende

			w $0000				;Programm-Start
::077			t "opt.INI.Build"		;Klasse/Version
			b $00				;Bildschirmflag
::097			b "GDOS64"			;Autor
			s 14				;Reserviert
			s 12  				;Anwendung/Klasse
			s 4  				;Anwendung/Version
			b NULL
			s 26				;Reserviert
::160			b NULL				;Infotext

;::HdrEnd		s (HdrB000+256)-:HdrEnd

;*** Bildschirm neu zeichnen.
:xDrawCfgMenu		lda	#ST_WR_FORE		;Grafik nur im Vordergrund.
			sta	dispBufferOn

			jsr	GetBackScreen		;Hintergrundbild laden.

			lda	#$00			;Fenster für Hauptmenü zeichnen.
			jsr	SetPattern
			jsr	i_Rectangle		;Titelzeile für Menüfenster.
			b	$00,$07
			w	$0000,$013f
			lda	C_WinTitel
			jsr	DirectColor

			LoadW	r0,configTitle		;Titelzeile ausgeben.
			jsr	PutString

			lda	C_WinIcon		;Farbe für Menü-Icons setzen.
			jsr	i_UserColor
			b	$00,$01,$28,$03
			lda	C_WinIcon		;Farbe für Beenden-Icon setzen.
			jsr	i_UserColor
			b	$00,$05,$05,$03
			lda	C_WinIcon		;Farbe für Speichern-Icon setzen.
			jsr	i_UserColor
			b	$00,$09,$05,$03

			LoadW	r0,Icon_Menu		;Iconmenü aktivieren.
			jmp	DoIcons

;*** Registermenü laden.
;Übergabe: A/X = Zeiger auf Registermenü-Tabelle.
;                $0000: Nur Registermenü laden.
.EnableRegMenu		pha
			txa
			pha

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont

			pla
			sta	r0H
			pla
			sta	r0L
			ora	r0H
			beq	:exit

			jsr	DoRegister

::exit			rts

;*** AutoBoot-Routine laden/speichern.
:Fetch_AutoBoot		ldy	#jobFetch
			b $2c
:Stash_AutoBoot		ldy	#jobStash
			LoadW	r0 ,BASE_AUTO_BOOT
			LoadW	r1 ,R3A_AUTOBBUF
			LoadW	r2 ,SIZE_AUTO_BOOT
			lda	MP3_64K_DATA
			sta	r3L
			jmp	DoRAMOp

;*** Variablen.
:bufStackPointer	b $00
:sysCurMenu		b $00  ;>$00 = Modul geöffnet.

;*** Systemkennung für GD.CONFIG.
:sysCfgCode		b "GDCONF10"

;*** Daten für GD.INI-Datei.
:FNamGDINI		b "GD.INI"
			e FNamGDINI +17
:ClassGDINI		t "opt.INI.Build"

;*** Titelzeile.
:configTitle		b PLAINTEXT
			b GOTOXY
			w $0008
			b $06
if LANG = LANG_DE
			b "GDOS64 - System konfigurieren"
endif
if LANG = LANG_EN
			b "GDOS64 - Configure system"
endif
			b NULL

;*** Daten für Konfigurationsmodule.
.sysCfgToolNmVec	w :tabCfgNames +17 *0
			w :tabCfgNames +17 *1
			w :tabCfgNames +17 *2
			w :tabCfgNames +17 *3
			w :tabCfgNames +17 *4
			w :tabCfgNames +17 *5
			w :tabCfgNames +17 *6
			w :tabCfgNames +17 *7

::tabCfgNames
::ram			b "GD.CONF.RAM"
::ram_e			s 17 - (:ram_e - :ram)
::prninpt		b "GD.CONF.PRNINPT"
::prninpt_e		s 17 - (:prninpt_e - :prninpt)
::drives		b "GD.CONF.DRIVES"
::drives_e		s 17 - (:drives_e - :drives)
::screen		b "GD.CONF.SCREEN"
::screen_e		s 17 - (:screen_e - :screen)
::geos			b "GD.CONF.GEOS"
::geos_e		s 17 - (:geos_e - :geos)
::geohelp		b "GD.CONF.GEOHELP"
::geohelp_e		s 17 - (:geohelp_e - :geohelp)
::taskman		b "GD.CONF.TASKMAN"
::taskman_e		s 17 - (:taskman_e - :taskman)
::spooler		b "GD.CONF.SPOOLER"
::spooler_e		s 17 - (:spooler_e - :spooler)
			b NULL

.sysCfgToolAdr		b $00,$00			;RAM
			b $00,$00			;Print/Input
			b $00,$00			;Drives
			b $00,$00			;Screen
			b $00,$00			;GEOS
			b $00,$00			;GeoHelp
			b $00,$00			;TaskMan
			b $00,$00			;Spooler

.sysCfgInitAdr		b $00,$00			;RAM
			b $00,$00			;Print/Input
			b $00,$00			;Drives
			b $00,$00			;Screen
			b $00,$00			;GEOS
			b $00,$00			;GeoHelp
			b $00,$00			;TaskMan
			b $00,$00			;Spooler

;*** Dialogboxen.
if LANG = LANG_DE
.DLG_T_ERR		b PLAINTEXT,BOLDON
			b "FEHLER!",0
.DLG_T_INF		b PLAINTEXT,BOLDON
			b "INFORMATION",0
endif
if LANG = LANG_EN
.DLG_T_ERR		b PLAINTEXT,BOLDON
			b "ERROR!",0
.DLG_T_INF		b PLAINTEXT,BOLDON
			b "INFORMATION",0
endif

;*** Dialogbox: Anwendung nicht gefunden.
:Dlg_NoCfgFile		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_INF
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBVARSTR   ,$20,$36
			b r15L
			b DBTXTSTR   ,$0c,$42
			w :3
			b OK         ,$01,$50
			b NULL
if LANG = LANG_DE
::1			b "Konfigurationsmodul laden",0
::2			b "ist nicht möglich. Die Datei:",0
::3			b "wurde nicht gefunden!",0
endif
if LANG = LANG_EN
::1			b "Loading configuration file failed.",0
::2			b "The following file:",0
::3			b "was not found!",0
endif

;*** Dialogbox: Setup-Datei fehlt.
:Dlg_CfgFileErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBVARSTR   ,$20,$36
			b r15L
			b NULL
if LANG = LANG_DE
::1			b "Systemstart abgebrochen. Die",0
::2			b "folgende System-Datei fehlt:",0
endif
if LANG = LANG_EN
::1			b "Start cancelled. The following",0
::2			b "system file was not found:",0
endif

;*** Dialogbox: Konfiguration kann nicht gespeichert werden.
:Dlg_SvCfgError		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$0c,$40
			w :3
			b DBTXTSTR   ,$54,$40
			w DiskErrCode
			b OK         ,$01,$50
			b NULL
if LANG = LANG_DE
::1			b "Speichern der Konfiguration",0
::2			b "ist fehlgeschlagen!",0
::3			b "Fehlercode:",0
endif
if LANG = LANG_EN
::1			b "Saving configuration to",0
::2			b "disk has failed!",0
::3			b "Error code: $",0
endif

:DiskErrCode		b "$XX",0

;*** Icon-Menü.
:Icon_Menu		b $0a
			w $0000
			b $00

			w Icon_CfgExit
			b $00,$28,Icon_CfgExit_x,Icon_CfgExit_y
			w ExitSetup

			w Icon_CfgSave
			b $00,$48,Icon_CfgSave_x,Icon_CfgSave_y
			w SaveCfgBOOT

;HINWEIS:
;Die Reihenfolge der Icons entspricht
;dem Startvorgang von GDOS64.

			w Icon_CfgRAM
			b $00,$08,Icon_CfgRAM_x,Icon_CfgRAM_y
			w LoadCfgRAM

			w Icon_CfgInOut
			b $05,$08,Icon_CfgInOut_x,Icon_CfgInOut_y
			w LoadCfgInOut

			w Icon_CfgDrive
			b $0a,$08,Icon_CfgDrive_x,Icon_CfgDrive_y
			w LoadCfgDrive

			w Icon_CfgScreen
			b $0f,$08,Icon_CfgScreen_x,Icon_CfgScreen_y
			w LoadCfgScreen

			w Icon_CfgGEOS
			b $14,$08,Icon_CfgGEOS_x,Icon_CfgGEOS_y
			w LoadCfgGEOS

			w Icon_CfgHelp
			b $19,$08,Icon_CfgHelp_x,Icon_CfgHelp_y
			w LoadCfgHelp

			w Icon_CfgTask
			b $1e,$08,Icon_CfgTask_x,Icon_CfgTask_y
			w LoadCfgTask

			w Icon_CfgSpool
			b $23,$08,Icon_CfgSpool_x,Icon_CfgSpool_y
			w LoadCfgSpool

;*** Icons.
if LANG = LANG_DE
:Icon_CfgExit
<MISSING_IMAGE_DATA>
endif

if LANG = LANG_EN
:Icon_CfgExit
<MISSING_IMAGE_DATA>
endif

:Icon_CfgExit_x			= .x
:Icon_CfgExit_y			= .y

if LANG = LANG_DE
:Icon_CfgSave
<MISSING_IMAGE_DATA>
endif

if LANG = LANG_EN
:Icon_CfgSave
<MISSING_IMAGE_DATA>
endif

:Icon_CfgSave_x			= .x
:Icon_CfgSave_y			= .y

:Icon_CfgDrive
<MISSING_IMAGE_DATA>
:Icon_CfgDrive_x		= .x
:Icon_CfgDrive_y		= .y

:Icon_CfgTask
<MISSING_IMAGE_DATA>
:Icon_CfgTask_x			= .x
:Icon_CfgTask_y			= .y

:Icon_CfgSpool
<MISSING_IMAGE_DATA>
:Icon_CfgSpool_x		= .x
:Icon_CfgSpool_y		= .y

:Icon_CfgInOut
<MISSING_IMAGE_DATA>
:Icon_CfgInOut_x		= .x
:Icon_CfgInOut_y		= .y

:Icon_CfgScreen
<MISSING_IMAGE_DATA>
:Icon_CfgScreen_x		= .x
:Icon_CfgScreen_y		= .y

:Icon_CfgGEOS
<MISSING_IMAGE_DATA>
:Icon_CfgGEOS_x			= .x
:Icon_CfgGEOS_y			= .y

:Icon_CfgRAM
<MISSING_IMAGE_DATA>
:Icon_CfgRAM_x			= .x
:Icon_CfgRAM_y			= .y

:Icon_CfgHelp
<MISSING_IMAGE_DATA>
:Icon_CfgHelp_x			= .x
:Icon_CfgHelp_y			= .y

;******************************************************************************
;*** Startadresse für Konfigurationsmodule festlegen.
;******************************************************************************
:TEMP
.BASE_CONFIG_TOOL =	((>TEMP) +1) * 256
.BASE_CONFIG_SAVE	=	BASE_CONFIG_TOOL +3
.BASE_CONFIG_TEST	=	BASE_CONFIG_TOOL +6
;******************************************************************************

;******************************************************************************
;*** Auf GDOS testen.
;******************************************************************************
			t "-G3_FindGD"
;******************************************************************************

;******************************************************************************
;*** Endadresse für GD.UPDATE testen.
;******************************************************************************
			g BASE_AUTO_BOOT
;******************************************************************************
