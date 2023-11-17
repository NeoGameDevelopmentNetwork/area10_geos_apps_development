; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_CONV		OPEN_CONVERT

			b $f0,"src.GD_CONVERT",$00
			b $f0,"dos.ConvTab#02",$00
			b $f0,"dos.ConvTab#03",$00
			b $f0,"dos.ConvTab#04",$00
			b $f0,"dos.ConvTab#05",$00
			b $f0,"dos.ConvTab#06",$00
			b $f0,"dos.ConvTab#07",$00
			b $f0,"dos.ConvTab#08",$00
			b $f0,"dos.ConvTab#09",$00
			b $f0,"dos.ConvTab#10",$00
			b $f0,"cbm.ConvTab#42",$00
			b $f0,"cbm.ConvTab#43",$00
			b $f0,"cbm.ConvTab#44",$00
			b $f0,"cbm.ConvTab#45",$00
			b $f0,"cbm.ConvTab#46",$00
			b $f0,"cbm.ConvTab#47",$00
			b $f0,"cbm.ConvTab#48",$00
			b $f0,"cbm.ConvTab#49",$00
			b $f0,"cbm.ConvTab#50",$00
			b $f0,"txt.ConvTab#82",$00
			b $f0,"txt.ConvTab#83",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	r0,:102
			jsr	DeleteFile
			LoadW	a0,:103
			rts

::102			b "GD_CONVERT",$00

::103			b $f5
			b $f0,"lnk.GD_CONVERT",$00
