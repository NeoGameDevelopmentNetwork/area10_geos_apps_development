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
			t "SymbTab_MMAP"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "SymbTab_GRAM"
			t "SymbTab_GRFX"
			t "SymbTab_DCMD"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "s.GD.BOOT.2.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"
			t "o.DvRAM_RLNK.ext"
			t "o.DvRAM_SRAM.ext"

;--- GD.INI-Version.
			t "opt.INI.Version"

;--- GEOS-BOOT: StashRAM/VerifyRAM
:BOOT_STASHRAM		= StashRAM
:BOOT_VERIFYRAM		= VerifyRAM

;--- Variablenspeicher Laufwerkstreiber.
;HINIWEIS:
;Datei wird über den Kernal geladen,
;dabei werden die ersten beiden Bytes
;als Ladeadresse interpretiert.
:DDRV_BOOT_BASE		= (BASE_GEOS_SYS -2)
:DDRV_JMP_SIZE		= 3*3
;:DDRV_VAR_SIZE		= 20 -DDRV_JMP_SIZE
;:DDRV_VAR_START	= BASE_DDRV_DATA_NG +DDRV_JMP_SIZE
:DDRV_VAR_START		= DDRV_BOOT_BASE +DDRV_JMP_SIZE
;:DDRV_VAR_GADR		= DDRV_VAR_START +0
;:DDRV_VAR_MODE		= DDRV_VAR_START +1
;:DDRV_VAR_TYPE		= DDRV_VAR_START +2
;--- Konfigurationsregister:
;%1xxxxxxx = CMDHD-PP-Modus aktiv.
;%x1xxxxxx = CMDHD-PP-Modus wählen.
;%xx1xxxxx = Keine Partition wählen.
:DDRV_VAR_CONF		= DDRV_VAR_START +3
;--- Treiberspezifische Register.
:DDRV_PPOFFSET		= DDRV_VAR_START +4
;
;--- Titel für Treiber-Installation.
;:DDRV_SYS_TITLE	= (DDRV_BOOT_BASE +DDRV_JMP_SIZE +DDRV_VAR_SIZE)
;--- Start Laufwerkstreiber.
:DDRV_SYS_DEVDATA	= (DDRV_BOOT_BASE +64)
endif

;*** GEOS-Header.
			n "GD.BOOT"
			c "GDOSBOOT    V3.0"
			t "opt.Author"
;--- Hinweis:
;Startprogramme können von DESKTOP 2.x
;nicht kopiert werden.
;			f SYSTEM_BOOT ;Typ Startprogramm.
			f SYSTEM      ;Typ Systemdatei.
			z $80 ;nur GEOS64

			o BASE_GEOSBOOT -2		;BASIC-Start beachten!
			p MainInit

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Installiert GDOS64"
			h "auf Ihrem C64-System..."
endif
if LANG = LANG_EN
			h "Install GDOS64"
			h "on your C64 system..."
endif

;*** Füllbytes.
.L_KernalData		w BASE_GEOSBOOT			;DummyBytes, da Programm über
							;BASIC-LOAD geladen wird!!!
;*** Einsprung aus GEOS-Startprogramm.
:InitBootProc		jmp	MainInit

;*** Angaben zum Systemstart.
;Speichererweiterung:
;Wird beim Start automatisch erkannt
;oder aus GD.INI eingelesen.
;
;Startlaufwerk:
;Wird beim Start automatisch erkannt.
;

;--- Speichererweiterung.
;BOOT_RAM_TYPE wird durch GD.RESET auf
;$00 gesetzt -> Auswahlmenü anzeigen.
;BOOT_RAM_TYPE: $00 = RAM nicht gewählt.
;               $10 = RAMCard gewählt.
;               $20 = BBGRAM  gewählt.
;               $40 = C=REU   gewählt.
;               $80 = RAMLink gewählt.
;               $FF = DACC neu wählen.
:BOOT_RAM_TYPE		b $00    ;DACC-Speicher: Typ.
:BOOT_RAM_SIZE		b $00    ;DACC-Speicher: Größe.
:BOOT_RAM_BANK		w $0000  ;Adresse erste Speicherbank RAMLink/RAMCard.
:BOOT_RAM_PART		b $00    ;Nicht verwendet.

;--- Startlaufwerk.
;Mögliche Werte für BOOT_MODE:
;(Kombinieren mit SET_MODE_xx ! SET_MODE_yy)
;SET_MODE_PARTITION = %10000000;CMD-Partitionen.
;SET_MODE_SUBDIR    = %01000000;CMD-NativeMode-Verzeichnisse.
;SET_MODE_FASTDISK  = %00100000;CMD-HDPP/RL/RAMDISK.
;
:Boot_Drive		b $00				;Laufwerks-Adresse.
:Boot_Type		b $00				;Laufwerks-Typ.
:Boot_Mode		b $00				;Laufwerks-Modus.
:Boot_Part		b $00				;Boot-Partition.
			b $00				;CMD-RL: High-Byte Boot-Partition.

;RAMLink:
;:Boot_Drive		b $08				;Laufwerks-Adresse.
;:Boot_Type		b DrvRL81			;Laufwerks-Typ.
;:Boot_Mode		b SET_MODE_PARTITION!SET_MODE_FASTDISK
;:Boot_Part		b $00				;Boot-Partition.
;			b $00				;CMD-RL: High-Byte Boot-Partition.
;CMD-HD:
;:Boot_Drive		b $08				;Laufwerks-Adresse.
;:Boot_Type		b DrvHD81			;Laufwerks-Typ.
;:Boot_Mode		b SET_MODE_PARTITION!SET_MODE_FASTDISK
;:Boot_Part		b $00				;Boot-Partition.
;			b $00				;CMD-RL: High-Byte Boot-Partition.
;1581:
;:Boot_Drive		b $08				;Laufwerks-Adresse.
;:Boot_Type		b Drv1581			;Laufwerks-Typ.
;:Boot_Mode		b NULL
;:Boot_Part		b $00				;Boot-Partition.
;			b $00				;CMD-RL: High-Byte Boot-Partition.

;*** GD.BOOT - Systemroutinen.
			t "-G3_Core.Boot"		;GD.BOOT-Systemroutinen.
			t "-G3_PrntString"		;Boot-Meldungen ausgeben.
			t "-G3_DataBootInfo"		;Boot-Meldungen.
;			t "-G3_InitDevHD"		;CMD-HD-Kabel deaktivieren.

;*** Systemroutinen GD.BOOT/GD.UPDATE.
			t "-G3_Core.Install"		;Shared Code GD.BOOT/GD.UPDATE.
			t "-G3_SvDACCdev"		;DACC-Typ in Boot-Config speichern.
			t "-G3_LoadGDINI"		;GD.INI-Datei in DACC laden.
			t "-G3_InitDevRAM"		;RAM-Treiber installieren.
			t "-G3_InitDevSCPU"		;SuperCPU installieren.

;--- Standard-Gerätetreiber laden.
;Wird durch GD.CONFIG ausgeführt.
;Der Kernal beinhaltet standardmäßig
;den Mouse1351-Treiber.
;			t "-G3_LdPrntInpt"		;Drucker-/Eingabetreiber laden.

;*** Hardware-Erkennung.
;HINWEIS:
;Code darf nicht überschrieben werden!
			t "-G3_CheckSCPU"		;SuperCPU erkennen.
			t "-G3_CheckRLNK"		;RAMLink erkennen.

;*** Kernal-Daten.
;HINWEIS:
;Der folgende Datenbereich wird auch
;von "GD.UPDATE" mitverwendet.
.S_KernalData		t "-G3_KernalData"
.E_KernalData		g BASE_GEOS_SYS
;******************************************************************************

;*** Erweiterte Systemroutinen.
;HINWEIS:
;Alle folgenden Routinen werden beim
;Start teilweise überschrieben!

;--- Startmeldungen ausgeben.
			t "-G3_GetPAL_NTSC"
			t "-G3_PrntBootInf"
			t "-G3_PrntCoreInf"

;--- GD.INI.
			t "-G3_LdDACCdev"		;DACC-Typ aus Boot-Config einlesen.
			t "-G3_CreateGDINI"		;Neue GD.INI-Datei erzeugen.

;--- Speichererweiterung.
			t "-R3_DetectRLNK"
			t "-R3_DetectSCPU"
			t "-R3_DetectCREU"
			t "-R3_DetectGRAM"
			t "-R3_GetSizeSRAM"
			t "-R3_GetSizeCREU"
			t "-R3_GetSizeGRAM"
			t "-R3_GetSBnkGRAM"

;--- GEOS-DACC testen.
			t "-G3_GetRLPEntry"
			t "-G3_FindRAMExp"
			t "-G3_GetRAMType"

;*** Startlaufwerk übernehmen.
			t "-G3_BootNG.DDev"
			t "-G3_BootNG.DDat"
;******************************************************************************

;*** Startlaufwerk identifizieren.
:DETECT_MODE = %01000000
			t "-D3_DriveDetect"		;Laufwerkserkennung.
