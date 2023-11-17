; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Konfiguration.
:CFG__1			OPEN_BOOT
			OPEN_SYMBOL

;--- ext.Kernal-Module für TaskMan/Spooler.
			OPEN_KERNAL

			b $f0,"e.TaskMan",$00
			b $f0,"e.SpoolPrinter",$00
			b $f0,"e.SpoolMenu",$00

;--- GD.CONFIG.
			OPEN_CONFIG

			b $f0,"s.GDC.Config",$00
			b $f0,"s.GDC.E.INIT",$00
			b $f0,"s.GDC.E.DACC",$00
			b $f0,"s.GDC.E.SCRN",$00
			b $f0,"s.GDC.E.GEOS",$00
			b $f0,"s.GDC.E.SDEV",$00
			b $f0,"s.GDC.E.HELP",$00
			b $f0,"s.GDC.E.TASK",$00
			b $f0,"s.GDC.E.PSPL",$00
			b $f0,"s.GDC.RAM",$00
			b $f0,"s.GDC.Drives",$00
			b $f0,"s.GDC.Screen",$00
			b $f0,"s.GDC.GEOS",$00
			b $f0,"s.GDC.PrnInpt",$00
			b $f0,"s.GDC.GeoHelp",$00
			b $f0,"s.GDC.TaskMan",$00
			b $f0,"s.GDC.Spooler",$00

;--- GDC.Tools löschen.
			b $f1
			lda	#DvAdr_Target
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:0 			;GD.CONFIG löschen.
			jsr	DeleteFile

			LoadW	r0,:1 			;GD.CONF.TASKMAN löschen.
			jsr	DeleteFile

			LoadW	r0,:2 			;GD.CONF.SPOOLER löschen.
			jsr	DeleteFile

			LoadW	a0,:NEXT
			rts

::0			b "GD.CONFIG",$00
::1			b "GD.CONF.TASKMAN",$00
::2			b "GD.CONF.SPOOLER",$00

;--- GDC.Tools linken.
::NEXT			b $f5
			b $f0,"lnk.GDC.Config",$00
			b $f0,"lnk.GDC.TaskMan",$00
			b $f0,"lnk.GDC.Spooler",$00
			b $f4
