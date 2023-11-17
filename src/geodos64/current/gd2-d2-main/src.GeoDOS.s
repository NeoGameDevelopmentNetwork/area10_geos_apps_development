; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; GeoDOS64
; (w) by Markus Kanet
;        darkvision(at)gmx.eu

if .p
			t "TopSym"
			t "Sym128.erg"
			t "TopMac"
			t "GD_Mac"

;*** Landessprache festlegen.
;    Wird im Quellcode "-GD_System"
;    definiert!!!
;    Die GEOS-Klasse ist dort ebenfalls
;    bei neuen Versionen anzupassen.
endif

			n "mod.#100.obj",NULL
			f APPLICATION
			c "GeoDOS 64   V298",NULL
			o $0400
			p MainInit
			a "M. Kanet",NULL
			i
<MISSING_IMAGE_DATA>
			z $00 ; = Nur 40Z.

;******************************************************************************
;Einsprung für "BootGD"
;******************************************************************************
:InitBootGD		jmp	BootGD_Init

;******************************************************************************
;*** Speicheraufteilung.
;******************************************************************************
if .p
;OS_VARS		= $8000				;Beginn GEOS-Variablen.
.Copy2Sek		= $7f00				;CBM-Sektorspeicher #2.
.Copy1Sek		= $7e00				;CBM-Sektorspeicher #1.
;PrintBase		= $7900				;Startadresse Drucker.
.DOS_Driver		= $7200				;Startadresse MSDOS-Treiber.
.DrvSlctBase		= $6400				;Startadresse Laufwerksauswahl (VLIR-Mod)
.FileNTab		= $6100				;Speicher für Dateinamen.
.FilePTab		= $6000				;Speicher für Partitions-Nummern.
.Disk_Sek		= $5f00				;MSDOS-Sektor.
.Disk2_Sek		= Disk_Sek + $0100
.Disk1_Sek		= Disk_Sek + $0000
.FAT			= $4d00				;MSDOS-FAT.
.Boot_Sektor		= $4b00				;MSDOS-Bootsektor.
.FileDTab3		= $4900				;MSDOS-Datenspeicher Größe #4.
.FileDTab2		= $4300				;MSDOS-Datenspeicher Größe #3.
.FileDTab1		= $4200				;MSDOS-Datenspeicher Größe #2.
.FileDTab		= $4100				;MSDOS-Datenspeicher Größe #1.
.TestHardware		= $4000				;Startadresse Hardwaretest-VLIR-Modul.

.EndAreaCBM		= DOS_Driver  -1		;Max. Endadresse CBM-Funktionen.
.EndAreaDOS		= Boot_Sektor -1		;Max. Endadresse DOS-Funktionen.
.EndAreaMenu		= DrvSlctBase -1		;Max. Endadresse Menüfunktionen.

.JobCodeInit		= DOS_Driver +0			;MSDOS-Floppy-Jobcodes initialisieren.
.dosDiskName		= DOS_Driver +3			;MSDOS-Diskettenname.

;*** Einsprungadressen für Bootsektor-Informationen.
.Boot			= Boot_Sektor + $00		;Einsprung in Boot-Routine
.Disk_Typ		= Boot_Sektor + $03		;Name des Herstellers & Version
.BpSek			= Boot_Sektor + $0b		;Anzahl Bytes pro Sektor        (Word).
.SpClu			= Boot_Sektor + $0d		;Anzahl Sektoren pro Cluster    (Byte).
.AreSek			= Boot_Sektor + $0e		;Anzahl reservierter Sektoren   (Word).
.Anz_Fat		= Boot_Sektor + $10		;Anzahl File-Allocation-Tables  (Byte).
.Anz_Files		= Boot_Sektor + $11		;Anzahl Eintraege MainDirectory (Word).
.Anz_Sektor		= Boot_Sektor + $13		;Anzahl Sektoren im Volume      (Word).
.Media			= Boot_Sektor + $15		;Media-Descriptor               (Byte).
.SekFat			= Boot_Sektor + $16		;Anzahl Sektoren pro FAT        (Word).
.SekSpr			= Boot_Sektor + $18		;Anzahl Sektoren pro Spur       (Word).
.AnzSLK			= Boot_Sektor + $1a		;Anzahl der Schreib-/Lese-Köpfe (Word).
.FstSek			= Boot_Sektor + $1c		;Entfernung des ersten Sektors im
							;Volume vom ersten Sektor auf dem
							;Speichermedium                 (Word).

;*** C64-Kernal Einsprünge.
.SECOND			= $ff93				;Sekundär-Adresse nach LISTEN senden.
.TKSA			= $ff96				;Sekundär-Adresse nach TALK senden.
.ACPTR			= $ffa5				;Byte-Eingabe vom IEC-Bus.
.CIOUT			= $ffa8				;Byte-Ausgabe auf IEC-Bus.
.UNTALK			= $ffab				;UNTALK-Signal auf IEC-Bus senden.
.UNLSN			= $ffae				;UNLISTEN-Signal auf IEC-Bus senden.
.LISTEN			= $ffb1				;LISTEN-Signal auf IEC-Bus senden.
.TALK			= $ffb4				;TALK-Signal auf IEC-Bus senden.
.SETLFS			= $ffba				;Dateiparameter setzen.
.SETNAM			= $ffbd				;Dateiname setzen.
.OPENCHN		= $ffc0				;Datei öffnen.
.CLOSE			= $ffc3				;Datei schließen.
.CHKIN			= $ffc6				;Eingabefile setzen.
.CKOUT			= $ffc9				;Ausgabefile setzen.
.CLRCHN			= $ffcc				;Standard-I/O setzen.
.CHROUT			= $ffd2				;Zeichen ausgeben.
.GETIN			= $ffe4				;Zeichen einlesen.
.CLALL			= $ffe7				;Alle Kanäle schließen.

;*** C128-Kernal Einsprünge.
;--- Ergänzung: 26.11.18/M.Kanet
;SETBNK ist im GEOS-Kernal nicht vohanden, da beim C128 die
;Einsprungadressen im KERNAL durch eine BANK-Switch-Routine ersetzt
;wurden. Die Routine muss daher manuell nachgebildet werden!
;SETBNK			= $ff68				;Speicherbank für Dateiname/LOAD setzen.

;*** Einsprünge im RAMLink-Kernal.
.EN_SET_REC		= $e0a9
.RL_HW_EN		= $e0b1
.SET_REC_IMG		= $fe03
.EXEC_REC_REU		= $fe06
.EXEC_REC_SEC		= $fe09
.RL_HW_DIS		= $fe0c
.RL_HW_DIS2		= $fe0f
.EXEC_REU_DIS		= $fe1e
.EXEC_SEC_DIS		= $fe21

;*** Variablen für Dialogboxen.
.IBoxLeft		= 107
.IBoxBase1		= 80
.IBoxBase2		= 90
.DBoxLeft		= 51
.DBoxBase1		= 24
.DBoxBase2		= 34
endif

;******************************************************************************
;*** Liste der Laufwerkstypen für :DriveTypes.
;******************************************************************************
if .p
;*** Unterstützte Laufwerkstypen.
;Bei Änderungen an der Nummerierung sind die Datentabellen anzupassen.
; -> DriveType-Datentabelle:
;    -src.GetDrive        Schreibschutz und Icon-Daten.
;    -dos.FormatRename    DOS-Format-Optionen.
;    -cbm.FormatRename    CBM-Format-Optionen.
;    -src.BootGD          Kopie der Laufwerkstypen.
.Drv_None		= 0				;Kein Laufwerk.
.Drv_1541		= 1				;Commodore 1541 (I,C,II).
.Drv_1571		= 2				;Commodore 1571.
.Drv_1581		= 3				;Commodore 1581.
.Drv_R1541		= 4				;RAMDisk 170 Kbyte = 1541.
.Drv_R1571		= 5				;RAMDisk 340 Kbyte = 1571.
.Drv_R1581		= 6				;RAMDisk 790 Kbyte = 1581.
.Drv_RNAT		= 7				;RAMDisk Native.
.Drv_GWRD		= 8				;GateWay RAMDisk Native.
.Drv_CMDRL		= 9				;CMD RAMLink.
.Drv_CMDRD		= 10				;CMD RAMDrive.
.Drv_CMDFD2		= 11				;CMD FD2000.
.Drv_CMDFD4		= 12				;CMD FD4000.
.Drv_CMDHD		= 13				;CMD HD.
.Drv_64Net		= 14				;64Net.
.Drv_DOS_1581		= 15				;DOS 1581
.Drv_DOS_FD2		= 16				;DOS FD2000
.Drv_DOS_FD4		= 17				;DOS FD4000
.Drv_Native		= 18				;IECBus Native.

;*** Laufwerke bei der Hardware-Erkennung.
;    Später nicht mehr verfügbar!
.Drv_CMDRL_GW		= 19				;gateWay CMD RAMLink.
.Drv_RAMDrv_GW		= 20				;gateWay RAMDrive.
.Drv_CMDRLNat		= 21				;Native-Mode CMD RAMLink.
.Drv_RAMDrvNat		= 22				;Native-Mode RAMDrive.
.Drv_CMDRLNat_GW	= 23				;gateWay CMD RAMLink.
.Drv_RAMDrvNat_GW	= 24				;gateWay RAMDrive.
.Drv_CMDFD2nat		= 25				;Native-Mode CMD FD2000.
.Drv_CMDFD4nat		= 26				;Native-Mode CMD FD4000.
.Drv_CMDHDnat		= 27				;Native-Mode CMD HD.
.Drv_Unknown		= 28				;Unbekannte Laufwerkstypen.
endif

;******************************************************************************
;*** Modul-Nummern.
;*** Als Variablen definiert, damit bei
;*** Änderungen nicht alle Quelltexte
;*** überarbeitet werden müssen!
;******************************************************************************
if .p
;*** Modul-Nummern: GeoDOS 64.
:mod_100		= 0				;Hauptmodul.
:mod_101		= 1				;Hardware-Erkennung.
:mod_102		= 2				;Info.
:mod_103		= 3				;Laufwerksauswahl.
:mod_104		= 4				;Menü.
:mod_105		= 5				;Applikationen/Dokumente.
:mod_106		= 6				;BASIC-Programme starten.
:mod_107		= 7				;ColorSetup.
:mod_108		= 8				;Uhrzeit ändern.
:mod_109		= 9				;Online-Hilfe
:mod_110		= 10				;Laufwerke tauschen.
:mod_111		= 11				;Diskettenfehler.
:mod_112		= 12				;Parken/TurnOff
:mod_113		= 13				;GeoDOS beenden.

;*** Modul-Nummern: GD_COPY.
:mod_201		= 0				;Optionen.
:mod_202		= 1				;Auswahl DOS nach CBM.
:mod_203		= 2				;Auswahl CBM nach DOS.
:mod_204		= 3				;Auswahl CBM nach CBM.
:mod_205		= 4				;Kopierfehlermeldung.
:mod_210		= 5				;Copy DOS to CBM.
:mod_211		= 6				;Copy DOS to geoWrite
:mod_212		= 7				;Copy DOS to CBM       FAST!
:mod_213		= 8				;Copy CBM to DOS.
:mod_214		= 9				;Copy geoWrite to DOS
:mod_215		= 10				;Copy CBM to DOS       FAST!
:mod_216		= 11				;Copy CBM to CBM.
:mod_217		= 12				;Copy CBM to geoWrite
:mod_218		= 13				;Copy geoWrite to CBM
:mod_219		= 14				;Copy geoWrite to geoWrite
:mod_220		= 15				;Copy CBM to CBM       FAST!

;*** Modul-Nummern: GD_DOS.
:mod_301		= 0				;DOS Format/Rename.
:mod_302		= 1				;DOS Directory.
:mod_303		= 2				;DOS Unterverzeichnisse.
:mod_304		= 3				;DOS Dateiparameter.
:mod_308		= 4				;DOS Verzeichnis drucken.
:mod_309		= 5				;DOS Dateien löschen/umbenennen.
:mod_310		= 6				;DOS Dateien drucken.

;*** Modul-Nummern: GD_CBM.
:mod_401		= 0				;CBM Format/Rename.
:mod_402		= 1				;CBM Directory.
:mod_403		= 2				;CBM Partitionen.
:mod_404		= 3				;CBM Dateiparameter.
:mod_405		= 4				;CBM DiskCopy.
:mod_406		= 5				;CBM DiskCopy Kopier-Routine.
:mod_407		= 6				;CBM Directory sortieren.
:mod_408		= 7				;CBM Verzeichnis drucken.
:mod_409		= 8				;CBM Dateien löschen/umbenennen.
:mod_410		= 9				;CBM Dateien drucken.
:mod_411		= 10				;CBM Validate

endif

;******************************************************************************
;*** Systemdaten.
;******************************************************************************
.GD_OS_VARS

;*** GeoDOS-Systemvariablen.
			t "-GD_System"

;*** Tabelle mit Farbwerten.
			t "-ColorData"

;*** Ende Systemvariablen.
.GD_OS_VARS2

;*** GeoDOS-Parameter.
.OptionData		t "-GD_Optionen"

.EndOptionData

;******************************************************************************
;*** Systemvariablen.
;******************************************************************************

;*** Systemvariablen im Infoblock.
.IBlockSektor		= fileHeader
			t "-IBlockData"

;*** Klasse der Systemdateien.
:ToolClass		w AppClass
			w CopyClass
			w DOS_Class
			w CBM_Class

:CopyClass		b "GD_Copy     V2.1",NULL
:DOS_Class		b "GD_DOS      V2.1",NULL
:CBM_Class		b "GD_CBM      V2.2",NULL
:DDrvClass		b "GD_DOSDRIVE V2.2",NULL

;*** Zeiger für "FAT verändert".
.BAM_Modify		b $00

;*** Anzahl Dateien zum kopieren.
.AnzahlFiles		b $00

;*** Angaben über Moduldaten.
:Flag_LdMenu		b $00
:Flag_LdDrvSlct		b $00
:SysClass		w $0000
:X_Register		b $00
:Y_Register		b $00
.ModBuf			s $08				;Zwischenspeicher bei Modulwechsel.

;*** Variablen zum Anzeigen der Hilfe.
:VHelp01		s 17
:VHelp02		b "LoadGeoHelp ",NULL
:VHelp04		b "GeoHelpView ",NULL

:VHelp11		s 32

:VHelp21		b "12345678901234567890",NULL
:VHelp22		w $0000

;*** Partitions- und Verzeichniswechsel-Befehle.
:V100b0			b $00				;Anzahl Einträge.
:V100b1			b "$=P:*=8"
:V100b2			b "$=P"
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;"$*=B"-Befehl durch InitNewDir ersetzt.
if FALSE
:V100b3			b "$*=B"
endif
:V100b4			b "$*=P"
:V100b5			b $00,"478N",$00,$00,$00
:V100b6			b $00,$00, "CD:1234567890123456",NULL
:V100b7			b $03,$00, "CD",$5f
:V100b8			b $04,$00, "CD//"

;******************************************************************************
;*** Systemvariablen.
;******************************************************************************
if Sprache = Deutsch
;*** Variablen.
:V100c0			b $00				;$FF = Aktive Partition übernehmen.

;*** Dialogboxen.
:V100d0			b $ff
			b $00
			b $00
			b $10
			b $00
:V100d1			w $ffff				;Zeiger auf Titel Partitionsauswahl.
			w FileNTab

:V100d2			b $ff
			b $00
			b $00
			b $10
:V100d3			b $00
			w Titel_SDir			;Zeiger auf Titel Partitionsauswahl.
			w FileNTab

.Titel_Part		b PLAINTEXT,"Partition wählen",NULL
.Titel_SDir		b PLAINTEXT,"Verzeichnis wählen",NULL
.Titel_File		b PLAINTEXT,"Dateien wählen",NULL

;*** Infobox-Texte.
.DB_RdPart		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Partitionsdaten"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "einlesen..."
			b NULL

.DB_RdSDir		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Unterverzeichnisse"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "einlesen..."
			b NULL

.DB_RdFile		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Dateien werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "eingelesen..."
			b NULL

;*** Hinweis: "Systemfehler".
:V100a0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Systemlaufwerk defekt",NULL
::102			b        "oder Systemdatei fehlt!",NULL

;*** Hinweis: "Verzeichnis ist nicht ansprechbar!"
:V100a1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Das Verzeichnis ist",NULL
::102			b        "nicht ansprechbar!",NULL

;*** Hinweis: "Kein MSDOS-Treiber!"
:V100a2			w :101, :102, ISet_Achtung
::101			b BOLDON,"MSDOS-Gerätetreiber",NULL
::102			b        "nicht geladen!",NULL
endif

;******************************************************************************
;*** Systemvariablen.
;******************************************************************************
if Sprache = Englisch
;*** Variablen.
:V100c0			b $00				;$FF = Aktive Partition übernehmen.

;*** Dialogboxen.
:V100d0			b $ff
			b $00
			b $00
			b $10
			b $00
:V100d1			w $ffff				;Zeiger auf Titel Partitionsauswahl.
			w FileNTab

:V100d2			b $ff
			b $00
			b $00
			b $10
:V100d3			b $00
			w Titel_SDir			;Zeiger auf Titel Partitionsauswahl.
			w FileNTab

.Titel_Part		b PLAINTEXT,"Select partition",NULL
.Titel_SDir		b PLAINTEXT,"Select folder",NULL
.Titel_File		b PLAINTEXT,"Select files",NULL

;*** Infobox-Texte.
.DB_RdPart		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "partitions..."
			b NULL

.DB_RdSDir		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "folders..."
			b NULL

.DB_RdFile		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "files..."
			b NULL

;*** Hinweis: "Systemfehler".
:V100a0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Systemdrive or GeoDOS",NULL
::102			b        "is corrupt!",NULL

;*** Hinweis: "Verzeichnis ist nicht ansprechbar!"
:V100a1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Cannot open the",NULL
::102			b        "selected folder!",NULL

;*** Hinweis: "Kein MSDOS-Treiber!"
:V100a2			w :101, :102, ISet_Achtung
::101			b BOLDON,"MSDOS-Devicedriver",NULL
::102			b        "not loaded!",NULL
endif

;******************************************************************************
;*** "VLIR-Load"-Systemvariablen.
;******************************************************************************

;*** Daten für Modul einlesen.
; a3L: b MNR = Modulnummer.
; a3H: b $00 = Immer Laufwerksauswahlbox.
;        $80 = Keine Laufwerksauswahlbox.
; !OR: b $00 = Start über "JMP :ModStart +$00"
;        $03 = Start über "JMP :ModStart +$03"
;        $06 = Start über "JMP :ModStart +$06" usw ...
; a4L: b AKR = Wert für AKKU-Register bei Laufwerksauswahlbox.
; a4H: b $00 = Kein DOS-Laufwerk wählen.
;        $40 = Target-DOS.
;        $80 = Source_DOS.

:GD_MenuTab		b mod_102 , $80 ! 0,%00000000,$00;Titelbildschirm.
			b mod_102 , $80 ! 0,%00000000,$00;Infobildschirm.
;--- Ergänzung: 24.04.19/M.Kanet
;Mit MegaPatch V3.3r5 funktioniert die
;Original ToBASIC-Routine wieder.
;Diese kann auch von einem RAM-Laufwerk
;BASIC-Programme laden und starten.
;Das funktioniert zwar nur relativ an
;die Ladeadresse $0801, dafür kann aber
;von allen Laufwerken ein Programm
;ausgeführt werden.
;			b mod_106 , $00 ! 0,%00010000,$00;RunBASIC
			b mod_106 , $00 ! 0,%00000000,$00;RunBASIC
			b mod_110 , $00 ! 0,%00001001,$00;SwapDrives
			b mod_111 , $80 ! 0,%00000000,$00;Diskettenfehler.
			b mod_112 , $80 ! 0,%00000000,$00;ParkHD
			b mod_112 , $80 ! 3,%00000000,$00;UnParkHD
			b mod_112 , $80 ! 6,%00000000,$00;PowerOff

:GD_CopyTab		b mod_201 , $80 ! 0,%00000000,$00;SetOptions
			b mod_202 , $00 ! 0,%10000001,$80;DOStoCBM
			b mod_203 , $00 ! 0,%10000001,$40;CBMtoDOS
			b mod_204 , $00 ! 0,%10100001,$00;CBMtoCBM
			b mod_204 , $00 ! 0,%10000000,$00;Duplicate
			b mod_205 , $80 ! 0,%00000000,$00;CopyError

:GD_DOS_Tab		b mod_301 , $00 ! 0,%10000000,$40;DOS_Format
			b mod_301 , $00 ! 3,%10000000,$40;DOS_Rename
			b mod_302 , $00 ! 0,%00000000,$40;DOS_Dir
			b mod_303 , $00 ! 0,%10000000,$40;DOS_MakeDir
			b mod_303 , $00 ! 3,%10000000,$40;DOS_RemoveDir
			b mod_304 , $00 ! 0,%00000000,$40;DOS_FileData
			b mod_308 , $00 ! 0,%00000000,$40;DOS_DirPrint
			b mod_309 , $00 ! 0,%10000000,$40;DOS_DelFile
			b mod_309 , $00 ! 3,%10000000,$40;DOS_RenFile
			b mod_310 , $00 ! 0,%00000000,$40;DOS_PrnFile

:GD_CBM_Tab		b mod_401 , $00 ! 0,%10000000,$00;CBM_Format
			b mod_401 , $00 ! 3,%10000000,$00;CBM_Rename
			b mod_402 , $00 ! 0,%00000000,$00;CBM_Dir
			b mod_403 , $80 ! 0,%00000000,$00;CBM_Partitionen
			b mod_403 , $00 ! 3,%10000110,$00;CBM_MakeDir
			b mod_403 , $00 ! 6,%10000110,$00;CBM_RemoveDir
			b mod_403 , $00 ! 9,%00000110,$00;CBM_SelectDir
			b mod_404 , $00 ! 0,%00000000,$00;CBM_FileInfo
			b mod_405 , $00 ! 0,%10100001,$00;CBM_DiskCopy
			b mod_407 , $00 ! 0,%10000000,$00;CBM_SortDir
			b mod_408 , $00 ! 0,%00000000,$00;CBM_DirPrint
			b mod_409 , $00 ! 0,%10000000,$00;CBM_DelFile
			b mod_409 , $00 ! 3,%10000000,$00;CBM_RenFile
			b mod_410 , $00 ! 0,%00000000,$00;CBM_PrnFile
			b mod_411 , $00 ! 0,%10000000,$00;CBM_Validate
			b mod_411 , $00 ! 3,%10000000,$00;CBM_Undelete

;*** Untermenü laden.
:SubVLIRtab		b mod_308,3,mod_302,3		;DOS: Verzeichnis drucken.
			b mod_408,3,mod_402,3		;CBM: Verzeichnis drucken.
			b mod_401,6,mod_405,3		;CBM: Laufwerk formatieren.

;*** Klasse der Systemdateien.
:VecToolClass		b $00
:ToolData		w GD_MenuTab
			w GD_CopyTab
			w GD_DOS_Tab
			w GD_CBM_Tab

;******************************************************************************
;*** Haupt-Programmteil.
;******************************************************************************
			t   "-FontType1"
			t   "-ColorBox64"
			t   "-SetColorGD"
			t   "-ConvertChar"
			t   "-PrintText"
			t   "-DialogBox"
			t   "-InfoBox"
			t   "-DoZahl24Bit"
			t   "-ZahlToASCII"
			t   "-FloppyCom"
			t   "-SetNewPart"
			t   "-GetPartInfo"
			t   "-ClrPartInfo"
			t   "-SaveDrive"
			t   "-SystemDrive"
			t   "-NewOpenDisk"
			t   "-CMD_Native"
			t   "-InsertDisk"
			t   "-CheckDiskCBM"
			t   "-CheckDiskDOS"
			t   "-PrepGetFile"
			t   "-LookForFile"
			t   "-SelectBox"
			t   "-SetMseArea"
			t   "-ScrollBar"
			t   "-Addition"
;******************************************************************************

;*** Kein DOS-Laufwerkstreiber.
.NoDOS_Driver		jsr	SetGDScrnCol
			jsr	ClrScreen
			DB_OK	V100a2
			jmp	InitScreen

;*** GeoDOS Disketten-Fehler.
.GDDiskError		jsr	SetGDScrnCol
			jsr	ClrScreen
			DB_OK	V100a0

;*** Rückkehr zum DeskTop.
.OpenDeskTop		lda	#8			;Laufwerk #8 aktivieren.
			jsr	SetDevice
			jsr	PrepareExit		;Farben zurücksetzen.
			jmp	EnterDeskTop		;Zum DeskTop.

;*** Bildschirm löschen und Farben zurücksetzen.
.PrepareExit		jsr	ClrScreen
			jsr	i_C_GEOS
			b	$00,$00,$28,$19

;*** GEOS-Farben setzen.
.SetGEOSCol		lda	C_GEOS_BACK		;Bildschirmfarbe zurücksetzen.
			sta	screencolors
			jsr	InitForIO		;Mauszeiger & Rahmenfarbe zurücksetzen.
			lda	C_GEOS_FRAME
			ldy	C_GEOS_MOUSE
			jmp	SetGDCol1

;*** GeoDOS-Farben setzen.
.SetGDScrnCol		jsr	InitForIO
			lda	C_ScreenBack
			and	#%00001111
			ldy	C_Mouse
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;SetGEOSCol und SetGDScrnCol zusammengeführt.
:SetGDCol1		sta	$d020
			sty	$d027
			jmp	DoneWithIO

;*** Menüs deaktivieren.
.ClearMenus		bit	mouseOn
			bvc	:101
			jsr	RecoverAllMenus
::101			lda	mouseOn
			and	#%10011111
			sta	mouseOn

;*** Bildschirm löschen.
.ClrScreen		Display	ST_WR_FORE
			jsr	ClrBackCol
			jmp	ClrBitMap

;*** Bildschirm löschen.
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Unnötige Befehle entfernt da aktuell kein BackScreen mehr
;verwendet wird (Hier liegen Kopierspeicher und Druckertreiber).
.Clr2BitMap		;jsr	ClrBackScr
.ClrBitMap		;jsr	i_FillRam
			;w	8000,SCREEN_BASE
			;b	$00
			;rts

.ClrBackScr		jsr	i_FillRam
			w	8000,SCREEN_BASE
			b	$00
			rts

;*** Hintergrundfarben setzen.
.ClrBackCol		jsr	i_C_ColorClr
			b	$00,$00,$28,$19
			rts

;*** Neues Laufwerk anmelden.
;    Dabei GeoDOS-Variablen aktualisieren.
.NewDrive		jsr	SetDevice		;Neues Laufwerk definieren.
			txa
			bne	:102			;Laufwerks-Fehler.

			ldx	curDrive		;Aktuelles Laufwerk als "ACTION_DRV"
			stx	Action_Drv		;zwischenspeichern.

			lda	DriveTypes-8,x		;Laufwerks-Typ definieren.
			sta	curDrvType

			lda	DriveModes-8,x		;Emulations-Modus definieren.
			sta	curDrvMode
			and	#%00001000		;RAM-Modus definieren.
			sta	curDriveRAM

			bit	DDrvInstall
			bpl	:101
			jsr	JobCodeInit		;Job-Codes initialisieren.
							;(1581 oder CMD FDx)

::101			ldx	#$00			;Kein Fehler.
::102			rts				;Rücksprung.

;*** Partition wechseln.
.CMD_OtherPart		lda	curDrive
			ldx	#<Titel_Part
			ldy	#>Titel_Part
.CMD_GetPart		jsr	InitCMD1		;Partitionswechsel initialisieren.
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere RTS-Befehle zusammengeführt.
			bmi	CMDExit			; => Abbruch.
			jmp	CMD_1			;Partition wechseln.

;*** Verzeichnis wechseln.
.CMD_OtherNDir		lda	curDrive
			ldx	#<Titel_SDir
			ldy	#>Titel_SDir
			jsr	InitCMD1		;Partitionswechsel initialisieren.
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere RTS-Befehle zusammengeführt.
			bmi	CMDExit			; => Abbruch.
			jmp	CMD_2			;NativeMode-Verzeichnis wechseln.

;*** Partition & Verzeichnis wechseln.
.CMD_NewTarget		lda	curDrive
			ldx	#<Titel_Part
			ldy	#>Titel_Part
			bne	CMD_SlctPart

.CMD_TakePart		lda	curDrive
			ora	#%10000000		;Flag für "Akt. Partition übernehmen"

.CMD_SlctPart		jsr	InitCMD1
			jsr	CMD_1			;Partition wechseln.
			txa
			beq	SlctNDir1
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere RTS-Befehle zusammengeführt.
:CMDExit		rts

.CMD_SlctNDir		jsr	InitCMD1		;Partitionswechsel initialisieren.
:SlctNDir1		jmp	CMD_2			;NativeMode-Verzeichnis wechseln.

;*** Partitionswechsel initialisieren.
.InitCMD1		pha
			and	#%10000000
			sta	V100c0
			bne	:101
			stx	V100d1+0
			sty	V100d1+1
::101			pla
			and	#%01111111
			jsr	NewDrive		;Laufwerk aktivieren.

			lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01			;"OK" ?
			beq	InitNoErr1		; => Ja, Ende...

::102			ldx	#$ff			; => Abbruch.
			rts

;*** Partition aktivieren.
.InitCMD2		ldx	curDrive
			lda	DrivePart - 8,x
			sta	TDrvPart  + 0
			jsr	SetNewPart		;Neue partition setzen.
			txa				;Diskettenfehler?
			beq	:101			; => Nein, weiter...
::100			ldx	#$21			;Fehler: "Disk nicht partitioniert!"
			rts

::101			bit	curDrvMode		;RAMLink/RAMDrive-Partition ?
			bvc	InitNoErr1		; => Nein, weiter...

			lda	Part_Info +22		;RAM-Adresse sichern.
			sta	TDrvPart  + 1
			lda	Part_Info +23
			sta	TDrvPart  + 2

:InitNoErr1		ldx	#$00			;OK, Kein Fehler...
			rts

;*** Haupt- oder Unterverzeichnis festlegen.
.InitCMD3		lda	curDirHead+32
			sta	TDrvNDir  + 1
			ldx	curDirHead+33
			stx	TDrvNDir  + 2
			ldy	#$ff			; => Vorgabe Unterverzeichnis.
			cmp	#$02			;Erster Verzeichnis-Sektor $01/$01
			bcs	:101			;Falls Nein, dann Unterverzeichnis.
			cpx	#$02
			bcs	:101
			iny				; => Hauptverzeichnis.
::101			sty	TDrvNDir  + 0
			rts

;*** Partition wechseln.
:CMD_1			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:104			;Ja, Partitionen einlesen.

::101			ldy	#$02			;Partitionsdaten löschen.
			lda	#$00
::102			sta	TDrvPart,y
			dey
			bpl	:102

			jsr	InitCMD2		;Partition aktivieren.
			txa
			bne	:105

			lda	curDrvMode
			and	#%00100000		;NativeMode-Laufwerk ?
			beq	:103			;Nein, weiter...

			jsr	InitCMD3		;Native-Verzeichnis einlesen und
							;Verzeichnistyp ermitteln.
::103			bit	V100c0			;Partition & Verzeichnis ändern ?
			bpl	:111			;Ja, weiter...
::104			ldx	#$00			;Ende.
::105			rts

;*** Verfügbare Partitionen einlesen.
::111			jsr	CMD_Part		;Partitionen einlesen.
			cpx	#$00			;Disketten-Fehler ?
			bne	:105			;Ja, Ende.
			cmp	#$02			;Mehr als eine Partition ?
			bcc	:114			;Ja, weiter...

::112			lda	#<V100d0
			ldx	#>V100d0
			jsr	SelectBox		;Partitionsauswahlbox.

			lda	r13L			;Partition gewählt ?
			beq	:113			;Ja, weiter...
			cmp	#$01			;Klick auf "OK" ?
			beq	:104			;Ja, Partition übernehmen.
			ldx	#$ff			;Abbruch.
			rts

::113			ldx	r13H			;Zeiger auf Partitions-Eintrag.
::114			lda	FilePTab,x		;Partitionsnummer einlesen,
			ldy	curDrive
			sta	DrivePart-8,y
			jmp	InitCMD2		;Partition aktivieren.

;*** Native-Mode Verzeichnisse wechseln.
:CMD_2			lda	curDrvMode
;--- Ergänzung: 22.11.18/M.Kanet
;Bit#7 für CMD-Laufwerk nicht mehr auswerten das Unterverzeichnisse
;auch auf RAMNative und SD2IEC möglich sind.
;			bpl	:101
			and	#%00100000		;NativeMode-Laufwerk ?
			bne	InitDirSlct		;Ja, weiter...
::101			ldx	#$00			;Ende.
::102			rts

;*** Zum Hauptverzeichnis.
:InitDirSlct		ldy	#$02			;Partitionsdaten löschen.
			lda	#$00
::101			sta	TDrvNDir,y
			dey
			bpl	:101
			jmp	SlctDirIsRoot		;Hauptverzeichnis aktivieren.

;*** Native-Mode Verzeichnisse einlesen.
:SlctNewSubDir		jsr	InitCMD3
			jsr	CMD_NativeDir
			cpx	#$00
			bne	:104
			tax				;Verzeichnisse gefunden ?
			bne	:101			;Ja, weiter...

			bit	TDrvNDir + 0		;Hauptverzeichnis ?
			bpl	:103			;Nein, weiterr

::101			ldy	TDrvNDir + 0		;Hauptverzeichnis ?
			beq	:102			;Ja, weiter...

			jsr	i_MoveData		;"." und ".." - Eintrag erzeugen.
			w	FileNTab + 0
			w	FileNTab +32
			w	254 * 16
			jsr	i_MoveData
			w	FilePTab + 0
			w	FilePTab + 2
			w	254

			jsr	i_FillRam
			w	32
			w	FileNTab
			b	" "
			lda	#"."
			sta	FileNTab + 0
			sta	FileNTab +16
			sta	FileNTab +17
			lda	#$00
			sta	FilePTab + 0
			sta	FilePTab + 1

			ldy	#$02
::102			sty	V100d3			;Anzahl ACTION-Files.

			lda	#<V100d2
			ldx	#>V100d2
			jsr	SelectBox		;Verzeichnisauswahlbox.

			lda	r13L			;Verzeichnis gewählt ?
			beq	:106			;Ja, weiter...
			cmp	#$01			;Klick auf "OK" ?
			bne	:105			;Nein, Abbruch.
::103			ldx	#$00			;Verzeichnis übernehmen.
::104			rts

::105			jsr	SetOldDir		;Verzeichnis zurücksetzen.
			ldx	#$ff			;Abbruch.
			rts

::106			CmpB	r13H,V100d3		;"." oder ".." - Eintrag ?
			bcc	CheckNewDir		;Ja, weiter...
			jmp	OpenNewDir		;Nein, Verzeichnis wählen.

;*** Zurück zum Hauptverzeichnis.
:CheckNewDir		cmp	#$00			;"." - Eintrag ?
			bne	SlctDirIsSubD		;Nein, weiter...

;*** Hauptverzeichnis aktivieren.
:SlctDirIsRoot		jsr	New_CMD_Root		;Hauptverzeichnis aktivieren.
			C_Send	V100b8			;Befehl "CD//" senden.
			jmp	SlctNewSubDir		;Weitere Verzeichnisse wählen.

;*** Unterverzeichnis aktivieren.
:SlctDirIsSubD		jsr	GetDirHead		;Elternverzeichnis aktivieren.

			ldx	curDirHead+35		;Zeiger auf Parent-Verzeichnis
			lda	curDirHead+34 		;einlesen. Hauptverzeichnis ?
			beq	SlctDirIsRoot		;Ja, zum Hauptverzeichnis.
			jsr	SetDirToUSER		;Parent-Verzeichnis aktivieren.
			C_Send	V100b7			;Befehl "CD/" senden.
			jmp	SlctNewSubDir		;Weitere Verzeichnisse wählen.

;*** Neues Verzeichnis aktivieren.
:OpenNewDir		ldy	#$10
			lda	#$00
			sta	(r15L),y		;Ende Dateinamen markieren.

			MoveW	r15,r6			;Eintrag zu Verzeichnis suchen.
			jsr	FindFile
			txa
			beq	:302

			DB_OK	V100a1			;"Verzeichnis nicht verfügbar!"
			jsr	SetOldDir
			jmp	SlctNewSubDir

::302			ldy	#$00
::303			lda	(r15L),y		;Verzeichnisname in "CD"-Befehl
			beq	:304			;kopieren.
			sta	V100b6+5,y
			iny
			cpy	#$10
			bne	:303
::304			tya				;Anzahl Zeichen in "CD"-Befehl
			add	3			;berechnen.
			sta	V100b6+0
			C_Send	V100b6			;Verzeichnis mit "CD"-Befehl wechseln.

			lda	dirEntryBuf+1		;Zeiger auf Header-Sektor für
			ldx	dirEntryBuf+2		;neues Verzeichnis einlesen.
			jsr	SetDirToUSER		;Verzeichnis aktivieren.
			jmp	SlctNewSubDir		;Weitere Verzeichnisse wählen.

;*** Native-Mode-Verzeichnis zurücksetzen.
:SetOldDir		lda	TDrvNDir +1
			ldx	TDrvNDir +2

;*** NativeMode-Verzeichnis für GEOS anmelden.
:SetDirToUSER		sta	r1L
			stx	r1H
			jmp	New_CMD_SubD		;Neues Native-Verzeichnis setzen.

;*** Kompatible Partition einlesen.
.CMD_Part		ldy	curDrive		;Partitions-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			tay
			lda	V100b5,y
			beq	:101
			sta	V100b1 +6

::101			jsr	DoInfoBox
			PrintStrgDB_RdPart

			lda	#<V100b1
			ldx	#>V100b1
			ldy	#$07
			jmp	InitDir

;*** Alle Partition einlesen.
.CMD_AllPart		jsr	DoInfoBox
			PrintStrgDB_RdPart

			lda	#<V100b2
			ldx	#>V100b2
			ldy	#$03
			jmp	InitDir

;*** Native-Mode-Verzeichnisse einlesen.
.CMD_NativeDir		jsr	DoInfoBox
			PrintStrgDB_RdSDir

;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;"$*=B"-Befehl durch InitNewDir ersetzt.
if FALSE
			lda	#<V100b3		;Verzeichnisse über "$*=B" einlesen.
			ldx	#>V100b3
			ldy	#$04
			jmp	InitDir
endif
			jmp	InitNewDir		;Verzeichnisse für GEOS-Routinen
							;einlesen.

;*** Native-Mode-Verzeichnisse einlesen.
.CMD_Files		jsr	DoInfoBox
			PrintStrgDB_RdFile

			lda	#<V100b4
			ldx	#>V100b4
			ldy	#$04

;*** Aktuelles Verzeichnis einlesen.
;Das Verzeichnis wird über den "$"-Befehl über den seriellen
;Bus eingelesen und in den Dateinamenspeicher übertragen.
.InitDir		sty	r14H
			sta	r15L
			stx	r15H

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO

;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere LISTEN-Befehle durch Unterprogramm ersetzt.
			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.

			bit	STATUS			;Status-Byte prüfen.
			bpl	:102			;OK, weiter...
::101			ldx	#$0d			;Fehler: "Laufwerk nicht bereits".
			jmp	EndInitDir		;Abbruch.

::102			lda	#$f0			;Datenkanal aktivieren.
			jsr	SECOND
			bit	STATUS			;Status-Byte prüfen.
			bmi	:101			;Fehler, Abbruch.

::103			ldy	#$00
::104			lda	(r15L),y		;Byte aus Befehl einlesen und
			jsr	CIOUT			;an Floppy senden.
			iny
			cpy	r14H			;Alle Zeichen gesendet ?
			bne	:104			;Nein, weiter...
			jsr	UNLSN			;Befehl abschliesen.

;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere TALK-Befehle durch Unterprogramm ersetzt.
			lda	#$f0			;Datenkanal öffnen.
			jsr	TALK_CURDRV		;TALK-Signal auf IEC-Bus senden.

			jsr	ACPTR			;Byte einlesen.

			bit	STATUS			;Status testen.
			bpl	:105			;OK, weiter...
			ldx	#$05			;Fehler: "Verzeichnis nicht gefunden".
			jmp	EndInitDir

::105			ldy	#$1f			;Verzeichnis-Header
::106			jsr	ACPTR			;überlesen.
			dey
			bne	:106

			jsr	InitDirData

;*** Partitionen aus Verzeichnis einlesen.
::200			jsr	ACPTR			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	:300
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	ACPTR			;Low-Byte der Zeilen-Nr.
			ldy	V100b0			;in Tabelle.
			sta	FilePTab,y
			jsr	ACPTR			;High-Byte Zeilen-Nr. überlesen.

::201			jsr	ACPTR			;Weiterlesen bis zum
			cmp	#$00			;Dateinamen.
			beq	:205
			cmp	#$22			; " - Zeichen erreicht ?
			bne	:201			;Nein, weiter...

			ldy	#$00			;Zeichenzähler löschen.
::202			jsr	ACPTR			;Byte aus Dateinamen einlesen.
			cmp	#$22			;Ende erreicht ?
			beq	:203			;Ja, Ende...
			sta	(r15L),y		;Byte in Tabelle übertragen.
			iny
			bne	:202

::203			jsr	Add_16_r15		;Zeiger auf Speicher für nächsten
			inc	V100b0			;Dateinamen, Zähler +1.
			CmpBI	V100b0,255		;Speicher voll ?
			beq	:300			;Ja, Ende...

::205			jsr	ACPTR			;Rest der Verzeichniszeile überlesen.
			cmp	#$00
			bne	:205
			jmp	:200			;Nächsten Dateinamen einlesen.

;*** Verzeichnis-Ende.
::300			jsr	UNTALK			;Datenkanal schließen.

;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere LISTEN-Befehle durch Unterprogramm ersetzt.
			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.

			lda	#$e0			;Laufwerk abschalten.
			jsr	SECOND
			jsr	UNLSN

			ldx	#$00			;Kein Fehler.

;*** Verzeichnis abschließen.
:EndInitDir		txa
			pha
			jsr	DoneWithIO		;I/O deaktivieren.
			jsr	ClrBox			;Infobox löschen.
			pla
			tax
			lda	V100b0			;Anzahl Einträge.
			rts				;Ende.

;*** Speicher für Dateieinträge löschen.
;--- Ergänzung: 22.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrere Init-Befehle durch Unterprogramm ersetzt.
:InitDirData		jsr	i_FillRam		;Speicher für Dateinamen löschen.
			w	18*256
			w	FilePTab
			b	$00

			lda	#$00
			sta	V100b0			;Anzahl Einträge löschen.

			lda	#<FileNTab		;Zeiger auf Speicher für Daten.
			sta	r15L
			lda	#>FileNTab		;Zeiger auf Speicher für Daten.
			sta	r15H
			rts

;--- Ergänzung: 22.11.18/M.Kanet
;*** Neues Verzeichnis über GEOS-Routinen einlesen.
;Wird für den Wechsel von NativeMode-Unterverzeichnissen verwendet.
:InitNewDir		jsr	InitDirData

			jsr	GetDirHead
			txa
			beq	:102
::101			rts

::102			jsr	EnterTurbo
			txa
			bne	:101

			jsr	InitForIO

			LoadW	r4,diskBlkBuf

			lda	curDirHead +0
			ldx	curDirHead +1
::103			sta	r1L
			stx	r1H
			jsr	ReadBlock
			txa
			bne	:400

;			ldx	#$00
::104			txa
			pha

			lda	diskBlkBuf +2,x
			cmp	#$86			;Typ Verzeichnis?
			bne	:107			; => Nein, weiter...

			ldy	#$00			;Name in Zwischenspeicher übertrage.
::105			lda	diskBlkBuf +5,x
			cmp	#$a0
			beq	:106
			sta	(r15L),y
			inx
			iny
			cpy	#16
			bcc	:105

::106			jsr	Add_16_r15		;Zeiger auf Speicher für nächsten
			inc	V100b0			;Dateinamen, Zähler +1.
			CmpBI	V100b0,255		;Speicher voll ?
			bne	:107			;Ja, Ende...
			pla
			jmp	:300

::107			pla				;Zeiger auf nächsten Eintrag
			clc				;in Verzeichnis-Sektor setzen.
			adc	#$20
			tax				;Ende erreicht?
			bne	:104			; => Nein, weiter...

			ldx	diskBlkBuf +1		;Nächsten Verzeichnis-Sektor einlesen.
			lda	diskBlkBuf +0		;Ende erreicht?
			bne	:103			; => Nein, weiter...

::300			ldx	#$00			;Kein Fehler.

;*** Verzeichnis abschließen.
::400			jmp	EndInitDir

;*** Hilfe installieren.
.InstallHelp		sta	VHelp22    +0
			stx	VHelp22    +1

			ldy	#$00
::101			lda	(r0L)  ,y
			sta	VHelp21,y
			beq	:102
			iny
			bne	:101
			tya
::102			sta	keyData

			lda	keyVector  +0
			sta	:104       +1
			lda	keyVector  +1
			sta	:104       +3
			LoadW	keyVector,:103
			rts

;*** Auf F1-Taste testen.
::103			CmpBI	keyData,$01
			beq	:105
::104			lda	#$ff
			ldx	#$ff
			jmp	CallRoutine

::105			jsr	OpenSysDrive
			jsr	BootHelp
			jsr	OpenUsrDrive
			jmp	(VHelp22)

;*** Hilfe aktivieren.
.BootHelp		lda	#DESK_ACC
			ldx	#<VHelp02
			ldy	#>VHelp02
			jsr	LookForFile
			txa
			beq	:102
::101			rts

::102			jsr	i_MoveData
			w	FileNameBuf
			w	VHelp01
			w	16

;*** Infosektor von "GeoHelpView" anpassen.
			jsr	LoadGHV_Hdr
			txa
			bne	:101

			jsr	i_MoveData
			w	fileHeader +$a0
			w	VHelp11
			w	$0020

			lda	#"="
			sta	fileHeader +$a0
			lda	#">"
			sta	fileHeader +$a1

			lda	fileHeader +$a2
			cmp	#"("
			bne	:105

			ldy	#$03
::103			lda	fileHeader +$a0,y
			cmp	#")"
			beq	:104
			iny
			bne	:103
			beq	:105

::104			iny
			b $2c

::105			ldy	#$02
			ldx	#$00
::106			lda	VHelp21        ,x
			sta	fileHeader +$a0,y
			beq	:107
			iny
			inx
			cpx	#$16
			bcc	:106

			lda	#$00
			sta	fileHeader +$a0,y

::107			jsr	SaveGHV_Hdr

;*** OnlineHilfe starten.
:StartHelp		PushB	screencolors

			lda	C_ScreenClear
			sta	screencolors

			jsr	PrepGetFile		;":dlgBoxRamBuf"-Speicher löschen.

;			LoadB	r0L,%0000000		;Wird durch "PrepGetFile" gelöscht!
			LoadW	r6 ,VHelp01		;Zeiger auf Dateiname.
;			ClrB	r10L			;Wird durch "PrepGetFile" gelöscht!
			jsr	GetFile			;OnlineHilfe starten.

			jsr	ClrScreen
			PopB	screencolors

			jsr	LoadGHV_Hdr

			jsr	i_MoveData
			w	VHelp11
			w	fileHeader +$a0
			w	$0020

			jmp	SaveGHV_Hdr

;*** GeoHelpView-Infoblock suchen & einlesen.
:LoadGHV_Hdr		lda	#APPLICATION
			ldx	#<VHelp04
			ldy	#>VHelp04
			jsr	LookForFile
			txa
			bne	:101

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo
::101			rts

;*** GeoHelpView-Infoblock schreiben.
:SaveGHV_Hdr		lda	dirEntryBuf+$13
			sta	r1L
			lda	dirEntryBuf+$14
			sta	r1H
			LoadW	r4,fileHeader
			jmp	PutBlock

;*** Bildschirm löschen, Hauptmenü und
;    Laufwerksauswahlin Speicher einlesen.
.InitScreen		jsr	SetLdMainFile		;Zeiger auf GeoDOS-Hauptprogramm.

			bit	Flag_LdDrvSlct		;Laufwerkswahl im Speicher ?
			bmi	:101			;Ja, nur Hauptmenü laden.
			jsr	LdDrvSlctBox		;Laufwerksauswahlbox einlesen.

::101			bit	Flag_LdMenu		;Menü im Speicher ?
			bmi	:102			;Nein, Laufwerkswahl & Menü laden.
			jsr	LdGD_MainMenu		;Hauptmenü einlesen.

::102			lda	#$ff			;Menü und Laufwerkswahl mit
			sta	Flag_LdMenu		;Flag "Im Speicher" markieren.
			sta	Flag_LdDrvSlct

			jsr	DoneGetMod		;Anwender-Laufwerk öffnen.
			lda	#$00
			jmp	DefJumpAdr		;Hauptmenü starten.

;*** Menü-Funktionen laden.
;    Routinen dürfen max. bis Adresse ":DrvSlctBase" reichen, damit die
;    Laufwerksauswahlbox-Routine im Speicher nicht überschrieben wird!
.vExitBASIC		ldx	#$00			;Nach BASIC verlassen.
			b $2c
.vExitGD		ldx	#$ff			;Nach DeskTop verlassen.
			lda	#mod_113
			jmp	GetMenuMod

.vAppl_Doks		lda	#mod_105		;Applikation / Dokument öffnen.
			b $2c
.vColorSetup		lda	#mod_107		;ColorSetup
			b $2c
.vSetCMDtime		lda	#mod_108		;Uhrzeit setzen.
			b $2c
.vGetHelp		lda	#mod_109		;GetHelp

;*** Menü-Funktionen laden.
:GetMenuMod		stx	X_Register
			sty	Y_Register

			pha
			jsr	SetLdMainFile		;Zeiger auf GeoDOS-Hauptprogramm.
			pla
			jsr	LdGD_Data		;VLIR-Modul einlesen.

			ClrB	Flag_LdMenu		;Hauptmenü nicht mehr im Speicher.
			jsr	DoneGetMod		;Anwender-Laufwerk öffnen.

			ldy	Y_Register
			ldx	X_Register
			lda	#$00
			jmp	DefJumpAdr

;*** Laufwerk wählen, bei Abbruch zum Menü zurück.
:GetDrvConfig		bit	Flag_LdDrvSlct
			bmi	:101

			pha
			txa
			pha
			tya
			pha

			jsr	SetLdMainFile		;Zeiger auf GeoDOS-Hauptprogramm.
			jsr	LdDrvSlctBox		;Laufwerksauswahlbox einlesen.
			jsr	DoneGetMod		;Anwender-Laufwerk öffnen.
			lda	#$ff			;Flag: "Laufwerkswahl im Speicher".
			sta	Flag_LdDrvSlct
			pla
			tay
			pla
			tax
			pla
::101			jsr	DrvSlctBase
			cpx	#$00
			beq	:102
			jmp	InitScreen

::102			rts

;*** Standard-Routinen laden.
.vTitel			lda	# 0			;Titelbildschirm, muß "ldx #0" sein!
			b $2c
.vInfo			lda	# 4			;Infobildschirm
			b $2c
.vRunBASIC		lda	# 8			;BASIC-Programme starten
			b $2c
.vSwapDrives		lda	#12			;Laufwerke tauschen.
			b $2c
.DiskError		lda	#16 ! $80		;Diskettenfehler.
			b $2c
.vParkHD		lda	#20			;ParkHD
			b $2c
.vUnParkHD		lda	#24			;UnParkHD
			b $2c
.vPowerOff		lda	#28			;PowerOff

			jsr	SetRegister		;X/Y-Register speichern.

			ldx	#$00
			jmp	Load1VLIR

;*** Kopieroptionen/Fehler.
.vSetOptions		lda	#0			;SetOptions
			b $2c
.vSetOpt1		lda	#0  ! $80		;SetOpt1
			b $2c
.vCopyError		lda	#20 ! $80		;CopyError
			jmp	GD_Copy_101

;*** Kopieren: DOS - CBM.
.vDOStoCBM		ldx	#%00000000		;DOStoCBMmit  Partitionsauswahl.
			b $2c
.vDOStoGW		ldx	#%10000000		;DOStoGWmit  Partitionsauswahl.
			b $2c
.vDOStoCBM_F		ldx	#%01000000		;DOStoCBM_Fmit  Partitionsauswahl.
			lda	#4 ! $80
			jmp	GD_Copy_100

;*** Kopieren: CBM - DOS.
.vCBMtoDOS		ldx	#%00000000		;CBMtoDOSmit  Partitionsauswahl.
			b $2c
.vGWtoDOS		ldx	#%10000000		;GWtoDOSmit  Partitionsauswahl.
			b $2c
.vCBMtoDOS_F		ldx	#%01000000		;CBMtoDOS_Fmit  Partitionsauswahl.
			lda	#8 ! $80
			jmp	GD_Copy_100

;*** Kopieren: CBM - CBM.
.vCBMtoCBM		ldx	#%00000000		;CBMtoCBMmit  Partitionsauswahl.
			b $2c
.vCBMtoGW		ldx	#%10000000		;CBMtoGWmit  Partitionsauswahl.
			b $2c
.vGWtoCBM		ldx	#%01000000		;GWtoCBMmit  Partitionsauswahl.
			b $2c
.vGWtoGW		ldx	#%00100000		;GWtoGWmit  Partitionsauswahl.
			b $2c
.vCBMtoCBM_F		ldx	#%00010000		;CBMtoCBM_Fmit  Partitionsauswahl.
			lda	#12 ! $80
			jmp	GD_Copy_100

;*** Dateien duplizieren.
.vDuplicate		ldx	#%00001000		;Duplicatemit  Partitionsauswahl.
			lda	#16 ! $80

;*** Modul aus Datei "GD_Copy" einlesen.
:GD_Copy_100		bit	CopyMod
			bpl	GD_Copy_101
			inx
:GD_Copy_101		jsr	SetRegister		;X/Y-Register speichern.

			ldx	#$02
			jmp	Load1VLIR

;*** Kopier-Routinen.
;    Einsprung nicht über ":Load1VLIR"
;    da hier der Bildschirm gelöscht
;    wird und in diesem Bereich bereits
;    die Kopier-Informationen liegen!
.vC_DOStoCBM		lda	#mod_210		;DOStoCBM
			b $2c
.vC_DOStoGW		lda	#mod_211		;DOStoGW
			b $2c
.vC_DOStoCBM_F		lda	#mod_212		;DOStoCBM_F
			b $2c
.vC_CBMtoDOS		lda	#mod_213		;CBMtoDOS
			b $2c
.vC_GWtoDOS		lda	#mod_214		;GWtoDOS
			b $2c
.vC_CBMtoDOS_F		lda	#mod_215		;CBMtoDOS_F
			b $2c
.vC_CBMtoCBM		lda	#mod_216		;CBMtoCBM
			b $2c
.vC_CBMtoGW		lda	#mod_217		;CBMtoGW
			b $2c
.vC_GWtoCBM		lda	#mod_218		;GWtoCBM
			b $2c
.vC_GWtoGW		lda	#mod_219		;GWtoGW
			b $2c
.vC_CBMtoCBM_F		lda	#mod_220		;CBMtoCBM_F
			jsr	GetModule		;VLIR-Modul laden und
			lda	#$00
			jmp	DefJumpAdr		;Modul starten.

;*** DOS-Routinen laden.
.vD_Format		lda	#0			;Formatieren
			b $2c
.vD_Rename		lda	#4			;Diskettenname ändern
			b $2c
.vD_Dir			lda	#8			;Inhaltsverzeichnis
			b $2c
.vD_MD			lda	#12			;Verzeichnis erstellen
			b $2c
.vD_RD			lda	#16			;Verzeichnis löschen
			b $2c
.vD_FileInfo		lda	#20			;Datei-Informationen
			b $2c
.vD_DirPrint		lda	#24			;Directory drucken
			b $2c
.vD_DelFile		lda	#28			;Dateien löschen
			b $2c
.vD_RenFile		lda	#32			;Dateien umbenennen
			b $2c
.vD_PrnFile		lda	#36			;Dateien drucken

			jsr	SetRegister		;X/Y-Register speichern.

			ldx	#$04
			jmp	Load1VLIR

;*** Modul als Unterprogramm aufrufen.
.vD_PrnCurDir		ldx	#$00			;Aktuelles Verzeichnis drucken.
			jmp	LoadSubVLIR

;*** CBM-Routinen laden.
.vC_Format		lda	#0			;Formatieren
			b $2c
.vC_Rename		lda	#4			;Diskettenname ändern
			b $2c
.vC_Dir			lda	#8			;Inhaltsverzeichnis
			b $2c
.vC_PartCMD		lda	#12			;Partitionswechsel
			b $2c
.vC_MD			lda	#16			;Verzeichnis erstellen
			b $2c
.vC_RD			lda	#20			;Verzeichnis löschen
			b $2c
.vC_CD			lda	#24			;Verzeichnis wechseln
			b $2c
.vC_FileInfo		lda	#28			;Datei-Informationen
			b $2c
.vC_DiskCopy		lda	#32			;Diskette kopieren
			b $2c
.vC_SortDir		lda	#36			;Verzeichnis sortieren
			b $2c
.vC_DirPrint		lda	#40			;Directory drucken
			b $2c
.vC_DelFile		lda	#44			;Dateien löschen
			b $2c
.vC_RenFile		lda	#48			;Dateien umbenennen
			b $2c
.vC_PrnFile		lda	#52			;Dateien drucken
			b $2c
.vC_Validate		lda	#56			;Diskette aufräumen
			b $2c
.vC_UndelFile		lda	#60			;Dateien retten

			jsr	SetRegister		;X/Y-Register speichern.

			ldx	#$06
			jmp	Load1VLIR

;*** Folgemodul einlesen.
.vC_DISKtoDISK		lda	#mod_406		;DISKtoDISK Kopiervorgang starten.
			jsr	GetModule
			lda	#$00
			jmp	DefJumpAdr

;*** Modul als Unterprogramm aufrufen.
.vC_PrnCurDir		ldx	#$04			;Aktuelles Verzeichnis drucken.
			b $2c
.vC_Format1		ldx	#$08			;Aktuelle Diskette formatieren.
			jmp	LoadSubVLIR

;*** Zeiger auf GeoDOS-Hauptprogramm &
;    "VLIR-Load" initialisieren.
:SetLdMainFile		ldx	#$00
			jsr	SetToolClass

;*** "VLIR-Load" initialisieren.
:InitGetMod		jsr	MouseOff		;Mauszeiger abschalten.
			jsr	OpenSysDrive		;Start-Laufwerk aktivieren.

			lda	#APPLICATION
			ldx	VecToolClass
			beq	:101
			lda	#SYSTEM
::101			sta	r7L
			lda	#$01
			sta	r7H
			LoadW	r6,AppNameBuf
			MoveW	SysClass,r10
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			beq	:103			;Nein, weiter...
::102			jmp	GDDiskError		;Systemfehler.

::103			lda	r7H			;Modul gefunden ?
			bne	:102			;Nein, Systemfehler...

			LoadW	r0,AppNameBuf		;VLIR-Header einlesen.
			jsr	OpenRecordFile
			jmp	CloseRecordFile

;*** "VLIR-Load" beenden.
:DoneGetMod		jsr	OpenUsrDrive		;Anwenderlaufwerk öffnen.
			jmp	MouseUp			;Mauszeiger einschalten.

;*** AKKU, X- und Y-Register definieren.
:SetRegister		cmp	#$80			;X- und Y-Register löschen ?
			bcs	:101			;Nein, weiter...

			ldx	#$00			;X- und Y-Register mit $00-Byte
			ldy	#$00			;vorbelegen.

::101			stx	X_Register		;X- und Y-Register zwischenspeichern.
			sty	Y_Register

			and	#%01111111		;Zeiger auf Modul-Tabelle berechnen.
			rts

;*** Klasse für GeoDOS-Systemdatei.
:SetToolClass		stx	VecToolClass
			lda	ToolClass+0,x
			sta	SysClass +0
			lda	ToolClass+1,x
			sta	SysClass +1
			rts

;*** VLIR-Modul laden.
;    AKKU: Modul-Nr. in VLIR-Datei.
:GetModule		pha
			jsr	InitGetMod		;"VLIR-Load" initialisieren.
			pla
			jsr	LdGD_Data
			jmp	DoneGetMod		;Anwender-Laufwerk öffnen.

;*** GeoDOS-Hauptmenü einlesen.
:LdGD_MainMenu		lda	#mod_104

;*** GeoDOS-Funktion einlesen.
;    AKKU: Modul-Nummer im Speicher.
:LdGD_Data		ldx	#<ModStart
			ldy	#>ModStart
			bne	LdVLIR_Data

;*** Laufwerksauswahlbox einlesen.
:LdDrvSlctBox		lda	#mod_103
			ldx	#<DrvSlctBase
			ldy	#>DrvSlctBase

;*** GeoDOS-VLIR-Modul einlesen.
:LdVLIR_Data		stx	r7L			;Startadresse speichern.
			sty	r7H

			asl				;Zeiger auf VLIR-Datensatz berechnen.
			tax
			lda	fileHeader+2,x		;Zeiger auf ersten Datensatz-Sektor
			beq	:101			;einlesen und speichern.
			sta	r1L
			lda	fileHeader+3,x
			sta	r1H
			LoadW	r2,$7fff-ModStart
			jsr	ReadFile		;Modul in Speicher einlesen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Systemfehler.

			stx	Flag_LdMenu		;Menü und Laufwerkswahl mit
			stx	Flag_LdDrvSlct		;"Nicht im Speicher" markieren.
			rts

::101			jmp	GDDiskError		;Systemfehler.

;*** VLIR-Modul einlesen.
;    AKKU = Zeiger auf Datentabelle.
;    XReg = Zeiger auf Programmteil.
;           $00 = GeoDOS 64
;           $02 = GD_COPY
;           $04 = GD_DOS
;           $06 = GD_CBM
:Load1VLIR		clc
			adc	ToolData +0,x		;Zeiger auf VLIR-Tabelle berechnen.
			sta	a2L
			lda	#$00
			adc	ToolData +1,x
			sta	a2H

			jsr	SetToolClass		;Class für Programmteil definieren.

			ldy	#$03
::101			lda	(a2L),y			;VLIR-Daten kopieren.
			sta	a3,y
			dey
			bpl	:101

			jsr	ClearMenus		;Bildschirm & Menüs löschen.

			lda	a4H			;DOS-Laufwerk wählen ?
			beq	:102			;Nein, weiter...
			bit	DDrvInstall		;DOS-Treiber geladen ?
			bmi	:102			;Ja, weiter...
			jmp	NoDOS_Driver		;Fehler: "DOS-Treiber nicht geladen!"

::102			bit	a3H			;Laufwerksauswahl ?
			bmi	:104			;Nein, weiter...

			PushB	VecToolClass

			lda	a4H			;Parameter für Laufwerksauswahl.
			and	#%10000000
			tax
			lda	a4H
			and	#%01000000
			asl
			tay
			lda	a4L
			jsr	GetDrvConfig		;Laufwerk wählen.

			pla
			tax
			jsr	SetToolClass

;*** Zeiger auf VLIR-Modul definieren und Modul einlesen.
::104			lda	a3L
			jsr	GetModule

			lda	a3H
			and	#%00111111
			ldx	X_Register
			ldy	Y_Register

;*** Einsprungadresse definieren & Programm starten.
:DefJumpAdr		clc
			adc	#<ModStart
			sta	a8L
			lda	#$00
			adc	#>ModStart
			sta	a8H
			LoadW	a9,InitScreen
			jmp	(a8)

;*** VLIR-Modul als Unterprogramm einlesen.
;    X-Register ist Offset auf ":SubVLIRtab".
:LoadSubVLIR		jsr	:101			;Unterprogramm laden.

			ldx	:102 + 1		;Offset wieder einlesen und auf
			inx				;Rücksprung-Programm richten.
			inx

::101			stx	:102 +1
			lda	SubVLIRtab+0,x
			jsr	GetModule		;Modul einlesen.

::102			ldx	#$ff			;Einsprungadresse berechnen.
			lda	SubVLIRtab+1,x
			jmp	DefJumpAdr

;******************************************************************************
;Ladeadresse für VLIR-Module.
;******************************************************************************

.ModStart

;******************************************************************************
;GeoDOS initialisieren.
;******************************************************************************
:BootGD_Init		jsr	i_MoveData
			w	PRINTBASE
			w	GD_OS_VARS
			w	(GD_OS_VARS2 - GD_OS_VARS)
			jmp	PrintTitel

:MainInit		t   "-InitSystem"
			t   "-CheckRAM"

;******************************************************************************
;*** ENDE ***
;******************************************************************************
