; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

geoWiC64ntp
Get date and time from NTP server and update GEOS date/time.

Version 0.1
Released: 2022/03/26

This application can be used as AUTO_EXEC file or as an APPLICATION. Simply copy the file to your boot disk and it will be executed when GEOS will be started. You can also start this file as an application from your desktop.
If no WiC64 was detected, the file will either exit without any message during GEOS startup or it will display a short error message when started as application.

You can set a specific timezone in the GEOS infoblock. To enable this feature the first the characters in the info text must be "TZN", followed by a two digit number 00-31. This will set the time zone when the application will be executed.

If the WiC64 will send a malformed date and time string, the program will set the default timezone to `00`.

Availeble timezones (from www.WiC64.de):

00	GMT	Greenwich Mean Time	GMT
01	UTC	Universal Coordinated Time	GMT
02	ECT	European Central Time	GMT+01:00
03	EET	Eastern European Time	GMT+02:00
04	ART	(Arabic) Egypt Standard Time	GMT+02:00
05	EAT	Eastern African Time	GMT+03:00
06	MET	Middle East Time	GMT+03:30
07	NET	Near East Time	GMT+04:00
08	PLT	Pakistan Lahore Time	GMT+05:00
09	IST	India Standard Time	GMT+05:30
10	BST	Bangladesh Standard Time	GMT+06:00
11	VST	Vietnam Standard Time	GMT+07:00
12	CTT	China Taiwan Time	GMT+08:00
13	JST	Japan Standard Time	GMT+09:00
14	ACT	Australia Central Time	GMT+09:30
15	AET	Australia Eastern Time	GMT+10:00
16	SST	Solomon Standard Time	GMT+11:00
17	NST	New Zealand Standard Time	GMT+12:00
18	MIT	Midway Islands Time	GMT-11:00
19	HST	Hawaii Standard Time	GMT-10:00
20	AST	Alaska Standard Time	GMT-09:00
21	PST	Pacific Standard Time	GMT-08:00
22	PNT	Phoenix Standard Time	GMT-07:00
23	MST	Mountain Standard Time	GMT-07:00
24	CST	Central Standard Time	GMT-06:00
25	EST	Eastern Standard Time	GMT-05:00
26	IET	Indiana Eastern Standard Time	GMT-05:00
27	PRT	Puerto Rico US Virg. Isl. Time	GMT-04:00
28	CNT	Canada Newfoundland Time	GMT-03:30
29	AGT	Argentina Standard Time	GMT-03:00
30	BET	Brazil Eastern Time	GMT-03:00
31	CAT	Central African Time	GMT-01:00

ChangeLog:
2022/03/26 - V0.1
-	Initial release.
