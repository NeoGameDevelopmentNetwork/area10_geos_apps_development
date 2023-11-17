; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDisk"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DCMD"

;--- Ergänzung: 09.04.21/M.Kanet
;Speicher DiskImage-Verzeichnisliste.
;$6D00-$7FFF = Bereich Registermenü.
;Auf 127 Dateinamen begrenzt, max. sind
;255 Dateien möglich.
:FileNTab		= LD_ADDR_REGISTER
:SizeNTab		= 127*17			;BASE_EDITOR_DATA-FileNTab = $1d80
:MaxFileN		= 127				;SizeNTab/17
:FileNTabBuf		= FileNTab + SizeNTab

;--- Variablenspeicher Laufwerkstreiber.
.DDRV_JMP_SIZE		= 3*3
.DDRV_VAR_START		= BASE_DDRV_DATA_NG +DDRV_JMP_SIZE
;DrvAdrGEOS		= DDRV_VAR_START +0
;DrvMode		= DDRV_VAR_START +1
;DrvType		= DDRV_VAR_START +2
.DDRV_VAR_HDPP		= DDRV_VAR_START +3
.DDRV_VAR_SIZE		= 20 -DDRV_JMP_SIZE
.DDRV_SYS_TITLE		= (BASE_DDRV_DATA_NG +DDRV_JMP_SIZE +DDRV_VAR_SIZE)
.DDRV_SYS_DEVDATA	= (BASE_DDRV_DATA_NG +64)

:GD_NG_MODE		= TRUE
endif

;*** GEOS-Header.
			n "GD.DISK.CORE"
			o BASE_DDRV_INIT
			f SYSTEM
			c "GD.DISKCORE V1.0"
			t "G3_Sys.Author"
			z $80				;nur GEOS64

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Systemroutinen zur Installation von Laufwerken."
			h "Nur für MegaPatch/GeoDOS V3!"
endif
if Sprache = Englisch
			h "Core functions to install disk drives."
			h "For MegaPatch/GeoDOS V3 only!"
endif

;******************************************************************************
;*** Systemkennung.
;******************************************************************************
;G3(D)isk(C)oreV(x).(y)
			b "G3DC10"
;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
.x_SlctGEOSadr		jmp	SlctGEOSadr

.x_CopyKernal2REU	jmp	CopyKernal2REU

.x_purgeAllDrvTurbo	jmp	purgeAllDrvTurbo
.x_DskDev_ClrData	jmp	DskDev_ClrData
.x_DskDev_Unload	jmp	DskDev_Unload
.x_DskDev_Prepare	jmp	DskDev_Prepare

.x_FreeRAM		jmp	FreeRAM
.x_AllocRAM		jmp	AllocRAM
.x_FindFreeRAM		jmp	FindFreeRAM

.x_FindSBusDevice	jmp	FindSBusDevice
.x_DetectAllDrives	jmp	DetectAllDrives
.x_DetectCurDrive	jmp	DetectCurDrive
.x_GetAllSerDrives	jmp	xGetAllSerDrives
.x_FindDriveType	jmp	FindDriveType
.x_TurnOnNewDrive	jmp	TurnOnNewDrive
.x_SwapDiskDevAdr	jmp	SwapDiskDevAdr
.x_GetFreeDrvAdr	jmp	GetFreeDrvAdr
.x_SendComVLen		jmp	xSendComVLen

.x_OpenNewDisk		jmp	OpenNewDisk
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
:DrawDBoxTitel		t "-G3_DBoxTitel"		;Titel für Dialogboxen.
			t "-G3_Kernal2REU"		;Kernal in REU aktualisieren.
;******************************************************************************
			t "-DD_DDrvUnload"		;Deinstallation: RAM freigeben.
			t "-DD_DDrvClrDat"		;Deinstallation: Laufwerk löschen.
			t "-DD_DDrvPrepare"		;Installation  : Vorbereiten.
;******************************************************************************
			t "-DD_AllocBank"		;Speicher reservieren.
			t "-DD_GetFreeBank"		;Freien Speicher suchen.
			t "-DD_FreeBank"		;Speicher freiegeben.
:FreeBankTab		= FreeRAM
;******************************************************************************
			t "-DD_SlctDrvAdr"		;GEOS-Laufwerksadresse wählen.
			t "-DD_SwapDrvAdr"		;Laufwerksadresse tauschen.
			t "-DD_GetFreeAdr"		;Freie Laufwerksadresse suchen.
			t "-DD_TurnOnDrv"		;Neues Laufwerk einschalten.
			t "-DD_FindSBusDev"		;Gerät am ser.Bus testen.
			t "-DD_FindDrvType"		;Laufwerkstyp suchen.
			t "-DD_SetDDrvAdr"		;Neue Laufwerksadresse setzen.
			t "-DD_SwapDAdrTab"		;Laufwerksadressen tauschen.
;******************************************************************************

;******************************************************************************
;*** Alle Laufwerke am ser. Bus ermitteln und Typ feststellen.
;******************************************************************************
			t "-D3_PurgeAllTD"		;Alle Laufwerke: TurboDOS aus.
			t "-D3_DriveDetect"		;Laufwerkserkennung.
			t "-D3_DvDetectSys"		;Routinen zur Laufwerkserkennung.
:SendComVLen		t "-D3_SendComVLen"		;Befehl an Lauferk senden.
			t "-D3_SendComCTRL"		;CONTROL-Codes an Laufwerk senden.
			t "-D3_TestSBusDrv"		;Laufwerk am ser.Bus testen.

if CFG_DRV_DETECT = 1
			t "-D3_DvDetect_V1"		;ROM-basierte Erkennung.
endif
if CFG_DRV_DETECT = 2
			t "-D3_DvDetect_V2"		;Eigenschaften-basierte Erkennung.
			t "-D3_DvDetectCMD"		;Routinen zur Partitionsserkennung.
endif

			t "-DD_GetAllDrive"
:TestSBusDrive		= xTestSBusDrive

.devInfo		= sysDevInfo
.devGEOS		= sysDevGEOS
;******************************************************************************

;******************************************************************************
;*** Partition/DiskImage wechseln.
;******************************************************************************
			t "-DD_OpenNewDisk"
			t "-DD_SD2IEC_DIMG"
;******************************************************************************

;******************************************************************************
;*** Ladeadresse Laufwerkstreiber.
;******************************************************************************
:END_DISK_CORE		g ( BASE_DDRV_INIT + SIZE_DDRV_INIT_NG )
.DKDRV_LOAD_ADDR	= BASE_DDRV_DATA_NG
;******************************************************************************
