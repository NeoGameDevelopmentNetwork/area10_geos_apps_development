# Area6510

### geoKeysFix
This is a small utility to fix a problem with geoKeys when using GEOS/MegaPatch 64/128.
Tested with geokeys v1.5.

#### Description
When using geoKeys with GEOS/MegaPatch a problem appears if you are using your mouse when a register menu is active and your are editing a text string.
The mouse click should send "RETURN" to the keyboard buffer. With the geokeys keyboard driver this will cause screen garbage or a crash.

#### Install
Copy geoKeysFixMP3 to your boot disk after InstallKeys. On reboot the fix will be applied if the geoKeys keyboard driver is installed.
If the keyboard driver is not installed nothing will be changed. If the driver is not compatible with geoKeysFixMP3 the MegaPatch function ":PutKeyinBuffer" will be disabled.
