; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DDRV"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "SymbTab_GRAM"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "s.GD.BOOT.ext"
			t "s.GD.BOOT.2.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"
			t "o.DvRAM_RLNK.ext"
			t "o.DvRAM_SRAM.ext"
			t "o.DiskCore.ext"

;--- GD.INI-Version.
			t "opt.INI.Version"
endif

;*** GEOS-Header.
			n "GD.UPDATE"
			c "GDUPDATE    V3.0"
			t "opt.Author"
			f APPLICATION
			z $80 ;nur GEOS64

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
if LANG = LANG_DE
			h "+: Startet GDOS64"
			h "+/- Laufwerke speichern"
endif
if LANG = LANG_EN
			h "+: Launch GDOS64"
			h "+/- Update drive config"
endif

;*** Installationsroutine.
:obj_Updater		d "obj.GD.INITSYS"
:end_Updater		b NULL

;--- Speicherkonfiguration.
:UserRAMData		= obj_Updater +3

;--- Laufwerkskonfiguration.
:UserConfig		= obj_Updater +8
:UserPConfig		= obj_Updater +12
:UserPType		= obj_Updater +16
:UserRamBase		= obj_Updater +20

;*** Konfiguartionsparameter für GD.CONFIG
:UserTools		= obj_Updater +24

;*** Farben für Setup-Menü.
			t "v.MenuColDef"		;Farbdefinitionen.

;*** GD.UPDATE - Systemroutinen.
			t "-G3_Core.Update"		;GD.UPDATE-Systemroutinen.

;*** Systemroutinen GD.BOOT/GD.UPDATE.
			t "-G3_Core.Install"		;Shared Code GD.BOOT/GD.UPDATE.
			t "-G3_InitDevRAM"		;RAM-Treiber installieren.
			t "-G3_InitDevSCPU"		;SuperCPU installieren.
			t "-G3_GetPAL_NTSC"		;PAL/NTSC-Erkennung.
			t "-G3_LdPrntInpt"		;Drucker-/Eingabetreiber laden.

;*** Hardware-Erkennung.
;HINWEIS:
;Muss in einem Bereich des Programms
;stehen, der nicht durch das nachladen
;von Programm-Code überschrieben wird!
			t "-G3_CheckSCPU"		;SuperCPU erkennen.
			t "-G3_CheckRLNK"		;RAMLink erkennen.

;*** DoRAMOp für GeoRAM/GEOS 2.x.
;HINWEIS:
;Ersatz für GEOS 2.0r-StashRAM wegen
;evtl. unterschiedlicher Bank-Größe.
;Siehe G3_UpRAMOp für weitere
;Informationen.
			t "-G3_UpdRAMOp"

;--- GEOS-BOOT: StashRAM/VerifyRAM
:BOOT_STASHRAM		= GD3StashRAM
:BOOT_VERIFYRAM		= GD3VerifyRAM
			t "-R3_DoRAM_GUPD"
			t "-R3_DoRAMOpGRAM"

;******************************************************************************
;*** Endadresse testen.
;*** Ab ":S_KernalData" werden die Kernal-Daten des GDOS-Systems geladen!
;******************************************************************************
			g S_KernalData
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
			LoadW	r2,(OS_BASE - UPDEOF)
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
			w	UPDEOF + (DDRV_SYS_DEVDATA - BASE_DDRV_DATA)
			w	UPDEOF
			w	DISK_DRIVER_SIZE

			ldx	#NO_ERROR		;Kein Fehler.
			rts

::err			ldx	#DEV_NOT_FOUND		;Treiber nicht gefunden.
::exit			rts

;******************************************************************************
;*** GD.UPDTAE - Systemroutinen Teil #2.
;******************************************************************************
			t "-G3_InitUpdate"		;Update initialisieren.
			t "-G3_ChkRAMSize"		;Größe GEOS-DACC testen.
			t "-G3_FindActDACC"		;Aktuellen GEOS-DACC feststellen.
			t "-G3_PrntActDACC"		;Größe GEOS-DACC ausgeben.
			t "-G3_GetRLPEntry"		;RAMLink-Partiton feststellen.
			t "-G3_InitInpDev"		;Eingabegerät installieren.
			t "-G3_LoadSysDrv"		;System-Laufwerkstreiber laden.
			t "-G3_HEX2ASCII"		;HEX-Zahl nach ASCII wandeln.

			t "-D3_1571Mode"		;1571-Laufwerksmodus festlegen.

			t "-R3_DetectRLNK"		;RAMLink testen.
			t "-R3_DetectSCPU"		;SuperCPU testen.
			t "-R3_DetectCREU"		;C=REU testen.
			t "-R3_DetectGRAM"		;GeoRAM testen.
			t "-R3_GetSBnkGRAM"		;Bank-Größe GeoRAM feststellen.
;******************************************************************************

;******************************************************************************
;*** Aktuelles Laufwerke am ser. Bus ermitteln.
;******************************************************************************
:DETECT_MODE = %01000000
			t "-D3_DriveDetect"		;Laufwerkserkennung.
;******************************************************************************

;*** Texte für alle Dialogboxen.
if LANG = LANG_DE
:Dlg_Information	b PLAINTEXT,BOLDON
			b "INFORMATION:",NULL
:Dlg_CancelUpdate	b PLAINTEXT
			b "(Zurück zu GEOS)",NULL
endif

if LANG = LANG_EN
:Dlg_Information	b PLAINTEXT,BOLDON
			b "INFORMATION:",NULL
:Dlg_CancelUpdate	b PLAINTEXT
			b "(Back to GEOS)",NULL
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

;*** Datei suchen.
;Übergabe: A/X = Zeiger auf Dateiname.
:FindFileAX		sta	r6L
			stx	r6H
			jsr	FindFile		;auf Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			rts

;*** GD.INI-Datei suchen.
:FindGDINI		lda	#< FNamGDINI
			ldx	#> FNamGDINI
			jsr	FindFileAX
;			txa
			bne	:exit

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Konfiguration einlesen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, neue GD.INI erzeugen.

			lda	diskBlkBuf +2
			cmp	#GDINI_VER		;GD.INI-Version gültig?
			bne	:err			; => Nein, neue GD.INI erzeugen.
			lda	diskBlkBuf +3
			cmp	#$c0			;GD.INI-Kennung gültig?
			beq	:exit			; => Ja, Ende...

::err			ldx	#INCOMPATIBLE
::exit			rts

;*** Gültige GD.INI suchen/erstellen.
:TestGDINI		jsr	FindGDINI		;GD.INI suchen.
			txa				;Datei vorhanden/gültig?
			beq	:exit			; => Ja, weiter...

			cpx	#FILE_NOT_FOUND		;Datei nicht gefunden?
			beq	:create			; => Ja, GD.INI erstellen.

::replace		LoadW	r0,FNamGDINI
			jsr	DeleteFile		;Vorhandene GD.INI löschen.

::create		LoadB	r10L,0
			LoadW	r9,HdrB000
			jsr	SaveFile		;Neue GD.INI-Datei speichern.
;			txa
;			bne	:exit

::exit			rts

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w FNamGDINI
::002			b $03,$15
			b $bf
			b %10101010,%10101010,%10101011
			b %01010101,%01010101,%01010111
			b %10000000,%00000000,%00000011
			b %01001111,%00111110,%00000011
			b %10011000,%00110011,%00000011
			b %01011011,%10110011,%00000011
			b %10011001,%10110011,%00000011
			b %01001111,%10111110,%00000011
			b %10000000,%00000000,%00000011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01001000,%10100101,%00010011
			b %10001100,%10110101,%00110011
			b %01001100,%10101101,%00110011
			b %10001000,%10100101,%00010011
			b %01000000,%00000000,%00000011
			b %10000000,%00000000,%00000011
			b %01111111,%11111111,%11111111
			b %11111111,%11111111,%11111111

::068			b $82				;PRG
			b SYSTEM			;GEOS-Systemdatei
			b SEQUENTIAL			;GEOS-Dateityp SEQUENTIELL
			w CFG_START			;Programm-Anfang
			w CFG_END			;Programm-Ende
			w $0000				;Programm-Start
::077			t "opt.INI.Build"		;Klasse/Version
			b $00				;Bildschirmflag
::097			b "GDOS64"			;Autor
			s 14				;Reserviert
			s 12  				;Anwendung/Klasse
			s 4  				;Anwendung/Version
			b NULL
			s 26				;Reserviert
::160			b NULL				;Infotext

;::HdrEnd		s (HdrB000+256)-:HdrEnd

;*** GDOS64 Konfiguration.
:CFG_START
:CFG_GDOS		t "-G3_StdConfig"
:CFG_GDOS_END		e CFG_GDOS +254

;*** GeoDesk Konfiguration.
:CFG_GDESK		t "-G3_StdConfigGD"
:CFG_GDESK_END		e CFG_GDESK +254
:CFG_END
