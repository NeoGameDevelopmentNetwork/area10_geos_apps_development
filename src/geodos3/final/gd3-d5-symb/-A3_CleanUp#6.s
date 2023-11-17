; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Externe Symboltabellen löschen.
:DelExtFilesDisk	b $f1
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

;s.GD.DISK
::30			b "s.1541_Turbo.ext",$00
::31			b "s.1571_Turbo.ext",$00
::32			b "s.1581_Turbo.ext",$00
::33			b "s.PP_Turbo.ext",$00
::34			b "s.DOS_Turbo.ext",$00
::35			b "s.PCDOS.ext",$00
::36			b "s.PCDOS_EXT.ext",$00
;::37			b "s.IECB_Turbo.ext",$00

if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
::89			b "s.GD.DRV.Cor.ext",$00
endif

::90			w :30,:31,:32,:33,:34,:35,:36
;			w :37
if (ENABLE_DISK_NG = TRUE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
			w :89
endif

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
