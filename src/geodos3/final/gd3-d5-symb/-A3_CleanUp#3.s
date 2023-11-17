; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Laufwerkstreiber löschen.
:DelObjDevFiles		b $f1
			lda	#DEL_OBJ_FILES
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
::10			b "obj.Turbo41",$00
::11			b "obj.Turbo71",$00
::12			b "obj.Turbo81",$00
::13			b "obj.TurboPP",$00
::14			b "obj.TurboDOS",$00
::15			b "obj.PCDOS",$00
;::16			b "obj.TurboIECB",$00

::54			b "DiskDev_HD41_PP",$00
::55			b "DiskDev_HD71_PP",$00
::56			b "DiskDev_HD81_PP",$00
::57			b "DiskDev_HDNM_PP",$00

::90			w :10,:11,:12,:13,:14,:15
;			w :16
			w :54,:55,:56,:57

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
::811			b PLAINTEXT,"Kann Treiber-Datei nicht löschen:",NULL

::NEXT
