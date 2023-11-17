; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Programme
:PROG__1		OPEN_BOOT
			OPEN_SYMBOL

;--- Laufwerkstreiber für Bootdiskette.
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			OPEN_DISK
			t "-A3_Disk#B"
endif

;--- GD.CONFIG.
			OPEN_CONFIG
			t "-A3_Prog#1"

;--- Zusatzprogramme.
			OPEN_PROG
			t "-A3_Prog#2"

;--- Installationsprogramm.
			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:116
			jsr	DeleteFile
			LoadW	a0,:117
			rts

::116			b "SetupGD_64",$00
::117			b $f5
			b $f0,"lnk.SetupGD",$00
			b $f4
