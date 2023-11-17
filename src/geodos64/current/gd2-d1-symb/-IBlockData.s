; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Infoblock-Variablen..
; Datum			: 05.07.97
; Aufruf		: -
; Übergabe		: -
; Rückgabe		: -
; Verändert		: -
; Variablen		: -IBlockSektor
; Routinen		: -
;******************************************************************************

;******************************************************************************
.SYS_Installed		= IBlockSektor +$76		;$FF = Programm installiert.

.SYS_DriveType		= IBlockSektor +$77		;Speicher ":DriveTypes".
.SYS_DrvType_A		= IBlockSektor +$77		;Speicher ":DriveTypes +0".
.SYS_DrvType_B		= IBlockSektor +$78		;Speicher ":DriveTypes +1".
.SYS_DrvType_C		= IBlockSektor +$79		;Speicher ":DriveTypes +2".
.SYS_DrvType_D		= IBlockSektor +$7a		;Speicher ":DriveTypes +3".

.SYS_DriveMode		= IBlockSektor +$7b		;Speicher ":DriveModes".
.SYS_DrvMode_A		= IBlockSektor +$7b		;Speicher ":DriveModes +0".
.SYS_DrvMode_B		= IBlockSektor +$7c		;Speicher ":DriveModes +1".
.SYS_DrvMode_C		= IBlockSektor +$7d		;Speicher ":DriveModes +2".
.SYS_DrvMode_D		= IBlockSektor +$7e		;Speicher ":DriveModes +3".

.SYS_Drive_Adr		= IBlockSektor +$7f		;Speicher ":DriveAdress".
.SYS_Drv_Adr_A		= IBlockSektor +$7f		;Speicher ":DriveAdress +0".
.SYS_Drv_Adr_B		= IBlockSektor +$80		;Speicher ":DriveAdress +1".
.SYS_Drv_Adr_C		= IBlockSektor +$81		;Speicher ":DriveAdress +2".
.SYS_Drv_Adr_D		= IBlockSektor +$82		;Speicher ":DriveAdress +3".

.SYS_GD64Drive		= IBlockSektor +$83		;Speicher für System-Laufwerkstyp.
.SYS_GD64_Part		= IBlockSektor +$84		;Speicher für System-Partition.
.SYS_GD64_PR_L		= IBlockSektor +$85		;Speicher für System-Partition/RAMLink.
.SYS_GD64_PR_H		= IBlockSektor +$86		;Speicher für System-Partition/RAMLink.
.SYS_GD64_NM_T		= IBlockSektor +$87		;Speicher für System-Verzeichnis/Tr.
.SYS_GD64_NM_S		= IBlockSektor +$88		;Speicher für System-Verzeichnis/Se.

.SYS_HelpDrive		= IBlockSektor +$89		;Laufwerk für GeoHelp-Dokumente.
.SYS_Help_Part		= IBlockSektor +$8a		;Partition für GeoHelp-Dokumente.

.SYS_GD64RAMOK		= IBlockSektor +$8b		;$FF = RAM_GeoDOS installiert.
.SYS_GD64RBank		= IBlockSektor +$8c		;Bank für RAM_GeoDOS.
.SYS_GeoHelpOK		= IBlockSektor +$8d		;$FF = GeoHelp installiert.
.SYS_Help_Bank		= IBlockSektor +$8e		;Bank für GeoHelp.

.SYS_TaskManOK		= IBlockSektor +$8f		;$FF = TaskMan installiert.
.SYS_TaskBank0		= IBlockSektor +$90		;Bank #0 für TaskMan.
.SYS_TaskBank1		= IBlockSektor +$91		;Bank #1 für TaskMan.
.SYS_TaskBank2		= IBlockSektor +$92		;Bank #2 für TaskMan.
.SYS_TaskBank3		= IBlockSektor +$93		;Bank #3 für TaskMan.
.SYS_TaskBank4		= IBlockSektor +$94		;Bank #4 für TaskMan.
.SYS_TaskBank5		= IBlockSektor +$95		;Bank #5 für TaskMan.
.SYS_TaskBank6		= IBlockSektor +$96		;Bank #6 für TaskMan.
.SYS_TaskBank7		= IBlockSektor +$97		;Bank #7 für TaskMan.
.SYS_TaskBank8		= IBlockSektor +$98		;Bank #8 für TaskMan.

.SYS_DrvTarget		= IBlockSektor +$99		;GeoDOS-Menü: Laufwerksauswahl.
.SYS_Copy_Mode		= IBlockSektor +$9a		;GeoDOS-Menü: Partitionsauswahl.
.SYS_Bubble_OK		= IBlockSektor +$9b		;GeoDOS-Menü: Bubble-Anzeige.
.SYS_MKey2Mode		= IBlockSektor +$9c		;Modus für mittlere Maustaste.
;--- Ergänzung: 22.12.18/M.Kanet
;Unterstützung für Option D'n'D On/Off ergänzt.
;Kann im Menü TOOLS ein-/ausgeschaltet werden.
.SYS_EnableDnD		= IBlockSektor +$9d		;Drag'n'Drop ein-/ausschalten.

.SYS_Unused_9e		= IBlockSektor +$9e
.SYS_Unused_9f		= IBlockSektor +$9f
;******************************************************************************
