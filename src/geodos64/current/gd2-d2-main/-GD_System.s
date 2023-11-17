; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Systemvariablen.
; Datum			: 05.07.97
;
;*** Landessprache festlegen.
			t "-GD_Sprache"
;******************************************************************************

;******************************************************************************
.VersionCode		b PLAINTEXT
;			k				;Aktuelles Datum.
			b "020123"			;Festes Datum.
			b "dev"
;Jahres-Angabe Copyright auch
;in src.TestHardware ändern!
			b "-"
;.Ser_No		b "GD642-"
;GEOS-Klasse auch in src.GeoDOS ändern!
.Version		b PLAINTEXT,"V2.980",NULL
.AppClass		b "GeoDOS 64   V298",NULL
;******************************************************************************

;******************************************************************************
;*** Systemvariablen.
;******************************************************************************
.AppDrv			b $00				;Startlaufwerk.
.AppType		b $00				;Typ des Startlaufwerks.
.AppMode		b $00
.AppPart		b $00
.AppRLPart		b $00,$00			;Startadresse RAMLink-Boot-Partition.
.AppNDir		b $00,$00
.AppNameBuf		s 17

.BootDrive		b $00
.BootType		b $00				;Typ des Startlaufwerks.
.BootMode		b $00
.BootPart		b $00
.BootRLpart		b $00,$00
.BootNDir		b $00,$00

;*** Angaben über RAM-Status.
.GD_RAM_Bank		b $00
.GD_TaskMan		b $00

;*** Angabe über vorhandene GD-Module.
.CBM_Install		b $00
.DOS_Install		b $00
.DDrvInstall		b $00
.CopyInstall		b $00

;*** Systemvariablen.
.curMenu		b $00
.CopyMod		b $00
.BubbleMod		b $00
.TargetMode		b $00
.TempTrgtMode		b $00
.MseKey2Mode		b $00
;--- Ergänzung: 22.12.18/M.Kanet
;Unterstützung für Option D'n'D On/Off ergänzt.
;Kann im Menü TOOLS ein-/ausgeschaltet werden.
.EnableDnD		b $00

;*** Laufwerksbezeichnug in ASCII.
.Drive_ASCII   s 32

;*** Laufwerks-Parameter.
.Source_Drv		b $00
.Target_Drv		b $00
.Action_Drv		b $00
.curDrvType		b $00
.curDrvMode		b $00
.curDriveRAM		b $00
.CBM_Count		b $00
.DOS_Count		b $00
.DriveTypes		s $04
.DriveModes		s $04
.DriveAdress		s $04
.DrivePart		s $04
.SDrvPart		s $03
.TDrvPart		s $03
.SDrvNDir		s $03
.TDrvNDir		s $03

;*** Partitions-Befehle.
.Part_Change		b $04,$00, 67,208,$00,$0d
.Part_GetInfo		b $05,$00, "G-P",$00,$0d
.Part_Info		w $001f
			s 32

;*** Angaben zum aktuellen CMD-Verzeichnis.
.WorkNDir		b $00,$00
