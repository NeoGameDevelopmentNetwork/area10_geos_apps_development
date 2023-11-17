; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Speicherbelegung Systemprogramme.
;******************************************************************************
:BASE_GEOSBOOT		= $1000				;startadress geosboot-code.
:BASE_GEOS_SYS		= $2e00				;startadress geos-sys-files.
:BASE_REBOOT		= $4000				;startadress reboot-code.
:SIZE_REBOOT		= $0500				;max. size of reboot-code.
:BASE_AUTO_BOOT		= $5000				;startadress autoboot-code.
:SIZE_AUTO_BOOT		= $0500				;max. size of autoboot-code.
:BASE_HELPSYS		= $1000				;helpsystem.

;******************************************************************************
;*** Speicherbelegung Laufwerkstreiber.
;******************************************************************************
:DDRV_MAX		= 32

;--- Laufwerkstreiber.
; :BASE_DDRV_CORE      = $0400
; :BASE_DDRV_DATA      = $1300
; :BASE_DDRV_INFO      = $3400
;   :DRVINF_NG_START   = $3400
;   :DRVINF_NG_SIZE    = $3440
;   :DRVINF_NG_RAMB    = $3480
;   :DRVINF_NG_FOUND   = $34A0
;   :DRVINF_NG_TYPES   = $34C0
;   :DRVINF_NG_NAMES   = $34E0
; :BASE_GCFG_DATA      = $3700
; :BASE_GCFG_MAIN      = $3800
;---
:BASE_DDRV_CORE		= APP_RAM
:SIZE_DDRV_CORE		= $0f00
:BASE_DDRV_DATA		= BASE_DDRV_CORE  +SIZE_DDRV_CORE
:SIZE_DDRV_DATA		= $2100
:BASE_GCFG_BOOT		= BASE_DDRV_DATA
:SIZE_GCFG_BOOT		= SIZE_DDRV_DATA
;---
:BASE_DDRV_INFO		= BASE_DDRV_DATA  +SIZE_DDRV_DATA
:SIZE_DDRV_INFO		= $0300
:DRVINF_NG_START	= BASE_DDRV_INFO
:DRVINF_NG_SIZE		= DRVINF_NG_START +DDRV_MAX*2
:DRVINF_NG_RAMB		= DRVINF_NG_SIZE  +DDRV_MAX*2
:DRVINF_NG_FOUND	= DRVINF_NG_RAMB  +DDRV_MAX
:DRVINF_NG_TYPES	= DRVINF_NG_FOUND +DDRV_MAX
:DRVINF_NG_NAMES	= DRVINF_NG_TYPES +DDRV_MAX
;---
:BASE_GCFG_DATA		= BASE_DDRV_INFO  +SIZE_DDRV_INFO
:SIZE_GCFG_DATA		= $0100
:BASE_GCFG_MAIN		= BASE_GCFG_DATA  +SIZE_GCFG_DATA

;******************************************************************************
;*** GDOS: Speicherbelegung.
;******************************************************************************
;--- GEOS-System (Immer Bank #0).
;Variablen die den Inhalt der ersten
;GEOS-Speicherbank bestimmen.
:R1S_MOVEDATA		= $7900				;MoveData-Transfer-Bereich.
:R1S_SYS_VAR1		= $0500				;Kernal-Variablen.
:R1S_REBOOT		= $0500				;ReBoot-Routine.
:R1S_DSKDEV_A		= $0d80				;Laufwerkstreiber A:
:R1S_DSKDEV_B		= $0d80				;Laufwerkstreiber B:
:R1S_DSKDEV_C		= $0d80				;Laufwerkstreiber C:
:R1S_DSKDEV_D		= $0d80				;Laufwerkstreiber D:
:R1S_SYS_PRG1		= $0280				;Kernal $9D80-$9FFF
:R1S_SYS_PRG2		= $10c0				;Kernal $BF40-$CFFF
:R1S_SYS_PRG3		= $3000				;Kernal $D000-$DFFF
:R1S_RBOOTMSE		= $003f				;Aktuelles Mauszeiger-Icon.
;:R1S_SYS_BBG		= $0100				;DoRAMOp-Zusatz für BBGRAM.
;:R1S_RESERVED		= $0100				;Reserved.

:R1A_MOVEDATA		= $0000
:R1A_SYS_VAR1		= $7900
:R1A_REBOOT		= $7e00
:R1A_DSKDEV_A		= $8300
:R1A_DSKDEV_B		= $9080
:R1A_DSKDEV_C		= $9e00
:R1A_DSKDEV_D		= $ab80
:R1A_SYS_PRG1		= $b900
:R1A_SYS_PRG2		= $bb80
:R1A_SYS_PRG3		= $cc40
:R1A_RBOOTMSE		= $fc40
;:R1A_SYS_BBG		= $fe00
;:R1A_RESERVED		= $ff00

;-- GDOS-Kernal (MP3_64K_SYSTEM).
;Variablen die den Inhalt der zweiten
;GDOS-Speicherbank bestimmen.
;Für diese Routinen existiert ein
;Einsprung in der System-Sprungtabelle.
;
:GDOS_EXT_MODULES	= 15				;Anzahl Module in ":G3_KernalData".

;--- Ergänzung: 20.07.21/M.Kanet
;Speicherbereiche die bei MP3 identisch
;sind. Nicht verändern, da TopDesk die
;Grafikdaten für das Hintergrundbild an
;einer definierten Stelle erwartet.
:R2S_REGISTER		= $0c00				;Registermenü-Routine.
:R2S_ENTER_DT		= $0200				;EnterDeskTop-Routine.
:R2S_PANIC		= $0100				;Neue PANIC!-Box.
:R2S_TOBASIC		= $0200				;Neue ToBasic-Routine.
:R2S_GETNXDAY		= $0080				;Nächsten Tag berechnen.
:R2S_DOALARM		= $0080				;Weckzeit anzeigen.
:R2S_GETFILES		= $1c00				;Neue Dateiauswahlbox.
:R2S_GFILDATA		= $0180				;GetFiles-Subroutine.
:R2S_GFILMENU		= $0380				;GetFiles-Subroutine.
:R2S_DB_SCREEN		= $0300				;Dialogboxbildschirm laden/speichern.
:R2S_DB_COLOR		= 25*40				;Dialogboxbildschirm: Farbe.
:R2S_DB_GRAFX		= 25*40*8			;Dialogboxbildschirm: Grafik.
:R2S_GETBSCRN		= $0100				;Hintergrundbild einlesen.
:R2S_BS_COLOR		= 25*40				;Hintergrundbild: Farbe.
:R2S_BS_GRAFX		= 25*40*8			;Hintergrundbild: Grafik.
:R2S_SCRSAVER		= $1c00				;Bildschirmschoner-Routine.
:R2S_SS_COLOR		= 25*40				;Bildschirmschoner: Farbe.
:R2S_SS_GRAFX		= 25*40*8			;Bildschirmschoner: Grafik.
:R2S_SPOOLER		= $1508				;Spooler-Menü.
:R2S_PRNSPHDR		= $0100				;Header für Druckerspooler-Treiber.

;--- Ergänzung: 30.12.18/M.Kanet
;geoCalc64 nutzt beim Drucken ab $5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reduziert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;SetADDR_Printer und SetADDR_PrnSpool dürfen max. bis $7F3E reichen.
;Siehe auch Datei "-G3_SetVecRAM".
:R2S_PRNSPOOL		= $0640				;Druckerspooler-Treiber.
:R2S_PRNTHDR		= $0100				;Header für Drucker-Treiber.
:R2S_PRINTER		= $0640				;Drucker-Treiber.

;--- Ergänzung: 20.07.21/M.Kanet
;InitSys verschoben um kompatibel zu
;TopDesk zu bleiben.
:R2S_INIT_SYS		= $0080				;EnterDeskTop-Routine.
:R2S_GEOHELP		= $0200				;Online-Hilfe.
:R2S_DDRVCORE		= SIZE_DDRV_CORE

:R2A_REGISTER		= $0000
:R2A_ENTER_DT		= (R2A_REGISTER + R2S_REGISTER)
:R2A_PANIC		= (R2A_ENTER_DT + R2S_ENTER_DT)
:R2A_TOBASIC		= (R2A_PANIC    + R2S_PANIC   )
:R2A_GETNXDAY		= (R2A_TOBASIC  + R2S_TOBASIC )
:R2A_DOALARM		= (R2A_GETNXDAY + R2S_GETNXDAY)
:R2A_GETFILES		= (R2A_DOALARM  + R2S_DOALARM )
:R2A_GFILDATA		= (R2A_GETFILES + R2S_GETFILES)
:R2A_GFILMENU		= (R2A_GFILDATA + R2S_GFILDATA)
:R2A_DB_SCREEN		= (R2A_GFILMENU + R2S_GFILMENU)
:R2A_DB_COLOR		= (R2A_DB_SCREEN+ R2S_DB_SCREEN)
:R2A_DB_GRAFX		= (R2A_DB_COLOR + R2S_DB_COLOR)
:R2A_GETBSCRN		= (R2A_DB_GRAFX + R2S_DB_GRAFX)
;Feste Adresse: $5A28 -> TopDesk64
:R2A_BS_COLOR		= (R2A_GETBSCRN + R2S_GETBSCRN)
;Feste Adresse: $5E10 -> TopDesk64
:R2A_BS_GRAFX		= (R2A_BS_COLOR + R2S_BS_COLOR)
:R2A_SCRSAVER		= (R2A_BS_GRAFX + R2S_BS_GRAFX)
:R2A_SS_COLOR		= (R2A_SCRSAVER + R2S_SCRSAVER)
:R2A_SS_GRAFX		= (R2A_SS_COLOR + R2S_SS_COLOR)
:R2A_SPOOLER		= (R2A_SS_GRAFX + R2S_SS_GRAFX)
:R2A_PRNSPHDR		= (R2A_SPOOLER  + R2S_SPOOLER)
:R2A_PRNSPOOL		= (R2A_PRNSPHDR + R2S_PRNSPHDR)
:R2A_PRNTHDR		= (R2A_PRNSPOOL + R2S_PRNSPOOL)
:R2A_PRINTER		= (R2A_PRNTHDR  + R2S_PRNTHDR)

;--- Ergänzung: 20.07.21/M.Kanet
;InitSys verschoben um kompatibel zu
;TopDesk zu bleiben.
:R2A_INIT_SYS		= (R2A_PRINTER + R2S_PRINTER)
:R2A_GEOHELP		= (R2A_INIT_SYS+ R2S_INIT_SYS)
:R2A_DDRVCORE		= (R2A_GEOHELP + R2S_GEOHELP)

;--- Ende GDOS-Kernal.
:R2A_END_KERNAL		= (R2A_DDRVCORE+ R2S_DDRVCORE)

;--- GDOS-Daten (MP3_64K_DATA).
;Variablen die den Inhalt der dritten
;GDOS-Speicherbank bestimmen.
;Für diese Variablen gibt es keinen
;Eintrag in der Sprungtabelle!!!
:R3S_SWAPFILE		= $7c00				;Größe der Auslagerungsdatei.
:R3S_FNAMES		= $1200				;Puffer für Dateinamen.
:R3S_AUTOBBUF		= SIZE_AUTO_BOOT		;Puffer AutoBoot-Routine.
:R3S_REGMEMBUF		= R2S_REGISTER			;Puffer Registermenü.
:R3S_ZEROPBUF		= $0400				;Puffer ZeroPage.
:R3S_OSVARBUF		= $0c00				;Puffer GEOS-Register.
:R3S_MPVARBUF		= EXTVAR_SIZE			;Puffer GDOS-Register.
:R3S_SP_COLOR		= 25*40				;Puffer Druckerspooler / Grafik.
:R3S_SP_GRAFX		= 25*40*8			;Puffer Druckerspooler / FarbRAM.
:R3S_SPOOLDAT		= 640 + 80 + 1920		;Puffer Druckerspooler / Daten.
:R3S_PRNSPLTMP		= $0640				;Temp. Kopie Spooler-Treiber.
:R3S_CPROFILE		= $003c				;Farbprofil.
:R3S_CFG_GDOS		= 254				;GD.INI: GDOS64.
:R3S_CFG_GDSK		= 254				;GD.INI: GeoDesk.

:R3A_SWAPFILE		= $0000
;			= $0000-$11FF			;GD.CONFIG: SwapFile für Dateiliste.
;			= $4000-$5FFF			;GD.CONFIG: SwapFile für TaskMan.
:R3A_FNAMES		= (R3A_SWAPFILE  + R3S_SWAPFILE )
:R3A_AUTOBBUF		= (R3A_FNAMES    + R3S_FNAMES   )
:R3A_REGMEMBUF		= (R3A_AUTOBBUF  + R3S_AUTOBBUF )
:R3A_ZEROPBUF		= (R3A_REGMEMBUF + R3S_REGMEMBUF)
:R3A_OSVARBUF		= (R3A_ZEROPBUF  + R3S_ZEROPBUF )
:R3A_MPVARBUF		= (R3A_OSVARBUF  + R3S_OSVARBUF )
:R3A_SP_COLOR		= (R3A_MPVARBUF  + R3S_MPVARBUF )
:R3A_SP_GRAFX		= (R3A_SP_COLOR  + R3S_SP_COLOR )
:R3A_SPOOLDAT		= (R3A_SP_GRAFX  + R3S_SP_GRAFX )
:R3A_PRNSPLTMP		= (R3A_SPOOLDAT  + R3S_SPOOLDAT )
:R3A_CPROFILE		= (R3A_PRNSPLTMP + R3S_PRNSPLTMP)
:R3A_CFG_GDOS		= (R3A_CPROFILE  + R3S_CPROFILE )
:R3A_CFG_GDSK		= (R3A_CFG_GDOS  + R3S_CFG_GDOS )

;--- Ende GDOS-System.
:R3A_END_SYSTEM		= (R3A_CFG_GDSK  + R3S_CFG_GDSK )

;--- GDOS64-Startadressen.
;Die externen Routinen werden an diese
;Adresse geladen und ausgeführt.
:LOAD_NEWBSCRN		= $7800
:LOAD_REGISTER		= PRINTBASE - R2S_REGISTER
:LOAD_INIT_SYS		= OS_BASE
:LOAD_ENTER_DT		= OS_BASE - R2S_ENTER_DT
:LOAD_PANIC		= OS_BASE
:LOAD_TOBASIC		= DISK_BASE - R2S_TOBASIC
:LOAD_GETNXDAY		= OS_BASE
:LOAD_DOALARM		= OS_BASE
:LOAD_GETFILES		= BACK_SCR_BASE
:LOAD_GFILDATA		= dlgBoxRamBuf + 0
:LOAD_GFILPART		= dlgBoxRamBuf + 9
:LOAD_GFILMENU		= OS_BASE			;- R2S_GFILMENU
:LOAD_GFILICON		= LOAD_GFILMENU + 3
:LOAD_GFILFBOX		= LOAD_GFILMENU + 6
:LOAD_DBOXICON		= LOAD_GFILMENU + 9
:DB_FNAME_BUF		= LOAD_GETFILES - R3S_FNAMES
:DB_PDATA_BUF		= LOAD_GETFILES - 256
:LOAD_DB_SCREEN		= OS_BASE
:DB_SCREEN_SAVE		= LOAD_DB_SCREEN + 0
:DB_SCREEN_LOAD		= LOAD_DB_SCREEN + 3
:LOAD_SCRSAVER		= OS_BASE - R2S_SCRSAVER
:LOAD_SCRSVINIT		= LOAD_SCRSAVER + 3
:LOAD_GETBSCRN		= OS_BASE
:LOAD_SPOOLER		= $4000
:LOAD_GEOHELP		= $0400

;--- Ergänzung: 20.07.21/M.Kanet
;Der TaskManager-Code wird nicht in der
;GDOS-Speicherbank abgelegt, sondern
;direkt in der ersten TaskManager-Bank!
:RTS_TASKMAN		= $2000				;Größe des TaskSwitchers.
:RTA_TASKMAN		= $4000				;Adresse TaskManager in ":Flag_TaskBank".
:LOAD_TASKMAN		= $4000				;Lade-Adresse TaskManager.

;--- Ergänzung: 22.08.21/M.Kanet
;Der GeoHelp-Code wird nicht in der
;GDOS-Speicherbank abgelegt, sondern
;direkt in der GeoHelp-Speicherbank!
:RHS_HELPSYS		= $2c00				;Größe von GeoHelp.
:RHA_HELPSYS		= $1000				;Adresse in GeoHelp-Speicherbank.
:LOAD_HELPSYS		= $1000				;Lade-Adresse GeoHelp.
