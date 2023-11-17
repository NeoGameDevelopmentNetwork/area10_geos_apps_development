; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;"Strg_name"-Routinen geben eine Meldung auf dem Bildschirm aus.
;******************************************************************************
			t "G3_SymMacExt"
			t "G3_V.Cl.64.Boot"

			n "GEOS64.BOOT"

			o BASE_GEOSBOOT -2		;BASIC-Start beachten!
			p InitBootProc

			z $80
			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Installiert MegaPatch 64"
			h "in Ihrem GEOS-System..."
endif

if Sprache = Englisch
			h "Installs MegaPatch 64"
			h "in your GEOS-kernal..."
endif

if .p
			t "s.GEOS64.1.ext"
			t "s.GEOS64.2.ext"
			t "s.GEOS64.3.ext"
			t "s.GEOS64.4.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"
endif

;*** Füllbytes.
.L_KernelData		w BASE_GEOSBOOT			;DummyBytes, da Programm über
							;BASIC-LOAD geladen wird!!!

;*** Einsprung aus GEOS-Startprogramm.
:InitBootProc		jmp	MainInit

;*** Boot-Informationen einbinden.
			t "-G3_BootVar"

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
:FNamGEOS_B		b "GEOS64.BOOT",NULL
:FNamGEOS_1		b "GEOS64.1",NULL
:FNamGEOS_2		b "GEOS64.2",NULL
:FNamGEOS_3		b "GEOS64.3",NULL
:FNamGEOS_4		b "GEOS64.4",NULL
:FNamRBOOT_B		b "RBOOT64.BOOT",NULL

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

			ldx	#$ff			;SuperCPU verügbar ?
			lda	$d0bc
			bpl	:51
			inx
::51			stx	Device_SCPU

			ldx	#$ff			;RAMLink verügbar ?
			lda	EN_SET_REC
			cmp	#$78
			beq	:52
			inx
::52			stx	Device_RL

			lda	Boot_Type
			and	#%11110000
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
			bne	:53			; => Nein, weiter...

			lda	curDevice		;RL-Geräteadresse speichern.
			sta	RL_BootAddr
			cmp	#12			;Adresse #8 bis #11 ?
			bcs	:54			; => Nein, weiter...

::53			lda	curDevice		;Boot-Laufwerk speichern.
			sta	Boot_Drive

::54			jsr	PrintBootInfo

;*** Speichererweiterung wählen.
:DetectRAM		jsr	FindRamExp		;Speichererweiterung suchen.

;*** GEOS System laden.
:Initialize		jsr	Strg_Initialize
			jsr	Strg_Titel

;*** Startlaufwerk initialisieren.
			jsr	FindRL_Part		;RAMLink-Startpartition ermitteln.

;*** GEOS-Kernal einlesen und installieren.
:Load_GEOS_MP		jsr	LoadSys_GEOS		;Kernal-Teil #1 laden und
			jsr	InitSys_GEOS		;installieren.

			sei
			lda	#RAM_64K		;64K-RAM-Bereich einblenden.
			sta	CPU_DATA

			jsr	InitSys_SetRAM		;DACC-Information festlegen.
			txa				;DACC-Informationen gültig?
			bne	:49			; => Nein, Abbruch...

			jsr	Strg_MgrRAM		;Installationsmeldung ausgeben.
			jsr	InitDeviceRAM		;RAM-Patches installieren.
			txa
			bne	:49

			jsr	Strg_OK			;Installationsmeldung ausgeben.

;--- Hinweis:
;GEOS-Information müssen hier bereits gesetzt werden, da bei der Installation
;von GEOS.2 bereits StashRAM verwendet wird.
;Für das testen der Speichererweiterung wird StashRAM/FetchRAM verwendet.
			jsr	InitSys_ClrVar		;GEOS-Variablen löschen.
			jsr	InitSys_SetRAM		;DACC-Information festlegen.
			txa				;DACC-Informationen gültig?
			bne	:49			; => Nein, Abbruch...

			lda	Device_SCPU		;SCPU verfügbar ?
			beq	:51			;=> Nein, weiter...

			lda	ExtRAM_Type
			cmp	#RAM_SCPU		;SuperCPU/RAMCard als GEOS-DACC ?
			bne	:48			; => Nein, weiter...

			sei
			lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA

;--- Speichermanagement der SuperCPU aktualisieren.
			sta	$d07e

			lda	#$00			;SuperCPU-Variablen
			sta	$d27c			;aktualisieren.
			lda	RamBankFirst +1
			clc
			adc	ramExpSize
			sta	$d27d

			sta	$d07f

;--- GEOS-Code für SuperCPU patchen.
::48			jsr	Strg_MgrSCPU		;Installationsmeldung ausgeben.
			jsr	InitDeviceSCPU		;SuperCPU patchen.
			jsr	Strg_OK			;Installationsmeldung ausgeben.

			lda	#RAM_64K		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA

::51			jsr	Strg_TestRAMExp		;RAM-Treiber testen.
			jsr	TestDeviceRAM
			txa
			beq	:50
::49			jsr	Strg_LoadError		;Erweiterung nicht erkannt, Fehler.
			jmp	ROM_BASIC_READY		;Abbruch zum BASIC.

::50			jsr	Strg_OK			;Installationsmeldung ausgeben.

			jsr	LoadSys_MPp1		;Kernal-Teil #2 laden.
			jsr	InitSys_MPp1

			jsr	LoadSys_MPp2a		;Kernal-Teil #3 laden.
			jsr	InitSys_MPp2a

			jsr	LoadSys_MPp2b		;Kernal-Teil #4 laden.
			jsr	InitSys_MPp2b

;--- Hinweis:
;GEOS-Information müssen hier erneut gesetzt werden, da
;beim laden von GEOS.3 der Bereich ab $8000 teilw. überschrieben wird.
if FALSE
			jsr	InitSys_ClrVar		;GEOS-Variablen löschen.
			jsr	InitSys_SetRAM		;DACC-Information festlegen.
			txa				;DACC-Informationen gültig?
			bne	:49			; => Nein, Abbruch...
endif							;Befehl deaktiviert ein vorhandenes

;--- CMD-HD-PP-Kabel deaktivieren.
if FALSE
			jsr	InitDeviceHD		;"P0"-Befehl ausführen. Dieser
endif							;Befehl deaktiviert ein vorhandenes
							;Kabel von der RL zur HD.

;*** GEOS-Variablen initialisieren.
:InitSys_GEOSVar	jsr	Strg_InitGEOS		;Installationsmeldung ausgeben.

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
::1			sta	sysApplData +0,x
			dex
			bpl	:1
endif
;---

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

			lda	#%01110000		;Kein MoveData, DiskDriver in REU,
			sta	sysRAMFlg		;ReBoot-Kernal in REU.

			lda	#$ff			;TaskSwitcher deaktivieren (da noch
			sta	Flag_TaskAktiv		;nicht installiert... Erst über
							;MegaEditor!!!)
			jsr	FirstInit		;GEOS initialisieren.

			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)
			jsr	InitMouse		;Mausabfrage starten (nur temporär
							;notwendig, da gewünschter Treiber
							;erst später geladen wird!)

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			LoadB	year ,18		;Startdatum setzen.
			LoadB	month,01		;Das Jahrtausendbyte wird in
			LoadB	day  ,01		;":millenium" im Kernal gesetzt.
							;(siehe Kernal/-G3_MP3_VAR)

			lda	#$01			;Anzahl Laufwerke löschen.
			sta	numDrives

;*** Laufwerksvariablen initialisieren.
:InitSys_GEOSDDrv	ldy	Boot_Drive		;Startlaufwerk aktivieren.
			sty	curDrive

			lda	Boot_Type		;Typ "RAMLink" nach "RAMxy"
			and	#%11110000		;wandeln.
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
			bne	:51			; => Nein, weiter...

			lda	Boot_Type		;Emulationstyp isolieren und
			and	#%00001111		;RAM-Flag setzen.
			ora	#%10000000
			bne	:52

::51			lda	Boot_Type
::52			sta	curType			;Emulationstyp speichern.
			sta	driveType   -8,y

			lda	Boot_Mode		;Laufwerksmodi speichern.
			sta	RealDrvMode -8,y
			lda	Boot_Type		;Laufwerkstyp speichern.
			sta	RealDrvType -8,y
			and	#%11110000
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
			bne	:53			; => Nein, weiter...

			lda	Boot_Part   +1		;Bootpartition aktivieren.
			sta	ramBase     -8,y

::53			lda	Boot_Drive		;Startlaufwerk aktivieren. Dabei
			jsr	SetDevice		;werden bei der RAMLink auch die
			jsr	OpenDisk		;Laufwerkstreiber-Variablen gesetzt.

;*** Standard-Gerätetreiber laden.
			jsr	LoadDev_Printer		;Druckertreiber laden.
			jsr	LoadDev_Mouse		;Eingabetreiber laden.
			jsr	InitMouse		;Maustreiber initialisieren.

;*** Konfiguration speichern.
			jsr	SaveRamConfig

;*** AutoBoot-Programme ausführen.
:AUTO_INSTALL		jsr	i_MoveData		;AutoBoot-Routine kopieren.
			w	AutoBoot_a
			w	BASE_AUTO_BOOT
			w	(AutoBoot_b - AutoBoot_a)

			jmp	BASE_AUTO_BOOT		;AutoBoot starten.

;******************************************************************************
;*** Systemroutinen
;******************************************************************************
			t "-G3_BootShared"
;******************************************************************************

;*** Datei "GEOS.1.SYS" nachladen.
:LoadSys_GEOS		jsr	Strg_LdGEOS_1		;Installationsmeldung ausgeben.

			ldy	#>FNamGEOS_1
			ldx	#<FNamGEOS_1
			jmp	SYSTEM_ROM_LOAD

;*** Datei "GEOS.2.SYS" nachladen.
:LoadSys_MPp1		lda	#"1"
			sta	BootText41+14
			sta	BootText51+13
			jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

			ldy	#>FNamGEOS_2
			ldx	#<FNamGEOS_2
			jmp	SYSTEM_ROM_LOAD

;*** Datei "GEOS.3.SYS" nachladen.
:LoadSys_MPp2a		lda	#"2"
			sta	BootText41+14
			sta	BootText51+13
			jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

			ldy	#>FNamGEOS_3
			ldx	#<FNamGEOS_3
			jmp	SYSTEM_ROM_LOAD

;*** Datei "GEOS.4.SYS" nachladen.
:LoadSys_MPp2b		lda	#"3"
			sta	BootText41+14
			sta	BootText51+13
			jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

			ldy	#>FNamGEOS_4
			ldx	#<FNamGEOS_4

;*** Systemdatei nachladen.
:SYSTEM_ROM_LOAD	lda	#KRNL_BAS_IO_IN		;GEOS-Bereich ausblenden.
			sta	CPU_DATA
			lda	#8			;Länge Dateiname = 8 Zeichen.
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
			bcs	ERROR			;Fehler ? Nein, weiter...

			lda	#RAM_64K		;GEOS-Bereich einblenden.
			sta	CPU_DATA

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Fehler, zurück zum BASIC.
:ERROR			jsr	Strg_LoadError		;Fehlermeldung ausgeben und Ende.

			lda	#KRNL_BAS_IO_IN
			sta	CPU_DATA
			cli

			jmp	ROM_BASIC_READY

;*** Kernal-Teil #1 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    nach $9000-$9C7F und $BF40-$FFFF kopiert.
:InitSys_GEOS		jsr	Strg_Install_1		;Installationsmeldung ausgeben.

;			sei
;			lda	#RAM_64K		;GEOS-Bereich einblenden.
;			sta	CPU_DATA		;Ist bereits gesetzt.

			LoadW	r0,BASE_GEOS_SYS	;Laufwerkstreiber aus Startdatei
			LoadW	r1,DISK_BASE		;nach $9000 kopieren.

			ldx	#$10
			ldy	#$00
::52			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:52
			inc	r0H
			inc	r1H
			dex
			bne	:52

			LoadW	r1,$bf40		;GEOS-Kernal aus Startdatei
							;nach $BF40 kopieren.
			ldy	#$00
::53			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:53
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:53

			ldy	#$00
::54			lda	(r0L),y
			sta	(r1L),y
			iny
			cpy	#$c0
			bne	:54

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Kernal-Teil #2 installieren,ReBoot-Routine in REU kopieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;--- Ausgelagerte Kernal-Funktionen in RAM kopieren.
:InitSys_MPp1		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			lda	#<MP3_BANK_1
			ldx	#>MP3_BANK_1
			ldy	#$09
			jsr	InitSys_Core

;--- ReBoot-Kernal in RAM kopieren.
			jsr	Strg_Install_R		;Installationsmeldung ausgeben.

			ldx	#$00			;Zeiger auf ReBoot-Datentabelle.
			lda	GEOS_RAM_TYP		;RAM-Typ einlesen.
			cmp	#RAM_SCPU		;SuperCPU ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_RL			;RAMLink ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_REU		;C=REU ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_BBG		;BBGRAM ?
			beq	:51			;Ja, weiter...
			ldx	#$00

::51			lda	Vec_ReBoot +0,x		;Startadresse für ReBoot-Routine
			sta	r0L			;in MegaEditor-Programm einlesen.
			lda	Vec_ReBoot +1,x
			sta	r0H

			lda	#$00
			sta	r1L
			sta	r2L
			sta	r3L
			lda	#>R1_ADDR_REBOOT	;Startadresse in REU.
			sta	r1H
			lda	#>R1_SIZE_REBOOT	;Anzahl Bytes.
			sta	r2H
			jsr	StashRAM		;ReBoot-Routine speichern.
			jsr	VerifyRAM
			and	#%00100000
			bne	:52
			jmp	Strg_OK			;Installationsmeldung ausgeben.

::52			jsr	Strg_LoadError		;Fehler beim Speichertransfer.
			jmp	ROM_BASIC_READY		;FEHLER!, Abbruch...

;*** Kernal-Teil #3 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
:InitSys_MPp2a		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			lda	#<MP3_BANK_2a
			ldx	#>MP3_BANK_2a
			ldy	#$03
			jmp	InitSys_Core

;*** Kernal-Teil #4 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
:InitSys_MPp2b		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			lda	#<MP3_BANK_2b
			ldx	#>MP3_BANK_2b
			ldy	#$03

;*** Programmdaten in Speicherbank #1 kopieren.
;    Übergabe:		AKKU = LowByte -Tabelle,
;			xReg = HighByte-Tabelle,
;			yReg = Anzahl Datenblöcke.
:InitSys_Core		sta	:53 +1			;Tabellenzeiger speichern.
			stx	:53 +2
			sty	:54 +1

			lda	#$00			;Kernal-Funktionen in REU
::51			pha				;kopieren.
			asl
			sta	:52 +1
			asl
			clc
::52			adc	#$ff
			tay
			ldx	#$00
::53			lda	$ffff,y			;Zeiger auf Position in Startdatei
			sta	r0L  ,x			;einlesen.
			iny
			inx
			cpx	#$06
			bcc	:53

			lda	MP3_64K_SYSTEM		;Speicherbank festlegen.
			sta	r3L

			jsr	StashRAM		;Daten in REU kopieren.
			jsr	VerifyRAM
			and	#%00100000
			bne	:55

			pla
			clc
			adc	#$01
::54			cmp	#$ff			;Alle Datenblöcke kopiert ?
			bcc	:51			; => Nein, weiter...
			jmp	Strg_OK			;Installationsmeldung ausgeben.

::55			jsr	Strg_LoadError		;Fehler beim Speichertransfer.
			jmp	ROM_BASIC_READY		;FEHLER!, Abbruch...

;******************************************************************************
;*** RAM-Treiber installieren.
;******************************************************************************
			t "-G3_InitDevRAM"
;******************************************************************************

;******************************************************************************
;*** SuperCPU patchen.
;******************************************************************************
			t "-G3_InitDevSCPU"
;******************************************************************************

;******************************************************************************
;*** CMD-HD initialisieren.
;******************************************************************************
if FALSE
			t "-G3_InitDevHD"
endif
;******************************************************************************

;******************************************************************************
;*** Boot-Meldungen ausgeben.
;******************************************************************************
			t "-G3_PrntString"
;******************************************************************************

;******************************************************************************
;*** Boot-Meldungen einbinden.
;******************************************************************************
			t "-G3_BootInfo"
;******************************************************************************

;******************************************************************************
;*** Der folgende Datenbereich wird auch von "GEOS.MP3" mitverwendet.
;*** Der Datenbereich wird dazu von "GEOS.MP3" nachgeladen.
;******************************************************************************
.S_KernelData		t "-G3_KernalData"
;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
.E_KernelData		g BASE_GEOS_SYS
;******************************************************************************

;******************************************************************************
;*** ACHTUNG!
;*** Alle folgenden Routinen werden beim Start teilweise überschrieben!
;******************************************************************************
			t "-R3_DetectRLNK"
			t "-R3_DetectSRAM"
			t "-R3_DetectCREU"
			t "-R3_DetectGRAM"
			t "-R3_GetSizeSRAM"
			t "-R3_GetSizeCREU"
			t "-R3_GetSizeGRAM"
			t "-R3_GetSBnkGRAM"
			t "-G3_SysInfo"
			t "-G3_GetRLPEntry"
			t "-G3_FindRAMExp"
;******************************************************************************
