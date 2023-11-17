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
			t "G3_V.Cl.128.Boot"

			n "GEOS128.BOOT"

			o BASE_GEOSBOOT -2		;BASIC-Start beachten!
			p InitBootProc

			z $40

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Installiert MegaPatch 128"
			h "in Ihrem GEOS-System..."
endif

if Sprache = Englisch
			h "Installs MegaPatch 128"
			h "in your GEOS-kernal..."
endif

if .p
			t "s.GEOS128.1.ext"
			t "s.GEOS128.2.ext"
			t "s.GEOS128.3.ext"
			t "s.GEOS128.4.ext"
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
:FNamGEOS_B		b "GEOS128.BOOT",NULL
:FNamGEOS_0		b "GEOS128.?",NULL
:FNamRBOOT_B		b "RBOOT128.BOOT",NULL

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

;*** Resetroutine bei Hardware-Reset
:ResetGEOS		LoadB	MMU,$7e			;RAM 1 und IO
			jmp	SystemReBoot		;GEOS ReBoot

; Dieses Programm befindet sich sowohl in Bank 0 als auch in Bank 1
; Beachte geänderte Variablen beim Bankwechsel !
;*** Hardware erkennen.
:MainInit		sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
;			ldx	#$ff			;Stack-Pointer löschen.
;			txs

			lda	#%00000111		;Common Area $0000 - $4000 aktiv.
			sta	RAM_Conf_Reg
			lda	#%00001110		;Bank#0, ROM ab $c000 aktiv + I/O.
			sta	MMU

			ldx	#$ff			;SuperCPU verfügbar ?
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
:Load_GEOS_MP		jsr	LoadSys_GEOS_B0		;Kernal-Teil #0 (Bank 0) laden und
			jsr	InitSys_GEOS_B0		;installieren.

			sei				;Interrupt sperren.
			lda	#$7f			;GEOS-Bank 1-Bereich einblenden.
			sta	MMU

			jsr	LoadSys_GEOS_B1		;Kernal-Teil #1 (Bank 1) laden und
			jsr	InitSys_GEOS_B1		;installieren.

			sei				;Interrupt sperren.
			lda	#$7e			;Bank#1 und I/O aktivieren.
			sta	MMU

			jsr	InitSys_SetRAM		;DACC-Information festlegen.
			txa				;DACC-Informationen gültig?
			bne	:49			; => Nein, Abbruch...

;--- Ergänzung: 08.09.18/M.Kanet
;Bank#1 aktivieren da hier das GEOS-System abgelegt ist.
;CommonArea $0000-$3FFF aktivieren da hier das Startprogramm liegt.
;RAM und I/O-Bereich aktivieren.
;			sei				;Interrupt sperren.
;			lda	#%01111110		;Bank#1 und I/O bereits aktiv.
;			sta	MMU
;			lda	#%00000111
;			sta	RAM_Conf_Reg

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

;			sei
;			lda	#$7e			;Bank#1 und I/O bereits aktiv.
;			sta	MMU

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

::51			jsr	Strg_TestRAMExp		;RAM-Treiber testen.
			jsr	TestDeviceRAM
			txa
			beq	:50
::49			jsr	Strg_LoadError		;Erweiterung nicht erkannt, Fehler.
			jmp	ROM_BASIC_READY		;Abbruch zum BASIC.

::50			jsr	Strg_OK			;Installationsmeldung ausgeben.

;*** MegaPatch Kernal laden und installieren.
;			lda	#$00			;Wird durch LoadSys_MPp1 gesetzt.
;			sta	MMU
			jsr	LoadSys_MPp1		;Kernal-Teil #2 laden.
;			lda	#$7e			;Bank#1 und I/O bereits aktiv.
;			sta	MMU
			jsr	InitSys_MPp1

;			lda	#$00			;Wird durch LoadSys_MPp2 gesetzt.
;			sta	MMU
			jsr	LoadSys_MPp2a		;Kernal-Teil #3 laden.
;			lda	#$7e			;Bank#1 und I/O bereits aktiv.
;			sta	MMU
			jsr	InitSys_MPp2a

;			lda	#$00			;Wird durch LoadSys_MPp2 gesetzt.
;			sta	MMU
			jsr	LoadSys_MPp2b		;Kernal-Teil #4 laden.
;			lda	#$7e			;Bank#1 und I/O bereits aktiv.
;			sta	MMU
			jsr	InitSys_MPp2b

;--- Hinweis:
;GEOS-Information müssen hier erneut gesetzt werden, da
;beim laden von GEOS.3 der Bereich ab $8000 teilw. überschrieben wird.
if FALSE
			jsr	InitSys_ClrVar		;GEOS-Variablen löschen.
			jsr	InitSys_SetRAM		;DACC-Information festlegen.
			txa				;DACC-Informationen gültig?
			bne	:49			; => Nein, Abbruch...
endif

;*** GEOS-Variablen initialisieren.
;--- Ergänzung: 10.09.18/M.Kanet
;GEOS.BOOT setzt hier RAM_Conf_Reg auf %01000000 = VIC Bank#1 ohne CommonArea.
;So lange CommonArea aktiv sieht VIC den 40Z-Bildschirm bei $0400.
;Wird die CommonArea abgeschaltet um auf Bank #1 zugreifen zu können
;wird am Bildschirm Speicherinhalt dargestellt => Flackern beim Systemstart.
;Code sollte geprüft und optimiert werden.
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

			sei	 			;Interrupt sperren
			cld	 			;Dezimalflag löschen
			ldx	#$ff			;Stapelzeiger löschen
			txs

;			LoadB	MMU,$7e			;Bank#1 und I/O bereits aktiv.
			LoadB	RAM_Conf_Reg,$40	;VIC Bank#1.

			ldx	#0			;1 Mhz
			lda	Mode_Conf_Reg		;40(1)/80(2) Zeichen Modus
			and	#$80			;Flag maskieren und umdrehen
			eor	#$80			;umdrehen und in graphMode
			sta	graphMode		;speichern 40($00)/80($80)
			bpl	:40
			ldx	#1			;2 Mhz
::40			stx	CLKRATE

			LoadB	$dd0d,$7f		;IRQ sperren
			lda	$dd0d			;und löschen
			LoadB	$d011,$1b		;Grafikmodus 40Zeichen an

			lda	#%01110000		;Kein MoveData, DiskDriver in REU,
			sta	sysRAMFlg		;ReBoot-Kernal in REU.

			lda	#$ff			;TaskSwitcher deaktivieren (da noch
			sta	Flag_TaskAktiv		;nicht installiert... Erst über
							;MegaEditor!!!)
			jsr	FirstInit		;GEOS Initialisierung

			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)
			ldx	#$00
			stx	firstBoot
			stx	PrntFileName
			stx	inputDevName
			lda	#$08
			sta	interleave
			lda	$dc0f			;Uhr-Register setzen
			and	#$7f
			sta	$dc0f
			lda	#$81
			sta	$dc0b
;			ldx	#$00
			stx	$dc0a
			stx	$dc09
			stx	$dc08
			lda	#18
			sta	year			;Startdatum setzen.
;			ldx	#1
			inx
			stx	month			;Das Jahrtausendbyte wird in
			stx	day			;":millenium" im Kernal gesetzt.
							;(siehe Kernal/-G3_MP3_VAR)

			LoadB	RAM_Conf_Reg,$44	;Common Area $0000 - $03ff
			ldy	#7
::7			lda	ResetGEOS,y		;Hardware-Reset Routine
			sta	$03e4,y			;installieren
			dey	 			;in Bank 0
			bpl	:7
			LoadB	RAM_Conf_Reg,$40

;*** Laufwerksvariablen initialisieren.
;Die Daten werden dabei aus der CommonArea $0000-$3FFF/Bank#0 = $47 nach
;Bank#1 = $40 kopiert. Bit %6 ginbt dabei die BANK für den VIC an.
:InitSys_GEOSDDrv	LoadB	RAM_Conf_Reg,$47	;Common Area $0000 - $4000 aktiv
			ldy	Boot_Drive		;Startlaufwerk aktivieren.
			LoadB	RAM_Conf_Reg,$40
			sty	curDrive

			LoadB	RAM_Conf_Reg,$47	;Common Area $0000 - $4000 aktiv
			lda	Boot_Type		;Typ "RAMLink" nach "RAMxy"
			and	#%11110000		;wandeln.
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
			bne	:51			; => Nein, weiter...

			lda	Boot_Type		;Emulationstyp isolieren und
			and	#%00001111		;RAM-Flag setzen.
			ora	#%10000000
			bne	:52

::51			lda	Boot_Type
::52			ldx	#$40
			stx	RAM_Conf_Reg
			sta	curType			;Emulationstyp speichern.
			sta	driveType   -8,y

			lda	Boot_Mode
			sta	RealDrvMode -8,y

			LoadB	RAM_Conf_Reg,$47	;Common Area $0000 - $4000 aktiv
			lda	Boot_Type		;Laufwerkstyp speichern.
			ldx	#$40
			stx	RAM_Conf_Reg
			sta	RealDrvType -8,y
			and	#%11110000
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
			bne	:53			; => Nein, weiter...

			LoadB	RAM_Conf_Reg,$47	;Common Area $0000 - $4000 aktiv
			lda	Boot_Part   +1		;Bootpartition aktivieren.
			ldx	#$40
			stx	RAM_Conf_Reg
			sta	ramBase     -8,y

::53			LoadB	RAM_Conf_Reg,$47	;Common Area $0000 - $4000 aktiv
			lda	Boot_Drive		;Startlaufwerk aktivieren. Dabei
			ldx	#$40
			stx	RAM_Conf_Reg
			jsr	SetDevice		;werden bei der RAMLink auch die
			jsr	OpenDisk		;Laufwerkstreiber-Variablen gesetzt.

;*** Standard-Gerätetreiber laden.
			jsr	LoadDev_Printer		;Druckertreiber laden.
			jsr	LoadDev_Mouse		;Eingabetreiber laden.
			jsr	InitMouse		;Initialisierung des Maustr.

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

;*** Datei "GEOS.0" nachladen.
;Kernel Bank 0
:LoadSys_GEOS_B0	jsr	Strg_LdGEOS_1		;Installationsmeldung ausgeben.

if FALSE
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU

			lda	#0			;($3f) RAM 0 (für Speicher)
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE
endif
			ldy	#$00
			jmp	LoadSys_G0

;*** Datei "GEOS.1" nachladen.
;Kernel Bank 1
:LoadSys_GEOS_B1	jsr	Strg_LdGEOS_128		;Installationsmeldung ausgeben.

if FALSE
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU

			lda	#1			;($3f) RAM 1 (für Speicher)
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE
endif
			ldy	#$01
			jmp	LoadSys_G1

;*** Datei "GEOS.2.SYS" nachladen.
:LoadSys_MPp1		lda	#"1"
			sta	BootText41+14
			sta	BootText51+13
			jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

if FALSE
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU

			lda	#1			;($3f) RAM 1 (für Speicher)
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE
endif
			ldy	#$01
			jmp	LoadSys_G2

;*** Datei "GEOS.3.SYS" nachladen.
:LoadSys_MPp2a		lda	#"2"
			sta	BootText41+14
			sta	BootText51+13
			jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

if FALSE
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU

			lda	#1			;($3f) RAM 1 (für Speicher)
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE
endif
			ldy	#$01
			jmp	LoadSys_G3

;*** Datei "GEOS.4.SYS" nachladen.
:LoadSys_MPp2b		lda	#"3"
			sta	BootText41+14
			sta	BootText51+13
			jsr	Strg_LdGEOS_2		;Installationsmeldung ausgeben.

if FALSE
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU

			lda	#1			;($3f) RAM 1 (für Speicher)
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE
endif
			ldy	#$01
			jmp	LoadSys_G4

;*** Systemdatei nachladen.
;    Übergabe: XReg/YReg = Zeiger auf Dateiname "GEOS128.x"
:LoadSys_G0		lda	#"0"
			b $2c
:LoadSys_G1		lda	#"1"
			b $2c
:LoadSys_G2		lda	#"2"
			b $2c
:LoadSys_G3		lda	#"3"
			b $2c
:LoadSys_G4		lda	#"4"
			sta	FNamGEOS_0+8

			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU

			tya
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE

			ldx	#<FNamGEOS_0
			ldy	#>FNamGEOS_0
:SYSTEM_ROM_LOAD	lda	#9			;Länge Dateiname = 9 Zeichen.

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

			pla
			sta	MMU			;MMU-Register zurücksetzen.

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Fehler, zurück zum BASIC.
:ERROR			jsr	Strg_LoadError		;Fehlermeldung ausgeben und Ende.

			pla
;			sta	MMU			;MMU-Register zurücksetzen.

			lda	#$00			;Bank#0, RAM bis $3FFF ROM + I/O.
			sta	MMU

			cli
			jmp	ROM_BASIC_READY		;Zurück zu BASIC.

;*** Kernal-Teil #1 Bank 0 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    nach $C000-$FFFF kopiert.
:InitSys_GEOS_B0	jsr	Strg_Install_1		;Installationsmeldung ausgeben.

;			sei				;Interrupts bereits gesperrt.
			lda	MMU			;GEOS-Bank 0 nur RAM-Bereich
			pha				;einblenden.
			lda	#$0f
			sta	MMU

			LoadW	r0,BASE_GEOS_SYS	;GEOS-Kernal Bank 0 aus Startdatei
			LoadW	r1,$c000		;nach $C000 kopieren.
			ldy	#$00
::4			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$c000 (Bank 0)
			iny	 			;bis $feff verschieben
			bne	:4
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:4

			ldy	#5			;Bereich $ff05 bis $ffff
::3			lda	(r0L),y			;setzen in Bank 0
			sta	(r1L),y
			iny
			bne	:3

			pla
			sta	MMU			;MMU-Register zurücksetzen.

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Kernal-Teil #1 Bank 1 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" in Bank 1 (!) im Speicher und wird
;    nach $9000-$9C7F und $C000-$FFFF kopiert.
:InitSys_GEOS_B1	jsr	Strg_Install_128	;Installationsmeldung ausgeben.

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

							;GEOS-Kernal Bank 1 aus Startdatei
			LoadW	r1,$c000		;nach $C000 kopieren.
			ldy	#$00
::4			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$c000 (Bank 1)
			iny	 			;bis $feff verschieben
			bne	:4
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:4

			ldy	#5			;Bereich $ff05 bis $ffff
::3			lda	(r0L),y			;setzen in Bank 1
			sta	(r1L),y
			iny
			bne	:3

			jmp	Strg_OK			;Installationsmeldung ausgeben.

;*** Kernal-Teil #2 installieren,ReBoot-Routine in REU kopieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;--- Ausgelagerte Kernal-Funktionen in RAM kopieren.
:InitSys_MPp1		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			LoadB	RAM_Conf_Reg,$00	;keine Common Area
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

::51			LoadB	RAM_Conf_Reg,$00	;keine Common Area

			lda	Vec_ReBoot +0,x		;Startadresse für ReBoot-Routine
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

			LoadB	RAM_Conf_Reg,$07	;Common Area $0000 - $4000 aktiv

			jmp	Strg_OK			;Installationsmeldung ausgeben.

::52			LoadB	RAM_Conf_Reg,$07	;Common Area $0000 - $4000 aktiv

			jsr	Strg_LoadError		;Fehler beim Speichertransfer.
			jmp	ROM_BASIC_READY		;FEHLER!, Abbruch...

;*** Kernal-Teil #3 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;    ACHTUNG:
;    Bereich GEOS-Variablen wird aufgrund der Größe der Datei überschrieben
;    Wurde im Bereich Bank 0 gesichert
;--- Ergänmzung: 20.12.18/M.Kanet
;Teil#2 in #2a und #2b aufgeteilt. Bereich ab $8000 bleibt erhalten.
:InitSys_MPp2a		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			LoadB	RAM_Conf_Reg,$00	;keine Common Area

			lda	#<MP3_BANK_2a
			ldx	#>MP3_BANK_2a
			ldy	#$03
			jmp	InitSys_Core

;*** Kernal-Teil #4 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS" im Speicher und wird
;    in die Speicherbank #1 kopiert.
:InitSys_MPp2b		jsr	Strg_Install_2		;Installationsmeldung ausgeben.

			LoadB	RAM_Conf_Reg,$00	;keine Common Area

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

			LoadB	RAM_Conf_Reg,$07	;Common Area $0000 - $4000 aktiv

			jmp	Strg_OK			;Installationsmeldung ausgeben.

::55			LoadB	RAM_Conf_Reg,$07	;Common Area $0000 - $4000 aktiv

			jsr	Strg_LoadError		;Fehler beim Speichertransfer.
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
.E_KernelData		g BASE_GEOS_SYS128
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
