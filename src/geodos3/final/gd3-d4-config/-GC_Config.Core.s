; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemvariablen.
.Boot_StartData
.BootConfig		b $00,$00,$00,$00
.BootPartRL		b $00,$00,$00,$00
.BootPartRL_I		b $00,$00,$00,$00
.BootPartType		b $00,$00,$00,$00
.BootRamBase		b $00,$00,$00,$00

.BootMenuStatus		b %11100000
.BootMLineMode		b $00
.BootColsMode		b $80
.BootCRSR_Repeat	b $03
.BootSpeed		b $00
.BootOptimize		b $00
.BootRTCdrive		b $ff				;$fe=-,$10=FD,$20=HD,$30=RL,$FE=SmartMouse,$FF=Auto

;*** Systemvariablen.
;    Bit#7: 0=Kein REU-MoveData
;    Bit#6: 1=Laufwerkstreiber in REU
;    Bit#5: 1=ReBoot-Daten in REU
;    Bit#4: 1=ReBoot-Kernal in REU
;    Bit#3: 1=Hintergrundbild aktiv
.BootRAM_Flag		b %00001000			;Bit#3=1: Hintergrund aktiv.

.BootScrSaver		b %01000000			;Bit#7=0: Aktiv, Bit#6=1:Neustart.
.BootScrSvCnt		b $0f

.BootSaverName		b "Starfield"
;--- Ergänzung: 02.02.21/M.Kanet:
;Sicherstellen das genügend Speicher
;für lange Dateinamen verfügbar ist.
			e BootSaverName+17

.BootGrfxFile		b "GD.LOGO"
;--- Ergänzung: 02.02.21/M.Kanet:
;Sicherstellen das genügend Speicher
;für lange Dateinamen verfügbar ist.
			e BootGrfxFile+17

.BootPattern		b $02

.BootPrntMode		b $00
.BootGCalcFix		b $80				;$80 = GCalcFix aktiv.
.BootPrntName		s 17
.BootInptName		s 17

;--- Ergänzung: 03.01.19/M.Kanet
;Option für QWERTZ ergänzt.
if Sprache = Deutsch
.BootQWERTZ		b $ff				;$FF = QWERTZ aktiv.
endif

.BootSpooler		b $80				;$80 = Spooler aktivieren.
.BootSpoolCount		b $03				;Aktivierungszeit Spooler.
.BootSpoolSize		b $01				;Größe Spooler beim ersten Start automatisch setzen!

.BootTaskMan		b $00
.BootTaskSize		b $03
.BootTaskStart		b $00

.BootBankBlocked	s RAM_MAX_SIZE
.BootBankAppl		b $04				;4x64K für GeoDesk64 reservieren.

.BootHelpSysMode	b $ff
.BootHelpSysDrv		b $00
.BootHelpSysPart	b $00

;--- Ergänzung: 22.12.18/M.Kanet
;Falls eine HD nur über den IEC-Bus angeschlossen ist kann es unter bestimmten
;Umständen zu Problemen bei der Hardware-Erkennung kommen.
;Parallel-Kabel standardmäßig deaktivieren.
;.BootUseFastPP		b $80
.BootUseFastPP		b $00				;$80 = Aktiv.

;--- Ergänzung: 10.08.21/M.Kanet
;Support für Boot-Konfiguration ergänzt.
if GD_NG_MODE = TRUE
.BootDrvReplace		b $ff				;$FF = Start von #8 bis #11 = A: bis D: ersetzen.
							;$00 = Tauschen wenn in Konfiguration vorhanden.
.BootDrvRAMLink		b $00				;$00 = AUTO oder $08-$0B für GEOS-Laufwerk A: bis D:.
endif

;--- Ergänzung: 18.07.21/M.Kanet
;Support für DeskTop-Name ergänzt.
.BootNameDT		b "GEODESK"
::1			s 9  - (:1 - BootNameDT)
.BootFileDT		b "GEODESK"
::1			s 17 - (:1 - BootFileDT)

;*** Farbtabelle.
.BootC_FarbTab						;Beginn der Farbtabelle.
.BootC_Balken			b $01			;Scrollbalken.
.BootC_Register			b $0e			;Karteikarten: Aktiv.
.BootC_RegisterOff	b $03				;Karteikarten: Inaktiv.
.BootC_RegisterBack	b $0e				;Karteikarten: Hintergrund.
.BootC_Mouse			b $66			;Mausfarbe.
.BootC_DBoxTitel		b $16			;Dialogbox: Titel.
.BootC_DBoxBack			b $0e			;Dialogbox: Hintergrund + Text.
.BootC_DBoxDIcon		b $01			;Dialogbox: System-Icons.
.BootC_FBoxTitel		b $16			;Dateiauswahlbox: Titel.
.BootC_FBoxBack			b $0e			;Dateiauswahlbox: Hintergrund/Text.
.BootC_FBoxDIcon		b $01			;Dateiauswahlbox: System-Icons.
.BootC_FBoxFiles		b $03			;Dateiauswahlbox: Dateifenster.
.BootC_WinTitel			b $0d			;Fenster: Titl.
.BootC_WinBack			b $01			;Fenster: Hintergrund.
.BootC_WinShadow		b $00			;Fenster: Schatten.
.BootC_WinIcon			b $0d			;Fenster: System-Icons.
.BootC_PullDMenu		b $03			;PullDown-Menu.
.BootC_InputField		b $01			;Text-Eingabefeld.
.BootC_InputFieldOff	b $0f				;Inaktives Optionsfeld.
.BootC_GEOS_BACK		b $bf			;GEOS-Standard: Hintergrund.
.BootC_GEOS_FRAME		b $00			;GEOS-Standard: Rahmen.
.BootC_GEOS_MOUSE		b $66			;GEOS-Standard: Mauszeiger.

;*** Initialisierungsbyte für Laufwerksinstallaton.
;    Dieses Byte hat immer den Wert $FF wenn die Konfiguration
;    mindestens 1x gespeichert wurde.
.BootInstalled		b $00
.Boot_EndData

;*** Kopie von ":firstBoot"-Flag.
.Copy_firstBoot		b $00

;*** Kopie Initialisierungsbyte für Laufwerksinstallaton.
.Copy_BootInstalled	b $00

;*** Initialisierungsbyte für TaskManager.
;    Dieses Byte hat immer den Wert $FF= 'Nicht installieren'.
;    Wird das externe Tool 'GD.CONFIG.TaskMan' gestartet, so wird dieses
;    Byte modifiziert und das Hauptprogramm kann den TaskMan aktivieren.
.Copy_BootTaskMan	b $ff

;*** Systemvariablen.
.SystemDevice		b $00
.SysFileClass		t "src.Config.Build"
.SysFileName		s 17

;*** Einsprungtabelle.
.DrawCfgMenu		jmp	xDrawCfgMenu

.OpenFile		jmp	xOpenFile

.GetFreeBank		jmp	FindFree64K
.GetFreeBankTab		jmp	FindFreeRAM
.GetFreeBankL		jmp	LastFree64K
.GetFreeBankLTab	jmp	LastFreeRAM
.AllocateBank		jmp	Alloc64K
.AllocateBankTab	jmp	AllocRAM
.FreeBank		jmp	Free64K
.FreeBankTab		jmp	FreeRAM
.BankUsed_GetByte	jmp	GetBankByte
.BankUsed_Type		jmp	GetBankType

;*** Menü initialisieren.
:InitSetup		jsr	FindGD3			;GD3/MP3-Kernal suchen.

if GD_NG_MODE = TRUE
			jsr	InitDiskCoreData
endif

;--- Ergänzung: 26.02.21/M.Kanet
;Kein BackScreen-Buffer verwenden, da
;die einzelnen Konfigurations-Module
;den Speicherbereich bis zum Beginn
;des Register-Menüs verwenden dürfen!
			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	firstBoot		;GEOS-BootUp-Flag merken.
			sta	Copy_firstBoot

			lda	BootInstalled		;Flag für Setup-Erststart merken.
			sta	Copy_BootInstalled
			lda	#$ff
			sta	BootInstalled

;--- Hinweis:
;":curDevice" an Stelle von ":curDrive"
;verwenden, da beim Systemstart von
;einem Laufwerk #12 ":curDrive" auf
;das Laufwerk A: umgestellt wurde.
			lda	curDevice		;Start-Laufwerk speichern.
			sta	SystemDevice		;Bei CMD-HD/RL auch >= #12!

			jsr	LogoScreen		;Titellogo zeichnen.

;*** Menü starten/AutoBoot ausführen.
:DoSetupJob		bit	firstBoot		;GEOS-BootUp ?
			bmi	DoAppStart		; => Nein, weiter...
			jmp	DoAutoBoot

;*** Menü starten.
:DoAppStart		lda	Flag_TaskAktiv		;TaskManager-Status einlesen und
			sta	BootTaskMan		;zwischenspeichern.
			sta	Copy_BootTaskMan
			lda	#$ff			;TaskManager deaktivieren.
			sta	Flag_TaskAktiv

if GD_NG_MODE = FALSE
			jsr	xGetAllSerDrives	;Ser. Geräte erkennen. Wichtig für
							;Laufwerksauswahl und RTC-Auswahl.
endif

			jmp	LoadCfgDrive		;Sprung zur Laufwerksauswahl.

;*** AutoBoot
:DoAutoBoot		jsr	Stash_AutoBoot		;AutoBoot-Routine retten.

if GD_NG_MODE = FALSE
			jsr	xGetAllSerDrives	;Ser. Geräte erkennen. Wichtig für
							;Laufwerksauswahl und RTC-Auswahl.

			ldx	SystemDevice
			cpx	#12			;Start von Laufwerk >=12 ?
			bcc	:ok			; => Nein, weiter...

			lda	devInfo -8,x
			and	#%11111000
			cmp	#DrvRAMLink		;Start von CMD-RAMLink ?
			beq	:ok			; => Ja, Adresse >=12 i.O.

			LoadW	r0,Dlg_BootAdrErr	;Fehler ausgeben.
			jmp	DoDlgBox		;Ende...
::ok
endif

			lda	#$00			;GEOS-Speicherbank #0
			ldx	#%11000000		;reservieren.
			jsr	Alloc64K		;(GEOS-System)

;--- Ergänzung: 20.05.21/M.Kanet
;Speicher für GeoDOS und ggf. für
;Anwendungen wie GeoDesk reservieren.
			lda	ramExpSize
			cmp	#$08 +1			;Mehr als 512K GEOS-DACC ?
			bcs	:skip			; => Ja, weiter...

			lda	#$00			;Nicht genügend Speicher, das
			sta	BootHelpSysMode		;Hilfesystem abschalten.

::skip			lda	#$02			;GeoDOS Speicherbank #1/#2.
			bit	BootHelpSysMode		;Hilfe installieren ?
			bpl	:1			; => Nein, weiter...
			clc				;Speicherbank für Hilfesystem
			adc	#$01			;reservieren.
::1			clc
			adc	BootBankAppl		;Für Anwendungen reservierter
			sta	r0L			;Speicher addieren.

			lda	ramExpSize
::alloc			sec
			sbc	#$01			;Gesamter Speicher belegt ?
			beq	:StartCfgTools		; => Ja, Abbruch...
			pha
			ldx	#%11000000
			jsr	Alloc64K		;64K-Speicherbank reservieren.
			pla
			dec	r0L			;Speicher reserviert ?
			bne	:alloc			; => Nein, weiter...

;--- Config-Tools starten.
::StartCfgTools		jsr	BootInfoRAM		;Setup: TaskManager
			jsr	LoadCfgRAM

			jsr	BootInfoDrive		;Setup: Laufwerke
			jsr	LoadCfgDrive

			jsr	BootInfoScreen		;Setup: Anzeige
			jsr	LoadCfgScreen

			jsr	BootInfoGEOS		;Setup: GEOS
			jsr	LoadCfgGEOS

			jsr	BootInfoInOut		;Setup: Drucker/Eingabegeräte
			jsr	LoadCfgInOut

			bit	BootHelpSysMode		;Hilfe installieren ?
			bpl	:2			; => Nein, weiter...
			lda	ramExpSize
;			sec				;Letze Speicherbank = DACC -1.
;			sbc	#$01
			sec				;2x64K für GD3-System abziehen.
			sbc	#$02 +1			;Bank-Adresse Hilfesystem berechnen.
			jsr	Free64K			;Speicher freigeben.

::2			jsr	BootInfoHelp		;Setup: GeoHelp
			jsr	LoadCfgHelp

			jsr	BootInfoTask		;Setup: TaskManager
			jsr	LoadCfgTask

			jsr	BootInfoSpool		;Setup: Spooler
			jsr	LoadCfgSpool

;--- Ergänzung: 20.05.21/M.Kanet
;Reservierten Speicher für GeoDesk
;wieder freigeben.
			lda	BootBankAppl		;Speicher reserviert ?
			beq	ExitSetup		; => Nein, weiter...
			sta	r0L

			lda	ramExpSize
			sec
			sbc	#$01

			sec
			sbc	#$02			;GeoDOS Speicherbank #1/#2.

			bit	BootHelpSysMode		;Hilfe installieren ?
			bpl	:free			; => Nein, weiter...
			sec
			sbc	#$01			;GeoDOS Speicherbank Hilfesystem.

::free			pha
			jsr	Free64K			;Speicher freigeben.
			pla

			sec				;Zeiger auf nächste reservierte
			sbc	#$01			;64K-Speicherbank.
			beq	ExitSetup		;Bank #0 -> Nicht freigeben, Ende...

			dec	r0L			;Reservierter Speicher freigegeben ?
			bne	:free			; => Nein, weiter...

;*** Setup beenden.
:ExitSetup		jsr	SaveCfgGEOS		;GEOS-Konfiguration speichern.
			txa				;Konfigurationsfehler ?
			beq	:0			; => Nein, weiter...
			jmp	DoAppStart

::0			lda	Copy_firstBoot		;GEOS-Copy_firstBoot zurücksetzen.
			sta	firstBoot

			lda	StackPointer		;Menu-Aufruf aus AutoBoot-Setup ?
			beq	:1			; => Nein, weiter...
			jsr	LogoScreen		;Titellogo zeichnen.
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
:Update_Kernel		jsr	CopyKernal2REU		;Kernal in REU kopieren.
			jmp	EnterDeskTop		;Zurück zum DeskTop/Boot-Routine.

;******************************************************************************

;*** BootUp-Information anzeigen.
:BootInfoSpool		lda	#<Icon_CfgSpool
			ldx	#>Icon_CfgSpool
			ldy	#$23
			jsr	BootInfoIcon
:BootInfoTask		lda	#<Icon_CfgTask
			ldx	#>Icon_CfgTask
			ldy	#$1e
			jsr	BootInfoIcon
:BootInfoHelp		lda	#<Icon_CfgHelp
			ldx	#>Icon_CfgHelp
			ldy	#$19
			jsr	BootInfoIcon
:BootInfoInOut		lda	#<Icon_CfgInOut
			ldx	#>Icon_CfgInOut
			ldy	#$14
			jsr	BootInfoIcon
:BootInfoGEOS		lda	#<Icon_CfgGEOS
			ldx	#>Icon_CfgGEOS
			ldy	#$0f
			jsr	BootInfoIcon
:BootInfoScreen		lda	#<Icon_CfgScreen
			ldx	#>Icon_CfgScreen
			ldy	#$0a
			jsr	BootInfoIcon
:BootInfoDrive		lda	#<Icon_CfgDrive
			ldx	#>Icon_CfgDrive
			ldy	#$05
			jsr	BootInfoIcon
:BootInfoRAM		lda	#<Icon_CfgRAM
			ldx	#>Icon_CfgRAM
			ldy	#$00
:BootInfoIcon		sta	r0L
			stx	r0H
			sty	r1L
			sty	:1			;Icon-Position speichern.
			LoadB	r1H,$b0
			LoadB	r2L,$05
			LoadB	r2H,$18
			jsr	BitmapUp		;Icon darstellen.

			lda	C_WinIcon		;Farbe setzen.
			jsr	i_UserColor
::1			b	$ff,$16,$05,$03

			lda	#$00
			sta	Flag_OpenMenu
			rts

;*** Konfigurationsmenü nachladen.
:LoadCfgRAM		lda	#$01			;Spooler.
			b $2c
:LoadCfgDrive		lda	#$02			;Laufwerksauswahl.
			b $2c
:LoadCfgScreen		lda	#$03			;Anzeige.
			b $2c
:LoadCfgGEOS		lda	#$04			;GEOS.
			b $2c
:LoadCfgInOut		lda	#$05			;Ein-/Ausgabegeräte.
			b $2c
:LoadCfgHelp		lda	#$06			;Ein-/Ausgabegeräte.
			b $2c
:LoadCfgTask		lda	#$07			;TaskManager.
			b $2c
:LoadCfgSpool		lda	#$08			;Spooler.
			sta	r14H			;Modul-Nr. merken.
			cmp	Flag_OpenMenu		;Modul bereits geöffnet ?
			beq	:3			; => Ja, Ende...

			jsr	SaveCfgGEOS		;Konfigurationsdaten speichern.
			txa				;Konfigurationsfehler ?
			bne	:3			; => Ja, Ende...

			jsr	LoadCfgTool		;Konfigurationsmenü laden.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Ende...

;--- Konfigurationsmenü starten.
			lda	#$00			;":appMain"-Vektor löschen. Wird
			sta	appMain +0		;z.B. von Modul "GEOS" für SCPU-
			sta	appMain +1		;Abfrage gesetzt.
			sta	otherPressVec +0	;Evtl. aktives Register-Menü
			sta	otherPressVec +1	;deaktivieren.

			lda	r14H			;Menü-Nr. speichern.
			sta	Flag_OpenMenu

			bit	firstBoot		;GEOS-BootUp ?
			bpl	LoadCfgAutoBoot		; => Ja, weiter...
			jsr	DrawCfgMenu		;Bildschirm löschen.
			jmp	BASE_CONFIG_TOOL	;Konfigurationsmenü starten.

;--- Fehler beim laden eines Setup-Tools.
::1			bit	firstBoot		;GEOS-BootUp ?
			bpl	:2			; => Ja, Ende...

			LoadW	r0,Dlg_NoCfgFile
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

::2			ldx	Flag_OpenMenu		;Systemdatei-Fehler ?
			dex				;(Nur GD.CONFIG.DRIVE)
			bne	:3			; => Nein, weiter...

			LoadW	r0,Dlg_CfgFileErr	;Start abbrechen und
			jmp	DoDlgBox		;Fehlermeldung ausgeben.
::3			rts

;*** Konfigurationsfehler während GEOS-BootUp.
;    Hauptmenü nachladen.
:LoadCfgAutoBoot	jsr	BASE_CONFIG_TOOL	;Konfiguratiuonsmenü starten.
:LoadCfgChkData		jsr	BASE_CONFIG_TEST	;GEOS-Konfiguration testen.
			txa				;Gültig ?
			beq	:1			; => Ja, weiter...

			tsx				;Ungültig, Menü aufrufen.
			stx	StackPointer		;Stack-Position speichern.

			lda	#$ff
			sta	firstBoot
			jsr	DrawCfgMenu		;Bildschirm löschen.
			jsr	BASE_CONFIG_TOOL	;Konfigurationsmenü starten.
			jmp	MainLoop		;Zur MainLoop.
::1			rts

;*** Hauptmenü während GEOS-BootUp verlassen.
:LoadCfgExitBoot	ldx	StackPointer		;StackPointer wieder zurücksetzen.
			txs
			lda	#$00
			sta	StackPointer

			lda	Copy_firstBoot		;GEOS-Copy_firstBoot zurücksetzen.
			sta	firstBoot		;Zurück zur AutoBoot-Routine des
			rts				;Hauptprogramms.

;*** Konfigurationsmenü nachladen.
:LoadCfgTool		lda	SystemDevice
			cmp	#12
			bcs	:skip
			jsr	SetDevice		;Systemlaufwerk öffnen und
::skip			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			lda	r14H			;Modul-Nr. einlesen und
			asl				;Zeiger auf Class-Info berechnen.
			tax
			lda	VecNameTab-2,x
			sta	r10L
			sta	r15L
			lda	VecNameTab-1,x
			sta	r10H
			sta	r15H

			LoadW	r6 ,dataFileName
			LoadB	r7L,SYSTEM
			LoadB	r7H,1
			jsr	FindFTypes		;Konfigurationsmodul suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			lda	r7H			;Modul gefunden ?
			bne	:1			; => Nein, Abbruch...

			LoadW	r6,dataFileName
			jsr	FindFile		;Verzeichnis-Eintrag einlesen.
			txa				;Diskettenfehler ?
			bne	:1			; => Nein, weiter...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r2,LD_ADDR_REGISTER - BASE_CONFIG_TOOL
			LoadW	r7,BASE_CONFIG_TOOL
			jmp	ReadFile

::1			ldx	#FILE_NOT_FOUND
			rts

;*** Konfiguration speichern.
:SaveCfgGEOS		ldx	Flag_OpenMenu		;Konfigurationsmenü geladen ?
			beq	:51			; => Nein, weiter...
			jsr	BASE_CONFIG_SAVE	;GEOS-Variablen aktualsieren.
::51			rts

;*** Aktuelle Konfiguration speichern.
:SaveCfgBOOT		jsr	SaveCfgGEOS		;GEOS-Variablen aktualsieren.

			lda	SystemDevice		;Start-Laufwerk aktivieren.
			jsr	SetDevice

			LoadW	r6 ,SysFileName
			LoadW	r10,SysFileClass
			LoadB	r7L,AUTO_EXEC
			LoadB	r7H,1
			jsr	FindFTypes		;Systemdatei suchen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			ldx	#FILE_NOT_FOUND
			lda	r7H			;Datei gefunden ?
			bne	:error			; => Nein, Abbruch...

			LoadW	r6,SysFileName
			jsr	FindFile		;Verzeichnis-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Sektor mit Konfiguration laden.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			ldy	#(Boot_EndData -  Boot_StartData) -1
::51			lda	Boot_StartData,y
			sta	diskBlkBuf  +2,y
			dey
			cpy	#$ff
			bne	:51

			jsr	PutBlock		;Sektor mit Konfiguration speichern.
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

;*** Bildschirm neu zeichnen.
:xDrawCfgMenu		jsr	DrawLogo		;Logo ausgeben.
			jsr	UseFontG3		;Font aktivieren.

			lda	C_WinIcon		;Farbe für Icons setzen.
			jsr	i_UserColor
			b	$00,$00,$28,$03
			lda	C_WinIcon		;Farbe für Icons setzen.
			jsr	i_UserColor
			b	$00,$05,$05,$03
			lda	C_WinIcon		;Farbe für Icons setzen.
			jsr	i_UserColor
			b	$00,$09,$05,$03
			LoadW	r0,Icon_Menu		;Iconmenü aktivieren.
			jmp	DoIcons

;*** Titelbild anzeigen.
:DrawLogo		lda	sysRAMFlg
			and	#%00001000
			beq	:print_logo
			jmp	GetBackScreen		;Hintergrundbild laden.

;******************************************************************************
;*** Titelbild ausgeben.
;******************************************************************************
::print_logo		t "-G3_LogoScreen"
;******************************************************************************

;*** AutoBoot-Routine laden/speichern.
:Fetch_AutoBoot		ldy	#jobFetch
			b $2c
:Stash_AutoBoot		ldy	#jobStash
			LoadW	r0 ,BASE_AUTO_BOOT
			LoadW	r1 ,R3_ADDR_AUTOBBUF
			LoadW	r2 ,SIZE_AUTO_BOOT
			lda	MP3_64K_DATA
			sta	r3L
			jmp	DoRAMOp

;******************************************************************************
;*** Datei auswählen.
;******************************************************************************
;    Übergabe:		r7L  = Datei-Typ.
;			r10  = Datei-Klasse.
;    Rückgabe:		In ":dataFileName" steht der Dateiname.
;			xReg = $00, Datei wurde ausgewählt.
:xOpenFile		MoveB	r7L,OpenFile_Type
			MoveW	r10,OpenFile_Class

::1			ldx	curDrive
			lda	driveType -8,x
			bne	:3

			ldx	#8
::2			lda	driveType -8,x
			bne	:3
			inx
			cpx	#12
			bcc	:2
			ldx	#$ff
			rts

::3			txa
			jsr	SetDevice

::4			MoveB	OpenFile_Type ,r7L
			MoveW	OpenFile_Class,r10
			LoadW	r5 ,dataFileName
			LoadB	r7H,255
			LoadW	r0,Dlg_SlctFile
			jsr	DoDlgBox		;Datei auswählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:5			; => Nein, weiter...

			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			beq	:4			; => Nein, weiter...
			bne	:1			; => Ja, gültiges Laufwerk suchen.

::5			cmp	#DISK			;Partition wechseln ?
			beq	:4			; => Ja, weiter...
			ldx	#$ff
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:6			; => Ja, Abbruch...
			inx
::6			rts

;******************************************************************************
;*** Variablen.
;******************************************************************************
:StackPointer		b $00
:OpenFile_Type		b $00				;Dateiauswahl: Dateityp.
:OpenFile_Class		w $0000				;Dateiauswahl: Zeiger auf Klasse.

;*** Programmdateien.
:VecNameTab		w ClassCfgRAM
			w ClassCfgDrive
			w ClassCfgScreen
			w ClassCfgGEOS
			w ClassCfgInOut
			w ClassCfgHelp
			w ClassCfgTask
			w ClassCfgSpool

:ClassCfgRAM		b "GDC.RAM     V1.0",NULL
:ClassCfgDrive		b "GDC.DRIVES  V1.0",NULL
:ClassCfgScreen		b "GDC.SCREEN  V1.0",NULL
:ClassCfgGEOS		b "GDC.GEOS    V1.0",NULL
:ClassCfgInOut		b "GDC.PRNINPT V1.0",NULL
:ClassCfgHelp		b "GDC.GEOHELP V1.0",NULL
:ClassCfgTask		b "GDC.TASKMAN V1.0",NULL
:ClassCfgSpool		b "GDC.SPOOLER V1.0",NULL

:Flag_OpenMenu		b $00

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
if Sprache = Deutsch
:DLG_T_ERR		b PLAINTEXT,BOLDON
			b "Fehlermeldung",0
:DLG_T_INF		b PLAINTEXT,BOLDON
			b "Information",0
endif
if Sprache = Englisch
:DLG_T_ERR		b PLAINTEXT,BOLDON
			b "Systemerror",0
:DLG_T_INF		b PLAINTEXT,BOLDON
			b "Information",0
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
if Sprache = Deutsch
::1			b "Konfigurationsmodul laden",0
::2			b "ist nicht möglich. Die Datei:",0
::3			b "wurde nicht gefunden!",0
endif
if Sprache = Englisch
::1			b "Loading configuration file failed.",0
::2			b "The following file:",0
::3			b "was not found!",0
endif

;*** Dialogbox: Start von Laufwerk >=12 nicht unterstützt.
if GD_NG_MODE = FALSE
:Dlg_BootAdrErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$3a
			w :2
			b NULL
endif
if GD_NG_MODE!Sprache = FALSE!Deutsch
::1			b "Systemstart abgebrochen!",0
::2			b PLAINTEXT
			b "Laufwerk >=12 wird nicht unterstützt!",0
endif
if GD_NG_MODE!Sprache = FALSE!Englisch
::1			b "Start cancelled!",0
::2			b PLAINTEXT
			b "Device address >=12 not supported!",0
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
if Sprache = Deutsch
::1			b "Systemstart abgebrochen. Die",0
::2			b "folgende System-Datei fehlt:",0
endif
if Sprache = Englisch
::1			b "Start cancelled. The following",0
::2			b "system-file was not found:",0
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
if Sprache = Deutsch
::1			b "Speichern der Konfiguration",0
::2			b "ist fehlgeschlagen!",0
::3			b "Fehlercode:",0
endif
if Sprache = Englisch
::1			b "Saveing configuration to",0
::2			b "disk has failed!",0
::3			b "Error code: $",0
endif

:DiskErrCode		b "$XX",0

;*** Dialogbox: Datei wählen.
:Dlg_SlctFile		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b DISK                    ,$00,$00
			b DBUSRICON               ,$00,$00
			w Dlg_SlctInstall
			b NULL

;*** Icon für Dateiauswahlbox.
:Dlg_SlctInstall	w Icon_Install
			b $00,$00,Icon_Install_x,Icon_Install_y
			w :exit

::exit			lda	#OPEN
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Icon-Menü.
:Icon_Menu		b $0a
			w $0000
			b $00

			w Icon_CfgExit
			b $00,$00,Icon_CfgExit_x,Icon_CfgExit_y
			w ExitSetup

			w Icon_CfgSave
			b $00,$28,Icon_CfgSave_x,Icon_CfgSave_y
			w SaveCfgBOOT

			w Icon_CfgHelp
			b $00,$48,Icon_CfgHelp_x,Icon_CfgHelp_y
			w LoadCfgHelp

			w Icon_CfgRAM
			b $05,$00,Icon_CfgRAM_x,Icon_CfgRAM_y
			w LoadCfgRAM

			w Icon_CfgDrive
			b $0a,$00,Icon_CfgDrive_x,Icon_CfgDrive_y
			w LoadCfgDrive

			w Icon_CfgTask
			b $0f,$00,Icon_CfgTask_x,Icon_CfgTask_y
			w LoadCfgTask

			w Icon_CfgSpool
			b $14,$00,Icon_CfgSpool_x,Icon_CfgSpool_y
			w LoadCfgSpool

			w Icon_CfgInOut
			b $19,$00,Icon_CfgInOut_x,Icon_CfgInOut_y
			w LoadCfgInOut

			w Icon_CfgScreen
			b $1e,$00,Icon_CfgScreen_x,Icon_CfgScreen_y
			w LoadCfgScreen

			w Icon_CfgGEOS
			b $23,$00,Icon_CfgGEOS_x,Icon_CfgGEOS_y
			w LoadCfgGEOS

;*** Icons.
:Icon_Install                <MISSING_IMAGE_DATA>
:Icon_Install_x		= .x
:Icon_Install_y		= .y

if Sprache = Deutsch
:Icon_CfgExit
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_CfgExit
<MISSING_IMAGE_DATA>
endif

:Icon_CfgExit_x			= .x
:Icon_CfgExit_y			= .y

if Sprache = Deutsch
:Icon_CfgSave
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
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
