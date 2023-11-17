; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_CBM		OPEN_DOSCBM

			b $f0,"cbm.FormatRename",$00
			b $f0,"cbm.Dir",$00
			b $f0,"cbm.Part_NDir",$00
			b $f0,"cbm.FileInfo",$00
			b $f0,"cbm.DSKtoDSK",$00
			b $f0,"cbm.DoDSKtoDSK",$00
			b $f0,"cbm.SortDir",$00
			b $f0,"cbm.PrintDir",$00
			b $f0,"cbm.RenDelFile",$00
			b $f0,"cbm.PrintFile",$00
			b $f0,"cbm.ValidUndel",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	r0,:102
			jsr	DeleteFile
			LoadW	a0,:103
			rts

::102			b "GD_CBM",$00

::103			b $f5
			b $f0,"lnk.GD_CBM",$00
