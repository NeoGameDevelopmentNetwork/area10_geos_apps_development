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
			t "s.GD.BOOT.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"
			t "src.Config.DMode"

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
;Hinweis: Die ersten beiden Zeichen geben darüber Auskunft ob
;die Laufwerkskonfiguration über GD.CONFIG gespeichert werden
;soll (+) und ob GD.MAKEBOOT ausgeführt werden soll (+).
;Nach dem update sind beide Flags gelöscht (-).
if Sprache = Deutsch
			h "++: Startet GeoDOS 64 V3"
			h "+/- Laufwerke speichern"
			h "+/- Bootdisk erstellen"
endif
if Sprache = Englisch
			h "++: Launch GeoDOS 64 V3"
			h "+/- Configure disk drives"
			h "+/- Create bootdisk"
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

;*** Aktuellen Laufwerkstreiber laden.
;Übergabe: AKKU = Zeiger auf Laufwerkstyp.
:LoadNewDkDrv		sta	:record

			LoadW	r0 ,FNamGDISK
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	:record			;Datensatz-Nr. einlesen.
			asl				;Zeiger auf Tabelle berechnen.
			tay
			lda	tempDrvRecords +1,y
			jsr	PointRecord		;Zeiger auf Datensatz setzen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			LoadW	r2,R1_SIZE_DSKDEV_A
			LoadW	r7,UPDEOF
			jsr	ReadRecord		;Laufwerkstreiber einlesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

::err			txa
			pha
			jsr	CloseRecordFile
			pla
			tax
			rts

::record		b $00

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

;*** Speicher für Daten über verfügbare Laufwerkstreiber.
;--- Angaben aus GD.DISK:
;Bei Änderungen "s.GD.DISK.MODE",
;"s.GDC.Drives" und "s.GD.UPDATE"
;ebenfalls anpassen!

;--- Systemkennung für GEOS.Disk.
;G3(D)isk(C)oreV(x).(y)
:tempDrvInfo		b "G3DC10"

;--- Speicher für Daten über verfügbare Laufwerkstreiber.
			t "-D3_DrvTypes"
			t "-D3_DrvTypesVLIR"

;--- Laufwerksmodi $01,$41,$81...
:tempDrvTypes		= DskDrvTypes
;--- Treibernamen.
:tempDrvNames		= DskDrvNames
;--- Datensatztabelle DInit,DDrv.
:tempDrvRecords		= DskDrvVLIR

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
