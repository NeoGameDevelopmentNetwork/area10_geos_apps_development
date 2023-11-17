; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

# Area6510

#### For english translation, please scroll down!

## GEOS64-FBOOT
GEOS64-FBOOT, oder kurz "FBOOT", ist ein Programm um GEOS oder GEOS/MP3 etwas schneller zu starten.

"FBOOT" funktioniert ähnlich wie "RBOOT", welches den GEOS-Kernal aus einer vorhandenen Speichererweiterung (REU) lädt und das GEOS-System initialisiert. Damit "FBOOT" funktioniert, muss GEOS mindestens einmal normal gestartet worden sein. Im "CONFIGURE"-Programm von GEOS 2.x muss dazu die Option "Neustarten des RAM" oder "RAM Reboot" aktiviert sein. In GEOS/MP3 ist diese Option automatisch gesetzt.

Im Gegensatz zu "RBOOT" führt "FBOOT" nach dem laden des GEOS-Kernals auch Autostart-Programme von einem vorgegebenen Laufwerk aus. Das kann dann auch ein RAM-Laufwerk sein, das dann auch die Datei "DESK TOP" enthält.

Das Programm ist für den Einsatz einer NeoRAM gedacht, welche den Inhalt der Speichererweiterung (REU) über eine Batterie sichert.
Das Programm kann auch mit einem TurboChameleon64, einer UltimateII+ oder einem Ultimate64 verwendet werden. Diese Geräte können den Inhalt einer emulierten Speichererweiterung auf USB/SD-Karte speichern und nach einem Neustart wieder einladen.
Zusätzlich kann "FBOOT" dann von USB/SD-Karte gestartet werden, was dann den Einsatz von physischen Diskettenlaufwerken zum starten von GEOS hinfällig macht.

#### Inhalt des RAM-Laufwerks unter GEOS 2.x:
* DESK TOP
* Drucker-/Eingabetreiber
* Autostart-Programme

"CONFIGURE" (oder die deutsche Version "KONFIGURIEREN") darf nicht auf die RAM-Disk kopiert werden, da dieses Programm den Inhalt von RAM-Laufwerken beim Neustart löscht.

#### Inhalt des RAM-Laufwerks unter GEOS/MP3:
* GEOS64.Editor
* GEOS64.Disk
* DESK TOP
* Drucker-/Eingabetreiber
* Hintergrundbild
* Autostart-Programme

Im Gegensatz zu GEOS 2.x muss hier der GEOS64.Editor mit auf das RAM-Laufwerk, da der Editor das System konfiguriert. Der Inhalt von RAM-Laufwerken wird dabei nur dann gelöscht, wenn das Verzeichnis ungültig ist. Daher müssen die RAM-Laufwerke unter GEOS/MP3 in einer bestimmten Reihenfolge eingerichtet werden:
Dazu den GEOS64.Editor starten und zuerst auf der Registerkarte "SPEICHER" prüfen, ob am Anfang der Speicherbelegung (linke obere Ecke) max. ein GEOS-Block reserviert(rot) ist. Falls dem nicht so ist, haben evtl. andere GEOS-Programme hier Speicher reserviert (z.B. TopDesk mit der Option "RAMTopDesk"). Diese Programme müssen deaktiviert werden.
Dann alle RAM-Laufwerke deinstallieren und der Reihe nach von Laufwerk A: bis D: aufsteigend erneut einrichten. ACHTUNG! Dabei geht dann in der Regel der Inhalt verloren!
Danach die oben aufgeführten Dateien auf das RAM-Laufwerk kopieren, von dort dann den GEOS.Editor starten und jetzt die Konfiguration speichern.

Damit sind die RAM-Laufwerke für den schnellen Start mit "FBOOT" vorbereitet.
Um GEOS nun schneller zu starten, "FBOOT" passend zur verwendeten Speichererweiterung laden:

**LOAD"FBOOT64-CREU",8,1**  oder   **LOAD"FBOOT64-GRAM",8,1**

Standardmäß�ig setzt "FBOOT" den GEOS-Bootvorgang von dem Laufwerk unter GEOS fort, von dem es unter BASIC aus geladen wurde. Im Beispiel oben von Laufwerk 8: oder A:.
Wenn der Bootvorgang von einem anderen Laufwerk vortgesetzt werden soll, muss das "FBOOT" mitgeteilt werden. Nach dem Laden des Programms folgendes eingeben:

**POKE 2064,x**
X muss dabei durch eine Zahl von 8 bis 11 ersetzt werden und entspricht dem GEOS-Laufwerk A: bis D:.
Nach der Anpassung kann das Programm auch wieder gespeichert werden, damit diese Vorgabe dauerhaft erhalten bleibt.

**SAVE"FBOOT64-CREU-9",8,1**

Der Name kann frei gewählt werden, die Erweiterung "-9" zeigt nur an, das diese Version GEOS von Laufwerk B: startet.

## ENGLISH TRANSLATION

## GEOS64-FBOOT

GEOS64-FBOOT, or "FBOOT" for short, is a program to boot GEOS or GEOS/MP3 a little faster.

"FBOOT" works similar to "RBOOT", which loads the GEOS kernal from an existing ram expansion unit (REU) and initializes the GEOS system. For "FBOOT" to work, GEOS must have been started normally at least once. In the "CONFIGURE" program of GEOS 2.x the option "Restart RAM" or "RAM Reboot" must be activated for this. In GEOS/MP3 this option is set automatically.

In contrast to "RBOOT", "FBOOT" also executes autostart programs from a specified drive after loading the GEOS kernal. This can be a RAM drive, which contains at least the file "DESK TOP".

The program is intended for the use of a NeoRAM, which saves the contents of the ram expansion unit via a battery.
The program can also be used with a TurboChameleon64, an UltimateII+ or an Ultimate64. These devices can save the contents of an emulated ram memory expansion to USB/SD card and load it again after a reboot.
In addition, "FBOOT" can then be booted from USB/SD card, which then makes the use of physical floppy drives to boot GEOS obsolete.

#### RAM drive contents under GEOS 2.x:
* DESK TOP
* printer / input driver
* autostart programs

"CONFIGURE" (or the German version "KONFIGURIEREN") must not be copied to the RAM disk, because this program deletes the contents of RAM drives on restart.

#### RAM drive contents under GEOS/MP3:
* GEOS64.Editor
* GEOS64.Disk
* DESK TOP
* printer / input driver
* background image
* autostart programs

In contrast to GEOS 2.x the GEOS64.Editor must be included on the RAM drive, because the editor configures the system. RAM drives are only deleted if the directory is invalid.
Therefore the RAM drives must be configured in a certain order when using GEOS/MP3:
To do this, start the GEOS64.Editor and first check on the "MEMORY" tab if there is max. one GEOS block reserved(red) at the beginning of the memory allocation table (upper left corner).
If this is not the case, other GEOS programs may have reserved memory here (e.g. TopDesk with the option "RAMTopDesk"). These programs must be deactivated.
Then uninstall all RAM drives and set them up again in ascending order from drive A: to D:. ATTENTION: In this case the content will be lost!
Then copy the files listed above to the RAM drive, then start the GEOS.Editor from there and now save the configuration.

Now the RAM drives are prepared for the fast start with "FBOOT".
To start GEOS faster now, load "FBOOT" according to the used ram expansion unit:

**LOAD"FBOOT64-CREU",8,1**  or  **LOAD"FBOOT64-GRAM",8,1**

By default, "FBOOT" continues the GEOS boot process from the drive under GEOS, from which it was loaded under BASIC. In the example above from drive 8: or A:.
If you want to continue the boot process from another drive, you have to tell "FBOOT" which drive to use. After loading the program enter the following:

**POKE 2064,x**

X must be replaced by a number from 8 to 11 and corresponds to the GEOS drive A: to D:. After the adjustment the program can also be saved again, so that this default is permanently saved.

**SAVE"FBOOT64-CREU-9",8,1**

The name can be freely chosen, the extension "-9" only indicates that this version starts GEOS from drive B:.
