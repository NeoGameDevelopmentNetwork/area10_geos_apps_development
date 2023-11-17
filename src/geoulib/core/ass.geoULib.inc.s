; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** geoUlib:
;			b $f0,"src.geoUTemplate",$00

			b $f0,"src.geoUTestERAM",$00
			b $f0,"src.geoUTarget",$00
			b $f0,"src.geoUGetHWInf",$00
			b $f0,"src.geoUDrvInfo",$00
			b $f0,"src.geoUDiskPwr",$00

			b $f0,"src.geoUFreeze",$00
			b $f0,"src.geoUFreezeIO",$00
			b $f0,"src.geoUFreezeNM",$00
			b $f0,"src.geoUReboot",$00

			b $f0,"src.geoUInfoTime",$00
			b $f0,"src.geoUGetTime",$00

			b $f0,"src.geoUHomePath",$00
			b $f0,"src.geoUGetPath",$00
			b $f0,"src.geoUMakeDir",$00
			b $f0,"src.geoUChDir",$00
			b $f0,"src.geoUPathUsb0",$00
			b $f0,"src.geoUPathUsb1",$00

			b $f0,"src.geoUReadDir",$00

			b $f0,"src.geoUFileInfo",$00
			b $f0,"src.geoUFileStat",$00
			b $f0,"src.geoUFileSeek",$00
			b $f0,"src.geoUDRead",$00
			b $f0,"src.geoUDWrite2",$00
			b $f0,"src.geoUDWrite5",$00
			b $f0,"src.geoUDWrite8",$00

			b $f0,"src.geoUDelFile",$00
			b $f0,"src.geoURenFile",$00
			b $f0,"src.geoUCopyFile",$00

			b $f0,"src.geoULoadREU",$00
			b $f0,"src.geoUSaveREU",$00
			b $f0,"src.geoUSaveERAM",$00

			b $f0,"src.geoUSetTime",$00

			b $f0,"src.geoUEnDiskA",$00
			b $f0,"src.geoUDisDiskA",$00

			b $f0,"src.geoUDiskMnt",$00
			b $f0,"src.geoUDiskMntF",$00
			b $f0,"src.geoUDiskUMnt",$00
			b $f0,"src.geoUSwapDisk",$00

			b $f0,"src.geoUGetIFCnt",$00
			b $f0,"src.geoUGetMAC",$00
			b $f0,"src.geoUGetIPAdr",$00
			b $f0,"src.geoUOpenTCP",$00
			b $f0,"src.geoUOpenUDP",$00
			b $f0,"src.geoUReadNTP",$00
