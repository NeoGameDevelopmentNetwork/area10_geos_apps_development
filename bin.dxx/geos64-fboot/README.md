# Area6510

### GEOS64-FBOOT
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
