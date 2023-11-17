; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GEODESK und Module löschen.
:GEODESK_DEL		b $f1
			lda	#DvAdr_Target
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:1 			;GEODESK löschen.
			jsr	DeleteFile

			LoadW	r0,:2 			;GEODESK.mod löschen.
			jsr	DeleteFile

			LoadW	a0,GEODESK
			rts

::1			b "GEODESK",$00
::2			b "GEODESK.mod",$00

;--- GEODESK Teil #1.
:GEODESK		OPEN_GDESK1

			b $f0,"s.GD.00.Boot",$00

			b $f0,"s.GD.10.Core",$00

			b $f0,"s.GD.20.WM",$00
			b $f0,"s.GD.21.DeskTop",$00

			b $f0,"s.GD.25.DrawDTop",$00
			b $f0,"s.GD.26.StartHC",$00
			b $f0,"s.GD.27.InptPrnt",$00
			b $f0,"s.GD.28.WinFiles",$00
			b $f0,"s.GD.29.ShortCut",$00

			b $f0,"s.GD.30.MenuGEOS",$00
			b $f0,"s.GD.31.MenuWin",$00
			b $f0,"s.GD.32.MenuComp",$00
			b $f0,"s.GD.33.MenuDesk",$00
			b $f0,"s.GD.34.MenuALnk",$00
			b $f0,"s.GD.35.MenuDisk",$00
			b $f0,"s.GD.36.MenuFile",$00
			b $f0,"s.GD.37.MenuTWin",$00
			b $f0,"s.GD.38.MenuSD",$00
			b $f0,"s.GD.39.MenuCBM",$00

			b $f0,"s.GD.40.DirData",$00
			b $f0,"s.GD.41.AppLink",$00
			b $f0,"s.GD.42.OpenFile",$00
			b $f0,"s.GD.43.Border",$00
			b $f0,"s.GD.45.GetFiles",$00
			b $f0,"s.GD.48.BackScrn",$00

			b $f0,"s.GD.50.SysInfo",$00
			b $f0,"s.GD.52.SysTime",$00
			b $f0,"s.GD.53.Colors",$00
			b $f0,"s.GD.54.Options",$00
			b $f0,"s.GD.55.DrvMode",$00
			b $f0,"s.GD.56.StatMsg",$00

;--- GEODESK Teil #2.
			OPEN_GDESK2

			b $f0,"s.GD.60.DiskInfo",$00
			b $f0,"s.GD.61.MakeDImg",$00
			b $f0,"s.GD.62.Format",$00
			b $f0,"s.GD.63.DiskCopy",$00
			b $f0,"s.GD.64.Validate",$00

			b $f0,"s.GD.80.FileInfo",$00
			b $f0,"s.GD.81.MakeSDir",$00
			b $f0,"s.GD.82.Delete",$00
			b $f0,"s.GD.83.CopyMove",$00

;--- GEODESK-Module.
			b $f0,"m.GD.00.ModMenu",$00
			b $f0,"s.GD.90.Help",$00
			b $f0,"s.GD.91.DirSort",$00
			b $f0,"s.GD.92.FileCVT",$00
			b $f0,"s.GD.93.GPShow",$00
			b $f0,"s.GD.94.SendTo",$00
			b $f0,"s.GD.95.CBMDisk",$00
			b $f0,"s.GD.96.CMDPart",$00
			b $f0,"s.GD.97.IconMan",$00
			b $f0,"s.GD.98.SD2IEC",$00

;--- GEODESK linken.
			b $f5
			b $f0,"lnk.GeoDesk.mod",$00
			b $f0,"lnk.GeoDesk",$00
			b $f4
