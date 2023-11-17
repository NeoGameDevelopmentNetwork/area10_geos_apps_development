; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Angaben zur Speichererweiterung.
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
:FNamGBOOT		b "GD.BOOT",NULL
:FNamGBOOT_1		b "GD.BOOT.1",NULL
:FNamGBOOT_2		b "GD.BOOT.2",NULL
:FNamRBOOT		b "GD.RBOOT.SYS",NULL
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
:MainInit		sei				;IRQ sperren.
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

if GD_NG_MODE = TRUE
			jsr	InitBootDevice		;Boot-Laufwerk übernehmen.
			txa				;Laufwerk erkannt ?
			beq	:1			; => Ja, weiter...
			jmp	ERR_EXIT_BASIC_L	;Fehler, zurück zum BASIC.
endif

::1			jsr	FindRL_Part		;RAMLink-Startpartition ermitteln.

;*** Variablenspeicher initialisieren.
:Init_GEOS_Var		jsr	InitSys_ClrVar		;GEOS-Variablen löschen.

;*** GEOS-Kernal einlesen und installieren.
:Load_GEOS_GD		jsr	LoadSys_GEOS		;Kernal-Teil #1 laden und
			jsr	InitSys_GEOS		;installieren.

;--- NG-Laufwerkstreiber einlesen.
if GD_NG_MODE = TRUE
			jsr	LoadSys_DISK		;Laufwerkstreiber laden und
			jsr	InitSys_DISK		;installieren.
endif

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

;--- GD3-Kernal installieren.
;Ab hier kann wieder GEOS-":DoRAMOp"
;verwendet werden, da der RAM-Treiber
;installiert ist.
			jsr	LoadSys_GD3		;Kernal-Teil #2 laden.
			jsr	InitSys_GD3

;--- Ergänzung: 09.09.18/M.Kanet
;Wenn kein PP-Kabel vorhanden ist, dann fürt dieser
;Befehl zu Problemen mit andere Hardware/Speedern.
;Code ist deaktiviert. TurboDOS+PP-Kabel funktioniert.
;--- CMD-HD-PP-Kabel deaktivieren.
;			jsr	InitDeviceHD		;"P0"-Befehl ausführen. Dieser
							;Befehl deaktiviert ein vorhandenes
							;Kabel von der RL zur HD.

;*** GEOS-Variablen initialisieren.
:InitSys_GEOSVar	jsr	Strg_InitGEOS		;Installationsmeldung ausgeben.

			sei
			cld
			ldx	#$ff			;Stack-Pointer löschen.
			txs
			lda	#IO_IN			;I/O-Bereiche einblenden.
			sta	CPU_DATA

			lda	cia1base +15		;I/O-Register initialisieren.
			and	#$7f
			sta	cia1base +15
			lda	#$81
			sta	cia1base +11
			lda	#$00
			sta	cia1base +10
			sta	cia1base + 9
			sta	cia1base + 8

			lda	#RAM_64K		;GEOS-RAM aktivieren.
			sta	CPU_DATA

			ldx	#$07			;Sprite-Pointer setzen.
			lda	#$bb
::51			sta	$8fe8,x
			dex
			bpl	:51

			lda	#$bf
			sta	$8ff0

			lda	#%01110000		;Kein MoveData, DiskDriver in REU,
			sta	sysRAMFlg		;ReBoot-Kernal in REU.
			lda	#$ff			;TaskSwitcher deaktivieren (da noch
			sta	Flag_TaskAktiv		;nicht installiert...)

			jsr	FirstInit		;GEOS initialisieren.

			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)
			jsr	InitMouse		;Mausabfrage starten (nur temporär
							;notwendig, da gewünschter Treiber
							;erst später geladen wird!)

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			LoadB	year ,21		;Startdatum setzen.
			LoadB	month,01		;Das Jahrtausendbyte wird in
			LoadB	day  ,01		;":millenium" im Kernal gesetzt.
							;(siehe Kernal/-G3_GD3_VAR)

			lda	#$01			;Anzahl Laufwerke löschen.
			sta	numDrives

;*** Laufwerksvariablen initialisieren.
:InitSys_GEOSDDrv	ldy	Boot_Drive		;Startlaufwerk aktivieren.
			cpy	#12
			bcc	:1
			ldy	#8
::1			sty	curDrive

			lda	Boot_Type		;Typ "RAMLink" nach "RAMxy"
			sta	RealDrvType -8,y
			and	#%11110000		;wandeln.
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

;--- Hinweis:
;Kein ":SetDevice" ausführen, da hier
;das Boot-Laufwerk auch >12 sein kann.
;Nur ":OpenDisk" ausführen um bei einer
;RAMLink den GEOS-Laufwerkstreiber zu
;initialisieren.
			jsr	OpenDisk		;Laufwerkstreiber-Variablen gesetzt.

;*** Standard-Gerätetreiber laden.
			jsr	LoadDev_Printer		;Druckertreiber laden.
			jsr	LoadDev_Mouse		;Eingabetreiber laden.

;--- Ergänzung: 09.02.21/M.Kanet
;Maustreiber nach dem laden initialisieren.
			jsr	InitMouse		;Maustreiber initialisieren.

;*** Konfiguration speichern.
			jsr	SaveConfigDACC

;*** AutoBoot-Programme ausführen.
:AUTO_INSTALL		jsr	i_MoveData		;AutoBoot-Routine kopieren.
			w	AutoBoot_a
			w	BASE_AUTO_BOOT
			w	(AutoBoot_b - AutoBoot_a)

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

;*** Datei "GEOS.1.SYS" nachladen.
:LoadSys_GEOS		jsr	Strg_LdGEOS_1		;Installationsmeldung ausgeben.

			ldx	#<FNamGBOOT_1
			ldy	#>FNamGBOOT_1
			bne	LoadSys_FILE

;*** Datei "GEOS.2.SYS" nachladen.
:LoadSys_GD3		jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

			ldx	#<FNamGBOOT_2
			ldy	#>FNamGBOOT_2

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
			ldx	#<BASE_GEOS_SYS
			ldy	#>BASE_GEOS_SYS
			jsr	LOAD			;Datei laden.
			sei				;IRQ wieder sperren.
			bcs	ERR_EXIT_BASIC_L	;Fehler ? Nein, weiter...

			lda	#RAM_64K		;GEOS-Bereich einblenden.
			sta	CPU_DATA

			jmp	Strg_OK			;Installationsmeldung ausgeben.
::err			jmp	ERR_EXIT_BASIC_L	;Fehler, Zurück zu BASIC.

;*** GEOS-Laufwerkstreiber nachladen.
if GD_NG_MODE = TRUE
:LoadSys_DISK		lda	#<Strg_LdDISK		;Installationsmeldung ausgeben.
			ldy	#>Strg_LdDISK
			jsr	Strg_CurText

			ldy	#0
::1			lda	FNamGDISK,y
			beq	:2
			iny
			cpy	#16
			bcc	:1

::2			tya
			ldx	#<FNamGDISK
			ldy	#>FNamGDISK
			jmp	LoadSys_USER

;*** GEOS-Laufwerkstreiber installieren.
:InitSys_DISK		lda	#<Strg_Install_D	;Installationsmeldung ausgeben.
			ldy	#>Strg_Install_D
			jsr	Strg_CurText

			LoadW	r0,(BASE_GEOS_SYS +64 -2)
			jsr	CopySys_DISK		;Laufwerkstreiber installieren.

			jmp	Strg_OK			;Installationsmeldung ausgeben.
endif

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

if GD_NG_MODE = FALSE
			LoadW	r0,BASE_GEOS_SYS
			jsr	CopySys_DISK		;Laufwerkstreiber installieren.

			LoadW	r0,BASE_GEOS_SYS + DISK_DRIVER_SIZE
			jsr	CopySys_GEOS		;GEOS-Kernal installieren.
endif

if GD_NG_MODE = TRUE
			LoadW	r0,BASE_GEOS_SYS
			jsr	CopySys_GEOS		;GEOS-Kernal installieren.
endif

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Kernal-Teil #2 installieren,ReBoot-Routine in REU kopieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;--- Ausgelagerte Kernal-Funktionen in RAM kopieren.
:InitSys_GD3		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			jsr	CopySys_GD3		;GeoDOS-Kernal installieren.
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
