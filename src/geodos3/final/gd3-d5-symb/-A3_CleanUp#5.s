; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Laufwerkstreiber löschen.
:DelObjIniFiles		b $f1
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
::80a			b "mod.MDD_#100",$00
::81a			b "mod.MDD_#110",$00
::81b			b "mod.MDD_#112",$00
::81c			b "mod.MDD_#114",$00
::82a			b "mod.MDD_#120",$00
::82b			b "mod.MDD_#122",$00
::82c			b "mod.MDD_#124",$00
::82d			b "mod.MDD_#126",$00
::83a			b "mod.MDD_#130",$00
::84a			b "mod.MDD_#140",$00
::84b			b "mod.MDD_#142",$00
::84c			b "mod.MDD_#144",$00
::84d			b "mod.MDD_#146",$00
::85a			b "mod.MDD_#150",$00
::86a			b "mod.MDD_#160",$00
::87a			b "mod.MDD_#170",$00
::87b			b "mod.MDD_#172",$00
::87c			b "mod.MDD_#174",$00
::88a			b "mod.MDD_#180",$00

::90			w :80a
			w :81a,:81b,:81c,:82a,:82b,:82c,:82d
			w :83a,:84a,:84b,:84c,:84d,:85a,:86a
			w :87a,:87b,:87c,:88a

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
