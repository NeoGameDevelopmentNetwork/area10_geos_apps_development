; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Programme.
:PROG__1		OPEN_BOOT
			OPEN_SYMBOL

			OPEN_PROG

;--- HilfeSystem.
			b $f0,"s.GD.GeoHelp.DA",$00
			b $f0,"s.GD.GeoHelp",$00
			b $f0,"s.GD.GeoHelp.Prn",$00

;--- REBOOT-Funktionen.
			b $f0,"o.ReBoot.SCPU",$00
			b $f0,"o.ReBoot.RL",$00
			b $f0,"o.ReBoot.REU",$00
			b $f0,"o.ReBoot.BBG",$00

;--- Boot-Programme.
			b $f0,"s.GD",$00
			b $f0,"s.GD.RESET",$00
			b $f0,"s.GD.BOOT.1",$00
			b $f0,"s.GD.BOOT.2",$00
			b $f0,"o.GD.AUTOBOOT",$00
			b $f0,"s.GD.BOOT",$00
			b $f0,"s.GD.RBOOT",$00
			b $f0,"s.GD.RBOOT.SYS",$00
			b $f0,"s.GD.FBOOT",$00

;--- Update-Programme.
			b $f0,"o.GD.INITSYS",$00
			b $f0,"s.GD.UPDATE",$00

;--- Installationsprogramm.
			b $f0,"s.MakeSetupGDOS",$00

;--- Setup-Programm.
if LANG = LANG_DE
:SETUP_DE		b $f0,"s.SetupGDOS",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:fname_de
			jsr	DeleteFile
			LoadW	a0,:cont_de
			rts

::fname_de		b "SetupGDOS64de",$00
::cont_de		b $f5
			b $f0,"lnk.SetupGDOS.de",$00
			b $f4
endif
if LANG = LANG_EN
:SETUP_EN		b $f0,"s.SetupGDOS",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:fname_en
			jsr	DeleteFile
			LoadW	a0,:cont_en
			rts

::fname_en		b "SetupGDOS64en",$00
::cont_en		b $f5
			b $f0,"lnk.SetupGDOS.en",$00
			b $f4
endif

;--- Mauszeiger.
			b $f0,"s.NewMouse64",$00

;--- gMicroMys.
			b $f0,"s.gMicroMys",$00
