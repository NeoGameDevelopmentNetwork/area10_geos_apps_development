; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Hardware-Erkennung GEOS-DACC.
:ExtRAM_Type		b $00				;$00 = keine RAM-Erweiterung.
							;$80 = RAMLink / RAMDrive.
							;$40 = Commodore REU.
							;$20 = BBG/GEORAM.
							;$10 = SuperCPU/RAMCard.
:ExtRAM_Size		b $00				;Anzahl 64K-Bänke.
:ExtRAM_Bank		w $0000
:ExtRAM_Part		b $00
:ExtRAM_Name		w $0000

;*** Kennbytes der Speichererweiterung.
:RamTypeCodes		b NULL
			b RAM_SCPU
			b RAM_RL
			b RAM_REU
			b RAM_BBG
			b NULL

;*** Dateinamen für Systemdateien.
:FNamGDINI		b "GD.INI",NULL
:FNamGBOOT		b "GD.BOOT",NULL
:FNamGBOOT_1		b "GD.BOOT.1",NULL
:FNamGBOOT_2		b "GD.BOOT.2",NULL
:FNamGDISK		s 17

;*** Partitions-Daten.
:GP_Befehl		b $47,$2d,$50,$ff,$0d
:GP_Data		s $20

;*** Laufwerksadresse RAMLink.
:RL_BootAddr		b $00

;*** Verzögerung für Textausgabe.
;--- Ergänzung: 06.09.18/M.Kanet
;Verzögerung der Ausgabe von Systemtexten deaktiviert.
;Wurde eingeführt um beim Start Systemmeldungen und Fehler erkennen zu können.
if FALSE
:TEXT_OUT_DELAY		b $00
endif

;*** Hardware erkennen.
:MainInit		jsr	LoadConfigDACC		;Speichererweiterung einlesen.
			txa				;Fehler?
			beq	:init			; => Nein, weiter...

			jsr	CreateNewGDINI		;Neue GD.INI-Datei erzeugen.
			txa				;Fehler?
			beq	:init			; => Nein, weiter...

			jmp	ERR_EXIT_BASIC_R	;Abbruch nach BASIC.

::init			sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.

;			ldx	#$ff			;Stack-Pointer löschen.
;			txs

			lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA

			jsr	CheckSCPU		;SuperCPU erkennen.
			jsr	CheckRLNK		;RAMLink erkennen.

			jsr	PrintBootInfo		;Boot-Meldungen ausgeben.

;*** Speichererweiterung wählen.
:DetectRAM		jsr	FindRamExp		;Speichererweiterung suchen.

;*** GEOS-System laden.
:Initialize		jsr	Strg_Initialize		;"System wird geladen..."
			jsr	Strg_Titel		;Versionsinformationen...

;*** Startlaufwerk initialisieren.
			jsr	Strg_DvInit_Info	;Installationsmeldung ausgeben.

			lda	curDevice		;Boot-Laufwerk speichern.
			sta	Boot_Drive

			jsr	InitBootDevice		;Boot-Laufwerk übernehmen.
			txa				;Laufwerk erkannt ?
			beq	:1			; => Ja, weiter...
			jmp	ERR_EXIT_BASIC_L	;Fehler, zurück zum BASIC.

::1			jsr	FindRL_Part		;RAMLink-Startpartition ermitteln.

;*** Variablenspeicher initialisieren.
:Init_GEOS_Var		jsr	InitSys_ClrVar		;GEOS-Variablen löschen.

;*** GEOS-Kernal einlesen und installieren.
:Load_GEOS_GD		jsr	LoadSys_GEOS		;Kernal-Teil #1 laden und
			jsr	InitSys_GEOS		;installieren.

;--- Laufwerkstreiber einlesen.
			jsr	LoadSys_DISK		;Laufwerkstreiber laden und
			jsr	InitSys_DISK		;installieren.

;--- RAM-Treiber installieren.
			sei
			lda	#RAM_64K		;64K-RAM-Bereich einblenden.
			sta	CPU_DATA

			jsr	InitSys_SetDACC		;DACC-Informationen festlegen.
			txa				;DACC-Informationen gültig?
			bne	:ram_err		; => Nein, Abbruch...

			jsr	Strg_MgrRAM		;Installationsmeldung ausgeben.
			jsr	InitDeviceRAM		;RAM-Patches installieren.
			txa				;Fehler?
			bne	:ram_err		; => Ja, Abbruch...

			jsr	Strg_OK			;Installationsmeldung ausgeben.

;--- Ergänzung: 09.02.21/M.Kanet
;GEOS-Informationen müssen hier erneut gesetzt werden, da bei der Installation
;von "GD.BOOT.2" bereits StashRAM verwendet wird.
;Für das testen der Speichererweiterung wird StashRAM/FetchRAM verwendet.
			jsr	InitSys_ClrVar		;GEOS-Variablen löschen.
			jsr	InitSys_SetDACC		;DACC-Informationen festlegen.
			txa				;DACC-Informationen gültig?
			bne	:ram_err		; => Nein, Abbruch...

;--- Sonderbehandlung für SuperCPU.
			lda	Device_SCPU		;SuperCPU verfügbar?
			beq	:test_ram		; => Nein, weiter...

			lda	ExtRAM_Type
			cmp	#RAM_SCPU		;SuperCPU/RAMCard als GEOS-DACC ?
			bne	:patch_scpu		; => Nein, weiter...

;--- Speichermanagement der SuperCPU aktualisieren.
			sei
			lda	#KRNL_BAS_IO_IN		;Kernal-ROM + I/O einblenden.
			sta	CPU_DATA

			sta	SCPU_HW_EN		;SuperCPU-Register einschalten.

			lda	#$00			;Speichermanagement der SuperCPU
			sta	SRAM_FIRST_PAGE		;aktualisieren.
			lda	RamBankFirst +1
			clc
			adc	ramExpSize
			sta	SRAM_FIRST_BANK

			sta	SCPU_HW_DIS		;SuperCPU-Register abschalten.

;--- GEOS-Code für SuperCPU patchen.
::patch_scpu		jsr	Strg_MgrSCPU		;Installationsmeldung ausgeben.
			jsr	InitDeviceSCPU		;SuperCPU patchen.
			jsr	Strg_OK			;Installationsmeldung ausgeben.

			lda	#RAM_64K		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA

;--- Speichererweiterung testen.
::test_ram		jsr	Strg_TestRAMExp		;RAM-Treiber testen.
			jsr	TestDeviceRAM
			txa				;RAM-Test OK?
			beq	:test_ram_ok		; => Ja, weiter...
::ram_err		jmp	ERR_EXIT_BASIC_R	;Abbruch nach BASIC.

::test_ram_ok		jsr	Strg_OK			;Installationsmeldung ausgeben.

;--- Ergänzung: 09.09.18/M.Kanet
;Wenn kein PP-Kabel vorhanden ist, dann fürt dieser
;Befehl zu Problemen mit andere Hardware/Speedern.
;Code ist deaktiviert. TurboDOS+PP-Kabel funktioniert.
;--- CMD-HD-PP-Kabel deaktivieren.
;			jsr	InitDeviceHD		;"P0"-Befehl ausführen. Dieser
							;Befehl deaktiviert ein vorhandenes
							;Kabel von der RL zur HD.

;*** GEOS-Variablen initialisieren.
:InitSys_GEOSVar	sei				;Interrupt sperren.
;			cld				;DEZIMAL-Flag bereits gelöscht.

;			ldx	#$ff			;Stack-Pointer löschen.
;			txs

			lda	#IO_IN			;I/O-Bereiche einblenden.
			sta	CPU_DATA

			lda	cia1base +15		;I/O-Register initialisieren.
			and	#%01111111
			sta	cia1base +15		;CIA#1/TOD: Alarm-Flag löschen.
			lda	#%10000001
			sta	cia1base +11		;CIA#1/TOD: 1pm
			lda	#$00
			sta	cia1base +10
			sta	cia1base + 9
			sta	cia1base + 8		;CIA#1/TOD: min/sec=0, Uhr starten.

			lda	#RAM_64K		;64K-GEOS-RAM aktivieren.
			sta	CPU_DATA

;*** Laufwerksvariablen initialisieren.
:InitSys_GEOSDDrv	ldy	Boot_Drive		;Startlaufwerk aktivieren.
			cpy	#12
			bcc	:1
			ldy	#8
::1			sty	curDrive

			lda	Boot_Type		;Typ Startlaufwerk speichern.
			sta	RealDrvType -8,y
			and	#%11110000		;Laufwerkstyp isolieren.
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
			bne	:2			; => Nein, weiter...

			lda	Boot_Part   +1		;Bootpartition aktivieren.
			sta	ramBase     -8,y

			lda	Boot_Type		;Emulationstyp isolieren und
			and	#%00001111		;RAM-Flag setzen.
			ora	#%10000000
			bne	:3

::2			lda	Boot_Type
::3			sta	curType			;Emulationstyp speichern.
			sta	driveType   -8,y

			lda	Boot_Mode		;Laufwerksmodi speichern.
			sta	RealDrvMode -8,y

			lda	#$01			;Anzahl Laufwerke initialisieren.
			sta	numDrives

			lda	#$00			;RAMLink-Adresse zurücksetzen.
			sta	sysRAMLink

			lda	#%01110000		;Kein MoveData, DiskDriver in REU,
			sta	sysRAMFlg		;ReBoot-Kernal in REU.

;--- Hinweis:
;Nur ":OpenDisk" ausführen um bei einer
;RAMLink den GEOS-Laufwerkstreiber zu
;initialisieren.
			jsr	OpenDisk		;Laufwerkstreiber initialisieren.

;--- GDOS-Kernal installieren.
;Ab hier kann wieder GEOS-":DoRAMOp"
;verwendet werden, da der RAM-Treiber
;installiert ist.
;Der GDOS-Kernal muss vor der GEOS-
;Initialisierung im System installiert
;werden, da die Initialisierung über
;ext. GDOS-Routinen aufgerufen wird.
			jsr	LoadSys_GDOS		;Kernal-Teil #2 laden.
			jsr	InitSys_GDOS

;--- Standard-Gerätetreiber laden.
;Wird durch GD.CONFIG ausgeführt.
;Der Kernal beinhaltet standardmäßig
;den Mouse1351-Treiber.
;			jsr	LoadDev_Printer		;Druckertreiber laden.
;			jsr	LoadDev_Mouse		;Eingabetreiber laden.

;*** GEOS-Hauptinitialisierung.
:InitSYS_GEOSCore	jsr	Strg_InitGEOS		;Installationsmeldung ausgeben.

;--- Ergänzung: 24.12.22/M.Kanet
;In VIC-Bank#0 ist der Bereich von
;$07E8-$07F7 "unused". Für die in GEOS
;aktive VIC-Bank#2 = $8FE8-$8FF7.
;Es gibt im Kernal an keiner Stelle
;einen Zugriff auf diese Adressen, die
;Spritepointer liegen ab $8FF8 und
;werden durch GEOS_Init1 gesetzt.
;
; -> sysApplData
;
;GEOS V2 mit DESKTOP V2 legt hier über
;das Programm "pad color mgr" Farben
;für den DeskTop und Datei-Icons ab.
;Ab $8FE8 finden sich in 8 Byte bzw.
;16 Halb-Nibble die Farben für GEOS-
;Dateitypen 0-15, und ab $8FF0 findet
;sich die Farbe für den Arbeitsplatz.
;
;*** "pad color mgr"-Vorgaben setzen.
::DefPadCol		ldx	#6			;Ungenutzte Bytes
			lda	#$00			;initialisieren.
::50			sta	sysApplData +9,x
			dex
			bpl	:50

;--- Hinweis:
;Wird durch ":FirstInit" initialisiert.
if FALSE
			lda	#$bf			;Standardfarbe Arbeitsplatz.
			sta	sysApplData +8

			ldx	#7			;Standardfarbe für die ersten
			lda	#$bb			;16 GEOS-Dateitypen.
::51			sta	sysApplData +0,x
			dex
			bpl	:51
endif
;---

			lda	#$ff			;TaskSwitcher deaktivieren (da noch
			sta	Flag_TaskAktiv		;nicht installiert...)

			jsr	FirstInit		;GEOS initialisieren.

			lda	#ST_WR_FORE		;Nur in Vordergrund schreiben.
			sta	dispBufferOn
			jsr	UseSystemFont		;Standard-Zeichensatz aktivieren.

			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)
			jsr	InitMouse		;Maustreiber initialisieren.

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			LoadB	year ,22		;Startdatum setzen.
			LoadB	month,01		;Das Jahrtausendbyte wird in
			LoadB	day  ,01		;":millenium" im Kernal gesetzt.
							;(siehe Kernal-Variablen)
;--- Konfiguration speichern.
			jsr	SaveConfigDACC		;GD.INI mit DACC-TYP aktualisieren.
			jsr	LoadGDINI		;GD.INI in GEOS-DACC laden.

;*** AutoBoot-Programme ausführen.
;Hinweis:
;Dabei wird zuerst GD.CONFIG gestartet
;und erst danach alle AUTOEXEC-Dateien!
:AUTO_INSTALL		jsr	i_MoveData		;AutoBoot-Routine kopieren.
			w	AutoBoot_a
			w	BASE_AUTO_BOOT
			w	(AutoBoot_b - AutoBoot_a)

			sei				;System initialisieren.
			cld

			ldx	#$ff			;Stack löschen.
			txs

			jmp	BASE_AUTO_BOOT		;AutoBoot starten.

;*** RAM-Treiber testen.
:TestDeviceRAM		ldy	#$00			;Testdaten erzeugen.
			lda	#%11101010
::52			sta	diskBlkBuf,y
			iny
			bne	:52

			jsr	:60			;DoRAMOp-Werte setzen.
			jsr	StashRAM		;Testdaten in REU speichern.

			ldy	#$00			;Prüfdaten erzeugen.
			lda	#%00010101
::53			sta	diskBlkBuf,y
			iny
			bne	:53

			jsr	:60			;DoRAMOp-Werte setzen.
			jsr	FetchRAM		;Testdaten aus REU einlesen.

			ldy	#$00			;Testdaten mit Prüfdaten
::54			lda	diskBlkBuf,y		;vergleichen.
			eor	#%11111111
			cmp	#%00010101
			bne	:55
			iny
			bne	:54

			ldx	#NO_ERROR
			b $2c
::55			ldx	#DEV_NOT_FOUND
			rts

;--- Werte für DoRAMOp setzen.
::60			lda	#$00
			ldx	#> diskBlkBuf
			sta	r0L
			stx	r0H

;			lda	#$00
			sta	r1L
			sta	r1H

;			lda	#$00
			ldx	#$01
			sta	r2L
			stx	r2H

;			lda	#$00
			sta	r3L
			rts

;*** Datei "GD.BOOT.1" nachladen.
:LoadSys_GEOS		jsr	Strg_LdGEOS_1		;Installationsmeldung ausgeben.

			ldx	#< FNamGBOOT_1		;GEOS-Kernal laden.
			ldy	#> FNamGBOOT_1

;*** Systemdatei nachladen.
:LoadSys_FILE		lda	#9			;Länge Dateiname = 9 Zeichen.
:LoadSys_USER		pha
			lda	#KRNL_BAS_IO_IN		;GEOS-Bereich ausblenden.
			sta	CPU_DATA
			pla
			jsr	SETNAM			;Dateiname festlegen.

			lda	#$01
			ldx	curDevice
			ldy	#$00
			jsr	SETLFS			;Dateiparameter festlegen.

			lda	#$00
			ldx	#< BASE_GEOS_SYS
			ldy	#> BASE_GEOS_SYS
			jsr	LOAD			;Datei laden.
			sei				;IRQ wieder sperren.
			bcs	:err			;Fehler ? Nein, weiter...

			lda	#RAM_64K		;GEOS-Bereich einblenden.
			sta	CPU_DATA

			jmp	Strg_OK			;Installationsmeldung ausgeben.
::err			jmp	ERR_EXIT_BASIC_L	;Fehler, Zurück zu BASIC.

;*** Datei "GD.BOOT.2" nachladen.
:LoadSys_GDOS		jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

if FALSE
			ldx	#< FNamGBOOT_2
			ldy	#> FNamGBOOT_2
			bne	LoadSys_FILE		;GDOS-Kernal über Kernal-ROM laden.
endif
if TRUE
			LoadB	r0L,%00000001
			LoadW	r6 ,FNamGBOOT_2
			LoadW	r7 ,BASE_GEOS_SYS -2
			jsr	GetFile			;GDOS-Kernal mit GEOS-Treiber laden.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jmp	Strg_OK			;Installationsmeldung ausgeben.
::err			jmp	ERR_EXIT_BASIC_L	;Fehler, Zurück zu BASIC.
endif

;*** GEOS-Laufwerkstreiber nachladen.
:LoadSys_DISK		jsr	Strg_LdDisk		;Installationsmeldung ausgeben.

			ldy	#0
::1			lda	FNamGDISK,y
			beq	:2
			iny
			cpy	#16
			bcc	:1

::2			tya
			ldx	#< FNamGDISK
			ldy	#> FNamGDISK
			jmp	LoadSys_USER

;*** GEOS-Laufwerkstreiber installieren.
:InitSys_DISK		jsr	Strg_InitDisk		;Installationsmeldung ausgeben.

			jsr	:testCBMkey		;CBM-Taste gedrückt ?
			php
			ldx	#< DDRV_SYS_DEVDATA
			ldy	#> DDRV_SYS_DEVDATA
			plp
			beq	:setbase		; => Ja, ser.Bus-Treiber laden.

			lda	Boot_Type
			bmi	:setbase
			and	#DrvCMD
			cmp	#DrvHD			;CMD-HD ?
			bne	:setbase		; => Nein, weiter...

			lda	DDRV_VAR_CONF		;PP-Modus aktivieren ?
			bpl	:setbase		; => Nein, weiter...

			txa				;OffSet auf PP-Treiber berechnen.
			clc
			adc	DDRV_PPOFFSET +0
			tax
			tya
			adc	DDRV_PPOFFSET +1
			tay

::setbase		stx	r0L			;Zeiger auf Treiberdaten
			sty	r0H			;setzen.

;			LoadW	r0,(BASE_GEOS_SYS +64 -2)
			jsr	CopySys_DISK		;Laufwerkstreiber installieren.

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;--- Auf C=-Taste testen.
::testCBMkey		php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	#%01111111
			sta	cia1base +0
			lda	cia1base +1
			stx	CPU_DATA
			plp
			and	#%00100000
			rts

;*** Kernal-Teil #1 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    nach $9000-$9C7F und $BF40-$FFFF kopiert.
:InitSys_GEOS		jsr	Strg_Install_1		;Installationsmeldung ausgeben.

;			sei
;			lda	#RAM_64K		;GEOS-Bereich einblenden.
;			sta	CPU_DATA		;(Ist bereits gesetzt)

;--- GEOS-Variablenspeicher löschen.

			jsr	InitSys_ClrVar		;GEOS-Variablen löschen.

			lda	#$bf			;Standard-GEOS-Hintergrundfarbe.
			jsr	InitSys_ClrCol		;Farb-RAM löschen.

			LoadW	r0,BASE_GEOS_SYS
			jsr	CopySys_GEOS		;GEOS-Kernal installieren.

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Kernal-Teil #2 installieren,ReBoot-Routine in REU kopieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;--- Ausgelagerte Kernal-Funktionen in RAM kopieren.
:InitSys_GDOS		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			jsr	CopySys_GDOS		;GDOS-Kernal installieren.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	Strg_OK			;Installationsmeldung ausgeben.

			jsr	Strg_Install_R		;Installationsmeldung ausgeben.

			jsr	CopySys_RBOOT		;RBOOT-Routine installieren.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jmp	Strg_OK			;Installationsmeldung ausgeben.
::err			jmp	ERR_EXIT_BASIC_R	;Abbruch nach BASIC.

;*** RAM-Fehler, zurück zum BASIC.
:ERR_EXIT_BASIC_R	lda	#KRNL_BAS_IO_IN
			sta	CPU_DATA
			cli

			jsr	Strg_LoadError		;Fehlermeldung ausgeben und Ende.
			jmp	ROM_BASIC_READY		;Abbruch nach BASIC.

;*** Load-Fehler, zurück zum BASIC.
:ERR_EXIT_BASIC_L	lda	#KRNL_BAS_IO_IN
			sta	CPU_DATA
			cli

			jsr	Strg_DiskError		;Fehlermeldung ausgeben und Ende.
			jmp	ROM_BASIC_READY		;Abbruch nach BASIC.
