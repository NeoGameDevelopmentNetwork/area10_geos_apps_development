; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
endif

			n "ass.DESKTOP_EN"
			c "ass.SysFile V1.0"
			h "* AutoAssembler Systemdatei."
			h "Erstellt Systemprogramme."
			a "Markus Kanet"
			f $04

			o $4000

:CompileAll		b $f0,"lang.DESKTOP_EN",$00
			b $f0,"src.DESKTOP",$00
			b $f0,"src.mod#1",$00
			b $f0,"src.mod#2",$00
			b $f0,"src.mod#3",$00
			b $f0,"src.mod#4",$00
			b $f0,"src.mod#5",$00
			b $f0,"src.RunDESKTOP",$00

:DelObjFile		b $f1
			lda	a1H			;Open Target-Device.
			jsr	SetDevice
			jsr	OpenDisk		;Open disk with object files.

			LoadW	r0,:1			;Delete existing linked application.
			jsr	DeleteFile

;--- MegaLinker aufrufen.
			LoadW	a0,:2			;Continue with AutoAssembler...
			rts

::1			b "DESK TOP",$00

::2			b $f5
			b $f0,"lnk.DESKTOP",$00		;Link DESK TOP v2.

			b $ff				;All done!
