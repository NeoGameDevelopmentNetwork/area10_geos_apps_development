; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;

geoSD2RTC
Read RTC from SD2IEC and update GEOS date/time.
(requires GEOS/MegaPatch)

Version 1.3
Released: 2024/02/22

Note: Please note that support for MegaPatch128 is experimental and should be used at your own risk!

This application can be used as an AUTO_EXEC file or as an APPLICATION. To use it as an AUTO_EXEC file, copy it to your boot disk and it will be executed when GEOS starts. Alternatively, you can also start it as an application from your desktop.
If no SD2IEC drive with an RTC is detected on drives A: to D:, the file will either exit without any message during GEOS startup or it will display a short error message when started as an application.

By default GEOS drives A: to D: will be tested. Edit the configuration in the "geoSD2RTC" file header block to test selected SD2IEC drives only, for example SD:CD: will only test SD2IEC drives C: and D: for an RTC device.

Note: Some SD2IEC drives may have a software RTC enabled which could report incorrect date and time values. Drives that report year earlier than 2020 will be ignored.

geoRTC2SD:
Since version 1.3, there is an additional utility called "geoRTC2SD". This tool can be used to set the software RTC on SD2IEC devices using the current GEOS date and time.
The AUTO_EXEC file must be placed in the directory behind the utility which will read GEOS date and time from other RTC devices like TurboChameleon64 or WiC64.

By default all GEOS drives A: to D: will be updated. when GEOS starts. Edit the configuration in the "geoRTC2SD" file header block to update selected drives only, for example SD:AC: will only update the RTC on SD2IEC drives A: and C:.

Note: Please note that there may be different SD2IEC devices with varying firmware versions and RTC types.
If your SD2IEC RTC supports the "T-RI" command then "geoRTC2SD" will be able to set day of the week correctly using "T-WI".
If "T-RI" is not supported by your SD2IEC firmware then "geoRTC2SD" will use "T-WB". If the updated SD2IEC date differs from the current GEOS date, the RTC may not be set without specifing the correct day of the week. Since GEOS does not handle day of the week, "geoRTC2SD" will always use "SUNDAY".
For example VICE may "fix" the specified date on CMD devices if the day of the week does not match. This behaviour is different from real CMD hardware and SD2IEC devices used here for testing.
If your SD2IEC device behaves similarly to VICE then you cannot use the "geoRTC2SD" utility.

ChangeLog:
2024/02/22 - V1.3
- Remove deprecated code.
- Added config support to geoSD2RTC.
- Added geoRTC2SD to set the RTC on SD2IEC.
2024/02/18 - V1.2
- Added a fix for SD2IEC with software RTC.
2024/02/17 - V1.1
- Added experimental support for MegaPatch128.
2024/02/16 - V1.0
- Initial release.
