; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:INIT_DOS		OPEN_DOSCBM

			b $f0,"dos.FormatRename",$00
			b $f0,"dos.Dir",$00
			b $f0,"dos.SubDir",$00
			b $f0,"dos.FileInfo",$00
			b $f0,"dos.PrintDir",$00
			b $f0,"dos.RenDelFile",$00
			b $f0,"dos.PrintFile",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	r0,:102
			jsr	DeleteFile
			LoadW	a0,:103
			rts

::102			b "GD_DOS",$00

::103			b $f5
			b $f0,"lnk.GD_DOS",$00
