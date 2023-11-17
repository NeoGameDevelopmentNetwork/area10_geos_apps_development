; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_COPY		OPEN_CONVERT

			b $f0,"copy.Options",$00
			b $f0,"copy.DOStoCBM",$00
			b $f0,"copy.CBMtoDOS",$00
			b $f0,"copy.CBMtoCBM",$00
			b $f0,"copy.Error",$00
			b $f0,"copy.DoDOStoCBM",$00
			b $f0,"copy.DoDOStoGW",$00
			b $f0,"copy.DoDOStoCBMF",$00
			b $f0,"copy.DoCBMtoDOS",$00
			b $f0,"copy.DoGWtoDOS",$00
			b $f0,"copy.DoCBMtoDOSF",$00
			b $f0,"copy.DoCBMtoCBM",$00
			b $f0,"copy.DoCBMtoGW",$00
			b $f0,"copy.DoGWtoCBM",$00
			b $f0,"copy.DoGWtoGW",$00
			b $f0,"copy.DoCBMtoCBMF",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	r0,:102
			jsr	DeleteFile
			LoadW	a0,:103
			rts

::102			b "GD_Copy",$00

::103			b $f5
			b $f0,"lnk.GD_Copy",$00
