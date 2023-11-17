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
			OPEN_SYSTEM
			t "-A3_Sys#1"

;--- Externe Kernal-Routinen.
;			OPEN_SYSTEM
			t "-A3_Sys#2"

;--- Setup-Programme.
;			OPEN_SYSTEM
			t "-A3_Sys#3"
