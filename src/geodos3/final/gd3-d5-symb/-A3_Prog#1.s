; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- GD.CONFIG.
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GDC.Config",$00
			b $f0,"s.GDC.RAM",$00
			b $f0,"s.GDC.Drives",$00
			b $f0,"s.GDC.Screen",$00
			b $f0,"s.GDC.GEOS",$00
			b $f0,"s.GDC.PrnInpt",$00
			b $f0,"s.GDC.GeoHelp",$00
			b $f0,"s.GDC.TaskMan",$00
			b $f0,"s.GDC.Spooler",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GDC.Config.NG",$00
			b $f0,"s.GDC.RAM",$00
			b $f0,"s.GDC.Drives.NG",$00
			b $f0,"s.GDC.Screen",$00
			b $f0,"s.GDC.GEOS.NG",$00
			b $f0,"s.GDC.PrnInpt",$00
			b $f0,"s.GDC.GeoHelp",$00
			b $f0,"s.GDC.TaskMan",$00
			b $f0,"s.GDC.Spooler",$00
endif
