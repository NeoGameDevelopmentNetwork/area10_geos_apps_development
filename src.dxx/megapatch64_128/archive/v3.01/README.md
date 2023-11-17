# Area6510

# GEOS MEGAPATCH 64/128 [GERMAN]
For english translation please scroll down...


# MegaPatch 3.01:
MegaPatch 3.01 wurde im Jahr 2003 von W.Grimm veröffentlicht und enthält einige Erweiterungen wie etwas 64Net-Unterstützung und den TopDesk V4.
Der hier veröffentlichte Source-Code ist der Versuch den Code der Version von 2003 zu rekonstruieren.


### Systemvoraussetzungen:

Um den MegaPatch-Quelltext zu kompilieren wird der MegaAssembler V3.9 benötigt. Sofern die einzelnen Quelltext-Dateien manuell kompiliert werden sollen, ist die Version V3.8 ausreichend.
Aktuell wurde MegaPatch nur auf einem bereits installiertem MegaPatch-System kompiliert. Auf einem reinem GEOS2-System müssen die Dateien manuell kompiliert werden da die AutoAssembler-Dateien bereits MegaPatch-Systemroutinen verwenden (CMD-Partitionswechsel).


### Inhalt der Quelltext-Disketten:

##### Disk #1 - Symbol
Disk#1 beinhaltet Symboltabellen und AutoAssembler-Dateien. Ausserdem finden sich hier die BootScreen-Dateien im geoPaint-Format, welche vor dem erstellen der SETUP-Dateien auf die ziel-Diskette kopiert werden müssen.

##### Disk #2 - Kernal
Disk#2 beinhaltet den GEOS MegaPatch-Kernal für den C64/C128.

##### Disk #3 - System
Disk#3 beinhaltet erweiterte Kernal-Funtkionen.

##### Disk #4 - Disk
Disk#4 beinhaltet die Laufwerkstreiber.

##### Disk #5 - Program
Disk#5 beinhaltet den GEOS.Editor und ie GEOS Startprogramme.

##### Disk #6 - Extras
Disk#6 Icons, Fonts und externe Symboltatbellen.




### Der Source-Code:
Die Quelltext-Disketten sind vorbereitet für ein Vier-Laufwerks-Setup.
Wenn die AutoAssembler-Konfiguration angepasst werden soll ist die Datei 'ass.DRIVES' auf der Diskette 'mp-d1-symbol' entsprechend anzupassen.
Die Datei 'src.GEOS_MP3.64/128' beinhaltet die Definition der Landessprache.
Die Datei 'src.BuildRev' definiert den aktuellen Build.




### Laufwerks-Setup:
Szenario #1 ist voreingestellt.

##### Szenario #1:
RAMNM  Laufwerk 10:    Desktop, MegaAssembler, Symboldateien,
                       Makrodateien, AutoAssembler-Dateien,
                       Ziel-Laufwerk für Objektcode.
                       Mind. 800Kb Speicher.
RAMNM  Laufwerk 11:    MegaPatch-Kernal, Systemerweiterungen,
                       Programme, Laufwerkstreiber
                       Mind. 2500Kb Speicher

##### MegaAssembler-Setup:
Quelltexte: Laufwerk D:/11
Programmcode: Laufwerk C:/10
Symboltabellen: Laufwerk C:/10
AutoAssembler: Laufwerk C:/10

##### Szenario #2: (Ungetestet)
1581   Laufwerk 8:     Desktop, MegaAssembler, Symboldateien,
                       Makrodateien, AutoAssembler-Dateien,
                       Ziel-Laufwerk für Objektcode.
1581   Laufwerk 9:     MegaPatch-Kernal, Systemerweiterungen,
                       Programme, Laufwerkstreiber
                       MegaAssembler fordert ggf. zu einem
                       Diskettenwechsel auf.

##### MegaAssembler-Setup:
Quelltexte: Laufwerk B:/9
Programmcode: Laufwerk A:/8
Symboltabellen: Laufwerk A:/8
AutoAssembler:Laufwerk A:/8




### Konfigurieren des MegaPatch Source-Codes:
Um die Sprache für GEOS-MegaPatch festzulegen ist die Datei 'src.SetLanguage' auf der Diskette 'mp_d2_kernal' anzupassen.




### Lokale Anpassungen:
Erforderlich wenn MegaPatch ohne MakeBoot gestartet werden soll:

##### mp_d2_kernal/-GEOS_ID:
In dieser Datei ist die GEOS-ID anzupassen. Angabe in 4-stelliger, hexadezimaler Form.

##### mp_d5_programm/-G3_BootData2:
Hier muss der Laufwerkstreiber für den Boot-Vorgang eingebunden werden. Die verfügbaren Treiber können der Datei mp64_128_disk/lnk.G3_64.Disk.s entnommen werden. (Standard: DiskDrv_1581)

##### mp_d5_programm/-G3_BootData:
Beim Label ":BootType" ist der Laufwerkstyp für den Boot-Vorgang festzulegen. Die verfügbaren Typen kann man der Datei mp64_128_symbol/SymbTab-1.s entnehmen. (Standard: Drv1581)

##### mp_d1_symbol/-A3_Disk#2
Diese Datei beinhaltet den Laufwerkstreiber für die Bootdisk. Die Datei muss nur dann geändert werden wenn man den AutoAssembler verwendet.




### AutoAssembler:
Es wird empfohlen den AutoAssembler zu verwenden um GEOS-MegaPatch zu kompilieren, da die Dateien in einer bestimmten Reihenfolge kompiliert werden müssen.
Die AutoAssembler-Macros verwenden GEOS-MegaPatch-Systemaufrufe, daher können die AutoAssembler-Dateien nur unter einem bereits installierten GEOS-MegaPatch verwendet werden.
* ass.MP64/128.s             Kompiliert die AutoAssembler Steuerdateien
* ass.MP64/128_1.s           Kernal kompilieren und packen
* ass.MP64/128_2.s           Laufwerkstreiber und Programme kompilieren
* ass.MP64/128_DSK.s         Nur Laufwerkstreiber kompilieren
* ass.MP64/128_PRG.s         Nur Programme kompilieren

* ass.MP64/128_1      Stage1: Kernal erstellen. Das Programm wird beendet und der Kernal gepackt.
* ass.MP64/128_2      Stage2: Laufwerkstreiber und Programme kompilieren.




### Vorbereitungen:
Um GEOS-MegaPatch mit Hilfe von Szenario#1 zu kompilieren müssen die Quelltext-Dateien wie folgt auf die beiden Systemlaufwerke verteilt werden:

##### Laufwerk #10:
Beinhaltet DeskTop, geoWrite, MegaAssembler und ggf. Druckertreiber.
Ausserdem sollten alle Dateien der Disk 'mp_d1_symbol' auf dieses Laufwerk kopiert werden.
Dieses Laufwerk sollte als AutoAssembler und ProgrammCode-Laufwerk definiert werden.

##### Laufwerk #11:
ACHTUNG: TopDesk kann nicht mehr als 255 Dateien auf ein Laufwerk kopieren. Abhile ist mit geoDOS oder DualTop möglich. Beide Programme funktionieren auch im 40Z-Modus unter GEOS128.
Die Inhalte der Disketten 'mp-d2-kernal', 'mp-d3-system', 'mp-d4-disk' und 'mp-d5-prohram' sollten auf diesen Laufwerk kopiert werden.
Im MegaAssembler dieses Laufwerk als 'Quelltext'-Laufwerk einstellen.




### Kompilieren:
MegaAssembler starten und im AutoAssembler-Modus 'MP64/128_1' auswählen. Es wird der Kernal kompiliert und gepackt. Danach erfolgt die Rückkehr zum Desktop.
Nach der Rückkehr zum Desktop MegaAssembler erneut starten und 'MP64/128_2' kompilieren. Es werden jetzt alle benötigten Systemdateien erzeugt.




### MakeInstall:
Um die MegaPatch-Installationsdateien zu erstellen müssen zuvor noch die Hintergrundbilder auf das Ziel-Laufwerk kopiert werden:
* MegaScreen.pic: C64/C128
* BOOTMP64.PIC  : C64
* BOOTMP128.PIC : C128
Anschließend die Datei 'MakeInstall_64/128' starten. Die benötigten Systemdateien werden zusamengefasst und komprimiert.




### StartMP:
Zur Installation werde auf dem Ziel-Computer folgende Dateien benötigt:
* StartMP64/128
* StartMP64/128.1
* StartMP64/128.2
* StartMP64/128.3
* StartMP64/128.4
* StartMP64/128.5




### Manuelle Installation von GEOS-MegaPatch.
Die Liste der Dateien und Reihenfolge stehtr am Ende dieser README-Datei.


.
.
.
.


# GEOS MEGAPATCH 64/128 [ENGLISH]


# MegaPatch 3.01:
MegaPatch 3.01 was released in 2003 by W.Grimm and includes some enhancements such as 64Net support and TopDesk V4.
The source code published here is an attempt to reconstruct the code of the 2003 version.


### System requirements:

To compile the MegaPatch source code the MegaAssembler V3.9 is needed. If the individual source text files are to be compiled manually, version V3.8 is sufficient.
Currently MegaPatch has been compiled on an already installed MegaPatch system. On a pure GEOS2 system, the files must be compiled manually because the AutoAssembler files already use MegaPatch system routines (CMD partition switch).


### Content of the source diskettes:

##### Disk # 1 - Symbol
Disk # 1 includes symbol tables and AutoAssembler files. In addition, you will find the BootScreen files in geoPaint format, which have to be copied to the target disk before creating the SETUP files.

##### Disk # 2 - Kernal
Disk # 2 includes the GEOS MegaPatch kernel for the C64 / C128.

##### Disk # 3 - System
Disk # 3 includes extended kernal functions.

##### Disk # 4 - Disk
Disk # 4 includes the ddisk drivers.

##### Disk # 5 - Program
Disk # 5 includes the GEOS.Editor and GEOS startup programs.

##### Disk # 6 - Extras
Disk # 6 Icons, fonts and external symbol charts.




### The source code:
The source diskettes are prepared for a four-drive setup.
If the AutoAssembler-configuration is to be adjusted, the file 'ass.DRIVES' on the diskette 'mp-d1-symbol' must be adapted accordingly.
The file 'src.GEOS_MP3.64/128' includes settings for the system language.
The src.BuildRev file defines the current build.




### Drive setup:
Scenario # 1 is the default.

##### Scenario # 1:
RAMNM drive 10: Desktop, MegaAssembler, Symbol files,
                       Macro files, AutoAssembler files,
                       Destination drive for object code.
                       About 800Kb of disk space.
RAMNM Drive 11: MegaPatch Kernal, System Extensions,
                       Programs, disk drivers
                       About 2300Kb of disk space.

##### MegaAssembler-Setup:
Source code: drive D: / 11
Program code: drive C: / 10
Symbol tables: Drive C: / 10
AutoAssembler: drive C: / 10

##### Scenario # 2: (Untested)
1581 Drive 8: Desktop, MegaAssembler, Symbol files,
                       Macro files, AutoAssembler files,
                       Destination drive for object code.
1581 Drive 9: MegaPatch Kernal, System Extensions,
                       Programs, disk drivers
                       MegaAssembler may ask for one
                       Floppy change on.

##### MegaAssembler-Setup:
Source code: drive B: / 9
Program code: Drive A: / 8
Symbol tables: Drive A: / 8
AutoAssembler: drive A: / 8




### Configuring the MegaPatch Source Code:
To set the language for GEOS-MegaPatch the file 'src.SetLanguage' has to be adapted on the disk 'mp_d2_kernal'.




### Local adjustments:
Required if MegaPatch should be started without MakeBoot:

##### mp_d2_kernal / -GEOS_ID:
In this file the GEOS-ID has to be adapted. Specification in 4-digit, hexadecimal form.

##### mp_d5_program / -G3_BootData2:
This file includes the disk driver for the boot process. The available drivers can be found in the file mp64_128_disk / lnk.G3_64.Disk.s. (Default: DiskDrv_1581)

##### mp_d5_program / -G3_BootData:
For the ": BootType" label, specify the drive type for the boot process. The available types can be found in the file mp64_128_symbol / SymbTab-1.s. (Default: Drv1581)

##### mp_d1_symbol / -A3_Disk # 2.s
This file contains the disk driver for the boot disk. The file only needs to be changed when using the AutoAssembler.




### AutoAssembler:
It is recommended to use the AutoAssembler to compile GEOS-MegaPatch because the files have to be compiled in a certain order.
The AutoAssembler macros use GEOS MegaPatch system calls, so the AutoAssembler files can only be used under an already installed GEOS MegaPatch.
* ass.MP64 / 128.s Compiles the AutoAssembler control files
* ass.MP64 / 128_1.s Kernal compile and pack
* ass.MP64 / 128_2.s compile disk drivers and programs
* ass.MP64 / 128_DSK.s Compile disk drivers only
* ass.MP64 / 128_PRG.s Compile programs only

* ass.MP64 / 128_1 Stage1: Creating Kernal. The program will finished and the Kernal packed.
* ass.MP64 / 128_2 Stage2: Compile disk drivers and Programs.




### Preparations:
To compile GEOS MegaPatch using Scenario # 1, the source code files must be distributed to the two system drives as follows:

##### Drive # 10:
Includes DeskTop, geoWrite, MegaAssembler and printer drivers if required.
In addition, all files of the disc 'mp_d1_symbol' should be copied to this drive.
This drive should be defined as an AutoAssembler and ProgramCode drive.

##### Drive # 11:
ATTENTION: TopDesk can not copy more than 255 files to a drive. A solution is possible with geoDOS or DualTop. Both programs also work in 40Z mode under GEOS128.
The contents of the disks 'mp-d2-kernal', 'mp-d3-system', 'mp-d4-disk' and 'mp-d5-prohram' should be copied to this drive.
In MegaAssembler set this drive as 'source text' drive.




### Compile:
Start MegaAssembler and select 'MP64 / 128_1' in AutoAssembler mode. The kernal is compiled and packed. Then the return to the desktop takes place.
After returning to the desktop, restart MegaAssembler and compile 'MP64 / 128_2'. All necessary system files are generated now.




### MakeInstall:
To create the MegaPatch installation files, the background images must first be copied to the destination drive:
* MegaScreen.pic: C64 / C128
* BOOTMP64.PIC: C64
* BOOTMP128.PIC: C128
Start the file 'MakeInstall_64 / 128'. The required system files will be merged and compressed.




### StartMP:
For installation, the following files are required on the target computer:
* StartMP64 / 128
* StartupMP64 / 128.1
* StartMP64 / 128.2
* StartMP64 / 128.3
* StartMP64 / 128.4
* StartMP64 / 128.5




### Manual installation of GEOS-MegaPatch.
See README file below for a list of files and the correct build order...


.
.
.
.


# GEOS-MegaPatch build order.
```

if COMP_SYS = TRUE_C64
;--- Maustreiber.
                        b $f0,"s.SMouse64",$00
endif

if COMP_SYS = TRUE_C128
;--- Maustreiber.
                        b $f0,"s.SMouse128",$00
endif

if COMP_SYS = TRUE_C64
;--- Kernal
                        b $f0,"src.BuildID.Rev",$00     ;Build-ID/Revision
                        b $f0,"src.GEOS_MP3.64",$00     ;Kernel
                        b $f0,"src.MakeKernal",$00      ;Kernel-Packer
endif

if COMP_SYS = TRUE_C128
;--- Kernal
                        b $f0,"src.BuildID.Rev",$00     ;Build-ID/Revision
                        b $f0,"src.GEOS_MP3.128",$00    ;Kernel Bank1
                        b $f0,"src.G3_RBasic128",$00    ;Externe ToBasic-Routine Bank0
                        b $f0,"src.G3_B0_128",$00       ;Kernel Bank0
                        b $f0,"src.MakeKernal",$00      ;Kernel-Packer
endif

if COMP_SYS = TRUE_C64
;--- Joysticktreiber.
                        b $f0,"s.SStick64.1",$00
                        b $f0,"s.SStick64.2",$00
endif

if COMP_SYS = TRUE_C128
;--- Joysticktreiber.
                        b $f0,"s.SStick128.1",$00
                        b $f0,"s.SStick128.2",$00
endif

;--- MegaPatch Kernal packen.


;--- Laufwerkstreiber.
                        b $f0,"s.1541_Turbo",$00
                        b $f0,"s.1571_Turbo",$00
                        b $f0,"s.1581_Turbo",$00
                        b $f0,"s.DOS_Turbo",$00
                        b $f0,"s.PP_Turbo",$00

                        b $f0,"s.1541",$00
                        b $f0,"s.1571",$00
                        b $f0,"s.1581",$00
                        b $f0,"s.RAM41",$00
                        b $f0,"s.RAM71",$00
                        b $f0,"s.RAM81",$00
                        b $f0,"s.RAMNM",$00
                        b $f0,"s.RAMNM_SCPU",$00
                        b $f0,"s.FD41",$00
                        b $f0,"s.FD71",$00
                        b $f0,"s.FD81",$00
                        b $f0,"s.FDNM",$00
                        b $f0,"s.PCDOS",$00
                        b $f0,"s.PCDOS_EXT",$00
                        b $f0,"s.HD41",$00
                        b $f0,"s.HD71",$00
                        b $f0,"s.HD81",$00
                        b $f0,"s.HDNM",$00
                        b $f0,"s.HD41_PP",$00
                        b $f0,"s.HD71_PP",$00
                        b $f0,"s.HD81_PP",$00
                        b $f0,"s.HDNM_PP",$00
                        b $f0,"s.RL41",$00
                        b $f0,"s.RL71",$00
                        b $f0,"s.RL81",$00
                        b $f0,"s.RLNM",$00

                        b $f0,"s.MP.DiskTypes",$00
                        b $f0,"s.INIT 1541",$00
                        b $f0,"s.INIT 1571",$00
                        b $f0,"s.INIT 81FD",$00
                        b $f0,"s.INIT PCDOS",$00
                        b $f0,"s.INIT HD41",$00
                        b $f0,"s.INIT HD71",$00
                        b $f0,"s.INIT HD81",$00
                        b $f0,"s.INIT HDNM",$00
                        b $f0,"s.INIT RAM41",$00
                        b $f0,"s.INIT RAM71",$00
                        b $f0,"s.INIT RAM81",$00
                        b $f0,"s.INIT RAMNM",$00
                        b $f0,"s.INIT SRAMNM",$00
                        b $f0,"s.INIT RL",$00

;Treiberabhängig ist auch das TurboDOS-
;Modul zu kompilieren!
;                       b $f0,"s.1541_Turbo",$00
;                       b $f0,"s.1541",$00
;                       b $f0,"s.1571_Turbo",$00
;                       b $f0,"s.1571",$00

;TurboDOS 1581 für 1581 und CMD FD/HD
                        b $f0,"s.1581_Turbo",$00
                        b $f0,"s.1581",$00
;                       b $f0,"s.FD41",$00
;                       b $f0,"s.FD71",$00
;                       b $f0,"s.FD81",$00
;                       b $f0,"s.FDNM",$00
;CMD-HD-Kabel wird nur innerhalb GEOS unterstützt.
;Beim Boot-Vorgang wird TurboDOS verwendet.
;                       b $f0,"s.HD41",$00
;                       b $f0,"s.HD71",$00
;                       b $f0,"s.HD81",$00
;                       b $f0,"s.HDNM",$00

;RamLink benötigt kein TurboDOS.
;                       b $f0,"s.RL41",$00
;                       b $f0,"s.RL71",$00
;                       b $f0,"s.RL81",$00
;                       b $f0,"s.RLNM",$00

;--- Programme/Externes Kernel.
                        b $f0,"e.Register",$00
                        b $f0,"e.EnterDeskTop",$00
                        b $f0,"e.NewToBasic",$00
                        b $f0,"e.NewPanicBox",$00
                        b $f0,"e.GetNextDay",$00
                        b $f0,"e.DoAlarm",$00
                        b $f0,"e.GetFiles",$00
                        b $f0,"e.GetFiles_Data",$00
                        b $f0,"e.GetFiles_Menu",$00
                        b $f0,"e.DB_LdSvScreen",$00
                        b $f0,"e.TaskMan",$00
                        b $f0,"e.SpoolPrinter",$00
                        b $f0,"e.SpoolMenu",$00
                        b $f0,"e.SS_Starfield",$00
                        b $f0,"e.SS_PuzzleIt!",$00
if COMP_SYS = TRUE_C64
                        b $f0,"e.SS_Raster",$00
                        b $f0,"e.SS_PacMan",$00
                        b $f0,"o.SS_64erMove",$00
                        b $f0,"e.SS_64erMove",$00
endif
                        b $f0,"e.ScreenSaver",$00
                        b $f0,"e.GetBackScrn",$00

;--- Patches.
                        b $f0,"o.Patch_SRAM",$00        ;SCPU-Patch $D200
                        b $f0,"o.Patch_SCPU",$00

;--- RAM-Gerätetreiber.
                        b $f0,"o.DvRAM_SCPU",$00
                        b $f0,"o.DvRAM_REU",$00
                        b $f0,"o.DvRAM_RL",$00
                        b $f0,"o.DvRAM_BBG.1",$00
                        b $f0,"o.DvRAM_BBG.2",$00

;--- GEOS.Editor.
                        b $f0,"s.MP3.Edit.1",$00
                        b $f0,"s.MP3.Edit.2",$00

if COMP_SYS = TRUE_C64
::1                     b "GEOS64.Editor",$00
::2                     b $f5
                        b $f0,"lnk.GEOS64.Edit",$00
                        b $f4
endif

if COMP_SYS = TRUE_C128
::1                     b "GEOS128.Editor",$00
::2                     b $f5
                        b $f0,"lnk.GEOS128.Edit",$00
                        b $f4
endif

if COMP_SYS = TRUE_C64
;--- REBOOT-Funktionen.
                        b $f0,"o.ReBoot.SCPU",$00
                        b $f0,"o.ReBoot.RL",$00
                        b $f0,"o.ReBoot.REU",$00
                        b $f0,"o.ReBoot.BBG",$00

;--- Bootprogramme.
                        b $f0,"s.GEOS64",$00
                        b $f0,"s.GEOS64.RESET",$00
                        b $f0,"s.GEOS64.1",$00
                        b $f0,"s.GEOS64.2",$00
                        b $f0,"s.GEOS64.3",$00
                        b $f0,"o.AUTO.BOOT64",$00
                        b $f0,"s.GEOS64.BOOT",$00
                        b $f0,"s.RBOOT64",$00
                        b $f0,"s.RBOOT64.BOOT",$00

;--- Installationsprogramme.
                        b $f0,"s.GEOS64.TaskMse",$00
                        b $f0,"s.GEOS64.MKBT",$00
                        b $f0,"o.Update2MP3",$00
                        b $f0,"s.GEOS64.MP3",$00
                        b $f0,"s.MInstall_64",$00
                        b $f0,"s.StartMP3_64",$00

;--- Mauszeiger.
                        b  $f0,"s.NewMouse64",$00

endif

if COMP_SYS = TRUE_C128
;--- REBOOT-Funktionen.
                        b $f0,"o.ReBoot128.SCPU",$00
                        b $f0,"o.ReBoot128.RL",$00
                        b $f0,"o.ReBoot128.REU",$00
                        b $f0,"o.ReBoot128.BBG",$00

;--- Bootprogramme.
                        b $f0,"s.GEOS128",$00
                        b $f0,"s.GEOS128.RESET",$00
                        b $f0,"s.GEOS128.0",$00
                        b $f0,"s.GEOS128.1",$00
                        b $f0,"s.GEOS128.2",$00
                        b $f0,"s.GEOS128.3",$00
                        b $f0,"o.AUTO.BOOT128",$00
                        b $f0,"s.GEOS128.BOOT",$00
                        b $f0,"s.RBOOT128",$00
                        b $f0,"s.RBOOT128.BOOT",$00

;--- Installationsprogramme.
                        b $f0,"s.GEOS128.TaskMs",$00
                        b $f0,"s.GEOS128.MKBT",$00
                        b $f0,"o.Update2MP3",$00
                        b $f0,"s.GEOS128.MP3",$00
                        b $f0,"s.MInstall_128",$00
                        b $f0,"s.StartMP3_128",$00

;--- Mauszeiger.
                        b  $f0,"s.NewMouse128",$00

endif
