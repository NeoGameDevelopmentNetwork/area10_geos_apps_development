; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_MAIN		OPEN_MAIN

			b $f0,"src.GeoDOS",$00
			b $f0,"src.DOSDRIVE",$00
			b $f0,"src.TestHardware",$00
			b $f0,"src.Info",$00
			b $f0,"src.GetDrive",$00
			b $f0,"src.Menu",$00
			b $f0,"src.Appl_Doks",$00
;--- Ergänzung: 24.04.19/M.Kanet
;RunBASIC durch neue Routine ersetzt.
;Seit MegaPatch V3.3r5 funktioniert
;das laden/starten von BASIC-Programmen.
;Keine Spezial-Routine notwendig.
;			b $f0,"src.RunBASIC",$00
			b $f0,"src.RunBASICv2",$00
			b $f0,"src.ColorSetup",$00
			b $f0,"src.SetTime",$00
			b $f0,"src.GetHelp",$00
			b $f0,"src.SwapDrives",$00
			b $f0,"src.DiskError",$00
			b $f0,"src.ParkTurnOff",$00
			b $f0,"src.ExitGD",$00
			b $f0,"src.BootGD",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	r0,:102
			jsr	DeleteFile
			LoadW	a0,:103
			rts

::102			b "GeoDOS64",$00
::103			b $f5
			b $f0,"lnk.GeoDOS",$00
