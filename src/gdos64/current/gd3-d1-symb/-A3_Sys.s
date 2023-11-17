; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Systemerweiterungen
:SYS__1			OPEN_BOOT
			OPEN_SYMBOL

;--- SuperCPU/RAM-Patches.
;Hinweis: Die Dateien befinden sich auf der Kernal-Disk da der Code auch
;direkt in den Kernal eingebunden werden kann.
			OPEN_KERNAL

			b $f0,"o.Patch_SRAM",$00
			b $f0,"o.Patch_SCPU",$00

			b $f0,"o.DvRAM_SRAM",$00
			b $f0,"o.DvRAM_CREU",$00
			b $f0,"o.DvRAM_RLNK",$00
			b $f0,"o.DvRAM_GRAM",$00
			b $f0,"o.DvRAM_GSYS",$00

;--- Externe Kernal-Routinen.
;			OPEN_KERNAL

			b $f0,"e.Register",$00
			b $f0,"e.InitSystem",$00
			b $f0,"e.EnterDeskTop",$00
			b $f0,"e.NewToBasic",$00
			b $f0,"e.NewPanicBox",$00
			b $f0,"e.GetNextDay",$00
			b $f0,"e.DoAlarm",$00
			b $f0,"e.GetFiles",$00
			b $f0,"e.GetFiles_Data",$00
			b $f0,"e.GetFiles_Menu",$00
			b $f0,"e.DB_LdSvScreen",$00
			b $f0,"e.SS_Starfield",$00
			b $f0,"e.SS_PuzzleIt!",$00
			b $f0,"e.SS_Raster",$00
			b $f0,"e.SS_PacMan",$00
			b $f0,"o.SS_64erMove",$00
			b $f0,"e.SS_64erMove",$00
			b $f0,"e.ScreenSaver",$00
			b $f0,"e.GetBackScrn",$00
			b $f0,"e.GeoHelp",$00

;--- Joysticktreiber.
;			OPEN_KERNAL
			b $f0,"s.SStick64.1",$00
			b $f0,"s.SStick64.2",$00

;--- Zusätzliche Maustreiber.
;			OPEN_KERNAL
			b $f0,"s.SmartMouse",$00
			b $f0,"s.SMouse64",$00
			b $f0,"s.MicroMysX0",$00
			b $f0,"s.MicroMysX1",$00
			b $f0,"s.MicroMysX2",$00
			b $f0,"s.MicroMysX3",$00
