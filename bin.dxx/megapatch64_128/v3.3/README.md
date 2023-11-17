# Area6510

## GEOS MEGAPATCH 64/128
This directory contains current releases of GEOS MegaPatch.
German version : 'mp33-de.d81'
English version: 'mp33-en.d81'

## Changes
Read the ChangeLog online [**here**](https://bitbucket.org/mkgit64/area6510/src/master/src/megapatch64_128/current/doc/README-EN.txt)

#### Note
The current releases no longer contain TOPDESK anymore since TOPDESK does not belong to the GEOS MegaPatch core system.
TOPDESK released with MegaPatch from 2000/2003 can still be used. Same applies to the original DESKTOP from GEOS 2.x.

## REQUIREMENTS
- GEOS 64/128 V2.x or GEOS MegaPatch 64/128 V3.x
- A disk drive of type 1541/1571 (when install from a D64, you need a double-sided disk then) and a second drive as target or a single 1581 (when install from a D81) for source and target drive.
- Install on a RAM1541-drive is possible with at least 512K RAM (RAM1571 with 512K will not work, with 1Mb a RAM1581 should work too). A RAM1571 with 512K will be converted into a NativeMode RAMDisk.
- C=1351 compatible input device, joystick will work too. Use port #1.

If the target device has less then 300Kb free disk space you should use the custom setup and install only required system files and disk drivers.
Make sure you have a file called "DESK TOP" (C64) or "128 DESKTOP" (C128) on the boot drive. This can either be DESKTOP V2 or any TOPDESK version.

#### Note
Not all desktop applications do support all features of the MegaPatch disk drivers. The TOPDESK release from 2000/2003 has some known bugs (disk-copy, validate, especially on NativeMode).

## SUPPORTED DEVICES
C64/C64C (PAL/NTSC), C128/C128D, 1541/II, 1571, 1581, CMD FD2000, CMD F4000, CMD HD (incl. parallel cable), CMD RAMLink, CMD SuperCPU 64/128, SD2IEC (with recent firmware), C=1351, CMD SmartMouse, Joystick, C=REU, CMD REU XL, GeoRAM, BBGRAM, CMD RAMCard, 64Net (untested since year 2000/2003).

#### Note
SD2IEC will be detected as 1541/1571/1581 with the file based memory emulation (see SD2IEC manual -> "XR"-command). Device adress will be configured automatically except for the boot device.
For NativeMode you must configure the SD2IEC with the correct device adresse (i.e. drive D: = device #11). File based memory emulation is not needed for NativeMode.
