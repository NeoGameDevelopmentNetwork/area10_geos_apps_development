; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerkstreiber.
:DISK__1		OPEN_BOOT
			OPEN_SYMBOL

;--- GD.DISK löschen.
			t "-A3_Disk.del"

;--- TurboDOS / Treiber.
			OPEN_DISK
			t "-A3_Disk#1"

;--- Laufwerksinstallation.
			OPEN_CONFIG

;--- GD.DISK-Laufwerkstreiber.
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			t "-A3_Disk#2"			;GD.DISK-Systemdatei.
endif

;--- GD.DISK/NG-Laufwerkstreiber.
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			t "-A3_Disk#3"			;GD.DISK.<DRIVER>-Anwendungen.
endif

;--- Linker: GD.DISK.
;Nach GD.DISK/NG, da sonst die Treiber
;für die NG-Treiber fehlen!
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			t "-A3_Disk.lnk"
endif
