; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemlabels.
if .p
			t "TopSym"
			t "TopMac"
endif

			o $4000
			c "ass.SysFile V1.0"
			n "ass.GeoDOS"
			f $04

:INIT_MAIN		b $f0,"src.geoDOS",$00
			b $f0,"mod.#1",$00
			b $f0,"mod.#10",$00
			b $f0,"mod.#20",$00
			b $f0,"mod.#21",$00
			b $f0,"mod.#22",$00
			b $f0,"mod.#30",$00
			b $f0,"mod.#31",$00
			b $f0,"mod.#40",$00
			b $f0,"mod.#41",$00
			b $f0,"mod.#42",$00
			b $f0,"mod.#50",$00
			b $f0,"mod.#100",$00
			b $f0,"mod.#101",$00
			b $f0,"dos.ConvTab #0",$00
			b $f0,"dos.ConvTab #1",$00
			b $f0,"dos.ConvTab #2",$00
			b $f0,"dos.ConvTab #3",$00
			b $f0,"dos.ConvTab #4",$00
			b $f0,"dos.ConvTab #5",$00
			b $f0,"dos.ConvTab #6",$00
			b $f0,"dos.ConvTab #7",$00
			b $f0,"dos.ConvTab #8",$00
			b $f0,"dos.ConvTab #9",$00
			b $f0,"cbm.ConvTab #0",$00
			b $f0,"cbm.ConvTab #1",$00
			b $f0,"cbm.ConvTab #2",$00
			b $f0,"cbm.ConvTab #3",$00
			b $f0,"cbm.ConvTab #4",$00
			b $f0,"cbm.ConvTab #5",$00
			b $f0,"cbm.ConvTab #6",$00
			b $f0,"cbm.ConvTab #7",$00
			b $f0,"cbm.ConvTab #8",$00
			b $f0,"cbm.ConvTab #9",$00

			b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	r0,:102
			jsr	DeleteFile
			LoadW	a0,:103
			rts

::102			b "geoDOS64",$00
::103			b $f5
			b $f0,"lnk.geoDOS",$00
			b $ff

