# Area6510

### geoWiC64ntp
The goal of this project is set the GEOS system date and time using the WiC64 and a NTP server. Requires a Commodore64 with WiC64 running GEOS/MegaPatch64 or GDOS64.

If no valid date and time is received the program will set the timezone to "00" = Greenwich mean time.
To set a specific timezone edit the GEOS infoblock and edit "TZNxx" on top of the info text while xx is a two-digit-number from 00 to 31.

Available timezones (from www.wic64.de):

* 00 GMT GMT+00:00 Greenwich Mean Time
* 01 UTC GMT+00:00 Universal Coordinated Time
* 02 ECT GMT+01:00 European Central Time
* 03 EET GMT+02:00 Eastern European Time
* 04 ART GMT+02:00 (Arabic) Egypt Standard Time
* 05 EAT GMT+03:00 Eastern African Time
* 06 MET GMT+03:30 Middle East Time
* 07 NET GMT+04:00 Near East Time
* 08 PLT GMT+05:00 Pakistan Lahore Time
* 09 IST GMT+05:30 India Standard Time
* 10 BST GMT+06:00 Bangladesh Standard Time
* 11 VST GMT+07:00 Vietnam Standard Time
* 12 CTT GMT+08:00 China Taiwan Time
* 13 JST GMT+09:00 Japan Standard Time
* 14 ACT GMT+09:30 Australia Central Time
* 15 AET GMT+10:00 Australia Eastern Time
* 16 SST GMT+11:00 Solomon Standard Time
* 17 NST GMT+12:00 New Zealand Standard Time
* 18 MIT GMT-11:00 Midway Islands Time
* 19 HST GMT-10:00 Hawaii Standard Time
* 20 AST GMT-09:00 Alaska Standard Time
* 21 PST GMT-08:00 Pacific Standard Time
* 22 PNT GMT-07:00 Phoenix Standard Time
* 23 MST GMT-07:00 Mountain Standard Time
* 24 CST GMT-06:00 Central Standard Time
* 25 EST GMT-05:00 Eastern Standard Time
* 26 IET GMT-05:00 Indiana Eastern Standard Time
* 27 PRT GMT-04:00 Puerto Rico US Virg. Isl. Time
* 28 CNT GMT-03:30 Canada Newfoundland Time
* 29 AGT GMT-03:00 Argentina Standard Time
* 30 BET GMT-03:00 Brazil Eastern Time
* 31 CAT GMT-01:00 Central African Time
