; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if COMP_SYS = TRUE_C64
;--- REBOOT-Funktionen.
			b $f0,"o.ReBoot.SCPU",$00
			b $f0,"o.ReBoot.RL",$00
			b $f0,"o.ReBoot.REU",$00
			b $f0,"o.ReBoot.BBG",$00

;--- Bootprogramme.
			b $f0,"s.GEOS64",$00
			b $f0,"s.GEOS64.RESET",$00
			b $f0,"s.GEOS64.1",$00
			b $f0,"s.GEOS64.2",$00
			b $f0,"s.GEOS64.3",$00
			b $f0,"s.GEOS64.4",$00
			b $f0,"o.AUTO.BOOT",$00
			b $f0,"s.GEOS64.BOOT",$00
			b $f0,"s.RBOOT64",$00
			b $f0,"s.RBOOT64.BOOT",$00

;--- Installationsprogramme.
			b $f0,"s.GEOS64.TaskMse",$00
			b $f0,"s.GEOS64.MKBT",$00
			b $f0,"o.Update2MP3",$00
			b $f0,"s.GEOS64.MP3",$00

;--- Mauszeiger.
			b $f0,"s.NewMouse64",$00

;--- Farbeditor.
			b $f0,"s.GEOS.ColorEdit",$00

endif

if COMP_SYS = TRUE_C128
;--- REBOOT-Funktionen.
			b $f0,"o.ReBoot.SCPU",$00
			b $f0,"o.ReBoot.RL",$00
			b $f0,"o.ReBoot.REU",$00
			b $f0,"o.ReBoot.BBG",$00

;--- Bootprogramme.
			b $f0,"s.GEOS128",$00
			b $f0,"s.GEOS128.RESET",$00
			b $f0,"s.GEOS128.0",$00
			b $f0,"s.GEOS128.1",$00
			b $f0,"s.GEOS128.2",$00
			b $f0,"s.GEOS128.3",$00
			b $f0,"s.GEOS128.4",$00
			b $f0,"o.AUTO.BOOT",$00
			b $f0,"s.GEOS128.BOOT",$00
			b $f0,"s.RBOOT128",$00
			b $f0,"s.RBOOT128.BOOT",$00

;--- Installationsprogramme.
			b $f0,"s.GEOS128.TaskMs",$00
			b $f0,"s.GEOS128.MKBT",$00
			b $f0,"o.Update2MP3",$00
			b $f0,"s.GEOS128.MP3",$00

;--- Mauszeiger.
			b $f0,"s.NewMouse128",$00

;--- Farbeditor.
			b $f0,"s.GEOS.ColorEdit",$00

endif
