; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Haupt-Initialisierungsroutine für den GEOS.Editor.
;*** Beim ersten Start wird die Konfiguration im laufenden Betrieb übernommen
;*** bzw. wenn während des Boot-Vorgangs ausgeführt werden alle physikalischen
;*** Laufwerk 8-11 erkannt und installiert.
;******************************************************************************

;*** Startvorgang initialisieren.
:MainInitBoot		lda	#ST_WR_FORE		;Bildschirm löschen.
			sta	dispBufferOn

			bit	Flag_ME1stBoot		;GEOS.Editor im SETUP-Modus?
			bmi	:1			; => Nein, weiter...
			bit	firstBoot		;GEOS-BootUp ?
			bmi	:1			; => Nein, weiter...
			jsr	PrntCfgMessage

;--- Laufwerkstreiber in REU kopieren.
::1			jsr	ClearScreen		;Status-Anzeige aktualisieren.
			jsr	PrintArea001p 		;(Nur bei erstem Programmstart).

			jsr	LoadDiskDrivers
			txa
			beq	:2
			jmp	Err_LdDskFile

;--- Aktiven TaskManager einlesen und in Zwischenspeicher kopieren.
::2			bit	firstBoot		;GEOS-BootUp ?
			bpl	:5			; => Ja, weiter...
			lda	Flag_TaskAktiv		;Ist TaskManager installiert ?
			bmi	:4			; => Nein, weiter...

			LoadW	r0,R2_ADDR_TASKMAN_E
			LoadW	r1,R2_ADDR_TASKMAN
			LoadW	r2,R2_SIZE_TASKMAN
			lda	Flag_TaskBank
			sta	r3L
			jsr	FetchRAM
			jsr	SetTaskBank		;Zeiger auf TaskManager und
			jsr	StashRAM		;aktuellen Manager speichern.

			ldy	#$08			;Variablen einlesen.
::3			lda	R2_ADDR_TASKMAN_E +3,y
			sta	TASK_BANK_ADDR      ,y

if Flag64_128 = TRUE_C128
			lda	R2_ADDR_TASKMAN_E +22,y
			sta	TASK_VDC_ADDR      ,y
			lda	R2_ADDR_TASKMAN_E +22+9,y
			sta	TASK_BANK0_ADDR      ,y
endif
			dey
			bpl	:3

			lda	R2_ADDR_TASKMAN_E +21
			sta	TASK_COUNT
			lda	#$00			;Taskmanager war aktiviert,
::4			sta	BootTaskMan		;"Install"-Flag setzen.
::5			lda	#$ff			;TaskManager abschalten.
			sta	Flag_TaskAktiv

;--- Status Druckerspooler übernehmen und deaktivieren.
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:7			; => Ja, weiter...

			ldy	#$00			;Vorgabe: Spoolergrößezurücksetzen.
			lda	Flag_Spooler		;Ist Spooler installiert ?
			bpl	:6			; => Nein, weiter...

			lda	Flag_SpoolMinB		;Ist RAM für Druckerspooler
			ora	Flag_SpoolMaxB		;reserviert ?
			beq	:6			; => Nein, weiter...

			lda	Flag_SpoolMaxB
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			tay

			ldx	Flag_SpoolCount		;Verzögerungszeit für
			stx	BootSpoolCount		;Druckerspooler setzen.

			lda	#%10000000		;Spooler war installiert,
::6			sta	BootSpooler		;"Install"-Flag setzen.
			sty	BootSpoolSize		;Spoolergröße setzen.

::7			lda	#%00000000		;Spooler deaktivieren.
			sta	Flag_Spooler

;*** Speicherbelegungstabelle erstellen.
:InitRamTab		jsr	Make64KRamTab		;Bank-Belegungstabelle definieren.
							;TaskMan/Spooler nicht beachten.
			bit	firstBoot		;GEOS-BootUp ?
			bmi	Find_CMD_SCPU		; => Nein, weiter...
			jsr	AllocBankUser		;Anwenderspeicher reservieren.

;*** SuperCPU erkennen.
:Find_CMD_SCPU		lda	#$00			;Takt für SCPU auf 1Mhz setzen.
			sta	LastSpeedMode		;(Falls keine SCPU vorhanden)
			sta	SCPU_Aktiv		;Flag: "Keine SCPU".

			php
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			ldx	MMU
			lda	#$7e
			sta	MMU
endif
			lda	$d0bc

if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			stx	MMU
endif

			plp
			and	#%10000000		;Bit 7=1, SCPU nicht aktiv.
			bne	Find_CMD_RL
			dec	SCPU_Aktiv		;Flag setzen: "SCPU verfügbar".

			jsr	CheckForSpeed		;SCPU-Takt ermitteln und
			sta	LastSpeedMode		;zwischenspeichern.

;*** RAMLink erkennen.
:Find_CMD_RL		lda	#$00			;Flag: "Keine RAMLink".
			sta	RL_Aktiv

			php
			sei

if Flag64_128 = TRUE_C64
			ldy	CPU_DATA
			lda	#$36
			sta	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			ldy	MMU
			lda	#$4e
			sta	MMU
endif

			ldx	$e0a9			;Byte aus C64-Kernal einlesen.

if Flag64_128 = TRUE_C64
			sty	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			sty	MMU
endif

			plp
			cpx	#$78			;"SEI"-Befehl ?
			bne	:1			;Nein, weiter...
			dec	RL_Aktiv		;RAMLink verfügbar.

;--- Keine RAMLink, RLxy-Laufwerke nach RAMxy konvertieren.
::1			lda	RL_Aktiv		;RAMLink verfügbar ?
			bne	Install			; => Ja, weiter...

			ldx	#$00			;RAMLink-Laufwerke in RAM-Laufwerke
::2			lda	BootConfig,x		;umwandeln, da keine RAMLink
			and	#%11110000		;verfügbar ist. Damit wird versucht
			cmp	#DrvRAMLink		;die Konfiguration beizubehalten!
			bne	:3
			lda	BootConfig,x
			and	#%00001111		;Emulationsmodus isolieren und
			ora	#%10000000		;"RAM-Laufwerk"-Flag setzen.
			sta	BootConfig,x
::3			inx
			cpx	#$04
			bcc	:2

;*** MegaPatch konfigurieren/Menü-Oberfläche starten.
:Install		jsr	PrintArea025p		;Status-Anzeige aktualisieren.

			jsr	GetAllSerDrive		;<*> Alle Laufwerke erkennen.

			bit	firstBoot		;GEOS-BootUp ?
			bpl	:3			; => Ja, automatisch installieren.
			ldx	#3
::1			lda	driveType     ,x
			beq	:2
			bmi	:2
			lda	DriveInfoTab  ,x
			beq	:2
			lda	#$ff
			sta	DriveInUseTab ,x
::2			dex
			bpl	:1
			jmp	LoadMainMenu		;Hauptmenü starten.

::3			jsr	PurgeTurbo		;GEOS-TurboDOS abschalten.
			jsr	InstallDkDev		;Laufwerke installieren.
;			jmp	AutoInstall		;Editor/Standard konfigurieren.

;*** MegaPatch konfigurieren/Uhrzeit setzen.
:AutoInstall		jsr	PrintArea050p		;Status-Anzeige aktualisieren.

			jsr	SetClockGEOS		;Uhrzeit einlesen.

;*** MegaPatch konfigurieren/System konfigurieren.
:Install_SCPU		jsr	PrintArea075p		;Status-Anzeige aktualisieren.

			bit	SCPU_Aktiv		;Ist SuperCPU aktiviert ?
			bpl	Install_Cursor		; => Nein, weiter...

			php				;SuperCPU-Taktfrequenz festlegen.
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif

			ldy	#$00
			bit	BootSpeed
			bvs	:1
			iny
::1			sta	$d07a,y			;Takt über Register $D07A/$D07B

if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;einstellen.
endif

			plp

:Install_SCPU_Opt	lda	BootOptimize		;Optimierung für SuperCPU
			jsr	SCPU_SetOpt		;festlegen.

:Install_Cursor		lda	BootCRSR_Repeat		;Wiederholungsgeschwindigkeit für
			sta	Flag_CrsrRepeat		;CURSOR festlegen.

:Install_Printer	lda	BootPrntMode		;Modus für Druckertreiber
			sta	Flag_LoadPrnt		;aus RAM/DISK festlegen.
			jsr	InitPrntDevice

;--- Ergänzung: 31.12.18/M.Kanet
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert.
if Flag64_128 = TRUE_C64
			jsr	InitGCalcFix
endif

;--- Ergänzung: 31.12.18/M.Kanet
;QWERTZ-Tastatur aktivieren.
;Damit kann die Tastenbelegung Y/Z getauscht werden.
if Sprache = Deutsch
			jsr	InitQWERTZ
endif

:Install_Input		jsr	InitInptDevice

:Install_Menu		lda	BootColsMode		;Modus für Systemfarben festlegen.
			sta	Flag_SetColor
			lda	BootMenuStatus		;Menü-Parameter festlegen.
			sta	Flag_MenuStatus
			lda	BootMLineMode
			sta	Flag_SetMLine

:Install_ScrSaver	lda	BootScrSaver		;Modus für Bildschirmschoner
			sta	Flag_ScrSaver		;installieren.
			lda	BootScrSvCnt		;Startverzögerung für
			sta	Flag_ScrSvCnt		;Bildschirmschoner festlegen.
			lda	BootSaverName		;Bildschirmschoner nachladen ?
			beq	:1			;Nein, weiter...
			LoadW	r6,BootSaverName	;Neuen Bildschirmschoner starten.
			jsr	InitScrSaver

::1			jsr	PrintArea100p		;Status-Anzeige aktualisieren.

			bit	Flag_ME1stBoot		;Konfiguration gespeichert, dann
			bpl	Install_Task_Spl	;ist dieses Flag für immer $FF.

			jmp	ExitToDeskTop

;*** MegaPatch während des bootens automatisch konfigurieren.
;Wenn MP3 zum ersten mal installiert
;wird, dann TaskManager und Drucker-
;spooler automatisch konfigurieren.
:Install_Task_Spl	lda	#$00
			sta	TASK_COUNT		;Vorgabewert: Alle Tasks löschen.
			sta	BootSpoolSize		;Vorgabewert: Spooler deaktivieren.
			jsr	GetMaxFree		;Max. freien Speicher ermitteln.
			cpy	#$03			;Genügend Speicher frei ?
			bcc	:8			; => Nein, Ende...

;--- Max. RAM für TaskManager aktivieren.
			bit	BootTaskMan		;TaskManager installieren ?
			bmi	:1			; => Nein, weiter...
			lda	#MAX_TASK_ACTIV		;Vorgabewert: Alle Tasks aktivieren.
			sta	TASK_COUNT

;--- Max. RAM für Spooler aktivieren.
::1			bit	BootSpooler		;Spooler installieren ?
			bpl	:4			; => Nein, weiter...
			lda	ramExpSize		;Vorgabewert: Max. Spoolergröße.
			cmp	#MAX_SPOOL_SIZE		;Max. Größe des Spoolers
			bcc	:2			;überschritten ?
			lda	#MAX_SPOOL_SIZE		; => Ja, Größe auf Maximum setzen.
::2			cmp	#MAX_SPOOL_STD		;Mehr als Standard(256) reserviert ?
			bcc	:3			; => Nein, weiter...
			lda	#MAX_SPOOL_STD		;Standardgröße Spooler verwenden.
::3			sta	BootSpoolSize		;Spoolergröße festlegen.

;--- Taskmanager und Spooler konfigurieren.
::4			jsr	ClrBank_Blocked		;Reserviertes RAM freigeben.
			jsr	AllocBankUser		;Anwenderspeicher reservieren.
			jsr	BlockFreeBank		;Zwei Bänke reservieren: 1x für
			jsr	BlockFreeBank		;GEOS-Anwendungen, 1x für Spooler.
			jsr	InitTaskManager		;TaskManager installieren.

			jsr	ClrBank_Blocked		;Reserviertes RAM freigeben.
			jsr	AllocBankUser		;Anwenderspeicher reservieren.
			jsr	BlockFreeBank		;64K für Anwendungen reservieren.
			jsr	InitPrntSpooler		;Spooler installieren.

			jsr	ClrBank_Blocked		;Reserviertes RAM freigeben.
			jsr	AllocBankUser		;Anwenderspeicher reservieren.

;--- Installierte Größe von TaskManager retten.
			jsr	GetMaxTask		;Vorgabewerte für Taskmanager und
							;Druckerspooler bestimmen.
if Flag64_128 = TRUE_C64
			sty	TASK_COUNT
endif
if Flag64_128 = TRUE_C128
			ldx	#0
::5			cpy	#0
			beq	:6
			inx
			dey
			dey
			dey
			jmp	:5
::6			stx	TASK_COUNT
endif

;--- Installierte Größe von Spooler retten.
			jsr	GetMaxSpool
			sty	BootSpoolSize

;--- Zurück zum DeskTop.
::8			jmp	ExitToDeskTop

;*** Dialogbox zeichnen.
:DrawCfgDlgBox		lda	#$00			;Schatten zeichnen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$87
			w	$0048 ! DOUBLE_W
			w	$0107 ! DOUBLE_W ! ADD1_W
			lda	C_WinShadow
			jsr	DirectColor

			jsr	i_Rectangle		;Titel zeichnen.
			b	$20,$2f
			w	$0040 ! DOUBLE_W
			w	$00ff ! DOUBLE_W ! ADD1_W
			lda	C_DBoxTitel
			jsr	DirectColor

			jsr	i_Rectangle		;Dialogbox zeichnen.
			b	$30,$7f
			w	$0040 ! DOUBLE_W
			w	$00ff ! DOUBLE_W ! ADD1_W
			lda	#%11111111
			jsr	FrameRectangle
			lda	C_DBoxBack
			jmp	DirectColor

;*** Dialogbox: GEOS-Editor wird konfiguriert.
:PrntCfgMessage		jsr	DrawCfgDlgBox
			jsr	i_PutString		;Textmeldung ausgeben.
			w	$0050 ! DOUBLE_W
			b	$2b
if Sprache = Deutsch
			b	PLAINTEXT,BOLDON
			b	"System vorbereiten"
endif
if Sprache = Englisch
			b	PLAINTEXT,BOLDON
			b	 "Preparing System"
endif
			b	GOTOXY
			w	$0050 ! DOUBLE_W
			b	$40
if Sprache = Deutsch
			b	"Der GEOS.Editor wird"
endif
if Sprache = Englisch
			b	"GEOS.Editor will be configured,"
endif
			b	GOTOXY
			w	$0050 ! DOUBLE_W
			b	$4c
if Sprache = Deutsch
			b	"konfiguriert. Bitte warten..."
endif
if Sprache = Englisch
			b	"please wait..."
endif
			b	NULL
			rts

;*** Statusbereich löschen.
:ClearScreen		bit	Flag_ME1stBoot		;GEOS.Editor im SETUP-Modus?
			bmi	:1			; => Nein, weiter...
			bit	firstBoot		;GEOS-BootUp ?
			bmi	:1			; => Nein, weiter...

			lda	#$00			;Statuszeile löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$b8,$c7
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W
			lda	#%11111111
			jsr	FrameRectangle
			lda	C_WinBack
			jsr	DirectColor

			lda	#$05			;Prozent-Bereich löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$ba,$c5
			w	$001e ! DOUBLE_W
			w	$013d ! DOUBLE_W
			lda	#%11111111
			jmp	FrameRectangle
::1			rts

;*** Prozent-Anzeige ausgeben.
:PrintArea001p		lda	#0
			b $2c
:PrintArea025p		lda	#1
			b $2c
:PrintArea050p		lda	#2
			b $2c
:PrintArea075p		lda	#3
			b $2c
:PrintArea100p		lda	#4

:PrintStatus		bit	Flag_ME1stBoot		;GEOS.Editor im SETUP-Modus?
			bmi	:1			; => Nein, weiter...
			bit	firstBoot		;GEOS-BootUp ?
			bmi	:1			; => Nein, weiter...

			pha

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0001 ! DOUBLE_W
			b	$b9
			b	RECTANGLETO
			w	$001d ! DOUBLE_W
			b	$c6
			b	ESC_PUTSTRING
			w	$0004 ! DOUBLE_W
			b	$c2
			b	PLAINTEXT,BOLDON
			b	NULL

			LoadB	r2L,$ba
			LoadB	r2H,$c5
			LoadW	r3,30 ! DOUBLE_W
			pla
			pha
			asl
			tax
			lda	:width +0,x
			sta	r4L
			lda	:width +1,x
			sta	r4H
			lda	#$01
			jsr	SetPattern
			jsr	Rectangle
			pla
			tax
			lda	:percent,x
			sta	r0L
			lda	#$00
			sta	r0H
			LoadW	r11,$0004 ! DOUBLE_W
			LoadB	r1H,$c2
			lda	#%11000000
			jsr	PutDecimal
			lda	#"%"
			jsr	PutChar
::1			rts

;*** Breite des Fortschrittsbalkens.
::width			w 30+(288*001/100 -1) ! DOUBLE_W
			w 30+(288*025/100 -1) ! DOUBLE_W
			w 30+(288*050/100 -1) ! DOUBLE_W
			w 30+(288*075/100 -1) ! DOUBLE_W
			w 30+(288*100/100 -1) ! DOUBLE_W

;*** Werte für Fortschrittsanzeige.
::percent		b 1,25,50,75,100
