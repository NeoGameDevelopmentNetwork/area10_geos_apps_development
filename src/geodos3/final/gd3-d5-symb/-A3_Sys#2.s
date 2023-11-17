; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Externe Kernal-Routinen.
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
			b $f0,"e.TaskMan",$00
			b $f0,"e.SpoolPrinter",$00
			b $f0,"e.SpoolMenu",$00
			b $f0,"e.SS_Starfield",$00
			b $f0,"e.SS_PuzzleIt!",$00
			b $f0,"e.SS_Raster",$00
			b $f0,"e.SS_PacMan",$00
			b $f0,"o.SS_64erMove",$00
			b $f0,"e.SS_64erMove",$00
			b $f0,"e.ScreenSaver",$00
			b $f0,"e.GetBackScrn",$00
			b $f0,"e.GeoHelp",$00
