; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

geoCham64RTC
Read RTC from Chameleon64 and update GEOS date/time.
(Since V1.2 Ultimate64/II(+) is also supported)

Version 1.4
Released: 2021/02/07

This application can be used as AUTO_EXEC file or as an APPLICATION. Simply copy the file to your boot disk and it will be executed when GEOS will be started. You can also start this file as an application from your desktop.
If no Chameleon64 was detected, the file will either exit without any message during GEOS startup or it will display a short error message when started as application.

ChangeLog:
2021/02/07 - V1.4
-	Added english version.
-	Added hint for Ultimate 64/II(+) users on how to enable the command interface.

2019/02/15 - V1.3
-	Cleanup source code.

2019/02/14 - V1.2
-	Added code to read RTC from Ultimate64/II(+) also. This is done by a second version of geoCham64RTC:
	geoCham64RTC	is for Chameleon64 only.
	geoCham64RTC+	is for Chameleon64 and Ultimate64/II(+).
	For the Ultimate you need to enable the control registers. With the '+'-version you can have a bootdisk which can be used on the Chameleon64 and the Ultimate and it will read the RTC from any of these modules.

2019/02/13 - V1.1
-	BUG: Do not display an error message during startup if no Chameleon64 was detected.
-	Added a GEOS file icon.
-	Cleanup source code.

2019/02/11 - V1.0
-	Initial release.
