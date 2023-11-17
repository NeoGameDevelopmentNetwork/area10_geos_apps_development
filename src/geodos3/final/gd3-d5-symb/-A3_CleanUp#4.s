; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Laufwerkstreiber löschen.
:DelObjDrvFiles		b $f1
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
::20			b "DiskDev_1541",$00
::21			b "DiskDev_1571",$00
::22			b "DiskDev_1581",$00
::23			b "DiskDev_PCDOS",$00

::30			b "DiskDev_RAM41",$00
::31			b "DiskDev_RAM71",$00
::32			b "DiskDev_RAM81",$00
::33			b "DiskDev_RAMNM",$00
::34			b "DiskDev_RAMNMC",$00
::35			b "DiskDev_RAMNMG",$00
::36			b "DiskDev_RAMNMS",$00

::40			b "DiskDev_FD41",$00
::41			b "DiskDev_FD71",$00
::42			b "DiskDev_FD81",$00
::43			b "DiskDev_FDNM",$00

::50			b "DiskDev_HD41",$00
::51			b "DiskDev_HD71",$00
::52			b "DiskDev_HD81",$00
::53			b "DiskDev_HDNM",$00

::60			b "DiskDev_RL41",$00
::61			b "DiskDev_RL71",$00
::62			b "DiskDev_RL81",$00
::63			b "DiskDev_RLNM",$00

::70			b "DiskDev_SD2IEC",$00
;::71			b "DiskDev_IECBNM",$00

::90			w :20,:21,:22,:23
			w :30,:31,:32,:33,:34,:35,:36
			w :40,:41,:42,:43
			w :50,:51,:52,:53
			w :60,:61,:62,:63
			w :70
;			w :71

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
