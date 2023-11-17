# Area6510

### SCSI connect
SCSI-Connect is a small utility program for switching SCSI devices connected to CMD-HD devices such as IomegaZIP or MO drives.

#### History
The original version 1.5 of VCA WEST only supports the Commodore128.

Therefore the original version was disassembled with "Input-ReAss64" and converted with "GeoDOS64" into the GEOS-MegaAssembler format. The source code was provided with comments and labels and reassembled. The result was a 100% binary compatible copy of the original version 1.5. 

The code specific to the Commodore128 was removed and some kernel routines were adapted for use with the Commodore64. Also the screen layout had to be adapted, as the Commodore64 can only use 40 columns. 

Finally SCSI-Connect64 works on the Commodore64!

#### Requirements
The original version and SCSI-Connect64 both require the CMD-HD autostart utility called 'COPYRIGHT CMD 89' on the standard partition of every SCSI device (including the internal hard disk).
Also a BootROM V2.80 is required for the CMD-HD. With older versions of the BootROM this will definitely not work! The autostart utility checks the required ROM version. With older versions, calling routines of the autostart file causes all LEDs of the CMD-HD to start blinking.

#### Improvements
The CMD-HD autostart utility has been integrated into SCSI-Connect128+/64+ to avoid the need to have a copy of 'COPYRIGHT CMD 89' on every SCSI device on all standard partitions.
Although this seems to work, it is recommended that you use the CMD-HD autostart utility, as other applications may also need it.

#### SWITCH-SCSI-DEMO
This is a small BASIC utility that demonstrates how to use the autostart utility to switch SCSI devices.
