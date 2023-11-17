; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Erweiterte Symboltabelle für GEOS/MegaPatch3
; Revision 29.10.2022

; Symbole für Inhalt der GEOS-Speicherbank
; (Erste Speicherbank im GEOS-DACC)
:R1_SIZE_MOVEDATA	= $7900				;MoveData-Transfer-Bereich
; :R1_SIZE_SYS_VAR1	= $0500				;Kernal-Variablen
; :R1_SIZE_REBOOT	= $0500				;ReBoot-Routine
:R1_SIZE_DSKDEV_A	= $0d80				;Laufwerkstreiber A:
:R1_SIZE_DSKDEV_B	= $0d80				;Laufwerkstreiber B:
:R1_SIZE_DSKDEV_C	= $0d80				;Laufwerkstreiber C:
:R1_SIZE_DSKDEV_D	= $0d80				;Laufwerkstreiber D:
; :R1_SIZE_SYS_PRG1	= $0280				;Kernal $9D80-$9FFF
; :R1_SIZE_SYS_PRG2	= $10c0				;Kernal $BF40-$CFFF
; :R1_SIZE_SYS_PRG3	= $3000				;Kernal $D000-$DFFF
; :R1_SIZE_RBOOTMSE	= $003f				;Aktuelles Mauszeiger-Icon
; :R1_SIZE_SYS_BBG1	= $0100				;DoRAMOp-Zusatz für BBGRAM
; :R1_SIZE_SYS_BBG2	= $0100				;DoRAMOp-Zusatz für BBGRAM

:R1_ADDR_MOVEDATA	= $0000
; :R1_ADDR_SYS_VAR1	= $7900
; :R1_ADDR_REBOOT	= $7e00
:R1_ADDR_DSKDEV_A	= $8300
:R1_ADDR_DSKDEV_B	= $9080
:R1_ADDR_DSKDEV_C	= $9e00
:R1_ADDR_DSKDEV_D	= $ab80
; :R1_ADDR_SYS_PRG1	= $b900
; :R1_ADDR_SYS_PRG2	= $bb80
; :R1_ADDR_SYS_PRG3	= $cc40
; :R1_ADDR_RBOOTMSE	= $fc40
; :R1_ADDR_SYS_BBG1	= $fe00
; :R1_ADDR_SYS_BBG2	= $ff00

; Symbole für die Speicherbank mit den
; erweiterten Routinen in MegaPatch
; (Letzte Speicherbank im GEOS-DACC)
:R2_SIZE_REGISTER	= $0c00				;Registermenü-Routine
:R2_SIZE_ENTER_DT	= $0200				;EnterDeskTop-Routine
:R2_SIZE_PANIC		= $0100				;Neue PANIC!-Box
:R2_SIZE_TOBASIC	= $0200				;Neue ToBasic-Routine
:R2_SIZE_GETNXDAY	= $0080				;Nächsten Tag berechnen
:R2_SIZE_DOALARM	= $0080				;Weckzeit anzeigen
:R2_SIZE_GETFILES	= $1c00				;Neue Dateiauswahlbox
:R2_SIZE_GFILDATA	= $0180				;GetFiles-Subroutine
:R2_SIZE_GFILMENU	= $0380				;GetFiles-Subroutine
:R2_SIZE_DB_SCREEN	= $0300				;Dialogboxbildschirm laden/speichern
:R2_SIZE_DB_COLOR	= 25*40				;Dialogboxbildschirm: Farbe
:R2_SIZE_DB_GRAFX	= 25*40*8			;Dialogboxbildschirm: Grafik
:R2_SIZE_GETBSCRN	= $0100				;Hintergrundbild einlesen
:R2_SIZE_BS_COLOR	= 25*40				;Hintergrundbild: Farbe
:R2_SIZE_BS_GRAFX	= 25*40*8			;Hintergrundbild: Grafik
:R2_SIZE_SCRSAVER	= $1c00				;Bildschirmschoner-Routine
:R2_SIZE_SS_COLOR	= 25*40				;Bildschirmschoner: Farbe
:R2_SIZE_SS_GRAFX	= 25*40*8			;Bildschirmschoner: Grafik
:R2_SIZE_SPOOLER	= $1508				;Spooler-Menü
:R2_SIZE_PRNSPHDR	= $0100				;Header für Druckerspooler-Treiber
:R2_SIZE_PRNSPOOL	= $0640				;Druckerspooler-Treiber
:R2_SIZE_PRNTHDR	= $0100				;Header für Drucker-Treiber
:R2_SIZE_PRINTER	= $0640				;Drucker-Treiber
:R2_SIZE_TASKMAN	= $2000				;Größe des TaskSwitchers

:R2_ADDR_REGISTER	= $0000
:R2_ADDR_ENTER_DT	= (R2_ADDR_REGISTER + R2_SIZE_REGISTER)
:R2_ADDR_PANIC		= (R2_ADDR_ENTER_DT + R2_SIZE_ENTER_DT)
:R2_ADDR_TOBASIC	= (R2_ADDR_PANIC + R2_SIZE_PANIC)
:R2_ADDR_GETNXDAY	= (R2_ADDR_TOBASIC + R2_SIZE_TOBASIC)
:R2_ADDR_DOALARM	= (R2_ADDR_GETNXDAY + R2_SIZE_GETNXDAY)
:R2_ADDR_GETFILES	= (R2_ADDR_DOALARM + R2_SIZE_DOALARM)
:R2_ADDR_GFILDATA	= (R2_ADDR_GETFILES + R2_SIZE_GETFILES)
:R2_ADDR_GFILMENU	= (R2_ADDR_GFILDATA + R2_SIZE_GFILDATA)
:R2_ADDR_DB_SCREEN	= (R2_ADDR_GFILMENU + R2_SIZE_GFILMENU)
:R2_ADDR_DB_COLOR	= (R2_ADDR_DB_SCREEN+ R2_SIZE_DB_SCREEN)
:R2_ADDR_DB_GRAFX	= (R2_ADDR_DB_COLOR + R2_SIZE_DB_COLOR)
:R2_ADDR_GETBSCRN	= (R2_ADDR_DB_GRAFX + R2_SIZE_DB_GRAFX)
:R2_ADDR_BS_COLOR	= (R2_ADDR_GETBSCRN + R2_SIZE_GETBSCRN)
:R2_ADDR_BS_GRAFX	= (R2_ADDR_BS_COLOR + R2_SIZE_BS_COLOR)
:R2_ADDR_SCRSAVER	= (R2_ADDR_BS_GRAFX + R2_SIZE_BS_GRAFX)
:R2_ADDR_SS_COLOR	= (R2_ADDR_SCRSAVER + R2_SIZE_SCRSAVER)
:R2_ADDR_SS_GRAFX	= (R2_ADDR_SS_COLOR + R2_SIZE_SS_COLOR)
:R2_ADDR_SPOOLER	= (R2_ADDR_SS_GRAFX + R2_SIZE_SS_GRAFX)
:R2_ADDR_PRNSPHDR	= (R2_ADDR_SPOOLER + R2_SIZE_SPOOLER)
:R2_ADDR_PRNSPOOL	= (R2_ADDR_PRNSPHDR + R2_SIZE_PRNSPHDR)
:R2_ADDR_PRNTHDR	= (R2_ADDR_PRNSPOOL + R2_SIZE_PRNSPOOL)
:R2_ADDR_PRINTER	= (R2_ADDR_PRNTHDR + R2_SIZE_PRNTHDR)
:R2_ADDR_TASKMAN_B	= (R2_ADDR_PRINTER + R2_SIZE_PRINTER)

; :R2_ADDR_TASKMAN	= $4000				;Adresse TaskManager
; :R2_ADDR_TASKMAN_E	= $6000				;Adresse TaskManager während GEOS.Editor

; Symbole für die Speicherbank mit den
; Zwischenspeichern für GEOS/MegaPatch
; (Vorletzte Speicherbank im GEOS-DACC)
; :R3_SIZE_SWAPFILE	= $7c00				;Größe der Auslagerungsdatei
; :R3_SIZE_FNAMES	= $1200				;Puffer für Dateinamen
; :R3_SIZE_AUTOBBUF	= SIZE_AUTO_BOOT		;Puffer AutoBoot-Routine
; :R3_SIZE_REGMEMBUF	= R2_SIZE_REGISTER		;Puffer Registermenü
; :R3_SIZE_ZEROPBUF	= $0400				;Puffer Zeropage
; :R3_SIZE_OSVARBUF	= $0c00				;Puffer OS_VARS
; :R3_SIZE_MPVARBUF	= $0050				;Puffer OS_VAR_MP
; :R3_SIZE_SP_COLOR	= 25*40				;Puffer Druckerspooler/Farbe.
; :R3_SIZE_SP_GRAFX	= 25*40*8			;Puffer Druckerspooler/Grafik
; :R3_SIZE_SPOOLDAT	= 640 + 80 + 1920		;Puffer Druckerspooler/Daten
; :R3_SIZE_PRNSPLTMP	= $0640				;Temp. Kopie Spooler-Treiber

; :R3_ADDR_SWAPFILE	= $0000
; :R3_ADDR_FNAMES	= (R3_ADDR_SWAPFILE + R3_SIZE_SWAPFILE)
; :R3_ADDR_AUTOBBUF	= (R3_ADDR_FNAMES + R3_SIZE_FNAMES)
; :R3_ADDR_REGMEMBUF	= (R3_ADDR_AUTOBBUF + R3_SIZE_AUTOBBUF)
; :R3_ADDR_ZEROPBUF	= (R3_ADDR_REGMEMBUF + R3_SIZE_REGMEMBUF)
; :R3_ADDR_OSVARBUF	= (R3_ADDR_ZEROPBUF + R3_SIZE_ZEROPBUF)
; :R3_ADDR_MPVARBUF	= (R3_ADDR_OSVARBUF + R3_SIZE_OSVARBUF)
; :R3_ADDR_SP_COLOR	= (R3_ADDR_MPVARBUF + R3_SIZE_MPVARBUF)
; :R3_ADDR_SP_GRAFX	= (R3_ADDR_SP_COLOR + R3_SIZE_SP_COLOR)
; :R3_ADDR_SPOOLDAT	= (R3_ADDR_SP_GRAFX + R3_SIZE_SP_GRAFX)
; :R3_ADDR_PRNSPLTMP	= (R3_ADDR_SPOOLDAT + R3_SIZE_SPOOLDAT)
; :R3_ADDR_END_MP3	= (R3_ADDR_PRNSPLTMP + R3_SIZE_PRNSPLTMP)

; Symbole für die Ladeadressen der
; erweiterten Routinen in GEOS/MegaPatch
:LD_ADDR_NEWBSCRN	= $7800
; :LD_ADDR_REGISTER	= PRINTBASE - R2_SIZE_REGISTER
:LD_ADDR_ENTER_DT	= diskBlkBuf - R2_SIZE_ENTER_DT
; :LD_ADDR_PANIC	= diskBlkBuf
; :LD_ADDR_TOBASIC	= DISK_BASE - R2_SIZE_TOBASIC
; :LD_ADDR_GETNXDAY	= diskBlkBuf
; :LD_ADDR_DOALARM	= diskBlkBuf
; :LD_ADDR_GETFILES	= BACK_SCR_BASE
; :LD_ADDR_GFILDATA	= dlgBoxRamBuf + 0
; :LD_ADDR_GFILPART	= dlgBoxRamBuf + 9
; :LD_ADDR_GFILMENU	= diskBlkBuf
; :LD_ADDR_GFILICON	= LD_ADDR_GFILMENU + 3
; :LD_ADDR_GFILFBOX	= LD_ADDR_GFILMENU + 6
; :LD_ADDR_DBOXICON	= LD_ADDR_GFILMENU + 9
; :DB_FNAME_BUF		= LD_ADDR_GETFILES - R3_SIZE_FNAMES
; :DB_PDATA_BUF		= LD_ADDR_GETFILES - 256
; :LD_ADDR_DB_SCREEN	= diskBlkBuf
; :DB_SCREEN_SAVE	= LD_ADDR_DB_SCREEN + 0
; :DB_SCREEN_LOAD	= LD_ADDR_DB_SCREEN + 3
; :LD_ADDR_TASKMAN	= $4000
; :LD_ADDR_INIT_GEOS	= diskBlkBuf
:LD_ADDR_SCRSAVER	= OS_VARS - R2_SIZE_SCRSAVER
:LD_ADDR_SCRSVINIT	= LD_ADDR_SCRSAVER + 3
:LD_ADDR_GETBSCRN	= diskBlkBuf
; :LD_ADDR_SPOOLER	= $4000

; Symbole für den Zugriff auf die
; erweiterten Routinen in GEOS/MegaPatch
:SetADDR_TaskMan	= $cfed
; :SetADDR_Register	= $cfe6				; In TopSym.MP3 definiert
:SetADDR_EnterDT	= $cfe3
; :SetADDR_ToBASIC	= $cfe0
; :SetADDR_PANIC	= $cfdd
; :SetADDR_GetNxDay	= $cfda
; :SetADDR_DoAlarm	= $cfd7
; :SetADDR_GetFiles	= $cfd4
; :SetADDR_GFilData	= $cfd1
; :SetADDR_GFilMenu	= $cfce
; :SetADDR_DB_SCRN	= $cfcb
; :SetADDR_DB_GRFX	= $cfc8
; :SetADDR_DB_COLS	= $cfc5
:SetADDR_BackScrn	= $cfc2
:SetADDR_ScrSaver	= $cfbf
; :SetADDR_Spooler	= $cfbc
; :SetADDR_PrnSpool	= $cfb9
; :SetADDR_PrnSpHdr	= $cfb6
; :SetADDR_Printer	= $cfb3
; :SetADDR_PrntHdr	= $cfb0
