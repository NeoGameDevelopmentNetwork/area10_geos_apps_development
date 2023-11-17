; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Build-Dateien löschen.
:DEL__BUILD		OPEN_TARGET

;--- Objekt-Dateien löschen.
;(über 'd'-OpCode in Code eingebunden)
:DelExtFiles		b $f1
			lda	#DEL_EXT_FILES
			cmp	#FALSE
			beq	:5

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::3			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:5
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:4
			jsr	:doDelete
::4			pla
			tay
			iny
			iny
			bne	:3

::5			LoadW	a0,:NEXT
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

;Main
::01			b "src.GeoDOS.ext",$00
::02			b "src.BootGD.ext",$00
::03			b "src.ExitGD.ext",$00
::04			b "src.DOSDRIVE.ext",$00
::05			b "src.Menu.ext",$00

;DOS
::11			b "dos.Dir.ext",$00

;CBM
::21			b "cbm.Dir.ext",$00
::22			b "cbm.FormatRe.ext",$00
::23			b "cbm.PrintDir.ext",$00
::24			b "cbm.SortDir.ext",$00
::25			b "cbm.ValidUnd.ext",$00

;TOOLS
::30			b "src.GeoHelpV.ext",$00
::31			b "src.LoadGeoH.ext",$00

::90			w :01,:02,:03,:04,:05
			w :11
			w :21,:22,:23,:24,:25
			w :30,:31

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
