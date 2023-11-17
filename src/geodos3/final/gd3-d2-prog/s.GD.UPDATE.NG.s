; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DCMD"
			t "SymbTab_64ROM"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "SymbTab_COLOR"
			t "SymbTab_DBOX"
			t "s.GD.BOOT.2.ext"
			t "s.GD.BOOT.NG.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"
			t "src.Config.DMode"
			t "s.GD.DRV.Cor.ext"

			t "o.GD.INITSYS.ext"
:GD_NG_MODE 		= INITSYS_NG_MODE
endif

;*** GEOS-Header.
			n "GD.UPDATE"
			t "G3_Appl.V.Class"
			t "G3_Sys.Author"
			z $80				;nur GEOS64

			o APP_RAM			;BASIC-Start beachten!
			p MainInit

			i
<MISSING_IMAGE_DATA>

;--- Infoblock definieren.
;Hinweis: Um die Laufwerkskonfiguration
;über "GD.CONFIG" automatisch auf Disk
;zu speichern, muss das erste Zeichen
;ein (+) sein. Nicht speichern mit (-).
;Nach dem Update wird das Flag gelöscht.
if Sprache = Deutsch
			h "+: Startet GeoDOS 64 V3"
			h "+/- Laufwerke speichern"
endif
if Sprache = Englisch
			h "+: Launch GeoDOS 64 V3"
			h "+/- Update drive config"
endif

;******************************************************************************
;*** GD.UPDATE - Systemroutinen.
;******************************************************************************
			t "-G3_Core.Update"		;GD.UPDATE-Systemroutinen.
;******************************************************************************

;******************************************************************************
;*** Systemroutinen GD.BOOT/GD.UPDATE.
;******************************************************************************
			t "-G3_Core.Install"		;Shared Code GD.BOOT/GD.UPDATE.
			t "-G3_SvDACCdev"		;DACC-Typ in Boot-Config speichern.
			t "-G3_InitDevRAM"		;RAM-Treiber installieren.
			t "-G3_InitDevSCPU"		;SuperCPU installieren.
			t "-G3_GetPAL_NTSC"		;PAL/NTSC-Erkennung.
;******************************************************************************

;******************************************************************************
;*** Hardware-Erkennung.
;******************************************************************************
;Muss in einem Bereich des Programms
;stehen, der nicht durch das nachladen
;von Programm-Code überschrieben wird!
			t "-G3_CheckSCPU"		;SuperCPU erkennen.
			t "-G3_CheckRLNK"		;RAMLink erkennen.
;******************************************************************************

;******************************************************************************
;*** Ersatz für GEOS 2.0r-StashRAM.
;*** Siehe G3_UpRAMOp für weitere Informationen.
;******************************************************************************
			t "-G3_UpdRAMOp"

;--- GEOS-BOOT: StashRAM/VerifyRAM
:BOOT_STASHRAM		= GD3StashRAM
:BOOT_VERIFYRAM		= GD3VerifyRAM
;******************************************************************************
;*** DoRAMOp-Routine für GeoRAM.
;******************************************************************************
			t "-R3_DoRAM_GUPD"
			t "-R3_DoRAMOpGRAM"
;******************************************************************************

;*** Programmcodes.
:obj_Updater		d "obj.GD.INITSYS"
:end_Updater		b NULL
:UserConfig		= obj_Updater +3
:UserPConfig		= obj_Updater +7
:UserRamBase		= obj_Updater +11

;*** Konfiguartionsparameter für GD.CONFIG
:UserTools		= obj_Updater +15

;******************************************************************************
;*** Endadresse testen.
;*** Ab ":S_KernelData" werden die Kernal-Daten des GD3-Systems geladen!
;******************************************************************************
			g S_KernelData
;******************************************************************************

;******************************************************************************
;*** Die folgenden Routinen sind nur zu Beginn verfügbar und werden im Verlauf
;*** Installation überschrieben.
;******************************************************************************

;*** Zeiger auf Name Laufwerkstreiber.
;Übergabe: XReg = Nummer.
;Rückgabe: r6   = Zeiger auf Name.
:SetDrvNmVec		stx	r6L			;Zeiger auf Laufwerkstyp berechnen.
			LoadB	r1L,17

			ldx	#r6L
			ldy	#r1L
			jsr	BBMult

			AddVW	tempDrvNames,r6
			rts

;*** Aktuellen Laufwerkstreiber laden.
;Übergabe: AKKU   = Zeiger auf Laufwerkstyp.
;Rückgabe: UPDEOF = GEOS-Laufwerkstreiber.
:LoadNewDkDrv		pha

			lda	Device_Boot
			jsr	SetDevice		;Laufwerk aktivieren.

			pla
			tax
			jsr	SetDrvNmVec		;Zeiger auf Dateiname berechnen.
			jsr	FindFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:err			; => Nein, Abbruch...

			MoveB	dirEntryBuf +1,r1L
			MoveB	dirEntryBuf +2,r1H
			LoadW	r2,(OS_VARS - UPDEOF)
			LoadW	r7,UPDEOF
			jsr	ReadFile		;Laufwerkstreiber einlesen.
			txa				;Fehler ?
			bne	:err			; => Nein, Ende...

;--- GEOS-Laufwerkstreiber.
;Hier wird von der Treiberanwendung nur
;der Teil des GEOS-Laufwerkstreibers
;nach ":UPDEOF" kopiert.
;Damit kann die aufrufende Routine die
;Daten des Treibers analysieren und
;anschließend in der REU sichern.
			jsr	i_MoveData
			w	UPDEOF + (DDRV_SYS_DEVDATA - BASE_DDRV_DATA_NG)
			w	UPDEOF
			w	SIZE_DDRV_DATA

			ldx	#NO_ERROR		;Kein Fehler.
			rts

::err			ldx	#DEV_NOT_FOUND		;Treiber nicht gefunden.
::exit			rts

;******************************************************************************
;*** GD.UPDTAE - Systemroutinen Teil #2.
;******************************************************************************
			t "-G3_InitUpdate"
			t "-G3_ChkRAMSize"		;Größe GEOS-DACC testen.
			t "-G3_FindActDACC"		;Aktuellen GEOS-DACC feststellen.
			t "-G3_PrntActDACC"		;Größe GEOS-DACC ausgeben.
			t "-G3_GetRLPEntry"		;RAMLink-Partiton feststellen.
			t "-G3_InitInpDev"		;Eingabegerät installieren.
			t "-G3_LoadSysDrv"		;System-Laufwerkstreiber laden.
			t "-G3_HEX2ASCII"		;HEX-Zahl nach ASCII wandeln.

			t "-D3_1571Mode"		;1571-Laufwerksmodus festlegen.
			t "-D3_PurgeAllTD"		;TurboDOS abschalten.
			t "-D3_DriveDetect"		;Laufwerkserkennung.
			t "-D3_DvDetectSys"		;Routinen zur Laufwerkserkennung.
			t "-D3_SendComVLen"		;Befehl an Lauferk senden.
			t "-D3_SendComCTRL"		;CONTROL-Codes an Laufwerk senden.
			t "-D3_TestSBusDrv"		;Laufwerk am ser.Bus testen.

if CFG_DRV_DETECT = 1
			t "-D3_DvDetect_V1"		;ROM-basierte Erkennung.
endif
if CFG_DRV_DETECT = 2
			t "-D3_DvDetect_V2"		;Eigenschaften-basierte Erkennung.
			t "-D3_DvDetectCMD"		;Routinen zur Partitionsserkennung.
endif

			t "-R3_DetectRLNK"		;RAMLink testen.
			t "-R3_DetectSCPU"		;SuperCPU testen.
			t "-R3_DetectCREU"		;C=REU testen.
			t "-R3_DetectGRAM"		;GeoRAM testen.
			t "-R3_GetSBnkGRAM"		;Bank-Größe GeoRAM feststellen.
;******************************************************************************

;*** Texte für alle Dialogboxen.
if Sprache = Deutsch
:Dlg_Information	b PLAINTEXT,BOLDON
			b "Information:",NULL
:Dlg_CancelUpdate	b "(Zurück zu GEOS)",NULL
endif

if Sprache = Englisch
:Dlg_Information	b PLAINTEXT,BOLDON
			b "Information:",NULL
:Dlg_CancelUpdate	b "(Back to GEOS)",NULL
endif

;--- Speicher für Daten über verfügbare Laufwerkstreiber.
:tempDrvInfo		t "-D3_DrvTypes"

;--- Laufwerksmodi $01,$41,$81...
:tempDrvTypes		= DskDrvTypes
;--- Treibernamen.
:tempDrvNames		= DskDrvNames
;--- Treiberstatus, >0 = Laufwerk/verfügbar.
:tempDrvFound		s DDRV_MAX

;*** Beginn Zwischenspeicher.
;Mind. 2 NULL-Bytes einbinden, da beim
;laden des GEOS-Kernals der Start um
;die BASIC-Ladeadresse reduziert wird.
:UPDEOF			w NULL

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_GEOS_SYS
;******************************************************************************
