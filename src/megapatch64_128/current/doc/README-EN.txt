; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

GEOS MEGAPATCH 64/128
Installationmanual - Date: 2023/01/19

This disk contains current releases of GEOS-MegaPatch.

The current releases no longer contain TOPDESK as desktop application anymore.
TOPDESK released with MegaPatch from 2000/2003 can still be used.
Same applies to the original DESKTOP from GEOS 2.x.

The file "USER-MANUAL-EN" includes a short manual for GEOS-MegaPatch.

REQUIREMENTS
- GEOS 64/128 V2.x or GEOS-MegaPatch 64/128 V3.x
- A disk drive of type 1541/1571 (when install from a D64, you need a double-sided disk then) and a second drive as target or a single 1581 (when install from a D81) for source and target drive.
- Install on a RAM1541-drive is possible with at least 512K RAM (RAM1571 with 512K will not work, with 1Mb a RAM1581 should work too). A RAM1571 with 512K will be converted into a NativeMode RAMDisk.
- C=1351 compatible input device, joystick will work too. Use port #1.
- C128 only: 64Kb VDC RAM required.

INSTALLATION
Start the file "SETUPMP_64" or "SETUPMP_128" and follow the instructions displayed on screen.
If the target disk has less then 300Kb free disk space you should use the custom setup and install only required system files and disk drivers.
Make sure you have a file called "DESK TOP" (C64) or "128 DESKTOP" (C128) on the boot drive. This can either be DESKTOP V2 or any TOPDESK version.

Not all desktop applications do support all features of the MegaPatch disk drivers. The TOPDESK release from 2000/2003 has some known bugs (disk-copy, validate, especially on NativeMode).

SUPPORTED HARDWARE:
C64/C64C (PAL/NTSC), C128/C128D, C64 Reloaded, 1541/II, 1571, 1581, CMD FD2000, CMD F4000, CMD HD (incl. parallel cable), CMD RAMLink, CMD SuperCPU 64/128, SD2IEC (with recent firmware), C=1351, CMD SmartMouse, Joystick, C=REU, CMD REU XL, GeoRAM, BBGRAM, CMD RAMCard, 64Net (untested since year 2000/2003). TurboChameleon64. Tom+/MicroMys-Adapter with USB/PS2-mouse.

UNSUPPORTED HARDWARE:
Ultimate64 with firmware > 1.29 Starting from this version the TurboMode is supported: MegaPatch may not install with certain settings.

C128 with less then 64Kb VDC RAM.

SD2IEC will be detected as 1541/1571/1581 with the file based memory emulation (see SD2IEC manual -> "XR"-command). Device adress will be configured automatically except for the boot device. You can use the 1541/1571/1581 disk driver.
For NativeMode you must configure the SD2IEC with the correct device adresse (i.e. drive D: = device #11) and use the "SD2IEC"-Driver. File based memory emulation is not needed for NativeMode.
Use the GEOS.Editor and the "Switch DiskImage/Partition" button on the "DRIVES" page (the lower arrow for each drive) to switch the disk images.
The current disk image can not be saved. On next boot the current disk image will stay active.

FIXED PROBLEMS
- Installation via GEOS.MP3 replaces multiple RAMNative drives with a single drive.
- The screen saver is reactivated each time you restart.
- The 1541 cache driver cannot be installed or uninstalled without errors and may free system memory which can lead to a crash.
- The ReBoot system is "Optional", but was detected as "missing system file" during the boot disk check: The installation cannot be continued.
- The scan of the system files of the startup diskette was faulty and was fixed.
- Incorrect color representation in the MegaPatch logo fixed.
- With the C128, different colors were used in the setup program for the author hint.
- Bug in color display with startup image "Megascreen.pic" fixed.
- Too long file name for the startup image overwrites the file name for the default printer.
- The faulty installation in 40character mode of the C128 was fixed.
- Incorrect color display in dialog boxes in the setup program in 80character mode of the C128 fixed.
- The option "Fast memory transfer for C=REU/MoveData" is no longer deactivated after each restart and is only enabled for a C=REU memory extension.
- The screensaver 64erMove now works together with C=REU and MoveData.
- 64erMove can now also be saved in the editor (wrong file name).
- In the GEOS.editor some settings were not updated if they are changed by other settings. This caused (X) options to be displayed as "Enabled" even though the option was disabled.
- GEOS.BOOT now starts the system clock, even if it was previously stopped outside GEOS.
- Immediate update of free/busy memory banks in GEOS when changes are made in the editor.
- System date is now set to 1.1.2018 by default if no RTC clock is found.
- When using a memory expansion with 16.384KByte the size was not recognized correctly. The error was fixed, but only 255x64KByte = 16.320JByte can be used.
- When using more than one setup diskette, the new diskette is now initialized after a diskette change and GEOS-internal system variables are updated to detect a faulty diskette change if necessary.
- When starting without a background image, the background color is now set to Standard in the 80 character mode of the C128. Necessary because 128DUALTOP does not delete the color memory at startup.
- The automatic recognition of an RTC to set the time leads to a system standstill if the parallel cable of the 1571 is installed.
- If GEOS.MP3 is started by GEOS128v2/DESKTOPv2 in 80Z mode, the DB_DblBit flag may not be set correctly. DialogBox icons are then not automatically doubled in width.
- Clear screen when leaving GEOS.MP3 otherwise GEOS128v2/DESKTOPv2 will be displayed with wrong colors.
- The X register must remain unchanged if ":MoveData" is used. At least TopDesk v4.1 has problems here if the X register is changed.
- In TaskManager128 reading the drive bytes from the REU via FetchRAM into the ZeroPage leads to an error ("The drive configuration was changed").
- When changing the current task TurboDOS is deactivated in all drives, otherwise VICE can crash on hardware drives (1541,71,81...) with a DISK-JAM.
- geoPaint crashes when moving the image section with REU-MoveData option enabled.
- geoPaint crashes when restoring a changed drawing.
- Problems with installation with distributed setup on 2x1541 disks fixed.
- Fixed a bug in the ToBASIC routine. The error prevented starting BASIC programs and executing BASIC commands when exiting GEOS.
- Fixed SuperMouse64 input driver to work with TurboChameleon64.
- The GEOS border block was created for 1541/1571 drives in the directory area, analogous to the 1581 format. Track/sektor for the border block changed according to GEOS v2.
- RAM41/71/81 are no longer automatically created as GEOS diskette (corresponds to NativeMode).
  NOTE: MegaPatch V3.3r5 and earlier will clear non-GEOS RAMDisk in 1541/71/81 format during boot!
- The FD71/HD71/RL71 disk drivers do not set the ":doubleSideFlg" correctly. Applications which evaluate the flag may only copy the "first side" of a corresponding partition.
- Fixed problems with dualTop128 (NewMoveData).
- C= sign was bad in the englisch MegaPatch128 release since MP3.0/2000.
- ":SetNextFree" allocates in some rare cases blocks reserved for the root directory on NativeMode drives for files. This causes the number of used blocks on disk to be displayed incorrectly.
- Unlike GEOS-V2 the routine DoRAMOp did not check for a valid bank.

FIXED PROBLEMS (Continued)
- GateWay displays a corrupted file icon at file info.
- DualTop128 inverted the previous or next directory entry when scrolling up or down using the up/down arrows. This happend because of the value in ":curPattern" was tested for $xxF0 which should be pattern#0. This value has been different for MP128 since the first release which caused the filename to be printed with REVON=inverted. Does not happen with DualTop64 (Test for $xx00).
- When using the TaskManager to open a document while the required application can not be found, a new invalid task will be created. When exiting the TaskManager MegaPatch may crash.
- PacMan screen saver did not remove the last pixel column after the sprites have changed the direction. Also the screen saver was running too fast when using a TurboChameleon64.
- The GetString routine did not work correct if ST_WR_BACK was set in dispBufferOn since all input was written into the back screen only.
- Fixed a problem with DoDlgBox in MegaPatch128. The flag DB_DblBit was not always set correctly and in case of a dialog box without a shadow it was never set. Because of this some system icons were placed wrong in the dialog box.
- Fixed a bug in the file selection box in MegaPatch128. The flag DB_DblBit was not set and this caused in some rare cases system icons to be displayed half in size.
- Fixed an issue in register menu for MegaPatch128: The size of the checkbox icon was always doubled in size, even if the option field was not defined using the double-bit. This caused the checkbox icon to be larger then the option field itself.
- Fixed a crash when open a geoWrite document from a NativeMode disk drive and select "Edit/Cut" from the geoWrite menu.

FIXED PROBLEMS IN TEST RELEASES 2018-2023
- MP3 cannot be installed on a C128 with RAMLink and SuperCPU (GEOS.Editor hangs or GEOS.MakeBoot crashes due to missing switch to 1MHz in the drive drivers to RAMDrive, RAMlink and CMDHD with parallel cable)
- The system start messages have been revised, including the author's notes.
- Mark StartMP_64 under GEOS128 as "Only executable under GEOS64".
- Clarification of the option C=REU-MoveData in the GEOS editor: This option is deactivated with a SuperCPU, because 16Bit-MoveData of the SuperCPU is used here.
- Clean up system startup messages for a clearer startup process.
- GEOS.Editor displays some icons with the wrong width under DESKTOP 2.x in 80character mode. This is because DESKTOP does not activate the DblBit.
- Installation error with SuperCPU/RAMCard as GEOS-DACC and GeoRAM-Native drive as setup drive (source and destination) fixed. GRAM_BANK_SIZE was not detected because SuperCPU/RAMCard=GEOS-DACC.
- RAM81 drives could not be used with RAMLink drives.
- Fixed a bug when using CMDHD+CMDRAMLink+parallelcable: When using NativeMode a wrong drive size will be displayed in the editor.
- Fixed a bug on MP128 when switching drive or partition on the device where the editor was started from.
- When updating GEOS MegaPatch to a newer version, the update crashes when using a GeoRAM-Native drive as target drive.
- Random system crashes using a TurboChameleon64 and the PCDOS disk driver: The disk driver will now enable the 1MHz-mode when accessing the disk drive.
- With the update from 26.12.2018 the SD2IEC detection routine for the 1541/71/81 disk drivers was changed, which leads to problems under MegaPatch128, e.g. system crash or pixel error in VDC screen mode/80 column mode..
- An SD2IEC without active "M-R" emulation was changed to a different drive adddress when installing a new drive. This leads to a system crash.
- In GEOS.Editor, a change in the seriel bus drive detection caused existing drives to be ignored.
- When trying to install GeoRAM-, CREU- or SuperRAM-Native twice the system will crash.
- The 1541-Shadow driver not not make use of the reserved RAM and does always access the diskette instead of reading data from the shadow RAM.
- When closing an active task, the TaskManager may hang in a endless loop when testing the mouse buttons if the mouse has been deactivated by the program or the kernal.
- geoPublish crashes during installation because of the 1541 disk driver does not include the required installation data anymore. Fixed with 3.3r10.
- Fixed a bug when adding a photo scrap to geoWrite documents on 1581/NativeMode disk drives.
- MegaPatch128/geoPaint128 may crash when switching the current task. This bug was introduced in 3.3r9 and could cause the system to crash if the current application is using a custom IRQ routine. This bug may also affect MegaPatch64, it depends on the current application code.
- Setup for MegaPatch/DE and MegaPatch/US used the same names for setup files.

IMPROVEMENTS
- The GEOS.editor has been enhanced with a progress indicator at system startup.
- In the GEOS128.BOOT file, the I/O area is now activated before accessing the registers starting at $Dxxx.
- In the GEOS.Editor the possibility to change and save the GEOS serial number has been added.
- Support of GeoRAM/C=REU with 16Mb. The size is displayed when the system is started. The memory extensions are still only supported up to 4Mb when used as GEOS-DACC.
- New drive drivers GeoRAM-Native/C=REU-Native. The drivers allow to use the unused memory of a GeoRAM/C=REU as RAM drive, similar to the SuperRAM driver.
- HD compatible NativeMode driver without parallel cable support for DNP support under SD2IEC (IECBus NativeMode). Replaced by the SD2IEC driver, but still available in source code.
- The extended memory is tested at startup, query the extended memory size at startup: If less than 192Kb return to BASIC.
- New SD2IEC driver: IECBus-NM only works with SD2IEC up to 8mb(127 tracks) due to TurboDOS limitations. The new SD2IEC avoids this problem with specific TurboDOS commands. Therefore the driver only works with SD2IEC.
- On SD2IEC/IECBusNM subdirectories are now possible.
- All drives are now checked for valid track/sector addresses when reading/writing sectors.
- Change in range 1581/NM drives: According to GEOS 2.x, the disc name for all drive types is displayed at byte $90 in the BAM sector. Applications that change the disc name from byte $04 in the BAM sector do not work anymore. Change corresponds to the behavior of GEOS 2.x!
- TaskManager128: When opening a new application, the screen flag is evaluated and activated according to the 40 or 80 character screen.
- In the GEOS.editor, the drive mode of the SD2IEC can now be changed between 1541/1571/1581 or SD2IEC/Native.
- Changing the DiskImages to SD2IEC is possible with the GEOS.Editor.
- Set mouse limits under MP128 when switching between 40/80 screen mode.
- CMD HD cable is now disabled by default.
- New option in GEOS.Editor "GeoCalc-Fix", see Register "PRINTER" (C64 only). If the current printer is  loaded from RAM or if the PrinterSpooler is active the size of a printer driver will be limited to be compatible with GeoCalc.
- MegaPatch/german only: Added new option "QWERTZ" to swap "Z" and "Y" on the keyboard.
- :RealDrvMode does now support SD2IEC: If bit #1 ist set, the current drive is a SD2IEC.
- Added new adresses for applications, see technical manual for details.
- In register menus it is now possible to set an option for BOX_ICON if the icon should flash or not when clicked by the user. Additionally in GEOS.Editor the system default can be enabled for older applications.
- New autostart application "GEOS.ColorEditor" to edit system colors and load the settings during boot.

KNOWN ISSUES
- The InfoBlock for GEOS.1 and GEOS.BOOT is lost during update/MakeBoot (GEOS SaveFile routine deletes InfoBlock).
- When using VICE switching a drive from a 1581 to 1571 leads to an unstable drive. If you access the drive the whole system will hang in an endless loop and you have to reset your computer.

COMMENTS
The following change was listed in the ChangeLog for the 2003 version:
> The kernel routines InitForIO and DoneWithIO have been changed so that
> is no longer switched back to 1Mhz when accessing Ram drives.

This is only partially correct:
The routines InitForIO and DoneWithIO no longer change the CLKRATE register at $D030. The RAM routines for the C=REU on the other hand still set the register to 1MHz. A comment suggests that this is necessary for the C=REU chip.

The 2003 version is able to recognize PC64 as emulator. With the emulator VICE there is no possibility if you don't switch on additional registers which make this possible.

TopDesk64/128 and GeoDOS use their own routines to exit after BASIC. Here a "cold start" is executed which releases the whole memory of the SuperCPU with RAMCard.
DualTop uses the GEOS routine "ToBASIC" in conformity with the system. This routine only performs a "warm start", the memory reserved by MegaPatch for the SuperCPU remains marked as "Reserved" and is available for a quick restart even after other programs have been used.
Note: Programs that do not respect the memory management of the SuperCPU can overwrite the memory of the SuperCPU and thus the system memory of MegaPatch.
If you want to free the whole memory of the SuperCPU/RAMCard it is sufficient to run a 'SYS64738' or switch the C64 off and on again.

TopDeskV4 displays the 1581 icon for the new (unknown) drives GeoRAM-Native, C=REU-Native or IECBus-Native. This should be fixed with TopDeskV5.

Under VICE/x128 a wrong SETUP can lead to the fact that MegaPatch cannot be installed under GEOS 2.x (system hangs after unpacking the files). VICE should only be used with default settings and without WARP mode! Whis might be related to the "Switch-drive" issue (see known Problems).

The autostart file 'RUN_DUALTOP' starts the DeskTop application 'DUAL_TOP' automatically at system start. The disadvantage of the startup program is that the first printer and mouse driver is also installed on disk, no matter which driver is set in GEOS.Editor.

geoCalc64 crashes when using printer spooler or "printer driver in RAM" when printing a file. The problem is due to geoCalc itself using a memory area reserved for the printer drivers (address $7F3F, call from geoCalc starting from $5569). See "GeoCalc-Fix" included in the GEOS.Editor.

With V3.3r7 there are now TurboDOS-free disk drivers available. These will be really slow but can be easily modified for new devices that do not support any kind of floppy speeder.

MEGAPATCH 64/128 * 1998-2023
Markus Kanet
