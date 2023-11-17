; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Externe Symboltabellen löschen.
:DelExtFiles		b $f1
			lda	#DEL_EXT_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:3
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:2
			jsr	:doDelete
::2			pla
			tay
			iny
			iny
			bne	:1

::3			LoadW	a0,:NEXT
			rts

::doDelete		MoveW	r0,:801
			jsr	DeleteFile
			txa
			beq	:exitDlg
			lda	#DEL_ENABLE_WARN
			beq	:exitDlg
			LoadW	r0,:800
			jsr	DoDlgBox
::exitDlg		rts

;s.GD3_KERNAL.ext
::01			b "s.GD3_KERNAL.ext",$00

;e.Register
::10			b "e.Register.ext",$00

;s.GD.CONFIG
::11			b "s.GDC.Config.ext",$00

;o.Patch_SRAM/SCPU
::12			b "o.Patch_SRAM.ext",$00
::13			b "o.Patch_SCPU.ext",$00

;o.DvRAM_GRAM
::15			b "o.DvRAM_GRAM.ext",$00

;s.GD.BOOT.1/.2/s.GD.BOOT
::21			b "s.GD.BOOT.2.ext",$00
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
::22a			b "s.GD.BOOT.ext",$00
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
::22b			b "s.GD.BOOT.NG.ext",$00
endif

;s.GD.RBOOT.S.ext
::31			b "s.GD.RBOOT.S.ext",$00

;o.GD.INITSYS
::40			b "o.GD.INITSYS.ext",$00

::90			w :01,:10,:11,:12,:13,:15
			w :21
if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			w :22a
endif
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			w :22b
endif
			w :31,:40

			w $0000

::800			b $01
			b $30,$72
			w $0040,$00ff
			b DBTXTSTR,$10,$0e
			w :810
			b DBTXTSTR,$10,$1e
			w :811
			b DBTXTSTR,$10,$28
::801			w $ffff
			b OK,$02,$30
			b NULL
::810			b BOLDON,"DATEIFEHLER!",NULL
::811			b PLAINTEXT,"Kann Symbol-Datei nicht löschen:",NULL

::NEXT
