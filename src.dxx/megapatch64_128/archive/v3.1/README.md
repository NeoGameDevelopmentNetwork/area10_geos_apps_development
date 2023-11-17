# Area6510

# GEOS MEGAPATCH 64/128 [GERMAN]
For english translation please scroll down...


### Systemvoraussetzungen:

Um den MegaPatch-Quelltext zu kompilieren wird der MegaAssembler V3.9 benötigt. Sofern die einzelnen Quelltext-Dateien manuell kompiliert werden sollen, ist die Version V3.8 ausreichend.
Aktuell wurde MegaPatch nur auf einem bereits installiertem MegaPatch-System kompiliert. Auf einem reinem GEOS2-System müssen die Dateien manuell kompiliert werden da die AutoAssembler-Dateien bereits MegaPatch-Systemroutinen verwenden (CMD-Partitionswechsel).

### Bekannte Probleme:
* Wird GEOS-MegaPatch auf einem C64/C128 installiert und direkt nach der Installation nach BASIC verlassen, dann funktioniert RBOOT nicht korrekt.
* Wird GEOS-MegaPatch direkt nach der Installation über RBOOT neu gestartet wird der Hintergrund-Bildschirm in TopDesk nicht angezeigt. GEOS muss mindestens einmal beendet und neu gestartet werden.
* Wird GEOS-MegaPatch in der Sprache 'Englisch' kompiliert und mit einem deutschem TopDesk V4.x gestartet, dann führt dies zu einem Systemabsturz.
* GEOS-MegaPatch64/128.rev2 beinhaltet keinen Desktop, die Version von TopDesk aus dem Jahr 2000 bzw. 2003 funktioniert aber weiterhin.


### Fehlerbeseitigungen:
##### Programme / GEOS.Editor:
Im GEOS.Editor beim laden des Bildschirmschoners nur das "Initialize"-Bit setzen da sonst das On/Off-Bit überschrieben und der Bildschirmschoner immer aktiviert wird.
Gleiches beim setzen der Verzögerung: Auch hier nur das "Initialize"-Bit (ora #%0100000) setzen sonst wird der Bildschirmschonner immer neu aktiviert.
Hinweis: Bei deaktivierten Bildschirmschoner kann dieser im Editor derzeit nicht getestet werden.
Wenn ein Bildschirmschoner bei der Initialisierung einen Fehler zurückmeldet, dann wird der Bildschirmschoner jetzt deaktiviert.
Die Funktion "C=REU für schnellen Speichertransfer"/MOVE_DATA wird jetzt korrekt gespeichert.

##### Kernal / FollowChain:
Die Routine erzeugt keine gültige Sektortabelle in (:r3) wenn die Routine mit $00/AnzahlBytes in r1L/r1H (die ersten Bytes im letzten Datensektor einer Datei) aufgerufen wird. Zum Ende wird in r1L/r1H die ersten Bytes des letzten Sektors ($00/AnzahlBytes) übergeben.

##### Disk / 1541:
Bei der deinstallation eines 1541/Cache Laufwerks wird eine falsche Anzahl an 64K-Speicherbänken freigegeben was zu einem Systemabsturz führen kann.

##### Kernal / ChkDkGEOS:
Das ZERO-Flag muss am Ende gesetzt werden da einige Routinen direkt mittels BEQ verzweigen wenn es keine GEOS-Diskette ist.

##### Kernal / GetBorderBlock:
Zur Sicherheit nach der Prüfung auf eine GEOS-Diskette das Flag :isGEOS laden. Nur mittels BEQ zu verzweigen könnte bei unveränderter ChkDkGEOS-Routine zu falschen Ergebnissen führen.

##### System / 64erMove:
Der Bildschirmschoner benötigt mind. eine 64K Speicherbank in der REU. Fehlermeldung anzeigen wenn keine freie Bank verfügbar ist.
Bei aktivierter MOVE_DATA-Routine kein Systemabsturz mehr.

##### Sonstiges:
Fehlende Routinen für den C128 wurden der Version 2003 entnommen und im Quellcode rekonstruiert. Ein großer Teil der Änderung bezieht sich auf die Verwendung des Registers: MMU anstelle von: CPU_DATA.




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
Wenn die temporären Objectdateien oder die externen Symboltabellen nicht mehr benötigt werden kann man die Datei 'ass.Options' anpassen.
Die Datei 'src.SetLanuage' beinhaltet die Definition der Landessprache.
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


### System requirements:

To compile the MegaPatch source code the MegaAssembler V3.9 is needed. If the individual source text files are to be compiled manually, version V3.8 is sufficient.
Currently MegaPatch has been compiled on an already installed MegaPatch system. On a pure GEOS2 system, the files must be compiled manually because the AutoAssembler files already use MegaPatch system routines (CMD partition switch).

### Known problems:
* If GEOS MegaPatch is installed on a C64 / C128 and left directly after installation to BASIC, RBOOT will not work properly.
* If GEOS-MegaPatch is restarted via RBOOT directly after installation, the background screen will not be displayed in TopDesk. GEOS must be stopped and restarted at least once.
* If GEOS-MegaPatch is compiled in the language 'English' and started with a German TopDesk V4.x, this leads to a system crash.
* GEOS-MegaPatch64 / 128.rev2 does not include a desktop, but the version of TopDesk from 2000 or 2003 still works.


### Bugfixes:
##### Programs / GEOS.Editor:
In the GEOS.Editor, when loading the screen saver, only set the "Initialize" bit otherwise the on / off bit will be overwritten and the screen saver will always be activated.
Same thing when setting the delay: Again, only the "Initialize" bit (ora #% 0100000) set otherwise the screen saver is always reactivated.
Note: If the screen saver is disabled, it can not be tested in the editor at this time.
If a screen saver reports an error during initialization, the screen saver is now deactivated.
The function "C=REU for fast memory transfer" / MOVE_DATA is now stored correctly.

##### Kernal / FollowChain:
The routine does not create a valid sector table in (: r3) if the routine is called with $ 00 / number bytes in r1L / r1H (the first bytes in the last data sector of a file). At the end, the first bytes of the last sector ($ 00 / number of bytes) are transferred in r1L / r1H.

##### Disk / 1541:
Uninstalling a 1541 / cache drive releases an incorrect number of 64K memory banks, which can lead to a system crash.

##### Kernal / ChkDkGEOS:
The ZERO flag must be set at the end because some routines branch directly using BEQ if it is not a GEOS diskette.

##### Kernal / GetBorderBlock:
For safety, check the flag: isGEOS after checking for a GEOS diskette. Branching only with BEQ could lead to wrong results if the ChkDkGEOS routine is unchanged.

##### System / 64erMove:
The screensaver needs at least a 64K memory bank in the REU. Show error message if no free bank is available.
If the MOVE_DATA routine is activated, there is no longer a system crash.

##### Miscellaneous:
Missing routines for the C128 were taken from version 2003 and have been reconstructed in the source code. Much of the change relates to using the register: MMU instead of: CPU_DATA.




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
If you do not need the temporary object files or external symbol tables you can edit 'ass.Options'.
The file 'src.SetLanuage' includes settings for the system language.
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
;--- Kernal- und Systemprogramme / Patches.
if COMP_SYS = TRUE_C64
	s.SMouse64
endif
if COMP_SYS = TRUE_C128
	s.SMouse128
endif
if COMP_SYS = TRUE_C64
	src.BuildID.Rev		;Build-ID/Revision
	src.GEOS_MP3.64		;Kernel
	src.MakeKernal		;Kernel-Packer
endif
if COMP_SYS = TRUE_C128
	src.BuildID.Rev		;Build-ID/Revision
	src.GEOS_MP3.128	;Kernel Bank1
	src.G3_RBasic128	;Externe ToBasic-Routine Bank0
	src.G3_B0_128		;Kernel Bank0
	src.MakeKernal		;Kernel-Packer
endif
if COMP_SYS = TRUE_C64
	s.SStick64.1
	s.SStick64.2
endif
if COMP_SYS = TRUE_C128
	s.SStick128.1
	s.SStick128.2
endif
	o.Patch_SRAM	;SCPU-Patch $D200
	o.Patch_SCPU
	o.DvRAM_SCPU
	o.DvRAM_REU
	o.DvRAM_RL
	o.DvRAM_BBG.1
	o.DvRAM_BBG.2

;An dieser Stelle ist das zuvor assemblierte Programm
;'MakeKernal' auszuführen um das gepackte Kernal-Image
;zu erstellen.

;--- Laufwerkstreiber.
	s.1541_Turbo
	s.1571_Turbo
	s.1581_Turbo
	s.DOS_Turbo
	s.PP_Turbo
	s.1541
	s.1571
	s.1581
	s.RAM41
	s.RAM71
	s.RAM81
	s.RAMNM
	s.RAMNM_SCPU
	s.FD41
	s.FD71
	s.FD81
	s.FDNM
	s.PCDOS
	s.PCDOS_EXT
	s.HD41
	s.HD71
	s.HD81
	s.HDNM
	s.HD41_PP
	s.HD71_PP
	s.HD81_PP
	s.HDNM_PP
	s.RL41
	s.RL71
	s.RL81
	s.RLNM
	s.Info.DTypes
	s.INIT 1541
	s.INIT 1571
	s.INIT 81FD
	s.INIT PCDOS
	s.INIT HD41
	s.INIT HD71
	s.INIT HD81
	s.INIT HDNM
	s.INIT RAM41
	s.INIT RAM71
	s.INIT RAM81
	s.INIT RAMNM
	s.INIT SRAMNM
	s.INIT RL

;--- Ausgelagerte Kernal-Funtkionen.
	e.Register
	e.EnterDeskTop
	e.NewToBasic
	e.NewPanicBox
	e.GetNextDay
	e.DoAlarm
	e.GetFiles
	e.GetFiles_Data
	e.GetFiles_Menu
	e.DB_LdSvScreen
	e.TaskMan
	e.SpoolPrinter
	e.SpoolMenu
	e.SS_Starfield
	e.SS_PuzzleIt!
if COMP_SYS = TRUE_C64
	e.SS_Raster
	e.SS_PacMan
	o.SS_64erMove
	e.SS_64erMove
endif
	e.ScreenSaver
	e.GetBackScrn

;--- Setup-Programme.
if COMP_SYS = TRUE_C64
	s.MInstall_64
	s.StartMP3_64
endif
if COMP_SYS = TRUE_C128
	s.MInstall_128
	s.StartMP3_128
endif

;--- MegaPatch-Start- und Systemprogramme.
;An dieser Stelle muss man den Laufwerkstreiber für
;die Boot-Datei erzeugen. Standard ist 1581.
;Wird MegaPatch später über das SETUP-Programm
;installiert, dann spielt der Treiber hier keine
;Rolle. Dieser wird später durch SETUP ersetzt.
;	s.1541_Turbo
;	s.1541
;	s.1571_Turbo
;	s.1571
	s.1581_Turbo
	s.1581
;	s.FD41
;	s.FD71
;	s.FD81
;	s.FDNM
;CMD-HD-Kabel wird nur innerhalb GEOS unterstützt.
;	s.HD41
;	s.HD71
;	s.HD81
;	s.HDNM
;	s.RL41
;	s.RL71
;	s.RL81
;	s.RLNM

	s.MP3.Edit.1
	s.MP3.Edit.2
if COMP_SYS = TRUE_C64
	o.ReBoot.SCPU
	o.ReBoot.RL
	o.ReBoot.REU
	o.ReBoot.BBG
	s.GEOS64
	s.GEOS64.RESET
	s.GEOS64.1
	s.GEOS64.2
	s.GEOS64.3
	o.AUTO.BOOT64
	s.GEOS64.BOOT
	s.RBOOT64
	s.RBOOT64.BOOT
	s.GEOS64.TaskMse
	s.GEOS64.MKBT
	o.Update2MP3
	s.GEOS64.MP3
	s.NewMouse64
endif
if COMP_SYS = TRUE_C128
	o.ReBoot128.SCPU
	o.ReBoot128.RL
	o.ReBoot128.REU
	o.ReBoot128.BBG
	s.GEOS128
	s.GEOS128.RESET
	s.GEOS128.0
	s.GEOS128.1
	s.GEOS128.2
	s.GEOS128.3
	o.AUTO.BOOT128
	s.GEOS128.BOOT
	s.RBOOT128
	s.RBOOT128.BOOT
	s.GEOS128.TaskMs
	s.GEOS128.MKBT
	o.Update2MP3
	s.GEOS128.MP3
	s.NewMouse128
endif
```
