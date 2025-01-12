
Welcome to the GEOS update `GDOS64`
by Markus Kanet

WARNING:
SYSTEM IS STILL IN DEVELOPMENT!
UNDISCOVERED ERRORS MAY CAUSE DATA LOSS!
USE AT YOUR OWN RISK!

System requirements:
Commodore 64
512Kb RAM (C=REU, GeoRAM, RAMCard, RAMLink)
Commodore 1351 or compatible mouse

Recommended:
1024Kb RAM
CMD-SuperCPU or TurboChameleon64

Note: Ultimate64 with turbo firmware
is currently not supported!

Installation:
For installation it is recommended to copy the file "SETUPGD64EN"
to a RAM drive and start from there, because the analysis of the
setup data on physical drives can take a long time

Tips:
* Install on an empty disk:
  The installation requires about 440Kb of disk space.
* MakeBoot not required anymore:
  The startdisk should boot on all devices.
* Enable "Drivers-to-RAM":
  For easy switching drive mode SD2IEC+CMDRL/FD/HD drives.
* Start drivers from disk:
  GD.DISK.xxx files can be launched from the GeoDesk desktop.
  It is possible to create AppLinks on the desktop.

Notes:
* Tested on two different configurations:
  There can still a lot of errors included.
* Help system not yet complete:
  The included help files are just a demo.
* Booting GDOS64 from a C64 using a C=1571 disk drive:
  The C=1571 disk drive must be set to double-sided mode!
  OPEN 15,x,15,"U0>M1":CLOSE 15     :REM x = Device address

History:
1997: Reassembled GEOS source code
1999: Released GEOS MegaPatch
1999: Started to work on GeoDOS64-V3
2021: Merged changes from MegaPatch with GeoDOS64-V3
2022: Renamed GeoDOS64 V3 to GDOS64.

Date: 19.01.2023
