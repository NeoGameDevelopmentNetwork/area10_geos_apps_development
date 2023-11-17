; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- HilfeSystem.
			b $f0,"s.GD.GeoHelp.Ld",$00
			b $f0,"s.GD.GeoHelp",$00
			b $f0,"s.GD.GeoHelp.Prn",$00

;--- REBOOT-Funktionen.
			b $f0,"o.ReBoot.SCPU",$00
			b $f0,"o.ReBoot.RL",$00
			b $f0,"o.ReBoot.REU",$00
			b $f0,"o.ReBoot.BBG",$00

;--- Bootprogramme.
			b $f0,"s.GD",$00
			b $f0,"s.GD.RESET",$00
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GD.BOOT.1",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GD.BOOT.1.NG",$00
endif
			b $f0,"s.GD.BOOT.2",$00
			b $f0,"o.GD.AUTOBOOT",$00
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GD.BOOT",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GD.BOOT.NG",$00
endif
			b $f0,"s.GD.RBOOT",$00
			b $f0,"s.GD.RBOOT.SYS",$00

;--- Makeboot.
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GD.MAKEBOOT",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.GD.MAKEBOOT.NG",$00
endif

;--- Updateprogramm.
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"o.GD.INITSYS",$00
			b $f0,"s.GD.UPDATE",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"o.GD.INITSYS",$00
			b $f0,"s.GD.UPDATE.NG",$00
endif

;--- Installationsprogramme.
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.MakeSetupGD",$00
			b $f0,"s.SetupGD",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			b $f0,"s.MakeSetupGD.NG",$00
			b $f0,"s.SetupGD.NG",$00
endif

;--- Mauszeiger.
			b $f0,"s.NewMouse64",$00
