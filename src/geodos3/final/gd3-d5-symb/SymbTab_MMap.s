; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GeoDOS64-V3: MemoryMap-Labels.
;******************************************************************************
;*** Variablen die den Inhalt der ersten Speicherbank bestimmen.
:R1_SIZE_MOVEDATA	= $7900				;MoveData-Transfer-Bereich.
:R1_SIZE_SYS_VAR1	= $0500				;Kernal-Variablen.
:R1_SIZE_REBOOT		= $0500				;ReBoot-Routine.
:R1_SIZE_DSKDEV_A	= $0d80				;Laufwerkstreiber A:
:R1_SIZE_DSKDEV_B	= $0d80				;Laufwerkstreiber B:
:R1_SIZE_DSKDEV_C	= $0d80				;Laufwerkstreiber C:
:R1_SIZE_DSKDEV_D	= $0d80				;Laufwerkstreiber D:
:R1_SIZE_SYS_PRG1	= $0280				;Kernal $9D80-$9FFF
:R1_SIZE_SYS_PRG2	= $10c0				;Kernal $BF40-$CFFF
:R1_SIZE_SYS_PRG3	= $3000				;Kernal $D000-$DFFF
:R1_SIZE_RBOOTMSE	= $003f				;Aktuelles Mauszeiger-Icon.
:R1_SIZE_SYS_BBG1	= $0100				;DoRAMOp-Zusatz für BBGRAM.
:R1_SIZE_SYS_BBG2	= $0100				;DoRAMOp-Zusatz für BBGRAM.

:R1_ADDR_MOVEDATA	= $0000
:R1_ADDR_SYS_VAR1	= $7900
:R1_ADDR_REBOOT		= $7e00
:R1_ADDR_DSKDEV_A	= $8300
:R1_ADDR_DSKDEV_B	= $9080
:R1_ADDR_DSKDEV_C	= $9e00
:R1_ADDR_DSKDEV_D	= $ab80
:R1_ADDR_SYS_PRG1	= $b900
:R1_ADDR_SYS_PRG2	= $bb80
:R1_ADDR_SYS_PRG3	= $cc40
:R1_ADDR_RBOOTMSE	= $fc40
:R1_ADDR_SYS_BBG1	= $fe00
:R1_ADDR_SYS_BBG2	= $ff00

;*** Variablen die den Inhalt der zweiten (GD3)-Speicherbank bestimmen.
;    Für diese Routinen existiert ein Einsprung in der System-Sprungtabelle.
;--- Ergänzung: 20.07.21/M.Kanet
;Speicherbereiche die bei MP3 identisch
;sind. Nicht verändern, da TopDesk die
;Grafikdaten für das Hintergrundbild an
;einer definiefrten Stelle erwartet.
:R2_COUNT_MODULES	= 14				;Anzahl Module in ":G3_KernalData".
:R2_SIZE_REGISTER	= $0c00				;Registermenü-Routine.
:R2_SIZE_ENTER_DT	= $0200				;EnterDeskTop-Routine.
:R2_SIZE_PANIC		= $0100				;Neue PANIC!-Box.
:R2_SIZE_TOBASIC	= $0200				;Neue ToBasic-Routine.
:R2_SIZE_GETNXDAY	= $0080				;Nächsten Tag berechnen.
:R2_SIZE_DOALARM	= $0080				;Weckzeit anzeigen.
:R2_SIZE_GETFILES	= $1c00				;Neue Dateiauswahlbox.
:R2_SIZE_GFILDATA	= $0180				;GetFiles-Subroutine.
:R2_SIZE_GFILMENU	= $0380				;GetFiles-Subroutine.
:R2_SIZE_DB_SCREEN	= $0300				;Dialogboxbildschirm laden/speichern.
:R2_SIZE_DB_COLOR	= 25*40				;Dialogboxbildschirm: Farbe.
:R2_SIZE_DB_GRAFX	= 25*40*8			;Dialogboxbildschirm: Grafik.
:R2_SIZE_GETBSCRN	= $0100				;Hintergrundbild einlesen.
:R2_SIZE_BS_COLOR	= 25*40				;Hintergrundbild: Farbe.
:R2_SIZE_BS_GRAFX	= 25*40*8			;Hintergrundbild: Grafik.
:R2_SIZE_SCRSAVER	= $1c00				;Bildschirmschoner-Routine.
:R2_SIZE_SS_COLOR	= 25*40				;Bildschirmschoner: Farbe.
:R2_SIZE_SS_GRAFX	= 25*40*8			;Bildschirmschoner: Grafik.
:R2_SIZE_SPOOLER	= $1600				;Spooler-Menü.
:R2_SIZE_PRNSPHDR	= $0100				;Header für Druckerspooler-Treiber.

;--- Ergänzung: 30.12.18/M.Kanet
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reduziert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;SetADDR_Printer und SetADDR_PrnSpool dürfen max. bis $7F3E reichen.
;Siehe auch Datei "-G3_SetVecRAM".
:R2_SIZE_PRNSPOOL	= $0640				;Druckerspooler-Treiber.
:R2_SIZE_PRNTHDR	= $0100				;Header für Drucker-Treiber.
:R2_SIZE_PRINTER	= $0640				;Drucker-Treiber.

;--- Ergänzung: 20.07.21/M.Kanet
;InitSys verschoben um kompatibel zu
;TopDesk zu bleiben.
:R2_SIZE_INIT_SYS	= $0080				;EnterDeskTop-Routine.
:R2_SIZE_GEOHELP	= $0200				;Online-Hilfe.
:R2_SIZE_DDRVCORE	= SIZE_DDRV_INIT_NG

:R2_ADDR_REGISTER	= $0000
:R2_ADDR_ENTER_DT	= (R2_ADDR_REGISTER + R2_SIZE_REGISTER)
:R2_ADDR_PANIC		= (R2_ADDR_ENTER_DT + R2_SIZE_ENTER_DT)
:R2_ADDR_TOBASIC	= (R2_ADDR_PANIC    + R2_SIZE_PANIC   )
:R2_ADDR_GETNXDAY	= (R2_ADDR_TOBASIC  + R2_SIZE_TOBASIC )
:R2_ADDR_DOALARM	= (R2_ADDR_GETNXDAY + R2_SIZE_GETNXDAY)
:R2_ADDR_GETFILES	= (R2_ADDR_DOALARM  + R2_SIZE_DOALARM )
:R2_ADDR_GFILDATA	= (R2_ADDR_GETFILES + R2_SIZE_GETFILES)
:R2_ADDR_GFILMENU	= (R2_ADDR_GFILDATA + R2_SIZE_GFILDATA)
:R2_ADDR_DB_SCREEN	= (R2_ADDR_GFILMENU + R2_SIZE_GFILMENU)
:R2_ADDR_DB_COLOR	= (R2_ADDR_DB_SCREEN+ R2_SIZE_DB_SCREEN)
:R2_ADDR_DB_GRAFX	= (R2_ADDR_DB_COLOR + R2_SIZE_DB_COLOR)
:R2_ADDR_GETBSCRN	= (R2_ADDR_DB_GRAFX + R2_SIZE_DB_GRAFX)
;Feste Adresse: $5A28 -> TopDesk64
:R2_ADDR_BS_COLOR	= (R2_ADDR_GETBSCRN + R2_SIZE_GETBSCRN)
;Feste Adresse: $5E10 -> TopDesk64
:R2_ADDR_BS_GRAFX	= (R2_ADDR_BS_COLOR + R2_SIZE_BS_COLOR)
:R2_ADDR_SCRSAVER	= (R2_ADDR_BS_GRAFX + R2_SIZE_BS_GRAFX)
:R2_ADDR_SS_COLOR	= (R2_ADDR_SCRSAVER + R2_SIZE_SCRSAVER)
:R2_ADDR_SS_GRAFX	= (R2_ADDR_SS_COLOR + R2_SIZE_SS_COLOR)
:R2_ADDR_SPOOLER	= (R2_ADDR_SS_GRAFX + R2_SIZE_SS_GRAFX)
:R2_ADDR_PRNSPHDR	= (R2_ADDR_SPOOLER  + R2_SIZE_SPOOLER)
:R2_ADDR_PRNSPOOL	= (R2_ADDR_PRNSPHDR + R2_SIZE_PRNSPHDR)
:R2_ADDR_PRNTHDR	= (R2_ADDR_PRNSPOOL + R2_SIZE_PRNSPOOL)
:R2_ADDR_PRINTER	= (R2_ADDR_PRNTHDR  + R2_SIZE_PRNTHDR)

;--- Ergänzung: 20.07.21/M.Kanet
;InitSys verschoben um kompatibel zu
;TopDesk zu bleiben.
:R2_ADDR_INIT_SYS	= (R2_ADDR_PRINTER + R2_SIZE_PRINTER)
:R2_ADDR_GEOHELP	= (R2_ADDR_INIT_SYS+ R2_SIZE_INIT_SYS)
:R2_ADDR_DDRVCORE	= (R2_ADDR_GEOHELP + R2_SIZE_GEOHELP)
:R2_ADDR_END		= (R2_ADDR_DDRVCORE+ R2_SIZE_DDRVCORE)

;*** Variablen die den Inhalt der dritten (MP)-Speicherbank bestimmen.
;    Für diese Variablen gibt es keinen Eintrag in der Sprungtabelle!!!
:R3_SIZE_SWAPFILE	= $7c00				;Größe der Auslagerungsdatei.
:R3_SIZE_FNAMES		= $1200				;Puffer für Dateinamen.
:R3_SIZE_AUTOBBUF	= SIZE_AUTO_BOOT		;Puffer AutoBoot-Routine.
:R3_SIZE_REGMEMBUF	= R2_SIZE_REGISTER		;Puffer Registermenü.
:R3_SIZE_ZEROPBUF	= $0400				;Puffer Druckerspooler.
:R3_SIZE_OSVARBUF	= $0c00				;Puffer Druckerspooler.
:R3_SIZE_MPVARBUF	= $0050				;Puffer Druckerspooler.
:R3_SIZE_SP_COLOR	= 25*40				;Puffer Druckerspooler.
:R3_SIZE_SP_GRAFX	= 25*40*8			;Puffer Druckerspooler.
:R3_SIZE_SPOOLDAT	= 640 + 80 + 1920		;Puffer Druckerspooler.
:R3_SIZE_PRNSPLTMP	= $0640				;Temp. Kopie Spooler-Treiber.

:R3_ADDR_SWAPFILE	= $0000
:R3_ADDR_FNAMES		= (R3_ADDR_SWAPFILE  + R3_SIZE_SWAPFILE )
:R3_ADDR_AUTOBBUF	= (R3_ADDR_FNAMES    + R3_SIZE_FNAMES   )
:R3_ADDR_REGMEMBUF	= (R3_ADDR_AUTOBBUF  + R3_SIZE_AUTOBBUF )
:R3_ADDR_ZEROPBUF	= (R3_ADDR_REGMEMBUF + R3_SIZE_REGMEMBUF)
:R3_ADDR_OSVARBUF	= (R3_ADDR_ZEROPBUF  + R3_SIZE_ZEROPBUF )
:R3_ADDR_MPVARBUF	= (R3_ADDR_OSVARBUF  + R3_SIZE_OSVARBUF )
:R3_ADDR_SP_COLOR	= (R3_ADDR_MPVARBUF  + R3_SIZE_MPVARBUF )
:R3_ADDR_SP_GRAFX	= (R3_ADDR_SP_COLOR  + R3_SIZE_SP_COLOR )
:R3_ADDR_SPOOLDAT	= (R3_ADDR_SP_GRAFX  + R3_SIZE_SP_GRAFX )
:R3_ADDR_PRNSPLTMP	= (R3_ADDR_SPOOLDAT  + R3_SIZE_SPOOLDAT )
:R3_ADDR_END_MP3	= (R3_ADDR_PRNSPLTMP + R3_SIZE_PRNSPLTMP)

;*** MegaPatch-Startadressen.
;    Die externen Routinen werden an diese Adresse geladen und ausgeführt.
:LD_ADDR_NEWBSCRN	= $7800
:LD_ADDR_REGISTER	= PRINTBASE - R2_SIZE_REGISTER
:LD_ADDR_INIT_SYS	= diskBlkBuf
:LD_ADDR_ENTER_DT	= diskBlkBuf - R2_SIZE_ENTER_DT
:LD_ADDR_PANIC		= diskBlkBuf
:LD_ADDR_TOBASIC	= DISK_BASE - R2_SIZE_TOBASIC
:LD_ADDR_GETNXDAY	= diskBlkBuf
:LD_ADDR_DOALARM	= diskBlkBuf
:LD_ADDR_GETFILES	= BACK_SCR_BASE
:LD_ADDR_GFILDATA	= dlgBoxRamBuf + 0
:LD_ADDR_GFILPART	= dlgBoxRamBuf + 9
:LD_ADDR_GFILMENU	= diskBlkBuf			;- R2_SIZE_GFILMENU
:LD_ADDR_GFILICON	= LD_ADDR_GFILMENU + 3
:LD_ADDR_GFILFBOX	= LD_ADDR_GFILMENU + 6
:LD_ADDR_DBOXICON	= LD_ADDR_GFILMENU + 9
:DB_FNAME_BUF		= LD_ADDR_GETFILES - R3_SIZE_FNAMES
:DB_PDATA_BUF		= LD_ADDR_GETFILES - 256
:LD_ADDR_DB_SCREEN	= diskBlkBuf
:DB_SCREEN_SAVE		= LD_ADDR_DB_SCREEN + 0
:DB_SCREEN_LOAD		= LD_ADDR_DB_SCREEN + 3
:LD_ADDR_INIT_GEOS	= diskBlkBuf
:LD_ADDR_SCRSAVER	= OS_VARS - R2_SIZE_SCRSAVER
:LD_ADDR_SCRSVINIT	= LD_ADDR_SCRSAVER + 3
:LD_ADDR_GETBSCRN	= diskBlkBuf
:LD_ADDR_SPOOLER	= $4000
:LD_ADDR_GEOHELP	= $0400

;--- Ergänzung: 20.07.21/M.Kanet
;Der TaskManager-Code wird nicht in der
;GD3-Speicherbank abgelegt, sondern
;direkt in der ersten TaskManager-Bank!
:RT_SIZE_TASKMAN	= $2000				;Größe des TaskSwitchers.
:RT_ADDR_TASKMAN	= $4000				;Adresse TaskManager in ":Flag_TaskBank".
:LD_ADDR_TASKMAN	= $4000				;Lade-Adresse TaskManager.

;--- Ergänzung: 22.08.21/M.Kanet
;Der GeoHelp-Code wird nicht in der
;GD3-Speicherbank abgelegt, sondern
;direkt in der GeoHelp-Speicherbank!
:RH_SIZE_HELPSYS	= $2c00				;Größe von GeoHelp.
:RH_ADDR_HELPSYS	= $1000				;Adresse in GeoHelp-Speicherbank.
:LD_ADDR_HELPSYS	= $1000				;Lade-Adresse GeoHelp.
